---
date: 2026-07-18
instance: onion-evolve
type: innovation
classification: collective
tags: [write-kg, ssot-as-runtime, orchestration, bookend, kg-first, persistence]
affects: [meta, orchestration]
breadcrumb_for: []
share_with: [granaai, metagamify, marcio-pessoal]
next_recommended: ""
review_after: 2026-10-15
conflict_class: static
---

## Signal
O ciclo `read(KG)→verify→act→write(KG)` (SSOT-as-runtime) tinha o leg **`write(KG)` aberto**: skills do harness (ex.: `deep-research`) despejam a síntese no `/tmp` efêmero e **não persistem** — o `write` dependia de o agente **lembrar**. Fechado como o **bookend simétrico** do `read(KG)` (que já era passo 0 em `warm-up`/`catch-up`/`engineer:work`): toda orquestração que **produz conhecimento** fecha persistindo a síntese no repo (`docs/**/research/*.md`) **e** materializando o `.kg.yaml` via `/meta:kg` + `kg-radar` (exit 0). **Mecanismo, não conselho** — "advice-que-depende-de-lembrar" falhou empiricamente (3 pesquisas perderam o write até o próprio maestro).

## Evidence
- Skill: `.claude/skills/onion-orchestration/SKILL.md` passo 7 (+ bullet de Resiliência). Comando: `.claude/commands/meta/orchestrate.md` `Passo 4.5` (v1.2.0).
- **Convergência com guard já existente:** a regra de lint "toda pesquisa nova nasce em KG" (doutrina 2026-07-17, era granaai) **é o guard mecânico** deste write(KG) — o CI reprovou até o `.kg.yaml` estar co-locado no dir da pesquisa.
- Dogfood no mesmo loop: a exploração 3-streams desta sessão foi persistida em `docs/evolution/research/doctrine-sync-ingestor-2026-07/` (SYNTHESIS.md + `.kg.yaml`, radar exit 0) em vez de morrer no contexto.
- Origem: sinal de campo do onion-pessoal `2026-07-18-deep-research-no-auto-kg-persist` (→ `_processed`). PR #421.

## Next crumb
Ao concluir qualquer pesquisa/auditoria orquestrada: **antes do relatório**, persista a síntese em `docs/**/research/*.md` + materialize o `.kg.yaml` co-locado (radar exit 0) e **nomeie o path**. Se veio do harness (`deep-research`), o output está no `/tmp` e **drifta** — a orquestração Onion é dona do `write(KG)`. "Esqueci de salvar" é o modo-de-falha que o KG-first mata.
