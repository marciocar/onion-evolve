---
title: Meta-spec — Padrões para Comandos do Sistema Onion
date: 2026-06-17
version: 1.5.0
level: L0
status: active
gate-keeper: "@metaspec-gate-keeper"
---

# Meta-spec — Padrões para Comandos do Sistema Onion

## Propósito

Define os padrões imutáveis (L0) que **todos os comandos** em `.claude/commands/` devem seguir. Inclui o conceito **invariante** de workflows faseados retomáveis, mecanismo que distingue o Onion de coleções de comandos avulsos.

Aplica-se ao **Sistema Onion**, não ao projeto-alvo onde o Onion é instalado.

Referências relacionadas:

- [agents.md](./agents.md) — padrões para agentes
- [architecture.md](./architecture.md) — estrutura de diretórios e dependências
- [code-standards.md](./code-standards.md) — padrões de código e idioma
- [integrations.md](./integrations.md) — padrões para integrações

---

## 1. Estrutura obrigatória

Todo comando em `.claude/commands/<categoria>/<nome>.md` deve conter:

### 1.1 Frontmatter YAML

```yaml
---
description: <descrição em uma linha — aparece na lista de comandos>
name: <slug kebab-case — opcional; quando presente, deve casar o nome do arquivo>
allowed-tools: [<tools permitidas, ou omitir para herdar contexto>]
argument-hint: <hint opcional sobre argumentos esperados>
---
```

- `description` é obrigatório
- `name` opcional; quando presente, **deve** ser kebab-case (ver §8) e casar o nome do arquivo
- `allowed-tools` opcional, mas recomendado para comandos que executam ações sensíveis
- `argument-hint` opcional, melhora UX da invocação
- **Schema aberto**: campos organizacionais adicionais (`model`, `category`, `tags`, `version`, `updated`) são **permitidos** e não invalidam o comando — a regra normativa cobre apenas os campos acima

### 1.2 Corpo do comando

Após o frontmatter:

```markdown
# <Título descritivo do comando>

## Objetivo
<O que este comando entrega>

## Quando usar
<Gatilhos, casos de uso típicos>

## Etapas
<Passo a passo executável>

## Saída esperada
<Artefatos, mudanças, output ao usuário>

## Exemplos
<Invocações reais>
```

Comandos curtos (< 50 linhas) podem omitir seções não aplicáveis, mas **devem manter frontmatter + título + propósito**.

### 1.3 Convenção de `allowed-tools` (escopo mínimo)

Comandos que executam **ações sensíveis** (git, escrita de arquivos, operações
de Task Manager) devem declarar `allowed-tools` escopado ao mínimo necessário,
no formato de regras de permissão do Claude Code:

```yaml
allowed-tools: Bash(git *) Bash(gh *) Read Edit Write Grep Glob
```

Diretrizes:

- Escopar pelo **uso real observado** — restritivo demais quebra o comando.
- Para Bash, prefira prefixos específicos (`Bash(git *)`) a `Bash(*)`.
- Detecção de provider via `.env`: `Bash(cat .env*)`.
- Ferramentas MCP do provider ativo são herdadas do agente delegado
  (`@clickup-specialist`, etc.) — o comando não precisa enumerá-las.
- Comandos puramente informativos (READMEs, ajuda) podem omitir.

Comandos sensíveis canônicos que **devem** declarar `allowed-tools`:
`engineer/pr`, `engineer/start`, `engineer/work`, `product/task`,
`git/fast-commit`.

> Automação a nível de evento (hooks) vive em `.claude/settings.json`, não no
> frontmatter — ver `architecture.md` e `integrations.md`.

---

## 2. Categorias válidas

Comandos devem residir em uma das categorias abaixo. Categorias com asterisco representam **as três dimensões peer do ciclo Onion**.

