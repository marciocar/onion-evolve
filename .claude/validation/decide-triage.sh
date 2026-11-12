#!/usr/bin/env bash
# ===========================================================================
# decide-triage.sh — o MEDIDOR do modo triagem em lote do /meta:decide (irmão do decide-census.sh).
#
# Por que existe (D_FORGE_DECIDE_BATCH_TRIAGE_MODE_1111, maestro, 2026-11-11): o censo mostra 40 linhas por
# vez e o maestro vê sempre as mesmas perguntas, enquanto centenas de nós decision/question seguem `open`
# (medido no hub de um adotante: 106 em 34 grafos). Este medidor lista os CANDIDATOS À TRIAGEM, com as
# colunas que ajudam a sessão a classificar cada um num dos quatro destinos da cláusula 10 da doutrina.
#
# ── QUEM ENTRA (lista positiva, todas as condições) ───────────────────────────────────────────
#   · nó `decision` ou `question` com `status: open`, num grafo RASTREADO (fora de fixtures/ e vendor/);
#   · mais VELHO que o teto (--max-age-days, padrão 30): idade > teto, em dias;
#   · SEM DONO ATIVO: nenhuma reserva VIVA da chave <repo>#<ID> no registro do maestro-ask
#     (.claude/utils/orchestration/maestro-ask.sh; ONION_ASK_DIR troca o registro);
#   · sem PEDIDO EM CURSO: o nó que a triagem já pediu a outro papel (owner ≠ maestro e x_due ≥ hoje) volta
#     só quando o prazo vence, e então com a dica `pedido-vencido`, MESMO abaixo do teto (o selo do pedido
#     rejuvenesce o bloco, e a idade por commit o esconderia até o teto).
#   O que fica de fora por dona viva ou pedido em curso é CONTADO e NOMEADO, nunca some calado.
#
# ── A IDADE (regra declarada) ─────────────────────────────────────────────────────────────────
#   1. `verified_at` do nó, quando é data legível: é o carimbo que o próprio nó declara da última vez que
#      alguém o conferiu, e é o que o radar e o /meta:kg-freshness já usam como relógio.
#   2. na falta dele, a data do ÚLTIMO COMMIT que tocou alguma linha do bloco do nó (`git blame` do grafo,
#      o maior committer-time entre as linhas do bloco). Linha não commitada conta como hoje (idade 0).
#      Teto declarado: migração em massa que reescreve o bloco (aspas, campo novo) rejuvenesce o nó.
#   3. nó sem verified_at e fora da forma `- id:` de bloco, ou com verified_at no FUTURO: idade NÃO MEDIDA, aviso
#      nomeado, não entra (nunca some calado como "abaixo do teto").
#
# ── AS COLUNAS (pistas para classificar) ──────────────────────────────────────────────────────
#   superseded  arestas SUPERSEDES que CHEGAM ao nó (quem, com que status) e nós FECHADOS mais novos que
#               citam o id na prosa (decision/question done|confirmed com verified_at mais novo que a idade)
#   owner       o `owner:` que o nó declara (papel do contrato kg-ssot) e o `x_due`, quando há
#   measurable  por que dá para fechar por medição: vizinho claim/evidence em plane PROD, comando citado na
#               prosa, ou caminho de verified_against que existe no repo
#   hint        a DICA de destino: obsoleto · pedido · pedido-vencido · medição · maestro
#   ⚠️ A DICA É PISTA, NÃO DECISÃO. Ela sai de padrões fixos, erra para os dois lados e nunca vira escrita:
#      a sessão LÊ o nó, classifica com evidência e monta o lote; o maestro aprova; o selador grava.
#
# ── DESCOBERTA POR REFERÊNCIA ─────────────────────────────────────────────────────────────────
#   O medidor nunca constrói nome de arquivo nem id: os grafos vêm do índice git, os nós do YAML, as
#   arestas do próprio grafo, as reservas do registro. Nenhum nó é inventado; nenhum é escrito.
#
# Uso:  bash .claude/validation/decide-triage.sh [<repo>] [--markdown|--tsv] [--max-age-days N] [--self <id>] [--own <papel>]...
#   --own <papel>  papel DESTA casa (repetível): `owner:` com ele não vira dica de pedido. Default: maestro + o `role:` do
#                  .claude/.onion-version, ou `core` no repo-fonte, que não tem esse arquivo
#       (também por `decide-census.sh --triage ...`, que repassa para cá)
# Env (bancada e sandbox; todo override ativo é DECLARADO na saída):
#   DECIDE_TODAY=<AAAA-MM-DD>  data de referência (default: date +%F)
#   DECIDE_NOW=<epoch>         relógio da reserva viva (default: agora)
#   ONION_ASK_DIR=<dir>        registro de perguntas ao maestro (default: o do maestro-ask.sh)
#   DECIDE_CENSUS_TOP=<n>      teto de linhas da projeção markdown (default 40); o resto é NOMEADO
# Exit: 0 = medido (inclusive zero candidatos) · 2 = entrada quebrada (teto inválido, sem índice git,
#       PyYAML ausente, grafo rastreado que não parseia).
# Determinístico, sem LLM, 0 tokens, só leitura. Exercitado por lint-selftest.sh (run_decide_selftests).
# ===========================================================================
set -uo pipefail
REPO=""; FMT="--markdown"; MAXAGE="30"; SELF=""; OWN=""
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "decide-triage: $1 exige um valor" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --markdown|--tsv) FMT="$1" ;;
    --triage) ;;   # repassado pelo decide-census.sh --triage
    --max-age-days) _need "$@"; shift; MAXAGE="$1" ;;
    --self) _need "$@"; shift; SELF="$1" ;;
    --own) _need "$@"; shift; OWN="${OWN}${OWN:+ }$1" ;;
    --*) echo "decide-triage: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
