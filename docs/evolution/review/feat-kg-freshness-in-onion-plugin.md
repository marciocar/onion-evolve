---
title: "Revisao — kg-freshness no plugin onion (self-review)"
date: 2026-08-25
branch: feat/kg-freshness-in-onion-plugin
reviewer: "self-review (autor) — adiciona 1 comando (kg-freshness) ao manifesto do plugin onion; guarda de moat confirmada GREEN"
reviewed_diff_sha256: b298c41b9a5cb48c8c133bae61f4e81a39f7a8f14510bad0ca9b4f343ef13910
findings_total: 1
findings_real: 0
verdict: APROVADO
tokens: 500
duration_min: 2
---

# Residuo — REGRA 56 (self-review)

Fecha o gap achado pela duvida do maestro: kg-freshness (re-verificacao do grafo contra o vivo) ficava
core-only enquanto /meta:kg + kb/context-freshness ja iam via onion-work-tools. kg-freshness NAO e moat
(opera sobre os grafos DO ADOTANTE — KG-SSOT-First), so faltava distribuir.

- **Moat OK?** SIM — a REGRA 61 (guarda por expansao) foi confirmada GREEN: kg-freshness nao casa a
  denylist de meta-fabrica/federacao/grafo. Nao vaza nada.
- **Assembla limpo?** SIM — deps fecham (kg-radar ja estava em VALIDATION do onion; onion-orchestration
  em SKILLS). plugins/onion/commands/kg-freshness.md presente. lint 0 HARD, kg-radar exit 0.
- **Colocacao coerente?** SIM — no NUCLEO onion, junto do kg-radar (o detector), fechando a historia do
  runtime KG: detectar (kg-radar) + re-verificar (kg-freshness). kb/context-freshness (frescor de DOC)
  seguem em work-tools; kg-freshness (frescor de GRAFO) e runtime, cabe no nucleo.

**Veredito: APROVADO** — adicao minima, moat provado GREEN, deps fechadas. Falta so re-materializar +
push do repo publico para o kg-freshness chegar ao marketplace live.
