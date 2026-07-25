---
title: Guia de Navegação do Codebase — Sistema Onion (core)
date: 2026-07-25
---

# Guia de Navegação do Codebase — Sistema Onion (core)

> **Escopo**: este arquivo cobre o **CORE** do Sistema Onion — o framework template
> que vive em `.claude/` deste repositório (`onion-evolve`). Não é um app com API;
> é um conjunto de comandos/agentes/skills/scripts que o Claude Code executa. Por
> isso as seções tradicionais "API Specification" e "Business Logic" **não se
> aplicam** aqui (ficam vazias por design — o core não expõe endpoints nem regras
> de negócio de domínio; quem tem isso é o *projeto-alvo* que adota o framework).
>
> **SSOT de contagens**: todo número de comandos/agentes/skills/KBs citado abaixo
> vem de [`docs/onion/inventory.md`](../../onion/inventory.md), gerado por
> `.claude/validation/inventory.sh` a partir do filesystem (nunca digitado à mão).
> Se este arquivo e o inventory divergirem, **o inventory vence** — rode
> `/meta:inventory` para resincronizar.

---

## 1. Estrutura de Diretórios (visão de topo)

```
onion-evolve/
├── .claude/                    # o FRAMEWORK propriamente dito (o "produto")
│   ├── commands/                # 99 comandos invocáveis, 10 categorias
│   ├── agents/                  # 51 agentes especializados, 9 categorias
│   ├── skills/                  # 10 skills (Claude Code-nativas)
│   ├── utils/                   # abstrações SDAAL (task-manager, forge, ...)
│   ├── validation/               # scripts determinísticos (lint, inventory, kg-radar...)
│   ├── hooks/                    # hooks de ciclo de vida de sessão (SessionStart, PreCompact...)
│   ├── sessions/                 # sessões de trabalho persistentes (engineer/plan→pr-update)
│   └── settings.json              # registro dos hooks + permissions
├── docs/                        # Spec as Code (documentação estruturada, L0→L4)
│   ├── meta-specs/                # L0 — constituição (architecture, code-standards, integrations, agents, commands)
│   ├── knowledge-base/            # 87 KBs (conceitos/frameworks/padrões, técnica)
│   ├── onion/                     # documentação operacional do próprio framework (SSOT, guias, grafo)
│   ├── evolution/                 # co-evolução core↔adotantes (inbox/outbox/federation/rfc)
│   ├── business-context/          # spec-as-code de negócio (gerado por /docs:build-business-docs)
│   ├── technical-context/         # spec-as-code técnico (ESTE arquivo vive aqui)
│   ├── compliance-context/        # spec-as-code de compliance (gerado por /docs:build-compliance-docs)
│   ├── design-context/            # spec-as-code de identidade visual (gerado por /design:identity)
│   ├── analysis/, discussions/, applying/, materials/, sdaal/  # artefatos de trabalho e pesquisa
│   └── INDEX.md                   # índice raiz de docs/
└── CLAUDE.md                    # regras de projeto que o Claude Code lê a cada sessão
```

**Fonte**: listagem direta de `.claude/` e `docs/` (comando `ls`, 2026-07-25).

---

## 2. Comandos — 99 invocáveis em 10 categorias

Contagem por categoria (SSOT [`docs/onion/inventory.md`](../../onion/inventory.md), regenerada por
`.claude/validation/inventory.sh` — contrato: "comando invocável" = `.md` em
`.claude/commands/` exceto `common/` e `README.md`, `.claude/validation/inventory.sh:14-15`):

| Categoria | Path | Comandos |
|-----------|------|---------:|
| `meta/` | `.claude/commands/meta/` | 33 |
| `product/` | `.claude/commands/product/` | 21 |
| `engineer/` | `.claude/commands/engineer/` | 12 |
| `docs/` | `.claude/commands/docs/` | 11 |
| `validate/` | `.claude/commands/validate/` (inclui subpastas `collab/`, `qa-points/`, `test-strategy/`) | 6 |
| `git/` | `.claude/commands/git/` | 6 |
| `test/` | `.claude/commands/test/` | 3 |
| `design/` | `.claude/commands/design/` | 2 |
| `quick/` | `.claude/commands/quick/` | 1 |
| `development/` | `.claude/commands/development/` | 1 |
| _root_ | `onion.md`, `warm-up.md`, `catch-up.md` | 3 |
| **Total** | | **99** |

`.claude/commands/common/` **não conta** como categoria — guarda fragmentos
compartilhados (`common/templates/`, `common/prompts/`) reusados via referência
pelos comandos reais (ex.: `common/templates/technical-context-template.md`, a
base deste próprio arquivo).

