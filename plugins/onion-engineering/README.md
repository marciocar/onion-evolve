# Onion · Engineering — plugin `onion-engineering` do Sistema Onion 🧅

Vertical de engenharia do Onion: fluxo faseado plan→start→work→pre-pr→pr→pr-update (GitFlow + sessões persistentes), gates pré-PR, especialistas de código (Node, React, Postgres, NX, Docker, segurança) e testes (unit/integration/e2e, estratégia de teste, QA story points).

**Versão** `0.1.118` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-engineering@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-engineering@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-engineering@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 21 |
| Agentes | 19 |
| Skills | 1 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `gitflow-faseado`, `pull-request-lifecycle`, `code-review-pre-pr`, `code-specialists-node-react-postgres-nx-docker`, `ssot-context-resolver`, `geracao-testes-unit-integration-e2e`, `estrategia-de-teste`, `qa-story-points`; requer `agent:gitflow-specialist`, `agent:branch-code-reviewer`, `agent:code-reviewer`, `agent:nodejs-specialist`, `agent:react-developer`, `agent:postgres-specialist`, `agent:docker-specialist`, `skill:onion-engineering-context`, `agent:test-agent`, `agent:test-engineer`, `agent:test-planner`.

## Comandos

Invocação: `/onion-engineering:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-engineering:bump` | Bump de versão seguindo semver. |
| `/onion-engineering:code-review` | [Alias] Redireciona para /onion:setup-code-review (setup de code review no CI). |
| `/onion-engineering:docs` | Invocar agente de documentação para branch atual. |
| `/onion-engineering:e2e` | Gera e executa testes end-to-end automaticamente com detecção de framework. |
| `/onion-engineering:fast-commit` | Adiciona todas as mudanças e faz commit rápido. |
| `/onion-engineering:flow` | Dispatcher único do ciclo de vida GitFlow: feature/release/hotfix × start/publish/finish. |
| `/onion-engineering:help` | Ajuda contextual da vertical de engenharia do Onion — o ciclo faseado plan→pr + GitFlow + especialistas. |
| `/onion-engineering:hotfix` | Emergency workflow completo: task no Task Manager + branch hotfix + desenvolvimento. |
| `/onion-engineering:init` | Inicializar repositório com GitFlow e convenções padrão. |
| `/onion-engineering:integration` | Gera e executa testes de integração automaticamente com detecção de framework. |
| `/onion-engineering:plan` | Planejamento de feature. |
| `/onion-engineering:pr-update` | Atualizar PR existente com mudanças adicionais. |
| `/onion-engineering:pr` | Criar Pull Request com integração GitFlow e sync automático. |
| `/onion-engineering:pre-pr` | Validação completa antes do PR. |
| `/onion-engineering:start` | Iniciar desenvolvimento de feature. |
| `/onion-engineering:sync` | Sincronização automática de branches com GitFlow e proteção de branches críticas. |
| `/onion-engineering:unit` | Gera e executa testes unitários automaticamente com detecção de framework. |
| `/onion-engineering:validate-phase-sync` | Validar sincronização entre fases do plan.md e subtasks do Task Manager. |
| `/onion-engineering:warm-up` | Preparação de contexto técnico e de engenharia. |
| `/onion-engineering:work` | Continuar trabalho em feature ativa. |
| `/onion-engineering:workflow` | Validar completude de workflows do Sistema Onion. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@branch-code-reviewer` | Especialista em revisão de código pré-PR focado em mudanças do branch atual. |
| `@branch-documentation-writer` | Especialista em documentação que sincroniza docs com mudanças do branch atual. |
| `@branch-metaspec-checker` | Especialista em validação de conformidade com metaspecs para o branch atual. |
| `@branch-test-planner` | Especialista em cobertura de testes para mudanças do branch atual. |
| `@claude-code-specialist` | Especialista em Claude Code para otimização, configuração e troubleshooting. |
| `@code-reviewer` | Especialista em revisão de código focado em correção e manutenibilidade. |
| `@docker-specialist` | Especialista em Docker, containerização de apps Node.js/Next.js, Docker Compose e integração com PostgreSQL. |
| `@gitflow-specialist` | Especialista em GitFlow para branching, releases e versionamento semântico. |
| `@linux-security-specialist` | Especialista em segurança Linux para hardening, auditoria e resposta a incidentes. |
| `@nodejs-specialist` | Especialista em backend Node.js/TypeScript com PNPM e performance optimization. |
| `@nx-migration-specialist` | Especialista em migração segura de NX Monorepo (v19+ para v21+). |
| `@nx-monorepo-specialist` | Especialista em NX Monorepo para criação de libs/apps e estrutura enterprise. |
| `@postgres-specialist` | Especialista em PostgreSQL 17 para triggers, functions, schema e performance. |
| `@react-developer` | Especialista em React moderno com shadcn/ui, TypeScript e arquitetura component-first. |
| `@runflow-specialist` | Especialista em Runflow SDK e plataforma para desenvolvimento de agentes IA, workflows e integrações. |
| `@test-agent` | Especialista completo em estratégias de teste baseado no Framework Completo de Testes e QA. |
| `@test-engineer` | Especialista em testes unitários práticos que verifica comportamento real. |
| `@test-planner` | Especialista em planejamento e cobertura de testes para análise sistemática. |
| `@zen-engine-specialist` | Especialista em ZEN Engine e JDM (JSON Decision Model) para criação, validação e otimização de regras de negócios. |

## Skills

| Skill | Quando ativa |
|---|---|
| `onion-engineering-context` | Contrato de SSOT mínimo e resolver de contexto da vertical de engenharia do Onion. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `meta:adopt` (comando do core, não distribuído por plugin) no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Origem | `marciocar/onion-evolve` (repositório privado) |
| tree_sha (hash do conteúdo das fontes) | `cc4d2798649f` |

A origem identifica DE ONDE este artefato foi gerado; o canal público de instalação, issues e suporte é https://github.com/marciocar/onion-plugins. Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Comandos do core citados (não distribuídos neste plugin)

Estes comandos aparecem no texto sem a barra inicial porque pertencem ao core do Onion (meta-fábrica ou outra superfície) e **não** são instalados por este plugin: `git:feature:finish`, `git:feature:publish`, `git:feature:start`, `git:hotfix:finish`, `git:hotfix:start`, `git:release:finish`, `git:release:start`, `meta:adopt`, `test:watch`. Estão disponíveis num repo que adotou o Onion por vendorização (`.claude/` completo).

## Funciona melhor com

Comandos deste plugin citam: `onion`. Não é dependência — sem eles, essas menções apontam para comandos não instalados.

## Licença

MIT (texto integral em `LICENSE`, na raiz do plugin) — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Issues e suporte: https://github.com/marciocar/onion-plugins
