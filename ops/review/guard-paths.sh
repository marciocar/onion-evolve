#!/usr/bin/env bash
# =============================================================================
# guard-paths.sh — a LISTA DE GUARDAS do core, derivada num lugar só (core-only)
#
# POR QUE EXISTE (decisão do maestro de 2026-11-13, D_REVIEW_AUTO_WITH_FALLBACK_1113, no grafo
# docs/onion/graph/review-gate-saldo-2026-09.kg.yaml): o modo `auto` do revisor de IA do CI revisa SÓ o
# PR que toca GUARDA, e a lista de guardas é a MESMA que trava o merge da sessão (item 3 da delegação,
# D_DELEGATION_TRUST_MODEL_1113). Duas listas escritas à mão divergem em silêncio; por isso a derivação
# mora aqui, e os consumidores perguntam a este script em vez de copiar a lista:
#   · ops/review/review-mode-decide.sh  (a regra do `auto` e o campo `guard` do fallback)
#   · ops/pr-merge-verified.sh          (o resíduo independente exigido em fallback)
#   · o PR #1647 (feat/delegated-acts-1113) escreveu a mesma lista como regex no pr-merge-verified.sh
#     (`_PMV_GUARD_RE`); depois do merge dos dois, ele passa a usar este helper. Os caminhos que aquela
#     regex tem e o moat-targets.tsv de hoje ainda não tem entram na lista FIXA abaixo, marcados.
#
# ── A LISTA ──────────────────────────────────────────────────────────────────────────────────────────
# DERIVADA do ops/moat-targets.tsv (as linhas que não são comentário):
#   · classe `ato`    → a coluna 3 (o script cujo uso é o ato)
#   · classe `delega` → a coluna 3 (o script delegado)
#   · classe `deploy` → a coluna 4, quando é um script de ops/ (o wrapper do deploy)
# FIXA (as cercas que o tsv não descreve, porque não são alvo de deploy):
#   .claude/hooks/  .claude/settings.json  .claude/settings.local.json  docs/evolution/federation/members.yaml
#   .github/workflows/  ops/review/  .claude/validation/act-signature-check.sh  ops/sudoers/
#   ops/moat-targets.tsv (o próprio tsv: quem tira uma linha dele tira a guarda da lista)
#   ops/pr-merge-verified.sh  ops/bridge-backup.sh  ops/delegated-ops.sh (compat com a regex do #1647)
# Padrão terminado em `/` é PREFIXO (vale tudo abaixo); os outros são caminho EXATO.
#
# ── O QUE CONTA COMO "TOCAR" ─────────────────────────────────────────────────────────────────────────
# Todo caminho do diff: adicionado, modificado, REMOVIDO, e o rename pelos DOIS nomes (o antigo vem no
# `previous_filename` da API, ou do `--no-renames` do git, que parte o rename em remoção + adição).
# Mover um hook para docs/ continua tocando guarda.
#
# Uso:
#   bash ops/review/guard-paths.sh --pr <N> [--repo <dono/repo>]   arquivos do PR pela API (uma leitura paginada)
#   bash ops/review/guard-paths.sh --pr-json <arq>                  o mesmo, do JSON da API num arquivo (bancada)
#   bash ops/review/guard-paths.sh --files-from <arq|->             lista pronta, um caminho por linha
#   bash ops/review/guard-paths.sh --range <base>...<head> [--git-dir <dir>]   o diff do git
#   bash ops/review/guard-paths.sh --print-patterns                 a lista derivada, um padrão por linha
#   Opção comum: --targets <arq> (padrão: o ops/moat-targets.tsv ao lado deste script)
# Exit: 0 = toca guarda (stdout: os caminhos que casaram, únicos) · 1 = não toca · 2 = erro NOMEADO
#       (tsv ilegível, API ou diff que não leu). Erro nunca vira "não toca": quem chama decide o lado.
# =============================================================================
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS="${_HERE}/../moat-targets.tsv"
# o jq das duas leituras da API (a de verdade e a da bancada): o nome e, no rename, o nome antigo
_FILES_JQ='.[] | .filename, (.previous_filename // empty)'
FIXED_PATTERNS=(
  '.claude/hooks/'
  '.claude/settings.json'
  '.claude/settings.local.json'
  'docs/evolution/federation/members.yaml'
  '.github/workflows/'
  'ops/review/'
  '.claude/validation/act-signature-check.sh'
  'ops/sudoers/'
  'ops/moat-targets.tsv'
  'ops/pr-merge-verified.sh'
  'ops/bridge-backup.sh'
  'ops/delegated-ops.sh'
)

