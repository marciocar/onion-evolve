#!/usr/bin/env bash
# =============================================================================
# lint-artifacts.sh — Linter determinístico do Sistema Onion (sem LLM)
#
# Propósito : Validar artefatos em .claude/ contra regras arquiteturais do
#             framework. Não faz chamadas a modelos — usa apenas grep/wc/find.
#
# Uso       : bash .claude/validation/lint-artifacts.sh
#             Rodar a partir da raiz do repositório.
#
# Saída     : Linhas "VIOLATION: <arquivo>: <regra>" para cada violação.
#             Exit 1 se houver pelo menos uma violação HARD.
#             Exit 0 se nenhuma violação HARD for encontrada.
#
# Categorias:
#   HARD  — bloqueia CI / impede merge
#   SOFT  — aviso; não bloqueia
#
# Regras implementadas:
#   1. Frontmatter de agente: name:, description:, tools: obrigatórios
#   2. Frontmatter de comando: description: obrigatório (exceto common/ e README)
#   3. Campo model: não pode conter gpt-4 (linhas iniciando com 'model:')
#   4. Ausência de 'mcp_onion-orchestrator' em .claude/ [HARD]
#   5. Limite de linhas: agente >1500 [HARD], comando >800 [HARD]
#      (common/templates e common/prompts ficam isentos do limite de comando)
#   6. Filenames em .claude/ devem ser kebab-case [SOFT]
#      (exceções: README.md, SKILL.md, ESPERANTO.md e templates com underscore
#       em common/templates)
#   7. Nenhum agente pode ter name: contendo 'worker-orchestrator' [HARD]
#   8. Inventário canônico (docs/onion/inventory.md) em sincronia com o
#      filesystem [HARD] — gerado por inventory.sh; drift bloqueia merge
#   9. Contagens no CLAUDE.md em sincronia com a SSOT [HARD]
#  10. SDAAL: sem chamada direta a provider (mcp_<provider>_* / clickup_mcp /
#      $CLICKUP_TASK_ID) em commands/agents fora de adapters e especialistas
#      [HARD] — consumo de task manager é agnóstico e API-first (integrations §9)
#  11. SDAAL: método de taskManager./tm./forge. usado no consumidor deve EXISTIR
#      na interface (ITaskManager/IForge) [HARD] — pega método agnóstico inventado
#      (ex.: getTaskList em vez de searchTasks) que o grep anti-MCP não vê
#  12. Nomes de tool de agente: estilo-Cursor (read_file, run_terminal_cmd, …)
#      [HARD] — não existem no Claude Code, deixam o subagente sem ferramentas;
#      MCP de underscore único (mcp_<Server>_…) [HARD] — formato é mcp__server__tool
#  13. Templates canônicos (commands/common/templates/) dialeto-puro [HARD] —
#      são copiados verbatim ao criar agentes/comandos; token Cursor ou MCP
#      underscore-único aqui re-propaga o bug para toda nova orquestração
#  14. Meta-specs (docs/meta-specs/) sem dialeto Cursor em exemplos de tools:
#      [HARD] — autoridade L0; token Cursor como item de lista YAML ou MCP
#      underscore-único. A lista de PROIBIÇÃO em prosa/blockquote é isenta
#  15. Frescor de contexto de domínio [SOFT] — arquivo POPULADO em docs/*-context/
#      (exclui README/index) deve carregar carimbo 'Última Atualização'/'updated:';
#      habilita a fase Manage (/meta:context-freshness). No framework = no-op (templates)
#  16. Contagem de inventário-TOTAL divergente da SSOT [SOFT] — comandos/agentes/KBs +
#      categorias; categorias de AGENTE via ONION_AGENT_CATEGORIES (≠ COMMAND_CATEGORIES)
#  17. Frontmatter: valor escalar com ': ' não-aspado [HARD] — quebra YAML no Claude Code
#  18. Documentação versionada sob .claude/docs/ [HARD] — árvore proibida (usar docs/)
#  19. Plugins de vertical (plugins/*) em sincronia com as fontes [HARD] — gerados por
#      assemble-plugin.sh; drift (edição à mão OU fonte alterada sem regenerar) bloqueia merge
#  20. Capability Contract: tier de conformance reivindicado é cumprido [HARD] — Bronze (campos
#      mínimos), Silver (requires resolvem), Gold (Silver + loads). Declarar acima do cumprido bloqueia.
#  21. Grafo (docs/onion/graph.md) em sincronia com a spec-as-code [HARD] — gerado por graph.sh;
#      drift (editar à mão OU mudar fonte sem regenerar) bloqueia merge.
#  29. Proveniência INVERTIDA com catraca [HARD+SOFT] — documento de análise sob
#      docs/analysis/ e docs/evolution/research/ deve ser citado em trace:/evidence:
#      por algum .kg.yaml. Passivo no baseline versionado = SOFT; documento NOVO fora
#      do baseline = HARD; baseline que CRESCE = HARD. Delega a kg-provenance-coverage.sh
#      (escopo e exclusões justificados lá). Sinal de um adotante regulado, 2026-07-20.
#
# Convenção: .claude/validation/fixtures/ guarda TEMPLATES de teste das próprias
#   guardas (consumidos por lint-selftest.sh), não artefatos ativos. As 4 regras de
#   varredura ampla (3, 4, 6, 16) isentam '*/validation/fixtures/*'; as demais varrem
#   roots estreitos (agents/, commands/, templates/, meta-specs/, *-context/) que as
#   fixtures não habitam. Por isso uma fixture "bad" não polui o lint real do repo.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolução de caminhos: suporte a execução de qualquer diretório
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# O script fica em .claude/validation/; subimos dois níveis para a raiz do repo
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAUDE_DIR="${REPO_ROOT}/.claude"

# ── PAPEL DO REPO, resolvido UMA VEZ (era três predicados divergentes e um grep por arquivo) ──
# MEDIDO 2026-08-06: o mesmo predicado existia em TRÊS formas neste arquivo — com espaço
# LITERAL (`'^(role: (adopted|hub)|decoupled_from:)'`, 5 usos), tolerante-a-espaço (2 usos) e
# só-folha (2 usos). O write-stamp.sh emite `role: %s` com UM espaço, então a máquina sempre
# casava as três; o rombo é o stamp EDITADO À MÃO. Com `role:adopted` (sem espaço) o repo se
# partia ao meio — metade das guardas via adotante, metade via core — e o dano foi medido em
# sandbox: 7 HARD espúrios. Um predicado, um lugar.
# A âncora de fim (`_ROLE_TAIL`) também mata o casamento por PREFIXO que a forma antiga aceitava:
# `role: adoptedX` deixava de ser confundido com `adopted`. E resolver uma vez, em vez de um
# `grep` dentro do predicado por-arquivo, tira ~1.461 execuções de grep por varredura.
_stamp_has() { grep -qE "$1" "${REPO_ROOT}/.claude/.onion-version" 2>/dev/null; }
_ROLE_TAIL='[[:space:]]*(#.*)?$'
IS_DERIVED=0; _stamp_has "^([[:space:]]*role:[[:space:]]*(adopted|hub)${_ROLE_TAIL}|[[:space:]]*decoupled_from:)" && IS_DERIVED=1
IS_LEAF=0;    _stamp_has "^[[:space:]]*role:[[:space:]]*adopted${_ROLE_TAIL}" && IS_LEAF=1

# ---------------------------------------------------------------------------
# Contadores de violações
# ---------------------------------------------------------------------------
HARD_COUNT=0
SOFT_COUNT=0
TOTAL_COUNT=0

# ---------------------------------------------------------------------------
# Modo --fix: além de detectar, REESCREVE as contagens divergentes para a SSOT.
# Sem --fix o script é puramente diagnóstico (comportamento histórico).
# ---------------------------------------------------------------------------
FIX_MODE=0
ONLY_PATH=""        # --only=<abspath>: escopa a varredura a UM arquivo (acelera o selftest: O(fixtures×1))
for _arg in "$@"; do
  case "${_arg}" in
    --fix) FIX_MODE=1 ;;
    --only=*) ONLY_PATH="${_arg#--only=}" ;;
  esac
done
# Normaliza --only para ABSOLUTO (a checagem de pertencimento compara com raízes
# absolutas; caminho relativo casaria nada → falso-verde silencioso). Arquivo
# inexistente → aborta (não deixar um escopo quebrado "passar" vazio).
if [ -n "${ONLY_PATH}" ]; then
  case "${ONLY_PATH}" in
    /*) ;;
    *) ONLY_PATH="$(cd "$(dirname "${ONLY_PATH}")" 2>/dev/null && pwd)/$(basename "${ONLY_PATH}")" ;;
  esac
  [ -f "${ONLY_PATH}" ] || { echo "ERRO: --only: arquivo inexistente: ${ONLY_PATH}" >&2; exit 2; }
fi
FIXED_FILES=0
declare -a FIX_LOG=()

# ---------------------------------------------------------------------------
# Escopo único do inventário — predicado COMPARTILHADO por detecção (REGRA 16)
# e correção (--fix). Extraí-lo garante que o --fix NUNCA toque um arquivo que
# a detecção isenta (materials/marketing, análises datadas, snapshots, a SSOT).
# Retorna 0 (sucesso) = EXCLUIR; 1 = incluir na varredura de contagem.
# ---------------------------------------------------------------------------
inventory_scope_excluded() {
  local f="$1"
  case "${f}" in
    */docs/analysis/*|*/.claude/sessions/*|*/docs/materials/*|*/docs/onion/inventory.md|*/validation/fixtures/*) return 0 ;;
    # canais de mail (co-evolução): sinais relayados do adotante + relatórios downstream CITAM números
    # do produto alheio ('100+ agentes' do sistema do adotante) — não são claims do inventário Onion.
    # Mesma doutrina do adopter-aware abaixo, mas vale inclusive no core (role: source). Sinal de campo 2026-07-25.
    */docs/evolution/inbox/*|*/docs/evolution/inbound/*) return 0 ;;
  esac
  # Adopter-aware: num repo DERIVADO (role: adopted|hub|decoupled), SÓ os docs Onion VENDORIZADOS podem
  # legitimamente afirmar contagens do inventário Onion. Os docs de PRODUTO do adotante (docs/specs,
  # docs/architecture, CLAUDE.md próprio, relatórios em docs/evolution/, …) falam do sistema DELE —
  # 'N agentes' ali é do produto, não do Onion. Falso-positivo REAL: um adotante (2026-07-24) tinha
  # docs/specs/capability-registry.md com '100+ agentes' do próprio produto. Restringe a varredura à
  # superfície Onion. No core (role: source) NÃO se aplica — todos os docs são Onion. [[fix-must-become-mechanism]]
  if [ "${IS_DERIVED}" -eq 1 ]; then
    case "${f}" in
      # Varre o que é DO ALVO e REGENERÁVEL: docs/onion/ (inventory.md e graph.md nascem do
      # filesystem dele) e o CLAUDE.onion.md dele. Aí a contagem é claim sobre a instalação DELE.
      */docs/onion/*|*/CLAUDE.onion.md) : ;;
      # NÃO varre a prosa VENDORIZADA do core (knowledge-base, meta-specs, sdaal): ela viaja
      # INTACTA e afirma sobre o FRAMEWORK, não sobre a instalação do adotante. Gateá-la contra o
      # inventário do alvo é comparar maçã com laranja — e o defeito não é teórico:
      # MEDIDO 2026-08-06 num adotante que tem 1 KB e 1 skill PRÓPRIAS: o vendorizado
      # onion-framework-identity.md diz 90 KBs / 11 skills (verdade sobre o core) e o inventário
      # regenerado dele diz 91 / 12 (verdade sobre ele) → 3 HARD permanentes, insolúveis no alvo,
      # porque "consertar" significaria editar prosa do core que o próximo update sobrescreve.
      # Todo adotante com artefato próprio nasce vermelho. [[fix-must-become-mechanism]]
      */docs/knowledge-base/*|*/docs/meta-specs/*|*/docs/sdaal/*) return 0 ;;
      *) return 0 ;;                                                    # doc de produto do adotante → exclui
    esac
  fi
  if grep -qiE '^(status:[[:space:]]*snapshot|type:[[:space:]]*(adr|evolution-backlog))' "${f}" 2>/dev/null; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# _find — wrapper de find que honra --only=<arquivo>. Sem --only, é find normal.
# Com --only, emite SÓ o arquivo-alvo, e apenas se ele estiver sob uma das raízes
# da regra — preservando a semântica de escopo de cada regra (regra cujo alvo
# está fora das suas raízes → não varre nada, idêntico ao find real que não
# acharia o arquivo lá). Convenção: raízes vêm ANTES dos predicados (que começam
# com '-' ou '!'). É o que dá ao selftest O(fixtures × 1) em vez de
# O(fixtures × repo-inteiro) — mesma cobertura, segundos em vez de minutos.
# ---------------------------------------------------------------------------
_find() {
  local roots=() preds=()
  while [ $# -gt 0 ]; do
    case "$1" in
      # '(' ')' ',' também iniciam EXPRESSÃO do find, não são raízes. Sem eles, o '(' de
      # uma regra agrupada vazava para roots[] e mudava a forma da expressão montada
      # abaixo — o -prune passava a imprimir o DIRETÓRIO podado, e o `wc -l < "$dir"`
      # do chamador morria com "Is a directory" (medido 2026-08-04, regra 5c).
      -*|'!'|'('|')'|',') preds=("$@"); break ;;
      *) roots+=("$1"); shift ;;
    esac
  done
  if [ -n "${ONLY_PATH}" ]; then
    local r
    for r in "${roots[@]}"; do
      case "${ONLY_PATH}" in
        "${r}"/*|"${r}") find "${ONLY_PATH}" "${preds[@]}"; return ;;
      esac
    done
    return 0   # alvo fora das raízes desta regra → nada a varrer
  fi
  # Poda .claude/worktrees/ (git worktrees locais, gitignored) — não são artefatos
  # do framework; varrê-los gera falso-positivo local (o CI nunca os vê). Prune ANTES
  # dos preds: '-o' curto-circuita p/ o alvo podado; o lado direito preserva -print0.
  #
  # ÂNCORA OBRIGATÓRIA (${CLAUDE_DIR}, não glob global): o padrão anterior
  # '*/.claude/worktrees/*' casava por SUFIXO, então quando o próprio lint rodava de
  # DENTRO de um worktree ele podava a árvore que estava varrendo — 0 agentes varridos,
  # sem uma linha de aviso, e o pre-commit morria. Não é caso de borda: Claude Code cria
  # worktree nativo em .claude/worktrees/ desde a v2.1.49, e worktree-convention-2026.md
  # registra esse caminho como o canônico para worktree de harness. Ancorado em
  # CLAUDE_DIR o predicado poda os worktrees do checkout que está sendo varrido e
  # NUNCA a si mesmo (de dentro do worktree, ${CLAUDE_DIR}/worktrees nem existe).
  # Guardado por check_scan_sanity() (REGRA 54) — se esta poda voltar a se comer, o
  # gate reprova ALTO em vez de passar verde.
  find "${roots[@]}" -path "${CLAUDE_DIR}/worktrees/*" -prune -o "${preds[@]}"
}

# ===========================================================================
# REGRA 54 — A varredura ENXERGA o que existe (guarda-das-guardas) [HARD]
# previne: gate que varre ZERO arquivo e mesmo assim reporta OK — verde sem ter olhado
#   Toda regra deste lint responde "achei violação?". NENHUMA respondia "eu cheguei a
#   olhar?". São perguntas diferentes, e a segunda é a que falha em silêncio: uma
#   varredura cega devolve zero violações, que é indistinguível de conformidade.
#   Medido em 2026-08-04, rodando o lint de dentro de um worktree de harness: 0 dos 51
#   agentes varridos, nenhum aviso — o gate teria dito "OK ✓" tendo verificado nada
#   (só não disse porque uma regra vizinha morreu antes, por acaso).
#   A cura NÃO é consertar aquela poda (isso é o F2): é exigir que a varredura PROVE
#   ter visto. O chão de verdade vem do safe-count.sh, o helper que nasceu em
#   2026-08-03 justamente para "zero" e "falhou" nunca mais colidirem — e que até aqui
#   nenhuma das 38 guardas usava, só o selftest. O antídoto existia, sem estar ligado.
#   Cobre de uma vez as duas formas de cegueira que se manifestam igual: poda que se
#   come (o worktree) e raiz que nunca entra (escopo). A forma SEMÂNTICA — veredito que
#   não cobre a dimensão do erro — é outra natureza e não se resolve aqui.
#   [[fix-must-become-mechanism]]
# ===========================================================================
check_scan_sanity() {
  # Sob --only=<arquivo> a varredura é escopada DE PROPÓSITO: raiz que não contém o alvo
  # devolve zero, e isso é a semântica declarada do modo, não cegueira. Acusar aqui seria
  # falso-positivo — foi o que o selftest (rules-registry (f)) pegou ao estrear esta regra.
  # Não é fail-open: --only nunca alega cobertura total; quem gateia o CI é a passada cheia.
  if [ -n "${ONLY_PATH}" ]; then return; fi

  local helper="${REPO_ROOT}/.claude/utils/safe-count.sh"
  if [ ! -f "${helper}" ]; then
    violation "HARD" "${helper}" "[varredura-sa] safe-count.sh ausente — sem chão de verdade a sanidade da varredura não é verificável (erro viraria número, que é o que ele existe para impedir)"
    return
  fi
  # shellcheck source=/dev/null
  . "${helper}"

  local root dir real seen
  for root in agents commands skills utils rules; do
    dir="${CLAUDE_DIR}/${root}"
    [ -d "${dir}" ] || continue     # superfície ausente tem regra própria; aqui não é o assunto
    if ! real="$(count_files "${dir}" '*.md')"; then
      violation "HARD" "${dir}" "[varredura-sa] o chão de verdade quebrou em ${root}/ — count_files falhou, e um erro engolido aqui viraria 'zero arquivos' silencioso"
      continue
    fi
    [ "${real}" -gt 0 ] || continue  # vazio DE VERDADE: nada a exigir da varredura
    # se _find quebrar, o resultado é 0 — e 0 é exatamente a condição que reprova.
    # Por isso aqui não há 2>/dev/null: falha tem de aparecer, não virar número.
    seen="$(_find "${dir}" -name '*.md' -print | wc -l | tr -d ' ')"
    if [ "${seen}" -eq 0 ]; then
      violation "HARD" "${dir}" "[varredura-sa] a varredura enxergou 0 arquivos em ${root}/, mas existem ${real} — o gate está CEGO nesta superfície e reportaria OK sem ter olhado (causas conhecidas: poda que casa a própria árvore varrida, raiz errada, ou predicado do find vazando para as raízes em _find)"
    fi
  done
}

# ---------------------------------------------------------------------------
# Função auxiliar: emitir violação
# ---------------------------------------------------------------------------
violation() {
  local severity="$1"   # HARD | SOFT
  local file="$2"
  local rule="$3"

  # Caminho relativo à raiz do repo para mensagens mais legíveis
  local rel_file="${file#${REPO_ROOT}/}"

  echo "VIOLATION: ${rel_file}: ${rule}"
  TOTAL_COUNT=$(( TOTAL_COUNT + 1 ))

  if [ "${severity}" = "HARD" ]; then
    HARD_COUNT=$(( HARD_COUNT + 1 ))
  else
    SOFT_COUNT=$(( SOFT_COUNT + 1 ))
  fi
}

# ---------------------------------------------------------------------------
# _gen_into — roda um GERADOR e separa QUEBRA de DRIFT.
#
# O padrão anterior era `bash "${gen}" > "${tmp}" 2>/dev/null || true`: engolia o exit
# code E o stderr. O diff seguinte comparava a saída VAZIA de um gerador quebrado com o
# arquivo bom e concluía "desatualizado — regenere". A mensagem então MANDAVA sobrescrever
# o arquivo correto com o vazio. Falha aberta que vira falha DESTRUTIVA: quem obedecesse
# a própria guarda perdia o conteúdo.
#
# Medido em 2026-08-04: sob hook do git em worktree, GIT_DIR absoluto fazia
# `git -C <subdir> rev-parse --show-toplevel` devolver o subdir; os geradores não achavam
# members.yaml e emitiam zero byte. 4 falsos "desatualizado" de uma vez.
#
# Uso: _gen_into <tmp> <arquivo-rastreado> <rótulo> -- <comando...>
#   rc 0 → gerou algo utilizável, siga para o diff
#   rc 1 → QUEBROU; a violação certa já foi emitida e NÃO diz "regenere"
# ---------------------------------------------------------------------------
_gen_into() {
  local tmp="$1" tracked="$2" label="$3"; shift 3
  [ "${1:-}" = "--" ] && shift
  local err rc=0
  err="$(mktemp)"
  "$@" > "${tmp}" 2>"${err}" || rc=$?
  if [ "${rc}" -ne 0 ]; then
    violation "HARD" "${label}" "o GERADOR falhou (exit ${rc}) — NÃO regenere por cima: sobrescreveria o arquivo bom com saída inválida. stderr: $(head -c 300 "${err}" | tr '\n' ' ')"
    rm -f "${err}"; return 1
  fi
  if [ ! -s "${tmp}" ] && [ -s "${tracked}" ]; then
    violation "HARD" "${label}" "o GERADOR devolveu saída VAZIA e o arquivo rastreado tem conteúdo — isto é QUEBRA, não drift. NÃO regenere por cima: zeraria o arquivo. stderr: $(head -c 300 "${err}" | tr '\n' ' ')"
    rm -f "${err}"; return 1
  fi
  rm -f "${err}"; return 0
}

# ===========================================================================
# REGRA 1 — Frontmatter de agente: name:, description:, tools: obrigatórios [HARD]
# previne: agente sem name/description/tools obrigatórios — não carrega nem roteia direito
# ===========================================================================
check_agent_frontmatter() {
  while IFS= read -r -d '' agent; do
    local missing=""

    grep -q "^name:" "${agent}"        || missing="${missing} name:"
    grep -q "^description:" "${agent}" || missing="${missing} description:"
    grep -q "^tools:" "${agent}"       || missing="${missing} tools:"

    if [ -n "${missing}" ]; then
      violation "HARD" "${agent}" "frontmatter de agente incompleto — campos ausentes:${missing} — copie do template .claude/commands/common/templates/agent-template.md"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 2 — Frontmatter de comando: description: obrigatório [HARD]
# previne: comando sem description — invisível/ambíguo no menu
#           (exceto arquivos em common/ e arquivos README.md)
# ===========================================================================
check_command_description() {
  while IFS= read -r -d '' cmd; do
    if ! grep -q "^description:" "${cmd}"; then
      violation "HARD" "${cmd}" "frontmatter de comando sem description: — copie do template .claude/commands/common/templates/command-template.md"
    fi
  done < <(
    _find "${CLAUDE_DIR}/commands" -name "*.md" \
      ! -path "*/common/*"   \
      ! -name "README.md"    \
      -print0 2>/dev/null
  )
}

# ===========================================================================
# REGRA 3 — Campo model: restrito à allowlist sonnet|opus|haiku|fable [HARD]
# previne: model fora da allowlist embarcado num artefato
#           Era denylist de 1 item (gpt-4) para um campo que na prática é
#           allowlist fechada de 3-4 valores — 'model: gpt-5', 'o3' ou
#           'claude-3-opus' passariam hoje, sem barrar nada além do literal
#           'gpt-4'. Allowlist medida contra o uso real (153 arquivos com
#           frontmatter): sonnet/opus/haiku; 'fable' é o 4o valor documentado
#           pela SSOT dos templates (command-template.md e agent-template.md).
#           Checa SÓ o `model:` do FRONTMATTER real (entre o par de '---' no
#           TOPO do arquivo) — não o corpo, onde exemplos ilustrativos
#           ('model: [sonnet|opus]' em agent-creator-specialist.md,
#           'model: sonnet|opus|haiku' em onion-patterns/SKILL.md) usam a
#           sintaxe como PROSA, não como valor de campo, e disparariam
#           falso-positivo sob varredura ingênua do arquivo inteiro.
# ===========================================================================
check_no_gpt4_model() {
  while IFS= read -r -d '' file; do
    local model_line token
    model_line="$(awk 'NR==1 && $0=="---" { infm=1; next } infm && $0=="---" { exit } infm && /^model:/ { print; exit }' "${file}")"
    [ -n "${model_line}" ] || continue
    token="$(printf '%s' "${model_line}" | sed -E 's/^model:[[:space:]]*//' | awk '{print $1}')"
    case "${token}" in
      sonnet|opus|haiku|fable) : ;;
      *) violation "HARD" "${file}" "campo model: fora da allowlist (sonnet|opus|haiku|fable): '${token}' — troque '${token}' por um destes quatro valores" ;;
    esac
  done < <(_find "${CLAUDE_DIR}" -name "*.md" ! -path "*/validation/fixtures/*" -print0 2>/dev/null)
}

