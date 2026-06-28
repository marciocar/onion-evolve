---
title: Meta-spec — Padrões para Agentes do Sistema Onion
date: 2026-06-17
version: 1.2.0
level: L0
status: active
gate-keeper: "@metaspec-gate-keeper"
---

# Meta-spec — Padrões para Agentes do Sistema Onion

## Propósito

Define os padrões imutáveis (L0) que **todos os agentes** em `.claude/agents/` devem seguir. Esta spec é a constituição normativa do `@metaspec-gate-keeper` para validar conformidade em PRs que criam ou modificam agentes.

Aplica-se ao **Sistema Onion**, não ao projeto-alvo onde o Onion é instalado.

Referências relacionadas:

- [commands.md](./commands.md) — padrões para comandos
- [architecture.md](./architecture.md) — estrutura de diretórios e dependências
- [code-standards.md](./code-standards.md) — padrões de código e idioma
- [integrations.md](./integrations.md) — padrões para integrações com sistemas externos

---

## 1. Estrutura YAML obrigatória

Todo agente em `.claude/agents/<categoria>/<nome>.md` deve começar com frontmatter YAML contendo no mínimo:

```yaml
---
name: <kebab-case-slug>
description: <descrição em uma linha, voltada a quando invocar o agente>
tools: [<lista de tools necessárias>]
---
```

### Campos obrigatórios

| Campo | Tipo | Regra |
|---|---|---|
| `name` | string | kebab-case, único entre todos os agentes, sem prefixo `@` |
| `description` | string | Uma frase descrevendo **quando** invocar; pode incluir "use para X" e "relacionado: @outro-agente" |
| `tools` | lista ou string | Tools nativas do Claude Code OU `*` para todos. Listar MCPs específicos quando necessário |

### Campos opcionais

| Campo | Tipo | Uso |
|---|---|---|
| `model` | string | Override de modelo (`opus`, `sonnet`, `haiku`, `fable`). Omitir para herdar do parent |
| `color` | string | Hint visual de categoria |

### Exemplos

**Agente bem-formado** (extraído de `.claude/agents/product/product-agent.md`):

```yaml
---
name: product-agent
description: Especialista em gestão de projetos e produtos AI que coordena iniciativas e especifica funcionalidades. Use para gerenciamento estratégico de produto e coordenação de equipes. Relacionado: @task-specialist, @clickup-specialist.
tools: [Read, Write, Grep, Glob, WebSearch, TodoWrite, Bash]
---
```

> **Nomes de tool válidos (Claude Code):** `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`,
> `WebSearch`, `WebFetch`, `TodoWrite`, `NotebookEdit`, `Task` — mais tools MCP (`mcp_*`).
> **NUNCA** use nomes de outras IDEs (`read_file`, `run_terminal_cmd`, `codebase_search`,
> `list_dir`, `search_replace`, `web_search`, `todo_write`, `glob_file_search`): não existem no
> Claude Code e o subagente fica **sem ferramentas** (`tool_uses:0` → abstém ou alucina).
> Validado pelo lint (`check_agent_tool_names`).

---

## 2. Categorias válidas

Agentes devem residir em uma das **9 categorias** abaixo. Criação de nova categoria exige proposta com justificativa.

| Categoria | Função | Exemplos |
|---|---|---|
| `development/` | Especialistas técnicos verticais (linguagem, framework, infra) | `react-developer`, `nodejs-specialist`, `postgres-specialist` |
| `product/` | Discovery, especificação, decomposição, branding, reuniões | `product-agent`, `task-specialist`, `extract-meeting-specialist` |
| `compliance/` | Frameworks regulatórios, segurança, governança | `iso-27001-specialist`, `soc2-specialist`, `pmbok-specialist` |
| `meta/` | Criação, validação e orquestração de artefatos do próprio Onion | `command-creator-specialist`, `agent-creator-specialist`, `metaspec-gate-keeper`, `onion` |
| `git/` | GitFlow, code review, branch-specific tasks | `gitflow-specialist`, `branch-code-reviewer` |
| `testing/` | Estratégia, planejamento e implementação de testes | `test-agent`, `test-engineer`, `test-planner` |
| `review/` | Code review pós-implementação | `code-reviewer` |
| `research/` | Pesquisa multi-fonte, análise semântica | `research-agent` |
| `deployment/` | Containerização, infraestrutura, deploy | `docker-specialist` |

**Regra**: o nome do diretório deve corresponder exatamente ao slug da categoria (sem variações de capitalização ou separadores).

---

## 3. Convenção de naming

- **Slug** (campo `name` + nome do arquivo): kebab-case sem prefixo (`product-agent`, não `@product-agent` nem `Product-Agent`)
- **Filename**: `<slug>.md` (corresponde ao `name`)
- **Path completo**: `.claude/agents/<categoria>/<slug>.md`
- **Invocação**: usuário invoca com `@<slug>` no chat
- Sufixos comuns aceitos: `-specialist`, `-agent`, `-developer`, `-engineer`, `-reviewer`, `-creator`, `-checker`, `-master`

---

## 4. Limites de tamanho

| Limite | Linhas | Tratamento |
|---|---|---|
| Recomendado | até 1.200 | OK |
| Soft warning | 1.200 – 1.500 | Considerar modularização (delegar para sub-agentes, extrair KBs) |
| Hard limit | > 1.500 | Refatoração obrigatória antes de merge |

