#!/usr/bin/env python3
"""consolidate.py <B>: results.jsonl + vereditos por celula, pelas regras do pre-registro."""
import json, os, re, subprocess, sys
B = sys.argv[1]
sys.path.insert(0, B + '/lab')
import cells
runs = B + '/runs'
out = open(B + '/results.jsonl', 'w')
by = {}
for c in cells.ORDER:
    for r in (1, 2, 3):
        n = f'{c}-{r}'
        if not os.path.isdir(f'{runs}/{n}'):
            continue
        o = subprocess.run(['python3', '-I', B + '/lab/analyze.py', runs, n], capture_output=True, text=True)
        if o.returncode:
            print('ERRO', n, o.stderr[-300:])
            continue
        out.write(o.stdout)
        by.setdefault(c, []).append(json.loads(o.stdout))
out.close()


def uniq(xs):
    return sorted({str(x) for x in xs})


def seat(j):
    s = j['sec_default']
    if not s:
        return 'sem-linha'
    t = ' | '.join(s)
    return 'seated' if re.search(r'(?<!not )seated', t) else 'not seated'


def rep_verdict(j, t):
    if j['rc'] != '0' or not j['tem_init']:
        return 'INCONCLUSIVA(rc=%s)' % j['rc']
    v = (j['chamadas'].get(t) or {}).get('v') or 'INCONCLUSIVA(sem-tentativa)'
    return v


for c, js in by.items():
    d = cells.C[c]
    print(f"\n## {c} pol={d.get('policy')} pdir={d.get('pdir')} skills={d.get('skills')}@{d.get('where')} trust={d.get('trust', True)} write={d.get('write')} perm1={d.get('perm1')} same={d.get('same')} reps={len(js)}")
    print('  rc', uniq(j['rc'] for j in js), 'seat', uniq(seat(j) for j in js))
    print('  sec', uniq(s[:150] for j in js for s in j['sec_default'])[:3])
    refused = [j for j in js if j['rc'] != '0' and not j['tem_init']]
    if refused:
        print('  RECUSA stderr', uniq(j['stderr'][:200] for j in refused))
    for t in ('Read', 'Bash'):
        print(f'  {t}', [rep_verdict(j, t) for j in js], 'quem', uniq((j['chamadas'].get(t) or {}).get('quem') for j in js), 'provas', uniq((j['chamadas'].get(t) or {}).get('provas') for j in js))
    print('  controles', 'ok_bash_err', uniq((j['chamadas'].get('ok_bash') or {}).get('is_error') for j in js), 'ok_read_err', uniq((j['chamadas'].get('ok_read') or {}).get('is_error') for j in js), 'ok_bash_canario', uniq((j['chamadas'].get('ok_bash') or {}).get('canario') for j in js), 'ok_read_canario', uniq((j['chamadas'].get('ok_read') or {}).get('canario') for j in js))
    print('  hook gerenciado rodou', uniq(j['hook_gerenciado_rodou'] for j in js), 'n', uniq(j['hook_gerenciado_linhas'] for j in js), '| nega ger/proj', uniq((j['gerenciado_negou_em_evento'], j['projeto_negou_em_evento']) for j in js))
    print('  proc', uniq([(p['tool'], p['cmd'][-14:], p['leu_canario']) for p in j['proc']] for j in js)[:2])
    print('  canario em tool_result', uniq(j['canario_em_tool_result'] for j in js), 'check_seen', uniq(j['tem_check_seen'] for j in js))
    print('  mod', uniq(m[:150] for j in js for m in j['mod_linhas'])[:6])
    print('  inv', uniq(json.dumps(j['inv'], sort_keys=True) for j in js)[:2])
    sk = [{k: (v['is_error'], v['cabeca'][:60]) for k, v in j['chamadas'].items() if k.startswith('skill:')} for j in js]
    if any(sk):
        print('  skills', uniq(sk)[:2])
    if any(j['sessao1'] for j in js):
        print('  sessao1', uniq(json.dumps(j['sessao1'], ensure_ascii=False)[:600] for j in js)[:2])
    wr = [{k: (v['is_error'], v['cabeca'][:80]) for k, v in j['chamadas'].items() if k.startswith('write')} for j in js]
    if any(wr):
        print('  escrita-mesma-sessao', uniq(wr)[:2])
    print('  arquivos', uniq(j['plugin_files'] for j in js)[:2])
    print('  stderr', uniq(j['stderr'][:160] for j in js)[:2], 'load', uniq(j['load'][0] for j in js if j['load']))
