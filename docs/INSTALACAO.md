# Instalação

## Você vai precisar

- TV Box **Aquário STV-2000** (Amlogic S905W, 1 GB de RAM)
- Cartão **microSD de 8 GB ou mais** (classe 10 / A1 recomendado) e um leitor de cartão no PC
- Controle USB (ou teclado USB) e cabo HDMI
- Cabo de rede (opcional: SSH, atualizações e capas dos jogos)
- Um **palito de dente** (ou cotonete). Evite objetos de metal.

## 1. Baixar e conferir a imagem

Baixe `stv2000-retro-linux-*.img.xz` e o `.sha256` em [Releases](../../releases)
(ou gere a sua: [COMPILAR.md](COMPILAR.md)). Para conferir no PowerShell:

```powershell
Get-FileHash .\stv2000-retro-linux-*.img.xz -Algorithm SHA256
```

O resultado deve ser igual ao conteúdo do arquivo `.sha256`.

## 2. Gravar no cartão

Use o **[balenaEtcher](https://etcher.balena.io/)** ou o **[Rufus](https://rufus.ie/)**.
Os dois aceitam o `.img.xz` direto, sem descompactar.

1. Escolha a imagem e o cartão microSD (**confira a letra/tamanho**: tudo nele será apagado).
2. Grave e aguarde a verificação.
3. Ao terminar, o Windows pode mostrar várias unidades novas e pedir para
   **formatar** uma delas. É a partição do Linux (ext4): **clique em Cancelar**.
   As partições `STVBOOT` e `JOGOS` aparecem normalmente.

> Dica: você já pode copiar alguns jogos para `JOGOS\roms\...` agora, mas a partição
> só tem 128 MB até o primeiro boot. Depois do primeiro boot ela passa a ocupar o
> cartão inteiro. **Recomendado: dar o primeiro boot antes de copiar os jogos.**
>
> Sem cabo de rede? Preencha agora o `JOGOS\wifi.txt` (nome da rede e senha). Ele é
> mantido no primeiro boot. Veja [Wi-Fi](CONFIGURACAO.md#wi-fi).

## 3. Primeiro boot (só uma vez): o "palito"

O STV-2000 tem um botão escondido **dentro do conector AV** (a saída de vídeo
composto, conector P2 de 3,5 mm). Ele faz o carregador de fábrica executar o
`aml_autoscript` do cartão, que habilita o boot por cartão SD/USB.

1. Com o aparelho **fora da tomada**, insira o cartão, conecte HDMI e o controle USB.
2. Enfie o palito no conector **AV** até sentir o clique do botão. **Mantenha apertado.**
3. Ligue a fonte na tomada.
4. Solte quando aparecer o logo e a tela piscar ou apagar (5 a 10 segundos).
5. O aparelho reinicia sozinho e liga o Linux.

No primeiro boot o sistema expande a partição `JOGOS` até o fim do cartão e pode
reiniciar mais uma vez. Em seguida o **RetroArch abre em português**.

Daqui em diante, **com o cartão** o aparelho liga o Linux e **sem o cartão** liga o
Android. Não precisa mais do palito.

## 4. Voltar ao Android

Basta desligar, tirar o cartão e ligar de novo. A memória interna não foi alterada.
(O único ajuste feito no aparelho é a ordem de boot "cartão/USB primeiro", que é
inofensiva sem o cartão.)

## Se algo der errado

| Sintoma | O que fazer |
|---|---|
| Liga o Android mesmo com o cartão | Repita o passo 3 segurando o botão por mais tempo. Confira se a gravação terminou e se o cartão tem a partição `STVBOOT`. |
| Tela preta depois do logo | No PC, abra `STVBOOT\uEnv.txt` no Bloco de Notas e troque a linha `FDT=` pelas alternativas listadas em `STVBOOT\LEIA-ME.txt` (p281 → tx3-mini → s905x-p212). |
| Não dá boot de jeito nenhum | Em `STVBOOT`, renomeie `u-boot.ext.alternativo` para `u-boot.ext` (carrega um U-Boot moderno). Se precisar trocar o device tree, faça isso em `extlinux\extlinux.conf`. Para desfazer, renomeie de volta. |
| RetroArch abre mas sem som | Veja "Áudio" em [CONFIGURACAO.md](CONFIGURACAO.md). |
| Quer ver o que está acontecendo | Use a serial da placa (UART, 115200 8N1, 3,3 V). Veja [HARDWARE.md](HARDWARE.md). |

Ao relatar problemas, abra uma *issue* informando o que aparece na tela e, se tiver, o log da serial.
