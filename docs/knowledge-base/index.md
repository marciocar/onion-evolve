# 📚 Índice - Knowledge Bases

> **Última atualização**: 2025-12-20 | **Gerado por**: `/docs/build-index knowbase`

Bem-vindo ao índice das **Knowledge Bases** do Sistema Onion. Este documento organiza todos os 24 arquivos de conhecimento estruturado para consumo por IA e referência técnica.

---

## 🎯 Visão Geral

As **Knowledge Bases** são documentos estruturados que servem como fonte de verdade para:
- 🤖 **Agentes de IA** - Contexto especializado para tomada de decisões
- 👨‍💻 **Desenvolvedores** - Referência técnica e metodológica
- 📋 **Product Owners** - Frameworks e estratégias de produto
- 🏗️ **Arquitetos** - Padrões e decisões arquiteturais

---

## 📊 Estatísticas

- **31 arquivos** de knowledge bases
- **14 conceitos** fundamentais
- **11 frameworks** e metodologias
- **3 ferramentas** documentadas
- **1 plataforma** documentada
- **1 categoria patterns** (padrões de implementação — ex.: SDAAL)
- **1 categoria architectures** (C4/ADR)
- **1 categoria meta** (criação de comandos/agentes)

> Categorias `patterns/`, `architectures/` e `meta/` criadas em 2026-06-02 ao
> extrair conteúdo de referência dos outliers de tamanho (T1.5).

---

## 📁 Estrutura por Categoria

```
docs/knowledge-base/
├── concepts/          # 14 arquivos - Conceitos fundamentais
├── frameworks/        # 11 arquivos - Frameworks e metodologias
├── tools/             # 3 arquivos - Ferramentas e recursos
├── platforms/         # 1 arquivo - Plataformas e tecnologias
├── patterns/          # 1 arquivo - Padrões de implementação (SDAAL examples)
├── architectures/     # 1 arquivo - C4 + ADR patterns
└── meta/              # 1 arquivo - Padrões de criação de comandos
```

---

## 🧠 Conceitos Fundamentais (13 arquivos)

Conceitos essenciais que fundamentam o Sistema Onion e desenvolvimento com IA:

### Abstrações e Padrões

1. **[Task Manager Abstraction](concepts/task-manager-abstraction.md)** - Abstração de gerenciadores de tarefas
   - Padrão SDAAL implementado
   - Suporte a ClickUp, Asana, Linear
   - Interface unificada para múltiplos provedores

2. **[Specification-Driven AI Abstraction Layer](concepts/specification-driven-ai-abstraction-layer.md)** - Camada de abstração orientada a especificações
   - Padrão SDAAL completo
   - Documentação como código executável
   - Implementação de referência

3. **[Abstraction Patterns Catalog](concepts/abstraction-patterns-catalog.md)** - Catálogo de padrões de abstração
   - Padrões de design aplicáveis
   - Exemplos práticos
   - Quando usar cada padrão

4. **[AI Agent Design Patterns](concepts/ai-agent-design-patterns.md)** - Padrões de design para agentes IA
   - Arquiteturas de agentes
   - Patterns de especialização
   - Patterns de delegação

### Metodologias de Desenvolvimento

5. **[Spec-as-Code Strategy](concepts/spec-as-code-strategy.md)** - Estratégia de especificações como código
   - Hierarquia de especificações (L0-L3)
   - Versionamento e rastreabilidade
   - Integração com IA

6. **[Spec-Driven Development](concepts/spec-driven-development.md)** - Metodologia emergente de desenvolvimento com IA ✨ NOVO
   - Níveis de implementação (Spec-First, Spec-Anchored, Spec-as-Source)
   - Ferramentas disponíveis (Kiro, Spec-Kit, Tessl)
   - Comparação com TDD, BDD, MDD
   - Benefícios e desafios

### Otimização e Gestão

7. **[Context Window Optimization](concepts/context-window-optimization.md)** - Otimização de contexto para IA
   - Estratégias de redução de tokens
   - Hierarquia de contexto
   - Técnicas de compressão

8. **[Configuration Management](concepts/configuration-management.md)** - Gestão de configurações
   - Variáveis de ambiente
   - Gestão de secrets
   - Integrações opcionais

### Produto e Negócio

9. **[Framework de Story Points](concepts/framework_story_points.md)** - Sistema de estimativas ágeis
   - Escala Fibonacci (1-13)
   - Checklist detalhado por ponto
   - Integração com Task Managers

10. **[Framework de Testes](concepts/framework_testes.md)** - Metodologias de teste completas
    - Modelo V de testes
    - White-box, Grey-box, Black-box
    - QA Story Points

11. **[Identificar e Precificar Dor do Cliente](concepts/identificar-precificar-dor-cliente.md)** - Metodologias de produto
    - Identificação de dores
    - Precificação de soluções
    - Validação de mercado

