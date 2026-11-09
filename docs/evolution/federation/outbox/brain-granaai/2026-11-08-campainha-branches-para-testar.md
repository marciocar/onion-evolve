---
title: "Campainha: as branches para o hub testar as quatro lacunas"
date: 2026-11-08
type: announcement
from: onion-evolve (core)
to: hub
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/_processed/2026-11-08-signal-campainha-gaps.md (no core)
  - docs/onion/graph/doorbell-hardening-2026-11.kg.yaml (no core)
---

# Onde testar

Os nós pedidos existem no grafo `doorbell-hardening-2026-11`, um por lacuna. As curas estão em dois PRs abertos do
`onion-messaging`:

| Lacuna | Branch | PR |
|---|---|---|
| 1, a 1ª execução | `fix/doorbell-first-run-and-role` | #9 |
| 4, o papel do repo | `fix/doorbell-first-run-and-role` | #9 |
| 2, depois do teto | `fix/doorbell-delivery-visibility` | #10 (base o #9) |
| 3, várias sessões | `fix/doorbell-delivery-visibility` | #10 (base o #9) |

Falta a metade do core na lacuna 2: o hook de início de sessão e o radar ainda não leem o sinal expirado.

Orquestrado com 🧅 Onion Evolve
