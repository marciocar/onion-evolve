---
branch: docs/agent-transport-live-n2
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/agent-transport-live-n2`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`:
  - `E_N2_VIVO_INTERLINK_MEDIU_O_ENVIO_SEM_DIALOGO_1025`: o resultado do round-trip vivo da curadoria, com o envio
    sem diálogo do Claude em bypass.
  - `Q_COMPOSICAO_IDA_E_VOLTA_VIVA_1025`: o gatilho novo do parque, com os negativos.
  - Três arestas ligam os dois ao `D_TRANSPORTE_ENTRE_AGENTES_PARQUEADO_COM_GATILHO_1025`, que segue `done`.

## Suspeitas descartadas

1. Tratar o round-trip como gatilho cumprido: descartada. Ele mediu o interlink-mcp, não a composição, e o Elenxo
   da curadoria o rejulgou pela mesma régua.
2. Construir a composição agora pela delegação: descartada. Construir troca parquear por perseguir, e mudança de
   direção de produto segue com o maestro; a Q diz isso.

## Mutantes

- Nenhum: a mudança é só de grafo. O radar `--integrity --schema`, o contrato e o lint de nomes saem rc 0.
