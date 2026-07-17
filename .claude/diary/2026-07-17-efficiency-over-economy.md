---
date: 2026-07-17
instance: onion-evolve
type: decision
classification: public
tags: [tiering, orchestration, dogfood, cost]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-10-15
conflict_class: static
---

## Signal
Diretiva do maestro (verbatim): **"Não queremos economia, queremos eficiência e eficácia!"** A régua ao orquestrar **não é custo** — é a doutrina de **tiering** (model+effort por fase). Nunca propor a alternativa barata como default nem justificar escolha por "economiza tokens".

## Evidence
- Economia otimiza *gasto*; eficiência+eficácia otimizam **resultado por esforço bem gasto**. Cortar custo por reflexo mata o dogfood — o padrão master do Onion.
- Escala já provada no repo: runs de 8 a 107 agentes, 700k–2,7M tokens, 10–27 min.
- Tiering canônico (`.claude/skills/onion-orchestration/SKILL.md`, diretiva do maestro 2026-07-12): mecânico→`haiku/low` · médio→`sonnet/medium` · difícil/alto risco→`opus/high|xhigh`. Regra de bug: *"se uma fase difícil rodou barata ou uma mecânica rodou cara, é bug de tiering."*
- Gastar opus num juiz adversarial = eficácia; gastar opus numa varredura mecânica = bug.
- Par doutrinário: [[worst-truth-is-uncertain]] governa *o que aceitar como sabido*; esta governa *quanto gastar*.

## Next crumb
Ao orquestrar, sempre declarar `model` + `effort` por fase e **reportar o tier** — não pedir permissão para gastar. Fase difícil que rodou barata (ou mecânica que rodou cara) é sinal de bug de tiering a corrigir.
