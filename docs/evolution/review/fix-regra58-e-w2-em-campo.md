---
branch: fix/regra58-e-w2-em-campo
date: 2026-08-09
reviewed_diff_sha256: bf725896c3e469bdc08f06224fa5da0cebbc32291dabdaa04c3a986b32274221
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-DOIS-DEFEITOS-DE-DOUTRINA-ACHADOS-REVISANDO-O-ALINHAMENTO-E-UM-SANDBOX-QUE-MENTIU
reviewer: sem passada adversarial — ver "O que NÃO foi feito"
---

# Revisar o alinhamento achou dois defeitos, e o meu primeiro sandbox mentiu

O pedido era revisar o alinhamento das 4 classes que faltavam da W2 e seguir até o fim. **Revisar o
alinhamento — ler a fonte em vez da lembrança — foi o que produziu os dois achados.**

## 1 · A tabela de doutrina da catraca mentia, e sobreviveu a um Elenxo inteiro

```
linha 371:  #   REMOVIDO   o nó não existe mais naquele arquivo   → SOFT (ato visível no diff)
linha 420:      emit HARD REMOVIDO
```

O PR da 2ª porta trocou a emissão para HARD em 08/08 e **não tocou na tabela**. É
`declarado ≠ verificado` dentro do cabeçalho do gate que existe para caçar isso — e passou por uma
passada adversarial de 9 refutadores mais juiz, porque **revisor lê a tabela COMO SE fosse a
verdade** em vez de compará-la com o código.

A cura não podia ser *"quem editar a emissão edita a tabela"*. Virou a **catraca `(w)`**: extrai as
classes do cabeçalho, extrai as severidades de `emit`, e compara.

Duas armadilhas cobertas de propósito:

- **classe com duas severidades é legítima** — `MUDOU-DE-PATH` sai HARD fora do escopo e SOFT em
  path vivo. O teste é *"a severidade da tabela está ENTRE as emitidas"*, nunca igualdade; a versão
  ingênua nasceria com falso-positivo, que é como se ensina a ignorar guarda;
- **canário contra vacuidade** — o extrator depende do formato do comentário, e um reflow o mataria
  em silêncio. Menos de 5 classes extraídas é `record_fail`, não verde.

Provada nas duas direções: tabela íntegra passa; devolvendo `REMOVIDO → SOFT`, acusa.

## 2 · O backlog prometia três coisas e não cobrava nenhuma — **REGRA 58**

O `meta:` de `fios-abertos.kg.yaml` declara, em letra grande: **teto de 20 nós**, *"onda nova exige
onda COLHIDA"* e **"QUEM NÃO CONSEGUE CARIMBAR NÃO PODE DECLARAR FEITO"**. As três eram disciplina.

E há um motivo estrutural para isso ser perigoso, que não estava previsto quando se escolheu o
plano: **a REGRA 49 não alcança este arquivo.** Ele nasce todo `plane: DEV`, de propósito, para não
poluir o baseline com nós que afirmam sobre *trabalho* e não sobre *produção*. A R49 só olha `PROD`.
O efeito colateral é que declarar `done` ali **saía de graça** — no arquivo cujo cabeçalho diz que
não se pode.

`kg-backlog-check.sh` fecha:

| classe | quando | severidade |
|---|---|---|
| `TETO` | mais nós que o teto **declarado no próprio `meta:`** | HARD |
| `DONE-NU` | item `done` sem `verified_at` **e** `verified_against` | HARD |
| `SEM-TETO` | o `meta:` não declara teto | HARD |

**O teto é lido do arquivo, nunca hardcoded** — um número no script e outro no `meta:` seria a mesma
classe de defeito do achado nº1, cometida ao curá-lo.

**`SEM-TETO` é fail-loud por desenho.** Guarda que não sabe o que cobrar jamais afirma conformidade
(P0 da REGRA 30), e *"sem teto"* é indistinguível de *"teto zero"* para quem só olha o exit code.

