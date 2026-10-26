---
branch: docs/decide-seals-1026b
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 9b42e4fbd9f5e6f4bf3f7e4e7b5f1ab043cc9fcc2a455f6f596c9c9835caae30
reviewed_code_sha256: 6b9356d1229b69a1eff2d690387116b7e97cd56b4f5c1d1710882d7e59a7317d
findings_total: 0
findings_real: 0
tokens: 56242
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-d4), passada própria sobre o diff
nota: "tokens = os do run de re-teste wf_79bb235e-71e (3 agentes); a passada própria não foi medida"
---

# Passada adversarial: `docs/decide-seals-1026b`

## O que muda

- `Q_RETESTAR_A_MIGALHA_DO_RESUME_NA_2_1_305` (r14): selada com o re-teste do run wf_79bb235e-71e.
- `Q_GUARDA_DE_ISOLAMENTO_ACEITA_O_PREFIXO_LC_ALL_DA_CASA_1023` (r17): fechada pela medida dos agentes isolados de
  2026-10-25 e 26.

## Suspeitas descartadas

1. O TaskStop não ser «morte de processo»: aceito como limite. O processo do CLI segue vivo, e o que foi parado é o
   run. A condição de outra sessão fica declarada como não testável por contrato.
2. O resume ter reexecutado os paralelos sem deixar rastro: descartada. O journal não ganhou `started` para eles, e
   os meta.json dos dois mantêm o horário de antes; só o agente editado ganhou um agentId novo.

## Limite declarado

- O gatilho do `D_ESTACIONAR_SAC180_ATE_O_1O_RESUME_REAL` (primeiro resume real de workflow com parallel que morreu
  no meio) pode ser lido como disparado por este teste. Isso fica para o maestro reabrir ou não.
