#!/usr/bin/env bash
# =============================================================================
# onion-version.sh — Identidade/proveniência do framework Onion (SSOT de versão)
#
# Propósito : Emitir a IDENTIDADE do framework derivada do git (commit + data),
#             SEM semver formal — preserva architecture.md §6.1 ("versão implícita
#             no main"). É o irmão de inventory.sh: deriva do estado real, não
#             digita à mão.
#
# Modelo    : o repo-FONTE (este) NÃO carrega stamp committado — a identidade é
#             lida AO VIVO daqui, evitando auto-referência (arquivo↔commit) e
#             churn por commit. Em repos ADOTADOS, /meta:adopt escreve
#             .claude/.onion-version com esta identidade + proveniência
#             (adopted_from, adopted_at, mode). Schema do stamp: architecture.md §6.1.
#
# Uso       : bash .claude/validation/onion-version.sh [--yaml|--json]
#               --yaml (default) : bloco YAML (humano + /meta:adopt)
#               --json           : objeto JSON (ferramentas / federação)
#
# Consumidores: /meta:adopt (carimba repos adotados) · federação (versão de cada
#               membro — multi-repo-federation.md) · CI.
# Determinístico (mesma árvore git → mesma saída). Sem LLM.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

cd "${REPO_ROOT}"

# Nome do framework: derivado do remote origin (fallback: basename do repo-root).
framework="$(git remote get-url origin 2>/dev/null | sed -E 's#.*/##; s#\.git$##' || true)"
[ -n "${framework}" ] || framework="$(basename "${REPO_ROOT}")"

# Identidade derivada do git — sem semver (§6.1). commit = ref curta; date = data do commit.
commit="$(git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
commit_date="$(git log -1 --format=%cd --date=short 2>/dev/null || echo unknown)"

# Papel: o repo-FONTE não carrega stamp committado; um repo ADOTADO carrega
# .claude/.onion-version (escrito pelo /meta:adopt). A PRESENÇA do stamp é a
# evidência de adoção — antes este script emitia 'role: source' hardcoded, o que
# tornava o guard de identidade do /meta:adopt inofensivo em instância adotada
# (o script é vendorizado; bug FED-3-1 da auditoria 2026-07-01).
role="source"
STAMP="${REPO_ROOT}/.claude/.onion-version"
if [ -f "${STAMP}" ]; then
  role="$(awk '/^role:/{print $2; exit}' "${STAMP}")"
  [ -n "${role}" ] || role="adopted"   # stamp presente sem campo role → adotado por definição
fi

FORMAT="${1:---yaml}"

case "${FORMAT}" in
  --json)
    printf '{"framework":"%s","commit":"%s","commit_date":"%s","role":"%s"}\n' \
      "${framework}" "${commit}" "${commit_date}" "${role}"
    ;;
  --yaml)
    cat <<YAML
framework: ${framework}
commit: ${commit}
commit_date: ${commit_date}
role: ${role}
YAML
    ;;
  *)
    echo "uso: bash .claude/validation/onion-version.sh [--yaml|--json]" >&2
    exit 2
    ;;
esac
