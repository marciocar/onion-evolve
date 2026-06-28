---
title: Padrões de Criação de Comandos Claude Code
category: meta
tags:
  - claude-code-commands
  - command-patterns
  - templates
  - anti-patterns
  - best-practices
status: reference
date: 2026-06-02
---

# Padrões de Criação de Comandos Claude Code

> **Catálogo de referência** consumido pelo `@command-creator-specialist` (`.claude/agents/meta/command-creator-specialist.md`).
> O agente mantém a **lógica de orquestração** (FASES 1-6, Filosofia Core) inline e **referencia este documento** para templates por categoria, anti-patterns, best practices e templates rápidos.
> Ao criar um comando, o agente deve **ler este KB** para aplicar os padrões adequados.

---

## 🧩 Frontmatter de comando (campos)

Todo comando criado deve ter frontmatter YAML. Campos:

- `description` (**obrigatório**) — uma linha; aparece na lista de comandos.
- `model` — ex.: `sonnet`.
- `category` + `tags` — categorização.
- `allowed-tools` (**recomendado para comandos sensíveis**) — escopo mínimo de
  ferramentas (git, escrita, Task Manager). Convenção e exemplos em
  `docs/meta-specs/commands.md §1.3`. Ex.:
  `allowed-tools: Bash(git *) Read Edit Write Grep Glob`.
- `argument-hint` (opcional) — hint sobre argumentos esperados.

> Comandos puramente informativos (READMEs, ajuda) podem omitir `allowed-tools`.

---

## 🎯 Categorias de Comandos e Padrões

### 📁 meta/ - Meta-Operações

**Propósito:** Comandos que manipulam o próprio sistema de comandos e agentes

**Padrões:**
- Geralmente invocam agentes meta (`@agent-creator-specialist`, `@command-creator-specialist`)
- Complexidade média a alta
- Requerem diálogo com usuário
- Geram artefatos (.md files)

**Exemplos:**
- `/meta/create-agent` - Criar novo agente
- `/meta/create-command` - Criar novo comando
- `/meta/update-docs` - Atualizar documentação do sistema

**Template:**
```markdown
# Meta [Operação]

Comando meta que [ação] do sistema.

## Execução

**Agente:** @[meta-agent]

**Instruções:**
```
[Tarefa meta com parâmetros específicos]
```
```

---

### 🔧 engineer/ - Engineering Workflows

**Propósito:** Comandos para workflows de desenvolvimento (start, work, pr, etc.)

**Padrões:**
- Integram com o task manager ativo via abstração `TASK_MANAGER_PROVIDER` (o adapter resolve Jira/ClickUp/Asana/Linear; nunca chamam a API/MCP do provider direto)
- Gerenciam sessions (.claude/sessions/)
- Coordenam múltiplos agentes — quando as subtarefas são **independentes**, use a camada de orquestração (fan-out/fan-in) sobre a ferramenta nativa **Workflow**; ver `docs/knowledge-base/concepts/agent-orchestration.md` e o comando `/meta:orchestrate`
- Workflows complexos e iterativos

**Exemplos:**
- `/engineer/start` - Iniciar desenvolvimento
- `/engineer/work` - Trabalhar em feature
- `/engineer/pr` - Criar pull request
- `/engineer/docs` - Gerar documentação

**Template:**
```markdown
# Engineer [Operação]

Comando de engenharia para [propósito].

## Configuração

### Validar Branch
```bash
CURRENT_BRANCH=$(git branch --show-current)
[validações]
```

### Verificar Task (provider-agnóstico)
```bash
set -a; source .env; set +a                       # carrega TASK_MANAGER_PROVIDER
TASK_ID=$(taskManager_get_task_id_from_session)    # abstração resolve o provider ativo
[validações]
```

## Execução

### Step 1: Análise
**Agente:** @research-agent
[instruções]

### Step 2: Implementação
**Agente:** @[dev-agent]
[instruções]

### Step 3: Validação
**Agente:** @code-reviewer
[instruções]
```

---

### 📋 product/ - Product Management

**Propósito:** Comandos para gestão de produto e criação de tasks

**Padrões:**
- Operam sobre o task manager ativo (via `TASK_MANAGER_PROVIDER`; delegam ao `@task-specialist` ou ao especialista do provider, nunca à API/MCP direta)
- Criam/atualizam tasks, checklists, subtasks
- Invocam `@product-agent` ou `@task-specialist`
- Workflows de decomposição e especificação

