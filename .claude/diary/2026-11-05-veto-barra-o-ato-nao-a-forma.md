---
date: 2026-11-05
instance: onion-evolve
type: learning
classification: public
tags: [guard, veto, moat, fail-closed]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Ao forjar veto novo, listar os caminhos que chegam ao mesmo ATO (script, comando direto, outra ferramenta) antes de escrever o padrão"
review_after: 2027-02-03
conflict_class: dynamic
significance: "O veto que casava a forma do comando deixava o ato passar por outro caminho; virar o alvo para o ato fechou a classe, não o caso."
---

## Signal
Um veto que casa a FORMA de um comando cobre só aquela forma. O mesmo ato (deploy, publicação, escrita na memória)
chega por outros caminhos. Veto se escreve contra o ato, e fecha (exit 2) quando a própria análise falha.

## Evidence
- PR #1492: o veto do MOAT passou a barrar o ato de deploy e de publicação, não só a forma do comando.
- PR #1480: python em modo isolado e vetos que fecham quando a análise falha (antes, análise quebrada = passa).
- PR #1491 e #1490: a escrita na memória do Claude Code e o plugin escrito em `.claude/skills` ganharam veto e varredura.
- PR #1496: os vetos passam a valer no adotante carimbado, não só no core.

## Next crumb
Re-testar com o artefato: para cada veto da REGRA 101, plantar o ato por um caminho que não seja o canônico e ver se
o veto reprova.
