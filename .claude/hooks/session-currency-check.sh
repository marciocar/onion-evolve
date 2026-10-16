#!/usr/bin/env bash
# UserPromptSubmit — a base sobre a qual esta sessão constrói está nas versões atuais? (Onion, 2026-10-16)
#
# ── A ORDEM (maestro, 2026-10-16) ──────────────────────────────────────────────────────────────────
# "temos que usar sempre as versões mais atuais e não sair criando coisas em cima de base velha" e, logo
# depois, "este aviso anterior de manter atualizado é eterno, não só em memoria e sessão". Uma ordem eterna
# não pode depender de alguém lembrar dela: este hook a COBRA sozinho. Doutrina (a fonte citável):
# docs/knowledge-base/concepts/keep-current-doctrine.md. Medidor: .claude/validation/currency-census.sh.
#
# ── O BURACO QUE ELE FECHA (medido em 2026-10-16) ──────────────────────────────────────────────────
# O CLI do Agent SDK que serve o bridge estava em 0.3.301 com o npm em 0.3.302, e nada avisou: o
# session-version-drift.sh vê só processo≠disco do CLI do host, e o censo do /meta:cc-update compara o SDK
# com o host e só roda quando invocado. A regra "use a base atual" vivia num preâmbulo de agente no
# scratchpad da sessão.
#
# ── POR QUE UserPromptSubmit, AVISO e não veto ─────────────────────────────────────────────────────
# Sessões aqui vivem dias (o session-version-drift mediu 6): só um hook ao longo da vida da sessão vê a
# defasagem nascer. A rede é paga no máximo uma vez por TTL (cache do censo, 1 h); nos outros prompts é
# leitura de arquivo. NUNCA bloqueia (exit 0 sempre): toda superfície depende de registro de terceiro e de
# rede, e um veto que dispara quando o npm publica é falso positivo por construção (cláusula 4 da doutrina
# de guardas). Subir é ato do fluxo, com o maestro sabendo.
#
# ── DISCIPLINA ─────────────────────────────────────────────────────────────────────────────────────
# Avisa UMA vez por (sessão, assinatura do que não está em dia): se algo novo ficar defasado, ou o publicado
# andar, avisa de novo. Fonte inalcançável aparece como NÃO MEDIDO, nunca como "em dia".
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
census="${ONION_CURRENCY_CENSUS:-${here}/../validation/currency-census.sh}"
[ -f "${census}" ] || exit 0
repo="${CLAUDE_PROJECT_DIR:-$(pwd)}"
notice="$(bash "${census}" "${repo}" --notice 2>/dev/null)" || exit 0
[ -n "${notice}" ] || exit 0
# assinatura: as linhas do aviso sem a idade da medição (que muda a cada minuto)
sig="$(printf '%s\n' "${notice}" | sed '1s/Medido há [0-9]* min//' | cksum | awk '{print $1}')"
state_dir="${ONION_CURRENCY_STATE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/onion-currency-notice}"
mkdir -p "${state_dir}" 2>/dev/null || true
marker="${state_dir}/${CLAUDE_CODE_SESSION_ID:-nosession}-${sig}"
[ -e "${marker}" ] && exit 0
: > "${marker}" 2>/dev/null || true
printf '%s\n' "${notice}"
echo "  (Repasse ao maestro com a fonte: este aviso é do hook session-currency-check.sh, medido pelo currency-census.sh.)"
exit 0
