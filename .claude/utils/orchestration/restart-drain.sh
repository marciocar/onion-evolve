#!/usr/bin/env bash
# ===========================================================================
# restart-drain.sh — o MEDIDOR e ESCRITOR do /meta:restart: reinício gracioso (drain) sem perder agentes e tarefas.
#
# ── POR QUE EXISTE (medido em 2026-11-21) ─────────────────────────────────────────────────────────────
# Atualizar o Claude Code («Update installed · Restart to update») ou reabrir a sessão mata os subagentes e as tarefas
# de fundo, que vivem no processo. Em 2026-11-21, 5 agentes pararam no meio de pre-commit e CI e foram retomados à mão,
# um por um, por SendMessage. Ninguém tinha anotado quem estava em voo, em qual worktree nem em qual passo.
#
# ── A FORMA É A DO MERCADO: desligamento gracioso (graceful shutdown / drain) ──────────────────────────
#   parar de aceitar trabalho novo → esperar o que está em curso, com teto → gravar o estado → reiniciar → retomar.
#   É o `terminationGracePeriodSeconds` + preStop do Kubernetes, o `drain` do Nomad e do Consul, o SIGTERM com
#   prazo antes do SIGKILL. Aqui o «trabalho novo» é despacho de agente, e o estado gravado é o bilhete de retomada.
#
# ── O QUE MEDE (descoberta por referência, nada reimplementado) ───────────────────────────────────────
#   agentes   as linhas `agent` do baton-pulse.sh --tsv (achado em ../../validation/), só desta sessão (--self), sem
#             peers, sem família, sem gh e sem o decide-census (BATON_DECIDE_TSV=/dev/null: aqui só os agentes importam).
#             A classe é a dele (AGENT_RUNNING|STALLED|SILENT|DONE|UNMEASURED), nunca refeita aqui.
#   tarefas   a sonda background-task-probe.sh (achada em ../../hooks/), rodada sobre o transcript da sessão E sobre o
#             transcript de cada agente não terminado (a sonda sozinha não vê tarefa lançada por subagente: teto dela).
#             «tarefa X: PID …» = viva · «sem processo» = morta · «NÃO MEDIDO» = conta como viva (fail-closed).
#   onde      worktree e branch de cada agente: o caminho de worktree (do `git worktree list` do repo) citado por último
#             nas entradas de ferramenta do transcript dele; sem citação, o cwd e o gitBranch da última entrada, DITOS.
#   passo     o comando pendente do agente como o baton-pulse o entrega, JÁ REDIGIDO (segredo → [REDACTED], pela lista
#             dele); sem pendência, só o nome da última ferramenta e o arquivo. O texto cru do comando nunca é lido para o
#             bilhete. A home sai como ~.
#
# ── O QUE GRAVA (em ${ONION_RESTART_DIR:-~/.local/state/onion/restart}) ───────────────────────────────
#   <sid>.draining   o MARCADOR «sem despacho novo» (since, nome, modo). Quem lê: a batida (baton-pulse.sh avisa) e a
#                    própria sessão (o /meta:restart manda não despachar enquanto ele existir). Apagado no --resume-check,
#                    que também limpa o marcador órfão de uma drenagem que saiu rc 2 (sem bilhete: rc 4).
#   O diretório é o irmão `restart/` do estado da batuta: ${XDG_STATE_HOME:-~/.local/state}/onion/restart. Arquivos 0600.
#   <sid>.md         o BILHETE de retomada: cada agente em voo (id, descrição, classe, worktree, branch, último passo),
#                    as tarefas de fundo, o comando de retomada da sessão e o que mandar a cada agente na volta.
#   <sid>.tsv        o mesmo bilhete para máquina (o --resume-check lê este, nunca a prosa do .md).
#
# Uso:
#   restart-drain.sh [--session <sid>] [--name <nome>] [--repo <dir>] [--timeout-min N | --timeout-s N] [--poll-s N]
#                    [--stale-min N] [--now]
#       drena: marcador → mede → espera até zerar ou vencer o teto, dizendo o que ainda corre → bilhete → comando.
#       --now pula a espera (só marcador + bilhete). Padrões: teto 15 min, sondagem 30 s, antigo além de 240 min.
#   restart-drain.sh --resume-check [--session <sid> | --all]
#       na volta: lista quem retomar (do .tsv), apaga o marcador e arquiva o bilhete como <sid>.<epoch>.resumed.*.
#   restart-drain.sh --status
#       só lê: marcadores e bilhetes pendentes (TSV). Não apaga nada.
# ── O MODO DA SESSÃO E A CÓPIA (2026-11-24, Claude Code 2.1.331) ─────────────────────────────────────
#   A receita de retomada depende de onde a sessão roda, lido da lista de peers (`claude agents --json`, pela regra única
#   de «viva» do session-liveness.sh, ao lado) e do ambiente do processo (a chave TMUX): tmux = a receita de sempre;
#   fundo nativo = `claude stop <id> && bash ops/session-open.sh <nome> --resume <id>` (core-only), que volta ao tmux e
#   recupera o canal da campainha; terminal solto = a mesma receita com o aviso de /exit antes; não medido = dito. O
#   sufixo « (N)» que o harness põe no nome repetido sai antes de montar o comando do abridor.
#   A tecla ← manda a sessão ao fundo como CÓPIA de id novo (fork_inherit). O --resume-check chamado da cópia, sem
#   bilhete do próprio id, segue o bilhete do ANCESTRAL: o pendente cujo transcript é a origem dela (fork-of).
# Ambiente (bancada): ONION_RESTART_DIR · RESTART_PROJECTS_DIR (padrão ~/.claude/projects) · RESTART_PULSE ·
#   RESTART_PROBE · RESTART_SESSION_OPEN (padrão <repo>/ops/session-open.sh, core-only) · CLAUDE_CODE_SESSION_ID (o --session padrão) ·
#   RESTART_CLAUDE (o binário do `agents --json`) · RESTART_LIVENESS (a regra de «viva») · RESTART_PROC (um /proc falso).
# Saída: 0 zerou ou --now (bilhete gravado) · 3 teto vencido com trabalho em curso (bilhete gravado, o que corre é dito)
#        · 5 bilhete gravado COM LACUNA (algo NÃO MEDIDO, no --now ou numa falha durante a espera; no --resume-check,
#          bilhete que trazia lacuna) · 4 --resume-check sem bilhete · 2 uso, sessão sem id, ou medição impossível
#          (a drenagem não espera às cegas: medidor ou sonda ausente, transcript da sessão não achado).
# TETO HONESTO: não mata nada e não reinicia nada; quem reinicia é o humano (ou o update). Não sabe se o processo de um
#   subagente vive (o harness não expõe pid por subagente): o que mede é o transcript. Um agente que despacha o próprio
#   /meta:restart a partir de um subagente conta a si mesmo como RUNNING: rode-o da sessão principal.
# Bancada: run_restart_drain_selftests em .claude/validation/lint-selftest.sh.
# ===========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RESTART_HERE="${HERE}"
exec python3 -I - "$@" <<'PY'
import glob, json, os, re, shlex, subprocess, sys, time

