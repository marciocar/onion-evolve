---
branch: docs/kg-fid1
pr: TBD
date: 2026-08-15
reviewed_diff_sha256: a9f1a94d7c35cd3d4da07fff7263f4f5d5e05d2b05acfa9985ce3feab4efc611
findings_total: 9
findings_real: 9
findings_fixed: 9
tokens: 60000
duration_min: 30
verdict: CORRIGIDO
reviewer: Elenxo F-ID.1 adversarial (agente dedicado, 9 achados medidos rodando o SDK) + verificação claim→medição
---

# Passada adversarial — `docs/kg-fid1`

Carimbo de F_ID_1_ADOCAO_LIMPA done/PROD. Substância: a adoção limpa no bridge (commit
2e10b49, deployado). O Elenxo F-ID.1 mediu 9 achados rodando o Agent SDK de verdade —
CRÍTICO cross-workspace (que eu abri no P0-5) e a falsa-cura da race (minha), ambos
curados e provados por sonda: comandos onion vivos (settingSources project), próprio
legível, VIZINHO_BLOQUEADO (guardCwdRead no canUseTool), vendor-manifest 5/5. A lição
central foi de MÉTODO: o dogfood que "provou" a fase inicialmente era o modelo lendo o
comando como prosa — declarado≠verificado; o gate real virou o system/init do SDK.
Resíduo declarado: convidado sem Bash (sandbox deferido, P0-7), sem coletor por idade.
Radar exit 0.
