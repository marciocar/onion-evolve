---
branch: feat/dissect-multi-piece-verdicts
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: da8d56c1fbe302dd7ba0f73eaf282c1137e20173181f46edc1690d998a345cff
reviewed_code_sha256: e5c017c77d46b8d33d2e7e686eebad9398a49c35e3bd6f98f7460a9e98cb6503
findings_total: 3
findings_real: 2
tokens: 0
duration_min: 0
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: claude-opus-5-5 (passada própria do agente de execução, sobre o diff e o caso vivo)
nota: "tokens e duração não medidos (0). O achado real não corrigido aqui é do censo, fora do escopo, e fica declarado em Limites."
---

# Passada adversarial: `feat/dissect-multi-piece-verdicts`

## O que muda

O `dissect-object-check.py` passa a aceitar um objeto em **peças**: `meta.x_dissect_pieces: [ids]` (2 ou mais), cada
peça com o seu `x_dissect_verdict`. O item 2 aceita um veredito por peça declarada. Veredito fora delas sai
`veredito-fora-das-pecas`, peça sem veredito sai `peca-sem-veredito`, e a lista mal formada sai `pecas-mal-formadas`.
Os itens 2 (família, selo, perseguir, Elenxo), 6 (superação) e 7 (gatilho, inclusive o aviso depois do selo) rodam
em cada peça. O item 8 reprova se qualquer peça não parqueia. O selo vale **por peça**. `x_piece_verdict` é lido como
apelido, e quando diverge do campo sai `veredito-de-peca-diverge`. O `--expect-verdict` aceita `ID=V,…`. Sem peças,
tudo segue como antes.

## Achados

1. **REAL, corrigido no 2º commit.** Com o mapa `ID=V` do `--expect-verdict`, a peça que ficava fora do mapa não era
   conferida: um mapa com uma peça só deixava as outras sem juiz. Agora sai `veredito-sem-elenxo`, com caso e mutante.
2. **REAL, fora do escopo, declarado.** O `dissect-census.sh` lê só o **primeiro** `x_dissect_verdict` do arquivo
   (`head -1`). Com peças, o `--check-verdict` julga só a 1ª peça. No caso vivo ela é `costurar`, então o
   critério e a superação das peças que parqueiam não passam pelo censo, só por este checador.
3. **Hipótese refutada.** Suspeitei que o mutante por código não discriminasse os dois sites de
   `veredito-diverge-do-elenxo` (o de id estranho e o de cada peça). Ele cala os dois juntos, mas cada site tem um
   caso que só ele faz acusar. Se alguém apagar um site, o caso dele fica vermelho.

## Mutantes

A bancada gera um mutante por código, lido do fonte. Os 6 códigos novos (`pecas-mal-formadas`,
`veredito-fora-das-pecas`, `peca-sem-veredito`, `veredito-de-peca-diverge`, `veredito-sem-elenxo`, e os sites novos
de códigos antigos) têm caso, e cada caso fica verde contra o seu mutante. Placar: 98 casos + 4 de rc 3. O piso do
`run_dissect_object_selftests` subiu de 72 para 98.

O risco medido foi reproduzido no **antes** (checador da origin/main). No caso "o mesmo risco pelo apelido
x_piece_verdict", o parque de peça com o gatilho disparado sai rc 0 com 0 achado. No caso vivo da curadoria
(origin/main d4be222), quando uma medição nova SUPERSEDES o `E_N2_SPARQL_E1`, o antes também dá rc 0 calado. O
depois dá rc 1, por `veredito-duplicado` na forma literal e por `gatilho-ja-disparou: D_RDF_EXTRA_B_VERDICT` na forma
com peças.

## Limites declarados

- O censo (achado 2) segue com um veredito por estudo. Para o censo ver as peças, ele precisa de mudança própria.
- O apelido `x_piece_verdict` só vale como leitura. O estudo vivo precisa declarar `meta.x_dissect_pieces` para
  passar: sem isso, o checador agora reprova com `veredito-duplicado`, que é o achado certo.
- O checador segue julgando forma, pertença e ordem no git. Ele não julga se o corte em peças está certo.
