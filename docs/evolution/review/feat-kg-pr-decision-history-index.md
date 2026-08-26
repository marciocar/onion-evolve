---
title: "Revisao — indice completo dos 672 PRs como .kg.yaml (fase 1)"
date: 2026-08-26
branch: feat/kg-pr-decision-history-index
reviewer: "self-review (autor) — KG dos PRs pedido pelo maestro; gerado deterministicamente; radar exit 0; nomes comerciais scrubados"
reviewed_diff_sha256: 14aa13fee4cf19b47f6c2b293859bca3dfdfd71ab1322fec094a9dcc0fa32535
findings_total: 2
findings_real: 0
verdict: APROVADO
tokens: 1800
duration_min: 20
---

# Residuo — REGRA 56 (self-review; artefato de core, sem deploy)

Fase 1 do KG dos PRs: o INDICE completo (espinha). Grafo-primeiro; as vitrines de PR do site
(ticker/prova/historia/provas) devem PROJETAR desta SSOT, nao hand-curar (foi assim que o 448 driftou).

**O que e:**
- Gerado DETERMINISTICAMENTE de `gh pr list --state merged --limit 1000` (672 PRs, 2026-06-13..08-26).
  Gerador em `$CLAUDE_JOB_DIR/tmp/gen_pr_kg.py` (reproduzivel). Nao ha LLM na fase 1 — e indice, nao analise.
- 1 hub `E_PR_DECISION_LOG` (entity, a SSOT) + 672 nos `decision` (id PR_N, label=titulo, plane PROD,
  status done, verified_at=data REAL do merge, trace=URL) + 672 arestas TRACES_TO (zero orfao).
- Impacto pelo prefixo conventional-commit (feat/fix/refactor=3, docs/test=2, chore/ci=1) — heuristica
  LEVE e declarada, refinavel na fase 2.

**Achados verificados (2, ambos resolvidos):**
1. **Orfaos (radar reprova grau 0)** — grafo sem arestas reprovava. Resolvido com o hub + TRACES_TO por PR.
2. **REGRA 30 (nome comercial de membro privado em superficie) — HARD** — 7 titulos vaziam MetaGamify/
   Grana.Ai/GranaAi. Scrub p/ o id publico (metagamify/granaai) no gerador (reproduzivel) + defensivo p/
   BetaHauss/Tornak→gustavo-pulga. Re-verificado: 0 nomes comerciais restantes; lint 0 HARD.

**Limites declarados (fase 2, de proposito):** sem classe (incidente/doutrina/marco/mecanismo/rotina),
sem flag publicavel, sem arestas semanticas PR↔PR (SUPERSEDES/CAUSES/REFUTES). Essas exigem ler
titulo+corpo+residuo e sao a fase 'categorizar e selecionar' — orquestrada, ingerindo os 125 residuos /
71 grafos / 106 diarios ja existentes.

**Nao quebrou?** radar exit 0 (673 nos, 672 arestas, integridade limpa, schema 1); lint 0 HARD. graph.md
NAO e afetado (graph.sh gera dos agentes, nao dos .kg.yaml). Sem deploy (artefato de core).

**Veredito: APROVADO** — indice valido e completo; base da fase 2.
