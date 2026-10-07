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
#   · exit 0 só com: lint em "Violações HARD : 0" literal (rc lido) julgado sobre o COMMIT (worktree destacada
#     do HEAD, com o env do CI — o mesmo que o pre-push e o runner veem), resíduo ✅, painel estável.
#     Qualquer outra coisa = exit 1, nada enviado (commits locais já feitos FICAM, e a mensagem diz).
#   · NÃO LAVA RESÍDUO (bloqueador B1 do Elenxo, 2026-10-05): a 1ª versão recarimbava o hash de um resíduo
#     caduco mesmo quando o CÓDIGO tinha mudado depois da revisão — código não revisado saía com carimbo de
#     revisado. Agora o resíduo guarda também `reviewed_code_sha256` (o diff SEM as projeções geradas), e o
#     recarimbo só acontece se esse hash não mudou. Resíduo novo (`reviewed_diff_sha256: pendente`) é a
#     declaração de quem revisou: carimba os dois. Código mudado depois da revisão = recusa, "re-revise".
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

# .claude/validation/lint-rules.md (REGRA 39) também é regenerado pelo regen-ssot-projections.sh: fora da
# lista, ficava regenerado na árvore e defasado no commit (bloqueador B2 do Elenxo).
# A lista e o hash de código vêm da FONTE ÚNICA (onion-regen-lib.sh), que o pre-commit também usa.
# shellcheck source=/dev/null
# Carregada do lado DO MOTOR (ops/../.claude/validation), não do repo onde ele roda: a bancada exercita o
# motor num sandbox sem a lib, e a 1ª forma (git rev-parse) quebrou ali — a lib é do motor, não do alvo.
_ONION_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/validation/onion-regen-lib.sh"
[ -r "${_ONION_LIB}" ] || { echo "PR-FINALIZE: lib ausente (${_ONION_LIB}) — não calculo hash de código sem ela" >&2; exit 1; }
. "${_ONION_LIB}"
GENERATED="${ONION_GENERATED}"
RES="docs/evolution/review/$(printf '%s' "${BR}" | tr / -).md"
# Julga SEMPRE no contexto de PR, como o runner (antes do `gh pr create` a guarda do resíduo dizia "fora de
# escopo" e o motor aceitava — maior M3 do Elenxo). Número real se houver; 0 se ainda não há PR.
PRNUM="$(gh pr list --head "${BR}" --state open --json number --jq '.[0].number' 2>/dev/null || true)"
_ci() { GITHUB_EVENT_NAME=pull_request GITHUB_HEAD_REF="${BR}" GITHUB_REF_NAME="${PRNUM:-0}/merge" "$@"; }
_base() {  # a MESMA base da guarda do resíduo: origin/main, com fallback para main local
  git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null
}
_codehash() {  # identidade do CÓDIGO do índice contra a base, SEM o resíduo e SEM as projeções geradas.
  # `git patch-id --stable` (maior 4 do Elenxo 2): a 1ª forma hasheava o diff cru, e a linha `index` e o
  # contexto mudam num rebase LIMPO — o motor dizia "o código mudou" sem ninguém ter mudado nada, e o
  # falso positivo ensinava a lavar à mão. O patch-id é estável sob rebase e muda quando o hunk muda.
  # Exclui SÓ o resíduo deste PR (menor 8): outro arquivo em docs/evolution/review/ é código.
  onion_codehash "${RES}"
}
_field() {  # lê o campo como a guarda lê (só o frontmatter, sem aspas), e sem espaço nas pontas
  awk 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1' "${RES}" \
    | sed -n "s/^$1:[[:space:]]*//p" | head -1 | tr -d '"' | sed 's/[[:space:]]*$//'
}

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
  # o rebase pode falhar SEM deixar estado (ex.: arquivo não rastreado que a main traz) — e a 1ª versão
  # declarava "rebaseado" assim mesmo (maior M2 do Elenxo). A prova é a ancestralidade, não a mensagem.
  git merge-base --is-ancestor origin/main HEAD || die "o rebase NÃO trouxe a origin/main para baixo do HEAD — nada a enviar"
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
  local out sha decl code rcode
  out="$(_ci bash .claude/validation/review-artifact-check.sh . 2>&1)"
  [ -f "${RES}" ] || die "resíduo ausente: ${RES} — escreva a passada adversarial (REGRA 56) e rode de novo"
  # `die` dentro de $(...) não aborta o script (maior 3 do Elenxo 2): o rc da substituição é lido aqui
  code="$(_codehash)" || exit 1
  grep -qE '^[0-9a-f]{64}$' <<< "${code}" || die "hash de código inválido ('${code}') — não carimbo nada"
  rcode="$(_field reviewed_code_sha256)"
  [ -z "${rcode}" ] || grep -qE '^[0-9a-f]{64}$' <<< "${rcode}" || die "reviewed_code_sha256 fora da forma canônica ('${rcode}') — corrija à mão"
  if grep -q '✅' <<< "${out}"; then
    # casando: só garante o hash de código (resíduos antigos não o tinham)
    [ -n "${rcode}" ] || { sed -i "/^reviewed_diff_sha256:/a reviewed_code_sha256: ${code}" "${RES}"; git add -- "${RES}"; }
    return 0
  fi
  sha="$(grep -oE '(atual|diff é) [0-9a-f]{64}' <<< "${out}" | grep -oE '[0-9a-f]{64}' | tail -1)"
  [ -n "${sha}" ] || die "a guarda do resíduo não deu hash nem ✅ no contexto de PR: ${out##*$'\n'}"
  # BLOQUEADOR do Elenxo 2: a forma anterior tratava QUALQUER valor não-hex como "pendente" — um hash
  # entre aspas ou com espaço no fim (4 resíduos do acervo usam aspas) caía no ramo de resíduo novo e o
  # motor recarimbava código não revisado. Só o literal `pendente` declara revisão nova.
  decl="$(_field reviewed_diff_sha256)"
  if [ "${decl}" = pendente ]; then
    :   # resíduo NOVO: é a declaração de quem revisou — carimba os dois
  elif ! grep -qE '^[0-9a-f]{64}$' <<< "${decl}"; then
    die "reviewed_diff_sha256 fora da forma canônica ('${decl}') — escreva 'pendente' (revisão nova) ou o hash de 64 hex"
  elif [ -z "${rcode}" ]; then
    die "resíduo caduco e SEM reviewed_code_sha256 — não dá para provar que só as projeções mudaram; re-revise e ponha 'reviewed_diff_sha256: pendente'"
  elif [ "${rcode}" != "${code}" ]; then
    die "o CÓDIGO mudou depois da revisão (hash de código ${rcode:0:12} → ${code:0:12}) — re-revise e ponha 'reviewed_diff_sha256: pendente'; o motor não recarimba revisão que não houve"
  fi
  sed -i "s/^reviewed_diff_sha256: .*/reviewed_diff_sha256: ${sha}/" "${RES}"
  if grep -q '^reviewed_code_sha256:' "${RES}"; then sed -i "s/^reviewed_code_sha256: .*/reviewed_code_sha256: ${code}/" "${RES}"
  else sed -i "/^reviewed_diff_sha256:/a reviewed_code_sha256: ${code}" "${RES}"; fi
  git add -- "${RES}"
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
# 3. o veredito sobre o COMMIT, não a árvore (bloqueador B2): worktree destacada do HEAD, env do CI
git diff --cached --quiet || die "sobrou conteúdo stageado fora do commit — nada enviado"
_tmp="$(mktemp -d)"; trap 'git worktree remove --force "${_tmp}/wt" >/dev/null 2>&1; rm -rf "${_tmp}"' EXIT
git worktree add -q --detach "${_tmp}/wt" HEAD || die "não montei o HEAD para julgar"
_lint="$(cd "${_tmp}/wt" && _ci env LC_ALL=C ONION_LINT_HARD_FILE="${_tmp}/hard.txt" bash .claude/validation/lint-artifacts.sh 2>&1)"; _rc=$?
_hard="$(grep -oE 'Violações HARD : [0-9]+' <<< "${_lint}" | grep -oE '[0-9]+$' | tail -1)"
if ! { [ "${_rc}" = 0 ] && [ "${_hard}" = 0 ]; }; then
  # as HARD, nomeadas (2026-10-07): antes o motor só dizia "rode o lint", e cada reprovação custava um lint inteiro
  if [ -s "${_tmp}/hard.txt" ]; then echo "PR-FINALIZE: as violações HARD do commit:" >&2; sed 's/^/  /' "${_tmp}/hard.txt" >&2; fi
  die "lint do COMMIT rc=${_rc}, HARD=${_hard:-?} — nada enviado (os commits locais ficam)."
fi
# marcador para o pre-push não relintar o MESMO commit (maior M6: ~11 min por fechamento com lint duplicado)
printf '%s\n' "$(git rev-parse HEAD)" > "$(git rev-parse --git-common-dir)/onion-prefinalize-ok"
echo "PR-FINALIZE: ${BR} pronto — 0 HARD, resíduo casando, projeções estáveis."
# 5. push só por pedido explícito
if [ "${PUSH}" = 1 ]; then
  # --force-with-lease: depois de --rebase o push é reescrita da PRÓPRIA branch; o lease recusa se o
  # remoto andou por outra mão. Nunca é a main: a branch foi recusada lá em cima.
  # --force-if-includes: depois do `git fetch` do --rebase o lease simples fica vazio e apagava commit de
  # outra mão no remoto (maior M1 do Elenxo, reproduzido e curado com este par).
  git push -q --force-with-lease --force-if-includes origin "${BR}" || die "push recusado (o pre-push julga o commit; veja a mensagem dele)"
  echo "PR-FINALIZE: enviado ${BR} @ $(git rev-parse --short HEAD)"
fi
