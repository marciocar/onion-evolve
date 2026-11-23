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
#   aside-router.sh task-map [--check]   # lista o mapa da rota `tarefa:` (intenção → comando) com o caminho
#                                        # resolvido e se existe; --check sai 1 se algum comando do mapa sumiu
# Sem marcador → NADA no stdout, exit 0 (falso-negativo é inócuo; nunca descarrilha).
# Testável: fixtures em .claude/validation/fixtures/aside/ (registradas no lint-selftest.sh).
set -euo pipefail

SUFFIX="— rota canônica sugerida; use julgamento se conflitar. Isto é recall, não regra."
GATE="PROPONHA e aguarde a confirmação do maestro (Ato 3/W6) ANTES de executar."

# Raiz da maquinaria a partir do PRÓPRIO motor: no core, .claude/validation → .claude; no plugin, validation/ → raiz
# do plugin. Mesma resolução do hook (2026-09-04: caminho montado a partir do repo morria em silêncio no plugin).
# CDPATH= : com CDPATH no ambiente o `cd` relativo imprime o destino e a variável ganharia duas linhas (revisão 2026-11-20).
MACHINERY_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"

# Mapa da rota `tarefa:` — intenção → peça do inventário. É DADO, não prosa: a rota só cita a peça cujo arquivo
# EXISTE nesta instalação (o plugin e as portas não levam tudo), e a bancada `aside_router_task` reprova no core
# a linha cujo comando sumiu — a lista não envelhece calada. Ref `cat:nome` → commands/cat/nome.md;
# `skill:nome` → skills/nome/SKILL.md. Medição que gerou a categoria (2026-11-20): 43 de 1441 turnos do maestro
# levaram a sessão a chamar uma Skill; nos 232 apartes roteados, 3.
TASK_MAP='decisão do maestro|meta:decide
peça nova (comando, agente, skill)|meta:forge
guarda (hook ou check)|meta:forge-guard
feature ou código|engineer:plan
objeto externo (ferramenta, prática, ator)|meta:dissect
pesquisa ou estado da arte|skill:onion-research
plano longo até o fim|meta:drive
dúvida de desenho contra o mercado|meta:peek'

ref_path() {  # $1 = ref → caminho do arquivo que a materializa
  case "$1" in
    skill:*) printf '%s/skills/%s/SKILL.md' "$MACHINERY_ROOT" "${1#skill:}" ;;
    *:*)     printf '%s/commands/%s/%s.md' "$MACHINERY_ROOT" "${1%%:*}" "${1#*:}" ;;
    *)       printf '%s/commands/%s.md' "$MACHINERY_ROOT" "$1" ;;
  esac
}

ref_label() {  # $1 = ref → como a sessão invoca
  case "$1" in skill:*) printf 'skill %s' "${1#skill:}" ;; *) printf '/%s' "$1" ;; esac
}

task_choices() {  # imprime "intenção → /cmd · …" só com o que existe; vazio se nada existe
  local intent ref out=""
  while IFS='|' read -r intent ref; do
    [ -n "$ref" ] || continue
    [ -f "$(ref_path "$ref")" ] || continue
    out="${out:+${out} · }${intent} → $(ref_label "$ref")"
  done <<< "$TASK_MAP"
  printf '%s' "$out"
}

task_map() {  # $1 = --check (opcional): sai 1 se algum ref do mapa não existe
  local intent ref p missing=0
  while IFS='|' read -r intent ref; do
    [ -n "$ref" ] || continue
    p="$(ref_path "$ref")"
    if [ -f "$p" ]; then printf 'ok\t%s\t%s\n' "$ref" "$p"; else printf 'MISSING\t%s\t%s\n' "$ref" "$p"; missing=1; fi
  done <<< "$TASK_MAP"
  if [ "${1:-}" = "--check" ] && [ "$missing" -eq 1 ]; then return 1; fi
  return 0
}

