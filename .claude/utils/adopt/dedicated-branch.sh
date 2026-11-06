#!/usr/bin/env bash
# =============================================================================
# dedicated-branch.sh — prepara a BRANCH DEDICADA onde o /meta:adopt --update e o --promote-hub
# escrevem, e imprime o DIRETÓRIO onde trabalhar.
#
# Uso : dedicated-branch.sh <TARGET> <BRANCH> <BASE> [--worktree]
#   --worktree = abre a worktree irmã mesmo sem farol vivo (SAC-144: o operador não tinha como
#   forçá-la, e o checkout do alvo era trocado de branch sempre que nenhuma sessão estava lá)
#   TARGET = repo do alvo · BRANCH = chore/onion-update-<pin> | chore/onion-promote-hub
#   BASE   = de onde a branch nasce (a integração do alvo); ignorada se BRANCH já existe (retomada)
# stdout: o diretório de trabalho — o próprio TARGET, ou uma WORKTREE dele quando há farol vivo.
# rc  : 0 pronto · 2 precondição (não-repo, base inexistente, árvore suja, branch presa noutra worktree)
#       3 worktree aberta, mas sem o diretório de hooks GERADO (`.husky/_`): gate INERTE nela; o stderr diz o
#         passo (worktree-hooks-ready.sh). Re-rodar depois do passo é retomada e confere de novo.
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
# WORKTREE SEM OS HOOKS GERADOS (sinal de campo de um adotante, 2026-11-05): o husky grava core.hooksPath=.husky/_
# no config COMPARTILHADO e gera `.husky/_` no prepare, ignorado pelo git; a worktree irmã nasce sem ele e o git não
# roda hook nenhum, nem o do Onion encadeado. Conferido AQUI, onde a worktree nasce, e não num passo do adopt.md que
# se pula. --install gera só sem rede (husky já em node_modules/.bin); nunca symlink para o checkout principal.
_wt_ready() {
  local _r; _r="$(bash "${HERE}/worktree-hooks-ready.sh" "$1" --install 2>&1)"; local rc=$?
  [ "${rc}" -eq 3 ] || return 0   # 0 pronto · 4 o hook falta também no principal: o --update o reinstala adiante
  echo "${_r}" >&2
  echo "PARE: a worktree ${1} está aberta, mas o gate nela está INERTE — rode o passo acima e re-rode o --update (retomada)." >&2
  exit 3
}
T="${1:-}"; BR="${2:-}"; BASE="${3:-}"; FORCE_WT=0
case "${4:-}" in --worktree) FORCE_WT=1 ;; "") ;; *) echo "ERRO: 4º argumento desconhecido '${4}' (só --worktree)" >&2; exit 2 ;; esac
[ -n "${T}" ] && [ -n "${BR}" ] && [ -n "${BASE}" ] || { echo "uso: dedicated-branch.sh <TARGET> <BRANCH> <BASE> [--worktree]" >&2; exit 2; }

TOP="$(git -C "${T}" rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRO: '${T}' não é repositório git." >&2; exit 2; }
_has_br=0; git -C "${TOP}" rev-parse --verify --quiet "refs/heads/${BR}" >/dev/null && _has_br=1
if [ "${_has_br}" = 0 ] && ! git -C "${TOP}" rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null; then
  echo "ERRO: base '${BASE}' não resolve para um commit em ${TOP}." >&2; exit 2
fi

