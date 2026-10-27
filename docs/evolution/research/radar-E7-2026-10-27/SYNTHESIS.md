---
title: Radar E7 r1 — o mercado de treino e inferência, primeira baseline
date: 2026-10-27
kg: docs/evolution/research/radar-E7-2026-10-27/radar-E7-2026-10-27.kg.yaml
run_id: wf_2be7b5c9-f34
tokens: 1558281
agents: 24
duration_min: 10
review_after: 2026-11-26
type: research
mode: primaries
---

> **Projeção do grafo, nunca fonte.** O grafo tem 65 nós: 55 escritos pelo run (1 pergunta raiz, 30 evidências
> ancoradas, 15 objeções sobreviventes, 1 contabilidade, 7 superações e 1 pergunta de fechamento), 2 do
> fechamento (o selo da baseline e a passada adversarial do PR) e 8 termos `x_term` que dão nome aos códigos de
> produto e unidade vindos das fontes (H100, B200, BF16, CO2, ML4, K2, K3, V3), exigidos pelo lint de nomes da
> kg-ssot. O retorno bruto do run está em
> `data/workflow-return.json`. Modo primárias: 10 fontes nomeadas, lidas inteiras, 0 inalcançáveis. A pauta veio
> da curadoria (`docs/evolution/inbox/_processed/2026-10-27-signal-e7-sources.md`) mais a página de
> descontinuações da OpenAI, relida.

## O que a rodada sustenta

É uma **baseline datada, não uma trajetória**: 1ª rodada do eixo, um ponto por série (`meta.x_supersedes_none`).

- **Os três degraus da OpenAI**, verbatim na página de descontinuações:
  - **2026-05-07**: quem nunca rodou fine-tuning não cria job (`E_OPENAI_FT_CLOSED_NEW_ORGS_20260507`);
  - **2026-07-02**: fecha para quem não rodou inferência em modelo ajustado nos últimos 60 dias
    (`E_OPENAI_FT_CLOSED_NO_RECENT_INFERENCE_20260702`). A janela de 60 dias estava fora do trecho que o
    verificador ancorou, e a passada do PR a achou verbatim (`E_E7_PR_PASS_60_DAYS_VERBATIM_1027`);
  - **2027-01-06**: clientes ativos também perdem a criação de job (`E_OPENAI_FT_CLOSED_ALL_NEW_JOBS_20270106`).
  - A inferência em modelos já ajustados continua até a descontinuação do modelo base.

  Os quatro nós sustentam, por aresta externa SUPPORTS, o nó do corpus `E_OPENAI_SELF_SERVE_FINETUNE_SUNSET_2026`
  (nanochat-onion-2026-10), que fica confirmado e datado sem ser editado.
- **Gemini 4 Argon dobra de preço em 2026-12-01** (página de preço atualizada em 2026-10-26): entrada de
  **US$2 para US$4** e saída de **US$10 para US$20** por 1M tokens, nível pago Standard
  (`E_GEMINI_4_ARGON_INPUT_PRICE_DOUBLES_20261201`, `E_GEMINI_4_ARGON_OUTPUT_PRICE_DOUBLES_20261201`). É um modelo e
  um nível só.
- **O RFT (ajuste por reforço) abriu no Amazon Bedrock em 2026-02-17** para pesos abertos, com
  `qwen.qwen3-32b` e `openai.gpt-oss-20b` no lançamento e inferência sob demanda por APIs compatíveis com as da
  OpenAI. A recompensa vem de grader de regra **ou** de juiz de IA (`E_BEDROCK_RFT_LAUNCH_QWEN3_GPTOSS_20260217`,
  `E_BEDROCK_RFT_RULE_GRADERS_OR_AI_JUDGES`). O catálogo é o do lançamento.
- **Faixas de preço de ajuste da Fireworks**, por tamanho e método: LoRA (ajuste de adaptadores) com SFT (ajuste supervisionado) a US$0,50 (até 16B), US$3 (16,1B a 80B),
  US$6 (80B a 300B) e US$10 (acima de 300B) por 1M tokens de treino. O ajuste completo custa o dobro do LoRA, e o
  DPO (ajuste por preferência) o dobro do SFT (`E_FIREWORKS_LORA_SFT_SIZE_TIERS`, `E_FIREWORKS_FULL_PARAM_DOUBLE_LORA`).