case "${MAXAGE}" in ''|*[!0-9]*) echo "decide-triage: --max-age-days inválido (${MAXAGE}) — inteiro >= 0 (dias)" >&2; exit 2 ;; esac
[ "${#MAXAGE}" -le 5 ] || { echo "decide-triage: --max-age-days inválido (${MAXAGE}) — teto acima de 99999 dias" >&2; exit 2; }
case "${DECIDE_NOW:-0}" in *[!0-9]*) echo "decide-triage: DECIDE_NOW inválido (${DECIDE_NOW}) — epoch em segundos" >&2; exit 2 ;; esac
TOP="${DECIDE_CENSUS_TOP:-40}"
case "${TOP}" in ''|*[!0-9]*|0) echo "decide-triage: DECIDE_CENSUS_TOP inválido (${TOP}) — inteiro >= 1" >&2; exit 2 ;; esac
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "decide-triage: alvo inexistente: ${REPO}" >&2; exit 2; }
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "decide-triage: sem índice git em ${REPO} — os grafos rastreados são a fonte; recuso medir outro conjunto" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "decide-triage: python3 ausente" >&2; exit 2; }
OVR="$(env | LC_ALL=C grep -oE '^(DECIDE_(TODAY|NOW|CENSUS_TOP)|ONION_ASK_DIR)=.*' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"

PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${REPO}" "${FMT}" "${MAXAGE}" "${TOP}" "${OVR}" "${SELF}" "${DECIDE_TODAY:-$(date +%F)}" "${OWN}" <<'PY'
import sys, os, re, subprocess, datetime, time
repo, fmt, maxage, top, ovr, self_who, today, own = sys.argv[1:9]
maxage, top = int(maxage), int(top)
self_who = self_who or os.environ.get('CLAUDE_CODE_SESSION_ID', '')
now_s = int(os.environ.get('DECIDE_NOW') or time.time())
try:
    import yaml
except ImportError:
    print('decide-triage: PyYAML ausente — os grafos não podem ser lidos (fail-loud, nunca "zero candidatos")', file=sys.stderr); sys.exit(2)
try:
    today_d = datetime.date.fromisoformat(today)
