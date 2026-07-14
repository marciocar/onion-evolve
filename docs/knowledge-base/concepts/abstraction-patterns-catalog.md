# Catálogo de Padrões de Abstração

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Criado** | 2025-11-25 |
| **Última Atualização** | 2026-06-14 |
| **Categoria** | Architecture |
| **Tags** | `abstraction`, `adapter-pattern`, `multi-provider`, `catalog` |

---

## 🎯 Visão Geral

Este catálogo documenta todos os **padrões de abstração** que podem ser implementados no Sistema Onion usando o **Adapter Pattern**. Cada padrão permite trocar provedores sem modificar comandos ou agentes.

### Padrão Base

Todos os padrões seguem a mesma arquitetura:

```
┌─────────────────────────────────────────────────────────────┐
│                    COMANDOS / AGENTES                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   ABSTRACTION LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │   Factory   │→ │  Detector   │→ │  Interface  │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┬───────────────┐
         ▼               ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Provider A │  │  Provider B │  │  Provider C │  │    None     │
│   Adapter   │  │   Adapter   │  │   (Stub)    │  │   Adapter   │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
```

---

## 📊 Catálogo Completo

### Matriz de Padrões

| # | Padrão | Categoria | Status | Prioridade | Valor |
|---|--------|-----------|--------|------------|-------|
| 1 | Task Manager | Produtividade | ✅ Implementado | - | ⭐⭐⭐⭐⭐ |
| 2 | Forge (Git Provider) | DevOps | ✅ Implementado | - | ⭐⭐⭐⭐⭐ |
| 3 | LLM Provider | IA | 📝 Proposto | 🔴 Alta | ⭐⭐⭐⭐⭐ |
| 4 | Documentation | Docs | 📝 Proposto | 🟡 Média | ⭐⭐⭐⭐ |
| 5 | CI/CD | DevOps | 📝 Proposto | 🟡 Média | ⭐⭐⭐⭐ |
| 6 | Communication | Colaboração | 📝 Proposto | 🟡 Média | ⭐⭐⭐⭐ |
| 7 | Messaging/Queue | Infraestrutura | 📝 Proposto | 🟢 Baixa | ⭐⭐⭐ |
| 8 | Calendar | Produtividade | 📝 Proposto | 🟢 Baixa | ⭐⭐⭐ |
| 9 | Payment | Negócio | 📝 Proposto | 🟢 Baixa | ⭐⭐⭐ |
| 10 | Storage | Infraestrutura | 📝 Proposto | 🟢 Baixa | ⭐⭐⭐ |

---

## 1️⃣ Task Manager Abstraction ✅

**Status**: Implementado  
**Documentação**: [task-manager-abstraction.md](task-manager-abstraction.md)

### Provedores Suportados

| Provedor | Status | Env Variable |
|----------|--------|--------------|
| ClickUp | ✅ Completo | `TASK_MANAGER_PROVIDER=clickup` |
| Asana | ✅ Completo | `TASK_MANAGER_PROVIDER=asana` |
| Linear | ✅ Completo | `TASK_MANAGER_PROVIDER=linear` |
| Jira | ✅ Completo | `TASK_MANAGER_PROVIDER=jira` |

### Interface Principal

```typescript
interface ITaskManager {
  createTask(input: CreateTaskInput): Promise<TaskOutput>;
  getTask(taskId: string): Promise<TaskOutput>;
  updateStatus(taskId: string, status: string): Promise<TaskOutput>;
  addComment(taskId: string, comment: string): Promise<CommentOutput>;
}
```

---

## 2️⃣ Forge Abstraction (Git Provider / Host Remoto) ✅

**Status**: Implementado  
**Documentação**: [`.claude/utils/forge/`](../../../.claude/utils/forge/)

### Problema resolvido

Comandos `/git/*` e `/engineer/pr` assumiam GitHub diretamente. O Forge Adapter
abstrai operações de **host remoto** (PR, review, CI/checks, Release) para que
GitLab, Bitbucket e outros possam ser suportados sem alterar os comandos.

> **Fronteira importante**: o adapter cobre **só host remoto**. Git local
> (branch, merge, tag, push) usa `git` direto via motor GitFlow.

