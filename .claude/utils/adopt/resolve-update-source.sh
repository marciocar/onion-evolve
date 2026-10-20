#!/usr/bin/env bash
# =============================================================================
# resolve-update-source.sh — resolve a FONTE do /meta:adopt --update: de que commit do core o framework
# sai, e de que diretório os helpers do update rodam.
#
# Uso : resolve-update-source.sh <CORE_ROOT> <TARGET> [--source auto|head|origin|<commit-ish>]
#   CORE_ROOT = checkout do core (ou hub) onde a sessão roda · TARGET = repo adotado (tem .onion-version)
#   --source  auto (default): segue SÓ se o HEAD do checkout é a ponta de origin/<integração> e o
#                             manifesto está limpo; qualquer outra situação RECUSA e pede a escolha.
#             head          : o HEAD do checkout, escolhido de propósito (avisa se não está na integração).
#             origin        : a ponta de origin/<integração>, buscada agora (fetch).
#             <commit-ish>  : um commit nomeado (sha, tag, branch) do core.
# stdout: linhas `CHAVE=valor` (shell-quoted) para `eval`, em DOIS tempos (ver adopt.md):
#   UPDATE_SOURCE_ROOT      diretório cujo HEAD É o commit escolhido — vira o SOURCE_ROOT do update
#   UPDATE_SOURCE_SHA       o commit (12) — vira o pin (NOW)
#   UPDATE_SOURCE_MODE      head|origin|ref
#   UPDATE_SOURCE_RELATION  equal|behind|unmerged|no-remote|unmeasured (o commit × origin/<integração>)
#   UPDATE_SOURCE_WORKTREE  worktree destacada criada para a fonte ("" quando é o próprio checkout);
#                           quem chama a remove no fim (`git -C <CORE_ROOT> worktree remove <dir>`)
# rc  : 0 resolvida · 2 uso/precondição · 3 NÃO MEDIDO (fetch falhou onde a relação decide) ·
#       4 RECUSADA (combinação perigosa ou fonte ambígua) — sempre com o próximo passo no stderr.
#
# ══ POR QUE EXISTE (SAC-144, item 3, 2026-10-15) ══════════════════════════════════════════════════
# O --update usava SEMPRE o HEAD do checkout onde a sessão roda, sem dizer e sem deixar escolher. A
# regra vivia em 6 sítios de prosa do adopt.md (o `SOURCE_ROOT=`, o `NOW=HEAD`, o `.env.example` de
# HEAD, o `diff ..HEAD`, o `vendor-branch update` e o re-carimbo do `onion-version.sh`), e nenhum
# media de onde o HEAD vinha. Medido nos carimbos de 22 adotantes locais (126 pares adotante×pin, de
# toda a história do `.onion-version`): 6 pins saíram de um HEAD fora da linha de main do core — 3
# de branch mergeada DEPOIS (o adotante recebeu código ainda não revisado) e 3 que NUNCA chegaram à
# main (rebase/squash reescreveu; o pin só existe enquanto a branch existir no disco de quem rodou,
# e o pin-integrity-check de qualquer outro clone o declara não confiável). Nenhuma porta foi afetada.
#
# O que este script decide, e por quê:
#   · a fonte vira um DIRETÓRIO, não só um sha: os helpers do update leem a ÁRVORE de trabalho do
#     SOURCE_ROOT (settings.json, os próprios scripts, os baselines), não só o HEAD. Por isso fonte
#     ≠ checkout ⇒ worktree DESTACADA no commit, dentro do git-dir comum (nunca rastreável, nunca
#     visível no checkout). É o mesmo princípio do motor de publicação das portas: os scripts que
#     materializam rodam do commit publicado, não do disco de quem chama.
#   · `head` com o manifesto SUJO no checkout é recusado: o transporte sai de HEAD (git archive) e os
#     helpers saem da árvore suja — duas fontes num só update.
#   · alvo PORTA (`kind: door`) só aceita a ponta de origin/<integração>: porta é projeção de
#     origin/main, e um pin fora dela publicaria código não revisado num repo público.
#   · `auto` nunca adivinha: fora do caso inequívoco (HEAD == ponta, manifesto limpo), recusa.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_adopt_update_source_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CORE="${1:-}"; TARGET="${2:-}"; shift 2 2>/dev/null || true
SOURCE="auto"
while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 || { echo "uso: --source exige um valor" >&2; exit 2; } ;;
    --source=*) SOURCE="${1#--source=}"; shift ;;
    *) echo "ERRO: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
