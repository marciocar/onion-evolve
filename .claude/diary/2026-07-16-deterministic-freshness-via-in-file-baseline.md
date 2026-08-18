---
date: 2026-07-16
instance: onion-evolve
type: innovation
classification: public
tags: [kg-sdaal, freshness, determinism, gate-design, kg-radar, verified_at]
affects: [meta, engineering]
breadcrumb_for: [meta:kg, meta:evolve]
share_with: [rhilo-metagamify]
next_recommended: ""
review_after: 2026-10-14
conflict_class: static
---

## Innovation
Um gate de **frescor/staleness** determinístico **não precisa de "agora"**. Ao carimbar
`verified_at:` no nó e uma `baseline:` no `meta:` do próprio arquivo, o gate compara **duas datas
in-file** (`verified_at` × `baseline`) — 0% dependência de relógio, 100% reproduzível. Resolveu o
Q2 do ADR `[[onion-adr-kg-freshness-gate-2026-07]]` **melhor que o plano original**, que temia ter
de introduzir dependência de tempo (como o mail-hook, que compara `review_after` vs agora).

## Why it matters
"Frescor" parece exigir "hoje" — é o instinto errado. O que o STALE realmente pergunta é *"esta
foto foi tirada depois da última vez que o mundo mudou?"*. Se **a referência do mundo também mora no
artefato** (a `baseline`), a pergunta vira comparação de dois campos — determinística, testável por
fixture, sem `date`. O mesmo gate roda idêntico em CI, em replay, e daqui a um ano. STALE-MISSING
(carimbo ausente) é ainda mais barato: zero-knob, nem baseline precisa.

## How to apply
- Sempre que desenhar um gate de "isto está velho?": procure a **referência-de-mundo mais próxima
  que já esteja no artefato** (baseline, schema_version, commit) antes de reflexar para `now()`.
- Determinismo do gate > conveniência de "hoje automático". Um humano/CI atualiza a `baseline`
  quando roda um dump novo — esse ato é o que "move o mundo", e ele fica **git-visível**.
- Comparação de datas ISO `AAAA-MM-DD` é lexicográfica — string compare em awk basta (sem parse).
  Cuidado só com o footgun de tipo numérico (força string context; ver `[[knowledge-graph-sdaal]]`).

## Evidence
`kg-radar.sh --freshness` (PR #375): STALE-MISSING + STALE-OLD, ambos sem `date`. 5 selftests que
reagem (fixtures fresh/stale-missing/stale-old), 282/0. Dogfoodado contra grafo real do core
(`onion-identity` → exit 0, só avisos). Espelho de gate: `--schema` (drift de formato, ✗ recusa) —
mesma família "o radar recusa/avisa quando a SSOT driftou". Loop completo nesta sessão: sinal
`[[2026-07-16-kg-sdaal-dogfood-gold-backlog]]` → ADR → F1 (#375) → F2 (#376).
