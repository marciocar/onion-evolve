---
reviewed_diff_sha256: 25e783e715ef6ec2102a8d17163e43e36724a00764cc36af4b6acdd612542c53
findings_total: 8
findings_real: 8
tokens: 107735
duration_min: 3
verdict: APROVADO
elenxo: sim
nota: >
  Elenxo opus em worktree isolada REPROVOU a 1a versão com três blockers, todos fail-open no pipeline
  e na bancada. Os três e os recommended foram curados aqui, e cada cura tem mutante que morde —
  inclusive os dois mutantes com que o refutador provou o caso decorativo. O verdict APROVADO é o
  estado depois das curas, não o veredito da passada.
---

# Resíduo — `feat/evolve-workflow-piece`

A peça 4 do `/meta:evolve`: o script que a rodada de 2026-10-04 autorou inline virou
`.claude/workflows/evolve.js`, e o Passo 3 da superfície deixou de ser JS que não rodava.

## O que o refutador derrubou

1. **BLOCKER — juiz nulo virava sobrevivente silencioso**, e o log ainda o contava como
   "verificado". **Curado**: `unjudged` é campo de 1ª classe; o log conta só vereditos não-nulos.
2. **BLOCKER — dimensão cujo worker lançava sumia** de todos os campos, sem log. **Curado**: `lost` =
   o que devia rodar e não voltou, com log.
3. **BLOCKER — o caso (d) era decorativo**: passava com `survived = all` e com correlação por índice,
   porque o stub refutava o índice 0. **Curado**: o stub refuta o índice 1 e o caso exige igualdade
   exata; casos novos (e) juiz nulo, (f) scan que lança, (g) entrada e schema.
4. **recommended — "superconjunto dos gatilhos" era falso**: um `opportunistic` que propusesse fundir
   fases escapava do veto. **Curado**: o script julga todo achado que toque `engineer/`, `product/`,
   fusão ou consolidação, qualquer que seja a severidade.
5. **recommended — o Passo 3.2 era só prosa.** **Curado**: virou conferência explícita do contexto
   principal sobre `dims`/`skipped`/`lost`/Passo 2.5.
6. **recommended — `FindingSchema` pendurado** na tabela do Passo 2.5. **Curado** (aponta o `FINDINGS`).
7. **recommended — `args` como string rodava TUDO** (12 agentes em vez de 2). **Curado**: string é
   parseada; não-objeto e `cap` fora de 1..30 recusam.
8. **opportunistic** — `d1` minúsculo, `Skill` fora do `allowed-tools`, `Agent` sem schema no
   fallback. **Curados**.

## Mutantes (6/6 mordem)

`survived = all` · correlação por índice · juiz nulo vira sobrevivente · `lost` apagado · `args`
string ignorado · sem normalizar caixa.

## O que não foi verificado

O runtime real de `Workflow` (se `agent()` devolve nulo ou lança na falha): os dois caminhos estão
cobertos. Nenhuma rodada com tokens foi feita depois da cura.
