---
branch: fix/regra58-e-w2-em-campo
date: 2026-08-09
reviewed_diff_sha256: fff45a2289ad22bd161828838fbe91f34fe06b5d06c1113f68827a8d3739d5f0
findings_total: 42
findings_real: 21
findings_fixed: 8
tokens: 846502
duration_min: 46
verdict: HARD-MAS-NAO-COMO-ESTAVA-A-REGRA-NOVA-ACUSAVA-SEM-CONTAR-E-O-ESCOPO-ERA-O-PROPRIO-PREDICADO
reviewer: Elenxo — 3 lentes × 2 refutadores + juiz (opus/high, juiz em max), wf_511ffd3e-2c0
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

## A passada adversarial derrubou a entrega — 3 de 6 refutadores disseram `CAI`

**42 achados brutos → 21 sobrevivem** (9 HARD). Veredito do juiz: **«HARD, mas NÃO como está.»** A
tese e a parte de campo sobreviveram — ele reproduziu o controle `47 SOFT / 0 HARD` e as 4 mutações
da W2, e confirmou que a explicação do *"sandbox mentiroso"* é a causa correta **e única**.

O que não sobreviveu foi a REGRA 58 como entregue.

### Dois verdes-falsos, e a raiz é a mesma

**1 · A regra acusava e NÃO contava.** `violation()` incrementa `HARD_COUNT` no shell **pai**;
`printf | while` roda o laço em **subshell** e o incremento morre com ele. Medido:

```
lint imprime:  VIOLATION: ... [kg-backlog/DONE-NU] ...
lint fecha  :  Violações HARD : 0 · OK ✓ · exit 0
```

**Guarda que acusa e não conta é pior que guarda ausente — produz a aparência de rigor.** Curado com
process substitution: `HARD 7 → 8`.

**2 · O filtro de escopo ERA o próprio predicado julgado.** Ele escopava por `grep TETO`, que é
exatamente o que a classe `SEM-TETO` existe para acusar. Duas consequências, ambas medidas:

- reescrever `TETO: 20 NÓS.` para `TETO de 20 nos.` **desligava a regra inteira**, em silêncio e
  verde — o fail-loud era **estruturalmente inalcançável** pelo gate, e o docstring o vendia como
  *"HARD, não silêncio"*. `declarado ≠ verificado` **dentro da regra criada para caçar isso**;
- e o escopo **viajava**: um grafo de adotante com "TETO: 3 Nós" num comentário qualquer entrava no
  julgamento. É a lição do `kg-trace-resolve` (11 falsos no 1º adotante) repetida no PR que a cita.

Curado com um marcador **próprio** (`# kg-backlog-guard: on`), independente do que se julga. Medido:
apagando a linha do teto, o `SEM-TETO` agora **chega ao gate** (HARD 8).

### E a raiz, que o juiz nomeou

```
grep -c check_kg_backlog lint-selftest.sh  →  0
```

Os 5 selftests mediam `bash "${helper}"`, **nunca o gate**. Ficavam 5/5 verdes com o fail-open ativo
**e** com a regra comentada fora do dispatcher. É `bancada-espelha-o-runner` na forma mais cara: o
teste media um artefato que **não é** o que barra o merge.

O caso `(e)` foi reescrito para **atravessar o lint inteiro** num sandbox git, plantar a violação e
exigir que **o contador suba** — não que a linha apareça. Cobre de uma vez o subshell, o fio no
dispatcher e o escopo.

### A tabela do helper NOVO já mentia

No PR que mecaniza a catraca contra tabelas que mentem, a tabela do `kg-backlog-check.sh` declarava
`PARADO → SOFT` (**nunca emitido**) e **omitia** `SEM-TETO` (emitido). Corrigida — e a catraca `(w)`
ganhou a **segunda direção**: classe emitida e ausente da tabela agora reprova.

### Carimbo de ar

`DONE-NU` aceitava `verified_at: ""`, `null`, `TODO`, e `status: "done"` com aspas escapava; CRLF
colava `\r` no valor. Todos YAML válido e indistinguíveis a olho. **Carimbo de ar é pior que carimbo
ausente: declara medição que não houve**, que é o defeito fundador da REGRA 49. Curado com
normalização (`trim`, aspas, `\r`, placeholders), medido nas cinco formas.

### E o `(w)` era enganável por COMENTÁRIO

Uma linha de comentário contendo o texto `emit SOFT REMOVIDO` re-escondia o drift **fundador** desta
catraca — o extrator via prosa como se fosse emissão. Comparar prosa com prosa é o oposto do ponto.

## O sétimo "medi o artefato errado", e é uma classe NOVA

A bancada abortou com **erro de sintaxe numa linha que `bash -n` aprovava**. Causa: **eu editei
`lint-selftest.sh` enquanto a bancada o executava.** Bash lê o script por offset de byte; minhas
edições deslocaram tudo sob os pés dele.

Não foi medir artefato **defasado** — foi **mutar o artefato durante a própria medição**. A corrida
seguinte passou a carregar `sha256sum` antes e depois, e a declarar `artefato ESTAVEL` no relatório.

E a primeira tentativa de cura piorou: congelar uma cópia em `$CLAUDE_JOB_DIR` quebrou tudo, porque
`SCRIPT_DIR` resolve pela **localização do arquivo**. A cura certa era a mais simples — rodar no
lugar e não tocar no arquivo.

## O que NÃO foi feito, declarado

- **A passada adversarial aconteceu** (o texto acima), mas as correções dela **não foram
  re-auditadas** por uma segunda passada. Os achados aqui vieram de *revisar o alinhamento contra a fonte*, que
  é uma forma mais barata do mesmo movimento — mas menos completa. O que um refutador provavelmente
  atacaria: o extrator do `(w)` depende do formato do comentário (o canário cobre o caso vazio, não
  o caso *parcialmente* quebrado), e o `kg-backlog-check.sh` lê o teto por regex no comentário, que
  é a mesma fragilidade num campo adiante.
- **Falta uma refutação GENUÍNA de nó real.** O `RECONCILIADO` foi provado em *condições* de campo,
  não como reconciliação de verdade: ela depende de uma medição que **derrube** um nó, e fabricar
  uma seria o oposto do ponto. Fica como o único fio da W2 realmente aberto.
- **"Onda nova exige onda colhida"** continua sem guarda — só o teto e o `done` nu foram
  mecanizados. A promessa é mais difícil de expressar mecanicamente e não quis forjar meia-cura.
