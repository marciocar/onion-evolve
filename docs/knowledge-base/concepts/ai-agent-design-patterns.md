# AI Agent Design Patterns

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2025-11-24 |
| **Última Atualização** | 2026-06-13 (refresh orquestração de subagentes) |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Design de Agentes |

### Fontes

**Substrato nativo (Claude Code, 2026):**

- [Introducing Dynamic Workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) — ferramenta Workflow (`agent`/`parallel`/`pipeline`/`schema`/`isolation`/`budget`), research preview (28/mai/2026)
- [The State of Agentic Coding 2026 — Context Studios](https://contextstudios.ai/) — relatório sobre doutrina de orquestração
- Padrões canônicos de orquestração da Anthropic (2026)
- Práticas do Sistema Onion

**Influências históricas (frameworks externos):**

- [LangChain Agent Documentation](https://python.langchain.com/docs/modules/agents/)
- [CrewAI Framework](https://www.crewai.com/)
- [AutoGen Multi-Agent Framework](https://microsoft.github.io/autogen/)

---

## 🎯 Visão Geral

Este documento define patterns de design para agentes de IA, focando em arquitetura, especialização, delegação e orquestração para sistemas multi-agente eficientes.

> **Atualização 2026-06-13**: a orquestração multi-agente deixou de ser conceitual e passou a assentar sobre primitivas **nativas do Claude Code** — a ferramenta **Workflow** (`agent`/`parallel`/`pipeline`/`schema`/`isolation`/`budget`). A seção de orquestração foi reescrita para refletir esse substrato. Para o aprofundamento operacional de **orquestração** (até 16 subagentes concorrentes, 1.000 agregados por run, custo e tiers), consulte a KB irmã [`agent-orchestration.md`](agent-orchestration.md).

### Definição de Agente

```
Agente = Identidade + Especialização + Ferramentas + Protocolo de Ação
```

**Componentes Essenciais:**
- **Identidade**: Nome, descrição, propósito único
- **Especialização**: Área de expertise bem definida
- **Ferramentas**: Capacidades disponíveis (read, write, search, etc.)
- **Protocolo**: Como o agente opera e se comunica

---

## 🏗️ Arquitetura de Agentes

### Pattern 1: Single Agent (Agente Único)

```
┌─────────────────────────────────────┐
│           SINGLE AGENT              │
│  ┌─────────────────────────────┐    │
│  │  Identidade + Ferramentas   │    │
│  │  + Todo o conhecimento      │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
              ▼
         [OUTPUT]
```

**Quando usar:**
- Tarefas simples e bem definidas
- Domínio único e específico
- Contexto limitado

**Exemplo:** Agente de revisão de código para uma linguagem.

### Pattern 2: Orchestrator-Worker (Orquestrador-Trabalhador)

```
                    ┌─────────────────┐
                    │   ORCHESTRATOR  │
                    │   (Coordena)    │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │ Worker A │      │ Worker B │      │ Worker C │
    │(Pesquisa)│      │ (Código) │      │ (Teste)  │
    └──────────┘      └──────────┘      └──────────┘
```

**Quando usar:**
- Tarefas complexas com múltiplas especialidades
- Necessidade de coordenação
- Resultados precisam ser consolidados

**Exemplo:** Orquestrador de documentação delegando para especialistas.

> **No Claude Code (2026)** este pattern materializa-se na ferramenta **Workflow**: o orquestrador chama `parallel([thunks])` (fan-out com barreira) ou `pipeline(items, stage1, stage2)` (esteira sem barreira entre itens), e cada worker é um `agent(prompt, opts)`. Veja a seção [Orquestração nativa](#-orquestração-nativa-ferramenta-workflow).

### Pattern 3: Pipeline (Sequencial)

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Agent A  │───▶│ Agent B  │───▶│ Agent C  │───▶│  Output  │
│(Análise) │    │ (Design) │    │ (Impl.)  │    │ (Final)  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

**Quando usar:**
- Processo com etapas bem definidas
- Output de um agente é input do próximo
- Ordem de execução importante

**Exemplo:** Análise → Design → Implementação → Review.

### Pattern 4: Peer Review (Revisão por Pares)

```
┌──────────────────────────────────────┐
│           TASK                       │
└──────────────────┬───────────────────┘
                   │
    ┌──────────────┴──────────────┐
    ▼                             ▼
┌──────────┐               ┌──────────┐
│ Agent A  │◀─────────────▶│ Agent B  │
│(Executor)│   Feedback    │(Reviewer)│
└──────────┘               └──────────┘
    │                             │
    └──────────────┬──────────────┘
                   ▼
          ┌──────────────┐
          │   OUTPUT     │
          │  (Refinado)  │
          └──────────────┘
```

**Quando usar:**
- Qualidade crítica
- Necessidade de segunda opinião
- Redução de erros e alucinações

**Exemplo:** Code-reviewer revisando output de developer.

---

## 🚀 Orquestração nativa (ferramenta Workflow)

No Claude Code, a coordenação multi-agente não é mais "promptware": ela assenta na ferramenta **Workflow** (research preview, 28/mai/2026). A lógica de coordenação roda em **JavaScript** e custa **0 tokens de modelo** — só os subagentes consomem tokens. Isso muda o eixo de design: o orquestrador descreve o **grafo de execução** em código, não em prosa.

### Primitivas

| Primitiva | Papel | Semântica |
|-----------|-------|-----------|
| `agent(prompt, opts)` | Dispara **1 subagente** especializado | Unidade de trabalho |
| `parallel([thunks])` | **Fan-out com barreira** | Aguarda todos terminarem antes de prosseguir |
| `pipeline(items, stage1, stage2, ...)` | Esteira por itens | **Sem barreira** entre itens — cada item flui pelos estágios |
| `schema` | Structured output validado | Garante shape do retorno de cada agente |
| `isolation: 'worktree'` | Isolamento por git worktree | Cada agente em sua própria árvore de trabalho |
| `budget` | Teto de tokens | Limite de custo por agente/run |

**Limites operacionais (jun/2026):** até **16 subagentes concorrentes** e **1.000 agregados por run**.

### Snippet: fan-out + síntese

```javascript
// Lead Opus despacha 3 workers em paralelo (barreira), depois sintetiza.
const findings = await parallel([
  () => agent("Audite segurança do módulo de auth", { schema: FindingSchema }),
  () => agent("Audite performance das queries", { schema: FindingSchema }),
  () => agent("Audite cobertura de testes", { schema: FindingSchema }),
]);

// Barreira liberada: todos os 3 retornaram. Agora consolida.
const report = await agent(
  `Sintetize um relatório único a partir destes achados: ${JSON.stringify(findings)}`,
  { schema: ReportSchema }
);
```

> **Onde mora a orquestração:** na arquitetura do Onion (architecture.md §4.2), `agents/*` **NÃO pode** invocar `commands/*` — um agente sugere, não orquestra. Quem orquestra os workers é **skill + comando** (`skills/* → commands/*, agents/*`). Portanto, **nunca** crie um agente `worker-orchestrator`; a coordenação dos workers vive no **nível principal** (skill/comando), onde é mais barata e limpa.

---

## 🧩 Padrões canônicos de orquestração (Anthropic 2026)

Seis padrões de referência mapeados às primitivas nativas da ferramenta Workflow:

| Padrão | Definição (1 linha) | Primitiva |
|--------|---------------------|-----------|
| **classify-and-act** | Classifica a entrada e roteia para o handler correto. | `agent` (classificador) → `agent` (handler escolhido) |
| **fan-out-and-synthesize** | Dispara N workers em paralelo e consolida os resultados. | `parallel([...])` + `agent` de síntese |
| **adversarial verification** | Um agente produz, outro contesta para reduzir erro/alucinação. | `agent` (gerador) + `agent` (crítico) |
| **generate-and-filter** | Gera muitos candidatos e filtra os que passam no critério. | `parallel([...])` gera + `agent`/JS filtra |
| **tournament** | Compara candidatos em rodadas até eleger o melhor. | `parallel()` por rodada (barreira entre rodadas) + redução JS |
| **loop-until-done** | Itera um agente até satisfazer uma condição de parada. | `agent` em loop JS com guarda de `budget` |

Doutrina associada (era da orquestração): **control before autonomy** (controle antes de autonomia), atenção ao **delegation gap** (lacuna de delegação entre intenção e execução) e uso de **prompt caching** para conter custo de runs longos.

---

## 🏔️ Hierarchical model tiers e nesting

### Hierarchical model tiers

Padrão de custo-eficiência: usar **modelos diferentes por papel** no grafo de orquestração.

- **Lead (orquestrador)** → tier **opus** (o modelo Claude mais capaz): raciocínio sobre o grafo, decomposição, síntese final.
- **Workers** → tiers **sonnet** / **haiku**: trabalho paralelo de alto volume, onde o tier mais barato basta.

A ferramenta Workflow permite fixar o modelo por chamada de `agent(...)`, então o lead opus pode despachar dezenas de workers sonnet/haiku sob `budget`, mantendo qualidade de coordenação sem pagar opus em cada folha.

> Tiers disponíveis no Claude Code: **fable**, **opus**, **sonnet**, **haiku** (à época jun/2026: Fable 5 / Opus 4.8 / Sonnet 4.6 / Haiku 4.5). Não existe "gpt-4" nem qualquer modelo OpenAI como opção de modelo de agente no Claude Code.

### Nesting de subagentes (5 níveis)

Desde **10/jun/2026 (v2.1.172)**, subagentes podem aninhar **até 5 níveis** de profundidade — antes, o fan-out era de nível único.

Mesmo com nesting disponível, a recomendação permanece: **orquestrar no nível principal** (skill/comando), não dentro de um subagente. Coordenar a orquestração a partir do nível principal é mais barato (coordenação JS = 0 tokens) e mais limpo (respeita a regra `agents/* ↛ commands/*`). Reserve o nesting profundo para sub-decomposições legítimas, não para esconder a orquestração dentro de um agente.

---

## 📐 Patterns de Especialização

### Pattern: Single Responsibility Agent

**Princípio:** Cada agente deve ter uma única responsabilidade bem definida.

**❌ Anti-pattern:**
```yaml
name: super-agent
description: Faz tudo - código, testes, docs, deploy, reviews...
```

**✅ Pattern correto:**
```yaml
name: code-reviewer
description: Revisa código para qualidade, segurança e padrões.
expertise: ["code-review", "security", "best-practices"]
```

### Pattern: Expert Agent

**Princípio:** Agente com conhecimento profundo em domínio específico.

```yaml
name: react-developer
description: Especialista em desenvolvimento React e ecossistema.
expertise:
  - React hooks e patterns
  - Estado com Zustand/Redux
  - Testes com Testing Library
  - Performance optimization
tools:
  - Read
  - write
  - Grep
```

### Pattern: Meta Agent

**Princípio:** Agente que cria ou gerencia outros agentes.

```yaml
name: agent-creator-specialist
description: Meta-agente especializado em criar agentes.
expertise:
  - Design de agentes
  - Prompt engineering
  - Estruturação de conhecimento
tools:
  - Read
  - write
  - Grep
related_agents:
  - command-creator-specialist
```

---

## 🔄 Patterns de Delegação

### Pattern: Explicit Delegation

**Princípio:** Delegação explícita com instruções claras.

```markdown
## Processo
1. Analisar requisitos
2. **DELEGAR para @code-reviewer**:
   - Fornecer: código gerado
   - Solicitar: review de qualidade
   - Esperar: feedback e sugestões
3. Aplicar feedback
4. Retornar resultado
```

### Pattern: Conditional Delegation

**Princípio:** Delegar baseado em condições.

```markdown
## Delegação Condicional

SE tarefa envolve código TypeScript:
  DELEGAR para @typescript-specialist

SE tarefa envolve testes:
  DELEGAR para @test-engineer

SE tarefa envolve segurança:
  DELEGAR para @security-specialist

SENÃO:
  Executar internamente
```

### Pattern: Cascade Delegation

**Princípio:** Delegação em cascata para refinamento progressivo.

```
Request → @product-agent (estratégia)
                 │
                 ▼
         @task-specialist (decomposição)
                 │
                 ▼
         @code-reviewer (validação)
                 │
                 ▼
         @test-engineer (testes)
```

---

## 🎯 Patterns de Contexto

### Pattern: Context Injection

**Princípio:** Injetar contexto relevante no prompt do agente.

```markdown
## Contexto Automático

Ao invocar este agente, incluir:
1. Sessão atual: @.claude/sessions/<feature>/context.md
2. Padrões do projeto: @.claude/rules/
3. Última atividade: últimos 5 arquivos modificados
```

### Pattern: Progressive Context

**Princípio:** Expandir contexto progressivamente conforme necessidade.

```
Nível 1: Arquivo atual
    ↓ (se insuficiente)
Nível 2: Arquivos relacionados (@imports)
    ↓ (se insuficiente)
Nível 3: Módulo/pasta inteira
    ↓ (se insuficiente)
Nível 4: Projeto completo (@codebase)
```

### Pattern: Context Boundary

**Princípio:** Definir limites claros do que entra no contexto.

```yaml
context:
  include:
    - ".claude/sessions/current/*"
    - "src/components/<component>/*"
  exclude:
    - "node_modules/"
    - "*.test.ts"
    - "*.spec.ts"
  max_files: 10
  max_tokens: 8000
```

---

## 🛠️ Patterns de Ferramentas

### Pattern: Tool Selection by Task

**Princípio:** Agentes devem ter apenas ferramentas necessárias.

| Tipo de Agente | Ferramentas Recomendadas |
|----------------|--------------------------|
| **Pesquisa** | `Grep`, `WebSearch`, `Grep`, `Read` |
| **Desenvolvimento** | `Read`, `Write`, `Edit`, `Bash` |
| **Review** | `Read`, `Grep`, `Grep` |
| **Documentação** | `Read`, `Write`, `Grep` |
| **Teste** | `Read`, `Write`, `Bash` |

### Pattern: Agnostic Tools

**Princípio:** Ferramentas genéricas permitem agentes portáveis.

**✅ Agente Agnóstico:**
```yaml
tools:
  - Read
  - write
  - Grep
  - grep
  - WebSearch
# Sem MCPs específicos - portável para qualquer projeto
```

**⚠️ Agente Especializado:**
```yaml
tools:
  - Read
  - write
  - mcp__clickup__*      # Acoplado ao ClickUp
# Útil, mas menos portável
```

### Pattern: Tool Fallback

**Princípio:** Comportamento alternativo quando ferramenta indisponível.

```markdown
## Integração ClickUp

SE mcp_ClickUp disponível:
  → Usar para criar/atualizar tasks
SENÃO:
  → Gerar output em formato Markdown compatível
  → Usuário pode copiar manualmente
```

---

## 📝 Patterns de Prompt Engineering

### Pattern: Structured Identity

**Princípio:** Identidade clara no início do prompt.

```markdown
# Identidade

Você é o **@code-reviewer**, especialista em:
- Revisão de código TypeScript/JavaScript
- Identificação de problemas de segurança
- Aplicação de padrões e boas práticas

## Sua Missão
Revisar código para qualidade, mantendo padrões do projeto.

## Suas Regras
- Seja específico nas sugestões
- Cite linhas de código
- Priorize issues críticas
```

### Pattern: Action Protocol

**Princípio:** Definir protocolo claro de ação.

```markdown
## Protocolo de Operação

### Fase 1: Análise (sem output)
- Ler código completo
- Identificar padrões usados
- Mapear dependências

### Fase 2: Avaliação (notas internas)
- Listar issues encontradas
- Classificar por severidade
- Identificar melhorias

### Fase 3: Output (para usuário)
- Apresentar sumário
- Detalhar issues críticas
- Sugerir melhorias
```

### Pattern: Output Format

**Princípio:** Definir formato de saída esperado.

```markdown
## Formato de Saída

### Estrutura Obrigatória
```
## 📊 Sumário
- Issues críticas: X
- Melhorias sugeridas: Y
- Aprovado: Sim/Não

## 🚨 Issues Críticas
1. [SECURITY] Descrição - linha X
2. [BUG] Descrição - linha Y

## 💡 Melhorias
1. Descrição - linha Z

## ✅ Pontos Positivos
- Item 1
- Item 2
```
```

---

## 🔗 Aplicação no Sistema Onion

### Hierarquia de Agentes

```
                    ┌─────────────────┐
                    │    @onion       │
                    │  (Orquestrador) │
                    └────────┬────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     │                       │                       │
     ▼                       ▼                       ▼
┌──────────┐          ┌──────────┐          ┌──────────┐
│ product/ │          │ develop- │          │  meta/   │
│ agents   │          │  ment/   │          │ agents   │
└──────────┘          └──────────┘          └──────────┘
```

### Patterns Implementados

| Pattern | Implementação Onion |
|---------|---------------------|
| Orchestrator-Worker | `@onion` coordena especialistas |
| Expert Agent | `@clickup-specialist`, `@react-developer` |
| Meta Agent | `@agent-creator-specialist` |
| Peer Review | `@code-reviewer` + desenvolvedor |
| Context Injection | Sessions em `.claude/sessions/` |

### Template de Agente Onion

```yaml
---
name: agent-name
description: |
  Descrição clara em 1-2 linhas.
model: sonnet
tools: [Read, write, Grep, grep]

color: purple
priority: alta
category: development

expertise: ["area-1", "area-2"]
related_agents: ["agente-1", "agente-2"]
related_commands: ["/categoria/comando"]

version: "1.0.0"
updated: "2025-11-24"
---

# Nome do Agente

## 🎯 Identidade e Propósito
[Quem é e o que faz]

## 📋 Protocolo de Operação
### Fase 1: [Nome]
### Fase 2: [Nome]
### Fase 3: [Nome]

## 🔌 Integrações Opcionais
| MCP | Uso |
|-----|-----|
| ClickUp | Se disponível, gerenciar tasks |

## 💡 Guidelines
[Regras e melhores práticas]
```

---

## ⚠️ Anti-Patterns

### 1. God Agent

**❌ Problema:** Um agente faz tudo
```yaml
name: do-everything-agent
expertise: [tudo]
```

**✅ Solução:** Especialização + delegação

### 2. Context Overload

**❌ Problema:** Carregar todo o projeto no contexto
```
@codebase (100.000 linhas)
```

**✅ Solução:** Context boundary + progressive loading

### 3. Vague Identity

**❌ Problema:** Identidade genérica
```
Você é um assistente útil.
```

**✅ Solução:** Identidade específica e expertise clara

### 4. Missing Protocol

**❌ Problema:** Sem processo definido
```
Faça o que achar melhor.
```

**✅ Solução:** Protocolo com fases claras

---

## 📚 Recursos Adicionais

### Internos (Sistema Onion)
- [Agent Orchestration](agent-orchestration.md) - **KB irmã**: aprofundamento operacional de orquestração (Workflow nativo, tiers, custo, isolamento)
- [Specification-Driven AI Abstraction Layer](specification-driven-ai-abstraction-layer.md) - Padrão para abstrações documentais
- [Task Manager Abstraction](task-manager-abstraction.md) - Implementação de referência do SDAAL
- [Spec-as-Code Strategy](spec-as-code-strategy.md) - Metodologia de especificações

### Substrato nativo (Claude Code, 2026)
- [Introducing Dynamic Workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code)
- [The State of Agentic Coding 2026 — Context Studios](https://contextstudios.ai/)

### Influências históricas (frameworks externos)
- [LangChain Agents](https://python.langchain.com/docs/modules/agents/)
- [CrewAI Documentation](https://docs.crewai.com/)
- [AutoGen](https://microsoft.github.io/autogen/)

---

**Próxima Atualização Planejada**: Dezembro 2026
**Responsável**: Sistema Onion

