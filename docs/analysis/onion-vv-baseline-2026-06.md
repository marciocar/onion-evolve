---
title: Baseline de Verificação e Validação do Onion — Junho/2026
date: 2026-06-02
status: baseline
fonte-plano: ~/.claude/plans/preciso-que-fa-a-um-serialized-peach.md
escopo: Fase 0 (estado "antes") do plano de V&V + T1.5 + T3.2
---

# Baseline de Verificação e Validação do Onion — Junho/2026

Estado do framework **antes** da execução do plano de verificação/validação
(modernização de plataforma + T1.5 outliers + T3.2 piloto). Serve como linha de
base para medir o "depois".

Inventário geral: **49 agentes** (29.637 linhas) · **93 arquivos de comando**
(inclui fragmentos `common/` e 2 symlinks quebrados).

---

## 1. Inventário de tamanhos

### 1.1 Agentes acima do recomendado (≤1.200)

| Arquivo | Linhas | Tier |
|---|---|---|
| `.claude/agents/meta/command-creator-specialist.md` | 1.519 | 🔴 HARD (>1.500) |
| `.claude/agents/development/system-documentation-orchestrator.md` | 1.387 | 🟡 soft |
| `.claude/agents/development/gitflow-specialist.md` | 1.206 | 🟡 soft |

> `docker-specialist` (1.192), `presentation-orchestrator` (1.190),
> `gamma-api-specialist` (1.168), `agent-creator-specialist` (1.135),
> `postgres-specialist` (1.123) estão **abaixo** do recomendado (OK), porém
> próximos do limite — monitorar.

### 1.2 Comandos acima do recomendado (≤500)

| Arquivo | Linhas | Tier |
|---|---|---|
| `.claude/commands/validate/test-strategy/analyze.md` | 1.134 | 🔴 HARD (>800) |
| `.claude/commands/meta/create-abstraction.md` | 859 | 🔴 HARD (>800) |
| `.claude/commands/common/templates/business-context-template.md` | 747 | 🟡 soft · template* |
| `.claude/commands/product/analyze-pain-price.md` | 694 | 🟡 soft |
| `.claude/commands/validate/qa-points/estimate.md` | 660 | 🟡 soft |
| `.claude/commands/validate/collab/pair-testing.md` | 632 | 🟡 soft |
| `.claude/commands/git/README.md` | 605 | 🟡 soft · README* |
| `.claude/commands/product/transform-consolidated.md` | 577 | 🟡 soft |
| `.claude/commands/product/task.md` | 555 | 🟡 soft |
| `.claude/commands/common/templates/technical-context-template.md` | 525 | 🟡 soft · template* |
| `.claude/commands/test/integration.md` | 508 | 🟡 soft |
| `.claude/commands/validate/collab/three-amigos.md` | 504 | 🟡 soft |

> `*` = arquivo que **não é comando invocável** (template/README); candidato a
> relocação/enxugamento, não a refatoração de lógica.

**Resumo:** 2 agentes + 1 hard agente = 3 agentes; 12 comandos >500 (2 hard).

---

## 2. Matriz de conformidade de plataforma (tecnologias atuais Claude Code)

| Recurso | Estado | Evidência |
|---|---|---|
| `settings.json` (hooks) | ❌ ausente | nenhum `.claude/settings.json` |
| `settings.local.json` | ❌ ausente | — (e **não coberto** pelo `.gitignore`) |
| `.mcp.json` (registro MCP) | ❌ ausente | MCP só implícito nos `tools` dos agentes |
| `allowed-tools` em comandos | ⚠️ 1/93 | só `meta/create-skill.md` |
| `model` em comandos | ✅ 77/~89 reais | maioria `sonnet` |
| `model` em agentes | ⚠️ 48/49 | falta em `development/runflow-specialist.md` |
| `tools` em agentes | ✅ 49/49 | todos declaram |
| `allowed-tools` em skills | ⚠️ 3/4 | falta em `skills/language-standards/SKILL.md` |
| Agent Skills (`.claude/skills/`) | ✅ 4 skills | onion, onion-patterns, onion-validation, language-standards |
| CLAUDE.md | ✅ completo | roteamento provider, idioma, formatação |
| Spec as Code | ✅ | meta-specs L0 + business/technical/knowledge-base |

### 2.1 Comandos reais sem frontmatter YAML

São comandos invocáveis (não fragmentos) que deveriam ter header:

- `.claude/commands/product/README.md`
- `.claude/commands/git/README.md`
- `.claude/commands/product/analyze-pain-price.md`
- `.claude/commands/product/branding.md`

> Os arquivos em `common/prompts/*` e `common/templates/*` são **fragmentos de
> skill** (carregados como `common:prompts:*` / `common:templates:*`), não
> comandos — ausência de frontmatter é aceitável para eles.

---

## 3. Resíduos da estrutura `.onion/` abandonada (achado novo)

Dois **symlinks quebrados** apontam para `.onion/contexts/`, estrutura
formalmente abandonada em 2026-05-18:

| Symlink | Aponta para (inexistente) |
|---|---|
| `.claude/commands/engineer/help.md` | `../../../.onion/contexts/technical/commands/help.md` |
| `.claude/commands/product/help.md` | `../../../.onion/contexts/business/commands/help.md` |

**Ação:** remover ambos (links mortos) — alinhado ao abandono de `.onion/`.

---

## 4. Itens de correção derivados (entrada para Fases 1–2)

1. Criar `.claude/settings.json` com hooks mínimos genéricos.
2. Adicionar `settings.local.json` ao `.gitignore`.
3. Criar `.claude/.mcp.json` declarando MCP servers.
4. Adicionar `allowed-tools` a comandos sensíveis + documentar em `commands.md`.
5. Adicionar `model:` a `runflow-specialist.md`.
6. Adicionar `allowed-tools:` a skill `language-standards`.
7. Normalizar frontmatter de 4 comandos reais sem header.
8. Remover 2 symlinks quebrados de `.onion/`.
9. Refatorar 3 agentes + 12 comandos acima do recomendado (T1.5).
10. Relocar 2 templates de `commands/common/templates/` para `docs/templates/`.

---

## 5. Comandos de re-auditoria (para a verificação final)

```bash
# tamanhos
find .claude/agents   -name '*.md' -exec wc -l {} \; | sort -rn | head
find .claude/commands -name '*.md' -exec wc -l {} \; | sort -rn | head
# plataforma
ls .claude/settings.json .claude/.mcp.json
grep -rL '^allowed-tools:' .claude/commands/engineer/pr.md .claude/commands/product/task.md
# symlinks quebrados (deve retornar vazio)
find .claude -xtype l
```
