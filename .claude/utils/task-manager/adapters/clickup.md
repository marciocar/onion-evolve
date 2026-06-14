# 🔵 ClickUp Adapter

## 🎯 Propósito

Implementação do `ITaskManager` para ClickUp, seguindo o padrão **SDAAL** (ver [specification-driven-ai-abstraction-layer.md](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)).

**Transporte padrão**: ClickUp REST API v2 via `fetch` — sem dependências externas.
**Transporte opcional**: MCP ClickUp, ativado quando `TASK_MANAGER_TRANSPORT=mcp`.

---

## 📋 Configuração

### Variáveis de Ambiente

```bash
# Obrigatória
CLICKUP_API_TOKEN=pk_xxxxx

# Opcionais
CLICKUP_WORKSPACE_ID=your_workspace_id    # Auto-detectado se não informado
CLICKUP_DEFAULT_LIST_ID=your_list_id      # Lista padrão para novas tasks

# Controle de transporte (default: api)
TASK_MANAGER_TRANSPORT=api               # api (default) | mcp
```

### Obter Token

1. Acesse ClickUp → Settings → Apps
2. Clique em "Generate" em API Token
3. Copie o token e adicione ao `.env`

---

## 🌐 Transporte: REST API v2 (padrão)

### Endpoint Base

```
https://api.clickup.com/api/v2/
```

### Autenticação

```
Authorization: {CLICKUP_API_TOKEN}
Content-Type: application/json
```

> Nota: o ClickUp usa o token direto no header `Authorization`, sem prefixo `Bearer`.

### Endpoints Principais

| Operação | Método | Endpoint |
|----------|--------|----------|
| Criar task | POST | `/list/{list_id}/task` |
| Obter task | GET | `/task/{task_id}?subtasks=true` |
| Atualizar task | PUT | `/task/{task_id}` |
| Deletar task | DELETE | `/task/{task_id}` |
| Criar comentário | POST | `/task/{task_id}/comment` |
| Listar comentários | GET | `/task/{task_id}/comment` |
| Buscar tasks | GET | `/team/{workspace_id}/task?` |
| Hierarquia do workspace | GET | `/team/{workspace_id}/space?archived=false` |
| Listas de um space | GET | `/space/{space_id}/list` |
| Obter lista | GET | `/list/{list_id}` |

---

## 🔌 Transporte: MCP (opcional)

Ativado quando `TASK_MANAGER_TRANSPORT=mcp` **e** o servidor MCP do ClickUp estiver disponível no ambiente.

Quando ativo, substitui os `fetch` calls pelas funções MCP equivalentes:

| Via API (padrão) | Via MCP (opcional) |
|------------------|--------------------|
| `POST /list/{id}/task` | `mcp_ClickUp_clickup_create_task(...)` |
| `GET /task/{id}` | `mcp_ClickUp_clickup_get_task(...)` |
| `PUT /task/{id}` | `mcp_ClickUp_clickup_update_task(...)` |
| `DELETE /task/{id}` | `mcp_ClickUp_clickup_delete_task(...)` |
| `POST /task/{id}/comment` | `mcp_ClickUp_clickup_create_task_comment(...)` |
| `GET /task/{id}/comment` | `mcp_ClickUp_clickup_get_task_comments(...)` |
| `GET /team/{wid}/task` | `mcp_ClickUp_clickup_search(...)` |
| Hierarquia workspace | `mcp_ClickUp_clickup_get_workspace_hierarchy(...)` |
| `GET /list/{id}` | `mcp_ClickUp_clickup_get_list(...)` |

Se `TASK_MANAGER_TRANSPORT=mcp` mas o servidor MCP não estiver disponível, o adapter cai para API automaticamente (fallback gracioso).

---

## 🔧 Implementação

