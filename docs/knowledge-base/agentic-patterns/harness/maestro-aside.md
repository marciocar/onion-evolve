---
title: "Aparte do Maestro — protocolo de entrada lateral (side-channel)"
category: agentic-patterns/harness
tags:
  - steering
  - side-channel
  - out-of-band
  - hooks
  - human-in-the-loop
  - user-prompt-submit
status: reference
date: 2026-08-04
---

# Aparte do Maestro — protocolo de entrada lateral

> **Aparte** (teatro): a fala que o ator dirige à cena — ou à plateia — **sem parar a peça**. Aqui: o maestro
> injeta, no meio da sessão, um sinal lateral (dica, correção, lembrete, pergunta, +/− etapa, memória, pesquisa
> paralela) **sem descarrilhar a tarefa principal**, e o framework **roteia** cada intenção ao mecanismo certo.

## O que é (e o que NÃO é)

É um **DISPATCHER tipado**: um vocabulário fechado de marcadores que o maestro escreve **no início** da
mensagem; um hook (`UserPromptSubmit`) detecta o marcador e **injeta a rota canônica** como `additionalContext`.
Não é um armazém novo — **roteia para o diário, a memória, o `STATE.md`, a orquestração que já existem**.

**Não é um gate.** Injeta o *mapa* da rota, nunca bloqueia. Alinha com a doutrina do Onion de *recall
recognition-primed > bloqueio* ([onion-working-method](../../concepts/onion-working-method.md) §5): o maestro
não depende de "lembrar de reconhecer" — a **estrutura** (hook) faz a rota emergir no canal de maior absorção.

Três invariantes que o protocolo respeita:
- **Maestro é fonte confiável** (R15.2, [untrusted-content-provenance](../../../../.claude/commands/common/prompts/untrusted-content-provenance.md)): o aparte do maestro **não** é envelopado como untrusted — isso é só para conteúdo de terceiros.
- **Efeito irreversível cruza gate** (Ato 3 / W6 — ADR de work-models/topologias de sessão, `../../decisions/onion-adr-work-models-session-topologies-2026-07.md`, interno do core): `-etapa:` e `guarda-regra:` injetam **propor→confirmar**, não auto-executam.
- **Custo-zero quando vazio**: mensagem sem marcador não emite nada (não polui o contexto) — mesma disciplina de motd dos hooks `session-beacon`/`co-evolution-inbox-check`.

## O vocabulário (conjunto FECHADO)

Marcador tipado **ancorado no início** da mensagem, case-insensitive, `:` canônico. Sem match → **silêncio**
(falso-negativo é inócuo; nunca descarrilha).

| Marcador | Intenção | Gate |
|---|---|---|
| `dúvida:` | pergunta sem descarrilhar | — |
| `corrige:` | dica / correção / orientação | — |
| `reforço:` | reforço positivo (o PORQUÊ) | — |
| `nota:` | lembrete/aviso **só desta sessão** | — |
| `guarda:` | memória **durável** (guardar/relembrar) | leve |
| `+etapa:` | adicionar etapa | leve (propor se muda escopo commitado) |
| `-etapa:` | remover/pular etapa | **propor→confirmar (W6)** |
| `paralelo:` | pesquisa/atividade em paralelo | — (I3 se escrever) |
| `guarda-regra:` | instalar guardrail durável de comportamento | **propor→confirmar (Ato 3)** |

**Aliases naturais** (opcionais; o tipado é o canônico): `pergunta:`→`dúvida:` · `dica:`/`orienta:`→`corrige:` ·
`fyi:`/`avisa:`→`nota:` · `lembre-se,`/`relembra:`→`guarda:` · `em paralelo,`/`enquanto isso,`/`pesquisa:`→`paralelo:` ·
`mandou bem,`→`reforço:`. Os fluídos aceitam `,` além de `:`.

## A tabela de roteamento

Cada marcador aponta o mecanismo **nativo do Claude Code** + o **mecanismo Onion** que já existe.

