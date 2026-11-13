---
branch: feat/market-peek
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: 5f68bac914d7cf4e5694ae6ae44bc2f982359afac9ce50a69c07624cf503d71f
reviewed_code_sha256: cb0e5e8eb6c8a449a8ce7e642c5c92205cfdda610e939adad2c5ce1a1f9e96c8
findings_total: 4
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: "1ª passada: o próprio agente de execução (o brief proibiu lançar agentes); voz única, DECLARADA. A passada independente fica PENDENTE e é lançada pelo team-lead da sessão do core; ela regrava este resíduo."
nota: "tokens 0 = não medido. Medido: bancada market_peek 36 de 36 (18 casos e 18 mutantes), radar --integrity --schema exit 0 e kg-contract-check rc 0 nos dois grafos, ops/kg-vocab-ci.sh rc 0, peek-census.sh no repo rc 0 (1 espiada, 0 inválidas), community-peek.sh ao vivo rc 0 (hn 200, github 200, lobsters 200, reddit GAP)."
---

# Passada adversarial: `feat/market-peek`

## O que muda

Nasce o `/meta:peek`, a maquinaria de espiar o mercado na dúvida pedida pelo maestro em 2026-11-13. São cinco
peças: a doutrina (`peek-doctrine.md`); a tabela da escada (`peek-ladder.tsv`); o executor do nível 1
(`community-peek.sh`: HN, GitHub e Lobsters, com o `http_code` conferido e o Reddit como lacuna); o medidor
injetado (`peek-census.sh`: escolhe o nível, cobra o registro e propõe recalibração); e a bancada `market_peek`.
Entram também o grafo da pesquisa `wf_3157a547-84f` com a SYNTHESIS e o registro com a 1ª espiada real. O comando
nasce no conjunto `pending` do `roles.yaml` (fonte e hub). O censo da forja dá 5 de 7 peças: o workflow (peça 4)
é o `/onion-research` dos níveis 2 e 3, e a lente (peça 6) fica de fora nesta fase.

## Achados

| # | achado | real? | destino |
|---|---|---|---|
| 1 | `--gh-repo` validado por glob de `case` (`[A-Za-z0-9._-]*/…*`): o `*` casa qualquer coisa, e «a/b c» passava | sim | curado: regex ancorada; caso (r) da bancada, que reprova contra o glob |
| 2 | o nó da espiada citava um código de regra sem termo na prosa, e o lint de nomes acusou um código novo | sim | curado: troquei o código pela glosa; `kg-vocab-ci.sh` rc 0 |
| 3 | a contagem `items=` do resumo soma a página devolvida (até 20 por fonte), não o `total_count` | não | limite: o total vai na nota da linha da fonte (`total=9118`), e o resumo conta o que foi lido |
| 4 | o Lobsters filtra por substring dos termos (`agent` casa `agents`) | não | limite: o recall baixo já está declarado na linha e na doutrina |

## Mutantes

Cada um dos 18 casos da `run_market_peek_selftests` roda contra o SUT intacto e contra um mutante plantado na
própria âncora, que precisa existir uma vez só. Por exemplo: o `>` sem codificar, `if fail` virando `if False`, o
`sys.exit(0)` fixo, o `incomplete_results` forçado a `false`, o Reddit consultado, o filtro de data removido, a
banda de severidade em 5, o teto da mão dupla desligado, a célula faltante aceita, o enum do desfecho aberto, o
override exigido sempre, a recalibração para baixo e para cima desligadas, a amostra mínima ignorada, o
`pending-old` em 3000 dias, a fixture contada, o booleano do YAML não normalizado e o `--gh-repo` por glob. Todos os
18 mutantes reprovam (36 de 36).

## Limites declarados

- A ponte reversibilidade → degrau e a recalibração pelo histórico são **cunhagem Onion**, sem evidência de mercado
  na rodada. A 1ª proposta real do medidor é o teste (`Q_PEEK_LADDER_LEARNS_1113`).
- A classificação da reversibilidade é juízo da sessão: não existe classificador, e ela fica gravada no nó para
  auditoria.
- Reddit, fóruns de fornecedor e Discussions do GitHub ficam como lacunas declaradas.
- O portal no `/meta:decide` é o 2º PR (`Q_PEEK_DECIDE_PORTAL_1113`).
- O executor depende de HN Algolia, GitHub e Lobsters, e essa dependência é intrínseca e declarada
  (`D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027`). Sem rede, o nível 1 sai NÃO MEDIDO (rc 1).
