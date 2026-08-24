# 🟣 Linear Adapter

> Instância do padrão [SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md).
> Transporte **padrão: GraphQL API**. MCP opcional via `TASK_MANAGER_TRANSPORT=mcp`.

---

## 📋 Configuração

### Variáveis de Ambiente

```bash
# Obrigatória
LINEAR_API_KEY=lin_api_xxxxx

# Opcionais
LINEAR_TEAM_ID=xxxxx-xxxxx-xxxxx   # Team padrão para novas issues

# Transporte (padrão: api)
TASK_MANAGER_TRANSPORT=api   # "api" (GraphQL) | "mcp" (MCP opcional)
```

### Obter Token

1. Acesse Linear → Settings → API → Personal API Keys
2. Clique em "Create key"
3. Copie o token e adicione ao `.env`

---

## 🚦 Seleção de Transporte

| `TASK_MANAGER_TRANSPORT` | Comportamento |
|--------------------------|---------------|
| `api` (padrão) | Chama a Linear GraphQL API diretamente via `fetch` |
| `mcp` | Usa ferramentas MCP `mcp__claude_ai_Linear__*` quando disponíveis; cai para API se não disponível |

> Regra de ouro: prefira `api`. Use `mcp` apenas quando o servidor MCP do Linear estiver ativo na sessão.

---

## 🌐 Transporte: GraphQL API (padrão)

### Endpoint

```
https://api.linear.app/graphql
```

### Autenticação

```
Authorization: Bearer {LINEAR_API_KEY}
Content-Type: application/json
```

### Campos padrão para issues (reduz payload)

```typescript
const ISSUE_FIELDS = `
  id
  identifier
  title
  description
  state { id name type }
  priority
  priorityLabel
  url
  createdAt
  updatedAt
  dueDate
  startedAt
  assignee { id name email }
  labels { nodes { id name } }
  parent { id identifier }
  children { nodes { id identifier title } }
  team { id name }
  project { id name }
`;
```

---

## 🔌 Transporte: MCP (opcional)

Ativado quando `TASK_MANAGER_TRANSPORT=mcp` **e** o servidor MCP do Linear estiver disponível no ambiente.

Quando ativo, substitui os `fetch` calls pelas funções MCP equivalentes:

| Via API (padrão) | Via MCP (opcional) |
|------------------|--------------------|
| `mutation IssueCreate` | `mcp__claude_ai_Linear__save_issue(...)` |
| `query Issue` | `mcp__claude_ai_Linear__get_issue(...)` |
| `mutation IssueUpdate` | `mcp__claude_ai_Linear__save_issue(...)` |
| `mutation IssueArchive` | `mcp__claude_ai_Linear__save_issue({ archived: true })` |
| `mutation CommentCreate` | `mcp__claude_ai_Linear__save_comment(...)` |
| `query Issue.comments` | `mcp__claude_ai_Linear__list_comments(...)` |
| `query Issues` | `mcp__claude_ai_Linear__list_issues(...)` |
| `query Teams` | `mcp__claude_ai_Linear__list_teams(...)` |
| `query Projects` | `mcp__claude_ai_Linear__list_projects(...)` |

Se `TASK_MANAGER_TRANSPORT=mcp` mas o servidor MCP não estiver disponível, o adapter cai para API automaticamente (fallback gracioso).

---

## 🔧 Implementação

### Helper GraphQL

```typescript
const LINEAR_GRAPHQL = 'https://api.linear.app/graphql';

async function linearGraphql<T>(
  apiKey: string,
  query: string,
  variables?: Record<string, unknown>
): Promise<T> {
  const res = await fetch(LINEAR_GRAPHQL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ query, variables })
  });

  if (!res.ok) {
    throw new Error(`Linear API HTTP ${res.status}: ${res.statusText}`);
  }

  const json = await res.json();

  if (json.errors?.length) {
    throw new Error(`Linear GraphQL: ${json.errors[0].message}`);
  }

  return json.data as T;
}
```

### LinearAdapter

