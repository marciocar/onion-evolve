# 🤖 Agentic Patterns — Knowledge Base

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-06-30 |
| **Categoria** | Agentic Patterns |
| **Tags** | `ai`, `harness`, `strategies`, `transformer`, `claude-code` |

---

## 🎯 Missão

Mapear e evoluir o conhecimento sobre **como operar IA de perto**: comportamentos internos
de harnesses, estratégias de guiar o transformer, padrões que emergem do uso real.

Esta KB **não é documentação de produto** — é conhecimento destilado do campo. Nasce de
observar o transformer operar, notar o que surpreende, e formalizar o que se repete.

**Escopo deliberadamente aberto:** Claude Code é o foco inicial (dogfood), mas a KB evolui
com qualquer harness ou framework que o maestro operar — Cursor, Codex, Copilot, frameworks
open-source, etc. Fechar ao Claude Code seria trair o princípio de adaptação constante.

---

## 🗂️ Trilhos

| Trilho | O que captura | Formalidade |
|--------|---------------|-------------|
| [`harness/`](harness/README.md) | Internals de harnesses: paths, task systems, hooks, protocolos de armazenamento | Alta |
| [`ai-strategies/`](ai-strategies/README.md) | Padrões de guiar o transformer + estratégias que funcionam na prática | Média |
| [`field-observations/`](field-observations/README.md) | Observações brutas do dia a dia — o que surpreendeu, o que emergiu | Baixa |

---

## 🔄 Processo de Evolução (dogfood)

```
campo
  └→ field-observations/ (captura rápida, sem polir)
       └→ assess (pelo maestro — vale formalizar?)
            └→ harness/ ou ai-strategies/ (entrada formal, distilada)
```

Espelha o ciclo `inbox/` → triagem → core do Onion. A observação bruta é o insumo;
a entrada formal é o produto. **Não pular a observação** — o campo sabe antes da teoria.

**Curadoria periódica:** a cada ciclo de evolução do core, revisar `field-observations/`
e promover o que amadureceu. O não-promovido permanece como evidência histórica.

---

## 📚 Índice de Entradas

### harness/
- [Claude Code — Internals](harness/claude-code-internals.md) — filesystem layout, task system, workflow journals, hooks, memória

### ai-strategies/
- [Object-Led Discovery & Fitting](ai-strategies/object-led-discovery.md) — promover objeto a papel via ciclo dirigível
- [Breadcrumb Patterns](ai-strategies/breadcrumb-patterns.md) — forçar absorção vs acomodação no transformer

### field-observations/
- [2026-06-30 — Harness Paths](field-observations/2026-06-30-harness-paths.md) — conversa que originou este KB