### Provedores Suportados

| Provedor | Status | Transporte padrão |
|----------|--------|------------------|
| GitHub | ✅ Implementado | `cli` (`gh`) — default |
| GitLab | 🔜 Costura pronta | — |
| Bitbucket | 🔜 Costura pronta | — |
| NoForgeAdapter | ✅ Fallback | modo local (push funciona, PR/CI degradam) |

### Variáveis de Ambiente

```bash
# .env
FORGE_PROVIDER=github    # github | gitlab | bitbucket | none
FORGE_TRANSPORT=cli      # cli (default, usa gh) | api (REST fallback)

# GitHub (via gh auth login OU token explícito)
GH_TOKEN=ghp_xxxxx       # alternativa: GITHUB_TOKEN
```

### Comandos que usam o adapter

- `/git:flow` — dispatcher GitFlow (feature/release/hotfix)
- `/engineer/pr` — abrir PR
- `/engineer/pr-update` — atualizar PR existente
- `/git/sync` — sync pós-merge

---

## 3️⃣ LLM Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🔴 Alta

### Problema

Agentes hardcoded para Anthropic Claude. Usuários podem preferir OpenAI, Google, ou modelos locais.

### Provedores Propostos

| Provedor | Prioridade | Modelos |
|----------|------------|---------|
| Anthropic | ✅ Padrão | família sonnet / opus (modelo Claude vigente) |
| OpenAI | 🔴 Alta | GPT-4o, GPT-4 Turbo |
| Google | 🟡 Média | Gemini Pro, Gemini Ultra |
| Ollama | 🟡 Média | Llama 3, Mistral, etc |
| Azure OpenAI | 🟢 Baixa | GPT-4 via Azure |

### Interface Proposta

```typescript
interface ILLMProvider {
  readonly provider: 'anthropic' | 'openai' | 'google' | 'ollama' | 'azure';
  readonly model: string;
  readonly isConfigured: boolean;

  // Chat
  chat(messages: Message[], options?: ChatOptions): Promise<ChatResponse>;
  
  // Streaming
  chatStream(messages: Message[], options?: ChatOptions): AsyncIterable<ChatChunk>;

  // Completion (legacy)
  complete(prompt: string, options?: CompleteOptions): Promise<string>;

  // Embeddings
  embed(text: string | string[]): Promise<number[][]>;

  // Capabilities
  supportsVision(): boolean;
  supportsTools(): boolean;
  supportsFunctionCalling(): boolean;
  maxContextTokens(): number;

  // Token counting
  countTokens(text: string): Promise<number>;
}

interface ChatOptions {
  temperature?: number;      // 0-1
  maxTokens?: number;
  topP?: number;
  stopSequences?: string[];
  tools?: ToolDefinition[];
  systemPrompt?: string;
}
```

### Variáveis de Ambiente

```bash
# .env
LLM_PROVIDER=anthropic  # anthropic | openai | google | ollama | azure
LLM_MODEL=claude-sonnet-latest  # alias de tier evergreen; ex. jul/2026: claude-sonnet-5

# Anthropic
ANTHROPIC_API_KEY=sk-ant-xxxxx

# OpenAI
OPENAI_API_KEY=sk-xxxxx
OPENAI_ORG_ID=org-xxxxx  # opcional

# Google
GOOGLE_AI_API_KEY=AIza-xxxxx

# Ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://myresource.openai.azure.com
AZURE_OPENAI_API_KEY=xxxxx
AZURE_OPENAI_DEPLOYMENT=gpt-4
```

---

## 4️⃣ Documentation Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟡 Média

### Provedores Propostos

| Provedor | Tipo | API |
|----------|------|-----|
| Notion | SaaS | REST API |
| Confluence | SaaS/Server | REST API |
| GitBook | SaaS | REST API |
| Markdown | Local | File System |

### Interface Proposta