HERE = os.environ['RESTART_HERE']
HOME = os.path.expanduser('~')
# o mesmo lugar que a batida lê: o irmão `restart/` do diretório de estado da batuta (XDG_STATE_HOME ou ~/.local/state)
RDIR = os.environ.get('ONION_RESTART_DIR') or os.path.join(os.environ.get('XDG_STATE_HOME') or os.path.join(HOME, '.local', 'state'), 'onion', 'restart')
PROJ = os.environ.get('RESTART_PROJECTS_DIR') or os.path.join(HOME, '.claude', 'projects')
PULSE = os.environ.get('RESTART_PULSE') or os.path.normpath(os.path.join(HERE, '..', '..', 'validation', 'baton-pulse.sh'))
PROBE = os.environ.get('RESTART_PROBE') or os.path.normpath(os.path.join(HERE, '..', '..', 'hooks', 'background-task-probe.sh'))
NAME_RE = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')   # o valid_name do ops/session-open.sh (core-only)
# a regra única de «viva» e a detecção da cópia (fork_inherit): .claude/utils/orchestration/session-liveness.sh, ao lado
LIV = os.environ.get('RESTART_LIVENESS') or os.path.join(HERE, 'session-liveness.sh')
CLAUDE = os.environ.get('RESTART_CLAUDE') or 'claude'
PROCD = os.environ.get('RESTART_PROC') or '/proc'
os.umask(0o077)   # marcador e bilhete trazem ids, caminhos e comandos: só o dono lê

def die(msg, rc=2):
    print(f'restart-drain: {msg}', file=sys.stderr); sys.exit(rc)

# ── argumentos ──
a = sys.argv[1:]
opt = {'session': os.environ.get('CLAUDE_CODE_SESSION_ID', ''), 'name': '', 'repo': '', 'timeout': 900, 'poll': 30,
       'stale': 240, 'now': False, 'mode': 'drain', 'all': False}
def need(i):
    if i + 1 >= len(a): die(f'{a[i]} pede valor')
    return a[i + 1]
def posint(v, flag, zero_ok=False):
    if not re.fullmatch(r'[0-9]+', v) or (int(v) == 0 and not zero_ok): die(f'{flag} inválido ({v}) — inteiro >= {0 if zero_ok else 1}')
    return int(v)
