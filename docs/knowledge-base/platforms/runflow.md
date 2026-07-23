---
title: Runflow
category: platforms
verified_at: 2026-07-23
source: docs.runflow.ai
version: "@runflow-ai/sdk 1.6.2"
created: 2025-11-18T21:19:48Z
updated: 2026-07-23
sources:
  - type: official-docs
    url: https://docs.runflow.ai/
    consulted_at: 2026-07-23
    description: Documentação oficial Runflow (re-verificada via WebFetch)
  - type: link
    url: https://registry.npmjs.org/@runflow-ai/sdk/latest
    consulted_at: 2026-07-23
    description: Registry npm — versão do pacote @runflow-ai/sdk (1.6.2)
  - type: official-docs
    url: https://www.npmjs.com/package/@runflow-ai/sdk
    consulted_at: 2026-07-23
    description: Pacote npm oficial
---

# Runflow

> **KB re-verificado contra `docs.runflow.ai` em 2026-07-23; Runflow é spin-off do IFTL.**
> Todo bloco de código e assinatura de API abaixo foi extraído VERBATIM das páginas oficiais consultadas
> nessa data. Onde a doc não cobre um ponto, está marcado explicitamente — nada foi preenchido de memória.
> O pin anterior deste KB (`@runflow-ai/sdk` 1.0.56, nov/2025) estava ~8 meses defasado; o SDK saltou para
> 1.6.2 e a superfície de API mudou substancialmente. Este documento reflete a doc atual.

## 📋 Visão Geral

**Runflow** é descrito na doc oficial como *"a complete platform for building, deploying, and managing AI
agents"* que *"combines a powerful TypeScript SDK with a command-line interface (CLI) and a management
portal."* Ou seja, três peças integradas: **SDK TypeScript** + **CLI (`rf`)** + **portal de gestão**.

Posicionamento do quickstart (verbatim): *"Runflow enables building AI agents with an official CLI,
supporting conversation memory, tool integration, and observability tracking."*

O SDK embute (verbatim, como fato do produto): *"axios, zod, date-fns, lodash, cheerio, and pino — No need
to install separately."*

## 🎯 Conceitos Fundamentais

O SDK organiza-se em torno de primitivas confirmadas nos exemplos oficiais:

- **`Agent`** — classe (`new Agent({...})`); combina modelo LLM, `instructions`, `memory`, `rag`, `tools`,
  e sub-agentes (padrão supervisor).
- **Model factories** — `openai(...)`, `anthropic(...)`, `bedrock(...)`, `groq(...)`, `gemini(...)`,
  `xai(...)`, `custom(...)`.
- **`createTool(...)`** — define uma tool com validação Zod.
- **`flow(...)`** — construtor fluente de workflows (recomendado); `.build()` + `.execute(...)`. (`createWorkflow(...)` é a forma **legada/deprecada**.)
- **`identify()` / `track()`** — observabilidade (namespace `@runflow-ai/sdk/observability`).
- **`Knowledge`, `KV`, `Memory`** — RAG, key-value store e memória de conversa.

### O `main.ts` (entrypoint do agente)

