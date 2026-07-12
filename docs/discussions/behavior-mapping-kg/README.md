---
title: "Índice — frente behavior-mapping-kg (sensor de comportamento → contexto)"
category: discussion-index
status: fonte-de-discussao-isolada
branch: discuss/behavior-mapping-kg
---

# 🧵 behavior-mapping-kg — índice da frente

> **Isolada.** Pensa, não entrega. **Nada vai pro core sem o maestro pedir.** Não misturar com os
> outros temas. ⚠️ Tema de alta sensibilidade (privacidade) — a ética vem antes do "como coletar".

**O tema** ([SEED.md](SEED.md)): algo que **coleta e mapeia** o comportamento do usuário
(multi-superfície) para **documentar, padronizar, entender e automatizar** — e o **cataloga com KG
SDAAL**. Sempre no sentido de **mapeamento consentido e deliberadamente autorizado** (a pessoa **E** a
organização querem+autorizam; nunca imposto nem acidental) — **não é vigilância**.

## As 5 perguntas → 5 notas

| # | Nota | Veredito, em uma frase | Pesquisa | Proto (radar ✅) |
|---|------|------------------------|----------|------------------|
| **Q1** | [01 — consentimento dual](01-consentimento-dual.md) | Mapear consentido ≠ vigiar; dupla autorização (pessoa **E** org); a inferência é a lacuna que o consentimento não fecha. | [P1](research/SYNTHESIS-P1.md) | [consent](proto/consent.kg.yaml) |
| **Q2** | [02 — intake × execução](02-intake-execucao.md) | **Três gates, não um**: observar, inferir e agir; entre eles, intake autônomo. | [P2](research/SYNTHESIS-P2.md) | [pipeline-gates](proto/pipeline-gates.kg.yaml) |
| **Q3** | [03 — captura e localidade](03-captura-e-localidade.md) | Passiva **E** declarada (o say-do gap é informação); o bruto fica **local**, só o predicado sai. | [P3](research/SYNTHESIS-P3.md) | [capture-modes](proto/capture-modes.kg.yaml) |
| **Q4** | [04 — sinal ao KG](04-sinal-ao-kg.md) | Ação → `event` (PROD); pessoa/app/doc → `entity`; inferência → `claim`; reconciliar faz×diz por SUPPORTS/REFUTES/SUPERSEDES. | [P4](research/SYNTHESIS-P4.md) | [signal-to-kg](proto/signal-to-kg.kg.yaml) |
| **Q5** | [05 — fronteira de produto](05-fronteira-produto.md) | ✅ **DECIDIDO (2026-07-12): sensor-como-capability** do Onion pessoal; produto próprio **deferido** (gated: pull frio externo). | [P5](research/SYNTHESIS-P5.md) | [product-boundary](proto/product-boundary.kg.yaml) |

## O fio que liga as notas

1. **Ética primeiro** (Q1): a linha é mapear-para-melhoria × vigiar; e a permissão de **observar** é
   o gate — não o guardar.
2. **Onde ficam os gates** (Q2): a linha intake↔execução do Onion, aplicada ao pipeline bruto→ação,
   dá **três** gates (observar/inferir/agir). Derivar já é ato regulado (SCHUFA).
3. **Como e onde capturar** (Q3): triangular passiva+declarada; local-first, bruto não sai.
4. **Como catalogar** (Q4): o mapa bruto→KG e a reconciliação faz×diz (o say-do gap vira aresta).
5. **O que isto é** (Q5): ✅ **decidido — capability** do Onion pessoal; produto próprio deferido (revisável se surgir pull frio externo).

## Convenção

Cada nota segue o padrão do front-irmão `onion-pessoal-marcio`: **pesquisa citada antes de posição**
(`research/SYNTHESIS-P*.md`, verificada, com carimbo temporal honesto) → nota numerada (veredito →
análise → **Honestidade** → tabela → **Dogfood**) → um `proto/*.kg.yaml` validado pelo
`kg-radar.sh` (motor determinístico do KG SDAAL). Todos os 5 protos passam o gate de integridade.

## Estado

As 5 perguntas do SEED estão trabalhadas e a **decisão de rumo (Q5) foi fechada** (2026-07-12:
capability, produto deferido). O próximo passo — promover algo a `feat/*`, aprofundar uma nota, ou
parkear — é **decisão do maestro**. Ligações vivas: `discuss/onion-pessoal-marcio` (o cérebro que este sensor
alimentaria), `discuss/interface-state-of-art` (telemetria).
