#!/usr/bin/env bash
# =============================================================================
# task-manager-provider-hook.sh — SessionStart: anuncia o TASK_MANAGER_PROVIDER ativo.
#
# Propósito : O hook antigo (inline no settings.json) lia SÓ o ARQUIVO .env; o adapter
#             (detector.md) lê o AMBIENTE (process.env). Fontes diferentes → as duas
#             podiam divergir. Sinal de campo (adoção legacy 2026-07, D2): o projeto
#             usa direnv+pass (SEM .env solto), o Linear está provado e2e, e mesmo assim
#             o hook anunciava 'none' a cada boot. Pior caso simétrico: .env declara um
#             provider que o ambiente não tem → o hook anunciava um ✅ cosmético que o
#             adapter (cego) não honra. [[fix-must-become-mechanism]]
#
# Correção  : consulta o AMBIENTE PRIMEIRO (mesma fonte do adapter → hook e adapter
#             concordam), com .env como FALLBACK HONESTO — quando o provider só existe
#             no .env (não carregado no ambiente), avisa que o adapter ficaria cego em
#             vez de anunciar um provider cosmético.
#
# Saída     : JSON de hookSpecificOutput (additionalContext) no STDOUT. Nunca falha o
#             boot (set -uo pipefail + defaults). Determinístico, sem LLM.
#
# Consumido por .claude/settings.json (SessionStart) e exercitado pelo lint-selftest.sh
# (run_task_manager_hook_selftests).
# =============================================================================
set -uo pipefail

# o texto pode levar um caminho: sem escapar, `"` e `\` geram JSON inválido
emit() {
  local s="$1"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "${s}"
}

# (1) AMBIENTE primeiro — é o que o adapter (process.env) enxerga. Hook e adapter alinhados.
p="${TASK_MANAGER_PROVIDER:-}"
if [ -n "${p}" ]; then
  emit "Onion: TASK_MANAGER_PROVIDER ativo = ${p}"
  exit 0
fi

# (2) FALLBACK .env — declarado no arquivo mas AUSENTE do ambiente: o adapter ficaria cego.
#     Avisa honesto (não anuncia provider cosmético). Caminho relativo à raiz do projeto.
ENV_FILE="${CLAUDE_PROJECT_DIR:-.}/.env"
ENV_HINT=".env"
# WORKTREE sem .env: o provider vem do checkout principal, como no tm.sh; sem isto o hook anunciava `none` (2026-11-09).
if [ ! -e "${ENV_FILE}" ]; then
  _common="$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "${_common}" ] && [ -e "$(dirname "${_common}")/.env" ]; then ENV_FILE="$(dirname "${_common}")/.env"; ENV_HINT="$(printf '%q' "${ENV_FILE}")"; fi
fi
# ILEGÍVEL não é "none": abertura de verdade, porque sob sandbox `[ -r ]` responde legível. Só arquivo regular: FIFO penduraria.
if [ -e "${ENV_FILE}" ] && ! { [ -f "${ENV_FILE}" ] && { : < "${ENV_FILE}"; } 2>/dev/null; }; then
  emit "Onion: o .env existe mas esta ilegivel (sandbox ou permissao): provider desconhecido, o adapter fica cego"
  exit 0
fi
if [ -f "${ENV_FILE}" ]; then
  # UM parser só: o do env-check.sh, quando presente (o Elenxo mediu que dois parsers "alinhados" divergiam em aspas e
  # comentário). Sem o helper, o awk abaixo; e um valor fora da lista de providers não é ecoado.
  HELPER="${CLAUDE_PROJECT_DIR:-.}/.claude/utils/task-manager/env-check.sh"
  if [ -f "${HELPER}" ]; then
    pf="$(TASK_MANAGER_PROVIDER= bash "${HELPER}" --env "${ENV_FILE}" --provider 2>/dev/null)"
    [ "${pf}" = ausente ] && pf=""
  else
  pf="$(awk '{ l=$0; sub(/^[ \t]*export[ \t]+/, "", l) } l ~ /^[ \t]*TASK_MANAGER_PROVIDER[ \t]*=/ { v=l; sub(/^[^=]*=[ \t]*/, "", v); sub(/[ \t]+#.*$/, "", v); sub(/[ \t]+$/, "", v); gsub(/^["\047]|["\047]$/, "", v); sub(/[ \t]+$/, "", v); last=v } END { printf "%s", last }' "${ENV_FILE}" 2>/dev/null)"
    case "${pf}" in jira|clickup|asana|linear|zoho|none|"") ;; *) pf=invalido ;; esac
  fi
  if [ -n "${pf}" ]; then
    emit "Onion: TASK_MANAGER_PROVIDER=${pf} declarado no .env mas NAO no ambiente — carregue (set -a; source ${ENV_HINT}; set +a) senao o adapter fica cego"
    exit 0
  fi
fi

emit "Onion: TASK_MANAGER_PROVIDER ativo = none"
