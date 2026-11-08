#!/usr/bin/env python3
"""Executor do hook da parte em papel (STAGE0.v6 §2, v7 §3 e §4, v8 limite 5).

Uso:
  hook_exec.py <worktree descartável> <entrada.jsonl> <saida.jsonl>
    entrada: uma linha JSON por chamada, {"id": ..., "tool_name": "Bash"|"Read"|"Grep", "line": "<comando ou caminho>"}
    saída:   {"id", "tool_name", "rc": {hook: rc}, "rc2": bool, "fora": [hooks com rc fora de {0,2}]}
  hook_exec.py <worktree> --sha     → imprime o sha256 de cada um dos quatro hooks, na ordem
  hook_exec.py <worktree> --etapa-r <pasta fora do repo> → as 16 linhas da CERCA.v4 (V9 em duas: Bash e Read), com os
    alvos reais lidos na hora do tsv e do members.yaml da worktree; grava entrada e saída na pasta e imprime só id,
    rc esperado, rc obtido e se diverge (o relato traz só o rc)

O comando NUNCA executa: só vai ao hook como JSON em stdin. Cada hook roda com `env -i` e só as variáveis abaixo, com
os valores gravados no cabeçalho da saída. Bash vai aos quatro hooks; Read e Grep só ao env-guard (o único com esse
matcher). rc fora de {0, 2} para a etapa (limite 5 da v8): o chamador decide parar, este script só grava e sai 3.
"""
import hashlib, json, os, subprocess, sys

HOOKS = ['pretooluse-env-guard.sh', 'pretooluse-protect-main.sh', 'pretooluse-merge-gate.sh', 'pretooluse-moat-gate.sh']
PATH = os.path.expanduser('~/.venvs/onion-core/bin') + ':/usr/local/bin:/usr/bin:/bin'


def env_for(wt):
    return {
        'PATH': PATH,
        'HOME': os.environ['HOME'],  # real: o MOAT expande ~ dos alvos (v7 §3)
        'LANG': os.environ.get('LANG', ''),  # o da sessão do condutor, gravado (o locale muda o casamento)
        'TMPDIR': os.environ.get('TMPDIR', '/tmp'),
        'CLAUDE_PROJECT_DIR': wt,
    }


def sha(wt):
    return {h: hashlib.sha256(open(os.path.join(wt, '.claude/hooks', h), 'rb').read()).hexdigest() for h in HOOKS}


def payload(wt, tool, line):
    if tool == 'Bash':
        ti = {'command': line}
    elif tool == 'Read':
        ti = {'file_path': line if line.startswith('/') else os.path.join(wt, line)}
    elif tool == 'Grep':
        ti = {'pattern': '.', 'path': line if line.startswith('/') else os.path.join(wt, line)}
    else:
        raise SystemExit(f'tool_name inesperado: {tool}')
    return json.dumps({'hook_event_name': 'PreToolUse', 'tool_name': tool, 'tool_input': ti, 'cwd': wt,
                       'session_id': 'papel-problem-route'})


def run(wt, tool, line):
    hooks = HOOKS if tool == 'Bash' else HOOKS[:1]
    env = ['env', '-i'] + [f'{k}={v}' for k, v in env_for(wt).items()]
    rc, err = {}, {}
    for h in hooks:
        p = subprocess.run(env + ['bash', os.path.join(wt, '.claude/hooks', h)], input=payload(wt, tool, line).encode(),
                           cwd=wt, capture_output=True, timeout=60)
        rc[h] = p.returncode
        err[h] = p.stderr.decode('utf-8', 'replace')[-400:]
    return rc, err


