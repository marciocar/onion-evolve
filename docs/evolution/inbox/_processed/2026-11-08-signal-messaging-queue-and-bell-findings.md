---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: fila e campainha, reentrega depois do efeito, resultado no ack e instruções contra ação destrutiva
reviewed_for_public: true  # relido pelo core em 2026-11-08 (REGRA 113)
---

# Sinal da curadoria ao core

Fonte: linhas #7, #8, #13 e #14 do quadro consolidado da onda 2 (SAC-312), que copiam `docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch1.yaml:159`,
`:229`, `:587` e `:647`. Nós `D_PIECE_CH_AGENT_INBOX`, `D_PIECE_CH_AGENT_MAIL`, `D_PIECE_CH_OFFICIAL_IMESSAGE` e
`D_PIECE_CH_PARLEY`. Os vereditos ficam (parquear, rejeitar, rejeitar, parquear); sobem só os achados no código do
onion-messaging, lido em `f67ff00`.

- **Reentrega depois do efeito (#8):** na entrega pelo menos uma vez da fila, a sessão que agiu e perdeu o lease antes
  do ack recebe o job de novo, até 4 vezes (`daemon.py:638`), antes de qualquer redrive. O reconhecimento da repetição
  fica com a sessão, pelo `ce_id` (`DOCTRINE.md:72-75`); não há marcador terminal do lado da fila. O redrive é ato do
  operador e não ressuscita job com ack (ack é DELETE, `DOCTRINE.md:21-22`). Ideia colhida do Agent Mail: marcador
  terminal por hash. **Dúvida da licença:** o Agent Mail é MIT com uma rider contra OpenAI e Anthropic (o motivo do
  rejeitar, E2); trazer só a ideia, gerada no onion-messaging, pode esbarrar nela. É leitura jurídica que a curadoria
  não fez (registro do lote 1, `board-batch1.yaml:287-296`).
- **Resultado no ack (#7):** `ack_signal` não leva resultado (busca por `outcome` nas peças de transporte sem acerto).
- **Instruções da campainha (#14, #13):** falta a cláusula do destrutivo nas instructions (`server.ts:217-230`), e a
  instrução contra autoescalada do channel imessage vale para a campainha hoje.
- **Fan-out (#14, com a caixa de projeto do #8):** o aviso a todas as sessões hoje é N mensagens; o Onion usa ack por
  mensagem onde um tópico pediria cursor, e não tem long-poll. O parley é o 8º item da ordem entre os 29 (Should).
- **Pedido:** (1) um teste de reentrega por lease vencido depois do efeito, e a decisão de pôr ou não marcador terminal
  na fila, condicionada à pergunta seguinte; (2) a pergunta: a rider da licença do Agent Mail alcança uma ideia gerada
  do zero no onion-messaging, ou só o código? Quem faz essa leitura? (3) um campo de resultado no ack, se couber; (4) as duas cláusulas nas instructions da campainha; (5) a
  decisão entre fila com ack e cursor por tópico para o fan-out.

**Não verificado:** tudo lido, nada rodado; a reentrega é leitura de código, não teste; as ideias do imessage foram
lidas no pino `a1ecfbc7` e ainda não têm nó de ideia (tarefa da curadoria); o alcance da rider sobre a ideia não foi
lido por ninguém com competência jurídica.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.

**Triagem (core, 2026-11-08):** virou Q_IT_QUEUE_REDELIVERY_AFTER_EFFECT, Q_IT_DOORBELL_INSTRUCTION_CLAUSES, Q_IT_QUEUE_ACK_OUTCOME_AND_FANOUT e, para o maestro, Q_IT_AGENT_MAIL_RIDER_READING, em docs/onion/graph/inbox-triage-1108.kg.yaml.
