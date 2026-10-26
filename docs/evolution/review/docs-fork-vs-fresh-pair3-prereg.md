---
branch: docs/fork-vs-fresh-pair3-prereg
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 9681840f3498c95d72ce807f3680cd8c19df9075ae148e074ce770ff252a9470
reviewed_code_sha256: ab7d01289004c56e8a1250d96ab1d9988bd7de9b8737160b04ee09acf8ded4d9
findings_total: 0
findings_real: 0
tokens: 1012849
duration_min: 60
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: juiz cego (agente separado, 87.004 tokens) sobre os dois braços do par 3; passada própria da sessão sobre este diff
nota: "tokens = braço A 125.764 + braço B 800.081 + juiz 87.004; a passada própria sobre o diff não foi medida"
---

# Passada adversarial: `docs/fork-vs-fresh-pair3-prereg`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`:
  - `E_FORK_VS_AGENTE_NOVO_PAR_3_PRE_REGISTRO_1026`: o critério, commitado antes de rodar (6830604f).
  - `E_FORK_VS_AGENTE_NOVO_PAR_3_RESULTADO_1026`: o resultado medido.
  - O selo de `Q_FORK_VS_AGENTE_NOVO_TRES_PARES_MEDIDOS`.
- `.claude/skills/onion-orchestration/SKILL.md`: a regra na seção Gotchas.

## Suspeitas descartadas

1. O critério ter sido ajustado ao resultado: descartada. O commit do pré-registro (6830604f) é anterior ao
   lançamento dos braços, e a regra aplicada é a escrita lá.
2. O par 3 ser parecido demais com o par 2 (ambos update): aceito como limite. É o tipo de tarefa mais frequente
   da casa; um par de outro tipo seria o próximo passo, se a regra for contestada.
