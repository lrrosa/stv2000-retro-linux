# Configuração e uso

## A interface

O aparelho liga direto no menu de jogos (XMB do RetroArch, o mesmo do Lakka), em
português. Tudo se faz com o controle:

| Botão | Ação |
|---|---|
| ← → | troca de aba: Menu principal, Configurações, Histórico, Favoritos e um sistema por aba |
| ↑ ↓ | escolhe o jogo (segure para andar rápido; L/R pulam por letra) |
| botão de **baixo** (B no SNES, A no Xbox, ✕ no PlayStation) | abre / confirma: no jogo, escolha **Executar** |
| botão da **direita** (A no SNES, B no Xbox, ○ no PlayStation) | volta |
| Start + Select | durante o jogo: menu rápido (salvar/carregar estado, trocar disco, **Fechar conteúdo**) |

Prefere confirmar com o botão da direita, como no SNES? A troca fica em *Configurações →
Entrada*, nos controles do menu (trocar os botões OK e Cancelar).

- **Favoritos**: abra o jogo na lista e escolha *Adicionar aos favoritos*.
- **Histórico**: os últimos 50 jogos abertos, com o tempo jogado.
- **Visual**: ícones coloridos (tema *Retrosystem*) e fundos com tema de jogos: em cada
  sistema, a tela de um jogo dele desfocada; nas outras abas, um degradê com silhuetas de
  controles. Para mudar: *Configurações → Interface do usuário → Aparência* (tema de
  ícones, tema de cores, opacidade do fundo).
- **Nomes**: aparecem sem as etiquetas de versão. Por exemplo,
  `Sonic The Hedgehog (USA, Europe) (Rev 1).md` vira *Sonic The Hedgehog (USA, Europe)*.

### Capas (thumbnails)

Com o **cabo de rede** ligado, a capa e a tela-título de cada jogo são baixadas
automaticamente do servidor do libretro na primeira vez que você passa pelo jogo na
lista. Elas ficam salvas em `JOGOS\thumbnails` e depois funcionam sem rede. Para baixar
todas de uma vez: *Menu principal → Atualizador on-line → Atualizar miniaturas das listas*.

