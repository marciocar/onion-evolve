---
date: 2026-11-03
instance: onion-evolve
type: innovation
classification: public
tags: [stub-llm, hooks, harness, qwen-code, mistral-vibe, custo]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Para medir comportamento de harness (hooks, veto, sinal, modos de falha), use um modelo stub compatível com OpenAI que decide pelo conteúdo do pedido e valida a chamada contra o tools do próprio pedido; o modelo real entra só como braço de confirmação, pareado célula a célula."
review_after: 2027-02-01
conflict_class: conditional
valid_when: "os clientes medidos falam a API de chat compatível com OpenAI e aceitam um base URL local"
significance: "Uma matriz de 108 células que não cabia em 9 horas de CPU com um modelo de 9B rodou em minutos, sem falta de tentativa do modelo e sem o limite de transporte de ~900 s."
kg: docs/evolution/research/port-spikes-qwen-vibe-2026-11/port-spikes-qwen-vibe-2026-11.kg.yaml
---

## Signal
**O veto é do cliente, não do modelo: meça o cliente com um modelo falso que sempre tenta.**

## Evidence
O stub (`harness/stub_llm.py`) devolve a chamada fixa quando o pedido tem `tools` e não tem resultado de ferramenta,
"DONE" depois do resultado e texto nas chamadas auxiliares; marca STUB-INVÁLIDO quando a chamada não valida. O braço
real (Qwen3.5-9B na CPU) confirmou o controle positivo e o veto do push nos dois clientes, entre 7 e 18 minutos por
célula.