i = 0
while i < len(a):
    x = a[i]
    if x == '--session': opt['session'] = need(i); i += 1
    elif x == '--name': opt['name'] = need(i); i += 1
    elif x == '--repo': opt['repo'] = need(i); i += 1
    elif x == '--timeout-min': opt['timeout'] = posint(need(i), x, True) * 60; i += 1
    elif x == '--timeout-s': opt['timeout'] = posint(need(i), x, True); i += 1
    elif x == '--poll-s': opt['poll'] = posint(need(i), x); i += 1
    elif x == '--stale-min': opt['stale'] = posint(need(i), x); i += 1
    elif x == '--now': opt['now'] = True
    elif x in ('--resume-check', '--status'):
        m = 'resume' if x == '--resume-check' else 'status'
        if opt['mode'] not in ('drain', m): die('--resume-check e --status não se combinam')
        opt['mode'] = m
    elif x == '--all': opt['all'] = True
    else: die(f'opção desconhecida: {x}')
    i += 1
if opt['mode'] != 'drain' and opt['now']: die('--now só vale na drenagem (sem --status/--resume-check)')
if opt['mode'] != 'resume' and opt['all']: die('--all só vale com --resume-check')
if opt['name'] and not NAME_RE.fullmatch(opt['name']): die(f'--name fora do padrão do session-open.sh ({opt["name"]})')
SID = opt['session']
if SID and not re.fullmatch(r'[A-Za-z0-9._-]+', SID): die(f'--session fora do alfabeto ({SID})')

def iso(t): return time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(t))
def read_tsv(p):
    try:
        with open(p, encoding='utf-8') as f: return [l.rstrip('\n').split('\t') for l in f if l.strip()]
    except OSError: return None

# ── --status: só lê ──
if opt['mode'] == 'status':
    print('kind\tsession\tname\tsince\tdetail')
    for p in sorted(glob.glob(os.path.join(glob.escape(RDIR), '*.draining'))):
        r = (read_tsv(p) or [['?', '?', '?']])[0] + ['?', '?', '?']
        print(f'draining\t{os.path.basename(p)[:-len(".draining")]}\t{r[1]}\t{r[0]}\tmodo {r[2]}')
    for p in sorted(glob.glob(os.path.join(glob.escape(RDIR), '*.tsv'))):
        b = os.path.basename(p)
        if '.resumed.' in b: continue
        rows = read_tsv(p) or []
        head = next((r for r in rows if r and r[0] == 'session'), ['session', '?', '?', '?'])
        n = sum(1 for r in rows if r and r[0] == 'agent'); t = sum(1 for r in rows if r and r[0] == 'task')
        ng = sum(1 for r in rows if r and r[0] == 'gap')
        ag_unm = any(r[0] == 'gap' and 'agentes NÃO MEDIDOS' in '\t'.join(r) for r in rows if r)
        print(f'ticket\t{b[:-4]}\t{head[2] if len(head) > 2 else "?"}\t{head[3] if len(head) > 3 else "?"}\t{"agentes NÃO MEDIDOS" if ag_unm else f"{n} agente(s)"}, {t} tarefa(s)'
              + (f', ⚠️ {ng} lacuna(s): o que não foi medido NÃO é zero' if ng else ''))
    sys.exit(0)

# ── --resume-check: lista quem retomar, apaga o marcador, arquiva o bilhete ──
def transcript_of(sid):
    m = glob.glob(os.path.join(glob.escape(PROJ), '*', glob.escape(sid) + '.jsonl')); return m[0] if m else ''
