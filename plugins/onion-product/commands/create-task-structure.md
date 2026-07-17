---
name: create-task-structure
description: |
  Decomposição de tarefas complexas em estrutura hierárquica.
  Use para criar estrutura organizada de subtarefas.
  Diferença vs /product:task: este é decomposição LOCAL read-only (saída textual); o /product:task PERSISTE no task manager ativo (Jira/ClickUp/Asana/Linear).
model: sonnet
allowed-tools: Read

parameters:
  - name: task
    description: Descrição da tarefa complexa
    required: true
  - name: output
    description: Formato de saída (markdown/json/clickup)
    required: false
    default: markdown

category: product
tags:
  - task-decomposition
  - planning
  - structure

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /product/task
  - /engineer/start

related_agents:
  - task-specialist
---

# 📋 Criar Estrutura de Tarefas

Decomposição de tarefas complexas em hierarquia gerenciável.

## 🎯 Objetivo

Transformar tarefa complexa em estrutura organizada de subtarefas.

## ⚡ Fluxo de Execução

### Passo 1: Analisar Tarefa

Entender `{{task}}`:

| Aspecto | Pergunta |
|---------|----------|
| Objetivo | O que precisa estar pronto? |
| Escopo | Quais áreas são afetadas? |
| Complexidade | Quantas etapas? |
| Dependências | Ordem obrigatória? |
| Riscos | Pontos críticos? |

### Passo 2: Identificar Subtarefas

#### Por Camada Técnica

- 📊 **Data**: schemas, migrations, modelos
- 🔌 **API**: endpoints, validação, business logic
- 🎨 **UI**: componentes, páginas, styling
- 🧪 **Testing**: unit, integration, e2e
- 📚 **Docs**: documentação, comentários

#### Por Tipo de Atividade

- 🔍 Análise e pesquisa
- 🏗️ Implementação
- 🧪 Testes
- 📝 Documentação
- 🔄 Integração

### Passo 3: Estruturar Hierarquia

Consultar @task-specialist para estrutura:

```
📋 TASK PRINCIPAL
├── 🔧 Fase 1: [Nome]
│   ├── ✅ Subtask 1.1
│   └── ✅ Subtask 1.2
├── 🔧 Fase 2: [Nome]
│   ├── ✅ Subtask 2.1
│   └── ✅ Subtask 2.2
└── 🔧 Fase 3: [Nome]
    └── ✅ Subtask 3.1
```

### Passo 4: Gerar Output

SE `{{output}}` = "markdown":
```markdown
# Estrutura de Tarefas: [Nome]

## Resumo
- Total de fases: X
- Total de subtasks: Y
- Estimativa: Z dias

## Estrutura
[hierarquia]
```

SE `{{output}}` = "json":
```json
{
  "task": "...",
  "phases": [...],
  "estimatedDays": X
}
```

SE `{{output}}` = "clickup":
→ Delegar para @clickup-specialist

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ESTRUTURA CRIADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: {{task}}

📊 Decomposição:
∟ Fases: 4
∟ Subtasks: 12
∟ Estimativa: 5 dias

🔧 Estrutura:
├── Fase 1: Setup (1d)
├── Fase 2: Implementação (2d)
├── Fase 3: Testes (1d)
└── Fase 4: Deploy (1d)

🚀 Próximo: /product/task
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- Decomposição: @task-specialist
- Criação no ClickUp: /product/task

## ⚠️ Notas

- Máximo 6 fases por task
- Subtasks de 1-4h cada
- Se muito grande: quebrar em múltiplas tasks
