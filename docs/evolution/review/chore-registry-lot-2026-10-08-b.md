---
title: 'Resíduo — registro da triagem de provenance e dos sinais do onion-curation'
date: 2026-10-08
branch: chore/registry-lot-2026-10-08-b
reviewed_diff_sha256: b2a3a7e4c6ff1edf551688bb55282ab313ee1df1e67f78ed33e9e7ebeb480943
reviewed_code_sha256: e744c31fa1f34af8736bef9134990df2b1cf6e3a6a94f14922231f1bac5ce779
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CORRIGIDO
elenxo: nao
nota: >-
  PR de registro, sem superfície executável: nós, dados da triagem e sinais arquivados. A passada
  não usou agentes. Ela conferiu cada número e cada linha citada contra a fonte viva.
---

# Conferências

1. **Números da triagem × `routing.tsv`:** a coluna `final` dá A1 1.442, A2 1.546 e R 806, somando
   3.794. Bate com o nó `E_TRIAGEM_DA_PROVENANCE_DO_CORPUS` e com o `REPORT.md`.
2. **Linhas citadas pelos sinais, abertas no core:** `kg-trace-resolve.sh` (a condição (b) exige `/`) e
   `kg-read-leg.sh` (o `./` é removido antes do casamento). Também conferi que `pr-merge-verified.sh`
   faz rebase por padrão e só `--merge-commit` preserva o SHA. O que os sinais afirmam procede.
3. **Os dois grafos:** `kg-radar --integrity --schema` exit 0 e `kg-contract-check` rc 0. O
   `kg-read-leg-2026-08` está "sem piorar o SHOULD herdado".

# Achado (real, curado)

- O `kg-contract-check` reprovou `integrity.orphan-node`: `Q_TRACE_DE_ARQUIVO_DA_RAIZ_CEGO` tinha
  entrado sem aresta no grafo do contrato. O nó não pertencia ali. Movi-o para o grafo da sua classe,
  o `kg-read-leg-2026-08`, ligado a `E_glob_blind_36pct` (outra cegueira da perna de leitura por regra
  de descoberta).

# Tetos

- O método `"<classe>: <detalhe>"` foi usado nos nós novos. O canônico só vira MUST no v5.
- A concordância da triagem foi julgada pelo próprio autor do classificador. Está declarado no nó e no REPORT.