12. **[Branding e Posicionamento](concepts/branding-posicionamento-marca.md)** - Estratégias de marca
    - Posicionamento de marca
    - Narrativas de negócio
    - Comunicação estratégica

### Processamento de Conhecimento

13. **[Meeting Transcription to Knowledge Base](concepts/meeting-transcription-to-knowledge-base.md)** - Processamento de reuniões
    - Framework EXTRACT (7 dimensões)
    - Transformação de transcrições em conhecimento
    - Templates estruturados

---

## 🏗️ Frameworks e Metodologias (7 arquivos)

Frameworks completos e metodologias aplicáveis:

### Frameworks de Desenvolvimento

1. **[Framework de Story Points](frameworks/framework_story_points.md)** - Estimativas ágeis
   - Escala Fibonacci completa
   - Checklist por ponto
   - Calibração de equipe

2. **[Framework de Testes](frameworks/framework_testes.md)** - White-box, Grey-box, Black-box
   - Modelo V completo
   - Técnicas por perspectiva
   - QA Story Points

### Frameworks do Sistema Onion

3. **[Onion Multi-Context Orchestrator Vision](frameworks/onion-multi-context-orchestrator-vision.md)** - Visão arquitetural
   - Arquitetura Multi-Context
   - Separação business/technical
   - Design philosophy

4. **[Onion Complete Cycle Understanding](frameworks/onion-complete-cycle-understanding.md)** - Sistema completo de 5 camadas
   - Camadas do sistema
   - Fluxos completos
   - Integração entre camadas

5. **[Onion IDE Integration Strategy](frameworks/onion-ide-integration-strategy.md)** - Estratégia multi-IDE
   - Suporte a múltiplos IDEs
   - Estratégia de portabilidade
   - Implementação por IDE

6. **[Onion System Critical Analysis 2025](frameworks/onion-system-critical-analysis-2025.md)** - Análise crítica do sistema
   - Pontos fortes e fracos
   - Oportunidades de melhoria
   - Roadmap estratégico

### Ferramentas e Análises

7. **[Spec-Driven Development Tools 2025](frameworks/spec-driven-development-tools-2025.md)** - Ferramentas e análise
   - Análise comparativa de ferramentas
   - Quando usar cada uma
   - Recomendações práticas

---

## 🛠️ Ferramentas (2 arquivos)

Documentação completa de ferramentas utilizadas:

1. **[Whisper](tools/whisper.md)** - Sistema de transcrição de áudio (OpenAI) ✨ NOVO
   - Arquitetura técnica
   - Instalação multi-plataforma
   - Uso e integração
   - Otimizações para português
   - Integração com Sistema Onion

2. **[Claude Code Commands Best Practices 2026](tools/claude-code-commands-best-practices-2026.md)** - Boas práticas de comandos Claude Code
   - Padrões de design
   - Estrutura recomendada
   - Melhores práticas
   - Anti-patterns

---

## 🌐 Plataformas e Tecnologias (1 arquivo)

Documentação de plataformas integradas:

1. **[Runflow](platforms/runflow.md)** - Documentação da plataforma
   - Visão geral da plataforma
   - Funcionalidades principais
   - Integração com Sistema Onion

---

## 🔌 Provedores de Serviços (1 arquivo)

Documentação de provedores de serviços integrados:

1. **[Microsoft Graph Teams API](providers/microsoft-graph-teams-api-guia-completo.md)** - Guia completo de integração
   - Autenticação e autorização
   - Endpoints principais
   - Casos de uso
   - Exemplos práticos

---

## 🗺️ Navegação por Tema

### Desenvolvimento com IA

- [AI Agent Design Patterns](concepts/ai-agent-design-patterns.md)
- [Spec-Driven Development](concepts/spec-driven-development.md)
- [Spec-as-Code Strategy](concepts/spec-as-code-strategy.md)
- [Specification-Driven AI Abstraction Layer](concepts/specification-driven-ai-abstraction-layer.md)
- [Context Window Optimization](concepts/context-window-optimization.md)

### Metodologias Ágeis