# ===========================================================================
# [NUMERO APOSENTADO] A regra 4 foi REMOVIDA em 2026-08-03 — não reutilizar o número.
#   (o cabeçalho não usa a forma "# REGRA N —" de propósito: o parser do
#    rules-registry a capturaria como regra VIVA sem `previne:` e o gerador
#    falharia com exit 2 — foi o que aconteceu na 1a tentativa desta remoção)
#   Guardava a string `mcp_onion-orchestrator` — um componente VAPORWARE que nunca
#   existiu como uso real. Medido: zero ocorrências vivas; a guarda precisava de 3
#   exclusões auto-referenciais só para não se acusar (o próprio script, o registro
#   gerado e as fixtures). Guardava contra algo que NUNCA aconteceu.
#   A generalização proposta ("MCP declarado que não está no .mcp.json") foi avaliada
#   e REFUTADA: não existe .mcp.json neste repo, e as duas generalizações naturais já
#   são cobertas pela REGRA 12 (formato mcp__server__tool; MCP de provider no tools:).
#   Sem espaço próprio e sem dano medido → gated-until-trigger manda remover.
#   Contraste deliberado com as REGRAS 13/14 (dialeto Cursor), MANTIDAS na mesma
#   rodada: aquele dialeto EXISTIU em 49 agentes e foi migrado — guarda contra o que
#   já aconteceu é catraca de regressão, não profilaxia especulativa.
# ===========================================================================
# ===========================================================================
# REGRA 5 — Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal) [HARD + SOFT]
# previne: artefato inchado muito além do saudável para o seu tipo
#           Agente  > 1500 linhas → HARD
#           Comando > 800  linhas → HARD  (common/templates e common/prompts isentos)
#           SDAAL núcleo (interface/types/factory/detector) > 500 → SOFT
#           SDAAL adapter (utils/**/adapters/*.md)          > 900 → SOFT
#           Critério por classe (doutrina docs/sdaal/sdaal.md §7): núcleo é contrato enxuto;
#           adapter de provider rico tem mapeamento campo-a-campo irredutível. SOFT = crescimento
#           orgânico permitido, mas o débito fica VISÍVEL/medido (não invisível).
# ===========================================================================
check_line_limits() {
  # 5a. Agentes
  while IFS= read -r -d '' agent; do
    local lines
    lines=$(wc -l < "${agent}")
    if [ "${lines}" -gt 1500 ]; then
      violation "HARD" "${agent}" "agente com ${lines} linhas (limite: 1500) — extraia para KB, skill ou sub-agente delegável (agents.md §4)"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)

  # 5b. Comandos (exclui common/templates e common/prompts)
  while IFS= read -r -d '' cmd; do
    local lines
    lines=$(wc -l < "${cmd}")
    if [ "${lines}" -gt 800 ]; then
      violation "HARD" "${cmd}" "comando com ${lines} linhas (limite: 800) — extraia para common/templates, common/prompts, KB ou sub-comando (commands.md §5)"
    fi
  done < <(
    _find "${CLAUDE_DIR}/commands" -name "*.md" \
      ! -path "*/common/templates/*" \
      ! -path "*/common/prompts/*"   \
      -print0 2>/dev/null
  )

  # 5c. SDAAL núcleo (interface/types/factory/detector) — alvo ≤ 500 [SOFT]
  while IFS= read -r -d '' core; do
    local lines
    lines=$(wc -l < "${core}")
    if [ "${lines}" -gt 500 ]; then
      violation "SOFT" "${core}" "núcleo SDAAL com ${lines} linhas (alvo: 500) — fragmente via progressive disclosure (sdaal.md §14.5)"
    fi
  done < <(
    _find "${CLAUDE_DIR}/utils" \
      \( -name "interface.md" -o -name "types.md" -o -name "factory.md" -o -name "detector.md" \) \
      -print0 2>/dev/null
  )

  # 5d. SDAAL adapter de provider — alvo ≤ 900 [SOFT] (densidade campo-a-campo legítima)
  while IFS= read -r -d '' adapter; do
    local lines
    lines=$(wc -l < "${adapter}")
    if [ "${lines}" -gt 900 ]; then
      violation "SOFT" "${adapter}" "adapter SDAAL com ${lines} linhas (alvo: 900 — fragmentar via progressive disclosure, sdaal.md §14.5)"
    fi
  done < <(_find "${CLAUDE_DIR}/utils" -path "*/adapters/*.md" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 6 — Filenames em .claude/ devem ser kebab-case [SOFT]
# previne: filename fora de kebab-case — inconsistência e link quebrado
#           Exceções permitidas (convenções estabelecidas):
#             • README.md  — convenção universal de documentação
#             • SKILL.md   — convenção do framework de skills
#             • *_template.md em common/templates — legado aceito pelo framework
# ===========================================================================
check_kebab_case_filenames() {
  while IFS= read -r -d '' file; do
    local base
    base=$(basename "${file}")

    # Exceções explícitas (nomes em maiúsculas ou com underscore aceitos)
    case "${base}" in
      README.md|SKILL.md) continue ;;
    esac

    # Sessões são artefatos de trabalho gitignored (nomes arbitrários do usuário: INDEX.md,
    # STATE.md, dirs datados) — não são artefatos do framework, fora do kebab-case.
    if [[ "${file}" == */sessions/* ]]; then continue; fi

    # Underscore em common/templates é aceito (legado de templates)
    if [[ "${file}" == */common/templates/* ]] && [[ "${base}" == *_* ]]; then
      continue
    fi

    # Detecta violações: letra maiúscula (exceto toda a extensão) ou espaço ou underscore
    local name_part="${base%.*}"  # remove extensão para checagem

    if echo "${name_part}" | grep -qE '[A-Z]| |_'; then
      violation "SOFT" "${file}" "filename não segue kebab-case (maiúsculas, espaço ou underscore em '${base}') — renomeie '${base}' para kebab-case"
    fi
  done < <(_find "${CLAUDE_DIR}" -name "*.md" ! -path "*/validation/fixtures/*" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 7 — Nenhum agente pode ter name: contendo 'worker-orchestrator' [HARD]
# previne: agente com o nome do anti-padrão 'worker-orchestrator'
#           (violação arquitetural — §4.2 de architecture.md)
# ===========================================================================
check_no_worker_orchestrator_agent() {
  while IFS= read -r -d '' agent; do
    if grep -q "^name:.*worker-orchestrator" "${agent}"; then
      violation "HARD" "${agent}" "agente com name: 'worker-orchestrator' viola §4.2 da arquitetura — mova a orquestração para skill/comando (onion-orchestration / /meta:orchestrate), não para um agente"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 52 — Todo .kg.yaml do repo passa no radar de INTEGRIDADE [HARD]
# previne: grafo com contradição estrutural vivendo no repo sem ninguém medir
#   O kg-radar.sh é o único mecanismo que reprova CONTRADIÇÃO (nó que recebe REFUTES
#   e segue status:confirmed) — e NADA o rodava por cadência. Chegava ao CI só
#   indiretamente: REGRA 43 (só grafos citados em `kg:`) e REGRA 31 (só grafos com
#   lente). Grafo não-citado e sem lente NUNCA era verificado.
#
#   ⚠ SOBREPOSIÇÃO DECLARADA com a REGRA 43 (disciplina das irmãs R30/R33 e R31/R8/R21):
#   a R43 JÁ roda `--integrity` (+ `--schema`) nos grafos que algum doc declara em `kg:`
#   — hoje **11 dos 51**. Esta regra é SUPERSET: o ganho real são os **40 grafos** que
#   ninguém cita e que, por isso, nunca eram verificados.
#   Reproduza os dois números (a 1ª redação deste docstring dizia 18/33, não-reproduzíveis
#   — corrigido na revisão de 2026-08-03; regra que nasce com número não-medido carrega o
#   defeito que ela existe para pegar):
#     grep -rhE '^kg:' --include='*.md' .claude/diary docs/analysis docs/evolution/research \
#       | sed 's/^kg:[[:space:]]*//; s/^["'"'"']//; s/["'"'"'].*$//; s/ .*//' | sort -u | wc -l
#     git ls-files '*.kg.yaml' | grep -v '/fixtures/' | wc -l
#   Threat models distintos, por isso as duas coexistem:
#     · R43 = "o grafo que ESTA MIGALHA declara é real e são?" (proveniência p/ dentro)
#     · R52 = "TODOS os grafos do repo estão sãos hoje?" (integridade do acervo)
#   Um grafo citado é checado duas vezes. É custo aceito: a R43 morre com a migalha que
#   a invoca, a R52 não depende de ninguém citar nada.
#   A convocação já existia em .claude/rules/kg-grammar.md:41 ("exit 0 obrigatório"),
#   mas é COGNITIVA: só carrega ao TOCAR um .kg.yaml, depende do ator obedecer, e não
#   pega DEGRADAÇÃO PASSIVA (um REFUTES que chega depois contradiz o alvo sem ninguém
#   editar o arquivo). Esta regra é a mesma convocação, promovida a MECÂNICA.
#   [[fix-must-become-mechanism]] Lacuna medida em 2026-08-03.
#   SEM CATRACA por medição, não por descuido: 51 grafos no escopo, 0 reprovam hoje.
#   A medição foi provada não-vazia (MUT): grafo com REFUTES sobre nó confirmed → exit 1.
#   fixtures/ fica FORA por desenho (lá vivem grafos inválidos que alimentam o selftest).
# ===========================================================================
check_kg_radar_integrity() {
  local helper="${SCRIPT_DIR}/kg-radar-integrity.sh"
  [ -f "${helper}" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      *.kg.yaml|*/kg-radar.sh|*/kg-radar-integrity.sh) : ;;
      *) return 0 ;;
    esac
  fi
  local out sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    violation "${sev}" "${REPO_ROOT}/${path}" "[kg-integridade/${tag}] ${msg}"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 55 — O `trace:` de um nó APONTA para alvo que EXISTE [HARD]
# previne: âncora declarada que não resolve — quem tenta voltar ao "porquê" cai no vazio
#   Irmã da REGRA 52 (integridade do acervo) e do bloco PROVENIÊNCIA do kg-radar.
#   A PROVENIÊNCIA cobra que a decisão APONTE para a origem; nunca que o alvo EXISTA.
#   É o behavior-over-declaration da casa virado para a própria âncora: um `trace:`
#   apontando para arquivo movido passa no gate e MENTE.
#   MEDIDO 2026-08-06 (54 grafos, 1.659 nós com trace:): 13 ponteiros mortos — 7 por
#   arquivo movido para _processed/, 4 por prefixo perdido (commands/git → engineer),
#   2 por reorganização de pasta. TODOS consertados antes desta regra entrar, e é por
#   isso que ela nasce HARD SEM BASELINE: não há passivo tolerado a carregar.
#   POR QUE SCRIPT-IRMÃO e não cláusula no kg-radar (refutação medida): (1) o escopo
#   mandado — `--freshness-tsv` — cobre 2 dos 13 casos, nasceria vendo 15% e DECLARANDO
#   cobertura; (2) o kg-radar tem ZERO acesso a filesystem, e essa pureza é o que o faz
#   rodar sob `env -i` (portabilidade medida no M3) — embutir I/O custaria a propriedade
#   para cobrir menos. Toda a lógica (duas raízes, 3 classes não-julgáveis, guarda de
#   vacuidade) vive em kg-trace-resolve.sh.
# ===========================================================================
check_kg_trace_resolve() {
  local helper="${SCRIPT_DIR}/kg-trace-resolve.sh"
  [ -f "${helper}" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      *.kg.yaml|*/kg-trace-resolve.sh) : ;;
      *) return 0 ;;
    esac
  fi
  local out g nid ntype target verdict
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r g nid ntype target verdict; do
    [ -n "${nid}" ] || continue
    # VACUIDADE não é um nó com âncora quebrada — é o PARSER morto. Mensagem própria, senão o
    # aviso sairia como "o nó PARSER aponta para (nenhum nó lido)", que confunde quem lê.
    if [ "${verdict}" = "VACUIDADE" ]; then
      violation "HARD" "${SCRIPT_DIR}/kg-trace-resolve.sh" \
        "[trace-resolve/VACUIDADE] existe \`trace:\` no corpus e o parser não leu NADA — nem julgável, nem excluído. A guarda está cega: ela reportaria verde sem verificar coisa alguma (detalhe: bash .claude/validation/kg-trace-resolve.sh)"
      continue
    fi
    violation "HARD" "${REPO_ROOT}/${g}" \
      "[trace-resolve/${verdict}] ${nid} (${ntype}): \`trace:\` aponta para '${target}', que não existe — arquivo movido/renomeado? cite o caminho real (detalhe: bash .claude/validation/kg-trace-resolve.sh)"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 56 — PR aberto carrega RESÍDUO da passada adversarial [HARD]
# previne: trabalho proposto sem revisão semântica — e sem forma de saber que não houve
#   Irmã da REGRA 55 na forma (feeder determinístico + TSV), mas de outra natureza: as
#   demais regras julgam ARTEFATO; esta julga se o PROCESSO deixou rastro.
#   ORIGEM (dano medido 2026-08-06): 8 erros num dia, 6 achados por revisão adversarial
#   rodada À MÃO — e a passada só rodou porque o maestro perguntou. Em 2026-08-02 o mesmo
#   já fora medido (15 auto-correções, 8 pelo gatilho social, "nenhuma por auto-revisão").
#   Nomear não curou; a cura que a casa provou funcionar é RESÍDUO MATERIAL, auditado por
#   terceiro e desacoplado do ator — não "prestar mais atenção". [[fix-must-become-mechanism]]
#   O QUE ELA NÃO FAZ: não julga a QUALIDADE da revisão (nenhum script sabe se um achado é
#   bom). Exige o resíduo e amarra-o ao diff por sha256 — mudou o código depois de revisar,
#   o artefato caduca. É o mesmo limite honesto do frescor: o GATE cria a cadência, o WORKER
#   testa a verdade.
#   ESCOPO — só com PR ABERTO. Exigir a cada commit intermediário travaria o ciclo, e
#   falso-positivo TRAVANTE é o modo de falha medido desta casa. Trabalho em curso ≠ proposto.
#   ISENÇÕES, contadas e de vocabulário fechado: branch default · sem PR · sem `gh` (a guarda
#   declara que não sabe, em vez de passar em silêncio) · PR que edita o próprio onion-review.yml.
#   TETO DECLARADO: este repo não tem branch protection (403) — NADA impede um merge. O que
#   esta regra torna impossível não é mergear errado, é mergear SEM SABER.
#   Toda a lógica vive em review-artifact-check.sh.
# ===========================================================================
check_review_artifact() {
  local helper="${SCRIPT_DIR}/review-artifact-check.sh"
  [ -f "${helper}" ] || return 0
  [ -n "${ONLY_PATH}" ] && return 0        # é regra de PR, não de arquivo
  local out sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format=tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    violation "${sev}" "${REPO_ROOT}/${path}" "[review-artifact/${tag}] ${msg}"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 51 — Agentes branch-* documentam a distinção vs o par geral [SOFT]
# previne: par de agentes com overlap invisível — dispatcher que roteia por description não escolhe
#   Um agente DIFF-SCOPED (branch-code-reviewer, branch-metaspec-checker, ...)
#   tem um par de escopo geral (@code-reviewer, @metaspec-gate-keeper, ...). A
#   'description' É o contrato de roteamento que um dispatcher lê — sem cláusula
#   de distinção ('Diferença vs' / 'DIFF-SCOPED'), o roteamento por description
#   não sabe escolher (par com overlap real invisível). Guard nascido do achado
#   D2 do evolve 2026-07-17 (description-como-contrato-de-roteamento).
# ===========================================================================
check_branch_agent_distinction() {
  while IFS= read -r -d '' agent; do
    if grep -qE "^name:[[:space:]]*branch-" "${agent}"; then
      if ! grep -qiE 'Diferença vs|DIFF-SCOPED' "${agent}"; then
        violation "SOFT" "${agent}" "agente branch-* sem cláusula de distinção ('Diferença vs'/'DIFF-SCOPED') — contrato de roteamento por description incompleto (achado D2, evolve 2026-07-17) — adicione na description uma frase 'Diferença vs @<par-geral>'"
      fi
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 53 — Regra path-scoped declara `paths:` que casa algo real [HARD]
# previne: regra em .claude/rules/ que nunca carrega — instrução que o modelo jamais vê
#   `.claude/rules/*.md` são regras COGNITIVAS: o harness as injeta no contexto quando
#   o arquivo tocado casa o glob de `paths:`. Sem `paths:`, ou com um glob que não casa
#   NADA no repo, a regra existe no disco e nunca chega ao modelo — e a ausência é
#   silenciosa (ninguém percebe uma instrução que não apareceu).
#   Lacuna medida em 2026-08-03: `grep 'claude/rules' lint-artifacts.sh` → ZERO. Era a
#   única superfície de .claude/ sem guarda nenhuma, num diretório que estreou 2026-08-02.
#   É a mesma classe da guarda-verde-vazia que a própria kg-grammar.md nasceu para evitar
#   (grep de `type: REFUTES` que devolve zero) — só que aplicada ao continente, não ao conteúdo.
#   [[fix-must-become-mechanism]]
# ===========================================================================
# Um glob de `paths:` casa algo REAL?
# Preferimos o índice do git (rastreado = o que a rede de fato vê). Mas o sandbox do
# lint-selftest é uma CÓPIA sem `.git` — ali `git ls-files` falha e TODO glob pareceria
# morto, reprovando até a fixture `good`. Falso-positivo medido no dogfood, 2026-08-03:
# a guarda acusaria a si mesma no próprio auto-teste. Fora de repo git, cai para `find`.
_rule_glob_matches() { # $1=glob
  local g="$1" pat
  if git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "${REPO_ROOT}" ls-files -- "${g}"        | grep -q . && return 0
    # o harness escreve '**/x'; o pathspec do git resolve o mesmo com o sufixo puro
    git -C "${REPO_ROOT}" ls-files -- "${g#\*\*/}"  | grep -q . && return 0
    return 1
  fi
  pat="${g##*/}"                                   # '**/*.kg.yaml' → '*.kg.yaml'
  [ -n "${pat}" ] || return 1
  find "${REPO_ROOT}" -name "${pat}" -not -path '*/.git/*' -print -quit | grep -q .
}

check_rules_pathscoped() {
  local rules_dir="${CLAUDE_DIR}/rules"
  [ -d "${rules_dir}" ] || return 0          # sem rules/ → nada a checar (adotante)
  local rule globs g matched
  while IFS= read -r -d '' rule; do
    # (a) frontmatter com `paths:` — sem isso a regra nunca é elegível a carregar
    if ! grep -qE '^paths:' "${rule}"; then
      violation "HARD" "${rule}" "regra path-scoped sem 'paths:' no frontmatter — nunca carrega (regra que não chega ao modelo é indistinguível de regra ausente) — adicione 'paths:' com ao menos um glob no frontmatter da regra"
      continue
    fi
    # (b) ao menos um glob declarado
    # O `---` de fechamento do frontmatter TAMBÉM casa "^[[:space:]]*-", e sem o guard abaixo
    # ele entrava como o item de lista "--" — o ramo `paths:` VAZIO nunca disparava e caía no
    # ramo errado. Achado no dogfood da própria regra, 2026-08-03.
    globs="$(awk '/^---[[:space:]]*$/{f=0;next} /^paths:/{f=1;next} /^[a-zA-Z_-]+:/{f=0} f&&/^[[:space:]]*-[[:space:]]+/{gsub(/^[[:space:]]*-[[:space:]]+/,""); gsub(/^["'"'"']|["'"'"']$/,""); print}' "${rule}")"
    if [ -z "${globs}" ]; then
      violation "HARD" "${rule}" "'paths:' declarado mas VAZIO — nenhum glob, a regra nunca carrega — adicione ao menos um glob sob 'paths:' (ex.: '  - \"**/*.sh\"')"
      continue
    fi
    # (c) ao menos um glob casa arquivo RASTREADO — glob que não casa nada é regra morta
    matched=0
    while IFS= read -r g; do
      [ -n "${g}" ] || continue
      if _rule_glob_matches "${g}"; then matched=1; break; fi
    done <<< "${globs}"
    if [ "${matched}" -eq 0 ]; then
      violation "HARD" "${rule}" "nenhum glob de 'paths:' casa arquivo rastreado ($(printf '%s' "${globs}" | tr '\n' ' ')) — a regra existe no disco e NUNCA carrega — corrija o glob para casar um arquivo real rastreado (git ls-files), ou remova a regra se obsoleta"
    fi
  done < <(_find "${rules_dir}" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 8 — Inventário canônico sincronizado com o filesystem [HARD]
# previne: inventário mentindo vs o filesystem real (contagem drifta)
#           docs/onion/inventory.md é gerado por inventory.sh (SSOT).
#           Regenera para um temp e compara: se divergir, alguém alterou
#           comandos/agentes/skills/KBs sem regenerar o inventário.
# ===========================================================================
check_inventory_sync() {
  local inv_script="${SCRIPT_DIR}/inventory.sh"
  local inv_file="${REPO_ROOT}/docs/onion/inventory.md"

  if [ ! -f "${inv_script}" ]; then
    violation "HARD" "${inv_script}" "inventory.sh ausente (SSOT do inventário não pode ser computada)"
    return
  fi
  if [ ! -f "${inv_file}" ]; then
    violation "HARD" "${inv_file}" "docs/onion/inventory.md ausente — rode 'bash .claude/validation/inventory.sh --markdown > docs/onion/inventory.md'"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  if _gen_into "${tmp}" "${inv_file}" "${inv_file}" -- bash "${inv_script}" --markdown &&
     ! diff -q "${inv_file}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "${inv_file}" "inventário desatualizado vs filesystem — regenere com '/meta:inventory' (bash .claude/validation/inventory.sh --markdown > docs/onion/inventory.md)"
  fi
  rm -f "${tmp}"
}

# ===========================================================================
# REGRA 19 — Plugins de vertical (plugins/*) sincronizados com as fontes [HARD]
# previne: plugin de vertical driftando das fontes — bundle de adoção errado
#           Cada plugins/<name> é GERADO por assemble-plugin.sh a partir de
#           verticals/<name>.manifest.sh. Regenera p/ temp e compara: drift =
#           alguém editou o plugin à mão OU mudou a fonte sem regenerar.
#           IGNORA ref/commit_date do provenance.json (voláteis por commit);
#           compara o resto + o tree_sha (sinal de conteúdo, worktree-based).
# ===========================================================================
check_plugins_sync() {
  local asm="${SCRIPT_DIR}/../utils/marketplace/assemble-plugin.sh"
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  # consumidor (role: adopted) NÃO distribui plugins — marketplace é superfície do source; a fonte é
  # vendorizada mas a SAÍDA gerada (plugins/ + marketplace.json) não. Guarda POR PAPEL (não só por
  # ferramenta) — sinal de campo 2026-07-10 (12 HARD falsos bloqueavam todo commit do adotante).
  [ "${IS_DERIVED}" -eq 1 ] && return 0
  [ -f "${asm}" ] || return 0            # sem assembler → nada a checar (repo sem a feature)
  [ -d "${vdir}" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0   # sem jq → pula gracioso (mesma graça dos outros)

  local manifest name committed tmp
  for manifest in "${vdir}"/*.manifest.sh; do
    [ -f "${manifest}" ] || continue
    name="$(. "${manifest}" >/dev/null 2>&1; printf '%s' "${PLUGIN_NAME:-}")"
    [ -n "${name}" ] || continue
    committed="${REPO_ROOT}/plugins/${name}"
    if [ ! -d "${committed}" ]; then
      violation "HARD" "plugins/${name}" "plugin ausente — gere com 'bash .claude/utils/marketplace/assemble-plugin.sh ${manifest#${REPO_ROOT}/}'"
      continue
    fi
    tmp="$(mktemp -d)"
    bash "${asm}" "${manifest}" "${REPO_ROOT}" "${tmp}/${name}" >/dev/null 2>&1
    # (a) tudo exceto provenance.json (ref/commit_date voláteis lá dentro)
    if ! diff -r -x provenance.json "${committed}" "${tmp}/${name}" >/dev/null 2>&1; then
      violation "HARD" "plugins/${name}" "plugin fora de sincronia com a fonte — regenere com 'bash .claude/utils/marketplace/assemble-plugin.sh ${manifest#${REPO_ROOT}/}'"
    fi
    # (b) tree_sha (sinal de conteúdo content-addressed)
    local c_sha t_sha
    c_sha="$(jq -r '.tree_sha' "${committed}/.claude-plugin/provenance.json" 2>/dev/null)"
    t_sha="$(jq -r '.tree_sha' "${tmp}/${name}/.claude-plugin/provenance.json" 2>/dev/null)"
    if [ "${c_sha}" != "${t_sha}" ]; then
      violation "HARD" "plugins/${name}" "tree_sha divergente (fonte mudou sem regenerar) — rode assemble-plugin.sh"
    fi
    rm -rf "${tmp}"
  done
}

# ===========================================================================
# REGRA 20 — Capability Contract: tier de conformance cumprido [HARD]
# previne: componente reivindica um tier de conformance que não cumpre
#           Cada verticals/<name>.manifest.sh declara CONFORMANCE (bronze|silver|
#           gold) + PROVIDES/REQUIRES/LOADS. Valida o tier reivindicado:
#             bronze = provides + description + version presentes
#             silver = bronze + cada REQUIRES (type:value) resolve no filesystem
#             gold   = silver + LOADS presente
#           Reivindicar acima do cumprido = HARD (auto-descrição honesta).
# ===========================================================================
check_capability_conformance() {
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  [ -d "${vdir}" ] || return 0
  local manifest report name claimed bronze silver gold unresolved met
  for manifest in "${vdir}"/*.manifest.sh; do
    [ -f "${manifest}" ] || continue
    # Subshell: source o manifesto e computa os tiers cumpridos + requires não-resolvidos.
    report="$(
      REPO_ROOT="${REPO_ROOT}"
      . "${manifest}" >/dev/null 2>&1
      claimed="${CONFORMANCE:-bronze}"
      b=1; { [ "${#PROVIDES[@]}" -gt 0 ] && [ -n "${PLUGIN_DESC:-}" ] && [ -n "${PLUGIN_VERSION:-}" ]; } || b=0
      un=""
      for r in "${REQUIRES[@]:-}"; do
        [ -n "${r}" ] || continue
        ty="${r%%:*}"; va="${r#*:}"; ok=0
        case "${ty}" in
          agent)      find "${REPO_ROOT}/.claude/agents" -name "${va}.md" 2>/dev/null | grep -q . && ok=1 ;;
          command)    find "${REPO_ROOT}/.claude/commands" -name "${va}.md" 2>/dev/null | grep -q . && ok=1 ;;
          skill)      [ -d "${REPO_ROOT}/.claude/skills/${va}" ] && ok=1 ;;
          validation) [ -f "${REPO_ROOT}/.claude/validation/${va}" ] && ok=1 ;;
          util)       [ -d "${REPO_ROOT}/.claude/utils/${va}" ] && ok=1 ;;
          template)   [ -f "${REPO_ROOT}/.claude/commands/common/templates/${va}" ] && ok=1 ;;
          env)        grep -q "^${va}=" "${REPO_ROOT}/.env.example" 2>/dev/null && ok=1 ;;
          kb)         [ -e "${REPO_ROOT}/docs/knowledge-base/${va}" ] && ok=1 ;;
          *)          ok=0 ;;
        esac
        [ "${ok}" = 1 ] || un="${un} ${r}"
      done
      s=1; { [ "${b}" = 1 ] && [ -z "${un}" ]; } || s=0
      g=1; { [ "${s}" = 1 ] && [ "${#LOADS[@]}" -gt 0 ]; } || g=0
      printf 'NAME=%s\nCLAIMED=%s\nB=%s\nS=%s\nG=%s\nUN=%s\n' "${PLUGIN_NAME:-?}" "${claimed}" "${b}" "${s}" "${g}" "${un# }"
    )"
    name="$(printf '%s' "${report}" | sed -n 's/^NAME=//p')"
    claimed="$(printf '%s' "${report}" | sed -n 's/^CLAIMED=//p')"
    bronze="$(printf '%s' "${report}" | sed -n 's/^B=//p')"
    silver="$(printf '%s' "${report}" | sed -n 's/^S=//p')"
    gold="$(printf '%s' "${report}" | sed -n 's/^G=//p')"
    unresolved="$(printf '%s' "${report}" | sed -n 's/^UN=//p')"
    # met = maior tier cumprido
    met="none"; [ "${bronze}" = 1 ] && met="bronze"; [ "${silver}" = 1 ] && met="silver"; [ "${gold}" = 1 ] && met="gold"
    # rank p/ comparar
    rank() { case "$1" in bronze) echo 1;; silver) echo 2;; gold) echo 3;; *) echo 0;; esac; }
    if [ "$(rank "${claimed}")" -gt "$(rank "${met}")" ]; then
      local why=""; [ -n "${unresolved}" ] && why=" (requires não-resolvidos:${unresolved})"
      violation "HARD" "verticals/${name}.manifest.sh" "capability: reivindica '${claimed}' mas só cumpre '${met}'${why} — ajuste CONFORMANCE ou as deps/loads"
    fi
  done
}

# ===========================================================================
# REGRA 37 — Mapa role→bundle (roles.yaml) consistente com os verticais [HARD]
# previne: mapa role->bundle (roles.yaml) driftando dos verticais
#           Todo vertical nomeado em roles.yaml (base/optional de qualquer papel)
#           deve ter manifesto em verticals/ E estar registrado no marketplace.json.
#           Impede roles.yaml apontar p/ vertical inexistente. Pula gracioso sem python3/yaml.
# ===========================================================================
check_role_bundle_sync() {
  local roles="${SCRIPT_DIR}/../utils/marketplace/roles.yaml"
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  local mkt="${REPO_ROOT}/.claude-plugin/marketplace.json"
  # consumidor não carrega marketplace.json — mesma guarda por papel de check_plugins_sync (sinal de campo)
  [ "${IS_DERIVED}" -eq 1 ] && return 0
  [ -f "${roles}" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  python3 -c "import yaml" >/dev/null 2>&1 || return 0
  local refs v
  refs="$(python3 - "${roles}" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
s = set()
for role, spec in (d.get("roles") or {}).items():
    for key in ("base", "optional"):
        for x in ((spec or {}).get(key) or []):
            s.add(x)
print("\n".join(sorted(s)))
PY
)"
  for v in ${refs}; do
    [ -n "${v}" ] || continue
    [ -f "${vdir}/${v}.manifest.sh" ] || violation "HARD" "utils/marketplace/roles.yaml" "papel referencia vertical '${v}' sem manifesto em verticals/${v}.manifest.sh — crie com /meta:create-vertical ${v} --plugin (materializa manifesto + marketplace.json)"
    grep -q "\"${v}\"" "${mkt}" 2>/dev/null || violation "HARD" "utils/marketplace/roles.yaml" "vertical '${v}' referenciado em roles.yaml não registrado no marketplace.json — registre '${v}' em .claude-plugin/marketplace.json (mesmo padrão dos demais verticais)"
  done

  # --- WORK_TOOLS (eixo cross-cutting, 2026-07-19) — drift-guard próprio ---
  #   (1) todo `work_tools:` de papel referencia um set válido (ou none/tbd);
  #   (2) todo tool nomeado em work_tool_sets resolve a um comando real .claude/commands/meta/<tool>.md;
  #   (3) o conjunto `full` está coberto pelo manifesto onion-work-tools (roles.yaml <-> manifesto).
  local wt_out kind a b
  wt_out="$(python3 - "${roles}" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
sets = d.get("work_tool_sets") or {}
valid = set(sets.keys()) | {"none", "tbd"}
for role, spec in (d.get("roles") or {}).items():
    wt = (spec or {}).get("work_tools")
    if wt is not None and wt not in valid:
        print("BADSET\t%s\t%s" % (role, wt))
for name, lst in sets.items():
    for t in (lst or []):
        print("TOOL\t%s\t" % t)
PY
)"
  while IFS=$'\t' read -r kind a b; do
    case "${kind}" in
      BADSET) violation "HARD" "utils/marketplace/roles.yaml" "papel '${a}' referencia work_tools set '${b}' inexistente em work_tool_sets" ;;
      TOOL) [ -f "${REPO_ROOT}/.claude/commands/meta/${a}.md" ] || violation "HARD" "utils/marketplace/roles.yaml" "work_tool '${a}' sem comando em .claude/commands/meta/${a}.md — crie com /meta:create-command ${a} (ou corrija o nome em work_tool_sets se foi digitado errado)" ;;
    esac
  done <<< "${wt_out}"
  local wtman="${vdir}/onion-work-tools.manifest.sh" ft
  if [ -f "${wtman}" ]; then
    for ft in $(python3 -c "import yaml; d=yaml.safe_load(open('${roles}')) or {}; print(' '.join((d.get('work_tool_sets') or {}).get('full') or []))" 2>/dev/null); do
      grep -q "commands/meta/${ft}.md" "${wtman}" || violation "HARD" "utils/marketplace/verticals/onion-work-tools.manifest.sh" "work_tool 'full:${ft}' (roles.yaml) ausente do manifesto onion-work-tools — adicione 'commands/meta/${ft}.md' ao manifesto onion-work-tools.manifest.sh"
    done
  fi
}

# ===========================================================================
# REGRA 21 — Grafo (docs/onion/graph.md) sincronizado com a spec-as-code [HARD]
# previne: docs/onion/graph.md desatualizado vs a spec-as-code
#           graph.md é GERADO por graph.sh (actors.yaml + capability + frontmatter).
#           Regenera p/ temp e compara: drift = editou à mão OU mudou a fonte sem
#           regenerar. Espelha check_inventory_sync. Pula gracioso sem jq.
# ===========================================================================
have_py_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }

check_graph_sync() {
  local gen="${SCRIPT_DIR}/graph.sh"
  local gfile="${REPO_ROOT}/docs/onion/graph.md"
  [ -f "${gen}" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0     # graph.sh usa jq p/ capability → pula gracioso sem jq
  have_py_yaml || return 0                        # graph.sh usa python+yaml p/ members.yaml → pula gracioso sem eles
  if [ ! -f "${gfile}" ]; then
    violation "HARD" "docs/onion/graph.md" "grafo ausente — rode 'bash .claude/validation/graph.sh --markdown > docs/onion/graph.md'"
    return
  fi
  local tmp; tmp="$(mktemp)"
  if _gen_into "${tmp}" "${gfile}" "docs/onion/graph.md" -- bash "${gen}" --markdown &&
     ! diff -q "${gfile}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "docs/onion/graph.md" "grafo desatualizado vs spec-as-code — regenere com '/meta:graph' (bash .claude/validation/graph.sh --markdown > docs/onion/graph.md)"
  fi
  rm -f "${tmp}"
}

# REGRA 38 — Mapa da federação (docs/onion/federation-map.md) sincronizado com members.yaml [HARD]
# previne: mapa da federação driftando de members.yaml
#           GERADO por graph.sh --map (SSOT = members.yaml). Espelha check_graph_sync. Pula sem python+yaml.
check_federation_map_sync() {
  local gen="${SCRIPT_DIR}/graph.sh"
  local mfile="${REPO_ROOT}/docs/onion/federation-map.md"
  local members="${REPO_ROOT}/docs/evolution/federation/members.yaml"
  [ -f "${gen}" ] && [ -f "${members}" ] || return 0
  have_py_yaml || return 0
  if [ ! -f "${mfile}" ]; then
    violation "HARD" "docs/onion/federation-map.md" "mapa ausente — rode 'bash .claude/validation/graph.sh --map > docs/onion/federation-map.md'"
    return
  fi
  local tmp; tmp="$(mktemp)"
  if _gen_into "${tmp}" "${mfile}" "docs/onion/federation-map.md" -- bash "${gen}" --map &&
     ! diff -q "${mfile}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "docs/onion/federation-map.md" "mapa da federação desatualizado vs members.yaml — regenere: bash .claude/validation/graph.sh --map > docs/onion/federation-map.md"
  fi
  rm -f "${tmp}"
}

# REGRA 24 — Console da federação (docs/onion/federation-console.html) sincronizado com o SSOT [HARD]
# previne: console da federação publica estado que não bate com o SSOT
#           GERADO por federation-console.sh (members.yaml + CHANGELOG). Espelha check_federation_map_sync.
check_federation_console_sync() {
  local gen="${SCRIPT_DIR}/federation-console.sh"
  local cfile="${REPO_ROOT}/docs/onion/federation-console.html"
  local members="${REPO_ROOT}/docs/evolution/federation/members.yaml"
  [ -f "${gen}" ] && [ -f "${members}" ] || return 0
  have_py_yaml || return 0
  if [ ! -f "${cfile}" ]; then
    violation "HARD" "docs/onion/federation-console.html" "console ausente — rode 'bash .claude/validation/federation-console.sh > docs/onion/federation-console.html'"
    return
  fi
  local tmp; tmp="$(mktemp)"
  if _gen_into "${tmp}" "${cfile}" "docs/onion/federation-console.html" -- bash "${gen}" &&
     ! diff -q "${cfile}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "docs/onion/federation-console.html" "console desatualizado vs SSOT — regenere: bash .claude/validation/federation-console.sh > docs/onion/federation-console.html"
  fi
  rm -f "${tmp}"
}

# REGRA 25 — Agent Card A2A do core (docs/onion/agent-card.json) sincronizado com o SSOT [HARD]
# previne: agent-card A2A do core driftando do SSOT — interop mente
#           GERADO por a2a-agent-card.sh (members.yaml, FILTRADO ao core — F2.2 fundação a2a-live).
#           Espelha check_federation_console_sync. Pula sem python+yaml.
check_agent_card_sync() {
  local gen="${SCRIPT_DIR}/a2a-agent-card.sh"
  local cfile="${REPO_ROOT}/docs/onion/agent-card.json"
  local members="${REPO_ROOT}/docs/evolution/federation/members.yaml"
  [ -f "${gen}" ] && [ -f "${members}" ] || return 0
  have_py_yaml || return 0
  if [ ! -f "${cfile}" ]; then
    violation "HARD" "docs/onion/agent-card.json" "agent card ausente — rode 'bash .claude/validation/a2a-agent-card.sh > docs/onion/agent-card.json'"
    return
  fi
  local tmp; tmp="$(mktemp)"
  if _gen_into "${tmp}" "${cfile}" "docs/onion/agent-card.json" -- bash "${gen}" &&
     ! diff -q "${cfile}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "docs/onion/agent-card.json" "agent card desatualizado vs SSOT — regenere: bash .claude/validation/a2a-agent-card.sh > docs/onion/agent-card.json"
  fi
  rm -f "${tmp}"
}

# ===========================================================================
# REGRA 28 — Anúncio em staging para membro SEM canal de recepção [SOFT]
# previne: anúncio a um membro sem canal de recepção — entrega no vazio
#   Cada anúncio de 1º nível em docs/evolution/federation/outbox/<membro>/*.md
#   resolve o <membro> em members.yaml; se o membro tem local_path mas esse path
#   NÃO tem docs/evolution/inbound/, o anúncio é ESTRUTURALMENTE não-entregável
#   por essa rota (ex.: marcio-pessoal — adota o MÉTODO, não vendoriza .claude/,
#   por desenho — onion_version: n/a). Achado 2026-07-19: 6 anúncios ficaram dias
#   em staging sem ninguém notar, porque nada cruzava "este membro tem canal?"
#   antes de o /meta:co-announce produzir.
#   SOFT DELIBERADO (nunca HARD): a decisão — dar canal ao membro, ou o
#   co-announce pular membros sem canal — é do maestro, não do lint.
#   Degrade gracioso: sem python3/yaml, membro não resolvido/sem local_path, ou
#   local_path inexistente no filesystem → pula sem falhar.
#   AMPUTAÇÃO 2026-08 (double-firing, revisão das 53 regras): a classe "dir de
#   outbox que não resolve a NENHUM id" saiu daqui — é a MESMA condição da
#   REGRA 46, que já a cobre de forma estritamente mais geral (recursiva, inclui
#   _processed/). Um dir órfão com N anúncios emitia N SOFT aqui + 1 SOFT
#   agregado na 46, para o MESMO fato. A 46 fica dona; esta regra agora só fala
#   de membro que EXISTE em members.yaml mas não tem canal — o que finalmente
#   torna o título "membro SEM canal" literal (antes, a classe removida
#   violava "membro nenhum", não "membro sem canal").
# ===========================================================================
check_outbox_channel_exists() {
  local outbox="${REPO_ROOT}/docs/evolution/federation/outbox"
  local members="${REPO_ROOT}/docs/evolution/federation/members.yaml"
  [ -d "${outbox}" ] && [ -f "${members}" ] || return 0
  have_py_yaml || return 0

  # DUAS classes de "anúncio a um membro que EXISTE mas não tem canal" (a classe do
  # dir órfão — que não resolve a NENHUM id — foi amputada em 2026-08: é a REGRA 46,
  # que já a cobre sem repetir violation por arquivo). A 1ª (onion_version n/a) é
  # decidível SÓ COM O REPO — por isso roda no CI. (A 1ª versão desta regra só olhava
  # o filesystem do adotante e era NO-OP no CI: nenhum local_path existe no runner,
  # logo zero membros avaliados — a regra dependia do mesmo ato humano cuja ausência
  # causou o furo original.)
  local member_dir member_id f meta resolved ver local_path pend
  for member_dir in "${outbox}"/*/; do
    [ -d "${member_dir}" ] || continue
    member_id="$(basename "${member_dir}")"

    meta="$(python3 - "${members}" "${member_id}" <<'PY' 2>/dev/null
import sys, yaml
path, mid = sys.argv[1], sys.argv[2]
d = yaml.safe_load(open(path)) or {}
for m in (d.get("members") or []):
    if m.get("id") == mid:
        print("1|%s|%s" % (m.get("onion_version") or "", m.get("local_path") or ""))
        break
else:
    print("0||")
PY
)"
    resolved="${meta%%|*}"; meta="${meta#*|}"
    ver="${meta%%|*}"; local_path="${meta#*|}"

    # Há anúncio de 1º nível aguardando transporte? (_processed/ já foi entregue — não varrer)
    # `_`-prefixado é área reservada (`_processed`, `_archive`), não canal de membro.
    case "${member_id}" in _*) continue ;; esac
    pend=0
    for f in "${member_dir}"*.md; do [ -f "${f}" ] && pend=1 && break; done
    [ "${pend}" -eq 1 ] || continue

    # Dir que NÃO resolve a NENHUM id de members.yaml é órfão — mas "órfão" não é
    # "membro sem canal" (não há membro nenhum aqui). Classe AMPUTADA desta regra
    # em 2026-08 (double-firing: a REGRA 46 já cobre isto, de forma mais geral e
    # SEM repetir 1 violation por arquivo). A 46 é a dona; aqui, silêncio.
    [ "${resolved}" = "1" ] || continue

    # (1) [CI] membro que NÃO vendoriza (onion_version: n/a) não tem doc-bridge por desenho.
    if [ "${ver}" = "n/a" ]; then
      for f in "${member_dir}"*.md; do
        [ -f "${f}" ] || continue
        violation "SOFT" "${f}" "anúncio em staging para '${member_id}', que adota o MÉTODO e NÃO vendoriza (onion_version: n/a) — logo não tem canal inbound/ por desenho; decisão do maestro: dar canal ao membro, ou o /meta:co-announce pular membros sem canal"
      done
      continue
    fi

    # (2) [LOCAL, bônus] membro vendorizado cujo clone existe aqui mas está sem o canal.
    [ -n "${local_path}" ] && [ -d "${local_path}" ] || continue
    [ -d "${local_path}/docs/evolution/inbound" ] && continue
    for f in "${member_dir}"*.md; do
      [ -f "${f}" ] || continue
      violation "SOFT" "${f}" "anúncio em staging para '${member_id}': o clone local existe (${local_path}) mas NÃO tem docs/evolution/inbound/ — canal ausente"
    done
  done
}

# ===========================================================================
# REGRA 50 — Contagens do SITE público sincronizadas com a SSOT [HARD]
# previne: pitch público driftando da SSOT — número que mente para quem não pode conferir
#           O site hardcoda números que a inventory.sh GERA. Sem gate, o pitch
#           público drifta silencioso a cada comando criado — e mente para quem
#           não pode conferir. Achado 2026-07-17 (re-verificação do grafo de
#           identidade): o site exibia 95/96 comandos e 66 KBs; a SSOT dizia
#           97 e 74 — e as três ocorrências divergiam ENTRE SI.
#           Espelha check_claude_md_counts, com duas diferenças deliberadas:
#           (a) checa TODAS as ocorrências (o bug foi valores divergentes entre
#               si no mesmo arquivo — head -1 teria passado);
#           (b) escopo = site/index.html (o PITCH). site/historia/ fica FORA por
#               desenho: a timeline é histórica ("comando nº 95" era verdade
#               quando o /meta:kg nasceu) — gatear história seria forjá-la.
#           Ausente site/ (todo adotante) → no-op gracioso.
# ===========================================================================
check_site_inventory_sync() {
  local site="${REPO_ROOT}/site/index.html"
  local inv_script="${SCRIPT_DIR}/inventory.sh"
  [ -f "${site}" ] || return 0          # sem site → nada a checar (adotante)
  [ -f "${inv_script}" ] || return 0

  local env_out
  env_out="$(bash "${inv_script}" --env 2>/dev/null || true)"
  local truth noun claim
  # noun exibido no site → variável canônica da SSOT
  for pair in "comandos:ONION_COMMANDS_TOTAL" "agentes:ONION_AGENTS_TOTAL" \
              "skills:ONION_SKILLS_TOTAL" "knowledge bases:ONION_KBS_TOTAL"; do
    noun="${pair%%:*}"
    truth="$(echo "${env_out}" | grep "^${pair##*:}=" | cut -d= -f2)"
    [ -n "${truth}" ] || continue
    # (a) prose: "<N> <noun>"  — todas as ocorrências
    while read -r claim; do
      [ -n "${claim}" ] || continue
      [ "${claim}" = "${truth}" ] || violation "HARD" "${site}" \
        "site afirma ${claim} ${noun}, filesystem tem ${truth} — alinhe à SSOT (/meta:inventory)"
    done < <(grep -oiE "[0-9]+ ${noun}" "${site}" 2>/dev/null | grep -oE '^[0-9]+')
    # (b) contador animado: data-n="<N>">0</b><span><noun></span>
    while read -r claim; do
      [ -n "${claim}" ] || continue
      [ "${claim}" = "${truth}" ] || violation "HARD" "${site}" \
        "contador data-n do site afirma ${claim} ${noun}, filesystem tem ${truth} — alinhe à SSOT (/meta:inventory)"
    done < <(grep -oE "data-n=\"[0-9]+\">0</b><span>${noun}</span>" "${site}" 2>/dev/null \
             | grep -oE '[0-9]+' | head -1)
  done
}

# ===========================================================================
# REGRA 9 — Contagens no CLAUDE.md em sincronia com a SSOT [HARD]
# previne: contagens no CLAUDE.md drifta da SSOT do inventário
#           Extrai "N comandos invocáveis", "N agentes", "N skills" do CLAUDE.md
#           e compara com os totais computados por inventory.sh. Impede que a
#           constituição volte a drifar (foi onde o drift 79≠76 vivia).
#   [[fix-must-become-mechanism]] Docstring movido para junto da SUA função em
#   2026-08-03: estava 45 linhas acima, antes do bloco da REGRA 50, e o parser do
#   rules-registry.sh (que associa o 1º `nome() {` após o header) publicava a
#   severidade de check_site_inventory_sync como se fosse a da REGRA 9.
# ===========================================================================
check_claude_md_counts() {
  local claude_md="${REPO_ROOT}/CLAUDE.md"
  local inv_script="${SCRIPT_DIR}/inventory.sh"
  [ -f "${claude_md}" ] || return 0
  [ -f "${inv_script}" ] || return 0

  # Totais canônicos do filesystem
  local env_out
  env_out="$(bash "${inv_script}" --env 2>/dev/null || true)"

  # Checa TODAS as ocorrências de cada padrão — não só a 1a ('head -1' escondia
  # divergência ENTRE ocorrências no mesmo arquivo, o mesmo modo-de-falha que a
  # REGRA 50 (irmã, site/index.html) já trata corretamente. Formato do trio:
  # '<padrão no CLAUDE.md>:<var ONION_*_TOTAL>:<substantivo na mensagem>'.
  local truth noun pattern rest truth_var claim
  for trio in "comandos invocáveis:ONION_COMMANDS_TOTAL:comandos" \
              "agentes:ONION_AGENTS_TOTAL:agentes" \
              "skills:ONION_SKILLS_TOTAL:skills"; do
    pattern="${trio%%:*}"
    rest="${trio#*:}"
    truth_var="${rest%%:*}"
    noun="${rest#*:}"
    truth="$(echo "${env_out}" | grep "^${truth_var}=" | cut -d= -f2)"
    [ -n "${truth}" ] || continue
    while read -r claim; do
      [ -n "${claim}" ] || continue
      [ "${claim}" = "${truth}" ] || violation "HARD" "${claude_md}" \
        "CLAUDE.md afirma ${claim} ${noun}, filesystem tem ${truth} — alinhe à SSOT (/meta:inventory)"
    done < <(grep -oE "[0-9]+ ${pattern}" "${claude_md}" | grep -oE '^[0-9]+')
  done
}

# ===========================================================================
# REGRA 10 — SDAAL: sem chamada direta a provider no consumidor [HARD]
# previne: consumidor chamando o provider direto, furando a abstração SDAAL
#            Comandos/agentes devem operar via abstração (taskManager.*),
#            não chamar o MCP/SDK do provider direto nem usar var de roteamento
#            específica. Provider-specific só vive em adapters/ e nos
#            especialistas. (integrations.md §9 — API-first, agnóstico)
# ===========================================================================
check_no_direct_provider_calls() {
  # Padrão de chamada direta a provider (não confundir com menção a @agente)
  local pattern='mcp_ClickUp_|mcp_clickup-mcp-server_|clickup_mcp\.|mcp_asana_|mcp_jira_|CLICKUP_TASK_ID'

  while IFS= read -r -d '' file; do
    # Allowlist: onde provider-specific é legítimo
    case "${file}" in
      */utils/task-manager/adapters/*) continue ;;
      */utils/forge/adapters/*)        continue ;;
      */agents/development/clickup-specialist.md) continue ;;
    esac

    if grep -qE "${pattern}" "${file}"; then
      local lines
      lines=$(grep -nE "${pattern}" "${file}" | head -3 | sed 's/^/      /')
      violation "HARD" "${file}" "chamada direta a provider (use taskManager.* via adapter — SDAAL §9). Ocorrências:
${lines}"
    fi
  done < <(
    _find "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null
  )
}

# ===========================================================================
# REGRA 11 — Método de abstração usado no consumidor deve existir na interface [HARD]
# previne: consumidor chama método de abstração que não existe na interface
#            Pega método agnóstico INVENTADO (ex.: taskManager.getTaskList(...)
#            quando o canônico é searchTasks). Ancora em ".<metodo>(" — acessos a
#            propriedade (taskManager.provider, .isConfigured) não têm paren e não
#            são checados. A Regra 10 (anti-MCP) não vê isto: já está agnóstico.
# ===========================================================================
check_abstraction_methods_exist() {
  local tm_iface="${CLAUDE_DIR}/utils/task-manager/interface.md"
  local forge_iface="${CLAUDE_DIR}/utils/forge/interface.md"
  [ -f "${tm_iface}" ] || return 0
  [ -f "${forge_iface}" ] || return 0

  # Conjunto canônico de métodos (assinaturas "  metodo(" nas interfaces)
  local methods
  methods=$(grep -hoE '^[[:space:]]+[a-zA-Z]+\(' "${tm_iface}" "${forge_iface}" 2>/dev/null \
    | tr -d ' (' | sort -u)
  [ -n "${methods}" ] || return 0

  while IFS= read -r -d '' file; do
    # Allowlist: adapters e especialistas podem usar pseudocódigo específico
    case "${file}" in
      */utils/*/adapters/*) continue ;;
      */agents/development/clickup-specialist.md) continue ;;
      */agents/development/jira-specialist.md)    continue ;;
      */commands/common/templates/*) continue ;;
    esac

    # Extrai chamadas (taskManager|tm|forge).<metodo>( e valida cada método
    local m
    while IFS= read -r m; do
      [ -z "${m}" ] && continue
      if ! printf '%s\n' "${methods}" | grep -qx "${m}"; then
        local where
        where=$(grep -nE "(taskManager|tm|forge)\.${m}\(" "${file}" | head -2 | sed 's/^/      /')
        violation "HARD" "${file}" "método de abstração inexistente na interface: '${m}()' (use um método de ITaskManager/IForge — ex.: searchTasks). Ocorrências:
${where}"
      fi
    done < <(grep -hoE '(taskManager|tm|forge)\.[a-zA-Z]+\(' "${file}" 2>/dev/null \
              | sed -E 's/.*\.([a-zA-Z]+)\(/\1/' | sort -u)
  done < <(_find "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 12 — Nomes de tool de agente válidos no Claude Code [HARD]
# previne: agente declara uma tool inexistente no Claude Code
#   Cursor-style (read_file, run_terminal_cmd, …) [HARD] — sem ferramentas;
#   MCP underscore único (mcp_<Server>_…) [HARD] — formato é mcp__server__tool
#   MCP de PROVIDER de task/forge no tools: [HARD] — pega tanto a forma idiomática
#     (mcp__clickup__, mcp__github__ — o que um criador escreveria à mão) quanto a
#     forma gerenciada deste harness (mcp__claude_ai_Atlassian__, mcp__claude_ai_Asana__…).
#     Viola SDAAL/API-first: providers vão via taskManager.*/forge.* (adapter), não
#     declarados num agente novo. Só adapters e especialistas (clickup/jira-specialist)
#     podem (integrations §9). Escopado ao frontmatter tools: → não pega exemplo RUIM em prosa.
# ===========================================================================
check_agent_tool_names() {
  local CURSOR='read_file|write|search_replace|run_terminal_cmd|codebase_search|grep|glob_file_search|list_dir|web_search|todo_write|read_lints|update_memory'
  while IFS= read -r -d '' agent; do
    while IFS= read -r tool; do
      [ -z "${tool}" ] && continue
      if echo "${tool}" | grep -qE "^(${CURSOR})$"; then
        violation "HARD" "${agent}" "tool name estilo-Cursor: '${tool}' — use nome nativo do Claude Code (Read/Write/Edit/Bash/Grep/Glob/WebSearch/WebFetch/TodoWrite)"
      elif echo "${tool}" | grep -qE '^mcp_[A-Za-z]' && ! echo "${tool}" | grep -qE '^mcp__'; then
        violation "HARD" "${agent}" "tool MCP em formato inválido: '${tool}' — Claude Code usa 'mcp__<server>__<tool>' (duplo underscore)"
      elif echo "${tool}" | grep -qiE '^mcp__(claude_ai_)?(clickup|jira|atlassian|asana|linear|github|gitlab|bitbucket)__'; then
        case "${agent}" in
          */clickup-specialist.md|*/jira-specialist.md) : ;;   # especialistas de provider podem
          *) violation "HARD" "${agent}" "tool MCP de provider direto no frontmatter: '${tool}' — providers de task/forge vão via adapter SDAAL (taskManager.*/forge.*), não mcp__<provider>__* (integrations §9; só adapters/especialistas)" ;;
        esac
      fi
    done < <(awk '
      # Escopa ao 1º bloco de frontmatter (---...---); ignora exemplos no corpo.
      /^---[[:space:]]*$/ { fmcount++; next }
      fmcount!=1 { next }
      /^tools:[[:space:]]*\[/ {
        s=$0; sub(/^tools:[[:space:]]*\[/,"",s); sub(/\].*$/,"",s);
        n=split(s,a,","); for(i=1;i<=n;i++){ gsub(/[[:space:]"]/,"",a[i]); if(a[i]!="") print a[i] } next
      }
      /^tools:/ {
        rest=$0; sub(/^tools:[[:space:]]*/,"",rest); sub(/[[:space:]]*#.*$/,"",rest);
        if (rest=="") { inblk=1; next }
        n=split(rest,a,","); for(i=1;i<=n;i++){ gsub(/[[:space:]"]/,"",a[i]); if(a[i]!="") print a[i] } next
      }
      inblk && /^[^[:space:]#]/ { inblk=0 }
      inblk && /^[[:space:]]*-/ { t=$0; sub(/^[[:space:]]*-[[:space:]]*/,"",t); sub(/[[:space:]#].*$/,"",t); if(t!="") print t }
    ' "${agent}")
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 13 — Templates canônicos devem ser dialeto-puro [HARD]
# previne: template canônico contaminado com dialeto não-canônico
#   Templates em commands/common/templates/ são copiados verbatim ao criar
#   agentes/comandos; qualquer nome de tool estilo-Cursor [HARD] ou MCP
#   underscore-único [HARD] aqui re-propaga o bug para toda nova orquestração.
#   Cobre tokens distintivos em QUALQUER lugar do template (não só frontmatter,
#   pois o template demonstra YAML no corpo). 'write'/'grep' ficam de fora por
#   ambiguidade com prosa/shell — no frontmatter real a REGRA 12 os pega.
# ===========================================================================
check_template_dialect() {
  local CURSOR='read_file|search_replace|run_terminal_cmd|codebase_search|glob_file_search|list_dir|web_search|todo_write|read_lints|update_memory|edit_file|edit_notebook|MultiEdit'
  local tdir="${CLAUDE_DIR}/commands/common/templates"
  [ -d "${tdir}" ] || return 0
  while IFS= read -r -d '' tpl; do
    while IFS= read -r tok; do
      [ -n "${tok}" ] && violation "HARD" "${tpl}" "dialeto Cursor no template: '${tok}' — copiado verbatim; use nome nativo (Read/Write/Edit/Bash/Grep/Glob/WebSearch/WebFetch/TodoWrite)"
    done < <(grep -hoE "\\b(${CURSOR})\\b" "${tpl}" 2>/dev/null | sort -u)
    while IFS= read -r m; do
      [ -n "${m}" ] && violation "HARD" "${tpl}" "MCP em formato Cursor no template: '${m}' — use 'mcp__<server>__<tool>' (duplo underscore)"
    done < <(grep -hoE 'mcp_[A-Za-z][A-Za-z_]*' "${tpl}" 2>/dev/null | grep -vE '^mcp__' | sort -u)
  done < <(_find "${tdir}" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 14 — Meta-specs (autoridade L0) sem dialeto Cursor em exemplos [HARD]
# previne: exemplo de meta-spec L0 com dialeto Cursor
#   docs/meta-specs/ define o formato canônico que template e creator-agents
#   espelham. Token Cursor declarado como ITEM DE LISTA YAML (- token) [HARD]
#   e MCP underscore-único [HARD]. Tokens em prosa/blockquote (a lista de
#   PROIBIÇÃO que cita os nomes de propósito) NÃO disparam.
# ===========================================================================
check_metaspec_dialect() {
  local CURSOR='read_file|search_replace|run_terminal_cmd|codebase_search|glob_file_search|list_dir|web_search|todo_write|read_lints|update_memory|edit_file|edit_notebook|MultiEdit'
  # Raiz ABSOLUTA — era `docs/meta-specs` relativo, a ÚNICA das 53 regras assim. Como o
  # `[ -d ]` resolve contra o CWD, rodar o lint de qualquer outro diretório fazia a guarda
  # retornar 0 e EVAPORAR em silêncio (medido 2026-08-03: do repo root acusa 1 violação; de
  # /tmp, zero — mesma guarda, mesmo repo, mesma violação presente). Mesma classe do bug da
  # REGRA 47: a guarda não falha, ela deixa de existir. Achado ao escrever a fixture dela —
  # a regra não tinha teste, e por isso o furo viveu invisível.
  local mdir="${REPO_ROOT}/docs/meta-specs"
  [ -d "${mdir}" ] || return 0
  while IFS= read -r -d '' spec; do
    while IFS= read -r tok; do
      [ -n "${tok}" ] && violation "HARD" "${spec}" "dialeto Cursor em exemplo de tools: '${tok}' — use nome nativo (Read/Write/Edit/Bash/Grep/Glob/WebSearch/WebFetch/TodoWrite)"
    done < <(grep -hE "^[[:space:]]*-[[:space:]]+(${CURSOR})([[:space:]#].*)?$" "${spec}" 2>/dev/null | sed -E "s/^[[:space:]]*-[[:space:]]+//; s/[[:space:]#].*$//" | sort -u)
    while IFS= read -r m; do
      [ -n "${m}" ] && violation "HARD" "${spec}" "MCP em formato Cursor: '${m}' — use 'mcp__<server>__<tool>' (duplo underscore)"
    done < <(grep -hoE 'mcp_[A-Za-z][A-Za-z_]*' "${spec}" 2>/dev/null | grep -vE '^mcp__' | sort -u)
  done < <(_find "${mdir}" -name "*.md" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 15 — Frescor de contexto de domínio: carimbo de atualização [SOFT]
# previne: contexto de domínio sem carimbo de atualização — frescor incerto
#   Cada arquivo POPULADO de docs/*-context/ (exclui README/index) deve carregar
#   um carimbo de frescor ('Última Atualização' ou 'updated:'/'date:'). Habilita a
#   fase Manage (/meta:context-freshness): sem carimbo não há como auditar staleness.
#   No framework os contextos são templates (só README) → no-op. A idade (>18 meses)
#   é avaliada pelo comando LLM, não pelo lint determinístico (que seria
#   não-reproduzível no tempo). Aqui exigimos apenas a PRESENÇA do carimbo.
# ===========================================================================
check_context_freshness_stamp() {
  local ctx base
  for ctx in business-context technical-context compliance-context; do
    base="${REPO_ROOT}/docs/${ctx}"
    [ -d "${base}" ] || continue
    while IFS= read -r -d '' f; do
      # Casa pelo radical ASCII 'Atualiza' (sem -i): robusto a locale C (case-fold de
      # 'Ú' multibyte) e a NBSP/espaço duplo entre as palavras. Frontmatter via âncora.
      if ! grep -qE 'Atualiza|^[Uu]pdated:|^[Dd]ate:' "${f}"; then
        violation "SOFT" "${f}" "contexto de domínio sem carimbo de frescor ('Última Atualização'/'updated:') — exigido pela fase Manage (/meta:context-freshness)"
      fi
    done < <(_find "${base}" -name "*.md" ! -iname "readme.md" ! -iname "index.md" -print0 2>/dev/null)
  done
}

# ===========================================================================
# REGRA 16 — Contagem de inventário-TOTAL divergente da SSOT [SOFT]
# previne: contagem-TOTAL do inventário divergindo da SSOT
#   Checa SÓ frases-de-total CANÔNICAS contra inventory.sh — nunca 'N comandos' cru
#   nem 'N especializados' (palavra comum em por-categoria/feature). Marcadores de
#   total confiáveis: 'N comandos invocáveis', 'N comandos em M categorias',
#   'N agentes ...em M categorias' (qualquer texto antes de 'em N categorias') e
#   'N Knowledge Bases'. FORMATOS AMPLIADOS (2026-06): parentético '(N total)'
#   ANCORADO no substantivo da linha (agentes/comandos); aproximado 'N+ comandos|agentes'
#   com GUARDA ANTI-ORQUESTRAÇÃO (pula ranges 'A-B+' e linhas paralel/frota/fan-out — 'N+ agentes'
#   ali é carga de runtime, não inventário); composto 'N comandos, M agentes, P skills,
#   K knowledge bases' (ordem inversa da combinada → não colidem). Assim NÃO flaga métricas de frota
#   ('28 agentes' de um run), breakdowns ('4 comandos especializados de docs',
#   '3 agentes especializados criados') nem snapshots. Complementa a Regra 9 (só CLAUDE.md).
#   FORMATOS 2026-08 (achado PR #517 — 'N skills' driftou em docs/INDEX.md e na KB de
#   identidade SEM nenhum feeder disparar; causa: forma de frase, não ausência de guarda):
#   bare 'N skills' ANCORADO ('.claude/skills/' ou 'skills de orquestração' na MESMA
#   linha — sem âncora, 'skills' é ruído de prosa comum demais para o SOFT confiar);
#   forma INVERTIDA rótulo→número em TABELA ('| Skills | 5 |', '| Comandos invocáveis |
#   99 |' — os 4 rótulos canônicos, valor = 1º inteiro da célula); parentética invertida
#   'Knowledge Bases (N documentos...)' (âncora 'documentos' — não 'arquivos', que tem
#   semântica DIFERENTE em sítios reais, ex. '(N arquivos, incl. index)').
#   SOFT: heurística sobre linguagem natural — surfaca drift sem bloquear CI por FP.
#   ISENTA: docs/analysis/ (datado), .claude/sessions/ (gitignored), docs/materials/
#   (derivado — deferido), docs/onion/inventory.md (SSOT), e frontmatter
#   status:snapshot / type:adr / type:evolution-backlog.
# ===========================================================================
check_inventory_total_drift() {
  local env_out cmd agent cats agent_cats kb skill n pair num ct line cn an sn kn lbl
  env_out="$(bash "${SCRIPT_DIR}/inventory.sh" --env 2>/dev/null || true)"
  # Sem env (inventário ausente/vazio num adotante mínimo ou recém-adotado, antes de gerar o
  # inventário) → nada a comparar; a ausência é da REGRA 8, não desta. Sem este guard, os 'grep'
  # abaixo não casam → exit 1 → sob 'set -euo pipefail' abortavam o LINT INTEIRO (mesma classe da
  # REGRA 36; achado 2026-07-22 ao testar a REGRA 40 num sandbox de adotante). [[fix-must-become-mechanism]]
  [ -n "${env_out}" ] || return 0
  cmd="$(printf '%s\n' "${env_out}" | grep '^ONION_COMMANDS_TOTAL=' | cut -d= -f2)"
  agent="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENTS_TOTAL=' | cut -d= -f2)"
  cats="$(printf '%s\n' "${env_out}" | grep '^ONION_COMMAND_CATEGORIES=' | cut -d= -f2)"
  # Categorias de AGENTE ≠ categorias de COMANDO (podem divergir: ex. 10 cmd-cats × 9 agent-cats).
  # Usar a var própria evita validar/afirmar 'N agentes em <cmd_cats> categorias' (falso).
  agent_cats="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENT_CATEGORIES=' | cut -d= -f2)"
  kb="$(printf '%s\n' "${env_out}" | grep '^ONION_KBS_TOTAL=' | cut -d= -f2)"
  skill="$(printf '%s\n' "${env_out}" | grep '^ONION_SKILLS_TOTAL=' | cut -d= -f2)"
  [ -n "${cmd}" ] || return 0

  while IFS= read -r -d '' f; do
    inventory_scope_excluded "${f}" && continue

    # 'N comandos invocáveis' — 'invocáveis' é marcador de TOTAL (nunca por-categoria)
    while IFS= read -r n; do
      if [ -n "${n}" ] && [ "${n}" != "${cmd}" ]; then
        violation "SOFT" "${f}" "contagem-total de comandos divergente da SSOT: '${n} comandos invocáveis' (esperado ${cmd}) — derive de inventory.md (/meta:inventory)"
      fi
    done < <(grep -oiE '[0-9]+ comandos invocáveis' "${f}" 2>/dev/null | grep -oE '^[0-9]+')

    # 'N comandos [...] em M categorias' — frase-de-total canônica.
    # COBERTURA AMPLIADA: '[^.,|]*' permite qualificadores entre 'comandos' e 'em'
    # (ex.: '86 comandos especializados organizados em 9 categorias'); '[^.,|]'
    # barra vírgula/ponto/pipe → não atravessa frases nem casa linha de tabela.
    # Subsume a forma estrita 'N comandos em M categorias'.
    while IFS= read -r pair; do
      [ -z "${pair}" ] && continue
      num="$(printf '%s' "${pair}" | grep -oE '^[0-9]+')"
      ct="$(printf '%s' "${pair}" | grep -oE '[0-9]+ categorias' | grep -oE '^[0-9]+')"
      if [ -n "${num}" ] && [ "${num}" != "${cmd}" ]; then
        violation "SOFT" "${f}" "contagem-total de comandos divergente da SSOT: '${pair}' (esperado ${cmd} comandos) — /meta:inventory"
      fi
      if [ -n "${ct}" ] && [ "${ct}" != "${cats}" ]; then
        violation "SOFT" "${f}" "contagem de categorias divergente da SSOT: '${pair}' (esperado ${cats}) — /meta:inventory"
      fi
    done < <(grep -oiE '[0-9]+ comandos[^.,|]*em [0-9]+ categorias' "${f}" 2>/dev/null)

    # 'N agentes ... em M categorias' — qualquer texto entre 'agentes' e 'em N categorias'
    # (de IA / especializados / IA distribuídos); o qualificador 'em N categorias' marca o total
    while IFS= read -r pair; do
      [ -z "${pair}" ] && continue
      num="$(printf '%s' "${pair}" | grep -oE '^[0-9]+')"
      ct="$(printf '%s' "${pair}" | grep -oE '[0-9]+ categorias' | grep -oE '^[0-9]+')"
      if [ -n "${num}" ] && [ "${num}" != "${agent}" ]; then
        violation "SOFT" "${f}" "contagem-total de agentes divergente da SSOT: '${pair}' (esperado ${agent}) — /meta:inventory"
      fi
      if [ -n "${ct}" ] && [ "${ct}" != "${agent_cats}" ]; then
        violation "SOFT" "${f}" "contagem de categorias de agentes divergente da SSOT: '${pair}' (esperado ${agent_cats}) — /meta:inventory"
      fi
    done < <(grep -oiE '[0-9]+ agentes[^.,|]*em [0-9]+ categorias' "${f}" 2>/dev/null)

    # 'N agentes e/, M comandos' — frase-de-total COMBINADA (ex.: descrição do
    # agente @onion 'conhecimento completo de 49 agentes e 84 comandos'). Valida
    # ambos os números. GUARDA anti-tabela: linhas iniciadas por '|' são breakdown
    # (ex.: '| 3 agentes, 3 comandos |'), não total → puladas (evita falso-positivo).
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      case "${line}" in [[:space:]]*\|*|\|*) continue ;; esac
      pair="$(printf '%s' "${line}" | grep -oiE '[0-9]+ agentes[[:space:]]*[e,][[:space:]]*[0-9]+ comandos' || true)"
      [ -z "${pair}" ] && continue
      num="$(printf '%s' "${pair}" | grep -oE '^[0-9]+')"
      ct="$(printf '%s' "${pair}" | grep -oE '[0-9]+ comandos' | grep -oE '^[0-9]+')"
      if [ -n "${num}" ] && [ "${num}" != "${agent}" ]; then
        violation "SOFT" "${f}" "contagem-total de agentes divergente da SSOT: '${pair}' (esperado ${agent}) — /meta:inventory"
      fi
      if [ -n "${ct}" ] && [ "${ct}" != "${cmd}" ]; then
        violation "SOFT" "${f}" "contagem-total de comandos divergente da SSOT: '${pair}' (esperado ${cmd}) — /meta:inventory"
      fi
    done < <(grep -iE '[0-9]+ agentes[[:space:]]*[e,][[:space:]]*[0-9]+ comandos' "${f}" 2>/dev/null)

    # 'N Knowledge Bases' — frase-de-total (forma curta 'KBs' é ambígua em exemplos → não usada)
    while IFS= read -r n; do
      if [ -n "${n}" ] && [ "${n}" != "${kb}" ]; then
        violation "SOFT" "${f}" "contagem-total de KBs divergente da SSOT: '${n} Knowledge Bases' (esperado ${kb}) — /meta:inventory"
      fi
    done < <(grep -oiE '[0-9]+ knowledge bases' "${f}" 2>/dev/null | grep -oE '^[0-9]+')

    # '(N total)' — forma PARENTÉTICA (ex.: header '### Agentes Disponíveis (49 total)').
    # '(N total)' isolado é AMBÍGUO (cmd? agente?) → ANCORA no substantivo da MESMA linha.
    # Guarda anti-tabela: linhas iniciadas por '|' são breakdown, não total.
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      case "${line}" in [[:space:]]*\|*|\|*) continue ;; esac
      n="$(printf '%s' "${line}" | grep -oiE '\([0-9]+ total' | grep -oE '[0-9]+' | head -1 || true)"
      [ -z "${n}" ] && continue
      if printf '%s' "${line}" | grep -qiE 'agentes'; then
        if [ "${n}" != "${agent}" ]; then
          violation "SOFT" "${f}" "contagem-total de agentes divergente da SSOT: '(${n} total)' (esperado ${agent}) — /meta:inventory"
        fi
      elif printf '%s' "${line}" | grep -qiE 'comandos'; then
        if [ "${n}" != "${cmd}" ]; then
          violation "SOFT" "${f}" "contagem-total de comandos divergente da SSOT: '(${n} total)' (esperado ${cmd}) — /meta:inventory"
        fi
      fi
    done < <(grep -iE '\([0-9]+ total' "${f}" 2>/dev/null)

    # 'N+ comandos|agentes' — forma APROXIMADA (ex.: 'ecossistema de 60+ comandos').
    # GUARDA ANTI-ORQUESTRAÇÃO: pula ranges 'A-B+' (o '[^0-9-]' barra o número precedido de '-')
    # e linhas de métrica de EXECUÇÃO (paralel/frota/fan-out/...), que usam 'N+ agentes'
    # para carga de runtime — NÃO inventário (FP real: agent-orchestration-landscape KB).
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      case "${line}" in [[:space:]]*\|*|\|*) continue ;; esac
      if printf '%s' "${line}" | grep -qiE 'paralel|orquestração de workers|orquestração paralela|orchestrator-worker|frota|fan-out|simultân|supervision'; then continue; fi
      n="$(printf '%s' "${line}" | grep -oiE '(^|[^0-9-])[0-9]+\+ comandos' | grep -oE '[0-9]+' | head -1 || true)"
      if [ -n "${n}" ] && [ "${n}" != "${cmd}" ]; then
        violation "SOFT" "${f}" "contagem aproximada de comandos divergente da SSOT: '${n}+ comandos' (esperado ${cmd}+) — /meta:inventory"
      fi
      n="$(printf '%s' "${line}" | grep -oiE '(^|[^0-9-])[0-9]+\+ agentes' | grep -oE '[0-9]+' | head -1 || true)"
      if [ -n "${n}" ] && [ "${n}" != "${agent}" ]; then
        violation "SOFT" "${f}" "contagem aproximada de agentes divergente da SSOT: '${n}+ agentes' (esperado ${agent}+) — /meta:inventory"
      fi
    done < <(grep -iE '[0-9]+\+ (comandos|agentes)' "${f}" 2>/dev/null)

    # 'N comandos, M agentes, P skills, K knowledge bases' — forma COMPOSTA numa linha.
    # Ordem comandos→agentes é INVERSA da combinada 'N agentes e M comandos' (acima) → não colidem.
    # O feeder EXIGE a forma CANÔNICA COMPLETA (até 'knowledge bases'): uma enumeração
    # parcial com reticências (ex.: '(79 comandos, 38 agentes, 4 skills…)' em prosa que
    # DESCREVE o anti-padrão de hardcode) é ilustrativa, não um total — não deve flagar.
    # Guarda anti-tabela. Valida cada campo contra sua SSOT.
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      case "${line}" in [[:space:]]*\|*|\|*) continue ;; esac
      cn="$(printf '%s' "${line}" | grep -oiE '[0-9]+ comandos' | grep -oE '^[0-9]+' | head -1 || true)"
      an="$(printf '%s' "${line}" | grep -oiE '[0-9]+ agentes' | grep -oE '^[0-9]+' | head -1 || true)"
      sn="$(printf '%s' "${line}" | grep -oiE '[0-9]+ skills' | grep -oE '^[0-9]+' | head -1 || true)"
      kn="$(printf '%s' "${line}" | grep -oiE '[0-9]+ knowledge bases' | grep -oE '^[0-9]+' | head -1 || true)"
      if [ -n "${cn}" ] && [ "${cn}" != "${cmd}" ]; then
        violation "SOFT" "${f}" "contagem composta de comandos divergente da SSOT: '${cn} comandos' (esperado ${cmd}) — /meta:inventory"
      fi
      if [ -n "${an}" ] && [ "${an}" != "${agent}" ]; then
        violation "SOFT" "${f}" "contagem composta de agentes divergente da SSOT: '${an} agentes' (esperado ${agent}) — /meta:inventory"
      fi
      if [ -n "${sn}" ] && [ "${sn}" != "${skill}" ]; then
        violation "SOFT" "${f}" "contagem composta de skills divergente da SSOT: '${sn} skills' (esperado ${skill}) — /meta:inventory"
      fi
      if [ -n "${kn}" ] && [ "${kn}" != "${kb}" ]; then
        violation "SOFT" "${f}" "contagem composta de KBs divergente da SSOT: '${kn} knowledge bases' (esperado ${kb}) — /meta:inventory"
      fi
    done < <(grep -iE '[0-9]+ comandos,[^|]*[0-9]+ agentes,[^|]*[0-9]+ [Kk]nowledge [Bb]ases' "${f}" 2>/dev/null)

    # 'N agentes especializados' / 'N agentes IA' — forma BARE de total-atual (sem
    # âncora 'em categorias'/total/composto, que as regras acima já cobrem). É campo
    # minado de FALSO-POSITIVO → guarda densa em DUAS camadas:
    #   (1) pula tabelas (|) e linhas de ORQUESTRAÇÃO/EXECUÇÃO/CRIAÇÃO
    #       (paralel|frota|fan-out|simultân|supervision|trabalhando|criad);
    #   (2) SÓ considera linhas com MARCADOR de total-atual — 'especializados' OU ' IA'
    #       (com ou sem '**' do markdown). É o marcador que separa "49 agentes
    #       especializados/IA" [inventário-atual] de: "os 49 agentes usavam Cursor"
    #       [histórico], "5 agentes — frameworks" [breakdown por categoria],
    #       "(20 agentes)" [contagem por-categoria], "49 agentes / 4 skills" [changelog],
    #       "8 agentes · 1.2M tokens" [métrica de run] — nenhum traz o marcador.
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      case "${line}" in [[:space:]]*\|*|\|*) continue ;; esac
      if printf '%s' "${line}" | grep -qiE 'paralel|orquestração de workers|orquestração paralela|orchestrator-worker|frota|fan-out|simultân|supervision|trabalhando|criad'; then continue; fi
      # '(N agentes)' parentético = contagem POR-CATEGORIA/breakdown (ex.: header
      # 'AGENTES ESPECIALIZADOS (3 agentes)'), não total — pula mesmo com marcador.
      if printf '%s' "${line}" | grep -qE '\([0-9]+ agentes\)'; then continue; fi
      printf '%s' "${line}" | grep -qiE 'agentes especializados|agentes\*{0,2} (de )?IA' || continue
      n="$(printf '%s' "${line}" | grep -oiE '[0-9]+ agentes' | grep -oE '^[0-9]+' | head -1 || true)"
      if [ -n "${n}" ] && [ "${n}" != "${agent}" ]; then
        violation "SOFT" "${f}" "contagem-total de agentes divergente da SSOT: '${n} agentes (especializados/IA)' (esperado ${agent}) — /meta:inventory"
      fi
    done < <(grep -iE '[0-9]+ agentes' "${f}" 2>/dev/null)

    # 'N skills' — forma BARE do total (sem 'comandos'/'agentes' companheiros na mesma
    # frase, que os padrões compostos acima já cobrem). Achado PR #517: 'N skills'
    # driftou em docs/INDEX.md e na KB de identidade SEM nenhum feeder disparar — a
    # única forma composta ('N comandos, M agentes, P skills, K knowledge bases') exige
    # as QUATRO contagens juntas, e a prosa real usa 'skills' isolado ('**11 skills**
    # em `.claude/skills/`', '5 skills de orquestração'). ÂNCORA obrigatória — 'skills'
    # sozinho é ruído comum demais em prosa ('soft skills', 'skills de comunicação do
    # time') para o SOFT confiar sem marcador; exige '.claude/skills/' OU 'skills de
    # orquestração' na MESMA linha — as duas formas que o corpus usa de fato para o
    # total. Guarda anti-tabela: a forma tabular tem feeder PRÓPRIO logo abaixo (o
    # valor não é a 1ª palavra da linha ali, então esta guarda não competiria).
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      case "${line}" in [[:space:]]*\|*|\|*) continue ;; esac
      printf '%s' "${line}" | grep -qE '\.claude/skills/|skills de orquestração' || continue
      n="$(printf '%s' "${line}" | grep -oiE '[0-9]+ skills' | grep -oE '^[0-9]+' | head -1 || true)"
      if [ -n "${n}" ] && [ "${n}" != "${skill}" ]; then
        violation "SOFT" "${f}" "contagem-total de skills divergente da SSOT: '${n} skills' (esperado ${skill}) — /meta:inventory"
      fi
    done < <(grep -iE '[0-9]+ skills' "${f}" 2>/dev/null)

    # 'Knowledge Bases (N documentos...)' — forma PARENTÉTICA INVERTIDA (substantivo
    # ANTES do número; achado PR #517, a 2ª classe que escapou). Âncora 'documentos'
    # logo após o número — não 'arquivos': esse termo tem semântica DIFERENTE em
    # sítios reais (.claude/commands/warm-up.md, docs/INDEX.md usam '(N arquivos,
    # incl. index)' = contagem de ARQUIVO físico, +1 pelo próprio index.md — não o
    # total de KBs do inventário). Casar 'arquivos' também flagaria essa forma
    # legítima como falso-positivo.
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      n="$(printf '%s' "${line}" | grep -oiE 'knowledge bases \([0-9]+ documentos' | grep -oE '[0-9]+' | head -1 || true)"
      [ -z "${n}" ] && continue
      if [ "${n}" != "${kb}" ]; then
        violation "SOFT" "${f}" "contagem-total de KBs divergente da SSOT: 'Knowledge Bases (${n} documentos)' (esperado ${kb}) — /meta:inventory"
      fi
    done < <(grep -iE 'knowledge bases \([0-9]+ documentos' "${f}" 2>/dev/null)

    # FORMA INVERTIDA em TABELA rótulo→valor (achado PR #517, a mesma 2ª classe): o
    # número é a 2ª CÉLULA, não a 1ª palavra da linha — por isso as guardas anti-
    # tabela das frases acima (que pulam TODA linha '|') não competem aqui, e esta é
    # a única forma que PRECISA da linha '|' para disparar. Rótulos restritos aos 4
    # canônicos (forma curta e longa de comandos/agentes) para não colidir com
    # tabelas de BREAKDOWN que reusam a palavra em métrica de FROTA/RUN (ex.: '|
    # Agentes | 36 (9 scan + 27 juízes) |' — vive hoje só em docs/analysis/, já
    # isento pelo escopo, mas a restrição de rótulo vale por doutrina, não por sorte
    # de escopo). Extrai o PRIMEIRO inteiro da célula de valor — mesma doutrina do
    # '(N total)' parentético acima.
    while IFS= read -r line; do
      [ -z "${line}" ] && continue
      lbl=""
      case "${line}" in
        '| Comandos invocáveis |'*|'| Comandos |'*)   lbl="cmd" ;;
        '| Agentes especializados |'*|'| Agentes |'*) lbl="agent" ;;
        '| Skills |'*)                                lbl="skill" ;;
        '| Knowledge Bases |'*)                        lbl="kb" ;;
        *) continue ;;
      esac
      n="$(printf '%s' "${line}" | cut -d'|' -f3 | grep -oE '[0-9]+' | head -1 || true)"
      [ -z "${n}" ] && continue
      case "${lbl}" in
        cmd)   [ "${n}" != "${cmd}" ]   && violation "SOFT" "${f}" "contagem-total de comandos divergente da SSOT (forma tabela): '${n}' (esperado ${cmd}) — /meta:inventory" ;;
        agent) [ "${n}" != "${agent}" ] && violation "SOFT" "${f}" "contagem-total de agentes divergente da SSOT (forma tabela): '${n}' (esperado ${agent}) — /meta:inventory" ;;
        skill) [ "${n}" != "${skill}" ] && violation "SOFT" "${f}" "contagem-total de skills divergente da SSOT (forma tabela): '${n}' (esperado ${skill}) — /meta:inventory" ;;
        kb)    [ "${n}" != "${kb}" ]    && violation "SOFT" "${f}" "contagem-total de KBs divergente da SSOT (forma tabela): '${n}' (esperado ${kb}) — /meta:inventory" ;;
      esac
    done < <(grep -E '^\|[[:space:]]*(Comandos invocáveis|Comandos|Agentes especializados|Agentes|Skills|Knowledge Bases)[[:space:]]*\|' "${f}" 2>/dev/null)
  # PRÉ-FILTRO (perf, 2026-07-13): só varre .md que CONTÊM uma frase-de-contagem candidata.
  #   Antes: 750 arquivos × ~8 greps/arquivo (esta é ~50% do tempo total do lint); ~90% dos .md
  #   não têm número+substantivo-de-inventário → puro overhead. O pattern abaixo é SUPERSET de
  #   TODAS as 8 patterns internas (comandos|agentes|knowledge bases|categorias|skills; '\+?' cobre
  #   a forma aproximada 'N+ comandos'; '(N total' cobre a parentética) → nenhum arquivo candidato
  #   é excluído: comportamento IDÊNTICO (arquivo sem match não geraria violação alguma).
  #   'xargs -r' evita rodar grep quando _find não emite nada (ex.: ONLY_PATH fora das raízes).
  #   ⚠️ INVARIANTE QUEBRADA E RESTAURADA (2026-08-03): os feeders de forma INVERTIDA
  #   (substantivo ANTES do número — `| Skills | 14 |` e `Knowledge Bases (87 documentos)`)
  #   nasceram sem alternativa correspondente aqui. O pattern antigo exigia
  #   `[0-9]+ <substantivo>`, então um arquivo que só tivesse a forma invertida era
  #   EXCLUÍDO antes de chegar ao feeder — cego por construção. Só era visto quando o
  #   arquivo tinha, por acaso, também uma frase em prosa (foi o caso do getting-started,
  #   que mascarou o furo). Duas fixtures BAD não dispararam e expuseram isto.
  #   O superset acima é PROMESSA VERIFICÁVEL: feeder novo exige alternativa nova aqui.
  done < <(_find "${CLAUDE_DIR}" "${REPO_ROOT}/docs" -name "*.md" -print0 2>/dev/null \
    | xargs -0 -r grep -lZ -iE '[0-9]+\+?[[:space:]]+(comandos|agentes|knowledge[[:space:]]+bases|categorias|skills)|\([0-9]+[[:space:]]+total|^\|[[:space:]]*(comandos|comandos[[:space:]]+invocáveis|agentes|agentes[[:space:]]+especializados|skills|knowledge[[:space:]]+bases)[[:space:]]*\||(comandos|agentes|skills|knowledge[[:space:]]+bases)[[:space:]]*\([0-9]' 2>/dev/null)
}

# ===========================================================================
# REGRA 17 — Frontmatter: valor escalar com ': ' não-aspado [HARD]
# previne: YAML de frontmatter quebrado por escalar com ': ' não-aspado
#   Causa-raiz do "metadata dropada" no Claude Code (YAML: "mapping values are
#   not allowed here"): um valor de frontmatter NÃO-aspado contendo ': '
#   (dois-pontos-espaço) — ex.: `description: Foo (ex: bar)`. Quebrou 22 artefatos
#   e passou batido pelo lint (grep não parseia YAML). Guarda determinística (awk,
#   sem dependência → vale igual em pre-commit e CI). Validação YAML COMPLETA é do
#   `claude plugin validate` (fluxo de plugin); esta regra cobre a classe que de fato bate.
# ===========================================================================
check_frontmatter_scalar_colon() {
  while IFS= read -r -d '' f; do
    head -1 "${f}" | grep -q '^---$' || continue   # só arquivos com bloco de frontmatter
    awk '
      NR==1 && $0=="---" { infm=1; next }
      infm && $0=="---"  { exit }
      infm {
        if (match($0, /^[[:space:]]*[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]+/)) {
          val = substr($0, RLENGTH+1)
          sub(/[[:space:]]#.*$/, "", val)                 # remove comentário inline
          first = substr(val, 1, 1)
          if (first=="\047"||first=="\042"||first=="|"||first==">"||first=="["||first=="{"||first=="&"||first=="*"||first=="#") next
          if (index(val, ": ") > 0) print NR
        }
      }
    ' "${f}" | while IFS= read -r badln; do
      violation "HARD" "${f}" "frontmatter linha ${badln}: valor escalar com ': ' não-aspado (quebra o YAML → metadata dropada no Claude Code; aspe o valor)"
    done
  done < <(_find "${CLAUDE_DIR}/agents" "${CLAUDE_DIR}/commands" -name '*.md' ! -path '*/validation/fixtures/*' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 18 — Sem documentação versionada sob .claude/docs/ [HARD]
# previne: documentação versionada no lugar errado (.claude/docs/)
#   architecture.md §2: artefato invocável vive em .claude/; descrição/análise
#   vive em docs/ (raiz). .claude/docs/ é um ponto cego (não varrido pelas demais
#   regras), onde cruft stale/de-dialeto-errado se esconde. Esta guarda impede a
#   reacumulação. Insumos OPERACIONAIS de agentes (templates/regras) vão para
#   .claude/utils/ (ex.: c4-*.md), não .claude/docs/.
# ===========================================================================
check_no_claude_docs() {
  local d="${CLAUDE_DIR}/docs"
  [ -d "${d}" ] || return 0
  while IFS= read -r -d '' f; do
    violation "HARD" "${f}" "documentação sob .claude/docs/ — proibido (architecture.md §2: docs vivem em docs/; insumos de agente em .claude/utils/). Mova ou remova."
  done < <(_find "${d}" -name '*.md' -print0 2>/dev/null)
}

# ===========================================================================
# MODO --fix — propaga a SSOT para as frases-de-total divergentes
#   SEGURANÇA: cada sed casa a FRASE CANÔNICA INTEIRA e o backreference reproduz
#   as palavras-âncora (' comandos invocáveis', ' em N categorias', …). Nunca um
#   'sed s/85/86/' cego — um número solto (ano, '9 categorias' correto) jamais é
#   tocado. ESCOPO idêntico ao da detecção (inventory_scope_excluded). IDEMPOTENTE:
#   se já está na SSOT, o sed reescreve para o mesmo valor → bytes idênticos.
# ===========================================================================
_apply_fix_file() {            # $1=arquivo  $2=programa sed -E
  local file="$1" prog="$2"
  local tmp; tmp="$(mktemp)"
  sed -E "${prog}" "${file}" > "${tmp}" 2>/dev/null || { rm -f "${tmp}"; return; }
  if ! diff -q "${file}" "${tmp}" >/dev/null 2>&1; then
    while IFS= read -r dline; do
      FIX_LOG+=("${file#${REPO_ROOT}/}: ${dline}")
    done < <(diff "${file}" "${tmp}" | grep -E '^[<>]' || true)
    cat "${tmp}" > "${file}"
    FIXED_FILES=$(( FIXED_FILES + 1 ))
  fi
  rm -f "${tmp}"
}

run_inventory_fixes() {
  local env_out cmd agent cats agent_cats kb skill prog
  env_out="$(bash "${SCRIPT_DIR}/inventory.sh" --env 2>/dev/null || true)"
  cmd="$(printf '%s\n'   "${env_out}" | grep '^ONION_COMMANDS_TOTAL='     | cut -d= -f2)"
  agent="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENTS_TOTAL='       | cut -d= -f2)"
  cats="$(printf '%s\n'  "${env_out}" | grep '^ONION_COMMAND_CATEGORIES=' | cut -d= -f2)"
  agent_cats="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENT_CATEGORIES=' | cut -d= -f2)"  # ≠ cats
  kb="$(printf '%s\n'    "${env_out}" | grep '^ONION_KBS_TOTAL='          | cut -d= -f2)"
  skill="$(printf '%s\n' "${env_out}" | grep '^ONION_SKILLS_TOTAL='       | cut -d= -f2)"
  [ -n "${cmd}" ] || return 0

  # REGRA 8 — a SSOT é REGENERADA (nunca editada frase-a-frase); materializa a
  # verdade que as frases derivam. inventory.md é isento das reescritas seguintes.
  bash "${SCRIPT_DIR}/inventory.sh" --markdown > "${REPO_ROOT}/docs/onion/inventory.md" 2>/dev/null || true

  # Mesmo conjunto de frases canônicas da detecção (REGRA 16). Frases com DUAS
  # contagens reescrevem ambas numa só substituição (o \N preserva o miolo/cauda).
  prog="s/[0-9]+( comandos invocáveis)/${cmd}\1/g"
  prog="${prog}; s/([0-9]+)( comandos[^.,|]*em )([0-9]+)( categorias)/${cmd}\2${cats}\4/g"
  prog="${prog}; s/([0-9]+)( agentes[^.,|]*em )([0-9]+)( categorias)/${agent}\2${agent_cats}\4/g"
  prog="${prog}; /^[[:space:]]*\|/! s/([0-9]+)( agentes[[:space:]]*[e,][[:space:]]*)([0-9]+)( comandos)/${agent}\2${cmd}\4/g"
  prog="${prog}; s/[0-9]+( [Kk]nowledge [Bb]ases)/${kb}\1/g"
  # Formatos AMPLIADOS (espelham a detecção da Regra 16):
  # (a) parentético '(N total)' — ancora no substantivo; '[^()]*' não atravessa o parêntese
  prog="${prog}; s/([Aa]gentes[^()]*\()[0-9]+( total)/\1${agent}\2/g"
  prog="${prog}; s/([Cc]omandos[^()]*\()[0-9]+( total)/\1${cmd}\2/g"
  # (b) aproximado 'N+ comandos|agentes' — preserva o '+'; '[^0-9-]' impede tocar ranges 'A-B+'
  #     (métrica de orquestração, ex.: '8-16+ agentes paralelos'). Risco residual: 'N+ agentes' SEM range
  #     em linha de orquestração não tem guarda 'paralel' por-linha (sed é global) → coberto pela revisão do diff.
  prog="${prog}; s/([^0-9-])[0-9]+(\+ comandos)/\1${cmd}\2/g"
  prog="${prog}; s/([^0-9-])[0-9]+(\+ agentes)/\1${agent}\2/g"
  # (c) composto 'N comandos, M agentes, P skills, K knowledge bases' — reescreve os 4 campos de uma vez
  prog="${prog}; s/[0-9]+( comandos, )[0-9]+( agentes, )[0-9]+( skills, )[0-9]+( [Kk]nowledge [Bb]ases)/${cmd}\1${agent}\2${skill}\3${kb}\4/g"
  # (d) BARE 'N agentes especializados/IA' — só formas SED-SEGURAS (sed é global, sem guarda
  #     por-linha): fim-de-linha/pontuação (não toca 'especializados criados'), 'especializados
  #     de IA', e '** IA' do markdown. As variantes amorfas (ex.: 'N agentes + matriz') ficam só
  #     na DETECÇÃO (SOFT avisa) + correção à mão. Marcador especializados/IA = anti-histórico.
  prog="${prog}; s/[0-9]+( agentes especializados)([.,;:)]|[[:space:]]*\$)/${agent}\1\2/g"
  prog="${prog}; s/[0-9]+( agentes especializados de IA)/${agent}\1/g"
  prog="${prog}; s/[0-9]+( agentes\*{0,2} IA)/${agent}\1/g"

  while IFS= read -r -d '' f; do
    inventory_scope_excluded "${f}" && continue
    _apply_fix_file "${f}" "${prog}"
  done < <(_find "${CLAUDE_DIR}" "${REPO_ROOT}/docs" -name "*.md" -print0 2>/dev/null)

  # CLAUDE.md vive na RAIZ do repo — FORA dos roots varridos (.claude/, docs/),
  # então o loop acima NÃO o alcança (a detecção R9 cobre suas contagens, não a
  # R16). Aplica o MESMO programa de frases canônicas + o fix de 'N skills' (forma
  # curta, seguro só aqui: ocorrência única canônica que espelha a R9 HARD).
  # ISENÇÃO OBRIGATÓRIA, e ela faltava: o laço acima honra inventory_scope_excluded, mas este
  # ramo tratava o CLAUDE.md da raiz FORA dele — violando o invariante declarado no cabeçalho
  # deste bloco ("o --fix NUNCA toca um arquivo que a detecção isenta").
  # DANO MEDIDO em revisão adversarial (2026-08-06), com diff: num repo `role: adopted`, o
  # CLAUDE.md da raiz é o doc de PRODUTO do cliente — a detecção corretamente o isenta, e o --fix
  # gravava nele a contagem de skills do ONION, transformando uma frase verdadeira sobre o produto
  # dele numa AFIRMAÇÃO FALSA. Corromper dado do adotante é pior que qualquer falso-positivo.
  if [ -f "${REPO_ROOT}/CLAUDE.md" ] && ! inventory_scope_excluded "${REPO_ROOT}/CLAUDE.md"; then
    _apply_fix_file "${REPO_ROOT}/CLAUDE.md" "${prog}; s/[0-9]+( skills)/${skill}\1/g"
  fi
}

# ===========================================================================
# REGRA 22 — Links relativos quebrados em docs/evolution/ e docs/knowledge-base/ [HARD]
# previne: link relativo quebrado em docs/evolution ou docs/knowledge-base
#   Origem: auditoria 2026-07-04 (alerta transversal nº 1) + Q_LINT_LINKS do KG —
#   o ritual de triagem (git mv → _processed/) quebra quem aponta pro arquivo
#   movido; 4 dos 16 achados confirmados eram exatamente isso.
#   Extensão 2026-07-13 (sinal de campo A2, dogfood pre-pr onion-guardrails): o
#   escopo cobria só docs/evolution/, então link quebrado em KB só era pego por
#   revisor semântico. Estendido a docs/knowledge-base/ — guardrail determinístico
#   de integridade de link de KB (categoria ONION-R1). Dry-run pré-fiação: 74 KBs,
#   0 quebrados, 0 falso-positivo → extensão segura.
#   Lições dos 3 falso-positivos REFUTADOS pelo juiz (viram requisitos):
#   - IGNORA conteúdo dentro de code fences ``` (E_J_FENCES — templates de
#     geração citam paths do arquivo GERADO, não deste);
#   - ACEITA link de diretório (D7-18 — link de coleção é legítimo; test -e).
#   Âncora (#...) é removida antes do teste; http(s)/mailto/absoluto/só-âncora
#   ficam fora do escopo. Determinístico, sem jq.
# ===========================================================================
# Scanner genérico — varre <base> e emite violação por link relativo que não
# resolve, com <hint> de correção específico do escopo. Reusado pelos dois checks.
_scan_relative_links() {
  local base="$1" hint="$2"
  [ -d "${base}" ] || return 0
  # Role-guard (sinal de campo 2026-07-16): o adotante NÃO vendoriza os docs core-only
  # (analysis/evolution/discussions/applying/materials/plans/onion) — um doc vendorizado (KB/comando)
  # que os referencia resolve no CORE, mas o alvo é ausente-por-desenho no adotante. Pular SÓ o
  # alvo-ausente que cai nesses prefixos; a checagem de link KB-interno (arquivo que DEVERIA existir)
  # continua ativa. No core (role: source) o guard é no-op (os docs existem).
  #
  # Extensão porta-de-framework (ADR onion-adr-family-repo-topology-2026-07 D4 + roles.yaml): um door
  # role-scoped (bundle 'standalone') SELA a meta-factory (commands/meta + agents/meta) e os verticais
  # não-base (design/development/quick commands; compliance/research agents; lint-selftest e demais
  # validações meta). KBs de doutrina embarcados citam esses arquivos por link — ausentes-por-desenho no
  # door, exatamente como os docs core-only. Só ATIVA quando o alvo está ausente ([ ! -e ] abaixo): num
  # adotante-cheio o alvo existe (nunca entra); no core (role: source) o guard nem roda. Backward-safe.
  local adopted=""; [ "${IS_DERIVED}" -eq 1 ] && adopted=1
  local f dir lineno target clean rel
  while IFS= read -r -d '' f; do
    dir="$(dirname "${f}")"
    while IFS=$'\t' read -r lineno target; do
      [ -n "${target}" ] || continue
      clean="${target%%#*}"
      [ -n "${clean}" ] || continue
      if [ ! -e "${dir}/${clean}" ]; then
        if [ -n "${adopted}" ]; then
          rel="$(realpath -m --relative-to="${REPO_ROOT}" "${dir}/${clean}" 2>/dev/null)"
          case "${rel}" in
            docs/analysis/*|docs/evolution/*|docs/discussions/*|docs/applying/*|docs/materials/*|docs/plans/*|docs/onion/*) continue ;;
            # meta-factory + verticais não-base selados num door role-scoped (ausente-por-desenho)
            .claude/commands/meta/*|.claude/commands/design/*|.claude/commands/development/*|.claude/commands/quick/*) continue ;;
            .claude/agents/meta/*|.claude/agents/compliance/*|.claude/agents/research/*) continue ;;
            .claude/validation/lint-selftest.sh|.claude/validation/federation-*|.claude/validation/kg-*|.claude/validation/graph.sh|.claude/validation/constellation-map.sh|.claude/validation/diary-index.sh|.claude/validation/a2a-*|.claude/validation/trust-topology-check.sh|.claude/validation/lint-design-tokens.sh) continue ;;
          esac
        fi
        violation "HARD" "${f}" "link relativo quebrado (linha ${lineno}): '${target}' não resolve — ${hint}"
      fi
    done < <(awk '
      /^[[:space:]]*```/ { fence = !fence; next }
      fence { next }
      {
        line = $0
        while (match(line, /\]\(([^)]+)\)/)) {
          tgt = substr(line, RSTART + 2, RLENGTH - 3)
          line = substr(line, RSTART + RLENGTH)
          if (tgt ~ /^(https?|mailto):/) continue
          if (tgt ~ /^\//) continue
          if (tgt ~ /^#/) continue
          printf "%d\t%s\n", NR, tgt
        }
      }
    ' "${f}")
  done < <(_find "${base}" -name '*.md' -print0 2>/dev/null)
}

check_evolution_links() {
  _scan_relative_links "${REPO_ROOT}/docs/evolution" \
    "alvo movido para _processed/? atualize o link junto com o git mv"
}

check_knowledge_base_links() {
  _scan_relative_links "${REPO_ROOT}/docs/knowledge-base" \
    "KB movida/renomeada? atualize o link (a integridade de SSOT é gate, não só revisão semântica)"
}

# ===========================================================================
# REGRA 26 — Pesquisa nasce em KG, não morre em prosa [HARD]
# previne: pesquisa morrendo em prosa, sem .kg.yaml irmão (não nasce no grafo)
#   Toda pasta docs/evolution/research/<tema>/ com SYNTHESIS.md exige um <tema>.kg.yaml
#   irmão (doutrina 2026-07-17, born-in-KG — o antídoto do "17/7/2": a contagem de
#   achados vira consultável pelo radar, não re-derivável da prosa). Legadas pré-doutrina
#   sem KG = DEBITO DE MIGRACAO nomeado na allowlist (nao anistia silenciosa — sai da lista
#   quando migrar). Origem: 1a pesquisa nascida em KG (research/whatsapp-api-2026-07).
# ===========================================================================
check_research_kg() {
  local base="${REPO_ROOT}/docs/evolution/research"
  [ -d "${base}" ] || return 0
  local legacy=" federation-2026 knowledge-centric-ssot-2026 spec-as-code-evolution-2026 "
  local dir tema
  for dir in "${base}"/*/; do
    [ -f "${dir}SYNTHESIS.md" ] || continue
    tema="$(basename "${dir}")"
    if ! ls "${dir}"*.kg.yaml >/dev/null 2>&1; then
      case "${legacy}" in
        *" ${tema} "*) : ;;
        *) violation "HARD" "${dir}" "pesquisa sem .kg.yaml — toda pesquisa NOVA nasce em KG (nao morre em prosa; doutrina 2026-07-17). Modele e valide: bash .claude/validation/kg-radar.sh ${dir}<tema>.kg.yaml" ;;
      esac
    fi
  done
}

# ===========================================================================
# REGRA 29 — Gate de PROVENIÊNCIA INVERTIDO, com catraca [HARD + SOFT]
# previne: relatório de análise órfão do grafo (nenhum nó o cita)
#   Espelho da REGRA 26 e do kg-radar. O radar pergunta "esta DECISÃO tem
#   origem?"; a R26 pergunta "esta PASTA de pesquisa tem .kg.yaml?". Falta a
#   terceira: "este DOCUMENTO existe no grafo?" — coberto = algum nó de algum
#   .kg.yaml o cita em trace:/evidence:.
#   Origem de campo: sinal de um adotante regulado 2026-07-20 (docs/evolution/inbox/_processed/
#   2026-07-20-gate-proveniencia-invertido.md) — a doutrina KG-SSOT tinha forcing
#   function só na LEITURA; nada impedia conhecimento de NASCER fora do grafo.
#   CATRACA (o que torna adotável): passivo no baseline versionado = SOFT;
#   documento NOVO fora do baseline e sem nó = HARD; baseline que CRESCE = HARD.
#   Toda a lógica (escopo, exclusões, catraca) vive em kg-provenance-coverage.sh,
#   com o PORQUÊ de cada exclusão no cabeçalho de lá.
#   Agregação: a classe PASSIVO sai como UMA linha SOFT com a contagem (dezenas de
#   linhas idênticas afogariam as classes acionáveis); as demais, individualmente.
# ===========================================================================
check_kg_provenance_coverage() {
  local helper="${SCRIPT_DIR}/kg-provenance-coverage.sh"
  [ -f "${helper}" ] || return 0
  # Honra --only com a MESMA semântica do _find: alvo fora das raízes desta regra
  # → nada a varrer (é o que dá ao selftest O(fixtures × 1)).
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      "${REPO_ROOT}"/docs/analysis/*|"${REPO_ROOT}"/docs/evolution/research/*|*/kg-coverage-baseline.txt) : ;;
      *) return 0 ;;
    esac
  fi
  local out passivo=0 sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    if [ "${tag}" = "PASSIVO" ]; then passivo=$(( passivo + 1 )); continue; fi
    violation "${sev}" "${REPO_ROOT}/${path}" "[proveniência-invertida/${tag}] ${msg}"
  done <<< "${out}"
  if [ "${passivo}" -gt 0 ]; then
    violation "SOFT" "${REPO_ROOT}/.claude/validation/kg-coverage-baseline.txt" \
      "[proveniência-invertida/PASSIVO] ${passivo} documento(s) de análise ainda sem nó no grafo, tolerados pelo baseline — a métrica de saúde é este número DIMINUINDO (detalhe: bash .claude/validation/kg-provenance-coverage.sh)"
  fi
}

# ===========================================================================
# REGRA 49 — Nó plane:PROD de alto impacto carrega VERIFICAÇÃO, com catraca [HARD + SOFT]
# previne: nó afirmando sobre produção sem nunca ter sido medido contra o vivo
#   Terceiro irmão da família de catraca (29 = documento existe no grafo; 42 = doutrina
#   carimbada e dentro do TTL; 49 = nó que AFIRMA SOBRE PRODUÇÃO foi medido alguma vez).
#   Origem: o kg-radar DETECTA frescor (STALE-MISSING/OLD/UNANCHORED) e PARA AÍ, como
#   "⚠ atenção, NÃO reprova" — logo o passivo CRESCE SEM LIMITE. Medido 2026-08-02:
#   53 nós vivos plane:PROD impact>=4 sem NENHUM verified_at.
#   O GATILHO É O DESENHO: esta regra nunca manda rodar /meta:kg-freshness — ela torna
#   RODÁ-LO a única forma de encolher o baseline. A cadência vem do trabalho, não do aviso.
#   LIMITE HONESTO (igual à 42): não checa se o carimbo é VERDADE, só que existe. Quem
#   testa a verdade é o worker do kg-freshness, contra o vivo.
#   Toda a lógica (escopo, catraca, fail-closed) vive em kg-verification-coverage.sh.
#   MEIA-VIDA POR CLASSE fica GATED (hoje 0 nós com carimbo vencido — regra sobre conjunto
#   vazio é cerimônia): docs/analysis/onion-adr-kg-halflife-2026-08.md.
# ===========================================================================
check_kg_verification_coverage() {
  local helper="${SCRIPT_DIR}/kg-verification-coverage.sh"
  [ -f "${helper}" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      *.kg.yaml|*/kg-verification-baseline.txt) : ;;
      *) return 0 ;;
    esac
  fi
  local out passivo=0 sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    if [ "${tag}" = "PASSIVO" ]; then passivo=$(( passivo + 1 )); continue; fi
    violation "${sev}" "${REPO_ROOT}/${path}" "[kg-verificacao/${tag}] ${msg}"
  done <<< "${out}"
  if [ "${passivo}" -gt 0 ]; then
    violation "SOFT" "${REPO_ROOT}/.claude/validation/kg-verification-baseline.txt" \
      "[kg-verificacao/PASSIVO] ${passivo} no(s) plane:PROD impact>=4 ainda sem verified_at, tolerados pelo baseline — a metrica de saude e este numero DIMINUINDO (/meta:kg-freshness mede, voce carimba)"
  fi
}

# ===========================================================================
# REGRA 42 — Gate de FRESCOR DOUTRINÁRIO, com catraca [HARD + SOFT]
# previne: afirmação sensível-ao-tempo sem carimbo ou fora do TTL
#   Irmão TEMPORAL da REGRA 29. A 29 fecha conhecimento nascendo FORA do grafo
#   (eixo ESPACIAL); esta fecha a afirmação doutrinária que EXPIROU EM SILÊNCIO
#   (eixo TEMPORAL). Ambas são declarado≠verificado — uma contra o grafo, outra
#   contra o TEMPO. Generaliza o STALE-OLD do kg-radar (verified_at vencido) de
#   NÓ de grafo para AFIRMAÇÃO de doutrina em prosa de KB.
#   Origem de campo (world-sync 2026-07-20/23): o cutoff do modelo é jan/2026; uma
#   KB dizendo "o lineup vigente é X" vira MENTIRA em julho sem uma linha do repo
#   mudar — e o world-sync achou tier acima do Opus, tetos errados e aspas
#   fabricadas em doutrina "que parecia fina". O gate NÃO checa a web (seria no-op
#   no CI); verifica que todo doc world-facing carrega verified_at (+ source) e que
#   a data não expirou — força re-verificação; quem re-verifica é a sessão.
#   Nível A (lista world-facing enumerada, o único eixo HARD): sem verified_at e
#   FORA do baseline = HARD; no baseline = SOFT (passivo); malformado/futuro = HARD
#   estrutural; > TTL = SOFT (re-verifique); relógio não-confiável degrada a idade
#   a SOFT. Nível B (rede lexical em docs/knowledge-base, SOFT-only): token gatilho
#   sem verified_at = SOFT. Toda a lógica (lista, TTL, relógio, catraca) vive em
#   doctrine-freshness.sh, com o PORQUÊ de cada pressuposto no cabeçalho de lá.
#   Agregação: PASSIVO e LEXICAL saem como UMA linha SOFT com a contagem (dezenas de
#   linhas idênticas afogariam as classes acionáveis); as demais, individualmente.
# ===========================================================================
check_doctrine_freshness() {
  local helper="${SCRIPT_DIR}/doctrine-freshness.sh"
  [ -f "${helper}" ] || return 0
  # Honra --only: as raízes desta regra são a lista world-facing (docs/knowledge-base),
  # o baseline e o próprio helper. Alvo fora disso → nada a varrer (O(fixtures×1)).
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      "${REPO_ROOT}"/docs/knowledge-base/*|*/doctrine-freshness-baseline.txt|"${helper}") : ;;
      *) return 0 ;;
    esac
  fi
  local out passivo=0 lexical=0 sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    case "${tag}" in
      PASSIVO) passivo=$(( passivo + 1 )); continue ;;
      LEXICAL) lexical=$(( lexical + 1 )); continue ;;
    esac
    violation "${sev}" "${REPO_ROOT}/${path}" "[frescor-doutrinário/${tag}] ${msg}"
  done <<< "${out}"
  if [ "${passivo}" -gt 0 ]; then
    violation "SOFT" "${REPO_ROOT}/.claude/validation/doctrine-freshness-baseline.txt" \
      "[frescor-doutrinário/PASSIVO] ${passivo} doc(s) world-facing ainda sem verified_at, tolerados pelo baseline — a métrica de saúde é este número DIMINUINDO (detalhe: bash .claude/validation/doctrine-freshness.sh)"
  fi
  if [ "${lexical}" -gt 0 ]; then
    violation "SOFT" "${REPO_ROOT}/docs/knowledge-base" \
      "[frescor-doutrinário/LEXICAL] ${lexical} doc(s) em docs/knowledge-base usam linguagem sensível-ao-tempo sem verified_at — rede frágil, revise se algum afirma lineup/versão/GA e precisa de carimbo (detalhe: bash .claude/validation/doctrine-freshness.sh)"
  fi
}

