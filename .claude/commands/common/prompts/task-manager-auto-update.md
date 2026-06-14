# 🔄 Auto-Update do Task Manager — Mecanismo Compartilhado

> Fragmento canônico do **mecanismo** de auto-update de tasks, reutilizado por
> comandos que sincronizam progresso/resultado com o Task Manager. Citar como
> `common:prompts:task-manager-auto-update`. O **gatilho** (quando atualizar) e o
> **payload** (o que vai no comentário) são específicos de cada comando — este
> fragmento cobre apenas o que é comum.
>
> Pré-requisito: detecção de provedor via `common:prompts:task-manager-provider-detection`.

## Como funciona (via abstração)

O comando atualiza a task no **provedor ativo** através do adapter
([`factory.md`](../../../utils/task-manager/factory.md) → `getTaskManager()`).
Em `none`/offline, **não persistir**: registrar o resultado apenas no contexto
local da sessão (`notes.md` / `context.md`).

```typescript
const taskManager = getTaskManager();          // adapter do provedor ativo
if (!taskManager.isConfigured) {
  // modo offline — registrar localmente, não chamar API
}
```

## 💬 Estratégia DUAL de comentários (quando há subtasks)

Ao registrar progresso de um item com subtasks:

1. **Comentário DETALHADO na SUBTASK** — arquivos, implementações, decisões, métricas.
2. **Comentário RESUMIDO na TASK PRINCIPAL** — referência à subtask + próximo passo.

Sem hierarquia de subtask, registrar um único comentário na task.
Use `updateStatus(taskId, ...)` via adapter quando o evento muda o estado da task.

## 📝 Requisitos de todo comentário

- **Timestamp + status** obrigatórios no rodapé.
- Estrutura visual: cabeçalho + separador + conteúdo + rodapé.

## 🎨 Formatação por provedor (roteamento)

O **conteúdo** é o mesmo; só a **sintaxe** muda conforme o adapter do provedor ativo:

| Provedor | Formato | Quem formata | Adapter / padrões |
|----------|---------|--------------|-------------------|
| `clickup` | Unicode (`━━━`, `∟`, `▶`) | `@clickup-specialist` | `adapters/clickup.md` · `common:prompts:clickup-patterns` |
| `jira` | ADF (Atlassian Document Format) | `@jira-specialist` | `adapters/jira.md` |
| `asana` | HTML/Markdown (story) | `@task-specialist` | `adapters/asana.md` |
| `linear` | Markdown | `@task-specialist` | `adapters/linear.md` |
| `none` | — (local, sem persistir) | — | — |

## 📋 Identificação da Task

1. **`context.md`** da sessão ativa (`.claude/sessions/<slug>/`).
2. **Argumento** explícito (task-id passado pelo usuário).
3. **Branch git** atual (quando aplicável).
4. Não identificada → perguntar ao usuário.

## 🔗 Referências

- Abstração: [`.claude/utils/task-manager/`](../../../utils/task-manager/) (factory · detector)
- Detecção de provedor: `common:prompts:task-manager-provider-detection`
- Formatação ClickUp: `common:prompts:clickup-patterns`
