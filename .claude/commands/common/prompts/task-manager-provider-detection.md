# 🚨 Detecção de Provedor — Task Manager (PASSO 0 OBRIGATÓRIO)

> Fragmento canônico de detecção de provedor reutilizado por comandos que operam
> com tasks. Citar como `common:prompts:task-manager-provider-detection`.
> A lógica de detecção/parsing vive no adapter: [`.claude/utils/task-manager/detector.md`](../../../utils/task-manager/detector.md).

**⚠️ CRÍTICO — EXECUTAR ANTES DE QUALQUER OUTRA AÇÃO. NUNCA assumir o provedor.**

1. **Ler `.env`** (`Read .env`) e extrair `TASK_MANAGER_PROVIDER`
   (valores: `jira` | `clickup` | `asana` | `linear` | `none`).
2. **Validar a variável obrigatória do provedor ativo:**

   | Provedor | Variável obrigatória | Adapter (transporte: REST API default; MCP opcional) |
   |----------|----------------------|----------------------------|
   | `jira` | `JIRA_HOST`, `JIRA_EMAIL`, `JIRA_API_TOKEN` | `.claude/utils/task-manager/adapters/jira.md` |
   | `clickup` | `CLICKUP_API_TOKEN` | `.claude/utils/task-manager/adapters/clickup.md` |
   | `asana` | `ASANA_ACCESS_TOKEN` | `.claude/utils/task-manager/adapters/asana.md` |
   | `linear` | `LINEAR_API_KEY` | `.claude/utils/task-manager/adapters/linear.md` |
   | `none` / ausente | — | modo offline (sessões locais em `.claude/sessions/`) |

3. **(Quando o comando recebe um `task-id`)** Validar compatibilidade do task-id
   com o provedor ativo via `detectProviderFromTaskId` / `validateProviderMatch` —
   se houver incompatibilidade, avisar o usuário antes de prosseguir.
4. **Fallback gracioso:** se a variável obrigatória faltar, avisar em pt-BR qual
   variável está ausente, sugerir `/meta:setup-integration` e seguir em **modo offline**
   (usar apenas o contexto local da sessão, sem chamadas de API). Não inventar
   valores nem assumir outro provedor.

> Detalhes de detecção, parsing do `.env` e validação de ID:
> [`.claude/utils/task-manager/detector.md`](../../../utils/task-manager/detector.md).
