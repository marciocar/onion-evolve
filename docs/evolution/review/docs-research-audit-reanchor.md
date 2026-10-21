---
branch: docs/research-audit-reanchor
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
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
