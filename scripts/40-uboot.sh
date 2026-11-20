#!/bin/bash
# Compila o U-Boot mainline (placa de referência p212, mesma família GXL do S905W)
# para ser carregado em cadeia pelo U-Boot de fábrica (u-boot.ext). É o caminho de boot
# padrão: no STV-2000 o boot direto pelo U-Boot antigo dá tela preta. Gera $ART/u-boot.ext
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"

[ -f "$ART/u-boot.ext" ] && { log "u-boot.ext já existe"; exit 0; }
mkdir -p "$SRC" "$ART"
if [ -z "${UBOOT_TAG:-}" ]; then
    UBOOT_TAG=$(git ls-remote --tags --refs https://github.com/u-boot/u-boot 'v20*' \
        | awk -F/ '{print $NF}' | grep -E '^v[0-9]{4}\.[0-9]{2}$' | sort -V | tail -n 1)
fi
log "U-Boot $UBOOT_TAG"
if [ ! -d "$SRC/u-boot/.git" ]; then
    git clone --depth 1 --branch "$UBOOT_TAG" https://github.com/u-boot/u-boot "$SRC/u-boot"
fi
cd "$SRC/u-boot"
make CROSS_COMPILE=aarch64-linux-gnu- p212_defconfig > "$WORK/logs/uboot.log" 2>&1
make CROSS_COMPILE=aarch64-linux-gnu- -j"$JOBS" >> "$WORK/logs/uboot.log" 2>&1 \
    || { tail -30 "$WORK/logs/uboot.log"; die "falha ao compilar U-Boot"; }
install -m644 u-boot.bin "$ART/u-boot.ext"
echo "$UBOOT_TAG" > "$ART/u-boot.version"
log "u-boot.ext pronto ($(du -h "$ART/u-boot.ext" | cut -f1), $UBOOT_TAG)"
