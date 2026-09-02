# Pesquisa externa — Claude Code / Agent SDK em torno do Fable 5.1

> Pesquisa de plataforma (não de doutrina Onion). Hoje é 2026-09-02. Local: Claude Code 2.1.257 instalado. Todo item tem fonte (URL ou comando+saída); o que não foi encontrado está marcado como tal.

## Changelog 2.1.250 → latest (2.1.258)

Fonte: WebFetch `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` (2026-09-02).

### v2.1.258 (topo do changelog — última no momento da coleta)
- "Fixed Claude Code failing to launch on macOS 12 (Monterey), a regression introduced in 2.1.255"
- "Fixed remote and scheduled sessions failing with 'user messages must have non-empty content' after a re-sent permission approval could not be applied"

Sem outras entradas relevantes a modelo/hooks/subagentes nesta versão.

### v2.1.257 — a versão instalada localmente, e a que introduz o Fable 5.1
- **Modelo**: "Added Claude Fable 5.1 (`claude-fable-5-1`), now the default Fable model — 1M context, $10/$50 per Mtok with $0.25/Mtok cache reads"
- **Subagentes/força de modelo**: "Added `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` to apply `CLAUDE_CODE_SUBAGENT_MODEL` (or the main model) to every subagent, ignoring per-spawn and agent-definition model overrides" — **requer 2.1.257+** (confirmado também na doc de sub-agents).
- **Effort**: "Added `s` in `/effort` to change effort for the current session only, matching `/model`"
- **Effort — mudança de semântica**: "Changed `--effort` to lift a new model's default-effort hold for that session only rather than permanently; an effort picked on claude.ai for a Remote Control session now applies during the hold"
- **Gateway/model discovery**: "Added support for a gateway-supplied `description` on discovered `/model` picker entries (`CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY`)"
- **Compat de gateway com o 5.1**: "Changed `fable` and `best` in Claude apps gateway sessions to keep resolving to Fable 5 for now, since gateways not yet configured for Fable 5.1 reject it; pick Fable 5.1 in `/model` to use it" — **implicação prática**: um gateway corporativo pode servir Fable 5 mesmo pedindo o alias `fable`/`best`; para garantir 5.1 é preciso nomear o modelo explicitamente.
- **Hooks — settings dinâmicos**: "Fixed settings in a `.claude/` folder created after startup not being picked up until restart"
- **Hooks/hidden thinking (Bedrock)**: "Fixed Bedrock and Bedrock Mantle requests going silent during long hidden-thinking phases on Opus 4.7 and later... the stream now carries progress events"
- **Subagentes — token counter**: "Fixed the token counter freezing or crawling after switching to another subagent's transcript, and made background subagents' and teammates' counters update live"
- **Subagentes — continuidade**: "Fixed subagents stopping when a response was cut off mid-stream by a computer sleep, dropped connection, or server error; they now automatically continue instead of ending with an incomplete response"
- **Sessões background**: várias correções (macOS self-update, Windows daemon lock, listagem em `claude agents`, `claude --bg` reportando erro corretamente).
- **Plugins — segurança**: "Fixed plugins being able to read files outside their own directory through a declared command, agent, skill, hooks or other component path that is a symlink; such paths are now refused with an error" — relevante para o `onion-publish`/marketplace do core.
- **Bash guard**: "Fixed Bash `Read()`/`Edit()` deny rules not applying to `< file` redirects and reader commands like `tac` and `egrep`; a deny rule on any argument or redirect target now refuses the command"
- **Worktree**: "Fixed worktree-isolated sessions refusing Bash loops, `$VAR` reads, `\"$(…)\"` and heredocs that never touch git as 'too complex to verify that it stays inside the worktree'"
- **/model e /effort**: "Fixed `/model` and `/effort` showing a prompt-cache warning after rewinding a conversation back to empty"
- **VSCode**: novo model pill com Effort row no rodapé; output style selector no menu de comandos.