```typescript
/**
 * Adapter ClickUp implementando ITaskManager.
 *
 * Transporte:
 * - PADRÃO: ClickUp REST API v2 via fetch (TASK_MANAGER_TRANSPORT=api ou ausente)
 * - OPCIONAL: MCP ClickUp (TASK_MANAGER_TRANSPORT=mcp, quando servidor disponível)
 *
 * Formatação de conteúdo:
 * - Descrições de tasks: Markdown nativo (campo markdown_description)
 * - Comentários: formatação visual Unicode (independente do transporte)
 */
class ClickUpAdapter implements ITaskManager {
  readonly provider: TaskManagerProvider = 'clickup';
  readonly isConfigured: boolean;

  private apiToken: string;
  private workspaceId?: string;
  private defaultListId?: string;
  private baseUrl = 'https://api.clickup.com/api/v2';
  private useMcp: boolean;

  constructor(config: ClickUpAdapterConfig) {
    this.apiToken = config.apiToken;
    this.workspaceId = config.workspaceId;
    this.defaultListId = config.defaultListId;
    this.isConfigured = !!this.apiToken;
    this.useMcp = process.env.TASK_MANAGER_TRANSPORT === 'mcp';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS DE TRANSPORTE
  // ═══════════════════════════════════════════════════════════════════════════

  private get headers() {
    return {
      'Authorization': this.apiToken,
      'Content-Type': 'application/json'
    };
  }

  /** Executa fetch na REST API v2 do ClickUp. */
  private async api<T>(method: string, path: string, body?: unknown): Promise<T> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers: this.headers,
      body: body ? JSON.stringify(body) : undefined
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`ClickUp API ${method} ${path} → ${res.status}: ${err}`);
    }

    return res.json() as Promise<T>;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD DE TASKS
  // ═══════════════════════════════════════════════════════════════════════════

  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
    const listId = input.projectId || this.defaultListId;

    if (!listId) {
      throw new Error('❌ list_id ou CLICKUP_DEFAULT_LIST_ID obrigatório');
    }

    const payload = {
      name: input.name,
      description: input.description,
      markdown_description: input.markdownDescription,
      priority: this.mapPriorityToClickUp(input.priority),
      due_date: input.dueDate,
      start_date: input.startDate,
      assignees: input.assignees,
      tags: input.tags
    };

    if (this.useMcp) {
      // Via MCP
      const result = await mcp_ClickUp_clickup_create_task({
        workspace_id: this.workspaceId,
        list_id: listId,
        ...payload
      });
      return this.normalizeTask(JSON.parse(result.content[0].text));
    }

    // Via API (padrão)
    const data = await this.api<any>('POST', `/list/${listId}/task`, payload);
    return this.normalizeTask(data);
  }

  async getTask(taskId: string): Promise<TaskOutput> {
    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_get_task({
        workspace_id: this.workspaceId,
        task_id: taskId,
        subtasks: true
      });
      return this.normalizeTask(JSON.parse(result.content[0].text));
    }

    const data = await this.api<any>('GET', `/task/${taskId}?subtasks=true`);
    return this.normalizeTask(data);
  }

  async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
    const payload = {
      name: updates.name,
      description: updates.description,
      markdown_description: updates.markdownDescription,
      status: updates.status ? this.mapStatusToClickUp(updates.status) : undefined,
      priority: updates.priority ? this.mapPriorityToClickUp(updates.priority) : undefined,
      due_date: updates.dueDate,
      start_date: updates.startDate,
      assignees: updates.assignees
    };

    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_update_task({
        workspace_id: this.workspaceId,
        task_id: taskId,
        ...payload
      });
      return this.normalizeTask(JSON.parse(result.content[0].text));
    }

    const data = await this.api<any>('PUT', `/task/${taskId}`, payload);
    return this.normalizeTask(data);
  }

  async deleteTask(taskId: string): Promise<boolean> {
    try {
      if (this.useMcp) {
        await mcp_ClickUp_clickup_delete_task({
          workspace_id: this.workspaceId,
          task_id: taskId
        });
        return true;
      }

      await this.api('DELETE', `/task/${taskId}`);
      return true;
    } catch {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTASKS
  // ═══════════════════════════════════════════════════════════════════════════

  async createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput> {
    const parentTask = await this.getTask(parentId);
    const listId = parentTask.projectId || this.defaultListId;

    const payload = {
      name: input.name,
      description: input.description,
      markdown_description: input.markdownDescription,
      priority: this.mapPriorityToClickUp(input.priority),
      tags: input.tags,
      parent: parentId   // ← Torna subtask
    };

    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_create_task({
        workspace_id: this.workspaceId,
        list_id: listId,
        ...payload
      });
      return this.normalizeTask(JSON.parse(result.content[0].text));
    }

    const data = await this.api<any>('POST', `/list/${listId}/task`, payload);
    return this.normalizeTask(data);
  }

  async getSubtasks(parentId: string): Promise<TaskOutput[]> {
    const task = await this.getTask(parentId);
    return task.subtasks || [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════

  async addComment(taskId: string, comment: string): Promise<CommentOutput> {
    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_create_task_comment({
        workspace_id: this.workspaceId,
        task_id: taskId,
        comment_text: comment
      });
      const data = JSON.parse(result.content[0].text);
      return this.normalizeComment(data.comment || data, comment);
    }

    const data = await this.api<any>('POST', `/task/${taskId}/comment`, {
      comment_text: comment,
      notify_all: false
    });
    return this.normalizeComment(data, comment);
  }

  async getComments(taskId: string): Promise<CommentOutput[]> {
    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_get_task_comments({
        workspace_id: this.workspaceId,
        task_id: taskId
      });
      const data = JSON.parse(result.content[0].text);
      return (data.comments || []).map((c: any) => this.normalizeComment(c, c.comment_text || c.comment));
    }

    const data = await this.api<any>('GET', `/task/${taskId}/comment`);
    return (data.comments || []).map((c: any) => this.normalizeComment(c, c.comment_text || c.comment));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> {
    return this.updateTask(taskId, { status });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSCA
  // ═══════════════════════════════════════════════════════════════════════════

  async searchTasks(query: SearchQuery): Promise<TaskOutput[]> {
    if (!this.workspaceId) {
      throw new Error('❌ CLICKUP_WORKSPACE_ID obrigatório para busca');
    }

    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_search({
        workspace_id: this.workspaceId,
        keywords: query.text,
        filters: { asset_types: ['task'] }
      });
      const data = JSON.parse(result.content[0].text);
      return (data.results || [])
        .filter((r: any) => r.type === 'task')
        .slice(0, query.limit || 50)
        .map((r: any) => this.normalizeSearchResult(r));
    }

    // REST API: GET /team/{workspace_id}/task
    const params = new URLSearchParams({
      page: '0',
      ...(query.text ? { search_text: query.text } : {}),
      ...(query.limit ? { page_size: String(query.limit) } : {})
    });

    const data = await this.api<any>('GET', `/team/${this.workspaceId}/task?${params}`);
    return (data.tasks || []).map((t: any) => this.normalizeTask(t));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJETOS / LISTAS
  // ═══════════════════════════════════════════════════════════════════════════

  async getProjectList(): Promise<ProjectOutput[]> {
    if (!this.workspaceId) {
      throw new Error('❌ CLICKUP_WORKSPACE_ID obrigatório para listar projetos');
    }

    const projects: ProjectOutput[] = [];

    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_get_workspace_hierarchy({
        workspace_id: this.workspaceId,
        max_depth: 2
      });
      const data = JSON.parse(result.content[0].text);
      return this.extractProjectsFromHierarchy(data);
    }

    // REST API: listar spaces → folders → lists
    const spacesData = await this.api<any>('GET', `/team/${this.workspaceId}/space?archived=false`);

    for (const space of spacesData.spaces || []) {
      // Listas dentro de folders
      const foldersData = await this.api<any>('GET', `/space/${space.id}/folder?archived=false`);
      for (const folder of foldersData.folders || []) {
        const listsData = await this.api<any>('GET', `/folder/${folder.id}/list?archived=false`);
        for (const list of listsData.lists || []) {
          projects.push({
            id: list.id,
            name: `${space.name} / ${folder.name} / ${list.name}`,
            workspaceId: this.workspaceId
          });
        }
      }
      // Listas sem folder (folderless)
      const folderlessData = await this.api<any>('GET', `/space/${space.id}/list?archived=false`);
      for (const list of folderlessData.lists || []) {
        projects.push({
          id: list.id,
          name: `${space.name} / ${list.name}`,
          workspaceId: this.workspaceId
        });
      }
    }

    return projects;
  }

  async getProject(projectId: string): Promise<ProjectOutput> {
    if (this.useMcp) {
      const result = await mcp_ClickUp_clickup_get_list({
        workspace_id: this.workspaceId,
        list_id: projectId
      });
      const data = JSON.parse(result.content[0].text);
      return { id: data.id, name: data.name, description: data.content, workspaceId: this.workspaceId };
    }

    const data = await this.api<any>('GET', `/list/${projectId}`);
    return { id: data.id, name: data.name, description: data.content, workspaceId: this.workspaceId };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  validateTaskId(taskId: string): boolean {
    // ClickUp IDs: 9 caracteres alfanuméricos
    return /^[a-z0-9]{9}$/i.test(taskId);
  }

  getProviderFromTaskId(taskId: string): TaskManagerProvider | null {
    return this.validateTaskId(taskId) ? 'clickup' : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  private normalizeTask(raw: any): TaskOutput {
    return {
      id: raw.id,
      provider: 'clickup',
      name: raw.name,
      description: raw.text_content || raw.description || '',
      status: this.normalizeStatus(raw.status?.status),
      statusRaw: raw.status?.status,
      statusColor: raw.status?.color,
      priority: this.normalizePriority(raw.priority?.priority),
      url: raw.url,
      createdAt: new Date(parseInt(raw.date_created)).toISOString(),
      updatedAt: new Date(parseInt(raw.date_updated)).toISOString(),
      dueDate: raw.due_date ? new Date(parseInt(raw.due_date)).toISOString() : undefined,
      startDate: raw.start_date ? new Date(parseInt(raw.start_date)).toISOString() : undefined,
      assignees: (raw.assignees || []).map((a: any) => ({
        id: String(a.id),
        name: a.username,
        email: a.email
      })),
      tags: (raw.tags || []).map((t: any) => t.name),
      subtasks: raw.subtasks?.map((st: any) => this.normalizeTask(st)),
      parent: raw.parent || undefined,
      projectId: raw.list?.id,
      projectName: raw.list?.name,
      timeEstimate: raw.time_estimate ? Math.round(raw.time_estimate / 60000) : undefined,
      timeSpent: raw.time_spent ? Math.round(raw.time_spent / 60000) : undefined
    };
  }

  private normalizeComment(raw: any, text: string): CommentOutput {
    return {
      id: String(raw.id),
      text,
      author: {
        id: String(raw.user?.id || 'unknown'),
        name: raw.user?.username || 'Unknown'
      },
      createdAt: raw.date ? new Date(parseInt(raw.date)).toISOString() : new Date().toISOString()
    };
  }

  private normalizeSearchResult(raw: any): TaskOutput {
    return {
      id: raw.id,
      provider: 'clickup',
      name: raw.name,
      description: raw.description || '',
      status: 'todo',
      url: raw.url || `https://app.clickup.com/t/${raw.id}`,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      assignees: [],
      tags: []
    };
  }

  private extractProjectsFromHierarchy(data: any): ProjectOutput[] {
    const projects: ProjectOutput[] = [];
    for (const space of data.spaces || []) {
      for (const folder of space.folders || []) {
        for (const list of folder.lists || []) {
          projects.push({
            id: list.id,
            name: `${space.name} / ${folder.name} / ${list.name}`,
            workspaceId: this.workspaceId
          });
        }
      }
      for (const list of space.lists || []) {
        projects.push({
          id: list.id,
          name: `${space.name} / ${list.name}`,
          workspaceId: this.workspaceId
        });
      }
    }
    return projects;
  }

  private normalizeStatus(clickupStatus?: string): TaskStatus {
    const statusMap: Record<string, TaskStatus> = {
      'backlog': 'backlog',
      'bakclog': 'backlog',   // typo comum no ClickUp
      'to do': 'todo',
      'open': 'todo',
      'in progress': 'in_progress',
      'in review': 'review',
      'review': 'review',
      'done': 'done',
      'complete': 'done',
      'closed': 'closed'
    };
    return statusMap[clickupStatus?.toLowerCase() || ''] || 'todo';
  }

  private mapStatusToClickUp(status: TaskStatus): string {
    const statusMap: Record<TaskStatus, string> = {
      'backlog': 'backlog',
      'todo': 'to do',
      'in_progress': 'in progress',
      'review': 'review',
      'done': 'done',
      'closed': 'closed',
      'canceled': 'closed'
    };
    return statusMap[status] || 'to do';
  }

  private normalizePriority(clickupPriority?: string): TaskPriority | undefined {
    const priorityMap: Record<string, TaskPriority> = {
      '1': 'urgent', 'urgent': 'urgent',
      '2': 'high',   'high': 'high',
      '3': 'normal', 'normal': 'normal',
      '4': 'low',    'low': 'low'
    };
    return priorityMap[clickupPriority?.toLowerCase() || ''];
  }

  private mapPriorityToClickUp(priority?: TaskPriority): string | undefined {
    if (!priority) return undefined;
    const priorityMap: Record<TaskPriority, string> = {
      'urgent': 'urgent',
      'high': 'high',
      'normal': 'normal',
      'low': 'low'
    };
    return priorityMap[priority];
  }
}
```

---

## 📊 Mapeamento de Campos

### Task Fields

| Interface | ClickUp API | Notas |
|-----------|-------------|-------|
| `name` | `name` | Direto |
| `description` | `description` | Texto plano |
| `markdownDescription` | `markdown_description` | Com formatação |
| `status` | `status.status` | Mapeado |
| `priority` | `priority.priority` | Mapeado |
| `dueDate` | `due_date` | Timestamp ms |
| `assignees` | `assignees[].id` | Array de IDs |
| `tags` | `tags[].name` | Array de strings |
| `projectId` | `list.id` | ID da lista |

### Status Mapping

| Interface | ClickUp |
|-----------|---------|
| `backlog` | "backlog" |
| `todo` | "to do" |
| `in_progress` | "in progress" |
| `review` | "review" |
| `done` | "done" |
| `closed` | "closed" |

---

## 💬 Formatação de Conteúdo

A formatação é específica do ClickUp e **independente do transporte escolhido** (API ou MCP).

### Descrições de Tasks (`markdown_description`)

Use Markdown nativo:

```markdown
## Objetivo
Implementar funcionalidade X conforme spec.

