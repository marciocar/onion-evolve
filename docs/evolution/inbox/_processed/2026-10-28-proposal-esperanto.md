---
title: 'Dissecação do Esperanto (lfnovo/esperanto): rejeitar como dependência do núcleo; parquear o cliente de vários provedores'
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

## Veredito proposto, em duas peças

| peça | veredito | por quê |
|---|---|---|
| **1. dependência do núcleo do Onion** | **rejeitar**, pela 2ª vez | o grep por mecanismo na origin/main (`evidence/core-grep.txt`) não acha cliente de vários provedores; o único cliente direto de modelo é o curl da Anthropic no revisor de CI, por decisão Claude-only, e os outros dois usos são locais (transcrição e embedding); o core já tirou o Esperanto no dia 1 |
| **2. cliente de vários provedores para uma peça ou um adotante** | **parquear**, com gatilho | pela régua do necessário, zero consumidor hoje não é eliminatório, e há consumidores nomeados que podem aparecer: o adaptador `local-slm` da de-identificação (Ollama ou vLLM) saindo de gated, a transcrição por provedor de nuvem e o embedding de provedor no kg-ssot; o gatilho é uma evidência com SUPERSEDES para `Q_MULTI_PROVIDER_CONSUMER` |

**Quando o gatilho disparar,** a comparação é entre o padrão de mercado e a opção leve:
- **a LiteLLM,** o padrão de mercado: as mesmas cinco modalidades, 62 mil estrelas e 92 milhões de downloads por mês.
  Ela teve as versões 1.82.7 e 1.82.8 maliciosas no PyPI em 2026-03-24, que roubavam credenciais (Datadog Security
  Labs);
- **o Esperanto,** só com httpx e pydantic, a menor superfície de dependência.

Não há superação hoje: sem consumidor, nenhuma das duas entrega nada ao Onion.

Também fica declarado o conflito do corte pré-registrado ("nenhum consumidor reprova") com a régua do necessário da
doutrina. Foi por isso que a peça 2 ficou em parque.

## Não verificado

A lista está no `meta.x_unverified` do grafo.

Orquestrado com 🧅 Onion Evolve
