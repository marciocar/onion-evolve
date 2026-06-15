---
title: "Onion: Identidade e Produto — Material Bruto para KB"
date: 2026-06-15
status: material-bruto
scope: landing-page · manual · case-studies · press-kit · artigos-críticos
fontes:
  - CLAUDE.md
  - docs/analysis/onion-review-2026-05.md
  - docs/analysis/onion-vv-baseline-2026-06.md
  - docs/analysis/onion-evolution-2026-06-15.md
  - docs/analysis/onion-agent-teams-evaluation-2026-06.md
  - docs/analysis/onion-federation-design-v2-2026-06.md
  - docs/onion/getting-started.md
  - docs/knowledge-base/concepts/agent-fleet-orchestration.md
  - docs/knowledge-base/concepts/task-manager-abstraction.md
  - docs/knowledge-base/concepts/multi-repo-federation.md
---

# Onion: Identidade e Produto — Material Bruto para KB

> Levantamento exaustivo para construção da KB canônica de posicionamento.
> Toda afirmação tem fonte citada. Nada inventado.

---

## 1. IDENTIDADE — 3 Versões de Pitch

### 30 segundos
**Sistema Onion é um framework template em `.claude/` que instala num repositório o ciclo completo de desenvolvimento orientado por IA — produto, engenharia e compliance — sem alterar uma linha de código do projeto-alvo.**

*(Fonte: CLAUDE.md — "framework template em `.claude/` projetado para ser instalado e aplicado em qualquer projeto (novo, legado ou regulado) para orquestrar o ciclo completo de desenvolvimento com Claude Code")*

---

### 2 minutos
O Sistema Onion é um **framework de orquestração de desenvolvimento** que vive inteiramente em `.claude/` — uma pasta de configuração do Claude Code. Ao instalar o Onion num projeto, você ganha 82 comandos invocáveis, 49 agentes especializados de IA e 5 skills de orquestração cobrindo três dimensões peer: produto (discovery a backlog), engenharia (planejamento a PR) e compliance (ISO 27001, SOC2, PMBOK). O Onion se conecta ao seu gerenciador de tarefas existente (Jira, ClickUp, Asana ou Linear) via uma camada de abstração agnóstica. Não é uma CLI, não tem npm, não requer mudança de stack — é pura configuração que transforma o Claude Code no cérebro orquestrador do seu fluxo de trabalho.

*(Fontes: CLAUDE.md §Inventário; onion-review-2026-05.md §1 Sumário Executivo)*

---

### 10 minutos (versão técnica)
O Sistema Onion é um **framework template instalável em `.claude/`** que orquestra o ciclo completo de desenvolvimento com Claude Code como plataforma única. A identidade foi consolidada em 2026-05-18 após abandonar formalmente as direções de CLI standalone, multi-IDE e estrutura `.onion/` — a aposta é na profundidade de integração com Claude Code, não na portabilidade entre IDEs.

**Arquitetura em camadas:**

**Camada 1 — Comandos (.claude/commands/):** 82 arquivos Markdown invocáveis por categoria (`/product:*`, `/engineer:*`, `/git:*`, `/docs:*`, `/meta:*`, `/validate:*`, `/test:*`). Cada comando define seu `allowed-tools` (escopo de permissão), `model` (tier de custo) e lógica de orquestração. Comandos são workflows — definem *o que fazer e como*, não *quem sabe fazer*.

**Camada 2 — Agentes (.claude/agents/):** 49 especialistas de IA em 9 categorias (development, product, git, meta, compliance, testing, review, research, deployment). Agentes sabem *fazer* — são convocados pelos comandos ou diretamente pelo usuário. `@jira-specialist` faz JQL + ADF, `@metaspec-gate-keeper` valida arquitetura, `@react-developer` escreve componentes.

**Camada 3 — Skills (.claude/skills/):** 5 programas de orquestração de alto nível. `onion-fleet` é o mais poderoso: autora scripts Workflow nativos do Claude Code para fan-out paralelo de agentes, com tiering de modelos (haiku para scan/classificação, sonnet para raciocínio, opus para julgamento adversarial).

**Camada 4 — Abstrações (.claude/utils/):** SDAAL (Service Decoupled Abstraction Adapter Layer) em dois eixos — Task Manager (Jira/ClickUp/Asana/Linear) e Forge (GitHub/GitLab/Bitbucket). Os comandos nunca chamam APIs direto; delegam ao adapter que resolve transporte, formatação e fallback.