except ValueError:
    print(f'decide-triage: DECIDE_TODAY inválido ({today}) — AAAA-MM-DD', file=sys.stderr); sys.exit(2)

def git(*a):
    r = subprocess.run(['git', '-C', repo, *a], capture_output=True, text=True)
    return r.returncode, r.stdout
def one(s): return ' '.join(str(s).split())
def clip(s, n):
    s = one(s); return s if len(s) <= n else s[:n - 1] + '…'
def as_date(v):
    if isinstance(v, datetime.datetime): return v.date()
    if isinstance(v, datetime.date): return v
    m = re.match(r'^\s*(\d{4}-\d{2}-\d{2})', str(v or ''))
    if not m: return None
    try: return datetime.date.fromisoformat(m.group(1))
    except ValueError: return None

avisos = []
if ovr: avisos.append(f'override ativo, esta NÃO é a medição de produção: {ovr}')
rc, out = git('-c', 'core.quotePath=false', 'ls-files', '-z', '--', '*.kg.yaml')
graphs = sorted(g for g in out.split('\0') if g and 'fixtures' not in g.split('/') and 'vendor' not in g.split('/'))

# reservas VIVAS do maestro-ask (a mesma leitura do decide-census.sh): «dono ativo» = reserva viva da chave
ask_dir = os.environ.get('ONION_ASK_DIR') or os.path.join(os.environ.get('XDG_STATE_HOME') or os.path.join(os.path.expanduser('~'), '.local', 'state'), 'onion', 'maestro-asks')
_rcg, _gcd = git('rev-parse', '--path-format=absolute', '--git-common-dir')
repo_name = os.path.basename(os.path.dirname(_gcd.strip())) if _rcg == 0 and _gcd.strip() else os.path.basename(os.path.abspath(repo))
live_asks = {}; ask_desc = 'registro ausente'
if os.path.isdir(ask_dir):
    try:
        for fn in sorted(os.listdir(ask_dir)):
            if not fn.endswith('.ask'): continue
            try: f = open(os.path.join(ask_dir, fn), encoding='utf-8').read().rstrip('\n').split('\t')
            except OSError: avisos.append(f'pergunta reservada ilegível: {fn}'); continue
            if len(f) < 5 or not f[4].isdigit():
                avisos.append(f'pergunta reservada fora da forma: {fn}'); continue
            if int(f[4]) > now_s: live_asks[f[0]] = f[1]
        ask_desc = f'{len(live_asks)} viva(s)'
    except OSError as e:
        avisos.append(f'registro de perguntas ilegível ({clip(e, 80)}) — donas NÃO medidas: candidato com dona pode aparecer'); ask_desc = 'NÃO MEDIDO'

CMD_PAT = re.compile(r'`[^`]*(?:\bbash\b|\.sh\b|\bgrep\b|\bgh\b|\bgit\b|\bpython3?\b|\bcurl\b|\bjq\b)[^`]*`')
PATH_PAT = re.compile(r'(?<![\w/.-])((?:\.claude|docs|ops|tools|spec|src|scripts|vendor)/[\w./-]+\.[A-Za-z0-9]+)')
# OS PAPÉIS DESTA CASA: `owner:` com um deles não é «outro papel» (o pedido é a si mesmo). Medido no core em 2026-11-11:
# 65 nós declaram `owner: core` e 49 `owner: maestro` — tratar `core` como outro papel punha o trabalho do próprio
# core na dica `pedido`. --own <papel> (repetível) diz quais são; sem ele: `maestro` sempre, mais o `role:` do
# .claude/.onion-version (adotante) ou `core` quando o repo não tem esse arquivo (a fonte). Lido, nunca deduzido do nome.
own_roles = {'maestro'} | {x.casefold() for x in own.split() if x}
if not own.split():
    ov = os.path.join(repo, '.claude', '.onion-version')
    if os.path.isfile(ov):
        m = re.search(r'(?m)^\s*role\s*:\s*["\']?([A-Za-z0-9._-]+)', open(ov, encoding='utf-8', errors='replace').read())
        if m: own_roles.add(m.group(1).casefold())
    else: own_roles.add('core')
