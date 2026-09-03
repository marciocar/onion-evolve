---
name: create-skill
description: |
  Orquestrador para criar, validar, otimizar e migrar Agent Skills via
  @agent-skills-specialist. Padrão Onion: skills em .claude/skills/ (Claude Code-nativo).
  Suporta também .agents/skills/ para distribuição cross-client.
allowed-tools: Read Write Bash(ls *) Bash(grep *) Bash(bash .claude/validation/inventory.sh*)

parameters:
  - name: action
    description: "create | validate | optimize | migrate | eval (default: create)"
    required: false
    default: create
  - name: skill_name
    description: Nome do skill em kebab-case (ou path para skill existente)
    required: false
  - name: context
    description: Descrição do domínio, problema ou expertise que o skill vai encapsular
    required: false
  - name: scope
    description: "claude (default, .claude/skills/) | cross (.agents/skills/)"
    required: false
    default: claude

category: meta
tags:
  - agent-skills
  - skill-creation
  - claude-code
  - cross-agent
  - meta

version: "1.1.0"
updated: "2026-05-15"

related_commands:
  - /meta/create-agent
  - /meta/create-command
  - /meta/create-knowledge-base

related_agents:
  - agent-skills-specialist
  - command-creator-specialist
  - agent-creator-specialist
---

# 🧩 Agent Skills — Criar / Validar / Otimizar / Migrar

Orquestrador para o `@agent-skills-specialist`. Detecta o modo de operação, coleta contexto e delega.

## 🎯 Objetivo

Guiar a criação e manutenção de **Agent Skills** — formato que estende capacidades do Claude Code (e clientes compatíveis) via pastas com `SKILL.md`. No Sistema Onion, o padrão é `.claude/skills/` (Claude Code-first).

**Lembrete crítico**: no Claude Code, custom commands e skills foram **mesclados** — `.claude/commands/X.md` e `.claude/skills/X/SKILL.md` ambos criam `/X`. Skills é a forma recomendada para workflows novos (suporta supporting files, frontmatter rico, ativação automática).

---

## ⚡ Fluxo de Execução

### Passo 1: Detectar Modo de Operação

Ler `$ARGUMENTS` e determinar:

| Argumento | Modo | O que faz |
|-----------|------|-----------|
| `create` (default) | **Criar** | Novo skill em `.claude/skills/<name>/` |
| `validate` | **Validar** | Checar skill existente (estrutura, frontmatter, lifecycle cost) |
| `optimize` | **Otimizar** | Melhorar description trigger via eval set |
| `migrate` | **Migrar** | Converter `.claude/commands/X.md` em skill |
| `eval` | **Avaliar** | Configurar test cases de qualidade |

