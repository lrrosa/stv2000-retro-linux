# ~/.profile do jogador
export PATH="$PATH:/usr/local/bin:/usr/local/sbin"

# Na TV (tty1) abre direto o RetroArch; por SSH ou nos outros terminais, shell normal.
if [ "$(tty)" = /dev/tty1 ] && [ -z "$SSH_CONNECTION" ]; then
    /usr/local/bin/stv-session
fi
