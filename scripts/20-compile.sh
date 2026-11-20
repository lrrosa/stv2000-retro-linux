#!/bin/bash
# Clona (no host) e compila (no chroot aarch64) o RetroArch enxuto e os cores
# que o Alpine não empacota. Resultado em $ART/{retroarch,cores}.
# Uso: 20-compile.sh [nome ...]   (sem argumentos compila tudo; pula o que já existe)
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"

[ -f "$BUILDER/etc/alpine-release" ] || die "rode 10-builder.sh antes"
mkdir -p "$SRC" "$ART/cores" "$ART/retroarch" "$WORK/logs"

# nome | repositório | ref (vazio = padrão) | comando de build | .so gerado (relativo ao fonte)
CORES=(
"snes9x2010|https://github.com/libretro/snes9x2010||make -j\$J|snes9x2010_libretro.so"
"snes9x|https://github.com/libretro/snes9x||make -C libretro -j\$J|libretro/snes9x_libretro.so"
"genesis_plus_gx|https://github.com/libretro/Genesis-Plus-GX||make -f Makefile.libretro -j\$J|genesis_plus_gx_libretro.so"
"picodrive|https://github.com/libretro/picodrive||make -f Makefile.libretro -j\$J|picodrive_libretro.so"
"pcsx_rearmed|https://github.com/libretro/pcsx_rearmed||make -f Makefile.libretro -j\$J|pcsx_rearmed_libretro.so"
"mednafen_pce_fast|https://github.com/libretro/beetle-pce-fast-libretro||make -j\$J|mednafen_pce_fast_libretro.so"
"fbneo|https://github.com/libretro/FBNeo||make -C src/burner/libretro -j\$J|src/burner/libretro/fbneo_libretro.so"
"mame2003_plus|https://github.com/libretro/mame2003-plus-libretro||make -j\$J|mame2003_plus_libretro.so"
)

clone() {  # nome url ref
    local dir="$SRC/$1" url="$2" ref="$3"
    if [ -d "$dir/.git" ]; then return 0; fi
    log "Clonando $1"
    git clone --depth 1 ${ref:+--branch "$ref"} --recurse-submodules --shallow-submodules "$url" "$dir"
}

# O fonte fica no host (git rápido) e é montado em /src dentro do builder.
chroot_mount "$BUILDER"
private_bind "$SRC" "$BUILDER/src"

