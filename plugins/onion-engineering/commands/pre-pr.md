---
name: pre-pr
description: Validação completa antes do PR. Verifica padrões e qualidade.
model: sonnet
allowed-tools: Read Bash(cat .env*) Bash(git *)
category: engineer
tags: [validation, pr, quality]
version: "3.1.0"
updated: "2026-06-13"
---

# Pre-PR - Validação Completa Antes do Pull Request

Estamos nos aproximando de finalizar o trabalho nesta branch e nos preparar para um pull request. Agora, é hora de fazer verificações finais e limpezas para garantir que estamos alinhados com nossos padrões e objetivos.

## 🔄 **Auto-Update do Task Manager**

Mecanismo de sincronização: `common:prompts:task-manager-auto-update` (provedor
ativo via adapter; comentário formatado por provider; timestamp + status; offline
→ gerar relatório local, sem persistir).

**Gatilho deste comando:** durante a preparação para PR.

### **✅ Específico do pre-PR:**
- Tag `ready-for-pr` quando todas as verificações passam; `needs-fixes` se alguma falha.
- Progresso estimado ~90% (quase pronto).

### **💬 Payload do comentário:**
Resultado da validação de critérios de aceitação (completo? cobertura? critérios
pendentes?), checks técnicos (meta specs, code review, testes) e indicador `readyForPR`.

## Checklist de Preparação:

### ✅ Validação de Critérios de Aceitação:
1. **Extrair critérios** - Ler checkboxes da description da task/subtask
2. **Validar cobertura** - Confirmar que TODOS os checkboxes estão marcados `[x]`
3. **Gerar relatório** - Criar lista de critérios validados
4. **Bloquear se incompleto** - Se algum critério não estiver marcado, indicar no comentário

### 🔧 Validações Técnicas (fan-out paralelo):

Os quatro agentes abaixo são **independentes** — execute-os como uma **orquestração em paralelo** (fan-out) e depois **consolide** o feedback num relatório único (fan-in). Padrão na skill `onion-orchestration` e na KB `agent-orchestration`.

**Fan-out (paralelo)** — dispare simultaneamente, cada um com saída estruturada:
- `branch-metaspec-checker` — alinhamento da branch com as meta-specs do projeto.
- `branch-code-reviewer` — qualidade do código, pronto para lançar.
- `branch-documentation-writer` — documentação do projeto atualizada.
- `branch-test-planner` — testes finalizados para a branch.

**Fan-in (consolidação)** — mescle os quatro retornos num **relatório único** de pré-PR, deduplicando achados e ordenando por severidade.

> **Fallback sequencial:** se o substrato de fan-out paralelo não estiver disponível, invoque os quatro agentes em sequência (1→4) e consolide ao final — mesmo resultado, mais lento. Padrão canônico de degradação: `common/prompts/orchestration-fallback.md`.

### 📋 AUTO-UPDATE:
5. **Validar critérios de aceitação** - Verificar todos os checkboxes
6. **Adicionar comentário de preparação** no Task Manager configurado automaticamente (conforme `TASK_MANAGER_PROVIDER`)
7. **Aplicar tags** (ready-for-pr ou needs-fixes)
8. **Atualizar progresso** para 90%

Você também precisará lidar com todo o feedback que esses agentes fornecerem e fazer mudanças e correções conforme necessário.

Uma vez terminado E todos os critérios de aceitação validados, me avise e peça minha permissão para abrir o Pull Request.

