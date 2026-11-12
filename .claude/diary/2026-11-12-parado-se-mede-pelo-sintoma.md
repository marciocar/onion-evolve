---
date: 2026-11-12
instance: onion-evolve
type: learning
classification: public
tags: [baton, subagent, stalled, approval, background]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Rodar /meta:baton depois de cada lote de subagentes e conferir que nenhum AGENT_STALLED passa de 15 min sem ação"
review_after: 2027-02-10
conflict_class: dynamic
significance: "Três revisores pareceram ocupados por até três horas; medir o sintoma (tool_use sem resultado) pegou a causa que ninguém tinha nomeado."
kg: "docs/evolution/research/forge-baton-2026-11/forge-baton-2026-11.kg.yaml"
---

## Signal
Agente parado parece ocupado. O que separa os dois é a idade da última prova de vida, não a frase dele. O pulso da
batuta mede o sintoma: `AGENT_STALLED` (tool_use sem tool_result há mais de 15 min) e `AGENT_SILENT` (calado sem
pendência e sem fim). As duas causas conhecidas viraram guarda.

## Evidence
- 2026-11-12: três refutadores ficaram de 1h40 a 3h parados num pedido de permissão que agente de fundo não tem quem responda.
- PR #1617: o pulso acusa o subagente parado; o refutador reprovou duas vezes (na 2ª, a regra de abandono errava 12 de 14 casos reais), tudo curado com caso e mutante.
- PR #1622: o agente de Workflow que entrega por StructuredOutput conta como fim.
- PR #1614: veto ao `run_in_background` de subagente. PR #1615: o preâmbulo de execução proíbe o que pede aprovação humana.

## Next crumb
O medidor não distingue ferramenta longa legítima de travamento (limite declarado). Medir a taxa de falso STALLED numa
semana de uso.
