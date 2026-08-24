# 🏭 Factory - Task Manager

> Instância concreta do padrão **SDAAL** (Specification-Driven AI Abstraction Layer).
> Referência canônica: `docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`

## 🎯 Propósito

Instanciar o adapter correto para o provider e transporte configurados, abstraindo a criação e permitindo uso uniforme nos comandos.

**Regra de transporte (invariante):**
- `TASK_MANAGER_TRANSPORT=api` (default) → REST API direta; sempre disponível.
- `TASK_MANAGER_TRANSPORT=mcp` → MCP server do provider; ativado apenas quando o provider suporta MCP (`clickup`, `linear`). Se não suportado, cai automaticamente para `api`.

A decisão final de transporte é resolvida pelo `detectProvider()` (ver `detector.md`) e exposta em `ProviderConfig.transport`. A factory lê esse campo — nunca relê `TASK_MANAGER_TRANSPORT` diretamente.

---

## 📋 Função Principal

### getTaskManager()

```typescript
/**
 * Retorna uma instância do TaskManager configurado.
 *
 * Fluxo:
 *   1. detectProvider() → resolve provider + transporte efetivo
 *   2. Se não configurado → fallback ou erro (conforme options)
 *   3. Instancia o adapter passando { transport } no config
 *      - transport='api'  → adapter usa REST API direta
 *      - transport='mcp'  → adapter usa MCP server (apenas providers capazes)
 *
 * @param options - Opções de configuração (opcional)
 * @returns Instância do adapter apropriado
 *
 * @example
 * const tm = getTaskManager();
 * const task = await tm.createTask({ name: 'Nova Task' });
 */
function getTaskManager(options?: FactoryOptions): ITaskManager {
  const config = detectProvider();
  // config.transport já é o transporte EFETIVO (api | mcp), após fallback do detector

  // Log de debug (se habilitado)
  if (options?.debug) {
    console.log(`[TaskManager] Provider:   ${config.provider}`);
    console.log(`[TaskManager] Transport:  ${config.transport}`);
    console.log(`[TaskManager] Configured: ${config.isConfigured}`);
  }

  // Provedor selecionado mas não configurado — decidir comportamento
  if (!config.isConfigured) {
    if (options?.throwOnMisconfigured) {
      throw new Error(config.errorMessage || 'Provider not configured');
    }
    console.warn(`⚠️ ${config.errorMessage}`);
    console.warn(`💡 Continuando em modo offline...`);
    return new NoProviderAdapter();
  }

  // Instanciar adapter com transporte resolvido
  switch (config.provider) {

    case 'clickup':
      // transport='api'  → REST API  (https://api.clickup.com/api/v2)
      // transport='mcp'  → MCP server ClickUp (quando TASK_MANAGER_TRANSPORT=mcp)
      return new ClickUpAdapter({
        transport: config.transport,          // <- ciente do transporte
        apiToken: process.env.CLICKUP_API_TOKEN!,
        workspaceId: process.env.CLICKUP_WORKSPACE_ID,
        defaultListId: process.env.CLICKUP_DEFAULT_LIST_ID
      });

    case 'asana':
      // transport='api' (REST) | 'mcp' (Asana via conector claude.ai)
      return new AsanaAdapter({
        transport: config.transport,
        accessToken: process.env.ASANA_ACCESS_TOKEN!,
        workspaceId: process.env.ASANA_WORKSPACE_ID,
        defaultProjectId: process.env.ASANA_DEFAULT_PROJECT_ID
      });

    case 'jira':
      // transport='api' (REST v3/v2, ADF) | 'mcp' (Atlassian via conector claude.ai)
      return new JiraAdapter({
        transport: config.transport,
        host: process.env.JIRA_HOST!,
        email: process.env.JIRA_EMAIL,
        apiToken: process.env.JIRA_API_TOKEN!,
        defaultProjectKey: process.env.JIRA_PROJECT_KEY,
        authType: (process.env.JIRA_AUTH_TYPE as 'basic' | 'bearer') || 'basic',
        apiVersion: (process.env.JIRA_API_VERSION as '2' | '3') || '3'
      });

    case 'linear':
      // transport='api'  → GraphQL API  (https://api.linear.app/graphql)
      // transport='mcp'  → MCP server Linear (quando TASK_MANAGER_TRANSPORT=mcp)
      return new LinearAdapter({
        transport: config.transport,          // <- ciente do transporte
        apiKey: process.env.LINEAR_API_KEY!,
        teamId: process.env.LINEAR_TEAM_ID
      });

    case 'none':
    default:
      return new NoProviderAdapter();
  }
}
```

---

## ⚙️ Tipos da Factory

