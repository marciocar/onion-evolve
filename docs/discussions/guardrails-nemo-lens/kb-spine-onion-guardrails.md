---
title: "Onion Guardrails — a camada de liberação nomeada (espinha de KB — DRAFT isolado)"
category: discussion
status: draft-para-promocao-gated
date: 2026-07-12
branch: discuss/guardrails-nemo-lens
promove_para: docs/knowledge-base/concepts/onion-guardrails.md
depende_de: [research-market-lens.md, taxonomy-onion-r.md]
nota: >
  Este é o RASCUNHO da espinha da KB, escrito dentro da discussão isolada.
  A promoção para docs/knowledge-base/concepts/ é um passo GATED separado —
  o maestro decide entregar ao core. Nada aqui é vertical peer nova.
---

> **Isolada.** Pensa, não entrega. A promoção ao core é decisão do maestro.

# Onion Guardrails — a camada de liberação nomeada

## 1. O que é (e o que NÃO é)

**Onion Guardrails** é a **moldura que nomeia, indexa e dá superfície** aos guardrails que o Sistema Onion **já enforça** — hoje dispersos por `a2a-verify`, `trust-topology-check`, `.claude/validation/*`, `never-clobber`, `metaspec-gate-keeper` e a camada de liberação intake×execução. Não é código novo; é o **nome e a lente** que faltavam (o SEED diagnosticou: "falta o nome, a moldura e a superfície").

O que **NÃO** é (fronteiras deliberadas):

- ❌ **Não é uma 4ª dimensão peer.** As três permanecem produto / engenharia / compliance. Guardrail é **transversal** às três, como o Task Manager ou o Forge.
- ❌ **Não é uma DSL configurável** ao estilo Colang (NeMo) ou RAIL (Guardrails-AI). Os guardrails do Onion são scripts determinísticos + convenções + constituições textuais gated — uma "camada configurável central" importaria a complexidade e o custo (latência, manutenção de exemplos) que a doutrina recusa.
- ❌ **Não é um classificador probabilístico** (guard-model) no caminho crítico. Ver §2, princípio 2.

O que **é**: uma KB transversal (moldura + taxonomia + índice de read-paths) e, no máximo futuro e gated, um comando de **leitura** (`/meta:guardrails` — lista/explica, não configura). O valor é reconhecimento de mercado **sem trair o motor**.

## 2. Doutrina de escopo — a decisão semântica

A pergunta que a discussão deixou aberta: *guardrails de camada semântica (prompt-injection, vazamento, moderação de conteúdo) são in-scope, ou delegados ao runtime hospedeiro?* A resposta, derivada do diferencial-âncora (**determinístico + gated + spec-as-code**) e do que a mineração de vetos reais provou:

### Princípio 1 — Moderação de conteúdo é DELEGADA ao runtime hospedeiro
O Onion é um **framework de desenvolvimento** que roda *dentro* do Claude Code — **não é um chatbot de usuário final**. Moderar violência, ódio, CSAM, self-harm (a taxonomia Llama Guard S1–S14) é responsabilidade do **provedor do modelo + do host** (Anthropic + Claude Code: safety do modelo, sistema de permissões, sandbox, hooks). O Onion **não replica** essa camada. Reivindicar "cobertura Llama Guard" seria falso e redundante. → **Out-of-scope by design.**

### Princípio 2 — Nenhum classificador probabilístico no caminho crítico
Detectar injection/toxicidade por um **guard-model** (um 2º LLM pontuando por probabilidade) é exatamente o mecanismo que a doutrina Onion recusa. A mineração confirmou: até o guardrail **anti-alucinação** (`ONION-R9`, a REGRA ZERO do `metaspec-gate-keeper`) é resolvido por **abstenção gated com evidência citada**, não por confiança estatística. Importar um classificador trairia o motor. → Guardrails novos são **determinísticos** (script + exit code), **gated** (constituição textual) ou **estruturais** (impossíveis por construção) — nunca probabilísticos.

### Princípio 3 — A fatia semântica que o Onion DE FATO possui é in-scope, à maneira Onion
O Onion tem uma superfície de **conteúdo não-confiável** que é arquiteturalmente sua: **sinais de federação** (a2a) e **conteúdo de repo adotado** (`/meta:adopt`, `/docs:reverse-consolidate`, `inbound/`) fluem para o raciocínio dos agentes. O `a2a-verify` fecha a confiança **criptográfica** (R2 autenticidade, R6 topologia, R11 anti-replay) — mas **uma mensagem assinada por um peer confiável ainda pode carregar instrução injetada**. Essa é a leitura Onion do **OWASP LLM01 (Prompt Injection)**:

> **Proveniência e quarentena de conteúdo não-confiável** — tratar conteúdo externo (federação, repo adotado, inbound) como **dado, não instrução**; marcar a origem; e **passar por gate antes de agir** sobre ele. Determinístico e gated, estendendo a camada intake×execução — **nunca** um detector de injection probabilístico.

