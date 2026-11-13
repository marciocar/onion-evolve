#!/usr/bin/env bash
# kg-vocab-graph.sh — o LINT DE NOMES (kg_vocab.py lint, contrato v4.14) julgando UM grafo, rastreado ou não.
#
# Por que existe (2026-11-13): o write(KG) do /onion-research conferia radar e contrato no arquivo escrito, mas
# não o lint de nomes, que o CI roda sobre a prosa dos grafos. A rodada wf_45f0fcd2-079 saiu verde e o commit
# reprovou: 29 ocorrências de LLM06, ASI03, ASI08, T8 e T9 sem termo (PR #1654), curadas à mão depois. O lint
# só lê o que o git rastreia (e o leitor do vendor descarta GIT_INDEX_FILE de propósito), e o grafo da rodada
# nasce NÃO rastreado. Por isso este script chama o MESMO lint do vendor por dentro (kg_vocab.main) e, só quando o
# grafo não é rastreado, acrescenta-o ao corpus que o kg_query.load monta de --root: o corpus inteiro dá os termos,
# o arquivo novo é julgado como se já estivesse no índice. Nada no repo nem no índice muda. Se o vendor deixar de
# expor kg_query.load, o script sai rc 2 (não julgou), nunca verde.
#
# O que conta: os achados (código sem termo ou ambíguo) NO arquivo julgado. Com a base da catraca
# (.kg-ssot/vocab-lint.json), só os acima da base, para a dívida antiga de um grafo apendado não virar culpa da
# rodada; sem base, todos os do arquivo. As externas do repo (.kg-ssot/vocab-externals.tsv) entram como --external.
#
# Uso: bash .claude/validation/kg-vocab-graph.sh <arquivo.kg.yaml>
# rc:  0 = nenhum achado no arquivo · 1 = achado(s), impressos um por linha · 2 = não pôde julgar (kg_vocab.py
#      ausente, fora de repo git, arquivo inexistente, lint que não julgou) — dito em stderr, nunca verde calado.
set -uo pipefail

[ "$#" -eq 1 ] || { echo "uso: kg-vocab-graph.sh <arquivo.kg.yaml>" >&2; exit 2; }
GRAPH="$1"
[ -f "${GRAPH}" ] || { echo "kg-vocab-graph: arquivo inexistente: ${GRAPH}" >&2; exit 2; }
ROOT="$(cd "$(dirname "${GRAPH}")" && git rev-parse --show-toplevel 2>/dev/null)" || { echo "kg-vocab-graph: fora de um repo git" >&2; exit 2; }
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/kg/kgssot-tools.sh" 2>/dev/null || kgssot_tools_dir() { return 1; }
TOOLS="$(kgssot_tools_dir "${ROOT}")" || TOOLS="${ROOT}/vendor/kg-ssot/tools"
V="${TOOLS}/kg_vocab.py"
[ -f "${V}" ] || { echo "kg-vocab-graph: kg_vocab.py ausente (${V}) — não dá para julgar" >&2; exit 2; }

# o caminho como o lint o escreve (relativo à raiz); python e não `realpath --relative-to`, que é só GNU
REL="$(python3 -I -c 'import os, sys; print(os.path.relpath(os.path.realpath(sys.argv[2]), os.path.realpath(sys.argv[1])))' "${ROOT}" "${GRAPH}")" || exit 2
case "${REL}" in ../*) echo "kg-vocab-graph: ${GRAPH} está fora do repo ${ROOT}" >&2; exit 2 ;; esac

args=(lint --root . --format json)
[ -f "${ROOT}/.kg-ssot/vocab-lint.json" ] && args+=(--baseline .kg-ssot/vocab-lint.json)
if [ -f "${ROOT}/.kg-ssot/vocab-externals.tsv" ]; then
  while IFS=$'\t' read -r s rx rest; do
    case "${s}" in ''|'#'*) continue ;; esac
    { [ -n "${rx}" ] && [ -z "${rest:-}" ]; } || { echo "kg-vocab-graph: linha malformada em .kg-ssot/vocab-externals.tsv (${s})" >&2; exit 2; }
    args+=(--external "${s}=${rx}")
  done < "${ROOT}/.kg-ssot/vocab-externals.tsv"
fi

TMPD="$(mktemp -d)"; trap 'rm -rf "${TMPD}"' EXIT
EXTRA=""
git -C "${ROOT}" ls-files --error-unmatch -- "${REL}" >/dev/null 2>&1 || EXTRA="${REL}"
(cd "${ROOT}" && python3 -I -B - "${TOOLS}" "${EXTRA}" "${args[@]}" <<'PY'
import sys
tools, extra, argv = sys.argv[1], sys.argv[2], sys.argv[3:]
sys.path.insert(0, tools)
import kg_query, kg_vocab
orig = getattr(kg_query, "load", None)
if orig is None or getattr(kg_vocab, "kg_query", None) is not kg_query:
    print("kg-vocab-graph: o vendor não expõe kg_query.load como o kg_vocab o usa", file=sys.stderr); sys.exit(3)
def load(root=None, files=(), exclude=(), defaults=True):
    return orig(root, tuple(files) + ((extra,) if extra and root is not None else ()), exclude, defaults)
kg_query.load = load
sys.exit(kg_vocab.main(argv))
PY
) > "${TMPD}/out.json" 2>"${TMPD}/err"
rc=$?
[ "${rc}" -le 1 ] || { echo "kg-vocab-graph: kg_vocab.py lint saiu rc=${rc} — não julgou: $(head -c 300 "${TMPD}/err")" >&2; exit 2; }

python3 -I - "${TMPD}/out.json" "${REL}" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    print("kg-vocab-graph: JSON ilegível do lint: %s" % e, file=sys.stderr); sys.exit(2)
rel = sys.argv[2]
l = d.get("lint") if isinstance(d, dict) else None
if not isinstance(l, dict) or not isinstance(l.get("findings"), list):
    print("kg-vocab-graph: forma inesperada do lint", file=sys.stderr); sys.exit(2)
for u in d.get("unreadable") or []:
    if rel in (u if isinstance(u, str) else json.dumps(u, ensure_ascii=False)):
        print("  ✗ ilegível: %s" % (u if isinstance(u, str) else json.dumps(u, ensure_ascii=False))); sys.exit(1)
pool = l.get("new") if isinstance(l.get("new"), list) else l["findings"]
mine = [f for f in pool if f.get("file") == rel]
for f in mine:
    print("  ✗ %s %s#%s %s %s%s" % (f.get("code"), f.get("file"), f.get("id"), f.get("field"), f.get("token"),
                                    " (%s)" % f["detail"] if f.get("detail") else ""))
if mine:
    print("✗ nomes: %d código(s) sem termo (ou ambíguo) em %s — dê a cada um um nó com x_term (pref, notation, scheme) ou escreva esquema:código" % (len(mine), rel))
    sys.exit(1)
print("✓ nomes: nenhum código sem termo em %s" % rel)
PY
