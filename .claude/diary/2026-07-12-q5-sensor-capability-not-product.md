---
date: 2026-07-12
instance: onion-evolve
type: decision
classification: protected
tags: [behavior-sensor, product-boundary, capability-vs-product, north-star, discussion-worktree]
affects: [product, strategy, meta]
breadcrumb_for: [discuss:behavior-mapping-kg, discuss:onion-pessoal-marcio]
share_with: []
next_recommended: "docs/discussions/behavior-mapping-kg/05-fronteira-produto.md"
review_after: 2026-10-10
conflict_class: conditional
valid_when: "não surgiu pull frio externo por um process-mining pessoal standalone (Q_COLD_ADOPTER segue sem prova)"
---

## Signal
Q5 da frente `behavior-mapping-kg` foi **fechada pelo maestro (2026-07-12): o sensor de comportamento é
uma CAPABILITY do Onion pessoal, NÃO um produto próprio.** O produto standalone fica **deferido** (não
descartado) — revisável **só se** surgir um pull frio externo (herda o desempate `Q_COLD_ADOPTER` do
north-star). Absorva como decisão vigente **enquanto** o `valid_when` valer.

## Evidence
- **Fecho no grafo:** `proto/product-boundary.kg.yaml` — `D_SENSOR_AS_CAPABILITY` open→**confirmed** (não `done`: rumo estratégico não se verifica em PROD), `C_FEATURE`→confirmed, `C_PRODUCT` mantido `open` = **deferido** (não refutado), + evidência `E_NORTHSTAR`. kg-radar verde (9 nós, 10 arestas).
- **Razão:** capability alinha com a identidade canônica (framework-template, sem CLI/produto standalone) e com a tese knowledge-centric (o valor é a inteligência sobre o log = o cérebro pessoal). Produto standalone = desvio de identidade + mercado ocupado (RescueTime/Timely/enterprise).
- **Coerência com o north-star:** hoje *zero adotante frio* → "a demanda é do eixo, não do Onion"; deferir o produto até haver pull frio é o mesmo desempate `Q_COLD_ADOPTER` já registrado em [[2026-07-11-knowledge-centric-reframe-and-north-star]].
- **Propagado:** nota 05, README e SEED (`phase: DEEP→CONVERGE`, `next_action` sem "FECHAR Q5"). Tudo isolado na branch `discuss/*`.

## Next crumb
Re-teste é **barato** (conflict_class conditional): checar só o `valid_when` — *apareceu pull frio arms-length por um process-mining pessoal standalone?* Se **não** → decisão vale, renovar `review_after`. Se **sim** → reabrir `C_PRODUCT`/`D_SENSOR_AS_CAPABILITY` e reavaliar (o produto deixou de ser hipótese morta de propósito). Promover o sensor a `feat/*` continua sendo decisão separada do maestro — **nada promove ao core sem pedir**.
