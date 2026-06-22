#!/usr/bin/env bash
# =============================================================================
# inventory.sh — Fonte única de verdade (SSOT) do inventário do Sistema Onion
#
# Propósito : Computar o inventário canônico (comandos, agentes, skills, KBs)
#             DIRETAMENTE do filesystem — nenhum número é digitado à mão.
#             É a base do princípio "documentação deriva, não repete".
#
# Uso       : bash .claude/validation/inventory.sh [--markdown|--json|--env]
#               --markdown (default) : tabela canônica para docs/onion/inventory.md
#               --json               : objeto JSON (para consumo por ferramentas)
#               --env                : pares KEY=VALUE (para o lint sourçar)
#
# Contrato  : "comando invocável" = .md em .claude/commands/ exceto common/ e
#             READMEs. "agente" = .md em .claude/agents/ exceto READMEs.
#             "skill" = diretório em .claude/skills/. "KB" = .md em
#             docs/knowledge-base/ exceto index.md.
#
# Determinístico, sem LLM. Mesma entrada (filesystem) → mesma saída.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CLAUDE_DIR="${REPO_ROOT}/.claude"
KB_DIR="${REPO_ROOT}/docs/knowledge-base"
DOCS_DIR="${REPO_ROOT}/docs"

# ---------------------------------------------------------------------------
# Contagem de comandos invocáveis por categoria (exclui common/ e READMEs)
# ---------------------------------------------------------------------------
count_commands_in() {
  # $1 = diretório de categoria
  find "$1" -maxdepth 10 -name "*.md" \
    ! -iname "readme.md" \
    -print 2>/dev/null | wc -l | tr -d ' '
}

# Total invocável (categorias + root onion/warm-up/catch-up), exclui common/ e READMEs
count_commands_total() {
  find "${CLAUDE_DIR}/commands" -name "*.md" \
    ! -path "*/common/*" \
    ! -iname "readme.md" \
    -print 2>/dev/null | wc -l | tr -d ' '
}

count_agents_in() {
  find "$1" -name "*.md" ! -iname "readme.md" -print 2>/dev/null | wc -l | tr -d ' '
}

count_agents_total() {
  find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname "readme.md" -print 2>/dev/null | wc -l | tr -d ' '
}

count_skills() {
  find "${CLAUDE_DIR}/skills" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | wc -l | tr -d ' '
}

count_kbs() {
  # Mesma guarda de dir das funções de contexto: docs/knowledge-base/ pode não
  # existir num projeto-alvo → sem isto, find sai 1 → pipefail → $(...) aborta (set -e).
  [ -d "${KB_DIR}" ] || { echo 0; return 0; }
  find "${KB_DIR}" -name "*.md" ! -iname "index.md" -print 2>/dev/null | wc -l | tr -d ' '
}

# Arquivos POPULADOS de um contexto de domínio (exclui README.md template e index.md).
# No framework os contextos são templates (só README) → 0; em projeto-alvo conta o conteúdo.
count_context_files() {
  # $1 = nome do contexto (ex.: business-context)
  # Guarda de dir ausente: em projeto-alvo um contexto pode não existir; sem isto,
  # find sai 1 → pipefail propaga → a atribuição $(...) aborta o script (set -e).
  local d="${DOCS_DIR}/$1"
  [ -d "${d}" ] || { echo 0; return 0; }
  find "${d}" -name "*.md" ! -iname "readme.md" ! -iname "index.md" -print 2>/dev/null | wc -l | tr -d ' '
}

# ---------------------------------------------------------------------------
# Coleta de valores
# ---------------------------------------------------------------------------
CMD_TOTAL="$(count_commands_total)"
AGENT_TOTAL="$(count_agents_total)"
SKILLS="$(count_skills)"
KBS="$(count_kbs)"
CTX_BUSINESS="$(count_context_files business-context)"
CTX_TECHNICAL="$(count_context_files technical-context)"
CTX_COMPLIANCE="$(count_context_files compliance-context)"

# Categorias de comando (ordenadas por contagem desc na saída markdown)
declare -A CMD_CATS=()
while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  cat="$(basename "$dir")"
  [ "$cat" = "common" ] && continue
  CMD_CATS["$cat"]="$(count_commands_in "$dir")"
