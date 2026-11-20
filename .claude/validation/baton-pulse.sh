#!/usr/bin/env bash
# ===========================================================================
# baton-pulse.sh — o MEDIDOR da peça 3 do /meta:baton (o pulso da batuta).
#
# Responde por medição o que a sessão responderia de memória quando o maestro pergunta «como estão as sessões?»
# e, no /loop, «tem sessão parada com trabalho pronto?». Pedido do maestro em 2026-11-12: «as sessões ficam ociosas
# esperando algo mas poderiam tocar outras tarefas que são necessárias, e a batuta serviria para isso».
# É o NÍVEL 0 da escada selada (D_AUTOMATION_LEVELS_0_TO_2_SCHEDULED_1111): só MEDE e LÊ. Não grava grafo, não
# manda mensagem, não despacha. Quem pergunta às sessões é a sessão que roda o /meta:baton (SendMessage), nunca este script.
#
# ── DESCOBERTA POR REFERÊNCIA, COM FONTE EM CADA LINHA ──────────────────────────────────────────
#   sessões   (1) a lista de peers do harness: `claude agents --json` (a interface suportada; a mesma que a linha de
#                 sessões da statusLine lê), ou o arquivo passado em --peers (o que a ferramenta ListAgents devolveu
#                 na sessão, salvo em JSON). Status busy|idle|waiting, state working|blocked, pid, cwd, sessionId.
#             (2) os FARÓIS (session-beacon.sh, achado AO LADO deste script): o checkout principal deste repo e, com a
#                 família ligada, o `local_path` de cada membro em docs/evolution/federation/members.yaml. O veredito
#                 de cada farol é o do próprio session-beacon.sh (`verdict`), nunca reimplementado aqui.
#   atividade a última prova de vida da sessão: o mtime do transcript (~/.claude/projects/*/<sessionId>.jsonl, só
#             `stat`, o conteúdo NÃO é lido) e o refreshed_at do farol (só sobe no prompt). Vale o mais novo.
#   fila      PRONTA de cada sessão, só de dono DECLARADO, nada inferido de prosa:
#             · nós `open` com `owner:` igual ao rótulo da sessão, em todo .kg.yaml rastreado (fora fixtures/vendor);
#             · reservas de pergunta ao maestro cuja dona é o id da sessão (registro do maestro-ask.sh);
#             · PRs abertos cuja branch é a do farol da sessão ou está na worktree onde ela roda.
#             O RÓTULO da sessão (o `owner:` que ela atende) vem de owners.tsv no diretório de estado (chave = id,
#             nome ou cwd; rótulo) ou, sem linha lá, de candidatos derivados e DITOS: o nome, a pasta do cwd, a pasta
#             sem o prefixo `onion-`, e `core` para o checkout principal do repo que roda o pulso quando ele é a fonte
#             (role: source, ou sem carimbo .claude/.onion-version, que é o core).
#             Dono declarado sem sessão casada sai em «fila sem sessão», nunca é atribuído por palpite.
#   parada    por ordem do maestro: parked.tsv no diretório de estado (sessão | motivo | até). A chave casa o id,
#             o nome ou o rótulo. «até» vazio ou `-` = até nova ordem; vencido = não vale e é dito.
#   em voo    PRs com CI e idade, worktrees com pendência, sinais sem ack, perguntas reservadas, candidatas a selo e
#             checkpoints: TUDO do decide-census.sh --tsv (achado ao lado), não remedido aqui.
#   carga     /proc/loadavg e, onde existe, o `check` do lease de carga do core (ops/load-lease.sh, core-only).
#
# ── CLASSES (saída de máquina, em inglês) ───────────────────────────────────────────────────────
#   PARKED           tem linha viva no parked.tsv. Vence tudo: parada por ordem NUNCA vira ociosa.
#   UNREACHABLE      a fonte diz que existiu e não há processo: pid morto, sessão de fundo sem pid, farol orphan|stale.
#   ACTIVE           o harness diz busy, ou houve atividade há menos de --idle-min (padrão 20).
#   IDLE_WITH_QUEUE  ociosa e com fila pronta de dono declarado — o caso que a fase 2 ataca.
#   IDLE_NO_QUEUE    ociosa e sem fila declarada.
#   PARK_UNMEASURED  o parked.tsv EXISTE e não se lê (permissão, diretório): fail-closed, toda sessão alcançável sai
#                    aqui e nenhuma recebe oferta. Ilegível nunca vira «ninguém parado».
#   SUBAGENTES (SAC-421, 2026-11-12) de cada sessão viva e desta: <projects>/*/<sessão>/subagents/agent-<id>.jsonl e os
#   da ferramenta Workflow em subagents/workflows/<run>/agent-<id>.jsonl (o <id>.output em /tmp/claude-<uid>/…/tasks/ é
#   symlink para o primeiro). Lê o CONTEÚDO do transcript do subagente. Pendente = tool_use sem tool_result do MESMO id;
#   nem texto do usuário (a cutucada do líder) nem nova mensagem do assistente fecham pendência (pendência aberta nunca é DONE):
#   AGENT_STALLED    há pendente e o mtime passou de --stall-min (padrão 15). Mede o SINTOMA, não a causa: aprovação
#                    sem quem responda, comando pendurado, harness travado e ferramenta longa legítima saem iguais.
#   AGENT_SILENT     sem pendente, sem fim e sem escrita além do teto (nomeia o «Exit code 137» do último resultado).
#   AGENT_RUNNING    pendente mais novo que o teto, ou escrita recente sem fim.
#   AGENT_DONE       texto final do assistente, relatório entregue (SubagentHandback, ou StructuredOutput no agente de
#                    Workflow) ou interrupção pelo humano. A idade é a da última entrada user/assistant (attachment não conta).
#   AGENT_UNMEASURED transcript ilegível ou sem entrada user/assistant: NÃO medido, nunca «não parado».
#   O comando pendente sai com segredo trocado por [REDACTED] (por LISTA: o que não está nela passa) e a home por ~. Só STALLED, SILENT e UNMEASURED entram no
#   sha. Não sabe se o processo do subagente vive (o harness não expõe pid por subagente): um pendurado E morto sai STALLED.
#   PEÇAS (D_BACKBONE_OWNER_1112, 2026-11-12): todo membro `piece: true` do members.yaml tem sessão dona. Dono em ordem
#   fixa, parando na 1ª: owner_session do members.yaml → owners.tsv (linha cujo rótulo é o id da peça) → a sessão do core.
#   Casa pelo NOME da sessão viva (não UNREACHABLE), nunca pelo ref. Aviso, nunca bloqueio; cada aviso traz o card de
#   arranque (texto: o pulso nunca abre sessão):
#   PIECE_OWNED               há sessão viva com o nome do dono.
#   PIECE_UNOWNED             nenhuma sessão viva com esse nome, nem sessão viva no repo da peça.
#   PIECE_OWNER_NAME_MISMATCH há sessão viva com cwd no repo da peça, com outro nome: a retomada troca ref e nome, e o
#                             desencontro não pode sair como dono ausente (pedido de rigor da curadoria).
#   PIECE_UNMEASURED          sem a lista de peers não há nome a casar, ou o leitor de posse falhou: NÃO medido, nunca «sem dono».
#   O 1º degrau (owner_session) é lido pelo LEITOR ÚNICO de posse, .claude/utils/orchestration/ownership.sh (o mesmo do
#   ops/session-open.sh, D_SESSION_ONE_OWNERSHIP_REGISTRY_BY_NAME_1120); BATON_OWNERSHIP troca o caminho (bancada).
#   HIGIENE (D_SESSION_HYGIENE_TMUX_WORKTREE_1114, 2026-11-14): por PROCESSO interativo vivo dos peers, lendo <proc>
#   (BATON_PROC, padrão /proc): stat (estado, ppid), comm e, SÓ do processo `claude`, a chave TMUX do environ (presença;
#   o resto do ambiente nunca sai). Aviso, nunca bloqueio; cada aviso traz o comando de cura como texto:
#   SESSION_STOPPED        estado T|t (Ctrl+Z, SIGSTOP): suspensa e invisível, o harness segue listando idle.
#   SESSION_NOT_IN_TMUX    sem TMUX e sem ancestral tmux (ex.: mosh-server→bash): sem reanexar e sem sobreviver a reboot/fim do terminal.
#   SESSION_SAME_CHECKOUT  duas interativas vivas no mesmo topo git: a 2ª abre com `claude --worktree`.
#   SESSION_CAP            SESSÕES interativas distintas (dedupe por sid; a retomada em dois terminais conta uma) acima de --max-interactive (padrão 10, D_SESSION_CAP_10_PLUS_5_AGENTS_1119, 2026-11-19; antes 8).
#   Estado ou árvore ilegível é lacuna (HYGIENE_UNMEASURED), nunca «em tmux».
#   Teto do que dá para medir: atividade é escrita no transcript ou prompt; uma sessão que só espera um processo
#   longo em primeiro plano escreve no transcript ao voltar, então sai ociosa enquanto espera (o harness diz busy e
#   isso vence, quando a lista de peers foi lida). Sem lista de peers, a classe é só pela idade do farol.
#
# ── MODO SILENCIOSO (o /loop) ───────────────────────────────────────────────────────────────────
#   --quiet --last-sha <sha> [--since <iso>]: a batida sem mudança sai em UMA linha, e SÓ quando o sha do estado bate
#   com o --last-sha (classe e fila de cada sessão, CI e PARADO de cada PR, PARADO de cada worktree, os ids dos sinais
#   pendentes, perguntas, carga, e o que foi ou não medido). O --since só ACRESCENTA eventos datados (sessão nova, sessão
#   que ficou ociosa, pergunta nova, PR que se moveu); sozinho ele não cala nada: sem --last-sha não há base e a batida
#   fala. A linha única carrega o aviso do que não foi medido (PRs, sinais, perguntas, parada).
#
# Uso:  bash .claude/validation/baton-pulse.sh [<repo>] [--markdown|--tsv] [--quiet] [--since <iso|epoch>]
#                [--last-sha <sha>] [--idle-min N] [--stall-min N] [--peers <arquivo.json|->] [--no-peers] [--no-family]
#                [--skip-repo <caminho>]... [--no-gh] [--self <sessionId>] [--max-interactive N]
# Env (bancada; todo override ativo é DECLARADO na saída):
#   BATON_NOW=<epoch>  BATON_STATE_DIR=<dir> (padrão ~/.local/state/onion/baton)  BATON_PROJECTS_DIR=<dir>
#   BATON_DECIDE_TSV=<arquivo> (saída pronta do decide-census --tsv)  BATON_CLAUDE=<binário>  ONION_ASK_DIR=<dir>
#   BATON_PROC=<dir> (um /proc falso: a bancada da higiene)  BATON_TOPLEVEL_TIMEOUT_S=<seg> (teto do rev-parse por cwd, padrão 5)
# Exit: 0 = medido (inclusive com lacunas DECLARADAS) · 2 = entrada quebrada (opção, data, python3/PyYAML ausente).
# Determinístico, sem LLM, 0 tokens. Exercitado por lint-selftest.sh (run_baton_pulse_selftests).
# ===========================================================================
set -uo pipefail
REPO=""; MAXI="10"; FMT="--markdown"; QUIET="0"; SINCE=""; LAST=""; IDLE="20"; STALL="15"; PEERS=""; NOPEERS="0"; FAMILY="1"; SKIP=""; NOGH="0"; SELF=""
_need() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "baton-pulse: $1 exige um valor" >&2; exit 2; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --markdown|--tsv) FMT="$1" ;;
    --quiet) QUIET="1" ;;
    --since) _need "$@"; shift; SINCE="$1" ;;
    --last-sha) _need "$@"; shift; LAST="$1" ;;
    --idle-min) _need "$@"; shift; IDLE="$1" ;;
    --stall-min) _need "$@"; shift; STALL="$1" ;;
    --peers) _need "$@"; shift; PEERS="$1" ;;
    --no-peers) NOPEERS="1" ;;
    --no-family) FAMILY="0" ;;
    --skip-repo) _need "$@"; shift; SKIP="${SKIP}${SKIP:+
}$1" ;;
    --no-gh) NOGH="1" ;;
    --max-interactive) _need "$@"; shift; MAXI="$1" ;;
    --self) _need "$@"; shift; SELF="$1" ;;
    --*) echo "baton-pulse: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