ID_TOK = re.compile(r'[A-Z][A-Z0-9]*_[A-Z0-9_]*[A-Z0-9]')

cands = []; excluded_ask = []; excluded_req = []; young = 0; total_open = 0
closed_citers = []   # (graph, id, verified_at date, set de ids citados) — nós fechados mais novos que podem superar
_blame = {}
def blame_times(g):
    """linha (1-based) → committer-time; linha não commitada → agora. Uma chamada por grafo, só quando precisa."""
    if g in _blame: return _blame[g]
    r = subprocess.run(['git', '-C', repo, 'blame', '--line-porcelain', '--', g], capture_output=True, text=True)
    m = {}
    if r.returncode == 0:
        cur_t = None; cur_ln = None; uncommitted = False
        for l in r.stdout.split('\n'):
            h = re.match(r'^([0-9a-f]{40}) \d+ (\d+)', l)
            if h: cur_ln = int(h.group(2)); uncommitted = set(h.group(1)) == {'0'}; continue
            if l.startswith('committer-time '): cur_t = int(l.split()[1])
            elif l.startswith('\t') and cur_ln is not None:
                m[cur_ln] = now_s if uncommitted else cur_t
    else:
        avisos.append(f'git blame falhou em {g} (rc {r.returncode}): idade por commit NÃO medida nesse grafo')
    _blame[g] = m
    return m

per_graph = {}
for g in graphs:
    p = os.path.join(repo, g)
    if not os.path.isfile(p):
        avisos.append(f'grafo rastreado AUSENTE do disco (não medido): {g}'); continue
    try:
        txt = open(p, encoding='utf-8').read(); d = yaml.safe_load(txt)
    except Exception as e:
        print(f'decide-triage: grafo rastreado que NÃO PARSEIA (YAML ou UTF-8): {g}: {one(e)[:200]} — recuso medir o resto como se ele não existisse', file=sys.stderr)
        sys.exit(2)
    if not isinstance(d, dict) or not isinstance(d.get('nodes') or [], list):
        avisos.append(f'grafo rastreado sem mapa no topo ou sem lista de nós, NÃO medido: {g}'); continue
    nodes = [n for n in (d.get('nodes') or []) if isinstance(n, dict)]
    byid = {str(n.get('id')): n for n in nodes}
    edges = [e for e in (d.get('edges') or []) if isinstance(e, dict)]
    per_graph[g] = (txt, nodes, byid, edges)
    for n in nodes:
        if n.get('node_type') in ('decision', 'question') and n.get('status') in ('done', 'confirmed'):
            va = as_date(n.get('verified_at'))
            if va:
                toks = set(ID_TOK.findall(one(n.get('label') or '') + ' ' + one(n.get('narrative') or '')))
                toks.discard(str(n.get('id')))
                if toks: closed_citers.append((g, str(n.get('id')), va, toks))