Todo agente Runflow precisa de um `main.ts` na raiz que exporta uma `async function main(input)` — é a
função que o engine chama ao receber mensagens (verbatim: *"The `main.ts` file is the only required file.
It must export an `async function main(input)`"*).

Parâmetros de entrada de `main()` (verbatim):

- `input.message` — mensagem do usuário
- `input.sessionId` — identificador de sessão
- `input.email`, `input.phone` — identificadores de usuário
- Campos adicionais vindos da integração

Retorno (verbatim): *"An object containing at least `message` (agent's response) plus optional metadata."*

```typescript
import { Agent, openai } from '@runflow-ai/sdk';
import { identify } from '@runflow-ai/sdk/observability';

const agent = new Agent({
  name: 'My Agent',
  instructions: 'You are a helpful assistant.',
  model: openai('gpt-4o'),
});

export async function main(input: any) {
  identify(input.email || input.phone || 'anonymous');

  const result = await agent.process({
    message: input.message,
    sessionId: input.sessionId,
  });

  return { message: result.message };
}
```

## 🏗️ Estrutura de Projeto

A doc mostra três padrões de organização (verbatim). O único arquivo obrigatório é `main.ts`.

**Simple:**

```
my-agent/
├── main.ts
├── tools/
│   └── weather.ts
├── .runflow/
│   └── rf.json
├── package.json
└── tsconfig.json
```

**Medium** (acrescenta `agent.ts`, `tools/index.ts` + tools separadas, `prompts/`):

```
my-agent/
├── main.ts
├── agent.ts
├── tools/
│   ├── index.ts
│   ├── create-ticket.ts
│   ├── search-orders.ts
│   └── send-email.ts
├── prompts/
│   └── index.ts
├── .runflow/
│   └── rf.json
├── package.json
└── tsconfig.json
```

**Complex (enterprise):** acrescenta `workflows/`, `connectors/`, `config/`.

## 🚀 Guia de Início Rápido

### Instalação

CLI (global):

```bash
npm i -g @runflow-ai/cli
```

SDK (no projeto — via npm, yarn ou pnpm):

```bash
npm install @runflow-ai/sdk
```

### Requisitos (verbatim)

- **Node.js**: `>= 22.0.0`
- **TypeScript**: `>= 5.0.0` (recomendado)

### Fluxo end-to-end (verbatim, quickstart)

```bash
npm i -g @runflow-ai/cli
rf login --api-key YOUR_API_KEY
rf create --name my-agent --template starter --yes
cd my-agent/
```

### Exemplo mínimo (quickstart, verbatim)

```typescript
import { Agent, openai } from "@runflow-ai/sdk";

const agent = new Agent({
  name: "Support Agent",
  instructions: "You are a helpful customer support assistant.",
  model: openai("gpt-4o"),
  memory: { maxTurns: 10 },
});

const result = await agent.process({
  message: "I need help with my order",
  sessionId: "session_456",
});
```

## ⚙️ Configuração (`.runflow/rf.json`, env vars, prioridade)

Arquivo `.runflow/rf.json` (verbatim):

```json
{
  "agentId": "your_agent_id",
  "tenantId": "your_tenant_id",
  "apiKey": "your_api_key",
  "apiUrl": "http://localhost:3001"
}
```

Descoberta (verbatim): o SDK *"automatically searches for `.runflow/rf.json` in the current directory and
parent directories."*

Carregamento automático para `process.env` (verbatim):

```typescript
import '@runflow-ai/sdk/init';
```

> A doc descreve que esse import carrega o `.runflow/rf.json` e popula `process.env` com as variáveis mapeadas (paráfrase — a tabela de mapeamento abaixo é o que a página lista literalmente).

Mapeamento config → env var (verbatim):

| Campo em `rf.json` | Variável de ambiente |
|--------------------|----------------------|
| `apiUrl`           | `RUNFLOW_API_URL`    |
| `apiKey`           | `RUNFLOW_API_KEY`    |
| `tenantId`         | `RUNFLOW_TENANT_ID`  |
| `agentId`          | `RUNFLOW_AGENT_ID`   |

Lista completa de env vars mostrada na doc de instalação (verbatim):

```bash
RUNFLOW_API_URL=http://localhost:3001
RUNFLOW_API_KEY=your_api_key_here
RUNFLOW_TENANT_ID=your_tenant_id
RUNFLOW_AGENT_ID=your_agent_id
RUNFLOW_EXECUTION_ID=exec_123
RUNFLOW_THREAD_ID=thread_456
RUNFLOW_ENV=development
RUNFLOW_LOCAL_TRACES=true
NODE_ENV=development
```

Ordem de prioridade (verbatim): *"Explicit code config → `.runflow/rf.json` → Environment variables →
Defaults."* Nota: *"existing environment variables are **never overwritten**."*

## 🤖 Agents — construtor completo

Bloco verbatim da doc de agents (mostra os campos suportados):

```typescript
import { Agent, anthropic } from '@runflow-ai/sdk';

const agent = new Agent({
  name: 'Advanced Support Agent',
  instructions: `You are an expert customer support agent.
    - Always be polite and helpful
    - Solve problems efficiently
    - Use tools when needed`,
  model: anthropic('claude-3-5-sonnet-20241022'),
  modelConfig: {
    temperature: 0.7,
    maxTokens: 4000,
    topP: 0.9,
    frequencyPenalty: 0,
    presencePenalty: 0,
  },
  memory: {
    maxTurns: 20,
    summarizeAfter: 50,
    summarizePrompt: 'Create a concise summary highlighting key points and decisions',
    summarizeModel: openai('gpt-4o-mini'),
  },
  rag: {
    vectorStore: 'support-docs',
    k: 5,
    threshold: 0.7,
    searchPrompt: 'Use for technical questions',
  },
  tools: {
    createTicket: ticketTool,
    searchOrders: orderTool,
  },
  maxToolIterations: 10,
  streaming: {
    enabled: true,
  },
  debug: true,
});
```

Métodos de execução (verbatim):

```typescript
const result = await agent.process(input: AgentInput): Promise<AgentOutput>;
const stream = await agent.processStream(input: AgentInput): AsyncIterable<ChunkType>;
const response = await agent.generate(input: string | Message[]): Promise<{ text: string }>;
```

> ⚠️ Verificar com a IFTL: os docs consultados não detalham a forma de cada chunk de `processStream`
> (`ChunkType`) — só a assinatura acima. (O KB antigo mostrava iteração com `chunk.done`/`chunk.text`; isso
> **não** foi confirmado na doc atual.)

## 🧠 Providers / Modelos

Lista real de providers suportados (verbatim, `providers/llm-provider.md`): *"Runflow supports eight
provider types: OpenAI, Anthropic, AWS Bedrock, Groq, Google Gemini, xAI, Azure OpenAI, and custom
OpenAI-compatible providers."*

```typescript
import { openai, anthropic, bedrock, groq, gemini, xai, custom } from '@runflow-ai/sdk';
```

Cada helper retorna um `ModelProvider` (verbatim):

```typescript
interface ModelProvider {
  provider: 'openai' | 'anthropic' | 'bedrock' | 'groq' | 'gemini' | 'xai' | 'custom';
  model: string;
  providerName?: string;
  legacy?: boolean;
}
```

Exemplos por provider (verbatim):

- **OpenAI** (`sk-...`): `openai('gpt-4o')`
- **Anthropic** (`sk-ant-...`): `anthropic('claude-sonnet-4-20250514')`
- **AWS Bedrock** (credenciais AWS): `bedrock('anthropic.claude-3-5-sonnet-20241022-v2:0')`
- **Groq** (`gsk-...`): `groq('llama-3.3-70b-versatile')`
- **Google Gemini** (`AIza...`): `gemini('gemini-2.5-flash')`
- **xAI** (`xai-...`): `xai('grok-4-1-fast-non-reasoning')`
- **Azure OpenAI**: `openai('gpt-4o', { providerName: 'Azure Production' })`
- **Custom / OpenAI-compatible**: `custom('llama3', 'Ollama Local')`

Setup (verbatim): configurar o provider no portal em **Settings > LLM Providers** com credenciais → Runflow
auto-descobre os modelos disponíveis → importar os helpers no código. Para múltiplas configs do mesmo tipo,
usar `providerName` para atingir um deployment específico.

> ⚠️ Inconsistência interna da própria doc (ambas citações verbatim, páginas diferentes): `llm-provider.md`
> usa `anthropic('claude-sonnet-4-20250514')`, enquanto `built-in-providers.md` usa
> `anthropic('claude-sonnet-4-6')`. Não harmonizado aqui — são os exemplos que estão na doc. Verificar com a
> IFTL qual o ID canônico.
>
> ⚠️ Verificar com a IFTL: a doc **não** publica uma lista fechada de model IDs por provider (diz que os
> modelos são auto-descobertos do portal). Os IDs acima são apenas os exemplos literais das páginas.

## 🛠️ Tools

Tools são criadas com `createTool`, com validação type-safe via Zod (verbatim):

```typescript
createTool({
  id: string,
  description: string,
  inputSchema: ZodSchema,
  outputSchema: ZodSchema,
  execute: async (params, toolContext) => {}
})
```

- `execute` recebe: `params` (inputs validados via Zod) e `toolContext` — objeto com
  `{ projectId, companyId, userId, sessionId, runflow }` para acessar as APIs da plataforma.
- Integrações a partir da tool: `toolContext.runflow.vectorSearch()` (vetorial),
  `toolContext.runflow.connector()` (conectores), ou chamadas async diretas a APIs externas.
- Tools são registradas no agente via o objeto `tools` na instanciação.

Exemplo real (verbatim, use-case de suporte):

```typescript
import { createTool } from '@runflow-ai/sdk';
import { z } from 'zod';

export const searchOrdersTool = createTool({
  id: 'search-orders',
  description: 'Search customer orders by order ID or customer email',
  inputSchema: z.object({
    orderId: z.string().optional().describe('Order ID (e.g., ORD-12345)'),
    customerEmail: z.string().email().optional().describe('Customer email'),
  }),
  execute: async (params, toolContext) => {
    const response = await fetch(
      `https://api.yourcompany.com/orders?id=${params.orderId || ''}&email=${params.customerEmail || ''}`,
      { headers: { 'Authorization': `Bearer ${process.env.ORDERS_API_KEY}` } }
    );
    if (!response.ok) return { found: false, error: 'Failed to search orders' };
    const orders = await response.json();
    if (!orders.length) return { found: false, query: params.orderId || params.customerEmail };
    return {
      found: true,
      orders: orders.map((o: any) => ({
        id: o.id, status: o.status, total: o.total,
        createdAt: o.createdAt, estimatedDelivery: o.estimatedDelivery,
      })),
    };
  },
});
```

## 🔌 Connectors

Verbatim: *"Connectors are dynamic integrations with external services defined in the Runflow backend."* Os
schemas são buscados **dinamicamente do backend** (a doc enfatiza que não há lista fechada de "providers
suportados" — schemas são lazy-loaded e cached). Features citadas: mock mode, resolução de path params,
auth flexível (API Key, Bearer, Basic, OAuth2), credential overrides multi-tenant, conversão type-safe de
JSON Schema para Zod.

Como agent tool (verbatim):

```typescript
import { createConnectorTool, Agent, openai } from '@runflow-ai/sdk';

