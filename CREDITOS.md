# Créditos e licenças de terceiros

Este repositório contém apenas scripts e arquivos de configuração (GPL-3.0). A imagem
gerada inclui software de terceiros, cada um com a sua licença. As revisões exatas dos
fontes compilados ficam em `fontes.txt`, publicado junto de cada Release. Os pacotes do
Alpine podem ser obtidos, com fontes, em <https://pkgs.alpinelinux.org> e
<https://gitlab.alpinelinux.org/alpine/aports>.

| Componente | Origem | Licença |
|---|---|---|
| Alpine Linux 3.24 (pacotes) | pacotes oficiais | várias (cada pacote) |
| Linux 6.18 LTS (`linux-lts`) | pacote Alpine | GPL-2.0 |
| Mesa (driver lima) | pacote Alpine | MIT |
| Samba (compartilhamento `\\STV2000\JOGOS`) | pacote Alpine | GPL-3.0 |
| U-Boot (u-boot.ext) | <https://github.com/u-boot/u-boot>, compilado | GPL-2.0+ |
| RetroArch 1.22.2 | <https://github.com/libretro/RetroArch>, compilado com os patches em `patches/retroarch` | GPL-3.0 |
| Driver Wi-Fi SSV6051P (`ssv6051.ko`) | <https://github.com/eloirotava/6051> (código da iComm/South Silicon Valley, portado pela comunidade), compilado | GPL-3.0 ou posterior (cabeçalhos dos fontes) |
| Firmware `ssv6051-sw.bin` e `ssv6051-wifi.cfg` | mesmo repositório (firmware do fabricante, também distribuído pelo Armbian) | do fabricante, redistribuído como está |
| retroarch-assets, joypad-autoconfig, core-info, database | pacotes Alpine | ver cada projeto libretro (retroarch-assets: CC-BY 4.0) |
| Índices de nomes por CRC (`/usr/share/stv2000/nomes`) | gerados no build por `scripts/gen-nomes-crc.py` a partir do libretro-database | a do libretro-database |
| Fundos do Menu principal, Histórico e Favoritos | gerados no build por `scripts/gen-fundos.py` com as silhuetas do tema *monochrome* do retroarch-assets | CC-BY 4.0 (obra derivada) |
| PCSX ReARMed | <https://github.com/libretro/pcsx_rearmed>, compilado | GPL-2.0 |
| Beetle PCE Fast | <https://github.com/libretro/beetle-pce-fast-libretro>, compilado | GPL-2.0 |
| Snes9x / Snes9x 2010 | <https://github.com/libretro/snes9x>, <https://github.com/libretro/snes9x2010>, compilados | **não comercial** |
| Genesis Plus GX | <https://github.com/libretro/Genesis-Plus-GX>, compilado | **não comercial** |
| PicoDrive | <https://github.com/libretro/picodrive>, compilado | **não comercial** |
| FinalBurn Neo | <https://github.com/libretro/FBNeo>, compilado | **não comercial** |
| MAME 2003-Plus | <https://github.com/libretro/mame2003-plus-libretro>, compilado | **não comercial** (licença MAME antiga) |
| FCEUmm, Nestopia, Gambatte, gpSP, Stella 2014, ProSystem, Beetle NGP/WonderSwan, DOSBox | pacotes Alpine (`libretro-*`) | GPL-2.0 |
| mGBA | pacote Alpine | MPL-2.0 |
| Handy | pacote Alpine | zlib |
| vecx, PokeMini | pacotes Alpine | GPL-3.0 |
| fMSX | pacote Alpine | **não comercial** |

As licenças acima são as declaradas pelos projetos na data do build. Em caso de dúvida,
vale a licença do repositório de origem.

**Por causa dos componentes não comerciais, a imagem pode ser usada e distribuída
gratuitamente, mas não pode ser vendida nem vir pré-instalada em produtos à venda.**

Nenhum jogo (ROM) ou BIOS é distribuído. Use apenas cópias de software que você possui.

Agradecimentos à comunidade que documentou o boot de Linux em TV Box Amlogic (Armbian,
balbes150, ophub/amlogic-s9xxx-armbian, LibreELEC/CoreELEC) e ao artigo da antbr.com
que identificou o STV-2000 como uma placa S905W p281.
