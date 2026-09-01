---
title: "Revisão — hook protect-main: fallback só para push NU + selagem final da Onda 7"
date: 2026-09-01
branch: fix/protect-main-bare-push-scope
reviewer: "2º falso-positivo de PRODUÇÃO medido (loop de merge sentado na main pushando '$br' de feature foi vetado): fallback branch-corrente agora só se aplica a push NU (flags apenas); bateria 5/5 re-provada; selos da onda só com PR MERGED provado (mergedAt citado); censo DONE"
reviewed_diff_sha256: 412fbb3737e76b033d11fcb9aa4228d7a2cfd7a3b77e5b89bc4733f185480f10
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 0
duration_min: 12
---

# Resíduo — REGRA 56

Cura do 2º falso-positivo do 1º PreToolUse de produção (a guarda premia refspec explícito) +
selagem dos 4 itens da Onda 7 (PRs #748/#745/#746/#747, mergedAt citado por item). Censo: DONE.
