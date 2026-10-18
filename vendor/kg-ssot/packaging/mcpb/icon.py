#!/usr/bin/env python3
"""Gera o icon.png do MCPB (512x512): três nós ligados por arestas, o grafo verificável, em Python puro (zlib).
Uso: python3 -I packaging/mcpb/icon.py packaging/mcpb/icon.png"""
import math
import struct
import sys
import zlib

N = 512
BG, EDGE, NODE, RING = (31, 41, 55), (148, 163, 184), (111, 66, 193), (255, 255, 255)
NODES = [(256, 140), (140, 360), (372, 360)]
EDGES = [(0, 1), (0, 2), (1, 2)]


def seg_dist(px, py, a, b):
    (ax, ay), (bx, by) = a, b
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def pixel(x, y):
    # cantos arredondados: fora do quadrado de raio 96 nos cantos, transparente
    r = 96
    cx, cy = min(max(x, r), N - 1 - r), min(max(y, r), N - 1 - r)
    if math.hypot(x - cx, y - cy) > r:
        return (0, 0, 0, 0)
    for nx, ny in NODES:
        d = math.hypot(x - nx, y - ny)
        if d <= 46:
            return NODE + (255,)
        if d <= 58:
            return RING + (255,)
    if any(seg_dist(x, y, NODES[i], NODES[j]) <= 9 for i, j in EDGES):
        return EDGE + (255,)
    return BG + (255,)


def main(out):
    raw = b"".join(b"\x00" + b"".join(bytes(pixel(x, y)) for x in range(N)) for y in range(N))
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    with open(out, "wb") as fh:
        fh.write(png)


if __name__ == "__main__":
    main(sys.argv[1])