const getClienteTool = createConnectorTool({
  connector: 'api-contabil',
  resource: 'get-customers',
  description: 'Get customer by ID from accounting API',
  enableMock: true,
});

const agent = new Agent({
  name: 'Accounting Agent',
  instructions: 'You help manage customers in the accounting system.',
  model: openai('gpt-4o'),
  tools: {
    getCliente: getClienteTool,
    listClientes: createConnectorTool({
      connector: 'api-contabil',
      resource: 'list-customers',
    }),
  },
});
```

Invocação direta (verbatim):

```typescript
import { connector } from '@runflow-ai/sdk';

const result = await connector('hubspot-prod', 'create-contact', {
  email: 'john@example.com',
  firstname: 'John',
  lastname: 'Doe',
});
```

Com opções de execução (verbatim):

```typescript
const options: ConnectorExecutionOptions = {
  credentialId: 'cred-prod-123',
  timeout: 10000,
  retries: 3,
  useMock: false,
};

const result = await connector('api-contabil', 'get-customer', { id: 123 }, options);
```

Helper `loadConnector` (verbatim):

```typescript
import { loadConnector } from '@runflow-ai/sdk';

const contabil = loadConnector('api-contabil');

const agent = new Agent({
  name: 'Accounting Agent',
  instructions: 'You manage accounting data.',
  model: openai('gpt-4o'),
  tools: {
    listClientes: contabil.tool('list-customers'),
    getCliente: contabil.tool('get-customer'),
    createCliente: contabil.tool('create-customer'),
    updateCliente: contabil.tool('update-customer'),
  },
});
```

> Connectors citados como exemplo na doc (não é lista fechada): `api-contabil`, `hubspot-prod`, `hubspot`,
> `api-elegibilidade`, `jsonplaceholder`.

## 🔗 MCP

Runflow suporta MCP de duas formas (verbatim):

1. **MCP Server Connector** — *"Connect to external MCP servers (Linear, GitHub, DeepWiki, etc.) and use
   their tools in your agents."*
2. **MCP Gateway** — *"Expose your Runflow connectors (REST APIs, databases, MCP servers) as a single MCP
   endpoint."*

Setup via portal: **Connectors > New Connector > MCP Server**; informar URL do servidor (ex.:
`https://mcp.linear.app/sse`), transporte SSE ou Streamable HTTP, auth (Bearer / Basic / OAuth2), e "Sync
Tools" para auto-discover. Sync (verbatim): *"Runflow connects to the MCP server, calls `tools/list`, and
creates a resource for each tool."*

