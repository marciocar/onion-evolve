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

## 🎨 Formatação por provedor (responsabilidade do adapter)

O comando passa o **conteúdo** agnóstico para `taskManager.addComment(...)`; **o adapter do provedor ativo resolve a sintaxe** (e, internamente, pode acionar o especialista do provider quando a API exige). O comando **não** escolhe formato nem especialista — só chama o método agnóstico. Para referência, o formato de cada adapter:

| Provedor | Formato (resolvido pelo adapter) | Adapter |
|----------|----------------------------------|---------|
| `clickup` | Unicode (`━━━`, `∟`, `▶`) | `adapters/clickup.md` · `common:prompts:clickup-patterns` |
| `jira` | ADF (Atlassian Document Format) | `adapters/jira.md` |
| `asana` | HTML/Markdown (story) | `adapters/asana.md` |
| `linear` | Markdown | `adapters/linear.md` |
| `none` | — (local, sem persistir) | — |

## 📋 Identificação da Task

1. **`context.md`** da sessão ativa (`.claude/sessions/<slug>/`).
2. **Argumento** explícito (task-id passado pelo usuário).
3. **Branch git** atual (quando aplicável).
4. Não identificada → perguntar ao usuário.

## 🔁 Pontos de auto-update no ciclo (agnóstico)

Os eventos do ciclo de engenharia disparam o mecanismo via adapter (transporte default = REST API; MCP opcional). O **padrão** é idêntico para qualquer provider — só os métodos agnósticos abaixo:

| Evento | Ação (agnóstica via adapter) |
|--------|------------------------------|
| `/engineer:start` | `getTask(id, {subtasks:true})` → `updateStatus(id,'in_progress')` → `addComment(id, '🚀 …')` → criar mapeamento fase→subtask no `context.md` |
| `/engineer:work` (fim de fase) | `updateStatus(subtaskId,'done')` → `addComment(mainTaskId, '🔧 progresso …')` → atualizar `plan.md` |
| `/engineer:pr` | `updateStatus(id,'in_progress')` + tag `under-review` → `addComment(id, '🚀 PR …')` |
| `/git:sync` (pós-merge) | `updateStatus(id,'done')` → `addComment(id, '✅ concluída/merged …')` |

> Exemplos de transporte específico (ClickUp/Jira/etc.) vivem no respectivo adapter — ex.: `adapters/clickup.md` (Hierarquia, Checklists, formatação Unicode). O comando **nunca** chama o MCP/SDK do provider direto.

## 🔗 Referências

- Abstração: [`.claude/utils/task-manager/`](../../../utils/task-manager/) (factory · detector)
- Detecção de provedor: `common:prompts:task-manager-provider-detection`
- Formatação/transporte por provider: o adapter ativo (ex.: `adapters/clickup.md` · `common:prompts:clickup-patterns`)
