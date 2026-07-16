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
# Uso       : bash .claude/validation/lint-selftest.sh
# Saída     : exit 0 se todos os vereditos batem; exit 1 se algum diverge.
#
# Determinístico, sem LLM. Par do princípio inventory.sh/lint-artifacts.sh.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FIX_DIR="${SCRIPT_DIR}/fixtures"
MANIFEST="${FIX_DIR}/manifest.tsv"
INJECT_BASE="selftest-fixture-probe"     # kebab-case → não dispara a Regra 6
INJECT_NAME="${INJECT_BASE}.md"

PASS=0
FAIL=0
FAILED_CASES=()

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
# (ADR onion-adr-kg-freshness-gate, propostas #2/#1 do dogfood rhilo). Frescor é AVISO
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
  # claim epistêmico DEV puro. Sinal rhilo ssot-como-runtime §2 (C_CONSOLIDATION_MAP stale).
  rc=0; out=$(bash "${radar}" "${fx}/dev-tracked-stale.kg.yaml" --freshness 2>&1) || rc=$?
  if [ "${rc}" -eq 0 ] \
     && printf '%s' "${out}" | grep -q 'STALE-MISSING: C_STRAT' \
     && ! printf '%s' "${out}" | grep -q 'C_READ'; then
    record_pass "kg-freshness: DEV+verified_against → STALE-MISSING; DEV puro NÃO flagado (não inunda)"
  else record_fail "kg-freshness: dev-tracked" "esperava STALE C_STRAT sem C_READ; rc=${rc} out=${out}"; fi
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
    record_pass "${fixture} (skip: jq ausente)"; return
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
  printf 'role: adopted\nintegration_branch: arandek-evolve\n' > "${d}/.claude/.onion-version"
  out="$(bash "${helper}" "${d}" 2>/dev/null || true)"; rm -rf "${d}"
  if [ "${out}" = "arandek-evolve" ]; then record_pass "resolve: campo integration_branch vence"
  else record_fail "resolve: campo integration_branch vence" "esperava 'arandek-evolve', veio '${out}'"; fi

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
    # artefatos GERADOS na adoção (achado de campo gustavo-pulga 2026-07-09): devem ser durables também
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

  # (b2) artefatos GERADOS na adoção também durables (regressão do achado gustavo-pulga)
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
  bash "${helper}" update "$t" "$core" v2 "$ib" >/dev/null 2>&1
  if grep -q v2 "$t/docs/meta-specs/spec.md" && grep -q produto "$t/src/app.js"; then
    record_pass "vendor-branch: update limpo aplica framework + preserva produto"
  else record_fail "vendor-branch: update limpo" "v2 não aplicado ou produto perdido"; fi

  # (c) CONFLITO — o teste-chave
  printf 'cmd v2 CUSTOMIZADO\n' > "$t/.claude/commands/foo.md"; git -C "$t" add -A; git -C "$t" commit -qm custom
  _vb_core "$core" 3
  local rc=0; bash "${helper}" update "$t" "$core" v3 "$ib" >/dev/null 2>&1 || rc=$?
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
  bash "${helper}" update "$t2" "$c2" v2 "$ib2" >/dev/null 2>&1 || true
  local rci=0; bash "${helper}" update "$t2" "$c2" v2 "$ib2" >/dev/null 2>&1 || rci=$?
  if [ "$rci" -eq 0 ] && [ -z "$(git -C "$t2" status --short)" ]; then
    record_pass "vendor-branch: re-update idempotente (exit 0, tree limpa)"
  else record_fail "vendor-branch: idempotência" "exit=$rci ou tree suja"; fi

  # (e) legado — sem onion/vendor, update semeia
  local c3 t3 ib3; c3="$(mktemp -d)/c3"; t3="$(mktemp -d)/a3"; _vb_core "$c3" 1; _vb_adopter "$t3" "$c3"
  ib3="$(git -C "$t3" rev-parse --abbrev-ref HEAD)"; _vb_core "$c3" 2
  local rcl=0; bash "${helper}" update "$t3" "$c3" v2 "$ib3" >/dev/null 2>&1 || rcl=$?
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
  local rcf=0; bash "${helper}" update "$t4" "$c4" v2 "$ib4" >/dev/null 2>&1 || rcf=$?
  if [ "$rcf" -eq 10 ] && grep -q CUSTOM "$t4/.claude/commands/foo.md"; then
    record_pass "vendor-branch: legado c/ customização commitada → baseline limpo → CONFLITO (não clobra)"
  else record_fail "vendor-branch: legado baseline §8" "exit=$rcf ou customização clobada"; fi
  git -C "$t4" merge --abort 2>/dev/null || true

  rm -rf "$core" "$t" "$c2" "$t2" "$c3" "$t3" "$c4" "$t4" 2>/dev/null
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
  if ! command -v jq >/dev/null 2>&1; then record_pass "compose-settings: jq ausente → pulado (gracioso)"; return; fi
  local d; d="$(mktemp -d)"
  printf '%s' '{"theme":"dark","permissions":{"allow":["Bash(git *)"],"deny":[]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"fw"}]}]}}' > "$d/fw.json"
  printf '%s' '{"permissions":{"deny":["x"]},"env":{"ORG":"granaai"}}' > "$d/org.json"
  printf '%s' '{"model":"opus","permissions":{"allow":["Bash(nx *)"]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"team"}]}]}}' > "$d/team.json"
  printf '%s' '{"theme":"light","env":{"EDITOR":"vim"}}' > "$d/person.json"
  local C; C="$(bash "${helper}" "$d/fw.json" "$d/org.json" "$d/team.json" "$d/person.json" 2>/dev/null)"
  if [ "$(printf '%s' "$C" | jq -r .theme)" = "light" ] \
     && [ "$(printf '%s' "$C" | jq -r .model)" = "opus" ] \
     && [ "$(printf '%s' "$C" | jq -c '.permissions.allow')" = '["Bash(git *)","Bash(nx *)"]' ] \
     && [ "$(printf '%s' "$C" | jq -r '.env.ORG')" = "granaai" ] && [ "$(printf '%s' "$C" | jq -r '.env.EDITOR')" = "vim" ] \
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
    record_pass "resolve-target: seletor sobre membros pulado (sem python+yaml — gracioso)"; return; fi
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
# Modo federation-console — exercita .claude/validation/federation-console.sh (F1.3: console estático
# read-only do SSOT). Asserções estruturais (não fixam roster). Pula/exit-3 sem python+yaml.
# ---------------------------------------------------------------------------
run_federation_console_selftests() {
  local helper="${REPO_ROOT}/.claude/validation/federation-console.sh"
  if [ ! -f "${helper}" ]; then record_fail "federation-console" "helper ausente: ${helper}"; return; fi
  if ! (command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1); then
    local rc=0; bash "${helper}" >/dev/null 2>&1 || rc=$?
    if [ "${rc}" -eq 3 ]; then record_pass "federation-console: sem python+yaml → exit 3 (gracioso)"
    else record_pass "federation-console: pulado (sem python+yaml)"; fi
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
# Modo adopted-role — os checks de marketplace (plugins_sync/role_bundle_sync) devem PULAR
# em role: adopted (consumidor não distribui plugins). Sinal granaai 2026-07-10: rodando como
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
  rm -rf "${asb}"
}

