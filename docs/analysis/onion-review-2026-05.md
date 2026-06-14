---
title: Revisão Analítica do Sistema Onion — Maio/2026
date: 2026-05-18
author: Sistema Onion (assistido por IA)
status: snapshot
scope: framework-template-instalavel
abandonado:
  - estrutura .onion/
  - plano de implementação v4.0 (FASES 5-9)
  - packages/onion-cli/ (a ser removido)
predecessores-historicos:  # removidos do repo (curadoria 2026-06-14); recuperáveis via git history
  - onion-system-critical-analysis-2025.md
  - onion-complete-cycle-understanding.md
  - onion-multi-context-orchestrator-vision.md
plano-execucao: onion-saneamento-plan-2026-05.md  # executado e removido; ver git history
---

# Revisão Analítica do Sistema Onion — Maio/2026

## Sumário

1. [Sumário Executivo](#1-sumário-executivo)
2. [Arquitetura e Estrutura](#2-arquitetura-e-estrutura)
   - 2.1 Inventário Quantitativo
   - 2.2 Balanceamento de Categorias (Três Dimensões do Ciclo)
   - 2.3 Duplicação de Nomes Entre Categorias
   - 2.4 Workflows Faseados vs Sobreposição Real
   - 2.5 Padrões Estruturais
   - 2.6 Task Manager Abstraction
3. [Saúde da Documentação](#3-saúde-da-documentação)
   - 3.1 Meta-specs do Onion vs Contextos do Projeto-alvo
   - 3.2 Spec as Code Multi-Context (templates por design)
   - 3.3 Knowledge Bases
   - 3.4 Memória de IA
4. [Heranças do Roadmap Abandonado](#4-heranças-do-roadmap-abandonado)
5. [Riscos e Sustentabilidade](#5-riscos-e-sustentabilidade)
6. [Recomendações Priorizadas](#6-recomendações-priorizadas)
7. [Conclusão e Próximos Passos](#7-conclusão-e-próximos-passos)

---

## 1. Sumário Executivo

### Estado do sistema em 2026-05-18

O Sistema Onion é um **framework template em `.claude/`** projetado para ser instalado e aplicado em qualquer projeto — novo, legado ou regulado — para orquestrar produto, engenharia e compliance com Claude Code. Não é produto npm, não é distribuído publicamente, não tem CLI standalone. Em maio de 2026, foram formalmente abandonadas duas direções estratégicas anteriores: a estrutura `.onion/` agnóstica e o plano de implementação v4.0 (FASES 5-9, incluindo `packages/onion-cli/`).

**Volume**: 94 comandos em 11 categorias + 49 agentes em 9 categorias + 1 skill + 24 knowledge bases + Task Manager Abstraction multi-provider (Jira, ClickUp, Asana, Linear).

**Maturidade**: substancialmente completo em cobertura, **pré-aplicável** em validação formal e camada operacional para uso externo.

### Reposicionamento

A análise foi conduzida sob a lente "framework reutilizável para aplicação em projeto-alvo", não "workspace de uso pessoal". Isso muda o critério para "que comandos merecem ficar": não é "usados pelo mantenedor no dia a dia", é "fazem sentido quando o Onion é instalado em projeto novo, legado ou regulado".

O ciclo coberto é tri-dimensional e simétrico:

- **Produto** — 22 comandos + 8 agentes — discovery, refinamento, especificação, decomposição de tasks
- **Engenharia** — 12 comandos + 20 agentes em `development/` — planejamento, sessões retomáveis, ciclo de PR
- **Compliance** — 5 agentes + `/docs:build-compliance-docs` — ISO 27001, ISO 22301, SOC2, PMBOK

As três dimensões são **peer**, não hierarquizadas.

### Top 5 forças identificadas

1. **Task Manager Abstraction madura** — padrão SDAAL real, 4 adapters (Jira, ClickUp, Asana, Linear), fallback gracioso, formatação tipada por provider
2. **Workflows faseados retomáveis** — `engineer/plan→pr-update` e `product/collect→feature` são ciclos com sessões persistentes, não duplicação
3. **Cobertura de compliance integrada** — frameworks ISO 27001/22301, SOC2, PMBOK com orquestrador (`@security-information-master`), raro em frameworks de orquestração com IA
4. **Knowledge bases ricas em pt-BR** — 24 KBs estruturadas para consumo por IA, cobrindo conceitos, frameworks, ferramentas
5. **Identidade convergente após descope** — abandonando `.onion/` e v4, a direção do framework ficou clara e focada

### Top 5 fraquezas / riscos sob a nova lente

1. **5 meta-specs marcadas "A CRIAR" há ~6 meses** — `@metaspec-gate-keeper` sem base normativa, validação arquitetural vira opinião
2. **Três análises críticas de 2025-12-20 sem marcação histórica** — propõem visões abandonadas; operador externo lê e forma mapa mental errado
3. **Ausência de guias operacionais por cenário** — não há documentação clara para "Onion em projeto novo", "Onion em projeto legado", "Onion em projeto regulado"
4. **`packages/` com `onion-cli` ainda no repositório** — confirmado para remoção, mas presente; sinaliza visão não realizada
5. **Memória IA com 1 entrada substantiva** — decisões e gotchas não acumulam, cada conversa nova começa sem rastro

### Veredito

O sistema **não está pronto para ser aplicado a um projeto-alvo sem mantenedor de plantão**, apesar de ter todas as peças necessárias. Três bloqueios operacionais explicam o "ainda não":

1. Documentação e KBs ainda descrevem visões abandonadas (resolvido em **P0**)
2. Meta-specs ausentes deixam padrões implícitos e validação vaga (resolvido em **P2**)
3. Guias operacionais por cenário não existem (resolvido em **P3**)

Resolvendo as 19 recomendações priorizadas nas seções P0-P3, o framework passa para estado **aplicável** — operador externo consegue instalar e usar sem consultar o mantenedor.

### Próximo passo concreto

Aprovar o plano de execução `onion-saneamento-plan-2026-05.md` e executar P0 nos próximos 7 dias. _(Nota 2026-06-14: o plano foi 100% executado — P0–P3 e backlog v1/v2 nos PRs #16–#27 — e removido do repo; recuperável via git history.)_

---


## 2. Arquitetura e Estrutura

Esta é a seção principal da análise. O Onion é, antes de tudo, uma arquitetura de componentes: comandos (workflows), agentes (especialistas), skills (cérebro), utilitários (abstrações) e documentação (constituição). Avaliar arquitetura significa avaliar se essas peças encaixam, se cobrem o ciclo declarado e se podem ser aplicadas a um projeto-alvo sem precisar de retrabalho.

### 2.1 Inventário Quantitativo

Estado em 2026-05-18 (fonte: [docs/INDEX.md](../INDEX.md) + inventário direto em `.claude/`):

| Recurso | Quantidade | Distribuição |
|---|---|---|
| Comandos Claude Code | **94** | 11 categorias + 2 no root (`onion.md`, `warm-up.md`) |
| Agentes especializados | **49** | 9 categorias |
| Skills `.claude/skills/` | **1** | `onion` (orquestrador) |
| Arquivos de documentação | **64+** markdown | `docs/` |
| Knowledge Bases | **24** | 5 categorias (concepts, frameworks, tools, platforms, providers) |

**Volume agregado de prompts**:

- ~23.400 linhas em comandos (~509 linhas/comando em média)
- ~29.600 linhas em agentes (~1.186 linhas/agente em média)
- Total: **~53.000 linhas de prompts ativos** mantidos pelo framework

**Outliers de tamanho**:

- Maior comando: [.claude/commands/validate/test-strategy/analyze.md](../../.claude/commands/validate/test-strategy/analyze.md) — 1.134 linhas
- Maior agente: [.claude/agents/meta/command-creator-specialist.md](../../.claude/agents/meta/command-creator-specialist.md) — 1.519 linhas
- Menor comando: [.claude/commands/engineer/docs.md](../../.claude/commands/engineer/docs.md) — 10 linhas
- 85/91 comandos (~93%) têm headers YAML documentados — 6 sem cabeçalho

A leitura inicial dos números pode sugerir "inchaço". Mas isso só faz sentido se o framework fosse pensado para uso isolado. Como **biblioteca reutilizável aplicável em projetos diversos**, o critério não é "quantos comandos cabem no dia a dia do mantenedor" — é "quantas peças o framework precisa carregar para cobrir projetos novos, legados e regulados".

### 2.2 Balanceamento de Categorias — As Três Dimensões do Ciclo

**Princípio orientador**: o Onion cobre o ciclo completo de desenvolvimento em três dimensões — **produto**, **engenharia** e **compliance/governança**. Alta densidade nessas três dimensões é esperada e legítima, não problema.

#### Dimensão Produto

**Comandos** (22): `product/collect`, `product/refine`, `product/spec`, `product/task`, `product/estimate`, `product/feature`, `product/check`, `product/light-arch`, `product/branding`, `product/whisper`, `product/presentation`, `product/validate-task`, `product/task-check`, `product/extract-meeting`, `product/consolidate-meetings`, `product/convert-to-tasks`, `product/transform-consolidated`, `product/analyze-pain-price`, `product/checklist-sync`, `product/warm-up`, `product/README`, `product/refine`.

**Agentes** (8): `product-agent`, `task-specialist`, `story-points-framework-specialist`, `storytelling-business-specialist`, `branding-positioning-specialist`, `pain-price-specialist`, `extract-meeting-specialist`, `meeting-consolidator`.

**Cobertura**: discovery, refinamento, especificação, decomposição de tarefas, estimativas, branding, extração e consolidação de reuniões, validação de implementação.

#### Dimensão Engenharia

**Comandos** (12): `engineer/plan`, `engineer/start`, `engineer/work`, `engineer/pre-pr`, `engineer/pr`, `engineer/pr-update`, `engineer/hotfix`, `engineer/bump`, `engineer/docs`, `engineer/warm-up`, `engineer/validate-phase-sync`, mais um.

**Agentes** (20 em `development/` — 41% do total): especialistas técnicos em React, Node.js, NX, C4, Mermaid, Docker, Postgres, Linux Security, NX Migration, Jira, ClickUp, Gamma API, Runflow, Whisper, ZEN Engine, GitFlow, Storypoints, e demais.

**Cobertura**: planejamento, sessões de desenvolvimento retomáveis, ciclo de PR, hotfix, versionamento, especialização técnica vertical.

#### Dimensão Compliance e Governança

**Comandos**: `/docs:build-compliance-docs` (gerador de contexto) e a categoria `validate/` (6 comandos: workflow validation, test-strategy create/analyze, qa-points estimate, three-amigos, pair-testing).

**Agentes** (5 em `compliance/`): `iso-27001-specialist`, `iso-22301-specialist`, `soc2-specialist`, `pmbok-specialist`, `corporate-compliance-specialist`, mais o orquestrador `security-information-master`.

**Cobertura**: SGSI ISO 27001:2022, BCMS ISO 22301:2019, SOC2 Type II, PMBOK 7th, compliance corporativo, detecção e roteamento entre frameworks regulatórios.

#### Categorias de Apoio (Transversais)

`git/` (13 comandos, 4 agentes — GitFlow, feature/release/hotfix, code-review, sync), `docs/` (11 comandos — build/validate/consolidate/index), `meta/` (10 comandos, 5 agentes — criação de comandos/agentes/skills/KBs, integration setup), `common/` (12 templates e prompts), `test/` (3 comandos), `validate/` (6 comandos), `quick/` (1), `development/` (1 comando), `global/` (1).

#### Conclusão sobre balanceamento

Cada dimensão deve ser **completa para sua função no ciclo**, não comparável quantitativamente entre as outras. Os 22 comandos de `product/` não são "inflação" — são o lado simétrico dos 12 comandos de `engineer/` somados aos 6 comandos de `validate/`. O peso aparente em `development/` (20 agentes) reflete a realidade de que cobertura técnica vertical exige especialistas múltiplos.

A única real assimetria preocupante são as **categorias de 1 elemento** (`quick/`, `development/` comandos, `global/`) — verificar se são placeholders inacabados ou se representam funções genuinamente atômicas.

### 2.3 Duplicação de Nomes Entre Categorias

Existem nomes que aparecem em mais de uma categoria de comandos: `README`, `warm-up`, `estimate`, `start`, `finish`, `help`. Casos concretos:

- `warm-up` em `product/`, `engineer/`, e no root (`warm-up.md`)
- `README` em `product/`, `git/`, `common/`
- `help` em `git/`, `docs/`
- `start` em `engineer/`, `git/feature/`, `git/hotfix/`, `git/release/`
- `finish` em `git/feature/`, `git/hotfix/`, `git/release/`
- `estimate` em `product/`, `validate/qa-points/`

**Risco real**: ambiguidade em busca/discoverability — `/<tab>` ou pesquisa textual retorna múltiplos hits. Para um operador externo aplicando o Onion em projeto novo, isso confunde.

**Avaliação**: a duplicação **não é defeito de design** quando contextualizada pela categoria-pai (o `start` de `git/feature/` é o início de feature branch; o `start` de `engineer/` é o início de sessão de desenvolvimento). O problema é que a invocação real frequentemente usa apenas o nome final — `start` sem prefixo — e o operador precisa saber qual escolher.

Solução não é renomear arbitrariamente — é **documentar a convenção** em meta-spec `commands.md` (ver Seção 6, P2): cada nome curto deve ter uma **categoria canônica** documentada, e variantes em outras categorias devem usar nome explícito.

### 2.4 Workflows Faseados vs Sobreposição Real

Esta é a distinção mais importante da análise estrutural. Antes de qualquer recomendação de "fusão" ou "remoção", a análise precisa separar:

- **Workflow faseado intencional**: múltiplos comandos cobrindo fases distintas de um mesmo fluxo (planejar → iniciar → executar → entregar), com **estado retomável entre fases**.
- **Sobreposição real**: comandos que fazem efetivamente a mesma coisa com nomes diferentes.

#### Workflows faseados — preservar

O Onion implementa dois workflows faseados principais, ambos com sessões persistentes em `.claude/sessions/`:

**Workflow de Engenharia** (6 fases):

```
engineer/plan → engineer/start → engineer/work → engineer/pre-pr → engineer/pr → engineer/pr-update
```

- `plan` analisa requisitos e cria plano estruturado
- `start` cria sessão de desenvolvimento e analisa tasks
- `work` retoma sessão e identifica próxima fase
- `pre-pr` valida padrões e qualidade antes do PR
- `pr` cria Pull Request com integração GitFlow e sync
- `pr-update` atualiza PR existente com mudanças adicionais

Cada comando tem **momento próprio**, **input próprio**, **estado próprio**. Não é duplicação — é granularidade de controle de fluxo que permite **interrupção e retomada** entre sessões.

**Workflow de Produto** (sequência canônica documentada):

```
product/collect → product/refine → product/spec → product/task → product/estimate → product/feature
```

- `collect` coleta novas ideias de features ou bugs
- `refine` refina requisitos através de perguntas de esclarecimento
- `spec` cria especificação a partir de requisitos
- `task` decompõe em tasks/subtasks/action items
- `estimate` aplica framework de story points
- `feature` cria task de feature no gerenciador configurado

Também faseado, também retomável, também **não consolidar**.

#### Sobreposição real — investigar caso a caso

Há pares/trios de agentes com nomes semelhantes cuja diferenciação não está evidente apenas pelo nome:

- `code-reviewer` vs `branch-code-reviewer` — descrição sugere "review prático geral" vs "review pré-PR focado em branch atual". Diferenças válidas ou redundância?
- `test-engineer` vs `test-agent` vs `test-planner` — implementação vs estratégia completa vs planejamento de cobertura. Três escopos legítimos ou três níveis de uma mesma coisa?
- `branch-code-reviewer` vs `branch-test-planner` vs `branch-documentation-writer` vs `branch-metaspec-checker` — quarteto de agentes pré-PR. Coerência boa, mas cada um suficiente isoladamente?

**Recomendação**: ler os YAMLs lado a lado e fundir **somente** se a sobreposição for confirmada como real. Diferenciação real é valor; diferenciação imaginada por similaridade de nome é débito.

#### Hierarquia e discoverability

O Sistema de Níveis (antes descrito em `docs/onion/levels-system.md`, doc removido em 2026-06-03 por estar atrelado à visão v4.0 abandonada) era o mecanismo previsto para hierarquizar comandos por familiaridade do operador (starter, intermediate, advanced). Validar empiricamente: o `levels-system` cobre adequadamente tanto o ciclo product/* quanto o engineer/* como **ciclos completos**, não como conjunto de comandos isolados?

### 2.5 Padrões Estruturais

**Headers YAML**: 85/91 (~93%) dos comandos têm frontmatter documentado. Os 6 restantes são casos a investigar — provavelmente comandos curtos de redirecionamento.

**Distribuição de tamanho**:

| Faixa | Comandos | Agentes |
|---|---|---|
| < 50 linhas | 4 | 0 |
| 50-200 linhas | ~30 | ~5 |
| 200-500 linhas | ~50 | ~25 |
| 500-1.000 linhas | ~7 | ~15 |
| > 1.000 linhas | 1 | 4 |

**Conclusão**: comandos têm distribuição razoável; agentes tendem ao inflado. Quatro agentes acima de 1.000 linhas (incluindo `command-creator-specialist` com 1.519) sugerem que esses agentes acumularam responsabilidades que poderiam ser modularizadas (delegando para sub-comandos, KBs externas referenciadas, ou skills).

**Conformidade com meta-specs**: **impossível validar** no momento, porque os arquivos de meta-spec não existem ainda. As 5 specs L0 estão marcadas como "A CRIAR" em [docs/meta-specs/index.md](../meta-specs/index.md) desde 2025-11-24. Isso é tratado em detalhe na Seção 3.1.

### 2.6 Task Manager Abstraction

Avaliação estrutural: **o ponto mais maduro do framework**.

Localização: [.claude/utils/task-manager/](../../.claude/utils/task-manager/) com componentes:

- `factory.md` — instancia o adapter via `TASK_MANAGER_PROVIDER`
- `interface.md` — contrato `ITaskManager`
- `types.md` — tipos
- `detector.md` — detecção automática
- `adapters/jira.md`, `clickup.md`, `asana.md`, `linear.md` — 4 providers

**Roteamento**:

1. Lê `.env` → `TASK_MANAGER_PROVIDER`
2. Valida variáveis obrigatórias do provider
3. Delega ao agente especialista (`@jira-specialist`, `@clickup-specialist`) ou ao agnóstico `@task-specialist`
4. Aplica formatação correta (ADF para Jira v3, Markdown para ClickUp descriptions, Unicode para ClickUp comments, HTML para Asana, Markdown para Linear)

**Forças**: padrão SDAAL real, fallback gracioso quando provider ausente, formatação tipada por provider, documentação de operação em ADRs externos.

**Riscos**: nenhum teste automatizado observado para a abstração — quebras de contrato dos providers (ex: mudança de payload do Jira REST v3) só seriam descobertas em uso real.



## 3. Saúde da Documentação

A documentação do Onion vive em três camadas distintas, com naturezas e ciclos diferentes:

1. **Meta-specs** (`docs/meta-specs/`) — constituição do framework, vive no Onion
2. **Contextos spec-as-code** (`docs/business-context/`, `docs/technical-context/`, `docs/compliance-context/`) — templates aqui, populados em projeto-alvo
3. **Knowledge bases** (`docs/knowledge-base/`) e **documentação operacional** (`docs/onion/`) — referência viva para humanos e IA

Confundir essas três camadas leva a falsos gaps. A distinção mais importante para esta análise é a do tópico 3.1.

### 3.1 Meta-specs do Onion vs Contextos do Projeto-alvo

Um esclarecimento estrutural levantado durante a análise: **meta-specs do Onion** e **contextos spec-as-code** parecem similares (ambos vivem em `docs/`), mas têm naturezas totalmente diferentes:

| Artefato | Onde vive | Quando é gerado | Sobre o quê |
|---|---|---|---|
| `docs/meta-specs/*.md` | Sempre no repo do Onion (este repo) | Manualmente pelo mantenedor do Onion | Constituição do **próprio framework** (padrões de agentes, comandos, integrações, código, arquitetura) |
| `docs/business-context/` | No projeto-alvo | `/docs:build-business-docs` durante aplicação | Negócio do projeto-alvo |
| `docs/technical-context/` | No projeto-alvo | `/docs:build-tech-docs` durante aplicação | Arquitetura/stack do projeto-alvo |
| `docs/compliance-context/` | No projeto-alvo | `/docs:build-compliance-docs` durante aplicação | Frameworks regulatórios do projeto-alvo |

**Implicação**: as 5 meta-specs (`agents.md`, `commands.md`, `architecture.md`, `code-standards.md`, `integrations.md`) pertencem **a este repo** e definem como o **próprio Onion** deve ser estruturado. Elas são o input do `@metaspec-gate-keeper` para validar PRs neste repositório. Não são geradas em projeto-alvo, não têm "build command" próprio, são editadas à mão como qualquer documentação técnica.

#### Estado atual das meta-specs

Conforme [docs/meta-specs/index.md](../meta-specs/index.md), versão 1.0.0 de 2025-11-24:

- `architecture.md` — marcado "A CRIAR"
- `code-standards.md` — marcado "A CRIAR"
- `agents.md` — marcado "A CRIAR"
- `commands.md` — marcado "A CRIAR"
- `integrations.md` — marcado "A CRIAR"

Cinco arquivos planejados, zero criados, **~6 meses parados**. Esse é o gap mais crítico da documentação do Onion.

**Consequências práticas**:

- `@metaspec-gate-keeper` existe como agente mas **não tem base normativa** para operar
- Validação arquitetural vira opinião do revisor humano, não conformidade
- Novos comandos/agentes herdam padrões "por imitação" do que existe, sem regra explícita
- Decisões arquiteturais (ex: workflows faseados são intencionais) ficam apenas em CLAUDE.md, vulneráveis a reescrita

#### O que essas 5 meta-specs devem conter

- **`agents.md`**: estrutura YAML obrigatória (name, description, tools), categorias válidas (development, product, compliance, meta, git, testing, review, research, deployment), naming kebab-case, limites de tamanho, padrões de delegação, integração com MCPs.
- **`commands.md`**: estrutura obrigatória do frontmatter, categorias válidas, **workflows faseados como conceito documentado** (preserva `engineer/plan→pr-update` e `product/collect→feature`), naming, limites de tamanho, modularização.
- **`architecture.md`**: estrutura de diretórios obrigatória, separação `.claude/` vs `docs/`, princípio de framework instalável, dependências permitidas/proibidas entre categorias.
- **`code-standards.md`**: pt-BR em documentação e comentários, inglês em código/variáveis/commits/branches/logs, formatação, padrões de teste, validação de qualidade.
- **`integrations.md`**: Task Manager Abstraction como referência canônica, padrão de adapter, fallback gracioso, gestão de `.env`, MCPs suportados.

### 3.2 Spec as Code Multi-Context — templates por design

Os três contextos de spec-as-code **devem permanecer vazios neste repositório-mãe** porque são templates a serem populados em projeto-alvo:

| Contexto | Comando gerador | Agentes consumidores | Status no repo-mãe |
|---|---|---|---|
| [docs/business-context/](../business-context/) | `/docs:build-business-docs` | `@product-agent`, `@branding-positioning-specialist`, `@pain-price-specialist`, `@research-agent` | Apenas README template (correto) |
| [docs/technical-context/](../technical-context/) | `/docs:build-tech-docs` | `@c4-architecture-specialist`, `@c4-documentation-specialist`, `@nodejs-specialist`, `@react-developer`, demais | Apenas README template (correto) |
| `docs/compliance-context/` | `/docs:build-compliance-docs` | `@iso-27001-specialist`, `@iso-22301-specialist`, `@soc2-specialist`, `@pmbok-specialist`, `@corporate-compliance-specialist`, `@security-information-master` | Estado a verificar — possivelmente sem README equivalente |

A KB [docs/sdaal/sdaal.md](../sdaal/sdaal.md) (v1.0.0, maio/2026) documenta o padrão SDAAL — Specification-Driven AI Abstraction Layer — aplicado a esses três contextos.

**Falso gap a evitar**: dizer "business-context está vazio" como problema. Está vazio **por design**.

**Gap real a tratar**: três perguntas operacionais:

1. Os READMEs dos três contextos explicam claramente que são templates a serem populados em projeto-alvo? `compliance-context/` tem README equivalente aos demais?
2. Os três comandos `/docs:build-*-docs` estão completos e prontos para uso em projeto externo? Foram testados ponta a ponta em projeto greenfield e legado?
3. Existe documentação de **como ativar** cada contexto em um projeto-alvo? Quando ativar `compliance-context/` (projeto regulado) vs deixar dormente (projeto interno)?

### 3.3 Knowledge Bases

Estado em [docs/knowledge-base/index.md](../knowledge-base/index.md): 24-25 arquivos em 5 categorias.

**Distribuição**:

- `concepts/` — 13 arquivos (Task Manager Abstraction, AI Agent Design Patterns, Spec-as-Code Strategy, Spec-Driven Development, SDAAL, Context Window Optimization, Configuration Management, Story Points, Testes, Pain Pricing, Branding, Meeting Transcription, Abstraction Patterns)
- `frameworks/` — 7 arquivos (Story Points, Testes, **3 análises críticas do Onion de 2025-12-20**, Onion IDE Integration, Spec-Driven Development Tools 2025)
- `tools/` — 3 arquivos (Agent Skills, Claude Code Commands Best Practices 2025, Whisper)
- `platforms/` — 1 arquivo (Runflow)
- `providers/` — 1 arquivo (Microsoft Graph Teams API)

**Forças**:

- Cobertura conceitual ampla
- Linguagem consistente em pt-BR estruturado para consumo por IA
- KBs novas como `spec-driven-development.md` (2025-12-02) refletem estado da arte

**Fraquezas estruturais**:

- **Sem cross-reference KB ↔ artefatos consumidores** — não há índice mostrando "qual comando/agente consome qual KB"
- Categorias assimétricas em volume (concepts: 13 vs platforms: 1, providers: 1) — não é problema em si, mas indica que categorias pequenas podem estar mal definidas
- **Três análises críticas de 2025-12-20** continuam em `frameworks/` sem marcação histórica, apesar de defenderem visões agora abandonadas (`.onion/`, CLI standalone, multi-IDE). Operador que ler primeiro essas KBs vai construir mapa mental errado.

### 3.4 Memória de IA

Localização: `/home/marciocar/.claude/projects/-home-marciocar-onion-claude/memory/`

**Conteúdo atual**:

- `MEMORY.md` — índice com 1 pointer
- `project_onion_scope.md` — anota que Onion é "uso interno, não produto npm"

Apenas **1 entrada substantiva** após meses de uso. Memória vazia significa que:

- Cada conversa nova começa sem rastro de decisões anteriores
- Pivôs (como o abandono de `.onion/` e v4) precisam ser re-narrados a cada vez
- Gotchas e padrões aprendidos não acumulam
- O sistema "esquece" o que aprendeu

**Oportunidade**: popular memória com pelo menos quatro entradas críticas durante este saneamento — identidade reposicionada (framework template instalável), workflows faseados como princípio, três dimensões do ciclo, esta análise como referência canônica. Detalhado na Seção 6 (P3.18).



## 4. Heranças do Roadmap Abandonado

Em 2025-12-20, três análises críticas foram produzidas em sequência _(as KBs-fonte abaixo foram removidas do repo na curadoria de 2026-06-14 — esta síntese preserva suas conclusões; o conteúdo verboso é recuperável via git history)_:

1. `onion-system-critical-analysis-2025.md` — análise comparativa contra ferramentas SDD (Kiro, Spec-Kit, OpenSpec). Conclusão: complexidade excessiva, onboarding inaceitável, propor cortar 70%.
2. `onion-complete-cycle-understanding.md` — reavaliação que reconhece o Onion como "metodologia completa de 5 camadas", reverte conclusões da análise anterior.
3. `onion-multi-context-orchestrator-vision.md` — síntese final propondo identidade "Multi-Context Development Orchestrator" com estrutura `.onion/contexts/`, CLI standalone, suporte multi-IDE.

Essas três análises geraram um **plano de implementação v4.0** de 9 fases. As fases 1-4 (Multi-Context structure, starter kit, levels system, beta release) foram parcialmente entregues. As fases 5-9 foram **descontinuadas em 2026-05-18**.

Em 2026-05-18 também foram tomadas duas decisões adicionais:

- **Abandono do `.onion/`** — a proposta de diretório agnóstico para portabilidade entre IDEs não será mais perseguida; o Onion permanece em `.claude/`.
- **Abandono do `packages/onion-cli/`** — a CLI standalone (`onion init/add/migrate`) também é descontinuada; a pasta `packages/` será removida.

### Mapa do que foi abandonado

| Proposta original | Origem | Status atual | Ação concreta no saneamento |
|---|---|---|---|
| Estrutura `.onion/contexts/` agnóstica | multi-context-vision | Abandonada | Remover referências em README, CLAUDE.md, INDEX.md, KBs |
| CLI standalone (`onion init/add/migrate`) | critical-analysis + multi-context | Abandonada | Deletar `packages/onion-cli/` e a pasta `packages/` inteira |
| Suporte multi-IDE (Cursor, Continue, Cline) | onion-ide-integration-strategy | Abandonada | Aceitar Claude Code como plataforma única |
| Sistema de aprendizado contínuo (FASE 5) | complete-cycle | Abandonada | Remover menções em KBs e roadmaps |
| Abstractions extras (FASE 6) | v4 plan | Abandonada | Manter apenas Task Manager Abstraction |
| Story Points como plugin (FASE 7) | critical-analysis | Abandonada | Manter inline (`product/estimate` + `@story-points-framework-specialist`) |
| Learnings auto-gerados (FASE 8) | v4 plan | Abandonada | Memória IA continua manual |
| Polimento e release GA (FASE 9) | v4 plan | Abandonada | Não há release público planejado |
| Reduzir 70% dos comandos | critical-analysis-2025 | **Não se aplica** | Critério obsoleto — substituído por "completude do ciclo product+engineer+compliance" |
| Decidir identidade entre SDD/Multi-Context/Metodologia | três análises | **Resolvido pelo descope** | Identidade: framework template instalável em `.claude/` |
| Onboarding em <30min | critical-analysis-2025 | Reformulada | Onboarding agora se aplica ao **operador externo** que instala o Onion em projeto-alvo, não a "novo usuário do Onion" |

### Implicação central — KBs históricas

As três análises de 2025-12-20 permanecem em [docs/knowledge-base/frameworks/](../knowledge-base/frameworks/) sem qualquer marcação que as identifique como históricas. Um operador externo que descubra essas KBs primeiro construirá expectativa de `.onion/`, CLI standalone, multi-IDE — todas inexistentes.

**Tratamento recomendado** (detalhado em P0, Seção 6):

Atualizar o frontmatter dessas três KBs adicionando:

```yaml
status: historical
replaced-by: docs/analysis/onion-review-2026-05.md
note: |
  Esta análise documenta visões estratégicas (Multi-Context Orchestrator,
  .onion/, CLI standalone, multi-IDE) que foram formalmente abandonadas
  em 2026-05-18. Mantida como registro do pensamento estratégico de 12/2025.
  Para o estado atual e direção do Onion, consultar a análise indicada em
  replaced-by.
```

Adicionar um banner equivalente no topo do corpo de cada arquivo.

### O que sobrevive das análises de 12/2025

Nem tudo virou dívida. As três análises produziram insights que **continuam válidos** mesmo com o descope:

- Distinção entre as três dimensões do ciclo (produto/engenharia/compliance) — incorporada à Seção 2.2 desta análise
- Conceito de **workflows faseados retomáveis** — incorporado à Seção 2.4 e elevado a princípio formal
- Necessidade de **starter kit** para reduzir barreira de entrada — concretizada no sistema de níveis (`levels-system.md`, doc removido em 2026-06-03 junto com a visão v4.0)
- Validação empírica em projeto-alvo como critério de qualidade — incorporada à Seção 5 e P3
- Importância de meta-specs como mecanismo de validação — incorporada à Seção 3.1 e P2



## 5. Riscos e Sustentabilidade

Como **framework template instalável**, o Onion enfrenta riscos diferentes dos enfrentados por um produto SaaS, por um workspace pessoal isolado ou por uma biblioteca npm distribuída publicamente. A pergunta orientadora é:

> O framework está coerente e completo o suficiente para ser aplicado a um projeto-alvo sem que o operador precise consultar o mantenedor original?

A partir dessa pergunta, os riscos relevantes são os a seguir.

### Risco 1 — Manutenção da biblioteca

**Volume**: 49 agentes × 1.186 linhas médias + 94 comandos × 509 linhas médias = aproximadamente **53.000 linhas de prompts ativos** que precisam ser mantidos consistentes.

**Implicação**: qualquer mudança transversal (formato de YAML header, convenção de naming, padrão de delegação) exige edit em massa. Se há um único mantenedor ativo, o custo de iterar em padrões é alto.

**Mitigação**: meta-specs são o mecanismo formal para que mudanças transversais sejam **proposta única validada antes de aplicar**, em vez de ad-hoc espalhada. Sem meta-specs, cada mudança vira renegociação implícita.

### Risco 2 — Drift entre intenção e prática

**Sintoma**: KBs em [docs/knowledge-base/frameworks/](../knowledge-base/frameworks/) descrevem visões abandonadas como se fossem direção atual. Comandos em `.claude/commands/` operam em estado consolidado em `.claude/`. README.md, CLAUDE.md e INDEX.md podem citar `.onion/` ou outras visões.

**Implicação**: o operador externo que descobre o Onion via KBs primeiro forma mapa mental incompatível com o estado real. Atrito imediato no momento de aplicação.

**Mitigação**: marcação histórica explícita (P0.1 e P0.3), com banner no topo das KBs e atualização de README/CLAUDE.md para refletir a identidade atual.

### Risco 3 — Débito de validação arquitetural

**Sintoma**: 5 meta-specs marcadas "A CRIAR" há ~6 meses. `@metaspec-gate-keeper` existe sem base normativa para operar.

**Implicação**: toda decisão arquitetural vira gosto pessoal. Não há critério para responder "esse novo agente segue o padrão?" ou "esse novo comando está bem estruturado?". A consequência prática é que padrões herdam-se por imitação do existente, propagando inconsistências.

**Mitigação**: criar as 5 meta-specs em P2 e rodar `@metaspec-gate-keeper` em PR experimental para validar que a especificação habilita validação real.

### Risco 4 — Comandos vestigiais

**Sintoma**: categorias com 1 elemento (`quick/`, `development/` em comandos, `global/`), comandos sem header documentado (6/91), agentes com escopo ambíguo (3 pares listados na Seção 2.4).

**Implicação**: cada componente vestigial é dívida cognitiva ao operador externo. "O que faz `quick/analisys`? Por que está em `quick/` e não em `meta/`?"

**Critério revisado para "merece ficar"**: o componente faz sentido quando o Onion é aplicado a um projeto-alvo? Não é "foi usado pelo mantenedor" nem "tem volume baixo". É "tem caso de uso defensável fora deste repositório".

**Mitigação**: auditoria descrita em P1.4 e P1.5.

### Risco 5 — Documentação aspiracional sobrepondo operacional

**Sintoma**: parcela significativa das KBs descreve "o que poderia ser" — frameworks de Spec-Driven Development, comparativos com Kiro/Spec-Kit, análises críticas de 12/2025. Documentação operacional ("como aplicar o Onion no seu projeto") é menor em volume e visibilidade.

**Implicação**: operador externo encontra ensaios estratégicos antes de instruções práticas. Inverte a relação esperada: documentação operacional deveria ser a porta de entrada; documentação estratégica, anexo de aprofundamento.

**Mitigação**: P3.17 — criar três guias operacionais ("Onion em projeto novo", "Onion em projeto legado", "Onion em projeto regulado") e elevá-los na hierarquia do INDEX.

### Risco 6 — Cobertura para múltiplos cenários de aplicação

O Onion declara aplicabilidade a três cenários distintos:

- **Greenfield**: projeto novo, sem código nem documentação prévia
- **Legado**: projeto existente, requer engenharia reversa antes da aplicação
- **Regulado**: projeto sujeito a frameworks de compliance (ISO 27001, ISO 22301, SOC2, PMBOK)

**Pergunta**: o framework tem caminho documentado e testado para os três? Existem comandos específicos por cenário?

- Para legado: [.claude/commands/docs/reverse-consolidate.md](../../.claude/commands/docs/reverse-consolidate.md) e `@docs-reverse-engineer` cobrem extração inicial. Funciona ponta a ponta?
- Para greenfield: o sistema de níveis (starter kit) é o caminho previsto. Está completo?
- Para regulado: os 5 agentes de compliance + `/docs:build-compliance-docs` + orquestração via `@security-information-master`. Coerente? Cobre decisão "qual framework escolher"?

**Mitigação**: P3.16 e P3.17.

### Risco 7 — Portabilidade de configuração

**Sintoma**: Task Manager Abstraction depende de `.env` com variáveis específicas por provider. MCPs configurados via `settings.json`. Integrações via API tokens.

**Pergunta para o operador externo**: existe guia "do zero ao primeiro comando útil"? `/meta:setup-integration` cobre todos os providers e MCPs? O operador consegue configurar Jira + ClickUp + Whisper em fluxo guiado?

**Mitigação**: validar `/meta:setup-integration` ponta a ponta (P3.16) e referenciar do guia de aplicação (P3.17).

### Risco 8 — Drift de plataforma

**Premissa do framework**: Claude Code como plataforma única.

**Risco**: mudanças em Claude Code (novo formato de skill, mudança em `.claude/agents/` estrutura, deprecation de tools) podem quebrar o framework inteiro. Sem testes automatizados, regressões só seriam descobertas em uso.

**Mitigação fora do escopo desta análise**: criar suite mínima de validação que rode `@metaspec-gate-keeper` + sintaxe YAML + paths de referência. Para o saneamento atual, basta documentar a premissa explicitamente.

### Pergunta-chave de sustentabilidade

> O framework está coerente e completo o suficiente para ser aplicado a um projeto novo sem que o operador precise consultar o mantenedor?

Resposta honesta em 2026-05-18: **ainda não**. O framework tem cobertura ampla (94 comandos, 49 agentes), boa abstração em Task Manager, knowledge bases ricas. Mas tem três bloqueios para aplicação externa:

1. KBs e docs ainda descrevem visões abandonadas (Risco 2)
2. Meta-specs ausentes deixam padrões implícitos (Risco 3)
3. Guias operacionais por cenário ausentes (Risco 5 e 6)

Os três bloqueios são tratados pelas recomendações P0, P2 e P3 da próxima seção. Resolvê-los muda a resposta de "ainda não" para "sim".



## 6. Recomendações Priorizadas

Priorização sob a lente "framework template instalável em projetos novos, legados ou regulados". O detalhamento executável de cada recomendação vivia no plano de saneamento `onion-saneamento-plan-2026-05.md` — executado e removido do repo (recuperável via git history).

### P0 — Marcar o que mudou e parar de sangrar contexto

Antes de qualquer outra coisa, fechar o gap entre **visão histórica** e **estado atual**. Sem isso, todo trabalho subsequente compete com narrativas obsoletas.

**1. Marcar as 3 análises de 2025-12-20 como históricas** _(✅ executado — superado: as 3 KBs foram removidas na curadoria de 2026-06-14, recuperáveis via git history; suas conclusões estão sintetizadas neste documento)_

Ação original — adicionar ao frontmatter de `onion-system-critical-analysis-2025.md`, `onion-complete-cycle-understanding.md` e `onion-multi-context-orchestrator-vision.md`:

```yaml
status: historical
replaced-by: docs/analysis/onion-review-2026-05.md
```

Inserir banner no topo do corpo de cada arquivo explicando que as visões `.onion/`, CLI standalone e multi-IDE foram formalmente abandonadas em 2026-05-18.

**2. Deletar `packages/` e referências a `.onion/`**

- Remover o diretório `packages/onion-cli/` e, se a pasta `packages/` ficar vazia, removê-la integralmente
- Buscar e tratar referências a `.onion/`, `onion-cli`, "CLI standalone" e "multi-IDE" em: README.md, CLAUDE.md, [docs/INDEX.md](../INDEX.md), [docs/onion/](../onion/), [docs/knowledge-base/](../knowledge-base/)
- Em release notes e arquivos de implementação, transformar referências em prosa histórica (não apagar a história, apagar a expectativa)

**3. Atualizar CLAUDE.md e README.md com a identidade atual**

Mudar a descrição de "Sistema Onion" para refletir:

- Framework template em `.claude/`, instalável em qualquer projeto novo, legado ou regulado
- Cobertura das três dimensões: produto, engenharia, compliance
- Workflows faseados retomáveis como princípio
- Plataforma única: Claude Code
- Não é produto npm, não é distribuído publicamente, não tem CLI standalone

### P1 — Saneamento estrutural cuidadoso (preservar workflows)

Princípio: **workflows faseados são valor, não débito**. Antes de fundir ou eliminar qualquer artefato, validar que não há intenção de faseamento ou retomada subjacente.

**4. Auditar comandos pelo critério "faz sentido em projeto-alvo?"**

Para cada comando potencialmente vestigial (`quick/analisys`, `development/runflow-dev`, `global/*`, comandos sem header documentado), responder:

- Faz parte de algum workflow faseado ativo? Se sim, manter e documentar no `commands.md`.
- Tem caso de uso defensável quando o Onion é aplicado em projeto-alvo? Se sim, manter e adicionar exemplo na guia de aplicação correspondente.
- Não atende nenhum dos dois? Mover para `.claude/commands/.archive/` ou remover, registrando a decisão em commit message.

**Crítico**: o critério é **completude do ciclo product → engineering → compliance**, não "redução de volume por estética".

**5. Auditar agentes potencialmente sobrepostos**

Ler lado a lado os YAMLs de:

- `@code-reviewer` vs `@branch-code-reviewer`
- `@test-engineer` vs `@test-agent` vs `@test-planner`
- Quarteto `@branch-*` em [.claude/agents/git/](../../.claude/agents/git/) (review, test-planner, documentation-writer, metaspec-checker)

Fundir **apenas** quando a sobreposição for confirmada como real (mesmo escopo, mesmas ferramentas, mesmo gatilho). Diferenciação real é valor.

**6. Preservar formalmente os workflows faseados em meta-spec**

Documentar em `commands.md` (a ser criada em P2):

- **Workflow de Engenharia**: `engineer/plan → start → work → pre-pr → pr → pr-update` — ciclo retomável com sessões persistentes em `.claude/sessions/`
- **Workflow de Produto**: `product/collect → refine → spec → task → estimate → feature` — ciclo de descoberta a backlog

Tornar explícito que esses dois workflows não são candidatos a consolidação e que novos workflows similares (se surgirem) devem seguir o mesmo padrão.

**7. Consolidar política de duplicação de nomes**

Para cada nome que aparece em múltiplas categorias (`README`, `warm-up`, `start`, `finish`, `help`, `estimate`), decidir e documentar em `commands.md`:

- Categoria canônica do nome curto (ex: `start` canônico em `engineer/`, demais usam nome explícito `feature-start`, `hotfix-start`, etc.)
- OU manter a duplicação justificada documentando o contexto de invocação esperado em cada categoria

A decisão pode variar por nome — o importante é registrar a regra.

**8. Refatorar outliers de tamanho**

Estabelecer limites em `commands.md` e `agents.md`:

- Comandos: máximo recomendado 500 linhas, hard limit 800
- Agentes: máximo recomendado 1.200 linhas, hard limit 1.500

Refatorar os outliers:

- `validate/test-strategy/analyze.md` (1.134 linhas) — extrair KBs externas referenciadas
- `command-creator-specialist.md` (1.519 linhas) — modularizar via skills ou sub-agentes
- Agentes acima de 1.200 linhas — análise caso a caso

### P2 — Meta-specs completas (mecanismo de validação preservado)

Princípio: as 5 meta-specs são o **mecanismo formal** de validação via `@metaspec-gate-keeper`. Descopar enfraquece a governança. Manter as 5, com escopo enxuto e prático.

Importante: meta-specs são **do Onion**, não do projeto-alvo. Veja Seção 3.1 para distinção.

**9. Criar `agents.md`**

Conteúdo mínimo:

- Estrutura YAML obrigatória (`name`, `description`, `tools`, opcionalmente `model`)
- Categorias válidas com função (development, product, compliance, meta, git, testing, review, research, deployment)
- Convenção de naming (kebab-case)
- Limites de linhas (recomendado e hard)
- Padrões de delegação (quando criar especialista vs estender `@task-specialist`)
- Integração com MCPs (quando declarar tool MCP no YAML)

**10. Criar `commands.md`**

Conteúdo mínimo:

- Estrutura obrigatória (frontmatter, descrição, etapas, exemplos)
- Categorias válidas com função
- **Workflows faseados como conceito documentado** (preserva `engineer/plan→pr-update` e `product/collect→feature`)
- Convenção de naming + política de duplicação entre categorias (referência a P1.7)
- Limites de linhas
- Modularização via skills, common templates ou sub-comandos

**11. Criar `architecture.md`**

Conteúdo mínimo:

- Estrutura obrigatória de diretórios em `.claude/` e `docs/`
- Separação `.claude/` (artefatos operacionais) vs `docs/` (documentação consumida por humanos e IA)
- Princípio de framework instalável (sem dependências de path absoluto, sem assunções sobre estrutura do projeto-alvo além de `.claude/` no root)
- Dependências permitidas/proibidas entre categorias (ex: agentes de `compliance/` podem consumir KBs, mas não devem invocar comandos de `engineer/` diretamente)
- Plataforma alvo: Claude Code

**12. Criar `code-standards.md`**

Conteúdo mínimo (parte já em CLAUDE.md):

- pt-BR em documentação, comentários, mensagens ao usuário, respostas do assistente
- Inglês em código, variáveis, funções, classes, arquivos, commits, branches, logs
- Formatação Markdown padrão (headers, listas, tabelas)
- Padrões de teste por linguagem (quando aplicável ao framework)

**13. Criar `integrations.md`**

Conteúdo mínimo:

- Task Manager Abstraction como referência canônica de padrão de adapter
- Estrutura obrigatória de adapter (factory + interface + types + detector + provider docs)
- Gestão de `.env` (variáveis obrigatórias vs opcionais, fallback gracioso)
- MCPs suportados e como declarar no YAML de agente
- Formatação por provider (ADF para Jira v3, Markdown para ClickUp descriptions, Unicode para ClickUp comments, etc.)

**14. Validar via `@metaspec-gate-keeper` em PR experimental**

Após criar as 5 meta-specs, abrir PR experimental (pode ser uma alteração trivial em um comando ou agente) e rodar `@metaspec-gate-keeper`. Confirmar que:

- O agente carrega as 5 meta-specs como input
- Detecta violações reais (criar PR com violação intencional para teste)
- Aprova quando conforme

Se algo falhar, iterar as meta-specs antes de considerar P2 concluído.

### P3 — Documentação operacional (foco em aplicação em projeto-alvo)

Princípio: `business/technical/compliance-context` **devem ficar vazios neste repo** — são templates. O gap real está na **camada de instruções para aplicar o Onion**.

**15. Validar READMEs dos três contextos**

Para [docs/business-context/README.md](../business-context/README.md), [docs/technical-context/README.md](../technical-context/README.md) e `docs/compliance-context/README.md`:

- Cada README deve declarar explicitamente: "este diretório é populado quando o comando `/docs:build-*-docs` correspondente é executado em um projeto de desenvolvimento que tenha instalado o Onion"
- Se `docs/compliance-context/README.md` não existir, criar com mesma estrutura dos demais
- Listar agentes consumidores
- Linkar para a KB SDAAL e para o guia de aplicação correspondente

**16. Validar completude dos três comandos `/docs:build-*-docs`**

Testar em projeto externo (greenfield e legado):

- `/docs:build-business-docs` — invoca `@product-agent`, `@branding-positioning-specialist`, `@pain-price-specialist`? Gera estrutura esperada em `docs/business-context/` do projeto-alvo?
- `/docs:build-tech-docs` — invoca agentes de development corretamente? Gera C4, arquitetura, padrões?
- `/docs:build-compliance-docs` — invoca os 5 agentes de compliance? Cobre detecção de framework apropriado (ISO 27001 vs SOC2 vs PMBOK)? Orquestra via `@security-information-master`?

Documentar lacunas encontradas como tarefas no plano de saneamento.

**17. Criar três guias de aplicação**

Em [docs/onion/](../onion/) ou nova pasta `docs/applying/`:

- **"Onion em projeto novo"** (`applying-greenfield.md`) — passo a passo desde `git init` até primeiro comando útil. Decisão sobre quais dos três contextos ativar (business sempre, technical sempre, compliance se regulado).
- **"Onion em projeto legado"** (`applying-legacy.md`) — fluxo `/docs:reverse-consolidate` + `@docs-reverse-engineer` para extração inicial, depois `/docs:build-*` para refinamento estruturado.
- **"Onion em projeto regulado"** (`applying-regulated.md`) — quando ativar `compliance-context/`, qual framework escolher (matriz: saúde → SOC2 + ISO 27001; financeiro → ISO 27001; governo → PMBOK + ISO 22301), papel do `@security-information-master`.

**18. Popular memória IA com decisões-chave**

Em `/home/marciocar/.claude/projects/-home-marciocar-onion-claude/memory/`, criar e indexar:

- `feedback_workflows_faseados.md` — workflows faseados em `product/*` e `engineer/*` são intencionais; não consolidar
- `project_onion_identity.md` — Onion é framework template instalável; `.onion/`, plano v4.0 e `packages/onion-cli/` abandonados em 2026-05-18
- `project_onion_three_dimensions.md` — três dimensões peer do ciclo (produto + engenharia + compliance), cada uma com contexto spec-as-code próprio no projeto-alvo
- `reference_review_2026_05.md` — análise canônica do estado em maio/2026

**19. Atualizar `docs/INDEX.md`**

- Adicionar entrada para esta análise em "Análises e Planos" → "Análises"
- Adicionar entrada para o plano de saneamento em "Análises e Planos" → "Planos de Execução"
- Remover ou atualizar seções aspiracionais que ainda mencionam `.onion/`, CLI standalone, multi-IDE, FASES 5-9 do v4
- Adicionar (quando criadas em P3.17) entradas para os três guias de aplicação
- Atualizar timestamp e descrição inicial para refletir identidade atual



## 7. Conclusão e Próximos Passos

### Veredito

O Onion em 2026-05-18 é um framework **substancialmente completo em cobertura** (94 comandos + 49 agentes + 1 skill + Task Manager Abstraction maduro + KBs ricas) mas **incompleto em validação formal** (5 meta-specs ausentes) e em **camada operacional para aplicação externa** (guias por cenário ausentes, KBs históricas ainda apresentadas como visão atual).

Sob a lente "framework template instalável", o framework está em estado **pré-aplicável**: tem peças, falta marcação e instruções. Resolvendo os 19 itens priorizados na Seção 6, especialmente P0 (limpeza de visões abandonadas) e P3 (guias operacionais), o framework passa para estado **aplicável a projeto-alvo sem necessidade de mantenedor de plantão**.

### Três decisões imediatas

**Decisão 1 — Quando iniciar P0?**
P0 (marcação histórica + delete `packages/` + atualização CLAUDE.md/README.md) é pré-requisito de tudo. Recomendado executar nos próximos 7 dias para que qualquer novo trabalho parta do estado limpo.

**Decisão 2 — Em que ordem executar P1 e P2?**
Há dependência entre eles: P1.6 (documentar workflows faseados) e P1.7 (política de naming) precisam de `commands.md` (P2.10). Sugestão: executar P2 primeiro (criar as 5 meta-specs com conteúdo enxuto), depois P1 (saneamento estrutural usando meta-specs como referência), depois iterar meta-specs com aprendizado do P1.

**Decisão 3 — Qual projeto-alvo será o piloto para validar P3?**
P3.16 (validar `/docs:build-*-docs`) e P3.17 (guias de aplicação) só podem ser concluídos com **aplicação real em projeto externo**. Definir um projeto piloto — preferencialmente um cenário regulado (que exercita as três dimensões) — é decisão estratégica que precede a execução de P3.

### Pergunta aberta para o mantenedor

> Qual projeto-alvo será usado para validar empiricamente o framework após o saneamento das P0-P2?

A resposta a essa pergunta determina o cronograma realista de P3 e a confiança final de que o framework está pronto para aplicação. Sem piloto identificado, P3 permanece teórica.

### Próximo passo concreto

Revisar e aprovar o plano de execução `onion-saneamento-plan-2026-05.md`, que detalhava cada uma das 19 recomendações em tarefas executáveis. _(✅ executado e removido na curadoria de 2026-06-14; recuperável via git history.)_

---

