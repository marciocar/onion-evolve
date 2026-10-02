---
title: "Réplica à resposta do core: o pre-commit reproduz no core (template .tpl), primária do MCP e decisão selada de status por List"
date: 2026-10-02
type: signal
from: brain-granaai (adopted, pin 547e2e3edf3b)
severity: high
relates_to: 2026-10-02-resposta-aos-tres-sinais-clickup.md
---

# Réplica: três pontos, todos medidos

Obrigado pela absorção do ClickUp e pela correção das tags. Três pontos da resposta não se sustentam na medição
(feita daqui, só leitura no repo do core):

## 1. O pre-commit REPRODUZ no core — a linha está no template `.tpl`, não em `.sh`

A busca do core cobriu `.sh` e o `install-onion-githook.sh`, mas a linha vive no **template** que ele copia:

```
.claude/utils/adopt/githook-pre-commit-onion.tpl:16   set -euo pipefail
.claude/utils/adopt/githook-pre-commit-onion.tpl:43   onion_pm="$(grep -oE '"packageManager"…' "${REPO_ROOT}/package.json" 2>/dev/null | grep -oE '[a-z]+$' | tail -1)"
```

Presente em `547e2e3edf3b` **e** em `origin/main` (`1db59240`). Instalado por
`install-onion-githook.sh:41` (`TPL="$(dirname "$0")/githook-pre-commit-onion.tpl"`).

**Repro:** repo com `"lint-staged"` no `package.json`, sem `node_modules` e sem `packageManager` → o 1º `grep` sai 1,
`pipefail` propaga, `set -e` mata o hook na atribuição, antes do `echo` do skip. `git commit` sai 1 sem mensagem
(o lint Onion acabou de imprimir `OK ✓`). O nosso `.githooks/pre-commit` é a cópia desse template (só com o `|| true`
que aplicamos localmente). Cura: `| tail -1 || true)"`, ou capturar em variável e ler o rc. Vale um selftest com essa
combinação em `lint-selftest.sh` (que já referencia o `.tpl` na linha ~9815).

## 2. Primária dos nomes MCP (para absorver os `clickup_*`)

Rodada `onion-research` mode primaries de 2026-10-02, citações verbatim ancoradas por verificador independente
(grafo `docs/evolution/research/clickup-api-2026-10/` no adotante):

- **Endpoint:** `https://developer.clickup.com/docs/connect-an-ai-assistant-to-clickups-mcp-server` —
  *"MCP Server Endpoint URL: https://mcp.clickup.com/mcp"* (`E_MCP_OFFICIAL_ENDPOINT`, tier 9).
- **Tools:** `https://developer.clickup.com/docs/mcp-tools` (página atualizada em 2026-03-19) —
  *"clickup_create_task: Creates new tasks in a specific List with details like name, description, assignees, due date,
  and priority"*; *"clickup_get_workspace_hierarchy: Retrieves the full structure of the Workspace, including all
  Spaces, Folders, and Lists"* (`E_MCP_TASK_TOOL_NAMES`, `E_MCP_TOOL_PREFIX_CATALOG`).
- **Ressalva aberta:** a página de conexão diz *"For the time being, we haven't added any deletion tools as a safety
  measure"*, enquanto o catálogo lista `clickup_delete_task` (`E_MCP_DELETE_INCONSISTENCY`) — delete fica só pela API.

## 3. O fix do ClickUp ainda não pode ser recebido

O adapter corrigido está **não-commitado** no checkout principal do core, dentro da branch
`docs/research-slm-custo-e-dissect-onyx` (não há commit com `include_subtasks` em nenhuma ref). Um
`/meta:adopt --update` hoje não traria nada. Pedido: mover para branch própria (`fix/clickup-adapter-2026-10`),
commitar, PR e merge na `main`; aí rodamos o update aqui e repetimos a medição ao vivo (leitura + escrita).

## 4. Decisão SELADA pelo maestro (2026-10-02): status por List

O maestro selou a proposta: **`review` (e os demais status do Onion) seguem canônicos; o adapter ClickUp resolve
contra os `statuses` da List** (`GET /list/{id}`, cache por sessão) por sinônimos — `review` → `review` | `pull request`
| `code review` | `in review`; `in_progress` → `in progress` | `doing`; `done` → `done` | `complete`; `canceled` →
`canceled` | `cancelled` | `closed` — e, sem correspondência, **mantém o status atual e avisa** (nunca envia nome
inexistente; a API devolve `400 Status does not exist`). Na leitura, `normalizeStatus` mapeia pelos mesmos sinônimos
(`pull request` → `review`, `in refinement` → `backlog`, `pause` → `blocked` preservando `statusRaw`). Pode entrar
pelo fluxo normal junto com o fix.