### v2.1.252
- Só correções de bugs (background tasks, Bash task-output swap, "always allow" sem `.claude/settings.local.json`, notificações grandes de background task).

### v2.1.251
- **Hooks novos**: "Added `PreModelSwitch` and `PostModelSwitch` hook events (block, confirm, or annotate a model switch); `SessionStart` resume hooks now receive session staleness and the estimated re-cache cost"
- **Subagentes — streaming**: "Added live streaming of a foreground subagent's tool calls and results to Remote Control clients (background subagents, the default, still show status only)"
- **Effort — bug de compatibilidade**: "Fixed Opus 5 requests failing with 'effort … is not supported when thinking is disabled' when effort was xhigh/max and thinking was turned off; effort is now sent as `high` in that case"
- **Agent teams**: "Fixed agent teams: a teammate's final answer not reaching the team lead — it now arrives in the idle notification instead of a content-free 'available' notice"; "Fixed background subagents being unable to reply to a message from an unnamed sibling or parent agent (`from` was the agent type, which is not an address)"
- **Subagentes — resolução de modelo (MUDANÇA DE COMPORTAMENTO IMPORTANTE)**: "Changed `CLAUDE_CODE_SUBAGENT_MODEL` to set the default subagent model rather than override everything: an agent definition's `model:` and an explicit per-spawn model now take precedence over it" — antes desta versão `CLAUDE_CODE_SUBAGENT_MODEL` tinha prioridade MÁXIMA (sobrepunha até `model: inherit`); agora é o piso, não o teto. Isso é relevante para qualquer tiering do Onion que dependa dessa env var.
- **Contexto/cache**: "Fixed a 'switch to Opus 1M for 5x more context' tip that appeared even when the current Opus model already has a 1M context window"
- **Commits**: "Changed the default commit trailer to `Co-Authored-By: Claude Code` when the active model isn't a recognized Claude model"
- **Plano padrão**: "Changed the default model for seat-based Enterprise subscriptions to Opus 5, matching other premium plans"
- **Effort persistente por modelo**: "Changed `/effort` to save your default effort level per model, so each model keeps its own setting when you switch"

### v2.1.250
- "Bug fixes and reliability improvements" — sem detalhamento no changelog.

## Instalação local medida

Comando: `claude --version` → `2.1.257 (Claude Code)`.

`claude --help` (trechos relevantes, verbatim):
- `--model <model>`: "Model for the current session. Provide an alias for the latest model (e.g. 'fable', 'opus', or 'sonnet') or a model's full name (e.g. 'claude-fable-5')." — o texto de ajuda ainda cita `claude-fable-5` como exemplo, não `claude-fable-5-1` (o help embutido não foi atualizado com o novo ID, mas o modelo está disponível — ver settings.json real abaixo).
- `--effort <level>`: "Effort level for the current session (low, medium, high, xhigh, max)" — bate com a doc oficial.
- `--permission-mode <mode>`: choices "acceptEdits", "auto", "bypassPermissions", "manual", "dontAsk", "plan".
- Comandos relacionados a background/agentes: `agents`, `attach <id>`, `logs <id>`, `respawn`, `rm <id>`, `stop|kill <id>`, `ultrareview`.
- `--restricted`: modo que remove Bash/PowerShell/REPL e WebFetch por padrão, ignora settings de projeto, confina file tools aos diretórios de trabalho.
- `--safe-mode`: desliga TODAS as customizações (CLAUDE.md, skills, plugins, hooks, MCP, comandos/agentes custom, output styles, workflows) — settings admin-managed continuam valendo.

