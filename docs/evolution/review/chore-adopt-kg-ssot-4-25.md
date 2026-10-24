---
branch: chore/adopt-kg-ssot-4-25
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: 3b746ed6e41dad4bd041aea3c336f57c86844b0eab4fca73bd7640e378f35ad2
reviewed_code_sha256: a463f795bb4938d50f8ce3a61a7ba555a3e46876d71c79eeb2b5326440ac0ec2
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 35
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: "agente de execução da sessão (claude-opus-5-5), passada própria com mutantes"
nota: "tokens não medidos; o achado é o wrapper que não passava --allow-unreleased, curado neste PR"
---

# Passada adversarial: `chore/adopt-kg-ssot-4-25`

## O que muda

- `vendor/kg-ssot` 4.23.0 → 4.25.0 (`b5582deee07e`, 627 arquivos) pelo `kg_vendor.py update --tag`, `check` rc 0.
  Entram o `update --ref` com o carimbo `unreleased` (4.24.0) e o `kg_trace.py` com `spec/trace.schema.json`
  (4.25.0). Contrato v4.14, sem mudança: o gate não pediu `--update`.
- `ops/kg-gate-ci.sh`: `KG_ALLOW_UNRELEASED` passa `--allow-unreleased` ao check do vendor E ao `kg_gate.py`; com
  `CI` no ambiente a variável sai rc 2.
- `lint-selftest.sh`: família nova `kg_gate_ci` (6 casos).
- Nó `E_KG_SSOT_425_ADOTADA_1024` em `sinais-de-campo-2026-09.kg.yaml`.

## Achados

1. (real, curado) O wrapper rodava `kg_vendor.py check` sem flag e mandava os args só ao `kg_gate.py`: com um vendor de
   `update --ref` a bancada pré-tag reprovava no check antes de chegar ao gate, e não havia como passar a flag.

Gate antes e depois: saída idêntica, fora a linha do carimbo (4.23.0 → 4.25.0); rc 0 nos dois, sem `--update`.

## Mutantes

- Vendor real de `update --ref` (o commit da 4.25.0 de `kg-ssot`) no próprio worktree: sem a variável rc 1
  (`UNRELEASED VENDOR`), com ela rc 0, com `CI=true` rc 2; depois `update --tag` restaurou e o `check` deu rc 0.
- Mutante (e) da família: a variável tirada da linha do `kg_gate.py` → o gate recusa a bancada (rc 1), o caso morre.
- Mutante à mão: a variável tirada do check → o caso (c) reprova (rc 1, `UNRELEASED VENDOR`).

## Limites declarados

- Qualquer valor não vazio liga a variável (`KG_ALLOW_UNRELEASED=0` também liga), como a forma `${VAR:+...}` pede.
- A recusa no CI lê `CI`, que o GitHub Actions define; um runner que não o defina não é pego por esta linha (a
  família confere, à parte, que nenhum workflow define a variável).
- O `kg_trace.py` só entra no vendor; trocar o resolvedor da REGRA 55 é o PR seguinte.
