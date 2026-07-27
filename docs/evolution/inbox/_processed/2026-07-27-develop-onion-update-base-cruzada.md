---
tipo: sinal-upstream
origem: rhilo-metagamify (adotante)
destino: onion-evolve (core)
data: 2026-07-27
assunto: "Update do Onion na 2ª integration branch (develop) dá conflito contábil — onion/vendor segue a linhagem da chore, não da develop. Pedido de ajuda p/ a base correta."
fluxo: feedback + pedido (adotante → core)
prioridade: media
relacionado:
  - docs/evolution/inbound/2026-07-21-pin-guard-vendor-verificado.md
  - docs/evolution/inbound/2026-07-24-vendor-vnextpin-invalido.md
  - docs/evolution/inbound/2026-07-25-update-pin-21213cc.md
---

# 🧭 Pedido — como atualizar o Onion numa SEGUNDA integration branch (develop) sem conflito contábil

> **Contexto de confiança:** o update em `chore/onion-framework` (pin 9547ca7 → **21213cc**, 25/07) foi
> **limpo** (merge do `onion/vendor`, 0 conflitos). O problema abaixo é **só** ao tentar levar o mesmo
> framework para a `develop`. Nada quebrou — abortei e restaurei a develop intacta.

## 1. O que aconteceu

Este repo tem **duas integration branches adotadas** (histórico da higienização multibranch):
- `chore/onion-framework` — `integration_branch: chore/onion-framework`, pin **21213cc** (atualizado).
- `develop` — `integration_branch: develop`, pin **4fdfee9** (adoção original de 30/06, **nunca** atualizada).
  É a **base oficial dos PRs Onion** (CLAUDE.md), então é onde o framework novo deveria estar.

Rodei o fluxo canônico mirando a develop:
```
vendor-branch.sh update <wt-develop> <core> <NOW> develop
```
→ **exit 10 (conflito)** com **~110 arquivos**, incluindo **código de aplicação** que não é framework:
`apps/api/src/services/wrr-distribution.service.ts`, `apps/api/src/scripts/dose-sim-harness.ts`,
`docs/wrr/2026-07-09-mapa-consolidacao.md`, além dos `.claude/**` e `docs/knowledge-base/**`.

`git merge --abort` + `reset --hard` → develop de volta ao original (pin 4fdfee9, árvore limpa). Zero dano.

## 2. Diagnóstico (por que é conflito contábil, não real)

É exatamente o padrão que os avisos `pin-guard-vendor-verificado` (17 arquivos byte-idênticos num
adotante-irmão) e `vendor-vnextpin-invalido` descreveram — **base de merge errada** —, só que a causa aqui
é estrutural e nova:

- O `onion/vendor` deste repo foi **semeado/avançado pela linhagem da `chore/onion-framework`** (é
  ancestral dela). Seu topo é o framework 21213cc aplicado sobre a história da chore.
- A `develop` divergiu **muito** da chore (`develop` +210 / `chore` +40 commits) e foi adotada por um
  caminho próprio.
- Mergear `onion/vendor` (linhagem-chore) na `develop` → o 3-way usa um ancestral comum **distante**, e lê
  a divergência natural das duas branches (inclusive código WRR) como **conflito**. Não é conteúdo de
  framework brigando; é ancestralidade.

**Contorno que usamos (funciona, mas é contorno):** overlay do framework **por arquivo** (copiar só os
paths do manifesto de `chore` para uma worktree sobre `rhilo/main`), sem merge de história → branch
`work/onion-fresh` com Onion 21213cc + código de produção, `apps/` intacto. Bom para um workspace; **não**
resolve a develop como integration branch de verdade.

## 3. O pedido

O core se ofereceu (em `vendor-vnextpin-invalido`) a cruzar timestamps e devolver o SHA/base correto.
Aqui o pedido é mais estrutural:

1. **Como o `--update` deve tratar um adotante com MAIS DE UMA integration branch** (`develop` **e**
   `chore/onion-framework`) cujas linhagens de framework divergiram? O `onion/vendor` é único por repo —
   ele consegue servir de base para as duas? Ou cada integration branch precisa da sua própria
   fonte-de-merge?
2. **Qual a receita segura para trazer 4fdfee9 → 21213cc na `develop`** sem arrastar os 33 commits WRR da
   chore nem gerar o conflito contábil? (Candidatos que enxergamos: re-semear um `onion/vendor` a partir da
   base da *develop*; ou um vendor por-branch; ou um caminho de "adoção paralela" documentado.)
3. **Efeito colateral a confirmar:** o `update` abortado **avançou** o `onion/vendor` para `f626989e`
   (pin f6bb7c7, HEAD do core no momento). Isso é benigno (forward válido) ou devemos re-carimbar/reverter
   antes do próximo update da chore?

## 4. Valor pro core (dogfood)

É a primeira vez que a capacidade de `--update` encontra um adotante com **duas integration branches
vivas e divergentes** — um caso que o design de vendor-branch (um vendor por repo) não cobre explicitamente.
Vale virar ADR/guia: *"adoção com múltiplas integration branches"* ou, no mínimo, um guard que **detecta a
base cruzada e recusa o merge** (em vez de despejar 110 conflitos contábeis no maestro).

— rhilo-metagamify (adotante), 2026-07-27
