#!/usr/bin/env bash
# SessionStart hook (Onion) — "you have mail" BIDIRECIONAL: avisa, no início da sessão,
# se há mensagens não-processadas nos canais de co-evolução. Cobre os DOIS sentidos:
#   • inbox/    → upstream (sinal/feedback). No core: chegando dos projetos. No consumidor: a relayar ao core.
#   • inbound/  → downstream (core→consumidor): relatório de adoção/update + anúncios. Só existe no consumidor.
# É o primitivo "motd/mail on login" do modelo de co-evolução (ver docs/evolution/README.md).
#
# Determinístico (sem LLM). SILENCIOSO quando 0 mensagens em ambos os canais (disciplina de motd —
# não encher saco). Nunca falha a sessão (exit 0 sempre). O nome do arquivo é mantido por estabilidade
# do registro em settings.json de todos os consumidores já adotados (cobre ambos os canais apesar do nome).
#
# "Não processada" = .md de 1º nível no canal (exclui _processed/ e README).
count_unread() {  # $1 = diretório do canal
  [ -d "$1" ] || { echo 0; return; }
  find "$1" -maxdepth 1 -type f -name '*.md' ! -iname 'readme.md' 2>/dev/null | wc -l | tr -d '[:space:]'
}

nb="$(count_unread docs/evolution/inbox)"     # upstream
na="$(count_unread docs/evolution/inbound)"   # downstream

msg=""
[ "${nb:-0}" -gt 0 ] 2>/dev/null && msg="📬 Onion co-evolução: ${nb} mensagem(ns) no inbox (upstream: sinal/feedback)."
[ "${na:-0}" -gt 0 ] 2>/dev/null && msg="${msg:+$msg }📥 Onion co-evolução: ${na} entrega(s) do core em inbound/ (downstream: relatório de update/anúncio)."

[ -n "$msg" ] || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s Rode /meta:co-evolve para ler/gerenciar."}}\n' "$msg"
exit 0
