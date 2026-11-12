---
kg: docs/evolution/research/company-brain-non-devs-2026-11/company-brain-non-devs-2026-11.kg.yaml
nodes: [D_COMMS_BACKBONE_COMPOSED_1112, D_COMMS_BACKBONE_VALUE_TABLE_1112]
date: 2026-11-12
status: rascunho de critérios, para virar medidas no plano com épicos
---

# Backbone de comunicação: tabela de critérios e valores

Decisões do maestro de 2026-11-12. `D_COMMS_BACKBONE_COMPOSED_1112` diz **o que se constrói e em que ordem**. `D_COMMS_BACKBONE_VALUE_TABLE_1112` diz **o que se vende**. O que não se vende sozinho é o encanamento (mover bytes de A para B). As **qualidades** do transporte se vendem, cada uma com critério e medida. Por cima delas vêm a governança, o grafo e a soberania.

A coluna "Hoje" é a leitura do core em 12/11 e precisa ser medida peça por peça antes de virar argumento de venda. Nada aqui foi provado ao comprador ainda.

| Valor | O que o comprador recebe | Critério e medida | Hoje |
|---|---|---|---|
| Segurança | só agente autorizado fala e age | 100% das mensagens com identidade verificada; 0 credencial fora do conector; resultado de teste de intrusão | parcial: assinatura JWS RS256 no bridge; veto por tipo na rota `/send`, em revisão e sem deploy |
| Criptografia | conteúdo protegido em trânsito e em repouso | TLS em todo salto; assinatura JWS em 100%; cifra do corpo onde for pedida | parcial: assinatura no bridge; TLS por salto e cifra do corpo a medir |
| Rastreabilidade | quem pediu, quem agiu e o que saiu | % de mensagens com quem pediu e quem agiu recuperáveis | parcial: linha de base do kg-ssot de 12/11, com 20/20 quem pediu e 1/20 quem agiu (19 saíram pela conta pessoal, antes da fase 1) |
| Observabilidade | ver o fluxo de ponta a ponta | p95 e p99 de latência por salto; traço por mensagem pelo id do CloudEvents | falta |
| Monitoramento | saber na hora quando algo para | tempo para detectar agente ou conector parado; alertas falsos por semana | parcial: o medidor da batuta acusa agente parado ou calado (PRs #1617 e #1622) |
| Eventos | reagir ao fato, não varrer | % de entrada por evento contra busca periódica; vigias por varredura eliminadas | falta: o Slack ainda é lido por busca |
| Agendamento | mensagem e tarefa na hora marcada, com garantia | % entregue dentro da janela; atraso médio | a medir |
| Gestão de falhas | nada se perde, nada se duplica | 0 perda e 0 dobro em uma semana; entrega uma vez sob queda (critério S8c); tempo de recuperação | parcial: fila durável no bridge; o teste de queda (S8c) está marcado para 12/11, sem resultado ainda |
| Auditoria | prova para TI, jurídico e regulador | trilha assinada e imutável; pacote de evidência gerado; tempo para responder a um pedido de auditoria | parcial: selos e grafo; falta o pacote do tráfego |
| Soberania | dado e operação sob controle do cliente | roda 100% em self-host; 0 dependência de SaaS no caminho do núcleo | parcial: por desenho; a provar no empacotamento |

## Duas hipóteses de venda, medidas separadas

1. **Funcionamento** (a fundação): o aceite de uma semana, com 0 perda, 0 dobro, tudo pelo bot e p95 abaixo de 60 s.
2. **Valor** (o que o comprador paga): cada linha acima com a medida dela, e uma medida própria de que o comprador paga pelas qualidades e pela governança. Esse é o limite que a curadoria declarou no Delphi.

## Modelo de produto

Open-core: a camada aberta, sob Apache 2.0, e a governança paga, para empresas reguladas, operações soberanas e consultorias. O empacotamento só começa depois que o aceite da fundação passar no dogfood.

## Limites declarados no Delphi

- **Curadoria:** falta medir se o comprador paga pela governança.
- **kg-ssot:** falta o log de leitura.
- **Hub:** a fila local não cobre falha do disco do host.