**Exemplos:**
- `/product/task` - Criar task com decomposição
- `/product/spec` - Especificar funcionalidade
- `/product/feature` - Planejar feature completa
- `/product/refine` - Refinar requisitos

**Template:**
```markdown
# Product [Operação]

Comando de gestão de produto para [propósito].

## Análise

**Questões a esclarecer:**
- [Pergunta 1]
- [Pergunta 2]

## Execução

### Step 1: Decomposição
**Agente:** @task-specialist
```
Decomponha [funcionalidade] em:
- Tasks principais
- Subtasks
- Checklists
```

### Step 2: Criação no task manager ativo
```bash
# Criar task principal via abstração agnóstica (o adapter resolve o provider do .env)
TASK_ID=$(taskManager_create_task "$TASK_NAME")

# Criar subtasks
[lógica de criação]
```
```

---

### 🌿 git/ - Git Flow Operations

**Propósito:** Comandos para operações Git Flow (features, releases, hotfixes)

**Padrões:**
- Invocam `@gitflow-specialist`
- Validam estado do repositório
- Operações de branch management
- Integram com o task manager ativo via abstração (`TASK_MANAGER_PROVIDER`), quando aplicável

**Exemplos:**
- `/git/init` - Inicializar Git Flow
- `/git:flow feature start` - Iniciar feature branch
- `/git:flow feature finish` - Finalizar feature
- `/git:flow hotfix start` - Iniciar hotfix

**Template:**
```markdown
# Git [Operação]

Comando Git Flow para [propósito].

## Configuração

### Validar Repositório
```bash
# Verificar se é repositório Git
[validações]
```

## Execução

**Agente:** @gitflow-specialist

**Instruções:**
```
Execute [operação Git Flow]:
- Branch: [nome]
- Base: [base]
- Validações: [lista]
```

## Validações

- [ ] Branch criada corretamente
- [ ] Sem conflitos
- [ ] Working directory limpo
```

---

### 📜 compliance/ - Compliance & Audit

**Propósito:** Comandos para geração de documentação de conformidade

**Padrões:**
- Invocam agentes de compliance específicos
- Geram documentação estruturada
- Seguem frameworks (ISO, SOC2, etc.)
- Output em docs/compliance-context/

**Exemplos:**
- `/compliance/audit/iso27001` - Gerar docs ISO 27001
- `/compliance/audit/soc2` - Gerar docs SOC2
- `/compliance/generate/policies` - Gerar políticas

**Template:**
```markdown
# Compliance [Operação]

Comando de conformidade para [framework/padrão].

## Execução

**Agente:** @[compliance-agent]

**Instruções:**
```
Gere documentação de [framework]:
- Standard: [ISO/SOC2/etc]
- Escopo: [descrição]
- Output: docs/compliance-context/[categoria]/
```

## Validações

- [ ] Documentos gerados corretamente
- [ ] Formato audit-ready
- [ ] Cross-references completos
```

---

### 📚 docs/ - Documentation Generation

**Propósito:** Comandos para geração e atualização de documentação

**Padrões:**
- Invocam agentes de documentação
- Geram markdown estruturado
- Atualizam índices e referências
- Output em docs/

**Exemplos:**
- `/docs/generate/api` - Gerar docs de API
- `/docs/update/index` - Atualizar INDEX.md
- `/docs/diagram/c4` - Gerar diagramas C4

**Template:**
```markdown
# Docs [Operação]

Comando de documentação para [propósito].

## Execução

**Agente:** @[docs-agent]

**Instruções:**
```
Gere/atualize documentação:
- Tipo: [API/Arquitetura/etc]
- Formato: [Markdown/Diagram]
- Output: [caminho]
```
```

---

## 🚫 Anti-Patterns (O Que Evitar)

### ❌ Anti-Pattern 1: Comando Genérico Demais

```markdown
# RUIM
# Do Stuff

Faz várias coisas úteis.
```

**Por quê:** Não tem workflow claro, propósito vago
**Correto:** Definir workflow específico e acionável

### ❌ Anti-Pattern 2: Duplicação de Funcionalidades

```markdown
# RUIM - já existe /engineer/start
# Start Development

Inicia desenvolvimento de feature...
```

**Por quê:** Duplica comando existente
**Correto:** Estender comando existente ou criar sub-comando especializado

### ❌ Anti-Pattern 3: Confusão Terminal vs Claude Code Command

```markdown
# RUIM
## Uso

No terminal:
```bash
$ /engineer/work
```
```

