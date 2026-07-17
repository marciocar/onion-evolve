---
name: task
description: |
  Criação de tasks com decomposição hierárquica inteligente.
  Use para criar tasks estruturadas com subtasks e action items.
  Suporta: Jira, ClickUp, Asana, Linear (via TASK_MANAGER_PROVIDER).
  Diferença vs /product:create-task-structure: este PERSISTE no task manager ativo; o create-task-structure é decomposição LOCAL read-only (saída textual, não grava).
model: sonnet
allowed-tools: Bash(cat .env*) Read Write Grep Glob
parameters:
  - name: description
    description: Descrição da task
    required: true
  - name: project_name
    description: Nome do projeto/lista (opcional)
    required: false

category: product
tags:
  - task
  - task-manager
  - decomposition

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /product/spec
  - /product/estimate
  - /engineer/start

related_agents:
  - task-specialist
  - product-agent
  - story-points-framework-specialist
---

# 🚀 Criação de Task com Decomposição

Criar tasks estruturadas no gerenciador de tarefas configurado, com decomposição
hierárquica **Task → Subtask → Action Item** e story points automáticos.

## 🎯 Objetivo

Estabelecer base sólida para desenvolvimento, registrando intenção no Task Manager
antes de qualquer execução, com plano confirmado pelo usuário.

## 🚨 PASSO 0 (OBRIGATÓRIO): Detectar Provedor

Detectar e validar o provedor ativo **antes de qualquer ação**, seguindo o
fragmento canônico `common:prompts:task-manager-provider-detection`: ler `.env`,
validar a variável obrigatória do provedor e aplicar o fallback gracioso em
modo offline.

## ⚡ Fluxo de Execução

### Passo 1: Resolver Projeto/Lista

```markdown
SE project_name fornecido:
  - Buscar o projeto/lista pelo nome via `taskManager.getProjectList()` (o adapter resolve por provedor)
  - Se não encontrado: perguntar ao usuário
SE project_name NÃO fornecido:
  - Usar default do .env (CLICKUP_DEFAULT_LIST_ID / ASANA_DEFAULT_PROJECT_ID / LINEAR_TEAM_ID)
  - Se não configurado: listar opções e perguntar
```

> Mapeamento de IDs por provedor: `.claude/utils/task-manager/adapters/{provedor}.md`.

### Passo 2: Análise de Contexto e Compreensão

**SEMPRE siga esta sequência antes de decompor:**

1. **Revisar documentação do projeto** (`README.md`, arquivos em `docs/`) para
   identificar padrões, tecnologias e estrutura existentes.
2. **Ler cuidadosamente** a descrição: `{{description}}`.
3. **Formular perguntas internas** para resolver ambiguidades e entender como a
   tarefa se encaixa na estrutura existente.
4. **Classificar complexidade** (define a granularidade da decomposição):

   | Tipo | Duração | Subtasks | Action Items/Subtask |
   |------|---------|----------|---------------------|
   | Simples | 1-3d | 2-3 | 2-3 |
   | Média | 4-7d | 3-4 | 3-4 |
   | Complexa | 1-2sem | 4-6 | 3-5 |
   | Épico | >2sem | Quebrar em múltiplas tasks | — |

### Passo 3: Decompor Hierarquicamente

Consultar `@task-specialist` para a estrutura. Cada action item deve caber em **1-4h**:

```
📋 TASK (Objetivo de Alto Nível)
├── 🔧 Subtask 1 (Componente Funcional)
│   ├── ✅ Action Item 1.1 (1-4h)
│   ├── ✅ Action Item 1.2 (1-4h)
│   └── ✅ Action Item 1.3 (1-4h)
└── 🔧 Subtask 2 (Componente Funcional)
    ├── ✅ Action Item 2.1 (1-4h)
    └── ✅ Action Item 2.2 (1-4h)
```

### Passo 4: Estimar Story Points (Automático)

Após decompor, **SEMPRE** estimar via `@story-points-framework-specialist`:

1. **Task principal** — passar descrição, lista de subtasks e complexidade inicial.
   Obter: story points, análise de complexidade/risco/incerteza e recomendações.
