---
name: analysis
description: |
  Análise rápida usando template padrão.
  Diferença vs /meta:analyze-complex-problem: este é o caminho RÁPIDO (template único, sem tipagem, sem gate); o analyze-complex-problem é a análise estruturada para casos críticos (migrações, arquitetura, performance).
allowed-tools: Read Write
category: quick
tags: [analysis, quick, template]
version: "3.0.1"
updated: "2026-06-27"
---

faça uma análise usando o template `.claude/commands/common/templates/analysis-template.md` sobre 

<requirements>
#ARGUMENTS
</requirements>

coloque o resultado em docs/analysis/*.md

> ⚠️ **Grafo primeiro, markdown como VISTA** (sinal de campo de um adotante regulado, 2026-07-20). `docs/analysis/`
> está no escopo **HARD** do gate de proveniência invertido (`kg-provenance-coverage.sh`): documento novo
> aqui **precisa ser citado** por algum nó (`trace:`/`evidence:`) de um `.kg.yaml`. Ordem correta: modele
> os achados no grafo **antes** de renderizar o relatório — o markdown é projeção, não fonte paralela.
> O erro que originou esta regra entrou no **planejamento** ("saída: relatório.md"), não na execução.