# ---------------------------------------------------------------------------
# Modo write-stamp — escrita determinística do .onion-version (sinal granaai multi-lineage:
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
  else record_pass "write-stamp: restore pulado (sem python+yaml)"; fi
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
    else record_pass "kg-console: pulado (sem python+yaml)"; fi
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
    record_pass "a2a-verify: tooling p/ forjar fixtures ausente → skip (não-SUT)"; return
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

  # kid-binding: from=fin (sem k1 nas suas a2a.keys) assina com k1 → veto (anti-impersonação, hardening metagamify)
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
    record_pass "agent-card: python+yaml ausente → skip (não-SUT)"; return
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
  if ! command -v jq >/dev/null 2>&1; then record_pass "a2a-accept: jq ausente → skip (não-SUT)"; return; fi
  local d ib rec out rc doc
  d="$(mktemp -d)"; ib="${d}/inbox"; mkdir -p "${ib}"
  rec="${d}/verified.json"
  cat > "${rec}" <<'JSON'
{"taskId":"t1","receivedAt":"2026-07-09T21:42:01Z","from":"metagamify","signal":{"id":"2026-07-09-metagamify-a2a-hello","from":"metagamify","to":"onion-evolve","kind":"signal","body_path":"docs/x.md"},"verdict":{"verified":true,"regulated":false,"apply_mode":"gated"}}
JSON
  doc="${ib}/2026-07-09-metagamify-a2a-hello.md"
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
  else record_pass "resolve-scope-layers: compose pulado (sem jq)"; fi
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
  if ! command -v jq >/dev/null 2>&1; then record_pass "show-scope: jq ausente → pulado (gracioso)"; return; fi
  local TAB=$'\t'
  local d; d="$(mktemp -d)"
  printf '%s' '{"theme":"dark","permissions":{"allow":["Bash(git *)"],"deny":[]},"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"fw"}]}]}}' > "$d/fw.json"
  printf '%s' '{"permissions":{"deny":["x"]},"env":{"ORG":"granaai"}}' > "$d/org.json"
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
     && printf '%s\n' "$S" | grep -qxF "empresa${TAB}env.ORG=\"granaai\"" \
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

  # (e) complete-no-header → 5 paths soltos (espelha o rhilo real): no-op, NÃO injeta cabeçalho órfão
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
  if ! command -v jq >/dev/null 2>&1; then record_pass "assemble-plugin: jq ausente → pulado (gracioso)"; return; fi
  # Maquinaria de marketplace é core-only: validar a MONTAGEM de plugin só faz sentido
  # em quem publica plugins (o core tem plugins/ committed). Um consumidor não republica
  # → pular gracioso em vez de cair no assemble (que exige todos os componentes-fonte do
  # manifest presentes) sob set -e e abortar o harness inteiro.
  if [ ! -d "${REPO_ROOT}/plugins" ]; then record_pass "assemble-plugin: sem plugins/ vendorizados → pulado (consumidor não publica plugins)"; return; fi
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
  if ! command -v jq >/dev/null 2>&1; then record_pass "plugins-sync: jq ausente → pulado (gracioso)"; return; fi
  # Drift-guard de plugins committed é core-only: o adotante não vendoriza plugins/
  # (só verticals/*.manifest.sh). Sem plugins/ não há "committed" para comparar → pular.
  if [ ! -d "${REPO_ROOT}/plugins" ]; then record_pass "plugins-sync: sem plugins/ vendorizados → pulado (consumidor não publica plugins)"; return; fi
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
# Modo role-bundle — exercita o mapa role→bundle (REGRA 22 check_role_bundle_sync) + o resolver:
# (a) resolver acerta papeis conhecidos (source não-vazio, distilled vazio) e rejeita inválido;
# (b) todo vertical em roles.yaml tem manifesto + está no marketplace.json (consistência).
# ---------------------------------------------------------------------------
run_role_bundle_selftests() {
  local roles="${REPO_ROOT}/.claude/utils/marketplace/roles.yaml"
  local resolver="${REPO_ROOT}/.claude/utils/marketplace/resolve-role-bundle.sh"
  local vdir="${REPO_ROOT}/.claude/utils/marketplace/verticals"
  local mkt="${REPO_ROOT}/.claude-plugin/marketplace.json"
  if [ ! -f "${roles}" ] || [ ! -f "${resolver}" ]; then record_pass "role-bundle: roles.yaml/resolver ausentes → pulado (repo sem a feature)"; return; fi
  if ! python3 -c "import yaml" >/dev/null 2>&1; then record_pass "role-bundle: pyyaml ausente → pulado (gracioso)"; return; fi

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

  if ! command -v jq >/dev/null 2>&1; then record_pass "graph: jq ausente → demais checks pulados (gracioso)"; return; fi
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
    record_pass "graph: members/--map pulados (sem python+yaml — gracioso)"
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
    record_pass "design-tokens (skip: jq/awk ausente)"; return
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
  if ! command -v python3 >/dev/null 2>&1; then record_pass "de-id: python3 ausente → pulado (gracioso)"; return; fi

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

  # (b) stamp role: adopted → adopted (e o guard do /meta:adopt ABORTA — regressão FED-3-1)
  printf 'framework: onion\nsource_commit: abc123\nrole: adopted\n' > "${d}/.claude/.onion-version"
  out="$(bash "${d}/.claude/validation/onion-version.sh" | grep '^role:' || true)"
  if [ "${out}" = "role: adopted" ] \
     && ! bash "${d}/.claude/validation/onion-version.sh" | grep -q '^role: source'; then
    record_pass "onion-version: stamp adopted → guard do adopt aborta (regressão FED-3-1)"
  else record_fail "onion-version: stamp adopted" "esperava 'role: adopted', veio '${out}'"; fi

  # (c) stamp presente SEM campo role → adopted por definição (nunca 'source' por omissão)
  printf 'framework: onion\n' > "${d}/.claude/.onion-version"
  out="$(bash "${d}/.claude/validation/onion-version.sh" | grep '^role:' || true)"
  if [ "${out}" = "role: adopted" ]; then record_pass "onion-version: stamp sem role → adopted (fail-safe)"
  else record_fail "onion-version: stamp sem role" "esperava 'role: adopted', veio '${out}'"; fi
  rm -rf "${d}"
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
  rm -rf "${d}"
}

