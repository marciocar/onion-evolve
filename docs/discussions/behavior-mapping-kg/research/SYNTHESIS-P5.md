---
title: "Síntese P5 — Fronteira de produto: sensor/feature × produto próprio"
category: research-synthesis
responde: "SEED.md — pergunta 5 (feature do Onion pessoal vs produto próprio)"
data: "2026-07-12"
branch: "discuss/behavior-mapping-kg"
fontes_verificadas: 9
metodo: "pesquisa orquestrada 1 frente (agente direto, WebSearch real) + identidade canônica do Onion"
---

# Síntese P5 — Sensor/feature × produto próprio

> **Carimbo: hoje = 2026-07-12.** Uma frente (landscape + estratégia feature/produto) + a identidade
> canônica do Onion (CLAUDE.md / onion-review-2026-05). Datas como fornecidas; **s/d** = sem data.

---

## Fronteira de produto — sensor/feature vs. produto próprio

O "process mining pessoal" reusa o mesmo insumo do corporativo — um **event log** — aplicado ao
indivíduo. Nesse insumo mora a distinção estratégica: **o sensor (captura do log) é camada de
plataforma; o produto é o que se faz com o log.** Ferramentas provam a linha: **ActivityWatch** se
posiciona como *datastore* local-first extensível (um sensor que outros consomem), enquanto
RescueTime/Rize/Timely divergem no que fazem *depois* do log (relatório / billing / timesheet por
IA). Quem só entrega o log corre o risco clássico de ser **feature, não produto**. O cânone de VC
formaliza o teste: você é *feature* se cada usuário te "compra" por um motivo diferente e depende de
outro produto para chegar ao mercado; vira *produto* quando a dor é universal num mercado grande com
distribuição própria. A versão enterprise (Celonis, SAP Signavio, Microsoft, UiPath, Fluxicon) já é
categoria bilionária — prova de que **o valor está na inteligência sobre o log, não no log em si**.

- **ActivityWatch** — sensor/plataforma puro: datastore local-first, buckets de séries temporais,
  API de eventos/query, watchers como plugins — [ActivityWatch docs](https://docs.activitywatch.net/en/latest/) / [site](https://activitywatch.net/), s/d (MPL-2.0).
- O mesmo sensor vira produtos diferentes conforme a camada de aplicação — [Rize vs RescueTime](https://rize.io/blog/rize-vs-rescuetime), 2026.
- Log privado alimenta múltiplos produtos (Timely billing, **Dewo** deep work); memórias nunca
  compartilhadas — [Timely Memory App](https://www.timely.com/memory-app/), s/d; [Memory.ai levanta US$14M (TechCrunch)](https://techcrunch.com/2021/06/22/memory-ai-the-startup-behind-time-tracking-app-timely-raises-14m-to-build-more-ai-based-productivity-apps/), 2021.
- **Feature → Product → Company continuum**: "se cada usuário compra por um motivo diferente, é
  feature set, não produto" — [Seth Levine](https://www.sethlevine.com/archives/2017/10/the-feature-product-company-continuum.html), 2017; [Feature not a company (Feld)](https://www.askthevc.com/what-does-a-vc-mean-when-he-says-your-product-is-a-feature-and-not-a-company/), s/d; [Build a company, not a feature (TechCrunch)](https://techcrunch.com/2023/01/17/build-a-company-not-a-feature/), 2023.
- Process mining enterprise = categoria madura (1º Gartner MQ em 2024) — o valor defensável é a
  inteligência sobre o log — [Gartner Process Mining](https://www.gartner.com/en/information-technology/glossary/process-mining), s/d; [2024 MQ takeaways](https://solutionsreview.com/business-process-management/key-takeaways-2024-gartner-magic-quadrant-for-process-mining-tools/), 2024.
- "Personal informatics" como produto: curadoria é fardo, retenção frágil, privacidade é ônus
  operacional — [Personal Informatics challenges (Springer)](https://link.springer.com/chapter/10.1007/978-3-319-07509-9_58), 2014; [Privacy Challenges in the Quantified Self (PETS)](https://petsymposium.org/2016/files/papers/Privacy_Challenges_in_the_Quantified_Self_Movement_%E2%80%93_An_EU_Perspective.pdf), 2016.

**Tensões:** sensor forte ≠ produto viável (ActivityWatch tem o melhor sensor e não monetiza como as
apps fechadas). Privacidade é **diferencial e ônus** ao mesmo tempo. "Feature × produto" é
**contínuo, não binário** — quase toda empresa começa no meio; os critérios (dependência de
plataforma alheia × universalidade da dor) são complementares. **Honestidade:** não achei fonte
primária que use "sensor" no sentido estratégico exato — a distinção foi montada das arquiteturas
(ActivityWatch como datastore) + o cânone feature/produto.

---

## O peso do lado do Onion (identidade canônica)

A decisão não é só de mercado — colide com a **identidade canônica** do Onion (CLAUDE.md /
[onion-review-2026-05](../../analysis/onion-review-2026-05.md)):

- Onion é **framework template em `.claude/`** — *não é produto npm, não é distribuído publicamente,
  não tem CLI standalone*. O plano v4.0 (CLI standalone, multi-IDE) foi **formalmente abandonado**
  em 2026-05-18.
- O SEED já enquadra este sensor como **o insumo que alimenta** `discuss/onion-pessoal-marcio` (o
  cérebro pessoal) e `discuss/interface-state-of-art` (telemetria) — ou seja, nasceu como **sensor
  de uma plataforma**, não como produto de ponta a ponta.

## Implicações para a nota P5 (decisão ABERTA)

1. **O enquadramento "sensor" alinha com a identidade** — capability que alimenta o Onion pessoal,
   não produto standalone (que contradiria "não é produto npm/sem CLI").
2. **O mercado do "produto próprio" é real mas ocupado** — RescueTime/Timely/ActivityWatch + o
   enterprise bilionário; entrar como produto é competição, não greenfield.
3. **O valor está na inteligência sobre o log** — que é justamente o que o Onion pessoal (o cérebro)
   faz; o sensor sozinho é feature.
4. **Recomendação (não decisão):** sensor-como-**capability** do Onion pessoal; a hipótese
   produto-próprio fica **gated ao maestro** — é escolha de rumo, não de execução. A nota **não
   fecha** isto.
