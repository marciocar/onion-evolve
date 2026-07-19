# Claude Code — Internals do Harness

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-06-30 |
| **Harness** | Claude Code (Anthropic) |
| **Tags** | `claude-code`, `filesystem`, `task-system`, `workflow`, `hooks`, `memory` |

---

## 🗂️ Mapa de Armazenamento

O harness usa **dois escopos de armazenamento** com lifecycles diferentes:

```
~/.claude/                              ← persistente (sobrevive reboot)
└── settings.json                       # config global do usuário
└── keybindings.json                    # atalhos customizados
└── image-cache/<session-uuid>/         # imagens coladas no chat
│   └── <n>.png
└── projects/<workdir-codificado>/      # por projeto
    └── memory/                         # memória persistente
    │   ├── MEMORY.md                   # índice (sempre no contexto)
    │   └── *.md                        # arquivos individuais
    └── <session-uuid>/                 # por sessão (dentro do projeto)
        └── subagents/workflows/
            └── wf_<id>/
                └── agent-<id>.jsonl   # journal do workflow (JSONL)

/tmp/claude-<uid>/                      ← efêmero (limpo no reboot)
└── <workdir-codificado>/
    └── <session-uuid>/
        ├── scratchpad/                 # arquivos temporários da sessão
        └── tasks/
            └── <task-id>.output       # stdout de background tasks
```

---

## 🔑 Convenção de Codificação de Paths

O workdir é codificado como chave de namespace:

```
/home/<user>/<project>  →  -home-<user>-<project>
```

**Regra:** toda `/` vira `-`; prefixo `-` no início. Garante unicidade sem criar
subdiretórios aninhados.

**Consequência prática:** ao inspecionar `/tmp/claude-*/` ou `~/.claude/projects/`,
você pode identificar o workdir de qualquer sessão só pelo nome da pasta.

---

## ⚙️ Sistema de Tasks em Background

Quando o harness executa uma task assíncrona (`TaskCreate` / shell em background):

```
/tmp/claude-<uid>/<workdir>/<session-uuid>/tasks/<task-id>.output
```

- **`<task-id>`**: ID curto (~9 chars alfanumérico), ex: `byjz0kaab`
- **`.output`**: pipe de stdout — o processo background escreve aqui
- **Poll pattern:** `sleep N && cat <path>.output` — poll simples enquanto o
  background task ainda processa; o harness notifica quando conclui

**Lifecycle:** efêmero — o arquivo existe só enquanto a sessão está viva. Ao
reboot, o `/tmp` é limpo e os outputs são perdidos.

---

## 📓 Sistema de Workflow Journals

Workflows (`Workflow` tool) têm armazenamento persistente em `~/.claude/`:

```
~/.claude/projects/<workdir>/
└── <session-uuid>/
    └── subagents/workflows/
        └── wf_<run-id>/               # wf_ é o prefixo canônico
            └── agent-<id>.jsonl       # transcript do subagente em JSON Lines
```

**Por que `~/.claude/` e não `/tmp/`?** Para suportar **resume cross-sessão**:
`Workflow({ resumeFromRunId: "wf_..." })` relê os journals e retorna resultados
cacheados dos agentes já completados, sem re-executar. Isso só é possível porque
os journals sobrevivem ao reboot.

**Formato JSONL:** cada linha é um evento de conversação do agente (mensagem,
tool call, resultado). Append-only — o harness pode `tail -5 <path>.jsonl | python3 -c ...`
para checar status sem bloquear o processo que escreve. É assim que `/workflows`
mostra progresso em tempo real ("0/1 agents done").

**Run ID (`wf_<id>`):** é o `resumeFromRunId` usado para retomar. O ID `wf_f9902145-332`
que aparece nos paths é exatamente o parâmetro da ferramenta `Workflow`.

---

## ⚡ Sistema de Hooks

Hooks são shell commands configurados no `settings.json` que o harness executa
deterministicamente em resposta a eventos — **não o modelo, o harness**.

```json
"hooks": {
  "SessionStart": ["bash .claude/hooks/session-start.sh"],
  "PreToolUse":   ["bash .claude/hooks/pre-tool.sh {{tool_name}}"],
  "PostToolUse":  ["bash .claude/hooks/post-tool.sh {{tool_name}}"],
  "Stop":         ["bash .claude/hooks/on-stop.sh"]
}
```

**Implicação crítica:** automações "sempre que X acontecer faça Y" exigem hooks —
não podem ser satisfeitas por memória ou preferências do modelo, pois o modelo não
executa entre turnos. Ex: o "📬 you have mail" no SessionStart é um hook que conta
arquivos em `docs/evolution/inbox/`.

---

## 🧠 Sistema de Memória

A memória do harness opera em **dois níveis de carregamento**:

| Nível | Arquivo | Carregamento | Tamanho |
|-------|---------|-------------|---------|
| Índice | `MEMORY.md` | Sempre (toda sessão) | Limitado a ~200 linhas |
| Detalhes | `*.md` individuais | On-demand (quando relevante) | Sem limite fixo |

**Por que o índice é separado:** o `MEMORY.md` entra no system prompt de toda sessão
— mantê-lo conciso garante que o modelo sempre sabe o que existe sem pagar o custo
de carregar todo o conteúdo. Os arquivos detalhados são lidos quando o modelo julga
necessário.

**Convenção de frontmatter:**
```yaml
---
name: <slug-kebab-case>
description: <uma linha — usada para decidir relevância>
metadata:
  type: user | feedback | project | reference
---
```

---

## 📐 Configuração em Camadas

```
~/.claude/settings.json          # global (usuário) — máxima precedência
<projeto>/.claude/settings.json  # projeto (commitado no repo)
<projeto>/.claude/settings.local.json  # local (não commitado, no .gitignore)
```

Mesclados em cascata: o mais específico sobrescreve o mais geral. Variáveis de
ambiente, permissões de ferramentas, hooks e `TASK_MANAGER_PROVIDER` vivem aqui.

---

## 🖼️ Image Cache

```
~/.claude/image-cache/<session-uuid>/<n>.png
```

Imagens coladas no chat são salvas aqui antes de serem enviadas ao modelo. Persistente
(em `~/.claude/`) porque a sessão precisa poder referenciar a imagem durante toda a
conversa, mesmo após scroll/compact.

---

## 🧭 Resumo do Modelo Mental

| Pergunta | Resposta |
|----------|---------|
| "Onde está o output do background task?" | `/tmp/claude-<uid>/<workdir>/<uuid>/tasks/<id>.output` |
| "Como saber de qual projeto é?" | Decodificar o workdir: `-home-user-projeto` → `/home/user/projeto` |
| "O workflow pode ser retomado?" | Sim — journal em `~/.claude/projects/...` sobrevive reboot |
| "Como ver progresso do workflow?" | `/workflows` — lê os `.jsonl` via tail+parse |
| "Onde ficam as memórias?" | `~/.claude/projects/<workdir>/memory/*.md` |
| "Hooks rodam mesmo sem o modelo?" | Sim — o harness executa, não o modelo |
