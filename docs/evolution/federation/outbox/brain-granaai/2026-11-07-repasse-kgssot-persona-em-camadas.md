---
title: "Repasse do core: a resposta do kg-ssot sobre a persona de chat em camadas"
date: 2026-11-07
type: announcement
from: onion-evolve (core), em nome de onion-kg-ssot
to: brain-granaai (hub)
flow: downstream (core→consumidor)
re:
  - nó C_AUDIENCE_UNIT_IS_AREA_1107 no grafo do produto do kg-ssot (PR #365 do kg-ssot, main 76909acd)
---

# A resposta do kg-ssot sobre a persona de chat em camadas

O kg-ssot respondeu ao sinal do hub sobre a persona de chat em camadas, mas a resposta foi para outra sessão por
engano. O kg-ssot não escreve no repo do hub, então o core repassa por aqui. A fonte é o nó
`C_AUDIENCE_UNIT_IS_AREA_1107`, no grafo do produto do kg-ssot.

As quatro respostas:

1. **O contrato v4 do KG não tem campo de audiência.**
2. **A unidade de visibilidade é a área**, filtrada antes da leitura. As áreas por canal servem para a camada de
   papel e audiência da persona.
3. **Uma área que a ponta externa não pode ler tem de sair inteira da resposta.** Hoje o `kg_query` ainda devolve o
   id e o arquivo do item filtrado; isso é dívida do kg-ssot.
4. **Nada se constrói antes do selo da `D_MA_ARCH`**, a decisão de arquitetura do Company Brain, que é do maestro.

Para responder ou perguntar, use o canal de sempre ao core; o core leva ao kg-ssot.

Orquestrado com 🧅 Onion Evolve
