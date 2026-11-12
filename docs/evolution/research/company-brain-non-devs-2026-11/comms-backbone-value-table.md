---
kg: company-brain-non-devs-2026-11.kg.yaml
nodes: [D_COMMS_BACKBONE_COMPOSED_1112, D_COMMS_BACKBONE_VALUE_TABLE_1112]
date: 2026-11-12
status: rascunho de critérios, para virar medidas no plano com épicos
---

# Backbone de comunicação: tabela de critérios e valores

Decisões do maestro de 2026-11-12. `D_COMMS_BACKBONE_COMPOSED_1112` diz **o que se constrói e em que ordem**. `D_COMMS_BACKBONE_VALUE_TABLE_1112` diz **o que se vende**. O que não se vende sozinho é o encanamento (mover bytes de A para B). As **qualidades** do transporte se vendem, cada uma com critério e medida. Por cima delas vêm a governança, o grafo e a soberania.

A coluna "Hoje" é a leitura do core em 12/11 e precisa ser medida peça por peça antes de virar argumento de venda. Nada aqui foi provado ao comprador ainda.

| Valor | O que o comprador recebe | Critério e medida | Hoje |
|---|---|---|---|
| Segurança | só agente autorizado fala e age | 100% das mensagens com identidade verificada; 0 credencial fora do conector; resultado de teste de intrusão | parcial: JWS RS256 no bridge; veto por tipo na rota `/send` |
| Criptografia | conteúdo protegido em trânsito e em repouso | TLS em todo salto; assinatura JWS em 100%; cifra do corpo onde for pedida | parcial: assinatura sim; cifra do corpo a medir |
| Rastreabilidade | quem pediu, quem agiu e o que saiu | % de mensagens com quem pediu e quem agiu recuperáveis | parcial: linha de base de 12/11 com 20/20 quem pediu e 1/20 quem agiu |
| Observabilidade | ver o fluxo de ponta a ponta | p95 e p99 de latência por salto; traço por mensagem pelo id do CloudEvents | falta |
| Monitoramento | saber na hora quando algo para | tempo para detectar agente ou conector parado; alertas falsos por semana | parcial: o medidor da batuta acusa agente parado |
| Eventos | reagir ao fato, não varrer | % de entrada por evento contra busca periódica; vigias por varredura eliminadas | falta: o Slack ainda é lido por busca |
| Agendamento | mensagem e tarefa na hora marcada, com garantia | % entregue dentro da janela; atraso médio | a medir: o core não agenda por desenho; o adotante agenda |
| Gestão de falhas | nada se perde, nada se duplica | 0 perda e 0 dobro em uma semana; entrega uma vez sob queda (critério S8c); tempo de recuperação | parcial: fila durável no bridge; o S8c roda em 12/11 |
| Auditoria | prova para TI, jurídico e regulador | trilha assinada e imutável; pacote de evidência gerado; tempo para responder a um pedido de auditoria | parcial: selos e grafo; falta o pacote do tráfego |
| Soberania | dado e operação sob controle do cliente | roda 100% em self-host; 0 dependência de SaaS no caminho do núcleo | sim por desenho; a provar no empacotamento |

## Duas hipóteses de venda, medidas separadas

1. **Funcionamento** (a fundação): o aceite de uma semana, com 0 perda, 0 dobro, tudo pelo bot e p95 abaixo de 60 s.
2. **Valor** (o que o comprador paga): cada linha acima com a medida dela, e uma medida própria de que o comprador paga pelas qualidades e pela governança. Esse é o limite que a curadoria declarou no Delphi.
