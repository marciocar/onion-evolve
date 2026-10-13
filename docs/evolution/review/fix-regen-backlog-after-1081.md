---
branch: fix/regen-backlog-after-1081
date: 2026-10-13
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: APROVADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: lint 0 HARD e família backlog_projection
---

# A projeção do backlog volta a casar com os grafos, e o alarme do main fecha

## O que aconteceu

A bancada completa no push ao main (passo D) reprovou em `ff5abe51` (merge do #1081): o caso
`backlog-projection: em-dia` achou a REGRA 62 (Projeção GERADA em sincronia com a fonte (docs/backlog.md))
violada num sandbox limpo. O alarme abriu a issue #1086 e o PR de revert #1085, como desenhado. O drift
seguia no main atual (`825e93f6`), medido localmente: 1 HARD, a mesma REGRA 62.

## A cura

`bash .claude/validation/kg-backlog-project.sh --write`: o cabeçalho passa de 478 para 479 itens abertos.
Lint 0 HARD depois.

## Passada adversarial

1. **Reverter o #1081 seria a cura certa?** Não: o código do #1081 não toca o projetor nem os grafos que
   mudaram a contagem; a projeção ficou para trás na combinação dos merges da leva. Corrigir para a frente
   fecha o alarme sem desfazer o caminho rápido. O #1085 fecha como superado.
