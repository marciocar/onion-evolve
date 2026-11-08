#!/usr/bin/env python3
"""Monta os prompts dos processos cegos e lê as respostas (condução mecânica; não marca nem julga).

Uso: build.py <modo> <pasta de trabalho fora do repo> [args]
  presented               → presented.json: os candidatos por fila em ordem de rank, até o teto (+20 de folga)
  g1 | g2 | f | leak      → prompt.<modo>.md
  apply rota|formula      → prompt.apply-<x>.md
  hookin                  → hook.in.jsonl, das linhas de comando das fichas
  hookout                 → hook.json: {arquivo: rc2}
  j                       → prompt.j.md e codes.json (código opaco por rota)
  parse <saida.json> <destino.json>  → extrai o array JSON do campo result
"""
import hashlib, json, os, random, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SEED = '5773269bc1b25df57129601717c0029ff6f36be0'
CAP = {'FR': 30, 'FF': 30, 'FV': 20, 'B': 40, 'A': 40}
rank = lambda x: hashlib.sha256(f'{SEED}|{x}'.encode()).hexdigest()


def rd(p):
    with open(p, encoding='utf-8') as fh:
        return fh.read()


def jl(p):
    return json.loads(rd(p))


def wr(p, s):
    with open(p, 'w', encoding='utf-8') as fh:
        fh.write(s if isinstance(s, str) else json.dumps(s, ensure_ascii=False, indent=1))


def presented(w):
    idx = jl(os.path.join(w, 'cand.index.json'))
    rows = []
    for name, key in idx.items():
        q, pos = name[:-4].rsplit('-', 1)
        rows.append({'file': name, 'key': key, 'queue': q, 'pos': int(pos)})
    order = list(CAP)
    rows.sort(key=lambda r: (order.index(r['queue']), r['pos']))
    wr(os.path.join(w, 'presented.json'), rows)


def cand_block(w, rows):
    out = []
    for r in rows:
        out.append(f"--- arquivo: {r['file']} | origem: {r['key']} ---\n{rd(os.path.join(w, 'cand', r['file']))}\n")
    return '\n'.join(out)


def g(w, which):
    rows = jl(os.path.join(w, 'presented.json'))
    if which == 'g1':
        seen, pick = set(), []
        for r in rows:
            if r['pos'] > CAP[r['queue']] or r['key'] in seen:
                continue
            seen.add(r['key'])
            pick.append(r)
        tarefa = ('Leia os candidatos na ordem. Para cada um, decida primeiro se ele é **pulado**, e só por um destes '
                  'motivos: `sem problema` (não contém problema nenhum), `sem data` (nem o texto traz data), `duplicata` '
                  '(duplica um incidente de candidato anterior desta lista ou de item da USED; diga qual). Item ainda '
                  'aberto é elegível. Não pule por nenhum outro motivo; quantos casos entram não é decisão sua.')
        pulo = 'Pulado: `"pulo": "<motivo>"`, `"pulo_motivo": "<frase>"`, `"atos": []`.'
    else:
        acc = jl(os.path.join(w, 'accept.json'))['accepted'] + (jl(os.path.join(w, 'repose.json')) if os.path.exists(os.path.join(w, 'repose.json')) else [])
        done = {m['arquivo'] for m in jl(os.path.join(w, 'g2.json'))} if os.path.exists(os.path.join(w, 'g2.json')) else set()
        pick = [r for r in acc if r['file'] not in done]
        tarefa = 'Todos os candidatos abaixo já foram aceitos: você não decide pulo nem quantos entram.'
        pulo = 'Use sempre `"pulo": null`.'
    t = rd(os.path.join(HERE, 'prompts/G.md'))
    t = t.replace('{{TAREFA}}', tarefa).replace('{{PULO}}', pulo)
    t = t.replace('{{CERCA}}', rd(os.path.join(HERE, 'CERCA.v4.md'))).replace('{{USED}}', rd(os.path.join(HERE, 'USED.txt')))
    t = t.replace('{{CANDIDATOS}}', cand_block(w, pick))
    wr(os.path.join(w, f'prompt.{which}.md'), t)
    print(f'{which}: {len(pick)} candidatos')