for g, (txt, nodes, byid, edges) in per_graph.items():
    lines = txt.split('\n')
    idline = {}
    for i, l in enumerate(lines):
        m = re.match(r'^(\s*)-\s+id:\s*["\']?([A-Za-z0-9_]+)["\']?\s*(#.*)?$', l)
        if m: idline.setdefault(m.group(2), (i + 1, len(m.group(1))))
    for n in nodes:
        if n.get('node_type') not in ('decision', 'question') or n.get('status') != 'open': continue
        total_open += 1
        nid = str(n.get('id'))
        ln, ind = idline.get(nid, (0, 0))
        va = as_date(n.get('verified_at'))
        if va and va > today_d:
            # carimbo no FUTURO não é idade: sumia calado como "abaixo do teto" (limite curado na passada independente)
            avisos.append(f'verified_at no FUTURO ({va.isoformat()} > {today}): {nid} em {g} — idade NÃO MEDIDA, conserte o carimbo'); continue
        if va:
            born = va; src = 'verified_at'
        elif ln:
            end = len(lines)
            for j in range(ln, len(lines)):
                l = lines[j]
                if not l.strip(): continue
                lind = len(l) - len(l.lstrip())
                if lind < ind or (lind == ind and l.lstrip().startswith('-')) or (lind <= ind and l.lstrip().startswith('#')):
                    end = j; break
            bt = blame_times(g)
            ts = [bt[k] for k in range(ln, end + 1) if k in bt]
            if not ts:
                avisos.append(f'idade NÃO MEDIDA (sem verified_at e sem blame do bloco): {nid} em {g}'); continue
            born = datetime.datetime.fromtimestamp(max(ts), datetime.timezone.utc).date(); src = 'commit'
        else:
            avisos.append(f'idade NÃO MEDIDA (sem verified_at e fora da forma `- id:` de bloco): {nid} em {g}'); continue
        age = max(0, (today_d - born).days)
        owner = one(n.get('owner') or '')
        due = as_date(n.get('x_due'))
        delegated = bool(owner) and owner.casefold() not in own_roles and due is not None
        # o pedido VENCIDO volta mesmo abaixo do teto: o selo do pedido rejuvenesce o bloco (idade por commit)
        if age <= maxage and not (delegated and due < today_d): young += 1; continue
        if f'{repo_name}#{nid}' in live_asks:
            excluded_ask.append(f"{nid} ({live_asks[f'{repo_name}#{nid}']})"); continue
        if delegated and due >= today_d:
            excluded_req.append(f'{nid} ({owner} até {due.isoformat()})'); continue
        # ── pistas ──
        sup = []
        for e in edges:
            if str(e.get('to')) == nid and e.get('edge_type') == 'SUPERSEDES':
                fr = str(e.get('from')); sup.append(f"{fr} SUPERSEDES ({(byid.get(fr) or {}).get('status', '?')})")
        for (cg, cid, cva, toks) in closed_citers:
            if nid in toks and cva > born and not (cg == g and cid == nid):
                sup.append(f'{cid} fechado em {cva.isoformat()} cita o id' + ('' if cg == g else f' ({cg})'))
        sup = sup[:4]
        meas = []
        nbr = {str(e.get('to')) for e in edges if str(e.get('from')) == nid} | {str(e.get('from')) for e in edges if str(e.get('to')) == nid}
        prod = sorted(x for x in nbr if (byid.get(x) or {}).get('node_type') in ('claim', 'evidence') and (byid.get(x) or {}).get('plane') == 'PROD')
        if prod: meas.append('vizinho PROD: ' + ', '.join(prod[:3]))
        text = one(n.get('label') or '') + ' ' + one(n.get('narrative') or '')
        cm = CMD_PAT.search(text)
        if cm: meas.append('comando citado: ' + clip(cm.group(0), 60))
        vag = one(n.get('verified_against') or '')
        pth = [x for x in PATH_PAT.findall(vag) if os.path.exists(os.path.join(repo, x))]
        if pth: meas.append('verified_against confere: ' + pth[0])
        if sup: hint, why = 'obsoleto', 'algo mais novo o supera ou o cita fechado'
        elif owner and owner.casefold() not in own_roles:
            hint, why = ('pedido-vencido', f'pedido a {owner} venceu em {due.isoformat()}') if due else ('pedido', f'o nó declara owner: {owner}')
        elif meas: hint, why = 'medição', 'há como conferir contra o vivo'
        else: hint, why = 'maestro', 'nenhuma pista mecânica: escopo, trade-off ou entendimento'
        cands.append({'id': nid, 'origin': f'{g}:{ln}', 'graph': g, 'age': age, 'src': src, 'type': n.get('node_type'),
                      'impact': n.get('impact') or 0, 'label': clip(n.get('label') or '', 160),
                      'superseded': ' · '.join(sup), 'owner': owner + (f' (x_due {due.isoformat()})' if due else ''),
                      'measurable': ' · '.join(meas), 'hint': hint, 'why': why})