| Categoria | Função | Volume típico |
|---|---|---|
| `product/` (*) | Discovery, especificação, decomposição de tarefas, branding, reuniões | 20+ |
| `engineer/` (*) | Planejamento e implementação faseada de features | 10+ |
| `docs/` | Geração e validação de documentação (incluindo `/docs:build-compliance-docs` da dimensão compliance) | 10+ |
| `git/` | GitFlow, feature/release/hotfix, code review | 10+ |
| `meta/` | Criação de comandos/agentes/skills/KBs, integração | 8+ |
| `common/` | Templates e prompts compartilhados | 8+ |
| `validate/` | Validação de testes, QA, workflows colaborativos | 4+ |
| `test/` | Estratégias de teste (unit, integration, e2e) | 3 |
| `development/` | Comandos de desenvolvimento específicos | 1+ |
| `design/` | Vertical de design — identidade visual como spec-as-code (**INCUBAÇÃO**: categoria provisória; `design-context/` é 4º peer candidato, não cravado — ver ADR design-peer-promotion) | 1+ |
| `quick/` | Análises pontuais rápidas | 1+ |
| (root) | `onion.md` e `warm-up.md` — pontos de entrada | 2 |

Categorias podem ter subdiretórios quando agrupam variantes (ex: `validate/test-strategy/`, `validate/qa-points/`). Subdiretórios são para **variantes genuinamente distintas**; **não** para fases/verbos de um mesmo fluxo — estas devem ser argumentos de um dispatcher (ver §4.1, padrão `/git:flow`).

---

## 3. Workflows faseados — INVARIANTE DO FRAMEWORK

**Princípio**: o Onion implementa workflows faseados como **mecanismo central**. Múltiplos comandos cobrindo fases distintas de um mesmo fluxo, com estado retomável persistido em `.claude/sessions/`, são **valor de design**, não duplicação.

### 3.1 Workflows canônicos

Os **dois workflows abaixo são invariantes** do framework. Devem ser preservados intactos. Qualquer proposta de fusão deve ser rejeitada por `@metaspec-gate-keeper`.

**Workflow de Engenharia** (6 fases):

```
engineer/plan → engineer/start → engineer/work → engineer/pre-pr → engineer/pr → engineer/pr-update
```

- `plan` — analisa requisitos e cria plano estruturado
- `start` — cria sessão de desenvolvimento e analisa tasks
- `work` — retoma sessão e identifica próxima fase
- `pre-pr` — valida padrões e qualidade antes do PR
- `pr` — cria Pull Request com GitFlow e sync
- `pr-update` — atualiza PR existente

**Workflow de Produto** (6 fases):

```
product/collect → product/refine → product/spec → product/task → product/estimate → product/feature
```

- `collect` — coleta ideias de features ou bugs
- `refine` — refina via perguntas de esclarecimento
- `spec` — cria especificação a partir de requisitos
- `task` — decompõe em tasks/subtasks/action items
- `estimate` — aplica framework de story points
- `feature` — cria task no gerenciador configurado

### 3.2 Regras para workflows faseados

1. Cada fase deve ter **input claro** (estado da sessão ou argumentos), **output claro** (próximo estado da sessão) e ser **invocável isoladamente** quando o estado permite
2. Estado entre fases é persistido em `.claude/sessions/<feature>/`
3. Fases nomeadas explicitamente, sem ambiguidade de ordem
4. Novos workflows similares devem seguir o mesmo padrão (sessões persistentes, fases nomeadas, retomável)
5. **Proibido fundir fases** de workflow ativo sem justificativa formal aprovada via PR específico para esta meta-spec

### 3.3 Padrão para identificar workflow faseado

Características de um comando que faz parte de workflow faseado:

- Vive em categoria que representa dimensão do ciclo (`product/`, `engineer/`)
- Lê ou escreve estado em `.claude/sessions/`
- Tem nome que sugere fase explícita (verbo de ação temporal: `start`, `work`, `pre-pr`, `pr-update`)
- Documenta a posição no ciclo no corpo do comando

---

## 4. Convenção de naming

- **Slug** (nome do arquivo): kebab-case (`pre-pr.md`, `build-tech-docs.md`)
- **Path completo**: `.claude/commands/<categoria>/<slug>.md` ou `.claude/commands/<categoria>/<subcategoria>/<slug>.md`
- **Invocação**: usuário invoca com `/<categoria>:<slug>` ou `/<categoria>/<subcategoria>:<slug>`

