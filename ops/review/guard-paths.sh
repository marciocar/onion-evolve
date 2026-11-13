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
# ── A LISTA (refeita na 2ª passada do refutador do #1652: a 1ª regredia e deixava cercas de fora) ─────────
# DERIVADA do ops/moat-targets.tsv, o da ÁRVORE somado ao de origin/main (mais caminho é mais estrito, como o
# #1647 faz; um PR que tire uma linha do tsv não sai da lista por isso):
#   · classes `ato`, `delega` e `fecho` → a coluna 3. `fecho` é o FECHO TRANSITIVO: o que os atos EXECUTAM
#     (o #1647 o constrói, e a REGRA 117 confere que está completo). Quando ele entrar na main, entra aqui sozinho.
#   · classes `deploy` e `relogio` → a coluna 4, quando é um script de ops/ (o wrapper)
# FIXA:
#   · as cercas que o tsv não descreve: .claude/hooks/ .claude/settings.json .claude/settings.local.json
#     docs/evolution/federation/members.yaml .github/workflows/ .githooks/ ops/review/ ops/sudoers/
#     ops/moat-targets.tsv (o próprio tsv)
#   · .claude/validation/ INTEIRO: o que o lint barra é guarda (inclui act-signature-check.sh, a catraca da
#     REGRA 117, review-artifact-check.sh, o único que compara reviewed_diff_sha256 com o diff, e review-verdict.sh)
#   · a SENSITIVE_PATHS antiga do review-mode-decide.sh, somada: ops/update-* ops/deploy-* ops/mcp-*
#     ops/pr-merge-verified.sh ops/merge-serial.sh ops/apply-ruleset-main.sh
#   · o fecho que o tsv de hoje ainda não traz (o do #1647, até ele entrar): ops/pr-finalize.sh
#     ops/materialize-door.sh ops/merge-serial.sh .claude/utils/forge/post-review-comment.sh (o que o workflow do
#     revisor executa) e ops/bridge-backup.sh ops/bridge-hardening.sh ops/chat-runner.sh ops/delegated-ops.sh
# Padrão terminado em `/` é PREFIXO; padrão com `*` é GLOB (o `*` casa também `/`, como o `case` da lista antiga); o resto é EXATO.
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
#   --all (com --pr/--pr-json/--files-from/--range): imprime TODOS os caminhos lidos (nomes antigos inclusos), sem filtrar,
#         exit 0 — o merge-verified mede a maquinaria do revisor sobre o PR inteiro com a mesma leitura
#   Opção comum: --targets <arq> (repetível; os tsv se SOMAM). Sem --targets: o ops/moat-targets.tsv ao lado deste
#                script mais o de origin/main do repo dele (git show). Pelo menos um tem de ser legível.
# Exit: 0 = toca guarda (stdout: os caminhos que casaram, únicos) · 1 = não toca · 2 = erro NOMEADO
#       (tsv ilegível, API ou diff que não leu). Erro nunca vira "não toca": quem chama decide o lado.
# =============================================================================
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGETS=()
# o jq das duas leituras da API (a de verdade e a da bancada): o nome e, no rename, o nome antigo
_FILES_JQ='.[] | .filename, (.previous_filename // empty)'
# o mesmo, ETIQUETADO, para contar os arquivos contra o changed_files (o nome antigo não é arquivo a mais)
_FILES_JQ_TAGGED='.[] | ("F\t" + .filename), (.previous_filename // empty | "P\t" + .)'
MAX_API_FILES=3000
FIXED_PATTERNS=(
  '.claude/hooks/'
  '.claude/settings.json'
  '.claude/settings.local.json'
  'docs/evolution/federation/members.yaml'
  '.github/workflows/'
  '.githooks/'
  'ops/review/'
  'ops/sudoers/'
  'ops/moat-targets.tsv'
  '.claude/validation/'
  'ops/update-*'
  'ops/deploy-*'
  'ops/mcp-*'
  'ops/pr-merge-verified.sh'
  'ops/merge-serial.sh'
  'ops/apply-ruleset-main.sh'
  'ops/pr-finalize.sh'
  'ops/materialize-door.sh'
  '.claude/utils/forge/post-review-comment.sh'
  'ops/bridge-backup.sh'
  'ops/bridge-hardening.sh'
  'ops/chat-runner.sh'
  'ops/delegated-ops.sh'
)

_die2() { printf 'guard-paths: %s\n' "$1" >&2; exit 2; }

_tsv_all() { # os tsv somados: os passados por --targets, ou o da árvore + o de origin/main
  local t ok=0
  if [ "${#TARGETS[@]}" -gt 0 ]; then
    for t in "${TARGETS[@]}"; do [ -r "${t}" ] && { cat "${t}"; ok=1; }; done
  else
    [ -r "${_HERE}/../moat-targets.tsv" ] && { cat "${_HERE}/../moat-targets.tsv"; ok=1; }
    git -C "${_HERE}" show origin/main:ops/moat-targets.tsv 2>/dev/null && ok=1
  fi
  [ "${ok}" -eq 1 ]
}

