#!/bin/bash
# Gera a imagem do cartão SD:
#   p1  STVBOOT  FAT32  256 MiB  boot (scripts Amlogic, kernel, initrd, dtbs)
#   p2  STVROOT  ext4            sistema Alpine
#   p3  JOGOS    FAT32  128 MiB  jogos/BIOS/saves (expande no 1º boot)
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"

[ -f "$TARGET/boot/vmlinuz-lts" ] || die "rootfs sem kernel (rode 30-rootfs.sh)"
for m in proc sys dev; do mountpoint -q "$TARGET/$m" && { umount -R "$TARGET/$m" || die "não consegui desmontar $TARGET/$m"; }; done
rm -rf "$STAGE"; mkdir -p "$STAGE/boot" "$OUT_DIR"

log "Montando a partição de boot"
B="$STAGE/boot"
rsync -a --no-links --exclude 'System.map-*' "$TARGET/boot/" "$B/"
cp "$PROJ/boot/aml_autoscript.cmd" "$PROJ/boot/s905_autoscript.cmd" "$PROJ/boot/LEIA-ME.txt" "$B/"
sed "s|@DTB@|$DTB_DEFAULT|; s|@CMDLINE@|$KERNEL_CMDLINE|" "$PROJ/boot/uEnv.txt.in" > "$B/uEnv.txt"
mkdir -p "$B/extlinux"
sed "s|@DTB@|$DTB_DEFAULT|; s|@CMDLINE@|$KERNEL_CMDLINE|" "$PROJ/boot/extlinux.conf.in" > "$B/extlinux/extlinux.conf"
[ -f "$ART/u-boot.ext" ] && cp "$ART/u-boot.ext" "$B/u-boot.ext.alternativo"
# Image cru + uInitrd + scripts compilados: o mesmo script que roda no aparelho
PATH="$PATH" sh "$PROJ/overlay/usr/local/sbin/stv-update-boot" "$B"
[ -f "$B/dtbs-lts/$DTB_DEFAULT" ] || die "DTB $DTB_DEFAULT não existe"
# garante que nenhum arquivo ficou mais novo que o Image (o hook do apk compara datas)
touch "$B/Image" "$B/uInitrd" "$B/aml_autoscript" "$B/s905_autoscript"

boot_img="$STAGE/boot.fat"
rm -f "$boot_img"; truncate -s "${BOOT_MB}M" "$boot_img"
mkfs.vfat -F 32 -n "$LABEL_BOOT" "$boot_img" >/dev/null
mcopy -s -p -m -i "$boot_img" "$B"/* ::/

log "Montando a partição JOGOS"
jogos_img="$STAGE/jogos.fat"
rm -f "$jogos_img"; truncate -s "${JOGOS_MB}M" "$jogos_img"
mkfs.vfat -F 32 -S 512 -s 1 -n "$LABEL_JOGOS" "$jogos_img" >/dev/null
mcopy -s -i "$jogos_img" "$TARGET/usr/share/stv2000/jogos-template"/* "$TARGET/usr/share/stv2000/jogos-template"/.stv-modelo ::/

log "Montando a partição do sistema (ext4)"
used_mb=$(du -sm --exclude=./boot --exclude=./proc --exclude=./sys --exclude=./dev "$TARGET" | cut -f1)
root_mb=$(( (used_mb * 110 / 100) + ROOT_FREE_MB ))
root_img="$STAGE/root.ext4"
rm -f "$root_img"; truncate -s "${root_mb}M" "$root_img"
# /boot vazio no ext4 (vira ponto de montagem da partição FAT)
mkdir -p "$STAGE/vazio"; mount --bind "$STAGE/vazio" "$TARGET/boot"; mount --make-private "$TARGET/boot"
trap 'umount "$TARGET/boot" 2>/dev/null || true' EXIT
mkfs.ext4 -q -L "$LABEL_ROOT" -m 1 -E lazy_itable_init=0,lazy_journal_init=0 -d "$TARGET" "$root_img"
umount "$TARGET/boot"; trap - EXIT

log "Juntando tudo no .img"
img="$STAGE/imagem.img"   # nome fixo (usado pelo teste no QEMU)
s_boot=$((16)); s_root=$((16 + BOOT_MB)); s_jogos=$((s_root + root_mb))
total_mb=$((s_jogos + JOGOS_MB + 1))
rm -f "$img.tmp"; truncate -s "${total_mb}M" "$img.tmp"
sfdisk -q "$img.tmp" <<EOF
label: dos
start=${s_boot}MiB, size=${BOOT_MB}MiB, type=c, bootable
start=${s_root}MiB, size=${root_mb}MiB, type=83
start=${s_jogos}MiB, size=${JOGOS_MB}MiB, type=c
EOF
dd if="$boot_img"  of="$img.tmp" bs=1M seek="$s_boot"  conv=notrunc,sparse status=none
dd if="$root_img"  of="$img.tmp" bs=1M seek="$s_root"  conv=notrunc,sparse status=none
dd if="$jogos_img" of="$img.tmp" bs=1M seek="$s_jogos" conv=notrunc,sparse status=none
mv -f "$img.tmp" "$img"
rm -f "$boot_img" "$root_img" "$jogos_img"
sfdisk -l "$img"

# Nomes de distribuição: stv2000-retro-linux-AAAAMMDD.img(.xz) + .sha256 + fontes.txt
nome="stv2000-retro-linux-$(date +%Y%m%d)"
log "Comprimindo ($nome.img.xz)"
rm -f "$STAGE"/stv2000-retro-linux-*
cp --sparse=always "$img" "$STAGE/$nome.img"
xz -T0 -6 -k -f "$STAGE/$nome.img"
( cd "$STAGE" && sha256sum "$nome.img" "$nome.img.xz" > "$nome.sha256" )
write_fontes && cp "$ART/fontes.txt" "$STAGE/$nome-fontes.txt"
log "Copiando para $OUT_DIR"
rm -f "$OUT_DIR"/stv2000-retro-linux-* "$OUT_DIR"/alpine-stv2000.img*
cp -f "$STAGE/$nome".* "$STAGE/$nome"-* "$OUT_DIR/" 2>/dev/null || cp -f "$STAGE/$nome".* "$OUT_DIR/"
rm -f "$STAGE/$nome.img"
log "Imagem pronta: $OUT_DIR/$nome.img ($(du -h --apparent-size "$img" | cut -f1), .xz: $(du -h "$STAGE/$nome.img.xz" | cut -f1)); sistema usa ${used_mb} MiB de ${root_mb} MiB"
