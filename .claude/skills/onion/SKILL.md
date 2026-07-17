---
description: >
  Orquestrador mestre do Sistema Onion. Use quando o usuário precisar de orientação
  sobre por onde começar, qual comando ou agente usar, como executar um fluxo de trabalho
  (feature, hotfix, PR, documentação, produto, testes), como configurar integrações
  (Jira, ClickUp, Asana, Linear), ou qualquer navegação dentro do framework.
  Ative também quando o usuário perguntar "o que faço agora?", "próximos passos",
  "como funciona o sistema?", "qual agente para X?", "como crio Y?", mesmo sem
  mencionar "onion" explicitamente.
  Ative também quando a mensagem do usuário for essencialmente apenas a palavra
  "onion" ou "Onion" (invocação isolada, como quem digita um comando) — trate como
  pedido de orientação/entrada no sistema. NÃO ative por menções a "onion" dentro
  de frases (nomes de arquivo, docs, código, esta base de código se chama onion),
  apenas pela invocação isolada da palavra.
allowed-tools: Bash(grep * .env) Bash(ls .claude/*) Bash(git branch*)
---

## Estado Atual do Projeto

Provider ativo:
!`grep -E '^TASK_MANAGER_PROVIDER=' .env 2>/dev/null | head -1 || echo "TASK_MANAGER_PROVIDER=não configurado"`

Sessões abertas:
!`ls .claude/sessions/ 2>/dev/null || echo "(nenhuma sessão ativa)"`

Branch atual:
!`git branch --show-current 2>/dev/null || echo "(não é repositório git)"`

---

## Routing por Intenção

### Desenvolvimento de Feature
| Intenção | Comando / Agente |
|----------|-----------------|
| Criar task / planejar feature | `/product/task` |
| Iniciar desenvolvimento | `/engineer/start` |
| Continuar trabalho em feature | `/engineer/work` |
| Preparar PR (lint, testes, review) | `/engineer/pre-pr` |
| Criar Pull Request | `/engineer/pr` |
| Atualizar PR existente | `/engineer/pr-update` |
| Hotfix urgente em produção | `/engineer/hotfix` |
| Bump de versão (semver) | `/engineer/bump` |

**Sequência completa de feature:**
```
/product/task → /engineer/start → /engineer/work → /engineer/pre-pr → /engineer/pr
```

**Sequência de hotfix:**
```
/engineer/hotfix → /engineer/work → /engineer/pr → /git:flow hotfix finish
```

---

### Produto e Discovery
| Intenção | Comando / Agente |
|----------|-----------------|
| Coletar requisitos / ideias | `/product:collect` |
| Refinar requisitos | `/product:refine` |
| Especificação de produto | `/product:spec` |
| Estimar story points | `/product:estimate` |
| Warm-up de produto | `/product/warm-up` |
| Transcrever áudio / reunião | `/product:whisper` |
| Extrair ata de reunião | `/product:extract-meeting` |
| Consolidar múltiplas reuniões | `/product:consolidate-meetings` |
| Converter documento em tasks | `/product:convert-to-tasks` |
| Analisar dor do cliente | `/product:analyze-pain-price` |
| Branding e posicionamento | `/product:branding` |

**Sequência de discovery:**
```
/product:collect → /product:refine → /product:spec → /product/task
```

---

### Documentação
| Intenção | Comando / Agente |
|----------|-----------------|
| Documentação técnica | `/docs:build-tech-docs` |
| Documentação de negócio | `/docs:build-business-docs` |
| Atualizar índice de docs | `/docs:build-index` |
| Engenharia reversa de projeto | `/docs:reverse-consolidate` |
| Validar documentação | `/docs:validate-docs` |
| Diagrama de arquitetura C4 | `@c4-architecture-specialist` |
| Diagrama Mermaid | `@mermaid-specialist` |

**Sequência de documentação:**
```
/docs:build-tech-docs → /docs:build-business-docs → /docs:build-index
```

---

### Criar Componentes do Onion
| Intenção | Comando |
|----------|---------|
| Novo agente especializado | `/meta:create-agent` |
| Novo skill | `/meta:create-skill` |
| Novo comando | `/meta:create-command` |
| Nova knowledge base | `/meta:create-knowledge-base` |
| Configurar integração (task manager, APIs) | `/meta:setup-integration` |
| Análise de problema complexo | `/meta:analyze-complex-problem` |
| Orquestrar subagentes (fan-out paralelo) | `/meta:orchestrate` (skill `onion-orchestration`) |

**Régua de decisão — em qual CAIXA vai um procedimento recorrente?** (a tabela acima dá o comando *se você já sabe a caixa*; isto decide a caixa — antes de criar)
1. **P0 — Já existe?** `grep`/`find` no namespace. Se algo cobre, ou é extensão natural (flag, parâmetro, seção a um SKILL.md) → **EXTEND/FIX, não crie** (anti-proliferação de átomos).
2. **P1 — Determinístico ou juízo?** Output idêntico p/ o mesmo input, sem contexto de sessão (regex, contagem, diff, SSOT) → **script** (`.claude/validation/` p/ guards do CI; `.claude/utils/` p/ helpers reusados). Requer contexto/intenção/trade-off → P2.
3. **P2 — Semântica ou invocação explícita?** Domínio/expertise recorrente → **skill** (SKILL.md <500 linhas + `references/`/`scripts/` sob demanda — progressive disclosure). Ponto de entrada consciente `/nome` com juízo de quando → **comando** fino. Conhecimento de fundo lido pontual (doutrina/ADR) → **KB**. Especialista delegável → **agente** (`.claude/agents/<categoria>/`). Façade multi-provider → **abstração SDAAL** — mas só passando no **Teste do Eixo**: ≥2 implementações **reais** (não prometidas) · escolha do `.env`, não do autor · consumidor **precisa** ser cego. Falhou uma → **script** (P1). 1 provider real + N prometidos = script; o 2º provider real é o gatilho. Critério: [abstraction-doctrine](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md).
4. **P3 — Irreversível?** Muta estado externo sem undo (push --force, deploy, merge de release, bulk task-manager) → **+ gate humano** (camada ORTOGONAL — soma-se a qualquer caixa de P2).

**Combinação canônica** (procedimento completo ≈ combinação, não átomo): script (controle) + comando (juízo) + KB/ADR (doutrina) + gate (se irreversível). Template no core: vertical `co-*` (`co-*.sh` + `co-*.md` + ADR + human-gate). Detalhe: [discovery S1](../../../docs/analysis/onion-toolbox-s1-scoping-2026-06.md).

---

### Orquestração (paralelo)
| Intenção | Comando / Skill |
|----------|-----------------|
| Auditoria/migração/review amplos em paralelo | `/meta:orchestrate` |
| Decompor → delegar → sintetizar/verificar | skill `onion-orchestration` (autora `Workflow`) |
| Doutrina e padrões canônicos | KB `agent-orchestration` |

---

### Auto-Evolução do Framework
| Intenção | Comando / KB |
|----------|--------------|
| "Auditar o Onion", "como melhoro o framework?", "está desatualizado/pesado?" | `/meta:evolve` (orquestração, read-only → backlog priorizado) |
| Qual padrão de refatoração aplicar (consolidar/adapter/KB/skill/fan-out) | KB `onion-modernization-doctrine` |
| Frescor de KBs · conformidade meta-spec | `/meta:kb-freshness` · `/meta:metaspec-validate` (compostos pelo `/meta:evolve`) |

---

### Qualidade e Revisão
| Intenção | Comando / Agente |
|----------|-----------------|
| Code review | `@code-reviewer` |
| Review de branch completa | `@branch-code-reviewer` |
| Testes unitários | `/test:unit` |
| Testes de integração | `/test:integration` |
| Testes E2E | `/test:e2e` |
| Planejamento de testes | `@test-planner` |
| Validar conformidade arquitetural | `@metaspec-gate-keeper` |
| Validar workflow do Onion | `/validate:workflow` |

---

### Git e Versionamento
| Intenção | Comando |
|----------|---------|
| Iniciar feature branch | `/git:flow feature start` |
| Finalizar feature | `/git:flow feature finish` |
| Publicar branch remota | `/git:flow feature publish` |
| Sincronizar com GitFlow | `/git:sync` |
| Iniciar release | `/git:flow release start` |
| Finalizar release | `/git:flow release finish` |
| Commit rápido | `/git:fast-commit` |

---

### Task Managers (Provider-Aware)
| Provider | Agente | Quando usar |
|----------|--------|-------------|
| ClickUp | `@clickup-specialist` | Tasks, listas, custom fields, MCP |
| Jira | `@jira-specialist` | JQL, ADF, transitions, sprints |
| Qualquer / agnóstico | `@task-specialist` | Decomposição sem persistir, Asana, Linear |
| Estratégia / gestão | `@product-agent` | Priorização, roadmap, qualquer provider |

---

### Contexto e Navegação
| Intenção | Comando |
|----------|---------|
| Warm-up geral (sem contexto) | `/warm-up` |
| Warm-up de engenharia | `/engineer/warm-up` |
| Warm-up de produto | `/product/warm-up` |
| Visão geral do sistema | `/onion` |
| Listar todas as ferramentas | `/meta:all-tools` |

---

## Agentes por Categoria

**development/** (20): `@react-developer`, `@nodejs-specialist`, `@clickup-specialist`, `@jira-specialist`, `@claude-code-specialist`, `@c4-architecture-specialist`, `@mermaid-specialist`, `@nx-monorepo-specialist`, `@zen-engine-specialist` e outros. **deployment/** (1): `@docker-specialist`.

**product/** (8): `@product-agent`, `@story-points-framework-specialist`, `@presentation-orchestrator`, `@storytelling-business-specialist`, `@branding-positioning-specialist`, `@extract-meeting-specialist`, `@meeting-consolidator`, `@pain-price-specialist`. (`@whisper-specialist` vive em development/.)

**meta/** (5): `@onion`, `@metaspec-gate-keeper`, `@agent-creator-specialist`, `@command-creator-specialist`, `@agent-skills-specialist`.

**compliance/** (5): `@iso-27001-specialist`, `@iso-22301-specialist`, `@soc2-specialist`, `@pmbok-specialist`, `@security-information-master`. (`@corporate-compliance-specialist` vive em review/.)

**git/** (4): `@branch-code-reviewer`, `@branch-documentation-writer`, `@branch-test-planner`, `@branch-metaspec-checker`.

**testing/** (3): `@test-agent`, `@test-engineer`, `@test-planner`. **review/** (2), **research/** (1), **deployment/** (1).

---

## Gotchas Críticos

**Task Manager Provider obrigatório**
Antes de qualquer operação com tasks: ler `TASK_MANAGER_PROVIDER` no `.env`. Providers válidos: `clickup`, `jira`, `asana`, `linear`, `none`. Se ausente ou inválido: avisar o usuário e sugerir `/meta:setup-integration`. Nunca inventar valores nem assumir outro provider.

**Feature slug: sempre kebab-case**
Correto: `user-authentication`. Errado: `user_authentication`, `UserAuth`, `userAuth`. O slug é usado tanto no nome da branch Git quanto na pasta de sessão `.claude/sessions/<feature-slug>/`.

**Worklog de feature (sessão em arquivo) ≠ transcript nativo**
"Worklog" = a pasta `.claude/sessions/<feature-slug>/` (estado durável em arquivo); "transcript" = a conversa nativa do Claude Code (`claude --resume`). São complementares. Estrutura na SSOT: [gitflow-patterns.md §Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento). Para reportar status ou retomar, leia **só o `STATE.md`** (índice Tier-0 ~1KB), não a pasta inteira — protocolo em [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md). `/engineer/start` cria; `/engineer/work` consome. Verificar se o worklog existe antes de recomendar `/engineer/work`.

**Formatação ClickUp vs Jira**
- ClickUp: descriptions → Markdown nativo; comments → Unicode visual (`━━━`, `▶`, `◆`)
- Jira Cloud REST v3: descriptions e comments → ADF (JSON estruturado obrigatório)
- Jira Server/DC (v2): wiki markup ou plain text

**Como me invocar (sintaxes)**

| Sintaxe | Real? | O que faz |
|---|---|---|
| `/onion` | ✅ | Executa o comando `.claude/commands/onion.md` (ponto de entrada). |
| `onion` / `Onion` no texto | ✅ | Menção em linguagem natural → ativa a **skill** `onion` por match semântico (case-insensitive). |
| `@onion` | ✅ | Delega ao **agente** orquestrador `.claude/agents/meta/onion.md` (subagente). |
| `/Onion` | ❌ | Slash-command é case-sensitive no Linux: não acha `onion.md`. Use `/onion`. |
| `$onion` | ❌ | `$` não é prefixo de invocação (`$ARGUMENTS` só existe dentro de arquivos de comando). |
| `#onion` | ❌ | `#` é atalho de **memória** do Claude Code (anexa ao `CLAUDE.md`); não invoca nada. |

Regra geral: `/nome` → comando/skill · `@nome` → agente · nome no texto → skill por match semântico. `#` e `$` **não** invocam.

**Search Jira 2025**
`GET /rest/api/3/search` foi removido em maio/2025. Usar `POST /rest/api/3/search/jql` com `nextPageToken`.

---

## Referências

- Agente orquestrador completo: `.claude/agents/meta/onion.md`
- Task Manager Abstraction: `docs/knowledge-base/concepts/task-manager-abstraction.md`
- Índice geral: `docs/INDEX.md`
- Guia de comandos: `docs/onion/commands-guide.md`
- Referência de agentes: `docs/onion/agents-reference.md`
