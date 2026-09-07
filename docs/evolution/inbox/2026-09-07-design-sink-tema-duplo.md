---
title: 'design-sink css-vars emite tema plano — falta a projeção claro/escuro sob nomes canônicos'
date: 2026-09-07
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core)
---

## Contexto

Rodamos a vertical de design inteira (`/design:generate` → gate → juiz → promoção) para escolher a
identidade do Portal MAAGICA. O brief exigia **dark mode desde o início**, então a SSOT ficou com dois
conjuntos de papéis: `color.<papel>` (claro) e `color.dark.<papel>` (escuro).

## O que encontramos

`tokens-to-css-vars.sh` resolve os aliases corretamente, mas emite **tudo plano num único `:root`**:

```css
:root {
  --color-surface-base: #faf8fd;
  --color-dark-surface-base: #1a1225;   /* nome separado, que ninguém consome */
}
```

Isso não é um tema utilizável. A UI precisa que `--color-surface-base` **mude de valor** conforme o
tema; um segundo nome não muda nada sozinho, e o componente teria de escolher a var na mão — que é
exatamente o acoplamento que os papéis semânticos existem para evitar.

Não é bug do script: ele faz o que documenta (achatar a SSOT em custom properties). É uma **lacuna de
provider** — e o README do `design-sink` já a declara ao marcar `tailwind` e `shadcn` como "output de
referência validado, adapter reutilizável 🔜".

## O que fizemos aqui

`ops/tokens-to-theme.sh` (projeto-local, porque este repo é `role: adopted` e não desenvolve o core).
Lê a mesma SSOT, resolve os aliases, e emite os papéis sob **nomes canônicos** três vezes — que são os
três estados que o viewer pode ter:

```css
:root { ... }                                                    /* claro (default) */
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { ... } }
:root[data-theme="dark"] { ... }
```

O terceiro é o que costuma faltar: o estado "sistema" **não estampa nada** no root, então só a media
query o separa — e sem o `:not([data-theme="light"])` a escolha explícita do usuário por claro perde
para o SO. Emite também aviso em STDERR quando um papel existe num tema e não no outro, que é o modo de
falha real: descobrir na tela que um papel herdou silenciosamente a cor do tema errado.

## Proposta

Um provider `theme` (ou uma flag `--modes` no `css-vars`) que reconheça um ramo de modo na SSOT — seja
por prefixo (`color.dark.*`) ou por diretório (`modes/dark/`) — e faça essa projeção. A convenção do
prefixo é a que usamos e funciona, mas quem decide a forma canônica é o core.

Vale junto a guarda de paridade: **papel sem contraparte no outro modo é aviso**, não silêncio. Foi o
que nos salvou de promover uma paleta cujo `info-strong` só existia no claro.

## Achado colateral, que talvez interesse mais que o adapter

O gate `lint-design-tokens.sh` só calcula os pares que a `governance/contrast-pairs.json` declara. Se a
governança declara só o tema claro, o gate **aprova em silêncio** uma paleta ilegível no escuro — e
"passou no gate" vira uma afirmação mais forte do que o gate mediu. Não é falha do script; é uma
armadilha de uso que talvez mereça um aviso quando a SSOT tem ramo de modo sem pares correspondentes.

Medimos o custo disso: as quatro candidatas tinham `brand.500` reprovando contra fundo escuro (1.71 a
2.60, alvo 3.0), e nenhuma teria sido barrada.