### 4.1 Política de duplicação de nomes entre categorias

Os nomes abaixo aparecem em múltiplas categorias por razões funcionais legítimas. Esta política torna a regra explícita.

| Nome | Categorias | Categoria canônica | Variantes em outras categorias |
|---|---|---|---|
| `README` | `product/`, `git/`, `common/`, `docs/` | Específico por categoria (não há canônico) | Cada README descreve a categoria que o contém |
| `warm-up` | `product/`, `engineer/`, root (`warm-up.md`) | root (`/warm-up`) | `product/warm-up`, `engineer/warm-up` são specializations contextuais |
| `start` | `engineer/` | `engineer/start` (sessão de desenvolvimento) | O ciclo de vida GitFlow **não** usa mais `git/feature/start` etc. — virou o dispatcher `/git:flow <tipo> <ação>` (consolidado em 2026-06-13) |
| `finish` | — | n/a | Ações GitFlow `start`/`publish`/`finish` são **argumentos** de `/git:flow`, não comandos/subpastas distintos |
| `help` | `git/`, `docs/` | Específico por categoria | Ajuda contextual da categoria |
| `estimate` | `product/`, `validate/qa-points/` | `product/estimate` (story points de feature) | `validate/qa-points/estimate` é QA story points |
| `plan` | `engineer/`, `product/light-arch` (similar) | `engineer/plan` (planejamento de implementação) | `product/light-arch` é design de arquitetura leve |
| `check` | `product/`, `product/task-check` | `product/check` (verificação contra meta-specs) | `product/task-check` é verificação de task |

**Regra geral**:

- Quando houver canônico, novos comandos com nome curto devem usar o canônico ou nome explícito
- Quando não houver canônico, sempre invocar com path completo (`/<categoria>:<slug>`)
- Renomes para resolver ambiguidade devem usar aliases temporários para não quebrar invocações existentes

### 4.2 Padrão dispatcher para verbos de um mesmo fluxo

Quando N comandos representam **verbos/fases de um mesmo fluxo** que não é workflow faseado retomável (§3), eles devem ser **um dispatcher arg-driven**, não N arquivos/subpastas. Exemplo canônico: o ciclo de vida GitFlow virou `/git:flow <tipo> <ação>` (`feature`/`release`/`hotfix` × `start`/`publish`/`finish`), consolidando 7 arquivos + 3 subpastas num único `git/flow.md` (2026-06-13). Critério (ver `docs/knowledge-base/concepts/onion-modernization-doctrine.md`): mesma intenção + sem estado faseado retomável + lógica canônica numa KB citável.

> **Distinção da §3**: workflows faseados (`engineer/*`, `product/*`) são **invariantes** — cada fase é comando autônomo com estado de sessão; **não** viram dispatcher. O padrão dispatcher aplica-se a verbos sem estado retomável (GitFlow).

> **Migração de caminho**: a consolidação num dispatcher altera os caminhos de invocação (ex.: `/git:feature:start` → `/git:flow feature start`). Documente o mapeamento antigo→novo no próprio dispatcher (ver `git/flow.md` §Migração); por ser framework interno (não distribuído), aceita-se a quebra documentada em vez de N stubs de alias.

---

## 5. Limites de tamanho

| Limite | Linhas | Tratamento |
|---|---|---|
| Recomendado | até 500 | OK |
| Soft warning | 500 – 800 | Considerar modularização |
| Hard limit | > 800 | Refatoração obrigatória antes de merge |

Comandos que excederem 800 linhas devem extrair partes para:

- Templates em `.claude/commands/common/templates/`
- Prompts em `.claude/commands/common/prompts/`
- Knowledge bases em `docs/knowledge-base/`
- Sub-comandos referenciados

### 5.1 Isenções (não são comandos invocáveis)

O limite acima aplica-se a **comandos invocáveis** (`/categoria/nome`). São
**isentos** por natureza, seguindo guidance própria:

