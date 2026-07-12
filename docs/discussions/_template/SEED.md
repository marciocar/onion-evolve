---
title: "Fonte de discussão — <TEMA>"
category: discussion
status: fonte-de-discussao-isolada
date: <AAAA-MM-DD>
branch: discuss/<slug>
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: SEED            # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "<uma frase imperativa: o próximo passo, análogo ao ## NEXT do STATE.md>"
scope_globs: ["docs/"]           # globs que este estudo TENDE a tocar (detecta colisão de escopo entre estrelas)
objective_tags: []               # ex.: ["NS1", "north-star"] (detecta convergência de objetivo entre estrelas)
---

# 🧵 <TEMA> — <subtítulo de uma linha>

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os outros temas.

## O tema
<o que é este estudo, em 2-3 frases>

## Por que importa pro Onion
<a conexão estratégica: north-star, verticais, um gap real>

## Perguntas de partida
1. <pergunta 1>
2. <pergunta 2>

## Conexões com o que já existe
<KBs, ADRs, outros estudos que aterram esta discussão — pra a sessão começar afiada, não do zero>

## Como abrir
`cd ~/worktrees/onion-evolve/discuss-<slug> && claude`

---
<!--
Fases (campo `phase:` acima):
  SEED     recém-semeada, ainda não explorada
  EXPLORE  explorando amplo
  DEEP     descendo fundo num ângulo (Tier-2→3)
  CONVERGE fechando pra uma decisão/síntese
  PROMOTE  pronta pra virar entrega (feat/*) ou ser trazida ao core
  PARK     estacionada (pausa consciente)
Recolher = atualizar `phase` + `next_action` ANTES de rotacionar (handoff-commitado). O mapa re-lê daqui.
-->
