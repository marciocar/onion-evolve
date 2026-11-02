---
branch: docs/coord-decide-2026-11-02
pr: pendente
date: 2026-11-02
reviewed_diff_sha256: f27eda3e44e6b74674670bb94a93b8ed51989dd834af1445404499d704cf667f
reviewed_code_sha256: 84ad9b3849f3804cadef4d820cf7852cf0086ac1aff17d524994c180508eff49
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline; diff de um grafo, só escrito pelo selador)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `docs/coord-decide-2026-11-02`

## O que muda

Só `docs/onion/graph/coordenacao-sessoes-2026-10.kg.yaml`, escrito pelo `kg-decide-seal.sh` (o selador do
`/meta:decide`): três nós do documento controlado selados (`done`) e dois nós `D_` novos (personas de
vertical aceitas; nenhum nome curto para o modelo de operação), todos com a decisão do maestro de
2026-11-02 como testemunho.

## Achados

1. Hipótese: os dois `D_` novos ligam a `E_COORD_CENSO_DAS_PENDENCIAS_1027`, e não às propostas da
   curadoria, que vivem em outro repo. Não é defeito: aresta para nó de outro repo pede a URL fixada (o nó
   `Q_COORD_URL_FIXADA_NOS_SELOS_DE_FORA`, ainda aberto); o label cita o id da proposta pelo nome.

## Mutantes

Nenhum: não há código novo. O selador saiu 0 cinco vezes com o radar `--integrity --schema` exit 0, o
contrato rc 0 e o lint de nomes sem achado novo, e ele desfaz a escrita quando qualquer um reprova.

## Limites declarados

O selo dos nós da curadoria (`D_VERTICAL_PERSONAS_PROPOSAL` e afins) é da sessão dela, no repo dela.
