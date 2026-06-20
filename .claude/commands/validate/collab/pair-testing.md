---
name: pair-testing
description: |
  Organiza sessão de pair testing multi-perspectiva para validação colaborativa de features.
  Use para estruturar sessões de teste em par (Dev+Dev, Dev+QA, QA+QA) com foco em White-box, Grey-box ou Black-box.
model: sonnet
allowed-tools: Read Glob Write

parameters:
  - name: feature
    description: 'Nome da feature/funcionalidade a ser testada (ex: "checkout", "login", "user-profile")'
    required: true
  - name: perspective
    description: Perspectiva de teste (white-box|grey-box|black-box). Define o foco da sessão
    required: true
  - name: schedule
    description: Criar evento no calendário para a sessão
    required: false
  - name: task-manager
    description: 'Task manager usado (clickup|jira|linear|asana). Default: TASK_MANAGER_PROVIDER do .env'
    required: false
    default: auto
  - name: feature-id
    description: 'ID da feature no task manager (ex: TASK-123, CU-456). Opcional para buscar contexto'
    required: false
  - name: participants
    description: 'Participantes da sessão (ex: "dev1,qa1" ou "dev1,dev2"). Se não fornecido, será inferido da perspectiva'
    required: false

category: validate
tags:
  - collaboration
  - pair-testing
  - testing
  - qa
  - validation
  - grey-box
  - black-box
  - white-box

version: "3.0.0"
updated: "2025-12-03"

related_commands:
  - /validate/collab/three-amigos
  - /validate/test-strategy/create
  - /validate/test-strategy/analyze
  - /product/task

related_agents:
  - test-engineer
  - test-planner
---

# 🤝 Pair Testing - Sessão de Teste em Par

Organiza sessões de pair testing multi-perspectiva para validação colaborativa de features.

Este comando é um **orquestrador**: os protocolos detalhados (agendas por perspectiva, template de documentação, checklist de execução, formatos de comentário) vivem na KB de referência [`docs/knowledge-base/frameworks/collaborative-testing-patterns.md`](../../../../docs/knowledge-base/frameworks/collaborative-testing-patterns.md). O framework canônico de testes (perspectivas, QA Story Points, técnicas) vive em [`framework-testes.md`](../../../../docs/knowledge-base/frameworks/framework-testes.md).

## 🎯 Objetivo

Estruturar e facilitar sessões de pair testing que resultem em:
- **Validação colaborativa** da feature sob múltiplas perspectivas
- **Descoberta de edge cases** através de diferentes olhares
- **Transferência de conhecimento** entre participantes
- **Documentação em tempo real** de findings e bugs
- **Estimativa colaborativa** de QA Story Points
- **Test strategy refinada** baseada em descobertas

## ⚡ Fluxo de Execução

### Passo 1: Carregar Referências (OBRIGATÓRIO)

Antes de organizar a sessão, ler:
1. `docs/knowledge-base/frameworks/collaborative-testing-patterns.md` — protocolo, agendas, templates e checklists.
2. `docs/knowledge-base/frameworks/framework-testes.md` — framework canônico (perspectivas White/Grey/Black-box, QA Story Points, técnicas).

```markdown
SE alguma KB não for encontrada:
  ❌ ERRO: KB não encontrada em <caminho>
  💡 Verifique se o arquivo existe e tente novamente
```

### Passo 2: Validar e Normalizar Parâmetros

```markdown
- feature: {{feature}} ✅ obrigatório (abortar se vazio)
- perspective: {{perspective}} ✅ obrigatório — minúsculas, validar em [white-box|grey-box|black-box]
- schedule: {{schedule}} ou false
- task-manager: {{task-manager}} ou "clickup"
- feature-id: {{feature-id}} ou null
- participants: {{participants}} ou inferir da perspectiva

SE perspective inválida:
  ❌ ERRO: Perspectiva inválida: {{perspective}} — válidos: white-box, grey-box, black-box → exit 1
```

### Passo 3: Determinar Participantes e Combinação

**SE** `{{participants}}` fornecido → usar diretamente (validar formato, ex: `"dev1,qa1"`).
**SENÃO** → inferir da perspectiva usando a tabela **§1 (Perspectiva → Combinação)** da KB. Gerar o bloco "Participantes Sugeridos" descrito lá.

### Passo 4: Buscar Contexto da Feature (Opcional)

**SE** `{{feature-id}}` fornecido:
- buscar via adapter do Task Manager (REST API; MCP opcional): descrição, critérios de aceitação, test strategy, bugs conhecidos, comentários.

