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
#   7. Nenhum agente pode ter name: contendo 'fleet-orchestrator' [HARD]
#   8. Inventário canônico (docs/onion/inventory.md) em sincronia com o
#      filesystem [HARD] — gerado por inventory.sh; drift bloqueia merge
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
  done < <(find "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null)
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
    find "${CLAUDE_DIR}/commands" -name "*.md" \
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
  done < <(find "${CLAUDE_DIR}" -name "*.md" -print0 2>/dev/null)
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
    | grep -v "^${self}$" || true)

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
  done < <(find "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null)

  # 5b. Comandos (exclui common/templates e common/prompts)
  while IFS= read -r -d '' cmd; do
    local lines
    lines=$(wc -l < "${cmd}")
    if [ "${lines}" -gt 800 ]; then
      violation "HARD" "${cmd}" "comando com ${lines} linhas (limite: 800)"
    fi
  done < <(
    find "${CLAUDE_DIR}/commands" -name "*.md" \
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

    # Underscore em common/templates é aceito (legado de templates)
    if [[ "${file}" == */common/templates/* ]] && [[ "${base}" == *_* ]]; then
      continue
    fi

    # Detecta violações: letra maiúscula (exceto toda a extensão) ou espaço ou underscore
    local name_part="${base%.*}"  # remove extensão para checagem

    if echo "${name_part}" | grep -qE '[A-Z]| |_'; then
      violation "SOFT" "${file}" "filename não segue kebab-case (maiúsculas, espaço ou underscore em '${base}')"
    fi
  done < <(find "${CLAUDE_DIR}" -name "*.md" -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 7 — Nenhum agente pode ter name: contendo 'fleet-orchestrator' [HARD]
#           (violação arquitetural — §4.2 de architecture.md)
# ===========================================================================
check_no_fleet_orchestrator_agent() {
  while IFS= read -r -d '' agent; do
    if grep -q "^name:.*fleet-orchestrator" "${agent}"; then
      violation "HARD" "${agent}" "agente com name: 'fleet-orchestrator' viola §4.2 da arquitetura"
    fi
  done < <(find "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null)
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
# EXECUÇÃO DAS CHECAGENS
# ===========================================================================
echo "=== Onion Lint — iniciando validação em ${CLAUDE_DIR} ==="
echo ""

check_agent_frontmatter
check_command_description
check_no_gpt4_model
check_no_mcp_onion_orchestrator
check_line_limits
check_kebab_case_filenames
check_no_fleet_orchestrator_agent
check_inventory_sync
check_claude_md_counts

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
