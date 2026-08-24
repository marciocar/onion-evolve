# 🟠 Asana Adapter

> Instância do padrão [SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md).
> Transporte **padrão: REST API**. MCP opcional via `TASK_MANAGER_TRANSPORT=mcp`.

---

## 📋 Configuração

### Variáveis de Ambiente

```bash
# Obrigatória
ASANA_ACCESS_TOKEN=1/xxxxx

# Opcionais
ASANA_WORKSPACE_ID=1234567890123456       # Workspace padrão
ASANA_DEFAULT_PROJECT_ID=1234567890123456 # Projeto padrão

# Transporte (padrão: api)
TASK_MANAGER_TRANSPORT=api   # "api" (REST) | "mcp" (MCP opcional)
```

### Obter Token

1. Acesse Asana → My Settings → Apps → Developer Apps
2. Clique em "Create new app" ou use existente
3. Gere um Personal Access Token
4. Copie o token e adicione ao `.env`

---

## 🚦 Seleção de Transporte

| `TASK_MANAGER_TRANSPORT` | Comportamento |
|--------------------------|---------------|
| `api` (padrão) | Chama a Asana REST API diretamente via `fetch` |
| `mcp` | Usa ferramentas MCP `mcp__claude_ai_Asana__asana_*` quando disponíveis; cai para API se não disponível |

> Regra de ouro: prefira `api`. Use `mcp` apenas quando o servidor MCP do Asana estiver ativo na sessão.

---

## 🔧 Implementação

### Constantes e Helpers Comuns

```typescript
const ASANA_BASE = 'https://app.asana.com/api/1.0';

// Cabeçalhos para todas as requisições REST
function asanaHeaders(token: string): HeadersInit {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };
}

// Campos padrão para reduzir payload (~70 % menor)
const TASK_FIELDS =
  'gid,name,notes,completed,due_on,start_on,assignee,assignee.name,assignee.email,' +
  'tags,tags.name,parent,parent.gid,projects,projects.gid,projects.name,' +
  'created_at,modified_at,permalink_url';
```

### AsanaAdapter

