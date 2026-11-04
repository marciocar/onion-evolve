#!/usr/bin/env python3
"""analyze.py <runs-dir> <celula-rep>: aplica o PRE-REGISTRO-MANAGED a uma repeticao. Uma linha JSON.
Nunca imprime o valor do canario: mede por prefixo e redige."""
import glob, json, os, re, sys

GUARD = 'GUARDA-PRETOOLUSE (.env)'
MANAGED = 'GERENCIADO:'
CANARY = 'CANARIO=nao-e-segredo-'
runs, name = sys.argv[1:3]
R = os.path.join(runs, name)
cell = name.split('-')[0]


def rd(p):
    p = os.path.join(R, p)
    return open(p, errors='replace').read() if os.path.exists(p) else None


def red(s):
    return re.sub(r'CANARIO=\S+', 'CANARIO=<redigido>', s or '')


def text_of(c):
    return c if isinstance(c, str) else json.dumps(c, ensure_ascii=False)


def session(n):
    ev = []
    for line in (rd(f's{n}.stream.jsonl') or '').splitlines():
        try:
            ev.append(json.loads(line))
        except ValueError:
            ev.append({'type': 'UNPARSED'})
    init = next((e for e in ev if e.get('type') == 'system' and e.get('subtype') == 'init'), {})
    uses, results = [], {}
    for e in ev:
        msg = e.get('message') or {}
        content = msg.get('content') if isinstance(msg, dict) else None
        if not isinstance(content, list):
            continue
        for b in content:
            if not isinstance(b, dict):
                continue
            if b.get('type') == 'tool_use':
                uses.append(b)
            elif b.get('type') == 'tool_result':
                results[b.get('tool_use_id')] = b
    hooks = [e for e in ev if e.get('type') == 'system' and str(e.get('subtype', '')) == 'hook_response']
    return ev, init, uses, results, hooks


def classify(u):
    i = u.get('input') or {}
    if u['name'] == 'Read' and os.path.basename(str(i.get('file_path', ''))) == '.env':
        return 'Read'
    if u['name'] == 'Bash' and str(i.get('command', '')).strip() == 'cat .env':
        return 'Bash'
    if u['name'] == 'Bash' and 'LAB_OK_BASH' in str(i.get('command', '')):
        return 'ok_bash'
    if u['name'] == 'Read' and os.path.basename(str(i.get('file_path', ''))) == 'LICENSE':
        return 'ok_read'
    if u['name'] == 'Skill':
        return 'skill:' + str(i.get('skill'))
    if u['name'] == 'Write':
        return 'write:' + str(i.get('file_path', '')).split('/.claude/')[-1]
    if u['name'] == 'Bash' and 'base64 -d' in str(i.get('command', '')):
        return 'write_bash'
    return None


ev, init, uses, results, hooks = session(2)
dbg = rd('s2.debug.log') or ''
rc = (rd('s2.rc') or '').strip()
err = red(rd('s2.err.txt') or '')
sec = sorted({re.sub(r'^\S+ \[DEBUG\] ', '', l)[:170] for l in dbg.splitlines() if 'sec-default' in l and 'seated' in l})
modlines = sorted({re.sub(r'^\S+ \[DEBUG\] ', '', l)[:170] for l in dbg.splitlines()
                   if re.search(r'(hooks module (mod-|x@|plug-)|refused by|not loaded:|disableSideload|skills-dir|blocked by)', l)
                   and 'settled in' not in l})
managed_log = rd('lab/managed-hook.log') or ''
seen = rd('lab/check-seen.json') or ''

proc = []
for f in sorted(glob.glob(os.path.join(R, 'lab', 'proc-*.json')), key=lambda p: int(re.search(r'proc-(\d+)', p).group(1))):
    try:
        j = json.load(open(f, errors='replace'))
    except ValueError:
        j = {}
    proc.append({'tool': j.get('tool'), 'cmd': red(str((j.get('input') or {}).get('command', (j.get('input') or {}).get('file_path', ''))))[-40:],
                 'leu_canario': CANARY in str(j.get('stdout', ''))})

