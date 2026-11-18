---
verified_at: 2026-11-18
source: "https://platform.claude.com/docs/en/build-with-claude/prompt-caching"
---

# Context Window Optimization

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2025-11-24 |
| **Última Atualização** | 2026-11-18 (reverificação: lineup 5.5, contexto de 1M, TTL do cache, limites do Workflow, `.claudeignore` e `@include`) |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Otimização de Tokens |

### Fontes

- [Claude Platform Docs](https://platform.claude.com/docs/en/home) (o `docs.anthropic.com` redireciona para cá; HTTP 200, 2026-11-18)
- [Prompt Caching — Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) (reverificado 2026-11-18, HTTP 200)
- [Models overview](https://platform.claude.com/docs/en/models/overview) — janelas de contexto do lineup vigente (reverificado 2026-11-18, HTTP 200)
- [Claude Code — Dynamic Workflows](https://code.claude.com/docs/en/workflows) (lançado em research preview em 28/mai/2026; reverificado 2026-11-18, HTTP 200)
- [Claude Code Overview](https://code.claude.com/docs/en/overview) (reverificado 2026-11-18)
- [Padrões canônicos de orquestração de agentes — Anthropic](https://www.anthropic.com/research/multi-agent-research-system) (2026; a URL `/engineering/` antiga redireciona para cá)
- Práticas do Sistema Onion
- Experiência prática com LLMs

---

## 🎯 Visão Geral

**Context Window Optimization** é o conjunto de técnicas para maximizar a eficiência do uso do contexto disponível em modelos de linguagem, reduzindo custos e melhorando a qualidade das respostas.

### Por Que Otimizar?

| Fator | Impacto |
|-------|---------|
| **Custo** | Tokens = dinheiro (API billing) |
| **Velocidade** | Menos tokens = resposta mais rápida |
| **Qualidade** | Contexto focado = respostas melhores |
| **Limites** | Context windows têm tamanho máximo |

### Context Windows por Modelo (reverificado 2026-11-18)

Lineup atual do Claude no Claude Code — use estes modelos; não há modelos OpenAI/Gemini como opções de agente no Onion.

| Modelo | Papel típico em orquestração | Context Window | ~Linhas de Código |
|--------|-----------------------|----------------|-------------------|
| tier `fable` (hoje **Fable 5.2**) | Orquestração de raciocínio profundo | 1M tokens | ~400K linhas |
| tier `opus` (hoje **Opus 5.5**) | Orquestrador (planeja, sintetiza, decide) | 1M tokens | ~400K linhas |
| tier `sonnet` (hoje **Sonnet 5.5**) | Worker de uso geral (implementação, análise) | 1M tokens | ~400K linhas |
| tier `haiku` (hoje **Haiku 5.5**) | Worker barato/rápido (classificação, extração, filtro) | 1M tokens | ~400K linhas |

> **Reverificado em 2026-11-18** no [overview de modelos](https://platform.claude.com/docs/en/models/overview): os quatro modelos vigentes têm **1M de contexto e 128K de saída**. A versão anterior desta tabela dava 200K ao `haiku` e 200K–1M ao `sonnet`, o que não vale mais. O Haiku 5.5 cobra mais caro acima de 100K tokens de prompt ($0,50/$2,50 em vez de $0,10/$0,50 por MTok, CHANGELOG do Claude Code 2.1.293), o que pesa no tiering de workers com contexto grande.

> ⚠️ **Versões acima são SNAPSHOT (2026-11-18), não lineup vigente** — o lineup drifta (de jun a nov/2026 a linha foi de 4.x a 5 e a 5.5, e **fable** é tier *acima* de opus, não par). Os **limites de contexto por tier** seguem úteis; para *qual modelo usar*, cite por **tier** e consulte a fonte única do lineup: [`agent-orchestration.md` §Disponibilidade de modelos](agent-orchestration.md).

**Nota**: 1 token ≈ 4 caracteres em inglês, ~3 em código.

**Tiering de modelos** (doutrina "orchestration era"): o orquestrador roda no tier `opus` (hoje **Opus 5.5**; ou o tier Mythos-class/`fable` quando o raciocínio domina **e a conta tem acesso**); os workers paralelos rodam em `sonnet` ou `haiku`. Reservar o modelo caro só para o nível que decide reduz custo agregado sem perder qualidade no resultado final. **Referência por-tier (evergreen)**: o lineup e a disponibilidade vivem na fonte única [`agent-orchestration.md` §Disponibilidade de modelos](agent-orchestration.md) — atualizar SÓ lá mantém isto corrente (não hardcodar versão aqui). Veja [Custo em Orquestração (Multi-Agente)](#-custo-em-orquestração-multi-agente).

---

## 📊 Métricas de Otimização

### Token Budget

```
┌─────────────────────────────────────────────────────────┐
│                   CONTEXT WINDOW                        │
├──────────────┬──────────────┬──────────────────────────┤
│   SYSTEM     │    USER      │       RESPONSE           │
│   PROMPT     │   CONTEXT    │       SPACE              │
│   (15-20%)   │   (50-60%)   │       (20-30%)           │
└──────────────┴──────────────┴──────────────────────────┘
```

### Distribuição Recomendada (128K tokens)

| Componente | % | Tokens | Uso |
|------------|---|--------|-----|
| System Prompt | 15% | ~19K | Instruções, identidade |
| User Context | 55% | ~70K | Arquivos, código, docs |
| Response Space | 30% | ~38K | Output do modelo |

### KPIs de Eficiência

| Métrica | Meta | Como Medir |
|---------|------|------------|
| Tokens/Execução | < 10K | Observar consumo |
| Relevance Score | > 80% | % contexto usado na resposta |
| Response Quality | > 4/5 | Avaliação humana |
| First-Try Success | > 70% | Tasks completadas sem retry |

---

## 🛠️ Técnicas de Otimização

### 1. Chunking Strategies

**Princípio:** Dividir conteúdo em partes gerenciáveis.

#### Chunking por Semântica

```
┌────────────────────────────────────────┐
│           ARQUIVO GRANDE               │
│  ┌─────────────────────────────────┐   │
│  │ Chunk 1: Imports + Types        │   │
│  ├─────────────────────────────────┤   │
│  │ Chunk 2: Class/Component        │   │
│  ├─────────────────────────────────┤   │
│  │ Chunk 3: Helper Functions       │   │
│  ├─────────────────────────────────┤   │
│  │ Chunk 4: Exports                │   │
│  └─────────────────────────────────┘   │
└────────────────────────────────────────┘
```

#### Tamanhos Recomendados

| Tipo de Conteúdo | Tamanho Chunk | Motivo |
|------------------|---------------|--------|
| Código | 100-300 linhas | Função/classe completa |
| Documentação | 500-1000 palavras | Seção coesa |
| Logs | 50-100 linhas | Contexto de erro |

### 2. Relevance Filtering

**Princípio:** Incluir apenas o que é necessário.

#### Filtros por Tipo

```yaml
relevance_filters:
  always_include:
    - Arquivo sendo editado
    - Imports diretos
    - Types/Interfaces usados
    
  conditionally_include:
    - Arquivos relacionados (se referenciados)
    - Testes (se revisando código)
    - Docs (se documentando)
    
  always_exclude:
    - node_modules/
    - build/, dist/
    - Arquivos binários
    - Logs antigos
```

#### Filtro por Distância

```
Distância 0: Arquivo atual
Distância 1: Imports diretos
Distância 2: Imports dos imports
Distância 3+: Raramente necessário
```

### 3. Prompt Compression

**Princípio:** Dizer mais com menos tokens.

#### Antes vs Depois

**❌ Prolixo (45 tokens):**
```
Por favor, eu gostaria muito que você pudesse me ajudar 
a criar um componente React que seja responsivo e que 
funcione bem em dispositivos móveis e também em desktop.
```

**✅ Comprimido (15 tokens):**
```
Crie componente React responsivo (mobile + desktop).
```

#### Técnicas de Compressão

| Técnica | Exemplo |
|---------|---------|
| Abreviações | "Create component" → "Create comp" |
| Remoção de fluff | "Por favor" → (remover) |
| Bullet points | Parágrafos → listas |
| Código como spec | Descrição → TypeScript interface |

### 4. Progressive Loading

**Princípio:** Carregar contexto sob demanda.

```
ETAPA 1: Prompt inicial (mínimo)
    │
    ├── Se precisa de mais contexto:
    │       ETAPA 2: Carregar arquivos específicos
    │           │
    │           ├── Se ainda insuficiente:
    │           │       ETAPA 3: Expandir para pasta
    │           │           │
    │           │           └── ETAPA 4: Busca semântica
    │           │
    │           └── Suficiente → Executar
    │
    └── Suficiente → Executar
```

### 5. Caching de Contexto

**Princípio:** Reutilizar contexto entre chamadas.

```
┌─────────────────────────────────────────────┐
│           SESSÃO DE TRABALHO                │
├─────────────────────────────────────────────┤
│  CACHE (persistente entre chamadas):        │
│  - Arquitetura do projeto                   │
│  - Padrões de código                        │
│  - Entidades do domínio                     │
├─────────────────────────────────────────────┤
│  VARIÁVEL (muda por chamada):               │
│  - Arquivo atual                            │
│  - Tarefa específica                        │
│  - Erros recentes                           │
└─────────────────────────────────────────────┘
```

Para o mecanismo concreto de cache de prompt entre chamadas e entre subagentes, veja [Prompt Caching](#-prompt-caching).

---

## 💾 Prompt Caching

**Prompt caching** é a maior alavanca de custo quando o mesmo prefixo de contexto se repete entre chamadas. Em vez de reprocessar (e re-cobrar integralmente) o bloco repetido a cada turno, o provider materializa um cache do prefixo; chamadas seguintes que compartilham esse prefixo leem do cache a uma fração do custo.

### O que vale a pena cachear

| Bloco | Estabilidade | Cacheável? |
|-------|--------------|------------|
| System prompt / identidade do agente | Alta (não muda no run) | ✅ Sim — prefixo ideal |
| Regras do projeto (CLAUDE.md, padrões) | Alta | ✅ Sim |
| Documentação de referência / KB injetada | Alta | ✅ Sim |
| Spec/plano compartilhado entre workers | Alta dentro do run | ✅ Sim |
| Arquivo sendo editado | Baixa (muda por turno) | ❌ Não — fica fora do prefixo cacheado |
| Erros/saída recentes | Baixa | ❌ Não |

**Números do mecanismo (reverificados 2026-11-18 na [doc de prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)):** o cache vive **5 minutos** por default e se renova sem custo a cada uso; há TTL de **1 hora** a custo maior. A escrita custa **1,25×** o input base (TTL de 5 min) ou **2×** (TTL de 1 h); a leitura custa **0,1×** no padrão, **0,05×** no Opus 5.5 e no Sonnet 5.5 e **0,025×** no Fable/Mythos 5.1 e 5.2. No Claude Code, o agente de workflow fica fora do balde de TTL da conversa principal e o cache dele dura 5 min por default, inclusive em assinatura; `subagentPromptCacheTtl: "1h"` estende ([doc de workflows](https://code.claude.com/docs/en/workflows), §Prompt caching in a fan-out).

**Regra de ouro:** ordene o contexto do **mais estável para o mais volátil**. O cache cobre apenas o prefixo comum; qualquer mudança no início invalida o que vem depois. System prompt e blocos compartilhados primeiro, conteúdo volátil (arquivo atual, tarefa, erros) por último.

### Caching em orquestração (fan-out)

Em um fan-out, N subagentes recebem o **mesmo prefixo** (system prompt do worker + spec/plano + KB de referência) e diferem apenas na fatia volátil (o item que cada um processa). Esse prefixo idêntico é exatamente o caso de uso do prompt caching: paga-se o processamento do prefixo essencialmente uma vez e os N workers o reutilizam. A doc do Claude Code precisa a condição: dois agentes do mesmo run compartilham o prefixo quando rodam com o **mesmo modelo, esforço, tipo de agente, ferramentas, schema de saída e diretório**, e o segundo só lê o cache se começar depois que a resposta do primeiro já começou (reverificado 2026-11-18).

```
┌────────────────────────────────────────────────────────┐
│  PREFIXO COMPARTILHADO (cacheado, processado ~1x)        │
│  - System prompt do worker                               │
│  - Spec / plano da feature                               │
│  - Padrões do projeto + KB                               │
├────────────────────────────────────────────────────────┤
│  worker 1 │ worker 2 │ worker 3 │ ... │ worker N         │
│  + item 1 │ + item 2 │ + item 3 │ ... │ + item N  (vol.) │
└────────────────────────────────────────────────────────┘
```

> **A coordenação custa 0 tokens de modelo.** Na ferramenta nativa **Workflow** (Dynamic Workflows, lançada em research preview em 28/mai/2026), a lógica de orquestração — `agent(...)`, `parallel([...])`, `pipeline(...)`, agregação e validação de `schema` — roda em **JavaScript**, não consome tokens do modelo. Apenas as chamadas de subagente (`agent`) gastam tokens. Combinado com prompt caching no prefixo compartilhado, o overhead de coordenar uma orquestração grande tende a zero: você paga pelos workers e pelo prefixo (uma vez), não por orquestrar.

Detalhamento de custo e alocação de budget entre orquestrador e workers em [Custo em Orquestração (Multi-Agente)](#-custo-em-orquestração-multi-agente). Para os padrões de orquestração em si (fan-out, pipeline, isolamento por worktree), veja [agent-orchestration.md](agent-orchestration.md).

---

## 📁 Otimização por Tipo de Conteúdo

### Código-fonte

| Estratégia | Quando Usar |
|------------|-------------|
| Arquivo completo | < 300 linhas |
| Função específica | Edição pontual |
| Assinaturas apenas | Contexto de API |
| Skeleton | Visão geral de estrutura |

**Skeleton Example:**
```typescript
// Skeleton de UserService (reduzido de 500 para 50 linhas)
class UserService {
  // Dependências
  constructor(private db: Database, private cache: Cache) {}
  
  // Métodos públicos
  async getUser(id: string): Promise<User> { /* ... */ }
  async createUser(data: CreateUserDto): Promise<User> { /* ... */ }
  async updateUser(id: string, data: UpdateUserDto): Promise<User> { /* ... */ }
  async deleteUser(id: string): Promise<void> { /* ... */ }
  
  // Métodos privados (omitidos)
  // - validateUser
  // - hashPassword
  // - sendWelcomeEmail
}
```

### Documentação

| Estratégia | Quando Usar |
|------------|-------------|
| TOC + Seção relevante | Docs grandes |
| Sumário executivo | Visão geral |
| Exemplos apenas | Implementação rápida |

### Logs e Erros

| Estratégia | Quando Usar |
|------------|-------------|
| Stack trace completo | Debug |
| Últimas N linhas | Monitoramento |
| Padrão de erro | Categorização |

---

## 🔧 Configuração no Sistema Onion

### .claudeignore (convenção da casa) e o mecanismo documentado

> ⚠️ **Reverificado em 2026-11-18:** `.claudeignore` **não aparece** na documentação do Claude Code (zero ocorrências no índice `code.claude.com/docs/llms.txt`) nem no CHANGELOG oficial. O core mantém um `.claudeignore` na raiz, mas trate-o como **convenção da casa, sem efeito garantido no harness**. O mecanismo documentado para manter arquivos fora do alcance do modelo são as regras `deny` de `Read(...)` em `permissions` do `settings.json`, com sintaxe de gitignore ([settings](https://code.claude.com/docs/en/settings), [permissions](https://code.claude.com/docs/en/permissions)). Exemplo da doc: `"deny": ["Read(./.env)"]`.

```gitignore
# Arquivos grandes/binários
*.pdf
*.zip
*.png
*.jpg

# Build artifacts
node_modules/
dist/
build/
.next/

# Dependências
vendor/
packages/*/node_modules/

# Logs
*.log
logs/

# Temporários
.cache/
.tmp/
```

### Estrutura de Comandos Otimizada

```markdown
# Template de Comando Otimizado

## 🎯 Objetivo (1-2 linhas)
[Descrição concisa]

## 📥 Entrada (lista)
- Parâmetro 1
- Parâmetro 2

## 🔄 Processo (numerado)
1. Etapa 1
2. Etapa 2

## 📤 Saída (formato)
[Especificação do output]

<!-- Evitar: histórico, explicações longas, exemplos redundantes -->
```

### Limite de Tamanho para Comandos

| Classificação | Linhas | Tokens (~) | Recomendação |
|---------------|--------|------------|--------------|
| Ideal | < 200 | < 2K | ✅ |
| Aceitável | 200-400 | 2-4K | ⚠️ |
| Limite | 400-500 | 4-5K | ⚠️ Revisar |
| Problemático | > 500 | > 5K | ❌ Refatorar |

### Modularização de Prompts

```
.claude/commands/
└── common/
    └── prompts/
        ├── validation-rules.md    # Regras reutilizáveis
        ├── output-formats.md      # Formatos de saída
        ├── clickup-patterns.md    # Padrões ClickUp
        └── technical.md           # Contexto técnico
```

**Uso em Comando:**

> ⚠️ **Reverificado em 2026-11-18:** `@include` **não é sintaxe do Claude Code**. O documentado é o import `@caminho/do/arquivo` dentro do CLAUDE.md ([memory](https://code.claude.com/docs/en/memory), §Import additional files) e a referência `@arquivo` num comando ou skill, que anexa o arquivo. O bloco abaixo é a convenção textual da casa (o modelo lê e segue), não uma diretiva que o harness expanda.

```markdown
## Validações
@include common/prompts/validation-rules.md

## Formato de Saída
@include common/prompts/output-formats.md
```

---

## 📈 Estratégias Avançadas

### 1. Semantic Compression

```typescript
// ANTES: 50 tokens
interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}

// DEPOIS: 15 tokens
// User: { id, email, name, createdAt, updatedAt }
```

### 2. Reference Instead of Include

```markdown
## Contexto

Em vez de incluir o arquivo completo, referencie:
- Padrões: ver @docs/standards.md
- Exemplos: ver @src/components/Button.tsx
- Testes: rodar `npm test -- User`
```

### 3. Hierarchical Context

```
Level 1: Sumário do projeto (sempre)
Level 2: Módulo relevante (sob demanda)
Level 3: Arquivo específico (quando necessário)
Level 4: Função específica (para edição pontual)
```

### 4. Context Budgeting

```yaml
budget:
  total: 10000  # tokens disponíveis
  
  allocation:
    system_prompt: 1500   # 15%
    project_context: 2000 # 20%
    current_task: 4000    # 40%
    response_space: 2500  # 25%
    
  overflow_strategy: "truncate_oldest"
```

---

## 🚀 Custo em Orquestração (Multi-Agente)

Quando o trabalho é distribuído entre vários subagentes, a otimização de contexto deixa de ser "um budget" e passa a ser **alocação de budget entre o orquestrador e N workers**. O objetivo é o mesmo — gastar menos tokens por resultado — mas as alavancas mudam.

> No Sistema Onion a orquestração mora em **skill + comando** (que podem invocar `commands/*` e `agents/*`), nunca dentro de um agente — `architecture.md` §4.2 proíbe `agents/* → commands/*`. Não existe e não se deve criar um agente "worker-orchestrator".

### 1. Token budgeting por worker

Defina o gasto de cada worker pelo trabalho que ele realmente faz, não pelo budget do orquestrador. ⚠️ Reverificado em 2026-11-18: a doc pública da ferramenta Workflow **não documenta** um parâmetro `budget` por chamada de `agent(...)` (documenta `schema` e `label`); o binário 2.1.326 traz `budget.remaining()` como global do script, que é saldo do run. Na prática, o teto por worker se faz pelo tier do modelo, pelo tamanho do prompt e pelo escopo da tarefa; a tabela abaixo é orientação de dimensionamento, não parâmetro.

| Worker | Trabalho típico | Budget sugerido |
|--------|-----------------|-----------------|
| Classificador / roteador | Lê pouco, decide rótulo | Baixo |
| Extrator / filtro | Lê um item, devolve campos | Baixo–médio |
| Implementador | Lê + edita arquivos | Médio–alto |
| Verificador adversarial | Relê e contesta um output | Médio |

### 2. Model tiering

Não use o modelo do orquestrador em todo worker. O orquestrador (que planeja, sintetiza e decide) roda no tier **`opus`** (hoje Opus 5.5) — ou no tier **Mythos-class/`fable`** quando o raciocínio domina e há acesso; os workers paralelos rodam em **`sonnet`** (uso geral) ou **`haiku`** (classificação, extração, filtro, tarefas mecânicas). Reservar o tier caro para o nível de decisão é o que torna a orquestração economicamente viável. (Versões correntes: ver `agent-orchestration.md` §Disponibilidade — fonte única.)

```
opus (orquestrador) ──── planeja, distribui, sintetiza
   │
   ├── sonnet      (worker — implementa / analisa)
   ├── sonnet      (worker — implementa / analisa)
   ├── haiku       (worker — classifica / extrai)
   └── haiku       (worker — classifica / extrai)
```

### 3. Alocação de budget: orquestrador + N workers

O custo agregado de um run não é o budget de um agente, e sim a soma do orquestrador com os workers. Um modelo grosseiro de alocação:

```yaml
orchestration_budget:
  total_run: 200000          # teto agregado do run (tokens de modelo)
  orchestrator:
    model: opus              # tier, nunca versão (fonte única: agent-orchestration.md)
    budget: 40000            # plano + síntese final + roteamento
  workers:
    count: 8
    model: sonnet            # ou haiku para tarefas mecânicas
    budget_each: 18000       # 8 × 18000 = 144000
  # coordenação (parallel/pipeline/schema) = 0 tokens de modelo (roda em JS)
  # prefixo compartilhado (system + spec + KB) cacheado → cobrado ~1x
```

Limites operacionais da ferramenta Workflow (reverificados 2026-11-18): **16 agentes concorrentes por default** (ajustável de 1 a 256 por `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS`), **1.000 agentes por run** e até **4.096 itens** por `parallel()`/`pipeline()`; nesting de subagentes até **3 camadas** por default desde 2.1.219 (a nota antiga de "5 níveis, v2.1.172" foi superada). Mesmo assim, prefira orquestrar os workers no **nível principal** (skill/comando): é mais barato e limpo do que aninhar fan-out dentro de um subagente.

### 4. Quando paralelizar compensa

Paralelizar tem custo fixo (o budget do orquestrador para fan-out e síntese). Compensa quando:

| Situação | Paralelizar? | Por quê |
|----------|--------------|---------|
| Muitos itens independentes (arquivos, fontes, casos) | ✅ Sim | `parallel([...])` / `pipeline(...)` ganham em wall-clock; prefixo cacheado dilui o custo |
| Tarefa única e sequencial (uma edição pontual) | ❌ Não | Overhead de orquestração > ganho |
| Itens com dependência forte entre si | ⚠️ Parcial | Use `pipeline` (sem barreira entre itens) ou um único agente |
| Verificação adversarial de um output crítico | ✅ Sim | Worker barato (Haiku) contesta o resultado — `generate-and-filter` / adversarial verification |
| Volume pequeno (2–3 itens triviais) | ❌ Não | O custo de coordenar não se paga |

**Heurística:** paralelize quando o trabalho é divisível em itens independentes **e** o prefixo compartilhado (cacheável) é grande em relação à fatia volátil de cada worker — aí o caching + a coordenação em JS (0 tokens) fazem o custo marginal de cada worker tender só ao seu trabalho real.

> Os padrões de orquestração citados (fan-out-and-synthesize, pipeline, classify-and-act, generate-and-filter, adversarial verification, tournament, loop-until-done) estão detalhados em [agent-orchestration.md](agent-orchestration.md).

---

## ⚠️ Anti-Patterns

### 1. Context Dump

**❌ Problema:** Carregar todo o projeto
```
@codebase  // 100K tokens
```

**✅ Solução:** Seleção específica
```
@src/services/UserService.ts
@src/types/user.ts
```

### 2. Redundant Context

**❌ Problema:** Repetir informações
```markdown
O projeto usa React.
Este é um projeto React.
Estamos trabalhando com React.
```

**✅ Solução:** Mencionar uma vez

### 3. Stale Context

**❌ Problema:** Contexto desatualizado
```
// Código de 3 conversas atrás
```

**✅ Solução:** Sempre usar @file atual

### 4. Over-Engineering Prompts

**❌ Problema:** Instruções excessivas
```markdown
## Regras Importantes (500 linhas)
[...]
## Mais Regras (300 linhas)
[...]
```

**✅ Solução:** Essencial apenas

---

## 📊 Checklist de Otimização

### Comando/Prompt

- [ ] < 500 linhas totais
- [ ] Objetivo em 1-2 linhas
- [ ] Processo em etapas numeradas
- [ ] Sem repetição de instruções
- [ ] Prompts comuns em `common/prompts/`

### Contexto de Sessão

- [ ] `.claudeignore` configurado
- [ ] Apenas arquivos relevantes carregados
- [ ] Referências em vez de cópias
- [ ] Progressive loading implementado

### Arquivos

- [ ] Arquivos grandes chunkeados
- [ ] Binários excluídos
- [ ] Build artifacts ignorados
- [ ] Logs rotacionados

---

## 📚 Recursos Adicionais

- [Claude Platform Docs](https://platform.claude.com/docs/en/home) (reverificado 2026-11-18)
- [Prompt Caching — Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) (reverificado 2026-11-18)
- [Claude Code — Dynamic Workflows](https://code.claude.com/docs/en/workflows) (reverificado 2026-11-18)
- [Claude Code Overview](https://code.claude.com/docs/en/overview) (reverificado 2026-11-18)

### Conceitos Relacionados

- [agent-orchestration.md](agent-orchestration.md) — padrões de orquestração (fan-out, pipeline, isolamento por worktree) e onde o custo multi-agente desta KB se aplica
- [ai-agent-design-patterns.md](ai-agent-design-patterns.md) — padrões de design de agentes de IA

---

**Próxima Atualização Planejada**: Dezembro 2026
**Responsável**: Sistema Onion

