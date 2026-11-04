#!/usr/bin/env bash
# hook_veto.sh — hook pre-tool dos spikes de veto (Qwen Code e Mistral Vibe).
#
# Uso:  hook_veto.sh <MODE> <LOG_ABS> [ROLE]   (ou via env SPIKE_HOOK_MODE / SPIKE_HOOK_LOG)
#       ROLE = main (default) | probe. O probe é um log_allow posto ANTES do hook em
#       falha na mesma config: a linha dele prova que a config foi carregada.
#
# PRIMEIRO grava (antes de decidir qualquer coisa) uma linha JSON no LOG com o stdin
# recebido, o carimbo de tempo e o modo; depois decide pelo MODE e grava uma 2ª linha
# com a decisão. O LOG fica FORA da pasta de trabalho (caminho absoluto).
#
# Modos:
#   log_allow       controle: permite (exit 0, stdout vazio)
#   deny_exit2      estilo Claude/Qwen: motivo no stderr + exit 2
#   deny_json       estilo Vibe: stdout {"decision":"deny","reason":...}, exit 0
#                   (esquema lido de mistralai_vibe_local_harness/vibe/_foreign_hooks.py,
#                   _interpret_stdout: parsed.get("decision") == "deny" + "reason")
#   deny_json_qwen  estilo Qwen/Claude por JSON: hookSpecificOutput.permissionDecision
#                   "deny", exit 0 (PreToolUseHookOutput.getPermissionDecision no bundle)
#   exit1           erro interno: exit 1
#   sleep           dorme 300 s (o timeout do hook na config é 5 s), depois permite;
#                   o classify mede o intervalo entre a entrada do hook e a próxima
#                   requisição do harness ao stub (o momento em que ele seguiu)
#   nonjson         exit 0 com stdout não vazio e não JSON ("nope")
#   empty           exit 0 com stdout vazio (célula S3e)
#   deny_target_exit2 / deny_target_json   (rodada 2) negam SÓ a chamada-alvo do cenário
#                   (o 4º argumento): o mesmo target_in do classify.py (push no c/sub/ts/proc/tc/
#                   tcd; MARKER.txt no w/w2/mcp). As demais chamadas do roteiro (tool_search,
#                   agent, agents.spawn...) passam com "allow_not_target". Sem o cenário, nega tudo.
#   bash_only       S1-tn-script: o script compara tool_name == "Bash" (matcher "*");
#                   nega (exit 2) só nesse caso, qualquer outro nome passa.
#                   (S1-tn-matcher não é modo do script: é a config com matcher "Bash"
#                   + deny_exit2/deny_json, montada pelo run_cell.sh.)
#
# Toda negação grava DUAS linhas: "deny-intent" antes de escrever a resposta e
# "deny-done" depois; o classify só aceita a negação com "deny-done".
#
# O caso "script ausente" não usa este arquivo: a config aponta um caminho inexistente.
# Todo veto carrega o texto único ONION-SPIKE-VETO.
set -u

MODE="${1:-${SPIKE_HOOK_MODE:-}}"
LOG="${2:-${SPIKE_HOOK_LOG:-}}"
ROLE="${3:-main}"
SCENARIO="${4:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REASON="ONION-SPIKE-VETO: blocked by onion spike hook (mode=${MODE})"

if [ -z "$MODE" ] || [ -z "$LOG" ]; then
  echo "hook_veto.sh: MODE and LOG are required" >&2
  exit 1
