---
name: warm-up
description: |
  Preparação geral do projeto - contexto completo do Sistema Onion.
  Revisa README, estrutura de documentação e meta especificações.
model: sonnet
allowed-tools: Read Bash(ls *) Bash(find docs*)
category: general
tags: [warmup, context, preparation, overview]
version: "3.1.0"
updated: "2026-06-18"
---

# 🔥 Warm-up Geral do Projeto

Preparação completa do contexto geral do Sistema Onion para sessões de trabalho.

## 🎯 Objetivo

Estabelecer contexto completo do projeto incluindo:
- Visão geral do Sistema Onion
- Estrutura completa de documentação
- Meta especificações (constituição do sistema)
- Mapeamento de recursos disponíveis

## 📋 Checklist de Preparação

### 1. README Principal
- ✅ Revisar `README.md` na raiz do projeto
- ✅ Entender estrutura do Sistema Onion v3.0
- ✅ Identificar comandos e agentes principais
- ✅ Mapear integrações disponíveis (ClickUp, Asana, Linear)

### 2. Estrutura de Documentação
- ✅ Listar arquivos em `docs/` e manter no contexto
- ✅ Revisar `docs/INDEX.md` (índice central)
- ✅ Mapear estrutura:
  - `docs/onion/` - Sistema Onion (12 arquivos)
  - `docs/knowledge-base/` - Knowledge Bases (16 arquivos)
  - `docs/meta-specs/` - Meta Especificações
  - `docs/analysis/` - Análises
  - `docs/plans/` - Planos de execução

### 3. Meta Especificações
- ✅ Revisar `docs/meta-specs/index.md`
- ✅ Memorizar hierarquia: Meta Specs (L0) → Domain Specs (L1) → Feature Specs (L2) → Task Specs (L3)
- ✅ Entender arquivos planejados:
  - `architecture.md` - Padrões arquiteturais
  - `code-standards.md` - Padrões de código
  - `agents.md` - Padrões para agentes
  - `commands.md` - Padrões para comandos
  - `integrations.md` - Padrões para integrações
- ✅ Conhecer processo de validação via `@metaspec-gate-keeper`

### 4. Recursos Principais
- ✅ Comando `/onion` - ponto de entrada inteligente
- ✅ Agente `@onion` - orquestrador master
- ✅ Task Manager Abstraction (ClickUp, Asana, Linear)
- ✅ Framework EXTRACT para reuniões

### 5. Co-evolução (se `docs/evolution/` existir)
- ✅ Reconhecer o papel do repo: `source` (core) · `adopted` (consumidor) — via `.claude/.onion-version` ou `.claude/validation/onion-version.sh`
- ✅ Conferir os canais de co-evolução: `docs/evolution/inbox/` (upstream, sinal/feedback) e, em consumidores, `docs/evolution/inbound/` (downstream, relatório de update/anúncio do core). O hook SessionStart "you have mail" já avisa a **contagem** no boot (📬 inbox / 📥 inbound); o warm-up apenas **orienta** — não re-conta.
- ✅ Havendo mensagens, rodar `/meta:co-evolve` para ler/gerenciar. O protocolo canônico (3 fluxos) vive em `docs/evolution/README.md`.

## 🔍 Contexto a Manter

### Documentação Essencial
- `README.md` - Visão geral completa
- `docs/INDEX.md` - Hub de navegação
- `docs/onion/commands-guide.md` - Todos os comandos
- `docs/onion/agents-reference.md` - Todos os agentes
- `docs/meta-specs/index.md` - Meta especificações
- `docs/evolution/README.md` - Modelo de co-evolução core↔derivados (se presente)

### Estrutura de Comandos
- 91 comandos em 10 categorias
- 51 agentes especializados em 9 categorias
- Knowledge Bases estruturadas para IA

## 💡 Quando Usar Este Warm-up

- ✅ Primeira vez no projeto
- ✅ Retorno após período ausente
- ✅ Mudança de contexto de trabalho
- ✅ Necessidade de visão geral completa

## 🔗 Próximos Passos

Após este warm-up geral, use warm-ups específicos:
- `/product/warm-up` - Para trabalho de produto
- `/engineer/warm-up` - Para trabalho de engenharia
- `/meta:co-evolve` - Se o hook "you have mail" (📬 inbox / 📥 inbound) sinalizou mensagens nos canais de co-evolução

## ⚠️ Notas

- Este warm-up fornece contexto geral, não técnico profundo
- Para trabalho específico, use warm-ups de categoria
- Mantenha lista de arquivos `docs/` no contexto para referência rápida
