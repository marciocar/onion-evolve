---
title: Runflow
category: platforms
version: 2025-11-18T21:19:48Z
created: 2025-11-18T21:19:48Z
updated: 2025-11-18T21:19:48Z
sources:
  - type: link
    url: https://runflow.ai/
    consulted_at: 2025-11-18T21:19:48Z
    description: Site oficial Runflow - Plataforma enterprise
  - type: mcp
    library: /websites/npmjs_package_runflow-ai_sdk
    consulted_at: 2025-11-18T21:19:48Z
    description: Documentação oficial via Context7 MCP
  - type: knowbase
    path: docs/draft/runflow.md
    consulted_at: 2025-11-18T21:19:48Z
    description: Rascunho de documentação existente no projeto
  - type: official-docs
    url: https://www.npmjs.com/package/@runflow-ai/sdk
    consulted_at: 2025-11-18T21:19:48Z
    description: Pacote npm oficial
---

# Runflow

## 📋 Visão Geral

**Runflow** é uma plataforma enterprise completa para criar, operar e gerenciar agentes de IA de ponta a ponta. O Runflow acelera a implantação de agentes de IA corporativos com uma plataforma completa: da integração com seus sistemas até insights de negócio, tudo auditável e sob seu controle.

O Runflow funciona como um **sistema operacional completo** para orquestrar agentes de IA dentro da sua empresa, permitindo construir agentes até **11x vezes mais rápido** do que métodos tradicionais.

### Características Principais

- **Plataforma Enterprise**: Solução completa para empresas com funcionalidades de segurança e governança
- **TypeScript-First**: Framework TypeScript nativo com controle total sobre prompts, tools e comportamento
- **Base de Conhecimento Nativa**: RAG corporativo sem depender de ferramentas externas
- **Observabilidade de Produção**: Traces em tempo real, análise de custos, taxa de sucesso
- **CLI para Desenvolvedores**: Ferramentas de linha de comando para desenvolvimento e deploy
- **SDK com Métodos Úteis**: SDK completo com abstrações e utilitários

⚠️ **Versão do Projeto**: 1.0.56 | **Versão Mais Recente**: 1.0.56 (atualizada)

Última verificação: 2025-11-18 via npm registry e documentação oficial

## 🎯 Conceitos Fundamentais

### O que é Runflow?

Runflow é uma plataforma que combina:

1. **SDK TypeScript**: Framework para desenvolvimento de agentes
2. **Plataforma Cloud**: Infraestrutura gerenciada para execução e monitoramento
3. **Conectores**: Integrações prontas com mais de 150 ferramentas (HubSpot, Twilio, Email, Slack, etc.)
4. **Base de Conhecimento**: Sistema RAG nativo para busca semântica
5. **Observabilidade**: Rastreamento completo de execuções, custos e performance

### Arquitetura de Agentes

Runflow permite criar diferentes tipos de agentes:

- **Agentes Simples**: Agentes conversacionais básicos
- **Agentes com Memória**: Agentes que lembram histórico de conversas
- **Agentes com RAG**: Agentes que buscam em bases de conhecimento
- **Agentes com Tools**: Agentes que executam ações específicas
- **Multi-Agent Systems**: Sistemas com múltiplos agentes especializados (padrão Supervisor)

### Workflows

Workflows permitem orquestrar múltiplos agentes, funções e conectores em sequências complexas, incluindo execução paralela e passos condicionais.

## 🏗️ Arquitetura e Componentes

### Componentes Principais

1. **Agents (Agentes)**
   - Core do SDK Runflow
   - Combinam LLMs, tools, memory e RAG
   - Suportam múltiplos modelos (OpenAI, Anthropic, AWS Bedrock)

2. **Tools (Ferramentas)**
   - Ações customizadas que agentes podem executar
   - Validação type-safe com Zod
   - Integração com APIs externas

3. **Memory (Memória)**
   - Histórico de conversação persistente
   - Sumarização automática para conversas longas
   - Busca em memória

