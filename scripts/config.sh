# Configuração comum do build (incluída pelos outros scripts).
# Pode ser sobrescrita por variáveis de ambiente.

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ALPINE_BRANCH="${ALPINE_BRANCH:-v3.24}"
ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"

WORK="${WORK:-/var/tmp/stv2000}"      # disco ext4 do WSL (rápido)
JOBS="${JOBS:-$(nproc)}"
TOOLS="$WORK/tools"                   # apk.static
BUILDER="${BUILDER:-$WORK/builder}"   # chroot aarch64 para compilar
TARGET="$WORK/rootfs"                 # rootfs final do TV Box
SRC="$WORK/src"                       # fontes clonados (host)
ART="$WORK/artifacts"                 # RetroArch + cores compilados
STAGE="$WORK/stage"                   # partições montadas em arquivos
OUT_DIR="${OUT_DIR:-$PROJ/saida}"     # .img final (pasta do projeto)

RETROARCH_TAG="${RETROARCH_TAG:-v1.22.2}"   # mesma versão dos assets do Alpine 3.24

# Driver comunitário do Wi-Fi interno (iComm SSV6051P, SDIO), portado para o kernel 6.x.
# Commit fixo: o módulo é compilado para a versão exata do kernel da imagem.
SSV6051_REPO="${SSV6051_REPO:-https://github.com/eloirotava/6051}"
SSV6051_REF="${SSV6051_REF:-d6718be301635f9aade72000f978f81aa53acb3a}"

# Device tree padrão (placa de referência p281 = S905W). Alternativas no LEIA-ME.
DTB_DEFAULT="${DTB_DEFAULT:-amlogic/meson-gxl-s905w-p281.dtb}"

HOSTNAME_STV="stv2000"
USER_NAME="gamer"
USER_UID=1000
USER_PASS="${USER_PASS:-retro}"

# Rótulos das partições (o fstab e o boot dependem deles).
LABEL_BOOT="STVBOOT"
LABEL_ROOT="STVROOT"
LABEL_JOGOS="JOGOS"

BOOT_MB=256          # FAT32 de boot
ROOT_FREE_MB=1536    # espaço livre extra no ext4 do sistema
JOGOS_MB=128         # FAT32 de jogos inicial (expande no 1º boot)

# Boot sem texto na TV: mensagens do kernel e do OpenRC só na serial (ttyAML0); a TV
# mostra a tela de abertura (stv-splash). Para ver o texto do boot na TV, acrescente
# "console=tty0" no fim da linha APPEND do extlinux.conf (e tire "quiet").
# video=: 720p desde o boot, o mesmo modo do RetroArch (a TV não troca de modo no meio).
KERNEL_CMDLINE="root=LABEL=$LABEL_ROOT rootfstype=ext4 rootwait rw console=ttyAML0,115200n8 consoleblank=0 quiet loglevel=3 vt.global_cursor_default=0 video=HDMI-A-1:1280x720@60"
