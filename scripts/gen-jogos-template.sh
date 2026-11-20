#!/bin/bash
# Gera a estrutura de pastas da partição JOGOS a partir do systems.conf.
# Uso: gen-jogos-template.sh <systems.conf> <pasta destino>
set -euo pipefail
CONF="$1"; DEST="$2"
rm -rf "$DEST"; mkdir -p "$DEST"/{roms,bios,saves,states,screenshots,thumbnails}

crlf() { sed 's/$/\r/'; }   # o Bloco de Notas do Windows agradece

{
cat <<'EOF'
==========================================================================
  STV-2000 - Partição JOGOS
==========================================================================

Coloque os jogos (ROMs) na pasta do sistema correspondente, dentro de "roms".
As listas do RetroArch são atualizadas sozinhas e os jogos aparecem no menu,
cada sistema com o emulador (core) certo.

Pela rede, sem tirar o cartão (aparelho ligado, com cabo de rede ou Wi-Fi):
  no PC, abra  \\STV2000\JOGOS  (ou \\<IP do aparelho>\JOGOS), sem senha.
  O Windows 11 24H2 ou mais novo bloqueia pasta sem senha. Rode uma vez no
  PowerShell do PC:  cmdkey /add:STV2000 /user:gamer /pass:retro

Usuário e senha do sistema (SSH/SFTP): gamer / retro (troque com "passwd").
O menu de jogos e a pasta na rede não pedem senha.

  roms\         jogos, uma pasta por sistema (tabela abaixo)
  bios\         arquivos de BIOS exigidos por alguns sistemas
  saves\        jogos salvos (memória do cartucho), separados por emulador
  states\       "save states" do RetroArch
  screenshots\  capturas de tela
  thumbnails\   capas/imagens baixadas pelo RetroArch
  wifi.txt      nome e senha da rede Wi-Fi (opcional)

Dicas:
 - Arquivos .zip e .7z funcionam (exceto arcade: deixe o .zip original).
 - Arcade (FBNeo/MAME): use o romset certo; o neogeo.zip vai junto dos jogos.
 - PlayStation / Mega-CD / PC Engine CD: use .cue+.bin ou .chd. Jogos com
   vários discos: crie um .m3u listando os discos (um por linha).
 - Limite do FAT32: 4 GB por arquivo (sobra para todos estes sistemas).
 - Ejete o cartão com segurança no Windows antes de tirar do PC.

--------------------------------------------------------------------------
 Pasta          Sistema                                 Extensões
--------------------------------------------------------------------------
EOF
grep -v '^#' "$CONF" | while IFS='|' read -r dir db core exts desc bios; do
    [ -n "$dir" ] || continue
    printf ' %-14s %-39s %s\n' "$dir" "$desc" "$exts"
done
cat <<'EOF'

--------------------------------------------------------------------------
 BIOS (copie para a pasta bios\ com estes nomes exatos)
--------------------------------------------------------------------------
EOF
grep -v '^#' "$CONF" | while IFS='|' read -r dir db core exts desc bios; do
    if [ -n "$dir" ] && [ "$bios" != "-" ]; then printf ' %-14s %s\n' "$dir" "$bios"; fi
done
} | crlf > "$DEST/LEIA-ME.txt"

grep -v '^#' "$CONF" | while IFS='|' read -r dir db core exts desc bios; do
    [ -n "$dir" ] || continue
    mkdir -p "$DEST/roms/$dir"
    {
        echo "$desc"
        echo "Extensões aceitas: $exts"
        echo "Emulador (core): $core"
        if [ "$bios" != "-" ]; then echo "BIOS: $bios  (na pasta bios\\)"; fi
    } | crlf > "$DEST/roms/$dir/_LEIA-ME.txt"
done
cat <<'EOF' | crlf > "$DEST/wifi.txt"
# Wi-Fi do STV-2000 (opcional: com o cabo de rede não precisa configurar nada)
#
# Escreva o nome da rede e a senha depois do "=", salve este arquivo e ligue
# o aparelho com o cartão. Exemplo:
#   REDE=MinhaCasa
#   SENHA=minhasenha123
#
# O Wi-Fi interno do aparelho (chip SSV6051P) só enxerga redes de 2,4 GHz e é
# lento (cerca de 10 Mbit/s): dá para baixar capas de jogos e acessar por SSH.
# Para desligar o Wi-Fi, apague o nome da rede. A senha fica neste arquivo
# em texto puro.
#
# Opcional: PAIS=BR (código do país, define os canais permitidos)

REDE=
SENHA=
EOF
echo "modelo STV-2000" > "$DEST/.stv-modelo"
echo "template: $(find "$DEST/roms" -mindepth 1 -maxdepth 1 -type d | wc -l) sistemas em $DEST"
