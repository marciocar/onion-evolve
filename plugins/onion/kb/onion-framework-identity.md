---
title: "Onion: Identidade e Produto"
category: meta
tags:
  - identidade
  - posicionamento
  - landing-page
  - manual
  - case-studies
  - press-kit
status: reference
date: 2026-06-15
---

# Onion: Identidade e Produto

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.3.0 |
| **Data de Criação** | 2026-06-15 |
| **Última Atualização** | 2026-08-03 |
| **Categoria** | Meta |
| **Propósito** | SSOT para materiais externos: landing page, manual, estudos de caso, artigos críticos, press kit |
| **Fonte completa** | `onion-product-material-raw-2026-06.md` (interno do core) — material bruto/levantamento exaustivo onde **toda afirmação da KB é rastreável** à fonte primária citada `arquivo:seção`; é a camada de rastreabilidade sob esta síntese |

> Esta KB é a **síntese canônica**. Cada afirmação aqui é rastreável ao material bruto linkado acima, que por sua vez cita a fonte primária (`CLAUDE.md`, análises em `docs/analysis/`, KBs de conceitos). Para elaborar um material derivado, comece aqui e desça ao bruto só onde precisar de profundidade/citação literal.

---

## 1. O que é o Onion

### Pitch de 30 segundos

> **Sistema Onion é um framework template em `.claude/` que instala num repositório o ciclo completo de desenvolvimento orientado por IA — produto, engenharia e compliance — sem alterar uma linha de código do projeto-alvo.**

*(Fonte: `CLAUDE.md` — identidade canônica)*

### Pitch de 2 minutos

O Sistema Onion é um **framework de orquestração de desenvolvimento** que vive inteiramente em `.claude/` — uma pasta de configuração do Claude Code. Ao instalar o Onion num projeto, o time ganha **109 comandos invocáveis**, **51 agentes especializados de IA** e **13 skills** de orquestração, cobrindo três dimensões **peer**: produto (discovery → backlog), engenharia (planejamento → PR) e compliance (ISO 27001, SOC2, PMBOK, ISO 22301). O Onion se conecta ao gerenciador de tarefas existente (Jira, ClickUp, Asana ou Linear) via uma camada de abstração agnóstica (SDAAL) e ao host de código (GitHub; GitLab/Bitbucket têm a **costura pronta**, não implementados — o gatilho declarado é *um adotante que os use*) via adapter de forge. Não é uma CLI, não tem pacote npm, não exige mudança de stack — é configuração pura que transforma o Claude Code no cérebro orquestrador do fluxo de trabalho.

*(Fontes: `CLAUDE.md` §Inventário; `onion-review-2026-05.md` §1 — Revisão Analítica de Maio/2026, interno do core: o snapshot que consolidou a identidade canônica (framework template em `.claude/`, plataforma única Claude Code, três dimensões peer) e o abandono formal de `.onion/`/CLI standalone/v4.0; veredito "substancialmente completo em cobertura, pré-aplicável em validação")*

### Pitch de 10 minutos (técnico)

A identidade do Onion foi consolidada em **2026-05-18**, quando o framework abandonou formalmente as direções de CLI standalone, suporte multi-IDE e estrutura agnóstica `.onion/` — a aposta passou a ser **profundidade de integração com Claude Code**, não portabilidade entre IDEs. O resultado é uma arquitetura em **5 camadas** (detalhada na seção 3): comandos (workflows), agentes (especialistas), skills (orquestração de alto nível), abstrações SDAAL (task manager + forge) e documentação constitucional (meta-specs + knowledge bases + spec-as-code).

O ponto diferenciador central: o ciclo é **tri-dimensional e simétrico** — Produto, Engenharia e Compliance são **peers**, não hierarquizados. Um time pode entrar pelo `@product-agent`, pelo `/engineer:plan`, ou diretamente em `/validate:collab/three-amigos` — o framework não privilegia nenhuma dimensão, e cada uma pode evoluir e ser adotada independentemente.

*(Fontes: `CLAUDE.md` §Identidade canônica; `onion-review-2026-05.md` §2 (interno do core))*

---

## 1.5 Invenções nomeadas — o catálogo canônico

**Esta é a SSOT da lista** (o contrato que o [`/warm-up`](../../../.claude/commands/warm-up.md) declara).
Materiais derivados — o manual de adoção (`onion-adoption-manual.md` §1.3, interno do core — persona autobiográfica em 1ª pessoa "O Despertar", texto canônico do *Autobiographical Marketing*), press kit,
artigos — **citam esta tabela**; não a reescrevem ([fonte ≠ derivação](../concepts/source-vs-derivation.md)).

**Critério de entrada:** emergiu da prática (não foi projetado), **ganhou nome próprio**, e tem casa
canônica citável. Nome sem casa é órfão — entra na tabela só quando a casa existir.