ORD = {'obsoleto': 0, 'pedido-vencido': 1, 'pedido': 2, 'medição': 3, 'maestro': 4}
cands.sort(key=lambda c: (ORD[c['hint']], -c['age'], c['origin']))
dist = {}
for c in cands: dist[c['hint']] = dist.get(c['hint'], 0) + 1
def tsvc(s): return str(s).replace('\t', ' ').replace('\n', ' ')
if fmt == '--tsv':
    COLS = ('id', 'origin', 'age_days', 'age_src', 'type', 'superseded', 'owner', 'measurable', 'hint', 'label')
    print('\t'.join(COLS))
    for c in cands:
        print('\t'.join(tsvc(x) for x in (c['id'], c['origin'], c['age'], c['src'], c['type'], c['superseded'], c['owner'], c['measurable'], c['hint'], c['label'])))
    for x in excluded_ask: print(f'excluded\t{tsvc(x)}\t-\t-\tdona viva' + '\t' * 5)
    for x in excluded_req: print(f'excluded\t{tsvc(x)}\t-\t-\tpedido em curso' + '\t' * 5)
    for a in avisos: print(f'warn\t{tsvc(a)}' + '\t' * 8)
    sys.exit(0)

print(f'# decide-triage · {today} · {len(cands)} candidato(s) à triagem em lote')
print(f'papéis da casa (owner que não é pedido): {", ".join(sorted(own_roles))}')
print(f'fontes: grafos={len(per_graph)} · decision/question open={total_open} · teto={maxage}d (idade > teto) · '
      f'abaixo do teto={young} · fora por dona viva={len(excluded_ask)} · fora por pedido em curso={len(excluded_req)} · perguntas={ask_desc}')
print('dicas: ' + ' · '.join(f'{k} {dist.get(k, 0)}' for k in ORD))
print('\n> ⚠️ A DICA É PISTA, NÃO DECISÃO. Leia o nó, classifique com evidência num dos 4 destinos da cláusula 10 da'
      '\n> decide-doctrine e monte o LOTE; só o maestro aprova (uma pergunta, lista visível) e só o selador grava.'
      '\n> `medição` fecha pelo /meta:kg-freshness, nunca pelo selador; `maestro` vai para a rodada normal.')
if avisos:
    print('\n## ⚠️ Avisos (medição incompleta ou não-produção — leia antes das linhas)')
    for a in avisos: print(f'- {a}')
if excluded_ask: print('\n- fora por DONA VIVA (não triar; leve o id à dona): ' + ', '.join(excluded_ask))
if excluded_req: print('- fora por PEDIDO EM CURSO (volta quando o prazo vencer): ' + ', '.join(excluded_req))
shown, rest = cands[:top], cands[top:]
cur = None
for c in shown:
    if c['hint'] != cur:
        cur = c['hint']; print(f'\n## dica: {cur} ({dist[cur]})')
    print(f"- `{c['id']}` ({c['type']}, {c['age']}d por {c['src']}) — {c['origin']} — {c['label']}")
    if c['superseded']: print(f"  - superação: {c['superseded']}")
    if c['owner']: print(f"  - owner: {c['owner']}")
    if c['measurable']: print(f"  - medível: {c['measurable']} → `/meta:kg-freshness {c['graph']} --node {c['id']}`")
if rest:
    print(f'\n⚠️ TETO: mostrados {len(shown)} de {len(cands)} (DECIDE_CENSUS_TOP={top}). Os {len(rest)} restantes NÃO são zero — NOMEADOS: '
          + ', '.join(c['id'] for c in rest))
    print('   Conjunto completo: `bash .claude/validation/decide-triage.sh . --tsv`.')
print(f'\nVEREDITO: {len(cands)} candidato(s) — CLASSIFICAR com evidência e montar o lote (cláusula 10).' if cands
      else '\nVEREDITO: NENHUM candidato acima do teto' + (' — mas a medição está INCOMPLETA (ver avisos).' if avisos else '.'))
PY