`~/.claude/settings.json` local (chaves relevantes, valores sensíveis já redigidos por mim antes de imprimir):
```
"model": "opus[1m]"
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1", "CLAUDE_CODE_ENABLE_TODO_TOOLS": "1" }
"worktree": { "baseRef": "fresh" }
"workflowKeywordTriggerEnabled": false
"teammateMode": "auto"
"crossSessionInbound": "accept"
```
- Ou seja: **Agent Teams está ligado nesta instância** (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), o `teammateMode` é `"auto"` (default oficial é `"in-process"` desde 2.1.179 — este ambiente está usando um valor não-default). O modelo default de sessão está fixado em `opus[1m]`, não em `fable`/`best`.
- `claude config list` (sem subcomando) não lista aliases/effort reconhecidos — devolve só a tabela de arquivos de config (projeto/usuário) e pede para eu nomear o alvo. **NÃO ENCONTRADO** via este comando: não há uma forma de `config list` enumerar aliases de modelo ou níveis de effort reconhecidos pela instalação local; essa informação vem só da doc oficial (abaixo) e do `--help`.
- `ls ~/.claude/` confirma diretórios `teams/`, `tasks/`, `jobs/`, `daemon*`, `session-env/` — consistentes com Agent Teams + background sessions ativos nesta máquina.

## Docs oficiais (code.claude.com/docs — docs.anthropic.com redireciona 301 para lá)

### Model config — `https://code.claude.com/docs/en/model-config`
- **Prioridade de configuração de modelo**: `/model` (sessão) > `--model` (startup) > `ANTHROPIC_MODEL` (env) > `model` em settings > `ANTHROPIC_DEFAULT_MODEL` (default de novas sessões).
- **Aliases**: `default` (limpa override), `best` ("Latest Fable model where available, otherwise same as `opus`"), `fable` ("Latest Fable model for hardest and longest-running tasks"), `sonnet`, `opus`, `haiku`, `sonnet[1m]`, `opus[1m]`, `opusplan` (opus no plan mode, sonnet na execução).
- **Resolução de alias por provider**: na Anthropic API, `opus`→Opus 5, `sonnet`→Sonnet 5. No Claude Platform on AWS, `sonnet`→Sonnet 4.6. No Bedrock/Vertex, `sonnet`→Sonnet 4.5. No Microsoft Foundry, `opus`→Opus 4.6, `sonnet`→Sonnet 4.5. **Implicação**: o alias `fable`/`best` não é garantido igual em todo provider — cada ambiente tem que ser verificado.
- **Effort — níveis disponíveis por modelo**:
  - Fable 5.1 e Fable 5: `low, medium, high, xhigh, max`
  - Opus 5, Sonnet 5, Opus 4.8, Opus 4.7: `low, medium, high, xhigh, max`
  - Opus 4.6 e Sonnet 4.6: `low, medium, high, max` (sem `xhigh`)
- **Fallback de effort**: "If you set a level the active model does not support, Claude Code falls back to the highest supported level at or below the one you set. For example, `xhigh` runs as `high` on Opus 4.6."
- **Persistência de effort**: salvo por sessão interativa em `modelSettings` (settings do usuário), por modelo — cada modelo mantém seu próprio nível salvo.
- **`max`**: nível mais profundo; a menos que setado via env `CLAUDE_CODE_EFFORT_LEVEL`, `max` só se aplica à sessão atual (não persiste).
- **`ultracode`**: "Claude Code setting: `xhigh` effort + dynamic workflows" — nível especial citado na tabela de uso, distinto dos 5 níveis-base.
- **Contexto 1M**: Fable 5.1, Fable 5, Sonnet 5, Opus 4.6+ e Sonnet 4.6 suportam 1M tokens. Sonnet 5 na Anthropic API SEMPRE roda com 1M (não há variante 200K, sem sufixo `[1m]`, sem usage credits). Auto-compact em ~967K tokens por padrão, ajustável via `CLAUDE_CODE_AUTO_COMPACT_WINDOW`. Desligar 1M globalmente: `CLAUDE_CODE_DISABLE_1M_CONTEXT=1`.
- **Default por tipo de conta**: Max/Team Premium/Enterprise/API → Opus 5 default; Pro/Team Standard → Sonnet 5 default; Microsoft Foundry → Sonnet 4.5.

