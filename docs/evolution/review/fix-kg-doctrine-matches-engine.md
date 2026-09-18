---
title: 'Resíduo — a doutrina prometia um gate que não existe, e o radar escondia o vencimento'
date: 2026-09-18
branch: fix/kg-doctrine-matches-engine
reviewed_diff_sha256: PENDENTE
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Dois sinais de campo do mesmo adotante, medidos com arquivo:linha dos dois lados, confirmados
  no vivo antes de curar. E um deles já estava curado sem que o remetente soubesse — medir o que
  mudou desde a chegada do sinal faz parte de triar.
---

# O adotante foi construir em cima da doutrina e conferiu se ela era verdade

Não era, em onze pontos. Este PR fecha os dois mais baratos e de maior retorno — os que o próprio
sinal ordenou por custo — e confirma no vivo **antes** de curar.

## Achado 1 — a KB promete cinco reprovações; o motor faz cinco OUTRAS

`knowledge-graph-sdaal.md:195-196` afirmava que a INTEGRIDADE reprova: nó `refuted` recebendo
`SUPPORTS` · `decision` `done` fora do plane PROD · órfãos · migalhas pendentes · ciclos
`DEPENDS_ON`.

O motor (`kg-radar.sh:27-29`) barra: **ids duplicados · aresta para nó inexistente · órfão ·
contradição (`REFUTES` entrando em nó `confirmed`/`open`) · enum inválido**.

Placar medido pelo adotante: **uma implementada** (órfãos), **três ausentes**, **uma rebaixada a
aviso**. Não há detecção de ciclo (`grep 'ciclo'` = 0; `A→B→A` passa com exit 0).

**A correção é o texto alcançar o código**, nunca o contrário — o cabeçalho do motor já trazia a
lista certa. E o placar **fica registrado** em vez de apagado, pela mesma razão que a casa já aplicou
uma vez: *"apagá-lo transformaria a vitrine em propaganda"*.

Por que importa, nas palavras do sinal: *"hoje a KB promete um gate que não existe, e um adotante que
confie nela constrói sobre areia."*

Corrigido junto: a atenção era descrita como **"PageRank ponderado"** e o motor nunca fez PageRank —
sem iteração, sem amortecimento, e com **grau não-direcionado**. A diferença não é cosmética: grau
não distingue *"conectado a coisas importantes"* de *"conectado a muitas coisas"*, e ordenar atenção
é a função central do radar.

## Achado 2 — o radar saía verde sobre conhecimento caduco

`meta.review_after` está na gramática e em 16 grafos. Quem o cobrava era só a REGRA 67 (Grafo de
pesquisa com REVISITA carimbada) — **SOFT, e no lint**. Medido: `grep -c review_after kg-radar.sh` = **0**.

Então **quem rodava o radar nunca sabia que o grafo tinha vencido**. Isso é pior que não ter o campo:
é um painel que afirma saúde sem ter olhado para a validade.

Nas palavras do sinal: *"não é feature nova, é parar de esconder"*.

Seção **VALIDADE** nova, com os três estados — vencido, em dia, e **não-medido** (grafo sem o campo
declara que não mediu, em vez de silêncio). **Não reprova**, por doutrina explícita do sinal:

> *"nada disso nasce bloqueando — um gate que impede trabalho é contornado com `--no-verify` na
> primeira sexta-feira, e aí se perde o mecanismo E a informação."*

O caso **(b)** da bancada existe só para guardar isso: se alguém transformar o vencimento em muro,
ele reprova.

## Achado 3 — um item do sinal já estava curado, e o remetente não sabia

O sinal de 09-11 pedia, como item de **maior** retorno, *"ligar o hook de leitura — o menor, e o único
que teria evitado o caso deste sinal"*. Medido hoje: `kg-read-leg.sh` **existe e está registrado no
`settings.json`**.

Ele pagou um dia de trabalho e quatro teses erradas para medir o custo da lacuna, e a lacuna fechou
sem que ele fosse avisado. **Medir o que mudou desde a chegada do sinal faz parte de triar** — sem
isso, a resposta ao adotante seria sobre um mundo que não existe mais.

## Um defeito meu, no harness

A 1ª redação do caso (b) reprovou acusando *"o vencimento virou muro"*. Era **falso**: a fixture não
declarava `impact`, a INTEGRIDADE reprovava por isso, e o `rc=1` não tinha nada a ver com validade.
SUT correto, harness incompleto — a mesma classe que esta casa já registrou em
`[[bancada-espelha-o-runner]]`.
