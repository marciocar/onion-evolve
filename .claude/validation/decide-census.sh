#!/usr/bin/env bash
# ===========================================================================
# decide-census.sh — o MEDIDOR da peça 3 do /meta:decide.
#
# Responde por medição o que a sessão responderia de memória quando o maestro pergunta "o que está
# em voo e o que é decisão minha?": os FIOS EM VOO deste repo, um por linha, com a origem citável.
#   checkpoint  meta.x_drive_checkpoint: pending nos grafos rastreados (o P0.5 do /meta:drive: bloqueia)
#   merge       PRs abertos e o estado dos checks (via `gh`; falha do gh vira AVISO NOMEADO, nunca lista vazia)
#   seal        nós decision/question `open` que (a) o texto passado em --cite CITA por id, (b) casam
#               TODOS os termos de --theme, ou (c) tiveram id/label/narrative tocados na janela
#               (--window dias, default 7: diff entre o último commit antes da janela e a árvore de
#               trabalho). Só as linhas de SENTIDO contam: migração em massa toca o bloco de todo nó.
#               Cada linha seal traz QUEM CHEGA por aresta (opções às vezes são nós vizinhos), e o id
#               citado que não está na fila (inexistente ou já fechado) vira AVISO nomeado.
#   thread      worktrees do repo com arquivo não commitado ou commit não empurrado (ou prunable)
#   triage      itens de 1º nível em docs/evolution/{inbox,inbound,kg-inbox} (fora README e `_*`)
#
# ── DESCOBERTA POR REFERÊNCIA (cláusula 1 da forja) ─────────────────────────────────────────
# O corpus não é varrido por palavra-chave "parece decisão": o nó entra porque o texto CITA o id dele,
# porque o maestro passou o tema, ou porque o git diz que o bloco dele mudou. Medido na forja
# (2026-10-12, antes dos nós da própria forja): 159 decision e 300 question abertos em 117 grafos — despejar isso na sessão seria
# ruído; nenhum deles tem opções em campo estruturado (vivem em label/narrative).
#
# ── O QUE ESTE SCRIPT NÃO FAZ (fronteira declarada) ─────────────────────────────────────────
# Ele NÃO decide o que é do maestro: lista o que está em voo. O FILTRO (o que dá para medir e decidir
# sozinho não vira pergunta) é o passo 2 do comando, julgamento da sessão. E os "trechos que parecem
# opções" são CÓPIA LITERAL de label/narrative por padrão fixo — (a)/(b), "opção X", frase com `?` e
# " ou " — nunca opção composta; nó sem trecho legível diz isso.
#
# Uso:  bash .claude/validation/decide-census.sh [<repo>] [--markdown|--tsv] [--cite <arquivo|->]
#                                               [--theme "<termos>"] [--window <dias>] [--no-gh]
# Env (bancada e sandbox; NUNCA para fingir medição — todo override ativo é declarado na saída):
#   DECIDE_TODAY=<AAAA-MM-DD>   data de referência da janela (default: date +%F)
#   DECIDE_GH=<binário>         o `gh` a usar (default: gh)
#   DECIDE_CENSUS_TOP=<n>       teto de linhas da projeção markdown (default 40); o RESTO é NOMEADO,
#                               nunca cortado em silêncio. O --tsv não corta.
# Exit: 0 = medido (inclusive "nada em voo", e com avisos nomeados) · 2 = entrada quebrada (sem índice
#       git, PyYAML ausente, grafo rastreado que não parseia, --cite ilegível, opção inválida).
# Determinístico, sem LLM, 0 tokens. Exercitado por lint-selftest.sh (run_decide_selftests).
# ===========================================================================
set -uo pipefail
REPO=""; FMT="--markdown"; CITE=""; THEME=""; WINDOW="7"; NOGH="0"
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "decide-census: $1 exige um valor" >&2; exit 2; }; }   # rc 2, nunca o 1 do ${:?}
while [ $# -gt 0 ]; do
  case "$1" in
    --markdown|--tsv) FMT="$1" ;;
    --cite) _need "$@"; shift; CITE="$1" ;;
    --theme) _need "$@"; shift; THEME="$1" ;;
    --window) _need "$@"; shift; WINDOW="$1" ;;
    --no-gh) NOGH="1" ;;
    --*) echo "decide-census: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
