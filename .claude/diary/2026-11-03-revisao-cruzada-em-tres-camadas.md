---
date: 2026-11-03
instance: onion-evolve
type: reflection
classification: collective
tags: [revisao-adversarial, pre-registro, sessoes-peer, orquestracao, procedencia]
affects: [meta, engineering]
breadcrumb_for: []
share_with: [onion-curation, onion-kg-ssot]
next_recommended: "Antes de qualquer célula valer, submeta a medida a três camadas de revisão por sessões diferentes: desenho (pré-registro), código (executor reclassificando a partir do git archive) e processo (procedência e quando cada veredito nasceu). Achado convergente entre revisores vem primeiro."
review_after: 2027-02-01
conflict_class: static
significance: "Mais de 60 achados reais pegos antes de qualquer veredito valer, em três artefatos num só dia; três dariam BARRA falso e um ligaria um gatilho por ausência."
kg: docs/evolution/research/port-spikes-qwen-vibe-2026-11/port-spikes-qwen-vibe-2026-11.kg.yaml
---

## Signal
**Revisão em três camadas por sessões diferentes pega o que uma camada só deixa passar.** O desenho fechou e o código
reprovou; o código fechou e o processo reprovou.

## Evidence
- Pré-registro dos spikes: v1 reprovada (BARRA sem prova de disparo, modo padrão recusando antes do hook, push que não
  discriminava), v2 reprovada (stub decidindo pela ordem das chamadas), v3 fechada com 5 emendas.
- Executor: o kg-ssot, reclassificando a partir do `git archive`, achou que o `*.log` do `.gitignore` da raiz tirava
  toda a prova do commit; depois, o hook certo conferido depois do efeito; depois, veredito criado depois do dado e
  procedência sobrescrita.
- Comandos do vigia: a curadoria (dona do PLAN-E) achou em cinco passadas a lacuna fechada por qualquer linha, o
  mode_change no futuro descartado em silêncio e um remetente apagando o evento de outro.

## Why it matters
Uma passada só, ou revisores que leem a mesma camada, não pegam a classe seguinte. O padrão vale como mecanismo de
orquestração entre sessões (estudo `session-orchestration-2026-11`).
