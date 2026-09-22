# Sinal ao core — a perna de leitura quebrada tem custo medido, e o gatilho certo não é relógio

**Data:** 2026-09-11 · **Repo:** jogo-da-vida (adotante) · **Complementa:** `2026-09-10-doutrina-versus-codigo-no-motor-do-kg.md`
(os onze achados doutrina≠código, já relayados)

Aquele sinal trouxe onze achados **teóricos**. Este traz **um caso de campo**, com custo, e a leitura de
desenho que ele sugere. O caso é o próprio adotante falhando — não um usuário hipotético.

## O caso: um dia de trabalho e quatro teses erradas num repo que guardava a resposta

Sessão de 2026-09-10/11. Tarefa: entender o modelo MAAGICA do autor e o que dele sustenta um Personal Brain
sobre o Onion. O corpus tem **três `.kg.yaml` com 1.395 nós** (`maagica` 291 · `livro-magico` 447 ·
`jogo-dos-negocios` 657), além das obras em markdown.

**O que fiz:** li 8.585 linhas de fonte em quatro frentes paralelas e construí um grafo de 53 nós.

**O que eu deveria ter feito primeiro:** aberto `maagica.kg.yaml`. A pergunta central da pesquisa — o PLEA é
recursivo intrafases? — está respondida em **quatro nós**:

| nó | o que já dizia |
|---|---|
| `EN_MAAGICA_PLEA_MODEL` | "modelo e ferramenta de Pedro Rosário (2004a), **cíclico intrafases**" |
| `C_MAAGICA_PLEA_INTRAPHASE_CYCLIC` | "**cada fase contém o ciclo das três fases**: as tarefas de cada fase são planejadas, realizadas e avaliadas" |
| `EN_MAAGICA_PLEA_EXECUTION` | "implementação de estratégias, **monitorando** sua eficácia com ajustes sucessivos ao planejamento" |
| `EN_MAAGICA_PLEA_EVALUATION` | (a fase que contém a própria execução) |

**O custo:** **quatro teses publicadas e derrubadas** em sequência, todas por correção do autor, nenhuma pelo
método. Todas registradas com `SUPERSEDES`/`REFUTES` no grafo da pesquisa — o histórico está lá, e é
constrangedor de ler.

**O agravante:** eu **citei** `maagica.kg.yaml` no prompt que escrevi para as frentes — como *checklist para
conferir se não perderam nada*, nunca como **fonte de verdade**. A informação estava presente, disponível e
referenciada por mim. **Não foi falta de acesso nem de contexto. Foi falta de mecanismo.**

**A frase que resume:** *o grafo que não é lido é indistinguível do grafo que não foi escrito.* Hoje isso
deixou de ser retórica e virou medição.

## Por que isso é sinal ao core, e não vergonha do adotante

Porque é a consequência prática do ⚠️10 — *"a perna de LEITURA foi anunciada como mecanismo; é conselho"* ·
*"nenhum dos hooks lê `.kg.yaml`"* (`knowledge-graph-sdaal.md:287-297`). O core já se corrigiu no texto e
manteve o registro, o que é sinal de saúde. **O que faltava era alguém medir o preço da lacuna.** Aqui está:
um dia, quatro conclusões erradas, num repositório que guardava a resposta desde sempre.

E o sinal de campo de 2026-07-16 dizia que o autor da doutrina reincidiu ≥4× em reconstruir de git/memória
com o KG "de lado". **Este é mais um caso, agora de um agente**, o que reforça a tese do core: *"lembrar de
consultar" não é forcing function*.

## O desenho: três gatilhos diferentes para três necessidades diferentes (o adotante propõe)

A pergunta natural é "maquinaria ou temporizador?". A resposta medida é: **temporizador é a opção errada por
padrão**, e as três necessidades têm naturezas distintas.

**Por que não relógio.** `review_after` **já é** um temporizador, está em 16 grafos, e não fez ninguém
revisitar nada. Relógio produz **lote de obrigações fora de contexto**, num momento em que ninguém
perguntou — é assim que a prática de ADR virou cemitério. (E agendar por relógio é MOAT declarado.)

