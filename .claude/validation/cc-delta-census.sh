#!/usr/bin/env bash
# ===========================================================================
# cc-delta-census.sh — o MEDIDOR da peça 3 do /meta:cc-update.
#
# Responde por medição o que a sessão responderia de memória depois de atualizar o Claude Code:
#   (1) QUAIS versões entraram: a baseline do eixo E3 (`cc_version` em docs/onion/radar-baselines.yaml)
#       contra o disco (`claude --version`) e o PROCESSO (CLAUDE_CODE_EXECPATH / /proc/$CLAUDE_PID/exe);
#   (2) O QUE diz cada uma: baixa o CHANGELOG OFICIAL e separa só as seções do delta;
#   (3) O QUE no Onion pode ser tocado: inventário das superfícies (hooks do settings.json, rules
#       com `paths:`, skills `context: fork`, agentes por model, a allowlist de modelo do E6,
#       plugins, arquivos de .claude/ que citam scriptPath do Workflow).
# TETO do inventário: lê só .claude/settings.json (não settings.local.json nem hooks de plugin) e conta
# CITAÇÃO de scriptPath, não execução. A cada carga o medidor baixa o CHANGELOG (até 60 s de rede).
#   (4) Com `--write <dir>`: grava `data/<versão>.txt` e o ESQUELETO do grafo da rodada.
#
# ── O QUE ESTE SCRIPT NÃO FAZ (fronteira declarada, nasceu de defeito medido) ──────────────
# Ele NÃO decide se um item do CHANGELOG toca o Onion. Na rodada r8 (2026-10-08) três nós afirmaram
# ligação com o core que não existia (reescrita de input por PreToolUse, SessionStart async, guarda de
# modelo) e o juiz os reprovou medindo o vivo. Casar item com superfície por palavra-chave fabrica
# exatamente essa ligação. Quem liga item a superfície é a rodada, com o juiz conferindo no vivo.
# O inventário mede O QUE EXISTE; o delta diz O QUE MUDOU; o cruzamento é julgamento.
#
# ── O esqueleto não sela nada ─────────────────────────────────────────────────────────────
# Ele nasce com 2 nós (a evidência do delta, com provenance, e a pergunta aberta da rodada) e SEM a
# chave de Aufhebung: a REGRA 89 (Rodada de radar selada reconcilia o corpus que superou (Aufhebung),
# com catraca) acusa a ausência até a rodada decidir entre `x_supersedes_external` e
# `x_supersedes_none`. Chave com prefixo `x_` porque o contrato v3 do `.kg.yaml` só reconhece
# extensão assim (medido em 2026-10-08: a forma sem prefixo reprovava toda rodada nova no gate).
#
# Uso:  bash .claude/validation/cc-delta-census.sh [<repo>] [--markdown|--tsv] [--write <dir>]
# Env (bancada e sandbox; NUNCA para fingir medição):
#   CC_DELTA_CHANGELOG=<arquivo>   usa este CHANGELOG em vez de baixar (bancada sem rede)
#   CC_DELTA_URL=<url>             fonte oficial (default: raw.githubusercontent.com/anthropics/claude-code)
#   CC_DELTA_BASELINE=<x.y.z>      sobrescreve a cc_version lida do baseline
#   CC_DELTA_DISK=<x.y.z>          sobrescreve a versão do disco
#   CC_DELTA_PROC=<x.y.z>          sobrescreve a versão do processo (vazio-definido = sem sinal)
#   CC_DELTA_TODAY=<AAAA-MM-DD>    data da rodada (default: date +%F)
# Exit: 0 = medido (delta ou "NADA A MEDIR", a linha VEREDITO diz qual) · 2 = entrada quebrada
#       (sem baseline, CHANGELOG inalcançável, versão ilegível ou fora do CHANGELOG) — nunca 0 em
#       silêncio. Determinístico, sem LLM. Exercitado por lint-selftest.sh
#       (run_cc_delta_census_selftests).
# ===========================================================================
set -uo pipefail
REPO=""; FMT="--markdown"; WRITE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --markdown|--tsv) FMT="$1" ;;
    --write) shift; WRITE="${1:?--write exige o diretório da rodada}" ;;
    --*) echo "cc-delta-census: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "cc-delta-census: alvo inexistente: ${REPO}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "cc-delta-census: python3 ausente — não meço sem ele (nunca 0 em silêncio)" >&2; exit 2; }