```typescript
interface IDocProvider {
  readonly provider: 'notion' | 'confluence' | 'gitbook' | 'markdown';
  readonly isConfigured: boolean;

  // Pages
  createPage(input: PageInput): Promise<PageOutput>;
  getPage(id: string): Promise<PageOutput>;
  updatePage(id: string, content: ContentInput): Promise<PageOutput>;
  deletePage(id: string): Promise<void>;

  // Hierarchy
  getChildren(pageId: string): Promise<PageOutput[]>;
  movePage(pageId: string, newParentId: string): Promise<void>;

  // Databases/Spaces
  createDatabase?(input: DatabaseInput): Promise<DatabaseOutput>;
  queryDatabase?(id: string, query: Query): Promise<PageOutput[]>;

  // Search
  search(query: string): Promise<SearchResult[]>;

  // Export/Import
  exportToMarkdown(pageId: string): Promise<string>;
  importFromMarkdown(markdown: string, parentId?: string): Promise<PageOutput>;
}
```

### Variáveis de Ambiente

```bash
# .env
DOC_PROVIDER=notion  # notion | confluence | gitbook | markdown

# Notion
NOTION_API_KEY=secret_xxxxx
NOTION_DATABASE_ID=xxxxx

# Confluence
CONFLUENCE_BASE_URL=https://mycompany.atlassian.net/wiki
CONFLUENCE_USERNAME=email@company.com
CONFLUENCE_API_TOKEN=xxxxx
CONFLUENCE_SPACE_KEY=DOCS

# GitBook
GITBOOK_API_TOKEN=xxxxx
GITBOOK_SPACE_ID=xxxxx

# Markdown (local)
MARKDOWN_DOCS_PATH=./docs
```

---

## 5️⃣ CI/CD Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟡 Média

### Provedores Propostos

| Provedor | Tipo | API |
|----------|------|-----|
| GitHub Actions | SaaS | REST API |
| GitLab CI | SaaS/Server | REST API |
| CircleCI | SaaS | REST API |
| Jenkins | Self-hosted | REST API |

### Interface Proposta

```typescript
interface ICICDProvider {
  readonly provider: 'github_actions' | 'gitlab_ci' | 'circleci' | 'jenkins';
  readonly isConfigured: boolean;

  // Workflows/Pipelines
  listWorkflows(): Promise<WorkflowOutput[]>;
  triggerWorkflow(name: string, inputs?: Record<string, any>): Promise<RunOutput>;
  
  // Runs
  getRun(runId: string): Promise<RunOutput>;
  getRunLogs(runId: string, jobName?: string): Promise<string>;
  cancelRun(runId: string): Promise<void>;
  rerunWorkflow(runId: string): Promise<RunOutput>;

  // Status
  getLatestRuns(workflowName: string, limit?: number): Promise<RunOutput[]>;
  getRunStatus(runId: string): Promise<'queued' | 'running' | 'success' | 'failure' | 'cancelled'>;

  // Artifacts
  listArtifacts(runId: string): Promise<ArtifactOutput[]>;
  downloadArtifact(runId: string, artifactName: string): Promise<Buffer>;
}
```

---

## 6️⃣ Communication Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟡 Média

### Provedores Propostos

| Provedor | Tipo | Uso Típico |
|----------|------|------------|
| Slack | SaaS | Empresas tech |
| Discord | SaaS | Comunidades/startups |
| Microsoft Teams | SaaS | Enterprises |
| Telegram | SaaS | Bots/notificações |

### Interface Proposta

```typescript
interface ICommunicationProvider {
  readonly provider: 'slack' | 'discord' | 'teams' | 'telegram';
  readonly isConfigured: boolean;

  // Messages
  sendMessage(channel: string, message: MessageInput): Promise<MessageOutput>;
  sendDirectMessage(userId: string, message: MessageInput): Promise<MessageOutput>;
  editMessage(messageId: string, content: string): Promise<MessageOutput>;
  deleteMessage(messageId: string): Promise<void>;

  // Threads
  replyToThread(threadId: string, message: MessageInput): Promise<MessageOutput>;
  getThreadReplies(threadId: string): Promise<MessageOutput[]>;

  // Rich Content
  sendBlockMessage?(channel: string, blocks: Block[]): Promise<MessageOutput>;
  sendEmbed?(channel: string, embed: EmbedInput): Promise<MessageOutput>;

  // Reactions
  addReaction?(messageId: string, emoji: string): Promise<void>;

  // Channels
  listChannels(): Promise<ChannelOutput[]>;
  getChannel(id: string): Promise<ChannelOutput>;
}

interface MessageInput {
  text: string;
  markdown?: boolean;
  attachments?: AttachmentInput[];
  mentionUsers?: string[];
}
```