def accepted_codes(w):
    """Casos aceitos (aceite + reposição), em ordem de rank('F'+chave), com código P01..; estável ao repor."""
    acc = jl(os.path.join(w, 'accept.json'))['accepted']
    rep = jl(os.path.join(w, 'repose.json')) if os.path.exists(os.path.join(w, 'repose.json')) else []
    base = sorted(acc, key=lambda r: rank('F' + r['key']))
    rows = base + sorted(rep, key=lambda r: rank('F' + r['key']))
    return [(f'P{i + 1:02d}', r) for i, r in enumerate(rows)]


def f(w):
    done = set(jl(os.path.join(w, 'fichas.raw.json')).keys()) if os.path.exists(os.path.join(w, 'fichas.raw.json')) else set()
    pick = [(c, r) for c, r in accepted_codes(w) if c not in done]
    mats = '\n'.join(f"--- código: {c} ---\n{rd(os.path.join(w, 'cand', r['file']))}\n" for c, r in pick)
    t = rd(os.path.join(HERE, 'prompts/F.md')).replace('{{EXTRA}}', '').replace('{{MATERIAIS}}', mats)
    wr(os.path.join(w, 'prompt.f.md'), t)
    print(f'f: {len(pick)} materiais')


def fichas_block(w, with_origin, only=None):
    raw = jl(os.path.join(w, 'fichas.raw.json'))
    out = []
    for c, r in accepted_codes(w):
        if c not in raw or (only is not None and c not in only):
            continue
        x = raw[c]
        cmds = '\n'.join(f"  - [{k['tool']}] {k['line']}" for k in x.get('comandos', [])) or '  (nenhum)'
        head = f"--- ficha {c}" + (f" | origem: {r['key']}" if with_origin else '') + ' ---'
        out.append(f"{head}\n{x['ficha']}\ncomandos:\n{cmds}\n")
    return '\n'.join(out)


def leak(w):
    only = set(sys.argv[3].split(',')) if len(sys.argv) > 3 else None
    t = rd(os.path.join(HERE, 'prompts/LEAK.md')).replace('{{FICHAS}}', fichas_block(w, True, only))
    wr(os.path.join(w, 'prompt.leak.md'), t)


def apply(w, which):
    text = rd(os.path.join(HERE, 'ROTA.v5.md')) if which == 'rota' else rd(os.path.join(HERE, '../problem-formula-2026-11/FORMULA.v2.md'))
    final = {c['file'] for c in jl(os.path.join(w, 'classes.json')) if c['status'] == 'aceito'}
    codes = [c for c, r in accepted_codes(w) if r['file'] in final]
    t = rd(os.path.join(HERE, 'prompts/APPLY.md')).replace('{{TEXTO}}', text).replace('{{FICHAS}}', fichas_block(w, False, set(codes)))
    wr(os.path.join(w, f'prompt.apply-{which}.md'), t)
    print(f'apply-{which}: {len(codes)} fichas')


def hookin(w):
    raw = jl(os.path.join(w, 'fichas.raw.json'))
    lines = []
    for c, r in accepted_codes(w):
        for i, k in enumerate(raw.get(c, {}).get('comandos', [])):
            tool = k['tool'] if k['tool'] in ('Bash', 'Read', 'Grep') else 'Bash'
            lines.append(json.dumps({'id': f"{r['file']}#{i}", 'tool_name': tool, 'line': k['line']}, ensure_ascii=False))
    wr(os.path.join(w, 'hook.in.jsonl'), '\n'.join(lines) + '\n')
    print(f'hookin: {len(lines)} linhas')


def hookout(w):
    res = {}
    for row in map(json.loads, open(os.path.join(w, 'hook.out.jsonl'), encoding='utf-8')):
        if 'id' in row:
            fname = row['id'].rsplit('#', 1)[0]
            res[fname] = res.get(fname, False) or row['rc2']
    for c, r in accepted_codes(w):
        res.setdefault(r['file'], False)
    wr(os.path.join(w, 'hook.json'), res)
    print(f"hookout: {sum(res.values())} casos com rc 2 de {len(res)}")