- **Faixas da Together** (foto de 2026-10-27, página sem data):
  - inferência de pesos abertos a centavos: gpt-oss-120B a US$0,15 de entrada e US$0,60 de saída, Qwen3.5 9B a
    US$0,17 e US$0,25 (`E_TOGETHER_INFERENCE_SMALL_OPEN_WEIGHTS_CENTS`); na faixa alta (GLM-5.3, Kimi K3), de US$1,40
    a US$3 na entrada e de US$4,40 a US$15 na saída (`E_TOGETHER_INFERENCE_HIGH_TIER_OPEN_WEIGHTS`);
  - ajuste SFT de 8B/9B a US$0,34 por 1M tokens (mínimo de US$4, DPO a US$0,84), crescendo com o tamanho até US$40
    (GLM-5.2) (`E_TOGETHER_SFT_SMALL_034_USD`, `E_TOGETHER_SFT_COST_SCALES_WITH_SIZE`).
- **NVIDIA Nemotron 3.5 Bolt**: pesos abertos de 74B com 9B ativos, híbrido Mamba-2/Transformer com MoE (mistura de especialistas) latente,
  no Hugging Face em 2026-10-15, contexto de 256K, licença OpenMDW 1.1 (`E_NEMOTRON_BOLT_*`). Os benchmarks são
  declaração da NVIDIA, não medida independente.
- **Destilação a 622 horas de H100** (arXiv 2602.20164, autores da Lenovo, pré-publicação): um 8B destilado de um
  professor de 685B (`E_DISTILL_8B_622_H100_HOURS`). **O 2.000x é explicitamente marginal**: a conta soma só a
  inferência do professor e o treino do aluno, sem o treino do professor e sem o pré-treino do aluno
  (`E_DISTILL_COST_IS_MARGINAL`). A base de comparação é estimativa pela regra 6ND (seis vezes parâmetros vezes tokens) com 38% de MFU (uso efetivo da GPU), não medida
  (`E_DISTILL_BASELINE_IS_6ND_ESTIMATE`).
- **Fechamentos noutras superfícies**: a Gemini API e o AI Studio estão sem modelo ajustável desde 2025-05, sem
  plano imediato de reabrir. A página de ajuste fino da Mistral está marcada deprecated. O Mistral Large 4 foi
  anunciado em 2026-10-06 com pesos prometidos para o fim do mês.

## O que ela NÃO sustenta

Da recomendação do Elenxo (o método de refutar antes de selar) da rodada (`.result.elenxo.recommendation`):

- **"O Google fechou o ajuste fino."** O fechamento é de **2025-05**, não de 2026, e vale **só para a superfície
  da Gemini API e do AI Studio**. A própria página diz que o ajuste segue suportado na Gemini Enterprise Agent
  Platform (`E_OBJECAO_E7_05`).
- **Uma data para a descontinuação da Mistral**, e o preço de US$4 por job e US$2/mês como custo vigente: a página
  não é datada e o preço é de uma doc deprecated.
- **"Os pesos do Mistral Large 4 ainda não foram entregues"** hoje, e o rótulo de pesos abertos sem licença
  nomeada: nada foi lido depois de 2026-10-06.
- **Comparar o ajuste da Together com o da Fireworks**: a Together não diz qual tabela é LoRA e qual é ajuste
  completo, e cobra dataset vezes épocas mais tokens de avaliação.
- **A permissão comercial do Nemotron**: a licença está nomeada, a permissão está sem trecho citado.
- **Qualquer "encaixe" do RFT com o Onion**: o Onion não treina, e `C_BASE_MODELS_MENU_2026_10` (onion-slm-2026-10)
  segue aberto com confiança 0,5, condicionado a um eval falhar.
- **A tendência "a inferência encarece"**: o Gemini é um ponto contra os pesos abertos baratos da Together.
- **"Trajetória"** de qualquer série: é o primeiro ponto. A trajetória começa na 2ª rodada.

## O que isto muda para o Onion

Hoje, nada na maquinaria: o Onion não treina, e a escada de modelos da sessão é do E6, que esta rodada não toca. O
que muda é a pauta:

- **Ajuste fino self-serve não é base para nada do Onion.** Se a opção de usar o corpus para ajustar um modelo de
  terceiro um dia abrir, ela não pode depender da API de ajuste de um fornecedor que fecha. Três fecharam, cada um
  do seu jeito, e o caminho que sobra é a plataforma gerenciada de pesos abertos (Bedrock, Together, Fireworks).
