---
date: 2026-07-29
instance: onion-evolve
type: learning
classification: collective
tags: [behavior-over-declaration, declarado-vs-verificado, elenxo, d5-pricing, instrumentation, mechanism-over-discipline, verify-live, orchestration]
affects: [meta, product]
breadcrumb_for: []
share_with: []
next_recommended: "Ao RETOMAR um trabalho de sessão anterior (o próprio 'onde parei', um spec, um plano, um pin): VERIFIQUE O VIVO ANTES DE AGIR — git log, o filesystem, o gate rodando, a fonte externa. Numa sessão só, 7 declarações (memória/spec/plano/pin/processo) foram refutadas pelo vivo; cada verificação-antes-de-agir evitou duplicar trabalho feito, cravar boundary falso ou embarcar metric morto. A cura nunca é 'lembrar de verificar' (falha) — é o MECANISMO que verifica por você (gate, radar, selftest, hook ativado, branch protegida). Ao construir sobre um spec, trate cada premissa dele como claim a checar, não fato."
review_after: 2026-10-29
conflict_class: static
significance: "Fechei o D5 (preço/ticket) de ponta a ponta: decisão ratificada (treino=testar, cert=inicial, compliance/SOTA gated) + os 4 sinais de instrumentação valor-por-adotante VIVOS e determinísticos (ciclos #481, frescor+engajamento #482, velocidade #483 — este destravou um metric morto promovendo timestamps de sessão a um ledger tracked sem quebrar 'conteúdo de sessão fica local'). Mas a lição DURÁVEL é o padrão que atravessou a sessão: behavior-over-declaration pagou 7 vezes, sempre igual — uma declaração que o vivo refutou ao ser verificada. É a doutrina que a KB behavior-over-declaration (do próprio core) prega, dogfoodada à exaustão numa sessão real, incluindo contra o meu próprio processo."
---

## O que fechou

O **D5** (preço/ticket) — o resíduo parcial do M1a — foi ao fim de dentro do que dá pra fechar de dentro:

- **Decisão ratificada** (#480): degrau 1 treino = TESTAR 2-3 pontos ($1.8-3k/dia) antes de fixar; degrau 2 cert = só inicial ~$1.250 (renovação gated no diretório); degraus 3-4 (compliance-pack/SOTA) sob-consulta/gated (D6/D2).
- **Instrumentação — 4/4 sinais vivos**, todos determinísticos + custo-zero + `--jsonl` + denominador honesto + selftest: ciclos (`cycle-completion.sh` #481), frescor (`context-freshness-metric.sh` #482), engajamento (`federation-engagement.sh` #482), velocidade (`session-velocity.sh` #483).

O sinal de velocidade nasceu MORTO (o spec mandava `git log -- STATE.md`, mas `.claude/sessions/` é gitignored por desenho) e foi destravado por decisão do maestro: promover só os **timestamps** a um ledger tracked (`.claude/session-lifecycle.jsonl`, apendado pelo beacon em down/sweep), preservando "conteúdo de sessão fica local".

## A lição durável — behavior-over-declaration, 7× numa sessão

O padrão não variou: uma **declaração** (memória, spec, plano, pin, processo) que o **vivo refutou** assim que verificada.

| # | A declaração | O que o vivo mostrou |
|---|---|---|
| 1 | Minha memória de "onde parei" (M1/M3/version-sweep) | já landado em continuações |
| 2 | O M2 (Bridge/Logto) como "coordenar, não faço" | **executado** por outra sessão, provado no ar |
| 3 | O finding #3 (githook refresh) a construir | **já feito** em #462 + guardado por selftest |
| 4 | O commit `e15a657`: org-ids "não verificados" | **byte-match** contra o Logto vivo (`--write-org-map`) |
| 5 | O spec: "status existe em TODO STATE.md" | **2/8 sem status**; last_checkpoint/blocked_by inexistentes |
| 6 | O spec: velocidade via git-history | sessões **gitignored** → metric morto |
| 7 | Meu commit direto na `main` | a **main protegida** rejeitou o push |

## A cura foi sempre mecanismo, nunca disciplina

Nenhuma dessas foi resolvida por "eu lembrar de verificar" (isso falha — é o que o `next_recommended` alerta). Foi sempre um **mecanismo que verifica por mim**: o gate de lint, o kg-radar, o selftest, o hook nativo ativado (finding #1), a branch protegida (caso 7). E os 3 sinais que ship carregam o gap que acharam **no próprio código** — sem-sinal fora do denominador, proxy declarado no cabeçalho, opt-in que não vaza. Honestos por construção, não por promessa.

## Fronteira honesta

O que fechou é o que dá pra fechar **de dentro**: a decisão e os sinais. O que falta é **campo** — o teste real do day-rate, as 1-2 entrevistas P4 pro compliance-pack, o baseline de semanas que dá sentido às séries temporais. Isso é do maestro no mercado, não do core no repo. E os sinais são **proxies core-side** (o adotante é soberano): medem o dogfood do core + a atividade do doc-bridge, não o uso soberano do adotante — nomeado no código, não escondido.