### Variáveis de Ambiente

```bash
# .env
COMMUNICATION_PROVIDER=slack  # slack | discord | teams | telegram

# Slack
SLACK_BOT_TOKEN=xoxb-xxxxx
SLACK_DEFAULT_CHANNEL=C0123456789

# Discord
DISCORD_BOT_TOKEN=xxxxx
DISCORD_DEFAULT_CHANNEL=1234567890

# Microsoft Teams
TEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/xxxxx
# Ou via Graph API
TEAMS_CLIENT_ID=xxxxx
TEAMS_CLIENT_SECRET=xxxxx
TEAMS_TENANT_ID=xxxxx

# Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-xxxxx
TELEGRAM_DEFAULT_CHAT_ID=-1001234567890
```

---

## 7️⃣ Messaging/Queue Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟢 Baixa

### Provedores Propostos

| Provedor | Tipo | Uso Típico |
|----------|------|------------|
| RabbitMQ | Self-hosted | Mensageria tradicional |
| AWS SQS | Cloud | AWS ecosystem |
| Redis Pub/Sub | Hybrid | Cache + mensageria |
| Kafka | Self-hosted/Cloud | Event streaming |

### Interface Proposta

```typescript
interface IMessagingProvider {
  readonly provider: 'rabbitmq' | 'sqs' | 'redis' | 'kafka';
  readonly isConfigured: boolean;

  // Publish
  publish(queue: string, message: any, options?: PublishOptions): Promise<void>;
  publishBatch(queue: string, messages: any[]): Promise<void>;

  // Subscribe
  subscribe(queue: string, handler: MessageHandler): Promise<Subscription>;
  unsubscribe(subscription: Subscription): Promise<void>;

  // Queue Management
  createQueue?(name: string, options?: QueueOptions): Promise<void>;
  deleteQueue?(name: string): Promise<void>;
  getQueueInfo?(name: string): Promise<QueueInfo>;

  // Dead Letter
  getDeadLetterMessages?(queue: string): Promise<any[]>;
  reprocessDeadLetter?(queue: string, messageId: string): Promise<void>;
}
```

### Variáveis de Ambiente

```bash
# .env
MESSAGING_PROVIDER=rabbitmq  # rabbitmq | sqs | redis | kafka

# RabbitMQ
RABBITMQ_URL=amqp://user:pass@localhost:5672

# AWS SQS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=xxxxx
AWS_SECRET_ACCESS_KEY=xxxxx
SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789/myqueue

# Redis
REDIS_URL=redis://localhost:6379

# Kafka
KAFKA_BROKERS=localhost:9092
KAFKA_CLIENT_ID=onion-system
```

---

## 8️⃣ Calendar Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟢 Baixa

### Provedores Propostos

| Provedor | Tipo | API |
|----------|------|-----|
| Google Calendar | SaaS | REST API |
| Outlook/Microsoft | SaaS | Graph API |
| Calendly | SaaS | REST API |
| Cal.com | OSS | REST API |

### Interface Proposta

```typescript
interface ICalendarProvider {
  readonly provider: 'google' | 'outlook' | 'calendly' | 'calcom';
  readonly isConfigured: boolean;

  // Events
  createEvent(input: EventInput): Promise<EventOutput>;
  getEvent(id: string): Promise<EventOutput>;
  updateEvent(id: string, updates: EventUpdateInput): Promise<EventOutput>;
  deleteEvent(id: string): Promise<void>;

  // Listing
  listEvents(options: ListOptions): Promise<EventOutput[]>;
  getEventsInRange(start: Date, end: Date): Promise<EventOutput[]>;

  // Availability
  getFreeBusy(start: Date, end: Date): Promise<FreeBusyOutput>;
  findAvailableSlots?(duration: number, range: DateRange): Promise<TimeSlot[]>;

  // Scheduling Links (Calendly/Cal.com)
  createSchedulingLink?(options: SchedulingOptions): Promise<string>;
}

interface EventInput {
  title: string;
  description?: string;
  start: Date;
  end: Date;
  attendees?: string[];
  location?: string;
  conferenceLink?: boolean;  // criar link de meet automaticamente
}
```

