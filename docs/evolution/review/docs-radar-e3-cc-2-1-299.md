---
branch: docs/radar-e3-cc-2-1-299
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 7
findings_fixed: 7
tokens: 157956
duration_min: 35
verdict: REPROVADO_E_CURADO
reviewer: juiz opus/high (subagente não-fork, mandato REFUTAR, default REPROVA), que baixou o CHANGELOG oficial e remediu cada nó no vivo
---

# Radar E3 r10: o delta 2.1.299 contra a maquinaria do core

## Passada adversarial

O juiz julgou 7 nós: 2 sustentam, 3 exageravam (população de hooks PreToolUse contada em 5 e não 6; regra
MCP que o settings não tem; revisor do CI que roda pela Agent SDK, não por `claude -p`) e 2 foram
reprovados (grep cego por construção sem `-z`; migalha do PreCompact que não existe nas branches do core).
Os 5 foram reescritos com a medição dele, conferida aqui (o `case` do hook l.12-13; 0 refs com os prefixos
do GitFlow; o manifesto do bundle l.74-78). Das omissões, 3 de impacto 2 viraram nós; as de impacto 1
estão na seção NÃO-VERIFICADOS da SYNTHESIS. Aufhebung por `x_supersedes_none`, com a deriva da r9 enviada
ao `/meta:kg-freshness` (SAC-119).