# ── BASE FRESCA: a branch nasce da ponta MAIS NOVA da integração, nunca da ref local defasada ─────────
# Sinal de campo da curadoria (2026-11-06, PR do update para o pin 4e488f2fef65): a main LOCAL estava atrás da
# origin, a branch nasceu dela, e o head do PR rodava sem as 67 regras de permissions.deny que já estavam na
# origin/main — a curadoria leu "67 → 0" como o update apagando o deny. O update não apagou nada; a base é que
# era velha. Mesma classe que o applied-delta.sh curou em 2026-11-05 (ref local 2 commits atrás).
# Busca a integração no origin e escolhe, entre o nome dado, o upstream dele e origin/<nome>, a ponta que
# DESCENDE das outras. Pontas divergentes (a local tem commit que a remota não tem E vice-versa) = rc 2: não há
# base certa a escolher sem o dono decidir. Só vale para branch NOVA; a retomada segue a branch que existe.
# Sem rede o fetch falha: segue com o que tem, e diz que a remota NÃO foi buscada.
# --no-track nos dois `-b` (passada adversarial deste PR): nascer de origin/<base> faria o git gravar origin/<base>
# como upstream da branch do update, e um `git push` sem argumentos com push.default=upstream iria para a integração.
START="${BASE}"
if [ "${_has_br}" = 0 ] && git -C "${TOP}" show-ref --verify --quiet "refs/heads/${BASE}"; then
  if git -C "${TOP}" remote get-url origin >/dev/null 2>&1; then
    GIT_TERMINAL_PROMPT=0 git -C "${TOP}" fetch -q origin "+refs/heads/${BASE}:refs/remotes/origin/${BASE}" >&2 \
      || echo "  AVISO: não consegui buscar origin/${BASE} — a base é a melhor ref LOCAL, remota NÃO buscada." >&2
  fi
  _cands=("${BASE}")
  _up="$(git -C "${TOP}" rev-parse --abbrev-ref --symbolic-full-name "${BASE}@{upstream}" 2>/dev/null)" && [ -n "${_up}" ] && _cands+=("${_up}")
  git -C "${TOP}" rev-parse --verify --quiet "refs/remotes/origin/${BASE}^{commit}" >/dev/null && _cands+=("origin/${BASE}")
  for _c in "${_cands[@]}"; do
    [ "${_c}" = "${START}" ] && continue
    _a="$(git -C "${TOP}" rev-parse "${START}^{commit}")"; _b="$(git -C "${TOP}" rev-parse "${_c}^{commit}")"
    [ "${_a}" = "${_b}" ] && continue
    if git -C "${TOP}" merge-base --is-ancestor "${_a}" "${_b}"; then START="${_c}"
    elif ! git -C "${TOP}" merge-base --is-ancestor "${_b}" "${_a}"; then
      echo "ERRO: '${START}' e '${_c}' DIVERGEM em ${TOP} — não escolho a base do update por você. Integre as duas (pull/push) e re-rode." >&2
      exit 2
    fi
  done
  [ "${START}" != "${BASE}" ] && echo "  base fresca: '${BASE}' local estava atrás; a branch nasce de ${START} ($(git -C "${TOP}" rev-parse --short=12 "${START}"))." >&2
fi

# ── RETOMADA: a branch já está aberta numa worktree? Então é lá, com ou sem farol agora ─────────────
# Passada adversarial do PR da F1 (D1): 1ª rodada com farol vivo cria a worktree irmã; a outra sessão
# sai; a retomada (shell novo, WORK não persiste) ia pelo caminho "sem farol", tentava `checkout` da
# branch no alvo e o git recusava (a branch está em uso pela worktree) — --update irretomável, rc=2.
git -C "${TOP}" worktree prune 2>/dev/null || true   # worktree com diretório apagado não é retomada
_existing="$(git -C "${TOP}" worktree list --porcelain | awk -v b="refs/heads/${BR}" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w; exit}')"
if [ -n "${_existing}" ]; then
  [ "${_existing}" != "${TOP}" ] && echo "  retomada: '${BR}' já está aberta na worktree ${_existing} — trabalho lá." >&2
  [ "${_existing}" != "${TOP}" ] && _wt_ready "${_existing}"
  printf '%s\n' "${_existing}"
  exit 0
fi

# ── farol: há OUTRA sessão viva no alvo? ─────────────────────────────────────────────────────────
BEACON="${HERE}/../../validation/session-beacon.sh"
LIVE=1
if [ "${FORCE_WT}" = 1 ]; then
  echo "  --worktree: worktree irmã por escolha do operador (sem consultar o farol)." >&2
elif [ -f "${BEACON}" ]; then
  bash "${BEACON}" check "${TOP}" >/dev/null 2>&1 && LIVE=0
else
  echo "  (sem session-beacon.sh: não há como provar que o alvo está livre — uso worktree)" >&2
fi

if [ "${LIVE}" = 1 ]; then
  WT="$(dirname "${TOP}")/$(basename "${TOP}")-${BR//\//-}"
  if grep -qxF "worktree ${WT}" <<< "$(git -C "${TOP}" worktree list --porcelain)"; then
    _cur="$(git -C "${WT}" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    [ "${_cur}" = "${BR}" ] || { echo "ERRO: a worktree ${WT} existe mas está em '${_cur}', não em '${BR}'." >&2; exit 2; }
  elif [ -e "${WT}" ]; then
    echo "ERRO: ${WT} existe e não é worktree deste repo — não sobrescrevo." >&2; exit 2
  elif [ "${_has_br}" = 1 ]; then
    git -C "${TOP}" worktree add -q "${WT}" "${BR}" >&2 || { echo "ERRO: não consegui abrir a worktree de '${BR}' (presa noutra worktree?)." >&2; exit 2; }
  else
    git -C "${TOP}" worktree add -q --no-track -b "${BR}" "${WT}" "${START}" >&2 || { echo "ERRO: não consegui criar a worktree de '${BR}'." >&2; exit 2; }
  fi
  [ "${FORCE_WT}" = 1 ] || echo "  farol vivo em ${TOP}: trabalho na worktree ${WT} (branch ${BR}); o checkout do alvo fica intocado." >&2
  _wt_ready "${WT}"
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
  else git -C "${TOP}" checkout -q --no-track -b "${BR}" "${START}" >&2; fi \
    || { echo "ERRO: checkout de '${BR}' falhou em ${TOP}." >&2; exit 2; }
fi
printf '%s\n' "${TOP}"
