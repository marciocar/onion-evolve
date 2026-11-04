---
branch: docs/coord-registros-1104
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: "kg-ssot achou a citação quebrada, por kg_query --revisit --with; sem outra passada adversarial neste diff"
nota: "tokens e duração 0 = não medido. Só registro: grafo de coordenação e diário."
---

# Passada adversarial: `docs/coord-registros-1104`

## O que muda

- `D_COORD_SQLITE_EM_PROJECT_VEREDITO_1103` volta ao grafo de coordenação, sem mudar o conteúdo, com a aresta que tinha.
- `Q_COORD_CORE_COMPANY_BRAIN_MARKET_PROPOSAL` passa a `done`, porque o selo condicionado teve a condição cumprida.
- O label de `Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA` deixa de dizer que o gatilho segue aberto.
- `DIARIO.md` da orquestração ganha a janela de 2026-11-04, com decisões, desfechos, estratégias e o que deu errado.

## Achados

1. A colheita de 2026-11-04 apagou um selo que dois nós da curadoria citam, com o comentário «sem referência em outro grafo». A checagem só varreu este repo. Curado devolvendo o nó, e a lição está na memória da sessão.

## Mutantes

Não se aplica: só registro.

## Limites declarados

O comentário da colheita segue como afirmação sobre o que foi varrido; os outros dois nós colhidos não foram reconferidos contra os repos peer além do grep citado. O diário é relato da sessão do core, conferido contra as saídas dela, sem revisão das peers.