wanted() { [ $# -eq 0 ] && return 0; local w; for w in "${SELECTED[@]}"; do [ "$w" = "$1" ] && return 0; done; return 1; }
SELECTED=("$@")

build_core() {  # linha da tabela
    local name url ref cmd so
    IFS='|' read -r name url ref cmd so <<<"$1"
    wanted "$name" || [ ${#SELECTED[@]} -eq 0 ] || return 0
    local out="$ART/cores/${name}_libretro.so"
    if [ -f "$out" ]; then log "$name já compilado"; return 0; fi
    clone "$name" "$url" "$ref"
    log "Compilando core $name ($JOBS jobs, via qemu)"
    local t0=$SECONDS
    if in_chroot "$BUILDER" "cd /src/$name && J=$JOBS && $cmd" > "$WORK/logs/core-$name.log" 2>&1; then
        chroot "$BUILDER" strip --strip-unneeded "/src/$name/$so"
        install -m644 "$SRC/$name/$so" "$out"
        log "$name OK em $((SECONDS-t0))s ($(du -h "$out" | cut -f1))"
    else
        tail -30 "$WORK/logs/core-$name.log"
        die "falha ao compilar $name (log: $WORK/logs/core-$name.log)"
    fi
}

# Aplica patches/<nome>/*.patch na árvore do fonte (pula os já aplicados)
apply_patches() {  # nome
    local d="$SRC/$1" p
    for p in "$PROJ/patches/$1"/*.patch; do
        [ -f "$p" ] || continue
        git -C "$d" apply --reverse --check "$p" 2>/dev/null && continue
        git -C "$d" apply "$p" || die "patch não aplicou: $p"
        log "patch aplicado: $1/$(basename "$p")"
    done
}

build_retroarch() {
    wanted retroarch || [ ${#SELECTED[@]} -eq 0 ] || return 0
    local stamp="$ART/retroarch/.patches" sig
    sig=$(cat "$PROJ"/patches/retroarch/*.patch 2>/dev/null | md5sum | cut -d' ' -f1)
    if [ -x "$ART/retroarch/usr/bin/retroarch" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$sig" ]; then
        log "RetroArch já compilado"; return 0
    fi
    clone retroarch https://github.com/libretro/RetroArch "$RETROARCH_TAG"
    apply_patches retroarch
    if [ -f "$SRC/retroarch/config.mk" ] && [ -x "$ART/retroarch/usr/bin/retroarch" ]; then
        # já configurado antes: só recompila o que os patches mudaram
        log "Recompilando RetroArch (patches novos)"
        local t0=$SECONDS
        in_chroot "$BUILDER" "cd /src/retroarch && make -j$JOBS && rm -rf /tmp/ra-install && make DESTDIR=/tmp/ra-install install" \
            >> "$WORK/logs/retroarch.log" 2>&1 || { tail -40 "$WORK/logs/retroarch.log"; die "falha ao recompilar RetroArch"; }
        chroot "$BUILDER" strip /tmp/ra-install/usr/bin/retroarch
        install -m755 "$BUILDER/tmp/ra-install/usr/bin/retroarch" "$ART/retroarch/usr/bin/retroarch"
        echo "$sig" > "$stamp"
        log "RetroArch OK em $((SECONDS-t0))s"
        return 0
    fi
    log "Compilando RetroArch $RETROARCH_TAG (KMS + GLES2 + udev + ALSA, sem X11/Wayland/Qt/ffmpeg)"
    local want=(
        --disable-qt --disable-x11 --disable-wayland --disable-pulse --disable-jack --disable-oss
        --disable-sdl --disable-sdl2 --disable-ffmpeg --disable-vulkan --disable-opengl1
        --disable-opengl_core --disable-opengles3 --disable-dbus --disable-v4l2 --disable-pipewire
        --disable-discord --disable-update_cores --disable-cg --disable-caca --disable-sixel
        --disable-xvideo --disable-xinerama --disable-xrandr --disable-libdecor --disable-mpv
        --disable-microphone --disable-cdrom
        --enable-opengles --enable-egl --enable-kms --enable-udev --enable-alsa --enable-zlib
    )
    # Passa só as opções que o configure desta versão conhece.
    local help flags=() f
    help=$(in_chroot "$BUILDER" "cd /src/retroarch && ./configure --help" 2>&1 || true)
    for f in "${want[@]}"; do
        local base="${f#--enable-}"; base="${base#--disable-}"
        grep -qE -- "--(enable|disable)-${base}([^a-z0-9_]|$)" <<<"$help" && flags+=("$f")
    done
    echo "flags: ${flags[*]}" > "$WORK/logs/retroarch.log"
    local t0=$SECONDS
    if in_chroot "$BUILDER" "cd /src/retroarch && ./configure --prefix=/usr --sysconfdir=/etc ${flags[*]} && make -j$JOBS && make DESTDIR=/tmp/ra-install install" >> "$WORK/logs/retroarch.log" 2>&1; then
        rm -rf "$ART/retroarch"; mkdir -p "$ART/retroarch"
        cp -a "$BUILDER/tmp/ra-install/." "$ART/retroarch/"
        chroot "$BUILDER" strip /tmp/ra-install/usr/bin/retroarch
        install -m755 "$BUILDER/tmp/ra-install/usr/bin/retroarch" "$ART/retroarch/usr/bin/retroarch"
        echo "$sig" > "$stamp"
        log "RetroArch OK em $((SECONDS-t0))s"
        grep -E '^Checking presence of|^Checking function|KMS|EGL|OPENGLES|UDEV|ALSA' "$WORK/logs/retroarch.log" | grep -Ei 'kms|egl|gles|udev|alsa' | head -20 || true
    else
        tail -40 "$WORK/logs/retroarch.log"
        die "falha ao compilar RetroArch"
    fi
}

build_retroarch
for c in "${CORES[@]}"; do build_core "$c"; done

write_fontes   # revisões exatas dos fontes (GPL); refeito também pelo 50-image.sh
log "Artefatos:"; ls -la "$ART/cores" "$ART/retroarch/usr/bin"; cat "$ART/fontes.txt"
