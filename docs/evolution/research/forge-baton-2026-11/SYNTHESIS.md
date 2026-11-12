---
title: Forja do /meta:baton, o pulso da batuta (fase 1)
date: 2026-11-12
kg: docs/evolution/research/forge-baton-2026-11/forge-baton-2026-11.kg.yaml
run_id: "nenhum (sem Workflow: forja conduzida por um agente de execução da sessão do core, sem subagente nem juiz)"
tokens: 0
agents: 1
duration_min: 75
x_cost_note: "tokens 0 = não medido: o agente de execução não vê o próprio consumo. duration_min é a duração aproximada da forja pelo relógio da sessão. agents 1 = o agente de execução; nenhum subagente."
review_after: 2026-12-12
type: forge
mode: forge
---

# Forja do /meta:baton (fase 1)

> Projeção do grafo `forge-baton-2026-11.kg.yaml`. A fonte é o grafo; este texto deriva dele.

**A pergunta** (`Q_BATON_IDLE_SESSIONS_1112`): as sessões ficam ociosas esperando algo enquanto há trabalho pronto em
outra fila. Como medir quem está parado com trabalho pronto, perguntar o estado a cada sessão e oferecer a fila sem
empurrar nem acordar quem foi parado por ordem?

**O pedido** (`E_PEDIDO_DO_MAESTRO_BATON_LOOP_1112`), do maestro em 2026-11-12: «Forjar o comando da batuta com o
/loop. As sessões ficam ociosas esperando algo mas poderiam tocar outras tarefas que são necessárias, e a batuta
serviria para isso.»

## Por que (a evidência)

- **Espera que ninguém via** (`E_WAIT_LOOPS_MATCHED_SIBLINGS_1111`): em 2026-11-11, quatro laços de espera da sessão do
  core se esperaram uns aos outros por quase uma hora, porque o padrão do `pgrep` casava os próprios irmãos. Relato da
  sessão do core; a mesma classe está medida desde 2026-11-05 no cabeçalho do lease de carga.
- **Estado só ao perguntar** (`E_SESSION_STATE_ONLY_BY_ASKING_1111`): a cada «como estão as sessões», o estado só era
  descoberto perguntando a cada uma. A regra de perguntar existia; faltava a medição que diz a quem perguntar e o que
  cruzar com a resposta.

## O que a fase 1 entregou (`C_BATON_PHASE1_PULSE_BUILT_1112`)

| Peça | Artefato | Estado |
|---|---|---|
| 1 superfície | `.claude/commands/meta/baton.md` | presente |
| 2 doutrina | cláusula 7 de `.claude/commands/common/prompts/baton-doctrine.md` | presente |
| 3 contexto medido | `.claude/validation/baton-pulse.sh`, injetado na carga | presente |
| 4 orquestração | nenhuma: a pergunta é uma `SendMessage` por sessão | ausente por desenho |
| 5 destino | TSV de pulsos com `--record` | especificado para a fase 2 |
| 6 lente | nenhuma path-scoped cobre; nenhuma nova sem uso medido | ausente, declarado |
| 7 bancada | `run_baton_pulse_selftests`, 6 casos com mutante | presente |

O `forge-census` conta o baton com 4/7, que são as peças que ele cita. É o nível 0 da escada selada
(`D_AUTOMATION_LEVELS_0_TO_2_SCHEDULED_1111`): só mede e lê.

## O primeiro pulso real (`E_DOGFOOD_BATON_PULSE_CLASSES_1112`)

O 1º pulso no core, em 2026-11-12T02:41Z, mediu **15 sessões**:

| ACTIVE | IDLE_WITH_QUEUE | IDLE_NO_QUEUE | PARKED | UNREACHABLE |
|---:|---:|---:|---:|---:|
| 6 | 0 | 1 | 0 | 8 |

Três `owner:` têm fila e nenhuma sessão casada: `brain`, `curadoria` e `onion-messaging`. O dogfood achou três
defeitos, curados no mesmo laço:

1. Os faróis velhos da família inflavam o UNREACHABLE para 22. Eles saíram da contagem como rastro.
2. Faróis vivos fora da lista de peers do harness saíam como IDLE_WITH_QUEUE falso. Com a lista lida, eles agora são
   UNREACHABLE.
3. A sessão `onion-curation` atende o `owner: curadoria`, e nenhum rótulo derivado casa os dois. A fila aparece sem
   sessão até o maestro declarar a linha no `owners.tsv`.

A batida seguinte, com o sha devolvido, saiu em uma linha.

## A bancada (`E_BENCH_BATON_PULSE_SIX_CASES_1112`)

Seis casos, cada um reprovado pelo seu mutante:

- a sessão ociosa com fila sai IDLE_WITH_QUEUE;
- a parada por ordem nunca vira ociosa;
- a batida sem mudança sai em uma linha;
- a fila vem só de dono declarado;
- o PR com CI vermelho aparece;
- o medidor sem fonte declara a lacuna em vez de dizer zero.

## O que fica aberto

- **Fase 2** (`Q_BATON_PHASE2_MATCH_AND_MEASURE_1112`, owner core): casar a sessão ociosa com a fila dela, como
  oferta e nunca como ordem, e medir por um dia as horas ociosas com fila, antes e depois da oferta. O gatilho é o
  maestro aprovar a gravação do TSV de pulsos.
- **Fase 3** (`Q_BATON_PHASE3_TRAVEL_TO_DOORS_1112`, owner core): decidir se o comando viaja às portas, com os
  números da fase 2. Hoje ele está no conjunto `pending` (fonte e hub).
- **Limite de nome:** a doutrina se chama `baton-doctrine.md`, fora da regra de identificador em inglês. O rename
  é um PR à parte, com os links atualizados.
