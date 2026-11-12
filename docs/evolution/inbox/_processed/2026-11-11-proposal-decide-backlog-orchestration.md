---
title: "Fila grande de decisões abertas no hub: o core orquestra a triagem com a sessão do hub"
date: 2026-11-11
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
reviewed_for_public: true  # relido pelo core em 2026-11-12 como publicado: só a forma, sem cliente, pessoas, segredo nem postura
---

# Fila grande de decisões abertas: triagem orquestrada pelo core

O `/meta:decide` do hub mediu hoje 118 fios em voo, dos quais cerca de 106 são nós `decision`/`question` abertos
em 34 grafos. O maestro respondeu na sessão só o que era da rodada dele e pediu que o core ajuste o resto,
orquestrando com a sessão do hub.

## A dor (genérica)

- O censo mostra só 40 linhas por vez; o resto fica nomeado, mas sem triagem.
- Muitos nós são de outros papéis (CEO, COO, jurídico, financeiro) e esperam pessoas fora da sessão; outros já
  podem estar resolvidos pelos fatos e só precisam de medição, não de pergunta.
- Sem um método, a fila só cresce e o maestro vê sempre as mesmas perguntas.

## O que o hub pede ao core

1. **Um método de triagem em lote**, rodado pela sessão do hub com o core orquestrando: para cada nó, classificar
   em (a) fechável por medição ou evidência já existente, (b) de outro papel, virar pedido para a pessoa certa
   com prazo, (c) obsoleto, virar `superseded` com motivo, (d) do maestro, entrar na próxima rodada do decide.
2. **Um teto de idade**: pergunta aberta há mais de N dias sem dono ativo dispara a triagem.
3. **O encaixe com o `/meta:kg-freshness`**, para que o que fecha por medição não passe pelo selador do decide.

O hub roda as medições e os selos no próprio repo; ao core sobe só o método e os aprendizados genéricos.
