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
review_after: 2027-01-12
conflict_class: static
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
- **Estado em 2026-10-14 (re-teste):** a KB segue `status: active` e continua sendo a reconciliação canônica
  (última mudança em `ad983f53`, 2026-09-16). Das 3 pendências do Next crumb, 2 FECHARAM: a doutrina T2
  (consumer-de-hub) está fechada na RFC-0003 §5 (core-driven, `parent: <hub-id>`, nenhum T2 real ainda), e
  `regulated` × classificação de dados também (RFC-0003 §2.2: default `protected`, promoção só com revisão
  humana). A 3ª (semântica de `adopted_at` no `--update`) saiu da KB e virou código: `write-stamp.sh`
  preserva o `adopted_at` (família `write_stamp` 7/7).

## Next crumb
Antes de tocar qualquer doc de federação, ler a KB primeiro e usar o namespace certo de "role".
As pendências de 07-01 (T2, `adopted_at`, regulated × classificação) estão fechadas; ver Evidence. Pendência
viva que a KB registra hoje: o T2 real e o *hub-driven adoption* seguem como gatilho futuro (1º T2 real + dor de roteamento).

## Re-testada em 2026-10-14 — PARCIAL: (static, contra a KB atual) o Signal vale. O Evidence e o Next crumb foram reescritos: 2 das 3 pendências estão fechadas na RFC-0003 §5 e §2.2, e a 3ª virou `write-stamp.sh`.