5 selftests, todos mutando o **backlog real** copiado em `mktemp` — não fixture inventada. O caso
`(a)` existe para que os outros quatro não provem o nada.

## 3 · O meu primeiro sandbox mentiu, e o controle foi o que salvou

Para provar as classes HARD **em campo**, montei o sandbox com `git archive HEAD | tar -x`. Resultado:

```
REMOVIDO         → 47 HARD
FUGA-SEM-ARESTA  → 47 HARD
FUGA-DE-ESCOPO   → 47 HARD
```

Editar **um** nó não pode apagar 47. `git archive | tar -x` **não cria `.git`**, o `load_universe`
varre com `git ls-files`, o universo saiu vazio, e **toda** chave do baseline virou *"não existe
mais"*. Os três testes mediram o mesmo artefato quebrado e não provaram nada.

**Sexta vez nesta sessão que medi o artefato errado.** O que salvou foi rodar um **CONTROLE** antes
das mutações — sandbox intacto tem de dar `47 SOFT / 0 HARD`. Sem ele, eu teria relatado "as três
classes mordem" com três números falsos.

Refeito com `git init` + commit no sandbox:

| tentativa | veredito | acusações |
|---|---|---|
| `REMOVIDO` (apagar o nó) | HARD | **1**, nomeando o nó |
| `FUGA-SEM-ARESTA` (reetiqueta nua) | HARD | **1**, nomeando o nó e a aresta que falta |
| `FUGA-DE-ESCOPO` (rebaixar impact) | HARD | **1**, citando `plane:PROD impact:2` |
| `RECONCILIADO` (reetiqueta **com** aresta) | **SOFT** | 0 HARD |

**O par que mais importa:** a *mesma* reetiqueta de `EN_MAESTRO` dá HARD sem a aresta e SOFT com ela.
**A aresta é o discriminador** — e agora isso está provado no corpus real, não em fixture.

## A correção de leitura do plano

O plano dizia *"tirar 5 nós do baseline, um por classe, incluindo as duas HARD"*. Revisando o
alinhamento contra a fonte: **as três classes HARD não são saídas legítimas do baseline** — são o
que acontece quando alguém sai errado. O dogfood delas é **tentar e ser recusado**, nunca *conseguir*.

Só `CARIMBADO` e `RECONCILIADO` se produzem por medição, e o `CARIMBADO` já foi feito **em
produção** (#564: baseline 48→47, e a medição achou um piso de memória protegendo unit inexistente).

## Verificação

- bancada **748 passam / 0 falham / 0 pulam**, corrida solo · lint **0 HARD** + 4 SOFT pré-existentes
- catraca `(w)`: tabela íntegra passa; `REMOVIDO → SOFT` acusa
- backlog: **18/20**, nenhum `done` sem carimbo · radar do grafo verde (18 nós, 18 arestas)
- as 4 classes em sandbox `git` real, cada uma precedida do controle `47 SOFT / 0 HARD`
- REGRA 58 classificada no registry e projetada em `lint-rules.md`

## O que NÃO foi feito, declarado

- **Sem passada adversarial.** Os achados aqui vieram de *revisar o alinhamento contra a fonte*, que
  é uma forma mais barata do mesmo movimento — mas menos completa. O que um refutador provavelmente
  atacaria: o extrator do `(w)` depende do formato do comentário (o canário cobre o caso vazio, não
  o caso *parcialmente* quebrado), e o `kg-backlog-check.sh` lê o teto por regex no comentário, que
  é a mesma fragilidade num campo adiante.
- **Falta uma refutação GENUÍNA de nó real.** O `RECONCILIADO` foi provado em *condições* de campo,
  não como reconciliação de verdade: ela depende de uma medição que **derrube** um nó, e fabricar
  uma seria o oposto do ponto. Fica como o único fio da W2 realmente aberto.
- **"Onda nova exige onda colhida"** continua sem guarda — só o teto e o `done` nu foram
  mecanizados. A promessa é mais difícil de expressar mecanicamente e não quis forjar meia-cura.
