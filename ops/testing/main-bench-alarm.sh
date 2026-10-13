#!/usr/bin/env bash
# =============================================================================
# main-bench-alarm.sh — o ALARME do nível main da bancada em dois níveis (core-only)
#
# POR QUE EXISTE (passo D de D_MERGE_PROCESS_ONION_2026_10, selado pelo maestro em 2026-10-13):
# no PR a bancada roda só as famílias que o diff toca (selftest-pr-selection.sh). O que o PR deixou de
# exercer é exercido no push ao main, pela bancada COMPLETA — e o main pode estar quebrado no intervalo.
# Essa janela é ACEITA E DECLARADA (o Elenxo da decisão: os achados de defeito sem detecção automática e
# de quebra semântica sem conflito pedem verificar no main de qualquer jeito). Este script é o que faz
# a janela ter fim: quando a bancada do main reprova, ele
#   1. abre (ou atualiza) UMA issue de título fixo, nomeando o commit culpado e o run;
#   2. prepara o revert do commit do merge numa branch `revert/<sha12>` e tenta abrir o PR;
#   3. dispara os workflows do CI na branch do revert (PR aberto por GITHUB_TOKEN não dispara CI);
# e quando a bancada do main volta a passar, comenta e fecha a issue.
#
# ⚠️ NUNCA MERGEIA. O merge do revert é pelo caminho verificado (ops/pr-merge-verified.sh, o único que o
# hook de veto exit 2 deixa mergear no main). Um alarme que mergeasse sozinho tiraria o merge do caminho
# que o hook vigia — o mesmo motivo que deixou a fila de terceiro (opção F) gated.
#
# ⚠️ LIMITE MEDIDO em 2026-10-13: o repo tem `can_approve_pull_request_reviews: false`
# (gh api repos/marciocar/onion-evolve/actions/permissions/workflow), e com isso o GITHUB_TOKEN NÃO abre
# PR. O script empurra a branch, tenta o PR e, na recusa, escreve na issue o comando exato para abri-lo.
# Ligar a permissão é decisão do maestro, não deste script.
#
# Uso  : bash ops/testing/main-bench-alarm.sh --result <resultado> --sha <sha> --run-url <url> [--repo dono/nome]
#        <resultado> = o `needs.selftest.result` do run (success · failure · cancelled · skipped) ou
#        `plano-<resultado>` quando nem o plano saiu. Revert SÓ em `failure` (uma faixa REPROVOU);
#        cancelado/plano quebrado abre o alarme sem revert, porque o culpado não está provado.
# Exit : 0 alarme entregue (ou nada a fazer) · 1 não consegui abrir/atualizar a issue · 2 uso inválido.
# =============================================================================
set -uo pipefail

TITLE="🚨 main quebrado — a bancada completa reprovou no push ao main"
RESULT=""; SHA=""; RUN_URL=""; REPO="${GITHUB_REPOSITORY:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --result) shift; RESULT="${1:-}" ;;
    --sha) shift; SHA="${1:-}" ;;
    --run-url) shift; RUN_URL="${1:-}" ;;
    --repo) shift; REPO="${1:-}" ;;
    -h|--help) sed -n '/^# Uso  :/,/^# Exit :/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "main-bench-alarm: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
  shift
done
[ -n "${RESULT}" ] && [ -n "${REPO}" ] || { echo "main-bench-alarm: --result e --repo (ou GITHUB_REPOSITORY) obrigatórios" >&2; exit 2; }
case "${SHA}" in *[!0-9a-f]*|"") echo "main-bench-alarm: --sha precisa ser um sha hexadecimal" >&2; exit 2 ;; esac
[ "${#SHA}" -ge 12 ] || { echo "main-bench-alarm: --sha curto demais (${SHA})" >&2; exit 2; }
SHA12="${SHA:0:12}"

_open_issue() {  # número da issue ABERTA de título exato, ou vazio
  gh issue list --repo "${REPO}" --state open --limit 100 --json number,title \
    --jq ".[] | select(.title == \"${TITLE}\") | .number" 2>/dev/null | head -n1
}

# ── VERDE: a janela fecha ─────────────────────────────────────────────────────────────────────
if [ "${RESULT}" = "success" ]; then
  _n="$(_open_issue)"
  if [ -z "${_n}" ]; then echo "main-bench-alarm: main verde em ${SHA12}, nenhum alarme aberto — nada a fazer"; exit 0; fi
  gh issue comment "${_n}" --repo "${REPO}" --body "✅ A bancada completa voltou a passar no main em \`${SHA12}\` (${RUN_URL}). Fecho o alarme. PR de revert ainda aberto, se houver, NÃO é tocado: feche-o à mão se o conserto veio por outro caminho." >/dev/null \
    || { echo "main-bench-alarm: não consegui comentar na issue #${_n}" >&2; exit 1; }
  gh issue close "${_n}" --repo "${REPO}" >/dev/null || { echo "main-bench-alarm: não consegui fechar a issue #${_n}" >&2; exit 1; }
  echo "main-bench-alarm: main verde em ${SHA12} — issue #${_n} comentada e fechada"
  exit 0
