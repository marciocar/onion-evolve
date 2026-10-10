#!/usr/bin/env bash
# =============================================================================
# plugin-bundle-check.sh — as guardas de PLUGIN rodam sobre um BUNDLE MONTADO, não sobre o core
#
# O QUE   : recebe a FONTE (o core, ou a worktree destacada em origin/main da publicação) e um BUNDLE
#           (um diretório com plugins/<nome>/ e .claude-plugin/marketplace.json — o clone de
#           onion-plugins depois do materialize, ou um temporário da bancada) e roda nele as guardas
#           que julgam o ARTEFATO publicado:
#             · REGRA 61 (Fronteira de MOAT) — metade do RESULTADO: nenhum arquivo de adoção, federação,
#               motor do marketplace nem *.kg.yaml dentro de um plugin montado. A metade da DECLARAÇÃO
#               (os manifestos) segue no lint de PR, onde custa nada e não exige montar;
#             · REGRA 72 (Namespace de comando em plugin é /<plugin>:<cmd>, nunca o do core);
#             · REGRA 73 (Hook empacotado resolve no plugin instalado);
#             · REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca);
#             · REGRA 75 (Link markdown relativo dentro de plugin resolve no plugin);
#             · REGRA 76 (marketplace.json da raiz aponta o repo PÚBLICO e é projeção dos manifestos) — metade da PUBLICAÇÃO: o catálogo do bundle tem source relativo para um plugin
#               que existe, e as entradas dele são as MESMAS da raiz do core (fora o `source`). A metade
#               da raiz (aponta o público, projeção dos manifestos) segue no lint de PR;
#             · REGRA 77 (Contrato de dependência entre plugins);
#             · REGRA 79 (Artefato de plugin não publica o repo-fonte PRIVADO como endereço).
#
# POR QUÊ : F4 das portas (SAC-93, 2026-10-10, D_MATRIZ_DE_PORTAS_2026_10). Até a F4 o core VERSIONAVA
#           `plugins/` e estas guardas rodavam no lint de todo PR sobre essa cópia — o que obrigava cada
#           PR que tocasse uma fonte bundlada a regenerar e commitar o plugin (o auto-fix do pre-commit,
#           a REGRA 19 (Plugins de vertical sincronizados com as fontes), conflitos de projeção no rebase). O `plugins/` saiu do core. As guardas não
#           sumiram: mudaram de OBJETO. Julgam o bundle que vai a público, na hora em que ele vai
#           (`ops/publish-door.sh onion-plugins`, passo 5d), e a bancada as exercita sobre um bundle
#           TEMPORÁRIO montado das fontes vivas (família plugin_bundle) — nunca a árvore viva.
#
# COMO    : monta uma raiz temporária com `.claude` → link para a FONTE e cópias de `plugins/` e
#           `.claude-plugin/` do BUNDLE, e chama os helpers de sempre com essa raiz. Os helpers não
#           mudaram: eles sempre leram `<raiz>/plugins` e `<raiz>/.claude/...`.
#           A CATRACA da REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca)
#           roda em dois lugares (achado I2 da passada adversarial da F4, que mediu que ela tinha sumido):
#           no lint de PR (check_plugin_bare_path_ratchet: o baseline não cresce contra origin/main) e
#           aqui, com --prev-baseline <arquivo> = o baseline do pin PUBLICADO antes (o publish-door.sh o
#           extrai do provenance do clone). Sem --prev-baseline a raiz temporária não tem histórico e a
#           catraca daqui não tem com o que comparar; o baseline ainda separa passivo (SOFT) de novo (HARD).
#
# OS CABEÇALHOS das regras que moram AQUI (saíram do lint-artifacts.sh na F4), no formato que o hook
# rule-title-in-prose.sh lê para sugerir o título — número é chave, título é significado:
# REGRA 72 — Namespace de comando em plugin é /<plugin>:<cmd>, nunca o do core [HARD]
# REGRA 73 — Hook empacotado resolve no plugin instalado [HARD]
# REGRA 74 — Caminho .claude/ NU dentro de plugin só resolve no core, com catraca [HARD + SOFT]
# REGRA 75 — Link markdown relativo dentro de plugin resolve no plugin [HARD]
# REGRA 77 — Contrato de dependência entre plugins [HARD + SOFT]
# REGRA 79 — Artefato de plugin não publica o repo-fonte PRIVADO como endereço [HARD]
#
# USO     : plugin-bundle-check.sh --source <FONTE> --bundle <BUNDLE> [--format text|tsv] [--prev-baseline <arquivo>]
# SAÍDA   : tsv: SEV<TAB>REGRA<TAB>classe<TAB>caminho<TAB>mensagem · text: legível + sumário
# rc      : 0 nenhum HARD · 1 há HARD · 2 não pude medir (bundle sem plugins/, fonte inválida,
#           helper ausente, python ausente) — "não medi" nunca vira "limpo".
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC=""; BUNDLE=""; FORMAT="text"
while [ $# -gt 0 ]; do
  case "$1" in
    --source) SRC="${2:-}"; shift 2 ;;
    --bundle) BUNDLE="${2:-}"; shift 2 ;;
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --prev-baseline) export ONION_BAREPATH_PREV_FILE="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "plugin-bundle-check: argumento desconhecido '$1'" >&2; exit 2 ;;
  esac