Agentes que excederem 1.500 linhas devem extrair partes para:

- Knowledge bases em `docs/knowledge-base/`
- Skills em `.claude/skills/` quando o conhecimento é "cérebro" reutilizável
- Outros agentes especialistas delegáveis

---

## 5. Padrões de delegação

### Quando criar um especialista novo

Justificativa válida exige **pelo menos um** dos critérios:

- Conhecimento técnico específico não coberto pelos agentes existentes (linguagem, framework, padrão)
- Framework regulatório específico (ISO, SOC2, PMBOK)
- Integração com sistema externo com formatação/protocolo próprio (Jira ADF, ClickUp Unicode)
- Workflow especializado que justifica contexto próprio (review pré-PR de branch, extração de reuniões)

### Quando estender agente agnóstico em vez de criar especialista

- Decomposição genérica de tarefas → `@task-specialist`
- Análise de produto sem framework específico → `@product-agent`
- Pesquisa multi-fonte → `@research-agent`

### Proibido: agente orquestrador de workers

**Não crie um agente "worker-orchestrator".** A orquestração de workers (fan-out paralelo) reside em **skill/comando** (`onion-orchestration` + `/meta:orchestrate`), nunca em agente — por [architecture.md §4.2](./architecture.md), `agents/* → commands/*` é proibido e subagentes não disparam a orquestração. Ver [commands.md §10](./commands.md).

### Regra para o YAML `description`

A descrição deve indicar **quando** invocar (gatilho), não apenas **o que** faz. Padrão:

```
<Especialização>. Use para <casos de uso>. Relacionado: @agente1, @agente2.
```

---

## 6. Integração com MCPs

Quando um agente depende de MCP (Model Context Protocol), declarar no campo `tools`:

```yaml
tools:
  - Read
  - Write
  - mcp__clickup__create_task
  - mcp__clickup__update_task
  - mcp__clickup__get_workspace_hierarchy
```

**Regras**:

- Listar apenas as tools MCP que o agente realmente usa (não declarar acesso amplo desnecessário)
- Documentar dependências MCP no corpo do agente, sob seção "Dependências"
- Validar configuração via `/meta:setup-integration`

Referência canônica: [integrations.md](./integrations.md).

---

## 7. Estrutura do corpo do arquivo

Após o frontmatter YAML, recomenda-se estrutura mínima:

```markdown
# <Nome do Agente>

## Propósito
<O que este agente faz e por que existe>

## Quando invocar
<Gatilhos concretos, casos de uso>

## Quando NÃO invocar
<Limites do escopo, agentes alternativos>

## Workflow
<Passo a passo do que o agente executa quando invocado>

## Dependências
<KBs, MCPs, outros agentes, comandos>

## Exemplos
<Casos práticos com input/output esperados>
```

---

## 8. Exemplos de conformidade

### Exemplo conforme

Arquivo: `.claude/agents/product/product-agent.md`

- Frontmatter completo com `name`, `description` orientado a uso, `tools` específicas
- Categoria válida (`product/`)
- Kebab-case
- Descrição inclui "use para" e "relacionado:"
- Tamanho dentro de limite recomendado

**Veredito**: `@metaspec-gate-keeper` deve aprovar.

### Exemplo quase-conforme

Arquivo hipotético: `.claude/agents/development/react-developer.md`

- Frontmatter correto
- Categoria válida
- Tamanho: 1.350 linhas (entre soft warning e hard limit)

**Veredito**: aprovação condicional com nota de "considerar modularização". Não bloqueia merge, mas registra dívida técnica.

### Exemplo não-conforme

Arquivo hipotético: `.claude/agents/misc/MyAgent.md`

- Categoria inválida (`misc/` não existe na lista)
- Filename em PascalCase (deveria ser `my-agent.md`)
- Frontmatter sem campo `tools`

**Veredito**: `@metaspec-gate-keeper` deve rejeitar com 3 violações listadas.

---

## 9. Guardas determinísticas que tocam agentes testam a si mesmas

Várias guardas de `lint-artifacts.sh` protegem agentes — frontmatter obrigatório (Regra 1), nomes de tool válidos / proibição de MCP de provider no frontmatter (Regra 12), limites de tamanho (Regra 5), proibição de agente worker-orchestrator (Regra 7). Pela simetria com [commands.md §11](./commands.md), toda guarda **nova** (ou alteração) que valide agentes nasce com:

1. **Fixture de failure-mode** em `.claude/validation/fixtures/`, registrada no `manifest.tsv`, isolando a regra (caso `bad` obrigatório; `good`/`exempt` quando houver allowlist — ex.: a allowlist de especialistas de provider da Regra 12).
2. **Revisão independente** de prompt neutro antes do PR.

O contrato executável é `.claude/validation/lint-selftest.sh`, que injeta cada fixture num sandbox e confere o veredito real — uma guarda de agente que parar de reagir faz o CI falhar em vez de degradar em silêncio. Ver [commands.md §11](./commands.md) para a doutrina completa.

---

## 10. Versionamento e mudanças

Mudanças nesta spec exigem:

1. PR específico para `docs/meta-specs/agents.md`
2. Atualização do campo `version` no frontmatter
3. Validação por `@metaspec-gate-keeper` de que agentes existentes ainda passam (ou plano de migração explícito)
4. Atualização desta spec não pode ser feita em PR que toca em agentes — separação para evitar mudança normativa "no atacado"
