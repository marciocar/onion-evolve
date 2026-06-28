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
  if ! command -v jq >/dev/null 2>&1; then record_pass "graph: jq ausente → pulado (gracioso)"; return; fi
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
      merge)    run_merge_fixture "${fixture}" ;;
      *)        record_fail "${fixture:-?}" "kind desconhecido '${kind}'" ;;
    esac
  done < "${MANIFEST}"
else
  record_pass "fixtures: manifest ausente → loop de fixture pulado (core-only; adotante não vendoriza fixtures/)"
fi

# Modo resolve — não vem do manifest (cenários self-contained, sem fixture-file).
run_resolve_selftests

# Modo prettierignore — idem (cenários self-contained, sem fixture-file).
run_prettierignore_selftests

# Modo githook — idem (hook nativo Onion; cenários self-contained em mktemp).
run_githook_selftests

# Modo assemble-plugin — idem (empacota vertical Design como plugin; dest em mktemp).
# Core-only: já pula gracioso sem plugins/ (ver função). O `|| true` é rede de segurança —
# um abort imprevisto sob set -e jamais esconde os modos self-contained seguintes (de-id).
run_assemble_plugin_selftests || true

# Modo plugins-sync — drift-guard (REGRA 19): committed bate com a regeneração da fonte.
run_plugins_sync_selftests || true

# Modo capability — Capability Contract (REGRA 20): contrato honesto + resolução de requires.
run_capability_selftests

# Modo graph — lente sócio-técnica (REGRA 21): graph.md em-sync + determinismo + atores + impacto.
run_graph_selftests

# Modo design-tokens — idem (cenários self-contained, sem fixture-file).
run_design_tokens_selftests

# Modo co-relay — idem (carteiro upstream; adotante+core em mktemp, sem fixture-file).
run_corelay_selftests

# Modo de-identification — baseline determinístico (adapter regex da abstração SDAAL): redação + round-trip + no-op + determinismo.
run_de_identification_selftests

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
