---
title: "Revisao — cura do --update (REMOVIDO × baseline do core)"
date: 2026-08-24
branch: fix/adopt-update-baseline-removido
reviewer: "branch-code-reviewer (passada adversarial, 4 hipoteses de defeito) + dogfood real no clone da granaai"
reviewed_diff_sha256: fdb015b94be5331779cb65d6788824141d4be1c5f367ba377e8b41a19785f5ac
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 121000
duration_min: 15
---

# Residuo de revisao — REGRA 56 (cura de maquinaria delicada: adopt × catraca)

Cura do bug que a granaai (adotante regulado) achou: o `--update` trazia o baseline de catraca do CORE
(chaves de grafos core-only) ao adotante via merge do onion/vendor → `REMOVIDO` HARD sobre nos que ele
nunca teve. Toca `vendor-branch.sh` (a cura), `lint-selftest.sh` (o selftest) e o grafo catraca-regra49.

## A passada adversarial (branch-code-reviewer) — veredito 🟡, sem bug critico bloqueante

O revisor atacou 4 hipoteses + a de "reinjecao do veneno"; nenhuma se sustentou como bug funcional. Mas
levantou 3 ressalvas REAIS — todas verificadas por mim (dogfood, nao aceitas por confianca):

- **M1 (rationale falso no SSOT) — CORRIGIDO.** Minha 1a redacao dizia "o vendor NUNCA carrega baseline
  do core". Medi o campo: poc(47)/gustavo(48) JA carregam (contaminados por updates pre-cura). A cura
  funciona por outro mecanismo — RESETA o baseline do vendor ao proprio HEAD (o merge 3-way toma *ours*).
  Comentario e grafo reescritos para a verdade medida.
- **M3 (fixture nao batia nenhum estado de campo; granaai=no-op) — VERIFICADO E CURA ESTENDIDA.** O
  revisor apontou que a 1a cura (`git checkout`) so cobria o estado com baseline RASTREADO no vendor; para
  o adotante PRE-catraca (granaai/arandek, vendor SEM baseline) era NO-OP. **Reproduzi (RED), confirmei no
  clone real da granaai, e estendi a cura** (remove o untracked que o tar-x traz). O selftest agora tem 3
  casos (A/GREEN, B/GREEN, RED/MUT que remove o bloco entre marcadores e contamina os dois estados).
- **M2 (veneno congelado nos vendors ja contaminados) — RASTREADO como follow-up.** poc/gustavo mantem as
  chaves estrangeiras congeladas inertes (vendor==merge-base). A cura nao as remove, so impede de avancar.
  Scrub = D_SCRUB_FROZEN_POISON_IN_VENDORS no grafo, gated ate a equivalencia quebrar.

## Achado do dogfood real (materializado no grafo)

A granaai ja falhava `NO-BASELINE` ANTES de qualquer update (estado pre-catraca, sem baseline proprio) —
bloqueio SEPARADO da contaminacao, independente do `--update`. A contaminacao esta curada; o NO-BASELINE
e outro fio (D_ADOPT_MUST_EMIT_MISSING_BASELINES, gated).

## Provas por comportamento
- Reproducao isolada (helpers reais): SEM cura → REMOVIDO HARD:1; COM → 0.
- `run_vendor_baseline_removido_selftests`: 3/3 (A/GREEN + B/GREEN + RED/MUT load-bearing).
- Dogfood REAL num clone descartavel da granaai: update curado → vendor 0 chaves estrangeiras, develop sem
  baseline do core. (Nunca toquei o repo real da granaai.)
- `lint-artifacts` 0 HARD, `kg-radar` exit 0.

**Veredito: APROVADO** — a cura fecha o RED nos dois estados de campo, a bancada guarda o RED/MUT contra
recorrencia silenciosa, o SSOT foi corrigido, e os fios remanescentes (M2, NO-BASELINE) estao rastreados
com gatilho nomeado no grafo. A guarda critica da catraca nao foi tocada.
