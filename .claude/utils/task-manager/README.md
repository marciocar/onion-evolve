# Task Manager Abstraction Layer

> **Esta camada é uma instância concreta do padrão SDAAL (Specification-Driven AI Abstraction Layer).**
> Consulte o padrão-pai em [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) para entender os princípios de design, terminologia e diretrizes de extensão que regem esta implementação.

## Propósito

Camada de abstração que permite trocar o gerenciador de tarefas (ClickUp, Asana, Jira, Linear) sem modificar os comandos do Sistema Onion.

## Transporte: API-first, MCP opcional

Cada adapter usa a **REST API do provider como transporte padrão e preferencial**. O MCP é uma alternativa opcional, ativada explicitamente via variável de ambiente:

```bash
TASK_MANAGER_TRANSPORT=api   # padrão — REST API direta
TASK_MANAGER_TRANSPORT=mcp   # opcional — usa servidor MCP do provider quando disponível;
                              # se o provider não tiver MCP, cai automaticamente para API
```

Não existem wrappers MCP por provider. Cada adapter documenta as duas vias (API default; MCP opcional) de forma uniforme na sua própria documentação.

---

## Estrutura

```
task-manager/
├── README.md          # Este arquivo
├── interface.md       # Interface ITaskManager
├── types.md           # Tipos compartilhados
├── detector.md        # Detecção de provedor
├── factory.md         # Factory para adapters
└── adapters/
    ├── clickup.md     # Adapter ClickUp
    ├── asana.md       # Adapter Asana
    ├── jira.md        # Adapter Jira
    └── linear.md      # Adapter Linear (API-first; MCP opcional)
```

## Uso Rápido

### 1. Configurar provedor e transporte

No `.env`:
```bash
# Provider ativo (obrigatório)
TASK_MANAGER_PROVIDER=clickup   # clickup | asana | jira | linear | none

# Transporte (opcional — default: api)
TASK_MANAGER_TRANSPORT=api      # api (default) | mcp
```

### 2. Usar nos comandos

```typescript
// Importar factory
import { getTaskManager } from '.claude/utils/task-manager/factory';

// Obter adapter configurado (respeita TASK_MANAGER_PROVIDER e TASK_MANAGER_TRANSPORT)
const taskManager = getTaskManager();

// Usar interface comum — independente de provider ou transporte
const task = await taskManager.createTask({
  name: 'Minha Task',
  description: 'Descrição da task'
});
```

## Provedores Suportados

| Provedor | Status | Transporte padrão | MCP disponível |
|----------|--------|--------------------|----------------|
| ClickUp | Completo | REST API | Sim (opcional via `TASK_MANAGER_TRANSPORT=mcp`) |
| Asana | Completo | REST API | Sim (opcional via `TASK_MANAGER_TRANSPORT=mcp`) |
| Jira | Completo | REST API v3 (Cloud) / v2 (Server/DC) | Sim (opcional via `TASK_MANAGER_TRANSPORT=mcp`) |
| Linear | Completo | GraphQL API | Sim (opcional via `TASK_MANAGER_TRANSPORT=mcp`) |
| None | Funcional | — (modo offline) | — |

## Fluxo de Execução

```
Comando Onion
     │
     ▼
┌─────────────┐
│   Factory   │ → TASK_MANAGER_PROVIDER + TASK_MANAGER_TRANSPORT
└─────────────┘
     │
     ▼
┌─────────────┐
│  Adapter    │ → ClickUp | Asana | Jira | Linear | None
└─────────────┘
     │
     ▼
┌──────────────────────────────────┐
│  Transporte                      │
│  • api  (default) → REST API     │
│  • mcp  (opcional) → MCP server  │
│    (fallback para API se indis.) │
└──────────────────────────────────┘
     │
     ▼
  Operação executada
```

## Referências internas

- [Interface ITaskManager](./interface.md)
- [Tipos Compartilhados](./types.md)
- [Detector de Provedor](./detector.md)
- [Factory](./factory.md)
- [Adapter ClickUp](./adapters/clickup.md)
- [Adapter Asana](./adapters/asana.md)
- [Adapter Jira](./adapters/jira.md)
- [Adapter Linear](./adapters/linear.md)

## Documentação relacionada

- [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) — padrão SDAAL (padrão-pai desta camada)
- `docs/knowledge-base/concepts/task-manager-abstraction.md` — Knowledge Base completa desta instância
- `.env.example` — variáveis de ambiente disponíveis

---

**Criado em**: 2025-11-24 | **Atualizado em**: 2026-06-13