### Variáveis de Ambiente

```bash
# .env
CALENDAR_PROVIDER=google  # google | outlook | calendly | calcom

# Google Calendar
GOOGLE_CALENDAR_CLIENT_ID=xxxxx
GOOGLE_CALENDAR_CLIENT_SECRET=xxxxx
GOOGLE_CALENDAR_REFRESH_TOKEN=xxxxx
GOOGLE_CALENDAR_ID=primary

# Outlook
OUTLOOK_CLIENT_ID=xxxxx
OUTLOOK_CLIENT_SECRET=xxxxx
OUTLOOK_TENANT_ID=xxxxx

# Calendly
CALENDLY_API_KEY=xxxxx
CALENDLY_USER_URI=https://api.calendly.com/users/xxxxx

# Cal.com
CALCOM_API_KEY=cal_xxxxx
CALCOM_USERNAME=myusername
```

---

## 9️⃣ Payment Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟢 Baixa

### Provedores Propostos

| Provedor | Tipo | Uso Típico |
|----------|------|------------|
| Stripe | SaaS | Global |
| PayPal | SaaS | Global |
| Mercado Pago | SaaS | LATAM |
| PagSeguro | SaaS | Brasil |

### Interface Proposta

```typescript
interface IPaymentProvider {
  readonly provider: 'stripe' | 'paypal' | 'mercadopago' | 'pagseguro';
  readonly isConfigured: boolean;

  // Customers
  createCustomer(input: CustomerInput): Promise<CustomerOutput>;
  getCustomer(id: string): Promise<CustomerOutput>;

  // Charges
  createCharge(input: ChargeInput): Promise<ChargeOutput>;
  getCharge(id: string): Promise<ChargeOutput>;
  refundCharge(id: string, amount?: number): Promise<RefundOutput>;

  // Subscriptions
  createSubscription?(input: SubscriptionInput): Promise<SubscriptionOutput>;
  cancelSubscription?(id: string): Promise<void>;

  // Payment Links
  createPaymentLink?(input: PaymentLinkInput): Promise<string>;

  // Webhooks
  verifyWebhookSignature?(payload: string, signature: string): boolean;
}

interface ChargeInput {
  amount: number;           // em centavos
  currency: string;         // 'BRL', 'USD', etc
  customerId?: string;
  paymentMethod?: string;
  description?: string;
  metadata?: Record<string, string>;
}
```

### Variáveis de Ambiente

```bash
# .env
PAYMENT_PROVIDER=stripe  # stripe | paypal | mercadopago | pagseguro

# Stripe
STRIPE_SECRET_KEY=sk_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx

# PayPal
PAYPAL_CLIENT_ID=xxxxx
PAYPAL_CLIENT_SECRET=xxxxx
PAYPAL_MODE=sandbox  # sandbox | live

# Mercado Pago
MERCADOPAGO_ACCESS_TOKEN=xxxxx

# PagSeguro
PAGSEGURO_EMAIL=email@example.com
PAGSEGURO_TOKEN=xxxxx
PAGSEGURO_SANDBOX=true
```

---

## 🔟 Storage Provider Abstraction 📝

**Status**: Proposto  
**Prioridade**: 🟢 Baixa

### Provedores Propostos

| Provedor | Tipo | Uso Típico |
|----------|------|------------|
| AWS S3 | Cloud | AWS ecosystem |
| Google Cloud Storage | Cloud | GCP ecosystem |
| Azure Blob | Cloud | Azure ecosystem |
| MinIO | Self-hosted | S3-compatible |
| Local | File System | Desenvolvimento |

### Interface Proposta

