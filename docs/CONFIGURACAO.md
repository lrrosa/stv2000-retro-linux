# Configuração e uso

## A interface

O aparelho liga direto no menu de jogos (XMB do RetroArch, o mesmo do Lakka), em
português. Tudo se faz com o controle:

| Botão | Ação |
|---|---|
| ← → | troca de aba: Menu principal, Configurações, Histórico, Favoritos e um sistema por aba |
| ↑ ↓ | escolhe o jogo (segure para andar rápido; L/R pulam por letra) |
| botão de **baixo** (B no SNES, A no Xbox, ✕ no PlayStation) | abre / confirma: no jogo, escolha **Executar** |
| botão da **direita** (A no SNES, B no Xbox, ○ no PlayStation) | volta (dentro de um jogo, o **←** também volta) |
| **Select + Start** | durante o jogo: **sai do jogo** e volta à lista |
| **segurar Start** (2 s) | durante o jogo: menu rápido (salvar/carregar estado, trocar disco) |

Prefere confirmar com o botão da direita, como no SNES? A troca fica em *Configurações →
Entrada*, nos controles do menu (trocar os botões OK e Cancelar).

- **Favoritos**: abra o jogo na lista e escolha *Adicionar aos favoritos*.
- **Opções do jogo**: ao abrir um jogo aparecem só *Executar*, *Adicionar aos favoritos*,
  *Informações* e, por último, *Opções*. Renomear, remover da lista e trocar o núcleo
  ficam dentro de *Opções*, para não remover um jogo sem querer.
- **Histórico**: os últimos 50 jogos abertos, com o tempo jogado.
- **Visual**: ícones coloridos (tema *Retrosystem*) e fundos com tema de jogos: em cada
  sistema, a tela de um jogo dele desfocada; nas outras abas, um degradê com silhuetas de
  controles. Para mudar: *Configurações → Interface do usuário → Aparência* (tema de
  ícones, tema de cores, opacidade do fundo).
- **Nomes**: aparecem sem as etiquetas de versão. Por exemplo,
  `Sonic The Hedgehog (USA, Europe) (Rev 1).md` vira *Sonic The Hedgehog (USA, Europe)*.
  Nos sistemas de cartucho, o aparelho reconhece cada ROM pelo CRC na base de dados do
  libretro e usa o **nome oficial**, seja qual for o nome do arquivo:
  `Sonic The Hedgehog 2 (W) (REV01) [!].gen` aparece como *Sonic The Hedgehog 2 (World)*.
  Jogos recém-copiados aparecem primeiro com o nome do arquivo e ganham o nome oficial
  alguns segundos depois (cada ROM é lida uma vez só).

### Capas (thumbnails)

