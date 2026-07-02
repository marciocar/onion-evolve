---
date: 2026-07-01
instance: onion-evolve
type: decision
classification: public
tags: [federation, co-evolution, taxonomy, rfc-0003]
affects: [meta, product]
breadcrumb_for: [meta:co-evolve, meta:adopt, meta:federation-register]
share_with: [collective]
next_recommended: ""
review_after: 2026-09-29
---

## Signal
O "papel da federação por tipo de uso" agora tem SSOT única: a KB
`docs/knowledge-base/concepts/federation-usage-modes.md`. Regra central: eixos de **adoção**
(cenário × controle) descrevem o *momento*; o **tier** (T0-T3) descreve a *vida em rede*;
`in-place` ⇒ fora da federação por construção.

## Evidence
- 4 artefatos usavam eixos sobrepostos nunca cruzados (adoption-lifecycle, RFC-0003, cartão, members.yaml).
- 3 namespaces de "role" coexistiam sem nome: contrato (`producer/consumers`), membro (tiers) e stamp
  (`source/adopted`) — causa de metade do backlog da auditoria 2026-07-01.
- Gatilhos de graduação estavam espalhados em ≥4 docs; agora consolidados numa tabela única com estado
  real verificado (F1: 0/10 entradas de diário; formal: gated corretamente; A2A: não é dívida ativa).

## Next crumb
Antes de tocar qualquer doc de federação, ler a KB primeiro e usar o namespace certo de "role".
Pendências que a KB registra: doutrina de T2 (consumer-de-hub), semântica de `adopted_at` no `--update`,
classificação de dados × `mode: regulated`.
