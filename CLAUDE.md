# 🧅 Sistema Onion - Claude Code Rules

## 🎯 Contexto do Projeto

Este é o **Sistema Onion** — um **framework template em `.claude/`** projetado para ser instalado e aplicado em qualquer projeto (novo, legado ou regulado) para orquestrar o ciclo completo de desenvolvimento com Claude Code.

**Identidade canônica** (decisões de 2026-05-18, consolidadas em [docs/analysis/onion-review-2026-05.md](docs/analysis/onion-review-2026-05.md)):

- Framework template em `.claude/` — **não é produto npm**, **não tem CLI standalone**
- **Plataforma única: Claude Code** — por **capacidade**, não por origem. O Onion nasceu no **Cursor**
  buscando ser agnóstico, e foi de fato **portado** para Claude/Antigravity/Codex para o Curso de
  Desenvolvimento com IA (Pulse Mais), com alunos usando. A decisão de 2026-05-18 foi **parar de
  gastar energia em agnosticismo** para poder usar recursos de fronteira. É conclusão de experimento
  real, não restrição de nascença.
  **A capacidade que COMPRA o acoplamento** (corrigido em 2026-08-16, medido): o **`exit 2`
  determinístico de hook**, que barra a ação inclusive sob `bypassPermissions` — isso não existe fora
  do Claude Code e nenhum CI replica. O exemplo antigo era `SendMessage` no modo Teams, e a medição o
  derrubou: `grep -rn SendMessage .claude` devolve **ZERO** — a capacidade citada como razão de
  abandonar o agnosticismo **nunca foi exercitada na maquinaria**. Acoplamento declarado e não usado é
  a pior categoria: paga-se o preço doutrinário sem receber a capacidade. E há uma inversão a saber:
  medidas as massas, **26.596 linhas de shell agnóstico (o que REPROVA, roda em qualquer CI)** contra
  **52.655 de markdown acoplado (o que ACONSELHA)** — o fosso do Onion está, de fato, na metade que
  não precisa de acoplamento nenhum. SSOT: `docs/evolution/research/claude-code-2.1-onion-2026-08/`.
- **A postura de acoplamento** (o critério que decide toda adoção de substrato): *acoplado ao Claude
  Code para tirar vantagem da sua estrutura e maquinaria, **mas mantendo independência sempre que
  isso for mais vantajoso e o acoplamento não for necessidade***. Acople só quando a capacidade
  ganha não existe fora — nunca por conveniência nem por simetria.
- **CORE ≠ FAMÍLIA** — estas linhas descrevem **este repo** (o core). Existe uma **família multi-IDE
  pública e CONGELADA** (`onion`, `onion-cursor`, `onion-antigravity`, `onion-copilot`,
  `onion-architect`, `onion-mini`, `onion-standalone`): material de curso e **prova de
  portabilidade**, não linha de manutenção ativa. Sem esta distinção, quem lê conclui que os repos
  públicos violam a doutrina — **conclusão errada, já cometida em 2026-08-02**. SSOT:
  `docs/onion/graph/onion-identity-2026-07.kg.yaml` (`C_CORE_NAO_E_FAMILIA`, `C_POSTURA_ACOPLAMENTO`)
- Cobre **três dimensões peer** do ciclo: produto, engenharia, compliance/governança
- **Workflows faseados retomáveis** com sessões persistentes — `product/collect→feature` (descoberta a backlog) e `engineer/plan→pr-update` (planejamento a entrega) são invariantes do framework, não devem ser consolidados
- `.onion/` (estrutura agnóstica) e plano v4.0 FASES 5-9 (CLI standalone, multi-IDE, aprendizado contínuo) foram **formalmente abandonados em 2026-05-18**

**Inventário atual** (contagens canônicas vivem em [docs/onion/inventory.md](docs/onion/inventory.md) — **SSOT gerada do filesystem** por `.claude/validation/inventory.sh` e validada no CI; nunca edite os números à mão, rode `/meta:inventory`. Convenção de contagem: a contagem de Knowledge Bases inclui os READMEs de (sub)categoria e exclui `index.md`):

- 109 comandos invocáveis por categoria (`product`, `git`, `engineer`, `docs`, `meta`, `validate`, `test`, `design`, `development`, `quick`) + `onion.md`, `warm-up.md` e `catch-up.md` no root; `common/` guarda fragmentos compartilhados (templates/prompts) e há READMEs de categoria. (`design/` é **categoria de comando**, não 4ª dimensão peer — esta permanece em 3: produto, engenharia, compliance; a promoção de `design-context` a peer é provisória e gated)
- 51 agentes especializados de IA em 9 categorias (`compliance`, `deployment`, `development`, `git`, `meta`, `product`, `research`, `review`, `testing`)
- 12 skills em `.claude/skills/` (`onion` — orquestrador; `onion-patterns`; `onion-validation`; `language-standards`; `onion-orchestration` — orquestração de subagentes; `onion-retro` — retro/feedback como spec-as-code; `onion-publish` — condução da publicação do marketplace, core-only)
- **Task Manager Abstraction** plugável (Jira, ClickUp, Asana, Linear) via `.claude/utils/task-manager/`
- Workflows automatizados de desenvolvimento (GitFlow + sessions persistentes em `.claude/sessions/`)

