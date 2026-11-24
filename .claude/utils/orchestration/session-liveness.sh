#!/usr/bin/env bash
# ===========================================================================
# session-liveness.sh — a REGRA ÚNICA de «sessão viva» das peças que leem a lista de peers do harness.
#
# ── POR QUE EXISTE (medido em 2026-11-24, Claude Code 2.1.331) ────────────────────────────────────────
# O ops/session-open.sh (core-only) e o .claude/validation/baton-pulse.sh tinham cada um a sua regra, e elas
# discordavam: o mesmo registro de fundo `kind: background, state: blocked`, SEM pid, criado dias antes, era «viva
# neste checkout» para o abridor (que recusou reabrir a sessão do core) e UNREACHABLE («sessão de fundo sem
# processo») para o pulso. O registro era morto: o daemon de fundo é transitório e o processo dele já tinha saído.
#
# ── A REGRA (uma só, para todos) ─────────────────────────────────────────────────────────────────
#   1. tem pid e o pid não existe (kill -0 dá ESRCH)        → MORTA  («pid N morto»: lista velha)
#   2. kind interactive                                      → VIVA   (o harness só lista interativa que roda)
#   3. de fundo (ou outro kind) COM pid vivo                 → VIVA   (kill -0 ok, ou EPERM: o processo existe)
#   4. de fundo (ou outro kind) SEM pid                      → MORTA  (registro do harness sem processo)
#   O `state` (working, blocked, idle…) NÃO decide: é o último estado que o harness gravou, e sobrevive ao processo.
#
# ── A CÓPIA (fork_inherit) ───────────────────────────────────────────────────────────────────────
# Mandar a sessão ao fundo nativo (a tecla ←) cria uma CÓPIA com id novo. Formato medido no transcript da cópia
# (~/.claude/projects/<pasta>/<id-novo>.jsonl): a 1ª linha é {"type":"history-suppression","cause":"fork_inherit",…}
# SEM o id de origem (com o `ts` do fork), e todo `sessionId` do histórico copiado é reescrito para o id novo. O que
# liga as duas é o `uuid` das mensagens: a cópia descende da origem quando um uuid HERDADO por ela (timestamp anterior ao
# `ts` do fork) está na parte PRÓPRIA da origem (o que a origem escreveu depois do próprio fork, ou tudo, se ela não é
# cópia). Só «estar na origem» não basta: o uuid herdado reaparece em filhas e irmãs mais novas, como herança delas. (O daemon grava a origem em
# ~/.claude/daemon/roster.json, `dispatch.launch.sessionId` com `fork: true`, mas só enquanto o worker vive: não é
# fonte durável, e é estado interno do harness.)
#
# Uso:
#   session-liveness.sh live <kind> <state> <pid>      rc 0 viva · 1 morta; imprime o motivo (uma linha)
#   session-liveness.sh classify [<arquivo.json>|-]    lê a lista do `claude agents --json` (padrão: stdin) e imprime,
#                                                      por entrada, TSV: sessionId kind state pid name cwd live short motivo
#                                                      (campo vazio vira «-»; live = live|dead; short = o `id` curto do
#                                                      harness, ou os 8 primeiros caracteres do sessionId)
#   session-liveness.sh fork-of <copia.jsonl> <origem.jsonl>
#                                                      rc 0 a cópia descende da origem, direta ou em cadeia
#                                                      (fork_inherit + uuid herdado na parte PRÓPRIA da origem)
#                                                      · 1 não descende (ou não é cópia; filha e irmã não são origem)
#                                                      · 2 não medido (arquivo ilegível, cópia sem ts, ou cópia
#                                                      recém-criada sem mensagem herdada)
# Saída: 0/1 como acima · 2 uso ou entrada ilegível (classify: JSON que não é lista).
# Só lê. Da cópia lê a herança até a 1ª mensagem nova (uuid e timestamp); da origem, a 1ª linha e a busca dos uuids (grep -F -f).
# Bancada: run_session_open_selftests, run_baton_pulse_selftests e run_restart_drain_selftests (lint-selftest.sh).
# ===========================================================================
set -uo pipefail