# ===========================================================================
# REGRA 43 — Integridade do marcador kg: (proveniência virada p/ DENTRO) [HARD]
# previne: marcador kg: (born-in-graph) inconsistente com o grafo
#   Irmão INTERNO da REGRA 29. A 29 pergunta, de fora do grafo p/ dentro, "este
#   RELATÓRIO existe no grafo?" (algum nó o cita). Esta é de dentro da migalha/doc
#   p/ o grafo: "o grafo que esta migalha DECLARA ter nascido dela é REAL e são?".
#   Quem DECLARA `kg:` no frontmatter (migalha epistêmica ou doc de achado) tem de
#   apontar para um .kg.yaml que EXISTE, é .kg.yaml, e passa no kg-radar --integrity
#   E --schema. Pendurado/não-grafo/radar-reprova ⇒ HARD.
#   CRÍTICO (não é a catraca da 29): a AUSÊNCIA de `kg:` NÃO é violação — as ~72
#   migalhas existentes não declaram kg: e o gate nasce SILENCIOSO. missing != violation
#   ⇒ sem baseline/catraca (pô-los aqui repetiria o erro que a 29 existe p/ não repetir).
#   LIMITE HONESTO: investigação não-declarada é indetectável (pode não tocar o repo)
#   — disciplina + default-path (FASE write(KG) da onion-orchestration), NÃO este gate.
#   Origem: memória do maestro 2026-07-23 (radar sub-usado). Toda a lógica vive em
#   kg-born-marker.sh, com o PORQUÊ de cada pressuposto no cabeçalho de lá.
# ===========================================================================
check_kg_born_marker() {
  local helper="${SCRIPT_DIR}/kg-born-marker.sh"
  [ -f "${helper}" ] || return 0
  # Honra --only: as raízes desta regra são .claude/diary, docs/analysis e
  # docs/evolution/research. Alvo fora disso → nada a varrer (O(fixtures×1)).
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      "${REPO_ROOT}"/.claude/diary/*|"${REPO_ROOT}"/docs/analysis/*|"${REPO_ROOT}"/docs/evolution/research/*) : ;;
      *) return 0 ;;
    esac
  fi
  local out sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    violation "${sev}" "${REPO_ROOT}/${path}" "[marcador-kg/${tag}] ${msg}"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 44 — Integridade da escada de Automação Graduada [HARD]
# previne: classe sobe de degrau sem gate de promoção alcançável (rung-jump forjado)
#   Guarda a máxima do maestro "automação se conquista por ação provada":
#   nenhuma classe de ação sobe de degrau (HUMAN→MONITORED→DYNAMIC→AUTO) sem
#   gate de promoção ALCANÇÁVEL. Delega a ladder-integrity-check.sh (doutrina:
#   graduated-automation-ladder.md). Hoje: 6 HUMAN, 6 STRUCTURAL, 1 MONITORED, 2 MOAT (medido 2026-07-24).
check_ladder_integrity() {
  local helper="${SCRIPT_DIR}/ladder-integrity-check.sh"
  [ -f "${helper}" ] || return 0
  [ -n "${ONLY_PATH}" ] && return 0
  local out sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    violation "${sev}" "${REPO_ROOT}/${path}" "[escada-automacao/${tag}] ${msg}"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 45 — Link vendorizado não aponta caminho core-privado, com catraca [HARD + SOFT]
# previne: link vivo em superfície vendorizada para caminho core-privado — morto no adotante
#   Nenhuma das 9 RAÍZES VENDORIZADAS (as mesmas do `want=` do /meta:adopt e do `roots=`
#   da REGRA 36) deve carregar link VIVO para
#   docs/{analysis,onion,evolution,discussions,applying,materials,plans} ou
#   .claude/{diary,sessions} — ausentes em TODO adotante. O link resolve no core e
#   o lint local passa, mas no adotante é morto (o bug de campo de uma adoção real:
#   link p/ .claude/diary reprovou DENTRO do repo dele; o do core não via).
#   Guard core-side que mecaniza "o adotante é o oráculo": força a conversão em
#   referência plain-text + GLOSS (a essência, fonte≠derivação com dimensão).
#   Catraca idêntica à REGRA 29 (passivo baselined = SOFT; novo = HARD; só encolhe),
#   agora ciente de ESCOPO: o baseline declara `# scope:` e, quando ele muda, a checagem
#   de crescimento é suspensa com SOFT visível — senão a catraca DEFENDERIA o ponto cego
#   que existe para expor (ampliar a varredura dispararia dezenas de CATRACA VIOLADA).
#   Toda a lógica vive em kb-vendored-link-check.sh.
#
#   HISTÓRICO DO PASSIVO (o docstring dizia "nasce com 101" muito depois de o número
#   morrer — `declarado ≠ verificado` dentro da própria guarda, achado 2026-08-03):
#     · nasceu com 101 na KB · drenado a 0 em 165e1e1 · escopo ampliado de 1 para 9
#       raízes em 2026-08-03, revelando 43 links que NENHUMA guarda via.
#   O baseline em 0 tinha DECLARADO VITÓRIA com o mesmo modo de falha vivo em 8 raízes
#   ao lado. Métrica de saúde = o número no CI diminuindo; leia-o, não este comentário.
# ===========================================================================
check_kb_vendored_links() {
  local helper="${SCRIPT_DIR}/kb-vendored-link-check.sh"
  [ -f "${helper}" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      "${REPO_ROOT}"/docs/knowledge-base/*|*/kb-vendored-link-baseline.txt) : ;;
      *) return 0 ;;
    esac
  fi
  local out passivo=0 sev tag path msg
  out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    if [ "${tag}" = "PASSIVO" ]; then passivo=$(( passivo + 1 )); continue; fi
    violation "${sev}" "${REPO_ROOT}/${path}" "[link-vendorizado/${tag}] ${msg}"
  done <<< "${out}"
  if [ "${passivo}" -gt 0 ]; then
    violation "SOFT" "${REPO_ROOT}/.claude/validation/kb-vendored-link-baseline.txt" \
      "[link-vendorizado/PASSIVO] ${passivo} link(s) core-privado(s) em superfície VENDORIZADA (9 raízes, não só a KB), tolerados pelo baseline — a métrica de saúde é este número DIMINUINDO (migre link→plain-text+gloss; detalhe: bash .claude/validation/kb-vendored-link-check.sh)"
  fi
}