Agent com MCP tools (via `createConnectorTool`, verbatim):

```typescript
import { Agent, openai, createConnectorTool } from '@runflow-ai/sdk';

const agent = new Agent({
  name: 'Project Manager',
  instructions: `You help manage Linear issues and projects.`,
  model: openai('gpt-4o'),
  tools: {
    listIssues: createConnectorTool({ connector: 'linear-mcp', resource: 'list-issues' }),
    createIssue: createConnectorTool({ connector: 'linear-mcp', resource: 'create-issue' }),
  },
});
```

MCP Gateway — Claude Desktop (verbatim):

```json
{
  "mcpServers": {
    "runflow": {
      "url": "https://api.runflow.ai/api/v1/gateways/my-gateway/mcp?apiKey=sk-your-key"
    }
  }
}
```

MCP Gateway — Claude Code CLI (verbatim):

```bash
claude mcp add runflow --transport http \
  "https://api.runflow.ai/api/v1/gateways/my-gateway/mcp?apiKey=sk-your-key"
```

Servidores MCP citados como suportados: Linear, DeepWiki, Sentry, Cloudflare, Notion — *"Any server
implementing the MCP protocol works."*

## 🌐 Web Search

Dá aos agentes acesso à internet em tempo real, como tool programática ou invocável pelo agente. Providers
suportados (tabela verbatim):

| Provider | Força | Free tier |
|----------|-------|-----------|
| Tavily   | AI-native, retorna conteúdo limpo + resposta AI | 1,000 req/mês |
| Exa      | Busca semântica/neural, páginas similares | 1,000 req/mês |
| Serper   | Resultados reais do Google, muito barato | 2,500 créditos |

Setup no agent (verbatim):

```typescript
import { Agent, openai, createWebSearchTool } from '@runflow-ai/sdk';

const agent = new Agent({
  name: 'Research Agent',
  instructions: 'You help users research topics using the internet.',
  model: openai('gpt-4o'),
  tools: {
    search: createWebSearchTool({
      provider: 'tavily',
      apiKey: process.env.TAVILY_API_KEY,
    }),
  },
});
```

Função programática (verbatim):

```typescript
import { webSearch } from '@runflow-ai/sdk';

const results = await webSearch('Runflow AI platform', {
  provider: 'tavily',
  apiKey: process.env.TAVILY_API_KEY,
  maxResults: 5,
  searchDepth: 'advanced',
});
```

Parâmetros (verbatim): `provider` (`'tavily'|'exa'|'serper'`, default `tavily`), `apiKey`, `connector`
(referência de credencial no modo plataforma), `maxResults` (default 5), `searchDepth`
(`'basic'|'advanced'`, default `basic`, específico do Tavily), `includeContent` (bool, default false).

## 🧵 Memory

Verbatim: *"Memory system provides intelligent conversation history management"* — com trimming automático
por `maxTurns`/`maxTokens` e compaction via summarization. Distinção citada: *"Appending fake messages to
conversation history to persist arbitrary data is unreliable."* — memória é para contexto de conversa; para
persistir valores JSON exatos, use o **KV Store**.

APIs — Standalone Memory (métodos estáticos, *"99% dos casos"*): `Memory.append()`, `Memory.getFormatted()`,
`Memory.getRecent(n)`, `Memory.search()`, `Memory.exists()`, `Memory.get()`, `Memory.clear()`.

Instance-based:

```typescript
new Memory({ memoryKey: string, maxTurns: number })
```

Session management: `Memory.list()`, `Memory.setStatus()` (lifecycle: qualified, closed, nurturing),
`Memory.summarize()`.

Configuração (tabela verbatim):

| Parâmetro | Tipo | Propósito |
|-----------|------|-----------|
| `maxTurns` | number | Limite de turnos de conversa |
| `maxTokens` | number | Teto de tokens |
| `summarizeAfter` | number | Dispara sumário em N turnos |
| `summarizePrompt` | string | Instruções custom de sumário |
| `summarizeModel` | ModelProvider | Modelo para sumários |

Acesso cross-session (verbatim): `Memory.get('phone:+5511999999999')`, `Memory.search(term, 'user:123')`.
Administração cross-agent via módulo `MemoryAdmin` (mantém isolamento por tenant).

## 🆔 Context Management (identify / estado)

Imports (verbatim):

```typescript
import { identify } from '@runflow-ai/sdk/observability';
import { Agent, openai } from '@runflow-ai/sdk';
import { Runflow } from '@runflow-ai/sdk/core';
```

`identify()` aceita string simples OU objeto (verbatim):

```typescript
identify(userPhone);                // string
identify({ type, value, userId, threadId });   // objeto
```

Objeto explícito (verbatim):

```typescript
{
  type: 'custom_type',      // hubspot_contact, order, document, session, etc.
  value: 'identifier_value',
  userId?: 'user_identifier',
  threadId?: 'custom_thread_id'
}
```

Verbatim: *"When you call identify(), you're telling Runflow **who** is interacting with your agent."* —
conecta memória, traces e métricas ao usuário. Aviso (best-practices, verbatim): *"Without identify(),
memory won't persist correctly between sessions and traces won't be linked to specific users."*

Estado global (verbatim): `Runflow.getState()`, `Runflow.get(key)`, `Runflow.setState(object)`,
`Runflow.clearState()`.

### Tipos de identificação auto-detectados (verbatim)

