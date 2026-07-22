#!/usr/bin/env bash
# =============================================================================
# resolve-production-branch.sh — Resolve a BRANCH DE PRODUÇÃO de um repo Onion
#
# Propósito : Irmão do resolve-integration-branch.sh. Enquanto aquele responde
#             "qual branch os PRs de evolução devem mirar?" (INTEGRAÇÃO), este
#             responde "qual branch é a PRODUÇÃO?" — a base de hotfix, o alvo do
#             release, o valor de `git config gitflow.branch.master`.
#
# Origem de campo (sinal de um adotante regulado, 2026-07-19):
#             o /meta:adopt derivava produção do DEFAULT do repo (origin/HEAD).
#             No repo de um adotante regulado, `origin/HEAD -> origin/develop` (o default do
#             GitHub aponta para a branch de trabalho), então a adoção gravava
#             `gitflow.branch.master=develop` — produção == integração. O veneno
#             é durável: o consumidor resolve-integration-branch.sh LÊ esse
#             config, então o erro se propaga a cada resolução seguinte. O
#             adotante regulado TEM `origin/master` viva (adbebb35d, 2026-07-19) — a
#             produção existia e estava a um `show-ref` de distância; o que
#             faltava era não confiar cegamente no origin/HEAD.
#
# Regras de resolução (e o PORQUÊ de cada uma):
#   (1) CANDIDATOS por existência REAL de ref (`show-ref --verify --quiet`),
#       nomes convencionais `master` e `main`, preferindo `refs/remotes/origin/`
#       a `refs/heads/` — o remoto é a verdade compartilhada; o local pode ser
#       um resquício da máquina. Verificar o ref (em vez de assumir o nome) é o
#       que teria achado a produção de um adotante regulado.
#   (2) origin/HEAD é candidato LEGÍTIMO **somente quando DIFERE** da branch de
#       integração. origin/HEAD não é lixo — é o único sinal que cobre
#       trunk-based com default fora da convenção (`trunk`, `production`,
#       `stable`). Ele só é INVÁLIDO no formato exato do bug: apontando para a
#       própria integração. Banir por completo perderia os casos legítimos;
#       confiar cegamente reproduz o bug. Por isso: condicional.
#   (3) AMBIGUIDADE (mais de um candidato vivo, ex.: `master` E `main`) → vence
#       o de COMMIT MAIS RECENTE (`committerdate`), com AVISO no STDERR. Em repo
#       que renomeou master→main deixando o ref antigo congelado, a ordem fixa
#       "master antes de main" elegeria silenciosamente uma branch MORTA.
#   (4) TRUNK-BASED POR DESIGN não é bug. Se o ÚNICO candidato for igual à
#       integração (greenfield só com `main` — o caso mais comum do /meta:adopt,
#       que é greenfield-first), a resposta correta é esse mesmo nome, SEM
#       alarme. O bug é o outro formato: origin/HEAD == integração ENQUANTO
#       existe um candidato real e distinto — aí a regra (2) descarta o
#       origin/HEAD e o candidato distinto vence naturalmente.
#   (5) NUNCA chutar "main". Sem candidato identificável, o STDOUT sai VAZIO e o
#       STDERR explica como setar à mão. Um palpite aqui vira config durável
#       errada (exatamente o dano do sinal de um adotante regulado) — melhor não gravar nada do
#       que gravar mentira.
#
# Uso       : resolve-production-branch.sh <REPO_DIR> [--integration <branch>]
#             (REPO_DIR default: `.`; --integration omitido → resolve pelo irmão
#             resolve-integration-branch.sh)
#             STDOUT: o nome da branch de produção, ou NADA se não identificar.
#             STDERR: avisos em pt-BR.
#             Exit 0 sempre que a resolução ocorreu sem erro operacional —
#             "não identificou" é resposta, não erro (quem chama decide).
#
# Determinístico, sem LLM. Consumido por /meta:adopt; coberto pelo
# lint-selftest.sh. Viaja para repos adotados via manifesto.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_DIR=""
INTEGRATION=""

while [ $# -gt 0 ]; do
  case "$1" in
    --integration)
      if [ $# -lt 2 ]; then
        printf '❌ resolve-production-branch: --integration exige um nome de branch.\n' >&2
        exit 2
      fi
      INTEGRATION="$2"; shift 2 ;;
    --integration=*)
      INTEGRATION="${1#--integration=}"; shift ;;
    -h|--help)
      printf 'Uso: resolve-production-branch.sh <REPO_DIR> [--integration <branch>]\n' >&2
      exit 0 ;;
    *)
      if [ -z "${REPO_DIR}" ]; then REPO_DIR="$1"; else
        printf '❌ resolve-production-branch: argumento inesperado "%s".\n' "$1" >&2
        exit 2
      fi
      shift ;;
  esac
done

REPO_DIR="${REPO_DIR:-.}"

if ! git -C "${REPO_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
  printf '⚠️  resolve-production-branch: "%s" não é um repositório git — produção não identificada.\n' "${REPO_DIR}" >&2
  exit 0
fi