| Invenção | O que é | Casa canônica | Status |
|---|---|---|---|
| **Dogfood Doctrine** | toda mudança de core se valida **rodando o artefato**; fix → re-dogfood | [`onion-dogfooding-doctrine.md`](../concepts/onion-dogfooding-doctrine.md) | ✅ ativa |
| **Modernization Doctrine** | qual padrão de refatoração aplicar sem ferir invariantes | [`onion-modernization-doctrine.md`](../concepts/onion-modernization-doctrine.md) | ✅ ativa |
| **Abstraction Doctrine** | **quando** algo vira SDAAL (Teste do Eixo + Teste do Gatilho) | [`onion-abstraction-doctrine.md`](../concepts/onion-abstraction-doctrine.md) | ✅ ativa (2026-07-17) |
| **Economy of Motors** | 3 motores (Transformer · SLM-ferramenta · Shell); use o mais barato capaz | [`onion-engine-economy.md`](../concepts/onion-engine-economy.md) | ✅ ativa |
| **SDAAL** *(Specification-Driven AI Abstraction Layer)* | uma interface, N providers; o spec é o artefato e o LLM o runtime | [KB](../concepts/specification-driven-ai-abstraction-layer.md) · [whitepaper](../../sdaal/sdaal.md) | ✅ ativa |
| **KG SDAAL** | investigação/domínio como grafo tipado; verdades **reconciliadas** (`REFUTES`/`SUPERSEDES`), radar determinístico | [`knowledge-graph-sdaal.md`](../concepts/knowledge-graph-sdaal.md) | ✅ ativa — **é infraestrutura**: 51 grafos, `kg-radar`, `kg-console`, `/meta:kg`, `/meta:kg-freshness`, REGRAS 43/47/49/52 e regra path-scoped nativa |
| **SSOT-as-runtime** | a SSOT é o **programa que se executa**: `read→verify→act→write`; KG-first + drive-to-verify | [KG SDAAL §SSOT-as-runtime](../concepts/knowledge-graph-sdaal.md#ssot-as-runtime--o-kg-é-o-primeiro-ato-mecanismo-não-conselho) | ✅ ativa (cabeada nos 3 loops) |
| **`gated-until-trigger`** | o artefato nasce do **uso que o prove**, nunca de simetria/plano | [modernization §🚦](../concepts/onion-modernization-doctrine.md) | ✅ ativa |
| **`declarado ≠ verificado`** | carimbo/doc/branch é DEV; só o artefato vivo é PROD | [verify-read-path-first](../agentic-patterns/ai-strategies/verify-read-path-first.md) (tabela da família) | ✅ ativa |
| **`fonte ≠ derivação`** | fonte e nossa leitura em artefatos **fisicamente** separados; a derivação **cita** | [`source-vs-derivation.md`](../concepts/source-vs-derivation.md) | ✅ ativa |
| **PFR** *(Padrão Faseado Retomável)* | sessão durável + `STATE.md` + retomada fria; fases nunca fundidas | `onion-adr-phased-resumable-pattern-2026-06.md` (ADR interno do core — nomeia o PFR, padrão já invariante L0; provisório, PR à meta-spec diferido até gatilho) + [método §2a](../concepts/onion-working-method.md) | 🟡 ADR provisório (a cravar em `commands.md §3`) |
| **Capability Contract** | o que um repo adotado pode esperar: Bronze/Silver/Gold — contrato **verificável** | `onion-adr-capability-contract-2026-06.md` (ADR interno do core — auto-descrição `provides/requires/loads/conformance`, tiers Bronze/Silver/Gold, validada pelo lint REGRA 20; visão-de-fora composta dos contratos, não registry à mão) + **7** `plugins/*/.claude-plugin/capability.json` | ✅ ativa — ADR **+ mecanismo** (REGRA 20 [HARD]) |
| **Co-Evolution Protocol** *(doc-bridge)* | sinal bidirecional core↔adotante por arquivo commitado; sem runtime acoplado | `docs/evolution/README.md` (interno do core — fonte canônica do protocolo doc-bridge; maestro humano orquestra, execução do que chega é gate humano) + `/meta:co-*` | ✅ ativa |
| **Breadcrumbs / migalhas** | sinal explícito **no artefato** que força **absorção** em vez de acomodação | [`breadcrumb-patterns.md`](../agentic-patterns/ai-strategies/breadcrumb-patterns.md) + `/meta:diary` | ✅ ativa — 92 entradas, TTL + `conflict_class` por entrada, e o `personality-sync` F2 fez a **identidade emergir de 74 migalhas** |
| **Object-led discovery** | o maestro dirige com o objeto; o Transformer executa com as peças certas | [KB](../agentic-patterns/ai-strategies/object-led-discovery.md) + `onion-adr-object-led-discovery-2026-07.md` (ADR interno do core — playbook espelhar→descobrir(object-led)→vestir(capability-fitting)→materializar→realimentar; "quem sabe sobre o objeto é o próprio objeto", Information Expert) | ✅ ativa |
| **Autobiographical Marketing** | o framework conta a própria história; os commits **são** a autobiografia | `onion-adoption-manual.md` (persona 1ª pessoa) + **onionevolve.com reformado** (2026-08-25, PR #672): /historia/ com a curva dos commits gerada do git, diário com 62 migalhas, /doutrinas/ com as cicatrizes datadas | ✅ ativa (2026-08-25 — deixou de ser só prosa de manual: virou site vivo com números derivados da SSOT em build) |
| **Maestro's Aside** *(Aparte do Maestro)* | protocolo de entrada lateral tipada: marcador pt-BR no início da mensagem (`dúvida:`/`corrige:`/`paralelo:`…) → hook `UserPromptSubmit` injeta a rota canônica (recall, **não** gate); dispatcher p/ diário/memória/STATE/orquestração que já existem | [`maestro-aside.md`](../agentic-patterns/harness/maestro-aside.md) + hook+motor | ✅ ativa (2026-08-04) |

> **Manutenção:** ao nomear algo novo, **primeiro dê a casa**, depois adicione a linha. Nome anunciado
> antes de existir é `declarado ≠ verificado` aplicado a nós mesmos — foi o que aconteceu com `KG-first` e
> `drive-to-verify`, anunciados a 3 adotantes antes de terem casa no core (2026-07-16).

## 2. O Problema que Resolve

| # | Problema | Sem Onion | Com Onion |
|---|----------|-----------|-----------|
| 1 | Orquestração manual da IA | Prompts ad-hoc por tarefa, sem memória de workflow nem tiering de agentes | 109 comandos = workflows codificados (`/engineer:plan` já sabe delegar a `@task-specialist`) |
| 2 | Cada integração de task manager é caso especial | Reescrever prompts/formatos por provider (Jira exige ADF, ClickUp Unicode, Asana HTML) | SDAAL Task Manager Abstraction — `TASK_MANAGER_PROVIDER` no `.env` roteia ao adapter certo, formatação tipada |
| 3 | Trabalho interrompido = contexto perdido | Reexplicar contexto do zero a cada retomada de sessão | Workflows faseados retomáveis + `STATE.md` (ponteiro Tier-0 ~1KB) em `.claude/sessions/` |
| 4 | Compliance é silo separado do dev | Documentação ISO/SOC2 criada depois, manualmente, desconectada da entrega | 5 agentes de compliance integrados ao mesmo ciclo; `/docs:build-compliance-docs` gera a partir do estado real |
| 5 | Orquestrações de IA são caras e trabalhosas | Escrever scripts de orquestração manuais, schemas, tiering, tratamento de falha | Skill `onion-orchestration` autora `Workflow` com tiering automático (haiku/sonnet/opus), barrier+fan-in, verificação adversarial |
| 6 | Multi-repo sem coordenação quebra integrações | Coordenação por Slack/docs manuais, sem garantia de validação prévia | Federation v2 — topologia peer + ledger git (`publish` → `check` → `status` → `rollback`) |
| 7 | Framework envelhece silenciosamente | Documentação e agentes ficam obsoletos sem que ninguém audite | `/meta:evolve` — auto-auditoria em 10 dimensões via orquestração, backlog priorizado com evidência citada |
| 8 | Sem padrão paralelo vs sequencial | O time não sabe quando usar fan-out, sessões ou Agent Teams | KB `agent-orchestration` — tabela de decisão dos 3 substratos + fallback gracioso |

*(Detalhamento "antes/depois" com prosa completa e fontes por item: material bruto §2)*

---

## 3. Arquitetura em Camadas

### Diagrama de componentes

```
┌─────────────────────────────────────────────────────────────┐
│                 Claude Code (plataforma única)                │
├─────────────────────────────────────────────────────────────┤
│  SKILLS (.claude/skills/) — 11 — orquestração de alto nível    │
│    onion · onion-orchestration · onion-patterns ·                      │
│    onion-validation · language-standards ·                     │
│    onion-{product,engineering,compliance}-context ·            │
│    onion-wizard · onion-onboarding · onion-retro               │
├──────────────────┬──────────────────────────────────────────┤
│  COMMANDS         │  AGENTS (.claude/agents/)                 │
│  (.claude/        │  51 especialistas em 9 categorias:        │
│  commands/)       │    development · product · git            │
│  109 workflows em │    meta · compliance · testing             │
│  10 categorias    │    review · research · deployment          │
├──────────────────┴──────────────────────────────────────────┤
│  ABSTRAÇÕES (.claude/utils/) — padrão SDAAL                    │
│    Task Manager (Jira · ClickUp · Asana · Linear)              │
│    Forge (GitHub; GitLab/Bitbucket = costura, não capability)  │
├─────────────────────────────────────────────────────────────┤
│  DOCUMENTAÇÃO CONSTITUCIONAL (docs/)                           │
│    Meta-specs L0 · Knowledge Bases (93) · Spec as Code         │
│    Sessions (.claude/sessions/) — gitignored, retomáveis       │
└─────────────────────────────────────────────────────────────┘
```

### As 5 camadas

1. **Comandos** (`.claude/commands/`) — 109 arquivos Markdown invocáveis por categoria (`/product:*`, `/engineer:*`, `/git:*`, `/docs:*`, `/meta:*`, `/validate:*`, `/test:*`, `/design:*`, `/development:*`, `/quick:*`). Cada um define `allowed-tools` (escopo de permissão), `model` (tier de custo) e a lógica de orquestração. Comandos definem **o que fazer e como** — não *quem sabe fazer*.
2. **Agentes** (`.claude/agents/`) — 51 especialistas em 9 categorias (development, product, git, meta, compliance, testing, review, research, deployment). Sabem **fazer**: `@jira-specialist` opera JQL+ADF, `@metaspec-gate-keeper` valida arquitetura, `@react-developer` escreve componentes.
3. **Skills** (`.claude/skills/`) — 12 programas de orquestração de alto nível. `onion-orchestration` é o mais poderoso: autora scripts `Workflow` nativos do Claude Code para fan-out paralelo de agentes, com tiering de modelos por tier (haiku para scan/classificação, sonnet para raciocínio, opus para julgamento adversarial — sem fixar versão exata).
4. **Abstrações** (`.claude/utils/`) — padrão SDAAL em dois eixos: **Task Manager** (Jira/ClickUp/Asana/Linear, API-first com MCP opcional) e **Forge** (GitHub hoje, GitLab/Bitbucket com costura pronta). Comandos nunca chamam a API do provider direto — sempre via adapter, que resolve transporte, formatação e fallback.
5. **Documentação constitucional** (`docs/`) — Meta-specs L0 (constituição), Knowledge Bases (93 documentos estruturados para consumo por IA), Business/Technical/Compliance Contexts (Spec as Code gerados por `/docs:build-*-docs`).

### Fluxo de uma feature típica

```
/product:collect → /product:refine → /product:spec → /product:task
   ↓
/engineer:start (cria worklog STATE.md)
   ↓
/engineer:work (retomável — lê STATE.md, continua fase [ACTIVE])
   ↓
/engineer:pre-pr (@branch-metaspec-checker + testes)
   ↓
/engineer:pr (forge adapter → PR com link da task)
   ↓
/git:sync (cleanup + archive de sessão)
```

`product/collect→task` e `engineer/plan→pr-update` são **workflows faseados retomáveis** — invariantes do framework. Nunca são fundidos numa fase única.

### Padrão SDAAL (Specification-Driven AI Abstraction Layer)

- **Task Manager**: `TASK_MANAGER_PROVIDER` no `.env` define o adapter ativo. O consumidor chama `taskManager.create()`; o adapter resolve para `POST /rest/api/3/issue` (Jira) ou a chamada equivalente (ClickUp/Asana/Linear).
- **Forge**: `FORGE_PROVIDER` define o host remoto. `/engineer:pr` chama `forge.createPR()`; o adapter usa `gh pr create` (default) ou REST (fallback).

**Por que importa:** o mesmo comando funciona em projetos com stacks de ferramentas diferentes, sem reescrita — e troca de provider é mudança de `.env`, não de código.

*(Fontes: material bruto §3; `onion-review-2026-05.md` §2 (interno do core); `CLAUDE.md` §Padrões Técnicos)*

---

## 4. Capacidades por Categoria

### Produto & Discovery

| Capacidade | Comando | Exemplo concreto |
|------------|---------|------------------|
| Coletar requisitos | `/product:collect` | Entrevistar usuário, estruturar em história |
| Refinar especificação | `/product:refine` | Gap analysis, critérios de aceite |
| Especificação completa | `/product:spec` | Gerar spec pronta para `/engineer:plan` |
| Transcrição de reunião | `/product:whisper` | Áudio → ata estruturada |
| Extração de ata | `/product:extract-meeting` | Ata bruta → decisions/actions |
| Análise de dor do cliente | `/product:analyze-pain-price` | JTBD + precificação |
| Converter em tasks | `/product:convert-to-tasks` | Spec → hierarquia no task manager ativo |

### Engenharia & GitFlow

| Capacidade | Comando | Exemplo concreto |
|------------|---------|------------------|
| Planejar feature | `/engineer:plan` | Fases retomáveis, `STATE.md` |
| Iniciar dev | `/engineer:start` | Cria worklog, branch GitFlow |
| Retomar dev | `/engineer:work` | Lê `STATE.md`, continua fase `[ACTIVE]` |
| Gate pré-PR | `/engineer:pre-pr` | Lint, testes, `@branch-metaspec-checker` |
| Abrir PR | `/engineer:pr` | Forge adapter → PR com link da task |
| Hotfix urgente | `/engineer:hotfix` | Branch hotfix, PR fast-track |

### Qualidade & Compliance

| Capacidade | Agente/Comando | Exemplo concreto |
|------------|----------------|------------------|
| Code review | `@code-reviewer` | Bugs, patterns, manutenibilidade |
| Review de branch | `@branch-code-reviewer` | Diff-scoped, pré-PR |
| Testes unitários | `/test:unit` | Gerar + executar suíte |
| ISO 27001 | `@iso-27001-specialist` | Política SGSI, risk assessment |
| SOC2 Type II | `@soc2-specialist` | Controles + coleta de evidências |
| Validação arquitetural | `@metaspec-gate-keeper` | Conformidade L0/L1+ |

### Orquestração

| Capacidade | Mecanismo | Quando usar |
|------------|-----------|-------------|
| Fan-out paralelo | `Workflow` (nativo) + skill `onion-orchestration` | Auditoria, migração, review amplo |
| Sessões retomáveis | `.claude/sessions/` + `STATE.md` | Feature de longa duração |
| Agent Teams (opt-in) | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Negociação peer-a-peer viva, experimental |
| Federation multi-repo | `/meta:federation-*` | Coordenação cross-repo sem quebrar contratos |

### Meta (Auto-Evolução)

| Capacidade | Comando |
|------------|---------|
| Auto-auditoria | `/meta:evolve` — 10 dimensões, orquestração, backlog priorizado |
| Frescor de KBs | `/meta:kb-freshness` — veredito CURRENT/STALE/HISTORICAL |
| Criar novo agente | `/meta:create-agent` — contextualizado no ecossistema |
| Criar novo comando | `/meta:create-command` |
| Validar conformidade | `/meta:metaspec-validate` |
| Inventário automático | `/meta:inventory` — SSOT gerada do filesystem |

---

## 5. Casos de Uso Reais

### Caso 1 — Federation v2: "Coordenação Multi-Repo Sem Quebrar Nada"

**Situação:** time com múltiplos repositórios integrados (API + frontend + infra); qualquer mudança de contrato podia quebrar os demais, coordenada manualmente via Slack.
**O que o Onion fez:** topologia peer + ledger git, implementada em fases (register → publish+check → status+rollback); cada repo valida localmente via `/meta:federation-check`.
**Resultado:** ciclo `register→publish→check→status→rollback` completo em produção; mudança incompatível é bloqueada com mensagem acionável, rollback coordenado restaura o estado.
**Citação:** *"Cada Onion defende seus interesses — o repo dono valida localmente as mudanças que o afetam (conhecimento de 1ª mão)."* — `onion-federation-design-v2-2026-06.md` §2 (interno do core: design da Federation na **topologia peer + ledger git** — cada repo mantém seu Onion soberano e valida em casa as mudanças de contrato que o afetam; documenta o pivô do hub v1, que repousava num spike não-verificado)

### Caso 2 — `/meta:evolve`: "O Framework se Auto-Auditando"

**Situação:** após um ciclo grande de mudanças (migração Cursor→native, federation, novos comandos), o framework não tinha auditoria formal recente.
**O que o Onion fez:** `/meta:evolve` disparou 28 agentes em 8 dimensões (peso, redundância, duplicação, KBs stale, conformidade, legado, links, frontmatter); juiz adversarial (opus) refutou 11 de 41 achados brutos.
**Resultado:** 30 achados sobreviventes → backlog priorizado → 100% executado (8 PRs do ciclo de auto-auditoria #54-#61: sweep MCP-first, índices reconciliados, 51 comandos com `allowed-tools`, calibração de régua de frescor).
**Citação:** *"28 agentes (8 auditores + ~19 juízes + critic) · 1.27M tokens · 635 tool-uses · ~26 min."* — `onion-evolution-2026-06-15.md` §0 (backlog de auto-auditoria do `/meta:evolve`, interno do core: run real que gerou 41 achados brutos → **30 sobreviventes** após o juiz adversarial refutar 11)

### Caso 3 — Agent Teams: "Decidindo Não Adotar (Com Evidência)"

**Situação:** a Anthropic lançou `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (substrato experimental de peers persistentes) — adotar como novo padrão de orquestração?
**O que o Onion fez:** smoke-test empírico (TeamCreate→TaskCreate→SendMessage round-trip), demo real com divisão de tarefas por `owner`, e avaliação estruturada das três primitivas (sessões faseadas / `Workflow` / Agent Teams).
**Resultado:** ADR formal — Agent Teams entra como **3º modo opt-in** com detecção de capacidade e fallback gracioso; os padrões existentes (`Workflow`-first) permanecem.
**Citação:** *"Workflow = orquestração que o orquestrador desenha. Agent Teams = coordenação que emerge."* — `onion-agent-teams-evaluation-2026-06.md` §3 (interno do core: a avaliação que decidiu **NÃO** tornar Agent Teams padrão — entra como 3º modo de orquestração opt-in, atrás de detecção de capacidade com fallback gracioso; o Workflow-first permanece)

### Caso 4 — Cursor→Claude Code Native: "Corrigindo o Propagador"

**Situação:** os 49 agentes usavam nomes de ferramentas do dialeto Cursor (`create_file`, `search_files`); o lint validava o dialeto errado.
**O que o Onion fez:** identificou `agent-template.md` como o propagador, corrigiu-o primeiro, depois migrou os 49 agentes em fan-out paralelo e corrigiu o lint.
**Resultado:** 100% dos agentes com nomes de ferramenta nativos, lint corrigido, zero falsos positivos.
**Citação:** *"Conserta o propagador, não só as folhas."* — princípio de refatoração em escala, salvo como padrão.

### Caso 5 — D8 `allowed-tools`: "Capability Surface como Política"

**Situação:** auditoria D8 encontrou 51 de 82 comandos sem `allowed-tools` declarado — um vazio de política que permite ao agente usar qualquer ferramenta.
**O que o Onion fez:** fan-out de 51 workers haiku propôs o `allowed-tools` mínimo por comando; revisão humana rejeitou propostas inconsistentes (ex.: `Bash(gh *)` em comandos que devem usar o forge adapter).
**Resultado:** 82/82 comandos com `allowed-tools` escopado. Insight: **`allowed-tools` é a capability surface real** — prosa que diz "nunca use gh" mas com `Bash(gh *)` no frontmatter é a inconsistência que importa.

*(Narrativa completa, com passos numerados e citações adicionais: material bruto §5)*

---

## 6. Métricas e Evidências

| Métrica | Valor | Fonte |
|---------|-------|-------|
| Comandos invocáveis | 109 (10 categorias + root) | `docs/onion/inventory.md` (SSOT gerada) |
| Agentes especializados | 51 (9 categorias) | `docs/onion/inventory.md` (SSOT gerada) |
| Skills | 13 | `docs/onion/inventory.md` (SSOT gerada) |
| Knowledge Bases | 93 | `docs/onion/inventory.md` (SSOT gerada) |
| Task Manager providers suportados | 4 (Jira, ClickUp, Asana, Linear) | `CLAUDE.md` §Task Manager |
| PRs na jornada completa de auto-evolução (Agent Teams + Federation + Evolve) | 22 | ⚠️ **não-verificável** — a fonte (`.claude/sessions/INDEX.md`) é **gitignored**; número congelado-no-tempo, sem como re-medir |
| Workers no `/meta:evolve` | 28 agentes | onion-evolution-2026-06-15.md §0 |
| Tokens no `/meta:evolve` | 1.27M | onion-evolution-2026-06-15.md §0 |
| Tool-uses no `/meta:evolve` | 635 | onion-evolution-2026-06-15.md §0 |
| Duração do `/meta:evolve` | ~26 min | onion-evolution-2026-06-15.md §0 |
| Achados D1 (peso/tamanho) | 0 outliers | onion-evolution-2026-06-15.md §2 — "framework dentro dos limites" |
| Agentes migrados Cursor→native | 49/49 (100%) | sessions archives jun/2026 |
| Comandos com `allowed-tools` após D8 | 82/82 (100%) | PR #60 |
| Dimensões da auto-auditoria | 10 (D1–D10) | `evolve.md` §Dimensões |
| Fases de federation implementadas | 5 (0→ledger, 1→register, 2→publish/check, 3→status/rollback) | `multi-repo-federation.md` |

> ⚠️ **Um TERCEIRO tipo que esta nota não classificava** (achado 2026-08-03): a linha
> "Fases de federation implementadas | 5" **não é** contagem de inventário (não vem de
> `inventory.md`) **nem é** congelada-no-tempo declarada — e houve o redesign RFC-0004 desde então.
> Números assim, de estado-de-programa, precisam de re-verificação própria; não herdam nem a
> atualização automática do inventário nem a imunidade do histórico.
>
> **Manutenção (anti-redrift):** as contagens de inventário **presentes** (comandos/agentes/skills/KBs/dimensões)
> são derivadas da SSOT gerada `docs/onion/inventory.md` (interna do core — contagens de comandos/agentes/skills/KBs computadas do filesystem por `${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh`, validadas no CI, nunca digitadas à mão)
> — ao resync, leia a SSOT, nunca reescreva de memória. Os números **dentro dos Casos de Uso (§5)** e das
> métricas de run específico (tokens/agentes/duração do `/meta:evolve` de 2026-06-15) são **congelados-no-tempo**:
> descrevem um evento histórico e **não** se atualizam com o inventário. Family [`declarado ≠ verificado`](#15-invenções-nomeadas--o-catálogo-canônico).

---

## 7. Posicionamento vs Alternativas

### O que o Onion NÃO é (decidido formalmente em 2026-05-18)

| Direção abandonada | Por quê |
|---------------------|---------|
| CLI standalone (`packages/onion-cli/`) | Distribuir como produto contradiz a identidade de template instalável |
| Multi-IDE **no core** | Ver o quadro abaixo — a nuance importa, e ler esta linha sem ela leva a uma conclusão errada |
| `.onion/` agnóstico | Abstração prematura sem ganho real |
| v4.0 FASES 5-9 (aprendizado contínuo, A2A runtime) | Beira agente autônomo fora de controle; humano-maestro é invariante |

#### ⚠️ CORE ≠ FAMÍLIA — a distinção sem a qual a linha acima mente

Esta tabela descreve **o core** (`onion-evolve`). A **família multi-IDE é outro objeto**, com outro
propósito e outro ciclo de vida:

| | Core (`onion-evolve`) | Família multi-IDE |
|---|---|---|
| O que é | o framework vivo | material de curso + **prova de portabilidade** |
| Plataforma | Claude Code, **por capacidade** | Cursor, Antigravity, Copilot e outros |
| Ciclo de vida | manutenção ativa | **CONGELADA** — não é linha ativa |
| Repos | este | `onion` (hub) · `onion-cursor` · `onion-antigravity` · `onion-copilot` · `onion-architect` · `onion-mini` · `onion-standalone` |

**E a decisão de 2026-05-18 foi por CAPACIDADE, não abandono do agnosticismo.** O Onion nasceu no
Cursor buscando ser agnóstico e foi de fato **portado** para Claude/Antigravity/Codex para o Curso de
Desenvolvimento com IA (Pulse Mais), **com alunos usando em campo**. A escolha foi *parar de gastar
energia em agnosticismo* para poder usar recursos de fronteira (nominalmente `SendMessage` entre
agentes no modo Teams). É **conclusão de um experimento multi-IDE de escala real** — não restrição
de origem.

O critério que decide toda adoção de substrato é **a postura de acoplamento**: acoplado ao Claude
Code para tirar vantagem da sua maquinaria, *mas mantendo independência sempre que isso for mais
vantajoso e o acoplamento não for necessidade*. Acople só quando a capacidade ganha não existe fora.

> **Por que este quadro existe:** sem a distinção escrita, quem lê a linha "Multi-IDE abandonado"
> conclui que os repos públicos violam a doutrina — **conclusão errada, já cometida em 2026-08-02**.
> Esta KB, além disso, se **contradizia**: dizia "multi-IDE abandonado" aqui e celebrava "família
> multi-plataforma" na §10.

*(Fontes: `CLAUDE.md` §Identidade canônica; `onion-review-2026-05.md` §4 (interno do core); SSOT do
grafo: `docs/onion/graph/onion-identity-2026-07.kg.yaml` → `C_CORE_NAO_E_FAMILIA`,
`D_CLAUDE_CODE_POR_CAPACIDADE`, `E_FAMILIA_MULTIIDE_CONGELADA`, `E_PORTE_PARA_O_CURSO`)*

### Diferenciação de "cursor rules" / prompt engineering ad-hoc

| Dimensão | Cursor rules / prompts ad-hoc | Sistema Onion |
|----------|-------------------------------|---------------|
| Escopo | Instruções para uma sessão | Framework reutilizável instalável |
| Task Manager | Não existe | 4 providers via SDAAL (API-first) |
| Compliance | Não existe | ISO 27001, SOC2, PMBOK, ISO 22301 integrados |
| Orquestração | Manual, caso a caso | 109 workflows + 51 agentes + 13 skills |
| Multi-repo | Não existe | Federation v2 com topologia peer |
| Auto-evolução | Não existe | `/meta:evolve` audita 10 dimensões |
| Sessions retomáveis | Não existe | `STATE.md` + worklog persistente |
| Abstração de integração | Não existe | SDAAL (Task Manager + Forge) |

### Público-alvo ideal

1. **Dev/tech lead com projeto legado** — estruturar uso de IA no dia a dia sem mudar stack.
2. **Startup técnica** com Jira/ClickUp + GitHub — acelerar o ciclo produto→eng sem aumentar headcount.
3. **Time regulado** (fintech, healthtech, SaaS enterprise) — compliance (ISO 27001/SOC2) integrado ao fluxo, não como silo.
4. **Mantenedor de múltiplos repos** — coordenar mudanças cross-repo com garantia de não quebrar integrações.

*(Fonte: `onion-review-2026-05.md` §1 (interno do core))*

---

## 8. FAQ

**Preciso mudar meu stack para usar o Onion?**
Não. O Onion vive inteiramente em `.claude/` — código, linguagem, framework e infra do projeto não são tocados.

**Funciona com qualquer gerenciador de tarefas?**
Sim, para Jira, ClickUp, Asana ou Linear — basta definir `TASK_MANAGER_PROVIDER` no `.env`. Sem provider, o modo `none` permite uso offline com decomposição local.

**Precisa de plano Claude Code pago?**
O Onion usa o Claude Code como plataforma. Orquestrações pesadas (ex.: `/meta:evolve` ≈ 1.27M tokens numa auditoria completa) favorecem planos com mais headroom; uso moderado funciona em planos menores.

**O Onion substitui o GitFlow?**
Não — complementa. `/engineer:*` e `/git:*` são orientados pelo motor GitFlow (`gitflow-patterns.md`); o Onion adiciona sessões retomáveis, gates de qualidade e integração com task manager por cima.

**O que acontece se o Claude Code lançar uma feature incompatível?**
O framework tem meta-specs L0 e `/meta:evolve` para auto-auditoria — mudanças de plataforma geram achados D6 (legado/modernização) que o mantenedor executa. A migração Cursor→native em 49 agentes é um exemplo real.

**Funciona em projetos legados sem testes?**
Sim — projetado para "qualquer projeto (novo, legado ou regulado)". Os agentes `/test:*` e `@branch-test-planner` ajudam a estabelecer cobertura onde não existe.

**Qual é o esforço de instalação?**
Copiar `.claude/` para o projeto, configurar `.env` (task manager + forge) e rodar `/warm-up`. Um dev experiente faz em menos de 2 horas.

**Posso usar só partes do Onion?**
Sim. As três dimensões (produto, engenharia, compliance) são peer — pode começar só com `/engineer:*`. Adapters só ativam se as variáveis do `.env` estiverem configuradas.

**Agent Teams substitui o Workflow para orquestração?**
Não. São complementares: `Workflow` = orquestração determinística de forma conhecida (auditoria, migração, review); Agent Teams = coordenação emergente peer-a-peer (negociação viva). Onion usa `Workflow` por padrão; Agent Teams é opt-in.

**O Onion funciona com monorepo?**
Sim — `@nx-monorepo-specialist` e `@nx-migration-specialist` são especializados em NX, validados em repositórios NX reais.

**O que é o `/meta:evolve` e por que é relevante?**
A auto-auditoria do framework: dispara uma orquestração em 10 dimensões (peso, redundância, duplicação, KBs stale, conformidade, legado, links, frontmatter, frescor de contexto, frescor de memória) e produz backlog priorizado com evidência `arquivo:linha`. O framework se diagnostica periodicamente sem revisão manual artefato-a-artefato.

**Como funciona a integração de compliance?**
Agentes como `@iso-27001-specialist` e `@soc2-specialist` leem o estado real do projeto (código, arquitetura, processos) e geram/atualizam documentação de conformidade; `@security-information-master` detecta qual framework aplicar.

---

## 9. Citações-chave (Press Kit)

1. *"Framework template em `.claude/` projetado para ser instalado e aplicado em qualquer projeto — novo, legado ou regulado — para orquestrar o ciclo completo de desenvolvimento com Claude Code."* — `CLAUDE.md` (identidade canônica)
2. *"As três dimensões são peer, não hierarquizadas."* — `onion-review-2026-05.md` §1 (interno do core)
3. *"Workflow = orquestração que o orquestrador desenha. Agent Teams = coordenação que emerge."* — `onion-agent-teams-evaluation-2026-06.md` §3 (interno do core)
4. *"Cada Onion defende seus interesses — o repo dono valida localmente as mudanças que o afetam."* — `onion-federation-design-v2-2026-06.md` §2 (interno do core)
5. *"28 agentes · 1.27M tokens · 635 tool-uses · ~26 min"* — custo de uma auto-auditoria completa, `onion-evolution-2026-06-15.md` §0 (interno do core)
6. *"Read-only por contrato. O comando nunca muta `.claude/`; a única escrita é o relatório em `docs/analysis/`."* — `evolve.md` §Objetivo
7. *"Conserta o propagador, não só as folhas."* — princípio de refatoração em escala (migração Cursor→native)
8. *"Task Manager Abstraction madura — padrão SDAAL real, 4 adapters, fallback gracioso, formatação tipada por provider."* — `onion-review-2026-05.md` §Top 5 forças (interno do core)
9. *"O veredito: substantialmente completo em cobertura."* — `onion-review-2026-05.md` §1 (interno do core; estado pós P0–P3)

---

## 10. Ecossistema Vivo (2026-07)

> Fonte: `onion-adoption-manual.md` (interno do core, Partes I-II) +
> verificação ao vivo em 2026-07-03 (endpoints respondendo).

- **Persona autobiográfica**: o Onion conta a própria história em 1ª pessoa — é a invenção
  *Autobiographical Marketing* ([§1.5](#15-invenções-nomeadas--o-catálogo-canônico); os commits são a
  autobiografia; os docs gerados de si são o portfólio). O texto canônico da persona é o **Manual de Adoção**
  (`docs/applying/onion-adoption-manual.md`, prólogo "O Despertar").
- **Onion-Bridge (mobile) — deployed**: ponte fina (repo privado `~/onion-bridge`, Node 22 + Hono
  + PWA Android) que expõe o framework via `@anthropic-ai/claude-agent-sdk` com `cwd` no core.
  **No ar**: site público **`onionevolve.com`** ("Onion Evolute — A Autobiografia de um Framework
  Vivo") e backend **`app.onionevolve.com`** (VPS com Caddy/TLS + clone do core em
  `/home/onion/onion-evolve`), deploy ~2026-06-29.
- **Adotantes reais**: vários adotantes em campo — co-evolução ativa (lineages mapeadas em
  `docs/evolution/federation/members.yaml`), sessões persistentes (Jira/ADF, multi-contexto) e um adotante da
  vertical educacional (materiais publicados).
- **Família multi-plataforma — pública e CONGELADA**: hub `onion` + destilações por plataforma
  (`onion-cursor`, `onion-antigravity`, `onion-copilot`, `onion-architect`), o **Onion Mini**
  (`marciocar/onion-mini`, público — destilação máxima e produto de ENTRADA) e o
  **`onion-standalone`**. **Congelada** significa: material de curso e **prova de portabilidade**,
  **não linha de manutenção ativa** — os repos existem e não recebem evolução. O core segue
  Claude-Code-only **por capacidade** (ver §7); quem é multi-plataforma é a família.
  *(Lista medida via `gh api` em 2026-08-02 — `E_FAMILIA_MULTIIDE_CONGELADA`. A redação anterior
  desta linha listava `codex` e `zed`, que não foram medidos, e omitia `architect` e `standalone`,
  que existem: um press kit derivado dela publicaria repos possivelmente inexistentes.)*

---

## Mapa de Uso — Esta KB → Materiais Derivados

| Seção | Alimenta |
|-------|----------|
| 1. O que é o Onion | Landing page (hero), press 1-pager |
| 2. O problema que resolve | Landing page (seção de valor), case studies |
| 3. Arquitetura em camadas | Manual técnico, artigos técnicos |
| 4. Capacidades por categoria | Manual, landing page (feature grid) |
| 5. Casos de uso reais | Case studies, artigos críticos |
| 6. Métricas e evidências | Press kit, estudos de caso |
| 7. Posicionamento vs alternativas | Artigos críticos, comparativos |
| 8. FAQ | Press kit, manual, onboarding |
| 9. Citações-chave | Press kit, landing page |
| 10. Ecossistema vivo | Landing page (prova social), press kit, site onionevolve.com |

---

## Referências

- **Material bruto (citações linha-a-linha)**: `onion-product-material-raw-2026-06.md` (interno do core)
- **Identidade canônica**: `CLAUDE.md` · `onion-review-2026-05.md` (interno do core)
- **Auto-auditoria**: `onion-evolution-2026-06-15.md` (interno do core)
- **Agent Teams ADR**: `onion-agent-teams-evaluation-2026-06.md` (interno do core)
- **Federation v2**: `onion-federation-design-v2-2026-06.md` (interno do core) · [multi-repo-federation.md](../concepts/multi-repo-federation.md)
- **Doutrina de orquestração**: [agent-orchestration.md](../concepts/agent-orchestration.md)
- **Task Manager Abstraction**: [task-manager-abstraction.md](../concepts/task-manager-abstraction.md)
- **Getting started**: `docs/onion/getting-started.md`

---

**Última atualização**: 2026-08-03 — **v1.3.0**

Duas rodadas no mesmo dia:

**(a) resync de inventário** → SSOT: 102 comandos / 51 agentes / **11 skills** / **87 KBs** / 10
dimensões. O resync de 2026-07-24 deixara a KB inconsistente **consigo mesma** (o pitch dizia 102
comandos e a tabela §6 dizia 99); §3, §6 e §7 passaram a derivar da mesma SSOT.

**(b) atualidade doutrinária** — o drift que importava, num artefato voltado ao **público externo**:

| Onde | Estava | Ficou |
|---|---|---|
| §7 | "Multi-IDE abandonado", sem nuance — e **contradizendo** a §10 | quadro **CORE ≠ FAMÍLIA** + a decisão reenquadrada **por capacidade** (`SendMessage`/Teams), conclusão de experimento real com alunos |
| §10 | família como "ecossistema **vivo**"; lista com `codex`/`zed` **não medidos**, sem `architect`/`standalone` | **CONGELADA**, com os 7 repos medidos por `gh api` |
| §1 e §3 | forge "GitLab/Bitbucket **no roadmap**" / `🔜` nu | **costura pronta, não capability**, com o gatilho nomeado — a `gated-until-trigger` que a própria KB lista em §1.5 |
| §1.5 | KG SDAAL `🟡 candidata` · Capability Contract `🟡 só ADR` · Breadcrumbs `🟡 draft` | os três **✅ ativos**, com a evidência que os promoveu |
| §6 e §10 | 3 caminhos em prosa que não resolvem | corrigidos; a métrica "22 PRs" marcada **não-verificável** (fonte gitignored) |
| §6 | nota anti-redrift classificava 2 tipos de número | explicitado o **3º tipo** (estado-de-programa) que ela não cobria |

Casos históricos §5 seguem **intactos** como congelados-no-tempo. SSOT da doutrina:
`docs/onion/graph/onion-identity-2026-07.kg.yaml`.
**Mantido por**: Sistema Onion (síntese — gerada via `/meta:create-knowledge-base`, Fase 3 do plano de materiais externos)
