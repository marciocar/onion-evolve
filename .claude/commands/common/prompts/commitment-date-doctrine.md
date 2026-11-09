# 📅 Doutrina da data no compromisso

Fragmento canônico. O `/product:estimate` e o `velocity-meter.py` **referenciam** este arquivo; nenhum comando o copia.
Regra do maestro, 2026-11-09: *«a data vem quando alguém valida a estimativa e coloca para desenvolvimento, ou alguém fixa a data»*.

## A regra

| Momento | O que existe | O que não existe |
|---|---|---|
| Backlog e fila | pontos e horas | data |
| Alguém validou a estimativa e a issue entrou em desenvolvimento | data: início mais o P80 do histórico, com o acerto do caminho ao lado | |
| Alguém fixou a data à mão | a data, e o registro de quem fixou (`tm.sh due_date.set --set-by`) | |

Data de issue na fila depende de quando alguém decide começar. Medido no core em 2026-11-09, em simulação retroativa de 8 datas: a data
final acertou 19,6% (9 de 46) para issue em fila e 0 de 174 quando supunha início imediato.

## De onde vem (primárias, conferidas em 2026-11-09)

**Scrum Guide (edição de novembro de 2020, <https://scrumguides.org/scrum-guide.html>)** põe o dimensionamento no refinamento e o compromisso no planejamento:

- «Product Backlog refinement is the act of breaking down and further defining Product Backlog items into smaller more precise items.
  This is an ongoing activity to add details, such as a description, order, and size.»
- «The Developers who will be doing the work are responsible for the sizing.»
- «Although the Sprint Goal is a commitment by the Developers, it provides flexibility in terms of the exact work needed to achieve it.»

**Kanban Guide (v2025, <https://kanbanguides.org/english/>)** dá a forma da previsão por item, contada a partir do início:

- «A service level expectation (SLE), which is a forecast of how long it should take a work item to flow from started to finished.»
- «The SLE itself has two parts: a period of elapsed time and a probability associated with that period […]. The SLE should be based on historical cycle time […]»

## O que esta doutrina NÃO promete

- O Scrum Guide assume compromisso sobre o Sprint Goal, não prazo por item; a data por item é o perfil do Onion por cima do padrão, e a forma dela vem do SLE.
- O core não tem sprint: «entrou em desenvolvimento» é o `startedAt` do task manager. O medidor não sabe se alguém validou os pontos, só que eles existem.
- Pontos dados depois da conclusão (`docs/onion/retro-estimates.tsv`) são base prévia, não estimativa validada.
- P80 é a convenção do medidor; o acerto real sai medido ao lado da data, e pode ser baixo ou não medido.
