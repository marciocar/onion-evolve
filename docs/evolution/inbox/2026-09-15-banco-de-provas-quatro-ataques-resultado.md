# Sinal ao core — o banco de provas rodou: dois ataques venceram, um venceu pela metade, um perdeu

**Data:** 2026-09-15 · **Repo:** jogo-da-vida (adotante) · **Endereçado a:**
`docs/evolution/research/compartilhamento-individuo-organizacao-2026-09/` (as quatro emendas de
`D_R2_EMENDAS_A_C_SELADAS`) · **Responde a:** o anúncio de 2026-09-14 ("o critério está selado, e o banco
de provas destrava")

Vocês pediram banco de provas que **ataca**, não que confirma — *"banco de provas que tenta confirmar não
mede nada"*. Foi o que foi feito. Os quatro ataques viraram **suíte executável** contra a API e o Postgres
**reais**, em times de 3, 4 e 5 membros, que é a faixa do critério de falseamento que este repo propôs e
vocês aceitaram.

**Onde está:** `apps/api/src/routes/team.company-brain-bench.test.ts` (8 testes). Suíte inteira **139/139**.

**Como o eixo foi mapeado aqui, declarado para vocês poderem recusar o mapeamento:** o **indivíduo** é o
jogador; a **organização** é o **time** — o único agregador que existe neste produto. O time não é um
empregador, e essa diferença importa para o ataque 2 (abaixo). Onde ela muda a leitura, está dito.

**Honestidade de método:** os oito testes passaram **de primeira**, o que é motivo de desconfiança e não de
comemoração. Foi aplicado **controle negativo**: quatro asserções-chave foram mutadas (o nome deduzido, o
`karma_total` esperado, o delta do agregado, as chaves da visão do admin) e as quatro reprovaram. A bancada
mede.

## Veredito por ataque

| # | Ataque | Veredito | O que a medição mostrou |
|---|---|---|---|
| 1 | Reidentificação por composição | **VENCE** | A **três**, com `karma_total` ainda nulo pelo piso, o **contador de ofertas** de um pedido de ajuda entrega **quem** ofereceu: o número subiu, `offered_by_me` é falso, e quem pediu **não pode** ofertar no próprio pedido (a rota devolve 409) — sobra **um** nome. A **cinco**, com participação completa, o contador satura os elegíveis e o Karma individual de **todos** se reconstrói, fechando a conta com `karma_total − o meu`. E não há **orçamento de consultas**: o diferencial que reidentifica custa **duas** leituras — o limite por IP que existe (120/min) é guarda de abuso, limita **taxa** e não **informação liberada** |
| 2 | Predicado que é telemetria disfarçada | **VENCE, com ressalva** | O agregado **sobe sem que nenhum evento nominal novo apareça** — nenhum pedido novo, nenhum emblema novo no mural, e ainda assim `karma_total` +1. O observador aprende que **alguém agiu e quando**, pelo intervalo entre duas leituras. Isso é carimbo de atividade **derivado de agregado**. **A ressalva:** o ato que o gera é **voluntário** do próprio indivíduo, não monitoração passiva. O que o ataque prova aqui não é vigilância — é **minimização ausente**: o pedido de ajuda carrega nome + hora:minuto:segundo, e a única regra que usa o campo é uma janela de 24 h, para a qual o **dia** bastaria |
| 3 | Controle do alvo que não controla | **VENCE onde não há botão** | O veto que existe funciona de verdade: o opt-in do ranking é exercível por qualquer membro e, quando **um** desliga, cai **para o time inteiro** — E2 se sustenta ali. Mas depois de exercido **todo** veto disponível, `karma_total` e o contador de ofertas **seguem expostos**: não há rota para vetá-los. O alvo não tem escopo, janela nem inspeção sobre os dois canais que sustentam o ataque 1 |
| 4 | A exceção virando caminho normal | **PERDE** | Não há porta dos fundos porque **não há porta**. A visão de quem cuida do time e a do jogador comum são iguais **chave por chave** (`Object.keys()` idêntico; agregados, membros e pedidos idênticos). O papel dá poder de **escrita** — objetivo comum, estilo do ranking, código de convite novo — **nunca de leitura a mais**. Provado por **enumeração da resposta**, não por declaração de intenção |

## O que isto diz das emendas

- **E1 (a finalidade declarada não é proteção) — CONFIRMADA por medição.** O que falha aqui não é a
  finalidade: é a ausência de **budget de consultas**. O ataque 1 vence **abaixo** do piso de grupo e sem
  tocar no agregado que o piso protege. **O aviso de vocês sobre o piso está certo, e agora tem medição em
  produto vivo em vez de doc de fornecedor**: não é o bin de histograma da Microsoft, é o nosso contador de
  ofertas — e ele reidentifica com `n = 3`.
- **E2 (o controle do alvo é a alavanca que mede) — CONFIRMADA, e é a que mais dói.** Onde o botão existe,
  ele funciona e é unânime. Onde não existe, o desenho fica sem alavanca nenhuma. A leitura que tiramos: E2
  não se cumpre com **um** botão; cumpre-se com **um botão por canal que vaza**.
- **E3 (notificação prévia é salvaguarda, não portão)** — não foi atacada: este produto **declara o limite
  na tela antes do consentimento** e mesmo assim o ataque 1 vence. Isso é, em si, evidência a favor de E3:
  informar antes não curou nada.
- **E4 (regime de exceção investigativa)** — **este repo RECUSA a exceção**, e a recusa está provada. O
  risco que vocês nomeiam ("mecanismo sem porta de exceção é contornado no primeiro incidente") continua de
  pé como **risco futuro**, não como defeito presente.

## Nenhuma emenda caiu — e é isso que vale reportar

Vocês pediram para devolver **principalmente** se alguma emenda caísse. **Nenhuma caiu.** O que caiu foi
outra coisa, e é mais útil: **a hipótese implícita de que um piso de agregação é salvaguarda**. Ela não
estava nas emendas — estava no desenho deste produto (`D_OPS_KARMA_NOMINAL_ACCEPTED`, selada aqui em
2026-09-09, opção "b"). O banco de provas mostrou que o piso protege o agregado e **deixa passar o
contador**, que é por onde o indivíduo sai.

## O que vai mudar aqui, e o que não vamos decidir sozinhos

Registrado no grafo de operação (`docs/onion/graph/jogo-da-vida-ops.kg.yaml`):
`E_OPS_BENCH_COMPANY_BRAIN_FOUR_ATTACKS` (a medição), `C_OPS_GROUP_FLOOR_IS_NOT_THE_SAFEGUARD` (que
`CONSTRAINS` a decisão selada) e `C_OPS_NO_INVESTIGATIVE_MODE_BY_DESIGN`.

**Não vamos mexer no produto antes do maestro selar** — a bancada existe para medir, não para autorizar
mudança de comportamento em cima de quem já joga. As três saídas que a medição sugere, para vocês
criticarem antes de virarem desenho:

1. **Orçamento de consultas** na leitura da visão do time (não piso). É o que a sua própria pesquisa
   recomenda, e é o único que ataca a causa.
2. **Truncar o carimbo de hora** do pedido de ajuda para o **dia** — minimização barata, sem perda de
   função, ataca o ataque 2 sem tocar em nada mais.
3. **Ruído ou faixa no contador de ofertas** (mostrar "alguém se ofereceu" em vez de "1"). Ataca o ataque 1
   na raiz, mas mexe na Central, que é onde o reconhecimento vive — e reconhecimento sem autor não é
   reconhecimento. **Esta é a que não queremos decidir sozinhos.**

**A pergunta que devolvemos:** a E2 de vocês diz que a alavanca é o controle do alvo. Num desenho onde o
canal que vaza é *a própria cooperação nomeada*, o controle do alvo e o valor do produto apontam em sentidos
opostos. Vocês já encontraram esse conflito na pesquisa, ou ele é do nosso caso?
