---
title: "Adendo ao patch ClickUp: medição ao vivo (subtasks quebradas hoje e status de PR por List)"
date: 2026-10-02
type: signal
from: brain-granaai (adopted, pin 547e2e3edf3b)
severity: high
relates_to: 2026-10-02-clickup-adapter-update.md
---

# Adendo: medição ao vivo contra um workspace real

Com um token válido (só leitura, plano de 100 req/min), medimos as lacunas que o patch deixou abertas. Nós no
grafo do adotante `docs/evolution/research/clickup-api-2026-10/` (`C_GET_TASK_SUBTASKS_LIVE`, `C_PR_STATUS_LIST_SCOPED`).

## 1. Bug ativo no adapter atual: subtasks não aparecem

`GET /api/v2/task/{id}?include_subtasks=true` devolveu **42 subtasks**; o mesmo GET com `subtasks=true` (o que o
adapter atual usa, `clickup.md:58, 198`) devolveu a task **sem** o campo `subtasks`. Ou seja, hoje `getTask` com
subtasks e `getSubtasks` retornam vazio, quebrando `/engineer:start`, `/engineer:work`, `validate-phase-sync` e
`checklist-sync` para qualquer adotante ClickUp. **O patch já usa `include_subtasks`**; pode remover o fallback para
o parâmetro legado, que não funciona.

## 2. Ajuste necessário no patch: status canônico de PR não pode ser fixo

Status no ClickUp são **por List**. A lista medida tem `backlog, in refinement, to do, pause, in progress, testing,
pull request, done, Closed` — **não existe `review`**. Mandar `review` geraria erro ou status inválido.

Proposta: manter `review` como status **canônico** do Onion, mas o adapter resolve contra os `statuses` da List
(`GET /list/{id}`, com cache por sessão) por sinônimos — `review` → `review` | `pull request` | `code review` |
`in review`; `in_progress` → `in progress` | `doing`; `done` → `done` | `complete`; `canceled` → `canceled` |
`cancelled` | `closed` — e, sem correspondência, mantém o status atual e avisa (nunca envia nome inexistente).
O mesmo vale para `normalizeStatus` na leitura (`pull request` → `review`, `testing` → `review` ou `in_progress`,
`in refinement` → `backlog`, `pause` → `blocked`/`in_progress` com `statusRaw`).

## 3. Outras medições

- `due_date` vem como string de milissegundos (confirma conversão ms no adapter).
- Prioridades em uso: `urgent`, `high`, `normal`, `none` (sem prioridade precisa ser tratada).
- Não há custom field "Story Points" nem `points` em uso; o fallback "points nativo como Story Points" do patch
  não tem dado para conferir neste workspace.
- `x-ratelimit-limit: 100` no plano do workspace (confirma `C_RATE_LIMIT_BY_PLAN`).

Ainda não medido (exige escrita ou MCP): `clickup_delete_task` no MCP oficial, formatos de escrita de priority,
tags, assignees no PUT e Edit Checklist Item.
