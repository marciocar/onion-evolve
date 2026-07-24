---
date: 2026-07-24
instance: onion-evolve
type: learning
classification: collective
tags: [vendorization, adopter-oracle, lint, catraca, fonte-vs-derivacao, gloss, sigpipe, fix-vira-mecanismo, pedro]
affects: [meta, engineering, federation]
breadcrumb_for: []
share_with: []
next_recommended: "Ao citar um artefato core-privado (docs/analysis, docs/onion, docs/evolution, .claude/diary) dentro de uma KB VENDORIZADA, nunca deixe um link vivo — vira texto simples + um gloss que carrega a DIMENSÃO real do artefato. A REGRA 45 (kb-vendored-link-check.sh) reprova o link novo com catraca; o baseline (101 hoje) é dívida a migrar, e a métrica de saúde é ele DIMINUINDO. Quando construir um selftest que faz `child | grep -q`, capture a saída numa VAR primeiro (out=$(child)); sob set -o pipefail o grep -q fecha a pipe no 1º match e o child morre de SIGPIPE(141), fazendo a pipe reportar falso."
review_after: 2026-10-22
conflict_class: static
significance: "O lint do core NÃO via um bug que quebrava o adotante: um link vivo de KB vendorizada para caminho core-privado resolve no core (o arquivo existe aqui) e passa — mas 404 no adotante. Só o lint DENTRO do repo do Pedro pegou. Escopo real: 101 links assim em 33 KBs, latentes. Virou REGRA 45 (guard core-side com catraca) + a convenção do gloss — mecanismo, não memória."
---

## Signal
**O adotante é o oráculo que o core não enxerga.** Uma KB vendorizada que cita um ADR por link relativo
(`](../../analysis/…)`) resolve no core — o arquivo existe aqui, o lint passa. No adotante esse caminho é
**ausente-por-desenho** (`docs/analysis`, `docs/onion`, `docs/evolution`, `.claude/diary` não vendorizam): o
link é **morto**. O core, sendo `role:source`, é estruturalmente **cego** a essa classe de bug — ele só se
revela onde a cópia roda. Foi o lint DENTRO do `onion-pedro` que reprovou (um link para `.claude/diary`); o do
core deixara passar. Não é um link torto isolado: são **101 links em 33 KBs**, latentes.

## O que virou mecanismo (fix-vira-mecanismo, não one-off)
- **REGRA 45** (`kb-vendored-link-check.sh`) — guard **core-side** que mecaniza "o adotante é o oráculo": o
  core passa a checar a perspectiva do adotante. Catraca idêntica à REGRA 29 (passivo baselined = SOFT; link
  novo = HARD; baseline só encolhe). O `_scan_relative_links` já *tolerava* esses links no adotante (pulava os
  "ausente-por-desenho"); tolerar o **lint** não conserta a **experiência** — o guard força a conversão.
- **A convenção do gloss** — link vivo → texto simples + um gloss que carrega a **dimensão real** do artefato
  (o que decide/prova, por que importa). Preserva `fonte≠derivação` (não recopia) E o valor pro adotante que
  não pode clicar. Doutrina em `graduated-automation-ladder.md` §Convenção; o guard aponta pra ela.

## A armadilha do selftest (reusável, e eu re-caí nela)
Construindo o selftest do guard, 3/6 casos falsos-falharam: o child produzia o HARD (o debug provou), mas
`child | grep -q "^HARD"` sob `set -o pipefail` reportava falso. Causa: `grep -q` sai no 1º match e **fecha a
pipe**; o child morre de **SIGPIPE(141)** na próxima escrita; com pipefail a pipe herda o 141 → o `if` vê
falso. **O cabeçalho do `kg-provenance-coverage.sh` já documenta exatamente isso** ("head morre de SIGPIPE") —
e eu re-caí. Fix: `out="$(child)"; printf '%s' "$out" | grep -q …` — capturar em var deixa o child terminar.
Lição meta: um gotcha documentado num arquivo não me imuniza; o mecanismo (o selftest que expôs) é que pega.

## Por que importa pra rede
Todo adotante regulado (Pedro/Aura, granaai) lê essas KBs. Um link morto numa KB de compliance é pior que
ruído: sugere uma fonte auditável que não existe do lado deles. O guard fecha isso na origem, antes de embarcar.
