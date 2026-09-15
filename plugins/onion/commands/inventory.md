---
name: inventory
description: Regenerar o inventário canônico do Sistema Onion (comandos, agentes, skills, KBs) a partir do filesystem. Use para atualizar docs/onion/inventory.md após criar/remover recursos e manter as contagens (CLAUDE.md, index) em sincronia — a SSOT que o lint protege.
category: meta
tags: [inventory, ssot, counts, generator, self-evolution]
version: "1.0.0"
updated: "2026-06-14"
allowed-tools: Read Edit Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh*) Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh*) Bash(find *) Bash(diff *)
argument-hint: "(sem argumentos — sempre regenera tudo do filesystem)"
---

# /onion:inventory — Inventário Canônico (SSOT)

## 🎯 Objetivo

Manter o **inventário canônico** do Sistema Onion como **fonte única de verdade
(SSOT)** computada do filesystem — nunca digitada à mão. Materializa o princípio
**"documentação deriva, não repete"**: as contagens em `CLAUDE.md`, `docs/onion/index.md`
e nos guias **derivam** deste inventário, não o contradizem.

> **Por que existe:** contagens hardcoded (79 comandos, 38 agentes, 4 skills…)
> entropizam a cada recurso criado. A SSOT + o guard de lint
> (`check_inventory_sync` em `lint-artifacts.sh`) tornam o drift **impossível de
> mergear** — é o braço de **auto-evolução** do framework. Relacionado:
> `/onion-product:build-index` (navegação de `docs/`) e `meta:evolve` D8 (reporta drift).

## ⚡ Execução

### Passo 1 — Regenerar o inventário (determinístico, sem LLM)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh --markdown > docs/onion/inventory.md
```

O script (`inventory.sh`) é a autoridade: conta `commands/` (invocáveis, exceto
`common/` e READMEs), `agents/` (exceto READMEs), `skills/` (diretórios) e
`docs/knowledge-base` (exceto `index.md`), por categoria e total.

### Passo 2 — Capturar os totais canônicos

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh --env
# ONION_COMMANDS_TOTAL / ONION_AGENTS_TOTAL / ONION_SKILLS_TOTAL / ONION_KBS_TOTAL …
```

### Passo 3 — Propagar para os derivados (determinístico, sem reescrita à mão)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh --fix
```

O lint **sabe**, por arquivo, qual é a contagem correta (computa do filesystem) e
**reescreve apenas as frases-de-total divergentes** — frase canônica inteira, com as
palavras-âncora preservadas (`N comandos invocáveis`, `N agentes e M comandos`,
`N agentes/comandos em M categorias`, `N Knowledge Bases`). Herda o **mesmo escopo e
exclusões** da detecção: nunca toca `docs/materials/` (marketing), `docs/analysis/`
(datado), snapshots, nem a própria SSOT (que é **regenerada**, não editada frase a frase).
Idempotente — rodar de novo é no-op. **Fecha o loop**: "gerar" agora é acoplado a
"propagar", então um add/remove de recurso não pode mais terminar com violação.

> **Não cobre por design** (reconciliação manual): breakdowns por categoria em prosa
> (estrutura, não só número) e `docs/materials/`. Para esses, edite com contexto.

### Passo 4 — Validar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh   # 0 HARD e 0 SOFT (drift de contagem zerado)
```

Se ainda acusar drift, é um caso **fora do escopo do `--fix`** (breakdown por categoria,
material derivado) — reconcilie à mão, ou um recurso mudou após o Passo 1 (rode de novo).

## 📤 Saída esperada

```
✅ docs/onion/inventory.md regenerado
   ◆ Comandos: <N>  ◆ Agentes: <N>  ◆ Skills: <N>  ◆ KBs: <N>
✅ --fix: <N> arquivo(s) realinhado(s) à SSOT (ou "nenhuma frase-de-total divergente")
   <arquivo:linha — frase antiga → frase nova, por mudança>
✅ lint: 0 HARD / 0 SOFT
```

## ⚠️ Notas

- **Read-only sobre `.claude/`**: o comando só escreve `inventory.md` e ajusta
  contagens em docs — nunca cria/remove recursos.
- **Idempotente**: rodar 2× sem mudança no filesystem não altera nada.
- **O número nunca vem da memória** — sempre do `inventory.sh`. Se o script e a
  prosa divergem, o script vence.

## 🔗 Referências

- SSOT: `${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh` · Artefato: `docs/onion/inventory.md`
- Guard: `${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh` (Regra 8 — `check_inventory_sync`)
- Relacionados: `/onion-product:build-index`, `meta:evolve` (D8), `/onion:kb-freshness`
