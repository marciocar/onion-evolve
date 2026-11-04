---
title: 'Sinal: o write-stamp.sh troca só o pin no ONION_INSTALLED, pela 4ª vez seguida'
date: 2026-11-04
from: onion-curation (adotante)
to: core (onion-evolve)
type: signal
evidencia: docs/onion/graph/onion-adoption.kg.yaml#E_STAMP_HELPER_PIN_ONLY_LABEL
reviewed_for_public: false  # o carteiro mediu a visibilidade deste repo: public
---

# Sinal: o escritor do carimbo deixa o nó do Onion instalado com dados do update anterior

**Pedido do core em 2026-11-04,** depois do update da curadoria para o pin `a682c090d1bc` (PR #195): "quatro vezes
seguidas é classe, não caso, e a cura tem de virar mecanismo".

## O defeito

No `--update`, o `write-stamp.sh` carimba o pin no nó `ONION_INSTALLED` do `docs/onion/graph/onion-adoption.kg.yaml`
do adotante. Ele troca só o token do pin no `label` e o `x_pin`. Ficam do update anterior:
- a data e a versão da kg-ssot no `label`;
- a lista de pins anteriores na `narrative`, que passa a omitir o pin que acabou de sair;
- a `provenance`, que segue citando o commit do carimbo antigo.

## As quatro ocorrências, todas curadas à mão

| pin do update | onde está registrado na curadoria |
|---|---|
| `fb36b24becfa` | `docs/evolution/review/chore-onion-update-fb36b24becfa.md`, linha 34 |
| `87c9b8f53be7` | `docs/evolution/review/chore-onion-update-87c9b8f53be7.md`, linha 33 |
| `3ade85b7e1c0` | `docs/evolution/review/chore-onion-update-3ade85b7e1c0.md`, achado M1 (a lista omitia o `67e9d003689f`) |
| `a682c090d1bc` | commit `21af2d9` (label com 2026-11-03 e kg-ssot 4.40.2, lista sem o `3ade85b7e1c0`, provenance `@d86aa63`) |

A evidência ficou registrada no nó `E_STAMP_HELPER_PIN_ONLY_LABEL`, que constrange o `ONION_INSTALLED`.

## A proposta, na leitura do core de 2026-11-04

- O helper refaz o `label` e a `narrative` do `ONION_INSTALLED` a partir do carimbo novo (pin, data, versão da
  kg-ssot do `vendor/kg-ssot/.kg-ssot-version`, contrato) e do `git log` da `onion/vendor` (a lista de pins
  anteriores).
- O helper recusa quando o `label` traz um token velho que ele não sabe trocar.
- Há caso de bancada e mutante para os dois comportamentos.

A peça é do core. A curadoria confere quando o PR existir.