4. **RAG / Knowledge Base**
   - Busca semântica em bases de conhecimento vetoriais
   - Agente decide quando buscar (Agentic RAG)
   - Suporte a múltiplas bases de conhecimento

5. **Workflows**
   - Orquestração de múltiplos passos
   - Execução sequencial e paralela
   - Passos condicionais

6. **Connectors (Conectores)**
   - Mais de 150 conectores prontos
   - HubSpot, Twilio, Email, Slack
   - Integração com bancos de dados, APIs e MCPs

7. **Observability (Observabilidade)**
   - Coleta automática de traces
   - Análise de custos
   - Métricas de performance

## 🚀 Guia de Início Rápido

### Instalação

```bash
npm install @runflow-ai/sdk
# ou
yarn add @runflow-ai/sdk
# ou
pnpm add @runflow-ai/sdk
```

### Requisitos

- Node.js >= 22.0.0
- TypeScript >= 5.0.0 (recomendado)
- Zod ^3.22.0 (incluído como dependência)

### Configuração

Crie um arquivo `.runflow/rf.json` na raiz do projeto:

```json
{
  "agentId": "your_agent_id",
  "tenantId": "your_tenant_id",
  "apiKey": "your_api_key",
  "apiUrl": "https://api.runflow.ai"
}
```

**Auto-Configuração**: O SDK busca automaticamente este arquivo no diretório atual e diretórios pais.

**Variáveis de Ambiente (Alternativa)**:

```bash
RUNFLOW_API_KEY=your_api_key
RUNFLOW_TENANT_ID=your_tenant_id
RUNFLOW_AGENT_ID=your_agent_id
RUNFLOW_API_URL=https://api.runflow.ai
```

### Exemplo Básico

```typescript
import { Agent, openai } from '@runflow-ai/sdk';

const agent = new Agent({
  name: 'Support Agent',
  instructions: 'You are a helpful customer support assistant.',
  model: openai('gpt-4o'),
});

const result = await agent.process({
  message: 'I need help with my order',
  sessionId: 'session_456',
});

console.log(result.message);
```

## 💡 Casos de Uso Comuns

### 1. Agente de Suporte ao Cliente com RAG

Agente sofisticado que busca em documentação, lembra contexto e cria tickets no HubSpot:

```typescript
import { Agent, openai, createTool } from '@runflow-ai/sdk';
import { hubspotConnector } from '@runflow-ai/sdk/connectors';
import { z } from 'zod';

const supportAgent = new Agent({
  name: 'Customer Support AI',
  instructions: `Você é um agente de suporte.
  - Busque na base de conhecimento
  - Lembre conversas anteriores
  - Crie tickets para casos complexos
  - Seja profissional e empático`,

  model: openai('gpt-4o'),

  memory: {
    type: 'conversation',
    maxTurns: 20,
    summarization: {
      enabled: true,
      threshold: 10,
    },
  },

  rag: {
    vectorStore: 'support-docs',
    k: 5,
    threshold: 0.7,
    searchPrompt: `Use searchKnowledge when user asks:
- Technical problems
- Process questions
- Specific information`,
  },

  tools: {
    createTicket: hubspotConnector.tickets.create,
    searchOrders: createTool({
      id: 'search-orders',
      description: 'Buscar pedidos do cliente',
      inputSchema: z.object({
        customerId: z.string(),
      }),
      execute: async ({ context }) => {
        const orders = await fetchOrders(context.input.customerId);
        return { orders };
      },
    }),
  },
});

const result = await supportAgent.process({
  message: 'Meu pedido #12345 ainda não chegou',
  sessionId: 'session_xyz',
  userId: 'user_123',
});
```

### 2. Sistema Multi-Agente (Padrão Supervisor)

Roteie solicitações para agentes especializados baseado na intenção:

```typescript
import { Agent, openai } from '@runflow-ai/sdk';

// Agentes especializados
const salesAgent = new Agent({
  name: 'Sales Specialist',
  instructions: 'Expert em vendas. Ajude com preços, demos e compras.',
  model: openai('gpt-4o'),
});

const supportAgent = new Agent({
  name: 'Technical Support',
  instructions: 'Expert técnico. Ajude com problemas técnicos.',
  model: openai('gpt-4o'),
  rag: { vectorStore: 'tech-docs', k: 5 },
});

// Agente supervisor
const supervisorAgent = new Agent({
  name: 'Supervisor',
  instructions: `Roteie solicitações para o especialista certo:
  - Sales: preços, demos, compras
  - Support: problemas técnicos, bugs
  Responda com: ROUTE_TO: [sales|support]`,
  model: openai('gpt-4o-mini'),
});
```

### 3. Workflow de Automação de Vendas

Automatize qualificação de leads, criação de deals e notificações:

```typescript
import { createWorkflow, Agent, openai } from '@runflow-ai/sdk';
import { z } from 'zod';

const qualifierAgent = new Agent({
  name: 'Lead Qualifier',
  instructions: 'Analise o lead e atribua nota (1-10) com justificativa.',
  model: openai('gpt-4o-mini'),
});

const salesWorkflow = createWorkflow({
  id: 'lead-to-deal',
  inputSchema: z.object({
    leadEmail: z.string().email(),
    leadName: z.string(),
    company: z.string(),
  }),
  outputSchema: z.any(),
})
  .agent('qualify', qualifierAgent, {
    promptTemplate: 'Analise este lead: {{input.leadName}} da {{input.company}}',
  })
  .connector('create-contact', 'hubspot', 'contacts', 'create', {
    email: '{{input.leadEmail}}',
    firstname: '{{input.leadName}}',
  })
  .build();
```

## ⚙️ Configuração e Setup

### Instalação da CLI

```bash
npm i -g @runflow-ai/cli
```

### Login

```bash
rf login --api-key SUA_API_KEY
```

### Testar com Front Interativo

```bash
rf test
```

Isso compila o código TypeScript e abre uma interface interativa para testar o agente.

### Estrutura de Projeto Recomendada

```
runflow-agent/
├── main.ts              # Configuração principal do agente
├── package.json         # Dependências e scripts
├── tsconfig.json        # Configuração TypeScript
├── .runflow/
│   └── rf.json         # Configuração Runflow
└── dist/               # Código compilado (gerado automaticamente)
```

## 📚 Recursos e Referências

### Documentação Oficial

- **Site Oficial**: https://runflow.ai/
- **NPM Package**: https://www.npmjs.com/package/@runflow-ai/sdk
- **Documentação SDK**: Disponível via Context7 MCP

### Modelos Suportados

**OpenAI:**
- gpt-4o
- gpt-4o-mini
- gpt-4-turbo
- gpt-3.5-turbo

**Anthropic (Claude):**
- Famílias por **tier**: opus, sonnet, haiku (e a linha Fable mais recente). Use sempre a versão **vigente** do tier conforme a disponibilidade no provider/Runflow — evite fixar um ID datado.

> ℹ️ O conjunto de IDs específicos suportados muda com o tempo. Consulte a documentação oficial do Runflow/Anthropic para os IDs vigentes (snapshot desta página: 2025-11).

**AWS Bedrock:**
- Claude (Bedrock)
- Titan
- Outros modelos

### Conectores Disponíveis

- **HubSpot**: Contatos, tickets, deals, empresas
- **Twilio**: WhatsApp, SMS
- **Email**: Envio de emails
- **Slack**: Mensagens e notificações
- **Mais de 150 conectores** prontos para usar

## 🔄 Atualizações e Roadmap

### Versão Atual

- **SDK**: 1.0.56 (novembro 2025)
- **Node.js**: Requer >= 22.0.0
- **TypeScript**: Recomendado >= 5.0.0

### Funcionalidades Principais