**Camada 5 — Documentação constitucional (docs/):** Meta-specs L0 (constituição), Knowledge Bases (34 documentos estruturados para consumo por IA), Business/Technical/Compliance Contexts (Spec as Code gerados por comandos `/docs:build-*`).

O ponto diferenciador: o ciclo é **tri-dimensional e simétrico** — Produto, Engenharia e Compliance são **peers**, não hierarquizados. Um usuário pode entrar pelo `@product-agent`, pelo `@engineer`, ou diretamente em `/validate:collab/three-amigos` — o framework não privilegia nenhuma dimensão.

*(Fontes: onion-review-2026-05.md §2; CLAUDE.md §Padrões Técnicos; getting-started.md §Estrutura de Diretórios)*

---

## 2. O PROBLEMA QUE RESOLVE

### Problema 1: O desenvolvedor orquestra manualmente o que a IA faz
**Sem Onion:** O dev escreve prompts ad-hoc a cada tarefa. Não há memória de workflow, sem padrões de delegação, sem tiering de agentes por complexidade.
**Com Onion:** 82 comandos são workflows codificados — `/engineer:plan` sabe que delegar planejamento a `@task-specialist` → Jira via adapter. O dev invoca; o framework orquestra.
*(Fonte: CLAUDE.md §Agentes Especializados; getting-started.md §Checklist)*

### Problema 2: Cada integração com task manager é um caso especial
**Sem Onion:** Um projeto usa Jira e outro ClickUp — o dev reescreve prompts e formatos para cada um. Jira exige ADF (JSON), ClickUp usa Unicode em comments, Asana aceita HTML.
**Com Onion:** Task Manager Abstraction (SDAAL) detecta `TASK_MANAGER_PROVIDER` no `.env` e roteia para o adapter correto, com formatação tipada por provider. O mesmo comando `/product:task` funciona em Jira ou ClickUp.
*(Fonte: CLAUDE.md §Task Manager; onion-review-2026-05.md §Top 5 forças — "Task Manager Abstraction madura")*

### Problema 3: Trabalho interrompido = contexto perdido
**Sem Onion:** Sessão interrompida → o dev precisa reexplicar o contexto completo na retomada.
**Com Onion:** Workflows faseados retomáveis com sessões persistentes em `.claude/sessions/`. O `STATE.md` é o ponteiro Tier-0 (~1KB) que um agente lê para retomar qualquer feature sem perguntar ao dev.
*(Fonte: CLAUDE.md §Workflows; onion-review-2026-05.md §Top 5 forças — "Workflows faseados retomáveis")*

### Problema 4: Compliance é um silo separado do desenvolvimento
**Sem Onion:** A documentação de ISO 27001 ou SOC2 é criada depois, manualmente, desconectada do que foi realmente entregue.
**Com Onion:** 5 agentes de compliance (iso-27001, iso-22301, soc2, pmbok, security-information-master) integrados ao mesmo ciclo. `/docs:build-compliance-docs` gera documentação de conformidade a partir do estado real do projeto.
*(Fonte: onion-review-2026-05.md §Top 5 forças — "Cobertura de compliance integrada")*

### Problema 5: Frotas de IA são caras e trabalhosas de montar
**Sem Onion:** Orquestrar 30 agentes em paralelo exige escrever scripts Workflow complexos manualmente, definir schemas, tierar modelos, lidar com falhas.
**Com Onion:** A skill `onion-fleet` autora scripts Workflow nativos com tiering automático (haiku/sonnet/opus), barrier + fan-in, verificação adversarial e fallback serial. Um comando `/meta:evolve` dispara 28 agentes em 8 dimensões sem o dev escrever um linha de orquestração.
*(Fonte: docs/analysis/onion-evolution-2026-06-15.md §0 Sumário — "28 agentes · 1.27M tokens · ~26 min")*

### Problema 6: Multi-repositório sem coordenação rompe integrações
**Sem Onion:** Mudanças cross-repo são coordenadas por Slack/docs manuais. Não há garantia de que um consumidor validou antes do produtor fazer merge.
**Com Onion:** Federation v2 — peer topology + ledger git. O produtor `publish` anuncia contratos, cada consumidor `check` valida em casa (1ª mão), `status` monitora drift. Humano-maestro dirige a ordem de merge.
*(Fonte: docs/analysis/onion-federation-design-v2-2026-06.md §1)*