# ===========================================================================
# REGRA 32 — Página pública do grafo: números conferidos contra o mapa [HARD]
# previne: página pública do grafo com números que não batem com o mapa
#   A página /historia/grafo/ publica contagens do .kg.yaml em prosa e em
#   BARRAS. Número no site é promessa: se o grafo cresce e a página não, ela
#   mente para o público — e a barra mente pior que o número, porque o leitor
#   a lê sem conferir. Mesmo molde da REGRA 21 (site × inventário).
#   Guarda o QUANTITATIVO. O que ela NÃO guarda, e por isso está declarado no
#   comentário da própria página: a decisão EDITORIAL de não publicar rótulo de
#   nó. A REGRA 30 tampouco cobre isso (só barra nome comercial de parceiro) —
#   conteúdo estratégico é contenção humana, não mecânica. Registrado para que
#   ninguém confunda "o lint passou" com "é seguro publicar".
# ===========================================================================
check_site_graph_sync() {
  local page="${REPO_ROOT}/site/historia/grafo/index.html"
  local view="${SCRIPT_DIR}/kg-view.sh"
  local kg="${REPO_ROOT}/docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml"
  [ -f "${page}" ] || return 0
  [ -f "${view}" ] && [ -f "${kg}" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${page}"|"${kg}") : ;; *) return 0 ;; esac
  fi
  local cov out
  cov="$(bash "${SCRIPT_DIR}/kg-provenance-coverage.sh" "${REPO_ROOT}" 2>/dev/null \
        | awk -F: '/Cobertos pelo grafo/ {gsub(/ /,"",$2); print $2}')"
  out="$(bash "${view}" "${kg}" --json 2>/dev/null | python3 -c '
import json,sys,re
d=json.load(sys.stdin)
page=open(sys.argv[1],encoding="utf-8").read()
cov=sys.argv[2]
truth={"nodes":d["node_count"],"edges":d["edge_count"],"orphans":d["orphans"]}
for k,v in d["by_status"].items(): truth["s:"+k]=v
for k,v in d["by_type"].items():   truth["t:"+k]=v
if cov: truth["coverage"]=int(cov)
bad=[]
seen=set()
for m in re.finditer(r"data-kg=\"([^\"]+)\"[^>]*>([0-9]+)<", page):
    key,claim=m.group(1),int(m.group(2)); seen.add(key)
    if key not in truth: bad.append(f"marcador data-kg=\"{key}\" nao existe no grafo")
    elif truth[key]!=claim: bad.append(f"pagina afirma {claim} para \"{key}\", o grafo tem {truth[key]}")
for k in truth:
    if k not in seen and k.startswith(("s:","t:")):
        bad.append(f"o grafo tem \"{k}\" ({truth[k]}) e a pagina nao mostra — composicao incompleta")
# barras: a largura precisa bater com a proporcao real (tolerancia 0.15pp)
tot_s=sum(d["by_status"].values()); tot_t=sum(d["by_type"].values())
TT={"confirmada":("s:confirmed",tot_s),"em aberto":("s:open",tot_s),"superada":("s:superseded",tot_s),
    "refutada":("s:refuted",tot_s),"encerrada":("s:done",tot_s),
    "afirmação":("t:claim",tot_t),"decisão":("t:decision",tot_t),"evidência":("t:evidence",tot_t),
    "pergunta":("t:question",tot_t),"entidade":("t:entity",tot_t),"artefato":("t:artifact",tot_t)}
for m in re.finditer(r"width:([0-9.]+)%[^\"]*\"\s+title=\"([^\"]+)\"", page):
    w,title=float(m.group(1)),m.group(2)
    if title in TT:
        key,tot=TT[title]
        exp=truth.get(key,0)/tot*100
        if abs(exp-w)>0.15:
            bad.append(f"barra \"{title}\" tem {w}%, o real e {exp:.2f}%")
print("\n".join(bad))
' "${page}" "${cov}")"
  [ -n "${out}" ] || return 0
  while IFS= read -r line; do
    [ -n "${line}" ] || continue
    violation "HARD" "site/historia/grafo/index.html" "[grafo-público] ${line} — regenere os números (bash .claude/validation/kg-view.sh ${kg#${REPO_ROOT}/} --json)"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 31 — Lente do grafo: DERIVADA e em paridade com o motor [HARD]
# previne: lente do grafo divergindo do motor que a deriva
#   Duas obrigações, porque são dois modos de falha distintos:
#   (a) DRIFT DE CONTEÚDO — a lente é gerada de um .kg.yaml; se o grafo mudou e
#       a lente não, ela vira relatório desatualizado com cara de atual (mesma
#       classe das REGRAS 8/21/24 sobre SSOT gerada).
#   (b) DRIFT DE PARSER — kg-view.sh reimplementa o parse do kg-radar.sh. Se os
#       dois saírem de sincronia, a lente mostra um grafo que o motor não vê:
#       mentira com autoridade de projeção. `--assert-parity` é o que torna
#       essa dívida admissível; sem ela, o desvio só apareceria num gráfico
#       errado meses depois.
# ===========================================================================
check_kg_view_sync() {
  local gen="${SCRIPT_DIR}/kg-view.sh"
  [ -f "${gen}" ] || return 0
  local kg lens tmp out
  while IFS= read -r kg; do
    [ -n "${kg}" ] || continue
    lens="${kg%.kg.yaml}-radar.md"
    [ -f "${lens}" ] || continue           # lente é opt-in: só cobra o que existe
    if [ -n "${ONLY_PATH}" ]; then
      case "${ONLY_PATH}" in "${kg}"|"${lens}") : ;; *) continue ;; esac
    fi
    # (b) paridade de parser primeiro — se os parsers divergem, comparar o
    # conteúdo da lente é comparar contra a projeção errada.
    if ! out="$(bash "${gen}" "${kg}" --assert-parity 2>&1)"; then
      violation "HARD" "${lens}" "[lente/PARIDADE] kg-view.sh e kg-radar.sh discordam sobre o tamanho do grafo — a lente está mentindo (${out})"
      continue
    fi
    # (a) drift de conteúdo
    tmp="$(mktemp)"
    if _gen_into "${tmp}" "${lens}" "${lens}" -- bash "${gen}" "${kg}" --markdown &&
       ! diff -q "${lens}" "${tmp}" >/dev/null 2>&1; then
      violation "HARD" "${lens}" "[lente/DRIFT] lente desatualizada vs o grafo — regenere: bash .claude/validation/kg-view.sh ${kg#${REPO_ROOT}/} --markdown > ${lens#${REPO_ROOT}/}"
    fi
    rm -f "${tmp}"
  done < <(find "${REPO_ROOT}/docs" -name '*.kg.yaml' -type f 2>/dev/null | sort)
}

