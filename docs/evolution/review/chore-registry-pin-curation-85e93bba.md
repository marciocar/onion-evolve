---
branch: chore/registry-pin-curation-85e93bba
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: a sessão executora; o pin foi conferido no remoto do adotante antes do selo
nota: "PR de registro, só o pin carimbado pelo ops/registry-pins.sh --seal a partir do remoto. Sem passada adversarial: não há código. tokens e duration_min em 0 = não medidos."
---

# Passada adversarial: `chore/registry-pin-curation-85e93bba`

## O que muda

O pin do `onion-curation` no `members.yaml` sobe de 10514066fb28 para 85e93bba1609, carimbado pelo
`ops/registry-pins.sh --seal --only onion-curation`, que leu o carimbo do remoto do adotante.

## Conferido antes do selo

- PR #20 do adotante mergeado por merge commit (c4faaa8).
- `.onion-version` da main dele com `source_commit: 85e93bba1609`.
- `onion/vendor` ancestral da main dele.
- O hook aposentado já não está no settings.json dele (curado à mão lá; a cura no core é a SAC-145).
