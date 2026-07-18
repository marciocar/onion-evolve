---
title: 'Furo de doutrina — deep-research (harness) não persiste no KG-SSOT automaticamente'
date: 2026-07-18
from: sessão de core-dev (branch discuss/onion-pessoal-app, na VPS)
to: onion-evolve (core / sala de design)
type: dogfood-signal (co-evolução, fluxo upstream)
status: novo — triagem pendente (/meta:co-evolve)
re: knowledge-graph-sdaal.md §SSOT-as-runtime (leg write(KG)) · skill deep-research (harness) · /meta:orchestrate · /meta:kg
---

# Sinal: o `write(KG)` do ciclo SSOT-as-runtime não é automático quando a pesquisa vem do harness `deep-research`

> Pedido explícito do maestro (2026-07-18): *"diga para o core que não fez isso natural e automaticamente; este
> furo tem que estar previsto e direcionado por ele para que você e outros não deixem de seguir o padrão da
> doutrina trabalhada com o core."*

## O furo (dogfood de campo)

O harness **`deep-research`** é uma skill **do harness (plugin), não do Onion**. Ela despeja a síntese em
`/tmp/.../tasks/<id>.output` — **efêmero** — e **não** persiste no repo nem cristaliza em `.kg.yaml`. Logo o ciclo
obrigatório **`read(KG) → verify → act → write(KG)`** (`knowledge-graph-sdaal.md` §SSOT-as-runtime) fica com o leg
**`write(KG)` DEPENDENTE de o agente lembrar** de salvar `.md` + rodar `/meta:kg` à mão. É exatamente o modo-de-falha
que a doutrina do KG-first foi criada pra eliminar ("advice-que-depende-de-lembrar falhou empiricamente até para o
próprio autor").

## Evidência (esta sessão, 3 deep-researches)

- A síntese de **compat** (`wte2k70qw`) quase ficou **só no /tmp** — foi salva no repo **apenas porque o maestro
  lembrou** ("não esqueça de guardar as pesquisas e kg"). Sem o lembrete, teria driftado.
- Padrão repetido em 3 pesquisas (`wwujc53hz`, `wte2k70qw`, `wzxz11dvf`): o `write(KG)` foi manual toda vez.

## Direção proposta (o core prevê + direciona — não deixa ao acaso do agente)

1. **Wire determinístico:** `/meta:orchestrate` (e/ou um wrapper Onion do `deep-research`) deve **auto-persistir**
   a síntese em `docs/**/research/*.md` **e** oferecer/exigir a materialização via `/meta:kg` (nó audit + `kg-radar`)
   como **passo do fluxo, não opção**. Fechar a costura harness→repo.
2. **OU gate/afordância na skill `onion-orchestration`:** ao concluir uma pesquisa, o `write(KG)` vira **passo
   obrigatório** (checklist visível), espelhando o KG-first já cabeado em `warm-up`/`catch-up`/`engineer:work`.
3. **Secundário (mesmo espírito, outro furo visto 2× nesta sessão):** o hook `session-beacon-hook.sh`
   (`UserPromptSubmit`) usa **caminho relativo** `.claude/hooks/...` e **quebra quando o cwd deriva** (após `cd`
   a outro repo). Usar `$CLAUDE_PROJECT_DIR` / caminho absoluto — robustez de hook.

## Onde vive a evidência
`docs/discussions/onion-pessoal-app/research/` (3 sínteses `.md` + `stack-research-2026-07.kg.yaml`, radar exit 0),
na branch `discuss/onion-pessoal-app` (pushada). Este sinal foi **staged** na inbox desta branch (a main checkout
estava noutra branch com sessão viva — I3); **relayar para a inbox da main** para triagem via `/meta:co-evolve`.
