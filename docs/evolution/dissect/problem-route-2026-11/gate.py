#!/usr/bin/env python3
"""Portão de integridade da parte em papel (STAGE0.v2 §10, v6 §4, v7 §4). Roda antes de cada etapa de (a).

Uso: python3 gate.py   (de qualquer lugar; resolve a raiz pelo git)
Sai 0 só se: GATE.txt existe, o reviewed_hash é o `git log -1` dos arquivos revisados, o kg_criterion.py confere o
sha256 de cada versão da Etapa 0, e todo nó com x_sha256 bate com o sha256sum do arquivo do trace. Sai 1 se diverge,
2 se não deu para julgar.
"""
import hashlib, json, os, subprocess, sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = subprocess.run(['git', '-C', HERE, 'rev-parse', '--show-toplevel'], capture_output=True, text=True, check=True).stdout.strip()
REL = os.path.relpath(HERE, ROOT)
KG = os.path.join(HERE, 'problem-route-2026-11.kg.yaml')


def fail(msg, rc=1):
    print(f'gate: ✗ {msg}')
    sys.exit(rc)


gate = os.path.join(HERE, 'GATE.txt')
if not os.path.exists(gate):
    fail('GATE.txt ausente')
fields = {}
for line in open(gate, encoding='utf-8'):
    if ':' in line:
        k, v = line.split(':', 1)
        fields[k.strip()] = v.strip()
if not fields.get('curadoria_response') or fields.get('reviewed_hash', '') not in fields['curadoria_response']:
    fail('curadoria_response ausente ou sem o reviewed_hash')
files = [os.path.join(REL, f) for f in fields.get('reviewed_files', '').split()]
want = subprocess.run(['git', '-C', ROOT, 'log', '-1', '--format=%H', '--', *files], capture_output=True, text=True).stdout.strip()
if not files or want != fields['reviewed_hash']:
    fail(f'reviewed_hash {fields.get("reviewed_hash")} != git log -1 dos arquivos revisados ({want})')

p = subprocess.run([sys.executable, '-I', '-B', os.path.join(ROOT, 'vendor/kg-ssot/tools/kg_criterion.py'), 'check',
                    '--root', ROOT, '--format', 'json', KG], capture_output=True, text=True)
try:
    d = json.loads(p.stdout)
except ValueError:
    fail(f'kg_criterion.py não julgou (rc {p.returncode})', 2)
if d.get('findings') or d.get('unreadable') or p.returncode != 0:
    fail(f'kg_criterion.py: {d.get("findings")} {d.get("unreadable")}')

n = 0
for node in yaml.safe_load(open(KG, encoding='utf-8'))['nodes']:
    if 'x_sha256' in node:
        path = os.path.join(ROOT, node['trace'])
        if not os.path.exists(path):
            fail(f'{node["id"]}: {node["trace"]} ausente')
        got = hashlib.sha256(open(path, 'rb').read()).hexdigest()
        if got != node['x_sha256']:
            fail(f'{node["id"]}: sha256 {got} != {node["x_sha256"]}')
        n += 1
        if node['trace'].endswith('MANIFEST.sha256'):
            # o manifesto cobre os scripts de condução e os prompts: cada linha confere
            for line in open(path, encoding='utf-8'):
                want_sha, rel = line.split(None, 1)
                rel = rel.strip()
                got = hashlib.sha256(open(os.path.join(HERE, rel), 'rb').read()).hexdigest()
                if got != want_sha:
                    fail(f'MANIFEST: {rel} sha256 {got} != {want_sha}')
                n += 1
print(f'gate: ✓ GATE.txt em {fields["reviewed_hash"][:9]}, critério conferido ({d.get("criteria")} versões), {n} artefatos com sha256')
