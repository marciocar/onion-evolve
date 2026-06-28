---
name: generate
description: |
  Camada generativa da vertical de design: diverge (N identidades por IA, em orquestração
  paralela) → converge (gate WCAG determinístico filtra + juiz ranqueia) → vencedora
  alimenta o DEVELOP do /design:identity. A IA gera; o gate decide. Orquestra os workers
  via onion-orchestration/Workflow (generate-and-filter). Delega a @brand-generator (workers).
model: opus
allowed-tools: Read Write Edit Glob Grep Workflow Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/utils/design-source/*) Bash(mktemp -d -t onion-design-*) Bash(rm -rf /tmp/onion-design-*)
category: design
tags: [design, tokens, generative, orchestration, wcag, branding]
version: "0.1.0"
updated: "2026-06-23"
related_agents:
  - brand-generator
  - design-system-specialist
  - branding-positioning-specialist
related_commands:
  - /design:identity
  - /product:branding
  - /meta:orchestrate
---

# /design:generate — Identidade generativa (diverge → converge)

## Objetivo

Explorar o **espaço de identidades** de uma marca por **geração divergente** (várias direções de
paleta propostas por IA, em paralelo) e **convergência determinística** (o gate WCAG filtra; um juiz
ranqueia as aprovadas por aderência ao brief). A vencedora não é "a que a IA gostou" — é **uma que
passou no contraste calculado** e melhor atende o brief.

> **Princípio reitor.** A IA **gera**, o **gate decide**. Contraste é **calculado**
> (`lint-design-tokens.sh`), nunca "achado" pelo modelo — que é o pior juiz da própria saída
> (doutrina de dogfooding). A orquestração cobre largura (N ângulos independentes); o gate corta o que
> não serve.

## Fronteiras

- **Alimenta**, não substitui, o `/design:identity`: a candidata vencedora vira input do **DEVELOP**
  (Fase 2) do identity, que a materializa via `design-sink`. Aqui só se **gera e escolhe**.
- **NÃO** decide posicionamento → o brief vem de `/product:branding` / `business-context`.
- **NÃO** commita candidatas na SSOT automaticamente: vivem em staging (`/tmp` ou
  `docs/design-context/_candidates/`) até o **maestro** escolher e promover. Promover uma 2ª marca
  na cascata pende do gatilho do [ADR de peer](../../../docs/design-context/decisions/onion-adr-design-peer-promotion.md).
- **É OPT-IN de orquestração**: dispara a ferramenta `Workflow` (custo de N workers). Avisar escopo/custo antes.

## Fluxo (orquestração de subagentes — generate-and-filter)

Padrão canônico da skill [`onion-orchestration`](../../skills/onion-orchestration/SKILL.md) (KB `agent-orchestration`).
A orquestração mora **aqui** (comando, nível principal) — nunca dentro de um worker.

### 1. BRIEF + ângulos
Ler `docs/design-context/brief.md` (ou coletar o mínimo com o maestro). Derivar **N ângulos
divergentes** (ex.: `conservadora`, `ousada`, `alto-contraste`, `monocromática-quente`) — cada um
guia um worker, para cobrir o espaço sem convergir cedo. `N` default 4 (ajustável ao budget).

### 2. DIVERGE (fan-out, `Workflow`)
N `@brand-generator` em **paralelo** (`parallel()`), cada um com seu ângulo, tier **sonnet** (worker
generativo). Independência real: nenhum lê a saída do outro.

> **Contrato worker↔gate (importante).** A **estrutura de papéis é FIXA pela SSOT**, não pelo worker: o
> `semantic/` (papéis → `{alias}`) e o `governance/contrast-pairs.json` (quais pares o gate verifica, por
> **path de token**, ex. `color.on-surface.strong`/`color.surface.base`) vêm do projeto. Cada worker varia
> **só as `foundations`** (a paleta crua), com os **nomes de foundation que o `semantic` espera**
> (`brand.*`, `neutral.*`, `green/blue/red/amber.500`). Assim a comparação é justa (mesmos pares para todas)
> e o gate não reprova por descasamento de nomenclatura. O `schema` da candidata é, portanto,
> `{ angle, rationale, foundations }` — **não** carrega `contrast-pairs` (esses são da SSOT).

### 3. CONVERGE (filtro determinístico, 0 tokens)
Para **cada** candidata, montar um `design-context` temporário e rodar o **gate**:
```bash
tmp="$(mktemp -d -t onion-design-XXXXXX)"
mkdir -p "$tmp/docs/design-context"/{foundations,semantic,governance}
# foundations da candidata: paleta flat → DTCG via o adapter file da F3 (reuso)
printf '%s' "<foundations-flat-json>" \
  | bash ${CLAUDE_PLUGIN_ROOT}/utils/design-source/file-to-tokens.sh - \
  > "$tmp/docs/design-context/foundations/color.tokens.json"
# semantic + governance: estrutura FIXA da SSOT (copiar a do projeto)
cp docs/design-context/semantic/color.tokens.json      "$tmp/docs/design-context/semantic/"
cp docs/design-context/governance/contrast-pairs.json  "$tmp/docs/design-context/governance/"
bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-design-tokens.sh "$tmp" && rm -rf "$tmp"
```
Reprovadas (contraste < mín, alias órfão/ciclo, DTCG malformado) são **descartadas** — o corte é
calculado, não opinião. Reportar quantas passaram/caíram (`SKIP — <motivo>`). _(É exatamente este passo
que justifica a permissão `design-source/*`: a F3 materializa as `foundations` da candidata em DTCG.)_

### 4. RANQUEAR (juiz) + fan-in
Um **juiz** (agente independente, opus) ranqueia **só as aprovadas** por aderência ao brief
(personalidade, tom, restrições) — não por contraste (já garantido). Fan-in no nível principal:
um único resultado com a **vencedora** + runners-up + o porquê.

### 5. ENTREGA ao maestro
Apresentar a vencedora (tokens + rationale) e **parar**: o maestro decide promover. Se sim → vira
input do `/design:identity` DEVELOP (escopo `core` ou `brands/<brand>` para multi-brand).

## Dogfood (padrão master)

Rodar no próprio onion-evolve: gerar variações candidatas da **identidade Onion** (ancoradas em
`#D97757`/`#8A2BE2`), filtrar pelo gate, ranquear — **sem** commitar como 2ª marca (a cascata
multi-brand pende de marca real, ADR-peer). Testar **modo de falha**: um ângulo que force baixo
contraste deve ser **descartado** pelo gate, não vencer. Prova que "o gate decide", não a IA.

## Saída esperada

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/design:generate — <scope> — orquestração generate-and-filter
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Ângulos     : <N> (conservadora, ousada, …)  · workers: <N> sonnet
◆ Geradas     : <N>  → Gate WCAG: <P> aprovadas / <R> descartadas (SKIP)
◆ Vencedora   : <ângulo> — <rationale 1 linha> — contraste min <ratio>
◆ Runners-up  : <ângulo>, <ângulo>
▶ Próximo     : maestro promove? → /design:identity DEVELOP <scope>
```

## Referências

- Workers: `@brand-generator` · Materializa o vencedor: `@design-system-specialist`
- Gate: `${CLAUDE_PLUGIN_ROOT}/validation/lint-design-tokens.sh` · Ingestão: `${CLAUDE_PLUGIN_ROOT}/utils/design-source/`
- Orquestração: skill `onion-orchestration` · `/meta:orchestrate` · KB `agent-orchestration`
- Consome o vencedor: `/design:identity` (Fase 2 DEVELOP) · Brief: `/product:branding`
- Peer provisório: `docs/design-context/decisions/onion-adr-design-peer-promotion.md`