- **O custo de ajustar um modelo pequeno é baixo e público** (centavos a poucos dólares por 1M tokens). Se o eval de
  `C_BASE_MODELS_MENU_2026_10` falhar, o custo não é a barreira.
- **Gatilhos de revisita antes do mês**: o fim de 2026-10 (pesos do Mistral Large 4), 2026-12-01 (o preço dobrado do
  Gemini 4 Argon) e 2027-01-06 (o fim de todo job novo na OpenAI).
- **A linha "o que muda para o Onion" por fonte é leitura do escritor, não medida**: 29 das 30 evidências não a
  traziam do run. A pergunta `Q_E7_BASELINE_CLOSE_BEFORE_SEAL_1027` (três primárias a mais e a linha por fonte) fica
  aberta para a 2ª rodada.

## NÃO-VERIFICADOS

**Rejeitadas na ancoragem (8, nenhuma virou nó de evidência):**

1. [openai-deprecations, EXAGERADA] "a série GPT-4 inteira desliga em 2027-01-14, substituto gpt-6-luna": a entrada
   de 2026-10-14 cobre só quatro famílias (GPT-4o, GPT-4o mini, GPT-4.1, GPT-4.1 mini). É fronteira do E6 e não
   migra para cá (`C_SUPERACAO_20261027_GPT4_FOUR_FAMILIES_ONLY`).
2. [gemini-tuning, EXAGERADA] "a Gemini Enterprise Agent Platform é o substituto indicado": a página só diz que o
   ajuste é suportado lá. Busca por recommend, migrat, switch e instead: 0. Sem superação.
3. [bedrock-rft, EXAGERADA] "abre justo quando a OpenAI fecha o self-serve": a página não cita a OpenAI
   (`C_SUPERACAO_20261027_BEDROCK_RFT_NO_OPENAI_LINK`).
4. [bedrock-rft, EXAGERADA] "treino barato, recompensador verificável": "cost-effective" qualifica o modelo de
   destino, e o grader pode ser juiz de IA (`C_SUPERACAO_20261027_BEDROCK_RFT_NO_TRAINING_COST_CLAIM`).
5. [together-pricing, EXAGERADA] "cobrança por tokens do dataset": a frase completa multiplica por épocas e soma
   os tokens de avaliação (`C_SUPERACAO_20261027_TOGETHER_BILLING_EPOCHS_EVAL_TOKENS`).
6. [fireworks-pricing, EXAGERADA] a substância se sustenta, mas a citação omitia "across Standard, Priority, and
   Fast serving paths" (`C_SUPERACAO_20261027_FIREWORKS_SERVERLESS_VERBATIM_QUOTE`).
7. [mistral-large-4, EXAGERADA] "1T de pesos exige infraestrutura pesada de inferência": inferência do leitor
   (`C_SUPERACAO_20261027_ML4_SCALE_WITHOUT_INFRA_INFERENCE`).
8. [mistral-large-4, NÃO-ENCONTRADA] o preço de US$1,36/US$4,18 existe no cartão, mas a frase citada foi
   reformulada (`C_SUPERACAO_20261027_ML4_PRICE_CARD_VERBATIM`).

**Lacunas abertas** (`E_LACUNAS_RADAR_E7_2026_10_27`): os pesos e a licença do Mistral Large 4 em 2026-10-27; a data
da descontinuação da Mistral; preço e modelos da Gemini Enterprise Agent Platform; o método por tabela da Together;
a permissão comercial do Nemotron; o catálogo atual do RFT no Bedrock.

**Fora do orçamento:** nenhuma fonte inalcançável. As fontes que a curadoria recusou (o preço da OpenAI com 403, a
lista de modelos ajustáveis da Vertex e do Bedrock, os comparativos de terceiros, o blog da Multiverse) não foram
lidas e não entraram no roster.

## Valeu a pena

1.558.281 tokens, 24 agentes, cerca de 10 minutos. São **28.332 tokens por nó** sobre os 55 nós do run e 51.943 por
evidência ancorada (30). É a faixa que o modo primárias prometia (42 mil por nó medidos em 2026-09-13, contra 291 mil
da varredura), e abaixo dela. O ganho é a baseline do eixo, que até ontem nunca tinha rodado, com 4 nós sustentando
um fato do corpus e 9 fontes novas no roster. O custo que fica é a 2ª rodada: a trajetória só existe a partir dela.
