---
name: sync
description: |
  Sincronização automática de branches com GitFlow e proteção de branches críticas.
  Use após merge de PRs para manter branches atualizadas.
model: sonnet
allowed-tools: Bash(git *) Read Bash(cat .env*)

parameters:
  - name: branch
    description: 'Branch alvo para sincronização (default: develop)'
    required: false
    default: develop

category: git
tags:
  - sync
  - gitflow
  - branch-protection

version: "3.1.0"
updated: "2026-06-13"

related_commands:
  - /engineer/pr
  - /git/flow

related_agents:
  - gitflow-specialist
---

# 🔄 Git Sync - Sincronização com GitFlow

Sincronização pós-merge de branches com proteção automática. Orquestrador fino sobre o **motor GitFlow** (git local).

## 🎯 Objetivo

Automatizar a sincronização após merge de PRs, respeitando a proteção de branches.

## ⚡ Fluxo de Execução

Segue a [Matriz de Branches Protegidas e Estratégia de Sync](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#matriz-de-branches-protegidas-e-estratégia-de-sync) — **fonte única** da proteção e da estratégia por contexto.

1. **Detectar contexto** — `CURRENT=$(git branch --show-current)`, `TARGET=${branch:-develop}`.
2. **Validar estado** — abortar se houver mudanças não commitadas; `git fetch origin --prune`.
3. **Aplicar estratégia** (da matriz da KB): `feature/* → develop` (merge normal), branch protegida (`main`/`master`/`develop`) → **fast-forward apenas**; se FF falhar, instruir `/engineer/pr` (nunca forçar).
4. **Cleanup** — se a feature já foi merged no remote, oferecer deletar a branch local.
5. **Task Manager (opcional)** — se `TASK_MANAGER_PROVIDER` != `none`, registrar o sync via o adapter ([utils/task-manager/factory.md](../../utils/task-manager/factory.md)). Roteamento por provider é do adapter — **não reimplementar aqui**.

## 📤 Output Esperado

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SYNC CONCLUÍDO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
∟ Branch atual: feature/user-auth   ∟ Sincronizado com: develop
∟ Commits atualizados: 5            ∟ Conflitos: 0
🚀 Próximo: /engineer/work
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Em branch protegida sem FF possível, reportar bloqueio e o workflow correto (`/engineer/pr` → merge via host → `/git/sync develop`). Em conflito, listar arquivos e instruir resolução manual + nova execução.

## 🔗 Referências

- Proteção e estratégia: [gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md#matriz-de-branches-protegidas-e-estratégia-de-sync)
- Sync de task: [utils/task-manager/factory.md](../../utils/task-manager/factory.md)
- Mentor (conflitos, troubleshooting): `@gitflow-specialist`