# ===========================================================================
# REGRA 30 — Segurança de PROJEÇÃO: nome comercial de membro privado não sai [HARD]
# previne: nome comercial de membro privado vazando em superfície pública
#   do repo privado [HARD]
#   Origem: incidente 2026-07-10 — o console PÚBLICO da federação vazou
#   "<nome> — CONFIDENCIAL" verbatim, porque o `name:` do members.yaml carrega
#   anotação INTERNA do maestro entre parênteses. A correção nasceu como
#   convenção LOCAL dentro de federation-console.sh (um split + comentário) e,
#   por viver só ali, não alcançava a PRÓXIMA superfície que projetasse para
#   fora — exatamente a forma de falha registrada em
#   .claude/diary/2026-07-20-admission-rule-blindspot.md (cláusula local não
#   alcança o próximo mecanismo). Esta regra é a promoção daquela convenção a
#   guarda compartilhada, com os pressupostos enumerados no próprio helper.
#   Termos são DERIVADOS de members.yaml (nunca hardcoded — nome de cliente no
#   script seria o próprio vazamento).
#   Hub de privacidade: as REGRAS 33 e 36 derivam desta (threat models distintos).
# ===========================================================================
check_projection_safety() {
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  [ -f "${helper}" ] || return 0
  # Honra --only com a MESMA semântica do _find (mantém o selftest O(fixtures × 1)).
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in
      "${REPO_ROOT}"/site/*|"${REPO_ROOT}"/docs/onion/graph/*|*/federation-console.html|*/members.yaml) : ;;
      *) return 0 ;;
    esac
  fi
  # ATENÇÃO (P3 — superfícies são enumeradas, não inferidas): federation-console.html
  # entrou nesta lista porque a 1ª versão da regra NÃO o auditava — e ele é servido
  # em console.onionevolve.com e foi JUSTAMENTE a superfície que vazou em 2026-07-10.
  # Toda superfície pública nova precisa ser acrescentada aqui à mão; o que não está
  # nesta linha é invisível para a guarda.
  local out sev tag path msg
  # SUPERFÍCIES PÚBLICAS — e num ADOTANTE FOLHA elas não são as mesmas. `docs/onion/graph/` e o
  # `federation-console.html` são públicos NO CORE, porque alimentam o console de KG e o mapa da
  # federação que vão para a web. No repo de um `role: adopted` nada disso é publicado: os grafos
  # dele são privados e nomear o próprio cliente ali é legítimo, não vazamento.
  # MEDIDO 2026-08-06: um adotante levou HARD por citar a MARCA DELE no grafo DELE, dentro do
  # repo DELE. `site/` FICA no escopo — um adotante pode publicar site, e aí a regra vale.
  local surfaces=("${REPO_ROOT}/site")
  if [ "${IS_LEAF}" -ne 1 ]; then
    surfaces+=("${REPO_ROOT}/docs/onion/graph" "${REPO_ROOT}/docs/onion/federation-console.html")
  fi
  out="$(bash "${helper}" --format tsv "${surfaces[@]}" 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    violation "${sev}" "${REPO_ROOT}/${path}" "[projeção/${tag}] ${msg}"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 33 — Segurança de projeção no HISTÓRICO DE FEDERAÇÃO (mailbox-aware) [HARD]
