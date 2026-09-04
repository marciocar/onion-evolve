# Onion · Product — plugin `onion-product` do Sistema Onion 🧅

Vertical de produto do Onion: descoberta a backlog (collect→refine→spec→feature), decomposicao de tasks agnostica, estimativas (story points), extracao de reunioes e apresentacoes. Camada 1; o task-manager do consumidor via SDAAL.

**Versão** `0.1.43` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

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
| Comandos | 21 |
| Agentes | 12 |
| Skills | 1 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `descoberta-a-backlog`, `decomposicao-de-tasks`, `estimativa-story-points`, `extracao-de-reunioes`, `apresentacoes`, `ssot-context-resolver`; requer `agent:product-agent`, `agent:task-specialist`, `agent:story-points-framework-specialist`, `agent:pain-price-specialist`, `agent:extract-meeting-specialist`, `skill:onion-product-context`.

## Comandos

Invocação: `/onion-product:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-product:analyze-pain-price` | Análise de Dor e Precificação do Cliente. |
| `/onion-product:branding` | Branding e Posicionamento de Marca. |
| `/onion-product:check` | Verificar requisitos contra meta-specs do projeto. |
| `/onion-product:checklist-sync` | Sincronizar e monitorar checklists do Task Manager (checklist nativo é capacidade resolvida pelo adapter). |
| `/onion-product:collect` | Coletar novas ideias de features ou bugs para o projeto. |
| `/onion-product:consolidate-meetings` | Consolida múltiplas reuniões usando o Consolidador de Reuniões. |
| `/onion-product:convert-to-tasks` | Converte documentos consolidados em tasks organizadas hierarquicamente. |
| `/onion-product:create-task-structure` | Decomposição de tarefas complexas em estrutura hierárquica. |
| `/onion-product:estimate` | Orquestra estimativas de story points utilizando o Framework de Story Points. |
| `/onion-product:extract-meeting` | Extração estruturada de conhecimento de transcrições de reuniões usando Framework EXTRACT. |
| `/onion-product:feature` | Criar task de feature no gerenciador configurado para planejamento e backlog. |
| `/onion-product:light-arch` | Design de arquitetura leve para features. |
| `/onion-product:presentation` | Criação de apresentações profissionais via Gamma.app. |
| `/onion-product:refine` | Refinar requisitos através de perguntas de esclarecimento. |
| `/onion-product:spec` | Criar especificação de produto a partir de requisitos iniciais. |
| `/onion-product:task-check` | Verificar se task do Task Manager foi implementada no código. |
| `/onion-product:task` | Criação de tasks com decomposição hierárquica inteligente. |
| `/onion-product:transform-consolidated` | Transforma documentos consolidados (reuniões ou documentos) em contexto estruturado para criação de tasks. |
| `/onion-product:validate-task` | Validar e analisar task existente do Task Manager. |
| `/onion-product:warm-up` | Preparação de contexto de produto e negócio. |
| `/onion-product:whisper` | Facilita o uso eficiente do agente Whisper para transcrição de áudio. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@clickup-specialist` | Especialista técnico em ClickUp (API-first; MCP opcional) para automações avançadas e otimizações de performance. |
| `@extract-meeting-specialist` | Especialista em aplicar o framework EXTRACT para transformar transcrições de reuniões em conhecimento estruturado. |
| `@gamma-api-specialist` | Especialista em Gamma.App API para criação automatizada de apresentações e conteúdo com IA. |
| `@jira-specialist` | Especialista técnico em Jira (Cloud e Server/DC) via REST API v3/v2 para automações avançadas, JQL otimizado, workflows com transitions, bulk operations e ADF. |
| `@meeting-consolidator` | Especialista em consolidar, classificar, divergir e convergir múltiplas reuniões. |
| `@pain-price-specialist` | Especialista em analisar e precificar a dor de clientes usando frameworks validados e conhecimento estruturado. |
| `@presentation-orchestrator` | Orquestrador de apresentações que coordena @storytelling-business-specialist, @mermaid-specialist e @gamma-api-specialist. |
| `@product-agent` | Especialista em gestão de projetos e produtos AI que coordena iniciativas e especifica funcionalidades. |
| `@story-points-framework-specialist` | Especialista em estimativas ágeis utilizando o Framework de Story Points, com profundo conhecimento em análise de complexidade, decomposição de tarefas e calib… |
| `@storytelling-business-specialist` | Especialista em storytelling empresarial que transforma dados em narrativas impactantes. |
| `@task-specialist` | Especialista em decomposição inteligente de tarefas e estruturação hierárquica. |
| `@whisper-specialist` | Especialista em Whisper (OpenAI) para transcrição de áudio e processamento de fala. |

## Skills

| Skill | Quando ativa |
|---|---|
| `onion-product-context` | Contrato de SSOT mínimo e resolver de contexto da vertical de PRODUTO do Onion. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `1c7b02026faf` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
