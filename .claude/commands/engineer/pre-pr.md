---
name: pre-pr
description: Validação completa antes do PR. Verifica padrões e qualidade.
model: sonnet
category: engineer
tags: [validation, pr, quality]
version: "3.1.0"
updated: "2026-06-13"
---

# Pre-PR - Validação Completa Antes do Pull Request

Estamos nos aproximando de finalizar o trabalho nesta branch e nos preparar para um pull request. Agora, é hora de fazer verificações finais e limpezas para garantir que estamos alinhados com nossos padrões e objetivos.

## 🔄 **Auto-Update do Task Manager**

Este comando **automaticamente atualiza** a task no **Task Manager configurado** durante preparação para PR. Antes de operar, carregue o `.env` e leia `TASK_MANAGER_PROVIDER` (`jira` | `clickup` | `asana` | `linear` | `none`) para rotear ao provider e adapter corretos. Se `none`, gere o relatório de validação localmente sem persistir.

### **✅ Updates Automáticos SEMPRE:**
- **Validação de critérios de aceitação** - Verifica todos os checkboxes
- **Comentário de preparação** com checklist completo
- **Tag 'ready-for-pr'** quando todas verificações passam
- **Tag 'needs-fixes'** se verificações falham
- **Progresso estimado** para 90% (quase pronto)

### **💬 Formato do Comentário de Pre-PR:**

O comentário de validação deve conter: resultado da validação de critérios de aceitação (completo? cobertura? critérios pendentes?), checks técnicos (meta specs, code review, testes) e indicador `readyForPR`.

**Roteamento por provider** (carregar `.env` → ler `TASK_MANAGER_PROVIDER` → seguir o adapter):

- **`clickup`** → comentário em formatação Unicode via `@clickup-specialist`. Adapter: `.claude/utils/task-manager/adapters/clickup.md` (API-first; MCP opcional). Padrões: `.claude/commands/common/prompts/clickup-patterns.md`.
- **`jira`** → comentário em ADF via `@jira-specialist`. Adapter: `.claude/utils/task-manager/adapters/jira.md`.
- **`asana`** → comentário (story) via `@task-specialist`. Adapter: `.claude/utils/task-manager/adapters/asana.md`.
- **`linear`** → comentário em Markdown via `@task-specialist`. Adapter: `.claude/utils/task-manager/adapters/linear.md`.
- **`none`** → gerar relatório localmente, sem persistir.

### **📋 Identificação da Task:**
1. **Context.md**: Lê task-id da sessão ativa
2. **Branch atual**: Detecta automaticamente pela branch git

## Checklist de Preparação:

### ✅ Validação de Critérios de Aceitação:
1. **Extrair critérios** - Ler checkboxes da description da task/subtask
2. **Validar cobertura** - Confirmar que TODOS os checkboxes estão marcados `[x]`
3. **Gerar relatório** - Criar lista de critérios validados
4. **Bloquear se incompleto** - Se algum critério não estiver marcado, indicar no comentário

### 🔧 Validações Técnicas (fan-out paralelo):

Os quatro agentes abaixo são **independentes** — execute-os como uma **frota em paralelo** (fan-out) e depois **consolide** o feedback num relatório único (fan-in). Padrão na skill `onion-fleet` e na KB `agent-fleet-orchestration`.

**Fan-out (paralelo)** — dispare simultaneamente, cada um com saída estruturada:
- `branch-metaspec-checker` — alinhamento da branch com as meta-specs do projeto.
- `branch-code-reviewer` — qualidade do código, pronto para lançar.
- `branch-documentation-writer` — documentação do projeto atualizada.
- `branch-test-planner` — testes finalizados para a branch.

**Fan-in (consolidação)** — mescle os quatro retornos num **relatório único** de pré-PR, deduplicando achados e ordenando por severidade.

> **Fallback sequencial:** se o substrato de fan-out paralelo não estiver disponível, invoque os quatro agentes em sequência (1→4) e consolide ao final — mesmo resultado, mais lento. Padrão canônico de degradação: `common/prompts/fleet-fallback.md`.

### 📋 AUTO-UPDATE:
5. **Validar critérios de aceitação** - Verificar todos os checkboxes
6. **Adicionar comentário de preparação** no Task Manager configurado automaticamente (conforme `TASK_MANAGER_PROVIDER`)
7. **Aplicar tags** (ready-for-pr ou needs-fixes)
8. **Atualizar progresso** para 90%

Você também precisará lidar com todo o feedback que esses agentes fornecerem e fazer mudanças e correções conforme necessário.

Uma vez terminado E todos os critérios de aceitação validados, me avise e peça minha permissão para abrir o Pull Request.

