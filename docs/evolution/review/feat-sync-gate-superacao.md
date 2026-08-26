---
title: "Revisao — sync gated no merge provado (--sync) + no de superacao no KG"
date: 2026-08-26
branch: feat/sync-gate-superacao
reviewer: "self-review (autor) — Aufhebung do erro da sessao; cura provada por comportamento; nascida como grafo"
reviewed_diff_sha256: c023b9b13a571fb4ceaa7093bdd808c14c311f5e124d2842e3121b545cba948a
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 1500
duration_min: 15
---

# Residuo — REGRA 56 (self-review; ops + KG, sem deploy)

O maestro, por dúvida socrática, pegou a inconsistência: passei a sessao inteira fazendo o site PROJETAR
do grafo (grafo-primeiro), e registrei a licao do MEU erro (checkout main encadeado a merge recusado) como
PROSA na memoria. Esta e a metade que faltava da superacao.

**Achado real (findings_real:1 — o meu proprio erro, agora superado por mecanismo, nao conselho):**
- **MECANISMO:** `ops/pr-merge-verified.sh --sync`. O `git checkout main + pull` foi movido para DENTRO do
  `case MERGED\\|*)` (pos-prova pelo estado). Os ramos `die` (merge nao provado) saem ANTES — o sync e
  estruturalmente inacessivel sem a prova. Substitui o `checkout main` encadeado à mao que me deixou em main.
- **GRAFO:** `docs/onion/graph/sync-gate-superacao-2026-08.kg.yaml` — a licao nasce como SSOT
  (D_SYNC_GATED_IN_MERGE_PROOF SUPERSEDES C_CHAINED_SYNC_IS_FLAWED; evidencia SUPPORTS). A migalha de
  memoria agora DERIVA deste grafo, nao o contrario.

**Prova por comportamento (nao declaracao):**
- `bash ops/pr-merge-verified.sh 999999 --sync` → MORRE ao ler o headRefOid, **0 'sincronizada'** na saida.
  O sync nao roda sem o merge provado. (Executado, nao inferido do codigo.)
- `bash -n` OK; `caddy`-nada aqui; `kg-radar` no grafo novo: **rc 0** (3 nos, 2 arestas, SUPERSEDES
  reconciliado, integridade limpa).
- lint 0 HARD.

**Dogfood declarado:** este PR sera mergeado com o proprio `--sync` — o mecanismo mergeia e sincroniza a si
mesmo. Se algo estiver errado no --sync, o merge desta PR o revela.

**Veredito: APROVADO** — fix-must-become-mechanism cumprido: a cura virou mecanismo + grafo, nao migalha.
