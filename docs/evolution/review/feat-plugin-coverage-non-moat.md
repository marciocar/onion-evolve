---
title: "Revisao — cobertura nao-moat dos plugins (self-review)"
date: 2026-08-25
branch: feat/plugin-coverage-non-moat
reviewer: "self-review (autor) — adiciona 1 KB + 2 comandos NAO-moat aos plugins; moat confirmado GREEN; decisao do maestro 'manter moat + preencher nao-moat'"
reviewed_diff_sha256: c11ab267abcffdfb52cf2fe20d0895b8945b0fe1158044a98ba9cf98a99b50c2
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 700
duration_min: 3
---

# Residuo — REGRA 56 (self-review)

Varredura de cobertura (duvida do maestro): medido que os verticais ja carregam os comandos de dominio
(dir-level); os gaps nao-moat reais eram poucos. Decisao do maestro: manter o moat, preencher nao-moat.

- **Moat intacto?** SIM — confirmado GREEN pela REGRA 61 (guarda por expansao). A meta-fabrica
  (create-*/adopt/evolve/federation/absorb-skill/co-deliver) segue core-only, bloqueada. Nada de
  auto-replicacao nem grafo privado nos plugins.
- **So nao-moat adicionado?** SIM: KB onion-framework-identity (o que E o Onion) -> onion; /meta:backlog
  (projeta o backlog dos grafos DO ADOTANTE) + /quick:analysis -> onion-work-tools. Todos capacidade,
  nenhum e fabrica nem SSOT privado do core.
- **Deps fechadas?** SIM: backlog cabeia kg-backlog-project.sh + kg-backlog-check.sh — adicionados ao
  VALIDATION do work-tools (dead-ref fechado). tree_sha regenerado. lint 0 HARD, kg-radar exit 0.
- **Deixados de fora com criterio?** SIM (transparente no commit): inventory/graph (manutencao de
  meta-doc do framework), kg-inbox (co-evolucao/federacao), personality-sync (core), runflow-dev (nicho).

**Veredito: APROVADO** — adicao criteriosa de capacidade nao-moat, fronteira de moat provada intacta,
deps fechadas. Falta re-materializar + push do repo publico.
