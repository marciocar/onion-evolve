#!/usr/bin/env bash
# Fecha um PR do core na ordem certa — projeções, commit, resíduo, painel estável, lint 0 HARD, push —
# e RECUSA qualquer passo que não se prove.
#
# ── POR QUE EXISTE (defeito medido, 2026-10-05) ─────────────────────────────────────────
# Num só dia, fechando 5 PRs à mão, errei a MESMA sequência três vezes, com o CI vermelho em dois:
#   1. regenerei backlog/índice de leitura ANTES de stagear o grafo novo — os geradores leem o índice
#      do git, então o grafo não entrou na projeção (REGRAS 62 e 84 no CI);
#   2. regenerei o painel testing-state.md ANTES de recarimbar o resíduo — o painel lê os produtores
#      que o resíduo muda, e ficou defasado no commit final (REGRA 81 no CI de #923 e #925);
#   3. encadeei `lint | grep 'Violações HARD'` com `&&` e enviei com "HARD : 2": o grep ACHAR a linha
#      é sucesso, qualquer que seja o número.
# Nenhum dos três é falta de saber a regra; é a ordem escrita à mão em cada sessão. O cuidado vira
# artefato: um caminho só, que falha fechado.
#
# Uso:
#   bash ops/pr-finalize.sh [--rebase] [--push] [-m "<assunto do commit de projeções>"]
#
#   --rebase  traz a branch para cima da origin/main antes de tudo. Conflito em PROJEÇÃO GERADA é
#             resolvido pela versão do commit e regenerado logo depois; conflito em qualquer outro
#             arquivo = recusa (rebase abortado, nada muda). Motivo medido (2026-10-05): três PRs do
#             mesmo dia mexiam nas mesmas projeções, e o merge do primeiro deixou os outros dois em
#             conflito ou defasados — o CI nem dispara com o PR em conflito.
#
# Contrato:
#   · trabalha sobre o que JÁ ESTÁ STAGEADO: o conteúdo do PR é decisão de quem chama; este script só
#     acrescenta as projeções geradas e o carimbo do resíduo. Nunca faz `git add -A`.
#   · os commits que ele cria respeitam os hooks (sem --no-verify), salvo ONION_FINALIZE_CHECKPOINT=1,
#     que é checkpoint DECLARADO — nesse caso o gate final é o CI.
#   · exit 0 só com: lint em "Violações HARD : 0" literal (rc lido), resíduo ✅ casando com o diff, painel
#     estável em duas regenerações seguidas. Qualquer outra coisa = exit 1, nada enviado.
#   · --push envia a branch atual; nunca a main (o veto de push protege, e este script recusa antes).
set -uo pipefail

die() { echo "PR-FINALIZE: $*" >&2; exit 1; }
PUSH=0; REBASE=0; SUBJ="docs: projeções geradas regeneradas"
while [ $# -gt 0 ]; do
  case "$1" in
    --push) PUSH=1 ;;
    --rebase) REBASE=1 ;;
    -m) shift; SUBJ="${1:?-m exige assunto}" ;;
    *) die "argumento desconhecido: $1" ;;
  esac
  shift
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "fora de um repositório git"
cd "${ROOT}" || die "não entrei em ${ROOT}"
BR="$(git branch --show-current)"
[ -n "${BR}" ] || die "HEAD destacado — finalize numa branch de PR"
case "${BR}" in main|master|develop) die "branch '${BR}' é de integração — PR nasce em branch de trabalho" ;; esac
TRAILER="${ONION_COMMIT_TRAILER:-$(python3 -c 'import json,sys
try: print(json.load(open(".claude/settings.json",encoding="utf-8")).get("attribution",{}).get("commit",""))
except Exception: print("")' 2>/dev/null)}"
VERIFY=(); [ "${ONION_FINALIZE_CHECKPOINT:-0}" = 1 ] && VERIFY=(--no-verify)

GENERATED="docs/onion/inventory.md docs/onion/graph.md docs/onion/testing-state.md docs/onion/testing-inventory.md docs/onion/kg-read-index.tsv docs/onion/federation-console.html docs/backlog.md"

if [ "${REBASE}" = 1 ]; then
  # o --autostash devolveria o conteúdo stageado FORA do índice, e ele sumiria do commit em silêncio
  git diff --cached --quiet || die "--rebase exige índice limpo: commite o conteúdo do PR antes"
  git fetch -q origin || die "fetch falhou"
  if ! git rebase --autostash origin/main >/dev/null 2>&1; then
    for _r in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
      _c="$(git diff --name-only --diff-filter=U)"
      [ -n "${_c}" ] || break
      for _f in ${_c}; do
        case " ${GENERATED} " in
          *" ${_f} "*) git checkout --theirs -- "${_f}" && git add -- "${_f}" ;;
          *) git rebase --abort >/dev/null 2>&1; die "conflito REAL em ${_f} — rebase abortado, nada mudou; resolva à mão" ;;
        esac
      done
      GIT_EDITOR=true git rebase --continue >/dev/null 2>&1 && break
    done
    [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ] \
      && { git rebase --abort >/dev/null 2>&1; die "rebase não terminou — abortado, nada mudou"; }
  fi
  echo "PR-FINALIZE: rebaseado sobre origin/main @ $(git rev-parse --short origin/main)"
fi

