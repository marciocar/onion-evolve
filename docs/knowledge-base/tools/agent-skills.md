# Agent Skills - Knowledge Base

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-05-15 |
| **Última Atualização** | 2026-05-15 |
| **Categoria** | tools |
| **Fontes Principais** | https://agentskills.io, https://agentskills.io/specification, https://code.claude.com/docs/en/skills |

---

## 📋 Visão Geral

**Agent Skills** é um formato aberto e leve para estender capacidades de agentes IA com conhecimento especializado e workflows repetíveis. Originalmente desenvolvido pela Anthropic, hoje é um padrão aberto adotado por 35+ ferramentas (Claude Code, GitHub Copilot, VS Code, Cursor, Gemini CLI, OpenAI Codex, OpenHands, Kiro, etc.).

**Conceito central**: um skill é uma pasta com um arquivo `SKILL.md` contendo metadados YAML + instruções Markdown. O agente carrega apenas o nome e descrição no startup; as instruções completas só são lidas quando o task bate com o skill (*progressive disclosure*).

**No Claude Code especificamente**:
- Skills e Commands foram **mesclados**: `.claude/commands/deploy.md` e `.claude/skills/deploy/SKILL.md` ambos criam `/deploy` e funcionam de forma equivalente
- Skills é a forma **recomendada** agora — suporta supporting files, frontmatter rico, ativação automática
- `.claude/commands/` continua funcionando (compatibilidade)

---

## 🎯 Casos de Uso

| Quando usar | Exemplos |
|-------------|----------|
| Workflows multi-step repetíveis | Deploy, migração de DB, geração de relatório |
| Conhecimento de domínio não público | APIs internas, schemas proprietários |
| Correção de erros sistemáticos do agente | Gotchas: soft deletes, ID aliases, endpoints especiais |
| Reuse entre agentes/IDEs | Skill criado no Cursor funciona no Claude Code |
| Execução de scripts específicos do projeto | Validadores, formatadores, processadores |

**Quando NÃO usar**:
- Task simples que o agente resolve com conhecimento geral
- Instruções genéricas como "siga boas práticas" (sem especificidade real)
- Skill sem fonte de expertise real (gerado por LLM sem contexto do domínio)

---

## 📁 Paths Oficiais por Cliente

