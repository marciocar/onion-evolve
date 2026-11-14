---
title: A maquinaria de espiar o mercado na dúvida, com o esforço que ela merece
date: 2026-11-13
kg: docs/evolution/research/market-peek-machinery-2026-11/market-peek-machinery-2026-11.kg.yaml
run_id: wf_3157a547-84f
tokens: 1445869
agents: 19
duration_min: 14
review_after: 2026-12-13
type: research
mode: primaries
---

# A maquinaria de espiar o mercado na dúvida

**A pergunta**, feita pelo maestro em 2026-11-13: nas dúvidas, a sessão tem de espiar o mercado, e principalmente
fóruns e comunidades, para saber o que estão falando do problema, da estratégia, da ferramenta ou da ideia. O esforço
gasto nessa descoberta tem de seguir um padrão escolhido e aprendido, e isso precisa de maquinaria.

**Resposta curta:**
- **Escada de esforço é padrão de mercado.** A Anthropic embute regras de escala no prompt porque o agente julga mal o
  esforço, e o degrau-base é 1 agente com 3-10 chamadas. Isso vira o teto do nível 1.
- **A ponte reversibilidade → degrau é nossa.** A taxonomia de porta de mão única x dupla vem da carta aos acionistas
  da Amazon de 2015. A Anthropic escala por complexidade, não por reversibilidade. A ligação entre as duas é cunhagem
  Onion, declarada como tal.
- **VOI/EVPI (valor da informação; o EVPI é o da informação perfeita) só serve de teto.** Sem payoffs numéricos não vira regra de parada: as duas claims que tentavam isso foram
  rejeitadas como exageradas, e a objeção à claim 4 bloqueia.
- **Escutar HN, GitHub e Lobsters por delta é viável e barato**, com duas armadilhas medidas: o `>` cru no
  `numericFilters` do HN Algolia devolve 400, e quem não confere o `http_code` registra «nada novo» em silêncio.
- **Reddit fica fora.** Devolveu 403 desta VPS de novo e vira lacuna declarada, nunca promessa.
- **O registro por espiada e a recalibração pelo histórico não têm evidência de mercado.** São desenho próprio, a
  medir por dogfood.

## O que a rodada sustenta e o que não sustenta

| Item | Status | Onde |
|---|---|---|
| Escada de esforço embutida no prompt (claim 19) | mercado, ancorado | Anthropic, *multi-agent research system* |
| Degrau-base de 1 agente com 3-10 chamadas (claim 20) | mercado, a objeção não sobreviveu | idem |
| Porta de mão única x dupla e o alerta contra processo pesado em decisão reversível (claims 1-3) | mercado, ancorado; **sem classificador operacional** (objeção 1, limite) | carta da Amazon, 2015 |
| EVPI como teto do que vale pagar por informação (claim 4) | **só teto**; a objeção bloqueia o uso como regra | teoria da decisão |
| HN Algolia `search_by_date` com delta por `created_at_i` (claim 7) | mercado, **com a armadilha do 400** (objeção bloqueia a forma literal) | doc da API do HN |
| GitHub REST `search/issues`: teto de 1.000 e `incomplete_results` (claims 10-12) | mercado, ancorado | doc do GitHub |
| Discussions do GitHub só pelo GraphQL, com token (claim 13) | ancorado; fora do nível 1 | doc do GitHub |
| OpenMagpie e TrendRadar como molde de arquitetura (claims 23-25) | molde; adotar o OpenMagpie fica bloqueado pela dependência externa | repositórios |
| Ponte reversibilidade → degrau | **cunhagem Onion** | `C_EFFORT_LADDER_BY_REVERSIBILITY_1113` |
| Registro por espiada e recalibração pelo histórico | **cunhagem Onion**, sem fonte | `C_PEEK_LEDGER_RECALIBRATION_1113` |

## O que a forja fez com isso

O `/meta:peek` materializa a recomendação do Elenxo (o método de refutar antes de selar), sem passar dela:

1. **Escada fixa** em `.claude/utils/peek/peek-ladder.tsv`: 12 células (reversibilidade x banda de severidade x
   incerteza) dão o nível 0-3. Porta de mão dupla nunca passa do nível 1, e o medidor recusa a tabela que viole isso.
2. **Executor do nível 1**, `.claude/utils/peek/community-peek.sh`: HN (stories e comentários), GitHub e Lobsters,
   com o `>` codificado, o `http_code` conferido por fonte, o teto e o `incomplete_results` do GitHub na linha, e o
   Reddit e os fóruns de fornecedor como linha `GAP`.
3. **Registro e medidor**: cada espiada é um nó com `x_peek_*`, e o `.claude/validation/peek-census.sh` propõe descer
   ou subir a célula quando ela junta 5 espiadas decididas. Quem muda a tabela é o maestro.
4. **Dependência declarada** (`D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027`): HN, GitHub e Lobsters são serviços de
   terceiro, e a dependência é intrínseca, porque a fonte é a comunidade. Sem rede, o nível 1 sai NÃO MEDIDO e o
   nível 0 (corpus local) segue de pé.

## Lacunas declaradas

- **Reddit**: 403 em `www` e `old.reddit.com` em 2026-11-13, como em 2026-08-28 (`Q_PEEK_REDDIT_GAP_1113`).
- **Fóruns de fornecedor** (Discourse e afins) e **Lobsters por busca**: sem claim na rodada. O Lobsters entra só
  pelo `/newest.json`, com recall baixo dito na linha.
- **Classificador de reversibilidade**: nenhum achado. A classificação é juízo da sessão, gravado no nó para auditoria.
- **Portal no `/meta:decide`**: fica para o 2º PR (`Q_PEEK_DECIDE_PORTAL_1113`).

## Contrato de custo

Rodada `wf_3157a547-84f`, modo primárias: 19 agentes, 1.445.869 tokens, cerca de 14 minutos. Foram 8 fontes, 7
alcançadas, 25 claims ancoradas e 5 rejeitadas. O grafo tem 56 nós e 95 arestas, e o radar
(`--integrity --schema`) saiu com exit 0.
