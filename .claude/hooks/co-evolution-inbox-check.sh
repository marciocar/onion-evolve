#!/usr/bin/env bash
# SessionStart hook (Onion) — "you have mail" BIDIRECIONAL + reflexão: avisa, no início da
# sessão, se há mensagens não-processadas nos canais de co-evolução e migalhas vencidas no diário:
#   • inbox/    → upstream (sinal/feedback). No core: chegando dos projetos. No consumidor: a relayar ao core.
#   • inbound/  → downstream (core→consumidor): relatório de adoção/update + anúncios. Só existe no consumidor.
#   • ⏰ diário → migalhas com review_after vencido (gatilho invariável de reflexão — ADR work-models §4; o campo review_after vem da RFC-0003 §2.3).
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

# ⏰ Gatilho invariável de reflexão (ADR work-models §4; campo review_after: RFC-0003 §2.3): conta migalhas do diário com
# review_after VENCIDO — learnings que precisam ser reavaliados (ainda válidos?).
# Comparação lexicográfica de datas ISO (AAAA-MM-DD) — determinístico, sem date-math.
count_overdue_diary() {
  local dir=".claude/diary" today f ra n=0
  [ -d "$dir" ] || { echo 0; return; }
  today="$(date +%F)"
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in index.md|readme.md) continue ;; esac
    ra="$(awk -F': *' '/^review_after:/{gsub(/["'"'"']/,"",$2); print $2; exit}' "$f" 2>/dev/null)"
    [ -n "$ra" ] && [ "$ra" \< "$today" ] && n=$((n+1))
  done
  echo "$n"
}

nb="$(count_unread docs/evolution/inbox)"     # upstream
na="$(count_unread docs/evolution/inbound)"   # downstream
nd="$(count_overdue_diary)"                   # reflexão (diário vencido)

msg=""
[ "${nb:-0}" -gt 0 ] 2>/dev/null && msg="📬 Onion co-evolução: ${nb} mensagem(ns) no inbox (upstream: sinal/feedback)."
[ "${na:-0}" -gt 0 ] 2>/dev/null && msg="${msg:+$msg }📥 Onion co-evolução: ${na} entrega(s) do core em inbound/ (downstream: relatório de update/anúncio)."
[ "${nd:-0}" -gt 0 ] 2>/dev/null && msg="${msg:+$msg }⏰ Onion diário: ${nd} migalha(s) com review_after vencido — reflexão pendente (/meta:diary list)."

[ -n "$msg" ] || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s Rode /meta:co-evolve para ler/gerenciar."}}\n' "$msg"
exit 0
