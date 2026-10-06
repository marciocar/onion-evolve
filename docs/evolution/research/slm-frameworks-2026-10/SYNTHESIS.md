---
kg: docs/evolution/research/slm-frameworks-2026-10/slm-frameworks-2026-10.kg.yaml
run_id: wf_e53f21ed-be6
mode: primaries
tokens: 1411884
agents: 20
duration_min: 13
date: 2026-10-05
---

# Onion SLM — o roteiro gradual, segundo as primárias

> **Projeção do grafo** `slm-frameworks-2026-10` (59 nós, 87 arestas, radar `--integrity --schema` exit 0).
> Foram lidas 9 fontes, todas alcançadas, com **37 claims ancoradas** e **17 rejeitadas na ancoragem**, todas por
> exagero. Pedido do maestro: roteiro gradual (spike → PoC → MVP → …), pesquisa progressiva e decisões
> conduzidas por formulário.

## O achado transversal

**Nenhuma das 9 fontes dá critério numérico de passagem entre etapas** (`C_NO_NUMERIC_PASS_CRITERIA_IN_SOURCES`).
O que elas dão é a **ORDEM**, e as nove convergem nela:

1. decidir *se* treina;
2. instrumentar e medir;
3. medir o pronto;
4. ajustar só se o pronto falhar;
5. instrumentar o uso.

Smol Playbook, HF Course, Hamel, Google, Anthropic e NVIDIA dizem isso com palavras diferentes.

Duas consequências:

- O vocabulário **spike/PoC/MVP/produto é cunhagem do Onion**, porque nenhuma fonte o usa
  (`C_ROADMAP_VOCAB_IS_ONION_COINAGE`).
- **Todo limiar é decisão do maestro.** Cada um vira pergunta de formulário, nunca número atribuído a uma
  fonte.

## O roteiro (proposta, não sela — `Q_SLM_GRADUAL_ROADMAP_PROPOSAL`)

| etapa | entra | sai | passa quando | nó |
|---|---|---|---|---|
| **Porta 0** | "precisa de ML?" + erros REAIS selados do corpus | eval selado + corretor determinístico + critérios escritos | o eval roda no harness e foi inspecionado à mão (≥ 50 amostras, Guidebook) | `C_STAGE0_GATE_BEFORE_ANY_MODEL` |
| **Spike** (dias) | eval selado + os 4 especialistas prontos + o baseline atual | tabela recall/precision e PR-AUC por tipo, **custo medido na VPS**, lista de erros | o maestro decide sobre a tabela | `C_SPIKE_MEASURE_READY_SPECIALISTS` |
| **PoC** | o especialista que passou | pipeline ponta a ponta via adapter SDAAL num fluxo real (ex.: de-id), instrumentado | "working end to end system with unit and system tests" (Google, o único gate explícito, e qualitativo) | `C_POC_E2E_WITH_SIMPLE_MODEL` |
| **MVP / ajuste** | **só se o eval FALHAR** | especialista ajustado (LoRA rank 4–8) medido no MESMO eval | supera o pronto no critério do maestro | `C_MVP_FINETUNE_ONLY_IF_EVAL_FAILS` |
| **Produto** | o que passou | uso instrumentado; erros novos voltam ao eval | o laço reabre o spike quando surge modo de falha novo | `C_PRODUCT_INSTRUMENT_AND_LOOP` |

**Resultado final possível:** uma ferramenta de conjunto fechado, plugada por SDAAL e julgada pelo gate
determinístico. O modelo é substituível. **O que fica é o mecanismo**: eval selado, corretor e radar.

## Pré-condições obrigatórias que a rodada levantou

- **O eval selado fica PRIVADO e fora da porta `onion-core`** (`C_EVAL_SET_PRIVATE_EXCLUDED_FROM_DOOR`). Dataset
  público se presume contaminado (Guidebook). Se entrar em `origin/main`, o `materialize-door.sh` o
  publica pela REGRA 85 (Porta pública espelha o core, com catraca). Isso **veta** também subir o eval ao Hub
  para o lighteval.
- **LLM-as-judge fica fora do gate** (`C_LLM_JUDGE_VETOED_SINGLE_ANNOTATOR`). Calibrar o juiz exige concordância
  humano-humano, e o Onion tem um rotulador só.
- **lighteval é candidato, não escolha** (`C_LIGHTEVAL_IS_CANDIDATE_NOT_CHOICE`). O spike mede o custo dele contra
  um harness próprio em shell/Python, que é a metade agnóstica que já é o fosso do Onion.
- **Custo não é a régua** (`C_COST_ARGUMENTS_NOT_THE_RULER`). Os 161k GPU-h do Smol são de pré-treino, e aplicá-los
  a LoRA é erro de categoria. O argumento válido para "não treinar agora" é de **ordem**, não de custo.
- **"Não treinar agora" vale enquanto o eval não existe** (`C_NO_TRAIN_HOLDS_ONLY_WHILE_NO_EVAL`). Com eval, o
  ajuste fica barato (Hamel). O gatilho de reabertura é o eval rodar, e a forma selada continua a mesma.

## NÃO-VERIFICADOS

- **17 claims rejeitadas na ancoragem**, todas por exagero. A lista com o motivo de cada uma está em
  `E_LACUNAS_SLM_FRAMEWORKS_PRIMARIES_1005` e em `data/`.
- **4 passagens a re-ancorar** antes de selar o roteiro. Uma é "eval por tarefa antes de treinar" (Smol), que outra
  passagem sustenta mas ninguém ancorou.
- **Nada foi medido.** Nenhum especialista rodou, e o custo do lighteval e do harness próprio é hipótese.

## valeu-a-pena

1.411.884 tokens ÷ 59 nós ≈ **24k/nó**, abaixo dos 30k/nó da rodada `onion-slm-2026-10` e dos 42k/nó da
referência de primárias. O caro e decisivo foi a ancoragem: 17 exageros não viraram nó, e entre eles
estavam limiares que as fontes não dão.
