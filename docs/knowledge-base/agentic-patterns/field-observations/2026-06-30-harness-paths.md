---
date: 2026-06-30
subject: Como o Claude Code armazena state — paths e convenções do harness
status: promoted
promoted_to: harness/claude-code-internals.md
---

# 2026-06-30 — Harness Paths (Claude Code)

## O que originou esta observação

Durante uma sessão de um adotante (teste E2E de dispersão do motor), o maestro
viu dois paths internos do harness que nunca tinha visto explicitamente:

**Path 1** — task output (efêmero):
```
/tmp/claude-1000/-home-<user>-<project>/d5d16703-.../tasks/byjz0kaab.output
```

**Path 2** — workflow journal (persistente):
```
~/.claude/projects/-home-<user>-<project>/d5d16703-.../subagents/workflows/wf_f9902145-332/agent-a29e919445b736448.jsonl
```

A pergunta "qual o formato desses arquivos? de onde vem esse padrão?" abriu a
conversa que mapeou os internals do harness.

## O que surpreendeu

1. **Dois escopos de lifecycle opostos:** o mesmo session UUID aparece em `/tmp/`
   (efêmero) e em `~/.claude/` (persistente) — mas para fins completamente diferentes.
   O `/tmp` é para tasks de curta vida; o `~/.claude` é para journals que precisam
   sobreviver ao reboot para permitir `resumeFromRunId`.

2. **A codificação do workdir:** a conversão `/home/user/proj` → `-home-user-proj`
   é simples (barra vira hífen, prefixo `-`), mas não é óbvia. Uma vez que você vê,
   consegue decodificar qualquer path do harness só pelo nome da pasta.

3. **O poll pattern:** `sleep 8 && cat <path>.output` não é "aguardar o subprocess" —
   é uma poll manual porque o harness não tem event-driven para o task output. O modelo
   aguarda N segundos e então lê. Parece primitivo mas funciona de forma previsível.

4. **JSONL para journals:** append-only permite `tail -5 | python3 -c ...` para checar
   status sem bloquear o writer. É assim que `/workflows` mostra progresso sem polling
   explícito do modelo.

## Como isso levou ao KB

A conversa revelou que o maestro nunca tinha mapeado explicitamente os internals do
harness — cada observação era pontual e se perdia. A proposta de criar uma KB
`agentic-patterns/` nasceu daqui: um lugar estruturado para acumular e distil esse
conhecimento sem perder a dimensão de "o que surpreendeu".

Esta observação foi imediatamente promovida para `harness/claude-code-internals.md`
porque era completa e verificável.
