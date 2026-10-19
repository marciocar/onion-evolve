---
title: 'Resíduo — onda 2 do EPIPE: os pontos compostos e o baseline em 3'
date: 2026-10-19
branch: fix/epipe-wave-2
reviewed_diff_sha256: 4f938b98def108896dabda8d87a67e680466fc1297d83728ac4d84c7aa270a1c
reviewed_code_sha256: dae63e0cccdbe40b943af79df6ff4f5521424be24e2451503e51d32af99a8b88
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 75
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Onda 2 de D_EPIPE_VIRA_GUARDA_DE_CLASSE_1019. Os pontos compostos (produtor seguido de | grep -q) viram
  grep -q P <<< "$(produtor)": a substituição lê a saída inteira, sem EPIPE. 45 por conversor, restrito às
  linhas que o pipe-verdict-check reporta e lido troca a troca; 8 à mão (multilinha, texto executado por eval,
  curl dos wrappers do bridge). Baseline 49 → 3 (os fixtures do selftest da própria guarda, que ficam). Mudança
  de sentido DECLARADA: o status do produtor deixa de pesar, e o veredito vira só "o padrão está na saída".
  Três achados, todos curados antes do commit: (1) a 1ª rodada do conversor errou o `)` de padrão de case e um
  | dentro de comentário, pegos por bash -n, revertidos e reaplicados só nas linhas reportadas; (2) a bancada
  completa reprovou o (b5c): dentro de $(...) a bancada não enxerga o handler de EXIT do pai, então trap -p
  passa a ser gravado em arquivo no shell corrente; (3) um comentário do lint citava a forma literal e a guarda
  o contava, reescrito. Prova: bash -n nos 12 arquivos; bancada completa 4170/1 antes da cura do (b5c), e as
  duas famílias tocadas verdes depois; mutante 1 (update-bridge.sh revertido) reprova ACIMA; mutante 2
  (baseline antigo) reprova DESTRAVADA. Sem refutador separado: transformação mecânica, revisada linha a linha.
---
