---
title: 'Resíduo — o merge do .prettierignore deixa de re-anexar caminho presente por EPIPE sob pipefail'
date: 2026-10-19
branch: fix/prettierignore-epipe
reviewed_diff_sha256: 9b1567fb42b8274f54d530a3a10db45d330e2994a0881a8ae8836e60c95d2817
reviewed_code_sha256: 42a33cd4fbdea01e4fc0599206a5ab3414627c3f0bfded6e6e847da19066c6e2
findings_total: 1
findings_real: 1
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Falha intermitente da bancada no CI, medida em 3 de 12 runs falhos recentes, em PRs sem relação com o helper
  (casos "prettierignore: complete" e "complete-no-header"). Causa lida no código: o merge-prettierignore.sh
  testava presença com printf | grep -qxF sob pipefail; o grep -q sai no 1º acerto, o printf leva EPIPE, o
  pipeline devolve diferente de 0 e o caminho presente era tratado como faltante e re-anexado. Cura: here-string.
  Caso novo (d2): alvo completo com mais de 64 KB depois dos caminhos torna o EPIPE determinístico; com a cura
  revertida ele reprova (medido), com a cura passa. Achado que fica, NÃO curado aqui e declarado: a mesma forma
  printf|echo seguido de grep -q aparece em 95 pontos de .claude e ops; muitos estão em scripts sem pipefail ou
  com entrada pequena. A varredura da classe é o próximo passo, e o pipe-verdict-check.sh é o lugar dela.
---
