---
title: "Dissecação das duas contradições do manifesto do onion-slm com a doutrina do core (card SAC-487)"
date: 2026-11-21
from: onion-curation
to: onion-evolve (core)
type: dissect-signal
family: pratica
request: "Core → curadoria (2026-11-21): dissecar os dois pontos em que o manifesto do onion-slm diz contradizer a doutrina do core; por ponto, a afirmação de cada lado com arquivo:linha, quem tem a evidência mais forte, e o veredito da família."
reviewed_for_public: true  # relido pelo core em 2026-11-21 como se publicado: só cita grafos públicos do core e do onion-slm, sem cliente, pessoa ou segredo
---

# Dissecação — as duas contradições manifesto-slm × doutrina do core

A curadoria **disseca e propõe**; o core sela. Nada aqui é selado.

## Escopo e como cheguei aos dois pontos

O objeto é o manifesto `docs/manifesto/onion-brain-manifesto-2026-11.md` do **onion-slm** (só leitura).
O caderno de leitura dele rotula **dois** itens, lado a lado, como "Contradição entre o core e …"
(`docs/manifesto/notes/reading-log.md:384-390`), e são esses os dois pontos:

1. **Passagem da porta 0** — inspeção humana de ≥50 amostras (doutrina do core) × verificação por regra + dois leitores LLM (prática do onion-slm).
2. **Veto a LLM-as-judge** — "não serve de gate em etapa nenhuma" (core) × dois leitores LLM verificando o **gabarito** (não julgando o modelo).

Os dois foram registrados pelo próprio onion-slm no nó `E_DOCTRINE_VS_DOGFOOD_INSPECTION`
(`docs/manifesto/onion-brain-manifesto-2026-11.kg.yaml:308-317`, "registrada e não resolvida").
Um terceiro candidato — **CONSTRAINS em audit** — **não é contradição viva**: o core já o resolveu
(ver o rodapé). Família do objeto, conforme o core pediu: **pratica** (vereditos absorver · costurar · parquear · rejeitar).

**Achado central (vale para os dois pontos):** as duas contradições são a mesma, vista por dois ângulos.
Ambas somem com **uma** distinção que a doutrina do core ainda não nomeia:
**leitor-LLM-que-verifica-o-gabarito ≠ juiz-LLM-que-julga-o-modelo.**

---

## Ponto 1 — porta 0: inspeção humana × regra + dois leitores

**Afirmação do core.** A porta 0 "PASSA quando: o eval existe, roda no harness e foi **inspecionado à
mão (≥50 amostras, guidebook)**" — `C_STAGE0_GATE_BEFORE_ANY_MODEL`,
`docs/evolution/research/slm-frameworks-2026-10/slm-frameworks-2026-10.kg.yaml:857`
(resumo em `SYNTHESIS.md:42`). A fonte é o Evaluation Guidebook, ancorada por verificador independente:
"Take 50 random samples and manually inspect them" (`E_GUIDEBOOK_INSPECT_50_SAMPLES`, mesmo grafo, l.258-268).

**Afirmação do onion-slm.** A porta 0 passou "com ≤2 prováveis erros por tarefa de gate na verificação
por **regra e dois leitores**" — `D_STAGE0_PASS_BY_VERIFICATION`
(`docs/onion/graph/onion-slm-stage0.kg.yaml:688`), sustentada por `D_VERIFY_BY_RULE_AND_TWO_READERS`
(mesmo arquivo, l.636-645): regra determinística + dois leitores LLM às cegas (opus e sonnet 5.5, sem
gabarito/ids/status), e **cada divergência recorrente vira pergunta de REGRA ao maestro**. O selo diz
"verificado por regra e dois leitores", não "inspecionado por humano". Motivo declarado: o maestro
não confiou no próprio juízo caso a caso (`E_MAESTRO_VERDICTS_GUESSED`), e "a sessão do core não pode
ser leitora, porque já leu os gabaritos".

**Quem tem a evidência mais forte.** Dividido, com vantagem para o onion-slm no ponto estreito:
- A favor do onion-slm: a **própria âncora do core admite o limite** — a quote do Guidebook cobre
  "inspecionar" um dataset **existente** e **não dá tamanho mínimo** (`E_GUIDEBOOK_INSPECT_50_SAMPLES`
  label, l.268: "a seção trata de dataset EXISTENTE, não de dataset próprio de erros reais … NÃO DÁ:
  tamanho mínimo"). "Inspecionar à mão" é **ler amostras para corrigir** — que é o que dois leitores
  cegos fazem sobre o gabarito, não julgar um modelo. E o onion-slm tem um resultado **medido**
  (node_type 1, edge_type 2 erros prováveis).
- A favor do core: a preocupação de **calibração de um anotador só** é legítima (ver Ponto 2); dois
  leitores LLM sem padrão-ouro humano não estabelecem concordância humano-humano. O onion-slm **mitiga**
  isso escalando a divergência como **pergunta de regra ao maestro** (humano decide regra, não rótulo).

**Veredito proposto: `costurar`.** Não há conflito real quando se separa "inspecionar o gabarito" de
"julgar um modelo". Costurar à doutrina da porta 0 que a inspeção pode ser cumprida por
**regra + leitores cegos verificando o gabarito, com as divergências escaladas como perguntas de regra**,
quando não há anotador humano qualificado — o core **mantém** o requisito de inspeção/≥50, só nomeia o
mecanismo aceitável. Não é `absorver` (não é gate novo; é refino). Não é `rejeitar` (a prática é sólida
e medida). Não é `parquear` (é acionável e barato: edição de doutrina).

---

## Ponto 2 — veto a LLM-as-judge × dois leitores verificando o gabarito

**Afirmação do core.** "LLM-as-judge **NÃO serve de gate em etapa nenhuma** enquanto o Onion tiver um
rotulador só. A calibração exige correlação LLM-humano ≈ humano-humano (Yan) … **juiz LLM, se entrar,
é sinal auxiliar, não gate.** O gabarito do Onion fica no corretor determinístico sobre nós selados" —
`C_LLM_JUDGE_VETOED_SINGLE_ANNOTATOR`
(`docs/evolution/research/slm-frameworks-2026-10/slm-frameworks-2026-10.kg.yaml:913`; `SYNTHESIS.md:57`).
Status `open`, confiança 0,75.

**Afirmação do onion-slm.** O veto conflaria duas coisas: usar leitores LLM para **verificar o gabarito**
(ground-truth) é diferente de LLM-as-judge **julgando o modelo**; "a distinção é real (gabarito ×
julgamento), mas a doutrina do core não a faz" (`reading-log.md:388-390`). A previsão 9 pede que o core
absorva a distinção e critica "o veto **absoluto** permanece sem a distinção"
(`P_CORE_ABSORBS_READER_VS_JUDGE_2027_12`, grafo do manifesto l.739-750). Evidência de uso real:
dois leitores cegos contestaram 116 de 224 rótulos no v4 (`E_V4_VERIFICATION`).

