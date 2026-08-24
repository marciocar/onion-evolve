# 📐 Interface ITaskManager

## 🎯 Propósito

Define o contrato que todos os adapters de gerenciadores de tarefas devem implementar, garantindo consistência e permitindo troca transparente de provedores.

---

## 📋 Interface Completa

```typescript
/**
 * Interface abstrata para gerenciadores de tarefas.
 * Todos os adapters (ClickUp, Asana, Linear) devem implementar esta interface.
 */
interface ITaskManager {
  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTIFICAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Nome do provedor: 'clickup' | 'asana' | 'jira' | 'linear' | 'none'
   */
  readonly provider: TaskManagerProvider;
  
  /**
   * Indica se o provedor está configurado corretamente
   */
  readonly isConfigured: boolean;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD DE TASKS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Cria uma nova task no gerenciador.
   * @param input - Dados da task a criar
   * @returns Task criada com ID e URL
   */
  createTask(input: CreateTaskInput): Promise<TaskOutput>;
  
  /**
   * Obtém detalhes de uma task existente.
   * @param taskId - ID da task no provedor
   * @returns Task completa com todos os detalhes
   */
  getTask(taskId: string): Promise<TaskOutput>;
  
  /**
   * Atualiza uma task existente.
   * @param taskId - ID da task
   * @param updates - Campos a atualizar (parcial)
   * @returns Task atualizada
   */
  updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput>;
  
  /**
   * Remove uma task.
   * @param taskId - ID da task
   * @returns true se removida com sucesso
   */
  deleteTask(taskId: string): Promise<boolean>;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTASKS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Cria uma subtask vinculada a uma task pai.
   * @param parentId - ID da task pai
   * @param input - Dados da subtask
   * @returns Subtask criada
   */
  createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput>;
  
  /**
   * Lista todas as subtasks de uma task.
   * @param parentId - ID da task pai
   * @returns Array de subtasks
   */
  getSubtasks(parentId: string): Promise<TaskOutput[]>;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Adiciona um comentário a uma task.
   * @param taskId - ID da task
   * @param comment - Texto do comentário
   * @returns Comentário criado
   */
  addComment(taskId: string, comment: string): Promise<CommentOutput>;
  
  /**
   * Lista comentários de uma task.
   * @param taskId - ID da task
   * @returns Array de comentários
   */
  getComments(taskId: string): Promise<CommentOutput[]>;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Atualiza o status de uma task.
   * @param taskId - ID da task
   * @param status - Novo status (mapeado internamente pelo adapter)
   * @returns Task atualizada
   */
  updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput>;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BUSCA
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Busca tasks com filtros.
   * @param query - Critérios de busca
   * @returns Array de tasks que correspondem aos critérios
   */
  searchTasks(query: SearchQuery): Promise<TaskOutput[]>;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PROJETOS/LISTAS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Lista projetos/listas disponíveis.
   * @returns Array de projetos
   */
  getProjectList(): Promise<ProjectOutput[]>;
  
  /**
   * Obtém detalhes de um projeto.
   * @param projectId - ID do projeto
   * @returns Projeto com detalhes
   */
  getProject(projectId: string): Promise<ProjectOutput>;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════
  
  /**
   * Valida se um ID de task é válido para este provedor.
   * @param taskId - ID a validar
   * @returns true se o formato é válido
   */
  validateTaskId(taskId: string): boolean;
  
  /**
   * Detecta o provedor de origem de um ID de task.
   * @param taskId - ID da task
   * @returns Nome do provedor ou null se desconhecido
   */
  getProviderFromTaskId(taskId: string): TaskManagerProvider | null;
}
```

---

## 📊 Métodos por Categoria

| Categoria | Métodos | Descrição |
|-----------|---------|-----------|
| **Identificação** | `provider`, `isConfigured` | Informações do adapter |
| **CRUD Tasks** | `createTask`, `getTask`, `updateTask`, `deleteTask` | Operações básicas |
| **Subtasks** | `createSubtask`, `getSubtasks` | Hierarquia de tasks |
| **Comentários** | `addComment`, `getComments` | Documentação e discussão |
| **Status** | `updateStatus` | Workflow |
| **Busca** | `searchTasks` | Localização de tasks |
| **Projetos** | `getProjectList`, `getProject` | Navegação |
| **Validação** | `validateTaskId`, `getProviderFromTaskId` | Compatibilidade |

---

## 🔄 Mapeamento por Provedor

### Status

| Interface | ClickUp | Asana | Jira | Linear |
|-----------|---------|-------|------|--------|
| `backlog` | "backlog" | - | "Backlog" | "Backlog" |
| `todo` | "to do" | - | "To Do" | "Todo" |
| `in_progress` | "in progress" | - | "In Progress" | "In Progress" |
| `review` | "review" | - | "In Review" | "In Review" |
| `done` | "done" | completed: true | "Done" | "Done" |
| `closed` | "closed" | completed: true | "Closed" | "Canceled" |
| `canceled` | "closed" | completed: true | "Cancelled" | "Canceled" |

### Prioridade

| Interface | ClickUp | Asana | Jira | Linear |
|-----------|---------|-------|------|--------|
| `urgent` | 1 | - | Highest | 1 |
| `high` | 2 | - | High | 2 |
| `normal` | 3 | - | Medium | 3 |
| `low` | 4 | - | Low | 4 |

---

## 🧪 Exemplo de Uso

```typescript
// Obter adapter
const taskManager = getTaskManager();

// Verificar configuração
if (!taskManager.isConfigured) {
  console.warn('⚠️ Provedor não configurado. Execute /meta/setup-integration');
  return;
}

// Criar task
const task = await taskManager.createTask({
  name: 'Implementar feature X',
  description: 'Descrição detalhada...',
  priority: 'high',
  tags: ['feature', 'v2']
});

console.log(`✅ Task criada: ${task.url}`);

// Criar subtask
const subtask = await taskManager.createSubtask(task.id, {
  name: 'Fase 1: Setup'
});

// Adicionar comentário
await taskManager.addComment(task.id, '🚀 Desenvolvimento iniciado!');

// Atualizar status
await taskManager.updateStatus(subtask.id, 'in_progress');
```

---

## 📚 Referências

- [Tipos Compartilhados](./types.md)
- [Factory](./factory.md)
- [Adapters](./adapters/)

---

**Versão**: 1.0.0
**Criado em**: 2025-11-24

