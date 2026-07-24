---
date: 2026-07-24
instance: onion-evolve
type: innovation
classification: collective
tags: [co-evolution, doc-bridge, multi-checkout, reconciliation, dogfood, fix-becomes-mechanism, federation-health]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "Ao fechar um nó 'declarado != entregue' de anúncio (C_ANNOUNCE_BACKLOG e família), NÃO assuma pelo status do outbox — rode a reconciliação outbox×inbound (Passo 2.1 do /meta:co-evolve: comm -13 entre o que o core marcou _processed e o que está no inbound do checkout que TRABALHA). O status do core mente sozinho na topologia multi-checkout. Quando achar transportado-mas-ausente, recupere por re-entrega (cp never-clobber / co-deliver, entrega-sem-commit I3) para o local_path do members.yaml, não para o path histórico."
review_after: 2026-10-22
conflict_class: static
significance: "A reconciliação outbox×inbound (Passo 2.1), mecanizada em 2026-07-23 a partir de um sinal de campo, caçou uma perda REAL menos de 24h depois — 5 anúncios do metagamify marcados transportados mas ausentes do checkout que trabalha — provando o loop fix-becomes-mechanism no menor intervalo possível."
---

## Signal
**A guarda construída ontem achou a falha de hoje.** Ao fechar o nó `C_ANNOUNCE_BACKLOG` do grafo
`federation-health` (que dizia "anúncios 07-18 em staging, não transportados"), rodei a reconciliação
`outbox×inbound` — o **Passo 2.1** do `/meta:co-evolve`, mecanizado ONTEM (2026-07-23) a partir do sinal de
campo multi-checkout. Dois resultados: o backlog 07-18 era **stale** (tudo já em `_processed`), MAS o mesmo
`comm -13` pegou um caso **real**: 5 anúncios do metagamify (07-09/07-16) marcados transportados no core e
**ausentes do inbound do checkout do VPS**. O mecanismo provou seu valor no menor intervalo possível.

## Evidence
- **A mecanização (07-23):** commit `8451a39` adicionou o Passo 2.1 ao `/meta:co-evolve` — `comm -13` entre
  `outbox/<id>/_processed/` (o que o core diz ter entregue) e o `inbound{,/_processed}/` do adotante,
  quando core e adotante vivem na mesma máquina. Nasceu do sinal `2026-07-21-carteiro-cego-adotante-multi-checkout`.
- **A caçada (07-24):** rodado contra metagamify/pulse-mais/onion-mini. pulse-mais e onion-mini limpos; o
  metagamify acusou 5 ausentes: `2026-07-09-{consolidacao-multibranch,resposta-kg-dogfood-domain-layer,
  resposta-mapa-consolidacao-verificacao,sdaal-design-vertical}` + `2026-07-16-kg-first-mechanism`. Todos em
  `outbox/metagamify/_processed/` (core: "entregue"), nenhum no inbound do `/home/marcio/rhilo-metagamify` — a
  cegueira multi-checkout exata que o sinal descreveu (entregues ao path histórico, não ao que trabalha).
- **A recuperação:** re-entrega por cópia never-clobber do `_processed` do core → inbound do adotante
  (entrega-sem-commit; o adotante commita/processa — I3). Re-reconciliação: zerou.
- **Reconciliado no grafo (append-mostly):** `E_ANNOUNCE_BACKLOG_RECONCILED` SUPERSEDES `C_ANNOUNCE_BACKLOG`
  (commit `391d7f7`); radar integridade 13/13. Fecha a família de "declarado≠verificado" da federação junto
  das re-verificações de pin de granaai e metagamify no mesmo dia.

## Next crumb
Ver `next_recommended`. É a prova de campo de [[fix-must-become-mechanism]] no menor ciclo possível (guarda
nasce dia 1, pega falha dia 2) — irmã de [[pin-enters-proving-itself]] (capacidade exercida contra adotantes
reais, não desenhada) e de [[radar-is-runtime-investigations-born-as-graph]] (o grafo dirige: foi o KG-first
do warm-up que apontou o nó a fechar). O passo maior segue gated: `C_FED_RADAR_ABSENT` (o radar de federação
unificado — o Passo 2.1 é uma de suas peças vivas).