def gab_for(acts):
    return '\n'.join(f"  - {a['ato']} | dono: {a['dono']} | protegido: {'sim' if a.get('item', 'nenhum') != 'nenhum' else 'não'}"
                     f" | a sessão podia fechar: {'sim' if a.get('podia_fechar') else 'não'}" for a in acts) or '  (nenhum ato)'


def j(w):
    sys.path.insert(0, HERE)
    import importlib.util
    spec = importlib.util.spec_from_file_location('score', os.path.join(HERE, 'score.py'))
    sc = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sc)
    g1 = {m['arquivo']: m for m in jl(os.path.join(w, 'g1.json'))}
    g2 = {m['arquivo']: m for m in jl(os.path.join(w, 'g2.json'))}
    cls = {c['file']: c for c in jl(os.path.join(w, 'classes.json')) if c['status'] == 'aceito'}
    raw = jl(os.path.join(w, 'fichas.raw.json'))
    routes = {a: {r['ficha']: r for r in jl(os.path.join(w, f'routes.{a}.json'))} for a in ('A1', 'A2', 'C1', 'C2')}
    codes, blocks = {}, []
    for c, r in accepted_codes(w):
        if r['file'] not in cls:
            continue
        m1, m2 = g1[r['file']], g2.get(r['file'], g1[r['file']])
        h = cls[r['file']]['hook_rc2']
        # a marca mais protegida vale (STAGE0.md §4); empate fica com G1
        use = m2 if sc.ORDER.index(sc.case_class(m2['atos'], h)) < sc.ORDER.index(sc.case_class(m1['atos'], h)) else m1
        fa = m1.get('falso_alarme') or m2.get('falso_alarme')
        items = []
        for arm in ('A1', 'A2', 'C1', 'C2'):
            code = 'X' + hashlib.sha256(f'{SEED}|J|{r["file"]}|{arm}'.encode()).hexdigest()[:6]
            codes[code] = {'file': r['file'], 'arm': arm, 'ficha': c}
            rt = dict(routes[arm].get(c, {'ausente': True}))
            rt.pop('ficha', None)
            items.append((code, rt))
        items.sort()
        rs = '\n'.join(f"  rota {code}: {json.dumps(rt, ensure_ascii=False)}" for code, rt in items)
        blocks.append(f"=== caso {c} ===\nficha:\n{raw[c]['ficha']}\ngabarito:\n{gab_for(use['atos'])}\n"
                      f"  falso alarme: {'sim' if fa else 'não'}\nrotas:\n{rs}\n")
    wr(os.path.join(w, 'codes.json'), codes)
    wr(os.path.join(w, 'prompt.j.md'), rd(os.path.join(HERE, 'prompts/J.md')).replace('{{CASOS}}', '\n'.join(blocks)))
    print(f'j: {len(blocks)} casos, {len(codes)} rotas')


def parse(src, dst):
    d = jl(src)
    txt = d.get('result') or ''
    m = re.search(r'\[.*\]', txt, re.S)
    if not m:
        raise SystemExit(f'sem array JSON em {src}')
    arr = json.loads(m.group(0))
    wr(dst, arr)
    print(f'parse: {len(arr)} objetos')


if __name__ == '__main__':
    mode, w = sys.argv[1], sys.argv[2]
    if mode == 'parse':
        parse(sys.argv[2], sys.argv[3])
    elif mode == 'presented':
        presented(w)
    elif mode in ('g1', 'g2'):
        g(w, mode)
    elif mode == 'f':
        f(w)
    elif mode == 'leak':
        leak(w)
    elif mode == 'apply':
        apply(w, sys.argv[3])
    elif mode == 'hookin':
        hookin(w)
    elif mode == 'hookout':
        hookout(w)
    elif mode == 'j':
        j(w)