case "${STALL}" in ''|*[!0-9]*|0) echo "baton-pulse: --stall-min inválido (${STALL}) — inteiro >= 1" >&2; exit 2 ;; esac
case "${IDLE}" in ''|*[!0-9]*|0) echo "baton-pulse: --idle-min inválido (${IDLE}) — inteiro >= 1" >&2; exit 2 ;; esac
case "${MAXI}" in ''|*[!0-9]*|0) echo "baton-pulse: --max-interactive inválido (${MAXI}) — inteiro >= 1" >&2; exit 2 ;; esac
case "${BATON_NOW:-0}" in *[!0-9]*) echo "baton-pulse: BATON_NOW inválido (${BATON_NOW}) — epoch em segundos" >&2; exit 2 ;; esac
case "${LAST}" in ''|*[!0-9a-f]*) [ -z "${LAST}" ] || { echo "baton-pulse: --last-sha inválido (${LAST}) — hexadecimal" >&2; exit 2; } ;; esac
# --since se valida ANTES de medir (o decide-census custa ~15 s): a forma completa o Python confere de novo
[ -z "${SINCE}" ] || LC_ALL=C grep -qE '^([0-9]+|[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}:[0-9]{2}(:[0-9]{2})?)?Z?)$' <<< "${SINCE}" \
  || { echo "baton-pulse: --since inválido (${SINCE}) — AAAA-MM-DD[THH:MM[:SS]][Z] (UTC) ou epoch" >&2; exit 2; }
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
[ -d "${REPO}" ] || { echo "baton-pulse: alvo inexistente: ${REPO}" >&2; exit 2; }
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 || { echo "baton-pulse: sem índice git em ${REPO}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "baton-pulse: python3 ausente — não meço sem ele (nunca 0 em silêncio)" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPD="$(mktemp -d)"; trap 'rm -rf "${TMPD}"' EXIT
if [ "${PEERS}" = "-" ]; then cat > "${TMPD}/peers.json"; PEERS="${TMPD}/peers.json"; fi
[ -z "${PEERS}" ] || [ -r "${PEERS}" ] || { echo "baton-pulse: --peers ilegível: ${PEERS}" >&2; exit 2; }

# ── o que está em voo: o decide-census.sh, achado AO LADO (por referência, nunca reimplementado) ──
DC_RC=""; DC_FILE="${TMPD}/decide.tsv"
if [ -n "${BATON_DECIDE_TSV:-}" ]; then
  cp "${BATON_DECIDE_TSV}" "${DC_FILE}" 2>/dev/null && DC_RC="override" || DC_RC="ilegível: ${BATON_DECIDE_TSV}"
elif [ -f "${HERE}/decide-census.sh" ]; then
  _dca=("${REPO}" --tsv); [ "${NOGH}" = 1 ] && _dca+=(--no-gh); [ -n "${SELF}" ] && _dca+=(--self "${SELF}")
  bash "${HERE}/decide-census.sh" "${_dca[@]}" > "${DC_FILE}" 2> "${TMPD}/decide.err"; DC_RC="$?"
else DC_RC="ausente: ${HERE}/decide-census.sh"; fi

# ── a lista de peers do harness ──
PEERS_SRC=""
if [ "${NOPEERS}" = 1 ]; then PEERS_SRC="desligada (--no-peers)"
elif [ -n "${PEERS}" ]; then PEERS_SRC="file:${PEERS}"
else
  _cl="${BATON_CLAUDE:-claude}"
  if command -v "${_cl}" >/dev/null 2>&1; then
    if timeout 20 "${_cl}" agents --json > "${TMPD}/agents.json" 2> "${TMPD}/agents.err"; then
      PEERS="${TMPD}/agents.json"; PEERS_SRC="cmd:${_cl} agents --json"
    else PEERS_SRC="falhou: ${_cl} agents --json (rc $?)"; fi
  else PEERS_SRC="ausente: ${_cl} (sem binário do harness nesta máquina)"; fi
fi

# ── carga ──
LOAD_LINE=""
if [ -r /proc/loadavg ]; then LOAD_LINE="load1 $(cut -d' ' -f1 /proc/loadavg)"; else LOAD_LINE="não medida (/proc/loadavg ilegível)"; fi
_ll="$(git -C "${REPO}" rev-parse --show-toplevel 2>/dev/null)/ops/load-lease.sh"
if [ -f "${_ll}" ]; then
  bash "${_ll}" check >/dev/null 2>&1; case "$?" in 0) LOAD_LINE="${LOAD_LINE} · lease livre" ;; 3) LOAD_LINE="${LOAD_LINE} · lease OCUPADO (load ≥ HIGH)" ;; *) LOAD_LINE="${LOAD_LINE} · lease não mediu" ;; esac
else LOAD_LINE="${LOAD_LINE} · lease ausente neste papel"; fi

OVR="$(env | LC_ALL=C grep -oE '^(BATON_(NOW|STATE_DIR|PROJECTS_DIR|DECIDE_TSV|CLAUDE|PROC|TOPLEVEL_TIMEOUT_S)|ONION_ASK_DIR)=.*' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"

PYTHONDONTWRITEBYTECODE=1 python3 -I -B - "${REPO}" "${FMT}" "${QUIET}" "${SINCE}" "${LAST}" "${IDLE}" "${PEERS}" "${PEERS_SRC}" \
  "${FAMILY}" "${SKIP}" "${SELF}" "${HERE}" "${DC_FILE}" "${DC_RC}" "${LOAD_LINE}" "${OVR}" "${STALL}" "${MAXI}" <<'PY'
import sys, os, re, json, glob, time, hashlib, subprocess, datetime
(repo, fmt, quiet, since, last_sha, idle_min, peers_file, peers_src, family, skip, self_sid, here, dc_file, dc_rc,
 load_line, ovr, stall_min, max_inter) = sys.argv[1:19]
stall_s = int(stall_min) * 60
quiet = quiet == '1'; idle_s = int(idle_min) * 60
self_sid = self_sid or os.environ.get('CLAUDE_CODE_SESSION_ID', '')
now = int(os.environ.get('BATON_NOW') or time.time())
home = os.path.expanduser('~')
state_dir = os.environ.get('BATON_STATE_DIR') or os.path.join(os.environ.get('XDG_STATE_HOME') or os.path.join(home, '.local/state'), 'onion/baton')
proj_dir = os.environ.get('BATON_PROJECTS_DIR') or os.path.join(home, '.claude/projects')
ask_dir = os.environ.get('ONION_ASK_DIR') or os.path.join(os.environ.get('XDG_STATE_HOME') or os.path.join(home, '.local/state'), 'onion/maestro-asks')
try:
    import yaml
except ImportError:
    print('baton-pulse: PyYAML ausente — os grafos (fila de dono declarado) não podem ser lidos', file=sys.stderr); sys.exit(2)

def iso(ts): return datetime.datetime.fromtimestamp(int(ts), datetime.timezone.utc).strftime('%Y-%m-%dT%H:%MZ')
def parse_since(s):
    if not s: return None
    if s.isdigit(): return int(s)
    m = re.fullmatch(r'(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?Z?', s)
    if not m: print(f'baton-pulse: --since inválido ({s}) — AAAA-MM-DD[THH:MM[:SS]][Z] (UTC) ou epoch', file=sys.stderr); sys.exit(2)
    d = datetime.datetime.fromisoformat(m.group(1)).replace(tzinfo=datetime.timezone.utc)
    d = d.replace(hour=int(m.group(2) or 0), minute=int(m.group(3) or 0), second=int(m.group(4) or 0))
    return int(d.timestamp())
