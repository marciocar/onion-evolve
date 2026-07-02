#!/usr/bin/env bash
# Hook do FAROL DE SESSÃO (Onion) — presença de sessão git-invisível + aviso de colisão.
#
# Registrado em .claude/settings.json com 1 argumento:
#   up      (SessionStart)      — acende o farol; se há OUTRA sessão viva, avisa 🕯️
#   refresh (UserPromptSubmit)  — refresca o heartbeat (silencioso)
#   down    (SessionEnd)        — apaga o farol
#
# Motor: .claude/validation/session-beacon.sh (testável no lint-selftest, modo session-beacon).
# Disciplina de motd: SILENCIOSO quando não há nada a dizer. Nunca falha a sessão (exit 0).
MODE="${1:-up}"
input=$(cat 2>/dev/null) || input=""

# session_id (mesmo fallback sem-jq do worklog-capture-session.sh)
if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
else
  sid=$(printf '%s' "$input" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi
[ -n "${sid:-}" ] || exit 0

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SB="$REPO/.claude/validation/session-beacon.sh"
[ -f "$SB" ] || exit 0

case "$MODE" in
  up)
    bash "$SB" up "$REPO" "$sid" 2>/dev/null || true
    others="$(bash "$SB" check "$REPO" --ignore "$sid" 2>/dev/null)" || {
      # exit 1 do check = há sessão VIVA alheia → avisar no boot (colisão W1×W2/W3)
      msg="$(printf '%s' "$others" | grep '^🕯️' | tr '\n' '; ' | sed 's/"/\\"/g')"
      printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"🕯️ Onion farol: OUTRA sessão viva neste repo — %s. Um escritor por repo (I3): coordene com o maestro antes de checkout/escrita."}}\n' "$msg"
    }
    ;;
  refresh)
    bash "$SB" up "$REPO" "$sid" 2>/dev/null || true
    ;;
  down)
    bash "$SB" down "$REPO" "$sid" 2>/dev/null || true
    ;;
esac
exit 0