done
[ -n "${CORE}" ] && [ -n "${TARGET}" ] && [ -n "${SOURCE}" ] || {
  echo "uso: resolve-update-source.sh <CORE_ROOT> <TARGET> [--source auto|head|origin|<commit-ish>]" >&2; exit 2; }

CORE="$(git -C "${CORE}" rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRO: CORE_ROOT não é repositório git." >&2; exit 2; }
STAMP="${TARGET}/.claude/.onion-version"
[ -f "${STAMP}" ] || { echo "ERRO: ${TARGET} sem .claude/.onion-version — repo não adotado." >&2; exit 2; }
ROLE="$(awk '/^role:/{print $2; exit}' "${STAMP}")"; [ -n "${ROLE}" ] || ROLE=adopted
KIND="$(awk '/^kind:/{print $2; exit}' "${STAMP}")"; [ "${KIND}" = door ] || KIND=adoption

_next() {  # o próximo passo é sempre o mesmo par de saídas explícitas
  echo "  Próximo passo: escolha a fonte e re-rode com" >&2
  echo "    --source origin   (a ponta de origin/${INTEG}, o caminho normal)" >&2
  echo "    --source head     (o HEAD deste checkout, por decisão declarada no relatório do update)" >&2
}

INTEG="$(bash "${HERE}/../../validation/resolve-integration-branch.sh" "${CORE}" 2>/dev/null)"; [ -n "${INTEG}" ] || INTEG=main
HAS_REMOTE=0; git -C "${CORE}" remote get-url origin >/dev/null 2>&1 && HAS_REMOTE=1

# ── a ponta de origin/<integração>, buscada AGORA (a ref local pode ter dias) ─────────────────────
TIP=""; FETCHED=0
if [ "${HAS_REMOTE}" = 1 ]; then
  # refspec EXPLÍCITO: num clone de refspec estreito o `fetch origin main` só grava FETCH_HEAD, e a ref
  # remota ficaria velha (achado do refutador). Sem prompt de credencial: sem TTY, falha em vez de pendurar.
  if GIT_TERMINAL_PROMPT=0 git -C "${CORE}" fetch -q origin "+refs/heads/${INTEG}:refs/remotes/origin/${INTEG}" >/dev/null 2>&1; then FETCHED=1; fi
  TIP="$(git -C "${CORE}" rev-parse --verify -q "refs/remotes/origin/${INTEG}^{commit}" 2>/dev/null)"
fi

# ── o commit escolhido ─────────────────────────────────────────────────────────────────────────────
HEAD_SHA="$(git -C "${CORE}" rev-parse --verify -q HEAD^{commit} 2>/dev/null)" || { echo "ERRO: ${CORE} sem HEAD." >&2; exit 2; }
case "${SOURCE}" in
  auto|head) MODE=head; SHA="${HEAD_SHA}" ;;
  origin)
    MODE=origin
    [ "${HAS_REMOTE}" = 1 ] || { echo "RECUSADO: --source origin, mas ${CORE} não tem remoto 'origin'." >&2; echo "  Próximo passo: --source head (ou um commit nomeado)." >&2; exit 4; }
    if [ "${FETCHED}" != 1 ] || [ -z "${TIP}" ]; then
      echo "NÃO MEDIDO: o fetch de origin/${INTEG} falhou — a ponta do remoto não é conhecida agora." >&2
      echo "  Próximo passo: restabeleça o acesso ao remoto, ou escolha --source head / um commit nomeado." >&2
      exit 3
    fi
    SHA="${TIP}" ;;
  *)
    MODE=ref
    SHA="$(git -C "${CORE}" rev-parse --verify -q "${SOURCE}^{commit}" 2>/dev/null)" \
      || { echo "ERRO: --source '${SOURCE}' não resolve para um commit em ${CORE}." >&2; exit 2; } ;;
