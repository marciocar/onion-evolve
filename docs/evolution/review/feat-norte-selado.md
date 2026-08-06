---
branch: feat/norte-selado
date: 2026-08-06
reviewed_diff_sha256: 8f81df4430a8c6d65aa23d0ba489c53ab360918f0d72e86b9ad17352c1b3f68b
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 446255
duration_min: 16
verdict: ELENXO-MUDOU-A-ORDEM
reviewer: Elenxo — 4 refutadores adversariais + juiz (opus/high), wf_48698acf-543
---

# Passada adversarial — as decisões de norte sob ataque

**A revisão foi o Elenxo, não um code-review**: quatro refutadores atacaram as três decisões
recém-tomadas, com a regra mecanizada *refutação sem `superacao` é DESCARTADA*.

**Zero descartadas por falta de superação.** As três decisões sobrevivem **RESTRINGIDAS**; nenhuma cai.

## Os ataques, e o que aconteceu com cada um

| ataque | veredito |
|---|---|
| **R1** — "só quem autora o grafo o consome" | **MORREU na medição.** O consumidor certo é a SESSÃO, não o corpo do PR: **1.022 execuções** do radar em 39/53 sessões · **61 de 132** pares (sessão×grafo) são leitura-sem-autoria · **54 de 55** citam id daquele grafo no texto do agente. O refutador ainda **corrigiu o próprio instrumento** (1ª rodada deu 0/55 por bug de resolução de caminho). |
| **R2** — orquestração é cara e não-medida | **SOBREVIVE restringindo:** o valor passa a ler-se "orquestração ancorada, COM régua de custo". |
| **R3** — ICP primário aspiracional | **REFUTADO por medição** (86 sinais em `inbox/_processed`). |
| **R4** — "ancorada" é retórica (79%) | **O NÚMERO ERA MEU E ESTAVA ERRADO:** 43% run-level, **76% na janela recente**. O denominador incluía runs operacionais que a doutrina nunca obrigou a virar grafo. |

## O que mudou de verdade

**A Fase 3 deixou de ser um passo e virou três, em ordem obrigatória** — e a ordem não é estética:
construir o selo antes do schema produz **um gate que só passa mentindo**. Verificado em sandbox,
com o status como única variável.

**E o que a Fase 3 cura mudou:** não é *"as orquestrações não ancoram"* (falso, 76%), é
**"o grafo não sabe dizer que envelheceu"**. Cura diferente, e mais barata.

**Entrou um item que não estava no plano** e governa o preço de tudo depois: a régua de W +
`tool_uses` no contrato do M6. Sem ela, todo Elenxo futuro sai com W=N por default.

**Desceu na fila** o lado paralelo do M8 (projeção ≥1,4M): a pergunta dele tem resposta mais barata em disco.

## O que este PR entrega

Fase 1 (as três decisões seladas, com a contradição medida registrada junto) e **Fase 3a**
(os dois status legais) — o pré-requisito sem o qual o resto seria fail-open.
