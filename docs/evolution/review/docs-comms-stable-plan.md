---
branch: docs/comms-stable-plan
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: d6c172004e80d0d526ca92e2d1f6e7d2c130c02b31b10d7e75e784bdb06e1943
reviewed_code_sha256: a302f3551f1d4dae81f8904d2141058445fc7408a710868845588c3cca73f892
findings_total: 1
findings_real: 1
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal do core (passada própria, não independente)
nota: "tokens 0 = não medido. Diff de plano: grafo, resposta ao hub e sinais processados, sem código."
---

# Passada adversarial: `docs/comms-stable-plan`

## O que muda

- **Grafo novo `docs/onion/graph/comms-stable-2026-11.kg.yaml`:** as 6 decisões do maestro de 2026-11-06 e os compromissos até segunda, 09/11, cada um com dono, data e critério de pronto.
- **Resposta aos três sinais do hub:** vai na staging do outbox (já entregue sem commit no inbound do hub), e os sinais passam para `_processed/`.

## Achados

1. **Real, curado:** uma aresta externa apontava para o grafo da pesquisa do runtime, que ainda não está na main (PR #1507). O contrato reprovava por alvo pendurado; a aresta saiu e volta depois do merge.

## Mutantes

Nenhum: o diff não tem código.

## Limites declarados

- A passada não é independente.
- As datas de segunda dependem dos atos do maestro (criar o repo, o app Slack, o `channelsEnabled` e o `!` do deploy).
