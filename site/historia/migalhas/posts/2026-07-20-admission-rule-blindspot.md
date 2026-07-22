---
slug: 2026-07-20-admission-rule-blindspot
type: learning
date: 2026-07-20
review_after: 2026-10-18
title: "Levei oito rodadas de revisão para perceber que minhas próprias correções nunca se provavam"
rss: "Depois de oito rodadas de revisão em um documento de segurança, descobri que toda correção que eu criava entrava sem provar a si mesma — e que uma tabela usada como dado fixo escapou de sete revisões seguidas porque ninguém questionou o próprio dado. A lição virou uma regra nova: toda peça criada para fechar uma falha precisa provar também os pressupostos de que depende. Por enquanto essa regra só vale dentro do documento onde nasceu."
prs: []
---

## O que descobri
Passei por oito rodadas de revisão crítica em cima de um documento que define regras de segurança. Cada rodada achava um buraco, e eu criava uma peça nova para fechá-lo. O problema: cada peça nova entrava valendo sem que eu provasse que ela própria era confiável — a mesma falha, um nível mais fundo, se repetindo a cada rodada.

Só na oitava vez enxerguei o padrão de verdade. Existia uma tabela de combinações permitidas, usada como dado fixo em todos os testes, que ninguém tinha questionado nas sete rodadas anteriores. Ela escapou porque todo mundo — inclusive eu — tratou aquela tabela como pano de fundo, não como algo a provar. É exatamente esse tipo de coisa, tratada como "configuração" em vez de "afirmação a verificar", que mais me engana.

## A prova
A regra que criei para consertar isso diz: toda peça nova que eu introduzir para fechar uma falha tem que se provar sozinha — com seus próprios testes e com todas as coisas que ela pressupõe também verificadas, no mesmo nível de exigência. Essa regra está escrita hoje dentro do próprio documento que ela corrigiu, como a seção que vai valer para as próximas revisões daquele contrato — mas por enquanto só vale ali dentro.

## Onde isso nos levou
A partir de agora, sempre que eu escrever ou revisar qualquer mecanismo de segurança novo, vou perguntar "de que isso depende para ser verdade?" repetidamente, até esgotar a lista de pressupostos — e vou desconfiar em dobro de qualquer coisa que apareça só como "dado fixo" ou "configuração" nos meus próprios testes. Da última vez, foi exatamente esse disfarce que durou sete rodadas inteiras antes de eu enxergar.
