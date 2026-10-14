# Aula 5 — KG e Forja: o grafo dos seus projetos e os componentes do seu time

> Espelho em texto de [`lesson-5-kg-forge.html`](lesson-5-kg-forge.html), com a mesma substância.
> A versão para projetar é a HTML: abre offline, tem botão de copiar em cada comando e modo projetor.
> **Rascunho de 2026-10-14.** A nota para o revisor fica no fim deste arquivo.

**Série:** formação de equipe de um hub adotante, em 6 aulas.
**Esta é a 5ª.** Antes dela: (1) o "Há vagas", o perfil dos agentes que vocês querem; (2) os
documentos de negócio; (3) a adoção dos projetos e a maquinaria; (4) um projeto real com task manager.
Depois dela: (6) comunicação e federação, o Company Brain.

**Duração:** 3 horas, com um intervalo de 10 minutos. **Formato:** mão na massa. Cada bloco tem um
conceito curto, uma demonstração com o comando exato e um exercício no repositório de vocês, com um
critério de "pronto" que se confere por comando.

---

## Objetivo

No fim da aula, cada dupla sai com cinco coisas **no repositório**, todas conferíveis:

1. **Um grafo que o motor lê.** Os grafos do hub passam no `kg-radar` sem aviso e o `/meta:drive` os aceita.
2. **Um projeto mapeado contra o código.** As regras de domínio de um projeto real apontam para o
   arquivo e a linha que as executam, e não só para o documento que as descreve.
3. **Um documento de negócio ligado ao projeto.** Um documento das aulas 2 a 4 que ainda não estava
   em grafo nenhum vira nós, com a confiança certa, ligados às regras que ele afeta.
4. **Uma ferramenta de terceiro dissecada e decidida.** Um grafo de dissecação com veredito e o nó
   de decisão selado, antes de qualquer adoção.
5. **Um componente do time forjado.** Uma skill com doutrina, medidor e bancada, nascida de uma dor
   que vocês mediram (ou do plano de absorção da dissecação), e que o censo da forja enxerga.

E uma ideia: **o grafo é o estado do trabalho, não um desenho dele.** A sessão lê o grafo antes de
ler a prosa, o backlog é projeção do grafo, e uma decisão só existe quando está selada nele.

---

## Antes da aula (instrutor): medir a turma

A aula usa os artefatos reais da equipe como matéria-prima. Meça no dia, porque o repositório anda.
Rode **na raiz do hub** e, depois, **na raiz do projeto adotado** que a equipe trouxe na aula 4:

```bash
cat .claude/.onion-version                                  # pin e papel (hub / adopted)
git ls-files '*.kg.yaml' | grep -v '/fixtures/'             # os grafos de verdade
ls .claude/commands/meta/ | grep -iE 'kg|forge|backlog|realign|drive|dissect|graph'
ls docs/business-context docs/technical-context              # o que as aulas 2 e 3 geraram
for g in $(git ls-files '*.kg.yaml' | grep -v '/fixtures/'); do
  echo "== $g"; bash .claude/validation/kg-radar.sh "$g" --integrity --schema
done
```

Anote na ficha da turma (fica com vocês, não entra neste material):

| Medida | Hub | Projeto |
|---|---|---|
| grafos rastreados (sem fixtures) | | |
| grafos com aviso `multi-documento` | | |
| nós `rule`/`invariant`/`policy` com `trace:` em `docs/` × em código | | |
| documentos de negócio que nenhum grafo cita | | |
| itens abertos no `/meta:backlog --markdown` | | |
| candidatos e "6+ peças" no censo da forja | | |

> **Se um número sair zero, confira o porquê antes de usá-lo.** Zero de "não existe" e zero de
> "o comando falhou" têm a mesma cara. Os medidores desta casa recusam com `exit 3` quando não
> conseguem medir, justamente para não confundir as duas coisas.

---

## Pré-requisitos (participantes)

Confira em 2 minutos, no começo da aula:

Antes da aula, quem cuida do hub roda o **`/meta:adopt --update` do hub** e mergeia a
atualização: os blocos D, E e F pedem um pin que já traga o `/meta:decide`, o `/meta:dissect` e o
`/meta:forge` abertos
(pin **≥ 6e6deab1c443 (onion-v1.2.0)**). Depois, os projetos adotados pelo hub se atualizam do mesmo jeito.

```bash
git status --short                       # árvore limpa (ou um commit WIP antes de começar)
git switch -c lesson-5/<seu-nome>        # cada dupla numa branch própria
cat .claude/.onion-version               # o pin precisa ser o mesmo da turma
ls .claude/validation/kg-radar.sh .claude/validation/forge-census.sh .claude/rules/kg-grammar.md
ls .claude/commands/meta/decide.md .claude/commands/meta/forge.md .claude/validation/kg-decide-seal.sh
ls .claude/commands/meta/dissect.md .claude/validation/dissect-census.sh
docker --version || echo "sem Docker: o bloco E usa worktree descartável"
python3 -c "import yaml" && echo "PyYAML ok"   # o /meta:drive e o kg-realign leem YAML
```

Se o `ls` reclamar de arquivo ausente, o pin está velho: o `/meta:adopt --update` não rodou.
Resolva antes da aula, não durante.

---

## Mapa da aula

| Bloco | Tema | Tempo |
|---|---|---|
| 0 | Abertura: o que a sessão sabe antes de você falar | 10 min |
| A | O grafo como fonte única, e a gramática | 20 min |
| B | Mapear um projeto real contra o código | 30 min |
| C | Mapear um documento de negócio e ligar ao projeto | 25 min |
| — | Intervalo | 10 min |
| D | O grafo como runtime: warm-up, backlog, realign, drive e `/meta:decide` | 20 min |
| E | Dissecar antes de adotar: o `/meta:dissect` | 25 min |
| F | A forja: forjar um componente do time com o `/meta:forge` | 35 min |
| G | Fechamento e ponte para a aula 6 | 5 min |
| | **Total** | **3 h** |

---

## Bloco 0 — Abertura (10 min)

**Conceito.** Na aula 3 vocês geraram documentos e maquinaria. A pergunta desta aula é: quando uma
sessão nova abre o repositório, **o que ela sabe antes de vocês digitarem?** O passo 0 do `/warm-up`
responde: se existe `.kg.yaml`, ele é lido **primeiro**, antes da prosa. Um repositório sem grafo
faz a sessão adivinhar a partir de texto solto.

**Demo.**

```bash
/warm-up
```

Mostre o passo 0 encontrando os grafos e rodando o radar. Depois abra o grafo de adoção do hub,
`docs/onion/graph/onion-adoption.kg.yaml`, e leia em voz alta a pergunta aberta que a adoção deixou:
**qual é o domínio deste repositório?** Ela está lá desde o dia da adoção, esperando resposta. Hoje
ela é respondida.

---

## Bloco A — O grafo como fonte única, e a gramática (20 min)

**Conceito.** Um `.kg.yaml` é um grafo tipado: **nós** com `node_type:` (o que a coisa é) e
**arestas** com `edge_type:` (como as coisas se relacionam). Há duas camadas. A `audit` registra
conhecimento: `claim`, `evidence`, `decision`, `question`. A `domain` registra o negócio: `entity`,
`state`, `event`, `rule`, `invariant`, `policy`. O radar (`kg-radar.sh`) é `awk`, não um parser de
YAML: ele exige uma chave por linha e reprova contradição estrutural. A gramática inteira, curta,
está em `.claude/rules/kg-grammar.md`, e carrega sozinha quando a sessão toca um `.kg.yaml`.

