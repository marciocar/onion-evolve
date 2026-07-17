---
title: 'ADR — SDAAL aninhado de 2 níveis (canal → solução): o adapter que é, ele mesmo, um SDAAL'
date: 2026-07-17
type: adr
status: accepted (design) — materialização GATED por nível (gated-until-trigger)
decision-scope: engineering / abstraction pattern (generaliza o eixo-por-faceta para 2 níveis)
supersedes: none
extends: docs/knowledge-base/concepts/onion-abstraction-doctrine.md (a SSOT do critério — este ADR cita, não recopia)
origin-signal: pedido do maestro 2026-07-17 (mensageria multi-canal-multi-solução encadeada; WAHA como adapter, não serviço)
deciders: maestro
related:
  - onion-adr-branch-roles-sdaal-2026-07.md (facetas/papéis + a regra de ouro compõe-N vs escolhe-1; o precedente mais próximo)
  - onion-parecer-whatsapp-sender-2026-07.md (a pesquisa que matou a Evolution como "melhor opção"; canal oficial p/ regulado)
  - rfc-0005-scope-inheritance-polymorphism.md (a fronteira versão×escopo que a regra de ouro crava)
  - knowledge-graph-sdaal.md (KG-SDAAL — mesmo acrônimo, coisa diferente; ver §Lacuna do KG)
---

# ADR — SDAAL aninhado de 2 níveis (canal → solução)

## Contexto (o furo, e como cheguei a ele sem defasagem)

"Enviar uma mensagem" tem **dois graus de liberdade**: o **canal** (whatsapp / sms / email / push) e, dentro de
cada canal, a **solução** (whatsapp → WAHA · Cloud API · BSP). O maestro pediu que o SDAAL nascesse pronto para
esse encadeamento — *"mesmo quando a solução for uma só mas com espera de ter mais, já deixa o SDAAL pronto, mas
para ser realmente usado desta maneira encadeada"*.

Antes de decidir, revisei **todo o cânone SDAAL** (padrões + ADRs + KG — 60 afirmações canônicas, 24 relevantes
ao aninhamento, 21 superadas/gated) via orquestração, porque a [doutrina de abstração][doutrina] é de **hoje**
(v1.0.0, 2026-07-17) e o espaço está em fluxo. Três achados sustentam este ADR:

1. **O contrato SDAAL abstrai UM eixo por instância** — o eixo varia (provider externo, tier, via), o contrato
   não ([doutrina][doutrina] §"O eixo abstraído varia"). **Aninhamento — um adapter que é, por dentro, outro
   SDAAL — nunca foi feito.**
2. **O 2 níveis está insinuado, não resolvido.** O transporte (`api|mcp|cli`) é um 2º grau de liberdade **dentro**
   do adapter, mas é **campo de config resolvido por detector, não um sub-SDAAL** — não pode ser citado como
   precedente de aninhamento. O `branch-roles-sdaal` resolve **facetas** (flow/environment/lineage) com adapter
   no nível TOPOLOGIA — próximo, mas não é "canal seleciona um sub-adapter que seleciona uma solução".
3. **O mercado valida o desenho** (pesquisa orquestrada, fonte primária): Novu/Knock modelam exatamente
   `channel → provider`, 2 níveis, com fallback nos dois eixos. Não é invenção nossa — é o padrão dominante.

## Decisão

**Reconhecer o SDAAL-aninhado como uma GENERALIZAÇÃO (não um padrão novo) do eixo-por-faceta:** um adapter de
nível-1 pode delegar a um **sub-SDAAL** de nível-2 quando — e somente quando — o sub-eixo passa o Teste do Eixo
por si. Cinco regras, todas ancoradas no cânone verificado em 1ª mão:

### 1. O Teste do Eixo é RECURSIVO — o aninhamento não é rota de fuga do gate

Cada nível responde às 3 condições do [Teste do Eixo][doutrina] (`onion-abstraction-doctrine.md:41-49`) **por
si**. Nível-1 (canal): há ≥2 canais reais e intercambiáveis sob o mesmo contrato? Nível-2 (solução): há ≥2
soluções reais para o canal escolhido? Se o nível-2 tem **1 real + N prometidos**, o nível-2 é **script/gated**
pelo Teste do Gatilho (`:55-64`), mesmo que o nível-1 gradue. **Aninhar não relaxa o gate — multiplica-o.**

### 2. Canal→solução é FACETA (escolhe-1), não ESCOPO (compõe-N)

Pela regra de ouro do `onion-adr-branch-roles-sdaal-2026-07.md:151-152` — *"compõe por leitura em runtime (N
camadas coexistem) → escopo; é uma linha paralela onde se fica numa por vez → papel de branch"* — mensageria é
**escolhe-1 por nível** (uma mensagem sai por um canal, com uma solução). Logo herda a mecânica **faceta/papel**
(resolução por-faceta, Null Object por-faceta com exit honesto — `:107-110`), **não** a de escopo composto
(cascata de N camadas do `resolve-scope-layers.sh`). Isto crava a fronteira: mensageria **não** é caso de RFC-0005.

### 3. Qual nível é o adapter — decisão explícita (espelha branch-roles Fase 3)

