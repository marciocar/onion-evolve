---
branch: docs/research-audit-evidence
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 992a9aee20066324fa709ab5f3f15f0710cdfb6006940ec3531b50f502130e5c
reviewed_code_sha256: d20edc814ca5b89a3daf0d5e52777ee6e6c6c47b20997623fe8fbe7c033c4352
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 10
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão principal (passada sobre o grafo do run e a síntese)
nota: "tokens 0 = não medido na passada da sessão; o Elenxo do run (wf_25b440d5-1f7) é a passada adversarial do conteúdo"
---

# Passada adversarial: `docs/research-audit-evidence`

## O que muda

O grafo da pesquisa em modo primárias da auditoria contínua (57 nós), a `SYNTHESIS.md` como projeção
com o contrato de custo, e o retorno integral do run em `data/`.

## Achados

1. **Origem declarada inexistente.** O cabeçalho e a pergunta raiz diziam que
   `D_AUDITORIA_CONTINUA_PESQUISA_ANTES_DE_1_2` não existia. Era verdade quando o run escreveu, mas o
   PR #1244 mergeou antes do fechamento. Curado: o texto foi corrigido e uma aresta `external_edges`
   TRACES_TO foi ligada ao nó real.
2. **Caminho absoluto da máquina no retorno do run.** O `data/*.json` carregava o prefixo da home.
   Curado: o prefixo foi trocado por caminho relativo ao repo.
3. **A síntese afirmava fato fora do grafo**, o candidato `reverify_every` da sessão do kg-ssot. Curado:
   o trecho virou uma nota explícita de "fora do grafo, não é afirmação da rodada".

## Mutantes

Não se aplica: o diff só tem dado de pesquisa e projeção, sem guarda nem código.

## Limites declarados

- Não reli as 10 fontes. A ancoragem por verificador separado é do run, e esta passada confia nela.
- Varri o vazamento de cliente por lista de nomes conhecidos, e o vocabulário dessa lista é o limite.
