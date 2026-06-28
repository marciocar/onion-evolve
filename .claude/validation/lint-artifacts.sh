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
  esac
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
      -*|'!') preds=("$@"); break ;;
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
  find "${roots[@]}" "${preds[@]}"
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

# ===========================================================================
# REGRA 1 — Frontmatter de agente: name:, description:, tools: obrigatórios
# ===========================================================================
check_agent_frontmatter() {
  while IFS= read -r -d '' agent; do
    local missing=""

    grep -q "^name:" "${agent}"        || missing="${missing} name:"
    grep -q "^description:" "${agent}" || missing="${missing} description:"
    grep -q "^tools:" "${agent}"       || missing="${missing} tools:"

    if [ -n "${missing}" ]; then
      violation "HARD" "${agent}" "frontmatter de agente incompleto — campos ausentes:${missing}"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 2 — Frontmatter de comando: description: obrigatório
#           (exceto arquivos em common/ e arquivos README.md)
# ===========================================================================
check_command_description() {
  while IFS= read -r -d '' cmd; do
    if ! grep -q "^description:" "${cmd}"; then
      violation "HARD" "${cmd}" "frontmatter de comando sem description:"
    fi
  done < <(
    _find "${CLAUDE_DIR}/commands" -name "*.md" \
      ! -path "*/common/*"   \
      ! -name "README.md"    \
      -print0 2>/dev/null
  )
}

# ===========================================================================
# REGRA 3 — Campo model: não pode conter gpt-4
#           Verifica apenas linhas que começam com 'model:' em .claude/**/*.md
#           NÃO falha por ocorrências dentro de blocos de código
# ===========================================================================
check_no_gpt4_model() {
  while IFS= read -r -d '' file; do
    # Extrai apenas as linhas que iniciam com 'model:' e verifica gpt-4
    if grep -q "^model:.*gpt-4" "${file}"; then
      local lines
      lines=$(grep -n "^model:.*gpt-4" "${file}" | head -3)
      violation "HARD" "${file}" "campo model: contém gpt-4 (linha(s): ${lines})"
    fi
  done < <(_find "${CLAUDE_DIR}" -name "*.md" ! -path "*/validation/fixtures/*" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 4 — Ausência de 'mcp_onion-orchestrator' em .claude/ [HARD]
#           (referência a componente vaporware — nunca foi implementado)
# ===========================================================================
check_no_mcp_onion_orchestrator() {
  local self
  self="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"

  local hits
  # O próprio script contém a string como padrão de busca — excluí-lo da varredura
  hits=$(grep -rl "mcp_onion-orchestrator" "${CLAUDE_DIR}" 2>/dev/null \
    | grep -v "^${self}$" \
    | grep -v "/validation/fixtures/" || true)

  if [ -n "${hits}" ]; then
    while IFS= read -r file; do
      violation "HARD" "${file}" "referência a 'mcp_onion-orchestrator' (componente vaporware)"
    done <<< "${hits}"
  fi
}

# ===========================================================================
# REGRA 5 — Limites de linhas
#           Agente  > 1500 linhas → HARD
#           Comando > 800  linhas → HARD  (common/templates e common/prompts isentos)
# ===========================================================================
check_line_limits() {
  # 5a. Agentes
  while IFS= read -r -d '' agent; do
    local lines
    lines=$(wc -l < "${agent}")
    if [ "${lines}" -gt 1500 ]; then
      violation "HARD" "${agent}" "agente com ${lines} linhas (limite: 1500)"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)

  # 5b. Comandos (exclui common/templates e common/prompts)
  while IFS= read -r -d '' cmd; do
    local lines
    lines=$(wc -l < "${cmd}")
    if [ "${lines}" -gt 800 ]; then
      violation "HARD" "${cmd}" "comando com ${lines} linhas (limite: 800)"
    fi
  done < <(
    _find "${CLAUDE_DIR}/commands" -name "*.md" \
      ! -path "*/common/templates/*" \
      ! -path "*/common/prompts/*"   \
      -print0 2>/dev/null
  )
}

# ===========================================================================
# REGRA 6 — Filenames em .claude/ devem ser kebab-case [SOFT]
#           Exceções permitidas (convenções estabelecidas):
#             • README.md  — convenção universal de documentação
#             • SKILL.md   — convenção do framework de skills
#             • ESPERANTO.md — arquivo canônico do sistema
#             • *_template.md em common/templates — legado aceito pelo framework
# ===========================================================================
check_kebab_case_filenames() {
  while IFS= read -r -d '' file; do
    local base
    base=$(basename "${file}")

    # Exceções explícitas (nomes em maiúsculas ou com underscore aceitos)
    case "${base}" in
      README.md|SKILL.md|ESPERANTO.md) continue ;;
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
      violation "SOFT" "${file}" "filename não segue kebab-case (maiúsculas, espaço ou underscore em '${base}')"
    fi
  done < <(_find "${CLAUDE_DIR}" -name "*.md" ! -path "*/validation/fixtures/*" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 7 — Nenhum agente pode ter name: contendo 'worker-orchestrator' [HARD]
#           (violação arquitetural — §4.2 de architecture.md)
# ===========================================================================
check_no_worker_orchestrator_agent() {
  while IFS= read -r -d '' agent; do
    if grep -q "^name:.*worker-orchestrator" "${agent}"; then
      violation "HARD" "${agent}" "agente com name: 'worker-orchestrator' viola §4.2 da arquitetura"
    fi
  done < <(_find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 8 — Inventário canônico sincronizado com o filesystem [HARD]
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
  bash "${inv_script}" --markdown > "${tmp}" 2>/dev/null || true

  if ! diff -q "${inv_file}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "${inv_file}" "inventário desatualizado vs filesystem — regenere com '/meta:inventory' (bash .claude/validation/inventory.sh --markdown > docs/onion/inventory.md)"
  fi
  rm -f "${tmp}"
}

# ===========================================================================
# REGRA 19 — Plugins de vertical (plugins/*) sincronizados com as fontes [HARD]
#           Cada plugins/<name> é GERADO por assemble-plugin.sh a partir de
#           verticals/<name>.manifest.sh. Regenera p/ temp e compara: drift =
#           alguém editou o plugin à mão OU mudou a fonte sem regenerar.
#           IGNORA ref/commit_date do provenance.json (voláteis por commit);
#           compara o resto + o tree_sha (sinal de conteúdo, worktree-based).
# ===========================================================================
check_plugins_sync() {
  local asm="${SCRIPT_DIR}/../utils/marketplace/assemble-plugin.sh"
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  [ -f "${asm}" ] || return            # sem assembler → nada a checar (repo sem a feature)
  [ -d "${vdir}" ] || return
  command -v jq >/dev/null 2>&1 || return   # sem jq → pula gracioso (mesma graça dos outros)

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
#           Cada verticals/<name>.manifest.sh declara CONFORMANCE (bronze|silver|
#           gold) + PROVIDES/REQUIRES/LOADS. Valida o tier reivindicado:
#             bronze = provides + description + version presentes
#             silver = bronze + cada REQUIRES (type:value) resolve no filesystem
#             gold   = silver + LOADS presente
#           Reivindicar acima do cumprido = HARD (auto-descrição honesta).
# ===========================================================================
check_capability_conformance() {
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  [ -d "${vdir}" ] || return
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
# REGRA 21 — Grafo (docs/onion/graph.md) sincronizado com a spec-as-code [HARD]
#           graph.md é GERADO por graph.sh (actors.yaml + capability + frontmatter).
#           Regenera p/ temp e compara: drift = editou à mão OU mudou a fonte sem
#           regenerar. Espelha check_inventory_sync. Pula gracioso sem jq.
# ===========================================================================
check_graph_sync() {
  local gen="${SCRIPT_DIR}/graph.sh"
  local gfile="${REPO_ROOT}/docs/onion/graph.md"
  [ -f "${gen}" ] || return
  command -v jq >/dev/null 2>&1 || return   # graph.sh usa jq p/ capability → pula gracioso sem jq
  if [ ! -f "${gfile}" ]; then
    violation "HARD" "docs/onion/graph.md" "grafo ausente — rode 'bash .claude/validation/graph.sh --markdown > docs/onion/graph.md'"
    return
  fi
  local tmp; tmp="$(mktemp)"
  bash "${gen}" --markdown > "${tmp}" 2>/dev/null || true
  if ! diff -q "${gfile}" "${tmp}" >/dev/null 2>&1; then
    violation "HARD" "docs/onion/graph.md" "grafo desatualizado vs spec-as-code — regenere com '/meta:graph' (bash .claude/validation/graph.sh --markdown > docs/onion/graph.md)"
  fi
  rm -f "${tmp}"
}

# ===========================================================================
# REGRA 9 — Contagens no CLAUDE.md em sincronia com a SSOT [HARD]
#           Extrai "N comandos invocáveis", "N agentes", "N skills" do CLAUDE.md
#           e compara com os totais computados por inventory.sh. Impede que a
#           constituição volte a drifar (foi onde o drift 79≠76 vivia).
# ===========================================================================
check_claude_md_counts() {
  local claude_md="${REPO_ROOT}/CLAUDE.md"
  local inv_script="${SCRIPT_DIR}/inventory.sh"
  [ -f "${claude_md}" ] || return
  [ -f "${inv_script}" ] || return

  # Totais canônicos do filesystem
  local env_out cmd_truth agent_truth skill_truth
  env_out="$(bash "${inv_script}" --env 2>/dev/null || true)"
  cmd_truth="$(echo "${env_out}"   | grep '^ONION_COMMANDS_TOTAL=' | cut -d= -f2)"
  agent_truth="$(echo "${env_out}" | grep '^ONION_AGENTS_TOTAL='   | cut -d= -f2)"
  skill_truth="$(echo "${env_out}" | grep '^ONION_SKILLS_TOTAL='   | cut -d= -f2)"

  # Números declarados no CLAUDE.md (primeira ocorrência de cada padrão)
  local cmd_claim agent_claim skill_claim
  cmd_claim="$(grep -oE '[0-9]+ comandos invocáveis' "${claude_md}"      | head -1 | grep -oE '^[0-9]+' || true)"
  agent_claim="$(grep -oE '[0-9]+ agentes' "${claude_md}"               | head -1 | grep -oE '^[0-9]+' || true)"
  skill_claim="$(grep -oE '[0-9]+ skills' "${claude_md}"                | head -1 | grep -oE '^[0-9]+' || true)"

  if [ -n "${cmd_claim}" ] && [ "${cmd_claim}" != "${cmd_truth}" ]; then
    violation "HARD" "${claude_md}" "CLAUDE.md afirma ${cmd_claim} comandos, filesystem tem ${cmd_truth} — alinhe à SSOT (/meta:inventory)"
  fi
  if [ -n "${agent_claim}" ] && [ "${agent_claim}" != "${agent_truth}" ]; then
    violation "HARD" "${claude_md}" "CLAUDE.md afirma ${agent_claim} agentes, filesystem tem ${agent_truth} — alinhe à SSOT (/meta:inventory)"
  fi
  if [ -n "${skill_claim}" ] && [ "${skill_claim}" != "${skill_truth}" ]; then
    violation "HARD" "${claude_md}" "CLAUDE.md afirma ${skill_claim} skills, filesystem tem ${skill_truth} — alinhe à SSOT (/meta:inventory)"
  fi
}

# ===========================================================================
# REGRA 10 — SDAAL: sem chamada direta a provider no consumidor [HARD]
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
      */agents/development/jira-specialist.md)    continue ;;
      */commands/common/prompts/clickup-patterns.md) continue ;;
      */commands/common/templates/*)  continue ;;
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
#            Pega método agnóstico INVENTADO (ex.: taskManager.getTaskList(...)
#            quando o canônico é searchTasks). Ancora em ".<metodo>(" — acessos a
#            propriedade (taskManager.provider, .isConfigured) não têm paren e não
#            são checados. A Regra 10 (anti-MCP) não vê isto: já está agnóstico.
# ===========================================================================
check_abstraction_methods_exist() {
  local tm_iface="${CLAUDE_DIR}/utils/task-manager/interface.md"
  local forge_iface="${CLAUDE_DIR}/utils/forge/interface.md"
  [ -f "${tm_iface}" ] || return
  [ -f "${forge_iface}" ] || return

  # Conjunto canônico de métodos (assinaturas "  metodo(" nas interfaces)
  local methods
  methods=$(grep -hoE '^[[:space:]]+[a-zA-Z]+\(' "${tm_iface}" "${forge_iface}" 2>/dev/null \
    | tr -d ' (' | sort -u)
  [ -n "${methods}" ] || return

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
# REGRA 12 — Nomes de tool de agente válidos no Claude Code
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
# REGRA 13 — Templates canônicos devem ser dialeto-puro
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
# REGRA 14 — Meta-specs (autoridade L0) sem dialeto Cursor em exemplos
#   docs/meta-specs/ define o formato canônico que template e creator-agents
#   espelham. Token Cursor declarado como ITEM DE LISTA YAML (- token) [HARD]
#   e MCP underscore-único [HARD]. Tokens em prosa/blockquote (a lista de
#   PROIBIÇÃO que cita os nomes de propósito) NÃO disparam.
# ===========================================================================
check_metaspec_dialect() {
  local CURSOR='read_file|search_replace|run_terminal_cmd|codebase_search|glob_file_search|list_dir|web_search|todo_write|read_lints|update_memory|edit_file|edit_notebook|MultiEdit'
  local mdir="docs/meta-specs"
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
#   SOFT: heurística sobre linguagem natural — surfaca drift sem bloquear CI por FP.
#   ISENTA: docs/analysis/ (datado), .claude/sessions/ (gitignored), docs/materials/
#   (derivado — deferido), docs/onion/inventory.md (SSOT), e frontmatter
#   status:snapshot / type:adr / type:evolution-backlog.
# ===========================================================================
check_inventory_total_drift() {
  local env_out cmd agent cats agent_cats kb skill n pair num ct line cn an sn kn
  env_out="$(bash "${SCRIPT_DIR}/inventory.sh" --env 2>/dev/null || true)"
  cmd="$(printf '%s\n' "${env_out}" | grep '^ONION_COMMANDS_TOTAL=' | cut -d= -f2)"
  agent="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENTS_TOTAL=' | cut -d= -f2)"
  cats="$(printf '%s\n' "${env_out}" | grep '^ONION_COMMAND_CATEGORIES=' | cut -d= -f2)"
  # Categorias de AGENTE ≠ categorias de COMANDO (podem divergir: ex. 10 cmd-cats × 9 agent-cats).
  # Usar a var própria evita validar/afirmar 'N agentes em <cmd_cats> categorias' (falso).
  agent_cats="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENT_CATEGORIES=' | cut -d= -f2)"
  kb="$(printf '%s\n' "${env_out}" | grep '^ONION_KBS_TOTAL=' | cut -d= -f2)"
  skill="$(printf '%s\n' "${env_out}" | grep '^ONION_SKILLS_TOTAL=' | cut -d= -f2)"
  [ -n "${cmd}" ] || return

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
  done < <(_find "${CLAUDE_DIR}" "${REPO_ROOT}/docs" -name "*.md" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 17 — Frontmatter: valor escalar com ': ' não-aspado [HARD]
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
  [ -n "${cmd}" ] || return

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
  if [ -f "${REPO_ROOT}/CLAUDE.md" ]; then
    _apply_fix_file "${REPO_ROOT}/CLAUDE.md" "${prog}; s/[0-9]+( skills)/${skill}\1/g"
  fi
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

check_agent_frontmatter
check_agent_tool_names
check_template_dialect
check_metaspec_dialect
check_command_description
check_no_gpt4_model
check_no_mcp_onion_orchestrator
check_line_limits
check_kebab_case_filenames
check_no_worker_orchestrator_agent
check_inventory_sync
check_claude_md_counts
check_plugins_sync
check_capability_conformance
check_graph_sync
check_no_direct_provider_calls
check_abstraction_methods_exist
check_context_freshness_stamp
check_inventory_total_drift
check_frontmatter_scalar_colon
check_no_claude_docs

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
