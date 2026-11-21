---
branch: docs/plain-language-adoption-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: 9fc64b6592774ac49a18a5c029b3c5cfd2c0298975c1bd235dcbce25dff59a7e
reviewed_code_sha256: 029680872d95c36caa126c60113a3609e30d550b7d45a013f179df9c4e7428e4
findings_total: 6
findings_real: 6
findings_blocking: 2
tokens: 64378
duration_min: 2
findings_fixed: 6
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: code-reviewer (agente separado, brief sem a conclusão do autor)
nota: >-
  Um refutador separado leu o diff inteiro, rodou o radar, o contrato e a guarda do índice das bases
  de conhecimento. Achou 2 bloqueios (a contagem 108 no índice, que a guarda marca HARD, e a
  proveniência do selo que dizia "pergunta com opções" sem ter havido pergunta) e 4 limites. Os 6
  foram curados no mesmo PR.
---

# Passada adversarial: a Linguagem Simples entra no Onion por costura

## O que muda

- Base de conhecimento nova `docs/knowledge-base/concepts/plain-language-by-surface.md`: a régua de 11
  itens da ABNT NBR ISO 24495-1:2024 por superfície, com o sinal que mede cada item.
- Uma linha na skill `language-standards` e um item opcional (só LIMITE) na triagem de revisão.
- O selo `D_PLAIN_LANGUAGE_STITCH_1121` (costurar) no grafo de selos, dado pelo core a pedido direto do
  maestro e com a revisão dele pendente.
- O sinal da curadoria relido como público e arquivado em `_processed/`.
- Contagens: 115 bases de conhecimento, 109 de conteúdo; no getting-started, comandos 119 → 122 e skills
  14 → 16 (defasagem anterior a este PR).

## Achados

| # | achado | triagem | destino |
|---|---|---|---|
| 1 | o índice dizia 108 documentos de conteúdo; o disco tem 109 | bloqueia | curado |
| 2 | `method` e `locator` do selo diziam "pergunta com opções" que não existiu | bloqueia | curado: pedido direto, grau escolhido pelo core |
| 3 | a tabela de superfícies estreitava a régua da curadoria sem dizer | limite | curado: seção "Onde o core estreitou a régua" |
| 4 | "C1 medido pelo hook" sem dizer que o hook só cobre três superfícies | limite | curado |
| 5 | o exemplo "depois" deixava "juiz" e "SUPERSEDES" sem glosa | limite | curado |
| 6 | a aresta para a catraca de decisões sugeria uma autoridade que ela não dá | limite | curado: a narrativa diz que é contexto |

## Mutantes

Não se aplica: o PR é de documentação e grafo, sem código. Os gates rodados: `kg-radar.sh --integrity
--schema` (rc 0), `kg-contract-check.sh` (conforme), `kb-index-check.sh` (rc 0) e
`relay-public-review-check.sh` (rc 0).

## Limites declarados

- A régua veio de um teste com n = 2 textos e um codificador só. Por isso é doutrina e item opcional, não
  gate.
- A KB não foi conferida contra a cópia paga da norma; as seções citadas vêm da dissecação da curadoria.
