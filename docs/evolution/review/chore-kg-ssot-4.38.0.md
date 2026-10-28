---
branch: chore/kg-ssot-4.38.0
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: pendente
reviewed_code_sha256: pendente
findings_total: 3
findings_real: 3
tokens: 73779
duration_min: 4
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente revisor novo (code-reviewer), só leitura, sem a conclusão da sessão de adoção, sobre o diff contra a origin/main fora do vendor"
nota: "o revisor leu o check_schemes e o main_digest do kg_trace.py do vendor como contrato, rodou a família kg_trace_resolve, o kg_trace check sem --with e o digest do nó da curadoria; tokens e duração são os do subagente"
---

# Passada adversarial: `chore/kg-ssot-4.38.0`

## O que muda

A adoção da kg-ssot 4.38.0 (contrato v4.18, só SHOULD). No core:

- o vendor sobe e o `.kg-ssot/gate/` grava a identidade do contrato v4.18 (MUST e SHOULD idênticos);
- a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE): o `integrity.trace-node-sha256-mismatch` sai com o nó
  e a cura própria (o `digest` do produto), HARD no core e SOFT no derivado; o `not_canonical` do skipped entra no
  `SCHEME-AVISO`; casos (n1)-(n3) e dois mutantes;
- dois traces para `memory/…` saem, com a origem na narrative;
- `Q_COORD_MAESTRO_SELAR_PRODUTO_KGSSOT` fecha como done; `Q_MA_FREE_ORG_READ_ENFORCED` troca o `sha256` do arquivo
  pelo `node_sha256` do nó citado.

## Achados (3 reais, 2 corrigidos, 1 respondido)

1. **Comentário defasado no `kg-trace.sh`** (baixa): o exemplo do `Q_MA_FREE_ORG_READ_ENFORCED` falava só do sha256, e o
   nó passa a usar o node_sha256. Cura: o texto diz "o sha256 ou o node_sha256".
2. **A cura da mensagem não servia para nó de outro repo** (baixa): o `digest` lê a árvore de trabalho, e o
   `check --with` lê o commit fixado. Cura: a mensagem diz que, para nó de outro repo, o digest roda sobre o arquivo do
   commit fixado no `source`; e o comando ganhou o `-B` da casa.
3. **O fechamento do nó de coordenação cita um `git show 55db567` que o revisor não reproduziu** (baixa): o isolamento
   dele recusou git fora da worktree, e o clone `kg-ssot` local é o espelho público, sem `docs/onion/graph`.
   Respondido com a medida: o repo das decisões é o `onion-kg-ssot` (privado, no `members.yaml`), e na origin/main
   dele (55db567) `D_KG_SSOT_PRODUTO_SEPARADO` está `done` com `verified_at` 2026-10-24 e
   `D_KG_SSOT_PRODUCT_FORM_1007` está `done` com `verified_at` 2026-10-25, lidos pela sessão de adoção. É leitura de
   artefato, então o `evidence_class: testimony` sai. Do mesmo jeito, o `node_sha256` foi calculado sobre o arquivo
   exportado do commit 518b332 (não da árvore da curadoria), e o `kg_trace check --with` do prefixo `/blob` deu rc 0 com
   `node_sha256_checked` 1.

## Não reais (testados pelo revisor)

- O `not_canonical` do aviso não nomeia o nó: o produto só dá a contagem.
- `not_json` e `not_text` fora do aviso: não-julgado por desenho, anterior a este PR.
- As âncoras dos dois mutantes são únicas e mordem pelo motivo certo; o `contract.json` confere com o hash do contrato.
