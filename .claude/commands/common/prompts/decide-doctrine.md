# 🗳️ Doutrina do /meta:decide — o que está em voo vira questionário, e a resposta vira selo

Fragmento canônico do [`/meta:decide`](../../meta/decide.md). A superfície **referencia**, não copia.

**Por que existe (pedido do maestro, 2026-10-12, literal):** *"quando tenho opções, tarefas pendentes,
fios abertos e outros, principalmente quando tenho que tomar decisões ou selar algum entendimento quero
poder rodar algo que ajusta o que está acontecendo e coloque em forma de questionário bem estruturado
com as sugestões, descrição e recomendações que facilite e oriente os próximos movimentos"*. A
topologia foi selada na entrevista da forja no mesmo dia (fonte = a sessão e os fios em voo; forma =
`AskUserQuestion`; destino = selo no grafo e segue); decisão e evidência em
`docs/evolution/research/forge-decide-2026-10/`.

**Medido na forja, antes dos nós da própria forja (que somam 2 perguntas e 1 grafo):** o corpus tinha 159 nós `decision` e 300 `question` abertos, espalhados por 117
grafos rastreados (50 com decisão aberta), e **nenhum** guarda as opções em campo estruturado — elas
vivem em `label`/`narrative`, quando vivem. Por isso o corpus entra **por referência** (nó citado por
id, tema passado, bloco tocado na janela), nunca despejado.

## As cláusulas

### 1. O FILTRO: só vira pergunta o que é do maestro
Precedente: a memória do maestro `decisao-do-maestro-vem-como-pergunta` (2026-09-11) — *decisão dele
vem como PERGUNTA com opções, nunca prosa com recomendação embutida; a recomendação vira a 1ª opção;
**não vale para o que dá para medir e decidir sozinho — aí mede, decide e reporta***. Esta cláusula é
o centro da doutrina. Antes de compor qualquer pergunta, a sessão passa cada linha do censo por três
testes, e a linha que falha em qualquer um **não é pergunta**:
- **É medível?** Se um `grep`, um `gh pr checks`, o radar ou uma execução responde, a sessão roda,
  conclui e reporta. Exemplos: "o CI está verde?", "o nó ainda vale?" (isso é `/meta:kg-freshness`),
  "a worktree tem algo a empurrar?".
- **É derivável da doutrina?** Se o CLAUDE.md, uma REGRA ou uma decisão já selada responde, a sessão
  aplica e cita a fonte. Perguntar o que já foi decidido é re-litigar.
- **É de outro dono?** Repo alheio, sessão alheia (I3) e o merge/deploy (MOAT) não viram selo daqui:
  merge e deploy continuam do maestro pelo caminho verificado; o que é de outra sessão vai para ela.
Sobra o que é **do maestro**: escopo, trade-off de produto, forma canônica, o que entra e o que fica
gated, um entendimento a selar. O que o filtro tirou é **listado** no relatório com o porquê
(medido / derivado / de outro dono) — o filtro não apaga em silêncio.

⚠️ **O que o filtro tirou NÃO se sela por aqui.** O selador grava `method: testemunho: decisão do
maestro…`; usá-lo num nó que o maestro não respondeu é forjar testemunho. Nó que a medição fecha se
fecha pelo caminho da medição (`/meta:kg-freshness`, ou o fluxo normal com `method: medição`), nunca
em lote "sem pergunta individual". Achado do dogfood de carga da forja (2026-10-12): a sessão de teste
propôs exatamente isso para oito decisões que julgou "já exercitadas".

### 2. Cada opção carrega a sua implicação
A opção não é um rótulo: a descrição diz **o custo**, **o que destrava** e **o que fica gated** se ela
for escolhida. Opção sem implicação transfere de volta ao maestro o trabalho de imaginar a
consequência — exatamente o que a pergunta existe para poupar. Opções saem do nó (os trechos que o
medidor copia literalmente de `label`/`narrative`) ou do embasamento medido na sessão; **nunca
inventadas para completar quatro**. Quando falta embasamento para compor opções honestas, uma das
opções é *"pesquisar antes"*, apontando o `/onion-research` em modo `decision` — o `/meta:decide`
não re-pesquisa.

### 3. A recomendada vem PRIMEIRO, marcada, com o porquê
Quando a sessão tem recomendação, ela é a **primeira** opção, com o rótulo terminando em
"(Recomendado)" e o **porquê** na descrição (a evidência ou a regra que a sustenta). Recomendação
embutida em prosa antes da pergunta enviesa sem deixar ver; recomendação como opção marcada fica ao
lado das alternativas, com o custo de cada uma visível. Sem recomendação honesta, nenhuma opção leva a
marca — inventar preferência é pior que declarar empate.

### 4. Teto e ordem: bloqueio primeiro, depois atenção
`AskUserQuestion` aceita até **4 perguntas por rodada** e **2–4 opções por pergunta**, com o `header`
em até **12 caracteres**. A ordem das perguntas é a do medidor: **o que bloqueia** (checkpoint pendente
do `/meta:drive`, PR com check vermelho) antes do **que pede atenção** (impacto, citação na conversa,
tema). Mais de 4 perguntas → rodadas sucessivas, e as que ficaram para depois são **nomeadas** ao
maestro antes da primeira rodada (o mesmo princípio do teto do medidor: corte nunca é silencioso).

