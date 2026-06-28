# Worklog Protocol — Sessões Retomáveis com Eficácia de IA

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-06-14 |
| **Última Atualização** | 2026-06-14 |
| **Categoria** | Concepts |
| **Aplicação** | Sistema Onion — estado persistente e resumabilidade de workflows faseados |

### Fontes

- [Prompt Caching — Anthropic](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) (jun/2026)
- [Claude Code — Overview](https://docs.claude.com/en/docs/claude-code/overview) (jun/2026)
- KBs irmãs (citadas, não duplicadas): [Context Window Optimization](context-window-optimization.md), [Spec-Driven Development](spec-driven-development.md), [Agent Orchestration](agent-orchestration.md)

---

## 1. Propósito

Este KB define **como** um worklog do Onion extrai o máximo de eficácia da IA: integração com o transcript nativo do Claude Code, protocolo de leitura escalonado, ordenação prompt-cache-friendly, vocabulário de estado determinístico e checkpoint resistente a `/compact`.

A **estrutura** do worklog (quais arquivos, ACTIVE vs ARCHIVED, versionamento) é definida na SSOT: [gitflow-patterns.md §Contrato de Sessão](../frameworks/gitflow-patterns.md#contrato-de-sessão-de-desenvolvimento). Este KB cobre a **mecânica de execução**; a SSOT cobre o **contrato**.

---

## 2. Worklog vs. Transcript — duas camadas complementares

| | **Worklog** (`.claude/sessions/<slug>/`) | **Transcript** (nativo) |
|---|---|---|
| Natureza | Arquivos Markdown | Conversa JSONL (`~/.claude/projects/`) |
| Guarda | Estado **comprometido** (objetivo, plano, decisões, próximo passo) | **Raciocínio** vivo da conversa |
| Sobrevive a `/clear`? | ✅ Sim | ❌ Não |
| Sobrevive a troca de máquina? | ✅ Sim (se versionado) | ❌ Não |
| Resume via | `/engineer/work <slug>` (lê `STATE.md`) | `claude --resume <id>` / `-c` |

**Regra de ouro:** o worklog deve ser **suficiente para resume frio** — um Claude novo, sem nenhum transcript, retoma o trabalho lendo só os arquivos. O transcript é um luxo, nunca uma dependência.

### Fluxo de resume

- **Resume quente** (mesma máquina, transcript vivo): `claude --resume <id>` restaura o raciocínio; depois `/engineer/work <slug>` re-sincroniza o estado de arquivo. Mais rico e barato.
- **Resume frio** (máquina nova / transcript perdido / após `/clear`): `/engineer/work <slug>` sozinho. O `STATE.md` **tem** que bastar.

> ✅ **Hook que fecha o gap:** um slash command não consegue auto-popular o session id, mas um **hook** sim. O framework ships `.claude/hooks/worklog-capture-session.sh` (wired em `.claude/settings.json` no evento `SessionStart`): captura o `session_id` nativo e grava/atualiza o `resume_command` no `STATE.md` do worklog ACTIVE — idempotente, e no-op fora de branch `feature/hotfix/release` ou sem `STATE.md`. Ainda assim, o resume frio **nunca depende** desse campo — é conveniência; os arquivos do worklog bastam.

---

## 3. `STATE.md` — o índice Tier-0

O `STATE.md` é o **único** arquivo que comandos de status (`/engineer/work`, `/onion`, `/engineer/warm-up`) precisam ler para se orientar. Custa ~300 tokens em vez dos ~12–40K de ler a pasta inteira.

Estrutura **prefixo estável → cauda volátil** (ver §5):

```markdown
# STATE — <slug>

<!-- PREFIXO ESTÁVEL (raramente muda; amortizado pelo cache) -->
## Objective
Uma frase: o quê + porquê. (Espelha context.md — não duplica.)

## Constraints
- Invariantes e "não toque em X".

## Map  (carregue só o que a fase precisa)
- architecture.md → §"Data flow" p/ fase 3; §"API" p/ fase 4
- context.md      → background; pular no resume
- plan.md         → ler SÓ o bloco da fase [ACTIVE]
- task-manager    → main: <id> · provider: <jira|clickup|none>

<!-- CAUDA VOLÁTIL (muda a cada fase/checkpoint) -->
## NEXT  ← ponteiro único e autoritativo de resume
phase: 4
phase_title: REST API (Controller + Routes)
status: in_progress
next_action: "Criar wrr.routes.ts ligando WRRController; depois registrar em app.ts"
blocked_by: none
files_in_flight:
  - src/.../wrr.controller.ts (done)
  - src/.../wrr.routes.ts (creating)
validate_with: "npm test -- wrr"
last_checkpoint: 2026-06-14T13:05Z

## Native transcript
resume_command: claude --resume <id>   # conveniência opcional (ver §2)
```

`## NEXT.next_action` é um **imperativo literal**, não um status — um Claude novo lê e age sem reconstruir intenção.

---

## 4. Protocolo de leitura escalonado (Tier 0→3)

Aplica diretamente [Context Window Optimization §Progressive Loading e §Reference Instead of Include](context-window-optimization.md). **Nunca** faça `cat` da pasta (anti-pattern "Context Dump").

```
TIER 0 (sempre, ~1KB):  STATE.md             → o que fazer agora
TIER 1 (sob demanda):   plan.md              → SÓ o bloco da fase [ACTIVE]
TIER 2 (raro):          architecture.md / context.md → só a seção que o Map aponta
TIER 3 (nunca default): histórico de notes.md, fases já [DONE], registros archived/
```

**Regra para `/engineer/work`:** leia `STATE.md`. Pare. Leia só o bloco da fase nomeada em `STATE.md.NEXT`. Abra `architecture.md`/`context.md` apenas se o `## Map` disser que a fase atual precisa.

---

## 5. Ordenação prompt-cache-friendly

Aplica [Context Window Optimization §Prompt Caching](context-window-optimization.md) — "estável → volátil", porque o cache só cobre o prefixo comum e qualquer mudança antecipada o invalida.

- **Dentro do `STATE.md`:** `Objective → Constraints → Map` (estável) primeiro; `## NEXT` e transcript (volátil) no fim. Ao avançar, **só a cauda muda** → o prefixo estável permanece quente em cada turno de `/engineer/work`.
- **Entre arquivos** (ordem de leitura que o comando emite): `CLAUDE.md` (auto) → seção de `architecture.md` (estável) → prefixo de `STATE.md` → `STATE.md.NEXT` (volátil) → bloco da fase atual de `plan.md` → diffs/erros vivos. Nunca leia um arquivo de 40KB **entre** dois blocos estáveis.
- **`notes.md` append-only:** novas notas sempre no fim, nunca editadas no meio (editar a linha 1 de um arquivo de 30KB invalida todo o cache).
- **`plan.md` por chunk:** cada fase é auto-contida (100–300 linhas); ler a fase 4 nunca exige as fases 1–3 em contexto.

---

## 6. Vocabulário de estado determinístico

Três estados, token **ASCII entre colchetes** (grep determinístico; emoji é decoração que não pode bifurcar o significado):

| Token | Era (fragmentação observada) |
|---|---|
| `[DONE]` | `Completada ✅`, `Concluída ✅` |
| `[ACTIVE]` | `Em Progresso ⏰`, `🚀`, `🚧 Em Andamento` |
| `[TODO]` | `Não Iniciada ⏳` |

**Invariantes:**
- Exatamente **uma** fase `[ACTIVE]` por worklog, e ela **é igual** a `STATE.md.NEXT.phase`.
- Se `STATE.md.NEXT` e os badges do `plan.md` divergirem, **`STATE.md` vence** e o comando sinaliza o drift (não escolhe silenciosamente).

---

## 7. Checkpoint & compaction

Amarre as escritas do worklog aos limites de `/compact` para não perder nada na fronteira de compactação.

**Quando fazer checkpoint** (atualizar `STATE.md.NEXT` + append em `notes.md`):
1. **Fim de cada fase** — flip da fase para `[DONE]`, próxima para `[ACTIVE]`, `NEXT` apontando adiante.
2. **Antes de `/compact`** (manual ou auto-compaction iminente) — flush primeiro; depois da compactação, reler só o `STATE.md` (Tier-0) reorienta instantaneamente.
3. **Antes de `/clear` ou fim do bloco de trabalho** — flush do `next_action` para o próximo arranque ser determinístico.

**Drift guard:** no resume, se `STATE.md.last_checkpoint` for mais antigo que a edição mais recente do `plan.md`, avisar "STATE.md pode estar defasado — reconciliar antes de prosseguir".

> ⚠️ **Caveat honesto (confirmado):** a saída de um hook `PreCompact` é **ignorada** pós-compactação — não dá para injetar um lembrete que sobreviva, e **nenhum hook "faz o flush"** (escrever o `STATE.md` com o raciocínio é coisa que só o Claude faz). A **garantia** continua sendo checkpoint em todo limite de fase (determinístico) + o hábito de "checkpoint antes de `/compact`". O que o framework ships é o único side-effect útil possível: `.claude/hooks/worklog-precompact-breadcrumb.sh` (wired no evento `PreCompact`) grava um **breadcrumb datado** no `notes.md` do worklog ACTIVE; na retomada, o drift-guard do `/engineer/work` cruza esse marcador com `STATE.md.last_checkpoint` para alertar se você compactou sem checkpointar.

---

## 8. Enquadramento conceitual

O worklog é uma instância de **Spec-Anchored Development** ([Spec-Driven Development](spec-driven-development.md) §níveis): a spec (objetivo + plano + decisões) é mantida e coevolui com o código — exatamente o loop de checkpoint. Em fases que fazem fan-out (orquestradas pela ferramenta nativa **Workflow**, mai/2026), os workers leem `STATE.md` + um bloco de fase como prefixo cacheável compartilhado com o orquestrador (ver [Agent Orchestration](agent-orchestration.md) §caching em orquestração).

---

## 9. Resumo executável

| Faça | Não faça |
|---|---|
| Ler `STATE.md` primeiro, sempre | `cat` da pasta de sessão |
| `STATE.md.NEXT` como verdade de resume | Confiar nos badges do `plan.md` para decidir o próximo passo |
| Tokens `[DONE]/[ACTIVE]/[TODO]` | Emoji solto (`✅`/`🚀`) como estado de máquina |
| Checkpoint em todo fim de fase e antes de `/compact` | Assumir que o transcript sobrevive |
| Worklog suficiente para resume frio | Depender de `resume_command` auto-populado |
