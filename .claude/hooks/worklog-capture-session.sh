#!/usr/bin/env bash
# SessionStart hook (Onion) — captura o session_id nativo do Claude Code e grava
# o resume_command no STATE.md do worklog ACTIVE, fechando o gap "session id não
# é auto-populável por comando" (ver docs/knowledge-base/concepts/worklog-protocol.md §2).
#
# Apenas side-effect; não emite saída. Safe no-op quando: não é repo git, branch
# sem prefixo (main/develop), ou não existe STATE.md. Nunca falha a sessão (exit 0).
#
# CORREÇÃO 2026-08-02 (medida, não hipótese): o filtro era `feature/*|hotfix/*|release/*` e
# resultava em NO-OP em 56 de 58 branches reais (96%) — o uso real migrou para prefixos de
# conventional-commit: docs/ (35), feat/ (10), fix/ (7), chore/ (4), feature/ (2). Consequência
# medida: session-lifecycle.jsonl com 1 linha em ~60 commits. Um instrumento de auto-observação
# calibrado para uma convenção que o próprio uso abandonou não observa nada — e sem ele NENHUM
# dogfood de campo é mensurável. O gate correto é a EXISTÊNCIA do STATE.md (linha 30), que é
# fato de filesystem, não o nome da branch, que é escolha do humano (acoplado ao ator).
input=$(cat 2>/dev/null) || exit 0

# session_id (jq se disponível; senão fallback grep/sed para JSON flat)
if command -v jq >/dev/null 2>&1; then
  sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
else
  sid=$(printf '%s' "$input" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi
[ -n "${sid:-}" ] || exit 0

# slug = branch sem o prefixo (qualquer um: feature/, feat/, fix/, docs/, chore/, hotfix/…)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
case "$branch" in
  */*) slug="${branch#*/}" ;;   # qualquer branch prefixada
  *)   exit 0 ;;                # main/develop/HEAD destacado — não têm worklog
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