```typescript
interface IStorageProvider {
  readonly provider: 's3' | 'gcs' | 'azure' | 'minio' | 'local';
  readonly isConfigured: boolean;

  // Upload/Download
  upload(key: string, data: Buffer | Stream, options?: UploadOptions): Promise<string>;
  download(key: string): Promise<Buffer>;
  getStream(key: string): Promise<ReadableStream>;

  // URLs
  getSignedUrl(key: string, expiresIn?: number): Promise<string>;
  getPublicUrl(key: string): string;

  // Management
  delete(key: string): Promise<void>;
  exists(key: string): Promise<boolean>;
  list(prefix?: string): Promise<FileInfo[]>;

  // Metadata
  getMetadata(key: string): Promise<FileMetadata>;
  setMetadata(key: string, metadata: Record<string, string>): Promise<void>;
}
```

---

## 📝 Template: Como Criar um Novo Adapter (STUB)

### Estrutura de Arquivos

```
.claude/utils/{nome}-provider/
├── README.md           # Visão geral
├── interface.md        # Interface do provedor
├── types.md            # Tipos compartilhados
├── detector.md         # Detecta provedor via .env
├── factory.md          # Cria instância do adapter
└── adapters/
    ├── provider-a.md   # Adapter completo
    ├── provider-b.md   # Adapter completo
    └── provider-c.md   # STUB documentado
```

### Template de STUB

```markdown
# {Provider Name} Adapter (STUB)

## 📋 Status

| Campo | Valor |
|-------|-------|
| **Status** | 📝 STUB |
| **Implementação** | Não iniciada |
| **Prioridade** | A definir |

---

## 🎯 Sobre este STUB

Este arquivo documenta como implementar o adapter para **{Provider Name}**.
É um STUB - não funcional, mas serve como guia de implementação.

---

## 📚 Documentação Oficial

- **API Docs**: [url]
- **SDK**: [url]
- **Autenticação**: [descrição]

---

## ⚙️ Configuração Necessária

### Variáveis de Ambiente

\`\`\`bash
{PROVIDER}_API_KEY=xxxxx
{PROVIDER}_WORKSPACE_ID=xxxxx
\`\`\`

### Dependências (se aplicável)

\`\`\`bash
npm install @provider/sdk
\`\`\`

---

## 🔧 Mapeamento de Métodos

### createTask → Provider API

\`\`\`typescript
// Interface comum
createTask(input: CreateTaskInput): Promise<TaskOutput>

// Chamada Provider (exemplo)
// POST /api/v1/tasks
// Body: { title: input.name, ... }
\`\`\`

### getTask → Provider API

\`\`\`typescript
// Interface comum
getTask(taskId: string): Promise<TaskOutput>

// Chamada Provider (exemplo)
// GET /api/v1/tasks/{taskId}
\`\`\`

[... continuar para cada método da interface ...]

---

## 🗺️ Mapeamento de Status

| Status Normalizado | {Provider} Status |
|-------------------|-------------------|
| backlog | ? |
| todo | ? |
| in_progress | ? |
| done | ? |

---

## ⚠️ Limitações Conhecidas

- [ ] Feature X não suportada
- [ ] Rate limiting: Y req/min

---

## 🚀 Próximos Passos para Implementar

1. [ ] Obter API key de teste
2. [ ] Mapear todos os endpoints
3. [ ] Implementar métodos básicos
4. [ ] Testar integração
5. [ ] Documentar edge cases
```

---

## 🔗 Referências

- [Task Manager Abstraction](task-manager-abstraction.md) - Implementação referência
- [Specification-Driven AI Abstraction Layer](specification-driven-ai-abstraction-layer.md)
- [AI Agent Design Patterns](ai-agent-design-patterns.md)
- [Configuration Management](configuration-management.md)

---

## 📚 Próximos Passos

1. **Implementar Git Provider** (prioridade alta)
2. **Implementar LLM Provider** (prioridade alta)
3. **Criar comando `/meta/create-abstraction`** para automatizar
4. **Documentar padrões em Knowledge Bases específicas**

---

**Última atualização**: 2025-11-25  
**Versão**: 1.0.0  
**Mantido por**: Sistema Onion
