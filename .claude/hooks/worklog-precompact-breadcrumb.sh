#!/usr/bin/env bash
# PreCompact hook (Onion) — a saída do PreCompact é IGNORADA pós-compactação (não
# injeta contexto que sobrevive), então deixamos um breadcrumb DURÁVEL no notes.md
# do worklog ACTIVE. Na retomada, o drift-guard do /engineer/work cruza
# STATE.md.last_checkpoint com este marcador (ver worklog-protocol.md §7).
#
# Non-blocking; apenas side-effect. Safe no-op fora de um worklog ativo. Exit 0 sempre.
input=$(cat 2>/dev/null) || exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
case "$branch" in
  feature/*|hotfix/*|release/*) slug="${branch#*/}" ;;
  *) exit 0 ;;
esac

notes=".claude/sessions/${slug}/notes.md"
[ -f "$notes" ] || exit 0

if command -v jq >/dev/null 2>&1; then
  trig=$(printf '%s' "$input" | jq -r '.source // "?"' 2>/dev/null)
else
  trig="?"
fi
ts=$(date -u +%FT%TZ 2>/dev/null || echo "?")
printf '\n- ⚠️ [%s] compaction (%s) — verifique se STATE.md.NEXT reflete o último raciocínio antes de prosseguir.\n' "$ts" "${trig:-?}" >> "$notes" 2>/dev/null
exit 0