# Override ativo é DECLARADO antes de qualquer veredito. Achado do 1º dogfood de carga (2026-10-08): com
# CC_DELTA_URL herdado de um teste, a sessão leu "CHANGELOG oficial inalcançável" e a causa era a variável.
# O erro culpava a fonte; quem lê tem de saber que a medição não é a de produção.
OVR="$(env | LC_ALL=C grep -oE '^CC_DELTA_[A-Z]+=.*' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"
[ -n "${OVR}" ] && echo "cc-delta-census: ⚠️ override ativo — esta NÃO é a medição de produção: ${OVR}" >&2

# ── versões ────────────────────────────────────────────────────────────────────────────────
_ver() { grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }
BASE="${CC_DELTA_BASELINE:-}"
if [ -z "${BASE}" ]; then
  BL="${REPO}/docs/onion/radar-baselines.yaml"
  [ -f "${BL}" ] || { echo "cc-delta-census: ${BL} ausente — sem baseline do E3 não há delta a medir" >&2; exit 2; }
  BASE="$(awk '/id: E3-claude-code-delta/{f=1;next} f&&/^  - id:/{f=0} f&&/cc_version:/{print;exit}' "${BL}" | _ver)"
  [ -n "${BASE}" ] || { echo "cc-delta-census: o eixo E3 de ${BL} não tem cc_version legível" >&2; exit 2; }
fi
DISK="${CC_DELTA_DISK-}"
if [ -z "${CC_DELTA_DISK+x}" ]; then
  DISK="$( (claude --version 2>/dev/null || true) | _ver)"
