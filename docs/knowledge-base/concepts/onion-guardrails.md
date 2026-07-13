---
title: "Onion Guardrails — a camada de guardrails nomeada (lente sobre gates existentes)"
category: concepts
tags: [seguranca, guardrails, gate, a2a, trust, intake, execucao, prompt-injection, taxonomia, fail-safe]
status: candidato
date: 2026-07-12
---

# Onion Guardrails — a camada de guardrails nomeada

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 0.1.0 (candidato) |
| **Categoria** | Concepts |
| **Aplicação** | Nomear, indexar e enquadrar os guardrails que o Onion já enforça; base para discutir cobertura por superfície |
| **Origem** | Discussão isolada `guardrails-nemo-lens` (2026-07-11/12): pesquisa de mercado → mineração de vetos → doutrina de escopo → design R15 → 3 checagens do core |
| **Consolida** | [`authorization-layers`](authorization-layers-intake-vs-execution.md) · `a2a-verify` · `trust-topology-check` · `metaspec-gate-keeper` · `.claude/validation/*` |
| **Registro de design** | [`docs/discussions/guardrails-nemo-lens/`](../../discussions/guardrails-nemo-lens/) (pesquisa, taxonomia com read-paths, protótipo R15, checagens) |

> **`candidato` — entra pra ganhar core por USO, não por estar pronta.** Esta KB nomeia e enquadra; não
> reivindica maturidade nem capacidade ativa. Toda afirmação de cobertura de mercado é **provisória**.

## 1. O que é (e o que NÃO é)

**Onion Guardrails** é a **moldura que nomeia, indexa e enquadra** os guardrails que o Sistema Onion **já
enforça** — hoje dispersos por `a2a-verify`, `trust-topology-check`, `.claude/validation/*`, never-clobber,
`metaspec-gate-keeper` e a camada de liberação [intake×execução](authorization-layers-intake-vs-execution.md).

> **É uma LENTE/ÍNDICE sobre gates existentes — não um sistema paralelo.** A grande maioria das categorias
> **herda por read-path** de mecanismos que já rodam; a taxonomia apenas os dá um vocabulário comum. Não é
> código novo; é o **nome, a moldura e a superfície** que faltavam.

O que **NÃO** é:
- ❌ **Não é 4ª dimensão peer.** As três permanecem produto/engenharia/compliance. Guardrail é **transversal**
  às três — como Task Manager ou Forge.
- ❌ **Não é vertical nova.** Consolidação transversal (KB + índice), não um plugin/manifesto `onion-guardrails`.
- ❌ **Não é DSL configurável** (estilo Colang/RAIL) nem **classificador probabilístico** no caminho crítico.

## 2. Doutrina de escopo — a decisão semântica

Derivada do diferencial-âncora (**determinístico + gated + spec-as-code**):

1. **Moderação de conteúdo** (violência/ódio/etc., estilo Llama Guard) é **delegada ao runtime hospedeiro**
   (Claude Code + provedor do modelo). O Onion é framework de desenvolvimento, não chatbot de usuário final.
2. **Nenhum classificador probabilístico** (guard-model) no caminho crítico — trairia o motor determinístico.
3. **A fatia semântica in-scope** é **proveniência de conteúdo não-confiável**: tratar conteúdo externo
   (federação, repo adotado, inbound) como **dado, não instrução**; marcar origem; gatear o efeito. É a
   leitura Onion do OWASP LLM01 — determinística, estendendo a camada de liberação, **nunca** um detector de
   injeção. (Design: [R15](../../discussions/guardrails-nemo-lens/r15-untrusted-content-provenance.md),
   protótipo em quarentena — **desenhado, não wired no core**.)

## 3. Os três modos de enforcement

Todo guardrail Onion enforça de um de **três modos** (não dois):

| Modo | Como veta | Custo de falha | Exemplo |
|------|-----------|----------------|---------|
| **Determinístico** | script emite string + `exit≠0`; sem LLM | baixo (falha ruidosa, testável) | `a2a-verify` → `bad-signature` |
| **Gated** | constituição textual que um LLM-agente obedece; abstém sem evidência | médio (depende do agente respeitar) | `metaspec-gate-keeper` REGRA ZERO |
| **Estrutural / silencioso** | previne por construção; **nunca emite** — a condição de erro é impossível por design | mínimo (não depende de *detectar* o erro) | `durable-commit` (staging por whitelist) |

Ordem de robustez para guardrails novos: **estrutural > determinístico > gated**. O modo estrutural é o mais
seguro porque não depende de a condição de erro ser detectada — ela não pode ocorrer.

## 4. A taxonomia ONION-R (índice)

A taxonomia **emergiu dos vetos reais** que os gates já emitem (não foi projetada). O catálogo completo — 14
categorias `ONION-R1..R14` + R15 (proposta), **148 vetos com read-path (`arquivo:linha`) e a string real
emitida** — vive no registro de design:
[`taxonomy-onion-r.md`](../../discussions/guardrails-nemo-lens/taxonomy-onion-r.md).

