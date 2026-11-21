---
title: "ADR — Fila única de passo pesado na máquina compartilhada, com teto de 2 ao mesmo tempo"
date: 2026-11-21
type: adr
status: accepted — aprovado pelo maestro em 2026-11-21; implementação pendente
decision-scope: operação / carga da máquina compartilhada / pre-commit e bancada
implementation-destination: mechanism
supersedes: none
related:
  - onion-adr-guard-merge-batch-2026-11.md
  - onion-adr-decision-destination-2026-11.md
  - ../concepts/onion-dogfooding-doctrine.md
---

# ADR — Fila única de passo pesado

| Campo | Valor |
|-------|-------|
| **Decisão** | Uma fila única serializa os passos pesados da máquina compartilhada, com teto de **2 ao mesmo tempo**. O terceiro espera a vez |
| **Escopo** | Passos pesados das sessões e agentes que dividem uma máquina: pre-commit, bancada de testes (lint-selftest), fechamento de PR |
| **Status** | ✅ **Aceito** em 2026-11-21. **Implementação pendente** |
| **Destino** | **Mecanismo**: uma fila (semáforo) na máquina, que pede um card da guarda a construir |
| **Origem** | Retro da semana de 14 a 21/11/2026 (trava 3) e proposta da curadoria, com confronto de mercado |

---

## Status

✅ **Aceito** em 2026-11-21, pelo maestro, junto com as melhorias A e D da mesma retro.
**Implementação pendente**: hoje cada sessão confere a carga por conta própria, sem fila comum.

## Contexto e problema

Várias sessões e agentes rodam numa só máquina. Cada um dispara os próprios passos pesados: o
pre-commit, a bancada de testes, o fechamento de PR. Ninguém sabe quantos outros estão rodando.

Na semana de 14 a 21/11, a carga da máquina passou de 15 quando vários passos pesados rodaram juntos.
Tudo ficou lento, inclusive o que era leve. A regra de hoje é de disciplina: parar com carga 15 ou mais
e voltar abaixo de 12. Ela depende de cada sessão medir antes, e não impede dois passos de começar no
mesmo minuto.

## Forças da decisão

- Limitar a carga da máquina de forma previsível.
- Não parar o trabalho: só pôr o pesado em fila.
- Medir antes de pensar em máquina maior.

## Opções consideradas

1. **Seguir sem limite.** Cada sessão confere a carga e decide sozinha.
2. **Fila única com teto de 2 passos pesados ao mesmo tempo.**
3. **Máquina maior.** Custa mais e só adia o problema: o número de sessões cresce junto.

## Decisão

Opção 2. Uma fila única na máquina conta os passos pesados em curso. Com dois rodando, o terceiro espera
a vez, em vez de começar e somar carga.

O teto vale para a máquina inteira, não por sessão. Os detalhes a seguir são desenho de implementação proposto pelo core; a obra os confirma
ou ajusta. A espera é declarada: quem está na fila vê a sua
posição e quem está à frente. Um passo que morre sem liberar a vaga não pode prender a fila para sempre:
a vaga vence por prazo, como o resto da orquestração mede ociosidade por prazo.

## Consequências

**Positivas**

- Carga previsível, sem sobrecarga por coincidência de horário.
- A regra de carga deixa de depender da disciplina de cada sessão.

**Negativas**

- Um passo pesado pode esperar na fila.
- É preciso um mecanismo de fila (trava ou semáforo) na máquina, com prazo de vaga e bancada própria.
- Um runner que mata processo longo pode matar quem está esperando: a espera tem de contar no teto de
  tempo de quem chama.

## Confronto com o mercado

O mercado limita trabalho pesado por máquina há tempo, com nome e configuração próprios.

- **`concurrent` do GitLab Runner.** No `config.toml`, fixa o teto de jobs simultâneos em todos os
  runners registrados no processo, que na prática é a máquina (por exemplo, `concurrent = 4` deixa no
  máximo 4 jobs). O `limit` por runner afina o teto. Fonte:
  [Advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/).
- **`max-parallel` do GitHub Actions.** Limita quantos jobs de uma matriz rodam de uma vez. A
  documentação traz o exemplo `max-parallel: 2`, o mesmo teto desta decisão, mas por workflow. Fonte:
  [Run job variations](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations).
- **`concurrency` do GitHub Actions.** Serializa ou enfileira execuções de um grupo. Não expressa um teto
  N arbitrário por máquina. Fonte:
  [Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

**Encaixe.** O mais próximo do «teto de 2 na máquina» é o `concurrent` do GitLab Runner, um teto
explícito por máquina. A fila única preenche a lacuna do `concurrency` do Actions, que não tem teto N
por máquina. A decisão segue o padrão de concorrência de runner próprio.

## Gatilhos que reabrem esta decisão

- A espera média na fila passa a travar o trabalho mais do que a carga travava: rever o teto.
- A máquina muda de tamanho: o teto de 2 é medido de novo.

## Referências

- [Doutrina de dogfooding](../concepts/onion-dogfooding-doctrine.md): rodar o artefato de verdade, que é
  o que gera os passos pesados.
- [Merge de guarda em lote](onion-adr-guard-merge-batch-2026-11.md) e
  [Destino declarado em cada decisão](onion-adr-decision-destination-2026-11.md): as outras duas
  melhorias da mesma retro.
- Retro da semana de 14 a 21/11/2026, guardada no histórico de evolução do core (não viaja).