case "${WINDOW}" in ''|*[!0-9]*) echo "decide-census: --window inválido (${WINDOW}) — inteiro >= 0 (0 desliga a janela)" >&2; exit 2 ;; esac
TOP="${DECIDE_CENSUS_TOP:-40}"
case "${TOP}" in ''|*[!0-9]*|0) echo "decide-census: DECIDE_CENSUS_TOP inválido (${TOP}) — inteiro >= 1. Recuso." >&2; exit 2 ;; esac
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "decide-census: alvo inexistente: ${REPO}" >&2; exit 2; }
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "decide-census: sem índice git em ${REPO} — os grafos rastreados são a fonte; recuso medir outro conjunto" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "decide-census: python3 ausente — não meço sem ele (nunca 0 em silêncio)" >&2; exit 2; }

TMPD="$(mktemp -d)"; trap 'rm -rf "${TMPD}"' EXIT
if [ "${CITE}" = "-" ]; then
  cat > "${TMPD}/cite.txt"; CITE="${TMPD}/cite.txt"; CITE_LABEL="stdin"
elif [ -n "${CITE}" ]; then
  [ -r "${CITE}" ] || { echo "decide-census: --cite ilegível: ${CITE}" >&2; exit 2; }
  CITE_LABEL="${CITE}"
else CITE_LABEL=""; fi

# Override ativo é DECLARADO (lição do cc-delta-census, 2026-10-08: a causa herdada parecia a fonte).
OVR="$(env | LC_ALL=C grep -oE '^DECIDE_(TODAY|GH|CENSUS_TOP)=.*' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"
TODAY="${DECIDE_TODAY:-$(date +%F)}"
GH="${DECIDE_GH:-gh}"

PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${REPO}" "${FMT}" "${CITE}" "${CITE_LABEL}" "${THEME}" "${WINDOW}" \
  "${NOGH}" "${TODAY}" "${TOP}" "${GH}" "${OVR}" <<'PY'
import sys, os, re, json, subprocess, datetime
repo, fmt, cite, cite_label, theme, window, nogh, today, top, gh, ovr = sys.argv[1:12]
window, top = int(window), int(top)
try:
    import yaml
except ImportError:
    print('decide-census: PyYAML ausente — os grafos não podem ser lidos (fail-loud, nunca "nada em voo")', file=sys.stderr); sys.exit(2)
try:
    today_d = datetime.date.fromisoformat(today)
except ValueError:
    print(f'decide-census: DECIDE_TODAY inválido ({today}) — AAAA-MM-DD', file=sys.stderr); sys.exit(2)

def git(*a, cwd=None):
    r = subprocess.run(['git', '-C', cwd or repo, *a], capture_output=True, text=True)
    return r.returncode, r.stdout
def one(s): return ' '.join(str(s).split())
def clip(s, n):
    s = one(s); return s if len(s) <= n else s[:n - 1] + '…'

avisos = []
if ovr: avisos.append(f'override ativo, esta NÃO é a medição de produção: {ovr}')

# ── grafos rastreados, fora de fixture e vendor ─────────────────────────────────────────────
rc, out = git('-c', 'core.quotePath=false', 'ls-files', '-z', '--', '*.kg.yaml')
graphs = []
for g in out.split('\0'):
    if not g: continue
    parts = g.split('/')
    if 'fixtures' in parts or 'vendor' in parts: continue
    graphs.append(g)
graphs.sort()

