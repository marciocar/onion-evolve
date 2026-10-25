---
branch: docs/peer-protocol-triage
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/peer-protocol-triage`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`:
  - `E_SINAL_PROTOCOLO_ENTRE_SESSOES_1025`: o sinal do estudo, com a conferência do 81 contra 79.
  - `D_PROTOCOLO_ENTRE_SESSOES_COSTURA_PEER_REF_CHECK_1025`: a peça que nasce, as que não nascem e a doutrina.
  - Uma aresta `TRACES_TO` do D ao sinal.
- `docs/evolution/inbox/_processed/2026-10-25-proposal-peer-protocol.md`: o sinal, lido inteiro.

## Suspeitas descartadas

1. O 81 contra 79 ser medida errada do core: descartada por reexecução. São dois instrumentos: a família
   `dissect_object` da bancada da casa (81 registros) e o `dissect-object-bench.py` (75 casos mais 4 de rc 3).

## Limites declarados

- A peça (o helper) não está neste PR: nasce no seguinte, com bancada e mutante.
- O texto do CLAUDE.md sobre o SendMessage, apontado como defasado, não muda aqui: mudar o CLAUDE.md fica com o
  maestro.
