---
kg: docs/evolution/research/task-manager-vocabulario-2026-10/task-manager-vocabulario-2026-10.kg.yaml
run_id: wf_8e56d56f-a8b
tokens: 1012508
agents: 13
duration_min: 11
---

# Vocabulário e matriz dos task managers — Onda 1 da SDAAL do Task Manager (SAC-62)

Pesquisa pelo `/onion-research` no modo `primaries`, com fontes nomeadas. Cada leitor abriu a doc oficial de
um provedor, e um verificador separado reabriu o documento para conferir cada citação.
- **Fontes:** 6 nomeadas. Alcançadas: Jira Cloud v3, Jira DC v2, ClickUp, Asana e Linear. Inalcançável: Zoho Projects v3.
- **Grafo:** 27 evidências ancoradas, 17 objeções do Elenxo como CONSTRAINS e 52 nós ao todo.
- **Retorno completo:** em `data/run-wf_8e56d56f-a8b.json`.

## O que a interface agnóstica (`interface.md`) herda

- **Paginação como iterador opaco** (`C_PAGINATION_AS_OPAQUE_ITERATOR`). Os 5 provedores alcançados usam 5 mecanismos diferentes:
  - token que expira em 7 dias no `/search/jql` do Jira Cloud;
  - `startAt` no DC;
  - offset no Asana;
  - cursor no Linear;
  - página no ClickUp.

  A interface expõe só "próxima página ou fim".
- **O formato do texto rico é responsabilidade do adapter** (`C_RICH_TEXT_FORMAT_IS_ADAPTER_CONCERN`):
  - ADF no Jira Cloud v3;
  - string no DC v2;
  - `markdown_content` no ClickUp;
  - `text` ou `html_text` no Asana;
  - markdown no Linear.
- **O lote é declarado por operação, não como capacidade uniforme** (`C_BULK_IS_PER_OPERATION_NOT_UNIFORM`):
  - Jira tem só bulk create, até 50 no Cloud;
  - Asana tem batch genérico de 10 ações;
  - Linear tem batch create e update.

## Correção do core feita nesta rodada

`Q_JIRA_SEARCH_REMOVAL_RECONCILE` tratou uma afirmação sem fonte. O core dizia, em 5 superfícies
(`CLAUDE.md`, `adapters/jira.md`, `jira-specialist`, skill `onion`), que o `/search` antigo do Jira "foi removido
em maio/2025". A referência v3 primária diz **"Endpoint is currently being removed"** (CHANGE-2046), sem data.
O changelog público lido em 2026-10-11 não trouxe a entrada. O core passou a afirmar só o que a primária sustenta:
o endpoint está em remoção e não tem data. O caminho recomendado continua o mesmo, `/search/jql`.

## Abertos (vão à Onda 2)

- **`Q_TASK_MANAGER_VOCABULARY_MATRIX`:** a matriz das 12 capacidades está só parcialmente ancorada.
- **`Q_WAVE2_PRIMARIES_CELLS`:** a segunda rodada de primárias precisa
  - reabrir o Zoho por outro transporte, o fallback SDAAL de busca;
  - mirar as células de hierarquia, anexo, label, sprint e versão.
- **`Q_JIRA_STATUS_BY_PUT_MEASURE`:** medir ao vivo se `PUT /issue` muda status, antes de declarar "transição obrigatória".

## NÃO-VERIFICADOS

- **Zoho Projects v3:** fonte inalcançável. A matriz desse provedor só tem o que o corpus já mediu, em
  `zoho-glpi-adapters-2026-09`, ligado por uma `external_edge` CONSTRAINS.
- **3 claims rejeitadas na ancoragem** por exagero. Não viraram nó e estão contabilizadas em `E_LACUNAS_*`.

## valeu-a-pena

Foram ~1,01 M tokens para 27 evidências ancoradas, cerca de 37 mil por evidência e ~19,5 mil por nó do grafo.
Fica abaixo do modo primaries medido em 2026-09-13 (~42 mil por nó). A rodada também pegou uma afirmação sem fonte
que estava em 5 superfícies do core.
