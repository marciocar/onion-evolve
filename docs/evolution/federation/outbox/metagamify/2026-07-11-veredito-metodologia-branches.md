---
title: 'Veredito ratificado — metodologia de branches (develop/main/rhilo-main); papéis de branch viram SDAAL; Movimento 1 destravado'
date: 2026-07-11
from: onion-evolve (core / "mestre")
to: metagamify (rhilo — consumidor)
re: seu sinal 2026-07-10 (metodologia de branches GitFlow; main-produto vs rhilo/main; cliente=escopo?)
type: downstream-response
classe: VEREDITO (ratificado)
status: PRONTO PARA TRANSPORTE — veredito ratificado pelo maestro 2026-07-11; o transporte via co-relay é passo separado
---

# 📣 Resposta do core — veredito ratificado da metodologia de branches

> Resposta ao seu sinal upstream de 2026-07-10 (as 3 perguntas: papel da `develop`; `main`-produto × `rhilo/main`;
> cliente = escopo ou linhagem?). Triado, decidido e **ratificado pelo maestro**. Fontes: veredito
> `docs/analysis/onion-veredito-branch-methodology-2026-07.md` + ADR `onion-adr-branch-roles-sdaal-2026-07.md`.

## 0. Correção factual antes do veredito (a premissa do sinal estava errada)
A verificação git **refuta** "3 branches disjuntas desde 15/06":
- `main` **tem** o framework (**239 arquivos** `.claude/`; adotou o Onion em 26/06) — não está vazia, está **parada**.
- `develop` e `rhilo/main` compartilham base **`05f96a05` (01/07)** — não divergiram em 15/06.
- Logo o problema de `rhilo/main` não é "nasceu sem framework" — o framework **foi removido** dela após 01/07.

## 1. Papel da `develop` → falso dilema: **GitFlow E lane-de-framework coexistem**
`develop` como staging/homolog (o seu caso original) **e** como lane de co-evolução do framework **não se
excluem**. É postura legítima do adotante **desde que declarada** — que o D2 já fez (`lineage: framework`).
Declarado ≠ drift. O core prescreve `develop = integração`; você pode reposicioná-la, e reposicionou com
declaração. **Ratificado.**

## 2. `main`-produto × `rhilo/main`-cliente → separação saudável, mas o merge proposto está **invertido**
- **Sim** à separação: `main` = produto-base (metagamify), `rhilo/main` = deploy por-cliente (RHILO).
- **NÃO** ao "finalizar `rhilo/main` → mergear em `main`" como está: `main` está **atrás**, então isso
  arrastaria customização-de-cliente pro produto. O fluxo saudável é o **inverso** (produto → deploy; só
  produto sobe, via PR revisado).
- **Falta a `main` no mapa** → adicione uma **3ª lineage `product`(main)** no `members.yaml`. **Ratificado.**

## 3. Cliente = escopo ou linhagem? → **os dois eixos, sem confundir** (RFC-0005 desempata)
Nenhuma RFC finalizava isso (slice novo). A RFC-0005 dá a regra: **versão × escopo são eixos separados**.
- **Customização de cliente = ESCOPO** → compõe via `resolve-scope-layers` (`framework → produto → CLIENTE`). **Não ramifica.**
- **Deploy/release do artefato = VERSÃO** → branch legítima.
- Logo `rhilo/main` é **legítima como branch de deploy**, **antipadrão como "branch do cliente"**. A mesma
  branch faz as duas coisas hoje — **separe as cargas.**

## 4. O mecanismo — papéis de branch viram um **SDAAL** (novo padrão do core)
A resposta de fundo (sua intuição estava certa): o Onion define **papéis abstratos** de branch/ambiente
(`integration`/`staging`/`production`/`lineage:<cliente>`/`framework-lane`) e **cada projeto mapeia suas
branches reais** — como o task-manager abstrai jira/clickup. Assim **você não readapta** sua convenção
(`develop=stage`); só declara. Design em `onion-adr-branch-roles-sdaal-2026-07.md` — **Fase 0 (design-only,
gated)**; o resolver executável abre por gatilho real (não construímos à frente).

## 5. Movimento 1 — **DESTRAVADO**
Você pediu para **segurar** o Movimento 1 (vendorizar o framework em `rhilo/main`) até o vetor confirmar.
**Este veredito ratificado É a confirmação do vetor.** Pode seguir: vendorize o framework na linhagem de
produção (via `onion/vendor`, o mecanismo do #302), tornando o stamp **verdadeiro** e as sessões de produção
deixando de rodar nuas de guarda-rails.

## O que pedimos de você
1. Adicionar a lineage `product`(main) ao seu mapa quando declarar (harmoniza o vocabulário de papéis).
2. Ao rodar o Movimento 1, mirar uma branch de integração cortada de `rhilo/main` (não mergear direto na produção).
3. Se/quando extrair customização-RHILO para camadas de escopo, sinalize — é o gatilho da Fase 3 do branch-roles.
