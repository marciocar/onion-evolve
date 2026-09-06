#!/usr/bin/env bash
# kg-seal-exception.sh — decide, POR PREDICADO, se um flip de status de verdade dispensa o selo humano.
#
# POR QUE EXISTE. A tabela de selagem do `/onion:drive` reserva ao maestro todo flip `→refuted`/
# `→superseded` (`onion-drive-doctrine.md` §4). A doutrina ganhou em 2026-09-06 uma EXCEÇÃO NOMEADA
# (§4.1): auto-refutação de nó que o maestro NUNCA SELOU — o nó nasceu e caiu no MESMO PR, então o
# par nó+refutação chega a ele como uma proposta só. Exceção em prosa é convite a julgar caso a caso;
# este script a torna mecânica, e por isso ela pode existir sem virar fresta.
#
# ⚠️ ESTA É UMA GUARDA QUE **LIBERA**, e o risco dela é assimétrico: um PARA indevido custa uma
# pergunta ao maestro; um AUTO indevido industrializa o carimbo-automático que a postura AUDIT existe
# para matar. Por isso tudo aqui é fail-closed e a bancada aperta o lado do AUTO, não o do PARA.
#
# ⚠️ A 1ª VERSÃO DESTE SCRIPT (mesmo dia) FOI REPROVADA POR TRÊS REVISORES ADVERSARIAIS COM SETE
#    CAMINHOS DE AUTO INDEVIDO MEDIDOS. Cada cura abaixo tem o ataque que a pagou:
#      · id entre aspas / aresta FORJADA dentro de um `label: |` / campo de medição citado em bloco
#        literal → o parser era regex+awk sobre o texto. CURA ESTRUTURAL: o grafo passa a ser lido
#        por YAML de verdade (PyYAML), que enxerga a ESTRUTURA e não o texto. Sem PyYAML, PARA.
#      · grafo RENOMEADO ou nó MOVIDO de um `.kg.yaml` para outro → a busca era presa a UM path.
#        CURA: a busca varre TODOS os `*.kg.yaml` da base (árvore e história).
#      · `origin/main` LOCAL DESATUALIZADO → o ref local era tratado como o estado do remoto.
#        CURA: com remote configurado, a base default é conferida contra `git ls-remote`; divergiu
#        ou não deu para conferir, PARA. Base explícita (`--base`) é decisão de quem chama.
#      · clone RASO (`--depth 1`) → a história truncada dizia "nunca existiu". CURA: repo shallow, PARA.
#      · `--base` sem valor → laço infinito mudo. CURA: o parser de flags valida a aridade.
#
# AS QUATRO PRECONDIÇÕES DO §4.1 — e o que este script alcança de cada uma:
#   (1) NUNCA-SELADO   MECANIZADA — o id não está em NENHUM `*.kg.yaml` da base nem na história dela
#   (2) MEDIÇÃO        PARCIAL    — exige `verified_at`+`verified_against` com valor real (YAML), mas
#                                   NENHUM script sabe se o texto descreve uma medição que ocorreu
#   (3) AUFHEBUNG      MECANIZADA — aresta REFUTES/SUPERSEDES real → alvo reconciliado
#   (4) DECLARADO      **NÃO MECANIZADA, E NÃO MECANIZÁVEL AQUI** — nomear o flip no STATE.md é ato
#                                   humano; exit 0 NUNCA significa que a (4) foi cumprida
# Um exit 0 diz "(1) e (3) provadas, (2) no que dá para provar" — não "pode selar sozinho".
#
# Uso : bash ${CLAUDE_PLUGIN_ROOT}/validation/kg-seal-exception.sh <grafo.kg.yaml> <NODE_ID> [--base <ref>] [--quiet]
# Exit: 0 = AUTO (dispensa selo) · 1 = PARA (precisa do maestro) · 2 = erro de uso.
set -uo pipefail

