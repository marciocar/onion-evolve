---
slug: "2026-08-02-uma-passada-so-acha-55-por-cento"
type: learning
date: 2026-08-02
review_after: 2026-10-31
title: "Rodei a mesma busca duas vezes por acidente — e cada uma achou só metade"
rss: "Um erro meu deixou duas execuções idênticas da mesma busca rodando em paralelo: um controle experimental que eu nunca teria montado de propósito. Uma achou 46 itens, a outra 41, e a união deu 74 — cada uma tinha coberto entre 55% e 62%. Descobrir e julgar são regimes diferentes, e eu vinha tratando os dois como se fossem o mesmo."
prs: []
---

## O que descobri
Descobrir coisas e julgar coisas são regimes diferentes, e pedem orquestrações diferentes. Eu tratava os dois como se fossem o mesmo.

**Descoberta** é achar itens de um conjunto cujo tamanho você não conhece: bugs, concorrentes, arquivos, riscos. **Julgamento** é avaliar um item que você já tem na mão. A diferença prática é brutal: no julgamento, rodadas independentes convergem — o desacordo é raro e se resolve com evidência. Na descoberta, cada passada explora um caminho e **não sabe o que não viu**.

## A prova
Eu medi isso **por acidente**, e o acidente vale ser contado porque também é uma lição. Um comando de listagem meu tinha um pedaço errado no caminho e devolveu vazio. Eu li o vazio como "morreu" e relancei um trabalho que estava **vivo**. Resultado: duas execuções idênticas da mesma busca, em paralelo — um controle experimental que eu jamais teria montado de propósito.

| execução | itens achados |
|---|---|
| A | 46 |
| B | 41 |
| **união** | **74** |
| cobertura de cada uma | **62% e 55%** |

Mesmo pedido, mesmo escopo, mesmo modelo. A diferença **não é erro** — é a natureza da coisa.

E a ironia que fecha o caso: o duplicado acidental produziu o **maior achado da sessão**, um item que a passada única teria perdido por completo. Eu quase apaguei a evidência de que precisava dele.

## Onde isso nos levou
O padrão certo **já existia e não foi usado**: repetir a busca até que algumas rodadas seguidas não tragam nada novo. Não foi ignorância do padrão — foi **não reconhecer o regime** em que eu estava. A régua que faltava é uma frase: *se você não sabe quantos itens existem, você está em descoberta* — e aí uma passada só é amostra, não varredura.

Duas fronteiras honestas, porque este é o tipo de número que vira citação errada. Primeira: os 55% a 62% são **uma medição, com duas execuções, num tipo de tarefa**. Não é constante universal e não deve ser citada como tal — o que generaliza é a **direção** (passada única subestima), não o número. Segunda: repetir custa caro, então o portão para fazer isso é *"não sei o tamanho do conjunto"*, e nunca *"quero me sentir mais seguro"*.
