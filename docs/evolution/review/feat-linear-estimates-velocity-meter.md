---
branch: feat/linear-estimates-velocity-meter
date: 2026-11-08
reviewed_diff_sha256: 9708628a5bd80560c1390c42a41d58bf53b33695c30b1fcf693ad0846dc4723f
reviewed_code_sha256: e323e7d1a3296d8c346642a148d4ff848320c528cfd4290d3328b6842ceb303c
findings_total: 7
findings_real: 7
tokens: 0
duration_min: 20
findings_fixed: 6
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes)"
nota: "tokens = 0: não medido. Uma lente só, sobre verbos, medidor, amostra cega e bancada; o que sustenta é a bancada com mutantes e o dogfood contra o Linear real."
---

# Resíduo: estimativa, prazo e medidor de planejado contra executado

Passada adversarial feita por quem escreveu, depois da bancada verde na primeira rodada completa de mutantes.

| # | Achado | Destino |
|---|---|---|
| 1 | O mutante da checagem de `hours_per_point` não mordia: a checagem da fila escondia a ausência dela. | Curado: o caso repete com `--queue-points`. |
| 2 | O mutante da forma `YYYY-MM-DD` não mordia: `date.fromisoformat` aceita `20261130` e o caso não o cobria. | Curado: valor entrou no caso. |
| 3 | O mutante do ano solto não mordia: os outros padrões cobriam todo ano do fixture. | Curado: fixture com ano solto. |
| 4 | A data partia da meia-noite mesmo sem `--today`, e podia sair um dia antes do possível. | Curado: parte do instante atual. |
| 5 | Lendo a amostra real, sobrou contagem de esforço (`3 rodadas de CI`). | Curado: padrão e caso novos. |
| 6 | A regra `eta` da bancada era engolida pela regra `beta`. | Curado no fixture. |
| 7 | A taxa de pontos usa só semanas com pontos, e a fila por velocidade sai otimista. | Limite declarado no campo `limits`. |

Limite que segue: o relógio é o do quadro, e 37 das 91 concluídas não têm `startedAt`. A mediana de 0,8 h mede agente, não pessoa.
