# Onion · Docs — plugin `onion-docs` do Sistema Onion 🧅

Vertical de documentacao do Onion: contexto de negocio/tecnico como spec-as-code, C4 (Context/Container/Component) + Mermaid, health/validacao de docs e engenharia reversa. Camada 1; business/technical-context = camada 2 do consumidor.

**Versão** `0.1.23` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `silver`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-docs@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-docs@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-docs@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 10 |
| Agentes | 5 |
| Skills | 0 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `business-technical-context`, `c4-model-mermaid`, `docs-health-validacao`, `engenharia-reversa`; requer `agent:c4-architecture-specialist`, `agent:c4-documentation-specialist`, `agent:mermaid-specialist`, `agent:docs-reverse-engineer`.

## Comandos

Invocação: `/onion-docs:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-docs:build-business-docs` | Gerar arquitetura de contexto de negócio em `docs/business-context/`. |
| `/onion-docs:build-index` | Gerar e atualizar índices de documentação em docs/ a partir da estrutura real (contagens escaneadas, nunca hardcoded). |
| `/onion-docs:build-tech-docs` | Gerar arquitetura de contexto técnico em `docs/technical-context/`. |
| `/onion-docs:consolidate-documents` | Consolida múltiplos documentos usando análise profunda, identificando divergências, convergências e insights estratégicos. |
| `/onion-docs:docs-health` | Health check completo da documentação do projeto. |
| `/onion-docs:help` | Ajuda interativa para comandos de documentação Onion. |
| `/onion-docs:refine-vision` | Refinar visão e estratégia do produto/projeto. |
| `/onion-docs:reverse-consolidate` | Engenharia reversa de projetos para gerar documentação consolidada. |
| `/onion-docs:sync-sessions` | Sincronizar e organizar sessões de trabalho do Sistema Onion. |
| `/onion-docs:validate-docs` | Validação de completude e consistência da documentação. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@c4-architecture-specialist` | Especialista em arquitetura C4 Model (Context, Containers, Components) com Mermaid. |
| `@c4-documentation-specialist` | Especialista em documentação textual C4 Model (Context, Container, Component, ADRs). |
| `@docs-reverse-engineer` | Especialista em engenharia reversa de projetos para análise estrutural e documentação. |
| `@mermaid-specialist` | Especialista em diagramas Mermaid para documentação Markdown renderizada em GitHub, IDEs (VS Code/Cursor com extensões) e Mermaid Live Editor. |
| `@system-documentation-orchestrator` | Orquestrador de documentação técnica que coordena @mermaid-specialist e @c4-architecture-specialist. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `e810818c71bb` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
