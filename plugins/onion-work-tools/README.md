# Onion · Work Tools — plugin `onion-work-tools` do Sistema Onion 🧅

Ferramentas de trabalho cross-cutting do Onion (nao meta-fabrica): knowledge-graph (kg + radar soberano), diario de aprendizado, orquestracao, validacao de metaspec, freshness de KB/contexto, constelacao de estudos, recover, setup de integracoes, e co-evolucao upstream (co-evolve/co-relay). Distribuido a source/hub/standalone.

**Versão** `0.1.146` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-work-tools@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-work-tools@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-work-tools@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 16 |
| Agentes | 1 |
| Skills | 4 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `knowledge-graph-sdaal`, `learning-diary`, `orchestration`, `metaspec-validation`, `freshness-audits`, `constellation-map`, `co-evolution-upstream`, `guided-conduction`, `guided-onboarding`, `retro-feedback`; requer `agent:metaspec-gate-keeper`, `skill:onion-orchestration`.

## Comandos

Invocação: `/onion-work-tools:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-work-tools:all-tools` | Apresenta, sob demanda, as ferramentas disponíveis no contexto atual (nativas do Claude Code + MCP) e defere ao inventário canônico para comandos/agentes/skill… |
| `/onion-work-tools:analysis` | Análise rápida usando template padrão. |
| `/onion-work-tools:analyze-complex-problem` | Análise estruturada de problemas complexos com template oficial. |
| `/onion-work-tools:backlog` | Regenerar docs/backlog.md — a projeção humana do trabalho ABERTO do core, a partir dos nós abertos (status open) da camada canônica (docs/onion/graph) + grafos… |
| `/onion-work-tools:co-evolve` | Orienta a sessão na co-evolução Onion core↔derivados — detecta o papel do repo (core/consumidor via .claude/.onion-version), lê o inbox de mensagens pendentes,… |
| `/onion-work-tools:co-relay` | Carteiro-LOCAL do doc-bridge (UPSTREAM) — espelho do /meta:co-deliver. |
| `/onion-work-tools:constellation` | 🗺️ O MAPA da Constelação de Estudos — visão macro das N estrelas (estudos discuss/*) lendo SÓ os metadados (frontmatter+Tier-0) de cada SEED. |
| `/onion-work-tools:context-freshness` | Audita o frescor dos contextos de domínio (docs/business-context/, docs/technical-context/, docs/compliance-context/) tratando-os como SSOT viva, não snapshot. |
| `/onion-work-tools:diary` | Gerencia o diário de aprendizado da instância Onion — sistema de breadcrumbs para o Transformer. |
| `/onion-work-tools:kb-freshness` | Audita cada KB em docs/knowledge-base/ contra o fluxo ATUAL do Sistema Onion (ferramenta Workflow nativa, padrões canônicos 2026, lineup de modelos Claude vige… |
| `/onion-work-tools:kg` | Modela uma investigação/auditoria longa como Knowledge Graph SDAAL (.kg.yaml): claims/evidência/decisões tipados, arestas SUPPORTS/REFUTES/SUPERSEDES, planes D… |
| `/onion-work-tools:metaspec-validate` | Valida um artefato/decisão contra as metaspecs vigentes, aplicando a constituição do @metaspec-gate-keeper. |
| `/onion-work-tools:orchestrate` | Orquestra subagentes em paralelo (fan-out/fan-in) sobre uma tarefa, via a ferramenta nativa Workflow. |
| `/onion-work-tools:recover` | Recupera a identidade Onion de um repo adotado que perdeu contato com o framework: regenera .onion-version ausente/incompleto e o skeleton do CLAUDE.md. |
| `/onion-work-tools:setup-code-review` | Setup, validação e otimização de code review automático no CI (GitHub Actions). |
| `/onion-work-tools:setup-integration` | Configura integrações do Sistema Onion (Task Managers, Gamma, etc). |

## Agentes

| Agente | Especialidade |
|---|---|
| `@metaspec-gate-keeper` | Guardião do DNA arquitetural que valida alinhamento com metaspecs e princípios de design. |

## Skills

| Skill | Quando ativa |
|---|---|
| `onion-onboarding` | Ajuda alguém a CONHECER e USAR o Onion — orienta a família (papéis), situa o papel do repo atual e conduz aos primeiros valores. |
| `onion-orchestration` | Reconhece trabalho elegível a fan-out e autora/dispara um script da ferramenta nativa Workflow que codifica o padrão canônico certo. |
| `onion-retro` | Retro/feedback como spec-as-code. |
| `onion-wizard` | Conduz o maestro por um MOVIMENTO da família Onion — criar um repo p/ cliente, adotar um projeto, promover a hub, atualizar um adotado. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `c483eef9acc8` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