- **Email** (RFC 5322)
- **Phone** (E.164, com/sem `+`, com/sem formatação)
- **UUID** (v1–v5)
- **URL** (com/sem protocolo)
- Fallback: `"id"` genérico
- Custom via `type` explícito (ex.: `hubspot_contact`, `order`, `document`, `session`)

## 📚 RAG / Knowledge

Módulo `RAG` na doc: *"semantic search in vector knowledge bases"*, standalone ou integrado a agents.

```typescript
import { Knowledge } from '@runflow-ai/sdk';

const knowledge = new Knowledge({
  vectorStore: 'support-docs',
  k: 5,
  threshold: 0.7,
});
```

Métodos primários (verbatim):

- `search(query, options?)` — resultados com content + score
- `getContext(query, options?)` — saída formatada para LLMs
- `addDocument(text, metadata?)`
- `addFile(buffer, filename, options?)` — upload síncrono
- `ingestFile(buffer, filename, options?)` — processamento assíncrono (**SDK 1.3.2+**)
- `getIngestionJob(jobId)` — status do job assíncrono

RAG num Agent — verbatim: *"the SDK automatically creates a searchKnowledge tool that the LLM can decide
when to use."*

```typescript
const agent = new Agent({
  rag: {
    vectorStore: 'support-docs',
    k: 5,
    threshold: 0.7,
    searchPrompt: '...',
    toolDescription: 'Search in support documentation for solutions',
  },
});
```

Múltiplos vector stores: array `vectorStores` com `id, name, description, threshold, k, searchPrompt` por
store. Metadata filters (operadores `=, !=, >, >=, <, <=, @>, <@`):

```typescript
filters: {
  category: 'authentication',
  version: { value: "2.0", operator: '>=' },
}
```

Ingestão de CSV (`delimiter`, `contentColumns`, `metadataColumns`), flags de higiene (`stripHtml`,
`removeUrls`, `dropEmptyValues`, `normalizeWhitespace`, `dedupeUnits`), interceptor `onResultsFound`. Job de
ingestão expõe: `status, progress, processedChunks, totalChunks, documentId, error`.

## 🗄️ KV Store

Persiste valores JSON exatos, tenant-wide.

```typescript
import { KV } from '@runflow-ai/sdk';

const carts = KV.namespace('carts');
await carts.set('cart:5511999:items', { items: ['sku-1', 'sku-2'] }, { ttl: 3600 });
const cart = await carts.get('cart:5511999:items');
const keys = await carts.keys('cart:*:items');
await carts.delete('cart:5511999:items');
```

Métodos estáticos (namespace default): `KV.set`, `KV.get`, `KV.has`, `KV.delete`. Namespaces:
`KV.namespaces()`, `carts.clear()`. Paginação/busca: `listEntries({ pattern, limit, offset })`,
`listKeys({ limit })`, `getAll('cart:5511999:*')`. Metadados de entrada via `getEntry()` retorna
`{ key, value, expiresAt, createdAt, updatedAt }`. Provider custom:

```typescript
import { KV, FileKvProvider } from '@runflow-ai/sdk';
const kv = KV.namespace('test', { provider: new FileKvProvider('/tmp/kv-test') });
```

Limites (verbatim): valor máx **256 KB** por entrada; chave 1–512 chars; namespace máx 128 chars; TTL
inteiro ≥ 1 segundo.

## 🔀 Workflows

Verbatim: *"Workflows orchestrate agents, functions, and connectors into execution pipelines with
branching, parallel execution, iteration, and observability using a type-safe fluent API."*

Construtor `flow(...)` (verbatim):

```typescript
const workflow = flow({
  id: 'support-ticket',
  name: 'Support Ticket Workflow',
  inputSchema: z.object({
    email: z.string().email(),
    issue: z.string(),
  }),
  outputSchema: z.any(),
})
  .step('classify', async (input) => ({ /* ... */ }))
  .build();
```

Assinaturas de método (verbatim):

- `.step(id, handler)` ou `.step(id, options)`
- `.agent(id, agent, options?)`
- `.connector(id, slug, resource, action, data)`
- `.branch(id, { condition, onTrue, onFalse })`
- `.switch(id, { on, cases, default })`
- `.parallel(id, stepsArray)`
- `.foreach(id, { handler, concurrency? })`
- `.map(transformFunction)`
- `.output((results, input) => ({}))`

Contexto (`ctx`) acessível nos handlers (verbatim): `ctx.input`, `ctx.results` (resultados por step ID),
`ctx.workflowId`, `ctx.executionId`, `ctx.currentStep`, `ctx.metadata` (timing).

```typescript
.step('fetch-orders', async (input, ctx) => {
  const user = ctx.results['fetch-user'];
  const original = ctx.input;
  return { orders, userName: input.name };
})
```

Event listeners (verbatim):

```typescript
workflow.on('workflow:start', ({ workflowId, executionId }) => {});
workflow.on('step:complete', ({ stepId, durationMs }) => {});
workflow.on('workflow:error', ({ executionId, error }) => {});
```

**Disparo e API recomendada (verbatim, `core-concepts/workflows.md`):** o workflow construído roda via
`await workflow.execute({...})`. E a doc é explícita sobre qual API usar:

> *"The `flow()` API is the recommended way to create workflows. The legacy `createWorkflow()` still works
> but is deprecated."*

Padrão completo (verbatim): construir com `flow({ id, name, inputSchema, outputSchema })`, encadear
`.step(...)`, fechar com `.build()`, disparar com `.execute({...})`:

```typescript
const workflow = flow({ id: 'support-ticket', name: 'Support Ticket Workflow', inputSchema: z.object({ email: z.string().email(), issue: z.string() }), outputSchema: z.any() })
  .step('classify', async (input) => ({ /* ... */ }))
  .step('respond', async (input, ctx) => ({ /* usa ctx.results.classify */ }))
  .build();

const result = await workflow.execute({ email: 'customer@example.com', issue: 'Urgent billing problem' });
```

