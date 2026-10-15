# Doutrina da dissecação de ferramenta — o "chupa-cabra" em cinco níveis

Fragmento canônico do [`/meta:dissect`](../../meta/dissect.md). Cunhagem do maestro
(**chupa-cabra de ferramentas**, 2026-10-01): mapear ferramenta de terceiro, entender o que ela
faz, e decidir o que o Onion **absorve**, o que ele **costura**, o que **parqueia como técnica a
investigar** e o que **rejeita com razão escrita**.

Nasce de um problema medido nesta casa, não de vontade de organizar: a sessão que encontra uma
ferramenta nova responde *de memória* se ela já foi vista, e erra. Em 2026-10-01 a mesma rodada
de pesquisa (a) **re-abriu** o Zep, o Port e o Roadie sem ler o que o corpus já dizia e (b)
tratou "a Onyx não entrega grafo" como achado, quando a doc do próprio fornecedor diz
`AI-generated knowledge graphs` e o módulo `backend/onyx/kg` está vivo no código. Dissecar sem
escada é refazer o nível 0 e nunca chegar ao 3.

---

## 1. A escada — cinco níveis, e cada um é um GATE

O corte de custo é a escada, não o orçamento: **nível reprovado não sobe**. Uma ferramenta morta
nunca deve consumir uma análise de mecanismo.

| Nível | Pergunta | O que PROVA a passagem | Reprova quando |
|---|---|---|---|
| **N0 IDENTIDADE** | o que é, quem mantém, licença, está vivo? | trajetória **datada**: commits/releases/estrelas por data, não "é popular" | sem commit no período da cadência, licença incompatível, mantenedor único sem sucessão declarada |
| **N1 CAPACIDADE** | o que ela FAZ que o Onion não faz? | lista de **verbos** extraída da superfície executável (CLI `--help`, API, schema), nunca do marketing | tudo que ela faz o Onion já faz, ou o delta não tem consumidor nomeado aqui |
| **N2 MECANISMO** | COMO faz — substrato, estrutura de dados, onde mora o determinismo | rodou, ou leu o **código-fonte**; nomeia o invariante que ela garante e o que ela não garante | só há declaração do fornecedor sobre o próprio mecanismo |
| **N3 TRANSFERIBILIDADE** | igual → transfere, diferente → desenha | a [régua de transferência](../../../../docs/knowledge-base/concepts/transfer-heuristic-aristotle.md) aplicada **com evidência**, e o veredito escrito | a analogia não sobrevive ao refutador (falsa analogia ou falsa distinção) |
| **N4 ABSORÇÃO** | o plano: o que entra, por qual costura, qual guarda cobra, qual bancada prova | as quatro respostas, **nomeadas**: artefato, costura SDAAL, guarda determinística, caso de bancada que reprova sem a mudança — **escritas como nós `x_absorb_*`** (§4b), que o `/meta:forge` lê | não se consegue nomear a guarda que cobraria — absorção sem guarda é desejo; ou o plano sai INCOMPLETO no leitor |

**Níveis selecionáveis.** `--level N` **para** no nível pedido. É assim que uma varredura de 30
ferramentas custa N0 vezes 30 e não N4 vezes 30.

**N0–N2 DESCREVEM. N3 JULGA. Só N4 recomenda.** Nível raso que recomenda é opinião com
aparência de análise.

---

## 1b. A régua e o estudo (decisões do maestro de 2026-10-14, SAC-135)

**A régua não é fixa no Onion.** "O que ela faz que o Onion não faz" é a pergunta do core. Num hub
ou num adotado, a pergunta certa é contra o **alvo** — o repo que vai receber a peça. Por isso:

- **A régua padrão é o próprio repo** (decisão do maestro de 2026-10-15, SAC-147): onde o dissect
  roda, é sobre ele que N1, N3 e N4 se medem. No core isso **é** o Onion e nada muda; num produto
  adotado, é o produto. A régua padrão é **derivada** pelo censo a partir do carimbo
  `.claude/.onion-version` (sem carimbo, `role: source` ou porta ⇒ `onion`; outro papel ⇒ o id do
  repo, pelo remote `origin`), nunca digitada pela sessão. "Sem carimbo" só é o core quando o medidor
  mora no próprio repo: instalado por plugin, sem carimbo é um produto qualquer, e a régua é o id
  dele; uma fonte desacoplada (`decoupled_from:`) também é soberana. A régua vai **sempre** para
  `meta.x_dissect_against`. O campo `framework:` do carimbo não serve de id: um adotado pode
  carregar o nome da fonte nele.
- `--against <repo>` troca a régua por outro repo (o hub medindo para um adotado) e grava
  `meta.x_dissect_against: <repo>`.
