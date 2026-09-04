# Onion · Compliance — plugin `onion-compliance` do Sistema Onion 🧅

Vertical de compliance do Onion: documentacao de conformidade como spec-as-code (ISO 27001/22301, SOC2, PMBOK) via agentes especialistas + build-compliance-docs. Auto-adapta ao compliance-context do consumidor (SDAAL).

**Versão** `0.1.19` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `gold`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-compliance@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-compliance@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-compliance@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 1 |
| Agentes | 5 |
| Skills | 1 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `iso-27001-isms`, `iso-22301-bcms`, `soc2-tsc`, `pmbok-governance`, `build-compliance-docs`, `ssot-context-resolver`; requer `agent:security-information-master`, `agent:iso-27001-specialist`, `agent:iso-22301-specialist`, `agent:soc2-specialist`, `agent:pmbok-specialist`, `command:build-compliance-docs`, `skill:onion-compliance-context`, `template:compliance-context-template.md`, `template:compliance_iso27001_template.md`, `template:compliance_iso22301_template.md`, `template:compliance_soc2_template.md`, `template:compliance_pmbok_template.md`.

## Comandos

Invocação: `/onion-compliance:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-compliance:build-compliance-docs` | Gerar arquitetura de compliance em `docs/compliance-context/`. |

## Agentes

| Agente | Especialidade |
|---|---|
| `@iso-22301-specialist` | Especialista em ISO 22301:2019 (BCMS) para documentação de continuidade de negócios. |
| `@iso-27001-specialist` | Especialista em ISO/IEC 27001:2022 (ISMS) para documentação completa de SGSI. |
| `@pmbok-specialist` | Especialista em PMBOK Guide 7th Edition para documentação de governança de projetos. |
| `@security-information-master` | Orquestrador de compliance que detecta frameworks (ISO 27001, ISO 22301, PMBOK, SOC2) e delega. |
| `@soc2-specialist` | Especialista em SOC2 Type II (AICPA Trust Services Criteria) para documentação de controles. |

## Skills

| Skill | Quando ativa |
|---|---|
| `onion-compliance-context` | Contrato de SSOT mínimo e resolver de contexto da vertical de COMPLIANCE do Onion. |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `1a75423eadc7` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