**Os cinco erros clássicos** (todos da gramática da casa):

| Erro | Por que dói |
|---|---|
| escrever `type:` no lugar de `node_type:`/`edge_type:` | o radar não lê; um grep por `type: REFUTES` devolve zero e a guarda nasce verde e vazia |
| nó recebe `REFUTES` e continua `confirmed` | contradição estrutural: o radar sai 1. Reconcilie para `refuted`/`superseded` |
| objeção que sobrevive modelada como `REFUTES` | objeção que **mata** é `REFUTES`; objeção que **limita** é `CONSTRAINS` |
| data sem aspas (`verified_at: 2026-10-14`) | leitor YAML tipado a lê como data, outro como texto; escreva `"2026-10-14"` |
| `---` separando um cabeçalho do resto | o arquivo vira **dois documentos** YAML; o radar avisa e o `/meta:drive` e o `kg-realign` **recusam** |

**Demo.**

```bash
bash .claude/validation/kg-radar.sh docs/onion/graph/onion-adoption.kg.yaml --integrity --schema
bash .claude/validation/kg-drive-project.sh docs/onion/graph/<um-grafo-com-aviso>.kg.yaml
```

Mostre o aviso `⚠ multi-documento: 2 separadores ---` no radar e, logo depois, o `/meta:drive`
recusando o mesmo arquivo com `YAML ilegivel … expected a single document`. É o mesmo defeito
visto por dois leitores: um avisa, o outro trava.

**Exercício.** Consertem todos os grafos do hub que o radar acusa de multi-documento. A cura que o
próprio radar sugere: tirar as linhas `---`. Os campos do cabeçalho viram chaves de topo; nenhum
dado muda.

```bash
for g in $(git ls-files '*.kg.yaml' | grep -v '/fixtures/'); do
  grep -q '^---$' "$g" && echo "multi-documento: $g"
done
# para cada um: apague as linhas que são exatamente '---' (no editor, ou peça à sessão)
```

**Pronto quando:**

```bash
bash .claude/validation/kg-radar.sh <grafo> --integrity --schema   # exit 0 e sem '⚠ multi-documento'
bash .claude/validation/kg-drive-project.sh <grafo>                # imprime 'veredito:' em vez de ERRO
git diff --stat                                                    # só linhas '---' removidas
```

**Erros comuns e saída.**
- *Apagou um `---` que estava dentro de um texto `|`.* O `grep '^---$'` só casa a linha inteira;
  confira no `git diff` que só saíram linhas de separador.
- *O drive agora mostra "bloqueado".* Não é erro: `DEPENDS_ON` é guarda. Leia a aresta: ela sai
  do nó que depende.

---

## Bloco B — Mapear um projeto real contra o código (30 min)

**Conceito.** Um grafo de domínio feito a partir de um documento diz o que alguém **escreveu** que
o sistema faz. Quando o código chega, cada `rule`, `invariant` e `policy` precisa ser conferido
nele, e a âncora (`trace:`) troca do documento para o `arquivo:linha` que executa a regra. Até lá, a
confiança fica abaixo de 1. Re-verificar contra o vivo é o trabalho do `/meta:kg-freshness`: ele
pega a fila do radar e, para cada nó, mede e **propõe** um veredito (`CONFIRMED`, `DRIFTED`,
`REFUTED`, `UNVERIFIABLE`). Quem sela é a pessoa.

**Duas trilhas, conforme o que o projeto já tem:**

- **Trilha 1, o projeto já tem grafo de domínio** (feito a partir do documento da feature): re-ancorar.
- **Trilha 2, o projeto não tem grafo:** criar o primeiro, com `/meta:kg map <área>`.

**Demo (trilha 1).** No projeto adotado:

```bash
bash .claude/validation/kg-view.sh docs/onion/graph/<dominio>.kg.yaml --markdown | head -30
grep -nE '^\s+trace:' docs/onion/graph/<dominio>.kg.yaml        # para onde as âncoras apontam
bash .claude/validation/kg-radar.sh docs/onion/graph/<dominio>.kg.yaml --domain
```

Mostre a composição (quantas `rule`, quantas `question`), as âncoras todas em `docs/` e o
radar-de-domínio apontando lacunas, como um estado absorvente (um estado em que se entra e de onde
não se sai: é fim legítimo ou limbo?). Depois procure uma regra no código, ao vivo:

```bash
grep -rn '<termo da regra>' apps/ packages/ | head
```

**Demo (trilha 2).**

```bash
/meta:kg map <área do sistema>
```

O modo `map` faz inventário, fatias de domínio e grafo, e fecha com o radar.

**Exercício.** Cada dupla pega **três** nós `rule`/`invariant`/`policy` e, para cada um:

1. acha o código que executa a regra (`grep -rn`; o número da linha sai do `grep -n`, nunca de
   contar na tela);
2. troca o `trace:` para `apps/<…>/<arquivo>:<linha>`;
3. atualiza `verified_at: "<data de hoje>"` e `verified_against:` com o que foi lido;
4. se o código **não** faz o que o rótulo diz: muda o `status` para `drifted` e escreve o porquê;
   se não achou o código: deixa a regra como está e cria um nó `question` ligado a ela.

Se o grafo tem uma pergunta do tipo "onde fica o código?", respondam-na e reconciliem para `done`.

**Pronto quando:**

```bash
bash .claude/validation/kg-radar.sh docs/onion/graph/<dominio>.kg.yaml --integrity --schema   # exit 0
grep -cE 'trace: (apps|packages)/' docs/onion/graph/<dominio>.kg.yaml                         # >= 3
bash .claude/validation/kg-trace-resolve.sh .                                                 # toda âncora resolve
```

**Erros comuns e saída.**
- *Linha citada de cabeça.* Ela erra por uma ou duas e a âncora aponta para outra coisa. Copie o
  `arquivo:linha` da saída do `grep -n`.
- *Subir a `confidence` para 1 só porque achou o arquivo.* Achar o arquivo não é ler a regra. Suba
  só depois de conferir que o código faz o que o rótulo diz.
- *`REFUTES` num nó que segue `confirmed`.* O radar sai 1. Mude o status junto com a aresta.

---

## Bloco C — Mapear um documento de negócio e ligar ao projeto (25 min)

**Conceito.** Os documentos das aulas 2 a 4 (personas, estratégia, features, decisões de trabalho)
são prosa. Prosa não tem confiança, não tem dono e não avisa quando caduca. Levá-los ao grafo dá a
cada afirmação um tipo, uma confiança e uma ligação com o que ela afeta. Uma regra boa para a
confiança: **o que o cliente confirmou** pode ser `confirmed`; **decisão de trabalho da equipe**
("inferimos isto") é `decision` `open` com `confidence` menor; **palpite** é ainda menor; **o que
depende de informação que só o cliente tem** é `question`.

**Demo.** Achar o documento que nenhum grafo cita:

```bash
for d in $(git ls-files 'docs/business-context/*.md'); do
  n=$(grep -l "$(basename "$d")" $(git ls-files '*.kg.yaml' | grep -v '/fixtures/') | wc -l)
  [ "$n" -eq 0 ] && echo "sem grafo: $d"
done
```

Mostre um nó de decisão de trabalho bem escrito (com `narrative:` para o porquê, porque o `label`
tem teto de 280 caracteres):