# previne: nome privado vazando no histórico de federação (mailbox)
#   Irmã da REGRA 30, threat model DIFERENTE. A 30 guarda superfície PÚBLICA
#   (chapada: nenhum nome comercial). Esta guarda a coordenação CROSS-TENANT:
#   nome comercial de um membro no mailbox de OUTRO, ou em artefato compartilhado
#   (CHANGELOG/README lido por todos). Nome do próprio membro no próprio mailbox
#   é PERMITIDO — auditar chapado geraria 20 falso-positivos e a guarda morreria.
#   Exclui members.yaml (fonte) e _processed/ (entregue; a casa não reescreve o
#   passado — se re-projetado publicamente, a REGRA 30 pega no ponto de projeção).
#   Origem: a própria REGRA 30, ao varrer o outbox, achou o nome comercial de um adotante numa mensagem
#   entregue a um adotante multi-linhagem (cross-tenant real) — 2026-07-21.
# ===========================================================================
check_federation_projection() {
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  local fed="${REPO_ROOT}/docs/evolution/federation"
  [ -f "${helper}" ] || return 0
  [ -d "${fed}" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${fed}"/*|*/members.yaml) : ;; *) return 0 ;; esac
  fi
  local out sev tag path msg
  out="$(bash "${helper}" --federation --format tsv "${fed}" 2>/dev/null || true)"
  [ -n "${out}" ] || return 0
  while IFS=$'\t' read -r sev tag path msg; do
    [ -n "${sev}" ] || continue
    violation "${sev}" "${REPO_ROOT}/${path}" "[federação/${tag}] ${msg}"
  done <<< "${out}"
}

# ===========================================================================
# REGRA 34 — Migalhas: superfícies DERIVADAS da fonte, sem drift [HARD]
# previne: migalha (superfície derivada) driftando da fonte
#   ADR onion-adr-blog-publication-generator-2026-07 (D2). As 3 superfícies
#   (index.html/provas/feed.xml) são PROJEÇÃO de site/historia/migalhas/posts/*.md
#   pelo migalhas-generate.sh. Editar a região gerada à mão (entre os marcadores
#   ONION:GEN) = fonte paralela = o drift que 12 de 41 posts já sofreram (feed≠provas,
#   medido na migração 2026-07-22). Regenerou? verde. Editou à mão? HARD. É o litmus
#   de source-vs-derivation.md ("edito em UM") virado ESTRUTURAL. Skip gracioso sem
#   python3 (exit 3 do gerador). Chrome (fora dos marcadores) é livre.
# ===========================================================================
check_migalhas_sync() {
  local gen="${SCRIPT_DIR}/migalhas-generate.sh"
  local mig="${REPO_ROOT}/site/historia/migalhas"
  [ -f "${gen}" ] || return 0
  [ -d "${mig}/posts" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${mig}"/*|"${gen}") : ;; *) return 0 ;; esac
  fi
  local rc=0
  bash "${gen}" --check >/dev/null 2>&1 || rc=$?
  case "${rc}" in
    0) : ;;                                  # em sincronia
    3) : ;;                                  # python3 ausente — skip gracioso
    *) violation "HARD" "site/historia/migalhas/" \
         "[migalhas/DRIFT] superfícies divergem da fonte posts/*.md — regenere: bash .claude/validation/migalhas-generate.sh (NÃO edite a região entre os marcadores ONION:GEN à mão)" ;;
  esac
}

