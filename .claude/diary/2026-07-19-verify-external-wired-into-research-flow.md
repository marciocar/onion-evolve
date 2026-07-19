---
date: 2026-07-19
instance: onion-evolve
type: learning
classification: collective
tags: [verify-external, research-flow, wire-in, forcing-function, gated-opened, webfetch-gap]
affects: [meta, research]
breadcrumb_for: [verify-external-for-current-doctrine]
share_with: [granaai, metagamify]
next_recommended: "Nenhum obrigatório. Opcional: quando /meta:orchestrate ganhar um passo de pesquisa próprio (hoje delega à skill), reavaliar se a afordância precisa de superfície ali — por ora a delegação do Passo 2 cobre."
review_after: 2026-10-19
conflict_class: static
---

## Signal
**Ato-2 FECHADO** — o gate foi aberto pelo maestro ("pegar o fio") e a forcing function da KB
`verify-external-for-current` foi cabeada no fluxo de pesquisa vivo, derivada **fresca** contra o artefato
(não pré-cozinhada; `gated-work-derives-fresh`). Decisão de escopo do wire-in: **2 superfícies, não 3** —
o `@research-agent` (executor) e a skill `onion-orchestration` (doutrina de orquestração). **`/meta:orchestrate`
ficou de fora de propósito**: o Passo 2 já delega seleção de padrão/elegibilidade à skill, então cabear a
skill cobre o caminho de fan-out do comando — as 3 cópias seriam o mesmo conceito repetido, exatamente o que
a refutação do item6 (Doutrina de Modernização) veta.

## Evidence
- **Gap concreto revelado pela fiação:** o `@research-agent` listava só `WebSearch` nos tools — o **fallback
  `WebFetch` da KB era literalmente impossível** para ele. Adicionar `WebFetch` aos tools foi o mecanismo
  (não prosa) — `.claude/agents/research/research-agent.md` frontmatter + Fase 3 (Regra dura, ponteiro à KB).
- Skill: 1 bullet na Resiliência, **mesma forma** do gotcha `verify-read-path-first` (claim de classe X exige
  fonte verificada antes de virar nó confirmado) — `.claude/skills/onion-orchestration/SKILL.md:179`.
- Gate mecânico (dogfood real): `lint-artifacts.sh` pegou o plugin `onion-work-tools` fora de sync (a skill
  é espelhada no bundle) → regenerado via `assemble-plugin.sh` → **0/0**.
- Doutrina-âncora: `docs/knowledge-base/concepts/verify-external-for-current.md` (mergeada em #449).

## Next crumb
A doutrina agora tem as **duas pernas**: KB durável (o quê/porquê, #449) + wire-in mecânico (o como, este PR).
Ao tocar o fluxo de pesquisa de novo: a afordância vive no `@research-agent` (Fase 3) e na skill (Resiliência);
não re-declarar em outros arquivos que delegam a esses dois. Se um comando de research ganhar caminho próprio
(sem delegar à skill), aí sim reavaliar superfície — mas por default a delegação já cobre.