- **Fragmentos de template** em `.claude/commands/common/templates/` — são
  estruturas de referência (ex.: `business-context-template.md`,
  `technical-context-template.md`), auto-registrados como skills
  `common:templates:*` e referenciados por múltiplos agentes/comandos. Tamanho é
  inerente ao template; **não relocar** sem atualizar o registro de skill e
  todas as referências.
- **Fragmentos de prompt** em `.claude/commands/common/prompts/` — skills
  `common:prompts:*`.
- **READMEs de categoria** (`<categoria>/README.md`) — são índices; devem ser
  enxutos (apontar para comandos/KB), mas não contam como comando.

---

## 6. Modularização

Comandos podem reaproveitar:

- **Templates** em `.claude/commands/common/templates/` (estruturas reutilizáveis)
- **Prompts** em `.claude/commands/common/prompts/` (instruções compartilhadas)
- **Skills** em `.claude/skills/` (cérebro de orquestração)
- **Agentes** em `.claude/agents/<categoria>/` (delegação especializada)

Comando que duplica >50 linhas de outro comando deve refatorar para template ou prompt compartilhado.

---

## 7. Exemplos de conformidade

### Exemplo conforme (workflow faseado)

Arquivo: `.claude/commands/engineer/start.md`

- Frontmatter com `description`
- Vive em `engineer/` (dimensão de engenharia)
- Faz parte do workflow canônico
- Persiste estado em `.claude/sessions/`
- Nome reflete fase explícita

**Veredito**: `@metaspec-gate-keeper` aprova.

### Exemplo conforme (comando atômico)

Arquivo: `.claude/commands/meta/setup-integration.md`

- Frontmatter com `description` e `allowed-tools`
- Vive em `meta/` (categoria válida)
- Não faz parte de workflow faseado — função atômica clara
- Tamanho dentro do limite

**Veredito**: aprovado.

### Exemplo quase-conforme

Arquivo hipotético: `.claude/commands/validate/test-strategy/analyze.md` (1.134 linhas reais)

- Frontmatter correto
- Categoria válida
- Tamanho acima de soft warning (500), acima de hard limit (800)

**Veredito**: requer refatoração antes de próximo merge tocando este arquivo.

### Exemplo não-conforme

Arquivo hipotético: `.claude/commands/misc/MyCommand.md`

- Categoria `misc/` inválida
- Filename PascalCase em vez de kebab-case
- Sem frontmatter

**Veredito**: rejeitado.

---

## 8. Proibições explícitas

