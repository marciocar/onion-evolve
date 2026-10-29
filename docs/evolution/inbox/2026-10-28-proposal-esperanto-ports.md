---
title: 'Dissecação do Esperanto (lfnovo/esperanto): rejeitar como dependência do núcleo e como cliente de vários provedores, sem costura'
date: 2026-10-28
from: onion-curation (adotante)
to: core (onion-evolve)
type: proposal
estudo: docs/evolution/dissect/esperanto-2026-10/
grafo: esperanto-2026-10.kg.yaml (D_PIECE_CORE_DEPENDENCY, D_PIECE_MULTI_PROVIDER_CLIENT)
---

# Esperanto: o que ele é hoje e o que dá ao Onion

**Pedido:** o maestro selou que o Onion e o Cortex nasceram juntos a partir do Esperanto de Luis Novo
(`Q_N0_SHARED_ORIGIN`) e pediu para dissecá-lo "para ver como está".

**Como foi feito:** a Etapa 0 foi commitada antes do N0, com a família `ferramenta`, o destino core e a régua
`onion-evolve`. A revisão adversarial **reprovou a 1ª versão**, e esta incorpora as 9 objeções que se sustentaram
(`evidence/elenxo/REVIEW.md`).

## O que ele é (medido)

- **Identidade:**
  - biblioteca Python MIT de Luis Novo, criada em 2024-11 e ativa: a 2.28.0 saiu em 2026-10-03, e sai cerca de uma
    minor por mês;
  - 223 estrelas e 71 mil downloads por mês;
  - um mantenedor quase único, com 362 dos 404 commits;
  - nenhum capital achado.
- **O que faz:** uma fábrica única cria cinco capacidades atrás de uma interface comum: LLM, embedding, reranking,
  transcrição e voz. São 12, 12, 4, 9 e 11 classes de provedor, mais profiles compatíveis com a OpenAI.
- **Como faz:**
  - o provedor sai de um registro estático com import tardio e é escolhido por argumento;
  - a interface comum fica no menor denominador comum, e cada provedor traduz para respostas no formato da OpenAI;
  - usa só httpx e pydantic, sem SDK de modelo.
- **Testes:** a suíte offline rodou isolada e sem chave. Passaram 1954. As falhas são de extra opcional ausente ou de
  pesos do Hugging Face com o Hub offline. A suíte é sobretudo de mock (61 de 83 arquivos): prova a normalização, não o
  contrato com o provedor real.

## A origem, medida no core

- **O 1º commit do core** (9d43d6db8, 2025-09-21) trazia `.cursor/esperanto-prompter/esperanto.md` ("Esperanto é uma
  biblioteca para interagir com múltiplos provedores…"). No mesmo dia, o f48f1cd51 o removeu, porque o Onion não é
  aplicação Python com o Esperanto (um grep pelo Esperanto e pelo AIFactory deu 0). **Este estudo é, portanto, o 2º
  fechamento do assunto.**
- **O README** cita o Esperanto como referência conceitual desde 2026-03-30.
- **O padrão de adaptadores do Onion** (SDAAL, com 5 instâncias: task-manager, de-identification, federation-transport,
  forge e trust) declara como fonte o GoF Adapter e Factory. A forma difere: o Esperanto escolhe o provedor por
  argumento, e o Onion por variável de ambiente, com transporte e um adaptador offline. **Não há medida de que o padrão
  venha do Esperanto.**

## Veredito: a resposta do maestro (/meta:decide, 2026-10-28), a selar pelo core

O maestro trouxe dois fatos que o estudo não tinha medido: há portas do Onion para outras ferramentas de IA, e já
existe um primeiro consumidor. A emenda B da Etapa 0 (`STAGE0-B.md`) foi commitada antes de medi-los, e o braço das
portas está em `evidence/ports-report.md`. A revisão adversarial dele (`evidence/elenxo/REVIEW-PORTS.md`) reprovou a
evidência da peça 2, e o maestro decidiu de novo com os fatos corrigidos.

**O que o braço das portas mostrou:**
- **Não existe repositório "claude-codex".** As portas são templates em que a própria ferramenta é o provedor. A ida e
  volta Claude ↔ Codex foi medida nesta curadoria, de agente para agente, sem cliente de modelo.
- **O consumidor é o `onion-slm`**, e o maestro confirmou.
- **O spike mede quatro especialistas prontos** (OpenAI Privacy Filter, GLiNER2-PII, NuExtract 3 e GLiNER2.5). Ao menos
  três são classificadores de token, que não falam Chat Completions.
- **Como dependência, o Esperanto atrapalharia pela cobertura,** não pelo tamanho. Não tem o effort da Anthropic e não
  cobre o backend por CLI. Em pacotes ele é menor (12) que o SDK da Anthropic que o consumidor já usa (16).
- **Do Esperanto nada se aproveita.** Para o modelo generativo, o padrão de mercado é o SDK oficial `openai` com
  `base_url`, ou o SDK de cada provedor.

| peça | resposta do maestro | destino que sela |
|---|---|---|
| **1. dependência do núcleo do Onion** (`D_PIECE_CORE_DEPENDENCY`) | **rejeitar**, pela 2ª vez | core |
| **2. cliente de vários provedores** (`D_PIECE_MULTI_PROVIDER_CLIENT_REJECT`, que substitui o selo de costurar) | **rejeitar, sem costura** | core |

Os dois nós estão `open`, com a resposta do maestro como testemunho. Eles fecham com `x_dissect_sealed_by` quando o core
selar. Não é preciso perguntar ao maestro de novo.

## Não verificado

A lista está no `meta.x_unverified` do grafo.

Orquestrado com 🧅 Onion Evolve
