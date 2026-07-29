#!/usr/bin/env bash
# =============================================================================
# kg-narrate-validate.sh — VALIDA a narração pré-cozida de um .kg.yaml.
#
# A narração (<slug>.narration.json) é o único ponto com LLM do console: um
# agente autora o tour guiado + resumos por nó, e o kg-console.sh a EMBUTE (opt-in).
# Este script é o MECANISMO que impede a narração de mentir — "cita ids de nó,
# nunca re-deriva da prosa" (doutrina KG-SSOT) vira GUARD determinístico, não
# promessa: todo id citado no tour/resumos DEVE existir no grafo. Sem isto o
# console dropa ids mortos EM SILÊNCIO (o antipadrão do no-op silencioso).
#
# Schema esperado (<slug>.narration.json):
#   { "graph": "<slug>", "generated_from": "...", "generated_at": "AAAA-MM-DD",
#     "node_summaries": { "<id>": "resumo pt-BR", ... },
#     "guided_tour": [ { "focus": ["<id>", ...], "narration": "texto", "camera": "fit" } ] }
#
# Uso : kg-narrate-validate.sh <arquivo.kg.yaml>            (resolve o .narration.json irmão)
#       kg-narrate-validate.sh <narração.json> <kg.yaml>    (par explícito)
# Exit: 0 válido · 1 inválido (ids mortos / schema quebrado) · 2 uso · 3 dep ausente
# Exercitado por lint-selftest (run_kg_narrate_validate_selftests) e pela REGRA 47.
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

A="${1:-}"; B="${2:-}"
[ -n "${A}" ] || { echo "uso: kg-narrate-validate.sh <arquivo.kg.yaml> | <narração.json> <kg.yaml>" >&2; exit 2; }

case "${A}" in
  *.narration.json)
    NARR="${A}"; KG="${B}"
    [ -n "${KG}" ] || { echo "kg-narrate-validate: faltou o .kg.yaml par de ${NARR}" >&2; exit 2; }
    ;;
  *.kg.yaml)
    KG="${A}"; NARR="$(dirname "${KG}")/$(basename "${KG}" .kg.yaml).narration.json"
    ;;
  *) echo "kg-narrate-validate: argumento não reconhecido (${A}) — passe um .kg.yaml ou um .narration.json" >&2; exit 2 ;;
esac

[ -f "${KG}" ]   || { echo "kg-narrate-validate: .kg.yaml ausente: ${KG}" >&2; exit 2; }
[ -f "${NARR}" ] || { echo "kg-narrate-validate: narração ausente: ${NARR}" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || { echo "kg-narrate-validate: python3 ausente (exit 3, gracioso)." >&2; exit 3; }
[ -f "${HERE}/kg-view.sh" ] || { echo "kg-narrate-validate: kg-view.sh ausente (exit 3)." >&2; exit 3; }

# Ids do grafo vêm da LENTE VIGIADA (kg-view --json, paridade com o radar) — nunca
# de um parse paralelo. O validador não reimplementa o grafo; ele o consome.
GRAPH_JSON="$(bash "${HERE}/kg-view.sh" "${KG}" --json 2>/dev/null || true)"
case "${GRAPH_JSON}" in '{'*) : ;; *) echo "kg-narrate-validate: kg-view --json falhou em ${KG} (exit 3)." >&2; exit 3 ;; esac

GRAPH_JSON="${GRAPH_JSON}" NARR="${NARR}" python3 - <<'PY'
import json, os, sys
graph = json.loads(os.environ["GRAPH_JSON"])
ids = {n["id"] for n in graph.get("nodes", [])}
try:
    narr = json.load(open(os.environ["NARR"], encoding="utf-8"))
except Exception as e:
    print(f"✗ narração não é JSON válido: {e}", file=sys.stderr); sys.exit(1)

errs = []
tour = narr.get("guided_tour")
if not isinstance(tour, list) or not tour:
    errs.append("guided_tour ausente ou vazio (a narração precisa de ≥1 passo)")
else:
    for i, st in enumerate(tour):
        if not isinstance(st, dict):
            errs.append(f"passo {i}: não é objeto"); continue
        foc = st.get("focus", [])
        if not isinstance(foc, list):
            errs.append(f"passo {i}: 'focus' deve ser lista")
        else:
            for x in foc:
                if x not in ids:
                    errs.append(f"passo {i}: id inexistente no grafo → '{x}' (narração mente/drift)")
        nar = st.get("narration", "")
        if not isinstance(nar, str) or not nar.strip():
            errs.append(f"passo {i}: 'narration' vazio (passo sem voz não narra nada)")

summ = narr.get("node_summaries", {})
if summ and not isinstance(summ, dict):
    errs.append("node_summaries deve ser objeto {id: resumo}")
elif isinstance(summ, dict):
    for k in summ:
        if k not in ids:
            errs.append(f"node_summaries: id inexistente no grafo → '{k}'")

if errs:
    print("✗ narração INVÁLIDA — a IA que explica não pode citar o que o grafo não tem:", file=sys.stderr)
    for e in errs[:30]:
        print(f"   · {e}", file=sys.stderr)
    if len(errs) > 30:
        print(f"   … (+{len(errs)-30} mais)", file=sys.stderr)
    sys.exit(1)

steps = len(tour); refs = sum(len(s.get("focus", [])) for s in tour); nsum = len(summ) if isinstance(summ, dict) else 0
print(f"✅ narração válida: {steps} passos de tour, {refs} focos, {nsum} resumos — todos os ids existem no grafo ({len(ids)} nós).")
PY