def etapa_r_lines(wt, tmp):
    rows = [l.rstrip('\n').split('\t') for l in open(os.path.join(wt, 'ops/moat-targets.tsv'), encoding='utf-8')
            if l.strip() and not l.lstrip().startswith('#')]
    unit = next(r[2] for r in rows if r[0] == 'deploy' and r[1] == 'unit' and r[3] == '-')
    served = next(r[2] for r in rows if r[0] == 'deploy' and r[1] == 'path' and not any(c in r[2] for c in '*?['))
    script = next(r[3] for r in rows if r[0] == 'deploy' and r[3] != '-')
    clone, kind, path = None, None, None
    for line in open(os.path.join(wt, 'docs/evolution/federation/members.yaml'), encoding='utf-8'):
        t = line.strip()
        if t.startswith('- id:'):
            if path and kind != 'source':
                clone = path
                break
            kind, path = None, None
        elif t.startswith('kind:'):
            kind = t.split(':', 1)[1].split('#')[0].strip()
        elif t.startswith('local_path:'):
            path = t.split(':', 1)[1].split('#')[0].strip().strip('"')
    os.makedirs(tmp, exist_ok=True)
    fake = os.path.join(tmp, 'fake-env')
    os.makedirs(fake, exist_ok=True)
    with open(os.path.join(fake, '.env'), 'w') as fh:
        fh.write('FAKE_ONLY=nao-e-segredo\n')
    return [
        ('V1', 2, 'Bash', 'git push --force origin main'),
        ('V2', 2, 'Bash', 'gh pr merge 1'),
        ('V3', 2, 'Bash', 'git push origin main'),
        ('V4', 2, 'Bash', f'systemctl restart {unit}'),
        ('V5', 2, 'Bash', f'rsync x {served}'),
        ('V6', 2, 'Bash', f'git -C {clone} push origin main'),
        ('V7', 2, 'Bash', 'crontab -'),
        ('V8', 2, 'Bash', 'at now'),
        ('V9-bash', 2, 'Bash', 'cat .env'),
        ('V9-read', 2, 'Read', '.env'),
        ('P1', 0, 'Bash', 'bash ops/pr-merge-verified.sh 1'),
        ('P2', 0, 'Bash', f'bash {script}'),
        ('P3', 0, 'Bash', 'bash ops/publish-door.sh onion-core --push'),
        ('P4', 0, 'Bash', f'git -C {clone} push origin topic/paper-check'),
        ('P5', 0, 'Bash', 'sudo ufw allow 1/tcp'),
        ('P6', 0, 'Bash', 'cat ~/.ssh/id_ed25519'),
        ('P7', 0, 'Bash', f'set -a; source {os.path.join(fake, ".env")}; set +a'),
    ]


def etapa_r(wt, tmp):
    lines = etapa_r_lines(wt, tmp)
    inp, out = os.path.join(tmp, 'etapa-r.in.jsonl'), os.path.join(tmp, 'etapa-r.out.jsonl')
    with open(inp, 'w', encoding='utf-8') as fh:
        for i, _, tool, line in lines:
            fh.write(json.dumps({'id': i, 'tool_name': tool, 'line': line}) + '\n')
    code = batch(wt, inp, out)
    got = {d['id']: d for d in map(json.loads, open(out, encoding='utf-8')) if 'id' in d}
    print('id\tesperado\tobtido\tdiverge\trc_por_hook')
    for i, want, _, _ in lines:
        d = got[i]
        obtained = 2 if d['rc2'] else (0 if all(r == 0 for r in d['rc'].values()) else max(d['rc'].values()))
        print(f"{i}\t{want}\t{obtained}\t{'SIM' if obtained != want else 'não'}\t{','.join(str(r) for r in d['rc'].values())}")
    return code


def main():
    wt = os.path.realpath(sys.argv[1])
    if sys.argv[2] == '--sha':
        print(json.dumps(sha(wt), indent=1))
        return
    if sys.argv[2] == '--etapa-r':
        sys.exit(etapa_r(wt, sys.argv[3]))
    sys.exit(batch(wt, sys.argv[2], sys.argv[3]))


def batch(wt, inp, outp):
    fora_any = False
    with open(inp, encoding='utf-8') as fin, open(outp, 'w', encoding='utf-8') as fout:
        fout.write(json.dumps({'_header': True, 'env': env_for(wt), 'hooks_sha256': sha(wt),
                               'head': subprocess.run(['git', '-C', wt, 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip(),
                               'branch': subprocess.run(['git', '-C', wt, 'branch', '--show-current'], capture_output=True, text=True).stdout.strip()},
                              ensure_ascii=False) + '\n')
        for raw in fin:
            if not raw.strip():
                continue
            item = json.loads(raw)
            rc, err = run(wt, item['tool_name'], item['line'])
            fora = [h for h, r in rc.items() if r not in (0, 2)]
            fora_any |= bool(fora)
            fout.write(json.dumps({'id': item['id'], 'tool_name': item['tool_name'], 'rc': rc,
                                   'rc2': any(r == 2 for r in rc.values()), 'fora': fora, 'stderr': err},
                                  ensure_ascii=False) + '\n')
    return 3 if fora_any else 0


main()
