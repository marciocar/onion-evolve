---
title: 'ADR — O ingestor de doutrina: o core absorve doutrina de campo do adotante (trust-gated, KG-backed, human-gated)'
date: 2026-07-18
type: adr
status: accepted (doutrina) — 1º dogfood nesta rodada (granaai); generalização a F4 é gated
decision-scope: co-evolution / federation (o elo ingestor que faltava na cadeia adotante→core)
supersedes: none
extends:
  - rfc/rfc-0003-federated-identity-collective-intelligence.md (F4 síntese coletiva — este ADR é o precursor CURADO, não o automático)
origin-signal: exploração orquestrada 2026-07-18 (docs/evolution/research/doctrine-sync-ingestor-2026-07/SYNTHESIS.md)
deciders: maestro
related:
  - docs/evolution/research/doctrine-sync-ingestor-2026-07/SYNTHESIS.md (o diagnóstico)
  - knowledge-graph-sdaal.md (o substrato: SUPERSEDES/planes/radar)
  - onion-adr-branch-roles-sdaal-2026-07.md (trust como policy-as-data)
---

# ADR — O ingestor de doutrina (adotante→core)

## Contexto (o buraco nomeado)

A cadeia **doutrina adotante→core** tem a metade produtora+transporte construída (`/meta:diary` →
`export-sharable` → `co-relay`/a2a-live → gate de `trust:`), mas a metade **ingestora no core está
vazia**: o "agregador que ingere com política" foi **nomeado** (research `S4:88`) e nunca construído.
Hoje o `/meta:co-evolve` **tria** um sinal (fix/feature/backlog) mas **não absorve** uma DOUTRINA
estruturalmente — ela vira prosa num `_processed/`, não conhecimento do core. A síntese coletiva
automática (RFC-0003 **F4**) está gated atrás de "3+ instâncias, diários 90d". Mas doutrina de campo
**chega agora** (granaai entregou 4 sinais de KG) — e o core não tem por onde absorvê-la.

## Decisão

**O ingestor de doutrina**: o core absorve doutrina de campo do adotante por **absorção curada,
trust-gated, KG-backed e human-gated** — o **precursor curado** da F4, não o sintetizador automático.

### 1. Trust-gate (quem pode corrigir o core)
Só se absorve **correção/conselho** de um membro cujo `trust.can_correct_to` (ou `can_advise_to`)
inclui `onion-evolve` no `members.yaml`. É policy-as-data — não prosa. (granaai:
`can_correct_to: [onion-evolve]`, elevado por rigor comprovado — autoriza esta rodada.)

### 2. KG-backed (a absorção é um grafo, não um despacho)
A doutrina entrante vira um `.kg.yaml` (audit): **evidence** (o sinal, com `arquivo:linha`) →
**claim** (a doutrina destilada) → **decision** (absorver | backlog | superseded). O `kg-radar` sai
**exit 0** (a absorção não pode se contradizer). Reusa o `SUPERSEDES` do KG SDAAL: doutrina que
atualiza uma visão anterior do core **supera sem apagar**.

### 3. Aterrissagem por tipo (a política)
- **Doutrina** (princípio durável) → **KB canônico** (ex.: `knowledge-graph-sdaal.md`), com crédito
  ao adotante e `arquivo:linha`.
- **Feature/fix** → **backlog** (não é doutrina; entra no ciclo de engenharia).
- **Já-feito** → nó `superseded`/`done` (a visão anterior do core é superada).
- **Soberania preservada:** absorve-se o **princípio/método**, nunca o **código** do adotante (ex.:
  a auto-extração de `TRACES_TO` fica soberana do gerador de cada instância; o core carrega a doutrina
  + um radar de *aviso*, não o parser do adotante).

### 4. Human-gated (ato-3) + declarado≠verificado
Nada auto-aterrissa: o maestro confirma a absorção. E ela só é "verificada" com **radar exit 0** /
`arquivo:linha` — declarado (o sinal existe) ≠ verificado (a doutrina foi absorvida e não contradiz).

## 1º dogfood (esta rodada — granaai)
Os 4 sinais de KG do granaai, modelados em `docs/onion/graph/granaai-doctrine-absorption-2026-07.kg.yaml`
(radar exit 0):
- **S1** (integridade técnica ≠ completude de rastreabilidade) → **KB** (nota de doutrina).
- **S3a** (validador local **delega** ao radar soberano) → **KB** (nota de doutrina).
- **S3b** (`--update` regenera `inventory.md`) + **S4** (`/meta:kg map <projeto>`) → **backlog**.
- **S2** (fail-open) → **superseded/done** (já absorvido em `kg-radar.sh:120-139`).

## Por que é o mesmo princípio, noutra superfície
É **aceitação-gated**, como a RFC-0004 (a2a só sob gate) e o merge_authority (produção de cliente =
consent do cliente): nada se impõe na superfície de quem tem a palavra final. Aqui a superfície é a
**doutrina do core**; o gate é o **trust + o maestro**. É a F4 **curada** — quando houver 3+ instâncias
com diários maduros, este ingestor curado generaliza para `/meta:synthesize-collective` (automático).

## Invariantes
- **Nunca absorver de quem não tem trust** para corrigir/aconselhar o core (fail-safe: ausência = não).
- **KG-backed sempre** (radar exit 0) — absorção que se contradiz não aterrissa.
- **Soberania**: doutrina/método viajam; código do adotante, não.
- **Human-gated** + `declarado≠verificado`.
