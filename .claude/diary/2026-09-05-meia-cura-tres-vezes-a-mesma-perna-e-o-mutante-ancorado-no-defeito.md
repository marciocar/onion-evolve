---
date: 2026-09-05
instance: onion-evolve
type: learning
classification: public
tags: [elenxo, meia-cura, guarda-por-vocabulario, mutante, roteamento-por-papel, kg-inbox]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "ao revisar perna faseada, procurar o critério que MANDA agir — não a porta; e nunca ancorar mutante numa linha que não foi lida como suspeita"
review_after: 2026-12-05
conflict_class: static
---

# Meia cura três vezes na mesma perna — e o mutante ancorado no próprio defeito

## O que aconteceu

Curei o `/meta:kg-inbox` para rotear por papel (a I3 é fronteira de **repo**, não de **papel**). Três
rodadas adversariais acharam **a mesma classe de defeito**, cada vez um passo mais fundo:

1. **A porta.** Roteei o `Passo 1` e deixei o `Passo 3 (a)` — o filtro de fronteira — perguntando só
   pelo core. O adotante passava a porta e era recusado no filtro seguinte.
2. **O filtro.** Curei o `(a)`. Sobrou o `(b)`/`(c)`: refraseando a recusa em prosa livre fora da
   tabela, a meia cura voltava e a guarda ficava verde.
3. **O fecho.** Curei a prosa. Sobrou `**(c) SINAL REAL DO CORE** → **SELAR**`: o único critério que
   MANDA selar seguia core-only, e o cabeçalho do `Passo 4` repetia a condição. Com porta e filtro
   roteados, a decisão travava no critério positivo.

## A lição que dói

**Eu usei a linha defeituosa como âncora dos meus próprios mutantes.** Ao provar o `mut-E`/`mut-F` eu
substituí exatamente `**(c) SINAL REAL DO CORE** → **SELAR**` por outro texto — li aquela linha três
vezes, escrevi-a de memória num script, e **não a vi**. Âncora de mutante entra no olho como
*estrutura*, não como *conteúdo*: a atenção vai para o que se injeta, nunca para o que se remove.

**Regra que fica:** ao ancorar um mutante, a linha-âncora passa pelo mesmo escrutínio do resto do
diff. Se ela é candidata a âncora, é porque é load-bearing — logo é candidata a defeito.

## A cura de mecanismo (não de disciplina)

Três reancoragens da guarda `(e)`, cada uma abandonando vocabulário por **propriedade estrutural**:

| rodada | a guarda media | passou a exigir |
|---|---|---|
| 1 | presença de `mora NESTE repo` no Passo 1 | os **quatro** passos que decidem |
| 2 | ausência de duas grafias da recusa | a linha da tabela **nomeia a fila que sela**; papel fora da tabela reprova |
| 3 | (nada — não olhava o critério) | **o critério que MANDA selar não nomeia o core**, no `(c)` e no cabeçalho do `Passo 4` |

A prova de que a rodada 2 não virou outra lista foi o `mut-F`: variante **sem nenhum token de recusa**
("em `role: adopted`, consulte o maestro antes de qualquer selagem") que reprova só pela estrutura.

E o texto do comando passou a dizer, na própria linha `(c)`, onde a classe se esconde: *"quem revisa
esta perna: procure o critério que MANDA selar, não a porta"* — o único lugar onde a próxima pessoa
vai olhar.

## Generalização

Numa perna **faseada** (guarda → filtro → critério → execução), curar o roteamento na entrada é o
default errado e sedutor: a mudança fica visível, o gate fica verde, e a recusa migra para o passo
seguinte. **Procure o critério positivo — o que MANDA agir.** É ele que decide; a porta só deixa
entrar.

Ver também: `guarda-por-lista-falha-pelo-vocabulario` (o defeito dominante em guarda de lista é o
vocabulário, não a lógica) e `erro-recorrente-vira-registro-com-cura` (recorrência vira registro de
CLASSE, com a cura anexada — é o que esta migalha é).