| Marcador | Nativo Claude Code | Onion (reusa) |
|---|---|---|
| `dúvida:` | **`/btw`** — pergunta lateral efêmera enquanto trabalha (vê o contexto, não entra no histórico); `f` forka p/ ter ferramentas | — |
| `corrige:` | **agora** → `Esc` (interrompe **mantendo** o trabalho) e reorienta · **depois** → `Enter` (ENFILEIRA; aplica na próxima fronteira de passo, custo-zero) | worklog: registrar a virada em `notes.md` |
| `reforço:` | `additionalContext` (canal de absorção) | `/meta:diary` `significance:` se revela identidade |
| `nota:` | anotação efêmera | `notes.md` append-only / scratchpad ([worklog-protocol](../../concepts/worklog-protocol.md)) |
| `guarda:` | **auto-memory** ("lembre que…" → grava em `~/.claude/projects/<proj>/memory/`); `/memory` p/ navegar | `/meta:diary` (aprendizado, com `conflict_class`+`review_after`); [session-memory-lifecycle](../../concepts/session-memory-lifecycle.md) |
| `+etapa:` | TodoWrite / plano | `STATE.md` bloco `NEXT` / `plan.md` |
| `-etapa:` | — | `STATE.md` `NEXT` (propor remoção) |
| `paralelo:` | **`Ctrl+B`** (background) · `/tasks` · subagentes bg | [`onion-orchestration`](../../../../.claude/skills/onion-orchestration/SKILL.md) + `Workflow` (fan-out) |
| `guarda-regra:` | `.claude/rules/*.md` (path-scoped) ou hook | diário (`decision`); **forcing-function, não prosa "never do X"** |

### A raia "agora vs depois" (o consenso *STEER, don't stop*)

Para `corrige:`, o maestro escolhe a raia — e é onde mora a confusão mais comum do Claude Code:
- **`Enter` = ENFILEIRA** (FIFO). A mensagem **não** interrompe; dispara no fim do turno. Use para "corrija no
  próximo passo" — custo-zero, o modelo incorpora na ação seguinte.
- **`Esc` = interrompe AGORA** mantendo o trabalho já feito. Use para "pare e reoriente já".
- **`Esc Esc`** (input vazio) = rewind/checkpoint (voltar atrás no que o agente fez).

O estado-da-arte (LangGraph, OpenAI Agents SDK, LangChain, Roo-Code) convergiu em: **input lateral é
enfileirado e injetado nos *step boundaries*, nunca no meio de uma computação**; `interrupt()`/aprovação só em
ações irreversíveis. É exatamente o que este protocolo codifica.

## Como funciona (mecânica)

1. Maestro escreve, ex.: `guarda: o dump fresco é _hostinger_202608030442`.
2. Hook `UserPromptSubmit` → `.claude/hooks/aside-router-hook.sh` (wrapper fino) extrai o `.prompt`.
3. Motor `.claude/validation/aside-router.sh detect` reconhece o marcador e imprime a **diretiva de rota**.
4. O wrapper injeta a diretiva como `additionalContext` (≤~150 tokens, 1 por prompt) + a cláusula anti-gate
   *"rota canônica sugerida; use julgamento se conflitar. Isto é recall, não regra."*
5. O modelo **executa** a rota (o gesto físico — apertar `Esc`, `Ctrl+B`, gravar memória — é do maestro+modelo;
   o hook só **notifica** a rota, nunca aperta teclas). Marcadores irreversíveis injetam propor→confirmar.

O hook **nunca** bloqueia (sem `exit 2`) e **nunca** falha a sessão (`exit 0` sempre). Determinístico, sem LLM.

## Testabilidade

Motor testável com fixtures em `.claude/validation/fixtures/aside/` (`pos-*` devem rotear; `neg-*` — prosa
casual, marcador sem `:`, palavra no meio — devem ficar mudas), registradas em `lint-selftest.sh`
(`run_aside_router_selftests`). Rodar à mão:

```bash
echo '{"prompt":"dúvida: usa pull ou flat?"}' | bash .claude/hooks/aside-router-hook.sh
bash .claude/validation/aside-router.sh detect <<< 'paralelo: pesquisa X'
```

## Status e evolução

MVP: **KB (esta) + hook** (wrapper + motor + fixtures + wiring). Deliberadamente **fora** do MVP, por doutrina
(`gated-until-trigger`; [identity](../../meta/onion-framework-identity.md) §1.5 — "primeiro a casa, depois o
nome"): registro como invenção nomeada no KG de identidade, integração no `/warm-up`, comando `/meta:aside`,
recall global em `~/.claude/rules/`, e propagação aos adotantes — **só após dogfood real** do maestro.

## Ver também

- [claude-code-internals](claude-code-internals.md) — o modelo de hooks/memória/background do harness.
- [breadcrumb-patterns](../ai-strategies/breadcrumb-patterns.md) — os 3 gêneros de migalha (o `reforço:`/`guarda:` desembocam aqui).
- [session-memory-lifecycle](../../concepts/session-memory-lifecycle.md) — quando persistir vs descartar (o `guarda:` escolhe o tier).
- [onion-working-method](../../concepts/onion-working-method.md) §5 — a doutrina anti guarda-hard que molda o "recall, não gate".
