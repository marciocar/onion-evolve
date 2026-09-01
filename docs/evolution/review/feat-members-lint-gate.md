---
title: "Revisão — M2 da federação: members.yaml no gate (REGRA 66)"
date: 2026-09-01
branch: feat/members-lint-gate
reviewer: "bancada 3/3 (vivo passa · inválido HARD com rc · rota validador-ausente fail-loud); costura SDAAL ONION_MEMBERS_FILE para testabilidade; core-only por dado (adotante sem o yaml = silêncio); registry regenerado (66 em Federação)"
reviewed_diff_sha256: 9333a80a87fd97ba786e662482188b24e48bcaea2ea88e05856b54b678c1f48e
findings_total: 2
findings_real: 2
verdict: APROVADO
tokens: 0
duration_min: 15
---

# Resíduo — REGRA 56

## 2ª rodada (dogfood do CI): a 66 disparava dentro de sandboxes da bancada

A família outbox fabrica members.yaml (append ao real copiado) e a 66 reprovava a fixture citando
o id sintético. Cura em 2 camadas: marcador do registro real (1ª linha) + core-only pelo PAPEL
(.claude/.onion-version presente ⇒ silêncio — sandboxes se declaram adotante). Re-dogfood: 12/12
nas duas famílias.

I_MEMBERS_NO_LINT_VIVO (Onda 7): fecha Q_members_ci_gate — o validador do OP-1 (PR #697) deixa
de depender de invocação manual; membro quebrado reprova o gate.

## Colheita herdada da stack (registro canônico no resíduo da Onda 7, PR #743)

Ids (para a guarda): W6_CARTEIRA_MAESTRO_VIVO E_SELO_POR_ATO_REGISTRADO I_PROVA_PRETOOLUSE
I_BENCHMARK_DO_GATE I_PECA_CATRACA I_RADAR_SURFACE I_HERO_PELO_MECANISMO
