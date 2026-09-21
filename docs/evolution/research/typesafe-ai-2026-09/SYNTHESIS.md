# TypeSafe AI, desmembrada — e o que ela tem a ver com o Onion

> **Rodada:** 2026-09-21 · **Grafo SSOT:** [`typesafe-ai-2026-09.kg.yaml`](typesafe-ai-2026-09.kg.yaml) (radar exit 0, 25 nós, 28 arestas)
> **Fonte primária dominante:** `docs.typesafe.ai/llms-full.txt` (903 KB, baixado integral) + typesafe.ai (home, manifesto, team) + blog de lançamento
> **Revisitar em:** 2026-10-21 (30d — o vendor tem **6 dias** de vida pública e a própria doc avisa que limites mudam sem aviso)

> ⚠️ **A fronteira desta rodada, dita antes de tudo:** **nenhuma chamada à API foi feita.** Não há
> `TYPESAFE_API_KEY` nesta máquina. Todo número de performance, custo e alucinação abaixo é
> **autodeclarado pelo vendor** — está marcado como tal onde aparece, e o §9 lista o que ficou fora.
> Esta é documentação de leitura, não de medição.

---

## 0. Ficha

| Campo | Valor |
|---|---|
| **O que é** | Lab de IA em São Francisco vendendo um modelo que **não escreve texto** |
| **Produto** | **Jev** (`jev-1.13.0`), o primeiro e único **System One Model** |
| **Superfície** | Um endpoint: `POST https://api.typesafe.ai/v1/systemone` |
| **Estado** | Early access; lançamento público em **2026-09-15** |
| **Preço** | US$ 42 / bilhão de tokens de **entrada**; **saída grátis** |
| **Capital** | Seed de US$ 40M liderado pela **DCVC** (imprensa, não fonte primária) |
| **Fundadores** | Diogo Almeida (CEO), Sasha Sheng (COO), Erik Gafni (CTO) |
| **Onde já toca o Onion** | Publica uma **skill + plugin no marketplace do Claude Code** |

---

## 1. A tese — e por que ela não é "um modelo melhor"

O manifesto recusa a corrida que todo mundo está correndo. A frase que carrega o argumento é
*"the bottleneck isn't raw intelligence"* — o gargalo não é inteligência bruta, é que **a inteligência de
hoje é difícil de construir em cima**.

A imagem que eles escolhem para isso é a **horseless carriage**: os primeiros automóveis mantiveram
bancos altos e suporte de chicote porque ninguém tinha ainda reimaginado o objeto, só tinha trocado o
cavalo. A IA atual, dizem, faz o mesmo — é treinada para ser *"a helpful, articulate, pleasant assistant"*
porque assume, sempre, um humano no loop lendo a resposta.

A alternativa que eles nomeiam é **Machine Native Intelligence**: IA com **propriedades de software** —
estrutura, confiabilidade, observabilidade, testabilidade, velocidade, consistência e baixo custo. A
projeção que sustenta a aposta é agressiva e explícita: automação em larga escala será **~99%
máquina-para-máquina e ~1% humana**. O lema interno é bom o bastante para roubar: **"Building prod,
not God"** — não estão tentando construir o modelo que faz tudo, estão mirando sistemas de produção
onde o código precisa de **uma decisão estreita que ele possa inspecionar**.

E o manifesto se compromete com uma métrica falsificável, o que é raro: sucesso = **crescimento da TFP
global chegando a 3% em cinco anos e se sustentando por dez**.

## 2. O modelo — System One, RLCD, e o limite que eles mesmos publicam

**System One Model** é uma *classe*, não um modelo. O nome vem do **System 1 de Kahneman** (*Thinking,
Fast and Slow*): o pensamento rápido e intuitivo, em oposição ao deliberado. Jev é o primeiro — e hoje
o único — exemplar.

Jev entende linguagem natural como um LLM. O que ele **não** faz: não escreve texto, não produz código,
não conversa, não explica o próprio raciocínio. Ele recebe um `state` e devolve **respostas tipadas com
distribuição de probabilidade**. O espaço de respostas é definido por **quem chama**, não pelo modelo.

### RLCD — a terceira via de pós-treino

A doc organiza o mundo em três caminhos de pós-treino, e a tabela é o argumento inteiro:

| Caminho | O que produziu | Otimiza para |
|---|---|---|
| **RLHF** | chatbots (InstructGPT, ChatGPT) | respostas que **pessoas preferem** |
| **RLVR** | modelos de raciocínio (fortes em matemática, lentos e caros) | recompensa **verificável** |
| **RLCD** | **Jev** | **decisões + probabilidades calibradas** |