done < <(find "${CLAUDE_DIR}/commands" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
# Root-level (onion, warm-up, catch-up)
CMD_ROOT="$(find "${CLAUDE_DIR}/commands" -maxdepth 1 -name "*.md" ! -iname "readme.md" -print 2>/dev/null | wc -l | tr -d ' ')"

# Categorias de agente
declare -A AGENT_CATS=()
while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  cat="$(basename "$dir")"
  AGENT_CATS["$cat"]="$(count_agents_in "$dir")"
done < <(find "${CLAUDE_DIR}/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

CMD_CAT_COUNT="${#CMD_CATS[@]}"
AGENT_CAT_COUNT="${#AGENT_CATS[@]}"

# ---------------------------------------------------------------------------
# Emissão
# ---------------------------------------------------------------------------
emit_env() {
  echo "ONION_COMMANDS_TOTAL=${CMD_TOTAL}"
  echo "ONION_AGENTS_TOTAL=${AGENT_TOTAL}"
  echo "ONION_SKILLS_TOTAL=${SKILLS}"
  echo "ONION_KBS_TOTAL=${KBS}"
  echo "ONION_CONTEXT_BUSINESS=${CTX_BUSINESS}"
  echo "ONION_CONTEXT_TECHNICAL=${CTX_TECHNICAL}"
  echo "ONION_CONTEXT_COMPLIANCE=${CTX_COMPLIANCE}"
  echo "ONION_COMMAND_CATEGORIES=${CMD_CAT_COUNT}"
  echo "ONION_AGENT_CATEGORIES=${AGENT_CAT_COUNT}"
}

emit_json() {
  printf '{\n'
  printf '  "commands_total": %s,\n' "${CMD_TOTAL}"
  printf '  "agents_total": %s,\n' "${AGENT_TOTAL}"
  printf '  "skills_total": %s,\n' "${SKILLS}"
  printf '  "kbs_total": %s,\n' "${KBS}"
  printf '  "context_business": %s,\n' "${CTX_BUSINESS}"
  printf '  "context_technical": %s,\n' "${CTX_TECHNICAL}"
  printf '  "context_compliance": %s,\n' "${CTX_COMPLIANCE}"
  printf '  "command_categories": %s,\n' "${CMD_CAT_COUNT}"
  printf '  "agent_categories": %s\n' "${AGENT_CAT_COUNT}"
  printf '}\n'
}

emit_markdown() {
  cat <<EOF
<!-- GENERATED BY .claude/validation/inventory.sh — NÃO EDITE À MÃO. Rode \`/meta:inventory\` ou \`bash .claude/validation/inventory.sh --markdown\` para regenerar. -->
# 📒 Inventário Canônico do Sistema Onion

> **Fonte única de verdade (SSOT)** — computado do filesystem, não digitado.
> Qualquer contagem em CLAUDE.md, index.md ou guias **deriva deste arquivo**.

## Totais

| Recurso | Quantidade |
|---------|-----------:|
| Comandos invocáveis | **${CMD_TOTAL}** |
| Agentes | **${AGENT_TOTAL}** |
| Skills | **${SKILLS}** |
| Knowledge Bases | **${KBS}** |

## Comandos por categoria (${CMD_CAT_COUNT} categorias + root)

| Categoria | Comandos |
|-----------|---------:|
EOF
  for cat in $(for c in "${!CMD_CATS[@]}"; do echo "${CMD_CATS[$c]} $c"; done | sort -rn | awk '{print $2}'); do
    echo "| \`${cat}/\` | ${CMD_CATS[$cat]} |"
  done
  echo "| _root_ (\`onion\`, \`warm-up\`, \`catch-up\`) | ${CMD_ROOT} |"
  echo "| **Total** | **${CMD_TOTAL}** |"
  cat <<EOF

## Agentes por categoria (${AGENT_CAT_COUNT} categorias)

| Categoria | Agentes |
|-----------|--------:|
EOF
  for cat in $(for c in "${!AGENT_CATS[@]}"; do echo "${AGENT_CATS[$c]} $c"; done | sort -rn | awk '{print $2}'); do
    echo "| \`${cat}/\` | ${AGENT_CATS[$cat]} |"
  done
  echo "| **Total** | **${AGENT_TOTAL}** |"

  cat <<EOF

## Contextos de domínio (spec-as-code — populados no projeto-alvo)

> Arquivos de conteúdo (exclui README/index). No framework são **templates** (0 = só README).

| Contexto | Arquivos |
|----------|---------:|
| \`business-context/\` | ${CTX_BUSINESS} |
| \`technical-context/\` | ${CTX_TECHNICAL} |
| \`compliance-context/\` | ${CTX_COMPLIANCE} |
EOF
}

case "${1:---markdown}" in
  --env)      emit_env ;;
  --json)     emit_json ;;
  --markdown) emit_markdown ;;
  *) echo "uso: inventory.sh [--markdown|--json|--env]" >&2; exit 2 ;;
esac