route() {  # $1 = key
  case "$1" in
    QUESTION)   printf 'APARTE dúvida — pergunta lateral do maestro. Responda BREVE sem parar a tarefa; se exigir ferramenta, sugira /btw (fork "f"). Retome o fluxo em seguida. %s' "$SUFFIX" ;;
    CORRECTION) printf 'APARTE corrige — dica/correção/orientação sobre o curso. Se é p/ AGORA, reoriente o passo atual (o maestro pode ter dado Esc); se é p/ o próximo, aplique na próxima fronteira de passo. Não descarte o trabalho já feito. %s' "$SUFFIX" ;;
    PRAISE)     printf 'APARTE reforço — reforço positivo. Absorva o PORQUÊ; se revela identidade/preferência durável, registre via /meta:diary (significance). %s' "$SUFFIX" ;;
    NOTE)       printf 'APARTE nota — lembrete/aviso SÓ desta sessão. Anote no scratchpad/notes.md (parking-lot); NÃO é memória durável nem exige ação agora. %s' "$SUFFIX" ;;
    REMEMBER)   printf 'APARTE guarda — memória DURÁVEL. Escolha o tier: fato pessoal/de-ambiente ou estado-de-trabalho → memória do harness (auto-memory); aprendizado/decisão de rede → /meta:diary (conflict_class + review_after). Repo é fonte, memória é cache. %s' "$SUFFIX" ;;
    ADD_STEP)   printf 'APARTE +etapa — adicionar etapa ao plano. Insira no STATE.md (bloco NEXT)/plan; se altera escopo já commitado, PROPONHA antes. %s' "$SUFFIX" ;;
    DROP_STEP)  printf 'APARTE -etapa — remover/pular etapa. %s Não descarte trabalho sem OK. %s' "$GATE" "$SUFFIX" ;;
    PARALLEL)   printf 'APARTE paralelo — atividade/pesquisa em paralelo sem parar o fluxo. Dispare assíncrono (Ctrl+B/background) ou fan-out via onion-orchestration/Workflow; sintetize no retorno. Se escrever, respeite I3 (um escritor/repo). %s' "$SUFFIX" ;;
    TASK)
      local choices; choices="$(task_choices)"
      [ -n "$choices" ] || choices="nenhuma peça do mapa achada pelo caminho do core (num plugin os comandos vivem como /<plugin>:<cmd>: confira a lista de comandos instalados antes de dizer que falta peça)"
      printf 'APARTE tarefa — execute PELA maquinaria do Onion, não à mão. (1) Escolha a peça do inventário: %s. Sem encaixe, diga qual peça faltou em vez de improvisar. (2) Antes de rodar, declare o custo estimado (tempo e tokens); Workflow ou fan-out só com opt-in do maestro. (3) Dogfood: rode o artefato de verdade, não pare no plano; o que for irreversível (merge, push na main, apagar): %s (4) Feche com evidência: o comando rodado e a saída observada. %s' "$choices" "$GATE" "$SUFFIX" ;;
    GUARDRAIL)  printf 'APARTE guarda-regra — instalar guardrail durável de comportamento. %s Prefira forcing-function (hook / .claude/rules path-scoped), não prosa "never do X"; registre a decisão no /meta:diary. %s' "$GATE" "$SUFFIX" ;;
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
  if   grep -qiE '^guarda-regra[[:space:]]*:' <<< "$line";                  then key=GUARDRAIL
  elif grep -qiE '^\+etapa[[:space:]]*:' <<< "$line";                        then key=ADD_STEP
  elif grep -qiE '^-etapa[[:space:]]*:' <<< "$line";                         then key=DROP_STEP
  elif grep -qiE '^(dúvida|duvida|pergunta)[[:space:]]*:' <<< "$line";       then key=QUESTION
  elif grep -qiE '^(corrige|dica|orienta)[[:space:]]*:' <<< "$line";         then key=CORRECTION
  elif grep -qiE '^(reforço|reforco)[[:space:]]*:' <<< "$line";              then key=PRAISE
  elif grep -qiE '^mandou bem[[:space:]]*,' <<< "$line";                     then key=PRAISE
  elif grep -qiE '^(nota|fyi|avisa)[[:space:]]*:' <<< "$line";               then key=NOTE
  elif grep -qiE '^(guarda|relembra)[[:space:]]*:' <<< "$line";              then key=REMEMBER
  elif grep -qiE '^lembre-se[[:space:]]*[:,]' <<< "$line";                   then key=REMEMBER
  elif grep -qiE '^(tarefa|fa(ç|Ç|c)a)[[:space:]]*:' <<< "$line";        then key=TASK
  elif grep -qiE '^(paralelo|pesquisa)[[:space:]]*:' <<< "$line";            then key=PARALLEL
  elif grep -qiE '^(em paralelo|enquanto isso)[[:space:]]*[:,]' <<< "$line"; then key=PARALLEL
  else return 0
  fi
  route "$key"
}

case "${1:-}" in
  detect) shift; detect "$@" ;;
  task-map) shift; task_map "$@" ;;
  ""|--help|-h)
    echo "uso: aside-router.sh detect [prompt] | task-map [--check]   (detect lê stdin se sem arg)" >&2
    exit 0 ;;
  *) echo "modo desconhecido: $1 (use 'detect' ou 'task-map')" >&2; exit 0 ;;
esac
