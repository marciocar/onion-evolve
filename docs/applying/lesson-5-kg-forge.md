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

No fim da aula, cada dupla sai com quatro coisas **no repositório**, todas conferíveis:

1. **Um grafo que o motor lê.** Os grafos do hub passam no `kg-radar` sem aviso e o `/meta:drive` os aceita.
2. **Um projeto mapeado contra o código.** As regras de domínio de um projeto real apontam para o
   arquivo e a linha que as executam, e não só para o documento que as descreve.
3. **Um documento de negócio ligado ao projeto.** Um documento das aulas 2 a 4 que ainda não estava
   em grafo nenhum vira nós, com a confiança certa, ligados às regras que ele afeta.
4. **Um componente do time forjado.** Uma skill com doutrina, medidor e bancada, nascida de uma dor
   que vocês mediram, e que o censo da forja enxerga.

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

```bash
git status --short                       # árvore limpa (ou um commit WIP antes de começar)
git switch -c lesson-5/<seu-nome>        # cada dupla numa branch própria
cat .claude/.onion-version               # o pin precisa ser o mesmo da turma
ls .claude/validation/kg-radar.sh .claude/validation/forge-census.sh .claude/rules/kg-grammar.md
python3 -c "import yaml" && echo "PyYAML ok"   # o /meta:drive e o kg-realign leem YAML
```

Se o `ls` reclamar de arquivo ausente, o pin está velho: atualizem pelo `/meta:adopt --update`
antes da aula, não durante.

---

## Mapa da aula

| Bloco | Tema | Tempo |
|---|---|---|
| 0 | Abertura: o que a sessão sabe antes de você falar | 10 min |
| A | O grafo como fonte única, e a gramática | 25 min |
| B | Mapear um projeto real contra o código | 35 min |
| C | Mapear um documento de negócio e ligar ao projeto | 30 min |
| — | Intervalo | 10 min |
| D | O grafo como runtime: warm-up, backlog, realign, drive, decisão | 25 min |
| E | A forja: forjar um componente do time | 40 min |
| F | Fechamento e ponte para a aula 6 | 5 min |
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

## Bloco A — O grafo como fonte única, e a gramática (25 min)

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

## Bloco B — Mapear um projeto real contra o código (35 min)

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

## Bloco C — Mapear um documento de negócio e ligar ao projeto (30 min)

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

## Bloco D — O grafo como runtime (25 min)

**Conceito.** Um grafo que só se lê na hora de escrever é documentação. Aqui ele **dirige** o
trabalho: o `/warm-up` e o `/catch-up` o leem para abrir a sessão; o `/meta:backlog` projeta os nós
`open` numa fila única, ordenada por atenção (impacto × incerteza × status); o `/meta:realign`
confere se o plano ainda coere com o vivo, em três camadas (passado, presente, futuro); o
`/meta:drive` conduz o plano nó a nó, a partir da fila pronta. A **decisão** também mora no grafo:
um nó `decision` só fecha quando alguém com autoridade o sela.

**Demo.**

```bash
bash .claude/validation/kg-backlog-project.sh --markdown | head -40     # a fila inteira, sem escrever arquivo
bash .claude/validation/kg-realign-project.sh docs/onion/graph/<grafo>.kg.yaml
bash .claude/validation/kg-drive-project.sh docs/onion/graph/<grafo>.kg.yaml
bash .claude/validation/kg-console.sh docs/onion/graph/<grafo>.kg.yaml > kg-console.html   # abra no navegador; não commite
```

No realign, mostre o **commitment-drift**: pergunta aberta de alto impacto sem nada que a apoie,
com o radar perguntando "abandonado?". No drive, mostre a fila pronta e os bloqueados.

**Como se sela uma decisão aqui.** O `/meta:decide` é do core e não vem no bundle do hub. No hub,
selar é editar o nó e rodar o radar no fim:

```yaml
  - id: D_<DECISAO>
    node_type: decision
    plane: DEV
    status: done
    verified_at: "2026-10-14"
    verified_against: "selo-na-aula-5"
    trace: docs/<onde a decisão foi registrada>.md
    provenance:
      source: "aula 5, decisão de <papel de quem decidiu>"
      locator: "bloco D"
      method: "testemunho: decisão do maestro em 2026-10-14"
    label: "<a decisão, curta>"
```

O texto do `method:` começa **exatamente** com `testemunho: decisão do maestro`: é por ele que o
motor reconhece um selo humano (troque "maestro" só no `source:`). Decisão selada é relato, não
medição, por isso fica em `DEV`. No pin de 2026-10-07 o radar ainda avisa `decision-done-em-DEV`
(aviso, não reprova); a exceção para o selo chega com a próxima atualização. Não passem para
`PROD` para calar o aviso: o motor novo acusa testemunho em `PROD` como `MISPLANED`.

