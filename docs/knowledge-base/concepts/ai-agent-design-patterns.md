---
verified_at: 2026-11-18
source: "https://code.claude.com/docs/en/workflows"
---

# AI Agent Design Patterns

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2025-11-24 |
| **Última Atualização** | 2026-11-18 (reverificação: limites do Workflow, nesting, nomes de ferramenta, fontes externas) |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Design de Agentes |

### Fontes

**Substrato nativo (Claude Code, 2026):**

- [Introducing Dynamic Workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) — ferramenta Workflow (`agent`/`parallel`/`pipeline`/`schema`/`isolation`/`budget`; o `isolation: "worktree"` dos agentes está declarado no CHANGELOG do Claude Code, o `budget` não aparece na documentação pública), lançada em research preview (28/mai/2026); a URL hoje redireciona para `claude.com/resources/articles/…` (HTTP 200, 2026-11-18)
- [Dynamic workflows — doc oficial](https://code.claude.com/docs/en/workflows) — estado atual: disponível em todos os planos pagos, limites do run (verificado 2026-11-18, HTTP 200)
- [The State of Agentic Coding 2026 — Context Studios](https://contextstudios.ai/) — relatório sobre doutrina de orquestração
- Padrões canônicos de orquestração da Anthropic (2026)
- Práticas do Sistema Onion

**Influências históricas (frameworks externos):**

- [LangChain Agent Documentation](https://docs.langchain.com/oss/python/langchain/overview) — a URL antiga `python.langchain.com/docs/modules/agents/` hoje redireciona para cá (2026-11-18)
- [CrewAI Framework](https://www.crewai.com/)
- [AutoGen Multi-Agent Framework](https://microsoft.github.io/autogen/) — ⚠️ a página do projeto hoje avisa que o repositório está **arquivado**, sem manutenção nem correções de segurança, e recomenda migrar para o [Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/migration-guide/from-autogen/) (verificado 2026-11-18). Influência histórica, não recomendação

---

## 🎯 Visão Geral

Este documento define patterns de design para agentes de IA, focando em arquitetura, especialização, delegação e orquestração para sistemas multi-agente eficientes.

> **Atualização 2026-06-13**: a orquestração multi-agente deixou de ser conceitual e passou a assentar sobre primitivas **nativas do Claude Code** — a ferramenta **Workflow** (`agent`/`parallel`/`pipeline`/`schema`/`isolation`/`budget`). A seção de orquestração foi reescrita para refletir esse substrato. Para o aprofundamento operacional de **orquestração** (16 agentes concorrentes por default e ajustáveis, 1.000 por run, custo e tiers), consulte a KB irmã [`agent-orchestration.md`](agent-orchestration.md).

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

No Claude Code, a coordenação multi-agente não é mais "promptware": ela assenta na ferramenta **Workflow** (lançada em research preview em 28/mai/2026; hoje disponível em todos os planos pagos, sem rótulo de preview na doc, reverificado 2026-11-18). A lógica de coordenação roda em **JavaScript** e custa **0 tokens de modelo** — só os subagentes consomem tokens. Isso muda o eixo de design: o orquestrador descreve o **grafo de execução** em código, não em prosa.

### Primitivas

| Primitiva | Papel | Semântica |
|-----------|-------|-----------|
| `agent(prompt, opts)` | Dispara **1 subagente** especializado | Unidade de trabalho |
| `parallel([thunks])` | **Fan-out com barreira** | Aguarda todos terminarem antes de prosseguir |
| `pipeline(items, stage1, stage2, ...)` | Esteira por itens | **Sem barreira** entre itens — cada item flui pelos estágios |
| `schema` | Structured output validado | Garante shape do retorno de cada agente |
| `isolation: 'worktree'` | Isolamento por git worktree | Cada agente em sua própria árvore de trabalho |
| `budget` | Teto de tokens | Limite de custo por agente/run |

**Limites operacionais (reverificados 2026-11-18 na [doc de workflows](https://code.claude.com/docs/en/workflows)):** **16 agentes concorrentes por default** (ajustável de 1 a 256 por `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS`), **1.000 agentes por run** e até **4.096 itens** por chamada de `parallel()`/`pipeline()`.

> **Alcance da tabela acima (2026-11-18):** a doc pública documenta `agent()`, `parallel()`, `pipeline()`, `phase()`, `log()`, `args` e as opções `schema` e `label` de `agent()`. `isolation: "worktree"` e `budget` **não** aparecem na doc pública; o que se conferiu é que o binário 2.1.326 do Claude Code contém as strings `isolation: "worktree"` e `budget.remaining()`, este último como global do script (saldo do run), não como opção por agente. A referência completa do script é a skill embutida `/workflow-authoring`.

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

> Tiers no Claude Code, do topo para a base: **fable** (Mythos-class, **acima** de opus — não é par dele), **opus**, **sonnet**, **haiku**. Versões driftam; cite por **tier**, nunca por versão — fonte única do lineup: [`agent-orchestration.md` §Disponibilidade de modelos](agent-orchestration.md). Não existe "gpt-4" nem qualquer modelo OpenAI como opção de modelo de agente no Claude Code.

### Nesting de subagentes (profundidade 3 por default)

Reverificado em 2026-11-18 na [doc de subagentes](https://code.claude.com/docs/en/sub-agents) e no CHANGELOG: desde **2.1.219** um subagente pode disparar subagentes **até 3 camadas abaixo da conversa principal** por default, ajustável por `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (`=1` desliga). A nota antiga ("5 níveis desde v2.1.172") foi superada: houve 5 níveis desde 2.1.172, nesting desligado por default em 2.1.217 e o default de 3 em 2.1.219. Há também um teto de **20 subagentes concorrentes** (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`), sem teto total por sessão.

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
  - Write
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
  - Write
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
| **Pesquisa** | `Glob`, `Grep`, `WebSearch`, `WebFetch`, `Read` |
| **Desenvolvimento** | `Read`, `Write`, `Edit`, `Bash` |
| **Review** | `Read`, `Grep`, `Glob` |
| **Documentação** | `Read`, `Write`, `Grep` |
| **Teste** | `Read`, `Write`, `Bash` |

> Os nomes vêm da [referência de ferramentas](https://code.claude.com/docs/en/tools-reference) (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `Bash`…), escritos com a inicial maiúscula. A redação anterior trazia `write` e `grep` em minúsculas e `Grep` repetido nos exemplos; corrigido em 2026-11-18.

### Pattern: Agnostic Tools

**Princípio:** Ferramentas genéricas permitem agentes portáveis.

**✅ Agente Agnóstico:**
```yaml
tools:
  - Read
  - Write
  - Grep
  - Glob
  - WebSearch
# Sem MCPs específicos - portável para qualquer projeto
```

**⚠️ Agente Especializado:**
```yaml
tools:
  - Read
  - Write
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
tools: [Read, Write, Grep, Glob]

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
- [Dynamic workflows — doc oficial](https://code.claude.com/docs/en/workflows)
- [The State of Agentic Coding 2026 — Context Studios](https://contextstudios.ai/)

### Influências históricas (frameworks externos)
- [LangChain Agents](https://docs.langchain.com/oss/python/langchain/overview)
- [CrewAI Documentation](https://docs.crewai.com/)
- [AutoGen](https://microsoft.github.io/autogen/) (arquivado; sucessor: Microsoft Agent Framework)

---

**Próxima Atualização Planejada**: Dezembro 2026
**Responsável**: Sistema Onion