### Claude Code (nativo)
| Scope | Path |
|-------|------|
| Pessoal | `~/.claude/skills/<name>/SKILL.md` |
| Projeto | `.claude/skills/<name>/SKILL.md` |
| Plugin | `<plugin>/skills/<name>/SKILL.md` |
| Enterprise | via [managed settings](https://code.claude.com/docs/en/settings) |

Claude Code também varre `.claude/skills/` em **diretórios pai** até a raiz do repo, e em **diretórios filhos** sob demanda (suporte a monorepo).

### Convenção cross-client (spec aberta)
| Scope | Path |
|-------|------|
| Pessoal | `~/.agents/skills/<name>/SKILL.md` |
| Projeto | `.agents/skills/<name>/SKILL.md` |

Adotado por VS Code Copilot e outros. Alguns clientes varrem ambos `.claude/` e `.agents/` por compatibilidade.

**Regra de ouro no Sistema Onion**: usar `.claude/skills/` (é Claude Code-first). Para distribuir cross-client, manter cópia em `.agents/skills/` também.

---

## ⚡ Quick Start (Claude Code)

```
.claude/skills/
└── meu-skill/
    └── SKILL.md
```

**SKILL.md mínimo:**
```markdown
---
description: O que faz e quando usar. Ex: Processa CSVs — análise, gráficos, limpeza. Use quando o usuário tiver arquivo CSV, TSV ou Excel.
---

## Instruções

Passo 1: ...
Passo 2: ...
```

**Verificar:**
```
/<skill-name>           # invocar diretamente
What skills are available?   # perguntar ao agente
```

Claude Code detecta mudanças **ao vivo** — adicionar/editar/remover skill em `.claude/skills/` reflete na sessão atual (sem restart, exceto se for o primeiro skill em uma pasta nova).

---

## 🔧 Especificação do SKILL.md

### Frontmatter — Spec aberta (todos clientes)

| Campo | Req | Constraints |
|-------|-----|-------------|
| `name` | ✅ (spec) / opcional (Claude Code) | Max 64 chars, lowercase + hífens, sem `--`. Claude Code usa nome da pasta se omitido |
| `description` | ✅ | Max 1024 chars (1536 no Claude Code combinado com `when_to_use`). Descreve **o quê** e **quando** |
| `license` | — | Nome ou path para arquivo de licença |
| `compatibility` | — | Max 500 chars, requisitos de ambiente |
| `metadata` | — | Map string→string |
| `allowed-tools` | — | String separada por espaços (experimental no spec; nativo no Claude Code) |

### Frontmatter — Extensões do Claude Code

Campos adicionais suportados em `.claude/skills/`:

| Campo | Descrição |
|-------|-----------|
| `when_to_use` | Contexto extra de ativação (trigger phrases, exemplos). Soma com `description` (cap 1536 chars) |
| `argument-hint` | Hint de autocomplete: `[issue-number]` |
| `arguments` | Argumentos nomeados posicionais para `$name` substitution |
| `disable-model-invocation` | `true` impede ativação automática pelo agente (só user pode `/invocar`) |
| `user-invocable` | `false` esconde do menu `/` (apenas Claude invoca) |
| `allowed-tools` | Tools pré-aprovadas: `Bash(git add *) Bash(git commit *) Read` |
| `model` | Override de modelo para a duração do skill |
| `effort` | `low` \| `medium` \| `high` \| `xhigh` \| `max` |
| `context` | `fork` → roda em subagent isolado |
| `agent` | Tipo de subagent quando `context: fork`: `Explore`, `Plan`, `general-purpose` ou custom |
| `hooks` | Hooks no ciclo do skill |
| `paths` | Glob — ativa só com arquivos matching: `"src/**/*.ts"` |
| `shell` | `bash` (default) ou `powershell` |

### Body (Markdown)
Sem restrições de formato. **Limite recomendado**: 500 linhas / ~5000 tokens. Conteúdo maior → mover para arquivos em `references/`.

⚠️ **Lifecycle no Claude Code**: uma vez ativado, o conteúdo do SKILL.md **fica em contexto pelo resto da sessão** — cada linha é custo recorrente de tokens. Auto-compaction preserva skills (primeiros 5000 tokens cada, budget combinado de 25000).

### Estrutura de diretórios

```
meu-skill/
├── SKILL.md              # Obrigatório
├── scripts/              # Código executável
├── references/           # Documentação adicional
├── assets/               # Templates, imagens, dados
└── examples/             # Exemplos de output esperado
```

---

## 🔥 Features Exclusivas do Claude Code

### 1. Dynamic Context Injection (`!`command`)

Roda comando shell **antes** do Claude ver o skill. Output substitui o placeholder:

````markdown
---
description: Resume mudanças não-commitadas e sinaliza riscos.
---

## Mudanças atuais

!`git diff HEAD`

## Instruções

Resuma as mudanças acima em 2-3 bullets e liste riscos (error handling ausente, hardcoded values, testes a atualizar).
````

Para comandos multi-linha, use fenced block:
````markdown
## Ambiente
```!
node --version
npm --version
git status --short
```
````

Pode ser desabilitado via `"disableSkillShellExecution": true` em settings.

### 2. Substituições de String

| Variável | Descrição |
|----------|-----------|
| `$ARGUMENTS` | Todos argumentos passados |
| `$ARGUMENTS[N]` / `$N` | Argumento posicional 0-indexed |
| `$name` | Argumento nomeado declarado em `arguments:` |
| `${CLAUDE_SKILL_DIR}` | Diretório do SKILL.md (use para referenciar scripts bundled) |
| `${CLAUDE_SESSION_ID}` | ID da sessão atual |
| `${CLAUDE_EFFORT}` | `low` \| `medium` \| `high` \| `xhigh` \| `max` |

**Exemplo:**
```yaml
---
arguments: [component, from, to]
---
Migre o componente $component de $from para $to.
Preserve todos os testes existentes.
```
```
/migrate-component SearchBar React Vue
```

### 3. `context: fork` — Skill em Subagent

Roda o skill em sessão isolada (sem histórico da conversa):

```yaml
---
description: Pesquisa profunda sobre um tópico.
context: fork
agent: Explore
---

Pesquise $ARGUMENTS profundamente:
1. Encontre arquivos relevantes (Glob, Grep)
2. Leia e analise o código
3. Sumarize com referências de arquivo
```

Combina com `agent: Explore` (read-only, otimizado para exploração) ou `Plan`, ou subagents custom.

> **Orquestração multi-agente (mai/2026):** `context: fork` roda **um** subagent isolado. Para coordenar **vários** agentes em paralelo/sequência (fan-out/fan-in, pipelines), o mecanismo canônico do Claude Code é a **ferramenta nativa `Workflow`** (research preview) — ver [Agent Orchestration](../concepts/agent-orchestration.md) e o comando `/meta:orchestrate`. Regra: `context: fork` para isolar uma skill; `Workflow` para orquestração.

### 4. Controle de Invocação

```yaml
# Apenas user invoca (Claude não decide sozinho)
disable-model-invocation: true

# Skill conhecimento de background — apenas Claude usa, não aparece em /
user-invocable: false
```

Padrão: ambos invocam.

---

## 💡 Best Practices

### 1. Partir de expertise real
Não peça ao LLM para gerar um skill sem fornecer contexto de domínio. Use como fonte:
- Runbooks internos, incident reports, ADRs
- Histórico de correções no git (`git log --grep`)
- Code review comments (revelam erros sistemáticos)
- API specs, schemas reais do projeto

### 2. Refinar com execução real
Execute o skill em tasks reais → leia o execution trace → corrija. Um ciclo de *execute-then-revise* melhora significativamente o resultado.

### 3. Adicionar apenas o que o agente não sabe
```markdown
<!-- ❌ Verboso — o agente já sabe o que é PDF -->
PDF é um formato de arquivo amplamente usado...

<!-- ✅ Direto -->
Use pdfplumber. Para PDFs escaneados, use pdf2image + pytesseract.
```

### 4. Gotchas section (alto valor)
```markdown
## Gotchas
- A tabela `users` usa soft delete. Sempre incluir `WHERE deleted_at IS NULL`.
- `user_id` no DB = `uid` no auth = `accountId` no billing. Mesma coisa.
- `/health` retorna 200 mesmo com DB offline. Use `/ready` para health real.
```

### 5. Templates, checklists, defaults claros
Agentes seguem template concreto melhor do que prosa. Sempre dar **um default + escape hatch**, não menu de opções.

### 6. SKILL.md enxuto, detalhes em `references/`
Mantenha < 500 linhas. Reference detalhes assim:
```markdown
Para detalhes completos da API, veja [reference.md](reference.md).
Se a API retornar 5xx, leia [troubleshooting.md](troubleshooting.md).
```

---

## 🎯 Otimizando o campo `description`

O `description` é o trigger principal. Sem ele, o skill não ativa.

**Princípios:**
- **Phrasing imperativo**: "Use when…" em vez de "This skill does…"
- **Foco no intent do usuário**, não na implementação
- **Inclua "mesmo que o usuário não mencione X explicitamente"** para capturar near-misses
- **Cap real no Claude Code**: 1536 chars (`description` + `when_to_use` combinados)

**Antes/depois:**
```yaml
# ❌
description: Process CSV files.

# ✅
description: >
  Analisa arquivos CSV e tabulares — estatísticas, colunas derivadas, gráficos,
  limpeza. Use quando o usuário tiver CSV, TSV ou Excel e quiser explorar,
  transformar ou visualizar, mesmo sem mencionar "CSV" explicitamente.
```

**Testando triggers (eval):**
1. ~20 queries: 10 should-trigger, 10 should-not-trigger (near-misses)
2. Split 60/40 train/validation
3. Rodar 3x cada, calcular trigger rate (threshold 0.5)
4. Iterar máx 5 ciclos, generalizar (não patch por keyword)

---

## 🔩 Scripts em Skills

### One-off commands
```bash
uvx ruff@0.8.0 check .        # Python (recomendado)
npx eslint@9 --fix .           # JavaScript
```
Sempre **pinar versão**.

### Scripts auto-contidos
**Python (PEP 723):**
```python
# scripts/extract.py
# /// script
# dependencies = ["pdfplumber>=0.11"]
# ///
import pdfplumber
```
```bash
uv run scripts/extract.py
```

### Path resolution no Claude Code

Use `${CLAUDE_SKILL_DIR}` para referenciar scripts independente do cwd:

````markdown
```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/visualize.py .
```
````

### Design para uso agentico
- **Sem prompts interativos** (agentes não respondem TTY)
- **`--help` descritivo** (é como o agente aprende a interface)
- **Erro útil + sugestão**: `Error: --env required. Options: staging, production`
- **stdout = dados, stderr = logs**
- **Idempotência** (agentes retry)
- **`--dry-run`** em ops destrutivas

---

## ⚠️ Limitações e Gotchas

| Limitação | Detalhe |
|-----------|---------|
| Confiança em repos externos | Skills em `.claude/skills/` de repos clonados exigem trust do workspace para `allowed-tools` aplicar |
| Non-determinismo | Mesmo query pode ou não ativar — testar com 3 runs |
| Tasks simples ignoram skills | Se o agente já resolve sozinho, skill não ativa |
| Description budget overflow | Com muitos skills, descriptions são cortadas para caber em ~1% do context window. `/doctor` mostra status |
| Lifecycle persistente | Skill ativado fica em contexto pelo resto da sessão — cada linha é custo recorrente |
| Colisão de nomes | Enterprise > Personal > Project (skills); Skill > Command com mesmo nome |
| `context: fork` requer task explícita | Skills só com guidelines (sem ação) retornam sem output em fork |

---

## 🔗 Integração com o Sistema Onion

### Commands ⇄ Skills (Claude Code)

**Importante**: no Claude Code, custom commands foram **mesclados** com skills.

| | `.claude/commands/deploy.md` | `.claude/skills/deploy/SKILL.md` |
|--|------------------------------|----------------------------------|
| Cria `/deploy` | ✅ | ✅ |
| Frontmatter rico | ❌ básico | ✅ completo |
| Supporting files | ❌ | ✅ (`scripts/`, `references/`) |
| Ativação automática | ❌ (sempre explícita) | ✅ (a menos que `disable-model-invocation: true`) |
| Cross-client | ❌ Claude Code only | ✅ via `.agents/skills/` |

**Recomendação no Onion**:
- **Workflows novos** → criar como skill em `.claude/skills/`
- **Comandos existentes em `.claude/commands/`** → continuam funcionando, migrar quando precisar de supporting files ou ativação automática
- **Para distribuir cross-IDE** → cópia em `.agents/skills/`

### Localização recomendada no projeto

```
.claude/skills/          # ✅ Padrão Onion (Claude Code-first)
.claude/commands/        # ✅ Legacy / comandos puramente explícitos
.agents/skills/          # Opcional — cross-client distribution
```

### Agentes relacionados
- `@agent-skills-specialist` — criar, validar e otimizar skills
- `@command-creator-specialist` — comandos `.claude/commands/` (legacy)
- `@agent-creator-specialist` — subagents customizados
- `@claude-code-specialist` — config e troubleshooting Claude Code

---

## 🔗 Referências

- [Claude Code Skills (oficial)](https://code.claude.com/docs/en/skills)
- [Agent Skills — Spec aberta](https://agentskills.io/specification)
- [Quickstart](https://agentskills.io/skill-creation/quickstart)
- [Best Practices](https://agentskills.io/skill-creation/best-practices)
- [Optimizing Descriptions](https://agentskills.io/skill-creation/optimizing-descriptions)
- [Evaluating Skills](https://agentskills.io/skill-creation/evaluating-skills)
- [Using Scripts](https://agentskills.io/skill-creation/using-scripts)
- [Client Implementation](https://agentskills.io/client-implementation/adding-skills-support)
- [Exemplos reais (Anthropic)](https://github.com/anthropics/skills)
- [skill-creator skill (automação de evals)](https://github.com/anthropics/skills/tree/main/skills/skill-creator)
- KBs relacionadas: [claude-code-commands-best-practices-2026](./claude-code-commands-best-practices-2026.md)

---

**Última atualização**: 2026-05-15
**Fonte primária**: https://code.claude.com/docs/en/skills (Claude Code) + https://agentskills.io/specification (spec aberta)