open_nodes = []          # dicts
checkpoints = []
STATUS = {'open', 'confirmed', 'drifted', 'unverifiable', 'refuted', 'superseded', 'done'}
all_ids = {}             # id → (grafo, node_type, status) de TODO nó rastreado: para nomear o citado que não está na fila
for g in graphs:
    p = os.path.join(repo, g)
    if not os.path.isfile(p):
        avisos.append(f'grafo rastreado AUSENTE do disco (não medido): {g}'); continue
    try:
        txt = open(p, encoding='utf-8').read()
        d = yaml.safe_load(txt)
    except Exception as e:
        print(f'decide-census: grafo rastreado que NÃO PARSEIA (YAML ou UTF-8): {g}: {one(e)[:200]} — recuso medir o resto como se ele não existisse', file=sys.stderr)
        sys.exit(2)
    if not isinstance(d, dict):
        avisos.append(f'grafo rastreado sem mapa no topo (vazio ou não-dict), NÃO medido: {g}'); continue
    if not isinstance(d.get('nodes') or [], list):
        avisos.append(f'grafo com `nodes:` que não é lista, NÃO medido: {g}'); continue
    meta = d.get('meta') or {}
    if isinstance(meta, dict):
        ck = meta.get('x_drive_checkpoint', meta.get('drive_checkpoint'))
        if str(ck) == 'pending':
            ln = next((i + 1 for i, l in enumerate(txt.split('\n')) if re.match(r'^\s+(x_)?drive_checkpoint\s*:', l)), 0)
            note = meta.get('x_drive_checkpoint_note', meta.get('drive_checkpoint_note')) or '(sem nota)'
            checkpoints.append({'kind': 'checkpoint', 'ref': g, 'origin': f'{g}:{ln}', 'label': clip(note, 220),
                                'state': 'pending', 'via': 'meta', 'options': ''})
    # quem CHEGA por aresta a cada nó: as opções às vezes vivem como NÓS vizinhos (C_OPCAO_* → D_ por SUPPORTS),
    # não como trecho da prosa — medido na forja: 4 das 159 decisões abertas, e o padrão fixo sobre a prosa não as
    # via (o dogfood selou uma cópia de D_UNIDADE_BILHETAVEL_DO_ONION enxergando 4 das 6 opções).
    ntype_of = {str(n.get('id')): n.get('node_type') for n in (d.get('nodes') or []) if isinstance(n, dict)}
    incoming = {}
    for e in d.get('edges') or []:
        if isinstance(e, dict) and e.get('to') is not None and e.get('from') is not None:
            incoming.setdefault(str(e['to']), []).append(f"{e['from']} ({ntype_of.get(str(e['from']), '?')}, {e.get('edge_type')})")
    lines = txt.split('\n')
    idline = {}
    for i, l in enumerate(lines):
        m = re.match(r'^(\s*)-\s+id:\s*["\']?([A-Za-z0-9_]+)["\']?\s*(#.*)?$', l)
        if m: idline.setdefault(m.group(2), (i + 1, len(m.group(1))))
    # fim de bloco de cada nó: próximo `- id:` no mesmo recuo, ou linha de recuo menor
    starts = sorted(idline.values())
    for n in d.get('nodes') or []:
        if not isinstance(n, dict): continue
        all_ids.setdefault(str(n.get('id')), (g, n.get('node_type'), n.get('status')))
        if n.get('node_type') in ('decision', 'question') and n.get('status') not in STATUS:
            avisos.append(f"decision/question com status fora do vocabulário (não medido como aberto): {n.get('id')} = {n.get('status')!r} em {g}")
        if n.get('node_type') not in ('decision', 'question') or n.get('status') != 'open': continue
        nid = str(n.get('id'))
        ln, ind = idline.get(nid, (0, 0))
        if not ln:   # 11: fora da forma de bloco (flow-style, id que não é a 1ª chave, id fora do alfabeto)
            avisos.append(f'nó aberto fora da forma `- id:` de bloco: {nid} em {g} — entra por cite/tema, mas a JANELA e a linha de origem NÃO são medidas')
        end = len(lines)
        if ln:
            for j in range(ln, len(lines)):
                l = lines[j]
                if not l.strip(): continue
                lind = len(l) - len(l.lstrip())
                if lind < ind or (lind == ind and l.lstrip().startswith('-')) or (lind <= ind and l.lstrip().startswith('#')):
                    end = j; break
        # linhas de SENTIDO do nó: a do id, a do label e a da narrative (com continuação). Migração em
        # massa (aspas em data, locality, external_edges) toca o bloco de TODO nó e não é fio em voo —
        # medido na forja: com o bloco inteiro, a janela de 7 d trazia 170+ nós do corpus.
        sense = set()
        if ln:
            sense.add(ln)
            fi = ind + 2; k = ln
            while k < end:
                l = lines[k]; lind = len(l) - len(l.lstrip())
                if lind == fi and re.match(r'^\s*(label|narrative)\s*:', l):
                    sense.add(k + 1); k += 1
                    while k < end and (not lines[k].strip() or len(lines[k]) - len(lines[k].lstrip()) > fi):
                        sense.add(k + 1); k += 1
                    continue
                k += 1
        open_nodes.append({'graph': g, 'id': nid, 'type': n.get('node_type'), 'impact': n.get('impact') or 0,
                           'label': one(n.get('label') or ''), 'narrative': one(n.get('narrative') or ''),
                           'line': ln, 'end': end, 'sense': sense, 'incoming': incoming.get(nid, [])})

