#!/usr/bin/env bash
# =============================================================================
# worktree-hooks-ready.sh — o diretório de hooks que o git usa EXISTE nesta worktree?
#
# POR QUE EXISTE (sinal de campo de um adotante, 2026-11-05, o --update num monorepo com husky v9):
# o husky grava `core.hooksPath=.husky/_` no .git/config, que é COMPARTILHADO entre as worktrees, e gera
# `.husky/_/` no `prepare` do pacote — um diretório IGNORADO pelo git. A worktree irmã do --update nasce
# sem ele (e sem node_modules), o caminho relativo resolve DENTRO dela para o vazio, e o git não roda
# hook nenhum: o gate do Onion encadeado pelo husky fica INERTE, e os gates do próprio adotante também.
# O fluxo `--worktree` do /meta:adopt não previa o caso.
#
# O QUE NÃO FAZ, de propósito: symlink para o `.husky/_` do checkout principal (é o checkout de outra
# sessão, e o farol que abriu esta worktree existe para não tocá-lo), nem `git config core.hooksPath`
# (o config é compartilhado: mudar aqui muda o principal e desliga os gates do husky lá).
#
# USO : worktree-hooks-ready.sh <WORK> [--install]
#   --install = gera o diretório quando dá para fazer LOCAL e sem rede: o binário do gerador já está em
#               <WORK>/node_modules/.bin (husky). Sem ele, declara o passo (instalar dependências usa rede
#               e roda scripts do adotante: é ato do operador, não deste helper).
# RC  : 0 pronto (ou não se aplica: hooksPath ausente ou absoluto, ou WORK é o checkout principal)
#       3 NÃO PRONTO — a última linha diz o passo que falta; o gate desta worktree está inerte até lá
#       4 não é caso de worktree: o diretório falta também no checkout principal (o hook falta de verdade, e
#         quem cuida é o install-onion-githook.sh; o --update o reinstala) — quem chama não deve parar por isto
#       2 uso / não é repo
# Exercitado por lint-selftest.sh (run_worktree_hooks_ready_selftests).
# =============================================================================
set -uo pipefail
W="${1:-}"; INSTALL=0
case "${2:-}" in --install) INSTALL=1 ;; "") ;; *) echo "uso: worktree-hooks-ready.sh <WORK> [--install]" >&2; exit 2 ;; esac
[ -n "${W}" ] || { echo "uso: worktree-hooks-ready.sh <WORK> [--install]" >&2; exit 2; }
TOP="$(git -C "${W}" rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRO: '${W}' não é repositório git." >&2; exit 2; }
MAIN="$(cd "$(git -C "${TOP}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)/.." 2>/dev/null && pwd)" || MAIN=""

HP="$(git -C "${TOP}" config core.hooksPath 2>/dev/null || true)"
if [ -z "${HP}" ]; then echo "hooks prontos: core.hooksPath ausente (o git usa o hooks/ do gitdir comum, o mesmo para toda worktree)."; exit 0; fi
case "${HP}" in /*) echo "hooks prontos: core.hooksPath absoluto (${HP}) — o mesmo diretório para toda worktree."; exit 0 ;; esac
if [ -f "${TOP}/${HP}/pre-commit" ]; then echo "hooks prontos: ${HP}/pre-commit existe em ${TOP}."; exit 0; fi

_in_main=0; [ -n "${MAIN}" ] && [ -f "${MAIN}/${HP}/pre-commit" ] && ! [ "${MAIN}" -ef "${TOP}" ] && _in_main=1
if [ "${_in_main}" -eq 0 ]; then
  echo "NÃO PRONTO: '${HP}/pre-commit' não existe nem aqui nem no checkout principal — não é caso de worktree; o hook falta de verdade (rode o install-onion-githook.sh / verify-adopter-gate.sh)."
  exit 4
fi

# gerador conhecido: o husky (v9 grava `.husky/_`; o v4-8 grava `.husky/_/husky.sh` e o hook em `.husky/`).
case "${HP}" in
  .husky|.husky/*) GEN=husky ;;
  *) GEN="" ;;
esac
if [ -z "${GEN}" ]; then
  echo "NÃO PRONTO: '${HP}' existe no checkout principal (${MAIN}) e não nesta worktree, e o gerador é desconhecido — gere-o aqui pelo procedimento do projeto (sem symlink para o principal)."
  exit 3
fi

if [ "${INSTALL}" -eq 1 ] && [ -x "${TOP}/node_modules/.bin/husky" ]; then
  if ( cd "${TOP}" && node_modules/.bin/husky ) >/dev/null 2>&1 && [ -f "${TOP}/${HP}/pre-commit" ]; then
    echo "hooks prontos: '${HP}' gerado nesta worktree pelo husky local (node_modules/.bin/husky)."
    exit 0
  fi
  echo "NÃO PRONTO: node_modules/.bin/husky rodou e '${HP}/pre-commit' continua ausente em ${TOP}."
  exit 3
fi

# gerenciador de pacotes do ALVO (nunca chute): o campo packageManager, senão o lockfile.
PM=""
_pm_raw="$(grep -oE '"packageManager"[[:space:]]*:[[:space:]]*"[a-z]+' "${TOP}/package.json" 2>/dev/null)" && PM="${_pm_raw##*\"}"
if [ -z "${PM}" ]; then
  if [ -f "${TOP}/bun.lock" ] || [ -f "${TOP}/bun.lockb" ]; then PM=bun
  elif [ -f "${TOP}/pnpm-lock.yaml" ]; then PM=pnpm
  elif [ -f "${TOP}/yarn.lock" ]; then PM=yarn
  elif [ -f "${TOP}/package-lock.json" ]; then PM=npm
  fi
fi
if [ -x "${TOP}/node_modules/.bin/husky" ]; then
  STEP="cd ${TOP} && node_modules/.bin/husky   (ou re-rode este helper com --install)"
elif [ -n "${PM}" ]; then
  STEP="cd ${TOP} && ${PM} install   (o prepare do pacote roda o husky e gera '${HP}')"
else
  STEP="cd ${TOP} && instale as dependências do projeto (o prepare do pacote roda o husky e gera '${HP}')"
fi
echo "NÃO PRONTO: '${HP}' existe no checkout principal (${MAIN}) e não nesta worktree (gerado pelo ${GEN}, ignorado pelo git) — o gate aqui está INERTE. Passo: ${STEP}"
exit 3