**Exercício.**

1. Rodem o backlog e escolham **um** item que vocês podem decidir hoje.
2. Selem-no no grafo como acima (ou, se a decisão não é de vocês, escrevam no `narrative:` de quem
   ela depende e deixem `open`).
3. Rodem o realign e o drive no grafo que mudou.

**Pronto quando:**

```bash
bash .claude/validation/kg-radar.sh <grafo> --integrity --schema                  # exit 0
bash .claude/validation/kg-backlog-project.sh --markdown | grep -c '<ID_DO_NO>'   # 0: saiu da fila
bash .claude/validation/kg-realign-project.sh <grafo> --check                     # exit 0
```

**Erros comuns e saída.**
- *Editar `docs/backlog.md` à mão.* É projeção: feche o nó no grafo e regenere. Se vocês
  commitarem `docs/backlog.md`, a REGRA 62 (Projeção GERADA em sincronia com a fonte
  (docs/backlog.md)) passa a cobrar que ele bata com a fonte; regenerem com `/meta:backlog`.
- *Selar a decisão de outra pessoa.* O selo diz quem decidiu. Se não foi vocês, não selem.
- *O drive para em `CHECKPOINT-PENDENTE`.* É de propósito: um lote anterior espera selo. Leia a
  `drive_checkpoint_note` no `meta:` do grafo.

---

## Bloco E — A forja: forjar um componente do time (40 min)

**Conceito.** Um comando que só tem o arquivo `.md` é uma instrução solta. Um **comando-com-framework**
tem o conjunto inteiro, as **7 peças** da doutrina da forja
(`.claude/commands/common/prompts/forge-doctrine.md`):

| # | Peça | Onde vive | Se faltar |
|---|---|---|---|
| 1 | superfície invocável | `.claude/skills/<n>/SKILL.md` | o poder existe e ninguém alcança |
| 2 | doutrina reutilizável | `.claude/commands/common/prompts/<n>-doctrine.md` | a doutrina se duplica e diverge |
| 3 | contexto medido injetado | `` !`bash <medidor>` `` na superfície | o modelo responde de memória o que um `ls` responde |
| 4 | orquestração faseada | `.claude/workflows/<n>.js` | a coordenação vira prosa e não retoma |
| 5 | destino do que se produz | fase final no grafo + `kg-radar` | a síntese evapora entre sessões |
| 6 | lente/guarda | `.claude/rules/<n>-lens.md` com `paths:` | a doutrina fica escrita e nunca é lida |
| 7 | bancada | casos que reprovam a versão defeituosa | a guarda apodrece verde |

Três cláusulas que importam hoje: **a peça 3 é medida por script**, nunca escrita à mão; **antes de
forjar, meça se já existe** (a cláusula que mais custou à casa); e **todo caso da bancada tem de
reprovar contra o mutante** (caso que passa nas duas versões é decorativo).

> **Por que forjamos à mão.** O `/meta:forge` se declara core-only, e o grafo de adoção do hub
> registra "não usar aqui". O que viaja e roda no hub é a **doutrina** e o **medidor**
> (`forge-census.sh`). A aula usa os dois e emite as peças à mão, uma por uma. É o mesmo
> procedimento do comando, sem o atalho.

**Demo 1: o censo.**

```bash
FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown | head -15
```

Leia o cabeçalho (quantos candidatos, quantos com 6+ peças) e o topo (os que têm 7/7). Diga como o
censo mede: **presença e referência**, nunca qualidade. Peça que existe e a superfície não cita conta
como ausente.

**Demo 2: medir antes de forjar.** Uma dor que o hub já sentiu: conferir o `.env` sem ler os
segredos. Antes de forjar um verificador, procure:

```bash
grep -rlni 'nunca ler' .claude/utils .claude/validation | head
```

Ele já existe (`.claude/utils/task-manager/env-check.sh`), e nasceu de um sinal do campo. **Forjar
de novo seria duplicar.** É a cláusula 3 acontecendo na frente da turma.

**Exercício: escolher a dor.** Cada dupla escolhe uma dor que **mediu** hoje, não uma que imagina.
Candidatas típicas, todas saídas dos blocos anteriores:

- regras de domínio ancoradas só em documento (bloco B) — o gabarito abaixo é esta;
- documentos de negócio que nenhum grafo cita (bloco C);
- perguntas abertas que esperam alguém de fora e não dizem quem (bloco D: o campo `owner:` existe e
  o backlog já agrupa por ele, então talvez a cura seja **declarar** `owner:`, não forjar nada).

Para a dor escolhida, rodem a pergunta da cláusula 3: `grep -rln '<palavra-chave>' .claude/`. Se já
existe, a entrega da dupla é usar o que existe e registrar isso no grafo.