# ---------------------------------------------------------------------------
# Modo pin-integrity — exercita .claude/validation/pin-integrity-check.sh (o
# guard do /meta:adopt --update contra pin forjado — incidente 2026-06-30/rhilo:
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

  # (b) CASO RHILO — pin real mas canário divergente (vendor mais velho/novo que o stamp) → untrusted
  printf '#!/bin/sh\necho v2\n' > "${tgt}/.claude/validation/lint-artifacts.sh"
  rc=0; out="$(bash "${pic}" "${src}" "${tgt}")" || rc=$?
  if [ "${rc}" -eq 1 ] && printf '%s' "${out}" | grep -q 'canario-divergente'; then
    record_pass "pin-integrity: canário divergente → untrusted (regressão incidente rhilo 06-30)"
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
  record_pass "fixtures: manifest ausente → loop de fixture pulado (core-only; adotante não vendoriza fixtures/)"
fi

# Modo kg-freshness/schema — guardas de frescor + versão de schema (ADR kg-freshness-gate F1).
run_kg_freshness_selftests

# Modo resolve — não vem do manifest (cenários self-contained, sem fixture-file).
run_resolve_selftests

# Modo durable-commit — commit durável da instalação (fix do incidente uncommitted-descartável).
run_durable_commit_selftests

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

