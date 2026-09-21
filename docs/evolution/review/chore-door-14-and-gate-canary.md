---
title: 'Resíduo — a 14ª porta é, de propósito, a cobaia que prova o gate no vivo'
date: 2026-09-21
branch: chore/door-14-and-gate-canary
reviewed_diff_sha256: 42293279de9b9eb5724ec7879b715dc2b9565192564773ca77810cc0f2dc408d
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Sem passada adversarial dedicada, e a razão é declarada: o diff é 100% projeção regenerada de
  produtor (pin, catraca, console, mapa, grafo) mais o resíduo. Não há desenho novo a refutar —
  o que existe a verificar é DETERMINÍSTICO e foi verificado: cada projeção saiu do gerador com
  rc=0, e o lint que as compara contra os produtores dá 0 HARD. Elenxo sobre projeção gerada
  seria cerimônia, e esta casa trata cerimônia como ruído que ensina a ignorar o gate.
---

# Duas coisas numa perna só

**A porta.** 14ª materialização, pin `7260feacbfe0`, de worktree **destacada em `origin/main`** —
nunca da branch, porque `git archive HEAD` daqui publicaria trabalho em voo num repo PÚBLICO
(armadilha que me pegou 3× nesta sessão). Push do maestro verificado no remoto (`36592d9ba145`,
14:46:00Z) **antes** de mover o pin: o pin só anda depois do push verificado, nunca depois do commit
local.

`onion-standalone` sobe 399 → 400 pelo critério de sempre — trabalho **mergeado** que a porta parada
não recebeu (os #856 e #857), não espera de push.

# Por que este PR é a cobaia

O #857 ligou o gate de achados, mas **não pôde prová-lo**: PR que edita o próprio `onion-review.yml`
faz a action se auto-pular, e foi o que aconteceu (`benigno=true`, medido no log). O verde de lá
provou a bancada, não a fiação.

Este PR **não toca o workflow**. Então o revisor roda de verdade, e o sinal a ler no resumo do job é:

| resumo diz | significa |
|---|---|
| `CONFIRMADA … (0 achados)` | fiação **viva**, contagem chegou |
| `apontou N violação(ões)` | fiação **viva**, e o gate bloqueou |
| `achados NÃO contabilizáveis` | **o gate nasceu inerte** — verde e mudo |

A leitura independente, depois do merge, é `bash ops/review-gate-health.sh`, que cruza o parecer
contra a conclusão do check em vez de confiar em qualquer um dos dois sozinho.
