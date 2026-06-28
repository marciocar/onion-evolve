---
title: 'ADR — Capability Contract: auto-descrição por componente + conformance tiers + injeção condicional (padrão de plugin Onion, descentralizado)'
date: 2026-06-27
type: adr
status: aceito
decision-scope: plugin-standard / self-description / conformance / context-engineering
supersedes: none
extends: onion-adr-exchange-unit-2026-06.md
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - onion-research-self-describing-components-2026-06.md (síntese SOTA + vocabulário + mapeamento)
  - onion-adr-exchange-unit-2026-06.md (vertical-skill como unidade de troca)
  - onion-adr-native-githooks-standard-2026-06.md (precedente: padrão que o core dogfooda)
  - ../sdaal/sdaal.md (SDAAL — a visão-de-dentro já existente; LLM=runtime)
  - ../../.claude/validation/lint-artifacts.sh (drift-guard REGRA 19; conformance REGRA 20)
---

# ADR — Capability Contract (auto-descrição + conformance + injeção condicional)

> **Status: ACEITO.** Operacionaliza, para o padrão de plugin, a visão "o componente sabe sobre si +
> orquestrador compõe + habilidades sob demanda + conformance". Protótipo no mesmo ciclo (design+compliance).

## Contexto

O maestro pediu **algo que valide e ajuste o padrão dos plugins** maximizando Transformer + SDAAL, sob a
ótica OOP "quem sabe responder sobre o objeto é o próprio objeto" (visão-de-dentro) somada à visão do
orquestrador, com **injeção de conhecimento pesado sob demanda**. A pesquisa
(`onion-research-self-describing-components-2026-06.md`) nomeou as técnicas (Progressive Disclosure / Context
Engineering · Information Expert + self-describing agents · self-/co-evolving agents + ACE · conformance
profiles Bronze/Silver/Gold) e mapeou que o Onion já tem o substrato; faltam deps explícitas, injeção
**condicional** e validação do artefato **contra a própria auto-descrição**.

## Decisão

1. **Cada componente (vertical/plugin primeiro) carrega um Capability Contract** — auto-descrição
   declarativa (a visão-de-dentro / Information Expert):
   - `provides` — capacidades que entrega.
   - `requires` — dependências (agentes/skills/KBs/env/templates) — o grafo hoje implícito.
   - `loads` — contexto **condicional sob-demanda** (`when <cond> → <recurso>`) — resolve o "tudo-ou-nada".
   - `conformance` — tier auto-reivindicado (`bronze|silver|gold`).
2. **A visão-de-fora é COMPOSTA dos contratos, não centralizada.** Como `inventory.md` é gerado de
   `inventory.sh`, o grafo de capacidades/roteamento é derivado dos contratos — nunca um registry mantido à mão.
3. **Conformance é validado pelo lint (REGRA 20), família do drift-guard:**
   - **Bronze** — campos mínimos (`provides`/`description`/`version`).
   - **Silver** — `requires` resolvem (existem no inventário/`.env.example`).
   - **Gold** — Silver + `loads` válido + proveniência/`tree_sha` em sincronia.
   - Reivindicar um tier sem cumpri-lo → violação **HARD**.
4. **Injeção condicional** = o `loads` alimenta o progressive disclosure seletivo (não carregar KB de provider
   inativo). O Transformer interpreta o contrato + os specs SDAAL (tese SDAAL: LLM=runtime, Markdown=bytecode).

## Por que descentralizado (rejeição explícita do registry central)

A frente de pesquisa interna sugeriu um **registry YAML central** (~600 linhas). **Rejeitado:** centraliza o
conhecimento para longe do componente — o oposto de *Information Expert* (a intuição do maestro) — e quebra o
princípio Onion de **SSOT gerada do filesystem**. O contrato vive **no componente**; a agregação é derivada.

## Consequências

- **+** Padrão único de auto-descrição validável; deps explícitas; injeção condicional; base p/ auto/co-evolução.
- **+** Reusa a maquinaria existente (manifesto → `assemble-plugin.sh` → `capability.json`; lint/drift-guard).
- **+** Tiers dão um caminho de maturação observável (bronze→gold) por componente.
- **−** Mais um artefato gerado por plugin (`capability.json`) — coberto pelo drift-guard.
- **−** Verticais command-based ainda dependem do progressive disclosure da plataforma p/ o `loads` agir;
  o ADR documenta o protocolo, a aplicação plena evolui com a plataforma.

## Protótipo (mesmo ciclo)

`CAPABILITY` (provides/requires/loads/conformance) nos manifestos `onion-design` e `onion-compliance` →
`assemble-plugin.sh` materializa `capability.json` → `check_capability_conformance` (REGRA 20, Bronze/Silver/
Gold) + guardas no selftest → dogfood adversarial. Evidência ao fim deste ADR quando fechar.

## Não-decisões (gated — o contrato é o substrato)

- Registry central (rejeitado). · Auto-healing / auto-routing dinâmico / version-pinning semântico / lint
  multi-repo herdado / runtime introspection profunda — follow-ups habilitados pelo contrato, gated por apetite.
- Expansão do contrato a TODOS os agents/skills/commands — gated (o protótipo prova nas 2 verticais primeiro).
