# Template Padrão para Agentes - Sistema Onion v3.0

---

## 📋 Estrutura YAML Obrigatória

```yaml
---
# ═══════════════════════════════════════════════════════════════════════════════
# HEADER OBRIGATÓRIO
# ═══════════════════════════════════════════════════════════════════════════════

name: nome-em-kebab-case
description: |
  Descrição clara em 1-2 linhas do propósito do agente.
  Use para [caso de uso principal]. Relacionado: @agente1, @agente2.
model: sonnet                    # sonnet | opus | haiku | fable
tools:                           # Ferramentas nativas do Claude Code
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - WebSearch
  - TodoWrite

# ═══════════════════════════════════════════════════════════════════════════════
# METADATA
# ═══════════════════════════════════════════════════════════════════════════════

color: purple                    # Cor identificadora (ver tabela abaixo)
priority: alta                   # alta | média | baixa
category: development            # Categoria do agente

# ═══════════════════════════════════════════════════════════════════════════════
# RELACIONAMENTOS
# ═══════════════════════════════════════════════════════════════════════════════

expertise:                       # 3-5 áreas de especialização
  - area-1
  - area-2
  - area-3

related_agents:                  # Agentes que colaboram
  - agente-1
  - agente-2

related_commands:                # Comandos relacionados
  - /categoria/comando

# ═══════════════════════════════════════════════════════════════════════════════
# VERSIONAMENTO
# ═══════════════════════════════════════════════════════════════════════════════

version: "1.0.0"
updated: "2025-11-24"
---
```

---

## 📊 Tabela de Campos

### Campos Obrigatórios

| Campo | Tipo | Descrição | Exemplo |
|-------|------|-----------|---------|
| `name` | string | Identificador único kebab-case | `code-reviewer` |
| `description` | string | Descrição em 1-2 linhas | `Especialista em revisão...` |
| `model` | enum | Modelo de IA | `sonnet`, `opus`, `haiku`, `fable` |
| `tools` | array | Ferramentas disponíveis | `[Read, Write, Edit, ...]` |
| `version` | semver | Versão do agente | `"1.0.0"` |
| `updated` | date | Data da última atualização | `"2025-11-24"` |

### Campos Opcionais

| Campo | Tipo | Descrição | Default |
|-------|------|-----------|---------|
| `color` | string | Cor para UI | `purple` |
| `priority` | enum | Prioridade | `média` |
| `category` | string | Categoria | inferido da pasta |
| `expertise` | array | Áreas de expertise | `[]` |
| `related_agents` | array | Agentes relacionados | `[]` |
| `related_commands` | array | Comandos relacionados | `[]` |

### Model tiering em orquestração

Ao orquestrar workers (fan-out via ferramenta Workflow nativa), distribua tiers:
o orquestrador roda em `opus`; workers de alto volume e baixa complexidade vão
para `sonnet` ou `haiku`. Em caso de dúvida, **herde do parent** omitindo o campo
`model`. Esse tiering reduz custo agregado em fan-out, onde dezenas de subagentes
executam em paralelo.

---

## 🎨 Tabela de Cores

| Categoria | Cor | Hex |
|-----------|-----|-----|
| development | `blue` | #4466ff |
| product | `purple` | #9c27b0 |
| review | `orange` | #ff9800 |
| testing | `green` | #4caf50 |
| compliance | `red` | #f44336 |
| meta | `cyan` | #00bcd4 |
| git | `teal` | #009688 |
| research | `indigo` | #3f51b5 |
| deployment | `brown` | #795548 |

---

## 🛠️ Ferramentas Padrão

### Ferramentas Genéricas (Todos os Agentes)

```yaml
tools:
  - Read         # Ler arquivos
  - Write        # Escrever arquivos
  - Edit         # Editar arquivos
  - Grep         # Busca por padrão / conteúdo
  - Glob         # Listar e buscar arquivos por glob
  - Bash         # Executar comandos
  - WebSearch    # Pesquisa web
  - TodoWrite    # Gerenciar TODOs
```

### Ferramentas por Especialidade

| Especialidade | Ferramentas Adicionais |
|---------------|------------------------|
| Code Review | (apenas genéricas — lint via `Bash`) |
| Testes | (apenas genéricas) |
| Documentação | (apenas genéricas) |

### ⚠️ MCPs - Regra de Ouro

**Agentes Agnósticos** (maioria):
- Usar APENAS ferramentas genéricas
- MCPs listados em seção "Integrações Opcionais"

**Agentes Especializados** (exceções):
- `clickup-specialist` → API-first (`Bash`/`WebFetch` p/ REST); MCP é transporte opcional via adapter
- Outros especialistas MCP → incluem seus MCPs

---

## 📝 Estrutura do Corpo do Agente

