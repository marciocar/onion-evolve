---
date: 2026-11-03
instance: onion-evolve
type: decision
classification: collective
tags: [pre-registro, reclassificacao, procedencia, emenda]
affects: [meta]
breadcrumb_for: []
share_with: [onion-curation, onion-kg-ssot]
next_recommended: "Qualquer mudança na função de veredito, ou no que o executor grava, aplicada a evidência já colhida põe a célula em INCONCLUSIVO e manda rodar de novo, para todas as células daquele executor; reclassificar acrescenta a linha de quem reclassificou, nunca sobrescreve a da coleta."
review_after: 2027-02-01
conflict_class: static
significance: "Separa consertar o instrumento de mudar o critério depois do dado — e o registro de quem classificou e quando passa a ser parte da evidência."
kg: docs/evolution/research/port-spikes-qwen-vibe-2026-11/port-spikes-qwen-vibe-2026-11.kg.yaml
---

## Signal
**Defeito do medidor anula o veredito já emitido; mudança de critério depois do dado é proibida. As duas coisas se
distinguem pelo registro.**

## Evidence
Emendas 1, 4 e 5 do pré-registro dos spikes: a regra veio da curadoria; a reclassificação das 120 células primeiro
sobrescreveu o classificador da coleta no `sha256.txt` (achado do kg-ssot) e depois passou a guardar os dois, com o
caso das 3 células cujo classificador da coleta não existe em commit nenhum declarado por escrito.
