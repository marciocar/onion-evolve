#!/usr/bin/env bash
# SessionStart hook (Onion) — "you have mail": avisa, no início da sessão, se há
# mensagens NÃO processadas no inbox de co-evolução (docs/evolution/inbox/).
# É o primitivo "motd/mail on login" do modelo de co-evolução (ver docs/evolution/README.md).
#
# Determinístico (sem LLM). SILENCIOSO quando 0 mensagens ou inbox inexistente
# (disciplina de motd — não encher saco). Nunca falha a sessão (exit 0 sempre).
#
# "Não processada" = .md de 1º nível em docs/evolution/inbox/ (exclui _processed/ e README).
inbox="docs/evolution/inbox"
[ -d "$inbox" ] || exit 0

n=$(find "$inbox" -maxdepth 1 -type f -name '*.md' ! -iname 'readme.md' 2>/dev/null | wc -l | tr -d '[:space:]')
[ "${n:-0}" -gt 0 ] 2>/dev/null || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"📬 Onion co-evolução: %s mensagem(ns) no inbox (docs/evolution/inbox/) — rode /meta:co-evolve para ler/gerenciar."}}\n' "$n"
exit 0
