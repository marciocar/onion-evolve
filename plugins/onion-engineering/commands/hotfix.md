---
name: hotfix
description: |
  Emergency workflow completo: task no Task Manager + branch hotfix + desenvolvimento.
  Use para correções urgentes em produção.
model: sonnet
allowed-tools: Bash(git *) Read Edit Write Bash(cat .env*)

parameters:
  - name: description
    description: Descrição do hotfix
    required: true
  - name: related_tasks
    description: IDs de tasks relacionadas (comma-separated)
    required: false
  - name: tags
    description: Tags adicionais (comma-separated)
    required: false

category: engineer
tags:
  - hotfix
  - emergency
  - gitflow

version: "3.1.0"
updated: "2026-06-13"

related_commands:
  - /git/flow
  - /product/task

related_agents:
  - gitflow-specialist
---

# 🔥 Engineer Hotfix

Emergency workflow completo: Task + Branch + Desenvolvimento, em um comando. **Provider-agnóstico** (Jira, ClickUp, Asana, Linear ou none).

## 🎯 Objetivo

Executar o setup de hotfix end-to-end. Orquestrador fino sobre o **adapter Task Manager**, o **motor GitFlow** (git local) e o **contrato de sessão**.

## ⚡ Fluxo de Execução

### Passo 1: Validar input

```bash
[ -z "{{description}}" ] && { echo "❌ Descrição obrigatória"; exit 1; }
CURRENT=$(git branch --show-current)
[[ "$CURRENT" =~ ^(main|master|develop)$ ]] || echo "⚠️ Recomendado iniciar de main/master"
```

### Passo 2: Criar task emergencial (opcional — provider-agnóstico)

Se `TASK_MANAGER_PROVIDER` != `none`, criar a task via o adapter ([utils/task-manager/factory.md](../../utils/task-manager/factory.md)) — **não** acoplar a provider específico:

```typescript
const tm = getTaskManager();                 // resolve provider do .env
const task = await tm.createTask({
  name: `🔥 HOTFIX: {{description}}`,
  priority: 'urgent',
  tags: ['hotfix', 'urgent', ...'{{tags}}'.split(',').filter(Boolean)],
  markdownDescription: `## 🚨 Emergency Hotfix\n\n**Descrição**: {{description}}\n\n## 📋 Checklist\n- [ ] Diagnóstico\n- [ ] Implementação\n- [ ] Testes\n- [ ] Deploy`
});
await tm.updateStatus(task.id, 'in_progress');
```

Roteamento, formatação (ADF/Markdown/Unicode/HTML) e mapeamento de status/prioridade são responsabilidade do adapter. Em modo offline (`none`), a task é local e o fluxo segue.

### Passo 3: Criar branch hotfix (git local)

Segue [gitflow-patterns.md §Template 4](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-4-emergency-hotfix); o patch bump usa o [Algoritmo Unificado de Semver](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#algoritmo-unificado-de-auto-bump-semver) (hotfix = sempre `patch`):

```bash
git checkout main && git pull origin main
# PATCH = última tag semver + 1 no patch (ver Algoritmo Unificado de Semver)
BRANCH="hotfix/$PATCH-$(echo '{{description}}' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 30)"
git checkout -b "$BRANCH"
```

### Passo 4: Setup de sessão (worklog)

Criar `.claude/sessions/<slug>/` conforme o [Contrato de Sessão](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento): `STATE.md` (índice de resume, com `NEXT`→fase 1), `context.md` (task vinculada, branch, base + Phase-Subtask Mapping), `plan.md` ([DONE]/[ACTIVE]/[TODO]) e `notes.md`. Em hotfix o `architecture.md` é **opcional** (correção urgente pula arquitetura profunda).

### Passo 5: Iniciar desenvolvimento

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔥 HOTFIX INICIADO
∟ Task: <ID/URL no provider ativo, ou "local">
∟ Branch: hotfix/X.Y.Z-description   ∟ Base: main
∟ Sessão: .claude/sessions/<slug>/
⚡ Próximos: implementar → /engineer/pre-pr → /git:flow hotfix finish
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- Motor GitFlow (hotfix, semver): [gitflow-patterns.md §Template 4](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#template-4-emergency-hotfix)
- Task Manager (criação provider-agnóstica): [utils/task-manager/factory.md](../../utils/task-manager/factory.md)
- Contrato de sessão: [gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento)
- Mentor: `@gitflow-specialist`

## ⚠️ Notas

- Sempre parte de `main`/`master`; merge dual (main + develop) no `/git:flow hotfix finish`.
- Task criada com prioridade `urgent` (mapeada pelo adapter ao vocabulário do provider).
