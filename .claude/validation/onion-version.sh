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

FORMAT="${1:---yaml}"

case "${FORMAT}" in
  --json)
    printf '{"framework":"%s","commit":"%s","commit_date":"%s","role":"source"}\n' \
      "${framework}" "${commit}" "${commit_date}"
    ;;
  --yaml)
    cat <<YAML
framework: ${framework}
commit: ${commit}
commit_date: ${commit_date}
role: source
YAML
    ;;
  *)
    echo "uso: bash .claude/validation/onion-version.sh [--yaml|--json]" >&2
    exit 2
    ;;
esac
