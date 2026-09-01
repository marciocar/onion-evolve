---
title: "Revisão — o lint SDAAL enxerga .github/workflows (I_LINT_VE_WORKFLOWS)"
date: 2026-09-01
branch: feat/lint-sees-workflows
reviewer: "extensão da REGRA 10 a workflows (consumidor sem allowlist de adapter); bancada 2/2 pelo harness-da-função (a 1ª redação com fixture fora do REPO_ROOT não seria varrida — corrigida antes de commitar); dogfood no vivo: workflows reais em silêncio; lint 0-HARD"
reviewed_diff_sha256: 07647b45c450156e9cde0a03fc8e70b6bbc11645a6154d3dc8de97d02570283d
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 0
duration_min: 15
---

# Resíduo — REGRA 56

I_LINT_VE_WORKFLOWS (Onda 8): step de Actions é shell puro — provider direto ali era a mesma
dívida SDAAL, invisível. Agora HARD com prova de mordida na bancada.

## Colheita herdada da stack (registro no resíduo da Onda 8, PR #757)

Ids: W7_GATILHOS_DISPARADOS E_SELO_POR_ATO_ONDA7 I_PRETOOLUSE_USO_REAL I_APOSENTAR_LANDING_MORTA
I_CARIMBAR_PASSIVO_KG I_MEMBERS_NO_LINT_VIVO
