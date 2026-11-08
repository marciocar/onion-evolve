#!/usr/bin/env python3
"""Redação para o repo público das saídas da corrida (STAGE0.md §4, "Fichas"; v6 §2, a linha inteira fica fora do repo).

Uso: redact.py <termos.txt> <entrada> <saída>
Termos: os ids que door-leak-scan.sh --emit-sub-ids e --emit-word-ids derivam do members.yaml (sem caixa, por
substring), mais IPv4 e o hostname da máquina. Cada ocorrência vira <adotante>, <ip> ou <host>; caminho sob /home
vira <home>/. Imprime só quantas trocas fez, nunca o termo.
"""
import re, socket, sys

terms = sorted({t.strip() for t in open(sys.argv[1], encoding='utf-8') if len(t.strip()) >= 4}, key=len, reverse=True)
s = open(sys.argv[2], encoding='utf-8').read()
n = 0
for t in terms:
    s, k = re.subn(re.escape(t), '<adotante>', s, flags=re.I)
    n += k
s, k = re.subn(r'\b(?:\d{1,3}\.){3}\d{1,3}\b', '<ip>', s); n += k
host = socket.gethostname()
if len(host) >= 4:
    s, k = re.subn(re.escape(host), '<host>', s, flags=re.I); n += k
s, k = re.subn(r'/home/[A-Za-z0-9_.-]+/', '<home>/', s); n += k
open(sys.argv[3], 'w', encoding='utf-8').write(s)
print(f'redact: {n} trocas')