### 5. A resposta livre também é selo
O maestro pode responder fora das opções (o "Other" do `AskUserQuestion`). Essa resposta é **decisão
dele**, não ruído: sela igual, com a marca `--other` no selador, que registra na narrative que a
escolha foi livre e lista as opções oferecidas como descartadas. Resposta livre ambígua (não dá para
saber o que foi escolhido) **não sela**: vira pergunta de esclarecimento na rodada seguinte.

### 6. O selo vai no MESMO movimento
Cada resposta vira escrita no grafo **antes** da próxima rodada, pelo selador
(`.claude/validation/kg-decide-seal.sh`), nunca à mão: nó existente → `status: done`, `verified_at`,
`provenance.method` = `testemunho: decisão do maestro por pergunta com opções, <data>`, a escolhida e
as descartadas na `narrative`; decisão sem nó → `D_` novo no grafo do tema, ligado ao nó de onde veio.
Só se sela nó **`open`** (lista positiva: `confirmed` com proveniência medida não é re-carimbado), com
a **pergunta** registrada (`--question` é obrigatório: é o único rastro de que houve pergunta), data
que não está no futuro, escolha não vazia e distinta das descartadas; a narrative anterior fica
**verbatim** e a proveniência anterior vai inteira para ela. O passo 0 roda radar **e** contrato: dívida
que o grafo já tinha não vira culpa do selo (rc 2, não 3). Curas da passada adversarial da forja.
O selo fica em **`plane: DEV`** (e rebaixa um PROD, dizendo isso na narrative): a base dele é
**testemunho**, e o contrato do `.kg.yaml` reprova testemunho em PROD (`integrity.testimony-in-prod`).
O radar avisa `decision-done-em-DEV` (SOFT, agregado) — os dois discordam, e vence o contrato; a
promoção a PROD é de quem **executa** a decisão e mede o artefato. Achado do dogfood da forja: a 1ª
versão subia para PROD, e o `kg-contract-check.sh` reprovou o próprio grafo da forja. O selador só termina rc 0 com o **radar `--integrity --schema`
exit 0** (e o contrato, onde vendorizado); senão **desfaz** byte a byte e sai 3. Selar depois, "no
fim da sessão", é o selo que evapora quando a sessão cai — a lição `grafo-sempre-atualizado`.

### 7. Nunca selar às cegas, nem campo humano, nem o que não foi perguntado
A sessão grava **só** o que o maestro respondeu. Pergunta pulada não sela; recomendação da sessão não
é resposta. E nó com campo **cego** (gate humano às cegas: o voto de qualquer outro o anula) é
**recusado** pelo selador, que reconhece a chave pelo nome (`blind`/`cego`) — lição de 2026-10-06, a
memória `never-fill-blind-human-gate`: um voto de IA no campo cego contaminou a leitura humana.

## O que esta doutrina NÃO promete

- **Não decide pelo maestro.** Mede, filtra, compõe, pergunta e grava; a escolha é dele.
- **Não re-pesquisa.** Falta de embasamento vira a opção "pesquisar antes", não uma pesquisa feita
  ali mesmo.
- **Não garante que o filtro acerte.** O filtro é julgamento da sessão; o que ele tirou é listado com
  o porquê, para o maestro poder devolver uma linha à mesa. O medidor não filtra: ele só lista.
- **Não lê opções estruturadas que não existem.** Os trechos "que parecem opções" são cópia literal
  por padrão fixo — (a)/(b), "opção X", frase com `?` e " ou " — e erram para os dois lados. Em
  alguns grafos as opções são **nós vizinhos** (`C_OPCAO_*` → `D_` por `SUPPORTS`; 4 das 159
  decisões abertas, medido na forja): o medidor lista **quem chega por aresta** a cada nó, e a sessão
  lê esses nós antes de compor. Id citado que não está na fila (inexistente, ou já fechado) vira
  **aviso nomeado**, nunca some.
- **Não mede a conversa.** O que foi dito na sessão entra pelo `--cite` (o texto que a sessão passa),
  não por leitura do transcript.
- **Contrato de custo** (`run_id` · `tokens` · `agents` · `duration_min`): **não se aplica** — o
  `/meta:decide` não é run de workflow; o medidor e o selador são 0 tokens. Declarado, não omitido.
- **Não executa merge, deploy nem escrita em repo alheio** (MOAT): "merge" no questionário é a
  pergunta *se* e *quando*; o ato segue o caminho verificado, nas mãos do maestro.

## 🔗 Referências

- Superfície: [`/meta:decide`](../../meta/decide.md) · medidor (peça 3):
  `.claude/validation/decide-census.sh` · destino (peça 5): `.claude/validation/kg-decide-seal.sh` ·
  bancada (peça 7): `run_decide_selftests`
- Precedente de forma: o checkpoint do [`/meta:drive`](../../meta/drive.md)
  (`kg-drive-project.sh --seal`), que já sela por escrita mecânica com radar
- Grafo da forja (core-only): `docs/evolution/research/forge-decide-2026-10/forge-decide-2026-10.kg.yaml`
