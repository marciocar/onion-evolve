#!/usr/bin/env bash
# SessionStart hook (Onion) — captura o session_id nativo do Claude Code e grava
# o resume_command no STATE.md do worklog ACTIVE, fechando o gap "session id não
# é auto-populável por comando" (ver docs/knowledge-base/concepts/worklog-protocol.md §2).
#
# Apenas side-effect; não emite saída. Safe no-op quando: não é repo git, branch
# não é feature/hotfix/release, ou não existe STATE.md. Nunca falha a sessão (exit 0).
input=$(cat 2>/dev/null) || exit 0

# session_id (jq se disponível; senão fallback grep/sed para JSON flat)
if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
else
  sid=$(printf '%s' "$input" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi
[ -n "${sid:-}" ] || exit 0

# slug = branch sem o prefixo GitFlow
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
case "$branch" in
  feature/*|hotfix/*|release/*) slug="${branch#*/}" ;;
  *) exit 0 ;;
esac

state=".claude/sessions/${slug}/STATE.md"
[ -f "$state" ] || exit 0

cmd="claude --resume ${sid}"
if grep -q '^resume_command:' "$state" 2>/dev/null; then
  # idempotente: só reescreve se o valor mudou
  grep -qx "resume_command: ${cmd}" "$state" 2>/dev/null && exit 0
  tmp=$(mktemp 2>/dev/null) || exit 0
  sed "s|^resume_command:.*|resume_command: ${cmd}|" "$state" > "$tmp" 2>/dev/null && mv "$tmp" "$state" 2>/dev/null
else
  printf '\n## Native transcript\nresume_command: %s\n' "$cmd" >> "$state" 2>/dev/null
fi
exit 0
