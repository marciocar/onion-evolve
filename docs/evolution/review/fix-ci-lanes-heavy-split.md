---
branch: fix/ci-lanes-heavy-split
pr: 1635
date: 2026-11-12
reviewed_diff_sha256: 02a7646f1f31bfcd36bcbde5d6e4aa2892a0f116c0a03752ed2aee5b78293d2e
reviewed_code_sha256: 459347f6b95b81a4ca145e774f30ba6b42107fd663639e3d14ca5ff9a01a06cf
findings_total: 7
findings_real: 7
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 5
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: refutador opus (pela sessão principal, REJECTED no b4d80d954) + passada própria do autor
nota: "tokens e duração não medidos. Re-revisão: os 2 bloqueios do refutador curados neste push; 2 achados dele ficam como limite declarado. O refutador ainda não re-revisou."
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
- **Tabela re-medida**: mediana de 18 runs completos de hoje, em TODAS as tentativas, com 4 limites
  inferiores (faixas que estouraram). A `selftest_selection` foi partida em duas famílias (achado 5).
- **7 faixas** no workflow.
- **Caso (h)**: o orçamento cai de 75% para 65% do teto do passo. **Casos novos**: (n) cada pesada tem faixa
  própria, sem `fixtures`, com as fatias cobrindo 0..k-1; (o) o coletor conta a faixa que estourou. O caso
  (a) aceita faixas sem `fixtures`, e o (i) roda com a separação desligada, porque mede a fila.

Projeção pela tabela nova (mediana, simulador da fila):

| plano | faixas (s) | pior | soma das paredes |
|---|---|---|---|
| antes: main, N=6 (tabela com todas as tentativas) | 418 / 1049 / 811 / 672 / 975 / 664 | 1049 s = 17,5 min (76%) | 76,5 min |
| 1º push: N=7, pesadas separadas (tabela da última tentativa) | 850 / 778 / 700 / 658 / 605 / 549 / 575 | 850 s = 14,2 min (62%) | 78,6 min |
| re-revisão: N=7, pesadas separadas e `selftest_selection` partida | 820 / 707 / 693 / 651 / 542 / 591 / 685 | 820 s = 13,7 min (59%) | 78,2 min |
| re-revisão +50% | — | 1230 s = 20,5 min (89%) | — |

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

4. (real, BLOQUEAVA, curado; refutador) O coletor baixava só a ÚLTIMA tentativa de cada run (`gh run
   download`). No run 43268758579 o estouro da tentativa 1 (`selftest_selection` no ar desde +390 s) foi
   trocado pela tentativa 2, verde em 660 s, e a tabela perdeu justamente o estouro citado no commit. Agora o
   coletor lista `actions/runs/<id>/artifacts` e baixa cada artefato pelo id: cada tentativa de cada faixa é
   uma observação, e a `fixtures` do run soma, por faixa, a mediana das tentativas. Com isso, a mediana da
   `selftest_selection` inteira foi de 850 para 870 s e a da `kg_backlog` de 776 para 820 s. O caso (o) agora
   usa um `gh` falso com 2 tentativas.
5. (real, BLOQUEAVA, curado pela opção (a); refutador) A faixa de uma pesada não leva `fixtures`, então a
   parede dela é a mediana da própria família, e somar faixa não a baixa. Com o dado corrigido, a
   `selftest_selection` sozinha ficava a um passo do orçamento do (h). Cura (a): a família foi PARTIDA. Os
   casos (d2), (e) e (e2) viraram a família `selftest_selection_failsafe`, sem mudar uma linha deles; só a
   fronteira da função mudou. Medido local: 333 s + 422 s (fração 0,44 / 0,56), 16 + 3 = 19 casos, como
   antes. Os runs anteriores à partição entram na tabela pela fração medida (`ONION_COLLECT_SPLIT`, escrito no
   cabeçalho da tabela). Também entrou um pedaço de (b): a mensagem do (h) diz se a pior faixa é de pesada
   (cura: partir a família, nomeada) ou de leves (cura: somar faixa). O comentário do workflow trocou a
   receita. Dogfood: com `kg_backlog` a 1000 s numa tabela de teste, o (h) reprova e nomeia
   "parta a família mais cara dela (kg_backlog)".
6. (real, LIMITE; refutador) A fração de pesada (0,5 da mais cara) é um parâmetro do plano que nenhum caso
   guarda. Mexer nela muda quem é pesada sem reprovar nada, a menos que a projeção estoure.
7. (real, LIMITE; refutador) Pesada RELATIVA num PR de subconjunto: no nível PR, o "mais caro" é o do
   subconjunto, e uma família leve pode virar pesada e ganhar faixa própria. Isso custa uma faixa a mais, sem
   risco de estouro.

## Mutantes

Plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, contra `--families shard_plan`. Na 1ª rodada,
os 8 abaixo morreram (rc 1); na re-revisão os 7 que restaram foram rodados de novo, mais os 2 novos, e todos
morreram:

- workflow com N=6: o (h) reprova (1076 s contra o orçamento de 897 s).
- `sep = False`: o (h) reprova (1004 s), e o (n) também.
- `fixtures` em todas as faixas (`fx_lanes = list(range(n))`): o (h) e o (n) reprovam.
- fatia `i/n` no lugar de `i/k`: o (n) reprova.
- coletor sem o limite inferior do teto (`last = last`): o (o) reprova.
- coletor sem a fatia de `fixtures` no ar (`fx += 0`): o (o) reprova.
- coletor com uma tentativa só por nome (dedupe do `actions/runs/<id>/artifacts`): o (o) reprova (zz_a 240).
- partição ignorada no coletor: o (o) reprova (zz_a 120 com a partição pedida).
- A mensagem de "faixa de pesada" do (h) não tem mutante; ela foi provada por dogfood (tabela com `kg_backlog`
  a 1000 s).

## Limites declarados

- **A leitura estrita do pedido segue inviável.** "≤65% do teto mesmo com +50%" pede uma projeção ≤ 598 s.
  Depois da partição, a pior é a `kg_backlog` sozinha (820 s), e `selftest_lanes` (698), `outbox_channel`
  (663) e `radar_staleness` (605) também passam de 598. O que este PR garante é a leitura viável: projeção
  ≤ 65%, e com +50% ainda dentro do passo (0,975). Na re-revisão, a pior +50% dá 20,5 min, 89% do teto. A
  margem estrita pede partir também essas quatro, e isso fica para outra leva.
- A fração da partição (0,44) é de UMA rodada local, não do runner. Ela só vale para os runs anteriores à
  partição; a próxima re-medição, com runs que já tenham as duas famílias, a substitui pela medida direta.
- Custo de runner: a soma das paredes sobe de 75,4 para 78,6 min por run completo, mais o setup de um job a
  mais (~0,5 a 1 min).
- O modelo continua sem a variância entre runners e sem o desbalanço da `fixtures` entre os workers. A
  separação tira esses dois efeitos do caminho crítico das faixas pesadas, mas não os modela.
- O plano de 7 faixas ainda não rodou no runner. A projeção é só do simulador.

## Re-revisão (2026-11-12, depois do REJECTED do refutador no b4d80d954)

Os dois bloqueios foram curados no mesmo PR (achados 4 e 5), e os dois limites do refutador estão
declarados (achados 6 e 7). Re-medido: a tabela vem do coletor novo sobre os 18 runs, com
`ONION_COLLECT_SPLIT=selftest_selection:0.44:selftest_selection_failsafe`. A família `shard_plan` passou
15/15, e as duas metades da `selftest_selection` passaram 16 + 3. Os mutantes estão na seção acima.
O refutador ainda não re-revisou este push.
