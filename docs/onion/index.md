# 📚 Índice - Sistema Onion

> **Última atualização**: 2026-06-14 | **Gerado por**: `/docs:build-index onion` | **Revisado**: auditoria manual

Bem-vindo ao índice da documentação do **Sistema Onion**. Este documento organiza os 16 documentos de documentação operacional do sistema em `docs/onion/`.

---

## 🎯 Visão Geral

O **Sistema Onion** é um **framework template em `.claude/`** — instalável em qualquer projeto (novo, legado ou regulado), plataforma única Claude Code, sem produto npm e sem CLI standalone. Inclui:
- 🤖 **104 comandos invocáveis** Claude Code em 10 categorias
- 🎯 **51 agentes de IA especializados** em 9 categorias
- 🧩 **11 skills** em `.claude/skills/` (`onion`, `onion-patterns`, `onion-validation`, `language-standards`, `onion-orchestration`, `onion-onboarding`, `onion-wizard`, `onion-retro`, `onion-engineering-context`, `onion-product-context`, `onion-compliance-context`)
- 🧅 **Skill + Comando `/onion`** — ponto de entrada inteligente
- 🔗 **Task Manager Abstraction** plugável (Jira, ClickUp, Asana, Linear)
- 🏗️ **Spec as Code Multi-Context** — business, technical e meta-specs

---

## 📊 Estatísticas

> **Contagens canônicas (SSOT):** [inventory.md](inventory.md) — gerado do filesystem por `/meta:inventory` e validado no CI. Os números abaixo derivam dele.

- **16 documentos** em `docs/onion/`
- **104 comandos invocáveis** Claude Code em `.claude/commands/`
- **51 agentes** IA em `.claude/agents/`
- **11 skills** em `.claude/skills/`

---

## 📖 Documentação Principal

### 🌟 Guias Essenciais

**Comece aqui se você é novo no Sistema Onion:**

1. **[Guia de Comandos](commands-guide.md)** - Documentação dos comandos disponíveis
   - 104 comandos invocáveis em 10 categorias
   - Exemplos de uso e workflows
   - Integrações com Task Managers

2. **[Referência de Agentes](agents-reference.md)** - Lista e descrição dos agentes especializados
   - 51 agentes em 9 categorias
   - Quando usar cada agente
   - Capacidades e especializações

3. **[Fluxos de Engenharia](engineering-flows.md)** - Workflows detalhados para desenvolvimento
   - Feature Development completo
   - Correção de bugs
   - Refatoração e hotfixes
   - Integração com Task Manager por fluxo

4. **[Sistema de Testes e Validação](testing-validation-system.md)** - Framework completo de testes e validação
   - 4 camadas integradas (Knowledge Base, Agentes, Comandos de Teste, Comandos de Validação)
   - White-box, Grey-box, Black-box
   - QA Story Points

### ⚙️ Integrações e Configuração

**Setup e configuração do sistema:**

1. **[Configuração Inicial](getting-started.md)** - Setup completo do sistema
   - Primeiros passos
   - Configuração de integrações
   - Workflows básicos

2. **Task Manager Abstraction** — configure provider (Jira/ClickUp/Asana/Linear) via `.env` e `/meta:setup-integration`. Adapters técnicos em [`.claude/utils/task-manager/adapters/`](../../.claude/utils/task-manager/adapters/).

3. **Aplicação em projetos-alvo** — ver guias em [`docs/applying/`](../applying/) (greenfield, legado, regulado).

### 🔧 Referências Técnicas

**Documentação técnica e arquitetural:**

1. **[Exemplos Práticos](practical-examples.md)** - Casos de uso reais com exemplos
   - Workflows completos
   - Cenários de uso
   - Melhores práticas

2. **Referência de Ferramentas** - rode `/meta:all-tools` para listar (sob demanda) as ferramentas disponíveis no contexto atual
   - Ferramentas integradas
   - Configuração
   - Uso e exemplos

3. **[Arquitetura de Comandos](claude-code-commands-architecture.md)** - Estrutura interna dos comandos
   - Padrões de design
   - Estrutura de arquivos
   - Best practices

4. **[CI/CD](ci.md)** - Validação automatizada via GitHub Actions
   - Workflows de integração contínua
   - Testes automatizados
   - Deploy pipeline

