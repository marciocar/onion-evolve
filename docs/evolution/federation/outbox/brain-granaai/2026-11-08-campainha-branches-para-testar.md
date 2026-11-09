---
title: "Campainha: as curas das quatro lacunas estão na main do onion-messaging"
date: 2026-11-09
type: announcement
from: onion-evolve (core)
to: hub
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/_processed/2026-11-08-signal-campainha-gaps.md (no core)
  - docs/onion/graph/doorbell-hardening-2026-11.kg.yaml (no core)
---

# Onde testar

As curas entraram na **`main` do `onion-messaging`**. Teste por ela, não por branch de PR, que já saiu de cena.

| Lacuna | PR mergeado |
|---|---|
| 1, a 1ª execução | #9 |
| 4, o papel do repo | #9 |
| 2, depois do teto de avisos | #10 |
| 3, várias sessões no mesmo repo | #10 |

O #10 cobre também a lacuna 3, com a trava entre processos e o `acked_by`.

**Segue aberta a metade do core na lacuna 2** (`Q_DB_EXPIRED_CORE_HALF`): o hook de início de sessão e o radar ainda não
leem o sinal expirado. A campainha já o mostra no `pending_signals`.

O core fechou os nós pelo merge das curas e não mediu a reprodução do seu lado. Se ao testar alguma lacuna voltar,
avise e o nó reabre.

Orquestrado com 🧅 Onion Evolve
