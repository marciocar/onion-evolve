---
title: "ADR — Destino declarado em cada decisão do maestro: mecanismo (com card da guarda) ou desenho (só texto)"
date: 2026-11-21
type: adr
status: accepted — aprovado pelo maestro em 2026-11-21; implementação pendente
decision-scope: governança / selo de decisão / dívida de decisão sem guarda
implementation-destination: mechanism
supersedes: none
market-position: superação declarada do padrão (MADR status, ciclo de vida de Nygard)
related:
  - onion-adr-decision-ratchet-2026-11.md
  - onion-adr-guard-merge-batch-2026-11.md
  - onion-adr-heavy-step-queue-2026-11.md
---

# ADR — Destino declarado em cada decisão do maestro

| Campo | Valor |
|-------|-------|
| **Decisão** | Todo selo novo de decisão do maestro declara o **destino**: `mechanism` (a decisão vira guarda, e o selo traz o ponteiro do card ou do nó da guarda a construir) ou `design` (a decisão é desenho e fica como texto, sem cobrança) |
| **Escopo** | Os selos gravados pelo selador do `/meta:decide`, a partir da implementação. Selos antigos, sem o campo, não reprovam |
| **Status** | ✅ **Aceito** em 2026-11-21. **Implementação pendente** |
| **Destino** | **Mecanismo**: campo no selo e contagem da dívida no medidor, o que pede uma guarda |
| **Origem** | Retro da semana de 14 a 21/11/2026 e proposta da curadoria, com confronto de mercado |

---

## Status

✅ **Aceito** em 2026-11-21, pelo maestro, junto com as melhorias A e B da mesma retro.
**Implementação pendente**: a primeira das três a entrar em obra.

## Contexto e problema

Na semana de 14 a 21/11, o maestro deu 49 selos de decisão. Nove viraram mecanismo, como uma guarda ou
um script. Quarenta ficaram como texto.

Parte do texto era desenho de propósito: uma escolha de nome, de forma, de prioridade. Outra parte devia
ter virado guarda e não virou. Sem um campo que diga o destino, não dá para separar uma da outra. A
dívida de «decisão que devia virar guarda» fica invisível.

## Forças da decisão

- Saber, por decisão, se ela deve virar mecanismo ou se é só desenho.
- Cobrar a construção do que é mecanismo.
- Não cobrar o que é desenho.
- Não reescrever o passado: selo antigo sem o campo não vira erro.

## Opções consideradas

1. **Seguir sem o campo.** O destino fica implícito, e a dívida, invisível.
2. **Cada decisão declara o destino.** `mechanism`, com o ponteiro da guarda a construir, ou `design`,
   só texto.

## Decisão

Opção 2.

- O selador passa a exigir o destino em todo selo novo: `x_destination: mechanism` ou
  `x_destination: design` no nó.
- Com `mechanism`, o selo exige também o ponteiro da guarda a construir (`x_guard`): a chave de um card
  do gerenciador de tarefas ou o id de um nó `Q_` do grafo.
- O medidor do `/meta:decide` conta as decisões `mechanism` cuja guarda ainda não foi feita. A dívida
  aparece em toda rodada.
- É uma catraca: só o selo novo precisa do campo. Os selos antigos seguem válidos como estão.

## Consequências

**Positivas**

- A dívida de «decisão que devia virar guarda e não virou» fica visível e contável.
- O desenho deixa de parecer dívida: o texto declarado como desenho não é cobrado.

**Negativas**

- Um campo a mais por selo, e uma pergunta a mais para quem sela: «isto vira guarda?».
- A contagem só enxerga o ponteiro declarado. Ela não prova que a guarda feita cobre a decisão.

## Confronto com o mercado

O mercado registra **se** a decisão foi aceita ou superada. Ele não registra **se** ela virou mecanismo.

- **Campo `status` do MADR.** O MADR 4.0.0 (setembro de 2024) tem um campo de status por registro:
  proposto, rejeitado, aceito, obsoleto, superado. O próprio projeto fixou a forma do campo num registro
  de decisão seu. Fonte: [MADR](https://adr.github.io/madr/).
- **Ciclo de vida de Nygard.** O registro passa de proposto a aceito e a superado, com um link para o
  registro que o supera. O registro aceito não se reabre nem se altera: ele é superado por outro. Fonte:
  [Martin Fowler, «Architecture Decision Record»](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html).
- **Supersede com link.** O `adr-tools` liga os dois registros nos dois sentidos. O guia do governo
  britânico ([GDS Way](https://gds-way.digital.cabinet-office.gov.uk/standards/architecture-decisions.html))
  marca o antigo como «superado», com o link para o novo. O guia da AWS acompanha os estados no ciclo de
  governança.

**Encaixe.** O mais próximo é o `status` do MADR somado a um link da decisão para o artefato. Nenhum
deles separa «virou mecanismo executável» de «ficou só texto». O destino `mechanism` ou `design` é um
eixo novo, de implementação, que o `status` não tem.

Por isso esta decisão se registra como **superação declarada do padrão**, e não como padrão de mercado
já existente. O Onion mantém o `status` do MADR como está e acrescenta o eixo do destino ao lado dele.

## Gatilhos que reabrem esta decisão

- A contagem da dívida cresce sem que as guardas apareçam: o campo virou formalidade, e a cobrança
  precisa de dente (por exemplo, prazo no card).
- Um padrão de mercado passa a registrar o eixo de implementação: o Onion adota a forma dele.

## Referências

- [Catraca de decisões automáticas](onion-adr-decision-ratchet-2026-11.md): a catraca que aprova os
  atos; este registro trata do destino da decisão depois do selo.
- [Merge de guarda em lote](onion-adr-guard-merge-batch-2026-11.md) e
  [Fila única de passo pesado](onion-adr-heavy-step-queue-2026-11.md): as outras duas melhorias da mesma
  retro, ambas com destino `mechanism`.
- Retro da semana de 14 a 21/11/2026, guardada no histórico de evolução do core (não viaja).
