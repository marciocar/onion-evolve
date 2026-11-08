#!/usr/bin/env python3
"""Sorteio determinístico da amostra da problem-formula (STAGE0.md §4 + STAGE0.v2.md §A).

Uso: sample.py <semente> [--census]. Lista, por estrato e em ordem de rank, os candidatos ainda não tomados.
Só imprime identificadores; os pulos (e o motivo) são decisão registrada em SAMPLE.md, na ordem que este script dá.
"""
import hashlib, re, subprocess, sys
import yaml

# Filtro do estrato B desde a STAGE0.v3 §5 (o antigo casava 60% do universo).
B = re.compile(r'merge (alheio|em repo|no ramo|na main|no main|de terceiro)|deploy|segredo|credencial|rotaç[ãa]o de chave|ufw|firewall|force.push|sudo|\.env\b|sem autoriz', re.I)
C = re.compile(r'falso alarme|falso positivo|false positive|não era|refutad|não procede|alarme falso', re.I)
OTHER_MARK = 'resposta livre do maestro, fora das opções oferecidas'
DIARY = 'docs/evolution/research/session-orchestration-2026-11/DIARIO.md'
OWN = 'docs/evolution/dissect/problem-formula-2026-11/'
QUOTA = {'B': 4, 'C': 3, 'D': 3, 'E': 2, 'A': 8}


def tracked(*paths):
    out = subprocess.run(['git', 'ls-files', '-z', '--', *paths], capture_output=True, check=True).stdout
    return [p for p in out.decode().split('\0') if p]


def read(path):
    with open(path, encoding='utf-8', errors='replace') as fh:
        return fh.read()


def text_items():
    items = {p: read(p) for p in tracked('docs/evolution/inbox/_processed', 'docs/evolution/review')}
    parts = re.split(r'(?m)^(?=#{2,3} )', read(DIARY))
    for part in parts[1:]:
        items[f"{DIARY}::{part.splitlines()[0].strip()}"] = part
    return items


def graph_nodes():
    d, e, unreadable = [], [], []
    for path in tracked('*.kg.yaml'):
        if path.startswith(('vendor/', OWN)) or 'fixture' in path:
            continue
        try:
            doc = yaml.safe_load(read(path))
        except yaml.YAMLError:
            unreadable.append(path)
            continue
        for node in (doc or {}).get('nodes') or []:
            if not isinstance(node, dict):
                continue
            key = f"{path}#{node.get('id')}"
            if node.get('owner') == 'maestro':
                d.append((key, node.get('status')))
            if OTHER_MARK in str(node.get('narrative') or ''):
                e.append((key, node.get('status')))
    return d, e, unreadable


def main():
    seed = sys.argv[1]
    rank = lambda x: hashlib.sha256(f'{seed}|{x}'.encode()).hexdigest()
    items = text_items()
    d, e, unreadable = graph_nodes()
    pools = {
        'B': [k for k, t in items.items() if B.search(t)],
        'C': [k for k, t in items.items() if C.search(t)],
        'D': [k for k, _ in d],
        'E': [k for k, _ in e],
        'A': list(items),
    }
    status = dict(d + e)
    # Sorteio da v2: nada do que a v1 já tomou ou pulou entra de novo (STAGE0.md, tabela de veredito).
    # --exclude pode repetir; linha `sha256:<hex>` exclui caminho que não se escreve em texto público.
    used = set()
    for i, arg in enumerate(sys.argv):
        if arg == '--exclude':
            used |= set(read(sys.argv[i + 1]).split())
    gone = lambda x: x in used or 'sha256:' + hashlib.sha256(x.encode()).hexdigest() in used
    pools = {k: [x for x in v if not gone(x)] for k, v in pools.items()}
    print(f'universo: {len(items)} itens de texto; D {len(d)} nós; E {len(e)} nós; grafos ilegíveis: {len(unreadable)} {unreadable}')
    for name, nodes in (('D', d), ('E', e)):
        opened = sum(1 for _, s in nodes if s == 'open')
        print(f'censo {name}: total {len(nodes)}, abertos {opened}')
    if '--census' in sys.argv:
        return
    for name in 'BCDEA':
        ordered = sorted(pools[name], key=rank)
        print(f'\n## {name} (cota {QUOTA[name]}, pool {len(ordered)})')
        for key in ordered[:QUOTA[name] * 6]:
            print(f"{key}" + (f"  [{status[key]}]" if key in status else ''))


main()
