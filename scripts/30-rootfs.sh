#!/bin/bash
# Monta o rootfs final do TV Box (Alpine aarch64) em $TARGET.
#   fase "pkgs"   : instala pacotes (kernel, mesa/lima, áudio, cores do Alpine...)
#   fase "config" : copia RetroArch/cores compilados, overlay e configura o sistema
# Uso: 30-rootfs.sh [pkgs|config|all]
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"
PHASE="${1:-all}"

PKGS=(
    # base e boot
    alpine-base mkinitfs linux-lts linux-firmware-none u-boot-tools kmod
    e2fsprogs e2fsprogs-extra dosfstools sfdisk partx findmnt blkid exfatprogs ntfs-3g
    eudev eudev-openrc udev-init-scripts udev-init-scripts-openrc zram-init
    tzdata chrony openssh-server openssh-sftp-server doas nano
    # Wi-Fi (driver do SSV6051P vem do 35-wifi.sh; serve também para dongles USB)
    wpa_supplicant wireless-regdb iw
    # gráfico (Mali-450 = driver lima do Mesa, saída direta em KMS) e áudio
    mesa-dri-gallium mesa-egl mesa-gles mesa-gbm libdrm eudev-libs zlib libstdc++
    alsa-lib alsa-utils alsa-utils-openrc
    # dados do RetroArch (menus, perfis de controle, info dos cores, base de dados)
    retroarch-assets retroarch-joypad-autoconfig libretro-core-info libretro-database
    # cores já empacotados pelo Alpine
    libretro-fceumm libretro-nestopia libretro-gambatte libretro-gpsp libretro-mgba
    libretro-stella2014 libretro-prosystem libretro-handy libretro-beetle-ngp
    libretro-beetle-wswan libretro-fmsx libretro-vecx libretro-dosbox libretro-pokemini
)

phase_pkgs() {
    bootstrap_alpine "$TARGET"
    # initramfs enxuto, com o que o S905W (cartão SD/USB) e o teste no QEMU (virtio) precisam
    mkdir -p "$TARGET/etc/mkinitfs/features.d"
    cat > "$TARGET/etc/mkinitfs/mkinitfs.conf" <<'EOF'
features="base ext4 mmc usb virtio meson"
EOF
    cat > "$TARGET/etc/mkinitfs/features.d/meson.modules" <<'EOF'
kernel/drivers/mmc/host/meson*
kernel/drivers/mmc/core/pwrseq*
kernel/drivers/clk/meson
kernel/drivers/pinctrl/meson
kernel/drivers/soc/amlogic
kernel/drivers/phy/amlogic
kernel/drivers/regulator/gpio-regulator.ko*
kernel/drivers/regulator/fixed.ko*
kernel/drivers/usb/dwc2
kernel/drivers/usb/dwc3
kernel/fs/vfat
kernel/fs/fat
kernel/fs/nls/nls_cp437.ko*
kernel/fs/nls/nls_iso8859-1.ko*
kernel/fs/nls/nls_utf8.ko*
EOF
    chroot_mount "$TARGET"
    log "Instalando pacotes do sistema final"
    apk_root "$TARGET" -U add "${PKGS[@]}"
    log "Kernel instalado:"; ls -la "$TARGET/boot"
}