## 👥 Supervisor (multi-agente)

Verbatim: *"The supervisor pattern enables 'a parent agent automatically routes requests to specialized
child agents' by using an LLM call to analyze the user's message against each child agent's instructions."*
Os child agents ficam sob a chave `agents` do `Agent` pai:

```typescript
import { Agent, openai } from '@runflow-ai/sdk';

const agent = new Agent({
  name: 'Customer Service',
  instructions: `Route requests to the right specialist:
    - Sales: pricing, plans, purchases, demos
    - Support: technical issues, bugs, how-to questions
    - Billing: invoices, payments, refunds`,
  model: openai('gpt-4o-mini'),
  agents: {
    sales: {
      name: 'Sales Agent',
      instructions: 'Handle sales inquiries. Be consultative, not pushy.',
      model: openai('gpt-4o'),
    },
    support: {
      name: 'Support Agent',
      instructions: 'Solve technical problems step by step.',
      model: openai('gpt-4o'),
    },
    billing: {
      name: 'Billing Agent',
      instructions: 'Handle invoices, payments, and refund requests.',
      model: openai('gpt-4o'),
    },
  },
});

const result = await agent.process({
  message: 'I need a refund for my last invoice',
  sessionId: 'session_abc',
});
```

Propriedades do supervisor (verbatim): `name`, `instructions` (`string | PromptRef`, usado como system
prompt), `model`, `agents` (`Record<string, AgentConfig>`), `memory`, `observability`
(`'full' | 'standard' | 'minimal'`), `debug`. Child agents suportam `AgentConfig` completo — incluindo
`tools`, `rag`, `media`, `streaming`, `maxToolIterations`. Recomendação de custo (verbatim): *"Use a fast,
cheap model for routing and reserve powerful models for the specialists that do the real work."*

## 🔁 Cross-Agent API

Requisito de versão citado (verbatim): **`@runflow-ai/sdk >= 1.2.0`**.

```typescript
import { Agents } from '@runflow-ai/sdk/agents';
import { Executions } from '@runflow-ai/sdk/executions';
import { Threads } from '@runflow-ai/sdk/threads';
import { MemoryAdmin } from '@runflow-ai/sdk/memory-admin';
import { Reviews } from '@runflow-ai/sdk/reviews';

const agents = new Agents();
const executions = new Executions();
const threads = new Threads();
const admin = new MemoryAdmin();
const reviews = new Reviews();
```

Invocação síncrona (aguarda conclusão, timeout default 60s) e assíncrona (fire-and-forget):

```typescript
const result = await agents.invoke('customer-support', {
  message: 'Resumo das últimas 24h',
  userId: 'reviewer-agent',
  channel: 'review',
});

const { executionId } = await agents.invokeAsync('customer-support', {
  message: 'Olá! Notei que estamos sem falar há 24h. Tudo bem?',
  userId: '+5511999999999',
  channel: 'follow-up',
});
```

Referência universal a um agent (verbatim): *"Every cross-agent endpoint accepts the same three identifier
forms"* — UUID, slug (match exato), ou name (case-insensitive, deve ser não-ambíguo). Discovery:
`agents.list({ limit })`, `agents.get(ref)`.

Demais módulos: `executions.list/get/getDetails/iterateTraces`, `threads.list/getFullThread/getExecutions`,
`admin.list/get/append/search/summarize/clear` (memória cross-agent), `reviews.create/list/stats/resolve/
dismiss`.

## 📈 Observabilidade

Verbatim: coleta automática de traces de execução + API `track()` para eventos de negócio. Traces são
hierárquicos; workflows tracam cada step com hierarquia completa: `workflow_execution`, `workflow_step`,
`agent_execution`, `llm_call`.

Imports (verbatim):

```typescript
import {
  track, flushTrackEvents, message, startSpan, log, logEvent, logError,
  identify, startExecution, configureLogging
} from '@runflow-ai/sdk/observability';

import { Reviews } from '@runflow-ai/sdk';
import { Executions } from '@runflow-ai/sdk/executions';
```

Assinaturas (verbatim):

```typescript
track(eventName: string, properties?: Record<string, any>, options?: TrackOptions)
flushTrackEvents(): Promise<void>

message({
  role: 'user' | 'assistant' | 'system' | 'tool' | string,
  content: string | object,
  metadata?: Record<string, any>,
  parentId?: string
})

const span = startSpan(name: string);
span.end({ output?: any });

log(name: string, data?: { input?: any, output?: any }, options?: { parentId?: string });
logEvent(name: string, { input?, output?, metadata? });
logError(name: string, error: Error);

identify({ type: string, value: any });
const exec = startExecution({ name: string, input?: any });
exec.log(name: string, data?: any);
exec.setError(error: Error);
exec.end({ output?: any });
```

Configuração de observabilidade — presets string ou config granular (verbatim):

```typescript
observability: 'full' | 'standard' | 'minimal'

observability: {
  mode: 'standard',
  verboseLLM: boolean,
  verboseMemory: boolean,
  verboseTools: boolean,
  maxInputLength: number,
  maxOutputLength: number,
  onTrace: (trace) => trace | null | void
}
```

Convenção de `track()` (best-practices, verbatim): *"Use snake_case for event names and keep properties
flat (no nested objects)."*

```typescript
track('ticket_created', { priority: 'high', category: 'billing' });
track('issue_resolved', { resolution_time: 45, first_contact: true });
track('lead_qualified', { score: 8, source: 'website' });
```