2. **Cada subtask** — passar nome, descrição e action items. Obter story points e
   armazenar o total (soma das subtasks).
3. **Validar consistência:**
   - Se `soma(subtasks) > task_principal` → ajustar task principal para a soma.
   - Se `task_principal > 13 pontos` → alertar **ÉPICO** e propor quebra em tasks menores.

> Framework: `docs/knowledge-base/frameworks/framework-story-points.md`.

### Passo 5: Apresentar Plano e Obter Confirmação (OBRIGATÓRIO ANTES DE CRIAR)

**⚠️ CRÍTICO: NUNCA criar task sem apresentar plano e obter confirmação explícita.**

```markdown
## 🎯 PLANO DE TASK PROPOSTO

### 📋 Task Principal
**Nome**: [NOME] | **Tipo**: [Feature/Bug/Improvement/Research]
**Complexidade**: [Simples/Média/Alta] | **Estimativa**: [TEMPO] | **Story Points**: [X]

### 📝 Descrição Funcional
[OBJETIVO CLARO]

### 🏗️ Arquitetura Técnica
[DETALHAMENTO TÉCNICO E IMPLEMENTAÇÃO]

### 📚 Bibliotecas/Dependências Sugeridas
[LISTA, PRIORIZANDO CONHECIDAS DO PROJETO]

### 🔧 Componentes Afetados
[COMPONENTES MODIFICADOS]

### 🔧 Decomposição
├── Subtask 1: [nome] — [X] pts
└── Subtask 2: [nome] — [Y] pts

### ✅ Critérios de Aceitação
- [ ] [CRITÉRIO_1]
- [ ] [CRITÉRIO_2]

### 🧪 Pontos de Atenção para Teste
[ESTRATÉGIA DE TESTES]

❓ **Este plano está correto? Posso criar a task no Task Manager?** [Y/n]
```

- **AGUARDAR confirmação explícita** — não criar nada até receber.
- Se o usuário pedir ajustes, revisar e reapresentar o plano.

### Passo 6: Criar no Gerenciador (APÓS CONFIRMAÇÃO)

**🚨 ORDEM CRÍTICA — sempre nesta sequência:**
1. **PRIMEIRO** criar a task no Task Manager (registrar o que VAI ser feito).
2. **DEPOIS** executar o trabalho, se a task envolver ação imediata (Passo 7).
3. **POR ÚLTIMO** atualizar a task com o resultado (Passo 8).

**❌ NUNCA** executar trabalho antes de criar a task, nem criar a task após o trabalho já estar feito.

#### 6.1. Preparar dados normalizados

Seguir a interface `ITaskManager` (entrada/saída padronizadas, priority
`urgent|high|normal|low`). O adapter resolve o transporte (REST default; MCP opcional); normalizar os dados antes de chamá-lo.

```markdown
Task Principal:
- name: "{{description}}"
- markdownDescription: [objetivo + critérios + story points]
- priority: 'high' | tags: ['feature'] | projectId: [resolvido no Passo 1]

Cada Subtask:
- name / markdownDescription (+ story points) / priority (herdar ou 'normal') / tags
```

> Formato completo de entrada/saída: `.claude/utils/task-manager/interface.md`.

#### 6.2. Criar task principal, subtasks e comentário (via Task Manager Adapter)

Chamar a abstração agnóstica (`taskManager.createTask(...)`, `createSubtask`, `addComment`); o
adapter resolve o transporte (REST default; MCP opcional via `TASK_MANAGER_TRANSPORT`). **Os
mapeamentos exatos de campos, nomes de ferramentas, conversão de markdown e construção de URL
estão nos adapters — NÃO duplicar aqui:**

- ClickUp → `.claude/utils/task-manager/adapters/clickup.md`
- Asana → `.claude/utils/task-manager/adapters/asana.md`
- Linear → `.claude/utils/task-manager/adapters/linear.md`

Sequência (idêntica em todos os provedores, variando só o adapter):
1. **Criar task principal** → extrair `id`/`gid` e `url`.
2. **Criar cada subtask** com `parent` = id da task principal.
3. **Adicionar comentário inicial** com o resumo de estimativas (template abaixo).

