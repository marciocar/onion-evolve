#!/usr/bin/env bash
# =============================================================================
# prove-gate-blocks.sh — prova que o pre-commit do ALVO BARRA uma violação HARD, num sandbox descartável
#
# POR QUE EXISTE (recorrência medida, 2026-10-20): em 11 `--update` seguidos o verificador do gate
# (`verify-adopter-gate.sh`, core-only) só provou que o hook EXECUTA. A prova de que ele BARRA dependia de o
# lint do alvo já estar reprovando, e no fim de um update bem feito o lint está limpo; então o
# verificador declara "o BLOQUEIO não foi exercido" e a prova fica com a sessão do adotante. No mesmo dia
# um adotante de campo a fez à mão: um commit-sonda barrado pela REGRA 8 (Inventário canônico sincronizado com
# o filesystem), rc 1. O verificador tinha razão em não inventar um gatilho HARD "portátil", mas a regra
# que todo papel tem existe: é esta. Este script é aquela prova manual virada mecanismo.
#
# O QUE FAZ, em ordem:
#   1. fotografa o checkout REAL do alvo (HEAD, branch, status com untracked, config local);
#   2. resolve o pre-commit que o git do alvo roda DE FATO (`rev-parse --git-path hooks`, que honra
#      `core.hooksPath`, relativo ou absoluto, e a worktree);
#   3. monta o SANDBOX: `git clone --shared --no-checkout` do repositório do alvo para um diretório
#      temporário (lê objetos, não escreve nada no alvo; o remoto é removido em seguida), checkout do HEAD
#      do alvo, e por cima o que está pendente na working tree dele (modificado e não-rastreado que não é
#      ignorado; apagado é apagado). O diretório de hooks é copiado do DISCO do alvo, e o sandbox aponta o
#      `core.hooksPath` para a cópia. Um commit-base `--no-verify` fixa esse estado;
#   4. CONTROLE: commit vazio pelo hook. Sem violação plantada, o gate tem de deixar passar (ou barrar
#      só por HARD que já existia, citada);
#   5. PLANTA: uma linha a mais em `docs/onion/inventory.md`. O inventário é gerado byte a byte do
#      filesystem pelo `inventory.sh`, e a REGRA 8 o compara byte a byte, então a linha extra é drift
#      determinístico, com o mesmo resultado em qualquer papel (source, hub, adopted, door) e em qualquer
#      corpus. Não cria arquivo novo, que acenderia outras regras e turvaria a atribuição;
#   6. exige rc≠0 E a REGRA 8 citada na saída do commit plantado;
#   7. apaga o sandbox e confere que a foto do passo 1 não mudou.
#
# ESCOLHA DA VIOLAÇÃO (e por que não "um comando novo sem regenerar o inventário"): as duas acendem a
# REGRA 8, mas o comando novo também passa pelas regras de frontmatter, tamanho, idioma e cita-por-nome,
# e o veredito passaria a depender de quantas delas o papel tem. A linha extra no inventário mexe num
# único arquivo, gerado, que todo papel recebe do `regen-ssot-projections.sh`.
#
# NUNCA planta nada no checkout real. Tudo o que se escreve vive em `mktemp -d` e é apagado no trap.
#
# USO  : prove-gate-blocks.sh <TARGET>
# SAÍDA: linhas de diagnóstico e, por ÚLTIMO, sempre uma destas duas:
#          bloqueio PROVADO (REGRA 8 (Inventário canônico sincronizado com o filesystem), rc N)
#          bloqueio NÃO PROVADO: <motivo>
# EXIT : 0 PROVADO · 1 NÃO PROVADO por defeito do gate (fail-open, barra tudo, barrou sem citar)
#        3 NÃO PROVADO por precondição (sem pre-commit, sem HEAD, sem inventário, sandbox falhou, timeout,
#          baseline já viola a REGRA 8) · 4 INTEGRIDADE: o checkout real mudou (pare tudo) · 2 uso
# ENV  : ONION_GATE_PROBE_TIMEOUT (segundos por commit, default 900)
# Determinístico, sem LLM, sem jq. Exercitado por lint-selftest.sh (run_prove_gate_blocks_selftests).
# =============================================================================
set -uo pipefail

T_IN="${1:-}"
[ -n "${T_IN}" ] || { echo "uso: prove-gate-blocks.sh <TARGET>" >&2; exit 2; }
[ -d "${T_IN}" ] || { echo "uso: ${T_IN} não é diretório" >&2; exit 2; }

# Variáveis de git herdadas (o update pode rodar dentro de um hook, ou de uma sessão que exportou
# GIT_INDEX_FILE) apontariam os comandos abaixo para o repositório de OUTRO lugar.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_COMMON_DIR GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE 2>/dev/null || true

RULE_LABEL="REGRA 8 (Inventário canônico sincronizado com o filesystem)"
# Citação aceita: a linha VIOLATION do inventário com o rótulo novo (`REGRA 8 (`) ou, em lint de pin
# antigo que ainda não rotulava, a frase da própria guarda. `REGRA 8 (` não casa `REGRA 80 (`.
CITE_RE='^VIOLATION: docs/onion/inventory\.md: .*(REGRA 8 \(|inventário desatualizado)'
PROBE_TIMEOUT="${ONION_GATE_PROBE_TIMEOUT:-900}"

