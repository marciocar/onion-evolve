---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: a régua determinística do quadro reprovou entre dois modelos, e lições de operação da sessão
reviewed_for_public: true  # relido pelo core em 2026-11-08 (REGRA 113)
---

# Sinal da curadoria ao core

Fonte: `docs/evolution/research/analysis-frameworks-board-2026-11/` no repositório da curadoria, nós
`E_WAVE1_RULER_TEST_FAILED_1108` e `E_WAVE1_AMENDMENT1_TEST_FAILED_1108`. As saídas brutas estão em `evidence/`.

## 1. Resultado negativo: comparar contra o que o Onion já tem não se fixou por régua

O quadro padronizado tinha uma coluna "o que o Onion já tem", com valor por tabela de três critérios (mesma saída,
mesma entrada, mesmo gate). O pré-registro exigia no máximo 2 divergências em 13 casos entre dois condutores de
famílias diferentes (subagente Claude e Codex CLI), com o mesmo brief e contextos separados.

| Rodada | O que estava fixo | Divergências em 13 |
|---|---|---|
| 1 | só a tabela e o comando de busca; termos de busca livres | 11 |
| 2 (emenda 1) | também os mecanismos candidatos e a forma do item, por caso | 6 |

- **Maior fonte de divergência:** os termos de busca, que decidem a lista de mecanismos. Um condutor buscou só o nome
  próprio e achou nada; o outro acrescentou sinônimos e achou mecanismos.
- **O que restou com a lista fixa:** o julgamento do gate e da forma do lado do Onion.
- **Wardley como régua:** 1 de 10 itens concordou nas duas linhas (limite: 8). Ficou só como vocabulário.
- **Consequência selada pelo Maestro:** a coluna virou julgamento declarado, de um condutor conferido por revisor
  separado. Os limiares não foram afrouxados.
- **O que não foi medido:** n de 13 casos, um par de modelos, e assimetria na rodada 1 (o Codex recusou a execução
  única, dizendo que um JSON completo "seria inventado", e rodou um caso por vez).

**Por que importa ao core:** o campo `onion` do `x_dissect_idea` (`temos | nao-temos | diferente`) depende do mesmo
julgamento. A doutrina define "diferente" só pelo porquê no `why`. Esta medida sugere não tratar esse valor como
reprodutível entre condutores.

**Pedido:** ler isso ao decidir o que o `x_dissect_idea` promete. Se valer, declarar o campo como julgamento.

## 2. Lições de operação (medidas nesta sessão)

- **`kg_query` conta o nó de partida.** Um `x_dissect_trigger` com `min_count: 1` nasce disparado (o checador acusou
  `gatilho-ja-disparou`, sem nenhuma superação). O mínimo útil é 2. Vale documentar no contrato do campo.
- **Radar e contrato passam onde o checador de dissecação reprova.** Um grafo com radar 0 e contrato ok falhou no K3
  do CI. Em grafo de dissecação, os três precisam rodar antes do push.
- **Selo que vive só no anúncio não fecha peça.** O `x_dissect_sealed_by` exige nó no core. Isso apareceu nas respostas
  à onda 2 e o core já está curando.
- **`gh pr checks` sai com erro quando um check falha.** Um laço de espera que condiciona a saída ao rc nunca termina,
  e a falha fica muda. Isso aconteceu aqui: um laço ficou 25 min preso.
- **A guarda do `.env` dá falso positivo em heredoc.** Barrou duas vezes um comando cujo texto de heredoc, em prosa,
  casou o padrão. Nada vazou; o custo é refazer o passo.
- **A guarda de PR sem resíduo** avisou num PR cuja branch local tinha outro nome que a remota, com o resíduo
  commitado pelo nome da remota. Parece procurar pelo nome local; é inferência, não li o código da guarda.

**Pedido:** avaliar os dois primeiros itens como correção de doutrina e os dois últimos como ajuste de guarda. Nada aqui
pede selo urgente.

**Triagem (core, 2026-11-08):** o campo como julgamento, o min_count e os três checadores entraram em dissect-doctrine.md neste PR; a guarda de resíduo virou Q_IT_RESIDUE_GUARD_REMOTE_BRANCH. O falso positivo em heredoc é teto já declarado na guarda; o rc do gh pr checks fica como lição.
