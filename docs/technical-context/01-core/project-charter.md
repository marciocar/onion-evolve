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
| Comandos invocáveis | 107 comandos em 10 categorias (`product`, `git`, `engineer`, `docs`, `meta`, `validate`, `test`, `design`, `development`, `quick`) + `onion.md`, `warm-up.md`, `catch-up.md` no root | `docs/onion/inventory.md:8-9,15-29` (SSOT gerada) |
| Agentes especializados | 51 agentes em 9 categorias (`compliance`, `deployment`, `development`, `git`, `meta`, `product`, `research`, `review`, `testing`) | `docs/onion/inventory.md:9,33-45` |
| Skills | 12 skills em `.claude/skills/` (`onion` orquestrador; `onion-patterns`; `onion-validation`; `language-standards`; `onion-orchestration`; entre outras) | `docs/onion/inventory.md:10`; `CLAUDE.md:13` |
| Knowledge Bases | 93 KBs em `docs/knowledge-base/` (contagem inclui READMEs de (sub)categoria, exclui `index.md`) | `docs/onion/inventory.md:11` |
| Task Manager Abstraction | Camada SDAAL plugável — Jira, ClickUp, Asana, Linear — via `.claude/utils/task-manager/` | `CLAUDE.md:14,20-38` |
| Forge (host remoto) | Abstração SDAAL irmã do task-manager — GitHub hoje (`cli` default via `gh`, `api` fallback); GitLab/Bitbucket com "costura pronta", não implementado | `CLAUDE.md` §Forge; `.claude/utils/forge/adapters/github.md` |
| Três dimensões peer | Produto (`product/collect→feature`), Engenharia (`engineer/plan→pr-update`), Compliance (ISO 27001, SOC2, PMBOK, ISO 22301) — workflows faseados retomáveis, invariantes do framework | `CLAUDE.md:9`; `docs/meta-specs/index.md` §commands.md |
| Documentação constitucional | Meta-specs L0 (`docs/meta-specs/`) + Knowledge Bases + Spec-as-Code (business/technical/compliance context) | `docs/meta-specs/index.md:6-24`; README.md §Arquitetura de contexto |
| Sessões persistentes | `.claude/sessions/<feature>/` para contexto de desenvolvimento retomável (workflows faseados) | `CLAUDE.md` §Estrutura de Arquivos |

### OUT of scope (abandonado formalmente em 2026-05-18)

| Direção abandonada | Por quê | Fonte |
|---|---|---|
| Estrutura `.onion/` agnóstica | Abstração prematura sem ganho real; core aposta em profundidade de integração com Claude Code, não portabilidade entre IDEs | `docs/analysis/onion-review-2026-05.md` frontmatter `abandonado:` + `CLAUDE.md:11` |
| Plano de implementação v4.0 (FASES 5-9) | Aprendizado contínuo / A2A runtime beira agente autônomo fora de controle; humano-maestro é invariante | `docs/analysis/onion-review-2026-05.md` frontmatter `abandonado:`; `CLAUDE.md:11` |
| `packages/onion-cli/` — CLI standalone | Distribuir como produto contradiz a identidade de template instalável | `docs/analysis/onion-review-2026-05.md` frontmatter `abandonado:`; `docs/meta-specs/architecture.md:230-232` |
| Multi-IDE (Cursor, Zed, Windsurf, Copilot, Antigravity, Codex) **no core** | Dilui a integração; plataforma única é Claude Code. Multi-plataforma é responsabilidade da **família** (repos-irmãos `onion-cursor`, `onion-zed` etc.), não do core `onion-evolve` | `docs/meta-specs/architecture.md:227-234`; README.md §Família Onion |
| Produto npm distribuído publicamente | Framework template consumido via clonagem/adoção de `.claude/`, não via `npm install` | `CLAUDE.md:9`; `docs/meta-specs/architecture.md:232` |
| `design/` como 4ª dimensão peer | `design/` é **categoria de comando** (INCUBAÇÃO/provisória); o ciclo permanece em 3 dimensões peer (produto/engenharia/compliance) — promoção de `design-context` a peer é provisória e gated | `CLAUDE.md:10`; `docs/meta-specs/architecture.md:44` (nota "INCUBAÇÃO — categoria provisória; ver ADR design-peer-promotion") |

