---
title: 'Resíduo — o pr-finalize nomeia as violações HARD quando reprova'
date: 2026-10-07
branch: fix/pr-finalize-shows-violations
reviewed_diff_sha256: 48ddd9742c18f4b45becb7812848268582e3f5ca2c8c543ce45e2c465554f699
reviewed_code_sha256: aea0037b108e8bf4b143aa730d96e3427e64b0dceca5bc5e35b1808b415dd2bd
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: CORRIGIDO
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

O 1º CI quebrou as 4 faixas: o ramo HARD de violation() terminava em `[ -n "$VAR" ] && echo`, que devolve 1 sem a variável — o lint abortava. Só o caso (a) existia, e ele sempre definia a variável. Curado com `if … fi`, e o caso (d) roda o lint SEM a variável e exige o sumário com a HARD contada; o mutante (a forma antiga) morde.

Teto: a lista mostra só as HARD; quem quiser as SOFT ainda roda o lint.