# ── (a) citados por id ──────────────────────────────────────────────────────────────────────
cited = set()
if cite:
    try:
        ctoks = set(re.findall(r'[A-Za-z0-9_]+', open(cite, encoding='utf-8', errors='replace').read()))
    except Exception as e:
        print(f'decide-census: --cite ilegível: {e}', file=sys.stderr); sys.exit(2)
    clow = {t.casefold() for t in ctoks}
    cited = {n['id'] for n in open_nodes if n['id'].casefold() in clow}   # sem caixa: "d_x" também cita D_X
    # o citado que NÃO entrou é NOMEADO (achado do dogfood da forja: um id citado e inexistente sumia calado,
    # e a sessão leria a ausência como "não há o que decidir sobre ele")
    for t in sorted(t for t in ctoks if t not in cited and t.upper() not in {c.upper() for c in cited}):
        if not re.fullmatch(r'[A-Z][A-Z0-9]*_[A-Z0-9_]*[A-Z0-9]', t): continue
        if t in all_ids:
            gg, ty, stt = all_ids[t]
            if ty in ('decision', 'question') and stt == 'open': continue
            avisos.append(f'citado e fora da fila: {t} é {ty} {stt} em {gg} (não é decision/question open)')
        else:
            avisos.append(f'citado e INEXISTENTE no corpus rastreado: {t} (fixture e vendor ficam fora por desenho; erro de digitação?)')
# ── (b) tema: TODOS os termos, sem caixa ────────────────────────────────────────────────────
terms = [t.lower() for t in theme.split() if t]
def themed(n):
    hay = (n['id'] + ' ' + n['label'] + ' ' + n['narrative']).lower()
    return bool(terms) and all(t in hay for t in terms)
# ── (c) janela: bloco do nó tocado entre o último commit ANTES da janela e a árvore de trabalho ─
touched = set(); base_desc = 'desligada'
_rc_sh, _sh = git('rev-parse', '--is-shallow-repository')
if window > 0 and _sh.strip() == 'true':
    avisos.append('clone RASO (shallow): o histórico não chega à base da janela — janela NÃO medida (nada entra por window)')
    window = 0; base_desc = 'NÃO MEDIDA (clone raso)'
