#!/bin/sh
# Após cada "apk add/upgrade": se o kernel ou o initramfs mudaram, regenera o
# Image e o uInitrd que o U-Boot de fábrica carrega (sem isso o aparelho
# subiria o kernel antigo com os módulos novos).
[ "$1" = post-commit ] || exit 0
mountpoint -q /boot || exit 0
exec /usr/local/sbin/stv-update-boot /boot
