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
#   bash ops/pr-finalize.sh [--rebase] [--push] [--check] [-m "<assunto do commit de projeções>"]
#
#   --check   faz o pré-voo inteiro numa worktree DESCARTÁVEL e diz o que faria — projeções que
#             mudariam, o carimbo do resíduo (ou a recusa), as violações HARD do commit — sem escrever
#             nada no repo: nem árvore, nem índice, nem resíduo, nem ref, nem push. Saída 0 = a rodada
#             real passaria; 1 = recusaria, com o motivo.
#
#   --rebase  traz a branch para cima da origin/main antes de tudo. Conflito em PROJEÇÃO GERADA é
#             resolvido pela versão do commit e regenerado logo depois (até a F4 das portas, conflito em
#             plugins/<v>/ era remontado das fontes; o `plugins/` saiu do core); conflito em qualquer outro
#             arquivo = recusa (rebase abortado, nada muda). Motivo medido (2026-10-05): três PRs do
#             mesmo dia mexiam nas mesmas projeções, e o merge do primeiro deixou os outros dois em
#             conflito ou defasados — o CI nem dispara com o PR em conflito.
#
# Contrato:
#   · trabalha sobre o que JÁ ESTÁ STAGEADO: o conteúdo do PR é decisão de quem chama; este script só
#     acrescenta as projeções geradas e o carimbo do resíduo. Nunca faz `git add -A`.
#   · os commits que ele cria respeitam os hooks (sem --no-verify), salvo ONION_FINALIZE_CHECKPOINT=1,
#     que é checkpoint DECLARADO — nesse caso o gate final é o CI. EXCEÇÃO (2026-10-08, SAC-66): o commit
#     que carrega SÓ projeção gerada e o resíduo deste PR sai sem o hook. O hook rodaria o lint inteiro
#     sobre a árvore, e o passo 3 abaixo roda o MESMO lint sobre o MESMO commit, no ambiente do CI: eram
#     duas passadas por rodada (medido na leva de 2026-10-07/08). O commit que traz conteúdo do PR segue
#     pelo hook. Não é fail-open: nada é enviado sem o lint do commit dar 0 HARD.
#   · O CARIMBO SÓ FICA EM RODADA QUE TERMINA (2026-10-08, SAC-66): uma rodada que falha devolve o resíduo
#     ao estado em que o encontrou (arquivo e índice). Antes, a falha deixava o resíduo carimbado, a rodada
#     seguinte recusava "o código mudou depois da revisão", e a limpeza era à mão (3 vezes num dia).
#   · exit 0 só com: lint em "Violações HARD : 0" literal (rc lido) julgado sobre o COMMIT (worktree destacada
#     do HEAD, com o env do CI — o mesmo que o pre-push e o runner veem), resíduo ✅, painel estável.
#     Qualquer outra coisa = exit 1, nada enviado (commits locais já feitos FICAM, e a mensagem diz).
#   · NÃO LAVA RESÍDUO (bloqueador B1 do Elenxo, 2026-10-05): a 1ª versão recarimbava o hash de um resíduo
#     caduco mesmo quando o CÓDIGO tinha mudado depois da revisão — código não revisado saía com carimbo de
#     revisado. Agora o resíduo guarda também `reviewed_code_sha256` (o diff SEM as projeções geradas), e o
#     recarimbo só acontece se esse hash não mudou. Resíduo novo (`reviewed_diff_sha256: pendente`) é a
#     declaração de quem revisou: carimba os dois. Código mudado depois da revisão = recusa, "re-revise".
#   · --push envia a branch atual; nunca a main (o veto de push protege, e este script recusa antes).
#   · NUNCA RODA A BANCADA COMPLETA (D_BANCADA_SEMAFORO_DA_MAQUINA_SEM_COMPLETA_LOCAL, 2026-10-13): a bancada
#     só roda em dois pontos, e os dois são estreitos. (1) O hook do commit de conteúdo: o pre-commit roda a
#     faixa local (`--affected-staged --local`), e o diff na infra da bancada NÃO compra mais a completa. (2) O
#     pré-voo (sempre, desde 2026-10-15): as famílias alteradas. A completa é do CI. Opt-in local: ONION_SELFTEST_FULL=1, que
#     vale para os dois pontos (o pré-voo a traduz, porque o `env -i` a apagaria).
set -uo pipefail

