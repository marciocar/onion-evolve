---
title: 'Resíduo — as faixas da bancada no CI divididas por tempo medido (etapa A)'
date: 2026-10-07
branch: ci/selftest-lanes-by-time
reviewed_diff_sha256: db662eca8b03d2ca75509288272defd4184055bb55c52e8da9911cbc8339e65d
reviewed_code_sha256: 4984f4477617f6965f5738cd640d7a76598d7d816f52fa2a87007883d7daa333
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Priorizado pelo maestro (2026-10-07) como cura de CAUSA do tempo até o merge: no mesmo PR as faixas da bancada
  levaram 5/10/17/19 min, e a soma pedia ~11 por faixa. O plano (selftest-shard-plan.sh) distribuía em
  round-robin, cego ao custo. Etapa A: (1) o workflow imprime ⏱ por família (ONION_SELFTEST_TIMING=1);
  (2) coletor novo ops/testing/collect-family-times.sh lê esses ⏱ do log de um run e emite a tabela
  familia<TAB>segundos — a régua é o runner de 2 núcleos, não a máquina local de 8; (3) o plano, quando a
  tabela existe, distribui por LPT guloso (o mais caro na faixa mais leve; família desconhecida entra com a
  mediana, nunca com zero); sem a tabela, o round-robin de sempre. Etapa B (próximo PR): gerar e versionar a
  tabela a partir do CI desta etapa — só então a divisão muda de verdade. Bancada: caso (f) da shard_plan — com
  uma tabela, a faixa mais pesada cai (4090 → 3800 nos tempos sintéticos) e a cobertura segue exata. Achado no
  caminho: o caso nasceu com o rótulo (e), já usado por outro caso da família; renomeado para (f). Mutante (o
  ramo por tempo desligado) morde: os planos empatam e o caso reprova. Sem Elenxo, declarado.
---

# Resíduo — `ci/selftest-lanes-by-time`

Teto: até a etapa B versionar a tabela, o CI segue em round-robin; esta etapa só passa a MEDIR.