### Sub-agents — `https://code.claude.com/docs/en/sub-agents`
- **Campo `model` no frontmatter**: aceita alias (`sonnet`, `opus`, `haiku`, `fable`), full model ID (`claude-opus-5`, `claude-sonnet-5` — mesmos valores que `--model`), ou `inherit` (usa o modelo da conversa principal).
- **Ordem de resolução (atual, pós-2.1.251)**:
  1. Parâmetro `model` por invocação
  2. `model` no frontmatter da definição do subagente (`inherit` → modelo da conversa principal)
  3. `CLAUDE_CODE_SUBAGENT_MODEL` (env), quando setado para um alias/ID (não `inherit`)
  4. Modelo da conversa principal
  - Nota explícita: "Before v2.1.251, `CLAUDE_CODE_SUBAGENT_MODEL` came first in this order and overrode both the per-invocation parameter and the frontmatter, including `model: inherit`."
- **`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`**: ignora toda a ordem acima — força TODOS os subagentes, teammates e workflow agents (inclusive os built-in Explore/Plan) a rodar em `CLAUDE_CODE_SUBAGENT_MODEL`. Exceção: um `fork` e uma skill rodando em subagente com `model: inherit` continuam no modelo da conversa principal. **Requer Claude Code v2.1.257+** — ou seja, só existe na versão que já está instalada localmente.
- **Campo `effort` por subagente** (frontmatter, separado de `model`): "Overrides the session effort level. Default: inherits from session. Options: `low, medium, high, xhigh, max`; available levels depend on the model."
- **Verificação em runtime**: `/tasks` mostra o modelo (e o effort, se setado) de cada subagente na sua linha.

### Hooks — `https://code.claude.com/docs/en/hooks`
Lista completa de eventos documentados (nome — descrição verbatim):
- `SessionStart` — "When a session begins or resumes"
- `Setup` — "When you start Claude Code with `--init-only`, or with `--init` or `--maintenance` in `-p` mode"
- `UserPromptSubmit` — "When you submit a prompt, before Claude processes it"
- `UserPromptExpansion` — "When a user-typed command expands into a prompt, before it reaches Claude. Can block the expansion"
- `PreToolUse` — "Before a tool call executes. Can block it"
- `PermissionRequest` — "When a tool call needs a permission decision"
- `PermissionDenied` — "When auto mode denies a tool call, including denials without a classifier verdict"
- `PostToolUse` — "After a tool call succeeds"
- `PostToolUseFailure` — "After a tool call fails"
- `PostToolBatch` — "After a full batch of parallel tool calls resolves, before the next model call"
- `Notification` — "When Claude Code sends a notification"
- `MessageDisplay` — "While assistant message text is displayed"
- `SubagentStart` / `SubagentStop`
- `TaskCreated` / `TaskCompleted`
- `Stop` — "When Claude finishes responding" (bloqueante, sem matcher)
- `StopFailure` — "When the turn ends due to an API error"
- `TeammateIdle` — "When an agent team teammate is about to go idle"
- `InstructionsLoaded` — "When a CLAUDE.md or `.claude/rules/*.md` file is loaded into context. Fires at session start and when files are lazily loaded during a session"
- `ConfigChange`, `CwdChanged`, `DirectoryAdded`, `FileChanged`
- `WorktreeCreate` / `WorktreeRemove`
- `PreCompact` / `PostCompact`
- **`PreModelSwitch`** — "Before Claude Code applies a model switch that you or a client requested. Can block the switch." Matcher avalia o **nome canônico do modelo de destino** (ex.: `claude-opus-5`, `.*opus.*`). Input JSON traz `from_model` e `to_model`. Timeout default rebaixado para 30s (vs 600s geral).
- **`PostModelSwitch`** — "After the session's model changes, including changes Claude Code makes on its own, such as restoring the model when you resume a session." Assíncrono, mesmos campos `from_model`/`to_model`, timeout 30s.
- `Elicitation` / `ElicitationResult`
- `SessionEnd`

