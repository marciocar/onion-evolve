---
branch: docs/dogfood-read-leg-trigger
pr: 618
date: 2026-08-16
reviewed_diff_sha256: 4bfb571dd00db3f778f5379474409c89540dd36ccbbbf258cce09541c4b6d6a5
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 25
verdict: CONFORME-COM-GATE-MANTIDO-FECHADO
reviewer: o próprio experimento é a passada — A/B cego contra a hipótese que eu queria confirmar; e o radar reprovou o PR no caminho (nó órfão)
REVISOU: true
---

# Resíduo — `docs/dogfood-read-leg-trigger`

Este PR **não implementa** nada: ele executa o teste que decidiria se vale implementar, e
registra que **não vale**. O que há para revisar é o desenho do experimento, porque um
dogfood mal desenhado é pior que nenhum — ele autoriza construir.

## Achado 1 — o experimento refutou a hipótese que eu queria confirmar

A/B cego (mesma pergunta, sessão headless nova, com e sem o hook descartável injetando o
veredito do radar): **3 de 3, o veredito injetado não mudou a resposta**. Em 3 de 3 a
sessão-controle consultou o grafo por conta própria, e no caso cujo fato existe **só** no
grafo ela citou o nó com arquivo:linha.

Duas salvaguardas de honestidade no desenho, que é o que torna o resultado utilizável:
- **A/B**, não impressão. Sem o controle, eu leria "a resposta com hook citou ids, logo
  ajudou" — e teria construído.
- O caso 3 foi escolhido **contra mim**: um fato que só existe no grafo, exatamente para dar
  ao hook a melhor chance. Ele empatou mesmo assim.

## Achado 2 — o limite do desenho, encontrado depois de rodar (e declarado, não escondido)

Testei *"acha quando perguntado de forma dirigida"*. O modo de falha medido no corpus de
2026-08-02 é outro: *"consulta enquanto está ocupado com outra tarefa"*. Uma pergunta de
decisão **convida** a consulta; uma tarefa em andamento **compete** com ela. Logo, o
resultado é evidência válida contra a injeção ajudar em pergunta de decisão, e **não é** o
teste do defeito real. O desenho seguinte ficou nomeado no nó e no diário: tarefa cujo
caminho óbvio contradiz um nó, medindo se a injeção muda a **ação**.

Não corrigi o desenho nesta rodada de propósito: refazer o experimento até ele autorizar o
que eu queria construir seria p-hacking com passos extras.

## Nota

O radar reprovou este PR no caminho — **nó órfão (grau 0)**, porque adicionei a evidência e
esqueci a aresta. Guarda funcionando dentro do PR que fala sobre guardas funcionarem. A
correção foi mecânica (duas arestas) e o radar voltou a exit 0 com 24 nós e 29 arestas.