```yaml
  - id: D_LOGIN_OIDC_ANY_IDP
    node_type: decision
    plane: DEV
    status: open
    impact: 4
    confidence: 0.6
    verified_at: "2026-10-14"
    verified_against: doc-de-decisoes-da-feature-secao-1-marca-INFERIDO
    trace: apps/<servico>/src/auth.ts
    label: "Decisão de trabalho: login por qualquer IdP OIDC; o serviço não guarda senha."
    narrative: "Marcada [INFERIDO] no documento: a equipe decidiu, o cliente não confirmou."

edges:
  - from: D_LOGIN_OIDC_ANY_IDP
    to: PO_ACCESS_BY_PROFILE
    edge_type: CONSTRAINS
```

**Exercício.** Duas trilhas, a dupla escolhe:

- **No projeto:** mapear o documento de decisões ou hipóteses da feature (se existir) no grafo de
  domínio do projeto. Uma decisão por nó; confiança pela marca do documento; `trace:` para o código
  quando o documento diz onde está; arestas `CONSTRAINS`/`SUPPORTS`/`DEPENDS_ON` para as regras que
  ela afeta.
- **No hub:** responder a pergunta do grafo de adoção ("qual é o domínio deste repositório?").
  Criem `docs/onion/graph/<tema>.kg.yaml` a partir de um documento de negócio da aula 2 (estratégia
  ou personas são bons pontos de partida) e reconciliem a pergunta do grafo de adoção para `done`,
  com `verified_against` apontando o grafo novo.

**Pronto quando:**

```bash
bash .claude/validation/kg-radar.sh <grafo> --integrity --schema      # exit 0
grep -c '<nome-do-documento>' <grafo>                                 # >= 1: o documento está no grafo
bash .claude/validation/kg-backlog-project.sh --markdown | head -20  # as perguntas novas aparecem
```

**Erros comuns e saída.**
- *Tudo vira `confirmed`.* Decisão de trabalho não confirmada pelo cliente não é fato. O backlog
  existe para mostrar o que espera confirmação: se tudo for `confirmed`, a fila mente.
- *Label-parágrafo.* Passou de 280 caracteres, o porquê vai para `narrative:`.
- *Id com ponto ou hífen.* Só `[A-Za-z0-9_]`; o radar reprova o resto.
- *Ligar ao grafo de outro repositório.* `external_edges:` liga grafos **do mesmo repositório**.
  Ligar o hub ao projeto é assunto da aula 6.

---

## Intervalo (10 min)

---

## Bloco D — O grafo como runtime (20 min)

> **Pré-requisito deste bloco, do E e do F:** o hub num pin **≥ 6e6deab1c443 (onion-v1.2.0)**, que já traz o `/meta:decide`
> e o `/meta:forge` abertos para o papel hub. Confira com `cat .claude/.onion-version` e
> `ls .claude/commands/meta/decide.md .claude/validation/kg-decide-seal.sh`.

**Conceito.** Um grafo que só se lê na hora de escrever é documentação. Aqui ele **dirige** o
trabalho: o `/warm-up` e o `/catch-up` o leem para abrir a sessão; o `/meta:backlog` projeta os nós
`open` numa fila única, ordenada por atenção (impacto × incerteza × status); o `/meta:realign`
confere se o plano ainda está alinhado (aligned) com o vivo, em três camadas (passado, presente, futuro); o
`/meta:drive` conduz o plano nó a nó, a partir da fila pronta. A **decisão** também mora no grafo, e
quem a fecha é o `/meta:decide`: ele mede o que está em voo, tira o que a sessão pode medir sozinha,
pergunta o resto com opções e sela cada resposta no nó. Ninguém edita o selo à mão.

**Demo 1: a fila e o plano.**

```bash
bash .claude/validation/kg-backlog-project.sh --markdown | head -40     # a fila inteira, sem escrever arquivo
bash .claude/validation/kg-realign-project.sh docs/onion/graph/<grafo>.kg.yaml
bash .claude/validation/kg-drive-project.sh docs/onion/graph/<grafo>.kg.yaml
bash .claude/validation/kg-console.sh docs/onion/graph/<grafo>.kg.yaml > kg-console.html   # abra no navegador; não commite
```

No realign, mostre o **commitment-drift**: pergunta aberta de alto impacto sem nada que a apoie,
com o radar perguntando "abandonado?". No drive, mostre a fila pronta e os bloqueados.

**Demo 2: decidir com o `/meta:decide`.** O comando tem quatro movimentos, e vale mostrá-los um a um:

1. **Medir.** Na carga ele roda o censo do que está em voo (checkpoints, PRs e CI, worktrees,
   inbox, nós citados). Para ver o mesmo censo fora do comando:

   ```bash
   bash .claude/validation/decide-census.sh . --markdown
   printf '%s' "<texto que cita os ids>" | bash .claude/validation/decide-census.sh . --markdown --cite -
   ```

   Os avisos (sem `gh`, teto atingido) vêm antes das linhas: ausência de linha com aviso não é zero.
2. **Filtrar.** O que é medível, a sessão mede; o que deriva de decisão já selada, ela aplica; o que
   é de outro dono (outro repositório, merge, deploy), ela encaminha. Só sobra o que é de quem decide.
3. **Perguntar com opções.** Até 4 perguntas por rodada, 2 a 4 opções cada, a recomendada primeiro
   com o porquê, e cada opção dizendo o custo e o que destrava. Faltou base: uma opção é "pesquisar
   antes".
4. **Selar.** Cada resposta vira selo no nó **antes** da rodada seguinte, sempre pelo selador:

   ```bash
   bash .claude/validation/kg-decide-seal.sh <grafo> <NODE_ID> \
     --chosen "<opção escolhida>" --rejected "<a|b>" --date <AAAA-MM-DD> --question "<a pergunta>"
   ```

   Ele grava `status: done`, `plane: DEV`, a proveniência de testemunho e, na `narrative`, a opção
   escolhida e as descartadas. Sai **0** só com o radar `--integrity --schema` em 0; **2** quando
   recusou sem escrever nada (nó inexistente, já `done`, campo cego); **3** quando o radar reprovou e
   a escrita foi **desfeita**.

**Exercício.**

1. Rodem o `/meta:backlog` e escolham **um** item que vocês podem decidir hoje.
2. Rodem `/meta:decide` citando esse item. Respondam a rodada de perguntas.
3. Confiram no `git diff` o que o selador escreveu no nó (status, proveniência, opções na narrative).
4. Rodem o realign e o drive no grafo que mudou.

**Pronto quando:**

```bash
git diff --stat                                                                   # só o grafo do item mudou
bash .claude/validation/kg-radar.sh <grafo> --integrity --schema                  # exit 0
bash .claude/validation/kg-backlog-project.sh --markdown | grep -c '<ID_DO_NO>'   # 0: saiu da fila
bash .claude/validation/kg-realign-project.sh <grafo> --check                     # exit 0
```

**Erros comuns e saída.**
- *Editar o nó à mão para "adiantar".* O selo diz quem decidiu, quando, e o que foi descartado. Use
  o selador; se ele recusou (rc 2) ou desfez (rc 3), leia a mensagem e conserte a causa.
- *Responder pela pessoa que decide.* O `/meta:decide` não decide por ninguém e não sela o que não
  foi perguntado. Se a decisão é de outra pessoa (do cliente, por exemplo), ela fica `open` e a
  rodada registra de quem depende.