if opt['mode'] == 'resume':
    if opt['all']: sids = sorted({os.path.basename(p)[:-4] for p in glob.glob(os.path.join(glob.escape(RDIR), '*.tsv')) if '.resumed.' not in p})
    elif SID: sids = [SID]
    else: die('sem id de sessão: passe --session <sid> ou --all (CLAUDE_CODE_SESSION_ID vazio)')
    # O BILHETE SEGUE A CÓPIA (2026-11-24): a sessão mandada ao fundo nativo (tecla ←) volta com id NOVO, e o bilhete
    # ficou no id antigo. Sem bilhete do próprio id, vale o de um ancestral: o bilhete pendente cujo transcript é a
    # origem desta cópia (fork_inherit + o 1º uuid da cópia presente na origem, pelo session-liveness.sh fork-of).
    if not opt['all'] and SID and not os.path.exists(os.path.join(RDIR, f'{SID}.tsv')):
        me = transcript_of(SID)
        for p in (sorted(glob.glob(os.path.join(glob.escape(RDIR), '*.tsv'))) if me else []):
            b = os.path.basename(p)[:-4]
            if '.resumed.' in os.path.basename(p) or b == SID: continue
            anc = transcript_of(b)
            if not anc: continue
            try: fr = subprocess.run(['bash', LIV, 'fork-of', me, anc], capture_output=True, text=True, timeout=120).returncode
            except (OSError, subprocess.TimeoutExpired): fr = 2
            if fr == 2: print(f'⚠️ não medi se esta sessão é cópia de {b} (fork-of falhou): o bilhete dele NÃO foi seguido')
            if fr == 0:
                print(f'esta sessão ({SID}) é cópia de {b} (fork_inherit: mandada ao fundo, ganhou id novo): sigo o bilhete do ancestral')
                sids = [b]; break
    found = 0; ngaps = 0; now = int(time.time())
    for s in sids:
        tp = os.path.join(RDIR, f'{s}.tsv'); rows = read_tsv(tp)
        mk = os.path.join(RDIR, f'{s}.draining')
        if rows is None:
            if os.path.exists(mk): os.remove(mk); print(f'marcador de {s} apagado (sem bilhete: drenagem que não terminou)')
            continue
        found += 1
        head = next((r for r in rows if r and r[0] == 'session'), ['session', s, '?', '?'])
        ags = [r for r in rows if r and r[0] == 'agent']; tks = [r for r in rows if r and r[0] == 'task']
        gps = [r for r in rows if r and r[0] == 'gap']; ngaps += len(gps)
        print(f'== bilhete de {head[2] if len(head) > 2 else "?"} ({s}), gravado em {head[3] if len(head) > 3 else "?"}: {len(ags)} agente(s) a retomar, {len(tks)} tarefa(s) de fundo')
        for r in ags:
            r = r + [''] * 8
            print(f'  · SendMessage to={r[1]} — «Reinício da sessão: retome de onde parou. Último passo: {r[7] or "—"}. '
                  f'Confira o estado (git status, PR, CI) antes de repetir qualquer passo.»  [{r[2]} · worktree {r[4] or "—"} · branch {r[5] or "—"}] {r[3]}')
        for r in tks:
            r = r + [''] * 3
            print(f'  · tarefa {r[1]}: morreu com o processo; relance à mão se ainda for preciso — {r[2]}')
        for r in gps:
            print(f'  ⚠️ NÃO MEDIDO na gravação: {(r + [""])[1]} — a lista acima pode estar incompleta; confira os transcripts')
        if os.path.exists(mk): os.remove(mk)
        for ext in ('tsv', 'md'):
            p = os.path.join(RDIR, f'{s}.{ext}')
            if os.path.exists(p): os.replace(p, os.path.join(RDIR, f'{s}.{now}.resumed.{ext}'))
        print(f'  marcador «sem despacho novo» apagado; bilhete arquivado em {RDIR}/{s}.{now}.resumed.md')
    if not found: print('nenhum bilhete de retomada pendente' + (f' para {SID}' if SID and not opt['all'] else '')); sys.exit(4)
    sys.exit(5 if ngaps else 0)

# ── drain ──
if not SID: die('sem id de sessão: passe --session <sid> (CLAUDE_CODE_SESSION_ID vazio)')
def git(*args, cwd=None):
    try: r = subprocess.run(['git', *args], cwd=cwd, capture_output=True, text=True, timeout=20); return r.returncode, r.stdout
    except (OSError, subprocess.TimeoutExpired): return 1, ''
REPO = opt['repo']
if not REPO:
    rc, out = git('rev-parse', '--show-toplevel'); REPO = out.strip() if rc == 0 else ''
if not REPO or git('rev-parse', '--git-dir', cwd=REPO)[0] != 0: die(f'sem índice git em «{REPO or os.getcwd()}»: passe --repo <dir>')
mt = glob.glob(os.path.join(glob.escape(PROJ), '*', glob.escape(SID) + '.jsonl'))
MAIN_T = mt[0] if mt else ''
# drenar às cegas é o defeito: medidor ausente ou sessão sem transcript recusam ANTES do marcador (no --now viram lacuna)
pre_gaps = []
if not os.path.isfile(PULSE): pre_gaps.append(f'medidor de agentes ausente ({PULSE}): agentes NÃO MEDIDOS')
if not os.path.isfile(PROBE): pre_gaps.append(f'sonda de tarefas ausente ({PROBE}): tarefas de fundo NÃO MEDIDAS')
if not MAIN_T: pre_gaps.append(f'transcript da sessão {SID} não achado em {PROJ} (id errado?): tarefas de fundo da sessão NÃO MEDIDAS')
if pre_gaps and not opt['now']:
    for g in pre_gaps: print(f'⚠️ {g}', file=sys.stderr)
    die('medição impossível: não drenei às cegas e não gravei marcador. Corrija o que está acima, ou use --now para gravar só o que se sabe')