A crítica ao RLHF é específica, não genérica: sicofancia, alucinação com tom confiante, e **mode
dropping** — a otimização por preferência estreita a distribuição, fazendo o modelo favorecer um estilo
e apagar outras saídas possíveis. (Uma versão branda do *mode collapse* clássico de GANs.)

E aqui há um peso de procedência incomum: **Diogo Almeida co-inventou o RLHF** que agora aponta como
inadequado para automação. Isso não torna o argumento verdadeiro, mas torna difícil descartá-lo como
desconhecimento.

### O limite da calibração — leia esta parte duas vezes

A própria documentação declara, em **duas páginas diferentes**, o limite que desarma o uso ingênuo:

> Calibração é medida **sobre grupos** de previsões. Ela **não garante nada sobre uma resposta.**
> "Outcomes assigned a probability of 0.2 should occur about 20% of the time."

Ou seja: `confidence: 0.9` **não** significa "esta resposta está certa com 90% de chance de forma
auditável individualmente" — significa que, na média de muitas respostas com aquele confidence, a taxa
de acerto bate. Quem ler confidence como certeza pontual está usando o produto errado. O fato de eles
publicarem isso na página de vendas técnica conta a favor deles.

## 3. A superfície técnica — três primitivas e um endpoint

Toda a API cabe num parágrafo: você manda um `state` e um mapa de `questions` nomeadas por você; volta
um mapa de `answers` com **as mesmas chaves**. As perguntas são avaliadas **em paralelo e
independentemente** contra o mesmo state — o resultado de uma não vira contexto oculto de outra.

### As três primitivas

| Tipo | Pergunta | Resposta | Confidence? |
|---|---|---|---|
| **Noul** | sim/não | um float `0..1` (probabilidade de "sim") | **não** |
| **Choice** | escolha 1 de N (até **255**) | opção escolhida + probabilidade de **cada** opção + confidence | sim |
| **Score** | nota contra níveis ordenados (2 a **10**) | valor **ponderado por probabilidade** — pode cair *entre* níveis (ex. `1.05`) + `legend` + probabilidades + confidence | sim |

Um request real, inteiro:

```json
{
  "state": "Help! My payouts have been failing for 3 days.",
  "model": "jev-latest",
  "questions": {
    "department": {
      "type": "choice",
      "instructions": "Which team should handle this?",
      "criteria": {
        "billing":   "Payments, invoicing, refunds",
        "technical": "Bugs, outages, integrations",
        "sales":     "Pricing, upgrades, new accounts"
      }
    }
  }
}
```

```json
{
  "model": "jev-1.13.0",
  "answers": {
    "department": {
      "type": "choice",
      "choice": "billing",
      "probabilities": { "billing": 0.88, "technical": 0.12, "sales": 0.0 },
      "confidence": 0.81
    }
  },
  "usage": { "input_tokens": 318, "output_tokens": 34 }
}
```

Repare no que **não** está ali: nenhuma string gerada, nenhum "aqui está o JSON que você pediu",
nenhum parsing. O tipo é garantido **por construção**, não por instrução.

### `state` — o material, separado das perguntas

O `state` é o conteúdo a avaliar: string, objeto JSON ou array de textos. A analogia da doc é boa — *o
material que você apresentaria a um painel de especialistas antes de pedir um julgamento*. A regra de
projeto é **separar conteúdo de pergunta**: fatos e políticas vão no `state`; os juízos vão em
`questions`.

### `confidence` — derivado, não declarado

`confidence` **não é um campo que o modelo "acha"**. É uma estatística **derivada da forma da
distribuição** que a resposta já carrega: concentrada = confiante, espalhada = incerta. Eles colapsam
isso num número 0..1 por conveniência e dizem explicitamente que **você não está preso à definição
deles** — as probabilidades cruas vêm na resposta.

A doutrina que acompanha vale citar:

> *"If an intelligent system, whether human or machine, cannot express honest uncertainty, the system
> cannot be trusted."*

E o limiar **não é um número só** — escala com a consequência. O exemplo da doc: ler saldo aceita 0.5;
aprovar transferência exige 0.9. **O código encoda a tolerância a risco.**

### Modelo e limites operacionais

