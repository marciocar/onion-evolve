---
branch: docs/coord-research-first-1102
pr: pendente
date: 2026-11-02
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 3
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão do core (passada inline; diff de um grafo)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `docs/coord-research-first-1102`

## O que muda

Duas evidências de testemunho no grafo de coordenação, com o «pesquise antes» do maestro na rodada 2 do
`/meta:decide` de 2026-11-02 (vigia de eventos e portas do onion-core), mais as arestas. Nenhum selo.

## Achados

1. Hipótese: gravar a resposta poderia fechar `Q_COORD_DECIDIR_VIGIA_DE_EVENTOS` por engano. Não fecha: o nó
   novo é `evidence` com SUPPORTS, e a pergunta segue `open`, porque pesquisar antes não é escolha.

2. Medido no lint: o grafo passou do teto de 40 (42). Curado no mesmo PR: colhidos os 8 nós done (o selo segue em @4f5513fd4) e aberto Q_COORD_CORE_PIN_NO_SELADOR_1102.

## Mutantes

Nenhum: não há código. Radar `--integrity --schema` exit 0 depois da escrita.

## Limites declarados

A edição foi à mão porque o selador só grava escolha; o caminho do Gmail não foi perguntado e fica dito no label.
