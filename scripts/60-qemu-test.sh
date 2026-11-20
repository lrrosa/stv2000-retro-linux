#!/bin/bash
# Teste do sistema no QEMU (máquina "virt" aarch64). Não testa o boot Amlogic nem os
# drivers do S905W, mas valida o userland: initramfs/root por LABEL, OpenRC, 1º boot
# (expansão da partição JOGOS, wifi.txt preservado), login automático, geração das
# listas e o RetroArch (renderização por software no QEMU; no aparelho é a GPU lima).
# Uso: 60-qemu-test.sh [segundos por boot]
#   REUSAR=1  pula a cópia da imagem e o 1º boot (reaproveita o teste.img anterior)
set -euo pipefail
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/lib.sh"
SECS="${1:-240}"
Q="$WORK/qemu"; mkdir -p "$Q"
IMG="$Q/teste.img"
B="$STAGE/boot"
M="$Q/mnt"; mkdir -p "$M"
[ -f "$STAGE/imagem.img" ] || die "rode 50-image.sh antes"

monitor() { python3 - "$Q/mon.sock" "$1" <<'PY'
import socket, sys, time
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); time.sleep(0.3); s.recv(65536)
s.sendall((sys.argv[2] + "\n").encode()); time.sleep(1.5); s.close()
PY
}
tela() { monitor "screendump $Q/tela-$1.png -f png" || true; }
# Comando de rede do RetroArch (UDP 55355, redirecionado pelo QEMU). Mais confiável que
# teclas: emulado, o RetroArch desenha poucos quadros por segundo e perde toques curtos.
ra() {  # comando [vezes]
    local i
    for ((i = 0; i < ${2:-1}; i++)); do
        python3 -c 'import socket,sys; socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(sys.argv[1].encode(), ("127.0.0.1", 55355))' "$1"
        sleep 4
    done
}
# liga a interface de comandos só na cópia de teste
ra_cmd_on() {
    local cfg="$M/home/gamer/.config/retroarch/retroarch.cfg" k
    mount -o loop,offset="$(part_off 2)" "$IMG" "$M"
    for k in 'network_cmd_enable = "true"' 'network_cmd_port = "55355"'; do
        if grep -q "^${k%% =*} =" "$cfg"; then sed -i "s/^${k%% =*} = .*/$k/" "$cfg"; else echo "$k" >> "$cfg"; fi
    done
    umount "$M"
}

# Percorre as abas do menu e fotografa cada uma.
# Ordem das abas: Menu principal, Configurações, Histórico, Favoritos, sistemas...
# OK é o MENU_B: no RetroArch 1.22 os botões OK/Cancelar vêm trocados por padrão
# (OK = botão de baixo do RetroPad, que é o "B"); MENU_A volta.
navegar() {
    local aba
    for aba in 3-aba-configuracoes 4-aba-historico 5-aba-favoritos 6-aba-nes 7-aba-snes 8-aba-psx; do
        ra MENU_RIGHT; sleep 8; tela "$aba"
    done
    ra MENU_B; sleep 8; tela 9-menu-do-jogo
}