### Problema 7: O framework envelhece e o dev não percebe
**Sem Onion:** Documentação e agentes ficam obsoletos silenciosamente. Ninguém audita.
**Com Onion:** `/meta:evolve` — auto-auditoria periódica em 8 dimensões via frota. Produz backlog priorizado com evidência citada e comando atuador por item. O framework se auto-diagnostica.
*(Fonte: docs/analysis/onion-evolution-2026-06-15.md §0 — "30 achados (2🔴·18🟡·10🟢)")*

### Problema 8: Não há padrão para quando usar paralelismo vs sequencial
**Sem Onion:** O dev não sabe quando fan-out paralelo é melhor que sessões sequenciais, ou quando Agent Teams agrega sobre Workflow.
**Com Onion:** KB `agent-fleet-orchestration` documenta os três substratos (sessões faseadas / Workflow / Agent Teams) com tabela de decisão, critérios e fallback gracioso. O padrão é codificado, não deixado à memória do dev.
*(Fonte: docs/knowledge-base/concepts/agent-fleet-orchestration.md §"Dois Substratos de Orquestração")*

---

## 3. ARQUITETURA EM CAMADAS

### Diagrama de componentes

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code (plataforma)                 │
├─────────────────────────────────────────────────────────────┤
│  SKILLS (.claude/skills/)        ← orquestração de alto nível │
│    onion · onion-fleet · onion-patterns · language-standards  │
├──────────────────┬──────────────────────────────────────────┤
│  COMMANDS        │  AGENTS (.claude/agents/)                │
│  (.claude/       │  49 especialistas em 9 categorias:       │
│  commands/)      │    development · product · git           │
│  82 workflows    │    meta · compliance · testing           │
│  em 9 categorias │    review · research · deployment        │
├──────────────────┴──────────────────────────────────────────┤
│  ABSTRAÇÕES (.claude/utils/)                                │
│    Task Manager (Jira/ClickUp/Asana/Linear)  [SDAAL]        │
│    Forge (GitHub/GitLab) [SDAAL]                            │
├─────────────────────────────────────────────────────────────┤
│  DOCUMENTAÇÃO CONSTITUCIONAL (docs/)                        │
│    Meta-specs L0 · Knowledge Bases (34) · Spec as Code      │
│    Sessions (.claude/sessions/) — gitignored, persistentes  │
└─────────────────────────────────────────────────────────────┘
```

### Fluxo de uma feature típica

```
/product:collect → /product:spec → /product:task
   ↓
/engineer:start (cria worklog STATE.md)
   ↓
/engineer:work (retomável — lê STATE.md)
   ↓
/engineer:pre-pr (@branch-metaspec-checker + testes)
   ↓
/engineer:pr (forge adapter → GitHub PR)
   ↓
