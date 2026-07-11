---
title: "Veredito — metodologia de branches (main-produto × rhilo/main-cliente × develop) — resposta ao sinal metagamify/rhilo"
category: meta
tags: [gitflow, lineages, escopo, versao, rfc-0004, rfc-0005, federacao, veredito, co-evolve]
status: rascunho-para-ratificacao
date: 2026-07-11
re: docs/evolution/inbox/2026-07-10-metodologia-branches-gitflow-main-produto-vs-rhilo.md
para: metagamify (rhilo) — via /meta:co-evolve (outbox)
autor: onion (síntese) — PENDENTE ratificação do maestro
---

# Veredito — metodologia de branches (resposta ao sinal de 2026-07-10)

> **Status: RASCUNHO PARA RATIFICAÇÃO.** Este é o veredito recomendado, ancorado em evidência
> (RFC-0004, RFC-0005, parecer de 03/07, verificação git). **Não** vai ao consumidor antes do "vai" do
> maestro — a pergunta era dirigida a ele. As recomendações honram a diretriz **"não entortar doutrina
> para caber na tese; os eixos coexistem"**.

## 0. Correção factual antes de qualquer veredito (o enquadramento estava errado)

O sinal descreve "3 branches que divergiram em 15/06 e nunca se reencontraram". A verificação git **refuta**:

