---
title: "Fontes primárias para o eixo de treino e inferência do radar (1º insumo da frente de IA)"
date: "2026-10-27"
from: onion-curation
to: onion-evolve
type: radar-sources
selo: D_AI_FRONT_RADAR_COUPLING_1027
kg: docs/evolution/dissect/ai-front-2026-10/ai-front-2026-10.kg.yaml
---

# Fontes primárias para o eixo de treino e inferência (E7) do radar

Este é o primeiro insumo da frente de IA da curadoria. Ele cumpre o selo do maestro de 2026-10-27
(`D_AI_FRONT_RADAR_COUPLING_1027`): a frente vira insumo do eixo de treino e inferência do radar do core. A forma foi
a combinada com o core: até 10 fontes primárias e datadas, cada uma com a lacuna que fecha, a citação literal e o
locator. O juiz é o do core, que ancora e decide o que entra no grupo `treino-inferencia` de
`docs/onion/radar-sources.yaml`.

## Filtro aplicado

O filtro vem do padrão dos três pilotos da frente (`E_PILOTS_PATTERN`). Cada fonte passou nas quatro condições:
1. mede a mesma coisa que a lacuna pede;
2. a url e o nome do item não aparecem no corpus do core (busca por texto em `.kg.yaml`, `.md` e `.yaml`, feita em
   2026-10-27);
3. a página original foi aberta e lida, não uma reprodução;
4. a data foi conferida na própria página. Quando a página não traz data, isso vem declarado.

As citações foram lidas em 2026-10-27, por leitura da página. Nada aqui foi medido de outro jeito: o que a fonte diz é
informado por ela.

## Fontes aceitas (9)

### 1. A API do Gemini fechou o ajuste fino
- url: https://ai.google.dev/gemini-api/docs/model-tuning
- kind: primary · tier proposto: 10
- data do item: página atualizada em 2026-04-28; a retirada do último modelo ajustável foi em maio de 2025
- lacuna: APIs de ajuste fino que fecham
- citação: "With the deprecation of Gemini 1.5 Flash-001 in May 2025, we no longer have a model available" … "We don't
  have immediate plans to bring fine-tuning support"; o ajuste segue "supported in Gemini Enterprise Agent Platform"
- locator: aviso no topo da página de ajuste de modelo

### 2. A Mistral descontinuou o ajuste fino pela API
- url: https://docs.mistral.ai/capabilities/finetuning/
- kind: primary · tier proposto: 9 (a página não traz a data da descontinuação)
- data do item: sem data na página; lida em 2026-10-27
- lacuna: APIs de ajuste fino que fecham
- citação: "This feature is deprecated and is no longer actively supported." · "Every fine-tuning job comes with a minimum
  fee of $4, and there's a monthly storage fee of $2 for each model."
- locator: seção "Deprecated features"; no menu lateral, "Fine-tuning API (legacy)"

### 3. O Amazon Bedrock abriu ajuste por reforço para modelos de pesos abertos, com API compatível com a da OpenAI
- url: https://aws.amazon.com/about-aws/whats-new/2026/02/amazon-bedrock-reinforcement-fine-tuning-openai/
- kind: primary · tier proposto: 10
- data do item: 2026-02-17
- lacuna: APIs de ajuste fino que abrem
- citação: "Models supported at this launch are: qwen.qwen3-32b and openai.gpt-oss-20b." · "use the resulting fine tuned
  model for on-demand inference through Amazon Bedrock's OpenAI-compatible APIs"
- locator: corpo do anúncio no feed What's New da AWS

### 4. Preço de inferência da API do Gemini, com o preço do modelo principal dobrando em 2026-12-01
- url: https://ai.google.dev/gemini-api/docs/pricing
- kind: primary · tier proposto: 10
- data do item: página atualizada em 2026-10-26
- lacuna: custo de inferência
- citação: Gemini 4 Argon, entrada "$2.00 through November 30, 2026." e "$4.00 starting December 1, 2026."; saída
  "$10.00 through November 30, 2026." e "$20.00 starting December 1, 2026."; Gemini 2.5 Flash-Lite, entrada "$0.10"
  e saída "$0.40" por milhão de tokens
- locator: tabelas do nível pago (Standard)