# Modo federation-console — console estático read-only do SSOT (F1.3 federação).
run_federation_console_selftests
run_kg_console_selftests
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

# Modo role-bundle — mapa role→bundle (REGRA 22): resolver + consistência dos verticais.
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

# Modo pin-integrity — pin do stamp é hipótese: guard do /meta:adopt --update (incidente rhilo 06-30; sandbox git).
run_pin_integrity_selftests

# Modo session-beacon — farol de sessão: I3 inclui sessões vivas (colisão W1×W2 de 2026-07-02; sandbox git).
run_session_beacon_selftests

# Modo mail-hook — "you have mail" + gatilho de reflexão ⏰ (motd silencioso, 3 sinais, exit 0; sandbox).
run_mail_hook_selftests

# Modo diary-crumbs — estrutura de decisão da migalha: conflict_class/valid_when (enabler breadcrumbs 2026-07; sandbox).
run_diary_crumbs_selftests

# ---------------------------------------------------------------------------
# Sumário
# ---------------------------------------------------------------------------
echo ""
echo "=== Sumário do auto-teste de guardas ==="
echo "  Passaram : ${PASS}"
echo "  Falharam : ${FAIL}"
echo ""

if [ "${FAIL}" -gt 0 ]; then
  echo "FALHOU — guardas que não reagiram conforme esperado:"
  for c in "${FAILED_CASES[@]}"; do echo "  - ${c}"; done
  exit 1
fi

echo "OK ✓ — todas as guardas reagiram conforme esperado."
exit 0