/git:sync (cleanup + archive session)
```

### Padrão SDAAL (Service Decoupled Abstraction Adapter Layer)
O Onion usa SDAAL em duas camadas de integração:
- **Task Manager:** `TASK_MANAGER_PROVIDER` define qual adapter ativo. Comandos chamam `taskManager.create()` — o adapter resolve para `POST /rest/api/3/issue` (Jira) ou `ClickUp list task` (ClickUp).
- **Forge:** `FORGE_PROVIDER` define o host remoto. `/engineer:pr` chama `forge.createPR()` — o adapter usa `gh pr create` (GitHub cli) ou REST (fallback).

**Por que isso importa:** o mesmo comando funciona em projetos com stacks de tools diferentes, sem reescrita.

---

## 4. CAPACIDADES POR CATEGORIA

### Produto & Discovery
| Capacidade | Comando | Exemplo concreto |
|------------|---------|------------------|
| Coletar requisitos | `/product:collect` | Entrevistar usuário, estruturar em história |
| Refinar especificação | `/product:refine` | Gap analysis, critérios de aceite |
| Especificação completa | `/product:spec` | Gerar spec pronta para `/engineer:plan` |
| Transcrição de reunião | `/product:whisper` | Áudio → ata estruturada |
| Extração de ata | `/product:extract-meeting` | Ata bruta → decisions/actions |
| Análise de dor do cliente | `/product:analyze-pain-price` | JTBD + precificação |
| Converter em tasks | `/product:convert-to-tasks` | Spec → hierarquia Jira/ClickUp |

### Engenharia & GitFlow
| Capacidade | Comando | Exemplo concreto |
|------------|---------|------------------|
| Planejar feature | `/engineer:plan` | Fases retomáveis, STATE.md |
| Iniciar dev | `/engineer:start` | Cria worklog, branch GitFlow |
| Retomar dev | `/engineer:work` | Lê STATE.md, continua fase [ACTIVE] |
| Gate pré-PR | `/engineer:pre-pr` | Lint, testes, metaspec-checker |
| Abrir PR | `/engineer:pr` | forge adapter → PR com link da task |
| Hotfix urgente | `/engineer:hotfix` | Branch hotfix, PR fast-track |

### Qualidade & Compliance
| Capacidade | Agente/Comando | Exemplo concreto |
|------------|----------------|------------------|
| Code review | `@code-reviewer` | Bugs, patterns, manutenibilidade |
| Review de branch | `@branch-code-reviewer` | Diff-scoped pré-PR |
| Testes unitários | `/test:unit` | Gerar + executar suíte |
| ISO 27001 | `@iso-27001-specialist` | Política SGSI, risk assessment |
| SOC2 Type II | `@soc2-specialist` | Controles + coleta de evidências |
| Validação arquitetural | `@metaspec-gate-keeper` | Conformidade L0/L1+ |

### Orquestração & Frota
| Capacidade | Mecanismo | Quando usar |
|------------|-----------|-------------|
| Fan-out paralelo | Workflow + `onion-fleet` | Auditoria, migração, review amplo |
| Sessões retomáveis | `.claude/sessions/` + STATE.md | Feature de longa duração |
| Agent Teams (opt-in) | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Negociação peer-a-peer viva |
| Federation multi-repo | `/meta:federation-*` | Coordenação cross-repo sem quebrar contratos |

### Meta (Auto-Evolução)
| Capacidade | Comando |
|------------|---------|
| Auto-auditoria | `/meta:evolve` — 8 dimensões, frota, backlog priorizado |
| Frescor de KBs | `/meta:kb-freshness` — veredito CURRENT/STALE/HISTORICAL |
| Criar novo agente | `/meta:create-agent` — contextualizado no ecossistema |
| Criar novo comando | `/meta:create-command` |
| Validar conformidade | `/meta:metaspec-validate` |
| Inventário automático | `/meta:inventory` — SSOT gerada do filesystem |

---

## 5. HISTÓRIAS CANDIDATAS A CASE STUDY

### Case Study 1: Federation v2 — "Coordenação Multi-Repo Sem Quebrar Nada"

**Situação:** Time com múltiplos repositórios que se integram (ex: API + frontend + infra). Qualquer mudança de contrato num repo pode quebrar os outros. A coordenação era manual — Slack + esperança.

**O que o Onion fez:**
1. Design adversarial: 42 agentes revisaram o design v1 (hub centralizado) → 24/36 achados críticos → pivot para topologia peer com ledger git.
2. Implementação em 4 fases: KB (ledger como working dir adicional) → register (validar+gravar contrato) → publish+check (anúncio + veto do consumidor) → status+rollback (monitor + recovery).
3. Cada repo roda `/meta:federation-check` localmente — valida com conhecimento de 1ª mão.
4. Rollback coordenado: order inversa, pin de versão, gate humano para falhas parciais.

**Resultado:** Ciclo completo `register→publish→check→status→rollback` implementado em 4 PRs. Mudança cross-repo testável: tentativa incompatível bloqueada com mensagem acionável.

**Citação:** *"Cada Onion defende seus interesses — o repo dono valida localmente as mudanças que o afetam (conhecimento de 1ª mão)"* — [onion-federation-design-v2-2026-06.md §2]

---

### Case Study 2: /meta:evolve — "O Framework se Auto-Auditando"

**Situação:** Após um ciclo grande de mudanças (Cursor→native migration, federation, novos comandos), o framework estava sem auditoria formal. O mantenedor precisava de um "raio-X de saúde" — sem fazer isso manualmente.

**O que o Onion fez:**
1. `/meta:evolve` disparou 28 agentes em 8 dimensões (D1-D8) — peso, redundância, duplicação, KBs stale, conformidade, legado, links, frontmatter.
2. Em 26 minutos: 1.27M tokens, 635 tool-uses, 41 achados brutos.
3. Juiz adversarial (opus): 11 refutados (ex: fusões D2 de "diferenciação real"), 30 sobreviventes.
4. Backlog priorizado com evidência citada (`arquivo:linha`) e comando atuador por item.
5. Todo o backlog foi executado: 8 PRs, MCP-first sweep, INDEX reconciliado, 51 comandos com allowed-tools, D4 calibrado.

**Resultado:** 30 achados → 0 pendentes. Framework auto-diagnosticou e executou o plano de cura.

**Citação:** *"28 agentes (8 auditores + ~19 juízes + critic) · 1.27M tokens · 635 tool-uses · ~26 min"* — [onion-evolution-2026-06-15.md §0 Sumário]

---

### Case Study 3: Agent Teams — "Decidindo Não Adotar (Com Evidência)"

**Situação:** A Anthropic lança uma feature experimental: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. A pergunta: o Onion deve adotar como padrão? Mudar toda a doutrina de frota?

**O que o Onion fez:**
1. Smoke-test empírico: TeamCreate → TaskCreate → SendMessage round-trip PASS.
2. Demo real com time dividido por tarefas e `owner`/`blockedBy`.
3. Avaliação estruturada: três primitivas mapeadas (sessões faseadas / Workflow / Agent Teams), cada uma com seu nicho, limitações e quando preferir.
4. ADR documentado com critérios: experimental + gated + acoplado a versão = não virar padrão obrigatório.

**Resultado:** Decisão opt-in/3º modo com detecção de capacidade + fallback gracioso. Os padrões existentes foram mantidos. A decisão foi documentada como ADR e sintetizada na KB de doutrina de frota.

**Citação:** *"Workflow = orquestração que o orquestrador desenha (a forma é conhecida antes de começar). Agent Teams = coordenação que emerge (os agentes se acertam em runtime)."* — [onion-agent-teams-evaluation-2026-06.md §3]

---

### Case Study 4: Cursor→Claude Code Native — "Corrigindo o Propagador"

**Situação:** 49 agentes usavam nomes de ferramentas do dialeto Cursor (`create_file`, `rewrite_file`, `search_files`). O Claude Code usa nomes nativos (`Write`, `Edit`, `Grep`). O lint REGRA 12 estava errado — validava o dialeto errado.

**O que o Onion fez:**
1. Diagnosticou o padrão: `agent-template.md` era o propagador — cada agente novo herdava os nomes errados.
2. Corrigiu o propagador PRIMEIRO (PR #44), não as 49 folhas.
3. Fan-out paralelo: migrou 49 agentes em 2 PRs (#42, #43).
4. Corrigiu o lint (Regra 12) para validar os nomes corretos.

**Resultado:** 100% dos agentes com tool names nativos. Lint atualizado. Zero falsos positivos.

**Citação:** *"Conserta o propagador, não só as folhas"* — lição salva na memória de IA como padrão.

---

### Case Study 5: D8 allowed-tools — "Capability Surface como Política"

**Situação:** Evolve D8 identificou que 51 de 82 comandos não tinham `allowed-tools` declarado — campo que define quais ferramentas o Claude Code pode usar ao executar aquele comando. A ausência é um vazio de política: o agente pode usar qualquer coisa.

**O que o Onion fez:**
1. Fan-out: 51 workers haiku leram cada comando e propuseram o `allowed-tools` mínimo adequado.
2. Revisão humana: o mantenedor revisou cada proposta (nenhum `Bash(gh *)` foi aceito em comandos que deveriam usar forge adapter).
3. Aplicação: PR #60 com 51 comandos atualizados.
4. Insight capturado: `allowed-tools` = capability surface real, não documentação. Prosa que diz "nunca use gh" mas `allowed-tools` contém `Bash(gh *)` = inconsistência real.

**Resultado:** 82/82 comandos com `allowed-tools` escoped. Insight salvo como memória de IA.

---

## 6. MÉTRICAS E EVIDÊNCIAS

| Métrica | Valor | Fonte |
|---------|-------|-------|
| Comandos invocáveis | 82 (9 categorias) | CLAUDE.md §Inventário |
| Agentes especializados | 49 (9 categorias) | CLAUDE.md §Inventário |
| Skills | 5 | CLAUDE.md §Inventário |
| Knowledge Bases | 34 | docs/onion/inventory.md |
| Task Manager providers suportados | 4 (Jira, ClickUp, Asana, Linear) | CLAUDE.md §Task Manager |
| PRs em uma única sessão de auto-evolução | 22 | sessions/INDEX.md |
| Workers no /meta:evolve | 28 agentes | onion-evolution-2026-06-15.md §0 |
| Tokens no /meta:evolve | 1.27M | onion-evolution-2026-06-15.md §0 |
| Tool-uses no /meta:evolve | 635 | onion-evolution-2026-06-15.md §0 |
| Duração do /meta:evolve | ~26 min | onion-evolution-2026-06-15.md §0 |
| Achados de auditoria D1 (peso) | 0 outliers | onion-evolution-2026-06-15.md §2 — "framework dentro dos limites" |
| Agentes migrados Cursor→native | 49/49 (100%) | sessions archives jun/2026 |
| Comandos com allowed-tools após D8 | 82/82 (100%) | PR #60 |
| Dimensões da auto-auditoria | 8 (D1–D8) | evolve.md §Dimensões |
| Fases de federation implementadas | 5 (0→register, 1→publish, 2→check, 3→status, 4→rollback) | multi-repo-federation.md |

---

## 7. POSICIONAMENTO

### O que o Onion NÃO é (decidido formalmente)

| Direção abandonada | Quando | Por quê |
|--------------------|--------|---------|
| CLI standalone (`packages/onion-cli/`) | 2026-05-18 | Distribui como produto; Onion é template instalável |
| Multi-IDE (Cursor, Zed, Windsurf) | 2026-05-18 | Dilui integração; Claude Code é a plataforma certa |
| `.onion/` agnóstico | 2026-05-18 | Abstração prematura sem ganho real |
| v4.0 FASES 5-9 (aprendizado contínuo, A2A runtime) | 2026-05-18 | Beira agente autônomo fora de controle; humano como maestro é invariante |

*(Fonte: onion-review-2026-05.md §4 "Heranças do Roadmap Abandonado"; CLAUDE.md §Identidade canônica)*

### Diferenciação de "cursor rules" ou prompt engineering simples

| Dimensão | Cursor rules / prompts ad-hoc | Sistema Onion |
|----------|-------------------------------|---------------|
| Escopo | Instruções para uma sessão | Framework reutilizável instalável |
| Task Manager | Não existe | 4 providers via SDAAL (API-first) |
| Compliance | Não existe | ISO 27001, SOC2, PMBOK integrados |
| Orquestração | Manual, caso a caso | 82 workflows + 49 agentes + 5 skills |
| Multi-repo | Não existe | Federation v2 com peer topology |
| Auto-evolução | Não existe | /meta:evolve auto-audita 8 dimensões |
| Sessions retomáveis | Não existe | STATE.md + worklog persistente |
| Abstração de integração | Não existe | SDAAL (Task Manager + Forge) |

### Público-alvo ideal

1. **Dev/tech lead com projeto legado** que quer estruturar o uso de IA no dia a dia sem mudar stack ou criar ferramentas novas.
2. **Startup técnica** com produto digital + Jira/ClickUp + GitHub que quer acelerar o ciclo produto→eng sem contratar mais headcount.
3. **Time regulado** (fintech, healthtech, saas enterprise) que precisa de compliance (ISO 27001/SOC2) integrado ao fluxo de desenvolvimento, não como silo.
4. **Mantenedor de múltiplos repos** que coordena mudanças cross-repo com garantia de não quebrar integrações.

*(Fonte: onion-review-2026-05.md §1 "Reposicionamento" — "framework reutilizável para aplicação em projeto-alvo")*

---

## 8. FAQ CANDIDATOS

**P: Preciso mudar meu stack para usar o Onion?**
R: Não. O Onion vive inteiramente em `.claude/` — uma pasta de configuração do Claude Code. Seu código, linguagem, framework e infra não são tocados.

**P: Funciona com qualquer gerenciador de tarefas?**
R: Sim, se for Jira, ClickUp, Asana ou Linear. Define `TASK_MANAGER_PROVIDER` no `.env` e o adapter correto assume automaticamente. Para outros providers, o modo `none` permite uso offline.

**P: Precisa de Claude Code pago ou funciona no plano gratuito?**
R: O Onion usa o Claude Code como plataforma. As frotas de agentes (como `/meta:evolve`) consomem tokens substancialmente — 1.27M tokens numa auditoria completa. Uso moderado funciona em planos menores; frotas pesadas favorecem planos ilimitados.

**P: O Onion substitui o GitFlow?**
R: Não — complementa. Os comandos `/engineer:*` e `/git:*` são orientados pelo motor GitFlow documentado em `gitflow-patterns.md`. O Onion adiciona sessões retomáveis, gates de qualidade automatizados e integração com task manager sobre o GitFlow existente.

**P: O que acontece se o Claude Code lançar uma feature incompatível?**
R: O framework tem meta-specs L0 (constituição) e `/meta:evolve` para auto-auditoria. Mudanças de plataforma geram achados de D6 (legado/modernização) que o mantenedor executa. A migração Cursor→Claude Code native em 49 agentes é um exemplo real disso.

**P: Funciona em projetos legados sem testes?**
R: Sim. O Onion foi projetado para "qualquer projeto (novo, legado ou regulado)". Para projetos sem testes, os agentes `/test:*` e `@branch-test-planner` ajudam a estabelecer cobertura.

**P: Qual é o esforço de instalação?**
R: Copiar a pasta `.claude/` para o projeto, configurar `.env` com o provider de task manager e forge, e executar `/warm-up` para calibrar o contexto. Um dev experiente faz em menos de 2 horas.

**P: Posso usar só partes do Onion?**
R: Sim. As três dimensões (produto, engenharia, compliance) são peer — pode começar só com `/engineer:*` e adicionar produto/compliance depois. Os adapters só são ativados se as variáveis do `.env` estiverem configuradas.

**P: Agent Teams substitui o Workflow para frotas?**
R: Não. São substratos complementares. Workflow = orquestração determinística de forma conhecida (melhor para auditoria, migração, review). Agent Teams = coordenação emergente peer-a-peer (melhor para negociação viva entre sub-streams). O Onion usa Workflow por padrão; Agent Teams é opt-in.

**P: O Onion funciona com monorepo?**
R: Sim. Os agentes `@nx-monorepo-specialist` e `@nx-migration-specialist` são especializados em NX. O Onion foi validado em repositórios NX.

**P: O que é o /meta:evolve e por que é relevante?**
R: É a auto-auditoria do framework — dispara 28 agentes em 8 dimensões (peso, redundância, duplicação, KBs stale, conformidade arquitetural, legado, links, frontmatter) e produz backlog priorizado com evidência citada. Na prática: o framework se diagnostica periodicamente sem mantenedor olhar manualmente para cada artefato.

**P: Como funciona o compliance integration?**
R: Os agentes `@iso-27001-specialist`, `@soc2-specialist`, etc. leem o estado atual do projeto (código, arquitetura, processos documentados) e geram ou atualizam documentação de conformidade. O orquestrador `@security-information-master` detecta qual framework de compliance aplicar.

---

## 9. FRASES DESTACADAS (para press kit / landing page)

1. *"Framework template em `.claude/` projetado para ser instalado e aplicado em qualquer projeto — novo, legado ou regulado — para orquestrar o ciclo completo de desenvolvimento com Claude Code."*
   — CLAUDE.md (identidade canônica)

2. *"As três dimensões são peer, não hierarquizadas."* — Product, Engenharia, Compliance como iguais.
   — onion-review-2026-05.md §1

3. *"O sistema não está pronto para ser aplicado a um projeto-alvo sem mantenedor de plantão"* [maio/2026] → *[jun/2026] o plano foi 100% executado.*
   — onion-review-2026-05.md §1 (veredito honest) + nota de execução

4. *"Workflow = orquestração que o orquestrador desenha. Agent Teams = coordenação que emerge."*
   — onion-agent-teams-evaluation-2026-06.md §3

5. *"Cada Onion defende seus interesses — o repo dono valida localmente as mudanças que o afetam."*
   — onion-federation-design-v2-2026-06.md §2

6. *"28 agentes · 1.27M tokens · 635 tool-uses · ~26 min"* — O que uma auto-auditoria completa custa.
   — onion-evolution-2026-06-15.md §0

7. *"Read-only por contrato. O comando nunca muta `.claude/`; a única escrita é o relatório em `docs/analysis/`."*
   — evolve.md §Objetivo (sobre o /meta:evolve)

8. *"Conserta o propagador, não só as folhas."* — Princípio de refatoração em escala.
   — sessão archives jun/2026 (lição da migração Cursor→native)

9. *"Task Manager Abstraction madura — padrão SDAAL real, 4 adapters, fallback gracioso, formatação tipada por provider."*
   — onion-review-2026-05.md §Top 5 forças

10. *"O veredito: substantialmente completo em cobertura."*
    — onion-review-2026-05.md §1 (estado pós P0–P3 executados)
