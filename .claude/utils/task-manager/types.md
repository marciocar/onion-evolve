# 📦 Tipos Compartilhados - Task Manager

## 🎯 Propósito

Define os tipos TypeScript compartilhados entre todos os adapters, garantindo consistência nas operações de entrada e saída.

---

## 🔧 Enums e Constantes

```typescript
/**
 * Provedores de gerenciamento de tarefas suportados.
 */
type TaskManagerProvider = 'clickup' | 'asana' | 'jira' | 'linear' | 'zoho' | 'none';

/**
 * Transporte usado pelo adapter para se comunicar com o provider.
 *
 * 'api' (default) — REST API direta; sempre disponível.
 * 'mcp'           — MCP server do provider; ativado via
 *                   TASK_MANAGER_TRANSPORT=mcp apenas quando o provider
 *                   suporta MCP (clickup, linear). Cai para 'api' nos demais.
 *
 * Controlado por: TASK_MANAGER_TRANSPORT (valores: 'api' | 'mcp'; default 'api').
 */
type TaskManagerTransport = 'api' | 'mcp';

/**
 * Status genéricos (mapeados internamente por cada adapter).
 */
type TaskStatus = 
  | 'backlog'
  | 'todo'
  | 'in_progress'
  | 'review'
  | 'done'
  | 'closed'
  | 'canceled';

/**
 * Níveis de prioridade.
 */
type TaskPriority = 'urgent' | 'high' | 'normal' | 'low';
```

---

## 📥 Tipos de Entrada (Input)

### CreateTaskInput

```typescript
/**
 * Dados para criação de uma nova task.
 */
interface CreateTaskInput {
  /** Nome/título da task (obrigatório) */
  name: string;
  
  /** Descrição em texto plano */
  description?: string;
  
  /** Descrição em Markdown */
  markdownDescription?: string;
  
  /** ID do projeto/lista onde criar */
  projectId?: string;
  
  /** Prioridade da task */
  priority?: TaskPriority;
  
  /** Data de vencimento (ISO 8601: YYYY-MM-DD) */
  dueDate?: string;
  
  /** Data de início (ISO 8601: YYYY-MM-DD) */
  startDate?: string;
  
  /** IDs de usuários assignees */
  assignees?: string[];
  
  /** Tags/labels */
  tags?: string[];
  
  /** Estimativa de tempo (minutos) */
  timeEstimate?: number;

  /** Estimativa de complexidade (story points) — grandeza distinta do tempo. Capacidade estimate.points */
  storyPoints?: number;

  /** Nível do item: 'task' (default em createTask) · 'epic' (createEpic) · 'subtask' (createSubtask) */
  level?: ItemLevel;
}
```

### UpdateTaskInput

```typescript
/**
 * Dados para atualização de task (todos opcionais).
 */
interface UpdateTaskInput {
  /** Novo nome */
  name?: string;
  
  /** Nova descrição */
  description?: string;
  
  /** Nova descrição markdown */
  markdownDescription?: string;
  
  /** Novo status */
  status?: TaskStatus;
  
  /** Nova prioridade */
  priority?: TaskPriority;
  
  /** Nova data de vencimento */
  dueDate?: string | null;
  
  /** Nova data de início */
  startDate?: string | null;
  
  /** Novos assignees (substitui existentes) */
  assignees?: string[];
  
  /** Novas tags (substitui existentes) */
  tags?: string[];
  
  /** Nova estimativa */
  timeEstimate?: number;

  /** Novos story points */
  storyPoints?: number;
}
```

### SearchQuery

```typescript
/**
 * Critérios de busca de tasks.
 */
interface SearchQuery {
  /** Texto para buscar no nome/descrição */
  text?: string;
  
  /** Filtrar por projeto */
  projectId?: string;
  
  /** Filtrar por status (múltiplos) */
  status?: TaskStatus[];
  
  /** Filtrar por assignee */
  assignee?: string;
  
  /** Filtrar por tags */
  tags?: string[];
  
  /** Filtrar por prioridade */
  priority?: TaskPriority[];
  
  /** Limite de resultados */
  limit?: number;
  
  /** Offset para paginação */
  offset?: number;
  
  /** Ordenação */
  orderBy?: 'created' | 'updated' | 'due_date' | 'priority';
  
  /** Direção da ordenação */
  orderDirection?: 'asc' | 'desc';
}
```

---

## 🧩 Tipos da Onda 2 (SAC-63)

Os tipos que as capacidades opcionais da [interface](./interface.md) usam. Quem não implementa a
capacidade não precisa deles; a declaração `adapters/<provedor>.capabilities.tsv` diz quem implementa.

