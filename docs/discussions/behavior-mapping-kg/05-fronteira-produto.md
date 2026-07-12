---
title: "P5 — Fronteira de produto: o sensor é capability do Onion pessoal (decisão aberta)"
category: discussion-note
status: fonte-de-discussao-isolada
branch: discuss/behavior-mapping-kg
responde: "SEED.md — pergunta 5 (feature do Onion pessoal vs produto próprio)"
lente: "feature × produto (continuum de VC) + a identidade canônica do Onion"
ancora_pesquisa: research/SYNTHESIS-P5.md
metodo: "pesquisa orquestrada 1 frente (citada) + identidade canônica; recomendação, não decisão"
constroi_sobre: [01-consentimento-dual, 02-intake-execucao, 03-captura-e-localidade, 04-sinal-ao-kg]
---

# 🧵 P5 — Fronteira de produto

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os
> outros temas. ⚠️ **Esta nota NÃO decide** — recomenda e deixa a escolha de rumo com o maestro.

## O veredito, em uma frase

**O enquadramento "sensor" alinha com a identidade do Onion (capability que alimenta o Onion
pessoal, não produto standalone); a hipótese "produto próprio" é real mas ocupada e conflita com a
identidade canônica — por isso a recomendação é sensor-como-capability, e a decisão fica ABERTA.**

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

## 3. A recomendação (não a decisão)

> **Sensor-como-capability do Onion pessoal.** O sensor (P1–P4: captura consentida, 3 gates, local-
> first, bruto→KG) é uma **capability** que alimenta `onion-pessoal-marcio` — não um produto
> próprio. A hipótese "produto próprio de process-mining consentido" **fica gated ao maestro**: é
> escolha de rumo (poderia justificar-se se a inteligência sobre o log virasse o diferencial, e se o
> maestro aceitar o desvio de identidade). A nota **não fecha** isto.

Por que deixar aberto e não decidir: a fronteira feature×produto é **contínua, não binária**, e a
escolha "virar produto" é estratégica (identidade, mercado, foco) — exatamente o tipo de decisão que
o padrão discussion-worktrees reserva ao maestro (*"nada promove ao core sem o maestro pedir"*).

## Honestidade (o fecho)

- **Sensor forte ≠ negócio viável.** ActivityWatch tem o melhor sensor e não monetiza como as apps
  fechadas — "ser a plataforma" e "ser o negócio" são coisas distintas.
- **Privacidade é diferencial E ônus.** O que a P1–P3 tratam como virtude (local-first, consentido)
  a literatura de personal informatics trata como custo de curadoria/retenção. As duas leituras convivem.
- **Recomendação ≠ veredito.** Eu recomendo o caminho-capability, mas a decisão de produto é do
  maestro — o proto deixa `D_SENSOR_AS_CAPABILITY` com `status: open` de propósito.
- **Fonte do "sensor estratégico" é composta** — montei a distinção das arquiteturas (ActivityWatch)
  + o cânone feature/produto, não de um artigo único que a nomeie assim.

## Tabela de fecho

| Caminho | A favor | Contra | Alinha com identidade? |
|---------|---------|--------|------------------------|
| **Sensor/capability** (recomendado) | coerente com framework-template; alimenta o cérebro pessoal | sozinho é "feature" | ✅ sim |
| **Produto próprio** | mercado real; valor na inteligência sobre o log | mercado ocupado; desvia da identidade canônica | ❌ conflita |
| **Decisão** | — | — | 🔓 **ABERTA — do maestro** |

## Dogfood

A fronteira vive como **grafo de decisão** (camada audit) em
[`proto/product-boundary.kg.yaml`](proto/product-boundary.kg.yaml) — a decisão
`D_SENSOR_AS_CAPABILITY` fica **`status: open`** (não decidida), com as hipóteses feature/produto e o
conflito de identidade como claims que ela `DEPENDS_ON`.

```bash
$ bash .claude/validation/kg-radar.sh docs/discussions/behavior-mapping-kg/proto/product-boundary.kg.yaml
# ══ RADAR: a decisão OPEN e a pergunta no topo da atenção — "isto ainda é do maestro"
# ══ RADAR-DE-DOMÍNIO: (camada domain ausente — grafo puramente epistêmico/audit)
# ══ INTEGRIDADE: ✅ sem contradições estruturais (8 nós, 9 arestas)  → exit 0
```

O radar deixa a decisão aberta no topo — a P5 mapeou o terreno e recomendou, mas o grafo registra
honestamente que a escolha **ainda não foi feita**.

---

## 🏁 A frente behavior-mapping-kg — as 5 perguntas do SEED

Com a P5, as cinco perguntas de partida do SEED estão **abertas e trabalhadas** (não "fechadas" — é
uma discussão):

| # | Nota | Veredito curto |
|---|------|----------------|
| Q1 | [01 — consentimento dual](01-consentimento-dual.md) | mapear consentido ≠ vigiar; dupla autorização; lacuna da inferência |
| Q2 | [02 — intake × execução](02-intake-execucao.md) | três gates (observar/inferir/agir), não um |
| Q3 | [03 — captura e localidade](03-captura-e-localidade.md) | passiva **E** declarada; bruto fica local |
| Q4 | [04 — sinal ao KG](04-sinal-ao-kg.md) | event/entity/claim; reconciliar faz×diz por SUPPORTS/REFUTES/SUPERSEDES |
| Q5 | [05 — fronteira de produto](05-fronteira-produto.md) | recomenda capability; **decisão de produto aberta** |

**Nada promove ao core sem o maestro pedir.** A frente pensou até clarear; o próximo passo (promover
algo a `feat/*`, aprofundar uma nota, ou descartar) é decisão do maestro.
