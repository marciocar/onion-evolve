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
# ── MODO `prompt` (UserPromptSubmit, 2026-11-09) ────────────────────────────────────────────────
# Sem o argumento isto é o SessionStart. Com `prompt`, só importa o spool do carteiro: sinal que chega numa
# sessão longa ficava parado em silêncio até a próxima sessão, porque o spool mora fora dos repos e a campainha
# só olha inbox/ e inbound/. Depois da importação o arquivo está no inbox/, e a campainha o vê no tick seguinte.
# Sai ANTES do pull do bridge e das contagens: 1 teste de diretório com o spool vazio (~25 ms medidos, sem rede).
# Fala quando algo entrou, com a contagem e nada do conteúdo. Sinal retido (ilegível, link, homônimo commitado) avisa
# uma vez por sessão e contagem, para não virar uma linha por prompt nem ficar calado para sempre. Fica descoberto: sessão ociosa e turno longo
# (não há prompt que dispare), e subagente (não recebe UserPromptSubmit).
if [ "${1:-}" = "prompt" ]; then
  _sh="${CLAUDE_PROJECT_DIR:-.}/.claude/utils/co-evolution/spool-import.sh"
  [ -f "$_sh" ] || exit 0
  _out="$(bash "$_sh" --hook --repo "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null)" || true
  case "$_out" in
    "imported="[1-9]*)
      _n="${_out#imported=}"; _n="${_n%% *}"
      printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"📬 Onion co-evolução: %s sinal(is) chegou(aram) pelo spool do carteiro ao inbox/. Rode /meta:co-evolve para ler/gerenciar."}}\n' "$_n"
      ;;
    *"pending="[1-9]*)
      _p="${_out##*pending=}"
      _state="${ONION_SPOOL_NOTICE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/onion-spool-notice}"
      mkdir -p "$_state" 2>/dev/null || true
      _mark="$_state/${CLAUDE_CODE_SESSION_ID:-nosession}-$_p"
      [ -e "$_mark" ] && exit 0
      [ -L "$_mark" ] && exit 0
      ( set -C; : > "$_mark" ) 2>/dev/null || true   # noclobber: nunca escreve através de um link
      printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"📮 Onion co-evolução: %s sinal(is) retido(s) no spool do carteiro (homônimo já commitado, link ou erro de leitura; /meta:co-evolve mostra o motivo)."}}\n' "$_p"
      ;;
  esac
  exit 0
fi

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
    # superada (`superseded: true` no frontmatter) não vence mais — o mesmo critério do diary-index.sh
    awk '/^---/{c++; next} c==1 && /^superseded:[[:space:]]*true/{f=1; exit} END{exit !f}' "$f" 2>/dev/null && continue
    ra="$(awk -F': *' '/^review_after:/{gsub(/["'"'"']/,"",$2); print $2; exit}' "$f" 2>/dev/null)"
    [ -n "$ra" ] && [ "$ra" \< "$today" ] && n=$((n+1))
  done
  echo "$n"
}

