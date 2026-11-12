---
branch: fix/ci-lanes-heavy-split
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: acc9751ed933cf0f376b9f9a99b0428456f4a77ca298c821a98948cb598195c6
reviewed_code_sha256: a65cb4775aa7043edab96aaaf4948bbcaff99702c943d13f7773322613392fd5
findings_total: 3
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: autor (passada própria; a passada do refutador opus é pedida pela sessão principal, não por este agente)
nota: "tokens e duração não medidos. Refutador externo pendente: a sessão principal o dispara antes do merge."
---

# Passada adversarial: `fix/ci-lanes-heavy-split`

## O que muda

Na tarde de 2026-11-12, a faixa 1 da bancada estourou o passo de 23 min em 3 de 4 pushes à main (runs
43265160002, 43268758579 na 1ª tentativa e 43279234372) e no PR #1630, sem caso reprovado. O plano de 6
faixas (PR #1619) juntava as quatro pesadas (`selftest_selection`, `kg_backlog`, `selftest_lanes`,
`outbox_channel`) e uma fatia da `fixtures` numa faixa só. O modelo achava a pilha eficiente, com 4 workers
e 4 pesadas em paralelo. Mas a parede dela é o máximo de quatro famílias ruidosas (cada uma de 1,2 a 1,44×
a mediana no pior run) somado à maior fatia de `fixtures` entre os workers, e nada disso o modelo vê.

- **Pesadas separadas** (`ops/testing/selftest-shard-plan.sh`). Pesada é a família com custo ≥ metade da mais
  cara (`ONION_SHARD_HEAVY_FRACTION`, 0,5); hoje são 5. Com N maior que o número de pesadas, cada uma vai
  para uma faixa própria, e essa faixa NÃO recebe fatia da `fixtures`. As leves completam as faixas pela
  fila simulada, e a `fixtures` se reparte só entre as faixas sem pesada (`fixtures_lane i/k`). Com N ≤
  pesadas, o plano avisa e volta ao modo antigo.
- **Coletor pela sonda de disco** (`ops/testing/collect-family-times.sh`). A tabela vinha das linhas `⏱`
  do log, e a faixa morta pelo teto não imprime nenhuma: a tabela só via os runs em que a família coube.
  Agora o coletor lê o `selftest-disk.tsv` do artefato. Família no ar quando a faixa morreu entra como
  limite inferior (do início dela até o teto do passo).
- **Tabela re-medida**: mediana de 18 runs completos de hoje, 3 deles com limite inferior (a
  `selftest_selection` nas faixas que estouraram).
- **7 faixas** no workflow.
- **Caso (h)**: o orçamento cai de 75% para 65% do teto do passo. **Casos novos**: (n) cada pesada tem faixa
  própria, sem `fixtures`, com as fatias cobrindo 0..k-1; (o) o coletor conta a faixa que estourou. O caso
  (a) aceita faixas sem `fixtures`, e o (i) roda com a separação desligada, porque mede a fila.

Projeção pela tabela nova (mediana, simulador da fila):

| plano | faixas (s) | pior | soma das paredes |
|---|---|---|---|
| antes: main, N=6 | 1029 / 587 / 586 / 581 / 824 / 918 | 1029 s = 17,1 min (75%) | 75,4 min |
| depois: N=7, pesadas separadas | 850 / 778 / 700 / 658 / 605 / 549 / 575 | 850 s = 14,2 min (62%) | 78,6 min |
| depois +50% | — | 1275 s = 21,3 min (92%) | — |

## Achados

1. (real, curado) O coletor só via os runs em que a família coube. A faixa que estourou não deixa `⏱`, e
   a tabela subestimava a `selftest_selection` (os 3 estouros de hoje: ≥938, ≥991 e ≥1053 s). Agora ele lê
   a sonda de disco, e o caso (o) prova isso.
2. (real, curado) No 1º desenho, a fatia da `fixtures` era `i/n` pelo índice da faixa. Com faixas sem
   `fixtures`, as fatias deixariam buracos no manifest. Ela passou a ser `i/k`, só nas faixas que a recebem;
   o caso (n) mata o mutante. O (a) não o via, porque planeja com N=4, sem separação.
3. (real, curado) O caso (i) quebraria com a separação ligada: a família de 1000 s ganharia faixa própria
   sem `fixtures`. Ele passou a rodar com `ONION_SHARD_HEAVY_FRACTION=2`, porque mede a fila, e quem cobre a
   separação é o (n).

## Mutantes

Plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, contra `--families shard_plan`. Os 8 morreram
(rc 1):

- workflow com N=6: o (h) reprova (1076 s contra o orçamento de 897 s).
- `sep = False`: o (h) reprova (1004 s), e o (n) também.
- `fixtures` em todas as faixas (`fx_lanes = list(range(n))`): o (h) e o (n) reprovam.
- fatia `i/n` no lugar de `i/k`: o (n) reprova.
- coletor sem o limite inferior do teto (`last = last`): o (o) reprova.
- coletor sem a fatia de `fixtures` no ar (`fx += 0`): o (o) reprova.

## Limites declarados

- **A leitura estrita do pedido é inviável sem partir famílias.** "≤65% do teto mesmo com +50%" pede uma
  projeção ≤ 598 s. A `selftest_selection` sozinha tem mediana de 850 s, e outras quatro pesadas passam de
  598. Partição não resolve isso. O que este PR garante é a leitura viável: projeção ≤ 65% do teto, e com
  +50% ainda dentro do passo (0,65 × 1,5 = 0,975). A pior faixa projetada +50% dá 21,3 min, 92% do teto. A
  cura que dá a margem estrita é partir as pesadas (`selftest_selection` tem 23 casos, cada um rodando o
  seletor sobre a bancada inteira), e isso fica para outra leva.
- Custo de runner: a soma das paredes sobe de 75,4 para 78,6 min por run completo, mais o setup de um job a
  mais (~0,5 a 1 min).
- O modelo continua sem a variância entre runners e sem o desbalanço da `fixtures` entre os workers. A
  separação tira esses dois efeitos do caminho crítico das faixas pesadas, mas não os modela.
- O plano de 7 faixas ainda não rodou no runner. A projeção é só do simulador.