- [Framework de Story Points](frameworks/framework_story_points.md)
- [Framework de Testes](frameworks/framework_testes.md)
- [QA Story Points](concepts/framework_testes.md#qa-story-points)

### Arquitetura e Padrões

- [Task Manager Abstraction](concepts/task-manager-abstraction.md)
- [Abstraction Patterns Catalog](concepts/abstraction-patterns-catalog.md)
- [Onion Multi-Context Orchestrator Vision](frameworks/onion-multi-context-orchestrator-vision.md)
- [Onion Complete Cycle Understanding](frameworks/onion-complete-cycle-understanding.md)

### Produto e Negócio

- [Identificar e Precificar Dor do Cliente](concepts/identificar-precificar-dor-cliente.md)
- [Branding e Posicionamento](concepts/branding-posicionamento-marca.md)
- [Meeting Transcription to Knowledge Base](concepts/meeting-transcription-to-knowledge-base.md)

### Ferramentas e Integrações

- [Whisper](tools/whisper.md)
- [Claude Code Commands Best Practices](tools/claude-code-commands-best-practices-2026.md)
- [Microsoft Graph Teams API](providers/microsoft-graph-teams-api-guia-completo.md)
- [Runflow](platforms/runflow.md)

---

## 🎯 Por Perfil de Usuário

### 👨‍💻 Desenvolvedores

**Conceitos essenciais:**
- [AI Agent Design Patterns](concepts/ai-agent-design-patterns.md)
- [Spec-Driven Development](concepts/spec-driven-development.md)
- [Context Window Optimization](concepts/context-window-optimization.md)
- [Configuration Management](concepts/configuration-management.md)

**Frameworks:**
- [Framework de Testes](frameworks/framework_testes.md)
- [Onion IDE Integration Strategy](frameworks/onion-ide-integration-strategy.md)

**Ferramentas:**
- [Whisper](tools/whisper.md)
- [Claude Code Commands Best Practices](tools/claude-code-commands-best-practices-2026.md)

### 📋 Product Owners

**Conceitos essenciais:**
- [Framework de Story Points](concepts/framework_story_points.md)
- [Identificar e Precificar Dor do Cliente](concepts/identificar-precificar-dor-cliente.md)
- [Branding e Posicionamento](concepts/branding-posicionamento-marca.md)
- [Meeting Transcription to Knowledge Base](concepts/meeting-transcription-to-knowledge-base.md)

**Frameworks:**
- [Framework de Story Points](frameworks/framework_story_points.md)
- [Spec-Driven Development Tools](frameworks/spec-driven-development-tools-2025.md)

### 🏗️ Arquitetos

**Conceitos essenciais:**
- [Task Manager Abstraction](concepts/task-manager-abstraction.md)
- [Specification-Driven AI Abstraction Layer](concepts/specification-driven-ai-abstraction-layer.md)
- [Abstraction Patterns Catalog](concepts/abstraction-patterns-catalog.md)
- [Spec-as-Code Strategy](concepts/spec-as-code-strategy.md)

**Frameworks:**
- [Onion Multi-Context Orchestrator Vision](frameworks/onion-multi-context-orchestrator-vision.md)
- [Onion Complete Cycle Understanding](frameworks/onion-complete-cycle-understanding.md)
- [Onion System Critical Analysis](frameworks/onion-system-critical-analysis-2025.md)

### 🧪 QA/Test Engineers

**Conceitos essenciais:**
- [Framework de Testes](concepts/framework_testes.md)
- [QA Story Points](concepts/framework_testes.md#qa-story-points)

**Frameworks:**
- [Framework de Testes](frameworks/framework_testes.md) - Guia completo

---

## 🔗 Links Rápidos

### Documentação Relacionada
- [Índice Central](../../INDEX.md) - Hub de navegação completo
- [Sistema Onion](../onion/index.md) - Documentação do Sistema Onion
- [Meta Especificações](../meta-specs/index.md) - Especificações de alto nível

### Comandos Relacionados
- `/docs/build-index` - Reconstruir índices
- `/meta/create-knowledge-base` - Criar novas knowledge bases

### Agentes Relacionados
- `@research-agent` - Pesquisa e análise
- `@product-agent` - Gestão de produto
- `@metaspec-gate-keeper` - Validação de conformidade

---

## 📅 Histórico de Atualizações

| Data | Mudança |
|------|---------|
| 2025-12-20 | Índice reconstruído com 24 arquivos |
| 2025-12-02 | Adicionado Spec-Driven Development |
| 2025-12-02 | Adicionado Whisper knowledge base |
| 2025-11-24 | Criação inicial do índice |

---

## 🆕 Novidades Recentes

### ✨ Adicionado Recentemente

- **[Spec-Driven Development](concepts/spec-driven-development.md)** (2025-12-02)
  - Metodologia emergente completa
  - Análise de ferramentas (Kiro, Spec-Kit, Tessl)
  - Níveis de implementação detalhados

- **[Whisper](tools/whisper.md)** (2025-12-02)
  - Knowledge base completa do Whisper
  - Instalação multi-plataforma
  - Integração com Sistema Onion

- **[Microsoft Graph Teams API](providers/microsoft-graph-teams-api-guia-completo.md)**
  - Guia completo de integração
  - Autenticação e endpoints
  - Casos de uso práticos

---

## 🔄 Manutenção

Este índice é gerado automaticamente pelo comando `/docs/build-index knowbase`.

**Para atualizar:**
```bash
/docs/build-index knowbase     # Reconstruir este índice
/docs/build-index              # Reconstruir índice principal
```

---

**Última atualização:** 2025-12-20  
**Versão:** 4.1.0-beta.1  
**Mantido por:** Sistema Onion

---

**Knowledge Bases** - Conhecimento estruturado para desenvolvimento com IA 📚