## Critérios de Aceite
- [ ] Comportamento A funciona
- [ ] Cobertura de testes ≥ 80%

| Campo | Valor |
|-------|-------|
| Sprint | 12 |
| Story Points | 5 |
```

### Comentários (`comment_text`)

Use formatação visual Unicode para legibilidade nos feeds do ClickUp:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ FASE CONCLUÍDA — Backend Implementation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Arquivos modificados
  ∟ src/auth/service.ts
  ∟ src/auth/routes.ts

◆ Implementações
  ✅ JWT auth
  ✅ Refresh tokens

◆ Testes: cobertura 95%

▶ Próxima fase: Frontend Integration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🕐 2026-06-13T14:30:00Z
```

**Regra**: todo comentário de progresso deve incluir timestamp e status atual.

---

## 🧪 Exemplos de Uso

```typescript
// Via Factory (transporte definido pelo .env)
const tm = getTaskManager(); // Retorna ClickUpAdapter se configurado

// Criar task
const task = await tm.createTask({
  name: 'Nova Feature',
  markdownDescription: '## Objetivo\nImplementar funcionalidade X',
  priority: 'high',
  tags: ['feature', 'v2']
});

// Criar subtask
const subtask = await tm.createSubtask(task.id, {
  name: 'Fase 1: Setup'
});

// Atualizar status
await tm.updateStatus(subtask.id, 'in_progress');

// Adicionar comentário com formatação Unicode
await tm.addComment(task.id, [
  '━━━━━━━━━━━━━━━━━━━━━━━',
  '▶ Desenvolvimento iniciado',
  `🕐 ${new Date().toISOString()}`
].join('\n'));
```