# ===========================================================================
# REGRA 35 — Site público não linka deep-link do repo PRIVADO (404 garantido) [HARD]
# previne: site público linkando deep-link de repo privado — 404 garantido
#   O repo onion-evolve é PRIVADO. Um link github.com/…/onion-evolve/(pull|commit|
#   blob|tree)/… em site/ dá 404 para todo visitante — a "prova viva" que não prova.
#   Origem: incidente recorrente — 5 commits de correção de link-404 (jul) + 7 links
#   vivos na home achados pelo MAESTRO usando o site (2026-07-22, declarado≠verificado
#   público). A prova público-segura é a página /historia/migalhas/provas/ (metadado
#   objetivo), nunca o PR cru. Turna a pega manual em trava permanente.
#   Nota: a HOME do próprio repo (github.com/marciocar/onion-evolve SEM /pull|commit|…)
#   é permitida — só os DEEP-LINKS que 404 são barrados.
# ===========================================================================
check_site_no_private_deeplinks() {
  local site="${REPO_ROOT}/site"
  [ -d "${site}" ] || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${site}"/*) : ;; *) return 0 ;; esac
  fi
  local f hits
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    hits="$(grep -oE 'github\.com/[^"/ ]+/onion-evolve/(pull|commit|blob|tree)/[^"() ]+' "${f}" 2>/dev/null | sort -u || true)"
    [ -n "${hits}" ] || continue
    while IFS= read -r h; do
      [ -n "${h}" ] || continue
      violation "HARD" "${f#${REPO_ROOT}/}" "[site/404-privado] deep-link p/ repo PRIVADO dá 404 no público: ${h} — aponte para /historia/migalhas/provas/ (prova público-segura)"
    done <<< "${hits}"
  done < <(find "${site}" -type f \( -name '*.html' -o -name '*.xml' -o -name '*.md' \) 2>/dev/null | sort)
}

# ===========================================================================
# REGRA 36 — Superfície VENDORIZADA sem nome comercial de cliente [HARD]
# previne: nome comercial de cliente vazando em superfície vendorizada
#   O que /meta:adopt copia (.claude/{agents,commands,skills,utils,validation,
#   hooks} + docs/{meta-specs,knowledge-base,sdaal}) VIAJA para todo adotante.
#   Um nome comercial de um cliente ali chega na máquina de OUTRO cliente que
#   não o conhece — cross-tenant por adoção. Origem: o onboarding de um adotante-empresa
#   (2026-07-22) exigiu uma "cópia limpa"; o scrub permanente + esta guarda
#   fecham o gate de uma vez, em vez de um scrub que alguém tem que lembrar.
#   Termos DERIVADOS do members.yaml (nunca hardcoded — nome no script é o
#   próprio vazamento), MENOS os marcadores (CONFIDENCIAL/PRIVADO são vocabulário
#   das guardas, legitimamente vendorizado). Fixtures isentas.
# ===========================================================================
check_vendored_surface_clean() {
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  [ -f "${helper}" ] || return 0

  # ADOTANTE FOLHA (role: adopted) NÃO é sujeito desta regra — correção de campo, não conveniência.
  # A regra existe porque a superfície `.claude/` do CORE (e de um HUB) VIAJA para outros repos:
  # nome de cliente ali é vazamento cross-tenant. Um adotante `role: adopted` é FOLHA — nada sai
  # dele — e sua `.claude/skills/<marca>-design/` é artefato PRÓPRIO, não vendor.
  # O defeito era CIRCULAR: no adotante o `members.yaml` é o VENDORIZADO do core, então a regra
  # derivava dali o nome do próprio dono e o acusava de vazar consigo mesmo.
  # MEDIDO 2026-08-06, atualizando um adotante do pin d9c447f para 0c3ac9c: 9 HARD, TODOS sobre
  # artefatos dele (a skill de design da marca dele; o nome dele na KB dele). Ele estava 0 HARD
  # antes do update, e os 9 travariam TODO commit seu — regressão entregue pelo próprio update.
  # `hub` NÃO é isento: um hub vendoriza para os projetos dele, e lá a regra continua valendo.
  # [[vendor-scrub-blind-spot]] · irmão do GAP3 (approx-count adopter-aware, dogfood de campo 2026-07-24).
  # (o crédito nominal do adotante fica no diário privado — esta guarda cobra isso, inclusive de mim)
  [ "${IS_LEAF}" -eq 1 ] && return 0
  local roots=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation .claude/hooks \
               docs/meta-specs docs/knowledge-base docs/sdaal)
  local targets=() r
  if [ -n "${ONLY_PATH}" ]; then
    local under=0
    for r in "${roots[@]}"; do case "${ONLY_PATH}" in "${REPO_ROOT}/${r}"/*) under=1 ;; esac; done
    [ "${under}" = "1" ] || return 0
    targets=("${ONLY_PATH}")
  else
    for r in "${roots[@]}"; do [ -e "${REPO_ROOT}/${r}" ] && targets+=("${REPO_ROOT}/${r}"); done
  fi
  [ ${#targets[@]} -gt 0 ] || return 0
  local terms term f
  # (1) nomes COMERCIAIS marcados (derivados, menos os marcadores que são vocabulário das guardas)
  terms="$(bash "${helper}" --emit-terms 2>/dev/null | grep -vE '^(CONFIDENCIAL|PRIVADO)$' || true)"
  # (2) IDS de ADOTANTE — o id também identifica o cliente (um id pode ser nome de pessoa, ou mapear direto na marca).
  #     Derivados do members.yaml, EXCLUINDO os nomes do PRÓPRIO framework (onion-*) e do maestro (marcio*).
  #     Decisão do maestro 2026-07-22: a superfície portável não nomeia parceiros; o crédito nominal fica no
  #     diário privado (que não vendoriza).
  local members="${REPO_ROOT}/docs/evolution/federation/members.yaml"
  local ids=""
  # Exclui: nomes do próprio framework (onion-*), do maestro (marcio*), e da convenção de
  # FIXTURE (selftest-*) — senão a guarda deriva os membros-de-teste do members.yaml de um
  # sandbox e se acusa nas próprias fixtures (achado ao rodar: quebrou os testes do outbox-channel).
  [ -r "${members}" ] && ids="$(awk '/^[[:space:]]*-[[:space:]]*id:[[:space:]]/{v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]*#.*$/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); if (v !~ /^onion-/ && v !~ /^marcio/ && v !~ /^selftest-/ && length(v)>=4) print v}' "${members}" 2>/dev/null || true)"
  # '|| true': num adotante LIMPO (sem members.yaml nem nome comercial) terms+ids são vazios;
  # grep -v não casa nada → exit 1 → sob 'set -euo pipefail' abortaria o LINT INTEIRO. O core
  # nunca vê isso (sempre tem termos), mas todo adotante greenfield veria — achado ao rodar o
  # lint DENTRO da cópia de um adotante (a lição de campo: o core é o pior oráculo do que viaja).
  terms="$(printf '%s\n%s\n' "${terms}" "${ids}" | grep -v '^[[:space:]]*$' | sort -u || true)"
  [ -n "${terms}" ] || return 0
  while IFS= read -r term; do
    [ -n "${term}" ] || continue
    while IFS= read -r f; do
      [ -n "${f}" ] || continue
      # Fixtures NÃO são exceção: um nome real de cliente num fixture VENDORIZA p/ todo adotante
      # igual a qualquer outro arquivo (achado 2026-07-22: um id de adotante num comentário de
      # crédito de fixture escapava a guarda e viajava). Os termos derivam de nomes REAIS — nenhum
      # fixture legítimo precisa deles (os de teste usam nomes inventados: acme-adopter, selftest-*).
      violation "HARD" "${f#${REPO_ROOT}/}" "[vendor-scrub] identificador de adotante '${term}' na superfície vendorizada — viaja p/ todo adotante (cross-tenant por adoção); generalize (o crédito nominal fica no diário privado)"
    done < <(grep -rilF -- "${term}" "${targets[@]}" 2>/dev/null | sort -u)
  done <<< "${terms}"
}

# ===========================================================================
# REGRA 23 — Frontmatter: model: em comandos e category: em agentes [HARD]
# previne: comando sem model: ou agente sem category:
#   Origem: Q_LINT_FRONTMATTER do KG (achados D8-20/D8-21 da auditoria
#   2026-07-04 — o gap deixou 7 artefatos divergirem em silêncio; a regra
#   impede o 8º). Escopo DELIBERADAMENTE determinístico: granularidade de
#   allowed-tools ficou DE FORA — é julgamento (o Bash(bash *) do adopt provou
#   que escopo largo às vezes é uso real; regra heurística geraria FP).
#   Mesmo molde/exclusões da R1 (agentes) e R2 (comandos: sem common/, sem README).
# ===========================================================================
check_frontmatter_model_category() {
  while IFS= read -r -d '' cmd; do
    if ! grep -q "^model:" "${cmd}"; then
      violation "HARD" "${cmd}" "frontmatter de comando sem model: — todo comando invocável declara o tier (achado D8-20, auditoria 2026-07-04) — adicione 'model: sonnet|opus|haiku|fable' ao frontmatter"
    fi
  done < <(
    _find "${CLAUDE_DIR}/commands" -name "*.md" \
      ! -path "*/common/*"   \
      ! -name "README.md"    \
      -print0 2>/dev/null
  )
  while IFS= read -r -d '' agent; do
    if ! grep -q "^category:" "${agent}"; then
      violation "HARD" "${agent}" "frontmatter de agente sem category: — exigido pelo inventário/roteamento (achado D8-21, auditoria 2026-07-04) — adicione 'category: <categoria>' ao frontmatter (ex.: o nome do subdiretório em .claude/agents/)"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 27 — Dependência de script de comando empacotado [HARD]
# previne: comando empacotado dependendo de script ausente no bundle
#   Todo script .claude/validation/*.sh que um comando EMPACOTADO (num manifesto de
#   vertical/work-tools) declara em `allowed-tools:` deve estar no VALIDATION[] do MESMO
#   manifesto — OU ser um script de HARNESS sempre-presente num repo adotado (allowlist).
#   Senão o plugin/bundle herda um DEAD-REF (o comando invoca um script ausente). Nasceu do
#   sinal de campo kg-radar 2026-07-19: engineer:work.md cabeava kg-radar.sh com VALIDATION=()
#   vazio → todo standalone montado herdava referência morta. Roda no source (o adotante não monta).
# ===========================================================================
check_bundled_command_script_deps() {
  [ "${IS_DERIVED}" -eq 1 ] && return 0
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  [ -d "${vdir}" ] || return 0
  # Harness sempre-presente num repo adotado (não precisa estar no VALIDATION[] do bundle).
  local harness=" onion-version.sh inventory.sh resolve-integration-branch.sh pin-integrity-check.sh lint-artifacts.sh lint-selftest.sh session-beacon.sh "
  local man
  for man in "${vdir}"/*.manifest.sh; do
    [ -f "${man}" ] || continue
    local dump pname="" valset=" ${harness}"; local -a cmds=()
    dump="$( COMMANDS=(); VALIDATION=(); PLUGIN_NAME=""; . "${man}" 2>/dev/null
             printf 'N\t%s\n' "${PLUGIN_NAME}"
             for c in "${COMMANDS[@]}"; do printf 'C\t%s\n' "${c}"; done
             for v in "${VALIDATION[@]}"; do printf 'V\t%s\n' "$(basename "${v}")"; done )"
    local k val
    while IFS=$'\t' read -r k val; do
      case "${k}" in N) pname="${val}";; C) cmds+=("${val}");; V) valset+="${val} ";; esac
    done <<< "${dump}"
    local c files f s
    for c in "${cmds[@]}"; do
      if [ -d "${REPO_ROOT}/${c}" ]; then files="$(find "${REPO_ROOT}/${c}" -maxdepth 1 -name '*.md' 2>/dev/null)"; else files="${REPO_ROOT}/${c}"; fi
      for f in ${files}; do
        [ -f "${f}" ] || continue
        for s in $(grep -m1 '^allowed-tools:' "${f}" 2>/dev/null | grep -oE '\.claude/validation/[a-z0-9-]+\.sh' | sed 's#.*/##' | sort -u); do
          case "${valset}" in
            *" ${s} "*) : ;;
            *) violation "HARD" "utils/marketplace/verticals/$(basename "${man}")" "comando '$(basename "${f}")' declara .claude/validation/${s} em allowed-tools, mas o manifesto '${pname}' não o inclui em VALIDATION[] (nem é harness) — dead-ref no bundle" ;;
          esac
        done
      done
    done
  done
}

