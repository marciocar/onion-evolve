---
title: "Project Charter — Sistema Onion (Core)"
date: 2026-07-25
---

# Project Charter: Sistema Onion (`onion-evolve`)

> Camada: `docs/technical-context/01-core/` — Layer 1 (Core Project Context) da Arquitetura de Contexto Técnico. Escopo: o **core** do framework (este repositório), não um projeto-alvo onde o Onion está instalado.

---

## Vision Statement

O Sistema Onion é um **framework template em `.claude/`** que se instala em qualquer projeto — novo, legado ou regulado — para orquestrar o ciclo completo de desenvolvimento com Claude Code, separando **decisão de negócio**, **execução técnica** e **governança/compliance** em contextos distintos, conectados por fluxos e padrões repetíveis.

> *"Sistema Onion é um framework template em `.claude/` que instala num repositório o ciclo completo de desenvolvimento orientado por IA — produto, engenharia e compliance — sem alterar uma linha de código do projeto-alvo."*
> — `CLAUDE.md:5-9` (Contexto do Projeto)

O princípio operacional é **framework instalável**: o Onion não é o produto do repositório onde vive — é copiado/adotado em outros repositórios como camada de orquestração (`docs/meta-specs/architecture.md:12` — "Define... o princípio de **framework instalável**... normatiza o que constitui o 'esqueleto' do Sistema Onion como artefato reutilizável em projetos-alvo").

`onion-evolve` especificamente é o **fork privado de evolução** da porta Claude Code da família Onion — onde novas capacidades (auto-auditoria `/meta:evolve`, federação multi-repo, auto-teste de guardas) são incubadas antes de propagar à porta pública canônica (README.md:20-21, nota `[!NOTE]`).

---

## Success Criteria

Não há métricas de produto (não é um app com usuários finais) — o critério de sucesso é **aplicabilidade como framework reutilizável**. Fonte: `docs/analysis/onion-review-2026-05.md` (Revisão Analítica de Maio/2026, identidade canônica ratificada):

- **Cobertura completa do ciclo tri-dimensional** — produto, engenharia e compliance como dimensões **peer**, nenhuma hierarquizada sobre as outras (`onion-review-2026-05.md:64-71`; `CLAUDE.md:11`).
- **Instalável sem mantenedor de plantão** — um operador externo consegue copiar `.claude/` para um projeto-alvo, configurar `.env` e operar sem consultar quem criou o framework (`onion-review-2026-05.md` §Veredito — "o sistema não está pronto para ser aplicado a um projeto-alvo sem mantenedor de plantão" era o veredito em maio/2026, com plano de saneamento P0-P3 100% executado nos PRs #16–#27, nota em `onion-review-2026-05.md` §Próximo passo concreto).
- **SSOT viva, não digitada à mão** — contagens de comandos/agentes/skills/KBs derivam do filesystem via `.claude/validation/inventory.sh`, nunca escritas manualmente (`docs/onion/inventory.md:1-2`).
- **Dogfooding como validação-padrão** — toda mudança no core se valida rodando o artefato de verdade, não só plano/lint/spec (`CLAUDE.md` §Evolução do Core — Dogfood é o padrão master).

---

## Scope Boundaries

### IN scope

| Área | Descrição | Fonte |
|---|---|---|
| Comandos invocáveis | 123 comandos em 11 categorias (`product`, `git`, `engineer`, `docs`, `meta`, `validate`, `test`, `design`, `development`, `quick`) + `onion.md`, `warm-up.md`, `catch-up.md` no root | `docs/onion/inventory.md:8-9,15-29` (SSOT gerada) |