```typescript
/**
 * Adapter Linear implementando ITaskManager.
 * Transporte padrão: Linear GraphQL API via fetch (TASK_MANAGER_TRANSPORT=api).
 * Transporte opcional: MCP Linear (TASK_MANAGER_TRANSPORT=mcp, quando servidor disponível).
 *
 * Formatação de conteúdo:
 * - Descrições e comentários: Markdown nativo (Linear suporta Markdown rico)
 */
class LinearAdapter implements ITaskManager {
  readonly provider: TaskManagerProvider = 'linear';
  readonly isConfigured: boolean;

  private apiKey: string;
  private teamId?: string;
  private useMcp: boolean;

  constructor(config: LinearAdapterConfig) {
    this.apiKey = config.apiKey;
    this.teamId = config.teamId;
    this.isConfigured = !!this.apiKey;
    this.useMcp = (process.env.TASK_MANAGER_TRANSPORT ?? 'api') === 'mcp';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER PRIVADO
  // ═══════════════════════════════════════════════════════════════════════════

  private async gql<T>(query: string, variables?: Record<string, unknown>): Promise<T> {
    return linearGraphql<T>(this.apiKey, query, variables);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD DE TASKS (ISSUES)
  // ═══════════════════════════════════════════════════════════════════════════

  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
    const teamId = input.projectId ?? this.teamId;

    if (!teamId) {
      throw new Error('❌ LINEAR_TEAM_ID ou input.projectId obrigatório para criar issue');
    }

    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__save_issue({
        title: input.name,
        description: input.description,
        teamId,
        priority: this.mapPriorityToLinear(input.priority),
        dueDate: input.dueDate,
        assigneeId: input.assignees?.[0],
        labelIds: undefined
      });
      return this.normalizeIssue(JSON.parse(result.content[0].text));
    }

    const data = await this.gql<{ issueCreate: { issue: any } }>(
      `mutation IssueCreate($input: IssueCreateInput!) {
        issueCreate(input: $input) {
          success
          issue { ${ISSUE_FIELDS} }
        }
      }`,
      {
        input: {
          title: input.name,
          description: input.description,
          teamId,
          priority: this.mapPriorityToLinear(input.priority),
          dueDate: input.dueDate,
          assigneeId: input.assignees?.[0]
        }
      }
    );

    return this.normalizeIssue(data.issueCreate.issue);
  }

  async getTask(taskId: string): Promise<TaskOutput> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__get_issue({ id: taskId });
      return this.normalizeIssue(JSON.parse(result.content[0].text));
    }

    const data = await this.gql<{ issue: any }>(
      `query Issue($id: String!) {
        issue(id: $id) { ${ISSUE_FIELDS} }
      }`,
      { id: taskId }
    );

    return this.normalizeIssue(data.issue);
  }

  async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
    const patch: Record<string, unknown> = {};
    if (updates.name) patch.title = updates.name;
    if (updates.description !== undefined) patch.description = updates.description;
    if (updates.priority !== undefined) patch.priority = this.mapPriorityToLinear(updates.priority);
    if (updates.dueDate !== undefined) patch.dueDate = updates.dueDate;
    if (updates.assignees?.length) patch.assigneeId = updates.assignees[0];
    if (updates.status !== undefined) {
      // Status precisa ser resolvido para stateId — ver seção Status Mapping
      patch._statusLabel = updates.status; // tratado por updateStatus()
    }

    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__save_issue({ id: taskId, ...patch });
      return this.normalizeIssue(JSON.parse(result.content[0].text));
    }

    const data = await this.gql<{ issueUpdate: { issue: any } }>(
      `mutation IssueUpdate($id: String!, $input: IssueUpdateInput!) {
        issueUpdate(id: $id, input: $input) {
          success
          issue { ${ISSUE_FIELDS} }
        }
      }`,
      { id: taskId, input: patch }
    );

    return this.normalizeIssue(data.issueUpdate.issue);
  }

  async deleteTask(taskId: string): Promise<boolean> {
    // Linear arquiva em vez de deletar permanentemente
    try {
      if (this.useMcp) {
        await mcp__claude_ai_Linear__save_issue({ id: taskId, archived: true });
        return true;
      }

      const data = await this.gql<{ issueArchive: { success: boolean } }>(
        `mutation IssueArchive($id: String!) {
          issueArchive(id: $id) { success }
        }`,
        { id: taskId }
      );

      return data.issueArchive.success;
    } catch {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTASKS (SUB-ISSUES)
  // ═══════════════════════════════════════════════════════════════════════════

  async createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput> {
    const parent = await this.getTask(parentId);
    const teamId = parent.projectId ?? this.teamId;

    if (!teamId) {
      throw new Error('❌ Não foi possível determinar o teamId para a sub-issue');
    }

    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__save_issue({
        title: input.name,
        description: input.description,
        teamId,
        parentId,
        priority: this.mapPriorityToLinear(input.priority)
      });
      return this.normalizeIssue(JSON.parse(result.content[0].text));
    }

    const data = await this.gql<{ issueCreate: { issue: any } }>(
      `mutation IssueCreate($input: IssueCreateInput!) {
        issueCreate(input: $input) {
          success
          issue { ${ISSUE_FIELDS} }
        }
      }`,
      {
        input: {
          title: input.name,
          description: input.description,
          teamId,
          parentId,
          priority: this.mapPriorityToLinear(input.priority)
        }
      }
    );

    return this.normalizeIssue(data.issueCreate.issue);
  }

  async getSubtasks(parentId: string): Promise<TaskOutput[]> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__list_issues({ parentId });
      return (JSON.parse(result.content[0].text).nodes ?? []).map((i: any) =>
        this.normalizeIssue(i)
      );
    }

    const data = await this.gql<{ issue: { children: { nodes: any[] } } }>(
      `query IssueChildren($id: String!) {
        issue(id: $id) {
          children { nodes { ${ISSUE_FIELDS} } }
        }
      }`,
      { id: parentId }
    );

    return (data.issue.children.nodes ?? []).map((i: any) => this.normalizeIssue(i));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMENTÁRIOS
  // ═══════════════════════════════════════════════════════════════════════════

  async addComment(taskId: string, comment: string): Promise<CommentOutput> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__save_comment({
        issueId: taskId,
        body: comment
      });
      const raw = JSON.parse(result.content[0].text);
      return this.normalizeComment(raw, comment);
    }

    const data = await this.gql<{ commentCreate: { comment: any } }>(
      `mutation CommentCreate($input: CommentCreateInput!) {
        commentCreate(input: $input) {
          success
          comment {
            id
            body
            createdAt
            user { id name email }
          }
        }
      }`,
      { input: { issueId: taskId, body: comment } }
    );

    return this.normalizeComment(data.commentCreate.comment, comment);
  }

  async getComments(taskId: string): Promise<CommentOutput[]> {
    const fields = 'id body createdAt user { id name email }';

    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__list_comments({ issueId: taskId });
      return (JSON.parse(result.content[0].text).nodes ?? []).map((c: any) =>
        this.normalizeComment(c, c.body)
      );
    }

    const data = await this.gql<{ issue: { comments: { nodes: any[] } } }>(
      `query IssueComments($id: String!) {
        issue(id: $id) {
          comments { nodes { ${fields} } }
        }
      }`,
      { id: taskId }
    );

    return (data.issue.comments.nodes ?? []).map((c: any) =>
      this.normalizeComment(c, c.body)
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> {
    // Linear status = WorkflowState, identificado por stateId dentro do team.
    // Para resolver stateId por nome, buscar estados do team primeiro.
    const issue = await this.getTask(taskId);
    const teamId = issue.projectId ?? this.teamId;

    if (!teamId) {
      throw new Error('❌ Não foi possível determinar o team para resolver stateId');
    }

    const stateId = await this.resolveStateId(teamId, status);

    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__save_issue({ id: taskId, stateId });
      return this.normalizeIssue(JSON.parse(result.content[0].text));
    }

    const data = await this.gql<{ issueUpdate: { issue: any } }>(
      `mutation IssueUpdate($id: String!, $input: IssueUpdateInput!) {
        issueUpdate(id: $id, input: $input) {
          success
          issue { ${ISSUE_FIELDS} }
        }
      }`,
      { id: taskId, input: { stateId } }
    );

    return this.normalizeIssue(data.issueUpdate.issue);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUSCA
  // ═══════════════════════════════════════════════════════════════════════════

  async searchTasks(query: SearchQuery): Promise<TaskOutput[]> {
    const filter: Record<string, unknown> = {};
    if (query.text) filter['title'] = { contains: query.text };
    if (query.projectId) filter['team'] = { id: { eq: query.projectId } };
    if (query.assignee) filter['assignee'] = { id: { eq: query.assignee } };
    if (query.status?.length) {
      filter['state'] = { type: { in: query.status.map(s => this.mapStatusToLinearType(s)) } };
    }

    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__list_issues({
        filter,
        first: query.limit ?? 50
      });
      return (JSON.parse(result.content[0].text).nodes ?? []).map((i: any) =>
        this.normalizeIssue(i)
      );
    }

    const data = await this.gql<{ issues: { nodes: any[] } }>(
      `query SearchIssues($filter: IssueFilter, $first: Int) {
        issues(filter: $filter, first: $first) {
          nodes { ${ISSUE_FIELDS} }
        }
      }`,
      { filter, first: query.limit ?? 50 }
    );

    return (data.issues.nodes ?? []).map((i: any) => this.normalizeIssue(i));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROJETOS (TEAMS)
  // ═══════════════════════════════════════════════════════════════════════════

  async getProjectList(): Promise<ProjectOutput[]> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__list_teams({});
      return (JSON.parse(result.content[0].text).nodes ?? []).map((t: any) =>
        this.normalizeTeam(t)
      );
    }

    const data = await this.gql<{ teams: { nodes: any[] } }>(
      `query Teams {
        teams {
          nodes { id name description key }
        }
      }`
    );

    return (data.teams.nodes ?? []).map((t: any) => this.normalizeTeam(t));
  }

  async getProject(projectId: string): Promise<ProjectOutput> {
    if (this.useMcp) {
      const result = await mcp__claude_ai_Linear__get_team({ id: projectId });
      return this.normalizeTeam(JSON.parse(result.content[0].text));
    }

    const data = await this.gql<{ team: any }>(
      `query Team($id: String!) {
        team(id: $id) { id name description key }
      }`,
      { id: projectId }
    );

    return this.normalizeTeam(data.team);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  validateTaskId(taskId: string): boolean {
    // Linear aceita dois formatos:
    // - Identifier: ABC-123 (team key + número)
    // - UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    return (
      /^[A-Z]+-\d+$/.test(taskId) ||
      /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(taskId)
    );
  }

  getProviderFromTaskId(taskId: string): TaskManagerProvider | null {
    return this.validateTaskId(taskId) ? 'linear' : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  private normalizeIssue(raw: any): TaskOutput {
    return {
      id: raw.id,
      provider: 'linear',
      name: raw.title,
      description: raw.description ?? '',
      status: this.normalizeStatus(raw.state?.type),
      statusRaw: raw.state?.name,
      priority: this.normalizePriority(raw.priority),
      url: raw.url ?? `https://linear.app/issue/${raw.identifier ?? raw.id}`,
      createdAt: raw.createdAt ?? new Date().toISOString(),
      updatedAt: raw.updatedAt ?? new Date().toISOString(),
      dueDate: raw.dueDate ?? undefined,
      startDate: raw.startedAt ?? undefined,
      assignees: raw.assignee
        ? [{ id: raw.assignee.id, name: raw.assignee.name, email: raw.assignee.email }]
        : [],
      tags: (raw.labels?.nodes ?? []).map((l: any) => l.name),
      parent: raw.parent?.id,
      projectId: raw.team?.id,
      projectName: raw.team?.name
    };
  }

  private normalizeComment(raw: any, text: string): CommentOutput {
    return {
      id: raw.id ?? String(Date.now()),
      text,
      author: {
        id: raw.user?.id ?? 'unknown',
        name: raw.user?.name ?? 'Unknown'
      },
      createdAt: raw.createdAt ?? new Date().toISOString()
    };
  }

  private normalizeTeam(raw: any): ProjectOutput {
    return {
      id: raw.id,
      name: raw.name,
      description: raw.description,
      workspaceId: undefined
    };
  }

  private normalizeStatus(linearStateType?: string): TaskStatus {
    const statusMap: Record<string, TaskStatus> = {
      'triage': 'backlog',
      'backlog': 'backlog',
      'unstarted': 'todo',
      'started': 'in_progress',
      'completed': 'done',
      'cancelled': 'canceled'
    };
    return statusMap[linearStateType?.toLowerCase() ?? ''] ?? 'todo';
  }

  private mapStatusToLinearType(status: TaskStatus): string {
    const map: Record<TaskStatus, string> = {
      'backlog': 'backlog',
      'todo': 'unstarted',
      'in_progress': 'started',
      'review': 'started',
      'done': 'completed',
      'closed': 'completed',
      'canceled': 'cancelled'
    };
    return map[status] ?? 'unstarted';
  }

  /** Resolve o stateId de um WorkflowState pelo nome mapeado dentro do team. */
  private async resolveStateId(teamId: string, status: TaskStatus): Promise<string> {
    const linearType = this.mapStatusToLinearType(status);

    const data = await this.gql<{ workflowStates: { nodes: { id: string; type: string; name: string }[] } }>(
      `query WorkflowStates($teamId: String!) {
        workflowStates(filter: { team: { id: { eq: $teamId } } }) {
          nodes { id type name }
        }
      }`,
      { teamId }
    );

    const match = data.workflowStates.nodes.find(s => s.type === linearType);

    if (!match) {
      throw new Error(
        `❌ Nenhum WorkflowState do tipo "${linearType}" encontrado no team ${teamId}.\n` +
        `Estados disponíveis: ${data.workflowStates.nodes.map(s => `${s.name}(${s.type})`).join(', ')}`
      );
    }

    return match.id;
  }

  private normalizePriority(linearPriority?: number): TaskPriority | undefined {
    const map: Record<number, TaskPriority> = {
      1: 'urgent',
      2: 'high',
      3: 'normal',
      4: 'low'
    };
    return linearPriority !== undefined ? map[linearPriority] : undefined;
  }

  private mapPriorityToLinear(priority?: TaskPriority): number | undefined {
    if (!priority) return undefined;
    const map: Record<TaskPriority, number> = {
      'urgent': 1,
      'high': 2,
      'normal': 3,
      'low': 4
    };
    return map[priority];
  }
}
```

---

## 📊 Mapeamento de Campos

### Task Fields

| Interface | Linear GraphQL | Notas |
|-----------|----------------|-------|
| `name` | `title` | Direto |
| `description` | `description` | Markdown nativo |
| `status` | `state.type` | Mapeado por tipo |
| `statusRaw` | `state.name` | Nome exato do estado no team |
| `priority` | `priority` | Inteiro 0-4 |
| `dueDate` | `dueDate` | ISO 8601 (date) |
| `startDate` | `startedAt` | ISO 8601 (datetime) |
| `assignees` | `assignee` | Apenas 1 por issue |
| `tags` | `labels.nodes[].name` | Array de strings |
| `projectId` | `team.id` | UUID do team |
| `parent` | `parent.id` | UUID da issue pai |

### Status Mapping

| Interface | Linear `state.type` |
|-----------|---------------------|
| `backlog` | `triage` / `backlog` |
| `todo` | `unstarted` |
| `in_progress` | `started` |
| `review` | `started` |
| `done` | `completed` |
| `closed` | `completed` |
| `canceled` | `cancelled` |

> Os estados do Linear são configuráveis por team. O campo `state.type` é o enum fixo usado para mapeamento; `state.name` é o label customizável exibido na UI.

### Priority Mapping

| Interface | Linear `priority` |
|-----------|-------------------|
| `urgent` | `1` |
| `high` | `2` |
| `normal` | `3` |
| `low` | `4` |
| _(sem prioridade)_ | `0` |

---

## 💬 Formatação de Conteúdo

Linear suporta **Markdown nativo** em descrições e comentários — use diretamente sem transformações.

```markdown
## Objetivo
Implementar funcionalidade X conforme spec.

