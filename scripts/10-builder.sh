#!/bin/bash
# Cria o chroot Alpine aarch64 usado só para compilar RetroArch e cores (roda via qemu-user).
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"

bootstrap_alpine "$BUILDER"
log "Instalando dependências de compilação no builder"
apk_root "$BUILDER" add \
    build-base git bash coreutils findutils grep sed gawk diffutils patch pkgconf \
    linux-headers zlib-dev mesa-dev libdrm-dev alsa-lib-dev eudev-dev
log "Builder pronto: $(cat "$BUILDER/etc/alpine-release")"