> ⚠️ Verificar com a IFTL: a doc de observabilidade **não** mostrou lista de sinks externos suportados
> (Langfuse, Datadog, etc.) — só o hook `onTrace`/`configureLogging({ onTrace })` para enviar externamente.

## 💻 CLI (`rf`)

Propósito (verbatim): *"RunFlow CLI is a powerful command line interface to manage AI agents via API
Portal."*

Instalação e verificação:

```bash
npm i -g @runflow-ai/cli
rf --version
rf --help
```

Comandos principais (tabela verbatim):

| Comando | Descrição |
|---------|-----------|
| `rf create` | Gerar novos agentes a partir de templates |
| `rf login` | Autenticar com a API RunFlow |
| `rf switch` | Alternar entre perfis salvos |
| `rf agents` | Gerenciar agentes (deploy, clone, duplicar) |
| `rf kb` | Gerenciar bases de conhecimento para RAG |
| `rf prompts` | Gerenciar templates de prompts (CRUD) |
| `rf test` | Iniciar servidor local com interface web |

Modo não-interativo (verbatim):

```bash
rf create --name my-agent --template starter --yes
rf login --api-key sk-xxx --profile prod
rf prompts create support --content "You are a helpful assistant"
rf kb upload docs ./files --yes
rf agents delete --yes
```

Workflow completo (verbatim):

```bash
rf login
rf create
cd support-bot/
rf kb create support-docs
rf kb upload support-docs ./docs --yes
rf prompts create system --content "You are a support assistant"
rf test
rf agents deploy
```

### `rf test`

Flags (verbatim): `-p, --port <port>` (ex.: `rf test --port 4500`) e `--no-browser`. Características
(verbatim): zero-config (auto-detecta o agente de `.runflow/rf.json`), live reload em mudanças de arquivo,
portal web com monitoramento em tempo real, abre o browser em `http://localhost:PORT`, auto-seleciona porta
livre (3000–4000). File watching: todos os `.ts`/`.js` em `src/`, `package.json`, `.runflow/rf.json`.
Traces salvos localmente em `.runflow/traces.json`.

## 💡 Casos de Uso

Os três casos abaixo foram **substituídos** pelo código atual da doc oficial (o KB anterior trazia API
1.0.x com imports e formas que não existem mais — ex.: `@runflow-ai/sdk/connectors`, `LLM.openai`).

### 1. Suporte ao cliente com RAG

`agent.ts` (verbatim):

```typescript
import { Agent, openai } from '@runflow-ai/sdk';
import { supportPrompt } from './prompts';
import { searchOrdersTool, createTicketTool } from './tools';

export const supportAgent = new Agent({
  name: 'Customer Support',
  instructions: supportPrompt,
  model: openai('gpt-4o'),

  memory: {
    maxTurns: 20,
    summarizeAfter: 15,
    summarizePrompt: 'Summarize key issues, actions taken, and pending items',
  },

  rag: {
    vectorStore: 'support-docs',
    k: 5,
    threshold: 0.7,
    searchPrompt: `Search the knowledge base when the customer asks about:
- Product features or how things work
- Pricing or plan details
- Policies (refund, cancellation, etc.)
- Technical troubleshooting steps`,
  },

  tools: {
    searchOrders: searchOrdersTool,
    createTicket: createTicketTool,
  },

  observability: 'full',
});
```

`main.ts` (verbatim):

```typescript
import { identify, track } from '@runflow-ai/sdk/observability';
import { supportAgent } from './agent';

export async function main(input: any) {
  if (!input?.message || typeof input.message !== 'string') {
    return { error: 'message is required' };
  }

  identify(input.email || input.phone || input.userId || 'anonymous');

  try {
    const result = await supportAgent.process({
      message: input.message,
      sessionId: input.sessionId,
    });

    track('support_request', {
      channel: input.channel || 'api',
      resolved: !result.metadata?.toolsUsed?.includes('create-ticket'),
    });

    return { message: result.message, metadata: result.metadata };
  } catch (error) {
    console.error('[support-agent] Error:', error);
    return { error: 'An error occurred. Please try again.' };
  }
}
```

Setup da Knowledge Base via CLI (verbatim):

```bash
rf kb create support-docs
rf kb upload support-docs ./docs/faq.md
rf kb upload support-docs ./docs/
rf kb search support-docs "How do I cancel my subscription?"
```

### 2. Sistema multi-agente (supervisor)

`supervisor.ts` (verbatim, trecho central — child agents recebem config estendida por spread):

```typescript
import { Agent, openai } from '@runflow-ai/sdk';
import { salesAgentConfig } from './agents/sales';
import { supportAgentConfig } from './agents/support';
import { billingAgentConfig } from './agents/billing';
import { searchOrdersTool, createTicketTool, checkInvoiceTool } from './tools';

export const supervisorAgent = new Agent({
  name: 'Customer Service Supervisor',
  instructions: `You route customer requests to the right specialist.
  ...
  - You do NOT answer questions directly — you route to specialists`,

  model: openai('gpt-4o-mini'), // Cheap model for routing

  agents: {
    sales: salesAgentConfig,
    support: {
      ...supportAgentConfig,
      tools: { searchOrders: searchOrdersTool, createTicket: createTicketTool },
      rag: { vectorStore: 'support-docs', k: 5, threshold: 0.7 },
    },
    billing: {
      ...billingAgentConfig,
      tools: { checkInvoice: checkInvoiceTool, createTicket: createTicketTool },
    },
  },

  memory: {
    maxTurns: 30,
    summarizeAfter: 20,
    summarizePrompt: 'Summarize: customer intent, which specialist handled it, actions taken, pending issues',
  },

  observability: 'full',
});
```

