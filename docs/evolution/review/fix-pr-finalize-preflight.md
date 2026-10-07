---
title: 'Resíduo — pré-voo do pr-finalize no ambiente do runner'
date: 2026-10-07
branch: fix/pr-finalize-preflight
reviewed_diff_sha256: d0581d1d5b9876ac44ee968e8fdc768a5804c044485d13898a912696e1b3ebcd
reviewed_code_sha256: 1326ab27ac4f28109e46aedc94b1edf5236e74765a19fda9b039c09851f6104f
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 25
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Item 2 priorizado pelo maestro (2026-10-07) como cura de CAUSA: sob checkpoint o motor só lintava e a bancada
  ficava para o CI, e três PRs num dia quebraram lá por casos NOVOS que passavam local (identidade git ausente no
  runner no #943, duas vezes; `[ ] && echo` devolvendo 1 sem a variável no #944; sítio novo da catraca no #936).
  Cura: (1) helper ops/testing/preflight-families.sh — as famílias que o diff STAGEADO alterou por dentro (linhas
  do lado + mapeadas à run_*_selftests que as contém), sempre somando a catraca shell_pipefail_robustness; o mapa
  --affected-staged não serve aqui porque mexer no lint-selftest.sh cai no failsafe das 217. (2) O motor, sob
  checkpoint, roda essas famílias ANTES de commitar num ambiente que imita o runner: env -i, HOME limpo com
  `user.useConfigOnly = true` (o git recusa adivinhar identidade, como no runner), GIT_CONFIG_NOSYSTEM, LC_ALL=C,
  sem ONION_*. Escape declarado: ONION_FINALIZE_SKIP_PREFLIGHT=1. DOGFOOD contra o defeito real: no commit
  63c465d5 (o #943 com o caso sem identidade) o ambiente deu "Author identity unknown" e a bancada ABORTOU igual
  ao CI; na versão curada eb3f6c34, 12/0. Bancada: família preflight_families — (a) acha a família alterada, soma
  a catraca e não acusa a intocada; (b) o motor chama o pré-voo com useConfigOnly. Sem Elenxo, declarado.
---

# Resíduo — `fix/pr-finalize-preflight`

Teto: o pré-voo cobre as famílias ALTERADAS; família intocada que quebra por mudança em outro arquivo (o caso do
#944, em que o lint abortava nas famílias de terceiros) segue só no CI. O ambiente imita identidade, HOME, locale e
variáveis — não os 2 núcleos do runner (corridas de concorrência seguem só no CI).