---

## ⚡ Operações em Lote (Bulk)

> Detalhe específico do ClickUp. Via abstração, o consumidor usa `createTask`/`createSubtask`; o adapter aplica internamente a regra abaixo.

**Quando usar bulk:** criar múltiplas tasks **independentes no mesmo nível**; atualizar status de várias tasks.

**Limitação crítica — bulk NÃO suporta hierarquia.** O endpoint de criação em lote **ignora** o `parent`. Para hierarquia (task → subtasks), use criação **sequencial** com `parent`:

```javascript
// ❌ ERRADO — parent ignorado no bulk
await create_bulk_tasks({ tasks: [{ name: 'Sub 1', parent: mainId }, { name: 'Sub 2', parent: mainId }] });

// ✅ CORRETO — sequencial preserva hierarquia
const sub1 = await create_task({ name: 'Sub 1', parent: mainId });
const sub2 = await create_task({ name: 'Sub 2', parent: mainId });
```

✅ bulk para: tasks independentes no mesmo nível · ❌ bulk para: hierarquia.

---

## 🏗️ Hierarquia de Tasks (3 níveis)

```
📋 TASK (objetivo de alto nível)
├── 🔧 Subtask 1 (componente)
│   ├── ✅ Checklist item 1.1
│   └── ✅ Checklist item 1.2
└── 🔧 Subtask 2
    └── ✅ Checklist item 2.1
```