---

## Key Stakeholders

| Papel | Quem/O quê | Fonte |
|---|---|---|
| **Maestro (humano)** | Marcio Carvalho — decisor final; nenhum plano de "aprendizado contínuo autônomo" substitui o humano no controle | `CLAUDE.md` frontmatter Git user; `docs/analysis/onion-review-2026-05.md` (abandono de v4.0 FASES 5-9 por essa razão) |
| **Operador externo (adotante)** | Dev/tech lead com projeto legado; startup técnica com Jira/ClickUp+GitHub; time regulado (fintech/healthtech/SaaS enterprise); mantenedor de múltiplos repos | `docs/knowledge-base/meta/onion-framework-identity.md:325-330` (§7 Público-alvo ideal) |
| **`@onion`** | Agente orquestrador master / ponto de entrada do framework | `CLAUDE.md` §Agentes Especializados |
| **`@product-agent`** | Gestão estratégica de produto (qualquer task manager) | `CLAUDE.md` §Agentes Especializados |
| **`@metaspec-gate-keeper`** | Valida conformidade arquitetural contra as 5 meta-specs L0; opera em modo Framework (L0, artefatos `.claude/**` deste repo) ou modo Projeto-alvo (L1+, quando instalado noutro repo) | `docs/meta-specs/index.md:57-71` |
| **`@branch-metaspec-checker`** | Aplica o mesmo padrão do gate-keeper ao diff do branch, no pré-PR | `docs/meta-specs/index.md:60` |
| **Família Onion (repos-irmãos)** | `onion` (hub público) · `onion-cursor` · `onion-antigravity` · `onion-zed` · `onion-codex` · `onion-copilot` — destilações multi-plataforma que consomem decisões do core mas não são o core | README.md §Família Onion |
| **Adotantes reais (co-evolução)** | Repos que instalaram o Onion e sinalizam mudanças de volta ao core via doc-bridge (`/meta:co-*`) — lineages mapeadas em `federation/members.yaml` | `docs/knowledge-base/meta/onion-framework-identity.md:404-406` (§10 Ecossistema Vivo) |

---

## Technical Constraints

Restrições **não-negociáveis** do core, extraídas de `CLAUDE.md` e `docs/meta-specs/architecture.md`:

1. **Plataforma única: Claude Code.** "Sistema Onion roda exclusivamente em Claude Code." Não há suporte planejado para Cursor/Continue/Cline como plataforma do *core*; mudanças na plataforma Claude Code (estrutura de `.claude/`, formato de skills, novas tools) podem exigir atualização do framework.
   *(Fonte: `docs/meta-specs/architecture.md:227-234`)*

2. **Não é CLI standalone, não é produto npm, não é distribuído publicamente.** Consumido via clonagem/adoção de `.claude/` num repositório-alvo — nunca via `npm install` ou binário instalado globalmente.
   *(Fonte: `CLAUDE.md:9`; README.md §O que é)*

3. **Três dimensões peer, sem acoplamento cruzado direto em nível de comando.** Produto, engenharia e compliance não podem depender diretamente umas das outras — coordenação só via sessions (estado compartilhado), meta-comandos em `meta/`, skills orquestradoras (`skill: onion`), ou documentação consolidada em `docs/`.
   *(Fonte: `docs/meta-specs/architecture.md:222-229`, §4.3 Acoplamento entre dimensões)*

4. **Workflows faseados retomáveis são invariantes — nunca fundidos numa fase única.** `product/collect→feature` (descoberta a backlog) e `engineer/plan→pr-update` (planejamento a entrega) devem permanecer multi-fase com sessões persistentes.
   *(Fonte: `CLAUDE.md:9`; `docs/meta-specs/index.md` §commands.md — "Workflows faseados como invariantes")*

