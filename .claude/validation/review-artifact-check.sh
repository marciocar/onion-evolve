#!/usr/bin/env bash
# review-artifact-check.sh — este PR foi revisado, e há RESÍDUO MATERIAL disso?
#
# ═══ POR QUE EXISTE (dano medido em 2026-08-06) ═══
# Em 2026-08-02 o diário registrou: 15 auto-correções, 8 só existiram porque o maestro perguntou,
# "nenhuma foi pega por auto-revisão". Em 2026-08-06 repetiu na mesma proporção: ~8 erros, quase
# todos descobertos porque ELE perguntou. Nomear o problema não o curou — e é essa a prova de que a
# cura não pode ser outra declaração de intenção.
#
# Das 8 falhas daquele dia, 6 foram achadas por REVISÃO ADVERSARIAL rodada à mão (2 execuções,
# 15 defeitos reais). O revisor do CI não as pegaria: ele estoura o orçamento de turnos justamente
# nos PRs grandes, e o `onion-review` sai VERDE por desenho quando isso acontece.
#
# ═══ O QUE ESTA GUARDA É, E O QUE ELA NÃO É ═══
# Ela NÃO julga a qualidade da revisão — nenhum script determinístico sabe se um achado é bom. Ela
# exige o RESÍDUO: um artefato commitado, cujo hash amarra a revisão ao diff REVISADO. É a forma que
# o diário de 08-02 identificou como a única que funciona — "resíduo material, auditado por terceiro,
# desacoplado do ator" — em oposição à que falhou: "vou prestar mais atenção".
#
# ═══ O TETO, DECLARADO ANTES DE PROMETER ═══
# Este repo NÃO tem branch protection (privado sem Pro — a API devolve 403). Nenhum check é
# obrigatório e NADA impede mecanicamente um merge. O que esta guarda torna impossível não é
# "mergear errado" — é "mergear sem saber". Prometer mais que isso seria falso.
#
# ═══ ESCOPO: SÓ QUANDO HÁ PR, E O CORTE IMPORTA MAIS QUE A REGRA ═══
# Exigir o artefato a cada commit intermediário travaria o trabalho — e falso-positivo TRAVANTE é o
# modo de falha que esta casa já mediu (diary 2026-08-02: como `exit 2` é o único canal, todo
# disparo interrompe; "o detector não pode ser heurístico"). A revisão se faz quando o trabalho é
# PROPOSTO, não enquanto é feito. Logo: só cobra quando existe PR aberto para o branch.
#
# Uso  : bash .claude/validation/review-artifact-check.sh [<repo_root>] [--format tsv]
# Saída: relatório humano (default) ou TSV (severidade·tag·path·mensagem)
# Exit : 0 = artefato presente e casando, ou fora de escopo · 1 = falta/caducou · 2 = uso inválido
set -euo pipefail

REPO_ROOT="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")/../..}" 2>/dev/null && pwd)" || {
  printf 'review-artifact-check: repo_root inválido\n' >&2; exit 2; }
FORMAT=human
for a in "$@"; do case "$a" in tsv|--format=tsv) FORMAT=tsv ;; esac; done
cd "${REPO_ROOT}"

REVIEW_DIR="docs/evolution/review"
SKIPS=""
_skip() { SKIPS="${SKIPS}${SKIPS:+ · }$1"; }

_out() {  # $1=sev $2=tag $3=path $4=msg
  if [ "${FORMAT}" = tsv ]; then printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  else printf '  ✗ %s: %s\n    %s\n' "$2" "$3" "$4"; fi
}

[ "${FORMAT}" = tsv ] || printf '══ REVIEW-ARTIFACT — este PR tem resíduo de revisão? ══\n'

# ── ESCOPO ────────────────────────────────────────────────────────────────────────────────────
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
DEFAULT="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
[ -n "${DEFAULT}" ] || DEFAULT=main

