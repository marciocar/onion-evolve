---
branch: docs/kg-writer-probe-1021
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 2bdec83f11ce1047b6f531094078fece5d47d45a66735ce2041651c344013da6
reviewed_code_sha256: 035372ed21a35a36f0637e3132bba8190abb954f3080442440dc7931c1c69cb4
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 3
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; um nó PROD de evidência do probe"
---

# Passada adversarial: `docs/kg-writer-probe-1021`

## O que muda

Um nó PROD, `E_WRITER_2CBE59D9_PROBE_AUTENTICADO_1021`, que apoia `A_MCP_KG_WRITER_SERVER`.

## Achados

1. A aresta caiu dentro de `external_edges`, porque o arquivo termina nessa seção, e o radar acusou nó
   órfão. Curado: a aresta foi para `edges`, e o radar e o contrato saem 0.

## Mutantes

Não se aplica.

## Limites declarados

A saída do probe foi colada pelo maestro. O HEAD da worktree de código eu medi por conta própria.