- *O radar avisa `decision-done-em-DEV`.* Depende do pin: o selo fica em `DEV` de propósito, porque
  é testemunho e não medição. Não passem o nó para `PROD` para calar o aviso: o motor acusa
  testemunho em `PROD` como `MISPLANED`.
- *Editar `docs/backlog.md` à mão.* É projeção: feche o nó no grafo e regenere. Se vocês
  commitarem `docs/backlog.md`, a REGRA 62 (Projeção GERADA em sincronia com a fonte
  (docs/backlog.md)) passa a cobrar que ele bata com a fonte; regenerem com `/meta:backlog`.
- *O drive para em `CHECKPOINT-PENDENTE`.* É de propósito: um lote anterior espera selo. O selo de
  checkpoint é do drive (`kg-drive-project.sh <grafo> --seal`), não do selador do decide.

---

## Bloco E — Dissecar antes de adotar: o `/meta:dissect` (25 min)

> **Pré-requisito:** o mesmo pin dos blocos D e F (**≥ 6e6deab1c443 (onion-v1.2.0)**), que traz o `/meta:dissect`
> aberto para o papel hub. Confira com `ls .claude/commands/meta/dissect.md .claude/validation/dissect-census.sh .claude/validation/dissect-plans.sh`.

**Conceito.** Antes de forjar, a pergunta é se alguém lá fora já resolveu a dor. O `/meta:dissect`
mapeia uma ferramenta de terceiro numa **escada de cinco níveis**, e **nível reprovado não sobe**:

| Nível | Pergunta | O que prova a passagem |
|---|---|---|
| **N0 identidade** | o que é, quem mantém, licença, está vivo? | trajetória **datada** (commits, releases), não "é popular" |
| **N1 capacidade** | o que ela faz que o Onion não faz? | os **verbos** da superfície executável (`--help`, API), nunca do marketing |
| **N2 mecanismo** | como faz, e onde mora o determinismo | **comportamento**: rodou, ou leu o código-fonte |
| **N3 transferibilidade** | igual → transfere; diferente → desenha | a régua de transferência aplicada com evidência e refutador |
| **N4 absorção** | o plano: artefato, costura, guarda, bancada | nós `x_absorb_*` no grafo, que o `/meta:forge` lê |

Toda dissecação que chega ao N3 fecha num de **quatro vereditos**, com razão escrita: **absorver**
(o conceito entra no Onion, reescrito na gramática da casa), **costurar** (a ferramenta fica de fora
e entra por adapter), **parquear** (técnica a investigar, **com gatilho nomeado**) ou **rejeitar**
(com a razão datada, para ninguém reabrir). "Interessante" e "vale acompanhar" não são veredito. O
comando **não sela**: ele grava o grafo da dissecação e deixa **1 nó `decision` aberto** por
ferramenta. Quem fecha é o `/meta:decide`, do bloco D.

> **A fronteira.** Ferramenta de terceiro **roda em worktree ou container, nunca na árvore de
> trabalho**. É mecanismo, não disciplina: um refutador com instrução escrita para não escrever
> escreveu em seis arquivos (medido pela casa em 2026-09-20).

**A ferramenta do exercício: `yq`** (o processador de YAML de linha de comando escrito em Go; o repositório e a imagem oficial de container saem do próprio N0, da fonte primária). É plausível para este time: os grafos são YAML, e alguém sempre propõe
"por que não lemos o `.kg.yaml` com `yq` em vez de `awk`?". É pública e roda num container.

**Demo 1: o censo vem primeiro.**

```bash
bash .claude/validation/dissect-census.sh . --markdown
```

Ele lista as dissecações que o corpus já pagou e o nível de cada uma. Ferramenta já dissecada com
carimbo fresco entra no nível **seguinte**, sem repagar. Saída `3` quer dizer "não pude medir".

**Demo 2: dissecar até o N3.**

```bash
/meta:dissect yq --level 3
```

Mostre o N0 (licença e trajetória datadas, da fonte primária), o N1 (os verbos lidos do
`yq --help`) e a parada do N2 para rodar a ferramenta **isolada**:

```bash
docker run --rm -v "$PWD":/workdir:ro <imagem-oficial-do-yq> '.nodes | length' docs/onion/graph/<grafo>.kg.yaml
bash .claude/validation/kg-radar.sh docs/onion/graph/<grafo>.kg.yaml --integrity --schema
```

Montagem `:ro`: o container lê o repositório e não escreve nele. Sem Docker, a alternativa é uma
worktree descartável (`git worktree add ../dissect-yq` e rodar lá dentro).

**Exercício.**

1. Rodem o censo e confiram se o `yq` (ou a ferramenta que a dupla escolher) já foi dissecado.
2. Rodem `/meta:dissect yq --level 3`. No N2, meçam o **comportamento**, sem confiar no que a
   documentação diz:
   - a contagem de nós que o `yq` devolve bate com a do `kg-view.sh`?
   - como o `yq` lê uma chave `on:` e uma data sem aspas? A gramática da casa explica por que isso
     importa: dois leitores discordando do mesmo byte foi o que fez a chave `on:` virar `trigger:`.
3. Leiam o veredito e o nó `decision` aberto no grafo que o comando gravou.
4. Fechem a decisão com `/meta:decide`, citando o id desse nó.
5. **Só se o veredito for absorver ou costurar:** rodem de novo com `--level 4` para gerar o plano
   de absorção (os nós `x_absorb_*`) e confiram o plano com o leitor da forja.

**Pronto quando:**

```bash
bash .claude/validation/dissect-census.sh . --markdown | grep -i yq             # a dissecação aparece, com o nível
bash .claude/validation/kg-radar.sh docs/evolution/dissect/<ferramenta>-<AAAA-MM>/<ferramenta>-<AAAA-MM>.kg.yaml --integrity --schema   # exit 0
grep -c 'x_dissect_verdict:' docs/evolution/dissect/<ferramenta>-<AAAA-MM>/<ferramenta>-<AAAA-MM>.kg.yaml   # >= 1
git status --short                                                              # nada fora do grafo da dissecação e do selo
# só com absorver/costurar, depois do --level 4:
bash .claude/validation/dissect-plans.sh . yq                                   # rc 0 = plano completo
```

**Erros comuns e saída.**
- *Rodar a ferramenta na árvore de trabalho "só para ver".* É exatamente o que a fronteira proíbe.
  Container com montagem `:ro` ou worktree descartável; depois, `git status` limpo.
- *N2 tirado da página do produto.* Página é fonte de N0 e N1. Sem rodar nem ler o código, o nó
  fica `open` com a lacuna nomeada: "não pude medir" é resultado.
- *Parquear sem gatilho.* Parque sem gatilho é cemitério. Escrevam o que reabre a questão.
- *Pular para o N4 com uma ferramenta que vai ser rejeitada.* O default `--level 3` existe para não
  gastar o plano de absorção à toa.
- *`dissect-plans.sh` sai 1.* O plano está INCOMPLETO, e a mensagem diz o motivo: falta origem
  **com pin** (sha ou tag), licença, forma (`reescrita`, `adapter-sdaal`, `vendor-pin`) ou a família
  de paridade. Plano incompleto não se forja; volte ao dissect.
- *Vendorizar código proprietário.* `x_absorb_form: vendor-pin` só para licença que o permita;
  proprietário nunca.

