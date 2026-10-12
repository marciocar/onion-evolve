---
branch: fix/merge-hooks-relocate-matcher
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 60
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutante executado (sem subagente) — gate mecânico: família fixtures (run_merge_fixture)
---

# O merge de hooks realoca o hook Onion que está num grupo com o matcher errado

## Defeito medido

No 2º `--update` do onion-kg-ssot (2026-10-12, PR #80 de lá), o `pretooluse-direct-provider-api.sh`
continuou num grupo **sem matcher**. Ele foi anexado assim pelo update anterior, que era anterior ao #1051. O #1051 casa por command:
dá refresh nas chaves do hook, mas não o muda de grupo. A asserção (5) da bancada só pedia que houvesse
uma cópia no grupo certo, não que faltasse uma no grupo errado.

## Cura

Hook Onion no alvo (command que a fonte tem) num grupo cujo matcher difere do grupo de origem: sai desse
grupo e volta num grupo próprio com o matcher da fonte. Leva as chaves extras do alvo e as da fonte por
cima. Grupo que fica vazio pela retirada some. Hook próprio do alvo e hook sem `.command` não são tocados.

## Achados (passada própria)

1. **`has(.command)` com o mapa como entrada.** Dentro de `$srcmt | has(.command)` o `.command` é do mapa,
   não do hook, e o jq abortava com rc 5 em todo alvo. Pego no dogfood antes de qualquer commit e curado
   com `.command as $c | $srcmt | has($c)`.
2. **Falta de asserção.** A (5) passava com o hook duplicado no grupo errado. Entrou a (6): nenhum hook
   Onion fica num grupo com matcher diferente do da fonte.

## Prova

- Dogfood no `settings.json` real do onion-kg-ssot (cópia): o `direct-provider-api` sai do grupo sem
  matcher e entra num grupo `matcher: "Bash"`. `onFailure: block` mantido, merge idempotente (`cmp`).
- Fixture nova `target-onion-hook-wrong-group.json`: 2 hooks Onion fora do grupo, 1 hook próprio e 1 chave
  extra do alvo. O hook próprio fica, a chave viaja e o grupo vazio some.
- Família fixtures **118/0** com a cura. Com o script de `origin/main` (o mutante), a fixture nova reprova.

## O que NÃO cobre

- Um hook Onion que o adotante moveu **de propósito** para outro matcher volta ao da fonte. O hook é
  do Onion, e o matcher faz parte do contrato dele. Quem quiser outro escopo cria um hook próprio.
- A ordem dos grupos muda: o realocado vai para o fim do evento. A ordem entre grupos não muda o
  efeito.
