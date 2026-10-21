---
branch: docs/research-audit-reanchor
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: a21fa7bac8ec7eaac579ec7dfcc5c6d32f971c74b07b5050fd015e17e7f6cc95
reviewed_code_sha256: 2d127175cc51f38bd5a21825ed433ec288c2f4cfe235063bfbba6bb22cc8289e
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 5
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão principal (passada sobre o apêndice do run)
nota: "tokens 0 = não medido na passada da sessão; o Elenxo do run wf_1bc82958-bf5 é a passada adversarial do conteúdo"
---

# Passada adversarial: `docs/research-audit-reanchor`

## O que muda

22 nós apendados ao grafo da auditoria pela reancoragem, um apêndice datado na `SYNTHESIS.md` e o
retorno do run em `data/`.

## Achados

1. O retorno do run trazia caminho absoluto da máquina. Curado: o prefixo virou caminho relativo ao repo.

Conferi também que os 57 nós da rodada 1 não mudaram de texto (o diff só acrescenta) e que o apêndice
marca as superações como leitura, sem âncora independente.

## Mutantes

Não se aplica: dado de pesquisa e projeção.

## Limites declarados

Não reli o metaschema do OSCAL. As linhas citadas nas superações (l.915-924, l.974, l.1896) vêm do run.