```typescript
/** Nível do item na hierarquia canônica. A profundidade máxima de subtask NÃO foi ancorada para nenhum provedor. */
type ItemLevel = 'epic' | 'task' | 'subtask';

/** Cursor opaco de paginação: o consumidor só o repassa. Pode EXPIRAR (Jira Cloud: 7 dias; Asana: "after some time"). */
type PageCursor = string & { readonly __opaque: unique symbol };

/** Uma página de resultados; next = null quando acabou. */
interface Page<T> { items: T[]; next: PageCursor | null }

/** Anexo a enviar. */
interface AttachmentInput { filename: string; contentType: string; bytes: Uint8Array }
interface AttachmentOutput { id: string; filename: string; url?: string }

// ── Leitura completa (SAC-116, 2026-10-12): entradas cronológicas, mãe completa + irmãs, arquivos em quarentena
interface ActivityEntry { id: string; createdAt: string; actor: string | null; changes: Array<{ field: string; from?: unknown; to?: unknown }> }
interface SubtaskView { id: string; identifier: string; title: string; status: TaskStatus; storyPoints?: number | null; descriptionSummary: string; subtasks: SubtaskView[] }
interface HierarchyContext { role: 'parent' | 'subtask' | 'standalone'; parent: TaskOutput | null; siblings: SubtaskView[]; subtasks: SubtaskView[]; truncated: boolean }
interface InlineRef { n: number; url: string; kind: 'image' | 'file'; alt: string; origin: string /* description | comment:<id> | attachment:<id> */ }
interface AttachmentListing { files: InlineRef[]; links: Array<{ id: string; title: string; url: string; downloadable: boolean }> }  // links: no Linear, Attachment = LINK
interface DownloadedAttachment { path: string; mime: string; size: number; sha256: string; origin: { issue: string; url: string; ref: string }; untrusted: true }

/** Sprint (Jira, ClickUp) ou cycle (Linear). */
interface Iteration { id: string; name: string; startDate?: string; endDate?: string }

/** Vínculo canônico. Tipo sem equivalente no provedor é ERRO do adapter, nunca aproximação silenciosa. */
type LinkType = 'blocks' | 'blocked_by' | 'relates' | 'duplicates';

/** Resultado de lote: por item, porque lote parcial existe (o adapter fatia pelo limite declarado). */
interface BulkResult<T> {
  succeeded: T[];
  failed: Array<{ index: number; error: string }>;
}
```

---

## 📤 Tipos de Saída (Output)

### TaskOutput

```typescript
/**
 * Task retornada pelo adapter (normalizada).
 */
interface TaskOutput {
  /** ID único no provedor */
  id: string;
  
  /** Provedor de origem */
  provider: TaskManagerProvider;
  
  /** Nome/título */
  name: string;
  
  /** Descrição (texto plano) */
  description: string;
  
  /** Status normalizado */
  status: TaskStatus;
  
  /** Status original do provedor */
  statusRaw?: string;
  
  /** Cor do status (hex) */
  statusColor?: string;
  
  /** Prioridade */
  priority?: TaskPriority;
  
  /** URL para abrir no provedor */
  url: string;
  
  /** Data de criação (ISO 8601) */
  createdAt: string;
  
  /** Data de última atualização (ISO 8601) */
  updatedAt: string;
  
  /** Data de vencimento (ISO 8601) */
  dueDate?: string;
  
  /** Data de início (ISO 8601) */
  startDate?: string;
  
  /** Usuários assignees */
  assignees: UserOutput[];
  
  /** Tags/labels */
  tags: string[];
  
  /** Subtasks (se solicitadas) */
  subtasks?: TaskOutput[];
  
  /** ID da task pai (se for subtask) */
  parent?: string;
  
  /** ID do projeto/lista */
  projectId?: string;
  
  /** Nome do projeto/lista */
  projectName?: string;
  
  /** Tempo estimado (minutos) */
  timeEstimate?: number;
  
  /** Tempo gasto (minutos) */
  timeSpent?: number;

  /** Story points LIDOS do provedor. Capacidade estimate.points_read (not_implemented nos 5 adapters em
   *  2026-10-11): ausente = sem pontos, e a derivação `progress` (progress.sh) cai na contagem declarando. */
  storyPoints?: number;
}
```

### CommentOutput

```typescript
/**
 * Comentário retornado pelo adapter.
 */
interface CommentOutput {
  /** ID único do comentário */
  id: string;
  
  /** Texto do comentário */
  text: string;
  
  /** Autor do comentário */
  author: UserOutput;
  
  /** Data de criação (ISO 8601) */
  createdAt: string;
  
  /** Se foi resolvido (threads) */
  resolved?: boolean;
}
```

