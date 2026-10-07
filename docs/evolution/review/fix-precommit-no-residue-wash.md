---
title: 'Resíduo — o pre-commit não lava mais o resíduo da REGRA 56'
date: 2026-10-07
branch: fix/precommit-no-residue-wash
reviewed_diff_sha256: 5c7e8afac06f22e37beca54d29178146dc956706bb436e94c65d0693d90efe89
reviewed_code_sha256: c8a9135a7e80d9238811f5adbfbf8b8948e2580632439798ccf5b08875e5eda3
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 25
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Item 1 da fila-2026-10-06 (Q_PRECOMMIT_NAO_LAVA_RESIDUO, impacto 4), achado pela avaliação do pr-finalize e
  provado em sandbox: o pre-commit recarimbava reviewed_diff_sha256 sem conferir reviewed_code_sha256 — o B1
  que o motor curou seguia vivo no hook, e código mudado depois da revisão saía carimbado como revisado.
  Cura: (1) a identidade do código vira FONTE ÚNICA na onion-regen-lib.sh (ONION_GENERATED + onion_codehash),
  que o motor passa a usar; (2) a decisão de recarimbo vira onion_r56_restamp na lib, e o hook só a chama:
  `pendente` carimba o diff e o código, hash de código igual ao revisado recarimba só o diff (o caso legítimo:
  auto-fix mexeu só em projeções), qualquer outra coisa não toca e avisa. Bancada por EXECUÇÃO, sourçando a
  lib real num repo sandbox: caso (r56) da hook_regen_table com as três polaridades. Mutante (o ramo de recusa
  vira carimbo) morde ("mudado-lavou"). Achado no caminho: o motor carregava a lib pelo repo-alvo e quebrou
  4 casos da bancada pre_push (sandbox sem a lib) — agora carrega do lado do próprio motor e falha alto sem
  ela. Famílias pre_push + hook_regen_table: 40/0. O template de pre-commit do adotante não tem o bloco
  (0 ocorrências), logo a cura é core-only. Sem Elenxo, declarado.
---

# Resíduo — `fix/precommit-no-residue-wash`

Teto: resíduo antigo sem reviewed_code_sha256 não é mais recarimbado pelo hook — ele avisa e a REGRA 56 cobra
a re-revisão (é o comportamento pedido: não carimbar revisão que não houve).