- **A régua pode ser um componente, não o repo inteiro.** `--scope <pathspec[,pathspec]>` grava
  `meta.x_dissect_scope` e estreita N1, N3 e N4 a uma ferramenta, funcionalidade ou biblioteca do
  repo — o caso típico é **trocar o provedor de identidade de um produto**: o N1 pergunta o que a
  ferramenta nova faz que o componente atual não faz, o N3 julga a substituição e o N4 escreve o
  plano para o componente. O escopo é **caminho** (pathspec do git), porque caminho se mede: o leitor
  de planos recusa plano cujo escopo não casa arquivo rastreado no repo da régua
  (`escopo-sem-arquivo`). Nível pago só se reusa na **mesma régua E no mesmo escopo**.
- Com outra régua, **N1** mede o delta contra o alvo, **N3** julga transferir para o alvo e **N4**
  escreve o plano (`x_absorb_*`) para o repo do alvo. **N0 e N2 independem da régua** (descrevem a
  ferramenta); **N1, N3 e N4 dependem**, então nível pago só se reusa na mesma régua.
- O leitor de planos mede as peças **no repo do alvo**, pela raiz que lhe é **passada** (para a
  régua = o próprio repo, a raiz é `.` implícita). Construir
  o caminho a partir do nome do alvo é a classe que a cláusula 1 do censo da forja proíbe; sem a
  raiz o plano sai NAO-MEDIDO, nunca medido contra o repo errado.

**O estudo é uma parada declarada no N2.** `--study` grava `meta.x_dissect_mode: study`, sobe
N0 → N1 → N2 com o N2 medido **rodando a ferramenta isolada**, e para. No lugar do nó `decision`
fica um nó `question` **aberto** ("adotar?"). É aprendizado com mecanismo medido, sem pressa de
veredito. Ler o código-fonte não substitui rodar no estudo; se não der para rodar, o nó do N2
nasce `open` com a lacuna nomeada (§3), como em qualquer dissecação.

- **O que o estudo NÃO promete:** não julga (não há N3), não recomenda e não emite plano. Um nó
  `x_absorb_*` dentro de estudo é recusado pelo leitor de planos; um estudo que passe do N2, traga
  veredito ou feche a `question` sai **INCOERENTE** no censo.
- **Estudo ≠ interrompida.** O censo separa os dois pela coluna `estado`. Dissecação parada no N2
  **sem** o marcador continua sendo **interrompida**: a parada só é intencional quando declarada.
- Modo que o censo não conhece (ex.: `estudo` em vez de `study`) sai **modo-DESCONHECIDO**, nunca
  lido como dissecação normal.

---

## 2. Os quatro vereditos, e nenhum deles é "não sei"

Toda dissecação que chega ao N3 fecha num destes, **com razão escrita**:

- **ABSORVER** — o conceito entra no mecanismo do Onion. Exige o plano N4 completo. Absorver é
  reescrever na gramática da casa, **nunca** vendorizar código alheio por conveniência.
- **COSTURAR** — a ferramenta fica de fora e entra por adapter (SDAAL). O default quando ela é
  boa e **não** precisa ser nossa.
- **PARQUEAR** — técnica a investigar, com **gatilho nomeado**. Parque sem gatilho é cemitério;
  é a cláusula que o [`gated-work-derives-fresh`] cobra. O nó nasce `open`.
- **REJEITAR** — com a razão, datada. Rejeição escrita é ativo: impede a 3ª sessão de re-abrir o
  que duas já fecharam.

**O que NÃO é veredito:** "interessante", "promissor", "vale acompanhar". São parque sem gatilho.

**REJEITAR e PARQUEAR são vereditos NEGATIVOS, e negativo leva superação e critério** (SAC-151). O
maestro, em 2026-10-15: "um juiz de sim ou não sem tentar superação em uma pesquisa pode restringir possibilidades de crescimento e inovação; é preciso ter medição e critérios claros". O nó do veredito declara
`x_dissect_criterion: "<comando que checa a reprovação>"` e `x_dissect_overcoming: <id>`, que aponta o nó
deste grafo com o que supera (aresta dele para a decisão), ou `nenhuma` mais
`x_dissect_overcoming_measure: "<o que se procurou e onde>"`. Sem isso o censo marca
`veredito-SEM-SUPERACAO` e `dissect-census.sh . --check-verdict <ferramenta>` sai 1. Caso-modelo: a
rejeição do markitdown num adotante de curadoria, cuja superação medida foi o `tesseract` local lendo o
PDF escaneado em que a ferramenta saía vazia.