Defaults inteligentes:
- Sem modo + path para SKILL.md existente → perguntar: validate/optimize/eval?
- Sem modo + path para .claude/commands/*.md → sugerir `migrate`
- Sem modo + descrição livre → `create`

### Passo 2: Coletar Inputs

**Modo `create`** — perguntar se não fornecidos:
1. **Nome do skill** (kebab-case, ex: `pdf-processing`)
2. **Expertise/domínio**: que erro sistemático ou conhecimento não-óbvio o skill encapsula?
3. **Artefatos de referência**: runbooks, schemas, histórico de PRs, API specs?
4. **Scripts necessários?** Python/Bash/Deno?
5. **Features Claude Code aplicáveis?**
   - Dynamic injection (`` !`git diff` ``) para dados live?
   - `disable-model-invocation` (skill destrutivo tipo deploy)?
   - `context: fork` (pesquisa que poluiria a conversa)?
   - `paths` glob (só ativar em certos arquivos)?
6. **Scope**: `.claude/skills/` (default Onion) ou `.agents/skills/` (cross-client)?

**Modo `validate`** — coletar:
1. Path do skill: `find . -name "SKILL.md" -path "*skills/*"`
2. Checar: frontmatter, contagem de linhas (< 500), description quality, lifecycle cost

**Modo `optimize`** — coletar:
1. Path do skill
2. Exemplos de queries que deveriam (e não deveriam) ativar
3. Output do `/doctor` se description estiver overflow

**Modo `migrate`** — coletar:
1. Path do comando legacy em `.claude/commands/`
2. Razões para migrar (precisa scripts? supporting files? ativação automática?)
3. Manter ou não `disable-model-invocation` (comando explícito → sim; queremos ativação semântica → não)

**Modo `eval`** — coletar:
1. Path do skill
2. 2-3 tasks reais como ponto de partida

### Passo 3: Verificações Rápidas

```bash
# Estrutura padrão Onion
ls .claude/skills/ 2>/dev/null || echo "Pasta .claude/skills/ ainda não existe"
ls ~/.claude/skills/ 2>/dev/null || echo "Sem skills pessoais ainda"

# Cross-client (opcional)
ls .agents/skills/ 2>/dev/null

# Verificar duplicação
find . -name "SKILL.md" 2>/dev/null | xargs grep -l "^name:\s*<skill_name>\|^description:" 2>/dev/null

# Commands legacy candidatos a migrar
ls .claude/commands/ 2>/dev/null
```

### Passo 4: Delegar para @agent-skills-specialist

Invocar com contexto estruturado:

```
@agent-skills-specialist

Modo: {{action}}
Skill: {{skill_name}}
Scope: {{scope}}
Localização alvo: {{path}}/skills/{{skill_name}}/SKILL.md
KB de referência: docs/knowledge-base/tools/agent-skills.md

Contexto do domínio:
{{context coletado}}

Artefatos disponíveis:
{{runbooks, schemas, exemplos}}

Features Claude Code desejadas:
{{dynamic injection, fork, paths, etc.}}
```

O agente vai:
- **create**: gerar `SKILL.md` + estrutura de pasta, com frontmatter adequado ao scope
- **validate**: checar coerência (description quality, lifecycle cost, paths, etc.)
- **optimize**: propor iterações da description com técnica train/validation
- **migrate**: converter command em skill mantendo o `/comando` funcional
- **eval**: estruturar `evals/evals.json` com test cases e assertions

### Passo 5: Confirmação Pós-Operação

```bash
# Estrutura criada
find .claude/skills/<name> -type f | sort

# Tamanho do SKILL.md
wc -l .claude/skills/<name>/SKILL.md

# Preview do frontmatter
head -25 .claude/skills/<name>/SKILL.md

# Claude Code detecta mudanças ao vivo — nova invocação:
# Em outra janela do Claude Code: "/<skill-name>" ou pergunta que bate com description
```

---

## 🗺️ Estrutura Esperada

### Skill no Claude Code (padrão Onion)
```
.claude/skills/<name>/
├── SKILL.md              # < 500 linhas
├── scripts/              # Referenciados via ${CLAUDE_SKILL_DIR}
│   └── *.py / *.sh
├── references/           # Carregados sob demanda
└── examples/             # Exemplos de output
```

### Skill cross-client (opcional)
```
.agents/skills/<name>/
├── SKILL.md              # Apenas frontmatter spec aberto
└── scripts/              # Paths relativos (não usa ${CLAUDE_SKILL_DIR})
```

### SKILL.md mínimo (Claude Code)
```markdown
---
description: >
  [O que faz — verbos de ação].
  Use quando [contexto explícito], mesmo que o usuário
  não mencione [keyword] diretamente.
---

## Instruções
[Passo a passo concreto]

## Gotchas
- [Erros sistemáticos do domínio]
```

### SKILL.md com features Claude Code
```markdown
---
description: Resume mudanças não-commitadas e flag riscos.
allowed-tools: Bash(git *)
---

## Mudanças atuais

!`git diff HEAD`

## Instruções
Resuma as mudanças em 2-3 bullets e liste riscos.
```

---

## 📤 Output Esperado

```
✅ SKILL {{action}}

━━━━━━━━━━━━━━

📁 Arquivo: .claude/skills/{{skill_name}}/SKILL.md
📏 Linhas: N (< 500)
🎯 Scope: claude (Claude Code nativo)

📋 RESULTADO:
   ∟ description: [preview 80 chars]
   ∟ Features Claude Code: [dynamic injection, fork, etc.]
   ∟ Scripts: sim/não
   ∟ References: sim/não

🔍 QUALIDADE:
   ∟ Frontmatter: ✅ válido
   ∟ Description: ✅ imperativa + contexto
   ∟ Lifecycle cost: ✅ < 500 linhas
   ∟ Gotchas: ✅/⚠️ presente/ausente

🚀 PRÓXIMOS PASSOS:
   ∟ Testar: /{{skill_name}} ou pergunta que bate com description
   ∟ Otimizar trigger: /meta/create-skill optimize {{skill_name}}
   ∟ Avaliar qualidade: /meta/create-skill eval {{skill_name}}
   ∟ Distribuir cross-client: copiar para .agents/skills/

━━━━━━━━━━━━━━
```

---

## 💡 Exemplos de Uso

```bash
# Criar skill no Claude Code (default)
/meta/create-skill "processar faturas no formato TISS"

# Criar cross-client (também em .agents/skills/)
/meta/create-skill create tiss-processor --scope cross

# Validar skill existente
/meta/create-skill validate .claude/skills/pdf-processing/

# Otimizar description (trigger accuracy)
/meta/create-skill optimize pdf-processing

# Migrar comando legacy para skill
/meta/create-skill migrate .claude/commands/deploy.md

# Configurar evals de qualidade
/meta/create-skill eval csv-analyzer
```

---

## 🔗 Referências

- **Agente principal**: @agent-skills-specialist
- **KB**: `docs/knowledge-base/tools/agent-skills.md`
- **Docs oficiais**: https://code.claude.com/docs/en/skills (Claude Code) | https://agentskills.io/specification (spec aberta)
- **Exemplos reais**: https://github.com/anthropics/skills
- **Relacionado**: `/meta/create-command` (commands legacy `.claude/commands/`)
- **Relacionado**: `/meta/create-agent` (subagents `.claude/agents/`)

## ⚠️ Notas

- **Padrão Onion**: `.claude/skills/` (Claude Code-nativo). `.agents/skills/` é opcional para distribuir cross-IDE
- **Commands ⇄ Skills mesclados**: `.claude/commands/X.md` e `.claude/skills/X/SKILL.md` ambos criam `/X`
- **Live reload**: Claude Code detecta mudanças em `.claude/skills/` sem restart (exceto primeira criação da pasta)
- Skill ativado permanece em contexto pelo resto da sessão — cada linha extra é custo recorrente
- Skill gerado sem contexto de domínio real tem valor mínimo — sempre extrair de runbooks/schemas/PRs
- Se o agente já lida bem com o task sem o skill → o skill não agrega valor
- **Passo final — sincronizar a SSOT:** após criar, rodar **`/meta:inventory`** (regenera `inventory.md`; a Regra 8 do lint é HARD → criar sem regenerar deixa o repo em HARD-fail silencioso). Mecanismo: `common:prompts:inventory-sync-after-create`.