die() { echo "PR-FINALIZE: $*" >&2; exit 1; }
PUSH=0; REBASE=0; CHECK=0; SUBJ="docs: projeções geradas regeneradas"
while [ $# -gt 0 ]; do
  case "$1" in
    --push) PUSH=1 ;;
    --check) CHECK=1 ;;
    --rebase) REBASE=1 ;;
    -m) shift; SUBJ="${1:?-m exige assunto}" ;;
    *) die "argumento desconhecido: $1" ;;
  esac
  shift
done

[ "${CHECK}" = 1 ] && { [ "${PUSH}" = 1 ] || [ "${REBASE}" = 1 ]; } && die "--check não escreve nada: não combina com --push nem --rebase"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "fora de um repositório git"
cd "${ROOT}" || die "não entrei em ${ROOT}"
# rebase de OUTRA MÃO em curso (SAC-136, 2026-10-14): não é nosso, e o motor não toca nele — nem para
# abortar. A recusa vem ANTES do trap da limpeza, então o abort do _cleanup nunca o alcança.
{ [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; } \
  && die "há um rebase em curso nesta worktree, começado antes de mim — não mexo nele; termine-o (--continue) ou aborte-o à mão"
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

# ── LIMPEZA ÚNICA E O CARIMBO TRANSACIONAL (SAC-66, 2026-10-08) ─────────────────────────────
# Um trap só: antes havia um `trap … EXIT` no passo 3, e qualquer outro trap o sobrescreveria em silêncio.
_WTS=(); _DIRS=(); _DONE=0; _RES_SNAP=""; _RES_IDX=""; _RES_HAD_IDX=0; _OWN_REBASE=0
_snap_res() {  # o estado do resíduo ANTES de a rodada mexer nele: arquivo e entrada do índice
  [ -f "${ROOT}/${RES}" ] || return 0
  _RES_SNAP="$(mktemp)"; _DIRS+=("${_RES_SNAP}")
  cp "${ROOT}/${RES}" "${_RES_SNAP}"
  if _RES_IDX="$(git -C "${ROOT}" rev-parse -q --verify ":${RES}" 2>/dev/null)"; then _RES_HAD_IDX=1; else _RES_IDX=""; fi
}
_restore_res() {  # rodada que NÃO terminou não deixa carimbo: devolve arquivo e índice como estavam
  [ "${_DONE}" = 1 ] && return 0
  [ -n "${_RES_SNAP}" ] && [ -f "${_RES_SNAP}" ] || return 0
  local cur; cur="$(git -C "${ROOT}" rev-parse -q --verify ":${RES}" 2>/dev/null || true)"
  if cmp -s "${_RES_SNAP}" "${ROOT}/${RES}" && [ "${cur}" = "${_RES_IDX}" ]; then return 0; fi
  cp "${_RES_SNAP}" "${ROOT}/${RES}"
  if [ "${_RES_HAD_IDX}" = 1 ]; then git -C "${ROOT}" update-index --cacheinfo "100644,${_RES_IDX},${RES}"
  else git -C "${ROOT}" reset -q -- "${RES}" >/dev/null 2>&1 || true; fi
  echo "PR-FINALIZE: a rodada não terminou — o resíduo voltou ao estado em que foi encontrado (o carimbo só fica em rodada que termina)" >&2
}
_abort_own_rebase() {  # SAC-136: morto no MEIO do rebase que ELE começou, o motor desfaz o rebase
  # A 2.1.300 do Claude Code mata o comando de fundo 1,5 s depois da saída da sessão (medido pelo juiz do
  # radar E3 r11). O SIGTERM roda este trap, mas antes ele não abortava o `git rebase` do --rebase: a
  # worktree ficava em rebase e a rodada seguinte morria no pré-check do índice. Só o rebase PRÓPRIO
  # (_OWN_REBASE, ligado ao começar e desligado quando ele termina); o alheio é recusado lá em cima.
  [ "${_OWN_REBASE}" = 1 ] || return 0
  _OWN_REBASE=0
  # --path-format=absolute: o --git-path sai relativo ao -C, e o `[ -d ]` o leria contra o cwd do trap
  { [ -d "$(git -C "${ROOT}" rev-parse --path-format=absolute --git-path rebase-merge)" ] \
    || [ -d "$(git -C "${ROOT}" rev-parse --path-format=absolute --git-path rebase-apply)" ]; } || return 0
  if git -C "${ROOT}" rebase --abort >/dev/null 2>&1; then
    echo "PR-FINALIZE: a rodada morreu no meio do rebase — rebase abortado, a branch voltou ao HEAD de antes" >&2
  else
    echo "PR-FINALIZE: a rodada morreu no meio do rebase e o abort FALHOU — rode 'git rebase --abort' à mão" >&2
  fi
}
_cleanup() {
  _abort_own_rebase
  _restore_res
  local w; for w in "${_WTS[@]}"; do git -C "${ROOT}" worktree remove --force "${w}" >/dev/null 2>&1; done
  local x; for x in "${_DIRS[@]}"; do rm -rf "${x}"; done
}
trap _cleanup EXIT

if [ "${REBASE}" = 1 ]; then
  # o --autostash devolveria o conteúdo stageado FORA do índice, e ele sumiria do commit em silêncio
  git diff --cached --quiet || die "--rebase exige índice limpo: commite o conteúdo do PR antes"
  git fetch -q origin || die "fetch falhou"
  _OWN_REBASE=1   # daqui até o fim do bloco o rebase é NOSSO: morte no meio = o _cleanup o aborta
  # DRIVER DAS FAMÍLIAS (SAC-146, 2026-10-15): o .gitattributes liga a bancada a `merge=onion-selftest-families`,
  # e a config do driver vai por `git -c` (nada persiste na config do repo). Ele resolve SÓ o conflito de
  # famílias acrescentadas lado a lado (base vazia, blocos inteiros, sem nome repetido, bash -n); qualquer
  # outro conflito do arquivo continua conflito e cai na recusa abaixo. Sem o driver no disco, merge de texto.
  _RB_CFG=(); _RB_LOG="$(mktemp)"; _DIRS+=("${_RB_LOG}")
  # Driver que não consegue rodar (python3 ausente) deixa o arquivo como o da main, SEM marcadores: só liga
  # com o interpretador presente, e o caminho vai entre aspas simples (raiz com espaço).
  [ -f "${ROOT}/ops/merge-drivers/selftest-families.py" ] && command -v python3 >/dev/null 2>&1 \
    && _RB_CFG=(-c merge.onion-selftest-families.name=onion-selftest-families \
    -c "merge.onion-selftest-families.driver=python3 -I '${ROOT}/ops/merge-drivers/selftest-families.py' %O %A %B %L %P")
  if ! git "${_RB_CFG[@]}" rebase --autostash origin/main >/dev/null 2>"${_RB_LOG}"; then
    for _r in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
      _c="$(git diff --name-only --diff-filter=U)"
      [ -n "${_c}" ] || break
      for _f in ${_c}; do
        if ! onion_is_generated "${_f}"; then
          sed -n 's/^.*SELFTEST-FAMILIES: /PR-FINALIZE: /p' "${_RB_LOG}" >&2   # o PORQUÊ do driver não resolver
          git rebase --abort >/dev/null 2>&1; die "conflito REAL em ${_f} — rebase abortado, nada mudou; resolva à mão"
        fi
        # projeção gerada em conflito: o lado da main vence aqui e a regeneração adiante a refaz.
        # (Até a F4 das portas, 2026-10-10, plugins/<vertical> tinha ramo próprio, remontado das fontes
        # mescladas — SAC-67. O `plugins/` saiu do core e o ramo saiu com ele.)
        git checkout --theirs -- "${_f}" && git add -- "${_f}"
        # o ops/pr-merge-verified.sh (core-only) lê esta linha para dizer no PR a CAUSA do auto-rebase (H5)
        echo "PR-FINALIZE: conflito de projeção resolvido em ${_f} (a regeneração refaz)"
      done
      GIT_EDITOR=true git "${_RB_CFG[@]}" rebase --continue >/dev/null 2>>"${_RB_LOG}" && break
    done
    [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ] \
      && { git rebase --abort >/dev/null 2>&1; die "rebase não terminou — abortado, nada mudou"; }
  fi
  # o rebase pode falhar SEM deixar estado (ex.: arquivo não rastreado que a main traz) — e a 1ª versão
  # declarava "rebaseado" assim mesmo (maior M2 do Elenxo). A prova é a ancestralidade, não a mensagem.
  # o que o driver resolveu é DITO (uma linha por conflito): o código combinado é novo, e o hash de código
  # do resíduo muda pelo contexto — a re-revisão declarada é a do caminho de sempre (o _restamp abaixo para)
  sed -n 's/^.*SELFTEST-FAMILIES: /PR-FINALIZE: /p' "${_RB_LOG}"
  _OWN_REBASE=0   # o rebase terminou (ou não deixou estado): nada mais a abortar
  git merge-base --is-ancestor origin/main HEAD || die "o rebase NÃO trouxe a origin/main para baixo do HEAD — nada a enviar"
  echo "PR-FINALIZE: rebaseado sobre origin/main @ $(git rev-parse --short origin/main)"
fi

_only_generated() {  # o índice só traz projeção gerada e o resíduo deste PR?
  local f
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    [ "${f}" = "${RES}" ] && continue
    onion_is_generated "${f}" || return 1
  done < <(git diff --cached --name-only)
  return 0
}

_commit() {  # $1 = assunto; commita SÓ se há algo stageado
  git diff --cached --quiet && return 0
  local v=("${VERIFY[@]}") why=""
  # SÓ projeção + resíduo: o hook seria a 2ª passada do mesmo lint que o passo 3 faz sobre ESTE commit,
  # no ambiente do CI, antes de qualquer envio. Conteúdo do PR no índice → o hook roda, como sempre.
  if [ "${#v[@]}" = 0 ] && _only_generated; then
    v=(--no-verify); why=" — só projeção e resíduo: o lint do commit (passo 3) é o gate, uma passada em vez de duas"
  fi
  local args=(-q "${v[@]}" -m "$1")
  [ -n "${TRAILER}" ] && args+=(-m "${TRAILER}")
  local log hf; log="$(mktemp)"; hf="$(mktemp)"; _DIRS+=("${log}" "${hf}")
  if ! ONION_LINT_HARD_FILE="${hf}" git commit "${args[@]}" > "${log}" 2>&1; then
    cat "${log}" >&2
    # o QUE reprovou, por último (SAC-66): antes saía só "o gate local reprovou", e saber a regra custava
    # rodar o lint inteiro de novo
    echo "PR-FINALIZE: o que reprovou o commit:" >&2
    if [ -s "${hf}" ]; then sed 's/^/  /' "${hf}" >&2
    else grep -E 'VIOLATION|❌|✗|ABORTOU|MORREU' "${log}" | tail -15 | sed 's/^/  /' >&2; fi
    die "commit recusado ('$1') — o gate local reprovou; corrija e rode de novo"
  fi
  cat "${log}"
  [ -n "${why}" ] && echo "PR-FINALIZE: commit '$1' sem o hook${why}"
  return 0
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
  # catálogo da raiz (REGRA 76 (marketplace.json da raiz aponta o repo PÚBLICO e é projeção dos manifestos)): projeção dos manifestos desde a F4 das portas (2026-10-10). O --write já
  # escreve por temp+mv (o gerador lê o topo do próprio arquivo).
  if [ -f .claude/validation/marketplace-root-check.sh ] && [ -f .claude-plugin/marketplace.json ]; then
    bash .claude/validation/marketplace-root-check.sh "${ROOT}" --write >/dev/null || die "marketplace-root-check.sh --write falhou"
  fi
  # mapa da federação (REGRA 38): projeção do members.yaml que o motor não regenerava (SAC-67)
  if [ -f .claude/validation/graph.sh ] && [ -f docs/evolution/federation/members.yaml ]; then
    local map; map="$(mktemp)"
    bash .claude/validation/graph.sh --map > "${map}" 2>/dev/null && [ -s "${map}" ] && mv "${map}" docs/onion/federation-map.md || rm -f "${map}"
  fi
  # lista EXPLÍCITA: docs/onion/metrics/*.jsonl churna sozinho e não pertence a PR nenhum
  local f; for f in ${GENERATED}; do
    if [ -f "${f}" ]; then git add -- "${f}" || return 1; fi
  done
  # o rc da função é o do laço, e o `[ -f ]` do ÚLTIMO item ausente devolvia 1 — com federation-map.md no
  # fim da lista, um repo sem ele recusava a rodada inteira (pego pela bancada do --check, SAC-67).
  return 0
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

# 0a. O ESQUEMA DO RESÍDUO, antes de qualquer passo caro (SAC-142, decisão do maestro de 2026-10-15). Medido de
#     10-05 a 10-15: 12 resíduos nasceram fora do esquema, todos achados só no FIM desta rodada; desde o pré-voo
#     sempre (SAC-141) cada um passou a custar o pré-voo inteiro (3 min 51 s no caso de 2026-10-15). Sem resíduo:
#     o esqueleto sai do PRÓPRIO validador (`--skeleton`, as mesmas constantes que julgam o PR) e a rodada para
#     para ele ser preenchido. Com resíduo: `--schema` confere o frontmatter em milissegundos.
if [ -f .claude/validation/review-artifact-check.sh ]; then
  if [ ! -f "${RES}" ]; then
    [ "${CHECK}" = 1 ] && die "resíduo ausente: ${RES} — gere com 'bash .claude/validation/review-artifact-check.sh --skeleton > ${RES}' e preencha (o --check não escreve)"
    mkdir -p "$(dirname "${RES}")" && bash .claude/validation/review-artifact-check.sh --skeleton "${BR}" > "${RES}" \
      || die "não consegui gerar o esqueleto do resíduo em ${RES}"
    die "resíduo ausente: o esqueleto foi gerado em ${RES} pelo validador. Preencha a passada adversarial (REGRA 56) e rode de novo."
  fi
  _sch="$(bash .claude/validation/review-artifact-check.sh --schema "${RES}" 2>&1)" \
    || { printf '%s\n' "${_sch}" >&2; die "o resíduo está fora do esquema — corrija e rode de novo (nada rodou ainda: nem pré-voo, nem lint)"; }
fi

# 0. PRÉ-VOO (2026-10-07; SEMPRE desde 2026-10-15, SAC-141, D_PRE_VOO_SEMPRE_E_SOMBRA): roda as famílias que o
#    diff ALTEROU por dentro (+ a catraca estática `| grep -q`) num ambiente que IMITA o runner — o corpo vive em
#    ops/testing/preflight-run.sh, que o pre-push também chama. Até 2026-10-15 ele só rodava sob
#    ONION_FINALIZE_CHECKPOINT=1, e a sessão passou a variável em 21% dos fechamentos (89 de 431, medido): 9 de 29
#    reprovações do CI de 10-07 a 10-14 eram casos que ele pegaria. Cache pela árvore do índice: a re-rodada com o
#    mesmo conteúdo pula e diz. Não substitui o CI: corta as quebras baratas antes de pagar o run.
#    A SOMBRA (ops/testing/preflight-shadow.sh) roda em paralelo e grava, fora do índice, quantas famílias o CI vai
#    rodar além das do pré-voo; nunca muda o rc. Escape declarado: ONION_FINALIZE_SKIP_PREFLIGHT=1 (diz que pulou).
if [ "${ONION_FINALIZE_SKIP_PREFLIGHT:-0}" = 1 ]; then
  echo "PR-FINALIZE: pré-voo PULADO por ONION_FINALIZE_SKIP_PREFLIGHT=1 (escape declarado; o CI é o único juiz da bancada)"
elif [ -f ops/testing/preflight-run.sh ]; then
  _pf_fams="$(bash ops/testing/preflight-run.sh --families-only)" || die "pré-voo: não descobri as famílias alteradas"
  _pf_shadow=""
  if [ "${CHECK}" != 1 ] && [ -f ops/testing/preflight-shadow.sh ]; then
    _pf_shadow="$(mktemp)"; bash ops/testing/preflight-shadow.sh record "${_pf_fams}" > "${_pf_shadow}" 2>&1 & _pf_spid=$!
  fi
  bash ops/testing/preflight-run.sh 2>&1 | sed 's/^/PR-FINALIZE: /'; _pf_rc="${PIPESTATUS[0]}"
  if [ -n "${_pf_shadow}" ]; then
    wait "${_pf_spid}" 2>/dev/null; sed 's/^/PR-FINALIZE: /' "${_pf_shadow}"; rm -f "${_pf_shadow}"
  fi
  [ "${_pf_rc}" = 0 ] || die "pré-voo reprovou no ambiente do runner (rc=${_pf_rc}) — nada commitado; o CI quebraria igual"
fi

_lint_in() {  # <worktree com o commit a julgar> <arquivo de HARD> → _rc e _hard; o env do CI, como o runner
  _lint="$(cd "$1" && _ci env LC_ALL=C ONION_LINT_HARD_FILE="$2" bash .claude/validation/lint-artifacts.sh 2>&1)"; _rc=$?
  _hard="$(grep -oE 'Violações HARD : [0-9]+' <<< "${_lint}" | grep -oE '[0-9]+$' | tail -1)"
  [ "${_rc}" = 0 ] && [ "${_hard}" = 0 ]
}

# ── --check: a rodada inteira numa worktree DESCARTÁVEL, montada do ÍNDICE (SAC-66, 2026-10-08) ──────
# O que se quer saber antes de escrever: o que o regen mudaria, se o resíduo carimba ou é recusado, e se o
# commit resultante passa no lint. Tudo isso roda na cópia; o repo vivo (árvore, índice, resíduo, refs)
# não é tocado. Ficam só objetos soltos no banco do git, que o gc recolhe — declarado.
if [ "${CHECK}" = 1 ]; then
  _ck="$(mktemp -d)"; _DIRS+=("${_ck}")
  _t0="$(git write-tree)" || die "--check: não li o índice como árvore"
  _c0="$(git commit-tree "${_t0}" -p HEAD -m "pr-finalize --check")" || die "--check: não montei o índice como commit"
  git worktree add -q --detach "${_ck}/wt" "${_c0}" >/dev/null 2>&1 || die "--check: não montei a worktree descartável"
  _WTS+=("${_ck}/wt")
  _ckrc=0
  ( cd "${_ck}/wt" && ROOT="${_ck}/wt" && _regen && _restamp ) > "${_ck}/out" 2>&1 || _ckrc=$?
  echo "PR-FINALIZE --check: o que a rodada faria (nada foi escrito no repo)"
  _proj="$(git -C "${_ck}/wt" diff --cached --name-only -- ${GENERATED} | tr '\n' ' ')"
  echo "  projeções que o regen mudaria: ${_proj:-nenhuma}"
  if [ "${_ckrc}" != 0 ]; then
    echo "  resíduo: a rodada RECUSARIA —"; grep 'PR-FINALIZE:' "${_ck}/out" | tail -3 | sed 's/^/    /'
    exit 1
  fi
  if git -C "${_ck}/wt" diff --cached --quiet -- "${RES}"; then echo "  resíduo: já casa, nada a carimbar"
  else echo "  resíduo: carimbaria —"; git -C "${_ck}/wt" diff --cached -- "${RES}" | grep -E '^\+reviewed_' | sed 's/^+/    /'; fi
  git -C "${_ck}/wt" -c user.name=pr-finalize -c user.email=check@pr-finalize commit -q --no-verify -m "pr-finalize --check" >/dev/null 2>&1 || true
  if _lint_in "${_ck}/wt" "${_ck}/hard.txt"; then
    if (cd "${_ck}/wt" && bash ops/kg-gate-ci.sh) > "${_ck}/kggate.txt" 2>&1; then
      echo "  lint do commit resultante: 0 HARD · contrato KG-SSOT verde — a rodada real passaria"; exit 0
    fi
    echo "  lint 0 HARD, mas o contrato KG-SSOT reprovaria o commit (o mesmo passo do CI):"
    grep -E '^✗|ausente|Error|erro' "${_ck}/kggate.txt" | grep -v '(herdado)' | head -20 | sed 's/^/    /'
    exit 1
  fi
  echo "  lint do commit resultante: rc=${_rc}, HARD=${_hard:-?} — a rodada real recusaria:"
  [ -s "${_ck}/hard.txt" ] && sed 's/^/    /' "${_ck}/hard.txt"
  exit 1
fi

# 1. conteúdo stageado + projeções + resíduo carimbado sobre esse mesmo índice → UM commit
_snap_res
_regen
_restamp
_commit "${SUBJ}"
# 2. projeção que lê produtores que o commit muda: regenera até ficar ESTÁVEL (no máximo 3 voltas).
#    Desde 2026-10-13 o testing-state.md não lê mais os contadores do resíduo (passo A de
#    D_MERGE_PROCESS_ONION_2026_10: eles saem só em testing-state.sh --live); segue na lista e é regenerado
#    aqui como qualquer projeção, só que não muda mais por PR. A volta continua valendo para as demais.
for _i in 1 2 3; do
  _regen
  _restamp
  git diff --cached --quiet && break
  _commit "docs(testing): projeções regeneradas e resíduo recarimbado"
  [ "${_i}" = 3 ] && die "projeções não estabilizaram em 3 voltas — há gerador lendo o próprio resultado"
done
# 3. o veredito sobre o COMMIT, não a árvore (bloqueador B2): worktree destacada do HEAD, env do CI
git diff --cached --quiet || die "sobrou conteúdo stageado fora do commit — nada enviado"
_tmp="$(mktemp -d)"; _DIRS+=("${_tmp}")
git worktree add -q --detach "${_tmp}/wt" HEAD || die "não montei o HEAD para julgar"
_WTS+=("${_tmp}/wt")
if ! _lint_in "${_tmp}/wt" "${_tmp}/hard.txt"; then
  # as HARD, nomeadas (2026-10-07): antes o motor só dizia "rode o lint", e cada reprovação custava um lint inteiro
  if [ -s "${_tmp}/hard.txt" ]; then echo "PR-FINALIZE: as violações HARD do commit:" >&2; sed 's/^/  /' "${_tmp}/hard.txt" >&2; fi
  die "lint do COMMIT rc=${_rc}, HARD=${_hard:-?} — nada enviado (os commits locais ficam; o resíduo volta como estava)."
fi
# 4. o contrato KG-SSOT sobre o MESMO commit, pela MESMA invocação do CI (ops/kg-gate-ci.sh): a catraca
#    da dívida SHOULD por grafo é do kg_gate.py, não do lint, e o #1106 passou aqui e reprovou no CI por
#    ela (label de 538 caracteres, 2026-10-14). ~5 s. Sem PyYAML/jsonschema o gate sai rc 2 e o envio para.
if ! (cd "${_tmp}/wt" && bash ops/kg-gate-ci.sh) > "${_tmp}/kggate.txt" 2>&1; then
  echo "PR-FINALIZE: o contrato KG-SSOT reprovou o commit (o mesmo passo do CI):" >&2
  grep -E '^✗|ausente|Error|erro' "${_tmp}/kggate.txt" | grep -v '(herdado)' | head -20 | sed 's/^/  /' >&2
  die "contrato KG-SSOT do COMMIT reprovou — nada enviado (os commits locais ficam; o resíduo volta como estava)."
fi
_DONE=1   # daqui em diante o carimbo é legítimo: o commit que o carrega passou no lint e no contrato
# marcador para o pre-push não relintar o MESMO commit (maior M6: ~11 min por fechamento com lint duplicado)
printf '%s\n' "$(git rev-parse HEAD)" > "$(git rev-parse --git-common-dir)/onion-prefinalize-ok"
echo "PR-FINALIZE: ${BR} pronto — 0 HARD, contrato KG-SSOT verde, resíduo casando, projeções estáveis."
# 5. push só por pedido explícito
if [ "${PUSH}" = 1 ]; then
  # --force-with-lease: depois de --rebase o push é reescrita da PRÓPRIA branch; o lease recusa se o
  # remoto andou por outra mão. Nunca é a main: a branch foi recusada lá em cima.
  # --force-if-includes: depois do `git fetch` do --rebase o lease simples fica vazio e apagava commit de
  # outra mão no remoto (maior M1 do Elenxo, reproduzido e curado com este par).
  git push -q --force-with-lease --force-if-includes origin "${BR}" || die "push recusado (o pre-push julga o commit; veja a mensagem dele)"
  echo "PR-FINALIZE: enviado ${BR} @ $(git rev-parse --short HEAD)"
fi