esac

# ── a relação do commit com a ponta da integração ─────────────────────────────────────────────────
if [ "${HAS_REMOTE}" = 0 ]; then REL=no-remote
elif [ "${FETCHED}" != 1 ] || [ -z "${TIP}" ]; then REL=unmeasured
elif [ "${SHA}" = "${TIP}" ]; then REL=equal
elif git -C "${CORE}" merge-base --is-ancestor "${SHA}" "${TIP}" 2>/dev/null; then REL=behind
else REL=unmerged; fi

# ── PORTA: só a ponta de origin ────────────────────────────────────────────────────────────────────
if [ "${KIND}" = door ] && [ "${REL}" != equal ]; then
  echo "RECUSADO: o alvo é uma PORTA (kind: door), e a fonte escolhida não é a ponta de origin/${INTEG} (relação: ${REL})." >&2
  echo "  Porta é projeção de origin/${INTEG}; um pin fora dela publicaria código não revisado num repo público." >&2
  [ "${REL}" = unmeasured ] && { echo "  Próximo passo: restabeleça o fetch de origin/${INTEG} e re-rode com --source origin." >&2; exit 3; }
  echo "  Próximo passo: --source origin (ou, na fonte, o /meta:publish da porta (core-only), o caminho normal de uma porta)." >&2
  exit 4
fi

# ── AUTO: só o caso inequívoco ─────────────────────────────────────────────────────────────────────
if [ "${SOURCE}" = auto ]; then
  case "${REL}" in
    equal) ;;
    no-remote)
      echo "RECUSADO: ${CORE} não tem remoto 'origin' — não há ponta para provar que o HEAD é a fonte revisada." >&2
      echo "  Próximo passo: --source head (o HEAD deste checkout, declarado no relatório) ou um commit nomeado." >&2
      exit 4 ;;
    unmeasured)
      echo "NÃO MEDIDO: o fetch de origin/${INTEG} falhou, e sem a ponta do remoto não sei se o HEAD está nela." >&2
      _next; exit 3 ;;
    behind)
      echo "RECUSADO: o HEAD de ${CORE} está ATRÁS de origin/${INTEG} ($(git -C "${CORE}" rev-list --count "${SHA}..${TIP}") commit(s)) — o update levaria um core velho." >&2
      _next; exit 4 ;;
    unmerged)
      echo "RECUSADO: o HEAD de ${CORE} tem $(git -C "${CORE}" rev-list --count "${TIP}..${SHA}") commit(s) fora de origin/${INTEG} (branch ainda não mergeada?)." >&2
      echo "  O adotante receberia código não revisado, e o pin pode sumir se a branch for reescrita (rebase/squash)." >&2
      _next; exit 4 ;;
  esac
fi
if [ "${MODE}" != origin ] && [ "${REL}" = unmerged ]; then
  echo "⚠️  fonte com $(git -C "${CORE}" rev-list --count "${TIP}..${SHA}") commit(s) fora de origin/${INTEG}, por escolha explícita: declare no relatório do update." >&2
fi
if [ "${SOURCE}" != auto ] && [ "${REL}" = behind ]; then
  echo "⚠️  fonte $(git -C "${CORE}" rev-list --count "${SHA}..${TIP}") commit(s) ATRÁS de origin/${INTEG}, por escolha explícita." >&2
fi
[ "${REL}" = unmeasured ] && echo "⚠️  a relação da fonte com origin/${INTEG} NÃO foi medida (fetch falhou)." >&2