**Implementação correta** — transporte default = **REST API** do adapter (`create_task` mapeia para `POST /list/{id}/task`); o `mcp_ClickUp_*` é apenas o transporte **opcional** via `TASK_MANAGER_TRANSPORT=mcp`:

```javascript
// 1. Task principal
const mainTask = await create_task({
  name: '🎯 Implementar Autenticação JWT',
  listId: '<list_id>',
  markdown_description: '## 🎯 Objetivo\nImplementar JWT...\n\n## ✅ Critérios\n- [ ] Login retorna JWT\n- [ ] Refresh funciona',
  tags: ['feature', 'security'], priority: 'high'
});

// 2. Subtasks com parent (← CRITICAL para hierarquia)
const sub1 = await create_task({ name: '🔧 Backend JWT Service', listId: '<list_id>', parent: mainTask.id, tags: ['subtask', 'backend'] });
const sub2 = await create_task({ name: '🔧 Frontend Integration', listId: '<list_id>', parent: mainTask.id, tags: ['subtask', 'frontend'] });

// 3. Comentário de setup (formatação Unicode — ver seção de Formatação)
await create_task_comment({ task_id: mainTask.id, comment_text: '🚀 TASK SETUP COMPLETO\n━━━━━━━━━━━━\n▶ Subtasks: 2\n⏰ ' + new Date().toISOString() });
```