_die2() { printf 'guard-paths: %s\n' "$1" >&2; exit 2; }

_patterns() {
  [ -r "${TARGETS}" ] || _die2 "não li ${TARGETS} — sem o moat-targets.tsv a lista de guardas fica incompleta, e lista incompleta não vira 'não toca'"
  local derived
  derived="$(awk -F'\t' '
    /^[[:space:]]*#/ || NF < 3 { next }
    ($1 == "ato" || $1 == "delega") && $2 == "script" { print $3; next }
    $1 == "deploy" && NF >= 4 && $4 ~ /^ops\// { print $4 }' "${TARGETS}")" \
    || _die2 "não consegui derivar a lista de ${TARGETS}"
  [ -n "${derived}" ] || _die2 "${TARGETS} não rendeu nenhum script de ato, delega ou wrapper — tsv vazio ou com outra forma; não sigo com a lista só fixa"
  { printf '%s\n' "${FIXED_PATTERNS[@]}"; printf '%s\n' "${derived}"; } | awk 'NF && !seen[$0]++'
}

_match() { # stdin: caminhos ; $1: padrões (um por linha)
  awk -v pats="$1" '
    BEGIN { n = split(pats, P, "\n") }
    NF {
      for (i = 1; i <= n; i++) {
        p = P[i]; if (p == "") continue
        if (substr(p, length(p)) == "/") { if (index($0, p) == 1) { hit = 1; break } }
        else if ($0 == p) { hit = 1; break }
      }
      if (hit && !seen[$0]++) print $0
      hit = 0
    }'
}

MODE=""; ARG=""; REPO=""; GIT_DIR_ARG="."
while [ $# -gt 0 ]; do
  case "$1" in
    --pr|--pr-json|--files-from|--range) MODE="$1"; ARG="${2-}"; [ -n "${ARG}" ] || _die2 "$1 exige valor"; shift 2 ;;
    --print-patterns) MODE="$1"; shift ;;
    --repo) REPO="${2-}"; [ -n "${REPO}" ] || _die2 "--repo exige <dono/repo>"; shift 2 ;;
    --git-dir) GIT_DIR_ARG="${2-}"; shift 2 ;;
    --targets) TARGETS="${2-}"; shift 2 ;;
    -h|--help) sed -n '/^# Uso:/,/^# Exit:/p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) _die2 "argumento desconhecido '$1'" ;;
  esac
done
[ -n "${MODE}" ] || _die2 "diga de onde vêm os caminhos: --pr, --pr-json, --files-from, --range ou --print-patterns"

PATS="$(_patterns)" || exit 2
case "${MODE}" in
  --print-patterns) printf '%s\n' "${PATS}"; exit 0 ;;
  --pr)
    case "${ARG}" in *[!0-9]*) _die2 "--pr exige número, veio '${ARG}'" ;; esac
    if [ -z "${REPO}" ]; then
      REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" || REPO=""
      [ -n "${REPO}" ] || _die2 "não descobri o repo do PR #${ARG} (passe --repo <dono/repo>)"
    fi
    FILES="$(gh api "repos/${REPO}/pulls/${ARG}/files?per_page=100" --paginate --jq "${_FILES_JQ}" 2>/dev/null)" \
      || _die2 "não li os arquivos do PR #${ARG} em ${REPO} — sem eles não sei se toca guarda" ;;
  --pr-json)
    command -v jq >/dev/null 2>&1 || _die2 "jq ausente"
    FILES="$(jq -r "${_FILES_JQ}" "${ARG}" 2>/dev/null)" || _die2 "JSON ilegível em ${ARG}" ;;
  --files-from)
    if [ "${ARG}" = "-" ]; then FILES="$(cat)"; else
      [ -r "${ARG}" ] || _die2 "não li ${ARG}"; FILES="$(cat "${ARG}")"; fi ;;
  --range)
    FILES="$(git -C "${GIT_DIR_ARG}" -c core.quotepath=off diff --name-status --no-renames "${ARG}" -- 2>/dev/null)" \
      || _die2 "o diff ${ARG} não pôde ser lido em ${GIT_DIR_ARG}"
    FILES="$(printf '%s\n' "${FILES}" | cut -f2-)" ;;
esac

HITS="$(printf '%s\n' "${FILES}" | _match "${PATS}")"
[ -n "${HITS}" ] || exit 1
printf '%s\n' "${HITS}"
exit 0