```typescript
/**
 * Opções para a factory.
 */
interface FactoryOptions {
  /** Habilita logs de debug (provider + transporte resolvido) */
  debug?: boolean;

  /** Lança erro se provedor não configurado (ao invés de fallback silencioso) */
  throwOnMisconfigured?: boolean;

  /** Força um provedor específico (ignora .env) — uso em testes / scripts */
  forceProvider?: TaskManagerProvider;
}

/**
 * Configuração base compartilhada por todos os adapters.
 * O campo `transport` determina a via de comunicação efetiva.
 */
interface BaseAdapterConfig {
  /** Transporte efetivo resolvido pelo detector. */
  transport: TaskManagerTransport;  // 'api' | 'mcp'
}

/**
 * Configuração para ClickUp Adapter.
 * Suporta transport='api' (REST) e transport='mcp' (MCP server).
 */
interface ClickUpAdapterConfig extends BaseAdapterConfig {
  apiToken: string;
  workspaceId?: string;
  defaultListId?: string;
}

/**
 * Configuração para Asana Adapter.
 * Suporta apenas transport='api' (REST).
 */
interface AsanaAdapterConfig extends BaseAdapterConfig {
  accessToken: string;
  workspaceId?: string;
  defaultProjectId?: string;
}

/**
 * Configuração para Jira Adapter.
 * Suporta apenas transport='api' (REST v3 Cloud / v2 Server).
 */
interface JiraAdapterConfig extends BaseAdapterConfig {
  /** Hostname do Jira (ex: 'empresa.atlassian.net') */
  host: string;
  /** Email Atlassian (obrigatório em Basic Auth / Cloud) */
  email?: string;
  /** API Token (Cloud) ou Personal Access Token (Server/DC) */
  apiToken: string;
  /** Project key padrão (ex: 'PROJ') */
  defaultProjectKey?: string;
  /** Tipo de autenticação: 'basic' (Cloud) | 'bearer' (Server/DC + PAT) */
  authType?: 'basic' | 'bearer';
  /** Versão da REST API: '3' (Cloud, default) | '2' (Server antigo) */
  apiVersion?: '2' | '3';
}

/**
 * Configuração para Linear Adapter.
 * Suporta transport='api' (GraphQL) e transport='mcp' (MCP server).
 */
interface LinearAdapterConfig extends BaseAdapterConfig {
  apiKey: string;
  teamId?: string;
}
```

---

## 🔄 Funções Auxiliares

### getTaskManagerOrFail()

```typescript
/**
 * Versão da factory que lança erro se o provedor não estiver configurado.
 * Útil para comandos que REQUEREM um provedor ativo.
 *
 * @throws Error se provedor não configurado
 */
function getTaskManagerOrFail(): ITaskManager {
  return getTaskManager({ throwOnMisconfigured: true });
}
```

### getTaskManagerWithWarning()

```typescript
/**
 * Versão da factory que expõe aviso formatado quando em modo offline.
 * Útil para comandos que podem funcionar sem provedor (degraded mode).
 *
 * @returns Adapter + flag indicando se está em modo offline + transporte ativo
 */
function getTaskManagerWithWarning(): {
  taskManager: ITaskManager;
  transport: TaskManagerTransport;
  isOffline: boolean;
  warning?: string;
} {
  const config = detectProvider();
  const taskManager = getTaskManager();

  if (config.provider === 'none' || !config.isConfigured) {
    return {
      taskManager,
      transport: 'api',
      isOffline: true,
      warning: `⚠️ MODO OFFLINE ATIVADO
━━━━━━━━━━━━━━━━━━━━━━━━
Nenhum gerenciador de tarefas configurado.

Funcionalidades disponíveis:
  ✅ Criar documentos locais
  ✅ Gerar estrutura de sessão
  ❌ Sincronizar com ClickUp/Asana/Jira/Linear
  ❌ Atualizar status de tasks

💡 Para habilitar sincronização:
   Execute /meta/setup-integration
━━━━━━━━━━━━━━━━━━━━━━━━`
    };
  }

  return {
    taskManager,
    transport: config.transport,
    isOffline: false
  };
}
```

---

## 📊 Classe Base NoProviderAdapter