# Integração: recebida por flag (o chamador já resolveu) ou pelo irmão.
# Só é usada como DISCRIMINANTE (regras 2 e 4) — nunca como resposta por si só.
if [ -z "${INTEGRATION}" ] && [ -x "${SCRIPT_DIR}/resolve-integration-branch.sh" ]; then
  INTEGRATION="$("${SCRIPT_DIR}/resolve-integration-branch.sh" "${REPO_DIR}" 2>/dev/null || true)"
fi

# --- Coleta de candidatos ----------------------------------------------------
# Arrays paralelos: nome curto da branch + ref completo (para ler committerdate).
CAND_NAMES=()
CAND_REFS=()

ref_exists() { git -C "${REPO_DIR}" show-ref --verify --quiet "$1"; }

already_candidate() {
  local n="$1" c
  for c in ${CAND_NAMES[@]+"${CAND_NAMES[@]}"}; do
    [ "${c}" = "${n}" ] && return 0
  done
  return 1
}

# Registra <nome> resolvendo o ref: origin primeiro (verdade compartilhada),
# depois local. Sem ref real, não vira candidato.
add_candidate() {
  local name="$1" ref=""
  [ -z "${name}" ] && return 0
  already_candidate "${name}" && return 0
  if ref_exists "refs/remotes/origin/${name}"; then
    ref="refs/remotes/origin/${name}"
  elif ref_exists "refs/heads/${name}"; then
    ref="refs/heads/${name}"
  else
    return 0
  fi
  CAND_NAMES+=("${name}")
  CAND_REFS+=("${ref}")
}

# (1) Nomes convencionais de produção.
add_candidate "master"
add_candidate "main"

# (2) Default do repo (origin/HEAD): candidato SÓ se diferir da integração.
default_branch="$(git -C "${REPO_DIR}" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
if [ -n "${default_branch:-}" ] && [ "${default_branch}" != "${INTEGRATION}" ]; then
  add_candidate "${default_branch}"
fi

# --- Decisão -----------------------------------------------------------------
# Contagem PORTÁVEL: `${#arr[@]}` com array vazio sob `set -u` é unbound em bash 3.2 (macOS) —
# e este helper VIAJA para repos adotados via manifesto. Conta pelo mesmo idioma
# `${arr[@]+...}` já usado acima, que degrada limpo no array vazio.
count=0
for _c in ${CAND_NAMES[@]+"${CAND_NAMES[@]}"}; do
  count=$((count + 1))
done
unset _c

# (5) Nada identificável → STDOUT vazio + como corrigir à mão. Nunca chutar.
if [ "${count}" -eq 0 ]; then
  {
    printf '⚠️  resolve-production-branch: branch de PRODUÇÃO não identificada em "%s".\n' "${REPO_DIR}"
    printf '    (sem refs master/main — nem em origin/ nem locais — e o default do repo não serve como sinal).\n'
    printf '    Nenhum palpite foi gravado de propósito: config de produção errada é durável e envenena o GitFlow.\n'
    printf '    Sete à mão, na raiz do repo alvo:\n'
    printf '      git config gitflow.branch.master <sua-branch-de-producao>\n'
  } >&2
  exit 0
fi

chosen="${CAND_NAMES[0]}"

# (3) Ambiguidade → vence o commit mais recente, e o desempate é ANUNCIADO.
if [ "${count}" -gt 1 ]; then
  # Antes de comparar datas: se ALGUM candidato vem de origin/, o desempate considera SÓ os remotos.
  # A data sozinha misturaria verdade compartilhada com rascunho local — um refs/heads/main
  # experimental do dev seria mais "recente" que o refs/remotes/origin/master de produção e venceria.
  # Mesma preferência que add_candidate() já aplica por nome (origin primeiro), agora no desempate.
  has_remote=0
  for r in ${CAND_REFS[@]+"${CAND_REFS[@]}"}; do
    case "${r}" in refs/remotes/*) has_remote=1 ;; esac
  done
  best_ts=-1
  i=0
  while [ "${i}" -lt "${count}" ]; do
    if [ "${has_remote}" -eq 1 ]; then
      case "${CAND_REFS[$i]}" in refs/remotes/*) : ;; *) i=$((i + 1)); continue ;; esac
    fi
    ts="$(git -C "${REPO_DIR}" for-each-ref --format='%(committerdate:unix)' "${CAND_REFS[$i]}" 2>/dev/null || true)"
    ts="${ts:-0}"
    if [ "${ts}" -gt "${best_ts}" ]; then
      best_ts="${ts}"
      chosen="${CAND_NAMES[$i]}"
    fi
    i=$((i + 1))
  done
  {
    printf '⚠️  resolve-production-branch: AMBIGUIDADE — mais de uma branch candidata a produção existe (%s).\n' "$(printf '%s ' ${CAND_NAMES[@]+"${CAND_NAMES[@]}"} | sed 's/ $//; s/ /, /g')"
    printf '    Escolhi "%s" por ter o COMMIT MAIS RECENTE (critério anti-branch-morta: em repo que renomeou\n' "${chosen}"
    printf '    master→main, o ref antigo continua existindo, congelado — escolher por ordem fixa elegeria o morto).\n'
    printf '    Se a produção for outra, sete à mão: git config gitflow.branch.master <sua-branch>\n'
  } >&2
fi

# (4) Candidato único igual à integração = trunk-based POR DESIGN (greenfield só
#     com main). Resposta legítima, sem alarme — não confundir com o bug.
printf '%s\n' "${chosen}"
