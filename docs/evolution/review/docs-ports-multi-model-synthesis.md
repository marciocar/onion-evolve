---
branch: docs/ports-multi-model-synthesis
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: 5b45517e3b18e6319370124447ea62f3eba8cffd589f0e09f741f34a34be5266
reviewed_code_sha256: 1ce2ecc40cf578fd19d1f42f2f1b8645010a31a5d6d4bbc2ef376932fb319231
findings_total: 2
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline contra o diário do run)"
nota: "tokens 0 = não medido (passada inline, sem subagente). O grafo já passou pelo Elenxo e pelo verificador do run wf_407cda39-1fb."
---

# Passada adversarial: `docs/ports-multi-model-synthesis`

## O que muda

O grafo da pesquisa de portas (gravado pelo run `wf_407cda39-1fb` em 2026-11-02 e até aqui fora do git) entra no
repo, com a SYNTHESIS como projeção e a citação dela no `trace` da pergunta.

## Achados

1. Hipótese: a SYNTHESIS afirmar mais que o grafo, ou selar a decisão. Conferido contra o `summary`, o `market`, o
   `stats` e as `openQuestions` do diário do run: cada afirmação tem par no grafo, e o `D_` segue `open`.
2. Hipótese: a medição do kg-ssot entrar como prova do core. Ela vai citada por nó e caminho@commit, marcada como
   não re-medida, e sem nó novo no grafo (o teto de 65 está cheio).

## Mutantes

Nenhum: não há código. Radar `--integrity --schema` rc 0 e contrato rc 0.
