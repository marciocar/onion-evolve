---
branch: chore/seal-maestro-decisions-1109b
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 3
tokens: 0
duration_min: 15
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução, relendo o diff contra o estado dos nós; sem subagente, porque o brief proíbe criar agentes"
nota: "tokens = 0: não medido. PR só de grafo, sem código. O gate foi radar --integrity --schema, contrato e lint de nomes nos 6 grafos tocados."
---

# Passada adversarial: `chore/seal-maestro-decisions-1109b`

## O que muda

Grafo novo `maestro-decisions-1109b` com cinco selos do `/meta:decide` de 09/11 e duas perguntas abertas. O
`D_MA_ARCH` e a pergunta das portas selam pelo `kg-decide-seal.sh`. Três perguntas fecham pelo fluxo normal,
citando o nó que as responde.

## Achados

| # | Achado | Destino |
|---|---|---|
| 1 | O label do selo dos atos do maestro trazia o código `P12` sem glosa. O selador não julgou nomes, porque o grafo ainda não estava rastreado, e o `kg_vocab.py lint` acusou depois do `git add`. | Curado: o label diz o que o teste é; o locator guarda a pergunta literal. |
| 2 | A narrativa de `Q_PS_RODADA_DECIDE_D_MA_ARCH_1116` dizia que o selo não esperou a pesquisa, mas `Q_PS_PESQUISA_DO_RUNTIME_1110` já estava `done`. | Curado: só a escada segue aberta. |
| 3 | O `D_MA_ARCH` selado segue com `DEPENDS_ON` para `Q_MA_MARKET`, ainda `open`, que não foi nomeado como portão. | Curado: conferido no grafo que a proposta de mercado foi aceita e a condição dela, cumprida em `Q_MA_FREE_ORG_READ_ENFORCED`; `Q_MA_MARKET` fecha citando `D_MA_PROPOSTA_DE_MERCADO_ACEITA_CONDICIONADA_1104`. Não é portão. |

Re-revisão depois do acréscimo das condições do kg-ssot à narrative do `D_MA_ARCH`: o parágrafo novo diz que é proposta e que não é decisão do maestro; o id citado é de outro repositório e está dito assim. Radar, contrato e lint de nomes verdes no grafo. Sem achado novo.

## Mutantes

Não se aplica: o PR não muda código nem guarda.

## Limites declarados

- A medida que cumpre a condição de `D_MA_PROPOSTA_DE_MERCADO_ACEITA_CONDICIONADA_1104` não rodou o passo de desligar o fork, que pede `admin:org`.
- O texto das perguntas dos selos, exceto o dos atos do maestro, foi redigido a partir do brief, sem o enunciado literal da rodada.