since_ts = parse_since(since)
def git(*a, cwd=None, timeout=None):
    # timeout=None (o default de toda chamada) = sem teto, comportamento inalterado; só a varredura de cwd dos peers
    # passa um teto curto (cwd em mount travado pendura o pulso inteiro). Estouro → (None, '') e quem chamou nomeia a LACUNA.
    try:
        r = subprocess.run(['git', '-C', cwd or repo, *a], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None, ''
    return r.returncode, r.stdout.strip()
def real(p):
    try: return os.path.realpath(p)
    except Exception: return p
def mins(sec): return None if sec is None else max(0, sec) // 60

gaps, warns = [], []
if ovr: warns.append(f'override ativo, esta NÃO é a medição de produção: {ovr}')
_, common = git('rev-parse', '--path-format=absolute', '--git-common-dir')
main_checkout = real(os.path.dirname(common)) if common else real(repo)
role = ''
try:
    for ln in open(os.path.join(main_checkout, '.claude/.onion-version'), encoding='utf-8'):
        m = re.match(r'\s*role:\s*"?([a-z-]+)', ln)
        if m: role = m.group(1); break
except OSError: role = 'source'   # sem carimbo .onion-version = o core (a convenção da casa, como no dissect-census)

# ── sessões: peers do harness ───────────────────────────────────────────────────────────
S = {}   # sid → dict
def sess(sid):
    return S.setdefault(sid, {'sid': sid, 'name': '', 'cwd': '', 'pid': None, 'status': '', 'state': '', 'kind': '',
                              'beacon': '', 'branch': '', 'started': None, 'act': None, 'act_src': '', 'src': []})
peers_ok = False; PROCS = []
if peers_file and not peers_src.startswith(('falhou', 'ausente', 'desligada')):
    try:
        data = json.load(open(peers_file, encoding='utf-8'))
        if not isinstance(data, list): raise ValueError('não é lista')
        peers_ok = True
        PROCS = [x for x in data if isinstance(x, dict)]
        for x in data:
            sid = str(x.get('sessionId') or x.get('id') or '')
            if not sid: continue
            s = sess(sid); s['src'].append('peers')
            s['name'] = str(x.get('name') or ''); s['cwd'] = real(str(x.get('cwd') or ''))
            s['pid'] = x.get('pid'); s['status'] = str(x.get('status') or ''); s['state'] = str(x.get('state') or '')
            s['kind'] = str(x.get('kind') or '')
            if x.get('startedAt'): s['started'] = int(x['startedAt']) // (1000 if int(x['startedAt']) > 10**11 else 1)
    except Exception as e:
        gaps.append(f'lista de peers ilegível ({peers_file}): {e}'); peers_src = f'ilegível: {e}'
else:
    gaps.append(f'lista de peers NÃO MEDIDA ({peers_src}): na sessão, a ferramenta ListAgents a dá; salve-a em JSON e passe --peers <arquivo>')

# ── faróis: este repo e a família ───────────────────────────────────────────────────────
beacon_tool = os.path.join(here, 'session-beacon.sh')
repos = [main_checkout]
skips = {real(p) for p in skip.split('\n') if p}
if family == '1':
    mp = os.path.join(repo, 'docs/evolution/federation/members.yaml')
    try:
        for m in (yaml.safe_load(open(mp, encoding='utf-8')) or {}).get('members') or []:
            lp = (m or {}).get('local_path')
            if lp and os.path.isdir(lp) and real(lp) not in repos: repos.append(real(lp))
    except OSError:
        gaps.append('família não medida: sem docs/evolution/federation/members.yaml neste papel')
    except Exception as e:
        gaps.append(f'família não medida: members.yaml ilegível ({e})')
repos = [r for r in repos if r not in skips]
beacons_n, beacon_desc = 0, ''
if not os.path.isfile(beacon_tool):
    gaps.append(f'farol NÃO MEDIDO: {beacon_tool} ausente — sessão sem lista de peers fica invisível, não «zero»')
    beacon_desc = 'NÃO MEDIDO (session-beacon.sh ausente)'
else:
    nodir = []
    for rp in repos:
        bd = os.path.join(rp, '.claude/beacons')
        if not os.path.isdir(bd): nodir.append(rp); continue
        for bf in sorted(glob.glob(os.path.join(bd, '*.beacon'))):
            kv = {}
            for ln in open(bf, encoding='utf-8', errors='replace'):
                if ': ' in ln: k, v = ln.rstrip('\n').split(': ', 1); kv[k] = v
            sid = kv.get('session_id') or os.path.basename(bf)[:-7]
            r = subprocess.run(['bash', beacon_tool, 'verdict', bf], capture_output=True, text=True)
            ver = (r.stdout.strip() or 'ilegível') if r.returncode == 0 else f'erro rc {r.returncode}'
            s = sess(sid); s['src'].append('farol'); beacons_n += 1
            s['beacon'] = ver; s['branch'] = kv.get('branch', '')
            if not s['cwd']: s['cwd'] = real(kv.get('worktree') or rp)
            if kv.get('started_at', '').isdigit() and not s['started']: s['started'] = int(kv['started_at'])
            if kv.get('refreshed_at', '').isdigit():
                t = int(kv['refreshed_at'])
                if s['act'] is None or t > s['act']: s['act'], s['act_src'] = t, 'farol.refreshed_at'
    beacon_desc = f'{beacons_n} farol(óis) em {len(repos)} repo(s)' + (f' · {len(nodir)} sem diretório de faróis' if nodir else '')
    if len(nodir) == len(repos):
        gaps.append('farol NÃO MEDIDO: nenhum repo tem .claude/beacons/ (o hook do farol nunca rodou aqui)'); beacon_desc = 'NÃO MEDIDO (nenhum diretório de faróis)'

# ── atividade pelo transcript (só stat) ─────────────────────────────────────────────────
proj_ok = os.path.isdir(proj_dir)
if not proj_ok: gaps.append(f'transcripts não medidos: {proj_dir} ausente (a atividade cai só no farol)')
for s in S.values():
    if proj_ok:
        fs = glob.glob(os.path.join(glob.escape(proj_dir), '*', glob.escape(s['sid']) + '.jsonl'))
        if fs:
            t = int(max(os.path.getmtime(f) for f in fs))
            if s['act'] is None or t > s['act']: s['act'], s['act_src'] = t, 'transcript.mtime'

def pid_alive(pid):
    try: pid = int(pid)
    except (TypeError, ValueError): return None
    if pid <= 0: return False
    try: os.kill(pid, 0); return True
    except ProcessLookupError: return False
    except PermissionError: return True
    except OverflowError: return False

# ── decide-census: PRs, worktrees, sinais, perguntas, selo, checkpoints ─────────────────
dc = []
if dc_rc in ('0', 'override'):
    lines = open(dc_file, encoding='utf-8', errors='replace').read().splitlines()
    cols = lines[0].split('\t') if lines else []
    for ln in lines[1:]:
        v = ln.split('\t'); dc.append(dict(zip(cols, v + [''] * (len(cols) - len(v)))))
else:
    gaps.append(f'o que está em voo NÃO MEDIDO: decide-census.sh rc {dc_rc} — PRs, worktrees, sinais e perguntas ficam sem linha (não é zero)')
def age_sec(txt):
    m = re.search(r'há (\d+)(min|h)\b', txt or '')
    return None if not m else int(m.group(1)) * (60 if m.group(2) == 'min' else 3600)
prs, threads, signals, seals, checkpoints = [], [], [], [], []
for r in dc:
    k = r.get('kind')
    if k == 'merge':
        st = r.get('state', ''); m = re.search(r'checks (\d+) ok · (\d+) falha · (\d+) em curso', st)
        ci = 'não medido' if not m else ('RED' if int(m.group(2)) > 0 else ('pending' if int(m.group(3)) > 0 else ('green' if int(m.group(1)) > 0 else 'none')))
        prs.append({'ref': r['ref'], 'branch': r.get('origin', ''), 'title': r.get('label', ''), 'ci': ci, 'stopped': st.startswith('PARADO'),
                    'age': age_sec(st.split('sem movimento')[-1]) if 'sem movimento' in st else None, 'state': st, 'actor': r.get('actor', '')})
    elif k == 'thread':
        threads.append({'ref': r['ref'], 'path': r.get('origin', ''), 'label': r.get('label', ''), 'stopped': r.get('state', '').startswith('PARADO'),
                        'state': r.get('state', ''), 'actor': r.get('actor', '')})
    elif k == 'signal': signals.append(r)
    elif k == 'seal': seals.append(r)
    elif k == 'checkpoint': checkpoints.append(r)
    elif k == 'warn': warns.append('decide-census: ' + r.get('label', ''))
prs_measured = dc_rc in ('0', 'override') and not any(r.get('kind') == 'warn' and 'NÃO medidos' in r.get('label', '') and 'PRs' in r.get('label', '')
                                                      and not r.get('label', '').startswith('repo alheio') for r in dc)
signals_measured = dc_rc in ('0', 'override') and not any(r.get('kind') == 'warn' and 'sinais sem ack NÃO medidos' in r.get('label', '') for r in dc)

# ── perguntas reservadas (o registro do maestro-ask.sh: chave, dona, sessão, desde, prazo, pergunta) ──
asks = []; asks_measured = True
if os.path.isdir(ask_dir) and not os.access(ask_dir, os.R_OK | os.X_OK):
    asks_measured = False; gaps.append(f'perguntas reservadas NÃO MEDIDAS: {ask_dir} ilegível (não é «0»)')
elif os.path.isdir(ask_dir):
    for f in sorted(glob.glob(os.path.join(ask_dir, '*.ask'))):
        try: v = open(f, encoding='utf-8').read().rstrip('\n').split('\t')
        except OSError: warns.append(f'pergunta reservada ilegível (não contada): {f}'); continue
        if len(v) >= 5 and v[3].isdigit() and v[4].isdigit():
            asks.append({'key': v[0], 'owner': v[1], 'sid': v[2], 'since': int(v[3]), 'deadline': int(v[4]), 'live': int(v[4]) > now})
elif os.path.lexists(ask_dir):
    asks_measured = False; gaps.append(f'perguntas reservadas NÃO MEDIDAS: {ask_dir} não é diretório')
# o diretório que não existe é «ninguém reservou ainda»: o maestro-ask.sh o cria na 1ª reserva

# ── fila de dono declarado: nós open com owner: em todo grafo rastreado ─────────────────
_, ls = git('-c', 'core.quotePath=false', 'ls-files', '--', '*.kg.yaml')
owned = {}   # owner → [(grafo, id, impact)]
for g in ls.splitlines():
    if not g or 'fixtures' in g.split('/') or 'vendor' in g.split('/'): continue
    p = os.path.join(repo, g)
    try: txt = open(p, encoding='utf-8').read()
    except OSError: continue
    if 'owner:' not in txt: continue
    try: d = yaml.safe_load(txt) or {}
    except Exception: warns.append(f'grafo que não parseia (fila dele não lida): {g}'); continue
    for n in (d.get('nodes') or []):
        if isinstance(n, dict) and n.get('status') == 'open' and n.get('owner'):
            owned.setdefault(str(n['owner']), []).append((g, str(n.get('id')), n.get('impact') or 0))

# ── rótulo e parada por ordem (estado declarado pelo maestro, lido) ─────────────────────
def read_tsv(name):
    """→ (linhas, caminho, estado): estado 'ok' | 'absent' (não existe: ninguém declarou) | 'unreadable' (existe e não se lê).
    ILEGÍVEL NÃO É AUSENTE (achado do refutador, 2026-11-12): um parked.tsv com chmod 000, ou um diretório no lugar
    dele, virava «ninguém parado» e a sessão parada saía IDLE_WITH_QUEUE — exatamente o que a cláusula 7 proíbe."""
    p = os.path.join(state_dir, name); rows = []
    if not os.path.lexists(p): return None, p, 'absent'
    try:
        for ln in open(p, encoding='utf-8'):
            if ln.strip() and not ln.startswith('#'): rows.append(ln.rstrip('\n').split('\t'))
        return rows, p, 'ok'
    except (OSError, UnicodeDecodeError) as e: return None, p, f'unreadable ({type(e).__name__})'
own_rows, own_p, own_st = read_tsv('owners.tsv')
park_rows, park_p, park_st = read_tsv('parked.tsv')
grant_rows, grant_p, grant_st = read_tsv('grants.tsv')
park_unknown = park_st.startswith('unreadable')
if park_unknown:
    gaps.append(f'parada por ordem NÃO MEDIDA: {park_p} {park_st} — fail-closed: nenhuma sessão alcançável é classificada '
                'ociosa nem recebe oferta (classe PARK_UNMEASURED) até o arquivo voltar a ser legível')
if own_st.startswith('unreadable'):
    gaps.append(f'rótulos declarados NÃO lidos: {own_p} {own_st} — os rótulos caem nos derivados (nome, pasta)')
if grant_st.startswith('unreadable'):
    gaps.append(f'concessões de batuta-de-projeto NÃO LIDAS: {grant_p} {grant_st} — a batuta-de-projeto de cada sessão fica '
                'DESCONHECIDA (não «nenhuma»); o nível 0 segue, mas a concessão não é medida até o arquivo voltar a ser legível')
owners_map = {r[0]: r[1] for r in (own_rows or []) if len(r) >= 2}
def labels_of(s):
    for k in (s['sid'], s['name'], s['cwd']):
        if k and k in owners_map: return [owners_map[k]], 'owners.tsv'
    c = []
    for x in (s['name'], os.path.basename(s['cwd'] or '')):
        if x and x not in c: c.append(x)
        if x.startswith('onion-') and x[6:] not in c: c.append(x[6:])
    if role == 'source' and s['cwd'] and real(s['cwd']) == main_checkout: c.append('core')
    return c, 'derivado (nome, pasta, pasta sem onion-' + (', core=checkout da fonte' if role == 'source' else '') + ')'
def parked_of(s, labels):
    for r in (park_rows or []):
        key = r[0]; why = r[1] if len(r) > 1 else ''; until = (r[2] if len(r) > 2 else '').strip()
        if key not in (s['sid'], s['name'], *labels): continue
        if until in ('', '-'): return True, f'{why} (até nova ordem)', None
        try: ut = parse_since(until)
        except SystemExit: return True, f'{why} (prazo ilegível «{until}»: vale como parada)', None
        if ut > now: return True, f'{why} (até {iso(ut)})', None
        return False, '', f'parada de {key} venceu em {iso(ut)} ({why}): não vale mais'
    return False, '', None
def grant_of(s, labels):
    """A batuta-de-projeto DECLARADA da sessão (grants.tsv, escrita pelo core por delegação do maestro — NUNCA por este
    pulso: o nível 0 LÊ e reporta a concessão, não concede nem despacha). Casa a chave da linha contra o id, o nome, a
    pasta e os rótulos da sessão. → (camada, tem_batuta, por) | None (sessão sem concessão declarada)."""
    for r in (grant_rows or []):
        key = r[0].strip()
        if not key: continue   # linha sem chave não casa ninguém (uma chave vazia casaria a pasta de um cwd com barra final)
        if key not in (s['sid'], s['name'], os.path.basename(s['cwd'] or ''), *labels): continue
        camada = r[1] if len(r) > 1 else '?'
        # fail-closed: a coluna da concessão AUSENTE (linha truncada) não concede — só «sim» escrito concede
        tem = (r[2].strip().lower() if len(r) > 2 else '') in ('sim', 'yes', 'true', '1')
        por = r[3] if len(r) > 3 else '?'
        return (camada, tem, por)
    return None

# PR ↔ sessão: branch do farol, ou a worktree da branch é o cwd da sessão
_, wtl = git('worktree', 'list', '--porcelain')
wt_branch, cur = {}, None
for ln in wtl.splitlines():
    if ln.startswith('worktree '): cur = real(ln[9:])
    elif ln.startswith('branch refs/heads/') and cur: wt_branch[ln[18:]] = cur

claimed_owner = set(); claimed_pr = set()
for s in S.values():
    labels, lab_src = labels_of(s); s['labels'], s['lab_src'] = labels, lab_src
    s['grant'] = grant_of(s, labels)
    q = []
    for l in labels:
        if l == 'maestro': continue
        for (g, nid, imp) in owned.get(l, []): q.append(f'nó {nid} ({os.path.basename(g)}, owner {l})'); claimed_owner.add(l)
    for a in asks:
        if a['sid'] == s['sid'] and a['live']: q.append(f'pergunta reservada {a["key"]}')
    for pr in prs:
        if (s['branch'] and pr['branch'] == s['branch'] and s['branch'] not in ('main', 'master', 'develop')) or \
           (pr['branch'] in wt_branch and s['cwd'] and wt_branch[pr['branch']] == s['cwd'] and s['cwd'] != main_checkout):
            q.append(f'{pr["ref"]} (CI {pr["ci"]})'); claimed_pr.add(pr['ref'])
    s['queue'] = q
    pk, why, warn = parked_of(s, labels)
    if warn: warns.append(warn)
    alive = pid_alive(s['pid']) if s['pid'] is not None else None
    idle_for = None if s['act'] is None else now - s['act']
    s['idle_for'] = idle_for
    if pk: cls, note = 'PARKED', why
    elif park_unknown and not (s['pid'] is not None and alive is False) and not ('peers' not in s['src'] and s['beacon'] in ('orphan', 'stale')):
        cls, note = 'PARK_UNMEASURED', f'estado de parada não medido ({park_st}): sem oferta'
    elif s['pid'] is not None and alive is False: cls, note = 'UNREACHABLE', f'pid {s["pid"]} morto'
    elif 'peers' in s['src'] and s['pid'] is None and s['kind'] == 'background' and s['state'] != 'working':
        cls, note = 'UNREACHABLE', f'sessão de fundo sem processo (state {s["state"] or "?"})'
    elif 'peers' not in s['src'] and s['beacon'] in ('orphan', 'stale'): cls, note = 'UNREACHABLE', f'farol {s["beacon"]}'
    elif 'peers' not in s['src'] and peers_ok: cls, note = 'UNREACHABLE', f'farol {s["beacon"]}, mas fora da lista de peers do harness (que foi lida)'
    elif s['status'] == 'busy': cls, note = 'ACTIVE', 'harness: busy'
    elif idle_for is not None and idle_for < idle_s: cls, note = 'ACTIVE', f'atividade há {mins(idle_for)}min ({s["act_src"]})'
    else:
        cls = 'IDLE_WITH_QUEUE' if q else 'IDLE_NO_QUEUE'
        note = (f'sem atividade há {mins(idle_for)}min ({s["act_src"]})' if idle_for is not None else 'ociosa pelo harness; duração NÃO medida')
        if s['state'] == 'blocked' or s['status'] == 'waiting': note += ' · espera o maestro'
    s['cls'], s['note'] = cls, note

# farol STALE sem peer é rastro velho (fora do TTL do farol), não sessão: sai da tabela e da contagem, e vira uma linha
stale_traces = sorted(s['sid'] for s in S.values() if 'peers' not in s['src'] and s['beacon'] == 'stale' and s['cls'] == 'UNREACHABLE')
for sid in stale_traces: del S[sid]
# ── subagentes das sessões vivas: o SINTOMA do agente parado num tool_use sem resultado (SAC-421) ──
# Medido em 2026-11-12: o transcript do subagente mora em <projects>/<projeto>/<sessionId>/subagents/agent-<id>.jsonl
# (com <id>.meta.json ao lado: agentType, description); o <id>.output em /tmp/claude-<uid>/<projeto>/<sessão>/tasks/ é
# symlink para ele, então não é segunda fonte. Lê-se o conteúdo SÓ do subagente (as entradas user/assistant), nunca o da sessão.
# redação por LISTA (limite declarado): o que não está aqui passa. Cobre chave de API, Bearer, x-api-key, var=valor de
# nome com token/secret/password/_key, --password <x>, -p<x> (mysql) e -u <u>:<x> (curl).
SECRET_RE = re.compile(r'(sk-[A-Za-z0-9_\-]{6,}|gh[pousr]_[A-Za-z0-9]{6,}|github_pat_[A-Za-z0-9_]{6,}|(?i:bearer)\s+[^\s"\']+'
                       r'|(?i:x-api-key):\s*[^\s"\']+|(?i:[a-z0-9_]*(?:token|secret|passw(?:or)?d|api_?key|_key)[a-z0-9_]*)=[^\s&"\']+'
                       r'|--password[=\s]+[^\s"\']+|(?<=\s)-p[^\s\-"\']{3,}|(?<=\s)-u\s+[^\s:"\']+:[^\s"\']+)')
def redact(s):
    """Antes de exibir: segredo vira [REDACTED] e a home de qualquer usuário vira ~ (a saída é colada em chat e PR)."""
    s = SECRET_RE.sub('[REDACTED]', s)
    return re.sub(r'/home/[^/\s"\']+|/root(?=/|\b)', '~', s)
def agent_cmd(tu):
    inp = tu.get('input') if isinstance(tu.get('input'), dict) else {}
    arg = inp.get('command') or inp.get('file_path') or inp.get('pattern') or inp.get('url') or inp.get('prompt') or \
          next((v for v in inp.values() if isinstance(v, str)), '')
    return redact(re.sub(r'\s+', ' ', f'{tu.get("name") or "?"}: {arg}').strip())[:120]
def md_code(s):
    """Crase no comando quebra o `…` do markdown: a cerca cresce (CommonMark) em vez de escapar com barra."""
    if not s: return ''
    f = '`' * (max((len(m) for m in re.findall(r'`+', s)), default=0) + 1)
    return f'{f} {s} {f}' if len(f) > 1 else f'`{s}`'
# ferramentas cujo resultado ENCERRA o agente: o subagente entrega por SubagentHandback; o agente da ferramenta Workflow
# entrega por StructuredOutput (medido em 2026-11-12: 4744 dos 4851 transcripts de workflow da máquina terminam assim)
FINAL_TOOLS = ('SubagentHandback', 'StructuredOutput')
def agent_state(path):
    """→ (classe, nota, comando pendente). Classe pelo FIM do transcript, nunca pela prosa.
    Pendente = tool_use cujo id não teve tool_result. Só o tool_result do MESMO id fecha, nunca uma linha user de texto:
    a cutucada do líder («The coordinator sent a message while you were working») chega no meio da ferramenta e não a
    resolve (achado do refutador, 2026-11-12). Nada ABANDONA uma pendência: depois da cutucada o harness roda dois fluxos
    do assistente ao mesmo tempo, e em 12 de 14 «abandonos» medidos o resultado chegou depois (re-revisão, 2026-11-12).
    Pendência aberta nunca é DONE, nem com texto final; o abandono legítimo fica STALLED, falha ruidosa."""
    pend, last, n, handback, last_res, last_ts = {}, None, 0, '', '', None
    try:
        with open(path, encoding='utf-8') as fh:
            for ln in fh:
                if not ln.strip(): continue
                try: d = json.loads(ln)
                except ValueError: continue   # linha cortada (escrita em curso): não decide a classe
                if not isinstance(d, dict) or d.get('type') not in ('user', 'assistant'): continue
                msg = d.get('message') or {}; c = msg.get('content'); n += 1; last = d; last_ts = d.get('timestamp') or last_ts
                blocks = c if isinstance(c, list) else [{'type': 'text', 'text': c}]
                if d['type'] == 'assistant':
                    mid = msg.get('id')
                    for b in blocks:
                        if isinstance(b, dict) and b.get('type') == 'tool_use' and b.get('id'): pend[b['id']] = (mid, b)
                    handback = ''   # nova mensagem do assistente depois da entrega: o fim deixou de ser o fim
                else:
                    for b in blocks:
                        if not (isinstance(b, dict) and b.get('type') == 'tool_result'): continue
                        hit = pend.pop(b.get('tool_use_id'), None)
                        rc = b.get('content'); last_res = rc if isinstance(rc, str) else json.dumps(rc, ensure_ascii=False)
                        # entrega com is_error não é fim: o agente tenta de novo (65 casos reais, refutador 2026-11-12)
                        if hit and hit[1].get('name') in FINAL_TOOLS and not b.get('is_error'): handback = hit[1]['name']
    except (OSError, UnicodeDecodeError) as e:
        return 'AGENT_UNMEASURED', f'transcript ilegível ({type(e).__name__}): NÃO medido', ''
    if not n: return 'AGENT_UNMEASURED', 'transcript sem entrada user/assistant legível: NÃO medido', ''
    # a idade é a da última entrada user/assistant (o carimbo dela), não o mtime: a linha `attachment` que o harness grava
    # depois do fim não é atividade (medido: 66 agentes de Workflow terminam em StructuredOutput + attachment). Sem carimbo, mtime.
    age = None
    if last_ts:
        try: age = now - int(datetime.datetime.fromisoformat(str(last_ts).replace('Z', '+00:00')).timestamp())
        except ValueError: age = None
    if age is None or age < 0: age = now - int(os.path.getmtime(path))   # carimbo no futuro não é idade: cai no mtime
    if pend:
        pl = [b for _, b in pend.values()]
        cmd = agent_cmd(pl[0]) + (f' (+{len(pl) - 1} pendente(s))' if len(pl) > 1 else '')   # o 1º da leva é o que segura os outros
        if age > stall_s: return 'AGENT_STALLED', f'tool_use sem tool_result há {mins(age)}min', cmd
        return 'AGENT_RUNNING', f'tool_use em curso há {mins(age)}min', cmd
    if handback: return 'AGENT_DONE', f'relatório entregue ({handback}) há {mins(age)}min', ''
    c = (last.get('message') or {}).get('content')
    blocks = c if isinstance(c, list) else [{'type': 'text', 'text': c}]
    txt = ' '.join(str(b.get('text') or '') for b in blocks if isinstance(b, dict) and b.get('type') == 'text')
    # o bloco de texto do meio de um turno tem stop_reason tool_use (blocos gravados um por linha): não é o fim
    if last['type'] == 'assistant' and txt.strip() and (last.get('message') or {}).get('stop_reason') != 'tool_use': return 'AGENT_DONE', f'texto final do assistente há {mins(age)}min', ''
    if last['type'] == 'user' and txt.startswith('[Request interrupted'): return 'AGENT_DONE', f'interrompido pelo humano há {mins(age)}min', ''
    if age > stall_s:   # sem pendência, sem fim e sem escrita: não é «rodando» (achado do refutador: RUNNING eterno)
        k137 = ' · último tool_result: Exit code 137 (processo morto)' if 'Exit code 137' in last_res else ''
        return 'AGENT_SILENT', f'sem pendência, sem texto final e sem escrita há {mins(age)}min{k137}', ''
    return 'AGENT_RUNNING', f'última escrita há {mins(age)}min, sem tool_use pendente', ''
AG = []   # subagentes das sessões vivas (não UNREACHABLE) e desta sessão
agents_measured = proj_ok and os.access(proj_dir, os.R_OK | os.X_OK)
live_sids = [s['sid'] for s in S.values() if s['cls'] != 'UNREACHABLE']
if self_sid and self_sid not in live_sids: live_sids.append(self_sid)
if agents_measured:
    for sid in live_sids:
        base = os.path.join(glob.escape(proj_dir), '*', glob.escape(sid), 'subagents')
        # os agentes da ferramenta Workflow moram um nível abaixo: subagents/workflows/<run>/agent-<id>.jsonl
        for f in sorted(glob.glob(os.path.join(base, 'agent-*.jsonl')) + glob.glob(os.path.join(base, 'workflows', '*', 'agent-*.jsonl'))):
            aid = os.path.basename(f)[len('agent-'):-len('.jsonl')]; desc = ''
            if os.path.basename(os.path.dirname(os.path.dirname(f))) == 'workflows': aid = os.path.basename(os.path.dirname(f)) + '/' + aid
            try: desc = str(json.load(open(f[:-len('.jsonl')] + '.meta.json', encoding='utf-8')).get('description') or '')
            except (OSError, ValueError, AttributeError): pass
            cls_a, note_a, cmd_a = agent_state(f)
            AG.append({'sid': sid, 'aid': aid, 'cls': cls_a, 'note': note_a, 'cmd': cmd_a, 'desc': redact(desc),
                       'rel': f[f.rindex('/subagents/') + 1:]})
else: gaps.append(f'subagentes NÃO MEDIDOS: {proj_dir} ' + ('ilegível' if proj_ok else 'ausente') + ' (não é «nenhum parado»)')
AORD = {c: i for i, c in enumerate(('AGENT_STALLED', 'AGENT_UNMEASURED', 'AGENT_SILENT', 'AGENT_RUNNING', 'AGENT_DONE'))}
AG.sort(key=lambda a: (AORD[a['cls']], a['sid'], a['aid']))
acnt = {c: sum(1 for a in AG if a['cls'] == c) for c in AORD}
AG_ALERT = ('AGENT_STALLED', 'AGENT_SILENT', 'AGENT_UNMEASURED')   # só estes entram no sha: RUNNING e DONE mudam toda batida

# ── peças: a sessão dona de cada peça estratégica (D_BACKBONE_OWNER_1112, cláusula 8 da doutrina) ──────────
# A peça é o membro com `piece: true` no members.yaml (o `kind:` segue sendo a NATUREZA, validada por enum). O dono se
# resolve em ORDEM FIXA, parando na 1ª que responde (a forma do Spotify Portal AI Explorer): (1) `owner_session` do
# members.yaml; (2) owners.tsv, a linha cujo rótulo é o id da peça (a chave é o NOME da sessão); (3) a sessão do core,
# último recurso. Casa pelo NOME da sessão, nunca pelo ref/sessionId: a retomada troca o ref e mantém o nome.
# Peça sem dono é AVISO, nunca bloqueio, e cada aviso traz o card de arranque como TEXTO: o pulso nunca abre sessão.
def card_of(lp, name):
    import shlex
    where = re.sub(r'^/home/[^/]+|^/root(?=/|$)', '~', lp) if isinstance(lp, str) and lp.startswith('/') else '<local_path>'
    return f'cd {where} && claude --name {shlex.quote(name)}'
PIECES = []; pieces_src = ''
try:
    _members = (yaml.safe_load(open(os.path.join(repo, 'docs/evolution/federation/members.yaml'), encoding='utf-8')) or {}).get('members') or []
    pieces_src = 'members.yaml'
except OSError: _members, pieces_src = [], 'sem members.yaml neste papel'
except Exception as e:
    _members, pieces_src = [], 'NÃO MEDIDAS'; gaps.append(f'peças NÃO MEDIDAS: members.yaml ilegível ({e})')
_live = [s for s in S.values() if s['cls'] != 'UNREACHABLE']
# O 1º degrau é o LEITOR ÚNICO de posse (D_SESSION_ONE_OWNERSHIP_REGISTRY_BY_NAME_1120, 2026-11-20):
# .claude/utils/orchestration/ownership.sh, o mesmo que o ops/session-open.sh lê, sobre o members.yaml deste papel (e a
# lista privada de sessões donas). O pulso não relê a owner_session por conta própria: leitor ausente ou falho deixa o
# 1º degrau NÃO MEDIDO (a peça sai PIECE_UNMEASURED), nunca cai calado no owners.tsv ou no core.
own_reader = os.environ.get('BATON_OWNERSHIP') or os.path.normpath(os.path.join(here, '..', 'utils', 'orchestration', 'ownership.sh'))
own_map, own_err = None, ''
if _members:
    try:
        _r = subprocess.run(['bash', own_reader, 'list', '--members', os.path.join(repo, 'docs/evolution/federation/members.yaml')],
                            capture_output=True, text=True, timeout=30)
        if _r.returncode != 0: raise RuntimeError(f'rc {_r.returncode}: {_r.stderr.strip()[:160]}')
        own_map = {}
        for ln in _r.stdout.splitlines():
            f = ln.split('\t')
            if len(f) >= 4 and f[0]: own_map[f[0]] = (f[1], 'lista privada' if f[3] == 'privada' else f[3])
    except Exception as e:
        own_err = f'{type(e).__name__}: {e}'
        gaps.append(f'leitor de posse NÃO lido ({own_reader}: {own_err}): o dono pela owner_session fica NÃO MEDIDO')
for m in _members:
    if not isinstance(m, dict) or m.get('piece') is not True: continue
    pc = {'id': str(m.get('id')), 'lp': m.get('local_path'), 'sponsor': str(m.get('sponsor') or '')}
    lp_r = real(pc['lp']) if isinstance(pc['lp'], str) and pc['lp'].startswith('/') else ''
    hit = next((r[0] for r in (own_rows or []) if len(r) >= 2 and r[1] == pc['id']), None)
    if own_map is None:
        pc['owner'], pc['osrc'] = '?', 'leitor de posse falhou'
    elif pc['id'] in own_map: pc['owner'], pc['osrc'] = own_map[pc['id']]
    elif hit: pc['owner'], pc['osrc'] = hit, 'owners.tsv'
    else: pc['owner'], pc['osrc'] = 'core', 'core (último recurso)'
    if pc['osrc'].startswith('core'):   # o core se reconhece pelo checkout da fonte, como no rótulo derivado
        match = [s for s in _live if 'core' in s['labels']]
    else: match = [s for s in _live if s['name'] == pc['owner']]
    in_repo = [s for s in _live if lp_r and s['cwd'] and (real(s['cwd']) == lp_r or real(s['cwd']).startswith(lp_r + '/'))]
    pc['card'] = ''
    if not peers_ok:
        pc['cls'], pc['note'] = 'PIECE_UNMEASURED', 'sem a lista de peers não há nome de sessão a casar: NÃO medido, nunca «sem dono»'
    elif own_map is None:   # o 1º degrau não se leu: cair no owners.tsv ou no core seria palpite
        pc['cls'], pc['note'] = 'PIECE_UNMEASURED', f'o leitor de posse falhou ({own_err[:120]}): o 1º degrau NÃO medido, nunca «sem dono»'
    elif pc['osrc'].startswith('core') and own_st.startswith('unreadable'):   # o 2º degrau não se leu: cair no core seria palpite
        pc['cls'], pc['note'] = 'PIECE_UNMEASURED', f'sem owner_session e o owners.tsv {own_st}: a ordem parou no 2º degrau, NÃO medido'
    elif match:
        pc['cls'], pc['note'] = 'PIECE_OWNED', 'dono vivo: ' + ', '.join(f'{s["name"] or "core"} ({s["cls"]})' for s in match)
    elif in_repo:
        pc['cls'] = 'PIECE_OWNER_NAME_MISMATCH'
        pc['note'] = 'há sessão viva no repo da peça com outro nome: ' + ', '.join(f'«{s["name"] or "sem nome"}» ({s["cls"]})' for s in in_repo) + \
                     f'; o dono declarado é «{pc["owner"]}» (retomada troca ref e nome: não é dono ausente)'
        pc['card'] = f'na sessão viva, /rename {pc["owner"]}; ou abra: {card_of(pc["lp"], pc["owner"])}'
    else:
        pc['cls'], pc['note'] = 'PIECE_UNOWNED', f'nenhuma sessão viva com o nome «{pc["owner"]}»'
        pc['card'] = card_of(pc['lp'], pc['owner'] if not pc['osrc'].startswith('core') else pc['id'])
    if pc['osrc'].startswith('core') and pc['cls'] != 'PIECE_UNMEASURED': warns.append(f'peça {pc["id"]} sem owner_session nem linha no owners.tsv: o dono caiu no core (último recurso)')
    PIECES.append(pc)
PORD = {c: i for i, c in enumerate(('PIECE_UNOWNED', 'PIECE_OWNER_NAME_MISMATCH', 'PIECE_UNMEASURED', 'PIECE_OWNED'))}
PIECES.sort(key=lambda p: (PORD[p['cls']], p['id']))
PIECE_ALERT = ('PIECE_UNOWNED', 'PIECE_OWNER_NAME_MISMATCH', 'PIECE_UNMEASURED')
pc_line = ('peças: ' + ' · '.join(f'{c} {sum(1 for p in PIECES if p["cls"] == c)}' for c in PORD)) if PIECES else f'peças: nenhuma declarada ({pieces_src})'

# ── higiene das sessões (D_SESSION_HYGIENE_TMUX_WORKTREE_1114, cláusula 9 da doutrina) ──────────────────
# Por PROCESSO dos peers (o mesmo sessionId aparece em dois pids quando a sessão foi retomada em dois terminais: S funde
# por sid, aqui não). Só processo interativo e vivo. Aviso, nunca bloqueio. Lê de <proc> (BATON_PROC, padrão /proc):
#   stat    o estado (3º campo DEPOIS do último ')': o comm pode ter espaço e parêntese, «tmux: server» quebra o awk) e o ppid;
#   comm    o nome, para subir a árvore e para conferir que o pid é `claude` ANTES de abrir o environ;
#   environ SÓ do processo claude, e dele SÓ a chave TMUX (presença; o valor e o resto nunca saem: pode haver segredo).
#   SESSION_STOPPED       estado T|t: a sessão suspensa (Ctrl+Z, SIGSTOP) é invisível ao harness, que a lista como idle.
#   SESSION_NOT_IN_TMUX   sem TMUX no environ e sem ancestral tmux: fora do tmux não há como reanexar nem sobreviver a
#                         reboot ou ao fim do processo do terminal (ssh puro cai com a conexão; mosh sobrevive à queda de rede, não a isto).
#   SESSION_SAME_CHECKOUT duas interativas vivas no mesmo checkout git (topo git do cwd, não a worktree): a 2ª vai de --worktree.
#                         SÓ dentro de repo git: fora dele o remédio --worktree não existe, então não se classifica. O rev-parse por
#                         cwd tem teto curto (BATON_TOPLEVEL_TIMEOUT_S, padrão 5s); estouro vira HYGIENE_UNMEASURED, nunca «mesmo checkout» por palpite.
#   SESSION_CAP           SESSÕES interativas distintas (dedupe por sid) acima de --max-interactive (padrão 10; o teto prático é 10 sessões + 5 agentes; D_SESSION_CAP_10_PLUS_5_AGENTS_1119, 2026-11-19).
#   Ilegível nunca é limpo: estado ou árvore que não se leem saem como lacuna nomeada (HYGIENE_UNMEASURED), não «em tmux».
proc_root = os.environ.get('BATON_PROC') or '/proc'
try: toplevel_timeout = float(os.environ.get('BATON_TOPLEVEL_TIMEOUT_S') or 5)
except ValueError: toplevel_timeout = 5.0
def proc_stat(pid):
    """→ (estado, ppid) ou None. O comm entre parênteses pode ter espaço e ')': corta no ÚLTIMO ')'."""
    try: raw = open(os.path.join(proc_root, str(pid), 'stat'), encoding='utf-8', errors='replace').read()
    except OSError: return None
    i = raw.rfind(')'); f = raw[i + 2:].split() if i >= 0 else []
    return (f[0], int(f[1])) if len(f) >= 2 and f[1].isdigit() else None
def proc_comm(pid):
    try: return open(os.path.join(proc_root, str(pid), 'comm'), encoding='utf-8', errors='replace').read().strip()
    except OSError: return None
def has_tmux_key(pid):
    """True|False|None (não lido). SÓ a chave: o valor e as outras variáveis nunca entram em memória além do split."""
    try: raw = open(os.path.join(proc_root, str(pid), 'environ'), 'rb').read()
    except OSError: return None
    return any(e.startswith(b'TMUX=') for e in raw.split(b'\0'))
def tilde(x): return re.sub(r'^/home/[^/]+|^/root(?=/|$)', '~', x or '')
def tmux_name(x): return re.sub(r'[^A-Za-z0-9_-]+', '-', x or 'sessao').strip('-') or 'sessao'
home_dir = real(os.environ.get('HOME') or os.path.expanduser('~'))
def opener_name(cwd):
    """O abridor ops/session-open.sh (core-only) resolve ~/<nome> e EXIGE repo: a cura por ele só vale quando o cwd é a
    RAIZ de um repo em ~/<basename> — então o nome a imprimir é esse basename, nunca o `name` do harness (que pode ser
    vazio → «sessao» rc 2) nem o de uma worktree (cujo cwd não fica em ~/<nome>, abriria o checkout principal). Fora
    disso → None, e o pulso imprime só a forma `tmux new -s`. Retorna o basename do repo, ou None."""
    if not cwd or os.path.dirname(cwd) != home_dir: return None
    rc_t, top = git('rev-parse', '--show-toplevel', cwd=cwd, timeout=toplevel_timeout)
    return os.path.basename(cwd) if rc_t == 0 and top and real(top) == cwd else None
HY, hy_gaps = [], []
inter = []
for x in PROCS:
    pid = x.get('pid')
    # vivo = existe <proc>/<pid>/stat (a mesma fonte que se lê a seguir; com o /proc real é o kill -0 sem sinal)
    if x.get('kind') != 'interactive' or not str(pid or '').isdigit() or not os.path.exists(os.path.join(proc_root, str(pid), 'stat')): continue
    inter.append({'pid': int(pid), 'sid': str(x.get('sessionId') or ''), 'name': str(x.get('name') or ''), 'cwd': real(str(x.get('cwd') or ''))})
if peers_ok:
    for p in inter:
        tag = f'{p["name"] or p["sid"][:8]} (pid {p["pid"]})'
        st = proc_stat(p['pid'])
        if st is None: hy_gaps.append(f'{tag}: {proc_root}/{p["pid"]}/stat ilegível, estado e árvore NÃO medidos'); continue
        if st[0] in ('T', 't'):
            HY.append(('SESSION_STOPPED', p, f'{tag} está suspensa (estado {st[0]}): o harness a lista, mas ela não anda',
                       f'kill -CONT {p["pid"]}  (ou `fg` no shell que a suspendeu)'))
        comm = proc_comm(p['pid'])
        key = has_tmux_key(p['pid']) if comm == 'claude' else None   # environ só de processo claude conferido
        chain, q, seen_tmux, broken = [], st[1], False, False
        for _ in range(32):
            if q in (0, 1): break
            c = proc_comm(q); nx = proc_stat(q)
            if c is None or nx is None: broken = True; break
            chain.append(c)
            if c.startswith('tmux'): seen_tmux = True; break
            q = nx[1]
        if key or seen_tmux: continue
        if key is None and broken:
            hy_gaps.append(f'{tag}: sem chave TMUX legível e árvore cortada em {"→".join(chain) or "?"}: tmux NÃO medido'); continue
        _repo = opener_name(p['cwd'])
        _tmux_form = f'tmux new -s {tmux_name(p["name"])} -c {tilde(p["cwd"])} \'claude --resume {p["sid"]}\''
        if _repo:
            _cura = f'na sessão, /exit; depois: bash ops/session-open.sh {_repo} --resume {p["sid"]} (ou, sem o abridor: {_tmux_form})'  # (core-only): cita ops/session-open.sh (REGRA 100); só quando o cwd é raiz de repo em ~/<nome>, com a forma tmux como alternativa
        else:
            _cura = f'na sessão, /exit; depois: {_tmux_form}'
        HY.append(('SESSION_NOT_IN_TMUX', p, f'{tag} roda fora do tmux (sem TMUX no ambiente; árvore {"→".join(chain) or "—"}): sem reanexar e sem sobreviver a reboot ou ao fim do processo do terminal (ssh puro cai com a conexão; mosh não)',
                   _cura))
    tops = {}
    for p in inter:
        git_top = None
        if p['cwd'] and os.path.isdir(p['cwd']):
            rc_t, top = git('rev-parse', '--show-toplevel', cwd=p['cwd'], timeout=toplevel_timeout)
            if rc_t is None:   # o rev-parse pendurou (cwd em mount travado): LACUNA nomeada, nunca «mesmo checkout» por palpite
                hy_gaps.append(f'{p["name"] or p["sid"][:8]} (pid {p["pid"]}): git rev-parse --show-toplevel em {tilde(p["cwd"])} '
                               f'pendurou (>{toplevel_timeout:g}s, mount travado?): checkout NÃO medido'); continue
            if rc_t == 0 and top: git_top = real(top)
        if git_top is None: continue   # fora de repo git (ou sem cwd): o remédio --worktree não se aplica, não é «mesmo checkout»
        tops.setdefault(git_top, []).append(p)
    for top, ps in sorted(tops.items()):
        if len(ps) < 2 or not top: continue
        same_sid = len({p['sid'] for p in ps}) < len(ps)
        who = ', '.join(f'{p["name"] or p["sid"][:8]} (pid {p["pid"]})' for p in ps)
        for p in ps[1:]:
            HY.append(('SESSION_SAME_CHECKOUT', p, f'{len(ps)} sessões interativas no mesmo checkout {os.path.basename(top)}: {who}'
                       + (' · o mesmo sessionId em dois processos (retomada em dois terminais)' if same_sid else ''),
                       (f'a mesma sessão em dois processos: feche o terminal de um deles (pids {", ".join(str(q["pid"]) for q in ps)}); '
                        f'trabalho paralelo abre com: cd {tilde(top)} && claude --worktree {tmux_name(p["name"])}-2') if same_sid else
                       f'feche a 2ª e reabra isolada: cd {tilde(top)} && claude --worktree {tmux_name(p["name"])}-2'))
    # o TETO conta SESSÕES distintas, não processos: a sessão retomada em dois terminais (mesmo sid, dois pids) conta uma
    # vez (a contagem por processo fica onde é intencional: SESSION_SAME_CHECKOUT). Sid vazio não deduplica (conta por processo).
    inter_sessions = len({p['sid'] for p in inter if p['sid']}) + sum(1 for p in inter if not p['sid'])
    if inter_sessions > int(max_inter):
        proc_note = f' ({len(inter)} processo(s))' if len(inter) != inter_sessions else ''
        HY.append(('SESSION_CAP', None, f'{inter_sessions} sessão(ões) interativa(s) distinta(s){proc_note} acima do teto de {max_inter} (teto prático: 10 sessões + 5 agentes)',
                   'feche ou estacione (parked.tsv) a ociosa sem fila; agente em vez de sessão para trabalho curto'))
else: hy_gaps.append('lista de peers não lida: sem pid não há processo a medir')
HORD = {c: i for i, c in enumerate(('SESSION_STOPPED', 'SESSION_NOT_IN_TMUX', 'SESSION_SAME_CHECKOUT', 'SESSION_CAP'))}
HY.sort(key=lambda h: (HORD[h[0]], h[1]['pid'] if h[1] else 0))
for g in hy_gaps: gaps.append(f'higiene das sessões NÃO MEDIDA (HYGIENE_UNMEASURED): {g}')
hy_line = f'higiene: {len(inter)} interativa(s) viva(s) · ' + (' · '.join(f'{c} {sum(1 for h in HY if h[0] == c)}' for c in HORD) if peers_ok else 'NÃO MEDIDA')

orphan_queue = {o: v for o, v in owned.items() if o != 'maestro' and o not in claimed_owner}
CLASSES = ('ACTIVE', 'IDLE_WITH_QUEUE', 'IDLE_NO_QUEUE', 'PARKED', 'UNREACHABLE', 'PARK_UNMEASURED')
cnt = {c: sum(1 for s in S.values() if s['cls'] == c) for c in CLASSES}
sessions_measured = peers_ok or beacons_n > 0 or (os.path.isfile(beacon_tool) and 'NÃO MEDIDO' not in beacon_desc)
ORD = {c: i for i, c in enumerate(('IDLE_WITH_QUEUE', 'IDLE_NO_QUEUE', 'ACTIVE', 'PARK_UNMEASURED', 'PARKED', 'UNREACHABLE'))}
sess_sorted = sorted(S.values(), key=lambda s: (ORD[s['cls']], s['cwd'], s['name'], s['sid']))

# ── o que mudou: eventos datados depois de --since, e o sha do estado ───────────────────
events = []
if since_ts is not None:
    for s in sess_sorted:
        tag = s['name'] or s['sid'][:8]
        if s['started'] and s['started'] > since_ts: events.append(f'sessão nova: {tag} ({iso(s["started"])})')
        if s['cls'].startswith('IDLE') and s['act'] is not None and since_ts < s['act'] + idle_s <= now:
            events.append(f'ficou ociosa: {tag} → {s["cls"]} (desde {iso(s["act"] + idle_s)})')
    for a in asks:
        if a['since'] > since_ts: events.append(f'pergunta nova: {a["key"]} ({a["owner"]})')
    for pr in prs:
        if pr['age'] is not None and now - pr['age'] > since_ts: events.append(f'{pr["ref"]} se moveu (CI {pr["ci"]})')
state = {'s': sorted((s['sid'], s['cls'], len(s['queue'])) for s in S.values()),
         'pr': sorted((p['ref'], p['ci'], p['stopped']) for p in prs), 'wt': sorted((t['ref'], t['path'], t['stopped']) for t in threads),
         'sig': sorted(f"{r.get('ref')}|{r.get('label')}" for r in signals), 'ask': sorted(a['key'] for a in asks if a['live']), 'busy': 'OCUPADO' in load_line,
         'measured': [prs_measured, signals_measured, asks_measured, park_st],
         'cp': len(checkpoints), 'gaps': sorted(gaps),
         'ag': sorted((a['sid'], a['aid'], a['cls']) for a in AG if a['cls'] in AG_ALERT), 'ag_n': [acnt[c] for c in AG_ALERT],
         'pc': sorted((p['id'], p['cls'], p['owner']) for p in PIECES),
         'hy': sorted((h[0], h[1]['sid'] if h[1] else '', h[1]['name'] if h[1] else '') for h in HY)}
sha = hashlib.sha256(json.dumps(state, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:16]
# «sem mudança» só quando o sha BATE (achado do refutador, 2026-11-12): com só --since, uma sessão que caiu ou um PR que
# ficou vermelho sem evento datado passava calado. Sem --last-sha não há base, e a batida fala.
changed = (not last_sha) or last_sha != sha or bool(events)

def tsvc(x): return str(x).replace('\t', ' ').replace('\n', ' ')
if fmt == '--tsv':
    print('kind\tref\tclass\trepo\tidle_min\tqueue\tsource\tdetail')
    for s in sess_sorted:
        print('\t'.join(tsvc(x) for x in ('session', s['sid'], s['cls'], os.path.basename(s['cwd']), '' if s['idle_for'] is None else mins(s['idle_for']),
              len(s['queue']), '+'.join(s['src']), f'{s["name"]} · {s["note"]} · rótulo {"/".join(s["labels"]) or "—"}' + (f' · batuta-de-projeto: {"sim" if s["grant"][1] else "não"} ({s["grant"][0]}, por {s["grant"][2]})' if s.get('grant') else '') + f' · fila: {"; ".join(s["queue"]) or "—"}')))
    for o, v in sorted(orphan_queue.items()): print(f'orphan_queue\t{tsvc(o)}\t-\t-\t\t{len(v)}\tgrafo\t' + tsvc('; '.join(n for _, n, _ in v)))
    for p in prs: print('\t'.join(tsvc(x) for x in ('pr', p['ref'], 'CI_' + p['ci'].upper().replace(' ', '_'), p['branch'], '' if p['age'] is None else mins(p['age']), '', 'decide-census', p['state'])))
    for t in threads: print('\t'.join(tsvc(x) for x in ('thread', t['ref'], 'STOPPED' if t['stopped'] else 'MOVING', t['path'], '', '', 'decide-census', f'{t["label"]} · {t["state"]} · {t["actor"]}')))
    for a in AG: print('\t'.join(tsvc(x) for x in ('agent', a['aid'], a['cls'], a['sid'], '', '', a['rel'], f'{a["desc"] or "—"} · {a["note"]} · pendente: {a["cmd"] or "—"}')))
    for p in PIECES: print('\t'.join(tsvc(x) for x in ('piece', p['id'], p['cls'], os.path.basename(str(p['lp'] or '')), '', '', p['osrc'],
              f'dono {p["owner"]} · sponsor {p["sponsor"] or "—"} · {p["note"]}' + (f' · arranque: {p["card"]}' if p['card'] else ''))))
    for c, p, note, cure in HY: print('\t'.join(tsvc(x) for x in ('hygiene', p['sid'] if p else '-', c, os.path.basename(p['cwd']) if p else '-', '', '', '/proc',
              f'{note} · cura: {cure}')))
    for r in signals: print(f'signal\t{tsvc(r.get("ref"))}\t-\t-\t\t\tdecide-census\t{tsvc(r.get("label"))}')
    print(f'maestro\tasks\t-\t-\t\t{sum(1 for a in asks if a["live"])}\tmaestro-ask\tvencidas {sum(1 for a in asks if not a["live"])}')
    print(f'maestro\tseal_candidates\t-\t-\t\t{len(seals)}\tdecide-census\tcheckpoints {len(checkpoints)} · nós open owner:maestro {len(owned.get("maestro", []))}')
    print(f'load\t-\t-\t-\t\t\t/proc/loadavg+lease\t{tsvc(load_line)}')
    print(f'stale_beacons\t-\t-\t-\t\t{len(stale_traces)}\tfarol\trastro fora do TTL, sem peer')
    for e in events: print(f'change\t-\t-\t-\t\t\tsince\t{tsvc(e)}')
    for g in gaps: print(f'gap\t-\t-\t-\t\t\t-\t{tsvc(g)}')
    for w in warns: print(f'warn\t-\t-\t-\t\t\t-\t{tsvc(w)}')
    print(f'sha\t{sha}\t-\t-\t\t\t-\t{"changed" if changed else "unchanged"}')
    sys.exit(0)

head = f'baton-pulse · {iso(now)} · sha {sha}'
cls_line = (' · '.join(f'{c} {cnt[c]}' for c in CLASSES)) if sessions_measured else 'sessões NÃO MEDIDAS (nenhuma fonte legível): não é zero'
ag_line = ('subagentes: ' + ' · '.join(f'{c} {acnt[c]}' for c in AORD)) if agents_measured else 'subagentes NÃO MEDIDOS'
if quiet and not changed:
    unm = ' · '.join(x for x, ok in (('⚠️ PRs NÃO medidos', prs_measured), ('⚠️ sinais NÃO medidos', signals_measured),
                                       ('⚠️ perguntas NÃO medidas', asks_measured), ('⚠️ parada NÃO medida', not park_unknown)) if not ok)
    print(f'{head} · sem mudança (sha igual ao --last-sha' + (f', nenhum evento desde {iso(since_ts)}' if since_ts is not None else '') + f') · {cls_line} · {ag_line} · {pc_line} · {hy_line}' + (f' · {unm}' if unm else ''))
    sys.exit(0)
print(f'# {head}')
print(f'fontes: peers={peers_src} · farol={beacon_desc} · repos={len(repos)} · transcript={"stat de " + proj_dir if proj_ok else "não medido"} · '
      f'em voo=decide-census rc {dc_rc} · perguntas={ask_dir} · parked={park_p}{" (" + str(len(park_rows)) + " linha(s))" if park_rows is not None else (" (ausente: ninguém parado por ordem)" if park_st == "absent" else " (" + park_st + ": NÃO MEDIDO)")} · '
      f'rótulos={own_p if own_rows is not None else ("derivados" if own_st == "absent" else "derivados (" + own_st + ")")} · ociosa após {idle_min}min · papel={role or "?"}')
print(f'classes: {cls_line}')
print(ag_line)
print(pc_line)
_gr = [s for s in S.values() if s.get('grant') and s['grant'][1]]
grant_src = grant_p if grant_rows is not None else ('ausente' if grant_st == 'absent' else grant_st + ': NÃO MEDIDO')
print(f'batutas-de-projeto: {len(_gr)} concedida(s)' + (f' · {sum(1 for s in _gr if s["cls"] == "ACTIVE")} ACTIVE (tocando o próprio fio)' if _gr else '') + f' · fonte={grant_src}')
print(hy_line)
for w in warns: print(f'⚠️ {w}')
for g in gaps: print(f'🕳️ lacuna: {g}')
if quiet:
    print('\n## O que mudou' + (f' desde {iso(since_ts)}' if since_ts is not None else ''))
    for e in events: print(f'- {e}')
    if not last_sha: print('- sem --last-sha: não há base de comparação, a batida fala (guarde o sha abaixo)')
    elif last_sha != sha: print(f'- o estado mudou (sha {last_sha} → {sha})')
    print(f'- sha do estado: {sha}')
    for s in sess_sorted:
        if s['cls'] == 'IDLE_WITH_QUEUE': print(f'- IDLE_WITH_QUEUE: {s["name"] or s["sid"][:8]} ({os.path.basename(s["cwd"])}) · {len(s["queue"])} item(ns) de fila')
    for p in prs:
        if p['ci'] == 'RED': print(f'- {p["ref"]} com CI vermelho ({p["branch"]})')
    for a in AG:
        if a['cls'] in AG_ALERT: print(f'- {a["cls"]}: {a["aid"]} da sessão {a["sid"][:8]} ({a["desc"] or "—"}) · {a["note"]}' + (f' · pendente: {md_code(a["cmd"])}' if a['cmd'] else ''))
    for c, p, note, cure in HY: print(f'- {c}: {note} · cura: {md_code(cure)}')
    for p in PIECES:
        if p['cls'] in PIECE_ALERT: print(f'- {p["cls"]}: {p["id"]} · dono {p["owner"]} ({p["osrc"]}) · {p["note"]}' + (f' · arranque: {md_code(p["card"])}' if p['card'] else ''))
    sys.exit(0)
print('\n## Sessões')
print('| classe | sessão | repo | estado medido | fila pronta (dono declarado) | fonte |')
print('|---|---|---|---|---|---|')
for s in sess_sorted:
    me = ' (esta sessão)' if self_sid and s['sid'] == self_sid else ''
    qd = (f'{len(s["queue"])}: ' + '; '.join(s['queue'][:4]) + (f'; +{len(s["queue"]) - 4}' if len(s['queue']) > 4 else '')) if s['queue'] else '—'
    gr = f' · batuta-de-projeto: {"sim" if s["grant"][1] else "não"} ({s["grant"][0]}, por {s["grant"][2]})' if s.get('grant') else ''
    print(f'| {s["cls"]} | {s["name"] or "—"} `{s["sid"][:8]}`{me} | {os.path.basename(s["cwd"]) or "—"} | {s["note"]} | {qd} | {"+".join(s["src"])} · rótulo {"/".join(s["labels"]) or "—"}{gr} |')
if not S: print('| — | nenhuma sessão nas fontes medidas | | | | |')
print('\n## Subagentes das sessões vivas (transcript em <projects>/*/<sessão>/subagents/ e subagents/workflows/<run>/)')
if not agents_measured: print('- NÃO MEDIDO (sem diretório de transcripts): não é «nenhum parado»')
for a in AG:
    if a['cls'] != 'AGENT_DONE': print(f'- {a["cls"]} `{a["aid"]}` · sessão `{a["sid"][:8]}` · {a["desc"] or "—"} · {a["note"]}' + (f' · pendente: {md_code(a["cmd"])}' if a['cmd'] else ''))
if agents_measured: print(f'- AGENT_DONE: {acnt["AGENT_DONE"]} (terminados, não listados; --tsv lista todos)' + ('' if AG else ' · nenhum transcript de subagente nas sessões vivas'))
print('\n## Peças (sessão dona por peça: owner_session → owners.tsv → core; aviso, nunca bloqueio)')
for p in PIECES:
    print(f'- {p["cls"]} `{p["id"]}` · dono «{p["owner"]}» ({p["osrc"]}) · sponsor {p["sponsor"] or "—"} · {p["note"]}' + (f' · arranque: {md_code(p["card"])}' if p['card'] else ''))
if not PIECES: print(f'- nenhuma peça declarada ({pieces_src})')
print('\n## Higiene das sessões (tmux nomeado, --worktree, teto; aviso, nunca bloqueio)')
for c, p, note, cure in HY: print(f'- {c} · {note} · cura: {md_code(cure)}')
if not HY: print('- nenhum aviso' if peers_ok else '- NÃO MEDIDA (sem lista de peers)')
print('\n## Fila declarada sem sessão casada')
if orphan_queue:
    for o, v in sorted(orphan_queue.items()):
        print(f'- `owner: {o}` · {len(v)} nó(s) open: ' + ', '.join(n for _, n, _ in v[:6]) + (' …' if len(v) > 6 else '') +
              f' — nenhuma sessão medida tem esse rótulo (declare em {own_p}: `<id|nome|cwd>\\t{o}`)')
else: print('- nenhuma')
print('\n## PRs abertos (decide-census)')
for p in prs:
    print(f'- {p["ref"]} `{p["branch"]}` · CI {p["ci"]} · {"PARADO" if p["stopped"] else "em voo"} · {p["state"]}' + ('' if p['ref'] in claimed_pr else ' · sem sessão casada'))
if not prs: print('- nenhum' if prs_measured else '- NÃO MEDIDO (gh indisponível ou --no-gh): não é «nenhum»')
print('\n## Worktrees com pendência (decide-census)')
for t in threads: print(f'- `{t["ref"]}` {t["path"]} · {t["label"]} · {t["state"]} · {t["actor"]}')
if not threads: print('- nenhuma' if dc_rc in ('0', 'override') else '- NÃO MEDIDO')
print('\n## Com o maestro')
la = [a for a in asks if a['live']]
print((f'- perguntas reservadas vivas: {len(la)} (vencidas: {len(asks) - len(la)})' if asks_measured else '- perguntas reservadas: NÃO MEDIDAS') + (': ' + ', '.join(a['key'].split('#')[-1] for a in la[:8]) if la else ''))
print(f'- candidatas a selo (decide-census, janela/citação): {len(seals)} · checkpoints pendentes: {len(checkpoints)} · nós open com `owner: maestro`: {len(owned.get("maestro", []))}')
print(f'- sinais sem ack: {len(signals) if signals_measured else "NÃO MEDIDOS"}' + (': ' + '; '.join(r.get('label', '') for r in signals) if signals else ''))
if stale_traces: print(f'- faróis velhos (stale, fora do TTL, sem peer): {len(stale_traces)} — rastro, não sessão; `session-beacon.sh sweep <repo>` limpa')
print(f'\n## Carga\n- {load_line}')
if since_ts is not None:
    print(f'\n## O que mudou desde {iso(since_ts)}')
    for e in events: print(f'- {e}')
    if not events: print('- nenhum evento datado')
print(f'\nsha do estado: `{sha}` (passe --last-sha {sha} na próxima batida)')
PY
