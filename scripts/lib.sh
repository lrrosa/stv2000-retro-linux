# Funções auxiliares (incluídas pelos outros scripts).

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERRO: %s\033[0m\n' "$*" >&2; exit 1; }

# Baixa o apk.static (x86_64) do repositório oficial, uma única vez.
ensure_apk_static() {
    [ -x "$TOOLS/apk.static" ] && return 0
    mkdir -p "$TOOLS/tmp"
    local idx="$TOOLS/tmp/APKINDEX.tar.gz" ver
    curl -fsSL "$ALPINE_MIRROR/$ALPINE_BRANCH/main/x86_64/APKINDEX.tar.gz" -o "$idx"
    ver=$(tar -xzOf "$idx" APKINDEX | awk 'BEGIN{RS="";FS="\n"} /\nP:apk-tools-static\n/{for(i=1;i<=NF;i++) if($i~/^V:/) print substr($i,3)}')
    [ -n "$ver" ] || die "não achei apk-tools-static no índice"
    log "Baixando apk-tools-static $ver"
    curl -fsSL "$ALPINE_MIRROR/$ALPINE_BRANCH/main/x86_64/apk-tools-static-$ver.apk" -o "$TOOLS/tmp/apk.apk"
    tar -xzf "$TOOLS/tmp/apk.apk" -C "$TOOLS/tmp" sbin/apk.static 2>/dev/null || true
    [ -f "$TOOLS/tmp/sbin/apk.static" ] || die "falha ao extrair apk.static"
    install -m755 "$TOOLS/tmp/sbin/apk.static" "$TOOLS/apk.static"
    "$TOOLS/apk.static" --version
}

# apk do host operando dentro de um rootfs aarch64 (scripts rodam via qemu/binfmt).
apk_root() {
    local root="$1"; shift
    "$TOOLS/apk.static" --root "$root" --arch aarch64 --no-progress "$@"
}

# Cria um rootfs Alpine mínimo em $1.
bootstrap_alpine() {
    local root="$1"
    ensure_apk_static
    if [ -f "$root/etc/alpine-release" ]; then
        log "rootfs já existe em $root (Alpine $(cat "$root/etc/alpine-release"))"
        return 0
    fi
    log "Criando rootfs Alpine $ALPINE_BRANCH aarch64 em $root"
    mkdir -p "$root/etc/apk"
    printf '%s/%s/main\n%s/%s/community\n' "$ALPINE_MIRROR" "$ALPINE_BRANCH" "$ALPINE_MIRROR" "$ALPINE_BRANCH" \
        > "$root/etc/apk/repositories"
    # Primeira instalação: as chaves ainda não existem no rootfs; o transporte é HTTPS
    # do CDN oficial. Depois disso todas as operações verificam assinatura.
    apk_root "$root" --initdb -U --allow-untrusted add alpine-keys
    apk_root "$root" -U add alpine-base
    cp -L /etc/resolv.conf "$root/etc/resolv.conf"
}

# Monta /proc, /sys e /dev no chroot (com desmontagem garantida via trap).
# IMPORTANTE: no WSL/systemd as montagens são "shared"; um bind simples de /dev
# seguido de umount propagaria a desmontagem para o /dev do próprio Ubuntu.
# Por isso: --rbind + --make-rslave (recebe do host, nunca devolve) e umount -R.
CHROOT_MOUNTS=()
chroot_mount() {
    local root="$1" m
    for m in proc sys dev; do
        mkdir -p "$root/$m"
        mountpoint -q "$root/$m" && continue
        case $m in
            proc) mount -t proc proc "$root/proc" ;;
            sys)  mount --rbind /sys "$root/sys"; mount --make-rslave "$root/sys" ;;
            dev)  mount --rbind /dev "$root/dev"; mount --make-rslave "$root/dev" ;;
        esac
        CHROOT_MOUNTS+=("$root/$m")
    done
    trap chroot_umount_all EXIT
}
# bind privado (ex.: fontes em /src do builder)
private_bind() {
    mkdir -p "$2"
    mountpoint -q "$2" && return 0
    mount --bind "$1" "$2"; mount --make-private "$2"
    CHROOT_MOUNTS+=("$2")
}
chroot_umount_all() {
    local i m
    for (( i=${#CHROOT_MOUNTS[@]}-1; i>=0; i-- )); do
        m="${CHROOT_MOUNTS[$i]}"
        # só desmonta caminhos dentro de $WORK (proteção extra)
        case "$m" in "$WORK"/*) umount -R "$m" 2>/dev/null || umount -R -l "$m" 2>/dev/null || true ;; esac
    done
    CHROOT_MOUNTS=()
}

# Revisões exatas dos fontes compilados (exigência da GPL ao distribuir binários)
write_fontes() {
    local d n p
    mkdir -p "$ART"
    {
        echo "# Fontes usados nos binários compilados (repositório + commit)"
        for d in "$SRC"/*/; do
            [ -d "$d/.git" ] || continue
            n=$(basename "$d")
            printf '%-18s %s %s\n' "$n" "$(git -C "$d" config --get remote.origin.url)" "$(git -C "$d" rev-parse HEAD)"
            for p in "$PROJ/patches/$n"/*.patch; do
                if [ -f "$p" ]; then printf '%-18s   + patch %s\n' "" "patches/$n/$(basename "$p")"; fi
            done
        done
    } > "$ART/fontes.txt"
}

in_chroot() {
    local root="$1"; shift
    chroot "$root" /usr/bin/env -i HOME=/root TERM=xterm PATH=/usr/sbin:/usr/bin:/sbin:/bin /bin/sh -c "$*"
}
