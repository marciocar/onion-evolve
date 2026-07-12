---
title: "Régua de transferência (Aristóteles) — igual→transfere, diferente→desenha"
category: concepts
tags: [heuristica, transferencia, aristoteles, reuso, sdaal, adopt, pesquisa, reguas]
status: candidato
date: 2026-07-12
---

# Régua de transferência — *igual → transfere / diferente → desenha*

> **Status: CANDIDATA — nomeia uma régua que o core JÁ vive, sem nome.** Não importa filosofia: dá nome e casa
> canônica a um critério de decisão que já opera no SDAAL (reusar adapter genérico × desenhar especialista) e no
> `/meta:adopt` (adotar × fresh). Nasceu explícita nos estudos de discussão (as "duas âncoras") e foi trabalhada
> como candidato gated na pesquisa da camada dialógica (branch `docs/constellation-dialogic-layer-2026-07`, ainda
> não mesclada). Promoção a doutrina firme = dogfood + nosso julgamento (é candidata, não lei).

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | Decidir, com evidência, se um conhecimento/artefato existente **transfere** ou se o caso exige **design fresco** |
| **Fonte** | Aristóteles, *Ética a Nicômaco* V (justiça formal: *tratar igual o que é igual, diferente o que é diferente*) |
| **Réguas irmãs** | [Hegel — limite/movimento](../../analysis/onion-plan-identity-kg-dogfood-2026-07.md) §2.6 (quando o conhecimento deixa de ser monotônico → KG) · [Bloom revisado](../../analysis/onion-plan-identity-kg-dogfood-2026-07.md) §2.2 (teto de esforço) |
| **Já vivida em** | [SDAAL](specification-driven-ai-abstraction-layer.md) (reuso × especialista) · `/meta:adopt` (adotar × fresh) |

## 1. O problema — transferir ou desenhar?

Diante de um caso novo (um provider, um cliente, um padrão de outra instância, um achado de pesquisa), há sempre a
pergunta: **reuso o que já existe, ou desenho do zero?** Errar para qualquer lado tem custo, e os dois erros são
**simétricos e opostos** — o que torna a decisão fácil de errar por reflexo.

## 2. A régua

**Declarar, com evidência, um veredito explícito:**

> **IGUAL → transfere** (reusa o que já existe) · **DIFERENTE → desenha** (cria fresco para este caso).

O valor não é o slogan — é a **disciplina do veredito declarado**: em cada decisão de encaixe, dizer qual dos dois
e **por quê** (com evidência), em vez de reusar por preguiça ou reinventar por vaidade.

## 3. Os dois erros simétricos (o que a régua bloqueia)

| Erro | O que é | Sintoma |
|---|---|---|
| **Falsa analogia** | forçar o caso novo no molde do velho porque "parece igual" | o reuso vaza premissas que não se aplicam; o encaixe range |
| **Falsa distinção** | reinventar do zero o que na verdade transferia | retrabalho; duas soluções para o mesmo problema, divergindo |

A régua existe para tornar esses dois erros **visíveis e nomeáveis** — não é "reusar sempre" (isso é falsa
analogia latente) nem "desenhar sempre" (falsa distinção latente).

## 4. Já vivida no core (por isso é *nomear*, não importar)

A régua não é nova aqui — ela já governa decisões de design do Onion, sem nome:

- **SDAAL** ([specification-driven-ai-abstraction-layer](specification-driven-ai-abstraction-layer.md)): Asana e
  Linear **reusam o `@task-specialist` genérico** (*igual → transfere*); Jira e ClickUp ganham **especialista
  dedicado** (*diferente → desenha*, porque ADF/JQL/transitions e Unicode/custom-fields justificam). A decisão
  "quem merece especialista" **é** a régua de transferência aplicada.
- **`/meta:adopt`** (`.claude/commands/meta/adopt.md`): a escolha entre **adotar** o que já existe upstream e
  **desenhar fresco** para a instância é o mesmo veredito.

Nomear o que o uso já mostra é dogfood — não intelectualização.

## 5. Conversa com as outras réguas (nota, não doutrina)

Esta régua **conversa** com dois outros critérios que o Onion usa ao decidir *como pensar*. A associação é
**observação, não doutrina ratificada** — não há um "trio" canônico; Hegel e Bloom vivem hoje num plano (§2.x),
não como réguas próprias. A tabela abaixo é um mapa mental, não uma tese:

| Critério | Eixo | Pergunta |
|---|---|---|
| **Aristóteles** (esta) | transferência | igual transfere, ou diferente exige design fresco? |
| **Hegel** (limite/movimento, §2.6) | não-monotonicidade | o novo *soma* (prosa) ou *contradiz/supera* (→ KG)? |
| **Bloom revisado** (§2.2) | esforço | qual o nível mais alto que a pergunta exige (Lembrar…Criar)? |

Os três são pragmáticos — critérios de decisão, não teses filosóficas.

## 6. Como aplicar (a disciplina)

- **Declare o veredito** em toda decisão de encaixe: *IGUAL → transfere* ou *DIFERENTE → desenha*, **com evidência**.
- **Dispare no intake** de conhecimento externo (é onde a transferência acontece) — não num relógio.
- **Prefira transferir quando igual, desenhar quando diferente** — e desconfie do reflexo (o caminho de menor
  esforço costuma ser um dos dois erros).

## 7. Resumo executável

| Faça | Não faça |
|---|---|
| declarar *igual→transfere / diferente→desenha* com **evidência** | reusar por preguiça (falsa analogia) |
| nomear o veredito em cada encaixe | reinventar por reflexo (falsa distinção) |
| tratar como **régua irmã** de Hegel/Bloom (critério pragmático) | tratá-la como filosofia/seminário |
| citá-la onde já se vive (SDAAL, adopt) | assumir que é uma ideia nova importada |
