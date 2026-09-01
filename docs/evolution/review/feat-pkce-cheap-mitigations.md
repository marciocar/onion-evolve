---
title: "Revisão — etapa 2: as mitigações PKCE passam a EXISTIR no vivo"
date: 2026-09-01
branch: feat/pkce-cheap-mitigations
reviewer: "tudo provado pelo estado vivo: CSP medida por curl -sI (3 headers, host OIDC corrigido de login→auth ANTES de morder — o instalador validado pegou); rotação aplicada e provada por re-run idempotente ('com rotação') após curar o check que comparava só a chave velha (declarado≠verificado no próprio idempotente); chave rotateRefreshToken confirmada no build do Logto vivo antes de usar; SUSPENSAO.md corrigido de flag-inventada para o caminho real (a classe que o censo pune, pega em auto-revisão)"
reviewed_diff_sha256: 98ec3072d1475dfd48f056dba83144e95724bfa517a4172065812a80a2155577
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 0
duration_min: 25
---

# Resíduo — REGRA 56

Etapa 2 da ordem: CSP no Caddyfile versionado (instalador com validate/reload/rollback) ·
rotateRefreshToken no provision + check de idempotência curado · SUSPENSAO.md ·
D_TTL_UX_TRADEOFF SUPERSEDES o refutado (TTL 3600 selado como decisão, rotação como compensação).
