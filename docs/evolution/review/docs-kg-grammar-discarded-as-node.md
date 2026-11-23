---
branch: docs/kg-grammar-discarded-as-node
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: 1446fc6cfbba4249e80b3ca062b9163b8c631cfba39cbd8e5199fa57a53678f6
reviewed_code_sha256: ebef16137134be46431b2a29a279974a370b1bbee4ae374d06885ea6c37bb468
findings_total: 9
findings_real: 9
findings_blocking: 1
tokens: 81586
duration_min: 3
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: code-reviewer (agente separado, brief sem a conclusão do autor)
nota: >-
  Um refutador separado leu o diff inteiro, conferiu a citação do MADR 4.0.0, rodou o radar e o
  contrato e recontou os números da curadoria. Achou 1 bloqueio (o caso CONSTRAINS dava status
  refuted, que zera o nó no radar) e 5 limites. Cinco foram curados no mesmo PR; o sexto (cópia
  original no inbox do checkout principal) é operacional e fica com a sessão do core. Em 2026-11-22 a sessão do core declarou
  elenxo_isolado: true pelo reviewer e por esta nota (refutador separado, brief sem a conclusão do autor).
---

# Passada adversarial: o descartado também é nó

## O que muda

- Um parágrafo em `.claude/rules/kg-grammar.md`, logo depois de «A regra que mais custa esquecer»: a
  opção de desenho rejeitada com conteúdo próprio vira nó ligado à decisão, só adiante.
- O selo `D_DISCARDED_OPTION_AS_NODE_1121` no grafo de selos, dado pelo core na ausência do maestro e
  marcado para a revisão dele, com as duas opções de desenho descartadas já como nós (a regra aplicada
  a si mesma).
- A proposta da curadoria relida como pública e arquivada em `_processed/`.

## Achados

| # | achado | triagem | destino |
|---|---|---|---|
| 1 | o caso CONSTRAINS recebia `refuted`, que zera o nó no radar e contradiz «limite não é derrota» | bloqueia | curado: `refuted`+`REFUTES`, `superseded`+`SUPERSEDES`, `open`/`confirmed`+`CONSTRAINS` |
| 2 | «ajuste o teto» virava saída padrão e supunha teto em todo grafo | limite | curado: vale em grafo com `kg-backlog-guard: on`; colher antes, ou subir com o porquê no `meta:` |
| 3 | o gatilho de 30 dias não tinha mecanismo | limite | curado: `reverify_every: "P30D"`, `reverify_on` e `owner` no nó |
| 4 | os números da curadoria (124 grafos, 482 linhas) não se reproduzem na main e um nó os afirmava sem atribuir | limite | curado: atribuídos, com a recontagem do core ao lado |
| 5 | a narrative dizia «com kg-decide-seal.sh» sem dizer que a autoria foi reescrita à mão | limite | curado |
| 6 | o original segue no inbox do checkout principal, ao lado da cópia em `_processed/` | limite (operacional) | fica com a sessão do core, fora deste PR |

## Mutantes

Não se aplica: o PR é de documentação e grafo, sem código. Os gates rodados: `kg-radar.sh <grafo>
--integrity --schema` (rc 0), `kg-radar.sh <grafo>` (rc 0) e `kg-contract-check.sh` (rc 0).

## Limites declarados

- Decisão do core na ausência do maestro, reversível; se ele discordar, o selo e o parágrafo se refazem.
- Sem lint: o aviso «rejeitadas só em texto» só se decide depois de 30 dias de uso medido.

## Revisão isolada pós-rebase (2026-11-23)

Subagente general-purpose (opus), isolado, mandato REFUTAR, só leitura. Veredito: **APPROVED**. Gates no grafo
tocado: `kg-radar.sh` rc 0, `--integrity --schema` rc 0, `kg-contract-check.sh` rc 0, `ops-citation-travel-check.sh` rc 0.

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | `D_DISCARDED_OPTION_AS_NODE_1121` é `done` em `plane: DEV` com selo do core; a exceção da gramática cobre selo do maestro, então o radar avisa `decision-done-em-DEV` (SOFT) | sim | não | Declarado: mesmo caso de `D_PLAIN_LANGUAGE_STITCH_1121`; a cura é a autoria do core no selador (#1713) |
| 2 | O caso CONSTRAINS diz `open`/`confirmed` sem lembrar que `confirmed` exige `provenance` | sim | não | Curado na linha 64 da gramática |
| 3 | A proposta arquivada ainda mostra a forma superada | sim | não | Curado: nota de superação no topo da seção |

Nenhum grafo do corpus muda de veredito: a regra é só texto.
