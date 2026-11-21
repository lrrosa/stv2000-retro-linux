# Compilar a imagem

O build roda no **Linux** e foi feito no Windows 11 com **WSL2 + Ubuntu 26.04**. Também
funciona em qualquer Debian/Ubuntu x86_64. A parte aarch64 (RetroArch e cores) é
compilada nativamente dentro de um chroot Alpine emulado pelo `qemu-user`.

Requisitos: ~15 GB livres, internet, acesso de root (no WSL: `wsl -u root`).
Tempo: ~1 h na primeira vez (os cores FBNeo e MAME 2003-Plus são os mais demorados
sob emulação). As execuções seguintes reaproveitam o que já foi compilado.

## Passo a passo

```powershell
wsl -d Ubuntu -u root
```

```sh
git clone https://github.com/lrrosa/stv2000-retro-linux
cd stv2000-retro-linux
./build.sh
```

Resultado em `saida/`: `stv2000-retro-linux-AAAAMMDD.img`, `.img.xz` e `.sha256`, além
das telas do teste no QEMU.

> No WSL, clone dentro do sistema de arquivos do Linux (ex.: `/root`), não em `/mnt/c`:
> fica bem mais rápido. A área de trabalho do build é `/var/tmp/stv2000` (`WORK=`).

## Etapas

| Script | O que faz |
|---|---|
| `scripts/00-host-deps.sh` | instala no host: qemu-user + binfmt, qemu-system, cross-gcc, mtools, dosfstools, python3-pil, smbclient (teste)… |
| `scripts/10-builder.sh` | cria o chroot Alpine aarch64 com `build-base` (usa o `apk.static` oficial) |
| `scripts/20-compile.sh` | compila o **RetroArch** (KMS/EGL/GLES2/udev/ALSA, sem X11/Qt/ffmpeg) e os cores que o Alpine não empacota; grava `fontes.txt` com os commits usados |
| `scripts/30-rootfs.sh` | cria o sistema final: pacotes, overlay, usuário, fundos do menu (`gen-fundos.py`), índices de nomes por CRC (`gen-nomes-crc.py`), serviços, initramfs |
| `scripts/35-wifi.sh` | compila para a versão exata do kernel do rootfs o driver do Wi-Fi SSV6051P **e o `clk-pwm.ko`** (relógio `wifi32k` que o kernel do Alpine não habilita; sem ele o SDIO do Wi-Fi nem sobe — veja [HARDWARE.md](HARDWARE.md#wi-fi-o-relógio-clk-pwm)), instala módulos + firmware e fixa o kernel no `/etc/apk/world` |
| `scripts/40-uboot.sh` | compila o U-Boot mainline (p212), carregado como `u-boot.ext` pelo U-Boot de fábrica (caminho de boot padrão) |
| `scripts/50-image.sh` | gera as 3 partições e o `.img` |
| `scripts/60-qemu-test.sh` | dá boot da imagem no QEMU (máquina virt): 1º boot (expansão da JOGOS mantendo os arquivos), envio de um jogo pelo Samba com o menu vazio, jogos de teste, listas; percorre as abas por comandos de rede do RetroArch e salva as telas |
| `scripts/gen-fundos.py` | gera os fundos das abas Menu principal/Configurações/Histórico/Favoritos (degradê + silhuetas do tema monochrome) |
| `scripts/gen-nomes-crc.py` | lê a base de dados do libretro (`.rdb`) e grava, por sistema de cartucho, o índice CRC32 → nome oficial que o `stv-playlists` usa para dar nome e capa às ROMs |

Cada etapa pode ser rodada sozinha e pula o que já existe. Para refazer algo, apague o
artefato em `/var/tmp/stv2000` (ex.: `artifacts/cores/fbneo_libretro.so`) ou rode só
a fase desejada (`bash scripts/30-rootfs.sh config`). `SEM_TESTE=1 ./build.sh` pula o QEMU.

## Personalizar

- `scripts/config.sh`: versão do Alpine, device tree padrão, tamanhos das partições,
  linha de comando do kernel, usuário e senha inicial (`USER_PASS`).
- `overlay/usr/share/stv2000/systems.conf`: sistemas, pastas, cores e extensões. Para
  acrescentar um sistema, adicione uma linha e, se o core não existir no Alpine,
  inclua-o na lista `CORES` de `scripts/20-compile.sh`.
- `overlay/` e `overlay-home/`: arquivos copiados para o sistema e para `/home/gamer`.
- `patches/<fonte>/*.patch`: aplicados no fonte antes de compilar. O RetroArch recebe
  um patch pequeno que mostra "Reiniciar" e "Desligar" no menu principal, como no
  Lakka, sem ativar o resto do modo Lakka.
- `SSV6051_REPO`/`SSV6051_REF` em `config.sh`: origem e commit do driver do Wi-Fi.

## Cuidados

- O script monta `/proc`, `/sys` e `/dev` dentro dos chroots com `--rbind` +
  `--make-rslave`. No WSL/systemd as montagens são *shared*: um `mount --bind /dev`
  simples, seguido de `umount`, propaga a desmontagem para o `/dev` do próprio Ubuntu,
  e o WSL para de responder (resolve com `wsl --shutdown`).
- O teste no QEMU valida o sistema (init, serviços, primeiro boot, listas, RetroArch),
  mas **não** o boot Amlogic nem os drivers do S905W. Isso só se testa no aparelho.
