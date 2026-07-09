---
name: warm-up
description: |
  Preparação de contexto de produto e negócio.
  Foca em documentação de produto, especificações, knowledge bases de negócio e frameworks de produto.
model: sonnet
allowed-tools: Read Glob
category: product
tags: [warmup, context, product, business]
version: "3.0.0"
updated: "2025-12-02"
---

# 🔥 Warm-up de Produto

Preparação específica para trabalho de produto, negócio e gestão de features.

## 🎯 Objetivo

Estabelecer contexto focado em:
- Documentação de produto e negócio
- Especificações de features e domínios
- Knowledge bases de produto
- Frameworks de produto (Story Points, etc)
- Comandos e agentes de produto

## 📋 Checklist de Preparação

### 1. Contexto Geral (Base)
- ✅ Revisar `README.md` para visão geral do Sistema Onion
- ✅ Entender estrutura de documentação em `docs/`

### 2. Meta Especificações
- ✅ Revisar `docs/meta-specs/index.md`
- ✅ Memorizar hierarquia de especificações
- ✅ Entender quando consultar meta specs para decisões de produto

### 3. Documentação de Produto
- ✅ Revisar `docs/onion/commands-guide.md` - Seção "Comandos de Produto"
- ✅ Mapear comandos de produto disponíveis:

**Gestão de Tasks:**
- `/product/task` - Criar tasks com estimativas automáticas
- `/product/feature` - Criar tasks de feature para backlog
- `/product/collect` - Coletar ideias de features/bugs
- `/product/task-check` - Verificar status de tasks
- `/product/validate-task` - Validar tasks contra meta-specs
- `/product/checklist-sync` - Sincronizar checklists

**Especificação e Refinamento:**
- `/product/spec` - Especificações técnicas
- `/product/refine` - Refinamento de requisitos
- `/product/estimate` - Estimar story points
- `/product/light-arch` - Arquitetura leve

**Processamento de Reuniões:**
- `/product/extract-meeting` - Extrair insights de reuniões (Framework EXTRACT)
- `/product/consolidate-meetings` - Consolidar múltiplas reuniões

**Análise e Validação:**
- `/product/check` - Verificar requisitos contra meta-specs
- `/product/analyze-pain-price` - Analisar dor do cliente e precificação

**Comunicação:**
- `/product/branding` - Trabalhar em branding e posicionamento
- `/product/presentation` - Criar apresentações

**Documentação Relacionada:**
- `/docs/consolidate-documents` - Consolidar documentos de produto/negócio

### 4. Knowledge Bases de Produto
- ✅ Revisar `${CLAUDE_PLUGIN_ROOT}/kb/framework-story-points.md`
- ✅ Revisar `docs/knowledge-base/concepts/task-manager-abstraction.md`
- ✅ Revisar `${CLAUDE_PLUGIN_ROOT}/kb/meeting-transcription-to-knowledge-base.md`
- ✅ Revisar `${CLAUDE_PLUGIN_ROOT}/kb/identificar-precificar-dor-cliente.md`
- ✅ Revisar `docs/knowledge-base/concepts/branding-posicionamento-marca.md`

### 5. Agentes de Produto
- ✅ Conhecer agentes especializados:
  - `@product-agent` - Orquestração estratégica
  - `@story-points-framework-specialist` - Estimativas ágeis
  - `@extract-meeting-specialist` - Extração de reuniões
  - `@meeting-consolidator` - Consolidação de reuniões
  - `@storytelling-business-specialist` - Narrativas de negócio
  - `@branding-positioning-specialist` - Branding e posicionamento

### 6. Task Manager Integration
- ✅ Verificar `TASK_MANAGER_PROVIDER` no `.env`
- ✅ Entender abstração de Task Manager (ClickUp, Asana, Linear)
- ✅ Revisar `docs/knowledge-base/concepts/task-manager-abstraction.md`

### 7. Especificações de Features
- ✅ Mapear estrutura de especificações:
  - Domain Specs (L1) - Regras de negócio
  - Feature Specs (L2) - Especificações de features
- ✅ Entender formato de especificações do projeto

## 🔍 Contexto Específico de Produto

### Documentação Essencial
- `docs/onion/commands-guide.md` - Comandos de produto
- `docs/onion/practical-examples.md` - Exemplos práticos
- `${CLAUDE_PLUGIN_ROOT}/kb/framework-story-points.md` - Framework de estimativas
- `${CLAUDE_PLUGIN_ROOT}/kb/meeting-transcription-to-knowledge-base.md` - Processamento de reuniões

### Workflows de Produto

**Workflow Completo de Feature:**
1. **Coletar**: `/product/collect` → Coletar ideias de features/bugs
2. **Criar Task**: `/product/task` → Cria com story points automáticos
3. **Criar Feature**: `/product/feature` → Criar task de feature para backlog
4. **Validar**: `/product/check` → Verificar requisitos contra meta-specs
5. **Especificar**: `/product/spec` → Documenta feature completa
6. **Estimar**: `/product/estimate` → Ajusta estimativas
7. **Refinar**: `/product/refine` → Recalcula estimativas após mudanças
8. **Arquitetura**: `/product/light-arch` → Arquitetura leve da feature

**Workflow de Reuniões:**
1. **Extrair Reunião**: `/product/extract-meeting` → Framework EXTRACT (7 dimensões)
2. **Consolidar**: `/product/consolidate-meetings` → Análise de múltiplas reuniões
3. **Consolidar Docs**: `/docs/consolidate-documents` → Consolidar documentos relacionados

**Workflow de Validação:**
1. **Validar Task**: `/product/validate-task` → Validar task contra meta-specs
2. **Verificar**: `/product/task-check` → Verificar status e completude
3. **Sincronizar**: `/product/checklist-sync` → Sincronizar checklists com Task Manager

**Workflow de Análise:**
1. **Analisar Dor**: `/product/analyze-pain-price` → Analisar dor do cliente e precificação
2. **Branding**: `/product/branding` → Trabalhar em branding e posicionamento
3. **Apresentação**: `/product/presentation` → Criar apresentações

## 💡 Quando Usar Este Warm-up

- ✅ Trabalho em especificações de features
- ✅ Criação ou refinamento de tasks (`/product/task`, `/product/feature`, `/product/collect`)
- ✅ Estimativas de story points (`/product/estimate`)
- ✅ Processamento de reuniões (`/product/extract-meeting`, `/product/consolidate-meetings`)
- ✅ Consolidação de documentos (`/docs/consolidate-documents`)
- ✅ Análise de requisitos de negócio (`/product/check`, `/product/validate-task`)
- ✅ Análise de dor do cliente (`/product/analyze-pain-price`)
- ✅ Trabalho com Product Owners
- ✅ Branding e posicionamento (`/product/branding`)
- ✅ Criação de apresentações (`/product/presentation`)

## 🔗 Integração com Engenharia

Após preparar contexto de produto:
- Tasks criadas são validadas por `/engineer/start`
- Story points são verificados antes de iniciar desenvolvimento
- Especificações alimentam sessões de engenharia

## ⚠️ Notas

- Foco em contexto de negócio e produto, não técnico
- Mantenha conhecimento de frameworks de produto no contexto
- Use agentes especializados para tarefas específicas
- Sempre sincronize tasks com Task Manager configurado