if window > 0:
    cutoff = today_d - datetime.timedelta(days=window)
    rc, base = git('rev-list', '-1', f'--before={cutoff.isoformat()}T00:00:00', 'HEAD')
    base = base.strip()
    if rc != 0:
        avisos.append('janela NÃO medida: o repo não tem HEAD legível'); base = ''
        base_desc = 'NÃO MEDIDA'
    else:
        if not base:
            base = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'   # árvore vazia: todo commit está na janela
            base_desc = f'{window}d (repo mais novo que a janela: todo o histórico)'
        else:
            base_desc = f'{window}d (base {base[:10]})'
        rc, names = git('-c', 'core.quotePath=false', 'diff', '--name-only', base, '--', '*.kg.yaml')
        changed = {x for x in names.split('\n') if x} & set(graphs)
        bygraph = {}
        for n in open_nodes:
            if n['graph'] in changed: bygraph.setdefault(n['graph'], []).append(n)
        for g, ns in bygraph.items():
            rc, diff = git('diff', '-U0', base, '--', g)
            ranges = []
            for m in re.finditer(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@', diff, re.M):
                s = int(m.group(1)); c = int(m.group(2)) if m.group(2) is not None else 1
                ranges.append((s, s + max(c, 1) - 1) if c else (s, s + 1))   # remoção pura toca a vizinhança
            for n in ns:
                if n['sense'] and any(a <= x <= b for a, b in ranges for x in n['sense']):
                    touched.add((g, n['id']))

# ── trechos de label/narrative que PARECEM opções: cópia literal, padrão fixo ───────────────
OPT_PATS = [
    re.compile(r'\((?:[a-hA-H]|[1-9]|i{1,3}|iv|v)\)\s*[^()]{3,160}?(?=\s*\((?:[a-hA-H]|[1-9]|i{1,3}|iv|v)\)|[.;]\s|$)'),
    re.compile(r'(?i)\bop[çc][ãa]o\s+[A-Z0-9]{1,3}\b[^.;]{0,160}'),
]
def options_of(n):
    text = n['label'] + ' ' + n['narrative']
    found = []
    for pat in OPT_PATS:
        for m in pat.finditer(text):
            s = clip(m.group(0), 160)
            if s not in found: found.append(s)
    if not found:
        for sent in re.split(r'(?<=[?.;!])\s+', text):
            if '?' in sent and re.search(r'\bou\b', sent): found.append(clip(sent, 160))
    return found   # sem teto: corte de trecho é corte silencioso (a 1ª versão parava em 4 e escondia (e) e (f))

seal_rows = []
for n in open_nodes:
    via = []
    if n['id'] in cited: via.append('cite')
    if themed(n): via.append('theme')
    if (n['graph'], n['id']) in touched: via.append('window')
    if not via: continue
    pri = 2 if 'cite' in via else (3 if 'theme' in via else 7)
    opts = options_of(n)
    seal_rows.append({'kind': 'seal', 'ref': n['id'], 'origin': f"{n['graph']}:{n['line']}", 'label': clip(n['label'], 220),
                      'state': f"{n['type']} impacto {n['impact']}", 'via': ','.join(via),
                      'options': ' ⟂ '.join(opts), 'pri': pri, 'imp': n['impact'],
                      'incoming': ' · '.join(n['incoming'])})

# ── PRs abertos (gh) — falha é AVISO NOMEADO ────────────────────────────────────────────────
merge_rows = []; pr_desc = ''
if nogh == '1':
    avisos.append('PRs NÃO medidos (--no-gh): "nenhum PR" aqui não quer dizer zero PRs'); pr_desc = 'NÃO MEDIDOS (--no-gh)'
else:
    why = ''
    try:
        r = subprocess.run([gh, 'pr', 'list', '--state', 'open', '--limit', '100', '--json',
                            'number,title,headRefName,isDraft,statusCheckRollup'],
                           cwd=repo, capture_output=True, text=True, timeout=45)
        if r.returncode != 0: why = f'rc {r.returncode}: {clip(r.stderr or r.stdout, 160)}'
        else:
            prs = json.loads(r.stdout or 'null')
            if not isinstance(prs, list): why = 'resposta não é lista JSON'
    except FileNotFoundError: why = f'binário ausente ({gh})'
    except subprocess.TimeoutExpired: why = 'timeout de 45 s'
    except ValueError as e: why = f'JSON ilegível: {clip(e, 120)}'
    if why:
        avisos.append(f'gh indisponível — PRs abertos e CI NÃO medidos ({why}); a ausência de linhas merge NÃO é zero PRs')
        pr_desc = 'NÃO MEDIDOS'
    else:
        pr_desc = f'{len(prs)} aberto(s)'
        if len(prs) >= 100: avisos.append('100 PRs abertos: o limite do gh foi atingido, pode haver mais')
        BAD = {'FAILURE', 'CANCELLED', 'TIMED_OUT', 'ACTION_REQUIRED', 'STARTUP_FAILURE', 'ERROR'}
        for p in prs:
            ok = fail = pend = 0; fails = []
            for c in p.get('statusCheckRollup') or []:
                concl = (c.get('conclusion') or '').upper(); st = (c.get('status') or '').upper(); state = (c.get('state') or '').upper()
                if concl in BAD or state in BAD: fail += 1; fails.append(c.get('name') or c.get('context') or '?')
                elif (st and st != 'COMPLETED') or state in ('PENDING', 'EXPECTED'): pend += 1
                else: ok += 1
            st = f'checks {ok} ok · {fail} falha · {pend} em curso' + (f' (falha: {", ".join(fails[:3])}{"…" if len(fails) > 3 else ""})' if fails else '')
            if p.get('isDraft'): st = 'rascunho · ' + st
            merge_rows.append({'kind': 'merge', 'ref': f"PR#{p.get('number')}", 'origin': p.get('headRefName') or '',
                               'label': clip(p.get('title') or '', 200), 'state': st, 'via': 'gh', 'options': '',
                               'pri': 1 if fail else 4, 'imp': 0})

# ── worktrees com trabalho não empurrado ────────────────────────────────────────────────────
thread_rows = []
rc, wl = git('worktree', 'list', '--porcelain')
rc_r, remotes = git('remote')
has_remote = bool(remotes.strip())
if not has_remote: avisos.append('repo sem remoto: "não empurrado" não é medível (conto só o não commitado)')
for blk in wl.strip().split('\n\n') if wl.strip() else []:
    kv = {}
    for l in blk.split('\n'):
        k, _, v = l.partition(' '); kv[k] = v
    path = kv.get('worktree', ''); br = kv.get('branch', '').replace('refs/heads/', '') or ('(detached)' if 'detached' in kv else '?')
    ra = os.path.abspath(repo)
    rel = os.path.relpath(path, ra) if (path == ra or path.startswith(ra + os.sep)) else path
    if 'prunable' in kv or not os.path.isdir(path):
        thread_rows.append({'kind': 'thread', 'ref': br, 'origin': rel, 'label': 'worktree prunable (o diretório sumiu)',
                            'state': 'prunable', 'via': 'git', 'options': '', 'pri': 5, 'imp': 0}); continue
    rc1, st = git('status', '--porcelain', cwd=path)
    dirty = len([x for x in st.split('\n') if x.strip()]) if rc1 == 0 else -1
    unp = 0
    if has_remote:
        rc2, cnt = git('rev-list', '--count', 'HEAD', '--not', '--remotes', cwd=path)
        unp = int(cnt.strip()) if rc2 == 0 and cnt.strip().isdigit() else -1
    if dirty == 0 and unp == 0: continue
    lab = f"{'?' if dirty < 0 else dirty} arquivo(s) não commitado(s) · {'?' if unp < 0 else unp} commit(s) não empurrado(s)"
    thread_rows.append({'kind': 'thread', 'ref': br, 'origin': rel, 'label': lab, 'state': 'em voo', 'via': 'git',
                        'options': '', 'pri': 5, 'imp': 0})

# ── inbox/inbound/kg-inbox de 1º nível ──────────────────────────────────────────────────────
triage_rows = []
for sub in ('docs/evolution/inbox', 'docs/evolution/inbound', 'docs/evolution/kg-inbox'):
    p = os.path.join(repo, sub)
    if not os.path.isdir(p): continue
    items = sorted(x for x in os.listdir(p) if not x.startswith(('_', '.')) and x != 'README.md')
    if items:
        triage_rows.append({'kind': 'triage', 'ref': sub, 'origin': sub, 'label': f'{len(items)} item(ns) não processado(s): ' + clip(', '.join(items), 180),
                            'state': f'{len(items)}', 'via': 'fs', 'options': '', 'pri': 6, 'imp': 0})

for r in checkpoints: r.update(pri=0, imp=0)
rows = checkpoints + merge_rows + seal_rows + thread_rows + triage_rows
rows.sort(key=lambda r: (r['pri'], -int(r['imp'] or 0), r['ref']))

def tsvc(s): return str(s).replace('\t', ' ').replace('\n', ' ')
if fmt == '--tsv':
    print('kind\tref\torigin\tlabel\tstate\tvia\toptions\tincoming')
    for r in rows: print('\t'.join(tsvc(r.get(k, '')) for k in ('kind', 'ref', 'origin', 'label', 'state', 'via', 'options', 'incoming')))
    for a in avisos: print(f'warn\t-\t-\t{tsvc(a)}\t\t\t\t')
    sys.exit(0)

KH = {'checkpoint': 'checkpoint pendente — BLOQUEIA (P0.5 do /meta:drive: o lote anterior não foi selado)',
      'merge': 'merge — PRs abertos e o estado do CI (merge é do maestro, pelo caminho verificado)',
      'seal': 'seal — nós decision/question abertos (candidatos a selo; o FILTRO decide se são do maestro)',
      'thread': 'thread — worktrees com trabalho não commitado ou não empurrado',
      'triage': 'triage — inbox/inbound/kg-inbox com itens não processados'}
print(f'# decide-census · {today} · {len(rows)} linha(s) em voo')
print(f'fontes: grafos={len(graphs)} · nós decision/question open={len(open_nodes)} · janela={base_desc} · '
      f'cite={cite_label or "—"} · tema={(chr(34) + theme + chr(34)) if terms else "—"} · PRs={pr_desc}')
if avisos:
    print('\n## ⚠️ Avisos (medição incompleta ou não-produção — leia antes das linhas)')
    for a in avisos: print(f'- {a}')
shown = rows[:top]; rest = rows[top:]
cur = None
for r in shown:
    if r['kind'] != cur:
        cur = r['kind']; print(f"\n## {KH[cur]}")
    if r['kind'] == 'seal':
        print(f"- [{r['via']}] `{r['ref']}` ({r['state']}) — {r['origin']} — {r['label']}")
        print(f"  - trechos com forma de opção (cópia literal; podem não ser as opções): {('«' + r['options'].replace(' ⟂ ', '» · «') + '»') if r['options'] else '(nenhum trecho com forma de opção no nó — compor com embasamento, ou a opção é pesquisar antes)'}")
        if r['incoming']:
            print(f"  - chegam por aresta (leia-os: opções e objeções às vezes vivem aqui): {r['incoming']}")
    elif r['kind'] == 'merge':
        print(f"- {r['ref']} `{r['origin']}` — {r['label']} · {r['state']}")
    else:
        print(f"- `{r['ref']}` — {r['origin']} — {r['label']}")
if rest:
    print(f'\n⚠️ TETO: mostradas {len(shown)} de {len(rows)} linhas (DECIDE_CENSUS_TOP={top}), na ordem bloqueio→atenção.')
    print(f'   As {len(rest)} restantes NÃO são zero — NOMEADAS: ' + ', '.join(f"{r['kind']}:{r['ref']}" for r in rest))
    print('   Conjunto completo: `bash .claude/validation/decide-census.sh . --tsv`.')
if rows: print(f'\nVEREDITO: {len(rows)} fio(s) em voo — FILTRAR o que é do maestro antes de perguntar.')
elif avisos: print('\nVEREDITO: NADA MEDIDO EM VOO — mas a medição está INCOMPLETA (ver avisos); não é "nada a decidir".')
else: print('\nVEREDITO: NADA EM VOO — nenhuma linha medida; se o maestro tem tema, passe --theme ou --cite.')
PY
