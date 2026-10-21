---
branch: chore/door-pins-and-a0
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: d92e4fb2306d561fa1929ea7818760547ee25c5062981c4871771a6915bf12b1
reviewed_code_sha256: e0e3b2d8ff8408ba5260571322d2cc8b9dbf72c25a5869f2212f60da5d13cbb4
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 2
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; cache do registro alinhado pelo ops/door-seal-pin.sh, que lê o remoto"
---

# Passada adversarial: `chore/door-pins-and-a0`

## O que muda

O `onion_version` das quatro portas no `members.yaml` passa de b52f41437ea0 para eb598aa5bcdd, que é o pin
publicado da onion-v2.0.4.

## Achados

Nenhum. O `publish-door.sh --status` lê o pin do carimbo remoto e dá eb598aa5bcdd nas quatro portas.

## Mutantes

Não se aplica.

## Limites declarados

O campo é cache. O fato é o carimbo publicado.