if [ -z "${BRANCH}" ] || [ "${BRANCH}" = "HEAD" ]; then
  _skip "detached-head"; [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"; exit 0
fi
if [ "${BRANCH}" = "${DEFAULT}" ]; then
  _skip "branch-default"; [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"; exit 0
fi

# Há PR aberto para este branch? É o que separa "trabalho em curso" de "trabalho PROPOSTO".
# Em CI o contexto é dado pelo evento; localmente pergunta-se ao forge.
PR_NUM=""
if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  PR_NUM="${GITHUB_REF_NAME%%/*}"
elif command -v gh >/dev/null 2>&1; then
  PR_NUM="$(gh pr view --json number --jq .number 2>/dev/null || true)"
else
  # SEM `gh` a guarda NÃO SABE se há PR. Declarar a ignorância é o comportamento correto — o mesmo
  # que o kg-radar faz quando não consegue ler, e o oposto do verde silencioso.
  _skip "sem-gh-nao-da-para-saber-se-ha-PR"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

if [ -z "${PR_NUM}" ]; then
  _skip "sem-PR-aberto(trabalho-em-curso)"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

BASE="$(git merge-base "origin/${DEFAULT}" HEAD 2>/dev/null || git merge-base "${DEFAULT}" HEAD 2>/dev/null || true)"
if [ -z "${BASE}" ]; then
  _skip "sem-merge-base-com-${DEFAULT}"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"; exit 0
fi

# ISENÇÃO DECLARADA, vocabulário FECHADO: um PR que edita o próprio revisor não pode ser gateado por
# ele — a action se auto-pula quando o workflow difere da branch default (ovo-galinha estrutural,
# documentado em .github/workflows/onion-review.yml). Isenção CONTADA, nunca silenciosa.
if git diff --name-only "${BASE}" HEAD 2>/dev/null | grep -qx '.github/workflows/onion-review.yml'; then
  _skip "PR-edita-o-proprio-revisor(ovo-galinha)"
  [ "${FORMAT}" = tsv ] || printf '  ⊘ fora de escopo: %s\n' "${SKIPS}"
  exit 0
fi

# ── O DIFF REVISADO ───────────────────────────────────────────────────────────────────────────
# O diretório de review sai do hash, senão o artefato mudaria o hash que ele mesmo declara.
DIFF_SHA="$(git diff "${BASE}" HEAD -- . ":(exclude)${REVIEW_DIR}" 2>/dev/null | sha256sum | cut -c1-64)"
SLUG="$(printf '%s' "${BRANCH}" | tr '/' '-')"
ART="${REVIEW_DIR}/${SLUG}.md"

if [ ! -f "${ART}" ]; then
  _out HARD ARTEFATO-AUSENTE "${ART}" "PR #${PR_NUM} aberto e sem resíduo de revisão. Rode a passada adversarial e registre o resultado em ${ART} (campos: reviewed_diff_sha256 · findings_total · findings_real · tokens · duration_min · verdict). O hash deste diff é ${DIFF_SHA}."
  [ "${FORMAT}" = tsv ] || printf '  (o verde do onion-review é soft-pass — não substitui esta passada)\n'
  exit 1
fi

_field() { sed -n "s/^$1:[[:space:]]*//p" "${ART}" | head -1 | tr -d '"'; }
DECL="$(_field reviewed_diff_sha256)"

if [ -z "${DECL}" ]; then
  _out HARD CAMPO-AUSENTE "${ART}" "artefato existe mas não declara reviewed_diff_sha256 — sem ele não há como saber SE a revisão cobriu ESTE código. Esperado: ${DIFF_SHA}"
  exit 1
fi
if [ "${DECL}" != "${DIFF_SHA}" ]; then
  _out HARD ARTEFATO-CADUCO "${ART}" "a revisão registrada cobre outro diff (declarado ${DECL}, atual ${DIFF_SHA}) — o código mudou DEPOIS de revisado. Re-revise e re-carimbe."
  exit 1
fi

# Os campos da REAVALIAÇÃO EM N=10 (decisão do maestro, 2026-08-06): a cadência "todo PR" só pode ser
# reavaliada se os dados existirem. Sem eles, no 10º PR eu repetiria o erro que este ciclo cura —
# declarar "medido" sem ledger. São exigidos, não sugeridos.
FALTAM=""
for f in findings_total findings_real tokens duration_min verdict; do
  [ -n "$(_field "${f}")" ] || FALTAM="${FALTAM}${FALTAM:+, }${f}"
done
if [ -n "${FALTAM}" ]; then
  _out HARD CAMPO-DE-REAVALIACAO-AUSENTE "${ART}" "faltam: ${FALTAM}. São o dado da reavaliação em N=10 — sem eles a cadência 'todo PR' não pode ser julgada, e a falsificação declarada deste mecanismo é justamente chegar ao 10º PR sem os campos."
  exit 1
fi

[ "${FORMAT}" = tsv ] || printf '  ✅ PR #%s: revisão registrada em %s, casando com o diff atual\n' "${PR_NUM}" "${ART}"
exit 0
