#!/bin/bash
# Wi-Fi interno do STV-2000 (iComm SSV6051P, ligado por SDIO): compila o driver
# comunitário (fora da árvore do kernel) para a versão exata do kernel do rootfs e
# instala módulo + firmware. Roda depois do 30-rootfs.sh.
# O kernel fica fixo no /etc/apk/world: um "apk upgrade" com kernel novo deixaria o
# módulo sem par. Para atualizar o kernel, gere uma imagem nova.
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

if [ -f "$out" ]; then
    log "ssv6051.ko já compilado para $kver"
else
    D="$SRC/ssv6051"
    if [ ! -d "$D/.git" ]; then log "Clonando o driver SSV6051"; git clone -q "$SSV6051_REPO" "$D"; fi
    git -C "$D" cat-file -e "$SSV6051_REF^{commit}" 2>/dev/null || git -C "$D" fetch -q origin
    git -C "$D" checkout -q "$SSV6051_REF"

    log "Headers do kernel $pver no builder"
    apk_root "$BUILDER" add "linux-lts-dev=$pver"
    chroot_mount "$BUILDER"
    private_bind "$SRC" "$BUILDER/src"

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
    chroot_umount_all
fi

vm=$(strings "$out" | sed -n 's/^vermagic=\([^ ]*\).*/\1/p' | head -n1)
[ "$vm" = "$kver" ] || die "módulo compilado para '$vm', mas o kernel do rootfs é '$kver'"

log "Instalando módulo e firmware no rootfs"
install -Dm644 "$out" "$TARGET/lib/modules/$kver/extra/ssv6051.ko"
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

# kernel fixo nesta versão (o módulo só serve para ela)
sed -i -E "s/^linux-lts(=.*)?$/linux-lts=$pver/" "$TARGET/etc/apk/world"
grep '^linux-lts' "$TARGET/etc/apk/world"