→ **In-scope**, como extensão da camada de liberação, não como classificador. Idem para uma leitura *determinística* de LLM02/LLM07 (lint que sinaliza segredo em artefato; convenção never-commit-`.env`) — o que for verificável por regra, não por modelo.

**Síntese da doutrina de escopo:** o Onion guarda o que pode guardar **por regra ou por gate**; **delega** ao host o que só se resolve por julgamento probabilístico de conteúdo; e reconhece que sua fatia semântica própria é **proveniência de conteúdo não-confiável**, não moderação.

## 3. Os três modos de enforcement

O eixo que a mineração revelou — e que é a espinha conceitual desta KB. Todo guardrail Onion enforça de um de **três modos** (não dois):

| Modo | Como veta | Custo de falha | Exemplo (read-path) |
|------|-----------|----------------|---------------------|
| **Determinístico** | script emite string + `exit≠0`; sem LLM | baixo (falha é ruidosa e testável) | `a2a-verify.sh:163` → `bad-signature` |
| **Gated** | constituição textual que um LLM-agente obedece; abstém sem evidência | médio (depende de o agente respeitar) | `metaspec-gate-keeper.md:64` → INCONCLUSIVO, nunca REJEITADO por falha de leitura |
| **Estrutural / silencioso** | previne por construção; **nunca emite** — a condição de erro é impossível por design | mínimo (não depende de *detectar* o erro) | `durable-commit.sh:46-47` (staging por whitelist); `merge-onion-hooks.sh` (merge por união) |

O **modo estrutural é o mais seguro**: não depende de a condição de erro ser detectada, ela não pode ocorrer. Um catálogo de guardrails que só listasse vetos *emitidos* perderia essa classe inteira — foi o achado do fio #1 (verificação das hipóteses de never-clobber). Guardrails novos devem **preferir estrutural > determinístico > gated**, nessa ordem de robustez.

## 4. A taxonomia ONION-R (índice)

Destilada de **148 vetos categorizados reais** minerados dos gates (todos com read-path confirmado — evidência completa em [`taxonomy-onion-r.md`](./taxonomy-onion-r.md)). **A taxonomia emergiu dos vetos, não foi projetada.** *(Nem todos são guardrails de **segurança** — inclui gates de qualidade genéricos: R1 drift, R7 CLI, R12 WCAG; a coluna "análogo de mercado" separa os dois.)*

