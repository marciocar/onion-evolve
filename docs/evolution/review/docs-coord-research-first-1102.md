---
branch: docs/coord-research-first-1102
pr: pendente
date: 2026-11-02
reviewed_diff_sha256: f936a2ab3f4add7c9e387b1606351dcbeb2847995c6050d0071fe8a325bef8d5
reviewed_code_sha256: 66617e6dcca58369c44457d663377f6a26116da9f90f12057b4c883306aff365
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 3
findings_fixed: 0
verdict: SEM_ACHADOS
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

## Mutantes

Nenhum: não há código. Radar `--integrity --schema` exit 0 depois da escrita.

## Limites declarados

A edição foi à mão porque o selador só grava escolha; o caminho do Gmail não foi perguntado e fica dito no label.
