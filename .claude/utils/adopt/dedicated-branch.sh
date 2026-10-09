#!/usr/bin/env bash
# =============================================================================
# dedicated-branch.sh — prepara a BRANCH DEDICADA onde o /meta:adopt --update e o --promote-hub
# escrevem, e imprime o DIRETÓRIO onde trabalhar.
#
# Uso : dedicated-branch.sh <TARGET> <BRANCH> <BASE>
#   TARGET = repo do alvo · BRANCH = chore/onion-update-<pin> | chore/onion-promote-hub
#   BASE   = de onde a branch nasce (a integração do alvo); ignorada se BRANCH já existe (retomada)
# stdout: o diretório de trabalho — o próprio TARGET, ou uma WORKTREE dele quando há farol vivo.
# rc  : 0 pronto · 2 precondição (não-repo, base inexistente, árvore suja, branch presa noutra worktree)
#
# ══ POR QUE EXISTE (F1 das portas, SAC-89, 2026-10-09) ════════════════════════════════════════════
# Medido no --update de um hub adotante (2026-10): o adopt.md mandava `BR=$INTEGRATION_BRANCH`, o vendor-branch
# fazia checkout E merge na integração, e o durable-commit fechava com `--no-verify`. Três escolhas que
# somadas punham o framework novo na branch de integração do adotante SEM passar por PR nem pelo gate
# dele — o oposto do que o Onion cobra de qualquer outra mudança. A branch dedicada devolve o update
# ao caminho normal: commit numa branch própria → push → PR → merge commit.
#
# E o FAROL: se há outra sessão viva no alvo (`session-beacon.sh check` rc=1), um `checkout` aqui
# troca a branch debaixo dela — o incidente W1×W2 que criou o farol (I3: um escritor por repo inclui
# SESSÕES). Com farol vivo a branch nasce numa worktree IRMÃ do alvo e o checkout dele fica intocado.
# Sem o script do farol não há como provar ausência, e a ausência de prova cai no lado seguro: worktree.
# Exercitado por lint-selftest.sh (run_adopt_robust_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="${1:-}"; BR="${2:-}"; BASE="${3:-}"
[ -n "${T}" ] && [ -n "${BR}" ] && [ -n "${BASE}" ] || { echo "uso: dedicated-branch.sh <TARGET> <BRANCH> <BASE>" >&2; exit 2; }

TOP="$(git -C "${T}" rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRO: '${T}' não é repositório git." >&2; exit 2; }
_has_br=0; git -C "${TOP}" rev-parse --verify --quiet "refs/heads/${BR}" >/dev/null && _has_br=1
if [ "${_has_br}" = 0 ] && ! git -C "${TOP}" rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null; then
  echo "ERRO: base '${BASE}' não resolve para um commit em ${TOP}." >&2; exit 2
fi

# ── farol: há OUTRA sessão viva no alvo? ─────────────────────────────────────────────────────────
BEACON="${HERE}/../../validation/session-beacon.sh"
LIVE=1
if [ -f "${BEACON}" ]; then
  bash "${BEACON}" check "${TOP}" >/dev/null 2>&1 && LIVE=0
else
  echo "  (sem session-beacon.sh: não há como provar que o alvo está livre — uso worktree)" >&2
fi

if [ "${LIVE}" = 1 ]; then
  WT="$(dirname "${TOP}")/$(basename "${TOP}")-${BR//\//-}"
  if git -C "${TOP}" worktree list --porcelain | grep -qxF "worktree ${WT}"; then
    _cur="$(git -C "${WT}" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ "${_cur}" = "${BR}" ] || { echo "ERRO: a worktree ${WT} existe mas está em '${_cur}', não em '${BR}'." >&2; exit 2; }
  elif [ -e "${WT}" ]; then
    echo "ERRO: ${WT} existe e não é worktree deste repo — não sobrescrevo." >&2; exit 2
  elif [ "${_has_br}" = 1 ]; then
    git -C "${TOP}" worktree add -q "${WT}" "${BR}" >&2 || { echo "ERRO: não consegui abrir a worktree de '${BR}' (presa noutra worktree?)." >&2; exit 2; }
  else
    git -C "${TOP}" worktree add -q -b "${BR}" "${WT}" "${BASE}" >&2 || { echo "ERRO: não consegui criar a worktree de '${BR}'." >&2; exit 2; }
  fi
  echo "  farol vivo em ${TOP}: trabalho na worktree ${WT} (branch ${BR}); o checkout do alvo fica intocado." >&2
  printf '%s\n' "${WT}"
  exit 0
fi

# ── sem farol: a branch nasce no próprio checkout, que tem de estar limpo ────────────────────────
if ! git -C "${TOP}" diff --quiet 2>/dev/null || ! git -C "${TOP}" diff --cached --quiet 2>/dev/null; then
  echo "ERRO: árvore de ${TOP} suja — commite ou guarde antes; trocar de branch carregaria trabalho alheio para a branch do update." >&2
  exit 2
fi
_cur="$(git -C "${TOP}" rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ "${_cur}" != "${BR}" ]; then
  if [ "${_has_br}" = 1 ]; then git -C "${TOP}" checkout -q "${BR}" >&2
  else git -C "${TOP}" checkout -q -b "${BR}" "${BASE}" >&2; fi \
    || { echo "ERRO: checkout de '${BR}' falhou em ${TOP}." >&2; exit 2; }
fi
printf '%s\n' "${TOP}"
