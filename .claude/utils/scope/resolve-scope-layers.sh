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
# Uso : resolve-scope-layers.sh <dir-do-escopo> [--user <path-settings-pessoa>] [--list] [--show-scope [--json]]
#   --list       : só imprime os paths das camadas resolvidas (não compõe). Útil p/ auditoria/proveniência.
#   --show-scope : proveniência por chave (paridade `git config --show-scope`) — repassa ao compose com os
#                  rótulos canônicos (empresa=/time=/pessoa=) e injeta --role/--form lidos do stamp
#                  `.claude/.onion-version` do repo, quando existir (§4.1: dimensão papel/forma).
#                  --provenance é alias; --json emite o formato de auditoria (regulado).
# Gracioso: camadas ausentes são puladas; 0 camadas → nada. Delega a compose-settings.sh (precisa jq).
# Determinístico. Exercitado por lint-selftest.sh (run_resolve_scope_layers_selftests).
# =============================================================================
set -uo pipefail

DIR=""; USERSET=""; LIST=""; SHOW=""; JSONF=""
usage() { echo "uso: resolve-scope-layers.sh <dir-do-escopo> [--user <path>] [--list] [--show-scope|--provenance] [--json]" >&2; }
while [ "$#" -gt 0 ]; do case "$1" in
  --user) USERSET="${2:-}"; shift 2 ;;
  --list) LIST=1; shift ;;
  --show-scope|--provenance) SHOW=1; shift ;;
  --json) JSONF=1; shift ;;
  -*) usage; exit 2 ;;
  *) [ -z "${DIR}" ] && DIR="$1"; shift ;;
esac; done
[ -n "${DIR}" ] || { usage; exit 2; }
[ -d "${DIR}" ] || { echo "ERRO: dir inexistente: ${DIR}" >&2; exit 2; }
[ -n "${JSONF}" ] && [ -z "${SHOW}" ] && { echo "ERRO: --json requer --show-scope." >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR_ABS="$(cd "${DIR}" && pwd)"
REPO="$(git -C "${DIR_ABS}" rev-parse --show-toplevel 2>/dev/null || echo "${DIR_ABS}")"
[ -n "${USERSET}" ] || USERSET="${HOME}/.claude/settings.json"

# Cadeia base→específico; só as que existem. Dedup: se o dir do time == repo, não repete a camada empresa.
# `paths` (compat --list) e `labeled` (rótulos canônicos p/ o --show-scope) andam em paralelo.
paths=(); labeled=()
if [ -f "${REPO}/.claude/settings.json" ]; then
  paths+=("${REPO}/.claude/settings.json");    labeled+=("empresa=${REPO}/.claude/settings.json")   # empresa (repo)
fi
if [ "${DIR_ABS}" != "${REPO}" ] && [ -f "${DIR_ABS}/.claude/settings.json" ]; then
  paths+=("${DIR_ABS}/.claude/settings.json"); labeled+=("time=${DIR_ABS}/.claude/settings.json")   # time (subdir)
fi
if [ -f "${USERSET}" ]; then
  paths+=("${USERSET}");                       labeled+=("pessoa=${USERSET}")                        # pessoa (user)
fi

if [ "${#paths[@]}" -eq 0 ]; then echo "resolve-scope-layers: nenhuma camada de settings.json encontrada." >&2; exit 0; fi

if [ -n "${LIST}" ]; then printf '%s\n' "${paths[@]}"; exit 0; fi

if [ -z "${SHOW}" ]; then exec bash "${HERE}/compose-settings.sh" "${paths[@]}"; fi

# --show-scope: injeta a dimensão papel/forma do stamp do repo (repos adotados; o core não carrega stamp).
args=(--show-scope)
[ -n "${JSONF}" ] && args+=(--json)
STAMP="${REPO}/.claude/.onion-version"
if [ -f "${STAMP}" ]; then
  role="$(grep -m1 '^role:' "${STAMP}" | sed 's/^role:[[:space:]]*//' || true)"
  form="$(grep -m1 '^form:' "${STAMP}" | sed 's/^form:[[:space:]]*//' || true)"
  case "${role}" in source|adopted) args+=(--role "${role}") ;; esac
  case "${form}" in full|docs-only|in-place) args+=(--form "${form}") ;; esac
fi
exec bash "${HERE}/compose-settings.sh" "${args[@]}" "${labeled[@]}"
