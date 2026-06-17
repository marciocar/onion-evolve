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
#      underscore-único aqui re-propaga o bug para toda nova frota
#  14. Meta-specs (docs/meta-specs/) sem dialeto Cursor em exemplos de tools:
#      [HARD] — autoridade L0; token Cursor como item de lista YAML ou MCP
#      underscore-único. A lista de PROIBIÇÃO em prosa/blockquote é isenta
#  15. Frescor de contexto de domínio [SOFT] — arquivo POPULADO em docs/*-context/
#      (exclui README/index) deve carregar carimbo 'Última Atualização'/'updated:';
#      habilita a fase Manage (/meta:context-freshness). No framework = no-op (templates)
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
  done < <(find "${CLAUDE_DIR}" -name "*.md" ! -path "*/validation/fixtures/*" -print0 2>/dev/null)
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
  done < <(find "${CLAUDE_DIR}" -name "*.md" ! -path "*/validation/fixtures/*" -print0 2>/dev/null)
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
    find "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null
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
  done < <(find "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents" -name "*.md" -print0 2>/dev/null)
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
  done < <(find "${CLAUDE_DIR}/agents" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
}

# ===========================================================================
# REGRA 13 — Templates canônicos devem ser dialeto-puro
#   Templates em commands/common/templates/ são copiados verbatim ao criar
#   agentes/comandos; qualquer nome de tool estilo-Cursor [HARD] ou MCP
#   underscore-único [HARD] aqui re-propaga o bug para toda nova frota.
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
  done < <(find "${tdir}" -name "*.md" ! -iname 'readme.md' -print0 2>/dev/null)
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
  done < <(find "${mdir}" -name "*.md" -print0 2>/dev/null)
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
    done < <(find "${base}" -name "*.md" ! -iname "readme.md" ! -iname "index.md" -print0 2>/dev/null)
  done
}

# ===========================================================================
# REGRA 16 — Contagem de inventário-TOTAL divergente da SSOT [SOFT]
#   Checa SÓ frases-de-total CANÔNICAS contra inventory.sh — nunca 'N comandos' cru
#   nem 'N especializados' (palavra comum em por-categoria/feature). Marcadores de
#   total confiáveis: 'N comandos invocáveis', 'N comandos em M categorias',
#   'N agentes ...em M categorias' (qualquer texto antes de 'em N categorias') e
#   'N Knowledge Bases'. Assim NÃO flaga métricas de frota
#   ('28 agentes' de um run), breakdowns ('4 comandos especializados de docs',
#   '3 agentes especializados criados') nem snapshots. Complementa a Regra 9 (só CLAUDE.md).
#   SOFT: heurística sobre linguagem natural — surfaca drift sem bloquear CI por FP.
#   ISENTA: docs/analysis/ (datado), .claude/sessions/ (gitignored), docs/materials/
#   (derivado — deferido), docs/onion/inventory.md (SSOT), e frontmatter
#   status:snapshot / type:adr / type:evolution-backlog.
# ===========================================================================
check_inventory_total_drift() {
  local env_out cmd agent cats kb n pair num ct
  env_out="$(bash "${SCRIPT_DIR}/inventory.sh" --env 2>/dev/null || true)"
  cmd="$(printf '%s\n' "${env_out}" | grep '^ONION_COMMANDS_TOTAL=' | cut -d= -f2)"
  agent="$(printf '%s\n' "${env_out}" | grep '^ONION_AGENTS_TOTAL=' | cut -d= -f2)"
  cats="$(printf '%s\n' "${env_out}" | grep '^ONION_COMMAND_CATEGORIES=' | cut -d= -f2)"
  kb="$(printf '%s\n' "${env_out}" | grep '^ONION_KBS_TOTAL=' | cut -d= -f2)"
  [ -n "${cmd}" ] || return

  while IFS= read -r -d '' f; do
    case "${f}" in
      */docs/analysis/*|*/.claude/sessions/*|*/docs/materials/*|*/docs/onion/inventory.md|*/validation/fixtures/*) continue ;;
    esac
    if grep -qiE '^(status:[[:space:]]*snapshot|type:[[:space:]]*(adr|evolution-backlog))' "${f}"; then continue; fi

    # 'N comandos invocáveis' — 'invocáveis' é marcador de TOTAL (nunca por-categoria)
    while IFS= read -r n; do
      if [ -n "${n}" ] && [ "${n}" != "${cmd}" ]; then
        violation "SOFT" "${f}" "contagem-total de comandos divergente da SSOT: '${n} comandos invocáveis' (esperado ${cmd}) — derive de inventory.md (/meta:inventory)"
      fi
    done < <(grep -oiE '[0-9]+ comandos invocáveis' "${f}" 2>/dev/null | grep -oE '^[0-9]+')

    # 'N comandos em M categorias' — frase-de-total canônica
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
    done < <(grep -oiE '[0-9]+ comandos em [0-9]+ categorias' "${f}" 2>/dev/null)

    # 'N agentes ... em M categorias' — qualquer texto entre 'agentes' e 'em N categorias'
    # (de IA / especializados / IA distribuídos); o qualificador 'em N categorias' marca o total
    while IFS= read -r pair; do
      [ -z "${pair}" ] && continue
      num="$(printf '%s' "${pair}" | grep -oE '^[0-9]+')"
      if [ -n "${num}" ] && [ "${num}" != "${agent}" ]; then
        violation "SOFT" "${f}" "contagem-total de agentes divergente da SSOT: '${pair}' (esperado ${agent}) — /meta:inventory"
      fi
    done < <(grep -oiE '[0-9]+ agentes[^.,|]*em [0-9]+ categorias' "${f}" 2>/dev/null)

    # 'N Knowledge Bases' — frase-de-total (forma curta 'KBs' é ambígua em exemplos → não usada)
    while IFS= read -r n; do
      if [ -n "${n}" ] && [ "${n}" != "${kb}" ]; then
        violation "SOFT" "${f}" "contagem-total de KBs divergente da SSOT: '${n} Knowledge Bases' (esperado ${kb}) — /meta:inventory"
      fi
    done < <(grep -oiE '[0-9]+ knowledge bases' "${f}" 2>/dev/null | grep -oE '^[0-9]+')
  done < <(find "${CLAUDE_DIR}" "${REPO_ROOT}/docs" -name "*.md" -print0 2>/dev/null)
}

# ===========================================================================
# EXECUÇÃO DAS CHECAGENS
# ===========================================================================
echo "=== Onion Lint — iniciando validação em ${CLAUDE_DIR} ==="
echo ""

check_agent_frontmatter
check_agent_tool_names
check_template_dialect
check_metaspec_dialect
check_command_description
check_no_gpt4_model
check_no_mcp_onion_orchestrator
check_line_limits
check_kebab_case_filenames
check_no_fleet_orchestrator_agent
check_inventory_sync
check_claude_md_counts
check_no_direct_provider_calls
check_abstraction_methods_exist
check_context_freshness_stamp
check_inventory_total_drift

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