**Comentário inicial (formatação visual):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 TASK CRIADA VIA /product/task
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 COMPLEXIDADE: ${complexity}
🎲 STORY POINTS:
∟ Task Principal: ${mainTaskStoryPoints} pontos
∟ Subtasks: ${subtasksPoints} pontos (${subtasks.length} subtasks)
∟ Total: ${totalPoints} pontos
⚡ FATORES: ${factorsSummary}
💡 RECOMENDAÇÕES: ${recommendations}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> Convenções de formatação de comentários: variam conforme o provedor ativo e são
> resolvidas pelo adapter (ex.: Unicode no ClickUp via `common:prompts:clickup-patterns`;
> ADF no Jira; Markdown no Linear). Detalhes em `.claude/utils/task-manager/adapters/`.

**Modo offline (`none`):** gerar `id` local (`local-{timestamp}`), criar documento em
`.claude/sessions/tasks/{id}.md` (subtasks em `.../{parent-id}/subtasks/`), anexar o
comentário ao documento e avisar que não será sincronizado.

#### 6.3. Normalizar saída

Após criar, montar `TaskOutput` padronizado: `id`, `provider`, `name`, `url`,
`status: 'todo'`, `createdAt` (ISO), `projectId`, `storyPoints`, `subtasks[]`.

### Passo 7: Executar Trabalho (Se Aplicável)

**APENAS** se a descrição indica ação imediata (ex.: "Remover arquivos X", "Criar
estrutura Y"): **após** criar a task, executar o trabalho e documentar o que foi feito.
Se a task é só planejamento/futuro, pular este passo (fica como "To Do").

### Passo 8: Atualizar Task com Resultado

Se houve execução no Passo 7:
1. Adicionar comentário com o que foi feito, arquivos modificados/criados/deletados,
   resultado e próximos passos.
2. Atualizar status: completo → "Done"; parcial → "In Progress"; só planejamento → "To Do".

### Passo 9: Apresentar Resultado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TASK CRIADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Task: {{description}}
🔗 URL: [url do provedor]
📊 Provedor: [clickup/asana/linear/local]

🎲 STORY POINTS:
∟ Task Principal: [X] pontos
∟ Subtasks: [Y] pontos ([N] subtasks)
∟ Total: [Z] pontos

📊 ANÁLISE: Complexidade [alta/média/baixa] | Risco [alto/médio/baixo] | Incerteza [alta/média/baixa]

🔧 ESTRUTURA:
├── Subtask 1: [nome] - [X] pontos
│   ├── ✅ Item 1.1
│   └── ✅ Item 1.2
└── Subtask 2: [nome] - [Y] pontos
    └── ✅ Item 2.1

💡 RECOMENDAÇÕES: ${recommendations}

🚀 Próximo: /engineer/start [feature-slug]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- **Detecção de provedor:** `.claude/utils/task-manager/detector.md`
- **Interface (entrada/saída normalizada):** `.claude/utils/task-manager/interface.md`
- **Tipos compartilhados:** `.claude/utils/task-manager/types.md`
- **Adapters (API-first; transporte por provedor — REST default, MCP opcional):** `.claude/utils/task-manager/adapters/{clickup,asana,linear}.md`
- **Decomposição:** `@task-specialist`
- **Estimativas:** `@story-points-framework-specialist`, `/product/estimate`,
  `docs/knowledge-base/frameworks/framework-story-points.md`
- **Formatação por provedor:** resolvida pelo adapter ativo em `.claude/utils/task-manager/adapters/` (ex.: `common:prompts:clickup-patterns` para ClickUp)

## ⚠️ Notas

- **OBRIGATÓRIO:** detectar provedor (`.env`) antes de tudo; nunca assumir.
- **OBRIGATÓRIO:** apresentar plano e pedir confirmação antes de criar.
- **OBRIGATÓRIO:** criar task PRIMEIRO, depois executar trabalho (se aplicável).
- Action items: máximo 4h cada. Épico (>13 pts): alertar e propor quebra.
- Estimativas automáticas para task principal e todas as subtasks.
- Se `soma(subtasks) > task principal`, ajustar a task principal.
- Sem provedor configurado: opera em modo local (sem sincronização).
