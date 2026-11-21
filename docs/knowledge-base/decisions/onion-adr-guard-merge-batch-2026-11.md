---
title: "ADR — Merge de guarda em lote: «pode rodar lote», só PR verde e revisado, registro por merge"
date: 2026-11-21
type: adr
status: accepted — aprovado pelo maestro em 2026-11-21; implementação pendente
decision-scope: governança / merge de guarda / aprovação do maestro
implementation-destination: mechanism
supersedes: none
related:
  - onion-adr-decision-ratchet-2026-11.md
  - onion-adr-decision-destination-2026-11.md
  - onion-adr-heavy-step-queue-2026-11.md
---

# ADR — Merge de guarda em lote

| Campo | Valor |
|-------|-------|
| **Decisão** | Um «pode rodar lote» na catraca de decisões aprova vários PRs de guarda de uma vez. Entra no lote só o PR com CI verde e com revisão isolada no resíduo. Cada merge fica registrado, um por um |
| **Escopo** | PRs que tocam guarda (check de lint, hook, bancada), que hoje só o maestro mergeia, um de cada vez |
| **Status** | ✅ **Aceito** em 2026-11-21. **Implementação pendente** |
| **Destino** | **Mecanismo**: muda a catraca e pede um card da guarda a construir |
| **Origem** | Retro da semana de 14 a 21/11/2026 (trava 1) e proposta da curadoria, com confronto de mercado |

---

## Status

✅ **Aceito** em 2026-11-21, pelo maestro, junto com as melhorias B e D da mesma retro.
**Implementação pendente**: a catraca ainda não distingue «lote» de «um».

## Contexto e problema

Guarda é uma regra que barra um erro antes do merge. A catraca de decisões é a régua que diz quem aprova
cada ato. Por ela, PR que toca guarda nunca é automático: só o maestro o mergeia, e um de cada vez.

Na semana de 14 a 21/11, doze PRs de guarda ficaram na fila. Cada um pedia um toque do maestro. A fila
travou o ritmo das sessões, que esperavam o merge para seguir.

## Forças da decisão

- Reduzir o número de toques do maestro.
- Manter a segurança: cada guarda continua revisada sozinha.
- Deixar rastro de quem mergeou o quê, e quando.

## Opções consideradas

1. **Seguir como está.** Um toque por PR.
2. **Merge em lote pela catraca.** «pode rodar lote», só PR com CI verde e revisão isolada, com registro
   por merge.
3. **Mergear guarda sem revisão.** Rejeitada: tira a segurança que justifica a classe da guarda.

## Decisão

Opção 2. O maestro digita «pode rodar lote» uma vez. A catraca monta o lote com os PRs de guarda que
cumprem as duas condições:

- o CI do PR está verde no head atual;
- o resíduo da revisão (REGRA 56: PR aberto carrega o resíduo da passada adversarial) registra uma
  revisão isolada, feita por quem não escreveu o código, e o carimbo bate com o diff.

Os detalhes acima (CI verde no head atual, carimbo do resíduo batendo com o diff) são desenho de
implementação proposto pelo core; a obra os confirma ou ajusta.

O PR que falha uma condição fica fora do lote e aparece nomeado, com o motivo. Cada merge do lote gera
uma linha de registro própria, com o PR, o head e o resultado.

A força da aprovação segue a da catraca: a frase digitada vale para o lote listado na hora, e só para
ele.

## Consequências

**Positivas**

- Menos toques do maestro. A fila de guarda não acumula.
- Cada PR continua com a sua revisão isolada antes de entrar no lote.

**Negativas**

- A catraca precisa distinguir «lote» de «um», e mostrar a lista antes da frase.
- Risco de mergear junto algo que pedia um olhar sozinho. A revisão isolada por PR, antes do lote,
  reduz esse risco, mas não o zera.

## Confronto com o mercado

O mercado apoia a ideia de agrupar merges com cada unidade verde.

- **Merge queue do GitHub.** Agrupa PRs num «merge group» e roda os checks por grupo. Cada entrada do
  grupo testa o PR somado aos que estão à frente dele na fila. Com a estratégia **ALLGREEN**, o commit de
  cada entrada precisa passar em todos os checks obrigatórios. Com a HEADGREEN, basta a cabeça do grupo.
  O tamanho do grupo é configurável. Exige proteção de branch, checks obrigatórios e o evento
  `merge_group` nos workflows. Fontes:
  [Managing a merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)
  e [REST de rulesets](https://docs.github.com/en/rest/repos/rules) (`grouping_strategy`).
- **Merge trains do GitLab.** Cada pipeline testa o MR junto com todos os que estão à frente. O MR
  entra quando o seu pipeline passa e os da frente entram. Uma falha tira o MR do trem e reinicia os de
  trás. Disponível nos planos Premium e Ultimate. Fonte:
  [Merge trains](https://docs.gitlab.com/ci/pipelines/merge_trains/).

**Encaixe.** O padrão de mercado dispensa o toque humano: basta CI verde e proteção de branch. A decisão
do Onion **acrescenta** duas coisas acima do padrão, sem contrariá-lo: a revisão humana isolada por PR e
o registro por merge. A condição do Onion também é diferente da do mercado: lá, cada entrada é testada
somada às da frente; aqui, cada PR precisa de CI verde no próprio head e de revisão isolada antes de
entrar no lote. O que as duas têm em comum é não deixar entrar unidade que não passou.

## Gatilhos que reabrem esta decisão

- Um PR de guarda mergeado em lote causa incidente: volta o merge de um em um até a causa ser medida.
- A catraca afrouxa a classe da guarda por histórico: o lote pode virar o caminho padrão.

## Referências

- [Catraca de decisões automáticas](onion-adr-decision-ratchet-2026-11.md): classes, força da aprovação,
  merge de guarda nunca automático.
- [Destino declarado em cada decisão](onion-adr-decision-destination-2026-11.md): por que este registro
  traz o campo «destino».
- Retro da semana de 14 a 21/11/2026, guardada no histórico de evolução do core (não viaja).
