---
branch: docs/ports-multi-model-synthesis
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: e2e78ea0af6deb8caf3c7b1bd3c0dbef1dc8a3b9bb8fa5f6b1b9b6b7b7d07318
reviewed_code_sha256: b2ad0cb5cbe8263b7ffa165d2a8b555307a8579b11db8bc4076db13e3d5d8018
findings_total: 3
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
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

3. **Real, medido no contrato KG-SSOT:** os códigos `R1` a `R8` (as claims refutadas na votação) iam sem glosa na
   narrativa de 11 nós. Curado: viraram «refutada 1» a «refutada 8»; o gate de nomes deu verde.

## Mutantes

Nenhum: não há código. Radar `--integrity --schema` rc 0 e contrato rc 0.