Campos comuns a todos os eventos (JSON de input): `session_id`, `prompt_id`, `transcript_path`, `cwd`, `permission_mode`, **`effort: { "level": "low|medium|high|xhigh|max" }`**, `hook_event_name`, `agent_id`, `agent_type`.

### Agent teams — `https://code.claude.com/docs/en/agent-teams`
- Feature experimental, desligada por padrão; liga com `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` — **e esta instância local JÁ TEM isso ligado** (visto no `~/.claude/settings.json`).
- **Resolução de modelo por teammate** (ordem):
  1. Modelo nomeado no prompt de spawn
  2. `model` da definição de subagente usada para o teammate (`inherit` → modelo do lead)
  3. `CLAUDE_CODE_SUBAGENT_MODEL` (quando ≠ `inherit`)
  4. Modelo atual do lead
  - `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` também se aplica a teammates, igual a subagentes.
  - Nota: "Before v2.1.251, `CLAUDE_CODE_SUBAGENT_MODEL` came first in this order" (mesma mudança já registrada acima).
  - `teammateDefaultModel` foi REMOVIDO em v2.1.234; valor legado é ignorado — nomear o modelo no prompt é o caminho agora.
  - Teammates herdam o **effort level da sessão do lead**; em modo split-pane isso só passou a valer a partir de v2.1.186.
  - Allowlist `availableModels` da organização pode substituir o modelo escolhido para um teammate — mecanismo de fallback documentado (family alias → versão mais nova permitida; qualquer outro valor bloqueado → cai no modelo do lead).
- **Uso de definições de subagente como teammates**: reutiliza `tools`, `model` e o corpo (system prompt) da definição; **`skills` da definição é IGNORADO** para teammates (carregam skills do projeto/usuário, não da definição do subagente) — ponto potencialmente relevante para agentes Onion pensados como teammate role.
- **Hooks de qualidade para times**: `TeammateIdle` (exit 2 = manda feedback e mantém trabalhando), `TaskCreated`, `TaskCompleted` (exit 2 em ambos bloqueia e devolve feedback).
- **Cache de prompt de teammate in-process**: cai fora do bucket TTL da conversa principal — cache de 5 min por padrão (mesmo em plano de assinatura); para manter 1h, setar `subagentPromptCacheTtl: "1h"` (billing de cache-write de 1h é mais caro na API).
- **Limitações documentadas**: sem resumo de sessão para teammates in-process (`/resume`/`/rewind` não os restaura), status de task pode atrasar, shutdown pode ser lento, 1 time por sessão, sem times aninhados, sem subagentes background disparados por teammate in-process, lead é fixo (não promovível), permissões fixadas no spawn (mudáveis depois, não no spawn).

### Settings reference — `https://code.claude.com/docs/en/settings-reference`
Chaves confirmadas (a WebFetch não trouxe o texto completo de cada uma, só a tabela-índice; verbatim das descrições curtas):
- `model` — "Change the model Claude Code starts with"
- `effortLevel` — "Set a default effort level for models without a saved level of their own"
- `modelSettings` — "Keep a saved effort level per model, which Claude Code writes when you run `/effort`" (confirma o formato `{"modelSettings": {"claude-opus-5": {"effortLevel": "max"}}}` visto na doc de model-config)
- `agent` — "Start every session as a named subagent with its prompt, tools, and model"
- `subagentPromptCacheTtl` — "Choose the prompt cache lifetime for subagents and other requests outside the main conversation"
- `subagentStatusLine` — "Rewrite rows in the subagent task display with your own command"
- `permissions.defaultMode` — "Set the permission mode new sessions start in" (valores confirmados via `--help`, não via esta página: `acceptEdits`, `auto`, `bypassPermissions`, `manual`, `dontAsk`, `plan`)
- **NÃO ENCONTRADO nesta página** (o WebFetch trouxe só a tabela-índice, truncada): texto completo de `CLAUDE_CODE_SUBAGENT_MODEL`/`CLAUDE_CODE_SUBAGENT_MODEL_FORCE` — essas duas env vars estão documentadas nas páginas de sub-agents e model-config (linkadas acima), não nesta.

