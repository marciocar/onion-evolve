# Onion — plugin `onion` do Sistema Onion 🧅

Nucleo operacional do Sistema Onion: o orquestrador mestre (skill onion) + skills core (language-standards, patterns, validation, orchestration) + runtime (warm-up/catch-up) + os motores (kg-radar: knowledge-graph SSOT como runtime, doutrina Elenxo/Dogfood) + guardas (hook exit-2 deterministico, aside-router) + abstracoes SDAAL (task-manager Jira/ClickUp/Asana/Linear, forge github). Instala a capacidade; o adotante gera os PROPRIOS grafos. Nao inclui a meta-fabrica.

**Versão** `0.1.164` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 4 |
| Agentes | 1 |
| Skills | 5 |
| Hooks | 2 |

**Capacidades (Capability Contract):** provê `master-orchestration`, `knowledge-graph-runtime`, `kg-freshness-reverify`, `sdaal-task-manager`, `sdaal-forge`, `session-runtime`, `dogfood-doctrine`, `language-standards`; requer `skill:onion-orchestration`.

## Comandos

Invocação: `/onion:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion:catch-up` | Briefing de retomada — reconstrói "onde paramos" de sinais duráveis (git recente, sessão ACTIVE, memória, inbox) após queda/saída de sessão. |
| `/onion:kg-freshness` | RE-VERIFICA contra o vivo os nós de um .kg.yaml — o que o radar apenas DETECTA. |
| `/onion:onion` | Ponto de entrada inteligente para o Sistema Onion. |
| `/onion:warm-up` | Preparação geral do projeto - contexto completo do Sistema Onion. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@onion` | Orquestrador master do Sistema Onion com conhecimento completo de 51 agentes e 109 comandos. |

## Skills

| Skill | Quando ativa |
|---|---|
| `language-standards` | Aplica padrões de idioma e documentação do projeto. |
| `onion-orchestration` | Reconhece trabalho elegível a fan-out e autora/dispara um script da ferramenta nativa Workflow que codifica o padrão canônico certo. |
| `onion-patterns` | Padrões de nomenclatura, estrutura e convenções do Sistema Onion. |
| `onion-validation` | Regras de validação para componentes do Sistema Onion. |
| `onion` | Orquestrador mestre do Sistema Onion. |

## Hooks

| Evento | Script |
|---|---|
| `UserPromptSubmit` | `aside-router-hook.sh` |
| `PostToolUse` | `bash-empty-result-guard.sh` |

Hooks são determinísticos (bash) e podem VETAR uma ação com `exit 2` — é a capacidade que só existe no Claude Code. Nenhum envia dados para fora; todos rodam local.

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `40c73b85f485` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