- ✅ Agentes com ciclo de vida completo (tools, memory, RAG)
- ✅ Multi-Agent com padrão Supervisor e roteamento
- ✅ Workflows com orquestração multi-step
- ✅ Memória com histórico e sumarização
- ✅ RAG Agentic com busca semântica
- ✅ Observabilidade com coleta de traces e custos
- ✅ Conectores para HubSpot, Twilio, Email, Slack
- ✅ Streaming com respostas em tempo real

## ⚠️ Limitações e Considerações

### Requisitos Técnicos

- **Node.js 22+**: Versão mínima obrigatória
- **TypeScript**: Recomendado para melhor experiência de desenvolvimento
- **API Key**: Necessária para uso da plataforma cloud

### Considerações de Uso

- **Custos**: Cada execução de agente consome tokens do modelo LLM escolhido
- **Rate Limits**: Verificar limites da API Runflow
- **Multi-tenancy**: Suportado via `companyId` e `tenantId`
- **Observabilidade**: Traces são coletados automaticamente para análise de custos

### Boas Práticas

- Use `sessionId` para manter contexto entre mensagens
- Configure `memory.maxTurns` apropriadamente para evitar custos desnecessários
- Use RAG apenas quando necessário (Agentic RAG decide automaticamente)
- Configure `observability: 'minimal'` em desenvolvimento para reduzir overhead

## 🎓 Aprofundamento

### Tipos de Traces

Runflow coleta automaticamente diferentes tipos de traces:

- `agent_execution` - Processamento completo do agente
- `tool_call` - Execução de ferramentas
- `llm_call` - Chamadas à API do LLM
- `rag_search` - Busca vetorial
- `memory_operation` - Acesso à memória
- `workflow_execution` - Processamento de workflow
- `connector_call` - Execução de conectores

### Context Management

Runflow fornece gerenciamento de contexto global:

```typescript
import { Runflow } from '@runflow-ai/sdk';

// Identificar usuário
Runflow.identify({
  type: 'phone',
  value: '+5511999999999',
});

// Obter estado completo
const state = Runflow.getState();

// Definir estado customizado
Runflow.setState({
  entityType: 'custom',
  entityValue: 'xyz',
  threadId: 'my_thread_123',
});
```

### Tipos de Identificação

- `phone` - WhatsApp/SMS
- `email` - Email do usuário
- `hubspot_contact` - Contato HubSpot
- Custom (order, ticket, etc.)

### LLM Standalone

Use LLMs diretamente sem criar agentes:

```typescript
import { LLM } from '@runflow-ai/sdk';

const llm = LLM.openai('gpt-4o', {
  temperature: 0.7,
  maxTokens: 2000,
});

const response = await llm.generate('What is the capital of Brazil?');
console.log(response.text);
console.log('Tokens:', response.usage);
```

### Streaming

Suporte a streaming para respostas em tempo real:

```typescript
const stream = await agent.processStream({
  message: 'Tell me a story',
  sessionId: 'session_456',
});

for await (const chunk of stream) {
  if (!chunk.done) {
    process.stdout.write(chunk.text);
  }
}
```

## 🏢 Por que Empresas Escolhem o Runflow

### Velocidade na Construção

Conseguem entregar agentes funcionando em semanas, não meses.

### Enterprise Ready

Todas as funcionalidades de segurança necessárias para atender empresas, incluindo:
- Multi-tenancy
- Auditoria completa
- Controle de acesso
- Observabilidade de produção

### Integração Real

Conectores com todos os sistemas já existentes:
- Mais de 150 conectores prontos
- Integração com bancos de dados
- APIs e MCPs
- Ferramentas de mercado

### Insights de Negócio

Acompanhe o resultado que o seu agente está gerando no negócio e faça a gestão dele como você faz de um humano:
- Métricas por categoria
- Uso por tenant
- Visão executiva e operacional

---

**Última atualização**: 2025-11-18T21:19:48Z  
**Versão documentada**: 1.0.56  
**Status**: Atualizado com informações mais recentes disponíveis