## SDK (`@anthropic-ai/claude-agent-sdk`)

Fonte: WebFetch `https://registry.npmjs.org/@anthropic-ai/claude-agent-sdk` (2026-09-02).
- `dist-tags.latest` = **0.3.258** (também é o `next`).
- **NÃO ENCONTRADO**: a data de publicação exata de 0.3.258 — o WebFetch (resumidor) truncou o campo `time` do JSON antes de chegar a essa entrada (só devolveu timestamps de versões 0.1.4x, de novembro de 2024, claramente desatualizados/não representativos da versão atual). O registry real tem o dado; a ferramenta de fetch não conseguiu trazê-lo por causa do tamanho do JSON. Para obter a data exata seria preciso `curl` direto ou `npm view @anthropic-ai/claude-agent-sdk time` — não executado nesta pesquisa (mandato restringia a WebFetch/leitura local, sem acesso a registry via npm CLI verificado aqui).
- Não foi possível extrair o changelog específico de mudanças multi-agente do SDK 0.3.258 a partir do registry (o registry não traz release notes, só metadados de versão). **NÃO ENCONTRADO**: changelog textual do Agent SDK — precisaria de outra fonte (ex. GitHub releases do SDK, não consultado nesta rodada).

## Lacunas declaradas

1. **Data de publicação exata do Agent SDK 0.3.258**: não obtida (ver acima) — só sei que é a `latest`/`next` no momento da coleta (2026-09-02).
2. **Changelog textual do Agent SDK** (o que mudou para orquestração multi-agente entre versões 0.1.x e 0.3.258): não encontrado nesta rodada — o registry npm não carrega release notes.
3. **Texto completo e verbatim de `CLAUDE_CODE_SUBAGENT_MODEL` / `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` na página settings-reference**: só temos a versão documentada nas páginas sub-agents/model-config (que é completa e citada acima); a settings-reference em si só devolveu a tabela-índice truncada.
2.1. **Valores válidos completos de `permissions.defaultMode`** confirmados via doc oficial (a settings-reference não listou; o `--help` local listou 6 valores — usados como fonte).
3. **`claude config list` local**: não enumera aliases de modelo/effort reconhecidos pela instalação — não há comando local que sirva essa informação diretamente; toda a superfície de aliases veio da doc oficial, não de introspecção local.
4. **CHANGELOG anterior a 2.1.250**: fora do escopo do mandato, não coletado.

## Fontes

- https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md (versões 2.1.250–2.1.258)
- Comando local: `claude --version` → `2.1.257 (Claude Code)`
- Comando local: `claude --help` (saída completa lida)
- Comando local: `cat ~/.claude/settings.json` (segredos redigidos antes de imprimir — não havia nenhum campo de token/senha no arquivo, na verdade; só config funcional)
- Comando local: `ls -la ~/.claude/`
- Comando local: `claude config list` (sem subcomando → menu de escopos, não introspecção de modelo/effort)
- https://code.claude.com/docs/en/model-config (redirecionado de docs.anthropic.com/en/docs/claude-code/model-config)
- https://code.claude.com/docs/en/sub-agents (redirecionado de docs.anthropic.com/en/docs/claude-code/sub-agents)
- https://code.claude.com/docs/en/hooks (redirecionado de docs.anthropic.com/en/docs/claude-code/hooks)
- https://code.claude.com/docs/en/settings-reference
- https://code.claude.com/docs/en/agent-teams
- https://registry.npmjs.org/@anthropic-ai/claude-agent-sdk (dist-tags apenas; `time` truncado pela ferramenta de fetch)
