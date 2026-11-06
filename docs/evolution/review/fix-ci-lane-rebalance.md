---
title: 'Resíduo — a bancada volta a caber no teto: tabela re-medida e 5 faixas (conserto da issue #1488)'
date: 2026-11-06
branch: fix/ci-lane-rebalance
reviewer: "condutor, passada adversarial própria (sem agente, por ordem da sessão principal): logs dos jobs dos runs 42063417161 (verde) e 42146679343 (faixa 3 cancelada) lidos por gh api .../jobs/<id>/logs; plano projetado em N=4/5/6; shard_plan 8/0; mutantes N=4 e tabela velha rodados"
reviewed_diff_sha256: e4e874b8187f961833bbf276e51b01608eda16cc022c1c4d42fbf0310938d682
reviewed_code_sha256: 96ff8e65b75732848e8ca09b60e5dc3ad1252e49b328075ace8ea2efd6d4d9b1
findings_total: 3
findings_real: 3
findings_fixed: 1
tokens: 0
duration_min: 60
verdict: CORRIGIDO
elenxo: nao
---

# Resíduo — `fix/ci-lane-rebalance`

## Causa medida

- Run verde 42063417161 (main, 2026-11-05): faixas de 20m37s, 20m44s, 14m53s e 12m37s; soma dos `⏱`
  por faixa 4417 / 4459 / 2843 / 2695 s (4 workers por faixa).
- Run 42146679343 (824c5cb85): faixa 3 cancelada aos 25m19s, sem nenhuma linha `⏱` no log (o pai só
  imprime no fim); faixas 1/2/4 em 19m29s, 15m29s e 14m08s.
- A tabela `ops/testing/selftest-family-times.tsv` era de 2026-10-12: 89 das 310 famílias não estavam
  nela e entravam pela mediana, que era 1 s — 4618 s invisíveis ao LPT (`selftest_selection` 674 s,
  `selector_per_file` 380, `stt_service` 372, `chat_runner` 332). `selftest_lanes` dizia 144 s contra
  555 medidos.

## Achados da passada adversarial

1. **Só rebalancear não dá folga** (corrigido pela escolha de N). Com a tabela nova em 4 faixas, a
   projeção (soma/W + fixtures/(N·W) + arranque, calibrada no run verde) dá 1076 s ≈ 18 min na pior
   faixa, e a variância medida entre dois runs da mesma faixa foi de +22%. Em 5 faixas: 887 s ≈ 15 min.
2. **O caso (h) não detecta tabela velha** (teto declarado, não curado). Com a tabela de 10-12 e N=5 ele
   projeta 9,4 min e passa: a tabela velha subestima. Quem pega a defasagem continua sendo o tempo
   real do CI; re-medir é `collect-family-times.sh <run>`.
3. **Constantes do caso (h) envelhecem** (teto declarado): W=4, fixtures_total=3766 s e arranque=130 s
   vêm do run verde de 2026-11-05 e estão citadas no comentário do caso.

## Mutantes

- `selftest-shard-plan.sh 4` no workflow (via `ONION_SHARD_WORKFLOW_UNDER_TEST`): (h) reprova com
  "N=4 · pior faixa 1076 s (17.9 min) · orçamento 1000 s".
- Tabela de 2026-10-12 com N=5: (h) passa (achado 2).

## Não mudou

- O teto (`timeout-minutes: 25`) não subiu. A tabela é o máximo por família entre os dois runs;
  `act_signature` não tem medida e entra pela mediana nova.
