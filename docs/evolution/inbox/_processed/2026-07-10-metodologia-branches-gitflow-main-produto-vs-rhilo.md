---
title: 'Metodologia de branches: GitFlow? papel real da develop, e main-como-produto-principal vs rhilo/main-como-produção-RHILO'
date: 2026-07-10
from: metagamify (rhilo-metagamify — consumidor, co-evolução ativa)
to: onion-evolve (core / maestro principal)
type: upstream-signal — pergunta de convenção / pedido-de-veredito
re: >
  parecer onion-parecer-rhilo-lineages-2026-07 (Mov.1 ainda pendente) +
  RFC-0004 (federação) + RFC-0005 (branch=versão, não escopo)
classe: PERGUNTA (não bloqueante — decisão do maestro)
---

# 🛰️ Sinal upstream — qual a metodologia de branches desta instância? (e onde o produto-base termina e a instância-RHILO começa)

> Contexto: hoje (2026-07-10) finalizamos o **deploy do metagamify em `rhilo/main`** (PR #77, `f7e4b034`)
> e a **higienização das branches locais** (20 apagadas, 3 arquivadas no origin). Ao arrumar a casa, a
> topologia de 3 branches divergidas expôs uma dúvida de **método**, não de git. Seguindo o parecer de
> 03/07: **Mov.2 (linhagens declaradas)** e **Mov.3 (KG dogfood)** = ✅ feitos; **Mov.1 (framework na
> linhagem de produção `rhilo/main`)** = ❌ ainda pendente (`rhilo/main` tem 1 arquivo em `.claude/` vs
> 355 na `develop` — as sessões que trabalham/deployam rodam nuas de guard-rails).

## Relação que enquadra tudo (contexto novo, 2026-07-10)

- **metagamify** e **onion-evolve** são **criações do Marcio Carvalho** (o produto e o framework).
- **RHILO é um CLIENTE de consultoria** do Marcio em **Gamificação** — não é um fork da comunidade.
- Logo `rhilo/main` **não é** "outro projeto": é a **linhagem de deploy do produto do Marcio (metagamify)
  para um cliente específico (RHILO)** — o padrão clássico de **produto de consultoria com deploy
  por-cliente**. Isso reposiciona a pergunta: não é "reconciliar dois projetos", é **"como o Onion
  prescreve versionar um produto-base (`main`) + N deployments por-cliente (`rhilo/main`, …)"**.

## O fato que provoca o sinal

As três branches do metagamify divergiram da base `c5036dfa` (15/06) e **nunca se reencontraram**:

| branch | função REAL hoje | tem framework/KG? | tem o motor deployado? | deployado? |
|---|---|---|---|---|
| `main` | toco da adoção Onion (26/06), parado | ❌ | ❌ | ❌ |
| `develop` | **SSOT de docs/framework/KG** (158 commits) | ✅ | ❌ | ❌ |
| `rhilo/main` | **produção de fato** (33 commits, PR#77) | ❌ (só stamp) | ✅ | ✅ |

## Pergunta 1 — GitFlow ou outro modelo? Qual o papel canônico da `develop`?

A `develop` desta instância **não** se comporta como a *integration branch* clássica do GitFlow
(`feature → develop → release → main`). Ela virou a **lane de conhecimento/framework** (todo o `.claude/`,
os docs, o KG SDAAL, a co-evolução). Isso é **intencional** (develop = lane de framework, um eixo próprio)
ou é **drift** de um GitFlow que deveria ter `main` como produção e `develop` como integração de features?
**Qual o papel que o Onion prescreve para a `develop` num consumidor adotado?**

## Pergunta 2 — `main` = produto-principal, `rhilo/main` = instância-RHILO (e merge de volta enquanto andam juntas)

Leitura do maestro: **o metagamify é o PRODUTO PRINCIPAL**, e a **fila/queue focada na RHILO** acabou se
**confundindo** com o produto-base. É saudável **separar** os dois. Por ora usamos `rhilo/main` como
produção *na RHILO*, mas **a `main` deveria ser normalmente a branch principal do metagamify** (o produto).

Proposta operacional **enquanto as duas andarem juntas**: depois de atualizar e **finalizar o deploy em
`rhilo/main`**, **mergear também na `main`** — mantendo a `main` como principal; quando divergirem de vez
(features só-RHILO vs produto-base), a separação fica declarada. Assim a **branch principal volta a ser a
`main`**.

**O core concorda com essa separação `main`(produto-base) × `rhilo/main`(instância-RHILO)?** Como ela
**convive com o modelo de 2 linhagens do parecer** — que posicionou `develop`(integração) × `rhilo/main`
(produção), mas **não posicionou a `main`-produto** nesse mapa? Onde a `main` entra nas `lineages:` do
`members.yaml`?

## Pergunta 3 — foi ACEITA **e IMPLEMENTADA** na RFC-0004 / RFC-0005? E o que elas dizem do caso "cliente"?

Verificamos (não herdado): ambas *accepted* 09/07 **e implementadas** — 0004 tem `a2a-live F2.2 COMPLETO`
(CHANGELOG 10/07, scripts `a2a-verify/accept/send-signal`, handshakes vivo+regulado); 0005 tem
`compose-settings.sh` + `resolve-scope-layers.sh` **entregues 10/07** (alguns modos "desenhado/gated").
Mas **nenhuma finaliza ESTA questão**:
- **RFC-0004** — trata de **federação inter-instâncias** (single-source + mesh + a2a), não do arranjo
  interno `main`/`develop`/`rhilo/main` de um membro.
- **RFC-0005** — herança de escopo (`framework → empresa → time → pessoa`), headline **"branch-para-escopo
  é rejeitado; branch permanece no eixo versão"**. Com o contexto novo isto vira **o cerne**: um **cliente
  de consultoria (RHILO)** é naturalmente **mais uma camada de escopo** (`framework → produto → CLIENTE`).
  Se a 0005 diz que **escopo não deve ser branch** (e sim `compose-settings`/`resolve-scope-layers`), então
  **`rhilo/main`-como-"branch-do-cliente" seria antipadrão** — o deploy por-cliente deveria ser uma
  **camada de escopo composta sobre o produto-base (`main`)**, não uma linhagem git paralela. **Mas**
  `rhilo/main` também carrega **versão/deploy real** (imagem ECS), que É eixo-branch legítimo. **Qual das
  duas leituras vale para um produto de consultoria: cliente = escopo (compõe, não ramifica) ou cliente =
  linhagem de deploy (ramifica)? Ou os dois eixos coexistem — `main` produto no eixo versão + camada de
  escopo por-cliente aplicada no deploy?**

**O core trabalhou/finalizou o caso "produto de consultoria + deploy por-cliente" em 0004/0005 — ou é um
slice novo?** Se a 0005 já responde (cliente = escopo via `resolve-scope-layers`, **sem** branch dedicada),
**qual o mecanismo concreto** para servir a RHILO sem manter `rhilo/main` como linhagem — e o que fazer com
a `rhilo/main` que já existe e está deployada?

## O que pedimos

Um **veredito** (ou apontar a RFC/parecer onde já fecha): (a) papel canônico da `develop`; (b) `main`-como-
produto-principal + política de merge `rhilo/main → main` enquanto andam juntas; (c) se 0004/0005 finalizam
ou se abre um slice novo. **Enquanto isso, seguramos o Movimento 1** (vendor do framework em `rhilo/main`)
até o vetor estar confirmado — não queremos vendorizar na linhagem errada de novo.