5. **Abstrações devem ser puras — `utils/*` nunca chama `agents/*` ou `commands/*` diretamente.** Toda integração externa (task manager, forge) passa pelo padrão SDAAL: o consumidor chama a interface agnóstica (`taskManager.*`, `forge.*`); o adapter resolve provider, transporte e formatação.
   *(Fonte: `docs/meta-specs/architecture.md:221`; `CLAUDE.md` §Task Manager e §Forge)*

6. **Provider-agnóstico por design, nunca hardcoded.** Antes de operar com tasks ou host remoto, sempre verificar `TASK_MANAGER_PROVIDER`/`FORGE_PROVIDER` em `.env` — nunca inventar valores nem assumir provider ausente.
   *(Fonte: `CLAUDE.md` §Fluxo obrigatório antes de operar com tasks; §Fallback gracioso)*

7. **Idioma segregado por camada.** Chat/comentários/documentação/mensagens ao usuário em português brasileiro; código/variáveis/nomes de arquivo/branch em inglês; commits com **prefixo** Conventional em inglês e **assunto/corpo em pt-BR**; logs/debugging em inglês. Autoridade canônica: skill `language-standards`, alinhada a `docs/meta-specs/code-standards.md`.
   *(Fonte: `CLAUDE.md` §Diretrizes de Linguagem)*

8. **Versão do framework é derivada do git, não semver formal do repo.** Meta-specs têm `version` semver simples no frontmatter; o repo-fonte não carrega stamp de versão committado (evita auto-referência arquivo↔commit); repos **adotados** recebem `.claude/.onion-version` gravado por `/meta:adopt`.
   *(Fonte: `docs/meta-specs/architecture.md:236-256`, §6.1 Versionamento)*

9. **Inventário é SSOT gerada, nunca editada à mão.** Contagens de comandos/agentes/skills/KBs em `CLAUDE.md`, `index.md` e guias **derivam** de `docs/onion/inventory.md`, computado do filesystem por `.claude/validation/inventory.sh` e validado no CI.
   *(Fonte: `docs/onion/inventory.md:1-5`; `CLAUDE.md:9`)*

10. **Dogfood é o padrão master de validação.** Mudanças no core se validam rodando o artefato de verdade — o gate mecânico (`.claude/validation/`: lint + selftest + inventory) é o dogfood determinístico; para o resto, invocar o artefato e observar (fix → re-dogfood no mesmo loop).
    *(Fonte: `CLAUDE.md` §🐕 Evolução do Core — Dogfood é o padrão master; `docs/knowledge-base/concepts/onion-dogfooding-doctrine.md`)*

---

## Nota de aplicabilidade deste documento (Layer 1)

Este arquivo cobre **Vision / Success Criteria / Scope / Stakeholders / Constraints** do template `technical-context-template.md`. Seções condicionais do template (Layer 3: `api-specification.md`, `business-logic.md`) **não se aplicam ao core** — o Onion não expõe API HTTP nem tem lógica de negócio de domínio própria; ele é um framework de orquestração de comandos/agentes consumido dentro do Claude Code. Se necessário no futuro, essas seções cabem melhor documentando **abstrações SDAAL** (Task Manager, Forge) como contrato de interface — não como API REST tradicional.

---

## Referências

- `CLAUDE.md` (raiz do repo) — regras de operação e identidade canônica
- `docs/analysis/onion-review-2026-05.md` — Revisão Analítica de Maio/2026 (decisões de identidade)
- `docs/meta-specs/index.md` e `docs/meta-specs/architecture.md` — constituição L0
- `docs/onion/inventory.md` — SSOT de contagens (comandos/agentes/skills/KBs)
- `docs/knowledge-base/meta/onion-framework-identity.md` — síntese de identidade e produto (materiais externos)
- `README.md` — ponto de entrada e Família Onion
