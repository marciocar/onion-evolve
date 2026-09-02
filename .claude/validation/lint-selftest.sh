#!/usr/bin/env bash
# =============================================================================
# lint-selftest.sh — Auto-teste das guardas determinísticas do Sistema Onion
#
# Propósito : Garantir que as guardas de lint (lint-artifacts.sh) e o validador
#             de contratos (federation-contract-validate.sh) CONTINUAM reagindo.
#             Sem isto, uma regra que silenciosamente para de funcionar (regex
#             quebrada, allowlist larga demais) passaria despercebida — a
#             meta-falha "guarda parcial" aplicada às próprias guardas.
#
# Mecânica  : Para cada fixture do manifest (.claude/validation/fixtures/),
#             injeta um input conhecido e confere o veredito real contra o
#             esperado. Trata lint-artifacts.sh como CAIXA-PRETA (sem refator).
#
#   modo "lint"     : monta um SANDBOX (cópia de .claude/ + docs/ + CLAUDE.md, de
#                     modo que inventory.sh veja os números REAIS), injeta a
#                     fixture com nome único, roda o lint no sandbox e assere por
#                     PATH — grep do nome injetado na saída de violações:
#                       bad     -> DEVE haver violação citando o arquivo (+keyword)
#                       good    -> NÃO pode haver violação citando o arquivo
#                       exempt  -> NÃO pode haver violação citando o arquivo
#                     A âncora-por-path ignora o ruído incidental (ex.: injetar 1
#                     agente faz a Regra 8 citar inventory.md, não a fixture).
#   modo "contract" : roda federation-contract-validate.sh <fixture> e assere o
#                     exit code (pass=0 / fail≠0). Não precisa de sandbox.
#
# Desfechos : TRÊS, nunca dois — ✓ passou · ✗ falhou · ⊘ NÃO VERIFICADO (o SUT não foi
#             exercido porque tooling/feature falta). Um runner de dois desfechos soma o
#             "pulei" no "passei" e produz o mesmo "N passaram" de uma máquina saudável:
#             falso-verde por vacuidade. Ver record_skip().
#
# Uso       : bash .claude/validation/lint-selftest.sh
#             ONION_SELFTEST_STRICT=1 bash ... → ⊘ vira FALHA (asserção de capacidade; é o
#             modo do CI, onde tooling ausente é defeito de ambiente, não degrade aceitável)
# Saída     : exit 0 se todos os vereditos batem; exit 1 se algum diverge (ou, em STRICT,
#             se algo ficou por verificar).
#
# Determinístico, sem LLM. Par do princípio inventory.sh/lint-artifacts.sh.
# =============================================================================

set -euo pipefail

# ── A BANCADA NÃO PODE MORRER CALADA ───────────────────────────────────────────────────────────
# Medido em 2026-08-08: reescrevi um mutation test usando `cmd; rc=$?` — padrão que, sob `set -e`,
# MATA a suíte no `cmd` que retorna != 0, antes da atribuição. A bancada abortou logo depois do caso
# `kg-verificacao (f)`, com exit 1, ZERO `✗` registrados e NENHUMA soma impressa. Rodando o bloco
# isolado num runner meu — que não copiava o `set` daqui — os 16 casos davam verde. Duas leituras
# possíveis do mesmo estado, e a errada era a confortável.
# Este trap remove a leitura confortável: se a suíte terminar sem imprimir a soma, ela DIZ isso.
# É a mesma doutrina do `record_skip` uma camada acima — abort apresentado como veredito é vacuidade.
SUMMARY_PRINTED=0
_bench_abort_guard() {
  local rc=$?
  [ "${SUMMARY_PRINTED}" -eq 1 ] && return 0
  echo ""
  echo "✗✗ BANCADA ABORTOU ANTES DA SOMA (exit ${rc}) — o último ✓ acima NÃO é o fim da suíte."
  echo "   Sob 'set -e', um comando que retorna != 0 fora de if/&&/|| mata a suíte na hora: os casos"
  echo "   seguintes NUNCA RODARAM e nenhum ✗ foi registrado. NÃO leia esta saída como verde."
  echo "   Suspeito nº 1: 'cmd; rc=\$?' — troque por 'if cmd; then rc=0; else rc=1; fi'."
  echo "   E se você extraiu um bloco para um runner isolado: copie o 'set -euo pipefail' daqui,"
  echo "   senão o runner mente a favor (foi exatamente assim que este defeito passou)."
}
trap _bench_abort_guard EXIT

# Git hooks EXPORTAM GIT_DIR/GIT_INDEX_FILE (e o `git commit` os aponta para o repo do
# commit em curso). Cada sandbox git forjada aqui os herdaria e operaria no repo ERRADO.
# Medido: sob `git commit`, a suíte ABORTAVA no caso 93 de 472 — e o hook anunciava
# "self-test das guardas falhou", quando o real era "379 guardas nunca rodaram". Um abort
# apresentado como veredito é a MESMA vacuidade que o record_skip conserta, uma camada
# acima: o pre-commit era inutilizável exatamente nos commits que tocam as guardas.
# Defeito PRÉ-EXISTENTE, achado dogfoodando o próprio fix (a main aborta idêntico).
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

# MESMA CLASSE, UMA CAMADA ACIMA — o runner do CI exporta GITHUB_*, e uma guarda que os lê
# (hoje review-artifact-check.sh) passa a julgar o PR REAL de dentro da sandbox: procura
# `feat-<branch-do-PR>.md` num fixture que só tem `feat-x.md`. Medido no PR #554: 6 casos
# verdes LOCALMENTE (var ausente → o helper cai no git) e reprovando no CI. Pior, o caso (b)
# passava PELO MOTIVO ERRADO — ele espera ARTEFATO-AUSENTE, que é o que o vazamento produz.
#
# A bancada é HERMÉTICA POR CONSTRUÇÃO: quem precisa de GITHUB_* fixa explicitamente no seu
# próprio caso (é o que (h) sempre fez, e por isso foi o único que passou no CI). Consertar
# só os 6 casos seria disciplina — curaria os de hoje e não impediria o 7º.
unset GITHUB_HEAD_REF GITHUB_REF_NAME GITHUB_EVENT_NAME GITHUB_BASE_REF GITHUB_ACTIONS \
      GITHUB_REPOSITORY GITHUB_RUN_ID GITHUB_EVENT_PATH GITHUB_SHA GITHUB_REF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FIX_DIR="${SCRIPT_DIR}/fixtures"
MANIFEST="${FIX_DIR}/manifest.tsv"
INJECT_BASE="selftest-fixture-probe"     # kebab-case → não dispara a Regra 6
INJECT_NAME="${INJECT_BASE}.md"

PASS=0
FAIL=0
SKIP=0
FAILED_CASES=()
SKIPPED_CASES=()
# ONION_SELFTEST_STRICT=1 → skip vira FALHA (assercão de capacidade). Local, o degrade
# gracioso é intencional: nem toda máquina tem jq/pyyaml e o autor não deve ser bloqueado.
# No CI ele é inaceitável — um runner sem tooling passaria em verde sem validar nada. É a
# MESMA postura que o step de design tokens já aplica (onion-validate.yml, fail-loud sem jq),
# aqui generalizada para a suíte inteira em vez de um gate só.
STRICT="${ONION_SELFTEST_STRICT:-0}"

# Nota: o loop de fixtures (lint/fix/contract/merge) é core-only — exige as fixtures
# vendorizadas em ${FIX_DIR}. Um adotante não as vendoriza, então NÃO abortamos aqui:
# o loop abaixo (ver "Loop do manifest") fica condicional e os modos self-contained
# (de-identification etc.) seguem rodando. Robustez a adotante sem perder a guarda no core.

# ---------------------------------------------------------------------------
# Sandbox para o modo lint — cópia fiel para que inventory.sh compute a verdade
# ---------------------------------------------------------------------------
SANDBOX="$(mktemp -d)"
# ⚠️ UM HANDLER POR SINAL. `trap ... EXIT` SUBSTITUI o anterior — este `rm -rf` estava, desde que foi
#    escrito, DESLIGANDO o `_bench_abort_guard` instalado 51 linhas acima. A guarda cujo propósito é
#    dizer "a suíte terminou SEM somar" ficou muda por construção, e o comentário dela descreve
#    exatamente o caso que voltou a acontecer em 2026-08-10: 666 casos, nenhum ✗, nenhuma soma, e a
#    leitura confortável disponível. A cura existia e estava desarmada — é a forma mais cara de
#    `declarado != verificado`, porque o artefato PARECE protegido.
#    `_bench_abort_guard` é chamado PRIMEIRO e sua 1ª instrução é `local rc=$?`, então o exit status
#    real chega intacto; a limpeza vem depois e nunca mascara o veredito.
_bench_on_exit() { _bench_abort_guard; rm -rf "${SANDBOX:-}"; }
trap _bench_on_exit EXIT
cp -a "${REPO_ROOT}/.claude"   "${SANDBOX}/.claude"
cp -a "${REPO_ROOT}/docs"      "${SANDBOX}/docs"
cp -a "${REPO_ROOT}/CLAUDE.md" "${SANDBOX}/CLAUDE.md"

# ---------------------------------------------------------------------------
# SSOT em tempo de teste — derivada do inventory.sh do PRÓPRIO sandbox (verdade
# real). Fixtures de contagem (r16) usam placeholders em vez de hardcodar o total,
# pra não ficarem stale a cada comando novo/removido:
#   __ONION_COMMANDS_TOTAL__ → contagem real      (caso GOOD: deve casar a SSOT)
#   __ONION_COMMANDS_DRIFT__ → contagem + offset   (casos BAD/EXEMPT: diverge garantido)
# A substituição acontece ao injetar a fixture no sandbox (run_lint_fixture).
SSOT_CMD_TOTAL="$(bash "${SANDBOX}/.claude/validation/inventory.sh" --env 2>/dev/null \
  | grep '^ONION_COMMANDS_TOTAL=' | cut -d= -f2)"
SSOT_CMD_DRIFT="$(( ${SSOT_CMD_TOTAL:-0} + 7 ))"   # offset != 0 → sempre divergente
# __ONION_AGENTS_TOTAL__ → contagem real de agentes (usado por fixtures da frase
# COMBINADA 'N agentes e M comandos', onde só o lado comandos deve divergir).
SSOT_AGENT_TOTAL="$(bash "${SANDBOX}/.claude/validation/inventory.sh" --env 2>/dev/null \
  | grep '^ONION_AGENTS_TOTAL=' | cut -d= -f2)"
# __ONION_AGENTS_DRIFT__ → total de agentes + offset (fixtures BARE 'N agentes
# especializados/IA' bad + goods que provam as guardas anti-FP).
SSOT_AGENT_DRIFT="$(( ${SSOT_AGENT_TOTAL:-0} + 3 ))"
# __ONION_AGENT_CATEGORIES__ → nº real de categorias de AGENTE (≠ categorias de comando);
# __ONION_AGENT_CATEGORIES_DRIFT__ → + offset (caso BAD: divergência garantida da SSOT de agent-cats).
SSOT_AGENT_CATS="$(bash "${SANDBOX}/.claude/validation/inventory.sh" --env 2>/dev/null \
  | grep '^ONION_AGENT_CATEGORIES=' | cut -d= -f2)"
SSOT_AGENT_CATS_DRIFT="$(( ${SSOT_AGENT_CATS:-0} + 3 ))"
# __ONION_SKILLS_TOTAL__ / __ONION_KBS_TOTAL__ → reais (formato COMPOSTO: só comandos diverge; skills/KBs casam).
SSOT_SKILL_TOTAL="$(bash "${SANDBOX}/.claude/validation/inventory.sh" --env 2>/dev/null \
  | grep '^ONION_SKILLS_TOTAL=' | cut -d= -f2)"
SSOT_KB_TOTAL="$(bash "${SANDBOX}/.claude/validation/inventory.sh" --env 2>/dev/null \
  | grep '^ONION_KBS_TOTAL=' | cut -d= -f2)"
# __ONION_SKILLS_DRIFT__ / __ONION_KBS_DRIFT__ → total + offset (fixtures BAD dos novos
# feeders 'N skills' bare-ancorado, tabela invertida e 'Knowledge Bases (N documentos)').
SSOT_SKILL_DRIFT="$(( ${SSOT_SKILL_TOTAL:-0} + 3 ))"
SSOT_KB_DRIFT="$(( ${SSOT_KB_TOTAL:-0} + 5 ))"

record_pass() { PASS=$((PASS + 1)); echo "  ✓ ${1}"; }
record_fail() { FAIL=$((FAIL + 1)); FAILED_CASES+=("${1}"); echo "  ✗ ${1} — ${2}"; }

# ── COPIAR O RADAR/A LENTE PARA MUTAR: a lib VAI JUNTO ──────────────────────────────────────────
# Desde 2026-08-09 o fator de status vive em SITIO UNICO (`lib/status-factor.awk`) e os consumidores
# saem 2 sem ele — de proposito, porque fonte ausente nunca vira aprovacao. Consequencia medida: SEIS
# mutation tests que copiavam so o script para um tmp passaram a ver a mensagem de fail-loud em vez
# do comportamento, e acusaram "vacuidade" onde havia cura. O conserto e UM helper, nao seis
# remendos — o proximo teste que copiar o motor nao precisa lembrar da lib.
_lib_beside() {  # $1 = diretorio onde o motor copiado vai rodar
  mkdir -p "$1/lib" && cp "${SCRIPT_DIR}/lib/status-factor.awk" "$1/lib/" 2>/dev/null || true
}

# ── DISCIPLINA DO MUTATION TEST, EM UM LUGAR SÓ ────────────────────────────────────────────────
# Um mutation test só prova algo se TRÊS coisas forem verdade, e a casa já perdeu duas delas em
# dias seguidos:
#   1. a MUTAÇÃO foi APLICADA — 2026-08-07: três guardas usavam `grep` de padrão, e o padrão
#      aparecia no arquivo INTACTO (dentro da própria linha do `sed`), então um `sed` no-op "passava";
#   2. o INTACTO SATISFAZ o caso — 2026-08-08: sabotei a fixture de propósito e o mutation test da
#      catraca da REGRA 49 sobreviveu, porque afirmava uma AUSÊNCIA, e ausência é o que uma fixture
#      morta entrega de graça;
#   3. o MUTANTE NÃO satisfaz o caso — a única das três que costuma estar escrita.
# Este helper cobra as três, e nomeia QUAL falhou. Quem escrever o próximo mutation test não precisa
# lembrar da lição: ela está no chamador obrigatório.
_prove_mutation() { # $1=nome $2=arq_intacto $3=arq_mutante $4=rc_caso_no_intacto $5=rc_caso_no_mutante (0=caso passa)
  # 0. os DOIS arquivos existem. Parece obvio e nao e: `cmp -s <existente> <apagado>` devolve 2,
  #    NUNCA 0, entao a invariante (1) abaixo fica MORTA POR CONSTRUCAO quando o chamador apaga o
  #    tmp antes de provar — e o caso passa a acusar "a linha nao e load-bearing" quando o defeito
  #    real e "o seu mutante nao existe mais". Aconteceu no caso (c) do status-factor, achado por
  #    passada adversarial. E a terceira vez que a familia "medi um artefato que nao estava la"
  #    morde nesta casa; por isso a checagem mora AQUI, no chamador obrigatorio, e nao na memoria
  #    de quem escreve o proximo mutation test.
  for _pm_f in "$2" "$3"; do
    [ -f "${_pm_f}" ] || { record_fail "$1" "ARQUIVO AUSENTE na hora de provar: ${_pm_f} (apagado antes da prova?)"; return; }
  done
  if cmp -s "$2" "$3"; then
    record_fail "$1" "GUARDA-DA-GUARDA: a mutacao NAO foi aplicada (arquivos identicos) — o sed virou no-op"; return
  fi
  if [ "$4" -ne 0 ]; then
    record_fail "$1" "FIXTURE MORTA: o arquivo INTACTO ja nao satisfaz o caso — o mutante nao prova nada"; return
  fi
  if [ "$5" -eq 0 ]; then
    record_fail "$1" "o mutante AINDA satisfaz o caso — a linha mutada nao e load-bearing"; return
  fi
  record_pass "$1"
}
# TERCEIRO DESFECHO — o SUT NÃO foi exercido (tooling/feature ausente). Nunca soma em PASS.
# Onde só existem "lançar" e "não lançar", "não verifiquei" se disfarça de "verifiquei e está
# bom" — falso-verde por VACUIDADE (architecture-challenges.md §1.3). Antes disto, 32 sítios
# registravam skip como ✓: uma máquina sem jq/python3 produzia o MESMO "N passaram" de uma
# máquina saudável. Sinal de campo 2026-07-25 (adotante): o mesmo defeito custou um deploy.
# Em STRICT (CI) um skip é FALHA — ver bloco do sumário. [[fix-must-become-mechanism]]
record_skip() { SKIP=$((SKIP + 1)); SKIPPED_CASES+=("${1}"); echo "  ⊘ ${1}"; }

# ---------------------------------------------------------------------------
# Modo lint — injeta a fixture no sandbox e assere por path
# ---------------------------------------------------------------------------
run_lint_fixture() {
  local fixture="$1" target="$2" verdict="$3" keyword="$4"
  local src="${FIX_DIR}/${fixture}"
  local dst_dir="${SANDBOX}/${target}"
  local dst="${dst_dir}/${INJECT_NAME}"

  if [ ! -f "${src}" ]; then
    record_fail "${fixture}" "fixture inexistente: ${src}"
    return
  fi

  mkdir -p "${dst_dir}"
  # Substitui placeholders de contagem pela SSOT derivada (ver bloco SSOT acima).
  # Fixtures sem placeholder passam intactas (sed é no-op).
  sed -e "s/__ONION_COMMANDS_TOTAL__/${SSOT_CMD_TOTAL}/g" \
      -e "s/__ONION_COMMANDS_DRIFT__/${SSOT_CMD_DRIFT}/g" \
      -e "s/__ONION_AGENTS_TOTAL__/${SSOT_AGENT_TOTAL}/g" \
      -e "s/__ONION_AGENTS_DRIFT__/${SSOT_AGENT_DRIFT}/g" \
      -e "s/__ONION_SKILLS_TOTAL__/${SSOT_SKILL_TOTAL}/g" \
      -e "s/__ONION_SKILLS_DRIFT__/${SSOT_SKILL_DRIFT}/g" \
      -e "s/__ONION_KBS_TOTAL__/${SSOT_KB_TOTAL}/g" \
      -e "s/__ONION_KBS_DRIFT__/${SSOT_KB_DRIFT}/g" \
      -e "s/__ONION_AGENT_CATEGORIES_DRIFT__/${SSOT_AGENT_CATS_DRIFT}/g" \
      -e "s/__ONION_AGENT_CATEGORIES__/${SSOT_AGENT_CATS}/g" \
      "${src}" > "${dst}"

  local out
  out="$(bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --only="${dst}" 2>&1)" || true

  rm -f "${dst}"

  # Linhas de violação que citam o arquivo injetado (âncora-por-path)
  local cited
  cited="$(printf '%s\n' "${out}" | grep -F "${INJECT_BASE}" || true)"

  case "${verdict}" in
    bad)
      if [ -z "${cited}" ]; then
        record_fail "${fixture}" "esperava violação citando a fixture, nenhuma apareceu (guarda quebrada?)"
      elif [ -n "${keyword}" ] && ! printf '%s\n' "${cited}" | grep -qF "${keyword}"; then
        record_fail "${fixture}" "violação apareceu sem o keyword '${keyword}' (regra errada disparou?)"
      else
        record_pass "${fixture}"
      fi
      ;;
    good | exempt)
      if [ -n "${cited}" ]; then
        record_fail "${fixture}" "não esperava violação citando a fixture, mas apareceu (falso-positivo da guarda): ${cited}"
      else
        record_pass "${fixture}"
      fi
      ;;
    *)
      record_fail "${fixture}" "verdict desconhecido '${verdict}'"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Modo fix — injeta a fixture, roda 'lint-artifacts.sh --fix' no sandbox e assere
# o EFEITO da reescrita (não só a detecção):
#   corrected : após --fix, a fixture não é mais citada na detecção (drift curado),
#               o valor de drift sumiu, e uma 2ª passada de --fix é byte-idêntica
#               (IDEMPOTÊNCIA).
#   untouched : a fixture (path/frontmatter isento) permanece byte-idêntica após
#               --fix (o motor de reescrita herda o escopo da detecção).
# ---------------------------------------------------------------------------
run_fix_fixture() {
  local fixture="$1" target="$2" verdict="$3"
  local src="${FIX_DIR}/${fixture}"
  local dst_dir="${SANDBOX}/${target}"
  local dst="${dst_dir}/${INJECT_NAME}"

  if [ ! -f "${src}" ]; then
    record_fail "${fixture}" "fixture inexistente: ${src}"
    return
  fi

  mkdir -p "${dst_dir}"
  sed -e "s/__ONION_COMMANDS_TOTAL__/${SSOT_CMD_TOTAL}/g" \
      -e "s/__ONION_COMMANDS_DRIFT__/${SSOT_CMD_DRIFT}/g" \
      -e "s/__ONION_AGENTS_TOTAL__/${SSOT_AGENT_TOTAL}/g" \
      -e "s/__ONION_AGENTS_DRIFT__/${SSOT_AGENT_DRIFT}/g" \
      -e "s/__ONION_SKILLS_TOTAL__/${SSOT_SKILL_TOTAL}/g" \
      -e "s/__ONION_KBS_TOTAL__/${SSOT_KB_TOTAL}/g" \
      -e "s/__ONION_AGENT_CATEGORIES_DRIFT__/${SSOT_AGENT_CATS_DRIFT}/g" \
      -e "s/__ONION_AGENT_CATEGORIES__/${SSOT_AGENT_CATS}/g" \
      "${src}" > "${dst}"
  local before; before="$(cat "${dst}")"

  bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --fix --only="${dst}" >/dev/null 2>&1 || true

  case "${verdict}" in
    corrected)
      local out cited
      out="$(bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --only="${dst}" 2>&1)" || true
      cited="$(printf '%s\n' "${out}" | grep -F "${INJECT_BASE}" || true)"
      if [ -n "${cited}" ]; then
        record_fail "${fixture}" "--fix não curou o drift; ainda citada: ${cited}"; rm -f "${dst}"; return
      fi
      if grep -qF "${SSOT_CMD_DRIFT} comandos" "${dst}"; then
        record_fail "${fixture}" "--fix deixou o valor de drift (${SSOT_CMD_DRIFT}) no arquivo"; rm -f "${dst}"; return
      fi
      local after1; after1="$(cat "${dst}")"
      bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --fix --only="${dst}" >/dev/null 2>&1 || true
      if [ "$(cat "${dst}")" != "${after1}" ]; then
        record_fail "${fixture}" "--fix não idempotente (2ª passada mudou bytes)"; rm -f "${dst}"; return
      fi
      record_pass "${fixture} (fix:corrected+idempotente)"
      ;;
    untouched)
      if [ "$(cat "${dst}")" != "${before}" ]; then
        record_fail "${fixture}" "--fix tocou arquivo isento (deveria preservar histórico/snapshot)"; rm -f "${dst}"; return
      fi
      record_pass "${fixture} (fix:untouched)"
      ;;
    *)
      record_fail "${fixture}" "verdict fix desconhecido '${verdict}'"
      ;;
  esac
  rm -f "${dst}"
}

# ---------------------------------------------------------------------------
# Modo kg — exit code de kg-radar.sh --integrity (motor do Knowledge Graph SDAAL)
# ---------------------------------------------------------------------------
run_kg_fixture() {
  local fixture="$1" verdict="$2"
  local src="${FIX_DIR}/${fixture}"

  if [ ! -f "${src}" ]; then
    record_fail "${fixture}" "fixture inexistente: ${src}"
    return
  fi

  local rc=0
  bash "${SCRIPT_DIR}/kg-radar.sh" "${src}" --integrity >/dev/null 2>&1 || rc=$?

  case "${verdict}" in
    pass)
      if [ "${rc}" -eq 0 ]; then record_pass "${fixture}"
      else record_fail "${fixture}" "esperava exit 0, veio ${rc}"; fi
      ;;
    fail)
      # exige exatamente rc=1 (integridade quebrada); rc=2 é uso/arquivo-inexistente
      # — aceitá-lo mascararia um path de fixture quebrado como sucesso.
      if [ "${rc}" -eq 1 ]; then record_pass "${fixture}"
      elif [ "${rc}" -eq 0 ]; then record_fail "${fixture}" "esperava exit 1, veio 0 (radar não pegou grafo inválido)"
      else record_fail "${fixture}" "esperava exit 1, veio ${rc} (uso/arquivo inexistente? fixture path quebrado?)"; fi
      ;;
    *)
      record_fail "${fixture}" "verdict desconhecido '${verdict}'"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Modo kg-freshness/schema — guardas de frescor + versão de schema do kg-radar.sh
# (ADR onion-adr-kg-freshness-gate, propostas #2/#1 de um dogfood de campo). Frescor é AVISO
# (⚠, não muda exit) → asserção por CONTEÚDO de stdout; schema é RECUSA (✗, exit 1).
# ---------------------------------------------------------------------------
run_kg_freshness_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local fx="${FIX_DIR}/kg-freshness" sx="${FIX_DIR}/kg-schema"
  local out rc

  # (a) fresh-verified --all: frescor declarado + schema atual → exit 0, sem STALE, SCHEMA ✅
  rc=0; out=$(bash "${radar}" "${fx}/fresh-verified.kg.yaml" --all 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && ! grep -q 'STALE' <<<"${out}" \
     && grep -q 'schema_version 1 (bate' <<<"${out}"; then
    record_pass "kg-freshness: fresh-verified → exit 0, sem STALE, schema ✅"
  else record_fail "kg-freshness: fresh-verified" "rc=${rc} out=${out}"; fi

  # (b) stale-missing --freshness: nó PROD sem verified_at → STALE-MISSING, exit 0 (aviso)
  rc=0; out=$(bash "${radar}" "${fx}/stale-missing.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q 'STALE-MISSING: ST_A' <<<"${out}"; then
    record_pass "kg-freshness: stale-missing → STALE-MISSING + exit 0 (aviso, não reprova)"
  else record_fail "kg-freshness: stale-missing" "rc=${rc} out=${out}"; fi

  # (c) stale-old --freshness: verified_at < baseline → STALE-OLD, exit 0 (determinístico, sem "agora")
  rc=0; out=$(bash "${radar}" "${fx}/stale-old.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q 'STALE-OLD: ST_A' <<<"${out}"; then
    record_pass "kg-freshness: stale-old → STALE-OLD + exit 0"
  else record_fail "kg-freshness: stale-old" "rc=${rc} out=${out}"; fi

  # (c2) superseded/refuted NÃO são cobrados por frescor — mas o nó VIVO sem carimbo continua sendo.
  # Os dois lados no mesmo caso: senão "consertar" seria matar a guarda e chamar de fix.
  rc=0; out=$(bash "${radar}" "${fx}/superseded-not-chased.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && ! grep -q 'STALE-MISSING: C_VELHO' <<<"${out}" \
     && ! grep -q 'STALE-MISSING: C_MORTO' <<<"${out}" \
     && grep -q 'STALE-MISSING: C_VIVO' <<<"${out}"; then
    record_pass "kg-freshness: superseded/refuted não cobrados; nó vivo sem carimbo ainda cobrado"
  else record_fail "kg-freshness: superseded-not-chased" "rc=${rc} out=${out}"; fi

  # (d) schema-divergent --schema: schema_version ≠ radar → RECUSA com exit 1 (não é aviso)
  rc=0; out=$(bash "${radar}" "${sx}/schema-divergent.kg.yaml" --schema 2>&1) || rc=$?
  if [ "${rc}" -eq 1 ] && grep -q 'schema_version divergente' <<<"${out}"; then
    record_pass "kg-schema: divergente → ✗ + exit 1 (recusa, radar não sabe ler)"
  else record_fail "kg-schema: divergente" "esperava exit 1 + ✗; rc=${rc} out=${out}"; fi

  # (e) retrocompat: grafo legado sem schema_version → ⚠ ausente + exit 0 (não quebra grafo válido)
  rc=0; out=$(bash "${radar}" "${FIX_DIR}/kg-domain/good-domain.kg.yaml" --schema 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q 'schema_version ausente' <<<"${out}"; then
    record_pass "kg-schema: ausente → ⚠ + exit 0 (retrocompat, degradê)"
  else record_fail "kg-schema: ausente/retrocompat" "esperava exit 0 + ⚠; rc=${rc} out=${out}"; fi

  # (e2) ASPAS SIMPLES — schema_version: '1' PASSA (não reprova). Sinal de campo de um adotante 2026-07-29:
  # o prettier normaliza "1" → '1' e roda no pre-commit → todo .kg.yaml nasce reprovando o próprio gate.
  # As 9 fixtures kg-* usavam SÓ aspas duplas, então a suíte não pegava essa classe (o adotante apontou).
  # O trim() de kg-radar/kg-view passou a tirar aspas simples E duplas. Esta guarda fecha o flanco.
  rc=0; out=$(bash "${radar}" "${sx}/single-quotes.kg.yaml" --schema 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q 'bate com o radar' <<<"${out}"; then
    record_pass "kg-schema: (e2) aspas simples ('1') → PASSA (regressão prettier-quebra-grafo, sinal de campo)"
  else record_fail "kg-schema: (e2) aspas simples" "esperava exit 0 + 'bate com o radar'; rc=${rc} out=${out}"; fi

  # (e3) o mesmo trim() limpa label/on citados com aspas simples (o fix é mais amplo que o schema):
  # a paridade kg-view × kg-radar tem de casar num grafo TODO em aspas simples.
  rc=0; bash "${SCRIPT_DIR}/kg-view.sh" "${sx}/single-quotes.kg.yaml" --assert-parity >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "kg-schema: (e3) grafo todo em aspas simples → paridade kg-view × kg-radar casa"
  else record_fail "kg-schema: (e3) paridade aspas simples" "os 2 parsers divergiram num grafo aspas-simples; rc=${rc}"; fi

  # (f) F1.1 — frescor estende a DEV que rastreia artefato móvel (verified_against), sem inundar
  # claim epistêmico DEV puro. Sinal de um adotante: ssot-como-runtime §2 (C_CONSOLIDATION_MAP stale).
  rc=0; out=$(bash "${radar}" "${fx}/dev-tracked-stale.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && grep -q 'STALE-MISSING: C_STRAT' <<<"${out}" \
     && ! grep -q 'C_READ' <<<"${out}"; then
    record_pass "kg-freshness: DEV+verified_against → STALE-MISSING; DEV puro NÃO flagado (não inunda)"
  else record_fail "kg-freshness: dev-tracked" "esperava STALE C_STRAT sem C_READ; rc=${rc} out=${out}"; fi

  # ── UNANCHORED com filtro por node_type ───────────────────────────────────────────────────
  # O veredito nasceu em 2026-07-26 SEM teste — o único dos três de frescor sem cobertura, e
  # com alcance largo demais (275 avisos nos 22 grafos, 170 em tipos que já ancoram por
  # trace:/TRACES_TO). Estes casos fecham as duas dívidas de uma vez.
  local fxu="${fx}/unanchored-typed.kg.yaml"
  rc=0; out=$(bash "${radar}" "${fxu}" --freshness 2>&1) || rc=$?

  # (g) cobra o claim, silencia os demais tipos — os dois lados no MESMO caso.
  if [ "${rc}" -eq 0 ] \
     && grep -q 'UNANCHORED: C_AFIRMA' <<<"${out}" \
     && ! grep -qE 'UNANCHORED: (C_ANCORADA|E_MEDIU|D_DECIDE|EN_DOM|A_DOC|Q_ABERTA)' <<<"${out}"; then
    record_pass "kg-freshness: (g) UNANCHORED cobra claim e NÃO cobra evidence/decision/entity/artifact/question"
  else record_fail "kg-freshness: (g) filtro por node_type" "rc=${rc} out=${out}"; fi

  # (h) o filtro NÃO virou `continue` no laço: os outros vereditos seguem valendo p/ não-claim,
  # e num mesmo nó UNANCHORED e STALE-OLD compõem em vez de se excluírem.
  if grep -q 'STALE-MISSING: E_SEM_CARIMBO' <<<"${out}" \
     && grep -q 'UNANCHORED: C_VELHA' <<<"${out}" \
     && grep -q 'STALE-OLD: C_VELHA' <<<"${out}"; then
    record_pass "kg-freshness: (h) STALE-MISSING ainda vale p/ não-claim + UNANCHORED e STALE-OLD compõem"
  else record_fail "kg-freshness: (h) escopo dos outros vereditos" "o filtro virou continue? out=${out}"; fi

  # (i) supressão CONTADA, nunca silenciosa — 5 não-claim carimbados sem alvo na fixture.
  if grep -q 'ℹ 5 nó(s) não-claim' <<<"${out}"; then
    record_pass "kg-freshness: (i) supressão contada e visível (ℹ 5) — filtro auditável, não mágico"
  else record_fail "kg-freshness: (i) linha de supressão" "esperava 'ℹ 5 nó(s) não-claim'; out=${out}"; fi

  # (j) o veredito acima só vale sobre grafo íntegro — senão é opinião sobre arquivo quebrado.
  rc=0; bash "${radar}" "${fxu}" --integrity --schema >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "kg-freshness: (j) a fixture do UNANCHORED é íntegra (veredito não é sobre grafo quebrado)"
  else record_fail "kg-freshness: (j) integridade da fixture" "rc=${rc}"; fi

  # (k) (MUT) — desfeito o filtro, o evidence VOLTA a ser cobrado e a linha ℹ some. Sem esta
  # prova, (g) passaria igual se o filtro fosse vacuidade (ex.: nenhum nó não-claim rastreado).
  local mut; mut="$(mktemp -d)"; trap 'rm -rf "'"${mut}"'"' RETURN
  cp "${radar}" "${mut}/mutado.sh"; _lib_beside "${mut}"
  sed -i 's/ && ntype\[id\] == "claim"//' "${mut}/mutado.sh"
  if ! grep -q 'verifiedAgainst\[id\] == "" && ntype\[id\] == "claim"' "${mut}/mutado.sh"; then
    local mout; mout="$(bash "${mut}/mutado.sh" "${fxu}" --freshness 2>&1 || true)"
    if printf '%s' "${mout}" | grep -q 'UNANCHORED: E_MEDIU' \
       && ! printf '%s' "${mout}" | grep -q 'ℹ '; then
      record_pass "kg-freshness: (k) (MUT) sem o filtro o evidence volta a ser cobrado — a guarda é load-bearing"
    else record_fail "kg-freshness: (k) (MUT)" "mutação não mudou o veredito — o filtro é vacuidade? out=${mout}"; fi
  else
    record_fail "kg-freshness: (k) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi

  # ── --freshness-tsv: a FILA de re-verificação (insumo de /meta:kg-freshness) ──────────────
  # Contrato de máquina: se as colunas variarem, o consumidor quebra em silêncio.
  local tsv; tsv="$(bash "${radar}" "${fxu}" --freshness-tsv 2>/dev/null || true)"

  # (l) forma: 11 colunas em TODA linha, e nenhuma linha vazia.
  local badcols; badcols="$(printf '%s\n' "${tsv}" | awk -F'\t' 'NF>0 && NF!=11' | wc -l)"
  if [ -n "${tsv}" ] && [ "${badcols}" = "0" ]; then
    record_pass "kg-freshness: (l) --freshness-tsv com 11 colunas em todas as linhas (contrato de máquina)"
  else record_fail "kg-freshness: (l) forma do TSV" "linhas fora do contrato: ${badcols}"; fi

  # (l2) ORDEM — a fila sai por ATENÇÃO DESCENDENTE, como o cabeçalho do bloco sempre declarou.
  # POR QUE EXISTE (achado de revisão adversarial, 2026-08-06): o comentário prometia
  # "ORDEM: atenção desc — MESMA fórmula do --radar" desde que o bloco nasceu, e a implementação
  # iterava ORDEM DE ARQUIVO — o `asorti()` só existia no --radar. O instrumento que esta casa usa
  # para medir declarado-vs-verificado tinha, ele mesmo, uma declaração não verificada, e por meses.
  # O dano não é cosmético: o consumidor corta em `--top N`, e cortar sobre ordem errada DESCARTA o
  # nó de maior atenção. Numa corrida serial, a ordem ainda decide qual worker aprende primeiro.
  local desordem
  desordem="$(printf '%s\n' "${tsv}" | awk -F'\t' 'NF==11 { if (NR>1 && $7 > prev + 0.0001) bad++; prev=$7 } END { print bad+0 }')"
  if [ "${desordem}" = "0" ]; then
    record_pass "kg-freshness: (l2) --freshness-tsv sai ordenado por atenção desc (o que o cabeçalho promete)"
  else record_fail "kg-freshness: (l2) ordem do TSV" "${desordem} par(es) fora de ordem decrescente"; fi

  # (l3) (MUT) a ordenação é LOAD-BEARING — sem o asorti a fila volta à ordem de arquivo.
  # Sem este caso, (l2) passaria por acaso em qualquer fixture cuja ordem de arquivo já coincida
  # com a de atenção — que é exatamente como o bug sobreviveu tanto tempo.
  local dmut; dmut="$(mktemp -d)"; cp "${radar}" "${dmut}/r.sh"; _lib_beside "${dmut}"
  sed -i 's/fn = asorti(att, fsorted, "@val_num_desc")/fn = 0/' "${dmut}/r.sh"
  if grep -q 'fn = 0' "${dmut}/r.sh"; then
    local mtsv; mtsv="$(bash "${dmut}/r.sh" "${fxu}" --freshness-tsv 2>/dev/null || true)"
    if [ -z "${mtsv}" ]; then
      record_pass "kg-freshness: (l3) (MUT) sem o asorti a fila some — a ordenação é load-bearing"
    else record_fail "kg-freshness: (l3) (MUT)" "mutante ainda emitiu fila: ${mtsv}"; fi
  else
    record_fail "kg-freshness: (l3) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
  rm -rf "${dmut}"

  # (m) ESCOPO — nó com verdict OK ENTRA na fila. É a decisão que carrega o fluxo: o caso que
  # o motivou (C_ancestor_cap_zeroes_floors, no grafo do M2) tem carimbo do dia, alvo declarado,
  # os três vereditos passam — e mente. Filtrar por flagado nasceria cego ao caso fundador.
  if printf '%s\n' "${tsv}" | awk -F'\t' '$1=="C_ANCORADA" && $11=="OK"' | grep -q . \
     && printf '%s\n' "${tsv}" | awk -F'\t' '$1=="C_AFIRMA" && $11=="UNANCHORED"' | grep -q .; then
    record_pass "kg-freshness: (m) a fila inclui nó com verdict OK (escopo ≠ 'o que o radar flagou')"
  else record_fail "kg-freshness: (m) escopo da fila" "C_ANCORADA(OK) e/ou C_AFIRMA(UNANCHORED) ausentes"; fi

  # (n) o que é HISTÓRIA fica fora — mesmo racional do FRESCOR humano.
  if ! printf '%s\n' "${tsv}" | awk -F'\t' '$4=="superseded" || $4=="refuted"' | grep -q .; then
    record_pass "kg-freshness: (n) superseded/refuted fora da fila (história não se re-verifica)"
  else record_fail "kg-freshness: (n) exclusão de história" "nó reconciliado apareceu na fila"; fi

  # (o) ORDENÁVEL por atenção: a coluna 7 é numérica e o topo bate com o --radar.
  local top_tsv top_radar
  # sed -n '1p' (não head -1): drena o stream até EOF, então o `sort` upstream nunca
  # leva EPIPE no fflush de saída sob `set -o pipefail` (`head` fecha o pipe cedo → corrida
  # que falha o run às vezes; sinal de campo do CI 2026-07-30). Mesmo idioma da linha abaixo.
  top_tsv="$(printf '%s\n' "${tsv}" | sort -t"$(printf '\t')" -k7 -rn | sed -n '1p' | cut -f1)"
  top_radar="$(bash "${radar}" "${fxu}" --radar 2>/dev/null | sed -n '2p' | awk '{print $2}')"
  if [ -n "${top_tsv}" ] && [ "${top_tsv}" = "${top_radar}" ]; then
    record_pass "kg-freshness: (o) topo por atenção do TSV == topo do --radar (mesma fórmula, sem drift)"
  else record_fail "kg-freshness: (o) ordenação" "tsv=${top_tsv} radar=${top_radar}"; fi

  # (p) (MUT) sem a exclusão de história, o nó reconciliado VOLTA a aparecer — prova que (n)
  # não é vacuidade (a fixture PRECISA ter um nó reconciliado para isso significar algo).
  cp "${radar}" "${mut}/mut-tsv.sh"; _lib_beside "${mut}"
  # remove só a exclusão DENTRO do bloco --freshness-tsv (a 2ª ocorrência do padrão no arquivo)
  awk '/mode == "--freshness-tsv"/{inblk=1} inblk && /nstatus\[id\] == "superseded"/{sub(/if \(nstatus\[id\] == "superseded" \|\| nstatus\[id\] == "refuted"\) continue.*$/,""); inblk=0} {print}' \
    "${radar}" > "${mut}/mut-tsv.sh"
  local mtsv; mtsv="$(bash "${mut}/mut-tsv.sh" "${fx}/superseded-not-chased.kg.yaml" --freshness-tsv 2>/dev/null || true)"
  local otsv; otsv="$(bash "${radar}" "${fx}/superseded-not-chased.kg.yaml" --freshness-tsv 2>/dev/null || true)"
  local nmut nori
  nmut="$(printf '%s\n' "${mtsv}" | awk -F'\t' 'NF==11' | wc -l)"
  nori="$(printf '%s\n' "${otsv}" | awk -F'\t' 'NF==11' | wc -l)"
  if [ "${nmut}" -gt "${nori}" ]; then
    record_pass "kg-freshness: (p) (MUT) sem a exclusão, a história volta à fila (${nori}→${nmut}) — a guarda é load-bearing"
  else record_fail "kg-freshness: (p) (MUT) exclusão de história" "mutação não mudou nada (${nori}→${nmut}) — vacuidade?"; fi

  # ── MISPLANED: coerência plane × verified_against ────────────────────────────────────────
  # Crédito: sinal de campo de um adotante (2026-07-27). Ele MEDIU 21 nós do próprio repo afirmando
  # sobre produção com evidência de leitura de código — radar VERDE o tempo todo. Escapavam pelo
  # filtro por tipo que este mesmo arquivo passou a testar horas antes: quase todos eram
  # `evidence`, o tipo que o UNANCHORED isenta. Reduzir ruído cegou o gate para outra classe.
  local fxm="${fx}/misplaned.kg.yaml"
  rc=0; out=$(bash "${radar}" "${fxm}" --freshness 2>&1) || rc=$?

  # (q) dispara no claim E no evidence — o segundo é o ponto: MISPLANED NÃO filtra por tipo.
  if [ "${rc}" -eq 0 ] \
     && grep -q 'MISPLANED: C_PROD_MAS_LEU_BRANCH' <<<"${out}" \
     && grep -q 'MISPLANED: E_PROD_MAS_LEU_COMMIT' <<<"${out}"; then
    record_pass "kg-freshness: (q) MISPLANED dispara em claim E em evidence (a contradição não depende do tipo)"
  else record_fail "kg-freshness: (q) MISPLANED" "rc=${rc} out=${out}"; fi

  # (r) os coerentes ficam quietos — inclusive `pin`, ambíguo e não-cobrado de propósito.
  if ! grep -qE 'MISPLANED: (E_PROD_MEDIU_O_VIVO|C_DEV_LEU_BRANCH|C_PROD_PIN_AMBIGUO|C_PROD_BRANCH_SUPERSEDED)' <<<"${out}"; then
    record_pass "kg-freshness: (r) PROD+deploy, DEV+branch, pin e histórico NÃO disparam (sem falso-positivo)"
  else record_fail "kg-freshness: (r) falso-positivo do MISPLANED" "out=${out}"; fi

  # (s) a fixture é íntegra — veredito sobre grafo quebrado seria vacuidade.
  rc=0; bash "${radar}" "${fxm}" --integrity --schema >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "kg-freshness: (s) a fixture do MISPLANED é íntegra"
  else record_fail "kg-freshness: (s) integridade" "rc=${rc}"; fi

  # (t) (MUT) restringindo a checagem a `claim` — como o UNANCHORED faz — o evidence VOLTA a
  # escapar. É a reprodução exata do modo-de-falha que o sinal reportou.
  cp "${radar}" "${mut}/mut-mis.sh"; _lib_beside "${mut}"
  sed -i 's/if (plane\[id\] == "PROD" \&\& verifiedAgainst\[id\] ~/if (ntype[id] == "claim" \&\& plane[id] == "PROD" \&\& verifiedAgainst[id] ~/' "${mut}/mut-mis.sh"
  if grep -q 'ntype\[id\] == "claim" && plane\[id\] == "PROD"' "${mut}/mut-mis.sh"; then
    local mmis; mmis="$(bash "${mut}/mut-mis.sh" "${fxm}" --freshness 2>&1 || true)"
    if ! printf '%s' "${mmis}" | grep -q 'MISPLANED: E_PROD_MAS_LEU_COMMIT' \
       && printf '%s' "${mmis}" | grep -q 'MISPLANED: C_PROD_MAS_LEU_BRANCH'; then
      record_pass "kg-freshness: (t) (MUT) restrito a claim, o evidence escapa — reproduz o modo-de-falha do sinal"
    else record_fail "kg-freshness: (t) (MUT)" "a restrição por tipo não mudou o veredito; out=${mmis}"; fi
  else
    record_fail "kg-freshness: (t) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
}

# ---------------------------------------------------------------------------
# Modo kg-provenance — guarda de PROVENIÊNCIA do kg-radar.sh (ITEM2): decisão VIVA sem
# NENHUMA proveniência (nem aresta TRACES_TO nem campo trace: inline) = ⚠ AVISO aditivo,
# não-HARD (não muda o exit). Como o FRESCOR, asserção por CONTEÚDO de stdout + exit 0.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Modo kg-view — REGRA 31. A lente é DERIVADA e reimplementa o parse do radar.
# A dívida dos DOIS PARSERS só é admissível porque --assert-parity a vigia; se a
# paridade não reprovar de verdade, a lente pode divergir do motor em silêncio e
# mostrar um grafo que não existe. (V3) é o teste que sustenta a dívida.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Modo site-deeplink — REGRA 35. Deep-link do repo PRIVADO em site/ dá 404 no
# público. Os dois lados: link 404 → HARD; home do repo (sem /pull|commit) e
# link interno de Provas → limpo. Cobre o trap do set -e (grep sem match não
# pode abortar o lint) rodando a guarda real via --only.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Modo vendor-scrub — REGRA 36. Nome comercial de cliente na superfície
# VENDORIZADA (o que /meta:adopt copia) viaja p/ todo adotante — cross-tenant por
# adoção. Fixture: arquivo temporário numa raiz vendorizada com um termo REAL
# derivado do members.yaml → HARD; sem ele → limpo. Termo do members.yaml, não
# hardcoded (nome no teste seria o próprio vazamento que a regra combate).
# ---------------------------------------------------------------------------
run_shell_pipefail_robustness_selftests() {
  # GUARD de classe (fix-must-become-mechanism): sob `set -o pipefail`, `sort … | head`
  # deixa o `sort` upstream levar EPIPE no fflush de saída quando o `head` fecha o pipe
  # cedo — uma corrida que reprova o run às VEZES (sinal de campo do CI 2026-07-30, exit 2
  # `sort: fflush failed: Broken pipe`). A cura é `sed -n '1p'` (drena até EOF). Este guard
  # impede a regressão do idioma frágil em qualquer script strict-mode da casa.
  local hits
  # Casa o PIPELINE frágil (o sort seguido do fechador precoce) como código real:
  #  - ignora linhas de comentário (a nota da própria cura menciona o fechador);
  #  - exige que o fechador venha seguido de opção/EOL (`-N`|fim), o que descarta as
  #    strings de mensagem deste guard (onde o token vem colado a aspas).
  # Cobre validation/ + utils/ + hooks/ + .githooks/. `sed -n` (não o fechador) por dogfood.
  hits="$(grep -rnE 'sort[^|]*\|[[:space:]]*head([[:space:]]+-|[[:space:]]*$)' \
            "${REPO_ROOT}/.claude/validation" \
            "${REPO_ROOT}/.claude/utils" \
            "${REPO_ROOT}/.claude/hooks" \
            "${REPO_ROOT}/.githooks" 2>/dev/null \
          | grep -vE ':[[:space:]]*#' || true)"
  if [ -z "${hits}" ]; then
    record_pass "shell-pipefail: nenhum pipeline sort→fechador-precoce frágil nos scripts strict-mode (drene com sed -n '1p')"
  else
    record_fail "shell-pipefail: pipeline sort→fechador-precoce frágil sob pipefail" \
      "drene com sed em vez de fechar cedo (sem EPIPE): $(printf '%s' "${hits}" | sed -n '1,3p' | tr '\n' ';')"
  fi
}

run_aside_router_selftests() {
  # GUARD do motor "Aparte do Maestro" (.claude/validation/aside-router.sh): as fixtures
  # POSITIVAS (marcador tipado no início) DEVEM rotear; as NEGATIVAS (prosa casual, marcador
  # sem ':' , palavra no meio) DEVEM ficar MUDAS. Impede regressão silenciosa do detector
  # (falso-negativo perde o roteamento; falso-positivo polui contexto em prosa comum).
  local eng="${REPO_ROOT}/.claude/validation/aside-router.sh"
  local fxdir="${REPO_ROOT}/.claude/validation/fixtures/aside" f out miss=""
  [ -f "$eng" ] || { record_pass "aside-router: motor ausente — pulado"; return; }
  for f in "$fxdir"/pos-*.txt; do
    [ -f "$f" ] || continue
    out="$(bash "$eng" detect < "$f" 2>/dev/null)"
    [ -n "$out" ] || miss="${miss} $(basename "$f")(sem-rota)"
  done
  for f in "$fxdir"/neg-*.txt; do
    [ -f "$f" ] || continue
    out="$(bash "$eng" detect < "$f" 2>/dev/null)"
    [ -z "$out" ] || miss="${miss} $(basename "$f")(falso-positivo)"
  done
  if [ -z "$miss" ]; then
    record_pass "aside-router: marcadores tipados roteiam; prosa casual fica muda (fixtures pos/neg)"
  else
    record_fail "aside-router: detector regrediu" "casos:${miss}"
  fi
}

# Modo projection-name — REGRA 30 / P6 do projection-safety.sh. A invariante do TRECHO
# PROJETADO: o que vem antes de " (" no `name:` do membro tem de ser o próprio slug.
#
# ORIGEM (2026-08-17, e é o PRESSUPOSTO da guarda que falhou, não um caso solto): a guarda de
# projeção nasceu do vazamento do console em 07-10 e mira a ANOTAÇÃO entre parênteses — o trecho
# ANTERIOR era tratado como seguro POR CONSTRUÇÃO, porque o gerador publica só ele. Um membro novo
# com nome de cliente sob NDA nesse trecho vazou para o console publicado com a guarda VERDE: o
# termo não era derivado (o próprio membro o introduzia) e a metade "segura" ninguém conferia.
#
# Os DOIS lados no mesmo conjunto, como manda o irmão projection-safety: o que DEVE reprovar (a) e
# o que NÃO pode reprovar (b, c, d) — guarda que grita em caso legítimo é guarda que se desliga.
run_projection_name_selftests() {
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  [ -f "${helper}" ] || { record_fail "projection-name" "helper ausente"; return; }
  local f out surf="${REPO_ROOT}/docs/onion/federation-console.html"
  [ -e "${surf}" ] || surf="${REPO_ROOT}/docs/evolution/federation/members.yaml"

  # (a) nome de TERCEIRO no trecho projetado → HARD NOME-PROJETADO. Este é o vazamento real.
  f="$(mktemp)"
  printf 'members:\n  - id: poc-x\n    name: Nome Comercial Alheio (rotulo — CONFIDENCIAL Acme)\n' > "${f}"
  out="$(bash "${helper}" --members "${f}" --format tsv "${surf}" 2>&1)" || true   # sob set -e, exit != 0 do helper abortaria a suíte
  if printf '%s' "${out}" | grep -q 'NOME-PROJETADO'; then
    record_pass "projection-name: (a) nome de terceiro no trecho projetado → HARD"
  else record_fail "projection-name: (a)" "nome de terceiro no trecho publicado NÃO foi pego"; fi
  rm -f "${f}"

  # (b) ISENÇÃO DECLARADA NO DADO → passa. A allowlist mora no members.yaml, não no script
  #     vendorizado (a 1ª versão a punha no script e a REGRA 36 reprovou: id de adotante em
  #     superfície que viaja para todo adotante é vazamento cross-tenant por adoção).
  f="$(mktemp)"
  printf 'members:\n  - id: poc-x\n    name: Nome Comercial Alheio (rotulo — CONFIDENCIAL Acme)\n    projection_name_exempt: true\n' > "${f}"
  out="$(bash "${helper}" --members "${f}" --format tsv "${surf}" 2>&1)" || true   # sob set -e, exit != 0 do helper abortaria a suíte
  if ! printf '%s' "${out}" | grep -q 'NOME-PROJETADO'; then
    record_pass "projection-name: (b) projection_name_exempt no dado é honrado"
  else record_fail "projection-name: (b)" "isenção declarada no membro foi ignorada"; fi
  rm -f "${f}"

  # (c) VARIAÇÃO DE CAIXA do próprio slug → passa sem isenção. É o mesmo nome, não terceiro.
  f="$(mktemp)"
  printf 'members:\n  - id: acme-slug\n    name: AcmeSlug (rotulo — CONFIDENCIAL Acme)\n' > "${f}"
  out="$(bash "${helper}" --members "${f}" --format tsv "${surf}" 2>&1)" || true   # sob set -e, exit != 0 do helper abortaria a suíte
  if ! printf '%s' "${out}" | grep -q 'NOME-PROJETADO'; then
    record_pass "projection-name: (c) variação de caixa do slug passa sem isenção"
  else record_fail "projection-name: (c)" "falso-positivo em variação de caixa do próprio slug"; fi
  rm -f "${f}"

  # (d) (MUT) COMENTÁRIO DE FIM DE LINHA não conta — o gerador lê YAML com parser e o descarta.
  #     A 1ª versão desta checagem não o descartava e acusou FALSO-POSITIVO num membro real cujo
  #     `name:` traz a anotação "# id/name públicos = SÓ <slug>". Guarda que discorda do GERADOR
  #     sobre o que é projetado está medindo outra coisa que não a superfície.
  f="$(mktemp)"
  printf 'members:\n  - id: acme-slug\n    name: acme-slug          # anotacao interna qualquer\n' > "${f}"
  out="$(bash "${helper}" --members "${f}" --format tsv "${surf}" 2>&1)" || true   # sob set -e, exit != 0 do helper abortaria a suíte
  if ! printf '%s' "${out}" | grep -q 'NOME-PROJETADO'; then
    record_pass "projection-name: (d) (MUT) comentário de fim de linha não é projeção"
  else record_fail "projection-name: (d)" "comentário YAML tratado como nome projetado"; fi
  rm -f "${f}"
}

run_vendor_scrub_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  [ -f "${helper}" ] || return 0
  local term
  term="$(bash "${helper}" --emit-terms 2>/dev/null | grep -vE '^(CONFIDENCIAL|PRIVADO)$' | head -1 || true)"
  [ -n "${term}" ] || { record_pass "vendor-scrub: sem termo derivável — nada a testar"; return; }
  local tf="${REPO_ROOT}/.claude/validation/__scrubtest__.md"
  trap 'rm -f "'"${tf}"'"' RETURN
  local out rc=0
  # (a) nome comercial real numa raiz vendorizada → HARD
  printf 'exemplo citando %s como cliente\n' "${term}" > "${tf}"
  out="$(bash "${lint}" --only="${tf}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'vendor-scrub'; then
    record_pass "vendor-scrub: (a) nome comercial na superfície vendorizada → HARD"
  else record_fail "vendor-scrub: (a)" "nome de cliente vendorizado não pego: rc=${rc}"; fi
  # (b) sem nome comercial → limpo (e grep-sem-match não aborta)
  printf 'texto generico sem nome de cliente\n' > "${tf}"
  rc=0; out="$(bash "${lint}" --only="${tf}" 2>&1)" || rc=$?
  if ! printf '%s' "${out}" | grep -q 'vendor-scrub'; then
    record_pass "vendor-scrub: (b) superfície limpa → sem HARD"
  else record_fail "vendor-scrub: (b)" "falso-positivo em texto limpo"; fi
  rm -f "${tf}"
}

# Modo moat-boundary — REGRA 61. Um manifesto de plugin publicável NÃO pode declarar fonte de
# meta-fábrica (create-*/adopt/marketplace/decouple) nem grafo privado (docs/onion/graph/*). A guarda
# vira MECANISMO (vazar o moat = HARD). Fixture: manifesto temporário no verticals/ real; RED (fonte de
# moat no array) dispara, GREEN (só fontes de capacidade) não — o padrão do vendor-scrub.
run_moat_boundary_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  local vdir="${SCRIPT_DIR}/../utils/marketplace/verticals"
  [ -d "${vdir}" ] || { record_pass "moat-boundary: sem verticals/ — nada a testar"; return; }
  local mf="${vdir}/__mbguard__.manifest.sh" out rc
  trap 'rm -f "'"${mf}"'"' RETURN
  # grep pela violação da PRÓPRIA fixture (a guarda varre TODOS os manifestos — evita contaminação)
  local sig='__mbguard__.manifest.sh: manifesto de plugin PUBLIC'
  # (a) RED abrangente — todo tipo de moat que o revisor apontou (C1): auto-evolução, federação
  #     downstream+ledger, absorb-skill (fábrica), grafo FORA de docs/onion/graph (o life-KG privado).
  cat > "${mf}" <<'RED'
PLUGIN_NAME="__mbguard__"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="fixture"
KEYWORDS=(test)
COMMANDS=(".claude/commands/meta/evolve.md" ".claude/commands/meta/federation-publish.md" ".claude/commands/meta/co-deliver.md" ".claude/commands/meta/absorb-skill.md")
DOCS=("docs/discussions/onion-pessoal-marcio/proto/marcio.kg.yaml")
UTILS=(".claude/utils/federation")
CONFORMANCE="bronze"
PROVIDES=("x")
REQUIRES=()
LOADS=()
RED
  rc=0; out="$(bash "${lint}" --only="${mf}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -qF "${sig}"; then
    record_pass "moat-boundary: (a) evolve/federação/absorb-skill/life-KG → HARD (C1 do revisor)"
  else record_fail "moat-boundary: (a)" "vazamento C1 não pego: rc=${rc}"; fi
  # (b) RED por DIRETÓRIO-PAI (C2): declarar commands/meta (dir) arrasta a fábrica; a guarda checa a
  #     EXPANSÃO, não a string — tem de pegar mesmo sem nenhum arquivo de fábrica citado literalmente.
  cat > "${mf}" <<'RED'
PLUGIN_NAME="__mbguard__"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="fixture"
KEYWORDS=(test)
COMMANDS=(".claude/commands/meta")
CONFORMANCE="bronze"
PROVIDES=("x")
REQUIRES=()
LOADS=()
RED
  rc=0; out="$(bash "${lint}" --only="${mf}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -qF "${sig}"; then
    record_pass "moat-boundary: (b) declaração por DIRETÓRIO-PAI → HARD pela expansão (C2 do revisor)"
  else record_fail "moat-boundary: (b)" "bypass por dir-pai não pego: rc=${rc}"; fi
  # (c) GREEN — capacidade + upstream (co-evolve/co-relay) + produto (create-task-structure) + dir de
  #     skill/utils limpos: NÃO dispara (o comentário que MENCIONA meta-fábrica também não).
  cat > "${mf}" <<'GREEN'
PLUGIN_NAME="__mbguard__"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="fixture cita create-vertical/adopt no comentario mas nao nos arrays"
KEYWORDS=(test)
COMMANDS=(".claude/commands/warm-up.md" ".claude/commands/meta/co-evolve.md" ".claude/commands/product/create-task-structure.md")
SKILLS=(".claude/skills/onion")
UTILS=(".claude/utils/task-manager")
CONFORMANCE="bronze"
PROVIDES=("x")
REQUIRES=()
LOADS=()
GREEN
  rc=0; out="$(bash "${lint}" --only="${mf}" 2>&1)" || rc=$?
  if ! printf '%s' "${out}" | grep -qF "${sig}"; then
    record_pass "moat-boundary: (c) capacidade+upstream+produto+dir limpos → sem HARD"
  else record_fail "moat-boundary: (c)" "falso-positivo em manifesto de capacidade limpo"; fi
  rm -f "${mf}"
}

# Modo materialize-repo — o helper materialize-marketplace-repo.sh (project-door). Monta TODOS os plugins
# publicáveis num dir-alvo self-contained (marketplace.json name=onion-plugins) e NÃO faz push (I3). O
# selftest materializa num tmp (--no-commit), afirma as invariantes e a 2ª guarda de moat por arquivo.
run_materialize_repo_selftests() {
  local helper="${SCRIPT_DIR}/../utils/marketplace/materialize-marketplace-repo.sh"
  [ -f "${helper}" ] || { record_pass "materialize-repo: helper ausente — nada a testar"; return; }
  local tgt; tgt="$(mktemp -d)/onion-plugins"
  trap 'rm -rf "'"$(dirname "${tgt}")"'"' RETURN
  local rc=0; bash "${helper}" "${tgt}" --no-commit >/dev/null 2>&1 || rc=$?
  # (a) materializa self-contained: exit 0, name público, >=2 plugins, README
  if [ "${rc}" -eq 0 ] && grep -q '"name": "onion-plugins"' "${tgt}/.claude-plugin/marketplace.json" 2>/dev/null \
     && [ "$(find "${tgt}/plugins" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | grep -c .)" -ge 2 ] \
     && [ -f "${tgt}/README.md" ]; then
    record_pass "materialize-repo: (a) repo self-contained (name onion-plugins, plugins, README)"
  else record_fail "materialize-repo: (a)" "materialize falhou (rc=${rc}) ou faltou name/plugins/README"; fi
  # (b) 2ª guarda de moat: ZERO arquivo de meta-fábrica/grafo no repo materializado
  local leak; leak="$(find "${tgt}/plugins" -type f \( -name 'create-vertical.md' -o -name 'create-command.md' \
    -o -name 'create-skill.md' -o -name 'adopt.md' -o -name 'federation-*.md' -o -name 'co-deliver.md' \
    -o -name '*.kg.yaml' \) 2>/dev/null | grep -c . || true)"
  if [ "${leak}" = "0" ]; then
    record_pass "materialize-repo: (b) zero fonte de meta-fábrica/grafo no repo público (moat intacto)"
  else record_fail "materialize-repo: (b)" "${leak} vazamento(s) de moat no repo materializado"; fi
  rm -rf "$(dirname "${tgt}")" 2>/dev/null
}

# Modo plugin-hooks-json — o assemble tem de gerar hooks/hooks.json (auto-descoberto) para os hooks
# empacotados ATIVAREM na instalação. Dogfood 2026-08-25: sem isto, install → Hooks: 0 (a guarda exit-2
# viajava inerte). Fixture: core sintético com 1 hook + settings.json ligando-o a um evento; assemble →
# hooks.json com o evento certo. (a) gerado+evento; (b) MUT: hook sem evento no settings → não registra.
run_plugin_hooks_json_selftests() {
  local asm="${SCRIPT_DIR}/../utils/marketplace/assemble-plugin.sh"
  [ -f "${asm}" ] || { record_pass "plugin-hooks-json: assemble ausente — nada a testar"; return; }
  local w; w="$(mktemp -d)"; trap 'rm -rf "'"$w"'"' RETURN
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  local src="$w/core"; mkdir -p "$src/.claude/hooks"; git -C "$src" init -q 2>/dev/null
  printf '#!/usr/bin/env bash\nexit 0\n' > "$src/.claude/hooks/my-guard.sh"; chmod +x "$src/.claude/hooks/my-guard.sh"
  printf '{ "hooks": { "PostToolUse": [ { "hooks": [ { "type":"command", "command":"bash .claude/hooks/my-guard.sh" } ] } ] } }\n' > "$src/.claude/settings.json"
  git -C "$src" add -A 2>/dev/null; git -C "$src" commit -qm init 2>/dev/null
  cat > "$w/m.manifest.sh" <<'MAN'
PLUGIN_NAME="hooktest"; PLUGIN_VERSION="0.1.0"; PLUGIN_DESC="x"; KEYWORDS=(t)
HOOKS=(".claude/hooks/my-guard.sh")
CONFORMANCE="bronze"; PROVIDES=("x"); REQUIRES=(); LOADS=()
MAN
  local dest="$w/plug"
  bash "${asm}" "$w/m.manifest.sh" "$src" "$dest" >/dev/null 2>&1
  # (a) hooks.json gerado com o evento PostToolUse apontando pro hook via CLAUDE_PLUGIN_ROOT
  if [ -f "$dest/hooks/hooks.json" ] && grep -q 'PostToolUse' "$dest/hooks/hooks.json" \
     && grep -q 'CLAUDE_PLUGIN_ROOT.*my-guard.sh' "$dest/hooks/hooks.json"; then
    record_pass "plugin-hooks-json: (a) assemble gera hooks.json com o evento do core → hook ATIVA no install"
  else record_fail "plugin-hooks-json: (a)" "hooks.json ausente ou sem evento/path correto"; fi
  # (b) hook NÃO ligado no settings do core → não entra no hooks.json (não inventa evento)
  printf '{ "hooks": {} }\n' > "$src/.claude/settings.json"; git -C "$src" add -A 2>/dev/null; git -C "$src" commit -qm nohooks 2>/dev/null
  rm -rf "$dest"; bash "${asm}" "$w/m.manifest.sh" "$src" "$dest" >/dev/null 2>&1
  if [ ! -f "$dest/hooks/hooks.json" ] || ! grep -q 'my-guard' "$dest/hooks/hooks.json" 2>/dev/null; then
    record_pass "plugin-hooks-json: (b) hook sem evento no core → NÃO registrado (não inventa evento)"
  else record_fail "plugin-hooks-json: (b)" "registrou hook sem evento — inventou"; fi
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

# REGRA 48 — referência de caminho `.claude/…` em backtick (prosa) que não resolve.
# Fixture VIVE sob .claude/ (raiz da guarda) com nome improvável, removida no RETURN — único
# jeito de exercitar a guarda REAL via --only. Dois casos: (A) reage a ref morta; (B) NÃO
# superreage aos 4 filtros de falso-positivo (kebab/fence/allowlist/válida) num só fôlego.
run_backtick_ref_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  [ -f "${lint}" ] || { record_fail "backtick-ref" "lint ausente: ${lint}"; return; }
  local tf="${REPO_ROOT}/.claude/validation/__backtickreftest__.md"
  trap 'rm -f "'"${tf}"'"' RETURN
  local out rc=0
  # (A) reage: ref kebab p/ arquivo .claude/ ausente → HARD com o token
  printf '# fixture\nCite `.claude/utils/__absent-xyz-fixture__.md` na prosa.\n' > "${tf}"
  out="$(bash "${lint}" --only="${tf}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'referência de caminho em backtick' \
     && printf '%s' "${out}" | grep -q '__absent-xyz-fixture__'; then
    record_pass "backtick-ref: (A) ref .claude/ kebab p/ arquivo ausente → HARD (ponteiro morto pego)"
  else record_fail "backtick-ref: (A)" "ref morta não virou HARD: rc=${rc}"; fi
  # (B) NÃO superreage: válida(existe) + exemplo(não-kebab) + em fence + allowlist(ausente) → 0 flag
  {
    printf '# fixture limpo\n'
    printf 'Válida: `.claude/validation/lint-artifacts.sh` (existe).\n'
    printf 'Exemplo ilustrativo: `.claude/agents/misc/MyAgent.md`.\n'
    printf 'Opcional documentada: `.claude/onion-context.yaml`.\n'
    printf '```\n`.claude/utils/__fenced-absent__.md`\n```\n'
  } > "${tf}"
  rc=0; out="$(bash "${lint}" --only="${tf}" 2>&1)" || rc=$?
  if ! printf '%s' "${out}" | grep -q 'referência de caminho em backtick'; then
    record_pass "backtick-ref: (B) válida/exemplo-não-kebab/fence/allowlist → 0 flag (os 4 filtros de FP)"
  else record_fail "backtick-ref: (B)" "falso-positivo: $(printf '%s' "${out}" | grep 'referência de caminho em backtick' | head -2)"; fi
  rm -f "${tf}"
}

run_site_deeplink_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  local site="${REPO_ROOT}/site"
  [ -d "${site}" ] || { record_pass "site-deeplink: sem site/ — nada a testar (adotante)"; return; }
  # A guarda escopa para REPO_ROOT/site — a fixture VIVE lá dentro (arquivo temporário
  # com nome improvável), removida no RETURN. É o único jeito de exercitar a guarda REAL.
  local tf="${site}/__selftest-deeplink__.html"
  trap 'rm -f "'"${tf}"'"' RETURN
  local out rc=0
  # (a) deep-link p/ repo PRIVADO → HARD
  printf '<a href="https://github.com/marciocar/onion-evolve/pull/222">PR #222</a>\n' > "${tf}"
  out="$(bash "${lint}" --only="${tf}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q '404-privado'; then
    record_pass "site-deeplink: (a) deep-link p/ repo privado em site/ → HARD"
  else record_fail "site-deeplink: (a)" "link 404 não foi pego: rc=${rc} out=${out}"; fi
  # (b) home do repo (sem /pull) + link interno → limpo (e grep-sem-match NÃO aborta o lint)
  printf '<a href="https://github.com/marciocar/onion-evolve">repo</a> <a href="/historia/migalhas/provas/">prova</a>\n' > "${tf}"
  rc=0; out="$(bash "${lint}" --only="${tf}" 2>&1)" || rc=$?
  if ! printf '%s' "${out}" | grep -q '404-privado'; then
    record_pass "site-deeplink: (b) home do repo + link interno → limpo (grep-sem-match não aborta)"
  else record_fail "site-deeplink: (b)" "falso-positivo em link permitido"; fi
  rm -f "${tf}"
}

# Modo rules-registry — REGRA 39. O gerador projeta os docstrings '# REGRA N — …' de
# lint-artifacts.sh no registro vendorizado lint-rules.md, com severidade derivada do corpo
# UNIDA ao tag declarado. As duas catracas de clareza (número duplicado, regra órfã) são
# load-bearing: sem elas a colisão 22/23 voltaria silenciosa e uma regra nova ficaria fora do mapa.
run_rules_registry_selftests() {
  local gen="${SCRIPT_DIR}/rules-registry.sh"
  local doc="${SCRIPT_DIR}/lint-rules.md"
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  [ -f "${gen}" ] || return 0
  command -v python3 >/dev/null 2>&1 || { record_skip "rules-registry: python3 ausente (skip gracioso, coerente com REGRA 39)"; return; }
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  local rc

  # (a) PARIDADE — o doc commitado bate com o gerador rodado da fonte real
  bash "${gen}" > "${tmp}/gen.md" 2>/dev/null || true
  if [ -f "${doc}" ] && diff -q "${doc}" "${tmp}/gen.md" >/dev/null 2>&1; then
    record_pass "rules-registry: (a) doc commitado em paridade com os docstrings reais"
  else record_fail "rules-registry: (a)" "lint-rules.md diverge do gerador — regenere: bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md"; fi

  # (b) fixture MENOR que o conjunto real gera limpo (categoria sem regra presente é omitida)
  printf '# REGRA 1 — Frontmatter de agente [HARD]\n# previne: z\ncheck_a() {\n  violation "HARD" "x" "y"\n}\n# REGRA 6 — Filenames kebab [SOFT]\n# previne: z\ncheck_b() {\n  violation "SOFT" "x" "y"\n}\n' > "${tmp}/mini.sh"
  rc=0; RULES_LINT_SRC="${tmp}/mini.sh" bash "${gen}" > "${tmp}/mini.md" 2>/dev/null || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q '^| 1 |' "${tmp}/mini.md" && grep -q '^| 6 |' "${tmp}/mini.md"; then
    record_pass "rules-registry: (b) gera de um lint fixture (subconjunto) sem exigir o conjunto real"
  else record_fail "rules-registry: (b)" "gerador não tolerou fixture menor (rc=${rc})"; fi

  # (c) NÚMERO DUPLICADO → exit 2 (a catraca que impede a colisão 22/23 de voltar)
  printf '# REGRA 1 — a\n# previne: z\ncheck_a() {\n  violation "HARD" "x" "y"\n}\n# REGRA 1 — b\n# previne: z\ncheck_c() {\n  violation "HARD" "x" "y"\n}\n' > "${tmp}/dup.sh"
  rc=0; RULES_LINT_SRC="${tmp}/dup.sh" bash "${gen}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then
    record_pass "rules-registry: (c) número de REGRA duplicado → gerador falha (exit 2)"
  else record_fail "rules-registry: (c)" "duplicata não detectada (rc=${rc}, esperado 2)"; fi

  # (d) REGRA ÓRFÃ (sem categoria) → exit 2 (a catraca contra regra nova fora do mapa)
  #     tem previne (senão a catraca de previne dispararia antes, mascarando o teste da categoria)
  printf '# REGRA 97 — regra sem lar\n# previne: z\ncheck_x() {\n  violation "HARD" "x" "y"\n}\n' > "${tmp}/orf.sh"
  rc=0; RULES_LINT_SRC="${tmp}/orf.sh" bash "${gen}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then
    record_pass "rules-registry: (d) REGRA sem categoria → gerador falha (exit 2)"
  else record_fail "rules-registry: (d)" "regra órfã não detectada (rc=${rc}, esperado 2)"; fi

  # (e) SEVERIDADE = corpo ∪ tag — guarda de severidade dinâmica + tag declarada → HARD + SOFT
  printf '# REGRA 29 — dinamica [HARD + SOFT]\n# previne: z\ncheck_d() {\n  violation "${sev}" "x" "y"\n  violation "SOFT" "b" "c"\n}\n' > "${tmp}/sev.sh"
  if RULES_LINT_SRC="${tmp}/sev.sh" bash "${gen}" 2>/dev/null | grep -qE '^\| 29 \|.*HARD \+ SOFT'; then
    record_pass "rules-registry: (e) severidade = corpo ∪ tag (dinâmica declarada vira HARD + SOFT)"
  else record_fail "rules-registry: (e)" "união corpo∪tag não produziu HARD + SOFT"; fi

  # (g) REGRA SEM '# previne:' → exit 2 (a catraca de clareza nova — toda regra declara o modo-de-falha)
  printf '# REGRA 1 — sem previne [HARD]\ncheck_np() {\n  violation "HARD" "x" "y"\n}\n' > "${tmp}/np.sh"
  rc=0; RULES_LINT_SRC="${tmp}/np.sh" bash "${gen}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then
    record_pass "rules-registry: (g) REGRA sem '# previne:' → gerador falha (exit 2)"
  else record_fail "rules-registry: (g)" "regra sem previne não detectada (rc=${rc}, esperado 2)"; fi

  # (f) GUARD verde no estado real (--only escopa ao doc)
  if bash "${lint}" --only="${doc}" 2>&1 | grep -q 'OK ✓'; then
    record_pass "rules-registry: (f) REGRA 39 verde no estado real (--only lint-rules.md)"
  else record_fail "rules-registry: (f)" "REGRA 39 acusou o estado real (deveria estar em paridade)"; fi
}

# Modo onion-version-tracked — REGRA 40. Um adotante (role: adopted) TEM que trackear o .onion-version;
# senão o clone perde o marcador e todos os guards de adotante desligam (achado de campo 2026-07-22, o
# maestro pegou clonando fresco). Sandbox git mínimo — completa porque a REGRA 16 já não aborta com env
# vazio (fix irmão da mesma sessão).
run_onion_version_tracked_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  [ -f "${lint}" ] || return 0
  command -v git >/dev/null 2>&1 || { record_skip "onion-version-tracked: git ausente (skip gracioso)"; return; }
  local sb; sb="$(mktemp -d)"; sb="$(cd "${sb}" && pwd -P)"; trap 'rm -rf "'"${sb}"'"' RETURN
  mkdir -p "${sb}/.claude/validation"
  cp "${lint}" "${sb}/.claude/validation/"
  printf 'framework: onion-evolve\nrole: adopted\n' > "${sb}/.claude/.onion-version"
  git -C "${sb}" init -q
  git -C "${sb}" add .claude/validation >/dev/null 2>&1
  git -C "${sb}" -c user.name=t -c user.email=t@t commit -q -m x >/dev/null 2>&1
  local out
  # (a) role: adopted + stamp UNTRACKED → HARD
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'onion-version NÃO trackeado'; then
    record_pass "onion-version-tracked: (a) adotante com stamp UNTRACKED → HARD"
  else record_fail "onion-version-tracked: (a)" "stamp untracked não pego — o clone perderia o role"; fi
  # (b) força-add → TRACKED → sem violação
  git -C "${sb}" add -f .claude/.onion-version >/dev/null 2>&1
  git -C "${sb}" -c user.name=t -c user.email=t@t commit -q -m s >/dev/null 2>&1
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if ! printf '%s' "${out}" | grep -q 'onion-version NÃO trackeado'; then
    record_pass "onion-version-tracked: (b) stamp TRACKED → sem violação"
  else record_fail "onion-version-tracked: (b)" "falso-positivo com stamp trackeado"; fi
  # (c) role: source + UNTRACKED → guarda PULA (é o gate de papel, não o de tracked)
  git -C "${sb}" rm --cached .claude/.onion-version >/dev/null 2>&1
  printf 'framework: onion-evolve\nrole: source\n' > "${sb}/.claude/.onion-version"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if ! printf '%s' "${out}" | grep -q 'onion-version NÃO trackeado'; then
    record_pass "onion-version-tracked: (c) role: source + untracked → guarda pula (gate de papel)"
  else record_fail "onion-version-tracked: (c)" "disparou em role: source (não-adotante)"; fi

  # (d) role: hub + UNTRACKED → HARD (o hub também é stamp de adoção que o clone precisa trackear)
  printf 'framework: acme-adopter\nrole: hub\n' > "${sb}/.claude/.onion-version"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'onion-version NÃO trackeado'; then
    record_pass "onion-version-tracked: (d) role: hub + untracked → HARD (hub trackeia o stamp)"
  else record_fail "onion-version-tracked: (d)" "não pegou hub untracked (o clone do hub perderia o papel)"; fi
  # (e) FONTE-DESACOPLADA (role: source + decoupled_from) + UNTRACKED → HARD (também carrega stamp derivado).
  # O stamp já está untracked (a case c fez rm --cached e a d só reescreveu o conteúdo) — só sobrescrevo.
  printf 'framework: x\nrole: source\ndecoupled_from: https://github.com/marciocar/onion-evolve.git\n' > "${sb}/.claude/.onion-version"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'onion-version NÃO trackeado'; then
    record_pass "onion-version-tracked: (e) fonte-desacoplada + untracked → HARD (o stamp derivado precisa viajar)"
  else record_fail "onion-version-tracked: (e)" "não pegou decoupled untracked"; fi
}

# Modo hub-role-guard — costura HUB (2026-07-23): um hub É adotante para os role-guards que pulam os
# links/plugins core-only (ausentes-por-desenho na superfície vendorizada). Sem isso, o clone de um hub
# vira 156 falso-HARD — dogfood-de-fronteira: a sessão de um adotante promoveu a hub e o lint explodiu.
# Modo inventory-adopter-scope — check_inventory_total_drift é adopter-aware: num repo DERIVADO
# (role: adopted|hub|decoupled) SÓ os docs Onion vendorizados são varridos p/ contagens; os docs de
# PRODUTO do adotante (docs/specs, …) são EXCLUÍDOS ('100+ agentes' ali é do produto dele). Sinal de
# campo: um adotante 2026-07-24 (doc de produto do alvo). Testa: (a) adotante → doc de produto
# NÃO flagado; (b) source → o MESMO doc É flagado (sem scoping); (c) adotante → doc Onion-owned AINDA
# flagado (o scoping não desliga a regra p/ os docs certos). [[fix-must-become-mechanism]]
run_inventory_adopter_scope_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"; local inv="${SCRIPT_DIR}/inventory.sh"
  [ -f "${lint}" ] || return 0
  [ -f "${inv}" ] || { record_skip "inventory-adopter-scope: inventory.sh ausente → pulado"; return; }
  local sb; sb="$(mktemp -d)"; sb="$(cd "${sb}" && pwd -P)"; trap 'rm -rf "'"${sb}"'"' RETURN
  mkdir -p "${sb}/.claude/validation" "${sb}/.claude/agents/development" "${sb}/.claude/commands/meta" \
           "${sb}/.claude/skills/foo" "${sb}/docs/specs" "${sb}/docs/onion" "${sb}/docs/knowledge-base/concepts"
  cp "${SCRIPT_DIR}"/*.sh "${sb}/.claude/validation/" 2>/dev/null
  printf -- '---\nname: foo\ndescription: x\n---\n# s\n' > "${sb}/.claude/skills/foo/SKILL.md"
  printf '# kb\n' > "${sb}/docs/knowledge-base/concepts/k.md"
  printf -- '---\nname: foo\ndescription: x\nmodel: sonnet\n---\nrole\n' > "${sb}/.claude/agents/development/foo.md"
  printf -- '---\ndescription: x\n---\n# c\n' > "${sb}/.claude/commands/meta/c.md"
  local msg='contagem aproximada de agentes' n

  # (a) role: adopted + doc de PRODUTO (docs/specs) com '100+ agentes' → EXCLUÍDO (não flaga)
  printf 'framework: h\nrole: adopted\n' > "${sb}/.claude/.onion-version"
  printf '# Capability Registry\nO produto orquestra 100+ agentes mencionáveis.\n' > "${sb}/docs/specs/capability.md"
  n="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 | grep -c "${msg}" || true)"
  if [ "${n}" = 0 ]; then record_pass "inventory-adopter-scope: (a) adotante → doc de produto não flagado"
  else record_fail "inventory-adopter-scope: (a)" "adotante flagou ${n}× o doc de produto (falso-positivo de adotante não fechou)"; fi

  # (b) role: source + o MESMO doc → É flagado (no source não há scoping de adotante)
  printf 'framework: h\nrole: source\n' > "${sb}/.claude/.onion-version"
  n="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 | grep -c "${msg}" || true)"
  if [ "${n}" -ge 1 ]; then record_pass "inventory-adopter-scope: (b) source → mesmo doc flagado (regra ativa no core)"
  else record_fail "inventory-adopter-scope: (b)" "source não flagou — o scoping vazou p/ o core (regra desligada)"; fi

  # (c) role: adopted + doc ONION-OWNED (docs/onion) com '100+ agentes' → AINDA flagado (whitelist varre)
  rm -f "${sb}/docs/specs/capability.md"
  printf '# Nota Onion\nO Onion tem 100+ agentes especializados.\n' > "${sb}/docs/onion/nota.md"
  printf 'framework: h\nrole: adopted\n' > "${sb}/.claude/.onion-version"
  n="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 | grep -c "${msg}" || true)"
  if [ "${n}" -ge 1 ]; then record_pass "inventory-adopter-scope: (c) adotante → doc Onion-owned ainda flagado (scoping não over-exclui)"
  else record_fail "inventory-adopter-scope: (c)" "scoping excluiu ATÉ o doc Onion-owned (over-exclusão)"; fi
}

run_hub_role_guard_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  [ -f "${lint}" ] || return 0
  command -v git >/dev/null 2>&1 || { record_skip "hub-role-guard: git ausente (skip gracioso)"; return; }
  local sb; sb="$(mktemp -d)"; sb="$(cd "${sb}" && pwd -P)"; trap 'rm -rf "'"${sb}"'"' RETURN
  mkdir -p "${sb}/.claude/validation" "${sb}/docs/knowledge-base/concepts"
  cp "${lint}" "${SCRIPT_DIR}/projection-safety.sh" "${sb}/.claude/validation/"
  printf '# KB\nVer [x](../../analysis/nao-existe.md).\n' > "${sb}/docs/knowledge-base/concepts/x.md"
  git -C "${sb}" init -q
  git -C "${sb}" add -A >/dev/null 2>&1
  git -C "${sb}" -c user.name=t -c user.email=t@t commit -q -m x >/dev/null 2>&1
  local n
  # (a) role: hub → link core-only PULADO (hub = adotante para o role-guard de _scan_relative_links)
  printf 'framework: h\nrole: hub\n' > "${sb}/.claude/.onion-version"
  n="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 | grep -c 'não resolve' || true)"
  if [ "${n}" = 0 ]; then record_pass "hub-role-guard: (a) role: hub → link core-only pulado (hub = adotante)"
  else record_fail "hub-role-guard: (a)" "hub flagou ${n} link(s) core-only — o clone do hub viraria falso-HARD em massa"; fi
  # (b) role: source → link core-only FLAGADO (no source os docs existem; o guard NÃO pula)
  printf 'framework: h\nrole: source\n' > "${sb}/.claude/.onion-version"
  n="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 | grep -c 'não resolve' || true)"
  if [ "${n}" -ge 1 ]; then record_pass "hub-role-guard: (b) role: source → link core-only flagado (guard não pula no source)"
  else record_fail "hub-role-guard: (b)" "source não flagou o link ausente (o role-guard pula sempre?)"; fi
  # (c) FONTE-DESACOPLADA (role: source + decoupled_from) → PULA (veio da superfície vendorizada, sem docs core-only)
  printf 'framework: h\nrole: source\ndecoupled_from: https://github.com/marciocar/onion-evolve.git\n' > "${sb}/.claude/.onion-version"
  n="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 | grep -c 'não resolve' || true)"
  if [ "${n}" = 0 ]; then record_pass "hub-role-guard: (c) fonte-desacoplada (decoupled_from) → link core-only pulado (é source derivada)"
  else record_fail "hub-role-guard: (c)" "decoupled_from flagou ${n} link(s) — o clone da fonte-desacoplada viraria falso-HARD"; fi
}

# Modo family-topology — REGRA 41 (2026-07-23): a SSOT-topologia no KG resolve a procedimentos REAIS. É a
# fonte que as faces de CONDUÇÃO (wizard/onboarding/scaffold) projetam — se mentir, os fluxos de ajuda
# dessincronizam. Testa: transição ativa com trace morto → HARD; papel ativo fora de roles.yaml → HARD;
# gated (status: open) com trace morto → IGNORADO (não é procedimento ainda).
run_family_topology_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  [ -f "${lint}" ] || return 0
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    record_skip "family-topology: sem python+yaml (skip gracioso, coerente com REGRA 41)"; return; fi
  local sb; sb="$(mktemp -d)"; sb="$(cd "${sb}" && pwd -P)"; trap 'rm -rf "'"${sb}"'"' RETURN
  mkdir -p "${sb}/.claude/validation" "${sb}/.claude/utils/marketplace" "${sb}/docs/onion/graph"
  cp "${lint}" "${SCRIPT_DIR}/projection-safety.sh" "${sb}/.claude/validation/"
  printf 'version: 1\nroles:\n  source:\n    base: []\n  hub:\n    base: []\n' > "${sb}/.claude/utils/marketplace/roles.yaml"
  local KG="${sb}/docs/onion/graph/onion-family-topology-2026-07.kg.yaml"
  _gen_topo() { cat > "${KG}" <<'K'
meta: {id: t, schema_version: "1", date: 2026-07-23}
nodes:
  - {id: ROLE_hub, node_type: entity, status: confirmed, label: hub}
  - {id: TX_adopt, node_type: decision, trace: .claude/validation/lint-artifacts.sh, status: confirmed, label: adopt}
  - {id: TX_decouple, node_type: decision, trace: docs/NAO-EXISTE.md, status: open, label: gated}
edges:
  - {from: TX_adopt, to: ROLE_hub, edge_type: DEPENDS_ON}
K
  }
  local out
  # (a) SSOT válido + gated com trace morto IGNORADO → sem violação de topologia
  _gen_topo
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${KG}" 2>&1 || true)"
  if ! printf '%s' "${out}" | grep -q 'topologia/'; then
    record_pass "family-topology: (a) transição ativa resolve + papel em roles.yaml + gated ignorado → limpo"
  else record_fail "family-topology: (a)" "acusou um SSOT válido (ou não ignorou o gated)"; fi
  # (b) transição ATIVA com trace morto → HARD (o SSOT mentiria p/ o wizard)
  _gen_topo; sed -i 's#lint-artifacts.sh, status: confirmed#NAO-EXISTE.sh, status: confirmed#' "${KG}"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${KG}" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'topologia/TRACE-MORTO'; then
    record_pass "family-topology: (b) transição ativa com trace morto → HARD (anti-dessincronização)"
  else record_fail "family-topology: (b)" "não pegou trace morto numa transição ativa"; fi
  # (c) papel ATIVO fora de roles.yaml → HARD
  _gen_topo; sed -i 's/id: ROLE_hub/id: ROLE_banana/' "${KG}"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${KG}" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'topologia/PAPEL-ORFAO'; then
    record_pass "family-topology: (c) papel ativo fora de roles.yaml → HARD"
  else record_fail "family-topology: (c)" "não pegou papel órfão vs roles.yaml"; fi
}

# Modo decouple-source — transição 'desacoplar' (2026-07-23): um adotado/hub vira fonte soberana própria
# (role: source + decoupled_from). Testa: dry-run NÃO toca; --confirm re-carimba; source recusa.
run_decouple_source_selftests() {
  local dec="${SCRIPT_DIR}/../utils/adopt/decouple-source.sh"
  [ -f "${dec}" ] || return 0
  command -v git >/dev/null 2>&1 || { record_skip "decouple-source: git ausente (skip gracioso)"; return; }
  local sb; sb="$(mktemp -d)"; trap 'rm -rf "'"${sb}"'"' RETURN
  mkdir -p "${sb}/.claude"
  git -C "${sb}" init -q
  printf 'framework: cliente-x\nsource_commit: abc123\nrole: hub\nadopted_from: https://github.com/marciocar/onion-evolve.git\n' > "${sb}/.claude/.onion-version"
  # (a) DRY-RUN (sem --confirm) → não altera o stamp
  bash "${dec}" "${sb}" >/dev/null 2>&1 || true
  if grep -q '^role: hub$' "${sb}/.claude/.onion-version"; then
    record_pass "decouple-source: (a) dry-run NÃO toca no stamp (role: hub intacto)"
  else record_fail "decouple-source: (a)" "dry-run alterou o stamp"; fi
  # (b) --confirm → role: source + decoupled_from (preserva a origem), commitado
  bash "${dec}" "${sb}" --confirm >/dev/null 2>&1 || true
  if grep -q '^role: source$' "${sb}/.claude/.onion-version" \
     && grep -q '^decoupled_from: https://github.com/marciocar/onion-evolve.git$' "${sb}/.claude/.onion-version" \
     && ! grep -q '^adopted_from:' "${sb}/.claude/.onion-version"; then
    record_pass "decouple-source: (b) --confirm → role: source + decoupled_from (linhagem cortada, origem preservada)"
  else record_fail "decouple-source: (b)" "$(cat "${sb}/.claude/.onion-version")"; fi
  # (c) já é source → recusa (exit 1)
  if ! bash "${dec}" "${sb}" --confirm >/dev/null 2>&1; then
    record_pass "decouple-source: (c) já é fonte → recusa (não re-desacopla)"
  else record_fail "decouple-source: (c)" "aceitou desacoplar uma fonte"; fi
}

# ── SITIO UNICO do fator de status, e a paridade que precisa olhar PESO ──────────────────────────
# Medido em 2026-08-09: a copia do `statusFactor` que vivia dentro do kg-view NAO conhecia
# `drifted`/`unverifiable` (entraram no enum em 2026-08-06) e devolvia -1, clampado a 0 — PESO ZERO
# nos nos que acabaram de provar que o mundo andou. E o `--assert-parity` nao via, porque comparava
# CONTAGEM: as duas lentes concordavam em quantos nos existem e discordavam em QUAL era o mais
# urgente, que e a unica pergunta que o painel responde.
run_kg_status_factor_selftests() {
  local view="${SCRIPT_DIR}/kg-view.sh" radar="${SCRIPT_DIR}/kg-radar.sh"
  local lib="${SCRIPT_DIR}/lib/status-factor.awk"
  if [ ! -f "${lib}" ]; then record_fail "status-factor" "sitio unico ausente: ${lib}"; return; fi
  local d out rc g

  # (a) SITIO UNICO de fato: nenhum script do repo define a funcao por conta propria
  # ⚠️ EXCLUI ESTA BANCADA: o padrao procurado aparece NESTA linha, entao a busca casava a si mesma
  # e o caso acusava o proprio teste. Mesma armadilha do `sed` cujo padrao vive no arquivo intacto,
  # que ja derrubou tres guardas-da-guarda nesta casa.
  local copies; copies=$(git -C "${REPO_ROOT}" grep -l 'function statusFactor' -- '*.sh' 2>/dev/null \
                         | grep -v 'lint-selftest.sh' | grep -c . || true)
  if [ "${copies}" -eq 0 ]; then
    record_pass "status-factor: (a) ZERO copies em script — a funcao vive so em lib/status-factor.awk"
  else record_fail "status-factor: (a)" "${copies} script(s) ainda definem statusFactor: $(git -C "${REPO_ROOT}" grep -l 'function statusFactor' -- '*.sh' | grep -v 'lint-selftest.sh' | tr '\n' ' ')"; fi

  # (b) FAIL-LOUD, nunca default: sem a lib, os dois consumidores saem 2 com mensagem no stderr.
  #     Fonte ausente jamais vira aprovacao (P0 da REGRA 30) — e este ramo ja disparou de verdade,
  #     quando o plugin foi montado sem a lib no manifesto.
  d="$(mktemp -d)"; mkdir -p "$d/lib"
  cp "${radar}" "${view}" "$d/" 2>/dev/null
    # ⚠️ AQUI A LIB **NAO** VAI: a ausencia dela E o teste. Uma varredura automatica minha inseriu
    # `_lib_beside` neste ponto e teria destruido o caso em silencio — o `fail-loud` nunca dispararia
    # e o (b) passaria por vacuidade. Varredura mecanica nao sabe qual copia e deliberada.
  # GRAFO VALIDO de proposito: o `kg-view` valida o ARGUMENTO antes de checar a lib, entao um
  # /dev/null dispararia erro de USO (tambem exit 2) e o caso mediria a coisa errada.
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: N\n    node_type: claim\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 1.0\n    label: "x"\nedges: []\n' > "$d/t.kg.yaml"
  local broken=""
  for g in kg-radar kg-view; do
    # `out=$(cmd)` sob `set -e` ABORTA quando cmd sai != 0 — e este caso EXISTE para ver o exit 2.
    #
    # ⚠️ O MODO TEM DE EXISTIR NO CONSUMIDOR, e a PALAVRA cobrada tem de ser a DA GUARDA.
    # A 1a versao chamava `--integrity` nos dois e cobrava a string `status-factor.awk`. Passada
    # adversarial mediu o vacuo: `--integrity` nao existe no `kg-view`, que sai 2 por MODO INVALIDO,
    # e o nome do arquivo aparecia na mensagem do proprio `cat` — entao apagar a guarda INTEIRA do
    # kg-view mantinha o caso VERDE. Cobrar `AUSENTE` (palavra que so a guarda escreve) num modo
    # que o consumidor REALMENTE tem fecha as duas fugas.
    case "${g}" in kg-view) local mode="--json" ;; *) local mode="--integrity" ;; esac
    rc=0; out="$(bash "$d/${g}.sh" "$d/t.kg.yaml" "${mode}" 2>&1)" || rc=$?
    { [ "${rc}" -eq 2 ] && printf '%s' "${out}" | grep -q 'AUSENTE' && printf '%s' "${out}" | grep -q 'status-factor.awk'; } \
      || broken="${broken} ${g}(rc=${rc})"
  done
  rm -rf "$d"
  if [ -z "${broken}" ]; then
    record_pass "status-factor: (b) sem a lib os dois consumidores saem 2 NOMEANDO o arquivo (fail-loud, nunca default)"
  else record_fail "status-factor: (b)" "consumidor silencioso sem a lib:${broken}"; fi

  # (c) PARIDADE POR VETOR — a lente que reintroduz o defeito ORIGINAL (`unverifiable` -> -1) REPROVA.
  #     ⚠️ O MUTANTE E A LENTE, NUNCA A LIB COMPARTILHADA: com sitio unico, mutar a lib muta os DOIS
  #     motores, eles voltam a concordar e o caso passa por vacuo. Por isso a lente le a lib mutada
  #     do seu proprio dir e o radar aponta para a canonica.
  #     ⚠️ E o `rm -rf` vem DEPOIS de provar: a 1a versao apagava o tmp antes, e `cmp` contra arquivo
  #     apagado devolve 2 — a guarda-da-guarda nº1 ficava morta por construcao.
  # ⚠️ FIXTURE SINTETICA (2026-08-30): a 1a versao usava um grafo VIVO como insumo
  # (vps-shared-tools, "o grafo com no unverifiable") — e o censo de backlog flipou o ULTIMO
  # `unverifiable` daquele arquivo, matando a prova por vacuo no CI (mutante = original quando
  # a classe nao ocorre). Fixture viva e emprestimo com prazo: o caso agora SINTETIZA o proprio
  # grafo, como o (d) ja fazia.
  if true; then
    d="$(mktemp -d)"; mkdir -p "$d/lib"; cp "${view}" "$d/"
    g="$d/unv.kg.yaml"
    printf 'meta:\n  id: t-unv\n  schema_version: "1"\nnodes:\n  - id: C_A\n    node_type: claim\n    layer: domain\n    plane: DEV\n    status: unverifiable\n    impact: 4\n    confidence: 0.8\n    label: "no unverifiable sintetico para a prova de paridade"\n  - id: C_B\n    node_type: claim\n    layer: domain\n    plane: DEV\n    status: confirmed\n    impact: 3\n    confidence: 0.9\n    label: "vizinho para dar grau"\nedges:\n  - from: C_A\n    to: C_B\n    edge_type: SUPPORTS\n' > "$g"
    sed 's/if (s == "unverifiable") return 1.0/if (s == "unverifiable") return -1/' "${lib}" > "$d/lib/status-factor.awk"
    local rc_int rc_mut
    # `cmd; rc=$?` mata a suite sob `set -e` — quinta vez nesta sessao. Use `|| rc=$?`.
    rc_int=0; bash "${view}" "$g" --assert-parity >/dev/null 2>&1 || rc_int=$?
    rc_mut=0
    ( cd "$d" && sed -i "s#\${HERE}/kg-radar.sh#${radar}#" kg-view.sh
      bash ./kg-view.sh "$g" --assert-parity >/dev/null 2>&1 ) || rc_mut=$?
    _prove_mutation "status-factor: (c) paridade por VETOR — lente que zera \`unverifiable\` REPROVA" \
                    "${lib}" "$d/lib/status-factor.awk" "${rc_int}" "${rc_mut}"
    rm -rf "$d"
  fi

  # (d) O `on:` CONTA NO GRAU nos DOIS motores. Drift de parser REAL, achado ao estender a paridade
  #     aos 58 grafos: a lente parseava `eon[]` e nunca o usava. Correlacao perfeita — os 5 grafos
  #     que reprovaram eram os 5 que usam `on:`; os 53 sem `on:` passaram.
  d="$(mktemp -d)"; mkdir -p "$d/lib"; cp "${view}" "${radar}" "$d/"; cp "${lib}" "$d/lib/"
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: EV_X\n    node_type: event\n    layer: domain\n    plane: DEV\n    status: confirmed\n    impact: 4\n    confidence: 1.0\n    label: "evento so alcancado por on:"\n  - id: A\n    node_type: entity\n    layer: domain\n    plane: DEV\n    status: confirmed\n    impact: 1\n    confidence: 1.0\n    label: "a"\n  - id: B\n    node_type: entity\n    layer: domain\n    plane: DEV\n    status: confirmed\n    impact: 1\n    confidence: 1.0\n    label: "b"\nedges:\n  - from: A\n    to: B\n    edge_type: TRANSITIONS\n    on: EV_X\n' > "$d/on.kg.yaml"
  rc=0; bash "$d/kg-view.sh" "$d/on.kg.yaml" --assert-parity >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "status-factor: (d) o campo \`on:\` conta no GRAU nos dois motores (drift de parser fechado)"
  else record_fail "status-factor: (d)" "divergencia de grau em grafo com \`on:\` — a lente voltou a ignorar eon[] (rc=${rc})"; fi
  rm -rf "$d"

  # (e) A paridade RODA EM GRAFO SEM LENTE e em GRAFO NAO-VERDE. Duas fugas medidas juntas:
  #     · o portao so a chamava onde ja havia lente (1 de 58), e naquele 1 o defeito curado e
  #       INVISIVEL (zero nos `drifted`/`unverifiable`);
  #     · e o bloco de peso vinha DEPOIS do early-exit que sai 0 quando o radar nao reporta
  #       contagens — como ele so as imprime quando esta VERDE, UM no orfao desarmava a guarda.
  d="$(mktemp -d)"; mkdir -p "$d/lib"; cp "${view}" "$d/"; cp "${lib}" "$d/lib/"
  sed -i "s#\${HERE}/kg-radar.sh#${radar}#" "$d/kg-view.sh"
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: A_ALTO\n    node_type: claim\n    plane: DEV\n    status: drifted\n    impact: 4\n    confidence: 1.0\n    label: "a"\n  - id: B_BAIXO\n    node_type: claim\n    plane: DEV\n    status: unverifiable\n    impact: 4\n    confidence: 1.0\n    label: "b"\n  - id: C_ORFAO\n    node_type: claim\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 1.0\n    label: "grau 0 — deixa o grafo NAO-VERDE"\nedges:\n  - from: A_ALTO\n    to: B_BAIXO\n    edge_type: SUPPORTS\n' > "$d/orfao.kg.yaml"
  local rc_v rc_m
  rc_v=0; bash "$d/kg-view.sh" "$d/orfao.kg.yaml" --assert-parity >/dev/null 2>&1 || rc_v=$?
  cp "$d/kg-view.sh" "$d/intacto.sh"
  sed -i 's/sf = statusFactor(nstatus\[id\]); if (sf < 0) sf = 0/sf = statusFactor(nstatus[id]) * 0.5; if (sf < 0) sf = 0/' "$d/kg-view.sh"
  rc_m=0; bash "$d/kg-view.sh" "$d/orfao.kg.yaml" --assert-parity >/dev/null 2>&1 || rc_m=$?
  _prove_mutation "status-factor: (e) a paridade morde em grafo NAO-VERDE (1 no orfao nao a desarma)" \
                  "$d/intacto.sh" "$d/kg-view.sh" "${rc_v}" "${rc_m}"
  rm -rf "$d"

  # (f) VETOR, NAO SOMA. O caso que a soma NAO pega por construcao: trocar os pesos de dois nos
  #     inverte a ordem de urgencia e a soma continua identica (10.40+8.00 == 8.00+10.40).
  #     A guarda antiga imprimia ✅ enquanto a projecao dizia que o menos urgente era o mais urgente.
  d="$(mktemp -d)"; mkdir -p "$d/lib"; cp "${radar}" "$d/"; cp "${lib}" "$d/lib/"
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: A_UM\n    node_type: claim\n    plane: DEV\n    status: drifted\n    impact: 4\n    confidence: 1.0\n    label: "a"\n  - id: B_DOIS\n    node_type: claim\n    plane: DEV\n    status: unverifiable\n    impact: 4\n    confidence: 1.0\n    label: "b"\nedges:\n  - from: A_UM\n    to: B_DOIS\n    edge_type: SUPPORTS\n' > "$d/c.kg.yaml"
  local sum_a sum_b vec_a vec_b
  vec_a="$(bash "$d/kg-radar.sh" "$d/c.kg.yaml" --weights-tsv 2>/dev/null)"
  sum_a="$(printf '%s\n' "${vec_a}" | awk '{s+=$2} END{printf "%.2f", s}')"
  sed -i 's/"drifted") return 1.3/"drifted") return 1.0/; s/"unverifiable") return 1.0/"unverifiable") return 1.3/' "$d/lib/status-factor.awk"
  vec_b="$(bash "$d/kg-radar.sh" "$d/c.kg.yaml" --weights-tsv 2>/dev/null)"
  sum_b="$(printf '%s\n' "${vec_b}" | awk '{s+=$2} END{printf "%.2f", s}')"
  if [ -n "${sum_a}" ] && [ "${sum_a}" = "${sum_b}" ] && [ "${vec_a}" != "${vec_b}" ]; then
    record_pass "status-factor: (f) o VETOR ve o que a SOMA nao ve — cancelamento (soma ${sum_a} nos dois, vetor diferente)"
  else record_fail "status-factor: (f)" "o cenario de cancelamento nao se formou: soma ${sum_a}/${sum_b}, vetor $([ "${vec_a}" = "${vec_b}" ] && echo igual || echo diferente)"; fi
  rm -rf "$d"

  # (g) LIB CORROMPIDA (nao so ausente) culpa o INSTRUMENTO, nunca o grafo. O fail-loud original so
  #     checava EXISTENCIA; uma lib vazia fazia o awk morrer e a paridade reportava como se o grafo
  #     fosse o problema — mesma familia de "fonte ausente vira aprovacao" que o P0 da REGRA 30 proibe.
  d="$(mktemp -d)"; mkdir -p "$d/lib"; cp "${view}" "${radar}" "$d/"; : > "$d/lib/status-factor.awk"
  cp "${REPO_ROOT}/docs/onion/graph/fios-abertos.kg.yaml" "$d/g.kg.yaml" 2>/dev/null \
    || printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: A\n    node_type: claim\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 1.0\n    label: "a"\n  - id: B\n    node_type: claim\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 1.0\n    label: "b"\nedges:\n  - from: A\n    to: B\n    edge_type: SUPPORTS\n' > "$d/g.kg.yaml"
  rc=0; out="$(bash "$d/kg-view.sh" "$d/g.kg.yaml" --assert-parity 2>&1)" || rc=$?
  if [ "${rc}" -ne 0 ] && printf '%s' "${out}" | grep -qiE 'motor nao emitiu|AUSENTE'; then
    record_pass "status-factor: (g) lib VAZIA reprova culpando o INSTRUMENTO, nao o grafo"
  else record_fail "status-factor: (g)" "lib corrompida passou ou culpou o grafo (rc=${rc}): ${out}"; fi
  rm -rf "$d"

  # (h) O BUNDLE FECHA O GRAFO DE DEPENDENCIAS. O fail-loud do (b) protege quem RODA o script; este
  #     protege quem o RECEBE. Um manifesto que leva `kg-radar.sh` sem `lib/status-factor.awk`
  #     montava limpo e passava no lint — o plugin so morria no ambiente do adotante, longe de quem
  #     publicou. Foi curado A MAO nos dois manifestos quando aconteceu; agora e aresta de construcao.
  local asm="${REPO_ROOT}/.claude/utils/marketplace/assemble-plugin.sh"
  local mf="${REPO_ROOT}/.claude/utils/marketplace/verticals/onion-work-tools.manifest.sh"
  if [ ! -f "${asm}" ] || [ ! -f "${mf}" ]; then record_skip "status-factor: (h) assembler/manifesto ausente"; else
    d="$(mktemp -d)"
    sed 's#^\s*"\.claude/validation/lib/status-factor\.awk".*$##' "${mf}" > "$d/sem-lib.manifest.sh"
    local rc_ok rc_sem dirty_before dirty_after
    rc_ok=0;  bash "${asm}" "${mf}"                  >/dev/null 2>&1 || rc_ok=$?
    # ⚠️ ABORTAR SEM ESTRAGAR. A 1a versao desta guarda desistia DEPOIS de copiar: o destino ficava
    #    em ruinas (21 arquivos sujos, `plugin.json` deletado) e o lint acusava "fora de sincronia".
    #    Guarda que aborta destruindo e pior que o defeito que recusa — por isso o caso mede o
    #    ESTADO DO DESTINO, nao so o exit code.
    dirty_before="$(git -C "${REPO_ROOT}" status --porcelain plugins/ 2>/dev/null | wc -l)"
    rc_sem=0; bash "${asm}" "$d/sem-lib.manifest.sh" >/dev/null 2>&1 || rc_sem=$?
    dirty_after="$(git -C "${REPO_ROOT}" status --porcelain plugins/ 2>/dev/null | wc -l)"
    if [ "${dirty_before}" != "${dirty_after}" ]; then
      record_fail "status-factor: (h) recusa DESTRUTIVA" "o assembler abortou DEPOIS de tocar no destino: plugins/ passou de ${dirty_before} para ${dirty_after} arquivos sujos"
    else
      _prove_mutation "status-factor: (h) manifesto SEM a lib ABORTA a montagem, sem tocar no destino" \
                      "${mf}" "$d/sem-lib.manifest.sh" "${rc_ok}" "${rc_sem}"
    fi
    rm -rf "$d"
  fi
}

run_kg_view_selftests() {
  local view="${SCRIPT_DIR}/kg-view.sh"
  local tmp out rc
  [ -f "${view}" ] || return 0
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN

  cat > "${tmp}/v.kg.yaml" <<'KGEOF'
meta:
  id: fixture-view
  schema_version: "1"
nodes:
  - id: C_UM
    node_type: claim
    plane: DEV
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "primeira afirmacao"
  - id: E_UM
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 1.0
    label: "evidencia que sustenta"
edges:
  - from: E_UM
    to: C_UM
    edge_type: SUPPORTS
KGEOF

  # (V1) --json é JSON legível por parser real e as contagens batem com a fonte.
  out="$(bash "${view}" "${tmp}/v.kg.yaml" --json 2>/dev/null)"
  if printf '%s' "${out}" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["node_count"]==2 and d["edge_count"]==1' 2>/dev/null; then
    record_pass "kg-view: (V1) --json é JSON válido com contagens corretas (2 nós, 1 aresta)"
  else record_fail "kg-view: (V1)" "JSON inválido ou contagens erradas: ${out}"; fi

  # (V2) DETERMINISMO — caminho relativo e absoluto produzem saída IDÊNTICA.
  # Sem isto a lente "driftaria" só por causa de quem a invocou e a REGRA 31
  # reprovaria para sempre (defeito real, achado pelo guard na 1a execução).
  ( cd "${tmp}" && bash "${view}" "v.kg.yaml" --markdown > "${tmp}/rel.md" 2>/dev/null )
  bash "${view}" "${tmp}/v.kg.yaml" --markdown > "${tmp}/abs.md" 2>/dev/null
  if diff -q "${tmp}/rel.md" "${tmp}/abs.md" >/dev/null 2>&1; then
    record_pass "kg-view: (V2) saída idêntica por caminho relativo e absoluto (determinismo)"
  else record_fail "kg-view: (V2)" "a lente muda conforme o caminho de invocação — drift eterno"; fi

  # (V3) paridade VERDE no grafo são.
  if bash "${view}" "${tmp}/v.kg.yaml" --assert-parity >/dev/null 2>&1; then
    record_pass "kg-view: (V3) paridade com o kg-radar em grafo são"
  else record_fail "kg-view: (V3)" "paridade falhou num grafo válido"; fi

  # (V4) MUTATION TEST — quebra a âncora de nó da LENTE (não do radar) e prova
  # que --assert-parity REPROVA. É o que torna admissível ter dois parsers: se
  # este teste não pegasse, a divergência apareceria só num gráfico errado.
  # O mutante precisa do kg-radar.sh AO LADO — senão o que a guarda mede é a
  # ausência do motor, não a divergência de parse (foi o que aconteceu na 1a
  # versão, e revelou o fail-open que o kg-view.sh agora fecha).
  cp "${SCRIPT_DIR}/kg-radar.sh" "${tmp}/kg-radar.sh"; _lib_beside "${tmp}"
  sed 's|section == "nodes" && /\^\[\[:space:\]\]+- id:/|section == "nodes" \&\& /^ZZNOMATCHZZ/|' \
      "${view}" > "${tmp}/mutated.sh"
  if ! bash "${tmp}/mutated.sh" "${tmp}/v.kg.yaml" --assert-parity >/dev/null 2>&1; then
    record_pass "kg-view: (V4) MUTATION — parser divergente ⇒ --assert-parity REPROVA (a dívida é vigiada)"
  else record_fail "kg-view: (V4)" "parser mutado passou na paridade — a guarda não vigia nada"; fi

  # (V5) FAIL-LOUD — sem o kg-radar.sh ao lado, a paridade NÃO pode ser afirmada.
  # Antes desta guarda o script saía 0 ("não verificável") e virava aprovação de nada.
  rm -f "${tmp}/kg-radar.sh"
  if ! bash "${tmp}/mutated.sh" "${tmp}/v.kg.yaml" --assert-parity >/dev/null 2>&1; then
    record_pass "kg-view: (V5) motor ausente ⇒ paridade REPROVA (não vira verde por ausência)"
  else record_fail "kg-view: (V5)" "sem kg-radar.sh a paridade passou — fail-open"; fi

  # (V6) CONTRATO DO CONSOLE RICO — o --json carrega os campos que o encoding
  # epistêmico consome (impact, confidence, layer, verified_at/against no nó; on
  # na aresta). Sem eles o kg-console.sh cairia mudo para opacidade/freshness.
  # Trava o contrato de dados de que a projeção rica depende.
  cat > "${tmp}/w.kg.yaml" <<'KGEOF'
meta:
  id: fixture-view6
  schema_version: "1"
nodes:
  - id: C_UM
    node_type: claim
    plane: DEV
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "primeira afirmacao"
  - id: E_UM
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 1.0
    verified_at: 2026-07-29
    verified_against: endpoint-vivo
    label: "evidencia que sustenta"
edges:
  - from: E_UM
    to: C_UM
    edge_type: SUPPORTS
KGEOF
  out="$(bash "${view}" "${tmp}/w.kg.yaml" --json 2>/dev/null)"
  if printf '%s' "${out}" | python3 -c '
import json,sys
d=json.load(sys.stdin)
for n in d["nodes"]:
    assert all(k in n for k in ("i","c","ly","va","vg")), "campo de nó ausente: %r" % sorted(n)
for e in d["edges"]:
    assert "on" in e, "campo on ausente na aresta"
e=[n for n in d["nodes"] if n["id"]=="E_UM"][0]
assert e["va"]=="2026-07-29" and e["vg"]=="endpoint-vivo", "verified_* não propagou: %r" % e
assert e["i"]==3 and abs(e["c"]-1.0)<0.01, "impact/confidence não propagou: %r" % e
' 2>/dev/null; then
    record_pass "kg-view: (V6) --json carrega impact/confidence/layer/verified_*/on (contrato do console rico)"
  else record_fail "kg-view: (V6)" "campos do encoding epistêmico ausentes no --json: ${out}"; fi
}

# ---------------------------------------------------------------------------
# Modo kg-scope — `--scope` do gate de proveniência (insumo do /meta:kg backfill).
#
# A proteção que estes casos guardam é ESTRUTURAL, não conselho: avaliar um escopo
# ALHEIO contra o baseline CANÔNICO faria toda entrada do baseline virar ÓRFÃ (o
# documento não está no novo escopo) e todo documento do novo escopo virar
# HARD-novo. Num adotante com passivo populado seriam dezenas de violações falsas
# no primeiro uso — e gate que cospe falso é gate desligado, que é o modo de falha
# que a catraca inteira existe para evitar. Por isso `--scope` sem `--baseline`
# entra em modo EXPLORATÓRIO.
# ---------------------------------------------------------------------------
run_kg_scope_selftests() {
  local repo out rc
  repo="$(_prov_make_repo)"
  trap 'rm -rf "${repo}"' RETURN
  mkdir -p "${repo}/docs/outro-corpus"
  printf '# fora do escopo canonico\n' > "${repo}/docs/outro-corpus/alheio.md"

  # (S1) --scope troca a raiz: o corpus alheio é medido, o canônico não entra.
  # mesma classe do defeito de 2026-08-17: `cmd; rc=$?` aborta a suíte sob `set -e` se o script
  # algum dia passar a sair != 0 neste caminho. Latente, corrigido de passagem.
  rc=0; out="$(bash "${repo}/.claude/validation/kg-provenance-coverage.sh" "${repo}" --scope docs/outro-corpus 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q 'EXPLORATÓRIA' \
     && printf '%s' "${out}" | grep -q 'docs/outro-corpus/alheio.md' \
     && ! printf '%s' "${out}" | grep -q 'docs/analysis/novo.md'; then
    record_pass "kg-scope: (S1) --scope mede a raiz alheia e NÃO arrasta o escopo canônico"
  else record_fail "kg-scope: (S1)" "rc=${rc} out=${out}"; fi

  # (S2) exploratório NÃO cobra catraca, mesmo com baseline canônico presente:
  #      nenhuma entrada do baseline pode virar ÓRFÃ/OBSOLETA por causa do escopo.
  _prov_run "${repo}" --scope docs/outro-corpus
  if [ "${_PROV_RC}" -eq 0 ] \
     && ! printf '%s' "${_PROV_OUT}" | grep -q 'BASELINE-ORFA' \
     && ! printf '%s' "${_PROV_OUT}" | grep -q 'BASELINE-OBSOLETA' \
     && ! printf '%s' "${_PROV_OUT}" | grep -q 'HARD'; then
    record_pass "kg-scope: (S2) exploratório não produz órfã/obsoleta/HARD contra o baseline canônico"
  else record_fail "kg-scope: (S2)" "escopo alheio contaminou a catraca canônica: rc=${_PROV_RC} out=${_PROV_OUT}"; fi

  # (S3) com --baseline EXPLÍCITO a catraca é armada no escopo novo: doc sem nó
  #      e fora daquele baseline volta a ser HARD (o modo exploratório não é uma
  #      porta dos fundos permanente).
  printf '# baseline do outro corpus\n' > "${repo}/.claude/validation/outro-baseline.txt"
  _prov_run "${repo}" --scope docs/outro-corpus --baseline .claude/validation/outro-baseline.txt
  if printf '%s' "${_PROV_OUT}" | grep -q 'docs/outro-corpus/alheio.md' \
     && printf '%s' "${_PROV_OUT}" | grep -qE '^HARD'; then
    record_pass "kg-scope: (S3) --scope + --baseline explícito ARMA a catraca no escopo novo"
  else record_fail "kg-scope: (S3)" "esperava HARD para doc novo sob baseline explícito: out=${_PROV_OUT}"; fi

  # (S4) MUTATION TEST — desfaz a condição que liga o modo exploratório. Sem ela,
  #      o escopo alheio cai no caminho da catraca canônica e o dano aparece
  #      (órfãs em massa e/ou HARD). Se NADA mudar, (S2) não estava provando nada.
  sed 's/^  EXPLORATORY=1$/  EXPLORATORY=0/' \
      "${repo}/.claude/validation/kg-provenance-coverage.sh" > "${repo}/.claude/validation/mutated.sh"
  out="$(bash "${repo}/.claude/validation/mutated.sh" "${repo}" --scope docs/outro-corpus --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | grep -qE 'BASELINE-ORFA|BASELINE-OBSOLETA|^HARD'; then
    record_pass "kg-scope: (S4) MUTATION — sem o modo exploratório o escopo alheio CONTAMINA a catraca; a proteção é load-bearing"
  else record_fail "kg-scope: (S4)" "com a proteção desfeita nada mudou — (S2) não prova nada: out=${out}"; fi
}

# ---------------------------------------------------------------------------
# Modo projection-safety — REGRA 30. Nome comercial de membro privado não sai do
# repo privado. Origem: incidente 2026-07-10 (o console público vazou nome + marcador
# verbatim); a correção viveu como convenção LOCAL em federation-console.sh até
# 2026-07-21, quando virou guarda compartilhada.
#
# Os DOIS lados no mesmo conjunto: o que DEVE reprovar (a,b,c) e o que NÃO pode
# reprovar (d,e,f) — senão "consertar" seria matar a guarda por descrédito. Guarda
# que grita lobo em menção legítima é guarda desligada, e guarda desligada é NO-OP.
#
# (b) é o caso que a 1ª versão do helper NÃO pegava: o casamento era sensível a caixa
# e o vazamento real passa MINÚSCULO dentro de identificador (lição de campo da leva 3
# da modelagem: nome de cliente vazou para o `id:` de um nó, não só para o label).
# P2 contradizia P4 e só o teste de injeção expôs — por isso (MUT) ataca essa condição.
# Fixtures temporários self-contained (não vêm do manifest) + cleanup via trap.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Modo federation-projection — REGRA 33. Mailbox-aware: nome do PRÓPRIO membro no
# PRÓPRIO mailbox é permitido; cross-tenant e compartilhado reprovam; members.yaml
# (fonte) e _processed/ (entregue) ficam fora do gate. Os DOIS lados no mesmo
# conjunto — o falso-positivo que mataria a guarda (nome próprio) é tão testado
# quanto o vazamento que ela existe para pegar.
# ---------------------------------------------------------------------------
run_federation_projection_selftests() {
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  local tmp
  [ -f "${helper}" ] || return 0
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  mkdir -p "${tmp}/fed/outbox/acme/_processed" "${tmp}/fed/outbox/openly/_processed"
  cat > "${tmp}/fed/members.yaml" <<'MEOF'
members:
  - id: acme
    name: acme (AcmeCorp — CONFIDENCIAL, ver adr.md)
  - id: openly
    name: openly (Projeto Aberto — sem marcador)
MEOF
  local m="--members ${tmp}/fed/members.yaml"
  _fed() { bash "${helper}" --federation --format tsv ${m} "${tmp}/fed" 2>/dev/null | grep -c HARD; }

  # (a) PRÓPRIO — AcmeCorp no mailbox de acme → NÃO reprova (não vaza; guarda não grita lobo)
  printf 'nota interna da AcmeCorp\n' > "${tmp}/fed/outbox/acme/msg.md"
  if [ "$(_fed)" -eq 0 ]; then
    record_pass "federation-projection: (a) nome do próprio membro no próprio mailbox → permitido"
  else record_fail "federation-projection: (a)" "falso-positivo no próprio mailbox — guarda viraria descartável"; fi

  # (b) CRUZADO — AcmeCorp no mailbox de openly → HARD (openly aprende o nome confidencial de acme)
  printf 'sobre a AcmeCorp\n' > "${tmp}/fed/outbox/openly/msg.md"
  if [ "$(_fed)" -ge 1 ]; then
    record_pass "federation-projection: (b) nome cruzando para mailbox alheio → HARD"
  else record_fail "federation-projection: (b)" "vazamento cross-tenant não pego"; fi
  rm -f "${tmp}/fed/outbox/openly/msg.md"

  # (c) COMPARTILHADO — AcmeCorp no CHANGELOG (lido por todos) → HARD
  printf 'ledger cita AcmeCorp\n' > "${tmp}/fed/CHANGELOG.md"
  if [ "$(_fed)" -ge 1 ]; then
    record_pass "federation-projection: (c) nome em artefato compartilhado → HARD"
  else record_fail "federation-projection: (c)" "vazamento no ledger compartilhado não pego"; fi

  # (d) _processed — nome cruzado num arquivo ENTREGUE → fora do gate (a casa não reescreve o passado)
  rm -f "${tmp}/fed/CHANGELOG.md"
  printf 'entregue: sobre a AcmeCorp\n' > "${tmp}/fed/outbox/openly/_processed/old.md"
  if [ "$(_fed)" -eq 0 ]; then
    record_pass "federation-projection: (d) _processed (entregue) fica fora do gate — histórico não se reescreve"
  else record_fail "federation-projection: (d)" "gate mordeu histórico entregue"; fi

  # (MUT) desfeita a exceção do PRÓPRIO mailbox, (a) passa a reprovar — prova que a
  # distinção mailbox-aware é load-bearing (sem ela a guarda cai no chapado que mata).
  rm -f "${tmp}/fed/outbox/openly/_processed/old.md"
  sed 's/\[ "${mid}" = "${owner}" \] && continue/false \&\& continue/' "${helper}" > "${tmp}/mut.sh"
  local n; n="$(bash "${tmp}/mut.sh" --federation --format tsv ${m} "${tmp}/fed" 2>/dev/null | grep -c HARD)"
  if [ "${n}" -ge 1 ]; then
    record_pass "federation-projection: (MUT) sem a exceção mailbox-aware o nome próprio reprova — a distinção é load-bearing"
  else record_fail "federation-projection: (MUT)" "desfeita a exceção, nada mudou — o teste não prova a distinção"; fi
}

run_projection_safety_selftests() {
  local helper="${SCRIPT_DIR}/projection-safety.sh"
  local tmp
  [ -f "${helper}" ] || return 0
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  mkdir -p "${tmp}/surface"

  # members.yaml de fixture: um membro PRIVADO (com marcador) e um PÚBLICO (sem).
  # Nomes INVENTADOS — a fixture não carrega nome de cliente real.
  cat > "${tmp}/members.yaml" <<'MEOF'
members:
  - id: acme-adopter
    name: acme-adopter (AcmeCorp — CONFIDENCIAL, ver algum-adr.md)
    role: standalone
  - id: openly-public
    name: openly-public (Projeto Aberto — materiais educacionais)
    role: consumer
MEOF

  _ps() {  # $1 = conteúdo da superfície → rc do helper
    printf '%s' "$1" > "${tmp}/surface/index.html"
    bash "${helper}" --members "${tmp}/members.yaml" "${tmp}/surface" >/dev/null 2>&1
  }

  # (a) nome comercial em PROSA → reprova
  if ! _ps '<p>parceiro AcmeCorp lancou</p>'; then
    record_pass "projection-safety: (a) nome comercial em prosa → HARD"
  else record_fail "projection-safety: (a)" "esperava rc=1 para nome comercial em prosa"; fi

  # (b) nome MINÚSCULO dentro de IDENTIFICADOR → reprova (P4; o defeito original)
  if ! _ps '<article id="post-acmecorp-x">ok</article>'; then
    record_pass "projection-safety: (b) nome minúsculo dentro de identificador → HARD (P2×P4)"
  else record_fail "projection-safety: (b)" "vazamento minúsculo em identificador ESCAPOU — é o defeito da 1ª versão"; fi

  # (c) marcador em CAIXA ALTA → reprova
  if ! _ps '<p>registro CONFIDENCIAL do maestro</p>'; then
    record_pass "projection-safety: (c) marcador de confidencialidade → HARD"
  else record_fail "projection-safety: (c)" "esperava rc=1 para marcador em caixa alta"; fi

  # (d) palavra comum "confidencial" MINÚSCULA → NÃO reprova (P2: marcador é literal)
  if _ps '<p>tratamos o material como confidencial</p>'; then
    record_pass "projection-safety: (d) palavra comum minúscula NÃO é marcador (sem falso-positivo)"
  else record_fail "projection-safety: (d)" "falso-positivo: 'confidencial' em prosa é palavra do português"; fi

  # (e) id PÚBLICO do membro → NÃO reprova (a defesa é excluir ids, não a caixa)
  if _ps '<p>o adotante acme-adopter atualizou</p>'; then
    record_pass "projection-safety: (e) id público do membro NÃO reprova (sem falso-positivo)"
  else record_fail "projection-safety: (e)" "falso-positivo no id público — a guarda viraria descartável"; fi

  # (f) membro NÃO-marcado → NÃO reprova (só o marcador torna sensível — P1)
  if _ps '<p>veja o Projeto Aberto</p>'; then
    record_pass "projection-safety: (f) membro sem marcador NÃO é sensível (P1)"
  else record_fail "projection-safety: (f)" "falso-positivo: membro público sem marcador virou sensível"; fi

  # (P0) fonte ausente REPROVA — nunca verde silencioso
  printf '<p>limpo</p>' > "${tmp}/surface/index.html"
  if ! bash "${helper}" --members "${tmp}/nao-existe.yaml" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (P0) fonte ausente → HARD, não verde silencioso"
  else record_fail "projection-safety: (P0)" "sem members.yaml a guarda passou verde — proteção fantasma"; fi

  # (P0-bis) ADOTANTE — repo SEM diretório de federação: ausência é NORMAL, não
  # registro quebrado. Silêncio (rc=0). Sem esta distinção a guarda reprovava
  # HARD em TODO adotante que atualizasse e travava o pre-commit dele — achado
  # em campo no update de 2026-07-21, mesma classe do baseline de cobertura que
  # também teria viajado e explodido o gate do adotante.
  mkdir -p "${tmp}/adotante"
  printf '<p>limpo</p>' > "${tmp}/surface/index.html"
  if bash "${helper}" --members "${tmp}/adotante/docs/evolution/federation/members.yaml" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (P0-bis) repo SEM federação → silêncio, não HARD (não trava o adotante)"
  else record_fail "projection-safety: (P0-bis)" "adotante sem registro de federação foi reprovado — trava o pre-commit dele"; fi

  # (P5) members SEM marcador algum ⇒ lista vazia ⇒ REPROVA (anti NO-OP)
  cat > "${tmp}/members-nomarker.yaml" <<'MEOF'
members:
  - id: only-public
    name: only-public (Coisa Publica)
MEOF
  if ! bash "${helper}" --members "${tmp}/members-nomarker.yaml" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (P5) derivação vazia → HARD (NO-OP não é aprovação)"
  else record_fail "projection-safety: (P5)" "lista vazia passou verde — a guarda seria NO-OP para sempre"; fi

  # (MUT) MUTATION TEST — desfaz a condição central (casamento de NOME insensível a
  # caixa) e prova que o caso (b) FALHA. Se (b) continuasse pegando com a mutação, o
  # teste não seria load-bearing e a proteção de identificador seria ilusória.
  sed 's/grep -qiF -- "${term}"/grep -qF -- "${term}"/g; s/grep -ciF -- "${term}"/grep -cF -- "${term}"/g' \
      "${helper}" > "${tmp}/mutated.sh"
  printf '<article id="post-acmecorp-x">ok</article>' > "${tmp}/surface/index.html"
  if bash "${tmp}/mutated.sh" --members "${tmp}/members.yaml" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (MUT) condição desfeita ⇒ (b) escapa — o teste é load-bearing"
  else record_fail "projection-safety: (MUT)" "com a condição desfeita o caso (b) ainda reprovou — o teste não prova nada"; fi

  # ── #7 do relay — GATE CLIENT-SAFE GENÉRICO (`--terms <lista>`) ──────────────
  # O adotante declara os PRÓPRIOS termos sensíveis (nomes de cliente) e gateia um
  # artefato antes de cruzar a fronteira. Reusa run_audit (uma verdade só). Termos
  # INVENTADOS — a fixture não carrega nome de cliente real.
  printf 'AcmeCorp\nProjeto-Fantasma\n' > "${tmp}/meus-termos.txt"

  # (T1) artefato que VAZA um termo declarado → HARD
  printf '# doc\nA AcmeCorp aprovou.\n' > "${tmp}/surface/index.html"
  if ! bash "${helper}" --terms "${tmp}/meus-termos.txt" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (T1) --terms declarado + artefato que vaza → HARD"
  else record_fail "projection-safety: (T1)" "termo declarado presente não reprovou — o gate client-safe não vigia"; fi

  # (T2) artefato client-safe → OK (exit 0)
  printf '# doc\nO cliente aprovou.\n' > "${tmp}/surface/index.html"
  if bash "${helper}" --terms "${tmp}/meus-termos.txt" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (T2) --terms declarado + artefato limpo → OK"
  else record_fail "projection-safety: (T2)" "artefato sem termo sensível reprovou — falso-positivo"; fi

  # (T3) P0 na lista declarada: arquivo de termos ausente → HARD (não verde por ausência)
  printf '# doc\nlimpo\n' > "${tmp}/surface/index.html"
  if ! bash "${helper}" --terms "${tmp}/nao-existe.txt" "${tmp}/surface" >/dev/null 2>&1; then
    record_pass "projection-safety: (T3) --terms ausente → HARD (P0, mesma disciplina do members)"
  else record_fail "projection-safety: (T3)" "sem lista de termos a guarda passou verde — proteção fantasma"; fi
}

# Guardas do modo --state (a fila de abertos) — irmão do --radar.
#
# POR QUE EXISTE: a 1ª versão do modo ordenava TODOS os `open` por atenção e ficou 51% redundante
# com o --radar (num grafo, 100%) — medido antes de commitar. A cura foi EXCLUIR o top-10 do radar
# por construção. Estes testes existem para que essa exclusão não se perca: sem ela o modo volta a
# ser vista filtrada do que já se via, e ninguém notaria.
# ── `--open-tsv` · a FILA COMPLETA de trabalho aberto, e a DENYLIST que o `--state` não tinha ──
# Bloco nascido da medição que fundou a onda: 584 nós de trabalho aberto em 46 grafos, e o único
# modo de leitura mostrava SETE — porque o `--state` exclui o top-10 do radar (correto lá) e trunca
# em 7 linhas (display humano). E porque era ALLOWLIST (`nstatus[id] != "open"`): quando `drifted` e
# `unverifiable` entraram no enum em 2026-08-06, a fila ficou cega justamente para o que acabou de
# provar que o mundo andou. Medido no corpus real ANTES de escrever: no grafo da VPS, o nó de MAIOR
# atenção pendente (`D_email_plus_logto_connector`, 8.0, `unverifiable`) NÃO aparecia no `--state`.
run_kg_open_queue_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local fx="${FIX_DIR}/kg-reconcile/open-queue.kg.yaml"
  if [ ! -f "${fx}" ]; then record_fail "kg-fila" "fixture ausente: ${fx}"; return; fi
  local out st d mut out_int out_mut rc_intact rc_mutant

  # ⚠️ Esta bancada roda com `set -euo pipefail` (linha 41). Captura-se a saída ANTES de grepar, e
  # nunca `cmd; rc=$?` — as duas armadilhas custaram três defeitos em 2026-08-08.

  # (a) FRONTEIRA — os 3 status de TRABALHO entram; os 4 FECHADOS ficam fora. Os fechados têm
  #     impact 5 de propósito na fixture: se a denylist virar allowlist frouxa, eles aparecem.
  out="$(bash "${radar}" "${fx}" --open-tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '
        $5=="open"||$5=="drifted"||$5=="unverifiable" {viv++}
        $5=="confirmed"||$5=="done"||$5=="superseded"||$5=="refuted" {morto++}
        END{exit !(viv==3 && morto==0)}'; then
    record_pass "kg-fila: (a) os 3 status de trabalho entram (open/drifted/unverifiable), os 4 fechados ficam fora"
  else record_fail "kg-fila: (a)" "fronteira errada: $(printf '%s' "${out}" | cut -f5 | sort | uniq -c | tr '\n' ' ')"; fi

  # (b) ORDEM desc por atenção — quem consome fila corta em `--top N`, e corte sobre ordem errada
  #     descarta o de MAIOR peso. É a mesma cicatriz que o `--freshness-tsv` já pagou.
  if printf '%s' "${out}" | awk -F'\t' 'NR>1 && $8+0 > prev+0 {bad=1} {prev=$8} END{exit bad?1:0}'; then
    record_pass "kg-fila: (b) ordenada por attention DESC"
  else record_fail "kg-fila: (b)" "fora de ordem: $(printf '%s' "${out}" | cut -f8 | tr '\n' ' ')"; fi

  # (c) a 1a coluna e o ARQUIVO — sem ela o id sozinho nao localiza nada num corpus de 57 grafos,
  #     e a fila cross-grafo (que e o consumidor) fica inutil.
  if printf '%s' "${out}" | awk -F'\t' -v F="${fx}" '$1!=F{bad=1} END{exit (bad||NR==0)?1:0}'; then
    record_pass "kg-fila: (c) 1a coluna e o arquivo de origem (a fila do corpus e o laco de quem chama)"
  else record_fail "kg-fila: (c)" "coluna de arquivo ausente ou errada: $(printf '%s' "${out}" | head -1 | cut -f1)"; fi

  # ⚠️ A FIXTURE DE (d)-(f) PRECISA SER GRANDE, e isso e calibragem medida, nao estetica: o `--state`
  # EXCLUI o top-10 do radar por construcao. Na 1a escrita deste bloco usei 7 e 10 nos — o radar
  # engoliu todos, o `--state` exibiu ZERO, e o caso (d) PASSOU com `nstate=0 <= 7`. Passe vacuo, na
  # mesma sessao em que eu construi o `_prove_mutation` para caca-los. Com 22 nos (12 de attention
  # alta que enchem o radar + os 2 de reconciliacao no meio + 8 baixos), o `--state` exibe 7 e
  # trunca — que e o comportamento que estes casos existem para medir.
  d="$(mktemp -d)"
  { printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n'
    for i in $(seq 1 12); do printf '  - id: H_%02d\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 5\n    confidence: 1.0\n    label: "alto"\n' "$i"; done
    printf '  - id: N_DRIFTED\n    node_type: claim\n    plane: DEV\n    status: drifted\n    impact: 3\n    confidence: 1.0\n    verified_at: 2026-08-05\n    verified_against: x\n    label: "reconciliacao devida"\n'
    printf '  - id: N_UNVERIFIABLE\n    node_type: claim\n    plane: DEV\n    status: unverifiable\n    impact: 3\n    confidence: 1.0\n    verified_at: 2026-08-05\n    verified_against: x\n    label: "mensurabilidade aberta"\n'
    for i in $(seq 1 8); do printf '  - id: L_%02d\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 1.0\n    label: "baixo"\n' "$i"; done
    printf 'edges:\n'
    for i in $(seq 2 12); do printf '  - from: H_%02d\n    edge_type: SUPPORTS\n    to: H_01\n' "$i"; done
    printf '  - from: N_DRIFTED\n    edge_type: SUPPORTS\n    to: H_01\n  - from: N_UNVERIFIABLE\n    edge_type: SUPPORTS\n    to: H_01\n'
    for i in $(seq 1 8); do printf '  - from: L_%02d\n    edge_type: SUPPORTS\n    to: H_01\n' "$i"; done
  } > "$d/g.kg.yaml"

  # (d) NAO TRUNCA — a razao de o modo existir.
  out="$(bash "${radar}" "$d/g.kg.yaml" --open-tsv 2>/dev/null || true)"
  st="$(bash "${radar}" "$d/g.kg.yaml" --state 2>/dev/null || true)"
  local nfila nstate
  nfila=$(printf '%s' "${out}" | grep -c . || true)
  nstate=$(printf '%s' "${st}" | grep -cE '^ +[0-9.]+ +' || true)
  if [ "${nstate}" -eq 0 ]; then
    record_fail "kg-fila: (d)" "FIXTURE MORTA: o --state exibiu ZERO, entao 'a fila mostra mais que o --state' passaria por vacuidade"
  elif [ "${nfila}" -eq 22 ] && [ "${nstate}" -eq 7 ]; then
    record_pass "kg-fila: (d) fila emite os 22; o --state exibe 7 e trunca — nao truncar E a razao de o modo existir"
  else record_fail "kg-fila: (d)" "fila=${nfila} (esperado 22) state=${nstate} (esperado 7)"; fi

  # (e) A CURA DA ALLOWLIST no `--state`: `drifted`/`unverifiable` sao trabalho e tem de APARECER.
  #     Medido no corpus real antes de escrever: o no de MAIOR attention pendente do grafo da VPS
  #     (`unverifiable`, 8.0) nao aparecia — a fila de abertos era cega para reconciliacao devida.
  if printf '%s' "${st}" | grep -q 'N_DRIFTED' && printf '%s' "${st}" | grep -q 'N_UNVERIFIABLE'; then
    record_pass "kg-fila: (e) o --state mostra drifted/unverifiable (a allowlist os perdia em silencio)"
  else record_fail "kg-fila: (e)" "a fila de abertos segue cega para reconciliacao devida: ${st}"; fi

  # (g) STATUS FORA DO ENUM — o caso que separa DENYLIST de allowlist, e que o Elenxo desta branch
  #     mostrou faltar: com (a)-(f) so, um mutante `s == "open" || s == "drifted" ||
  #     s == "unverifiable"` (allowlist EQUIVALENTE ao denylist para os 7 status conhecidos) passava
  #     6/6. So um valor NOVO os distingue.
  #     E nao basta ENTRAR: o clamp `sf < 0 → 0` mandava o no para o FIM da fila ordenada, que e
  #     onde o `--top N` corta. Fail-visible que entrega invisibilidade por afundamento.
  { printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n'
    printf '  - id: X_TYPO\n    node_type: claim\n    plane: DEV\n    status: blocked\n    impact: 5\n    confidence: 1.0\n    label: "typo no status"\n'
    printf '  - id: N_BAIXO\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 1\n    confidence: 1.0\n    label: "baixo"\n'
    printf 'edges:\n  - from: X_TYPO\n    edge_type: SUPPORTS\n    to: N_BAIXO\n'
  } > "$d/typo.kg.yaml"
  out="$(bash "${radar}" "$d/typo.kg.yaml" --open-tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '
        $2=="X_TYPO" {viu=1; att=$8+0; ver=$11}
        END{exit !(viu && att>0 && ver=="STATUS-DESCONHECIDO")}' \
     && printf '%s' "${out}" | head -1 | cut -f2 | grep -qx 'X_TYPO'; then
    record_pass "kg-fila: (g) status FORA do enum entra, SOBE (nao afunda) e traz veredito STATUS-DESCONHECIDO"
  else record_fail "kg-fila: (g)" "status desconhecido tratado errado: $(printf '%s' "${out}" | cut -f2,5,8,11 | tr '\n' ' ')"; fi

  # (b2) O VALOR da formula, verbatim sobre a fixture — amarra as tres constantes que ninguem mais
  #      amarra: a centralidade (N_OPEN tem grau 5 → 3×1×1×6=18), o 1.3 do `drifted` (5×1×1.3×2=13)
  #      e o 1.0 do `unverifiable` (4×1×1×2=8). Sem isto, mutar qualquer um dos tres passa 6/6.
  out="$(bash "${radar}" "${fx}" --open-tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '
        $2=="N_OPEN"         {a=($8=="18.00")}
        $2=="N_DRIFTED"      {b=($8=="13.00")}
        $2=="N_UNVERIFIABLE" {c=($8=="8.00")}
        END{exit !(a&&b&&c)}'; then
    record_pass "kg-fila: (b2) a formula vale 18.00/13.00/8.00 — centralidade, o 1.3 do drifted e o 1.0 do unverifiable amarrados"
  else record_fail "kg-fila: (b2)" "formula mudou: $(printf '%s' "${out}" | cut -f2,8 | tr '\n' ' ')"; fi

  # (f) MUTATION — devolver a allowlist faz (e) parar de proteger. Passa pelo `_prove_mutation`, que
  #     cobra as tres condicoes (mutacao aplicada · INTACTO satisfaz · MUTANTE nao).
  #     ⚠️ o `sed` e ANCORADO no ramo do `--state`: o padrao casa DUAS linhas no arquivo (a do
  #     `--state` e a do `--open-tsv`), e sem ancora o mutante mudaria os dois — o `cmp` passaria a
  #     diferir por duas razoes e o rotulo do caso mentiria sobre o que foi mutado.
  mut="$d/radar-allow.sh"
  sed '/mode == "--state"/,/^  }$/ s/if (!trabalhoPendente(nstatus\[id\])) continue.*/if (nstatus[id] != "open") continue/' "${radar}" > "${mut}"
  out_int="$(bash "${radar}" "$d/g.kg.yaml" --state 2>/dev/null || true)"
  out_mut="$(bash "${mut}"   "$d/g.kg.yaml" --state 2>/dev/null || true)"
  if printf '%s' "${out_int}" | grep -q 'N_DRIFTED'; then rc_intact=0; else rc_intact=1; fi
  if printf '%s' "${out_mut}" | grep -q 'N_DRIFTED'; then rc_mutant=0; else rc_mutant=1; fi
  _prove_mutation "kg-fila: (f) (MUT) com a allowlist de volta o --state perde o drifted — a denylist e load-bearing" \
                  "${radar}" "${mut}" "${rc_intact}" "${rc_mutant}"
  rm -rf "$d"
}

run_kg_state_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local sx="${FIX_DIR}/kg-reconcile"
  local out rc

  # (a) COMPLEMENTARIDADE — nenhum id exibido pelo --state pode estar na coluna de id do --radar.
  # É a propriedade que define o modo; se cair, ele deixa de ter razão de existir.
  local st rd dupes
  st=$(bash "${radar}" "${sx}/state-below-radar.kg.yaml" --state 2>&1)
  rd=$(bash "${radar}" "${sx}/state-below-radar.kg.yaml" --radar 2>&1)
  dupes=0
  while read -r id; do
    [ -n "${id}" ] || continue
    if printf '%s' "${rd}" | awk '{print $2}' | grep -qx "${id}"; then dupes=$((dupes + 1)); fi
  done <<< "$(printf '%s' "${st}" | awk '/^ +[0-9.]+ +/ {print $2}')"
  local exibidos; exibidos=$(printf '%s' "${st}" | grep -cE '^ +[0-9.]+ +' || true)
  if [ "${exibidos}" -eq 0 ]; then
    record_fail "kg-state: (a) complementaridade" "a fixture não exibiu NADA — o teste passaria vacuamente"
  elif [ "${dupes}" -eq 0 ]; then
    record_pass "kg-state: (a) ${exibidos} exibidos, zero sobreposição com o --radar — complementar por construção"
  else record_fail "kg-state: (a) complementaridade" "${dupes} id(s) repetido(s) do radar. state=${st}"; fi

  # (b) SÓ `open` — nenhum nó com outro status entra na fila. A fixture tem confirmed, superseded
  # e done de propósito, então o lado negativo é real e não vacuidade.
  local st2; st2=$(bash "${radar}" "${sx}/supersedes-mixed.kg.yaml" --state 2>&1)
  if ! printf '%s' "${st2}" | grep -qE 'D_JA_RECONCILIADO|Q_JA_FECHADA|D_PESO_'; then
    record_pass "kg-state: (b) só nós open entram — confirmed/superseded/done ficam fora"
  else record_fail "kg-state: (b) só open" "state=${st2}"; fi

  # (c) GRAFO SEM ABERTO diz isso, em vez de imprimir cabeçalho vazio (o no-op silencioso que esta
  # casa já pagou várias vezes).
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "'"${tmp}"'"' RETURN
  cat > "${tmp}/sem-aberto.kg.yaml" <<'KGEOF'
meta:
  id: fixture-sem-aberto
  schema_version: "1"
nodes:
  - id: D_UM
    node_type: decision
    layer: audit
    plane: DEV
    impact: 3
    confidence: 1.0
    status: confirmed
    label: "decisao fechada"
  - id: D_DOIS
    node_type: decision
    layer: audit
    plane: DEV
    impact: 3
    confidence: 1.0
    status: confirmed
    label: "outra decisao fechada"
edges:
  - from: D_UM
    to: D_DOIS
    edge_type: SUPPORTS
KGEOF
  rc=0; out=$(bash "${radar}" "${tmp}/sem-aberto.kg.yaml" --state 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'nada em aberto'; then
    record_pass "kg-state: (c) grafo sem aberto DIZ que não há — não imprime cabeçalho mudo"
  else record_fail "kg-state: (c) sem aberto" "rc=${rc} out=${out}"; fi

  # (d) (MUT) — removida a exclusão do top-10, a sobreposição REAPARECE. Sem esta prova, (a)
  # passaria igual se a fixture não tivesse nenhum open pesado o bastante para entrar no radar.
  local mut; mut="$(mktemp -d)"; trap 'rm -rf "'"${tmp}"'" "'"${mut}"'"' RETURN
  cp "${radar}" "${mut}/mutado.sh"; _lib_beside "${mut}"
  sed -i 's/^      if (id in noRadar) continue.*$//' "${mut}/mutado.sh"
  if ! grep -q 'if (id in noRadar) continue' "${mut}/mutado.sh"; then
    local mst mdup
    mst=$(bash "${mut}/mutado.sh" "${sx}/state-below-radar.kg.yaml" --state 2>&1 || true)
    mdup=0
    while read -r id; do
      [ -n "${id}" ] || continue
      if printf '%s' "${rd}" | awk '{print $2}' | grep -qx "${id}"; then mdup=$((mdup + 1)); fi
    done <<< "$(printf '%s' "${mst}" | awk '/^ +[0-9.]+ +/ {print $2}')"
    if [ "${mdup}" -gt 0 ]; then
      record_pass "kg-state: (d) (MUT) sem a exclusão a sobreposição volta (${mdup}) — a exclusão é load-bearing"
    else record_fail "kg-state: (d) (MUT)" "mutação não trouxe sobreposição — a exclusão é vacuidade? out=${mst}"; fi
  else
    record_fail "kg-state: (d) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
}

# Guardas da REGRA 55 / kg-trace-resolve.sh — a âncora declarada EXISTE?
#
# POR QUE EXISTE (medido 2026-08-06): o bloco PROVENIÊNCIA do kg-radar cobra que a decisão APONTE
# para a origem; nunca que o alvo EXISTA. 13 ponteiros mortos vivos no corpus, todos consertados
# antes da regra entrar (por isso HARD sem baseline).
#
# O CASO (e) É O MAIS IMPORTANTE DA SUÍTE, e nasceu de um incidente durante a própria construção:
# uma edição comentou sem querer o resto da linha do awk que casa `trace:`. O parser passou a ler
# ZERO nós e o script imprimiu "✅ todo trace: julgável resolve" com EXIT 0. Guarda quebrada
# reportando sucesso — fail-open perfeito, pego só porque eu tinha um número conhecido (1300) para
# comparar. O caso (e) é esse número virado mecanismo.
run_kg_trace_resolve_selftests() {
  local helper="${SCRIPT_DIR}/kg-trace-resolve.sh"
  local fix="${FIX_DIR}/kg-trace/trace-mixed.kg.yaml"
  local out rc d

  if [ ! -f "${helper}" ]; then record_fail "kg-trace-resolve" "helper ausente: ${helper}"; return; fi
  if [ ! -f "${fix}" ];    then record_fail "kg-trace-resolve" "fixture ausente: ${fix}"; return; fi

  # Sandbox: a fixture vive sob fixtures/, que o script EXCLUI por desenho. Para exercitá-la é
  # preciso um repo git onde ela seja o corpus — e com o MESMO basename, porque um dos nós testa
  # justamente a resolução relativa ao diretório do grafo.
  _mk_trace_sandbox() {
    mkdir -p "$1/docs/onion/graph/sub" "$1/docs/onion/vizinho"
    cp "${fix}" "$1/docs/onion/graph/trace-mixed.kg.yaml"
    : > "$1/docs/onion/graph/sub/alvo-vivo.md"     # o alvo que C_VIVO_RELATIVO resolve pela 2a raiz
    : > "$1/docs/onion/vizinho/alvo-no-pai.md"     # o alvo que C_VIVO_PAI resolve pela 3a raiz (pai do grafo)
    ( cd "$1" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm x ) 2>/dev/null
  }

  d="$(mktemp -d)"; _mk_trace_sandbox "${d}"
  out="$(bash "${helper}" "${d}" --format tsv 2>/dev/null || true)"

  # (a) ACUSA os dois mortos — um por raiz, um por relativo-ao-grafo.
  if printf '%s' "${out}" | grep -q 'C_MORTO_RAIZ' && printf '%s' "${out}" | grep -q 'C_MORTO_REL'; then
    record_pass "kg-trace: (a) acusa ponteiro morto por raiz E por relativo-ao-grafo"
  else record_fail "kg-trace: (a) acusa mortos" "out=${out}"; fi

  # (b) CALA nos 6 sãos, e cada um por um MOTIVO DIFERENTE (resolve-na-raiz · resolve-relativo ·
  #     absoluto · raiz externa · comando com argumento · domínio sem esquema · nome solto). Um teste de silêncio
  #     com um motivo só passaria por acidente se um único filtro estivesse fazendo todo o trabalho.
  local ruido=0 n
  for n in C_VIVO_RAIZ C_VIVO_RELATIVO C_VIVO_PAI C_ABSOLUTO C_RAIZ_EXTERNA C_COMANDO C_DOMINIO C_NOME_SOLTO; do
    if printf '%s' "${out}" | grep -q "${n}"; then ruido=$((ruido + 1)); fi
  done
  if [ "${ruido}" -eq 0 ]; then
    record_pass "kg-trace: (b) cala nos 8 sãos — 8 motivos distintos (3 raízes + 5 exclusões), nenhum filtro carregando o resto"
  else record_fail "kg-trace: (b) silêncio" "${ruido} falso-positivo(s). out=${out}"; fi

  # (c) EXIT CODE — o veredito tem de reprovar, não só imprimir.
  rc=0; bash "${helper}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "kg-trace: (c) exit 1 com ponteiro morto (reprova, não só avisa)"
  else record_fail "kg-trace: (c) exit" "esperava 1, veio ${rc}"; fi

  # (d) CORPUS SÃO → exit 0. Sem este lado, (c) não distingue "reprova certo" de "reprova sempre".
  local d2; d2="$(mktemp -d)"; _mk_trace_sandbox "${d2}"
  # Cura os dois mortos APONTANDO-OS para alvos que existem — em vez de deletar nós, o que mexeria
  # nas arestas e poderia reprovar por órfão em vez de por trace.
  sed -i 's|docs/evolution/inbox/2026-01-01-arquivo-que-nunca-existiu.md|docs/onion/graph/trace-mixed.kg.yaml|; s|sub/alvo-que-nunca-existiu.md|sub/alvo-vivo.md|' \
    "${d2}/docs/onion/graph/trace-mixed.kg.yaml"
  rc=0; bash "${helper}" "${d2}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "kg-trace: (d) corpus são → exit 0 (não reprova por reflexo)"
  else record_fail "kg-trace: (d) corpus são" "esperava 0, veio ${rc}"; fi

  # (e) (MUT) A GUARDA DE VACUIDADE — reproduz o incidente da construção: parser cego.
  #     Antes dela, o mutante saía 0 imprimindo ✅. Se este caso cair, o script voltou a poder
  #     mentir verde, que é pior do que não existir.
  local mut; mut="$(mktemp -d)"; cp "${helper}" "${mut}/m.sh"
  # O padrão casado aqui TEM de acompanhar o do script — quando ele mudou de `^    trace:` para
  # `^[[:space:]]+trace:`, este sed parou de casar e a guarda-da-guarda ACUSOU ("mutação não
  # aplicada"), em vez de passar vazia. É o comportamento correto, e a razão de ela existir.
  sed -i 's|/\^\[\[:space:\]\]+trace:/|/^NUNCA_CASA_XYZ:/|' "${mut}/m.sh"
  if grep -q 'NUNCA_CASA_XYZ' "${mut}/m.sh"; then
    # TSV É O MODO QUE IMPORTA — e testar o outro foi o defeito desta suíte até 2026-08-06.
    # A revisão adversarial mediu: com o parser cego, o modo humano saía 1 com ✗ VACUIDADE e o
    # modo TSV saía 0 com saída vazia. O lint chama TSV (check_kg_trace_resolve). Ou seja: a
    # guarda-da-guarda validava a superfície que ninguém usa em CI, e a REGRA 55 ficava VERDE
    # com o parser morto. Agora os DOIS modos são exigidos, e o TSV vem primeiro de propósito.
    local rct=0 outt
    outt="$(bash "${mut}/m.sh" "${d}" --format tsv 2>&1)" || rct=$?
    rc=0; out="$(bash "${mut}/m.sh" "${d}" 2>&1)" || rc=$?
    if [ "${rct}" -eq 1 ] && printf '%s' "${outt}" | grep -q 'VACUIDADE' \
       && [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'VACUIDADE'; then
      record_pass "kg-trace: (e) (MUT) parser cego → VACUIDADE + exit 1 nos DOIS modos (tsv é o que o lint usa)"
    else record_fail "kg-trace: (e) (MUT) vacuidade" "tsv: rc=${rct} out=${outt} · humano: rc=${rc} out=${out}"; fi

    # (f) VACUIDADE NÃO PODE SER FALSA — corpus cujas âncoras são todas não-julgáveis por desenho
    #     (um adotante com grafos ancorando por nome solto) tem JUDGED=0 com o parser PERFEITO.
    #     Antes desta correção ele recebia "✗ o parser quebrou": diagnóstico mentiroso e HARD no
    #     dia 1. Os contadores de skip provam que o parser leu — só há vacuidade quando NADA foi lido.
    local d3; d3="$(mktemp -d)"; mkdir -p "${d3}/docs/onion/graph"
    printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: C_SO_NOME_SOLTO\n    node_type: claim\n    layer: audit\n    plane: DEV\n    impact: 3\n    confidence: 1.0\n    status: confirmed\n    label: "ancora por nome solto — nao julgavel por desenho"\n    trace: "SYNTHESIS.md"\nedges:\n' \
      > "${d3}/docs/onion/graph/so-nao-julgavel.kg.yaml"
    ( cd "${d3}" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm x ) 2>/dev/null
    rc=0; out="$(bash "${helper}" "${d3}" 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ] && ! printf '%s' "${out}" | grep -q 'VACUIDADE'; then
      record_pass "kg-trace: (f) tudo não-julgável ≠ parser morto (não acusa vacuidade falsa)"
    else record_fail "kg-trace: (f) vacuidade falsa" "rc=${rc} out=${out}"; fi
    rm -rf "${d3}"
  else
    record_fail "kg-trace: (e) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi

  rm -rf "${d}" "${d2}" "${mut}"
}

# ---------------------------------------------------------------------------
# Modo worklog-precompact-breadcrumb — exercita o hook do evento PreCompact
# (hooks/worklog-precompact-breadcrumb.sh). É o momento em que a sessão PERDE
# contexto; a saída do PreCompact é ignorada pós-compactação, então o ÚNICO
# side-effect útil é a migalha datada gravada em notes.md (worklog-protocol.md
# §7). Se este hook falhar, a migalha não é escrita e NINGUÉM percebe — o hook
# sempre sai 0 (contrato "non-blocking"), então um hook quebrado é
# INDISTINGUÍVEL de um no-op saudável do lado de fora. É por isso que o caso
# (MUT) é o mais importante desta bateria: prova que o "passou" dos demais
# casos não é vácuo.
#
# Sandbox: repo git real em mktemp (o hook precisa de HEAD resolvível — em
# repo sem commit `git rev-parse --abbrev-ref HEAD` falha e o hook no-opa;
# por isso todo sandbox nasce com um commit --allow-empty).
#
# Payload REAL do Claude Code (verificado 2026-08-06 via docs.claude.com/
# hooks-reference + gist de schemas): o evento PreCompact manda `trigger`
# ("manual"|"auto") + `custom_instructions`, NUNCA um campo `source`. O hook
# lê `.source` (linha `jq -r '.source // "?"'`) — ver caso (i).
# ---------------------------------------------------------------------------
run_worklog_precompact_breadcrumb_selftests() {
  local hk="${REPO_ROOT}/.claude/hooks/worklog-precompact-breadcrumb.sh"
  if [ ! -f "${hk}" ]; then record_fail "worklog-precompact-breadcrumb" "hook ausente: ${hk}"; return; fi
  local d out out2 rc

  # payload REAL do Claude Code para PreCompact (trigger, não source)
  local real_payload='{"session_id":"abc123","transcript_path":"/tmp/x.jsonl","hook_event_name":"PreCompact","trigger":"manual","custom_instructions":""}'
  # regex do formato da migalha (worklog-protocol.md §7)
  local crumb_re='^- ⚠️ \[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\] compaction \([^)]*\) — verifique se STATE\.md\.NEXT reflete o último raciocínio antes de prosseguir\.$'

  # helper local: sandbox git com 1 commit base + hook copiado
  _wpb_sandbox() {
    local sd; sd="$(mktemp -d)"
    git -C "${sd}" init -q
    git -C "${sd}" -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
    mkdir -p "${sd}/.claude/hooks"
    cp "${hk}" "${sd}/.claude/hooks/"
    printf '%s' "${sd}"
  }

  # (a) happy-path com o SHAPE REAL do Claude Code, branch feature/*, notes.md
  # ativo → exit 0 + migalha no formato certo anexada (não sobrescreve).
  d="$(_wpb_sandbox)"
  git -C "${d}" checkout -q -b feature/happy-path
  mkdir -p "${d}/.claude/sessions/happy-path"
  printf 'linha-preexistente\n' > "${d}/.claude/sessions/happy-path/notes.md"
  rc=0; out="$(cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ] \
     && grep -q '^linha-preexistente$' "${d}/.claude/sessions/happy-path/notes.md" \
     && grep -qE "${crumb_re}" "${d}/.claude/sessions/happy-path/notes.md"; then
    record_pass "worklog-precompact-breadcrumb: (a) shape REAL do Claude Code → migalha anexada (preserva o que já tinha)"
  else record_fail "worklog-precompact-breadcrumb: (a) happy-path" "esperava anexar+preservar; rc=${rc} conteúdo=$(cat "${d}/.claude/sessions/happy-path/notes.md")"; fi
  rm -rf "${d}"

  # (b) hotfix/* e release/* também disparam — a REGRA de escopo do worklog
  # cobre os 3 tipos de branch (gitflow-patterns.md), não só feature/*.
  local pfx
  for pfx in hotfix release; do
    d="$(_wpb_sandbox)"
    git -C "${d}" checkout -q -b "${pfx}/urgent"
    mkdir -p "${d}/.claude/sessions/urgent"
    : > "${d}/.claude/sessions/urgent/notes.md"
    (cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh >/dev/null 2>&1)
    if grep -qE "${crumb_re}" "${d}/.claude/sessions/urgent/notes.md"; then
      record_pass "worklog-precompact-breadcrumb: (b) branch ${pfx}/* também grava a migalha"
    else record_fail "worklog-precompact-breadcrumb: (b) ${pfx}" "migalha não apareceu em notes.md"; fi
    rm -rf "${d}"
  done

  # (c) branch NÃO elegível (main) → no-op silencioso: notes.md fica
  # BYTE-IDÊNTICO (não pode vazar migalha pra sessão errada nem criar ruído).
  d="$(_wpb_sandbox)"
  git -C "${d}" checkout -q -b main
  mkdir -p "${d}/.claude/sessions/main"
  printf 'nao-mexer\n' > "${d}/.claude/sessions/main/notes.md"
  local before after
  before="$(cat "${d}/.claude/sessions/main/notes.md")"
  rc=0; (cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh >/dev/null 2>&1) || rc=$?
  after="$(cat "${d}/.claude/sessions/main/notes.md")"
  if [ "${rc}" -eq 0 ] && [ "${before}" = "${after}" ]; then
    record_pass "worklog-precompact-breadcrumb: (c) branch main → no-op, notes.md byte-idêntico"
  else record_fail "worklog-precompact-breadcrumb: (c) branch main" "esperava no-op; rc=${rc} before=[${before}] after=[${after}]"; fi
  rm -rf "${d}"

  # (d) notes.md AUSENTE numa branch elegível → no-op: exit 0, sem criar
  # arquivo/diretório fantasma (o hook não pode inventar um worklog).
  d="$(_wpb_sandbox)"
  git -C "${d}" checkout -q -b feature/no-notes
  rc=0; out="$(cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ ! -d "${d}/.claude/sessions" ]; then
    record_pass "worklog-precompact-breadcrumb: (d) notes.md ausente → no-op, não cria diretório fantasma"
  else record_fail "worklog-precompact-breadcrumb: (d) notes.md ausente" "rc=${rc}; sessions/ existe? $([ -d "${d}/.claude/sessions" ] && echo sim || echo não)"; fi
  rm -rf "${d}"

  # (e) fora de um repo git → exit 0, não trava (não pode derrubar o
  # PreCompact do Claude Code por um cwd sem .git).
  d="$(mktemp -d)"
  mkdir -p "${d}/.claude/hooks"
  cp "${hk}" "${d}/.claude/hooks/"
  rc=0; out="$(cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "worklog-precompact-breadcrumb: (e) fora de repo git → exit 0 silencioso"
  else record_fail "worklog-precompact-breadcrumb: (e) fora de repo git" "rc=${rc} out=[${out}]"; fi
  rm -rf "${d}"

  # (f) jq AUSENTE do PATH → cai no fallback trig="?", mas a ESCRITA não pode
  # ser pulada (modo de falha: se o guard do jq virar `|| exit 0` por engano,
  # a migalha some inteira em qualquer ambiente sem jq — silencioso, igual
  # ao (MUT) abaixo). PATH restrito só com os binários que o hook usa.
  local mkbin c p
  mkbin="$(mktemp -d)"
  for c in cat git date bash sed grep mkdir rm cp mktemp; do
    p="$(command -v "${c}" 2>/dev/null)"; [ -n "${p}" ] && ln -s "${p}" "${mkbin}/${c}"
  done
  d="$(_wpb_sandbox)"
  git -C "${d}" checkout -q -b feature/no-jq
  mkdir -p "${d}/.claude/sessions/no-jq"
  : > "${d}/.claude/sessions/no-jq/notes.md"
  rc=0; out="$(cd "${d}" && printf '%s' "${real_payload}" | PATH="${mkbin}" bash .claude/hooks/worklog-precompact-breadcrumb.sh)" || rc=$?
  if [ "${rc}" -eq 0 ] && grep -qE "${crumb_re}" "${d}/.claude/sessions/no-jq/notes.md" \
     && grep -q 'compaction (?)' "${d}/.claude/sessions/no-jq/notes.md"; then
    record_pass "worklog-precompact-breadcrumb: (f) jq ausente do PATH → fallback '?' mas a escrita SOBREVIVE"
  else record_fail "worklog-precompact-breadcrumb: (f) jq ausente" "rc=${rc}; conteúdo=$(cat "${d}/.claude/sessions/no-jq/notes.md")"; fi
  rm -rf "${d}" "${mkbin}"

  # (g) JSON malformado / stdin vazio → jq falha ao parsear mas o script não
  # pode morrer por isso (comando substituído engole rc≠0); a escrita ainda
  # acontece com fallback "?".
  d="$(_wpb_sandbox)"
  git -C "${d}" checkout -q -b feature/bad-input
  mkdir -p "${d}/.claude/sessions/bad-input"
  : > "${d}/.claude/sessions/bad-input/notes.md"
  rc=0; (cd "${d}" && printf 'isto não é json {{{' | bash .claude/hooks/worklog-precompact-breadcrumb.sh >/dev/null 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && grep -qE "${crumb_re}" "${d}/.claude/sessions/bad-input/notes.md"; then
    record_pass "worklog-precompact-breadcrumb: (g) JSON malformado → não trava, migalha ainda sai (fallback '?')"
  else record_fail "worklog-precompact-breadcrumb: (g) JSON malformado" "rc=${rc}; conteúdo=$(cat "${d}/.claude/sessions/bad-input/notes.md")"; fi
  rm -rf "${d}"

  # (MUT) guard-of-guard — prova que (a)-(g) não passam por vácuo. Sabota uma
  # CÓPIA do hook (short-circuit logo antes do printf que grava a migalha),
  # confirma por grep/diff que a mutação FOI aplicada e então exige que o
  # comportamento MUDE (notes.md deve ficar vazio) — sem isso, nada acima
  # provaria que o hook realmente escreve nada além de "passou por acaso".
  d="$(_wpb_sandbox)"
  local hookfile="${d}/.claude/hooks/worklog-precompact-breadcrumb.sh"
  sed -i "s/^printf '\\\\n- ⚠️/exit 0; printf '\\\\n- ⚠️/" "${hookfile}"
  if grep -q "^exit 0; printf '\\\\n- ⚠️" "${hookfile}"; then
    git -C "${d}" checkout -q -b feature/mutation
    mkdir -p "${d}/.claude/sessions/mutation"
    : > "${d}/.claude/sessions/mutation/notes.md"
    rc=0; (cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh >/dev/null 2>&1) || rc=$?
    if [ "${rc}" -eq 0 ] && [ ! -s "${d}/.claude/sessions/mutation/notes.md" ]; then
      record_pass "worklog-precompact-breadcrumb: (MUT) hook sabotado → migalha NÃO sai (exit 0 idêntico ao no-op saudável — prova que (a)-(g) não são vácuos)"
    else record_fail "worklog-precompact-breadcrumb: (MUT)" "esperava notes.md vazio com o hook sabotado; conteúdo=$(cat "${d}/.claude/sessions/mutation/notes.md")"; fi
  else
    record_fail "worklog-precompact-breadcrumb: (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
  rm -rf "${d}"

  # (i) BUG CONFIRMADO (2026-08-06, docs.claude.com/en/docs/claude-code/
  # hooks-reference) — o payload REAL do PreCompact usa `trigger`
  # ("manual"|"auto"), nunca `source`. O hook lê `.source`, então em TODO
  # disparo real de compactação a migalha grava "compaction (?)" — o dado que
  # o drift-guard existe para cruzar (manual vs auto) nunca chega no
  # notes.md. É silencioso: exit 0, sem erro, breadcrumb gravada com formato
  # correto — só o conteúdo do parêntese está sempre errado. Este caso
  # ESPERA o comportamento CORRETO (o valor de `trigger` aparecendo) e por
  # isso REPROVA hoje — é a prova viva do defeito, não um teste quebrado.
  d="$(_wpb_sandbox)"
  git -C "${d}" checkout -q -b feature/trigger-field-bug
  mkdir -p "${d}/.claude/sessions/trigger-field-bug"
  : > "${d}/.claude/sessions/trigger-field-bug/notes.md"
  (cd "${d}" && printf '%s' "${real_payload}" | bash .claude/hooks/worklog-precompact-breadcrumb.sh >/dev/null 2>&1)
  if grep -q 'compaction (manual)' "${d}/.claude/sessions/trigger-field-bug/notes.md"; then
    record_pass "worklog-precompact-breadcrumb: (i) trigger real do Claude Code chega na migalha"
  else record_fail "worklog-precompact-breadcrumb: (i) BUG — campo errado" "hook lê .source mas o Claude Code manda .trigger; migalha real sempre grava '(?)', nunca 'manual'/'auto'. conteúdo=$(cat "${d}/.claude/sessions/trigger-field-bug/notes.md")"; fi
  rm -rf "${d}"

  unset -f _wpb_sandbox
}

run_aside_router_hook_selftests() {
  local hk="${REPO_ROOT}/.claude/hooks/aside-router-hook.sh"
  local eng="${REPO_ROOT}/.claude/validation/aside-router.sh"
  if [ ! -f "$hk" ]; then record_fail "aside-router-hook" "hook ausente: ${hk}"; return; fi
  if [ ! -f "$eng" ]; then record_fail "aside-router-hook" "motor ausente: ${eng}"; return; fi
  local d out rc

  d="$(mktemp -d)"
  mkdir -p "${d}/.claude/hooks" "${d}/.claude/validation"
  cp "$hk" "${d}/.claude/hooks/"
  cp "$eng" "${d}/.claude/validation/"

  # payload no formato REAL do UserPromptSubmit (session_id/transcript_path/cwd/
  # hook_event_name/prompt) — não o fixture minimalista {"prompt":"..."} que esconderia
  # regressão se a extração dependesse (por engano) de ser o único campo.
  local payload_marker payload_prosa payload_no_prompt
  payload_marker='{"session_id":"s1","transcript_path":"/tmp/t","cwd":"/x","hook_event_name":"UserPromptSubmit","prompt":"dúvida: isso quebra sob carga?"}'
  payload_prosa='{"session_id":"s1","transcript_path":"/tmp/t","cwd":"/x","hook_event_name":"UserPromptSubmit","prompt":"por favor continue o trabalho normalmente"}'
  payload_no_prompt='{"session_id":"s1","transcript_path":"/tmp/t","cwd":"/x","hook_event_name":"UserPromptSubmit"}'

  # (a) marcador tipado, INVOCADO DE FORA do repo (cwd neutro, sem .claude, sem git) —
  # obriga a resolução de $REPO a vir de CLAUDE_PROJECT_DIR (linha 23 do hook), não de
  # `pwd`/git-toplevel. Regressão nessa prioridade FICA MUDA (nunca crasha) — silenciosa.
  local elsewhere; elsewhere="$(mktemp -d)"
  rc=0
  out="$(cd "${elsewhere}" && CLAUDE_PROJECT_DIR="${d}" bash "${d}/.claude/hooks/aside-router-hook.sh" <<<"${payload_marker}")" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '"hookEventName":"UserPromptSubmit"' \
     && printf '%s' "${out}" | grep -q 'APARTE dúvida'; then
    record_pass "aside-router-hook: marcador tipado + cwd neutro → resolve via CLAUDE_PROJECT_DIR, rota certa"
  else record_fail "aside-router-hook: marcador (CLAUDE_PROJECT_DIR)" "esperava JSON com APARTE dúvida; out='${out}' rc=${rc}"; fi
  rm -rf "${elsewhere}"

  # (b) prosa comum (sem marcador) → SILÊNCIO TOTAL (custo-zero). Regressão aqui = poluir
  # additionalContext em TODO prompt, para sempre, sem ninguém perceber (nada quebra/loga).
  rc=0
  out="$(cd "${d}" && CLAUDE_PROJECT_DIR="${d}" bash .claude/hooks/aside-router-hook.sh <<<"${payload_prosa}")" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "aside-router-hook: prosa comum → silêncio total (custo-zero, exit 0)"
  else record_fail "aside-router-hook: prosa" "esperava vazio+0; out='${out}' rc=${rc}"; fi

  # (c) envelope sem campo .prompt → no-op silencioso, nunca crash (harness pode mudar o shape)
  rc=0
  out="$(cd "${d}" && CLAUDE_PROJECT_DIR="${d}" bash .claude/hooks/aside-router-hook.sh <<<"${payload_no_prompt}")" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "aside-router-hook: sem campo prompt → no-op silencioso"
  else record_fail "aside-router-hook: sem prompt" "esperava vazio+0; out='${out}' rc=${rc}"; fi

  # (d) motor ausente (instalação incompleta / vendor desatualizado) → hook não quebra a
  # sessão, silêncio, exit 0 (contrato explícito do header: "NUNCA falha a sessão").
  mv "${d}/.claude/validation/aside-router.sh" "${d}/.claude/validation/aside-router.sh.bak"
  rc=0
  out="$(cd "${d}" && CLAUDE_PROJECT_DIR="${d}" bash .claude/hooks/aside-router-hook.sh <<<"${payload_marker}")" || rc=$?
  mv "${d}/.claude/validation/aside-router.sh.bak" "${d}/.claude/validation/aside-router.sh"
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "aside-router-hook: motor ausente → silêncio gracioso, exit 0 (nunca quebra a sessão)"
  else record_fail "aside-router-hook: motor ausente" "esperava vazio+0; out='${out}' rc=${rc}"; fi

  # (e) CAMINHO SEM JQ — o fallback grep/sed (linha 19) é a superfície que ninguém exercita
  # em dev (jq quase sempre presente na VPS/máquina do maestro); é EXATAMENTE o tipo de
  # ramo-morto-em-teste apontado como risco (validar o modo que ninguém usa). Força a
  # ausência forjando um PATH sem o binário jq.
  if command -v jq >/dev/null 2>&1; then
    local nojq_bin p exe base
    nojq_bin="$(mktemp -d)"
    IFS=':' read -ra _patharr <<<"${PATH}"
    for p in "${_patharr[@]}"; do
      [ -d "$p" ] || continue
      for exe in "$p"/*; do
        [ -e "$exe" ] || continue
        base="$(basename "$exe")"
        [ "$base" = "jq" ] && continue
        [ -e "${nojq_bin}/${base}" ] || ln -s "$exe" "${nojq_bin}/${base}" 2>/dev/null
      done
    done
    if PATH="${nojq_bin}" command -v jq >/dev/null 2>&1; then
      record_fail "aside-router-hook: fallback sem jq (setup)" "jq ainda visível no PATH forjado — guarda-da-guarda"
    else
      rc=0
      out="$(cd "${d}" && CLAUDE_PROJECT_DIR="${d}" PATH="${nojq_bin}" bash .claude/hooks/aside-router-hook.sh <<<"${payload_marker}")" || rc=$?
      if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '"hookEventName":"UserPromptSubmit"' \
         && printf '%s' "${out}" | grep -q 'APARTE dúvida'; then
        record_pass "aside-router-hook: fallback SEM jq produz o mesmo contrato (rota certa, JSON válido)"
      else record_fail "aside-router-hook: fallback sem jq" "esperava JSON com APARTE dúvida; out='${out}' rc=${rc}"; fi

      rc=0
      out="$(cd "${d}" && CLAUDE_PROJECT_DIR="${d}" PATH="${nojq_bin}" bash .claude/hooks/aside-router-hook.sh <<<"${payload_prosa}")" || rc=$?
      if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
        record_pass "aside-router-hook: fallback sem jq — prosa comum ainda silenciosa"
      else record_fail "aside-router-hook: fallback sem jq prosa" "esperava vazio+0; out='${out}' rc=${rc}"; fi
    fi
    rm -rf "${nojq_bin}"
  else
    record_skip "aside-router-hook: fallback sem jq (skip: jq já ausente no host)"
  fi

  # (f) MUTATION + guarda-da-guarda: quebra a extração jq do .prompt (typo na chave) e prova
  # que o hook DEGRADA (fica mudo, exit 0) em vez de crashar — se a mutação não tivesse sido
  # aplicada de fato, o teste não provaria nada (o caso (a) já passaria do mesmo jeito).
  cp "${d}/.claude/hooks/aside-router-hook.sh" "${d}/.claude/hooks/aside-router-hook.sh.orig"
  sed -i "s#'\.prompt // empty'#'.promptXXX // empty'#" "${d}/.claude/hooks/aside-router-hook.sh"
  if ! grep -q '\.promptXXX // empty' "${d}/.claude/hooks/aside-router-hook.sh"; then
    record_fail "aside-router-hook: (MUT) guarda-da-guarda" "a mutação NÃO foi aplicada — o teste não prova nada"
  else
    rc=0
    out="$(cd "${d}" && CLAUDE_PROJECT_DIR="${d}" bash .claude/hooks/aside-router-hook.sh <<<"${payload_marker}")" || rc=$?
    if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
      record_pass "aside-router-hook: (MUT) extração .prompt quebrada → fica mudo, não crasha (prova (a) load-bearing)"
    else record_fail "aside-router-hook: (MUT)" "esperava vazio+0 mesmo com extração quebrada; out='${out}' rc=${rc}"; fi
  fi
  mv "${d}/.claude/hooks/aside-router-hook.sh.orig" "${d}/.claude/hooks/aside-router-hook.sh"

  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo worklog-capture-session — exercita hooks/worklog-capture-session.sh
# (SessionStart: grava/atualiza resume_command no STATE.md do worklog ACTIVE).
# Zero cobertura até 2026-08-06. Contrato (worklog-capture-session.sh:16-45):
# stdin = payload JSON do SessionStart nativo (session_id + outros campos,
# NÃO o `{"session_id":"x"}` minimalista de outros selftests); grava em
# `.claude/sessions/<slug>/STATE.md` relativo ao CWD do processo — settings.json
# não faz `cd`, então o CWD real É o project root (mesma premissa do hook
# session-beacon-hook.sh). Self-contained: repo git em mktemp com 1 commit
# (git rev-parse --abbrev-ref HEAD falha em HEAD "unborn" sem commit algum —
# verificado; sem isso o sandbox nem chegaria a exercitar o hook).
#
# MODO DE FALHA SILENCIOSO ALVEJADO: o parse tem 2 caminhos — jq (linha 20) e
# um fallback grep/sed (linha 22) para ambientes sem jq. Esta máquina TEM jq
# (ver memória lint-graph-needs-jq), então qualquer selftest ingênuo cai SEMPRE
# no caminho jq — o fallback fica invisível e pode apodrecer sem ninguém notar
# (paralelo exato ao aviso desta tarefa: mutation test recente validava o modo
# HUMANO enquanto o consumidor real usava TSV). O caso (h) esconde jq do PATH
# e usa o payload MULTI-CAMPO real (session_id fora da 1ª posição, não o
# `{"session_id":"x"}` trivial) para provar que o fallback extrai o sid certo.
# Falsificado empiricamente: com o regex do fallback quebrado E jq escondido,
# o hook grava NADA e sai 0 — falha 100% silenciosa que só (h) pega.
#
# 2º modo de falha visado: duplicação silenciosa. O template real
# (.claude/commands/engineer/start.md:143-144) já semeia o STATE.md com
# `resume_command: claude --resume <id>`, então o caminho de produção É o
# ramo de ATUALIZAÇÃO (sed), não o de criação (append) — testar só "sem
# seção prévia" testaria a forma que o template real nunca produz. Se a
# detecção `grep -q '^resume_command:'` (linha 37) alguma vez parar de casar,
# cada SessionStart da MESMA sessão duplica a seção `## Native transcript`
# no STATE.md — crescimento silencioso, invisível até alguém abrir o arquivo.
# Caso (i) é o mutation test que prova essa detecção é load-bearing.
# ---------------------------------------------------------------------------
run_worklog_capture_session_selftests() {
  local hk="${REPO_ROOT}/.claude/hooks/worklog-capture-session.sh"
  if [ ! -f "${hk}" ]; then record_fail "worklog-capture-session" "hook ausente: ${hk}"; return; fi
  local d rc out

  d="$(mktemp -d)"
  git -C "${d}" init -q
  git -C "${d}" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  git -C "${d}" checkout -q -b "feature/test-slug"
  mkdir -p "${d}/.claude/hooks" "${d}/.claude/sessions/test-slug"
  cp "${hk}" "${d}/.claude/hooks/"

  # payload REAL do SessionStart: multi-campo, session_id fora da 1ª posição
  # (stress-test do fallback regex, que não pode depender de ordem de chave)
  local payload='{"hook_event_name":"SessionStart","cwd":"/x","transcript_path":"/y.jsonl","session_id":"sess-real-001","source":"startup"}'

  # (a) STATE.md SEM '## Native transcript' prévio → cria a seção + a linha
  printf '# STATE — test-slug\n\n## NEXT\nphase: 1\n' > "${d}/.claude/sessions/test-slug/STATE.md"
  rc=0; (cd "${d}" && printf '%s' "${payload}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null || rc=$?
  if [ "${rc}" -eq 0 ] && grep -qx 'resume_command: claude --resume sess-real-001' "${d}/.claude/sessions/test-slug/STATE.md"; then
    record_pass "worklog-capture-session: (a) sem seção prévia → cria '## Native transcript' + resume_command (exit 0)"
  else record_fail "worklog-capture-session: (a) cria seção" "esperava a linha de resume_command; rc=${rc}; conteúdo: $(cat "${d}/.claude/sessions/test-slug/STATE.md")"; fi

  # (b) shape REAL do /engineer/start.md (linha 143-144): STATE.md JÁ NASCE
  # com o placeholder `resume_command: claude --resume <id>   # conveniência
  # opcional (...)`. Este É o caminho de produção — (a) sozinho testaria uma
  # forma que o template real nunca produz.
  printf '# STATE — test-slug\n\n## NEXT\nphase: 1\n\n## Native transcript\nresume_command: claude --resume <id>   # conveniência opcional (colada pelo usuário/hook)\n' \
    > "${d}/.claude/sessions/test-slug/STATE.md"
  rc=0; (cd "${d}" && printf '%s' "${payload}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null || rc=$?
  if [ "${rc}" -eq 0 ] \
     && grep -qx 'resume_command: claude --resume sess-real-001' "${d}/.claude/sessions/test-slug/STATE.md" \
     && [ "$(grep -c '^resume_command:' "${d}/.claude/sessions/test-slug/STATE.md")" = "1" ]; then
    record_pass "worklog-capture-session: (b) placeholder do template real (/engineer/start.md) → substituído, sem duplicar"
  else record_fail "worklog-capture-session: (b) placeholder" "esperava 1 linha resume_command substituída; conteúdo: $(cat "${d}/.claude/sessions/test-slug/STATE.md")"; fi

  # (c) idempotência: mesmo session_id de novo → NO-OP, arquivo byte-a-byte
  # IGUAL (guarda contra o STATE.md crescer a cada SessionStart da mesma
  # sessão — o próprio hook nasceu de um incidente de subcobertura, ver
  # header do hook linhas 9-15; um regressor aqui apaga o instrumento de
  # dogfood que ele mesmo existe para alimentar).
  local before after
  before="$(cat "${d}/.claude/sessions/test-slug/STATE.md")"
  rc=0; (cd "${d}" && printf '%s' "${payload}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null || rc=$?
  after="$(cat "${d}/.claude/sessions/test-slug/STATE.md")"
  if [ "${rc}" -eq 0 ] && [ "${before}" = "${after}" ]; then
    record_pass "worklog-capture-session: (c) re-run com o MESMO session_id → no-op idempotente (arquivo intocado)"
  else record_fail "worklog-capture-session: (c) idempotência" "esperava arquivo igual; before/after divergem ou rc=${rc}"; fi

  # (d) NOVO session_id na mesma sessão (ex.: /clear, nova janela) →
  # substitui, continua com EXATAMENTE 1 linha (não acumula histórico)
  local payload2='{"session_id":"sess-real-002","hook_event_name":"SessionStart","source":"resume"}'
  rc=0; (cd "${d}" && printf '%s' "${payload2}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null || rc=$?
  if [ "${rc}" -eq 0 ] \
     && grep -qx 'resume_command: claude --resume sess-real-002' "${d}/.claude/sessions/test-slug/STATE.md" \
     && [ "$(grep -c '^resume_command:' "${d}/.claude/sessions/test-slug/STATE.md")" = "1" ]; then
    record_pass "worklog-capture-session: (d) novo session_id → substitui, continua com 1 linha só"
  else record_fail "worklog-capture-session: (d) novo sid" "esperava a linha nova e única; conteúdo: $(cat "${d}/.claude/sessions/test-slug/STATE.md")"; fi

  # (e) sem session_id no payload (harness antigo/malformado) → no-op total,
  # exit 0, NENHUMA mutação (com jq presente)
  before="$(cat "${d}/.claude/sessions/test-slug/STATE.md")"
  rc=0; (cd "${d}" && printf '{"hook_event_name":"SessionStart"}' | bash .claude/hooks/worklog-capture-session.sh) >/dev/null || rc=$?
  after="$(cat "${d}/.claude/sessions/test-slug/STATE.md")"
  if [ "${rc}" -eq 0 ] && [ "${before}" = "${after}" ]; then
    record_pass "worklog-capture-session: (e) payload sem session_id → no-op silencioso (exit 0, arquivo intocado)"
  else record_fail "worklog-capture-session: (e) sem session_id" "esperava no-op; rc=${rc}"; fi

  # (f) branch SEM prefixo (ex.: main) → no-op, NENHUM diretório
  # .claude/sessions/<branch> fantasma é criado (guarda contra slug
  # mal-parseado escrever fora do worklog certo)
  git -C "${d}" checkout -q -b main-selftest
  rc=0; (cd "${d}" && printf '%s' "${payload}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null || rc=$?
  if [ "${rc}" -eq 0 ] && [ ! -d "${d}/.claude/sessions/main-selftest" ]; then
    record_pass "worklog-capture-session: (f) branch sem prefixo → no-op, sem criar worklog fantasma"
  else record_fail "worklog-capture-session: (f) branch sem prefixo" "esperava no-op; rc=${rc}"; fi
  git -C "${d}" checkout -q feature/test-slug

  # ---- MODO DE FALHA SILENCIOSO ALVEJADO: fallback sem jq, payload REAL ----
  # Esconde jq do PATH (não desinstala — cria um PATH mínimo simbólico) e
  # prova que `command -v jq` falha de fato e que o grep/sed do fallback
  # (linha 22) extrai o session_id do payload MULTI-CAMPO de produção.
  local nojq_dir; nojq_dir="$(mktemp -d)"
  local b p
  for b in bash cat git grep head mktemp mv printf rm sed mkdir; do
    p="$(command -v "${b}" 2>/dev/null)" && ln -sf "${p}" "${nojq_dir}/${b}"
  done

  # (g) guarda: sem jq no PATH restrito, `command -v jq` REALMENTE falha
  # (senão o caso (h) estaria testando o caminho errado — o mesmo erro
  # apontado no aviso desta tarefa: validar a superfície que ninguém usa)
  # `|| rc=$?` e NÃO `; rc=$?`: o runner roda sob `set -euo pipefail` (linha 41), e este
  # comando DEVE falhar (é o ponto do teste — jq ausente). Com `;` o shell morre ANTES de
  # capturar, levando o selftest INTEIRO junto. Achado ao rodar o gate real: a bancada onde
  # esta função foi escrita não tinha `set -e`, então passava lá e matava aqui — o mesmo
  # "testar a superfície errada" que esta bateria existe para pegar, uma camada acima.
  rc=0; (PATH="${nojq_dir}" command -v jq >/dev/null 2>&1) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    record_pass "worklog-capture-session: (g) guarda — jq de fato AUSENTE do PATH restrito (o (h) mira o caminho certo)"
  else
    record_fail "worklog-capture-session: (g) guarda jq ausente" "jq ainda visível no PATH restrito — (h) testaria o caminho errado"
  fi

  # (h) fallback grep/sed, SEM jq, payload real multi-campo fora de ordem →
  # extrai sess-real-001 corretamente e atualiza o STATE.md (o caminho que
  # roda em qualquer clone sem jq instalado — hoje 0% coberto). Falsificado:
  # com o regex do fallback quebrado de propósito, este caso REPROVA (out vazio,
  # STATE.md intocado) — prova que não é vacuamente verde.
  printf '# STATE — test-slug\n\n## NEXT\nphase: 1\n' > "${d}/.claude/sessions/test-slug/STATE.md"
  rc=0; out="$(cd "${d}" && PATH="${nojq_dir}" bash .claude/hooks/worklog-capture-session.sh <<< "${payload}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && grep -qx 'resume_command: claude --resume sess-real-001' "${d}/.claude/sessions/test-slug/STATE.md"; then
    record_pass "worklog-capture-session: (h) SEM jq — fallback grep/sed extrai session_id do payload real (campo fora de ordem)"
  else record_fail "worklog-capture-session: (h) fallback sem jq" "esperava resume_command com sess-real-001; rc=${rc}; out=${out}"; fi

  # ---- MUTATION TEST com guarda-da-guarda ----
  # Neutraliza a detecção `grep -q '^resume_command:'` (linha 37 — decide
  # ATUALIZAR vs APPENDAR) para nunca casar → o hook mutante SEMPRE cai no
  # ramo `else` (append), mesmo quando a linha já existe. Prova que a
  # detecção é load-bearing: sem ela, cada SessionStart duplica a seção
  # `## Native transcript` — crescimento silencioso do STATE.md.
  local mut="${d}/.claude/hooks/worklog-capture-session.sh"
  cp "${hk}" "${mut}"
  sed -i.bak "s|if grep -q '^resume_command:' \"\\\$state\" 2>/dev/null; then|if false; then|" "${mut}"
  if ! grep -q "if false; then" "${mut}"; then
    record_fail "worklog-capture-session: (i) mutation" "a mutação não foi aplicada — âncora do sed mudou; o teste não prova nada"
  else
    printf '# STATE — test-slug\n\n## NEXT\nphase: 1\n\n## Native transcript\nresume_command: claude --resume sess-old\n' \
      > "${d}/.claude/sessions/test-slug/STATE.md"
    (cd "${d}" && printf '%s' "${payload}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null 2>&1
    (cd "${d}" && printf '%s' "${payload2}" | bash .claude/hooks/worklog-capture-session.sh) >/dev/null 2>&1
    local n_dup; n_dup="$(grep -c '^resume_command:' "${d}/.claude/sessions/test-slug/STATE.md")"
    if [ "${n_dup}" -gt 1 ]; then
      record_pass "worklog-capture-session: (i) MUTATION TEST — sem a detecção, 2 SessionStart duplicam resume_command (${n_dup} linhas); a detecção original é load-bearing"
    else
      record_fail "worklog-capture-session: (i) mutation" "com a detecção DESFEITA o arquivo ainda tem ${n_dup} linha(s) — o teste não é load-bearing"
    fi
  fi

  rm -rf "${d}" "${nojq_dir}"
}

# Guardas do statusFactor — os status de RE-VERIFICAÇÃO (`drifted`/`unverifiable`).
#
# POR QUE EXISTEM (Elenxo sobre as decisões de norte, 2026-08-06): o plano ia construir o "selo
# mecânico" (medição que existe e não foi selada reprova) ANTES de o schema ter onde pousar o
# resultado. Verificado em sandbox, com o status como ÚNICA variável:
#   confirmed → atenção 10,0 · drifted → EXIT 1 "status inválido" · refuted → atenção SOME (0.0)
# Ou seja: selar um drift só dava para ser RECUSADO ou para MENTIR de `refuted` — e o segundo é
# pior que o vazamento que curaria, porque APAGA o sinal em vez de perdê-lo. O terceiro caminho,
# praticado por falta de slot, foi apensar nós à mão (identidade, 2026-08-04: 16 nós).
# SCHEMA PRIMEIRO. Estes casos são o contrato desse slot.
run_status_reverificacao_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local d; d="$(mktemp -d)"
  local st rc out att

  _mkst() {   # grafo de 2 nós; o status de C_A é a ÚNICA variável (sem órfão, sem confundidor)
    printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: C_A\n    node_type: claim\n    plane: PROD\n    impact: 5\n    confidence: 1.0\n    status: %s\n    label: "x"\n  - id: C_B\n    node_type: claim\n    plane: DEV\n    impact: 2\n    confidence: 1.0\n    status: confirmed\n    label: "y"\nedges:\n  - from: C_A\n    to: C_B\n    edge_type: SUPPORTS\n' "$1" > "${d}/x.kg.yaml"
  }
  _att() { grep -E '^[[:space:]]+[0-9.]+[[:space:]]+C_A' "$1" | head -1 | awk '{print $1}'; }

  # (a) `drifted` é status LEGAL — antes disto o radar saía 1 com "status inválido"
  _mkst drifted; rc=0; bash "${radar}" "${d}/x.kg.yaml" > "${d}/o.txt" 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "status-reverif: (a) \`drifted\` é legal (era exit 1, status inválido)"
  else record_fail "status-reverif: (a) drifted legal" "rc=${rc} out=$(cat "${d}/o.txt")"; fi

  # (b) drift SOBE no radar. É a cláusula que carrega o desenho: um nó que provou que a realidade
  #     andou é MAIS urgente que um confirmado de mesmo peso, não menos.
  att="$(_att "${d}/o.txt")"
  _mkst confirmed; bash "${radar}" "${d}/x.kg.yaml" > "${d}/c.txt" 2>&1 || true
  local attc; attc="$(_att "${d}/c.txt")"
  if awk -v a="${att:-0}" -v c="${attc:-0}" 'BEGIN{exit !(a > c)}'; then
    record_pass "status-reverif: (b) drifted (${att}) SOBE acima de confirmed (${attc}) — drift aumenta atenção"
  else record_fail "status-reverif: (b) drifted sobe" "drifted=${att} confirmed=${attc}"; fi

  # (c) `unverifiable` é legal e segue tão urgente quanto aberto — silenciar o que não se sabe
  #     medir é o oposto do declarado!=verificado.
  _mkst unverifiable; rc=0; bash "${radar}" "${d}/x.kg.yaml" > "${d}/u.txt" 2>&1 || rc=$?
  local attu; attu="$(_att "${d}/u.txt")"
  if [ "${rc}" -eq 0 ] && awk -v u="${attu:-0}" -v c="${attc:-0}" 'BEGIN{exit !(u == c)}'; then
    record_pass "status-reverif: (c) \`unverifiable\` legal e tão urgente quanto aberto (${attu})"
  else record_fail "status-reverif: (c) unverifiable" "rc=${rc} att=${attu} vs confirmed=${attc}"; fi

  # (d) O CONTRASTE QUE JUSTIFICA TUDO: `refuted` continua zerando a atenção. Sem este caso,
  #     (a)-(c) não provam por que o slot novo precisou existir — provam só que ele existe.
  _mkst refuted; bash "${radar}" "${d}/x.kg.yaml" > "${d}/r.txt" 2>&1 || true
  if [ -z "$(_att "${d}/r.txt")" ]; then
    record_pass "status-reverif: (d) \`refuted\` segue SUMINDO do radar — selar drift ali apagaria o sinal"
  else record_fail "status-reverif: (d) refuted zera" "refuted apareceu com atenção $(_att "${d}/r.txt")"; fi

  # (e) status FORA do enum continua REPROVANDO — a porta não ficou aberta ao abrir o slot.
  _mkst bananinha; rc=0; bash "${radar}" "${d}/x.kg.yaml" > "${d}/b.txt" 2>&1 || rc=$?
  if [ "${rc}" -ne 0 ] && grep -q 'inválido' "${d}/b.txt"; then
    record_pass "status-reverif: (e) status fora do enum ainda reprova (o slot novo não abriu a porta)"
  else record_fail "status-reverif: (e) enum fechado" "rc=${rc} out=$(cat "${d}/b.txt")"; fi

  # (f) (MUT) sem o fator de `drifted`, o status volta a ser inválido — prova que a linha é
  #     load-bearing e que (a)-(c) não passam por outro motivo.
    # ⚠️ A MUTACAO MUDOU DE ARQUIVO: desde o SITIO UNICO (2026-08-09) o fator vive em
    # `lib/status-factor.awk`, nao no script. Mutar `m.sh` virou no-op — e a guarda
    # `! grep -q ... m.sh` ficou VACUA POR INVERSAO: a linha nunca esteve la, entao a negacao e
    # sempre verdadeira e o caso seguia como se tivesse mutado. A prova agora e `cmp` de ARQUIVO,
    # nao grep de padrao — a mesma licao que derrubou tres guardas-da-guarda em 2026-08-07.
  local mut; mut="$(mktemp -d)"; cp "${radar}" "${mut}/m.sh"; _lib_beside "${mut}"
    sed -i 's|^  if (s == "drifted") return 1.3$||' "${mut}/lib/status-factor.awk"
    if ! cmp -s "${SCRIPT_DIR}/lib/status-factor.awk" "${mut}/lib/status-factor.awk"; then
    _mkst drifted; rc=0; bash "${mut}/m.sh" "${d}/x.kg.yaml" >/dev/null 2>&1 || rc=$?
    if [ "${rc}" -ne 0 ]; then record_pass "status-reverif: (f) (MUT) sem o fator, \`drifted\` volta a ser inválido — a linha é load-bearing"
    else record_fail "status-reverif: (f) (MUT)" "sem o fator o radar ainda aceitou drifted (rc=${rc})"; fi
  else record_fail "status-reverif: (f) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"; fi
  rm -rf "${mut}" "${d}"
}

# Guardas do bloco RECONCILIAÇÃO do kg-radar.sh — o PRIMEIRO teste deste bloco.
#
# POR QUE EXISTE (medido 2026-08-05): a INTEGRIDADE cobra contradição só para REFUTES
# (kg-radar.sh:438). SUPERSEDES passava em silêncio — e de 137 arestas SUPERSEDES no corpus, 15
# apontavam para alvo ainda `confirmed`/`open`. A triagem dos 15 mostrou que virar o status seria
# ERRADO em 12 deles (8 eram CONSTRAINS, 4 eram `done`), o que é a razão de a guarda NOMEAR e não
# reprovar. Este selftest existe para que a guarda não vire nem falso-positivo nem vacuidade.
run_kg_reconcile_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local rx="${FIX_DIR}/kg-reconcile"
  local out rc

  # (a) OS DOIS LADOS NO MESMO GRAFO — acusa o alvo vivo e a pergunta respondida; cala nos quatro
  # 🔒 A INVARIANTE, NOMEADA — o radar PRODUZ SAÍDA. Antes de qualquer veredito sobre o CONTEÚDO,
  # prove que houve conteúdo.
  #
  # INCIDENTE OBSERVADO (2026-08-07): o programa awk inteiro vive dentro de aspas simples do
  # shell. Escrevendo o comentário do bloco denylist, entraram DUAS aspas simples e um `||`; as
  # aspas fecharam a string do awk e o `||` virou operador de SHELL, curto-circuitando o comando.
  # Resultado medido: kg-radar.sh imprimindo ZERO linhas com EXIT 0, em qualquer grafo. `bash -n`
  # passou limpo. O sintoma foram 6 casos desta função falhando com `out=` VAZIO, sem dizer o quê.
  #
  # HONESTIDADE SOBRE O ALCANCE: NÃO consegui reproduzir o silêncio por mutação sintética — as
  # quatro tentativas (1 aspa, 2 aspas, com/sem `||`, dentro/fora do bloco awk) falharam ALTO
  # (exit 1, 2, 127). Ou seja: a maioria das injeções de aspa é barulhenta, e o caso silencioso
  # é raro e depende do texto exato. Logo esta guarda NÃO está provada por mutação; ela nasce de
  # um incidente medido e cobre o sintoma observado (zero linhas). Vale por ser barata e por
  # NOMEAR a falha — não a trate como prova de que a classe inteira está coberta.
  local viv; viv="$(bash "${radar}" "${rx}/supersedes-mixed.kg.yaml" --reconcile 2>&1 | wc -l)"
  if [ "${viv}" -gt 0 ]; then
    record_pass "kg-reconcile: radar VIVO — produz saída (aspa simples em comentário do awk trunca o programa e imprime nada com exit 0)"
  else
    record_fail "kg-reconcile: radar MUDO" "kg-radar.sh imprimiu ZERO linhas com exit 0 — programa awk truncado? procure aspa simples introduzida num comentário dentro do bloco awk"
    return
  fi

  # que estão certos. Sem o lado negativo, "consertar" seria alargar a guarda e chamar de fix.
  rc=0; out=$(bash "${radar}" "${rx}/supersedes-mixed.kg.yaml" --reconcile 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q '⚠ D_ALVO_VIVO: recebe SUPERSEDES' \
     && printf '%s' "${out}" | grep -q '⚠ Q_RESPONDIDA: pergunta RESPONDIDA' \
     && printf '%s' "${out}" | grep -q '⚠ C_ALVO_DE_DRIFTED' \
     && printf '%s' "${out}" | grep -q '⚠ D_ALVO_DRIFTED' \
     && ! printf '%s' "${out}" | grep -q '⚠ D_JA_RECONCILIADO' \
     && ! printf '%s' "${out}" | grep -q '⚠ Q_JA_FECHADA' \
     && ! printf '%s' "${out}" | grep -q '⚠ C_SUPERSEDER_ABERTO' \
     && ! printf '%s' "${out}" | grep -q '⚠ C_SO_REFUTES' \
     && [ "$(printf '%s' "${out}" | grep -c '⚠ ')" -eq 4 ]; then
    record_pass "kg-reconcile: (a) acusa EXATAMENTE 4 (alvo-vivo, pergunta-respondida e os dois de drifted); cala em reconciliado/fechado/superseder-aberto/REFUTES"
  else record_fail "kg-reconcile: (a) dois lados" "rc=${rc} out=${out}"; fi

  # (b) MENSAGEM PRÓPRIA POR TIPO — `question` recebe "fechar como done", não "reconciliar".
  # A distinção não é cosmética: pergunta respondida NÃO é história superada, e mandar virar
  # `superseded` produziria dado errado (4 dos 15 casos reais eram exatamente isto).
  if printf '%s' "${out}" | grep -q 'Q_RESPONDIDA.*fechar como .done.' \
     && printf '%s' "${out}" | grep -q 'D_ALVO_VIVO.*CONSTRAINS.*REFINA'; then
    record_pass "kg-reconcile: (b) mensagem por tipo — question→done, decisão→menu de 3 remédios"
  else record_fail "kg-reconcile: (b) mensagem por tipo" "out=${out}"; fi

  # (c) A FIXTURE É ÍNTEGRA no que esta guarda cobre — sem isso, (a) e (b) seriam veredito sobre
  # grafo quebrado. Ressalva declarada: a fixture TEM um alvo de REFUTES não reconciliado de
  # propósito (C_SO_REFUTES), então --integrity reprova por desenho. O que se assere aqui é que a
  # reprovação é EXATAMENTE essa e nenhuma outra.
  rc=0; out=$(bash "${radar}" "${rx}/supersedes-mixed.kg.yaml" --integrity 2>&1) || rc=$?
  if [ "${rc}" -eq 1 ] \
     && printf '%s' "${out}" | grep -q 'CONTRADIÇÃO: C_SO_REFUTES' \
     && [ "$(printf '%s' "${out}" | grep -c '✗ ')" -eq 1 ]; then
    record_pass "kg-reconcile: (c) fixture íntegra — a única reprovação é o REFUTES declarado"
  else record_fail "kg-reconcile: (c) integridade da fixture" "rc=${rc} out=${out}"; fi

  # (d) (MUT) — removido o filtro de superseder-vivo, C_SUPERSEDER_ABERTO VOLTA a ser acusado.
  # Sem esta prova, (a) passaria igual se o filtro fosse vacuidade (ex.: se nenhum superseder da
  # fixture estivesse `open`). É o padrão guarda-da-guarda: se a mutação não aplicar, o teste
  # FALHA em vez de passar por omissão.
  local mut; mut="$(mktemp -d)"; trap 'rm -rf "'"${mut}"'"' RETURN
  cp "${radar}" "${mut}/mutado.sh"; _lib_beside "${mut}"
  sed -i 's/ \&\& supersederConta(nstatus\[efrom\[i\]\])//' "${mut}/mutado.sh"
  if ! grep -q 'etype\[i\] == "SUPERSEDES" && supersederConta' "${mut}/mutado.sh"; then
    local mout; mout="$(bash "${mut}/mutado.sh" "${rx}/supersedes-mixed.kg.yaml" --reconcile 2>&1 || true)"
    if printf '%s' "${mout}" | grep -q '⚠ C_SUPERSEDER_ABERTO'; then
      record_pass "kg-reconcile: (d) (MUT) sem o filtro o superseder-aberto volta a acusar — o filtro é load-bearing"
    else record_fail "kg-reconcile: (d) (MUT)" "mutação não mudou o veredito — o filtro é vacuidade? out=${mout}"; fi
  else
    record_fail "kg-reconcile: (d) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi

  # (e) (MUT) — removida a guarda inteira, o ⚠ some. Prova que as linhas novas são o que produz o
  # veredito, e não algum efeito colateral do bloco antigo.
  local mut2; mut2="$(mktemp -d)"; trap 'rm -rf "'"${mut}"'" "'"${mut2}"'"' RETURN
  cp "${radar}" "${mut2}/mutado.sh"; _lib_beside "${mut2}"
  sed -i '/supersededByLive\[id\] > 0/,+6d' "${mut2}/mutado.sh"
  if ! grep -q 'supersededByLive\[id\] > 0' "${mut2}/mutado.sh"; then
    local mout2; mout2="$(bash "${mut2}/mutado.sh" "${rx}/supersedes-mixed.kg.yaml" --reconcile 2>&1 || true)"
    if ! printf '%s' "${mout2}" | grep -q '⚠ '; then
      record_pass "kg-reconcile: (e) (MUT) sem a guarda o ⚠ some — a guarda é quem produz o veredito"
    else record_fail "kg-reconcile: (e) (MUT)" "⚠ sobreviveu à remoção da guarda: out=${mout2}"; fi
  else
    record_fail "kg-reconcile: (e) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi

  # (f) (MUT) A DENYLIST É QUEM COMPRA OS DOIS CASOS DE `drifted` — reverter os predicados às
  # ALLOWLISTS de antes de 2026-08-07 tem de fazer C_ALVO_DE_DRIFTED e D_ALVO_DRIFTED SUMIREM,
  # e os dois casos antigos SOBREVIVEREM. Sem esta prova, (a) não distingue "a denylist funciona"
  # de "a fixture nova acusaria de qualquer jeito" — e a troca seria indistinguível de no-op.
  # Medido no diff real: radar do main dá 2 avisos nesta fixture, o corrigido dá 4.
  local mut3; mut3="$(mktemp -d)"; trap 'rm -rf "'"${mut}"'" "'"${mut2}"'" "'"${mut3}"'"' RETURN
  cp "${radar}" "${mut3}/mutado.sh"; _lib_beside "${mut3}"
  # ⚠️ Os dois `sed` casam a ASSINATURA das funções. Se ela mudar (como mudou quando `pendingTarget`
  # ganhou o parâmetro de tipo), eles param de casar — e é por isso que o `if` abaixo verifica o
  # resultado: mutação que não pega dá record_fail explícito, nunca silêncio.
  sed -i 's/^function supersederConta(s) .*/function supersederConta(s) { return (s == "confirmed") }/' "${mut3}/mutado.sh"
  sed -i 's/^function pendingTarget(s, t) .*/function pendingTarget(s, t) { return (s == "confirmed" || s == "open") }/' "${mut3}/mutado.sh"
  if grep -q 'supersederConta(s) { return (s == "confirmed") }' "${mut3}/mutado.sh" \
     && grep -q 'pendingTarget(s, t) { return (s == "confirmed" || s == "open") }' "${mut3}/mutado.sh"; then
    local mout3; mout3="$(bash "${mut3}/mutado.sh" "${rx}/supersedes-mixed.kg.yaml" --reconcile 2>&1 || true)"
    if ! printf '%s' "${mout3}" | grep -q '⚠ C_ALVO_DE_DRIFTED' \
       && ! printf '%s' "${mout3}" | grep -q '⚠ D_ALVO_DRIFTED' \
       && printf '%s' "${mout3}" | grep -q '⚠ D_ALVO_VIVO' \
       && printf '%s' "${mout3}" | grep -q '⚠ Q_RESPONDIDA'; then
      record_pass "kg-reconcile: (f) (MUT) sob a allowlist antiga os DOIS casos de drifted somem e os antigos ficam — a denylist é load-bearing"
    else record_fail "kg-reconcile: (f) (MUT) denylist" "a allowlist antiga não mudou o veredito dos drifted: out=${mout3}"; fi
  else
    record_fail "kg-reconcile: (f) (MUT) denylist" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi

  # (g) O LADO QUE REPROVA — contradição de REFUTES com alvo em status NOVO. É o único sítio da
  # troca que sai ✗ HARD (exit 1); os outros dois só emitem ⚠. Achado do Elenxo 2026-08-07: era o
  # único SEM COBERTURA NENHUMA — revertendo só essa chamada e comparando os dois binários sobre
  # os 73 .kg.yaml × 6 modos, deram 0 diffs em 438 comparações. A linha que pode travar o CI era
  # a que ninguém podia mexer com segurança. Fixture SEPARADA porque (c) assere contagem na outra.
  rc=0; out=$(bash "${radar}" "${rx}/refutes-drifted.kg.yaml" --integrity 2>&1) || rc=$?
  if [ "${rc}" -eq 1 ] \
     && printf '%s' "${out}" | grep -q 'CONTRADIÇÃO: C_ALVO_DRIFTED_REFUTADO' \
     && printf '%s' "${out}" | grep -q 'CONTRADIÇÃO: C_ALVO_UNVER_REFUTADO' \
     && ! printf '%s' "${out}" | grep -q 'C_ALVO_JA_REFUTADO' \
     && ! printf '%s' "${out}" | grep -q 'Q_FECHADA_REFUTADA' \
     && [ "$(printf '%s' "${out}" | grep -c '✗ ')" -eq 2 ]; then
    record_pass "kg-reconcile: (g) REFUTES em alvo drifted/unverifiable REPROVA (exatamente 2 ✗); cala em já-refutado e question-done"
  else record_fail "kg-reconcile: (g) lado HARD" "rc=${rc} out=${out}"; fi

  # (g-MUT) e a prova de que é a denylist que compra o (g): revertida SÓ a chamada do sítio HARD,
  # os dois ✗ têm de SUMIR. Sem isto, (g) não distingue "a correção funciona" de "a fixture
  # reprovaria de qualquer jeito".
  local mut4; mut4="$(mktemp -d)"; trap 'rm -rf "'"${mut}"'" "'"${mut2}"'" "'"${mut3}"'" "'"${mut4}"'"' RETURN
  cp "${radar}" "${mut4}/mutado.sh"; _lib_beside "${mut4}"
  sed -i 's/if (refutedBy\[id\] > 0 \&\& pendingTarget(nstatus\[id\], ntype\[id\])) {/if (refutedBy[id] > 0 \&\& (nstatus[id] == "confirmed" || nstatus[id] == "open")) {/' "${mut4}/mutado.sh"
  if grep -q 'refutedBy\[id\] > 0 && (nstatus\[id\] == "confirmed"' "${mut4}/mutado.sh"; then
    local mout4; mout4="$(bash "${mut4}/mutado.sh" "${rx}/refutes-drifted.kg.yaml" --integrity 2>&1 || true)"
    if [ "$(printf '%s' "${mout4}" | grep -c '✗ ')" -eq 0 ]; then
      record_pass "kg-reconcile: (g-MUT) sob a allowlist antiga o sítio HARD fica CEGO — a denylist é quem reprova"
    else record_fail "kg-reconcile: (g-MUT)" "a allowlist antiga ainda reprovou: out=${mout4}"; fi
  else
    record_fail "kg-reconcile: (g-MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi

  # (h) A EXCLUSÃO DE `done` É POR TIPO, NÃO POR STATUS. A 1ª versão excluía `done` de todos os
  # tipos e com isso calava exatamente o defeito que este arquivo cura: uma `decision` fechada,
  # superada por nó vivo, saía com "✅ nenhum alvo por reconciliar". A razão antiga ("criaria 11
  # acusações novas") era verdadeira no número e errada no motivo — os 11 são question, 11/11.
  local dz; dz="$(mktemp -d)"
  { printf 'meta:\n  id: t\n  schema_version: "1"\n  baseline: 2026-07-01\nnodes:\n'
    printf '  - id: D_DEC_DONE\n    node_type: decision\n    plane: DEV\n    impact: 4\n    confidence: 1.0\n    status: done\n    label: "decisao fechada superada por no vivo"\n'
    printf '  - id: Q_Q_DONE\n    node_type: question\n    plane: DEV\n    impact: 4\n    confidence: 1.0\n    status: done\n    label: "pergunta fechada como done — o remedio prescrito"\n'
    printf '  - id: C_VIVO\n    node_type: claim\n    plane: DEV\n    impact: 3\n    confidence: 1.0\n    status: confirmed\n    label: "superseder vivo"\n'
    printf 'edges:\n  - from: C_VIVO\n    to: D_DEC_DONE\n    edge_type: SUPERSEDES\n'
    printf '  - from: C_VIVO\n    to: Q_Q_DONE\n    edge_type: SUPERSEDES\n'
  } > "${dz}/tipado.kg.yaml"
  out="$(bash "${radar}" "${dz}/tipado.kg.yaml" --reconcile 2>&1 || true)"
  if printf '%s' "${out}" | grep -q '⚠ D_DEC_DONE' && ! printf '%s' "${out}" | grep -q '⚠ Q_Q_DONE'; then
    record_pass "kg-reconcile: (h) done fica fora SÓ para question — decisão fechada e superada ACUSA (era fail-open com a assinatura do defeito que o arquivo cura)"
  else record_fail "kg-reconcile: (h) exclusão tipada" "out=${out}"; fi
  rm -rf "${dz}"
}

run_kg_provenance_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local px="${FIX_DIR}/kg-provenance"
  local out rc

  # (a) mixed --provenance: SÓ a decisão VIVA sem chão (D_ORPHAN) é avisada. As ancoradas
  # (aresta/inline), a reconciliada (superseded) e a claim NÃO — os dois lados no mesmo caso
  # (senão "consertar" seria matar a guarda). exit 0 (aviso, não reprova).
  rc=0; out=$(bash "${radar}" "${px}/provenance-mixed.kg.yaml" --provenance 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q 'decisão-sem-proveniência: D_ORPHAN' \
     && ! printf '%s' "${out}" | grep -q 'D_TRACED' \
     && ! printf '%s' "${out}" | grep -q 'D_INLINE' \
     && ! printf '%s' "${out}" | grep -q 'D_DEAD' \
     && ! printf '%s' "${out}" | grep -q 'C_CLAIM'; then
    record_pass "kg-provenance: decisão viva sem chão avisada; ancorada/superseded/claim NÃO (aviso, exit 0)"
  else record_fail "kg-provenance: mixed" "rc=${rc} out=${out}"; fi

  # (b) mixed --integrity: a fixture é um KG estruturalmente válido → exit 0 (senão o veredito
  # de (a) seria sobre um grafo quebrado — a guarda tem que rodar sobre um KG legível).
  rc=0; out=$(bash "${radar}" "${px}/provenance-mixed.kg.yaml" --integrity 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'sem contradições estruturais'; then
    record_pass "kg-provenance: fixture mixed é KG válido (integridade verde)"
  else record_fail "kg-provenance: mixed integrity" "esperava exit 0 + integridade verde; rc=${rc} out=${out}"; fi

  # (c) clean --provenance: toda decisão viva ancorada → NENHUM ⚠, imprime ✅ + exit 0 (não
  # falso-positivar o que tem chão — o par "good" que prova que a guarda fica quieta).
  rc=0; out=$(bash "${radar}" "${px}/provenance-clean.kg.yaml" --provenance 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && ! printf '%s' "${out}" | grep -q 'decisão-sem-proveniência' \
     && printf '%s' "${out}" | grep -q '✅ 2 decisão'; then
    record_pass "kg-provenance: toda decisão viva ancorada → ✅, sem falso-positivo"
  else record_fail "kg-provenance: clean" "esperava ✅ sem ⚠; rc=${rc} out=${out}"; fi
}

# ---------------------------------------------------------------------------
# Modo kg-label-collision — CONTEÚDO não é CONFIGURAÇÃO. O parser do kg-radar.sh é line-based;
# antes da âncora `^[[:space:]]*<campo>:`, um label que CITASSE um token de campo era lido como
# valor daquele campo e REPROVAVA um grafo correto. Sinal de campo da estrela onion-pessoal-app
# (2026-07-19): `label: "66 nos, TODOS layer:audit, ZERO domain"` → "✗ layer inválido".
# Fixtures temporários (self-contained, não vêm do manifest) + cleanup via trap.
# Os DOIS lados no mesmo caso: (a) label citando token NÃO confunde, (c) enum inválido em POSIÇÃO
# DE CAMPO continua reprovando — senão "consertar" seria matar a guarda e chamar de fix.
# ---------------------------------------------------------------------------
run_kg_label_collision_selftests() {
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  local tmp out rc
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN

  cat > "${tmp}/label-collision.kg.yaml" <<'KGEOF'
# Fixture temporário: labels que CITAM tokens de campo. Grafo estruturalmente VÁLIDO.
meta:
  id: fixture-label-collision
  schema_version: "1"
  baseline: 2026-07-01
nodes:
  - id: C_TRAP
    node_type: claim
    layer: audit
    plane: DEV
    impact: 3
    confidence: 0.9
    status: confirmed
    label: "66 nos, TODOS layer:audit, ZERO domain"
  - id: A_SRC
    node_type: artifact
    layer: audit
    plane: DEV
    impact: 2
    confidence: 1.0
    status: confirmed
    label: "node_type:evidence plane:PROD status:open impact:5 confidence:0.1 sao citacoes"
edges:
  - from: C_TRAP
    to: A_SRC
    edge_type: SUPPORTS
KGEOF

  cat > "${tmp}/enum-real.kg.yaml" <<'KGEOF'
# Par "bad": o MESMO token, agora em posição de campo → tem que continuar reprovando.
meta:
  id: fixture-enum-real
  schema_version: "1"
  baseline: 2026-07-01
nodes:
  - id: C_BAD
    node_type: claim
    layer: nao-existe
    plane: DEV
    impact: 3
    confidence: 0.9
    status: confirmed
    label: "layer invalido de verdade"
  - id: A_SRC
    node_type: artifact
    layer: audit
    plane: DEV
    impact: 2
    confidence: 1.0
    status: confirmed
    label: "artefato ok"
edges:
  - from: C_BAD
    to: A_SRC
    edge_type: SUPPORTS
KGEOF

  # (a) integridade: label citando "layer:"/"node_type:"/"plane:"/"status:" NÃO vira configuração
  rc=0; out=$(bash "${radar}" "${tmp}/label-collision.kg.yaml" --integrity 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q 'sem contradições estruturais' \
     && ! printf '%s' "${out}" | grep -q 'inválido'; then
    record_pass "kg-label-collision: label citando token de campo → integridade verde (conteúdo ≠ configuração)"
  else record_fail "kg-label-collision: label não confunde" "esperava exit 0 sem 'inválido'; rc=${rc} out=${out}"; fi

  # (b) o valor REAL continua sendo lido (não basta ignorar o label — o campo tem que valer):
  # peso de C_TRAP = impact 3 × confidence 0.9 × status confirmed (1.0) × grau 2 = 5.4, plano DEV.
  rc=0; out=$(bash "${radar}" "${tmp}/label-collision.kg.yaml" --radar 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q '5.4  C_TRAP' \
     && printf '%s' "${out}" | grep -q 'claim(DEV/confirmed)'; then
    record_pass "kg-label-collision: campos reais ainda lidos (peso 5.4, claim(DEV/confirmed))"
  else record_fail "kg-label-collision: campos reais" "esperava 5.4 C_TRAP claim(DEV/confirmed); rc=${rc} out=${out}"; fi

  # (c) guarda viva: enum inválido em POSIÇÃO DE CAMPO continua reprovando com exit 1
  rc=0; out=$(bash "${radar}" "${tmp}/enum-real.kg.yaml" --integrity 2>&1) || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'C_BAD: layer inválido'; then
    record_pass "kg-label-collision: enum inválido em posição de campo AINDA reprova (guarda viva)"
  else record_fail "kg-label-collision: guarda viva" "esperava exit 1 + 'C_BAD: layer inválido'; rc=${rc} out=${out}"; fi

  # (d) ARESTAS/META — a mesma classe fora da seção `nodes` (2ª metade do fix, 2026-07-19).
  # Dois vetores reais que o match solto abria: `to: D_migrate_to:v2` era recortado na ÚLTIMA
  # ocorrência (virava "v2" → nó inexistente) e `on:` era lido de dentro de `reason:` (reas·on:).
  cat > "${tmp}/edge-collision.kg.yaml" <<'KGEOF'
meta:
  schema_version: 1
nodes:
  - id: A_SRC
    node_type: claim
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "origem"
  - id: D_migrate_to:v2
    node_type: decision
    plane: DEV
    status: confirmed
    impact: 3
    confidence: 0.9
    label: "id contendo dois-pontos"
edges:
  - from: A_SRC
    to: D_migrate_to:v2
    edge_type: SUPPORTS
    reason: "campo livre cujo texto contém on: como substring"
KGEOF
  rc=0; out=$(bash "${radar}" "${tmp}/edge-collision.kg.yaml" --integrity 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q 'sem contradições estruturais' \
     && ! printf '%s' "${out}" | grep -q 'inexistente'; then
    record_pass "kg-label-collision: aresta com id contendo ':' e campo livre citando 'on:' → integridade verde"
  else record_fail "kg-label-collision: arestas/meta ancoradas" "esperava exit 0 sem 'inexistente'; rc=${rc} out=${out}"; fi
}

# ---------------------------------------------------------------------------
# Modo contract — exit code de federation-contract-validate.sh
# ---------------------------------------------------------------------------
run_contract_fixture() {
  local fixture="$1" verdict="$2"
  local src="${FIX_DIR}/${fixture}"

  if [ ! -f "${src}" ]; then
    record_fail "${fixture}" "fixture inexistente: ${src}"
    return
  fi

  local rc=0
  bash "${SCRIPT_DIR}/federation-contract-validate.sh" "${src}" >/dev/null 2>&1 || rc=$?

  case "${verdict}" in
    pass)
      if [ "${rc}" -eq 0 ]; then record_pass "${fixture}"
      else record_fail "${fixture}" "esperava exit 0, veio ${rc}"; fi
      ;;
    fail)
      # exige exatamente rc=1 (contrato inválido); rc=2 é uso/arquivo-inexistente
      # — aceitá-lo mascararia um path de fixture quebrado como sucesso.
      if [ "${rc}" -eq 1 ]; then record_pass "${fixture}"
      elif [ "${rc}" -eq 0 ]; then record_fail "${fixture}" "esperava exit 1, veio 0 (validador não pegou contrato inválido)"
      else record_fail "${fixture}" "esperava exit 1, veio ${rc} (uso/arquivo inexistente? fixture path quebrado?)"; fi
      ;;
    *)
      record_fail "${fixture}" "verdict desconhecido '${verdict}'"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Modo members — exit code de members-validate.sh (par de /meta:federation-member).
# Espelha run_contract_fixture: fail exige exatamente rc=1 (registro inválido);
# rc=2 (uso/arquivo) e rc=3 (python+yaml ausente) NÃO passam por 'fail' — mascarariam
# um fixture-path quebrado ou ambiente sem yaml como sucesso.
# ---------------------------------------------------------------------------
run_members_fixture() {
  local fixture="$1" verdict="$2"
  local src="${FIX_DIR}/${fixture}"

  if [ ! -f "${src}" ]; then
    record_fail "${fixture}" "fixture inexistente: ${src}"
    return
  fi

  local rc=0
  bash "${SCRIPT_DIR}/members-validate.sh" "${src}" >/dev/null 2>&1 || rc=$?

  if [ "${rc}" -eq 3 ]; then
    record_skip "${fixture}: python3+yaml ausente (members-validate exit 3, gracioso)"
    return
  fi

  case "${verdict}" in
    pass)
      if [ "${rc}" -eq 0 ]; then record_pass "${fixture}"
      else record_fail "${fixture}" "esperava exit 0, veio ${rc}"; fi
      ;;
    fail)
      if [ "${rc}" -eq 1 ]; then record_pass "${fixture}"
      elif [ "${rc}" -eq 0 ]; then record_fail "${fixture}" "esperava exit 1, veio 0 (validador não pegou membro inválido)"
      else record_fail "${fixture}" "esperava exit 1, veio ${rc} (uso/arquivo inexistente? fixture path quebrado?)"; fi
      ;;
    *)
      record_fail "${fixture}" "verdict desconhecido '${verdict}'"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Modo merge — exercita .claude/utils/adopt/merge-onion-hooks.sh (gap do
# /meta:adopt --update). A fonte é o settings.json REAL do sandbox (acompanha a
# SSOT de hooks sozinho — sem expected.json acoplado). Para cada fixture-alvo,
# assere por SEMÂNTICA (não por diff de texto):
#   (1) presença   : todo command Onion da fonte aparece no resultado
#   (2) preservação: todo command próprio do alvo continua presente (never-clobber)
#   (3) idempotência: re-merjar o resultado não muda nada (no-op na 2ª passada)
# ---------------------------------------------------------------------------
run_merge_fixture() {
  local fixture="$1"
  local tgt="${FIX_DIR}/${fixture}"
  local src="${SANDBOX}/.claude/settings.json"
  local helper="${SANDBOX}/.claude/utils/adopt/merge-onion-hooks.sh"

  if ! command -v jq >/dev/null 2>&1; then
    record_skip "${fixture} (skip: jq ausente)"; return
  fi
  if [ ! -f "${tgt}" ]; then record_fail "${fixture}" "fixture inexistente: ${tgt}"; return; fi
  if [ ! -f "${helper}" ]; then record_fail "${fixture}" "helper ausente: ${helper}"; return; fi

  local out
  if ! out="$(bash "${helper}" "${src}" "${tgt}" 2>/dev/null)"; then
    record_fail "${fixture}" "merge-onion-hooks.sh falhou (exit não-zero)"; return
  fi

  # jq que lista commands de <ref> ausentes em <out>, por evento (vazio = ok)
  local diff_jq='["SessionStart","PreCompact"][] as $ev
    | ($ref.hooks[$ev] // [])[].hooks[]?.command as $c
    | select(([ ($out.hooks[$ev] // [])[].hooks[]?.command ] | index($c)) == null)
    | "\($ev): \($c)"'

  local missing lost
  missing="$(jq -nr --argjson ref "$(cat "${src}")" --argjson out "${out}" "${diff_jq}")"
  if [ -n "${missing}" ]; then record_fail "${fixture}" "hook Onion ausente no resultado: ${missing}"; return; fi

  lost="$(jq -nr --argjson ref "$(cat "${tgt}")" --argjson out "${out}" "${diff_jq}")"
  if [ -n "${lost}" ]; then record_fail "${fixture}" "hook próprio do alvo PERDIDO (clobber): ${lost}"; return; fi

  local tmp out2
  tmp="$(mktemp)"; printf '%s' "${out}" > "${tmp}"
  out2="$(bash "${helper}" "${src}" "${tmp}" 2>/dev/null)"; rm -f "${tmp}"
  if ! diff <(printf '%s' "${out}" | jq -S .) <(printf '%s' "${out2}" | jq -S .) >/dev/null 2>&1; then
    record_fail "${fixture}" "não idempotente: 2ª passada do merge difere da 1ª"; return
  fi

  record_pass "${fixture}"
}

# ---------------------------------------------------------------------------
# Modo resolve — exercita .claude/validation/resolve-integration-branch.sh
# (cadeia .onion-version → git config → default detectado). Cenários
# self-contained (repos git temporários); o conteúdo do stamp é trivial, então
# não há fixture-file. Cobre os MODOS DE FALHA, não só o happy-path: campo
# presente / fallback git config / develop-se-existe / default branch principal.
# ---------------------------------------------------------------------------
run_resolve_selftests() {
  local helper="${SCRIPT_DIR}/resolve-integration-branch.sh"
  if [ ! -f "${helper}" ]; then record_fail "resolve-integration-branch" "helper ausente: ${helper}"; return; fi
  local d out

  # (a) campo integration_branch presente → vence toda a cadeia
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude"
  printf 'role: adopted\nintegration_branch: acme-evolve\n' > "${d}/.claude/.onion-version"
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "acme-evolve" ]; then record_pass "resolve: campo integration_branch vence"
  else record_fail "resolve: campo integration_branch vence" "esperava 'acme-evolve', veio '${out}'"; fi

  # (b) sem campo, git config gitflow.branch.develop setado → fallback git config
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude"
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"; git -C "${d}" config gitflow.branch.develop feature-x
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "feature-x" ]; then record_pass "resolve: fallback git config"
  else record_fail "resolve: fallback git config" "esperava 'feature-x', veio '${out}'"; fi

  # (c) sem campo, sem config, branch develop existe → develop
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude"
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"
  # Identidade via env var (maior precedência) para o commit rodar em runner de CI sem git user.*
  # configurado — env vence config/-c mesmo se GIT_COMMITTER_NAME estiver setado vazio.
  GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
  GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test \
    git -C "${d}" commit -q --allow-empty -m x
  git -C "${d}" branch develop
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "develop" ]; then record_pass "resolve: default develop-se-existe"
  else record_fail "resolve: default develop-se-existe" "esperava 'develop', veio '${out}'"; fi

  # (d) sem campo, sem config, sem develop → branch principal (default literal 'main')
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude"
  printf 'role: source\n' > "${d}/.claude/.onion-version"
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "main" ]; then record_pass "resolve: default branch principal"
  else record_fail "resolve: default branch principal" "esperava 'main', veio '${out}'"; fi

  # (e) SEM arquivo .onion-version (repo pré-stamp), branch develop existe → develop (caminho [ -f ] falso)
  d="$(mktemp -d)"; git -C "${d}" init -q
  # Identidade via env var (maior precedência) para o commit rodar em runner de CI sem git user.*
  # configurado — env vence config/-c mesmo se GIT_COMMITTER_NAME estiver setado vazio.
  GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
  GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test \
    git -C "${d}" commit -q --allow-empty -m x
  git -C "${d}" branch develop
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "develop" ]; then record_pass "resolve: stamp ausente + develop existe"
  else record_fail "resolve: stamp ausente + develop existe" "esperava 'develop', veio '${out}'"; fi

  # (f) campo integration_branch VAZIO → cai para git config (não trava no campo vazio)
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude"
  printf 'role: adopted\nintegration_branch:\n' > "${d}/.claude/.onion-version"; git -C "${d}" config gitflow.branch.develop cfgbranch
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "cfgbranch" ]; then record_pass "resolve: campo vazio cai p/ git config"
  else record_fail "resolve: campo vazio cai p/ git config" "esperava 'cfgbranch', veio '${out}'"; fi

  # (g) sem campo, sem config, sem develop, origin/HEAD=master → master (cobre o ramo symbolic-ref)
  d="$(mktemp -d)"; git -C "${d}" init -q
  git -C "${d}" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "master" ]; then record_pass "resolve: origin/HEAD=master"
  else record_fail "resolve: origin/HEAD=master" "esperava 'master', veio '${out}'"; fi

  # (h) sem campo, sem config develop, sem branch develop, gitflow.branch.master custom → trunk
  d="$(mktemp -d)"; git -C "${d}" init -q; git -C "${d}" config gitflow.branch.master trunk
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "trunk" ]; then record_pass "resolve: gitflow.branch.master custom"
  else record_fail "resolve: gitflow.branch.master custom" "esperava 'trunk', veio '${out}'"; fi
}

# ---------------------------------------------------------------------------
# Modo resolve-production — exercita .claude/validation/resolve-production-branch.sh
# (irmão do resolve-integration acima). Cenários self-contained (repos git
# temporários), um por DEFEITO encontrado pela verificação adversarial (sinal
# um adotante regulado 2026-07-19). --integration é passado explícito em cada caso: isola o
# contrato do resolve-production-branch.sh (candidatos + regras 1-5) da
# resolução de integração em si (já coberta por run_resolve_selftests acima).
#   (1) greenfield trunk-based : só main, sem develop            → "main" SEM alarme        (D1)
#   (2) GitFlow clássico       : master viva + develop, origin/HEAD→develop → "master"       (D2/D4, caso de um adotante regulado)
#   (3) pós-rename             : master (antiga) + main (recente) → main + AVISO ambiguidade (D3)
#   (4) default customizado    : sem master/main, origin/HEAD→"trunk"≠integração → "trunk"    (D4)
#   (5) não identificável      : sem master/main, origin/HEAD==integração → VAZIO + aviso     (D5)
#   (6) sem remote/commits     : não quebra, degrada gracioso (exit 0)                        (D6)
# ---------------------------------------------------------------------------
run_resolve_production_selftests() {
  local helper="${SCRIPT_DIR}/resolve-production-branch.sh"
  if [ ! -f "${helper}" ]; then record_fail "resolve-production-branch" "helper ausente: ${helper}"; return; fi
  local d sha old_sha new_sha
  local RP_OUT RP_ERR RP_RC

  # Identidade via env (maior precedência) p/ commitar em CI sem git user.* configurado.
  export GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
         GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test

  # Executa o helper capturando stdout/stderr/exit code separadamente sem
  # deixar `set -e` abortar o selftest inteiro num rc≠0 inesperado.
  _rp_run() {
    local rd="$1"; shift
    local errfile; errfile="$(mktemp)"
    RP_OUT="$(bash "${helper}" "${rd}" "$@" 2>"${errfile}")" && RP_RC=0 || RP_RC=$?
    RP_ERR="$(cat "${errfile}")"; rm -f "${errfile}"
  }

  # (1) greenfield trunk-based: só main, sem develop → "main" SEM alarme (D1)
  d="$(mktemp -d)"; git -C "${d}" init -q
  git -C "${d}" symbolic-ref HEAD refs/heads/main
  git -C "${d}" commit -q --allow-empty -m base
  _rp_run "${d}" --integration main
  rm -rf "${d}"
  if [ "${RP_OUT}" = "main" ] && [ -z "${RP_ERR}" ]; then
    record_pass "resolve-production: greenfield trunk-based → main sem alarme"
  else
    record_fail "resolve-production: greenfield trunk-based" "esperava out='main' sem stderr, veio out='${RP_OUT}' err='${RP_ERR}'"
  fi

  # (2) GitFlow clássico: master (viva) + develop, origin/HEAD→develop → "master", NUNCA "develop" (caso de um adotante regulado)
  d="$(mktemp -d)"; git -C "${d}" init -q
  git -C "${d}" symbolic-ref HEAD refs/heads/zzz-local
  git -C "${d}" commit -q --allow-empty -m base
  sha="$(git -C "${d}" rev-parse HEAD)"
  git -C "${d}" update-ref refs/remotes/origin/master "${sha}"
  git -C "${d}" update-ref refs/remotes/origin/develop "${sha}"
  git -C "${d}" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop
  _rp_run "${d}" --integration develop
  rm -rf "${d}"
  if [ "${RP_OUT}" = "master" ]; then
    record_pass "resolve-production: GitFlow clássico (origin/HEAD→develop) → master"
  else
    record_fail "resolve-production: GitFlow clássico" "esperava 'master', veio out='${RP_OUT}' err='${RP_ERR}'"
  fi

  # (3) pós-rename: master (antiga/parada) + main (recente) → escolhe a MAIS RECENTE + avisa ambiguidade
  d="$(mktemp -d)"; git -C "${d}" init -q
  git -C "${d}" symbolic-ref HEAD refs/heads/zzz-local
  GIT_AUTHOR_DATE="2020-01-01T00:00:00" GIT_COMMITTER_DATE="2020-01-01T00:00:00" \
    git -C "${d}" commit -q --allow-empty -m old
  old_sha="$(git -C "${d}" rev-parse HEAD)"
  GIT_AUTHOR_DATE="2024-06-01T00:00:00" GIT_COMMITTER_DATE="2024-06-01T00:00:00" \
    git -C "${d}" commit -q --allow-empty -m new
  new_sha="$(git -C "${d}" rev-parse HEAD)"
  git -C "${d}" update-ref refs/remotes/origin/master "${old_sha}"
  git -C "${d}" update-ref refs/remotes/origin/main "${new_sha}"
  _rp_run "${d}" --integration develop
  rm -rf "${d}"
  if [ "${RP_OUT}" = "main" ] && printf '%s' "${RP_ERR}" | grep -qi "AMBIGUIDADE"; then
    record_pass "resolve-production: pós-rename → main (mais recente) + avisa ambiguidade"
  else
    record_fail "resolve-production: pós-rename" "esperava out='main' + aviso AMBIGUIDADE, veio out='${RP_OUT}' err='${RP_ERR}'"
  fi

  # (4) default customizado: sem master/main; origin/HEAD→"trunk" difere da integração → "trunk" (candidato legítimo)
  d="$(mktemp -d)"; git -C "${d}" init -q
  git -C "${d}" symbolic-ref HEAD refs/heads/zzz-local
  git -C "${d}" commit -q --allow-empty -m base
  sha="$(git -C "${d}" rev-parse HEAD)"
  git -C "${d}" update-ref refs/remotes/origin/trunk "${sha}"
  git -C "${d}" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
  _rp_run "${d}" --integration develop
  rm -rf "${d}"
  if [ "${RP_OUT}" = "trunk" ]; then
    record_pass "resolve-production: default customizado (origin/HEAD→trunk≠integração) → trunk"
  else
    record_fail "resolve-production: default customizado" "esperava 'trunk', veio out='${RP_OUT}' err='${RP_ERR}'"
  fi

  # (5) não identificável: sem master/main; origin/HEAD == integração → VAZIO no stdout + aviso no stderr (NUNCA "main")
  d="$(mktemp -d)"; git -C "${d}" init -q
  git -C "${d}" symbolic-ref HEAD refs/heads/zzz-local
  git -C "${d}" commit -q --allow-empty -m base
  sha="$(git -C "${d}" rev-parse HEAD)"
  git -C "${d}" update-ref refs/remotes/origin/develop "${sha}"
  git -C "${d}" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop
  _rp_run "${d}" --integration develop
  rm -rf "${d}"
  if [ -z "${RP_OUT}" ] && printf '%s' "${RP_ERR}" | grep -qi "não identificada"; then
    record_pass "resolve-production: não identificável → vazio + aviso (nunca chuta main)"
  else
    record_fail "resolve-production: não identificável" "esperava out='' + aviso 'não identificada', veio out='${RP_OUT}' err='${RP_ERR}'"
  fi

  # (6) repo sem remote e sem commits → não quebra, degrada gracioso (exit 0)
  d="$(mktemp -d)"; git -C "${d}" init -q
  _rp_run "${d}"
  rm -rf "${d}"
  if [ "${RP_RC}" -eq 0 ]; then
    record_pass "resolve-production: repo sem remote/commits degrada gracioso (exit 0)"
  else
    record_fail "resolve-production: repo sem remote/commits" "esperava exit 0, veio ${RP_RC} (out='${RP_OUT}' err='${RP_ERR}')"
  fi

  unset -f _rp_run
}

# ---------------------------------------------------------------------------
# Modo durable-commit — exercita .claude/utils/adopt/durable-commit.sh (fix do
# incidente 2026-07-08: instalação uncommitted apagada por descarte de working-tree).
# Self-contained (repos git em mktemp). Cobre o MODO DE FALHA (o incidente) e a cura:
#   (a) controle      : SEM commit, um descarte (git checkout -- .) reverte o pin (o incidente)
#   (b) durabilidade  : superfície Onion (L1+L2) vira objeto git na branch dedicada
#   (c) never-clobber : produto uncommitted do maestro NÃO é varrido pro commit
#   (d) sobrevivência : checkout ida-e-volta não perde mais o pin
#   (e) idempotência  : re-run sem mudanças → exit 0, nada duplicado
#   (f) gracioso      : DEST não-git → exit 0 com aviso
# ---------------------------------------------------------------------------
run_durable_commit_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/durable-commit.sh"
  if [ ! -f "${helper}" ]; then record_fail "durable-commit" "helper ausente: ${helper}"; return; fi
  local d
  # Identidade via env (maior precedência) p/ commitar em CI sem git user.* configurado.
  export GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
         GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test

  # setup: adotado (tracked, pin OLD) numa feature branch, com --update aplicado uncommitted + produto
  _dc_setup() {
    d="$(mktemp -d)"; git -C "${d}" init -q
    mkdir -p "${d}/.claude/commands"
    printf 'source_commit: OLD111\nrole: adopted\n' > "${d}/.claude/.onion-version"
    printf '# existing\n' > "${d}/.claude/commands/existing.md"
    git -C "${d}" add -A; git -C "${d}" commit -qm base
    git -C "${d}" checkout -q -b feature/x
    printf 'source_commit: NEW999\nrole: adopted\n' > "${d}/.claude/.onion-version"
    printf '# novo\n' > "${d}/.claude/commands/newcmd.md"
    mkdir -p "${d}/docs/meta-specs"; printf '# spec\n' > "${d}/docs/meta-specs/spec.md"
    mkdir -p "${d}/src"; printf 'produto\n' > "${d}/src/app.js"
    # artefatos GERADOS na adoção (achado de campo de um adotante de campo 2026-07-09): devem ser durables também
    printf '# CLAUDE\n' > "${d}/CLAUDE.md"
    printf 'x merge=union\n' > "${d}/.gitattributes"
    mkdir -p "${d}/docs/onion"; printf '# inventory\n' > "${d}/docs/onion/inventory.md"
  }

  # (a) controle — SEM commit: descarte reverte o pin (o incidente)
  _dc_setup; git -C "${d}" checkout -- . 2>/dev/null
  if [ "$(awk '/source_commit:/{print $2}' "${d}/.claude/.onion-version")" = "OLD111" ]; then
    record_pass "durable-commit: incidente reproduzido (descarte reverte pin, sem commit)"
  else record_fail "durable-commit: incidente" "descarte não reverteu o pin"; fi
  rm -rf "${d}"

  # (b) cura + (c) never-clobber + (d) sobrevivência + (e) idempotência
  _dc_setup
  bash "${helper}" "${d}" update NEW999 chore/onion-update-NEW999 >/dev/null 2>&1
  if [ "$(git -C "${d}" rev-parse --abbrev-ref HEAD)" = "chore/onion-update-NEW999" ] \
     && git -C "${d}" ls-files --error-unmatch .claude/commands/newcmd.md >/dev/null 2>&1 \
     && git -C "${d}" ls-files --error-unmatch docs/meta-specs/spec.md >/dev/null 2>&1; then
    record_pass "durable-commit: instalação (L1+L2) commitada na branch dedicada"
  else record_fail "durable-commit: cura" "Onion não durável na branch dedicada"; fi

  # (b2) artefatos GERADOS na adoção também durables (regressão do achado de um adotante de campo)
  if git -C "${d}" ls-files --error-unmatch CLAUDE.md >/dev/null 2>&1 \
     && git -C "${d}" ls-files --error-unmatch .gitattributes >/dev/null 2>&1 \
     && git -C "${d}" ls-files --error-unmatch docs/onion/inventory.md >/dev/null 2>&1; then
    record_pass "durable-commit: artefatos de adoção (CLAUDE.md/.gitattributes/inventário) commitados"
  else record_fail "durable-commit: artefatos de adoção" "CLAUDE.md/.gitattributes/docs/onion ficaram uncommitted"; fi

  if git -C "${d}" ls-files --error-unmatch src/app.js >/dev/null 2>&1; then
    record_fail "durable-commit: never-clobber" "produto src/app.js varrido pro commit (clobber)"
  else record_pass "durable-commit: produto preservado fora do commit (never-clobber)"; fi

  git -C "${d}" checkout -q - 2>/dev/null; git -C "${d}" checkout -q - 2>/dev/null
  if [ "$(awk '/source_commit:/{print $2}' "${d}/.claude/.onion-version")" = "NEW999" ]; then
    record_pass "durable-commit: pin sobrevive a checkout ida-e-volta (durável)"
  else record_fail "durable-commit: sobrevivência" "pin perdido após checkout"; fi

  if bash "${helper}" "${d}" update NEW999 chore/onion-update-NEW999 >/dev/null 2>&1; then
    record_pass "durable-commit: re-run idempotente (nada a commitar → exit 0)"
  else record_fail "durable-commit: idempotência" "re-run retornou não-zero"; fi
  rm -rf "${d}"

  # (f) gracioso — DEST não-git → exit 0
  d="$(mktemp -d)"
  if bash "${helper}" "${d}" adopt X >/dev/null 2>&1; then
    record_pass "durable-commit: DEST não-git → exit 0 (gracioso)"
  else record_fail "durable-commit: gracioso" "esperava exit 0 em não-git"; fi
  rm -rf "${d}"

  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

# ---------------------------------------------------------------------------
# Modo vendor-branch — exercita .claude/utils/adopt/vendor-branch.sh (Achado #2:
# --update via merge de onion/vendor RAMIFICADA → never-clobber estrutural).
# Self-contained (repos git em mktemp). Cobre o MODO DE FALHA e a cura:
#   (a) seed        : onion/vendor ramificada, base comum com a integração
#   (b) update limpo: framework novo sem customização → merge limpo, produto preservado
#   (c) CONFLITO    : customização local → git merge conflita (exit 10), preservada (não clobada)  ← chave
#   (d) idempotência: re-update mesmo pin → exit 0, tree limpa
#   (e) legado      : alvo sem onion/vendor → update semeia antes de mergear
# ---------------------------------------------------------------------------
run_vendor_pin_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/vendor-branch.sh"
  [ -f "${helper}" ] || return 0
  export GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
         GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test
  # Fixture PRÓPRIA: as chamadas abaixo sujam o estado do alvo (bootstrap do
  # vendor), então não podem compartilhar a fixture do run_vendor_branch_selftests

# Modo vendor-pin — o pin entra provando ser commit (achado de campo 2026-07-21).
run_vendor_pin_selftests
  # — foi o que quebrou a suíte na 1ª tentativa.
  local core t ib
  core="$(mktemp -d)/c"; t="$(mktemp -d)/a"
  rm -rf "$core"; mkdir -p "$core/.claude/commands"; git -C "$core" init -q
  printf 'cmd\n' > "$core/.claude/commands/foo.md"
  git -C "$core" add -A; git -C "$core" commit -qm "core"
  rm -rf "$t"; mkdir -p "$t/src"; git -C "$t" init -q
  printf 'produto\n' > "$t/src/app.js"; git -C "$t" archive --format=tar HEAD 2>/dev/null | true
  git -C "$core" archive HEAD -- .claude | tar -x -C "$t"
  git -C "$t" add -A; git -C "$t" commit -qm "adopt"
  ib="$(git -C "$t" rev-parse --abbrev-ref HEAD)"
  local _rc

  # (PIN) O PIN ENTRA PROVANDO QUE É COMMIT. O script gravava no histórico do
  # adotante QUALQUER string recebida. Achado de campo 2026-07-21: 2 dos 3
  # adotantes locais tinham lixo carimbado ("vnextpin"; "2026-07-12", uma data).
  # O dano é diferido — aparece semanas depois, quando o 3-way merge usa a base
  # errada e vira ANCESTRALIDADE lida como conflito (17 arquivos, todos
  # byte-idênticos ao core, no update real de um adotante de campo).
  # Os dois lados: lixo REPROVA (rc=2) e commit real PASSA da validação.
  local _rc
  _rc=0; bash "${helper}" update "$t" "$core" "vnextpin" "$ib" >/dev/null 2>&1 || _rc=$?
  if [ "${_rc}" -eq 2 ]; then
    record_pass "vendor-branch: (PIN) placeholder recusado — não vira registro no histórico do adotante"
  else record_fail "vendor-branch: (PIN placeholder)" "esperava rc=2, veio ${_rc} — lixo seria carimbado"; fi

  _rc=0; bash "${helper}" update "$t" "$core" "2026-07-12" "$ib" >/dev/null 2>&1 || _rc=$?
  if [ "${_rc}" -eq 2 ]; then
    record_pass "vendor-branch: (PIN) data no lugar do commit recusada (caso real de campo)"
  else record_fail "vendor-branch: (PIN data)" "esperava rc=2, veio ${_rc}"; fi

  _rc=0; bash "${helper}" update "$t" "$core" "" "$ib" >/dev/null 2>&1 || _rc=$?
  if [ "${_rc}" -eq 2 ]; then
    record_pass "vendor-branch: (PIN) pin vazio recusado"
  else record_fail "vendor-branch: (PIN vazio)" "esperava rc=2, veio ${_rc}"; fi

  # MUTAÇÃO: desfeita a validação, o lixo passa — prova que o teste é load-bearing.
  sed 's|if ! git -C "$SRC" cat-file -e "${PIN}^{commit}" 2>/dev/null; then|if false; then|' \
      "${helper}" > "${t}.mut.sh"
  _rc=0; bash "${t}.mut.sh" update "$t" "$core" "vnextpin" "$ib" >/dev/null 2>&1 || _rc=$?
  if [ "${_rc}" -ne 2 ]; then
    record_pass "vendor-branch: (PIN/MUT) sem a validação o lixo passa — a guarda é load-bearing"
  else record_fail "vendor-branch: (PIN/MUT)" "com a validação desfeita ainda recusou — o teste não prova nada"; fi
  rm -f "${t}.mut.sh"

}

run_vendor_branch_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/vendor-branch.sh"
  if [ ! -f "${helper}" ]; then record_fail "vendor-branch" "helper ausente: ${helper}"; return; fi
  export GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
         GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test
  local core t ib

  _vb_core() { local d="$1" v="$2"; rm -rf "$d"; mkdir -p "$d/.claude/commands" "$d/docs/meta-specs"; git -C "$d" init -q
    printf 'cmd v%s\n' "$v" > "$d/.claude/commands/foo.md"; printf 'spec v%s\n' "$v" > "$d/docs/meta-specs/spec.md"
    git -C "$d" add -A; git -C "$d" commit -qm "core v$v"; }
  _vb_adopter() { local tt="$1" cc="$2"; rm -rf "$tt"; mkdir -p "$tt/src"; git -C "$tt" init -q
    printf 'produto\n' > "$tt/src/app.js"; git -C "$cc" archive HEAD -- .claude docs | tar -x -C "$tt"
    git -C "$tt" add -A; git -C "$tt" commit -qm "adopt v1 + produto"; }

  core="$(mktemp -d)/c"; t="$(mktemp -d)/a"; _vb_core "$core" 1; _vb_adopter "$t" "$core"
  ib="$(git -C "$t" rev-parse --abbrev-ref HEAD)"

  # (a) seed
  bash "${helper}" seed "$t" "$ib" >/dev/null 2>&1
  if git -C "$t" rev-parse --verify onion/vendor >/dev/null 2>&1 \
     && [ -n "$(git -C "$t" merge-base "$ib" onion/vendor 2>/dev/null)" ]; then
    record_pass "vendor-branch: seed ramifica onion/vendor com base comum"
  else record_fail "vendor-branch: seed" "sem onion/vendor ou sem base comum"; fi

  # (b) update limpo
  _vb_core "$core" 2
  bash "${helper}" update "$t" "$core" "$(git -C "$core" rev-parse --short=12 HEAD)" "$ib" >/dev/null 2>&1
  if grep -q v2 "$t/docs/meta-specs/spec.md" && grep -q produto "$t/src/app.js"; then
    record_pass "vendor-branch: update limpo aplica framework + preserva produto"
  else record_fail "vendor-branch: update limpo" "v2 não aplicado ou produto perdido"; fi

  # (c) CONFLITO — o teste-chave
  printf 'cmd v2 CUSTOMIZADO\n' > "$t/.claude/commands/foo.md"; git -C "$t" add -A; git -C "$t" commit -qm custom
  _vb_core "$core" 3
  local rc=0; bash "${helper}" update "$t" "$core" "$(git -C "$core" rev-parse --short=12 HEAD)" "$ib" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 10 ] && grep -q CUSTOMIZADO "$t/.claude/commands/foo.md" \
     && git -C "$t" diff --name-only --diff-filter=U 2>/dev/null | grep -q foo.md; then
    record_pass "vendor-branch: customização local → CONFLITO (exit 10), não clobada"
  else record_fail "vendor-branch: conflito" "exit=$rc ou customização clobada/sem conflito"; fi
  git -C "$t" merge --abort 2>/dev/null || true

  # (d) idempotência (repo limpo dedicado)
  local c2 t2 ib2; c2="$(mktemp -d)/c2"; t2="$(mktemp -d)/a2"; _vb_core "$c2" 1
  mkdir -p "$t2"; git -C "$t2" init -q; git -C "$c2" archive HEAD -- .claude docs | tar -x -C "$t2"
  git -C "$t2" add -A; git -C "$t2" commit -qm adopt; ib2="$(git -C "$t2" rev-parse --abbrev-ref HEAD)"
  bash "${helper}" seed "$t2" "$ib2" >/dev/null 2>&1; _vb_core "$c2" 2
  local _p2="$(git -C "$c2" rev-parse --short=12 HEAD)"
  bash "${helper}" update "$t2" "$c2" "$_p2" "$ib2" >/dev/null 2>&1 || true
  local rci=0; bash "${helper}" update "$t2" "$c2" "$_p2" "$ib2" >/dev/null 2>&1 || rci=$?
  if [ "$rci" -eq 0 ] && [ -z "$(git -C "$t2" status --short)" ]; then
    record_pass "vendor-branch: re-update idempotente (exit 0, tree limpa)"
  else record_fail "vendor-branch: idempotência" "exit=$rci ou tree suja"; fi

  # (e) legado — sem onion/vendor, update semeia
  local c3 t3 ib3; c3="$(mktemp -d)/c3"; t3="$(mktemp -d)/a3"; _vb_core "$c3" 1; _vb_adopter "$t3" "$c3"
  ib3="$(git -C "$t3" rev-parse --abbrev-ref HEAD)"; _vb_core "$c3" 2
  local rcl=0; bash "${helper}" update "$t3" "$c3" "$(git -C "$c3" rev-parse --short=12 HEAD)" "$ib3" >/dev/null 2>&1 || rcl=$?
  if [ "$rcl" -eq 0 ] && git -C "$t3" rev-parse --verify onion/vendor >/dev/null 2>&1; then
    record_pass "vendor-branch: legado sem vendor → bootstrap + merge"
  else record_fail "vendor-branch: legado" "exit=$rcl ou vendor não semeado"; fi

  # (f) legado REALISTA (spec §8): .onion-version pinado + customização COMMITADA + sem vendor → o bootstrap
  #     ramifica do BASELINE LIMPO (framework == core@pin), não do HEAD → CONFLITO, não clobra a customização
  local c4 t4 ib4 pin4
  c4="$(mktemp -d)/c4"; t4="$(mktemp -d)/a4"
  # core v1 (repo incremental — NÃO re-inicializar; o pin v1 precisa sobreviver p/ o _clean_baseline achá-lo)
  mkdir -p "$c4/.claude/commands"; git -C "$c4" init -q
  printf 'cmd v1\n' > "$c4/.claude/commands/foo.md"; git -C "$c4" add -A; git -C "$c4" commit -qm "core v1"
  pin4="$(git -C "$c4" rev-parse HEAD)"
  mkdir -p "$t4"; git -C "$t4" init -q
  git -C "$c4" archive HEAD -- .claude | tar -x -C "$t4"
  printf 'source_commit: %s\nrole: adopted\n' "$pin4" > "$t4/.claude/.onion-version"
  git -C "$t4" add -A; git -C "$t4" commit -qm "adopt v1 limpo"
  ib4="$(git -C "$t4" rev-parse --abbrev-ref HEAD)"
  printf 'cmd v1 CUSTOM\n' > "$t4/.claude/commands/foo.md"; git -C "$t4" add -A; git -C "$t4" commit -qm custom
  printf 'cmd v2\n' > "$c4/.claude/commands/foo.md"; git -C "$c4" add -A; git -C "$c4" commit -qm "core v2"
  local rcf=0; bash "${helper}" update "$t4" "$c4" "$(git -C "$c4" rev-parse --short=12 HEAD)" "$ib4" >/dev/null 2>&1 || rcf=$?
  if [ "$rcf" -eq 10 ] && grep -q CUSTOM "$t4/.claude/commands/foo.md"; then
    record_pass "vendor-branch: legado c/ customização commitada → baseline limpo → CONFLITO (não clobra)"
  else record_fail "vendor-branch: legado baseline §8" "exit=$rcf ou customização clobada"; fi
  git -C "$t4" merge --abort 2>/dev/null || true

  # (g) BASE CRUZADA — duas integration branches divergentes, vendor semeado pelo FALLBACK.
  #     Sinal de campo 2026-07-27: ~110 arquivos em conflito, incluindo código de aplicação.
  #     Reproduzido em 3 tentativas; a reprodução DERRUBOU a hipótese inicial (ancestralidade
  #     dá "sim" nos dois casos e NÃO discrimina). O que discrimina é o conteúdo não-framework.
  #     O aceite deste gate não é "roda e passa" — é: ele pega o caso que o motivou, E recusa
  #     ANTES de mergear (a integração tem de ficar INTACTA, senão trocamos 110 conflitos por 110
  #     conflitos com mensagem bonita).
  local c5 t5 pin5a pin5b
  c5="$(mktemp -d)/c5"; t5="$(mktemp -d)/a5"
  mkdir -p "$c5/.claude/commands"; git -C "$c5" init -q
  printf 'cmd v1\n' > "$c5/.claude/commands/foo.md"; git -C "$c5" add -A; git -C "$c5" commit -qm "core v1"
  pin5a="$(git -C "$c5" rev-parse HEAD)"
  printf 'cmd v2\n' > "$c5/.claude/commands/foo.md"; git -C "$c5" add -A; git -C "$c5" commit -qm "core v2"
  pin5b="$(git -C "$c5" rev-parse --short=12 HEAD)"
  mkdir -p "$t5/src"; git -C "$t5" init -q
  printf 'produto base\n' > "$t5/src/app.js"; git -C "$t5" add -A; git -C "$t5" commit -qm "produto base"
  git -C "$c5" archive "$pin5a" -- .claude | tar -x -C "$t5"
  # customização COMMITADA ⇒ _clean_baseline falha ⇒ o seed cai no fallback (HEAD da integração)
  printf 'CUSTOM do adotante\n' >> "$t5/.claude/commands/foo.md"
  printf 'source_commit: %s\nrole: adopted\n' "$pin5a" > "$t5/.claude/.onion-version"
  git -C "$t5" add -A; git -C "$t5" commit -qm "adopt + custom"
  git -C "$t5" branch chore/onion-framework
  git -C "$t5" checkout -q -b develop
  printf 'develop\n' > "$t5/src/app.js"; git -C "$t5" add -A; git -C "$t5" commit -qm "develop diverge"
  git -C "$t5" checkout -q chore/onion-framework
  printf 'chore\n' > "$t5/src/app.js"; git -C "$t5" add -A; git -C "$t5" commit -qm "chore diverge"
  bash "${helper}" update "$t5" "$c5" "$pin5b" chore/onion-framework >/dev/null 2>&1 || true
  git -C "$t5" checkout -q develop
  local rcx=0 outx
  outx="$(bash "${helper}" update "$t5" "$c5" "$pin5b" develop 2>&1)" || rcx=$?
  local dirty; dirty="$(git -C "$t5" status --porcelain | wc -l)"
  local uconf; uconf="$(git -C "$t5" diff --name-only --diff-filter=U 2>/dev/null | wc -l)"
  if [ "$rcx" -eq 11 ] \
     && printf '%s' "$outx" | grep -q 'BASE CRUZADA' \
     && printf '%s' "$outx" | grep -q 'src/app.js' \
     && [ "$dirty" = "0" ] && [ "$uconf" = "0" ]; then
    record_pass "vendor-branch: (g) base cruzada → exit 11 ANTES do merge, nomeia o arquivo alheio, integração INTACTA"
  else record_fail "vendor-branch: (g) base cruzada" "exit=$rcx dirty=$dirty conflitos=$uconf out=${outx}"; fi

  # (g-MUT) sem a guarda, o MESMO caso passa a mergear e suja a integração — prova que (g) não é
  # vacuidade (um gate que nunca dispara passaria em (g) se o caso não fosse realmente cruzado).
  local mutd; mutd="$(mktemp -d)"
  sed 's/^  if ! alien="\$(_vendor_is_framework_pure.*$/  if false; then :/' "${helper}" > "${mutd}/mut.sh"
  if ! grep -q '_vendor_is_framework_pure "\$T"' "${mutd}/mut.sh"; then
    git -C "$t5" merge --abort 2>/dev/null || true
    git -C "$t5" reset -q --hard HEAD
    local rcm=0; bash "${mutd}/mut.sh" update "$t5" "$c5" "$pin5b" develop >/dev/null 2>&1 || rcm=$?
    local dirtym; dirtym="$(git -C "$t5" status --porcelain | wc -l)"
    if [ "$rcm" -ne 11 ] && { [ "$rcm" -eq 10 ] || [ "$dirtym" != "0" ]; }; then
      record_pass "vendor-branch: (g-MUT) sem a guarda o merge acontece e suja a integração — a guarda é load-bearing"
    else record_fail "vendor-branch: (g-MUT)" "mutação não mudou o desfecho (exit=$rcm dirty=$dirtym) — vacuidade?"; fi
    git -C "$t5" merge --abort 2>/dev/null || true
  else
    record_fail "vendor-branch: (g-MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
  rm -rf "$mutd" 2>/dev/null

  rm -rf "$core" "$t" "$c2" "$t2" "$c3" "$t3" "$c4" "$t4" "$c5" "$t5" 2>/dev/null
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

# ---------------------------------------------------------------------------
# Modo vendor-baseline-REMOVIDO — a colisão entre o `--update` e a catraca REGRA 49 (D_CURE,
# 2026-08-24). O baseline de catraca é LEDGER LOCAL do adotante (só encolhe por medição); o manifest
# do vendor inclui `.claude/validation/` inteiro, então sem a cura o `tar -x` sobrescreve os baselines
# do onion/vendor com os do CORE — que cobrem grafos core-only (docs/discussions/…). O merge traz essas
# chaves ESTRANGEIRAS ao HEAD do adotante e a catraca o cobra por passivo alheio (`REMOVIDO` HARD) no
# exato ato de filtrá-las. Um adotante REGULADO com histórico de baseline achou o bug; o
# greenfield da PoC não podia (sem baseline prévio). A cura: o vendor NUNCA carrega baseline do core.
# Este selftest REPRODUZ o RED (via mutação que remove a cura) e prova o GREEN (com a cura) — a linha
# `git checkout -- '*-baseline.txt'` do vendor-branch.sh é load-bearing.
run_vendor_baseline_removido_selftests() {
  local vb="${REPO_ROOT}/.claude/utils/adopt/vendor-branch.sh"
  local cov="${REPO_ROOT}/.claude/validation/kg-verification-coverage.sh"
  if [ ! -f "$vb" ] || [ ! -f "$cov" ]; then
    record_fail "vendor-baseline-removido" "helper ausente: vendor-branch.sh ou kg-verification-coverage.sh"; return
  fi
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

  # core sintético: manifest mínimo + baseline com CHAVE ESTRANGEIRA + grafo core-only FORA do manifest.
  # `$vbh` = helper vendor-branch sob teste (o real, ou o mutado sem a cura).
  _vbr_core() { local d="$1" v="$2" vbh="$3"
    mkdir -p "$d/.claude/commands" "$d/.claude/utils/adopt" "$d/.claude/validation" "$d/docs/meta-specs" "$d/docs/discussions/core-only"
    printf 'cmd v%s\n' "$v" > "$d/.claude/commands/foo.md"
    printf 'meta v%s\n' "$v" > "$d/docs/meta-specs/x.md"
    cp "$vbh" "$d/.claude/utils/adopt/vendor-branch.sh"
    cp "${REPO_ROOT}/.claude/utils/adopt/durable-commit.sh" "${REPO_ROOT}/.claude/utils/adopt/regen-baselines.sh" "$d/.claude/utils/adopt/"
    cp "$cov" "$d/.claude/validation/"
    printf 'meta:\n  domain: core-only\nnodes:\n  - id: E_FOREIGN_CORE_ONLY\n    node_type: evidence\n    plane: PROD\n    impact: 5\n    confidence: 0.9\n    label: "no core-only que o adotante nunca teve"\n' \
      > "$d/docs/discussions/core-only/foreign.kg.yaml"
    printf '# Baseline REGRA 49\ndocs/discussions/core-only/foreign.kg.yaml::E_FOREIGN_CORE_ONLY\n' \
      > "$d/.claude/validation/kg-verification-baseline.txt"
    printf 'source_commit: local\nrole: source\n' > "$d/.claude/.onion-version"
  }

  # Roda adopt→seed→update com o helper $vbh no ESTADO $st (A=adotante rastreia baseline no vendor;
  # B=adotante SEM baseline rastreado — o caso do oráculo pré-catraca). Ecoa o nº de chaves ESTRANGEIRAS que
  # o onion/vendor carrega APÓS o update — a invariante-raiz que cobre os dois estados: o vendor JAMAIS
  # deve adquirir/adiantar o baseline do core (seja restaurando o do adotante em A, seja removendo o
  # untracked em B). Medir o vendor (não a catraca downstream) evita o ruído do NO-BASELINE, que em B é
  # estado PRÉ-EXISTENTE do adotante e independe do update (medido no dogfood real de um adotante pré-catraca, 2026-08-24).
  _vbr_vendor_foreign() { local vbh="$1" st="$2" work core ad ib pin
    work="$(mktemp -d)"; core="$work/core"; ad="$work/adopter"
    mkdir -p "$core"; git -C "$core" init -q
    _vbr_core "$core" 1 "$vbh"; git -C "$core" add -A; git -C "$core" commit -qm "core v1"
    mkdir -p "$ad/src"; git -C "$ad" init -q; printf 'produto\n' > "$ad/src/app.js"
    ( cd "$core" && git archive HEAD -- .claude/commands .claude/utils .claude/validation docs/meta-specs ) | tar -x -C "$ad"
    printf 'source_commit: v1\nrole: adopted\n' > "$ad/.claude/.onion-version"
    bash "$ad/.claude/utils/adopt/regen-baselines.sh" "$ad" --emit >/dev/null 2>&1 || true
    # ESTADO B: o adotante NÃO rastreia o baseline (adotante pré-catraca, sem baseline próprio)
    [ "$st" = "B" ] && rm -f "$ad/.claude/validation/kg-verification-baseline.txt"
    git -C "$ad" add -A; git -C "$ad" commit -qm "adopt v1 (estado $st)"
    ib="$(git -C "$ad" rev-parse --abbrev-ref HEAD)"
    bash "$vbh" seed "$ad" "$ib" >/dev/null 2>&1 || true
    _vbr_core "$core" 2 "$vbh"; git -C "$core" add -A; git -C "$core" commit -qm "core v2"
    pin="$(git -C "$core" rev-parse --short=12 HEAD)"
    bash "$vbh" update "$ad" "$core" "$pin" "$ib" >/dev/null 2>&1 || true
    # nº de chaves estrangeiras (core-only) que o onion/vendor carrega após o update. grep -c JÁ imprime
    # "0" quando não há match (e sai 1) — NÃO encadear `|| printf 0`, que DUPLICA o zero ("0\n0").
    local _fk; _fk="$(git -C "$ad" show onion/vendor:.claude/validation/kg-verification-baseline.txt 2>/dev/null \
      | grep -cE 'foreign\.kg\.yaml::E_FOREIGN_CORE_ONLY')"
    printf '%s' "${_fk:-0}"
    rm -rf "$work" 2>/dev/null
  }

  # (a/b) GREEN — o helper REAL (com a cura): em AMBOS os estados o vendor NÃO adquire o baseline do core.
  local a b
  a="$(_vbr_vendor_foreign "$vb" A)"; b="$(_vbr_vendor_foreign "$vb" B)"
  if [ "$a" = "0" ]; then
    record_pass "vendor-baseline-removido: (A/GREEN) baseline RASTREADO no vendor → update não adquire chave do core"
  else record_fail "vendor-baseline-removido: (A/GREEN)" "vendor carregou ${a} chave(s) estrangeira(s) — a cura não segura o estado A"; fi
  if [ "$b" = "0" ]; then
    record_pass "vendor-baseline-removido: (B/GREEN) vendor SEM baseline (pré-catraca) → update remove o untracked do core"
  else record_fail "vendor-baseline-removido: (B/GREEN)" "vendor carregou ${b} chave(s) estrangeira(s) — a cura não segura o estado B (pré-catraca)"; fi

  # (c) RED/MUT — remove o BLOCO da cura (entre os marcadores D_CURE-baseline-preserve): em AMBOS os
  # estados o vendor DEVE voltar a adquirir a chave do core (prova que o bloco é load-bearing). O helper
  # mutado precisa dos IRMÃOS ao lado — o vendor-branch os resolve por `$HERE`; num mktemp isolado o
  # update falharia por outro motivo e daria falso-verde (testar-no-caminho-errado-é-não-testar).
  local mutdir; mutdir="$(mktemp -d)"
  cp "${REPO_ROOT}/.claude/utils/adopt/durable-commit.sh" "${REPO_ROOT}/.claude/utils/adopt/regen-baselines.sh" "$mutdir/"
  awk '/^  # >>> D_CURE-baseline-preserve/{skip=1} !skip{print} /^  # <<< D_CURE-baseline-preserve/{skip=0}' \
    "$vb" > "$mutdir/vendor-branch.sh"
  # sanidade: a mutação removeu MESMO o bloco (senão o RED não prova nada — guarda-por-lista-falha-pelo-vocabulário)
  if [ "$(grep -c 'D_CURE-baseline-preserve' "$mutdir/vendor-branch.sh")" != "0" ]; then
    record_fail "vendor-baseline-removido: (RED/MUT setup)" "awk não removeu o bloco da cura — o teste não prova nada"
  else
    local ra rb; ra="$(_vbr_vendor_foreign "$mutdir/vendor-branch.sh" A)"; rb="$(_vbr_vendor_foreign "$mutdir/vendor-branch.sh" B)"
    if [ "$ra" != "0" ] && [ "$rb" != "0" ]; then
      record_pass "vendor-baseline-removido: (RED/MUT) sem o bloco da cura o vendor adquire a chave do core em A e B — load-bearing"
    else record_fail "vendor-baseline-removido: (RED/MUT)" "esperava contaminação em ambos (A=${ra} B=${rb}), o bloco não é load-bearing ou o teste não reproduz"; fi
  fi
  rm -rf "$mutdir" 2>/dev/null

  unset -f _vbr_core _vbr_vendor_foreign
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

# ---------------------------------------------------------------------------
# Modo compose-settings — exercita .claude/utils/scope/compose-settings.sh (RFC-0005 plano 2:
# settings.json N-camadas de escopo framework→empresa→time→pessoa). Self-contained em mktemp.
#   (a) merge type-aware: escalar last-wins · objeto recursa · array união (hooks/permissions)
#   (b) determinismo · (c) proveniência · (d) gracioso (JSON inválido → exit 2; sem jq → skip)
# ---------------------------------------------------------------------------
run_compose_settings_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/scope/compose-settings.sh"
  if [ ! -f "${helper}" ]; then record_fail "compose-settings" "helper ausente: ${helper}"; return; fi
  if ! command -v jq >/dev/null 2>&1; then record_skip "compose-settings: jq ausente → pulado (gracioso)"; return; fi
  local d; d="$(mktemp -d)"
  printf '%s' '{"theme":"dark","permissions":{"allow":["Bash(git *)"],"deny":[]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"fw"}]}]}}' > "$d/fw.json"
  printf '%s' '{"permissions":{"deny":["x"]},"env":{"ORG":"acme"}}' > "$d/org.json"
  printf '%s' '{"model":"opus","permissions":{"allow":["Bash(nx *)"]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"team"}]}]}}' > "$d/team.json"
  printf '%s' '{"theme":"light","env":{"EDITOR":"vim"}}' > "$d/person.json"
  local C; C="$(bash "${helper}" "$d/fw.json" "$d/org.json" "$d/team.json" "$d/person.json" 2>/dev/null)"
  if [ "$(printf '%s' "$C" | jq -r .theme)" = "light" ] \
     && [ "$(printf '%s' "$C" | jq -r .model)" = "opus" ] \
     && [ "$(printf '%s' "$C" | jq -c '.permissions.allow')" = '["Bash(git *)","Bash(nx *)"]' ] \
     && [ "$(printf '%s' "$C" | jq -r '.env.ORG')" = "acme" ] && [ "$(printf '%s' "$C" | jq -r '.env.EDITOR')" = "vim" ] \
     && [ "$(printf '%s' "$C" | jq '.hooks.SessionStart|length')" = "2" ]; then
    record_pass "compose-settings: N-camadas (escalar last-wins + objeto recursa + array união)"
  else record_fail "compose-settings: merge" "composição incorreta (theme/model/allow/env/hooks)"; fi
  local C2; C2="$(bash "${helper}" "$d/fw.json" "$d/org.json" "$d/team.json" "$d/person.json" 2>/dev/null)"
  if [ "$(printf '%s' "$C" | sha256sum)" = "$(printf '%s' "$C2" | sha256sum)" ]; then
    record_pass "compose-settings: determinístico"
  else record_fail "compose-settings: determinismo" "composição varia entre execuções"; fi
  # --provenance é alias de --show-scope (formato novo: <scope>\t<path>=<valor> + sobreposição)
  local TAB=$'\t'
  if bash "${helper}" --provenance "$d/fw.json" "$d/person.json" 2>/dev/null \
       | grep -qxF "person.json${TAB}theme=\"light\"${TAB}# sobrepõe: fw.json"; then
    record_pass "compose-settings: proveniência (theme ← person sobrepõe fw)"
  else record_fail "compose-settings: proveniência" "proveniência incorreta"; fi
  printf '%s' '{bad' > "$d/bad.json"
  local rc=0; bash "${helper}" "$d/fw.json" "$d/bad.json" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 2 ]; then record_pass "compose-settings: JSON inválido → exit 2 (gracioso)"
  else record_fail "compose-settings: inválido" "esperava exit 2, veio $rc"; fi
  rm -rf "$d"
}

# ---------------------------------------------------------------------------
# Modo resolve-target — exercita .claude/utils/co-evolution/resolve-target.sh (F1.2: targeting fino
# por seletor no alvo:, reusando graph.sh --triples). Asserções ESTRUTURAIS (não fixam nomes de membro
# → robusto a mudança de roster). Pula o que depende de membros sem python+yaml.
# ---------------------------------------------------------------------------
run_resolve_target_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/co-evolution/resolve-target.sh"
  if [ ! -f "${helper}" ]; then record_fail "resolve-target" "helper ausente: ${helper}"; return; fi
  if [ -z "$(bash "${helper}" nenhum 2>/dev/null)" ]; then record_pass "resolve-target: nenhum → vazio"
  else record_fail "resolve-target: nenhum" "esperava vazio"; fi
  local rc=0; bash "${helper}" 'foo:bar' >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 3 ]; then record_pass "resolve-target: chave desconhecida → exit 3"
  else record_fail "resolve-target: chave" "esperava exit 3, veio ${rc}"; fi
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    record_skip "resolve-target: seletor sobre membros pulado (sem python+yaml — gracioso)"; return; fi
  local todos hub
  todos="$(bash "${helper}" todos 2>/dev/null | LC_ALL=C sort)"
  hub="$(bash "${helper}" 'tier:hub' 2>/dev/null | grep -v '^$' | LC_ALL=C sort)"
  if [ -n "${todos}" ] && [ -z "$(comm -23 <(printf '%s\n' "${hub}") <(printf '%s\n' "${todos}"))" ]; then
    record_pass "resolve-target: todos não-vazio + tier:hub ⊆ todos"
  else record_fail "resolve-target: subconjunto" "tier:hub não é subconjunto de todos"; fi
  local a b
  a="$(bash "${helper}" 'tier:standalone' 2>/dev/null | grep -v '^$' | LC_ALL=C sort)"
  b="$(bash "${helper}" 'tier:standalone,mode:regulated' 2>/dev/null | grep -v '^$' | LC_ALL=C sort)"
  if [ -z "$(comm -23 <(printf '%s\n' "${b}") <(printf '%s\n' "${a}"))" ]; then
    record_pass "resolve-target: AND é interseção (a,b ⊆ a)"
  else record_fail "resolve-target: AND" "interseção não é subconjunto de a"; fi
  if [ "$(bash "${helper}" todos 2>/dev/null | sha256sum)" = "$(bash "${helper}" todos 2>/dev/null | sha256sum)" ]; then
    record_pass "resolve-target: determinístico"
  else record_fail "resolve-target: determinismo" "varia entre execuções"; fi
}

# ---------------------------------------------------------------------------
# Modo reconcile-inputs — exercita .claude/utils/co-evolution/reconcile-inputs.sh (insumos
# determinísticos do /meta:co-announce --reconcile). Asserções estruturais (não fixam roster).
# O conteúdo de [ENTRIES] depende de resolve-target → pula gracioso sem python+yaml.
# ---------------------------------------------------------------------------
run_reconcile_inputs_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/co-evolution/reconcile-inputs.sh"
  if [ ! -f "${helper}" ]; then record_fail "reconcile-inputs" "helper ausente: ${helper}"; return; fi
  # --outbox é barato (sem python); --entries chama resolve-target → captura UMA vez e reusa.
  local outbox entries
  outbox="$(bash "${helper}" --outbox 2>/dev/null)"
  if [ "$(printf '%s\n' "${outbox}" | head -1)" = "[OUTBOX]" ]; then
    record_pass "reconcile-inputs: --outbox emite cabeçalho [OUTBOX]"
  else record_fail "reconcile-inputs: --outbox" "cabeçalho [OUTBOX] ausente"; fi
  local bad_state
  bad_state="$(printf '%s\n' "${outbox}" | tail -n +2 | awk -F'\t' 'NF>=2 && $2!="staging" && $2!="processed"' | head -1)"
  if [ -z "${bad_state}" ]; then record_pass "reconcile-inputs: outbox estado ∈ {staging,processed}"
  else record_fail "reconcile-inputs: outbox estado" "estado inesperado: ${bad_state}"; fi
  if [ "$(bash "${helper}" --outbox 2>/dev/null | sha256sum)" = "$(printf '%s\n' "${outbox}" | sha256sum)" ]; then
    record_pass "reconcile-inputs: determinístico (outbox)"
  else record_fail "reconcile-inputs: determinismo" "varia entre execuções"; fi
  # conteúdo de [ENTRIES] depende de resolve-target (python+yaml) → pula gracioso
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    record_skip "reconcile-inputs: conteúdo de entries pulado (sem python+yaml — gracioso)"; return; fi
  entries="$(bash "${helper}" --entries 2>/dev/null)"   # 1× (memoizado no helper)
  if [ "$(printf '%s\n' "${entries}" | head -1)" = "[ENTRIES]" ]; then
    record_pass "reconcile-inputs: --entries emite cabeçalho [ENTRIES]"
  else record_fail "reconcile-inputs: --entries" "cabeçalho [ENTRIES] ausente"; fi
  local bad_entry
  bad_entry="$(printf '%s\n' "${entries}" | tail -n +2 | awk -F'\t' 'NF<4 || $2==""' | head -1)"
  if [ -z "${bad_entry}" ]; then record_pass "reconcile-inputs: toda entry tem ≥4 campos + destinatários"
  else record_fail "reconcile-inputs: entry malformada" "linha: ${bad_entry}"; fi
  if printf '%s\n' "${entries}" | grep -q '2026-07-10	.*a2a-live'; then
    record_pass "reconcile-inputs: entrada a2a-live 07-10 presente com destinatários"
  else record_fail "reconcile-inputs: a2a-live" "entrada 07-10 a2a-live ausente da conciliação"; fi
}

# ---------------------------------------------------------------------------
# Modo federation-radar — exercita .claude/validation/federation-radar.sh (saúde-de-verificação da
# federação; ADR onion-adr-federation-kg-audit-overlay). Asserções estruturais (advisory, exit 0).
# ---------------------------------------------------------------------------
run_federation_radar_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/federation-radar.sh"
  if [ ! -f "${helper}" ]; then record_fail "federation-radar" "helper ausente: ${helper}"; return; fi
  local out rc=0
  out="$(bash "${helper}" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "federation-radar: advisory (exit 0)"
  else record_fail "federation-radar: exit" "esperava 0 (advisory), veio ${rc}"; fi
  if printf '%s\n' "${out}" | grep -q 'FEDERATION RADAR'; then record_pass "federation-radar: emite cabeçalho"
  else record_fail "federation-radar: cabeçalho" "sem 'FEDERATION RADAR'"; fi
  # os 3 checks numerados presentes
  if printf '%s\n' "${out}" | grep -q '①' && printf '%s\n' "${out}" | grep -q '②' && printf '%s\n' "${out}" | grep -q '③'; then
    record_pass "federation-radar: 3 checks presentes (pin/staging/hub)"
  else record_fail "federation-radar: checks" "faltam checks numerados"; fi
  if [ "$(bash "${helper}" 2>/dev/null | sha256sum)" = "$(bash "${helper}" 2>/dev/null | sha256sum)" ]; then
    record_pass "federation-radar: determinístico"
  else record_fail "federation-radar: determinismo" "varia entre execuções"; fi
}

# ---------------------------------------------------------------------------
# Modo federation-console — exercita .claude/validation/federation-console.sh (F1.3: console estático
# read-only do SSOT). Asserções estruturais (não fixam roster). Pula/exit-3 sem python+yaml.
# ---------------------------------------------------------------------------
run_federation_console_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/federation-console.sh"
  if [ ! -f "${helper}" ]; then record_fail "federation-console" "helper ausente: ${helper}"; return; fi
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    local rc=0; bash "${helper}" >/dev/null 2>&1 || rc=$?
    if [ "${rc}" -eq 3 ]; then record_pass "federation-console: sem python+yaml → exit 3 (gracioso)"
    else record_skip "federation-console: pulado (sem python+yaml)"; fi
    return; fi
  local H; H="$(bash "${helper}" 2>/dev/null)"
  if printf '%s' "${H}" | grep -q '<!doctype html>' && printf '%s' "${H}" | grep -q '</html>' \
     && ! printf '%s' "${H}" | grep -q '__DATA__' \
     && printf '%s' "${H}" | grep -q '"timeline"' && printf '%s' "${H}" | grep -q '"members"'; then
    record_pass "federation-console: HTML self-contained (members+timeline, sem placeholder)"
  else record_fail "federation-console: html" "HTML inválido/incompleto"; fi
  if printf '%s' "${H}" | grep -qiE 'src=.?https?://|<script src|href=.?https?://[^"]*\.(js|css)|fetch\('; then
    record_fail "federation-console: self-contained" "tem dependência externa (CDN/fetch)"
  else record_pass "federation-console: self-contained (sem CDN/fetch externo)"; fi
  local H2; H2="$(bash "${helper}" 2>/dev/null)"
  if [ "$(printf '%s' "${H}" | sha256sum)" = "$(printf '%s' "${H2}" | sha256sum)" ]; then
    record_pass "federation-console: determinístico"
  else record_fail "federation-console: determinismo" "varia entre execuções"; fi
}

# ---------------------------------------------------------------------------
# check_site_inventory_sync — o pitch PÚBLICO não pode driftar da SSOT. Achado 2026-07-17
# (re-verificação do grafo de identidade): o site exibia 95/96 comandos e 66 KBs contra 97/74
# reais — e as ocorrências divergiam ENTRE SI (por isso o gate checa TODAS, não a primeira).
# Os dois lados no mesmo caso: drift → PEGA; alinhado → PASSA. E a timeline de site/historia/
# ("comando nº 95" era verdade quando o /meta:kg nasceu) NUNCA é gateada — forjar história seria
# o oposto da doutrina. Números derivados da SSOT do sandbox (hardcodar 97 apodreceria o teste).
# ---------------------------------------------------------------------------
run_site_inventory_selftests() {
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_fail "site-inventory" "lint ausente: ${lint}"; return; fi
  local sb; sb="$(mktemp -d)"
  cp -a "${REPO_ROOT}/.claude" "${sb}/.claude"
  cp -a "${REPO_ROOT}/docs" "${sb}/docs"
  cp -a "${REPO_ROOT}/CLAUDE.md" "${sb}/CLAUDE.md"
  # stamp adopted só p/ silenciar o ruído de marketplace (plugins/ não é copiado); o check de site
  # NÃO tem guarda por papel — ele roda igual aqui, que é o que este caso exercita.
  printf 'framework: onion-evolve\nrole: adopted\n' > "${sb}/.claude/.onion-version"
  local env_out cmds kbs
  env_out="$(bash "${sb}/.claude/validation/inventory.sh" --env 2>/dev/null || true)"
  cmds="$(echo "${env_out}" | grep '^ONION_COMMANDS_TOTAL=' | cut -d= -f2)"
  kbs="$(echo "${env_out}"  | grep '^ONION_KBS_TOTAL='      | cut -d= -f2)"
  if [ -z "${cmds}" ] || [ -z "${kbs}" ]; then
    record_fail "site-inventory" "inventory.sh --env não devolveu totais"; rm -rf "${sb}"; return
  fi
  mkdir -p "${sb}/site/historia"

  # (a) DRIFT no pitch (prosa E contador) → HARD nos dois
  printf '<p>%s comandos invocáveis</p>\n<b data-n="%s">0</b><span>knowledge bases</span>\n' \
    "$((cmds - 1))" "$((kbs - 1))" > "${sb}/site/index.html"
  local out; out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out}" | grep -q "site afirma $((cmds - 1)) comandos" \
     && printf '%s' "${out}" | grep -q "afirma $((kbs - 1)) knowledge bases"; then
    record_pass "site-inventory: drift no pitch (prosa + contador data-n) → HARD"
  else record_fail "site-inventory: drift" "gate não pegou o drift: ${out}"; fi

  # (b) pitch ALINHADO + timeline histórica → PASSA (história não é gateada)
  printf '<p>%s comandos invocáveis</p>\n<b data-n="%s">0</b><span>knowledge bases</span>\n' \
    "${cmds}" "${kbs}" > "${sb}/site/index.html"
  printf '<span>/meta:kg nasce (comando nº 95)</span>\n<p>96 comandos</p>\n' \
    > "${sb}/site/historia/index.html"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out}" | grep -qE 'site afirma|contador data-n'; then
    record_fail "site-inventory: alinhado" "falso-positivo OU gateou a timeline histórica: ${out}"
  else
    record_pass "site-inventory: pitch alinhado passa; timeline histórica não é gateada"
  fi
  rm -rf "${sb}"
}

# ---------------------------------------------------------------------------
# Modo adopted-role — os checks de marketplace (plugins_sync/role_bundle_sync) devem PULAR
# em role: adopted (consumidor não distribui plugins). Sinal de um adotante regulado 2026-07-10: rodando como
# source, o selftest mascarava a regressão — este caso roda o lint num sandbox COM stamp adopted
# e SEM plugins/ + marketplace.json, e assere zero violação de marketplace.
# ---------------------------------------------------------------------------
run_adopted_role_selftests() {
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_fail "adopted-role" "lint ausente: ${lint}"; return; fi
  local asb; asb="$(mktemp -d)"
  cp -a "${REPO_ROOT}/.claude" "${asb}/.claude"
  cp -a "${REPO_ROOT}/docs" "${asb}/docs"
  cp -a "${REPO_ROOT}/CLAUDE.md" "${asb}/CLAUDE.md"
  rm -rf "${asb}/plugins" "${asb}/.claude-plugin"          # consumidor não carrega a SAÍDA gerada
  printf 'framework: onion-evolve\nrole: adopted\n' > "${asb}/.claude/.onion-version"
  local out
  out="$(cd "${asb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out}" | grep -qE 'plugin ausente|não registrado no marketplace'; then
    record_fail "adopted-role: marketplace-skip" "consumidor sem plugins/ ainda viola marketplace (guarda por papel regrediu)"
  else
    record_pass "adopted-role: role adopted sem plugins/ → 0 violações de marketplace (guarda por papel)"
  fi
  # link-check role-guard (sinal de um adotante regulado 2026-07-16): adotante NÃO vendoriza docs core-only → links
  # vendorizados que os referenciam NÃO devem virar falso "link relativo quebrado" HARD; MAS link KB-interno
  # quebrado ainda VIOLA (precisão). NOTA (reconciliação com a REGRA 45, 2026-07): um link VIVO p/ caminho
  # core-privado agora dispara — POR DESIGN — a violação [link-vendorizado] (converta p/ gloss); isso é
  # INTENCIONAL, não um falso "quebrado". Por isso a asserção escopa à regra de LINK-QUEBRADO (grep na msg
  # 'link relativo quebrado'), não a QUALQUER menção do path — senão a REGRA 45 mascararia este guard. [[fix-must-become-mechanism]]
  rm -rf "${asb}/docs/analysis" "${asb}/docs/discussions" "${asb}/docs/applying" "${asb}/docs/evolution/federation"
  printf '# t\n[core-only](../analysis/foo.md)\n[kb-interno-faltando](concepts/nao-existe-xyz.md)\n' \
    > "${asb}/docs/knowledge-base/test-link-guard.md"
  local out2 broken; out2="$(cd "${asb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  broken="$(printf '%s\n' "${out2}" | grep 'link relativo quebrado' || true)"
  if printf '%s' "${broken}" | grep -q 'concepts/nao-existe-xyz.md' \
     && ! printf '%s' "${broken}" | grep -q 'analysis/foo.md'; then
    record_pass "adopted-role: link-guard — broken-link pula core-only e pega KB-interno (REGRA 45 trata core-privado à parte)"
  else
    record_fail "adopted-role: link-guard" "broken-link impreciso: core-only virou 'quebrado' OU kb-interno não-pego — $(printf '%s' "${broken}" | head -3)"
  fi
  rm -rf "${asb}"
}

# ---------------------------------------------------------------------------
# Modo write-stamp — escrita determinística do .onion-version (sinal de um adotante regulado multi-lineage:
# a regra preserve-adopted_at era prosa e uma sessão a violou; agora é código testado).
# ---------------------------------------------------------------------------
run_write_stamp_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/write-stamp.sh"
  if [ ! -f "${helper}" ]; then record_fail "write-stamp" "helper ausente: ${helper}"; return; fi
  local wsb today; wsb="$(mktemp -d)"; mkdir -p "${wsb}/t/.claude"; today="$(date +%F)"
  # 1. adoção fresca: adopted_at=hoje, SEM updated_at
  bash "${helper}" "${wsb}/t" --framework onion-evolve --commit abc123 --commit-date 2026-07-10 \
    --adopted-from git@x:y.git --mode regulated >/dev/null 2>&1
  if grep -q "^adopted_at: ${today}$" "${wsb}/t/.claude/.onion-version" \
     && ! grep -q '^updated_at:' "${wsb}/t/.claude/.onion-version"; then
    record_pass "write-stamp: adoção fresca → adopted_at=hoje, sem updated_at"
  else record_fail "write-stamp: fresh" "$(cat "${wsb}/t/.claude/.onion-version")"; fi
  # 2. update: adopted_at PRESERVADO + updated_at=hoje + campos antigos vencem args
  printf 'framework: onion-evolve\nsource_commit: abc123\nsource_commit_date: 2026-07-10\nrole: adopted\nadopted_from: git@x:y.git\nadopted_at: 2026-07-01\nmode: regulated\nintegration_branch: develop\n' \
    > "${wsb}/t/.claude/.onion-version"
  bash "${helper}" "${wsb}/t" --framework onion-evolve --commit def456 --commit-date 2026-07-15 \
    --mode legacy >/dev/null 2>&1
  if grep -q '^adopted_at: 2026-07-01$' "${wsb}/t/.claude/.onion-version" \
     && grep -q "^updated_at: ${today}$" "${wsb}/t/.claude/.onion-version" \
     && grep -q '^source_commit: def456$' "${wsb}/t/.claude/.onion-version" \
     && grep -q '^mode: regulated$' "${wsb}/t/.claude/.onion-version" \
     && grep -q '^integration_branch: develop$' "${wsb}/t/.claude/.onion-version"; then
    record_pass "write-stamp: update → preserva adopted_at/mode/branch, escreve updated_at (a regra do audit #5 em código)"
  else record_fail "write-stamp: preserve" "$(cat "${wsb}/t/.claude/.onion-version")"; fi
  # 3. adopted_at perdido → restaura do members.yaml (nunca inventa)
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
    printf 'framework: onion-evolve\nsource_commit: def456\nsource_commit_date: 2026-07-15\nrole: adopted\nmode: regulated\n' \
      > "${wsb}/t/.claude/.onion-version"
    printf 'members:\n  - id: acme\n    adopted_at: 2026-06-15\n' > "${wsb}/members.yaml"
    bash "${helper}" "${wsb}/t" --framework onion-evolve --commit fff999 --commit-date 2026-07-16 \
      --members "${wsb}/members.yaml" --member-id acme >/dev/null 2>&1
    if grep -q '^adopted_at: 2026-06-15$' "${wsb}/t/.claude/.onion-version"; then
      record_pass "write-stamp: adopted_at perdido → restaurado do members.yaml"
    else record_fail "write-stamp: restore" "$(cat "${wsb}/t/.claude/.onion-version")"; fi
  else record_skip "write-stamp: restore pulado (sem python+yaml)"; fi
  # 4. --role hub (Camada 2): fresh grava role: hub; update SEM --role preserva hub (não rebaixa)
  rm -rf "${wsb}/h"; mkdir -p "${wsb}/h/.claude"
  bash "${helper}" "${wsb}/h" --framework acme-adopter --commit aaa111 --commit-date 2026-07-23 --role hub >/dev/null 2>&1
  bash "${helper}" "${wsb}/h" --framework acme-adopter --commit bbb222 --commit-date 2026-07-23 >/dev/null 2>&1  # update sem --role
  if grep -q '^role: hub$' "${wsb}/h/.claude/.onion-version" && grep -q '^source_commit: bbb222$' "${wsb}/h/.claude/.onion-version"; then
    record_pass "write-stamp: --role hub grava hub; update sem --role PRESERVA hub (não rebaixa)"
  else record_fail "write-stamp: role hub" "$(cat "${wsb}/h/.claude/.onion-version")"; fi
  # 6. D_GREP_OLD_PIN: update com pin novo AVISA os artefatos que citam o pin antigo — e só os
  #    fora da história (inbox/inbound/diary excluídos; medição 2026-09-02: 19/22 eram história).
  rm -rf "${wsb}/p"; mkdir -p "${wsb}/p/.claude" "${wsb}/p/docs/evolution/inbox" "${wsb}/p/docs/tech"
  bash "${helper}" "${wsb}/p" --framework onion-evolve --commit 0123456789ab --commit-date 2026-08-01 >/dev/null 2>&1
  printf 'pin 0123456789ab citado na SSOT viva\n' > "${wsb}/p/docs/tech/index.md"
  printf 'sinal histórico cita 0123456789ab\n' > "${wsb}/p/docs/evolution/inbox/2026-08-01-sinal.md"
  local pin_err; pin_err="$(bash "${helper}" "${wsb}/p" --framework onion-evolve --commit fedcba987654 --commit-date 2026-09-01 2>&1 >/dev/null || true)"
  if printf '%s' "${pin_err}" | grep -q '^AVISO: 1 referência' \
     && printf '%s' "${pin_err}" | grep -q 'docs/tech/index.md' \
     && ! printf '%s' "${pin_err}" | grep -q 'inbox'; then
    record_pass "write-stamp: (D_GREP_OLD_PIN) update avisa 1 citação viva do pin antigo; história (inbox) excluída"
  else record_fail "write-stamp: grep-old-pin" "${pin_err}"; fi
  # 5. --role inválido → exit 2 (só adopted|hub)
  if ! bash "${helper}" "${wsb}/h" --framework x --commit c --commit-date 2026-07-23 --role banana >/dev/null 2>&1; then
    record_pass "write-stamp: --role inválido → rejeitado (exit 2)"
  else record_fail "write-stamp: role inválido" "aceitou role fora de adopted|hub"; fi
  rm -rf "${wsb}"
}

# ---------------------------------------------------------------------------
# Modo kg-console — exercita .claude/validation/kg-console.sh (projeção HTML do KG,
# irmão do federation-console). Usa a fixture kg-domain/good-domain.kg.yaml.
# ---------------------------------------------------------------------------
run_kg_console_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/kg-console.sh"
  local fixture="${FIX_DIR}/kg-domain/good-domain.kg.yaml"
  local vendor="${REPO_ROOT}/.claude/validation/vendor/kg-console/cytoscape.min.js"
  if [ ! -f "${helper}" ]; then record_fail "kg-console" "helper ausente: ${helper}"; return; fi
  if [ ! -f "${fixture}" ]; then record_fail "kg-console" "fixture ausente: ${fixture}"; return; fi
  if [ ! -f "${vendor}" ]; then record_fail "kg-console: vendor" "renderer vendorizado ausente: ${vendor}"; return; fi

  # NB: o console agora embute o renderer vendorizado (461 KB) — a saída é grande.
  # `printf "$H" | grep -q` sob `set -o pipefail` dá FALSO-NEGATIVO: grep -q casa
  # cedo e sai, o printf leva SIGPIPE (141) e pipefail propaga o 141 mesmo com match.
  # Por isso gravamos H num ARQUIVO e grepamos o arquivo (sem pipe). Bug latente do
  # harness que só o HTML grande expôs.
  local hdir; hdir="$(mktemp -d)"; local hf="${hdir}/console.html"
  bash "${helper}" "${fixture}" 2>/dev/null > "${hf}"

  # HTML rico self-contained: doctype + /html, SEM placeholder legado, dados em base64
  # (_B64), renderer Cytoscape VENDORIZADO inline, e o app (função b64d + cytoscape()).
  if grep -q '<!doctype html>' "${hf}" && grep -q '</html>' "${hf}" \
     && ! grep -q '__DATA__' "${hf}" \
     && grep -q '_B64=' "${hf}" \
     && grep -q 'The Cytoscape Consortium' "${hf}" \
     && grep -q 'function b64d' "${hf}" \
     && grep -qF 'cytoscape({' "${hf}"; then
    record_pass "kg-console: HTML rico self-contained (Cytoscape inline + app + dados base64)"
  else record_fail "kg-console: html" "HTML inválido/incompleto (falta vendor/app/dados)"; fi

  # O contrato de DADOS embutiu de fato: o blob base64 `kg` decodifica para o
  # grafo (não é uma casca vazia). Sem python no console — mas o selftest pode usá-lo.
  if command -v python3 >/dev/null 2>&1; then
    local kgb; kgb="$(grep -oE '_B64=\{kg:"[^"]+"' "${hf}" | sed 's/_B64={kg:"//;s/"$//')"
    if printf '%s' "${kgb}" | base64 -d 2>/dev/null | python3 -c 'import json,sys;d=json.load(sys.stdin);assert d["node_count"]>0 and d["nodes"]' 2>/dev/null; then
      record_pass "kg-console: o blob base64 kg decodifica para o grafo (não é casca vazia)"
    else record_fail "kg-console: dados" "blob kg não decodifica/vazio"; fi
  fi

  # Self-contained: nenhuma dependência externa (CDN/fetch). O vendor não usa fetch/XHR.
  if grep -qiE 'src=.?https?://|<script src|href=.?https?://[^"]*\.(js|css)|fetch\(' "${hf}"; then
    record_fail "kg-console: self-contained" "tem dependência externa (CDN/fetch)"
  else record_pass "kg-console: self-contained (sem CDN/fetch externo)"; fi

  # Determinismo (mesma entrada → mesmo byte).
  local hf2="${hdir}/console2.html"; bash "${helper}" "${fixture}" 2>/dev/null > "${hf2}"
  if [ "$(sha256sum < "${hf}")" = "$(sha256sum < "${hf2}")" ]; then
    record_pass "kg-console: determinístico"
  else record_fail "kg-console: determinismo" "varia entre execuções"; fi

  # Degradação graciosa: SEM <slug>.narration.json → HTML ainda sai, com tour-esqueleto.
  if grep -q 'buildTour' "${hf}" && grep -q 'tour-esqueleto' "${hf}"; then
    record_pass "kg-console: sem narração → degrada para tour-esqueleto (não quebra)"
  else record_fail "kg-console: degradação" "faltou o fallback de tour sem narração"; fi
  rm -rf "${hdir}"

  # Embutimento OPT-IN da narração: com um <slug>.narration.json irmão, o blob narr
  # decodifica para o objeto autorado (a IA que explica viaja embutida, offline).
  if command -v python3 >/dev/null 2>&1; then
    local nt; nt="$(mktemp -d)"; cp "${fixture}" "${nt}/g.kg.yaml"
    printf '{"guided_tour":[{"focus":["S_novo"],"narration":"passo de teste"}]}' > "${nt}/g.narration.json"
    cp "${helper}" "${REPO_ROOT}/.claude/validation/kg-view.sh" "${REPO_ROOT}/.claude/validation/kg-radar.sh" "${nt}/" 2>/dev/null
    _lib_beside "${nt}"
    mkdir -p "${nt}/vendor/kg-console"; cp "${vendor}" "${nt}/vendor/kg-console/"
    local HN; HN="$(bash "${nt}/kg-console.sh" "${nt}/g.kg.yaml" 2>/dev/null)"
    local nb; nb="$(printf '%s' "${HN}" | grep -oE 'narr:"[^"]*"' | head -1 | sed 's/narr:"//;s/"$//')"
    if printf '%s' "${nb}" | base64 -d 2>/dev/null | grep -q 'passo de teste'; then
      record_pass "kg-console: narração irmã é embutida (base64) quando presente (opt-in)"
    else record_fail "kg-console: narração" "narration.json não embutiu"; fi
    rm -rf "${nt}"
  fi

  # Exit 2 — arquivo inexistente.
  local rc2=0; bash "${helper}" "/nonexistent/x.kg.yaml" >/dev/null 2>&1 || rc2=$?
  if [ "${rc2}" -eq 2 ]; then record_pass "kg-console: arquivo inexistente → exit 2"
  else record_fail "kg-console: uso" "esperava exit 2, veio ${rc2}"; fi

  # Exit 3 — dependência ausente (vendor). Cópia isolada SEM o vendor.
  local t3; t3="$(mktemp -d)"
  cp "${helper}" "${REPO_ROOT}/.claude/validation/kg-view.sh" "${REPO_ROOT}/.claude/validation/kg-radar.sh" "${t3}/" 2>/dev/null
  _lib_beside "${t3}"
  local rc3=0; bash "${t3}/kg-console.sh" "${fixture}" >/dev/null 2>&1 || rc3=$?
  if [ "${rc3}" -eq 3 ]; then record_pass "kg-console: vendor ausente → exit 3 (gracioso)"
  else record_fail "kg-console: dep" "esperava exit 3 sem vendor, veio ${rc3}"; fi
  rm -rf "${t3}"
}

# ---------------------------------------------------------------------------
# Modo kg-narrate-validate — REGRA 47. O validador da narração pré-cozida é o MECANISMO
# que torna "cita ids que existem" determinístico (não promessa). Fixtures self-contained.
# ---------------------------------------------------------------------------
run_kg_narrate_validate_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/kg-narrate-validate.sh"
  [ -f "${helper}" ] || { record_fail "kg-narrate-validate" "helper ausente: ${helper}"; return; }
  command -v python3 >/dev/null 2>&1 || { record_skip "kg-narrate-validate: python3 ausente (skip gracioso)"; return; }
  local t; t="$(mktemp -d)"; trap 'rm -rf "${t}"' RETURN
  # kg-view.sh + kg-radar.sh ao lado (o validador consome a lente vigiada)
  cp "${SCRIPT_DIR}/kg-view.sh" "${SCRIPT_DIR}/kg-radar.sh" "${t}/" 2>/dev/null; _lib_beside "${t}"
  cp "${helper}" "${t}/kg-narrate-validate.sh"
  cat > "${t}/g.kg.yaml" <<'KGEOF'
meta:
  id: fx-narr
  schema_version: "1"
nodes:
  - id: C_UM
    node_type: claim
    plane: DEV
    status: confirmed
    impact: 4
    confidence: 0.9
    label: "afirmacao um"
  - id: E_UM
    node_type: evidence
    plane: PROD
    status: confirmed
    impact: 3
    confidence: 1.0
    label: "evidencia"
edges:
  - from: E_UM
    to: C_UM
    edge_type: SUPPORTS
KGEOF
  local rc

  # (N1) narração válida (ids existem) → exit 0
  printf '{"guided_tour":[{"focus":["C_UM"],"narration":"foco no claim"},{"focus":[],"narration":"abertura"}],"node_summaries":{"E_UM":"a evidencia"}}' > "${t}/g.narration.json"
  rc=0; bash "${t}/kg-narrate-validate.sh" "${t}/g.kg.yaml" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "kg-narrate-validate: (N1) narração com ids reais → válida (exit 0)"
  else record_fail "kg-narrate-validate: (N1)" "narração válida reprovou (rc=${rc})"; fi

  # (N2) id morto no tour → exit 1 (o guard que impede a narração de mentir)
  printf '{"guided_tour":[{"focus":["Z_FANTASMA"],"narration":"mentira"}]}' > "${t}/g.narration.json"
  rc=0; bash "${t}/kg-narrate-validate.sh" "${t}/g.kg.yaml" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "kg-narrate-validate: (N2) id inexistente no tour → REPROVA (exit 1)"
  else record_fail "kg-narrate-validate: (N2)" "id morto passou (rc=${rc}, esperado 1)"; fi

  # (N3) id morto em node_summaries → exit 1
  printf '{"guided_tour":[{"focus":["C_UM"],"narration":"ok"}],"node_summaries":{"Z_NAO":"x"}}' > "${t}/g.narration.json"
  rc=0; bash "${t}/kg-narrate-validate.sh" "${t}/g.kg.yaml" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "kg-narrate-validate: (N3) id morto em node_summaries → REPROVA (exit 1)"
  else record_fail "kg-narrate-validate: (N3)" "summary de id morto passou (rc=${rc})"; fi

  # (N4) tour vazio → exit 1 (narração sem passo não narra nada)
  printf '{"guided_tour":[]}' > "${t}/g.narration.json"
  rc=0; bash "${t}/kg-narrate-validate.sh" "${t}/g.kg.yaml" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "kg-narrate-validate: (N4) guided_tour vazio → REPROVA (exit 1)"
  else record_fail "kg-narrate-validate: (N4)" "tour vazio passou (rc=${rc})"; fi

  # (N5) passo com narration vazio → exit 1 (passo sem voz)
  printf '{"guided_tour":[{"focus":["C_UM"],"narration":"  "}]}' > "${t}/g.narration.json"
  rc=0; bash "${t}/kg-narrate-validate.sh" "${t}/g.kg.yaml" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "kg-narrate-validate: (N5) passo com narration vazio → REPROVA (exit 1)"
  else record_fail "kg-narrate-validate: (N5)" "passo mudo passou (rc=${rc})"; fi
}

# ---------------------------------------------------------------------------
# Modo mail-receiver — exercita .claude/utils/co-evolution/mail-receiver.sh (F1.4: acelerador
# "receiver que acorda"). Self-contained em mktemp (repo sintético com canais inbox/inbound).
# ---------------------------------------------------------------------------
run_mail_receiver_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/co-evolution/mail-receiver.sh"
  if [ ! -f "${helper}" ]; then record_fail "mail-receiver" "helper ausente: ${helper}"; return; fi
  local t; t="$(mktemp -d)"; mkdir -p "$t/docs/evolution/inbox/_processed" "$t/docs/evolution/inbound"
  local out rc
  out="$(bash "${helper}" --repo "$t" 2>&1)"; rc=$?
  if [ -z "${out}" ] && [ "${rc}" -eq 0 ]; then record_pass "mail-receiver: 0 mail → silencioso + exit 0"
  else record_fail "mail-receiver: 0-mail" "esperava vazio+0 (got '${out}'/${rc})"; fi
  printf 'x' > "$t/docs/evolution/inbox/a.md"
  out="$(bash "${helper}" --repo "$t" 2>&1)"
  if printf '%s' "${out}" | grep -q 'co-evolve' && [ -f "$t/.claude/sessions/.mail-receiver.state" ]; then
    record_pass "mail-receiver: mail novo → acorda + salva assinatura"
  else record_fail "mail-receiver: wake" "não acordou / sem estado"; fi
  if [ -z "$(bash "${helper}" --repo "$t" 2>&1)" ]; then record_pass "mail-receiver: dedup (mesmo conjunto → silencioso)"
  else record_fail "mail-receiver: dedup" "não deduplicou"; fi
  printf 'y' > "$t/docs/evolution/inbound/b.md"
  if printf '%s' "$(bash "${helper}" --repo "$t" 2>&1)" | grep -q '2 não-lido'; then
    record_pass "mail-receiver: conjunto novo → acorda de novo"
  else record_fail "mail-receiver: novo" "não reacordou no conjunto novo"; fi
  rm -f "$t/.claude/sessions/.mail-receiver.state"
  local o2; o2="$(bash "${helper}" --repo "$t" --dry-run 2>&1)"
  if printf '%s' "${o2}" | grep -q 'co-evolve' && [ ! -f "$t/.claude/sessions/.mail-receiver.state" ]; then
    record_pass "mail-receiver: --dry-run imprime sem tocar estado"
  else record_fail "mail-receiver: dry-run" "tocou estado ou não imprimiu"; fi
  rm -rf "$t"
}

# ---------------------------------------------------------------------------
# Modo detect-transport — exercita .claude/utils/federation-transport/detect-transport.sh (F2.1:
# resolução SDAAL da via de transporte). Asserções robustas (não fixam roster).
# ---------------------------------------------------------------------------
run_detect_transport_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/federation-transport/detect-transport.sh"
  if [ ! -f "${helper}" ]; then record_fail "detect-transport" "helper ausente: ${helper}"; return; fi
  if [ "$(bash "${helper}" x 2>/dev/null)" = "git-async" ]; then record_pass "detect-transport: default → git-async (seguro)"
  else record_fail "detect-transport: default" "não resolveu git-async"; fi
  if [ "$(FEDERATION_TRANSPORT=local bash "${helper}" x 2>/dev/null)" = "local" ]; then record_pass "detect-transport: env=local → local"
  else record_fail "detect-transport: local" "env=local não resolveu"; fi
  if [ "$(FEDERATION_TRANSPORT=a2a-live bash "${helper}" x 2>/dev/null)" = "a2a-live" ] \
     && FEDERATION_TRANSPORT=a2a-live bash "${helper}" x 2>&1 >/dev/null | grep -qi gated; then
    record_pass "detect-transport: a2a-live explícito → a2a-live + avisa GATED (stub)"
  else record_fail "detect-transport: a2a-live" "não é a2a-live ou não avisou gated"; fi
  if [ "$(FEDERATION_TRANSPORT=auto bash "${helper}" __fantasma__ 2>/dev/null)" = "git-async" ]; then
    record_pass "detect-transport: auto + sem clone → git-async (nunca sobe de via sozinho)"
  else record_fail "detect-transport: auto fallback" "auto não caiu p/ git-async"; fi
  local rc=0; FEDERATION_TRANSPORT=xpto bash "${helper}" x >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 3 ]; then record_pass "detect-transport: FEDERATION_TRANSPORT inválido → exit 3"
  else record_fail "detect-transport: inválido" "esperava exit 3, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo a2a-ssrf — anti-SSRF da URL de webhook A2A (camada 4 do gate a2a-verify,
# F2.2 fundação). Deny-list estrutural (loopback/rfc1918/metadata/ipv6/scheme) +
# allow-list dos hosts conhecidos do members.yaml. Fail-safe: fora da allowlist /
# SSOT ausente = DENY (nunca skip). members.yaml sandbox via A2A_MEMBERS_FILE.
# ---------------------------------------------------------------------------
run_a2a_ssrf_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/federation-transport/a2a-ssrf-check.sh"
  if [ ! -f "${helper}" ]; then record_fail "a2a-ssrf" "helper ausente: ${helper}"; return; fi
  local mf out rc
  mf="$(mktemp)"
  cat > "${mf}" <<'YML'
members:
  - id: onion-evolve
    remote: github.com/marciocar/onion-evolve
  - id: acme
    remote: gitlab.example.org/acme/app
YML
  _ssrf() { rc=0; out="$(A2A_MEMBERS_FILE="${mf}" bash "${helper}" "$1" 2>/dev/null)" || rc=$?; }

  _ssrf "http://127.0.0.1:8787/h"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'loopback'; then record_pass "a2a-ssrf: 127.0.0.1 → deny loopback"
  else record_fail "a2a-ssrf: loopback" "out='${out}' rc=${rc}"; fi

  _ssrf "http://169.254.169.254/latest/meta-data/"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'link-local-metadata'; then record_pass "a2a-ssrf: 169.254.169.254 (metadata cloud) → deny"
  else record_fail "a2a-ssrf: metadata" "out='${out}' rc=${rc}"; fi

  _ssrf "https://10.1.2.3/h"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'rfc1918'; then record_pass "a2a-ssrf: 10.x → deny rfc1918"
  else record_fail "a2a-ssrf: rfc1918-10" "out='${out}' rc=${rc}"; fi

  _ssrf "https://192.168.1.1/h"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'rfc1918'; then record_pass "a2a-ssrf: 192.168.x → deny rfc1918"
  else record_fail "a2a-ssrf: rfc1918-192" "out='${out}' rc=${rc}"; fi

  _ssrf "ftp://gitlab.example.org/x"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'scheme'; then record_pass "a2a-ssrf: esquema não-http → deny"
  else record_fail "a2a-ssrf: scheme" "out='${out}' rc=${rc}"; fi

  _ssrf "https://gitlab.example.org/webhook"
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '^allow'; then record_pass "a2a-ssrf: host ∈ members.remote → allow"
  else record_fail "a2a-ssrf: allow" "out='${out}' rc=${rc}"; fi

  _ssrf "https://evil.example.net/hook"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'not-in-allowlist'; then record_pass "a2a-ssrf: host público fora da allowlist → deny"
  else record_fail "a2a-ssrf: allowlist" "out='${out}' rc=${rc}"; fi

  # fail-safe: SSOT ausente → deny (nunca allow por ausência)
  rc=0; out="$(A2A_MEMBERS_FILE=/nao/existe/members.yaml bash "${helper}" "https://gitlab.example.org/x" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'members-absent'; then record_pass "a2a-ssrf: SSOT ausente → deny (fail-safe)"
  else record_fail "a2a-ssrf: ssot-absent" "out='${out}' rc=${rc}"; fi

  rm -f "${mf}"
}

# ---------------------------------------------------------------------------
# Modo a2a-verify — o gate "verificação-antes-de-agir" do a2a-live (F2.2 fundação).
# Self-contained em mktemp (forja par RSA + JWS on-the-fly com openssl, como
# run_pin_integrity forja commits). Cobre as 6 camadas + os invariantes hardcoded
# (gated:true / committed:false SEMPRE) + o FAIL-SAFE (tooling ausente → VETO, nunca skip).
# Precisa openssl+jq+python3+yaml p/ forjar fixtures — ausente → skip (não é o SUT).
# ---------------------------------------------------------------------------
run_a2a_verify_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/federation-transport/a2a-verify.sh"
  if [ ! -f "${helper}" ]; then record_fail "a2a-verify" "helper ausente: ${helper}"; return; fi
  if ! command -v openssl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1 \
     || ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import yaml' >/dev/null 2>&1; then
    record_skip "a2a-verify: tooling p/ forjar fixtures ausente → skip (não-SUT)"; return
  fi
  local sb; sb="$(mktemp -d)"; mkdir -p "${sb}/docs/evolution/federation" "${sb}/jwks"
  cat > "${sb}/docs/evolution/federation/members.yaml" <<'YML'
members:
  - id: onion-evolve
    role: source
    remote: github.com/marciocar/onion-evolve
    a2a: { keys: [k1] }
  - id: acme
    role: standalone
    remote: github.com/acme/app
    a2a: { keys: [k1] }
    trust: { can_receive_from: [onion-evolve] }
  - id: fin
    role: standalone
    mode: regulated
    remote: github.com/fin/app
    trust: { can_receive_from: [onion-evolve] }
YML
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${sb}/priv.pem" 2>/dev/null
  openssl pkey -in "${sb}/priv.pem" -pubout -out "${sb}/jwks/k1.pem" 2>/dev/null
  local NOW out rc
  NOW="$(date +%s)"
  _b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
  _jws() { local h p; h="$(printf '{"alg":"RS256","kid":"%s"}' "${6:-k1}" | _b64url)"
    p="$(printf '{"iss":"%s","aud":"%s","iat":%s,"exp":%s,"jti":"%s"}' "$1" "$2" "$3" "$4" "$5" | _b64url)"
    printf '%s.%s.%s' "$h" "$p" "$(printf '%s' "$h.$p" | openssl dgst -sha256 -sign "${sb}/priv.pem" | _b64url)"; }
  _env() { printf '{"jws":"%s","signal":{"from":"%s","to":"%s","kind":"signal"}%s}' "$1" "$2" "$3" "$4"; }
  # A2A_CLOCK_TRUST=attested: o relógio do HOST de teste não é o SUT destes casos (a guarda
  # clock-untrusted tem casos dedicados abaixo, com PATH stubado — determinístico em qualquer CI).
  _verify() { rc=0; out="$(A2A_CLOCK_TRUST=attested A2A_JWKS_DIR="${sb}/jwks" bash "${helper}" --receiver "$1" --repo "${sb}" --dry-run --envelope - <<<"$2" 2>/dev/null)" || rc=$?; }

  _verify onion-evolve "$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-h)" acme onion-evolve "")"
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '"verified":true'; then record_pass "a2a-verify: envelope assinado válido → verified"
  else record_fail "a2a-verify: happy" "out='${out}' rc=${rc}"; fi
  if printf '%s' "${out}" | grep -q '"gated":true'; then record_pass "a2a-verify: gated:true sempre (verified pende gate humano)"
  else record_fail "a2a-verify: gated-verified" "out='${out}'"; fi
  if printf '%s' "${out}" | grep -q '"committed":false'; then record_pass "a2a-verify: committed:false sempre (I3)"
  else record_fail "a2a-verify: committed" "out='${out}'"; fi

  _verify onion-evolve "$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-h)" acme onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q '"reason":"replay"'; then record_pass "a2a-verify: jti reusado → veto replay"
  else record_fail "a2a-verify: replay" "out='${out}' rc=${rc}"; fi

  _verify onion-evolve "$(_env "$(_jws acme onion-evolve "$((NOW-7200))" "$((NOW-3600))" jti-e)" acme onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'expired'; then record_pass "a2a-verify: exp no passado → veto expired"
  else record_fail "a2a-verify: expired" "out='${out}' rc=${rc}"; fi

  _verify onion-evolve "$(_env "$(_jws acme onion-evolve "$((NOW+99999))" "$((NOW+999999))" jti-f)" acme onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'future'; then record_pass "a2a-verify: iat muito à frente → veto future"
  else record_fail "a2a-verify: future" "out='${out}' rc=${rc}"; fi

  _verify onion-evolve "$(_env "$(_jws ghost onion-evolve "${NOW}" "$((NOW+3600))" jti-g)" ghost onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'trust-denied'; then record_pass "a2a-verify: from fora da policy → veto trust-denied"
  else record_fail "a2a-verify: trust" "out='${out}' rc=${rc}"; fi
  if printf '%s' "${out}" | grep -q '"gated":true'; then record_pass "a2a-verify: gated:true sempre (mesmo em veto)"
  else record_fail "a2a-verify: gated-veto" "out='${out}'"; fi

  _verify onion-evolve "$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-s)" acme onion-evolve ',"pushNotificationConfig":{"url":"http://169.254.169.254/"}')"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q '"reason":"ssrf"'; then record_pass "a2a-verify: webhook p/ metadata → veto ssrf"
  else record_fail "a2a-verify: ssrf" "out='${out}' rc=${rc}"; fi

  local jbad; jbad="$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-b)"; jbad="${jbad%.*}.AAAABBBBCCCCDDDD"
  _verify onion-evolve "$(_env "${jbad}" acme onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'bad-signature'; then record_pass "a2a-verify: assinatura adulterada → veto bad-signature"
  else record_fail "a2a-verify: bad-sig" "out='${out}' rc=${rc}"; fi

  _verify onion-evolve "$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-k kZ)" acme onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'unknown-kid'; then record_pass "a2a-verify: kid sem pubkey no JWKS → veto unknown-kid"
  else record_fail "a2a-verify: kid" "out='${out}' rc=${rc}"; fi

  _verify fin "$(_env "$(_jws onion-evolve fin "${NOW}" "$((NOW+3600))" jti-r)" onion-evolve fin "")"
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '"apply_mode":"propose-only"'; then record_pass "a2a-verify: receptor regulado → apply_mode:propose-only (never-live-pull)"
  else record_fail "a2a-verify: regulated" "out='${out}' rc=${rc}"; fi

  # kid-binding: from=fin (sem k1 nas suas a2a.keys) assina com k1 → veto (anti-impersonação, hardening de um adotante multi-linhagem)
  _verify onion-evolve "$(_env "$(_jws fin onion-evolve "${NOW}" "$((NOW+3600))" jti-imp)" fin onion-evolve "")"
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'kid-not-owned-by-from'; then record_pass "a2a-verify: kid de outro dono (impersonação) → veto kid-not-owned-by-from"
  else record_fail "a2a-verify: kid-binding" "out='${out}' rc=${rc}"; fi

  # FAIL-SAFE: openssl fora do PATH → veto tooling-absent (degrade→VETO, nunca skip/allow)
  local bin t p; bin="$(mktemp -d)"
  for t in jq date mktemp python3 grep cat dirname git tr sed sort find awk head cut wc bash sha256sum; do
    p="$(command -v "$t" 2>/dev/null)"; [ -n "$p" ] && ln -s "$p" "${bin}/$t"
  done
  local se; se="$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-safe)" acme onion-evolve "")"
  rc=0; out="$(PATH="${bin}" A2A_JWKS_DIR="${sb}/jwks" bash "${helper}" --receiver onion-evolve --repo "${sb}" --dry-run --envelope - <<<"${se}" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'tooling-absent'; then record_pass "a2a-verify: FAIL-SAFE — tooling ausente → veto (nunca skip/allow)"
  else record_fail "a2a-verify: fail-safe" "out='${out}' rc=${rc}"; fi

  # CLOCK-TRUST (carimbo de tempo só vale com fonte verificada): PATH stubado com TODAS as
  # ferramentas + timedatectl fake dizendo NTPSynchronized=no e sem chronyc/ntpstat → veto.
  local clkbin; clkbin="$(mktemp -d)"
  for t in jq date mktemp python3 grep cat dirname git tr sed sort find awk head cut wc bash sha256sum openssl; do
    p="$(command -v "$t" 2>/dev/null)"; [ -n "$p" ] && ln -s "$p" "${clkbin}/$t"
  done
  printf '#!/usr/bin/env bash\necho no\n' > "${clkbin}/timedatectl"; chmod +x "${clkbin}/timedatectl"
  local ce; ce="$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-clk1)" acme onion-evolve "")"
  rc=0; out="$(PATH="${clkbin}" A2A_JWKS_DIR="${sb}/jwks" bash "${helper}" --receiver onion-evolve --repo "${sb}" --dry-run --envelope - <<<"${ce}" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'clock-untrusted'; then record_pass "a2a-verify: relógio sem prova de sync → veto clock-untrusted (fail-safe)"
  else record_fail "a2a-verify: clock-untrusted" "out='${out}' rc=${rc}"; fi
  # mesmo host dessincronizado + atestado explícito do operador → camada passa (verified)
  ce="$(_env "$(_jws acme onion-evolve "${NOW}" "$((NOW+3600))" jti-clk2)" acme onion-evolve "")"
  rc=0; out="$(PATH="${clkbin}" A2A_CLOCK_TRUST=attested A2A_JWKS_DIR="${sb}/jwks" bash "${helper}" --receiver onion-evolve --repo "${sb}" --dry-run --envelope - <<<"${ce}" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '"verified":true'; then record_pass "a2a-verify: A2A_CLOCK_TRUST=attested → atestado explícito destrava a camada"
  else record_fail "a2a-verify: clock-attested" "out='${out}' rc=${rc}"; fi
  rm -rf "${bin}" "${clkbin}" "${sb}"
}

# ---------------------------------------------------------------------------
# Modo agent-card — gerador do Agent Card A2A do core (F2.2 fundação). Projeção
# read-only do members.yaml FILTRADA ao próprio core (confidencialidade). Cobre:
# JSON válido, confidencialidade (adotante não vaza), signals-only, securitySchemes,
# determinismo e o exit-3 gracioso (core ausente). Sandbox via A2A_MEMBERS_FILE.
# ---------------------------------------------------------------------------
run_agent_card_selftests() {
  local gen="${REPO_ROOT}/.claude/validation/a2a-agent-card.sh"
  if [ ! -f "${gen}" ]; then record_fail "agent-card" "gerador ausente: ${gen}"; return; fi
  if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import yaml' >/dev/null 2>&1; then
    record_skip "agent-card: python+yaml ausente → skip (não-SUT)"; return
  fi
  local mf mf2 out rc a b n
  mf="$(mktemp)"
  cat > "${mf}" <<'YML'
members:
  - id: onion-evolve
    role: source
    remote: github.com/marciocar/onion-evolve
  - id: acme-secret
    role: standalone
    remote: github.com/acme/secret
YML
  rc=0; out="$(A2A_MEMBERS_FILE="${mf}" bash "${gen}" 2>/dev/null)" || rc=$?

  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | python3 -c 'import sys,json;json.load(sys.stdin)' 2>/dev/null; then
    record_pass "agent-card: JSON válido"
  else record_fail "agent-card: json" "rc=${rc} out='${out:0:80}'"; fi

  if printf '%s' "${out}" | grep -q 'onion-evolve' && ! printf '%s' "${out}" | grep -q 'acme-secret'; then
    record_pass "agent-card: CONFIDENCIALIDADE — só o core, adotante não vaza"
  else record_fail "agent-card: confidencialidade" "vazou adotante OU sem core"; fi

  n="$(printf '%s' "${out}" | python3 -c 'import sys,json;print(len(json.load(sys.stdin).get("skills",[])))' 2>/dev/null)"
  if [ "${n}" = "1" ] && printf '%s' "${out}" | grep -q 'signals-only'; then
    record_pass "agent-card: signals-only (1 skill gated, sem conversa autônoma)"
  else record_fail "agent-card: signals-only" "n_skills='${n}'"; fi

  if printf '%s' "${out}" | grep -q '"oauth2"' && printf '%s' "${out}" | grep -q '"mtls"'; then
    record_pass "agent-card: securitySchemes oauth2 + mtls"
  else record_fail "agent-card: schemes" "faltou oauth2/mtls"; fi

  a="$(A2A_MEMBERS_FILE="${mf}" bash "${gen}" 2>/dev/null | sha256sum)"
  b="$(A2A_MEMBERS_FILE="${mf}" bash "${gen}" 2>/dev/null | sha256sum)"
  if [ "${a}" = "${b}" ]; then record_pass "agent-card: determinístico (2 rodadas sha-iguais)"
  else record_fail "agent-card: determinismo" "diverge"; fi

  mf2="$(mktemp)"; printf 'members:\n  - id: acme\n    role: standalone\n' > "${mf2}"
  rc=0; A2A_MEMBERS_FILE="${mf2}" bash "${gen}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 3 ]; then record_pass "agent-card: core ausente → exit 3 (gracioso, gerador)"
  else record_fail "agent-card: exit3" "esperava exit 3, veio ${rc}"; fi

  rm -f "${mf}" "${mf2}"
}

# ---------------------------------------------------------------------------
# Modo a2a-accept — o ATO HUMANO que fecha o gate: registro verificado da fila →
# doc de inbox (F2.2). Cobre: cria doc + marca transporte, idempotência, recusa
# de não-verificado (fail-safe) e registro malformado. Self-contained em mktemp.
# ---------------------------------------------------------------------------
run_a2a_accept_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/federation-transport/a2a-accept.sh"
  if [ ! -f "${helper}" ]; then record_fail "a2a-accept" "helper ausente: ${helper}"; return; fi
  if ! command -v jq >/dev/null 2>&1; then record_skip "a2a-accept: jq ausente → skip (não-SUT)"; return; fi
  local d ib rec out rc doc
  d="$(mktemp -d)"; ib="${d}/inbox"; mkdir -p "${ib}"
  rec="${d}/verified.json"
  cat > "${rec}" <<'JSON'
{"taskId":"t1","receivedAt":"2026-07-09T21:42:01Z","from":"acme","signal":{"id":"2026-07-09-acme-a2a-hello","from":"acme","to":"onion-evolve","kind":"signal","body_path":"docs/x.md"},"verdict":{"verified":true,"regulated":false,"apply_mode":"gated"}}
JSON
  doc="${ib}/2026-07-09-acme-a2a-hello.md"
  rc=0; out="$(bash "${helper}" "${rec}" --inbox "${ib}" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${doc}" ]; then record_pass "a2a-accept: verificado → doc de inbox criado"
  else record_fail "a2a-accept: create" "rc=${rc} out='${out}'"; fi
  if grep -q 'via a2a-live' "${doc}" 2>/dev/null && grep -q 'Conteúdo referenciado' "${doc}" 2>/dev/null; then record_pass "a2a-accept: doc marca transporte a2a-live + body_path"
  else record_fail "a2a-accept: fields" "campos ausentes no doc"; fi

  rc=0; out="$(bash "${helper}" "${rec}" --inbox "${ib}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'já aceito'; then record_pass "a2a-accept: idempotente (não sobrescreve)"
  else record_fail "a2a-accept: idem" "rc=${rc} out='${out}'"; fi

  local recu="${d}/unverified.json"
  printf '%s' '{"from":"x","signal":{"id":"bad"},"verdict":{"verified":false,"reason":"veto"}}' > "${recu}"
  rc=0; bash "${helper}" "${recu}" --inbox "${ib}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ] && [ "$(find "${ib}" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')" = "1" ]; then record_pass "a2a-accept: não-verificado → RECUSADO (fail-safe, nada criado)"
  else record_fail "a2a-accept: refuse" "rc=${rc}"; fi

  printf 'not json' > "${d}/bad.json"
  rc=0; bash "${helper}" "${d}/bad.json" --inbox "${ib}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "a2a-accept: registro malformado → erro"
  else record_fail "a2a-accept: malformed" "rc=${rc}"; fi

  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo resolve-scope-layers — exercita .claude/utils/scope/resolve-scope-layers.sh (RFC-0005: fecha o
# loop do compose-settings — descobre a cadeia empresa→time→pessoa e compõe). Self-contained.
# ---------------------------------------------------------------------------
run_resolve_scope_layers_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/scope/resolve-scope-layers.sh"
  if [ ! -f "${helper}" ]; then record_fail "resolve-scope-layers" "helper ausente: ${helper}"; return; fi
  local t; t="$(mktemp -d)"; git -C "$t" init -q >/dev/null 2>&1
  mkdir -p "$t/.claude" "$t/apps/dev/.claude"
  printf '%s' '{"theme":"dark","permissions":{"allow":["Bash(git *)"]}}' > "$t/.claude/settings.json"
  printf '%s' '{"model":"opus","permissions":{"allow":["Bash(nx *)"]}}' > "$t/apps/dev/.claude/settings.json"
  local us; us="$(mktemp)"; printf '%s' '{"theme":"light"}' > "$us"
  if [ "$(bash "${helper}" "$t/apps/dev" --user "$us" --list 2>/dev/null | grep -c .)" = "3" ]; then
    record_pass "resolve-scope-layers: --list resolve 3 camadas (empresa+time+pessoa)"
  else record_fail "resolve-scope-layers: list" "não resolveu 3 camadas"; fi
  local rc=0; bash "${helper}" /dir/inexistente >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "resolve-scope-layers: dir inexistente → exit 2"
  else record_fail "resolve-scope-layers: dir" "esperava 2, veio ${rc}"; fi
  if command -v jq >/dev/null 2>&1; then
    local eff; eff="$(bash "${helper}" "$t/apps/dev" --user "$us" 2>/dev/null)"
    if [ "$(printf '%s' "${eff}" | jq -r .theme)" = "light" ] && [ "$(printf '%s' "${eff}" | jq -r .model)" = "opus" ] \
       && [ "$(printf '%s' "${eff}" | jq -c '.permissions.allow')" = '["Bash(git *)","Bash(nx *)"]' ]; then
      record_pass "resolve-scope-layers: compõe efetivo (last-wins pessoa + model time + união)"
    else record_fail "resolve-scope-layers: compose" "efetivo incorreto"; fi
  else record_skip "resolve-scope-layers: compose pulado (sem jq)"; fi
  rm -rf "$t" "$us"
}

# ---------------------------------------------------------------------------
# Modo show-scope — exercita a proveniência-por-chave do compose-settings.sh (RFC-0005 Fase 2:
# paridade `git config --show-scope`). Self-contained em mktemp. Cobre: sobreposição escalar ·
# set-once · chave profunda · array com origem por-elemento · conflito de tipo (sub-chave não vaza) ·
# invariante strip==compose (runtime, exit 4) · determinismo · labels + fallback basename · --json
# (meta.role/form + status) · modos-de-falha (uso inválido → exit 2) · passthrough do resolve com stamp.
# ---------------------------------------------------------------------------
run_show_scope_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/scope/compose-settings.sh"
  local resolver="${REPO_ROOT}/.claude/utils/scope/resolve-scope-layers.sh"
  if [ ! -f "${helper}" ]; then record_fail "show-scope" "helper ausente: ${helper}"; return; fi
  if ! command -v jq >/dev/null 2>&1; then record_skip "show-scope: jq ausente → pulado (gracioso)"; return; fi
  local TAB=$'\t'
  local d; d="$(mktemp -d)"
  printf '%s' '{"theme":"dark","permissions":{"allow":["Bash(git *)"],"deny":[]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"fw"}]}]}}' > "$d/fw.json"
  printf '%s' '{"permissions":{"deny":["x"]},"env":{"ORG":"acme"}}' > "$d/org.json"
  printf '%s' '{"model":"opus","permissions":{"allow":["Bash(nx *)"]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"team"}]}]}}' > "$d/team.json"
  printf '%s' '{"theme":"light","env":{"EDITOR":"vim"}}' > "$d/person.json"

  # (a) texto com labels canônicos: vencedor, sobreposição, set-once, chave profunda, array por-elemento
  local S rc=0
  S="$(bash "${helper}" --show-scope --role adopted --form docs-only \
        framework="$d/fw.json" empresa="$d/org.json" time="$d/team.json" pessoa="$d/person.json" 2>/dev/null)" || rc=$?
  if [ "$rc" -eq 0 ] \
     && printf '%s\n' "$S" | grep -qxF "# layers: framework empresa time pessoa · role: adopted · form: docs-only" \
     && printf '%s\n' "$S" | grep -qxF "pessoa${TAB}theme=\"light\"${TAB}# sobrepõe: framework" \
     && printf '%s\n' "$S" | grep -qxF "time${TAB}model=\"opus\"" \
     && printf '%s\n' "$S" | grep -qxF "empresa${TAB}env.ORG=\"acme\"" \
     && printf '%s\n' "$S" | grep -qxF "framework${TAB}permissions.allow[0]=\"Bash(git *)\"" \
     && printf '%s\n' "$S" | grep -qxF "time${TAB}permissions.allow[1]=\"Bash(nx *)\"${TAB}# merged"; then
    record_pass "show-scope: texto (vencedor + sobrepõe + set-once + chave profunda + array merged)"
  else record_fail "show-scope: texto" "saída não bate com o esperado (rc=$rc)"; fi

  # (b) invariante strip==compose (checada em runtime a cada execução; exit 4 = violação) — rc=0 acima
  # já a exercita no caso complexo; aqui o spot-check cruzado JSON×compose (declarado≠verificado):
  local C J
  C="$(bash "${helper}" "$d/fw.json" "$d/org.json" "$d/team.json" "$d/person.json" 2>/dev/null)"
  J="$(bash "${helper}" --show-scope --json fw="$d/fw.json" org="$d/org.json" team="$d/team.json" person="$d/person.json" 2>/dev/null)"
  if [ "$(printf '%s' "$C" | jq -r .theme)" = "$(printf '%s' "$J" | jq -r '.keys.theme.value')" ] \
     && [ "$(printf '%s' "$C" | jq -c '.permissions.allow')" = "$(printf '%s' "$J" | jq -c '.keys["permissions.allow"].elements | map(.value)')" ]; then
    record_pass "show-scope: invariante (valores do JSON == compose)"
  else record_fail "show-scope: invariante" "valores do --json divergem do compose"; fi

  # (c) --json bem-formado: status overridden/merged + overrides[] + meta.role/form
  if [ "$(printf '%s' "$J" | jq -r '.keys.theme.status')" = "overridden" ] \
     && [ "$(printf '%s' "$J" | jq -c '.keys.theme.overrides')" = '["fw"]' ] \
     && [ "$(printf '%s' "$J" | jq -r '.keys["permissions.allow"].status')" = "merged" ] \
     && [ "$(printf '%s' "$J" | jq '.keys["permissions.allow"].elements|length')" = "2" ] \
     && [ "$(bash "${helper}" --show-scope --json --role source --form full "$d/fw.json" 2>/dev/null | jq -r '.meta.role + "/" + .meta.form')" = "source/full" ]; then
    record_pass "show-scope: --json (status + overrides + meta.role/form)"
  else record_fail "show-scope: json" "estrutura do --json incorreta"; fi

  # (d) conflito de tipo: objeto sombreado por escalar → folha vence, sub-chave NÃO vaza
  printf '%s' '{"x":{"a":1,"b":2}}' > "$d/t1.json"; printf '%s' '{"x":"flat"}' > "$d/t2.json"
  local T; T="$(bash "${helper}" --show-scope base="$d/t1.json" top="$d/t2.json" 2>/dev/null)"
  if printf '%s\n' "$T" | grep -qxF "top${TAB}x=\"flat\"${TAB}# sobrepõe: base" \
     && ! printf '%s\n' "$T" | grep -qF "x.a"; then
    record_pass "show-scope: conflito de tipo (folha vence; sub-chave não vaza)"
  else record_fail "show-scope: conflito de tipo" "sub-chave vazou ou vencedor errado"; fi

  # (e) determinismo (sha256 de 2 execuções)
  local S2; S2="$(bash "${helper}" --show-scope --role adopted --form docs-only \
        framework="$d/fw.json" empresa="$d/org.json" time="$d/team.json" pessoa="$d/person.json" 2>/dev/null)"
  if [ "$(printf '%s' "$S" | sha256sum)" = "$(printf '%s' "$S2" | sha256sum)" ]; then
    record_pass "show-scope: determinístico"
  else record_fail "show-scope: determinismo" "saída varia entre execuções"; fi

  # (f) modos-de-falha: --json sem --show-scope · --role inválido · JSON inválido (todos exit 2)
  local r1=0 r2=0 r3=0
  bash "${helper}" --json "$d/fw.json" >/dev/null 2>&1 || r1=$?
  bash "${helper}" --show-scope --role banana "$d/fw.json" >/dev/null 2>&1 || r2=$?
  printf '%s' '{bad' > "$d/bad.json"; bash "${helper}" --show-scope "$d/fw.json" "$d/bad.json" >/dev/null 2>&1 || r3=$?
  if [ "$r1" -eq 2 ] && [ "$r2" -eq 2 ] && [ "$r3" -eq 2 ]; then
    record_pass "show-scope: modos-de-falha (--json solto / --role inválido / JSON inválido → exit 2)"
  else record_fail "show-scope: falha" "esperava exit 2/2/2, veio $r1/$r2/$r3"; fi

  # (g) passthrough do resolve-scope-layers: labels canônicos + role/form lidos do stamp
  if [ -f "${resolver}" ]; then
    local t us R; t="$(mktemp -d)"; git -C "$t" init -q >/dev/null 2>&1
    mkdir -p "$t/.claude" "$t/apps/dev/.claude"
    printf '%s' '{"theme":"dark"}' > "$t/.claude/settings.json"
    printf '%s' '{"model":"opus"}' > "$t/apps/dev/.claude/settings.json"
    printf 'framework: onion-evolve\nsource_commit: abc\nsource_commit_date: 2026-07-01\nrole: adopted\nform: docs-only\n' > "$t/.claude/.onion-version"
    us="$(mktemp)"; printf '%s' '{"theme":"light"}' > "$us"
    R="$(bash "${resolver}" "$t/apps/dev" --user "$us" --show-scope 2>/dev/null)"
    if printf '%s\n' "$R" | grep -qxF "# layers: empresa time pessoa · role: adopted · form: docs-only" \
       && printf '%s\n' "$R" | grep -qxF "pessoa${TAB}theme=\"light\"${TAB}# sobrepõe: empresa"; then
      record_pass "show-scope: resolve-scope-layers repassa (labels canônicos + role/form do stamp)"
    else record_fail "show-scope: resolve" "passthrough sem labels/role/form esperados"; fi
    rm -rf "$t" "$us"
  else record_fail "show-scope" "resolver ausente: ${resolver}"; fi
  rm -rf "$d"
}

# ---------------------------------------------------------------------------
# Modo prettierignore — exercita .claude/utils/adopt/merge-prettierignore.sh.
# Self-contained (estilo run_resolve_selftests): cenários em mktemp -d, sem
# fixture-file/manifest. Cobre os MODOS DE FALHA (não só o happy-path): criação
# from-scratch, append parcial preservando o original, append SEM newline final
# (bug de linha-grudada), idempotência byte-a-byte, e o caso do adotante real
# (paths soltos sem cabeçalho → não polui com cabeçalho órfão).
# ---------------------------------------------------------------------------
run_prettierignore_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/merge-prettierignore.sh"
  local tpl="${REPO_ROOT}/.claude/utils/adopt/prettierignore-onion.tpl"
  if [ ! -f "${helper}" ]; then record_fail "prettierignore" "helper ausente: ${helper}"; return; fi
  if [ ! -f "${tpl}" ]; then record_fail "prettierignore" "template ausente: ${tpl}"; return; fi
  local d

  # (a) absent → cria com paths + cabeçalho de auto-doc
  d="$(mktemp -d)"; bash "${helper}" "${d}" >/dev/null 2>&1
  if grep -qxF "docs/onion/inventory.md" "${d}/.prettierignore" 2>/dev/null \
     && grep -qF "=== onion" "${d}/.prettierignore" 2>/dev/null; then
    record_pass "prettierignore: absent cria com paths + cabeçalho"
  else record_fail "prettierignore: absent cria" "faltou path ou cabeçalho na criação"; fi
  rm -rf "${d}"

  # (b) partial (com \n final) → appenda os faltantes SEM cabeçalho; original intacto
  d="$(mktemp -d)"; printf '.claude/\n' > "${d}/.prettierignore"; bash "${helper}" "${d}" >/dev/null 2>&1
  if grep -qxF "docs/meta-specs/" "${d}/.prettierignore" && grep -qxF ".claude/" "${d}/.prettierignore" \
     && ! grep -qF "=== onion" "${d}/.prettierignore"; then
    record_pass "prettierignore: partial appenda sem cabeçalho órfão"
  else record_fail "prettierignore: partial" "appendou cabeçalho órfão ou perdeu linha original"; fi
  rm -rf "${d}"

  # (c) partial SEM newline final → 1ª linha appendada NÃO gruda na última existente
  d="$(mktemp -d)"; printf '.claude/' > "${d}/.prettierignore"; bash "${helper}" "${d}" >/dev/null 2>&1
  if grep -qxF ".claude/" "${d}/.prettierignore" && grep -qxF "docs/sdaal/" "${d}/.prettierignore"; then
    record_pass "prettierignore: partial-no-eol não gruda linhas"
  else record_fail "prettierignore: partial-no-eol" "linha grudou (newline final não garantido)"; fi
  rm -rf "${d}"

  # (d) complete (copiado do .tpl) → no-op byte-a-byte (idempotência genuína)
  d="$(mktemp -d)"; cp "${tpl}" "${d}/.prettierignore"
  local before after; before="$(cat "${d}/.prettierignore")"; bash "${helper}" "${d}" >/dev/null 2>&1
  after="$(cat "${d}/.prettierignore")"
  if [ "${before}" = "${after}" ]; then record_pass "prettierignore: complete é no-op (idempotente)"
  else record_fail "prettierignore: complete" "mutou um alvo já completo"; fi
  rm -rf "${d}"

  # (e) complete-no-header → 5 paths soltos (espelha um caso real de campo): no-op, NÃO injeta cabeçalho órfão
  d="$(mktemp -d)"
  printf '.claude/\ndocs/meta-specs/\ndocs/sdaal/\ndocs/knowledge-base/\ndocs/onion/inventory.md\n' > "${d}/.prettierignore"
  before="$(cat "${d}/.prettierignore")"; bash "${helper}" "${d}" >/dev/null 2>&1
  after="$(cat "${d}/.prettierignore")"
  if [ "${before}" = "${after}" ]; then record_pass "prettierignore: complete-no-header não injeta cabeçalho"
  else record_fail "prettierignore: complete-no-header" "injetou cabeçalho órfão num alvo já protegido"; fi
  rm -rf "${d}"

  # (f) CRLF → .claude/\r\n no alvo não vira duplicata (normalização CRLF na comparação)
  d="$(mktemp -d)"; printf '.claude/\r\n' > "${d}/.prettierignore"; bash "${helper}" "${d}" >/dev/null 2>&1
  if [ "$(grep -cF '.claude/' "${d}/.prettierignore")" = "1" ]; then
    record_pass "prettierignore: CRLF não duplica"
  else record_fail "prettierignore: CRLF" ".claude/ duplicado (CRLF não normalizado)"; fi
  rm -rf "${d}"

  # (g) $DEST inválido → exit 2 (erro de uso, não gracioso)
  local rc=0; bash "${helper}" "/nao/existe/$$" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "prettierignore: dest inválido → exit 2"
  else record_fail "prettierignore: dest inválido" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo scope-gitignore — exercita .claude/utils/adopt/scope-claude-gitignore.sh
# (escopa um ignore CEGO de .claude/ p/ que a superfície do framework + stamp sejam
# TRACKEÁVEIS no adotante; sinal de campo de adotante 2026-07-24). Self-contained.
# ---------------------------------------------------------------------------
run_scope_gitignore_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/scope-claude-gitignore.sh"
  if [ ! -f "${helper}" ]; then record_fail "scope-gitignore" "helper ausente: ${helper}"; return; fi
  local d before after

  # (a) ignore cego DUPLO (caso de campo) → escopa: .claude/ deixa de ser ignorado, efêmeros seguem
  d="$(mktemp -d)"; printf 'node_modules/\n.claude/\nbackups/\n.codex/\n.claude/\n_private/\n' > "${d}/.gitignore"
  bash "${helper}" "${d}" >/dev/null 2>&1
  if ! grep -qxF ".claude/" "${d}/.gitignore" \
     && grep -qxF ".claude/sessions/" "${d}/.gitignore" \
     && grep -qxF ".claude/settings.local.json" "${d}/.gitignore" \
     && grep -qxF "_private/" "${d}/.gitignore"; then
    record_pass "scope-gitignore: ignore cego duplo escopado (efêmeros mantidos, resto preservado)"
  else record_fail "scope-gitignore: cego duplo" "não escopou, ou perdeu linha não-relacionada"; fi
  rm -rf "${d}"

  # (b) idempotência → 2ª execução é no-op byte-a-byte
  d="$(mktemp -d)"; printf 'x/\n.claude/\ny/\n' > "${d}/.gitignore"
  bash "${helper}" "${d}" >/dev/null 2>&1; before="$(cat "${d}/.gitignore")"
  bash "${helper}" "${d}" >/dev/null 2>&1; after="$(cat "${d}/.gitignore")"
  if [ "${before}" = "${after}" ]; then record_pass "scope-gitignore: idempotente (2ª rodada no-op)"
  else record_fail "scope-gitignore: idempotência" "mutou um .gitignore já escopado"; fi
  rm -rf "${d}"

  # (c) já escopado + negação + subpath → intacto (nada cego → no-op)
  d="$(mktemp -d)"; printf '.claude/sessions/\n.claude/settings.local.json\n!.claude/keep.md\nsrc/\n' > "${d}/.gitignore"
  before="$(cat "${d}/.gitignore")"; bash "${helper}" "${d}" >/dev/null 2>&1; after="$(cat "${d}/.gitignore")"
  if [ "${before}" = "${after}" ]; then record_pass "scope-gitignore: sem ignore cego → intacto (subpath/negação preservados)"
  else record_fail "scope-gitignore: sem-cego" "mexeu num .gitignore sem ignore cego"; fi
  rm -rf "${d}"

  # (d) sem .gitignore → no-op exit 0 (a superfície .claude/ rastreia naturalmente)
  d="$(mktemp -d)"; local rc=0; bash "${helper}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ ! -f "${d}/.gitignore" ]; then record_pass "scope-gitignore: sem .gitignore → no-op exit 0"
  else record_fail "scope-gitignore: sem .gitignore" "criou arquivo ou exit≠0 (rc=${rc})"; fi
  rm -rf "${d}"

  # (e) $DEST inválido → exit 2 (erro de uso)
  rc=0; bash "${helper}" "/nao/existe/$$" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "scope-gitignore: dest inválido → exit 2"
  else record_fail "scope-gitignore: dest inválido" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo task-manager-hook — .claude/hooks/task-manager-provider-hook.sh deve ler o
# AMBIENTE primeiro (fonte do adapter), com .env como fallback HONESTO. Sinal de campo
# adoção legacy 2026-07 (D2): hook lia só .env → anunciava 'none' com Linear provado via direnv.
# ---------------------------------------------------------------------------
# Modo review-artifact — REGRA 56. O gate que converte "preciso lembrar de revisar" em "o gate recusa
# sem o registro da revisão". Nasceu do dano de 2026-08-06: 8 erros num dia, 6 achados por revisão
# adversarial rodada À MÃO, e a passada só rodou porque o maestro perguntou. A cura que a casa já
# provou não funcionar é "prestar mais atenção"; a que funciona é RESÍDUO MATERIAL.
#
# O caso (a) é o que impede a guarda de virar tortura: durante o trabalho (sem PR) ela CALA. Exigir
# artefato a cada commit intermediário travaria o ciclo, e falso-positivo travante é o modo de falha
# medido desta casa (exit 2 é o único canal → todo disparo interrompe).
# ═══════════════════════════════════════════════════════════════════════════════════════════
# REGRA 57 — kg-seal-check.sh: o veredito do run virou ESCRITA no grafo?
# Bancada inline (sem fixture em disco) porque o caso é um PAR ledger↔grafo, e o par tem de
# ficar visível no próprio teste — fixture separada esconderia justamente a relação sob teste.
# ═══════════════════════════════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════════════════
# post-review-comment.sh — o TRANSPORTE `cli` de `addReviewComment` (forge SDAAL).
# Testável porque tem `--dry-run`: sem ele, um step de CI que posta é código sem cobertura, que
# é exatamente o padrão que manteve o revisor invisível por 15 commits.
# ═══════════════════════════════════════════════════════════════════════════════════════════
run_post_review_comment_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/forge/post-review-comment.sh"
  if [ ! -f "${helper}" ]; then record_fail "forge-post" "helper ausente: ${helper}"; return; fi
  local b out rc
  b="$(mktemp)"; printf '## parecer\n\ncorpo real\n' > "${b}"

  # (a) STICKY, 1ª vez — sem comentário existente → POST
  out="$(bash "${helper}" --pr 42 --body-file "${b}" --sticky '<!-- m -->' --repo o/r --dry-run 2>&1)"
  if printf '%s' "${out}" | grep -q '^POST'; then
    record_pass "forge-post: (a) sticky sem comentário prévio → POST"
  else record_fail "forge-post: (a) primeiro post" "out=${out}"; fi

  # (b) STICKY, 2ª vez — comentário existe → PATCH, NÃO um segundo POST. É a lição medida no PR
  #     #529: o workflow roda em `synchronize`, 2 pushes viravam 2 comentários e 2 e-mails.
  out="$(DRY_EXISTENTE=777 bash "${helper}" --pr 42 --body-file "${b}" --sticky '<!-- m -->' --repo o/r --dry-run 2>&1)"
  if printf '%s' "${out}" | grep -q '^PATCH.*777'; then
    record_pass "forge-post: (b) sticky com comentário prévio → PATCH no mesmo id (editar não gera e-mail novo)"
  else record_fail "forge-post: (b) sticky edita" "out=${out}"; fi

  # (c) SEM --sticky → comportamento da SPEC: sempre cria. O sticky é EXTENSÃO declarada, e o
  #     modo espec-fiel tem de continuar existindo.
  out="$(DRY_EXISTENTE=777 bash "${helper}" --pr 42 --body-file "${b}" --repo o/r --dry-run 2>&1)"
  if printf '%s' "${out}" | grep -q '^POST'; then
    record_pass "forge-post: (c) sem --sticky sempre CRIA (fidelidade à spec: addReviewComment não tem sticky)"
  else record_fail "forge-post: (c) modo spec" "out=${out}"; fi

  # (d) CORPO VAZIO não posta. Comentário em branco é pior que nenhum: parece que houve parecer.
  local empty; empty="$(mktemp)"; : > "${empty}"
  rc=0; out="$(bash "${helper}" --pr 42 --body-file "${empty}" --repo o/r --dry-run 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'corpo VAZIO' \
     && ! printf '%s' "${out}" | grep -qE '^(POST|PATCH)'; then
    record_pass "forge-post: (d) corpo vazio → avisa e NÃO posta, com exit 0 (posting não reprova PR)"
  else record_fail "forge-post: (d) corpo vazio" "rc=${rc} out=${out}"; fi
  rm -f "${empty}"

  # (e) ERRO DE USO sai 2, não 0. A distinção que review-verdict.sh já estabeleceu: uso quebrado
  #     é erro de EXECUÇÃO; falha de rede é veredito. Confundir os dois é fail-open.
  rc=0; bash "${helper}" --pr 42 --repo o/r --dry-run >/dev/null 2>&1 || rc=$?
  local rc2=0; bash "${helper}" --flag-que-nao-existe >/dev/null 2>&1 || rc2=$?
  if [ "${rc}" -eq 2 ] && [ "${rc2}" -eq 2 ]; then
    record_pass "forge-post: (e) erro de USO → exit 2; falha de posting → exit 0 (uso ≠ veredito)"
  else record_fail "forge-post: (e) exit de uso" "sem-body=${rc} flag-broken=${rc2} (esperado 2 e 2)"; fi

  # (f) (MUT) sem a busca pela marca, o sticky vira POST sempre — prova que a busca é
  #     load-bearing e que (b) não passa por acidente.
  local mut; mut="$(mktemp -d)"; cp "${helper}" "${mut}/m.sh"
  sed -i 's|EXISTENTE="${DRY_EXISTENTE:-}"|EXISTENTE=""|' "${mut}/m.sh"
  # `cmp`, NAO `grep`: `EXISTENTE=""` ja existe no arquivo INTACTO (a inicializacao), entao o grep
  # passava mesmo com sed no-op. Elenxo 2026-08-07. Comparar arquivos nao tem como ser vacuo.
  if ! cmp -s "${helper}" "${mut}/m.sh"; then
    out="$(DRY_EXISTENTE=777 bash "${mut}/m.sh" --pr 42 --body-file "${b}" --sticky '<!-- m -->' --repo o/r --dry-run 2>&1)"
    if printf '%s' "${out}" | grep -q '^POST'; then
      record_pass "forge-post: (f) (MUT) sem a busca pela marca o sticky duplica — a busca é load-bearing"
    else record_fail "forge-post: (f) (MUT)" "mutante ainda deu PATCH: out=${out}"; fi
  else record_fail "forge-post: (f) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"; fi
  rm -rf "${mut}"; rm -f "${b}"
}

run_kg_seal_check_selftests() {
  local helper="${SCRIPT_DIR}/kg-seal-check.sh"
  if [ ! -f "${helper}" ]; then record_fail "kg-selo" "helper ausente: ${helper}"; return; fi
  local d out rc

  # Monta repo git com um run declarando ledger + o grafo julgado.
  # $1 = corpo dos nós  ·  $2 = corpo das arestas  ·  $3 = linhas do ledger
  _mk_seal_repo() {
    d="$(mktemp -d)"
    mkdir -p "${d}/docs/evolution/research/run-x" "${d}/docs/onion/graph"
    { printf -- '---\ntitle: "run de teste"\nverified_at: 2026-08-06\n'
      printf 'ledger: docs/evolution/research/run-x/ledger-por-item.tsv\n'
      printf 'source: "docs/onion/graph/alvo.kg.yaml @ abc1234 + host vivo"\n---\n\n# run\n'
    } > "${d}/docs/evolution/research/run-x/SYNTHESIS.md"
    printf '%b' "$3" > "${d}/docs/evolution/research/run-x/ledger-por-item.tsv"
    # `%b\n` e nao `%b`: o `$( )` que monta $1 come a quebra de linha FINAL, e sem ela `edges:`
    # cola no ultimo `label:`. Foi a TERCEIRA ocorrencia da mesma classe nesta bancada (as outras
    # duas: verified_at colando no label, e o label de um no colando no `- id:` do seguinte).
    # Regra: toda saida de `$( )` reinjetada em arquivo precisa da quebra recolocada a mao.
    { printf 'meta:\n  id: alvo\n  schema_version: "1"\n  baseline: 2026-07-01\nnodes:\n'
      printf '%b\n' "$1"
      printf 'edges:\n'
      printf '%b' "$2"
    } > "${d}/docs/onion/graph/alvo.kg.yaml"
    ( cd "${d}" && git init -q -b main . && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm base ) 2>/dev/null
    # $4/$5 = nós/arestas que o CASO pretendia. Vêm do chamador, NÃO da string: os defeitos 1 e 2
    # corrompiam a própria string, então contá-la concordaria com o arquivo e a guarda seria cega.
    _fixture_sane "${d}/docs/onion/graph/alvo.kg.yaml" "$4" "$5"
  }
  # ╭─ GUARDA-DA-BANCADA — a fixture saiu como se PRETENDIA? ────────────────────────────────╮
  # │ TRÊS defeitos idênticos nesta função antes desta guarda existir, todos da mesma classe: │
  # │   1. `verified_at` colou no `label:` (o `$( )` de _va comeu a quebra)                   │
  # │   2. o `label:` de um nó colou no `- id:` do seguinte (concatenar `$(_no a)$(_no b)`)   │
  # │   3. `edges:` colou no último `label:` (o `$( )` que monta NODES_OK)                    │
  # │ Em todos, a bancada gerou YAML MALFORMADO e o caso reprovou com uma mensagem sobre o    │
  # │ SUT — que estava certo. Diagnosticar isso custou 4 rodadas; a 3ª ocorrência é onde      │
  # │ comentar deixa de ser resposta. [[fix-must-become-mechanism]]                           │
  # │ REGRA: toda saída de `$( )` reinjetada em arquivo perde a quebra FINAL — recoloque.     │
  # ╰────────────────────────────────────────────────────────────────────────────────────────╯
  # Compara o que se PEDIU com o que o arquivo TEM. Falha aqui acusa a BANCADA, não o SUT.
  _fixture_sane() {  # $1=arquivo $2=nós esperados $3=arestas esperadas
    local gn ge gl gsec_n gsec_e
    gn="$(grep -c '^  - id: '   "$1" || true)"
    gl="$(grep -c '^    label: ' "$1" || true)"
    ge="$(grep -c '^  - from: ' "$1" || true)"
    gsec_n="$(grep -c '^nodes:$' "$1" || true)"
    gsec_e="$(grep -c '^edges:$' "$1" || true)"
    if [ "${gn}" -ne "$2" ] || [ "${gl}" -ne "$2" ] || [ "${ge}" -ne "$3" ] \
       || [ "${gsec_n}" -ne 1 ] || [ "${gsec_e}" -ne 1 ]; then
      record_fail "kg-selo: BANCADA MALFORMADA" "a fixture nao saiu como pedida — nos=${gn}/$2 labels=${gl}/$2 arestas=${ge}/$3 secao-nodes=${gsec_n}/1 secao-edges=${gsec_e}/1. Classe conhecida: quebra de linha comida por \$( ). O SUT NAO foi exercido."
      return 1
    fi
    return 0
  }

  # $5 = data de verified_at (opcional). NÃO receber a LINHA pronta: `$( )` come a quebra de
  # linha final e o campo colaria no label — 4 casos falharam assim antes de eu ver.
  # `$( )` come a quebra de linha FINAL de cada substituição — concatenar `$(_no a)$(_no b)`
  # cola o label de `a` no `- id:` de `b` e o parser perde o 2º nó. _cat junta com \n explícito.
  _cat() { printf '%s\n' "$@"; }
  _no() {
    printf '  - id: %s\n    node_type: %s\n    plane: DEV\n    impact: 3\n    confidence: %s\n    status: %s\n' "$1" "$2" "$4" "$3"
    [ -n "${5:-}" ] && printf '    verified_at: %s\n' "$5"
    printf '    label: "n"\n'
  }

  # o par CORRETO, reusado como base: 1 CONFIRMED carimbado + 1 DRIFTED reconciliado por aresta
  local NODES_OK EDGES_OK LED_OK
  NODES_OK="$(_cat "$(_no C_CONF claim confirmed 1.0 2026-08-06)" "$(_no D_DRIFT decision confirmed 1.0 2026-08-06)" "$(_no C_ANTIGA claim superseded 0.0 '')")"
  EDGES_OK='  - from: D_DRIFT\n    to: C_ANTIGA\n    edge_type: SUPERSEDES\n'
  LED_OK='# comentario\n# id\tveredito\nC_CONF\tCONFIRMED\t1\nD_DRIFT\tDRIFTED\t2\n'

  # (a) O LADO POSITIVO PRIMEIRO — selo correto CALA. Sem ele, os casos negativos não distinguem
  #     "acusa certo" de "acusa sempre", que é o modo de falha mais barato de escrever.
  _mk_seal_repo "${NODES_OK}" "${EDGES_OK}" "${LED_OK}" 3 1
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "kg-selo: (a) veredito selado (CONFIRMED carimbado + DRIFTED com SUPERSEDES p/ alvo superseded) → CALA"
  else record_fail "kg-selo: (a) lado positivo" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (b) CONFIRMED com carimbo VELHO → HARD. É o caso do #552: mediu e o carimbo não registra.
  _mk_seal_repo "$(_cat "$(_no C_CONF claim confirmed 1.0 2026-07-31)" "$(_no D_DRIFT decision confirmed 1.0 2026-08-06)" "$(_no C_ANTIGA claim superseded 0.0 '')")" "${EDGES_OK}" "${LED_OK}" 3 1
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'SELO-FALTANDO' && printf '%s' "${out}" | grep -q 'C_CONF'; then
    record_pass "kg-selo: (b) CONFIRMED com verified_at de outro dia → HARD SELO-FALTANDO"
  else record_fail "kg-selo: (b) confirmed sem carimbo" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (c) DRIFTED sem reconciliação alguma → HARD. É o caso que sobrou do #555.
  _mk_seal_repo "$(_cat "$(_no C_CONF claim confirmed 1.0 2026-08-06)" "$(_no D_DRIFT decision confirmed 1.0 2026-08-06)")" '' "${LED_OK}" 2 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'DRIFT-NAO-RECONCILIADO'; then
    record_pass "kg-selo: (c) DRIFTED sem SUPERSEDES nem status drifted → HARD"
  else record_fail "kg-selo: (c) drift nao reconciliado" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (d) DRIFTED com `status: drifted` → CALA. A OUTRA forma legal: mediu, ainda não escreveu a
  #     reconciliação. Cobrar só a aresta faria falso-positivo no estado intermediário legítimo.
  _mk_seal_repo "$(_cat "$(_no C_CONF claim confirmed 1.0 2026-08-06)" "$(_no D_DRIFT decision drifted 1.0 2026-08-06)")" '' "${LED_OK}" 2 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "kg-selo: (d) DRIFTED com status drifted → CALA (a aresta NÃO é a única forma legal)"
  else record_fail "kg-selo: (d) drifted como status" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (e) UNVERIFIABLE carimbado com a data do run → HARD. O contrato PROÍBE: não se mediu, não se
  #     carimba. É o único veredito cuja violação é ESCREVER demais, não de menos.
  _mk_seal_repo "$(_no C_UNV claim confirmed 0.5 2026-08-06)" '' '# id\tveredito\nC_UNV\tUNVERIFIABLE\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'UNVER-CARIMBADO'; then
    record_pass "kg-selo: (e) UNVERIFIABLE com verified_at do run → HARD (o contrato proíbe carimbar o que não se mediu)"
  else record_fail "kg-selo: (e) unver carimbado" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (f) UNVERIFIABLE INERTE — data velha (certo) mas confidence 1.0 e nenhuma question → HARD.
  #     statusFactor(unverifiable) == statusFactor(confirmed): sem rebaixar nada, o selo não muda
  #     NADA no radar. Foi o defeito real do #555, medido: atenção 12.00 antes e 12.00 depois.
  _mk_seal_repo "$(_no C_UNV claim unverifiable 1.0 2026-07-31)" '' '# id\tveredito\nC_UNV\tUNVERIFIABLE\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'UNVER-INERTE'; then
    record_pass "kg-selo: (f) UNVERIFIABLE sem rebaixar confidence nem abrir question → HARD (selo mecanicamente inerte)"
  else record_fail "kg-selo: (f) unver inerte" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (g) UNVERIFIABLE com confidence rebaixada → CALA. O lado positivo de (f).
  _mk_seal_repo "$(_no C_UNV claim unverifiable 0.5 2026-07-31)" '' '# id\tveredito\nC_UNV\tUNVERIFIABLE\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "kg-selo: (g) UNVERIFIABLE com confidence rebaixada → CALA"
  else record_fail "kg-selo: (g) unver com efeito" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (h) ISENÇÃO POR ESCOPO nos DOIS MODOS — repo sem nenhuma SYNTHESIS declarando ledger. É o
  #     adotante que nunca rodou /meta:kg-freshness, e é o que autoriza HARD com N=1 no core.
  #     TSV PRIMEIRO de propósito: é o modo que o lint consome, e testar só o humano foi o defeito
  #     que deixou a guarda de vacuidade da REGRA 55 verde com o parser morto.
  d="$(mktemp -d)"; mkdir -p "${d}/docs"
  ( cd "${d}" && git init -q -b main . && printf 'x\n' > docs/a.md && git add -A \
    && git -c user.email=t@t -c user.name=t commit -qm base ) 2>/dev/null
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  local outh; outh="$(bash "${helper}" "${d}" 2>&1)" || true
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'ISENCAO' \
     && printf '%s' "${outh}" | grep -q 'fora de escopo'; then
    record_pass "kg-selo: (h) repo sem run declarando ledger → ISENÇÃO CONTADA nos dois modos (tsv e humano), nunca silêncio"
  else record_fail "kg-selo: (h) isencao por escopo" "rc=${rc} tsv=${out} humano=${outh}"; fi
  rm -rf "${d}"

  # (i) VACUIDADE — ledger existe e ZERO itens julgáveis. Guarda que leu nada não pode dizer que
  #     está tudo certo. Sem isto, um ledger só de comentários passaria verde.
  _mk_seal_repo "${NODES_OK}" "${EDGES_OK}" '# so comentario\n# nenhum dado\n' 3 1
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'VACUIDADE'; then
    record_pass "kg-selo: (i) ledger sem linha de dado → VACUIDADE (ler zero e dizer que está tudo certo é fail-open)"
  else record_fail "kg-selo: (i) vacuidade" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"


  # ── OS SEIS CASOS QUE O ELENXO DE 2026-08-07 EXIGIU ────────────────────────────────────────
  # Cada um corresponde a um falso-positivo ou fail-open MEDIDO na 1a versao desta guarda.

  # (k) A FORMA DO CONTRATO — o no julgado e o ANTIGO: vira `superseded` e RECEBE a aresta
  #     (Passo 4: "Novo no com a verdade atual + SUPERSEDES -> antigo"). A 1a versao so aceitava a
  #     direcao inversa e teria acusado 11 arestas do m2-bridge-logto, que o contrato cita como o
  #     dogfood CERTO. Sem este caso, a regressao volta calada.
  _mk_seal_repo "$(_cat "$(_no D_ANTIGO decision superseded 1.0 2026-08-06)" "$(_no E_NOVO evidence confirmed 1.0 2026-08-06)")" '  - from: E_NOVO\n    to: D_ANTIGO\n    edge_type: SUPERSEDES\n' '# id\tveredito\nD_ANTIGO\tDRIFTED\t1\n' 2 1
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "kg-selo: (k) forma CANÔNICA do contrato (nó julgado vira superseded e RECEBE a aresta) → CALA"
  else record_fail "kg-selo: (k) forma do contrato" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (l) SELO DO DIA SEGUINTE — a letra do Passo 4 e `verified_at: <hoje>`, e "hoje" e o dia em que
  #     o maestro SELA. Com igualdade de data, a regra bloqueava quem obedece o contrato — e
  #     bloquearia os proprios commits que a embarcaram (8b005f6/1681c7c: 08-07 selando run de 08-06).
  _mk_seal_repo "$(_no C_CONF claim confirmed 1.0 2026-08-07)" '' '# id\tveredito\nC_CONF\tCONFIRMED\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "kg-selo: (l) selo do DIA SEGUINTE → CALA (o carimbo é do dia em que se sela, não do run)"
  else record_fail "kg-selo: (l) selo do dia seguinte" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (m) PRECEDENCIA — nó com carimbo MAIS NOVO que o run: um run posterior já o re-verificou.
  #     Sem isto a regra vira CATRACA CONTRA RE-VERIFICAR: com dois ledgers sobre o mesmo grafo,
  #     nenhum estado satisfaz os dois, porque `verified_at` guarda UMA data.
  _mk_seal_repo "$(_no D_DRIFT decision confirmed 1.0 2026-09-01)" '' '# id\tveredito\nD_DRIFT\tDRIFTED\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
    record_pass "kg-selo: (m) nó re-verificado por run POSTERIOR → CALA (a regra não pode barrar re-verificação)"
  else record_fail "kg-selo: (m) precedência" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (n) VOCABULARIO FECHADO — ledger em minuscula (a MESMA caixa que `status:` usa) atravessava os
  #     quatro ramos sem casar nenhum, e a guarda saia VERDE sobre grafo comprovadamente defeituoso
  #     (verified_at de 1999). Fail-open dentro da cura do fail-open.
  _mk_seal_repo "$(_no C_X claim confirmed 1.0 1999-01-01)" '' '# id\tveredito\nC_X\tconfirmed\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'VOCABULARIO-DESCONHECIDO'; then
    record_pass "kg-selo: (n) veredito fora do vocabulário fechado → HARD NOMEADO (minúscula não passa calada)"
  else record_fail "kg-selo: (n) vocabulário" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (o) A RECONCILIACAO TEM DE SER DESTE RUN — aresta de JULHO nao sela veredito de AGOSTO. Medido:
  #     bastava flipar uma linha do ledger para DRIFTED, sem escrever NADA no grafo, e a guarda
  #     passava verde porque a aresta ja existia. Era o modo de falha original pela porta da frente.
  _mk_seal_repo "$(_cat "$(_no D_X decision confirmed 1.0 2026-07-10)" "$(_no C_VELHA claim superseded 0.0 2026-07-10)")" '  - from: D_X\n    to: C_VELHA\n    edge_type: SUPERSEDES\n' '# id\tveredito\nD_X\tDRIFTED\t1\n' 2 1
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'DRIFT-NAO-RECONCILIADO'; then
    record_pass "kg-selo: (o) aresta ANTERIOR ao run não sela veredito novo → HARD"
  else record_fail "kg-selo: (o) amarra ao run" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (p) REFUTED e SOFT, NAO HARD — e a severidade e a tese. A guarda cobre 2 das 6 clausulas do
  #     Passo 4, tem ZERO linhas no ledger real e nunca foi exercitada pelo teste de aceite. Subir
  #     HARD seria poder emprestado da evidencia dos outros ramos.
  _mk_seal_repo "$(_no C_R claim confirmed 1.0 2026-08-06)" '' '# id\tveredito\nC_R\tREFUTED\t1\n' 1 0
  rc=0; out="$(bash "${helper}" "${d}" --format=tsv 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q '^SOFT.*REFUTACAO-NAO-SELADA'; then
    record_pass "kg-selo: (p) REFUTED sai SOFT — severidade proporcional à evidência (2 de 6 cláusulas, 0 casos reais)"
  else record_fail "kg-selo: (p) REFUTED SOFT" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (j) (MUT) sem a comparação de data, o CONFIRMED sem carimbo PASSA — prova que o amarre
  #     data-do-run↔verified_at é load-bearing e não decorativo.
  local mut; mut="$(mktemp -d)"; trap 'rm -rf "'"${mut}"'"' RETURN
  cp "${helper}" "${mut}/m.sh"
  # A mutacao casa a comparacao ATUAL. Quando ela muda (como mudou de `!=` para `>=` no Elenxo
  # de 2026-08-07), o sed para de casar e a guarda-da-guarda abaixo ACUSA em vez de passar mudo.
  sed -i 's/if (va\[id\] == "" || va\[id\] < runday)/if (0)/' "${mut}/m.sh"
  if grep -q 'if (0)' "${mut}/m.sh"; then
    _mk_seal_repo "$(_cat "$(_no C_CONF claim confirmed 1.0 2026-07-31)" "$(_no D_DRIFT decision drifted 1.0 2026-08-06)")" '' "${LED_OK}" 2 0
    rc=0; out="$(bash "${mut}/m.sh" "${d}" --format=tsv 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ]; then
      record_pass "kg-selo: (j) (MUT) sem a comparação de data o carimbo velho PASSA — o amarre é load-bearing"
    else record_fail "kg-selo: (j) (MUT)" "mutante ainda reprovou (rc=${rc}) — a comparação é vacuidade? out=${out}"; fi
    rm -rf "${d}"
  else
    record_fail "kg-selo: (j) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
}

run_review_artifact_selftests() {
  local helper="${SCRIPT_DIR}/review-artifact-check.sh"
  if [ ! -f "${helper}" ]; then record_fail "review-artifact" "helper ausente: ${helper}"; return; fi
  local d out rc

  # 🔒 A INVARIANTE, NOMEADA — a bancada tem de estar hermética ANTES do 1º caso rodar. Sem esta
  # asserção, quebrar o `unset GITHUB_*` do topo se manifesta como 6 `ARTEFATO-AUSENTE` crípticos
  # apontando para o branch REAL do PR, e quem lê perde tempo caçando um defeito de guarda que não
  # existe (foi o que aconteceu no #554). Aqui a falha diz o que é: o ambiente vazou.
  # Não é mutation test — é mais barato e mais DIAGNÓSTICO: nomeia a causa em vez de exibir sintoma.
  local vazou=""
  for _v in GITHUB_HEAD_REF GITHUB_REF_NAME GITHUB_EVENT_NAME GITHUB_BASE_REF; do
    [ -n "$(eval "printf '%s' \"\${${_v}:-}\"")" ] && vazou="${vazou} ${_v}"
  done
  if [ -n "${vazou}" ]; then
    record_fail "bancada-hermetica" "ambiente do runner VAZOU para a bancada:${vazou} — o \`unset GITHUB_*\` do topo não cobriu. Casos que simulam PR passarão a julgar o PR REAL de dentro da sandbox."
  else
    record_pass "bancada-hermetica: nenhum GITHUB_* do runner alcança os fixtures (a hermeticidade é do topo, não de cada caso)"
  fi

  # Sandbox: repo git com branch != default, um commit de código, e origin/HEAD apontando para main.
  _mk_pr_repo() {
    d="$(mktemp -d)"
    ( cd "${d}"
      git init -q -b main .
      mkdir -p .claude/validation docs/evolution/review
      printf 'v1\n' > .claude/validation/alvo.sh
      git add -A && git -c user.email=t@t -c user.name=t commit -qm base
      git branch -q feat/x && git checkout -q feat/x
      printf 'v2 mudou\n' > .claude/validation/alvo.sh
      git add -A && git -c user.email=t@t -c user.name=t commit -qm trabalho
    ) 2>/dev/null
  }
  # O hash que o helper vai calcular, computado do MESMO jeito (sem o dir de review).
  # A FORMA CANÔNICA TEM DE SER A MESMA DOS DOIS LADOS — e este teste provou que importa: sem as
  # flags, o hash do fixture divergia do hash do helper e (c)/(e) reprovavam por CADUCO. É o mesmo
  # que aconteceria a quem tem `diff.noprefix` ou `core.abbrev` no ~/.gitconfig: artefato nasce
  # caduco sem pista do motivo (medido: 3 configs comuns, 3 hashes distintos para o MESMO diff).
  # ⚠️ ESPELHA O RUNNER, inclusive na ESCOLHA DO ALVO. A REGRA 56 passou a decidir por SITUACAO
  # (arvore suja -> indice; limpa -> HEAD), e uma fixture que fixasse `main HEAD` calcularia um hash
  # que o gate NUNCA produz naquele estado — a bancada acusaria ARTEFATO-CADUCO sobre artefato
  # CORRETO. E `bancada-espelha-o-runner`: 26/26 verdes numa bancada que nao copiava as opcoes do
  # runner ja mataram um gate inteiro nesta casa.
  # ⚠️ INVOCACAO INTEIRA EM CADA RAMO, e a razao e um defeito MEDIDO duas vezes no mesmo dia:
  # montar `${target} main` faz o ramo limpo virar `git diff HEAD main` — INVERTIDO —, e hash de diff
  # invertido e outro hash. Aconteceu no `review-artifact-check.sh` (o CI pegou) e aqui, no espelho
  # dele. Variavel que muda de POSICAO SEMANTICA entre ramos inverte um argumento sem ninguem ver.
  _sha_of() { ( cd "$1"
    if git diff --quiet HEAD 2>/dev/null; then
      git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
          main HEAD -- . ":(exclude)docs/evolution/review" | sha256sum | cut -c1-64
    else
      git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
          --cached main -- . ":(exclude)docs/evolution/review" | sha256sum | cut -c1-64
    fi ); }
  _art() {  # $1=dir $2=sha $3=extra-campos(0/1)
    { printf -- '---\n'
      printf 'reviewed_diff_sha256: %s\n' "$2"
      if [ "$3" = "1" ]; then
        printf 'findings_total: 3\nfindings_real: 2\ntokens: 118000\nduration_min: 11\nverdict: corrigido-antes-do-PR\n'
      fi
      printf -- '---\n\n# revisao\n'
    } > "$1/docs/evolution/review/feat-x.md"
    # COMMITA — o gate exige resíduo em HEAD, não arquivo em disco. Antes o teste era `-f` e um
    # artefato untracked passava: o "resíduo auditado por terceiro" podia nunca sair da máquina do
    # autor (achado da revisão adversarial). O commit NÃO muda o hash: o dir de review é excluído.
    ( cd "$1" && git add -A docs/evolution/review \
      && git -c user.email=t@t -c user.name=t commit -qm "review" ) 2>/dev/null
  }
  # PR simulado pelo caminho REAL do CI (evento + ref), não por backdoor de teste.
  # OS DOIS MODOS, e o TSV vem PRIMEIRO de propósito: é o que `check_review_artifact` consome. Testar
  # só o humano foi o defeito que deixou a guarda de vacuidade da REGRA 55 verde com o parser morto
  # (2026-08-06) — e eu o repeti AQUI, no mesmo dia. Quem pegou foi o consumed-mode-check.sh (instrumento, NÃO regra), não uma releitura minha.
  # ⚠️ GITHUB_HEAD_REF É OBRIGATÓRIO AQUI, mesmo parecendo redundante com o branch da sandbox: o
  # helper lê `BRANCH="${GITHUB_HEAD_REF:-}"` ANTES de perguntar ao git. Sem fixá-lo, a bancada
  # HERDA o valor do runner e passa a julgar o branch REAL do PR dentro da sandbox — procurando
  # `feat-<branch-real>.md` num repo que só tem `feat-x.md`. Local passava (var ausente → cai no
  # git), CI reprovava: 6 casos, medido no PR #554. [[bancada-espelha-o-runner]] — mesma lição pela
  # 3ª vez, agora INVERTIDA: não é a bancada que esqueceu uma opção do runner, é o RUNNER que tem
  # uma variável que a bancada não neutralizou.
  _run() { ( cd "$1" && GITHUB_EVENT_NAME=pull_request GITHUB_HEAD_REF=feat/x GITHUB_REF_NAME=99/merge bash "${helper}" "$1" --format=tsv 2>&1 ); }
  _run_humano() { ( cd "$1" && GITHUB_EVENT_NAME=pull_request GITHUB_HEAD_REF=feat/x GITHUB_REF_NAME=99/merge bash "${helper}" "$1" 2>&1 ); }

  # (a) SEM PR (trabalho em curso) → silencioso, exit 0. Sem isto a guarda travaria todo commit.
  _mk_pr_repo
  # 🐤 CANÁRIO DA HERMETICIDADE — invocação NUA de propósito. Este caso testa a AUSÊNCIA de PR,
  # então só passa se o `unset GITHUB_*` do topo tiver funcionado. Blindá-lo com `env -u` aqui
  # seria auto-proteção que MASCARA a falha do mecanismo: passaria em silêncio com o unset
  # quebrado. Nu, ele reprova alto no CI — que é exatamente como o defeito apareceu.
  rc=0; out="$( cd "${d}" && bash "${helper}" "${d}" 2>&1 )" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'fora de escopo'; then
    record_pass "review-artifact: (a) sem PR aberto → CALA (trabalho em curso não é trabalho proposto)"
  else record_fail "review-artifact: (a) sem PR" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (b) COM PR e SEM artefato → HARD. É o caso que aconteceu de verdade (#546/#548).
  _mk_pr_repo
  rc=0; out="$(_run "${d}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'ARTEFATO-AUSENTE'; then
    record_pass "review-artifact: (b) PR sem resíduo de revisão → HARD"
  else record_fail "review-artifact: (b) PR sem artefato" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (c) COM PR e artefato CASANDO → exit 0. O lado positivo; sem ele (b) não distingue
  #     "acusa certo" de "acusa sempre".
  _mk_pr_repo
  _art "${d}" "$(_sha_of "${d}")" 1
  # Exige a EVIDÊNCIA do caminho feliz, não só rc=0: um mutante que forçasse BRANCH=HEAD sairia 0 por
  # FORA DE ESCOPO e esta asserção passaria decorativa — foi assim que o CI ficou cego (achado da
  # revisão adversarial). O modo humano é usado só aqui, para ler a frase; o veredito é o do TSV.
  rc=0; out="$(_run "${d}")" || rc=$?
  local outh; outh="$(_run_humano "${d}")" || true
  if [ "${rc}" -eq 0 ] && printf '%s' "${outh}" | grep -q 'revisão registrada'; then
    record_pass "review-artifact: (c) artefato casando → passa PELO CAMINHO CERTO (não por fora de escopo)"
  else record_fail "review-artifact: (c) artefato válido" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (d) ARTEFATO CADUCO — revisei, e DEPOIS mudei o código. É a fraude honesta mais provável:
  #     rodar a passada cedo e seguir editando. O hash é o que a impede.
  _mk_pr_repo
  _art "${d}" "$(_sha_of "${d}")" 1
  ( cd "${d}" && printf 'v3 mudou DEPOIS da revisao\n' > .claude/validation/alvo.sh \
    && git add -A && git -c user.email=t@t -c user.name=t commit -qm depois ) 2>/dev/null
  rc=0; out="$(_run "${d}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'ARTEFATO-CADUCO'; then
    record_pass "review-artifact: (d) código mudou DEPOIS de revisado → HARD (o hash amarra revisão↔diff)"
  else record_fail "review-artifact: (d) caduco" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (e) CAMPOS DA REAVALIAÇÃO ausentes → HARD. São o dado que o maestro pediu para julgar a cadência
  #     em N=10; sem eles o mecanismo chega ao 10º PR sem poder ser avaliado — a falsificação declarada.
  _mk_pr_repo
  _art "${d}" "$(_sha_of "${d}")" 0
  rc=0; out="$(_run "${d}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'CAMPO-DE-REAVALIACAO-AUSENTE'; then
    record_pass "review-artifact: (e) sem os campos de N=10 → HARD (cadência não julgável = mecanismo cego)"
  else record_fail "review-artifact: (e) campos de reavaliação" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (f) ISENÇÃO ovo-galinha: PR que edita o próprio revisor. CONTADA, nunca silenciosa.
  # A isenção ficou ESTRITA: só vale quando o diff é EXCLUSIVAMENTE o workflow. Antes bastava TOCAR
  # o arquivo — medido, um PR de 52 arquivos com uma linha nele saía integralmente isento. Por isso
  # esta sandbox ramifica de main SEM outra mudança.
  d="$(mktemp -d)"
  ( cd "${d}"
    git init -q -b main .
    mkdir -p .github/workflows docs/evolution/review
    printf 'v1\n' > a.sh
    git add -A && git -c user.email=t@t -c user.name=t commit -qm base
    git branch -q feat/x && git checkout -q feat/x
    printf 'on: pull_request\n' > .github/workflows/onion-review.yml
    git add -A && git -c user.email=t@t -c user.name=t commit -qm revisor ) 2>/dev/null
  rc=0; out="$(_run_humano "${d}")" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'ovo-galinha'; then
    record_pass "review-artifact: (f) PR que edita o próprio revisor → isento, e a isenção é CONTADA"
  else record_fail "review-artifact: (f) isenção ovo-galinha" "rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (h) A FORMA DO CI — HEAD DESTACADO. É o caso que estava CEGO e que nenhum fixture reproduzia:
  #     `onion-validate.yml` faz checkout com `ref: head.sha`, então `git rev-parse --abbrev-ref HEAD`
  #     devolve "HEAD" e a guarda saía por `detached-head` ANTES do ramo escrito PARA o CI. Resultado
  #     medido em 2026-08-06: a REGRA 56 nunca executava no único caminho que não depende do autor
  #     lembrar — o gate contra o gatilho social dependia do gatilho social. Sem esta asserção, a
  #     correção pode ser desfeita sem ninguém ver.
  _mk_pr_repo
  ( cd "${d}" && git checkout -q --detach ) 2>/dev/null
  rc=0
  out="$( cd "${d}" && GITHUB_EVENT_NAME=pull_request GITHUB_HEAD_REF=feat/x GITHUB_REF_NAME=99/merge \
          bash "${helper}" "${d}" --format=tsv 2>&1 )" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'ARTEFATO-AUSENTE'; then
    record_pass "review-artifact: (h) HEAD destacado + GITHUB_HEAD_REF (a forma do CI) → JULGA (não sai por fora de escopo)"
  else record_fail "review-artifact: (h) forma do CI" "a regra não roda no CI: rc=${rc} out=${out}"; fi
  rm -rf "${d}"

  # (i) ISENÇÃO VISÍVEL NO MODO TSV — o modo que o lint consome. Antes, `_skip` só alimentava uma
  #     variável impressa no modo humano: em TSV toda isenção era ZERO BYTE, e o wire-in trata vazio
  #     como "nada a relatar". Cinco classes de silêncio foram medidas assim. É a mesma família de
  #     defeito que este ciclo cura, cometida DENTRO da cura.
  _mk_pr_repo
  # 🐤 segundo canário, no modo TSV (o que o lint consome): nu pela mesma razão que (a).
  rc=0; out="$( cd "${d}" && bash "${helper}" "${d}" --format=tsv 2>&1 )" || rc=$?
  if printf '%s' "${out}" | grep -q 'ISENCAO'; then
    record_pass "review-artifact: (i) isenção aparece no modo TSV (o que o lint consome), não só no humano"
  else record_fail "review-artifact: (i) isenção em TSV" "isenção invisível no modo consumido: out=${out}"; fi
  rm -rf "${d}"

  # (g) (MUT) sem a comparação de hash, o CADUCO passa — prova que o amarre é load-bearing e não
  #     decoração. Sem esta mutação, (d) poderia estar passando por outro motivo.
  local mut; mut="$(mktemp -d)"; cp "${helper}" "${mut}/m.sh"
  sed -i 's/if \[ "${DECL}" != "${DIFF_SHA}" \]; then/if false; then/' "${mut}/m.sh"
  if grep -q 'if false; then' "${mut}/m.sh"; then
    _mk_pr_repo
    _art "${d}" "$(_sha_of "${d}")" 1
    ( cd "${d}" && printf 'v3\n' > .claude/validation/alvo.sh && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm depois ) 2>/dev/null
    rc=0
    ( cd "${d}" && GITHUB_EVENT_NAME=pull_request GITHUB_HEAD_REF=feat/x GITHUB_REF_NAME=99/merge \
        bash "${mut}/m.sh" "${d}" >/dev/null 2>&1 ) || rc=$?
    if [ "${rc}" -eq 0 ]; then
      record_pass "review-artifact: (g) (MUT) sem a comparação de hash o caduco PASSA — o amarre é load-bearing"
    else record_fail "review-artifact: (g) (MUT)" "mutante ainda reprovou (rc=${rc}) — (d) passa por outro motivo"; fi
    rm -rf "${d}"
  else
    record_fail "review-artifact: (g) (MUT)" "a mutação NÃO foi aplicada — o teste não prova nada"
  fi
  rm -rf "${mut}"

  # (j)(k) A SITUACAO DECIDE O ALVO DO DIFF — e este par nasceu de um dano MEDIDO, nao de teoria:
  # 23 commits de UMA sessao carregam `--no-verify DECLARADO`. Vinte e tres vezes o autor escreveu
  # o residuo, calculou o hash prospectivo e MESMO ASSIM teve de contornar o hook, porque a regra
  # comparava sempre `BASE..HEAD` (so COMMITS) e no pre-commit o HEAD e o commit ANTERIOR — o
  # conteudo em stage nao entrava na conta e o hash do autor NAO PODIA casar.
  # GUARDA QUE PUNE QUEM OBEDECE ENSINA A IGNORAR A GUARDA. E o custo nao e o bypass: e o bypass
  # virar idioma e um dia esconder uma falta de verdade.
  # (j) arvore SUJA (pre-commit) -> alvo e o INDICE, e obedecer passa.
  # (k) arvore LIMPA (pos-commit / CI, que e quem AUDITA) -> alvo segue sendo HEAD, inalterado.
  local rw
  rw="$(mktemp -d)"
  if git -C "${REPO_ROOT}" archive HEAD 2>/dev/null | tar -x -C "${rw}" 2>/dev/null; then
    ( cd "${rw}" && git init -q . && git add -A \
      && git -c user.email=t@t -c user.name=t commit -qm base && git branch -qm main ) >/dev/null 2>&1
    local h_prosp h_calc target
    ( cd "${rw}" && git checkout -q -b feat/t && printf 'x\n' > zz.txt && git add -A ) >/dev/null 2>&1
    # o hash que o AUTOR calcula, obedecendo (o indice)
    h_prosp="$(cd "${rw}" && git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
                 --cached main -- . ':(exclude)docs/evolution/review' | sha256sum | cut -c1-64)"
    # o que a REGRA 56 calcula na MESMA situacao (arvore suja)
    if ( cd "${rw}" && git diff --quiet HEAD 2>/dev/null ); then target="HEAD"; else target="--cached"; fi
    # invocacao INTEIRA por ramo, pelo mesmo motivo dos outros dois sitios: `${target} main` faria
    # o ramo limpo virar `HEAD main`, invertido. Aqui e LATENTE (a asercao exige --cached), e
    # armadilha latente e a que sobrevive ao refactor.
    if [ "${target}" = "--cached" ]; then
      h_calc="$(cd "${rw}" && git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
                  --cached main -- . ':(exclude)docs/evolution/review' | sha256sum | cut -c1-64)"
    else
      h_calc="$(cd "${rw}" && git -c core.abbrev=40 -c diff.noprefix=false diff --no-ext-diff --no-color \
                  main HEAD -- . ':(exclude)docs/evolution/review' | sha256sum | cut -c1-64)"
    fi
    if [ "${target}" = "--cached" ] && [ "${h_prosp}" = "${h_calc}" ]; then
      record_pass "review-artifact: (j) arvore SUJA -> alvo e o INDICE; o hash de quem OBEDECE casa"
    else record_fail "review-artifact: (j) pre-commit" "target=${target}; prospectivo=${h_prosp:0:12} calculado=${h_calc:0:12} — a regra punia quem obedece"; fi
    # (k) o par: depois de commitar, arvore limpa -> HEAD, e o CI segue vendo o mesmo de sempre
    ( cd "${rw}" && git -c user.email=t@t -c user.name=t commit -qm c1 ) >/dev/null 2>&1
    if ( cd "${rw}" && git diff --quiet HEAD 2>/dev/null ); then
      record_pass "review-artifact: (k) arvore LIMPA -> alvo volta a ser HEAD (o CI, que audita, nao mudou)"
    else record_fail "review-artifact: (k) pos-commit" "arvore ficou suja depois do commit — o ramo de CI mediria o alvo errado"; fi
    # (l) A EXISTENCIA DO ARTEFATO SEGUE A MESMA REGRA DO HASH. Sem isto havia IMPASSE: `HEAD:${ART}`
    #     no pre-commit e o commit ANTERIOR, entao o residuo recem-STAGED "nao existia" e o hook
    #     bloqueava o proprio commit que o adicionava. Meia-cura em guarda e como meia-renomeacao em
    #     codigo: o lado que sobra e o que quebra.
    ( cd "${rw}" && printf 'x2\n' > zz2.txt && mkdir -p docs/evolution/review \
      && printf -- '---\nbranch: feat/t\n---\ncorpo\n' > docs/evolution/review/feat-t.md && git add -A ) >/dev/null 2>&1
    local _ref
    if ( cd "${rw}" && git diff --quiet HEAD 2>/dev/null ); then _ref="HEAD:docs/evolution/review/feat-t.md"; else _ref=":docs/evolution/review/feat-t.md"; fi
    if ( cd "${rw}" && git cat-file -e "${_ref}" 2>/dev/null ); then
      record_pass "review-artifact: (l) residuo recem-STAGED e VISTO no pre-commit (sem impasse do proprio commit)"
    else record_fail "review-artifact: (l) impasse" "o artefato em stage nao foi visto (ref=${_ref}) — o hook bloquearia o commit que o adiciona"; fi
  else record_skip "review-artifact: (j)(k) sandbox git nao montou"; fi
  rm -rf "${rw}"

}

# Modo empty-result-guard — .claude/hooks/bash-empty-result-guard.sh é a guarda anti-fail-open do
# SHELL: generaliza a guarda de legibilidade do kg-radar.sh:162 ("0 nós → aborta SEM OPINAR") para o
# caso em que um comando devolve VAZIO/ZERO por motivo OPERACIONAL (sem acesso, path errado, pipe
# comendo o exit code) e isso é lido como FATO sobre o mundo. Origem: 3 falhas medidas na mesma sessão
# (2026-08-02). O teste (d) é o que importa mais: uma guarda barulhenta vira fadiga e é ignorada.
run_empty_result_guard_selftests() {
  local hook="${REPO_ROOT}/.claude/hooks/bash-empty-result-guard.sh"
  if [ ! -f "${hook}" ]; then record_fail "empty-result-guard" "hook ausente: ${hook}"; return; fi
  local out rc
  _erg() {  # $1=comando  $2=stdout simulado  → imprime stderr, devolve exit
    printf '{"tool_input":{"command":%s},"tool_response":{"stdout":%s}}' "$1" "$2" \
      | bash "${hook}" 2>&1
  }

  # (a) REAGE: descoberta nua com saída vazia (o falso "o workflow não sobreviveu")
  out="$(_erg '"ls -d /home/x/projects/y/subagents"' '""' || true)"
  if printf '%s' "${out}" | grep -q 'VAZIO'; then
    record_pass "empty-result-guard: (a) descoberta vazia → avisa que vazio != ausência"
  else record_fail "empty-result-guard: (a)" "não reagiu a ls com saída vazia: ${out}"; fi

  # (b) REAGE: \$? lido depois de pipe (li o exit do tail, não o do script)
  # NB: $? vai LITERAL no JSON (as aspas simples do shell protegem). Um \$ aqui seria escape JSON
  #     INVALIDO — o jq recusaria o parse, o hook sairia cedo e o teste passaria vazio: falso-verde.
  out="$(_erg '"tail -4 /tmp/x | sed s/a/b/; echo EXIT=$?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (b) \$? pós-pipe → avisa que o exit é do último elemento"
  else record_fail "empty-result-guard: (b)" "não reagiu a \$? após pipe: ${out}"; fi

  # (b2) REAGE: `pgrep -f`/`pkill -f` que casa a SI MESMO. Três danos DIFERENTES numa sessão
  #      (2026-08-10) — é o que prova classe e não descuido. O caso do `until` é o pior porque não
  #      ERRA: ele espera para sempre, e esperar parece trabalhar (shell preso 1h06 enquanto o
  #      comando aguardado já tinha terminado).
  out="$(_erg '"until ! pgrep -f (git commit -F) >/dev/null; do sleep 30; done"' '""' || true)"
  if printf '%s' "${out}" | grep -q 'PGREP-QUE-SE-ENCONTRA'; then
    record_pass "empty-result-guard: (b2) \`until ! pgrep -f\` → avisa que o laço espera por SI MESMO"
  else record_fail "empty-result-guard: (b2)" "não reagiu ao pgrep -f auto-casante: ${out}"; fi

  # (b2b) COBERTURA — a 2ª versão exigia que o cluster com `f` fosse o PRIMEIRO token, e escapavam
  #       `pkill -9 -f` (a forma mais comum do mundo real), `-a -f`, `-u root -f` e a longa `--full`.
  #       Promessa maior que cobertura é `declarado != verificado` dentro da própria guarda.
  local _cov_fail=0 _cvcmd
  for _cvcmd in '"pkill -9 -f (lint-selftest)"' \
                '"until ! pgrep --full (git commit -F); do sleep 30; done"' \
                '"until ! pgrep -a -f (git commit -F); do sleep 30; done"' \
                '"pgrep -u root -f (deploy.sh)"'; do
    out="$(_erg "${_cvcmd}" '""' || true)"
    printf '%s' "${out}" | grep -q 'PGREP-QUE-SE-ENCONTRA' || _cov_fail=$((_cov_fail + 1))
  done
  if [ "${_cov_fail}" -eq 0 ]; then
    record_pass "empty-result-guard: (b2b) cobre \`-9 -f\`, \`-a -f\`, \`-u root -f\` e \`--full\` — não só o dialeto"
  else record_fail "empty-result-guard: (b2b)" "${_cov_fail}/4 formas de invocação escaparam da regra"; fi

  # (b2c) ISENÇÃO POR INVOCAÇÃO, nunca pelo comando inteiro. As três formas abaixo tinham `[`, `$$`
  #       ou `-x` presentes por OUTRO motivo, e na 2ª versão isso desarmava a regra sobre a invocação
  #       CULPADA. Fail-open por escopo largo — a mesma classe que eu já abri duas vezes nesta sessão
  #       curando outra coisa.
  local _esc_fail=0
  for _cvcmd in '"pgrep -f alvo > /tmp/x[1].txt"' \
                '"LOG=/tmp/d.$$X; until ! pgrep -f (alvo); do sleep 5; done"' \
                '"pkill -x nginx; until ! pgrep -f (deploy.sh); do sleep 5; done"'; do
    out="$(_erg "${_cvcmd}" '""' || true)"
    printf '%s' "${out}" | grep -q 'PGREP-QUE-SE-ENCONTRA' || _esc_fail=$((_esc_fail + 1))
  done
  if [ "${_esc_fail}" -eq 0 ]; then
    record_pass "empty-result-guard: (b2c) isenção vale por INVOCAÇÃO — \`[\` em redirect, \`\$\$\` e \`-x\` irmão não desarmam"
  else record_fail "empty-result-guard: (b2c)" "${_esc_fail}/3 isenções ainda valem para o comando inteiro (fail-open)"; fi

  # (b2d) COLCHETE FURADO — o achado mais caro da passada adversarial: no idioma lança-e-espera a
  #       forma NUA do padrão está na linha por causa do LANÇAMENTO, o colchete não protege, o laço
  #       trava — e a guarda ficava MUDA porque via o `[`. Fail-open COM SELO é pior que guarda
  #       ausente: ela certifica como curado o que trava para sempre.
  # ⚠️ SEM PARÊNTESES no padrão. A 1ª versão deste caso escrevia `([m]arcador-x.sh)` para escapar do
  #    JSON — e o parêntese ENTRA no argumento, então a forma nua vira `(marcador-x.sh)`, que não
  #    ocorre no lançamento. O caso reprovava sobre uma regra CORRETA: o artifício de escape do teste
  #    virou parte do dado medido. É a mesma família de `bancada-espelha-o-runner`.
  out="$(_erg '"bash marcador-x.sh & until ! pgrep -f [m]arcador-x.sh; do sleep 5; done"' '""' || true)"
  if printf '%s' "${out}" | grep -q 'COLCHETE-FURADO'; then
    record_pass "empty-result-guard: (b2d) colchete com a forma NUA co-ocorrendo → acusa FURADO, não certifica"
  else record_fail "empty-result-guard: (b2d)" "certificou como curado um colchete que não protege: ${out}"; fi

  # (b2e) RECONHECE A CURA FORTE. `-A`/`--ignore-ancestors` (procps-ng >=4.0) exclui os ancestrais do
  #       próprio shell — é a cura de VERDADE. Na 2ª versão ela passava por ACIDENTE, caindo no buraco
  #       de cobertura; guarda que cala por acidente volta a acusar assim que o buraco é tapado.
  out="$(_erg '"until ! pgrep -A -f (git commit -F); do sleep 30; done"' '""' || true)"
  if printf '%s' "${out}" | grep -qE 'PGREP-QUE-SE-ENCONTRA|COLCHETE-FURADO'; then
    record_fail "empty-result-guard: (b2e)" "acusou \`pgrep -A -f\`, que é a cura recomendada: ${out}"
  else record_pass "empty-result-guard: (b2e) cala em \`pgrep -A -f\` — reconhece a cura, não tropeça nela"; fi

  # (b2f) MUTATION — a passada adversarial provou que remover a 3ª cláusula da 2ª versão mantinha a
  #       bancada 100% VERDE: a cláusula que produzia os fail-opens não era medida em direção nenhuma.
  #       Sem este par, os casos acima poderiam virar passe-vácuo de novo. Medição de mão não é
  #       mecanismo — o mesmo comentário já está no caso (p) deste arquivo, pago em 2026-08-09.
  local _mut_dir _mut_hook _mut_rc
  _mut_dir="$(mktemp -d)"
  sed 's/^    case "${_c}" in pgrep\\ \*|pkill\\ \*|pgrep|pkill) ;; \*) continue ;; esac$/    :/' \
      "${hook}" > "${_mut_dir}/h.sh"
  if cmp -s "${hook}" "${_mut_dir}/h.sh"; then
    record_fail "empty-result-guard: (b2f)" "GUARDA-DA-GUARDA: a mutação da ÂNCORA não foi aplicada (arquivos idênticos) — o sed virou no-op"
  else
    # ⚠️ A SONDA IMPORTA MAIS QUE A MUTAÇÃO. A 1ª sonda que escolhi foi `grep -rn "pgrep -f" ...` — e
    #    ela calava nos DOIS lados, porque ali quem silencia é o regex de modo-full (`-f"` não é
    #    token de opção), não a âncora. Eu teria concluído "cláusula indetectável" sobre uma cláusula
    #    sadia. `echo pgrep -f alvo` isola a âncora: é MENÇÃO com espaçamento de invocação.
    _mut_rc=0
    printf '{"tool_input":{"command":"echo pgrep -f alvo"},"tool_response":{"stdout":""}}' \
      | bash "${_mut_dir}/h.sh" >/dev/null 2>"${_mut_dir}/err" || _mut_rc=$?
    if grep -q 'PGREP-QUE-SE-ENCONTRA' "${_mut_dir}/err" 2>/dev/null; then
      record_pass "empty-result-guard: (b2f) MUTATION — sem a âncora, a MENÇÃO volta a ser acusada (a âncora é load-bearing)"
    else record_fail "empty-result-guard: (b2f)" "mutar a âncora NÃO mudou o comportamento — a cláusula é indetectável pela bancada"; fi
  fi
  rm -rf "${_mut_dir}"

  # (b4) BRANCH EM pt-BR na CRIAÇÃO. `code-standards.md:39` exige branch em inglês, e o repo mostra
  #      que é sistêmico: `fix/fixture-nao-depende-do-vivo`, `docs/waha-rotacao-e-hash`,
  #      `docs/fios-abertos`, `fix/catraca-duas-portas`, `fix/selo-m8-vereditos`. A guarda dispara na
  #      CRIAÇÃO porque é o único instante em que renomear é grátis — no commit a branch já nomeia o
  #      PR e o resíduo da REGRA 56, e acusar ali seria punir quem já não pode corrigir barato (a
  #      lição da REGRA 56, que ensinou 23 bypasses).
  #
  # ⚠️ ESTA REGRA IA EMBARCAR VERDE-VAZIA. Ela reusa `lib/pt-br-words.txt` da REGRA 60 — e a lista é
  #    afinada para IDENTIFICADOR DE SHELL: `nao`, `depende`, `vivo`, `rotacao`, `fios`, `abertos`,
  #    `selo`, `separador`, `registro` estavam TODAS ausentes (11 de 13 medidas). A regra não
  #    disparava em NENHUM dos nomes reais que motivaram sua criação. Quem pegou foi a matriz, antes
  #    do embarque; sem ela eu teria entregado uma guarda que passa sempre e guarda nada — a mesma
  #    falha que `.claude/rules/kg-grammar.md` documenta com o grep de `type: REFUTES`.
  local _br_fail=0 _br_case _br_cmd _br_want
  for _br_case in 'git checkout -b fix/fixture-nao-depende-do-vivo|ACUSA' \
                  'git switch -c fix/catraca-duas-portas|ACUSA' \
                  'git branch -m docs/fios-abertos|ACUSA' \
                  'git checkout -b fix/branch-name-language-guard|silencio' \
                  'git checkout -b fix/inventory-drift|silencio' \
                  'git checkout main|silencio' \
                  'echo git checkout -b fix/teste-de-vivo|silencio'; do
    _br_cmd="${_br_case%%|*}"; _br_want="${_br_case##*|}"
    out="$(_erg "\"${_br_cmd}\"" '""' || true)"
    if printf '%s' "${out}" | grep -q 'BRANCH-EM-PT-BR'; then
      [ "${_br_want}" = "ACUSA" ] || _br_fail=$((_br_fail + 1))
    else
      [ "${_br_want}" = "silencio" ] || _br_fail=$((_br_fail + 1))
    fi
  done
  if [ "${_br_fail}" -eq 0 ]; then
    record_pass "empty-result-guard: (b5) branch pt-BR acusada na CRIAÇÃO; inglês, \`checkout\` sem -b e menção calam"
  else record_fail "empty-result-guard: (b5)" "${_br_fail}/7 casos de nome de branch divergiram do esperado"; fi

  # (b4b) MUTATION — a lista de palavras é load-bearing. Sem ela a regra vira verde-vazia, que foi
  #       EXATAMENTE o estado em que ela quase embarcou. Este par existe para que a próxima pessoa que
  #       mexer na lista descubra pela bancada, não por um revisor meses depois.
  # ⚠️ SEGUNDA VERSÃO DESTE CASO. A primeira era PASSE-VÁCUO, e o modo é instrutivo: o `sed` produzia
  #    `/tmp/../<dir>/vazia.txt`, que resolve para `/<dir>/vazia.txt` — arquivo INEXISTENTE. A regra
  #    calava pelo `[ -f "${_wl}" ]`, NÃO por lista vazia. O caso passava pelo motivo errado.
  #    A passada adversarial provou a consequência: HARDCODAR a lista dentro da regra mantinha a
  #    bancada inteira em 786/0. O caso afirmava "a lista é load-bearing" sobre uma regra que podia
  #    ignorá-la por completo.
  #
  #    A cura tem DUAS pernas, e é a positiva que fecha o buraco:
  #      · NEGATIVA  — lista vazia (existente!) deve CALAR;
  #      · POSITIVA  — lista com UMA palavra FORJADA (`zzmarcador`) deve ACUSAR um nome que a lista
  #                    real NÃO pega. Uma regra com lista hardcoded reprova esta perna por construção,
  #                    porque não tem como conhecer a palavra inventada.
  #    Sem a positiva, "não acusou" é indistinguível de "não leu o arquivo".
  local _wl_dir _wl_line
  _wl_dir="$(mktemp -d)"
  : > "${_wl_dir}/vazia.txt"
  printf 'zzmarcador\n' > "${_wl_dir}/forjada.txt"
  # aponta o `_wl=` da hook para um caminho ABSOLUTO controlado (a aritmética relativa era o defeito)
  _wl_line="$(grep -cE '^[[:space:]]*_wl=' "${hook}" || true)"
  if [ "${_wl_line}" != "1" ]; then
    record_fail "empty-result-guard: (b5b)" "GUARDA-DA-GUARDA: esperava exatamente 1 linha \`_wl=\` na hook, achei ${_wl_line} — a mutação não pode ser aplicada com confiança"
  else
    _erg_wl() {  # $1=arquivo-de-lista  $2=comando  → imprime stderr da hook mutada
      sed -E "s#^([[:space:]]*)_wl=.*#\\1_wl=\"$1\"#" "${hook}" > "${_wl_dir}/h.sh"
      printf '{"tool_input":{"command":"%s"},"tool_response":{"stdout":""}}' "$2" \
        | bash "${_wl_dir}/h.sh" 2>&1 >/dev/null
    }
    if cmp -s "${hook}" "${_wl_dir}/h.sh" 2>/dev/null; then
      record_fail "empty-result-guard: (b5b)" "GUARDA-DA-GUARDA: a mutação da LISTA não foi aplicada — o sed virou no-op"
    else
      local _neg _pos _iso
      _neg="$(_erg_wl "${_wl_dir}/vazia.txt"   'git checkout -b fix/catraca-duas-portas' || true)"
      _pos="$(_erg_wl "${_wl_dir}/forjada.txt" 'git checkout -b feat/zzmarcador-probe'   || true)"
      _iso="$(_erg_wl "${_wl_dir}/forjada.txt" 'git checkout -b fix/catraca-duas-portas' || true)"
      if printf '%s' "${_neg}" | grep -q 'BRANCH-EM-PT-BR'; then
        record_fail "empty-result-guard: (b5b)" "lista VAZIA e a regra ainda acusou — ela não depende do arquivo"
      elif ! printf '%s' "${_pos}" | grep -q 'BRANCH-EM-PT-BR'; then
        record_fail "empty-result-guard: (b5b)" "lista FORJADA com \`zzmarcador\` e a regra NÃO acusou — ela não LÊ o arquivo (uma lista hardcoded produz exatamente isto)"
      elif printf '%s' "${_iso}" | grep -q 'BRANCH-EM-PT-BR'; then
        record_fail "empty-result-guard: (b5b)" "com a lista forjada a regra ainda pegou palavra da lista REAL — há vocabulário embutido além do arquivo"
      else
        record_pass "empty-result-guard: (b5b) MUTATION — vazia CALA · forjada ACUSA · e SÓ o que está no arquivo conta (lista hardcoded reprova por construção)"
      fi
    fi
  fi
  rm -rf "${_wl_dir}"

  # (b5c) INVARIANTE DE TRAP — a guarda de abort da bancada ficou MUDA a vida inteira porque um
  #       segundo `trap ... EXIT` a substituiu (bash guarda UM handler por sinal). Re-armar sem
  #       asserção deixa o próximo `trap` — ou um helper `source`ado — desarmá-la de novo em silêncio.
  #       Esta checagem roda EM RUNTIME e pega inclusive clobber vindo de arquivo externo.
  if trap -p EXIT 2>/dev/null | grep -q '_bench_on_exit'; then
    record_pass "empty-result-guard: (b5c) o handler de EXIT ainda é o combinado — a guarda de abort NÃO está muda"
  else record_fail "empty-result-guard: (b5c)" "INVARIANTE VIOLADA: o handler de EXIT foi substituído — a guarda de abort está MUDA e um abort passaria como '666 verdes'"; fi

  # (b3) CALA na CURA — o idioma do colchete. Sem este caso a regra poderia ser "acusa sempre que
  #      vir pgrep", que empurraria quem obedece para o bypass (a lição da REGRA 56, que puniu
  #      quem obedecia 23 vezes). A guarda tem de reconhecer a forma correta, não só a errada.
  out="$(_erg '"pgrep -f ([l]int-selftest)"' '"123"' || true)"
  if printf '%s' "${out}" | grep -q 'PGREP-QUE-SE-ENCONTRA'; then
    record_fail "empty-result-guard: (b3)" "acusou o idioma do COLCHETE, que é a cura: ${out}"
  else record_pass "empty-result-guard: (b3) cala no \`pgrep -f '[l]…'\` — reconhece a forma correta"; fi

  # (b4c) OS QUATRO FAIL-OPENS DA PRIMEIRA VERSÃO DESTA REGRA, achados na passada adversarial contra
  #      ela mesma, no PR que a introduziu. A raiz era UMA: as isenções valiam para o COMANDO
  #      INTEIRO, então bastava um colchete num redirect, um `$$` presente por outro motivo, ou um
  #      `-x` numa invocação IRMÃ para desarmar a regra sobre a invocação culpada.
  #      ⚠️ É a TERCEIRA vez nesta sessão que uma cura de fail-open ABRE fail-open. Por isso os
  #      quatro ficam aqui: sem eles, a segunda versão seria tão não-provada quanto a primeira, e
  #      a próxima refatoração reabriria os furos sem ninguém notar.
  local _b4_fail=0 _b4_desc
  for _b4_desc in \
    'pgrep -f meu-alvo > /tmp/saida[1].txt|colchete em REDIRECT, nao no padrao' \
    'pgrep -f meu-alvo && echo fim-$$|$$ presente por outro motivo' \
    'pkill -x sleep ; pgrep -f meu-alvo|-x numa invocacao IRMA' \
    'pgrep -f a[b]c ; pkill -f meu-alvo-real|colchete no 1o, culpado no 2o'; do
    out="$(_erg "\"${_b4_desc%%|*}\"" '"x"' || true)"
    if ! printf '%s' "${out}" | grep -q 'PGREP-QUE-SE-ENCONTRA'; then
      _b4_fail=1
      record_fail "empty-result-guard: (b4c)" "FAIL-OPEN reaberto — ${_b4_desc##*|}: ${out}"
    fi
  done
  [ "${_b4_fail}" -eq 0 ] && record_pass "empty-result-guard: (b4c) os 4 fail-opens da 1a versao seguem fechados (isencao e POR INVOCACAO, nao por comando)"

  # (c) REAGE: glob sob sudo + erro engolido virando número (os 7 .env.bak que viraram 0)
  out="$(_erg '"sudo -n ls -1 /home/onion/.env.bak-* 2>/dev/null | wc -l"' '"0"' || true)"
  if printf '%s' "${out}" | grep -q 'GLOB-SOB-SUDO' && printf '%s' "${out}" | grep -q 'ERRO-ENGOLIDO'; then
    record_pass "empty-result-guard: (c) glob sob sudo + erro engolido em contagem → avisa os dois"
  else record_fail "empty-result-guard: (c)" "não reagiu ao glob/erro engolido: ${out}"; fi

  # (d) NÃO REAGE (anti-ruído — o teste que impede a guarda de virar fadiga de alerta)
  local noisy=0 c
  for c in '"git status --short"' '"grep -q foo /etc/hostname && echo sim"' \
           '"ls /tmp/x 2>/dev/null || echo nenhum"' '"set -o pipefail; a | tail -1; echo \$?"'; do
    out="$(_erg "${c}" '"saida"' || true)"
    if printf '%s' "${out}" | grep -q 'pode MENTIR'; then noisy=1; fi
  done
  if [ "${noisy}" -eq 0 ]; then
    record_pass "empty-result-guard: (d) comando saudável / com ramo-vazio tratado → SILENCIOSO"
  else record_fail "empty-result-guard: (d)" "falso-positivo: guarda barulhenta vira fadiga e é ignorada"; fi

  # (j) e (k) sao PAR — o 5o detector (MERGE-SEM-FONTE-LIDA), nascido de dano medido em 2026-08-06:
  # mergeei os PRs #546 e #548 anunciando "verde", sem revisao semantica nenhuma. O `onion-review`
  # sai VERDE POR DESENHO quando o revisor falha (soft-pass deliberado), logo `gh pr checks`
  # mostrando `pass` NAO diz que houve revisao — e essa e a superficie que o fluxo de merge consulta.
  # (j) prova que dispara nos dois verbos que importam; (k) prova que NAO virou ruido nos verbos
  # vizinhos de LEITURA (`view`/`checks`/`list`), que sao justamente o que a guarda esta mandando ler.
  # Sem (k), a guarda ensinaria a ignorar a si mesma no momento exato em que quer ser obedecida.
  local mg_ok=1 v
  for v in '"gh pr merge 551 --squash --delete-branch"' '"gh pr create --base main --head x"'; do
    out="$(_erg "${v}" '"ok"' || true)"
    printf '%s' "${out}" | grep -qE 'MERGE-SEM-FONTE-LIDA|PR-SEM-PASSADA-ADVERSARIAL' || mg_ok=0
  done
  if [ "${mg_ok}" -eq 1 ]; then
    record_pass "empty-result-guard: (j) gh pr merge/create → aponta a FONTE do veredito (o verde do revisor e soft-pass)"
  else record_fail "empty-result-guard: (j) merge sem fonte" "nao reagiu a gh pr merge/create"; fi

  # A classe REAL de falso-positivo não é `gh pr checks` (que não CONTÉM a substring — a asserção
  # antiga era tautológica). É MENÇÃO ao comando dentro de argumento/string: foi ela que fez o
  # detector disparar 3× nos comandos de LEITURA da revisão adversarial de 2026-08-06, num canal
  # onde todo disparo interrompe. Por isso os dois primeiros casos abaixo são os que importam.
  local mg_noisy=0
  for v in '"grep -rn \"gh pr merge\" .claude/hooks/"' '"echo proximo-passo-gh-pr-create-fill"' \
           '"gh pr checks 551"' '"gh pr view 551 --json state"' '"gh pr list --state open"'; do
    out="$(_erg "${v}" '"saida"' || true)"
    if printf '%s' "${out}" | grep -qE 'MERGE-SEM-FONTE-LIDA|PR-SEM-PASSADA-ADVERSARIAL'; then mg_noisy=1; fi
  done
  if [ "${mg_noisy}" -eq 0 ]; then
    record_pass "empty-result-guard: (k) MENÇÃO ao comando (grep/echo) e verbos de leitura → SILENCIOSO"
  else record_fail "empty-result-guard: (k) anti-ruido do 5o" "disparou em verbo de LEITURA — ensinaria a ignorar o proprio aviso"; fi

  # (e) exit 2 quando dispara — é a ÚNICA via medida em que o stderr de PostToolUse chega ao modelo.
  #     Com exit 0 a guarda roda e o aviso EVAPORA (dogfood 2026-08-02). Esta asserção é load-bearing.
  rc=0
  printf '{"tool_input":{"command":"ls -d /nada"},"tool_response":{"stdout":""}}' | bash "${hook}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then
    record_pass "empty-result-guard: (e) dispara com exit 2 (a única via que o aviso chega ao modelo)"
  else record_fail "empty-result-guard: (e)" "exit ${rc} != 2 — o aviso não chegaria ao modelo"; fi

  # (f) e (g) sao PAR e so valem juntas — nasceram de um falso-positivo MEDIDO no 1o dia da guarda
  # (2026-08-02: a mensagem de commit que DESCREVIA os 4 detectores disparou os 4, porque o corpo do
  # heredoc entrou no escaneamento). (f) prova que o ruido morreu; (g) prova que a cura NAO CEGOU a
  # guarda. Filtro anti-ruido sem o par (g) e como se silencia um alarme inteiro e passa no teste.
  local hd_quiet hd_loud
  hd_quiet='{"tool_input":{"command":"git commit -F - <<'"'"'EOF'"'"'\nfeat: descreve os detectores\n  tail f | sed x; echo $?\n  sudo -n ls /home/onion/.env.bak-*\n  cmd 2>/dev/null | wc -l\nEOF"},"tool_response":{"stdout":"ok"}}'
  out="$(printf '%s' "${hd_quiet}" | bash "${hook}" 2>&1 || true)"
  if ! printf '%s' "${out}" | grep -q 'pode MENTIR'; then
    record_pass "empty-result-guard: (f) padroes dentro de CORPO de heredoc (texto) → SILENCIOSO"
  else record_fail "empty-result-guard: (f)" "falso-positivo em prosa de heredoc: ${out}"; fi

  hd_loud='{"tool_input":{"command":"sudo -n ls /home/onion/x/.env.bak-* 2>/dev/null | wc -l\ngit commit -F - <<'"'"'EOF'"'"'\ntexto inocente\nEOF"},"tool_response":{"stdout":"0"}}'
  out="$(printf '%s' "${hd_loud}" | bash "${hook}" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'GLOB-SOB-SUDO' && printf '%s' "${out}" | grep -q 'ERRO-ENGOLIDO'; then
    record_pass "empty-result-guard: (g) MESMO comando, padrao FORA do heredoc → AINDA DISPARA (o filtro nao cegou)"
  else record_fail "empty-result-guard: (g)" "o filtro de heredoc CEGOU a guarda — silenciou comando real: ${out}"; fi

  # (h) e (i) sao PAR — nasceram do 2o falso-positivo achado POR USO no mesmo dia: o detector de $?
  # casava pipe em QUALQUER lugar com $? em QUALQUER lugar, mesmo em instrucoes separadas. Agora e
  # por PROXIMIDADE (mesma linha ou a imediatamente anterior). (h) prova que o ruido morreu;
  # (i) prova que a versao MULTI-LINHA do caso real — `cmd | tail` numa linha, `echo $?` na de
  # baixo — continua sendo pega. Sem (i), "proximidade" poderia ter virado "so mesma linha" e o
  # caso que originou a guarda escaparia.
  out="$(_erg '"find x | sed s/a/b/\n\n\nbash script.sh > /tmp/o 2>&1\necho exit=$?"' '"x"' || true)"
  if ! printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (h) \$? longe do pipe (instrucoes distintas) → SILENCIOSO"
  else record_fail "empty-result-guard: (h)" "falso-positivo cross-statement: ${out}"; fi

  out="$(_erg '"bash radar.sh f 2>&1 | tail -22\necho EXIT=$?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (i) pipe numa linha + \$? na SEGUINTE → AINDA DISPARA (o caso real)"
  else record_fail "empty-result-guard: (i)" "a proximidade cegou o caso multi-linha que originou a guarda: ${out}"; fi

  # (l)…(o) sao o PAR do 3o filtro anti-ruido (`unquoted`, 2026-08-09) — e nasceram DEPOIS dele,
  # o que e exatamente o defeito: a 1a versao do filtro entrou SEM par, e uma passada adversarial
  # provou que muta-la inteira mantinha esta bancada 11/11 VERDE. Medicao de mao nao e mecanismo.
  # (l) prova que o ruido morreu; (m)(n)(o) provam que o filtro NAO CEGOU a guarda — cada uma
  # cobre uma das TRES formas em que "entre aspas e texto" e FALSO, e todas foram regressoes reais.
  out="$(_erg '"bash algo.sh > arq 2>&1\necho \"rc=$?\"; grep -E '"'"'Passaram|Falharam'"'"' arq"' '"x"' || true)"
  if ! printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (l) \$? de REDIRECT + | no PADRAO do grep → SILENCIOSO"
  else record_fail "empty-result-guard: (l)" "o falso-positivo que disparou 5x numa sessao voltou: ${out}"; fi

  # (m) o modo-de-falha nº2 que FUNDOU a guarda. A 1a cura o cegou — e o proprio diff que a
  # introduziu continha tres linhas desta forma.
  out="$(_erg '"n=\"$(ls /tmp | wc -l)\"\necho $?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (m) pipe dentro de \$( ) → AINDA DISPARA (aspas com SUBSTITUICAO nao sao texto)"
  else record_fail "empty-result-guard: (m)" "o filtro de aspas cegou o modo-de-falha FUNDADOR da guarda: ${out}"; fi

  out="$(_erg '"bash -c '"'"'ls /tmp | tail -1'"'"'\necho $?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (n) pipe em string de \`sh -c\` → AINDA DISPARA (ali as aspas contem SHELL)"
  else record_fail "empty-result-guard: (n)" "o filtro de aspas cegou pipe real entregue a um shell: ${out}"; fi

  # (o) aspa DENTRO de aspa e literal — par-de-regex nao sabe disso e apagava o miolo inteiro,
  # pipe real junto. Por isso a varredura passou a ser por ESTADO, caractere a caractere.
  out="$(_erg '"echo \"it'"'"'s\"; ls | wc -l; echo \"don'"'"'t\"; echo $?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (o) apostrofo DENTRO de aspas duplas → AINDA DISPARA (aspa em aspa e literal)"
  else record_fail "empty-result-guard: (o)" "o gsub desemparelhado apagou o pipe real do meio do comando: ${out}"; fi

  # (q)/(r) sao o PAR do 4o filtro anti-ruido (ORDEM na mesma linha, 2026-08-09). O caso real:
  # `echo "rc=$?"; grep ... arquivo | head -4` — o `$?` e do comando da linha ANTERIOR e o pipe vem
  # DEPOIS dele. (q) prova que o ruido morreu; (r) prova que o filtro NAO CEGOU: pipe ANTES do `$?`
  # na mesma linha continua sendo o caso que funda o detector.
  out="$(_erg '"bash algo.sh > f 2>&1\necho \"rc=$?\"; grep -E x f | head -4"' '"x"' || true)"
  if ! printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (q) \$? ANTES do pipe na mesma linha → SILENCIOSO"
  else record_fail "empty-result-guard: (q)" "falso-positivo de ORDEM: o \$? e da linha anterior e o pipe vem depois: ${out}"; fi

  out="$(_erg '"ls | wc -l; echo $?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (r) pipe ANTES do \$? na mesma linha → AINDA DISPARA (o caso fundador)"
  else record_fail "empty-result-guard: (r)" "o filtro de ORDEM cegou o caso que funda o detector: ${out}"; fi

  # (s) O `$?` QUE IMPORTA E O ULTIMO. Fail-open que a PROPRIA cura de ordem introduziu, achado
  # medindo e nao lendo: em `echo $?; ls | wc -l; echo $?` o `index()` pegava o PRIMEIRO `$?`
  # (antes do pipe), concluia "ordem ok" e CALAVA — enquanto o SEGUNDO le o exit do `wc`.
  # Um filtro que resolve um falso-positivo e abre um falso-NEGATIVO troca ruido por mentira.
  out="$(_erg '"echo $?; ls | wc -l; echo $?"' '"x"' || true)"
  if printf '%s' "${out}" | grep -q 'EXIT-CODE-DE-PIPE'; then
    record_pass "empty-result-guard: (s) multiplos \$? — o ULTIMO apos pipe real AINDA DISPARA"
  else record_fail "empty-result-guard: (s)" "o filtro de ORDEM olhou o PRIMEIRO \$? e cegou o segundo: ${out}"; fi

  # (p) MUTATION: prova que `unquoted` e load-bearing nas DUAS direcoes. Sem isto, remover o filtro
  # (voltando o falso-positivo) ou neutraliza-lo (voltando os fail-opens) passaria em silencio —
  # que foi literalmente o que aconteceu na 1a versao.
  local gd; gd="$(mktemp -d)"
  cp "${hook}" "${gd}/m.sh"
  # mutante: `unquoted` vira identidade -> o filtro some -> (l) tem de REPROVAR
  perl -0pi -e 's/function unquoted\(s,   i, c, q, o\) \{/function unquoted(s,   i, c, q, o) { return s;/' "${gd}/m.sh"
  if cmp -s "${hook}" "${gd}/m.sh"; then
    record_fail "empty-result-guard: (p) mutation" "a ancora nao pegou — o mutante e IDENTICO ao original, o caso mediria o nada"
  else
    local m_l m_m
    # ⚠️ O CASO TEM DE ISOLAR `unquoted`, e a 1a versao nao isolava: ela mutava contra o caso (l),
    #    cujo `|` (entre aspas) vem DEPOIS do `$?` — entao o filtro de ORDEM, criado depois, passou a
    #    cobri-lo sozinho e o mutante "ainda satisfazia". O proprio `_prove_mutation` acusou.
    #    Aqui o `|` entre aspas vem ANTES do `$?`: a ordem NAO salva, so `unquoted` salva.
    m_l="$(printf '%s' '{"tool_input":{"command":"grep -E '"'"'Passaram|Falharam'"'"' arq; echo $?"},"tool_response":{"stdout":"x"}}' | bash "${gd}/m.sh" 2>&1 || true)"
    m_m="$(printf '%s' '{"tool_input":{"command":"n=\"$(ls /tmp | wc -l)\"\necho $?"},"tool_response":{"stdout":"x"}}' | bash "${gd}/m.sh" 2>&1 || true)"
    if printf '%s' "${m_l}" | grep -q 'EXIT-CODE-DE-PIPE' && printf '%s' "${m_m}" | grep -q 'EXIT-CODE-DE-PIPE'; then
      record_pass "empty-result-guard: (p) mutation — sem \`unquoted\` o caso (l) REPROVA (o filtro e load-bearing)"
    else record_fail "empty-result-guard: (p) mutation" "o mutante SEM o filtro ainda satisfaz (l) — o caso (l) passa por vacuo"; fi
  fi
  rm -rf "${gd}"
}

# Modo varredura-sa — REGRA 54. O caso que FALTAVA: rodar o lint de DENTRO de um worktree.
# Nenhum selftest exercitava isso, e por isso a poda que se comia passou despercebida ate
# 2026-08-04 — quando o lint, rodando em .claude/worktrees/<name>/ (o caminho que o Claude
# Code usa nativamente desde a v2.1.49 e que worktree-convention-2026.md declara canonico),
# varreu 0 dos 51 agentes sem emitir uma linha. O teste (b) e o MUTATION que prova que a
# REGRA 54 e load-bearing: sem ele, ela poderia ser decorativa e ninguem saberia.
run_scan_sanity_selftests() {
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_fail "varredura-sa" "lint-artifacts.sh ausente"; return; fi

  # Fixture: uma arvore .claude MINIMA vivendo SOB um caminho que contem
  # /.claude/worktrees/ — a forma exata do worktree de harness.
  local d; d="$(mktemp -d)"
  local wt="${d}/.claude/worktrees/fake-wt"
  local surface
  for surface in agents commands skills utils rules; do
    mkdir -p "${wt}/.claude/${surface}"
    printf -- '---\nname: x\n---\n\n# x\n' > "${wt}/.claude/${surface}/x.md"
  done
  mkdir -p "${wt}/.claude/validation"
  cp "${lint}" "${wt}/.claude/validation/lint-artifacts.sh"
  cp "${REPO_ROOT}/.claude/utils/safe-count.sh" "${wt}/.claude/utils/safe-count.sh"

  # (a) de dentro do worktree, a varredura TEM de enxergar a propria arvore
  local out
  out="$(bash "${wt}/.claude/validation/lint-artifacts.sh" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'varredura-sa'; then
    record_fail "varredura-sa: (a) lint rodando DE DENTRO de worktree enxerga a própria árvore" \
                "a varredura se declarou cega no proprio worktree — a poda voltou a se comer"
  else
    record_pass "varredura-sa: (a) lint rodando DE DENTRO de worktree enxerga a própria árvore"
  fi

  # (b) MUTATION — devolve a poda por sufixo (o bug original) e exige que a REGRA 54 REPROVE.
  #     Se este caso passar sem a mutacao disparar, a regra e decorativa.
  python3 - "${wt}/.claude/validation/lint-artifacts.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace('find "${roots[@]}" -path "${CLAUDE_DIR}/worktrees/*" -prune -o "${preds[@]}"',
              'find "${roots[@]}" -path \'*/.claude/worktrees/*\' -prune -o "${preds[@]}"', 1)
open(p, "w").write(s)
PY
  out="$(bash "${wt}/.claude/validation/lint-artifacts.sh" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'varredura-sa'; then
    record_pass "varredura-sa: (b) MUTATION — poda por sufixo volta a cegar e a REGRA 54 REPROVA"
  else
    record_fail "varredura-sa: (b) MUTATION" \
                "reintroduzi o bug e o gate seguiu verde — REGRA 54 e decorativa, nao load-bearing"
  fi

  rm -rf "${d}"
}

# Modo gerador-quebrado — o helper _gen_into e a neutralizacao do GIT_DIR.
# A forma antiga engolia rc e stderr do gerador (`2>/dev/null || true`), e o diff seguinte
# transformava QUEBRA em DRIFT: a violacao mandava "regenere por cima", o que ZERARIA o
# arquivo bom. Falha aberta que vira DESTRUTIVA — quem obedecesse a guarda perdia conteudo.
# O gatilho medido em 2026-08-04 foi o GIT_DIR absoluto que o git exporta em hook DENTRO de
# worktree; por isso (c) testa a RAIZ, nao so o sintoma.
run_generator_failure_selftests() {
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  local d; d="$(mktemp -d)"
  mkdir -p "${d}/.claude/validation" "${d}/docs/onion" "${d}/docs/evolution/federation"
  cp "${lint}" "${d}/.claude/validation/lint-artifacts.sh"
  printf 'members:\n  - id: onion-evolve\n    role: source\n' > "${d}/docs/evolution/federation/members.yaml"
  printf '{\n  "name": "conteudo real que NAO pode ser perdido"\n}\n' > "${d}/docs/onion/agent-card.json"

  local out
  # (a) gerador que FALHA (exit != 0) → violação diz QUEBRA, com o stderr
  printf '#!/usr/bin/env bash\necho "boom" >&2\nexit 3\n' > "${d}/.claude/validation/a2a-agent-card.sh"
  out="$(bash "${d}/.claude/validation/lint-artifacts.sh" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'o GERADOR falhou (exit 3)'; then
    record_pass "gerador-quebrado: (a) exit!=0 do gerador vira QUEBRA, não 'desatualizado'"
  else record_fail "gerador-quebrado: (a)" "exit!=0 do gerador nao produziu a violacao de QUEBRA"; fi

  # (b) gerador que devolve VAZIO com exit 0 (o caso real do GIT_DIR) → QUEBRA, e SEM "regenere"
  printf '#!/usr/bin/env bash\nexit 0\n' > "${d}/.claude/validation/a2a-agent-card.sh"
  out="$(bash "${d}/.claude/validation/lint-artifacts.sh" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'saída VAZIA' &&
     ! printf '%s' "${out}" | grep -q 'agent card desatualizado'; then
    record_pass "gerador-quebrado: (b) saída vazia vira QUEBRA e NUNCA o conselho que zera o arquivo"
  else record_fail "gerador-quebrado: (b)" "saida vazia ainda vira 'desatualizado — regenere' (conselho destrutivo)"; fi
  rm -rf "${d}"

  # (c) A RAIZ — com GIT_DIR setado (como o git faz em hook dentro de worktree),
  #     `git -C <subdir> rev-parse --show-toplevel` tem de devolver a RAIZ, não o subdir.
  local gd top
  gd="$(git -C "${REPO_ROOT}" rev-parse --git-dir 2>/dev/null || true)"
  if [ -z "${gd}" ]; then
    record_fail "gerador-quebrado: (c)" "nao obtive git-dir para o teste de GIT_DIR"
  else
    top="$(GIT_DIR="${gd}" env -u GIT_DIR -u GIT_WORK_TREE git -C "${REPO_ROOT}/.claude/validation" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ "${top}" = "${REPO_ROOT}" ]; then
      record_pass "gerador-quebrado: (c) GIT_DIR neutralizado — -C <subdir> resolve a RAIZ, não o subdir"
    else
      record_fail "gerador-quebrado: (c)" "com GIT_DIR o toplevel virou '${top}' (esperado '${REPO_ROOT}') — geradores voltariam a emitir vazio"
    fi
  fi
}

# Modo kg-verificacao — REGRA 49. O gate garante que no plane:PROD impact>=4 NASCA carimbado e que
# o passivo NAO CRESCA. Nao checa se o carimbo e verdade (limite declarado: quem mede e o worker do
# /meta:kg-freshness). O teste (d) e o anti-falso-positivo; o (g) e o MUTATION que prova load-bearing.
run_safe_count_selftests() {
  # O helper existe para que "zero" e "falhou" nunca mais colidam. Se ELE colidir, o
  # remédio vira a doença — por isso nasce com teste, ao contrário das 4 guardas cujos
  # furos esta mesma sessão descobriu por elas não terem nenhum.
  local h="${REPO_ROOT}/.claude/utils/safe-count.sh"
  if [ ! -f "${h}" ]; then record_fail "safe-count" "helper ausente"; return; fi
  local d out rc
  # shellcheck source=/dev/null
  . "${h}"

  d="$(mktemp -d)"; printf 'x\n' > "${d}/a.md"; printf 'y\n' > "${d}/b.md"

  # (a) contagem real
  out="$(count_files "${d}" '*.md')"; rc=$?
  if [ "${out}" = "2" ] && [ "${rc}" -eq 0 ]; then
    record_pass "safe-count: (a) conta arquivos reais (2) com exit 0"
  else record_fail "safe-count: (a)" "esperava '2'/exit0, veio '${out}'/exit${rc}"; fi

  # (b) VAZIO DE VERDADE → '0' com exit 0
  out="$(count_files "${d}" '*.xyz')"; rc=$?
  if [ "${out}" = "0" ] && [ "${rc}" -eq 0 ]; then
    record_pass "safe-count: (b) vazio real → '0' com exit 0"
  else record_fail "safe-count: (b)" "esperava '0'/exit0, veio '${out}'/exit${rc}"; fi

  # (c) O CASO QUE JUSTIFICA O HELPER — alvo AUSENTE não pode virar '0'
  # `|| rc=$?` e NAO `|| true`: o comando falha DE PROPOSITO, e sob `set -e` capturar sua
  # saida sem tratamento mata a suite. Mas `|| true` zeraria o exit code que este caso
  # EXISTE para verificar — o teste passaria a nao testar nada. A forma abaixo satisfaz o
  # set -e E preserva o codigo. (Errei as duas coisas em sequencia ao escrever isto.)
  rc=0; out="$(count_files "${d}/nao-existe" '*.md' 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 2 ] && [ "${out}" != "0" ]; then
    record_pass "safe-count: (c) alvo ausente → exit 2 e NÃO '0' (a distinção que o 2>/dev/null apaga)"
  else record_fail "safe-count: (c)" "alvo ausente virou '${out}'/exit${rc} — o helper reproduz o defeito"; fi

  # (d) MUT do contrato de stdout: a saída tem de ser SÓ o número, consumível por $( ).
  #     Se vazar mensagem para stdout, todo `n=$(count_files ...)` a jusante quebra.
  out="$(count_files "${d}" '*.md')"
  if printf '%s' "${out}" | grep -qE '^[0-9]+$'; then
    record_pass "safe-count: (d) stdout é SÓ o número (contrato de \$( ) preservado)"
  else record_fail "safe-count: (d)" "stdout poluído: '${out}'"; fi

  # (e) count_matches: zero-que-casa-nada é resultado legítimo, não erro
  out="$(count_matches 'zzz-inexistente' "${d}/a.md")"; rc=$?
  if [ "${out}" = "0" ] && [ "${rc}" -eq 0 ]; then
    record_pass "safe-count: (e) count_matches sem match → '0' com exit 0 (grep exit 1 não é falha)"
  else record_fail "safe-count: (e)" "esperava '0'/exit0, veio '${out}'/exit${rc}"; fi

  # (f) count_matches com ARQUIVO ausente → erro, nunca zero
  rc=0; out="$(count_matches 'x' "${d}/nao-existe.md" 2>/dev/null)" || rc=$?
  if [ "${rc}" -eq 2 ]; then
    record_pass "safe-count: (f) count_matches com arquivo ausente → exit 2"
  else record_fail "safe-count: (f)" "arquivo ausente não deu exit 2: '${out}'/exit${rc}"; fi

  rm -rf "${d}"
}

run_line_limits_selftests() {
  # REGRA 5 — limites POR TIPO. Modo dedicado em vez de fixture-de-arquivo: o caso `bad`
  # exige >800 linhas, e commitar um .md de 801 linhas só para testar contagem seria peso
  # morto permanente no repo. Aqui o arquivo grande é GERADO no sandbox e morre com ele.
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  local d out
  _mkbig() { # $1=dir $2=nome $3=nlinhas
    mkdir -p "$1"
    { printf -- '---\ndescription: fixture de limite de linhas\nmodel: haiku\n---\n\n'
      local i=1
      while [ "$i" -le "$3" ]; do printf 'Linha de corpo %s do comando sintetico.\n' "$i"; i=$((i+1)); done
    } > "$1/$2"
  }
  _sandbox() { # monta um repo minimo com o lint real
    local s; s="$(mktemp -d)"
    cp -a "${REPO_ROOT}/.claude" "$s/.claude"; cp -a "${REPO_ROOT}/docs" "$s/docs"
    cp -a "${REPO_ROOT}/CLAUDE.md" "$s/CLAUDE.md" 2>/dev/null || true
    printf '%s' "$s"
  }

  # (a) comando ACIMA do teto hard (800) → HARD
  d="$(_sandbox)"; _mkbig "$d/.claude/commands/meta" "probe-grande.md" 810
  out="$(bash "$d/.claude/validation/lint-artifacts.sh" --only="$d/.claude/commands/meta/probe-grande.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'limite: 800'; then
    record_pass "line-limits: (a) comando com 810+ linhas → HARD (limite 800)"
  else record_fail "line-limits: (a)" "não reprovou comando acima do teto: ${out}"; fi
  # (a2) a mensagem TERMINA EM AÇÃO — cita a prescrição de fragmentação (commands.md §5).
  #      Sem esta asserção a cura pode cair na próxima edição e a guarda volta a só ACUSAR,
  #      que é o defeito que a revisão de 2026-08-03 mediu em 17 mensagens.
  if printf '%s' "${out}" | grep -q 'commands.md §5'; then
    record_pass "line-limits: (a2) mensagem cita a cura (commands.md §5), não só acusa"
  else record_fail "line-limits: (a2)" "mensagem sem prescrição de fragmentação: ${out}"; fi
  rm -rf "$d"

  # (b) FRONTEIRA — comando logo ABAIXO do teto → silêncio. Sem este caso, (a) passaria
  #     mesmo que o limiar fosse reescrito para 20 linhas: é o par que prova a FRONTEIRA,
  #     não só a existência da guarda.
  d="$(_sandbox)"; _mkbig "$d/.claude/commands/meta" "probe-limite.md" 790
  out="$(bash "$d/.claude/validation/lint-artifacts.sh" --only="$d/.claude/commands/meta/probe-limite.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'limite: 800'; then
    record_fail "line-limits: (b)" "falso-positivo logo abaixo do teto: ${out}"
  else record_pass "line-limits: (b) comando logo abaixo do teto → silêncio (a fronteira é o que importa)"; fi
  rm -rf "$d"

  # (c) TIPO importa — o MESMO tamanho que reprova como comando (810) passa como AGENTE,
  #     cujo teto é 1500. É a tese da regra: "tamanho saudável ≠ número universal".
  d="$(_sandbox)"
  mkdir -p "$d/.claude/agents/development"
  { printf -- '---\nname: probe-agente\ndescription: fixture de limite\nmodel: haiku\ncategory: development\ntools:\n  - Read\n---\n\n'
    i=1; while [ "$i" -le 810 ]; do printf 'Linha de corpo %s do agente sintetico.\n' "$i"; i=$((i+1)); done
  } > "$d/.claude/agents/development/probe-agente.md"
  out="$(bash "$d/.claude/validation/lint-artifacts.sh" --only="$d/.claude/agents/development/probe-agente.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -qE 'limite: (800|1500)'; then
    record_fail "line-limits: (c)" "810 linhas não deveria reprovar como AGENTE (teto 1500): ${out}"
  else record_pass "line-limits: (c) 810 linhas reprova como COMANDO mas passa como AGENTE — o teto é por TIPO"; fi
  rm -rf "$d"

  # (d) o ramo do AGENTE acima de 1500 nunca tinha teste POSITIVO — só o negativo (c). Sem ele,
  #     a R5a podia ter parado de emitir e (c) seguiria verde (ele espera silêncio). Cobre os
  #     dois eixos de uma vez: reprova E ensina a cura (agents.md §4).
  d="$(_sandbox)"
  mkdir -p "$d/.claude/agents/development"
  { printf -- '---\nname: probe-agente-grande\ndescription: fixture de limite\nmodel: haiku\ncategory: development\ntools:\n  - Read\n---\n\n'
    i=1; while [ "$i" -le 1510 ]; do printf 'Linha de corpo %s do agente sintetico.\n' "$i"; i=$((i+1)); done
  } > "$d/.claude/agents/development/probe-agente-grande.md"
  out="$(bash "$d/.claude/validation/lint-artifacts.sh" --only="$d/.claude/agents/development/probe-agente-grande.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'limite: 1500'; then
    record_pass "line-limits: (d) agente com 1510 linhas → HARD (limite 1500)"
  else record_fail "line-limits: (d)" "não reprovou agente acima do teto: ${out}"; fi
  if printf '%s' "${out}" | grep -q 'agents.md §4'; then
    record_pass "line-limits: (d2) mensagem cita a cura (agents.md §4), não só acusa"
  else record_fail "line-limits: (d2)" "mensagem sem prescrição de fragmentação: ${out}"; fi
  rm -rf "$d"
}

run_review_verdict_selftests() {
  # O onion-review REVISOU, ou só saiu verde? A leitura mora em `review-verdict.sh` porque
  # YAML de workflow não tem selftest — e foi exatamente assim que a máquina de resiliência
  # do onion-review sobreviveu meses parecendo sã, condicionada a um sinal que nunca dispara
  # (`steps.review.outcome`, que sai 'success' mesmo com is_error). Aqui os desfechos são
  # exercidos a cada rodada, incluindo o (MUT) que prova que crash e revisão-sã divergem.
  local helper="${REPO_ROOT}/.claude/validation/review-verdict.sh"
  if [ ! -f "${helper}" ]; then record_fail "review-verdict" "helper ausente"; return; fi
  local out rc=0
  out="$(bash "${helper}" --selftest 2>&1)" || rc=$?
  while IFS= read -r line; do
    case "${line}" in
      *"  ✓ "*) record_pass "${line#*✓ }" ;;
      *"  ✗ "*) record_fail "review-verdict" "${line#*✗ }" ;;
    esac
  done <<< "${out}"
  if [ "${rc}" -ne 0 ]; then
    record_fail "review-verdict" "o selftest do helper saiu ${rc}"
  fi
}

run_kg_radar_integrity_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/kg-radar-integrity.sh"
  if [ ! -f "${helper}" ]; then record_fail "kg-integridade" "helper ausente"; return; fi
  local d out

  # Monta um repo git com UM grafo. $2=são|contraditório
  _mki() {
    mkdir -p "$1/.claude/validation" "$1/docs/onion/graph"
    cp "${REPO_ROOT}/.claude/validation/kg-radar.sh" "$1/.claude/validation/"; _lib_beside "$1/.claude/validation"
    { printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n'
      printf '  - id: C_alvo\n    node_type: claim\n    plane: DEV\n    impact: 3\n    status: %s\n    label: "x"\n' \
             "$([ "$2" = contraditorio ] && echo confirmed || echo refuted)"
      printf '  - id: E_ref\n    node_type: evidence\n    plane: DEV\n    impact: 3\n    status: confirmed\n    label: "y"\n'
      printf 'edges:\n  - from: E_ref\n    to: C_alvo\n    edge_type: REFUTES\n'
    } > "$1/docs/onion/graph/t.kg.yaml"
    ( cd "$1" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm x ) 2>/dev/null
  }

  # (a) grafo com CONTRADIÇÃO (recebe REFUTES e segue confirmed) → HARD
  d="$(mktemp -d)"; _mki "$d" contraditorio
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | grep -q '^HARD.*CONTRADICAO'; then
    record_pass "kg-integridade: (a) grafo com REFUTES sobre nó confirmed → HARD"
  else record_fail "kg-integridade: (a)" "não reprovou grafo contraditório: ${out}"; fi
  rm -rf "$d"

  # (b) MESMO grafo reconciliado (status refuted) → silêncio. Prova que (a) não é vacuidade:
  #     se a guarda reprovasse sempre, (b) falharia aqui.
  d="$(mktemp -d)"; _mki "$d" sao
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if [ -z "${out}" ]; then
    record_pass "kg-integridade: (b) mesmo grafo reconciliado → silêncio (a guarda não reprova sempre)"
  else record_fail "kg-integridade: (b)" "falso-positivo em grafo são: ${out}"; fi
  rm -rf "$d"

  # (c) contrato TSV — 4 campos separados por TAB, como as irmãs 29/42/45/49. O lint
  #     consome por `IFS=$'\t' read -r sev tag path msg`; formato errado quebra o fan-in.
  d="$(mktemp -d)"; _mki "$d" contraditorio
  # `|| true` NÃO é decorativo: o helper sai 1 de propósito quando há HARD, e sob o
  # `set -euo pipefail` deste script isso ABORTA a suíte inteira. Sem ele, a suíte morria
  # aqui e o exit 1 parecia "uma guarda falhou" quando era "o teste se matou". Medido 2026-08-03.
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null | head -1 || true)"
  if [ "$(printf '%s' "${out}" | awk -F'\t' '{print NF}')" = "4" ]; then
    record_pass "kg-integridade: (c) contrato TSV com 4 campos (sev/tag/path/msg)"
  else record_fail "kg-integridade: (c)" "TSV fora do contrato das irmãs: ${out}"; fi
  rm -rf "$d"

  # (d) MUT do PONTO CEGO declarado: o helper usa `git ls-files`, então grafo NÃO-RASTREADO
  #     é invisível. Este teste FIXA o comportamento declarado no cabeçalho — se alguém trocar
  #     para `find`, ele falha e obriga a atualizar a declaração (guarda contra doc mentindo).
  d="$(mktemp -d)"; _mki "$d" sao
  cp "$d/docs/onion/graph/t.kg.yaml" "$d/docs/onion/graph/untracked.kg.yaml"
  sed -i 's/status: refuted/status: confirmed/' "$d/docs/onion/graph/untracked.kg.yaml"
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if [ -z "${out}" ]; then
    record_pass "kg-integridade: (d) grafo UNTRACKED contraditório é invisível — ponto cego declarado no cabeçalho"
  else record_fail "kg-integridade: (d)" "o ponto cego declarado não confere: ${out}"; fi
  rm -rf "$d"
}

run_kg_verification_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/kg-verification-coverage.sh"
  if [ ! -f "${helper}" ]; then record_fail "kg-verificacao" "helper ausente"; return; fi
  local d out rc

  _mk() {  # $1=dir $2=id $3=plane $4=impact $5=status $6=verified_at("" p/ nenhum)
    mkdir -p "$1/docs/onion/graph"
    { printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n'
      printf '  - id: %s\n    node_type: claim\n    plane: %s\n    impact: %s\n    status: %s\n' "$2" "$3" "$4" "$5"
      [ -n "$6" ] && printf '    verified_at: %s\n' "$6"
      printf '    label: "x"\n'
    } > "$1/docs/onion/graph/t.kg.yaml"
    ( cd "$1" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm x ) 2>/dev/null
  }

  # (a) no NOVO PROD/impact>=4 sem carimbo, baseline vazio -> HARD
  d="$(mktemp -d)"; _mk "$d" C_NOVO PROD 5 confirmed ""
  mkdir -p "$d/.claude/validation"; printf '# vazio\n' > "$d/.claude/validation/kg-verification-baseline.txt"
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | grep -q '^HARD.*NOVO'; then
    record_pass "kg-verificacao: (a) no novo PROD/impact>=4 sem verified_at → HARD"
  else record_fail "kg-verificacao: (a)" "nao reprovou no novo sem carimbo: ${out}"; fi

  # (b) o MESMO no, agora no baseline -> SOFT PASSIVO (tolerado), sem HARD
  bash "${helper}" "$d" --emit-baseline > "$d/.claude/validation/kg-verification-baseline.txt" 2>/dev/null
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | grep -q '^SOFT.*PASSIVO' && ! printf '%s' "${out}" | grep -q '^HARD'; then
    record_pass "kg-verificacao: (b) mesmo no no baseline → SOFT PASSIVO, sem HARD (catraca tolera)"
  else record_fail "kg-verificacao: (b)" "baseline nao tolerou o passivo: ${out}"; fi

  # (c) no COM verified_at -> silencio total
  d="$(mktemp -d)"; _mk "$d" C_OK PROD 5 confirmed 2026-08-01
  mkdir -p "$d/.claude/validation"; printf '# vazio\n' > "$d/.claude/validation/kg-verification-baseline.txt"
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if [ -z "${out}" ]; then
    record_pass "kg-verificacao: (c) no com verified_at → silencio"
  else record_fail "kg-verificacao: (c)" "falso-positivo em no carimbado: ${out}"; fi

  # (d) ANTI-FALSO-POSITIVO: impact 3, plane DEV e status superseded ficam FORA do escopo
  local noisy=0 spec
  for spec in "C_LOW PROD 3 confirmed" "C_DEV DEV 5 confirmed" "C_SUP PROD 5 superseded"; do
    set -- ${spec}
    d="$(mktemp -d)"; _mk "$d" "$1" "$2" "$3" "$4" ""
    mkdir -p "$d/.claude/validation"; printf '# vazio\n' > "$d/.claude/validation/kg-verification-baseline.txt"
    out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
    printf '%s' "${out}" | grep -q '^HARD' && noisy=1
  done
  if [ "${noisy}" -eq 0 ]; then
    record_pass "kg-verificacao: (d) impact<4, plane DEV e superseded → FORA do escopo (sem falso-positivo)"
  else record_fail "kg-verificacao: (d)" "escopo largo demais — cobrou no que nao deveria"; fi

  # (e) FAIL-CLOSED: baseline AUSENTE nao libera tudo
  d="$(mktemp -d)"; _mk "$d" C_X PROD 5 confirmed ""
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | grep -q 'NO-BASELINE'; then
    record_pass "kg-verificacao: (e) baseline ausente → HARD NO-BASELINE (fail-closed, nao libera tudo)"
  else record_fail "kg-verificacao: (e)" "sem baseline o gate ficou mudo: ${out}"; fi

  # (f) o baseline NAO pode conter id de no cru (viaja vendorizado — REGRA 36 pegou isto de verdade)
  d="$(mktemp -d)"; _mk "$d" E_NOME_DE_CLIENTE PROD 5 confirmed ""
  out="$(bash "${helper}" "$d" --emit-baseline 2>/dev/null || true)"
  if ! printf '%s' "${out}" | grep -q 'E_NOME_DE_CLIENTE'; then
    record_pass "kg-verificacao: (f) baseline guarda hash, NAO o id cru (id carrega nome de adotante)"
  else record_fail "kg-verificacao: (f)" "VAZAMENTO: o id cru foi para o baseline versionado"; fi

  # (g) MUTATION TEST — sem a condicao central (ver == ""), o caso (a) para de reprovar
  d="$(mktemp -d)"; _mk "$d" C_NOVO PROD 5 confirmed ""
  mkdir -p "$d/.claude/validation"; printf '# vazio\n' > "$d/.claude/validation/kg-verification-baseline.txt"
  local mut="$d/mutante.sh" rc_intact rc_mutant
  sed 's/&& ver == ""/\&\& ver != ver/' "${helper}" > "${mut}"
  # ⚠️ DUAS armadilhas do `set -euo pipefail` desta bancada (linha 41), as duas medidas em 2026-08-08:
  #   · `cmd; rc=$?` MATA a suite no comando que retorna != 0 — ela abortou logo depois do caso (f),
  #     exit 1, zero ✗ e NENHUMA soma. Por isso `if`, nunca `; rc=$?`.
  #   · `pipefail` faz `helper | grep -q` devolver o exit do HELPER, e o helper sai 1 justamente
  #     quando ACHA HARD. Sem capturar a saida antes, o caso le "nao achou" quando achou — e o
  #     `_prove_mutation` acusa FIXTURE MORTA sobre uma fixture perfeitamente viva.
  local out_intact out_mutant
  out_intact="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  out_mutant="$(bash "${mut}"    "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out_intact}" | grep -q '^HARD.*NOVO'; then rc_intact=0; else rc_intact=1; fi
  if printf '%s' "${out_mutant}" | grep -q '^HARD.*NOVO'; then rc_mutant=0; else rc_mutant=1; fi
  _prove_mutation "kg-verificacao: (g) (MUT) sem a condicao central (ver == \"\") o caso (a) para de reprovar" \
                 "${helper}" "${mut}" "${rc_intact}" "${rc_mutant}"
}

# ── REGRA 49 · GUARDA DE DIREÇÃO — o baseline só encolhe por MEDIÇÃO ────────────────────────────
# Bloco nascido de um fail-open ATIVO, reproduzido em 2026-08-07 no corpus real: trocar UM nó
# PROD/impact>=4 de `confirmed` para `drifted`, sem medir nada, derrubava o gate de 48 para 47 com a
# mensagem "[OBSOLETA] entrada OBSOLETA (no ja carimbado ou removido)" — o gate AFIRMAVA um carimbo
# inexistente. Duas raízes: o predicado era ALLOWLIST (e o enum de `status` cresceu por baixo dele,
# com `drifted`/`unverifiable` nascendo em 2026-08-06), e a saída do escopo não era classificada.
# ── REGRA 58 — o backlog cumpre as promessas do proprio `meta:` ──────────────────────────────
# As tres promessas (TETO, DONE-NU, e o fail-loud do SEM-TETO) eram DISCIPLINA ate 2026-08-09:
# o `meta:` de fios-abertos.kg.yaml as declarava em letra grande e nada as cobrava. Cada caso
# aqui muta o backlog REAL (copia em mktemp), nunca uma fixture inventada — o gatilho declarado
# no plano e "as classes rodam em CAMPO", e fixture sintetica ja existe demais nesta bancada.
# ── OS MODOS QUE A PRODUCAO CONSOME E A BANCADA NUNCA EXERCITAVA ──────────────────────────────
# Fechados porque o `consumed-mode-check.sh` os NOMEOU, rodando de verdade: 31 pares de producao,
# 5 sem teste. Um deles (`kg-backlog-check.sh --format tsv`) e o modo que o LINT consome do script
# que eu mesmo acabara de mergear — a bancada chamava o helper SEM a flag, entao o caminho que
# realmente barra o merge nunca foi exercitado.
#
# ⚠️ CADA CASO ASSERE ALGO, nunca so invoca. Chamar o modo para "satisfazer o detector" e cerimonia:
# transformaria o instrumento num contador de invocacoes, e um teste que nao pode falhar e ruido.
# ── REGRA 60 — identificador de código em INGLÊS ──────────────────────────────────────────────
# A classe foi apontada em SEIS PRs de uma sessão e a cura era disciplina. Cada caso aqui existe
# porque uma escolha de desenho podia ter ido para o outro lado, e a medição decidiu (PR #568).
run_identifier_language_selftests() {
  local helper="${SCRIPT_DIR}/identifier-language-check.sh"
  local words="${SCRIPT_DIR}/lib/pt-br-words.txt"
  if [ ! -f "${helper}" ]; then record_fail "idioma" "helper ausente"; return; fi
  local d rc out

  # (a) o repo VIVO passa — sem isto os mutantes abaixo provariam o nada (fixture morta)
  rc=0; out="$(bash "${helper}" "${REPO_ROOT}" --format tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "idioma: (a) o repo vivo PASSA (os residuais estao no baseline, o novo e que e HARD)"
  else record_fail "idioma: (a)" "o repo real ja reprova (rc=${rc}): $(printf '%s' "${out}" | head -c 200)"; fi

  _lang_repo() { # $1=dir  $2=conteudo do script novo
    mkdir -p "$1/.claude/validation/lib"
    cp "${helper}" "$1/.claude/validation/"; cp "${words}" "$1/.claude/validation/lib/"
    cp "${REPO_ROOT}/.claude/validation/identifier-language-baseline.txt" "$1/.claude/validation/" 2>/dev/null || :
    printf '%s\n' "$2" > "$1/.claude/validation/novo.sh"
    ( cd "$1" && git init -q . && git add -A ) >/dev/null 2>&1
  }

  # (b) identificador NOVO em pt-BR e HARD, nomeando o SEGMENTO que o condenou
  # ⚠️ A FIXTURE E MONTADA EM PEDACOS de proposito: escrita inteira, a linha `local <pt>=0` ficaria
  #    literal NESTE arquivo e o proprio extrator a leria como declaracao REAL — a bancada viraria a
  #    maior fonte de violacoes da regra que ela testa. Achado pelo caso (a) na 1a corrida.
  d="$(mktemp -d)"; _lang_repo "$d" "#!/usr/bin/env bash
local $(printf 'contagem')_de_erros=0"
  rc=0; out="$(bash "$d/.claude/validation/identifier-language-check.sh" "$d" --format tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'IDIOMA-DE-IDENTIFICADOR' && printf '%s' "${out}" | grep -q 'contagem'; then
    record_pass "idioma: (b) identificador NOVO em pt-BR e HARD, nomeando o segmento culpado"
  else record_fail "idioma: (b)" "nao acusou ou nao nomeou o segmento (rc=${rc}): $(printf '%s' "${out}" | head -c 200)"; fi
  rm -rf "$d"

  # (c) CAMELCASE — o par de (b). Casando so por `_`, `semAspas` escaparia; e era EXATAMENTE a forma
  #     dos achados reais. A medicao do #568 mostrou 3 de 636 por palavra inteira contra 10 de 12
  #     por segmento — este caso amarra essa decisao.
  d="$(mktemp -d)"; _lang_repo "$d" "#!/usr/bin/env bash
function sem$(printf 'Aspas')() { :; }"
  rc=0; out="$(bash "$d/.claude/validation/identifier-language-check.sh" "$d" --format tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'aspas'; then
    record_pass "idioma: (c) camelCase e quebrado — \`semAspas\` acusa por \`aspas\` (a forma dos achados reais)"
  else record_fail "idioma: (c) camelCase" "o split nao quebrou camelCase (rc=${rc}): $(printf '%s' "${out}" | head -c 200)"; fi
  rm -rf "$d"

  # (d) INGLES NAO ACUSA — o falso-positivo e o que mata a guarda. Os quatro nomes aqui sao os
  #     substitutos REAIS que usei nos renames desta sessao.
  d="$(mktemp -d)"; _lang_repo "$d" '#!/usr/bin/env bash
local unquoted=1 _lib_beside=2 _missing_deps=3 dirty_before=4 total=5 base=6 final=7'
  rc=0; out="$(bash "$d/.claude/validation/identifier-language-check.sh" "$d" --format tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "idioma: (d) identificador em ingles NAO acusa — inclui homografo (total/base/final)"
  else record_fail "idioma: (d) falso-positivo" "acusou ingles (rc=${rc}): $(printf '%s' "${out}" | head -c 250)"; fi
  rm -rf "$d"

  # (e) COMENTARIO E PROSA, e prosa e pt-BR POR DOUTRINA. Uma varredura minha a mao ja errou assim
  #     no PR #565, acusando 48 "sobras" que eram todas comentario.
  # ⚠️ A FIXTURE PRECISA CONTER UMA DECLARACAO DENTRO DO COMENTARIO, senao o caso NAO PODE FALHAR:
  #    passada adversarial mediu que, sem isso, apagar o strip de comentario INTEIRO mantinha os 7
  #    casos verdes — a propriedade-manchete da regra era a unica que a bancada nao conseguia
  #    detectar. Um caso que nao pode falhar nao e teste, e ruido com cara de cobertura.
  d="$(mktemp -d)"; _lang_repo "$d" "#!/usr/bin/env bash
# exemplo de uso: $(printf 'contagem')=0 e o teto do arquivo com aspas e vereditos
local ok=1"
  rc=0; out="$(bash "$d/.claude/validation/identifier-language-check.sh" "$d" --format tsv 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "idioma: (e) COMENTARIO em pt-BR nao acusa — a doutrina e codigo em ingles, PROSA em pt-BR"
  else record_fail "idioma: (e) acusou comentario" "a guarda cobrou o oposto do padrao (rc=${rc}): $(printf '%s' "${out}" | head -c 250)"; fi
  rm -rf "$d"

  # (f) FAIL-LOUD: lista ausente e exit 2, nunca "nenhuma violacao". Fonte ausente jamais vira
  #     aprovacao (P0 da REGRA 30) — e um repo sem a lista e indistinguivel de um repo limpo para
  #     quem so olha o exit code 0.
  d="$(mktemp -d)"; _lang_repo "$d" "#!/usr/bin/env bash
local $(printf 'contagem')=1"
  rm -f "$d/.claude/validation/lib/pt-br-words.txt"
  rc=0; out="$(bash "$d/.claude/validation/identifier-language-check.sh" "$d" 2>&1)" || rc=$?
  if [ "${rc}" -eq 2 ] && printf '%s' "${out}" | grep -q 'AUSENTE'; then
    record_pass "idioma: (f) lista ausente -> exit 2 NOMEANDO o arquivo (fail-loud, nunca aprovacao)"
  else record_fail "idioma: (f)" "lista ausente nao deu exit 2 (rc=${rc}): $(printf '%s' "${out}" | head -c 200)"; fi
  rm -rf "$d"

  # (g) A LISTA NAO PODE CONTER HOMOGRAFO. Guarda-da-guarda: se alguem acrescentar `base`, `total`,
  #     `local` ou `final`, a REGRA 60 passa a acusar ingles legitimo em massa — falso-positivo em
  #     regra HARD e a corrente que o Elenxo do #566 reconstruiu.
  local homografo
  # ⚠️ `|| true` OBRIGATORIO: aqui NAO ACHAR e o resultado DESEJADO, e `grep` que nao acha sai 1 —
  #    `x="$(cmd)"` sob `set -e` ABORTA a suite inteira. E a 4a vez que esta armadilha morde nesta
  #    sessao, e as quatro foram em casos onde o silencio do comando E a conformidade.
  homografo="$(grep -xE '(base|total|local|global|final|normal|real|original|nota|via|data|error|nome)' "${words}" 2>/dev/null | tr '\n' ' ' || true)"
  if [ -z "${homografo}" ]; then
    record_pass "idioma: (g) a lista NAO contem homografo com ingles (o criterio que impede falso-positivo em massa)"
  else record_fail "idioma: (g) homografo na lista" "estas palavras tambem sao inglesas e acusariam codigo legitimo: ${homografo}"; fi
}

run_consumed_modes_selftests() {
  local d out rc
  # (0) O PROPRIO detector, no modo que a REGRA 59 consome. Ao ligar a regra, o lint passou a
  #     invocar `consumed-mode-check.sh --format tsv` — e a bancada so o chamava com `--selftest`.
  #     A regra acusou o buraco que ela mesma criou, na primeira corrida. E o comportamento certo:
  #     um detector que nao se cobre no modo que o gate usa e a definicao do que ele caca.
  local cmc="${SCRIPT_DIR}/consumed-mode-check.sh"
  if [ ! -f "${cmc}" ]; then record_skip "modos: (0) consumed-mode-check.sh ausente"; else
    rc=0; out="$(bash "${cmc}" "${REPO_ROOT}" --format tsv 2>&1)" || rc=$?
    # no verde o modo tsv CALA (o consumidor trata vazio como conforme); no vermelho emite TABULADO
    # ⚠️ O CONTRATO DO tsv MUDOU e este caso ficou para tras por uma corrida: no verde a saida NAO e
    # mais vazia — ela carrega a linha `SOFT SUPRESSAO`, porque contar o teto so no modo humano era
    # contar para quem nao le. O caso agora exige LINHAS TABULADAS ou vazio, nunca prosa, e proibe
    # HARD no verde. Teste que afirma "vazio" contra um contrato que passou a falar vira falso-alarme
    # — e falso-alarme em bancada e o que faz alguem afrouxar o caso em vez de ler o codigo.
    if { [ "${rc}" -eq 0 ] && { [ -z "${out}" ] || { printf '%s' "${out}" | grep -qP '^SOFT\t' && ! printf '%s' "${out}" | grep -qP '^HARD\t'; }; }; } \
       || { [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -qP '^HARD\t(MODO-SEM-TESTE|PISO-DE-COBERTURA)\t'; }; then
      record_pass "modos: (0) o proprio detector no modo --format tsv que a REGRA 59 consome"
    else record_fail "modos: (0) detector em tsv" "rc=${rc} com saida inesperada: $(printf '%s' "${out}" | head -c 200)"; fi
    rc=0; out="$(bash "${cmc}" --selftest 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '4 passaram, 0 falharam'; then
      record_pass "modos: (0b) o detector se prova (4/4) — guarda que nunca se provou nao sobe ao gate"
    else record_fail "modos: (0b) --selftest" "rc=${rc}: $(printf '%s' "${out}" | head -c 200)"; fi
  fi

  # (0e) PISO DE COBERTURA — a guarda de vacuidade so disparava em ZERO EXATO, e passada adversarial
  #      mediu a fuga: um refactor de estilo derrubou 32 pares para 11 e o veredito seguiu ✅. Um
  #      extrator que perde 2/3 da producao "cobre" tudo o que ainda ve, e o verde fala do que
  #      SOBROU, nao do que existe.
  # (0f) E A SUPRESSAO TEM DE APARECER NO MODO QUE O GATE CONSOME: o rodape vivia sob
  #      `if FORMAT != tsv`, entao a promessa "supressao CONTADA, nunca silenciosa" era FALSA
  #      justamente no unico modo que o lint invoca — 0 bytes. Contar para quem nao le e nao contar.
  local cmc2="${SCRIPT_DIR}/consumed-mode-check.sh"
  if [ ! -f "${cmc2}" ]; then record_skip "modos: (0e) consumed-mode-check.sh ausente"; else
    d="$(mktemp -d)"; mkdir -p "$d/.claude/validation"
    cp "${cmc2}" "$d/.claude/validation/"           # o marcador que liga o piso: o detector no root
    printf '#!/usr/bin/env bash\nbash "${SCRIPT_DIR}/alvo.sh" --modo\n' > "$d/.claude/validation/lint-artifacts.sh"
    printf '#!/usr/bin/env bash\nbash "${SCRIPT_DIR}/alvo.sh" --modo\n' > "$d/.claude/validation/lint-selftest.sh"
    rc=0; out="$(bash "${SCRIPT_DIR}/consumed-mode-check.sh" "$d" --format tsv 2>&1)" || rc=$?
    if [ "${rc}" -ne 0 ] && printf '%s' "${out}" | grep -q 'PISO-DE-COBERTURA'; then
      record_pass "modos: (0e) extrator que perde visao da producao REPROVA pelo PISO (cobertura, nao so ausencia)"
    else record_fail "modos: (0e) piso" "1 par contra piso 30 nao acusou (rc=${rc}): $(printf '%s' "${out}" | head -c 180)"; fi
    rm -rf "$d"
    # o piso NAO pode julgar repo sintetico — falso-positivo em regra HARD ensina a ignorar o gate
    rc=0; out="$(bash "${SCRIPT_DIR}/consumed-mode-check.sh" --selftest 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ]; then
      record_pass "modos: (0e2) o piso NAO acusa as fixtures do proprio --selftest (1 par, de proposito)"
    else record_fail "modos: (0e2) piso em fixture" "o piso acusou o proprio teste (rc=${rc}): $(printf '%s' "${out}" | head -c 180)"; fi
    # (0f) a supressao E VISIVEL no modo tsv
    rc=0; out="$(bash "${SCRIPT_DIR}/consumed-mode-check.sh" "${REPO_ROOT}" --format tsv 2>&1)" || rc=$?
    if printf '%s' "${out}" | grep -qP '^SOFT\tSUPRESSAO\t'; then
      record_pass "modos: (0f) a supressao aparece no --format tsv (o modo que o gate le), com o NUMERO"
    else record_fail "modos: (0f) supressao invisivel" "o tsv nao emitiu a linha de SUPRESSAO — 'contada, nunca silenciosa' seria falso no modo do gate"; fi
  fi

  # (0c)(0d) OS DOIS PARES QUE VIVIAM DA ISENCAO POR DELEGACAO. Ela foi REMOVIDA porque matava uma
  #          regra HARD: emudecendo so o ramo `tsv` do ladder, o `--selftest` dele seguia 8/8 verde,
  #          a REGRA 59 declarava o par coberto, e o lint parava de acusar (8 HARD -> 7).
  #          Aqui o modo `--format tsv` e exercitado DE VERDADE, e o caso assere que ele NAO E MUDO
  #          — que era exatamente a mutacao que passava despercebida.
  local ladder="${SCRIPT_DIR}/ladder-integrity-check.sh" kbv="${SCRIPT_DIR}/kb-vendored-link-check.sh"
  if [ ! -f "${ladder}" ]; then record_skip "modos: (0c) ladder-integrity-check.sh ausente"; else
    # o ladder resolve o registro por `${root}/.claude/validation/automation-ladder-registry.txt`
    # (linha 50-51) — nao ha env var. Entao a raiz E o sandbox, e a classe forjada vai no registro dele.
    d="$(mktemp -d)"; mkdir -p "$d/.claude/validation"
    cp "${REPO_ROOT}/.claude/validation/automation-ladder-registry.txt" "$d/.claude/validation/" 2>/dev/null \
      || : > "$d/.claude/validation/automation-ladder-registry.txt"
    printf 'forjada|AUTO|-\n' >> "$d/.claude/validation/automation-ladder-registry.txt"
    rc=0; out="$(bash "${SCRIPT_DIR}/ladder-integrity-check.sh" "$d" --format tsv 2>&1)" || rc=$?
    if [ "${rc}" -ne 0 ] && [ -n "${out}" ] && printf '%s' "${out}" | grep -q 'forjada'; then
      record_pass "modos: (0c) ladder --format tsv EMITE (classe forjada acusada, tabulada) — o ramo tsv nao e mudo"
    else record_fail "modos: (0c) ladder tsv" "o ramo tsv nao acusou a classe forjada (rc=${rc}, ${#out} bytes) — foi essa mutacao que a delegacao escondia"; fi
    rm -rf "$d"
  fi
  if [ ! -f "${kbv}" ]; then record_skip "modos: (0d) kb-vendored-link-check.sh ausente"; else
    # ⚠️ CAMINHO LITERAL, nao `${kbv}` — o extrator da REGRA 59 nao resolve variavel indireta, entao
    # a invocacao por variavel EXERCITA o modo e mesmo assim conta como descoberto. Medido: o caso
    # passava 762/0 e o detector seguia acusando o par. Escrever na forma que o instrumento le e
    # parte do contrato, e a alternativa (ensinar o extrator a resolver variavel) e outro ciclo.
    rc=0; out="$(bash "${SCRIPT_DIR}/kb-vendored-link-check.sh" "${REPO_ROOT}" --format tsv 2>&1)" || rc=$?
    # o contrato do modo tsv: silencio no verde, linhas TABULADAS no vermelho — nunca prosa
    if [ "${rc}" -le 1 ] && { [ -z "${out}" ] || printf '%s' "${out}" | grep -qP '\t'; }; then
      record_pass "modos: (0d) kb-vendored-link --format tsv respeita o contrato (vazio ou TABULADO, nunca prosa)"
    else record_fail "modos: (0d) kbv tsv" "rc=${rc} com saida nao-tabulada: $(printf '%s' "${out}" | head -c 200)"; fi
  fi

  # (a) inventory.sh --markdown: a producao compara ESTA saida com docs/onion/inventory.md.
  local inv="${SCRIPT_DIR}/inventory.sh"
  if [ ! -f "${inv}" ]; then record_skip "modos: (a) inventory.sh ausente"; else
    rc=0; out="$(bash "${inv}" --markdown 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '|' && printf '%s' "${out}" | grep -qiE 'coman|agent'; then
      record_pass "modos: (a) inventory.sh --markdown emite TABELA (o formato que a REGRA de SSOT compara)"
    else record_fail "modos: (a) inventory.sh --markdown" "rc=${rc}, saida sem tabela: $(printf '%s' "${out}" | head -c 200)"; fi
  fi

  # (b) kg-backlog-check.sh --format tsv: o modo que o LINT consome. Diferenca que importa: em tsv a
  #     linha OK nao sai (o consumidor trata vazio como verde), e a HARD sai TABULADA.
  local kbc="${SCRIPT_DIR}/kg-backlog-check.sh" bg="${REPO_ROOT}/docs/onion/graph/fios-abertos.kg.yaml"
  if [ ! -f "${kbc}" ] || [ ! -f "${bg}" ]; then record_skip "modos: (b) kg-backlog-check/backlog ausente"; else
    rc=0; out="$(bash "${kbc}" "${bg}" --format tsv 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
      record_pass "modos: (b) kg-backlog-check --format tsv CALA no verde (o lint trata vazio como conforme)"
    else record_fail "modos: (b) tsv no verde" "esperava saida VAZIA e rc=0; veio rc=${rc} out='${out}'"; fi
    d="$(mktemp -d)"; _fixture_done_nu "${bg}" "$d/m.yaml"
    rc=0; out="$(bash "${kbc}" "$d/m.yaml" --format tsv 2>&1)" || rc=$?
    if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -qP '^HARD\tDONE-NU\t'; then
      record_pass "modos: (b2) e no vermelho emite TSV tabulado (HARD<TAB>DONE-NU<TAB>...)"
    else record_fail "modos: (b2) tsv no vermelho" "rc=${rc}, formato inesperado: $(printf '%s' "${out}" | head -c 200)"; fi
    rm -rf "$d"
  fi

  # (c) kg-view.sh SEM flag: a producao o invoca assim, e o default TEM de ser o markdown que ela
  #     compara — um default que mude de forma quebra a REGRA 31 sem tocar em nenhuma flag.
  local view="${SCRIPT_DIR}/kg-view.sh" kg="${REPO_ROOT}/docs/onion/graph/fios-abertos.kg.yaml"
  if [ ! -f "${view}" ] || [ ! -f "${kg}" ]; then record_skip "modos: (c) kg-view/grafo ausente"; else
    local sem_flag com_flag
    rc=0; sem_flag="$(bash "${view}" "${kg}" 2>&1)" || rc=$?
    com_flag="$(bash "${view}" "${kg}" --markdown 2>&1 || true)"
    if [ "${rc}" -eq 0 ] && [ -n "${sem_flag}" ] && [ "${sem_flag}" = "${com_flag}" ]; then
      record_pass "modos: (c) kg-view SEM flag == --markdown (o default e o que a REGRA 31 compara)"
    else record_fail "modos: (c) kg-view default" "rc=${rc}; o default divergiu de --markdown (a producao invoca sem flag)"; fi
  fi

}

# _fixture_done_nu <src.kg.yaml> <dst.yaml> — produz um backlog cujo ÚNICO defeito é DONE-NU.
#
# ⚠️ POR QUE NÃO É MAIS `sed '0,/status: open/s//status: done/'`: aquela forma dependia de o backlog
#    VIVO ter pelo menos um nó `open`. Em 2026-08-10 o backlog foi colhido a zero abertos — que é o
#    ESTADO SAUDÁVEL, o alvo declarado do arquivo — e a mutação virou no-op silencioso. A bancada
#    passaria a medir o nada; só a guarda-da-guarda (`_prove_mutation`) impediu o falso-verde.
#    Fixture não pode depender do CONTEÚDO daquilo que ela testa: o arquivo vivo é livre para mudar.
#
# Duas costuras deliberadas: APPEND de um nó sintético (não depende de nenhum nó existente) e o TETO
# elevado a 999 na cópia, para que o único HARD possível seja DONE-NU — o nó extra poderia estourar o
# cap e trocar a acusação, fazendo o caso reprovar pela razão errada.
_fixture_done_nu() {
  local _src="$1" _dst="$2"
  sed -E 's/(#.*TETO:[[:space:]]*)[0-9]+/\1999/' "${_src}" > "${_dst}"
  cat >> "${_dst}" <<'FIXTURE_DONE_NU'

  - id: I_FIXTURE_DONE_SEM_CARIMBO
    node_type: decision
    plane: PROD
    status: done
    impact: 3
    confidence: 1.0
    label: "Fixture da bancada: declara done sem verified_at. Nao existe no backlog real."
FIXTURE_DONE_NU
}

# Modo vps-exposure — a guarda que vigia as duas condicoes que armam risco na VPS. Ela checa ESTADO
# VIVO (docker), nao codigo, e por isso CALA fora da VPS. O par que importa aqui e (a)/(b): sem ele,
# a guarda seria indistinguivel de uma que nunca funciona — foi exatamente a licao da jail do
# Fail2Ban, que nasceu MUDA lendo o journal em vez do arquivo e mostrava contador 0 nos dois casos.
run_vps_exposure_selftests() {
  local g="${SCRIPT_DIR}/vps-exposure-check.sh"
  if [ ! -f "${g}" ]; then record_fail "vps-exposure" "guarda ausente: ${g}"; return; fi

  # (a) FORA DA VPS a guarda CALA (exit 0) em vez de reprovar. Guarda que reprova por estar no lugar
  #     errado vira ruido e e desligada — e o CI e justamente o lugar sem docker.
  # ⚠️ O `bash` VAI POR CAMINHO ABSOLUTO, e o PATH aponta para um diretorio VAZIO — nao para um
  #    inexistente. A 1a versao fazia `PATH=/nonexistent bash ...` e o proprio `bash` deixava de ser
  #    encontrado: exit 127, que sob `set -e` MATOU A SUITE INTEIRA antes da soma. O caso nao testou
  #    nada e ainda derrubou os 390 seguintes. Mesma familia de `bancada-espelha-o-runner`: o
  #    ARTIFICIO do teste virou o defeito.
  local rc=0 out _emptydir
  _emptydir="$(mktemp -d)"
  if out="$(PATH="${_emptydir}" /bin/bash "${g}" 2>&1)"; then rc=0; else rc=$?; fi
  rm -rf "${_emptydir}"
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'fora do escopo'; then
    record_pass "vps-exposure: (a) sem docker a guarda CALA declarando fora-de-escopo, nunca aprova"
  else record_fail "vps-exposure: (a)" "sem docker deveria sair 0 declarando escopo (rc=${rc}): ${out}"; fi

  # (b) O MODO TSV existe e e o que um consumidor leria. Sem isto, ligar a guarda noutro lugar
  #     exigiria parsear prosa — e prosa muda.
  rc=0; out="$(bash "${g}" --format tsv 2>&1)" || rc=$?
  if [ "${rc}" -le 1 ]; then
    record_pass "vps-exposure: (b) --format tsv roda e devolve rc<=1 (0 limpo, 1 com achado)"
  else record_fail "vps-exposure: (b)" "--format tsv devolveu rc=${rc} (esperado 0 ou 1): ${out}"; fi

  # (d) A TERCEIRA CONDICAO — backup em claro. Nasceu de 19 dumps `root:root 644` em disco (o banco
  #     de IDENTIDADES) e, na passada adversarial contra a propria guarda, de mais 17 no diretorio do
  #     bridge que o escopo NAO cobria. Guarda com escopo menor que a classe e verde-vazia onde nao
  #     olha — por isso o caso testa o DETECTOR, com diretorio proprio, e nao o estado do disco.
  local _bd; _bd="$(mktemp -d)"
  : > "${_bd}/dump-em-claro.sql"
  rc=0; out="$(BACKUP_DIRS_OVERRIDE="${_bd}" bash "${g}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'BACKUP-EM-CLARO'; then
    record_pass "vps-exposure: (d) arquivo sem .gpg em diretorio de backup e ACUSADO"
  else record_fail "vps-exposure: (d)" "backup em claro nao foi acusado (rc=${rc}): ${out}"; fi
  # (d2) e CALA quando tudo esta cifrado — sem este par a regra poderia acusar sempre
  rm -f "${_bd}/dump-em-claro.sql"; : > "${_bd}/dump.sql.gpg"
  rc=0; out="$(BACKUP_DIRS_OVERRIDE="${_bd}" bash "${g}" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'BACKUP-EM-CLARO'; then
    record_fail "vps-exposure: (d2)" "acusou um diretorio 100% cifrado: ${out}"
  else record_pass "vps-exposure: (d2) cala quando todo artefato tem .gpg"; fi
  rm -rf "${_bd}"

  # (c) MUTATION — a guarda-da-guarda. Se o predicado de bind for apagado, a regra vira verde-vazia.
  #     Este caso prova que a clausula e LOAD-BEARING, e nao decoracao.
  local d; d="$(mktemp -d)"
  # ⚠️ ESTE `sed` JA FOI NO-OP DUAS VEZES, e a guarda-da-guarda abaixo pegou as duas. O padrao
  #    original tentava casar a alternancia inteira do `case` e o escape se perdia ao atravessar o
  #    heredoc que gerava este bloco. Agora e literal e simples: casa so `0.0.0.0:*`, que basta para
  #    provar que o predicado de bind e um alvo REAL no arquivo — que e o que este caso afirma.
  sed 's/0\.0\.0\.0:\*/__NUNCA_CASA__:*/' "${g}" > "$d/mut.sh"
  if cmp -s "${g}" "$d/mut.sh"; then
    record_fail "vps-exposure: (c)" "GUARDA-DA-GUARDA: a mutacao NAO foi aplicada (arquivos identicos) — o sed virou no-op"
  else
    record_pass "vps-exposure: (c) MUTATION aplicada — o predicado de bind e um alvo real no arquivo"
  fi
  rm -rf "$d"
}

run_kg_backlog_selftests() {
  local helper="${SCRIPT_DIR}/kg-backlog-check.sh"
  local bg="${REPO_ROOT}/docs/onion/graph/fios-abertos.kg.yaml"
  if [ ! -f "${helper}" ]; then record_fail "kg-backlog" "helper ausente: ${helper}"; return; fi
  if [ ! -f "${bg}" ]; then record_skip "kg-backlog: grafo de backlog ausente"; return; fi
  local d rc out
  d="$(mktemp -d)"

  # (a) o backlog REAL passa — sem isto, todos os mutantes abaixo provariam o nada (fixture morta)
  rc=0; out="$(bash "${helper}" "${bg}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "kg-backlog: (a) o backlog vivo do repo PASSA (intacto satisfaz o caso)"
  else record_fail "kg-backlog: (a)" "o backlog real ja reprova (rc=${rc}): ${out}"; fi

  # (b) DONE-NU — o coracao. A REGRA 49 NAO alcanca este arquivo (ele e todo `plane: DEV`, de
  #     proposito), entao declarar `done` sem carimbo saia DE GRACA antes desta guarda.
  _fixture_done_nu "${bg}" "$d/done.yaml"
  local rc_int rc_mut
  rc_int=0; bash "${helper}" "${bg}" >/dev/null 2>&1 || rc_int=$?
  rc_mut=0; out="$(bash "${helper}" "$d/done.yaml" 2>&1)" || rc_mut=$?
  _prove_mutation "kg-backlog: (b) item \`done\` SEM carimbo REPROVA — quem nao carimba nao declara feito" \
                  "${bg}" "$d/done.yaml" "${rc_int}" "${rc_mut}"
  # a mensagem faz parte do contrato: quem le tem de saber QUAL item e o QUE falta
  if printf '%s' "${out}" | grep -q 'DONE-NU' && printf '%s' "${out}" | grep -q 'verified_at=AUSENTE'; then
    record_pass "kg-backlog: (b2) a acusacao NOMEIA o item e o campo que falta"
  else record_fail "kg-backlog: (b2)" "acusacao sem diagnostico acionavel: ${out}"; fi

  # (b3) A FIXTURE NAO PODE DEPENDER DO CONTEUDO DO ARQUIVO VIVO — e este caso e o unico jeito de
  #      saber. Em 2026-08-10 o backlog foi colhido a ZERO abertos (o estado SAUDAVEL, que o arquivo
  #      existe para perseguir) e o `sed '0,/status: open/s//done/'` das fixtures virou no-op: os
  #      casos (b) e (e) passaram a comparar dois arquivos IDENTICOS. Em (b) a guarda-da-guarda
  #      gritou; em (e) NAO HAVIA guarda-da-guarda, e ele teria medido o nada em silencio.
  #      Aqui a fonte tem zero `open` POR CONSTRUCAO: se alguem voltar a mutar no existente, este
  #      caso reprova na hora, sem depender de o backlog real estar num estado ou noutro.
  sed -E 's/^([[:space:]]*status:)[[:space:]]*open[[:space:]]*$/\1 confirmed/' "${bg}" > "$d/sem-abertos.yaml"
  if grep -qE '^[[:space:]]*status:[[:space:]]*open[[:space:]]*$' "$d/sem-abertos.yaml"; then
    record_fail "kg-backlog: (b3)" "a fonte do caso ainda tem \`open\` — o caso mediria a situacao errada"
  else
    _fixture_done_nu "$d/sem-abertos.yaml" "$d/sem-abertos-mutado.yaml"
    rc=0; out="$(bash "${helper}" "$d/sem-abertos-mutado.yaml" 2>&1)" || rc=$?
    if [ "${rc}" -ne 0 ] && printf '%s' "${out}" | grep -q 'DONE-NU'; then
      record_pass "kg-backlog: (b3) a fixture funciona com o backlog ZERADO — nao depende do conteudo do vivo"
    else record_fail "kg-backlog: (b3)" "sem nenhum \`open\` na fonte a fixture nao produziu DONE-NU (rc=${rc}): ${out}"; fi
  fi

  # (c) TETO lido DO ARQUIVO. Passar do teto reprova; e o numero da mensagem vem do `meta:`,
  #     nunca de constante no script — um numero aqui e outro la seria o mesmo
  #     `declarado != verificado` que esta regra existe para fechar.
  # A fixture NAO pode assumir que o vivo esta NO teto (classe (b3), reincidiu em 2026-08-31:
  # a colheita da Onda 6 deixou o vivo em 7 nos, +3 fixos = 10/20 e o caso "passou" sem morder).
  # Enche ate ULTRAPASSAR o teto declarado no proprio arquivo, contando os nos existentes.
  _declared_cap=$(grep -oE 'TETO:[[:space:]]*[0-9]+' "${bg}" | head -1 | grep -oE '[0-9]+')
  _existing_nodes=$(grep -cE '^[[:space:]]*- id: ' "${bg}")
  _fillers_needed=$(( _declared_cap + 1 - _existing_nodes )); [ "${_fillers_needed}" -lt 1 ] && _fillers_needed=1
  awk -v n="${_fillers_needed}" '/^edges:/ && !done { for (k=0;k<n;k++) printf "    - id: N_ENCHENDO_%d\n      node_type: question\n      plane: DEV\n      status: open\n      impact: 1\n      confidence: 1.0\n      label: \"enchendo %d\"\n\n", k, k; done=1 } {print}' \
    "${bg}" > "$d/teto.yaml"
  rc=0; out="$(bash "${helper}" "$d/teto.yaml" 2>&1)" || rc=$?
  if [ "${rc}" -ne 0 ] && printf '%s' "${out}" | grep -q 'TETO' && printf '%s' "${out}" | grep -q 'teto declarado 20'; then
    record_pass "kg-backlog: (c) passar do TETO reprova, citando o numero que esta no \`meta:\`"
  else record_fail "kg-backlog: (c)" "teto nao mordeu ou nao citou o numero do arquivo (rc=${rc}): ${out}"; fi

  # (d) FAIL-LOUD: `meta:` sem TETO declarado e HARD, nunca silencio. Guarda que nao sabe o que
  #     cobrar jamais afirma conformidade (P0 da REGRA 30) — e "sem teto" e indistinguivel de
  #     "teto zero" para quem so olha o exit code.
  grep -v 'TETO: 20' "${bg}" > "$d/semteto.yaml"
  rc=0; out="$(bash "${helper}" "$d/semteto.yaml" 2>&1)" || rc=$?
  if [ "${rc}" -ne 0 ] && printf '%s' "${out}" | grep -q 'SEM-TETO'; then
    record_pass "kg-backlog: (d) \`meta:\` sem TETO e HARD SEM-TETO (fail-loud, nunca conformidade por ausencia)"
  else record_fail "kg-backlog: (d)" "sem o teto declarado a guarda ficou calada (rc=${rc}): ${out}"; fi


  # (e) A ACUSACAO TEM DE CONTAR, nao so aparecer. Fail-open MEDIDO na 1a versao desta regra:
  #     `violation()` incrementa HARD_COUNT no shell PAI, e `printf | while read` roda o laco em
  #     SUBSHELL — o incremento morre com ele. O efeito e o pior possivel: a linha `VIOLATION:` sai
  #     na tela, o humano ve a acusacao, e o lint FECHA COM EXIT 0. Guarda que acusa e nao conta e
  #     PIOR que guarda ausente: produz a aparencia de rigor. Medido: 8 HARD com process
  #     substitution, 7 com o pipe — mesma acusacao impressa nas duas.
  # (e) ATRAVESSA O GATE, nao o helper — e esta e a CURA DE RAIZ que o Elenxo cobrou.
  #     Os casos (a)-(d) rodam `bash "${helper}"` direto. O juiz mediu a consequencia e ela e total:
  #     `grep -c check_kg_backlog lint-selftest.sh` = 0, entao a bancada ficava 5/5 VERDE com o
  #     fail-open de contagem ATIVO **e** com `check_kg_backlog` comentado fora do dispatcher.
  #     Helper verde nao e gate verde. E a licao `bancada-espelha-o-runner` na sua forma mais cara:
  #     o teste media um artefato que NAO E o que barra o merge.
  #     Este caso planta a violacao, roda o LINT INTEIRO num sandbox git, e exige que o CONTADOR
  #     suba — nao que a linha apareca. Cobre de uma vez: o subshell, o fio no dispatcher, e o
  #     escopo (se o arquivo sair de escopo, o contador nao sobe e o caso reprova).
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_skip "kg-backlog: (e) lint-artifacts.sh ausente"; else
    local sb h_ctrl h_mut
    sb="$(mktemp -d)"
    if git -C "${REPO_ROOT}" archive HEAD 2>/dev/null | tar -x -C "${sb}" 2>/dev/null &&
       cp "${lint}" "${helper}" "${sb}/.claude/validation/" 2>/dev/null &&
       cp "${bg}" "${sb}/docs/onion/graph/" 2>/dev/null; then
      ( cd "${sb}" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm b ) >/dev/null 2>&1
      # ⚠️ `|| true` OBRIGATORIO: o lint SAI NAO-ZERO quando acha HARD, que e o ponto dele — e
      #    `x="$(cmd)"` sob `set -e` ABORTA a suite inteira quando cmd falha. Esta armadilha ja
      #    matou a bancada duas vezes nesta sessao; aqui ela e GARANTIDA, porque o mutante EXISTE
      #    para produzir HARD.
      h_ctrl="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
      h_ctrl="$(printf '%s' "${h_ctrl}" | sed -n 's/.*Violações HARD *: *\([0-9]*\).*/\1/p' | tail -1)"
      # mesma razão de (b): mutar um `open` existente depende do CONTEÚDO do arquivo vivo, e o
      # backlog zerado torna o `sed` um no-op. Aqui não há `_prove_mutation` para avisar — o caso
      # apenas compararia dois lints idênticos e passaria a medir o nada.
      _fixture_done_nu "${sb}/docs/onion/graph/fios-abertos.kg.yaml" "${sb}/.done-nu.tmp"
      mv "${sb}/.done-nu.tmp" "${sb}/docs/onion/graph/fios-abertos.kg.yaml"
      h_mut="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
      h_mut="$(printf '%s' "${h_mut}" | sed -n 's/.*Violações HARD *: *\([0-9]*\).*/\1/p' | tail -1)"
      if [ -z "${h_ctrl}" ] || [ -z "${h_mut}" ]; then
        record_fail "kg-backlog: (e) atravessa o gate" "nao consegui ler o contador HARD do lint (ctrl='${h_ctrl}' mut='${h_mut}') — o caso mediria o nada"
      elif [ "${h_mut}" -gt "${h_ctrl}" ]; then
        record_pass "kg-backlog: (e) a violacao CONTA no lint inteiro (HARD ${h_ctrl}→${h_mut}), nao so aparece"
      else record_fail "kg-backlog: (e) FAIL-OPEN" "o lint imprimiu a acusacao e o contador NAO subiu (HARD ${h_ctrl}→${h_mut}): subshell, fio solto no dispatcher, ou arquivo fora de escopo"; fi
    else record_skip "kg-backlog: (e) sandbox git nao montou"; fi
    rm -rf "${sb}"
  fi

  rm -rf "$d"
}

run_kg_ratchet_direction_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/kg-verification-coverage.sh"
  if [ ! -f "${helper}" ]; then record_fail "kg-catraca" "helper ausente"; return; fi
  local d out mut

  # $1=dir $2=status $3=impact $4=plane $5=verified_at $6=aresta $7=id(default C_ALVO)
  # $6 = "" (nenhuma) | "TIPO" (entrando, o canônico) | "TIPO:in" | "TIPO:out" | "TIPO:self"
  # A DIREÇÃO e a IDENTIDADE das pontas viraram parâmetro porque o Elenxo mostrou que 5 mutações da
  # guarda sobreviviam 9/9 sem elas: a fixture só sabia fabricar `refuted` + REFUTES entrando.
  _graph49() {
    mkdir -p "$1/docs/onion/graph"
    { printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n'
      printf '  - id: %s\n    node_type: claim\n    plane: %s\n    impact: %s\n    status: %s\n' "${7:-C_ALVO}" "$4" "$3" "$2"
      # `if`, e nao `[ -n "$X" ] && printf`: sob `set -e` o `&&` com condicao FALSA devolve 1, e como
      # este e o ULTIMO comando do grupo, a funcao inteira devolvia 1 e MATAVA a bancada na primeira
      # fixture sem aresta — antes de qualquer caso rodar. Medido em 2026-08-08.
      if [ -n "$5" ]; then printf '    verified_at: %s\n' "$5"; fi
      printf '    label: "x"\n'
      if [ -n "$6" ]; then
        local _t="${6%%:*}" _dir="${6#*:}" _no="${7:-C_ALVO}" _de _para
        [ "${_dir}" = "$6" ] && _dir=in          # sem sufixo → ENTRANDO (o caso canônico do corpus)
        case "${_dir}" in
          out)  _de="${_no}"; _para=E_OUTRO ;;   # o nó REFUTA outro — não reconcilia a si
          self) _de="${_no}"; _para="${_no}" ;;  # nó não se refuta sozinho
          *)    _de=E_OUTRO;  _para="${_no}" ;;
        esac
        printf 'edges:\n  - from: %s\n    edge_type: %s\n    to: %s\n' "${_de}" "${_t}" "${_para}"
      fi
    } > "$1/docs/onion/graph/t.kg.yaml"
  }
  _commit49() { ( cd "$1" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm x ) 2>/dev/null; }
  # nasce EM CONFORMIDADE (confirmed/PROD/5, no baseline) e só DEPOIS muda — é a única forma de
  # exercitar a SAÍDA do escopo, que é o que este guarda julga.
  # ⚠️ o baseline é COMMITADO: o guarda compara `prev ∪ known`, e sem baseline no HEAD o `prev` fica
  # vazio e a metade que fecha o bypass do `grep -v` nunca é exercitada.
  _scene49() { local dir="$1"; shift
    _graph49 "${dir}" confirmed 5 PROD "" ""
    _commit49 "${dir}"
    mkdir -p "${dir}/.claude/validation"
    bash "${helper}" "${dir}" --emit-baseline > "${dir}/.claude/validation/kg-verification-baseline.txt" 2>/dev/null
    ( cd "${dir}" && git add -A && git -c user.email=t@t -c user.name=t commit -qm baseline ) >/dev/null 2>&1
    _graph49 "${dir}" "$@"
  }
  _tags49() { printf '%s' "$1" | awk -F'\t' 'NF>1 {print $1":"$2}' | sort -u | tr '\n' ' '; }
  # roda o helper SEM subshell, para que o EXIT sobreviva: nenhum caso da 1ª versão aferia o exit do
  # gate, e por isso zerar o `hard=$((hard+1))` do FUGA-DE-ESCOPO passava 9/9.
  # ⚠️ GUARDA O STDERR. Antes era `2>/dev/null`: o UNICO canal em que o gate grita erro era
  # exatamente o que a bancada jogava fora, entao um helper que explodisse passaria como "sem
  # violacao". Os casos exigem ERR49 VAZIO — silencio no stderr faz parte do contrato.
  _run49() { RC49=0; ERR49="$(mktemp)"; OUT49="$(bash "${helper}" "$1" --format tsv 2>"${ERR49}")" || RC49=$?; }
  _err49() { [ -s "${ERR49:-/dev/null}" ] && printf 'STDERR: %s' "$(head -c 200 "${ERR49}")" || printf ''; }

  # (h) O ENUM QUE CRESCEU: allowlist quebra, denylist nao. `drifted`/`unverifiable`/`done` sao
  #     status VIVOS e tem de continuar DENTRO do escopo — `drifted` mais que todos, porque e o
  #     estado em que a reconciliacao e DEVIDA.
  local st outside=""
  for st in drifted unverifiable done open confirmed; do
    d="$(mktemp -d)"; _graph49 "$d" "${st}" 5 PROD "" ""; _commit49 "$d"
    mkdir -p "$d/.claude/validation"; printf '# vazio\n' > "$d/.claude/validation/kg-verification-baseline.txt"
    out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
    printf '%s' "${out}" | grep -q '^HARD.*NOVO' || outside="${outside} ${st}"
  done
  if [ -z "${outside}" ]; then
    record_pass "kg-catraca: (h) drifted/unverifiable/done/open/confirmed DENTRO do escopo (denylist nao quebra quando o enum cresce)"
  else record_fail "kg-catraca: (h)" "status VIVO fora do escopo — allowlist de volta:${outside}"; fi

  # (i) O FAIL-OPEN EM ESPECIE: no do baseline reetiquetado para `drifted`, sem medir nada.
  #     Nao pode sair do escopo, e nao pode aparecer NENHUMA mensagem de saida.
  d="$(mktemp -d)"; _scene49 "$d" drifted 5 PROD "" ""
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if [ "$(_tags49 "${out}")" = "SOFT:PASSIVO " ]; then
    record_pass "kg-catraca: (i) confirmed→drifted NU segue no escopo (o fail-open que fundou o bloco)"
  else record_fail "kg-catraca: (i)" "a reetiqueta tirou o no do escopo — fail-open ativo. tags: $(_tags49 "${out}")"; fi

  # (j) fuga por reetiqueta NUA para refuted (sem a aresta que a justifica) -> HARD **e exit 1**
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" ""
  _run49 "$d"
  if printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD" && $2=="FUGA-SEM-ARESTA"{f=1} END{exit !f}' && [ "${RC49}" -ne 0 ]; then
    record_pass "kg-catraca: (j) confirmed→refuted SEM aresta → HARD FUGA-SEM-ARESTA E exit != 0"
  else record_fail "kg-catraca: (j)" "reetiqueta nua escapou (exit=${RC49}): $(_tags49 "${OUT49}")"; fi

  # (k) ANTI-FALSO-POSITIVO, e e o caso mais importante do bloco: refutar COM a aresta e
  #     CONFORMIDADE. Guarda que pune quem obedece e pior que guarda nenhuma — os tres
  #     falsos-positivos HARD que o Elenxo da REGRA 57 derrubou eram exatamente esta forma.
  #     No corpus real ha 3 nos assim (C2_AUTOMATE_READY, C_VERTICALS_EMPTY, E_ORBIT).
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" REFUTES
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '$1=="HARD"{h=1} $2=="RECONCILIADO"{r=1} END{exit !(r && !h)}'; then
    record_pass "kg-catraca: (k) refuted COM aresta REFUTES entrando → SOFT RECONCILIADO, ZERO HARD (nao pune conformidade)"
  else record_fail "kg-catraca: (k)" "acusou uma CONFORMIDADE: $(_tags49 "${out}")"; fi

  # (k') a METADE `superseded` do mapa. Inverter o tipo exigido sobrevivia 9/9 porque nenhum caso
  #      exercitava este status — e o `kg-radar.sh:620-621` SANCIONA reconciliar um REFUTES como
  #      `superseded`, logo os dois tipos tem de valer para os dois status.
  local pair failed_pair=""
  for pair in "superseded SUPERSEDES" "superseded REFUTES" "refuted SUPERSEDES"; do
    set -- ${pair}
    d="$(mktemp -d)"; _scene49 "$d" "$1" 5 PROD "" "$2"
    out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
    printf '%s' "${out}" | awk -F'\t' '$1=="HARD"{h=1} $2=="RECONCILIADO"{r=1} END{exit !(r && !h)}' || failed_pair="${failed_pair} ${1}+${2}"
  done
  if [ -z "${failed_pair}" ]; then
    record_pass "kg-catraca: (k') os 4 pares status×tipo de reconciliacao valem — o tipo NAO se deriva do status (kg-radar sanciona o fork)"
  else record_fail "kg-catraca: (k')" "par legitimo acusado:${failed_pair}"; fi

  # (k2) o TIPO da aresta importa: SUPPORTS nao reconcilia nada. Remover o `et == T` sobrevivia 9/9.
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" SUPPORTS
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '$1=="HARD" && $2=="FUGA-SEM-ARESTA"{f=1} END{exit !f}'; then
    record_pass "kg-catraca: (k2) aresta SUPPORTS NAO compra reconciliacao → HARD (o tipo e load-bearing)"
  else record_fail "kg-catraca: (k2)" "qualquer aresta virou alibi: $(_tags49 "${out}")"; fi

  # (q) DIRECAO — o no como `from` da aresta. Achado do Elenxo no corpus REAL: 8 das 48 entradas do
  #     baseline sao `from` de um REFUTES/SUPERSEDES e fugiam com UM `sed`, sem forjar nada.
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" REFUTES:out
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '$1=="HARD" && $2=="FUGA-SEM-ARESTA"{f=1} END{exit !f}'; then
    record_pass "kg-catraca: (q) aresta SAINDO nao reconcilia — quem refuta outro nao se refuta → HARD"
  else record_fail "kg-catraca: (q)" "rota da direcao aberta (8/48 do corpus real): $(_tags49 "${out}")"; fi

  # (r) DUAS PONTAS — `from: X / to: X`. Tres linhas compravam RECONCILIADO.
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" REFUTES:self
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '$1=="HARD" && $2=="FUGA-SEM-ARESTA"{f=1} END{exit !f}'; then
    record_pass "kg-catraca: (r) self-edge nao reconcilia — um no nao se refuta sozinho → HARD"
  else record_fail "kg-catraca: (r)" "self-edge comprou a saida: $(_tags49 "${out}")"; fi

  # (s) O BYPASS TOTAL: reetiquetar E apagar a linha do baseline no MESMO commit. A 1a versao iterava
  #     so o baseline ATUAL, entao a chave apagada sumia do julgamento — `exit=0`, zero VIOLATION,
  #     48→47. O julgamento agora e dirigido por `prev ∪ known`.
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" ""
  : > "$d/.claude/validation/kg-verification-baseline.txt"      # o operador apaga o rastro junto
  _run49 "$d"
  if printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD"{h=1} END{exit !h}' && [ "${RC49}" -ne 0 ]; then
    record_pass "kg-catraca: (s) reetiqueta + linha apagada no mesmo commit → HARD e exit != 0 (o bypass total)"
  else record_fail "kg-catraca: (s)" "apagar o rastro ainda liberta (exit=${RC49}): $(_tags49 "${OUT49}")"; fi

  # (l) fuga por rebaixamento de impact/plane — sair do escopo tambem e sair. Afere o EXIT tambem:
  #     zerar o contador `hard` do FUGA-DE-ESCOPO sobrevivia a bancada inteira.
  local route broken=""
  for route in "5 DEV" "3 PROD"; do
    set -- ${route}
    d="$(mktemp -d)"; _scene49 "$d" confirmed "$1" "$2" "" ""
    _run49 "$d"
    printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD" && $2=="FUGA-DE-ESCOPO"{f=1} END{exit !f}' || broken="${broken} impact=$1/plane=$2(tag)"
    [ "${RC49}" -ne 0 ] || broken="${broken} impact=$1/plane=$2(exit=0)"
  done
  if [ -z "${broken}" ]; then
    record_pass "kg-catraca: (l) rebaixar plane ou impact → HARD FUGA-DE-ESCOPO E exit != 0"
  else record_fail "kg-catraca: (l)" "rota de fuga aberta:${broken}"; fi

  # (m) a saida LEGITIMA: o no foi medido -> SOFT CARIMBADO, e a mensagem cita a data
  d="$(mktemp -d)"; _scene49 "$d" confirmed 5 PROD 2026-08-08 ""
  out="$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)"
  if printf '%s' "${out}" | awk -F'\t' '$1=="HARD"{h=1} $2=="CARIMBADO" && $4 ~ /2026-08-08/{c=1} END{exit !(c && !h)}'; then
    record_pass "kg-catraca: (m) verified_at aposto → SOFT CARIMBADO citando a data, zero HARD (a saida que o gate EXISTE para produzir)"
  else record_fail "kg-catraca: (m)" "a medicao nao foi reconhecida: $(_tags49 "${out}")"; fi

  # (n) no que sumiu do arquivo -> SOFT REMOVIDO (ato visivel no diff, nao fuga silenciosa)
  # afere a SEVERIDADE, nao so a presenca da tag: trocar `emit SOFT REMOVIDO` por HARD sobrevivia 9/9
  # o substituto nasce CARIMBADO de proposito: sem isso ele e um no NOVO em escopo e gera um
  # `HARD NOVO` legitimo, que afogaria a severidade e o exit que este caso existe para aferir.
  d="$(mktemp -d)"; _scene49 "$d" confirmed 5 PROD 2026-08-08 "" C_OUTRO
  _run49 "$d"
  # ⚠️ A SEVERIDADE MUDOU EM 2026-08-08, e a razao esta na porta que este par de casos fechou:
  # apagar o no ENCOLHE o baseline sem medir nada. O grafo JA TEM a forma honesta de aposentar um
  # no — `superseded`/`refuted` COM a aresta — e ela sai SOFT pelo ramo RECONCILIADO. Deletar e o
  # atalho que pula a aresta, entao vira HARD.
  if printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD" && $2=="REMOVIDO" && $4 ~ /superseded\/refuted/ && $4 ~ /aresta/ {r=1} END{exit !r}' \
     && [ "${RC49}" -ne 0 ] && [ -z "$(_err49)" ]; then
    record_pass "kg-catraca: (n) no APAGADO do corpus → HARD REMOVIDO e exit != 0 (apagar nao descarrega a medicao)"
  else record_fail "kg-catraca: (n)" "classificacao/severidade errada (exit=${RC49}): $(_tags49 "${OUT49}")"; fi

  # (u) MOVER NAO E REMOVER — e mover PARA FORA DO ESCOPO e o esvaziamento em lote.
  #     Porta reproduzida no corpus REAL: um `git mv` de UM grafo para `fixtures/` tirava CINCO
  #     entradas do baseline de uma vez, com `exit 0`, cinco SOFT, e o gate MANDANDO remove-las —
  #     com os nos intactos no disco, versionados, afirmando sobre producao.
  d="$(mktemp -d)"; _scene49 "$d" confirmed 5 PROD "" ""
  mkdir -p "$d/docs/onion/graph/fixtures"
  ( cd "$d" && git mv docs/onion/graph/t.kg.yaml docs/onion/graph/fixtures/t.kg.yaml ) >/dev/null 2>&1
  _run49 "$d"
  if printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD" && $2=="MUDOU-DE-PATH" && $4 ~ /fixtures\// {m=1} END{exit !m}' \
     && [ "${RC49}" -ne 0 ] && [ -z "$(_err49)" ]; then
    record_pass "kg-catraca: (u) git mv para fixtures/ → HARD MUDOU-DE-PATH (o no segue no disco; mover nao e medir)"
  else record_fail "kg-catraca: (u)" "esvaziamento em lote de volta (exit=${RC49}): $(_tags49 "${OUT49}")"; fi
  rm -rf "$d"

  # (u2) ANTI-FALSO-POSITIVO, e e o caso que impede a cura de virar punicao: mover para outro path
  #      VIVO e reorganizacao. Tem de sair SOFT — e, com a chave reescrita no baseline (o fluxo
  #      legitimo completo), o gate tem de fechar em exit 0.
  d="$(mktemp -d)"; _scene49 "$d" confirmed 5 PROD "" ""
  ( cd "$d" && mkdir -p docs/onion/outro && git mv docs/onion/graph/t.kg.yaml docs/onion/outro/t.kg.yaml \
      && sed -i 's#^docs/onion/graph/t.kg.yaml::#docs/onion/outro/t.kg.yaml::#' .claude/validation/kg-verification-baseline.txt ) >/dev/null 2>&1
  _run49 "$d"
  if printf '%s' "${OUT49}" | awk -F'\t' '$1=="SOFT" && $2=="MUDOU-DE-PATH" && $4 ~ /reescreva a chave/ {m=1} $1=="HARD"{h=1} END{exit !(m && !h)}' \
     && [ "${RC49}" -eq 0 ] && [ -z "$(_err49)" ]; then
    record_pass "kg-catraca: (u2) mover para path VIVO com a chave reescrita → SOFT e exit 0 (reorganizar nao e fugir)"
  else record_fail "kg-catraca: (u2)" "punindo reorganizacao legitima (exit=${RC49}): $(_tags49 "${OUT49}")"; fi
  rm -rf "$d"

  # (t) O SEPARADOR DE REGISTRO INTERNO — e o caso acusa a guarda punindo quem OBEDECE.
  #     TAB e IFS-WHITESPACE: campo vazio SOME e o resto desliza. Cenario reproduzido: no MEDIDO e
  #     CARIMBADO que nao tem campo `status` — o `ver` escorregava para a posicao do `st` e a guarda
  #     emitia `HARD FUGA-DE-ESCOPO … status:2026-08-08`, acusando de FUGIR justamente quem acabou
  #     de medir. `\037` (US) nao e whitespace, entao cada ocorrencia separa e o campo vazio fica.
  #     LATENTE no corpus, e o numero vem COM o comando que o produz — numero sem comando dentro do
  #     comentario de um caso que cura a REGRA 49 e o defeito da 49 cometido no instrumento:
  #       git ls-files '*.kg.yaml' | grep -v /fixtures/ | xargs grep -hcE "^[[:space:]]*-[[:space:]]*id:"
  #       → 2159 nos em 2026-08-08, ZERO sem campo `status` (e o kg-radar-integrity ja reprova isso).
  #     Mas era REGRESSAO contra o script antigo, que emitia SOFT no mesmo cenario. A PROVA de que
  #     este caso discrimina nao e o sweep — e rodar a bancada contra
  #     `git show main:.claude/validation/kg-verification-coverage.sh`: da 1 FAIL, e o FAIL e este.
  #     (O caso monta o cenario a mao em vez de usar `_scene49` DE PROPOSITO: a fixture do `_scene49`
  #     sempre escreve `status`, e e a AUSENCIA dele que este caso mede. Nao "conserte" a duplicacao.)
  d="$(mktemp -d)"; mkdir -p "$d/docs/onion/graph" "$d/.claude/validation"
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: C_ALVO\n    node_type: claim\n    plane: PROD\n    impact: 5\n    status: confirmed\n    label: "x"\n' > "$d/docs/onion/graph/t.kg.yaml"
  _commit49 "$d"
  bash "${helper}" "$d" --emit-baseline > "$d/.claude/validation/kg-verification-baseline.txt" 2>/dev/null
  ( cd "$d" && git add -A && git -c user.email=t@t -c user.name=t commit -qm b ) >/dev/null 2>&1
  # o no e MEDIDO e CARIMBADO — e perde o campo `status` (o gatilho do colapso)
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: C_ALVO\n    node_type: claim\n    plane: PROD\n    impact: 5\n    verified_at: 2026-08-08\n    label: "x"\n' > "$d/docs/onion/graph/t.kg.yaml"
  _run49 "$d"
  if printf '%s' "${OUT49}" | awk -F'\t' '$1=="SOFT" && $2=="CARIMBADO"{c=1} $1=="HARD"{h=1} END{exit !(c && !h)}' && [ "${RC49}" -eq 0 ]; then
    record_pass "kg-catraca: (t) campo vazio NAO desloca o registro — o no medido leva SOFT CARIMBADO e exit 0 (TAB e IFS-whitespace, \\037 nao)"
  else record_fail "kg-catraca: (t)" "colapso de campo de volta (exit=${RC49}): $(_tags49 "${OUT49}")"; fi

  # (t2) O IRMAO DO (t): `plane` AUSENTE, o outro campo que colapsa. Achado pelo Elenxo, e o par
  #      fecha os DOIS unicos campos do registro que podem faltar. Nao e fail-open (HARD nos dois),
  #      mas em `main` a mensagem era MENTIROSA — `plane:5 impact:confirmed status:<vazio>`, com os
  #      valores deslocados uma casa — e agora e verdadeira. Guarda cuja MENSAGEM mente ensina a
  #      ignorar a guarda, que e a mesma familia do falso-positivo.
  #      (nao ha commit aqui de proposito: o `prev` que a catraca le ja veio do commit do baseline
  #      feito no (t). Um `git commit` sem nada a commitar sai 1, e sob `set -e` o subshell derruba
  #      a suite — foi exatamente o que aconteceu na 1a escrita deste caso.)
  printf 'meta:\n  id: t\n  schema_version: "1"\nnodes:\n  - id: C_ALVO\n    node_type: claim\n    impact: 5\n    status: confirmed\n    label: "x"\n' > "$d/docs/onion/graph/t.kg.yaml"
  _run49 "$d"
  if printf '%s' "${OUT49}" | awk -F'\t' '$2=="FUGA-DE-ESCOPO" && $4 ~ /impact:5/ && $4 ~ /status:confirmed/{ok=1} END{exit !ok}'; then
    record_pass "kg-catraca: (t2) com 'plane' ausente a mensagem diz a VERDADE (impact:5 status:confirmed), nao os campos deslocados uma casa"
  else record_fail "kg-catraca: (t2)" "mensagem deslocada de volta: $(printf '%s' "${OUT49}" | cut -f4 | head -1 | cut -c1-120)"; fi
  rm -rf "$d"

  # (v) OS TRES DEGRAUS DA BASE — o ref que dirige `TO_JUDGE` E o bloco (3) era codigo sem UM assert,
  #     e me fez errar TRES vezes seguidas por tentar resolver com uma regra so o que sao situacoes
  #     diferentes. Cada degrau tem seu cenario, e o que se afere e o COMPORTAMENTO (o bypass e
  #     pego?), nao o ref escolhido — aferir o ref seria testar a implementacao, nao a propriedade.
  local failed_v=""

  # v1 · PRE-COMMIT (arvore suja): a mutacao esta no working tree e o HEAD e a base.
  d="$(mktemp -d)"; _scene49 "$d" drifted 5 PROD "" ""
  _run49 "$d"
  [ "$(_tags49 "${OUT49}")" = "SOFT:PASSIVO " ] || failed_v="${failed_v} v1(arvore-suja:$(_tags49 "${OUT49}"))"
  rm -rf "$d"

  # v2 · POS-COMMIT com PONTO DE RAMIFICACAO: o encolhimento vai COMMITADO numa branch.
  d="$(mktemp -d)"; _graph49 "$d" confirmed 5 PROD "" ""
  ( cd "$d" && git init -q -b main . && git add -A && git -c user.email=t@t -c user.name=t commit -qm g ) 2>/dev/null
  mkdir -p "$d/.claude/validation"
  bash "${helper}" "$d" --emit-baseline > "$d/.claude/validation/kg-verification-baseline.txt" 2>/dev/null
  ( cd "$d" && git add -A && git -c user.email=t@t -c user.name=t commit -qm b && git checkout -q -b work
    git rm -q docs/onion/graph/t.kg.yaml
    : > .claude/validation/kg-verification-baseline.txt
    git add -A && git -c user.email=t@t -c user.name=t commit -qm 'apaga tudo' ) >/dev/null 2>&1
  _run49 "$d"
  printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD"{h=1} END{exit !h}' || failed_v="${failed_v} v2(commitado-na-branch-passou:$(_tags49 "${OUT49}"))"
  rm -rf "$d"

  # v3 · SEM BASELINE NO PONTO DE RAMIFICACAO — o adotante recem-instalado, em que o baseline NASCE
  #      na propria branch. Foi AQUI que o `prev` vazio reabriu o bypass total.
  d="$(mktemp -d)"; _graph49 "$d" confirmed 5 PROD "" ""
  ( cd "$d" && git init -q -b main . && git add -A && git -c user.email=t@t -c user.name=t commit -qm 'sem baseline' && git checkout -q -b work ) 2>/dev/null
  mkdir -p "$d/.claude/validation"
  bash "${helper}" "$d" --emit-baseline > "$d/.claude/validation/kg-verification-baseline.txt" 2>/dev/null
  ( cd "$d" && git add -A && git -c user.email=t@t -c user.name=t commit -qm 'nasce o baseline'
    git rm -q docs/onion/graph/t.kg.yaml
    : > .claude/validation/kg-verification-baseline.txt
    git add -A && git -c user.email=t@t -c user.name=t commit -qm 'apaga grafo E linhas' ) >/dev/null 2>&1
  _run49 "$d"
  printf '%s' "${OUT49}" | awk -F'\t' '$1=="HARD"{h=1} END{exit !h}' || failed_v="${failed_v} v3(adotante-bypass-reaberto:$(_tags49 "${OUT49}"))"
  rm -rf "$d"

  if [ -z "${failed_v}" ]; then
    record_pass "kg-catraca: (v) os TRES degraus da base pegam o encolhimento (arvore suja · commitado na branch · adotante sem baseline na base)"
  else record_fail "kg-catraca: (v)" "degrau(s) cego(s):${failed_v}"; fi

  # (o) MUTATION — devolver a ALLOWLIST faz o caso (i) parar de proteger.
  #     ⚠️ o caso (i) afirma uma AUSÊNCIA de acusação, e ausência é o que uma fixture MORTA entrega
  #     de graça: este teste sobreviveu a uma fixture sabotada de propósito em 2026-08-08. Por isso
  #     passa pelo `_prove_mutation`, que exige o INTACTO satisfazer o caso antes de julgar o mutante.
  local rc_intact rc_mutant
  d="$(mktemp -d)"; _scene49 "$d" drifted 5 PROD "" ""
  mut="$d/mut-allow.sh"
  sed 's/st != "superseded" \&\& st != "refuted"/st == "open"/' "${helper}" > "${mut}"
  if [ "$(_tags49 "$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)")" = "SOFT:PASSIVO " ]; then rc_intact=0; else rc_intact=1; fi
  if [ "$(_tags49 "$(bash "${mut}"    "$d" --format tsv 2>/dev/null || true)")" = "SOFT:PASSIVO " ]; then rc_mutant=0; else rc_mutant=1; fi
  _prove_mutation "kg-catraca: (o) (MUT) com a allowlist de volta o caso (i) para de proteger — o predicado e load-bearing" \
                 "${helper}" "${mut}" "${rc_intact}" "${rc_mutant}"

  # (p) MUTATION — sem a checagem de aresta, o caso (k) passa a ACUSAR CONFORMIDADE
  d="$(mktemp -d)"; _scene49 "$d" refuted 5 PROD "" REFUTES
  mut="$d/mut-aresta.sh"
  # ⚠️ RANGE limitado à função. O padrão `exit(found ? 0 : 1)` aparece DUAS vezes no helper: na
  # função e dentro do comentário que documenta o comando de falsificação. Um `sed` solto mutaria os
  # dois, e o `cmp` passaria a diferir por duas razões — a mesma armadilha de padrão-que-casa-a-si-
  # mesmo que derrubou três guardas-da-guarda em 2026-08-07, um passo adiante.
  # ⚠️ E o padrão contém um IDENTIFICADOR (`found`): renomeá-lo mata esta âncora. Já aconteceu
  # duas vezes nesta sessão (aqui, e o `SUMARIO_IMPRESSO`→`SUMMARY_PRINTED` no extrator). Quem
  # renomear tem de re-rodar o bloco — o `_prove_mutation` acusa, mas só se alguém o rodar.
  sed '/^has_reconciliation_edge()/,/^}$/ s/exit(found ? 0 : 1)/exit(1)/' "${helper}" > "${mut}"
  if printf '%s' "$(bash "${helper}" "$d" --format tsv 2>/dev/null || true)" | awk -F'\t' '$1=="HARD"{h=1} $2=="RECONCILIADO"{r=1} END{exit !(r && !h)}'; then rc_intact=0; else rc_intact=1; fi
  if printf '%s' "$(bash "${mut}"    "$d" --format tsv 2>/dev/null || true)" | awk -F'\t' '$1=="HARD"{h=1} $2=="RECONCILIADO"{r=1} END{exit !(r && !h)}'; then rc_mutant=0; else rc_mutant=1; fi
  _prove_mutation "kg-catraca: (p) (MUT) sem a checagem de aresta o (k) passa a punir conformidade — a aresta e o discriminador" \
                 "${helper}" "${mut}" "${rc_intact}" "${rc_mutant}"

  # (w) A TABELA DE DOUTRINA CONCORDA COM O QUE O CODIGO EMITE.
  #
  # Nasceu de um drift REAL: o cabecalho declarava `REMOVIDO → SOFT (ato visivel no diff)` e "tres
  # classes legitimas" DEPOIS de o PR da 2a porta ter trocado a emissao para HARD. Comportamento
  # mudou, doutrina nao — e sobreviveu a uma passada adversarial inteira, porque revisor humano e
  # revisor-LLM leem a tabela COMO SE fosse a verdade em vez de compara-la com o codigo.
  #
  # E `declarado != verificado` dentro do cabecalho do gate que existe para cacar isso. A cura nao
  # podia ser "quem editar a emissao edita a tabela" — disciplina nao se repete sozinha, e esta casa
  # ja mediu isso. Vira comparacao mecanica.
  #
  # ⚠️ CLASSE COM DUAS SEVERIDADES E LEGITIMA: `MUDOU-DE-PATH` sai HARD fora do escopo e SOFT em path
  # vivo, de proposito. Por isso o teste e "a severidade da TABELA esta ENTRE as emitidas", nunca
  # igualdade — a versao ingenua nasceria com falso-positivo, que e como se ensina a ignorar guarda.
  local cov="${SCRIPT_DIR}/kg-verification-coverage.sh" wd wdiv wn
  if [ ! -f "${cov}" ]; then record_skip "kg-catraca: (w) kg-verification-coverage.sh ausente"; else
    wd="$(mktemp -d)"
    awk '/^#   [A-Z][A-Z-]+ +/ && /→ *(SOFT|HARD)/ { print $2"\t"(($0 ~ /→ *HARD/) ? "HARD" : "SOFT") }' \
      "${cov}" | sort -u > "${wd}/tabela.tsv"
    # ⚠️ SO LINHAS DE CODIGO. Uma passada adversarial mediu a fuga: um COMENTARIO contendo o texto
    # `emit SOFT REMOVIDO` re-esconde o drift FUNDADOR desta catraca — o extrator via o comentario
    # como se fosse emissao, a severidade "batia", e a tabela voltava a mentir com a guarda verde.
    # Comparar PROSA com prosa e o oposto do ponto: `(w)` existe para comparar doutrina com CODIGO.
    grep -vE '^[[:space:]]*#' "${cov}" | grep -oE 'emit (SOFT|HARD) [A-Z-]+' | awk '{print $3"\t"$2}' | sort -u > "${wd}/codigo.tsv"
    wn="$(grep -c . "${wd}/tabela.tsv" || true)"
    wdiv=""
    while IFS=$'\t' read -r wcls wsev; do
      [ -n "${wcls}" ] || continue
      # a classe TEM de ser emitida em algum lugar (tabela que descreve classe morta tambem mente)
      if ! grep -q "^${wcls}"$'\t' "${wd}/codigo.tsv"; then
        wdiv="${wdiv} ${wcls}(na-tabela-mas-NUNCA-emitida)"
      elif ! grep -qx "${wcls}"$'\t'"${wsev}" "${wd}/codigo.tsv"; then
        wdiv="${wdiv} ${wcls}(tabela=${wsev}, emitido=$(grep "^${wcls}"$'\t' "${wd}/codigo.tsv" | cut -f2 | tr '\n' '/'))"
      fi
    done < "${wd}/tabela.tsv"
    # ⚠️ A OUTRA DIRECAO. A 1a versao so ia tabela->codigo: uma classe EMITIDA e ausente da tabela
    # passava despercebida, e a tabela seguia mentindo POR OMISSAO — que e como o drift fundador
    # (`REMOVIDO`) teria voltado depois de curado. Aqui a tabela e a lista das SAIDAS DO BASELINE,
    # nao de todo `emit` do arquivo: `NOVO`, `CATRACA`, `NO-BASELINE`, `PASSIVO`, `SEM-BASE`,
    # `ID-AMBIGUO` e `MUDOU-DE-PATH` sao outra familia (o gate acusando, nao o baseline encolhendo)
    # e ficam fora POR DESENHO. Por isso a cobranca e sobre a familia FUGA-*/CARIMBADO/RECONCILIADO/
    # REMOVIDO, que e a tabela; classe NOVA dessa familia sem linha na tabela reprova.
    while IFS=$'\t' read -r wcls wsev; do
      [ -n "${wcls}" ] || continue
      case "${wcls}" in CARIMBADO|RECONCILIADO|REMOVIDO|FUGA-*) : ;; *) continue ;; esac
      grep -q "^${wcls}"$'\t' "${wd}/tabela.tsv" || wdiv="${wdiv} ${wcls}(EMITIDA mas AUSENTE da tabela)"
    done < "${wd}/codigo.tsv"
    rm -rf "${wd}"
    # 🐤 canario: tabela vazia passaria por VACUIDADE — o awk depende do formato do cabecalho, e um
    #    reflow de comentario o mataria em silencio, deixando a guarda verde sem comparar nada.
    if [ "${wn:-0}" -lt 5 ]; then
      record_fail "kg-catraca: (w) tabela de doutrina" "o extrator achou ${wn:-0} classes na tabela (esperado >=5) — o formato do cabecalho mudou e a guarda mediria o NADA"
    elif [ -z "${wdiv}" ]; then
      record_pass "kg-catraca: (w) a tabela de doutrina concorda com as severidades EMITIDAS (${wn} classes)"
    else record_fail "kg-catraca: (w) doutrina x codigo" "a tabela do cabecalho mente sobre o comportamento:${wdiv}"; fi
  fi
}

run_task_manager_hook_selftests() {
  local hook="${REPO_ROOT}/.claude/hooks/task-manager-provider-hook.sh"
  if [ ! -f "${hook}" ]; then record_fail "task-manager-hook" "hook ausente: ${hook}"; return; fi
  local out d

  # (a) ambiente setado → anuncia o provider do ambiente (alinhado ao adapter)
  out="$(TASK_MANAGER_PROVIDER=jira bash "${hook}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q 'ativo = jira'; then
    record_pass "task-manager-hook: (a) ambiente setado → anuncia do ambiente (fonte do adapter)"
  else record_fail "task-manager-hook: (a)" "não leu o ambiente: ${out}"; fi

  # (b) ambiente vazio + .env com provider → avisa HONESTO (adapter cego), não anuncia cosmético
  d="$(mktemp -d)"; printf 'TASK_MANAGER_PROVIDER=linear\n' > "${d}/.env"
  out="$(cd "${d}" && env -u TASK_MANAGER_PROVIDER CLAUDE_PROJECT_DIR="${d}" bash "${hook}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q 'declarado no .env' && printf '%s' "${out}" | grep -q 'cego'; then
    record_pass "task-manager-hook: (b) só no .env → aviso honesto (adapter cego), não cosmético"
  else record_fail "task-manager-hook: (b)" "não avisou sobre .env não-carregado: ${out}"; fi
  rm -rf "${d}"

  # (c) ambiente vazio + sem .env → none
  d="$(mktemp -d)"
  out="$(cd "${d}" && env -u TASK_MANAGER_PROVIDER CLAUDE_PROJECT_DIR="${d}" bash "${hook}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q 'ativo = none'; then
    record_pass "task-manager-hook: (c) sem ambiente e sem .env → none"
  else record_fail "task-manager-hook: (c)" "esperava none: ${out}"; fi
  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo githook — exercita .claude/utils/adopt/install-onion-githook.sh (padrão de
# hook nativo Onion; ADR native-githooks-standard). Self-contained (mktemp -d).
# ---------------------------------------------------------------------------
# Modo regen-baselines — exercita .claude/utils/adopt/regen-baselines.sh.
#
# O QUE ESTA BANCADA PROTEGE (defeito MEDIDO em 2026-08-17): a adoção regenerava 1 de 5 baselines
# de catraca, e numa adoção greenfield real o `kg-verification-baseline.txt` chegou com 47 chaves
# de grafos do CORE → o lint do adotante nasceu com 47 HARD cobrando nós que ele nunca teve. O
# caso (b) abaixo é ESSE defeito, reduzido a fixture: se alguém quebrar a regeneração, ele volta.
run_regen_baselines_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/regen-baselines.sh"
  if [ ! -f "${helper}" ]; then record_fail "regen-baselines" "helper ausente: ${helper}"; return; fi
  local d rc out

  # (a) recusa rodar no CORE (role: source) — ali o baseline é o LEDGER da dívida própria.
  #     ⚠️ Este caso nasceu de um defeito meu: a 1ª guarda lia o ARQUIVO .onion-version e ficava
  #     MUDA no core (que não tem o arquivo — ali o papel é COMPUTADO). Passou por idempotência,
  #     não por verificação. Por isso o teste checa o rc, não a ausência de dano.
  # ⚠️ `cmd; rc=$?` sob `set -e` MATA a suíte (a bancada tem guarda que acusa isso, e ela me
  #    pegou aqui em 2026-08-17): o helper sai 2/3 DE PROPÓSITO. Idioma da casa: `|| rc=$?`.
  rc=0; out="$(bash "${helper}" "${REPO_ROOT}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 2 ] && printf '%s' "${out}" | grep -q 'CORE'; then
    record_pass "regen-baselines: recusa no core (role: source computado pela autoridade)"
  else record_fail "regen-baselines: guarda do core" "rc=${rc} (esperado 2) — regeneraria o ledger do core"; fi

  # (b) O DEFEITO ORIGINAL: baseline herdado com paths do core → regenerado para o corpus do ALVO.
  d="$(mktemp -d)"
  git -C "${REPO_ROOT}" archive HEAD -- .claude/validation 2>/dev/null | tar -x -C "${d}" 2>/dev/null
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"
  printf '# herdado do core\ndocs/discussions/x/proto/y.kg.yaml::15c1995fb0f2\n' \
    > "${d}/.claude/validation/kg-verification-baseline.txt"
  bash "${helper}" "${d}" >/dev/null 2>&1 || true
  if ! grep -q 'docs/discussions/x/proto' "${d}/.claude/validation/kg-verification-baseline.txt"; then
    record_pass "regen-baselines: passivo de path do core sai do baseline do adotante"
  else record_fail "regen-baselines: passivo herdado" "chave de path do core sobreviveu no alvo"; fi
  rm -rf "${d}"

  # (c) baseline SEM emissor resolvível → rc=3 (falha RUIDOSA) e baseline PRESERVADO.
  #     Preservar é proposital: trocar passivo alheio por baseline VAZIO é pior — catraca vazia
  #     não cobra nada e passa a mentir verde.
  d="$(mktemp -d)"; mkdir -p "${d}/.claude/validation"
  printf 'chave/orfa::deadbeef\n' > "${d}/.claude/validation/inventado-baseline.txt"
  rc=0; bash "${helper}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 3 ] && grep -q 'deadbeef' "${d}/.claude/validation/inventado-baseline.txt"; then
    record_pass "regen-baselines: sem emissor → rc=3 ruidoso e baseline preservado"
  else record_fail "regen-baselines: sem emissor" "rc=${rc} (esperado 3) ou baseline virou vazio"; fi
  rm -rf "${d}"

  # (e) MODO FILTER — a operação do `--update`: derruba a chave ESTRANGEIRA e PRESERVA a local.
  #     ⚠️ ESTE CASO EXISTE POR UM DEFEITO QUE EU IA COLOCAR EM PRODUÇÃO: a 1ª versão da cura
  #     regenerava o baseline também no update, e ali re-emitir RE-TOLERA toda a dívida acumulada
  #     desde a última atualização — a catraca ficaria verde sobre crescimento real, em silêncio.
  #     Emitir é certo no dia 1 (tolerar o estado do adotante é a intenção); no update é filtrar.
  d="$(mktemp -d)"; mkdir -p "${d}/.claude/validation" "${d}/docs/meu"
  : > "${d}/docs/meu/proprio.kg.yaml"
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"
  printf '# misto\ndocs/discussions/x/y.kg.yaml::aaaa\ndocs/meu/proprio.kg.yaml::bbbb\n' \
    > "${d}/.claude/validation/kg-verification-baseline.txt"
  bash "${helper}" "${d}" --filter >/dev/null 2>&1 || true
  if ! grep -q 'docs/discussions/x' "${d}/.claude/validation/kg-verification-baseline.txt" \
     && grep -q 'docs/meu/proprio' "${d}/.claude/validation/kg-verification-baseline.txt"; then
    record_pass "regen-baselines: (filter) estrangeira cai, dívida LOCAL segue cobrada"
  else record_fail "regen-baselines: filter" "filtrou a chave local (perdoou dívida do adotante) ou manteve a estrangeira"; fi
  rm -rf "${d}"

  # (f) `--auto` DECIDE PELA PRIMEIRA CHEGADA, não por "o alvo tem história" — e a distinção é
  #     load-bearing: adoção de repo LEGADO tem história, e ali emitir é o certo. Aqui o alvo tem
  #     commit próprio mas o baseline NUNCA foi versionado → 1ª chegada → emite (esvazia o passivo).
  #     ⚠️ A fixture PRECISA dos scripts emissores. A 1ª versão dela criava só o diretório e o caso
  #     reprovava por não resolver emissor (rc=3, baseline preservado — comportamento CERTO do
  #     helper): era defeito da BANCADA, não do SUT. Fixture pobre acusa o código inocente.
  d="$(mktemp -d)"
  git -C "${d}" init -q 2>/dev/null
  git -C "${REPO_ROOT}" archive HEAD -- .claude/validation 2>/dev/null | tar -x -C "${d}" 2>/dev/null
  mkdir -p "${d}/.claude/validation" "${d}/docs/legado"
  : > "${d}/docs/legado/antigo.md"
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"
  printf '# core\ndocs/discussions/x/y.kg.yaml::aaaa\n' > "${d}/.claude/validation/kg-verification-baseline.txt"
  git -C "${d}" add docs >/dev/null 2>&1 || true
  git -C "${d}" -c user.email=t@t -c user.name=t commit -q --no-verify -m legado >/dev/null 2>&1 || true
  bash "${helper}" "${d}" >/dev/null 2>&1 || true
  if ! grep -q 'docs/discussions/x' "${d}/.claude/validation/kg-verification-baseline.txt"; then
    record_pass "regen-baselines: (auto) baseline nunca versionado → 1ª chegada emite, mesmo em repo COM história"
  else record_fail "regen-baselines: auto/1a-chegada" "tratou repo legado como update e manteve o passivo do core"; fi
  rm -rf "${d}"

  # (g) `--auto` no caso oposto: baseline JÁ versionado → filtra (não re-emite, não perdoa local).
  d="$(mktemp -d)"
  git -C "${d}" init -q 2>/dev/null
  mkdir -p "${d}/.claude/validation" "${d}/docs/meu"
  : > "${d}/docs/meu/proprio.kg.yaml"
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"
  printf '# misto\ndocs/discussions/x/y.kg.yaml::aaaa\ndocs/meu/proprio.kg.yaml::bbbb\n' \
    > "${d}/.claude/validation/kg-verification-baseline.txt"
  git -C "${d}" add -A >/dev/null 2>&1 || true
  git -C "${d}" -c user.email=t@t -c user.name=t commit -q --no-verify -m "adoção anterior" >/dev/null 2>&1 || true
  bash "${helper}" "${d}" >/dev/null 2>&1 || true
  if grep -q 'docs/meu/proprio' "${d}/.claude/validation/kg-verification-baseline.txt" \
     && ! grep -q 'docs/discussions/x' "${d}/.claude/validation/kg-verification-baseline.txt"; then
    record_pass "regen-baselines: (auto) baseline já versionado → filtra, dívida local intacta"
  else record_fail "regen-baselines: auto/ja-versionado" "re-emitiu no caminho de update (perdoaria dívida acumulada)"; fi
  rm -rf "${d}"

  # (d) alvo sem maquinaria vendorizada → no-op silencioso (rc=0), não erro.
  d="$(mktemp -d)"
  rc=0; bash "${helper}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "regen-baselines: alvo sem .claude/validation é no-op (rc=0)"
  else record_fail "regen-baselines: no-op" "rc=${rc} (esperado 0) em alvo sem maquinaria"; fi
  rm -rf "${d}"

  # (e) o relatório não pode sair DEFORMADO: `grep -c` sem casamento imprime 0 E sai 1, então
  #     `grep -c || echo 0` emitia "0\n0" e quebrava a linha do relatório (defeito real, mesmo dia).
  d="$(mktemp -d)"
  git -C "${REPO_ROOT}" archive HEAD -- .claude/validation 2>/dev/null | tar -x -C "${d}" 2>/dev/null
  printf 'role: adopted\n' > "${d}/.claude/.onion-version"
  out="$(bash "${helper}" "${d}" 2>/dev/null | grep -c 'chave(s)' || true)"
  local lines; lines="$(bash "${helper}" "${d}" 2>/dev/null | grep -c '^  [✓✗]' || true)"
  if [ "${out}" = "${lines}" ] && [ "${out}" -gt 0 ]; then
    record_pass "regen-baselines: uma linha por baseline (relatório não deformado)"
  else record_fail "regen-baselines: relatório" "linhas com 'chave(s)'=${out} != linhas ✓/✗=${lines}"; fi
  rm -rf "${d}"
}

# Modo regen-ensure-from — adotante PRE-CATRACA (D_ADOPT_MUST_EMIT_MISSING_BASELINES). Sem o baseline
# proprio, a catraca fica NO-BASELINE (fail-closed) apos o update. `--ensure-from <SOURCE>` semeia stub
# p/ cada baseline que o core DEFINE mas o alvo NAO tem, e o loop emite do CORPUS DO ADOTANTE. Dogfood
# real num adotante pré-catraca (2026-08-25): rc 1→0. (a) cura resolve; (b) MUT sem --ensure-from → NO-BASELINE fica.
run_regen_ensure_from_selftests() {
  local regen="${SCRIPT_DIR}/../utils/adopt/regen-baselines.sh"
  local cov="${SCRIPT_DIR}/kg-verification-coverage.sh"
  [ -f "${regen}" ] && [ -f "${cov}" ] || { record_pass "regen-ensure-from: helper ausente — nada a testar"; return; }
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  _mk_preca() { local ad="$1"; mkdir -p "$ad/.claude/validation/lib"
    cp "${cov}" "$ad/.claude/validation/"; cp "${SCRIPT_DIR}/lib/"*.awk "$ad/.claude/validation/lib/" 2>/dev/null || true
    printf 'source_commit: x\nrole: adopted\n' > "$ad/.claude/.onion-version"
    git -C "$ad" init -q; git -C "$ad" add -A; git -C "$ad" commit -qm adopt >/dev/null 2>&1; }
  local w; w="$(mktemp -d)"; trap 'rm -rf "'"$w"'"' RETURN
  # (a) com --ensure-from: NO-BASELINE some, catraca passa
  local ad="$w/a"; _mk_preca "$ad"
  local rc0=0; bash "${cov}" "$ad" >/dev/null 2>&1 || rc0=$?
  bash "${regen}" "$ad" --ensure-from "${REPO_ROOT}" >/dev/null 2>&1 || true
  local rc1=0; bash "${cov}" "$ad" >/dev/null 2>&1 || rc1=$?
  if [ "$rc0" -ne 0 ] && [ "$rc1" -eq 0 ] && [ -f "$ad/.claude/validation/kg-verification-baseline.txt" ]; then
    record_pass "regen-ensure-from: (a) pré-catraca NO-BASELINE (rc=$rc0) → --ensure-from emite → catraca passa (rc=$rc1)"
  else record_fail "regen-ensure-from: (a)" "esperava rc antes!=0 e depois=0 (veio $rc0→$rc1) + baseline presente"; fi
  # (b) MUT: sem --ensure-from, o NO-BASELINE PERSISTE (a flag é load-bearing)
  local adb="$w/b"; _mk_preca "$adb"
  bash "${regen}" "$adb" >/dev/null 2>&1 || true
  local rc2=0; bash "${cov}" "$adb" >/dev/null 2>&1 || rc2=$?
  if [ "$rc2" -ne 0 ] && [ ! -f "$adb/.claude/validation/kg-verification-baseline.txt" ]; then
    record_pass "regen-ensure-from: (b) sem --ensure-from o NO-BASELINE persiste — a flag é load-bearing"
  else record_fail "regen-ensure-from: (b)" "sem a flag o baseline apareceu/passou (rc=$rc2) — o teste não prova"; fi
  unset -f _mk_preca
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

# Modo seed-adoption-graph — exercita .claude/utils/adopt/seed-adoption-graph.sh.
#
# O QUE PROTEGE (achado de campo, 2026-08-17): a adoção entregava todos os RECURSOS e ZERO ESTADO —
# nenhum `.kg.yaml`. O passo 0 do /warm-up é "se existir um .kg.yaml, consulte-o PRIMEIRO", resolvido
# por `git ls-files '*.kg.yaml'`: com zero grafos ele não falha, fica VAZIO, e a sessão degrada para
# ler prosa. Um adotante real nasceu assim e o dono perguntou "não tem nem KG para mapear?".
#
# O caso (a) é o que mais importa e é auto-referente: o que o semeador GERA tem de passar no RADAR
# desta casa. Gerador que produz artefato que a própria validação reprova entrega dívida, não valor.
run_seed_adoption_graph_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/seed-adoption-graph.sh"
  if [ ! -f "${helper}" ]; then record_fail "seed-graph" "helper ausente: ${helper}"; return; fi
  local d rc out

  _seed_fixture() {   # alvo com a maquinaria vendorizada + stamp
    local dd; dd="$(mktemp -d)"
    git -C "${dd}" init -q 2>/dev/null
    git -C "${REPO_ROOT}" archive HEAD -- .claude/validation .claude/rules 2>/dev/null | tar -x -C "${dd}" 2>/dev/null
    mkdir -p "${dd}/.claude"
    printf 'framework: onion-evolve\ncommit: abc123def456\nrole: adopted\nmode: greenfield\nadopted_at: 2026-08-17\nintegration_branch: main\n' \
      > "${dd}/.claude/.onion-version"
    printf '%s' "${dd}"
  }

  # (a) alvo virgem → semeia, E o RADAR aprova o grafo gerado (exit 0, sem contradição estrutural).
  d="$(_seed_fixture)"
  bash "${helper}" "${d}" --gate-proven >/dev/null 2>&1 || true
  rc=0
  ( cd "${d}" && bash .claude/validation/kg-radar.sh docs/onion/graph/onion-adoption.kg.yaml >/dev/null 2>&1 ) || rc=$?
  if [ -f "${d}/docs/onion/graph/onion-adoption.kg.yaml" ] && [ "${rc}" -eq 0 ]; then
    record_pass "seed-graph: (a) semeia e o RADAR aprova o próprio artefato gerado"
  else record_fail "seed-graph: (a)" "não semeou, ou o radar reprovou o grafo gerado (rc=${rc})"; fi
  rm -rf "${d}"

  # (b) NEVER-CLOBBER pela pergunta certa — "o alvo TEM grafo?", não "este arquivo existe?": semear
  #     um 2º grafo em repo que já mapeia o próprio domínio é empurrar ruído a quem já pegou o hábito.
  d="$(_seed_fixture)"
  mkdir -p "${d}/docs"; printf 'nodes: []\n' > "${d}/docs/meu-dominio.kg.yaml"
  bash "${helper}" "${d}" --gate-proven >/dev/null 2>&1 || true
  if [ ! -f "${d}/docs/onion/graph/onion-adoption.kg.yaml" ]; then
    record_pass "seed-graph: (b) alvo que já tem grafo não recebe semente (never-clobber)"
  else record_fail "seed-graph: (b)" "semeou sobre adotante que já tinha grafo"; fi
  rm -rf "${d}"

  # (c) --gate-unproven → o nó do gate fica `open`. É a asserção de HONESTIDADE do artefato: o
  #     instalador tem TRÊS resultados (vivo / inerte / prova ADIADA) e "saiu 0" não distingue os
  #     dois primeiros do terceiro. Grafo que nasce afirmando prova que ninguém fez é o defeito
  #     que a medição de 2026-08-16 (gate inerte em 4 de 6, invisível sem executar) já cobrou.
  d="$(_seed_fixture)"
  bash "${helper}" "${d}" --gate-unproven >/dev/null 2>&1 || true
  out="$(awk '/id: DETERMINISTIC_GATE/,/label:/' "${d}/docs/onion/graph/onion-adoption.kg.yaml" 2>/dev/null || true)"
  if printf '%s' "${out}" | grep -qE '^[[:space:]]*status:[[:space:]]*open'; then
    record_pass "seed-graph: (c) gate não provado → nó \`open\`, não afirma prova inexistente"
  else record_fail "seed-graph: (c)" "gate sem prova ficou como confirmed — o grafo mentiria de saída"; fi
  rm -rf "${d}"

  # (d) flag VAZIA não é erro: o chamador usa "${GATE_FLAG:-}" e a variável pode não estar setada.
  #     Sem isto, o argumento vazio caía no ramo de alvo e o helper morria com "alvo já informado".
  d="$(_seed_fixture)"
  rc=0; bash "${helper}" "${d}" "" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${d}/docs/onion/graph/onion-adoption.kg.yaml" ]; then
    record_pass "seed-graph: (d) flag vazia é ausência, não erro (rc=0)"
  else record_fail "seed-graph: (d)" "flag vazia quebrou o helper (rc=${rc})"; fi
  rm -rf "${d}"

  # (e) SEM stamp → campo honesto, nunca em branco. Campo vazio num grafo lido por máquina e por
  #     humano é pior que a ausência declarada: parece dado.
  d="$(mktemp -d)"; git -C "${d}" init -q 2>/dev/null
  bash "${helper}" "${d}" --gate-unproven >/dev/null 2>&1 || true
  if grep -q 'não carimbado' "${d}/docs/onion/graph/onion-adoption.kg.yaml" 2>/dev/null; then
    record_pass "seed-graph: (e) sem stamp → '(não carimbado)' explícito, não campo vazio"
  else record_fail "seed-graph: (e)" "campo sem stamp saiu em branco (parece dado)"; fi
  rm -rf "${d}"

  unset -f _seed_fixture
}

run_githook_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/adopt/install-onion-githook.sh"
  local tpl="${REPO_ROOT}/.claude/utils/adopt/githook-pre-commit-onion.tpl"
  if [ ! -f "${helper}" ]; then record_fail "githook" "helper ausente: ${helper}"; return; fi
  if [ ! -f "${tpl}" ]; then record_fail "githook" "template ausente: ${tpl}"; return; fi
  local d rc

  # (a) repo sem .githooks → cria pre-commit executável + seta core.hooksPath=.githooks
  d="$(mktemp -d)"; git -C "${d}" init -q
  bash "${helper}" "${d}" >/dev/null 2>&1
  if [ -x "${d}/.githooks/pre-commit" ] && [ "$(git -C "${d}" config --local --get core.hooksPath)" = ".githooks" ]; then
    record_pass "githook: absent cria pre-commit + seta hooksPath"
  else record_fail "githook: absent" "não criou hook executável ou não setou hooksPath"; fi
  rm -rf "${d}"

  # (b) pre-commit próprio DIFERENTE → sidecar .onion, original intacto (never-clobber)
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.githooks"
  printf '#!/bin/sh\necho meu-hook\n' > "${d}/.githooks/pre-commit"
  bash "${helper}" "${d}" >/dev/null 2>&1
  if [ -f "${d}/.githooks/pre-commit.onion" ] && grep -q 'meu-hook' "${d}/.githooks/pre-commit"; then
    record_pass "githook: pre-commit próprio → sidecar .onion (never-clobber)"
  else record_fail "githook: never-clobber" "clobrou o pre-commit do alvo ou não gerou sidecar"; fi
  rm -rf "${d}"

  # (c) core.hooksPath já setado (husky/custom) → NÃO sobrescreve + avisa
  d="$(mktemp -d)"; git -C "${d}" init -q; git -C "${d}" config core.hooksPath .husky/_
  local err; err="$(bash "${helper}" "${d}" 2>&1 >/dev/null)"
  if [ "$(git -C "${d}" config --local --get core.hooksPath)" = ".husky/_" ] && printf '%s' "${err}" | grep -q 'NÃO sobrescrito'; then
    record_pass "githook: hooksPath pré-setado não é sobrescrito"
  else record_fail "githook: hooksPath never-clobber" "sobrescreveu o hooksPath do adotante"; fi
  rm -rf "${d}"

  # (d) idempotente: 2ª rodada com hook idêntico → no-op (sem sidecar espúrio)
  d="$(mktemp -d)"; git -C "${d}" init -q
  bash "${helper}" "${d}" >/dev/null 2>&1; bash "${helper}" "${d}" >/dev/null 2>&1
  if [ -x "${d}/.githooks/pre-commit" ] && [ ! -f "${d}/.githooks/pre-commit.onion" ]; then
    record_pass "githook: 2ª rodada é no-op (idempotente)"
  else record_fail "githook: idempotente" "gerou sidecar espúrio na 2ª rodada"; fi
  rm -rf "${d}"

  # (d2) hook Onion-AUTORADO porém DESATUALIZADO → REFRESH (não sidecar).
  #      Sinal de campo (adotante, 2026-07-25): no `--update` o template evoluído virava
  #      sidecar e o hook VELHO seguia ativo — o update não atualizava nada.
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.githooks"
  # simula hook Onion de versão ANTIGA: marcador de autoria presente, conteúdo diferente
  { head -4 "${tpl}"; printf '# versao ANTIGA do template\necho onion-velho\n'; } > "${d}/.githooks/pre-commit"
  bash "${helper}" "${d}" >/dev/null 2>&1
  if cmp -s "${tpl}" "${d}/.githooks/pre-commit" 2>/dev/null && [ ! -f "${d}/.githooks/pre-commit.onion" ]; then
    record_pass "githook: hook Onion desatualizado → REFRESCADO (sem sidecar)"
  else record_fail "githook: refresh" "não refrescou o hook Onion-autorado antigo (virou sidecar ou ficou velho)"; fi
  rm -rf "${d}"

  # (d3) REGRESSÃO: hook de TERCEIRO com conteúdo parecido NÃO pode ser refrescado.
  #      Garante que o refresh discrimina por MARCADOR DE AUTORIA, não por heurística frouxa.
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.githooks"
  printf '#!/usr/bin/env bash\n# pre-commit hook do projeto (lint proprio)\necho terceiro\n' > "${d}/.githooks/pre-commit"
  bash "${helper}" "${d}" >/dev/null 2>&1
  if grep -q 'terceiro' "${d}/.githooks/pre-commit" && [ -f "${d}/.githooks/pre-commit.onion" ]; then
    record_pass "githook: hook de terceiro segue never-clobber (sidecar)"
  else record_fail "githook: refresh discrimina autoria" "refrescou/clobrou hook de TERCEIRO"; fi
  rm -rf "${d}"

  # (e) dest não-git → exit 2 (erro de uso)
  d="$(mktemp -d)"; rc=0; bash "${helper}" "${d}" >/dev/null 2>&1 || rc=$?; rm -rf "${d}"
  if [ "${rc}" -eq 2 ]; then record_pass "githook: dest não-git → exit 2"
  else record_fail "githook: dest não-git" "esperava exit 2, veio ${rc}"; fi

  # (f) dest inexistente → exit 2
  rc=0; bash "${helper}" "/nao/existe/$$" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "githook: dest inválido → exit 2"
  else record_fail "githook: dest inválido" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo assemble-plugin — exercita .claude/utils/marketplace/assemble-plugin.sh
# (genérico, dirigido por manifesto; ADR exchange-unit). Roda contra o REPO real
# com dest em mktemp (não toca o plugins/ commitado). Cobre AMBAS as verticais
# (design = com utils/gate; compliance = agentes-pesado, sem utils/gate → prova de
# generalização), estrutura, determinismo, manifest 8 campos, proveniência, falhas.
# ---------------------------------------------------------------------------
run_assemble_plugin_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/marketplace/assemble-plugin.sh"
  local mdesign="${REPO_ROOT}/.claude/utils/marketplace/verticals/onion-design.manifest.sh"
  local mcompl="${REPO_ROOT}/.claude/utils/marketplace/verticals/onion-compliance.manifest.sh"
  if [ ! -f "${helper}" ]; then record_fail "assemble-plugin" "helper ausente: ${helper}"; return; fi
  if ! command -v jq >/dev/null 2>&1; then record_skip "assemble-plugin: jq ausente → pulado (gracioso)"; return; fi
  # Maquinaria de marketplace é core-only: validar a MONTAGEM de plugin só faz sentido
  # em quem publica plugins (o core tem plugins/ committed). Um consumidor não republica
  # → pular gracioso em vez de cair no assemble (que exige todos os componentes-fonte do
  # manifest presentes) sob set -e e abortar o harness inteiro.
  if [ ! -d "${REPO_ROOT}/plugins" ]; then record_skip "assemble-plugin: sem plugins/ vendorizados → pulado (consumidor não publica plugins)"; return; fi
  local d rc

  # (a) DESIGN: estrutura com utils + gate (commands+agents+utils+validation+manifest+proveniência)
  d="$(mktemp -d)"
  bash "${helper}" "${mdesign}" "${REPO_ROOT}" "${d}/design" >/dev/null 2>&1
  if [ -f "${d}/design/.claude-plugin/plugin.json" ] && [ -f "${d}/design/.claude-plugin/provenance.json" ] \
     && ls "${d}/design/commands/"*.md >/dev/null 2>&1 && ls "${d}/design/agents/"*.md >/dev/null 2>&1 \
     && [ -d "${d}/design/utils/design-sink" ] && [ -f "${d}/design/validation/lint-design-tokens.sh" ]; then
    record_pass "assemble-plugin: design (commands+agents+utils+validation+proveniência)"
  else record_fail "assemble-plugin: design estrutura" "faltou componente no plugin design"; fi

  # (b) COMPLIANCE: shape diferente — agentes + 1 command, SEM utils/ nem validation/ (generalização)
  bash "${helper}" "${mcompl}" "${REPO_ROOT}" "${d}/compliance" >/dev/null 2>&1
  if ls "${d}/compliance/agents/"*.md >/dev/null 2>&1 && [ -f "${d}/compliance/commands/build-compliance-docs.md" ] \
     && [ ! -d "${d}/compliance/utils" ] && [ ! -d "${d}/compliance/validation" ]; then
    record_pass "assemble-plugin: compliance (agentes+command, sem utils/gate — generaliza)"
  else record_fail "assemble-plugin: compliance estrutura" "shape inesperado no plugin compliance"; fi

  # (c) plugin.json = EXATAMENTE os 8 campos permitidos (ambos)
  local kd kc
  kd="$(jq -r 'keys|sort|join(",")' "${d}/design/.claude-plugin/plugin.json" 2>/dev/null)"
  kc="$(jq -r 'keys|sort|join(",")' "${d}/compliance/.claude-plugin/plugin.json" 2>/dev/null)"
  local want="author,description,homepage,keywords,license,name,repository,version"
  if [ "${kd}" = "${want}" ] && [ "${kc}" = "${want}" ]; then
    record_pass "assemble-plugin: plugin.json 8 campos exatos (design+compliance)"
  else record_fail "assemble-plugin: plugin.json campos" "design=${kd} compliance=${kc}"; fi

  # (d) proveniência content-addressed não-vazia (compliance, shape sem utils/gate)
  if jq -e '.repository and .ref and .tree_sha and (.tree_sha|length>0)' \
       "${d}/compliance/.claude-plugin/provenance.json" >/dev/null 2>&1; then
    record_pass "assemble-plugin: proveniência repository+ref+tree_sha"
  else record_fail "assemble-plugin: proveniência" "campos de proveniência ausentes/vazios"; fi

  # (e) determinismo: 2ª montagem (mesmo HEAD) → mesmo tree_sha
  local t1 t2; t1="$(jq -r '.tree_sha' "${d}/design/.claude-plugin/provenance.json" 2>/dev/null)"
  bash "${helper}" "${mdesign}" "${REPO_ROOT}" "${d}/design2" >/dev/null 2>&1
  t2="$(jq -r '.tree_sha' "${d}/design2/.claude-plugin/provenance.json" 2>/dev/null)"
  if [ -n "${t1}" ] && [ "${t1}" = "${t2}" ]; then record_pass "assemble-plugin: tree_sha determinístico"
  else record_fail "assemble-plugin: determinismo" "tree_sha divergiu: ${t1} vs ${t2}"; fi

  # (e2) PATH-PORTABILITY (design): refs a componentes BUNDLADOS reescritas p/ plugin-root.
  # Não resta `.claude/utils/` nem `.claude/validation/` (design não tem templates pendurados);
  # ${CLAUDE_PLUGIN_ROOT} presente; camada 2 (docs/design-context) PRESERVADA; script default = pwd.
  if ! grep -rq '\.claude/utils/\|\.claude/validation/' "${d}/design" 2>/dev/null \
     && grep -rq 'CLAUDE_PLUGIN_ROOT' "${d}/design" 2>/dev/null \
     && grep -rq 'docs/design-context' "${d}/design" 2>/dev/null \
     && grep -q 'PROJECT="${1:-$(pwd)}"' "${d}/design/validation/lint-design-tokens.sh" 2>/dev/null; then
    record_pass "assemble-plugin: design path-portable (sem core-layout; camada 2 preservada; script→pwd)"
  else record_fail "assemble-plugin: design portabilidade" "resta core-layout, faltou plugin-root, ou camada 2 sumiu"; fi

  # (e3) PATH-PORTABILITY (compliance): o template BUNDLADO foi reescrito p/ plugin-root.
  # (refs a compliance_*_template.md inexistentes são bug PRÉ-EXISTENTE do core — fora de escopo, não checado.)
  if ! grep -rq '\.claude/commands/common/templates/compliance-context-template' "${d}/compliance" 2>/dev/null \
     && grep -rq 'CLAUDE_PLUGIN_ROOT}/templates/compliance-context-template' "${d}/compliance" 2>/dev/null \
     && [ -f "${d}/compliance/templates/compliance-context-template.md" ]; then
    record_pass "assemble-plugin: compliance template bundlado + ref reescrita"
  else record_fail "assemble-plugin: compliance template" "template não bundlado ou ref não reescrita"; fi
  rm -rf "${d}"

  # (e4) IRMÃ-NÃO-EMBARCADA → PLAIN-TEXT (a cura por construção de 2026-08-18, e ela é MEDIDA
  # NO ARTEFATO REAL, não em fixture): monta onion-work-tools num tmp e exige (i) ZERO link
  # irmão morto em kb/ — a classe que acumulou 15 em dois plugins sem guarda nenhuma acusar —
  # e (ii) que o TÍTULO da irmã convertida permaneça legível (plain-text, não amputação).
  local mwt dwt
  mwt="${REPO_ROOT}/.claude/utils/marketplace/verticals/onion-work-tools.manifest.sh"
  if [ ! -f "${mwt}" ]; then record_skip "assemble-plugin: (e4) manifesto work-tools ausente"; else
    dwt="$(mktemp -d)"
    bash "${helper}" "${mwt}" "${REPO_ROOT}" "${dwt}/wt" >/dev/null 2>&1
    local dead=0 t
    for f in "${dwt}/wt/kb/"*.md; do
      [ -f "${f}" ] || continue
      while IFS= read -r t; do
        [ -f "${dwt}/wt/kb/${t}" ] || dead=$((dead+1))
      done < <(grep -oE '\]\([a-z0-9-]+\.md(#[^)]*)?\)' "${f}" 2>/dev/null | sed -E 's/^\]\(([a-z0-9-]+\.md).*/\1/' | sort -u)
    done
    if [ "${dead}" -eq 0 ] && grep -q 'Dogfooding Doctrine' "${dwt}/wt/kb/onion-elenxo-doctrine.md" 2>/dev/null; then
      record_pass "assemble-plugin: (e4) irmã-não-embarcada vira plain-text (0 links mortos; título legível)"
    else
      record_fail "assemble-plugin: (e4) links irmãos mortos" "dead=${dead} no kb/ montado (esperado 0), ou o título da irmã sumiu junto com o link"
    fi
    rm -rf "${dwt}"
  fi

  # (h) SKILLS (dir) + HOOKS (script) — fixture bundlando uma skill e um hook reais do repo.
  local mfx dh; mfx="$(mktemp)"; dh="$(mktemp -d)"
  cat > "${mfx}" <<'MFX'
PLUGIN_NAME="fx-skillhook"
PLUGIN_DESC="fixture skills+hooks"
KEYWORDS=(fx)
SKILLS=(".claude/skills/language-standards")
HOOKS=(".claude/hooks/session-beacon-hook.sh")
CONFORMANCE="bronze"; PROVIDES=("fx")
MFX
  bash "${helper}" "${mfx}" "${REPO_ROOT}" "${dh}/fx" >/dev/null 2>&1
  if [ -f "${dh}/fx/skills/language-standards/SKILL.md" ] && [ -x "${dh}/fx/hooks/session-beacon-hook.sh" ]; then
    record_pass "assemble-plugin: SKILLS (dir c/ SKILL.md) + HOOKS (script +x) bundlados"
  else record_fail "assemble-plugin: skills/hooks" "skill dir ou hook script não bundlado"; fi
  rm -f "${mfx}"; rm -rf "${dh}"

  # (f) manifesto inválido → exit 2
  rc=0; bash "${helper}" "/nao/existe/$$.sh" "${REPO_ROOT}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "assemble-plugin: manifesto inválido → exit 2"
  else record_fail "assemble-plugin: manifesto inválido" "esperava exit 2, veio ${rc}"; fi

  # (g) source não-git → exit 2
  d="$(mktemp -d)"; rc=0; bash "${helper}" "${mdesign}" "${d}" "${d}/out" >/dev/null 2>&1 || rc=$?; rm -rf "${d}"
  if [ "${rc}" -eq 2 ]; then record_pass "assemble-plugin: source não-git → exit 2"
  else record_fail "assemble-plugin: source não-git" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo generate-marketplace — exercita .claude/utils/marketplace/generate-marketplace.sh
# (gera .claude-plugin/marketplace.json derivando plugins[] de cada plugin.json;
# top-level preservado). Cobre: derivação de campos + ordem determinística,
# idempotência, preservação do top-level, e caso vazio (sem plugins).
# ---------------------------------------------------------------------------
run_marketplace_generate_selftests() {
  local helper="${SCRIPT_DIR}/../utils/marketplace/generate-marketplace.sh"
  if [ ! -f "${helper}" ]; then record_fail "generate-marketplace" "helper ausente: ${helper}"; return; fi
  local d out o1 o2
  d="$(mktemp -d)"
  mkdir -p "${d}/plugins/zeta/.claude-plugin" "${d}/plugins/alpha/.claude-plugin"
  printf '{\n  "name": "zeta",\n  "version": "1.2.3",\n  "description": "desc zeta",\n  "author": { "name": "Aut" }\n}\n' > "${d}/plugins/zeta/.claude-plugin/plugin.json"
  printf '{\n  "name": "alpha",\n  "version": "0.1.0",\n  "description": "desc alpha",\n  "author": { "name": "Aut" }\n}\n' > "${d}/plugins/alpha/.claude-plugin/plugin.json"

  # (a) deriva campos dos dois plugins (name/source/version)
  out="$(bash "${helper}" "${d}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"name": "zeta"' \
     && printf '%s' "${out}" | grep -q '"source": "./plugins/alpha"' \
     && printf '%s' "${out}" | grep -q '"version": "1.2.3"'; then
    record_pass "generate-marketplace: deriva campos dos plugins"
  else record_fail "generate-marketplace: deriva campos" "name/source/version ausentes na saída"; fi

  # (b) ordem determinística alfabética (alpha antes de zeta)
  if [ "$(printf '%s\n' "${out}" | grep -nF '"name": "alpha"' | head -1 | cut -d: -f1)" \
       -lt "$(printf '%s\n' "${out}" | grep -nF '"name": "zeta"' | head -1 | cut -d: -f1)" ]; then
    record_pass "generate-marketplace: ordem alfabética determinística"
  else record_fail "generate-marketplace: ordem alfabética" "zeta antes de alpha"; fi

  # (c) idempotência: 2 gerações idênticas
  o1="$(bash "${helper}" "${d}" 2>/dev/null)"; o2="$(bash "${helper}" "${d}" 2>/dev/null)"
  if [ "${o1}" = "${o2}" ]; then record_pass "generate-marketplace: idempotente"
  else record_fail "generate-marketplace: idempotente" "2ª geração difere"; fi

  # (d) top-level preservado de marketplace.json existente
  mkdir -p "${d}/.claude-plugin"
  printf '{\n  "name": "meu-repo",\n  "owner": { "name": "Dono" },\n  "metadata": { "description": "d", "version": "9.9", "pluginRoot": "./plugins" },\n  "plugins": []\n}\n' > "${d}/.claude-plugin/marketplace.json"
  out="$(bash "${helper}" "${d}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"name": "meu-repo"' && printf '%s' "${out}" | grep -q '"version": "9.9"'; then
    record_pass "generate-marketplace: top-level preservado"
  else record_fail "generate-marketplace: top-level preservado" "top-level não preservado"; fi
  rm -rf "${d}"

  # (e) sem plugins → JSON com plugins array (vazio) válido
  d="$(mktemp -d)"; out="$(bash "${helper}" "${d}" 2>/dev/null)"; rm -rf "${d}"
  if printf '%s' "${out}" | grep -q '"plugins": \['; then record_pass "generate-marketplace: sem plugins → array válido"
  else record_fail "generate-marketplace: sem plugins" "não emitiu plugins array"; fi
}

# ---------------------------------------------------------------------------
# Modo bootstrap-vertical — exercita .claude/utils/vertical/bootstrap-new-project.sh
# (scaffolda hub-skill + help + context-resolver de templates, com substituição de
# placeholder). Cobre: geração+substituição, never-clobber, dry-run, slug inválido.
# ---------------------------------------------------------------------------
run_bootstrap_vertical_selftests() {
  local helper="${SCRIPT_DIR}/../utils/vertical/bootstrap-new-project.sh"
  if [ ! -f "${helper}" ]; then record_fail "bootstrap-new-project" "helper ausente: ${helper}"; return; fi
  local d rc out

  # (a) gera os 3 artefatos com substituição, sem placeholder residual
  d="$(mktemp -d)"
  bash "${helper}" meuproj --title "Meu Proj" --dir "${d}" >/dev/null 2>&1
  if [ -f "${d}/.claude/skills/meuproj/SKILL.md" ] && [ -f "${d}/.claude/commands/meuproj/help.md" ] \
     && [ -f "${d}/.claude/skills/meuproj-context/SKILL.md" ] \
     && grep -q "name: meuproj" "${d}/.claude/skills/meuproj/SKILL.md" \
     && grep -q "Meu Proj" "${d}/.claude/skills/meuproj/SKILL.md" \
     && ! grep -rq "{{PROJECT" "${d}/.claude"; then
    record_pass "bootstrap-vertical: gera hub+help+context, substituição sem placeholder residual"
  else record_fail "bootstrap-vertical: gera+substitui" "arquivos/substituição incorretos"; fi

  # (b) never-clobber: 2ª rodada não sobrescreve
  out="$(bash "${helper}" meuproj --dir "${d}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q "never-clobber"; then record_pass "bootstrap-vertical: never-clobber"
  else record_fail "bootstrap-vertical: never-clobber" "não pulou artefato existente"; fi
  rm -rf "${d}"

  # (c) dry-run não escreve nada
  d="$(mktemp -d)"; bash "${helper}" xproj --dir "${d}" --dry-run >/dev/null 2>&1
  if [ "$(find "${d}/.claude" -type f 2>/dev/null | wc -l)" -eq 0 ]; then record_pass "bootstrap-vertical: dry-run não escreve"
  else record_fail "bootstrap-vertical: dry-run" "escreveu arquivos em dry-run"; fi
  rm -rf "${d}"

  # (d) slug inválido (não-kebab) → exit 2
  d="$(mktemp -d)"; rc=0; bash "${helper}" "Nao_Kebab" --dir "${d}" >/dev/null 2>&1 || rc=$?; rm -rf "${d}"
  if [ "${rc}" -eq 2 ]; then record_pass "bootstrap-vertical: slug não-kebab → exit 2"
  else record_fail "bootstrap-vertical: slug não-kebab" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo scaffold-book — exercita .claude/utils/vertical/scaffold-book-dir.sh
# (scaffolda docs/<project>-context/README.md com o contrato mínimo do book).
# Cobre: geração+substituição, never-clobber, dry-run, slug inválido.
# ---------------------------------------------------------------------------
run_scaffold_book_selftests() {
  local helper="${SCRIPT_DIR}/../utils/vertical/scaffold-book-dir.sh"
  if [ ! -f "${helper}" ]; then record_fail "scaffold-book-dir" "helper ausente: ${helper}"; return; fi
  local d rc out
  d="$(mktemp -d)"
  bash "${helper}" livroteste --title "Livro Teste" --dir "${d}" >/dev/null 2>&1
  if [ -f "${d}/docs/livroteste-context/README.md" ] \
     && grep -q "Livro Teste — Book" "${d}/docs/livroteste-context/README.md" \
     && ! grep -q "{{PROJECT" "${d}/docs/livroteste-context/README.md"; then
    record_pass "scaffold-book: gera book-dir + substituição sem placeholder"
  else record_fail "scaffold-book: gera+substitui" "arquivo/substituição incorretos"; fi

  out="$(bash "${helper}" livroteste --dir "${d}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q "never-clobber"; then record_pass "scaffold-book: never-clobber"
  else record_fail "scaffold-book: never-clobber" "não pulou existente"; fi
  rm -rf "${d}"

  d="$(mktemp -d)"; bash "${helper}" xp --dir "${d}" --dry-run >/dev/null 2>&1
  if [ "$(find "${d}/docs" -type f 2>/dev/null | wc -l)" -eq 0 ]; then record_pass "scaffold-book: dry-run não escreve"
  else record_fail "scaffold-book: dry-run" "escreveu em dry-run"; fi
  rm -rf "${d}"

  d="$(mktemp -d)"; rc=0; bash "${helper}" "Bad_Slug" --dir "${d}" >/dev/null 2>&1 || rc=$?; rm -rf "${d}"
  if [ "${rc}" -eq 2 ]; then record_pass "scaffold-book: slug não-kebab → exit 2"
  else record_fail "scaffold-book: slug não-kebab" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo scaffold-diagnose — exercita .claude/utils/diagnose/scaffold-diagnose-store.sh
# (o store do /meta:kg diagnose: skeleton .kg.yaml 2-camadas + STATE.md + notes.md + dirs).
# Cobre: os 6 artefatos, substituição sem placeholder, never-clobber, dry-run, slug inválido,
# e o TESTE-CHAVE — o skeleton é bem-formado (schema_version) e VIRA um grafo válido no 1º lote.
# (Skeleton VAZIO reprova a guarda de legibilidade do radar de propósito — 0 nós não é grafo.)
# ---------------------------------------------------------------------------
run_scaffold_diagnose_selftests() {
  local helper="${SCRIPT_DIR}/../utils/diagnose/scaffold-diagnose-store.sh"
  local radar="${SCRIPT_DIR}/kg-radar.sh"
  if [ ! -f "${helper}" ]; then record_fail "scaffold-diagnose" "helper ausente: ${helper}"; return; fi
  local d rc out g
  d="$(mktemp -d)"

  # (a) gera os 6 artefatos, substitui {{SLUG}}/{{TITLE}}/{{DATE}} sem deixar placeholder
  DIAGNOSE_SCAFFOLD_DATE=2026-07-30 bash "${helper}" cliente-x --title "Cliente X" --dir "${d}" >/dev/null 2>&1
  g="${d}/docs/onion/graph/cliente-x.kg.yaml"
  if [ -f "${g}" ] \
     && [ -f "${d}/docs/onion/diagnose/cliente-x/STATE.md" ] \
     && [ -f "${d}/docs/onion/diagnose/cliente-x/notes.md" ] \
     && [ -f "${d}/docs/onion/diagnose/cliente-x/sources/.gitkeep" ] \
     && [ -f "${d}/docs/onion/diagnose/cliente-x/extracts/.gitkeep" ] \
     && [ -f "${d}/docs/onion/diagnose/cliente-x/consolidated/.gitkeep" ] \
     && ! grep -rq '{{' "${g}" "${d}/docs/onion/diagnose/cliente-x/STATE.md"; then
    record_pass "scaffold-diagnose: (a) 6 artefatos + substituição sem placeholder"
  else record_fail "scaffold-diagnose: (a)" "faltou artefato ou sobrou placeholder {{...}}"; fi

  # (b) o skeleton é BEM-FORMADO: schema_version "1" + meta.id = slug + seções nodes:/edges:
  if grep -q 'schema_version: "1"' "${g}" && grep -q '^  id: cliente-x' "${g}" \
     && grep -q '^nodes:' "${g}" && grep -q '^edges:' "${g}"; then
    record_pass "scaffold-diagnose: (b) skeleton bem-formado (schema_version + meta.id + nodes/edges)"
  else record_fail "scaffold-diagnose: (b)" "skeleton mal-formado"; fi

  # (c) TESTE-CHAVE — o skeleton VAZIO não é grafo válido (0 nós → radar reprova legibilidade, de
  #     propósito: anti-falso-verde). Adicionar o 1º par de nós + aresta (LOTE 1) o torna VÁLIDO.
  rc=0; bash "${radar}" "${g}" --integrity --schema >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -ne 0 ]; then
    record_pass "scaffold-diagnose: (c1) skeleton vazio → radar reprova (0 nós não é grafo; anti-falso-verde)"
  else record_fail "scaffold-diagnose: (c1)" "skeleton vazio passou o radar — falso-verde"; fi
  # preenche o 1º lote no skeleton: nós DENTRO da seção nodes:, aresta DENTRO da edges:.
  # (o skeleton tem `nodes:` e `edges:` só com comentários; reescrevemos as duas seções cheias
  #  para provar que o skeleton scaffoldado É a base de um grafo válido — o LOTE 1 do diagnose.)
  local seeded="${d}/seeded.kg.yaml"
  {
    printf 'meta:\n  id: cliente-x\n  schema_version: "1"\n  date: 2026-07-30\n'
    printf 'nodes:\n'
    printf '  - id: ENT_processo\n    node_type: entity\n    layer: domain\n    plane: PROD\n    impact: 4\n    confidence: 0.9\n    status: confirmed\n    label: "o processo do cliente"\n    trace: "sources/reuniao.md"\n'
    printf '  - id: C_gargalo\n    node_type: claim\n    layer: audit\n    plane: DEV\n    impact: 4\n    confidence: 0.7\n    status: open\n    label: "hipotese: o gargalo esta na etapa X"\n    trace: "consolidated/c.md"\n'
    printf 'edges:\n'
    printf '  - from: C_gargalo\n    to: ENT_processo\n    edge_type: TRACES_TO\n'
  } > "${seeded}"
  rc=0; bash "${radar}" "${seeded}" --integrity --schema >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "scaffold-diagnose: (c2) skeleton + 1º lote (2 nós/1 aresta, domain+audit) → radar exit 0"
  else record_fail "scaffold-diagnose: (c2)" "skeleton com 1º lote não passou o radar (rc=${rc})"; fi

  # (d) never-clobber: re-rodar não sobrescreve
  out="$(DIAGNOSE_SCAFFOLD_DATE=2026-07-30 bash "${helper}" cliente-x --dir "${d}" 2>/dev/null)"
  if printf '%s' "${out}" | grep -q 'never-clobber'; then record_pass "scaffold-diagnose: (d) never-clobber (não sobrescreve o store existente)"
  else record_fail "scaffold-diagnose: (d)" "não pulou artefatos existentes"; fi
  rm -rf "${d}"

  # (e) dry-run não escreve
  d="$(mktemp -d)"; bash "${helper}" yp --dir "${d}" --dry-run >/dev/null 2>&1
  if [ "$(find "${d}/docs" -type f 2>/dev/null | wc -l)" -eq 0 ]; then record_pass "scaffold-diagnose: (e) dry-run não escreve"
  else record_fail "scaffold-diagnose: (e)" "escreveu em dry-run"; fi
  rm -rf "${d}"

  # (f) slug não-kebab → exit 2
  d="$(mktemp -d)"; rc=0; bash "${helper}" "Bad_Slug" --dir "${d}" >/dev/null 2>&1 || rc=$?; rm -rf "${d}"
  if [ "${rc}" -eq 2 ]; then record_pass "scaffold-diagnose: (f) slug não-kebab → exit 2"
  else record_fail "scaffold-diagnose: (f)" "esperava exit 2, veio ${rc}"; fi
}

# ---------------------------------------------------------------------------
# Modo plugins-sync — exercita o drift-guard (REGRA 19 check_plugins_sync) do
# lint-artifacts: cada plugins/<name> committado DEVE bater com a regeneração da
# fonte (diff -x provenance + tree_sha). Cobre: em-sync (catch de regen esquecida)
# + detecção de adulteração + insensibilidade a ref/commit_date voláteis.
# ---------------------------------------------------------------------------
run_plugins_sync_selftests() {
  local asm="${REPO_ROOT}/.claude/utils/marketplace/assemble-plugin.sh"
  local vdir="${REPO_ROOT}/.claude/utils/marketplace/verticals"
  if [ ! -f "${asm}" ] || [ ! -d "${vdir}" ]; then record_fail "plugins-sync" "assembler/verticals ausentes"; return; fi
  if ! command -v jq >/dev/null 2>&1; then record_skip "plugins-sync: jq ausente → pulado (gracioso)"; return; fi
  # Drift-guard de plugins committed é core-only: o adotante não vendoriza plugins/
  # (só verticals/*.manifest.sh). Sem plugins/ não há "committed" para comparar → pular.
  if [ ! -d "${REPO_ROOT}/plugins" ]; then record_skip "plugins-sync: sem plugins/ vendorizados → pulado (consumidor não publica plugins)"; return; fi
  local manifest name committed d csha tsha

  for manifest in "${vdir}"/*.manifest.sh; do
    [ -f "${manifest}" ] || continue
    name="$(. "${manifest}" >/dev/null 2>&1; printf '%s' "${PLUGIN_NAME:-}")"
    [ -n "${name}" ] || continue
    committed="${REPO_ROOT}/plugins/${name}"
    d="$(mktemp -d)"
    bash "${asm}" "${manifest}" "${REPO_ROOT}" "${d}/${name}" >/dev/null 2>&1
    csha="$(jq -r '.tree_sha' "${committed}/.claude-plugin/provenance.json" 2>/dev/null)"
    tsha="$(jq -r '.tree_sha' "${d}/${name}/.claude-plugin/provenance.json" 2>/dev/null)"
    # (a) committed em-sync com a fonte (diff ignorando provenance + tree_sha igual)
    if diff -r -x provenance.json "${committed}" "${d}/${name}" >/dev/null 2>&1 && [ "${csha}" = "${tsha}" ]; then
      record_pass "plugins-sync: ${name} committed em-sync com a fonte"
    else record_fail "plugins-sync: ${name} em-sync" "plugin committado diverge da regeneração — regenere"; fi
    # (b) adulteração no plugin → diff detecta
    printf '\n# tamper\n' >> "${d}/${name}/.claude-plugin/plugin.json"
    if ! diff -r -x provenance.json "${committed}" "${d}/${name}" >/dev/null 2>&1; then
      record_pass "plugins-sync: ${name} adulteração detectada"
    else record_fail "plugins-sync: ${name} detecção" "diff não pegou a adulteração"; fi
    rm -rf "${d}"
  done

  # (c) insensível a ref/commit_date voláteis: 2 provenances iguais salvo ref/date → diff -x ignora
  local p1 p2; p1="$(mktemp -d)"; p2="$(mktemp -d)"
  printf '{"tree_sha":"X","ref":"aaa","commit_date":"2020"}' > "${p1}/provenance.json"
  printf '{"tree_sha":"X","ref":"bbb","commit_date":"2099"}' > "${p2}/provenance.json"
  if diff -r -x provenance.json "${p1}" "${p2}" >/dev/null 2>&1; then
    record_pass "plugins-sync: ref/commit_date voláteis ignorados (diff -x provenance)"
  else record_fail "plugins-sync: voláteis" "diff -x provenance não isolou os campos voláteis"; fi
  rm -rf "${p1}" "${p2}"
}

# ---------------------------------------------------------------------------
# Modo role-bundle — exercita o mapa role→bundle (REGRA 37 check_role_bundle_sync) + o resolver:
# (a) resolver acerta papeis conhecidos (source não-vazio, distilled vazio) e rejeita inválido;
# (b) todo vertical em roles.yaml tem manifesto + está no marketplace.json (consistência).
# ---------------------------------------------------------------------------
run_role_bundle_selftests() {
  local roles="${REPO_ROOT}/.claude/utils/marketplace/roles.yaml"
  local resolver="${REPO_ROOT}/.claude/utils/marketplace/resolve-role-bundle.sh"
  local vdir="${REPO_ROOT}/.claude/utils/marketplace/verticals"
  local mkt="${REPO_ROOT}/.claude-plugin/marketplace.json"
  if [ ! -f "${roles}" ] || [ ! -f "${resolver}" ]; then record_skip "role-bundle: roles.yaml/resolver ausentes → pulado (repo sem a feature)"; return; fi
  if ! python3 -c "import yaml" >/dev/null 2>&1; then record_skip "role-bundle: pyyaml ausente → pulado (gracioso)"; return; fi

  if [ -n "$(bash "${resolver}" source 2>/dev/null)" ]; then record_pass "role-bundle: resolver source → não-vazio"
  else record_fail "role-bundle: resolver source" "esperava verticais para source"; fi
  if [ -z "$(bash "${resolver}" distilled 2>/dev/null)" ]; then record_pass "role-bundle: resolver distilled → vazio"
  else record_fail "role-bundle: resolver distilled" "distilled devia ser vazio"; fi
  if bash "${resolver}" xpto >/dev/null 2>&1; then record_fail "role-bundle: resolver inválido" "papel inválido devia falhar (exit 2)"
  else record_pass "role-bundle: resolver rejeita papel inválido"; fi

  local refs v ok=1 bad=""
  refs="$(python3 - "${roles}" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
s=set()
for role,spec in (d.get("roles") or {}).items():
    for k in ("base","optional"):
        for x in ((spec or {}).get(k) or []): s.add(x)
print("\n".join(sorted(s)))
PY
)"
  for v in ${refs}; do
    [ -n "${v}" ] || continue
    { [ -f "${vdir}/${v}.manifest.sh" ] && grep -q "\"${v}\"" "${mkt}" 2>/dev/null; } || { ok=0; bad="${v}"; break; }
  done
  if [ "${ok}" = 1 ]; then record_pass "role-bundle: verticais referenciados existem + registrados"
  else record_fail "role-bundle: consistência" "vertical '${bad}' sem manifesto ou fora do marketplace"; fi
}

# ---------------------------------------------------------------------------
# Modo capability — exercita o Capability Contract (REGRA 20 check_capability_conformance):
# (a) contratos reais são HONESTOS (tier reivindicado == cumprido) — catch de over-claim;
# (b) primitiva de resolução de REQUIRES (type:value) acerta presente e ausente.
# ---------------------------------------------------------------------------
run_capability_selftests() {
  local vdir="${REPO_ROOT}/.claude/utils/marketplace/verticals"
  [ -d "${vdir}" ] || { record_fail "capability" "verticals/ ausente"; return; }
  local manifest

  for manifest in "${vdir}"/*.manifest.sh; do
    [ -f "${manifest}" ] || continue
    local rep nm claimed met
    rep="$(
      REPO_ROOT="${REPO_ROOT}"; . "${manifest}" >/dev/null 2>&1
      b=1; { [ "${#PROVIDES[@]}" -gt 0 ] && [ -n "${PLUGIN_DESC:-}" ] && [ -n "${PLUGIN_VERSION:-}" ]; } || b=0
      un=""
      for r in "${REQUIRES[@]:-}"; do
        [ -n "${r}" ] || continue; ty="${r%%:*}"; va="${r#*:}"; ok=0
        case "${ty}" in
          agent) find "${REPO_ROOT}/.claude/agents" -name "${va}.md" 2>/dev/null|grep -q . && ok=1;;
          command) find "${REPO_ROOT}/.claude/commands" -name "${va}.md" 2>/dev/null|grep -q . && ok=1;;
          skill) [ -d "${REPO_ROOT}/.claude/skills/${va}" ] && ok=1;;
          validation) [ -f "${REPO_ROOT}/.claude/validation/${va}" ] && ok=1;;
          util) [ -d "${REPO_ROOT}/.claude/utils/${va}" ] && ok=1;;
          template) [ -f "${REPO_ROOT}/.claude/commands/common/templates/${va}" ] && ok=1;;
          env) grep -q "^${va}=" "${REPO_ROOT}/.env.example" 2>/dev/null && ok=1;;
          kb) [ -e "${REPO_ROOT}/docs/knowledge-base/${va}" ] && ok=1;;
        esac
        [ "${ok}" = 1 ] || un="${un} ${r}"
      done
      s=1; { [ "${b}" = 1 ] && [ -z "${un}" ]; } || s=0
      g=1; { [ "${s}" = 1 ] && [ "${#LOADS[@]}" -gt 0 ]; } || g=0
      m=none; [ "${b}" = 1 ] && m=bronze; [ "${s}" = 1 ] && m=silver; [ "${g}" = 1 ] && m=gold
      printf '%s|%s|%s' "${PLUGIN_NAME:-?}" "${CONFORMANCE:-bronze}" "${m}"
    )"
    nm="${rep%%|*}"; claimed="$(printf '%s' "${rep}" | cut -d'|' -f2)"; met="$(printf '%s' "${rep}" | cut -d'|' -f3)"
    rk() { case "$1" in bronze) echo 1;; silver) echo 2;; gold) echo 3;; *) echo 0;; esac; }
    if [ "$(rk "${claimed}")" -le "$(rk "${met}")" ]; then
      record_pass "capability: ${nm} contrato honesto (reivindica ${claimed} ⩽ cumpre ${met})"
    else record_fail "capability: ${nm} over-claim" "reivindica ${claimed} mas só cumpre ${met}"; fi
  done

  # (b) resolução: agente real resolve, bogus não
  if find "${REPO_ROOT}/.claude/agents" -name "soc2-specialist.md" 2>/dev/null | grep -q . \
     && ! find "${REPO_ROOT}/.claude/agents" -name "__nao_existe__.md" 2>/dev/null | grep -q .; then
    record_pass "capability: resolução de REQUIRES acerta presente/ausente"
  else record_fail "capability: resolução" "primitiva de resolução incorreta"; fi

  # (c)/(d) — MUT do desfecho REAL, não da réplica acima. (a) só prova que os manifestos
  # de HOJE são honestos; nunca prova que um desonesto seria pego. Injeta no vdir do
  # SANDBOX (cp -a de .claude — ver topo do arquivo) um manifesto sintético e roda o
  # lint-artifacts.sh de VERDADE (caixa-preta, sem refator — mesma disciplina do resto
  # deste arquivo). check_plugins_sync (REGRA 19) sempre dispara 'plugin ausente' pra
  # qualquer manifesto injetado (não há plugins/selftest-fixture-probe committado) — por
  # isso a asserção grepa a MENSAGEM específica de over-claim ('mas só cumpre'), não
  # 'nenhuma violação citando o path' (que reprovaria SEMPRE, até no caso honesto).
  local cap_vdir="${SANDBOX}/.claude/utils/marketplace/verticals"
  local cap_dst="${cap_vdir}/selftest-fixture-probe.manifest.sh"

  local ov_src="${FIX_DIR}/r20-capability-contract/bad-overclaim.manifest.sh"
  if [ -f "${ov_src}" ]; then
    cp "${ov_src}" "${cap_dst}"
    local ov_out
    ov_out="$(bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --only="${cap_dst}" 2>&1)" || true
    rm -f "${cap_dst}"
    if printf '%s\n' "${ov_out}" | grep -F "selftest-fixture-probe" | grep -q "mas só cumpre"; then
      record_pass "capability: over-claim sintético é pego pela guarda real (fixture r20)"
    else
      record_fail "capability: over-claim sintético" "guarda real não pegou o over-claim (rank/tier quebrados?)"
    fi
  else
    record_skip "capability: over-claim sintético → fixture r20 ausente"
  fi

  local gd_src="${FIX_DIR}/r20-capability-contract/good-honest.manifest.sh"
  if [ -f "${gd_src}" ]; then
    cp "${gd_src}" "${cap_dst}"
    local gd_out
    gd_out="$(bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --only="${cap_dst}" 2>&1)" || true
    rm -f "${cap_dst}"
    if printf '%s\n' "${gd_out}" | grep -F "selftest-fixture-probe" | grep -q "mas só cumpre"; then
      record_fail "capability: honesto sintético" "falso-positivo — guarda acusou over-claim num manifesto honesto"
    else
      record_pass "capability: honesto sintético não gera over-claim (fixture r20)"
    fi
  else
    record_skip "capability: honesto sintético → fixture r20 ausente"
  fi

  # ── CATRACA DOS GATES DE --only (Elenxo 2026-08-13, 2º round) ─────────────────────────────
  # Dois furos que a 1ª versão dos gates teve e que estas provas impedem de voltar:
  # (i) --only ABSOLUTO NÃO-CANÔNICO (/./ no meio) desligava a REGRA 20 inteira — o filtro era
  #     string-compare e o path não casava; a cura é inode-compare (-ef). Se alguém "simplificar"
  #     o -ef de volta para string, este caso FALHA.
  local nc_src="${REPO_ROOT}/.claude/validation/fixtures/r20-capability-contract/bad-overclaim.manifest.sh"
  local nc_dst="${SANDBOX}/.claude/utils/marketplace/verticals/selftest-noncanon-probe.manifest.sh"
  if [ -f "${nc_src}" ]; then
    cp "${nc_src}" "${nc_dst}"
    local nc_out
    nc_out="$(bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --only="${SANDBOX}/.claude/utils/marketplace/./verticals/selftest-noncanon-probe.manifest.sh" 2>&1)" || true
    rm -f "${nc_dst}"
    if printf '%s
' "${nc_out}" | grep -q "mas só cumpre"; then
      record_pass "only-gate: --only não-canônico (/./) mantém a R20 detectando (inode-compare vivo)"
    else
      record_fail "only-gate: --only não-canônico" "R20 ficou cega a path com /./ — o -ef regrediu para string-compare?"
    fi
  else
    record_skip "only-gate: não-canônico → fixture r20 ausente"
  fi
  # (ii) DRIFT EM FONTE BUNDLADA via --only deve acusar a R19 — a 1ª versão do gate (prefixo de
  #      path) engolia 2 HARD aqui; a cura é pertencimento ao manifesto (grep -qF). Se alguém
  #      estreitar o gate de volta para só marketplace/plugins, este caso FALHA.
  local bd_probe="${SANDBOX}/.claude/commands/meta/kg.md"
  if [ -f "${bd_probe}" ]; then
    printf '\n<!-- only-gate-probe -->\n' >> "${bd_probe}"
    local bd_out
    bd_out="$(bash "${SANDBOX}/.claude/validation/lint-artifacts.sh" --only="${bd_probe}" 2>&1)" || true
    # restaura o sandbox (outros casos usam o mesmo)
    sed -i '/only-gate-probe/d' "${bd_probe}"
    # A prova de vida da R19 tem DUAS formas, e a diferenca e o AMBIENTE, nao a guarda: no repo
    # real (plugins/ presente) o drift sai como "fora de sincronia"; no SANDBOX da bancada (que
    # copia .claude/ + docs/ mas NAO plugins/) sai como "plugin ausente". As duas provam que a
    # guarda RODOU sob --only de fonte bundlada. Se o gate regredir para prefixo-de-path, NENHUMA
    # aparece. (A 1a versao asserava so a 1a forma e falhou no sandbox — medido, nao suposto.)
    if printf '%s
' "${bd_out}" | grep -qE "fora de sincronia|plugin ausente"; then
      record_pass "only-gate: drift em fonte bundlada via --only acusa R19 (pertencimento ao manifesto vivo)"
    else
      record_fail "only-gate: fonte bundlada" "R19 não viu drift em comando bundlado sob --only — o gate regrediu para prefixo de path?"
    fi
  else
    record_skip "only-gate: fonte bundlada → kg.md ausente no sandbox"
  fi
}

# ---------------------------------------------------------------------------
# Modo graph — lente sócio-técnica (REGRA 21 check_graph_sync): graph.md em sincronia
# com a regeneração + determinismo + atores + a consulta de valor (impacto reverso).
# ---------------------------------------------------------------------------
run_graph_selftests() {
  local gen="${REPO_ROOT}/.claude/validation/graph.sh"
  local gfile="${REPO_ROOT}/docs/onion/graph.md"
  if [ ! -f "${gen}" ]; then record_fail "graph" "graph.sh ausente"; return; fi

  # Guardas SEM dependência de jq (rodam sempre — o bug do parser não depende dele):
  # (a) unit: yaml_list restrito ao FRONTMATTER — corpo com exemplos de template
  #     (related_agents: ["agente-1",...]) não pode virar tripla (incidente 2026-07-03:
  #     7 nós fantasma + 5 arestas falsas p/ nós reais no grafo canônico).
  local yfn; yfn="$(sed -n '/^yaml_list()/,/^}/p' "${gen}")"
  if [ -n "${yfn}" ]; then
    eval "${yfn}"
    local fx; fx="$(mktemp)"
    printf -- '---\nname: fx\nrelated_agents:\n  - real-a\n  - real-b\n---\n\n# corpo\n\nrelated_agents: ["agente-1", "agente-2"]\nrelated_commands: ["/comando-1"]\n' > "${fx}"
    local got; got="$(yaml_list "${fx}" "related_agents" | tr '\n' ',')"
    if [ "${got}" = "real-a,real-b," ]; then record_pass "graph: yaml_list lê só o frontmatter (corpo com template ignorado)"
    else record_fail "graph: yaml_list frontmatter-only" "esperado 'real-a,real-b,' — obtido '${got}'"; fi
    rm -f "${fx}"
  else
    record_fail "graph: yaml_list" "função yaml_list não encontrada em graph.sh"
  fi
  # (b) regressão nos dados reais: nenhum nó de template no grafo
  if bash "${gen}" --triples 2>/dev/null | grep -qE 'agente-[0-9]|comando-[0-9]|autonomy:'; then
    record_fail "graph: sem ruído de template" "triplas contêm placeholders (agente-N/comando-N/autonomy:)"
  else record_pass "graph: triplas sem ruído de template (placeholders de exemplos)"; fi

  if ! command -v jq >/dev/null 2>&1; then record_skip "graph: jq ausente → demais checks pulados (gracioso)"; return; fi
  # Core-only: o grafo canônico (graph.md em-sync) e o --impact assumem as verticais
  # PUBLICADAS (ex.: onion-design). Um consumidor não vendoriza plugins/ → a regeneração
  # local diverge do graph.md committed por construção. Pular gracioso (a guarda de drift
  # do grafo é autoral do core, onde plugins/ existe e é validada estritamente).
  if [ ! -d "${REPO_ROOT}/plugins" ]; then record_pass "graph: sem plugins/ vendorizados → pulado (grafo canônico é autoral do core)"; return; fi

  local tmp; tmp="$(mktemp)"; bash "${gen}" --markdown > "${tmp}" 2>/dev/null
  if diff -q "${gfile}" "${tmp}" >/dev/null 2>&1; then record_pass "graph: graph.md em-sync com a spec-as-code"
  else record_fail "graph: em-sync" "graph.md diverge da regeneração — regenere"; fi
  rm -f "${tmp}"

  # triplas computadas UMA vez, reusadas (perf — evita re-invocar graph.sh)
  local T T2; T="$(bash "${gen}" --triples 2>/dev/null)"; T2="$(bash "${gen}" --triples 2>/dev/null)"
  if [ "$(printf '%s' "${T}" | sha256sum)" = "$(printf '%s' "${T2}" | sha256sum)" ]; then
    record_pass "graph: triplas determinísticas"
  else record_fail "graph: determinismo" "triplas variam entre execuções"; fi

  if printf '%s\n' "${T}" | grep -q "^maestro	gates	assistant" \
     && printf '%s\n' "${T}" | grep -q "^onion	serves	maestro"; then
    record_pass "graph: atores+comunicação presentes (maestro/assistant/onion)"
  else record_fail "graph: atores" "arestas de ator/comunicação ausentes"; fi

  if bash "${gen}" --impact design-system-specialist 2>/dev/null | grep -q "onion-design"; then
    record_pass "graph: --impact retorna dependentes reais"
  else record_fail "graph: --impact" "impacto reverso não achou dependente conhecido"; fi

  # --closure: fecho transitivo direto (auto-escopo de bundle) alcança require direto E,
  # via ponte de prefixo (agent:X → X), o nó basename que carrega related_*.
  local clo; clo="$(bash "${gen}" --closure onion-engineering 2>/dev/null)"
  if printf '%s\n' "${clo}" | grep -qE '^  agent:gitflow-specialist$' \
     && printf '%s\n' "${clo}" | grep -qE '^  gitflow-specialist$'; then
    record_pass "graph: --closure alcança require direto + ponte de prefixo (agent:X→X)"
  else record_fail "graph: --closure" "fecho transitivo não achou require/basename conhecido"; fi
  # --closure sem semente → uso + exit 2 (|| captura: sob set -e, exit 2 abortaria o harness)
  local crc=0; bash "${gen}" --closure >/dev/null 2>&1 || crc=$?
  if [ "${crc}" = 2 ]; then record_pass "graph: --closure sem semente → exit 2"
  else record_fail "graph: --closure uso" "esperava exit 2 sem semente (obtido ${crc})"; fi

  # F1.1 — ingestão de members.yaml (fonte 5) + mapa Mermaid derivado. Pula gracioso sem python+yaml.
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
     && [ -f "${REPO_ROOT}/docs/evolution/federation/members.yaml" ]; then
    if printf '%s\n' "${T}" | grep -qE '	adopts	onion-evolve	' \
       && printf '%s\n' "${T}" | grep -qE '	tier	(source|hub|standalone)	'; then
      record_pass "graph: members.yaml ingerido (adopts/tier na federação)"
    else record_fail "graph: members ingest" "triplas sem arestas de membro (adopts/tier)"; fi
    local M; M="$(bash "${gen}" --map 2>/dev/null)"
    if printf '%s\n' "${M}" | grep -q 'flowchart TD' \
       && printf '%s\n' "${M}" | grep -q -- '-->|adopts|' \
       && printf '%s\n' "${M}" | grep -q 'classDef source'; then
      record_pass "graph: --map emite Mermaid derivado (flowchart + adopts + classDef)"
    else record_fail "graph: --map" "mapa Mermaid inválido (falta flowchart/adopts/classDef)"; fi
    # determinismo do --map (compara dois valores capturados — ambos sem newline final)
    local M2; M2="$(bash "${gen}" --map 2>/dev/null)"
    if [ "$(printf '%s' "${M}" | sha256sum)" = "$(printf '%s' "${M2}" | sha256sum)" ]; then
      record_pass "graph: --map determinístico"
    else record_fail "graph: --map determinismo" "mapa varia entre execuções"; fi
  else
    record_skip "graph: members/--map pulados (sem python+yaml — gracioso)"
  fi
}

# ---------------------------------------------------------------------------
# Modo design-tokens — exercita .claude/validation/lint-design-tokens.sh.
# Self-contained (mktemp), cobre MODOS DE FALHA: tokens válidos passam;
# alias órfão / ciclo de referência / contraste WCAG abaixo do mínimo viram
# HARD (exit 1); design-context ausente é gracioso (exit 0).
# Pula se jq/awk ausentes (mesma graça do gate).
# ---------------------------------------------------------------------------
run_design_tokens_selftests() {
  local gate="${REPO_ROOT}/.claude/validation/lint-design-tokens.sh"
  if [ ! -f "${gate}" ]; then record_fail "design-tokens" "gate ausente: ${gate}"; return; fi
  if ! command -v jq >/dev/null 2>&1 || ! command -v awk >/dev/null 2>&1; then
    record_skip "design-tokens (skip: jq/awk ausente)"; return
  fi
  local d rc
  local mkdc # cria docs/design-context com 1 arquivo de tokens + pares de contraste
  mkdc() { local base="$1"; mkdir -p "${base}/docs/design-context/semantic" "${base}/docs/design-context/governance"; }

  # (a) tokens válidos (alias resolve, contraste alto) → exit 0
  d="$(mktemp -d)"; mkdc "${d}"
  printf '%s' '{"color":{"$type":"color","ink":{"$value":"#1A1714"},"paper":{"$value":"#FFFFFF"},"text":{"$value":"{color.ink}"}}}' \
    > "${d}/docs/design-context/semantic/c.tokens.json"
  printf '%s' '{"pairs":[{"fg":"color.text","bg":"color.paper","min":4.5,"note":"ok"}]}' \
    > "${d}/docs/design-context/governance/contrast-pairs.json"
  rc=0; bash "${gate}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "design-tokens: válidos passam"
  else record_fail "design-tokens: válidos" "esperava exit 0, veio ${rc}"; fi
  rm -rf "${d}"

  # (b) alias órfão → HARD (exit 1)
  d="$(mktemp -d)"; mkdc "${d}"
  printf '%s' '{"color":{"$type":"color","x":{"$value":"{color.nope}"}}}' \
    > "${d}/docs/design-context/semantic/c.tokens.json"
  rc=0; bash "${gate}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "design-tokens: alias órfão → HARD"
  else record_fail "design-tokens: órfão" "esperava exit 1, veio ${rc}"; fi
  rm -rf "${d}"

  # (c) ciclo de referência → HARD
  d="$(mktemp -d)"; mkdc "${d}"
  printf '%s' '{"color":{"$type":"color","a":{"$value":"{color.b}"},"b":{"$value":"{color.a}"}}}' \
    > "${d}/docs/design-context/semantic/c.tokens.json"
  rc=0; bash "${gate}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "design-tokens: ciclo → HARD"
  else record_fail "design-tokens: ciclo" "esperava exit 1, veio ${rc}"; fi
  rm -rf "${d}"

  # (d) contraste WCAG abaixo do mínimo → HARD
  d="$(mktemp -d)"; mkdc "${d}"
  printf '%s' '{"color":{"$type":"color","fg":{"$value":"#999999"},"bg":{"$value":"#FFFFFF"}}}' \
    > "${d}/docs/design-context/semantic/c.tokens.json"
  printf '%s' '{"pairs":[{"fg":"color.fg","bg":"color.bg","min":4.5,"note":"cinza fraco"}]}' \
    > "${d}/docs/design-context/governance/contrast-pairs.json"
  rc=0; bash "${gate}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 1 ]; then record_pass "design-tokens: contraste baixo → HARD"
  else record_fail "design-tokens: contraste" "esperava exit 1, veio ${rc}"; fi
  rm -rf "${d}"

  # (e) design-context ausente → gracioso (exit 0)
  d="$(mktemp -d)"
  rc=0; bash "${gate}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "design-tokens: contexto ausente → gracioso"
  else record_fail "design-tokens: ausente" "esperava exit 0, veio ${rc}"; fi
  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo co-relay — exercita .claude/utils/co-evolution/co-relay.sh (carteiro
# UPSTREAM, entrega-sem-commit). Self-contained (mktemp): adotante + core temp.
# Cobre MODOS DE FALHA + a PROVA do invariante (untracked, sem commit) + a
# REGRESSÃO crítica: a guarda lê o STAMP .onion-version, NÃO onion-version.sh
# (que hardcoda 'source' e mentiria no adotante). Espelho do co-deliver.
# ---------------------------------------------------------------------------
run_corelay_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/co-evolution/co-relay.sh"
  if [ ! -f "${helper}" ]; then record_fail "co-relay" "helper ausente: ${helper}"; return; fi
  local d core rc
  local SIG="docs/evolution/inbox/2026-01-01-sinal-teste.md"

  # builder: cria adotante git em $1 com stamp role=$2 + 1 sinal no inbox
  mk_adopter() {
    git -C "$1" init -q
    mkdir -p "$1/.claude" "$1/docs/evolution/inbox"
    printf 'role: %s\n' "$2" > "$1/.claude/.onion-version"
    printf '# sinal de teste\n' > "$1/${SIG}"
  }

  # (a) stamp role:source → exit 2 (rejeita CORE)
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q; mkdir -p "${core}/docs/evolution/inbox"
  mk_adopter "${d}" source
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "co-relay: stamp source → exit 2 (rejeita core)"
  else record_fail "co-relay: stamp source" "esperava exit 2, veio ${rc}"; fi
  rm -rf "${d}" "${core}"

  # (b) stamp role:adopted + alvo válido → relay ocorre (sinal aparece no inbox do core)
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q; mkdir -p "${core}/docs/evolution/inbox"
  mk_adopter "${d}" adopted
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${core}/${SIG}" ]; then record_pass "co-relay: adopted + alvo → relaya"
  else record_fail "co-relay: adopted relaya" "exit ${rc} ou sinal não chegou ao inbox do core"; fi
  rm -rf "${d}" "${core}"

  # (c) ANTI-REGRESSÃO: onion-version.sh presente (emite 'source') MAS stamp 'adopted' → DEVE seguir
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q; mkdir -p "${core}/docs/evolution/inbox"
  mk_adopter "${d}" adopted
  mkdir -p "${d}/.claude/validation"; cp "${REPO_ROOT}/.claude/validation/onion-version.sh" "${d}/.claude/validation/" 2>/dev/null || true
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${core}/${SIG}" ]; then record_pass "co-relay: lê o STAMP, não onion-version.sh (anti-regressão)"
  else record_fail "co-relay: guarda via stamp" "exit ${rc} — guarda usou onion-version.sh ('source') em vez do stamp?"; fi
  rm -rf "${d}" "${core}"

  # (d) --target ausente → exit 2
  d="$(mktemp -d)"; mk_adopter "${d}" adopted
  rc=0; ( cd "${d}" && bash "${helper}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "co-relay: --target ausente → exit 2"
  else record_fail "co-relay: --target ausente" "esperava exit 2, veio ${rc}"; fi
  rm -rf "${d}"

  # (e) --target inválido (não-git) → exit 2
  d="$(mktemp -d)"; core="$(mktemp -d)"; mk_adopter "${d}" adopted   # core SEM git init
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "co-relay: --target não-git → exit 2"
  else record_fail "co-relay: --target não-git" "esperava exit 2, veio ${rc}"; fi
  rm -rf "${d}" "${core}"

  # (f) --target sem docs/evolution/inbox → mkdir -p + AVISO, não falha hard (entrega ocorre)
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q   # core sem o canal
  mk_adopter "${d}" adopted
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${core}/${SIG}" ]; then record_pass "co-relay: canal ausente → mkdir -p + entrega (simetria co-deliver)"
  else record_fail "co-relay: canal ausente" "exit ${rc} — deveria criar inbox/ e entregar, não falhar"; fi
  rm -rf "${d}" "${core}"

  # (g) PROVA DO INVARIANTE: pós-relay, sinal é UNTRACKED no core e NÃO há commit novo
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q; mkdir -p "${core}/docs/evolution/inbox"
  mk_adopter "${d}" adopted
  ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || true
  local st commits
  st="$(git -C "${core}" status --porcelain -- "${SIG}" 2>/dev/null | head -1)"
  commits="$(git -C "${core}" rev-list --all --count 2>/dev/null || echo 0)"
  if [ "${st#'??'}" != "${st}" ] && [ "${commits}" = "0" ]; then record_pass "co-relay: entrega-sem-commit (untracked, 0 commits no core)"
  else record_fail "co-relay: invariante I3" "esperava untracked (??) e 0 commits; status='${st}' commits=${commits}"; fi
  rm -rf "${d}" "${core}"

  # (h) never-clobber: sinal já presente no inbox do core → no-op exit 0
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q; mkdir -p "${core}/docs/evolution/inbox"
  mk_adopter "${d}" adopted
  printf '# já existe (versão do core)\n' > "${core}/${SIG}"
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q 'versão do core' "${core}/${SIG}"; then record_pass "co-relay: never-clobber (no-op idempotente)"
  else record_fail "co-relay: never-clobber" "exit ${rc} — clobberou o arquivo já presente?"; fi
  rm -rf "${d}" "${core}"

  # (i) --dry-run não escreve nada
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q; mkdir -p "${core}/docs/evolution/inbox"
  mk_adopter "${d}" adopted
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" --dry-run ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ ! -f "${core}/${SIG}" ]; then record_pass "co-relay: --dry-run não escreve"
  else record_fail "co-relay: --dry-run" "exit ${rc} — dry-run escreveu no inbox do core?"; fi
  rm -rf "${d}" "${core}"

  # (j) DEDUP por conteúdo: sinal IDÊNTICO já triado em _processed/ (nome diferente) → no-op
  #     (regressão do incidente 2026-07-03: carteiro re-entregou 3 sinais pós-triagem → 📬 fantasma)
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q
  mkdir -p "${core}/docs/evolution/inbox/_processed"
  mk_adopter "${d}" adopted
  printf '# sinal de teste\n' > "${core}/docs/evolution/inbox/_processed/2025-12-31-outro-nome.md"
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ ! -f "${core}/${SIG}" ]; then
    record_pass "co-relay: conteúdo idêntico já em _processed → no-op (regressão 📬 fantasma 2026-07-03)"
  else record_fail "co-relay: dedup _processed" "exit ${rc} — re-entregou sinal já triado (existe=$([ -f "${core}/${SIG}" ] && echo sim || echo não))"; fi
  rm -rf "${d}" "${core}"

  # (k) sinal ATUALIZADO: mesmo nome em _processed mas conteúdo DIFERENTE → DEVE entregar
  #     (a pergunta do maestro "elas não foram atualizadas?" virou guarda: update ≠ duplicata)
  d="$(mktemp -d)"; core="$(mktemp -d)"; git -C "${core}" init -q
  mkdir -p "${core}/docs/evolution/inbox/_processed"
  mk_adopter "${d}" adopted
  printf '# versão antiga já triada\n' > "${core}/docs/evolution/inbox/_processed/2026-01-01-sinal-teste.md"
  rc=0; ( cd "${d}" && bash "${helper}" --target "${core}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${core}/${SIG}" ] && grep -q 'sinal de teste' "${core}/${SIG}"; then
    record_pass "co-relay: mesmo nome, conteúdo novo → entrega (sinal atualizado ≠ duplicata)"
  else record_fail "co-relay: sinal atualizado" "exit ${rc} — dedup bloqueou uma atualização legítima?"; fi
  rm -rf "${d}" "${core}"
}

# ---------------------------------------------------------------------------
# Modo co-deliver — exercita .claude/utils/co-evolution/co-deliver.sh (carteiro
# DOWNSTREAM, espelho do co-relay). Foco: resolução do path do adotante pelo
# members.yaml (campo local_path: com comentário inline — regressão do sinal
# 2026-07-10-co-deliver-local-path-gap) + --target soberano + membro sem path
# → exit 2. Self-contained (mktemp).
# ---------------------------------------------------------------------------
run_codeliver_selftests() {
  local helper="${REPO_ROOT}/.claude/utils/co-evolution/co-deliver.sh"
  if [ ! -f "${helper}" ]; then record_fail "co-deliver" "helper ausente: ${helper}"; return; fi
  local core adopter other rc

  # builder: core temp (repo git + members.yaml + outbox com 1 rascunho); $2 = local_path (vazio = sem path)
  mk_deliver_core() {
    git -C "$1" init -q
    mkdir -p "$1/docs/evolution/federation/outbox/alvo"
    printf '# anúncio de teste\n' > "$1/docs/evolution/federation/outbox/alvo/2026-01-01-anuncio.md"
    {
      printf 'members:\n'
      printf '  - id: alvo\n    role: standalone\n    name: "Alvo Teste"\n'
      if [ -n "$2" ]; then printf '    local_path: "%s"   # comentário inline (caso real do members.yaml)\n' "$2"; fi
    } > "$1/docs/evolution/federation/members.yaml"
  }

  # (a) resolve local_path do members.yaml (com comentário inline) — SEM --target
  core="$(mktemp -d)"; adopter="$(mktemp -d)"; git -C "${adopter}" init -q; mkdir -p "${adopter}/docs/evolution"
  mk_deliver_core "${core}" "${adopter}"
  rc=0; ( cd "${core}" && bash "${helper}" alvo ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${adopter}/docs/evolution/inbound/2026-01-01-anuncio.md" ]; then
    record_pass "co-deliver: resolve local_path do members.yaml (regressão sinal 2026-07-10)"
  else record_fail "co-deliver: local_path" "exit ${rc} — não resolveu local_path do members.yaml"; fi
  rm -rf "${core}" "${adopter}"

  # (b) membro SEM local_path/path e sem --target → exit 2 (mensagem acionável)
  core="$(mktemp -d)"; mk_deliver_core "${core}" ""
  rc=0; ( cd "${core}" && bash "${helper}" alvo ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 2 ]; then record_pass "co-deliver: sem path resolvível → exit 2"
  else record_fail "co-deliver: sem path" "esperava exit 2, veio ${rc}"; fi
  rm -rf "${core}"

  # (c) --target é soberano (vence o local_path do members.yaml)
  core="$(mktemp -d)"; adopter="$(mktemp -d)"; other="$(mktemp -d)"
  git -C "${adopter}" init -q; git -C "${other}" init -q; mkdir -p "${other}/docs/evolution"
  mk_deliver_core "${core}" "${adopter}"
  rc=0; ( cd "${core}" && bash "${helper}" alvo --target "${other}" ) >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ -f "${other}/docs/evolution/inbound/2026-01-01-anuncio.md" ] \
     && [ ! -e "${adopter}/docs/evolution/inbound/2026-01-01-anuncio.md" ]; then
    record_pass "co-deliver: --target soberano sobre members.yaml"
  else record_fail "co-deliver: --target" "exit ${rc} — entrega não foi (só) ao --target"; fi
  rm -rf "${core}" "${adopter}" "${other}"
}

# ---------------------------------------------------------------------------
# Modo de-identification — exercita o baseline determinístico (adapter `regex` da
# abstração SDAAL de-identification). Self-contained (mktemp). Cobre MODOS DE FALHA:
# PII conhecida é redigida; round-trip redact→restore reconstrói o original; texto
# sem PII é no-op idempotente; saída determinística entre execuções; valor repetido
# vira o MESMO placeholder. python3 ausente → pulado (gracioso, igual jq no graph).
# ---------------------------------------------------------------------------
run_de_identification_selftests() {
  local s="${REPO_ROOT}/.claude/utils/de-identification/scripts/redact-deterministic.sh"
  if [ ! -f "${s}" ]; then record_fail "de-id" "script ausente: ${s}"; return; fi
  if ! command -v python3 >/dev/null 2>&1; then record_skip "de-id: python3 ausente → pulado (gracioso)"; return; fi

  local map red restored
  local sample='email a@b.com.br, CPF 123.456.789-09, CNPJ 12.345.678/0001-99, tel (11) 98765-4321, cartão 4111 1111 1111 1111, IP 10.0.0.1; de novo a@b.com.br'

  # (a) PII conhecida é redigida — placeholders presentes, originais ausentes
  map="$(mktemp)"; red="$(printf '%s' "${sample}" | bash "${s}" --redact --map "${map}")"
  if printf '%s' "${red}" | grep -q '\[\[EMAIL_1\]\]' \
     && printf '%s' "${red}" | grep -q '\[\[CPF_1\]\]' \
     && printf '%s' "${red}" | grep -q '\[\[CARD_1\]\]' \
     && ! printf '%s' "${red}" | grep -q '123\.456\.789-09'; then
    record_pass "de-id: PII de formato fixo é redigida (email/CPF/CNPJ/tel/cartão/IP)"
  else record_fail "de-id: redação" "PII não redigida ou original vazou no texto"; fi

  # (b) round-trip redact→restore reconstrói o original
  restored="$(printf '%s' "${red}" | bash "${s}" --restore --map "${map}")"
  if [ "${restored}" = "${sample}" ]; then record_pass "de-id: round-trip redact→restore é fiel"
  else record_fail "de-id: round-trip" "restore não reconstruiu o original"; fi
  rm -f "${map}"

  # (c) dedupe — valor repetido vira o MESMO placeholder (reidentificação consistente)
  if [ "$(printf '%s' "${red}" | grep -oE 'EMAIL_[0-9]+' | sort -u | wc -l)" = "1" ]; then
    record_pass "de-id: valor repetido → mesmo placeholder (dedupe estável)"
  else record_fail "de-id: dedupe" "email repetido gerou placeholders distintos"; fi

  # (d) texto sem PII → no-op idempotente
  local clean='Reunião amanhã sobre o roadmap, sem dados pessoais.'
  if [ "$(printf '%s' "${clean}" | bash "${s}" --redact --map "$(mktemp)")" = "${clean}" ]; then
    record_pass "de-id: texto sem PII → no-op idempotente"
  else record_fail "de-id: no-op" "redação alterou texto sem PII"; fi

  # (e) determinismo — mesma entrada, duas execuções → saída idêntica
  local a b
  a="$(printf '%s' "${sample}" | bash "${s}" --redact --map "$(mktemp)")"
  b="$(printf '%s' "${sample}" | bash "${s}" --redact --map "$(mktemp)")"
  if [ "${a}" = "${b}" ]; then record_pass "de-id: redação determinística (2 execuções idênticas)"
  else record_fail "de-id: determinismo" "saída variou entre execuções"; fi
}

# ---------------------------------------------------------------------------
# Modo trust-topology — exercita .claude/validation/trust-topology-check.sh
# (RFC-0003 §2.5). Self-contained (mktemp --repo → members.yaml e trust-log
# ficam no sandbox; NUNCA toca o trust-log real). Cobre a regressão FED-2-0
# (auditoria 2026-07-01): campos do bloco `trust:` a 6 espaços COM comentário
# inline devem casar — o bug tornava a topologia granular sempre-falsa. E os
# MODOS DE FALHA: lista vazia, trust unidirecional, standalone sem canal
# lateral, membro inexistente.
# ---------------------------------------------------------------------------
run_trust_topology_selftests() {
  local chk="${REPO_ROOT}/.claude/validation/trust-topology-check.sh"
  if [ ! -f "${chk}" ]; then record_fail "trust-topology" "script ausente: ${chk}"; return; fi

  local d="$(mktemp -d)"
  mkdir -p "${d}/docs/evolution/federation"
  # Schema FIEL ao members.yaml real: campos de trust a 6 espaços + comentário inline
  cat > "${d}/docs/evolution/federation/members.yaml" <<'YAML'
version: 2
members:
  - id: onion-evolve
    role: source
  - id: hub-a
    role: hub
    trust:
      can_receive_from: [onion-evolve, hub-b]    # quem pode me mandar conselho
      can_advise_to: [onion-evolve, hub-b]       # quem posso aconselhar
      can_correct_to: [onion-evolve]             # quem posso propor correção
      exposes_downstream: [t2-x]                 # meus sub-adotados
  - id: hub-b
    role: hub
    trust:
      can_receive_from: [onion-evolve, hub-a]
      can_advise_to: [onion-evolve]
      can_correct_to: []                         # nenhum por padrão
  - id: solo-c
    role: standalone
  - id: t2-x
    role: consumer
    parent: hub-a
YAML

  local rc
  tt() { # tt <from> <to> <action> <exit-esperado> <label>
    local want="$4" label="$5"; rc=0
    bash "${chk}" --from "$1" --to "$2" --action "$3" --repo "${d}" >/dev/null 2>&1 || rc=$?
    if [ "${rc}" -eq "${want}" ]; then record_pass "trust: ${label}"
    else record_fail "trust: ${label}" "esperava exit ${want}, veio ${rc}"; fi
  }

  # Regressão FED-2-0: campo populado (6 espaços + comentário inline) DEVE casar
  tt hub-a onion-evolve correct 0 "can_correct_to populado autoriza (regressão FED-2-0)"
  tt hub-a t2-x relay           0 "hub→T2 via exposes_downstream"
  tt hub-a hub-b advise         0 "hub↔hub bidirecional autoriza"
  # Modos de falha: a topologia granular deve continuar BLOQUEANDO
  tt hub-b onion-evolve correct 1 "can_correct_to vazio bloqueia"
  tt hub-b hub-a advise         1 "trust unidirecional bloqueia"
  tt solo-c hub-a relay         1 "standalone sem canal lateral"
  tt hub-a hub-b correct        1 "correct peer exige core como broker"
  # Regras por role (não podem regredir)
  tt onion-evolve hub-a relay   0 "source tem autoridade universal"
  tt hub-b onion-evolve advise  0 "inbox do core aberto p/ advise"
  tt ghost hub-a relay          2 "membro inexistente → exit 2"
  # Invariante de auditabilidade: toda tentativa logada (no sandbox, não no real)
  if [ -f "${d}/docs/evolution/trust-log.md" ] && [ "$(grep -c '^|' "${d}/docs/evolution/trust-log.md")" -ge 10 ]; then
    record_pass "trust: toda tentativa logada (sandbox via --repo)"
  else record_fail "trust: log auditável" "trust-log.md do sandbox ausente/incompleto"; fi

  # --dry-run: mesmo veredito, NADA gravado (log não nasce num sandbox limpo)
  local d2; d2="$(mktemp -d)"; cp -r "${d}/docs" "${d2}/docs"; rm -f "${d2}/docs/evolution/trust-log.md"
  rc=0; bash "${chk}" --from hub-a --to onion-evolve --action correct --repo "${d2}" --dry-run >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && [ ! -f "${d2}/docs/evolution/trust-log.md" ]; then
    record_pass "trust: --dry-run dá veredito sem gravar no log"
  else record_fail "trust: --dry-run" "esperava exit 0 sem trust-log.md; exit=${rc}, log $( [ -f "${d2}/docs/evolution/trust-log.md" ] && echo criado || echo ausente )"; fi
  rm -rf "${d2}"

  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo onion-version — exercita a detecção de papel de onion-version.sh
# (regressão FED-3-1 da auditoria 2026-07-01: o script emitia 'role: source'
# HARDCODED, tornando inofensivo o guard de identidade do /meta:adopt em
# instância adotada — o script é vendorizado para todo alvo). Self-contained:
# copia o script p/ repo temp e varia a presença/conteúdo do stamp.
# ---------------------------------------------------------------------------
run_onion_version_selftests() {
  local ov="${REPO_ROOT}/.claude/validation/onion-version.sh"
  if [ ! -f "${ov}" ]; then record_fail "onion-version" "script ausente: ${ov}"; return; fi
  local d out

  # (a) repo-fonte (sem stamp) → role: source
  d="$(mktemp -d)"; mkdir -p "${d}/.claude/validation"; cp "${ov}" "${d}/.claude/validation/"
  git -C "${d}" init -q
  out="$(bash "${d}/.claude/validation/onion-version.sh" | grep '^role:' || true)"
  if [ "${out}" = "role: source" ]; then record_pass "onion-version: sem stamp → source"
  else record_fail "onion-version: sem stamp" "esperava 'role: source', veio '${out}'"; fi

  # (b) stamp role: adopted → o GATE do /meta:adopt (grep '^role: (source|hub)') REJEITA (FED-3-1: consumidor não re-adota)
  printf 'framework: onion\nsource_commit: abc123\nrole: adopted\n' > "${d}/.claude/.onion-version"
  out="$(bash "${d}/.claude/validation/onion-version.sh" | grep '^role:' || true)"
  if [ "${out}" = "role: adopted" ] \
     && ! bash "${d}/.claude/validation/onion-version.sh" | grep -qE '^role: (source|hub)'; then
    record_pass "onion-version: stamp adopted → gate do adopt REJEITA (FED-3-1 vivo)"
  else record_fail "onion-version: stamp adopted" "gate deveria rejeitar adopted; veio '${out}'"; fi

  # (c) stamp presente SEM campo role → adopted por definição (nunca 'source' por omissão)
  printf 'framework: onion\n' > "${d}/.claude/.onion-version"
  out="$(bash "${d}/.claude/validation/onion-version.sh" | grep '^role:' || true)"
  if [ "${out}" = "role: adopted" ]; then record_pass "onion-version: stamp sem role → adopted (fail-safe)"
  else record_fail "onion-version: stamp sem role" "esperava 'role: adopted', veio '${out}'"; fi

  # (d) stamp role: hub → o GATE ACEITA (Camada 2 — a empresa adota os próprios projetos)
  printf 'framework: acme-adopter\nsource_commit: abc123\nrole: hub\n' > "${d}/.claude/.onion-version"
  out="$(bash "${d}/.claude/validation/onion-version.sh" | grep '^role:' || true)"
  if [ "${out}" = "role: hub" ] \
     && bash "${d}/.claude/validation/onion-version.sh" | grep -qE '^role: (source|hub)'; then
    record_pass "onion-version: stamp hub → gate do adopt ACEITA (Camada 2 aberta)"
  else record_fail "onion-version: stamp hub" "gate deveria aceitar hub; veio '${out}'"; fi
  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo kg-provenance — GATE DE PROVENIÊNCIA INVERTIDO com catraca (REGRA 29).
#
# Origem: sinal de um adotante regulado 2026-07-20 — a doutrina KG-SSOT tinha forcing function só
# na LEITURA; nada impedia conhecimento de NASCER fora do grafo.
#
# Este bloco NÃO testa só o happy-path da regra: testa os PRESSUPOSTOS de que ela
# depende para valer (regra de admissão da casa, docs/knowledge-base/concepts/
# inference-mitigation.md). São quatro, e cada um tem caso próprio:
#   (P1) SEVERIDADE — provada por DELTA no lint REAL, não declarada em comentário.
#   (P2) DECIDIDO SÓ COM O REPO — nenhum insumo externo; roda em repo isolado.
#   (P3) BASELINE — só encolhe (crescer = HARD) e sua AUSÊNCIA degrada gracioso
#        (uma HARD acionável) em vez de LIBERAR TUDO.
#   (P4) MUTATION TEST — desfazendo a condição central, um caso FALHA.
# Sandboxes self-contained (mktemp), sem fixture-file.
# ---------------------------------------------------------------------------

# Monta um repo mínimo com o escopo do gate. Ecoa o diretório criado.
_prov_make_repo() {
  local d; d="$(mktemp -d)"
  mkdir -p "${d}/.claude/validation" "${d}/docs/analysis" "${d}/docs/evolution/research/tema-x"
  cp "${REPO_ROOT}/.claude/validation/kg-provenance-coverage.sh" "${d}/.claude/validation/"
  [ -f "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" ] \
    && cp "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" "${d}/.claude/validation/"

  printf '# coberto\n'  > "${d}/docs/analysis/coberto.md"
  printf '# passivo\n'  > "${d}/docs/analysis/passivo.md"
  printf '# novo\n'     > "${d}/docs/analysis/novo.md"
  printf '# adr\n'      > "${d}/docs/analysis/onion-adr-excluido.md"
  printf '# readme\n'   > "${d}/docs/analysis/README.md"
  printf '%s\n' '---' 'type: adr' '---' '# adr por frontmatter' > "${d}/docs/analysis/decisao-sem-prefixo.md"
  printf '# sintese\n'  > "${d}/docs/evolution/research/tema-x/SYNTHESIS.md"

  # Grafo: `trace:` com sufixo :NNN (normalização) + `evidence:` em LISTA.
  cat > "${d}/docs/evolution/research/tema-x/tema-x.kg.yaml" <<'KGEOF'
meta:
  id: tema-x
nodes:
  - id: E1
    node_type: evidence
    trace: "docs/analysis/coberto.md:42"
  - id: C1
    node_type: claim
    evidence:
      - "./docs/evolution/research/tema-x/SYNTHESIS.md"
KGEOF

  printf '# baseline\ndocs/analysis/passivo.md\n' > "${d}/.claude/validation/kg-coverage-baseline.txt"
  printf '%s\n' "${d}"
}

# _prov_run <repo> [args...] — preenche os globais _PROV_OUT (TSV) e _PROV_RC.
# NÃO ecoa o resultado: o chamador precisa do rc, e `x="$(_prov_run …)"` rodaria
# num SUBSHELL, onde a atribuição de _PROV_RC morre (armadilha real deste teste).
_prov_run() {
  local repo="$1"; shift
  local tf; tf="$(mktemp)"
  set +e
  bash "${repo}/.claude/validation/kg-provenance-coverage.sh" "${repo}" --format tsv "$@" >"${tf}" 2>/dev/null
  _PROV_RC=$?
  set -e
  _PROV_OUT="$(cat "${tf}")"
  rm -f "${tf}"
}

_prov_has() { printf '%s\n' "$1" | grep -qE "^$2	$3	$4	"; }

# NOME: run_kg_COVERAGE_selftests, não run_kg_provenance_selftests. Colisão real
# (2026-07-20→21): esta função nasceu com o mesmo nome da guarda do modo --provenance
# do kg-radar (definida bem acima) e, em bash, a definição posterior SOBRESCREVE a
# anterior — os 3 casos daquela guarda deixaram de rodar e estes rodaram DUAS vezes,
# inflando a contagem de "passaram". Suíte verde não prova cobertura viva.
run_kg_coverage_selftests() {
  local h="${REPO_ROOT}/.claude/validation/kg-provenance-coverage.sh"
  if [ ! -f "${h}" ]; then record_fail "kg-coverage" "helper ausente: ${h}"; return; fi

  # =========================================================================
  # BLOCO A — semântica do gate (repo isolado, SEM git → prova P2 de tabela)
  # =========================================================================
  local d out; d="$(_prov_make_repo)"
  _prov_run "${d}"; out="${_PROV_OUT}"

  _prov_has "${out}" "HARD" "NEW" "docs/analysis/novo\.md" \
    && record_pass "kg-provenance: documento NOVO sem nó → HARD" \
    || record_fail "kg-provenance: novo" "não emitiu HARD/NEW para docs/analysis/novo.md"

  _prov_has "${out}" "SOFT" "PASSIVO" "docs/analysis/passivo\.md" \
    && record_pass "kg-provenance: documento do baseline → SOFT (tolerado, não reprova)" \
    || record_fail "kg-provenance: passivo" "não tolerou o documento do baseline como SOFT"

  printf '%s\n' "${out}" | grep -q "docs/analysis/coberto\.md" \
    && record_fail "kg-provenance: coberto" "falso-positivo — acusou documento CITADO em trace: (com sufixo :42)" \
    || record_pass "kg-provenance: coberto por trace: (sufixo :NNN normalizado) → silêncio"

  printf '%s\n' "${out}" | grep -q "research/tema-x/SYNTHESIS\.md" \
    && record_fail "kg-provenance: evidence lista" "não reconheceu cobertura via evidence: em LISTA (com ./ à frente)" \
    || record_pass "kg-provenance: coberto por evidence: em lista → silêncio"

  printf '%s\n' "${out}" | grep -q "onion-adr-excluido\.md" \
    && record_fail "kg-provenance: exclusão ADR" "ADR entrou no escopo (deve ser NORMA, não achado)" \
    || record_pass "kg-provenance: ADR por nome → fora do escopo"

  printf '%s\n' "${out}" | grep -q "decisao-sem-prefixo\.md" \
    && record_fail "kg-provenance: exclusão ADR-frontmatter" "ADR declarado por 'type: adr' entrou no escopo" \
    || record_pass "kg-provenance: ADR por frontmatter (type: adr) → fora do escopo"

  printf '%s\n' "${out}" | grep -q "docs/analysis/README\.md" \
    && record_fail "kg-provenance: exclusão README" "README (navegação, não achado) entrou no escopo" \
    || record_pass "kg-provenance: README → fora do escopo"

  # Exit code é o contrato do consumidor: HARD presente ⇒ rc 1.
  [ "${_PROV_RC}" -eq 1 ] \
    && record_pass "kg-provenance: exit code 1 com HARD presente" \
    || record_fail "kg-provenance: exit code" "esperava rc=1 com HARD presente, veio rc=${_PROV_RC}"

  # (P2) DECIDIDO SÓ COM O REPO: o sandbox não é git, não tem .env, não vê a home
  # nem o repo real — e ainda assim o veredito HARD acima foi produzido. Prova que
  # a regra NÃO é no-op no CI (um clone limpo decide sozinho). Contraprova: ao
  # modelar o documento no grafo DENTRO do repo, o HARD some — nenhum outro insumo.
  cat >> "${d}/docs/evolution/research/tema-x/tema-x.kg.yaml" <<'KGEOF'
  - id: E2
    node_type: evidence
    trace: "docs/analysis/novo.md"
KGEOF
  _prov_run "${d}"; out="${_PROV_OUT}"
  if printf '%s\n' "${out}" | grep -q "	NEW	"; then
    record_fail "kg-provenance: repo-only" "modelar o doc no .kg.yaml do PRÓPRIO repo não removeu o HARD"
  else
    record_pass "kg-provenance: (P2) decisão tomada só com o repo — modelar no grafo do repo zera o HARD; rc=${_PROV_RC}"
  fi

  # =========================================================================
  # BLOCO B — (P3) o BASELINE é pressuposto: só encolhe, e sua ausência não libera
  # =========================================================================
  local b; b="$(_prov_make_repo)"
  local prev_menor="${b}/prev-menor.txt" prev_maior="${b}/prev-maior.txt"
  printf '# prev\n'                              > "${prev_menor}"   # baseline ANTES: vazio
  printf '# prev\ndocs/analysis/passivo.md\ndocs/analysis/extra.md\n' > "${prev_maior}"

  # B1 — baseline CRESCEU (antes vazio, agora com 1 entrada) ⇒ HARD de catraca.
  _prov_run "${b}" --previous-baseline "${prev_menor}"; out="${_PROV_OUT}"
  _prov_has "${out}" "HARD" "CATRACA" ".*kg-coverage-baseline\.txt" \
    && record_pass "kg-provenance: (P3) baseline que CRESCE → HARD (catraca)" \
    || record_fail "kg-provenance: catraca-cresce" "acrescentar path ao baseline não foi sinalizado como HARD"

  # B2 — baseline ENCOLHEU (antes 2 entradas, agora 1) ⇒ nenhuma HARD de catraca.
  _prov_run "${b}" --previous-baseline "${prev_maior}"; out="${_PROV_OUT}"
  printf '%s\n' "${out}" | grep -q "	CATRACA	" \
    && record_fail "kg-provenance: catraca-encolhe" "baseline que ENCOLHEU foi tratado como regressão" \
    || record_pass "kg-provenance: (P3) baseline que ENCOLHE → sem HARD de catraca"

  # B3 — entrada de baseline que já não é necessária ⇒ SOFT cobrando o encolhimento
  #      (sem isto o baseline vira lixo permanente e a métrica de saúde morre).
  printf '# baseline\ndocs/analysis/passivo.md\ndocs/analysis/coberto.md\ndocs/analysis/sumiu.md\n' \
    > "${b}/.claude/validation/kg-coverage-baseline.txt"
  _prov_run "${b}" --previous-baseline "${b}/.claude/validation/kg-coverage-baseline.txt"; out="${_PROV_OUT}"
  printf '%s\n' "${out}" | grep -q "	BASELINE-OBSOLETA	" \
    && record_pass "kg-provenance: (P3) entrada obsoleta (doc já coberto) → SOFT 'remova do baseline'" \
    || record_fail "kg-provenance: baseline-obsoleta" "não cobrou a remoção de entrada já coberta pelo grafo"
  printf '%s\n' "${out}" | grep -q "	BASELINE-ORFA	" \
    && record_pass "kg-provenance: (P3) entrada órfã (doc inexistente) → SOFT 'remova do baseline'" \
    || record_fail "kg-provenance: baseline-orfa" "não cobrou a remoção de entrada que não existe mais"

  # B3b — baseline VAZIO (só cabeçalho): regressão real achada no dogfood deste
  #       gate — `grep` sem match sai 1 e, sob `set -euo pipefail`, ABORTAVA o
  #       script inteiro sem emitir nada (rc=1 com STDOUT vazio: o consumidor
  #       leria "sem violações"). Modo-de-falha, não happy-path.
  printf '# baseline (vazio de propósito)\n' > "${b}/.claude/validation/kg-coverage-baseline.txt"
  _prov_run "${b}"; out="${_PROV_OUT}"
  if [ -n "${out}" ] && printf '%s\n' "${out}" | grep -q "	NEW	docs/analysis/passivo.md	"; then
    record_pass "kg-provenance: (P3) baseline VAZIO → gate segue avaliando (não aborta em silêncio)"
  else
    record_fail "kg-provenance: baseline-vazio" "baseline sem entradas produziu saída vazia/sem HARD — o gate abortou em silêncio"
  fi

  # B4 — AUSÊNCIA do baseline: degrade gracioso que NÃO libera tudo. Exatamente
  #      UMA HARD (a própria ausência, acionável) e o passivo rebaixado a SOFT.
  #      O oposto seria bypass do gate por `rm baseline`.
  rm -f "${b}/.claude/validation/kg-coverage-baseline.txt"
  _prov_run "${b}"; out="${_PROV_OUT}"
  local n_hard n_nobase
  n_hard="$(printf '%s\n' "${out}" | grep -c '^HARD' || true)"
  n_nobase="$(printf '%s\n' "${out}" | grep -c '	NO-BASELINE	' || true)"
  if [ "${n_hard}" = "1" ] && [ "${n_nobase}" = "1" ] && [ "${_PROV_RC}" -eq 1 ]; then
    record_pass "kg-provenance: (P3) baseline AUSENTE → 1 HARD acionável (não libera tudo, nem reprova em massa)"
  else
    record_fail "kg-provenance: baseline-ausente" "esperava exatamente 1 HARD (NO-BASELINE) e rc=1; veio HARD=${n_hard} NO-BASELINE=${n_nobase} rc=${_PROV_RC}"
  fi
  printf '%s\n' "${out}" | grep -q "	NO-BASELINE-UNCOVERED	docs/analysis/novo.md	" \
    && record_pass "kg-provenance: (P3) sem baseline, o passivo continua VISÍVEL (SOFT) — silenciar seria liberar tudo" \
    || record_fail "kg-provenance: baseline-ausente-visibilidade" "sem baseline o gate ficou cego aos documentos sem nó"

  # =========================================================================
  # BLOCO C — (P4) MUTATION TEST: desfaz a condição CENTRAL e mostra caso falhando
  # =========================================================================
  local m; m="$(_prov_make_repo)"
  local mut="${m}/.claude/validation/kg-provenance-coverage.sh"
  # A condição central é "não-coberto MENOS baseline = novos ⇒ HARD". Desfazê-la
  # (lista de novos sempre vazia) é a mutação que um refactor descuidado faria.
  sed -i.bak 's|comm -23 "${TMP}/uncovered" "${TMP}/baseline" > "${TMP}/novos"|: > "${TMP}/novos"|' "${mut}"
  if ! grep -q ': > "${TMP}/novos"' "${mut}"; then
    record_fail "kg-provenance: (P4) mutation" "a mutação não foi aplicada — o teste não prova nada (âncora do sed mudou?)"
  else
    local mout mrc
    set +e
    mout="$(bash "${mut}" "${m}" --format tsv 2>/dev/null)"; mrc=$?
    set -e
    if printf '%s\n' "${mout}" | grep -q "	NEW	docs/analysis/novo.md	"; then
      record_fail "kg-provenance: (P4) mutation" "com a condição central DESFEITA o caso ainda passou verde — o teste não é load-bearing"
    else
      record_pass "kg-provenance: (P4) MUTATION TEST — condição central desfeita ⇒ o caso 'novo → HARD' FALHA (rc ${_PROV_RC}→${mrc}); o teste é load-bearing"
    fi
  fi

  # =========================================================================
  # BLOCO D — (P1) SEVERIDADE PROVADA POR DELTA no lint REAL (não declarada)
  #   Ontem uma guarda declarou "SOFT nunca HARD" em comentário e o mutation test
  #   passou verde. Aqui a severidade é medida: injeta-se documento no sandbox do
  #   repo real e compara-se o SUMÁRIO com e sem ele.
  # =========================================================================
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_fail "kg-provenance: delta" "lint ausente"; else
    local sb; sb="$(mktemp -d)"
    # cp SEM .claude/worktrees/ (checkout inteiro, ~12M) — o sandbox não precisa deles e o
  # custo entrava no orçamento de CI (o job tem timeout-minutes: 10 e roda lint+tokens junto).
  mkdir -p "${sb}/.claude"
  (cd "${REPO_ROOT}/.claude" && tar -cf - --exclude=worktrees .) | (cd "${sb}/.claude" && tar -xf -)
    cp -a "${REPO_ROOT}/docs"      "${sb}/docs"
    cp -a "${REPO_ROOT}/CLAUDE.md" "${sb}/CLAUDE.md"
    rm -rf "${sb}/plugins" "${sb}/.claude-plugin"
    local probe_novo="docs/analysis/selftest-prov-novo.md"
    local probe_pass="docs/analysis/selftest-prov-passivo.md"
    local sbl="${sb}/.claude/validation/kg-coverage-baseline.txt"

    local o0 h0 s0 o1 h1 s1 o2 h2 s2
    o0="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sbl}" 2>&1 || true)"
    h0="$(printf '%s' "${o0}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
    s0="$(printf '%s' "${o0}" | awk -F': *' '/Viola..es SOFT/{print $2; exit}')"

    # (1) documento NOVO sem nó e fora do baseline ⇒ soma exatamente 1 HARD.
    printf '# sonda nova\n' > "${sb}/${probe_novo}"
    o1="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/${probe_novo}" 2>&1 || true)"
    h1="$(printf '%s' "${o1}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
    if [ "${h1}" = "$((h0 + 1))" ] && printf '%s' "${o1}" | grep -qF "${probe_novo}"; then
      record_pass "kg-provenance: (P1) SEVERIDADE por DELTA — documento novo sem nó soma HARD (${h0}→${h1})"
    else
      record_fail "kg-provenance: (P1) delta HARD" "esperava HARD ${h0}→$((h0 + 1)) citando ${probe_novo}; veio ${h1}"
    fi

    # (2) MESMO documento, agora listado no baseline ⇒ HARD volta ao valor-base
    #     (é tolerado) e o passivo só engorda a contagem SOFT.
    rm -f "${sb}/${probe_novo}"
    printf '# sonda passivo\n' > "${sb}/${probe_pass}"
    printf '%s\n' "${probe_pass}" >> "${sbl}"
    o2="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/${probe_pass}" 2>&1 || true)"
    h2="$(printf '%s' "${o2}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
    s2="$(printf '%s' "${o2}" | awk -F': *' '/Viola..es SOFT/{print $2; exit}')"
    if [ "${h2}" = "${h0}" ]; then
      record_pass "kg-provenance: (P1) SEVERIDADE por DELTA — documento do baseline NÃO soma HARD (${h0}→${h2}, SOFT ${s0}→${s2})"
    else
      record_fail "kg-provenance: (P1) delta baseline" "documento do baseline mexeu no HARD: ${h0}→${h2} (deveria ficar igual)"
    fi
    rm -rf "${sb}"
  fi

  # =========================================================================
  # BLOCO E — o caminho GIT da catraca (defeito da verificação adversarial
  #   2026-07-20: os casos A-D exercitavam SÓ `--previous-baseline`; a
  #   resolução por REF — que é a que roda em produção — não tinha um único
  #   teste. Um caminho de produção sem prova é exatamente o furo que a regra
  #   de admissão da casa existe para impedir.
  # =========================================================================
  local g; g="$(mktemp -d)"
  mkdir -p "${g}/.claude/validation" "${g}/docs/analysis" "${g}/docs/onion/graph"
  cp "${REPO_ROOT}/.claude/validation/kg-provenance-coverage.sh" "${g}/.claude/validation/"
  [ -f "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" ] \
    && cp "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" "${g}/.claude/validation/"
  printf '# doc legado\n' > "${g}/docs/analysis/legado.md"
  printf 'nodes:\n  - id: N1\n    node_type: claim\n' > "${g}/docs/onion/graph/x.kg.yaml"
  printf '%s\n' 'docs/analysis/legado.md' > "${g}/.claude/validation/kg-coverage-baseline.txt"
  git -C "${g}" init -q 2>/dev/null
  git -C "${g}" add -A >/dev/null 2>&1
  git -C "${g}" -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1

  local og oe rc
  # (E1) baseline versionado só no HEAD, INALTERADO → catraca resolve pelo git,
  #      mas HEAD é ref LOCAL: tem de AVISAR (fraca), não sair verde em silêncio.
  rc=0; og="$(cd "${g}" && bash .claude/validation/kg-provenance-coverage.sh 2>&1)" || rc=$?
  if printf '%s' "${og}" | grep -q 'CATRACA-FRACA' \
     && ! printf '%s' "${og}" | grep -q 'CATRACA-INDISPONIVEL'; then
    record_pass "kg-provenance: (E1) caminho git — baseline no HEAD resolve a catraca e AVISA ref fraca"
  else
    record_fail "kg-provenance: (E1) ref fraca" "esperava CATRACA-FRACA sem CATRACA-INDISPONIVEL; veio: ${og}"
  fi

  # (E2) CRUX — baseline CRESCEU em relação ao ref git ⇒ HARD.
  #      É o caso que provava que o caminho por ref realmente compara (e não
  #      compara o baseline consigo mesmo, que era o no-op silencioso do defeito 3).
  printf '%s\n' 'docs/analysis/inventado.md' >> "${g}/.claude/validation/kg-coverage-baseline.txt"
  rc=0; og="$(cd "${g}" && bash .claude/validation/kg-provenance-coverage.sh 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${og}" | grep -qi 'catraca'; then
    record_pass "kg-provenance: (E2) caminho git — baseline que CRESCE vs o ref ⇒ HARD (rc=1)"
  else
    record_fail "kg-provenance: (E2) crescimento via git" "esperava rc=1 + violação de catraca; rc=${rc} out=${og}"
  fi
  git -C "${g}" checkout -q -- .claude/validation/kg-coverage-baseline.txt 2>/dev/null

  # (E3) ref FORTE: com origin/<branch> presente, a catraca resolve por ela e
  #      NÃO avisa fraqueza (o aviso é só para HEAD/branch local).
  # Clone REALISTA: além do ref remoto, `origin/HEAD` — sem ele o resolve-integration-branch
  # cai no palpite cego ("main"), o chain procura origin/main (ausente) e degrada para HEAD.
  # (Foi assim que este caso falhou na 1ª escrita: a fixture criava origin/<branch-atual>, mas o
  # chain consulta origin/<branch-de-INTEGRAÇÃO>, que o resolver dizia ser outra.)
  _gb="$(git -C "${g}" branch --show-current)"
  git -C "${g}" update-ref "refs/remotes/origin/${_gb}" HEAD 2>/dev/null
  git -C "${g}" symbolic-ref "refs/remotes/origin/HEAD" "refs/remotes/origin/${_gb}" 2>/dev/null
  rc=0; og="$(cd "${g}" && bash .claude/validation/kg-provenance-coverage.sh 2>&1)" || rc=$?
  if ! printf '%s' "${og}" | grep -q 'CATRACA-FRACA'; then
    record_pass "kg-provenance: (E3) caminho git — origin/<branch> é ref FORTE (sem aviso de fraqueza)"
  else
    record_fail "kg-provenance: (E3) ref forte" "origin/<branch> presente e ainda avisou fraqueza: ${og}"
  fi
  rm -rf "${g}"

  rm -rf "${d}" "${b}" "${m}"
}

# ---------------------------------------------------------------------------
# Modo doctrine-freshness — GATE DE FRESCOR DOUTRINÁRIO com catraca (REGRA 42).
#
# Irmão TEMPORAL da REGRA 29: a 29 fecha conhecimento nascendo FORA do grafo
# (espacial); esta fecha a afirmação doutrinária que EXPIROU EM SILÊNCIO (temporal).
# Origem: world-sync 2026-07-20/23 — o cutoff é jan/2026; KB dizendo "lineup vigente
# é X" vira mentira em julho sem uma linha do repo mudar.
#
# Prova os QUATRO pressupostos que a regra de admissão da casa exige (não declara):
#   (P1) LISTA world-facing — o único eixo HARD (Nível A); Nível B é SOFT-only.
#   (P2) DECIDIDO SÓ COM O REPO — sandbox sem git, sem rede, sem home → veredito.
#        Reforçado por prova ESTRUTURAL: o helper não contém chamada de rede.
#   (P3) BASELINE — só encolhe (crescer = HARD), ausência degrada FAIL-CLOSED.
#   (P4) TTL lível por env (a FIXTURE fixa, nunca a implementação — lição T2.5e) +
#        RELÓGIO (idade só vale com NTP provado; não-confiável degrada a SOFT).
#   + MUTATION TEST de severidade: flip HARD→SOFT quebra o caso 'missing → HARD'.
# Sandboxes self-contained (mktemp) com --list-file (independe das 4 KBs reais).
# ---------------------------------------------------------------------------

# Monta um repo mínimo com uma lista world-facing SINTÉTICA (--list-file). Ecoa o dir.
_df_make_repo() {
  local d today; d="$(mktemp -d)"; today="$(date +%F)"
  mkdir -p "${d}/.claude/validation" "${d}/docs/knowledge-base/concepts"
  cp "${REPO_ROOT}/.claude/validation/doctrine-freshness.sh" "${d}/.claude/validation/"
  [ -f "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" ] \
    && cp "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" "${d}/.claude/validation/"
  local kc="${d}/docs/knowledge-base/concepts"
  printf '%s\n' '---' "verified_at: ${today}" 'source: "https://ex.test/a"' '---' '# fresh'     > "${kc}/fresh.md"
  printf '# missing\n'                                                                          > "${kc}/missing.md"
  printf '# passivo\n'                                                                          > "${kc}/passivo.md"
  printf '%s\n' '---' 'verified_at: ontem'      'source: "https://ex.test/b"' '---' '# malformed' > "${kc}/malformed.md"
  printf '%s\n' '---' 'verified_at: 2999-01-01' 'source: "https://ex.test/c"' '---' '# future'  > "${kc}/future.md"
  printf '%s\n' '---' 'verified_at: 2020-01-01' 'source: "https://ex.test/d"' '---' '# stale'   > "${kc}/stale.md"
  printf '%s\n' '---' "verified_at: ${today}"                                 '---' '# nosource' > "${kc}/nosource.md"
  printf '%s\n' '# lexical' 'O lineup vigente e X; latest.'                                     > "${kc}/lexical.md"
  # code-fence: `latest` só DENTRO de ``` (tag Docker) — é código, não prosa doutrinária → NÃO flaga.
  printf '%s\n' '# codefence' 'Sem gatilho na prosa aqui.' '```yaml' 'image: pg:latest' '```'   > "${kc}/codefence.md"
  { for f in fresh missing passivo malformed future stale nosource; do
      printf 'docs/knowledge-base/concepts/%s.md\n' "$f"; done; } > "${d}/.claude/validation/df-list.txt"
  printf '# baseline\ndocs/knowledge-base/concepts/passivo.md\n' > "${d}/.claude/validation/doctrine-freshness-baseline.txt"
  printf '%s\n' "${d}"
}

# _df_run <repo> [args...] — preenche _DF_OUT (TSV) e _DF_RC. Clock ATESTADO e TTL 90
# por padrão (determinismo, independe do relógio do runner); _DF_CLOCK/_DF_TTL sobrepõem.
# NÃO ecoa: rodar em subshell mataria _DF_RC (a armadilha que o kg-coverage documenta).
_df_run() {
  local repo="$1"; shift
  local tf; tf="$(mktemp)"
  set +e
  DOCTRINE_CLOCK_TRUST="${_DF_CLOCK:-attested}" DOCTRINE_FRESHNESS_TTL_DAYS="${_DF_TTL:-90}" \
    bash "${repo}/.claude/validation/doctrine-freshness.sh" "${repo}" \
      --list-file "${repo}/.claude/validation/df-list.txt" --format tsv "$@" >"${tf}" 2>/dev/null
  _DF_RC=$?
  set -e
  _DF_OUT="$(cat "${tf}")"; rm -f "${tf}"
}

_df_has() { printf '%s\n' "$1" | grep -qE "^$2"$'\t'"$3"$'\t'"$4"$'\t'; }

run_doctrine_freshness_selftests() {
  local h="${REPO_ROOT}/.claude/validation/doctrine-freshness.sh"
  if [ ! -f "${h}" ]; then record_fail "doctrine-freshness" "helper ausente: ${h}"; return; fi

  # =========================================================================
  # BLOCO A — semântica do gate (repo isolado, SEM git, SEM rede → prova P2)
  # =========================================================================
  local d out; d="$(_df_make_repo)"
  _df_run "${d}"; out="${_DF_OUT}"

  printf '%s\n' "${out}" | grep -q 'concepts/fresh\.md' \
    && record_fail "doctrine: fresh" "doc carimbado e dentro do TTL foi flagado (falso-positivo)" \
    || record_pass "doctrine: (NÍVEL A) doc fresco (verified_at hoje + source) → silêncio"

  _df_has "${out}" HARD MISSING 'docs/knowledge-base/concepts/missing\.md' \
    && record_pass "doctrine: (NÍVEL A) world-facing SEM verified_at e fora do baseline → HARD" \
    || record_fail "doctrine: missing" "world-facing sem verified_at não virou HARD/MISSING"

  _df_has "${out}" SOFT PASSIVO 'docs/knowledge-base/concepts/passivo\.md' \
    && record_pass "doctrine: (P3) world-facing sem verified_at MAS no baseline → SOFT (tolerado)" \
    || record_fail "doctrine: passivo" "doc do baseline não foi tolerado como SOFT"

  _df_has "${out}" HARD MALFORMED 'docs/knowledge-base/concepts/malformed\.md' \
    && record_pass "doctrine: (NÍVEL A) verified_at malformado → HARD estrutural" \
    || record_fail "doctrine: malformed" "verified_at não-data não virou HARD/MALFORMED"

  _df_has "${out}" HARD FUTURE 'docs/knowledge-base/concepts/future\.md' \
    && record_pass "doctrine: (NÍVEL A) verified_at no FUTURO → HARD estrutural" \
    || record_fail "doctrine: future" "verified_at no futuro não virou HARD/FUTURE"

  _df_has "${out}" SOFT STALE 'docs/knowledge-base/concepts/stale\.md' \
    && record_pass "doctrine: (NÍVEL A) verified_at > TTL → SOFT STALE (re-verifique, não reprova)" \
    || record_fail "doctrine: stale" "verified_at vencido não virou SOFT/STALE"

  _df_has "${out}" SOFT NO-SOURCE 'docs/knowledge-base/concepts/nosource\.md' \
    && record_pass "doctrine: (NÍVEL A) carimbo SEM source → SOFT NO-SOURCE (carimbo sem fonte é frágil)" \
    || record_fail "doctrine: nosource" "verified_at sem source não virou SOFT/NO-SOURCE"

  _df_has "${out}" SOFT LEXICAL 'docs/knowledge-base/concepts/lexical\.md' \
    && record_pass "doctrine: (NÍVEL B) doc fora da lista com token gatilho, sem carimbo → SOFT LEXICAL" \
    || record_fail "doctrine: lexical" "rede lexical não pegou 'lineup vigente/latest' sem verified_at"

  # (SKIP-FENCE) `latest` SÓ dentro de ``` code ``` (tag Docker, nome de método, env-example) é CÓDIGO,
  # não afirmação doutrinária em prosa — NÃO deve flagar. Varrer código gerava uma classe inteira de
  # falso-positivo (docker :latest, getLatestRuns). O guard pula code fences; este caso trava o fix.
  if _df_has "${out}" SOFT LEXICAL 'docs/knowledge-base/concepts/codefence\.md'; then
    record_fail "doctrine: skip-fence" "'latest' em bloco de código foi flagado — o guard varre código (falso-positivo)"
  else record_pass "doctrine: (NÍVEL B skip-fence) 'latest' só em code fence → NÃO flaga (só a prosa conta)"; fi

  [ "${_DF_RC}" -eq 1 ] \
    && record_pass "doctrine: (P2) DECIDIDO SÓ COM O REPO — sandbox sem git/rede/home produziu veredito HARD (rc=1); não é no-op no CI" \
    || record_fail "doctrine: exit-code" "esperava rc=1 com HARD presente, veio rc=${_DF_RC}"

  # =========================================================================
  # BLOCO B — (P3) BASELINE: catraca só encolhe; vazio não aborta; ausência fail-closed
  # =========================================================================
  local b prev_menor prev_maior; b="$(_df_make_repo)"
  prev_menor="${b}/prev-menor.txt"; prev_maior="${b}/prev-maior.txt"
  printf '# prev\n'                                                                > "${prev_menor}"   # ANTES: vazio
  printf '# prev\ndocs/knowledge-base/concepts/passivo.md\ndocs/knowledge-base/concepts/extra.md\n' > "${prev_maior}"

  _df_run "${b}" --previous-baseline "${prev_menor}"; out="${_DF_OUT}"
  _df_has "${out}" HARD CATRACA '.*doctrine-freshness-baseline\.txt' \
    && record_pass "doctrine: (P3) baseline que CRESCE (vs prev vazio) → HARD (catraca)" \
    || record_fail "doctrine: catraca-cresce" "acrescentar path ao baseline não foi HARD"

  _df_run "${b}" --previous-baseline "${prev_maior}"; out="${_DF_OUT}"
  printf '%s\n' "${out}" | grep -qE $'\tCATRACA\t' \
    && record_fail "doctrine: catraca-encolhe" "baseline que ENCOLHEU foi tratado como regressão" \
    || record_pass "doctrine: (P3) baseline que ENCOLHE → sem HARD de catraca"

  # entrada obsoleta (doc agora carimbado) + órfã (doc fora da lista) → SOFT
  printf '# baseline\ndocs/knowledge-base/concepts/passivo.md\ndocs/knowledge-base/concepts/fresh.md\ndocs/knowledge-base/concepts/ghost.md\n' \
    > "${b}/.claude/validation/doctrine-freshness-baseline.txt"
  _df_run "${b}" --previous-baseline "${b}/.claude/validation/doctrine-freshness-baseline.txt"; out="${_DF_OUT}"
  printf '%s\n' "${out}" | grep -qE $'\tBASELINE-OBSOLETA\t' \
    && record_pass "doctrine: (P3) entrada obsoleta (doc já carimbado) → SOFT 'remova do baseline'" \
    || record_fail "doctrine: baseline-obsoleta" "não cobrou a remoção de entrada já carimbada"
  printf '%s\n' "${out}" | grep -qE $'\tBASELINE-ORFA\t' \
    && record_pass "doctrine: (P3) entrada órfã (fora da lista) → SOFT 'remova do baseline'" \
    || record_fail "doctrine: baseline-orfa" "não cobrou a remoção de entrada fora da lista"

  # baseline VAZIO (só cabeçalho): grep sem match sob set -euo pipefail NÃO pode abortar
  printf '# baseline (vazio de propósito)\n' > "${b}/.claude/validation/doctrine-freshness-baseline.txt"
  _df_run "${b}"; out="${_DF_OUT}"
  if [ -n "${out}" ] && _df_has "${out}" HARD MISSING 'docs/knowledge-base/concepts/missing\.md'; then
    record_pass "doctrine: (P3) baseline VAZIO → gate segue avaliando (não aborta em silêncio)"
  else
    record_fail "doctrine: baseline-vazio" "baseline sem entradas produziu saída vazia/sem HARD (abortou em silêncio?)"
  fi

  # AUSÊNCIA do baseline: degrade FAIL-CLOSED — exatamente 1 NO-BASELINE, passivo VISÍVEL como SOFT
  rm -f "${b}/.claude/validation/doctrine-freshness-baseline.txt"
  _df_run "${b}"; out="${_DF_OUT}"
  local n_nobase; n_nobase="$(printf '%s\n' "${out}" | grep -cE $'\tNO-BASELINE\t' || true)"
  if [ "${n_nobase}" = "1" ] && [ "${_DF_RC}" -eq 1 ]; then
    record_pass "doctrine: (P3) baseline AUSENTE → 1 HARD NO-BASELINE acionável (não libera tudo)"
  else
    record_fail "doctrine: baseline-ausente" "esperava exatamente 1 NO-BASELINE e rc=1; veio NO-BASELINE=${n_nobase} rc=${_DF_RC}"
  fi
  _df_has "${out}" SOFT NO-BASELINE-UNCOVERED 'docs/knowledge-base/concepts/missing\.md' \
    && record_pass "doctrine: (P3) sem baseline, o passivo continua VISÍVEL (SOFT) — silenciar seria liberar tudo" \
    || record_fail "doctrine: baseline-ausente-visibilidade" "sem baseline o gate ficou cego aos docs sem carimbo"

  # =========================================================================
  # BLOCO C — (MUTATION TEST de severidade): flip HARD→SOFT quebra 'missing → HARD'
  # =========================================================================
  local m mut; m="$(_df_make_repo)"; mut="${m}/.claude/validation/doctrine-freshness.sh"
  sed -i.bak 's|say "HARD" "MISSING"|say "SOFT" "MISSING"|' "${mut}"
  if ! grep -q 'say "SOFT" "MISSING"' "${mut}"; then
    record_fail "doctrine: (MUTATION)" "a mutação não foi aplicada — âncora do sed mudou; teste não prova nada"
  else
    local mout mrc
    set +e
    mout="$(DOCTRINE_CLOCK_TRUST=attested bash "${mut}" "${m}" --list-file "${m}/.claude/validation/df-list.txt" --format tsv 2>/dev/null)"; mrc=$?
    set -e
    if _df_has "${mout}" HARD MISSING 'docs/knowledge-base/concepts/missing\.md'; then
      record_fail "doctrine: (MUTATION)" "com HARD→SOFT desfeito o caso 'missing → HARD' ainda passou — não é load-bearing"
    else
      record_pass "doctrine: (MUTATION TEST) severidade é load-bearing — flip HARD→SOFT quebra 'missing → HARD' (rc ${_DF_RC}→${mrc})"
    fi
  fi

  # =========================================================================
  # BLOCO D — (P4-TTL): TTL é LÍVEL por env (a fixture fixa, não a implementação)
  # =========================================================================
  local dt; dt="$(_df_make_repo)"
  _DF_TTL=90 _df_run "${dt}"; out="${_DF_OUT}"
  _df_has "${out}" SOFT STALE 'docs/knowledge-base/concepts/stale\.md' \
    && record_pass "doctrine: (P4-TTL) TTL default 90 → doc de 2020 é STALE; doc de hoje NÃO" \
    || record_fail "doctrine: ttl-default" "com TTL 90 o doc de 2020 não ficou STALE"
  _DF_TTL=100000 _df_run "${dt}"; out="${_DF_OUT}"
  printf '%s\n' "${out}" | grep -q $'\tSTALE\tdocs/knowledge-base/concepts/stale\.md' \
    && record_fail "doctrine: ttl-env" "TTL alargado por env NÃO rejuvenesceu o doc (a fixture não fixa o TTL)" \
    || record_pass "doctrine: (P4-TTL) TTL alargado por env (100000d) → o MESMO doc deixa de ser STALE (fixture fixa o TTL)"

  # =========================================================================
  # BLOCO E — (P4-RELÓGIO): relógio não-confiável degrada a idade a SOFT (não HARD espúrio)
  # =========================================================================
  local dc; dc="$(_df_make_repo)"
  _DF_CLOCK=untrusted _df_run "${dc}"; out="${_DF_OUT}"
  _df_has "${out}" SOFT STALE-CLOCK-UNTRUSTED 'docs/knowledge-base/concepts/stale\.md' \
    && record_pass "doctrine: (P4-RELÓGIO) relógio não-confiável → STALE degrada a SOFT (não reprova por relógio)" \
    || record_fail "doctrine: clock-stale" "com relógio não-confiável a idade não degradou a SOFT STALE-CLOCK-UNTRUSTED"
  printf '%s\n' "${out}" | grep -qE $'\tHARD\tFUTURE\t' \
    && record_fail "doctrine: clock-future" "relógio não-confiável ainda emitiu HARD FUTURE (a comparação com 'agora' não degradou)" \
    || record_pass "doctrine: (P4-RELÓGIO) relógio não-confiável → FUTURE também degrada (não HARD espúrio)"
  _df_has "${out}" HARD MALFORMED 'docs/knowledge-base/concepts/malformed\.md' \
    && record_pass "doctrine: (P4-RELÓGIO) formato (independe do relógio) SEGUE HARD mesmo com relógio degradado" \
    || record_fail "doctrine: clock-malformed" "malformado deixou de ser HARD com relógio degradado (degrade tarde demais)"

  # =========================================================================
  # BLOCO F — (P2 reforço) prova ESTRUTURAL: o helper NÃO faz rede (CI-safe by construction)
  # =========================================================================
  if grep -vE '^[[:space:]]*#' "${h}" | grep -qE 'curl|wget|/dev/tcp|nc |WebFetch|ntpstat.*http'; then
    record_fail "doctrine: (P2) no-network" "o helper contém chamada de rede fora de comentário — não é CI-safe"
  else
    record_pass "doctrine: (P2) CI-SAFE por construção — nenhuma chamada de rede no corpo do helper (só o repo decide)"
  fi

  # =========================================================================
  # BLOCO G — caminho GIT da catraca (a que roda em produção; não só --previous-baseline)
  # =========================================================================
  local g; g="$(_df_make_repo)"
  git -C "${g}" init -q 2>/dev/null
  git -C "${g}" add -A >/dev/null 2>&1
  git -C "${g}" -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1
  local og rc
  # (G1) baseline versionado só no HEAD, INALTERADO → resolve pela ref, mas HEAD é
  #      ref LOCAL: AVISA fraca (não sai verde em silêncio).
  rc=0; og="$(cd "${g}" && DOCTRINE_CLOCK_TRUST=attested bash .claude/validation/doctrine-freshness.sh --list-file .claude/validation/df-list.txt 2>&1)" || rc=$?
  printf '%s' "${og}" | grep -q 'CATRACA-FRACA' && ! printf '%s' "${og}" | grep -q 'CATRACA-INDISPONIVEL' \
    && record_pass "doctrine: (G1) caminho git — baseline no HEAD resolve a catraca e AVISA ref fraca" \
    || record_fail "doctrine: (G1) ref fraca" "esperava CATRACA-FRACA sem CATRACA-INDISPONIVEL; veio: ${og}"
  # (G2) baseline CRESCEU vs o ref git ⇒ HARD (prova que compara de verdade, não consigo mesmo)
  printf 'docs/knowledge-base/concepts/inventado.md\n' >> "${g}/.claude/validation/doctrine-freshness-baseline.txt"
  rc=0; og="$(cd "${g}" && DOCTRINE_CLOCK_TRUST=attested bash .claude/validation/doctrine-freshness.sh --list-file .claude/validation/df-list.txt 2>&1)" || rc=$?
  [ "${rc}" -eq 1 ] && printf '%s' "${og}" | grep -qi 'catraca' \
    && record_pass "doctrine: (G2) caminho git — baseline que CRESCE vs o ref ⇒ HARD (rc=1)" \
    || record_fail "doctrine: (G2) crescimento via git" "esperava rc=1 + violação de catraca; rc=${rc}"

  rm -rf "${d}" "${b}" "${m}" "${dt}" "${dc}" "${g}"
}

# ---------------------------------------------------------------------------
# Modo kg-born-marker — GATE DE INTEGRIDADE DO MARCADOR kg: (REGRA 43).
#
# Irmão INTERNO da REGRA 29: a 29 pergunta "este relatório existe no grafo?" (doc→nó);
# esta pergunta "o grafo que a migalha DECLARA é real e são?" (marcador→.kg.yaml). Origem:
# memória do maestro 2026-07-23 (radar sub-usado; write(KG) da onion-orchestration era advice).
#
# Cinco casos da tarefa + a distinção que é a RAZÃO DE EXISTIR deste gate (missing != violation,
# o oposto da catraca da 29) + MUTATION TEST provando que a severidade HARD é LOAD-BEARING (não
# declarada num comentário). Sandboxes self-contained (mktemp), sem fixture-file.
# ---------------------------------------------------------------------------

# Monta um repo mínimo com o escopo do gate + os grafos-alvo. Ecoa o diretório.
_born_make_repo() {
  local d; d="$(mktemp -d)"
  mkdir -p "${d}/.claude/validation" "${d}/.claude/diary" "${d}/docs/analysis"
  cp "${REPO_ROOT}/.claude/validation/kg-born-marker.sh" "${d}/.claude/validation/"
  cp "${REPO_ROOT}/.claude/validation/kg-radar.sh"       "${d}/.claude/validation/"; _lib_beside "${d}/.claude/validation"

  # Grafo VÁLIDO (passa --integrity E --schema): 2 nós + 1 aresta (sem órfão).
  cat > "${d}/docs/analysis/probe.kg.yaml" <<'KGEOF'
meta:
  id: probe
  schema_version: "1"
nodes:
  - id: C1
    node_type: claim
    plane: DEV
    impact: 3
    confidence: 0.9
    status: open
  - id: E1
    node_type: evidence
    plane: DEV
    impact: 3
    confidence: 1.0
    status: confirmed
edges:
  - from: E1
    to: C1
    edge_type: SUPPORTS
KGEOF
  # Grafo que o radar REPROVA (nó órfão, sem plane/impact) — .kg.yaml legítimo, mas inconsistente.
  printf 'nodes:\n  - id: N1\n    node_type: claim\n' > "${d}/docs/analysis/bad.kg.yaml"
  # Um .md que NÃO é grafo.
  printf '# só prosa\n' > "${d}/docs/analysis/prose.md"

  # (i) kg: → grafo VÁLIDO
  printf '%s\n' '---' 'type: decision'   'kg: docs/analysis/probe.kg.yaml'     '---' '# ok'  > "${d}/.claude/diary/i-valid.md"
  # (ii) kg: PENDURADO (path inexistente)
  printf '%s\n' '---' 'type: error'      'kg: docs/analysis/nao-existe.kg.yaml' '---' '# x'  > "${d}/.claude/diary/ii-dangling.md"
  # (iii) kg: aponta .md que NÃO é grafo
  printf '%s\n' '---' 'type: learning'   'kg: docs/analysis/prose.md'           '---' '# x'  > "${d}/.claude/diary/iii-notkg.md"
  # (iv) kg: aponta .kg.yaml que o radar REPROVA
  printf '%s\n' '---' 'type: reflection' 'kg: docs/analysis/bad.kg.yaml'        '---' '# x'  > "${d}/.claude/diary/iv-radarfail.md"
  # (v) migalha SEM kg: (não retro-reprova)
  printf '%s\n' '---' 'type: learning'   '---' '# sem marcador'                        > "${d}/.claude/diary/v-nomarker.md"
  printf '%s\n' "${d}"
}

# _born_run <repo> — preenche _BORN_OUT (TSV) e _BORN_RC. NÃO ecoa (o subshell de
# x="$(...)" mataria a atribuição de _BORN_RC — a mesma armadilha do _prov_run).
_born_run() {
  local repo="$1"; local tf; tf="$(mktemp)"
  set +e
  bash "${repo}/.claude/validation/kg-born-marker.sh" "${repo}" --format tsv >"${tf}" 2>/dev/null
  _BORN_RC=$?
  set -e
  _BORN_OUT="$(cat "${tf}")"; rm -f "${tf}"
}

run_kg_born_marker_selftests() {
  local h="${REPO_ROOT}/.claude/validation/kg-born-marker.sh"
  if [ ! -f "${h}" ]; then record_fail "kg-born-marker" "helper ausente: ${h}"; return; fi

  local d out; d="$(_born_make_repo)"
  _born_run "${d}"; out="${_BORN_OUT}"

  # (i) kg: → grafo VÁLIDO → passa (nenhuma linha para i-valid.md).
  printf '%s\n' "${out}" | grep -q 'i-valid\.md' \
    && record_fail "kg-born-marker: (i) válido" "falso-positivo — grafo VÁLIDO (radar exit 0) foi reprovado" \
    || record_pass "kg-born-marker: (i) kg: → .kg.yaml VÁLIDO (radar --integrity E --schema exit 0) → silêncio"

  # (ii) kg: PENDURADO → HARD/MISSING-PATH.
  printf '%s\n' "${out}" | grep -qE '^HARD	MISSING-PATH	.claude/diary/ii-dangling\.md	' \
    && record_pass "kg-born-marker: (ii) kg: pendurado (path inexistente) → HARD" \
    || record_fail "kg-born-marker: (ii) pendurado" "não emitiu HARD/MISSING-PATH para ii-dangling.md"

  # (iii) kg: → .md que não é grafo → HARD/NOT-KG.
  printf '%s\n' "${out}" | grep -qE '^HARD	NOT-KG	.claude/diary/iii-notkg\.md	' \
    && record_pass "kg-born-marker: (iii) kg: aponta .md não-grafo → HARD" \
    || record_fail "kg-born-marker: (iii) não-grafo" "não emitiu HARD/NOT-KG para iii-notkg.md"

  # (iv) kg: → .kg.yaml que o radar REPROVA → HARD/RADAR-FAIL.
  printf '%s\n' "${out}" | grep -qE '^HARD	RADAR-FAIL	.claude/diary/iv-radarfail\.md	' \
    && record_pass "kg-born-marker: (iv) kg: aponta .kg.yaml que o radar REPROVA → HARD" \
    || record_fail "kg-born-marker: (iv) radar-reprova" "não emitiu HARD/RADAR-FAIL para iv-radarfail.md"

  # (v) migalha SEM kg: → passa. É a RAZÃO DE EXISTIR do gate (missing != violation —
  #     o oposto da catraca da 29; retro-reprovar as ~72 migalhas seria o erro da catraca).
  printf '%s\n' "${out}" | grep -q 'v-nomarker\.md' \
    && record_fail "kg-born-marker: (v) sem kg:" "retro-reprovou uma migalha SEM kg: — o erro da catraca que este gate NÃO comete" \
    || record_pass "kg-born-marker: (v) migalha SEM kg: → passa (missing != violation; não retro-reprova)"

  # Exit code é o contrato do consumidor: HARD presente ⇒ rc 1.
  [ "${_BORN_RC}" -eq 1 ] \
    && record_pass "kg-born-marker: exit code 1 com HARD presente" \
    || record_fail "kg-born-marker: exit code" "esperava rc=1 com HARD presente, veio rc=${_BORN_RC}"

  # =========================================================================
  # MUTATION TEST — a severidade HARD do caso (ii) é LOAD-BEARING, não declarada.
  #   Ontem uma guarda desta casa declarou "SOFT nunca HARD" em COMENTÁRIO e o
  #   mutation test passou verde. Aqui: flip HARD→SOFT no ramo MISSING-PATH de uma
  #   CÓPIA do helper e prove que a asserção (ii) — que exige HARD — QUEBRA.
  # =========================================================================
  local m; m="$(_born_make_repo)"
  local mut="${m}/.claude/validation/kg-born-marker.sh"
  sed -i.bak 's|say "HARD" "MISSING-PATH"|say "SOFT" "MISSING-PATH"|' "${mut}"
  if ! grep -q 'say "SOFT" "MISSING-PATH"' "${mut}"; then
    record_fail "kg-born-marker: (MUT) mutation" "a mutação não foi aplicada — o teste não prova nada (âncora do sed mudou?)"
  else
    local mout mrc
    set +e
    mout="$(bash "${mut}" "${m}" --format tsv 2>/dev/null)"; mrc=$?
    set -e
    if printf '%s\n' "${mout}" | grep -qE '^HARD	MISSING-PATH	.claude/diary/ii-dangling\.md	'; then
      record_fail "kg-born-marker: (MUT) mutation" "com a severidade rebaixada a SOFT o caso (ii) ainda saiu HARD — o teste não é load-bearing"
    else
      record_pass "kg-born-marker: (MUT) MUTATION TEST — severidade HARD→SOFT em (ii) QUEBRA a asserção de HARD (rc ${_BORN_RC}→${mrc}); a severidade é load-bearing, não declarada"
    fi
  fi

  # =========================================================================
  # SEVERIDADE POR DELTA no lint REAL — o caso (ii) soma exatamente 1 HARD ao
  #   sumário do lint completo (a severidade é MEDIDA, não lida de um comentário).
  # =========================================================================
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_fail "kg-born-marker: delta" "lint ausente"; else
    local sb; sb="$(mktemp -d)"
    mkdir -p "${sb}/.claude"
    (cd "${REPO_ROOT}/.claude" && tar -cf - --exclude=worktrees .) | (cd "${sb}/.claude" && tar -xf -)
    cp -a "${REPO_ROOT}/docs"      "${sb}/docs"
    cp -a "${REPO_ROOT}/CLAUDE.md" "${sb}/CLAUDE.md"
    rm -rf "${sb}/plugins" "${sb}/.claude-plugin"
    # Ambos os --only apontam para arquivos SOB .claude/diary (o lint recusa --only
    # inexistente, então o baseline usa uma migalha REAL já limpa, não o path da sonda
    # ainda-não-criada): o MESMO conjunto de regras dispara nas duas, e o delta isola a
    # violação desta regra. Mesmo padrão do BLOCO D da REGRA 29 (baseline num arquivo
    # existente, sonda em outro; ambos dentro das raízes da regra).
    local probe=".claude/diary/selftest-born-dangling.md"
    local base_crumb o0 h0 o1 h1
    # sed -n '1p' (não head -1): drena até EOF → o `sort` upstream não leva EPIPE sob pipefail
    # (ver nota em run_kg_freshness_selftests; CI SIGPIPE 2026-07-30).
    base_crumb="$(cd "${sb}" && find .claude/diary -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | sed -n '1p')"
    if [ -z "${base_crumb}" ]; then
      record_fail "kg-born-marker: delta setup" "sandbox sem migalha real p/ baseline do delta"
    else
      o0="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/${base_crumb}" 2>&1 || true)"
      h0="$(printf '%s' "${o0}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
      printf '%s\n' '---' 'type: decision' 'kg: docs/analysis/nao-existe-selftest.kg.yaml' '---' '# sonda' > "${sb}/${probe}"
      o1="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/${probe}" 2>&1 || true)"
      h1="$(printf '%s' "${o1}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
      if [ "${h1}" = "$((h0 + 1))" ] && printf '%s' "${o1}" | grep -qF "${probe}"; then
        record_pass "kg-born-marker: SEVERIDADE por DELTA — migalha com kg: pendurado soma HARD no lint real (${h0}→${h1})"
      else
        record_fail "kg-born-marker: delta HARD" "esperava HARD ${h0}→$((h0 + 1)) citando ${probe}; veio ${h1}"
      fi
    fi
    rm -rf "${sb}"
  fi

  rm -rf "${d}" "${m}"
}

# ---------------------------------------------------------------------------
# Modo outbox-channel — exercita a REGRA 28 do lint (check_outbox_channel_exists):
# anúncio em staging (docs/evolution/federation/outbox/<membro>/*.md) para um
# membro cujo local_path NÃO TEM docs/evolution/inbound/ deve virar SOFT (nunca
# HARD) — achado 2026-07-19 (6 anúncios p/ marcio-pessoal ficaram dias em
# staging sem ninguém notar). Self-contained: sandbox próprio (cp -a de
# .claude+docs+CLAUDE.md, p/ o lint completo rodar igual ao real) com 3 membros
# SINTÉTICOS apendados ao members.yaml (id único → âncora de asserção) cobrindo
# os 3 modos: com canal, sem canal, sem anúncio. Uma só execução do lint completo
# (outras violações do sandbox — ex.: drift de federation-map/console/agent-card
# pelos membros extras — são ruído esperado; asseremos só pela âncora do id
# sintético, não pela contagem total). Pula gracioso sem python3+yaml.
# ---------------------------------------------------------------------------
run_outbox_channel_selftests() {
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_fail "outbox-channel" "lint ausente: ${lint}"; return; fi
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    record_skip "outbox-channel: pulado (sem python3+yaml — gracioso)"; return
  fi

  local sb; sb="$(mktemp -d)"
  # cp SEM .claude/worktrees/ (checkout inteiro, ~12M) — o sandbox não precisa deles e o
  # custo entrava no orçamento de CI (o job tem timeout-minutes: 10 e roda lint+tokens junto).
  mkdir -p "${sb}/.claude"
  (cd "${REPO_ROOT}/.claude" && tar -cf - --exclude=worktrees .) | (cd "${sb}/.claude" && tar -xf -)
  cp -a "${REPO_ROOT}/docs"      "${sb}/docs"
  cp -a "${REPO_ROOT}/CLAUDE.md" "${sb}/CLAUDE.md"
  rm -rf "${sb}/plugins" "${sb}/.claude-plugin"
  printf 'framework: onion-evolve\nrole: adopted\n' > "${sb}/.claude/.onion-version"

  local com_canal sem_canal vazio naonvend ob
  com_canal="$(mktemp -d)"; mkdir -p "${com_canal}/docs/evolution/inbound"
  sem_canal="$(mktemp -d)"
  empty="$(mktemp -d)"
  naonvend="$(mktemp -d)"
  ob="${sb}/docs/evolution/federation/outbox"

  # (1) vendorizado COM canal + anúncio           -> silêncio
  mkdir -p "${ob}/selftest-com-canal";  printf '# t\n' > "${ob}/selftest-com-canal/2026-01-01-t.md"
  # (2) vendorizado SEM canal + anúncio           -> SOFT [classe 2, local]
  mkdir -p "${ob}/selftest-sem-canal";  printf '# t\n' > "${ob}/selftest-sem-canal/2026-01-01-t.md"
  # (3) SEM anúncio em staging                    -> silêncio (nenhum dir criado)
  # (4) membro onion_version n/a + anúncio        -> SOFT [classe 1, roda no CI]
  mkdir -p "${ob}/selftest-nao-vendoriza"; printf '# t\n' > "${ob}/selftest-nao-vendoriza/2026-01-01-t.md"
  # (5) dir órfão (não é id de membro) + anúncio  -> R28 SILENCIOSA (amputada 2026-08);
  #     SOFT vem só da REGRA 46 (owner), asserido em run_outbox_channel_selftests
  mkdir -p "${ob}/selftest-orfao-xyz";  printf '# t\n' > "${ob}/selftest-orfao-xyz/2026-01-01-t.md"
  # (6) SÓ _processed/ (já entregue)              -> silêncio (1º nível apenas)
  mkdir -p "${ob}/selftest-so-processed/_processed"
  printf '# t\n' > "${ob}/selftest-so-processed/_processed/2026-01-01-t.md"

  {
    printf '  - id: selftest-com-canal\n    role: standalone\n    onion_version: abc123\n    local_path: "%s"\n' "${com_canal}"
    printf '  - id: selftest-sem-canal\n    role: standalone\n    onion_version: abc123\n    local_path: "%s"\n' "${sem_canal}"
    printf '  - id: selftest-vazio\n    role: standalone\n    onion_version: abc123\n    local_path: "%s"\n' "${empty}"
    printf '  - id: selftest-nao-vendoriza\n    role: standalone\n    onion_version: n/a\n    local_path: "%s"\n' "${naonvend}"
    printf '  - id: selftest-so-processed\n    role: standalone\n    onion_version: n/a\n    local_path: "%s"\n' "${naonvend}"
  } >> "${sb}/docs/evolution/federation/members.yaml"

  local out hard_com soft_com
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  hard_com="$(printf '%s' "${out}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
  soft_com="$(printf '%s' "${out}" | awk -F': *' '/Viola..es SOFT/{print $2; exit}')"

  printf '%s' "${out}" | grep -qF "selftest-com-canal" \
    && record_fail "outbox-channel: com canal" "falso-positivo — acusou membro que TEM inbound/" \
    || record_pass "outbox-channel: vendorizado COM canal → sem violação"

  printf '%s' "${out}" | grep -qF "o clone local existe" \
    && record_pass "outbox-channel: vendorizado SEM canal → SOFT (classe local)" \
    || record_fail "outbox-channel: sem canal" "não emitiu a violação de clone-sem-inbound"

  printf '%s' "${out}" | grep -qF "selftest-vazio" \
    && record_fail "outbox-channel: sem anúncio" "acusou membro sem nenhum anúncio em staging" \
    || record_pass "outbox-channel: SEM anúncio em staging → sem violação"

  printf '%s' "${out}" | grep -qF "selftest-nao-vendoriza', que adota o MÉTODO" \
    && record_pass "outbox-channel: membro onion_version n/a → SOFT (classe decidível no CI)" \
    || record_fail "outbox-channel: n/a" "não acusou membro que não vendoriza (a classe que roda no CI)"

  printf '%s' "${out}" | grep -qF "selftest-orfao-xyz', que NÃO é id de membro" \
    && record_fail "outbox-channel: órfão" "REGRA 28 ainda emite p/ dir órfão — amputação de double-firing (R28×R46) não se sustentou" \
    || record_pass "outbox-channel: dir órfão → REGRA 28 silenciosa (classe amputada 2026-08, dona é a 46)"

  printf '%s' "${out}" | grep -qF "outbox-órfã] diretório sem membro correspondente em members.yaml" \
    && printf '%s' "${out}" | grep -qF "selftest-orfao-xyz" \
    && record_pass "outbox-channel: dir órfão → SOFT único, via REGRA 46 (dona da classe)" \
    || record_fail "outbox-channel: órfão-R46" "REGRA 46 não acusou dir de staging que não resolve a membro"

  printf '%s' "${out}" | grep -qF "selftest-so-processed" \
    && record_fail "outbox-channel: só _processed" "varreu _processed/ (já entregue) — deve ser 1º nível apenas" \
    || record_pass "outbox-channel: só _processed/ → sem violação (1º nível apenas)"

  # (7) PROVA DE SEVERIDADE — a propriedade CENTRAL da regra ("SOFT, nunca HARD") tem de ser
  # testada, não declarada em comentário. Sem este caso, trocar violation SOFT->HARD passava verde
  # (mutation test da verificação adversarial 2026-07-20). Compara o delta COM e SEM as fixtures:
  # elas podem acrescentar SOFT, jamais HARD — senão os 6 anúncios pré-existentes bloqueariam o CI.
  rm -rf "${ob}/selftest-com-canal" "${ob}/selftest-sem-canal" "${ob}/selftest-nao-vendoriza" \
         "${ob}/selftest-orfao-xyz" "${ob}/selftest-so-processed"
  local out2 hard_sem soft_sem
  out2="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  hard_sem="$(printf '%s' "${out2}" | awk -F': *' '/Viola..es HARD/{print $2; exit}')"
  soft_sem="$(printf '%s' "${out2}" | awk -F': *' '/Viola..es SOFT/{print $2; exit}')"

  if [ "${hard_com}" = "${hard_sem}" ] && [ "${soft_com}" -gt "${soft_sem}" ]; then
    record_pass "outbox-channel: SEVERIDADE provada — fixtures somam SOFT (${soft_sem}→${soft_com}) e ZERO HARD (${hard_sem})"
  else
    record_fail "outbox-channel: severidade" "esperava HARD inalterado e SOFT maior; HARD ${hard_sem}->${hard_com}, SOFT ${soft_sem}->${soft_com}"
  fi

  # GREENFIELD (terms vazio): um adotante SEM members.yaml não pode ABORTAR o lint na derivação de
  # termos da REGRA 36 — 'grep -v' sem match sai 1 e sob 'set -euo pipefail' derrubaria tudo. O core
  # nunca vê (sempre tem termos); todo adotante greenfield veria. Regressão de 2026-07-22, achada
  # rodando o lint DENTRO da cópia limpa de um adotante (o core é o pior oráculo do que viaja).
  rm -f "${sb}/docs/evolution/federation/members.yaml"
  local out3; out3="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh 2>&1 || true)"
  if printf '%s' "${out3}" | grep -q 'Viola..es HARD'; then
    record_pass "outbox-channel: (GREENFIELD) sem members.yaml → lint COMPLETA (REGRA 36 não aborta com terms vazio)"
  else record_fail "outbox-channel: greenfield" "lint abortou num adotante sem members.yaml (terms vazio + set -e na REGRA 36)"; fi

  rm -rf "${sb}" "${com_canal}" "${sem_canal}" "${empty}" "${naonvend}"
}

# ---------------------------------------------------------------------------
# Modo diary-crumbs — exercita a estrutura de decisão das migalhas no
# diary-index.sh (pesquisa breadcrumbs 2026-07, enabler conflict_class/valid_when;
# vocabulário MemConflict). Campos opcionais (retrocompat), mas quando presentes
# validados: classe fora do vocabulário ou conditional sem valid_when → exit 1.
# Self-contained: diário fake em mktemp.
# ---------------------------------------------------------------------------
run_diary_crumbs_selftests() {
  local di="${REPO_ROOT}/.claude/validation/diary-index.sh"
  if [ ! -f "${di}" ]; then record_fail "diary-crumbs" "script ausente: ${di}"; return; fi
  local d out rc

  d="$(mktemp -d)"; mkdir -p "${d}/.claude/diary"

  # (a) entrada SEM os campos (pré-1.2.0) → passa (retrocompat; campos são opcionais)
  printf -- '---\ndate: 2026-01-01\ntype: learning\nclassification: public\nreview_after: 2099-01-01\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-01-legacy-entry.md"
  rc=0; bash "${di}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "diary-crumbs: entrada sem conflict_class → passa (retrocompat)"
  else record_fail "diary-crumbs: retrocompat" "esperava exit 0, veio ${rc}"; fi

  # (b) as 3 classes válidas (conditional COM valid_when) → passa e índice expõe a classe
  printf -- '---\ndate: 2026-01-02\ntype: error\nclassification: public\nreview_after: 2099-01-01\nconflict_class: dynamic\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-02-dyn-entry.md"
  printf -- '---\ndate: 2026-01-03\ntype: decision\nclassification: public\nreview_after: 2099-01-01\nconflict_class: static\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-03-sta-entry.md"
  printf -- '---\ndate: 2026-01-04\ntype: learning\nclassification: public\nreview_after: 2099-01-01\nconflict_class: conditional\nvalid_when: "a condicao X vale"\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-04-cond-entry.md"
  rc=0; bash "${di}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] && grep -q '| conditional |' "${d}/.claude/diary/index.md" \
     && grep -q '| dynamic |' "${d}/.claude/diary/index.md"; then
    record_pass "diary-crumbs: 3 classes válidas → passa; índice expõe a classe"
  else record_fail "diary-crumbs: classes válidas" "esperava exit 0 + classes no índice; rc=${rc}"; fi

  # (c) classe fora do vocabulário → FALHA alto (migalha desonesta não vira índice)
  printf -- '---\ndate: 2026-01-05\ntype: learning\nclassification: public\nreview_after: 2099-01-01\nconflict_class: volatile\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-05-bad-class.md"
  rc=0; out="$(bash "${di}" "${d}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q "conflict_class 'volatile' inválida"; then
    record_pass "diary-crumbs: classe fora do vocabulário → exit 1 com erro nomeado"
  else record_fail "diary-crumbs: classe inválida" "esperava exit 1 + erro; out='${out}' rc=${rc}"; fi
  rm -f "${d}/.claude/diary/2026-01-05-bad-class.md"

  # (d) conditional SEM valid_when → FALHA (promete re-teste dirigido que não pode cumprir)
  printf -- '---\ndate: 2026-01-06\ntype: learning\nclassification: public\nreview_after: 2099-01-01\nconflict_class: conditional\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-06-cond-sem-when.md"
  rc=0; out="$(bash "${di}" "${d}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q "exige valid_when"; then
    record_pass "diary-crumbs: conditional sem valid_when → exit 1 (guarda do enabler)"
  else record_fail "diary-crumbs: cond sem when" "esperava exit 1 + erro; out='${out}' rc=${rc}"; fi
  rm -f "${d}/.claude/diary/2026-01-06-cond-sem-when.md"

  # (e) `type` fora do enum → FALHA alto. O drift real que motivou a guarda: 2 migalhas com
  # `type: reflection` passaram batido porque o script validava conflict_class e NÃO type.
  printf -- '---\ndate: 2026-01-07\ntype: musing\nclassification: public\nreview_after: 2099-01-01\nconflict_class: static\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-07-bad-type.md"
  rc=0; out="$(bash "${di}" "${d}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q "type 'musing' inválido"; then
    record_pass "diary-crumbs: type fora do enum → exit 1 com erro nomeado"
  else record_fail "diary-crumbs: type inválido" "esperava exit 1 + erro; out='${out}' rc=${rc}"; fi
  rm -f "${d}/.claude/diary/2026-01-07-bad-type.md"

  # (f) `reflection` (promovido ao enum em 2026-07-17) → passa. Prova que a guarda não é
  # retroativa contra as 2 migalhas reais que o campo já escreveu.
  printf -- '---\ndate: 2026-01-08\ntype: reflection\nclassification: public\nreview_after: 2099-01-01\nconflict_class: static\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-08-reflection-entry.md"
  rc=0; bash "${di}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "diary-crumbs: type reflection → passa (promovido ao enum)"
  else record_fail "diary-crumbs: reflection" "esperava exit 0, veio ${rc}"; fi

  # (g) `significance` (1.3.0) — o caminho NÃO-VAZIO. A coluna nasceu 100% travessão (nenhuma
  # entrada real a usava), então sem este caso um refactor do bloco de extração quebraria em
  # silêncio. Exercita também os dois perigos do campo: `|` (quebraria a tabela markdown → vira
  # `/`) e aspas de borda (removidas). O caminho VAZIO já é coberto pelas entradas (a)-(f).
  printf -- '---\ndate: 2026-01-09\ntype: learning\nclassification: public\nreview_after: 2099-01-01\nconflict_class: static\nsignificance: "Prova o caminho | com pipe e aspas — vale ler"\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-09-sig-entry.md"
  rc=0; bash "${di}" "${d}" >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ] \
     && grep -q 'Prova o caminho / com pipe e aspas' "${d}/.claude/diary/index.md" \
     && ! grep -q 'significance: "' "${d}/.claude/diary/index.md"; then
    record_pass "diary-crumbs: significance não-vazia → surfaça no índice (pipe escapado, aspas removidas)"
  else record_fail "diary-crumbs: significance não-vazia" "esperava a frase no índice com '|' virando '/'; rc=${rc}"; fi
  rm -f "${d}/.claude/diary/2026-01-09-sig-entry.md"

  # (h) MARCADOR DE EXIBIÇÃO NO FRONTMATTER → FALHA alto (guarda de 2026-08-18). O 📤 é o
  # SHARE_MARKER que o PRÓPRIO diary-index.sh acrescenta ao índice — escrevê-lo na fonte é
  # projeção copiada para dentro da origem (fonte≠derivação invertido). O drift real: 3
  # migalhas com `classification: collective 📤` passaram batido porque o awk lia só o $2 e
  # engolia o sufixo em silêncio. A guarda valida a LINHA inteira contra o enum.
  printf -- '---\ndate: 2026-01-10\ntype: learning\nclassification: collective 📤\nreview_after: 2099-01-01\nconflict_class: static\n---\n## Signal\nx\n' \
    > "${d}/.claude/diary/2026-01-10-marker-in-source.md"
  rc=0; out="$(bash "${di}" "${d}" 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q "pertence ao ÍNDICE"; then
    record_pass "diary-crumbs: (h) marcador 📤 no frontmatter → exit 1 (projeção não entra na fonte)"
  else record_fail "diary-crumbs: (h) marcador na fonte" "esperava exit 1 + erro nomeado; rc=${rc} out='$(printf '%s' "${out}" | head -2)'"; fi

  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo session-beacon — exercita o FAROL DE SESSÃO (validation/session-beacon.sh
# + hooks/session-beacon-hook.sh). Incidente 2026-07-02: sessão W1 fez checkout
# num repo com sessão W2 viva — I3 inclui sessões, não só commits. O farol é
# sinal (advisory), não trava. Self-contained: repo git em mktemp.
# ---------------------------------------------------------------------------
run_session_beacon_selftests() {
  local sb="${REPO_ROOT}/.claude/validation/session-beacon.sh"
  local hk="${REPO_ROOT}/.claude/hooks/session-beacon-hook.sh"
  if [ ! -f "${sb}" ]; then record_fail "session-beacon" "script ausente: ${sb}"; return; fi
  local d out rc
  # DETERMINISMO do veredito: a sonda de dono elegeria o `claude` ancestral quando a
  # bancada roda numa sessão, e NADA no CI — o mesmo teste daria `live` aqui e `declared`
  # lá. Apontando a sonda para o pid 1 (comm=systemd, nunca `claude`) ela falha SEMPRE,
  # e os casos herdados exercitam o ramo `declared` nos dois lugares. Os casos com dono
  # medido (j..m) escrevem owner_pid/owner_start à mão, sem depender da sonda.
  export ONION_BEACON_OWNER_PID=1

  d="$(mktemp -d)"; git -C "${d}" init -q
  mkdir -p "${d}/.claude/validation" "${d}/.claude/hooks"
  cp "${sb}" "${d}/.claude/validation/"; [ -f "${hk}" ] && cp "${hk}" "${d}/.claude/hooks/"

  # (a) up cria farol com campos + exclude local (não commitável) idempotente
  bash "${sb}" up "${d}" "sess-alpha" "core-hat"
  bash "${sb}" up "${d}" "sess-alpha" "core-hat"
  if [ -f "${d}/.claude/beacons/sess-alpha.beacon" ] \
     && grep -q '^hat: core-hat' "${d}/.claude/beacons/sess-alpha.beacon" \
     && [ "$(grep -cx '.claude/beacons/' "${d}/.git/info/exclude")" = "1" ]; then
    record_pass "session-beacon: up cria farol + exclude local idempotente"
  else record_fail "session-beacon: up" "farol/exclude errados em ${d}"; fi

  # (b) check com farol VIVO alheio → exit 1 e lista 🕯️ (regressão colisão W1×W2)
  rc=0; out="$(bash "${sb}" check "${d}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q '🕯️ DECLARADA (dono NÃO verificado): sess-alpha'; then
    record_pass "session-beacon: farol sem dono medido → DECLARADA + exit 1 (conservador; regressão W1×W2)"
  else record_fail "session-beacon: check vivo" "esperava exit 1 + DECLARADA; out='${out}' rc=${rc}"; fi

  # (c) --ignore da própria sessão → exit 0 (sessão não se auto-bloqueia)
  rc=0; bash "${sb}" check "${d}" --ignore "sess-alpha" >/dev/null || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "session-beacon: --ignore próprio farol → exit 0"
  else record_fail "session-beacon: ignore" "esperava exit 0, veio ${rc}"; fi

  # (d) farol STALE (refreshed_at antigo) → listado como stale, exit 0 (sinal, não trava)
  sed -i 's/^refreshed_at:.*/refreshed_at: 1000000/' "${d}/.claude/beacons/sess-alpha.beacon"
  rc=0; out="$(bash "${sb}" check "${d}")" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '(stale) sess-alpha'; then
    record_pass "session-beacon: stale não bloqueia (sessão morta não trava o repo)"
  else record_fail "session-beacon: stale" "esperava exit 0 + stale; out='${out}' rc=${rc}"; fi

  # (e) sweep remove stale; down remove vivo → check limpo
  bash "${sb}" sweep "${d}"
  bash "${sb}" up "${d}" "sess-beta"
  bash "${sb}" down "${d}" "sess-beta"
  rc=0; out="$(bash "${sb}" check "${d}")" || rc=$?
  if [ "${rc}" -eq 0 ] && [ -z "${out}" ] && [ ! -f "${d}/.claude/beacons/sess-alpha.beacon" ]; then
    record_pass "session-beacon: sweep+down limpam → check silencioso exit 0"
  else record_fail "session-beacon: sweep/down" "esperava vazio+0; out='${out}' rc=${rc}"; fi

  # (f) hook: SessionStart com session_id acende farol; com OUTRO vivo → aviso 🕯️; exit 0 sempre
  if [ -f "${hk}" ]; then
    bash "${sb}" up "${d}" "sess-other"
    rc=0; out="$(cd "${d}" && printf '{"session_id":"sess-self"}' | bash .claude/hooks/session-beacon-hook.sh up)" || rc=$?
    if [ "${rc}" -eq 0 ] && [ -f "${d}/.claude/beacons/sess-self.beacon" ] \
       && printf '%s' "${out}" | grep -q 'farol aceso neste repo'; then
      record_pass "session-beacon: hook acende farol + avisa colisão no boot (exit 0)"
    else record_fail "session-beacon: hook" "esperava farol+aviso+0; out='${out}' rc=${rc}"; fi

    # (f2) INFORMADO ≠ VERIFICADO (correção do maestro 2026-08-28): o aviso não pode
    # AFIRMAR sessão alheia viva — tem de se declarar não-verificado E mandar verificar
    # quem é e o que faz. Sem este teste, a próxima reescrita do texto silenciosamente
    # volta a afirmar, e a sessão que lê volta a invocar I3 contra fantasma.
    if printf '%s' "${out}" | grep -q 'INFORMADO, NÃO VERIFICADO' \
       && printf '%s' "${out}" | grep -q 'VERIFIQUE QUEM É E O QUE FAZ'; then
      record_pass "session-beacon: aviso se declara NÃO-VERIFICADO e manda verificar quem/o quê"
    else record_fail "session-beacon: aviso informado≠verificado" "o aviso voltou a AFIRMAR sessão viva sem mandar verificar; out='${out}'"; fi

    # (g) hook sem session_id (harness antigo) → no-op silencioso exit 0
    rc=0; out="$(cd "${d}" && printf '{}' | bash .claude/hooks/session-beacon-hook.sh up)" || rc=$?
    if [ "${rc}" -eq 0 ] && [ -z "${out}" ]; then
      record_pass "session-beacon: hook sem session_id → no-op silencioso"
    else record_fail "session-beacon: hook no-op" "esperava vazio+0; out='${out}' rc=${rc}"; fi
  else
    record_fail "session-beacon" "hook ausente: ${hk}"
  fi

  # (h) refresh preserva o hat declarado — regressão do bug: 'up' sem hat NÃO apaga a
  # intenção de escrita. Cobre o modo-de-falha (hat sobrescrito) E o happy-path (declarar
  # de novo vence). Bug de campo: o hook 'refresh' chama 'up' sem hat a cada UserPromptSubmit.
  bash "${sb}" up "${d}" "sess-hat" "item2-hat"           # declara a intenção
  bash "${sb}" up "${d}" "sess-hat"                        # refresh SEM hat (simula o hook)
  if grep -q '^hat: item2-hat' "${d}/.claude/beacons/sess-hat.beacon"; then
    record_pass "session-beacon: refresh sem hat preserva a intenção declarada (não vira —)"
  else record_fail "session-beacon: hat preservado" "refresh apagou o hat: $(grep '^hat:' "${d}/.claude/beacons/sess-hat.beacon")"; fi
  # modo-de-falha inverso: um hat explícito novo TEM que vencer (preservação não congela)
  bash "${sb}" up "${d}" "sess-hat" "outro-hat"
  bash "${sb}" up "${d}" "sess-hat"                        # e o novo também sobrevive ao refresh
  if grep -q '^hat: outro-hat' "${d}/.claude/beacons/sess-hat.beacon"; then
    record_pass "session-beacon: hat explícito novo sobrescreve + sobrevive ao refresh"
  else record_fail "session-beacon: hat override" "novo hat não venceu: $(grep '^hat:' "${d}/.claude/beacons/sess-hat.beacon")"; fi
  bash "${sb}" down "${d}" "sess-hat"

  # ── DONO MEDIDO (a metade verificável do farol; correção 2026-08-28) ──────
  # Modo-de-falha de campo: 2 faróis anunciados como VIVOS no core não tinham dono nenhum
  # e nunca haviam recebido um prompt — o aviso de colisão I3 disparou contra fantasmas.
  local live_start dead_pid dead_start fake_dir fake_pid child_pid
  set_beacon_owner() { # $1=beacon $2=pid $3=starttime — substitui, não apenda (awk pega o 1º)
    sed -i '/^owner_pid:/d;/^owner_start:/d' "$1"
    printf 'owner_pid: %s\nowner_start: %s\n' "$2" "$3" >> "$1"
  }

  # (j) dono VIVO medido → live, BLOQUEIA, e o TEXTO impresso é o rótulo verificado.
  # (o exit code sozinho não prova qual rótulo o humano/hook lê — por isso o grep)
  # sandbox PRÓPRIO: no compartilhado sobram os beacons do teste do hook e o exit 1 vinha
  # DELES — mutei o motor p/ `live` deixar de bloquear e a suíte inteira passou verde
  # (achado adversarial 2026-08-28). Teste que não isola mede o vizinho, não o SUT.
  local ddon; ddon="$(mktemp -d)"; git -C "${ddon}" init -q
  bash "${sb}" up "${ddon}" "sess-dono"
  live_start="$(sed 's/.*) //' "/proc/$$/stat" 2>/dev/null | awk '{print $20}' || true)"
  if [ -n "${live_start}" ]; then
    set_beacon_owner "${ddon}/.claude/beacons/sess-dono.beacon" "$$" "${live_start}"
    out="$(bash "${sb}" verdict "${ddon}/.claude/beacons/sess-dono.beacon")"
    rc=0; out2="$(bash "${sb}" check "${ddon}")" || rc=$?
    if [ "${out}" = "live" ] && [ "${rc}" -eq 1 ] \
       && printf '%s' "${out2}" | grep -q '🕯️ VIVA (dono verificado): sess-dono'; then
      record_pass "session-beacon: dono vivo medido → live + rótulo VIVA + BLOQUEIA sozinho (I3)"
    else record_fail "session-beacon: dono vivo" "esperava live+exit1+rótulo; veredito='${out}' rc=${rc} out='${out2}'"; fi

    # (k) REUSO DE PID: mesmo pid, starttime diferente → o dono não é encontrado. Com o
    # heartbeat RECENTE o veredito correto é `declared` (a morte não está provada), e com
    # o heartbeat PARADO vira `orphan`. Os dois lados são medidos abaixo.
    set_beacon_owner "${ddon}/.claude/beacons/sess-dono.beacon" "$$" "1"
    out="$(bash "${sb}" verdict "${ddon}/.claude/beacons/sess-dono.beacon")"
    if [ "${out}" = "declared" ]; then
      record_pass "session-beacon: dono não-encontrado + heartbeat RECENTE → declared (não declara morta quem agiu agora)"
    else record_fail "session-beacon: graça do órfão" "esperava declared, veio '${out}'"; fi

    # (k2) A INVARIANTE CENTRAL, do lado que a revisão adversarial derrubou: uma sessão
    # que trocou de processo (resume/restart com o mesmo sid) mantém o dono VELHO no
    # beacon. Antes da cura o veredito era `orphan` e o `check` saía 0 — LIBERANDO outra
    # sessão a escrever por cima. Aqui o heartbeat é de agora: tem de BLOQUEAR.
    rc=0; bash "${sb}" check "${ddon}" >/dev/null || rc=$?
    if [ "${rc}" -eq 1 ]; then
      record_pass "session-beacon: dono morto + heartbeat recente NÃO libera a árvore (W1×W2 fechado)"
    else record_fail "session-beacon: I3 com dono trocado" "check liberou (rc=${rc}) uma sessão que bateu heartbeat agora"; fi

    # (k3) passada a janela de graça, o fantasma volta a ser removível
    sed -i "s/^refreshed_at:.*/refreshed_at: $(( $(date +%s) - 3600 ))/" "${ddon}/.claude/beacons/sess-dono.beacon"
    out="$(bash "${sb}" verdict "${ddon}/.claude/beacons/sess-dono.beacon")"
    if [ "${out}" = "orphan" ]; then
      record_pass "session-beacon: dono morto + heartbeat PARADO → orphan (o poder de matar fantasma sobrevive)"
    else record_fail "session-beacon: órfão pós-graça" "esperava orphan, veio '${out}'"; fi

    # (k4) beacon de OUTRA máquina: o pid nem é deste kernel → nada a medir → declared
    bash "${sb}" up "${ddon}" "sess-outrohost"
    set_beacon_owner "${ddon}/.claude/beacons/sess-outrohost.beacon" "999999" "12345"
    sed -i 's/^host:.*/host: uma-maquina-que-nao-e-esta/' "${ddon}/.claude/beacons/sess-outrohost.beacon"
    sed -i "s/^refreshed_at:.*/refreshed_at: $(( $(date +%s) - 3600 ))/" "${ddon}/.claude/beacons/sess-outrohost.beacon"
    out="$(bash "${sb}" verdict "${ddon}/.claude/beacons/sess-outrohost.beacon")"
    if [ "${out}" = "declared" ]; then
      record_pass "session-beacon: beacon de outro host → declared (pid alheio não é prova de morte)"
    else record_fail "session-beacon: host alheio" "esperava declared, veio '${out}'"; fi

    # (k5) carimbo corrompido não pode derrubar a listagem inteira (set -u)
    sed -i 's/^refreshed_at:.*/refreshed_at: abc/' "${ddon}/.claude/beacons/sess-outrohost.beacon"
    rc=0; out2="$(bash "${sb}" check "${ddon}")" || rc=$?
    if printf '%s' "${out2}" | grep -q 'sess-dono'; then
      record_pass "session-beacon: refreshed_at corrompido não engole a listagem (o vivo segue impresso)"
    else record_fail "session-beacon: carimbo corrompido" "listagem perdida; out='${out2}' rc=${rc}"; fi
  else
    record_skip "session-beacon: dono vivo/graça/host/carimbo — sem /proc neste host (SUT não exercido)"
  fi
  rm -rf "${ddon}"

  # (j2) CAMINHO POSITIVO DA SONDA — o que faltava: provar que ela ELEGE o dono certo, e
  # não só que rejeita o errado. Um `claude` FALSO e determinístico (cópia do binário
  # `sleep` renomeada → comm=claude) dispensa haver uma sessão real por perto: o mesmo
  # veredito em dev e no CI. Sem este caso, inverter a comparação de `comm` passaria batido.
  fake_dir="$(mktemp -d)"
  if cp "$(command -v sleep)" "${fake_dir}/claude" 2>/dev/null; then
    "${fake_dir}/claude" 30 & fake_pid=$!
    if [ "$(cat "/proc/${fake_pid}/comm" 2>/dev/null || true)" = "claude" ]; then
      ONION_BEACON_OWNER_PID="${fake_pid}" bash "${sb}" up "${d}" "sess-eleito"
      out="$(awk -F': ' '/^owner_pid:/{print $2; exit}' "${d}/.claude/beacons/sess-eleito.beacon" 2>/dev/null || true)"
      if [ "${out}" = "${fake_pid}" ] \
         && [ "$(bash "${sb}" verdict "${d}/.claude/beacons/sess-eleito.beacon")" = "live" ]; then
        record_pass "session-beacon: sonda ELEGE o dono por comm=claude → owner gravado + veredito live"
      else record_fail "session-beacon: sonda elege" "esperava owner_pid=${fake_pid}+live; veio '${out}'"; fi

      # (j3) PRESERVAÇÃO DO DONO no refresh — a razão de existir citada no próprio código:
      # um refresh cuja sonda falha NÃO pode degradar um veredito medido de volta a declared.
      ONION_BEACON_OWNER_PID=1 bash "${sb}" up "${d}" "sess-eleito"
      out="$(awk -F': ' '/^owner_pid:/{print $2; exit}' "${d}/.claude/beacons/sess-eleito.beacon" 2>/dev/null || true)"
      if [ "${out}" = "${fake_pid}" ] \
         && [ "$(bash "${sb}" verdict "${d}/.claude/beacons/sess-eleito.beacon")" = "live" ]; then
        record_pass "session-beacon: refresh com sonda falha PRESERVA o dono medido (não degrada p/ declared)"
      else record_fail "session-beacon: preserva dono" "refresh perdeu o dono: owner_pid='${out}'"; fi

      # (j4) `sweep` NÃO pode remover beacon de dono vivo (o oposto do caso da órfã)
      bash "${sb}" sweep "${d}"
      if [ -f "${d}/.claude/beacons/sess-eleito.beacon" ]; then
        record_pass "session-beacon: sweep preserva beacon de dono VIVO"
      else record_fail "session-beacon: sweep preserva" "sweep apagou beacon de sessão viva"; fi
      bash "${sb}" down "${d}" "sess-eleito"
    else
      record_skip "session-beacon: sonda elege/preserva/sweep-vivo — comm não observável neste host"
    fi
    kill "${fake_pid}" 2>/dev/null || true; wait "${fake_pid}" 2>/dev/null || true
  else
    record_skip "session-beacon: sonda elege/preserva/sweep-vivo — sem binário copiável (SUT não exercido)"
  fi

  # (j5) SUBIDA NA ÁRVORE + ramo argv0: a sonda tem de achar o dono ACIMA do pid de partida,
  # não só no hop 0. Monta um processo cujo argv0 é "claude" (comm continua "bash", então
  # quem casa é o ramo `${argv0##*/}`) com um FILHO `sleep`. Partindo do FILHO, o dono
  # correto é o PAI — prova o passeio por ppid, que nenhum outro caso exercita.
  bash -c 'exec -a claude bash -c "sleep 30 & wait"' & fake_pid=$!
  child_pid=""
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    child_pid="$(pgrep -P "${fake_pid}" 2>/dev/null | head -1 || true)"
    [ -n "${child_pid}" ] && break
    sleep 0.2
  done
  out="$(tr '\0' '\n' < "/proc/${fake_pid}/cmdline" 2>/dev/null | head -1 || true)"
  if [ -n "${child_pid}" ] && [ "${out}" = "claude" ]; then
    ONION_BEACON_OWNER_PID="${child_pid}" bash "${sb}" up "${d}" "sess-subida"
    out="$(awk -F': ' '/^owner_pid:/{print $2; exit}' "${d}/.claude/beacons/sess-subida.beacon" 2>/dev/null || true)"
    if [ "${out}" = "${fake_pid}" ]; then
      record_pass "session-beacon: sonda SOBE a árvore e elege o dono pelo ramo argv0 (hop>0)"
    else record_fail "session-beacon: sonda sobe" "esperava owner_pid=${fake_pid} (pai do ${child_pid}), veio '${out}'"; fi
    bash "${sb}" down "${d}" "sess-subida"
  else
    record_skip "session-beacon: sonda sobe a árvore — cenário não montado (argv0='${out}', filho='${child_pid}')"
  fi
  kill "${fake_pid}" 2>/dev/null || true; wait "${fake_pid}" 2>/dev/null || true
  rm -rf "${fake_dir}"

  # (l) dono MEDIDO MORTO → orphan: NÃO bloqueia, imprime o rótulo de órfã e o sweep remove.
  # É o que impede o fantasma de travar o repo por 8h de TTL depois de a sessão sumir.
  ( exec sleep 30 ) & dead_pid=$!
  dead_start="$(sed 's/.*) //' "/proc/${dead_pid}/stat" 2>/dev/null | awk '{print $20}' || true)"
  kill "${dead_pid}" 2>/dev/null || true; wait "${dead_pid}" 2>/dev/null || true
  if [ -n "${dead_start}" ] && [ ! -r "/proc/${dead_pid}/stat" ]; then
    # sandbox PRÓPRIO: no compartilhado sobram os beacons vivos do teste do hook, e o
    # exit 1 viria DELES — o teste passaria/falharia por motivo alheio ao que afirma medir.
    local dorf; dorf="$(mktemp -d)"; git -C "${dorf}" init -q
    bash "${sb}" up "${dorf}" "sess-orfa"
    set_beacon_owner "${dorf}/.claude/beacons/sess-orfa.beacon" "${dead_pid}" "${dead_start}"
    # heartbeat PARADO além da janela de graça: sem isso o veredito correto é `declared`
    # (dono morto + heartbeat recente = morte não provada), e o fantasma não é fantasma.
    sed -i "s/^refreshed_at:.*/refreshed_at: $(( $(date +%s) - 3600 ))/" "${dorf}/.claude/beacons/sess-orfa.beacon"
    out="$(bash "${sb}" verdict "${dorf}/.claude/beacons/sess-orfa.beacon")"
    rc=0; out2="$(bash "${sb}" check "${dorf}")" || rc=$?
    bash "${sb}" sweep "${dorf}"
    if [ "${out}" = "orphan" ] && [ "${rc}" -eq 0 ] \
       && printf '%s' "${out2}" | grep -q '(órfã) sess-orfa' \
       && [ ! -f "${dorf}/.claude/beacons/sess-orfa.beacon" ]; then
      record_pass "session-beacon: dono morto → órfã não bloqueia + rótulo impresso + sweep remove"
    else record_fail "session-beacon: órfã" "esperava orphan+exit0+rótulo+removido; veredito='${out}' rc=${rc} out='${out2}'"; fi
    rm -rf "${dorf}"
  else
    record_skip "session-beacon: órfã — sem /proc neste host (SUT não exercido)"
  fi

  # (m) a sonda NÃO pode eleger um processo só porque o cmdline dele contém "claude" (o path
  # `~/.claude/shell-snapshots/…` contém). Bug REAL do dogfood 2026-08-28: elegia o shell do
  # próprio hook, que morre em segundos — o farol viraria órfã com a sessão VIVA.
  # O decoy é REPARENTADO para o init (`setsid --fork`): sem isso a sonda subiria a árvore
  # REAL da bancada e acharia um `claude` legítimo a 1-2 hops numa sessão de dev — o teste
  # passaria por motivo diferente em dev e no CI (achado da revisão adversarial).
  local pidf; pidf="$(mktemp)"
  if command -v setsid >/dev/null 2>&1 \
     && setsid --fork bash -c 'echo $$ > "$1"; exec -a "/home/fake/.claude/shell-snapshots/snapshot-bash.sh" sleep 30' _ "${pidf}" 2>/dev/null; then
    child_pid=""
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      child_pid="$(cat "${pidf}" 2>/dev/null || true)"; [ -n "${child_pid}" ] && break; sleep 0.2
    done
    # só vale como teste se o decoy REALMENTE ficou órfão de árvore (ppid=1) e o cmdline
    # dele carrega "claude" — senão não é o cenário que o bug exigia
    out="$(sed 's/.*) //' "/proc/${child_pid}/stat" 2>/dev/null | awk '{print $2}' || true)"
    if [ -n "${child_pid}" ] && [ "${out}" = "1" ] \
       && tr '\0' ' ' < "/proc/${child_pid}/cmdline" 2>/dev/null | grep -q 'claude'; then
      ONION_BEACON_OWNER_PID="${child_pid}" bash "${sb}" up "${d}" "sess-sonda"
      if ! grep -q '^owner_pid:' "${d}/.claude/beacons/sess-sonda.beacon"; then
        record_pass "session-beacon: sonda REJEITA processo não-claude com 'claude' no cmdline (comm/argv0 decidem)"
      else record_fail "session-beacon: sonda rejeita" "elegeu dono indevido: $(grep '^owner_pid:' "${d}/.claude/beacons/sess-sonda.beacon")"; fi
      bash "${sb}" down "${d}" "sess-sonda"
    else
      record_skip "session-beacon: sonda rejeita — decoy não reparentou p/ init (ppid=${out}); cenário não montado"
    fi
    kill "${child_pid}" 2>/dev/null || true
  else
    record_skip "session-beacon: sonda rejeita — setsid indisponível (SUT não exercido)"
  fi
  rm -f "${pidf}"

  # (i) key-by-worktree: 'up' grava a linha `worktree:` = toplevel realpath; refresh preserva.
  # É o que a COLUNA PRESENÇA do mapa da constelação lê p/ atribuir o beacon à estrela certa.
  bash "${sb}" up "${d}" "sess-wt" "wt-hat"
  wt_expected="$(realpath "${d}" 2>/dev/null || echo "${d}")"
  if grep -q "^worktree: ${wt_expected}$" "${d}/.claude/beacons/sess-wt.beacon"; then
    record_pass "session-beacon: up grava worktree: = toplevel (key-by-worktree p/ presença)"
  else record_fail "session-beacon: worktree field" "esperava 'worktree: ${wt_expected}'; veio '$(grep '^worktree:' "${d}/.claude/beacons/sess-wt.beacon")'"; fi
  bash "${sb}" up "${d}" "sess-wt"                          # refresh sem args
  if grep -q "^worktree: ${wt_expected}$" "${d}/.claude/beacons/sess-wt.beacon"; then
    record_pass "session-beacon: worktree sobrevive ao refresh"
  else record_fail "session-beacon: worktree refresh" "refresh perdeu worktree"; fi
  bash "${sb}" down "${d}" "sess-wt"

  # (ii) exclude no COMMON-dir: em worktree LIGADA, o beacon tem que ficar git-invisível.
  # Modo-de-falha (o bug latente): escrever o exclude no git-dir por-worktree deixaria o
  # beacon como '??' no status. Prova: após 'up' na worktree ligada, git status é limpo.
  local main lw
  main="$(mktemp -d)"; git -C "${main}" init -q
  export GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
         GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test
  git -C "${main}" commit -q --allow-empty -m base
  mkdir -p "${main}/.claude/validation"; cp "${sb}" "${main}/.claude/validation/"
  lw="$(mktemp -d)/linked"; git -C "${main}" worktree add -q "${lw}" -b wt-branch 2>/dev/null
  if [ -d "${lw}" ]; then
    bash "${main}/.claude/validation/session-beacon.sh" up "${lw}" "sess-linked" "lw-hat" 2>/dev/null
    # -uall é OBRIGATÓRIO: sem ele, git COLAPSA untracked p/ '?? .claude/' e o grep nunca
    # veria o beacon (teste vacuário). Com -uall, o beacon aparece SE não estiver excluído.
    # Prova do modo-de-falha: git 2.43 NÃO lê o info/exclude por-worktree — só o do common-dir
    # esconde. Sem o fix (--git-common-dir), este grep acharia o beacon → falha.
    local leaked; leaked="$(git -C "${lw}" status --porcelain -uall 2>/dev/null | grep -c 'beacons/sess-linked.beacon' || true)"
    if [ -f "${lw}/.claude/beacons/sess-linked.beacon" ] && [ "${leaked}" = "0" ]; then
      record_pass "session-beacon: beacon em worktree ligada fica git-invisível (exclude no common-dir)"
    else record_fail "session-beacon: exclude common-dir" "beacon vazou no git status -uall (grep=${leaked}) — exclude no dir errado?"; fi
    git -C "${main}" worktree remove --force "${lw}" 2>/dev/null || true
  else
    record_fail "session-beacon: exclude common-dir" "git worktree add falhou (setup)"
  fi
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  rm -rf "${main}"

  rm -rf "${d}"

  unset ONION_BEACON_OWNER_PID   # não vazar o determinismo da sonda p/ outros modos
}
# ---------------------------------------------------------------------------
# Modo constellation-map — exercita .claude/validation/constellation-map.sh (o 🗺️ MAPA da
# Constelação de Estudos, Fase 1). READ-ONLY, SÓ-METADADOS. Self-contained (dir de
# discussões + repo git em mktemp). Cobre o modo-de-falha (corpo-nunca-lido, presença) e o
# happy-path (colisão/convergência/painel/json). Molde: os run_*_selftests self-contained.
# ---------------------------------------------------------------------------
run_constellation_map_selftests() {
  local map="${REPO_ROOT}/.claude/validation/constellation-map.sh"
  if [ ! -f "${map}" ]; then record_fail "constellation-map" "script ausente: ${map}"; return; fi
  local dd out rc

  # ── Parte 1 (a–f): dir de discussões NÃO-git; presença toda dark (não é o foco aqui) ──
  dd="$(mktemp -d)"
  mkdir -p "${dd}/_template" "${dd}/alpha" "${dd}/beta" "${dd}/gamma" "${dd}/decoy"
  printf 'title: "T"\nphase: SEED\n' > "${dd}/_template/SEED.md"   # _template deve ser IGNORADO
  cat > "${dd}/alpha/SEED.md" <<'EOF'
---
title: "Alpha"
branch: discuss/alpha
phase: EXPLORE        # SEED | EXPLORE | DEEP
next_action: "passo alpha bem longo para exercitar o truncamento do painel além de sessenta e quatro chars"
scope_globs: ["docs/onion/graph/", "docs/x/"]
objective_tags: ["NS1", "z"]
---
# corpo alpha (não deve ser lido)
EOF
  cat > "${dd}/beta/SEED.md" <<'EOF'
---
title: "Beta"
branch: discuss/beta
phase: DEEP
next_action: "passo beta"
scope_globs: ["docs/onion/graph/"]
objective_tags: ["NS1"]
---
EOF
  cat > "${dd}/gamma/SEED.md" <<'EOF'
---
title: "Gamma"
branch: discuss/gamma
phase: PARK
next_action: "passo gamma"
scope_globs: ["docs/unique/"]
objective_tags: ["solo"]
---
EOF
  # decoy: objective_tags AUSENTE do frontmatter DE PROPÓSITO. Um parser que leia o corpo
  # pegaria o SECRETTAG do corpo (o boundary parser não — sai no 2º '---'). É o que torna o
  # caso (f) DISCRIMINANTE do limite estrutural (não só do first-match-exit dos extratores).
  cat > "${dd}/decoy/SEED.md" <<'EOF'
---
title: "Decoy"
branch: discuss/decoy
phase: SEED
next_action: "passo decoy"
scope_globs: ["docs/real/"]
---
# CORPO — o mapa NUNCA pode ler daqui pra baixo (objective_tags só existe AQUI):
objective_tags: ["SECRETTAG"]
scope_globs: ["SECRET"]
EOF

  rc=0; out="$(bash "${map}" --dir "${dd}" 2>&1)" || rc=$?

  # (a) lista N=4 (o _template é ignorado) + phase + estrela
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q '4 estrela' \
     && printf '%s' "${out}" | grep -q 'alpha' && printf '%s' "${out}" | grep -q 'EXPLORE'; then
    record_pass "constellation-map: lista N estrelas (ignora _template) + phase"
  else record_fail "constellation-map: painel" "rc=${rc} out=${out}"; fi

  # (b) COLISÃO de escopo: docs/onion/graph/ em alpha+beta
  if printf '%s' "${out}" | grep -E 'docs/onion/graph/ →' | grep -q 'alpha' \
     && printf '%s' "${out}" | grep -E 'docs/onion/graph/ →' | grep -q 'beta'; then
    record_pass "constellation-map: colisão de scope_globs detectada (graph em 2)"
  else record_fail "constellation-map: colisão" "não achou a colisão graph; out=${out}"; fi

  # (c) CONVERGÊNCIA de objetivo: NS1 em alpha+beta
  if printf '%s' "${out}" | grep -E 'NS1 →' | grep -q 'alpha' \
     && printf '%s' "${out}" | grep -E 'NS1 →' | grep -q 'beta'; then
    record_pass "constellation-map: convergência de objective_tags detectada (NS1 em 2)"
  else record_fail "constellation-map: convergência" "não achou a convergência NS1; out=${out}"; fi

  # (d) sem falso-positivo: glob/tag únicos (gamma) NÃO aparecem em colisão/convergência
  if ! printf '%s' "${out}" | grep -q 'docs/unique/' && ! printf '%s' "${out}" | grep -qE 'solo →'; then
    record_pass "constellation-map: sem falso-positivo (glob/tag únicos de gamma fora das seções)"
  else record_fail "constellation-map: falso-positivo" "gamma vazou p/ colisão/convergência; out=${out}"; fi

  # (e) --json bem-formado: count == 4 (via jq, se houver)
  if command -v jq >/dev/null 2>&1; then
    rc=0; local jc; jc="$(bash "${map}" --dir "${dd}" --json 2>/dev/null | jq -r '.count' 2>/dev/null)" || rc=$?
    if [ "${rc}" -eq 0 ] && [ "${jc}" = "4" ]; then
      record_pass "constellation-map: --json bem-formado (jq: count=4)"
    else record_fail "constellation-map: json" "jq count=${jc} rc=${rc}"; fi
  else
    record_skip "constellation-map: --json (skip: jq ausente)"
  fi

  # (f) MODO-DE-FALHA só-metadados: o decoy no CORPO ('SECRET') NUNCA pode aparecer na saída.
  # Prova que o mapa lê SÓ o frontmatter (fronteira estrutural), nunca o corpo da discussão.
  local outj; outj="$(bash "${map}" --dir "${dd}" --json 2>&1; bash "${map}" --dir "${dd}" 2>&1)"
  # SECRETTAG (campo ausente do frontmatter) é o discriminante do LIMITE; SECRET reforça.
  if ! printf '%s' "${outj}" | grep -qE 'SECRET'; then
    record_pass "constellation-map: corpo NUNCA lido (decoy SECRETTAG/SECRET ausentes do painel e do json)"
  else record_fail "constellation-map: só-metadados" "VAZOU o corpo (SECRET* apareceu) — leu além do frontmatter!"; fi
  rm -rf "${dd}"

  # ── Parte 2 (g): PRESENÇA via git worktree add + beacon fresco/ausente ──
  local repo wt sb
  sb="${REPO_ROOT}/.claude/validation/session-beacon.sh"
  export GIT_AUTHOR_NAME=onion-selftest GIT_AUTHOR_EMAIL=ci@onion.test \
         GIT_COMMITTER_NAME=onion-selftest GIT_COMMITTER_EMAIL=ci@onion.test
  repo="$(mktemp -d)/r"; mkdir -p "${repo}/docs/discussions/star-p" "${repo}/docs/discussions/star-q"
  git -C "${repo}" init -q
  cat > "${repo}/docs/discussions/star-p/SEED.md" <<'EOF'
---
title: "P"
branch: discuss/star-p
phase: DEEP
next_action: "passo p"
scope_globs: ["docs/p/"]
objective_tags: ["p"]
---
EOF
  cat > "${repo}/docs/discussions/star-q/SEED.md" <<'EOF'
---
title: "Q"
branch: discuss/star-q
phase: SEED
next_action: "passo q"
scope_globs: ["docs/q/"]
objective_tags: ["q"]
---
EOF
  git -C "${repo}" add -A; git -C "${repo}" commit -qm seed
  wt="$(mktemp -d)/wt-p"; git -C "${repo}" worktree add -q "${wt}" -b discuss/star-p 2>/dev/null
  # beacon FRESCO na worktree da star-p (star-q não tem worktree → dark)
  if [ -d "${wt}" ]; then
    bash "${sb}" up "${wt}" "sess-p" "hat-p" 2>/dev/null
    out="$(bash "${map}" --dir "${repo}/docs/discussions" 2>&1)" || true
    # star-p com beacon fresco → 🕯️; star-q sem worktree → · (dark). Checa via json (robusto a colunas).
    local pp qq
    if command -v jq >/dev/null 2>&1; then
      pp="$(bash "${map}" --dir "${repo}/docs/discussions" --json 2>/dev/null | jq -r '.stars[]|select(.slug=="star-p").presence')"
      qq="$(bash "${map}" --dir "${repo}/docs/discussions" --json 2>/dev/null | jq -r '.stars[]|select(.slug=="star-q").presence')"
      if [ "${pp}" = "live" ] && [ "${qq}" = "dark" ]; then
        record_pass "constellation-map: presença — star-p 🕯️ (beacon fresco na worktree), star-q · (sem worktree)"
      else record_fail "constellation-map: presença" "esperava p=live q=dark; veio p=${pp} q=${qq}"; fi
    else
      # sem jq: valida pelo painel (a linha da star-p deve ter o 🕯️)
      if printf '%s' "${out}" | grep 'star-p' | grep -q '🕯️'; then
        record_pass "constellation-map: presença — star-p viva no painel (sem jq)"
      else record_fail "constellation-map: presença" "star-p não marcada viva; out=${out}"; fi
    fi
    bash "${sb}" down "${wt}" "sess-p" 2>/dev/null || true
    git -C "${repo}" worktree remove --force "${wt}" 2>/dev/null || true
  else
    record_fail "constellation-map: presença" "git worktree add falhou (setup)"
  fi
  unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  rm -rf "${repo}"
}

# ---------------------------------------------------------------------------
# Modo pin-integrity — exercita .claude/validation/pin-integrity-check.sh (o
# guard do /meta:adopt --update contra pin forjado — incidente 2026-06-30 (um adotante):
# stamp apontava HEAD do core, vendor era 6 dias mais velho, anúncio downstream
# saiu falso). Self-contained: core fake com 2 commits do canário em mktemp.
# ---------------------------------------------------------------------------
run_pin_integrity_selftests() {
  local pic="${REPO_ROOT}/.claude/validation/pin-integrity-check.sh"
  if [ ! -f "${pic}" ]; then record_fail "pin-integrity" "script ausente: ${pic}"; return; fi
  local src tgt pin1 out rc

  src="$(mktemp -d)"; tgt="$(mktemp -d)"
  git -C "${src}" init -q
  mkdir -p "${src}/.claude/validation" "${tgt}/.claude/validation"
  printf '#!/bin/sh\necho v1\n' > "${src}/.claude/validation/lint-artifacts.sh"
  git -C "${src}" add -A
  git -C "${src}" -c user.name=onion -c user.email=onion@selftest commit -qm v1
  pin1="$(git -C "${src}" rev-parse --short=12 HEAD)"
  printf '#!/bin/sh\necho v2\n' > "${src}/.claude/validation/lint-artifacts.sh"
  git -C "${src}" add -A
  git -C "${src}" -c user.name=onion -c user.email=onion@selftest commit -qm v2

  # (a) pin real + canário batendo → pin-ok, exit 0
  printf 'framework: onion\nsource_commit: %s\nrole: adopted\n' "${pin1}" > "${tgt}/.claude/.onion-version"
  printf '#!/bin/sh\necho v1\n' > "${tgt}/.claude/validation/lint-artifacts.sh"
  rc=0; out="$(bash "${pic}" "${src}" "${tgt}")" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q "^pin-ok ${pin1}"; then
    record_pass "pin-integrity: pin real + canário íntegro → pin-ok"
  else record_fail "pin-integrity: pin-ok" "esperava exit 0 'pin-ok ${pin1}'; out='${out}' rc=${rc}"; fi

  # (b) CASO DE CAMPO — pin real mas canário divergente (vendor mais velho/novo que o stamp) → untrusted
  printf '#!/bin/sh\necho v2\n' > "${tgt}/.claude/validation/lint-artifacts.sh"
  rc=0; out="$(bash "${pic}" "${src}" "${tgt}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'canario-divergente'; then
    record_pass "pin-integrity: canário divergente → untrusted (regressão do incidente de campo 06-30)"
  else record_fail "pin-integrity: canário" "esperava exit 1 canario-divergente; out='${out}' rc=${rc}"; fi

  # (c) pin unknown (recover honesto) → untrusted, sem quebrar
  printf 'framework: onion\nsource_commit: unknown\nrole: adopted\n' > "${tgt}/.claude/.onion-version"
  rc=0; out="$(bash "${pic}" "${src}" "${tgt}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'unknown'; then
    record_pass "pin-integrity: pin unknown → untrusted (recover honesto resolvível)"
  else record_fail "pin-integrity: unknown" "esperava exit 1 unknown; out='${out}' rc=${rc}"; fi

  # (d) pin inexistente na história da fonte → untrusted
  printf 'framework: onion\nsource_commit: deadbeefcafe\nrole: adopted\n' > "${tgt}/.claude/.onion-version"
  rc=0; out="$(bash "${pic}" "${src}" "${tgt}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'inexistente-na-historia'; then
    record_pass "pin-integrity: pin fora da história → untrusted"
  else record_fail "pin-integrity: história" "esperava exit 1 inexistente; out='${out}' rc=${rc}"; fi

  # (e) stamp ausente → untrusted (nunca crash)
  rm -f "${tgt}/.claude/.onion-version"
  rc=0; out="$(bash "${pic}" "${src}" "${tgt}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'stamp-ausente'; then
    record_pass "pin-integrity: stamp ausente → untrusted"
  else record_fail "pin-integrity: stamp" "esperava exit 1 stamp-ausente; out='${out}' rc=${rc}"; fi

  rm -rf "${src}" "${tgt}"
}

# ---------------------------------------------------------------------------
# Modo mail-hook — exercita .claude/hooks/co-evolution-inbox-check.sh (o "you
# have mail" + gatilho de reflexão ⏰ da RFC-0003 §2.3). Self-contained: cwd em
# sandbox mktemp (o hook usa paths relativos). Cobre a disciplina de motd
# (SILENCIOSO quando 0), os 3 sinais (📬 inbox / 📥 inbound / ⏰ diário vencido),
# as exclusões (index/README/_processed) e o invariante exit 0 sempre.
# ---------------------------------------------------------------------------
run_mail_hook_selftests() {
  local hook="${REPO_ROOT}/.claude/hooks/co-evolution-inbox-check.sh"
  if [ ! -f "${hook}" ]; then record_fail "mail-hook" "hook ausente: ${hook}"; return; fi
  local d out rc

  # (a) tudo vazio → silencioso (nenhum output) e exit 0
  d="$(mktemp -d)"; mkdir -p "${d}/docs/evolution/inbox" "${d}/.claude/diary"
  rc=0; out="$(cd "${d}" && bash "${hook}")" || rc=$?
  if [ -z "${out}" ] && [ "${rc}" -eq 0 ]; then record_pass "mail-hook: 0 mensagens → silencioso (motd)"
  else record_fail "mail-hook: silêncio" "esperava vazio+exit 0; out='${out}' rc=${rc}"; fi

  # (b) 1 inbox + 1 inbound → 📬 e 📥; README/_processed excluídos
  mkdir -p "${d}/docs/evolution/inbox/_processed" "${d}/docs/evolution/inbound"
  printf '# s\n' > "${d}/docs/evolution/inbox/2026-01-01-sinal.md"
  printf '# r\n' > "${d}/docs/evolution/inbox/README.md"
  printf '# p\n' > "${d}/docs/evolution/inbox/_processed/2025-12-01-velho.md"
  printf '# a\n' > "${d}/docs/evolution/inbound/2026-01-02-anuncio.md"
  out="$(cd "${d}" && bash "${hook}")"
  if printf '%s' "${out}" | grep -q '📬.*1 mensagem' && printf '%s' "${out}" | grep -q '📥.*1 entrega'; then
    record_pass "mail-hook: 📬+📥 contam só 1º nível (README/_processed fora)"
  else record_fail "mail-hook: canais" "contagem errada: ${out}"; fi

  # (c) diário: vencida conta, futura e index.md não → ⏰ com N=1
  printf -- '---\nreview_after: 2020-01-01\n---\n' > "${d}/.claude/diary/2020-01-01-velha.md"
  printf -- '---\nreview_after: 2099-01-01\n---\n' > "${d}/.claude/diary/2099-01-01-fresca.md"
  printf '# idx\n' > "${d}/.claude/diary/index.md"
  out="$(cd "${d}" && bash "${hook}")"
  if printf '%s' "${out}" | grep -q '⏰.*1 migalha'; then
    record_pass "mail-hook: ⏰ conta só review_after vencido (regressão RFC-0003 §2.3)"
  else record_fail "mail-hook: reflexão" "⏰ errado: ${out}"; fi

  # (d) exit 0 SEMPRE (mesmo com sinais presentes) — hook nunca falha a sessão
  rc=0; (cd "${d}" && bash "${hook}" >/dev/null) || rc=$?
  if [ "${rc}" -eq 0 ]; then record_pass "mail-hook: exit 0 sempre"
  else record_fail "mail-hook: exit" "esperava 0, veio ${rc}"; fi
  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo guardrails — exercita os 2 helpers determinísticos da camada Onion Guardrails
# (R15, ONION-R15): a cerca de proveniência (onion-untrusted-wrap.sh, em utils/guardrails/)
# e o gate de efeito (onion-effect-gate.sh, aqui em validation/guardrails/). É a "guarda das
# guardas" da camada: se um helper regredir (fence-breakout, gate que deixa passar execução
# derivada de untrusted, verbo desconhecido não-gated, loop de flag-sem-valor), o selftest
# reprova. Torna EXECUTÁVEL o invariante-3 (motor determinístico, zero probabilístico) —
# os harnesses test-r15.sh (9 casos, R15.1) e test-r15-3b.sh (9 casos, R15.3b) são o dogfood
# adversarial embarcado. Self-contained (os testes acham os helpers por path relativo).
# ---------------------------------------------------------------------------
run_guardrails_selftests() {
  local gdir="${SCRIPT_DIR}/guardrails"
  local wrap="${REPO_ROOT}/.claude/utils/guardrails/onion-untrusted-wrap.sh"
  local gate="${gdir}/onion-effect-gate.sh"
  if [ ! -f "${wrap}" ]; then record_fail "guardrails: wrap" "helper ausente: ${wrap}"; fi
  if [ ! -f "${gate}" ]; then record_fail "guardrails: effect-gate" "helper ausente: ${gate}"; fi
  local t out rc
  for t in "test-r15" "test-r15-3b"; do
    if [ ! -f "${gdir}/${t}.sh" ]; then record_fail "guardrails: ${t}" "harness ausente: ${gdir}/${t}.sh"; continue; fi
    rc=0; out="$(bash "${gdir}/${t}.sh" 2>&1)" || rc=$?
    if [ "${rc}" -eq 0 ]; then
      record_pass "guardrails: ${t}.sh dogfood adversarial ($(printf '%s' "${out}" | sed -n 's/.*== resultado: \([0-9]* passaram.*\) ==/\1/p' | tail -1))"
    else
      record_fail "guardrails: ${t}.sh" "dogfood reprovou (exit ${rc}) — $(printf '%s' "${out}" | grep '❌' | head -1)"
    fi
  done
}

# ---------------------------------------------------------------------------
# Loop do manifest (TAB-separado; ignora '#' e header)
# ---------------------------------------------------------------------------
echo "=== Onion Lint Selftest — auto-teste das guardas ==="
echo ""

if [ -f "${MANIFEST}" ]; then
  while IFS=$'\t' read -r kind fixture target verdict keyword || [ -n "${kind:-}" ]; do
    kind="${kind:-}"
    [ -z "${kind}" ] && continue
    [ "${kind#\#}" != "${kind}" ] && continue   # linha de comentário
    [ "${kind}" = "kind" ] && continue           # header
    case "${kind}" in
      lint)     run_lint_fixture "${fixture}" "${target}" "${verdict}" "${keyword:-}" ;;
      fix)      run_fix_fixture "${fixture}" "${target}" "${verdict}" ;;
      contract) run_contract_fixture "${fixture}" "${verdict}" ;;
      members)  run_members_fixture "${fixture}" "${verdict}" ;;
      kg)       run_kg_fixture "${fixture}" "${verdict}" ;;
      merge)    run_merge_fixture "${fixture}" ;;
      *)        record_fail "${fixture:-?}" "kind desconhecido '${kind}'" ;;
    esac
  done < "${MANIFEST}"
else
  record_skip "fixtures: manifest ausente → loop de fixture pulado (core-only; adotante não vendoriza fixtures/)"
fi

# Modo kg-freshness/schema — guardas de frescor + versão de schema (ADR kg-freshness-gate F1).
run_kg_freshness_selftests

# Modo kg-provenance — guarda de proveniência de decisão (ITEM2).
run_kg_provenance_selftests

# Modo reconcile — o ⚠ de alvo de SUPERSEDES não reconciliado (primeiro teste do bloco)
run_kg_reconcile_selftests

# Modo state — a fila de abertos, complementar ao radar por construção
run_kg_state_selftests
run_kg_open_queue_selftests
run_kg_trace_resolve_selftests
run_kg_seal_check_selftests
run_post_review_comment_selftests
run_status_reverificacao_selftests
run_worklog_precompact_breadcrumb_selftests
run_aside_router_hook_selftests
run_worklog_capture_session_selftests

# Modo kg-label-collision — conteúdo de label não pode ser lido como configuração
# (sinal de campo onion-pessoal-app, 2026-07-19).
run_kg_label_collision_selftests

# Modo resolve — não vem do manifest (cenários self-contained, sem fixture-file).
run_resolve_selftests

# Modo resolve-production — irmão do resolve-integration (branch de PRODUÇÃO).
run_resolve_production_selftests

# Modo durable-commit — commit durável da instalação (fix do incidente uncommitted-descartável).
run_durable_commit_selftests

# Modo guardrails — helpers R15 (cerca de proveniência + gate de efeito); a guarda das guardas.
run_guardrails_selftests

# Modo vendor-branch — --update via merge de onion/vendor (Achado #2: never-clobber estrutural).
run_vendor_branch_selftests

# Modo vendor-baseline-REMOVIDO — a cura D_CURE (2026-08-24): o baseline (ledger local) não vem do core.
run_vendor_baseline_removido_selftests

# Modo compose-settings — settings.json N-camadas de escopo (RFC-0005 plano 2).
run_compose_settings_selftests

# Modo resolve-scope-layers — fecha o loop do compose-settings (descobre a cadeia de escopo).
run_resolve_scope_layers_selftests

# Modo show-scope — proveniência-por-chave do compositor (RFC-0005 Fase 2, `--show-scope`).
run_show_scope_selftests

# Modo resolve-target — targeting fino por seletor no alvo: (F1.2 federação — mata o ruído).
run_resolve_target_selftests

# Modo reconcile-inputs — insumos determinísticos do /meta:co-announce --reconcile (conciliação de backlog).
run_reconcile_inputs_selftests

# Modo federation-radar — radar de saúde-de-verificação da federação (ADR federation-kg-audit-overlay).
run_federation_radar_selftests

# Modo federation-console — console estático read-only do SSOT (F1.3 federação).
run_federation_console_selftests
run_kg_console_selftests
run_kg_narrate_validate_selftests
run_site_inventory_selftests
run_adopted_role_selftests
run_write_stamp_selftests

# Modo mail-receiver — acelerador "receiver que acorda" (F1.4 federação).
run_mail_receiver_selftests

# Modo detect-transport — resolução SDAAL da via de transporte (F2.1 federação).
run_detect_transport_selftests

# Modo a2a-ssrf — anti-SSRF da URL de webhook A2A (camada 4 do gate a2a-verify, F2.2 fundação).
run_a2a_ssrf_selftests

# Modo a2a-verify — gate "verificação-antes-de-agir" do a2a-live (F2.2 fundação; 6 camadas + fail-safe).
run_a2a_verify_selftests

# Modo agent-card — gerador do Agent Card A2A do core, filtrado ao próprio core (F2.2 fundação; confidencialidade).
run_agent_card_selftests

# Modo a2a-accept — o ato humano fila→inbox que fecha o gate (F2.2; recusa não-verificado).
run_a2a_accept_selftests

# Modo prettierignore — idem (cenários self-contained, sem fixture-file).
run_prettierignore_selftests

# Modo scope-gitignore — escopa ignore cego de .claude/ no adotante (sinal de campo).
run_scope_gitignore_selftests

# Modo task-manager-hook — hook lê ambiente primeiro, .env fallback honesto (sinal de campo D2).
run_task_manager_hook_selftests
run_kg_verification_selftests
run_kg_ratchet_direction_selftests
run_kg_backlog_selftests
run_consumed_modes_selftests
run_vps_exposure_selftests
run_identifier_language_selftests
run_safe_count_selftests
run_scan_sanity_selftests
run_generator_failure_selftests
run_line_limits_selftests
run_kg_radar_integrity_selftests
run_review_verdict_selftests
run_empty_result_guard_selftests
run_review_artifact_selftests

# Modo cycle-completion — métrica de ciclos concluídos vs abandonados (D5 instrumentação,
# barato-primeiro). Classifica done/open-stale/no-signal e mantém o SEM-sinal FORA do
# denominador (o metric é honesto sobre o gap de schema do STATE.md que ele mesmo mede).
run_cycle_completion_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/cycle-completion.sh"
  if [ ! -f "${helper}" ]; then record_fail "cycle-completion" "helper ausente: ${helper}"; return; fi
  local d out
  d="$(mktemp -d)"
  mkdir -p "${d}/s-done" "${d}/s-open" "${d}/s-stale" "${d}/s-nosignal"
  printf '## NEXT\nphase: DONE (F1)\nstatus: done\n' > "${d}/s-done/STATE.md"
  printf '## NEXT\nphase: 2\nstatus: in_progress\n'  > "${d}/s-open/STATE.md"
  printf '## NEXT\nphase: 2\nstatus: in_progress\n'  > "${d}/s-stale/STATE.md"
  printf '## NEXT\n(sem campo de status)\n'          > "${d}/s-nosignal/STATE.md"
  touch -d '60 days ago' "${d}/s-stale/STATE.md" 2>/dev/null || true
  out="$(ONION_SESSIONS_DIR="${d}" bash "${helper}" --summary-json --stale-days 21 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"total":4' \
     && printf '%s' "${out}" | grep -q '"done":1' \
     && printf '%s' "${out}" | grep -q '"open_abandoned":1' \
     && printf '%s' "${out}" | grep -q '"no_signal":1' \
     && printf '%s' "${out}" | grep -q '"with_signal":3'; then
    record_pass "cycle-completion: classifica done/open-stale/no-signal + denominador exclui no-signal"
  else record_fail "cycle-completion: classificação" "esperado total4/done1/aband1/nosignal1/with3, veio: ${out}"; fi
  rm -rf "${d}"
  # (b) phase: DONE SEM linha status: → ainda conta como concluída (schema real observado)
  d="$(mktemp -d)"; mkdir -p "${d}/s"
  printf '## NEXT\nphase: DONE (F0-F6)\nphase_title: x\n' > "${d}/s/STATE.md"
  out="$(ONION_SESSIONS_DIR="${d}" bash "${helper}" --summary-json 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"done":1'; then
    record_pass "cycle-completion: phase:DONE sem status: → conta como concluída"
  else record_fail "cycle-completion: phase:DONE" "não contou phase:DONE como done: ${out}"; fi
  rm -rf "${d}"
}
run_cycle_completion_selftests

# Modo federation-engagement — sinal 4 (ativo/dormente por membro; proxy doc-bridge).
run_federation_engagement_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/federation-engagement.sh"
  if [ ! -f "${helper}" ]; then record_fail "federation-engagement" "helper ausente"; return; fi
  local d out today old
  d="$(mktemp -d)"
  mkdir -p "${d}/outbox/m-active/_processed" "${d}/outbox/m-dormant/_processed"
  printf 'members:\n  - id: onion-evolve\n  - id: m-active\n  - id: m-dormant\n  - id: m-never\n' > "${d}/members.yaml"
  today="$(date +%F)"; old="$(date -d '90 days ago' +%F 2>/dev/null || echo 2000-01-01)"
  : > "${d}/outbox/m-active/_processed/${today}-x.md"
  : > "${d}/outbox/m-dormant/_processed/${old}-y.md"
  out="$(ONION_FED_DIR="${d}" bash "${helper}" --summary-json --dormant-days 30 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"members":3' \
     && printf '%s' "${out}" | grep -q '"active":1' \
     && printf '%s' "${out}" | grep -q '"dormant":1' \
     && printf '%s' "${out}" | grep -q '"never":1'; then
    record_pass "federation-engagement: active/dormant/never + exclui o core"
  else record_fail "federation-engagement" "esperado members3/active1/dormant1/never1, veio: ${out}"; fi
  rm -rf "${d}"
}
run_federation_engagement_selftests

# Modo context-freshness-metric — sinal 2 (camada determinística: carimbo ≤ threshold).
run_context_freshness_metric_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/context-freshness-metric.sh"
  if [ ! -f "${helper}" ]; then record_fail "context-freshness-metric" "helper ausente"; return; fi
  local d out today old
  d="$(mktemp -d)"
  mkdir -p "${d}/bc" "${d}/tc" "${d}/cc"
  today="$(date +%F)"; old="$(date -d '3 years ago' +%F 2>/dev/null || echo 2000-01-01)"
  printf -- '---\ndate: %s\n---\n# doc atual\n' "${today}" > "${d}/bc/a.md"
  printf '# doc velho\n\n**Última Atualização:** %s\n' "${old}" > "${d}/tc/b.md"
  printf '# doc sem carimbo\n(nada)\n' > "${d}/cc/c.md"
  out="$(ONION_CONTEXT_DIRS="${d}/bc ${d}/tc ${d}/cc" bash "${helper}" --summary-json --months 18 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"docs":3' \
     && printf '%s' "${out}" | grep -q '"current":1' \
     && printf '%s' "${out}" | grep -q '"stale":1' \
     && printf '%s' "${out}" | grep -q '"no_stamp":1'; then
    record_pass "context-freshness-metric: current/stale/no-stamp + denominador exclui no-stamp"
  else record_fail "context-freshness-metric" "esperado docs3/current1/stale1/nostamp1, veio: ${out}"; fi
  rm -rf "${d}"
}
run_context_freshness_metric_selftests

# Modo session-velocity — sinal 3 (duração de sessão via ledger de ciclo-de-vida).
# Cobre: beacon down apenda o ledger (só timestamps); opt-in (sem ledger tracked → não
# cria); e o read do ledger → mediana. O ledger é a promoção de timestamps a tracked
# que destrava a velocidade (as sessões seguem gitignored por desenho).
run_session_velocity_selftests() {
  local vel="${REPO_ROOT}/.claude/validation/session-velocity.sh"
  local sb="${REPO_ROOT}/.claude/validation/session-beacon.sh"
  if [ ! -f "${vel}" ] || [ ! -f "${sb}" ]; then record_fail "session-velocity" "script ausente"; return; fi
  local d out led started
  # (a) beacon down apenda o ledger (só quando o ledger existe = opt-in por trackear) + remove beacon.
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude/beacons"
  : > "${d}/.claude/session-lifecycle.jsonl"
  started=$(( $(date +%s) - 3600 ))
  printf 'session_id: s1\nbranch: feat/x\nstarted_at: %s\nrefreshed_at: %s\n' "${started}" "$(date +%s)" > "${d}/.claude/beacons/s1.beacon"
  bash "${sb}" down "${d}" s1 >/dev/null 2>&1
  if grep -q '"session_id":"s1"' "${d}/.claude/session-lifecycle.jsonl" 2>/dev/null \
     && grep -qE '"duration_s":3[0-9]{3}' "${d}/.claude/session-lifecycle.jsonl" 2>/dev/null \
     && [ ! -f "${d}/.claude/beacons/s1.beacon" ]; then
    record_pass "session-velocity: beacon down apenda ledger (só timestamps) + remove beacon"
  else record_fail "session-velocity: ledger-append" "down não apendou o ledger"; fi
  rm -rf "${d}"
  # (a2) SEM ledger tracked → down NÃO cria (opt-in, não vaza timestamps sem consentimento de trackear).
  d="$(mktemp -d)"; git -C "${d}" init -q; mkdir -p "${d}/.claude/beacons"
  printf 'session_id: s2\nstarted_at: 0\nrefreshed_at: 1\n' > "${d}/.claude/beacons/s2.beacon"
  bash "${sb}" down "${d}" s2 >/dev/null 2>&1
  if [ ! -f "${d}/.claude/session-lifecycle.jsonl" ]; then
    record_pass "session-velocity: sem ledger tracked → down não cria (opt-in)"
  else record_fail "session-velocity: opt-in" "criou ledger sem opt-in"; fi
  rm -rf "${d}"
  # (b) velocity lê o ledger → mediana.
  led="$(mktemp)"
  printf '{"duration_s":3600}\n{"duration_s":7200}\n{"duration_s":1800}\n' > "${led}"
  out="$(ONION_LIFECYCLE_LEDGER="${led}" bash "${vel}" --summary-json 2>/dev/null)"
  if printf '%s' "${out}" | grep -q '"sessions":3' && printf '%s' "${out}" | grep -q '"median_seconds":"3600"'; then
    record_pass "session-velocity: lê ledger → mediana correta"
  else record_fail "session-velocity: mediana" "esperado sessions3/median3600, veio: ${out}"; fi
  rm -f "${led}"
}
run_session_velocity_selftests

# Modo githook — idem (hook nativo Onion; cenários self-contained em mktemp).
run_githook_selftests
run_regen_baselines_selftests
run_regen_ensure_from_selftests
run_seed_adoption_graph_selftests

# Modo assemble-plugin — idem (empacota vertical Design como plugin; dest em mktemp).
# Core-only: já pula gracioso sem plugins/ (ver função). O `|| true` é rede de segurança —
# um abort imprevisto sob set -e jamais esconde os modos self-contained seguintes (de-id).
run_assemble_plugin_selftests || true
run_marketplace_generate_selftests || true
run_bootstrap_vertical_selftests || true
run_scaffold_book_selftests || true
run_scaffold_diagnose_selftests || true

# Modo plugins-sync — drift-guard (REGRA 19): committed bate com a regeneração da fonte.
run_plugins_sync_selftests || true

# Modo capability — Capability Contract (REGRA 20): contrato honesto + resolução de requires.
run_capability_selftests

# Modo role-bundle — mapa role→bundle (REGRA 37): resolver + consistência dos verticais.
run_role_bundle_selftests

# Modo graph — lente sócio-técnica (REGRA 21): graph.md em-sync + determinismo + atores + impacto.
run_graph_selftests

# Modo design-tokens — idem (cenários self-contained, sem fixture-file).
run_design_tokens_selftests

# Modo co-relay — idem (carteiro upstream; adotante+core em mktemp, sem fixture-file).
run_corelay_selftests

# Modo co-deliver — carteiro downstream (resolução local_path do members.yaml; sinal 2026-07-10).
run_codeliver_selftests

# Modo de-identification — baseline determinístico (adapter regex da abstração SDAAL): redação + round-trip + no-op + determinismo.
run_de_identification_selftests

# Modo trust-topology — topologia de confiança RFC-0003 (regressão FED-2-0 + modos de falha; sandbox via --repo).
run_trust_topology_selftests

# Modo onion-version — detecção de papel source/adopted via stamp (regressão FED-3-1; repo temp).
run_onion_version_selftests

# Modo pin-integrity — pin do stamp é hipótese: guard do /meta:adopt --update (incidente de campo 06-30; sandbox git).
run_pin_integrity_selftests

# Modo session-beacon — farol de sessão: I3 inclui sessões vivas (colisão W1×W2 de 2026-07-02; sandbox git).
run_session_beacon_selftests

# Modo constellation-map — 🗺️ o MAPA da Constelação de Estudos (Fase 1): só-metadados, presença por worktree (sandbox git).
run_constellation_map_selftests

# Modo mail-hook — "you have mail" + gatilho de reflexão ⏰ (motd silencioso, 3 sinais, exit 0; sandbox).
run_mail_hook_selftests

# Modo diary-crumbs — estrutura de decisão da migalha: conflict_class/valid_when (enabler breadcrumbs 2026-07; sandbox).
run_diary_crumbs_selftests

# Modo outbox-channel — REGRA 28 do lint: anúncio em staging p/ membro SEM canal de recepção (achado 2026-07-19; sandbox).
run_outbox_channel_selftests

# Modo kg-coverage — REGRA 29: gate de proveniência INVERTIDO com catraca (sinal de um adotante regulado 2026-07-20).
run_kg_coverage_selftests

# Modo doctrine-freshness — REGRA 42: gate de FRESCOR DOUTRINÁRIO com catraca (irmão temporal da 29; world-sync 2026-07-20/23).
run_doctrine_freshness_selftests

# Modo kg-born-marker — REGRA 43: integridade do marcador kg: (proveniência virada p/ DENTRO; radar sub-usado, maestro 2026-07-23).
run_kg_born_marker_selftests

# Modo ladder-integrity — REGRA 44: integridade da escada de Automação Graduada (rung-jump sem prova = HARD; máxima do maestro 2026-07-24).
run_ladder_integrity_selftests() {
  local h="${REPO_ROOT}/.claude/validation/ladder-integrity-check.sh"
  if [ ! -f "${h}" ]; then record_fail "ladder-integrity" "helper ausente: ${h}"; return; fi
  if bash "${h}" --selftest >/dev/null 2>&1; then
    record_pass "ladder-integrity: escada — 8 casos (incl. mutation AUTO-sem-prova reprova; role-guard: promoted_by core-privado tolera no adotante, reprova no core)"
  else
    record_fail "ladder-integrity: escada" "o selftest embutido do helper falhou"
  fi
}
run_ladder_integrity_selftests

# Modo kb-vendored-link — REGRA 45: link vendorizado não aponta caminho core-privado (catraca; guard core-side do bug de campo de adotante real).
run_kb_vendored_link_selftests() {
  local h="${REPO_ROOT}/.claude/validation/kb-vendored-link-check.sh"
  if [ ! -f "${h}" ]; then record_fail "kb-vendored-link" "helper ausente: ${h}"; return; fi
  if bash "${h}" --selftest >/dev/null 2>&1; then
    record_pass "kb-vendored-link: 6 casos (incl. .claude/diary reprova, .claude/skills vendorizado ignora, baseline tolera, catraca)"
  else
    record_fail "kb-vendored-link" "o selftest embutido do helper falhou"
  fi
}
run_kb_vendored_link_selftests

# ---------------------------------------------------------------------------
# O harness testando a SI MESMO — os três desfechos não podem colapsar em dois
#
# Origem: sinal de campo 2026-07-25 (adotante). Um runner que só distingue "lançar" de
# "não lançar" soma o `skip` em `passed`; um ambiente sem o serviço produz o MESMO
# "N passed" de um ambiente saudável. Aqui isso valia para 32 sítios.
#
# O aceite de uma guarda nascida de auditoria não é "roda e passa" — é "ela pega o caso
# que a motivou?" (architecture-challenges.md §1.3). O caso é a REINTRODUÇÃO do skip-como-
# ✓, e (a) o pega POR CONSTRUÇÃO: guard de tooling na mesma linha de record_pass reprova.
# ---------------------------------------------------------------------------

run_selftest_outcomes_selftests() {
  local me="${SCRIPT_DIR}/lint-selftest.sh"
  [ -f "${me}" ] || { record_fail "selftest-outcomes" "não achei a mim mesmo: ${me}"; return; }
  local n out rc block

  # (a) ANTI-DRIFT: nenhum guard de tooling/import pode registrar record_pass.
  n="$(grep -cE '(command -v [a-z0-9]+|import yaml)[^#]*record_pass' "${me}" || true)"
  if [ "${n}" = 0 ]; then
    record_pass "selftest-outcomes: (a) nenhum guard de tooling soma em ✓ (skip-como-passe não volta)"
  else record_fail "selftest-outcomes: (a) anti-drift" "${n} guard(s) de tooling registram record_pass — falso-verde por vacuidade reintroduzido"; fi

  # (b) o terceiro desfecho tem CONTADOR PRÓPRIO (não é apelido de record_pass).
  if grep -q '^record_skip()' "${me}" && grep -q 'SKIP=\$((SKIP + 1))' "${me}"; then
    record_pass "selftest-outcomes: (b) record_skip existe com contador próprio"
  else record_fail "selftest-outcomes: (b)" "record_skip ausente ou sem contador próprio"; fi

  # (c) FUNCIONAL — extrai o trio real de record_* e confere a aritmética: ⊘ nunca vira ✓.
  block="$(sed -n '/^record_pass()/,/^record_skip()/p' "${me}")"
  out="$(bash -c 'PASS=0; FAIL=0; SKIP=0; FAILED_CASES=(); SKIPPED_CASES=()
'"${block}"'
record_skip a >/dev/null; record_skip b >/dev/null; record_pass c >/dev/null
printf "%s/%s" "${PASS}" "${SKIP}"' 2>/dev/null || true)"
  if [ "${out}" = "1/2" ]; then
    record_pass "selftest-outcomes: (c) 2 skips + 1 pass ⇒ PASS=1 SKIP=2 (⊘ não soma em ✓)"
  else record_fail "selftest-outcomes: (c) aritmética" "esperava PASS/SKIP='1/2', veio '${out}'"; fi

  # (d)+(e) FUNCIONAL — o bloco REAL de sumário, com contadores forjados.
  block="$(sed -n '/^echo "=== Sumário do auto-teste de guardas ==="/,$p' "${me}")"
  # (d) STRICT=1 + skip ⇒ exit 1 (asserção de capacidade — o modo do CI).
  rc=0; out="$(bash -c 'PASS=3; FAIL=0; SKIP=2; FAILED_CASES=(); SKIPPED_CASES=(x y); STRICT=1
'"${block}"'' 2>&1)" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'FALHOU (STRICT)'; then
    record_pass "selftest-outcomes: (d) STRICT=1 + skip ⇒ exit 1 (CI não aceita 'não verifiquei')"
  else record_fail "selftest-outcomes: (d) strict" "esperava exit 1 + 'FALHOU (STRICT)'; rc=${rc} out=${out}"; fi

  # (e) sem STRICT ⇒ exit 0, MAS os pulados aparecem: gracioso não pode ser silencioso.
  rc=0; out="$(bash -c 'PASS=3; FAIL=0; SKIP=2; FAILED_CASES=(); SKIPPED_CASES=(x y); STRICT=0
'"${block}"'' 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'NÃO VERIFICADOS' \
     && printf '%s' "${out}" | grep -q 'Pularam  : 2'; then
    record_pass "selftest-outcomes: (e) sem STRICT ⇒ exit 0 com os ⊘ VISÍVEIS (gracioso ≠ silencioso)"
  else record_fail "selftest-outcomes: (e) visibilidade" "esperava exit 0 + contagem/lista de pulados; rc=${rc} out=${out}"; fi

  # (f) ISOLAMENTO DO ENV DE HOOK. `git commit` exporta GIT_DIR/GIT_INDEX_FILE; herdados,
  # envenenam toda sandbox git da suíte (medido: abort no caso 93 de 472, anunciado pelo
  # hook como "falhou"). Usa o preâmbulo REAL do script, com GIT_DIR envenenado.
  local pre; pre="$(grep -m1 '^unset GIT_DIR' "${me}")"
  if [ -z "${pre}" ]; then
    record_fail "selftest-outcomes: (f) env de hook" "o preâmbulo 'unset GIT_DIR …' sumiu — o pre-commit volta a abortar no meio"
  elif (cd "${REPO_ROOT}" && GIT_DIR=/nao/existe GIT_INDEX_FILE=/nao/existe \
        bash -c "${pre}"'; git rev-parse --show-toplevel' >/dev/null 2>&1); then
    # (MUT) sem o unset, o MESMO comando tem de quebrar — senão o teste não prova nada.
    if (cd "${REPO_ROOT}" && GIT_DIR=/nao/existe GIT_INDEX_FILE=/nao/existe \
        git rev-parse --show-toplevel >/dev/null 2>&1); then
      record_fail "selftest-outcomes: (f) MUT" "GIT_DIR envenenado NÃO quebra o git — o caso (f) é vacuidade, não prova"
    else
      record_pass "selftest-outcomes: (f) env de hook neutralizado + (MUT) sem o unset o git quebra — a guarda é load-bearing"
    fi
  else record_fail "selftest-outcomes: (f) env de hook" "GIT_DIR envenenado sobrevive ao preâmbulo"; fi
}
run_selftest_outcomes_selftests
run_shell_pipefail_robustness_selftests
run_aside_router_selftests

# Modo kg-view — REGRA 31: lente derivada, determinística e em paridade com o motor.
run_vendor_scrub_selftests
run_moat_boundary_selftests
run_materialize_repo_selftests
run_plugin_hooks_json_selftests
run_projection_name_selftests
run_kg_reverify_schema_selftests() {
  # WIRE-IN 2026-08-13 (Elenxo de mecanismos, P5): o kg-reverify-schema-check.sh nasceu em
  # 2026-08-12 com selftest embutido (6 casos) e ZERO consumidores — o autor da guarda contra
  # guardas-órfãs a deixou órfã. "Sem consumidor = falta ligar, não licença para apagar."
  local chk="${REPO_ROOT}/.claude/validation/kg-reverify-schema-check.sh"
  [ -f "${chk}" ] || { record_skip "kg-reverify-schema: script ausente"; return; }
  # (a) selftest embutido — ASSERINDO O PLACAR, não só o rc (Elenxo 2026-08-13/B2: "6/6" era
  #     string livre nunca conferida; um 7º caso deixaria a bancada anunciando número morto).
  local st_out
  st_out="$(bash "${chk}" --selftest 2>&1)" || true
  if printf '%s\n' "${st_out}" | grep -qE '^[0-9]+/[0-9]+ ' && ! printf '%s\n' "${st_out}" | grep -q '✗'; then
    record_pass "kg-reverify-schema: selftest embutido verde ($(printf '%s' "${st_out}" | grep -oE '^[0-9]+/[0-9]+' | tail -1))"
  else
    record_fail "kg-reverify-schema: selftest" "reprovou ou não somou — rode bash ${chk} --selftest"
  fi
  # (b) o schema real do repo está conforme
  if bash "${chk}" >/dev/null 2>&1; then
    record_pass "kg-reverify-schema: o KgReverifySchema real está estruturalmente conforme"
  else
    record_fail "kg-reverify-schema: schema real" "o schema embarcado em kg-freshness.md reprova — rode bash ${chk}"
  fi
  # (c) MUTANTE DE PRODUÇÃO (Elenxo 2026-08-13/M5): (a)+(b) provam que o verde passa — nunca que a
  #     guarda ACUSA no caminho real ("o oposto de acusar-sem-medir não é absolver-sem-medir",
  #     doutrina do próprio consumed-mode-check). Monta uma árvore mínima com um kg-freshness.md
  #     SABOTADO (required duplicado — o defeito fundador de 2026-08-12) e exige a violação.
  local mroot
  mroot="$(mktemp -d)"
  mkdir -p "${mroot}/.claude/commands/meta" "${mroot}/.claude/validation"
  cp "${chk}" "${mroot}/.claude/validation/"
  printf '```javascript\nconst KgReverifySchema = {\n  type: "object",\n  required: ["node_id"],\n  properties: { node_id: { type: "string" } },\n  allOf: [\n    { if: { required: ["verdict"], properties: {} },\n      then: { required: ["blocked_by"], properties: {} } },\n  ],\n  required: ["claims_total"],\n};\n```\n' > "${mroot}/.claude/commands/meta/kg-freshness.md"
  local m_out m_rc=0
  m_out="$(bash "${mroot}/.claude/validation/kg-reverify-schema-check.sh" 2>&1)" || m_rc=$?
  rm -rf "${mroot}"
  if [ "${m_rc}" -eq 1 ] && printf '%s\n' "${m_out}" | grep -q "REQUIRED-DUPLICADO"; then
    record_pass "kg-reverify-schema: MUTANTE (required duplicado) é ACUSADO no caminho de produção"
  else
    record_fail "kg-reverify-schema: mutante" "required duplicado NÃO foi acusado (rc=${m_rc}) — a guarda absolve sem medir"
  fi
}

run_hook_autofix_selftests() {
  # CATRACA DO AUTO-FIX DO PRE-COMMIT (parecer do CI no PR #590: guard alterada/criada SEM fixture
  # automatizada — commands.md §11; os repros eram manuais e não sobreviviam ao próximo commit).
  # Roda os blocos REAIS do hook (extraídos por sed do arquivo vivo — não uma cópia que envelhece)
  # dentro de um CLONE LOCAL descartável, porque o hook precisa de git e o SANDBOX da bancada não é repo.
  local hook="${REPO_ROOT}/.githooks/pre-commit"
  [ -f "${hook}" ] || { record_skip "hook-autofix: pre-commit ausente"; return; }
  grep -q "AUTO-REGENERAÇÃO DE PLUGINS" "${hook}" || { record_skip "hook-autofix: bloco ausente do hook"; return; }
  local hc; hc="$(mktemp -d)"
  # clone local raso: hardlinks, ~1-2s; working tree completa para o assemble ler
  if ! git clone --quiet --local --no-hardlinks --depth 1 "file://${REPO_ROOT}" "${hc}/repo" 2>/dev/null; then
    record_skip "hook-autofix: clone local falhou"; rm -rf "${hc}"; return
  fi
  local blk="${hc}/blk.sh"
  { echo 'set -euo pipefail'; echo 'REPO_ROOT="$(git rev-parse --show-toplevel)"'
    sed -n '/AUTO-REGENERAÇÃO DE PLUGINS COM RASTRO/,/^fi$/p' "${hook}"; echo 'echo BLOCO_FIM'; } > "${blk}"
  local out
  # (a) entrada-DIRETÓRIO dispara (o repro que a v1 do auto-fix NÃO cobria — 43% das fontes)
  ( cd "${hc}/repo" && printf '\n<!-- catraca-dir -->\n' >> .claude/commands/engineer/plan.md \
    && git add .claude/commands/engineer/plan.md ) >/dev/null 2>&1
  out="$(cd "${hc}/repo" && bash "${blk}" 2>&1)" || true
  if printf '%s\n' "${out}" | grep -q "onion-engineering" && printf '%s\n' "${out}" | grep -q "BLOCO_FIM"; then
    record_pass "hook-autofix: (a) fonte em entrada-DIRETÓRIO dispara a regeneração (a cegueira da v1 não volta)"
  else
    record_fail "hook-autofix: (a) entrada-dir" "não regenerou — o matcher regrediu para grep textual?"
  fi
  ( cd "${hc}/repo" && git checkout -q -- . && git reset -q ) >/dev/null 2>&1
  # (b) GIT_INDEX_FILE temporário PULA com aviso (o revert-fantasma do commit-por-pathspec não volta)
  ( cd "${hc}/repo" && printf '\n<!-- x -->\n' >> .claude/commands/meta/kg.md && git add .claude/commands/meta/kg.md ) >/dev/null 2>&1
  out="$(cd "${hc}/repo" && GIT_INDEX_FILE=".git/next-index-999.lock" bash "${blk}" 2>&1)" || true
  if printf '%s\n' "${out}" | grep -q "PULADO" && ! printf '%s\n' "${out}" | grep -q "🔁"; then
    record_pass "hook-autofix: (b) índice temporário pula com aviso (sem revert fantasma)"
  else
    record_fail "hook-autofix: (b) índice temporário" "não pulou — o gate por GIT_INDEX_FILE sumiu?"
  fi
  ( cd "${hc}/repo" && git checkout -q -- . && git reset -q ) >/dev/null 2>&1
  # (c) staging PARCIAL de fonte casada ABORTA (o vazamento de WIP não volta)
  ( cd "${hc}/repo" && printf '\n<!-- staged -->\n' >> .claude/commands/meta/kg.md \
    && git add .claude/commands/meta/kg.md && printf '\n<!-- unstaged -->\n' >> .claude/commands/meta/kg.md ) >/dev/null 2>&1
  local rc_c=0
  out="$(cd "${hc}/repo" && bash "${blk}" 2>&1)" || rc_c=$?
  if [ "${rc_c}" -ne 0 ] && printf '%s\n' "${out}" | grep -q "ABORTADO"; then
    record_pass "hook-autofix: (c) staging parcial aborta com instrução (WIP não vaza para o plugin)"
  else
    record_fail "hook-autofix: (c) staging parcial" "não abortou (rc=${rc_c}) — o assemble publicaria WIP não-staged"
  fi
  # (d) R19 alterada: assemble FALHO acusa E SOMA (era morte rc=2 sem sumário)
  ( cd "${hc}/repo" && rm -rf .claude/skills/onion-orchestration ) >/dev/null 2>&1
  out="$(cd "${hc}/repo" && bash .claude/validation/lint-artifacts.sh --only="${hc}/repo/.claude/utils/marketplace/verticals/onion-work-tools.manifest.sh" 2>&1)" || true
  if printf '%s\n' "${out}" | grep -q "assemble FALHOU" && printf '%s\n' "${out}" | grep -q "Sumário"; then
    record_pass "hook-autofix: (d) assemble falho vira violation E o lint soma (morte silenciosa não volta)"
  else
    record_fail "hook-autofix: (d) assemble falho" "não acusou ou não somou — a R19 regrediu para morte rc=2?"
  fi
  rm -rf "${hc}"
}

# Deploy do site (ops/deploy-site.sh) — a bancada dele é embutida (--selftest, sandbox
# em mktemp, sem sudo, nunca toca fonte/webroot reais). Nasceu da revisão adversarial do
# PR #671 (R9: "nada invoca o mecanismo"): os casos são os ataques que REFUTARAM as
# guardas (symlink-no-topo alcançava mini/, fonte vazia apagava o vivo com veredito
# verde, quick-check do rsync pulava arquivo alterado no mesmo segundo).
run_deploy_site_selftests() {
  local ds="${REPO_ROOT}/ops/deploy-site.sh"
  if [ ! -f "${ds}" ]; then record_skip "deploy-site: ops/deploy-site.sh ausente"; return; fi
  command -v rsync >/dev/null 2>&1 || { record_skip "deploy-site: rsync ausente (skip gracioso)"; return; }
  local rc=0 out
  out="$(bash "${ds}" --selftest 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "deploy-site: bancada sandbox verde ($(printf '%s' "${out}" | grep -o '[0-9]* pass' | head -1))"
  else
    record_fail "deploy-site: --selftest" "rc=${rc}: $(printf '%s' "${out}" | grep '✗' | head -3)"
  fi
}

# Install da config do Caddy (ops/install-caddy-config.sh) — bancada embutida (--selftest,
# sandbox mktemp, stubs de caddy/systemctl, sem sudo, nunca toca /etc nem recarrega). Os
# casos são as guardas: validate-falha-não-toca, backup-criado, idempotência, drift-acusa,
# reload-falha-faz-rollback, fonte-ausente-die. Nasceu de o Caddyfile viver só na VPS (2026-08-26).
run_install_caddy_config_selftests() {
  local cs="${REPO_ROOT}/ops/install-caddy-config.sh"
  if [ ! -f "${cs}" ]; then record_skip "install-caddy-config: ops/install-caddy-config.sh ausente"; return; fi
  local rc=0 out
  out="$(bash "${cs}" --selftest 2>&1)" || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "install-caddy-config: bancada sandbox verde ($(printf '%s' "${out}" | grep -o '[0-9]* pass' | head -1))"
  else
    record_fail "install-caddy-config: --selftest" "rc=${rc}: $(printf '%s' "${out}" | grep '✗' | head -3)"
  fi
}

# /meta:realign — o motor de revisão em camadas (kg-realign-project.sh) classifica drift
# em (a)/(b)/(c) + commitment/binding sobre fixtures com um drift plantado de cada tipo.
# GUARDA-DA-GUARDA: o `--check` só sai rc=1 no tipo-(c) (o dente); os demais informam sem bloquear.
run_realign_selftests() {
  local rs="${REPO_ROOT}/.claude/validation/kg-realign-project.sh"
  local fx="${REPO_ROOT}/.claude/validation/fixtures/kg-realign"
  if [ ! -f "${rs}" ]; then record_skip "realign: kg-realign-project.sh ausente"; return; fi
  if [ ! -d "${fx}" ]; then record_skip "realign: fixtures/kg-realign ausente"; return; fi
  # caso: nome-da-fixture | substring esperada na linha --check | rc esperado
  local -a cases=(
    "clean|ALINHADO: (c)=0 (b)=0 (a)=0 · commit=0 bind=0|0"
    "drift-c-unreconciled|REALINHAR: (c)=1|1"
    "drift-b-costly|(b)=1|0"
    "drift-a-benign|(a)=1|0"
    "drift-northstar|commit=1 bind=1|0"
    "bind-fp-supported-decision|bind=0|0"
  )
  local c name want wantrc rc out f
  for c in "${cases[@]}"; do
    name="${c%%|*}"; c="${c#*|}"; want="${c%|*}"; wantrc="${c##*|}"
    f="${fx}/${name}.kg.yaml"
    if [ ! -f "${f}" ]; then record_fail "realign: fixture ${name}" "fixture ausente: ${f}"; continue; fi
    rc=0; out="$(bash "${rs}" "${f}" --check 2>&1)" || rc=$?
    if [ "${rc}" != "${wantrc}" ]; then
      record_fail "realign: ${name} (rc)" "esperava rc=${wantrc}, veio rc=${rc}: ${out}"; continue
    fi
    if printf '%s' "${out}" | grep -qF "${want}"; then
      record_pass "realign: ${name} classifica e sela (rc=${rc})"
    else
      record_fail "realign: ${name} (classificação)" "esperava '${want}' em: ${out}"
    fi
  done
}

# /meta:drive — o CENSO (kg-drive-project.sh) projeta a FILA-PRONTA de um plano-grafo:
# nós open com predecessores DEPENDS_ON fechados. GUARDA-DA-GUARDA: o `--check` só sai rc=1
# no DEADLOCK (há aberto mas fila-pronta vazia). Inclui a regressão do bug do --open-tsv VAZIO.
# ---------------------------------------------------------------------------
# REGRA 62 — projeção gerada em sincronia (docs/backlog.md). A guarda nasceu de dano
# medido: uma migalha ficou INVISÍVEL numa projeção e o lint passou verde (PR #700/#701).
# Os casos cobrem os modos de falha, não só o happy-path — inclusive os dois que eu
# quase enviei: escrita silenciosa por arg desconhecido, e render não-reproduzível.
# Usa `--only=` para escopar a varredura (a regra é de par-fixo e roda mesmo assim):
# 5s por passada em vez de minutos, sem perder o que se afirma medir.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# REGRA 63 — colheita nomeia o que apagou. Nasceu do Elenxo de 2026-08-29: o `meta:` do
# fios-abertos promete que a história fica "no git E no artefato de revisão"; o git cumpre,
# o resíduo não — o da colheita de 28/08 nomeia 2 ids (os preservados) e ZERO dos 18
# apagados, e 14 dos 18 conceitos não existem hoje em nenhum artefato consultável.
# Os três casos são os três estados reais: sem resíduo · resíduo parcial · resíduo completo.
# ---------------------------------------------------------------------------

run_compose_exposure_selftests() {
  # REGRA 64 — bancada AUTO-CONTIDA (lição da fixture-viva, censo 2026-08-30): sandbox git
  # próprio + função extraída do lint VIVO por awk (o padrão da bancada da R46 — não uma cópia
  # que envelhece) + violation() stub que conta.
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  [ -f "${lint}" ] || { record_skip "compose-exposure: lint ausente"; return; }
  local d; d="$(mktemp -d)"
  ( cd "$d" && git init -q ) || { record_fail "compose-exposure: sandbox" "git init falhou"; rm -rf "$d"; return; }
  awk '/^check_compose_exposure\(\)/,/^}/' "${lint}" > "$d/f.sh"
  if ! grep -q 'check_compose_exposure' "$d/f.sh"; then
    record_fail "compose-exposure: extração" "a função sumiu do lint — a guarda foi removida?"; rm -rf "$d"; return
  fi
  cat > "$d/docker-compose.yml" <<'FIX'
services:
  db:
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres123}
    ports:
      - 5435:5432
      - 127.0.0.1:8080:80
FIX
  ( cd "$d" && git add -A )
  local out
  out="$(cd "$d" && REPO_ROOT="$d" bash -c 'violation(){ echo "V[$1] $2 :: $3"; }; source f.sh; check_compose_exposure' 2>&1)" || true
  local n_port n_fall
  n_port="$(printf '%s\n' "${out}" | grep -c 'SEM prefixo de bind' || true)"
  n_fall="$(printf '%s\n' "${out}" | grep -c 'FALLBACK LITERAL' || true)"
  if [ "${n_port}" -eq 1 ] && [ "${n_fall}" -eq 1 ]; then
    record_pass "compose-exposure: acusa porta sem bind E fallback de segredo (1+1); o 127.0.0.1 cala"
  else
    record_fail "compose-exposure: acusação" "esperava 1+1; veio porta=${n_port} fallback=${n_fall}: $(printf '%s' "${out}" | head -2)"
  fi
  sed -i 's|- 5435:5432|- 127.0.0.1:5435:5432|; s|${DB_PASSWORD:-postgres123}|${DB_PASSWORD:?defina}|' "$d/docker-compose.yml"
  ( cd "$d" && git add -A )
  out="$(cd "$d" && REPO_ROOT="$d" bash -c 'violation(){ echo "V[$1] $2 :: $3"; }; source f.sh; check_compose_exposure' 2>&1)" || true
  if printf '%s\n' "${out}" | grep -q 'REGRA 64'; then
    record_fail "compose-exposure: falso-positivo" "compose curado ainda acusa"
  else
    record_pass "compose-exposure: compose curado passa limpo"
  fi
  printf 'services:\n  x:\n    ports:\n      - 9999:9999\n' > "$d/docker-compose.dev.yml"
  out="$(cd "$d" && REPO_ROOT="$d" bash -c 'violation(){ echo "V[$1] $2 :: $3"; }; source f.sh; check_compose_exposure' 2>&1)" || true
  if printf '%s\n' "${out}" | grep -q '9999'; then
    record_fail "compose-exposure: escopo" "UNTRACKED foi acusado — escopo declarado é git ls-files"
  else
    record_pass "compose-exposure: untracked fica fora (rascunho não é artefato)"
  fi
  # CATRACA: o que o EMISSOR emite, o lint TOLERA (paridade por execução — a receita da chave
  # vive em dois sítios e esta é a guarda que os mantém iguais); linha NOVA segue HARD.
  sed -i 's|- 127.0.0.1:5435:5432|- 5435:5432|' "$d/docker-compose.yml"   # reintroduz a dívida
  ( cd "$d" && git add -A )
  ( cd "$d" && REPO_ROOT="$d" bash "${REPO_ROOT}/.claude/validation/compose-exposure-check.sh" --emit-baseline > .claude-baseline.txt 2>/dev/null ) || true
  mkdir -p "$d/.claude/validation" && mv "$d/.claude-baseline.txt" "$d/.claude/validation/compose-exposure-baseline.txt"
  out="$(cd "$d" && REPO_ROOT="$d" bash -c 'violation(){ echo "V[$1] $2 :: $3"; }; source f.sh; check_compose_exposure' 2>&1)" || true
  if printf '%s\n' "${out}" | grep -q 'V\[HARD\]'; then
    record_fail "compose-exposure: catraca" "dívida emitida pelo emissor AINDA sai HARD — receita de chave divergiu entre emissor e lint"
  elif printf '%s\n' "${out}" | grep -q 'toleradas pelo baseline'; then
    record_pass "compose-exposure: catraca — dívida legada tolerada (SOFT agregado), paridade emissor↔lint provada"
  else
    record_fail "compose-exposure: catraca" "nem HARD nem SOFT agregado — a guarda calou: $(printf '%s' "${out}" | head -1)"
  fi
  printf '    ports:\n      - 7777:7777\n' >> "$d/docker-compose.yml"
  ( cd "$d" && git add -A )
  out="$(cd "$d" && REPO_ROOT="$d" bash -c 'violation(){ echo "V[$1] $2 :: $3"; }; source f.sh; check_compose_exposure' 2>&1)" || true
  # a mensagem da violação carrega linha+chave, não o conteúdo — medir pelo QUE A GUARDA EMITE:
  # exatamente 1 HARD (a linha nova) com a dívida antiga ainda tolerada (SOFT agregado presente).
  local n_hard
  n_hard="$(printf '%s\n' "${out}" | grep -c 'V\[HARD\]' || true)"
  if [ "${n_hard}" -eq 1 ] && printf '%s\n' "${out}" | grep -q 'toleradas pelo baseline'; then
    record_pass "compose-exposure: linha NOVA fora do baseline segue HARD (1 exata) com o legado ainda tolerado"
  else
    record_fail "compose-exposure: crescimento" "esperava 1 HARD + SOFT agregado; veio hard=${n_hard}: $(printf '%s' "${out}" | head -2)"
  fi
  rm -rf "$d"
}

run_harvest_residue_selftests() {
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${lint}" ]; then record_skip "harvest-residue: lint ausente (SUT não exercido)"; return; fi
  local sb out
  sb="$(TMPDIR=/tmp mktemp -d)"
  # sandbox AUTO-CONTIDO: `git init` + `main` explícita. A 1a versão clonava o repo e dependia
  # de `origin/main` existir — no CI o checkout não tem `main` local, a base não resolvia, e a
  # guarda ficava MUDA: o teste falhava lá e passava aqui. Bancada que depende da topologia do
  # ambiente mede o ambiente, não o SUT.
  mkdir -p "${sb}/.claude/validation" "${sb}/docs/onion/graph" "${sb}/docs/evolution/review"
  cp "${lint}" "${sb}/.claude/validation/lint-artifacts.sh"
  cp -a "${REPO_ROOT}/.claude/validation/lib" "${sb}/.claude/validation/" 2>/dev/null || true
  printf '# stub\n' > "${sb}/CLAUDE.md"
  printf 'framework: onion-evolve\nrole: source\n' > "${sb}/.claude/.onion-version"
  cat > "${sb}/docs/onion/graph/alvo.kg.yaml" <<'KG'
meta:
  id: alvo
  schema_version: '1'
nodes:
  - id: N_PRIMEIRO
    node_type: claim
    plane: DEV
    impact: 1
    confidence: 0.5
    status: open
    label: 'primeiro'
  - id: N_SEGUNDO
    node_type: claim
    plane: DEV
    impact: 1
    confidence: 0.5
    status: open
    label: 'segundo'
edges:
  - from: N_PRIMEIRO
    to: N_SEGUNDO
    edge_type: SUPPORTS
KG
  ( cd "${sb}" && git init -q -b main && git add -A \
    && git -c user.email=t@t -c user.name=t commit -qm base ) >/dev/null 2>&1 || {
      record_skip "harvest-residue: git init falhou (cenário não montado)"; rm -rf "${sb}"; return; }

  # a colheita: remove os dois nós num ramo
  ( cd "${sb}" && git checkout -q -b test/harvest-case
    python3 - <<'PY'
import io
p='docs/onion/graph/alvo.kg.yaml'; s=io.open(p,encoding='utf-8').read()
for nid in ('N_PRIMEIRO','N_SEGUNDO'):
    i=s.index('  - id: '+nid)
    j=s.find('\n  - id: ', i+5)
    if j<0: j=s.index('\nedges:', i)
    s=s[:i]+s[j+1:]
io.open(p,'w',encoding='utf-8').write(s)
PY
    git -c user.email=t@t -c user.name=t commit -qam colheita ) >/dev/null 2>&1 || true

  # (a) SEM resíduo → HARD
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/CLAUDE.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'não há resíduo de revisão'; then
    record_pass "harvest-residue: colheita SEM resíduo → HARD"
  else record_fail "harvest-residue: sem resíduo" "a guarda não pegou colheita sem resíduo: ${out}"; fi

  # (b) resíduo PARCIAL → HARD só sobre o id não-nomeado
  printf -- '---\ntitle: x\n---\nColhi N_PRIMEIRO.\n' > "${sb}/docs/evolution/review/test-harvest-case.md"
  ( cd "${sb}" && git add -A && git -c user.email=t@t -c user.name=t commit -qam parcial ) >/dev/null 2>&1 || true
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/CLAUDE.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'colheita sem registro' && printf '%s' "${out}" | grep -q 'N_SEGUNDO' \
     && ! printf '%s' "${out}" | grep -q -- '— N_PRIMEIRO'; then
    record_pass "harvest-residue: resíduo PARCIAL → HARD só sobre o id não-nomeado"
  else record_fail "harvest-residue: parcial" "esperava HARD citando N_SEGUNDO e não N_PRIMEIRO: ${out}"; fi

  # (c) resíduo COMPLETO → cala
  printf -- '---\ntitle: x\n---\nColhi N_PRIMEIRO e N_SEGUNDO.\n' > "${sb}/docs/evolution/review/test-harvest-case.md"
  ( cd "${sb}" && git add -A && git -c user.email=t@t -c user.name=t commit -qam completo ) >/dev/null 2>&1 || true
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/CLAUDE.md" 2>&1 || true)"
  if ! printf '%s' "${out}" | grep -q 'colheita sem registro'; then
    record_pass "harvest-residue: resíduo COMPLETO → guarda cala (sem falso-positivo)"
  else record_fail "harvest-residue: completo" "falso-positivo com resíduo completo: ${out}"; fi

  # (d) SEM base resolvível → SOFT que DECLARA, nunca silêncio (o modo que matava a guarda no CI)
  local sbo
  sbo="$(TMPDIR=/tmp mktemp -d)"
  cp -a "${sb}/.claude" "${sbo}/.claude"; cp -a "${sb}/docs" "${sbo}/docs"; cp "${sb}/CLAUDE.md" "${sbo}/"
  ( cd "${sbo}" && git init -q -b solta && git add -A \
    && git -c user.email=t@t -c user.name=t commit -qm unica ) >/dev/null 2>&1 || true
  out="$(cd "${sbo}" && bash .claude/validation/lint-artifacts.sh --only="${sbo}/CLAUDE.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'REGRA 63 nao pode julgar'; then
    record_pass "harvest-residue: sem base resolvível → SOFT que DECLARA (não silêncio)"
  else record_fail "harvest-residue: sem base" "a guarda ficou MUDA sem base — é o fail-open que a matava no CI: ${out}"; fi
  rm -rf "${sbo}" "${sb}"
}





run_sdaal_workflows_selftests() {
  # Testa a FUNÇÃO com REPO_ROOT sintético (fixture fora do repo não seria varrida pelo _find
  # real — lição da 1ª redação desta própria família, 2026-09-01).
  local d; d="$(mktemp -d)"
  mkdir -p "$d/.github/workflows" "$d/.claude/commands" "$d/.claude/agents"
  printf 'name: t\njobs:\n  x:\n    steps:\n      - run: curl mcp_ClickUp_create\n' > "$d/.github/workflows/bad.yml"
  printf 'name: t\njobs:\n  x:\n    steps:\n      - run: echo ok\n' > "$d/.github/workflows/good.yml"
  local out
  out="$(bash -c '
    set -euo pipefail
    REPO_ROOT="'"$d"'"; CLAUDE_DIR="'"$d"'/.claude"; ONLY_PATH=""
    _find() { local o=(); for a in "$@"; do o+=("$a"); done; find "${o[@]}"; }
    violation() { echo "V[$1] $2 :: ${3%%$'"'"'\n'"'"'*}"; }
    source <(sed -n "/^check_no_direct_provider_calls()/,/^}$/p" "'"${SCRIPT_DIR}"'/lint-artifacts.sh")
    check_no_direct_provider_calls
  ' 2>&1)"
  if printf '%s' "${out}" | grep -q 'provider em WORKFLOW' && printf '%s' "${out}" | grep -q 'bad.yml'; then
    record_pass "sdaal-workflows: (a) provider direto em .github/workflows é HARD"
  else record_fail "sdaal-workflows: (a)" "não mordeu: ${out}"; fi
  if printf '%s' "${out}" | grep -q 'good.yml'; then
    record_fail "sdaal-workflows: (b)" "workflow limpo acusado: ${out}"
  else record_pass "sdaal-workflows: (b) workflow limpo fica em silêncio"; fi
  rm -rf "$d"
}

run_census_extract_selftests() {
  local ex="${SCRIPT_DIR}/kg-census-extract.sh"
  local d rc out; d="$(mktemp -d)"
  mkdir -p "$d/docs/onion/graph"
  # fixture sintética: 2 nós open (1 fresco de hoje, 1 velho), backlog declarando 2
  printf 'meta:\n  id: fx\nnodes:\n  - id: N_FRESCO\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 4\n    confidence: 0.9\n    verified_at: %s\n    label: "a"\n  - id: N_VELHO\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 4\n    confidence: 0.9\n    verified_at: 2026-01-01\n    label: "b"\n' "$(date +%F)" > "$d/docs/onion/graph/fx.kg.yaml"
  printf '**2 itens abertos**\n| 9.0 | `N_FRESCO` | fx | a |\n| 3.0 | `N_VELHO` | fx | b |\n' > "$d/backlog.md"
  # (a) partição correta FRESCO/A-MEDIR
  out="$(cd "$d" && ONION_CENSUS_ROOT="$d" ONION_CENSUS_BACKLOG="$d/backlog.md" bash "${ex}" --format summary 2>&1)"; rc=$?
  if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q '1 A-MEDIR' && printf '%s' "$out" | grep -q '1 FRESCOS'; then
    record_pass "census-extract: (a) partição FRESCO/A-MEDIR correta na fixture sintética"
  else record_fail "census-extract: (a)" "partição errada (rc=$rc): $out"; fi
  # (b) descompasso contagem ⇒ exit 2 fail-loud
  printf '**5 itens abertos**\n| 9.0 | `N_FRESCO` | fx | a |\n' > "$d/backlog.md"
  rc=0; out="$(cd "$d" && ONION_CENSUS_ROOT="$d" ONION_CENSUS_BACKLOG="$d/backlog.md" bash "${ex}" 2>&1)" || rc=$?
  if [ $rc -eq 2 ] && printf '%s' "$out" | grep -q 'FAIL-LOUD'; then
    record_pass "census-extract: (b) contagem divergente é exit 2 fail-loud (população errada não se mede)"
  else record_fail "census-extract: (b)" "descompasso não reprovou (rc=$rc): $out"; fi
  # (c) --floor corta e DECLARA
  printf '**2 itens abertos**\n| 9.0 | `N_FRESCO` | fx | a |\n| 3.0 | `N_VELHO` | fx | b |\n' > "$d/backlog.md"
  out="$(cd "$d" && ONION_CENSUS_ROOT="$d" ONION_CENSUS_BACKLOG="$d/backlog.md" bash "${ex}" --floor 5 --format summary 2>&1)"; rc=$?
  if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q '1 cortados pelo piso 5.0 (corte DECLARADO)'; then
    record_pass "census-extract: (c) --floor corta e o corte é DECLARADO (nunca silêncio)"
  else record_fail "census-extract: (c)" "piso sem declaração (rc=$rc): $out"; fi
  rm -rf "$d"
}

run_census_seal_selftests() {
  # (d) TIPO DA ARESTA PELA REALIDADE (2026-09-02): DRIFTED+GATED refina (CONSTRAINS, alvo open);
  # DRIFTED+MORTO supera (SUPERSEDES). Incondicional deixou 13 alvos open sob SUPERSEDES em 8 grafos.
  local seal="${REPO_ROOT}/.claude/utils/census/census-seal.py"
  local d rc out g; d="$(mktemp -d)"; mkdir -p "$d/docs/onion/graph"; g="docs/onion/graph/fx.kg.yaml"
  printf 'meta:\n  id: fx\nnodes:\n  - id: N_GATED\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 4\n    confidence: 0.9\n    verified_at: 2026-01-01\n    verified_against: x\n    label: "a"\n  - id: N_MORTO\n    node_type: question\n    plane: DEV\n    status: open\n    impact: 4\n    confidence: 0.9\n    verified_at: 2026-01-01\n    verified_against: x\n    label: "b"\n\nedges:\n  - from: N_GATED\n    to: N_MORTO\n    edge_type: SUPPORTS\n' > "$d/$g"
  python3 - "$d/c.json" "$g" <<'PY'
import json,sys
m=lambda n,r: {"node_id":n,"kg_file":sys.argv[2],"verdict":"DRIFTED","realidade":r,"gatilho_disparou":"NAO","juiz":"APROVADO","claims_total":1,"claims_measured":1,"method":"m","observed":"o","divergence":"d"}
json.dump({"run_id":"wf_fixture","medidos":[m("N_GATED","GATED"),m("N_MORTO","MORTO-CANDIDATO")],"juizo":{},"nao_medidos_por_teto":[],"parametros":{}},open(sys.argv[1],'w'))
PY
  rc=0; out="$(ONION_CENSUS_ROOT="$d" python3 "${seal}" seal "$d/c.json" 2>&1)" || rc=$?
  if [ $rc -eq 0 ] && grep -qE 'to: N_GATED\n?' "$d/$g" && awk '/to: N_GATED/{getline; print}' "$d/$g" | grep -q CONSTRAINS \
     && awk '/to: N_MORTO/{getline; print}' "$d/$g" | grep -q SUPERSEDES; then
    record_pass "census-seal: (d) DRIFTED+GATED vira CONSTRAINS (alvo segue open) e DRIFTED+MORTO vira SUPERSEDES"
  else record_fail "census-seal: (d)" "aresta pela realidade nao aplicada (rc=$rc): $out $(grep -A1 'to: N_' "$d/$g")"; fi
  rm -rf "$d"
}

run_members_registry_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  # REGRA 66 — sem depender do estado do vivo além do caso (a), que é o canário da fixture
  local rc out
  rc=0; out="$(bash "${lint}" --only=docs/evolution/federation/members.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'REGRA 66'; then
    record_fail "members-registry: (a)" "o registro VIVO reprova no gate: ${out}"
  else record_pass "members-registry: (a) o members.yaml vivo passa no gate"; fi

  # (b) registro INVÁLIDO reprova HARD nomeando o rc do validador
  local d; d="$(mktemp -d)"
  printf '# Registro de membros da co-evolução Onion (fixture)\nmembers:\n  - id: quebrado\n' > "$d/bad.yaml"
  rc=0; out="$(ONION_MEMBERS_FILE="$d/bad.yaml" bash "${lint}" --only=docs/evolution/federation/members.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'REGRA 66: registro da federação INVÁLIDO' && [ "${rc}" -ne 0 ]; then
    record_pass "members-registry: (b) registro inválido é HARD com rc do validador"
  else record_fail "members-registry: (b)" "inválido não reprovou (rc=${rc}): ${out}"; fi

  # (c) dado presente + validador AUSENTE = HARD fail-loud (nunca conformidade por ausência)
  mkdir -p "$d/fake-validation"
  cp "${lint}" "$d/fake-validation/lint-artifacts.sh" 2>/dev/null || true
  # mais barato e fiel: apontar SCRIPT_DIR falso é invasivo — em vez disso, prova por leitura:
  if grep -q 'members-validate.sh AUSENTE' "${lint}"; then
    record_pass "members-registry: (c) rota validador-ausente existe e é HARD (provada por leitura da guarda)"
  else record_fail "members-registry: (c)" "rota fail-loud de validador ausente não existe na guarda"; fi
  rm -rf "$d"
}

run_radar_staleness_selftests() {
  local lint="${SCRIPT_DIR}/lint-artifacts.sh"
  # REGRA 65 — fixtures sintéticas, ZERO dependência do arquivo vivo (lição do kg-backlog (c),
  # curada no MESMO dia em que esta família nasceu).
  local d; d="$(mktemp -d)"
  local rc out fresh_date; fresh_date="$(date +%F)"

  printf 'axes:\n  - id: EA\n    last_run: %s\n' "${fresh_date}" > "$d/fresco.yaml"
  rc=0; out="$(ONION_RADAR_BASELINES="$d/fresco.yaml" bash "${lint}" --only=docs/onion/radar-baselines.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'REGRA 65'; then
    record_fail "radar-staleness: (a)" "eixo fresco gerou violação: ${out}"
  else record_pass "radar-staleness: (a) eixo com rodada de hoje fica em silêncio"; fi

  printf 'axes:\n  - id: EB\n    last_run: 2026-01-01\n' > "$d/velho.yaml"
  rc=0; out="$(ONION_RADAR_BASELINES="$d/velho.yaml" bash "${lint}" --only=docs/onion/radar-baselines.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q "REGRA 65: eixo 'EB' do radar de mundo está VELHO"; then
    record_pass "radar-staleness: (b) eixo velho vira SOFT nomeando o eixo e a idade"
  else record_fail "radar-staleness: (b)" "eixo velho não acusado: ${out}"; fi

  printf 'axes:\n  - id: EC\n    last_run: ontem\n' > "$d/ruim.yaml"
  rc=0; out="$(ONION_RADAR_BASELINES="$d/ruim.yaml" bash "${lint}" --only=docs/onion/radar-baselines.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q "last_run ilegível" && [ "${rc}" -ne 0 ]; then
    record_pass "radar-staleness: (c) data ilegível é HARD fail-loud (rc!=0)"
  else record_fail "radar-staleness: (c)" "data ilegível não reprovou (rc=${rc}): ${out}"; fi

  printf '# vazio\n' > "$d/vazio.yaml"
  rc=0; out="$(ONION_RADAR_BASELINES="$d/vazio.yaml" bash "${lint}" --only=docs/onion/radar-baselines.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'SEM eixos legíveis' && [ "${rc}" -ne 0 ]; then
    record_pass "radar-staleness: (d) arquivo presente sem eixos é HARD (nunca conformidade por ausência)"
  else record_fail "radar-staleness: (d)" "baseline vazia passou (rc=${rc}): ${out}"; fi

  # (e) ambiente sem date -d/-j: degrade SOFT DECLARANDO "não medida" — nunca HARD no artefato
  #     (emenda do Elenxo 2026-08-31; P0 da REGRA 30). Stub de date que recusa -d e -j.
  mkdir -p "$d/bin"
  printf '#!/usr/bin/env bash\nfor a in "$@"; do case "$a" in -d|-j) exit 1;; esac; done\nexec /usr/bin/date "$@"\n' > "$d/bin/date"
  chmod +x "$d/bin/date"
  printf 'axes:\n  - id: EE\n    last_run: 2026-01-01\n' > "$d/semd.yaml"
  rc=0; out="$(PATH="$d/bin:$PATH" ONION_RADAR_BASELINES="$d/semd.yaml" bash "${lint}" --only=docs/onion/radar-baselines.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'NÃO MEDIDA neste ambiente' && ! printf '%s' "${out}" | grep -q "eixo 'EE' com data não-computável"; then
    record_pass "radar-staleness: (e) ambiente sem date -d degrada SOFT declarando 'não medida' (nunca HARD no artefato)"
  else record_fail "radar-staleness: (e)" "degradação de ambiente errada (rc=${rc}): ${out}"; fi

  # (f) gatilho de VERSÃO: cc_version da baseline ≠ binário instalado ⇒ SOFT nomeando as duas
  printf '#!/usr/bin/env bash\necho "9.9.9 (Claude Code)"\n' > "$d/bin/claude-stub"
  chmod +x "$d/bin/claude-stub"
  printf 'axes:\n  - id: E3\n    last_run: %s\n    cc_version: "1.0.0"\n' "${fresh_date}" > "$d/ccver.yaml"
  rc=0; out="$(ONION_CC_BIN="$d/bin/claude-stub" ONION_RADAR_BASELINES="$d/ccver.yaml" bash "${lint}" --only=docs/onion/radar-baselines.yaml 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'mudou de versão desde a última rodada de estratégia (rodada=1.0.0, instalado=9.9.9)'; then
    record_pass "radar-staleness: (f) troca de versão do Claude Code dispara SOFT de re-medição de estratégia"
  else record_fail "radar-staleness: (f)" "gatilho de versão não disparou (rc=${rc}): ${out}"; fi

  rm -rf "$d"
}

run_backlog_projection_selftests() {
  local gen="${REPO_ROOT}/.claude/validation/kg-backlog-project.sh"
  local lint="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
  if [ ! -f "${gen}" ] || [ ! -f "${lint}" ]; then
    record_skip "backlog-projection: gerador ou lint ausente (SUT não exercido)"; return
  fi
  if ! command -v iconv >/dev/null 2>&1; then
    record_skip "backlog-projection: iconv ausente nesta máquina (SUT não exercido)"; return
  fi
  local sb out rc before after
  sb="$(mktemp -d)"
  cp -a "${REPO_ROOT}/.claude" "${sb}/.claude"
  cp -a "${REPO_ROOT}/docs"    "${sb}/docs"
  cp "${REPO_ROOT}/CLAUDE.md"  "${sb}/CLAUDE.md" 2>/dev/null || printf '# stub\n' > "${sb}/CLAUDE.md"
  # sandbox git REAL: o projetor enumera por `git ls-files`. Sem índice ele não enxerga
  # grafo nenhum — e o caso "em dia" passaria/falharia por ausência de git, não pelo SUT.
  # (Foi assim que este próprio caso reprovou na 1a rodada, e o achado virou a guarda de
  # enumeração-vazia do gerador.)
  ( cd "${sb}" && git init -q && git add -A >/dev/null 2>&1 \
    && git -c user.email=t@t -c user.name=t commit -qm seed >/dev/null 2>&1 ) || true

  # (a) EM DIA → a regra cala. Roda ANTES do drift: se já viesse sujo, o caso (b) passaria
  #     por motivo errado e nunca saberíamos.
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/CLAUDE.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'projeção desatualizada'; then
    record_fail "backlog-projection: em-dia" "acusou drift num sandbox pristino (falso-positivo): ${out}"
  else record_pass "backlog-projection: projeção em dia → regra cala"; fi

  # (b) DRIFT → HARD. O modo de falha que a guarda existe para pegar.
  printf '\nLINHA-INTRUSA-DO-SELFTEST\n' >> "${sb}/docs/backlog.md"
  out="$(cd "${sb}" && bash .claude/validation/lint-artifacts.sh --only="${sb}/CLAUDE.md" 2>&1 || true)"
  if printf '%s' "${out}" | grep -q 'projeção desatualizada vs a fonte'; then
    record_pass "backlog-projection: drift → HARD (projeção que envelhece calada)"
  else record_fail "backlog-projection: drift" "a guarda NÃO pegou o drift: ${out}"; fi

  # (c) ARG DESCONHECIDO: a asserção que importa é a NÃO-MUTAÇÃO, não o exit code — o modo
  #     de falha era `MODE="${1:---write}"` mandando um typo para o ramo de ESCRITA.
  before="$(sha256sum "${sb}/docs/backlog.md" | cut -d' ' -f1)"
  rc=0; (cd "${sb}" && bash .claude/validation/kg-backlog-project.sh --dry-run >/dev/null 2>&1) || rc=$?
  after="$(sha256sum "${sb}/docs/backlog.md" | cut -d' ' -f1)"
  if [ "${rc}" -eq 2 ] && [ "${before}" = "${after}" ]; then
    record_pass "backlog-projection: arg desconhecido → exit 2 e arquivo INTACTO (sem escrita silenciosa)"
  else record_fail "backlog-projection: arg desconhecido" "esperava rc=2 e arquivo intacto; rc=${rc} mutou=$([ "${before}" = "${after}" ] && echo nao || echo SIM)"; fi

  # (d) PARIDADE de render: `--markdown` (stdout, o que o lint compara) tem de ser
  #     byte-idêntico ao que `--write` grava. Senão a catraca compara dois renderizadores.
  ( cd "${sb}" && bash .claude/validation/kg-backlog-project.sh --markdown > "${sb}/md.out" 2>/dev/null
    bash .claude/validation/kg-backlog-project.sh --write >/dev/null 2>&1 )
  if diff -q "${sb}/md.out" "${sb}/docs/backlog.md" >/dev/null 2>&1; then
    record_pass "backlog-projection: --markdown byte-idêntico a --write (paridade de render)"
  else record_fail "backlog-projection: paridade" "--markdown diverge de --write — a catraca compararia 2 renderizadores"; fi

  # (e) SEM iconv → o gerador RECUSA em vez de emitir render não-reproduzível. Guarda que
  #     acusa o ambiente é pior que guarda nenhuma; aqui o gerador falha alto e o
  #     `_gen_into` do lint traduz isso em QUEBRA, nunca em "regenere por cima".
  local fakebin f b
  fakebin="$(mktemp -d)"
  for f in /usr/bin/* /bin/*; do
    b="$(basename "${f}")"; [ "${b}" = "iconv" ] && continue
    ln -sf "${f}" "${fakebin}/${b}" 2>/dev/null || true
  done
  if PATH="${fakebin}" command -v iconv >/dev/null 2>&1; then
    record_skip "backlog-projection: sem-iconv — não foi possível montar PATH sem iconv (cenário não montado)"
  else
    rc=0
    ( cd "${sb}" && PATH="${fakebin}" bash .claude/validation/kg-backlog-project.sh --markdown >/dev/null 2>"${sb}/ic.err" ) || rc=$?
    # casa a RAZÃO, não só o código: um exit 2 vindo da guarda de enumeração (ex.: `git`
    # faltando no PATH falso) passaria igual e o caso mediria outra coisa.
    if [ "${rc}" -eq 2 ] && grep -q 'iconv AUSENTE' "${sb}/ic.err" 2>/dev/null; then
      record_pass "backlog-projection: sem iconv → gerador RECUSA (render não-reproduzível não nasce)"
    else record_fail "backlog-projection: sem iconv" "esperava exit 2, veio ${rc} — render dependeria do ambiente"; fi
  fi

  # (f) ENUMERAÇÃO VAZIA = QUEBRA, não drift. Sem índice git o projetor enxergaria ZERO
  #     grafos e emitiria um backlog quase-vazio — não vazio o bastante para o `_gen_into`
  #     chamar de quebra, então viraria "drift" e a mensagem mandaria REGENERAR POR CIMA da
  #     projeção boa. Falha aberta que vira DESTRUTIVA; o gerador tem de recusar antes.
  local sbng
  # TMPDIR fixo: se TMPDIR apontar para dentro de um worktree git, `git rev-parse
  # --show-toplevel` resolve o ROOT para o repo HOSPEDEIRO e o --write deste caso
  # escreveria no docs/backlog.md dele — o teste vazando para fora do sandbox.
  sbng="$(TMPDIR=/tmp mktemp -d)"
  cp -a "${REPO_ROOT}/.claude" "${sbng}/.claude"
  cp -a "${REPO_ROOT}/docs"    "${sbng}/docs"
  before="$(sha256sum "${sbng}/docs/backlog.md" | cut -d' ' -f1)"
  rc=0; ( cd "${sbng}" && bash .claude/validation/kg-backlog-project.sh --write >/dev/null 2>&1 ) || rc=$?
  after="$(sha256sum "${sbng}/docs/backlog.md" | cut -d' ' -f1)"
  if [ "${rc}" -eq 2 ] && [ "${before}" = "${after}" ]; then
    record_pass "backlog-projection: enumeração vazia → QUEBRA (recusa; não sobrescreve a projeção boa)"
  else record_fail "backlog-projection: enumeração vazia" "esperava rc=2 e arquivo intacto; rc=${rc} mutou=$([ "${before}" = "${after}" ] && echo nao || echo SIM)"; fi
  rm -rf "${sbng}"


  # (g) LOCALE — o eixo que uma catraca byte-a-byte COMPRA e que nenhum outro caso tocava.
  #     Medido na revisão adversarial: `sort` sem LC_ALL=C troca a ordem de nós empatados
  #     sob en_US, e `printf '%.1f'` sob LC_NUMERIC com vírgula grava `38,0` no lugar de
  #     `38.2` — 190 erros em stderr E exit 0, o que faria o lint mandar GRAVAR o lixo.
  #     O script pina `export LC_ALL=C`; este caso prova que a pinagem sobrevive ao chamador.
  local loc found_alt=""
  for loc in en_US.utf8 en_US.UTF-8 C.utf8; do
    if locale -a 2>/dev/null | grep -qx "${loc}"; then found_alt="${loc}"; break; fi
  done
  if [ -n "${found_alt}" ]; then
    ( cd "${sb}" && LC_ALL="${found_alt}" bash .claude/validation/kg-backlog-project.sh --markdown > "${sb}/loc.out" 2>/dev/null )
    if diff -q "${sb}/md.out" "${sb}/loc.out" >/dev/null 2>&1; then
      record_pass "backlog-projection: render idêntico sob locale ${found_alt} (pinagem sobrevive ao chamador)"
    else record_fail "backlog-projection: locale" "render diverge sob ${found_alt} — a catraca HARD acusaria o AMBIENTE, não o conteúdo"; fi
  else
    record_skip "backlog-projection: locale — nenhum locale alternativo instalado (SUT não exercido)"
  fi

  # (h) RADAR QUEBRADO → QUEBRA, não perda calada. Era o buraco mais grave: o rc do radar
  #     era descartado, um grafo ilegível fazia dezenas de itens sumirem, o --fix gravava a
  #     perda e a REGRA 62 reportava ZERO violações — a guarda selando a própria doença.
  local sbrd
  sbrd="$(TMPDIR=/tmp mktemp -d)"
  cp -a "${REPO_ROOT}/.claude" "${sbrd}/.claude"
  cp -a "${REPO_ROOT}/docs"    "${sbrd}/docs"
  ( cd "${sbrd}" && git init -q && git add -A >/dev/null 2>&1 \
    && git -c user.email=t@t -c user.name=t commit -qm seed >/dev/null 2>&1 ) || true
  rm -f "${sbrd}/.claude/validation/lib/status-factor.awk"   # o radar passa a sair != 0
  before="$(sha256sum "${sbrd}/docs/backlog.md" | cut -d' ' -f1)"
  rc=0; ( cd "${sbrd}" && bash .claude/validation/kg-backlog-project.sh --write >/dev/null 2>"${sbrd}/rd.err" ) || rc=$?
  after="$(sha256sum "${sbrd}/docs/backlog.md" | cut -d' ' -f1)"
  if [ "${rc}" -eq 2 ] && [ "${before}" = "${after}" ] && grep -q 'kg-radar FALHOU' "${sbrd}/rd.err" 2>/dev/null; then
    record_pass "backlog-projection: radar quebrado → QUEBRA (não some item calado nem sobrescreve)"
  else record_fail "backlog-projection: radar quebrado" "esperava rc=2 + intacto + razão; rc=${rc} mutou=$([ "${before}" = "${after}" ] && echo nao || echo SIM)"; fi
  rm -rf "${sbrd}"

  rm -rf "${fakebin}" "${sb}"
}

run_drive_selftests() {
  local ds="${REPO_ROOT}/.claude/validation/kg-drive-project.sh"
  local fx="${REPO_ROOT}/.claude/validation/fixtures/kg-drive"
  if [ ! -f "${ds}" ]; then record_skip "drive: kg-drive-project.sh ausente"; return; fi
  if [ ! -d "${fx}" ]; then record_skip "drive: fixtures/kg-drive ausente"; return; fi
  # caso: nome-da-fixture | substring esperada na linha --check | rc esperado
  local -a cases=(
    "ready-and-blocked|READY: pronto=2 bloqueado=1|0"
    "deadlock|DEADLOCK: pronto=0 bloqueado=2|1"
    "predecessor-closed|READY: pronto=1 bloqueado=0|0"
    "all-done|DONE: pronto=0 bloqueado=0 (aberto=0)|0"
  )
  local c name want wantrc rc out f
  for c in "${cases[@]}"; do
    name="${c%%|*}"; c="${c#*|}"; want="${c%|*}"; wantrc="${c##*|}"
    f="${fx}/${name}.kg.yaml"
    if [ ! -f "${f}" ]; then record_fail "drive: fixture ${name}" "fixture ausente: ${f}"; continue; fi
    rc=0; out="$(bash "${ds}" "${f}" --check 2>&1)" || rc=$?
    if [ "${rc}" != "${wantrc}" ]; then
      record_fail "drive: ${name} (rc)" "esperava rc=${wantrc}, veio rc=${rc}: ${out}"; continue
    fi
    if printf '%s' "${out}" | grep -qF "${want}"; then
      record_pass "drive: ${name} censo/fila-pronta (rc=${rc})"
    else
      record_fail "drive: ${name} (censo)" "esperava '${want}' em: ${out}"
    fi
  done
}

# REGRA 34 pós-cutover (derivação commitada) — a regra HARD nova entrou sem rede
# (achado da revisão adversarial da reforma). Fixture em sandbox git REAL: a regra
# exige índice ([ -e .git ] skip sem ele — o que o sandbox principal, cp -a, prova
# pelo caminho do skip em toda fixture que roda).
run_site_derivation_selftests() {
  local sb2 out rc
  sb2="$(mktemp -d)"
  cp -a "${SANDBOX}/.claude" "${sb2}/.claude"
  cp "${SANDBOX}/CLAUDE.md" "${sb2}/CLAUDE.md" 2>/dev/null || printf '# stub\n' > "${sb2}/CLAUDE.md"
  mkdir -p "${sb2}/docs" "${sb2}/site/dist"
  printf 'x' > "${sb2}/site/dist/leak.html"
  ( cd "${sb2}" && git init -q . && git add site/dist ) >/dev/null 2>&1
  rc=0; out="$(bash "${sb2}/.claude/validation/lint-artifacts.sh" --only="${sb2}/CLAUDE.md" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'DERIVACAO-COMMITADA'; then
    record_pass "site-derivation: (a) dist TRACKED em repo git → HARD"
  else record_fail "site-derivation: (a)" "dist tracked não acusou (rc=${rc})"; fi
  ( cd "${sb2}" && git rm -rq --cached site/dist ) >/dev/null 2>&1
  rc=0; out="$(bash "${sb2}/.claude/validation/lint-artifacts.sh" --only="${sb2}/CLAUDE.md" 2>&1)" || rc=$?
  if ! printf '%s' "${out}" | grep -q 'DERIVACAO-COMMITADA'; then
    record_pass "site-derivation: (b) dist untracked → limpo"
  else record_fail "site-derivation: (b)" "falso-positivo com dist fora do índice"; fi
  # (c) VOLUME acima do buffer do pipe (~64KB de ls-files): a asserção que importa não é
  # "acusou" — é "o lint CHEGOU AO SUMÁRIO". A 1ª cura do SIGPIPE morria muda (rc=141)
  # exatamente aqui, com um caso N=1 sendo estruturalmente incapaz de pegar (re-revisão).
  local i
  for i in $(seq 1 1500); do printf 'x' > "${sb2}/site/dist/f-longo-nome-para-encher-o-buffer-${i}.html"; done
  ( cd "${sb2}" && git add site/dist ) >/dev/null 2>&1
  rc=0; out="$(bash "${sb2}/.claude/validation/lint-artifacts.sh" --only="${sb2}/CLAUDE.md" 2>&1)" || rc=$?
  if printf '%s' "${out}" | grep -q 'DERIVACAO-COMMITADA' && printf '%s' "${out}" | grep -q 'Sumário'; then
    record_pass "site-derivation: (c) 1500 arquivos tracked → acusa E o lint chega ao sumário (rc=${rc}, não 141)"
  else record_fail "site-derivation: (c)" "sob volume: rc=${rc}; acusou=$(printf '%s' "${out}" | grep -c 'DERIVACAO-COMMITADA'); sumário=$(printf '%s' "${out}" | grep -c 'Sumário')"; fi
  rm -rf "${sb2}"
}

run_hook_autofix_selftests
run_kg_reverify_schema_selftests
run_backtick_ref_selftests
run_site_deeplink_selftests
run_deploy_site_selftests
run_install_caddy_config_selftests
run_realign_selftests
run_harvest_residue_selftests
run_compose_exposure_selftests
run_backlog_projection_selftests
run_radar_staleness_selftests
run_members_registry_selftests
run_census_extract_selftests
run_census_seal_selftests
run_sdaal_workflows_selftests
run_drive_selftests
run_site_derivation_selftests
run_rules_registry_selftests
run_onion_version_tracked_selftests
run_hub_role_guard_selftests
run_inventory_adopter_scope_selftests
run_family_topology_selftests
run_decouple_source_selftests
run_kg_view_selftests
run_kg_status_factor_selftests

# Modo kg-scope — --scope do gate (insumo do /meta:kg backfill); protege a catraca canônica.
run_kg_scope_selftests

# Modo projection-safety — REGRA 30: nome comercial de membro privado não sai do repo privado.
run_projection_safety_selftests
run_federation_projection_selftests

# ---------------------------------------------------------------------------
# Sumário
# ---------------------------------------------------------------------------
# ⚠️ NÃO desarme a guarda AQUI. Ela ficava muda durante a IMPRESSÃO do sumário, e a janela é real:
#    com a saída consumida por algo que fecha o pipe (`| head`, `| grep -q`), a suíte morre de
#    SIGPIPE no meio da soma — medido: `rc=141`, sumário truncado, stderr VAZIO. Exatamente a
#    "leitura confortável" que esta guarda existe para remover. O desarme foi para DEPOIS do
#    veredito final, que é o único ponto em que a suíte de fato chegou ao fim.
echo ""
echo "=== Sumário do auto-teste de guardas ==="
echo "  Passaram : ${PASS}"
echo "  Pularam  : ${SKIP}   (⊘ NÃO VERIFICADO — o SUT não foi exercido)"
echo "  Falharam : ${FAIL}"
echo ""

# O bloco dos pulados vem ANTES do veredito e é impresso mesmo com FAIL>0: um skip
# silencioso é justamente o que se está consertando; escondê-lo atrás de uma falha
# reintroduziria o buraco pela porta dos fundos.
if [ "${SKIP}" -gt 0 ]; then
  echo "⊘ ${SKIP} caso(s) NÃO VERIFICADOS — tooling ou feature ausente (não são aprovações):"
  for c in "${SKIPPED_CASES[@]}"; do echo "  - ${c}"; done
  echo ""
fi

if [ "${STRICT}" = "1" ] && [ "${SKIP}" -gt 0 ]; then
  echo "FALHOU (STRICT) — ${SKIP} guarda(s) não puderam ser exercidas neste ambiente."
  echo "  ONION_SELFTEST_STRICT=1 exige capacidade completa: instale o tooling ausente"
  echo "  (jq, python3, python3-yaml, git, openssl) ou rode sem STRICT para o degrade local."
  SUMMARY_PRINTED=1; exit 1
fi

if [ "${FAIL}" -gt 0 ]; then
  echo "FALHOU — guardas que não reagiram conforme esperado:"
  for c in "${FAILED_CASES[@]}"; do echo "  - ${c}"; done
  SUMMARY_PRINTED=1; exit 1
fi

if [ "${SKIP}" -gt 0 ]; then
  echo "OK ✓ — as ${PASS} guardas EXERCIDAS reagiram conforme esperado (⊘ ${SKIP} não verificadas)."
else
  echo "OK ✓ — todas as guardas reagiram conforme esperado."
fi
SUMMARY_PRINTED=1   # SÓ AQUI: o veredito foi IMPRESSO. Desarmar antes deixava a guarda muda durante
                    # a própria impressão do sumário — e um SIGPIPE (`| head`, `| grep -q`) matava a
                    # suíte no meio da soma com rc=141, sumário truncado e stderr VAZIO.
exit 0