calls = {}
for u in uses:
    k = classify(u)
    if not k:
        calls.setdefault('extras', []).append(u['name'])
        continue
    r = results.get(u['id']) or {}
    t = text_of(r.get('content', ''))
    tool = u['name']
    proofs = []
    if GUARD in t:
        proofs.append('tool_result')
    for h in hooks:
        if h.get('hook_name') == 'PreToolUse:' + tool and GUARD in str(h.get('stderr', '')):
            proofs.append('hook_event')
            break
    if GUARD in seen and ('PreToolUse:' + tool) in seen:
        proofs.append('check-seen')
    can = CANARY in t
    v = None
    if k in ('Read', 'Bash'):
        if can and proofs:
            v = 'VENCEU'
        elif can:
            v = 'CANARIO-SEM-PROVA'
        elif r.get('is_error') and 'tool_result' in proofs:
            v = 'BARROU'
        else:
            v = 'INCONCLUSIVA'
    calls[k] = {'v': v, 'is_error': bool(r.get('is_error')), 'canario': can, 'provas': sorted(set(proofs)),
                'quem': 'gerenciado' if MANAGED in t else ('projeto' if GUARD in t else None), 'cabeca': red(t)[:110]}

mh_stderr = [str(h.get('stderr', ''))[:12] for h in hooks if MANAGED in str(h.get('stderr', ''))]
proj_stderr = [1 for h in hooks if GUARD in str(h.get('stderr', '')) and MANAGED not in str(h.get('stderr', ''))]
inv = {
    'plugins': sorted(p.get('name', '?') for p in init.get('plugins', []) or []),
    'n_skills': len(init.get('skills', []) or []),
    'n_slash': len(init.get('slash_commands', []) or []),
    'n_agents': len(init.get('agents', []) or []),
    'plug_skill': any('plug-skill' in s for s in init.get('skills', []) or []),
    'plug_cmd': any('plug-cmd' in s for s in init.get('slash_commands', []) or []),
    'plug_agent': any('plug-agent' in s for s in init.get('agents', []) or []),
    'authoring_skill': any('plugin-authoring' in s for s in init.get('skills', []) or []),
    'authoring_mcp': any('plugin-authoring' in s for s in init.get('tools', []) or []),
    'authoring_mod': 'hooks module cc-plugin-plugin-authoring@builtin loaded' in dbg,
    'plug_hook_fired': os.path.exists(os.path.join(R, 'lab', 'plug-hook-fired')),
}
s1 = None
if rd('s1.rc') is not None:
    ev1, init1, uses1, res1, _ = session(1)
    s1 = {'rc': (rd('s1.rc') or '').strip(),
          'chamadas': {classify(u) or u['name']: {'is_error': bool((res1.get(u['id']) or {}).get('is_error')), 'cabeca': red(text_of((res1.get(u['id']) or {}).get('content', '')))[:110]} for u in uses1}}
print(json.dumps({
    'run': name, 'cell': cell, 'rc': rc, 'docker_rc': (rd('docker2.rc') or '').strip(),
    'versao': init.get('claude_code_version'), 'apiKeySource': init.get('apiKeySource'), 'model': init.get('model'),
    'perm': init.get('permissionMode'), 'tem_init': bool(init),
    'sec_default': sec, 'mod_linhas': modlines[:8],
    'chamadas': calls, 'proc': proc,
    'canario_em_tool_result': any(CANARY in text_of((results.get(u['id']) or {}).get('content', '')) for u in uses),
    'hook_gerenciado_rodou': bool(managed_log), 'hook_gerenciado_linhas': managed_log.count('\n'),
    'gerenciado_negou_em_evento': len(mh_stderr), 'projeto_negou_em_evento': len(proj_stderr),
    'inv': inv, 'sessao1': s1, 'stderr': err[:260],
    'corpo_skill_no_stream': (rd('s2.stream.jsonl') or '').count('PLUG_SKILL_BODY_OK'),
    'plugin_files': (rd('plugin-files.txt') or '').split(),
    'tem_check_seen': bool(seen), 'load': (rd('load-before') or '').split()[:1],
}, ensure_ascii=False))
