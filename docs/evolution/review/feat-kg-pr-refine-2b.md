---
title: "Revisao — refino LLM dos 155 publicaveis + showcase (fase 2b)"
date: 2026-08-26
branch: feat/kg-pr-refine-2b
reviewer: "self-review (autor) — orquestracao (10 workers sonnet) sobre os 155 publicaveis; radar exit 0; showcase e a projecao"
reviewed_diff_sha256: c55eec274b93f98e0293654abad62676186d597311bf789e488bf632dc5ea56f
findings_total: 3
findings_real: 0
verdict: APROVADO
tokens: 3000
duration_min: 30
---

# Residuo — REGRA 56 (self-review; artefato de core, sem deploy)

Fase 2b (caminho 2): orquestracao LLM sobre os 155 publicaveis, sobre a base 2a (#681).

**Orquestracao:** Workflow `wf_c6112131-ae9`, 10 workers sonnet/medium, ~16 PRs cada, 592k tokens,
**0 erro / 0 vazio / 0 descartado** (10/10 vivos). Cada worker leu o corpus e refinou classe + keep +
surface + one-liner + arestas. Itens extraidos do journal.jsonl (155/155).

**O que mudou:**
- **Classe afiada por julgamento**: doutrina podada (a heuristica inflava com grafo/radar/kg; o LLM
  reclassificou p/ mecanismo/rotina); incidentes reais subiram (85). Distribuicao final dos 672:
  incidente 85 · doutrina 111 · marco 26 · mecanismo 245 · rotina 205.
- **131 keep** (24 dropados como nao-showcase); vitrine confirmada: prova 72 · historia 55 · ticker 4.
- **61 arestas semanticas PR<->PR** (CAUSES/DEPENDS_ON; SUPERSEDES/REFUTES MAPEADAS p/ nao-reconciliadoras
  — ver abaixo).
- **one-liner de vitrine** por publicavel (voz Onion, comprador) no showcase report.

**Achados verificados (3, resolvidos):**
1. **SUPERSEDES/REFUTES entre PRs quebrariam a integridade** — o radar exige que alvo de SUPERSEDES/REFUTES
   vire superseded/refuted; entre PRs SHIPADOS isso e falso (o PR mergeou, nao foi invalidado). Mapeei
   SUPERSEDES->DEPENDS_ON e REFUTES->CAUSES (preservam a relacao, nao reconciliam). Radar exit 0 confirma.
2. **Arestas p/ PR inexistente** — validado: so arestas cujo `to` existe nos 672 e `to!=from`.
3. **Nome comercial** — SCRUB reaplicado no assembler (grafo E showcase): 0 restantes.

**Projecao (grafo-primeiro):** novo `pr-showcase-selection-2026-08.md` — a vista que as vitrines do site
consomem. O grafo carrega estrutura (classe/vitrine/arestas); o report carrega o copy (one-liners). Proximo
passo (separado, gated no maestro): PROJETAR de fato o ticker/prova/historia do site deste showcase, e
validar as vitrines atuais contra ele.

**Nao quebrou?** radar exit 0 (681 nos, 872 arestas, integridade limpa, schema 1); lint 0 HARD. Sem deploy.

**Veredito: APROVADO** — fase 2 (categorizar + selecionar) completa: 672 categorizados, 131 selecionados
com copy e arestas. Base pronta p/ projetar as vitrines.
