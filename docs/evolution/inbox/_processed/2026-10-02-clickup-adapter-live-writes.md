---
title: "Adendo 2 ao patch ClickUp: formatos de escrita medidos ao vivo (2 bugs ativos)"
date: 2026-10-02
type: signal
from: brain-granaai (adopted, pin 547e2e3edf3b)
severity: high
relates_to: 2026-10-02-clickup-adapter-update.md
---

# Adendo 2: escrita medida ao vivo (tasks de teste criadas e apagadas)

24 chamadas REST v2 num workspace real; limpeza confirmada (GET final 404). Nós no grafo do adotante
`docs/evolution/research/clickup-api-2026-10/` (`E_LIVE_WRITE_FORMATS` e claims abaixo).

## Bugs ativos no adapter atual (o patch já corrige — conferir)

1. **Prioridade em string quebra:** `priority: "high"` → `400 Priority invalid`. Só inteiro 1–4. Hoje todo
   `createTask`/`updateTask` com prioridade falha (`/engineer:hotfix` usa `urgent`) — `C_ADAPTER_PRIORITY_STRING_BROKEN`.
2. **Tags no body do PUT são ignoradas** (200 sem efeito). Só `POST`/`DELETE /task/{id}/tag/{name}` mudam tags; a
   `under-review` do `/engineer:pr` nunca seria aplicada por `updateTask` — `C_TAGS_NEED_TAG_ENDPOINT`.

## Formatos confirmados

| Campo | Resultado |
|---|---|
| `markdown_content` (create/update) | aplica |
| `markdown_description` no update | **também aplica** (alias aceito) |
| `due_date` / `time_estimate` em ms com `due_date_time=true` | voltam exatos |
| `due_date_time=false` | normalizado para 07:00 e **pode cair no dia anterior** pelo fuso — enviar meio-dia no fuso do workspace (`C_DATE_ONLY_TIMEZONE_SHIFT`) |
| `assignees: {add, rem}` no PUT | funciona; array simples também devolve 200 |
| status inexistente (`review` numa lista sem ele) | `400 Status does not exist` — reforça o adendo 1 (status por List) |
| checklist, item e `PUT .../checklist_item/{iid}` com `resolved` | funcionam |
| `getTask` **sem parâmetro** | já traz `checklists[]` (`id, name, items, resolved, unresolved`; item com `assignee, children, due_date, parent...`) — não depende de `include_subtasks` |
| subtask com `parent` + `include_subtasks=true` | funciona |
| comentário com `comment_text` contendo `**markdown**` | **não vira negrito** (texto literal) — confirma o template Unicode dos comandos |

Não medido: `clickup_delete_task` no MCP oficial (exige servidor MCP conectado).
