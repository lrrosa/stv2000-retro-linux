# Hardware do Aquário STV-2000

Levantamento feito pelas marcações dos chips de uma unidade (placa `EB-KDC-2020112501`,
etiqueta "1G+8G", Android 7.1). Unidades de outros lotes podem ter peças diferentes.

| Item | Peça | Suporte no Linux mainline |
|---|---|---|
| SoC | **Amlogic S905W**: 4× Cortex-A53 (até 1,2 GHz), família GXL | sim |
| GPU | Mali-450 MP3 | sim, driver **lima** (OpenGL ES 2.0) |
| RAM | 1 GB DDR3 (4× Samsung 2 Gb, dois em cada face) | — |
| eMMC | Samsung KLM8G1WEMB-B031, 8 GB (Android) | não é usado por este projeto |
| Wi-Fi | iComm **SSV6051P** (SDIO, no `sd_emmc_a`) | driver comunitário fora da árvore ([eloirotava/6051](https://github.com/eloirotava/6051)) + módulo `clk-pwm`; testado no aparelho (~30–37 Mbit/s, só 2,4 GHz) |
| Ethernet | 10/100, PHY interno do SoC (transformador QX B1601SH) | sim |
| USB | hub Moai MA8601 → 4× USB 2.0 | sim |
| Vídeo | HDMI e AV (composto) | sim (HDMI testado como padrão) |
| Áudio | HDMI, AV analógico, SPDIF | HDMI sim (driver AIU) |
| Cartão | microSD | sim |
| IR | receptor infravermelho | driver presente, controle não mapeado |

A placa é equivalente à de referência **Amlogic P281** (a mesma dos MXQ Pro 4K com S905W),
por isso o device tree padrão é `amlogic/meson-gxl-s905w-p281.dtb`.

## Botão de reset ("palito")

Fica atrás do conector **AV** de 3,5 mm e é acionado por dentro dele. Segurado durante
a energização, faz o U-Boot de fábrica procurar o `aml_autoscript` no cartão SD/USB.

## Serial (UART)

Quatro furos/pinos na borda da placa, ao lado do conector de energia. Nível **3,3 V**,
**115200 8N1**. Use um adaptador USB-serial de 3,3 V e ligue só GND, TX e RX (cruzados).
Não ligue o pino de VCC. Pela serial aparecem as mensagens do U-Boot e do kernel, e há
um login em `ttyAML0`.

## Cadeia de boot

```
ROM do SoC → U-Boot de fábrica (eMMC)
   └─ 1ª vez, com o botão do AV: aml_autoscript (do cartão)
        → grava no ambiente: bootcmd = "procura s905_autoscript no SD/USB; senão Android"
   └─ boots seguintes: s905_autoscript (do cartão)
        ├─ padrão: desliga a camada OSD (some o logo/lixo na tela) e carrega o
        │  u-boot.ext (U-Boot mainline p212) → extlinux/extlinux.conf → booti
        │  (único caminho que funcionou no STV-2000 testado, com o DTB p281)
        └─ sem u-boot.ext: lê uEnv.txt → carrega Image (0x11000000), uInitrd
           (0x18000000), device tree (0x10e00000) → booti  (deu tela preta no teste)
              → kernel Alpine linux-lts → initramfs → root=LABEL=STVROOT
```

Observações:
- O kernel do Alpine vem como *EFI zboot* (`vmlinuz-lts`, comprimido). O U-Boot de
  fábrica (2015) não sabe descomprimi-lo, então o script `stv-update-boot` extrai o
  `Image` cru (~38 MB). Ele roda automaticamente após cada `apk upgrade` (hook em
  `/etc/apk/commit_hooks.d/`).
- Como o `Image` passa de 32 MB, o initrd é carregado em `0x18000000`, e não no
  `0x13000000` usado em scripts mais antigos para TV Box.
- O U-Boot de fábrica passa o MAC do aparelho em `mac=...` na linha de comando, e o
  `stv-mac` aplica esse endereço na `eth0`. Sem ele, é gerado um MAC fixo a partir do
  serial do SoC, para que o roteador mantenha o mesmo IP.

## Layout do cartão SD

| # | Rótulo | Sistema de arquivos | Tamanho | Conteúdo |
|---|---|---|---|---|
| 1 | `STVBOOT` | FAT32 | 256 MB | scripts de boot, kernel, initrd, dtbs |
| 2 | `STVROOT` | ext4 | ~2,5 GB | Alpine Linux |
| 3 | `JOGOS` | FAT32 | o resto do cartão | roms, bios, saves, states, screenshots, thumbnails |

A partição 1 começa em 16 MiB. A 3 é criada com 128 MB e, no primeiro boot, o
`stv-firstboot` a expande até o fim do cartão. O que já estiver nela é guardado na
partição do sistema e devolvido depois da formatação.

## Wi-Fi: o relógio `clk-pwm`

O chip SSV6051P fica no barramento SDIO `sd_emmc_a` (`d0070000.mmc`). No device tree da
p281 esse controlador depende de um `mmc-pwrseq-simple` (`sdio-pwrseq`, reset no
`GPIOX_6`), que por sua vez precisa de um relógio de 32768 Hz (`wifi32k`, `compatible =
"pwm-clock"`, gerado pelo `PWM_E`). O kernel do Alpine vem com
`# CONFIG_COMMON_CLK_PWM is not set`, então esse relógio nunca sobe: o `pwrseq` fica em
*deferred probe* ("external clock not ready"), o controlador SDIO não é registrado e o
chip não aparece no barramento.

A imagem resolve isso compilando o `clk-pwm.ko` fora da árvore (fonte do próprio
kernel.org, mesma versão do kernel da imagem) e instalando-o no rootfs. Ele é carregado
pelo device tree (alias `pwm-clock`) e, por garantia, o `stv-wifi` também faz
`modprobe clk-pwm` antes de subir a rede. Assim que o relógio aparece, o *deferred probe*
do SDIO conclui, o `ssv6051` detecta o chip (`device id: 3030:3030`) e a `wlan0` surge.
No teste neste aparelho o sinal ficou em -26 dBm (roteador perto) e a cópia de arquivos
por cima do SSH alcançou ~30–37 Mbit/s.