Cada `agents/<x>.ts` exporta uma config plain (não uma instância `Agent`), ex. `salesAgentConfig =
{ name, instructions, model: openai('gpt-4o') }`. O roteamento supervisor→especialista é feito pelo Runflow
(verbatim: *"Runflow handles routing automatically"*; o algoritmo interno não é mostrado).

### 3. Automação de vendas (workflow)

> ⚠️ **A doc de `use-cases/sales-automation.md` ainda usa `createWorkflow(...)` — que é a API LEGADA/DEPRECADA** (ver §Workflows: `flow()` é a recomendada). O código abaixo é verbatim da doc, mantido por fidelidade, mas em código novo prefira `flow(...).step(...).build()` + `.execute(...)`.

`workflows/lead-to-deal.ts` (verbatim — API legada `createWorkflow`):

```typescript
import { createWorkflow } from '@runflow-ai/sdk';
import { z } from 'zod';
import { qualifierAgent } from '../agents/qualifier';
import { copywriterAgent } from '../agents/copywriter';
import { QUALIFICATION_THRESHOLD } from '../config/settings';

export const leadToDealWorkflow = createWorkflow({
  id: 'lead-to-deal',
  inputSchema: z.object({
    leadEmail: z.string().email(),
    leadName: z.string(),
    company: z.string(),
    role: z.string().optional(),
    source: z.string(),
    notes: z.string(),
  }),
  outputSchema: z.any(),
})
  .agent('qualify', qualifierAgent, {
    promptTemplate: `Analyze this lead:
Name: {{input.leadName}}
Company: {{input.company}}
...`,
  })
  .condition(
    'check-score',
    (ctx) => {
      try {
        const analysis = JSON.parse(ctx.stepResults.get('qualify').text);
        return analysis.score >= QUALIFICATION_THRESHOLD;
      } catch {
        return false;
      }
    },
    [
      { id: 'create-contact', type: 'connector', config: { connector: 'hubspot', resource: 'contacts', action: 'create', parameters: { /* ... */ } } },
      { id: 'write-email', type: 'agent', config: { agent: copywriterAgent, promptTemplate: '...' } },
    ],
    [
      { id: 'log-skipped', type: 'function', config: { execute: async (input, ctx) => ({ status: 'skipped' }) } },
    ]
  )
  .build();
```

`main.ts` dispara com `.execute(...)` (verbatim): `const result = await leadToDealWorkflow.execute({ ... })`.

> Nota de design da doc: aqui usa-se **Workflow** (não Agent) porque *"é um pipeline — dados entram, passam
> por etapas, saem. Não há conversa"*. Os tipos de step vistos no exemplo são `connector`, `agent`,
> `function` (a lista completa de `type` não é enumerada na doc).

## ✅ Best Practices (verbatim)

- **Sempre `identify()`**: sem ele, a memória não persiste entre sessões e traces não se ligam ao usuário.
- **Validação de input** no `main()`:

```typescript
export async function main(input: any) {
  if (!input?.message || typeof input.message !== 'string') {
    return { error: 'message is required and must be a string' };
  }
  if (input.message.trim().length === 0) {
    return { error: 'message cannot be empty' };
  }
}
```

- **Tools**: descrições claras e específicas; `debug: true` para visibilidade; cuidado com
  `maxToolIterations` restritivo demais.
- **RAG**: se não retorna resultados, checar nome do vector store, ajustar `k`, ajustar `threshold`
  (*"lower = more results"*).
- **Type safety**: manter TypeScript `>= 5.0.0` e importar tipos via `import type`.

## ⚠️ Limitações e Considerações

- **Node.js 22+** obrigatório; **TypeScript 5.0+** recomendado.
- **Credenciais de provider LLM** e connectors são configuradas no **portal** antes do uso em código.
- **Custos**: cada execução consome tokens do modelo escolhido; traces são coletados automaticamente para
  análise de custo.
- **Multi-tenancy**: via `tenantId` / `companyId`; isolamento por tenant citado no MCP e MemoryAdmin.
- **KV Store**: valor máx 256 KB, chave 1–512 chars, namespace máx 128 chars, TTL ≥ 1s.

### Pontos não cobertos pela doc consultada (não inventar)

- **Número de versão dentro da doc**: nenhuma página cita literalmente "1.6.2". O `1.6.2` deste KB vem do
  **registry npm** (verificado 2026-07-23). A doc só cita mínimos pontuais: cross-agent exige
  `@runflow-ai/sdk >= 1.2.0`; `Knowledge.ingestFile` requer **SDK 1.3.2+**. Confirmar com a IFTL a versão
  contra a qual a doc pública está escrita.
- **Forma dos chunks de `processStream`** (`ChunkType`): não detalhada.

- **Sinks de observabilidade externos** (Langfuse/Datadog/etc.): não listados.
- **Lista fechada de model IDs / connectors / providers de KV**: a doc trata como auto-descoberta do
  portal ou schemas dinâmicos do backend — não há catálogo fechado nas páginas consultadas.
- **Payloads de retorno** (JSON exato) dos métodos de RAG/KV/cross-agent: não mostrados na íntegra.

---

**Última verificação**: 2026-07-23 (docs.runflow.ai via WebFetch + registry npm)
**Versão documentada**: `@runflow-ai/sdk` 1.6.2 (registry) · doc pública cita mínimos 1.2.0 / 1.3.2+
**Status**: Re-verificado; corpo alinhado à doc atual. Antes de tratar como referência definitiva (ex.: Tech
Sync com a IFTL), fechar os "pontos não cobertos" acima.