### UserOutput

```typescript
/**
 * Usuário normalizado.
 */
interface UserOutput {
  /** ID único no provedor */
  id: string;
  
  /** Nome de exibição */
  name: string;
  
  /** Email (se disponível) */
  email?: string;
  
  /** URL do avatar */
  avatarUrl?: string;
}
```

### ProjectOutput

```typescript
/**
 * Projeto/Lista normalizado.
 */
interface ProjectOutput {
  /** ID único */
  id: string;
  
  /** Nome do projeto */
  name: string;
  
  /** URL no provedor */
  url?: string;
  
  /** Descrição */
  description?: string;
  
  /** Se está arquivado */
  archived?: boolean;
  
  /** ID do workspace/space pai */
  workspaceId?: string;
}
```

---

## ⚙️ Tipos de Configuração

### ProviderConfig

```typescript
/**
 * Configuração de um provedor.
 */
interface ProviderConfig {
  /** Nome do provedor */
  provider: TaskManagerProvider;

  /**
   * Transporte efetivo escolhido pelo detector.
   * Reflete TASK_MANAGER_TRANSPORT; o adapter cai para 'api' em runtime quando o
   * servidor MCP do provider não está disponível. Adapters devem consultar este
   * campo — nunca ler a env var diretamente — para garantir o fallback correto.
   */
  transport: TaskManagerTransport;

  /** Se está configurado corretamente */
  isConfigured: boolean;

  /** Variáveis de ambiente obrigatórias */
  requiredEnvVars: string[];

  /** Variáveis de ambiente opcionais */
  optionalEnvVars: string[];

  /** Mensagem de erro se não configurado */
  errorMessage?: string;
}
```

### ValidationResult

```typescript
/**
 * Resultado de validação de ID.
 */
interface ValidationResult {
  /** Se o ID é válido */
  valid: boolean;
  
  /** Mensagem de aviso (se houver) */
  warning?: string;
  
  /** Provedor detectado */
  detectedProvider?: TaskManagerProvider;
}
```

---

## 🔄 Mapeamento de Status por Provedor

```typescript
/**
 * Mapeamento de status normalizado → provedor.
 */
// `Partial` porque ClickUp foi REMOVIDO deste mapa (ver a nota abaixo) — o tipo total mentiria.
const STATUS_MAPPING: Partial<Record<TaskManagerProvider, Record<TaskStatus, string>>> = {
  // ⚠️ ClickUp NÃO TEM ENTRADA AQUI, e a ausência é deliberada — removida em 2026-10-02 por um
  // Elenxo que a pegou. Status no ClickUp são propriedade da LIST, não do workspace: a List que um
  // adotante mediu oferece `… testing, pull request, done, Closed` e NÃO TEM `review`. Um mapa fixo
  // `review: 'review'` aqui devolve **`400 Status not found`** — e era exatamente esta tabela,
  // byte-a-byte, que o adapter tinha e que o PR do dia aboliu. Mantê-la aqui reinstalava o bug pelo
  // caminho pior: `types.md` é o contrato que a sessão lê ANTES do adapter, e viaja vendorizado.
  // Para ClickUp use `ClickUpAdapter.resolveStatusForTask`, que resolve contra `GET /list/{id}`.
  // Lição da classe: abolir um mapa no consumidor e deixá-lo na SSOT não aboliu nada.
  asana: {
    backlog: 'To Do',        // Mapeado para seção
    todo: 'To Do',
    in_progress: 'In Progress',
    review: 'Review',
    done: 'Done',            // completed: true
    closed: 'Done',
    canceled: 'Done'
  },
  jira: {
    backlog: 'Backlog',
    todo: 'To Do',
    in_progress: 'In Progress',
    review: 'In Review',
    done: 'Done',
    closed: 'Closed',
    canceled: 'Cancelled'
  },
  linear: {
    backlog: 'Backlog',
    todo: 'Todo',
    in_progress: 'In Progress',
    review: 'In Review',
    done: 'Done',
    closed: 'Canceled',
    canceled: 'Canceled'
  },
  none: {
    backlog: 'backlog',
    todo: 'todo',
    in_progress: 'in_progress',
    review: 'review',
    done: 'done',
    closed: 'closed',
    canceled: 'canceled'
  }
};
```

---

## 📚 Referências

- [Interface ITaskManager](./interface.md)
- [Detector de Provedor](./detector.md)

---

**Versão**: 1.2.0
**Criado em**: 2025-11-24
**Atualizado em**: 2026-10-11 (Onda 2: `storyPoints`, `level` e os tipos das capacidades opcionais)

