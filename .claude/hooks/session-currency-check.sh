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
# defasagem nascer. Os registros são lidos no máximo 1× por hora, o origin e o SDK 1× a cada 5 min, e
# fonte que falhou fica 10 min sem ser tentada (o prazo de cada perna é 9 s). NUNCA bloqueia (exit 0
# sempre): toda superfície depende de registro de terceiro e de rede, e um veto que dispara quando o npm publica é falso positivo por construção (cláusula 4 da doutrina
# de guardas). Subir é ato do fluxo, com o maestro sabendo.
#
# ── DISCIPLINA ─────────────────────────────────────────────────────────────────────────────────────
# Avisa UMA vez por (sessão, superfície, assinatura): se algo novo ficar defasado, o publicado andar, ou uma
# superfície que tinha voltado a em dia cair de novo, avisa de novo. Fonte inalcançável aparece como NÃO
# MEDIDO, nunca como "em dia". A rede é paga no máximo uma vez por TTL de cada fonte (o censo guarda só as
# respostas remotas; o lado local é relido a cada prompt, então a cura aparece na hora).
#
# ── O GATE DA PRÓPRIA BRANCH: core.hooksPath ABSOLUTO (2026-10-26) ─────────────────────────────────
# A outra metade de "base atual": o pre-commit que roda tem de ser o DESTA branch. Medido em 2026-10-26
# (git 2.43, no core e num adotante): com `core.hooksPath .githooks` (relativo) cada worktree roda o
# .githooks/ da própria branch; com o caminho ABSOLUTO, toda worktree roda o do checkout principal, e um PR
# que muda o .githooks/pre-commit não é provado por ele mesmo. Causa conhecida: o Claude Code grava o
# caminho absoluto ao criar worktree de agente, ou seja NO MEIO da sessão; por isso o lembrete mora aqui
# (UserPromptSubmit) e não num SessionStart, que só o veria na sessão seguinte. LEMBRETE, nunca veto
# (exit 0): avisa 1× por (sessão, valor); consertado e voltando, avisa de novo. Lê o valor EFETIVO e só
# fala quando ele é absoluto e é, por identidade de diretório, o .githooks/ deste repositório (da árvore
# atual ou do checkout principal). Silêncio quando é relativo, está ausente, aponta para outro lugar (um
# gestor de hooks compartilhado não é este defeito), o diretório não existe, ou não há git. Roda mesmo sem
# o censo (não depende de rede nem de registro).
# TETO: o conserto sugerido escreve no `--local`; se o absoluto vier de config por worktree
# (extensions.worktreeConfig), o lugar certo é `--worktree`, e o texto não distingue.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
census="${ONION_CURRENCY_CENSUS:-${here}/../validation/currency-census.sh}"
repo="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# a sessão vem do JSON do hook (stdin); sem ele, do ambiente. Sem nenhuma, não há como deduplicar por sessão.
payload=""; [ -t 0 ] || payload="$(head -c 65536 2>/dev/null)"
sess="$(printf '%s' "${payload}" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([A-Za-z0-9._-]*\)".*/\1/p' | awk 'NR==1')"
[ -n "${sess}" ] || sess="${CLAUDE_CODE_SESSION_ID:-nosession}"
sess="${sess//[^A-Za-z0-9._-]/_}"
# o estado só vale num diretório da conta e não gravável por outros; fora disso, avisa sem deduplicar
# (barulho num ambiente quebrado é preferível a um aviso que outra conta pode calar)
state_dir="${ONION_CURRENCY_STATE_DIR:-${XDG_RUNTIME_DIR:-${HOME:-/nonexistent}/.cache}/onion-currency-notice}"
mkdir -p -m 700 "${state_dir}" 2>/dev/null || true
state=""
st="$(stat -c '%u %a' "${state_dir}" 2>/dev/null)" && [ "${st%% *}" = "$(id -u)" ] && case "${st##* }" in *[2367]?|*?[2367]) ;; *) state="${state_dir}/${sess}.tsv" ;; esac
[ -z "${state}" ] || [ -f "${state}" ] || : > "${state}" 2>/dev/null
hookspath_reminder() {
  command -v git >/dev/null 2>&1 || return 0
  local top common hp abs mark
  mark=""; [ -z "${state}" ] || mark="${state%.tsv}.hookspath"
  top="$(git -C "${repo}" rev-parse --show-toplevel 2>/dev/null)" || return 0
  common="$(git -C "${repo}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || common=""
  # o valor EFETIVO (o que o git usa nesta árvore: config por worktree vence o --local), e o `~/` que o git expande
  hp="$(git -C "${repo}" config --get core.hooksPath 2>/dev/null)" || hp=""
  abs="${hp}"; case "${hp}" in "~/"*) abs="${HOME:-/nonexistent}/${hp#\~/}" ;; esac
  # só o .githooks DESTE repositório, por IDENTIDADE de diretório (`-ef`), nunca por string: um gestor de hooks
  # compartilhado noutro lugar não é este defeito, e o conserto `.githooks` trocaria quais hooks rodam
  case "${abs}" in
    /*) if [ "${abs}" -ef "${top}/.githooks" ] || { [ -n "${common}" ] && [ "${abs}" -ef "$(dirname "${common}")/.githooks" ]; }; then :; else abs=""; fi ;;
    *) abs="" ;;
  esac
  if [ -z "${abs}" ]; then [ -z "${mark}" ] || rm -f "${mark}" 2>/dev/null; return 0; fi
  [ -n "${mark}" ] && [ "$(cat "${mark}" 2>/dev/null)" = "${hp}" ] && return 0
  [ -z "${mark}" ] || printf '%s' "${hp}" > "${mark}" 2>/dev/null
  echo "⚠️ Onion — core.hooksPath está ABSOLUTO ('${hp}'): toda worktree roda o .githooks/ do checkout principal, não o da própria branch, e um PR que muda o pre-commit não é provado por ele mesmo. Conserto: git config core.hooksPath .githooks (causa conhecida: o Claude Code grava o caminho absoluto ao criar worktree de agente)."
  echo "  (Repasse ao maestro com a fonte: este lembrete é do hook session-currency-check.sh; nada foi bloqueado.)"
}
hookspath_reminder
[ -f "${census}" ] || exit 0
tsv="$(bash "${census}" "${repo}" --tsv </dev/null 2>/dev/null)" || exit 0
# POR SUPERFÍCIE (não pelo aviso inteiro): cada superfície que não está em dia é avisada 1× por sessão e
# por assinatura; a que VOLTA a em dia, ou que SOME da medição (perna que morreu e voltou), sai do estado,
# e se ela cair de novo o aviso volta. Na BASE a assinatura é só o estado (a branch padrão anda a cada
# merge: re-avisar a cada sha seria ruído).
out="$(awk -F'\t' -v OFS='\t' -v stf="${state:-/dev/null}" '
  BEGIN { while ((getline l < stf) > 0) { split(l, a, "\t"); seen[a[1]] = a[2] } }
  NF >= 4 {
    s = $1; cur[s] = 1
    if ($4 == "em-dia") { delete seen[s]; next }
    sig = (s ~ /^base/) ? $4 : $4 "|" $2 "|" $3
    if (seen[s] != sig) { print "N", $0; seen[s] = sig }
  }
  END { for (k in seen) if (k in cur) print "S", k, seen[k] }' <<<"${tsv}")"
[ -n "${state}" ] && { printf '%s\n' "${out}" | awk -F'\t' -v OFS='\t' '$1=="S"{print $2,$3}' > "${state}.$$" 2>/dev/null && mv -f "${state}.$$" "${state}" 2>/dev/null; }
new_rows="$(printf '%s\n' "${out}" | awk -F'\t' -v OFS='\t' '$1=="N"{ $1=""; sub(/^\t/, ""); print }')"
[ -n "${new_rows}" ] || exit 0
printf '%s\n' "${new_rows}" | bash "${census}" --render
echo "  (Repasse ao maestro com a fonte: este aviso é do hook session-currency-check.sh, medido pelo currency-census.sh.)"
exit 0
