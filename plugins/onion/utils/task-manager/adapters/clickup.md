# 🔵 ClickUp Adapter

## 🎯 Propósito

Implementação do `ITaskManager` para ClickUp, seguindo o padrão **SDAAL** (ver specification-driven-ai-abstraction-layer.md).

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
| Obter task | GET | `/task/{task_id}?include_subtasks=true` ⚠️ **não** `subtasks=true` (medido 2026-10-02: o legado devolve a task SEM o campo) |
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

> ⚠️ **A grafia dos nomes foi corrigida em 2026-10-02 — a anterior não resolvia em lugar nenhum.**
> As tabelas e o código citavam `mcp_ClickUp_clickup_*`, convenção da era **Cursor**, de quando o
> Onion ainda buscava agnosticismo. No Claude Code uma ferramenta MCP se chama
> `mcp__<alias-do-servidor>__<nome-da-ferramenta>`, e o nome documentado pelo ClickUp é
> `clickup_*` — logo `mcp__clickup__clickup_get_task`, **se** o servidor estiver registrado com o
> alias `clickup`. **O alias é escolha de quem configura**: a tabela abaixo mostra o padrão, não
> uma garantia. Confira o nome efetivo no seu ambiente antes de ligar o transporte MCP.
>
> - **Endpoint do servidor remoto:** `https://mcp.clickup.com/mcp`.
> - **NADA IMPEDE A GRAFIA ANTIGA DE VOLTAR, e isto é teto declarado:** a REGRA 10 (Tool MCP de
>   provider direto em comando/agente) conhece o padrão `mcp_ClickUp_` **mas allowlista o caminho
>   `*/utils/task-manager/adapters/*`** — foi por essa porta que 19 menções sobreviveram desde a era
>   Cursor sem ninguém notar. A correção de hoje é **one-off**; o mecanismo que a tornaria
>   permanente (cobrar a FORMA `mcp__<alias>__` dentro do adapter) precisa de guarda e caso de
>   bancada próprios. Gatilho nomeado: a próxima grafia antiga que aparecer num adapter.
> - **Inconsistência DECLARADA, não resolvida:** a documentação do provider lista uma ferramenta de
>   remoção cujo nome divergia entre páginas. Não medi qual responde, então `delete_task` fica
>   marcado abaixo como **não-verificado** — e o caminho API (`DELETE /task/{id}`), que é o default,
>   não depende disso.

Quando ativo, substitui os `fetch` calls pelas funções MCP equivalentes:

