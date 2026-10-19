---
title: 'Resíduo — onda 1 do EPIPE: 75 pontos curados e a catraca que só encolhe'
date: 2026-10-19
branch: fix/epipe-wave-1
reviewed_diff_sha256: 53da0d31687ae2325c72676b7a92d1b53da387ec30fd5fbee71ca732a7ff95f4
reviewed_code_sha256: aa02b06feff436ae68a9b053bc03721513243beb3ad2c0a8b6a8b3933adc7156
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Onda 1 de D_EPIPE_VIRA_GUARDA_DE_CLASSE_1019 (fila-2026-10-06). A medição corrigiu a premissa da pergunta: a
  guarda de classe já existia (pipe-verdict-check.sh, qualquer produtor seguido de | grep -q, com catraca em
  shell_pipefail_robustness), e os três pontos que derrubaram o CI em 2026-10-19 (prettierignore, hook do shell,
  modos (0b)) estavam no PASSIVO tolerado, não escapavam dela. Achado 1: a catraca não encolhia — o baseline
  dizia 138 com 124 reais depois das curas do dia, e uma cura podia voltar calada; agora a bancada reprova
  ponto curado com baseline não baixado (DESTRAVADA). Achado 2: o passivo morde. Curados os 75 pontos da forma
  simples (printf '%s' ou echo de UMA variável) por um conversor que respeita aspas, $(...) e continuação de
  linha; a 1ª rodada dele quebrou 4 arquivos na continuação com barra invertida (pego por bash -n, revertido e
  corrigido antes de qualquer commit). Baseline 138 → 49. Prova: bash -n nos 23 arquivos; bancada completa local
  4171 passaram, 0 falharam; mutante 1 (cura revertida no consumed-mode-check.sh) reprova ACIMA; mutante 2
  (baseline antigo) reprova DESTRAVADA. Sem refutador separado (elenxo: nao): a transformação é mecânica e a
  bancada completa é a prova. Fica para a onda 2: 49 pontos de forma composta (find, git, bash x seguidos de
  grep -q), que pedem captura em variável à mão.
---
