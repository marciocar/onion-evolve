---
title: "P5 — Fronteira de produto: o sensor é capability do Onion pessoal (DECIDIDO; produto deferido)"
category: discussion-note
status: fonte-de-discussao-isolada
decisao: "FECHADA 2026-07-12 — sensor-como-capability; produto próprio deferido (gated: pull frio externo)"
branch: discuss/behavior-mapping-kg
responde: "SEED.md — pergunta 5 (feature do Onion pessoal vs produto próprio)"
lente: "feature × produto (continuum de VC) + a identidade canônica do Onion"
ancora_pesquisa: research/SYNTHESIS-P5.md
metodo: "pesquisa orquestrada 1 frente (citada) + identidade canônica; decisão do maestro em 2026-07-12"
constroi_sobre: [01-consentimento-dual, 02-intake-execucao, 03-captura-e-localidade, 04-sinal-ao-kg]
---

# 🧵 P5 — Fronteira de produto

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os
> outros temas. ✅ **DECIDIDA pelo maestro (2026-07-12):** sensor-como-**capability**; o produto
> próprio fica **deferido** (revisável se surgir pull frio externo). A recomendação abaixo virou decisão.

## O veredito, em uma frase

**O enquadramento "sensor" alinha com a identidade do Onion (capability que alimenta o Onion
pessoal, não produto standalone); a hipótese "produto próprio" é real mas ocupada e conflita com a
identidade canônica — por isso a decisão (fechada em 2026-07-12) é sensor-como-**capability**, com o
produto próprio **deferido** e revisável se surgir pull frio externo.**

## 1. Sensor é plataforma; produto é o que se faz com o log

A distinção estratégica ([SYNTHESIS-P5](research/SYNTHESIS-P5.md)): **o sensor (captura do event log)
é camada de plataforma; o produto é a inteligência sobre o log.** O landscape prova — **ActivityWatch**
é sensor puro (datastore local-first, API), enquanto RescueTime/Rize/Timely divergem no que fazem
*depois* (relatório / billing / timesheet). Quem só entrega o log é **feature, não produto** (o teste
de VC: você é feature se cada um te "compra" por um motivo diferente e depende de outro produto para
chegar ao mercado). E o enterprise (Celonis/SAP/UiPath, categoria bilionária) prova que **o valor
defensável está na inteligência sobre o log, não no log**.

## 2. O peso da identidade canônica do Onion

A decisão não é só de mercado — colide com a identidade do Onion
([onion-review-2026-05](../../analysis/onion-review-2026-05.md), consolidada no CLAUDE.md):

- Onion é **framework template em `.claude/`** — *não é produto npm, não é distribuído publicamente,
  não tem CLI standalone*. O plano v4.0 (CLI standalone, multi-IDE) foi **abandonado** em 2026-05-18.
- O próprio SEED enquadra este sensor como **o insumo que alimenta** `discuss/onion-pessoal-marcio`
  (o cérebro) e `discuss/interface-state-of-art` (telemetria). Ele **nasceu como sensor de uma
  plataforma**, não como produto de ponta a ponta.

Um **produto standalone** de process-mining pessoal seria, portanto, um desvio da identidade
canônica **e** entrada num mercado ocupado (RescueTime/Timely + enterprise). Um **sensor/capability**
que alimenta o Onion pessoal é coerente com a tese knowledge-centric: atividade bruta → conhecimento
reconciliado (P4), consumido pelo cérebro pessoal.

## 3. A decisão (fechada pelo maestro, 2026-07-12)

> **DECIDIDO: sensor-como-capability do Onion pessoal.** O sensor (P1–P4: captura consentida, 3
> gates, local-first, bruto→KG) é uma **capability** que alimenta `onion-pessoal-marcio` — não um
> produto próprio. A hipótese "produto próprio de process-mining consentido" fica **DEFERIDA** (não
> descartada): revisável **se e quando** surgir um **pull frio externo** que prove a dor num mercado
> grande — o gatilho herda o desempate `Q_COLD_ADOPTER` do north-star (hoje: *zero adotante frio* →
> a demanda é do eixo, não do Onion).

Por que capability, e por que deferir (não matar) o produto:
- **Capability** alinha com a identidade canônica (framework-template, sem CLI/produto standalone) e
  com a tese knowledge-centric — o valor está na inteligência sobre o log, que é o cérebro pessoal.
