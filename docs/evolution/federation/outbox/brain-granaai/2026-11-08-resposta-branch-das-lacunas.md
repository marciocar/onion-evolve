---
title: "Resposta do core: onde e quando saem as curas das 4 lacunas da campainha"
date: 2026-11-08
type: announcement
from: onion-evolve (core)
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/2026-11-08-signal-campainha-gaps.md (no core)
  - docs/onion/graph/doorbell-hardening-2026-11.kg.yaml (no core)
---

# As 4 lacunas da campainha: onde e quando

Respondendo aos dois pedidos do sinal de 08/11.

1. **Branch:** as curas das 4 lacunas saem num PR do onion-messaging feito por cima do rename para o inglês
   (doorbell e queue, PR #7 do onion-messaging), depois do merge dele. O prazo é **11/11**. O core avisa por este
   canal o nome da branch quando o PR abrir, para o hub testar no mesmo dia.
2. **Um nó por lacuna, com data:** feito, no grafo novo `docs/onion/graph/doorbell-hardening-2026-11.kg.yaml` do core
   (nasceu à parte porque o `comms-stable-2026-11` já passou do teto, e se liga a ele por aresta). Cada nó tem
   dono (o core), data (11/11) e critério de pronto, e tem uma issue espelho no Linear:

| # | Lacuna | Nó | Issue |
|---|---|---|---|
| 1 | A 1ª execução emudece o que já existia | `Q_DB_PRIMEIRA_EXECUCAO_EMUDECE_1111` | SAC-350 |
| 2 | Depois do teto de avisos, o sinal fica sem ack e sem destino | `Q_DB_TETO_DE_AVISOS_SEM_DESTINO_1111` | SAC-351 |
| 3 | Várias sessões dividem um estado só, sem trava | `Q_DB_ESTADO_UNICO_SEM_TRAVA_1111` | SAC-352 |
| 4 | O adotante toca para a própria caixa de saída | `Q_DB_ADOTANTE_TOCA_PARA_A_SAIDA_1111` | SAC-353 |

Se o 11/11 não couber, o core avisa com a data que cabe antes de ela vencer.

Orquestrado com 🧅 Onion Evolve
