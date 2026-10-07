#!/usr/bin/env bash
# Hook do "APARTE DO MAESTRO" (Onion) — roteia entrada lateral tipada do maestro.
#
# Registrado em .claude/settings.json no array UserPromptSubmit (ao lado do farol de sessão).
# Fluxo: lê o prompt → o motor ${CLAUDE_PLUGIN_ROOT}/validation/aside-router.sh detecta o marcador tipado no
# INÍCIO da mensagem → injeta a DIRETIVA DE ROTA como additionalContext (recall, não gate).
#
# Disciplina de motd: SILENCIOSO quando não há marcador (custo-zero). NUNCA bloqueia (sem exit 2 —
# o maestro é fonte confiável, R15.2). NUNCA falha a sessão (exit 0 sempre).
# Doutrina completa: docs/knowledge-base/agentic-patterns/harness/maestro-aside.md
set -uo pipefail

input="$(cat 2>/dev/null)" || input=""

# extrai .prompt (jq com fallback grep sem-jq, na linha do session-beacon-hook.sh)
if command -v jq >/dev/null 2>&1; then
  prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)"
else
  prompt="$(printf '%s' "$input" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"prompt"[[:space:]]*:[[:space:]]*"//; s/"$//')"
fi
[ -n "${prompt:-}" ] || exit 0

# O motor é resolvido a partir do PRÓPRIO diretório do hook: no core, .claude/hooks → ${CLAUDE_PLUGIN_ROOT}/validation;
# no plugin instalado, hooks/ → validation/. Medido 2026-09-04: a forma antiga ("$REPO/${CLAUDE_PLUGIN_ROOT}/validation/…")
# virava "$REPO/${CLAUDE_PLUGIN_ROOT}/…" após o PATH-PORTABILITY do assembler — caminho sempre inválido, e o
# `[ -f ] || exit 0` abaixo escondia o defeito: o aparte do maestro estava MORTO e SILENCIOSO no plugin.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="${HERE}/../validation/aside-router.sh"
[ -f "$ENGINE" ] || exit 0

route="$(printf '%s' "$prompt" | bash "$ENGINE" detect 2>/dev/null)" || route=""
[ -n "$route" ] || exit 0   # sem marcador → silêncio (custo-zero)
# APARTE + WORKFLOW NO MESMO TURNO (sinal de um adotante, 2026-10-07): o harness repassa a TODO agente de um
# Workflow a ÚLTIMA mensagem do usuário no instante do disparo, mandando-a vencer a tarefa computada. Um aparte
# respondido e seguido de `Workflow(...)` no mesmo turno virou o pedido de um run inteiro (4,59M tokens, nenhum
# grafo). "Responda breve sem parar a tarefa" foi exatamente o que disparou o run — por isso o aviso vai junto.
route="${route} ⚠️ Se um Workflow estava para ser disparado neste turno, dispare-o só no PRÓXIMO turno: o harness repassa esta mensagem a todo agente do run como o pedido que vence a tarefa."

if command -v jq >/dev/null 2>&1; then
  jq -cn --arg ctx "$route" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
else
  esc="$(printf '%s' "$route" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$esc"
fi
exit 0
