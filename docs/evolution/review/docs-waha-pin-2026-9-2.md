---
branch: docs/waha-pin-2026-9-2
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork waha-pin (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada no próprio fork); só grafo"
---

# Passada adversarial: `docs/waha-pin-2026-9-2`

## O que muda

- `E_WAHA_FIXADA_2026_9_2_1022`: medição da versão viva (2026.7.2), da última release (2026.9.2) e do changelog, com o
  PR `marciocar/onion-waha#1` que fixa tag e digest.
- `Q_WAHA_REVISAO_MENSAL_DA_VERSAO`: a revisão periódica, como pergunta open, para aparecer no backlog projetado.

## Achados

1. A 1ª ideia era marcar `review_after` no nó. Medido no `kg-radar.sh` (linha 547): o radar só lê `review_after` do
   `meta:` do grafo; num nó ele seria ignorado em silêncio. Trocado por uma pergunta open, que o `/meta:backlog` projeta.
2. A ligação a `D_WAHA_ULTIMA_VERSAO_COM_REVISAO_PERIODICA_1022` não existia na 1ª versão: o nó ainda não estava na
   main, e aresta para id inexistente reprova o radar. A decisão entrou na main antes do merge (conflito na lista de
   arestas), e o rebase resolveu mantendo as arestas dos dois lados e acrescentando `E_WAHA_FIXADA_2026_9_2_1022
   SUPPORTS` a decisão. Radar e contrato rc 0 depois do rebase.

## Mutantes

- Não se aplica: só grafo; radar `--integrity --schema` e contrato rc 0.

## Limites declarados

- A versão rodando foi medida pelo digest e pela revisão da imagem; o endpoint `/api/version` pede chave e não foi lido.
- O deploy (pull e recreate) é do maestro, porque não há wrapper em `ops/` para o WAHA.
