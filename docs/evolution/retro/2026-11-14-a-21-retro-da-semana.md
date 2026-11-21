---
title: "Retro da semana de 14 a 21 de novembro de 2026"
date: 2026-11-21
type: retro
period: 2026-11-14 a 2026-11-21
origin: "proposta da curadoria, recebida como sinal e arquivada em docs/evolution/inbox/_processed/2026-11-21-retro-documentacao-ls-e-adr.md"
plain_language: "NBR ISO 24495-1:2024 (Linguagem Simples): relevante, localizável, compreensível e usável"
decisions:
  - ../../knowledge-base/decisions/onion-adr-guard-merge-batch-2026-11.md
  - ../../knowledge-base/decisions/onion-adr-heavy-step-queue-2026-11.md
  - ../../knowledge-base/decisions/onion-adr-decision-destination-2026-11.md
---

# Retro da semana de 14 a 21 de novembro de 2026

**Resumo:** a semana entregou muito, seis pontos travaram o ritmo, e o maestro aprovou três melhorias.

## Para que serve este texto

Este texto conta o que o ecossistema fez na semana e o que atrapalhou. Serve para o time olhar junto e
decidir o que melhorar.

Os números vêm de um levantamento de fatos feito pela curadoria. Aqui está só a forma pública. Ela não
traz nomes de pessoas, de clientes nem detalhes de operação.

## O que andou bem

- **O time entregou muito e rápido.** Foram 211 mudanças mergeadas na semana. A maioria entrou em menos
  de duas horas.
- **Saíram dois estudos profundos.** Um sobre o contrato do canal de conversa. Outro sobre a peça de
  páginas abertas por link.
- **As ferramentas de base ficaram atualizadas.**

## O que travou

1. **A fila de merge do maestro.** Doze mudanças de guarda ficaram esperando. Guarda é uma regra que
   barra um erro, como um check de lint ou um hook. Só o maestro mergeia uma guarda, e uma de cada vez.
   Por isso elas se acumularam.
2. **Sessões paradas com trabalho possível.** Algumas sessões pararam à espera de uma resposta. Elas não
   voltaram, mesmo com trabalho a fazer.
3. **A carga da máquina passou de 15.** Vários passos pesados rodaram juntos na mesma máquina. Passo
   pesado é um pre-commit ou uma bancada de testes. A máquina ficou lenta para todos.
4. **Quedas por limite de uso.** O limite de uso da conta derrubou agentes no meio do trabalho.
5. **Troca de login e sessão duplicada.** Uma troca de login e duas sessões abertas ao mesmo tempo
   confundiram quem fazia o quê.
6. **Atalhos de shell.** Em alguns casos, um comando avulso de shell substituiu o caminho próprio da
   casa.

## O que o maestro decidiu melhorar

Em 21/11 o maestro aprovou três melhorias. Cada uma tem um registro de decisão próprio. O registro
segue o padrão de mercado MADR (Markdown Architectural Decision Records), chamado ADR. O registro traz o problema, as opções, o que o mercado faz e o que fica pendente.

| Melhoria | O que muda | Trava que ataca | Registro |
|----------|-----------|-----------------|----------|
| **A** | Merge de guarda em lote: «pode rodar lote» aprova várias mudanças de uma vez (PR, pedido de merge), só as que passaram nos testes automáticos (CI) e na revisão isolada, com registro por merge | 1 | [Merge de guarda em lote](../../knowledge-base/decisions/onion-adr-guard-merge-batch-2026-11.md) |
| **B** | Fila única de passo pesado na máquina, com teto de 2 ao mesmo tempo | 3 | [Fila única de passo pesado](../../knowledge-base/decisions/onion-adr-heavy-step-queue-2026-11.md) |
| **D** | Cada decisão do maestro declara o destino: mecanismo (com card da guarda) ou desenho (só texto) | a dívida de decisão sem guarda | [Destino declarado em cada decisão](../../knowledge-base/decisions/onion-adr-decision-destination-2026-11.md) |

As três estão **aceitas, com a implementação pendente**. A melhoria D foi a primeira a entrar em obra.

## O que fica sem melhoria nomeada

As travas 2, 4, 5 e 6 não ganharam uma melhoria nesta retro. Elas ficam registradas aqui para a
próxima.

---

Orquestrado com 🧅 Onion Evolve
