---
title: 'Furo de doutrina (dogfood): linhagem de PRODUÇÃO de cliente-de-consultoria = merge consent-gated pelo cliente, não maestro-merge'
date: 2026-07-12
from: metagamify (rhilo-metagamify — consumidor, co-evolução ativa)
to: onion-evolve (core / maestro principal)
type: upstream-signal — furo descoberto em dogfood (prática→doutrina)
re: >
  veredito onion-adr-branch-roles-sdaal-2026-07 (2026-07-11) + Movimento 1 (PR #78 metagamify) + adopt/vendor
classe: SINAL (slice novo — o veredito de branch-roles NÃO fechou isto)
---

# 🛰️ Sinal upstream — o papel `production` de um adotante-CLIENTE tem autoridade de merge do CLIENTE, não do maestro

> Nasceu do dogfood do **Movimento 1** (vendorizar o framework na linhagem de produção `rhilo/main`).
> Executamos o veredito à risca: `/meta:adopt --update` do core → **PR #78** (framework-only, 432 arquivos,
> **zero** em `apps/`/`prisma/`/`libs/`/`src/`). Tudo correu certo. **Mas ao ver o PR pronto, o maestro
> travou o merge** — e ao travar, expôs um furo que nem o veredito de branch-roles nomeou.

## O furo

**RHILO é CLIENTE de consultoria** (metagamify é produto do Marcio). A `rhilo/main` é a **produção DELES**.
Mesmo o repo sendo do Marcio (`marciocar/metagamify`), o **código deployado que serve a RHILO é governado
pela ACEITAÇÃO da RHILO** — a palavra final do merge é **do cliente**, não do maestro do adotante.

O mecanismo (`adopt/vendor`) e o ADR de **branch-roles-sdaal** assumiram, implicitamente, que **quem adota
controla a linhagem de produção**. Para um adotante-cliente isso é falso: o vendor **propõe** (PR), a
**aceitação é um gate do cliente**. Hoje **só a prudência humana travou** — a doutrina, como está,
**permitiria** o maestro mergear na produção do cliente sem consentimento. Isso é um risco de "impor na
branch de quem tem a palavra final".

## Por que o veredito não fechou

O veredito de branch-roles definiu os papéis (`integration/staging/production/lineage:<cliente>/framework-lane`)
e a direção `produto→deploy`, mas **não atribuiu AUTORIDADE DE MERGE por papel/linhagem**. `production` de um
adotante que é dono ≠ `production` de um adotante-cliente. Falta o eixo "quem pode aceitar o merge".

## Proposta

1. **Novo atributo do papel SDAAL `production`: `merge_authority: self | client | core`.**
   Para `lineage:<cliente>` → `merge_authority: client`.
2. **`members.yaml` declara `merge_authority` por linhagem** (ao lado do pin). `client` = fora do controle
   do maestro do adotante e do core.
3. **`adopt/vendor` ganha um gate explícito:** quando a integration branch mira uma linhagem com
   `merge_authority ≠ self`, o fluxo **PARA no PR** e imprime "não mergear — autoridade é do <owner>"
   (o Procedimento de Commit Durável já não mergeia; falta **nomear** a proibição, não deixá-la à prudência).
4. **Relatório downstream do adopt** para lineage-de-cliente deve dizer, nos "próximos passos": *"abrir o PR
   e ENTREGAR ao cliente para revisão/aceite — o maestro NÃO mergeia"*.

## Perguntas ao core

- Isto entra como **atributo novo no ADR branch-roles-sdaal** (autoridade de merge por papel/linhagem) + gate
  no `adopt/vendor`? Ou já é coberto por algo (RFC-0005 escopo / RFC-0004 federação — não parece)?
- Como o **member-version awareness** lida com uma linhagem cujo pin só avança quando o **cliente** aceita
  (o pin de produção fica "proposto" até o merge do cliente — 5º membro da família *declarado ≠ verificado*)?

## Estado (nada imposto)

PR #78 **aberto e CONGELADO** aguardando autorização da RHILO. `rhilo/main` **intocada**. `chore/onion-framework`
é branch nossa (a proposta). Nenhum auto-merge, nenhum push na linhagem do cliente.