FILE=""; NODE=""; BASE=""; QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --base)  [ $# -ge 2 ] || { echo "ERRO: --base exige um valor" >&2; exit 2; }; BASE="$2"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -*)      echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *)       if [ -z "${FILE}" ]; then FILE="$1"; elif [ -z "${NODE}" ]; then NODE="$1"; else
               echo "ERRO: argumento extra '$1'" >&2; exit 2; fi; shift ;;
  esac
done
[ -n "${FILE}" ] && [ -n "${NODE}" ] || {
  echo "uso: kg-seal-exception.sh <grafo.kg.yaml> <NODE_ID> [--base <ref>] [--quiet]" >&2; exit 2; }
BASE_EXPLICIT=1; [ -n "${BASE}" ] || { BASE="origin/main"; BASE_EXPLICIT=0; }

say()  { [ "${QUIET}" -eq 1 ] || printf '%s\n' "$*"; }
halt() { say "PARA — ${1}"; say "  → o maestro sela este flip (doutrina do drive §4; a exceção §4.1 NÃO se aplica)"; exit 1; }

[ -f "${FILE}" ] || halt "grafo ausente: ${FILE}"
command -v git     >/dev/null 2>&1 || halt "git indisponível — não dá para provar (1) NUNCA-SELADO"
command -v python3 >/dev/null 2>&1 || halt "python3 indisponível — sem leitura YAML de verdade não se libera selo"
python3 -c 'import yaml' 2>/dev/null || halt "PyYAML ausente — o parser de texto já produziu AUTO indevido; sem YAML real, PARA"
git rev-parse --git-dir >/dev/null 2>&1 || halt "fora de um repositório git — (1) não é verificável"
git rev-parse --verify --quiet "${BASE}" >/dev/null 2>&1 || halt "base irresolvível: ${BASE}"

# ── FRESCOR DA BASE — um ref local velho MEDE ERRADO, e medir errado não é "não medir" ───────────
[ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)" = "false" ] \
  || halt "repositório RASO (shallow) — a história truncada faria um nó selado parecer novo"
if [ "${BASE_EXPLICIT}" -eq 0 ]; then
  _remote="${BASE%%/*}"; _branch="${BASE#*/}"
  git remote get-url "${_remote}" >/dev/null 2>&1 \
    || halt "base default '${BASE}' sem remote '${_remote}' configurado — passe --base explicitamente"
  _rem_sha="$(git ls-remote "${_remote}" "refs/heads/${_branch}" 2>/dev/null | awk 'NR==1{print $1}')"
  [ -n "${_rem_sha}" ] || halt "não deu para consultar '${_remote}' (offline?) — base não provada fresca"
  [ "${_rem_sha}" = "$(git rev-parse "${BASE}")" ] \
    || halt "'${BASE}' local está DESATUALIZADO vs o remoto — rode 'git fetch ${_remote}' antes (um nó já mergeado apareceria como novo)"
fi

# ── (1) NUNCA-SELADO — em TODOS os grafos da base: a árvore E a história ─────────────────────────
# ⚠️ NADA DE VEREDITO ATRAVÉS DE PIPE (`produtor | grep -q` é corrida sob pipefail: o leitor fecha no
#    1º match, o escritor toma EPIPE e o pipeline devolve FALHA com o padrão PRESENTE — aqui "falha"
#    significaria "nunca esteve lá", ou seja, AUTO por acidente). Conteúdo em variável, sempre.
_ID_IN_YAML='
import sys, yaml
node = sys.argv[1]
try:
    doc = yaml.safe_load(sys.stdin.read()) or {}
except Exception:
    sys.exit(3)                      # ilegível: quem chama decide (fail-closed)
for n in (doc.get("nodes") or []):
    if isinstance(n, dict) and str(n.get("id","")).strip() == node:
        sys.exit(0)
sys.exit(1)
'
_DEGRADED=""
_base_graphs="$(git ls-tree -r --name-only "${BASE}" 2>/dev/null | grep -E '\.kg\.yaml$' || true)"
while IFS= read -r g; do
  [ -n "${g}" ] || continue
  _blob="$(git show "${BASE}:${g}" 2>/dev/null || true)"
  [ -n "${_blob}" ] || continue
  printf '%s' "${_blob}" | python3 -c "${_ID_IN_YAML}" "${NODE}"
  case $? in
    0) halt "(1) o nó '${NODE}' JÁ EXISTE em ${BASE} (${g}) — o maestro o selou; flip é dele" ;;
    3) # ⚠️ LEITURA DEGRADADA, NUNCA DISPENSA. Medido 2026-09-06: QUATRO grafos do corpus são aceitos
       #    pelo radar (awk sobre texto) e REJEITADOS pelo PyYAML — erro de aspas/escape dentro de
       #    `label:`. Recusar tudo por causa deles tornaria esta guarda inútil no repo inteiro (o que
       #    é um fail-closed que ninguém usa, e guarda que ninguém usa não protege). Recusar só o que
       #    IMPORTA: varre-se o blob como TEXTO atrás do id. O texto SUPER-inclui (acha o id até em
       #    prosa), e super-incluir aqui erra para o lado do PARA — a direção segura.
       if grep -qF -- "${NODE}" <<< "${_blob}"; then
         halt "(1) '${g}' em ${BASE} não é YAML legível E menciona '${NODE}' — não se libera selo sobre leitura degradada"
       fi
       _DEGRADED="${_DEGRADED}${_DEGRADED:+, }${g}" ;;
  esac
done <<< "${_base_graphs}"

_hist="$(git log --format='%H' -S"id: ${NODE}" "${BASE}" -- '*.kg.yaml' 2>/dev/null || true)"
if [ -n "${_hist}" ]; then
  halt "(1) o nó '${NODE}' existiu na história de ${BASE} ($(printf '%s\n' "${_hist}" | wc -l) commit(s), em algum .kg.yaml) — já passou pelo maestro"
fi

# ── (2) e (3) — lidos por YAML de VERDADE, nunca por texto ───────────────────────────────────────
_FACTS='
import sys, yaml
node = sys.argv[1]
try:
    doc = yaml.safe_load(open(sys.argv[2], encoding="utf-8").read()) or {}
