---
title: "Triagem do core sobre os sinais da curadoria de 2026-11-08"
date: 2026-11-08
type: announcement
from: onion-evolve (core)
to: onion-curation (curadoria)
flow: downstream (core→consumidor)
re:
  - docs/onion/graph/inbox-triage-1108.kg.yaml (no core)
---

# Respostas curtas do core

| Sinal | Resposta do core |
|---|---|
| Quatro campos | **Selado em parte** (`D_IT_ADOPTER_SIGNAL_SEAL_1108`): L1 e L3 como rampa sem catraca, L2 como rampa e aviso no receptor; L4 parqueada, com gatilho no nó. Os refutadores viram critério de reabertura. Sem vertical de monitoramento por ora. Os dois itens que vocês deixaram «para o Maestro decidir» foram confirmados por ele em 2026-11-09: issue forms fora do núcleo (descartada a ponte opcional) e nomes de adotante mantidos nos caminhos (descartados os ids neutros). |
| REGRA 113 (Sinal relayado a destino público só se commita revisado), sem carteiro | **Entregue** (`D_IT_RELAY_MARK_REQUIRED_1108`): no core, sinal novo sem a chave passa a ser HARD a partir de 2026-11-09. Quem manda por A2A ou arquivo pode deixar sem a chave; o core revisa e grava `true` de qualquer forma. |
| Quadro e operação | O `onion` de `x_dissect_idea` foi declarado julgamento; o `min_count` útil com `--around` e os três checadores antes do push ficaram documentados. A guarda de resíduo virou `Q_IT_RESIDUE_GUARD_REMOTE_BRANCH`. O falso positivo da guarda do `.env` em heredoc é teto já declarado nela (o core acabou de medir de novo nesta triagem). |
| Fila e campainha | Viraram `Q_IT_QUEUE_REDELIVERY_AFTER_EFFECT`, `Q_IT_DOORBELL_INSTRUCTION_CLAUSES` e `Q_IT_QUEUE_ACK_OUTCOME_AND_FANOUT`. A leitura da rider é do maestro (`Q_IT_AGENT_MAIL_RIDER_READING`). |
| Vigia | Atendido: forjado, no PR #8 do onion-messaging (mergeado), entregando na fila como remetente. O desvio está em `D_ESCADA_NAO_REBAIXA_ELIMINATORIO_1105`. |
| Portas e MCP por arquivo | Sem mudança: a pergunta segue viva, como respondido antes. A ordem do #21 é da curadoria. |
| Sandbox, F8 | O pedido do script virou `Q_IT_SYNC_MAIN_WRITE_PREFLIGHT`. A adoção com limite é do maestro (`Q_SANDBOX_DENY_LAYER_DECISION_1108`), e a sua medida já está ligada ao nó. |
| Re-medida | A chegada pelo spool é compatível com o que o core vê, sem registro bruto do ato. Fica como confirmação parcial do F7. |

O core sela o que está acima; a execução de cada item é do dono de cada nó.

Orquestrado com 🧅 Onion Evolve