**SENÃO** → buscar arquivos relacionados no código (testes, documentação, especificações).

### Passo 5: Gerar Agenda Estruturada

Selecionar a agenda correspondente à perspectiva (**§2 da KB**):
- `grey-box` → Dev + Dev (§2.1)
- `white-box` / `black-box` com Dev+QA → Dev + QA (§2.2)
- `black-box` com QA+QA → QA + QA (§2.3)

Preencher cabeçalho com feature, participantes, perspectiva, duração (1-2h) e data. Salvar como `pair-testing-agenda-{{feature}}.md`.

### Passo 6: Criar Template de Documentação

Instanciar o **template §3 da KB** preenchido com `{{feature}}`/`{{feature-id}}`. Salvar como `pair-testing-session-{{feature}}.md`.

### Passo 7: Criar Checklist de Execução

Instanciar o **checklist §4 da KB**. Salvar como `pair-testing-checklist-{{feature}}.md`.

### Passo 8: Integração com Task Manager (Opcional)

**SE** `{{feature-id}}` fornecido → seguir **§5 da KB**: comentar resumo da sessão, criar subtasks (preparação, execução, follow-up de bugs), aplicar tags `pair-testing` e `{{perspective}}`. Respeitar o provider ativo (`TASK_MANAGER_PROVIDER`) e sua formatação.

### Passo 9: Integração com Calendar (Opcional)

**SE** `{{schedule}}` fornecido → criar evento conforme **§6 da KB** (título, duração, participantes, reminder 15min antes). **SENÃO** → gerar `.ics` ou instruir criação manual.

## 📤 Output Esperado

**Arquivos gerados:**
- `pair-testing-agenda-{{feature}}.md` — agenda por perspectiva
- `pair-testing-session-{{feature}}.md` — template de documentação preenchível
- `pair-testing-checklist-{{feature}}.md` — checklist de execução
- Calendar event (se `--schedule`)

**Atualizações no Task Manager** (se `{{feature-id}}`): comentário com resumo, subtasks, tags `pair-testing`/`{{perspective}}`, custom fields.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PAIR TESTING SESSION ORGANIZED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Feature: {{feature}}   🎯 Perspectiva: {{perspective}}
👥 Participantes: [Participante 1] + [Participante 2]
📁 Arquivos: agenda / session / checklist
🔗 Task Manager: {{task-manager}} (Feature ID: {{feature-id}})
📅 Calendar: [criado se --schedule]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- **Padrões de Testing Colaborativo (protocolo, agendas, templates, checklists):** `docs/knowledge-base/frameworks/collaborative-testing-patterns.md`
- **Framework de Testes (canônico):** `docs/knowledge-base/frameworks/framework-testes.md`
- **Three Amigos:** `/validate/collab/three-amigos`
- **Test Strategy:** `/validate/test-strategy/create`

## ⚠️ Notas

- **Duração:** 1-2 horas por sessão. **Rotação Driver/Navigator:** a cada 20-30min.
- **Perspectivas válidas:** `white-box`, `grey-box`, `black-box`.
- **Combinações:** `grey-box` → Dev+Dev · `white-box`/`black-box` com Dev+QA → Dev+QA · `black-box` com QA+QA → QA+QA.
- **Documentação:** sempre em tempo real. Use `--schedule` para calendar e `--feature-id` para integração automática.

## 💡 Exemplos de Uso

### Exemplo 1: Pair Testing Grey-box com Agendamento

```bash
/validate/collab/pair-testing "checkout" grey-box --schedule --feature-id CU-123
```

**Output:**
- Agenda gerada para Dev+Dev
- Template de documentação criado
- Checklist preparado
- Evento criado no calendário
- Comentário adicionado na task CU-123 no ClickUp

### Exemplo 2: Pair Testing Black-box Manual

```bash
/validate/collab/pair-testing "login" black-box --participants "qa1,qa2"
```

**Output:**
- Agenda gerada para QA+QA
- Template de documentação criado
- Checklist preparado
- Sem integração automática (sem `--feature-id` e `--schedule`)

### Exemplo 3: Pair Testing White-box com Contexto

```bash
/validate/collab/pair-testing "user-profile" white-box --feature-id TASK-456 --task-manager jira
```

**Output:**
- Agenda gerada para Dev+QA
- Contexto buscado do Jira (TASK-456)
- Template preenchido com contexto
- Checklist preparado
- Comentário adicionado na task do Jira