**Por quê:** Claude Code Commands NÃO são executados no terminal
**Correto:** Sempre especificar "No chat da Claude Code"

### ❌ Anti-Pattern 4: Instruções Vagas para Agentes

```markdown
# RUIM
**Agente:** @code-reviewer

**Instruções:**
```
Revise o código
```
```

**Por quê:** Falta contexto e especificidade
**Correto:** Instruções detalhadas com parâmetros claros

### ❌ Anti-Pattern 5: Falta de Validações

```markdown
# RUIM
## Execução

[comandos bash sem verificações]
```

**Por quê:** Erros não são tratados
**Correto:** Validações entre steps, tratamento de erros

### ❌ Anti-Pattern 6: Ausência de Exemplos

**Por quê:** Usuários não sabem como invocar
**Correto:** Mínimo 2 exemplos práticos

### ❌ Anti-Pattern 7: Workflow Não-Acionável

```markdown
# RUIM
## Execução

Faça análise e implemente solução.
```

**Por quê:** Instruções não são executáveis
**Correto:** Steps específicos com ações claras

---

## 💡 Best Practices

### ✅ 1. Commands Discovery First

**SEMPRE** começe descobrindo comandos existentes:
- Listar por categoria
- Ler comandos similares
- Identificar padrões
- Validar não-duplicação

### ✅ 2. Dialogue Before Creating

**SEMPRE** dialogue com usuário:
- Confirme workflow proposto
- Valide categoria
- Esclareça integrações
- Obtenha aprovação

### ✅ 3. Clear Agent Instructions

Instruções para agentes devem:
- Ter contexto completo
- Especificar parâmetros
- Definir formato de resposta
- Incluir critérios de sucesso

### ✅ 4. Integration by Design

**TODO** comando deve saber:
- Quais agentes invocar
- Quais serviços integrar (task manager ativo, Git)
- Quais comandos são relacionados
- Quando delegar vs. executar

### ✅ 5. Executable Workflows

**WORKFLOWS** devem ser acionáveis:
- Steps sequenciais e claros
- Validações entre steps
- Tratamento de erros
- Checkpoints de confirmação

### ✅ 6. Examples Are Essential

**EXEMPLOS** são obrigatórios:
- Mínimo 2 exemplos práticos
- Cobrir casos comuns e avançados
- Mostrar input + workflow + output
- Demonstrar invocação correta

### ✅ 7. Quality Checklist Mandatory

**VALIDAÇÃO** não é opcional:
- Checklist completo antes de finalizar
- Teste de invocação no chat Claude Code
- Documentação de integração
- Aprovação de qualidade

### ✅ 8. Claude Code Commands Clarity

**SEMPRE** deixar claro:
- Comandos são executados no chat
- NÃO são comandos de terminal
- Usar formato `/categoria/comando`
- Incluir exemplos de invocação

---

## 🎨 Templates Rápidos por Tipo

### Template 1: Comando Simples (Delegação a Agente)

```markdown
# [Título do Comando]

[Descrição simples]

## Quando Usar

✅ Use quando: [situação]
❌ NÃO use quando: [situação - usar outro comando]

## Execução

**Agente:** @[nome-agente]

**Instruções:**
```
[Tarefa específica com parâmetros]
```

## Próximos Passos

- `/comando-relacionado` - [quando usar]
```

### Template 2: Comando Médio (Workflow + Agente)

```markdown
# [Título do Comando]

[Descrição]

## Configuração

```bash
# Validações iniciais
[código]
```

## Execução

### Step 1: Setup
[ações iniciais]

### Step 2: Processamento
**Agente:** @[agente]
```
[instruções]
```

### Step 3: Finalização
[ações finais]

## Validações

- [ ] [Checkpoint 1]
- [ ] [Checkpoint 2]
```

### Template 3: Comando Complexo (Orquestração)

```markdown
# [Título do Comando]

[Descrição completa]

## Análise

**Questões:**
- [Pergunta 1]
- [Pergunta 2]

## Execução

### Step 1: Análise
**Agente:** @research-agent
[instruções]

### Step 2: Design
**Agente:** @architect-agent
[instruções]

### Step 3: Implementação
**Agente:** @dev-agent
[instruções]

### Step 4: Validação
**Agente:** @reviewer-agent
[instruções]

## Integração com Task Manager

[lógica de integração — via abstração `taskManager.*`; o adapter resolve o provider ativo]

## Documentação

[o que documentar]
```