**Quem tem a evidência mais forte.** Dividido, e aqui **o core está mais certo no que o manifesto
ataca**:
- Contra o manifesto: o veto do core **não é absoluto**. O nó já o restringe ao papel de **gate**
  ("não serve de **gate**") e já **permite** o uso auxiliar ("se entrar, é sinal auxiliar"). Chamar o
  veto de "absoluto" é exagero do manifesto — correção que levo de volta ao onion-slm.
- A favor do onion-slm: a distinção **ainda não está nomeada**. "Verificar o gabarito com leitores
  cegos" é atividade distinta de "julgar o modelo" e de "construir o gabarito"; e o "o gabarito fica no
  corretor determinístico sobre nós selados" pode ser lido como se **excluísse** leitores da verificação
  do gabarito. Nomear a distinção fecha a lacuna.

**Veredito proposto: `costurar`.** Costurar a distinção em `C_LLM_JUDGE_VETOED_SINGLE_ANNOTATOR`:
(a) o **veto de gate permanece** — juiz-LLM que pontua o modelo não é gate com um anotador só;
(b) **leitor-LLM que verifica/contesta o gabarito** (cego, modelos diferentes, divergência → pergunta de
regra ao humano) é atividade **distinta e permitida** — é inspeção, não julgamento. Com a **correção ao
onion-slm**: largar o enquadramento "veto absoluto"; o core já o escopou a "gate", então a costura é
nomear/clarificar, não derrubar.

---

## A costura única (a peça proposta ao core)

Os dois pontos pedem **uma** edição de doutrina, não duas: nomear, na doutrina de eval do core, a
distinção **leitor-de-gabarito ≠ juiz-de-modelo**, com três papéis separados de LLM sobre o eval:

| papel do LLM | o que faz | status na doutrina |
|---|---|---|
| **juiz-de-modelo** (LLM-as-judge) | pontua a saída do modelo como gate | **vetado** como gate com 1 anotador (mantém) |
| **leitor-de-gabarito** | lê amostras às cegas e contesta os rótulos; divergência → pergunta de regra ao humano | **permitido** — é a "inspeção à mão" cumprida por mecanismo (nomear) |
| **construtor-de-gabarito** | gera os rótulos de ground-truth | fora do escopo deste sinal (não proposto) |

Com essa costura, a porta 0 (Ponto 1) passa a aceitar regra + leitores-de-gabarito como inspeção, e o
veto (Ponto 2) fica escopado a juiz-de-modelo. **Onde medir a calibração** (a preocupação válida do core)
vira: amostrar divergências dos leitores e levá-las ao humano como regra — o que o onion-slm já faz.

## O que o core sela

Nada é selado aqui. Proponho: **costurar** os dois pontos pela peça única acima; se o core aceitar, o
crédito do sinal é do **onion-slm** (a previsão 9 pede exatamente isso). A correção ao enquadramento
"veto absoluto" volta ao onion-slm como limite declarado, não como bloqueio.

---

### Rodapé — o terceiro candidato (CONSTRAINS em audit): já resolvido, `parquear`

O manifesto lista um terceiro sinal esperando o core — **CONSTRAINS válido em audit**
(`D_CONSTRAINS_VALID_IN_AUDIT`, `docs/onion/graph/onion-slm-stage0.kg.yaml:594-603`, selado 2026-10-06).
**Não é contradição viva:** o core já absorveu isso no **mesmo dia**. A ontologia e a gramática já
listam CONSTRAINS nas duas camadas, medido no corpus (724 de 777 arestas CONSTRAINS ligam nós de audit):
`docs/knowledge-base/concepts/onion-kg-ontology-hierarchy.md:37-45` (commit `2d316566`) e
`.claude/rules/kg-grammar.md:19`. A evidência mais forte é do core, e aponta para onde o onion-slm
queria. Veredito: **parquear** (já absorvido; só atualizar o manifesto do onion-slm para fechar o nó).

---

Orquestrado com 🧅 Onion Evolve
