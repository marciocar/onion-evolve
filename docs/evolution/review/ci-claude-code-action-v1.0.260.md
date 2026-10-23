---
branch: ci/claude-code-action-v1.0.260
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: fb7c44929e1c12de73436f89b2434619ee281f46853c230a9d592cc78c6da285
reviewed_code_sha256: 66a51eb77cc1fdb2db848150cf105b39633e5d6a75f896bc55a410291098c382
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 8
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente-execucao
nota: >-
  Subida do pin da claude-code-action de v1.0.258 (6b6870e6) para v1.0.260 (commit 8d70a0dd, tag
  anotada 1c5885c4), pela decisão D_SUBIDAS_2_1_309_NA_PROXIMA_SESSAO_1022 da r16 e pela SAC-239. A
  v1.0.259 não tem notas; o compare v1.0.258...v1.0.260 tem 2 commits (o bump do CLI 2.1.309 e o
  #1915). O #1915 só muda o setupBranch, que roda no modo tag; o job com prompt roda no modo agent.
  Nenhum input nem output usado muda. tokens 0 = não medido.
---

# Passada adversarial: `ci/claude-code-action-v1.0.260`

## O que muda

Os dois `uses:` do `onion-review.yml` passam a apontar para `8d70a0dd`, e o histórico do pin ganha 4 linhas
nos dois blocos. O grafo da r17 ganha o nó `E_PIN_DO_REVISOR_SOBE_PARA_V1_0_260_1023`, com uma aresta
SUPPORTS para `Q_SUBIR_SDK_DO_BRIDGE_E_PIN_DO_REVISOR_PARA_2_1_309_1023`. A pergunta segue aberta, porque a
metade do bridge (SDK 0.3.309) depende do merge e do deploy do maestro.

## Achados

1. **Real, corrigido antes do commit.** A 1ª inserção do nó caiu dentro de `external_edges:`, porque o
   script casou o 1º `edges:` do arquivo (o sufixo de `external_edges:`). O radar com `--integrity --schema`
   deu rc 1, com aresta apontando nó inexistente, e o `kg-contract-check.sh` acusou `parse.yaml-error`. Movi
   o nó para o fim de `nodes:` e os dois deram rc 0.

Conferido sem achado:
- O #1915 lê `pull_request.head.sha` e recusa o run se o PR andou depois do gatilho, mas só dentro do
  `setupBranch`. Na `8d70a0dd`, o `src/modes/detector.ts` manda para o modo agent sempre que há `prompt`, e o
  `src/modes/agent/index.ts` não chama o `setupBranch`. Este job passa `prompt`, então a mudança não o alcança.
- Os inputs `prompt`, `anthropic_api_key` e `claude_args` e o output `execution_file` não mudam no compare.
- O sha antigo zerou no workflow (`grep -c 6b6870e649b5` = 0). O YAML parseia, e o `currency-census.sh` mostra
  a linha `action:anthropics/claude-code-action` em `1.0.260`, `em-dia`.

## Mutantes

O próprio achado 1 serviu de mutante: com o nó no lugar errado, o radar e o contrato reprovaram (rc 1). Com o
nó no lugar certo, os dois passaram (rc 0).

## Limites declarados

- NÃO MEDIDO: o revisor rodando de fato com o CLI 2.1.309. O PR que edita o workflow pode fazer a action se
  pular, então a prova da versão nova no log fica para o PR SEGUINTE com a label `review:ia`.
- NÃO MEDIDO: o modo tag com o #1915, porque este core não usa o modo tag.
