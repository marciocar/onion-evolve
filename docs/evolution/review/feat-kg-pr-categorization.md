---
title: "Revisao — categorizacao dos 672 PRs (fase 2a)"
date: 2026-08-26
branch: feat/kg-pr-categorization
reviewer: "self-review (autor) — categorizacao heuristica determinística; radar exit 0; refinamento LLM dos publicaveis e a fase 2b"
reviewed_diff_sha256: e62f1d1ae7411179f5e1efef3b3f886d19327de54609b82da554a5e58c6f78f6
findings_total: 1
findings_real: 0
verdict: APROVADO
tokens: 1500
duration_min: 15
---

# Residuo — REGRA 56 (self-review; artefato de core, sem deploy)

Fase 2a (caminho 2 escolhido pelo maestro): commitar a base categorizada, DEPOIS orquestrar o refinamento
dos publicaveis (fase 2b).

**O que muda no grafo:**
- Cada PR ganha CLASSE (incidente 50 · doutrina 170 · marco 31 · mecanismo 224 · rotina 197) via hub
  `E_CLASS_*` (aresta TRACES_TO); 155 PUBLICAVEIS (incidente/doutrina/marco, impacto>=3 OU residuo) via
  2a aresta p/ `E_VITRINE_<prova|historia|ticker>`. 681 nos, 835 arestas.
- Heuristica DETERMINISTICA (prefixo + keyword), honestamente rotulada. Gerador reproduzivel em
  `$CLAUDE_JOB_DIR/tmp/categorize_pr_kg.py`.

**Limite declarado (NAO e defeito escondido):** a classe **doutrina (170) esta INFLADA** — a keyword pega
palavras comuns (grafo/radar/kg/verificado) em PRs que sao mais mecanismo/rotina. Os **incidentes (50) e a
vitrine `prova` estao afiados** (sinal especifico: cura/bloqueou/refutou/fantasma). A poda da doutrina + as
arestas semanticas PR<->PR sao exatamente a fase 2b (orquestracao sobre os 155 publicaveis, nao os 672).

**Meta-nota (erro pego e corrigido nesta sessao):** computei o reviewed_diff_sha256 ANTES do git add/commit
na 1a tentativa (diff main..HEAD vazio → sha do vazio e3b0c442...). A verificacao pegou; recomputei pos-commit.
Registro porque e a classe [[exit-code-nao-e-a-verificacao]]: o comando 'passou' mas media o estado errado.

**Nao quebrou?** radar exit 0 (integridade limpa, schema 1); lint 0 HARD; nomes comerciais scrubados (0).
graph.md nao afetado. Sem deploy.

**Veredito: APROVADO** — categorizacao completa (heuristica, rotulada), base da fase 2b.