```typescript
/**
 * Adapter Asana implementando ITaskManager.
 * Transporte padrão: REST API (TASK_MANAGER_TRANSPORT=api).
 * Transporte opcional: MCP (TASK_MANAGER_TRANSPORT=mcp).
 */
class AsanaAdapter implements ITaskManager {
  readonly provider: TaskManagerProvider = 'asana';
  readonly isConfigured: boolean;

  private accessToken: string;
  private workspaceId?: string;
  private defaultProjectId?: string;
  private useMcp: boolean;

  constructor(config: AsanaAdapterConfig) {
    this.accessToken = config.accessToken;
    this.workspaceId = config.workspaceId;
    this.defaultProjectId = config.defaultProjectId;
    this.isConfigured = !!this.accessToken;
    this.useMcp = (process.env.TASK_MANAGER_TRANSPORT ?? 'api') === 'mcp';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD DE TASKS
  // ═══════════════════════════════════════════════════════════════════════════

  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
    const projectId = input.projectId ?? this.defaultProjectId;
    const body = {
      data: {
        name: input.name,
        notes: input.description,
        html_notes: input.markdownDescription,
        ...(projectId && { projects: [projectId] }),
        ...(this.workspaceId && { workspace: this.workspaceId }),
        ...(input.dueDate && { due_on: input.dueDate }),
        ...(input.startDate && { start_on: input.startDate }),
        ...(input.assignees?.[0] && { assignee: input.assignees[0] })
      }
    };

    if (this.useMcp) {
      // Via MCP (opcional)
      const result = await mcp__claude_ai_Asana__asana_create_task({
        name: input.name,
        notes: input.description,
        html_notes: input.markdownDescription,
        project_id: projectId,
        workspace: this.workspaceId,
        due_on: input.dueDate,
        start_on: input.startDate,
        assignee: input.assignees?.[0]
      });
      return this.normalizeTask(JSON.parse(result.content[0].text).data);
    }

    // Via REST API (padrão)
    const res = await fetch(`${ASANA_BASE}/tasks`, {
      method: 'POST',
      headers: asanaHeaders(this.accessToken),
      body: JSON.stringify(body)
    });
    const json = await res.json();
    return this.normalizeTask(json.data);
  }

  async getTask(taskId: string): Promise<TaskOutput> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_get_task({
        task_id: taskId,
        opt_fields: TASK_FIELDS
      });
      return this.normalizeTask(JSON.parse(result.content[0].text).data);
    }

    const res = await fetch(
      `${ASANA_BASE}/tasks/${taskId}?opt_fields=${TASK_FIELDS}`,
      { headers: asanaHeaders(this.accessToken) }
    );
    const json = await res.json();
    return this.normalizeTask(json.data);
  }

  async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
    const patch: Record<string, unknown> = {};
    if (updates.name) patch.name = updates.name;
    if (updates.description) patch.notes = updates.description;
    if (updates.status !== undefined)
      patch.completed = updates.status === 'done' || updates.status === 'closed';
    if (updates.dueDate !== undefined) patch.due_on = updates.dueDate;
    if (updates.startDate !== undefined) patch.start_on = updates.startDate;
    if (updates.assignees?.length) patch.assignee = updates.assignees[0];

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_update_task({
        task_id: taskId,
        ...patch
      });
      return this.normalizeTask(JSON.parse(result.content[0].text).data);
    }

    const res = await fetch(`${ASANA_BASE}/tasks/${taskId}`, {
      method: 'PUT',
      headers: asanaHeaders(this.accessToken),
      body: JSON.stringify({ data: patch })
    });
    const json = await res.json();
    return this.normalizeTask(json.data);
  }

  async deleteTask(taskId: string): Promise<boolean> {
    try {
      if (this.useMcp) {
        await mcp__claude_ai_Asana__asana_delete_task({ task_id: taskId });
        return true;
      }
      const res = await fetch(`${ASANA_BASE}/tasks/${taskId}`, {
        method: 'DELETE',
        headers: asanaHeaders(this.accessToken)
      });
      return res.ok;
    } catch {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTASKS
  // ═══════════════════════════════════════════════════════════════════════════

  async createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput> {
    const body = {
      data: {
        name: input.name,
        notes: input.description,
        parent: parentId,
        ...(this.workspaceId && { workspace: this.workspaceId })
      }
    };

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_create_task({
        name: input.name,
        notes: input.description,
        parent: parentId,
        workspace: this.workspaceId
      });
      return this.normalizeTask(JSON.parse(result.content[0].text).data);
    }

    const res = await fetch(`${ASANA_BASE}/tasks`, {
      method: 'POST',
      headers: asanaHeaders(this.accessToken),
      body: JSON.stringify(body)
    });
    const json = await res.json();
    return this.normalizeTask(json.data);
  }

  async getSubtasks(parentId: string): Promise<TaskOutput[]> {
    const fields = 'gid,name,notes,completed,due_on,assignee,permalink_url';

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_get_tasks({
        parent: parentId,
        opt_fields: fields
      });
      return (JSON.parse(result.content[0].text).data ?? []).map((t: any) =>
        this.normalizeTask(t)
      );
    }

    const res = await fetch(
      `${ASANA_BASE}/tasks/${parentId}/subtasks?opt_fields=${fields}`,
      { headers: asanaHeaders(this.accessToken) }
    );
    const json = await res.json();
    return (json.data ?? []).map((t: any) => this.normalizeTask(t));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════

  async addComment(taskId: string, comment: string): Promise<CommentOutput> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_create_task_story({
        task_id: taskId,
        text: comment
      });
      const story = JSON.parse(result.content[0].text).data ?? {};
      return this.normalizeStory(story, comment);
    }

    const res = await fetch(`${ASANA_BASE}/tasks/${taskId}/stories`, {
      method: 'POST',
      headers: asanaHeaders(this.accessToken),
      body: JSON.stringify({ data: { text: comment } })
    });
    const json = await res.json();
    return this.normalizeStory(json.data ?? {}, comment);
  }

  async getComments(taskId: string): Promise<CommentOutput[]> {
    const fields = 'gid,text,created_by,created_by.name,created_at,type';

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_get_stories_for_task({
        task_id: taskId,
        opt_fields: fields
      });
      return (JSON.parse(result.content[0].text).data ?? [])
        .filter((s: any) => s.type === 'comment')
        .map((s: any) => this.normalizeStory(s, s.text));
    }

    const res = await fetch(
      `${ASANA_BASE}/tasks/${taskId}/stories?opt_fields=${fields}`,
      { headers: asanaHeaders(this.accessToken) }
    );
    const json = await res.json();
    return (json.data ?? [])
      .filter((s: any) => s.type === 'comment')
      .map((s: any) => this.normalizeStory(s, s.text));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> {
    // Asana usa completed: true/false; seções do projeto para workflows intermediários
    return this.updateTask(taskId, { status });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSCA
  // ═══════════════════════════════════════════════════════════════════════════

  async searchTasks(query: SearchQuery): Promise<TaskOutput[]> {
    const fields = 'gid,name,notes,completed,due_on,assignee,permalink_url';
    const params: Record<string, string> = {
      opt_fields: fields,
      ...(this.workspaceId && { workspace: this.workspaceId })
    };
    if (query.text) params['text'] = query.text;
    if (query.projectId) params['projects.any'] = query.projectId;
    if (query.assignee) params['assignee.any'] = query.assignee;
    if (query.status?.includes('done')) params['completed'] = 'true';
    if (query.status?.includes('todo')) params['completed'] = 'false';

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_search_tasks({
        workspace: this.workspaceId,
        text: query.text,
        projects_any: query.projectId,
        assignee_any: query.assignee,
        completed: query.status?.includes('done') ? true : undefined,
        opt_fields: fields
      });
      return (JSON.parse(result.content[0].text).data ?? [])
        .slice(0, query.limit ?? 50)
        .map((t: any) => this.normalizeTask(t));
    }

    const qs = new URLSearchParams(params).toString();
    const res = await fetch(
      `${ASANA_BASE}/workspaces/${this.workspaceId}/tasks/search?${qs}`,
      { headers: asanaHeaders(this.accessToken) }
    );
    const json = await res.json();
    return (json.data ?? [])
      .slice(0, query.limit ?? 50)
      .map((t: any) => this.normalizeTask(t));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJETOS
  // ═══════════════════════════════════════════════════════════════════════════

  async getProjectList(): Promise<ProjectOutput[]> {
    const fields = 'gid,name,notes,permalink_url,archived';

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_get_projects({
        workspace: this.workspaceId,
        opt_fields: fields
      });
      return (JSON.parse(result.content[0].text).data ?? []).map((p: any) =>
        this.normalizeProject(p)
      );
    }

    const res = await fetch(
      `${ASANA_BASE}/projects?workspace=${this.workspaceId}&opt_fields=${fields}`,
      { headers: asanaHeaders(this.accessToken) }
    );
    const json = await res.json();
    return (json.data ?? []).map((p: any) => this.normalizeProject(p));
  }

  async getProject(projectId: string): Promise<ProjectOutput> {
    const fields = 'gid,name,notes,permalink_url,archived';

    if (this.useMcp) {
      const result = await mcp__claude_ai_Asana__asana_get_project({
        project_id: projectId,
        opt_fields: fields
      });
      return this.normalizeProject(JSON.parse(result.content[0].text).data ?? {});
    }

    const res = await fetch(
      `${ASANA_BASE}/projects/${projectId}?opt_fields=${fields}`,
      { headers: asanaHeaders(this.accessToken) }
    );
    const json = await res.json();
    return this.normalizeProject(json.data ?? {});
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  validateTaskId(taskId: string): boolean {
    // Asana GIDs: 15+ dígitos numéricos
    return /^\d{15,}$/.test(taskId);
  }

  getProviderFromTaskId(taskId: string): TaskManagerProvider | null {
    return this.validateTaskId(taskId) ? 'asana' : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  private normalizeTask(raw: any): TaskOutput {
    return {
      id: raw.gid,
      provider: 'asana',
      name: raw.name,
      description: raw.notes ?? '',
      status: raw.completed ? 'done' : 'todo',
      statusRaw: raw.completed ? 'Completed' : 'Not Completed',
      url: raw.permalink_url ?? `https://app.asana.com/0/0/${raw.gid}`,
      createdAt: raw.created_at ?? new Date().toISOString(),
      updatedAt: raw.modified_at ?? new Date().toISOString(),
      dueDate: raw.due_on,
      startDate: raw.start_on,
      assignees: raw.assignee
        ? [{ id: raw.assignee.gid, name: raw.assignee.name, email: raw.assignee.email }]
        : [],
      tags: (raw.tags ?? []).map((t: any) => t.name),
      parent: raw.parent?.gid,
      projectId: raw.projects?.[0]?.gid,
      projectName: raw.projects?.[0]?.name
    };
  }

  private normalizeStory(raw: any, text: string): CommentOutput {
    return {
      id: raw.gid ?? String(Date.now()),
      text,
      author: {
        id: raw.created_by?.gid ?? 'unknown',
        name: raw.created_by?.name ?? 'Unknown'
      },
      createdAt: raw.created_at ?? new Date().toISOString()
    };
  }

  private normalizeProject(raw: any): ProjectOutput {
    return {
      id: raw.gid,
      name: raw.name,
      description: raw.notes,
      url: raw.permalink_url,
      archived: raw.archived,
      workspaceId: this.workspaceId
    };
  }
}
```

---

## 📊 Mapeamento de Campos

### Task Fields

| Interface | Asana REST | Notas |
|-----------|------------|-------|
| `name` | `name` | Direto |
| `description` | `notes` | Texto plano ou HTML |
| `markdownDescription` | `html_notes` | Subset HTML aceito |
| `status` | `completed` | Boolean |
| `priority` | — | Não nativo; usar custom fields ou tags |
| `dueDate` | `due_on` | Formato `YYYY-MM-DD` |
| `startDate` | `start_on` | Formato `YYYY-MM-DD` |
| `assignees` | `assignee` | Apenas 1 por task |
| `tags` | `tags[].name` | Array de strings |
| `projectId` | `projects[0].gid` | GID numérico |

### Status Mapping

| Interface | Asana |
|-----------|-------|
| `todo`, `backlog`, `in_progress`, `review` | `completed: false` |
| `done`, `closed` | `completed: true` |

> Workflows intermediários (ex: "Em Revisão") devem ser modelados via **Sections** do projeto.
> O adapter não gerencia seções diretamente — use a API REST `POST /sections/{section_gid}/addTask` quando necessário.

---

## ⚠️ Limitações do Asana

| Limitação | Detalhe |
|-----------|---------|
| 1 assignee por task | Ao contrário de ClickUp/Linear |
| Status binário | `completed` true/false; seções para granularidade |
| Sem prioridade nativa | Usar custom fields ou tags como substituto |
| GIDs numéricos longos | 15+ dígitos; não confundir com outros providers |
| Rate limit | 150 req/min por token; evite N+1 com `opt_fields` |

---

## 🧪 Exemplos de Uso

```typescript
// Via Factory (TASK_MANAGER_PROVIDER=asana)
const tm = getTaskManager();

// Criar task
const task = await tm.createTask({
  name: 'Nova Feature',
  description: 'Implementar funcionalidade X',
  projectId: '1234567890123456'
});

// Criar subtask
const subtask = await tm.createSubtask(task.id, {
  name: 'Fase 1: Setup'
});

// Marcar como concluída
await tm.updateStatus(subtask.id, 'done');

// Comentar com timestamp
await tm.addComment(
  task.id,
  `[${new Date().toISOString()}] Desenvolvimento iniciado.`
);

// Buscar tasks abertas do projeto
const open = await tm.searchTasks({
  projectId: '1234567890123456',
  status: ['todo', 'in_progress'],
  limit: 20
});
```

---

## 📚 Referências

- [Asana REST API Docs](https://developers.asana.com/reference/rest-api-reference)
- [Asana API: Field Selection (opt_fields)](https://developers.asana.com/docs/inputoutput-options)
- [Interface ITaskManager](../interface.md)
- [Types](../types.md)
- [SDAAL — Padrão-pai](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 2.0.0
**Atualizado em**: 2026-06-13