done
[ -n "${SRC}" ] && [ -d "${SRC}/.claude" ] || { echo "plugin-bundle-check: --source sem .claude/: '${SRC}'" >&2; exit 2; }
[ -n "${BUNDLE}" ] && [ -d "${BUNDLE}/plugins" ] || { echo "plugin-bundle-check: --bundle sem plugins/: '${BUNDLE}' — nada montado não é bundle limpo" >&2; exit 2; }
ls -d "${BUNDLE}"/plugins/*/ >/dev/null 2>&1 || { echo "plugin-bundle-check: ${BUNDLE}/plugins/ está vazio — nada montado não é bundle limpo" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "plugin-bundle-check: python3 ausente — os helpers não rodam" >&2; exit 2; }
SRC="$(cd "${SRC}" && pwd)"; BUNDLE="$(cd "${BUNDLE}" && pwd)"

R="$(mktemp -d)"; ROWS="$(mktemp)"
trap 'rm -rf "${R}" "${ROWS}"' EXIT
ln -s "${SRC}/.claude" "${R}/.claude"
cp -R "${BUNDLE}/plugins" "${R}/plugins"
[ -d "${BUNDLE}/.claude-plugin" ] && cp -R "${BUNDLE}/.claude-plugin" "${R}/.claude-plugin"

_row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >> "${ROWS}"; }
MEASURE_FAIL=""

# ── helpers delegados (72, 73, 74, 75, 77): contrato TSV SEV<TAB>classe<TAB>caminho<TAB>msg ──────
_delegate() {  # $1 regra · $2 script
  local rule="$1" h="${HERE}/$2" out rc=0 sev cls path msg
  [ -f "${h}" ] || { MEASURE_FAIL="${MEASURE_FAIL} $2(ausente)"; return 0; }
  out="$(bash "${h}" "${R}" --format tsv 2>/dev/null)" || rc=$?
  # Os helpers saem 0 com ou sem achado; rc ≠ 0 é helper que QUEBROU — não mediu.
  [ "${rc}" -eq 0 ] || { MEASURE_FAIL="${MEASURE_FAIL} $2(rc=${rc})"; return 0; }
  while IFS=$'\t' read -r sev cls path msg; do
    [ -n "${sev}" ] || continue
    _row "${sev}" "${rule}" "${cls}" "${path}" "${msg}"
  done <<< "${out}"
  return 0
}
_delegate 72 plugin-namespace-check.sh
_delegate 73 plugin-hooks-check.sh
_delegate 74 plugin-bare-path-check.sh
_delegate 75 plugin-dead-link-check.sh
_delegate 77 plugin-deps-check.sh

# ── REGRA 61 (Fronteira de MOAT: manifesto de plugin publicável não vaza adoção, federação nem grafo privado), metade do RESULTADO: moat no que foi MONTADO ───────────────────────────────────────
# As MESMAS listas da check_moat_boundary (lint-artifacts.sh): basename de adoção/federação/motor do
# marketplace, e caminho de utils de adoção/federação/marketplace/co-evolução, skill onion-publish e
# qualquer *.kg.yaml. No bundle os utils moram em plugins/<p>/utils/<rel>, então o caminho casa igual.
MOAT_BASE='^(adopt|federation-.*|co-(announce|deliver|evolve|relay)|co-evolution-inbox-check|personality-sync|decouple-source|assemble-plugin|generate-marketplace|materialize-marketplace-repo)\.(md|sh)$'
MOAT_PATH='(/utils/adopt/|/utils/marketplace/|/utils/federation/|/utils/federation-transport/|/utils/co-evolution/|/skills/onion-publish/|\.kg\.yaml$)'
while IFS= read -r f; do
  [ -n "${f}" ] || continue
  rel="${f#${R}/}"; bn="$(basename "${f}")"
  if grep -qE "${MOAT_BASE}" <<< "${bn}" || grep -qE "${MOAT_PATH}" <<< "/${rel}"; then
    _row "HARD" "61" "moat-no-bundle" "${rel}" "plugin MONTADO carrega fonte de adoção/federação/motor do marketplace/grafo privado — a porta é pública; estreite o manifesto"
  fi
done < <(find "${R}/plugins" -type f 2>/dev/null | LC_ALL=C sort)

# ── REGRA 79 (Artefato de plugin não publica o repo-fonte PRIVADO como endereço): o repo-fonte PRIVADO nunca como endereço ───────────────────────────────────────────
# O slug privado é DERIVADO do remote `origin` da FONTE (quem forkar herda a guarda). provenance.json
# é a única isenção: lá o slug é marca de origem, não link.
src_slug="$(git -C "${SRC}" remote get-url origin 2>/dev/null | sed -E 's#(git@|https://)([^/:]+)[/:]##; s#\.git$##' || true)"
if [ -n "${src_slug}" ] && [ "${ONION_SOURCE_IS_PRIVATE:-1}" = "1" ]; then
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    case "${f}" in */provenance.json) continue ;; esac
    while IFS= read -r h; do
      [ -n "${h}" ] || continue
      _row "HARD" "79" "404-privado" "${f#${R}/}" "artefato público cita o repo-fonte PRIVADO como endereço: ${h} — a casa e o canal vêm de public-face.sh"
    done < <(grep -oE "github\.com/${src_slug}[^\"'\'')* ]*" "${f}" 2>/dev/null | sort -u)
  done < <( { find "${R}/plugins" -type f \( -name '*.md' -o -name '*.json' \) 2>/dev/null
              [ -f "${R}/.claude-plugin/marketplace.json" ] && printf '%s\n' "${R}/.claude-plugin/marketplace.json"; } | LC_ALL=C sort )