```markdown
# Nome do Agente

## 🎯 Identidade e Propósito

Você é o **@nome-do-agente**, especialista em [área].

### Missão
[Descrição da missão principal]

### Princípios
- Princípio 1
- Princípio 2
- Princípio 3

## 🔧 Configurações Necessárias
<!-- APENAS para agentes especializados (com MCPs) -->

Este agente requer as seguintes variáveis de ambiente:

| Variável | Obrigatória | Descrição | Como Obter |
|----------|-------------|-----------|------------|
| `VAR_NAME` | ✅ | Descrição | [Link](url) |

## 🔌 Integrações Opcionais
<!-- APENAS para agentes agnósticos (sem adapter dedicado) -->

Este agente integra serviços externos via **abstração API-first** (Task Manager / Forge); o MCP é
**transporte opcional** resolvido pelo adapter (`TASK_MANAGER_TRANSPORT=mcp`), **nunca** chamado direto:

| Integração | Acesso (API-first) | Uso |
|-----|-------------|-----|
| ClickUp | adapter `taskManager.*` (REST default; MCP opcional via `TASK_MANAGER_TRANSPORT`) | Gestão de tasks |

Consulte `docs/knowledge-base/concepts/configuration-management.md` para setup.

## 📋 Protocolo de Operação

### Fase 1: [Nome da Fase]
1. Passo 1
2. Passo 2

### Fase 2: [Nome da Fase]
1. Passo 1
2. Passo 2

### Fase 3: [Nome da Fase]
1. Passo 1
2. Passo 2

## 💡 Guidelines

### ✅ Fazer
- Ação recomendada 1
- Ação recomendada 2

### ❌ Evitar
- Anti-pattern 1
- Anti-pattern 2

## 🔗 Referências

- Agente relacionado: @outro-agente
- Comando relacionado: /categoria/comando
- KB: docs/knowledge-base/concepts/relevant-kb.md
```

---

## 🔄 Checklist de Validação

### Header YAML
- [ ] `name` único e em kebab-case
- [ ] `description` clara em 1-2 linhas
- [ ] `model` definido (sonnet/opus/haiku/fable)
- [ ] `tools` apenas genéricas (exceto especializados)
- [ ] `version` em formato semver
- [ ] `updated` com data atual

### Corpo
- [ ] Seção "Identidade e Propósito"
- [ ] Seção "Protocolo de Operação" com fases
- [ ] Seção "Guidelines" com ✅ e ❌
- [ ] Seção "Configurações" OU "Integrações Opcionais"

### Relacionamentos
- [ ] `related_agents` aponta para agentes existentes
- [ ] `related_commands` aponta para comandos existentes
- [ ] `expertise` com 3-5 áreas relevantes

---

## 📚 Exemplos

### Exemplo 1: Agente Agnóstico

```yaml
---
name: code-reviewer
description: |
  Especialista em revisão de código focado em qualidade, segurança e padrões.
  Use para reviews de PRs, validação de código e identificação de problemas.
model: opus
tools:
  - Read
  - Grep
  - Bash
  - TodoWrite

color: orange
priority: alta
category: review

expertise:
  - code-review
  - security
  - best-practices
  - typescript
  - react

related_agents:
  - test-engineer
  - metaspec-gate-keeper

related_commands:
  - /engineer/pr
  - /git/code-review

version: "3.0.0"
updated: "2025-11-24"
---

# Code Reviewer

## 🎯 Identidade e Propósito
[...]

## 🔌 Integrações Opcionais
[...]

## 📋 Protocolo de Operação
[...]
```

### Exemplo 2: Agente Especializado

```yaml
---
name: clickup-specialist
description: |
  Especialista em ClickUp (API-first; MCP opcional) para otimizações técnicas e operações em bulk.
  Use para operações avançadas no ClickUp, automações e integrações.
model: sonnet
tools:
  - Read
  - Write
  - Edit
  - Grep
  - WebSearch
  - WebFetch
  - TodoWrite
  - Bash        # REST da ClickUp API (curl) — API-first; MCP é transporte OPCIONAL via adapter

color: orange
priority: alta
category: development

expertise:
  - clickup-api
  - task-management
  - automation
  - bulk-operations

related_agents:
  - task-specialist
  - product-agent

related_commands:
  - /product/task
  - /product/check

version: "3.0.0"
updated: "2025-11-24"
---

# ClickUp Specialist

## 🎯 Identidade e Propósito
[...]

## 🔧 Configurações Necessárias

| Variável | Obrigatória | Descrição | Como Obter |
|----------|-------------|-----------|------------|
| `CLICKUP_API_TOKEN` | ✅ | Token de API | [ClickUp Settings](https://app.clickup.com/settings/apps) |
| `CLICKUP_WORKSPACE_ID` | ✅ | ID do workspace | URL do ClickUp |

## 📋 Protocolo de Operação
[...]
```

---

**Versão**: 3.0.0
**Atualizado**: 2025-11-24
**Responsável**: Sistema Onion