> **ONION-R é uma LENTE/ÍNDICE sobre gates existentes — não um sistema paralelo.** **11 das 14 categorias
> HERDAM por read-path** de mecanismos que já rodam (`a2a-verify`, `trust-topology-check`,
> `metaspec-gate-keeper`, `.claude/validation/*`); só R15 traz design novo — e mesmo ele **estende** a linha
> intake×execução da KB [`authorization-layers`](../../knowledge-base/concepts/authorization-layers-intake-vs-execution.md), não a reinventa. Reconciliação completa (checagem #1 do core):
> [`reconciliation-authorization-layers.md`](./reconciliation-authorization-layers.md).

| ONION-Rn | Categoria | Placement | Modo dominante | Análogo de mercado |
|---|---|---|---|---|
| **R1** | Integridade de SSOT / drift doc↔filesystem | meta | determinístico | sem equiv. (~LLM03) |
| **R2** | Autenticidade criptográfica A2A (JWS) | input/exec | determinístico | **nativo** (sem equiv.) |
| **R3** | Conformância de spec-as-code | input | determinístico | OWASP LLM03 |
| **R4** | SSRF / controle de egress | input/fed | determinístico | OWASP LLM06 |
| **R5** | Never-clobber / adoção (I3) | exec/input/output | **estrutural** | sem equiv. (~LLM06) |
| **R6** | Topologia de confiança / relay | federação | determinístico | **nativo** |
| **R7** | Higiene de entrada CLI/config | input/exec | determinístico | sem equiv. |
| **R8** | Validação de contrato de federação | input/meta | determinístico | sem equiv. (~LLM03) |
| **R9** | Aterramento em evidência / anti-alucinação | meta/input | **gated** | **OWASP LLM09** |
| **R10** | Proveniência / pin (supply chain) | input/exec | determinístico | **OWASP LLM03+LLM04** |
| **R11** | Anti-replay / frescor temporal | input/exec | determinístico | **nativo** |
| **R12** | Acessibilidade / design tokens (WCAG) | output | determinístico | sem equiv. (não-segurança) |
| **R13** | Invariantes de orquestração | execução | gated + determinístico | OWASP LLM06 |
| **R14** | Fronteira SDAAL / agência de tool | exec/input | determinístico | OWASP LLM06 |
| **R15** *(desenhada, [design](./r15-untrusted-content-provenance.md))* | **Proveniência de conteúdo não-confiável** | input/federação/adopt | estrutural + gated | **OWASP LLM01** |

R1–R14 são **destilados** (existem hoje). **R15 é a única categoria proposta** — a fatia in-scope do princípio 3, ainda a desenhar; entra como *aberta*, não como destilada.

## 5. Cobertura e fronteiras

Mapeando as 14 categorias existentes + R15 contra a moldura OWASP LLM Top 10:

| OWASP | Cobertura Onion | Situação |
|---|---|---|
| **LLM03** Supply Chain | R3, R8, R10 | ✅ coberto (determinístico) |
| **LLM04** Data/Model Poisoning | R10 (canário de pin) | ✅ coberto |
| **LLM06** Excessive Agency | R4, R13, R14 (+ braços R5) | ✅ coberto — **o mais forte** (casa 1:1 com camadas de liberação) |
| **LLM09** Misinformation | R9 (anti-alucinação gated) | ✅ coberto |
| **LLM01** Prompt Injection | **R15 (proposta)** | 🟡 fronteira própria in-scope — proveniência, não classificador |
| **LLM02 / LLM07** Sensitive Info / System-Prompt Leak | parcial futuro (lint determinístico) | 🟡 só a fatia verificável por regra |
| **LLM10** Unbounded Consumption | tangencial (fan-out opt-in, R13) | 🟡 sem gate de custo/loop dedicado |
| **LLM08** Vector/Embedding | — | ⚪ N/A por arquitetura (sem RAG) |
| **Llama Guard S1–S14** (conteúdo) | — | ⚪ **delegado ao host** (princípio 1) |

Braços **sem equivalente nas taxonomias de guardrail de LLM que revisamos** (OWASP LLM Top 10, Llama Guard) — a contribuição que o Onion tem *a mais*, não a menos: **R2/R6/R11** (autenticação, topologia e frescor message-layer agente-a-agente) e **R5** (never-clobber de coabitação na adoção). *(Ressalva: OWASP/Llama Guard são taxonomias de moderação/injeção, não desenhadas para identidade/federação agente-a-agente — a ausência ali é esperada, não prova de vácuo de mercado absoluto; um protocolo de identidade de agente (ex.: mTLS, SPIFFE) resolve parte disso em outra camada.)*

**Leitura de cobertura por placement** (do fio #1): a robustez de *input* do Onion é **toda sintática/estrutural** (envelope JSON, frontmatter YAML, URL, SHA). O *input semântico* (prompt/conteúdo não-confiável em linguagem natural) é a única fronteira aberta — e R15 é como o Onion a fecha **sem** virar um chatbot moderado.

## 6. Como falar disso em linguagem de mercado (sem trair o motor)

A lente Aristóteles (igual→transfere / diferente→desenha) do fio de pesquisa dá o guia:

- **Transfere** (empréstimo de vocabulário, ganho de reconhecimento): a **moldura de placement** do NeMo (input/execução/output/federação); a ideia de **taxonomia nomeada** do Llama Guard (é o `ONION-R`); o vocabulário de **ação on-fail** do Guardrails-AI (o loop `fix → re-dogfood` **é** um `FIX_REASK` determinístico); os rótulos **OWASP LLM0X** para auditores.
- **Desenha próprio** (natureza diverge): o **motor** — determinístico/gated/estrutural, não Colang nem guard-model; e os conceitos **nativos** (trust topology, never-clobber, entrega-sem-commit) que o mercado não tem palavra para nomear.

## 7. Estado e próximos passos (provisório)

- ✅ **Taxonomia destilada e 100% aterrada** (148 vetos categorizados, read-path confirmado) — [`taxonomy-onion-r.md`](./taxonomy-onion-r.md).
- ✅ **Doutrina de escopo decidida** (§2) — moderação delegada; classificador recusado; R15 (proveniência) é a fatia própria.
- ✅ **Três modos** identificados (§3) — o modelo conceitual da KB.
- ✅ **R15 desenhado** — [`r15-untrusted-content-provenance.md`](./r15-untrusted-content-provenance.md): proveniência (cerca estrutural no ingresso) + dado-não-instrução (constituição gated) + efeito gated (já estrutural em C1/C2, extensão gated em C3). Achado: das **4 sub-regras, 1 (R15.3a) já existe** estruturalmente sem nome (`a2a-accept.sh:8`, `co-deliver.sh:12`); **3 são design novo** (R15.1/R15.2/R15.3b) — **sem classificador**. (No eixo restrito do *efeito-gate*: existe para C1/C2, falta para C3.) Desenhado, não implementado (implementar = entrega gated).
- 🔜 **Superfície `/meta:guardrails`** (gated, só se justificar) — comando de **leitura** que lista as categorias e seus read-paths; **não** configura. Decidir a linha índice-vs-DSL antes de propor.
- ⚠️ **Promoção ao core é gated** — esta espinha vive na discussão isolada. Vira `docs/knowledge-base/concepts/onion-guardrails.md` só quando o maestro pedir; toda afirmação "cobre LLM0X" permanece **provisória** até revisão.