except Exception as e:
    print("ILEGIVEL\t%s" % str(e).replace("\n", " ")[:120]); sys.exit(0)
nodes = {str(n.get("id","")).strip(): n for n in (doc.get("nodes") or []) if isinstance(n, dict)}
if node not in nodes:
    print("SEM-ALVO\t"); sys.exit(0)
src = kind = None
for e in (doc.get("edges") or []):
    if not isinstance(e, dict): continue
    if str(e.get("to","")).strip() == node and str(e.get("edge_type","")).strip() in ("REFUTES","SUPERSEDES"):
        src, kind = str(e.get("from","")).strip(), str(e.get("edge_type","")).strip(); break
if src is None:
    print("SEM-ARESTA\t"); sys.exit(0)
if src not in nodes:
    print("FONTE-AUSENTE\t%s" % src); sys.exit(0)
def val(n, k):
    v = n.get(k, None)
    return "" if v is None else str(v).strip()
print("OK\t%s\t%s\t%s\t%s\t%s" % (str(nodes[node].get("status","")).strip(), src, kind,
                                  val(nodes[src], "verified_at"), val(nodes[src], "verified_against")))
'
_facts="$(python3 -c "${_FACTS}" "${NODE}" "${FILE}" 2>/dev/null || true)"
[ -n "${_facts}" ] || halt "não deu para ler ${FILE} como YAML — sem leitura estrutural não se libera selo"
IFS=$'\t' read -r _tag _f1 _f2 _f3 _f4 _f5 <<< "${_facts}"
case "${_tag}" in
  ILEGIVEL)      halt "${FILE} não é YAML válido (${_f1}) — o radar aceita texto que o YAML rejeita; aqui vale o YAML" ;;
  SEM-ALVO)      halt "(3) o alvo '${NODE}' não está no grafo ${FILE}" ;;
  SEM-ARESTA)    halt "(3) nenhuma aresta REFUTES/SUPERSEDES aponta para '${NODE}' — apendar solto quebra o --integrity" ;;
  FONTE-AUSENTE) halt "(3) a aresta parte de '${_f1}', que não é nó deste grafo" ;;
  OK)            : ;;
  *)             halt "leitura do grafo devolveu forma inesperada — fail-closed" ;;
esac
TARGET_STATUS="${_f1}"; SRC="${_f2}"; KIND="${_f3}"; V_AT="${_f4}"; V_AGAINST="${_f5}"

case "${TARGET_STATUS}" in
  refuted|superseded) : ;;
  *) halt "(3) o alvo '${NODE}' está '${TARGET_STATUS:-<sem status>}' — a Aufhebung não foi aplicada" ;;
esac

# ⚠️ TETO DECLARADO da (2): isto separa CAMPO VAZIO de campo preenchido. NÃO separa medição de
#    opinião — nenhum script sabe se `verified_against` descreve algo que de fato rodou. A lista de
#    placeholders abaixo é guarda-por-lista, a classe que nesta casa falha pelo VOCABULÁRIO; ela
#    reduz o descuido, não fecha a fraude. Quem fecha é o maestro lendo o checkpoint.
_is_placeholder() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    ""|null|none|nil|tbd|todo|tba|"n/a"|na|"?"|-|"--"|pendente|"a definir"|"a medir"|xxx) return 0 ;;
    *) return 1 ;;
  esac
}
_is_placeholder "${V_AT}"      && halt "(2) '${SRC}' não traz verified_at com valor real — sem medição executada não há refutação, há opinião"
_is_placeholder "${V_AGAINST}" && halt "(2) '${SRC}' não traz verified_against com valor real — o campo tem de dizer COMO se mediu"

# ── (4 do script / dentro da (3) da doutrina) INTEGRIDADE — o radar revisa a própria reconciliação ─
_RADAR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kg-radar.sh"
[ -f "${_RADAR}" ] || halt "radar ausente (${_RADAR}) — não dá para provar integridade"
if ! bash "${_RADAR}" "${FILE}" --integrity --schema >/dev/null 2>&1; then
  halt "kg-radar --integrity --schema REPROVA ${FILE}"
fi

say "AUTO — flip de '${NODE}' dispensa selo SEPARADO (exceção nomeada §4.1)"
say "  (1) não está em nenhum .kg.yaml de ${BASE}, nem na história dela (base provada fresca, repo completo)"
[ -z "${_DEGRADED}" ] || say "      ⚠️ leitura DEGRADADA (texto, não YAML) em: ${_DEGRADED} — nenhum deles menciona o id"
say "  (2) derrubado por '${SRC}' com verified_at + verified_against preenchidos — teto: o script não julga se a medição ocorreu"
say "  (3) aresta ${KIND} → alvo '${TARGET_STATUS}' (Aufhebung aplicada) · kg-radar --integrity --schema exit 0"
say "  ⚠️ A (4) DO §4.1 É HUMANA E ESTE EXIT 0 NÃO A CUMPRE: nomeie o flip no STATE.md do checkpoint."
exit 0