fi

# ── REGRA 76 (marketplace.json da raiz aponta o repo PÚBLICO e é projeção dos manifestos), metade da PUBLICAÇÃO: catálogo do bundle × raiz do core ────────────────────────────
GEN="${SRC}/.claude/utils/marketplace/generate-marketplace.sh"
if [ ! -f "${R}/.claude-plugin/marketplace.json" ]; then
  _row "HARD" "76" "catalogo-ausente" ".claude-plugin/marketplace.json" "o bundle não tem catálogo — o marketplace público não instala nada"
elif [ ! -f "${GEN}" ]; then
  MEASURE_FAIL="${MEASURE_FAIL} generate-marketplace.sh(ausente)"
else
  _rootj="$(mktemp)"
  if bash "${GEN}" "${SRC}" --from-manifests > "${_rootj}" 2>/dev/null; then
    python3 - "${R}" "${_rootj}" >> "${ROWS}" <<'PY' || MEASURE_FAIL="${MEASURE_FAIL} paridade-do-catalogo(python)"
import json, os, sys
root, rootj = sys.argv[1], sys.argv[2]
def rows(sev, cls, path, msg): print("\t".join([sev, "76", cls, path, msg]))
try:
    b = json.load(open(os.path.join(root, ".claude-plugin", "marketplace.json"), encoding="utf-8"))
except Exception as e:
    rows("HARD", "catalogo-invalido", ".claude-plugin/marketplace.json", "JSON inválido: %s" % e); sys.exit(0)
c = json.load(open(rootj, encoding="utf-8"))
bp = {p.get("name"): p for p in (b.get("plugins") or [])}
cp = {p.get("name"): p for p in (c.get("plugins") or [])}
for n, p in sorted(bp.items()):
    s = p.get("source")
    if not (isinstance(s, str) and s == "./plugins/%s" % n and os.path.isdir(os.path.join(root, "plugins", n))):
        rows("HARD", "source-do-bundle", ".claude-plugin/marketplace.json", "entrada '%s' com source %r — no bundle o source é ./plugins/<nome> e o diretório existe" % (n, s))
for n in sorted(set(cp) - set(bp)):
    rows("HARD", "sem-plugin-no-bundle", ".claude-plugin/marketplace.json", "a raiz do core lista '%s' e o bundle não o publica — o instalador da raiz cairia num caminho inexistente no público" % n)
for n in sorted(set(bp) - set(cp)):
    rows("SOFT", "so-no-bundle", ".claude-plugin/marketplace.json", "o bundle publica '%s' e a raiz do core não o lista (plugin preservado pelo dono do marketplace?)" % n)
for n in sorted(set(bp) & set(cp)):
    x = {k: v for k, v in bp[n].items() if k != "source"}
    y = {k: v for k, v in cp[n].items() if k != "source"}
    if x != y:
        diff = sorted(k for k in set(x) | set(y) if x.get(k) != y.get(k))
        rows("HARD", "entrada-diverge", ".claude-plugin/marketplace.json", "entrada '%s' difere da raiz do core em %s — as duas saem do mesmo emissor; regenere a raiz (marketplace-root-check.sh --write)" % (n, ",".join(diff)))
PY
  else
    MEASURE_FAIL="${MEASURE_FAIL} generate-marketplace--from-manifests(rc)"
  fi
  rm -f "${_rootj}"
fi

# ── veredito ─────────────────────────────────────────────────────────────────────────────────────
HARD_N="$(awk -F'\t' '$1=="HARD"' "${ROWS}" | grep -c . || true)"
SOFT_N="$(awk -F'\t' '$1=="SOFT"' "${ROWS}" | grep -c . || true)"
if [ "${FORMAT}" = "tsv" ]; then
  cat "${ROWS}"
else
  awk -F'\t' '{printf "%s REGRA %s [%s] %s: %s\n", $1, $2, $3, $4, $5}' "${ROWS}"
  echo "plugin-bundle-check: ${HARD_N} HARD · ${SOFT_N} SOFT · $(ls -d "${R}"/plugins/*/ | grep -c .) plugin(s) montado(s)"
fi
if [ -n "${MEASURE_FAIL}" ]; then
  echo "plugin-bundle-check: NÃO MEDIDO —${MEASURE_FAIL}" >&2
  exit 2
fi
[ "${HARD_N}" -eq 0 ] || exit 1
exit 0
