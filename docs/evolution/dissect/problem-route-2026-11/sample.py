#!/usr/bin/env python3
"""Filas do problem-route (STAGE0.md §4, com as emendas até a v8), lidas da árvore de um commit.

Uso: sample.py <semente> <commit> (--census | --dump <pasta> | --materialize <pasta> --carga <tsv do carga.sh>)

- Universo: o de problem-formula-2026-11/sample.py (inbox processado, review/, entradas do diário, nós `owner: maestro`,
  nós de resposta livre), lido de `git show <commit>:<caminho>` (STAGE0.v2: a parte em papel roda sobre a árvore de
  5773269bc), menos USED.txt, menos itens que citam problem-formula|problem-route|FORMULA\\.v|BULBO.
- rank(x) = sha256(semente + "|" + x), crescente.
- Filas, na ordem: FR, FF, FV, B, A, com o teto de leitura de cada uma.
- A exclusão por carga do .env (STAGE0.v6 §3, v7 §4) NÃO é feita aqui: é do carga.sh, por /usr/bin/grep (v8, limite 1).
  Com --carga, os itens que o carga.sh marcou como casados saem da fila, e a fila se repõe em ordem de rank.
- --materialize grava cada item da fila (até o teto + 20 de reposição) como arquivo de texto em <pasta>, com nome
  opaco <fila>-<ordem>.txt, e um índice JSON fora do repo. Não decide pulo nem classe: isso é de G1.
"""
import hashlib, json, os, re, subprocess, sys

import yaml

B = re.compile(r'merge (alheio|em repo|no ramo|na main|no main|de terceiro)|deploy|segredo|credencial|rotaç[ãa]o de chave|ufw|firewall|force.push|sudo|\.env\b|sem autoriz', re.I)
FR = re.compile(r'pr[óo]pria r[ée]gua|pr[óo]prio crit[ée]rio|rebaix|afrouxa|renovar a pr[óo]pria|julga[rn]? a si|juiz em causa pr[óo]pria|mesma sess[ãa]o que (forjou|escreveu)', re.I)
FF = re.compile(r'licen[cç]a|termos? de uso|banimento|LGPD|contrato|depende d[oa] (dono|conta)|risco de conta', re.I)
STUDY = re.compile(r'problem-formula|problem-route|FORMULA\.v|BULBO')
OTHER_MARK = 'resposta livre do maestro, fora das opções oferecidas'
DIARY = 'docs/evolution/research/session-orchestration-2026-11/DIARIO.md'
OWN = ('docs/evolution/dissect/problem-formula-2026-11/', 'docs/evolution/dissect/problem-route-2026-11/')
USED = 'docs/evolution/dissect/problem-route-2026-11/USED.txt'
CAP = {'FR': 30, 'FF': 30, 'FV': 20, 'B': 40, 'A': 40}
REPOSE = 20  # STAGE0.v7 §1: teto de 20 repostos por classe; materializa-se essa folga além do teto de leitura


def git(*args):
    return subprocess.run(['git', *args], capture_output=True, check=True).stdout


def tracked(commit, *paths):
    out = git('ls-tree', '--full-tree', '-r', '-z', '--name-only', commit, '--', *paths)
    return [p for p in out.decode().split('\0') if p]


def show(commit, path):
    return git('show', f'{commit}:{path}').decode('utf-8', errors='replace')


def text_items(commit):
    items = {p: show(commit, p) for p in tracked(commit, 'docs/evolution/inbox/_processed', 'docs/evolution/review')}
    parts = re.split(r'(?m)^(?=#{2,3} )', show(commit, DIARY))
    for part in parts[1:]:
        items[f"{DIARY}::{part.splitlines()[0].strip()}"] = part
    return items


def graph_nodes(commit):
    """FV: nós owner: maestro e nós de resposta livre, com o texto do nó em YAML."""
    fv, unreadable = {}, []
    paths = [p for p in tracked(commit) if p.endswith('.kg.yaml')]
    for path in paths:
        if path.startswith('vendor/') or path.startswith(OWN) or 'fixture' in path:
            continue
        try:
            doc = yaml.safe_load(show(commit, path))
        except yaml.YAMLError:
            unreadable.append(path)
            continue
        for node in (doc or {}).get('nodes') or []:
            if not isinstance(node, dict):
                continue
            if node.get('owner') == 'maestro' or OTHER_MARK in str(node.get('narrative') or ''):
                fv[f"{path}#{node.get('id')}"] = yaml.safe_dump(node, allow_unicode=True, sort_keys=False)
    return fv, unreadable


