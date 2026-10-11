#!/usr/bin/env bash
# =============================================================================
# forced-model-check.sh — o tiering declarado vai mesmo rodar? (behavior-over-declaration)
#
# O PROBLEMA (medido, radar E3 r9, 2026-10-11): o passo 8 da skill onion-orchestration checava o
# modelo forçado com um grep da substring `CLAUDE_CODE_SUBAGENT_MODEL` no `env`. O Claude Code 2.1.296
# criou `CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL` (roda TODO agente de Workflow num modelo só) e aquele
# grep dá 0 para ela — o nome novo não contém a substring procurada. E o grep errava no sentido oposto
# também: casava `CLAUDE_CODE_SUBAGENT_MODEL` sozinha, que desde 2.1.251 é PISO (default), não força.
# Prosa que o agente executa à mão erra nos dois sentidos; este helper é a forma determinística.
#
# O QUE FORÇA (catálogo, cada item com a versão que o criou):
#   · CLAUDE_CODE_SUBAGENT_MODEL_FORCE    (2.1.257) ligada → TODO subagente, teammate e agente de
#     Workflow roda em CLAUDE_CODE_SUBAGENT_MODEL (ou no modelo principal), ignorando `model` por
#     spawn e por definição de agente;
#   · CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL (2.1.296) não-vazia → todo agente de Workflow roda nela.
# O QUE NÃO FORÇA: CLAUDE_CODE_SUBAGENT_MODEL sozinha (piso; `model:` e o spawn têm precedência).
# NOVIDADE FALHA ALTO: qualquer outra `CLAUDE_CODE_*AGENT_MODEL*` exportada e não-vazia, fora do
# catálogo, vira AVISO "não catalogada" — a classe do defeito é nome novo invisível, e um aviso a
# mais custa uma linha; um aviso a menos custa um relatório de tiering falso.
#
# USO      bash .claude/utils/orchestration/forced-model-check.sh
# SAÍDA    stdout: uma linha `AVISO: tiering declarado ≠ executado (env force) …` por causa, ou nada.
#          rc 0 = silêncio (o tiering declarado é o executado) · rc 1 = há AVISO · rc 2 = uso inválido.
# Determinístico, sem rede, sem LLM. Exercitado pela família forced_model do lint-selftest.
# =============================================================================
set -uo pipefail

if [ "$#" -ne 0 ]; then sed -n '/^# USO/,/^# Determin/p' "$0" >&2; exit 2; fi

_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
_warn=0
_emit_warning() { echo "AVISO: tiering declarado ≠ executado (env force) — $*"; _warn=1; }

_floor="${CLAUDE_CODE_SUBAGENT_MODEL:-}"
_effective="${_floor:-o modelo principal da sessão}"

if [ -n "${CLAUDE_CODE_SUBAGENT_MODEL_FORCE+x}" ]; then
  case "$(_lower "${CLAUDE_CODE_SUBAGENT_MODEL_FORCE}")" in
    1|true|yes|on) _emit_warning "CLAUDE_CODE_SUBAGENT_MODEL_FORCE=${CLAUDE_CODE_SUBAGENT_MODEL_FORCE}: todo subagente e agente de Workflow roda em ${_effective}" ;;
    ''|0|false|no|off) : ;;
    *) _emit_warning "CLAUDE_CODE_SUBAGENT_MODEL_FORCE=${CLAUDE_CODE_SUBAGENT_MODEL_FORCE} (valor ambíguo, tratado como ligado): modelo efetivo provável ${_effective}" ;;
  esac
fi

if [ -n "${CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL:-}" ]; then
  _emit_warning "CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL=${CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL}: todo agente de Workflow roda nele"
fi

while IFS= read -r _name; do
  case "${_name}" in
    CLAUDE_CODE_SUBAGENT_MODEL|CLAUDE_CODE_SUBAGENT_MODEL_FORCE|CLAUDE_CODE_WORKFLOW_SUBAGENT_MODEL) continue ;;
  esac
  [ -n "${!_name:-}" ] || continue
  _emit_warning "${_name}=${!_name} (não catalogada neste helper): trate como forçada até medir o que ela faz"
done < <(compgen -e | LC_ALL=C grep -E '^CLAUDE_CODE_[A-Z0-9_]*AGENT_MODEL[A-Z0-9_]*$' || true)

exit "${_warn}"