---

## 🔌 Task Manager - Detecção e Roteamento

O Sistema Onion é **provider-agnóstico** para gerenciamento de tarefas — uma **instância do padrão SDAAL** (ver [integrations.md](docs/meta-specs/integrations.md)). Adapters são **API-first**; o MCP é um transporte **opcional**. Antes de operar com tasks, **sempre verifique qual provider está ativo** lendo `TASK_MANAGER_PROVIDER` em `.env`.

### Fluxo obrigatório antes de operar com tasks

1. **Carregar** variáveis do `.env` (ex: `set -a; source .env; set +a`)
2. **Ler** `TASK_MANAGER_PROVIDER` (`jira` | `clickup` | `asana` | `linear` | `none`) e `TASK_MANAGER_TRANSPORT` (`api` default | `mcp` opcional)
3. **Conferir** variáveis específicas do provider ativo (tabela abaixo)
4. **Delegar** ao agente correto — via API (default) ou MCP (se ativado) — e usar formatação adequada

### Mapa Provider → Variáveis → Agente → Adapter

| Provider | Variáveis obrigatórias | Variáveis opcionais | Agente especialista | Adapter doc |
|----------|------------------------|---------------------|---------------------|-------------|
| **`jira`** | `JIRA_HOST`, `JIRA_EMAIL`, `JIRA_API_TOKEN` | `JIRA_PROJECT_KEY`, `JIRA_AUTH_TYPE` (basic/bearer), `JIRA_API_VERSION` (3/2) | `@jira-specialist` | `.claude/utils/task-manager/adapters/jira.md` |
| **`clickup`** | `CLICKUP_API_TOKEN` | `CLICKUP_WORKSPACE_ID`, `CLICKUP_DEFAULT_LIST_ID` | `@clickup-specialist` | `.claude/utils/task-manager/adapters/clickup.md` |
| **`asana`** | `ASANA_ACCESS_TOKEN` | `ASANA_WORKSPACE_ID`, `ASANA_DEFAULT_PROJECT_ID` | _(agnóstico via `@task-specialist`)_ | `.claude/utils/task-manager/adapters/asana.md` |
| **`linear`** | `LINEAR_API_KEY` | `LINEAR_TEAM_ID` | _(agnóstico via `@task-specialist`)_ | `.claude/utils/task-manager/adapters/linear.md` |
| **`none`** | — | — | `@task-specialist` (decompõe localmente, sem persistir) | — |

### Regras de delegação

- **Estratégia / gestão / priorização** → `@product-agent` (qualquer provider)
- **Decomposição hierárquica de tasks** (agnóstico) → `@task-specialist`
- **Operação técnica do provider ativo** → especialista do provider:
  - `jira` → `@jira-specialist` (JQL, ADF, transitions, bulk, sprints/boards)
  - `clickup` → `@clickup-specialist` (API-first; MCP opcional, listas, custom fields, comentários Unicode)
- **Sem provider configurado** (`none`) → operar offline com `@task-specialist`; **não** tentar API calls

> **Por que só jira/clickup têm especialista dedicado (decisão de design, não viés):** Jira e ClickUp têm APIs/regras ricas o bastante para justificar um especialista (ADF + JQL + transitions no Jira; formatação Unicode + custom fields + hierarquia/checklists no ClickUp). **Asana e Linear** são integralmente cobertos pelo `@task-specialist` genérico + seu adapter (API-first) — criar especialistas dedicados seria inchar o conjunto de especialistas sem ganho. Em todos os casos, **o consumidor chama a abstração agnóstica** (`taskManager.*`); o adapter resolve transporte (REST API default, MCP opcional), formato e quando acionar o especialista. **Nunca** se chama o MCP/SDK de um provider direto no comando/agente.

### Fallback gracioso

Se variáveis obrigatórias do provider estiverem ausentes ou inválidas:
1. **Avisar** o usuário em pt-BR indicando qual variável falta
2. **Sugerir** `/meta/setup-integration` para reconfigurar
3. **Não inventar** valores nem assumir outro provider

---

## 🐙 Forge - Operações de Host Remoto (PR, review, CI, Release)

