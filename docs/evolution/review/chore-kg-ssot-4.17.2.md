---
branch: chore/kg-ssot-4.17.2
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 1fb6aa0e149b75c9ba23ddf249f07f6ce75683a9ac2fe6a8aa53550c91a441c1
reviewed_code_sha256: 162e3dc389a10b1f4e6fabd4c5fa36c064a9149ed30cadada171bccc04171bc3
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 4
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: sim
reviewer: sessao-principal
nota: >-
  Subida de vendor pelo kg_vendor.py (fonte oficial, tag kg-ssot-v4.17.2, 3ce4601f2bb8). Conferido:
  ops/kg-gate-ci.sh rc 0 sem --update (183 grafos, 167 no MUST, os mesmos 16 na dívida herdada da
  4.17.0); o pin do workflow trocado na única linha que o citava; o CHANGELOG da 4.17.1 e 4.17.2 lido
  (sem mudança de contrato).
---

# Passada adversarial: `chore/kg-ssot-4.17.2`

## O que muda

`vendor/kg-ssot` de 4.17.0 para 4.17.2 e o comentário do pin em `.github/workflows/onion-validate.yml`.

## O que a passada tentou refutar

- Contrato mudou e a identidade do gate vira: refutado, rc 0 sem --update.
- Dívida nova: refutado, os 16 herdados são os mesmos da 4.17.0.

## NÃO MEDIDO

O kg_mcp 4.17.2 servido (o onion-kg na VPS tem o próprio deploy).
