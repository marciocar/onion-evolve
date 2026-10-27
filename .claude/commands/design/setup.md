---
name: setup
description: |
  A entrada do ciclo de design: parte do docs/design-context/brief.md que já existe
  (ou cria o stub mínimo, com confirmação), faz três perguntas (a cor da marca, o
  público e o tom lidos do business-context, o alvo de tema detectado), mostra o
  plano em dry-run, grava sem nunca sobrescrever (idempotente) os tokens W3C DTCG e
  o grafo do design-context ligado ao business-context e ao technical-context, e
  termina no gate de tokens. Tudo local, sem serviço externo.
allowed-tools: AskUserQuestion Read Glob Grep Skill Bash(bash .claude/utils/design-setup/*) Bash(bash .claude/utils/scope/*) Bash(bash .claude/validation/lint-design-tokens.sh*) Bash(bash .claude/validation/design-context-check.sh*) Bash(bash .claude/validation/kg-radar.sh*) Bash(bash .claude/validation/kg-contract-check.sh*) Bash(git rev-parse*)
category: design
tags: [design, setup, tokens, wcag, kg, context]
version: "0.1.0"
updated: "2026-10-27"
related_agents:
  - design-system-specialist
  - branding-positioning-specialist
related_commands:
  - /design:identity
  - /design:generate
  - /meta:context-freshness
---

# /design:setup — a entrada do ciclo de design

## Objetivo

Levar um projeto do brief que ele já tem a um design-context **mínimo e verificável**: tokens W3C DTCG que
passam no gate, e o **grafo do design-context** ligado aos outros contextos. É o molde do `onion-wizard`
(Orient → perguntas críticas → dry-run → executar) e do `/meta:adopt` (never-clobber, retomável): você é o
intake guiado; o motor determinístico `.claude/utils/design-setup/design-setup.sh` é quem planeja e grava.

> **Princípio reitor.** A IA não inventa cor, público nem tom. O contraste é **calculado** pelo motor e
> **re-medido** pelo gate (`lint-design-tokens.sh`); a ligação entre contextos é **conferida** pelo gate do
> contrato KG-SSOT e pelo `design-context-check.sh`.

## Fronteiras

- **NÃO** decide posicionamento nem estratégia de marca → `/product:branding` antes.
- **NÃO** gera N identidades → `/design:generate`. **NÃO** materializa tema e componentes → `/design:identity`.
- **NÃO** usa serviço externo: tokens em arquivo, gate local, nenhuma rede (o Gamma não entra no ciclo).
- **NÃO** afirma uma 4ª dimensão: o design-context é contexto; a doutrina espera o gatilho medido.

## Fluxo

### 0. Orient (sem perguntar ainda)

1. Carregue a skill `onion-design-context` (onde o contexto mora e como o grafo se liga).
2. Resolva as pastas: `bash .claude/utils/scope/resolve-context-dir.sh design` (e `business`, `technical`).
   Exit 3 = declaração inválida: **pare** e diga qual.
3. Rode o plano sem argumentos: `bash .claude/utils/design-setup/design-setup.sh`. Ele diz o que existe
   (`MANTER`), o que falta (`PRECISA`), o alvo de tema detectado (`TEMA`) e as ligações possíveis (`LIGACAO`).

### 1. O brief é a entrada

- **Existe** `docs/design-context/brief.md` (ou o brief na pasta resolvida): leia-o inteiro. Ele é a
  entrada; a prosa **não é tocada**. Se não tem frontmatter, o plano diz `SUGERIR`: ofereça acrescentar
  `projection_of` e `review_after` (`--add-frontmatter`), só com confirmação.
- **Não existe**: ofereça o stub mínimo da skill (`--create-brief`). Sem confirmação, pare declarando
  "sem brief, o setup não começa" — nunca escreva um brief inventado.

### 2. As três perguntas (AskUserQuestion, só as críticas)

1. **A cor ou marca principal** — só se os tokens não existem (`--brand '#RRGGBB'`). Com tokens, a marca
   vem do alias de `color.action.primary`; confirme, não pergunte.
2. **O público e o tom** — **lidos** do business-context (resolva com a skill `onion-product-context`;
   leia o posicionamento e as personas). Mostre o que leu e peça confirmação. Sem business-context:
   pergunte, ofereça o stub do `onion-product-context` com confirmação, e se recusado o grafo nasce com a
   `question` aberta que declara a falta. Nunca invente dado de mercado. (Usados no stub: `--audience`, `--tone`.)
3. **O alvo de tema** — o detectado (`shadcn` por `components.json`, `tailwind` por `@theme` ou
   `tailwind.config.*`, `css-vars` por CSS ou `package.json`, `none`). Confirme ou corrija (`--theme-target`).

### 3. Dry-run (o gate humano)

Rode o motor com as respostas e **sem** `--apply`. Mostre o plano inteiro, inclusive a linha `CONTRASTE`:
o texto do CTA tem de chegar a **4,5:1** contra branco ou quase preto; se nenhum chega, o motor propõe o
tom mais escuro da marca para `color.action.primary` e deixa a cor original como acento. **Nada se grava
antes da confirmação explícita.**

### 4. Executar e terminar no gate

Com a confirmação, repita o mesmo comando com `--apply`. O motor:
- cria **só o que falta** (abre com `x`: arquivo que apareceu no meio não é sobrescrito);
- grava o grafo com as `external_edges` quando o nó-alvo existe (`E_POSITIONING` e `E_AUDIENCE` no
  business-context, `ST_THEME_APPLIED` no technical-context), e com a `question` aberta quando não existe;
- **termina no gate**: `lint-design-tokens.sh` (rc do setup) e, como aviso, `design-context-check.sh`.

Depois rode `bash .claude/validation/kg-radar.sh docs/design-context/design-context.kg.yaml --integrity --schema`
(exit 0) e, onde o contrato está vendorizado, `bash .claude/validation/kg-contract-check.sh` no grafo.
**Commite o grafo-alvo antes do grafo do design**: o gate do contrato só enxerga grafo rastreado, e o alvo
fora do git reprova até o caso íntegro.

**Reexecutar** não grava nada: o plano só tem `MANTER` (e as linhas informativas `TEMA`, `LIGACAO`, e
`AVISO` se vier uma `--brand` diferente da dos tokens) e termina em `NADA`. O setup é idempotente.

**Tokens parciais** (só foundations ou só semantic): o plano diz `FALTA` e sai 3 — o setup não inventa a
outra metade. **Pasta de design declarada** fora de `docs/design-context`: o motor grava, mas o gate de
tokens só lê `docs/design-context`, e o setup sai 2 ("gravado, não verificado") em vez de declarar verde.

## Saídas e rc

`design-setup.sh` sai 0 (plano pronto, ou aplicado com o gate verde) · 1 (aplicado e o gate reprovou) ·
2 (uso, entrada quebrada, não pude julgar) · 3 (falta confirmação ou dado: brief sem `--create-brief`,
tokens sem `--brand`). Próximo passo: `/design:identity` (materializar o tema) — onda 2.

## Referências

- Skill: `onion-design-context` · motor: `.claude/utils/design-setup/` · gate: `lint-design-tokens.sh`
- Guarda do grafo: `.claude/validation/design-context-check.sh` (locator de token e ligação do brief)
- Piloto: o grafo do próprio core em `docs/design-context/design-context.kg.yaml`
