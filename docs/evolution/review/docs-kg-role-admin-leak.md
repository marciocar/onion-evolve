---
branch: docs/kg-role-admin-leak
pr: TBD
date: 2026-08-14
reviewed_diff_sha256: 621dbf1f64e4a6640282b10b80b519f0e5ad6e574a656abc474a3b3e1933a8f1
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 15000
duration_min: 5
verdict: CORRIGIDO
reviewer: verificação claim→medição (cura executada e provada na Management API nesta sessão)
---

# Passada adversarial — `docs/kg-role-admin-leak`

Carimbo de 1 evidence (impact 5). Conferência claim→medição: DELETE do scope retornou
204 e a re-listagem mostra bridge-user=[invoke,write] (lido, não presumido); papel
bridge-admin criado (201) e atribuído ao marciocar (201, re-listado). O label declara
os DOIS resíduos honestos: tokens pré-cura sem revogação (≤1h) e bridge:write ainda
universal (gated). Radar exit 0.