**Exercício: forjar.** Emitam as peças nesta ordem (uma habilita a outra). O gabarito completo da
skill `domain-anchor` está na próxima seção; usem-no como molde.

1. **Peça 2, doutrina:** `.claude/commands/common/prompts/<n>-doctrine.md`, com as cláusulas **e o
   que ela não promete**.
2. **Peça 3, medidor:** `.claude/validation/<n>-census.sh`, determinístico, com saídas declaradas
   (`0` medido, `1` reprova no `--strict`, `2` uso inválido, `3` nada a medir).
3. **Peça 7, bancada:** `.claude/validation/<n>-selftest.sh`, um caso por saída.
4. **Peça 6, lente:** `.claude/rules/<n>-lens.md`, com `paths:` que casa arquivo rastreado.
5. **Peça 1, superfície:** `.claude/skills/<n>/SKILL.md`, com `` !`bash .claude/validation/<n>-census.sh …` ``
   e citando a doutrina, a lente e o `kg-radar` pelo caminho.
6. **Ligar e conferir:** `git add` das cinco peças (o censo só enxerga o que está no índice), depois
   `/meta:inventory` e o lint.

**O mutante.** Copiem o medidor, estraguem **uma** linha que importa e rodem a bancada contra a cópia:

```bash
sed 's/? "codigo" : "documento")/? "codigo" : "codigo")/' \
  .claude/validation/domain-anchor-census.sh > mutant.sh
diff .claude/validation/domain-anchor-census.sh mutant.sh   # TEM de mostrar 1 linha; vazio = mutante igual
bash .claude/validation/domain-anchor-selftest.sh ./mutant.sh   # TEM de reprovar
rm mutant.sh
```

**Pronto quando:**

```bash
bash .claude/validation/<n>-selftest.sh                         # todos ✅
bash .claude/validation/<n>-selftest.sh ./mutant.sh             # pelo menos 1 ❌ (e exit 1)
FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown | grep '<n>'   # 5/7 ou mais
bash .claude/validation/lint-artifacts.sh                       # 0 HARD
```

**Erros comuns e saída.**
- *O censo não mostra a skill.* Ela não está no índice: `git add` antes de medir. O censo lê
  `git ls-files`, como a sessão de outra pessoa leria.
- *O censo mostra a peça 7 como "—" mesmo com a bancada pronta.* É esperado e honesto: o censo só
  reconhece bancada registrada como família `run_<n>_selftests` dentro de `lint-selftest.sh`, que é
  arquivo do framework. Editá-lo no hub vira conflito na próxima atualização. Deixem a bancada no
  script próprio e aceitem o 5/7. Levar isso ao core é a aula 6.
- *O medidor sai 1 no caso bom.* Sob `set -e` e `pipefail`, um `grep -v` sem saída devolve 1 e mata
  o script. Proteja com `{ grep -v … || true; }`. (Foi o que a bancada do gabarito pegou no
  primeiro ensaio.)
- *O mutante passa.* Ou o `sed` não casou (o `diff` sai vazio e a cópia é idêntica), ou a bancada
  não testa a linha que vocês estragaram. Os dois aconteceram no ensaio deste gabarito.
- *Lint acusa inventário.* A REGRA 8 (Inventário canônico sincronizado com o filesystem) cobra a
  contagem nova de skills: rodem `/meta:inventory` e commitem junto.
- *Lint acusa a lente.* A REGRA 53 (Regra path-scoped declara `paths:` que casa algo real) exige
  `paths:` com um glob que case arquivo rastreado.

---

## Bloco F — Fechamento e ponte para a aula 6 (5 min)

Cada dupla mostra, em um minuto: o grafo consertado, as três âncoras no código, o documento ligado e
a skill forjada com o censo.

**A ponte.** Tudo o que fizemos hoje mora **num repositório só**. O hub tem grafo, o projeto tem
grafo, e eles ainda não se falam: `external_edges:` liga grafos do mesmo repositório, e a skill
forjada no projeto ainda não chega aos outros projetos. A aula 6 junta as pontas: o hub como Company
Brain, os projetos ligados a ele, o caminho de um componente que nasceu num projeto subir para o hub
e descer para os outros, e o caminho de um achado do time (como o "peça 7 invisível" acima) chegar ao
core.

Para casa: `/onion-retro` para registrar a aula, e cada dupla deixa o seu PR aberto com os quatro
"prontos" no corpo.

---

## Gabarito da forja: a skill `domain-anchor`

A dor: num projeto real, as regras de domínio do grafo apontavam todas para o documento da feature,
e nenhuma para o código, que já estava no repositório. A skill mede isso e conduz a re-ancoragem.
Ensaiada em 2026-10-14 contra uma cópia de um grafo real e contra uma cópia do framework: bancada
6 ✅, mutante reprovado, censo 5/7.

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
da gramática e ganhe 10 minutos para o bloco E). Confira que o PyYAML está instalado nas máquinas.