# ===========================================================================
# REGRA 39 — Registro de REGRAS derivado e em paridade com as guardas [HARD]
# previne: lint-rules.md driftando das guardas (nº duplicado ou regra órfã)
#           GERADO por rules-registry.sh (parseia os docstrings '# REGRA N — …' e o corpo de cada
#           guarda p/ severidade). É o "documento de conhecimento da rede": vendorizado em
#           .claude/validation/lint-rules.md, viaja no /meta:adopt. O gerador FALHA se houver
#           número duplicado ou regra sem categoria — a catraca contra colisão e contra regra órfã.
# ===========================================================================
check_rules_registry_sync() {
  local gen="${SCRIPT_DIR}/rules-registry.sh"
  local doc="${SCRIPT_DIR}/lint-rules.md"
  [ -f "${gen}" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  # Honra --only: só roda se o alvo for o gerador, o doc, ou o próprio lint (a fonte dos docstrings).
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${gen}"|"${doc}"|"${SCRIPT_DIR}/lint-artifacts.sh") : ;; *) return 0 ;; esac
  fi
  local tmp; tmp="$(mktemp)"
  if ! bash "${gen}" > "${tmp}" 2>/dev/null; then
    violation "HARD" ".claude/validation/lint-rules.md" "gerador do registro FALHOU (número de REGRA duplicado ou regra sem categoria) — rode: bash .claude/validation/rules-registry.sh"
    rm -f "${tmp}"; return
  fi
  if [ ! -f "${doc}" ]; then
    violation "HARD" ".claude/validation/lint-rules.md" "registro ausente — rode: bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md"
    rm -f "${tmp}"; return
  fi
  if ! diff -q "${doc}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" ".claude/validation/lint-rules.md" "registro desatualizado vs docstrings — regenere: bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md"
  fi
  rm -f "${tmp}"
}

# ===========================================================================
# REGRA 40 — Adotante: .onion-version DEVE estar trackeado no git [HARD]
# previne: adotante com .onion-version não-trackeado — 156 falso-HARD
#           Achado de campo 2026-07-22: o stamp é GITIGNORED na fonte (lá a identidade é lida ao vivo,
#           backstop local). Numa cópia gerada à mão (git add -A respeita o ignore) o stamp NÃO era
#           commitado → o clone perdia o marcador `role: adopted` → o role-guard de _scan_relative_links
#           e os guards de plugins tratavam o clone como role: source → links/plugins core-only viravam
#           156 falso-HARD. O adopt CANÔNICO force-adda; esta guarda garante que qualquer adotante
#           (à mão ou não) commite o stamp. Dispara p/ role: adopted OU hub (ambos são stamps de
#           adoção), em repo git. Fecha o buraco no mecanismo (não one-off): [[fix-must-become-mechanism]].
# ===========================================================================
# REGRA 46 — Canal da federação: diretório de outbox tem membro correspondente [SOFT]
# previne: anúncio órfão — diretório de outbox cujo nome não é id de membro nunca é servido pelo pull, e some em silêncio
# ------------------------------------------------------------------------------------
# Enquanto a entrega downstream era `cp` guiado por --target, o NOME do diretório de
# outbox nunca importou: o carteiro sabia o caminho. Com o pull (ADR transport-pull), o
# nome VIRA A CHAVE — o endpoint serve `outbox/<member-id>/_processed/` e resolve o
# membro pela organização do token. Diretório que não corresponde a membro é anúncio que
# NUNCA será servido, e some em silêncio.
#
# Achado de campo 2026-07-28: uma correção de id de membro (tirar o nome de uma empresa
# da superfície pública) renomeou o membro e deixou o diretório de outbox antigo para
# trás. 25 anúncios ficaram órfãos por 19 dias, e só apareceram quando o pull tornou a
# convenção executável. Esta guarda os teria pego no mesmo dia da renomeação.
check_federation_outbox_membership() {
  local base="docs/evolution/federation/outbox" members="docs/evolution/federation/members.yaml"
  [ -d "${REPO_ROOT}/${base}" ] && [ -f "${REPO_ROOT}/${members}" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0   # sem python3, não fingir que passou
  local orfaos
  orfaos="$(cd "${REPO_ROOT}" && python3 - "${members}" "${base}" <<'PYEOF'
import sys, os, re
members, base = sys.argv[1], sys.argv[2]
# leitura tolerante: `  - id: <slug>` no topo de cada membro (sem exigir pyyaml)
ids = set(re.findall(r'^\s*-\s+id:\s*([A-Za-z0-9._-]+)\s*$', open(members, encoding='utf-8').read(), re.M))
for d in sorted(os.listdir(base)):
    # `_`-prefixado e convenção de área reservada (como `_processed`, `_archive`):
    # não é canal de membro e portanto não pede membro correspondente.
    if d.startswith('_') or not os.path.isdir(os.path.join(base, d)) or d in ids:
        continue
    n = 0
    for root, _, files in os.walk(os.path.join(base, d)):
        n += sum(1 for f in files if f.endswith('.md') and f.lower() != 'readme.md')
    print(f"{d}\t{n}")
PYEOF
)"
  [ -n "${orfaos}" ] || return 0
  local d n
  while IFS=$'\t' read -r d n; do
    [ -n "${d}" ] || continue
    # SOFT, nunca HARD — e a escolha NAO e minha: o selftest da REGRA 28 (caso 7) defende
    # essa propriedade desde 2026-07-19, porque anuncio orfao PRE-EXISTENTE bloquearia o CI
    # de qualquer adotante que ja tenha um. Eu tinha escrito HARD sem saber, e o selftest
    # reprovou — que e exatamente para isso que ele existe.
    violation "SOFT" "${base}/${d}" "[federação/outbox-órfã] diretório sem membro correspondente em members.yaml — ${n} anúncio(s) que o pull NUNCA servirá (o endpoint resolve por member-id). Renomeie o diretório para o id do membro, ou registre o membro"
  done <<< "${orfaos}"
}

# REGRA 47 — Narração do KG cita ids que existem no grafo [HARD]
# previne: narração que cita nó inexistente no grafo — console embute e DROPA ids mortos silenciosamente
# ------------------------------------------------------------------------------------
# A narração pré-cozida é o único ponto com LLM do console (kg-console.sh a embute opt-in).
# A doutrina KG-SSOT manda "citar ids de nó, nunca re-derivar da prosa"; sem mecanismo isso
# é promessa. Esta guarda a torna determinística: todo <slug>.narration.json COMMITADO tem de
# validar contra seu .kg.yaml irmão (via kg-narrate-validate.sh) — todo id do tour/resumos
# existe no grafo. Senão o console dropa o id morto sem avisar (o no-op silencioso de sempre).
# Pula gracioso sem python3 (o validador degrada a exit 3). [[fix-must-become-mechanism]]
check_kg_narration_valid() {
  local validator="${REPO_ROOT}/.claude/validation/kg-narrate-validate.sh"
  [ -f "${validator}" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0   # sem python3 o validador degrada — não fingir que passou
  local narr rel kg rc out
  while IFS= read -r narr; do
    [ -n "${narr}" ] || continue
    rel="${narr#${REPO_ROOT}/}"
    # ONLY_PATH é ABSOLUTO (normalizado no topo do arquivo); comparar com `rel` NUNCA casava,
    # e a regra dava `continue` em toda narração — no-op SILENCIOSO exatamente no modo `--only`,
    # que é o do pre-commit e o do selftest. Uma fixture de R47 passaria como "good" para sempre.
    # Na rodada completa a guarda funcionava, então o furo era invisível. Achado 2026-08-03.
    # [[fix-must-become-mechanism]] As irmãs (R29 etc.) já comparavam absoluto — este era o ímpar.
    if [ -n "${ONLY_PATH}" ]; then case "${ONLY_PATH}" in "${narr}") : ;; *) continue ;; esac; fi
    kg="${narr%.narration.json}.kg.yaml"
    if [ ! -f "${kg}" ]; then
      violation "HARD" "${rel}" "[kg/narração] narração sem .kg.yaml irmão ($(basename "${kg}")) — narração órfã não projeta grafo nenhum"
      continue
    fi
    rc=0; out="$(bash "${validator}" "${kg}" 2>&1)" || rc=$?
    if [ "${rc}" -eq 1 ]; then
      violation "HARD" "${rel}" "[kg/narração] INVÁLIDA — cita id que o grafo não tem (o console o dropa em silêncio). Detalhe: $(printf '%s' "${out}" | tr '\n' ' ' | sed 's/  */ /g')"
    fi
  done < <(find "${REPO_ROOT}" -type f -name '*.narration.json' -path '*/graph/*' 2>/dev/null)
}

check_onion_version_tracked() {
  local stamp="${REPO_ROOT}/.claude/.onion-version"
  [ -f "${stamp}" ] || return 0
  grep -qE '^(role:[[:space:]]*(adopted|hub)|decoupled_from:)' "${stamp}" 2>/dev/null || return 0   # adotante, hub OU fonte-desacoplada (todos carregam stamp que o clone precisa trackear)
  git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1 || return 0     # precisa ser repo git
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${stamp}") : ;; *) return 0 ;; esac
  fi
  if ! git -C "${REPO_ROOT}" ls-files --error-unmatch .claude/.onion-version >/dev/null 2>&1; then
    violation "HARD" ".claude/.onion-version" "repo derivado (role: adopted|hub, ou fonte-desacoplada com decoupled_from) com .onion-version NÃO trackeado — commite-o ('git add -f .claude/.onion-version'): senão o clone perde o marcador e TODOS os guards de adotante desligam (links/plugins core-only viram falso-HARD em massa no clone). Achado 2026-07-22."
  fi
}

# ===========================================================================
# REGRA 41 — Topologia da família: SSOT no KG com procedimentos EXISTENTES [HARD]
# previne: SSOT de topologia da família apontando a procedimentos inexistentes
#           A topologia (docs/onion/graph/onion-family-topology-2026-07.kg.yaml) é a fonte que as faces de
#           CONDUÇÃO projetam (wizard/onboarding/scaffold — onion-guided-lifecycle.md). Se o SSOT mentir,
#           os fluxos de ajuda dessincronizam do que os comandos fazem — o medo do maestro. Esta guarda o
#           impede: (a) toda TRANSIÇÃO ativa (TX_*, status: confirmed) traceia um procedimento que EXISTE no filesystem;
#           (b) todo PAPEL ativo (ROLE_*, status: confirmed) existe em roles.yaml. Gated (status: open) é
#           pulado. Molde de check_role_bundle_sync. Pula gracioso sem python+yaml. [[fix-must-become-mechanism]]
# ===========================================================================
check_family_topology_sync() {
  local kg="${REPO_ROOT}/docs/onion/graph/onion-family-topology-2026-07.kg.yaml"
  local roles="${REPO_ROOT}/.claude/utils/marketplace/roles.yaml"
  [ -f "${kg}" ] || return 0
  have_py_yaml || return 0
  if [ -n "${ONLY_PATH}" ]; then
    case "${ONLY_PATH}" in "${kg}"|"${roles}") : ;; *) return 0 ;; esac
  fi
  local out
  out="$(python3 - "${kg}" "${roles}" "${REPO_ROOT}" <<'PY'
import sys, yaml, os, re
kg, roles_path, root = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = yaml.safe_load(open(kg, encoding='utf-8')) or {}
except Exception as e:
    print("ERRO\tKG ilegível: %s" % e); sys.exit(0)
# papéis reais de roles.yaml (chaves sob 'roles:')
real_roles = set()
try:
    r = yaml.safe_load(open(roles_path, encoding='utf-8')) or {}
    real_roles = set((r.get('roles') or {}).keys())
except Exception:
    pass
for n in (d.get('nodes') or []):
    nid = n.get('id', ''); status = n.get('status', '')
    if status != 'confirmed':
        continue  # gated (open) é pulado — transição/papel futuro, sem procedimento ainda
    if nid.startswith('TX_'):
        tr = n.get('trace', '')
        if not tr:
            print("SEM-TRACE\t%s: transição ativa sem trace: (aponte ao procedimento que a implementa)" % nid)
        elif not os.path.exists(os.path.join(root, tr)):
            print("TRACE-MORTO\t%s: trace '%s' não resolve — procedimento ausente (o SSOT mentiria p/ o wizard)" % (nid, tr))
    elif nid.startswith('ROLE_'):
        role = nid[len('ROLE_'):]
        # decoupled_source é VARIANTE de source (stamp: role: source + decoupled_from), não um bundle-role
        # próprio — sua superfície é a do source. Não exigir chave em roles.yaml.
        if role == 'decoupled_source':
            continue
        if real_roles and role not in real_roles:
            print("PAPEL-ORFAO\t%s: papel '%s' não existe em roles.yaml (SSOT da topologia divergente do bundle)" % (nid, role))
PY
)" || true
  if [ -n "${out}" ]; then
    while IFS=$'\t' read -r tag msg; do
      [ -n "${msg}" ] || continue
      violation "HARD" "docs/onion/graph/onion-family-topology-2026-07.kg.yaml" "[topologia/${tag}] ${msg} — edite o node no .kg.yaml: preencha/corrija 'trace:' apontando a um procedimento existente, ou alinhe o papel a uma chave real de roles.yaml"
    done <<< "${out}"
  fi
}

# ===========================================================================
# REGRA 48 — Referência de caminho `.claude/…` em backtick (prosa) que não resolve [HARD]
# previne: referência .claude/ em backtick na prosa apontando p/ arquivo inexistente (ponteiro morto silencioso)
#   Origem: dogfood de campo 2026-07-30 — `.claude/utils/clickup-formatting.md` era citado em
#   CLAUDE.md, integrations.md e no agente @onion, mas o arquivo NÃO existe (o fragmento real é
#   common:prompts:clickup-patterns). A REGRA 22 só pega LINKS markdown [x](path) em docs/evolution|
#   knowledge-base; referência de caminho em BACKTICK na prosa da constituição/meta-specs/agentes/
#   comandos ficava sem guarda determinística — só revisor semântico a pegaria. Esta a fecha.
#   Escopo do ALVO: SÓ `.claude/…ext` (presente em todo repo com o framework → sem o falso-HARD de
#   adotante que a REGRA 22 precisa contornar p/ docs core-only). Filtros contra falso-positivo
#   (dogfood do desenho: 143 refs reais no core → 0 broken, 0 FP):
#   - IGNORA code fences ``` (o path pode ser do arquivo GERADO, não deste — lição da REGRA 22);
#   - IGNORA alvo NÃO-kebab (`MyAgent.md`/`X.md`/`misc/MyCommand.md` são EXEMPLOS; arquivo .claude/
#     real é kebab-case por REGRA 6) — basenames all-caps convencionais (SKILL/README/…) exentos;
#   - IGNORA placeholders/globs (`<>[]{}*$ ` e `...`) e paths sem extensão de arquivo (ref de diretório);
#   - ALLOWLIST de alvos OPCIONAIS documentados (resolvidos-se-existirem): `.claude/onion-context.yaml`
#     (override de contexto do consumidor, resolvido pelos resolvers das skills *-context).
#   Role-guard (espelha REGRA 22): num door role-scoped a meta-factory + verticais não-base são selados
#   (ausentes-por-desenho) — pular SÓ o alvo-ausente nesses prefixos quando adopted/hub. Sem jq. [[fix-must-become-mechanism]]
# ===========================================================================
# Lista de arquivos da superfície de framework (honra --only via _find; CLAUDE.md tratado à parte
# por viver na raiz, fora das raízes de _find). Poda de worktrees vem de graça no _find.
_backtick_ref_files() {
  if [ -z "${ONLY_PATH}" ] || [ "${ONLY_PATH}" = "${REPO_ROOT}/CLAUDE.md" ]; then
    [ -f "${REPO_ROOT}/CLAUDE.md" ] && printf '%s\0' "${REPO_ROOT}/CLAUDE.md"
  fi
  # Isenta fixtures (convenção do topo deste arquivo, ~L67): a regra varre `.claude/**`,
  # e é ali que as fixtures VIVEM — uma fixture `bad` com ponteiro morto DELIBERADO
  # dispararia a guarda real e o repo reprovaria por ter teste.
  # Furo PRÉ-EXISTENTE, latente desde que a R48 nasceu (2026-07-30) e invisível porque
  # ela não tinha fixture nenhuma; apareceu no minuto em que a primeira foi criada.
  _find "${CLAUDE_DIR}" -name '*.md' ! -path '*/validation/fixtures/*' -print0 2>/dev/null
  _find "${REPO_ROOT}/docs/meta-specs" -name '*.md' -print0 2>/dev/null
}

check_backtick_path_refs() {
  local adopted=""
  [ "${IS_DERIVED}" -eq 1 ] && adopted=1
  local f lineno tok
  while IFS= read -r -d '' f; do
    [ -f "${f}" ] || continue
    while IFS=$'\t' read -r lineno tok; do
      [ -n "${tok}" ] || continue
      # allowlist: alvos OPCIONAIS documentados (override do consumidor, resolvido-se-existir)
      case "${tok}" in
        .claude/onion-context.yaml) continue ;;
      esac
      [ -e "${REPO_ROOT}/${tok}" ] && continue
      if [ -n "${adopted}" ]; then
        # door role-scoped: meta-factory + verticais não-base selados (ausentes-por-desenho)
        case "${tok}" in
          .claude/commands/meta/*|.claude/commands/design/*|.claude/commands/development/*|.claude/commands/quick/*) continue ;;
          .claude/agents/meta/*|.claude/agents/compliance/*|.claude/agents/research/*) continue ;;
          .claude/validation/lint-selftest.sh|.claude/validation/federation-*|.claude/validation/kg-*|.claude/validation/graph.sh|.claude/validation/constellation-map.sh|.claude/validation/diary-index.sh|.claude/validation/a2a-*|.claude/validation/trust-topology-check.sh|.claude/validation/lint-design-tokens.sh) continue ;;
        esac
      fi
      violation "HARD" "${f}" "referência de caminho em backtick (linha ${lineno}): \`${tok}\` não resolve — ponteiro morto (arquivo movido/renomeado? cite o fragmento/caminho real)"
    done < <(awk '
      /^[[:space:]]*```/ { fence = !fence; next }
      fence { next }
      {
        line = $0
        while (match(line, /`[^`]+`/)) {
          tok = substr(line, RSTART + 1, RLENGTH - 2)
          line = substr(line, RSTART + RLENGTH)
          if (tok !~ /^\.claude\//) continue
          if (tok !~ /\.(md|sh|json|ya?ml|html|txt)$/) continue
          if (tok ~ /[<>\[\]{}*$ ]/) continue
          if (tok ~ /\.\.\./) continue
          # gate kebab-case: arquivo .claude/ real é kebab (REGRA 6). Remove basenames all-caps
          # convencionais; se sobrou maiúscula → EXEMPLO (MyAgent/X), não referência real → pula.
          probe = tok
          gsub(/\/(SKILL|README|CLAUDE|MEMORY|INDEX|CHANGELOG|LICENSE)\.[a-z]+$/, "/", probe)
          if (probe ~ /[A-Z]/) continue
          printf "%d\t%s\n", NR, tok
        }
      }
    ' "${f}")
  done < <(_backtick_ref_files)
}

# ===========================================================================
# EXECUÇÃO DAS CHECAGENS
# ===========================================================================
echo "=== Onion Lint — iniciando validação em ${CLAUDE_DIR} ==="
echo ""

if [ "${FIX_MODE}" -eq 1 ]; then
  run_inventory_fixes
  if [ "${FIXED_FILES}" -gt 0 ]; then
    echo "=== --fix: ${FIXED_FILES} arquivo(s) realinhado(s) à SSOT ==="
    for entry in "${FIX_LOG[@]}"; do echo "  ${entry}"; done
    echo ""
  else
    echo "=== --fix: nenhuma frase-de-total divergente (já em sincronia) ==="
    echo ""
  fi
fi

# PRIMEIRA de todas por desenho: se a varredura está cega, o veredito de qualquer
# regra abaixo é vacuidade — a mesma razão pela qual o /meta:kg-freshness checa
# legibilidade antes de emitir veredito sobre um grafo.
check_scan_sanity

check_agent_frontmatter
check_agent_tool_names
check_template_dialect
check_metaspec_dialect
check_command_description
check_no_gpt4_model
check_line_limits
check_kebab_case_filenames
check_no_worker_orchestrator_agent
check_branch_agent_distinction
check_rules_pathscoped
check_inventory_sync
check_claude_md_counts
check_site_inventory_sync
check_plugins_sync
check_capability_conformance
check_role_bundle_sync
check_bundled_command_script_deps
check_graph_sync
check_federation_map_sync
check_federation_console_sync
check_agent_card_sync
check_outbox_channel_exists
check_no_direct_provider_calls
check_abstraction_methods_exist
check_context_freshness_stamp
check_inventory_total_drift
check_frontmatter_scalar_colon
check_no_claude_docs
check_evolution_links
check_knowledge_base_links
check_research_kg
check_kg_provenance_coverage
check_kg_verification_coverage
check_kg_radar_integrity
check_kg_trace_resolve
check_review_artifact
check_doctrine_freshness
check_kg_born_marker
check_ladder_integrity
check_kb_vendored_links
check_kg_view_sync
check_site_graph_sync
check_projection_safety
check_federation_projection
check_migalhas_sync
check_site_no_private_deeplinks
check_vendored_surface_clean
check_frontmatter_model_category
check_rules_registry_sync
check_onion_version_tracked
check_family_topology_sync
check_federation_outbox_membership
check_kg_narration_valid
check_backtick_path_refs

# ===========================================================================
# SUMÁRIO FINAL
# ===========================================================================
echo ""
echo "=== Sumário ==="
echo "  Violações HARD : ${HARD_COUNT}"
echo "  Violações SOFT : ${SOFT_COUNT}"
echo "  Total          : ${TOTAL_COUNT}"
echo ""

if [ "${HARD_COUNT}" -eq 0 ]; then
  echo "OK ✓  — nenhuma violação HARD encontrada."
  if [ "${SOFT_COUNT}" -gt 0 ]; then
    echo "       (${SOFT_COUNT} aviso(s) SOFT — revisar, mas não bloqueiam CI)"
  fi
  exit 0
else
  echo "FALHOU — ${HARD_COUNT} violação(ões) HARD devem ser corrigidas antes do merge."
  exit 1
fi