5. **[Inventário Canônico](inventory.md)** - SSOT de comandos/agentes/skills/KBs
   - Gerado do filesystem (`/meta:inventory`)
   - Validado no CI (lint Regra 8 + 9)
   - Contagens nunca hardcoded de memória

### 📚 Documentação Avançada

**Para usuários avançados e desenvolvedores do sistema:**

1. **[Testes de Validação E2E](end-to-end-validation-tests.md)** - Testes end-to-end do sistema
   - Suíte de testes completa
   - Validação de funcionalidades
   - Cobertura de testes

2. **[Guia de Engenharia Reversa](sistema-engenharia-reversa-guia-uso.md)** - Engenharia reversa de projetos
   - Metodologia completa
   - Templates adaptativos
   - Casos de uso

---

## 🗺️ Navegação Rápida

### Por Tipo de Documento

| Tipo | Arquivos | Descrição |
|------|----------|-----------|
| **Guias** | 4 | Guias essenciais de uso |
| **Configuração** | 1 | Setup inicial |
| **Referências** | 4 | Documentação técnica |
| **Avançado** | 2 | Para usuários avançados |

### Por Perfil de Usuário

#### 👨‍💻 Desenvolvedores
- Comece com: [Getting Started](getting-started.md)
- Aprenda: [Commands Guide](commands-guide.md)
- Explore: [Engineering Flows](engineering-flows.md)
- Teste: [Testing Validation System](testing-validation-system.md)

#### 📋 Product Owners
- Comece com: [Commands Guide](commands-guide.md) - Seção Produto
- Aprenda: [Practical Examples](practical-examples.md)
- Explore: [Agents Reference](agents-reference.md)

#### 🧪 QA/Test Engineers
- Comece com: [Testing Validation System](testing-validation-system.md)
- Aprenda: [End-to-End Validation Tests](end-to-end-validation-tests.md)
- Explore: [Agents Reference](agents-reference.md) - Seção Testing

#### 🏗️ Arquitetos
- Comece com: [Claude Code Commands Architecture](claude-code-commands-architecture.md)
- Explore: [Engineering Flows](engineering-flows.md)

#### 🔧 Administradores
- Comece com: [Getting Started](getting-started.md)
- Aplique em projetos: [`docs/applying/`](../applying/)
- Configure Task Manager: `/meta:setup-integration` (adapters em `.claude/utils/task-manager/adapters/`)

---

## 🔗 Links Rápidos

### Documentação Essencial
- [README Principal](../../README.md) - Visão geral do Sistema Onion
- [Índice Central](../INDEX.md) - Hub de navegação completo
- [Guia de Comandos](commands-guide.md) - Todos os comandos
- [Referência de Agentes](agents-reference.md) - Todos os agentes

### Knowledge Bases Relacionadas
- [Task Manager Abstraction](../knowledge-base/concepts/task-manager-abstraction.md)
- [Spec-Driven Development](../knowledge-base/concepts/spec-driven-development.md)
- [AI Agent Design Patterns](../knowledge-base/concepts/ai-agent-design-patterns.md)
- [Framework de Story Points](../knowledge-base/frameworks/framework-story-points.md)

### Configuração
- [Getting Started](getting-started.md)
- [Adapters de Task Manager](../../.claude/utils/task-manager/adapters/)

---

## 📅 Histórico de Atualizações

| Data | Mudança |
|------|---------|
| 2026-06-03 | Limpeza: removidos 14 docs obsoletos do v4.0/CLI abandonado; índice realinhado à identidade atual (78 comandos / 49 agentes / 4 skills) |
| 2026-05-15 | Auditoria manual: agente @onion corrigido (agentes fantasmas removidos, 18 novos adicionados) |
| 2025-12-20 | Índice reconstruído |
| 2025-12-02 | Adicionado Spec-Driven Development |

---

## 🔄 Manutenção

Este índice é gerado pelo comando `/docs:build-index onion`.

**Para atualizar:**
```bash
/docs:build-index onion        # Reconstruir este índice
/docs:build-index              # Reconstruir índice principal
```

---

**Sistema Onion** - Multi-Context Development Orchestrator 🧅
</content>
</invoke>