A capa é encontrada pelo **nome do arquivo**, que precisa seguir a nomenclatura No-Intro/
Redump, a usada pela maioria dos sets (ex.: `Super Mario World (USA).sfc`). Para usar
uma imagem sua, salve como PNG em
`JOGOS\thumbnails\<nome do sistema>\Named_Boxarts\<nome do jogo>.png`. O nome do sistema é
o da aba, por exemplo `Nintendo - Super Nintendo Entertainment System`. Os caracteres
``& * / : ` < > ? \ |`` do nome do jogo viram `_`.

## Colocando jogos

1. Desligue o aparelho (*Menu principal → Desligar*) e tire o cartão.
2. No PC, abra a unidade **`JOGOS`**. Há um `LEIA-ME.txt` com a tabela completa.
3. Copie cada jogo para a pasta do seu sistema, dentro de `roms\` (por exemplo
   `roms\snes\Jogo.sfc`, `roms\psx\Jogo.cue` + `Jogo.bin`). Cada pasta tem um
   `_LEIA-ME.txt` com as extensões aceitas.
4. Ejete o cartão com segurança, coloque no aparelho e ligue.

As listas do RetroArch são **recriadas automaticamente a cada boot** quando o conteúdo
de `roms\` muda. Cada sistema aparece como uma aba no menu, já com o emulador certo.

Dicas:
- `.zip` e `.7z` funcionam nos consoles. Em arcade, **não descompacte nem renomeie** os
  `.zip`: o nome precisa bater com o romset (FBNeo atual ou MAME 0.78). O `neogeo.zip`
  fica junto dos jogos, em `roms\arcade`.
- Para jogos de CD (PlayStation, Mega-CD, PC Engine CD), use `.cue`+`.bin` ou `.chd`.
  Para jogos com vários discos, crie um `.m3u` com o nome de cada disco, um por linha.
  Só o `.m3u` aparece na lista, e a troca de disco é feita pelo menu rápido do RetroArch.
- O FAT32 limita cada arquivo a 4 GB, o que basta para todos esses sistemas.

## BIOS

Copie para `JOGOS\bios\` com o nome exato:

| Sistema | Arquivo(s) | Obrigatório? |
|---|---|---|
| PlayStation | `scph5501.bin` (ou `scph1001.bin`, `scph7001.bin`) | recomendado (sem ele usa BIOS emulada) |
| Mega-CD | `bios_CD_U.bin`, `bios_CD_E.bin`, `bios_CD_J.bin` | sim |
| PC Engine CD | `syscard3.pce` | só jogos em CD |
| Famicom Disk System | `disksys.rom` | só FDS |
| Game Boy Advance | `gba_bios.bin` | opcional |
| Atari Lynx | `lynxboot.img` | sim |
| Neo Geo | `neogeo.zip` em `roms\arcade` (não em `bios\`) | sim |

## Controles

- Controles USB comuns (genéricos, Xbox, PlayStation com cabo, 8BitDo…) são
  **configurados automaticamente** ao conectar.
- **Start + Select** abre o menu do RetroArch durante o jogo (salvar/carregar estado,
  trocar disco, sair do jogo).
- Para remapear: *Configurações → Entrada → Controles da porta 1*.
- As configurações mais técnicas ficam escondidas. Para vê-las: *Configurações →
  Interface do usuário → Mostrar configurações avançadas*.

## Desligar e reiniciar

*Menu principal* → **Desligar** (ou **Reiniciar**). O aparelho fecha tudo com segurança.
Pode tirar da tomada quando a tela apagar. (O STV-2000 não tem botão de energia.)
No teclado, apertar **Esc** duas vezes também desliga.

## Vídeo

A saída padrão é **1280×720 a 60 Hz**, mais leve para a GPU. Para usar 1080p:
*Configurações → Vídeo → Modo de tela cheia → Largura/Altura* = 1920×1080 (ou 0×0 para
a resolução da TV) e reinicie o RetroArch. Em jogos 2D a diferença é pequena.

## Áudio

O som sai pela HDMI. A cada boot o script `/etc/local.d/20-audio.start` liga os
seletores do driver de áudio do S905W, que no kernel atual começam desligados. Se ficar
sem som, verifique por SSH:

```sh
amixer -c 0 contents | grep -A2 -E "HDMI|ACODEC"
amixer -c 0 sset 'AIU HDMI CTRL SRC' 'I2S'
```

## Rede e SSH

Com o cabo de rede ligado (ou o Wi-Fi configurado, veja abaixo), o aparelho pega IP
por DHCP e aparece na rede como **`stv2000`**.

```sh
ssh gamer@stv2000        # ou ssh gamer@<IP>
```

- Usuário **`gamer`**, senha inicial **`retro`**. **Troque logo:** `passwd`.
- O `root` fica bloqueado. Para administrar, use `doas` (ex.: `doas apk add htop`).
- Arquivos também podem ser transferidos por SFTP (WinSCP, FileZilla). Os jogos ficam em
  `/media/jogos`.

## Comandos úteis

| Comando | Para quê |
|---|---|
| `stv-playlists -f` | recria as listas de jogos (depois reabra o RetroArch) |
| `touch ~/.sem-autostart` | o RetroArch deixa de abrir sozinho (para voltar: `rm ~/.sem-autostart`) |
| `doas apk update && doas apk upgrade` | atualiza os programas (o kernel fica fixo, veja "Atualizações") |
| `doas stv-wifi status` / `restart` | estado do Wi-Fi / reconecta depois de editar o `wifi.txt` |
| `doas reboot` / `doas poweroff` | reinicia / desliga |
| `tail ~/.cache/retroarch.log` | log da última execução do RetroArch |

## Wi-Fi

O Wi-Fi interno (chip **iComm SSV6051P**) usa um driver da comunidade, compilado junto
com a imagem ([eloirotava/6051](https://github.com/eloirotava/6051)). Para ligar:

1. Com o cartão no PC, abra **`JOGOS\wifi.txt`** no Bloco de Notas.
2. Preencha o nome da rede e a senha:
   ```
   REDE=MinhaCasa
   SENHA=minhasenha123
   ```
3. Salve, volte o cartão para o aparelho e ligue. A conexão sobe em segundo plano,
   uns 20 segundos depois do menu aparecer.

Pode preencher o `wifi.txt` logo depois de gravar o cartão, antes do primeiro boot:
ele é mantido quando a partição JOGOS é expandida.

> [!IMPORTANT]
> O driver é **experimental** e ainda não foi testado neste aparelho. O chip só
> enxerga redes de **2,4 GHz** e é lento (por volta de 10 Mbit/s nos testes do autor
> do driver). Isso basta para capas de jogos, SSH e atualizações. Para jogar on-line
> (netplay), prefira o cabo.

Por SSH: `doas stv-wifi status` mostra a conexão, `doas stv-wifi restart` reconecta
depois de editar o `wifi.txt`. Se a interface `wlan0` não aparecer, veja
`dmesg | grep -i -E "ssv|mmc0|sdio"`.

Ajustes do driver (para quem quiser testar): `/lib/firmware/ssv6051-wifi.cfg`. Se
houver erros de CRC no `dmesg`, diminua `sdio_clock_hz` para `25000000`. A potência de
transmissão fica em `wifi_tx_gain_level_b`/`_gn`.

**Dongle USB**: o mesmo `wifi.txt` funciona com dongles que o kernel suporta, como os
chips MediaTek MT7601U e MT7610U ou Realtek RTL8188EU e RTL8192EU. O firmware do chip
não vem na imagem. Instale por SSH com o cabo ligado (`apk search linux-firmware`,
depois `doas apk add linux-firmware-<fabricante>`). Se o dongle virar `wlan1`, use
`STV_WIFI_IF=wlan1`.

## Atualizações

`doas apk update && doas apk upgrade` atualiza os programas. **O kernel fica fixo** na
versão da imagem, porque o driver do Wi-Fi é compilado para ela. Para um kernel novo,
grave uma imagem mais recente: os jogos e saves ficam na partição JOGOS, que pode ser
copiada para o PC antes.

## Onde fica cada coisa

| Caminho | Conteúdo |
|---|---|
| `/media/jogos` | partição JOGOS: `roms/`, `bios/`, `saves/`, `states/`, `screenshots/`, `thumbnails/`, `wifi.txt` |
| `/boot` | partição STVBOOT: kernel, `uEnv.txt`, scripts de boot |
| `~/.config/retroarch/retroarch.cfg` | configuração do RetroArch |
| `/usr/share/stv2000/systems.conf` | tabela pasta → sistema → emulador → extensões |
| `/usr/lib/libretro` | emuladores (cores) |
