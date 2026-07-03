---
date: 2026-07-03
instance: onion-evolve
type: learning
classification: public
tags: [workflow, orchestration, resume, cache, resilience]
affects: [meta, engineering]
breadcrumb_for: [onion-orchestration, meta:orchestrate]
share_with: [collective]
next_recommended: "2026-07-03-sandbox-selftest-exposes-latent-bugs"
review_after: 2026-10-01
conflict_class: conditional
valid_when: "a ferramenta Workflow mantém resume por runId com cache por (prompt, opts) inalterados"
---

## Signal
Run de orquestração grande que morre no meio NÃO se relança do zero — se retoma com
`resumeFromRunId` + o MESMO `args`: agentes concluídos voltam do cache instantaneamente e só o
que falhou re-roda. A pesquisa breadcrumbs (106 agentes) sobreviveu a 2 mortes distintas
(conexão caiu na síntese; limite de sessão matou 29 verificadores) e completou na 3ª passada
pagando só o delta.

## Evidence
- Run `wf_b1cf8d42-e18`: passada 1 = 105/106 done, síntese morreu (connection closed); passada 2
  = 77 do cache + re-verificação, morreu no limite de sessão (29 erros); passada 3 = tudo do
  cache + síntese nova = 106/106, ~1,4M tokens (vs ~3,7M da 1ª) — o cache pagou 2/3 do custo.
- Armadilha conhecida (2026-07-01, run anterior): retomar SEM repassar `args` quebra
  (`"No research question provided"`) — o resume exige scriptPath + resumeFromRunId + args
  idênticos.
- Antes de diagnosticar resultado vazio de run retomado: ler `journal.jsonl` do transcript dir —
  cache pode legitimamente conter resultado vazio.

## Next crumb
Em qualquer orquestração longa: guardar (scriptPath, runId, args) assim que o run lança — é o
bilhete de resgate. Se um run morrer por limite de sessão, retomar após o reset em vez de
relançar. Candidato a nota permanente na skill onion-orchestration se acontecer de novo.
