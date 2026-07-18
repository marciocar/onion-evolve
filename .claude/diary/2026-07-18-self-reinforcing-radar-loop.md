---
date: 2026-07-18
instance: onion-evolve
type: innovation
classification: collective
tags: [federation-radar, self-reinforcing-loop, observability, declarado-verificado, auto-evolution]
affects: [co-evolution, meta]
breadcrumb_for: []
share_with: [granaai, metagamify]
next_recommended: ""
review_after: 2026-10-15
conflict_class: static
---

## Signal
**O loop de auto-evolução se fechou sobre si mesmo.** O `federation-radar.sh` (construído numa passada do
runtime) **descobriu** um fio — anúncios em staging não-transportados — que o runtime então **fechou** (outbox
hygiene), e o radar **confirmou** o fix na re-rodada (**32 → 15 pontos de atenção**). A "foto da federação como
KG" não é só diagnóstico: **produz ação, e a ação se verifica no mesmo instrumento.** Observabilidade determinística
→ surfa o próximo trabalho → fecha → re-roda pra confirmar. É o `read(KG)→act→write(KG)` na escala da federação.

## Evidence
- `.claude/validation/federation-radar.sh` (4 checks do eixo declarado≠verificado, reusa `graph.sh --triples` +
  `reconcile-inputs.sh` + `members.yaml`; advisory exit 0). Dogfood: 32 pontos.
- Fio achado pelo check ② (staging-não-transportado) → PR #429 (outbox hygiene: 17 entregues → `_processed`,
  method-adopter/G1 fica em staging) → radar re-dogfoodado: **15** (self-heal verificado).
- **Sub-lição — `declarado≠verificado` aplicado a um BRANCH:** T-FIX-SDAAL parecia **vivo** pela data do commit,
  mas estava **morto** (conteúdo já no main via descoberta convergente — `grep` provou o steering + o guard de
  lint já presentes). Julgar vivo/morto de um branch pelo **conteúdo-no-main**, não pela data.

## Next crumb
Construir observabilidade (radar/lente) **não é o fim** — é o começo do loop: o radar surfa o fio, o runtime
fecha, o radar **re-confirma**. Ao herdar um branch órfão: `grep` o conteúdo-chave no main **antes** de assumir
que está vivo (data engana; conteúdo decide). Cada checagem de saúde só fecha `confirmed` com re-verificação.
