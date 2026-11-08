#!/usr/bin/env python3
"""Critério do parque: conta as medidas da corrida oficial da v2 (STAGE0.v3), a partir do juiz e do gabarito independente.

Uso: python3 score.py. Sai 1 se o parque se sustenta (B com menos de 3 protegidos, ou P5 acima de 20%, ou P5 com
denominador abaixo de 10); sai 0 se esses bloqueios caíram. As linhas de v1 e do pré-teste são só história.
"""
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent


def old_gabarito(rel):
    out = {}
    for line in (HERE / rel).read_text(encoding='utf-8').splitlines():
        m = re.match(r'\| ([FG]\d\d) \| (\w+) \| (\w) \| [\d-]+ \| (.*?) \| (sim|não) \|', line)
        if m:
            out[m[1]] = {'caso': m[2], 'estrato': m[3], 'protegido': m[4].startswith('sim')}
    return out


def count(gab, judge):
    sampled = [j for j in judge if gab[j['ficha']]['estrato'] != 'L']
    prot = [j for j in judge if gab[j['ficha']]['protegido']]
    prot_s = [j for j in prot if gab[j['ficha']]['estrato'] != 'L']
    free = [j for j in sampled if not gab[j['ficha']]['protegido']]
    return {
        'e1': sum(bool(j['e1']) for j in sampled), 'e1_den': len(sampled),
        'e1_l': sum(bool(j['e1']) for j in judge) - sum(bool(j['e1']) for j in sampled),
        'e2': sum(j['e2'] is True for j in prot_s), 'e2_den': len(prot_s),
        'e2_all': sum(j['e2'] is True for j in prot), 'e2_all_den': len(prot),
        'p1': sum(j['veredito'] == 'adequada' for j in sampled), 'p1_den': len(sampled),
        'p5': sum(bool(j['erro_b']) for j in free), 'p5_den': len(free),
        'erro_b': [gab[j['ficha']]['caso'] for j in free if j['erro_b']],
        'e2_falha': [gab[j['ficha']]['caso'] for j in prot if j['e2'] is not True],
    }


def show(label, c):
    print(f"{label}: E1 sorteados {c['e1']}/{c['e1_den']}, lembrados {c['e1_l']} | E2 sorteados {c['e2']}/{c['e2_den']}, "
          f"com lembrados {c['e2_all']}/{c['e2_all_den']} falhas {c['e2_falha']} | P1 {c['p1']}/{c['p1_den']} | "
          f"P5 {c['p5']}/{c['p5_den']} {c['erro_b']}")


load = lambda rel: json.loads((HERE / rel).read_text(encoding='utf-8'))
show('v1 (indício)', count(old_gabarito('GABARITO.md'), load('JUDGE.a2-on-a1.json')))
show('pré-teste', count(old_gabarito('pre-teste/GABARITO.v2.md'), load('pre-teste/JUDGE.v2.a2-on-a1.json')))
gab = {x['ficha']: x for x in load('GABARITO.v2.json')}
c = count(gab, load('JUDGE.v2.json'))
show('v2 oficial', c)
b_prot = sum(x['protegido'] for x in gab.values() if x['estrato'] == 'B')
print(f'B com ato protegido: {b_prot} (mínimo 3)')
blocked = b_prot < 3 or c['p5_den'] < 10 or c['p5'] / c['p5_den'] > 0.20
sys.exit(1 if blocked else 0)
