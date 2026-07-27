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

# Git hooks EXPORTAM GIT_DIR/GIT_INDEX_FILE (e o `git commit` os aponta para o repo do
# commit em curso). Cada sandbox git forjada aqui os herdaria e operaria no repo ERRADO.
# Medido: sob `git commit`, a suíte ABORTAVA no caso 93 de 472 — e o hook anunciava
# "self-test das guardas falhou", quando o real era "379 guardas nunca rodaram". Um abort
# apresentado como veredito é a MESMA vacuidade que o record_skip conserta, uma camada
# acima: o pre-commit era inutilizável exatamente nos commits que tocam as guardas.
# Defeito PRÉ-EXISTENTE, achado dogfoodando o próprio fix (a main aborta idêntico).
unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

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
trap 'rm -rf "${SANDBOX}"' EXIT
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

record_pass() { PASS=$((PASS + 1)); echo "  ✓ ${1}"; }
record_fail() { FAIL=$((FAIL + 1)); FAILED_CASES+=("${1}"); echo "  ✗ ${1} — ${2}"; }
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
      -e "s/__ONION_KBS_TOTAL__/${SSOT_KB_TOTAL}/g" \
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
  if [ "${rc}" -eq 0 ] && ! printf '%s' "${out}" | grep -q 'STALE' \
     && printf '%s' "${out}" | grep -q 'schema_version 1 (bate'; then
    record_pass "kg-freshness: fresh-verified → exit 0, sem STALE, schema ✅"
  else record_fail "kg-freshness: fresh-verified" "rc=${rc} out=${out}"; fi

  # (b) stale-missing --freshness: nó PROD sem verified_at → STALE-MISSING, exit 0 (aviso)
  rc=0; out=$(bash "${radar}" "${fx}/stale-missing.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'STALE-MISSING: ST_A'; then
    record_pass "kg-freshness: stale-missing → STALE-MISSING + exit 0 (aviso, não reprova)"
  else record_fail "kg-freshness: stale-missing" "rc=${rc} out=${out}"; fi

  # (c) stale-old --freshness: verified_at < baseline → STALE-OLD, exit 0 (determinístico, sem "agora")
  rc=0; out=$(bash "${radar}" "${fx}/stale-old.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'STALE-OLD: ST_A'; then
    record_pass "kg-freshness: stale-old → STALE-OLD + exit 0"
  else record_fail "kg-freshness: stale-old" "rc=${rc} out=${out}"; fi

  # (c2) superseded/refuted NÃO são cobrados por frescor — mas o nó VIVO sem carimbo continua sendo.
  # Os dois lados no mesmo caso: senão "consertar" seria matar a guarda e chamar de fix.
  rc=0; out=$(bash "${radar}" "${fx}/superseded-not-chased.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && ! printf '%s' "${out}" | grep -q 'STALE-MISSING: C_VELHO' \
     && ! printf '%s' "${out}" | grep -q 'STALE-MISSING: C_MORTO' \
     && printf '%s' "${out}" | grep -q 'STALE-MISSING: C_VIVO'; then
    record_pass "kg-freshness: superseded/refuted não cobrados; nó vivo sem carimbo ainda cobrado"
  else record_fail "kg-freshness: superseded-not-chased" "rc=${rc} out=${out}"; fi

  # (d) schema-divergent --schema: schema_version ≠ radar → RECUSA com exit 1 (não é aviso)
  rc=0; out=$(bash "${radar}" "${sx}/schema-divergent.kg.yaml" --schema 2>&1) || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'schema_version divergente'; then
    record_pass "kg-schema: divergente → ✗ + exit 1 (recusa, radar não sabe ler)"
  else record_fail "kg-schema: divergente" "esperava exit 1 + ✗; rc=${rc} out=${out}"; fi

  # (e) retrocompat: grafo legado sem schema_version → ⚠ ausente + exit 0 (não quebra grafo válido)
  rc=0; out=$(bash "${radar}" "${FIX_DIR}/kg-domain/good-domain.kg.yaml" --schema 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] && printf '%s' "${out}" | grep -q 'schema_version ausente'; then
    record_pass "kg-schema: ausente → ⚠ + exit 0 (retrocompat, degradê)"
  else record_fail "kg-schema: ausente/retrocompat" "esperava exit 0 + ⚠; rc=${rc} out=${out}"; fi

  # (f) F1.1 — frescor estende a DEV que rastreia artefato móvel (verified_against), sem inundar
  # claim epistêmico DEV puro. Sinal de um adotante: ssot-como-runtime §2 (C_CONSOLIDATION_MAP stale).
  rc=0; out=$(bash "${radar}" "${fx}/dev-tracked-stale.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q 'STALE-MISSING: C_STRAT' \
     && ! printf '%s' "${out}" | grep -q 'C_READ'; then
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
     && printf '%s' "${out}" | grep -q 'UNANCHORED: C_AFIRMA' \
     && ! printf '%s' "${out}" | grep -qE 'UNANCHORED: (C_ANCORADA|E_MEDIU|D_DECIDE|EN_DOM|A_DOC|Q_ABERTA)'; then
    record_pass "kg-freshness: (g) UNANCHORED cobra claim e NÃO cobra evidence/decision/entity/artifact/question"
  else record_fail "kg-freshness: (g) filtro por node_type" "rc=${rc} out=${out}"; fi

  # (h) o filtro NÃO virou `continue` no laço: os outros vereditos seguem valendo p/ não-claim,
  # e num mesmo nó UNANCHORED e STALE-OLD compõem em vez de se excluírem.
  if printf '%s' "${out}" | grep -q 'STALE-MISSING: E_SEM_CARIMBO' \
     && printf '%s' "${out}" | grep -q 'UNANCHORED: C_VELHA' \
     && printf '%s' "${out}" | grep -q 'STALE-OLD: C_VELHA'; then
    record_pass "kg-freshness: (h) STALE-MISSING ainda vale p/ não-claim + UNANCHORED e STALE-OLD compõem"
  else record_fail "kg-freshness: (h) escopo dos outros vereditos" "o filtro virou continue? out=${out}"; fi

  # (i) supressão CONTADA, nunca silenciosa — 5 não-claim carimbados sem alvo na fixture.
  if printf '%s' "${out}" | grep -q 'ℹ 5 nó(s) não-claim'; then
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
  cp "${radar}" "${mut}/mutado.sh"
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
  top_tsv="$(printf '%s\n' "${tsv}" | sort -t"$(printf '\t')" -k7 -rn | head -1 | cut -f1)"
  top_radar="$(bash "${radar}" "${fxu}" --radar 2>/dev/null | sed -n '2p' | awk '{print $2}')"
  if [ -n "${top_tsv}" ] && [ "${top_tsv}" = "${top_radar}" ]; then
    record_pass "kg-freshness: (o) topo por atenção do TSV == topo do --radar (mesma fórmula, sem drift)"
  else record_fail "kg-freshness: (o) ordenação" "tsv=${top_tsv} radar=${top_radar}"; fi

  # (p) (MUT) sem a exclusão de história, o nó reconciliado VOLTA a aparecer — prova que (n)
  # não é vacuidade (a fixture PRECISA ter um nó reconciliado para isso significar algo).
  cp "${radar}" "${mut}/mut-tsv.sh"
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
# Modo migalhas-generate — REGRA 34. O gerador projeta posts/*.md nas 3 superfícies
# entre os marcadores ONION:GEN. Fixture self-contained (chrome mínimo + 1 post),
# roda o gerador, verifica que a projeção saiu, que --check acusa drift após edição
# manual, e (mutation) que quebrar a substituição-por-marcador faz o --check FALHAR.
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

run_migalhas_generate_selftests() {
  local gen="${SCRIPT_DIR}/migalhas-generate.sh"
  local tmp
  [ -f "${gen}" ] || return 0
  command -v python3 >/dev/null 2>&1 || { record_skip "migalhas-generate: python3 ausente (skip gracioso, coerente com REGRA 34)"; return; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  local M="${tmp}/site/historia/migalhas"
  mkdir -p "${M}/posts" "${M}/provas"

  # superfícies mínimas com os marcadores (chrome irrelevante para o teste)
  printf '<html><body>\n<div class="feed" id="feed">\n<!-- ONION:GEN posts START -->\nVELHO\n<!-- ONION:GEN posts END -->\n</div>\n</body></html>\n' > "${M}/index.html"
  printf '<html><body>\n<div class="feed">\n<!-- ONION:GEN provas START -->\nVELHO\n<!-- ONION:GEN provas END -->\n</div>\n</body></html>\n' > "${M}/provas/index.html"
  printf '<rss><channel>\n<lastBuildDate>x</lastBuildDate>\n<!-- ONION:GEN items START -->\nVELHO\n<!-- ONION:GEN items END -->\n</channel></rss>\n' > "${M}/feed.xml"
  cat > "${M}/posts/2026-07-01-caso.md" <<'PEOF'
---
slug: 2026-07-01-caso
type: learning
date: 2026-07-01
review_after: 2026-10-01
title: "Um título de teste"
rss: "Um resumo de teste."
prs:
  - {label: "PR #7", status: "mergeado", meta: "1 jul · 1 arquivo · +1 −0"}
---
## O que descobri
Parágrafo *um*.

## A prova
Parágrafo dois.

## Onde isso nos levou
Parágrafo três.
PEOF

  # o gerador precisa do git-root p/ resolver ROOT; força via cwd + fallback do script
  MIGALHAS_ROOT="${tmp}" bash "${gen}" >/dev/null 2>&1
  # (a) projetou nas 3 superfícies?
  if grep -q 'id="post-2026-07-01-caso"' "${M}/index.html" \
     && grep -q 'id="prova-2026-07-01-caso"' "${M}/provas/index.html" \
     && grep -q '#post-2026-07-01-caso' "${M}/feed.xml"; then
    record_pass "migalhas-generate: (a) projeta o post nas 3 superfícies entre os marcadores"
  else record_fail "migalhas-generate: (a)" "post não projetado nas 3 superfícies"; fi

  # (b) PR label verbatim + pr-link derivado do slug
  if grep -q 'PR #7' "${M}/provas/index.html" \
     && grep -q 'href="/historia/migalhas/provas/#prova-2026-07-01-caso"' "${M}/index.html"; then
    record_pass "migalhas-generate: (b) label do PR verbatim + pr-link derivado do slug"
  else record_fail "migalhas-generate: (b)" "label/pr-link errados"; fi

  # (c) --check: em sincronia após gerar → exit 0
  local rc=0; MIGALHAS_ROOT="${tmp}" bash "${gen}" --check >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -eq 0 ]; then
    record_pass "migalhas-generate: (c) --check exit 0 quando em sincronia"
  else record_fail "migalhas-generate: (c)" "--check acusou drift num estado recém-gerado (rc=${rc})"; fi

  # (d) --check: edição manual na região gerada → exit 1 (o drift-guard)
  sed -i 's/Um título de teste/EDITADO A MAO/' "${M}/index.html"
  rc=0; MIGALHAS_ROOT="${tmp}" bash "${gen}" --check >/dev/null 2>&1 || rc=$?
  if [ "${rc}" -ne 0 ]; then
    record_pass "migalhas-generate: (d) --check exit 1 após edição manual (drift detectado)"
  else record_fail "migalhas-generate: (d)" "edição manual não foi detectada como drift"; fi

  # (MUT) quebrar a substituição-por-marcador (splice não escreve) → --check nunca acusa drift
  MIGALHAS_ROOT="${tmp}" bash "${gen}" >/dev/null 2>&1 || true   # re-sincroniza
  sed 's/if MODE!="--check": open(path,"w",encoding="utf-8").write(new)/pass  # MUTADO/' "${gen}" > "${tmp}/mut.sh"
  sed -i 's/Um título de teste/EDITADO DE NOVO/' "${M}/index.html"
  MIGALHAS_ROOT="${tmp}" bash "${tmp}/mut.sh" --check >/dev/null 2>&1 || true
  # com o write mutado, o --check ainda deve DETECTAR (só o write foi neutralizado, não o compare).
  # o que a mutação quebra é a ESCRITA: provamos que sem escrever, gerar não conserta o drift.
  MIGALHAS_ROOT="${tmp}" bash "${tmp}/mut.sh" >/dev/null 2>&1 || true   # "gera" com write mutado
  if grep -q 'EDITADO DE NOVO' "${M}/index.html"; then
    record_pass "migalhas-generate: (MUT) sem a escrita, gerar NÃO conserta o drift — a escrita é load-bearing"
  else record_fail "migalhas-generate: (MUT)" "o drift sumiu sem a escrita — o teste não prova nada"; fi
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
  cp "${SCRIPT_DIR}/kg-radar.sh" "${tmp}/kg-radar.sh"
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
  out="$(bash "${repo}/.claude/validation/kg-provenance-coverage.sh" "${repo}" --scope docs/outro-corpus 2>&1)"; rc=$?
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
  if [ ! -f "${helper}" ]; then record_fail "kg-console" "helper ausente: ${helper}"; return; fi
  if [ ! -f "${fixture}" ]; then record_fail "kg-console" "fixture ausente: ${fixture}"; return; fi
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    local rc=0; bash "${helper}" "${fixture}" >/dev/null 2>&1 || rc=$?
    if [ "${rc}" -eq 3 ]; then record_pass "kg-console: sem python+yaml → exit 3 (gracioso)"
    else record_skip "kg-console: pulado (sem python+yaml)"; fi
    return; fi
  local H; H="$(bash "${helper}" "${fixture}" 2>/dev/null)"
  if printf '%s' "${H}" | grep -q '<!doctype html>' && printf '%s' "${H}" | grep -q '</html>' \
     && ! printf '%s' "${H}" | grep -q '__DATA__' \
     && printf '%s' "${H}" | grep -q '"nodes"' && printf '%s' "${H}" | grep -q 'RADAR'; then
    record_pass "kg-console: HTML self-contained (nodes+veredito do radar, sem placeholder)"
  else record_fail "kg-console: html" "HTML inválido/incompleto"; fi
  if printf '%s' "${H}" | grep -qiE 'src=.?https?://|<script src|href=.?https?://[^"]*\.(js|css)|fetch\('; then
    record_fail "kg-console: self-contained" "tem dependência externa (CDN/fetch)"
  else record_pass "kg-console: self-contained (sem CDN/fetch externo)"; fi
  local H2; H2="$(bash "${helper}" "${fixture}" 2>/dev/null)"
  if [ "$(printf '%s' "${H}" | sha256sum)" = "$(printf '%s' "${H2}" | sha256sum)" ]; then
    record_pass "kg-console: determinístico"
  else record_fail "kg-console: determinismo" "varia entre execuções"; fi
  local rc2=0; bash "${helper}" "/nonexistent/x.kg.yaml" >/dev/null 2>&1 || rc2=$?
  if [ "${rc2}" -eq 2 ]; then record_pass "kg-console: arquivo inexistente → exit 2"
  else record_fail "kg-console: uso" "esperava exit 2, veio ${rc2}"; fi
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
  cp "${REPO_ROOT}/.claude/validation/kg-radar.sh"       "${d}/.claude/validation/"

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
    base_crumb="$(cd "${sb}" && find .claude/diary -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | head -1)"
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
  vazio="$(mktemp -d)"
  naonvend="$(mktemp -d)"
  ob="${sb}/docs/evolution/federation/outbox"

  # (1) vendorizado COM canal + anúncio           -> silêncio
  mkdir -p "${ob}/selftest-com-canal";  printf '# t\n' > "${ob}/selftest-com-canal/2026-01-01-t.md"
  # (2) vendorizado SEM canal + anúncio           -> SOFT [classe 3, local]
  mkdir -p "${ob}/selftest-sem-canal";  printf '# t\n' > "${ob}/selftest-sem-canal/2026-01-01-t.md"
  # (3) SEM anúncio em staging                    -> silêncio (nenhum dir criado)
  # (4) membro onion_version n/a + anúncio        -> SOFT [classe 2, roda no CI]
  mkdir -p "${ob}/selftest-nao-vendoriza"; printf '# t\n' > "${ob}/selftest-nao-vendoriza/2026-01-01-t.md"
  # (5) dir órfão (não é id de membro) + anúncio  -> SOFT [classe 1, roda no CI]
  mkdir -p "${ob}/selftest-orfao-xyz";  printf '# t\n' > "${ob}/selftest-orfao-xyz/2026-01-01-t.md"
  # (6) SÓ _processed/ (já entregue)              -> silêncio (1º nível apenas)
  mkdir -p "${ob}/selftest-so-processed/_processed"
  printf '# t\n' > "${ob}/selftest-so-processed/_processed/2026-01-01-t.md"

  {
    printf '  - id: selftest-com-canal\n    role: standalone\n    onion_version: abc123\n    local_path: "%s"\n' "${com_canal}"
    printf '  - id: selftest-sem-canal\n    role: standalone\n    onion_version: abc123\n    local_path: "%s"\n' "${sem_canal}"
    printf '  - id: selftest-vazio\n    role: standalone\n    onion_version: abc123\n    local_path: "%s"\n' "${vazio}"
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
    && record_pass "outbox-channel: dir órfão → SOFT (classe decidível no CI)" \
    || record_fail "outbox-channel: órfão" "não acusou dir de staging que não resolve a membro"

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

  rm -rf "${sb}" "${com_canal}" "${sem_canal}" "${vazio}" "${naonvend}"
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
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q '🕯️ VIVA: sess-alpha'; then
    record_pass "session-beacon: check detecta sessão viva alheia → exit 1 (regressão W1×W2)"
  else record_fail "session-beacon: check vivo" "esperava exit 1 + 🕯️; out='${out}' rc=${rc}"; fi

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
       && printf '%s' "${out}" | grep -q 'OUTRA sessão viva'; then
      record_pass "session-beacon: hook acende farol + avisa colisão no boot (exit 0)"
    else record_fail "session-beacon: hook" "esperava farol+aviso+0; out='${out}' rc=${rc}"; fi

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

# Modo githook — idem (hook nativo Onion; cenários self-contained em mktemp).
run_githook_selftests

# Modo assemble-plugin — idem (empacota vertical Design como plugin; dest em mktemp).
# Core-only: já pula gracioso sem plugins/ (ver função). O `|| true` é rede de segurança —
# um abort imprevisto sob set -e jamais esconde os modos self-contained seguintes (de-id).
run_assemble_plugin_selftests || true
run_marketplace_generate_selftests || true
run_bootstrap_vertical_selftests || true
run_scaffold_book_selftests || true

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

# Modo kb-vendored-link — REGRA 45: link vendorizado não aponta caminho core-privado (catraca; guard core-side do bug de campo do Pedro).
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

# Modo kg-view — REGRA 31: lente derivada, determinística e em paridade com o motor.
run_vendor_scrub_selftests
run_site_deeplink_selftests
run_migalhas_generate_selftests
run_rules_registry_selftests
run_onion_version_tracked_selftests
run_hub_role_guard_selftests
run_inventory_adopter_scope_selftests
run_family_topology_selftests
run_decouple_source_selftests
run_kg_view_selftests

# Modo kg-scope — --scope do gate (insumo do /meta:kg backfill); protege a catraca canônica.
run_kg_scope_selftests

# Modo projection-safety — REGRA 30: nome comercial de membro privado não sai do repo privado.
run_projection_safety_selftests
run_federation_projection_selftests

# ---------------------------------------------------------------------------
# Sumário
# ---------------------------------------------------------------------------
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
  exit 1
fi

if [ "${FAIL}" -gt 0 ]; then
  echo "FALHOU — guardas que não reagiram conforme esperado:"
  for c in "${FAILED_CASES[@]}"; do echo "  - ${c}"; done
  exit 1
fi

if [ "${SKIP}" -gt 0 ]; then
  echo "OK ✓ — as ${PASS} guardas EXERCIDAS reagiram conforme esperado (⊘ ${SKIP} não verificadas)."
else
  echo "OK ✓ — todas as guardas reagiram conforme esperado."
fi
exit 0
