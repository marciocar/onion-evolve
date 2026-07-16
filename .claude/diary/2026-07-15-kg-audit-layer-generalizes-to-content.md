---
date: 2026-07-15
instance: onion-evolve
type: learning
classification: protected
tags: [kg-sdaal, audit-layer, content-audit, field-signal, declared-vs-verified]
affects: [meta, product]
breadcrumb_for: [meta:kg, meta:co-evolve]
share_with: []
next_recommended: ""
review_after: 2026-10-13
conflict_class: conditional
valid_when: "a KB docs/knowledge-base/concepts/knowledge-graph-sdaal.md ainda NÃO documenta o uso da camada `audit` para auditar conteúdo/documentação (não-código) — quando documentar, aposentar esta migalha"
---

## Signal
A camada `audit` do KG SDAAL (`evidence→claim→decision→SUPERSEDES/REFUTES`) **generaliza para
auditar CONTEÚDO/documentação**, não só código/sistema — e o grafo **registra o próprio erro**
em vez de sobrescrevê-lo (`declarado ≠ verificado`). Evidência de campo, espontânea, sem o core.

## Evidence
- **Uso de campo (gustavo, `tornak.kg.yaml` Lote 10):** auditoria de 2 decks (37+17 slides)
  na gramática canônica — `E_SLIDE_AUDIT →SUPPORTS→ 7 claims →TRACES_TO→ artefatos`;
  `D_FIX_SCOPE →DEPENDS_ON→ claims`; **4 `V2 →SUPERSEDES→ V1`** (deck iterado, V1 vira `superseded`).
- **Auto-correção humana preservada:** `C_TARDE_NUM_15` (conf **0.4**) foi **REFUTED** por
  `C_TARDE_NUM_21` (conf **1.0**), backed por `E_MAESTRO_CORRECAO_NUM` — o erro da IA ficou no
  grafo, refutado e rastreável, não apagado. É a doutrina "declarado≠verificado" acontecendo no campo.
- **Gap de KB:** `knowledge-graph-sdaal.md` documenta a camada `audit` para investigações de
  código/sistema; **não menciona** auditoria de conteúdo — a gramática segurou sem adaptação.

## Next crumb
Avaliar registrar sinal no `inbox/` do core: **"camada `audit` do KG SDAAL generaliza p/
auditar conteúdo/documentação"** — material de KB. Re-teste barato = grep a KB pelo uso
content-audit (ver `valid_when`); quando documentado, aposentar esta migalha. Ver
`[[2026-07-15-kg-sdaal-crosses-federation]]` (o dogfood cross-fed que trouxe este grafo à luz).

## Retest 2026-07-16 — RESOLVIDA (migalha aposentada)
`valid_when` **satisfeito**: `knowledge-graph-sdaal.md` agora tem a nota de escopo
"a camada `audit` não é sobre código, é sobre investigação" documentando o uso content-audit
e citando o Lote 10 do Tornak. Sinal upstream `2026-07-15-sinal-kg-audit-layer-content-audit`
triado e movido para `_processed/`. A condição não vale mais → esta migalha não orienta mais
ação futura (fica como registro histórico, não deletada — `superseded ≠ apagado`).