fi

# ── VERMELHO: o culpado é o commit do push ───────────────────────────────────────────────────
_subj="$(git log -1 --format=%s "${SHA}" 2>/dev/null || echo '<commit ilegível no checkout>')"
_parents="$(git rev-list --parents -n1 "${SHA}" 2>/dev/null | wc -w)"; _parents=$(( ${_parents:-1} - 1 ))
_pr="$(printf '%s' "${_subj}" | sed -n 's/.*Merge pull request #\([0-9][0-9]*\).*/\1/p')"
BRANCH="revert/${SHA12}"
REVERT="não tentado (resultado '${RESULT}': o culpado não está provado — só faixa REPROVADA dispara revert)"

if [ "${RESULT}" = "failure" ]; then
  _gitbot=(-c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com")
  if git ls-remote --exit-code --heads origin "${BRANCH}" >/dev/null 2>&1; then
    REVERT="a branch \`${BRANCH}\` já existia (run repetido) — não refiz"
  elif ! git fetch -q origin main 2>/dev/null || ! git checkout -q -B "${BRANCH}" origin/main 2>/dev/null; then
    REVERT="FALHOU ao preparar a branch a partir de origin/main — revert manual"
  else
    _rv=(revert --no-edit); [ "${_parents}" -ge 2 ] && _rv+=(-m 1)
    if ! git "${_gitbot[@]}" "${_rv[@]}" "${SHA}" >/dev/null 2>&1; then
      git revert --abort >/dev/null 2>&1 || true
      REVERT="FALHOU: o revert de \`${SHA12}\` conflita com o main atual — revert manual"
    elif ! git push -q origin "HEAD:refs/heads/${BRANCH}" 2>/dev/null; then
      REVERT="FALHOU ao empurrar \`${BRANCH}\` — revert manual"
    else
      _body="Revert automático de \`${SHA12}\` (${_subj}), preparado porque a bancada completa reprovou no push ao main: ${RUN_URL}

NÃO foi mergeado por automação, e não deve ser: o merge é pelo caminho verificado (\`bash ops/pr-merge-verified.sh <PR> --merge-commit\`)."
      if _url="$(gh pr create --repo "${REPO}" --base main --head "${BRANCH}" --title "revert: ${_subj} (main quebrado em ${SHA12})" --body "${_body}" 2>&1)"; then
        REVERT="PR de revert aberto: ${_url##*$'\n'}"
      else
        REVERT="branch \`${BRANCH}\` empurrada, mas o PR NÃO abriu ($(printf '%s' "${_url}" | head -n1 | head -c 160)). Abra: \`gh pr create --base main --head ${BRANCH} --fill\`"
      fi
      # PR/push feito por GITHUB_TOKEN não dispara workflow; workflow_dispatch dispara (exceção documentada)
      for _wf in onion-selftest.yml onion-validate.yml; do
        gh workflow run "${_wf}" --repo "${REPO}" --ref "${BRANCH}" >/dev/null 2>&1 \
          && REVERT="${REVERT} · CI disparado: ${_wf}" || REVERT="${REVERT} · CI NÃO disparado: ${_wf}"
      done
    fi
  fi
fi

_f="$(mktemp)"
cat > "${_f}" <<EOF
A bancada completa (nível main da bancada em dois níveis) **não passou** no push ao main.

- **Commit culpado:** \`${SHA}\` — ${_subj}${_pr:+ (PR #${_pr})}
- **Resultado:** \`${RESULT}\`
- **Run:** ${RUN_URL}
- **Revert:** ${REVERT}

**Janela declarada:** o main pode ficar quebrado entre o merge e o merge do revert (a bancada completa do
main leva da ordem de 25 min, mais o tempo do merge verificado). É o preço aceito do nível PR rodar só as
famílias tocadas — decisão D_MERGE_PROCESS_ONION_2026_10, passo D. Enquanto este alarme está aberto, não
mergeie nada que não seja o conserto: cada merge novo alarga a janela e complica o revert.

Esta issue fecha sozinha quando a bancada completa voltar a passar num push ao main.
EOF
_n="$(_open_issue)"
if [ -n "${_n}" ]; then
  gh issue comment "${_n}" --repo "${REPO}" --body-file "${_f}" >/dev/null \
    || { echo "main-bench-alarm: não consegui comentar na issue #${_n}" >&2; rm -f "${_f}"; exit 1; }
  echo "main-bench-alarm: alarme ATUALIZADO na issue #${_n} — culpado ${SHA12} · ${REVERT}"
else
  gh issue create --repo "${REPO}" --title "${TITLE}" --body-file "${_f}" >/dev/null \
    || { echo "main-bench-alarm: não consegui abrir a issue de alarme" >&2; rm -f "${_f}"; exit 1; }
  echo "main-bench-alarm: alarme ABERTO — culpado ${SHA12} · ${REVERT}"
fi
rm -f "${_f}"
exit 0
