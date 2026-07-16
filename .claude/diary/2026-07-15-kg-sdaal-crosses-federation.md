---
date: 2026-07-15
instance: onion-evolve
type: learning
classification: protected
tags: [kg-sdaal, radar, federation, dogfood, cross-boundary]
affects: [meta, federation]
breadcrumb_for: [meta:kg, meta:evolve]
share_with: []
next_recommended: "2026-07-15-kg-audit-layer-generalizes-to-content"
review_after: 2026-10-13
conflict_class: dynamic
---

## Signal
O radar soberano do KG SDAAL (`.claude/validation/kg-radar.sh`) roda **limpo sobre o grafo
REAL de um adotante** — a máquina KG do core **atravessa a fronteira da federação sem
adaptação**. Não tratar o KG SDAAL como core-only: o radar vale sobre grafos de adotante.

## Evidence
- **Re-dogfood geral, todos os modos:** radar+reconcile+integrity+domain+triples em **11
  grafos** (10 do core + `tornak.kg.yaml` do gustavo) → **0 defeito**; integridade limpa em todos.
- **Cross-federation:** o `kg-radar.sh` do core processou o grafo do gustavo (**107 nós /
  172 arestas**), extraído de `origin/onion/adopt@4113a55` — ranqueou atenção, reconciliou
  `SUPERSEDES`/`REFUTES`, pegou 1 estado-absorvente (`ST_CONTRATO`, terminal legítimo).
- **Único warning recorrente** nos 11: "estado-absorvente" na camada `domain` (⚠ atenção,
  **não-reprova**) — todos terminais legítimos (contrato, destilado, emissão). Máquina não
  regrediu desde a construção (10-jul).

## Next crumb
Antes de assumir escopo core-only para o KG SDAAL, lembrar que o radar é agnóstico ao dono
do grafo. Re-teste = re-rodar `bash .claude/validation/kg-radar.sh <grafo>` (dynamic — grafos
e comportamento mudam com o tempo). Ver `[[2026-07-15-kg-audit-layer-generalizes-to-content]]`
(o que o grafo do adotante revelou sobre a camada audit).
