---
title: "Revisão adversarial PÓS-HOC do backlog abrangente + fixes R1/R2"
date: 2026-08-23
branch: fix/backlog-owner-anchor-posthoc-review
reviewer: "@branch-code-reviewer (passada adversarial, mandato REFUTAR)"
reviewed_diff_sha256: a58e41ea7d554839789863c3fb6cdaf0b5dbec4c432cfa945ef47f7d2fcef46d
findings_total: 8
findings_real: 2
tokens: 53959
duration_min: 8
verdict: VERDE
---

# Resíduo de revisão — REGRA 56 (revisão PÓS-HOC + fixes)

## Contexto: um slip de processo, remediado

O commit `7195d5dc` (escopo abrangente do backlog) foi para **main sem PR** — eu estava em main
após o merge anterior e não branchei (2ª vez na sessão; nomeado para virar mecanismo). Passou o
pre-commit local (0 HARD + selftest), mas pulou CI + a passada adversarial. **Remediação:** rodei a
revisão adversarial pós-hoc sobre o delta `25a18205..7195d5dc`, e trago os fixes que ela pediu por
este PR próprio (com branch), fechando o buraco de processo.

## A revisão (8 frentes, mandato refutar) — VERDE

Passaram: dedup canônico∪marcado (fios-abertos 1×; F4b presente), ordenação por max-atenção
(m2-bridge-logto @119 no topo, monotônica), `unset`+`declare` por grafo (não vaza entre grafos),
`set -uo pipefail` com assoc-array vazio (default-expansion imune), idempotência (byte-idêntico),
`--check`, lint **0 HARD**, guarda REGRA 58 verde no F4b, doc↔comportamento sem contradição.

## Os 2 achados — CORRIGIDOS neste PR

- **R1 (baixa, latente) — CORRIGIDO.** O awk id→owner só resetava `id` após imprimir; um nó SEM
  `owner:` mantinha o id vivo, e um `owner:` posterior (edge/aninhado) casaria o id errado. Hoje é
  latente (0 grafos têm `owner:`) e não-regressão (a v1 tinha a mesma classe). **Cura:** âncora
  `/^[^[:space:]]/ { id="" }` — linha top-level (nodes:/edges:/meta:) sai do escopo do nó. **Provado:**
  `owner:` numa edge de nó sem-owner NÃO vaza mais.
- **R2 (cosmética) — CORRIGIDO.** Comentário dizia "depois por tamanho" mas o `sort` só ordena por
  atenção. Comentário alinhado ao código.

## Veredito

**VERDE** — a mudança resistiu ao mandato de refutar (7/8 frentes limpas; 2 ressalvas menores, ambas
curadas neste PR). Output idêntico (508 abertos), idempotente, `bash -n` limpo. O slip de processo
fica registrado; a cura (guarda anti-commit-em-main) segue nomeada como próximo mecanismo.
