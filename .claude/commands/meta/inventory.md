---
name: inventory
description: Regenerar o inventário canônico do Sistema Onion (comandos, agentes, skills, KBs) a partir do filesystem. Use para atualizar docs/onion/inventory.md após criar/remover recursos e manter as contagens (CLAUDE.md, index) em sincronia — a SSOT que o lint protege.
model: haiku
category: meta
tags: [inventory, ssot, counts, generator, self-evolution]
version: "1.0.0"
updated: "2026-06-14"
allowed-tools: Read Edit Bash(bash .claude/validation/inventory.sh*) Bash(find *) Bash(diff *)
argument-hint: "(sem argumentos — sempre regenera tudo do filesystem)"
---

# /meta:inventory — Inventário Canônico (SSOT)

## 🎯 Objetivo

Manter o **inventário canônico** do Sistema Onion como **fonte única de verdade
(SSOT)** computada do filesystem — nunca digitada à mão. Materializa o princípio
**"documentação deriva, não repete"**: as contagens em `CLAUDE.md`, `docs/onion/index.md`
e nos guias **derivam** deste inventário, não o contradizem.

> **Por que existe:** contagens hardcoded (79 comandos, 38 agentes, 4 skills…)
> entropizam a cada recurso criado. A SSOT + o guard de lint
> (`check_inventory_sync` em `lint-artifacts.sh`) tornam o drift **impossível de
> mergear** — é o braço de **auto-evolução** do framework. Relacionado:
> `/docs:build-index` (navegação de `docs/`) e `/meta:evolve` D8 (reporta drift).

## ⚡ Execução

### Passo 1 — Regenerar o inventário (determinístico, sem LLM)

```bash
bash .claude/validation/inventory.sh --markdown > docs/onion/inventory.md
```

O script (`inventory.sh`) é a autoridade: conta `.claude/commands` (invocáveis,
exceto `common/` e READMEs), `.claude/agents` (exceto READMEs), `.claude/skills/`
(diretórios) e `docs/knowledge-base` (exceto `index.md`), por categoria e total.

### Passo 2 — Capturar os totais canônicos

```bash
bash .claude/validation/inventory.sh --env
# ONION_COMMANDS_TOTAL / ONION_AGENTS_TOTAL / ONION_SKILLS_TOTAL / ONION_KBS_TOTAL …
```

### Passo 3 — Reconciliar derivados (apenas se divergirem)

Ler e, **somente onde houver número divergente**, alinhar à SSOT — sem reescrever prosa:

- `CLAUDE.md` — bloco de inventário (linha "N comandos invocáveis…", agentes, skills).
- `docs/onion/index.md` — Visão + Estatísticas.
- `docs/knowledge-base/index.md` — total de KBs e contagem por subpasta.

Onde possível, prefira **apontar para `docs/onion/inventory.md`** em vez de repetir o número.

### Passo 4 — Validar

```bash
bash .claude/validation/lint-artifacts.sh   # check_inventory_sync deve passar (0 HARD)
```

Se o lint acusar drift, é porque o Passo 1 não foi rodado ou um recurso mudou
depois — rode o Passo 1 de novo.

## 📤 Saída esperada

```
✅ docs/onion/inventory.md regenerado
   ◆ Comandos: <N>  ◆ Agentes: <N>  ◆ Skills: <N>  ◆ KBs: <N>
✅ Derivados reconciliados: <lista de arquivos tocados> (ou "nenhum — já em sincronia")
✅ lint check_inventory_sync: OK
```

## ⚠️ Notas

- **Read-only sobre `.claude/`**: o comando só escreve `inventory.md` e ajusta
  contagens em docs — nunca cria/remove recursos.
- **Idempotente**: rodar 2× sem mudança no filesystem não altera nada.
- **O número nunca vem da memória** — sempre do `inventory.sh`. Se o script e a
  prosa divergem, o script vence.

## 🔗 Referências

- SSOT: `.claude/validation/inventory.sh` · Artefato: `docs/onion/inventory.md`
- Guard: `.claude/validation/lint-artifacts.sh` (Regra 8 — `check_inventory_sync`)
- Relacionados: `/docs:build-index`, `/meta:evolve` (D8), `/meta:kb-freshness`
