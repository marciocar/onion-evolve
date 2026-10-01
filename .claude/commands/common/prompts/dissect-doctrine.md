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
| **N4 ABSORÇÃO** | o plano: o que entra, por qual costura, qual guarda cobra, qual bancada prova | as quatro respostas, **nomeadas**: artefato, costura SDAAL, guarda determinística, caso de bancada que reprova sem a mudança | não se consegue nomear a guarda que cobraria — absorção sem guarda é desejo |

**Níveis selecionáveis.** `--level N` **para** no nível pedido. É assim que uma varredura de 30
ferramentas custa N0 vezes 30 e não N4 vezes 30.

**N0–N2 DESCREVEM. N3 JULGA. Só N4 recomenda.** Nível raso que recomenda é opinião com
aparência de análise.

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
