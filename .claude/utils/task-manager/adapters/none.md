# ⚪ None Task Manager Adapter (Null Object)

## 🎯 Propósito

Adapter de fallback (**Null Object Pattern**) usado quando nenhum task manager está configurado (`TASK_MANAGER_PROVIDER=none` ou ausência das variáveis obrigatórias do provider). Garante **degradação graciosa**: a decomposição local de tarefas continua funcionando (via `@task-specialist`), mas nada é persistido num provider remoto.

> A implementação concreta (`class NoProviderAdapter implements ITaskManager`) vive em [factory.md](../factory.md) §NoProviderAdapter — mesma convenção do `NoForgeAdapter` da Forge Abstraction. Este documento descreve o **comportamento contratual**.

---

## 🔌 Comportamento por operação

| Operação ITaskManager | Comportamento em modo offline |
|---|---|
| `createTask` / `createSubtask` | Cria task **local** (id `local-<timestamp>`, `url: ''`); avisa em pt-BR ("task LOCAL, não sincronizada") |
| `getTask` / `updateTask` | Avisa e lança `Error('Operação não disponível em modo offline')` (não há de onde ler/onde gravar) |
| `deleteTask` | No-op; retorna `false` |
| `addComment` / `getComments` | No-op / lista vazia com aviso |
| `updateStatus` | No-op com aviso (status local não tem workflow remoto) |
| `searchTasks` | Lista vazia (`[]`) |
| `getProjectList` / `getProject` | Stub local / identidade vazia |
| `validateConfiguration` | Retorna válido para `none` (modo offline é estado legítimo, não erro) |

---

## 🧭 Princípio

A decomposição de tarefas é a fronteira que **nunca** depende de um provider: o `@task-specialist` decompõe localmente sempre. Logo, em modo offline:

- ✅ Decompor requisitos em tasks/subtasks/action items funciona normalmente (sem persistir)
- ❌ Apenas o que exige API do provider (criar/ler/atualizar/buscar no remoto) degrada

Isso evita espalhar `if (provider == null)` pelos comandos — eles chamam `getTaskManager()` uniformemente e o Null Object cuida do caso "sem provider". Diferente do de-identification (que é **fail-safe**: recusa silenciar PII), o task-manager **degrada em silêncio com avisos** — perder sincronização não tem risco de segurança.

---

## 📚 Referências

- [Factory](../factory.md) — implementação `NoProviderAdapter`
- [Interface ITaskManager](../interface.md) — contrato canônico
- [SDAAL — Null Object](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-28