_usage() { printf 'uso: session-liveness.sh live <kind> <state> <pid> | classify [<arquivo.json>|-] | fork-of <copia.jsonl> <origem.jsonl>\n' >&2; exit 2; }
[ $# -ge 1 ] || _usage
cmd="$1"; shift
command -v python3 >/dev/null 2>&1 || { echo "session-liveness: python3 ausente" >&2; exit 2; }

case "${cmd}" in
  live|classify)
    [ "${cmd}" != live ] || [ $# -eq 3 ] || _usage
    [ "${cmd}" != classify ] || [ $# -le 1 ] || _usage
    exec python3 -I -c '
import json, os, sys

def pid_state(pid):
    """True vivo · False morto · None sem pid."""
    if pid in (None, "", "-", "None"): return None
    try: p = int(pid)
    except (TypeError, ValueError): return None
    if p <= 0: return False
    try: os.kill(p, 0); return True
    except ProcessLookupError: return False
    except PermissionError: return True       # existe, de outro dono
    except OverflowError: return False

def verdict(kind, state, pid):
    ps = pid_state(pid)
    if ps is False: return False, f"pid {pid} morto"
    if kind == "interactive": return True, "interativa listada pelo harness"
    if ps is True: return True, f"de fundo com pid {pid} vivo"
    st = state or "?"
    return False, f"sessão de fundo sem processo (state {st})"

mode = sys.argv[1]
if mode == "live":
    kind, state, pid = sys.argv[2:5]
    ok, why = verdict(kind, "" if state == "-" else state, pid)
    print(why); sys.exit(0 if ok else 1)

src = sys.argv[2] if len(sys.argv) > 2 else "-"
try:
    raw = sys.stdin.read() if src == "-" else open(src, encoding="utf-8").read()
    d = json.loads(raw or "null")
except (OSError, ValueError) as e:
    print(f"session-liveness: lista ilegível ({e})", file=sys.stderr); sys.exit(2)
if not isinstance(d, list):
    print("session-liveness: a lista de peers não é uma lista JSON", file=sys.stderr); sys.exit(2)
def cell(v): return "-" if v in (None, "") else str(v).replace("\t", " ").replace("\n", " ")
for x in d:
    if not isinstance(x, dict): continue
    sid = str(x.get("sessionId") or x.get("id") or "")
    if not sid: continue
    kind = str(x.get("kind") or ""); state = str(x.get("state") or ""); pid = x.get("pid")
    ok, why = verdict(kind, state, pid)
    short = str(x.get("id") or "") or sid[:8]
    print("\t".join(cell(v) for v in (sid, kind, state, pid, x.get("name"), x.get("cwd"), "live" if ok else "dead", short, why)))
' "${cmd}" "$@"
    ;;
  fork-of)
    [ $# -eq 2 ] || _usage
    exec python3 -I -c '
import json, os, subprocess, sys, tempfile
copy, origin = sys.argv[1:3]
# A cópia DESCENDE da origem quando um uuid HERDADO pela cópia está na parte PRÓPRIA da origem: o que a origem escreveu
# depois do próprio fork (todo o transcript, se a origem não é cópia). O uuid herdado reaparece em toda descendente e
# em toda irmã mais nova, mas lá ele é HERANÇA (timestamp anterior ao ts do fork delas), nunca parte própria. Assim a
# relação é ASSIMÉTRICA: filha e irmã não saem como origem. E a cadeia vale: a neta casa com a avó pelo que a avó
# escreveu antes do fork da mãe. (Medido em 2026-11-24: o 1º uuid se repete em irmãs; o último herdado reaparece na filha.)
def head(path):
    """→ (é cópia, ts do fork ou None) pela 1ª linha JSON do transcript."""
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try: o = json.loads(line)
            except ValueError: continue
            if not isinstance(o, dict): continue
            if o.get("type") == "history-suppression" and o.get("cause") == "fork_inherit":
                return True, (o.get("ts") if isinstance(o.get("ts"), str) else None)
            return False, None
    return False, None
try:
    is_copy, fork_ts = head(copy)
    if not is_copy: sys.exit(1)   # não é cópia
    if not fork_ts:
        print("session-liveness: cópia sem o ts do fork: origem NÃO medida", file=sys.stderr); sys.exit(2)
    inherited = []   # (uuid, timestamp) herdados pela cópia, até a 1ª mensagem nova dela
    with open(copy, encoding="utf-8", errors="replace") as f:
        next(f, None)
        for line in f:
            line = line.strip()
            if not line: continue
            try: o = json.loads(line)
            except ValueError: continue
            if not isinstance(o, dict): continue
            u = o.get("uuid"); t = o.get("timestamp")
            if not (isinstance(u, str) and u): continue
            if isinstance(t, str) and t >= fork_ts: break   # 1ª mensagem nova da cópia: a herança acabou
            inherited.append((u, t if isinstance(t, str) else None))
except OSError as e:
    print(f"session-liveness: cópia ilegível ({e})", file=sys.stderr); sys.exit(2)
if not inherited:
    # cópia recém-criada, só com a linha history-suppression: ainda não há o que casar
    print("session-liveness: cópia sem mensagem herdada ainda: origem NÃO medida", file=sys.stderr); sys.exit(2)
try: o_copy, o_ts = head(origin)
except OSError as e:
    print(f"session-liveness: origem ilegível ({e})", file=sys.stderr); sys.exit(2)
if o_copy and not o_ts:
    print("session-liveness: origem é cópia sem o ts do fork: NÃO medida", file=sys.stderr); sys.exit(2)
# só o que a origem escreveu DEPOIS do próprio fork é parte própria dela
cand = [u for u, t in inherited if (not o_copy) or (t is not None and t >= o_ts)]
if not cand: sys.exit(1)
with tempfile.NamedTemporaryFile("w", suffix=".pat", delete=False) as pf:
    pf.write("".join("\"uuid\":\"" + u + "\"\n" for u in cand)); pat = pf.name
try: r = subprocess.run(["grep", "-a", "-q", "-F", "-f", pat, "--", origin])
finally: os.unlink(pat)
sys.exit(0 if r.returncode == 0 else (1 if r.returncode == 1 else 2))
' "$@"
    ;;
  *) _usage ;;
esac
