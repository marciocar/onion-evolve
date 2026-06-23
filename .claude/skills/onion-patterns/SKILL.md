---
description: >
  Padrões de nomenclatura, estrutura e convenções do Sistema Onion. Use ao
  criar ou editar comandos, agentes, skills, sessions ou qualquer artefato em
  `.claude/`. Cobre estrutura de diretórios, kebab-case slugs, YAML headers
  obrigatórios, limites de linhas, formatação de comments ClickUp e fluxos
  principais. Ative mesmo sem o usuário mencionar "padrão" explicitamente.
paths: [".claude/**", "docs/onion/**"]
---

## Estrutura de Diretórios

### `.claude/commands/` (comandos invocáveis em 9 categorias + root; contagem canônica em `docs/INDEX.md`)
```
.claude/commands/
├── engineer/        # Fluxos de desenvolvimento
├── product/         # Gestão de produto e descoberta
├── git/             # GitFlow (feature/, hotfix/, release/)
├── docs/            # Documentação técnica e business
├── meta/            # Meta-comandos (criar agente, skill, command)
├── validate/        # Validações (test-strategy/, qa-points/, collab/)
├── test/            # Test unit, integration, e2e
├── common/          # Templates e prompts compartilhados
├── development/     # Comandos de desenvolvimento (runflow-dev)
└── quick/           # Ações rápidas
```

### `.claude/agents/` (50 agentes em 9 categorias)
```
.claude/agents/
├── development/     # 20 — React, Node, Jira, ClickUp, infra
├── product/         # 8 — product-agent, whisper, branding, etc.
├── meta/            # 5 — onion, agent-creator, skills-creator, etc.
├── compliance/      # 5 — ISO 27001/22301, SOC2, PMBOK
├── git/             # 4 — branch reviewers
├── testing/         # 3 — test-agent, test-engineer, test-planner
├── review/          # 2 — code-reviewer, compliance-reviewer
├── research/        # 1 — research-agent
└── deployment/      # 1 — docker-specialist
```

### `.claude/skills/<nome>/`
Cada skill em pasta própria com `SKILL.md`. Opcionalmente:
- `scripts/` — código executável (Python/Bash)
- `references/` — docs adicionais carregadas sob demanda
- `examples/` — exemplos de output

### `.claude/sessions/<feature-slug>/` (worklog)
Estrutura definida pela **SSOT** — não redefina aqui: [gitflow-patterns.md §Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento). Worklog ACTIVE = `STATE.md` (índice Tier-0, ponto de resume) + `context.md` (+ Phase-Subtask Mapping) + `architecture.md` + `plan.md` + `notes.md`. Mecânica de leitura/resume: [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md).

## Nomenclatura

### Feature slugs — kebab-case obrigatório
```
✅ user-authentication
✅ payment-integration
✅ onion-v3-refactoring

❌ UserAuth          (PascalCase)
❌ payment_integration (snake_case)
❌ feature123          (não descritivo)
```

### Comandos
- Arquivo: `nome-comando.md` em kebab-case
- Caminho de invocação: `/categoria/nome-comando` ou `/categoria:subcategoria:nome`
- Ex: `/engineer/start`, `/product/task`, `/git:flow feature start`, `/meta:create-skill`

### Agentes
- Arquivo: `nome-especialista.md` em kebab-case
- Referência inline: `@nome-especialista` (sem extensão)
- Ex: `@react-developer`, `@jira-specialist`, `@onion`

### Skills
- Pasta: `nome-skill/SKILL.md` em kebab-case
- Invocação: `/nome-skill` (Claude Code mescla skills e commands)

## YAML Headers Obrigatórios

### Comando (`.claude/commands/*.md`)
```yaml
---
name: nome-comando
description: Descrição curta (1-2 linhas)
model: sonnet
category: engineer|product|git|docs|meta|validate|quick|test|common|development
tags: [tag1, tag2, tag3]
version: "3.0.0"
updated: "YYYY-MM-DD"
---
```

### Agente (`.claude/agents/<categoria>/*.md`)
```yaml
---
name: nome-agente
description: Descrição da especialização
model: sonnet|opus|haiku
category: development|product|meta|compliance|review|testing|research|git|deployment
tags: [tag1, tag2]
expertise: [area1, area2, area3]
version: "3.0.0"
updated: "YYYY-MM-DD"
---
```

### Skill (`.claude/skills/<nome>/SKILL.md`)
```yaml
---
description: >
  [Verbo imperativo] [o que faz]. Use quando [contexto explícito],
  mesmo que o usuário não mencione [keyword] diretamente.
paths: ["glob/opcional"]  # opcional, ativa só com arquivos matching
allowed-tools: Tool1 Tool2(arg*)  # opcional, escopo mínimo
---
```

## Limites e Métricas

| Métrica | Limite | Razão |
|---------|--------|-------|
| Comando | < 400 linhas | Otimização de tokens |
| Agente | < 300 linhas | Foco e clareza |
| Skill | < 500 linhas | Lifecycle persistente em contexto |
| Expertise/agente | 3-5 áreas | Especialização real |
| Tags/arquivo | 3-7 | Organização sem ruído |
| Description em skill | < 1024 chars | Trigger budget |

## Formatação por Provider (ClickUp)

Quando `TASK_MANAGER_PROVIDER=clickup`, comments seguem padrão visual Unicode:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ FASE N CONCLUÍDA — Nome da Fase
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 YYYY-MM-DD | Status: DONE

📊 Resultados:
∟ Item 1: valor
∟ Item 2: valor

🚀 Próxima: Fase N+1 — Nome
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Regras**:
- **Subtask**: comentário **detalhado** (métricas, arquivos, decisões)
- **Task principal**: comentário **resumido** (fase, status, próximo)
- Sempre incluir **timestamp** e **status**

Para Jira (`TASK_MANAGER_PROVIDER=jira`), usar **ADF** (JSON estruturado) — não Markdown nem Unicode.

## Fluxos Principais

### Feature Development
```
/product/task "descrição" → /engineer/start <slug> → /engineer/work → /engineer/pre-pr → /engineer/pr
```

### Hotfix
```
/engineer/hotfix → /engineer/work → /engineer/pr → /git:flow hotfix finish
```

### Criação de componentes Onion
```
/meta:create-agent      # novo agente especializado
/meta:create-skill      # nova skill
/meta:create-command    # novo comando
/meta:create-knowledge-base  # nova KB em docs/knowledge-base/
```

## Gotchas

- **Feature slug com underscore quebra GitFlow**: branches Git e pastas de sessão usam o mesmo slug — kebab-case é obrigatório
- **Categoria inválida derruba o gate-keeper**: `@metaspec-gate-keeper` valida `category` no YAML header
- **Tag count fora de 3-7 reduz searchability**: muitas tags poluem, poucas não cobrem
- **YAML sem `updated` impede tracking**: sempre incluir data ISO

## Referências

- Knowledge Base: `docs/knowledge-base/concepts/task-manager-abstraction.md`
- Templates: `.claude/commands/common/templates/`
- Skill relacionada: `language-standards` (idioma e docs)
- Skill relacionada: `onion-validation` (regras de validação)
- Agente: `@metaspec-gate-keeper` (valida conformidade)
