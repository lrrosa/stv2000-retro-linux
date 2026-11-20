#!/bin/bash
# Wi-Fi interno do STV-2000 (iComm SSV6051P, ligado por SDIO): compila o driver
# comunitário (fora da árvore do kernel) para a versão exata do kernel do rootfs e
# instala módulo + firmware. Roda depois do 30-rootfs.sh.
# Compila também o clk-pwm.ko: o device tree da p281 liga o chip pelo "sdio-pwrseq", que
# precisa do relógio de 32 kHz "wifi32k" (compatible "pwm-clock", gerado pelo PWM_E). O
# kernel do Alpine vem sem CONFIG_COMMON_CLK_PWM; sem esse driver o pwrseq nunca sobe, o
# controlador SDIO (d0070000.mmc) não é registrado e o chip nem aparece no barramento.
# O kernel fica fixo no /etc/apk/world: um "apk upgrade" com kernel novo deixaria os
# módulos sem par. Para atualizar o kernel, gere uma imagem nova.
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"

[ -f "$BUILDER/etc/alpine-release" ] || die "rode 10-builder.sh antes"
[ -d "$TARGET/lib/modules" ] || die "rode 30-rootfs.sh antes"
kver=$(ls "$TARGET/lib/modules" | head -n1)
pver=$(awk '/^P:linux-lts$/ { getline; sub(/^V:/, ""); print; exit }' "$TARGET/lib/apk/db/installed")
[ -n "$kver" ] && [ -n "$pver" ] || die "kernel linux-lts não encontrado no rootfs"
mkdir -p "$SRC" "$ART/wifi" "$WORK/logs"
out="$ART/wifi/$kver/ssv6051.ko"
outclk="$ART/wifi/$kver/clk-pwm.ko"

builder_pronto=0
preparar_builder() {
    [ "$builder_pronto" = 1 ] && return 0
    log "Headers do kernel $pver no builder"
    apk_root "$BUILDER" add "linux-lts-dev=$pver"
    chroot_mount "$BUILDER"
    private_bind "$SRC" "$BUILDER/src"
    builder_pronto=1
}

if [ -f "$outclk" ]; then
    log "clk-pwm.ko já compilado para $kver"
else
    up=${kver%%-*}                       # 6.18.64-0-lts -> 6.18.64
    C="$SRC/clk-pwm-$up"; mkdir -p "$C"
    url="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/drivers/clk/clk-pwm.c"
    log "Baixando clk-pwm.c do Linux $up"
    curl -fsSL "$url?h=v$up" -o "$C/clk-pwm.c" \
        || curl -fsSL "$url?h=linux-${up%.*}.y" -o "$C/clk-pwm.c" \
        || die "não consegui baixar o clk-pwm.c"
    grep -q '"pwm-clock"' "$C/clk-pwm.c" || die "clk-pwm.c inesperado"
    echo 'obj-m := clk-pwm.o' > "$C/Kbuild"
    preparar_builder
    log "Compilando clk-pwm.ko para $kver (via qemu)"
    if in_chroot "$BUILDER" "make -C /lib/modules/$kver/build M=/src/clk-pwm-$up modules" \
            > "$WORK/logs/wifi-clk-pwm.log" 2>&1; then
        install -Dm644 "$C/clk-pwm.ko" "$outclk"
        log "clk-pwm.ko OK ($(du -h "$outclk" | cut -f1))"
    else
        tail -n 30 "$WORK/logs/wifi-clk-pwm.log"
        die "falha ao compilar o clk-pwm.ko (log: $WORK/logs/wifi-clk-pwm.log)"
    fi
fi

if [ -f "$out" ]; then
    log "ssv6051.ko já compilado para $kver"
else
    D="$SRC/ssv6051"
    if [ ! -d "$D/.git" ]; then log "Clonando o driver SSV6051"; git clone -q "$SSV6051_REPO" "$D"; fi
    git -C "$D" cat-file -e "$SSV6051_REF^{commit}" 2>/dev/null || git -C "$D" fetch -q origin
    git -C "$D" checkout -q "$SSV6051_REF"
    preparar_builder

    log "Compilando ssv6051.ko para $kver (via qemu)"
    t0=$SECONDS
    if in_chroot "$BUILDER" "cd /src/ssv6051 && export PWD=/src/ssv6051 && make clean >/dev/null 2>&1; make KBUILD_TOP=/src/ssv6051 KVERS_UNAME=$kver -j$JOBS" \
            > "$WORK/logs/wifi-ssv6051.log" 2>&1; then
        install -Dm644 "$D/ssv6051.ko" "$out"
        cp "$D/ssv6051-sw.bin" "$D/ssv6051-wifi.cfg" "$ART/wifi/"
        log "ssv6051.ko OK em $((SECONDS-t0))s ($(du -h "$out" | cut -f1))"
    else
        tail -n 40 "$WORK/logs/wifi-ssv6051.log"
        die "falha ao compilar o driver Wi-Fi (log: $WORK/logs/wifi-ssv6051.log)"
    fi
fi
if [ "$builder_pronto" = 1 ]; then chroot_umount_all; fi

for m in "$out" "$outclk"; do
    vm=$(strings "$m" | sed -n 's/^vermagic=\([^ ]*\).*/\1/p' | head -n1)
    [ "$vm" = "$kver" ] || die "${m##*/} compilado para '$vm', mas o kernel do rootfs é '$kver'"
done

log "Instalando módulos e firmware no rootfs"
install -Dm644 "$out" "$TARGET/lib/modules/$kver/extra/ssv6051.ko"
install -Dm644 "$outclk" "$TARGET/lib/modules/$kver/extra/clk-pwm.ko"
install -Dm644 "$ART/wifi/ssv6051-sw.bin"   "$TARGET/lib/firmware/ssv6051-sw.bin"
install -Dm644 "$ART/wifi/ssv6051-wifi.cfg" "$TARGET/lib/firmware/ssv6051-wifi.cfg"
# depmod do próprio Alpine (via qemu): o do host pode não ler os módulos .ko.gz e
# geraria um índice só com o ssv6051 (nada mais carregaria sozinho no aparelho)
chroot "$TARGET" /sbin/depmod -a "$kver"
n=$(wc -l < "$TARGET/lib/modules/$kver/modules.dep")
[ "$n" -gt 1000 ] || die "índice de módulos suspeito ($n linhas em modules.dep)"
grep -q 'ssv6051' "$TARGET/lib/modules/$kver/modules.alias" \
    && echo "  $n módulos indexados; carga automática pelo ID SDIO: ok" \
    || echo "  (aviso: sem alias SDIO; o stv-wifi carrega o módulo)"
grep -q 'pwm-clock.* clk_pwm' "$TARGET/lib/modules/$kver/modules.alias" \
    && echo "  clk-pwm: carga automática pelo device tree (pwm-clock): ok" \
    || die "clk-pwm.ko sem alias pwm-clock no modules.alias"

# kernel fixo nesta versão (os módulos só servem para ela)
sed -i -E "s/^linux-lts(=.*)?$/linux-lts=$pver/" "$TARGET/etc/apk/world"
grep '^linux-lts' "$TARGET/etc/apk/world"
