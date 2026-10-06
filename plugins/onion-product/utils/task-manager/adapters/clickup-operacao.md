# 🔧 ClickUp — Operação (exemplos, bulk, hierarquia, checklists, troubleshooting)

> **Irmão de [`clickup.md`](clickup.md) por *progressive disclosure* (`sdaal.md` §14.5).**
> O adapter guarda o **contrato e a implementação** — o que uma sessão precisa para CHAMAR certo,
> inclusive as armadilhas medidas (campos, formatos, status por List). Este arquivo guarda a
> **operação**: receitas, exemplos trabalhados e diagnóstico.
>
> **Por que o corte existe, e por que ele não é cosmético:** a REGRA 5 (Limites de linhas (por TIPO
> de artefato — tamanho saudável ≠ número universal)) acusou o adapter em 994 linhas contra alvo
> 900, e a §14.5 é explícita em que densidade legítima NÃO justifica fragmentar — o anti-padrão é
> **mistura de responsabilidades**. Era o caso: contrato de API e playbook de operação no mesmo
> arquivo. O corte segue essa fronteira, não o número. As **Notas Operacionais** ficaram no adapter
> de propósito: ali vivem as medições ao vivo, que são contrato, não receita.

## 🧪 Exemplos de Uso

```typescript
// Via Factory (transporte definido pelo .env)
const tm = getTaskManager(); // Retorna ClickUpAdapter se configurado

// Criar task
const task = await tm.createTask({
  name: 'Nova Feature',
  markdownDescription: '## Objetivo\nImplementar funcionalidade X',
  priority: 'high',
  tags: ['feature', 'v2']
});

// Criar subtask
const subtask = await tm.createSubtask(task.id, {
  name: 'Fase 1: Setup'
});

// Atualizar status
await tm.updateStatus(subtask.id, 'in_progress');

// Adicionar comentário com formatação Unicode
await tm.addComment(task.id, [
  '━━━━━━━━━━━━━━━━━━━━━━━',
  '▶ Desenvolvimento iniciado',
  `🕐 ${new Date().toISOString()}`
].join('\n'));
```

---

## ⚡ Operações em Lote (Bulk)

> Detalhe específico do ClickUp. Via abstração, o consumidor usa `createTask`/`createSubtask`; o adapter aplica internamente a regra abaixo.

**Quando usar bulk:** criar múltiplas tasks **independentes no mesmo nível**; atualizar status de várias tasks.

**Limitação crítica — bulk NÃO suporta hierarquia.** O endpoint de criação em lote **ignora** o `parent`. Para hierarquia (task → subtasks), use criação **sequencial** com `parent`:

```javascript
// ❌ ERRADO — parent ignorado no bulk
await create_bulk_tasks({ tasks: [{ name: 'Sub 1', parent: mainId }, { name: 'Sub 2', parent: mainId }] });

// ✅ CORRETO — sequencial preserva hierarquia
const sub1 = await create_task({ name: 'Sub 1', parent: mainId });
const sub2 = await create_task({ name: 'Sub 2', parent: mainId });
```

✅ bulk para: tasks independentes no mesmo nível · ❌ bulk para: hierarquia.

---

## 🏗️ Hierarquia de Tasks (3 níveis)

```
📋 TASK (objetivo de alto nível)
├── 🔧 Subtask 1 (componente)
│   ├── ✅ Checklist item 1.1
│   └── ✅ Checklist item 1.2
└── 🔧 Subtask 2
    └── ✅ Checklist item 2.1
```

**Implementação correta** — transporte default = **REST API** do adapter (`create_task` mapeia para `POST /list/{id}/task`); o `mcp__clickup__*` é apenas o transporte **opcional** via `TASK_MANAGER_TRANSPORT=mcp`:

```javascript
// 1. Task principal
const mainTask = await create_task({
  name: '🎯 Implementar Autenticação JWT',
  listId: '<list_id>',
  markdownDescription: '## 🎯 Objetivo\nImplementar JWT...\n\n## ✅ Critérios\n- [ ] Login retorna JWT\n- [ ] Refresh funciona',
  tags: ['feature', 'security'], priority: 'high'   // domínio: o adapter traduz para markdown_content + priority INTEIRO
});

// 2. Subtasks com parent (← CRITICAL para hierarquia)
const sub1 = await create_task({ name: '🔧 Backend JWT Service', listId: '<list_id>', parent: mainTask.id, tags: ['subtask', 'backend'] });
const sub2 = await create_task({ name: '🔧 Frontend Integration', listId: '<list_id>', parent: mainTask.id, tags: ['subtask', 'frontend'] });

// 3. Comentário de setup (formatação Unicode — ver seção de Formatação)
await create_task_comment({ task_id: mainTask.id, comment_text: '🚀 TASK SETUP COMPLETO\n━━━━━━━━━━━━\n▶ Subtasks: 2\n⏰ ' + new Date().toISOString() });
```

---

## ✅ Checklists Nativos

Checklists nativos do ClickUp (diferentes de checkboxes em markdown) oferecem tracking interativo (resolved/unresolved), progresso visual e leitura via API. O Sistema Onion suporta estrutura híbrida: checkboxes em markdown (documentação) + checklists nativos (tracking).

**Leitura e cálculo de progresso** (incluir `include_subtasks: true` — o legado `subtasks: true` NÃO funciona):

```javascript
const task = await getTask({ task_id: '<id>', include_subtasks: true });

function calculateProgress(task) {
  let total = 0, resolved = 0;
  (task.checklists || []).forEach(c => { total += c.unresolved + c.resolved; resolved += c.resolved; });
  return total > 0 ? (resolved / total * 100).toFixed(1) : 0;
}
// Progresso: `${calculateProgress(task)}%`
```

---

## 🔧 Troubleshooting (ClickUp)

| Problema | Causa | Solução |
|---|---|---|
| Subtasks aparecem como tasks independentes | uso de `create_bulk_tasks` com `parent` | criar sequencial com `create_task({ parent })` (ver Hierarquia) |
| Formatação quebrada em comments | markdown em comentário | usar Unicode visual (`━━━`, `▶`, `∟`); markdown só na descrição (`markdown_content` no request) |
| Auto-update não funciona | `context.md` sem task-id ou mapeamento fase→subtask ausente | validar com `/engineer/validate-phase-sync`; conferir `TASK_MANAGER_PROVIDER` e credenciais |
| **Subtasks** não aparecem | `get_task` com o legado `subtasks: true` (devolve 200 sem o campo) | usar `include_subtasks=true` |
| **Checklists** não aparecem | outra causa — a medição ao vivo registra que `getTask` **sem parâmetro** já traz `checklists[]`; checklist **não depende** de `include_subtasks` | conferir o `taskId` e a permissão do token; juntar as duas coisas nesta linha era erro meu |

---

## 💡 Best Practices (ClickUp)

1. **Hierarquia na ordem certa**: task principal → subtasks com `parent` → comentário de setup.
2. **Formatação por contexto**: descrição em Markdown (`markdown_content` no request); comentários em Unicode visual.
3. **Sempre timestamp + status** em comentários de progresso.
4. **Mapeamento fase→subtask** obrigatório no `context.md` da sessão.
5. **Validar estrutura** após criação (`getTask({ include_subtasks: true })` → conferir `subtasks.length`).

---

---

## 📚 Referências

- Contrato e implementação: [`clickup.md`](clickup.md)
- Abstração agnóstica: [`../interface.md`](../interface.md) · tipos: [`../types.md`](../types.md)
- Padrão-pai: SDAAL
