# Specification-Driven AI Abstraction Layer

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2025-11-25 |
| **Última Atualização** | 2026-06-13 |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Padrões de Desenvolvimento de IA |
| **Tags** | `ai-patterns`, `abstraction-layer`, `spec-as-code`, `claude-code-development` |

### Fontes

- Task Manager Abstraction (`.claude/utils/task-manager/`)
- [Adapter Pattern - GoF](https://refactoring.guru/design-patterns/adapter)
- [Factory Pattern - GoF](https://refactoring.guru/design-patterns/factory-method)
- Práticas do Sistema Onion
- Princípios de Prompt Engineering

---

## 🎯 Visão Geral

O **Specification-Driven AI Abstraction Layer** (SDAAL) é um padrão de desenvolvimento de IA onde **documentação Markdown substitui código executável**, permitindo que LLMs "executem" abstrações complexas baseadas em especificações estruturadas.

### Definição

```
SDAAL = Markdown Estruturado + Interfaces TypeScript + Documentação Executável por IA
```

**Princípio Central**: LLMs não executam código diretamente, mas podem simular comportamentos complexos quando as especificações são precisas, tipadas e bem estruturadas.

### Diferença de Spec-as-Code

| Aspecto | Spec-as-Code | SDAAL |
|---------|--------------|-------|
| **Foco** | Requisitos de negócio | Abstrações técnicas |
| **Saída** | Código gerado | Comportamento simulado |
| **Execução** | Compilação/Runtime | "Runtime mental" da IA |
| **Validação** | Testes automatizados | Consistência de respostas |

---

## 🧠 Fundamentos Teóricos

### Por que Funciona?

LLMs como Claude são excelentes em:

1. **Interpretar tipos TypeScript**: Entendem contratos de interface
2. **Seguir padrões documentados**: Aplicam lógica descrita em Markdown
3. **Mapear conceitos**: Traduzem entre sistemas (ClickUp → Asana)
4. **Manter consistência**: Respeitam comportamentos definidos

```
┌─────────────────────────────────────────────────────────────────┐
│                     MODELO MENTAL DA IA                         │
│                                                                 │
│   interface.md  →  "Entendo o contrato"                         │
│   adapter.md    →  "Sei como mapear para este provedor"         │
│   factory.md    →  "Sei qual adapter usar"                      │
│   detector.md   →  "Sei identificar o contexto"                 │
│                                                                 │
│   RESULTADO: IA "executa" a abstração consistentemente          │
└─────────────────────────────────────────────────────────────────┘
```

### Analogia: Código vs Documentação

```
Código Tradicional          SDAAL
─────────────────           ─────
function add(a, b) {        # Função add
  return a + b;             Recebe dois números `a` e `b`.
}                           Retorna a soma de ambos.
                            
Executado: VM/Runtime       Executado: Cognição do LLM
```

---

## 🏗️ Arquitetura do Padrão

### Componentes Essenciais

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPECIFICATION LAYER                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│  │ interface  │  │   types    │  │  factory   │  │  detector  │ │
│  │    .md     │  │    .md     │  │    .md     │  │    .md     │ │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘ │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ADAPTER LAYER                              │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│   │  jira   │ │ clickup │ │  asana  │ │ linear  │ │  none   │   │
│   │   .md   │ │   .md   │ │   .md   │ │   .md   │ │   .md   │   │
│   └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXECUTION LAYER                              │
│                  (MCP Tools / API Calls)                        │
│                                                                 │
│  jira:REST   clickup:API   asana:API   linear:GQL   none:local  │
└─────────────────────────────────────────────────────────────────┘
```

### Fluxo de "Execução"

```
1. Comando Onion invoca operação
   │
   ▼
2. IA lê factory.md → detectProvider()
   │
   ▼
3. IA identifica provedor configurado (via env)
   │
   ▼
4. IA lê adapter específico (clickup.md, asana.md)
   │
   ▼
5. IA "executa" o método conforme especificação
   │
   ▼
6. IA chama MCP tool real com parâmetros mapeados
   │
   ▼
7. IA normaliza resposta conforme types.md
   │
   ▼
8. Retorna resultado padronizado
```

---

## 📐 Estrutura de Arquivos

### Template de Abstraction Layer

```
.claude/utils/<abstraction>/
├── README.md           # Visão geral e uso rápido
├── interface.md        # Interface/Contrato principal
├── types.md            # Tipos de entrada e saída
├── factory.md          # Criação de instâncias
├── detector.md         # Detecção de contexto/provedor
└── adapters/
    ├── provider-a.md   # Implementação Provider A
    ├── provider-b.md   # Implementação Provider B
    └── none.md         # Fallback (Null Object Pattern)
```

### Estrutura de Cada Arquivo

#### interface.md

```markdown
# 📐 Interface I<Nome>

## 🎯 Propósito
[O que esta interface define]

## 📋 Interface Completa
\`\`\`typescript
interface I<Nome> {
  // Propriedades
  readonly property: Type;
  
  // Métodos
  method(input: Input): Promise<Output>;
}
\`\`\`

## 📊 Métodos por Categoria
| Categoria | Métodos | Descrição |
|-----------|---------|-----------|
| CRUD | create, get, update, delete | Operações básicas |

## 🧪 Exemplo de Uso
\`\`\`typescript
const instance = getFactory();
await instance.method({ ... });
\`\`\`
```

#### adapter.md

```markdown
# 🔵 <Provider> Adapter

## 🎯 Propósito
Implementação do I<Nome> para <Provider>.

## 📋 Configuração
\`\`\`bash
PROVIDER_API_TOKEN=xxx
PROVIDER_WORKSPACE_ID=xxx
\`\`\`

## 🔧 Implementação
\`\`\`typescript
class <Provider>Adapter implements I<Nome> {
  // Cada método com mapeamento específico
  async method(input): Promise<Output> {
    const result = await mcp__provider__call({
      // Mapear campos de input → provider
    });
    return this.normalize(result);
  }
  
  // Helpers de normalização
  private normalize(raw): Output { ... }
}
\`\`\`

## 📊 Mapeamento de Campos
| Interface | Provider API | Notas |
|-----------|-------------|-------|
| name | title | Direto |
| status | state | Mapeado |
```

---

## 🔑 Padrões de Design Aplicados

### 1. Adapter Pattern (Documental)

Cada provedor tem um adapter documentado que traduz:
- **Input**: Interface genérica → API específica
- **Output**: Resposta específica → Formato normalizado

```markdown
## Mapeamento de Status

| Interface | ClickUp | Asana |
|-----------|---------|-------|
| todo | "to do" | To Do (seção) |
| in_progress | "in progress" | In Progress |
| done | "done" | completed: true |
```

### 2. Factory Pattern (Documental)

A factory "decide" qual adapter usar baseado em configuração:

```typescript
function getTaskManager(): ITaskManager {
  const provider = detectProvider();
  
  switch (provider) {
    case 'clickup': return new ClickUpAdapter();
    case 'asana': return new AsanaAdapter();
    default: return new NoProviderAdapter();
  }
}
```

### 3. Strategy Pattern (Implícito)

Cada adapter implementa a mesma interface com estratégias diferentes:

```
ITaskManager.createTask()
  │
  ├── ClickUpAdapter: mcp__clickup__create_task
  ├── AsanaAdapter: mcp__asana__create_task
  └── NoProviderAdapter: retorna objeto local
```

### 4. Null Object Pattern

O `NoProviderAdapter` permite funcionamento sem provedor:

```typescript
class NoProviderAdapter implements ITaskManager {
  readonly isConfigured = false;
  
  async createTask(input): Promise<TaskOutput> {
    console.warn('⚠️ Modo offline - task local');
    return {
      id: `local-${Date.now()}`,
      provider: 'none',
      ...input
    };
  }
}
```

### 5. Context Injection Pattern

O detector injeta informações sobre o ambiente:

```typescript
function validateProviderMatch(taskId, currentProvider): ValidationResult {
  const detected = detectProviderFromTaskId(taskId);
  
  if (detected !== currentProvider) {
    return {
      valid: false,
      warning: `⚠️ Task ${taskId} é de ${detected}, mas ${currentProvider} está configurado`
    };
  }
  
  return { valid: true };
}
```

---

## 📝 Formato Otimizado para IA

### Elementos que Ajudam a IA

| Elemento | Propósito | Exemplo |
|----------|-----------|---------|
| **Emojis em headers** | Navegação visual | `## 🎯 Propósito` |
| **Separadores ASCII** | Divisões claras | `═══════════════` |
| **Tabelas de mapeamento** | Tradução entre sistemas | Status/Priority |
| **Code blocks TypeScript** | Tipagem precisa | `interface ITask` |
| **Exemplos práticos** | Demonstração de uso | `🧪 Exemplos de Uso` |
| **Referências cruzadas** | Contexto adicional | `[Ver types.md]` |

### Estrutura de Seções Recomendada

```markdown
# 📐 Nome do Componente

## 🎯 Propósito
[1-2 parágrafos explicando o objetivo]

---

## 📋 Definição Principal
[Interface/Classe/Função principal em TypeScript]

---

## 📊 Tabelas de Referência
[Mapeamentos, enums, constantes]

---

## 🔧 Métodos/Funções
[Detalhamento de cada operação]

---

## 🧪 Exemplos de Uso
[Código prático demonstrando uso]

---

## 📚 Referências
[Links para outros arquivos relacionados]
```

---

## ✅ Checklist de Implementação

### Ao Criar Nova Abstraction Layer

- [ ] **README.md**: Visão geral, estrutura de arquivos, uso rápido
- [ ] **interface.md**: Contrato completo com todos os métodos
- [ ] **types.md**: Todos os tipos de entrada e saída
- [ ] **factory.md**: Lógica de criação de instâncias
- [ ] **detector.md**: Lógica de detecção de contexto
- [ ] **adapters/**: Um arquivo por provedor suportado
- [ ] **adapters/none.md**: Fallback para modo offline

### Qualidade de Documentação

- [ ] TypeScript em todos os code blocks de interface/tipos
- [ ] Tabelas de mapeamento para traduções entre sistemas
- [ ] Exemplos práticos de uso em cada arquivo
- [ ] Referências cruzadas entre arquivos
- [ ] Emojis consistentes para navegação
- [ ] Versionamento e data de criação

---

## 🔄 Comparação com Abordagens Tradicionais

### Código Executável vs SDAAL

| Aspecto | Código Tradicional | SDAAL |
|---------|-------------------|-------|
| **Formato** | `.ts`, `.js`, `.py` | `.md` (Markdown) |
| **Execução** | Runtime (Node, Python) | Cognição do LLM |
| **Debugging** | Breakpoints, logs | Verificar resposta da IA |
| **Testes** | Unit tests, integration | Consistência de output |
| **Versionamento** | Git (código) | Git (documentação) |
| **Portabilidade** | Requer ambiente | Funciona em qualquer LLM |
| **Manutenção** | Refatoração | Atualização de docs |

### Quando Usar SDAAL

✅ **Use quando:**
- Sistema opera principalmente via LLM
- Precisa de flexibilidade para trocar provedores
- Deseja documentação e implementação unificadas
- Trabalha com assistentes de código (Claude Code, Copilot)

❌ **Não use quando:**
- Precisa de performance crítica
- Requer execução determinística
- Sistema não envolve IA
- Complexidade algorítmica alta

---

## 🏆 Instância Canônica: Task Manager Abstraction

O **Task Manager Abstraction** (`.claude/utils/task-manager/`) é a **implementação de referência** do padrão SDAAL no Sistema Onion. Toda nova abstraction layer deve tomar esta implementação como modelo.

> Documentação completa: [`docs/knowledge-base/concepts/task-manager-abstraction.md`](task-manager-abstraction.md)
> Código-fonte: [`.claude/utils/task-manager/`](../../../.claude/utils/task-manager/)

> **O eixo abstraído varia; o contrato não.** O `adapter` não precisa ser um *provider externo*. O SDAAL já
> generaliza para **papéis**: `trust` (`.claude/utils/trust/`) tem adapters por **tier** (source/hub/standalone/
> consumer); `federation-transport`, por **via** (git-async/local/a2a-live). E o design-alvo **`branch-roles`**
> (ADR [branch-roles-sdaal](../../analysis/onion-adr-branch-roles-sdaal-2026-07.md),
> `status: proposto/gated`) abstrai **papéis de branch/ambiente** — o adapter é a **topologia de branching**
> (gitflow/trunk-based/multi-lineage/none), e cada projeto declara qual branch cumpre qual papel
> (`integration`/`staging`/`production`/…). Provider externo, tier, topologia — o eixo muda; **interface +
> factory + adapters permanecem**.
>
> ⚠️ **Correção (2026-07-17):** esta nota afirmava que *detector + Null Object* **também** permaneciam em
> todas as instâncias. **É falso** — `trust` e `federation-transport` não têm `none.md` (um adapter real já
> é o fallback total), e `federation-transport` detecta por script. O formato-**papel** admite essa dispensa
> **desde que declarada no README** (precedente: a divergência `cli`-default do forge, `integrations.md`
> §1.0). Critério de quando algo vira SDAAL: [Doutrina de Abstração](onion-abstraction-doctrine.md).

### Por que é canônica?

| Princípio SDAAL | Como o Task Manager exemplifica |
|-----------------|--------------------------------|
| **Spec define o quê** | `interface.md` + `types.md` descrevem o contrato independente de provider |
| **Adapter define o como** | Cada `adapters/<provider>.md` decide como chegar ao provider (transporte) |
| **Factory/Detector** | `factory.md` + `detector.md` isolam a decisão de qual adapter usar |
| **Null Object** | `adapters/none.md` garante modo offline gracioso |
| **Portabilidade** | Mesmo comando funciona em Jira, ClickUp, Asana e Linear sem alteração |

### Modelo de Transporte: API-first + MCP opcional

A instância canônica introduz uma dimensão extra ao padrão: **o adapter também decide o transporte**, não apenas o mapeamento de campos. Isso é controlado pela variável `TASK_MANAGER_TRANSPORT`:

```
TASK_MANAGER_TRANSPORT=api   ← padrão; REST API direta
TASK_MANAGER_TRANSPORT=mcp   ← opcional; MCP quando disponível, fallback para API
```

```
┌──────────────────────────────────────────────────────────────────┐
│                    CAMADAS DO TASK MANAGER                       │
│                                                                  │
│  SPEC (o quê)                                                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│  │ interface  │  │   types    │  │  factory   │  │  detector  │ │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘ │
│                           │                                      │
│  ADAPTER (como)           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  adapter.md  →  lê TASK_MANAGER_TRANSPORT                  │  │
│  │                                                            │  │
│  │   api (default) ──► REST API do provider                  │  │
│  │   mcp (opcional) ──► MCP server → ou fallback para API    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                           │                                      │
│  EXECUÇÃO                 ▼                                      │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  POST /api/v3/tasks   |   mcp__clickup__create_task       │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

**Regra de ouro**: a spec (interface/types) nunca menciona transporte — isso é responsabilidade exclusiva do adapter. Quem consome a abstração não sabe (e não precisa saber) se a chamada foi via REST ou MCP.

### Estrutura de Arquivos (referência)

```
.claude/utils/task-manager/
├── README.md           # Visão geral e uso rápido
├── interface.md        # ITaskManager — contrato agnóstico
├── types.md            # CreateTaskInput, TaskOutput, etc.
├── factory.md          # getTaskManager() + NoProviderAdapter
├── detector.md         # detectProvider(), TASK_MANAGER_TRANSPORT
└── adapters/
    ├── jira.md         # REST v3/v2, ADF, JQL, transitions
    ├── clickup.md      # REST API; MCP opcional
    ├── asana.md        # REST API; MCP opcional
    ├── linear.md       # GraphQL API; MCP opcional
    └── none.md         # Null Object — modo offline
```

### Fluxo de execução com transporte explícito

```
1. /engineer/start TASK-123
          │
          ▼
2. factory.md → detectProvider()
          │  TASK_MANAGER_PROVIDER=clickup
          ▼
3. adapters/clickup.md carregado
          │  lê TASK_MANAGER_TRANSPORT
          ├─ api (default) → POST https://api.clickup.com/api/v2/task
          └─ mcp           → mcp__clickup__get_task(...)
          │
          ▼
4. resposta normalizada conforme types.md
   status "in progress" → TaskStatus.in_progress
          │
          ▼
5. TaskOutput padronizado devolvido ao comando
```

---

## ⚠️ Anti-Patterns

### 1. Documentação Incompleta

**❌ Problema:**
```markdown
# Adapter X
Faz coisas com o Provider X.
```

**✅ Solução:**
```markdown
# Adapter X

## Configuração
- PROVIDER_X_TOKEN: Token de API (obrigatório)

## Métodos
### createTask(input: CreateTaskInput): Promise<TaskOutput>
Cria task no Provider X.
\`\`\`typescript
await mcp__provider__create({
  title: input.name,
  body: input.description
});
\`\`\`
```

### 2. Tipos Vagos

**❌ Problema:**
```typescript
interface ITaskManager {
  createTask(data: any): Promise<any>;
}
```

**✅ Solução:**
```typescript
interface ITaskManager {
  createTask(input: CreateTaskInput): Promise<TaskOutput>;
}

interface CreateTaskInput {
  name: string;           // Obrigatório
  description?: string;   // Opcional
  priority?: TaskPriority;
}
```

### 3. Sem Fallback

**❌ Problema:** Sistema quebra se provedor não configurado

**✅ Solução:** Implementar `NoProviderAdapter` com degradação graciosa

### 4. Mapeamentos Inconsistentes

**❌ Problema:** Cada adapter mapeia diferente sem documentação

**✅ Solução:** Tabelas de mapeamento explícitas em cada adapter

---

## 🔗 Relação com Outros Padrões

### Spec-as-Code

SDAAL é uma aplicação de [Spec-as-Code](spec-as-code-strategy.md) focada em abstrações técnicas ao invés de requisitos de negócio.

### AI Agent Design Patterns

SDAAL complementa [AI Agent Design Patterns](ai-agent-design-patterns.md) fornecendo a camada de infraestrutura que agentes utilizam.

### Task Manager Abstraction

O [Task Manager Abstraction](task-manager-abstraction.md) é a **instância canônica** do padrão SDAAL no Sistema Onion. Ilustra o modelo **transporte API-first + MCP opcional** (`TASK_MANAGER_TRANSPORT`): a spec define o contrato; cada adapter decide o transporte (REST por padrão, MCP quando ativado). Ver seção [🏆 Instância Canônica](#-instância-canônica-task-manager-abstraction) para detalhes.

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA ONION                                │
│                                                                 │
│   ┌─────────────────┐                                           │
│   │ Spec-as-Code    │ → Requisitos de negócio                   │
│   └────────┬────────┘                                           │
│            │                                                    │
│   ┌────────▼────────┐                                           │
│   │ AI Agent        │ → Comportamento de agentes                │
│   │ Design Patterns │                                           │
│   └────────┬────────┘                                           │
│            │                                                    │
│   ┌────────▼────────┐                                           │
│   │ SDAAL           │ → Abstrações de infraestrutura (ESTE)     │
│   └────────┬────────┘                                           │
│            │                                                    │
│   ┌────────▼────────┐                                           │
│   │ Task Manager    │ → Implementação de referência             │
│   │ Abstraction     │                                           │
│   └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📚 Recursos Adicionais

### Internos (Sistema Onion)
- [Comando /meta/create-abstraction](../../../.claude/commands/meta/create-abstraction.md) - Gerador automático de SDAAL
- [Template de Abstração](../../../.claude/commands/common/templates/abstraction-template.md) - Template base

### Externos
- [Adapter Pattern - Refactoring Guru](https://refactoring.guru/design-patterns/adapter)
- [Factory Method - Refactoring Guru](https://refactoring.guru/design-patterns/factory-method)
- [Null Object Pattern](https://refactoring.guru/design-patterns/null-object)
- [Strategy Pattern](https://refactoring.guru/design-patterns/strategy)
- [Prompt Engineering Guide - Anthropic](https://docs.anthropic.com/claude/docs/prompt-engineering)

---

## 📖 Glossário

| Termo | Definição |
|-------|-----------|
| **SDAAL** | Specification-Driven AI Abstraction Layer |
| **Adapter** | Componente que traduz entre interface genérica e API específica |
| **Factory** | Componente que decide qual adapter instanciar |
| **Detector** | Componente que identifica contexto/provedor |
| **Null Object** | Adapter de fallback que não faz nada (gracefully) |
| **Normalização** | Processo de converter resposta específica em formato padrão |

---

**Última Atualização**: 2026-06-13 — adicionada seção instância canônica (Task Manager) com modelo transporte API-first + MCP opcional.
**Responsável**: Sistema Onion


