# Onion — plugin `onion` do Sistema Onion 🧅

Núcleo operacional do Sistema Onion: o orquestrador mestre (skill onion), runtime de knowledge graph (kg + radar soberano + kg-freshness), sessões e diário, orquestração de subagentes, condução (wizard/onboarding/retro), validação de meta-specs, co-evolução upstream e os adapters SDAAL de task-manager e forge.

**Versão** `0.1.236` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

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
| Comandos | 22 |
| Agentes | 2 |
| Skills | 8 |
| Hooks | 2 |

**Capacidades (Capability Contract):** provê `master-orchestration`, `knowledge-graph-runtime`, `kg-freshness-reverify`, `sdaal-task-manager`, `sdaal-forge`, `session-runtime`, `dogfood-doctrine`, `language-standards`, `knowledge-graph-sdaal`, `learning-diary`, `orchestration`, `metaspec-validation`, `freshness-audits`, `constellation-map`, `co-evolution-upstream`, `plan-graph-drive`, `plan-graph-realign`, `guided-conduction`, `guided-onboarding`, `retro-feedback`; requer `skill:onion-orchestration`, `agent:metaspec-gate-keeper`.

## Comandos

Invocação: `/onion:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion:all-tools` | Apresenta, sob demanda, as ferramentas disponíveis no contexto atual (nativas do Claude Code + MCP) e defere ao inventário canônico para comandos/agentes/skill… |
| `/onion:analysis` | Análise rápida usando template padrão. |
| `/onion:analyze-complex-problem` | Análise estruturada de problemas complexos com template oficial. |
| `/onion:backlog` | Regenerar docs/backlog.md — a projeção humana do trabalho ABERTO do core, a partir dos nós abertos (status open) da camada canônica (docs/onion/graph) + grafos… |
| `/onion:catch-up` | Briefing de retomada — reconstrói "onde paramos" de sinais duráveis (git recente, sessão ACTIVE, memória, inbox) após queda/saída de sessão. |
| `/onion:co-evolve` | Orienta a sessão na co-evolução Onion core↔derivados — detecta o papel do repo (core/consumidor via .claude/.onion-version), lê o inbox de mensagens pendentes,… |
| `/onion:co-relay` | Carteiro-LOCAL do doc-bridge (UPSTREAM) — espelho do meta:co-deliver. |
| `/onion:constellation` | 🗺️ O MAPA da Constelação de Estudos — visão macro das N estrelas (estudos discuss/*) lendo SÓ os metadados (frontmatter+Tier-0) de cada SEED. |
| `/onion:context-freshness` | Audita o frescor dos contextos de domínio (docs/business-context/, docs/technical-context/, docs/compliance-context/) tratando-os como SSOT viva, não snapshot. |
| `/onion:diary` | Gerencia o diário de aprendizado da instância Onion — sistema de breadcrumbs para o Transformer. |
| `/onion:drive` | Conduz um plano-grafo até o fim com rigor Onion — censo→avança→Elenxo→dogfood→realign→checkpoint (degrau AUDIT) |
| `/onion:kb-freshness` | Audita cada KB em docs/knowledge-base/ contra o fluxo ATUAL do Sistema Onion (ferramenta Workflow nativa, padrões canônicos 2026, lineup de modelos Claude vige… |
| `/onion:kg-freshness` | RE-VERIFICA contra o vivo os nós de um .kg.yaml — o que o radar apenas DETECTA. |
| `/onion:kg` | Modela uma investigação/auditoria longa como Knowledge Graph SDAAL (.kg.yaml): claims/evidência/decisões tipados, arestas SUPPORTS/REFUTES/SUPERSEDES, planes D… |
| `/onion:metaspec-validate` | Valida um artefato/decisão contra as metaspecs vigentes, aplicando a constituição do @metaspec-gate-keeper. |
| `/onion:onion` | Ponto de entrada inteligente para o Sistema Onion. |
| `/onion:orchestrate` | Orquestra subagentes em paralelo (fan-out/fan-in) sobre uma tarefa, via a ferramenta nativa Workflow. |
| `/onion:realign` | Revisão em camadas da jornada do plano × o vivo — o "selo realinhado" (passado/presente/futuro) |
| `/onion:recover` | Recupera a identidade Onion de um repo adotado que perdeu contato com o framework: regenera .onion-version ausente/incompleto e o skeleton do CLAUDE.md. |
| `/onion:setup-code-review` | Setup, validação e otimização de code review automático no CI (GitHub Actions). |
| `/onion:setup-integration` | Configura integrações do Sistema Onion (Task Managers, Gamma, etc). |
| `/onion:warm-up` | Preparação geral do projeto - contexto completo do Sistema Onion. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@metaspec-gate-keeper` | Guardião do DNA arquitetural que valida alinhamento com metaspecs e princípios de design. |
| `@onion` | Orquestrador master do Sistema Onion com conhecimento completo de 51 agentes e 109 comandos. |

## Skills

| Skill | Quando ativa |
|---|---|
| `language-standards` | Aplica padrões de idioma e documentação do projeto. |
| `onion-onboarding` | Ajuda alguém a CONHECER e USAR o Onion — orienta a família (papéis), situa o papel do repo atual e conduz aos primeiros valores. |
| `onion-orchestration` | Reconhece trabalho elegível a fan-out e autora/dispara um script da ferramenta nativa Workflow que codifica o padrão canônico certo. |
| `onion-patterns` | Padrões de nomenclatura, estrutura e convenções do Sistema Onion. |
| `onion-retro` | Retro/feedback como spec-as-code. |
| `onion-validation` | Regras de validação para componentes do Sistema Onion. |
| `onion-wizard` | Conduz o maestro por um MOVIMENTO da família Onion — criar um repo p/ cliente, adotar um projeto, promover a hub, atualizar um adotado. |
| `onion` | Orquestrador mestre do Sistema Onion. |

## Hooks

| Evento | Script |
|---|---|
| `UserPromptSubmit` | `aside-router-hook.sh` |
| `PostToolUse` | `bash-empty-result-guard.sh` |

Hooks são determinísticos (bash) e podem VETAR uma ação com `exit 2` — é a capacidade que só existe no Claude Code. Nenhum envia dados para fora; todos rodam local.

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `meta:adopt` (comando do core, não distribuído por plugin) no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `6db8ec8d8a03` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Comandos do core citados (não distribuídos neste plugin)

Estes comandos aparecem no texto sem a barra inicial porque pertencem ao core do Onion (meta-fábrica ou outra superfície) e **não** são instalados por este plugin: `engineer:work`, `meta:adopt`, `meta:co-announce`, `meta:co-deliver`, `meta:create-agent`, `meta:create-command`, `meta:create-knowledge-base`, `meta:create-skill`, `meta:evolve`, `meta:federation-check`, `meta:graph`, `meta:inventory`, `meta:personality-sync`, `validate:collab`. Estão disponíveis num repo que adotou o Onion por vendorização (`.claude/` completo).

## Funciona melhor com

Comandos deste plugin citam: `onion-compliance`, `onion-engineering`, `onion-product`. Não é dependência — sem eles, essas menções apontam para comandos não instalados.

## Licença

MIT (texto integral em `LICENSE`, na raiz do plugin) — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
