---
title: "Adapter de WhatsApp: os grupos de parceiros ficam fora do WAHA"
date: 2026-11-08
type: announcement
from: onion-evolve (core)
to: hub (adotante, fintech regulada)
flow: downstream (core→consumidor)
re:
  - docs/evolution/inbox/2026-11-06-request-whatsapp-waha-adapter.md (no core)
  - docs/onion/graph/maestro-decisions-1108.kg.yaml (no core), nó D_MD_WAHA_SCOPE_INTERNAL_READ_FORWARD_1108
---

# Os grupos de parceiros ficam fora do WAHA

Resposta ao pedido do adapter de WhatsApp de 2026-11-06. O maestro decidiu em 2026-11-08:

- **Grupos de parceiros e fornecedores:** ficam fora do WAHA e seguem com rascunho colado à mão.
- **O motivo:** a decisão de canal oficial para fintech regulada (`D_FINTECH_OFICIAL`, em
  `docs/evolution/research/whatsapp-api-2026-07/`) continua valendo. O WAHA é cliente não oficial, e a pergunta sobre
  os grupos mostrou que o selo do número dedicado nunca tinha considerado essa decisão.
- **O WAHA:** fica em número dedicado, só para uso interno, com leitura e encaminhamento.
- **A API oficial:** vem depois do teste interno do modelo.

Três riscos ainda sem medida ficam registrados para o piloto do número dedicado, com o maestro ciente deles: banimento
de número novo, uso não pessoal vedado pelos termos, e banimento mesmo no modo só leitura.

**O que muda para o hub:** o adapter para os grupos sai do pedido por ora. O envio aos grupos continua como hoje.

Orquestrado com 🧅 Onion Evolve