| | `jev-1.13.0` |
|---|---|
| Preço | US$ 42/Btok entrada · **saída grátis** |
| Rate limit | 250.000 tok/s · 1.200 req/min |
| Contexto | 64k por request (state + **todas** as perguntas) · 32k (state + a pergunta mais longa) |
| Entrada | **texto apenas** — sem imagem, áudio ou vídeo |
| Idioma | **inglês é a língua primária**; outras, inclusive CJK, *"handled but not equally well"* |
| Customização | **sem fine-tune, sem LoRA** — os mesmos pesos servem todo mundo |

Aliases `jev-latest` e `jev-preview`; a resposta sempre reporta o **ID versionado** que respondeu, e a
doc recomenda **fixar a versão** se você calibrou limiares contra ela. Erros HTTP convencionais
(401/422/429/**529 Overloaded**), SDKs Python e JavaScript com backoff por padrão. Existe uma página
inteira chamada **"Jev 1.13 jaggedness"** só para documentar como a acurácia muda conforme o `state`
cresce — publicar a própria irregularidade é postura, não acidente.

## 4. Os quatro padrões — o vocabulário que eles estão tentando fixar

| Padrão | O que é | Ganha em |
|---|---|---|
| **Speculative fan-out** | mandar muitas perguntas num request, **inclusive especulativas**, e o código decide o que era relevante — barato porque o `state` é ingerido **uma vez** | custo, velocidade |
| **Confidence-gated routing** | confidence como **segundo eixo**: a resposta diz *o quê*, o confidence diz **se agir** | confiabilidade, segurança |
| **Composite scoring** | quebrar um juízo complexo em notas **atômicas** e combinar com pesos que vivem **no seu código** | custo, confiabilidade, velocidade |
| **Intent routing** | classificar e rotear para lógica determinística, LLM especialista **ou humano** | custo, velocidade |

### A tese de arquitetura — e ela é adversária

A doc opõe três arquiteturas e escolhe a terceira **explicitamente contra a segunda**:

1. **Software tradicional** — árvore de decisão feita de primitivas confiáveis, componíveis porque cada
   uma é previsível.
2. **Agentes LLM** — *"every loop introduces another opportunity to go off the rails"*; funciona quando
   há alguém monitorando.
3. **AI-powered software** — o **código é dono do fluxo de controle**; o modelo aparece **só** onde o
   sistema precisa de senso comum programável.

A instrução de projeto é literal: ***"Avoid agent `while` loops when a software workflow can express the
same behavior."*** Guarde esta frase — ela volta no §7.

## 5. A economia declarada — e o que ela não prova

Os números de vitrine: **193,6x mais rápido**, **444,6x mais barato**, **238x mais barato que Claude
Fable 5.1** na entrada, **70–500ms** contra 3–329s, **"zero alucinações"**.

> 🔍 **Estes dois primeiros números vieram errados na primeira redação deste documento** — invertidos,
> "193,6x mais barato / 444,6x mais rápido". A causa: um resumo automático da página trocou os rótulos,
> e eu o repassei sem cruzar com a outra leitura da **mesma** página, que trazia o par correto. A
> correção veio do HTML cru (`193.6x Faster,<br>444.6x Cheaper.`). Fica registrado porque é a lição
> operacional da rodada: **número de manchete se confere na fonte crua, não num resumo dela** — e duas
> leituras discordantes da mesma página são um sinal a perseguir, não ruído a mediar.

O mérito da TypeSafe é que **ela mesma publica as ressalvas que desarmam os próprios números**:

- os *workflow evals* foram criados *"por indivíduos no time de capacidades do modelo"*;
- os ganhos são declaradamente **"no higher end"** do que se vê no mundo real;
- as medições de latência saem de **laptops na Costa Oeste**, onde o serviço mora;
- a demo lado-a-lado usa entrada *"curta, densa e detalhada"* que *"pinta nosso modelo de forma
  vantajosa"*;
- e o **"zero alucinações" é declaradamente não-empírico** — é conformidade de schema garantida por
  construção. **Isso não impede a resposta tipada de estar simplesmente errada.**

> **A leitura honesta:** "zero alucinação" aqui significa *"nunca devolve um valor fora do conjunto que
> você definiu"*, não *"nunca erra"*. São coisas muito diferentes, e confundi-las é o erro que o
> marketing do setor inteiro convida a cometer.

## 6. Empresa, time e capital

Saíram de ~2 anos de stealth com o lançamento público em **2026-09-15** e um **seed de US$ 40M
liderado pela DCVC**, com avaliação reportada de US$ 200M (Forbes, fonte não nomeada). ⚠️ Isso vem de
**imprensa concordante em 4+ veículos**, não de anúncio primário — a página `team` do próprio site diz
apenas *"top-tier investors"* sem nomear ninguém.

- **Diogo Almeida** (CEO) — **co-inventor do RLHF e do InstructGPT**; ex-OpenAI e Google Brain.
- **Sasha Sheng** (COO) — research engineer na Meta/FAIR; publicações em NeurIPS e ECCV.
- **Erik Gafni** (CTO) — fundador da Ravel (IA multimodal para sequenciamento de DNA); funcionário
  inicial em Invitae e Freenome.

O time é descrito como vindo de OpenAI, Google Brain, Meta/FAIR, Stripe, Airbnb, Plaid e Docker. A
demanda no lançamento foi grande o bastante para derrubar temporariamente a capacidade de servir a API
— e a página de modelos ainda carrega o aviso de que **os rate limits mudam sem aviso** enquanto
absorvem carga.

---

## 7. A relação com o Onion — sete leituras

> **Ponto de partida medido:** `kg-corpus-grep.sh` sobre os **99 grafos** do corpus devolveu **0 nós**
> para `typesafe`, e **0 nós** para `"decisao calibrada" "System One" RLCD "confidence calibrado"`.
> Um `grep -rin` no repo inteiro também devolveu zero. Este documento é a **primeira entrada** do
> vendor no corpus do Onion. Ausência **medida**, não presumida.

### 7.1 Jev não é um quarto motor — é o **Motor 2 finalmente com fornecedor**

A [Economia de Motores](../../../knowledge-base/concepts/onion-engine-economy.md) do Onion tem três
motores: **Transformer** (juízo e orquestração), **SLM-ferramenta via SDAAL** (tarefa estreita e
esquematizada, nunca orquestra) e **Shell** (determinístico — o que o LLM erra).

O Motor 2 sempre foi o mais teórico dos três: seu único caso era o adapter `local-slm` do
de-identification, **gated**, esperando um adotante regulado com runtime. Jev encaixa nos três critérios
do Motor 2 — tarefa estreita, nunca orquestra, entra atrás de adapter — **com dois refinamentos que a
KB não previa**:

- **(a) não é SLM local, é API remota.** Isso **inverte** o argumento de privacidade que motivava o
  Motor 2 no Onion. O motor 2 nasceu para *manter o dado em casa*; este fornecedor o tira de casa.
- **(b) traz uma saída que o Onion não tem em motor nenhum.** O Shell devolve **exit code** — declaração
  binária. O Transformer devolve **prosa**. Nenhum dos dois devolve **"não sei" mensurável**. O Jev
  devolve.

Esse segundo ponto é o achado real da rodada, e ele conversa com uma lição que o Onion já pagou caro
para aprender: *exit code é a declaração do script sobre si mesmo, não a verificação*. Um veredito com
distribuição de probabilidade é de outra natureza que um `exit 0`.

### 7.2 **Não** vira SDAAL hoje — e a própria doutrina do Onion reprova

Aplicando a [Abstraction Doctrine](../../../knowledge-base/concepts/onion-abstraction-doctrine.md) ao
próprio achado, antes que a empolgação escreva um adapter:

- **Teste do Eixo:** "decisão calibrada como serviço" tem **um único provider real** — Jev é
  declaradamente o primeiro e único System One Model. **Um provider só reprova.** O caminho correto é
  script / uso direto, **não** uma abstração nova.
- **Teste do Gatilho:** nomear a condição em vez de pré-cozinhar a costura. E ela é nomeável: **um
  segundo fornecedor** de decisão tipada com probabilidade calibrada, **ou** o Jev virar um caminho com
  consumidor real dentro do core.

Escrever o adapter agora seria exatamente o anti-padrão que a doutrina cataloga.

### 7.3 A convergência que incomoda — "a pior verdade é aquela que não temos certeza"

O Onion chegou por dor própria à certeza **como campo**: `verified_at`, `verified_against`,
`source_tier`, `confidence` vivem no `.kg.yaml` porque declaração não é verificação. A TypeSafe
construiu um **modelo** cujo contrato de treino é justamente devolver incerteza honesta como número.
As duas casas usam **a mesma palavra**: `confidence`.

E é precisamente por isso que a diferença precisa ficar dita antes que alguém misture os dois números
numa conta:

| | Onion (`.kg.yaml`) | Jev |
|---|---|---|
| Origem do `confidence` | **carimbado** por quem escreve o nó | **derivado** da distribuição que o modelo produziu |
| Natureza | declaração | medição |
| O que ele responde | "quanto eu confio no que escrevi" | "quão concentrada ficou a distribuição" |

Nenhum dos dois é inválido. São **espécies diferentes**, e somá-los seria o mesmo erro de categoria que
a doutrina do Onion combate em outro lugar: **confie no que o artefato faz, não no que ele declara de
si**.

### 7.4 Onde encaixaria, se encaixar — e uma contra-fronteira inegociável

O encaixe mais limpo **já existe com o nome pronto**: o veredito do `/meta:kg-freshness` é literalmente
um **Choice de quatro opções** — `CONFIRMED` / `DRIFTED` / `REFUTED` / `UNVERIFIABLE` — hoje produzido
por um **worker Transformer inteiro por nó**.

Outros candidatos, em ordem decrescente de aderência:

1. **Triagem do inbox de co-evolução** — Choice de rota.
2. **O aside-router de marcadores tipados** (`dúvida:`, `corrige:`, `guarda:`…), hoje casamento de
   prefixo por lista. E a classe de defeito que o Onion já catalogou — *"guarda por lista falha pelo
   **vocabulário**, não pela lógica"* — é **exatamente** o modo de falha que um `Choice` com `criteria`
   descritivo ataca.
3. **O censo do backlog.**

> ⛔ **Contra-fronteira inegociável: o `kg-radar` NÃO entra nesta lista.** Ele é determinístico e
> sem-LLM **por projeto** — é a metade que **reprova**. Trocar o que reprova por um juízo probabilístico
> de terceiro destruiria a propriedade que o torna útil, e **nenhum ganho de custo compra isso**.
> A regra geral: Jev é candidato onde hoje há **juízo do Transformer**, nunca onde há **gate
> determinístico**.

### 7.5 O atrito é estrutural, não de configuração

Usar Jev significa mandar o `state` para um terceiro. E num core de KG, **o `state` é o conteúdo dos
nós**. Isso colide de frente com linhas que o Onion já traçou e pagou:

- no de-identification, o provider `none` **recusa** em vez de redigir-e-passar, porque vazar PII não se
  desfaz;
- no Onion pessoal, o **INVARIANTE 0** diz que o KG cru **nunca sai do device**.

Zero data retention existe, **mas só em plano enterprise**. Some-se o **inglês como língua primária**
contra um core cuja doutrina inteira é escrita em pt-BR — com a própria doc avisando que outras línguas
têm acurácia menor — e o custo de adoção deixa de ser o preço por token.

### 7.6 A rivalidade é de **tese**, não de produto

Esta é a relação mais interessante, e ela é adversária.

A TypeSafe diz: *"evite loops de agente quando um workflow de software expressa o mesmo comportamento"*,
e projeta 99% máquina-para-máquina. O Onion **é** um framework de **orquestração agêntica** — sua aposta
é que o juízo do Transformer conduzido por spec-as-code vale o custo.

As duas teses não podem estar ambas certas no mesmo território. O que **desarma parcialmente** o
conflito é que o território não é o mesmo:

- a TypeSafe mira o **caminho de request de produto** — rotear ticket, pontuar risco, classificar em
  100ms, milhões de vezes, sem humano;
- o Onion mira o **ciclo de desenvolvimento**, onde o humano está no loop **por desenho**.

Mas a fronteira é porosa justamente **onde o Onion automatiza juízo sem humano** — e é lá que a tese
rival merece ser **medida, não rebatida**. Vale notar, aliás, que a própria TypeSafe *usa* a arquitetura
agêntica que critica: a recomendação deles é usar seu agente de código normalmente para escrever o
código que chama o Jev.

### 7.7 O espelho de distribuição — eles escolheram a mesma porta

A TypeSafe distribui uma **agent skill por marketplace de plugin do Claude Code**:

```bash
claude plugin marketplace add typesafe-ai/skills
claude plugin install typesafe@typesafe-ai
# invocável como /typesafe:typesafe-ai
```

Com auto-update via `/plugin`, namespace `/<plugin>:<skill>`, e uma via cross-agent por
`npx skills add typesafe-ai/skills`. É **exatamente** a superfície de distribuição que o Onion escolheu.

Um lab de US$ 40M com fundador co-inventor do RLHF apostando na mesma porta é **sinal de mercado sobre a
aposta de distribuição do Onion** — corroboração externa, não novidade. E há dois detalhes operacionais
que valem:

- eles publicam a skill em **repo próprio** (`typesafe-ai/skills`) e oferecem instalação manual copiando
  o diretório inteiro *"including its reference files"* — o mesmo problema de materialização que o ciclo
  de publicação do Onion resolve por clone e push;
- a seção de problemas comuns deles lista **o modo de falha que o Onion já conhece**: *"A stale skill
  can cause this"* — o agente inventa campos de request/response quando a skill está velha. É a mesma
  classe de "artefato-caduco" que o core guarda com catraca.

### 7.8 Bônus: o que o Onion **não** deve fazer com isso

Existe uma pergunta que a leitura apressada faria — *"trocar o modelo do Claude Code por Jev?"* — e o
próprio vendor mantém **uma página inteira** para respondê-la: **não**. Jev não é substituto do LLM por
trás do Claude Code, Cursor, Codex ou Copilot. Não existe `model: "jev-latest"` que transforme um agente
de código em agente Jev, porque *"the two systems solve different problems"*. O caminho é o inverso:
usar o agente de código para **escrever código que chama o Jev**.

---

## 8. Decisão desta rodada

**Documentar e NÃO adotar.** Não escrever adapter (reprovado pelo Teste do Eixo, §7.2), não alterar
motor nenhum, não abrir superfície nova. O que a rodada entrega é **o mapa**.

**O gatilho nomeado para reabrir** — único e mecânico:

> O maestro querer medir, **com chave de API própria**, o veredito do `/meta:kg-freshness` como
> **Choice de 4 opções** contra um lote de nós **já julgados por worker Transformer**.

A razão de ser *esse* alvo e não outro: é o único em que o Onion **já tem gabarito** para comparar.
**Sem gabarito não há dogfood — há impressão.** Até esse gatilho disparar, este grafo é leitura, não
backlog.

## 9. NÃO-VERIFICADOS — o que esta rodada não fez

Lista de primeira classe, porque omitir seria pior que não ter feito:

1. **Nenhuma chamada à API.** Sem chave, sem latência medida, sem custo real, sem acurácia observada.
2. **Nenhum benchmark reproduzido.** Os números do §5 seguem sendo do vendor.
3. **A skill `typesafe-ai` não foi instalada nem lida no GitHub** — só a página que a descreve.
4. **O capital vem de imprensa concordante**, não de anúncio primário do vendor nem de registro.
5. **O comportamento em pt-BR não foi testado**, e a doc já avisa que não-inglês tem acurácia menor.
   Para um core inteiro em pt-BR, **esta é a lacuna mais cara da lista**.

---

## Fontes

Primárias (tier 10):
- [typesafe.ai](https://typesafe.ai/) · [manifesto](https://typesafe.ai/manifesto) · [team](https://typesafe.ai/team)
- [docs.typesafe.ai](https://docs.typesafe.ai/) — `llms-full.txt` integral (903 KB), com destaque para
  [system-one](https://docs.typesafe.ai/concepts/system-one),
  [machine-learning-primer](https://docs.typesafe.ai/introduction/machine-learning-primer),
  [api](https://docs.typesafe.ai/api),
  [confidence](https://docs.typesafe.ai/confidence),
  [models](https://docs.typesafe.ai/models),
  [patterns](https://docs.typesafe.ai/patterns),
  [how-to-build-with-system-one](https://docs.typesafe.ai/concepts/how-to-build-with-system-one),
  [coding-agents](https://docs.typesafe.ai/introduction/coding-agents),
  [agent-skill](https://docs.typesafe.ai/agent-skill)

Imprensa (tier 4, usada **só** para capital):
- [FinSMEs](https://www.finsmes.com/2026/09/typesafe-ai-raises-40m-in-seed-funding.html) ·
  [The AI Insider](https://theaiinsider.tech/2026/09/17/typesafe-ai-emerges-from-stealth-with-40m-to-build-machine-native-ai-models/) ·
  [Stack Futures](https://stackfutures.com/blog/typesafe-ai-40m-seed-system-one-jev-structured-decisions-2026/) ·
  [Runtime Wire](https://runtimewire.com/article/diogo-almeida-typesafe-jev-40m-seed-pong)

Corpus do Onion citado:
- [`onion-engine-economy.md`](../../../knowledge-base/concepts/onion-engine-economy.md) — Economia de Motores
- [`onion-abstraction-doctrine.md`](../../../knowledge-base/concepts/onion-abstraction-doctrine.md) — Teste do Eixo / Teste do Gatilho
- [`onion-framework-identity.md`](../../../knowledge-base/meta/onion-framework-identity.md) — identidade e posicionamento