verdict_no() { echo "bloqueio NÃO PROVADO: $2"; exit "$1"; }

T="$(git -C "${T_IN}" rev-parse --show-toplevel 2>/dev/null)" \
  || verdict_no 3 "${T_IN} não é repositório git"
T_HEAD="$(git -C "${T}" rev-parse --verify -q HEAD 2>/dev/null)" \
  || verdict_no 3 "o alvo não tem commits (sem HEAD de onde montar o sandbox)"

# ── 1. FOTO do checkout real ────────────────────────────────────────────────────────────────────────
# HEAD, branch, status (com untracked) e config local. As OUTRAS refs ficam de fora de propósito, e foi
# medido no dogfood (2026-10-20): com a foto incluindo `for-each-ref`, a prova contra um clone do
# adotante de campo acusou o repo real de ter mudado, e o que mudou foi uma branch que a sessão do adotante,
# noutra worktree, commitou no meio dos 3,5 minutos da prova. O sandbox não tem caminho de escrita para
# as refs do alvo (clone `--shared` lê objetos, o remoto é removido), então refs alheias só dariam
# rc 4 falso em todo alvo com sessão viva.
snapshot() {   # GIT_OPTIONAL_LOCKS=0: o `status` não regrava o índice do alvo ao fotografá-lo
  local GIT_OPTIONAL_LOCKS=0; export GIT_OPTIONAL_LOCKS
  {
    git -C "${T}" rev-parse HEAD 2>/dev/null
    git -C "${T}" symbolic-ref -q HEAD 2>/dev/null || echo detached
    git -C "${T}" status --porcelain=v1 -z --untracked-files=all 2>/dev/null | od -An -c
    git -C "${T}" config --local --list 2>/dev/null
  } | sha256sum | cut -d' ' -f1
}
SNAP_BEFORE="$(snapshot)"

