# Onion · Engineering — plugin `onion-engineering` do Sistema Onion 🧅

Vertical de engenharia do Onion: fluxo faseado plan→start→work→pre-pr→pr→pr-update (GitFlow + sessoes persistentes) + especialistas de codigo (Node/React/Postgres/NX/Docker) e gates pre-PR. Camada 1; task-manager e forge do consumidor via SDAAL.

**Versão** `0.1.86` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

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
| Comandos | 17 |
| Agentes | 16 |
| Skills | 1 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `gitflow-faseado`, `pull-request-lifecycle`, `code-review-pre-pr`, `code-specialists-node-react-postgres-nx-docker`, `ssot-context-resolver`; requer `agent:gitflow-specialist`, `agent:branch-code-reviewer`, `agent:code-reviewer`, `agent:nodejs-specialist`, `agent:react-developer`, `agent:postgres-specialist`, `agent:docker-specialist`, `skill:onion-engineering-context`.

## Comandos

Invocação: `/onion-engineering:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-engineering:bump` | Bump de versão seguindo semver. |
| `/onion-engineering:code-review` | [Alias] Redireciona para /meta:setup-code-review (setup de code review no CI). |
| `/onion-engineering:docs` | Invocar agente de documentação para branch atual. |
| `/onion-engineering:fast-commit` | Adiciona todas as mudanças e faz commit rápido. |
| `/onion-engineering:flow` | Dispatcher único do ciclo de vida GitFlow: feature/release/hotfix × start/publish/finish. |
| `/onion-engineering:help` | Ajuda contextual da vertical de engenharia do Onion — o ciclo faseado plan→pr + GitFlow + especialistas. |
| `/onion-engineering:hotfix` | Emergency workflow completo: task no Task Manager + branch hotfix + desenvolvimento. |
| `/onion-engineering:init` | Inicializar repositório com GitFlow e convenções padrão. |
| `/onion-engineering:plan` | Planejamento de feature. |
| `/onion-engineering:pr-update` | Atualizar PR existente com mudanças adicionais. |
| `/onion-engineering:pr` | Criar Pull Request com integração GitFlow e sync automático. |
| `/onion-engineering:pre-pr` | Validação completa antes do PR. |
| `/onion-engineering:start` | Iniciar desenvolvimento de feature. |
| `/onion-engineering:sync` | Sincronização automática de branches com GitFlow e proteção de branches críticas. |
| `/onion-engineering:validate-phase-sync` | Validar sincronização entre fases do plan.md e subtasks do Task Manager. |
| `/onion-engineering:warm-up` | Preparação de contexto técnico e de engenharia. |
| `/onion-engineering:work` | Continuar trabalho em feature ativa. |

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
| `@zen-engine-specialist` | Especialista em ZEN Engine e JDM (JSON Decision Model) para criação, validação e otimização de regras de negócios. |

## Skills

| Skill | Quando ativa |
|---|---|
| `onion-engineering-context` | Contrato de SSOT mínimo e resolver de contexto da vertical de engenharia do Onion. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `1b7e7c0e008a` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
