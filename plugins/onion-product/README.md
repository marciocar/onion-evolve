# Onion · Product — plugin `onion-product` do Sistema Onion 🧅

Vertical de produto do Onion: descoberta a backlog (collect→refine→spec→feature), decomposição de tasks agnóstica ao provider, story points, extração de reuniões, apresentações e documentação de contexto (business/technical context, C4 + Mermaid, engenharia reversa, docs-health).

**Versão** `0.1.78` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-product@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-product@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-product@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 31 |
| Agentes | 17 |
| Skills | 1 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `descoberta-a-backlog`, `decomposicao-de-tasks`, `estimativa-story-points`, `extracao-de-reunioes`, `apresentacoes`, `ssot-context-resolver`, `business-technical-context`, `c4-model-mermaid`, `docs-health-validacao`, `engenharia-reversa`; requer `agent:product-agent`, `agent:task-specialist`, `agent:story-points-framework-specialist`, `agent:pain-price-specialist`, `agent:extract-meeting-specialist`, `skill:onion-product-context`, `agent:c4-architecture-specialist`, `agent:c4-documentation-specialist`, `agent:mermaid-specialist`, `agent:docs-reverse-engineer`.

## Comandos

Invocação: `/onion-product:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-product:analyze-pain-price` | Análise de Dor e Precificação do Cliente. |
| `/onion-product:branding` | Branding e Posicionamento de Marca. |
| `/onion-product:build-business-docs` | Gerar arquitetura de contexto de negócio em `docs/business-context/`. |
| `/onion-product:build-index` | Gerar e atualizar índices de documentação em docs/ a partir da estrutura real (contagens escaneadas, nunca hardcoded). |
| `/onion-product:build-tech-docs` | Gerar arquitetura de contexto técnico em `docs/technical-context/`. |
| `/onion-product:check` | Verificar requisitos contra meta-specs do projeto. |
| `/onion-product:checklist-sync` | Sincronizar e monitorar checklists do Task Manager (checklist nativo é capacidade resolvida pelo adapter). |
| `/onion-product:collect` | Coletar novas ideias de features ou bugs para o projeto. |
| `/onion-product:consolidate-documents` | Consolida múltiplos documentos usando análise profunda, identificando divergências, convergências e insights estratégicos. |
| `/onion-product:consolidate-meetings` | Consolida múltiplas reuniões usando o Consolidador de Reuniões. |
| `/onion-product:convert-to-tasks` | Converte documentos consolidados em tasks organizadas hierarquicamente. |
| `/onion-product:create-task-structure` | Decomposição de tarefas complexas em estrutura hierárquica. |
| `/onion-product:docs-health` | Health check completo da documentação do projeto. |
| `/onion-product:estimate` | Orquestra estimativas de story points utilizando o Framework de Story Points. |
| `/onion-product:extract-meeting` | Extração estruturada de conhecimento de transcrições de reuniões usando Framework EXTRACT. |
| `/onion-product:feature` | Criar task de feature no gerenciador configurado para planejamento e backlog. |
| `/onion-product:help` | Ajuda interativa para comandos de documentação Onion. |
| `/onion-product:light-arch` | Design de arquitetura leve para features. |
| `/onion-product:presentation` | Criação de apresentações profissionais via Gamma.app. |
| `/onion-product:refine-vision` | Refinar visão e estratégia do produto/projeto. |
| `/onion-product:refine` | Refinar requisitos através de perguntas de esclarecimento. |
| `/onion-product:reverse-consolidate` | Engenharia reversa de projetos para gerar documentação consolidada. |
| `/onion-product:spec` | Criar especificação de produto a partir de requisitos iniciais. |
| `/onion-product:sync-sessions` | Sincronizar e organizar sessões de trabalho do Sistema Onion. |
| `/onion-product:task-check` | Verificar se task do Task Manager foi implementada no código. |
| `/onion-product:task` | Criação de tasks com decomposição hierárquica inteligente. |
| `/onion-product:transform-consolidated` | Transforma documentos consolidados (reuniões ou documentos) em contexto estruturado para criação de tasks. |
| `/onion-product:validate-docs` | Validação de completude e consistência da documentação. |
| `/onion-product:validate-task` | Validar e analisar task existente do Task Manager. |
| `/onion-product:warm-up` | Preparação de contexto de produto e negócio. |
| `/onion-product:whisper` | Facilita o uso eficiente do agente Whisper para transcrição de áudio. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@c4-architecture-specialist` | Especialista em arquitetura C4 Model (Context, Containers, Components) com Mermaid. |
| `@c4-documentation-specialist` | Especialista em documentação textual C4 Model (Context, Container, Component, ADRs). |
| `@clickup-specialist` | Especialista técnico em ClickUp (API-first; MCP opcional) para automações avançadas e otimizações de performance. |
| `@docs-reverse-engineer` | Especialista em engenharia reversa de projetos para análise estrutural e documentação. |
| `@extract-meeting-specialist` | Especialista em aplicar o framework EXTRACT para transformar transcrições de reuniões em conhecimento estruturado. |
| `@gamma-api-specialist` | Especialista em Gamma.App API para criação automatizada de apresentações e conteúdo com IA. |
| `@jira-specialist` | Especialista técnico em Jira (Cloud e Server/DC) via REST API v3/v2 para automações avançadas, JQL otimizado, workflows com transitions, bulk operations e ADF. |
| `@meeting-consolidator` | Especialista em consolidar, classificar, divergir e convergir múltiplas reuniões. |
| `@mermaid-specialist` | Especialista em diagramas Mermaid para documentação Markdown renderizada em GitHub, IDEs (VS Code/Cursor com extensões) e Mermaid Live Editor. |
| `@pain-price-specialist` | Especialista em analisar e precificar a dor de clientes usando frameworks validados e conhecimento estruturado. |
| `@presentation-orchestrator` | Orquestrador de apresentações que coordena @storytelling-business-specialist, @mermaid-specialist e @gamma-api-specialist. |
| `@product-agent` | Especialista em gestão de projetos e produtos AI que coordena iniciativas e especifica funcionalidades. |
| `@story-points-framework-specialist` | Especialista em estimativas ágeis utilizando o Framework de Story Points, com profundo conhecimento em análise de complexidade, decomposição de tarefas e calib… |
| `@storytelling-business-specialist` | Especialista em storytelling empresarial que transforma dados em narrativas impactantes. |
| `@system-documentation-orchestrator` | Orquestrador de documentação técnica que coordena @mermaid-specialist e @c4-architecture-specialist. |
| `@task-specialist` | Especialista em decomposição inteligente de tarefas e estruturação hierárquica. |
| `@whisper-specialist` | Especialista em Whisper (OpenAI) para transcrição de áudio e processamento de fala. |

## Skills

| Skill | Quando ativa |
|---|---|
| `onion-product-context` | Contrato de SSOT mínimo e resolver de contexto da vertical de PRODUTO do Onion. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `meta:adopt` (comando do core, não distribuído por plugin) no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Origem | `marciocar/onion-evolve` (repositório privado) |
| tree_sha (hash do conteúdo das fontes) | `97112c846ec9` |

A origem identifica DE ONDE este artefato foi gerado; o canal público de instalação, issues e suporte é https://github.com/marciocar/onion-plugins. Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Comandos do core citados (não distribuídos neste plugin)

Estes comandos aparecem no texto sem a barra inicial porque pertencem ao core do Onion (meta-fábrica ou outra superfície) e **não** são instalados por este plugin: `meta:create-knowledge-base`. Estão disponíveis num repo que adotou o Onion por vendorização (`.claude/` completo).

## Funciona melhor com

Comandos deste plugin citam: `onion`, `onion-compliance`, `onion-engineering`. Não é dependência — sem eles, essas menções apontam para comandos não instalados.

## Licença

MIT (texto integral em `LICENSE`, na raiz do plugin) — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Issues e suporte: https://github.com/marciocar/onion-plugins
