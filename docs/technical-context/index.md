---
title: "Technical Context — Índice de Navegação (Core do Sistema Onion)"
date: 2026-07-25
kg: docs/onion/graph/technical-context-core-2026-07.kg.yaml
---

# Technical Context — Sistema Onion (core)

> Hub de navegação da **Arquitetura de Contexto Técnico** do **CORE** — o framework template em
> `.claude/` deste repositório (`onion-evolve`), não um projeto-alvo onde o Onion está instalado.
> Organizado nas 4 camadas do [`technical-context-template.md`](../../.claude/commands/common/templates/technical-context-template.md):
> Núcleo → AI-Context → Domínio → Workflow.
>
> **Escopo e omissões deliberadas.** O core é um framework de orquestração, não um app com API HTTP nem
> regras de negócio de domínio próprias — por isso `03-domain/api-specification.md` **não existe** (N/A por
> desenho) e `03-domain/business-logic.md` cobre o "domínio" real do core: as abstrações SDAAL, o Knowledge
> Graph, a co-evolução/federação e os workflows faseados. Essas ausências são intencionais, não lacunas.

---

## Camada 1 — Núcleo (`01-core/`)

| Arquivo | O que cobre |
|---------|-------------|
| [`project-charter.md`](01-core/project-charter.md) | Vision, success criteria, scope boundaries (in/out), stakeholders e technical constraints do core; identidade canônica (framework template, **não** npm, **não** CLI standalone, plataforma única Claude Code, 3 dimensões peer). |
| [`adr/index.md`](01-core/adr/index.md) | Índice dos **36 ADRs** reais (`docs/analysis/onion-adr-*.md`) agrupados em 5 temas; não recria os ADRs, só aponta com 1 linha de sumário + status. |

## Camada 2 — AI-Context (`02-ai-context/`)

| Arquivo | O que cobre |
|---------|-------------|
| [`ai-development-guide.md`](02-ai-context/ai-development-guide.md) | Style guide para quem **edita o próprio framework**: idioma por camada (pt-BR/inglês), naming/formatação, fronteiras de arquitetura §4.2/4.3, as **45 regras do lint** (41 HARD/8 SOFT), guardrails R15.2/R15.3b de conteúdo não-confiável, gotchas e checklist pré-PR. |
| [`codebase-guide.md`](02-ai-context/codebase-guide.md) | Mapa de diretórios (`.claude/` + `docs/`), 99 comandos / 51 agentes / 10 skills, utils SDAAL, scripts de validação (âncoras `inventory.sh`, `onion-version.sh`), hooks de ciclo de vida de sessão e fluxo de dados/integrações. |

## Camada 3 — Domínio (`03-domain/`)

| Arquivo | O que cobre |
|---------|-------------|
| [`business-logic.md`](03-domain/business-logic.md) | O "domínio" do core: (1) **SDAAL** e suas instâncias reais (task-manager API-first, forge CLI-first); (2) **Knowledge Graph SDAAL** (layers audit/domain, footguns de autoria, "git merge não reconcilia verdades"); (3) **co-evolução/federação** (tiers RFC-0003, invariante I3, never-clobber do `/meta:adopt`); (4) **workflows faseados** (contrato de fase `plan.md`, sessões persistentes). |
| _`api-specification.md`_ | **N/A por desenho** — o core não expõe API HTTP nem regras de negócio de domínio (isso é do projeto-alvo adotante). Ausência intencional. |

## Camada 4 — Workflow (`04-workflow/`)

| Arquivo | O que cobre |
|---------|-------------|
| [`contributing.md`](04-workflow/contributing.md) | Branch strategy (GitFlow via `/git:flow`), ciclo faseado `/engineer:plan→pr-update`, code review em 2 camadas (determinístico `onion-validate.yml` vs semântico `onion-review.yml`, vermelho invertido), testes, setup local (githook nativo `core.hooksPath`) e a doutrina de dogfood. |
| [`architecture-challenges.md`](04-workflow/architecture-challenges.md) | O retrato honesto do que falta: sinais do inbox de co-evolução ainda sem mecanismo aplicado, tensão federação formal (0 contratos) vs co-evolução informal ativa (58 no CHANGELOG), design-context provisório/gated, doutrina de mitigação de inferência não-embarcada, e os achados SOFT persistentes do próprio gate. |

---

## Grafo de proveniência

O mapa formal desta camada (as 4 camadas + os subsistemas-âncora traçando cada conceito ao arquivo que o
documenta) vive como Knowledge Graph SDAAL em
[`docs/onion/graph/technical-context-core-2026-07.kg.yaml`](../onion/graph/technical-context-core-2026-07.kg.yaml).
Rode `bash .claude/validation/kg-radar.sh docs/onion/graph/technical-context-core-2026-07.kg.yaml` para o
radar determinístico (atenção, integridade, frescor).

---

> **Proveniência.** Gerado por **M1b (dogfood do próprio technical-context)** em **2026-07-25** — o comando
> `/docs:build-tech-docs` rodado sobre o próprio core, um subsistema por arquivo, com reverse-eng real das
> fontes (Read/Bash/Grep no repo, não inventado). Contagens vêm sempre da SSOT
> [`docs/onion/inventory.md`](../onion/inventory.md) (gerada por `.claude/validation/inventory.sh`), nunca
> digitadas à mão.
