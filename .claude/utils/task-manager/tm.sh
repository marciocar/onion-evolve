#!/usr/bin/env bash
# tm.sh — dispatcher EXECUTÁVEL do task manager: `tm.sh <capability> [args]`.
#
# Por que existe (SAC-65, fatia 1, 2026-10-11): até aqui o adapter era só prosa (adapters/<p>.md) e a
# declaração (adapters/<p>.capabilities.tsv). Não havia executável, e a sessão principal operava o Linear
# com scripts GraphQL avulsos fora do repo — o mesmo cliente reescrito a cada sessão. Este dispatcher
# resolve o provider ativo e entrega o verbo ao executável dele (adapters/<p>.py | adapters/<p>.sh).
#
# Uso:
#   tm.sh --capabilities                 → verbos que o executável do provider ativo implementa (um por linha)
#   tm.sh item.read SAC-65              → leitura COMPLETA (comentários, atividade, hierarquia, anexos); --lean = enxuta
#   tm.sh attachment.list SAC-65  ·  tm.sh attachment.read SAC-65 <n>  ·  tm.sh attachment.add SAC-65 <arquivo>
#   tm.sh activity.list SAC-65  ·  tm.sh hierarchy.context SAC-65  ·  tm.sh inline.refs SAC-65
#   tm.sh comment.add SAC-65 "texto em markdown"   (ou --body-file <arquivo>)
#   tm.sh status.transition SAC-65 <nomeDoEstado|stateId>
#   tm.sh item.create --title T [--description D] [--project P] [--parent ID]
#   tm.sh search.query "<texto>"   ·   tm.sh project.list   ·   tm.sh hierarchy.subtask_list SAC-65
# Os verbos são os ids do vocabulário de interface.md §Capacidades.
#
# Saída: JSON em stdout · erros em pt-BR em stderr · rc 0 ok, 1 erro do provedor (HTTP, GraphQL com
# `errors`, entidade não achada), 2 uso/configuração (inclusive provider sem executável).
#
# Provider: `env-check.sh --provider` (ambiente primeiro, depois o .env). Nunca troca de provider por
# conta própria: provider sem executável sai com exit 2 nomeando o que falta.
# Segredo: o .env NÃO é carregado nem executado aqui. O dispatcher só aponta o caminho em TM_ENV_FILE, e o
# executável lê dele, COMO DADO, só a chave do próprio provider (mesma regra do env-check.sh). Numa worktree
# sem .env, usa o .env da árvore principal (git common dir) — onde o maestro o mantém.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_env_file() {
  [ -n "${TM_ENV_FILE:-}" ] && { printf '%s' "${TM_ENV_FILE}"; return; }
  local top common
  top="$(git -C "${PWD}" rev-parse --show-toplevel 2>/dev/null || pwd)"
  if [ -f "${top}/.env" ]; then printf '%s' "${top}/.env"; return; fi
  common="$(git -C "${PWD}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "${common}" ] && [ -f "$(dirname "${common}")/.env" ]; then printf '%s' "$(dirname "${common}")/.env"; return; fi
  printf '%s' "${top}/.env"
}

ENV_FILE="$(resolve_env_file)"
export TM_ENV_FILE="${ENV_FILE}"

provider="$(bash "${HERE}/env-check.sh" --env "${ENV_FILE}" --provider 2>/dev/null || true)"
case "${provider}" in
  ""|ausente)
    echo "tm: TASK_MANAGER_PROVIDER ausente (nem no ambiente, nem em ${ENV_FILE}) — rode /meta:setup-integration" >&2; exit 2 ;;
  invalido)
    echo "tm: TASK_MANAGER_PROVIDER inválido — rode /meta:setup-integration" >&2; exit 2 ;;
  none)
    echo "tm: provider 'none' — não há task manager remoto para operar (modo offline, @task-specialist)" >&2; exit 2 ;;
esac

exe=""
if [ -f "${HERE}/adapters/${provider}.py" ]; then exe="py"
elif [ -f "${HERE}/adapters/${provider}.sh" ]; then exe="sh"; fi
if [ -z "${exe}" ]; then
  echo "tm: o provider ativo '${provider}' ainda não tem executável — falta adapters/${provider}.py (ou .sh)." >&2
  echo "    Hoje só há a prosa (adapters/${provider}.md) e a declaração (adapters/${provider}.capabilities.tsv). Não troco de provider por conta própria." >&2
  exit 2
fi

if [ $# -eq 0 ]; then
  echo "uso: tm.sh --capabilities | <capability> [args]   (provider ativo: ${provider})" >&2; exit 2
fi

if [ "${exe}" = "py" ]; then
  command -v python3 >/dev/null 2>&1 || { echo "tm: python3 ausente — o executável do ${provider} exige python3" >&2; exit 2; }
  exec python3 -I -B "${HERE}/adapters/${provider}.py" "$@"
else
  exec bash "${HERE}/adapters/${provider}.sh" "$@"
fi
