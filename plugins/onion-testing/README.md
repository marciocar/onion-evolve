# Onion · Testing — plugin `onion-testing` do Sistema Onion 🧅

Vertical de testes/QA do Onion: geracao e execucao de testes (unit/integration/e2e) com deteccao de framework + validacao de workflow. Perspectivas White/Grey/Black-box e QA story points. Camada 1.

**Versão** `0.1.18` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-testing@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-testing@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-testing@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 4 |
| Agentes | 3 |
| Skills | 0 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `geracao-testes-unit-integration-e2e`, `estrategia-de-teste`, `qa-story-points`; requer `agent:test-agent`, `agent:test-engineer`, `agent:test-planner`.

## Comandos

Invocação: `/onion-testing:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-testing:e2e` | Gera e executa testes end-to-end automaticamente com detecção de framework. |
| `/onion-testing:integration` | Gera e executa testes de integração automaticamente com detecção de framework. |
| `/onion-testing:unit` | Gera e executa testes unitários automaticamente com detecção de framework. |
| `/onion-testing:workflow` | Validar completude de workflows do Sistema Onion. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@test-agent` | Especialista completo em estratégias de teste baseado no Framework Completo de Testes e QA. |
| `@test-engineer` | Especialista em testes unitários práticos que verifica comportamento real. |
| `@test-planner` | Especialista em planejamento e cobertura de testes para análise sistemática. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `88b7ac12f360` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
