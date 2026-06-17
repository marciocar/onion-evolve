# Meta Specs - Sistema Onion

---

## 📋 Visão Geral

**Meta Specs** são especificações de nível mais alto que servem como "constituição" do Sistema Onion. Elas definem princípios, padrões e regras imutáveis que todos os componentes devem seguir.

### Hierarquia de Especificações

```
┌─────────────────────────────────────────────────────────┐
│                    META-SPECS (L0)                      │
│          "Constituição" - Regras Imutáveis              │
├─────────────────────────────────────────────────────────┤
│                    DOMAIN SPECS (L1)                    │
│          Regras de Negócio e Domínio                    │
├─────────────────────────────────────────────────────────┤
│                    FEATURE SPECS (L2)                   │
│          Especificações de Features                     │
├─────────────────────────────────────────────────────────┤
│                    TASK SPECS (L3)                      │
│          Sessions e Contextos de Trabalho               │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Estrutura

```
docs/meta-specs/
├── index.md              # Este arquivo
├── architecture.md       # Padrões arquiteturais
├── code-standards.md     # Padrões de código
├── agents.md             # Padrões para agentes
├── commands.md           # Padrões para comandos
└── integrations.md       # Padrões para integrações
```

---

## 🎯 Propósito

### O que são Meta Specs?

Meta Specs definem:
- **Princípios arquiteturais** que o sistema deve seguir
- **Padrões de código** para consistência
- **Convenções de nomenclatura** para agentes e comandos
- **Regras de integração** com sistemas externos
- **Critérios de qualidade** para validação

### Quando usar Meta Specs?

| Situação | Uso |
|----------|-----|
| Criar novo agente | Consultar `agents.md` |
| Criar novo comando | Consultar `commands.md` |
| Tomar decisão arquitetural | Consultar `architecture.md` |
| Revisar código | Consultar `code-standards.md` |
| Integrar sistema externo | Consultar `integrations.md` |

### Quem mantém Meta Specs?

- **@metaspec-gate-keeper**: Valida conformidade (a constituição de validação)
- **`/meta/metaspec-validate`**: comando que **aplica** a constituição executando as leituras e produzindo o veredito com evidência (ponto de entrada confiável)
- **@branch-metaspec-checker**: aplica o mesmo padrão ao diff do branch no pré-PR
- **@onion**: Orquestra aplicação
- **Administradores do projeto**: Atualizam specs

### Dualidade de contexto — L0 (framework) vs L1+ (projeto-alvo)

O gate-keeper opera em **dois modos**, escolhendo a régua conforme o artefato:

- **Modo Framework (L0)** — no `onion-evolve`, valida artefatos `.claude/**`
  contra as **5 meta-specs L0** (agents/commands/architecture/code-standards/integrations).
- **Modo Projeto-alvo (L1+)** — quando o Onion está instalado num projeto, valida
  artefatos de **domínio/feature/ADR** contra as metaspecs **daquele projeto**.

Em ambos os modos as metaspecs são **descobertas dinamicamente** (`docs/meta-specs/`,
sem nomes cravados), para o mesmo gate-keeper funcionar em qualquer projeto-alvo.

---

## 📜 Meta Specs Disponíveis

> Todas as 5 meta-specs foram criadas em 2026-05-18 como parte da execução do Plano de Saneamento Onion 2026-05 (tarefas T2.1 a T2.5; plano executado e removido na curadoria de 2026-06-14 — ver [análise de identidade](../analysis/onion-review-2026-05.md) e git history).

### 🤖 [agents.md](./agents.md) — ATIVA (v1.0.0, 2026-05-18)
Padrões para agentes:
- Estrutura YAML obrigatória (`name`, `description`, `tools`)
- 9 categorias válidas
- Convenções de nomenclatura kebab-case
- Limites de tamanho (1.200 recomendado, 1.500 hard)
- Padrões de delegação e integração com MCPs

### 🔧 [commands.md](./commands.md) — ATIVA (v1.0.0, 2026-05-18)
Padrões para comandos:
- Estrutura obrigatória (frontmatter, corpo)
- Categorias válidas
- **Workflows faseados como invariantes** (`engineer/plan→pr-update` e `product/collect→feature`)
- Política de duplicação de nomes
- Limites de tamanho (500 recomendado, 800 hard)

### 🏗️ [architecture.md](./architecture.md) — ATIVA (v1.2.0, 2026-05-18)
Padrões arquiteturais:
- Estrutura obrigatória de `.claude/` e `docs/`
- Separação operacional vs documentação
- Princípio de framework instalável
- Dependências permitidas entre categorias (com diagrama)
- Plataforma única: Claude Code

### 📝 [code-standards.md](./code-standards.md) — ATIVA (v1.0.0, 2026-05-18)
Padrões de código e idioma:
- Separação pt-BR (docs/UX) vs inglês (código/commits/logs)
- Formatação Markdown
- Convenções de naming (filenames, slugs, branches, commits)
- Estilo de escrita
- Configuração e secrets

### 🔌 [integrations.md](./integrations.md) — ATIVA (v1.0.0, 2026-05-18)
Padrões para integrações:
- Task Manager Abstraction como referência canônica
- Estrutura obrigatória de adapter (factory + interface + types + detector + providers)
- Gestão de `.env` (obrigatórias vs opcionais, fallback gracioso)
- MCPs suportados
- Formatação por provider (ADF Jira v3, Markdown ClickUp, Unicode comments, HTML Asana, Markdown Linear)

---

## 🔄 Workflow de Validação

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    CHANGE       │────▶│  @metaspec-     │────▶│   APPROVED/     │
│    REQUEST      │     │  gate-keeper    │     │   REJECTED      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Processo

1. **Proposta de mudança**: Desenvolvedor propõe alteração
2. **Validação**: `@metaspec-gate-keeper` verifica conformidade
3. **Decisão**: Aprovado se conforme, rejeitado com justificativa

---

## 📚 Referências

- **Knowledge Bases**: `docs/knowledge-base/`
- **Documentação Onion**: `docs/onion/`
- **Agentes**: `.claude/agents/`
- **Comandos**: `.claude/commands/`
- **Regras**: `.claude/rules/`

---

## 📅 Histórico

| Data | Versão | Mudança |
|------|--------|---------|
| 2025-11-24 | 1.0.0 | Criação inicial |

---

**Responsável**: Sistema Onion v3.0
**Última Atualização**: 2025-11-24