_commit() {  # $1 = assunto; commita SÓ se há algo stageado
  git diff --cached --quiet && return 0
  local args=(-q "${VERIFY[@]}" -m "$1")
  [ -n "${TRAILER}" ] && args+=(-m "${TRAILER}")
  git commit "${args[@]}" || die "commit recusado ('$1') — o gate local reprovou; corrija e rode de novo"
}

_regen() {  # regenera TODA projeção gerada com catraca no lint e stageia só elas
  bash .claude/utils/adopt/regen-ssot-projections.sh "${ROOT}" >/dev/null || die "regen-ssot-projections.sh falhou"
  bash .claude/validation/kg-backlog-project.sh --write >/dev/null || die "kg-backlog-project.sh falhou"
  local idx; idx="$(mktemp)"
  bash .claude/validation/kg-trace-resolve.sh . --emit-index > "${idx}" || { rm -f "${idx}"; die "kg-trace-resolve.sh falhou"; }
  [ -s "${idx}" ] || { rm -f "${idx}"; die "índice de leitura saiu VAZIO — não sobrescrevo o vivo"; }
  mv "${idx}" docs/onion/kg-read-index.tsv
  if [ -f .claude/validation/federation-console.sh ]; then
    local con; con="$(mktemp)"
    bash .claude/validation/federation-console.sh > "${con}" || { rm -f "${con}"; die "federation-console.sh falhou"; }
    [ -s "${con}" ] && mv "${con}" docs/onion/federation-console.html || rm -f "${con}"
  fi
  # lista EXPLÍCITA: docs/onion/metrics/*.jsonl churna sozinho e não pertence a PR nenhum
  local f; for f in ${GENERATED}; do
    [ -f "${f}" ] && git add -- "${f}"
  done
}

_restamp() {  # carimba o resíduo e o STAGEIA, sem commitar. Com o índice sujo a guarda calcula o hash
  # SOBRE O ÍNDICE (--cached) e exclui o próprio resíduo — então carimbar ANTES do commit faz o
  # pre-commit já encontrar o resíduo casando. A 1ª versão commitava as projeções e SÓ DEPOIS carimbava:
  # depois de um --rebase o gate do commit de projeções reprovava pela REGRA 56 (PR aberto carrega
  # RESÍDUO da passada adversarial) antes de o carimbo chegar (dogfood no PR #924, 2026-10-05).
  local res="docs/evolution/review/$(printf '%s' "${BR}" | tr / -).md" out sha
  out="$(bash .claude/validation/review-artifact-check.sh . 2>&1)"
  grep -q '✅' <<< "${out}" && return 0
  sha="$(grep -oE '(atual|diff é) [0-9a-f]{64}' <<< "${out}" | grep -oE '[0-9a-f]{64}' | tail -1)"
  [ -n "${sha}" ] || { grep -q 'ISENCAO\|não julgou\|nao julgou\|fora de escopo' <<< "${out}" && return 0; die "a guarda do resíduo não deu hash nem ✅: ${out##*$'\n'}"; }
  [ -f "${res}" ] || die "resíduo ausente: ${res} — escreva a passada adversarial (REGRA 56) e rode de novo"
  sed -i "s/^reviewed_diff_sha256: .*/reviewed_diff_sha256: ${sha}/" "${res}"
  git add -- "${res}"
}

# 1. conteúdo stageado + projeções + resíduo carimbado sobre esse mesmo índice → UM commit
_regen
_restamp
_commit "${SUBJ}"
# 2. o painel lê produtores que o commit muda: regenera até ficar ESTÁVEL (no máximo 3 voltas)
for _i in 1 2 3; do
  _regen
  _restamp
  git diff --cached --quiet && break
  _commit "docs(testing): projeções regeneradas e resíduo recarimbado"
  [ "${_i}" = 3 ] && die "projeções não estabilizaram em 3 voltas — há gerador lendo o próprio resultado"
done
# 4. o veredito: número LIDO, nunca a presença da linha
_lint="$(LC_ALL=C bash .claude/validation/lint-artifacts.sh 2>&1)"; _rc=$?
_hard="$(grep -oE 'Violações HARD : [0-9]+' <<< "${_lint}" | grep -oE '[0-9]+$' | tail -1)"
[ "${_rc}" = 0 ] && [ "${_hard}" = 0 ] || die "lint rc=${_rc}, HARD=${_hard:-?} — nada enviado. $(grep '^VIOLATION' <<< "${_lint}" | head -3)"
_res="$(bash .claude/validation/review-artifact-check.sh . 2>&1)"
grep -q '✅\|ISENCAO\|não julgou\|nao julgou\|fora de escopo' <<< "${_res}" || die "resíduo não casa com o diff — nada enviado"
echo "PR-FINALIZE: ${BR} pronto — 0 HARD, resíduo casando, projeções estáveis."
# 5. push só por pedido explícito
if [ "${PUSH}" = 1 ]; then
  # --force-with-lease: depois de --rebase o push é reescrita da PRÓPRIA branch; o lease recusa se o
  # remoto andou por outra mão. Nunca é a main: a branch foi recusada lá em cima.
  git push -q --force-with-lease origin "${BR}" || die "push recusado (o pre-push julga o commit; veja a mensagem dele)"
  echo "PR-FINALIZE: enviado ${BR} @ $(git rev-parse --short HEAD)"
fi