---

## ✅ Checklists Nativos

Checklists nativos do ClickUp (diferentes de checkboxes em markdown) oferecem tracking interativo (resolved/unresolved), progresso visual e leitura via API. O Sistema Onion suporta estrutura híbrida: checkboxes em markdown (documentação) + checklists nativos (tracking).

**Leitura e cálculo de progresso** (incluir `subtasks: true` no get para trazer checklists):

```javascript
const task = await getTask({ task_id: '<id>', subtasks: true });

function calculateProgress(task) {
  let total = 0, resolved = 0;
  (task.checklists || []).forEach(c => { total += c.unresolved + c.resolved; resolved += c.resolved; });
  return total > 0 ? (resolved / total * 100).toFixed(1) : 0;
}
// Progresso: `${calculateProgress(task)}%`
```

---

## 🔧 Troubleshooting (ClickUp)

| Problema | Causa | Solução |
|---|---|---|
| Subtasks aparecem como tasks independentes | uso de `create_bulk_tasks` com `parent` | criar sequencial com `create_task({ parent })` (ver Hierarquia) |
| Formatação quebrada em comments | markdown em comentário | usar Unicode visual (`━━━`, `▶`, `∟`); markdown só em `markdown_description` |
| Auto-update não funciona | `context.md` sem task-id ou mapeamento fase→subtask ausente | validar com `/engineer/validate-phase-sync`; conferir `TASK_MANAGER_PROVIDER` e credenciais |
| Checklists não aparecem | `get_task` sem `subtasks: true` | passar `subtasks: true` na leitura |

---

## 💡 Best Practices (ClickUp)

1. **Hierarquia na ordem certa**: task principal → subtasks com `parent` → comentário de setup.
2. **Formatação por contexto**: `markdown_description` em Markdown; comentários em Unicode visual.
3. **Sempre timestamp + status** em comentários de progresso.
4. **Mapeamento fase→subtask** obrigatório no `context.md` da sessão.
5. **Validar estrutura** após criação (`getTask({ subtasks: true })` → conferir `subtasks.length`).

---

## ⚠️ Notas Operacionais

- **`CLICKUP_WORKSPACE_ID`** é obrigatório para busca (`searchTasks`) e listagem de projetos (`getProjectList`). Se ausente, essas operações lançam erro descritivo.
- **Datas** no ClickUp são timestamps em milissegundos (inteiros). Converter com `new Date(parseInt(raw.due_date)).toISOString()`.
- **IDs de tasks** ClickUp: 9 caracteres alfanuméricos (ex: `86abc1234`).
- **Status** são configuráveis por espaço/lista no ClickUp; os mapeamentos acima cobrem os nomes padrão. Em listas com status customizados, usar `statusRaw` para inspecionar o valor original.
- **Prioridade**: ClickUp aceita `urgent | high | normal | low` como string ou `1 | 2 | 3 | 4` como número.

---

## 📚 Referências

- [ClickUp REST API v2](https://clickup.com/api)
- [Interface ITaskManager](../interface.md)
- [Types](../types.md)
- [Factory](../factory.md)
- [SDAAL — padrão-pai](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 2.0.0
**Atualizado em**: 2026-06-13
