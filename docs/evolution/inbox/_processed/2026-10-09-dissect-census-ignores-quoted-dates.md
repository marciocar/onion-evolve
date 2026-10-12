---
title: 'dissect-census não lê baseline/review_after entre aspas, que a gramática v3 exige'
date: 2026-10-09
from: onion-curation (consumidor)
to: core (onion-evolve)
type: signal
flow: upstream (consumidor→core)
---

# O censo de dissecações não lê a data que a gramática manda escrever

## O que foi medido

- `.claude/rules/kg-grammar.md:30` (linha "datas"): `baseline`, `review_after`, `verified_at` e `valid_from`
  devem ir **sempre entre aspas**. Sem aspas, o contrato acusa `yaml.unquoted-date`.
- `.claude/validation/dissect-census.sh:74,76` lê a data com
  `sed -n 's/^[[:space:]]*review_after:[[:space:]]*\([0-9-]\{10\}\).*/\1/p'`. O padrão não aceita aspas, e o
  mesmo vale para o `baseline:`. Isso vale desde `507e8522` e segue igual no `origin/main` do core (`98cc49e2`) e no pin `7818b8a25ae6`.
- Controle: rodei o censo do `origin/main` do core sobre `docs/evolution/dissect/superpowers-2026-10/`
  deste repo, que tem `baseline: "2026-10-09"` e `review_after: "2026-11-08"`. Saída:
  `superpowers | N3 | rejeitar | - | - | NAO-DECLARADO`. O Cedar (`cedar-2026-10.kg.yaml:5-6`) sai
  `fresco` só porque escreve as datas **sem** aspas, isto é, fora da gramática v3.

## Efeito

Toda dissecação nova escrita conforme a gramática perde o frescor no censo e sai NAO-DECLARADO. O mesmo
acontece com as antigas: o `.claude/utils/kg/kg-migrate-v3.py:10,33` põe aspas em `baseline` e `review_after`,
então migrar o Cedar para o v3 também o deixaria cego no censo. A bancada do censo no `lint-selftest.sh` só
tem datas sem aspas, por isso não acusou. O
`/meta:dissect` passo 1 ("dissecação VENCIDA é re-medida") deixa de ver o vencimento. São dois leitores
discordando do mesmo byte, a mesma classe que motivou a troca de `on:` por `trigger:`.

## Pedido

Aceitar aspas opcionais (`["']\{0,1\}`) antes e depois da data nos dois `sed` do censo, e acrescentar à
bancada um caso com data entre aspas. Aqui não há correção local: o censo é vendorizado. Até lá, o estudo
do Superpowers fica com o frescor NAO-DECLARADO no censo, e o `review_after` dele é 2026-11-08.

Nota de versão: o pin `7818b8a25ae6` deste repo ainda lê só `dissect_tool:` sem `x_`. O core já corrigiu
isso no contrato v4 (`126a5564`). Aqui o estudo usa `x_`, então o censo local fica cego a ele até o próximo
update do Onion. Isso está declarado, não é pedido.