def used_set(commit):
    return set(show(commit, USED).split())


def build(seed, commit):
    rank = lambda x: hashlib.sha256(f'{seed}|{x}'.encode()).hexdigest()
    items = text_items(commit)
    fv, unreadable = graph_nodes(commit)
    used = used_set(commit)
    gone = lambda x: x in used or 'sha256:' + hashlib.sha256(x.encode()).hexdigest() in used
    allt = {**items, **fv}
    study = {k for k, t in allt.items() if STUDY.search(t) or STUDY.search(k)}
    keep = lambda k: not gone(k) and k not in study
    text = {k: t for k, t in items.items() if keep(k)}
    nodes = {k: t for k, t in fv.items() if keep(k)}
    pools = {
        'FR': [k for k, t in text.items() if FR.search(t)],
        'FF': [k for k, t in text.items() if FF.search(t)],
        'FV': list(nodes),
        'B': [k for k, t in text.items() if B.search(t)],
        'A': list(text),
    }
    pools = {q: sorted(v, key=rank) for q, v in pools.items()}
    stats = {
        'universo_texto': len(items), 'universo_fv': len(fv), 'ilegiveis': unreadable,
        'fora_used_texto': sum(1 for k in items if not gone(k)),
        'citam_estudo_texto': sum(1 for k in items if not gone(k) and k in study),
        'citam_estudo_fv': sum(1 for k in fv if not gone(k) and k in study),
        'fv_antes_used': len(fv),
        'pools': {q: len(v) for q, v in pools.items()},
    }
    return pools, allt, stats


def main():
    seed, commit = sys.argv[1], sys.argv[2]
    pools, allt, stats = build(seed, commit)
    print(json.dumps(stats, ensure_ascii=False))
    if '--census' in sys.argv:
        return
    if '--dump' in sys.argv:
        # todo item de alguma fila vira arquivo opaco, para o carga.sh julgar por /usr/bin/grep linha a linha
        out = sys.argv[sys.argv.index('--dump') + 1]
        os.makedirs(out, exist_ok=True)
        keys = sorted({k for v in pools.values() for k in v})
        with open(os.path.join(out, 'keys.tsv'), 'w', encoding='utf-8') as idx:
            for key in keys:
                h = hashlib.sha256(key.encode()).hexdigest()[:20]
                with open(os.path.join(out, h + '.txt'), 'w', encoding='utf-8') as fh:
                    fh.write(allt[key])
                idx.write(f'{h}\t{key}\n')
        print(f'dump: {len(keys)} itens')
        return
    excluded = set()
    if '--carga' in sys.argv:
        with open(sys.argv[sys.argv.index('--carga') + 1], encoding='utf-8') as fh:
            for line in fh:
                parts = line.rstrip('\n').split('\t')
                if len(parts) == 2 and parts[1] == 'CASA':
                    excluded.add(parts[0])
    out = sys.argv[sys.argv.index('--materialize') + 1]
    os.makedirs(out, exist_ok=True)
    index, report = {}, {}
    for q in CAP:
        n, skipped = 0, 0
        for key in pools[q]:
            if key in excluded:
                skipped += 1
                continue
            n += 1
            if n > CAP[q] + REPOSE:
                break
            name = f'{q}-{n:03d}.txt'
            with open(os.path.join(out, name), 'w', encoding='utf-8') as fh:
                fh.write(allt[key])
            index[name] = key
        report[q] = {'materializados': n if n <= CAP[q] + REPOSE else CAP[q] + REPOSE, 'excluidos_por_carga_ate_aqui': skipped}
    with open(out.rstrip('/') + '.index.json', 'w', encoding='utf-8') as fh:
        json.dump(index, fh, ensure_ascii=False, indent=1)
    print(json.dumps(report, ensure_ascii=False))


main()