phase_config() {
    [ -f "$TARGET/etc/alpine-release" ] || die "rode a fase pkgs antes"
    [ -x "$ART/retroarch/usr/bin/retroarch" ] || die "RetroArch não compilado (20-compile.sh)"
    chroot_mount "$TARGET"

    log "Copiando RetroArch e cores compilados"
    install -m755 "$ART/retroarch/usr/bin/retroarch" "$TARGET/usr/bin/retroarch"
    [ -f "$ART/retroarch/etc/retroarch.cfg" ] && install -m644 "$ART/retroarch/etc/retroarch.cfg" "$TARGET/etc/retroarch.cfg"
    mkdir -p "$TARGET/usr/lib/libretro"
    install -m644 "$ART"/cores/*_libretro.so "$TARGET/usr/lib/libretro/"

    log "Aplicando overlay de configuração"
    cp -a "$PROJ/overlay/." "$TARGET/"
    chmod 755 "$TARGET"/usr/local/bin/* "$TARGET"/usr/local/sbin/* "$TARGET"/etc/local.d/*.start \
              "$TARGET"/etc/apk/commit_hooks.d/*.sh
    chmod 600 "$TARGET/etc/doas.d/stv2000.conf"
    sed -i "s/@HOSTNAME@/$HOSTNAME_STV/g" "$TARGET/etc/hostname" "$TARGET/etc/hosts"
    sed -i "s/@LABEL_BOOT@/$LABEL_BOOT/; s/@LABEL_ROOT@/$LABEL_ROOT/; s/@LABEL_JOGOS@/$LABEL_JOGOS/" "$TARGET/etc/fstab"
    # zram: só o swap comprimido (o padrão também cria /tmp e /var/tmp em zram)
    sed -i 's/^num_devices=.*/num_devices=1/' "$TARGET/etc/conf.d/zram-init"

    log "Usuário $USER_NAME (login automático no RetroArch)"
    in_chroot "$TARGET" "
        id $USER_NAME >/dev/null 2>&1 || adduser -D -u $USER_UID -s /bin/sh -g 'Jogador' $USER_NAME
        for g in video input audio wheel; do addgroup $USER_NAME \$g >/dev/null 2>&1 || true; done
        echo '$USER_NAME:$USER_PASS' | chpasswd
        passwd -l root >/dev/null 2>&1 || true
        id $USER_NAME
    " || die "falha ao criar o usuário $USER_NAME"
    cp -a "$PROJ/overlay-home/." "$TARGET/home/$USER_NAME/"
    mkdir -p "$TARGET/home/$USER_NAME/.config/retroarch/playlists" "$TARGET/home/$USER_NAME/.cache"
    chown -R $USER_UID:$USER_UID "$TARGET/home/$USER_NAME"
    mkdir -p "$TARGET/media/jogos"

    log "Template da partição JOGOS"
    bash "$PROJ/scripts/gen-jogos-template.sh" "$TARGET/usr/share/stv2000/systems.conf" "$TARGET/usr/share/stv2000/jogos-template"

    log "Interface: fundos por sistema e limpeza dos assets"
    local A="$TARGET/usr/share/libretro/assets" es="emulationstation blured/1280x720"
    local F="$TARGET/usr/share/stv2000/fundos" db img
    rm -rf "$F"; mkdir -p "$F"
    grep -v '^#' "$TARGET/usr/share/stv2000/systems.conf" | cut -d'|' -f2 | while read -r db; do
        [ -n "$db" ] || continue
        img="$db.png"; [ -f "$A/wallpapers/$es/$img" ] || img="${db%% *}.png"   # "MAME 2003-Plus" -> MAME.png
        if [ -f "$A/wallpapers/$es/$img" ]; then
            ln -s "/usr/share/libretro/assets/wallpapers/$es/$img" "$F/$db.png"
        else
            echo "  (sem fundo para $db: usa o fundo do Menu principal)"
        fi
    done
    # abas Menu principal / Configurações / Histórico / Favoritos (e submenus)
    python3 "$PROJ/scripts/gen-fundos.py" "$A/xmb/monochrome/png" "$F" || die "falha ao gerar os fundos"
    # outros conjuntos de fundos e temas de outras plataformas (3DS, Switch): ~80 MB
    rm -rf "$A/wallpapers/nosh" "$A/wallpapers/blurred-consoles" "$A/wallpapers/bichromatic pads" \
           "$A/wallpapers/posterized consoles" "$A/switch" "$A/nxrgui" "$A/ctr"
    find "$A" -name '*.xcf' -delete

    log "Serviços OpenRC"
    in_chroot "$TARGET" '
        add() { lvl=$1; shift; for s in "$@"; do
            [ -e /etc/init.d/$s ] || { echo "serviço inexistente: $s"; exit 1; }
            rc-update add $s $lvl >/dev/null 2>&1 || true
        done; }
        add sysinit devfs dmesg udev udev-trigger udev-settle
        add boot modules sysctl hostname bootmisc syslog swclock seedrng zram-init
        add default udev-postmount networking chronyd sshd alsa local crond
        add shutdown killprocs mount-ro savecache
        # udev no lugar do mdev; sem hwclock (não há RTC útil), relógio via chrony
        for s in mdev hwdrivers; do rc-update del $s sysinit >/dev/null 2>&1 || true; done
        rc-update del hwclock boot >/dev/null 2>&1 || true
        rc-update show
    ' || die "falha ao configurar serviços"
    # fuso horário
    in_chroot "$TARGET" "ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && echo America/Sao_Paulo > /etc/timezone"

    log "Gerando initramfs"
    local kver; kver=$(ls "$TARGET/lib/modules" | sort -V | tail -1)
    in_chroot "$TARGET" "mkinitfs -o /boot/initramfs-lts $kver" >/dev/null
    echo "$kver" > "$WORK/kernel-version"
    rm -f "$TARGET/etc/resolv.conf"
    log "Rootfs pronto ($(du -sh --exclude=proc --exclude=sys --exclude=dev "$TARGET" | cut -f1))"
}

case "$PHASE" in
    pkgs) phase_pkgs ;;
    config) phase_config ;;
    all) phase_pkgs; phase_config ;;
    *) die "fase desconhecida: $PHASE" ;;
esac