**A ponte para a forja.** Se o veredito foi absorver ou costurar, o `/meta:forge` do bloco F **não
começa pela entrevista**: ele lê os planos `x_absorb_*` na carga, mede no censo as peças que o alvo
já tem e forja só as que faltam. Se foi parquear ou rejeitar, a dupla forja a partir de uma dor
medida, como no bloco F.

---

## Bloco F — A forja: forjar um componente do time (35 min)

**Conceito.** Um comando que só tem o arquivo `.md` é uma instrução solta. Um **comando-com-framework**
tem o conjunto inteiro, as **7 peças** da doutrina da forja
(`.claude/commands/common/prompts/forge-doctrine.md`):

| # | Peça | Onde vive | Se faltar |
|---|---|---|---|
| 1 | superfície invocável | `.claude/skills/<n>/SKILL.md` | o poder existe e ninguém alcança |
| 2 | doutrina reutilizável | `.claude/commands/common/prompts/<n>-doctrine.md` | a doutrina se duplica e diverge |
| 3 | contexto medido injetado | diretiva de injeção com o medidor, na superfície | o modelo responde de memória o que um `ls` responde |
| 4 | orquestração faseada | `.claude/workflows/<n>.js` | a coordenação vira prosa e não retoma |
| 5 | destino do que se produz | fase final no grafo + `kg-radar` | a síntese evapora entre sessões |
| 6 | lente/guarda | `.claude/rules/<n>-lens.md` com `paths:` | a doutrina fica escrita e nunca é lida |
| 7 | bancada | família `run_<n>_selftests`, casos que reprovam a versão defeituosa | a guarda apodrece verde |

O `/meta:forge` é o comando que conduz isso. Ele **emite** as peças 2, 3 e 7, **especifica** as 5 e 6
(com a guarda e o contrato que cada uma exige) e deixa a 1 e a 4 para os moldes próprios
(`/meta:create-skill` ou `/meta:create-command`, e o molde de fases da `onion-orchestration`). Três
cláusulas da doutrina importam hoje: **a peça 3 é medida por script**, nunca escrita à mão; **antes de
forjar, meça se já existe**; e **todo caso da bancada tem de reprovar contra o mutante**.

**Demo 1: o censo, o passo 1 do comando.**

```bash
FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown | head -15
```

O `/meta:forge` roda este censo na carga, antes de qualquer pergunta. Leia o cabeçalho (quantos
candidatos, quantos com 6+ peças) e o topo (os que têm 7/7). Diga como o censo mede: **presença e
referência**, nunca qualidade. Peça que existe e a superfície não cita conta como ausente. Se o censo
sair `3`, ele está dizendo que **não pôde medir**: conserte o ambiente antes de seguir.

**Demo 2: medir antes de forjar.** Uma dor que o hub já sentiu: conferir o `.env` sem ler os
segredos. Antes de forjar um verificador, procure:

```bash
grep -rlni 'nunca ler' .claude/utils .claude/validation | head
```

Ele já existe (`.claude/utils/task-manager/env-check.sh`), e nasceu de um sinal do campo. **Forjar
de novo seria duplicar.** É a cláusula 3 acontecendo na frente da turma.

**Se a dupla chegou do bloco E com absorver ou costurar:** a entrada da forja não é a entrevista,
é o plano. O `/meta:forge` lê os nós `x_absorb_*` na carga (pelo `dissect-plans.sh`), mede no censo
as peças que o alvo já tem e emite só as marcadas como faltando. Plano INCOMPLETO não se forja.
A origem e a licença vão no cabeçalho do artefato forjado, e o caso de paridade entra na família
que o plano nomeia. `costurar` vira adapter, nunca cópia. As outras duplas seguem abaixo.

**Exercício: escolher a dor.** Cada dupla escolhe uma dor que **mediu** hoje, não uma que imagina.
Candidatas típicas, todas saídas dos blocos anteriores:

- regras de domínio ancoradas só em documento (bloco B) — o exemplo do que sai, mais abaixo, é esta;
- documentos de negócio que nenhum grafo cita (bloco C);
- perguntas abertas que esperam alguém de fora e não dizem quem (bloco D: o campo `owner:` existe e
  o backlog já agrupa por ele, então talvez a cura seja **declarar** `owner:`, não forjar nada).

Para a dor escolhida, façam a pergunta da cláusula 3: `grep -rln '<palavra-chave>' .claude/`. Se já
existe, a entrega da dupla é usar o que existe e registrar isso no grafo.

**Exercício: forjar com o `/meta:forge`.** Rodem o comando e sigam os seis passos dele:

1. **Medir.** O censo roda na carga. Anotem a linha do candidato antes de forjar (ele ainda não
   existe, então não aparece: esse é o "antes").
2. **Entrevista da topologia.** O comando pergunta, não assume: qual o gênero (varredura, decisão,
   auditoria, migração), quais fases, o que se produz e para onde vai, de quanto em quanto tempo se
   revisita. Respondam com a dor medida, não com a forma do exemplo. A peça 5 (destino) é exigida de
   todo comando-com-framework; o exemplo abaixo responde "o próprio grafo de domínio".
3. **Emitir** as peças 2, 3 e 7, na ordem em que uma habilita a outra:
   - **2 doutrina** em `.claude/commands/common/prompts/<n>-doctrine.md`, com as cláusulas e **o que
     ela não promete**;
   - **3 medidor** em `.claude/validation/<n>-census.sh`, determinístico, que descobre por
     referência e declara as saídas (`0` medido, `1` reprova no `--strict`, `2` uso inválido, `3`
     nada a medir);
   - **7 bancada** como família `run_<n>_selftests`, um caso por saída.

   As peças 5 e 6 saem **especificadas**: a dupla escreve a lente (`.claude/rules/<n>-lens.md`, com
   `paths:` que casa arquivo rastreado) e a fase de destino seguindo a especificação que o comando
   imprime. A superfície (peça 1) sai do `/meta:create-skill`.
4. **Ligar.** A superfície cita **todas** as peças pelo caminho, e as peças entram no índice
   (`git add`). O censo lê `git ls-files`: o que não está no índice não existe para ele, nem para a
   sessão de outra pessoa.
5. **Dogfood.** Rodem o artefato de verdade: invoquem a skill numa sessão e rodem o medidor contra o
   grafo real, **e** o modo de falha (grafo sem regras, argumento errado). Lint verde não é dogfood.
6. **Gate com mutante.** Lint com 0 HARD, a família nova verde, e o mutante de cada caso provado:
   copiem o medidor, estraguem **uma** linha que importa e rodem a bancada contra a cópia.

   ```bash
   sed 's/? "codigo" : "documento")/? "codigo" : "codigo")/' \
     .claude/validation/domain-anchor-census.sh > mutant.sh
   diff .claude/validation/domain-anchor-census.sh mutant.sh   # TEM de mostrar 1 linha; vazio = mutante igual
   bash .claude/validation/domain-anchor-selftest.sh ./mutant.sh   # TEM de reprovar
   rm mutant.sh
   ```

**Pronto quando:**

```bash
bash .claude/validation/lint-selftest.sh --families <n_com_underscore>   # a família nova, toda verde
bash .claude/validation/<n>-selftest.sh ./mutant.sh              # pelo menos 1 ❌ (e exit 1)
FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown | grep '<n>'   # 6/7 (só a peça 4 ausente)
bash .claude/validation/lint-artifacts.sh                        # 0 HARD
```