Com **rede** (cabo ou Wi-Fi), a capa e a tela-título de cada jogo são baixadas
automaticamente na primeira vez que você passa pelo jogo na lista: do servidor do
libretro ou, se ele estiver fora do ar ou não tiver a imagem, do espelho
[libretro-thumbnails](https://github.com/libretro-thumbnails) no GitHub. Elas ficam salvas
em `JOGOS\thumbnails` e depois funcionam sem rede. Para baixar todas de uma vez:
*Menu principal → Atualizador on-line → Atualizar miniaturas das listas*.

A capa é encontrada pelo **nome do jogo na lista**. Nos sistemas de cartucho é o nome
oficial reconhecido pelo CRC (veja *Nomes* acima), então funciona com qualquer nome de
arquivo. Em CD (PlayStation, Mega-CD) e arcade, o nome do arquivo precisa seguir a
nomenclatura No-Intro/Redump (ex.: `Final Fantasy VII (USA) (Disc 1).chd`). Para usar
uma imagem sua, salve como PNG em
`JOGOS\thumbnails\<nome do sistema>\Named_Boxarts\<nome do jogo>.png`. O nome do sistema é
o da aba, por exemplo `Nintendo - Super Nintendo Entertainment System`. Os caracteres
``& * / : ` < > ? \ |`` do nome do jogo viram `_`.

## Colocando jogos

Cada jogo vai para a pasta do seu sistema, dentro de `roms\` (por exemplo
`roms\snes\Jogo.sfc`, `roms\psx\Jogo.cue` + `Jogo.bin`). Há um `LEIA-ME.txt` com a
tabela completa, e cada pasta tem um `_LEIA-ME.txt` com as extensões aceitas.

**Pela rede**, com o aparelho ligado: no PC, abra `\\STV2000\JOGOS` (veja
[Pasta de jogos pela rede](#pasta-de-jogos-pela-rede-smb)) e copie ou apague os jogos.

**Pelo cartão**:

1. Desligue o aparelho (*Menu principal → Desligar*) e tire o cartão.
2. No PC, abra a unidade **`JOGOS`** e copie os jogos.
3. Ejete o cartão com segurança, coloque no aparelho e ligue.

As listas do RetroArch são **atualizadas sozinhas** quando o conteúdo de `roms\` muda:
no boot e, com o aparelho ligado, a cada 15 segundos. Cada sistema aparece como uma aba
no menu, já com o emulador certo. Um jogo novo num sistema que já tem aba aparece ao
entrar de novo na aba. Um **sistema novo** ganha aba depois de *Menu principal →
Reiniciar*. A exceção é o aparelho sem nenhum jogo: aí o menu reabre sozinho quando o
primeiro jogo chega.

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
- **Select + Start** sai do jogo e volta à lista (como no Batocera/RetroPie). No menu,
  sem jogo aberto, essa combinação não faz nada.
- **Segurar Start por 2 segundos** abre o menu do RetroArch durante o jogo
  (salvar/carregar estado, trocar disco, opções do emulador).
- Cada sistema abre direto no emulador padrão (tabela `systems.conf`). Para usar outro
  num jogo: abra o jogo na lista → *Opções* → *Definir núcleo*.
- Para remapear: *Configurações → Entrada → Controles da porta 1*.
- As configurações mais técnicas ficam escondidas. Para vê-las: *Configurações →
  Interface do usuário → Mostrar configurações avançadas*.

## Desligar e reiniciar

*Menu principal* → **Desligar** (ou **Reiniciar**). O aparelho fecha tudo com segurança
e mostra a tela "Desligando...". Pode tirar da tomada quando a tela apagar. (O STV-2000
não tem botão de energia.)
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

## Pasta de jogos pela rede (SMB)

Com o cabo de rede ligado (ou o Wi-Fi configurado), a partição JOGOS fica
compartilhada na rede local, **sem usuário nem senha**:

- **Windows**: no Explorador de Arquivos, digite na barra de endereço
  **`\\STV2000\JOGOS`** (ou `\\<IP>\JOGOS`). Para deixar como unidade fixa: botão
  direito em *Este Computador → Mapear unidade de rede*.
- **Android**: num gerenciador de arquivos com SMB (CX File Explorer, Solid Explorer,
  VLC…), adicione o servidor pelo IP como **anônimo/convidado**.
- **macOS**: Finder → *Ir → Conectar ao Servidor* → `smb://<IP>/JOGOS` → *Convidado*.
- **Linux**: `smb://stv2000/JOGOS` no gerenciador de arquivos.

O aparelho só aceita conexões da rede local (endereços `192.168.x.x`, `10.x.x.x` e
`172.16-31.x.x`).

> [!IMPORTANT]
> **Windows 11 24H2 ou mais novo** bloqueia pastas anônimas por padrão. A mensagem é
> *"Você não pode acessar esta pasta compartilhada porque as políticas de segurança da
> organização bloqueiam o acesso de convidado não autenticado"*. Para resolver sem
> mexer na segurança do PC, guarde uma vez o usuário do aparelho no Windows. No
> PowerShell (não precisa ser administrador), rode:
>
> ```powershell
> cmdkey /add:STV2000 /user:gamer /pass:retro
> ```
>
> Depois disso, `\\STV2000\JOGOS` abre direto, sem perguntar nada. Se você acessa pelo
> IP, use o IP no lugar de `STV2000`. Se trocar a senha do Samba no aparelho, rode o
> `cmdkey` de novo com a senha nova.

- O nome `STV2000` é anunciado por NetBIOS. Ele **não aparece sozinho** na seção
  *Rede* do Explorador: digite o endereço. Se o nome não for encontrado, use o IP
  (ele aparece no roteador ou em *Menu principal → Informações → Rede*).
- Dá para copiar jogos com o aparelho no menu ou até durante um jogo. Evite apagar o
  jogo que está aberto.
- A senha do login `gamer` na rede é separada da senha do SSH. Para trocá-la (por SSH):
  `doas smbpasswd gamer`.
- Para desligar o compartilhamento: `doas rc-update del samba && doas rc-service samba stop`.
  A configuração fica em `/etc/samba/smb.conf`.

## Rede e SSH

Com o cabo de rede ligado (ou o Wi-Fi configurado, veja abaixo), o aparelho pega IP
por DHCP e aparece na rede como **`stv2000`**.

```sh
ssh gamer@stv2000        # ou ssh gamer@<IP>
```

- Usuário **`gamer`**, senha inicial **`retro`**. **Troque logo:** `passwd`.
- O `root` fica bloqueado. Para administrar, use `doas` (ex.: `doas apk add htop`), que
  pede a senha do `gamer`.
- Arquivos também podem ser transferidos por SFTP (WinSCP, FileZilla), com o mesmo
  usuário e senha. Os jogos ficam em `/media/jogos`.

## Comandos úteis

| Comando | Para quê |
|---|---|
| `stv-playlists -f` | recria as listas de jogos (depois reabra o RetroArch) |
| `doas rc-service samba restart` | reinicia o compartilhamento de rede (depois de editar o `smb.conf`) |
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
> O chip só enxerga redes de **2,4 GHz**. No teste neste aparelho ele conectou sozinho
> e alcançou **cerca de 30–37 Mbit/s** (cópia de arquivo por cima do SSH, com o roteador
> perto; longe do roteador a taxa cai). É um driver da comunidade, fora da árvore do
> kernel, mas estável no uso. Ainda assim, o **cabo de rede** (10/100) tem menor latência
> — para netplay, prefira o cabo.

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
| `/etc/samba/smb.conf` | compartilhamento de rede `\\STV2000\JOGOS` |
| `/usr/lib/libretro` | emuladores (cores) |