Como o branch-roles decidiu *"o adapter é a TOPOLOGIA… precedente: no `trust`, adapter = tier"*
(`branch-roles-sdaal:117-119`): aqui **o adapter concreto de nível-1 é o CANAL**; dentro dele, quando ≥2 soluções
reais existem, **o adapter de nível-2 é a SOLUÇÃO**. O canal que ainda tem 1 solução é um **adapter simples com
costura** (modelo forge, [anti-padrão #4][doutrina]: costura legítima, anúncio não), não um sub-SDAAL prematuro.

### 4. Default de solução é POR CANAL, declarado (precedente já aceito)

Assim como o default do 2º eixo diverge por domínio de forma declarada (task-manager→`api`, forge→`cli`,
federation-transport→`git-async` — `integrations.md:51-58`), **cada canal declara seu próprio default de
solução** no `.env`/stamp. Não há produto cartesiano obrigatório: um canal pode ter 1 solução e outro ter 3.

### 5. Fallback nos DOIS eixos, independentes (achado de mercado)

O contrato prevê fallback **entre canais** (channel-group: "tenta whatsapp, cai pra sms") **e** **entre soluções**
dentro de um canal (provider failover), como eixos separados — o padrão Knock/Courier. Cada um é opt-in e só
existe quando há ≥2 reais naquele eixo.

### Decisão sobre o GERADOR (o gap que a revisão do cânone expôs)

As 3 instâncias reais evoluíram o 2º eixo (transporte) **ad-hoc**, e o `/meta:create-abstraction` +
`sdaal-examples.md` **não modelam 2º eixo em lugar nenhum** (gap confirmado). Para **não perpetuar** o drift
"prática à frente do gerador", este ADR decide: **o gerador NÃO é estendido agora** (seria catedral no gerador
por 1 caso). O aninhamento é **extensão manual documentada** — como o transporte já é — e templatizar o 2º nível
no gerador fica **gated até o 2º caso real de aninhamento** (o 1º é messaging).

## O que este ADR NÃO é (defasagens que a revisão do cânone mandou evitar)

- **Não é um 3º formato SDAAL.** Os formatos canônicos são **dois** — SDAAL-provider e SDAAL-papel
  (`onion-abstraction-doctrine.md:68-78`). Aninhamento é uma **topologia de composição** de SDAALs, não um formato.
- **Não ressuscita "Null Object universal".** `none.md` **não** é obrigatório em toda instância (trust e
  federation-transport não têm) — correção de 2026-07-17 (`:75-78`). Cada nível do aninhamento segue essa regra.
- **Não inventa "SDAAL-transformação".** Transformação determinística sem LLM é script/P1 (`:80-81`).
- **Não anuncia canal/solução inexistente no `.env.example`** — anti-padrão #3/#4 (`declarado ≠ verificado`).
- **Não trata o transporte `api|mcp|cli` como sub-SDAAL** — é campo de config, não um segundo eixo de seleção.

## Invariantes

- **Cada nível passa o Teste do Eixo por si, ou não gradua.** O aninhamento multiplica o gate, nunca o contorna.
- **Materializar no gatilho, não antes** (design-only agora; o 2º real por nível materializa).
- **Este ADR cita a doutrina como SSOT, não recopia suas regras** ([fonte≠derivação][fonte]) — a doutrina
  `onion-abstraction-doctrine.md` é a SSOT operacional do critério; quando ela mudar, este ADR não é um 2º lugar
  a editar.

## Materialização (gated, por nível — o slice segue o dogfood)

| Nível | Gatilho nomeado | Estado |
|---|---|---|
| **Nível-1 (canal) gradua a SDAAL `messaging`** | 2 canais reais: `ntfy` (push, já existe ad-hoc em `mail-receiver.sh`) + `whatsapp` (WAHA rodando na infra do maestro) | gated até o WAHA rodar |
| **Nível-2 (solução) gradua o sub-SDAAL `whatsapp`** | 2 soluções reais: `waha` (dogfood) + `cloud-api` (Grana.Ai, canal oficial exigido por regulação) | gated até a Grana.Ai |
| **Templatizar o 2º nível no gerador** | 2º caso real de aninhamento além de messaging | gated |
| **Fallback entre soluções** | 2 soluções reais no mesmo canal | gated |

## Lacuna do KG (o "veja o KG" do maestro, respondido)

Nenhum `.kg.yaml` modela o **SDAAL-abstração** — os grafos só têm o **KG-SDAAL** (o SDAAL aplicado a
conhecimento: `knowledge-graph-sdaal.md:59-70`). São coisas distintas que compartilham o acrônimo. Consequência:
a evolução do padrão de abstração **não tem radar** que rode `SUPERSEDES`/`REFUTES` sobre suas decisões — a
blindagem contra defasagem é **manual/citacional** (a revisão do cânone que fundou este ADR), por isso este ADR
carrega suas próprias âncoras `file:line` e data a correção de 2026-07-17.
**Gatilho nomeado:** tornar a evolução do padrão SDAAL-abstração auditável em KG = dogfoodar `/meta:kg` sobre as
próprias decisões de abstração (audit layer: `claim`/`decision`/`SUPERSEDES`). Gated — não assumido feito aqui.

[doutrina]: ../knowledge-base/concepts/onion-abstraction-doctrine.md
[fonte]: ../knowledge-base/concepts/source-vs-derivation.md