# ── o diretório da fonte ───────────────────────────────────────────────────────────────────────────
WT=""; ROOT="${CORE}"
if [ "${SHA}" = "${HEAD_SHA}" ]; then
  # O próprio checkout serve — desde que o manifesto esteja limpo (senão são duas fontes num update).
  # O que conferir é o que os HELPERS leem, não só o que viaja ao alvo: o manifesto do papel do alvo
  # pode cortar os próprios helpers (standalone), e o settings.json da fonte entra pelo merge de hooks.
  # Por isso: manifesto do papel ∪ manifesto adopted ∪ settings.json ∪ .env.example (achado do refutador).
  _mf="$(ONION_KIND="${KIND}" bash "${HERE}/resolve-manifest.sh" "${CORE}" "${ROLE}")" \
    || { echo "ERRO: manifesto do papel '${ROLE}' não resolvido em ${CORE} — não sei o que conferir." >&2; exit 2; }
  _mfa_ad="$(ONION_KIND=adoption bash "${HERE}/resolve-manifest.sh" "${CORE}" adopted 2>/dev/null || true)"
  mapfile -t _mfa < <(printf '%s\n%s\n.claude/settings.json\n.env.example\n' "${_mf}" "${_mfa_ad}" | grep -v '^:(' | grep . | LC_ALL=C sort -u)
  _dirty="$(git -C "${CORE}" status --porcelain --untracked-files=no -- "${_mfa[@]}" 2>/dev/null)"
  if [ -n "${_dirty}" ]; then
    if [ "${MODE}" = head ]; then
      echo "RECUSADO: o manifesto está SUJO em ${CORE} — o transporte sairia de HEAD e os helpers da árvore suja:" >&2
      printf '%s\n' "${_dirty}" | head -5 | sed 's/^/    /' >&2
      echo "  Próximo passo: commite/guarde as mudanças, ou --source origin (fonte numa worktree limpa)." >&2
      exit 4
    fi
    ROOT=""   # origin/ref no mesmo sha mas com árvore suja: vai para a worktree limpa
  fi
fi
if [ -z "${ROOT}" ] || [ "${SHA}" != "${HEAD_SHA}" ]; then
  _gd="$(git -C "${CORE}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || { echo "ERRO: git-dir de ${CORE} não resolvido." >&2; exit 2; }
  WT="${_gd}/onion-update-source/${SHA:0:12}"
  git -C "${CORE}" worktree prune 2>/dev/null || true
  if [ -e "${WT}" ]; then
    # retomada: a mesma worktree, no mesmo commit, limpa — senão não é minha e não a toco.
    if [ "$(git -C "${WT}" rev-parse HEAD 2>/dev/null)" != "${SHA}" ] || [ -n "$(git -C "${WT}" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
      echo "ERRO: ${WT} existe e não é a worktree limpa de ${SHA:0:12} — não sobrescrevo." >&2; exit 2
    fi
  else
    mkdir -p "$(dirname "${WT}")"
    git -C "${CORE}" worktree add -q --detach "${WT}" "${SHA}" >/dev/null 2>&1 \
      || { echo "ERRO: não consegui abrir a worktree da fonte em ${WT}." >&2; exit 2; }
  fi
  ROOT="${WT}"
fi

echo "  fonte do update: ${SHA:0:12} (${MODE}, relação com origin/${INTEG}: ${REL})${WT:+ — worktree destacada ${WT}}" >&2
printf 'UPDATE_SOURCE_ROOT=%q\n' "${ROOT}"
printf 'UPDATE_SOURCE_SHA=%q\n' "${SHA:0:12}"
printf 'UPDATE_SOURCE_MODE=%q\n' "${MODE}"
printf 'UPDATE_SOURCE_RELATION=%q\n' "${REL}"
printf 'UPDATE_SOURCE_WORKTREE=%q\n' "${WT}"
exit 0
