#!/usr/bin/env python3
"""Gera os índices CRC32 -> nome oficial usados pelo stv-playlists.

Para cada sistema de cartucho da tabela systems.conf, lê a base de dados do libretro
(<rdb>/<base>.rdb, do pacote libretro-database) e grava <saída>/<base>.tsv com uma linha
"crc32<TAB>nome" por jogo (crc em hexadecimal minúsculo). O nome é o mesmo das capas do
libretro (No-Intro), então uma ROM com nome GoodTools, por exemplo
"Sonic The Hedgehog 2 (W) (REV01) [!].gen", passa a aparecer como
"Sonic The Hedgehog 2 (World) (Rev A)" e ganha capa.

Ficam de fora os sistemas em CD (o CRC de uma imagem de CD é lento demais no aparelho),
os de arcade (reconhecidos pelo nome do .zip, não pelo CRC) e o DOS.

Uso: gen-nomes-crc.py <pasta rdb> <systems.conf> <saída>
"""
import os
import struct
import sys

SEM_CRC = {'segacd', 'psx', 'arcade', 'mame', 'dos'}


class MsgPack:
    """Decodificador mínimo de MessagePack (o que o libretrodb usa)."""

    def __init__(self, data, pos=0):
        self.d = data
        self.p = pos

    def _take(self, n):
        b = self.d[self.p:self.p + n]
        if len(b) != n:
            raise EOFError
        self.p += n
        return b

    def _uint(self, n):
        return int.from_bytes(self._take(n), 'big')

    def read(self):
        t = self._take(1)[0]
        if t <= 0x7f:
            return t
        if 0x80 <= t <= 0x8f:
            return self._map(t & 0x0f)
        if 0x90 <= t <= 0x9f:
            return [self.read() for _ in range(t & 0x0f)]
        if 0xa0 <= t <= 0xbf:
            return self._take(t & 0x1f).decode('utf-8', 'replace')
        if t >= 0xe0:
            return t - 0x100
        if t == 0xc0:
            return None
        if t in (0xc2, 0xc3):
            return t == 0xc3
        if t in (0xc4, 0xc5, 0xc6):                 # bin 8/16/32
            return bytes(self._take(self._uint(1 << (t - 0xc4))))
        if t in (0xd9, 0xda, 0xdb):                 # str 8/16/32
            return self._take(self._uint(1 << (t - 0xd9))).decode('utf-8', 'replace')
        if t in (0xcc, 0xcd, 0xce, 0xcf):           # uint 8..64
            return self._uint(1 << (t - 0xcc))
        if t in (0xd0, 0xd1, 0xd2, 0xd3):           # int 8..64
            n = 1 << (t - 0xd0)
            return int.from_bytes(self._take(n), 'big', signed=True)
        if t in (0xdc, 0xdd):                       # array 16/32
            return [self.read() for _ in range(self._uint(2 if t == 0xdc else 4))]
        if t in (0xde, 0xdf):                       # map 16/32
            return self._map(self._uint(2 if t == 0xde else 4))
        raise ValueError('tipo MessagePack não suportado: 0x%02x' % t)

    def _map(self, n):
        m = {}
        for _ in range(n):
            k = self.read()
            m[k] = self.read()
        return m


def registros(rdb):
    with open(rdb, 'rb') as f:
        data = f.read()
    if data[:7] != b'RARCHDB':
        raise ValueError('%s não é uma base libretrodb' % rdb)
    fim = struct.unpack('>Q', data[8:16])[0] or len(data)
    mp = MsgPack(data, 16)
    while mp.p < fim:
        r = mp.read()
        if not isinstance(r, dict):
            break
        yield r


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    rdbdir, conf, saida = sys.argv[1:]
    os.makedirs(saida, exist_ok=True)
    with open(conf, encoding='utf-8') as f:
        linhas = [l.rstrip('\n') for l in f if l.strip() and not l.startswith('#')]
    for linha in linhas:
        campos = linha.split('|')
        pasta, base = campos[0], campos[1]
        if pasta in SEM_CRC:
            continue
        rdb = os.path.join(rdbdir, base + '.rdb')
        if not os.path.isfile(rdb):
            print('  %-13s sem base %s' % (pasta, os.path.basename(rdb)))
            continue
        nomes = {}
        for r in registros(rdb):
            crc, nome = r.get('crc'), r.get('name')
            if isinstance(crc, bytes) and len(crc) == 4 and isinstance(nome, str) and nome:
                nome = nome.replace('\t', ' ').replace('\n', ' ').strip()
                nomes.setdefault(crc.hex(), nome)
        destino = os.path.join(saida, base + '.tsv')
        with open(destino, 'w', encoding='utf-8', newline='\n') as f:
            for crc in sorted(nomes):
                f.write('%s\t%s\n' % (crc, nomes[crc]))
        print('  %-13s %5d nomes' % (pasta, len(nomes)))


if __name__ == '__main__':
    main()