# ── 2. RESOLUÇÃO do hook que o git do alvo roda ────────────────────────────────────────────────────
HP="$(git -C "${T}" rev-parse --git-path hooks 2>/dev/null)"
case "${HP}" in /*) H="${HP}" ;; *) H="${T}/${HP}" ;; esac
echo "· alvo: ${T} (HEAD ${T_HEAD:0:12})"
echo "· hooks que o git do alvo usa: ${H}"
[ -f "${H}/pre-commit" ] || verdict_no 3 "o alvo não tem pre-commit em '${H}' (o git não tem o que executar)"
[ -x "${H}/pre-commit" ] || verdict_no 3 "o pre-commit em '${H}' não é executável (o git o ignora)"
[ -f "${T}/docs/onion/inventory.md" ] \
  || verdict_no 3 "o alvo não tem docs/onion/inventory.md, o objeto da ${RULE_LABEL}"

# ── 3. SANDBOX ──────────────────────────────────────────────────────────────────────────────────────
SB="$(mktemp -d -t onion-gate-proof.XXXXXX)" || verdict_no 3 "mktemp falhou"
finish() {
  local rc=$?
  rm -rf "${SB}" 2>/dev/null
  # A integridade é conferida em TODA saída, inclusive nas de NÃO PROVADO: o sandbox existiu e pode ter
  # escapado. Divergência troca o veredito por INTEGRIDADE, porque mais nada importa se o alvo mudou.
  if [ "$(snapshot)" != "${SNAP_BEFORE}" ]; then
    echo "✗ INTEGRIDADE: o checkout real de ${T} MUDOU durante a prova (HEAD, branch, status ou config)."
    echo "bloqueio NÃO PROVADO: o checkout real do alvo mudou durante a prova — confira git status e git reflog em ${T}"
    exit 4
  fi
  [ -e "${SB}" ] && { echo "bloqueio NÃO PROVADO: o sandbox ${SB} não foi apagado"; exit 3; }
  exit "${rc}"
}
trap finish EXIT

R="${SB}/repo"
COMMON="$(git -C "${T}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
git clone -q --shared --no-checkout "${COMMON}" "${R}" >/dev/null 2>&1 \
  || verdict_no 3 "não consegui clonar o repositório do alvo para o sandbox"
git -C "${R}" remote remove origin >/dev/null 2>&1 || true   # nada no sandbox empurra de volta
git -C "${R}" -c core.hooksPath=/dev/null checkout -q --detach "${T_HEAD}" >/dev/null 2>&1 \
  || verdict_no 3 "não consegui fazer checkout do HEAD do alvo no sandbox"

# Pendente na working tree do alvo (o update aplica config e carimbo antes de commitá-los).
while IFS= read -r -d '' f; do
  [ -e "${T}/${f}" ] || [ -L "${T}/${f}" ] || continue
  mkdir -p "${R}/$(dirname -- "${f}")" && cp -a -- "${T}/${f}" "${R}/${f}" 2>/dev/null
done < <(git -C "${T}" ls-files -z -m -o --exclude-standard 2>/dev/null)
while IFS= read -r -d '' f; do rm -f -- "${R}/${f}"; done < <(git -C "${T}" ls-files -z -d 2>/dev/null)

# Hooks: copiados do DISCO do alvo. Dentro da árvore do alvo vão para o mesmo caminho relativo (hook que
# chama "$(dirname "$0")/../algo" continua achando); fora dela (worktree com hooks no gitdir comum, ou
# hooksPath absoluto para outro checkout), para um diretório próprio do sandbox.
case "${H}/" in
  "${T}/"*) HSB="${R}/${H#"${T}/"}" ;;
  *)        HSB="${SB}/hooks" ;;
esac
mkdir -p "${HSB}" && cp -a -- "${H}/." "${HSB}/" 2>/dev/null \
  || verdict_no 3 "não consegui copiar os hooks do alvo para o sandbox"
git -C "${R}" config core.hooksPath "${HSB}"

GC=(git -C "${R}" -c commit.gpgsign=false -c user.email=onion-gate-proof@local -c user.name='Onion Gate Proof')
"${GC[@]}" add -A >/dev/null 2>&1
if ! git -C "${R}" diff --cached --quiet 2>/dev/null; then
  "${GC[@]}" commit -q --no-verify -m "base: estado do alvo" >/dev/null 2>&1 \
    || verdict_no 3 "não consegui fixar o estado do alvo no sandbox (commit-base)"
fi

run_commit() {  # $@ = args do commit → define OUT e RC
  if command -v timeout >/dev/null 2>&1; then
    OUT="$(cd "${R}" && timeout "${PROBE_TIMEOUT}" "${GC[@]}" commit "$@" 2>&1)"; RC=$?
  else
    OUT="$(cd "${R}" && "${GC[@]}" commit "$@" 2>&1)"; RC=$?
  fi
}

# ── 4. CONTROLE ─────────────────────────────────────────────────────────────────────────────────────
run_commit --allow-empty -m "controle: sem violação plantada"
C_RC="${RC}"; C_OUT="${OUT}"
[ "${C_RC}" -eq 124 ] && verdict_no 3 "o commit de controle estourou o tempo (${PROBE_TIMEOUT}s)"
echo "· controle (sem violação): rc ${C_RC}"
if grep -Eq "${CITE_RE}" <<< "${C_OUT}"; then
  verdict_no 3 "o estado do alvo JÁ viola a ${RULE_LABEL} sem nada plantado — a prova não é atribuível; regenere o inventário no alvo (/meta:inventory) e rode de novo"
fi
C_HARD="$(grep -c '^VIOLATION:' <<< "${C_OUT}")" || C_HARD=0
if [ "${C_RC}" -ne 0 ] && [ "${C_HARD}" -eq 0 ]; then
  printf '%s\n' "${C_OUT}" | tail -8 | sed 's/^/    /'
  verdict_no 1 "o gate barra até o commit de controle, sem violação plantada nem citada (rc ${C_RC}) — barrar tudo não é discriminar HARD"
fi

# ── 5. PLANTA ───────────────────────────────────────────────────────────────────────────────────────
printf '\n<!-- onion-gate-proof: linha plantada no sandbox, nunca no alvo -->\n' >> "${R}/docs/onion/inventory.md"
"${GC[@]}" add -- docs/onion/inventory.md >/dev/null 2>&1
run_commit -m "sonda: violação HARD plantada (inventário fora de sincronia)"
P_RC="${RC}"; P_OUT="${OUT}"
[ "${P_RC}" -eq 124 ] && verdict_no 3 "o commit plantado estourou o tempo (${PROBE_TIMEOUT}s)"
echo "· plantado (inventário com uma linha a mais): rc ${P_RC}"

# ── 6. VEREDITO ─────────────────────────────────────────────────────────────────────────────────────
if [ "${P_RC}" -eq 0 ]; then
  if grep -Eq "${CITE_RE}" <<< "${P_OUT}"; then
    verdict_no 1 "FAIL-OPEN: o hook rodou o lint, o lint acusou a ${RULE_LABEL}, e o commit PASSOU (rc 0) — o hook ignora o veredito do lint"
  fi
  verdict_no 1 "FAIL-OPEN: violação HARD plantada (${RULE_LABEL}) e o commit PASSOU (rc 0) — o hook não rodou o lint do Onion"
fi
if ! grep -Eq "${CITE_RE}" <<< "${P_OUT}"; then
  printf '%s\n' "${P_OUT}" | tail -8 | sed 's/^/    /'
  verdict_no 1 "o commit plantado foi barrado (rc ${P_RC}) sem citar a ${RULE_LABEL} — quem barrou não foi o gate do Onion"
fi
grep -E "${CITE_RE}" <<< "${P_OUT}" | head -1 | sed 's/^/    /'
[ "${C_RC}" -ne 0 ] && echo "· aviso: o controle já era barrado por ${C_HARD} HARD pré-existente(s) (rc ${C_RC}) — o alvo não commita sem curá-las"
echo "bloqueio PROVADO (${RULE_LABEL}, rc ${P_RC})"
exit 0