def title_of(tp):
    """o último customTitle do transcript, lido como JSON (a linha type=custom-title), nunca por regex sobre o texto."""
    try: r = subprocess.run(['grep', '-a', '-F', 'customTitle', tp], capture_output=True, text=True, timeout=30, errors='replace')
    except (OSError, subprocess.TimeoutExpired): return ''
    t = ''
    for l in r.stdout.splitlines():
        try: d = json.loads(l)
        except ValueError: continue
        if isinstance(d, dict) and d.get('type') == 'custom-title' and isinstance(d.get('customTitle'), str): t = d['customTitle']
    return t
NAME = opt['name'] or (title_of(MAIN_T) if MAIN_T else '')
NAME_SRC = 'flag --name' if opt['name'] else ('customTitle do transcript' if NAME else 'sem título no transcript')
os.makedirs(RDIR, mode=0o700, exist_ok=True)
T0 = int(time.time())
MARK = os.path.join(RDIR, f'{SID}.draining')
with open(MARK, 'w', encoding='utf-8') as f: f.write(f'{iso(T0)}\t{NAME or "?"}\t{"now" if opt["now"] else "drain"}\n')
print(f'🛑 sem despacho novo: marcador gravado em {MARK} (a batida e a sessão o leem; o --resume-check o apaga)')

# worktrees do repo (caminho → branch), a principal fora
WT = {}
_, wl = git('worktree', 'list', '--porcelain', cwd=REPO)
cur = None; first = True
for l in wl.splitlines():
    if l.startswith('worktree '):
        cur = l[9:]
        if first: first = False
        else: WT[cur] = '(destacada)'
    elif l.startswith('branch ') and cur in WT: WT[cur] = l[7:].replace('refs/heads/', '')
def short(s, n=140):
    s = str(s).replace(HOME, '~').strip()
    s = s.splitlines()[0] if s else ''
    return (s[:n] + '…') if len(s) > n else s

