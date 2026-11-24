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
# SEM o id de origem, e todo `sessionId` do histórico copiado é reescrito para o id novo. O que liga as duas é o
# `uuid` das mensagens: o 1º `uuid` da cópia está, idêntico, no transcript da origem. (O daemon grava a origem em
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
#                                                      rc 0 a cópia descende da origem (fork_inherit + 1º uuid presente
#                                                      na origem) · 1 não descende · 2 não medido (arquivo ilegível)
# Saída: 0/1 como acima · 2 uso ou entrada ilegível (classify: JSON que não é lista).
# Só lê. Do transcript lê a 1ª linha e o 1º uuid da cópia; na origem procura só aquele uuid (grep -F), nunca a conversa.
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
import json, subprocess, sys
copy, origin = sys.argv[1:3]
try:
    with open(copy, encoding="utf-8", errors="replace") as f:
        first = None; uid = None
        for i, line in enumerate(f):
            if i >= 400: break
            line = line.strip()
            if not line: continue
            try: o = json.loads(line)
            except ValueError: continue
            if not isinstance(o, dict): continue
            if first is None: first = o
            if isinstance(o.get("uuid"), str) and o["uuid"]: uid = o["uuid"]; break
except OSError as e:
    print(f"session-liveness: cópia ilegível ({e})", file=sys.stderr); sys.exit(2)
if not first or first.get("type") != "history-suppression" or first.get("cause") != "fork_inherit" or not uid: sys.exit(1)
try: open(origin, "rb").close()
except OSError as e:
    print(f"session-liveness: origem ilegível ({e})", file=sys.stderr); sys.exit(2)
needle = "\"uuid\":\"" + uid + "\""
r = subprocess.run(["grep", "-a", "-q", "-F", "--", needle, origin])
sys.exit(0 if r.returncode == 0 else (1 if r.returncode == 1 else 2))
' "$@"
    ;;
  *) _usage ;;
esac
