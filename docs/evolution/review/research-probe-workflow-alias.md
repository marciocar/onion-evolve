---
title: "Revisão — probe do alias fable no Workflow tool (fecha Q_PROBE_WORKFLOW_ALIAS)"
date: 2026-09-02
branch: research/probe-workflow-alias
reviewer: "condutor com medição executada: Workflow run wf_5f0d93a6-28b, grep do campo model nos 2 transcripts (fable→claude-fable-5-1 1x; opus→claude-opus-5 2x) casados ao alias por agent-*.meta.json; radar --integrity --schema exit 0 (32 nós/43 arestas); backlog byte-identical LC_ALL=C; lint-artifacts rc=0, 0 HARD após corrigir DONE-NU"
reviewed_diff_sha256: badc259ee97b598dcaf72e78bf9f2c126e444b78534514bbb6933c253c09e944
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 93999
duration_min: 5
---

# Resíduo — REGRA 56

Medição de 1 turno ordenada pelo maestro (opt-in explícito do `Workflow`). Fecha a lacuna 3 da
pesquisa Fable 5.1 (PR #763).

## Achados

1. **Alias `fable` do `Workflow` = `claude-fable-5-1`** — mesmo resultado do `Agent`; a hipótese
   "o alias medido no Agent não transfere ao Workflow" era correta como cautela e falsa como fato.
   Controle `opus` → `claude-opus-5` prova que o campo distingue os aliases.
2. **DONE-NU pego pelo lint**: fechei a question sem `verified_at`/`verified_against`; a guarda
   `kg-backlog` reprovou HARD. Carimbo adicionado com o run como fonte — o mecanismo funcionou
   sem o maestro (gatilho-mecanico-funciona-sem-o-maestro).

## Não mudou

- Nenhum experimento `Q_EXP_*` executado — só a pré-condição caiu; gatilho = próximo `/meta:census`.
- Labels do E3 e da SYNTHESIS preservados como snapshot; a closure é apêndice datado.
- Auto-declaração dos workers registrada mas não usada como evidência.
