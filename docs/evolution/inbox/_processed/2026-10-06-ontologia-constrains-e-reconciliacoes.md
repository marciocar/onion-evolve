---
title: "A ontologia diz que CONSTRAINS é só de domain, a gramática manda usá-lo em audit — e três reconciliações que o eval da porta 0 achou"
date: 2026-10-06
type: signal
from: onion-slm (adopted, pin 9e75a73d0401)
to: core (onion-evolve)
flow: upstream
severity: medium
---

# Quatro achados sobre o próprio corpus do core

Achados montando o eval selado da porta 0 do Onion SLM, conferidos no commit `2d316566c9a4` por esta
sessão e pela sessão do core (`backlog-management-onion`), que leu cada caso além do par. As
decisões de como o eval os trata são do maestro e estão em
`docs/onion/graph/onion-slm-stage0.kg.yaml`.

## 1. CONSTRAINS: a ontologia contradiz a gramática

- `docs/knowledge-base/concepts/onion-kg-ontology-hierarchy.md:36-39` põe `CONSTRAINS` só em
  `layer: domain`; as arestas de `audit` seriam SUPPORTS/REFUTES/SUPERSEDES/CAUSES/DEPENDS_ON/TRACES_TO.
- `.claude/rules/kg-grammar.md` ensina o contrário para audit: "dissent que MATA é `REFUTES`; dissent
  que LIMITA é `CONSTRAINS`".
- O corpus segue a gramática: das 777 arestas `CONSTRAINS`, **724 (93%)** ligam nós que não são
  da camada domain (medido no commit `2d316566c9a4`, fixtures fora). Ex.: `backlog-grafo-2026-08.kg.yaml`
  declara `layer: audit` e usa CONSTRAINS 9 vezes.

Sugestão: a ontologia admitir `CONSTRAINS` em audit com o sentido "limita sem derrubar", ou a
gramática apontar outra aresta para a objeção sobrevivente. Hoje uma das duas está errada.

## 2. B2_2_claim_core_mechanic_healthy: refuted para satisfazer o radar

O nó está `refuted` desde o commit `e0bf994a` ("o radar de novo exigiu reconciliação: 17 nós
recebendo REFUTES…"). Mas o relatório de origem (`onion-federation-audit-2026-07-01.md:18-21`) diz
"Veredito de topo: o núcleo mecânico está saudável; os problemas reais são…" e lista o drift de
registro e o guard vazio como RESSALVAS dentro do veredito. As 5 arestas REFUTES que ele recebe
descrevem essas ressalvas. Sugestão: reconciliar como `confirmed` com as ressalvas em `CONSTRAINS`.
Este é o mesmo modo de falha que o radar devia evitar: um status posto para a catraca passar, não
medido.

## 3. pr-decision-history: arestas PR↔PR remapeadas por LLM

O cabeçalho (`pr-decision-history-2026-08.kg.yaml:1-3`) declara que SUPERSEDES/REFUTES "foram
mapeadas p/ DEPENDS_ON/CAUSES". São 52 DEPENDS_ON e 9 CAUSES entre PRs, vindas de um refino por LLM
(commit `ffecf8da`), sem guardar qual era a relação original. Quem ler o grafo como SSOT de relação
entre PRs lê uma aproximação. Sugestão: guardar a aresta original num campo, ou marcar essas arestas.

## 4. Grafo didático no corpus

`docs/materials/cold-adopter-2026-07/example-domain.kg.yaml` é material sintético para adotante
(dados fictícios: churn de 8% contra 3%), mas entra em qualquer leitura de `git ls-files '*.kg.yaml'`,
inclusive a do `/warm-up`. Sugestão: tirá-lo da descoberta padrão, como já se faz com `/fixtures/`.