- **Proibido** fundir comandos de workflow faseado canônico (engineer/* ou product/*) sem PR específico para esta meta-spec
- **Proibido** criar categoria fora da lista válida
- **Proibido** criar comando sem frontmatter
- **Proibido** comando com `name` em formato diferente de kebab-case
- **Proibido** adicionar/alterar uma guarda determinística (regra em `lint-artifacts.sh` ou validador irmão em `.claude/validation/`) sem a fixture de failure-mode correspondente registrada no manifest do auto-teste (ver Seção 11)

---

## 9. Versionamento e mudanças

Mudanças nesta spec exigem:

1. PR específico para `docs/meta-specs/commands.md`
2. Atualização do campo `version` no frontmatter
3. Validação por `@metaspec-gate-keeper` em comandos existentes
4. Especificamente para mudança em workflows canônicos (Seção 3.1): aprovação registrada em commit message com link para issue de discussão

---

## 10. Orquestração (fan-out paralelo)

Complementa a Seção 3: enquanto workflows faseados coordenam trabalho **sequencial e retomável**, a orquestração coordena trabalho **paralelo** (fan-out → fan-in) sobre o substrato nativo do Claude Code (ferramenta `Workflow`). Doutrina, padrões canônicos e mapeamento às primitivas: [docs/knowledge-base/concepts/agent-orchestration.md](../knowledge-base/concepts/agent-orchestration.md).

### 10.1 Onde a orquestração pode residir

- **Permitido**: em `skills/*` e `commands/*` — executam no contexto principal e podem orquestrar as ferramentas `Workflow`/`Agent`.
- **Proibido**: criar um **agente** orquestrador. Por [architecture.md §4.2](./architecture.md), `agents/* → commands/*` é proibido e subagentes não devem disparar a orquestração — esta mora no nível principal. A camada canônica é a skill `onion-orchestration` + o comando `/meta:orchestrate`.

### 10.2 Regras normativas

1. **Opt-in na execução, proativo na detecção**: *executar* fan-out é explícito, nunca o comportamento default (trabalho serial dependente permanece sequencial). Mas **detectar e propor** a oportunidade de fan-out é **dever** — ao receber tarefa com sinais de elegibilidade (varredura ampla, auditoria, N itens independentes, migração mecânica, review multi-dimensão), o Claude sinaliza/propõe **antes** de planejar execução serial. Detecção ≠ execução.
2. **Independência**: só paralelizar subtarefas sem dependência cruzada de dados.
3. **Fan-in obrigatório**: todo fan-out termina em consolidação num resultado único (não N saídas soltas).
4. **Mutação — partição-primeiro, worktree só p/ sobreposição, 1 branch**: ao mutar arquivos em paralelo, o orquestrador **particiona por arquivos disjuntos** (sem corrida → dispensa worktree); usa `isolation: 'worktree'` **apenas** quando há sobreposição real ou branches independentes a fundir. A saída é **uma branch de consolidação** que entra no fluxo faseado normal (`/git:flow` ou `/engineer:pr` via forge) — **nunca** N branches persistentes contornando o gate de PR. Conflito de partição ou operação irreversível → **gate humano**. Playbook completo: [agent-orchestration.md §7](../knowledge-base/concepts/agent-orchestration.md).
5. **Verificação**: achados de alto risco passam por verificação adversarial / judge-panel antes de serem aceitos.
6. **Budget e tiers**: respeitar teto de tokens (`budget`) e model tiering (orquestrador em opus; workers em sonnet/haiku).
7. **Invariante preservada**: a orquestração paraleliza *dentro* de uma fase; **não funde** os workflows faseados canônicos da Seção 3 (`engineer/*`, `product/*`).

### 10.3 Padrões canônicos

Os seis padrões canônicos (classify-and-act, fan-out-and-synthesize, adversarial verification, generate-and-filter, tournament, loop-until-done) e seu mapeamento às primitivas `agent()`/`parallel()`/`pipeline()` são normalizados na KB de orquestração (link acima).

---

## 11. Guardas determinísticas testam a si mesmas

As guardas determinísticas do framework (`.claude/validation/lint-artifacts.sh` e validadores irmãos como `federation-contract-validate.sh`) são a primeira linha de defesa do CI. Uma guarda que silenciosamente para de funcionar — regex quebrada, allowlist larga demais — é a meta-falha "guarda parcial" aplicada às próprias guardas: nada pega, e a regressão degrada em silêncio.

### 11.1 Regra normativa

Toda guarda determinística **nova** (ou alteração de uma existente) nasce com:

1. **Fixture de failure-mode** em `.claude/validation/fixtures/`, registrada no `manifest.tsv`, isolando a regra: ao menos um caso `bad` (input ruim → guarda **deve** flagrar) e, quando houver allowlist/exceção, um caso `good`/`exempt` (input legítimo → guarda **não** flagra).
2. **Revisão independente** de prompt neutro antes do PR (ex.: `@branch-code-reviewer` ou um reviewer sem o contexto de quem escreveu a guarda) — a disciplina ad-hoc que pegou bugs reais (tool-names estilo-Cursor, MCP de provider no frontmatter, drift de contagem) vira padrão escrito.

### 11.2 Contrato executável

`.claude/validation/lint-selftest.sh` é o **contrato executável** desta regra: injeta cada fixture do manifest, roda a guarda como caixa-preta e assere o veredito real contra o esperado. Roda no CI logo após o linter (ver [ci.md](../onion/ci.md)). Uma guarda quebrada faz o selftest — e portanto o CI — falhar, em vez de degradar em silêncio. Escopo deliberadamente determinístico: não testa comportamento de LLM (coberto, não-deterministicamente, por `/meta:metaspec-validate` + `onion-review.yml`).