fi
case "$LOG" in
  /*) ;;
  *) echo "hook_veto.sh: LOG must be absolute" >&2; exit 1 ;;
esac

STDIN_RAW="$(cat)"

# Registro 1/2: chegada (stdin bruto + tool_name extraído), antes de qualquer decisão.
log_line() {
  # $1 = phase, $2 = decision (pode ser vazio); stdin do python = STDIN_RAW
  printf '%s' "$STDIN_RAW" | python3 -I -c '
import json, os, sys, time
phase, decision, mode, log, role = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
raw = sys.stdin.read()
try:
    parsed = json.loads(raw)
except Exception:
    parsed = None
tool = parsed.get("tool_name") if isinstance(parsed, dict) else None
rec = {"ts": time.time(), "ts_iso": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
       "phase": phase, "mode": mode, "role": role, "pid": os.getpid(), "ppid": os.getppid(),
       "tool_name": tool, "decision": decision or None}
if phase == "start":
    rec["stdin"] = parsed if parsed is not None else raw
with open(log, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
' "$1" "$2" "$MODE" "$LOG" "$ROLE"
}

log_line start ""

TOOL_NAME="$(printf '%s' "$STDIN_RAW" | python3 -I -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_name") or "")
except Exception:
    print("")
')"

case "$MODE" in
  log_allow)
    log_line decision allow
    exit 0
    ;;
  deny_exit2)
    log_line decision deny-intent
    echo "$REASON" >&2
    log_line decision deny-done
    exit 2
    ;;
  deny_json)
    log_line decision deny-intent
    python3 -I -c 'import json,sys; print(json.dumps({"decision": "deny", "reason": sys.argv[1]}))' "$REASON"
    log_line decision deny-done
    exit 0
    ;;
  deny_json_qwen)
    log_line decision deny-intent
    python3 -I -c 'import json,sys; print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": sys.argv[1]}}))' "$REASON"
    log_line decision deny-done
    exit 0
    ;;
  exit1)
    log_line decision error_exit1
    echo "spike internal error (exit 1)" >&2
    exit 1
    ;;
  sleep)
    log_line decision sleeping
    sleep 300
    log_line decision allow_after_sleep
    exit 0
    ;;
  nonjson)
    log_line decision nonjson
    echo "nope"
    exit 0
    ;;
  empty)
    log_line decision empty
    exit 0
    ;;
  deny_target_exit2|deny_target_json)
    IS_TARGET=1
    if [ -n "$SCENARIO" ]; then
      IS_TARGET="$(printf '%s' "$STDIN_RAW" | python3 -I -c '
import json, sys
sys.path.insert(0, sys.argv[1])
from classify import target_in, TARGET_KIND
try:
    st = json.load(sys.stdin)
except Exception:
    print(1); sys.exit(0)        # stdin ilegível: nega (fecha)
# Emenda R2-1 (kg-ssot B3): só libera com stdin objeto, tool_input presente e cenário conhecido
if not isinstance(st, dict) or "tool_input" not in st or sys.argv[2] not in TARGET_KIND:
    print(1); sys.exit(0)
print(1 if target_in(st["tool_input"], sys.argv[2]) else 0)
' "$HERE" "$SCENARIO")"
    fi
    # Emenda R2-1 (curadoria 11, kg-ssot B3): libera SÓ com a saída exatamente "0"; Python que
    # caiu, saída vazia ou qualquer outra coisa nega (fecha)
    if [ "$IS_TARGET" = "0" ]; then
      log_line decision allow_not_target
      exit 0
    fi
    log_line decision deny-intent
    if [ "$MODE" = "deny_target_exit2" ]; then
      echo "$REASON" >&2
      log_line decision deny-done
      exit 2
    fi
    python3 -I -c 'import json,sys; print(json.dumps({"decision": "deny", "reason": sys.argv[1]}))' "$REASON"
    log_line decision deny-done
    exit 0
    ;;
  bash_only)
    if [ "$TOOL_NAME" = "Bash" ]; then
      log_line decision deny-intent
      echo "$REASON" >&2
      log_line decision deny-done
      exit 2
    fi
    log_line decision allow_not_bash
    exit 0
    ;;
  *)
    log_line decision unknown_mode
    echo "hook_veto.sh: unknown mode $MODE" >&2
    exit 1
    ;;
esac