- **Deferir** (não descartar) é honesto: a fronteira feature×produto é **contínua, não binária**;
  um pull frio externo futuro poderia reabrir a hipótese-produto sem contradizer esta decisão.
- **Gatilho de revisão:** surgir demanda arms-length por um process-mining pessoal standalone
  (o experimento `Q_COLD_ADOPTER`). Enquanto não surgir, capability é a escolha.

## Honestidade (o fecho)

- **Sensor forte ≠ negócio viável.** ActivityWatch tem o melhor sensor e não monetiza como as apps
  fechadas — "ser a plataforma" e "ser o negócio" são coisas distintas.
- **Privacidade é diferencial E ônus.** O que a P1–P3 tratam como virtude (local-first, consentido)
  a literatura de personal informatics trata como custo de curadoria/retenção. As duas leituras convivem.
- **Decidido, não `done`.** O maestro fechou como capability (`D_SENSOR_AS_CAPABILITY` = `confirmed`),
  mas não é `done`: rumo estratégico não se verifica em PROD. Fica **revisável** pelo gatilho de pull
  frio — o proto mantém `C_PRODUCT` `open` (deferido), não refutado.
- **Fonte do "sensor estratégico" é composta** — montei a distinção das arquiteturas (ActivityWatch)
  + o cânone feature/produto, não de um artigo único que a nomeie assim.

## Tabela de fecho

| Caminho | A favor | Contra | Veredito |
|---------|---------|--------|----------|
| **Sensor/capability** | coerente com framework-template; alimenta o cérebro pessoal | sozinho é "feature" | ✅ **ESCOLHIDO** |
| **Produto próprio** | mercado real; valor na inteligência sobre o log | mercado ocupado; desvia da identidade canônica | ⏸️ **DEFERIDO** (gated: pull frio) |
| **Decisão** | — | — | ✅ **FECHADA 2026-07-12 — capability** |

## Dogfood

A fronteira vive como **grafo de decisão** (camada audit) em
[`proto/product-boundary.kg.yaml`](proto/product-boundary.kg.yaml) — a decisão
`D_SENSOR_AS_CAPABILITY` agora é **`status: confirmed`**; `C_FEATURE` confirmado; `C_PRODUCT` fica
`open` (**deferido**, não refutado); e uma evidência `E_NORTHSTAR` sustenta deferir o produto.

```bash
$ bash .claude/validation/kg-radar.sh docs/discussions/behavior-mapping-kg/proto/product-boundary.kg.yaml
# ══ RADAR: D_SENSOR_AS_CAPABILITY (confirmed) + C_FEATURE no topo; C_PRODUCT despencou (deferido)
# ══ RADAR-DE-DOMÍNIO: (camada domain ausente — grafo puramente epistêmico/audit)
# ══ INTEGRIDADE: ✅ sem contradições estruturais (9 nós, 10 arestas)  → exit 0
```

O radar agora coloca a **decisão fechada** no topo — a P5 mapeou o terreno, o maestro decidiu, e o
grafo registra o fecho (capability) mantendo o produto como hipótese **deferida**, não morta.

---

## 🏁 A frente behavior-mapping-kg — as 5 perguntas do SEED

Com a P5 **fechada**, as cinco perguntas de partida do SEED estão trabalhadas — e a única decisão de
rumo (Q5) foi tomada:

| # | Nota | Veredito curto |
|---|------|----------------|
| Q1 | [01 — consentimento dual](01-consentimento-dual.md) | mapear consentido ≠ vigiar; dupla autorização; lacuna da inferência |
| Q2 | [02 — intake × execução](02-intake-execucao.md) | três gates (observar/inferir/agir), não um |
| Q3 | [03 — captura e localidade](03-captura-e-localidade.md) | passiva **E** declarada; bruto fica local |
| Q4 | [04 — sinal ao KG](04-sinal-ao-kg.md) | event/entity/claim; reconciliar faz×diz por SUPPORTS/REFUTES/SUPERSEDES |
| Q5 | [05 — fronteira de produto](05-fronteira-produto.md) | ✅ **DECIDIDO: capability**; produto próprio **deferido** (gated: pull frio) |

**Nada promove ao core sem o maestro pedir.** A frente pensou até clarear; o próximo passo (promover
algo a `feat/*`, aprofundar uma nota, ou descartar) é decisão do maestro.
