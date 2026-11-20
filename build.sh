#!/bin/bash
# Build completo da imagem Alpine para o TV Box Aquário STV-2000 (Amlogic S905W).
# Rodar no WSL2 (Ubuntu) como root:
#   wsl -d Ubuntu -u root -- bash "/mnt/f/.../alpine-stv2000/build.sh"
# Etapas (podem ser rodadas isoladas, cada uma pula o que já está pronto):
#   00 ferramentas do host   10 chroot de compilação   20 RetroArch + cores
#   30 rootfs final          35 driver Wi-Fi SSV6051P  40 U-Boot mainline
#   50 imagem .img           60 teste QEMU
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)/scripts"
source "$D/config.sh"
mkdir -p "$WORK/logs"
run() { echo ">>> $1"; bash "$D/$1" "${@:2}" 2>&1 | tee "$WORK/logs/$1.log"; }

run 00-host-deps.sh
run 10-builder.sh
run 20-compile.sh
run 30-rootfs.sh all
run 35-wifi.sh
run 40-uboot.sh
run 50-image.sh
[ "${SEM_TESTE:-0}" = 1 ] || run 60-qemu-test.sh
echo "Pronto:"; ls -la "$OUT_DIR"/stv2000-retro-linux-*
