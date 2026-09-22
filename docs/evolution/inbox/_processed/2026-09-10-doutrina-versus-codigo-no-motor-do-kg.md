# Sinal ao core — onze lugares onde a doutrina do KG afirma e o código não faz

**Data:** 2026-09-10 · **Repo:** jogo-da-vida (adotante) · **Medido em:** `/home/marcio/onion-evolve/`
**Origem:** leitura dos instrumentos do Onion para fundamentar um produto (Personal Brain) sobre o `.kg.yaml`.
Cada linha foi **medida na sessão**, com `arquivo:linha` dos dois lados. Nada foi escrito no core (I3).

## Por que isto chega assim

Um adotante foi ler a doutrina para construir em cima dela, e conferiu se ela é verdade no código. Não é,
em onze pontos. Isso não é crítica: é o tipo de coisa que só aparece quando alguém tenta **usar** o sistema
como fundação, e é melhor descobrir agora do que depois de prometer "company brain" a um cliente.

Onde o próprio core já se corrigiu (⚠️10), a correção ficou registrada em vez de apagada — *"apagá-lo
transformaria a vitrine em propaganda"*. Este sinal segue a mesma disciplina.

## Os achados

| # | A doutrina afirma | O código faz | Onde |
|---|---|---|---|
| 1 | atenção = impacto × confiança × **PageRank ponderado** | `impact × conf × sf × (1 + grau)` — sem iteração, amortecimento ou normalização; grau **não direcionado** | `knowledge-graph-sdaal.md:192-193` × `kg-radar.sh:398`, `:345-347` |
| 2 | a integridade reprova **ciclos `DEPENDS_ON`** | não há detecção de ciclo; `grep 'ciclo'` no radar = **0**. `A→B→A` passa com exit 0 | `:196` × `kg-radar.sh:781-815` |
| 3 | reprova `decision` `done` fora do plane PROD | valida `plane` só contra o enum; nenhuma condição composta com `status`/`node_type` | `:196`, `:215-216` × `kg-radar.sh:801` |
| 4 | reprova nó `refuted` ainda recebendo `SUPPORTS` | `SUPPORTS` aparece **uma vez** no motor, na string do enum. A checagem que existe é outra (nó que **recebe `REFUTES`** e segue `confirmed`) | `:196` × `kg-radar.sh:302`, `:806-808` |
| 5 | reprova migalhas pendentes | é ⚠ na seção PROVENIÊNCIA, que **não reprova**. Medido: radar sai **0** com 7 avisos | `:196` × `kg-radar.sh:33-36` |
| 6 | gramática **bi-temporal** (`valid_from`, `source_tier`, `source_kind`) | o motor **não lê** nenhum: `grep` = 0. **9 grafos já preenchem `valid_from`** sem consumidor | `kg-grammar.md:25` × `kg-radar.sh` |
| 7 | `meta.review_after` no mesmo conjunto | quem cobra é o lint (REGRA 67, **SOFT**), não o radar. Quem roda só o radar **nunca sabe que o grafo venceu** | `kg-grammar.md:26` × `lint-artifacts.sh:3807-3828` |
| 8 | valores de `status` fora do enum "passam sem gate — 11 circulando" | o código **reprova** (fator −1). Corpus medido: **3.715 status, zero fora do enum** | `kg-grammar.md:22` × `kg-radar.sh:803`, `lib/status-factor.awk:37` |
| 9 | laço de reconciliação com `drifted` (**único fator que sobe**, 1.3) | **`drifted` = 0 em 3.715 nós.** Nunca foi usado | `lib/status-factor.awk:15-28` × varredura do corpus |
| 10 | *(já corrigido pelo core em 2026-08-16)* a perna de LEITURA como mecanismo | é conselho — *"nenhum dos hooks lê `.kg.yaml`"* | `knowledge-graph-sdaal.md:287-289`, `:296-297` |

**Placar das cinco reprovações prometidas em `knowledge-graph-sdaal.md:195-196`: uma implementada** (órfãos),
três ausentes, uma rebaixada a aviso. **A lista correta do que barra está no cabeçalho do motor
(`kg-radar.sh:27-29`), não na KB.**

## O achado que mais dói, e por que ele é de produto

O ⚠️9 não é um bug: é o laço inteiro de reconciliação **construído e parado**. E a auto-avaliação do próprio
core confirma, em `docs/onion/graph/company-brain-market-2026-07.kg.yaml` (`C_three_verbs_selfcheck`):
*"`/meta:kg-freshness` com **0 runs em 34 dias**, 459/566 nós open (81%) sem nenhuma data"*.

Dos três verbos da definição de "company brain" — estrutura, converter em skills executáveis, **manter
atual** — o terceiro é o que falha. E é justamente o que um adotante compra quando compra a promessa.

**A perna de escrita funciona. A de leitura e a de reconciliação, não.**

## Sugestões (o adotante propõe; quem decide é o core)

1. **Alinhar a KB ao motor, não o contrário** — ou implementar as três reprovações ausentes, ou corrigir
   `knowledge-graph-sdaal.md:195-196` para a lista real. Hoje a KB promete um gate que não existe, e um
   adotante que confie nela constrói sobre areia.
2. **Trocar "PageRank ponderado" por "grau"** na doutrina, ou implementar PageRank. O motor já se corrige a
   si mesmo no cabeçalho (`kg-radar.sh:8`); a KB é que ficou para trás. Grau não distingue "conectado a
   coisas importantes" de "conectado a muitas coisas" — e ordenar atenção é a função central do radar.
3. **Fazer o radar avisar quando `review_after` venceu.** Hoje isso só existe num lint SOFT, e quem roda o
   radar acha que está em dia.
4. **Investigar por que `drifted` nunca foi usado.** Não é falta de motor: o slot existe, tem o peso certo e
   o racional escrito. Ou o laço de medição é caro demais, ou não há gatilho que o chame. Achar isso vale
   mais que qualquer feature nova — é a diferença entre um grafo que é memória e um que é arquivo morto.
5. **Consumir `valid_from`** ou removê-lo da gramática. Nove grafos preenchem um campo que nada lê.
