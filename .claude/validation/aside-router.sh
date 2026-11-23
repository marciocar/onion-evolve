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
TODAY="$(date +%F)"

# Raiz da maquinaria a partir do PRÓPRIO motor (core: .claude/; plugin: a raiz dele). Com CDPATH no ambiente o
# `cd` relativo pode cair num diretório homônimo de outra raiz (CDPATH= impede) e imprime o destino (>/dev/null engole).
MACHINERY_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)"
TM="${MACHINERY_ROOT}/utils/task-manager/tm.sh"
ENVCHECK="${MACHINERY_ROOT}/utils/task-manager/env-check.sh"
# na rota, os caminhos vão citados para o shell (%q): HOME com espaço quebraria o comando que a sessão copia
TM_Q="$(printf '%q' "$TM")"; ENVCHECK_Q="$(printf '%q' "$ENVCHECK")"

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
    # reforço = REFORÇO DE ORDEM/DIRETRIZ (decisão do maestro, 2026-11-20). Medido: nos 80 usos de 19/10 a 20/11 ele
    # reforça uma ordem ("ir até o final", "converse com o kg-ssot"), não elogia; a rota antiga mandava ao diário de
    # elogio, que a sessão usou 0 vezes.
    DIRECTIVE)  printf 'APARTE reforço — REFORÇO DE ORDEM ou DIRETRIZ do maestro (não é elogio). Trate como ordem reforçada: aplique JÁ ao que está em curso, sem esperar a próxima fronteira de passo. Se vale além desta tarefa (diretriz durável), grave memória de feedback (auto-memory, type: feedback) com a frase dele verbatim e a data %s; não é caso de diário. %s' "$TODAY" "$SUFFIX" ;;
    # nota = CARD no task manager do dono (decisão do maestro, 2026-11-20). Medido: os 16 usos eram pendência futura
    # ("precisamos de um manual…"), que o notes.md da sessão perdia. O caminho do tm.sh sai do inventário vivo:
    # sem o tm.sh nesta instalação, a rota já manda ao notes.md.
    NOTE)
      # a frase do maestro entra por heredoc com delimitador citado: entre aspas duplas, crase e $( ) dela seriam
      # executados pelo shell (revisão isolada, 2026-11-20)
      if [ -f "$TM" ]; then
        printf "APARTE nota — vira CARD de gestão, não nota de sessão. Confira o provider (bash %s --provider); se houver um, crie o card no dono certo (o core ou a sessão dona do assunto): bash %s item.create --title '[dono · %s] <resumo>' --description \"\$(cat <<'NOTA' … NOTA)\" [--project <projeto do dono>] (modelo, não literal: o heredoc abre e fecha em linhas próprias; o <resumo> do título é escrito pela sessão, sem aspas simples, crase nem \$, nunca a frase do maestro), com a frase do maestro verbatim e a data (%s) DENTRO do heredoc de delimitador citado (entre aspas duplas, crase e \$( ) da frase rodariam no shell), e confirme ao maestro o número do card que voltou. Sem provider (none) ou se o tm.sh falhar: anote no notes.md do scratchpad e DIGA que não virou card e por quê. %s" "$ENVCHECK_Q" "$TM_Q" "$TODAY" "$TODAY" "$SUFFIX"
      else
        printf 'APARTE nota — vira CARD de gestão, mas esta instalação não tem o tm.sh (%s): anote no notes.md do scratchpad com a frase e a data %s, e DIGA ao maestro que não virou card e por quê. %s' "$TM_Q" "$TODAY" "$SUFFIX"
      fi ;;
    # fyi:/avisa: seguem aviso SÓ desta sessão (0 usos no período medido; o card é decisão sobre `nota:`)
    FYI)        printf 'APARTE aviso — lembrete/aviso SÓ desta sessão. Anote no notes.md do scratchpad (parking-lot); NÃO vira card nem memória. %s' "$SUFFIX" ;;
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

  # PREFIXO COMPOSTO (2026-11-20): "paralelo: dúvida: …" emite as DUAS rotas, na ordem escrita (medido: 2 usos,
  # "paralelo: dúvida:" e "dúvida: reforço:"; a forma antiga só via o primeiro). Até 3 marcadores, sem repetir rota.
  local key seen=" " n=0 out=""
  while [ "$n" -lt 3 ] && [ -n "$line" ]; do
    key="$(match_key "$line")"
    [ -n "$key" ] || break
    # depois de uma DÚVIDA, marcador de efeito é assunto da pergunta, não ordem ("dúvida: nota: vira card?")
    case " ${seen} " in *" QUESTION "*) case "$key" in NOTE|DROP_STEP|ADD_STEP|GUARDRAIL|REMEMBER) break ;; esac ;; esac
    # numa linha só, separadas por " ‖ ": o fallback sem jq do hook escapa só \\ e ", e uma quebra de linha
    # crua deixaria o JSON inválido
    case "$seen" in *" ${key} "*) ;; *) out="${out:+${out} ‖ }$(route "$key")"; seen="${seen}${key} " ;; esac
    # tira o marcador já lido: até o 1º ':' ou ',' (nenhum marcador tem ':' ou ',' por dentro) e os espaços
    line="$(printf '%s' "$line" | sed -E 's/^[^:,]*[:,][[:space:]]*//')"
    n=$((n + 1))
  done
  [ -n "$out" ] || return 0
  printf '%s\n' "$out"
}

