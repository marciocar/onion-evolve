---
branch: chore/kg-ssot-v4.3.5
date: 2026-10-12
reviewed_diff_sha256: b48bb3b198a544c1a67ceded95fd180e3429174957a04b00b371f64fd5aa55c5
reviewed_code_sha256: 084357f64c9333c1d215ec8d13c6a54a83dae1ad71426d9a297860ccfeacc6b9
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: APROVADO
reviewer: passada própria (sem subagente) — gate mecânico: kg_vendor check, kg_gate do CI, famílias kg_contract_check, kg_radar_contract, vendor_pin, kb_vendored_link
---

# O core adota a kg-ssot-v4.3.5, pulando a 4.3.4

## O que muda

O vendor saiu da 4.3.3 (c32e6496be74), passou pela 4.3.4 e chegou à 4.3.5 (68648840dbe0). Foram de 298 para
309 arquivos. As duas tags só mudaram superfície: o manual do produto (`docs/manual`, 10 capítulos) e o
README entraram na release, e o `ADOPTING.md`, o `NOTICE` e o `spec/release.json` foram atualizados.

## O que foi conferido (e por que a passada não acha nada)

- O sha256 dos schemas MUST e SHOULD, do `kg_gate.py` e do `kg_validate.py` é **idêntico** ao da 4.3.3.
  O que julga o corpus não mudou.
- O `kg_vendor.py check` saiu íntegro. O `kg_gate` com os `--exclude` do CI saiu rc 0, com a mesma dívida
  SHOULD do main (`yaml.unquoted-date` 58).
- O `lint-artifacts.sh` deu 0 HARD com o vendor novo no índice. O manual vendorizado não disparou nenhuma
  guarda de superfície.
- As famílias kg_contract_check, kg_radar_contract, vendor_pin e kb_vendored_link passaram 35/0.
- O nó `E_CONTRATO_V43_ADOTADO` ganhou a medição e o `verified_at` novo. O radar e o kg-contract-check
  sairam rc 0.

## O que NÃO cobre

- O conteúdo do manual não foi revisado aqui. Ele é do dono do kit, que fez a passada dele (PRs #76 a
  #79 de lá).
