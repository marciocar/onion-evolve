---
date: 2026-07-18
instance: onion-evolve
type: decision
classification: collective
tags: [breadcrumb, estigmergia, absorcao, proveniencia, trilha, ssot-runtime, taxonomia]
affects: [meta, transformer]
breadcrumb_for: []
share_with: [granaai, metagamify]
next_recommended: "Trilha-no-KG é aspiração não-construída: se um dogfood provar a falta, propor uma aresta/campo forward (NEXT/next_recommended no nó) — não inventar antes (dogfood-gated)."
review_after: 2026-10-15
conflict_class: static
---

## Signal
**Breadcrumb não é um conceito só — são 3 GÊNEROS por DIREÇÃO do sinal, sob a família "migalhas".** ① **Absorção**
(presente — sinal no artefato que força o modelo a ler certo agora; anti-acomodação) · ② **Proveniência** (aponta
pra TRÁS — âncora à fonte: o campo de rastreio do `.kg.yaml`, `TRACES_TO`, `origin:`) · ③ **Trilha** (aponta pra
FRENTE — marca deixada pra a próxima sessão: `next_recommended` do diário, o **ato** `write(KG)`). **Estigmergia**
(Grassé 1959, reaplicada a agentes 2026) é a **propriedade** de ② dos ③ (Absorção+Trilha), **não** o nome da família
— Proveniência cita passado fixo, não é estigmérgica. A **validade/frescor** (`conflict_class`/`review_after`) é
**modificador transversal**, não um 4º gênero.

## Evidence
- Doutrina: KB `docs/knowledge-base/agentic-patterns/ai-strategies/breadcrumb-patterns.md` v2.0.0 (supersede o draft
  v1 só-Absorção). Grafo: `docs/evolution/research/breadcrumb-doctrine-2026-07/breadcrumb-doctrine.kg.yaml` (radar
  exit 0, `SUPERSEDES` do draft + da hipótese de 2 gêneros).
- **Decidido pelo padrão de validação** (orquestração 3 lentes → adversário: CONFIRMADO com 2 correções).
- **Correção factual (grep de 6 `.kg.yaml`):** o campo de rastreio é **Proveniência** (aponta pra fonte), **não**
  Trilha entre nós — a hipótese inicial estava errada. A trilha genuína no KG é o **ato** write(KG).
- **Amarra ao SSOT-as-runtime** (`read`=comer · `verify`=cheirar · `act`=andar · `write`=deixar) **escopada à Trilha**
  — generalizar aos 3 gêneros é overclaim. Trilha viva hoje é no **diário** (esta migalha é uma); no KG é aspiração.

## Next crumb
Ao modelar um `.kg.yaml`: distinga **Proveniência** (campo de rastreio → fonte, backward) de **Trilha** (próximo
passo, forward — que hoje vive no diário `next_recommended`, não no KG). **Migalha stale MENTE, não corrompe** — o
veredito é sempre *re-verificar*, nunca *recusar*; `review_after`/⏰ + `conflict_class` guardam contra seguir trilha
morta. A aresta/campo forward no KG é **dogfood-gated** — só construir quando um uso real provar a falta.
