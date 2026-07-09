#!/usr/bin/env bash
# =============================================================================
# resolve-scope-layers.sh — descobre a cadeia de camadas de settings.json de um escopo e compõe o efetivo.
#
# RFC-0005 (herança de escopo), fecha o loop do compose-settings.sh: automatiza a invocação da convenção
# (scope-convention-2026.md). Dado o diretório de um TIME (ou pessoa), descobre os settings.json das camadas
# que EXISTEM, na ordem base→específico, e compõe o efetivo:
#     empresa (repo/.claude/settings.json) → time (<dir>/.claude/settings.json) → pessoa (~/.claude/settings.json)
# (O framework já é a base do settings.json do repo — vendorizado.)
#
# Uso : resolve-scope-layers.sh <dir-do-escopo> [--user <path-settings-pessoa>] [--list]
#   --list : só imprime os paths das camadas resolvidas (não compõe). Útil p/ auditoria/proveniência.
# Gracioso: camadas ausentes são puladas; 0 camadas → nada. Delega a compose-settings.sh (precisa jq).
# Determinístico. Exercitado por lint-selftest.sh (run_resolve_scope_layers_selftests).
# =============================================================================
set -uo pipefail

DIR=""; USERSET=""; LIST=""
while [ "$#" -gt 0 ]; do case "$1" in
  --user) USERSET="${2:-}"; shift 2 ;;
  --list) LIST=1; shift ;;
  -*) echo "uso: resolve-scope-layers.sh <dir-do-escopo> [--user <path>] [--list]" >&2; exit 2 ;;
  *) [ -z "${DIR}" ] && DIR="$1"; shift ;;
esac; done
[ -n "${DIR}" ] || { echo "uso: resolve-scope-layers.sh <dir-do-escopo> [--user <path>] [--list]" >&2; exit 2; }
[ -d "${DIR}" ] || { echo "ERRO: dir inexistente: ${DIR}" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_ABS="$(cd "${DIR}" && pwd)"
REPO="$(git -C "${DIR_ABS}" rev-parse --show-toplevel 2>/dev/null || echo "${DIR_ABS}")"
[ -n "${USERSET}" ] || USERSET="${HOME}/.claude/settings.json"

# Cadeia base→específico; só as que existem. Dedup: se o dir do time == repo, não repete a camada empresa.
layers=()
[ -f "${REPO}/.claude/settings.json" ] && layers+=("${REPO}/.claude/settings.json")                  # empresa (repo)
if [ "${DIR_ABS}" != "${REPO}" ] && [ -f "${DIR_ABS}/.claude/settings.json" ]; then
  layers+=("${DIR_ABS}/.claude/settings.json")                                                        # time (subdir)
fi
[ -f "${USERSET}" ] && layers+=("${USERSET}")                                                         # pessoa (user)

if [ "${#layers[@]}" -eq 0 ]; then echo "resolve-scope-layers: nenhuma camada de settings.json encontrada." >&2; exit 0; fi

if [ -n "${LIST}" ]; then printf '%s\n' "${layers[@]}"; exit 0; fi
exec bash "${HERE}/compose-settings.sh" "${layers[@]}"