fi
PROC="${CC_DELTA_PROC-}"
if [ -z "${CC_DELTA_PROC+x}" ]; then
  ep="${CLAUDE_CODE_EXECPATH:-}"
  [ -n "${ep}" ] && PROC="$(printf '%s' "${ep##*/}" | _ver)"
  if [ -z "${PROC}" ] && [ -n "${CLAUDE_PID:-}" ] && [ -r "/proc/${CLAUDE_PID}/exe" ]; then
    PROC="$(readlink "/proc/${CLAUDE_PID}/exe" 2>/dev/null | sed 's/ (deleted)$//; s|.*/||' | _ver)"
  fi
fi
[ -n "${DISK}${PROC}" ] || { echo "cc-delta-census: nem o disco nem o processo deram versão do Claude Code — não sei o que foi instalado" >&2; exit 2; }

# ── CHANGELOG oficial ──────────────────────────────────────────────────────────────────────
CL="${CC_DELTA_CHANGELOG:-}"
TMPD="$(mktemp -d)"; trap 'rm -rf "${TMPD}"' EXIT
if [ -z "${CL}" ]; then
  URL="${CC_DELTA_URL:-https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md}"
  CL="${TMPD}/CHANGELOG.md"
  if ! curl -sfL --max-time 60 "${URL}" -o "${CL}"; then
    echo "cc-delta-census: CHANGELOG oficial inalcançável (${URL}) — declaro a lacuna e paro; não invento o delta" >&2; exit 2
  fi
fi
[ -s "${CL}" ] || { echo "cc-delta-census: CHANGELOG vazio ou ausente: ${CL}" >&2; exit 2; }

TODAY="${CC_DELTA_TODAY:-$(date +%F)}"
PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${REPO}" "${CL}" "${BASE}" "${DISK}" "${PROC}" "${FMT}" "${WRITE}" "${TODAY}" "${OVR}" <<'PY'
import sys, os, re, json, glob, datetime
repo, cl, base, disk, proc, fmt, write, today, ovr = sys.argv[1:10]
def vt(v): return tuple(int(x) for x in v.split('.'))
text = open(cl, encoding='utf-8').read()
parts = re.split(r'(?m)^## ', text)
sections = {}
for p in parts[1:]:
    head = p.split('\n', 1)[0].strip()
    m = re.match(r'^(\d+\.\d+\.\d+)\b', head)
    if m: sections[m.group(1)] = '## ' + p   # byte-a-byte como a r8: a seção inclui a linha em branco que a separa da próxima
if not sections:
    print('cc-delta-census: nenhuma seção "## x.y.z" no CHANGELOG — formato desconhecido, não meço', file=sys.stderr); sys.exit(2)
if base not in sections:
    print(f'cc-delta-census: a baseline {base} não está no CHANGELOG — o delta seria chute', file=sys.stderr); sys.exit(2)
target = max([v for v in (disk, proc) if v], key=vt)
if target not in sections:
    print(f'cc-delta-census: a versão instalada {target} não está no CHANGELOG (fonte defasada?) — não meço', file=sys.stderr); sys.exit(2)
delta = sorted([v for v in sections if vt(base) < vt(v) <= vt(target)], key=vt)
items = {v: len(re.findall(r'(?m)^- ', sections[v])) for v in delta}
lines = {v: len(sections[v].splitlines()) for v in delta}
avisos = []
if ovr:
    avisos.append(f'override ativo, esta NÃO é a medição de produção: {ovr}')
if disk and proc and disk != proc:
    avisos.append(f'processo em {proc} e disco em {disk}: o que só existe na versão nova está invisível nesta sessão (reinicie antes de medir capacidade)')
if vt(target) < vt(base):
    avisos.append(f'a instalada ({target}) é ANTERIOR à baseline ({base}) — downgrade? nada a medir para frente')

# ── inventário das superfícies do Onion (o que EXISTE; não o que é tocado) ─────────────────
def fm(path):
    try: s = open(path, encoding='utf-8').read()
    except Exception: return ''
    if not s.startswith('---'): return ''
    end = s.find('\n---', 3)
    return s[3:end] if end > 0 else ''
inv = {}
hooks = []
sj = os.path.join(repo, '.claude/settings.json')
if os.path.isfile(sj):
    try:
        conf = json.load(open(sj, encoding='utf-8'))
    except Exception as e:
        print(f'cc-delta-census: .claude/settings.json ilegível ({e}) — inventário de hooks impossível', file=sys.stderr); sys.exit(2)
    for ev, arr in (conf.get('hooks') or {}).items():
        for m in arr or []:
            for h in m.get('hooks', []) or []:
                cmd = h.get('command') or h.get('url') or h.get('prompt') or ''
                nm = re.search(r'([A-Za-z0-9_.-]+\.(?:sh|py|js|mjs))', cmd)
                hooks.append({'evento': ev, 'tipo': h.get('type', '?'), 'alvo': nm.group(1) if nm else cmd[:40],
                              'onFailure': h.get('onFailure', '—'), 'async': h.get('async', False), 'timeout': h.get('timeout', '—')})
inv['hooks'] = hooks
inv['rules_paths'] = sorted(os.path.relpath(f, repo) for f in glob.glob(os.path.join(repo, '.claude/rules/*.md')) if re.search(r'(?m)^paths:', fm(f)))
inv['skills_fork'] = sorted(os.path.relpath(f, repo) for f in glob.glob(os.path.join(repo, '.claude/skills/*/SKILL.md')) if re.search(r'(?m)^context:\s*fork', fm(f)))
models = {}
for f in glob.glob(os.path.join(repo, '.claude/agents/**/*.md'), recursive=True):
    m = re.search(r'(?m)^model:\s*(.+)$', fm(f))
    k = m.group(1).strip() if m else '(sem model)'
    models[k] = models.get(k, 0) + 1
inv['agentes_por_model'] = dict(sorted(models.items()))
sm = []
bl = os.path.join(repo, 'docs/onion/radar-baselines.yaml')
if os.path.isfile(bl):
    s = open(bl, encoding='utf-8').read()
    m = re.search(r'session_models:\s*\n((?:\s+- .+\n)+)', s)
    if m: sm = [re.sub(r'\s*#.*$', '', x).strip('- "\'\t ') for x in m.group(1).splitlines()]
inv['session_models'] = [x for x in sm if x]
# a rodada anterior e o diretório da próxima saem da baseline, não da memória de quem conduz
prev_kg, next_dir = '', ''
if os.path.isfile(bl):
    m = re.search(r'id: E3-claude-code-delta\n((?:    .*\n|\s*#.*\n)+)', open(bl, encoding='utf-8').read())
    k = re.search(r'(?m)^    kg:\s*(\S+)', m.group(1)) if m else None
    if k:
        prev_kg = k.group(1)
        r = re.search(r'-r(\d+)/', prev_kg)
        if r: next_dir = f'docs/evolution/research/radar-E3-{today}-r{int(r.group(1)) + 1}/'
inv['plugins'] = sorted(os.path.basename(d) for d in glob.glob(os.path.join(repo, 'plugins/*')) if os.path.isdir(d))
inv['marketplace'] = os.path.isfile(os.path.join(repo, '.claude-plugin/marketplace.json'))
wf = []
for pat in ('.claude/**/*.md', '.claude/**/*.js', '.claude/**/*.mjs'):
    for f in glob.glob(os.path.join(repo, pat), recursive=True):
        if '/worktrees/' in f: continue
        try:
            if 'scriptPath' in open(f, encoding='utf-8').read(): wf.append(os.path.relpath(f, repo))
        except Exception: pass
inv['workflow_scriptpath'] = sorted(set(wf))
# sinal factual, não ligação: id de modelo citado no delta que não está na allowlist do E6
novos = sorted({m for v in delta for m in re.findall(r'claude-[a-z]+-\d+(?:-\d+)?', sections[v])} - set(inv['session_models']))

veredito = 'NADA A MEDIR' if not delta else f'DELTA {len(delta)} versão(ões): {delta[0]} a {delta[-1]}'
sem_onfail = [h for h in hooks if h['onFailure'] == '—']

if write:
    os.makedirs(os.path.join(write, 'data'), exist_ok=True)
    for v in delta:
        open(os.path.join(write, 'data', f'{v}.txt'), 'w', encoding='utf-8').write(sections[v])
    if delta:
        rid = os.path.basename(os.path.normpath(write))
        review = (datetime.date.fromisoformat(today) + datetime.timedelta(days=30)).isoformat()
        conta = ', '.join(f'{v} ({lines[v]} linhas, {items[v]} itens)' for v in delta)
        rel = os.path.relpath(os.path.join(write, 'data'), repo) if os.path.isabs(write) else os.path.join(write, 'data')
        kg = f'''# kg-backlog-guard: on
# Radar E3 (ecossistema Claude Code): o delta de {delta[0]} a {delta[-1]} contra a baseline {base}.
# ESQUELETO gerado por .claude/validation/cc-delta-census.sh — a rodada liga item a superfície (com medição
# no vivo), o juiz refuta, e a rodada decide a Aufhebung: x_supersedes_external ou x_supersedes_none.
meta:
  id: {rid}
  schema_version: "1"
  baseline: "{today}"
  review_after: "{review}"   # 30d: cadência de ferramenta
  # ═══ TETO: 25 NÓS ═══
  #   2 no esqueleto ({today}).
nodes:
  - id: E_DELTA_DA_RODADA
    node_type: evidence
    layer: audit
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    verified_at: "{today}"
    verified_against: "CHANGELOG oficial: seções {conta}; baseline {base}, disco {disk or '—'}, processo {proc or '—'}"
    label: "o delta desde a baseline {base} são {len(delta)} versão(ões), de {delta[0]} a {delta[-1]}, extraídas do CHANGELOG oficial"
    provenance:
      source: "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
      locator: "seções ## {delta[0]} a ## {delta[-1]} (cópias em {rel}/)"
      method: "medição: extração determinística pelo cc-delta-census.sh"
  - id: Q_O_QUE_O_DELTA_TOCA_NO_ONION
    node_type: question
    layer: audit
    plane: DEV
    status: open
    impact: 3
    confidence: 0.5
    verified_at: "{today}"
    verified_against: "aberta pelo esqueleto em {today}; fecha quando a rodada ligar cada item a superfície medida no vivo e o juiz refutar"
    label: "quais itens de {delta[0]} a {delta[-1]} tocam o Onion de verdade, medidos no vivo e julgados pelo juiz"
edges:
  - from: E_DELTA_DA_RODADA
    to: Q_O_QUE_O_DELTA_TOCA_NO_ONION
    edge_type: SUPPORTS
'''
        open(os.path.join(write, f'{rid}.kg.yaml'), 'w', encoding='utf-8').write(kg)

if fmt == '--tsv':
    print(f'veredito\t{veredito}'); print(f'baseline\t{base}'); print(f'disco\t{disk}'); print(f'processo\t{proc}')
    print(f'rodada_anterior\t{prev_kg}'); print(f'proxima_rodada\t{next_dir}')
    for v in delta: print(f'versao\t{v}\t{lines[v]}\t{items[v]}')
    print(f'hooks\t{len(hooks)}\tsem_onFailure\t{len(sem_onfail)}')
    for a in avisos: print(f'aviso\t{a}')
    sys.exit(0)

print(f'# delta do Claude Code · {today}\n')
print(f'**VEREDITO: {veredito}**\n')
print('| fonte | versão |\n|---|---|')
print(f'| baseline E3 (`cc_version`) | {base} |\n| disco (`claude --version`) | {disk or "— (sem sinal)"} |\n| processo | {proc or "— (sem sinal)"} |\n')
for a in avisos: print(f'⚠️ {a}\n')
if not delta:
    print('Nada a medir: a instalada não passa da baseline. Não há rodada a escrever.')
    sys.exit(0)
print(f'- rodada anterior (baseline E3 `kg`): `{prev_kg or "— (não lida)"}`')
print(f'- diretório da próxima rodada: `{next_dir or "— (sem -rN na rodada anterior: nomeie à mão)"}`\n')
print('## seções do delta (texto integral em `data/<versão>.txt` com `--write`)\n')
print('| versão | linhas | itens |\n|---|---|---|')
for v in delta: print(f'| {v} | {lines[v]} | {items[v]} |')
print('\n## superfícies do Onion (inventário; a LIGAÇÃO item↔superfície é da rodada e do juiz)\n')
print(f'- hooks: **{len(hooks)}**, sem `onFailure`: **{len(sem_onfail)}**, async: {sum(1 for h in hooks if h["async"])}')
for h in hooks: print(f'  - {h["evento"]} · {h["tipo"]} · {h["alvo"]} · onFailure={h["onFailure"]} · timeout={h["timeout"]}')
print(f'- rules com `paths:` ({len(inv["rules_paths"])}): ' + ', '.join(inv['rules_paths']))
print(f'- skills `context: fork`: {len(inv["skills_fork"])}' + (': ' + ', '.join(inv['skills_fork']) if inv['skills_fork'] else ''))
print('- agentes por model: ' + ', '.join(f'{k}={v}' for k, v in inv['agentes_por_model'].items()))
print('- allowlist de modelo (E6 `session_models`): ' + (', '.join(inv['session_models']) or '— (não lida)'))
print(f'- plugins ({len(inv["plugins"])}): ' + ', '.join(inv['plugins']) + f' · marketplace.json: {"sim" if inv["marketplace"] else "não"}')
print(f'- arquivos de `.claude/` que citam `scriptPath` (citação, não execução): {len(inv["workflow_scriptpath"])}')
if novos: print(f'\n- sinal: ids de modelo citados no delta e fora da allowlist do E6: ' + ', '.join(novos))
print('\n(TETO: este censo mede versões, delta e superfícies. Ele NÃO diz que um item toca o Onion —'
      ' na r8 três ligações assim foram reprovadas pelo juiz medindo o vivo.)')
PY
