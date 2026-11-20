#!/usr/bin/env python3
"""Gera os fundos de tela do menu para as abas que não são de um sistema.

O XMB procura <pasta de fundos>/<título da aba>.png ("Menu principal", "Configurações",
"Histórico", "Favoritos"). Cada fundo é um degradê colorido com silhuetas de controles
e videogames espalhadas, ao estilo "papel de parede gamer". As silhuetas vêm dos ícones
monocromáticos do retroarch-assets (CC-BY 4.0), então o resultado é uma obra derivada
deles (créditos em CREDITOS.md).

Uso: gen-fundos.py <pasta de ícones xmb/monochrome/png> <pasta de saída>
Requer python3 com Pillow (pacote python3-pil no Ubuntu).
"""
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

W, H = 1280, 720

# Silhuetas usadas no padrão (nomes dos ícones do tema monochrome, sem ".png")
SILHUETAS = [
    "Nintendo - Nintendo Entertainment System",
    "Nintendo - Super Nintendo Entertainment System",
    "Nintendo - Nintendo 64",
    "Nintendo - Game Boy",
    "Nintendo - Game Boy Advance",
    "Sega - Mega Drive - Genesis",
    "Sega - Master System - Mark III",
    "Sega - Game Gear",
    "Sony - PlayStation",
    "NEC - PC Engine - TurboGrafx 16",
    "Atari - 2600",
    "retroarch",
    "favorites",
]

# título da aba -> (cor 1, cor 2, brilho, semente)
FUNDOS = {
    "Menu principal": ((46, 16, 102), (16, 58, 140), (214, 64, 214), 1),
    "Histórico": ((10, 66, 72), (22, 52, 120), (40, 210, 180), 2),
    "Favoritos": ((112, 28, 26), (120, 64, 6), (255, 184, 28), 3),
}
# abas que repetem outro fundo (o XMB também usa o "Menu principal" nos submenus)
COPIAS = {"Configurações": "Menu principal"}


def degrade(c1, c2, brilho):
    """Degradê diagonal de c1 para c2, com um brilho radial no canto superior direito."""
    mascara = Image.linear_gradient("L").rotate(-35, expand=True)
    mascara = mascara.resize((W * 2, H * 2)).crop((W // 2, H // 2, W // 2 + W, H // 2 + H))
    img = Image.composite(Image.new("RGB", (W, H), c2), Image.new("RGB", (W, H), c1), mascara)
    radial = Image.radial_gradient("L").resize((W * 2, W * 2))   # 0 no centro, 255 na borda
    radial = radial.point(lambda v: max(0, 150 - v) * 255 // 150)
    luz = Image.new("L", (W, H), 0)
    luz.paste(radial.crop((W - int(W * 0.85), W - int(H * 0.15), 2 * W - int(W * 0.85), W - int(H * 0.15) + H)))
    luz = luz.point(lambda v: v * 0.55)
    img = Image.composite(Image.new("RGB", (W, H), brilho), img, luz)
    return img


def padrao(pasta_icones, semente):
    """Camada RGBA com as silhuetas em grade irregular, giradas e semitransparentes."""
    rnd = random.Random(semente)
    icones = []
    for nome in SILHUETAS:
        caminho = os.path.join(pasta_icones, nome + ".png")
        if os.path.isfile(caminho):
            icones.append(Image.open(caminho).convert("RGBA"))
    if not icones:
        sys.exit("nenhum ícone encontrado em " + pasta_icones)
    camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    passo = 150
    ordem = list(range(len(icones)))
    i = 0
    for linha, y in enumerate(range(-40, H + 40, passo - 30)):
        desloc = (passo // 2) * (linha % 2)
        for x in range(-40 + desloc, W + 40, passo):
            if i % len(ordem) == 0:
                rnd.shuffle(ordem)
            ic = icones[ordem[i % len(ordem)]]
            i += 1
            tam = rnd.randint(64, 104)
            s = ic.resize((tam, tam), Image.LANCZOS).rotate(rnd.uniform(-28, 28), Image.BICUBIC, expand=True)
            alfa = rnd.uniform(0.08, 0.14)
            a = s.getchannel("A").point(lambda v, f=alfa: int(v * f))
            s.putalpha(a)
            px = x + rnd.randint(-22, 22) - s.width // 2
            py = y + rnd.randint(-18, 18) - s.height // 2
            colar(camada, s, px, py)
    return camada


def colar(base, img, x, y):
    """alpha_composite que aceita posição negativa ou fora da imagem (recorta)."""
    cx, cy = max(0, -x), max(0, -y)
    cw, ch = min(img.width, base.width - x), min(img.height, base.height - y)
    if cx >= cw or cy >= ch:
        return
    base.alpha_composite(img.crop((cx, cy, cw, ch)), dest=(max(x, 0), max(y, 0)))


def pixels(semente):
    """'Estrelas' de pixel: quadradinhos e cruzes claras espalhadas."""
    rnd = random.Random(semente * 7)
    camada = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(camada)
    for _ in range(90):
        x, y, t = rnd.randrange(W), rnd.randrange(H), rnd.choice((3, 4, 4, 6))
        a = rnd.randint(40, 110)
        if rnd.random() < 0.3:
            d.rectangle((x - t, y - 1, x + t, y), fill=(255, 255, 255, a))
            d.rectangle((x - 1, y - t, x, y + t), fill=(255, 255, 255, a))
        else:
            d.rectangle((x, y, x + t - 1, y + t - 1), fill=(255, 255, 255, a))
    return camada


def vinheta():
    """Escurece levemente as bordas de cima e de baixo (legibilidade dos textos)."""
    g = Image.linear_gradient("L").resize((1, H))           # 0 em cima, 255 embaixo
    topo = g.point(lambda v: max(0, 60 - v) * 2)            # faixa superior
    base = g.point(lambda v: max(0, v - 200) * 2)           # faixa inferior
    m = ImageChops.lighter(topo, base).resize((W, H))
    preto = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    preto.putalpha(m)
    return preto


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    icones, saida = sys.argv[1], sys.argv[2]
    os.makedirs(saida, exist_ok=True)
    for titulo, (c1, c2, brilho, semente) in FUNDOS.items():
        img = degrade(c1, c2, brilho).convert("RGBA")
        pad = padrao(icones, semente)
        img.alpha_composite(pad.filter(ImageFilter.GaussianBlur(6)))   # brilho suave
        img.alpha_composite(pad)
        img.alpha_composite(pixels(semente))
        img.alpha_composite(vinheta())
        destino = os.path.join(saida, titulo + ".png")
        img.convert("RGB").save(destino, optimize=True)
        print("  fundo:", destino)
    for titulo, origem in COPIAS.items():
        destino = os.path.join(saida, titulo + ".png")
        if os.path.lexists(destino):
            os.remove(destino)
        os.symlink(origem + ".png", destino)
        print("  fundo:", destino, "->", origem + ".png")


if __name__ == "__main__":
    main()