**A superação tem de ENTREGAR, não consolar** (SAC-151, 2ª leva). Antes de apontar
`x_dissect_overcoming: <id>`, responda: *a superação está MEDIDA e ENTREGA o valor que o objeto
prometia, ou é status quo, condição futura ou parte do próprio veredito?* Se não entrega, o
veredito é `nenhuma` com a medida, e isso é válido. O censo recusa o que a forma deixa ver: o nó
do próprio veredito, o nó que **deriva** dele pelas arestas (circular), o nó `open`, sem
`verified_at` legível, com `verified_at` futuro ou sem `verified_against` (não medido), e o nó cujo
`verified_against`/`trace` é igual ao `x_dissect_criterion` (mede a reprovação, não a entrega). A
derivação se lê pelo tipo da aresta: `A SUPPORTS B` faz B derivar de A, `A TRACES_TO B` faz A
derivar de B.
O status quo rotulado de superação **não** é detectável sem palavra-chave frágil. Ele fica com a
pergunta e com o Elenxo. Caso-modelo do consolo: um adotante de curadoria (PR #30) preencheu quatro
superações que passaram na forma e que o Elenxo reprovou.

---

## 3. Evidência: executar quando der, ler quando não der, e DECLARAR qual foi

A doutrina da casa é **behavior-over-declaration** — o que a ferramenta FAZ vence o que ela diz
de si. Logo:

- **N2 exige comportamento**: rodar a ferramenta, ou ler o código-fonte. Página de produto é
  fonte de N0/N1, nunca de N2.
- **Quando não for possível rodar**, o nó nasce `open` com a **lacuna nomeada** — nunca
  `confirmed`. "Não pude medir" é desfecho de 1ª classe; declarar mecanismo por folheto não é.
- **Executar é ato isolado.** Ferramenta de terceiro roda em worktree/container, nunca na árvore
  de trabalho. A fronteira é mecanismo, não disciplina: um refutador com instrução em prosa
  para não escrever escreveu em seis arquivos (medido 2026-09-20).
- **`source_tier` é a escala DREAM 1–10, onde 10 é a mais forte** e `<= 3` é fraca. Primária do
  fornecedor sobre si ≈ 9; arquivamento regulatório ≈ 10; enciclopédia ≈ 5;
  `vendor-on-competitor` é sempre suspeito. *(Esta linha existe porque eu carimbei um
  arquivamento da SEC como `source_tier: 1` em 2026-10-01, lendo a escala ao contrário.)*

---

## 4. Corpus primeiro — o nível 0 pode já estar pago

Antes de abrir qualquer fonte externa, **medir o que a casa já sabe**: a peça 3 do comando
(`dissect-census.sh`) lista as dissecações existentes, o nível alcançado e o frescor. Ferramenta
já dissecada no N2 com carimbo fresco **entra no N3 direto**. Re-derivar nível pago é o
desperdício que esta doutrina existe para cortar.

E o inverso vale igual: dissecação **vencida** não se cita como se fosse de hoje. Página de
preço, licença e mantenedor mudam em semanas — a cadência de revisita do grafo manda.

---

## 4b. A passagem para a forja — o plano é NÓ, e o que já existe é MEDIDO

Até 2026-10-11 o veredito terminava em prosa no nó de decisão e nada o entregava ao
[`/meta:forge`](../../meta/forge.md) (medido: só 2 grafos citavam o dissect, e nenhum chegara ao
N4). O dogfood do Conductor, a 1ª dissecação a chegar ao N4, fixou a forma mínima, sem comando novo:

1. **Peças** — `x_absorb_target` + `x_absorb_pieces`. Quais já existem no alvo **não se escreve**:
   o leitor (`dissect-plans.sh`) roda o `forge-census.sh` e mede. Campo digitado de
   "peça existe" seria plano preenchido sem medir.
2. **Proveniência e licença** — `x_absorb_origin` (URL **com pin**) + `x_absorb_license`. Absorver
   sem registrar a origem é o roubo que a casa proíbe.
3. **Paridade** — `x_absorb_parity` nomeia a família de bancada onde o caso que reprova sem a peça
   será cobrado: a peça faz o que a original fazia.
4. **Forma** — `x_absorb_form`: `reescrita` (o conceito na gramática da casa), `adapter-sdaal`
   (costurar: a ferramenta fica de fora) ou `vendor-pin` (como o contrato do KG-SSOT). Código
   `proprietary` nunca é vendorizado.

O leitor confere **forma**, não **verdade**: não abre a rede para provar que a licença é aquela.
Quem preenche mede a origem (N0 com fonte primária); o leitor recusa o plano que nem a declara.

---

## 5. O que esta doutrina NÃO promete

- **Não julga qualidade de software.** Ela decide **encaixe no Onion**, não se a ferramenta é
  boa. Ferramenta excelente sem consumidor aqui reprova no N1, e isso não é demérito dela.
- **Não substitui a pesquisa de mercado.** O eixo capital/M&A segue invariante da
  [doutrina de pesquisa](research-doctrine.md) — uma dissecação que ignora quem paga mede
  metade do objeto.
- **Não produz absorção.** Ela produz o **plano** e o nó `decision` **`open`**. Quem sela é o
  maestro; quem implementa é o fluxo normal (`/engineer:*`, PR, gate).
- **Não sabe o que ninguém escreveu.** O censo mede dissecações **declaradas no corpus**.
  Ferramenta que nunca foi anotada em lugar nenhum é invisível a ele, e ele diz isso em vez de
  fingir cobertura.
- **Não roda sozinha.** Maestro-invocada; sem cron, sem `/loop` (MOAT W7).
