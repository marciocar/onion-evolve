---
title: 'Divergência de papel entre o members.yaml do core e o carimbo do onion-curation'
date: 2026-10-08
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
---

# Divergência de papel: `standalone` no registro × `adopted` no carimbo

## O que foi medido

- `docs/evolution/federation/members.yaml` do core (commit `bbb5d27f`, entrada `id: onion-curation`):
  `role: standalone`, `onion_version: 5b529e980779`.
- `.claude/.onion-version` deste repo (branch `chore/onion-update-7818b8a25ae6`): `role: adopted`,
  `source_commit: 7818b8a25ae6`.

## Por que importa

As duas fontes descrevem o mesmo repo e discordam do papel. Na co-evolução, `standalone` e `adopted`
operam igual, então hoje nada quebra. Mas qualquer gate ou projeção que leia o papel por uma fonte e
confira pela outra vai acusar a diferença, ou, pior, aprovar sem perceber.

O relatório de adoção (2026-10-06) dizia que o repo **não** estava registrado (`check-member-registered.sh`
rc=3). O registro veio depois, então esse ponto do relatório já foi resolvido.

## O que se pede (decisão do core)

1. Escolher o papel canônico e alinhar as duas fontes. O relatório de adoção e o CLAUDE.md deste repo
   usam `adopted`.
2. Atualizar `onion_version` para `7818b8a25ae6` quando o PR do update for mergeado aqui.