> **6/7, não 5/7.** No ensaio deste material, feito sem o comando, a bancada ficou num script
> próprio e o censo a contou como ausente: ele só reconhece bancada registrada como família
> `run_<n>_selftests` dentro do `lint-selftest.sh`. Com o `/meta:forge`, a peça 7 já nasce como
> família, e o esperado é **6/7**, com a peça 4 (workflow) ausente por desenho. O custo fica
> declarado: o `lint-selftest.sh` é arquivo do framework, e a família nova é uma customização local
> dele. Na próxima atualização ela vira conflito de merge, real e resolvível, e não sobrescrita
> silenciosa. Se a versão do comando que vocês têm emitir a bancada de outro jeito, o censo é quem
> diz: confiem nele, não neste parágrafo.

**Erros comuns e saída.**
- *Responder a entrevista com a forma do exemplo.* A forja pergunta a topologia porque cada dor tem
  a sua. Copiar o `domain-anchor` para uma dor diferente petrifica a forma de um caso só.
- *O censo não mostra a skill.* Ela não está no índice: `git add` antes de medir.
- *O medidor sai 1 no caso bom.* Sob `set -e` e `pipefail`, um `grep -v` sem saída devolve 1 e mata
  o script. Proteja com `{ grep -v … || true; }`. (Foi o que a bancada do exemplo pegou no primeiro
  ensaio.)
- *O mutante passa.* Ou o `sed` não casou (o `diff` sai vazio e a cópia é idêntica), ou a bancada
  não testa a linha que vocês estragaram. Os dois aconteceram no ensaio do exemplo.
- *Lint acusa inventário.* A REGRA 8 (Inventário canônico sincronizado com o filesystem) cobra a
  contagem nova de skills: rodem `/meta:inventory` e commitem junto.
- *Lint acusa a lente.* A REGRA 53 (Regra path-scoped declara `paths:` que casa algo real) exige
  `paths:` com um glob que case arquivo rastreado.

---

## Bloco G — Fechamento e ponte para a aula 6 (5 min)

Cada dupla mostra, em um minuto: o grafo consertado, as três âncoras no código, o documento ligado,
a dissecação com o veredito selado e a skill forjada com o censo.

**A ponte.** Tudo o que fizemos hoje mora **num repositório só**. O hub tem grafo, o projeto tem
grafo, e eles ainda não se falam: `external_edges:` liga grafos do mesmo repositório, e a skill
forjada no projeto ainda não chega aos outros projetos. A aula 6 junta as pontas: o hub como Company
Brain, os projetos ligados a ele, o caminho de um componente que nasceu num projeto subir para o hub
e descer para os outros, e o caminho de um achado do time (como o custo de a bancada viver num arquivo do framework, acima) chegar ao
core.

Para casa: `/onion-retro` para registrar a aula, e cada dupla deixa o seu PR aberto com os cinco
"prontos" no corpo.

---

## Gabarito da forja: a skill `domain-anchor`

É o exemplo do que sai de uma forja, não um molde para copiar: a dor de cada dupla decide a forma.
A dor: num projeto real, as regras de domínio do grafo apontavam todas para o documento da feature,
e nenhuma para o código, que já estava no repositório. A skill mede isso e conduz a re-ancoragem.
Ensaiada em 2026-10-14, à mão e antes de o `/meta:forge` viajar para o hub, contra uma cópia de um
grafo real e contra uma cópia do framework: bancada 6 ✅, mutante reprovado, censo 5/7 (a bancada
estava fora do `lint-selftest.sh`; com o comando, ela nasce como família e o esperado é 6/7).

### Peça 3 — `.claude/validation/domain-anchor-census.sh`

```bash
#!/usr/bin/env bash
# domain-anchor-census.sh — regra de domínio ancorada em DOCUMENTO é promessa; em CÓDIGO, é fato.
#
# Mede, nos nós rule/invariant/policy de um ou mais .kg.yaml, para onde o `trace:` aponta:
#   codigo    — caminho que casa DOMAIN_ANCHOR_CODE_RE (default: apps/ packages/ src/ lib/ services/)
#   documento — qualquer outro caminho (docs/…)
#   sem-trace — o nó não declara âncora
# Uso : domain-anchor-census.sh <grafo.kg.yaml>... [--strict] [--tsv]
# Exit: 0 medido · 1 (--strict) há regra ancorada só em documento ou sem âncora
#       2 uso inválido / arquivo ausente · 3 nada a medir (zero regras NÃO é resultado)
set -euo pipefail
export LC_ALL=C

strict=0; tsv=0; files=()
for a in "$@"; do
  case "$a" in
    --strict) strict=1 ;;
    --tsv)    tsv=1 ;;
    -*) echo "uso: domain-anchor-census.sh <grafo.kg.yaml>... [--strict] [--tsv]" >&2; exit 2 ;;
    *)  files+=("$a") ;;
  esac
done
[ "${#files[@]}" -gt 0 ] || { echo "uso: domain-anchor-census.sh <grafo.kg.yaml>... [--strict] [--tsv]" >&2; exit 2; }

CODE_RE="${DOMAIN_ANCHOR_CODE_RE:-^(apps|packages|src|lib|services)/}"
rows=""
for f in "${files[@]}"; do
  [ -f "$f" ] || { echo "arquivo ausente: $f" >&2; exit 2; }
  rows+="$(awk -v code_re="$CODE_RE" -v src="$f" '
    function flush() {
      if (id != "" && (nt == "rule" || nt == "invariant" || nt == "policy")) {
        k = (tr == "") ? "sem-trace" : ((tr ~ code_re) ? "codigo" : "documento")
        printf "%s\t%s\t%s\t%s\t%s\n", k, nt, id, tr, src
      }
      id = ""; nt = ""; tr = ""
    }
    /^  - id:/    { flush(); id = $3; next }
    /^  - from:/  { flush(); next }
    /^[a-z_]+:/   { flush(); next }
    id != "" && /^    node_type:/ { nt = $2 }
    id != "" && /^    trace:/     { tr = $2; gsub(/["\047]/, "", tr) }
    END { flush() }' "$f")"$'\n'
done
rows="$(printf '%s' "$rows" | grep -v '^$' || true)"

[ -n "$rows" ] || { echo "domain-anchor: nenhum nó rule/invariant/policy nos grafos dados — nada a medir. Recusa." >&2; exit 3; }

if [ "$tsv" -eq 1 ]; then printf '%s\n' "$rows"; else
  n_code=$(printf '%s\n' "$rows" | grep -c '^codigo'    || true)
  n_doc=$(printf '%s\n' "$rows"  | grep -c '^documento' || true)
  n_none=$(printf '%s\n' "$rows" | grep -c '^sem-trace' || true)
  echo "# âncora das regras de domínio · codigo=${n_code} · documento=${n_doc} · sem-trace=${n_none}"
  # `|| true`: sem nenhuma pendência o grep -v sai 1, e sob pipefail + set -e isso MATAVA o medidor
  # com rc=1 no caso bom (achado pela bancada no 1º ensaio).
  printf '%s\n' "$rows" | { grep -v '^codigo' || true; } | awk -F'\t' '{printf "  - [%s] %s `%s` → %s\n", $1, $2, $3, ($4 == "" ? "(sem trace)" : $4)}'
fi

if [ "$strict" -eq 1 ] && printf '%s\n' "$rows" | grep -qv '^codigo'; then exit 1; fi
exit 0
```

### Peça 7 — `.claude/validation/domain-anchor-selftest.sh`

