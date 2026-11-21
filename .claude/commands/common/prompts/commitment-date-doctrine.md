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

## Data é previsão, não espera (2026-11-21)

Reforço do maestro: «nem toda data é espera; isso não pode ser memória, tem de ser doutrina e maquinaria». Toda data
de issue ou de nó é **previsão** por padrão: diz quando se previu terminar, não quando se pode começar. Ela só vira
**espera** quando o item declara a causa que trava, no título, no corpo ou na narrativa:

| Causa declarada | Exemplo de marcador |
|---|---|
| prazo pré-registrado de terceiros | «pré-registro», «pré-registrado» |
| aguarda pessoa nomeada | «aguarda <quem>», «bloqueado no maestro», «· maestro» |
| gatilho medido | «gatilho: <o que se mede>» |
| janela de observação | «janela de observação até <data>» |

Sem marcador, o item com data futura é **adiantável**. Ao terminar uma tarefa, a sessão consulta a orquestração (a
própria fila e a do core) e pergunta, item por item, se faz sentido adiantar o que tem data futura. O pulso da batuta
(`.claude/validation/baton-pulse.sh`) aplica a regra: lista o adiantável na oferta com a data prevista e conta à parte
o que está em espera declarada. A cláusula 11 da [doutrina da batuta](baton-doctrine.md) é a irmã desta.

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