### 5. Preço de ajuste fino e de inferência de modelos abertos na Together AI
- url: https://www.together.ai/pricing
- kind: primary · tier proposto: 8 (página sem data)
- data do item: sem data na página; lida em 2026-10-27
- lacuna: custo de ajuste fino e custo de inferência de modelos de pesos abertos
- citação: ajuste fino por milhão de tokens: "Qwen3.5 9B | $0.34 | $0.84 | $4.00", "Llama 3.3 70B | $2.03 | $5.08 |
  $4.00"; inferência: "gpt-oss-120B | $0.15 | $0.60", "Qwen3.5 9B | $0.17 | $0.25"
- locator: tabelas "Fine-tuning" e "Serverless inference"
- ressalva: a página não diz qual tabela de ajuste vale para LoRA e qual vale para o ajuste completo

### 6. Preço de ajuste LoRA por faixa de tamanho na Fireworks AI
- url: https://fireworks.ai/pricing
- kind: primary · tier proposto: 8 (página sem data)
- data do item: sem data na página; lida em 2026-10-27
- lacuna: custo de ajuste fino por tamanho de modelo
- citação: "Models up to 16B parameters": $0.50; "Models 16.1B - 80B": $3.00; "Models 80B - 300B (e.g. Qwen3-235B,
  gpt-oss-120B)": $6.00; "Models >300B (e.g. DeepSeek V3, Kimi K2)": $10.00, por milhão de tokens de treino
- locator: seção de ajuste fino supervisionado com LoRA

### 7. Pesos abertos: NVIDIA Nemotron 3.5 Bolt, de 74B com 9B ativos
- url: https://huggingface.co/nvidia/NVIDIA-Nemotron-3.5-Bolt-74B-A9B-BF16
- kind: primary · tier proposto: 9
- data do item: "Hugging Face 10/15/2026" (o repositório foi criado em 2026-10-09, pela API do Hugging Face)
- lacuna: plataformas e lançamentos de pesos abertos
- citação: "74B (9B active)" · licença "OpenMDW-1.1" · "Up to 256K tokens"
- locator: cartão do modelo, seções de visão geral, licença e contexto

### 8. Pesos abertos anunciados: Mistral Large 4
- url: https://mistral.ai/news/mistral-large-4/
- kind: primary · tier proposto: 9
- data do item: 2026-10-06
- lacuna: plataformas de pesos abertos (lançamento anunciado e ainda não entregue)
- citação: "ML4 is a 1 trillion-parameter natively multimodal model with 52 billion active parameters." · "We will
  release the weights by the end of the month."
- locator: post de lançamento
- ressalva: até 2026-10-27, a entrega dos pesos não foi conferida aqui. A página não nomeia a licença. A
  documentação técnica para provedores fala em licença confidencial sob medida até a liberação.

### 9. Destilação com número: um modelo de 8B destilado custa mais de 2.000 vezes menos computação
- url: https://arxiv.org/abs/2602.20164
- kind: primary · tier proposto: 7 (pré-publicação de autores da indústria, sem revisão por pares)
- data do item: submetido em 2026-01-28
- lacuna: treino barato e destilação com número
- citação: "We find that creating a distilled 8B model is over 2,000 times more compute-efficient than training its
  vanilla counterpart"
- locator: resumo
- ressalva: só o resumo foi lido. As horas de GPU e o custo em dólar do texto completo não foram conferidos.

## Recusadas (6)

| fonte | motivo |
|---|---|
| developers.openai.com/api/docs/deprecations (o fim do ajuste fino self-serve da OpenAI) | já está no grupo `treino-inferencia` do core, conferida em 2026-10-26: não é fonte nova |
| openai.com/api/pricing | a página devolveu 403 ao leitor; o original não foi lido |
| docs.cloud.google.com/vertex-ai/generative-ai/docs/models/tune-models | a leitura truncou na navegação; a lista de modelos ajustáveis não foi lida |
| docs.aws.amazon.com/bedrock/latest/userguide/custom-model-supported.html | o leitor recebeu a página sem corpo; a lista de modelos não foi lida |
| comparativos de modelos abertos de outubro (pasqualepillitteri.it e outros) | reprodução de terceiro, com datas que se contradizem |
| blog da Multiverse Computing sobre destilação barata | post de fornecedor, sem o número conferido na fonte; não aberto |

## Para a rodada do eixo

Pela leitura daqui, três fatos merecem a pauta da 1ª rodada, junto com o fim do ajuste fino self-serve da OpenAI.
Primeiro, a OpenAI, o Google (na API do Gemini) e a Mistral fecharam o ajuste fino self-serve, cada uma do seu jeito.
Segundo, a AWS abriu ajuste por reforço para modelos de pesos abertos. Terceiro, o preço do modelo principal do Gemini
dobra em 2026-12-01. A decisão é do juiz do core.
