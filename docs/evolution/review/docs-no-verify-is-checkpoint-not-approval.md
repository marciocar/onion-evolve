---
title: "Revisão — --no-verify é checkpoint, nunca validação final (migalha do reforço do maestro)"
date: 2026-09-02
branch: docs/no-verify-is-checkpoint-not-approval
reviewer: "condutor com gate executado: pre-commit COMPLETO (lint-artifacts + bancada) rodou no commit 89f7e496 sem --no-verify, 0 HARD / 5 SOFT pré-existentes; diary-index.sh rc=0 e index.md regenerado; a migalha aponta a memória local reescrita no mesmo movimento"
reviewed_diff_sha256: 10838752e8b90f4df79d133b0017a4c7d520038b7b6c409cd146d685aef5c405
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 18000
duration_min: 8
---

# Resíduo — REGRA 56

Migalha `error` que absorve o reforço do maestro de 2026-09-02: o pulo do pre-commit é checkpoint de
trabalho incompleto, nunca a validação que aprova. Este PR é o primeiro a aplicar a regra a si mesmo:
o commit passou pelo pre-commit inteiro e este resíduo nomeia esse gate como o validador do SHA.

## Achados

1. **O buraco era narrativo, não mecânico** — `ops/pr-merge-verified.sh` já exige CI verde no head;
   o que falhou no PR #765 foi o relatório apresentar o `--no-verify` como validação. A cura é
   doutrina (migalha + memória) e a convenção de relatório "validado por: <gate> no SHA <x>".

## Não mudou

- Nenhum hook/guarda novo: o mecanismo de aprovação existente é o correto; adicionar guarda ao
  `--no-verify` em feature branch quebraria o uso legítimo (checkpoint).
- Baselines/SOFTs pré-existentes (kg-verificacao, REGRA 65 cc_version, link-vendorizado) intocados.
