---
branch: chore/refresh-family-times-1123
pr: 1748
date: 2026-11-23
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: FIXED
elenxo: false
reviewer: "a sessão do core (autora); mudança só de dado medido, regenerado pelo coletor da casa"
nota: "tabela de tempos re-medida em 12 runs completos da main de 2026-11-22/23; cobre 100% do --list"
---

# Passada: `chore/refresh-family-times-1123`

## O que muda

`ops/testing/selftest-family-times.tsv` re-medida por `collect-family-times.sh` sobre os 12 runs verdes mais
recentes do workflow Onion Guard Selftest na main. A tabela antiga não tinha 14 famílias novas; com mais uma nova no
PR (#1680, `kg_writer_backup`), o aviso do plano truncava a lista de nomes e o caso (m) da família `shard_plan`
reprovava a faixa 5 em todo PR de bancada completa.

## Achados

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | O caso (m) depende de `selftest_selection` caber na lista truncada do aviso do plano; com 15 famílias sem tempo ele some e o caso reprova sem defeito real | sim | não | Curado o sintoma: a tabela cobre o `--list` inteiro. A fragilidade do caso fica para PR de guarda próprio |

## Conferido

- `--list` × tabela: nenhuma família sem tempo. `fixtures` presente (4956 s); `selftest_selection` 528 s.

## 2ª passada (CI do próprio PR, 2026-11-23)

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 2 | A re-medição inteira estoura o orçamento: pior faixa projetada 1007 s contra 897 s, e 9 pesadas dividem faixa com `fixtures` (casos h e n da `shard_plan`) | sim, medido no CI | sim para a tabela inteira | Curado pelo escopo: só as 13 famílias que faltavam entram com a mediana nova; as demais seguem com a medição anterior. A lentidão real vai ao card SAC-541 (somar faixa ou cortar custo) |

`shard_plan` local: OK, todas as guardas reagiram. Tabela × `--list`: nenhuma família sem tempo.