def agent_where(path):
    """→ (worktree, branch, ferramenta da última chamada, idade_min). O TEXTO do comando nunca sai daqui: o passo com
    comando vem do baton-pulse, já redigido (segredo → [REDACTED]); daqui sai só o nome da ferramenta e o arquivo."""
    wt = br = tool = ''; last_cwd = last_br = ''; texts = []
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            for line in f:
                try: d = json.loads(line)
                except ValueError: continue
                if not isinstance(d, dict) or d.get('type') not in ('user', 'assistant'): continue
                last_cwd = d.get('cwd') or last_cwd; last_br = d.get('gitBranch') or last_br
                if d['type'] != 'assistant': continue
                for c in ((d.get('message') or {}).get('content') or []):
                    if not isinstance(c, dict) or c.get('type') != 'tool_use': continue
                    inp = c.get('input') if isinstance(c.get('input'), dict) else {}
                    texts.append(' '.join(str(inp.get(k, '')) for k in ('command', 'file_path', 'path', 'cwd')).replace('~/', HOME + '/'))
                    fp = inp.get('file_path') or inp.get('path') or ''
                    tool = f'{c.get("name", "?")}' + (f': {short(fp)}' if fp else '')
    except OSError: return '', '', 'transcript ilegível', None
    for t in reversed(texts):
        hit = sorted((p for p in WT if p and re.search(re.escape(p) + r'(?=$|[/\s"\';&|)])', t)), key=len, reverse=True)
        if hit: wt, br = hit[0], WT[hit[0]]; break
    if not wt: wt, br = (f'{last_cwd} (cwd da sessão)' if last_cwd else ''), last_br
    try: age = int((time.time() - os.stat(path).st_mtime) // 60)
    except OSError: age = None
    return wt.replace(HOME, '~'), br, tool or '—', age

def probe(tp):
    """→ (lista de (id, viva:bool|None, linha), lacuna|None) da sonda sobre um transcript."""
    env = dict(os.environ, BG_PROBE_STATE_DIR=os.path.join(RDIR, '.probe'), LC_ALL='C')
    try: r = subprocess.run(['bash', PROBE], input=json.dumps({'transcript_path': tp}), capture_output=True, text=True, timeout=30, env=env)
    except (OSError, subprocess.TimeoutExpired) as e: return [], f'sonda não rodou sobre {os.path.basename(tp)} ({type(e).__name__}): tarefas NÃO MEDIDAS'
    try: ctx = ((json.loads(r.stdout).get('hookSpecificOutput') or {}).get('additionalContext') or '') if r.stdout.strip() else ''
    except (ValueError, AttributeError): return [], f'sonda devolveu saída ilegível sobre {os.path.basename(tp)}: tarefas NÃO MEDIDAS'
    out = []
    for l in ctx.splitlines():
        m = re.match(r'\s*· tarefa ([A-Za-z0-9_-]+): (.*)', l)
        if not m: continue
        body = m.group(2)
        alive = True if body.startswith('PID ') else (False if body.startswith('sem processo') else None)
        out.append((m.group(1), alive, short(body, 200)))
    return out, None

def measure_agents():
    """→ ((live, old), []) ou (None, lacunas). Classe e comando pendente (redigido) são os do baton-pulse --tsv."""
    if not os.path.isfile(PULSE): return None, [f'medidor de agentes ausente ({PULSE}): agentes NÃO MEDIDOS']
    env = dict(os.environ, BATON_DECIDE_TSV='/dev/null', BATON_PROJECTS_DIR=PROJ)
    try: r = subprocess.run(['bash', PULSE, REPO, '--tsv', '--no-peers', '--no-family', '--no-gh', '--self', SID],
                            capture_output=True, text=True, timeout=120, env=env)
    except (OSError, subprocess.TimeoutExpired) as e: return None, [f'baton-pulse não rodou ({type(e).__name__}): agentes NÃO MEDIDOS']
    if r.returncode != 0: return None, [f'baton-pulse rc {r.returncode}: agentes NÃO MEDIDOS — {short(r.stderr)}']
    gaps = []; ags = []
    for l in r.stdout.splitlines():
        f = l.split('\t')
        if f[0] == 'gap' and len(f) > 7 and 'subagentes' in f[7]: gaps.append(f[7])
        if f[0] != 'agent' or len(f) < 8 or f[3] != SID: continue
        desc_note, _, pend = f[7].rpartition(' · pendente: ')
        ags.append({'aid': f[1], 'cls': f[2], 'rel': f[6], 'desc': (desc_note or f[7]).split(' · ')[0], 'pend': pend.strip()})
    if gaps: return None, gaps
    live = []; old = []
    for g in ags:
        if g['cls'] == 'AGENT_DONE': continue
        p = glob.glob(os.path.join(glob.escape(PROJ), '*', glob.escape(SID), g['rel']))
        g['path'] = p[0] if p else ''
        g['wt'], g['br'], tool, g['age'] = agent_where(g['path']) if g['path'] else ('', '', 'transcript não achado', None)
        g['step'] = short(g['pend'], 160) if g['pend'] and g['pend'] != '—' else tool
        (old if g['cls'] != 'AGENT_RUNNING' and g['age'] is not None and g['age'] > opt['stale'] else live).append(g)
    return (live, old), []

def measure_tasks(live):
    """→ (tarefas não mortas, lacunas): a sonda sobre o transcript da sessão e sobre o de cada agente em voo."""
    if not os.path.isfile(PROBE): return [], [f'sonda de tarefas ausente ({PROBE}): tarefas de fundo NÃO MEDIDAS']
    tasks, gaps = [], []
    if not MAIN_T: gaps.append(f'transcript da sessão {SID} não achado em {PROJ}: tarefas de fundo da sessão NÃO MEDIDAS')
    for tp in ([MAIN_T] if MAIN_T else []) + [g['path'] for g in live if g.get('path')]:
        got, gap = probe(tp)
        if gap: gaps.append(gap)
        for tid, alive, line in got:
            if alive is False: continue
            tasks.append({'id': tid, 'alive': alive, 'line': line, 'of': 'sessão' if tp == MAIN_T else os.path.basename(tp)[6:-6]})
    return tasks, gaps

def busy(live, tasks):
    """o que segura a espera: agente rodando, com pendência ou NÃO MEDIDO (fail-closed), e tarefa viva ou NÃO MEDIDA."""
    return [g for g in live if g['cls'] in ('AGENT_RUNNING', 'AGENT_STALLED', 'AGENT_UNMEASURED')], [t for t in tasks if t['alive'] is not False]

res, gaps = measure_agents()
if res is None:
    for g in gaps: print(f'⚠️ {g}')
    if not opt['now']: die('medição impossível: não drenei às cegas. O marcador ficou (o --resume-check o apaga); rode de novo ou use --now para gravar só o que se sabe')
    live, old, agents_measured = [], [], False
else: (live, old), agents_measured = res, True
tasks, tgaps = measure_tasks(live); gaps = gaps + tgaps
if tgaps and not opt['now']:
    for g in tgaps: print(f'⚠️ {g}')
    die('medição impossível: tarefas de fundo NÃO MEDIDAS, não drenei às cegas. O marcador ficou (o --resume-check o apaga)')
outcome = '--now (sem espera)'; mid_fail = False
if not opt['now']:
    deadline = T0 + opt['timeout']
    while True:
        ba, bt = busy(live, tasks)
        left = deadline - int(time.time())
        if not ba and not bt: outcome = f'zerou em {int(time.time()) - T0}s'; break
        if left <= 0:
            outcome = f'teto de {opt["timeout"]}s vencido com {len(ba)} agente(s) e {len(bt)} tarefa(s) ainda em curso'; break
        print(f'⏳ {iso(time.time())} · em curso: {len(ba)} agente(s), {len(bt)} tarefa(s) · teto em {left}s')
        for g in ba: print(f'   · agente {g["aid"]} [{g["cls"]}] {g["desc"]} — {g["step"]}')
        for t in bt: print(f'   · tarefa {t["id"]} ({t["of"]}): {t["line"]}')
        time.sleep(min(opt['poll'], max(left, 1)))
        r2, g2 = measure_agents()
        t2, tg2 = measure_tasks(r2[0] if r2 else live)
        if r2 is None or tg2:
            for g in g2 + tg2: print(f'⚠️ {g}')
            # a última medição boa FICA (agentes e tarefas): falha no meio nunca vira «nada em curso»
            gaps = gaps + g2 + tg2; mid_fail = True
            outcome = 'medição falhou durante a espera: bilhete com a última medição boa'; break
        (live, old), tasks = r2, t2

# ── o MODO da sessão (2026-11-24): a receita de retomada depende de onde ela roda ──
#   tmux    interativa com a chave TMUX no ambiente do processo: a receita de sempre (o abridor reabre no tmux);
#   bg      de fundo nativo (`kind: background` no `claude agents --json`): `claude stop <id>` e depois o abridor, que
#           volta ao tmux e recupera o canal da campainha (a cópia de fundo nasce sem a flag do canal);
#   loose   interativa SEM tmux (terminal solto): a mesma receita, com o aviso de dar /exit antes;
#   unknown a lista de peers ou o ambiente não se leram: a receita de sempre, com a lacuna dita.
def session_mode():
    """→ (modo, id curto, nota)."""
    try:
        r = subprocess.run([CLAUDE, 'agents', '--json'], capture_output=True, text=True, timeout=20)
        if r.returncode != 0: raise RuntimeError(f'{CLAUDE} agents --json rc {r.returncode}')
        c = subprocess.run(['bash', LIV, 'classify', '-'], input=r.stdout, capture_output=True, text=True, timeout=30)
        if c.returncode != 0: raise RuntimeError(f'regra de «viva» rc {c.returncode}')
    except (OSError, subprocess.TimeoutExpired, RuntimeError) as e:
        return 'unknown', '', f'modo da sessão NÃO medido ({type(e).__name__}: {e})'
    row = next((f for f in (l.split('\t') for l in c.stdout.splitlines()) if f[0] == SID and len(f) >= 9), None)
    if not row: return 'unknown', '', 'a sessão não está na lista de peers do harness: modo NÃO medido'
    kind, pid, short = row[1], row[3], row[7]
    if kind == 'background': return 'bg', short, ''
    if kind != 'interactive': return 'unknown', short, f'kind «{kind}» desconhecido: modo NÃO medido'
    try: env = open(os.path.join(PROCD, pid, 'environ'), 'rb').read() if pid.isdigit() else None
    except OSError: env = None
    if env is None: return 'unknown', short, f'ambiente do processo {pid} ilegível: tmux NÃO medido'
    return ('tmux' if any(e.startswith(b'TMUX=') for e in env.split(b'\0')) else 'loose'), short, ''
MODE, SHORT, MODE_NOTE = session_mode()

# ── bilhete ──
SO = os.environ.get('RESTART_SESSION_OPEN') or os.path.join(REPO, 'ops', 'session-open.sh')
# o harness acrescenta « (N)» ao nome repetido (medido: «onion-evolve (5)»): o abridor quer o nome sem o sufixo
OPEN_NAME = re.sub(r' \(\d+\)$', '', NAME or '')
if os.path.isfile(SO) and OPEN_NAME and NAME_RE.fullmatch(OPEN_NAME):
    resume_cmd, resume_note = f'bash ops/session-open.sh {shlex.quote(OPEN_NAME)} --resume {shlex.quote(SID)}', ''  # (core-only): só quando o abridor existe (teste de presença acima)
else:
    resume_cmd = f'claude --resume {shlex.quote(SID)}'
    resume_note = (' (ops/session-open.sh ausente neste repo: retomada direta, sem tmux)' if not os.path.isfile(SO) else  # (core-only)
                   f' (título «{NAME or "?"}» fora do padrão de nome do ops/session-open.sh: retomada direta, sem tmux)')  # (core-only)
if MODE == 'bg':
    resume_cmd = f'claude stop {shlex.quote(SHORT)} && {resume_cmd}'
    resume_note += (' (a sessão roda no FUNDO NATIVO: o stop a para sem perder a conversa, e o abridor a reabre no tmux com o canal da '
                    'campainha; para só entrar nela, claude attach ' + SHORT + ')')
elif MODE == 'loose':
    resume_note += ' (⚠️ a sessão roda num terminal SOLTO, fora do tmux: dê /exit nela antes; o comando a reabre no tmux)'
elif MODE == 'unknown':
    resume_note += f' (⚠️ {MODE_NOTE}: confira se a sessão está no tmux, no fundo nativo ou num terminal solto)'
def tsvc(x): return str(x if x is not None else '').replace('\t', ' ').replace('\n', ' ')
with open(os.path.join(RDIR, f'{SID}.tsv.tmp'), 'w', encoding='utf-8') as f:
    f.write('\t'.join(tsvc(x) for x in ('session', SID, NAME or '?', iso(time.time()), outcome, resume_cmd, MODE)) + '\n')
    for g in live: f.write('\t'.join(tsvc(x) for x in ('agent', g['aid'], g['cls'], g['desc'], g['wt'], g['br'], g['age'], g['step'])) + '\n')
    for t in tasks: f.write('\t'.join(tsvc(x) for x in ('task', t['id'], f'{t["of"]}: {t["line"]}')) + '\n')
    for g in gaps: f.write(f'gap\t{tsvc(g)}\n')
os.replace(os.path.join(RDIR, f'{SID}.tsv.tmp'), os.path.join(RDIR, f'{SID}.tsv'))
L = [f'# Bilhete de retomada · {NAME or "?"} ({SID})', '',
     f'- gravado: {iso(time.time())} · modo: {"--now" if opt["now"] else "drain"} · teto: {opt["timeout"]}s · resultado: {outcome}',
     f'- nome da sessão: {NAME or "?"} ({NAME_SRC})',
     f'- modo da sessão: {MODE}' + (f' ({MODE_NOTE})' if MODE_NOTE else ''),
     f'- retomar a sessão: `{resume_cmd}`{resume_note}',
     f'- na volta: `bash .claude/utils/orchestration/restart-drain.sh --resume-check --session {SID}` (lista, apaga o marcador, arquiva este bilhete)', '',
     f'## Agentes em voo ({len(live) if agents_measured else "NÃO MEDIDOS"})', '']
if live:
    L += ['| id | descrição | classe | worktree | branch | último passo |', '|---|---|---|---|---|---|']
    for g in live:
        L.append('| ' + ' | '.join(tsvc(x).replace('|', '\\|') for x in (g['aid'], g['desc'], g['cls'], g['wt'] or '—', g['br'] or '—', g['step'])) + ' |')
    L += ['', 'Para cada agente, na volta: SendMessage com `to` = o id, texto «Reinício da sessão: retome de onde parou. '
          'Último passo: <o da tabela>. Confira o estado (git status, PR, CI) antes de repetir qualquer passo.»']
elif agents_measured: L.append('nenhum agente em voo nesta sessão.')
else: L.append('agentes NÃO MEDIDOS (ver «Não medido»): isto NÃO quer dizer «nenhum». Confira os transcripts em subagents/.')
L += ['', f'## Tarefas de fundo ({len(tasks)})', '']
L += [f'- {t["id"]} ({t["of"]}): {t["line"]} · morre com o processo: relance à mão se ainda for preciso' for t in tasks] or ['nenhuma tarefa de fundo viva.']
if old: L += ['', f'## Antigos, fora do bilhete ({len(old)})', '', f'Agentes não terminados e sem escrita há mais de {opt["stale"]} min (restos de vidas anteriores do processo):', '']
L += [f'- {g["aid"]} [{g["cls"]}, {g["age"]} min] {g["desc"]}' for g in old]
if gaps: L += ['', '## Não medido', ''] + [f'- {g}' for g in gaps]
with open(os.path.join(RDIR, f'{SID}.md'), 'w', encoding='utf-8') as f: f.write('\n'.join(L) + '\n')
print(f'📝 bilhete gravado: {RDIR}/{SID}.md ({len(live) if agents_measured else "NÃO MEDIDOS:"} agente(s) em voo, {len(tasks)} tarefa(s) de fundo) · {outcome}')
for g in live: print(f'   · {g["aid"]} [{g["cls"]}] {g["desc"]} · {g["wt"] or "—"} · {g["br"] or "—"} · {g["step"]}')
for g in gaps: print(f'   ⚠️ NÃO MEDIDO: {g}')
print(f'▶ retomar: {resume_cmd}{resume_note}')
sys.exit(5 if (gaps or mid_fail) else (3 if outcome.startswith('teto') else 0))
PY
