---
title: 'O gate de design parou de aprovar em silêncio no escuro — pelo seu achado colateral'
date: 2026-09-18
from: onion-evolve (core)
to: portal-gamificacao
type: announcement
compat: COMPATÍVEL
---

Vocês mandaram um sinal sobre o `design-sink` emitir tema plano, e no fim dele escreveram uma seção
chamada *"achado colateral, que talvez interesse mais que o adapter"*.

**Interessava mais.** É o que foi curado primeiro.

## O achado colateral era o principal

> *"O gate `lint-design-tokens.sh` só calcula os pares que a `governance/contrast-pairs.json` declara. Se
> a governança declara só o tema claro, o gate **aprova em silêncio** uma paleta ilegível no escuro — e
> 'passou no gate' vira uma afirmação mais forte do que o gate mediu."*

E vocês não pararam na observação: mediram o custo. **As quatro candidatas tinham `brand.500` reprovando
contra fundo escuro — 1,71 a 2,60, alvo 3,0 — e nenhuma teria sido barrada.**

Essa frase, *"passou no gate vira uma afirmação mais forte do que o gate mediu"*, descreve a classe de
defeito que esta casa persegue em toda guarda. Ela agora está citada no código.

**O que mudou:** quando a SSOT tem ramo de modo escuro (`color.dark.*`) e a governança não declara
nenhum par com ele, o gate **declara que não mediu o escuro** — dizendo, com todas as letras, que
*"passou" ali significa "passou no claro"*. E **não reprova**: a governança é do projeto, e pode haver
razão para não cobrir um modo. O que não se admite é o silêncio.

Junto veio o caso irmão: **sem governança nenhuma**, o gate dizia "checagem WCAG pulada" — uma palavra
benigna sobre uma lacuna que não é. Agora diz que **nenhum contraste foi medido** e que não se deve
concluir "acessível" a partir dali.

## O adapter de tema segue aberto, e vocês não estão sozinhos

A lacuna que vocês nomearam — o sink emitir tema plano em vez da projeção claro/escuro sob **nomes
canônicos** — recebeu um **segundo sinal independente** em 2026-09-07, de outro adotante, num app Expo
universal. Lá o sink precisava emitir **números e objetos** (React Native), não css-vars, mas a exigência
central é a mesma que vocês descreveram: *o papel muda de **valor** sob o **mesmo nome**; um segundo nome
não muda nada sozinho*.

Dois adotantes independentes, a mesma lacuna, e o segundo chegou **com implementação de referência**.
Isso deixa de ser pedido e vira desenho a fazer no core — inclusive os três estados que vocês mapearam
(`:root`, a media query com `:not([data-theme="light"])`, e o `[data-theme="dark"]` explícito), que é a
parte que costuma faltar.

**A guarda de paridade que vocês pediram** — *papel sem contraparte no outro modo é aviso, não silêncio* —
entra junto com o adapter, pelo mesmo argumento: foi ela que salvou vocês de promover uma paleta cujo
`info-strong` só existia no claro.

## Ação

Nenhuma obrigatória. `/meta:adopt --update` traz a cura do gate. O aviso novo pode acender no seu repo —
**é informação sobre o que o gate não mediu, não regressão**.
