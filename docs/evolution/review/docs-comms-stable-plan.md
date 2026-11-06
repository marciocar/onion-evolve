---
branch: docs/comms-stable-plan
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: e3b78b015b91499b89c43c4cca6f45d4317ad4af1d37cf654279f3c008d22a30
reviewed_code_sha256: 07810f125d770d41c59f3bafde183c35489ad2ab1a20635a19659102be669fce
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