> **Por que a taxonomia com read-paths NÃO está nesta KB (ainda).** Um catálogo de `arquivo:linha` no core
> **sem um gate anti-drift** violaria ONION-R1 (integridade de SSOT) — a própria categoria que ela define.
> Até a promoção amarrar esse gate (re-grep dirigido via `/meta:kb-freshness`), a taxonomia detalhada fica
> como **evidência de discussão linkada**, e esta KB referencia os gates **por nome** (resiliente a drift).

Índice compacto (placement · modo · análogo de mercado — *nem todos são guardrails de segurança*):

| ONION-Rn | Categoria | Placement | Modo | Análogo |
|---|---|---|---|---|
| R1 | Integridade de SSOT / drift | meta | determinístico | ~OWASP LLM03 (*não-seg.*) |
| R2 | Autenticidade cripto A2A | input/fed | determinístico | nativo |
| R3 | Conformância de spec-as-code | input | determinístico | OWASP LLM03 |
| R4 | SSRF / egress | input/fed | determinístico | OWASP LLM06 |
| R5 | Never-clobber / adoção (I3) | exec | estrutural | nativo (~LLM06) |
| R6 | Topologia de confiança | federação | determinístico | nativo |
| R7 | Higiene de entrada CLI | input | determinístico | *(não-seg.)* |
| R8 | Contrato de federação | input/meta | determinístico | ~OWASP LLM03 |
| R9 | Anti-alucinação (REGRA ZERO) | meta | gated | **OWASP LLM09** |
| R10 | Proveniência / pin | input/exec | determinístico | **OWASP LLM03+04** |
| R11 | Anti-replay / frescor | input/exec | determinístico | nativo |
| R12 | Acessibilidade / WCAG | output | determinístico | *(não-seg.)* |
| R13 | Invariantes de orquestração | exec | gated+determ. | OWASP LLM06 |
| R14 | Fronteira SDAAL / tool | exec | determinístico | OWASP LLM06 |
| **R15** *(proposta)* | Proveniência de conteúdo não-confiável | input/fed/adopt | estrutural+gated | **OWASP LLM01** |

**11 das 14 categorias destiladas HERDAM por read-path** de gates existentes (reconciliação vs
`authorization-layers`/`a2a-verify`/`trust`:
[`reconciliation-authorization-layers.md`](../../discussions/guardrails-nemo-lens/reconciliation-authorization-layers.md)). Só **R15** traz design novo — e mesmo ele **estende** a linha da KB
[`authorization-layers`](authorization-layers-intake-vs-execution.md) §7 (o "próximo passo" que ela declarou
faltar), não a reinventa.

## 5. Cobertura e fronteiras (provisório)

Mapeando contra OWASP LLM Top 10 — **cobertura com lastro real** (não hype):

- ✅ **LLM03** (R3/R8/R10) · **LLM04** (R10) · **LLM06** (R4/R13/R14) · **LLM09** (R9) — coberto, determinístico.
- 🟡 **LLM01** (R15, proposta/protótipo) · **LLM02/07** (fatia verificável por regra, futuro).
- ⚪ **Llama Guard S1–S14** (moderação de conteúdo) — **delegado ao host** (doutrina §2).
- **Braços nativos sem equivalente nas taxonomias OWASP/Llama Guard**: R2/R6/R11 (autenticação/topologia/
  frescor message-layer agente-a-agente) e R5 (never-clobber de coabitação). *(A ausência ali é esperada —
  são taxonomias de moderação/injeção, não de identidade/federação de agente.)*

## 6. Falar em linguagem de mercado sem trair o motor

Lente Aristóteles (`igual→transfere / diferente→desenha`):
- **Transfere:** a moldura de placement (NeMo), a taxonomia nomeada (Llama Guard → `ONION-R`), o vocabulário
  on-fail (Guardrails-AI → o loop `fix→re-dogfood` é um `FIX_REASK` determinístico), os rótulos OWASP LLM0X.
- **Desenha próprio:** o **motor** (determinístico/gated/estrutural, não Colang nem guard-model) e os
  conceitos nativos (trust topology, never-clobber, entrega-sem-commit).

## 7. Status e próximos passos

- ✅ Doutrina, taxonomia (evidência) e design R15 fechados; 3 checagens do core passadas (reconciliação,
  refutador, escopo).
- 🔜 **Gate anti-drift da taxonomia** (ONION-R1 sobre si mesma) — pré-requisito para promover o catálogo
  detalhado ao core.
- 🔜 **R15 (wire-in)** — cerca de proveniência + gate de efeito; hoje protótipo em quarentena, não wired.
- 🔜 **Superfície `/meta:guardrails`** (índice de leitura vs DSL) — questão de design aberta; fora de escopo.