match_key() {  # $1 = linha → imprime a chave do marcador no INÍCIO (ou nada)
  local line="$1" key=""
  # Ordem: mais específico primeiro (guarda-regra antes de guarda; ±etapa explícitos).
  # Canônicos exigem ':'; aliases fluídos (lembre-se / em paralelo / enquanto isso) aceitam ':' ou ','.
  # MAIÚSCULA COM ACENTO: `grep -i` em LC_ALL=C não dobra multibyte (DÚVIDA: e REFORÇO: ficavam mudos); por isso
  # o Ú, o Í e o Ç vão explícitos nas duas caixas.
  # DIGITAÇÃO (medido 19/10–20/11): "dpuvida:" 2 vezes (no ABNT2 a tecla do acento agudo fica ao lado do P) e
  # "dívida:" 1 vez, ambos querendo dúvida; "dívida:" como palavra própria, 0 vezes. Viram alias de dúvida.
  if   grep -qiE '^guarda-regra[[:space:]]*:' <<< "$line";                  then key=GUARDRAIL
  elif grep -qiE '^\+etapa[[:space:]]*:' <<< "$line";                        then key=ADD_STEP
  elif grep -qiE '^-etapa[[:space:]]*:' <<< "$line";                         then key=DROP_STEP
  elif grep -qiE '^(d(ú|Ú|u)vida|dpuvida|d(í|Í)vida|pergunta)[[:space:]]*:' <<< "$line"; then key=QUESTION
  elif grep -qiE '^(corrige|dica|orienta)[[:space:]]*:' <<< "$line";         then key=CORRECTION
  elif grep -qiE '^refor(ç|Ç|c)o[[:space:]]*:' <<< "$line";                  then key=DIRECTIVE
  elif grep -qiE '^nota[[:space:]]*:' <<< "$line";                         then key=NOTE
  elif grep -qiE '^(fyi|avisa)[[:space:]]*:' <<< "$line";                  then key=FYI
  elif grep -qiE '^(guarda|relembra)[[:space:]]*:' <<< "$line";              then key=REMEMBER
  elif grep -qiE '^lembre-se[[:space:]]*[:,]' <<< "$line";                   then key=REMEMBER
  elif grep -qiE '^(tarefa|fa(ç|Ç|c)a)[[:space:]]*:' <<< "$line";        then key=TASK
  elif grep -qiE '^(paralelo|pesquisa)[[:space:]]*:' <<< "$line";            then key=PARALLEL
  elif grep -qiE '^(em paralelo|enquanto isso)[[:space:]]*[:,]' <<< "$line"; then key=PARALLEL
  fi
  printf '%s' "$key"
}

case "${1:-}" in
  detect) shift; detect "$@" ;;
  task-map) shift; task_map "$@" ;;
  ""|--help|-h)
    echo "uso: aside-router.sh detect [prompt] | task-map [--check]   (detect lê stdin se sem arg)" >&2
    exit 0 ;;
  *) echo "modo desconhecido: $1 (use 'detect' ou 'task-map')" >&2; exit 0 ;;
esac