_patterns() {
  local all derived
  all="$(_tsv_all)" || _die2 "não li nenhum moat-targets.tsv (${TARGETS[*]:-árvore e origin/main}) — sem ele a lista de guardas fica incompleta, e lista incompleta não vira 'não toca'"
  derived="$(printf '%s\n' "${all}" | awk -F'\t' '
    /^[[:space:]]*#/ || NF < 3 { next }
    ($1 == "ato" || $1 == "delega" || $1 == "fecho") && $2 == "script" { print $3; next }
    ($1 == "deploy" || $1 == "relogio") && NF >= 4 && $4 ~ /^ops\// { print $4 }')"
  [ -n "${derived}" ] || _die2 "o moat-targets.tsv não rendeu nenhum script de ato, delega, fecho ou wrapper — tsv vazio ou com outra forma; não sigo com a lista só fixa"
  { printf '%s\n' "${FIXED_PATTERNS[@]}"; printf '%s\n' "${derived}"; } | awk 'NF && !seen[$0]++'
}

_match() { # stdin: caminhos ; $1: padrões (um por linha). Prefixo (`/` no fim), glob (`*` casa até `/`) ou exato.
  awk -v pats="$1" '
    function glob2re(g,   r, i, c) {
      r = "^"
      for (i = 1; i <= length(g); i++) {
        c = substr(g, i, 1)
        if (c == "*") r = r ".*"
        else if (c ~ /[.+?()|{}^$\[\]\\]/) r = r "\\" c
        else r = r c
      }
      return r "$"
    }
    BEGIN { n = split(pats, P, "\n"); for (i = 1; i <= n; i++) if (index(P[i], "*") > 0) R[i] = glob2re(P[i]) }
    NF {
      for (i = 1; i <= n; i++) {
        p = P[i]; if (p == "") continue
        if (i in R) { if ($0 ~ R[i]) { hit = 1; break } }
        else if (substr(p, length(p)) == "/") { if (index($0, p) == 1) { hit = 1; break } }
        else if ($0 == p) { hit = 1; break }
      }
      if (hit && !seen[$0]++) print $0
      hit = 0
    }'
}

MODE=""; ARG=""; REPO=""; GIT_DIR_ARG="."; ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --pr|--pr-json|--files-from|--range) MODE="$1"; ARG="${2-}"; [ -n "${ARG}" ] || _die2 "$1 exige valor"; shift 2 ;;
    --print-patterns) MODE="$1"; shift ;;
    --all) ALL=1; shift ;;
    --repo) REPO="${2-}"; [ -n "${REPO}" ] || _die2 "--repo exige <dono/repo>"; shift 2 ;;
    --git-dir) GIT_DIR_ARG="${2-}"; shift 2 ;;
    --targets) TARGETS+=("${2-}"); shift 2 ;;
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
    # TRUNCAMENTO (3ª passada do refutador do #1652, X2): `pulls/<n>/files` para em 3000 arquivos SEM erro. A leitura só
    # vale se a contagem bater com o `changed_files` do PR, e PR com mais de 3000 arquivos não se mede por aqui: rc 2.
    _CHANGED="$(gh api "repos/${REPO}/pulls/${ARG}" --jq '.changed_files' 2>/dev/null)" \
      || _die2 "não li o changed_files do PR #${ARG} em ${REPO} — sem ele não sei se a lista de arquivos veio inteira"
    case "${_CHANGED}" in ''|*[!0-9]*) _die2 "changed_files ilegível ('${_CHANGED}') no PR #${ARG}" ;; esac
    [ "${_CHANGED}" -le "${MAX_API_FILES}" ] \
      || _die2 "o PR #${ARG} muda ${_CHANGED} arquivos, acima do teto de ${MAX_API_FILES} que a API lista — não meço PR truncado"
    _RAW="$(gh api "repos/${REPO}/pulls/${ARG}/files?per_page=100" --paginate --jq "${_FILES_JQ_TAGGED}" 2>/dev/null)" \
      || _die2 "não li os arquivos do PR #${ARG} em ${REPO} — sem eles não sei se toca guarda"
    # linha `F<TAB>nome` = um arquivo; `P<TAB>nome` = o nome antigo de um rename; linha sem etiqueta conta como arquivo
    _READ="$(printf '%s\n' "${_RAW}" | awk -F'\t' 'NF && !($1 == "P" && NF == 2) {n++} END {print n+0}')"
    [ "${_READ}" -eq "${_CHANGED}" ] \
      || _die2 "li ${_READ} arquivo(s) do PR #${ARG}, e o PR declara changed_files=${_CHANGED} — lista truncada ou divergente; não meço pela metade"
    FILES="$(printf '%s\n' "${_RAW}" | awk -F'\t' 'NF == 2 && ($1 == "F" || $1 == "P") {print $2; next} NF {print}')" ;;
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

if [ "${ALL}" -eq 1 ]; then printf '%s\n' "${FILES}" | awk 'NF && !seen[$0]++'; exit 0; fi
HITS="$(printf '%s\n' "${FILES}" | _match "${PATS}")"
[ -n "${HITS}" ] || exit 1
printf '%s\n' "${HITS}"
exit 0
