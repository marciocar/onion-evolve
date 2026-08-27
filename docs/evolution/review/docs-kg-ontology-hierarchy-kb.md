---
title: "Revisao — KB de ontologia+hierarquia dos grafos (Fase 0 do /meta:realign)"
date: 2026-08-27
branch: feat/kg-ontology-hierarchy-kb
reviewer: "self-review (autor) — Fase 0 do plano de realinhamento; curada por 4 pesquisas (interna+3); cross-refs validados"
reviewed_diff_sha256: 8ef3162294c1d5ecde9d08521a119e93891fb787271acb8b6e67f5543865f51c
findings_total: 2
findings_real: 1
verdict: APROVADO
tokens: 3000
duration_min: 35
---

# Residuo — REGRA 56 (self-review; KB, sem deploy)

Fase 0 do plano `/meta:realign` (plano em ~/.claude/plans/em-casos-...). O maestro a levantou como
pre-requisito: uma maquinaria que REVE grafos precisa saber que TIPO de grafo revê e como ele se liga.
A ontologia do ATOMO ja era canonica (radar); a camada MACRO (taxonomia de KINDS + topologia) era
convencao implicita. Esta KB e o lar macro.

**O que entra:**
- `docs/knowledge-base/concepts/onion-kg-ontology-hierarchy.md` — taxonomia de KINDS por papel; mapa de
  topologia/espelhamento; fronteira cross-grafo; core↔adotante = soberania; SDAAL/federacao/moat; e os 2
  avisos de honestidade (DRY do atomo aponta ao radar; a perna de LEITURA e conselho, nao mecanismo).
  Desambigua KG SDAAL de /meta:graph. NAO re-duplica os enums (aponta a fonte unica — evita o drift que
  ja fez `invariant` divergir).
- Inventario 91→92 KB + correcao do count nas superficies NAO-vendorizadas (project-charter/getting-started/
  agents-reference/INDEX).

**Achados (findings_real:1):**
1. **Cross-refs** — TODOS os 8 arquivos referenciados verificados existentes (radar, gramatica, sdaal,
   getting-started, fios-abertos, constellation, relation-vocabulary, kg-read-leg SYNTHESIS).
2. **Cascata de plugin-sync (real, evitada):** corrigir o count em `onion-framework-identity.md` (que o
   plugin vendoriza) DESSINCRONIZOU `plugins/onion` → 2 HARD. Provado por stash-check (0 sem meus edits).
   Regenerar o plugin arrasta a churn de provenance ([[plugin-provenance-churn]]). Revertido esse UM
   arquivo (fica 91, count-drift SOFT tolerado la); as demais superficies ficam 92. HARD zerado, verificado.

**Limite declarado:** a KB e a Fase 0 do MACRO. O `/meta:realign` (Fase 1) e a Fase 2 (jornada em-voo +
ordenacao direcionada) sao PRs seguintes. A KB nao muta grafo nem codigo — e documentacao de substrato.

**Nao quebrou?** lint 0 HARD (6 SOFT tolerados, 2 deles o count de identity vendorizado); cross-refs ok.

**Veredito: APROVADO** — o substrato ganhou ontologia+hierarquia canonica documentada; o realign pode
confiar em saber QUE grafo revê e COMO ele se liga.