## Critérios de Aceite
- [ ] Comportamento A funciona
- [ ] Cobertura de testes ≥ 80%

## Notas técnicas
> Atenção: quebra potencial de compatibilidade na API v2.
```

---

## ⚠️ Notas Operacionais

| Ponto | Detalhe |
|-------|---------|
| `LINEAR_TEAM_ID` | Obrigatório para `createTask` quando `input.projectId` não é fornecido |
| Status / stateId | Não há endpoint direto por nome; `resolveStateId` busca `workflowStates` do team. Cache esse resultado em sessões longas |
| 1 assignee por issue | Linear não suporta múltiplos assignees nativamente |
| Identificadores | Suporta UUID e identifier (`ABC-123`); ambos aceitos por `validateTaskId` |
| Archive vs Delete | `deleteTask` usa `issueArchive` — a issue permanece no histórico |
| Rate limit | Linear não publica limite fixo; adote backoff exponencial em bulk |
| GraphQL introspection | Explore em https://linear.app/graphql (requer autenticação) |

---

## 🧪 Exemplos de Uso

```typescript
// Via Factory (TASK_MANAGER_PROVIDER=linear)
const tm = getTaskManager();

// Criar issue
const issue = await tm.createTask({
  name: 'Nova Feature',
  description: '## Objetivo\nImplementar funcionalidade X',
  priority: 'high'
});

// Criar sub-issue
const subIssue = await tm.createSubtask(issue.id, {
  name: 'Fase 1: Setup'
});

// Atualizar status
await tm.updateStatus(subIssue.id, 'in_progress');

// Adicionar comentário Markdown
await tm.addComment(issue.id, [
  `## Progresso — ${new Date().toISOString()}`,
  '',
  '- [x] Estrutura inicial criada',
  '- [ ] Testes unitários'
].join('\n'));

// Buscar issues abertas do team
const open = await tm.searchTasks({
  projectId: 'team-uuid-aqui',
  status: ['todo', 'in_progress'],
  limit: 20
});
```

---

## 📚 Referências

- [Linear API Docs](https://developers.linear.app/docs)
- [Linear GraphQL Explorer](https://linear.app/graphql)
- [Interface ITaskManager](../interface.md)
- [Types](../types.md)
- [Factory](../factory.md)
- [SDAAL — Padrão-pai](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 2.0.0
**Atualizado em**: 2026-06-13