| Via API (padrão) | Via MCP (opcional) |
|------------------|--------------------|
| `POST /list/{id}/task` | `mcp__clickup__clickup_create_task(...)` |
| `GET /task/{id}` | `mcp__clickup__clickup_get_task(...)` |
| `PUT /task/{id}` | `mcp__clickup__clickup_update_task(...)` |
| `DELETE /task/{id}` | `mcp__clickup__clickup_delete_task(...)` ⚠️ nome **não-verificado** |
| `POST /task/{id}/comment` | `mcp__clickup__clickup_create_task_comment(...)` |
| `GET /task/{id}/comment` | `mcp__clickup__clickup_get_task_comments(...)` |
| `GET /team/{wid}/task` | `mcp__clickup__clickup_search(...)` |
| Hierarquia workspace | `mcp__clickup__clickup_get_workspace_hierarchy(...)` |
| `GET /list/{id}` | `mcp__clickup__clickup_get_list(...)` |

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
 * - Descrições de tasks: Markdown nativo (campo markdown_content no REQUEST;
 *   markdown_description existe só na RESPOSTA — confundir os dois foi o bug de 2026-10-02)
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
      markdown_content: input.markdownDescription,   // REQUEST usa markdown_content
      priority: this.mapPriorityToClickUp(input.priority),
      // As flags derivam do valor CONVERTIDO, nunca do input cru: um ISO inválido deixava
      // `due_date_time: true` sem `due_date`. E `start_date` tinha a mesma exposição ao fuso que
      // `due_date` e estava sem flag — o comentário de toClickUpMs chamava a flag de OBRIGATÓRIA
      // e eu a aplicara a metade dos campos.
      due_date: this.toClickUpMs(input.dueDate),      // API quer Unix ms, não ISO
      due_date_time: this.toClickUpMs(input.dueDate) !== undefined ? true : undefined,
      start_date: this.toClickUpMs(input.startDate),
      start_date_time: this.toClickUpMs(input.startDate) !== undefined ? true : undefined,
      time_estimate: input.timeEstimate ? input.timeEstimate * 60000 : undefined,
      assignees: input.assignees,
      tags: input.tags
    };

    if (this.useMcp) {
      // Via MCP
      const result = await mcp__clickup__clickup_create_task({
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
      const result = await mcp__clickup__clickup_get_task({
        workspace_id: this.workspaceId,
        task_id: taskId,
        include_subtasks: true
      });
      return this.normalizeTask(JSON.parse(result.content[0].text));
    }

    // include_subtasks (não `subtasks`): medido ao vivo em 2026-10-02 — `include_subtasks=true`
    // devolveu 42 subtasks; `subtasks=true` devolveu a task SEM o campo. Com o parâmetro
    // legado, getTask/getSubtasks retornam VAZIO e quebram /onion-engineering:start, /onion-engineering:work,
    // validate-phase-sync e checklist-sync em todo repo que use este provider.
    const data = await this.api<any>('GET', `/task/${taskId}?include_subtasks=true`);
    return this.normalizeTask(data);
  }

  async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
    // STATUS É CONFIGURADO POR LIST — não existe vocabulário global no ClickUp. Por isso o nome
    // canônico só se resolve CONTRA a List da task (decisão selada pelo maestro 2026-10-02). Sem
    // sinônimo casando, o campo é OMITIDO e a task mantém o status atual: um status inventado
    // devolve `400 Status not found`, e inventar silenciosamente seria pior que não mexer.
    const resolvedStatus = updates.status
      ? await this.resolveStatusForTask(taskId, updates.status)
      : undefined;

    const payload = {
      name: updates.name,
      description: updates.description,
      markdown_content: updates.markdownDescription,  // REQUEST usa markdown_content
      status: resolvedStatus,
      priority: updates.priority ? this.mapPriorityToClickUp(updates.priority) : undefined,
      due_date: this.toClickUpMs(updates.dueDate),
      due_date_time: this.toClickUpMs(updates.dueDate) !== undefined ? true : undefined,
      start_date: this.toClickUpMs(updates.startDate),
      start_date_time: this.toClickUpMs(updates.startDate) !== undefined ? true : undefined,
      time_estimate: updates.timeEstimate ? updates.timeEstimate * 60000 : undefined,
      // ⚠️ `assignees` vai como ARRAY SIMPLES, e isto é TETO DECLARADO, não medição: o adendo do
      // adotante registra que `{add, rem}` FUNCIONA e que o array simples TAMBÉM devolve 200 — e
      // "devolve 200" foi exatamente o critério que condenou as tags. Ninguém mediu o EFEITO do
      // array simples aqui. Gatilho: a próxima medição ao vivo resolve, ou isto migra para {add,rem}.
      assignees: updates.assignees
      // ⚠️ TAGS NÃO VÃO NO BODY DO PUT — medido ao vivo por um adotante em 2026-10-02 (24 chamadas
      // REST, tasks criadas e apagadas, limpeza confirmada por 404): tags no corpo do PUT devolvem
      // 200 E NÃO FAZEM NADA. Só `POST /task/{id}/tag/{name}` e `DELETE /task/{id}/tag/{name}`
      // mudam tags. Eu tinha "consertado" isto ADICIONANDO tags aqui — campo que silenciosamente
      // não faz nada é PIOR que campo ausente, porque parece consertado. Quem precisa mexer em tag
      // chama o endpoint dedicado; a `under-review` do /onion-engineering:pr nunca seria aplicada por aqui.
    };

    // `tags` CONTINUA no contrato de UpdateTaskInput mas NÃO é enviada (ver a nota no payload).
    // Descartar em silêncio é o mesmo defeito que o PUT da API tem — só movido para cá. Avisa.
    if (updates.tags && updates.tags.length > 0) {
      console.warn(`⚠️  ClickUp: 'tags' NÃO é aplicada por updateTask (o body do PUT devolve 200 sem efeito). Use POST/DELETE /task/${taskId}/tag/{name}. Tags ignoradas: ${updates.tags.join(', ')}`);
    }

    if (this.useMcp) {
      const result = await mcp__clickup__clickup_update_task({
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
        await mcp__clickup__clickup_delete_task({
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
      markdown_content: input.markdownDescription,   // REQUEST usa markdown_content
      priority: this.mapPriorityToClickUp(input.priority),
      tags: input.tags,
      parent: parentId   // ← Torna subtask
    };

    if (this.useMcp) {
      const result = await mcp__clickup__clickup_create_task({
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
      const result = await mcp__clickup__clickup_create_task_comment({
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
      const result = await mcp__clickup__clickup_get_task_comments({
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
      const result = await mcp__clickup__clickup_search({
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
      const result = await mcp__clickup__clickup_get_workspace_hierarchy({
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
      const result = await mcp__clickup__clickup_get_list({
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

  // ENTRADA (ClickUp → Onion). Tabela PRÓPRIA, deliberadamente NÃO derivada de STATUS_SYNONYMS:
  // os dois sentidos resolvem problemas diferentes. Na saída é 1→N com filtro de disponibilidade
  // (qual dos meus sinônimos esta List aceita); na entrada é N→1 com POLÍTICA DE COLISÃO — 'closed'
  // é sinônimo de `done` E nome próprio de `closed`, e só uma ordem explícita decide. Derivar por
  // inversão daria o empate ao primeiro canônico iterado, trocando `closed → closed` por
  // `closed → done` sem que ninguém notasse. `statusRaw` preserva sempre a grafia original.
  private normalizeStatus(clickupStatus?: string): TaskStatus {
    const statusMap: Record<string, TaskStatus> = {
      'backlog': 'backlog',
      'bakclog': 'backlog',   // typo comum no ClickUp
      'ideas': 'backlog',
      'icebox': 'backlog',
      'to do': 'todo',
      'todo': 'todo',
      'open': 'todo',
      'not started': 'todo',
      'pending': 'todo',
      'in refinement': 'backlog',
      'refinement': 'backlog',
      'in progress': 'in_progress',
      'in-progress': 'in_progress',
      // `pause` existe na List medida e não tem canônico próprio no Onion (não há `blocked`).
      // `in_progress` é o menos errado — a task COMEÇOU — e `statusRaw` preserva `pause` para
      // quem precisar distinguir. Teto declarado, não omissão.
      'pause': 'in_progress',
      'paused': 'in_progress',
      'on hold': 'in_progress',
      'doing': 'in_progress',
      'wip': 'in_progress',
      'started': 'in_progress',
      'in review': 'review',
      'review': 'review',
      'pull request': 'review',
      'pr': 'review',
      'code review': 'review',
      'reviewing': 'review',
      'qa': 'review',
      'testing': 'review',
      'done': 'done',
      'complete': 'done',
      'completed': 'done',
      'resolved': 'done',
      'closed': 'closed',       // nome próprio vence o sinônimo de `done` — ver a nota acima
      'archived': 'closed',
      'canceled': 'canceled',
      'cancelled': 'canceled',
      'wont do': 'canceled',
      "won't do": 'canceled'
    };
    const hit = statusMap[clickupStatus?.toLowerCase() || ''];
    if (hit) return hit;
    // FALLBACK QUE AVISA. O anterior devolvia `todo` em silêncio, então uma List com nomes próprios
    // ('pull request', 'in refinement', 'pause') fazia `validate-phase-sync` e `checklist-sync`
    // lerem `todo` para tasks em revisão — e nada apontava. A escrita já avisava; a leitura não.
    if (clickupStatus) {
      console.warn(`⚠️  ClickUp: status '${clickupStatus}' não tem canônico Onion — lido como 'todo'. statusRaw preserva o original; acrescente o sinônimo se este nome for comum na sua List.`);
    }
    return 'todo';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS POR LIST — a decisão selada (maestro, 2026-10-02)
  //
  // POR QUE NÃO HÁ TABELA FIXA: no ClickUp o conjunto de status é propriedade da LIST (ou do
  // Space/Folder de onde ela herda), não do workspace. A versão anterior mapeava `review → 'review'`
  // às cegas; a medição ao vivo do adotante mostrou uma List cujos status eram
  // `to do / in progress / complete` — ou seja, `review` NÃO EXISTIA lá, e todo `updateStatus` do
  // /onion-engineering:pr devolvia `400`. Mapa fixo contra vocabulário configurável é o mesmo erro de
  // `priority: 'high'`: parece certo e falha em runtime.
  //
  // O QUE FICA CANÔNICO: os `TaskStatus` do Onion (`review` inclusive) seguem a moeda interna. O
  // adapter TRADUZ na fronteira, por sinônimos, contra o que a List de fato oferece.
  // ⚠️ A ORDEM É O VEREDITO, e um Elenxo me pegou nela: a primeira versão desta tabela punha
  // `testing` em `review` e OMITIA `pull request` — logo, na List que o adotante mediu
  // (`… testing, pull request, done, Closed`), `/onion-engineering:pr` moveria a task para **testing**.
  // Trocar um `400` por um status ERRADO E SILENCIOSO é piorar: o 400 avisa, o status errado não.
  // Os sinônimos vão do mais específico ao mais genérico, e os nomes da List medida vêm primeiro.
  private static readonly STATUS_SYNONYMS: Record<TaskStatus, string[]> = {
    'backlog':     ['backlog', 'bakclog', 'in refinement', 'refinement', 'ideas', 'icebox'],
    'todo':        ['to do', 'todo', 'open', 'not started', 'pending'],
    'in_progress': ['in progress', 'in-progress', 'doing', 'wip', 'started'],
    'review':      ['review', 'in review', 'pull request', 'code review', 'reviewing', 'qa', 'testing'],
    'done':        ['done', 'complete', 'completed', 'closed', 'resolved'],
    'closed':      ['closed', 'done', 'complete', 'completed', 'archived'],
    'canceled':    ['canceled', 'cancelled', 'wont do', "won't do", 'closed']
  };

  // Cache POR SESSÃO, nunca persistido: status de List muda por configuração do usuário, e um
  // cache durável mentiria depois. Chave = listId.
  private statusCache = new Map<string, string[]>();

  private async listStatuses(listId: string): Promise<string[]> {
    const cached = this.statusCache.get(listId);
    if (cached) return cached;
    const list = await this.api<any>('GET', `/list/${listId}`);
    const names: string[] = (list?.statuses || [])
      .map((s: any) => s?.status)
      .filter((n: any): n is string => typeof n === 'string' && n.length > 0);
    this.statusCache.set(listId, names);
    return names;
  }

  // Resolve o status canônico para o nome REAL da List da task. `undefined` = não há sinônimo,
  // o chamador OMITE o campo (mantém o status atual) e o aviso diz o que a List oferece.
  private async resolveStatusForTask(taskId: string, status: TaskStatus): Promise<string | undefined> {
    // FAIL-CLOSED, e esta foi uma correção de Elenxo: a 1ª versão tinha `catch { listId = undefined }`,
    // que transformava falha de REDE TRANSITÓRIA em "esta List não tem o status" — e a operação
    // devolvia sucesso com o status silenciosamente não aplicado. Erro de transporte tem de subir;
    // ausência de status é outra coisa e tem o seu próprio aviso abaixo.
    // TETO: este caminho não ramifica para MCP (os irmãos ramificam). Com TASK_MANAGER_TRANSPORT=mcp
    // a resolução de status usa a REST API. Declarado, não escondido.
    const raw = await this.api<any>('GET', `/task/${taskId}`);
    const listId: string | undefined = raw?.list?.id;
    if (!listId) {
      console.warn(`⚠️  ClickUp: não resolvi a List da task ${taskId} — status '${status}' NÃO aplicado (a task mantém o atual).`);
      return undefined;
    }

    const available = await this.listStatuses(listId);
    if (available.length === 0) {
      console.warn(`⚠️  ClickUp: a List ${listId} não declarou status — '${status}' NÃO aplicado.`);
      return undefined;
    }

    const byLower = new Map(available.map(n => [n.toLowerCase(), n]));
    for (const syn of ClickUpAdapter.STATUS_SYNONYMS[status] || []) {
      const hit = byLower.get(syn.toLowerCase());
      if (hit) return hit;   // devolve a grafia EXATA da List (o ClickUp é sensível a ela)
    }

    console.warn(
      `⚠️  ClickUp: a List ${listId} não tem status equivalente a '${status}'. ` +
      `Disponíveis: ${available.join(' | ')}. O campo foi OMITIDO — a task mantém o status atual ` +
      `(mandar um nome inexistente devolve 400).`
    );
    return undefined;
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

  // ISO (o tipo do domínio é `string`) → Unix MILISSEGUNDOS, que é o que a API aceita. Enviar o ISO
  // cru era o bug carregado até 2026-10-02: a API não reclama, apenas não aplica a data.
  //
  // ⚠️ E O PAR `due_date_time: true` É OBRIGATÓRIO, medido ao vivo por um adotante em 2026-10-02:
  // com `due_date_time=false` (o default) o ClickUp NORMALIZA para 07:00 e a data PODE CAIR NO DIA
  // ANTERIOR pelo fuso do workspace. Mandar o timestamp exato com a flag ligada é o único jeito de
  // a data voltar igual à que se enviou — confirmado: `due_date`/`time_estimate` em ms com a flag
  // voltam exatos.
  private toClickUpMs(iso?: string | null): number | undefined {
    if (!iso) return undefined;
    const ms = Date.parse(iso);
    // NaN é entrada inválida: devolver undefined (campo omitido) em vez de mandar NaN, que a API
    // aceitaria como erro silencioso. Guarda que não sabe nunca afirma — omite.
    return Number.isNaN(ms) ? undefined : ms;
  }

  // A API quer INTEGER (1 urgent … 4 low), nunca string — bug carregado ate 2026-10-02.
  private mapPriorityToClickUp(priority?: TaskPriority): number | undefined {
    if (!priority) return undefined;
    // ⚠️ O MAPA ANTIGO ERA IDENTIDADE ('urgent' → 'urgent'): ele NUNCA mapeou nada, só repassava a
    // string do domínio — e a API responde `400 Priority invalid` a string. Medido ao vivo em
    // 2026-10-02: só INTEIRO 1–4 é aceito. Trocar apenas a assinatura para `number` teria feito o
    // tipo MENTIR sobre um corpo que devolve string; a cura é o mapa de verdade.
    const priorityMap: Record<TaskPriority, number> = {
      'urgent': 1,
      'high': 2,
      'normal': 3,
      'low': 4
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
| `markdownDescription` | `markdown_content` (request) | Com formatação. `markdown_description` é da RESPOSTA |
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

### Descrições de Tasks (request: `markdown_content`)

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

## 🔧 Operação (exemplos, bulk, hierarquia, checklists, troubleshooting)

Movidos para o irmão **[`clickup-operacao.md`](clickup-operacao.md)** em 2026-10-02, por
*progressive disclosure* (`sdaal.md` §14.5): exemplos de uso, operações em lote, hierarquia de 3
níveis, checklists nativos, troubleshooting e best practices. Este arquivo ficou com o **contrato e
a implementação** — e com as **Notas Operacionais** abaixo, que são medição, não receita.


## ⚠️ Notas Operacionais

- **`CLICKUP_WORKSPACE_ID`** é obrigatório para busca (`searchTasks`) e listagem de projetos (`getProjectList`). Se ausente, essas operações lançam erro descritivo.
- **Datas** no ClickUp são timestamps em milissegundos (inteiros). Converter com `new Date(parseInt(raw.due_date)).toISOString()`.
- **IDs de tasks** ClickUp: 9 caracteres alfanuméricos (ex: `86abc1234`).
- **Status são propriedade da LIST**, não do workspace — e isso não é detalhe de borda: medido ao vivo
  em 2026-10-02, uma List real oferecia `to do / in progress / complete`, sem nenhum `review`, e todo
  `updateStatus` do `/onion-engineering:pr` devolvia **`400 Status not found`**. Por isso não há mapa fixo de
  saída: `resolveStatusForTask` lê `GET /list/{id}`, casa por sinônimos (`STATUS_SYNONYMS`) e devolve a
  **grafia exata da List**. Sem equivalente, o campo é **omitido com aviso** e a task mantém o status
  atual — nunca se inventa nome. `statusRaw` sempre preserva o valor original do provider.
- **Prioridade**: **só INTEIRO `1 | 2 | 3 | 4`** (1 urgent … 4 low). String **NÃO** é aceita —
  medido ao vivo em 2026-10-02: `priority: "high"` devolve **`400 Priority invalid`**. Esta linha
  dizia o contrário até hoje, 245 linhas depois do comentário que registra a medição; era ela que
  alguém lia para decidir.

---

## 📚 Referências

- [ClickUp REST API v2](https://clickup.com/api)
- [Interface ITaskManager](../interface.md)
- [Types](../types.md)
- [Factory](../factory.md)
- SDAAL — padrão-pai

---

**Versão**: 2.1.0
**Atualizado em**: 2026-10-02
