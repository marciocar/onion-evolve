---
title: "Revisão — o 1º PreToolUse de produção (protege main de force-push)"
date: 2026-09-01
branch: feat/pretooluse-protect-main
reviewer: "bateria 7/7 (3 vetos certos incl. -qf e operador &&; 4 liberações certas incl. o caso-classe: prosa/heredoc citando o vocabulário num comando composto — o falso-positivo foi MEDIDO no próprio commit desta feature e curado por julgamento POR LINHA DE INVOCAÇÃO); sonda viva vetou antes de executar; settings.json validado"
reviewed_diff_sha256: c2914e4c083864cd7ff5e8809fd5209a76c4fed9849443a72d0635fe0f6cf8c8
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 0
duration_min: 20
---

# Resíduo — REGRA 56

I_PRETOOLUSE_USO_REAL (Onda 7): 1º PreToolUse de produção. O 1º dogfood vetou o próprio commit
(prosa citava o vocabulário) — cura de classe aplicada no mesmo loop (linha-de-invocação, não
string inteira). E_PRETOOLUSE_EM_PRODUCAO no grafo do programa.

## Colheita herdada da stack (registro canônico no resíduo da Onda 7, PR #743)

Ids (para a guarda): W6_CARTEIRA_MAESTRO_VIVO E_SELO_POR_ATO_REGISTRADO I_PROVA_PRETOOLUSE
I_BENCHMARK_DO_GATE I_PECA_CATRACA I_RADAR_SURFACE I_HERO_PELO_MECANISMO