| Afirmado | Observado | Veredito |
|---|---|---|
| 3 disjuntas desde `c5036dfa` (15/06) | `develop`↔`rhilo/main` compartilham base **`05f96a05` (01/07, Merge PR#75)** | ❌ falso |
| `main` = "❌ sem framework" | `main` tem **239 arquivos** `.claude/` (adotou o Onion em 26/06) | ❌ falso |
| `rhilo/main` = 33 commits, só stamp | 33 ✅ · `.claude/` = 1 (`.onion-version`) ✅ | ✅ |

**O que muda:** não são "3 linhas paralelas". A realidade é: `main` **tem** o framework mas está **parada**
(26/06); `develop` e `rhilo/main` são **a mesma linha até 01/07**, e `rhilo/main` = essa linha **+33
commits de produção com o `.claude/` removido**. Logo o problema de `rhilo/main` não é "nasceu sem
framework" — é que o **framework foi tirado dela** após 01/07. Qualquer veredito parte deste fato, não do
framing original.

## 1. Q1 — Papel canônico da `develop`: GitFlow **ou** lane de framework?

**Veredito: falso dilema — os dois papéis coexistem; não escolha, declare.**

- O **eixo GitFlow** (`feature → develop → release → main`) permanece a doutrina do core para projetos com
  fluxo de features clássico.
- O **eixo conhecimento/framework** (a develop como lane de co-evolução) **não é drift** — é uma escolha
  legítima **de um adotante cuja "feature" principal é absorver e co-evoluir o framework**. É o caso do
  metagamify: a produção real mora em `rhilo/main`, então a `develop` naturalmente virou a lane de
  framework.
- **A regra (não entortar):** o core prescreve `develop = integração`. Um adotante **pode** reposicioná-la
  como lane de framework **desde que DECLARE** — que é exatamente o que o **D2 do parecer já fez** no
  `members.yaml` (lineage `framework: develop`). Declarado ≠ drift. O que seria drift é a develop virar
  lane de framework **sem** declaração e a produção rodar nua de guarda-rails — que é o estado a corrigir
  (Movimento 1), não o modelo a condenar.

→ **Ratifico** a lineage `framework`(develop) do parecer, com a nota: é postura do adotante, não mandato do
core. Os dois eixos da develop coexistem num projeto que tenha os dois fluxos.

## 2. Q2 — `main`-produto × `rhilo/main`-cliente: a separação e a política de merge

**Veredito: a separação é saudável e recomendada; a política de merge proposta, NÃO — ela está invertida.**

- **Sim** à leitura do maestro: `main` = **produto-base** (metagamify, o produto) e `rhilo/main` = linhagem
  de **deploy por-cliente** (a RHILO). É o padrão clássico de produto de consultoria com deploy por-cliente.
- **NÃO** à política "finalizar deploy em `rhilo/main` → mergear de volta em `main`" **como está**. Motivo
  factual: `main` está **atrás** (parada em 26/06), não à frente. Mergear produção-de-cliente de volta ao
  produto-base **arrastaria customizações-específicas-da-RHILO para dentro do produto** — poluindo a base.
  O fluxo saudável é o **inverso**: o produto-base (`main`/`develop`) flui **para** o deploy do cliente; só
  o que é **genuinamente produto** (não customização de cliente) sobe de volta, e via PR revisado, nunca
  por merge automático de linhagem.
- **Onde a `main` entra no `members.yaml`:** hoje o mapa tem só `framework`(develop) + `production`
  (rhilo/main). **Falta a `main`.** Recomendo uma **3ª lineage `product`(main)** — a linhagem do
  produto-base, distinta da linhagem de deploy-do-cliente. Isso resolve o buraco que o próprio sinal
  aponta: a `main`-produto passa a ter lugar declarado.

## 3. Q3 — cliente = escopo (compõe) **ou** linhagem (ramifica)? As RFCs fecham?

**Veredito: nenhuma RFC finaliza (é slice novo); e a resposta correta é "os dois eixos, sem confundi-los".**

O levantamento confirmou: **RFC-0004** trata de federação inter-instâncias (não do arranjo de branches
interno); **RFC-0005** trata de herança de escopo e **rejeita branch-como-escopo**, mantendo branch no eixo
**versão**. Nenhuma resolve o trio main/develop/rhilo-main — é slice novo. Mas a RFC-0005 dá o **princípio
que desempata**:

> **Versão × escopo são eixos separados. Escopo compõe (não ramifica); versão ramifica (no tempo).**

Aplicando ao caso "produto de consultoria + deploy por-cliente":

| Dimensão do "cliente RHILO" | Eixo | Mecanismo correto | `rhilo/main` como branch? |
|---|---|---|---|
| **Config/conhecimento/customização** de cliente | **escopo** | `resolve-scope-layers` / `compose-settings` (RFC-0005 plano 2), camada `framework→produto→CLIENTE` | ❌ **antipadrão** (escopo-como-branch) |
| **Deploy/release do artefato** (imagem ECS) | **versão** | branch de deploy/release (legítimo) | ✅ **legítimo** |

**A reconciliação (a chave):** `rhilo/main` é **legítima como branch de deploy** (carrega versão/release
real — isso é eixo-branch válido) e **ilegítima como "branch do cliente"** (carregar customização-de-cliente
como divergência-git-permanente = escopo-como-branch, o antipadrão da RFC-0005). A mesma branch pode estar
fazendo as **duas** coisas hoje — e é isso que confunde. A doutrina: **separe as duas cargas**.

**O que fazer com a `rhilo/main` já deployada** (3 movimentos, honrando a RFC-0005):
1. **Mantê-la** como branch de **deploy/release** (o que ela legitimamente é no eixo versão).
2. **Extrair** o que nela é **customização-de-cliente** para **camadas de escopo compostas** (`framework →
   produto → cliente-RHILO`) via `resolve-scope-layers` — em vez de divergência git.
3. **Reunificar o framework** nela — o **Movimento 1 do parecer, ainda pendente**: um `--update` mirando uma
   branch de integração cortada de `rhilo/main` (via `onion/vendor`, o mecanismo que acabou de shipar em
   #302), tornando o stamp **verdadeiro** e as sessões de produção deixando de rodar nuas de guarda-rails.

## 4. Síntese — o mapa recomendado

```
main            → lineage `product`   (produto-base metagamify; eixo VERSÃO do produto)   [NOVA no members.yaml]
develop         → lineage `framework` (co-evolução/conhecimento; declarada, D2)           [já existe]
rhilo/main      → lineage `production`(deploy/release do artefato; eixo VERSÃO do deploy)  [já existe]
cliente RHILO   → NÃO é branch: é CAMADA DE ESCOPO composta sobre o produto-base           [RFC-0005]
```

- **develop** e **GitFlow** coexistem (Q1) — declarados, não entortados.
- **main**-produto ganha lugar no mapa (Q2) — 3ª lineage `product`.
- **cliente = escopo** (compõe), **deploy = versão** (ramifica) (Q3) — os dois eixos, sem confundir.
- **Movimento 1 permanece o próximo passo** — vendorizar o framework na linhagem de produção, agora com o
  vetor confirmado (não vendorizar na linhagem errada de novo).

## 5. O que NÃO foi decidido aqui (fica com o maestro)

- Adicionar a lineage `product`(main) ao `members.yaml` — **recomendado**, mas é edição do SSOT de federação.
- Se e quando extrair as customizações-RHILO para camadas de escopo (esforço real; a RFC-0005 Fase 3
  `SUPERSEDES`-de-escopo ainda é gated).
- Liberar o **Movimento 1** (o sinal pediu para **segurá-lo** até o vetor confirmar — este veredito **é** a
  confirmação do vetor: pode seguir).

---

**Próximo passo:** ratificação do maestro → resposta ao metagamify via `/meta:co-evolve` (outbox), citando
este doc. Enquanto não ratificado, o Movimento 1 segue segurado conforme o consumidor pediu.