```typescript
/**
 * Adapter de fallback quando nenhum provedor está configurado.
 * Permite operações locais e gera IDs locais.
 */
class NoProviderAdapter implements ITaskManager {
  readonly provider: TaskManagerProvider = 'none';
  readonly isConfigured: boolean = false;
  
  async createTask(input: CreateTaskInput): Promise<TaskOutput> {
    console.warn('⚠️ Criando task LOCAL (não sincronizada)');
    
    const localId = `local-${Date.now()}`;
    
    return {
      id: localId,
      provider: 'none',
      name: input.name,
      description: input.description || '',
      status: 'todo',
      url: '',  // Sem URL pois é local
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      assignees: [],
      tags: input.tags || [],
      dueDate: input.dueDate,
      priority: input.priority
    };
  }
  
  async getTask(taskId: string): Promise<TaskOutput> {
    console.warn(`⚠️ getTask('${taskId}') - Operando em modo offline`);
    throw new Error('Operação não disponível em modo offline');
  }
  
  async updateTask(taskId: string, updates: UpdateTaskInput): Promise<TaskOutput> {
    console.warn(`⚠️ updateTask('${taskId}') - Operando em modo offline`);
    throw new Error('Operação não disponível em modo offline');
  }
  
  async deleteTask(taskId: string): Promise<boolean> {
    console.warn(`⚠️ deleteTask('${taskId}') - Operando em modo offline`);
    return false;
  }
  
  async createSubtask(parentId: string, input: CreateTaskInput): Promise<TaskOutput> {
    console.warn('⚠️ Criando subtask LOCAL (não sincronizada)');
    
    const localId = `local-${Date.now()}-sub`;
    
    return {
      id: localId,
      provider: 'none',
      name: input.name,
      description: input.description || '',
      status: 'todo',
      url: '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      assignees: [],
      tags: input.tags || [],
      parent: parentId
    };
  }
  
  async getSubtasks(parentId: string): Promise<TaskOutput[]> {
    console.warn(`⚠️ getSubtasks('${parentId}') - Operando em modo offline`);
    return [];
  }
  
  async addComment(taskId: string, comment: string): Promise<CommentOutput> {
    console.warn(`⚠️ addComment('${taskId}') - Operando em modo offline`);
    
    return {
      id: `local-comment-${Date.now()}`,
      text: comment,
      author: { id: 'local', name: 'Local User' },
      createdAt: new Date().toISOString()
    };
  }
  
  async getComments(taskId: string): Promise<CommentOutput[]> {
    return [];
  }
  
  async updateStatus(taskId: string, status: TaskStatus): Promise<TaskOutput> {
    console.warn(`⚠️ updateStatus('${taskId}', '${status}') - Operando em modo offline`);
    throw new Error('Operação não disponível em modo offline');
  }
  
  async searchTasks(query: SearchQuery): Promise<TaskOutput[]> {
    console.warn('⚠️ searchTasks() - Operando em modo offline');
    return [];
  }
  
  async getProjectList(): Promise<ProjectOutput[]> {
    return [];
  }
  
  async getProject(projectId: string): Promise<ProjectOutput> {
    throw new Error('Operação não disponível em modo offline');
  }
  
  validateTaskId(taskId: string): boolean {
    return /^local-\d+(-sub)?$/.test(taskId);
  }
  
  getProviderFromTaskId(taskId: string): TaskManagerProvider | null {
    return detectProviderFromTaskId(taskId);
  }
}
```

---

## 🧪 Exemplos de Uso

### Uso Básico

```typescript
// Obter adapter configurado (transporte resolvido automaticamente)
const taskManager = getTaskManager();

if (taskManager.isConfigured) {
  const task = await taskManager.createTask({
    name: 'Minha Task',
    description: 'Descrição'
  });
  console.log(`✅ Task criada: ${task.url}`);
} else {
  console.log('⚠️ Modo offline — task não será sincronizada');
}
```

### Uso com Debug de Transporte

```typescript
// Inspecionar qual transporte foi resolvido
const taskManager = getTaskManager({ debug: true });
// Saída de exemplo (ClickUp com MCP ativado):
//   [TaskManager] Provider:   clickup
//   [TaskManager] Transport:  mcp
//   [TaskManager] Configured: true
```

### Uso com Validação Estrita

```typescript
// Requer provedor configurado; lança erro se ausente
try {
  const taskManager = getTaskManagerOrFail();
  await taskManager.updateStatus(taskId, 'done');
} catch (error) {
  console.error('❌ Provedor não configurado — execute /meta/setup-integration');
}
```

### Uso com Warning (degraded mode)

```typescript
// Continua mesmo sem provedor; expõe transporte ativo
const { taskManager, transport, isOffline, warning } = getTaskManagerWithWarning();

if (isOffline) {
  console.log(warning);
} else {
  console.log(`Transporte ativo: ${transport}`); // 'api' ou 'mcp'
}

const task = await taskManager.createTask({ name: 'Task pode ser local' });
```

### Forçar Provider em Testes

```typescript
// Sobreposição do .env para scripts / testes isolados
const taskManager = getTaskManager({ forceProvider: 'linear' });
```

---

## 📊 Mapa de Suporte a Transporte por Provider

| Provider | `transport='api'` | `transport='mcp'` | Observação |
|----------|:-----------------:|:-----------------:|-----------|
| ClickUp  | ✅ default         | ✅ opcional        | Requer `TASK_MANAGER_TRANSPORT=mcp` |
| Linear   | ✅ default         | ✅ opcional        | Requer `TASK_MANAGER_TRANSPORT=mcp` |
| Asana    | ✅ default         | ✅ opcional        | MCP via conector claude.ai (runtime) |
| Jira     | ✅ default         | ✅ opcional        | MCP via conector Atlassian (runtime) |
| none     | — (offline)       | — (offline)       | NoProviderAdapter; sem chamadas externas |

> Regra: o detector resolve `transport` (api default | mcp opcional) **uniformemente** para
> todos os providers; a factory apenas consome o valor. Se o servidor MCP não responder em
> runtime, o adapter cai para `api`.

---

## 📚 Referências

- [Interface ITaskManager](./interface.md)
- [Detector](./detector.md) — resolve provider + transporte efetivo
- [Adapters](./adapters/) — documentam vias API (default) e MCP (opcional) de forma uniforme
- [SDAAL — padrão-pai](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 2.0.0
**Atualizado em**: 2026-06-13