**O que dizer, bloco a bloco.**

- **0.** "Quando uma sessão nova abre este repositório, o que ela sabe antes de vocês falarem?"
  Mostre a pergunta aberta do grafo de adoção. É o gancho da aula inteira.
- **A.** "O radar é `awk`, não um leitor de YAML. Ele é rígido de propósito: o que ele não lê,
  ninguém lê do mesmo jeito." Mostre o aviso e a recusa do drive lado a lado.
- **B.** "Documento diz o que alguém escreveu que o sistema faz. Código diz o que ele faz." O
  momento forte é achar, ao vivo, uma regra no código que **não** bate com o documento.
- **C.** "Decisão de trabalho não é fato." Mostre como a confiança muda com a marca do documento.
- **D.** "O backlog não é uma lista: é uma projeção do grafo. Feche o nó e o item some sozinho."
- **E.** "Antes de forjar, procure." A demo do `env-check.sh` é o centro do bloco: a dor era real,
  e a cura já existia.
- **F.** "Hoje cada repositório tem o seu grafo. Na próxima aula eles passam a conversar."

**Onde costuma travar.**

| Ponto | Sintoma | Saída |
|---|---|---|
| bloco A | apagaram um `---` dentro de texto | `git diff` e restaurar a linha |
| bloco B | não acham a regra no código | é resultado: vira `question`, não âncora inventada |
| bloco B | `kg-trace-resolve.sh` reprova | a âncora aponta para arquivo que não existe; confiram o caminho relativo à raiz |
| bloco C | nós longos demais | `label` curto, o resto em `narrative:` |
| bloco D | querem selar decisão do cliente | não selem; escrevam de quem depende |
| bloco E | censo sem a skill | faltou `git add` |
| bloco E | mutante passa | `diff` vazio ou bancada sem o caso daquela linha |
| bloco E | lint com HARD de inventário | `/meta:inventory` e commitar junto |

**Se o tempo apertar.** Corte o bloco C para a trilha do projeto só, e no bloco E entreguem o
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
| o plano ainda coere? | `/meta:realign <g>` · `bash .claude/validation/kg-realign-project.sh <g> --check` |
| conduzir o plano | `/meta:drive <g>` · `bash .claude/validation/kg-drive-project.sh <g>` |
| censo da forja | `FORGE_CENSUS_TOP=1000 bash .claude/validation/forge-census.sh . --markdown` |
| criar a superfície | `/meta:create-command` · `/meta:create-skill` |
| gate | `/meta:inventory` · `bash .claude/validation/lint-artifacts.sh` |
| fechar a aula | `/onion-retro` |

---

## Nota para o revisor

**Verificado em 2026-10-14**, no pin `8278fee79d1c` do hub e do projeto que ele adotou:

- todos os comandos do cartão existem no bundle do hub (`ls .claude/commands/meta/` e
  `ls .claude/validation/`);
- o radar avisa `multi-documento` em grafos com cabeçalho `---`, e o `kg-drive-project.sh` recusa o
  mesmo arquivo; sem os `---`, o radar passa limpo e o drive imprime o veredito;
- o `forge-census.sh` roda no hub e mede 59 candidatos;
- o gabarito `domain-anchor`: bancada 6 ✅; mutante (uma linha trocada) reprovado em 1 caso; contra
  uma cópia de um grafo de domínio real mediu `codigo=0 · documento=9`; com as cinco peças no índice
  de uma cópia do framework, o censo deu **5/7** (peças 4 e 7 ausentes, pelo motivo dito no bloco E).

**Não verificado (fica para o ensaio humano):**

- a skill `domain-anchor` **não** foi instalada no repositório da equipe nem invocada como `/domain-anchor`
  numa sessão real; a diretiva `` !`…` `` foi conferida só pelo censo, não pela carga;
- o lint do hub com as cinco peças novas não rodou; o bloco E prevê o HARD de inventário pela
  REGRA 8, mas o número exato de avisos é do dia;
- se uma skill nova do hub desce para os projetos no `/meta:adopt --update` (o manifesto inclui
  `.claude/skills` inteiro, mas a descida não foi ensaiada) — assunto da aula 6;
- o selo manual de decisão do bloco D foi conferido no radar dos dois pins (o do hub avisa
  `decision-done-em-DEV`; o do core aceita o selo em DEV e acusa `MISPLANED` em PROD), mas não
  passou pelas demais guardas de selo do hub.

**Comandos que esta aula quis usar e não estão no bundle do hub:** `/meta:decide` (core-only; o
bloco D ensina o selo à mão) e `kg-contract-check.sh` (o contrato formal do `.kg.yaml` não está
vendorizado no hub). O `/meta:forge` está no bundle, mas se declara core-only.
