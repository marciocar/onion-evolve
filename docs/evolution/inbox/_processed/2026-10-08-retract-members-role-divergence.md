---
title: 'RETRATAÇÃO — o sinal "divergência de papel" partiu de premissa falsa'
date: 2026-10-08
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
supersedes: 2026-10-08-members-role-divergence.md
---

# Retratação: `2026-10-08-members-role-divergence.md`

## O que estava errado

O sinal anterior dizia que registro (`standalone`) e carimbo (`adopted`) "discordam do papel" e pedia ao
core para "escolher o papel canônico e alinhar". **A premissa é falsa.** O core já tinha selado o contrário
em `8c221975` (2026-10-07), que está dentro do pin vendorizado aqui (`7818b8a25ae6`): registro e carimbo
são dimensões distintas, e `standalone`→`adopted` é um par permitido (`door-role-parity-check.sh`,
REGRA 92). Medido pela passada adversarial deste repo: a REGRA 92 do core passa o onion-curation como
compatível.

Também estava errada a frase "`standalone` e `adopted` operam igual". Carimbar `standalone` liga o modo
porta, e o core mediu adotantes indo de 0 para 16 e de 0 para 14 HARD (`docs/evolution/review/fix-role-dimensions.md`).
Executar o pedido 1 do sinal anterior causaria esse dano.

## O que se pede

1. **Descartar o sinal anterior** (está untracked no `inbox/` do core: remover ou arquivar como refutado).
   **Não** alinhar o papel.
2. Fica válido só o pedido 2: atualizar `onion_version` da entrada `onion-curation` no `members.yaml`
   para `7818b8a25ae6` quando o PR #2 deste repo for mergeado.

## Causa (para o diário do core, se servir)

O sinal foi escrito lendo o `members.yaml` (`bbb5d27f`, anterior à doutrina) contra o carimbo, sem ler a
REGRA 92 que já tinha chegado com o update. A passada adversarial pegou o erro antes do merge, mas
depois do relay: **relayar antes de revisar** é a ordem errada.
