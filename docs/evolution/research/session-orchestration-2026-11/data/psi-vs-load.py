#!/usr/bin/env python3
"""Qual sinal do instante prevê melhor a fila de CPU dos 10 min seguintes: o load de 1 min ou o PSI?

Entrada: psi-vs-load-2026-11-06.tsv (sysstat desta VPS, 8 vCPUs). Alvo: o PSI cpu some MÉDIO do intervalo
seguinte (fração do tempo com alguma tarefa esperando CPU), que é a fila que derrubou o gate. Uso:
    python3 -I psi-vs-load.py psi-vs-load-2026-11-06.tsv
"""
import statistics as st
import sys

rows = []
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("#") or line.startswith("timestamp"):
        continue
    t, l1, rq, p10, pint = line.rstrip("\n").split("\t")
    rows.append((t, float(l1), int(rq), float(p10), float(pint)))


def corr(a, b):
    ma, mb = st.mean(a), st.mean(b)
    sa = sum((x - ma) ** 2 for x in a) ** 0.5
    sb = sum((y - mb) ** 2 for y in b) ** 0.5
    return sum((x - ma) * (y - mb) for x, y in zip(a, b)) / (sa * sb)


L = [r[1] for r in rows[:-1]]
P = [r[3] for r in rows[:-1]]
nxt = [r[4] for r in rows[1:]]
print(f"intervalos: {len(rows)} ({rows[0][0]} a {rows[-1][0]})")
print(f"corr(load1 do instante, espera média dos 10 min seguintes) = {corr(L, nxt):.3f}")
print(f"corr(psi avg10 do instante, espera média dos 10 min seguintes) = {corr(P, nxt):.3f}")
for thr in (30, 40):
    bad = [s >= thr for s in nxt]
    nb = sum(bad)
    print(f"alvo: intervalo seguinte com espera >= {thr}% ({nb} de {len(bad)})")
    for name, X, cuts in (("load1", L, (8, 10, 12, 15)), ("psi10", P, (20, 30, 40))):
        for c in cuts:
            pred = [x >= c for x in X]
            tp = sum(a and b for a, b in zip(pred, bad))
            fp = sum(a and not b for a, b in zip(pred, bad))
            print(f"  {name} >= {c:<3} pega {tp}/{nb} · alarme falso {fp}")