Assim como o Task Manager, o **forge** (host de código remoto) é abstraído via **SDAAL** em `.claude/utils/forge/` — adapter-irmão do task-manager. Comandos `/git/*` e `/engineer/pr` **nunca** chamam `gh`/API do host diretamente; passam pelo adapter (integrations.md §9).

**Fronteira**: o adapter cobre **só host remoto** (PR, review, CI/checks, Release). Git local (branch, merge, tag, **push**) é `git` direto, orientado pelo motor GitFlow ([gitflow-patterns.md](docs/knowledge-base/frameworks/gitflow-patterns.md)).

### Mapa Provider → Variáveis → Transporte → Adapter

| Provider | Variáveis | Transporte | Adapter doc |
|----------|-----------|------------|-------------|
| **`github`** | `GH_TOKEN` ou `GITHUB_TOKEN` (ou `gh auth login`) | `cli` (default, `gh`) · `api` (REST fallback) | `.claude/utils/forge/adapters/github.md` |
| **`gitlab`** / **`bitbucket`** | — | — | 🔜 costura pronta (não implementado) |
| **`none`** | — | — | NoForgeAdapter (modo local; push funciona, PR/CI degradam) |

- `FORGE_PROVIDER` (default: detecta pelo remote `origin`) e `FORGE_TRANSPORT` (`cli` default | `api`) no `.env`.
- **Divergência intencional vs Task Manager**: forge default = `cli` (a CLI `gh` embute auth/paginação/rate-limit e é o caminho idiomático do Claude Code); task-manager default = `api`. Ver `forge/factory.md`.
- Fallback gracioso idêntico: variável ausente → avisar em pt-BR + sugerir `/meta:setup-integration`; nunca inventar.

---

## 📝 Diretrizes de Linguagem

A skill **`language-standards`** é a **autoridade canônica** (alinhada à meta-spec [`code-standards.md`](docs/meta-specs/code-standards.md)). Resumo:

- **Chat, comentários, instruções, documentação, READMEs, mensagens ao usuário**: Português brasileiro (pt-BR)
- **Código, variáveis, funções, nomes de arquivo/branch**: Inglês
- **Commits**: **prefixo** Conventional em inglês (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:` …) + **assunto e corpo em pt-BR** — ex.: `docs(kg): o radar reconstrói a escada de Elenxo`. O prefixo é contrato de máquina; o assunto é narrativa de decisão (ver [`code-standards.md §3.4`](docs/meta-specs/code-standards.md))
- **Branches**: Inglês (`fix/inventory-drift`, `chore/onion-saneamento`)
- **Logs e debugging**: Inglês

---

## 🛠️ Padrões Técnicos

### Estrutura de Arquivos
- Comandos: `.claude/commands/` organizados por categoria
- Agentes: `.claude/agents/<categoria>/` com YAML header + Markdown
- Sessões: `.claude/sessions/<feature>/` para contexto de desenvolvimento
- Abstração task manager: `.claude/utils/task-manager/`
- **Spec as Code** (documentação estruturada):
  - Meta Specs (L0 — constituição): `docs/meta-specs/`
  - Business Context: `docs/business-context/` (gerado por `/docs:build-business-docs`)
  - Technical Context: `docs/technical-context/` (gerado por `/docs:build-tech-docs`)
  - Knowledge Bases: `docs/knowledge-base/` (gerado por `/meta:create-knowledge-base`)

### Padrões de Código
- Siga convenções estabelecidas de cada linguagem/framework
- Priorize legibilidade e manutenibilidade
- Use type hints quando disponível
- Documente funções complexas

### Agentes Especializados (mais usados)
- `@onion` — orquestrador master / ponto de entrada
- `@product-agent` — gestão estratégica de produto (qualquer task manager)
- `@task-specialist` — decomposição agnóstica de tasks
- `@jira-specialist` — Jira REST API v3/v2, JQL, ADF, transitions, bulk
- `@clickup-specialist` — ClickUp MCP, formatação Unicode, custom fields
- `@claude-code-specialist` — IDE/workspace/configuração Claude Code
- `@react-developer` / `@nodejs-specialist` — desenvolvimento frontend/backend
- `@code-reviewer` — review prático de código
- `@test-engineer` / `@test-agent` — testes unitários e estratégia
- `@metaspec-gate-keeper` — validação de conformidade arquitetural

---

## 🎨 Formatação por Provider

A formatação de descrições e comentários **muda conforme o provider ativo**.

### Jira Cloud (`TASK_MANAGER_PROVIDER=jira` + REST v3)
- **Descrições e comments**: obrigatoriamente em **ADF (Atlassian Document Format)** — JSON estruturado
  ```json
  { "type": "doc", "version": 1, "content": [
    { "type": "heading", "attrs": { "level": 2 }, "content": [{ "type": "text", "text": "Objetivo" }] },
    { "type": "paragraph", "content": [{ "type": "text", "text": "..." }] }
  ]}
  ```
- **Workflow-aware**: nunca setar `status` direto — sempre `POST /issue/{key}/transitions`
- **Bulk**: usar `POST /rest/api/3/issue/bulk` (até 50/req) para >5 issues
- **Search**: `POST /rest/api/3/search/jql` com `nextPageToken` (o antigo `/search` foi removido em maio/2025)
- **Referência**: `@jira-specialist` (`.claude/agents/development/jira-specialist.md`)

### Jira Server/DC (`JIRA_API_VERSION=2`)
- Descrições em **wiki markup** ou plain text (string, não JSON)
- Search via `GET /rest/api/2/search` com `startAt`

### ClickUp (`TASK_MANAGER_PROVIDER=clickup`)
**Estratégia dual:**

- **📋 Task Descriptions (`markdown_description`)**: Markdown nativo
  - Use: `## Headers`, `| Tabelas |`, `**Bold**`, `- Listas`
  - Quando: `create_task`, `update_task` descriptions
  - Templates: `.claude/commands/common/prompts/clickup-patterns.md` — §"Task Descriptions"

- **💬 Task Comments (`commentText`)**: Formatação visual Unicode
  - Use: `━━━`, `∟`, `▶`, `◆`, `✅`
  - Quando: `create_task_comment`, progress updates, PR comments
  - **Obrigatório**: timestamp + status em todos os comments
  - **Estrutura**: Header + separador + conteúdo + footer
  - Templates: `.claude/commands/common/prompts/clickup-patterns.md` — §"Task Comments"

### Asana / Linear
- Asana: descrição em HTML notes (subset) ou plain text
- Linear: Markdown nativo (suporte rico)
- Consulte o adapter doc correspondente em `.claude/utils/task-manager/adapters/`

---

## 🔗 Princípios de Integração com Task Manager
- **Sincronização contínua**: tasks no provider sempre refletem o estado real do trabalho
- **Tags/labels** apropriadas para organização (`bug`, `feature`, `tech-debt`, etc.)
- **Atualização de progresso em tempo real** via comments/transitions
- **Comentar mudanças importantes** (PR aberto, blocker, decisão técnica) na própria task
- **Bulk-first** quando operar em lote (Jira `/issue/bulk`, ClickUp bulk endpoints) — evita N+1 calls

---

## ⚡ Performance e Produtividade
- Minimize arquivos irrelevantes com `.claudeignore`
- Use configurações otimizadas de context window
- Prefira chunks menores para melhor performance
- Configure API keys apropriadas para models
- **Field selection**: ao buscar issues, especifique apenas campos necessários (`fields=summary,status,assignee`) — reduz payload em 70%+

---

## 📚 Documentação
- Mantenha documentação sincronizada em `docs/onion/`
- Use exemplos práticos e casos de uso reais
- Estruture informação para consumo por IA
- Inclua troubleshooting para problemas comuns
- KB de referência: `docs/knowledge-base/concepts/task-manager-abstraction.md`

---

## 🧪 Testes e Qualidade
- Inclua testes para funcionalidades críticas
- Valide mudanças arquiteturais com `@metaspec-gate-keeper`
- Use linting e formatting automático
- Mantenha cobertura de testes adequada

---

## 🐕 Evolução do Core — Dogfood é o padrão master

Toda mudança no core do Onion se valida **rodando o artefato de verdade** — não só plano/lint/spec. Aprenda com o que o uso revela e **resolva no mesmo loop** (fix → re-dogfood), testando modo-de-falha (não só happy-path) e tratando veredito de revisor/subagente como hipótese a verificar com evidência. O gate mecânico (`.claude/validation/`: lint + selftest + inventory) é o dogfood determinístico; para o resto, **invoque o artefato e observe**. Doutrina canônica (com evidência e o encaixe no loop de auto-evolução): [`docs/knowledge-base/concepts/onion-dogfooding-doctrine.md`](docs/knowledge-base/concepts/onion-dogfooding-doctrine.md).

---

## 🚀 Deployment
- Siga fluxos `/engineer/*` para desenvolvimento
- Use feature branches para mudanças
- Mantenha commits atômicos e descritivos
- Documente breaking changes

---

Lembre-se: O Sistema Onion é sobre **eficiência**, **qualidade** e **automação inteligente**. Sempre detecte o provider ativo antes de operar com tasks — o mesmo comando funciona em Jira, ClickUp, Asana ou Linear quando o roteamento respeita o `.env`.