Com o `/meta:forge`, a bancada entra como a família `run_domain_anchor_selftests` no
`lint-selftest.sh`; o script abaixo é o corpo dos casos, e a família pode simplesmente chamá-lo.

```bash
#!/usr/bin/env bash
# domain-anchor-selftest.sh — bancada do domain-anchor-census.sh.
# Todo caso tem de REPROVAR contra a versão defeituosa (o mutante). Caso que passa nos dois é decorativo.
# Uso: domain-anchor-selftest.sh [<medidor>]   (default: o medidor ao lado deste arquivo)
set -uo pipefail
export LC_ALL=C
M="${1:-$(dirname "$0")/domain-anchor-census.sh}"
[ -f "$M" ] || { echo "medidor ausente: $M" >&2; exit 2; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
check() {  # $1=nome  $2=rc esperado  $3=rc obtido
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "  ✅ $1"; else fail=$((fail+1)); echo "  ❌ $1 (esperado rc=$2, veio rc=$3)"; fi
}
node() {  # $1=id $2=node_type $3=trace (vazio = sem trace)
  printf '  - id: %s\n    node_type: %s\n    status: open\n' "$1" "$2"
  [ -n "$3" ] && printf '    trace: %s\n' "$3"
  return 0
}
{ echo "nodes:"; node RU_A rule "apps/api/src/x.ts:10"; echo "edges:"; echo "  - from: RU_A"; } > "$T/code.kg.yaml"
{ echo "nodes:"; node RU_A rule "apps/api/src/x.ts:10"; node RU_B rule "docs/business-context/f.md:3"; } > "$T/doc.kg.yaml"
{ echo "nodes:"; node PO_A policy ""; } > "$T/none.kg.yaml"
{ echo "nodes:"; node EN_A entity "docs/x.md"; } > "$T/empty.kg.yaml"

bash "$M" "$T/code.kg.yaml" --strict >/dev/null 2>&1;  check "regra ancorada em código passa no --strict" 0 $?
bash "$M" "$T/doc.kg.yaml"  --strict >/dev/null 2>&1;  check "regra ancorada só em documento reprova no --strict" 1 $?
bash "$M" "$T/none.kg.yaml" --strict >/dev/null 2>&1;  check "política sem trace reprova no --strict" 1 $?
bash "$M" "$T/empty.kg.yaml"         >/dev/null 2>&1;  check "grafo sem regra recusa (exit 3, nunca zero silencioso)" 3 $?
bash "$M" --bogus                    >/dev/null 2>&1;  check "argumento desconhecido recusa (exit 2)" 2 $?
bash "$M" "$T/nao-existe.kg.yaml"    >/dev/null 2>&1;  check "arquivo ausente recusa (exit 2)" 2 $?
echo "# bancada domain-anchor: ${pass} ✅ · ${fail} ❌"
[ "$fail" -eq 0 ]
```

### Peça 2 — `.claude/commands/common/prompts/domain-anchor-doctrine.md`

```markdown
# Doutrina da âncora de domínio

Fragmento canônico. A skill `domain-anchor` referencia este arquivo; ninguém o copia.

## As três cláusulas

1. **Regra ancorada em documento é promessa.** Um nó `rule`, `invariant` ou `policy` cujo `trace:`
   aponta para `docs/` diz o que alguém escreveu que o sistema faz. Só a âncora no código diz o que
   ele faz. Enquanto a âncora for documento, a `confidence` fica abaixo de 1.
2. **A âncora se mede, não se lembra.** O estado entra na sessão pelo medidor
   (`.claude/validation/domain-anchor-census.sh`), e a linha do código sai de `grep -n`.
3. **Não achar o código é resultado.** Regra sem código vira pergunta aberta. Âncora inventada
   para o medidor passar é pior que âncora ausente, porque mente para quem volta ao porquê.

## O que esta doutrina NÃO promete

O medidor confere para ONDE a âncora aponta, não se o código faz o que a regra diz, nem se o
arquivo existe (isso é do `kg-trace-resolve.sh`). Ler o código e julgar continua sendo trabalho
de gente.
```

### Peça 6 — `.claude/rules/domain-anchor-lens.md`

```markdown
---
paths:
  - "docs/onion/graph/*.kg.yaml"
---

# Lente da âncora de domínio — carrega quando você toca um grafo

Ao escrever ou mudar um nó `rule`, `invariant` ou `policy`, a âncora (`trace:`) aponta para o
código que executa a regra, como `arquivo:linha` tirado de `grep -n`. Se só existe o documento,
deixe a `confidence` abaixo de 1 e diga isso no `verified_against`.

Doutrina: `.claude/commands/common/prompts/domain-anchor-doctrine.md`.
Medir: `bash .claude/validation/domain-anchor-census.sh <grafo>`.
```

### Peça 1 — `.claude/skills/domain-anchor/SKILL.md`

