# Onion · Design — plugin `onion-design` do Sistema Onion 🧅

Vertical de design do Onion: identidade visual como spec-as-code (tokens W3C/DTCG), gate WCAG e materializacao via design-sink. Auto-adapta ao design-context do consumidor.

**Versão** `0.1.22` (derivada do conteúdo: anda quando o conteúdo anda) · **Licença** MIT · **Conformance** `gold`

## Instalar

```
/plugin marketplace add marciocar/onion-plugins
/plugin install onion-design@onion-plugins
```

Instalado ≠ habilitado: se os comandos não aparecerem, `/plugin enable onion-design@onion-plugins` e reinicie o Claude Code (hooks só carregam em sessão nova).

```
# CLI, sem prompt
claude plugin marketplace add marciocar/onion-plugins && claude plugin install onion-design@onion-plugins
```

## O que traz

| Componente | Quantidade |
|---|---|
| Comandos | 3 |
| Agentes | 3 |
| Skills | 0 |
| Hooks | 0 |

**Capacidades (Capability Contract):** provê `design-tokens-w3c-dtcg`, `wcag-contrast-gate`, `materializacao-css-tailwind-shadcn`; requer `agent:design-system-specialist`, `agent:brand-generator`, `agent:branding-positioning-specialist`, `validation:lint-design-tokens.sh`, `util:design-source`, `util:design-sink`.

## Comandos

Invocação: `/onion-design:<comando>` (namespace do plugin).

| Comando | O que faz |
|---|---|
| `/onion-design:deck` | Gerador de deck de treino/onboarding AUTO-GUIADO como HTML self-contained: uma spec (roteiro de slides) vira um deck que abre em qualquer navegador, OFFLINE (f… |
| `/onion-design:generate` | Camada generativa da vertical de design: diverge (N identidades por IA, em orquestração paralela) → converge (gate WCAG determinístico filtra + juiz ranqueia) … |
| `/onion-design:identity` | Cria e desenvolve a identidade visual de um projeto como spec-as-code: brief (lê business-context) → develop (tokens W3C/DTCG na SSOT design-context, gate WCAG… |

## Agentes

| Agente | Especialidade |
|---|---|
| `@brand-generator` | Gerador divergente de identidade visual: propõe N variações de paleta/identidade (cores, papéis semânticos) a partir de um brief, em W3C/DTCG. |
| `@branding-positioning-specialist` | Especialista em Branding e Posicionamento de Marca que aplica métodos, estratégias e frameworks modernos de 2025 para desenvolver identidade de marca, posicion… |
| `@design-system-specialist` | Especialista em design system técnico: materializa design tokens W3C/DTCG em código (CSS vars, Tailwind v4 @theme, shadcn/ui), audita acessibilidade (WCAG) e m… |

## Requisitos

- Claude Code ≥ 2.1.239 (marketplace com `pluginRoot`); `bash`, `git`, `awk`; `python3` (motores KG e censos); `jq` opcional.
- Este plugin instala **capacidade** (read-only, atualizável pelo gerenciador). Não é adoção: para vendorizar o Onion num repo, o canal é `/meta:adopt` no repositório-fonte.

## Proveniência

| Campo | Valor |
|---|---|
| Fonte | `marciocar/onion-evolve` |
| tree_sha (hash do conteúdo das fontes) | `56e2fddc1720` |

Ref e data do commit de origem estão em `.claude-plugin/provenance.json`.

Artefato GERADO por `assemble-plugin.sh` + `plugin-readme.sh` a partir da SSOT em `.claude/` do source. Não edite à mão: a próxima montagem sobrescreve.

## Licença

MIT — © Onion · Marcio Carvalho. Site: https://onionevolve.com · Fonte: https://github.com/marciocar/onion-evolve
