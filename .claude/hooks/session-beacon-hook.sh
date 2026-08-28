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

# Ponto de partida da sonda de DONO: o pai DESTE hook — o processo que sustenta a
# sessão (ou um shell logo abaixo dele). A sonda sobe daqui até achar o `claude`;
# passar explicitamente encurta a subida e não depende do formato do spawn.
export ONION_BEACON_OWNER_PID="$PPID"

case "$MODE" in
  up)
    bash "$SB" up "$REPO" "$sid" 2>/dev/null || true
    # SWEEP antes do CHECK: a metade que MATA fantasma não tinha gatilho nenhum — nada
    # no settings.json chamava `sweep`, então beacons órfãos/stale se acumulavam e
    # seguiam bloqueando. Medido no core: 23 beacons, 20 stale (achado adversarial
    # 2026-08-28). Varrer aqui é barato e roda antes de qualquer veredito ser emitido.
    bash "$SB" sweep "$REPO" 2>/dev/null || true
    others="$(bash "$SB" check "$REPO" --ignore "$sid" 2>/dev/null)" || {
      # exit 1 do check = há farol alheio aceso → avisar no boot (colisão W1×W2/W3)
      #
      # O AVISO SE APRESENTA COMO DECLARAÇÃO, NÃO COMO FATO (correção do maestro
      # 2026-08-28): "informado é diferente de verificado". A versão anterior afirmava
      # "OUTRA sessão viva" — e a sessão que lia isso tratava como fato consumado,
      # invocando I3 contra faróis que não tinham dono nenhum. O `check` agora ROTULA
      # (VIVA = dono medido · DECLARADA = não medido), mas o rótulo só vira conduta se
      # o aviso MANDAR verificar quem é e o que faz. Por isso a instrução viaja junto
      # da lista: quem recebe o aviso não tem como saber, sozinho, o que ele vale.
      msg="$(printf '%s' "$others" | grep '^🕯️' | tr '\n' '; ' | sed 's/"/\\"/g')"
      printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"🕯️ Onion farol: há OUTRO farol aceso neste repo — %s. ⚠️ ISTO É INFORMADO, NÃO VERIFICADO — farol é carimbo que a própria sessão escreveu. ANTES de tratar como escritor concorrente (I3), VERIFIQUE QUEM É E O QUE FAZ: (1) `bash .claude/validation/session-beacon.sh check .` e leia o rótulo — VIVA = dono medido vivo; DECLARADA = dono NAO medido, pode ser fantasma; (2) `NUNCA refrescou` = a sessão jamais recebeu um prompt (presença sem escritor — assinatura de conexão de Remote Control, resume abortado ou crash, e pode ser sua própria); (3) na dúvida, confirme com o maestro DE QUEM é a sessão. Só depois de verificado, coordene antes de checkout/escrita — e NÃO relate ao maestro como sessão alheia viva o que você não mediu."}}\n' "$msg"
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
