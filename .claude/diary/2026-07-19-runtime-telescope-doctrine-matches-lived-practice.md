---
date: 2026-07-19
instance: onion-evolve
type: observation
classification: collective
tags: [autonomous-runtime, telescope, dogfood, gate-evidence, declarado-verificado]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "Evidência p/ os gates: o checkpoint da Fase 2 do runtime autônomo pode citar esta rodada como dogfood de prática-vivida. O gate do telescópio segue aberto — o '1 dogfood de RECALL estrito' (reidentificar invariantes só pelo nome) NÃO foi cumprido aqui (a doutrina foi apontada pelo KG, não recuperada do nome)."
review_after: 2026-10-15
conflict_class: static
---

## Signal
Um estudo (discuss/onion-pessoal-app) leu os dois ADRs gated — Telescópio e Runtime de orquestração
autônoma — e observou: **descrevem fielmente o que a sessão-core viveu nesta rodada.** Doutrina batendo
com prática, não à frente dela.

## Evidence (arco verificável no git/PRs)
- Nível 0/AUDIT o tempo todo: fios até PR verde em worktree própria (#435, SEEDs da Constelação, #437),
  re-dogfood antes/depois; gated proposto e NUNCA executado; I3 respeitado (survey read-only, sem escrita
  alheia); merge no main sempre human-gated ("mergeia o 435").
- Telescópio aplicado num caso real: "veja a tela da sessão X" → LOCAL-ONLY honrado (reportei "sem alvo"
  em vez de fabricar) + observar≠comunicar (ação voltou por comentário no PR, não injetada).

## Fronteira honesta (declarado ≠ verificado sobre esta própria evidência)
Isto é doutrina-APLICADA-em-campo (evidência p/ o checkpoint da Fase 2 do runtime). NÃO é o "1 dogfood de
recall" ESTRITO do telescópio (reidentificar só pelo nome) — a doutrina foi lida/apontada pelo KG. Esse
teste mais duro segue aberto; não conto como cumprido.

## Next crumb
Surfaced por um estudo, mas é aprendizado do FRAMEWORK → mora aqui (diário coletivo), não no contexto do
app pessoal (absorver doutrina gated downstream seria pular o gate + MOAT). Ver [[self-reinforcing-radar-loop]].
