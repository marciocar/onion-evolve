---
branch: docs/kg-fid2
pr: TBD
date: 2026-08-15
reviewed_diff_sha256: 4b2c73046c90ec50889323fa729965488118009d3155a9e2a83c1321a2af5046
findings_total: 14
findings_real: 14
findings_fixed: 12
tokens: 80000
duration_min: 40
verdict: CORRIGIDO
reviewer: Elenxo F-ID.2 adversarial (agente dedicado, 14 achados medidos rodando o SDK) + verificação claim→medição
---

# Passada adversarial — `docs/kg-fid2`

Carimbo de F_ID_2_CONTEXTOS_ORG done/PROD. Substância: dual-token + workspace/thread por
org (commit 83033b2, deployado). O Elenxo F-ID.2 mediu 14 achados rodando o SDK. O
dual-token resistiu a 7 ataques (montou JWKS controlado, cunhou tokens que o
verifyAccessToken REAL aceita — todos os negativos fail-closed). Dos 14: 12 curados
(2 CRÍTICOS provados por sonda — conflito de org não publica mais marcadores; realpath
nega symlink escape) e 2 declarados sem cura por serem UX/fail-closed (cota de org na
conta pessoal; token combinado recusado). Conferência claim→medição: origem de org SEM
marcadores após conflito real; resolve passaria o symlink, realpath nega; bench verde.
Radar exit 0. Resíduo: spike do org token humano real pendente de login vivo.
