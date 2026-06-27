# 🔄 Sincronizar o inventário após criar artefato — Passo Final Compartilhado

> Fragmento canônico do **passo pós-criação** reutilizado pelos comandos `/meta:create-*`
> que criam um artefato **contado pela SSOT** (command, agent, skill, knowledge base).
> Citar como `common:prompts:inventory-sync-after-create`.
>
> **Por que existe:** o inventário (`docs/onion/inventory.md`) é a SSOT gerada do filesystem,
> e a **Regra 8 do lint (`check_inventory_sync`) é HARD** — bloqueia o merge se a SSOT
> divergir do filesystem. Sem este passo, **criar um artefato deixa o repo em HARD-fail
> SILENCIOSO** até alguém rodar `/meta:inventory` à mão (o autor não vê o problema; o CI
> pega só no PR). Acoplar "criar" a "sincronizar" fecha esse buraco — mesmo espírito do
> `entrega-sem-commit` do co-deliver: o ato determinístico carrega sua consequência explícita.

## Passo final (obrigatório quando o artefato é contado pela SSOT)

Após gravar o novo command/agent/skill/KB, **regenere a SSOT e propague as contagens**:

```bash
bash .claude/validation/inventory.sh --markdown > docs/onion/inventory.md
bash .claude/validation/lint-artifacts.sh --fix      # propaga as contagens canônicas (Regra 16)
bash .claude/validation/lint-artifacts.sh            # confirma 0 HARD / 0 SOFT
```

Ou, equivalente e canônico: rodar **`/meta:inventory`** (faz exatamente os 3 passos acima).

> **Escopo:** só vale para artefatos que a SSOT conta — `command`, `agent`, `skill`,
> `knowledge base`. `create-abstraction` (gera em `.claude/utils/`, não contado) e
> `create-task-structure` (tasks de produto, não artefato Onion) **não** disparam este passo.
>
> **Não substitui a Regra 8** (rede de CI): este passo é conveniência no fluxo de criação;
> o gate HARD permanece como segurança no PR.