| # | Necessidade | Gatilho | Onde encostar | Tamanho |
|---|---|---|---|---|
| 1 | **Ler o grafo antes da fonte** | **evento** — "você está abrindo fonte que tem grafo" | **hook**; a classe já existe e roda a todo commit. Falta a fiação: nenhum hook lê `.kg.yaml` | pequeno — é ligar um fio solto |
| 2 | **Saber que o conhecimento venceu** | **nenhum** — basta o painel parar de mentir | `kg-radar.sh` sai **verde** com grafo vencido; só a REGRA 67 (SOFT, no lint) menciona. Mostrar "N nós fora da validade" **no radar**, que todos rodam | pequeno |
| 3 | **Revisitar o que ficou velho** | **contradição, no ato da escrita** | o momento barato é quando se escreve algo novo que colide com algo antigo: já se está no assunto. O radar já pega um pedaço (nó que recebe `REFUTES` e segue `confirmed`) | médio — precisa de desenho |
| 4 | **Que o carimbo valha algo** | **contrato, não gatilho** | ver abaixo | pequeno, e é o que decide |

### O item 4 é o que explica o zero

Rosário (2005), citado na própria dissertação do MAAGICA: a fase de avaliação *"não se centra na mera
**constatação** de eventuais erros de planejamento, mas sim no **REDESENHO de estratégias**"*.

Isso reenquadra `drifted = 0 em 3.715 nós`. A leitura fácil é "falta disciplina". A leitura medida é outra:
**carimbar é barato e não entrega nada.** Ninguém deixa de carimbar por preguiça — deixa porque o carimbo
sozinho não leva a lugar nenhum.

**Proposta:** um `drifted` **sem aresta para algo novo** está incompleto, e o radar avisa. O carimbo passa a
exigir o **par** — o desvio *e* o redesenho. É a diferença entre registrar que o mundo andou e fazer algo a
respeito, e é literalmente o núcleo da fase de avaliação segundo o autor do modelo que o Onion usa.

## O que NÃO fazer

1. **Nada disso nasce bloqueando.** Um gate que impede trabalho é contornado com `--no-verify` na primeira
   sexta-feira, e aí se perde o mecanismo *e* a informação. O padrão certo já é da casa: **catraca** — avisa,
   a métrica de saúde é o número diminuindo, endurece quando o número já está baixo.
2. **Não acrescentar doutrina.** Ela já está onze itens à frente do código. Mais texto aumenta a dívida que
   se quer pagar. O trabalho aqui é **código alcançando texto**, não o contrário.
3. **Não instrumentar por relógio** o que tem gatilho de evento disponível.

## As métricas que dizem se a espinha dorsal está viva

Não é tamanho do grafo — são 3.715 nós e isso não provou nada. É **com que frequência o grafo muda o que se
faz a seguir**:

- quantas vezes o grafo foi **lido antes** da fonte (hoje: sem instrumento para saber)
- `drifted` carimbados (hoje: **0** em 3.715)
- execuções de `kg-freshness` (hoje: **0** em 34 dias — dado do próprio core)
- decisões **revistas** — `SUPERSEDES` de decisão para decisão (hoje: **1** no corpus inteiro; das 20 arestas
  `SUPERSEDES`, **18 são decisão→pergunta**, que é *pergunta respondida*, não *decisão revista*)

Essa última medição é nova e vale por si: **o sistema parece reconciliar e, na prática, quase só conclui.**

## Ordem sugerida, por retorno sobre custo

1. **Ligar o hook de leitura** — o menor, e o único que teria evitado o caso deste sinal.
2. **Radar mostrar vencimento** — não é feature nova, é parar de esconder.
3. **Exigir o par desvio↔redesenho** — é o que dá valor ao carimbo e destrava o item 2 do core.
4. **Gatilho por contradição** — o mais caro, e o único que precisa de desenho de verdade.
