#!/usr/bin/env bash
# aside-router.sh — MOTOR do "Aparte do Maestro" (protocolo de entrada lateral / side-channel).
#
# O maestro injeta, no meio da sessão, um marcador tipado no INÍCIO da mensagem para rotear a
# intenção ao mecanismo certo SEM descarrilhar a tarefa. Este motor é DETERMINÍSTICO (sem LLM):
# detecta o marcador e imprime a DIRETIVA DE ROTA canônica (o wrapper aside-router-hook.sh a
# injeta como additionalContext no UserPromptSubmit).
#
# NOTA DE IDIOMA: "aside" = o aparte teatral (código = inglês). O nome-produto pt-BR é "Aparte do
# Maestro" e os MARCADORES são pt-BR (dúvida:/corrige:/…) — vocabulário de interação do maestro.
#
# DOUTRINA (respeitar — ver docs/knowledge-base/agentic-patterns/harness/maestro-aside.md):
#   • É RECALL, não gate: imprime o MAPA da rota, nunca bloqueia. Cláusula de julgamento embutida.
#   • Marcador de efeito irreversível (-etapa:, guarda-regra:) injeta PROPOR→CONFIRMAR (Ato 3/W6).
#   • Maestro é fonte CONFIÁVEL (R15.2): não envelopa como untrusted (isso é só p/ terceiros).
#   • DISPATCHER: roteia p/ diário/memória/STATE/orquestração que já existem — cria zero store.
#
# Uso:
#   aside-router.sh detect < prompt      # lê o prompt no stdin → imprime a diretiva (ou nada)
#   aside-router.sh detect "prompt..."   # ou como argumento
# Sem marcador → NADA no stdout, exit 0 (falso-negativo é inócuo; nunca descarrilha).
# Testável: fixtures em ${CLAUDE_PLUGIN_ROOT}/validation/fixtures/aside/ (registradas no lint-selftest.sh).
set -euo pipefail

SUFFIX="— rota canônica sugerida; use julgamento se conflitar. Isto é recall, não regra."
GATE="PROPONHA e aguarde a confirmação do maestro (Ato 3/W6) ANTES de executar."

route() {  # $1 = key
  case "$1" in
    QUESTION)   printf 'APARTE dúvida — pergunta lateral do maestro. Responda BREVE sem parar a tarefa; se exigir ferramenta, sugira /btw (fork "f"). Retome o fluxo em seguida. %s' "$SUFFIX" ;;
    CORRECTION) printf 'APARTE corrige — dica/correção/orientação sobre o curso. Se é p/ AGORA, reoriente o passo atual (o maestro pode ter dado Esc); se é p/ o próximo, aplique na próxima fronteira de passo. Não descarte o trabalho já feito. %s' "$SUFFIX" ;;
    PRAISE)     printf 'APARTE reforço — reforço positivo. Absorva o PORQUÊ; se revela identidade/preferência durável, registre via /onion:diary (significance). %s' "$SUFFIX" ;;
    NOTE)       printf 'APARTE nota — lembrete/aviso SÓ desta sessão. Anote no scratchpad/notes.md (parking-lot); NÃO é memória durável nem exige ação agora. %s' "$SUFFIX" ;;
    REMEMBER)   printf 'APARTE guarda — memória DURÁVEL. Escolha o tier: fato pessoal/de-ambiente ou estado-de-trabalho → memória do harness (auto-memory); aprendizado/decisão de rede → /onion:diary (conflict_class + review_after). Repo é fonte, memória é cache. %s' "$SUFFIX" ;;
    ADD_STEP)   printf 'APARTE +etapa — adicionar etapa ao plano. Insira no STATE.md (bloco NEXT)/plan; se altera escopo já commitado, PROPONHA antes. %s' "$SUFFIX" ;;
    DROP_STEP)  printf 'APARTE -etapa — remover/pular etapa. %s Não descarte trabalho sem OK. %s' "$GATE" "$SUFFIX" ;;
    PARALLEL)   printf 'APARTE paralelo — atividade/pesquisa em paralelo sem parar o fluxo. Dispare assíncrono (Ctrl+B/background) ou fan-out via onion-orchestration/Workflow; sintetize no retorno. Se escrever, respeite I3 (um escritor/repo). %s' "$SUFFIX" ;;
    GUARDRAIL)  printf 'APARTE guarda-regra — instalar guardrail durável de comportamento. %s Prefira forcing-function (hook / .claude/rules path-scoped), não prosa "never do X"; registre a decisão no /onion:diary. %s' "$GATE" "$SUFFIX" ;;
    *) return 0 ;;
  esac
  printf '\n'
}

detect() {
  local input line
  if [ "$#" -gt 0 ]; then input="$1"; else input="$(cat 2>/dev/null)" || input=""; fi
  # 1ª linha, sem espaços à esquerda
  line="$(printf '%s\n' "$input" | sed -n '1p')"
  line="${line#"${line%%[![:space:]]*}"}"
  [ -n "$line" ] || return 0

  # Ordem: mais específico primeiro (guarda-regra antes de guarda; ±etapa explícitos).
  # Canônicos exigem ':'; aliases fluídos (lembre-se / mandou bem / em paralelo / enquanto isso) aceitam ':' ou ','.
  local key=""
  if   printf '%s' "$line" | grep -qiE '^guarda-regra[[:space:]]*:';                  then key=GUARDRAIL
  elif printf '%s' "$line" | grep -qiE '^\+etapa[[:space:]]*:';                        then key=ADD_STEP
  elif printf '%s' "$line" | grep -qiE '^-etapa[[:space:]]*:';                         then key=DROP_STEP
  elif printf '%s' "$line" | grep -qiE '^(dúvida|duvida|pergunta)[[:space:]]*:';       then key=QUESTION
  elif printf '%s' "$line" | grep -qiE '^(corrige|dica|orienta)[[:space:]]*:';         then key=CORRECTION
  elif printf '%s' "$line" | grep -qiE '^(reforço|reforco)[[:space:]]*:';              then key=PRAISE
  elif printf '%s' "$line" | grep -qiE '^mandou bem[[:space:]]*,';                     then key=PRAISE
  elif printf '%s' "$line" | grep -qiE '^(nota|fyi|avisa)[[:space:]]*:';               then key=NOTE
  elif printf '%s' "$line" | grep -qiE '^(guarda|relembra)[[:space:]]*:';              then key=REMEMBER
  elif printf '%s' "$line" | grep -qiE '^lembre-se[[:space:]]*[:,]';                   then key=REMEMBER
  elif printf '%s' "$line" | grep -qiE '^(paralelo|pesquisa)[[:space:]]*:';            then key=PARALLEL
  elif printf '%s' "$line" | grep -qiE '^(em paralelo|enquanto isso)[[:space:]]*[:,]'; then key=PARALLEL
  else return 0
  fi
  route "$key"
}

case "${1:-}" in
  detect) shift; detect "$@" ;;
  ""|--help|-h)
    echo "uso: aside-router.sh detect [prompt]   (lê stdin se sem arg)" >&2
    exit 0 ;;
  *) echo "modo desconhecido: $1 (use 'detect')" >&2; exit 0 ;;
esac