# ── PULL DOWNSTREAM antes de contar (ADR transport-pull D1) ───────────────────
# Puxa do core os anúncios deste membro ANTES da contagem, para o 📥 refletir o que
# existe agora — e não o que sobrou da última cópia manual.
#
# Três exigências que brigam entre si, resolvidas por construção:
#   1. NÃO PODE TRAVAR  → `timeout` duro; sem ele, um bridge lento congela toda sessão.
#   2. NÃO PODE FALHAR  → tudo sob `|| true`; rede fora do ar não é motivo para a sessão
#                         do adotante não abrir. O que já está em disco continua contando.
#   3. NÃO PODE CUSTAR  → sem credencial no ambiente, sai em 4 testes de variável e ZERO
#                         syscall de rede. É o caso de todo adotante ainda não configurado,
#                         ou seja: comportamento inalterado para quem não optou.
pull_inbox() {
  local sh="${CLAUDE_PROJECT_DIR:-.}/.claude/utils/federation-transport/inbox-pull.sh"
  [ -f "$sh" ] || return 0
  # .env do adotante é a fonte das credenciais; ausente = não configurado = silêncio.
  # O arquivo é DADO, nunca código: sem `source`, só as chaves ONION_FED_*. Nada mais entra no ambiente do hook.
  [ -f .env ] && while IFS= read -r _l || [ -n "$_l" ]; do
    _l="${_l%$'\r'}"; _l="${_l#"${_l%%[![:space:]]*}"}"; _l="${_l#export }"; _l="${_l#"${_l%%[![:space:]]*}"}"
    _k="${_l%%=*}"; _v="${_l#*=}"
    case "$_k" in ONION_FED_*[!A-Z0-9_]*|"") continue ;; ONION_FED_*) ;; *) continue ;; esac
    # a forma documentada em docs/evolution/README.md: entre aspas vale até a aspa; sem aspas, `#` só comenta depois de espaço
    case "$_v" in
      \"*\"*) _v="${_v#\"}"; _v="${_v%%\"*}" ;;
      \'*\'*) _v="${_v#\'}"; _v="${_v%%\'*}" ;;
      *) _v="${_v%%[[:space:]]#*}"; _v="${_v%"${_v##*[![:space:]]}"}" ;;
    esac
    export "$_k=$_v"
  done < .env
  [ -n "${ONION_FED_CLIENT_ID:-}" ] && [ -n "${ONION_FED_CLIENT_SECRET:-}" ] \
    && [ -n "${ONION_FED_ORG_ID:-}" ] && [ -n "${ONION_FED_MEMBER:-}" ] || return 0
  command -v timeout >/dev/null 2>&1 || return 0
  timeout "${ONION_FED_TIMEOUT:-20}" bash "$sh" --apply >/dev/null 2>&1 || true
}
pull_inbox

# ── IMPORTA O SPOOL do carteiro antes de contar (F7, 2026-11-07) ─────────────────────────────────
# O remetente com o sandbox do Claude Code ligado pode não conseguir escrever no inbox/ daqui (uma regra
# Edit(//<este repo>/**) no deny dele vira denyWrite e cobre a exceção do inbox); aí o co-relay.sh deixa o
# sinal num spool fora dos repos, e é esta sessão que o traz. Sem spool, 1 teste de diretório e nada mais.
# Mesmas exigências do pull: não trava (local, sem rede), não falha (|| true), não custa.
import_spool() {
  local sh="${CLAUDE_PROJECT_DIR:-.}/.claude/utils/co-evolution/spool-import.sh" out
  [ -f "$sh" ] || return 0
  out="$(bash "$sh" --hook --repo "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null)" || true
  case "$out" in *"pending="[1-9]*) np="${out##*pending=}" ;; esac
  return 0
}
np=0
import_spool

nb="$(count_unread docs/evolution/inbox)"     # upstream
na="$(count_unread docs/evolution/inbound)"   # downstream
nd="$(count_overdue_diary)"                   # reflexão (diário vencido)

msg=""
[ "${nb:-0}" -gt 0 ] 2>/dev/null && msg="📬 Onion co-evolução: ${nb} mensagem(ns) no inbox (upstream: sinal/feedback)."
[ "${na:-0}" -gt 0 ] 2>/dev/null && msg="${msg:+$msg }📥 Onion co-evolução: ${na} entrega(s) do core em inbound/ (downstream: relatório de update/anúncio)."
[ "${np:-0}" -gt 0 ] 2>/dev/null && msg="${msg:+$msg }📮 Onion co-evolução: ${np} sinal(is) retido(s) no spool do carteiro (homônimo já commitado, link ou erro de leitura; /meta:co-evolve)."
[ "${nd:-0}" -gt 0 ] 2>/dev/null && msg="${msg:+$msg }⏰ Onion diário: ${nd} migalha(s) com review_after vencido — reflexão pendente (/meta:diary list)."

[ -n "$msg" ] || exit 0
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s Rode /meta:co-evolve para ler/gerenciar."}}\n' "$msg"
exit 0
