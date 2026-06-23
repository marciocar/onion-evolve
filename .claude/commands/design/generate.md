---
name: generate
description: |
  Camada generativa da vertical de design: diverge (N identidades por IA, em frota
  paralela) → converge (gate WCAG determinístico filtra + juiz ranqueia) → vencedora
  alimenta o DEVELOP do /design:identity. A IA gera; o gate decide. Orquestra a frota
  via onion-fleet/Workflow (generate-and-filter). Delega a @brand-generator (workers).
model: opus
allowed-tools: Read Write Edit Glob Grep Workflow Bash(bash .claude/validation/*) Bash(bash .claude/utils/design-source/*) Bash(mktemp*) Bash(rm -rf /tmp/*)
category: design
tags: [design, tokens, generative, fleet, wcag, branding]
version: "0.1.0"
updated: "2026-06-23"
related_agents:
  - brand-generator
  - design-system-specialist
  - branding-positioning-specialist
related_commands:
  - /design:identity
  - /product:branding
  - /meta:fleet
---

# /design:generate — Identidade generativa (diverge → converge)

## Objetivo

Explorar o **espaço de identidades** de uma marca por **geração divergente** (várias direções de
paleta propostas por IA, em paralelo) e **convergência determinística** (o gate WCAG filtra; um juiz
ranqueia as aprovadas por aderência ao brief). A vencedora não é "a que a IA gostou" — é **uma que
passou no contraste calculado** e melhor atende o brief.

> **Princípio reitor.** A IA **gera**, o **gate decide**. Contraste é **calculado**
> (`lint-design-tokens.sh`), nunca "achado" pelo modelo — que é o pior juiz da própria saída
> (doutrina de dogfooding). A frota cobre largura (N ângulos independentes); o gate corta o que
> não serve.

## Fronteiras

- **Alimenta**, não substitui, o `/design:identity`: a candidata vencedora vira input do **DEVELOP**
  (Fase 2) do identity, que a materializa via `design-sink`. Aqui só se **gera e escolhe**.
- **NÃO** decide posicionamento → o brief vem de `/product:branding` / `business-context`.
- **NÃO** commita candidatas na SSOT automaticamente: vivem em staging (`/tmp` ou
  `docs/design-context/_candidates/`) até o **maestro** escolher e promover. Promover uma 2ª marca
  na cascata pende do gatilho do [ADR de peer](../../../docs/design-context/decisions/onion-adr-design-peer-promotion.md).
- **É OPT-IN de frota**: dispara a ferramenta `Workflow` (custo de N workers). Avisar escopo/custo antes.

## Fluxo (orquestração de frota — generate-and-filter)

Padrão canônico da skill [`onion-fleet`](../../skills/onion-fleet/SKILL.md) (KB `agent-fleet-orchestration`).
A orquestração mora **aqui** (comando, nível principal) — nunca dentro de um worker.

### 1. BRIEF + ângulos
Ler `docs/design-context/brief.md` (ou coletar o mínimo com o maestro). Derivar **N ângulos
divergentes** (ex.: `conservadora`, `ousada`, `alto-contraste`, `monocromática-quente`) — cada um
guia um worker, para cobrir o espaço sem convergir cedo. `N` default 4 (ajustável ao budget).

### 2. DIVERGE (fan-out, `Workflow`)
N `@brand-generator` em **paralelo** (`parallel()`), cada um com seu ângulo, `schema` de candidata
(foundations + semantic + contrast-pairs), tier **sonnet** (worker generativo). Independência real:
nenhum lê a saída do outro.

### 3. CONVERGE (filtro determinístico, 0 tokens)
Para **cada** candidata: escrever os tokens num `design-context` temporário e rodar o **gate**:
```bash
bash .claude/validation/lint-design-tokens.sh "<tmp-da-candidata>"
```
Reprovadas (contraste < mín, alias órfão/ciclo, DTCG malformado) são **descartadas** — o corte é
calculado, não opinião. Reportar quantas passaram/cairam (`SKIP — <motivo>`).

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
/design:generate — <scope> — frota generate-and-filter
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Ângulos     : <N> (conservadora, ousada, …)  · workers: <N> sonnet
◆ Geradas     : <N>  → Gate WCAG: <P> aprovadas / <R> descartadas (SKIP)
◆ Vencedora   : <ângulo> — <rationale 1 linha> — contraste min <ratio>
◆ Runners-up  : <ângulo>, <ângulo>
▶ Próximo     : maestro promove? → /design:identity DEVELOP <scope>
```

## Referências

- Workers: `@brand-generator` · Materializa o vencedor: `@design-system-specialist`
- Gate: `.claude/validation/lint-design-tokens.sh` · Ingestão: `.claude/utils/design-source/`
- Frota: skill `onion-fleet` · `/meta:fleet` · KB `agent-fleet-orchestration`
- Consome o vencedor: `/design:identity` (Fase 2 DEVELOP) · Brief: `/product:branding`
- Peer provisório: `docs/design-context/decisions/onion-adr-design-peer-promotion.md`
