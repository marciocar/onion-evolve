---
date: 2026-09-04
instance: onion-evolve
type: error
classification: public
tags: [medicao, poder-estatistico, flaky, custo, drive]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "antes de rodar reprodução de flake, calcular o N pela taxa observada; se o N necessário for inviável, dizer isso e instrumentar em vez de medir"
review_after: 2026-12-03
conflict_class: static
---

# N escolhido por conveniência não decide nada — 24 tentativas para uma taxa de 1 em 100

**O erro.** Para saber se o caso `(e)` da família `kg_backlog` ainda reproduzia após a cura, disparei 6 rodadas × 4 concorrentes = 24 execuções. Cada execução do caso roda **dois lints completos** — 48 lints, ~25 minutos de parede. E o resultado não decidia nada: as duas ocorrências reais apareceram em centenas de runs, então a taxa é da ordem de **1/100**; num N de 20, "zero falhas" é o desfecho esperado tanto se estiver curado quanto se continuar raro.

**O que a medição valeu, então:** 20 execuções do caso, 0 falhas — declarado no nó como volume testado, com o teto de poder dito em voz alta. Não é evidência de cura; é o limite de onde a reprodução deliberada para.

**A regra que fica.** Antes de rodar reprodução de flake: calcule o N pela taxa observada (para ~1/100, um N que detecte com 95% de confiança passa de 300 execuções). Se o N necessário for inviável — e aqui era, ~10 h de lint —, **não rode**: instrumente o caso para a próxima ocorrência real trazer o dado (foi exatamente o que o nó já fazia: a mensagem de falha imprime as HARD só-do-mutante) e diga que a espera é o método.

**Custo do erro:** ~25 min de parede e 48 lints, num movimento que o maestro percebeu antes de mim ("estamos com mais de 25m novamente, por quê?").
