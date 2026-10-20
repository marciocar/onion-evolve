#!/usr/bin/env bash
# =============================================================================
# applied-delta.sh — "Arquivos aplicados" do relatório do --update, MEDIDO NO ALVO
#
# POR QUE EXISTE (sinal de campo de um hub, 2026-10-19, fricção 3): o relatório colava
# `git diff --stat <pin>..HEAD -- <manifesto>` da FONTE e dizia 239 arquivos; no alvo chegaram 540. A
# diferença era `vendor/kg-ssot` (389 arquivos), que já existia no core no pin mas só ENTROU NO MANIFESTO
# depois dele (5eed13fa, 2026-10-15): para o alvo ele chega inteiro, e o delta da fonte só conta o que mudou
# desde o pin. Toda entrada nova do manifesto cai nesse buraco. O delta da fonte responde "o que mudou no
# core"; a pergunta do relatório é "o que chegou no alvo", e só o alvo responde.
#
# COMO MEDE: no repo do alvo (a branch dedicada do update, ou a worktree irmã), de merge-base(<integração>,
# HEAD) até HEAD — o merge da onion/vendor e o que mais estiver commitado na branch — e, à parte, o que
# ainda está na árvore sem commit (config pós-merge, carimbo), que o commit durável leva em seguida. O
# merge-base, e não a ponta da integração, para que um commit novo na integração não entre na conta.
#
# USO  : applied-delta.sh <WORK> <INTEGRATION_BRANCH>
# SAÍDA: `Arquivos aplicados (medido no alvo): N commitados + M pendentes`, a quebra por diretório
#        (2 níveis) e o `git diff --stat` do intervalo
# EXIT : 0 = medido · 3 = não pude medir (não é repo git, integração inexistente, sem merge-base) —
#        escreva NÃO MEDIDO no relatório, nunca o delta da fonte no lugar
# =============================================================================
set -uo pipefail
W="${1:?uso: applied-delta.sh <WORK> <INTEGRATION_BRANCH>}"
INT="${2:?uso: applied-delta.sh <WORK> <INTEGRATION_BRANCH>}"

nm() { echo "ARQUIVOS APLICADOS NÃO MEDIDOS: $*" >&2; exit 3; }
git -C "${W}" rev-parse --git-dir >/dev/null 2>&1 || nm "${W} não é um repo git."
git -C "${W}" rev-parse --verify --quiet "${INT}^{commit}" >/dev/null || nm "a integração '${INT}' não existe em ${W}."
base="$(git -C "${W}" merge-base "${INT}" HEAD 2>/dev/null)" || nm "sem merge-base entre '${INT}' e HEAD em ${W}."
[ -n "${base}" ] || nm "sem merge-base entre '${INT}' e HEAD em ${W}."

# -c core.quotepath=off: nome com acento sai como está, e a contagem por linha não muda com isso.
names="$(git -C "${W}" -c core.quotepath=off diff --no-renames --name-only "${base}" HEAD)" || nm "git diff falhou em ${W}."
n=0; [ -n "${names}" ] && n="$(printf '%s\n' "${names}" | wc -l)"
pend="$(git -C "${W}" -c core.quotepath=off status --porcelain --untracked-files=all)" || nm "git status falhou em ${W}."
m=0; [ -n "${pend}" ] && m="$(printf '%s\n' "${pend}" | wc -l)"

echo "Arquivos aplicados (medido no alvo, merge-base(${INT})..HEAD): ${n} commitados + ${m} pendentes"
if [ "${n}" -gt 0 ]; then
  echo "Por diretório:"
  printf '%s\n' "${names}" | awk -F/ '{ k = (NF > 2) ? $1 "/" $2 : (NF == 2 ? $1 : "(raiz)"); c[k]++ }
    END { for (k in c) printf "  %6d  %s\n", c[k], k }' | LC_ALL=C sort -k1,1nr -k2,2
  echo
  git -C "${W}" -c core.quotepath=off diff --no-renames --stat=200 "${base}" HEAD | tail -n 1
fi
exit 0
