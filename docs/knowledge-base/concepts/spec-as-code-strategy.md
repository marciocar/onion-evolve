# Spec as Code Strategy

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2025-11-24 |
| **Última Atualização** | 2025-11-24 |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion - Metodologia de Especificação |

### Fontes

- Práticas do Sistema Onion
- [Behavior Driven Development (BDD)](https://cucumber.io/docs/bdd/)
- [Executable Specifications](https://martinfowler.com/bliki/ExecutableSpec.html)
- [Documentation as Code](https://www.writethedocs.org/guide/docs-as-code/)
- Princípios de Engenharia de Prompts

---

## 🎯 Visão Geral

**Spec as Code** é uma metodologia onde especificações técnicas e de negócio são tratadas como código versionável, servindo como "fonte da verdade" para sistemas de IA gerarem implementações consistentes e alinhadas com requisitos.

### Definição

```
Spec as Code = Especificações Estruturadas + Versionamento + Execução por IA
```

**Princípio Central**: Especificações bem escritas permitem que a IA gere código correto na primeira tentativa.

---

## 📐 Princípios Fundamentais

### 1. Especificação como Fonte da Verdade

```
┌─────────────────────────────────────────────────────────┐
│                    META-SPECS                           │
│          (Constituição do Sistema)                      │
├─────────────────────────────────────────────────────────┤
│                    DOMAIN SPECS                         │
│          (Regras de Negócio)                            │
├─────────────────────────────────────────────────────────┤
│                    FEATURE SPECS                        │
│          (Especificações de Features)                   │
├─────────────────────────────────────────────────────────┤
│                    IMPLEMENTATION                       │
│          (Código Gerado)                                │
└─────────────────────────────────────────────────────────┘
```

### 2. Hierarquia de Especificações

| Nível | Nome | Propósito | Exemplo |
|-------|------|-----------|---------|
| **L0** | Meta-Specs | Constituição, princípios imutáveis | Arquitetura base, padrões de código |
| **L1** | Domain Specs | Regras de negócio, domínio | Entidades, casos de uso |
| **L2** | Feature Specs | Especificações de funcionalidades | User stories com critérios |
| **L3** | Task Specs | Tarefas específicas | Subtasks, implementações |

### 3. Versionamento e Rastreabilidade

- Toda spec é um arquivo Markdown versionado em Git
- Mudanças em specs geram histórico rastreável
- Código gerado referencia spec de origem
- Validações verificam conformidade

---

## 🏗️ Estrutura de uma Spec

### Template Universal

```markdown
# [Nome da Spec]

## 📋 Metadata
- **Tipo**: [feature|domain|task]
- **Status**: [draft|review|approved|implemented]
- **Versão**: [semver]
- **Autor**: [responsável]
- **Data**: [YYYY-MM-DD]

## 🎯 Objetivo
[Descrição clara do que esta spec define]

## 📐 Contexto
[Informações de background necessárias]

## 📋 Requisitos

### Funcionais
- [ ] Requisito 1
- [ ] Requisito 2

### Não-Funcionais
- [ ] Performance
- [ ] Segurança

## 🔗 Dependências
- Spec A → esta spec depende de
- Spec B → depende desta spec

## ✅ Critérios de Aceitação
- [ ] Critério 1
- [ ] Critério 2

## 💡 Exemplos
[Casos de uso concretos]

## 🔍 Validações
[Como verificar se a implementação está correta]
```

### Exemplo Prático: Feature Spec

```markdown
# Feature: Sistema de Autenticação OAuth

## 📋 Metadata
- **Tipo**: feature
- **Status**: approved
- **Versão**: 1.0.0
- **Autor**: @product-agent
- **Data**: 2025-11-24

## 🎯 Objetivo
Implementar autenticação via OAuth 2.0 com suporte a Google e GitHub.

## 📐 Contexto
O sistema atual usa autenticação básica. Usuários solicitaram
login social para simplificar o acesso.

## 📋 Requisitos

### Funcionais
- [ ] Login com Google
- [ ] Login com GitHub
- [ ] Link/Unlink de contas sociais
- [ ] Refresh token automático

### Não-Funcionais
- [ ] Tempo de resposta < 2s
- [ ] Tokens armazenados de forma segura
- [ ] Rate limiting de 100 req/min

## ✅ Critérios de Aceitação
- [ ] Usuário consegue fazer login com Google
- [ ] Usuário consegue fazer login com GitHub
- [ ] Sessão persiste por 7 dias
- [ ] Erro amigável se provider indisponível

## 💡 Exemplos

### Fluxo de Login Google
1. Usuário clica "Login com Google"
2. Redirecionado para consent screen
3. Após aprovação, retorna ao app
4. Sessão criada automaticamente
```

---

## 🔄 Workflow Spec as Code

### Ciclo de Vida

A spec é um **artefato de handoff** entre **duas fases faseadas retomáveis e independentes** (invariantes do framework — ver CLAUDE.md): a fase **produto** (`/product/*`, descoberta → spec congelada) e a fase **engenharia** (`/engineer/*`, planejamento → entrega). A spec aprovada é a **fronteira** entre elas — **não** um pipeline linear único.

```
══ Fase PRODUTO (/product/*) ═══════════════╗   ╔══ Fase ENGENHARIA (/engineer/*) ══
┌──────────┐   ┌──────────┐   ┌──────────┐  ║   ║  ┌───────────┐
│  DRAFT   │──▶│  REVIEW  │──▶│ APPROVED │  ║──▶║  │IMPLEMENTED│  (plan→work→pr, retomável)
└──────────┘   └──────────┘   └──────────┘  ║   ║  └───────────┘
   Autor          Review          Gate       ╚═══╝    Geração de código
   escreve       por pares      (congela)    handoff: spec congelada
```

### Etapas Detalhadas

> As duas fases têm **sessões/estado próprios** e são retomáveis de forma independente; a spec congelada (APPROVED) é o único acoplamento entre elas. Ver [gitflow-patterns.md](../frameworks/gitflow-patterns.md) §Contrato de Sessão.

#### Fase PRODUTO — 1. DRAFT (Rascunho)
```bash
/product/spec "Nova funcionalidade X"
```
- Autor cria spec inicial
- Estrutura básica preenchida
- Requisitos preliminares

#### Fase PRODUTO — 2. REVIEW (Revisão)
```bash
/product/refine spec-x.md
```
- Pares revisam especificação
- Identificam gaps e ambiguidades
- Refinam requisitos

#### Fase PRODUTO — 3. APPROVED (Aprovado) — fronteira de handoff
```bash
/product/check spec-x.md
```
- Gate-keeper valida conformidade
- Spec **congelada** — pronta para handoff à engenharia
- Critérios de aceitação claros

#### Fase ENGENHARIA — 4. IMPLEMENTED (Implementado)
```bash
/engineer/start spec-x   # inicia a fase própria de engenharia (plan → work → pr), retomável
```
- IA gera código baseado na spec congelada
- Testes validam critérios de aceitação
- Código referencia spec de origem

---

## 🤖 Integração com IA

### Como a IA Usa Specs

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   SPEC FILE     │────▶│   AI CONTEXT    │────▶│  CODE OUTPUT    │
│  (Markdown)     │     │  (Prompt)       │     │  (Gerado)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Prompt Engineering para Specs

**Spec → Prompt Efetivo:**

```markdown
## Contexto
Você está implementando a feature definida em:
@docs/specs/auth-oauth.md

## Instruções
1. Leia a spec completamente
2. Implemente TODOS os requisitos funcionais
3. Respeite os requisitos não-funcionais
4. Gere testes para os critérios de aceitação

## Restrições
- Siga os padrões de @docs/meta-specs/code-standards.md
- Use libs aprovadas em @docs/meta-specs/dependencies.md
```

### Validação Automática

```markdown
## Checklist de Conformidade

### Requisitos Implementados
- [x] Login com Google ← linha 45-67 de auth.service.ts
- [x] Login com GitHub ← linha 68-89 de auth.service.ts
- [ ] Refresh token ← PENDENTE

### Testes Criados
- [x] auth.service.spec.ts - 12 testes passando

### Cobertura de Critérios
- 3/4 critérios de aceitação cobertos
- Falta: "Erro amigável se provider indisponível"
```

---

## 📁 Organização de Specs

### Estrutura de Diretórios

```
docs/
├── meta-specs/           # Nível L0 - Constituição
│   ├── index.md          # Índice de meta-specs
│   ├── architecture.md   # Arquitetura base
│   ├── code-standards.md # Padrões de código
│   └── dependencies.md   # Dependências aprovadas
│
├── domain-specs/         # Nível L1 - Domínio
│   ├── entities/         # Entidades do domínio
│   ├── use-cases/        # Casos de uso
│   └── rules/            # Regras de negócio
│
├── feature-specs/        # Nível L2 - Features
│   ├── auth/             # Specs de autenticação
│   ├── payments/         # Specs de pagamentos
│   └── reports/          # Specs de relatórios
│
└── task-specs/           # Nível L3 - Tarefas
    └── sessions/         # Contexto por sessão
```

### Convenções de Nomenclatura

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Meta-spec | `kebab-case.md` | `code-standards.md` |
| Domain spec | `entity-name.md` | `user-entity.md` |
| Feature spec | `feature-name.md` | `oauth-login.md` |
| Task spec | `task-id.md` ou `context.md` | `context.md` |

---

## ✨ Benefícios

### Para Desenvolvimento com IA

| Benefício | Descrição |
|-----------|-----------|
| **Consistência** | IA sempre gera código alinhado com specs |
| **Rastreabilidade** | Toda linha de código tem origem em spec |
| **Validação** | Critérios de aceitação são verificáveis |
| **Iteração** | Refinar spec = refinar código |
| **Documentação** | Specs servem como documentação viva |

### Para Equipes

| Benefício | Descrição |
|-----------|-----------|
| **Alinhamento** | Todos entendem o que será construído |
| **Review eficiente** | Revisar spec antes de código |
| **Onboarding** | Novos membros leem specs |
| **Handoff** | Specs transferem conhecimento |

---

## 🔗 Aplicação no Sistema Onion

### Meta-Specs como Constituição

```
.claude/
├── docs/
│   └── meta-specs/         # Regras imutáveis do sistema
│       ├── index.md        # Índice
│       ├── architecture.md # Padrões arquiteturais
│       └── agents.md       # Padrões de agentes
```

### Sessions (worklogs) como Task Specs

O worklog `.claude/sessions/<feature>/` é a materialização do **Task Spec (L3)**. Estrutura canônica (incl. `STATE.md`) na [SSOT §Contrato de Sessão](../frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) — abaixo, só a leitura sob a ótica de spec:

```
.claude/sessions/<feature>/
├── STATE.md      # Índice de resume (ponteiro NEXT)
├── context.md    # Spec da feature atual + Phase-Subtask Mapping
├── plan.md       # Decomposição em fases/subtasks
├── architecture.md # Design decisions
└── notes.md      # Decisões e observações
```

### Comandos Spec-Aware

| Comando | Interação com Specs |
|---------|---------------------|
| `/product/task` | Cria task spec |
| `/product/spec` | Cria feature spec |
| `/engineer/start` | Lê spec e prepara contexto |
| `/engineer/work` | Implementa baseado em spec |
| `@metaspec-gate-keeper` | Valida conformidade |

### Fluxo Completo

```
1. /product/task "Nova feature"
   → Cria context.md com spec inicial

2. /product/refine
   → Refina spec com detalhes

3. @metaspec-gate-keeper
   → Valida conformidade com meta-specs

4. /engineer/start
   → Prepara ambiente baseado na spec

5. /engineer/work
   → Implementa seguindo spec

6. /engineer/pr
   → Valida critérios de aceitação
```

---

## ⚠️ Anti-Patterns

### 1. Spec Incompleta

**❌ Problema:**
```markdown
# Feature X
Fazer o login funcionar
```

**✅ Solução:**
```markdown
# Feature: Login OAuth
## Requisitos
- Login com Google
- Login com GitHub
## Critérios de Aceitação
- Usuário autenticado em < 3 cliques
```

### 2. Spec Desatualizada

**❌ Problema:** Spec diz uma coisa, código faz outra

**✅ Solução:** 
- Atualizar spec ANTES de mudar código
- Validação automática de conformidade

### 3. Spec Muito Técnica

**❌ Problema:** Spec descreve implementação, não requisitos

**✅ Solução:** Focar no "O QUÊ", não no "COMO"

---

## 📚 Recursos Adicionais

### Internos (Sistema Onion)
- [Specification-Driven AI Abstraction Layer](specification-driven-ai-abstraction-layer.md) - Aplicação de Spec-as-Code para abstrações técnicas
- [Task Manager Abstraction](task-manager-abstraction.md) - Exemplo prático do padrão
- [AI Agent Design Patterns](ai-agent-design-patterns.md) - Padrões complementares de agentes

### Externos
- [Behavior Driven Development](https://cucumber.io/docs/bdd/)
- [Specification by Example](https://specificationbyexample.com)
- [Living Documentation](https://leanpub.com/livingdocumentation)
- [Docs as Code](https://www.writethedocs.org/guide/docs-as-code/)

---

**Próxima Atualização Planejada**: Janeiro 2026
**Responsável**: Sistema Onion

