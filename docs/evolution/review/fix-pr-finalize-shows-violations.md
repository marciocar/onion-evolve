---
title: 'Resíduo — o pr-finalize nomeia as violações HARD quando reprova'
date: 2026-10-07
branch: fix/pr-finalize-shows-violations
reviewed_diff_sha256: dfe0afb92138dd3eb3aa46402bf3755e71efbc6e2ac8431d1b7e6e09716a6692
reviewed_code_sha256: 0941d70c77abb776b439bcfd6808008b5ec51fd79df8c0765d97cabcd0cc3c5d
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  1ª das quatro melhorias de Q_PR_FINALIZE_MELHORIAS (fila-2026-10-06), a de maior atrito medido: em 2026-10-06
  o motor reprovou com "HARD=N" e a sessão relintou a árvore inteira QUATRO vezes para descobrir qual era a
  violação. A raiz: a linha VIOLATION do lint não diz a severidade, e o sumário só CONTA. Mudar o formato da
  linha quebraria o pre-push e a bancada (leem ^VIOLATION), então a cura não muda formato: o lint grava as HARD
  em ONION_LINT_HARD_FILE quando a variável existe, e o motor a pede ao julgar o commit e IMPRIME a lista ao
  reprovar. Bancada: família nova lint_hard_file — (a) a HARD de uma fixture da REGRA 12 chega ao arquivo,
  nomeada; (b) a fixture boa não escreve nada; (c) o motor pede e imprime a lista. Mutante (o lint não grava)
  morde. Família pre_push 31/0. As outras três melhorias (registro de etapa e rc com trap, catracas estáticas no
  checkpoint, rebase com índice sujo) seguem abertas no nó. Sem Elenxo, declarado.
---

# Resíduo — `fix/pr-finalize-shows-violations`

Teto: a lista mostra só as HARD; quem quiser as SOFT ainda roda o lint.
