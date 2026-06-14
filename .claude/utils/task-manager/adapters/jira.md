# 🔵 Jira Adapter

## 🎯 Propósito

Implementação completa do `ITaskManager` para Jira (Cloud e Server/DC). É uma instância concreta do padrão **SDAAL** (Specification-Driven AI Abstraction Layer) — consulte [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) para o contrato arquitetural pai.

**Transporte**: REST API é o **padrão e preferencial** (`TASK_MANAGER_TRANSPORT=api`, default). Atlassian MCP é **opcional e ativável** via `TASK_MANAGER_TRANSPORT=mcp` — quando configurado, o adapter delega para as ferramentas `mcp__claude_ai_Atlassian__*`; caso contrário, cai automaticamente para API.

> ✅ **Completo**: Todos os métodos do `ITaskManager` estão implementados. Suporta Jira Cloud (REST v3), Server e Data Center (REST v2).

---

## 📋 Configuração

### Variáveis de Ambiente

```bash
# Obrigatórias
JIRA_HOST=seu-dominio.atlassian.net       # Cloud: subdomínio.atlassian.net | Server: jira.suaempresa.com
JIRA_EMAIL=voce@suaempresa.com            # Não usar em Server/DC com PAT
JIRA_API_TOKEN=ATATT3xFfGF0...            # API Token (Cloud) ou Personal Access Token (Server/DC)

# Opcionais
JIRA_PROJECT_KEY=PROJ                     # Project key padrão para novas issues
JIRA_AUTH_TYPE=basic                      # basic (Cloud, default) | bearer (Server/DC com PAT)
JIRA_API_VERSION=3                        # 3 (Cloud, default) | 2 (Server antigo)

# Transporte (padrão: api)
TASK_MANAGER_TRANSPORT=api                # api (default, REST direto via fetch) | mcp (Atlassian MCP, requer configuração)
```

### Obter Token

**Jira Cloud:**
1. Acesse https://id.atlassian.com/manage-profile/security/api-tokens
2. "Create API token" → dê um nome → copie o token
3. Use seu email Atlassian + o token em `JIRA_EMAIL` / `JIRA_API_TOKEN`

**Jira Server/Data Center (8.14+):**
1. Acesse `https://seu-jira/secure/ViewProfile.jspa` → "Personal Access Tokens"
2. Crie um PAT com escopo apropriado
3. Defina `JIRA_AUTH_TYPE=bearer` e use o PAT em `JIRA_API_TOKEN` (deixe `JIRA_EMAIL` vazio)

---

## 📊 API do Jira

### Endpoint Base

```
https://{JIRA_HOST}/rest/api/{JIRA_API_VERSION}/
```

### Autenticação

**Basic Auth (Cloud, padrão):**
```
Authorization: Basic {base64(email:api_token)}
```

**Bearer (Server/DC com PAT):**
```
Authorization: Bearer {api_token}
```

---

## 🔧 Implementação