# Compartilhamento de rede (Samba, TCP 445 redirecionado para 14450): com o RetroArch
# aberto sem nenhum jogo, envia um jogo como anônimo. A lista deve ser criada sozinha e
# o RetroArch reaberto com a aba nova. Testa também o login gamer e uma senha errada.
smb_teste() {
    if ! command -v smbclient >/dev/null; then
        echo "(smbclient ausente no host: teste do compartilhamento pulado)"; return 0
    fi
    local s=(smbclient //127.0.0.1/JOGOS -p 14450 -m SMB3)
    printf 'teste' > "$Q/jogo-rede.nes"
    echo "--- SMB anônimo: enviando roms/nes/Jogo Pela Rede (Brasil).nes"
    "${s[@]}" -N -c "cd roms/nes; put $Q/jogo-rede.nes \"Jogo Pela Rede (Brasil).nes\"; ls" \
        || echo "FALHA: acesso anônimo"
    echo "--- SMB com o usuário gamer:"
    "${s[@]}" -U "$USER_NAME%$USER_PASS" -c 'ls' | head -n 4 || echo "FALHA: login gamer"
    echo "--- SMB com senha errada (deve ser recusado):"
    if "${s[@]}" -U "$USER_NAME%errada" -c 'ls' >/dev/null 2>&1; then
        echo "FALHA: aceitou senha errada"
    else
        echo "ok: recusado"
    fi
    sleep 100; tela 1b-jogo-pela-rede
}

boot_qemu() {  # nome [função a rodar com o sistema no ar]
    local name="$1" extra="${2:-}"
    rm -f "$Q/mon.sock" "$Q/serial-$name.log"
    qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 1024 \
        -kernel "$B/Image" -initrd "$B/initramfs-lts" \
        -append "root=LABEL=$LABEL_ROOT rootfstype=ext4 rootwait rw console=ttyAMA0 quiet loglevel=3 vt.global_cursor_default=0 net.ifnames=0" \
        -drive file="$IMG",format=raw,if=none,id=hd0 -device virtio-blk-pci,drive=hd0 \
        -device virtio-gpu-pci,xres=1280,yres=720 -device qemu-xhci -device usb-kbd \
        -netdev user,id=n0,hostfwd=udp:127.0.0.1:55355-:55355,hostfwd=tcp:127.0.0.1:14450-:445 \
        -device virtio-net-pci,netdev=n0 \
        -display none -serial file:"$Q/serial-$name.log" \
        -monitor unix:"$Q/mon.sock",server,nowait &
    local pid=$!
    log "QEMU ($name) rodando por ${SECS}s..."
    # tela de abertura (stv-splash), antes do RetroArch abrir. No QEMU ela fica uns 10 s,
    # por volta dos 45-60 s (antes disso a saída de vídeo nem está ativa): tenta até pegar
    local _
    sleep 36
    for _ in 1 2 3 4 5 6; do
        sleep 3; tela "$name-abertura"
        [ "$(stat -c %s "$Q/tela-$name-abertura.png" 2>/dev/null || echo 0)" -gt 100000 ] && break
    done
    sleep $((SECS - 66))
    tela "$name"
    if [ -n "$extra" ]; then "$extra"; fi
    sleep 2
    monitor "system_powerdown" || true
    for _ in $(seq 60); do kill -0 $pid 2>/dev/null || break; sleep 1; done
    kill $pid 2>/dev/null || true; wait $pid 2>/dev/null || true
}

part_off() {  # n -> offset em bytes
    sfdisk -J "$IMG" | python3 -c "import json,sys; p=json.load(sys.stdin)['partitiontable']['partitions'][$1-1]; print(p['start']*512)"
}

if [ "${REUSAR:-0}" != 1 ]; then
    log "Copiando a imagem para o teste e simulando um cartão de 8 GB"
    rm -f "$Q"/tela-*.png
    cp --sparse=always "$STAGE/imagem.img" "$IMG"
    truncate -s 8G "$IMG"

    log "Mexendo na JOGOS antes do 1º boot, como no Windows (wifi.txt, um arquivo, a pasta do Windows)"
    mount -o loop,offset="$(part_off 3)" "$IMG" "$M"
    printf 'REDE=Rede de Teste\r\nSENHA=senha12345\r\n' > "$M/wifi.txt"
    # arquivo do usuário fora de roms/ (não gera lista: o teste do Samba precisa do menu vazio)
    printf 'bios de teste' > "$M/bios/teste-antes-do-boot.bin"
    mkdir -p "$M/System Volume Information"; printf 'x' > "$M/System Volume Information/WPSettings.dat"
    umount "$M"

    boot_qemu 1-primeiro-boot smb_teste
    log "Partições depois do 1º boot:"; sfdisk -l "$IMG" | tail -n 4

    log "Colocando jogos de teste na partição JOGOS (arquivos fictícios)"
    mount -o loop,offset="$(part_off 3)" "$IMG" "$M"
    df -h "$M" | tail -n 1
    ls "$M" "$M/roms" | head -n 40
    echo "--- wifi.txt depois da expansão (deve manter a rede de teste):"; tr -d '\r' < "$M/wifi.txt"
    echo "--- roms/nes (deve ter o jogo enviado pela rede):"; ls -la "$M/roms/nes"
    echo "--- arquivo de antes do 1º boot (deve continuar lá) e pasta do Windows (não deve):"
    ls -la "$M/bios/teste-antes-do-boot.bin" || echo "FALHA: arquivo do usuário perdido na expansão"
    [ -e "$M/System Volume Information" ] && echo "(System Volume Information voltou)" || echo "ok: sem System Volume Information"
    printf 'teste' > "$M/roms/nes/Jogo de Teste (Brasil).nes"
    printf 'teste' > "$M/roms/snes/Super Mario World (USA).sfc"
    printf 'teste' > "$M/roms/snes/Outro Jogo (Europe) (Rev 1).sfc"
    printf 'teste' > "$M/roms/psx/Disco 1.cue"; printf 'teste' > "$M/roms/psx/Disco 2.cue"
    printf 'Disco 1.cue\r\nDisco 2.cue\r\n' > "$M/roms/psx/Jogo Multidisco.m3u"
    umount "$M"
fi

ra_cmd_on
boot_qemu 2-com-jogos navegar

log "Inspecionando o sistema depois dos boots"
rm -f "$OUT_DIR"/tela-*.png; cp -f "$Q"/tela-*.png "$OUT_DIR/" 2>/dev/null || true
# o QEMU é desligado à força (sem botão de energia ACPI): montar com escrita deixa o
# ext4 aplicar o journal pendente (é só a cópia de teste)
mount -o loop,offset="$(part_off 2)" "$IMG" "$M"
H="$M/home/gamer"
echo "--- playlists:"; ls -la "$H/.config/retroarch/playlists/" || true
for f in "$H"/.config/retroarch/playlists/*.lpl; do
    if [ -f "$f" ]; then echo "## $f"; cat "$f"; fi
done
echo "--- playlists.log:"; cat "$H/.cache/playlists.log" 2>/dev/null || true
echo "--- stv-session.log:"; tail -n 20 "$H/.cache/stv-session.log" 2>/dev/null || true
echo "--- samba (log.smbd):"; tail -n 15 "$M/var/log/samba/log.smbd" 2>/dev/null || true
echo "--- retroarch.log (fim):"; tail -n 40 "$H/.cache/retroarch.log" 2>/dev/null || true
echo "--- syslog (stv/erros):"; grep -aEi 'stv-|error|fail' "$M/var/log/messages" 2>/dev/null | tail -n 40 || true
umount "$M"
log "Telas salvas em $Q/tela-*.png e $OUT_DIR; logs seriais em $Q/serial-*.log"