```markdown
---
name: domain-anchor
description: >
  Mede para onde apontam as âncoras das regras de domínio do grafo (rule, invariant, policy):
  código, documento ou nada. Use ao revisar um grafo de domínio, antes de implementar uma regra,
  ou quando alguém perguntar "essa regra já está no código?", "o grafo bate com o sistema?".
  Ative mesmo sem a palavra "âncora".
---

# domain-anchor — regra ancorada em documento é promessa; em código, é fato

Doutrina: [`domain-anchor-doctrine.md`](../../commands/common/prompts/domain-anchor-doctrine.md).
Lente que carrega ao tocar um grafo: `.claude/rules/domain-anchor-lens.md`.

## Estado medido agora (o medidor roda antes de você pensar)

!`bash .claude/validation/domain-anchor-census.sh docs/onion/graph/*.kg.yaml || true`

## Procedimento

1. Leia o estado acima. Cada linha `[documento]` ou `[sem-trace]` é uma regra que ninguém conferiu
   no sistema.
2. Para cada uma, ache o código que a executa por `grep -rn '<termo da regra>' apps/ packages/`.
   O número da linha sai do `grep -n`, nunca da contagem visual.
3. Achou: troque o `trace:` para `arquivo:linha`, atualize `verified_at` e `verified_against`,
   e suba a `confidence` só se o código faz o que o rótulo diz.
4. Não achou: a regra continua `open`, ou vira `question` ("onde isso é aplicado?"). Nunca invente
   a âncora para o medidor ficar verde.
5. Feche com `bash .claude/validation/kg-radar.sh <grafo> --integrity --schema` (exit 0) e com o
   medidor de novo. Bancada: `bash .claude/validation/domain-anchor-selftest.sh`.
```

A peça 5 (destino) é o próprio grafo de domínio: a skill não produz um relatório à parte, ela muda
as âncoras no grafo e fecha com o radar. A peça 4 (workflow) não entra: a re-ancoragem cabe numa
sessão, e um workflow faseado só se paga quando houver dezenas de regras por grafo.

---

## Roteiro do instrutor

**Antes (30 min, no dia).** Rode a medição da turma no hub e no projeto e preencha a ficha. Ensaie o
bloco A num grafo com aviso de multi-documento (se não houver nenhum, use o bloco A só como leitura
da gramática e ganhe 10 minutos para o bloco F). Confira que o PyYAML está instalado nas máquinas.

**O que dizer, bloco a bloco.**

- **0.** "Quando uma sessão nova abre este repositório, o que ela sabe antes de vocês falarem?"
  Mostre a pergunta aberta do grafo de adoção. É o gancho da aula inteira.
- **A.** "O radar é `awk`, não um leitor de YAML. Ele é rígido de propósito: o que ele não lê,
  ninguém lê do mesmo jeito." Mostre o aviso e a recusa do drive lado a lado.
- **B.** "Documento diz o que alguém escreveu que o sistema faz. Código diz o que ele faz." O
  momento forte é achar, ao vivo, uma regra no código que **não** bate com o documento.
- **C.** "Decisão de trabalho não é fato." Mostre como a confiança muda com a marca do documento.
- **D.** "O backlog não é uma lista: é uma projeção do grafo. Feche o nó e o item some sozinho."
- **E.** "Antes de construir, veja se alguém já resolveu, e prove pelo comportamento." O momento
  forte é o N2: a ferramenta rodando num container somente-leitura, e a medição discordando (ou não)
  do que a documentação dela promete.
- **F.** "Antes de forjar, procure." A demo do `env-check.sh` abre o bloco: a dor era real,
  e a cura já existia.
- **G.** "Hoje cada repositório tem o seu grafo. Na próxima aula eles passam a conversar."

**Onde costuma travar.**

| Ponto | Sintoma | Saída |
|---|---|---|
| bloco A | apagaram um `---` dentro de texto | `git diff` e restaurar a linha |
| bloco B | não acham a regra no código | é resultado: vira `question`, não âncora inventada |
| bloco B | `kg-trace-resolve.sh` reprova | a âncora aponta para arquivo que não existe; confiram o caminho relativo à raiz |
| bloco C | nós longos demais | `label` curto, o resto em `narrative:` |
| bloco D | querem selar decisão do cliente | não selem; escrevam de quem depende |
| bloco E | sem Docker na máquina | worktree descartável; nunca rodar na árvore de trabalho |
| bloco E | veredito "interessante" | não é veredito: escolham um dos quatro, com razão escrita |
| bloco E | `dissect-plans.sh` sai 1 | falta pin na origem, licença, forma ou família de paridade |
| bloco F | censo sem a skill | faltou `git add` |
| bloco F | mutante passa | `diff` vazio ou bancada sem o caso daquela linha |
| bloco F | lint com HARD de inventário | `/meta:inventory` e commitar junto |

**Se o tempo apertar.** Corte o bloco C para a trilha do projeto só; no bloco E, parem no N1 e
deixem o N2 em container de lição de casa; no bloco F entreguem o
medidor e a bancada (peças 3 e 7); a superfície e a lente ficam de lição de casa.

---

## Cartão-resumo de comandos

| Para quê | Comando |
|---|---|
| achar os grafos | `git ls-files '*.kg.yaml' \| grep -v '/fixtures/'` |
| validar um grafo | `bash .claude/validation/kg-radar.sh <g> --integrity --schema` |
| lacunas do domínio | `bash .claude/validation/kg-radar.sh <g> --domain` |
| frescor | `bash .claude/validation/kg-radar.sh <g> --freshness` |
| âncoras que não resolvem | `bash .claude/validation/kg-trace-resolve.sh .` (o repositório inteiro) |
| ver o grafo | `bash .claude/validation/kg-view.sh <g> --markdown` |
| console visual | `bash .claude/validation/kg-console.sh <g> > kg-console.html` |
| mapear uma área | `/meta:kg map <área>` |
| re-verificar contra o vivo | `/meta:kg-freshness <g>` |
| abrir a sessão pelo grafo | `/warm-up` · `/catch-up` |
| fila de trabalho aberto | `/meta:backlog` · `bash .claude/validation/kg-backlog-project.sh --markdown` |
| o plano ainda está alinhado (aligned)? | `/meta:realign <g>` · `bash .claude/validation/kg-realign-project.sh <g> --check` |
| conduzir o plano | `/meta:drive <g>` · `bash .claude/validation/kg-drive-project.sh <g>` |
| decidir e selar | `/meta:decide` · `bash .claude/validation/decide-census.sh . --markdown` |
| dissecar uma ferramenta | `/meta:dissect <ferramenta> --level 3` · censo: `bash .claude/validation/dissect-census.sh . --markdown` · plano: `bash .claude/validation/dissect-plans.sh . <ferramenta>` |
| forjar | `/meta:forge` · censo: `FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown` |
| criar a superfície | `/meta:create-command` · `/meta:create-skill` |
| gate | `/meta:inventory` · `bash .claude/validation/lint-artifacts.sh` |
| fechar a aula | `/onion-retro` |

---

## Nota para o revisor

**Verificado em 2026-10-14**, no pin `8278fee79d1c` do hub e do projeto que ele adotou:

- os comandos do cartão existem no bundle do hub (`ls .claude/commands/meta/` e
  `ls .claude/validation/`), exceto o `/meta:decide` e o `decide-census.sh`, que chegam com o pin novo;
- o radar avisa `multi-documento` em grafos com cabeçalho `---`, e o `kg-drive-project.sh` recusa o
  mesmo arquivo; sem os `---`, o radar passa limpo e o drive imprime o veredito;
- o `forge-census.sh` roda no hub e mede 59 candidatos;
- o gabarito `domain-anchor` (forjado à mão, sem o comando): bancada 6 ✅; mutante (uma linha
  trocada) reprovado em 1 caso; contra uma cópia de um grafo de domínio real mediu
  `codigo=0 · documento=9`; com as cinco peças no índice de uma cópia do framework, o censo deu
  **5/7** (peças 4 e 7 ausentes, a 7 porque a bancada estava fora do `lint-selftest.sh`).

**Não verificado (fica para o ensaio humano):**

- a skill `domain-anchor` **não** foi instalada no repositório da equipe nem invocada como `/domain-anchor`
  numa sessão real; a diretiva `` !`…` `` foi conferida só pelo censo, não pela carga;
- o lint do hub com as cinco peças novas não rodou; o bloco F prevê o HARD de inventário pela
  REGRA 8, mas o número exato de avisos é do dia;
- se uma skill nova do hub desce para os projetos no `/meta:adopt --update` (o manifesto inclui
  `.claude/skills` inteiro, mas a descida não foi ensaiada) — assunto da aula 6;
- os blocos D, E e F dependem de um pin que ainda não existe (o que abre o `/meta:decide`, o
  `/meta:dissect` e o `/meta:forge` para o hub): o fluxo descrito é o dos comandos no core em
  2026-10-14, e nenhum dos três foi rodado no hub. O 6/7 esperado no bloco F é dedução (a bancada
  nasce como família), não medição;
- o `/meta:dissect` não rodou no hub, e o `yq` não foi dissecado nem executado em container neste
  ensaio: a licença, a trajetória e o comportamento do `yq` são o que o N0 e o N2 do exercício vão
  medir, e o material não antecipa o resultado. O `dissect-plans.sh` não está no pin atual do hub;
- o selo em DEV foi conferido no radar dos dois pins (o do hub avisa `decision-done-em-DEV`; o do
  core aceita o selo de testemunho em DEV e acusa `MISPLANED` em PROD).

**Comandos que dependem do pin novo:** `/meta:decide` (com `decide-census.sh` e
`kg-decide-seal.sh`), o `/meta:dissect` aberto ao hub (com o `dissect-plans.sh`) e a face do
`/meta:forge` aberta ao hub, ambos no pin **≥ 6e6deab1c443 (onion-v1.2.0)**. Fora
do bundle do hub, sem previsão: `kg-contract-check.sh` (o contrato formal do `.kg.yaml` não está
vendorizado no hub).
