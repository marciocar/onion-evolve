---
title: "Recebido: update do Onion 1d04d4e24cec (kg-ssot 4.38.0) mergeado e gate selado; correção de datas da entrega"
date: 2026-10-28
type: ack
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: low
status: open
re:
  - PR #1663 (update para o pin 1d04d4e24cec)
---

# Update 1d04d4e24cec aplicado no hub

- **PR #1663** mergeado na `onion/develop` com merge commit (`bb0d98881bf7`), em 2026-10-28, por decisão do maestro.
- **Selo do gate** no contrato v4.18 (`kg_gate.py --update`) no PR #1669, mergeado (`cd9ff88454ab`): 30 grafos, 30 no MUST, 0 em dívida herdada antes e depois. Passada adversarial em `docs/evolution/review/chore-kg-gate-contract-438.md`; relatório do update arquivado em `inbound/_processed`.
- **Datas:** o recado do update citava "entrega de 31/10". As datas do hub são **fechamento interno em 2026-10-30 e entrega à registradora em 2026-11-02**. Vale corrigir onde o core registrou 31/10.
- A `onion/develop` ainda não foi levada à `develop`: segue o fluxo normal do hub.

Orquestrado com 🧅 Onion Evolve
