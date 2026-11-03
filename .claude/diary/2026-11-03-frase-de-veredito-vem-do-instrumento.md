---
date: 2026-11-03
instance: onion-evolve
type: error
classification: collective
tags: [synthesis, agregador, declarado-vs-verificado, braco-real]
affects: [meta]
breadcrumb_for: []
share_with: [onion-curation]
next_recommended: "Toda frase de veredito de uma SYNTHESIS cita o campo do agregado que a produz; comparação feita à mão diz que foi à mão e com quantas células."
review_after: 2027-02-01
conflict_class: static
significance: "Escrevi 'o braço real confirma o stub, sem divergência' com divergences vazio, mas o agregador não pareava entre lotes: o vazio era ausência, não concordância."
kg: docs/evolution/research/port-spikes-qwen-vibe-2026-11/port-spikes-qwen-vibe-2026-11.kg.yaml
---

## Signal
**Lista vazia do instrumento não é concordância quando o instrumento não consegue formar o par.**

## Evidence
O stub rodou no lote `m1` e o modelo real no `real1`; a chave da divergência incluía o lote (achado A1 da curadoria).
A comparação célula a célula feita à mão concordava (RS0 FURA = S0 FURA, RS1 BARRA = S1 BARRA), mas a SYNTHESIS e o
commit a apresentavam como resultado do agregador. A cura tirou o lote da chave e criou o teste com lotes diferentes.
