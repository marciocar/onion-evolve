#!/usr/bin/env bash
# agent-brief.sh — monta o brief FINAL de um subagente de execução: cabeçalho fixo que manda ler e seguir o
# execution-agent-preamble.md + a linha da espera em primeiro plano COPIADA do preâmbulo + o brief.
#
# Por que existe (SAC-421, decisão do maestro de 2026-11-12): três subagentes num dia ficaram parados esperando
# tarefa de fundo, que não os acorda, porque os briefs não citavam o preâmbulo. A regra mora no preâmbulo; este
# ajudante garante que ela chegue ao brief sem ninguém reescrevê-la à mão (a linha é lida do arquivo por âncora).
#
# Uso:  bash .claude/utils/orchestration/agent-brief.sh <arquivo-do-brief>
#   rc 0 brief final no stdout · rc 2 brief ausente/vazio, preâmbulo ausente ou âncora da espera não achada.
# Env:  ONION_AGENT_PREAMBLE = caminho do preâmbulo (default: o do próprio repo; existe para a bancada).
set -euo pipefail

die2() { echo "agent-brief: $*" >&2; exit 2; }

brief="${1:-}"
[ -n "${brief}" ] || die2 "uso: agent-brief.sh <arquivo-do-brief>"
[ -f "${brief}" ] || die2 "brief ausente: ${brief}"
grep -q '[^[:space:]]' "${brief}" || die2 "brief vazio: ${brief}"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pre="${ONION_AGENT_PREAMBLE:-${here}/../../commands/common/prompts/execution-agent-preamble.md}"
[ -f "${pre}" ] || die2 "preâmbulo ausente: ${pre}"

# Âncora: o item "Processos longos" do preâmbulo (a espera em primeiro plano, com teto).
wait_line="$(grep -m1 -F -- '- Processos longos: ESPERA EM PRIMEIRO PLANO' "${pre}" || true)"
[ -n "${wait_line}" ] || die2 "âncora da espera em primeiro plano não achada em ${pre} (o preâmbulo mudou: ajuste a âncora aqui)"

# Caminho que o agente lê: relativo à raiz do repo quando o preâmbulo está dentro dele (o agente roda na raiz),
# senão o absoluto. Nunca um `.claude/` nu escrito aqui: dentro de um plugin ele não resolve (REGRA 74).
pre_abs="$(cd "$(dirname "${pre}")" && pwd)/$(basename "${pre}")"
root="$(git -C "$(dirname "${pre_abs}")" rev-parse --show-toplevel 2>/dev/null || true)"
pre_rel="${pre_abs}"
[ -n "${root}" ] && case "${pre_abs}" in "${root}"/*) pre_rel="${pre_abs#"${root}"/}" ;; esac

printf 'ANTES DE TUDO, leia e siga `%s`.\n' "${pre_rel}"
printf 'Regra que mais custou parar agente (copiada do preâmbulo):\n%s\n\n' "${wait_line}"
cat "${brief}"
