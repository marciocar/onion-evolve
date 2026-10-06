---
title: 'Resíduo — semente em documento único, aviso multi-documento, material didático fora do corpus e CONSTRAINS em audit'
date: 2026-10-06
branch: fix/kg-seed-single-doc-and-constrains
reviewed_diff_sha256: a48d8763a5111ee63fcbff53b7576c9265fa265ab531c83ca9cea4c7ffc529ce
reviewed_code_sha256: ce1d13c419062b49808f2ef68fa9961c91098afbad95c9d4c4e3f39dbbf00066
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Triagem de dois sinais do onion-slm (2026-10-06), aprovada pelo maestro: os itens A, C4 e C1.
  (A) A semente do /meta:adopt abria e fechava o cabeçalho com `---`: são dois documentos YAML. O radar
  aceitava; o kg-drive-project.sh recusava com exit 2, e o 1º grafo de todo adotante nascia fora do
  /meta:drive. Cura: documento único, e o radar AVISA multi-documento (SOFT, sem reprovar). Medido: a
  semente sai com 0 separadores, e radar e drive dão exit 0 (antes o drive dava 2).
  (C4) `docs/materials/` (grafo didático, dados fictícios) sai das LEITURAS de conhecimento: classe
  KG_DIDACTIC_RE e modo --filter-knowledge no kg-fixture-paths.sh, usados pelo kg-corpus-grep e pelo
  passo 0 do /warm-up, /catch-up e /engineer:work. Segue validado pelo --filter, sem ganhar isenção de
  catraca. Medido: o corpus cai de 138 para 137 grafos, e o C_CHURN_HIGH sai da busca.
  (C1) A ontologia e a tabela da kg-grammar passam a admitir CONSTRAINS em audit com o sentido "limita
  sem derrubar", que é o que a própria gramática (l.37) mandava e o corpus faz (724 de 777, 93%).
  Bancada: seed (a2) documento único e drive lê; (a3) aviso multi-documento; kg-fixture-paths --selftest
  com o didático fora do knowledge e dentro do filter. Três mutantes mordem: a semente com `---`, o
  radar sem o aviso e o filter-knowledge sem o didático. Sem Elenxo, declarado: a doutrina (C1) foi
  decisão do maestro na triagem, e os mecanismos têm mutante.
---

# Resíduo — `fix/kg-seed-single-doc-and-constrains`

Teto declarado: o aviso multi-documento é SOFT; um adotante com grafo antigo de `---` segue legível pelo
radar e recebe o aviso, sem reprovar. A semente de adotantes JÁ adotados (o onion-curation nasceu com
ela) não é reescrita por este PR: o --update não regera a semente, e cada um a corrige no próprio repo
ou recebe o aviso.
