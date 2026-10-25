---
branch: fix/kg-trace-empty-corpus-rc3
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: dad9a2e62975d0a6c5f16bb83f9bc8bf58e4ad6c1ea69afe33e9728d1fb5a44b
reviewed_code_sha256: 59dd367bb68b1dbaa3adba08dcd88b8c7dfc34b1b5069bf47b6f6753fdef6f7d
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff; o achado de origem é do Elenxo do onion-kg-ssot
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/kg-trace-empty-corpus-rc3`

## O que muda

- `.claude/validation/kg-trace.sh`: o rc 3 do `kg_trace.py check` (kg-ssot >= 4.27, nenhum grafo lido) deixa de
  ser ENTRADA-QUEBRADA.
  - Modo humano: sai 0 com aviso no stderr.
  - TSV: se o JSON não vier, entra um JSON mínimo (`judged 0`), e a guarda de vacuidade julga como sempre. Sem
    achado, sai 0.
  - `--emit-index`: sai 3 com "índice VAZIO … resolv", o que o lint (REGRA 84 (Índice de leitura do KG em
    sincronia com os traces)) e a porta (`materialize-door.sh`) já tratam como dia 1 legítimo.
- `.claude/validation/lint-selftest.sh`: caso (i) na família `kg_trace_root_file`, com um produto de mentira que
  sai 3 sem JSON.

## Achados

1. REAL, corrigido (achado do Elenxo do kg-ssot): o `case 0|1` das linhas 63 e 97 tornaria todo adotante sem grafo
   um HARD de ambiente assim que adotasse a 4.27.

## Suspeitas descartadas

1. O rc 3 cegar a guarda de vacuidade: descartada pelo caso (i). No sandbox com `trace:` no corpus, o TSV segue
   saindo 1 com VACUIDADE.
2. O modo humano não julgar vacuidade com rc 3: aceito. O modo humano nunca julgou vacuidade; quem julga é o TSV,
   que o lint consome.

## Mutantes

- O `kg-trace.sh` da `origin/main` reprova o caso (i): rc humano/tsv/índice = 3/1/2, com ENTRADA-QUEBRADA. Com a
  cura, as famílias `kg_trace_root_file` e `kg_trace_resolve` passaram 24 de 24.
