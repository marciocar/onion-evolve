---
name: three-amigos
description: |
  Facilita sessão Three Amigos (PO + Developer + QA) para refinement de stories.
  Gera agenda estruturada, template de ata e checklist de outputs.
model: sonnet
allowed-tools: Read Write Bash(cat .env*)

parameters:
  - name: story_id
    description: 'ID da story no task manager (ex: STORY-123, TASK-456)'
    required: true
  - name: task_manager
    description: 'Task manager usado (clickup|jira|linear|asana). Default: TASK_MANAGER_PROVIDER do .env'
    required: false
    default: auto
  - name: generate_agenda
    description: Gerar agenda automaticamente antes da sessão
    required: false
    default: false

category: validate
tags:
  - collaboration
  - three-amigos
  - refinement
  - qa
  - product

version: "3.0.0"
updated: "2025-11-24"

related_commands:
  - /validate/test-strategy/create
  - /product/refine
  - /product/task

related_agents:
  - test-engineer
  - product-agent
---

# 🤝 Three Amigos - Sessão de Colaboração

Facilita sessões Three Amigos (Product Owner + Developer + QA) para refinement de user stories, estimativa de pontos e definição de estratégia de testes.

## 🎯 Objetivo

Estruturar e facilitar sessões Three Amigos que resultem em:
- **User story refinada** com critérios de aceitação claros
- **Dev story points** e **QA story points** estimados
- **Cross-testing points** identificados
- **Test strategy** definida e **riscos** mapeados por todas as perspectivas
- **Definition of Done** acordada

## 📚 Knowledge Base

Os **protocolos de colaboração**, **agendas detalhadas**, **templates** e **checklists** vivem na KB de testing colaborativo. Este comando atua como **orquestrador** — carregue a KB e seção 8 (Three Amigos) ao montar agenda, ata, checklist ou integração:

- **KB:** [`docs/knowledge-base/frameworks/collaborative-testing-patterns.md`](../../../../docs/knowledge-base/frameworks/collaborative-testing-patterns.md)
  - Seção 8.1 — Agenda Three Amigos (PO/Dev/QA/Cross/Consolidação)
  - Seção 8.2 — Template de Ata
  - Seção 8.3 — Checklist de Outputs
  - Seção 8.4 — Comentário de conclusão + regras de integração com task manager
  - Seção 6 — Integração com Calendar
- **Framework canônico de testes** (White/Grey/Black-box, QA Story Points): [`framework-testes.md`](../../../../docs/knowledge-base/frameworks/framework-testes.md)

> **Não duplique** o conteúdo da KB neste comando. Sempre referencie e instancie os templates com `{{story_id}}` / `{{task_manager}}`.

## ⚡ Fluxo de Execução

### Passo 1: Preparação da Sessão

**SE** `{{generate_agenda}}` fornecido **OU** agenda não existe:
1. Buscar informações da story no task manager (Passo 2).
2. Gerar agenda usando o template da **KB seção 8.1**, substituindo `{{story_id}}`.
3. Salvar como `three-amigos-agenda-{{story_id}}.md`.

**SENÃO:** usar agenda existente ou criar manualmente.

### Passo 2: Buscar Contexto da Story

- Buscar via **adapter** do Task Manager (`taskManager.getTask(taskId)` — REST API default; MCP opcional): detalhes/descrição da task, critérios de aceitação, subtasks/itens e comentários anteriores. O adapter resolve o provider ativo (ClickUp/Jira/Asana/Linear) e o formato.
- Provider `none` / indisponível → solicitar as informações manualmente ao usuário.

### Passo 3: Gerar Template de Ata

Instanciar o template da **KB seção 8.2** com `{{story_id}}` e salvar como `three-amigos-ata-{{story_id}}.md`.

### Passo 4: Criar Checklist de Outputs

Instanciar o checklist da **KB seção 8.3** e salvar como `three-amigos-checklist-{{story_id}}.md`.

### Passo 5: Integração com Task Manager

Seguir as regras da **KB seção 8.4** (e seção 5 para o provider ativo):
- Atualizar descrição da task com a story refinada.
- Criar subtasks: Desenvolvimento (Dev points), Testes (QA points), Cross-testing (Cross points).
- Adicionar comentário de conclusão (template KB 8.4), tags `three-amigos` + `refined` e custom fields (Dev/QA/Cross Points) quando disponíveis.

Sem provider configurado (`none`): documentar manualmente, sem chamadas de API.

### Passo 6: Integração com Calendar (Opcional)

Conforme **KB seção 6**: criar evento `Three Amigos: {{story_id}}` (60-90min, PO/Dev/QA, agenda + link da story + anexo da ata), enviar convite e reminder 15min antes. Sem integração disponível: gerar `.ics` ou instruir criação manual.

## 📤 Output Esperado

**Arquivos gerados:**
- `three-amigos-agenda-{{story_id}}.md` — agenda com timing (se `--generate-agenda`)
- `three-amigos-ata-{{story_id}}.md` — template de ata preenchível
- `three-amigos-checklist-{{story_id}}.md` — validação de completude
- Calendar event (se integração disponível)

**Atualizações no task manager:** descrição atualizada, comentário de resumo, subtasks (Dev/QA/Cross), tags e custom fields.

**Resumo visual:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ THREE AMIGOS SESSION PREPARED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Story: {{story_id}}
📁 Arquivos: agenda · ata · checklist (three-amigos-*-{{story_id}}.md)
🔗 Task Manager: {{task_manager}} — story atualizada ✓ · comentário ✓
📅 Calendar: [Status]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## ⚠️ Notas

- **Duração:** 60-90 minutos por story · **Timing ideal:** Sprint Planning ou Refinement.
- **Participantes obrigatórios:** PO + Developer + QA.
- **Outputs críticos:** estimativas (Dev + QA + Cross) e test strategy.
- **Documentação:** sempre registrar a ata completa para referência futura.
- **Calendar:** integração opcional, pode ser manual.

## 💡 Exemplos de Uso

```bash
# Sessão com agenda automática (ClickUp)
/validate/collab/three-amigos STORY-123 clickup --generate-agenda
# → agenda + ata + checklist gerados · story atualizada no ClickUp

# Sessão manual sem agenda (Jira)
/validate/collab/three-amigos TASK-456 jira
# → ata + checklist · instruções para buscar story no Jira

# Sessão com calendar integration
/validate/collab/three-amigos FEATURE-789 clickup --generate-agenda --calendar
# → outputs acima + evento no calendário e convites enviados
```
