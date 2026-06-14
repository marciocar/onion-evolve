# 📋 Templates do Sistema Onion

> Templates estruturados com YAML front matter para Claude Code - Documentação, execução e decisões arquiteturais.

## 📑 Índice

- [Visão Geral](#visão-geral)
- [Templates Disponíveis](#templates-disponíveis)
- [Como Usar](#como-usar)
- [YAML Front Matter](#yaml-front-matter)
- [Casos de Uso](#casos-de-uso)
- [Melhores Práticas](#melhores-práticas)

---

## 🎯 Visão Geral

Este diretório contém templates estruturados para documentação e execução no Sistema Onion. Todos os templates utilizam **YAML front matter v2.0** para metadados parseáveis e integração com Claude Code.

### ✨ Características Principais

- 🤖 **Parseável** - Metadata estruturada em YAML
- 📊 **Rastreável** - Status, progresso e métricas automatizadas
- 🔍 **Searchable** - Busca e filtros avançados
- ✅ **Validável** - Schema validation disponível
- 🚀 **AI-ready** - Integração com AI assistants

---

## 📚 Templates Disponíveis

> **Planejamento faseado e execução de fases** não usam mais templates daqui — o template de `plan.md` é definido inline em [`/engineer/plan`](../../commands/engineer/plan.md) e a estrutura de worklog/`STATE.md` vive na [SSOT do Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento) + [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md).

### 📝 Documentação

#### 1. **guide-template.md**
```yaml
type: guide
category: documentation
complexity: Baixa (27 linhas YAML)
```

**Uso:** Guias de implementação, arquitetura, setup ou troubleshooting

**Principais Seções:**
- Context (sistema, objetivo, casos de uso)
- Guide Metadata (tipo, público-alvo, dificuldade)

**Quando usar:**
- ✅ Criar documentação de referência
- ✅ Guias passo a passo
- ✅ Onboarding de desenvolvedores
- ✅ Troubleshooting guides

**Tipos de guia:**
- Implementação
- Arquitetura
- Build/Setup
- Troubleshooting
- Integração

---

#### 2. **analysis-template.md**
```yaml
type: analysis
category: documentation
complexity: Média (52 linhas YAML)
```

**Uso:** Análises críticas, de implementação ou status de sistemas

**Principais Seções:**
- Analysis Metadata (tipo, analista, escopo)
- Severity Config (níveis crítico/alto/médio)
- Status (overall, completion, actions, risks)
- Tracking (fases, métricas)

**Quando usar:**
- ✅ Análise de status de projeto
- ✅ Identificar gaps e problemas
- ✅ Priorizar ações corretivas
- ✅ Reportar progresso

**Capacidades AI:**
- Auto-status calculation
- Action tracking
- Metrics monitoring
- Risk prioritization
- Solution suggestions

**Exemplo de uso:**
```yaml
---
status:
  overall: "CRÍTICO"
  completion_percentage: 67
  critical_actions: 5
  risks_identified: 12
  
tracking:
  metrics:
    - name: "Test Coverage"
      current: "45%"
      expected: "80%"
      status: "CRITICAL"
---
```

---

#### 3. **reference-template.md**
```yaml
type: reference
category: documentation
complexity: Baixa
```

**Uso:** Documentação de referência (API, CLI, Configuration, Schema)

**Quando usar:**
- ✅ Documentar APIs
- ✅ Referência de CLI
- ✅ Schemas e configurações
- ✅ Quick reference guides

---

#### 4. **solution-template.md**
```yaml
type: solution
category: troubleshooting
complexity: Baixa
```

**Uso:** Documentar soluções para problemas comuns

**Quando usar:**
- ✅ Problemas recorrentes
- ✅ Erros de build/runtime
- ✅ Knowledge base
- ✅ AI-searchable solutions

---

### 🏛️ Arquitetura e Decisões

#### 5. **adr-template.md**
```yaml
type: adr
category: architecture-decision
complexity: Média (65 linhas YAML)
```

**Uso:** Architecture Decision Records (ADR) estruturados

**Principais Seções:**
- Decision Metadata (status, data, deciders)
- Quality Attributes (performance, security, etc)
- Alternatives (alternativas consideradas)
- Decision Matrix (matriz de decisão)
- Consequences (positivas, negativas, neutras)
- Related Decisions (grafo de dependências)

**Quando usar:**
- ✅ Decisões arquiteturais importantes
- ✅ Mudanças de tecnologia
- ✅ Trade-offs significativos
- ✅ Decisões que impactam longo prazo

**Capacidades AI:**
- Suggest alternatives
- Validate consequences
- Track implementation
- Monitor metrics
- Build dependency graph

**Exemplo de grafo de dependências:**
```yaml
---
related_decisions:
  supersedes: ["ADR-001", "ADR-003"]
  superseded_by: []
  relates_to: ["ADR-010", "ADR-012"]
  impacts: ["ADR-015"]
---
```

**Status flow:**
```
Proposed → Accepted → [Superseded]
    ↓
 Rejected
```

---

## 🚀 Como Usar

### 1. Escolher Template Apropriado

```bash
# Para análise de sistema
cp analysis-template.md analise-arquitetura-atual.md

# Para decisão arquitetural
cp adr-template.md adr-001-escolha-framework.md

# Para guia
cp guide-template.md guia-setup-local.md
```

### 2. Personalizar YAML Front Matter

```yaml
---
template:
  type: execution-plan
  version: 2.0
  name: "Migração para React 19"
  
context:
  system: "Sistema de Autenticação"
  current_state: "React 18.2 - Migrando para 19"
  base: "React 18, TypeScript, Vite"
  
success_metrics:
  - metric: "Zero Breaking Changes"
    target: "100%"
    criteria: "All tests pass"
---
```

### 3. Preencher Conteúdo

Siga as seções do template substituindo placeholders `[VARIÁVEL]` por valores reais.

### 4. Usar com AI Assistant

O Claude Code automaticamente:
- ✅ Parse YAML metadata
- ✅ Sugere próximos passos
- ✅ Valida completude
- ✅ Atualiza status
- ✅ Calcula progresso

---

## 📊 YAML Front Matter

### Estrutura Base

Todos os templates seguem esta estrutura básica:

```yaml
---
# 1. TEMPLATE METADATA (obrigatório)
template:
  type: string              # Tipo do template
  version: number           # Sempre 2.0
  category: string          # Categoria
  name: string              # Nome descritivo

# 2. CONTEXT/METADATA ESPECÍFICA
# Varia por tipo de template

# 3. AI ASSISTANT CONFIG (opcional)
ai_assistant:
  [flags específicas por template]
---
```

### Tipos de Template

| Tipo | Category | Uso |
|------|----------|-----|
| `guide` | documentation | Guias e tutoriais |
| `analysis` | documentation | Análises de sistemas |
| `adr` | architecture-decision | Decisões arquiteturais |
| `reference` | documentation | Documentação de referência |
| `solution` | troubleshooting | Soluções de problemas |

### AI Assistant Flags

Flags comuns disponíveis:

```yaml
ai_assistant:
  # Tracking e atualização
  auto_update: boolean          # Auto-atualizar metadata
  track_progress: boolean       # Rastrear progresso
  track_validations: boolean    # Rastrear validações
  track_actions: boolean        # Rastrear ações
  
  # Execução e validação
  enforce_sequence: boolean     # Forçar sequência
  monitor_compliance: boolean   # Monitorar compliance
  validate_metrics: boolean     # Validar métricas
  
  # AI features
  suggest_alternatives: boolean # Sugerir alternativas
  suggest_sections: boolean     # Sugerir seções
  suggest_solutions: boolean    # Sugerir soluções
  prioritize_risks: boolean     # Priorizar riscos
  
  # Grafo e relacionamentos
  build_dependency_graph: boolean # Construir grafo
```

---

## 💡 Casos de Uso

> Planejamento/execução de implementação faseada é coberto por [`/engineer/plan`](../../commands/engineer/plan.md) → [`/engineer/work`](../../commands/engineer/work.md) (worklog + `STATE.md`), não por templates daqui.

### Caso 1: Análise e Correção

```yaml
# 1. Fazer análise
analysis-template.md → analise-sistema-atual.md

# 2. Documentar soluções encontradas
solution-template.md → solucao-problema-x.md
solution-template.md → solucao-problema-y.md
```

### Caso 2: Decisão Arquitetural

```yaml
# 1. Documentar decisão
adr-template.md → adr-001-escolha-database.md

# 2. Criar guia de implementação
guide-template.md → guia-setup-postgres.md
```

### Caso 3: Dashboard de Análises

```typescript
// Buscar análises críticas
const criticalAnalyses = loadTemplates()
  .filter(t => t.template.type === 'analysis')
  .filter(t => t.status.overall === 'CRÍTICO')
  .sort((a, b) => b.status.critical_actions - a.status.critical_actions);

// Gerar relatório
console.log(`Total análises críticas: ${criticalAnalyses.length}`);
criticalAnalyses.forEach(a => {
  console.log(`- ${a.analysis_metadata.base_document}`);
  console.log(`  Actions: ${a.status.critical_actions}`);
  console.log(`  Risks: ${a.status.risks_identified}`);
});
```

### Caso 4: Grafo de ADRs

```typescript
// Construir grafo de decisões
const adrs = loadTemplates()
  .filter(t => t.template.type === 'adr');

const graph = adrs.map(adr => ({
  id: adr.template.adr_number,
  status: adr.decision_metadata.status,
  supersedes: adr.related_decisions.supersedes,
  supersededBy: adr.related_decisions.superseded_by
}));

// Encontrar ADRs obsoletos
const obsolete = graph.filter(adr => 
  adr.supersededBy.length > 0
);
```

---

## ✅ Melhores Práticas

### 📝 Nomenclatura

```bash
# Bom
adr-template.md → adr-001-escolha-state-management.md
analysis-template.md → analise-performance-2025-01.md

# Evitar
adr-template.md → decisao.md
analysis-template.md → analise.md
```

### 🎯 Customização do YAML

```yaml
# ✅ Bom - Específico e mensurável
success_metrics:
  - metric: "API Response Time"
    target: "< 200ms"
    criteria: "P95 under load"

# ❌ Evitar - Vago
success_metrics:
  - metric: "Performance"
    target: "Good"
    criteria: "Fast enough"
```

### 📊 Status e Tracking

```yaml
# ✅ Bom - Atualizar regularmente
status:
  overall: "BOM"
  completion_percentage: 67
  critical_actions: 2  # Reduzir a cada ação concluída

# ❌ Evitar - Deixar desatualizado
status:
  overall: "BOM"
  completion_percentage: 0  # Nunca atualizado
```

### 🔗 Relacionamentos

```yaml
# ✅ Bom - Documentar relacionamentos
related_decisions:
  supersedes: ["ADR-001"]
  relates_to: ["ADR-010", "ADR-015"]
  
# ❌ Evitar - Deixar vazio quando há relações
related_decisions:
  supersedes: []
  relates_to: []
```

---

## 🛠️ Ferramentas e Integração

### Validação YAML

```bash
# Validar syntax YAML
yamllint *.md

# Validar contra schema (se disponível)
ajv validate -s template-schema.json -d plano-*.md
```

### Busca Avançada

```bash
# Buscar templates por tipo
rg "type: analysis" --glob "*.md"

# Buscar análises críticas
rg "overall: \"CRÍTICO\"" --glob "*analysis*.md"

# Buscar ADRs aceitos
rg "status: \"Accepted\"" --glob "adr-*.md"
```

### Scripts Úteis

```bash
# Listar todos os templates por tipo
find . -name "*.md" -exec grep -l "template:" {} \; | \
  xargs grep "type:" | sort

# Contar templates por categoria
rg "category: " --no-filename | sort | uniq -c

# Encontrar templates desatualizados (sem version 2.0)
rg "version: 1\." --glob "*.md"
```

---

## 📚 Recursos Adicionais

### Documentação
- [YAML Specification](https://yaml.org/spec/)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code/overview)
- [ADR Guidelines](https://adr.github.io/)

### Schema (futuro)
```bash
.claude/docs/templates/schema/
├── template-base.schema.json
├── execution-plan.schema.json
├── adr.schema.json
└── analysis.schema.json
```

---

## 🎯 Quick Reference

| Preciso... | Use este template |
|-----------|------------------|
| 📋 Planejar implementação faseada | [`/engineer/plan`](../../commands/engineer/plan.md) (worklog + `STATE.md`) |
| 📝 Criar guia/tutorial | `guide-template.md` |
| 🔍 Analisar sistema | `analysis-template.md` |
| 🏛️ Documentar decisão arquitetural | `adr-template.md` |
| 📖 Documentar API/CLI | `reference-template.md` |
| 🔧 Documentar solução de problema | `solution-template.md` |

---

**📦 Total de Templates:** 5  
**🎨 Versão YAML:** 2.0  
**🤖 AI-Ready:** Todos  
**📊 Última Atualização:** 2026-06-14

---

<div align="center">

**Sistema Onion** 🧅  
*Templates estruturados para documentação e execução eficiente*

</div>

