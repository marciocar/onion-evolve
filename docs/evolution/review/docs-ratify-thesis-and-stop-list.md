---
branch: docs/ratify-thesis-and-stop-list
pr: 617
date: 2026-08-16
reviewed_diff_sha256: 547de4475fec474de6b9096247fe7a627fe79e53efd52d012a080e500277e05b
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 20
verdict: CONFORME-COM-RECOMENDACAO-REFUTADA
reviewer: passada de execução — cada item do "parar de fazer" foi medido no PROPÓSITO do próprio código antes de qualquer remoção; 3 dos 5 caíram
REVISOU: true
---

# Resíduo — `docs/ratify-thesis-and-stop-list`

O PR faz duas coisas de natureza diferente e a revisão precisa separá-las: **ratifica** uma
tese (ato do maestro, não meu) e **executa** uma lista de remoções (ato meu, reversível
apenas enquanto não removi nada). Foi na segunda que a passada rendeu.

## Os 3 achados — todos contra a própria recomendação que eu ia executar

1. **Empacotamento — a recomendação caiu.** `claude plugin` tem `init` (scaffold de plugin
   NOVO), `validate` (schema), `tag` (confere plugin.json × marketplace) e `marketplace
   add/update` (distribuição). **Nenhum faz projeção.** Nossos scripts projetam a SSOT
   `.claude/` em layout de plugin e agregam o registro — e o `generate-marketplace.sh`
   nasceu de defeito de campo MEDIDO (adotante 2026-07-13 escrevendo `marketplace.json` à
   mão porque o lint dele cobrava um arquivo sem gerador). Pior para a recomendação:
   delegar a validação ao binário **acoplaria a metade que hoje reprova** — o fosso
   agnóstico que esta mesma rodada mediu.
2. **`MEMORY.md` — a recomendação caiu.** O nativo **mantém** o arquivo; o `evolve` D10
   **testa se o conteúdo ainda é verdade**, com veredito `UNVERIFIABLE` explícito quando
   não pode medir. São atos diferentes, e o segundo é a camada de aprendizagem
   autorregulada — justamente o que a doutrina Elenxo exige.
3. **Scaffolding — a recomendação caiu.** Os `setup-*` são específicos (integração de task
   manager, code review no CI), não o `/init` genérico.

## O que sobreviveu e foi executado

Os dois itens que eram **verdade a corrigir**, e ambos tocam declarações que a medição
derrubou: a KB canônica parou de anunciar leitura-como-mecanismo (com a correção **visível**
no texto, não apagada), e o `CLAUDE.md` trocou a justificativa do acoplamento por aquela que
a medição prova comprada.

## Nota de método (o que vale levar)

A lista veio de um revisor que mediu a **capacidade da plataforma**; ao medir o **propósito
do nosso código**, três quintos dela evaporaram. Recomendação derivada do que o outro faz é
**hipótese**; vira decisão só depois de medir o que o próprio código existe para fazer.
Registrado como classe no grafo — vale para toda futura leitura de changelog alheio.

Limite declarado: não removi nada nesta rodada, então não há regressão a medir; o risco que
sobra é o inverso (manter mecânica duplicada), e ele fica endereçado pelos gatilhos dos nós
`Q_RISCO_*`.
