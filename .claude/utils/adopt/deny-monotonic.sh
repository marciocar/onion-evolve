#!/usr/bin/env bash
# =============================================================================
# deny-monotonic.sh — a linha "deny" do relatório do /meta:adopt --update: o permissions.deny do adotante
# NUNCA encolhe num update.
#
# Uso : deny-monotonic.sh <WORK> <INTEGRATION_BRANCH>
#   WORK = a branch dedicada do update (o próprio alvo ou a worktree irmã), lida na ÁRVORE (o que vai no PR)
# stdout: `deny: N no alvo (<ref>) → M no head` e, se faltar regra, uma linha `- <regra>` por regra perdida
# rc  : 0 nenhuma regra do alvo se perdeu · 1 PERDEU regra (PARE: o update não segue assim)
#       2 uso · 3 NÃO MEDIDO (não é repo, sem jq, JSON inválido, integração inexistente)
#
# ══ POR QUE EXISTE (2026-11-06, sinal de campo da curadoria) ══════════════════════════════════════════
# O head do PR do update tinha 0 regras de deny e a origin/main do adotante 67. A causa era a base velha (a
# branch nasceu da main local defasada, curado no dedicated-branch.sh), mas o relatório não tinha linha que
# visse isso: o diff de hooks compara a foto tirada DENTRO da branch, que já nascera sem o deny. Aqui o "antes"
# é a ponta MAIS NOVA da integração (o nome dado, o upstream dele e origin/<nome>, a que descende das outras),
# lida pelo git, e não a foto. A comparação é por REGRA, não por contagem: trocar uma regra por outra mantém
# N = M e ainda assim perde a do alvo. Deny é monotônico: o vendor soma, e só apaga o que está declarado em
# deny-retired.tsv (2026-11-09); a retirada declarada é nomeada e não reprova.
# Exercitado por lint-selftest.sh (run_deny_monotonic_selftests).
# =============================================================================
set -uo pipefail
W="${1:-}"; INT="${2:-}"
[ -n "${W}" ] && [ -n "${INT}" ] || { echo "uso: deny-monotonic.sh <WORK> <INTEGRATION_BRANCH>" >&2; exit 2; }
nm() { echo "deny: NÃO MEDIDO — $*" ; exit 3; }
command -v jq >/dev/null 2>&1 || nm "jq ausente."
git -C "${W}" rev-parse --git-dir >/dev/null 2>&1 || nm "${W} não é um repo git."
git -C "${W}" rev-parse --verify --quiet "${INT}^{commit}" >/dev/null || nm "a integração '${INT}' não existe em ${W}."

REF="${INT}"
_cands=("${INT}")
_up="$(git -C "${W}" rev-parse --abbrev-ref --symbolic-full-name "${INT}@{upstream}" 2>/dev/null)" && [ -n "${_up}" ] && _cands+=("${_up}")
git -C "${W}" rev-parse --verify --quiet "refs/remotes/origin/${INT}^{commit}" >/dev/null && _cands+=("origin/${INT}")
for _c in "${_cands[@]}"; do
  [ "${_c}" = "${REF}" ] && continue
  git -C "${W}" merge-base --is-ancestor "${REF}" "${_c}" 2>/dev/null && REF="${_c}"
done

# o "antes": settings.json na ponta da integração (ausente = 0 regras, o adotante não tinha deny)
if git -C "${W}" cat-file -e "${REF}:.claude/settings.json" 2>/dev/null; then
  before="$(git -C "${W}" show "${REF}:.claude/settings.json" | jq -c '[.permissions.deny // [] | .[]] | unique')" \
    || nm "o settings.json de ${REF} não é JSON válido."
else before='[]'; fi
# o "depois": a árvore da branch do update (ausente com deny no alvo = tudo perdido)
if [ -f "${W}/.claude/settings.json" ]; then
  after="$(jq -c '[.permissions.deny // [] | .[]] | unique' "${W}/.claude/settings.json")" \
    || nm "o settings.json do head não é JSON válido."
else after='[]'; fi

n="$(jq 'length' <<< "${before}")"; m="$(jq 'length' <<< "${after}")"
lost="$(jq -r --argjson a "${after}" '.[] | select(. as $r | $a | index($r) | not)' <<< "${before}")"
echo "deny: ${n} no alvo (${REF}) → ${m} no head"
# a retirada DECLARADA em deny-retired.tsv não é perda: é a lista versionada do core, nomeada no relatório
# a lista e o leitor moram ao lado deste script, sem variável que os troque: lista de fora não pode aprovar perda
_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ret=""
[ -f "${_here}/deny-retired-list.sh" ] && _ret="$(bash "${_here}/deny-retired-list.sh" "${_here}/deny-retired.tsv")"
if [ -n "${lost}" ] && [ -n "${_ret}" ]; then
  _declared="$(grep -Fxf <(printf '%s\n' "${_ret}") <<< "${lost}" || true)"
  if [ -n "${_declared}" ]; then
    echo "retirada declarada pelo core: $(printf '%s\n' "${_declared}" | wc -l) regra(s)"
    printf '%s\n' "${_declared}" | sed 's/^/~ /'
    lost="$(grep -Fxvf <(printf '%s\n' "${_ret}") <<< "${lost}" || true)"
  fi
fi
if [ -n "${lost}" ]; then
  echo "PARE: o update PERDEU $(printf '%s\n' "${lost}" | wc -l) regra(s) de deny do alvo (deny é monotônico):"
  printf '%s\n' "${lost}" | sed 's/^/- /'
  exit 1
fi
exit 0
