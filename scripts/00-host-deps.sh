#!/bin/bash
# Instala as ferramentas de build no Ubuntu (WSL2). Rodar como root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    qemu-user qemu-user-binfmt qemu-system-arm \
    build-essential gcc-aarch64-linux-gnu make bison flex bc libssl-dev libgnutls28-dev \
    python3-dev python3-setuptools python3-pyelftools python3-pil swig \
    device-tree-compiler u-boot-tools \
    dosfstools e2fsprogs fdisk mtools \
    git wget curl xz-utils ca-certificates rsync file cpio \
    smbclient
# (smbclient: só para o teste do compartilhamento de rede no QEMU)

# Garante que o binfmt do aarch64 está registrado (necessário para o chroot).
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    systemctl restart systemd-binfmt 2>/dev/null || true
fi
echo "binfmt qemu-aarch64:"; cat /proc/sys/fs/binfmt_misc/qemu-aarch64
echo "interpretador:"; file -L "$(awk '/^interpreter/{print $2}' /proc/sys/fs/binfmt_misc/qemu-aarch64)"
for c in qemu-system-aarch64 aarch64-linux-gnu-gcc mkimage mkfs.vfat mkfs.ext4 mcopy sfdisk dtc git; do
    command -v "$c" >/dev/null || { echo "FALTA: $c"; exit 1; }
done
python3 -c 'import PIL' || { echo "FALTA: python3-pil (gera os fundos do menu)"; exit 1; }
echo "OK: ferramentas do host prontas"