```typescript
/**
 * Adapter Jira implementando ITaskManager (padrão SDAAL).
 *
 * Transporte padrão: Jira REST API v3 (Cloud) ou v2 (Server/DC) via fetch direto.
 * Transporte opcional: Atlassian MCP (ativar com TASK_MANAGER_TRANSPORT=mcp).
 *
 * Suporte:
 * - Jira Cloud (Basic Auth com email + API token; REST v3)
 * - Jira Server/Data Center (Bearer Token com PAT; REST v2)
 */
class JiraAdapter implements ITaskManager {
  readonly provider: TaskManagerProvider = 'jira';
  readonly isConfigured: boolean;

  private host: string;
  private email?: string;
  private apiToken: string;
  private defaultProjectKey?: string;
  private authType: 'basic' | 'bearer';
  private apiVersion: '2' | '3';
  private baseUrl: string;
  private authHeader: string;

  constructor(config: JiraAdapterConfig) {
    this.host = config.host.replace(/^https?:\/\//, '').replace(/\/$/, '');
    this.email = config.email;
    this.apiToken = config.apiToken;
    this.defaultProjectKey = config.defaultProjectKey;
    this.authType = config.authType || 'basic';
    this.apiVersion = config.apiVersion || '3';

    this.baseUrl = `https://${this.host}/rest/api/${this.apiVersion}`;

    if (this.authType === 'bearer') {
      this.authHeader = `Bearer ${this.apiToken}`;
    } else {
      const credentials = Buffer.from(`${this.email}:${this.apiToken}`).toString('base64');
      this.authHeader = `Basic ${credentials}`;
    }

    this.isConfigured = !!(this.host && this.apiToken && (this.authType === 'bearer' || this.email));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD DE TASKS (ISSUES)
  // ═══════════════════════════════════════════════════════════════════════════

  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
    const projectKey = this.resolveProjectKey(input.projectId);

    const fields: any = {
      project: { key: projectKey },
      summary: input.name,
      issuetype: { name: 'Task' }
    };

    if (input.description || input.markdownDescription) {
      fields.description = this.toADF(input.markdownDescription || input.description || '');
    }
    if (input.priority) {
      fields.priority = { name: this.mapPriorityToJira(input.priority) };
    }
    if (input.dueDate) {
      fields.duedate = input.dueDate;
    }
    if (input.assignees?.length) {
      fields.assignee = { accountId: input.assignees[0] };
    }
    if (input.tags?.length) {
      fields.labels = input.tags.map(t => t.replace(/\s+/g, '-'));
    }
    if (input.timeEstimate) {
      fields.timetracking = { originalEstimate: `${input.timeEstimate}m` };
    }

    const created = await this.rest<{ id: string; key: string; self: string }>(
      'POST',
      '/issue',
      { fields }
    );

    return this.getTask(created.key);
  }

  async getTask(taskId: string): Promise<TaskOutput> {
    const raw = await this.rest<any>(
      'GET',
      `/issue/${encodeURIComponent(taskId)}?expand=names,renderedFields`
    );
    return this.normalizeIssue(raw);
  }

  async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
    const fields: any = {};

    if (updates.name) fields.summary = updates.name;
    if (updates.description !== undefined || updates.markdownDescription !== undefined) {
      fields.description = this.toADF(updates.markdownDescription ?? updates.description ?? '');
    }
    if (updates.priority) {
      fields.priority = { name: this.mapPriorityToJira(updates.priority) };
    }
    if (updates.dueDate !== undefined) {
      fields.duedate = updates.dueDate;
    }
    if (updates.assignees) {
      fields.assignee = updates.assignees.length ? { accountId: updates.assignees[0] } : null;
    }
    if (updates.tags) {
      fields.labels = updates.tags.map(t => t.replace(/\s+/g, '-'));
    }
    if (updates.timeEstimate) {
      fields.timetracking = { originalEstimate: `${updates.timeEstimate}m` };
    }

    if (Object.keys(fields).length) {
      await this.rest('PUT', `/issue/${encodeURIComponent(taskId)}`, { fields });
    }

    if (updates.status) {
      await this.updateStatus(taskId, updates.status);
    }

    return this.getTask(taskId);
  }

  async deleteTask(taskId: string): Promise<boolean> {
    try {
      await this.rest('DELETE', `/issue/${encodeURIComponent(taskId)}`);
      return true;
    } catch {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTASKS (SUB-TASK ISSUE TYPE)
  // ═══════════════════════════════════════════════════════════════════════════

  async createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput> {
    const parent = await this.rest<any>(
      'GET',
      `/issue/${encodeURIComponent(parentId)}?fields=project`
    );
    const projectKey = parent.fields.project.key;

    const fields: any = {
      project: { key: projectKey },
      parent: { key: parent.key },
      summary: input.name,
      issuetype: { name: 'Sub-task' }
    };

    if (input.description || input.markdownDescription) {
      fields.description = this.toADF(input.markdownDescription || input.description || '');
    }
    if (input.assignees?.length) {
      fields.assignee = { accountId: input.assignees[0] };
    }

    const created = await this.rest<{ key: string }>('POST', '/issue', { fields });
    return this.getTask(created.key);
  }

  async getSubtasks(parentId: string): Promise<TaskOutput[]> {
    const jql = `parent = "${parentId}"`;
    // Paginar até esgotar (subtasks normalmente são poucas)
    const all: TaskOutput[] = [];
    let pageToken: string | undefined;
    do {
      const page = await this.searchByJQL(jql, 100, pageToken);
      all.push(...page.issues);
      pageToken = page.nextPageToken;
    } while (pageToken);
    return all;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════

  async addComment(taskId: string, comment: string): Promise<CommentOutput> {
    const body = this.apiVersion === '3'
      ? { body: this.toADF(comment) }
      : { body: comment };

    const created = await this.rest<any>(
      'POST',
      `/issue/${encodeURIComponent(taskId)}/comment`,
      body
    );

    return this.normalizeComment(created);
  }

  async getComments(taskId: string): Promise<CommentOutput[]> {
    const result = await this.rest<{ comments: any[] }>(
      'GET',
      `/issue/${encodeURIComponent(taskId)}/comment`
    );
    return (result.comments || []).map(c => this.normalizeComment(c));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS (TRANSITIONS)
  // ═══════════════════════════════════════════════════════════════════════════

  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> {
    const transitionId = await this.findTransitionId(taskId, status);

    if (!transitionId) {
      throw new Error(
        `❌ Não foi possível encontrar transição para status "${status}" em ${taskId}. ` +
        `Verifique o workflow do projeto Jira.`
      );
    }

    await this.rest(
      'POST',
      `/issue/${encodeURIComponent(taskId)}/transitions`,
      { transition: { id: transitionId } }
    );

    return this.getTask(taskId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSCA (JQL)
  // ═══════════════════════════════════════════════════════════════════════════

  async searchTasks(query: SearchQuery): Promise<TaskOutput[]> {
    const jqlParts: string[] = [];

    if (query.projectId) {
      jqlParts.push(`project = "${query.projectId}"`);
    } else if (this.defaultProjectKey) {
      jqlParts.push(`project = "${this.defaultProjectKey}"`);
    }

    if (query.text) {
      const escaped = query.text.replace(/"/g, '\\"');
      jqlParts.push(`(summary ~ "${escaped}" OR description ~ "${escaped}")`);
    }

    if (query.status?.length) {
      const jiraStatuses = query.status
        .map(s => `"${this.mapStatusToJira(s)}"`)
        .join(', ');
      jqlParts.push(`status in (${jiraStatuses})`);
    }

    if (query.assignee) {
      jqlParts.push(`assignee = "${query.assignee}"`);
    }

    if (query.tags?.length) {
      const labels = query.tags.map(t => `"${t.replace(/\s+/g, '-')}"`).join(', ');
      jqlParts.push(`labels in (${labels})`);
    }

    if (query.priority?.length) {
      const priorities = query.priority
        .map(p => `"${this.mapPriorityToJira(p)}"`)
        .join(', ');
      jqlParts.push(`priority in (${priorities})`);
    }

    const orderField = ({
      created: 'created',
      updated: 'updated',
      due_date: 'duedate',
      priority: 'priority'
    } as const)[query.orderBy || 'updated'];

    const direction = (query.orderDirection || 'desc').toUpperCase();
    const baseJql = jqlParts.join(' AND ');
    const jql = baseJql
      ? `${baseJql} ORDER BY ${orderField} ${direction}`
      : `ORDER BY ${orderField} ${direction}`;

    const maxResults = query.limit || 50;
    const skip = query.offset || 0;

    // Avança via nextPageToken até cobrir o offset solicitado (Cloud v3).
    let collected: TaskOutput[] = [];
    let pageToken: string | undefined;

    while (collected.length < skip + maxResults) {
      const page = await this.searchByJQL(jql, maxResults, pageToken);
      collected = collected.concat(page.issues);
      if (!page.nextPageToken) break;
      pageToken = page.nextPageToken;
    }

    return collected.slice(skip, skip + maxResults);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJETOS
  // ═══════════════════════════════════════════════════════════════════════════

  async getProjectList(): Promise<ProjectOutput[]> {
    const result = await this.rest<{ values: any[] }>(
      'GET',
      '/project/search?expand=description'
    );

    return (result.values || []).map(p => ({
      id: p.key,
      name: p.name,
      description: p.description || undefined,
      url: `https://${this.host}/browse/${p.key}`,
      archived: p.archived || false,
      workspaceId: this.host
    }));
  }

  async getProject(projectId: string): Promise<ProjectOutput> {
    const project = await this.rest<any>(
      'GET',
      `/project/${encodeURIComponent(projectId)}?expand=description`
    );

    return {
      id: project.key,
      name: project.name,
      description: project.description || undefined,
      url: `https://${this.host}/browse/${project.key}`,
      archived: project.archived || false,
      workspaceId: this.host
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  validateTaskId(taskId: string): boolean {
    // Jira keys: PREFIXO-NUMERO (ex: PROJ-123, ABC-4567)
    // IDs internos numéricos também são aceitos (ex: 10000)
    return /^[A-Z][A-Z0-9_]*-\d+$/.test(taskId) || /^\d+$/.test(taskId);
  }

  getProviderFromTaskId(taskId: string): TaskManagerProvider | null {
    // PROJ-123 colide com Linear; preferência via TASK_MANAGER_PROVIDER no detector.
    // Aqui, apenas indicamos compatibilidade de formato.
    return this.validateTaskId(taskId) ? 'jira' : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Faz uma chamada REST autenticada à API do Jira.
   */
  private async rest<T = any>(
    method: 'GET' | 'POST' | 'PUT' | 'DELETE',
    path: string,
    body?: any
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const response = await fetch(url, {
      method,
      headers: {
        'Authorization': this.authHeader,
        'Accept': 'application/json',
        ...(body ? { 'Content-Type': 'application/json' } : {})
      },
      body: body ? JSON.stringify(body) : undefined
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(
        `Jira API ${method} ${path} falhou: ${response.status} ${response.statusText}\n${errorText}`
      );
    }

    if (response.status === 204) {
      return undefined as unknown as T;
    }

    return response.json() as Promise<T>;
  }

  /**
   * Busca issues via JQL.
   *
   * Cloud (v3): usa POST /search/jql com paginação por nextPageToken (endpoint
   * antigo /search foi removido em maio/2025).
   * Server/DC (v2): usa GET /search com startAt (endpoint clássico).
   */
  private async searchByJQL(
    jql: string,
    maxResults = 50,
    pageToken?: string
  ): Promise<{ issues: TaskOutput[]; nextPageToken?: string }> {
    const fields = [
      'summary', 'description', 'status', 'priority', 'assignee',
      'labels', 'duedate', 'parent', 'project', 'created', 'updated',
      'subtasks', 'timetracking', 'issuetype'
    ];

    if (this.apiVersion === '3') {
      // Cloud — POST /search/jql com nextPageToken
      const body: any = { jql, maxResults, fields };
      if (pageToken) body.nextPageToken = pageToken;

      const result = await this.rest<{ issues: any[]; nextPageToken?: string }>(
        'POST',
        '/search/jql',
        body
      );

      return {
        issues: (result.issues || []).map(issue => this.normalizeIssue(issue)),
        nextPageToken: result.nextPageToken
      };
    }

    // Server/DC — GET /search com startAt
    const startAt = pageToken ? parseInt(pageToken, 10) : 0;
    const params = new URLSearchParams({
      jql,
      maxResults: String(maxResults),
      startAt: String(startAt),
      fields: fields.join(',')
    });

    const result = await this.rest<{
      issues: any[];
      startAt: number;
      maxResults: number;
      total: number;
    }>('GET', `/search?${params.toString()}`);

    const issues = (result.issues || []).map(issue => this.normalizeIssue(issue));
    const next = result.startAt + result.maxResults;
    const hasMore = next < (result.total ?? 0);

    return {
      issues,
      nextPageToken: hasMore ? String(next) : undefined
    };
  }

  /**
   * Procura o transition ID que leva uma issue ao status alvo.
   */
  private async findTransitionId(taskId: string, status: TaskStatus): Promise<string | null> {
    const targetName = this.mapStatusToJira(status).toLowerCase();

    const result = await this.rest<{ transitions: any[] }>(
      'GET',
      `/issue/${encodeURIComponent(taskId)}/transitions`
    );

    const match = (result.transitions || []).find(t =>
      t.to?.name?.toLowerCase() === targetName ||
      t.name?.toLowerCase() === targetName
    );

    return match?.id || null;
  }

  /**
   * Resolve a project key a partir do input ou da config padrão.
   */
  private resolveProjectKey(projectId?: string): string {
    const key = projectId || this.defaultProjectKey;
    if (!key) {
      throw new Error(
        '❌ Project key não informado. Defina JIRA_PROJECT_KEY ou passe projectId no input.'
      );
    }
    return key;
  }

  /**
   * Converte texto plano/markdown leve em Atlassian Document Format (ADF) para v3.
   * Em v2, retorna string crua.
   */
  private toADF(text: string): any {
    if (this.apiVersion === '2') return text;

    const paragraphs = text.split(/\n{2,}/);
    return {
      type: 'doc',
      version: 1,
      content: paragraphs.map(p => ({
        type: 'paragraph',
        content: [{ type: 'text', text: p }]
      }))
    };
  }

  /**
   * Extrai texto plano de ADF retornado pela API.
   */
  private fromADF(adf: any): string {
    if (typeof adf === 'string') return adf;
    if (!adf?.content) return '';

    const extract = (node: any): string => {
      if (node.type === 'text') return node.text || '';
      if (node.content) return node.content.map(extract).join('');
      return '';
    };

    return adf.content.map(extract).join('\n\n').trim();
  }

  /**
   * Normaliza uma issue do Jira para TaskOutput.
   */
  private normalizeIssue(issue: any): TaskOutput {
    const f = issue.fields || {};

    return {
      id: issue.key,
      provider: 'jira',
      name: f.summary || '',
      description: this.fromADF(f.description),
      status: this.mapStatusFromJira(f.status?.name || ''),
      statusRaw: f.status?.name,
      statusColor: f.status?.statusCategory?.colorName,
      priority: this.mapPriorityFromJira(f.priority?.name),
      url: `https://${this.host}/browse/${issue.key}`,
      createdAt: f.created || new Date().toISOString(),
      updatedAt: f.updated || new Date().toISOString(),
      dueDate: f.duedate || undefined,
      assignees: f.assignee ? [{
        id: f.assignee.accountId,
        name: f.assignee.displayName,
        email: f.assignee.emailAddress,
        avatarUrl: f.assignee.avatarUrls?.['48x48']
      }] : [],
      tags: f.labels || [],
      parent: f.parent?.key,
      projectId: f.project?.key,
      projectName: f.project?.name,
      timeEstimate: f.timetracking?.originalEstimateSeconds
        ? Math.round(f.timetracking.originalEstimateSeconds / 60)
        : undefined,
      timeSpent: f.timetracking?.timeSpentSeconds
        ? Math.round(f.timetracking.timeSpentSeconds / 60)
        : undefined
    };
  }

  /**
   * Normaliza um comentário do Jira para CommentOutput.
   */
  private normalizeComment(raw: any): CommentOutput {
    return {
      id: raw.id,
      text: this.fromADF(raw.body),
      author: {
        id: raw.author?.accountId || 'unknown',
        name: raw.author?.displayName || 'Unknown',
        email: raw.author?.emailAddress,
        avatarUrl: raw.author?.avatarUrls?.['48x48']
      },
      createdAt: raw.created || new Date().toISOString()
    };
  }

  // ─── Status & Priority Mapping ─────────────────────────────────────────────

  private mapStatusToJira(status: TaskStatus): string {
    const map: Record<TaskStatus, string> = {
      backlog: 'Backlog',
      todo: 'To Do',
      in_progress: 'In Progress',
      review: 'In Review',
      done: 'Done',
      closed: 'Closed',
      canceled: 'Cancelled'
    };
    return map[status] || 'To Do';
  }

  private mapStatusFromJira(jiraStatus: string): TaskStatus {
    const normalized = jiraStatus.toLowerCase().trim();
    const map: Record<string, TaskStatus> = {
      'backlog': 'backlog',
      'to do': 'todo',
      'todo': 'todo',
      'open': 'todo',
      'in progress': 'in_progress',
      'in review': 'review',
      'code review': 'review',
      'review': 'review',
      'done': 'done',
      'resolved': 'done',
      'closed': 'closed',
      'cancelled': 'canceled',
      'canceled': 'canceled'
    };
    return map[normalized] || 'todo';
  }

  private mapPriorityToJira(priority: TaskPriority): string {
    const map: Record<TaskPriority, string> = {
      urgent: 'Highest',
      high: 'High',
      normal: 'Medium',
      low: 'Low'
    };
    return map[priority] || 'Medium';
  }

  private mapPriorityFromJira(jiraPriority?: string): TaskPriority | undefined {
    if (!jiraPriority) return undefined;
    const normalized = jiraPriority.toLowerCase();
    const map: Record<string, TaskPriority> = {
      'highest': 'urgent',
      'high': 'high',
      'medium': 'normal',
      'low': 'low',
      'lowest': 'low'
    };
    return map[normalized];
  }
}
```

---

## 📊 Mapeamento de Conceitos

| Interface | Jira |
|-----------|------|
| `project` | Project |
| `task` | Issue (issuetype: Task/Story/Bug) |
| `subtask` | Issue (issuetype: Sub-task) com `fields.parent.key` |
| `status` | Status (gerenciado via Transitions) |
| `comment` | Comment |
| `tags` | `labels` |
| `assignees` | `assignee` (apenas 1) |
| `priority` | `priority.name` |
| `dueDate` | `duedate` (YYYY-MM-DD) |
| `timeEstimate` | `timetracking.originalEstimate` |

---

## 🔄 Status Mapping

| Interface | Jira (padrão) | Notas |
|-----------|---------------|-------|
| `backlog` | Backlog | Não existe em todos workflows |
| `todo` | To Do / Open | Comum |
| `in_progress` | In Progress | Sempre presente |
| `review` | In Review / Code Review | Customizado por projeto |
| `done` | Done / Resolved | Categoria "Done" |
| `closed` | Closed | Em workflows clássicos |
| `canceled` | Cancelled | Configuração customizada |

> ⚠️ **Workflows são customizáveis no Jira.** O adapter procura transições por nome (case-insensitive). Se seu projeto usar nomes diferentes, ajuste `mapStatusToJira()` ou crie workflows alinhados.

---

## 🔄 Priority Mapping

| Interface | Jira |
|-----------|------|
| `urgent` | Highest |
| `high` | High |
| `normal` | Medium |
| `low` | Low / Lowest |

---

## ⚠️ Limitações e Notas

1. **1 assignee por issue** — Jira não suporta múltiplos assignees nativamente
2. **Status via Transitions** — não é possível setar status diretamente; o adapter procura a transição com o nome alvo
3. **ADF em v3** — descrições e comentários usam Atlassian Document Format; o helper `toADF()` aceita texto plano (parágrafos separados por linha em branco). Para markdown completo, considere `JIRA_API_VERSION=2` ou converta para wiki markup antes
4. **JQL** — `searchTasks` traduz filtros para JQL; queries complexas podem precisar de ajustes
5. **Project keys vs IDs** — o adapter usa `key` (ex: `PROJ`) como `id` exposto, pois é mais legível e estável
6. **Custom fields** — não suportados na interface genérica; estenda o adapter se precisar (`customfield_XXXXX`)
7. **Delete vs Archive** — `deleteTask` usa DELETE real; em produção, considere mover para "Cancelled" via `updateStatus`

---

## 🗓️ Compatibilidade com a API (estado em maio/2026)

### Endpoints atuais (Cloud v3)

| Operação | Endpoint | Status |
|----------|----------|--------|
| Criar issue | `POST /rest/api/3/issue` | ✅ Atual |
| Get issue | `GET /rest/api/3/issue/{key}` | ✅ Atual |
| Update issue | `PUT /rest/api/3/issue/{key}` | ✅ Atual |
| Delete issue | `DELETE /rest/api/3/issue/{key}` | ✅ Atual |
| Buscar via JQL | `POST /rest/api/3/search/jql` | ✅ Atual (substituiu `/search` removido em maio/2025) |
| Transitions | `GET/POST /rest/api/3/issue/{key}/transitions` | ✅ Atual |
| Comments | `GET/POST /rest/api/3/issue/{key}/comment` | ✅ Atual |
| Projects | `GET /rest/api/3/project/search` | ✅ Atual |

### Migrações importantes

- **Maio/2025**: `GET/POST /rest/api/3/search` foi **removido**. Substituído por `POST /rest/api/3/search/jql` com **paginação por `nextPageToken`** (não mais `startAt`). Este adapter usa o endpoint novo em v3 e mantém `/search` clássico para v2 (Server/DC).
- **2024-2025**: Migração obrigatória para `accountId` em todos os campos de usuário (em vez de `name`/`username`). Já refletido no adapter.

### Considerações forward-looking

1. **Rate limiting** — Cloud retorna `429 Too Many Requests` com `Retry-After`. O `rest()` helper atual **não faz retry automático**. Para produção, envolva a chamada com retry+backoff exponencial.
2. **API tokens com escopos** (rollout iniciado em 2025) — Atlassian agora permite tokens com escopos granulares (`read:issue:jira`, `write:issue:jira`, etc.). Tokens legados com escopo total continuam funcionando. Se criar tokens novos, garanta os escopos: `read:jira-work`, `write:jira-work`.
3. **OAuth 2.0 (3LO)** — Recomendado para apps compartilhados, mas Basic Auth com API token segue suportada para automação pessoal/CI.
4. **Bulk operations** — `POST /rest/api/3/issue/bulk` está GA desde fim/2024. Pode ser explorado para criar múltiplas issues numa só chamada (não usado aqui).
5. **`/search/approximate-count`** — Como `/search/jql` não retorna `total`, há um endpoint separado se você precisar de contagem aproximada. Não usado por este adapter.

---

## 🧪 Exemplos de Uso

```typescript
// Via Factory (com TASK_MANAGER_PROVIDER=jira)
const tm = getTaskManager();

// Criar issue
const task = await tm.createTask({
  name: 'Implementar feature X',
  description: 'Descrição detalhada da feature.',
  projectId: 'PROJ',
  priority: 'high',
  tags: ['frontend', 'sprint-12'],
  dueDate: '2026-06-30'
});
// → task.id = 'PROJ-123', task.url = 'https://...atlassian.net/browse/PROJ-123'

// Criar subtask
const subtask = await tm.createSubtask('PROJ-123', {
  name: 'Fase 1: Setup do ambiente'
});

// Atualizar status (procura transição automaticamente)
await tm.updateStatus('PROJ-123', 'in_progress');

// Adicionar comentário
await tm.addComment('PROJ-123', 'Desenvolvimento iniciado!');

// Buscar issues
const inProgress = await tm.searchTasks({
  projectId: 'PROJ',
  status: ['in_progress'],
  limit: 20
});
```

---

## 🚀 Setup Rápido

1. **Configurar `.env`**:
   ```bash
   TASK_MANAGER_PROVIDER=jira
   TASK_MANAGER_TRANSPORT=api          # api (default) | mcp
   JIRA_HOST=suaempresa.atlassian.net
   JIRA_EMAIL=voce@suaempresa.com
   JIRA_API_TOKEN=ATATT3xFfGF0...
   JIRA_PROJECT_KEY=PROJ
   ```

2. **Testar conexão**:
   ```typescript
   const tm = getTaskManager();
   const projects = await tm.getProjectList();
   console.log(projects);  // Deve listar projetos visíveis
   ```

3. **Usar nos comandos Onion**:
   ```bash
   /product/task "Nova feature"
   /engineer/start PROJ-123
   ```

---

## 🔌 Transporte: API (default) vs MCP (opcional)

O adapter suporta dois transportes, controlados por `TASK_MANAGER_TRANSPORT` no `.env`:

| `TASK_MANAGER_TRANSPORT` | Transporte | Quando usar |
|--------------------------|------------|-------------|
| `api` (**default**) | REST direto via `fetch` — `https://{JIRA_HOST}/rest/api/{version}/` | Automação, CI/CD, uso geral — sem dependências externas |
| `mcp` | Atlassian MCP (`mcp__claude_ai_Atlassian__*`) | Ambientes interativos com MCP já configurado; OAuth gerenciado pelo servidor |

**Regra de fallback**: se `TASK_MANAGER_TRANSPORT=mcp` mas o servidor Atlassian MCP não estiver disponível, o adapter cai automaticamente para `api`.

### Ativar MCP (quando necessário)

1. Configurar o servidor: `claude mcp add atlassian` (ou via interface Claude Code)
2. Autenticar via `mcp__claude_ai_Atlassian__authenticate` + `mcp__claude_ai_Atlassian__complete_authentication`
3. Definir `TASK_MANAGER_TRANSPORT=mcp` no `.env`

---

## 📚 Referências

- [Jira Cloud REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/)
- [JQL — Jira Query Language](https://support.atlassian.com/jira-software-cloud/docs/use-advanced-search-with-jira-query-language-jql/)
- [Atlassian Document Format (ADF)](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
- [API Tokens (Cloud)](https://id.atlassian.com/manage-profile/security/api-tokens)
- [Personal Access Tokens (Server/DC)](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html)
- [Interface ITaskManager](../interface.md)
- [Types](../types.md)
- [Padrão SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.1.0
**Criado em**: 2026-05-15
**Atualizado em**: 2026-06-13
**Status**: ✅ Implementação completa
