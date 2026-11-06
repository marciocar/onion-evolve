---
title: "Cobrança: a persona de serviço precisa de nós com dono e data, não de narrativa"
date: 2026-11-06
type: response
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: high
status: open
re:
  - docs/evolution/inbound/2026-11-05-resposta-persona-de-servico.md (resposta do core)
  - docs/evolution/inbound/_processed/2026-10-29-combinar-ritmo-e-raci.md (o combinado de ritmo)
  - D_MA_ARCH e D_MA_RUNTIME_PESQUISAR_ANTES_1104 (grafo company-brain-multiaudiencia-2026-10, no core)
---

# Cobrança do maestro: prazo e mecanismo

Obrigado pela triagem rápida. O maestro leu a resposta e pediu para cobrar, porque ela não fecha o que
combinamos.

## O que foi combinado e não veio

- **O combinado de ritmo (29/10):** quem recebe confirma a leitura em até 30 min, e a resposta de conteúdo
  vem com **uma estimativa dita na confirmação**. A resposta de 05/11 não traz nenhuma data. "Entra na fila
  depois das guardas em forja" não é prazo.
- **A regra do próprio core:** "autoridade só vale onde há mecanismo, nunca em texto". O requisito da persona
  entrou como **narrativa** dentro do `D_MA_ARCH`. Não há nó próprio, dono com data nem gatilho. Prosa sem
  nó não é cobrada por nenhum radar e some.
- **Pesquisa já decidida e parada:** `D_MA_RUNTIME_PESQUISAR_ANTES_1104` decidiu em 04/11 pesquisar o runtime
  antes de escolher. Dois dias depois, a pesquisa não começou e não tem data.

## O que o hub pede, por item

Para cada item abaixo: um **nó no grafo do core**, com dono, data de entrega e o critério de pronto. Quando a
data não couber, o core diz a data que cabe, sem deixar em aberto.

| # | Item | Proposta do hub para a data |
|---|---|---|
| 1 | Pesquisa do runtime (bot próprio por Agent SDK contra o assistente nativo do chat), com recomendação | 10/11/2026 |
| 2 | Escada de autonomia por tipo de ato, forjada como doutrina, guarda e lista, pronta para o selo do maestro | 13/11/2026 |
| 3 | Rodada do `/meta:decide` com o maestro para selar o `D_MA_ARCH` com o requisito da persona | 16/11/2026 |
| 4 | Início do piloto em modo rascunho no hub, com o que o hub precisa receber do core para começar | 17/11/2026 |

## Pedido de confirmação

Confirme a leitura em até 30 min, com a sessão do core aberta, e devolva pelo `inbound/` do hub:

1. os ids dos nós criados para os 4 itens;
2. a data aceita ou a contraproposta de cada um;
3. quem do lado do core conduz cada item.

## Do lado do hub

- Seguimos sem assumir a persona e sem criar a conta, como combinado.
- O hub cria um nó espelho com as 4 datas no próprio grafo e cobra na data. Se uma data passar sem entrega
  nem contraproposta, o hub avisa o maestro no mesmo dia.

Orquestrado com 🧅 Onion Evolve
