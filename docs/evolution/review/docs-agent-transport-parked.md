---
branch: docs/agent-transport-parked
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: a7cb3d8d9b56c9e00c87246c82ff4cb90aa5d7f3872d04dad839311bdd78d76c
reviewed_code_sha256: 602ba169296bbe49482f7fcfb921c49a936dfbd9b3a42ae2da942fc7f2266a63
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

# Passada adversarial: `docs/agent-transport-parked`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`:
  - `E_SINAL_TRANSPORTE_ENTRE_AGENTES_1025`: a proposta da curadoria (estudo de transporte), com `trace:` para o
    sinal processado.
  - `D_TRANSPORTE_ENTRE_AGENTES_PARQUEADO_COM_GATILHO_1025`: o selo do maestro (parquear com gatilho) e a
    autorização do round-trip vivo Claude ↔ Codex.
  - `Q_CANAL_ENTRE_SESSOES_NEUTRO_DO_AGENTE_1025` passa a `done`: a condição de fecho dela (sinal lido e veredito
    selado) se cumpriu.
  - Três arestas `TRACES_TO` do D novo ao sinal, ao D do estudo e à Q.
- `docs/evolution/inbox/_processed/2026-10-25-proposal-agent-transport.md`: o sinal, lido inteiro e triado.

## Suspeitas descartadas

1. Fechar a Q antes do round-trip: descartada. A Q pergunta o que falta para outro agente falar pelo canal, e o
   estudo respondeu com a composição e o gatilho; o round-trip é o gatilho do D novo, não da Q.
2. A autorização do Codex CLI vir só da curadoria: descartada. O maestro a confirmou nesta sessão, na pergunta com
   opções, e o D registra isso.

## Mutantes

- Nenhum: a mudança é só de grafo. O radar `--integrity --schema`, o contrato e o lint de nomes saem rc 0.

## Limites declarados

- O `D_AGENT_TRANSPORT_VERDICT` mora no grafo da curadoria; quem o fecha é a sessão de lá, com
  `x_dissect_sealed_by` quando a 4.27 do kg-ssot aceitar a aresta para `.claude/`.