**Comandos-chave por dimensão** (confirmado por leitura de `.claude/commands/*/README.md`):
- `product/`: `collect → refine → spec → feature` (descoberta a backlog)
- `engineer/`: `plan → start → work → pre-pr → pr → pr-update` (planejamento a entrega, GitFlow)
- `git/`: `flow` é o dispatcher único do ciclo feature/release/hotfix × start/publish/finish
- `meta/`: `inventory` (regenera a SSOT de contagens), `adopt` (instala o framework em outro repo),
  `create-command`/`create-agent`/`create-skill` (meta-geração), `evolve` (auto-auditoria), `kg` (KG de investigação)
- root: `onion.md` é o atalho para o agente orquestrador `@onion` (`.claude/commands/onion.md`)

---

## 3. Agentes — 51 especializados em 9 categorias

SSOT (`.claude/validation/inventory.sh:48-52`, contrato: "agente" = `.md` em
`.claude/agents/` exceto READMEs):

| Categoria | Path | Agentes |
|-----------|------|--------:|
| `development/` | `.claude/agents/development/` | 20 |
| `product/` | `.claude/agents/product/` | 9 |
| `meta/` | `.claude/agents/meta/` | 5 |
| `git/` | `.claude/agents/git/` | 5 |
| `compliance/` | `.claude/agents/compliance/` | 5 |
| `testing/` | `.claude/agents/testing/` | 3 |
| `review/` | `.claude/agents/review/` | 2 |
| `research/` | `.claude/agents/research/` | 1 |
| `deployment/` | `.claude/agents/deployment/` | 1 |
| **Total** | | **51** |

Cada agente é um `.md` com YAML header obrigatório (`name`, `description`,
`model`, `tools`, `category`, `expertise`, `related_agents`, ...) — exemplo lido
em `.claude/agents/meta/onion.md:1-24`. O agente `@onion` é o orquestrador
master, citado no header como tendo "conhecimento completo de 51 agentes e 99
comandos" (`.claude/agents/meta/onion.md:4`) — ou seja, o próprio agente-âncora
referencia os totais da SSOT.

---

## 4. Skills — 10 em `.claude/skills/`

Contrato: "skill" = diretório em `.claude/skills/` (`.claude/validation/inventory.sh:56-58`).
Listagem direta (`ls .claude/skills/`, 2026-07-25):

`language-standards`, `onion` (orquestrador), `onion-compliance-context`,
`onion-engineering-context`, `onion-onboarding`, `onion-orchestration`,
`onion-patterns`, `onion-product-context`, `onion-validation`, `onion-wizard`.

> Nota de frescor: `docs/onion/index.md:14` ainda lista "5 skills" — está **stale**
> frente à SSOT atual (10). Não corrigir manualmente; rodar `/meta:inventory` +
> `/docs:build-index onion` propaga o número certo.

---

## 5. Utils — abstrações SDAAL (`.claude/utils/`)

Padrão **SDAAL** (Service/Data Access Abstraction Layer) — comandos/agentes nunca
chamam a API de um provider concreto direto; sempre passam por um adapter
agnóstico. Diretórios em `.claude/utils/` (listagem direta):

`adopt/`, `co-evolution/`, `de-identification/`, `design-sink/`, `design-source/`,
`federation-transport/`, `forge/`, `guardrails/`, `marketplace/`, `scope/`,
`task-manager/`, `vertical/`, mais arquivos soltos de padrões (`c4-*.md`,
`date-time-standards.md`).

**Arquivo-âncora**: `.claude/utils/scope/compose-settings.sh` — compõe um
`settings.json` efetivo a partir de N camadas de escopo
(`framework → empresa → time → pessoa`), com merge never-clobber type-aware
(objetos recursam, arrays unem+dedup, escalares last-wins) e modo
`--show-scope`/`--provenance` que responde por-chave qual camada setou cada
valor (RFC-0005, `.claude/utils/scope/compose-settings.sh:3-24`). Sem `jq` →
falha graciosa (`exit 3`); invariante de proveniência violada → `exit 4`.

O par `task-manager/` + `forge/` implementa o roteamento por provider descrito
em CLAUDE.md (Jira/ClickUp/Asana/Linear para tasks; GitHub/GitLab/Bitbucket para
host remoto), cada um com `adapters/<provider>.md` e um `factory.md`.

---

## 6. Validation — mecanismo determinístico (`.claude/validation/`)

Scripts sem LLM, mesma entrada (filesystem/git) → mesma saída. Dois são as
**âncoras de identidade/inventário** do framework:

### `inventory.sh` — SSOT do inventário canônico
- Propósito declarado: "Computar o inventário canônico (comandos, agentes,
  skills, KBs) DIRETAMENTE do filesystem — nenhum número é digitado à mão"
  (`.claude/validation/inventory.sh:5-7`).
- Uso: `bash .claude/validation/inventory.sh [--markdown|--json|--env]` —
  `--markdown` (default) gera a tabela de `docs/onion/inventory.md`; `--json`
  para consumo por ferramentas; `--env` para o lint sourçar
  (`.claude/validation/inventory.sh:9-12`).
- Contrato de contagem documentado inline (`.claude/validation/inventory.sh:14-17`):
  comando = `.md` em `commands/` exceto `common/`+READMEs; agente = `.md` em
  `agents/` exceto READMEs; skill = diretório em `skills/`; KB = `.md` em
  `docs/knowledge-base/` exceto `index.md` (README.md de categoria **conta**).
- Invocado via `/meta:inventory` — deve rodar após criar/remover qualquer
  comando/agente/skill/KB para manter `docs/onion/inventory.md` (e tudo que
  deriva dele, como CLAUDE.md e `docs/onion/index.md`) sincronizado.

### `onion-version.sh` — SSOT de identidade/proveniência do framework
- Propósito: emitir a identidade do framework **derivada do git** (commit curto
  + data do commit), sem semver formal — "preserva architecture.md §6.1 ('versão
  implícita no main')" (`.claude/validation/onion-version.sh:3-4`).
- No repo-fonte (este), a identidade é lida ao vivo do git — nunca há stamp
  committado (evita auto-referência arquivo↔commit e churn a cada commit).
- Em repos **adotados**, `/meta:adopt` escreve `.claude/.onion-version` com essa
  identidade + proveniência (`adopted_from`, `adopted_at`, `mode`). A presença
  desse arquivo é a evidência de que o repo é um adotante, não a fonte —
  `role` é lido de `.claude/.onion-version` quando presente, senão
  default `"source"` (`.claude/validation/onion-version.sh:44-50`).
- Uso: `bash .claude/validation/onion-version.sh [--yaml|--json]`.
- Consumidores citados no cabeçalho: `/meta:adopt`, a federação
  (`multi-repo-federation.md`), CI (`.claude/validation/onion-version.sh:19-21`).

Outros scripts notáveis em `.claude/validation/`: `lint-selftest.sh` (exercita
os próprios helpers, incl. `compose-settings.sh`), `kg-radar.sh`/`kg-view.sh`
(radar determinístico dos Knowledge Graphs `.kg.yaml` de investigação),
`federation-*.sh` (contrato/inbox/status de federação entre core e adotantes),
`graph.sh` (grafo de dependências docs↔código), `rules-registry.sh`/
`lint-rules.md` (registro das regras de lint do framework).

---

## 7. Hooks — ciclo de vida de sessão (`.claude/hooks/`)

Registrados em `.claude/settings.json:20+` (bloco `hooks`), disparados em
eventos do Claude Code:

| Hook | Evento | Propósito (linha-fonte) |
|------|--------|--------------------------|
| `task-manager-provider-hook.sh` | SessionStart | Anuncia o `TASK_MANAGER_PROVIDER` ativo, consultando o **ambiente primeiro** (mesma fonte do adapter) — corrige o hook antigo que só lia `.env` e podia divergir do runtime (`.claude/hooks/task-manager-provider-hook.sh:3-28`) |
| `worklog-capture-session.sh` | SessionStart | Captura o `session_id` nativo do Claude Code para o worklog |
| `co-evolution-inbox-check.sh` | SessionStart | "you have mail" bidirecional — avisa sinais pendentes de co-evolução core↔adotantes |
| `session-beacon-hook.sh up/refresh/down` | SessionStart / periódico / SessionEnd | Farol de presença de sessão git-invisível + aviso de colisão (`.claude/hooks/session-beacon-hook.sh:2`) |
| `worklog-precompact-breadcrumb.sh` | PreCompact | Grava uma migalha antes da compactação (a saída do PreCompact em si é ignorada pós-compactação) |

Fonte: `.claude/settings.json` linhas 20-80 (mapeamento hook↔evento) cruzado
com os comentários de cabeçalho de cada script em `.claude/hooks/`.

---

## 8. Fluxo de dados / integrações

O core não tem "banco de dados" — o estado vivo é o **filesystem do repo +
git** e as integrações externas são todas mediadas por abstração SDAAL:

```
usuário (chat Claude Code)
   │
   ├─▶ comando (.claude/commands/<categoria>/<nome>.md)
   │      │  YAML header define allowed-tools, parameters, related_agents
   │      ▼
   ├─▶ agente delegado (.claude/agents/<categoria>/<nome>.md)
   │      │  lê skills (.claude/skills/) para padrões/convenções
   │      │  lê contexto vivo (docs/{business,technical,compliance}-context/)
   │      ▼
   ├─▶ abstração SDAAL (.claude/utils/{task-manager,forge}/)
   │      │  resolve provider ativo via .env → delega ao especialista
   │      │  (@jira-specialist, @clickup-specialist, ...) OU chama o adapter genérico
   │      ▼
   └─▶ provider externo (Jira/ClickUp/Asana/Linear · GitHub/GitLab/Bitbucket)
```

Persistência local relevante:
- `.claude/sessions/<feature>/` — sessões de trabalho retomáveis dos workflows
  faseados `product/collect→feature` e `engineer/plan→pr-update`
- `docs/evolution/{inbox,outbox,inbound}/` — mensagens de co-evolução entre o
  core e repos adotantes (doc-bridge local, sem commit cross-repo)
- `*.kg.yaml` — Knowledge Graphs de investigação (schema em
  `.claude/skills/onion-validation`/`meta:kg`), lidos pelo `kg-radar.sh`

Integrações externas são **sempre** opt-in via `.env` (`TASK_MANAGER_PROVIDER`,
`FORGE_PROVIDER`) — nunca hardcoded a um provider específico, conforme CLAUDE.md
§"Task Manager - Detecção e Roteamento" e §"Forge - Operações de Host Remoto".

---

## 9. `docs/` — Spec as Code (onde a documentação gerada mora)

| Diretório | Conteúdo | Gerado por |
|-----------|----------|------------|
| `docs/meta-specs/` | L0 — constituição (`architecture.md`, `code-standards.md`, `integrations.md`, `agents.md`, `commands.md`) | mantido à mão, é a autoridade máxima |
| `docs/knowledge-base/` | 87 KBs em 9 subcategorias (`concepts/` é a maior, 48 arquivos de conteúdo) | `/meta:create-knowledge-base` |
| `docs/onion/` | Documentação operacional do próprio framework: `inventory.md` (SSOT), `getting-started.md`, `graph.md`, `federation-map.md`, `agents-reference.md`, `commands-guide.md`, entre outros | mistura gerado (`inventory.md`) + mantido à mão |
| `docs/evolution/` | Co-evolução core↔adotantes: `inbox/`, `outbox/`, `inbound/`, `federation/`, `rfc/`, `research/` | fluxo `/meta:co-*` e `/meta:federation-*` |
| `docs/business-context/` | Spec-as-code de negócio (`01-customer` a `04-operations`) | `/docs:build-business-docs` |
| `docs/technical-context/` | Spec-as-code técnico — **este arquivo** | `/docs:build-tech-docs` |
| `docs/compliance-context/` | Spec-as-code de compliance | `/docs:build-compliance-docs` |
| `docs/design-context/` | Tokens/identidade visual (W3C/DTCG) | `/design:identity` |

Estrutura de `docs/technical-context/` conforme convenção do próprio comando
gerador (`.claude/commands/docs/build-tech-docs.md:148-160`, que **tem
precedência** sobre `common/templates/technical-context-template.md` quanto a
nomes de arquivo — kebab-case minúsculo obrigatório):

```
docs/technical-context/
├── index.md
├── 01-core/            (project-charter.md + adr/)
├── 02-ai-context/       (ai-development-guide.md + codebase-guide.md ← este arquivo)
├── 03-domain/           (business-logic.md, api-specification.md — N/A para o core)
└── 04-workflow/         (contributing.md, troubleshooting.md, architecture-challenges.md)
```

> **Por que `03-domain/` não se aplica ao core**: o core do Onion é um
> *framework template*, não um sistema com regras de negócio de domínio nem
> endpoints HTTP. "Lógica de negócio" e "API" são propriedades do
> *projeto-alvo* que adota o framework — nele sim `business-logic.md` e
> `api-specification.md` fazem sentido. Aqui, ficam de fora por design, não por
> omissão.

---

## 10. Como manter este arquivo sincronizado

Este arquivo é **greenfield** (o core nunca havia dogfoodado o próprio
technical-context antes de 2026-07-25). Ao regenerar:

1. Números de comandos/agentes/skills/KBs → sempre reler
   `docs/onion/inventory.md`, nunca copiar deste arquivo sem checar drift.
2. Estrutura de diretórios → reconferir com `ls .claude/` e `ls docs/`, pois
   novas categorias/utils podem ter sido criadas.
3. Se `.claude/validation/inventory.sh` ou `.claude/validation/onion-version.sh`
   mudarem de contrato (novas exclusões, novo formato), atualizar as seções 2,
   3, 6 correspondentes.
