---
title: "Revisão — fechamento da onda da lente: migalha de diário, relatório da bancada e nó D_BANCADA_FAIXAS_E_MAPA"
date: 2026-09-03
branch: docs/onda-lente-fechamento
reviewer: "condutor (docs-only: diário + análise + 1 nó open no fios-abertos; radar --integrity --schema exit 0; backlog reprojetado)"
reviewed_diff_sha256: b3a7d3d0cfb62e8ad5a495213a9d0a0975fc86b8f835ea3a09d4a4c346f11984
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 60000
duration_min: 20
---

# Resíduo — REGRA 56

PR de docs após o merge do F4 (#778): (1) migalha `learning` do fechamento da onda F1–F4 da lente de pesquisa;
(2) `docs/analysis/bancada-faixas-e-mapa-2026-09.md` — a pesquisa de 4 eixos sobre a bancada (pergunta do maestro
"~830 não é muito?"), recuperada do run e carimbada como EVIDÊNCIA; (3) nó `D_BANCADA_FAIXAS_E_MAPA` (decision, open,
maestro sela) em `fios-abertos` com `DEPENDS_ON → W8_REAIS_EXECUTAVEIS`, como os irmãos; backlog reprojetado (REGRA 62).

## Achados

1. **A pesquisa da bancada não estava em disco**: o relatório vivia só no scratch de um job anterior (evaporado) e no
   transcript. Recuperado do heredoc do transcript e persistido em `docs/analysis/` — a doutrina "write(KG) é o último
   ato" vale também para pesquisa que ainda não virou nó: sem arquivo no repo, evidência não existe.
2. **O nó nasce `open` e a faixa rápida fica fora do repo**: o `pre-gate.sh` continua no scratch até o selo (reforço do
   maestro: mudança com embasamento, nunca no susto). O dogfood exigido antes de selar está nomeado no nó (mutante fora
   do mapa tem de disparar o failsafe).
