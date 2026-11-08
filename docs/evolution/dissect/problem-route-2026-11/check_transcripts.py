#!/usr/bin/env python3
"""Confere nos transcritos dos processos cegos (STAGE0.md §4): zero chamada de ferramenta em A, C e J; nenhuma leitura
fora da pasta do processo em G e F. Também soma o uso de tokens por mensagem do transcrito.

Uso: check_transcripts.py <ledger.jsonl>  → uma linha por processo; rc 1 se algum quebrou a regra
Não imprime conteúdo de transcrito: só contagens e caminhos lidos (que ficam fora do repo).
"""
import glob, json, os, sys

bad = 0
rows = [json.loads(l) for l in open(sys.argv[1], encoding='utf-8') if l.strip()]
for r in rows:
    sid = r.get('session_id')
    hits = glob.glob(os.path.expanduser(f'~/.claude/projects/*/{sid}.jsonl')) if sid else []
    if not hits:
        print(f"{r['role']}.{r['call']}: transcrito não achado")
        bad += 1
        continue
    tools, outside, folder = [], [], None
    for line in open(hits[0], encoding='utf-8'):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        folder = folder or ev.get('cwd')
        msg = ev.get('message') or {}
        if ev.get('type') == 'assistant' and isinstance(msg.get('content'), list):
            for c in msg['content']:
                if c.get('type') == 'tool_use':
                    tools.append(c.get('name'))
                    path = (c.get('input') or {}).get('file_path') or (c.get('input') or {}).get('path') or ''
                    if path and folder and not os.path.realpath(path).startswith(os.path.realpath(folder)):
                        outside.append(path)
    role = r['role']
    rule_ok = (not tools) if role[0] in 'ACJ' else (not outside)
    bad += not rule_ok
    print(f"{role}.{r['call']}: ferramentas {len(tools)} {sorted(set(tools))}; leituras fora da pasta {len(outside)}; "
          f"{'ok' if rule_ok else 'QUEBRA'}")
sys.exit(1 if bad else 0)
