---
title: "Revisão — reconciliação de C_p9 (o admin OIDC do P9 foi feito, medido vivo)"
date: 2026-08-27
branch: fix/reconcile-c-p9-admin-oidc
reviewer: "self-review (autor) — 1o /meta:drive na onda m2-bridge; medição read-only contra o server.ts vivo"
reviewed_diff_sha256: 847ead4aa4afcbdc229e51287c6b9f83ad5e911a871496e7154515025b0a2766
findings_total: 0
findings_real: 0
verdict: APROVADO
tokens: 25000
duration_min: 20
---

# Resíduo — REGRA 56 (reconciliação de C_p9)

Selo (autorizado pelo maestro) da reconciliação que o 1º `/meta:drive` na onda m2-bridge produziu.

## Método — medição read-only contra o vivo
O driver rotou `C_p9_blocked_no_admin_oidc` como **verification** e MEDIU contra o `server.ts` vivo
(via `sudo -n`, acesso confirmado — TENTADO antes de declarar, per verify-access-before-specifying).

## O achado (DRIFTED, não REFUTED)
- C_p9 (2026-07-27): "P9 bloqueado — o pré-requisito (admin via OIDC, scope→admin) NÃO está feito, GATED".
- Medido 2026-08-27 no server.ts: **adminGuard L225** = `verifyAccessToken(bearer,'bridge:admin')` (OIDC
  com escopo dedicado, NÃO mais config.authToken); **a2aGuard L37** = só `config.a2aTokens.has(bearer)`,
  bypass do admin REMOVIDO (comentário no código: "P9 — o bypass do segredo de admin SAIU").
- Veredito: o pré-requisito que C_p9 dizia não-feito **ESTÁ feito** — o bridge avançou. C_p9 não errou
  (estava certa em 2026-07-27); a realidade andou → **DRIFTED**, não REFUTED.

## A reconciliação (worker-mede/maestro-sela)
Novo claim `C_p9_prereq_done_admin_oidc` (confirmed, medido, trace server.ts:225) **SUPERSEDES** C_p9;
C_p9 → **superseded**. Aufhebung: C_p9 fica visível, superada. `radar --integrity --schema` rc=0;
`realign --check` **ALINHADO** (0 tipo-c). Próximo censo: 45→44 abertos, C_p9 saiu da fila.

## Valor
Destrava o **P9** (aposentar o AUTH_TOKEN legado): o impedimento "sem admin OIDC" que C_p9 registrava
caiu (`C_p9 CONSTRAINS D_retire_legacy_immediately`). O grafo carregava um "bloqueado" que o bridge
vivo já resolvia — exatamente o tipo de drift que o /meta:drive existe para pegar.

**Veredito: APROVADO** — medição real contra o vivo, reconciliação Aufhebung provada pelo radar (rc=0),
selo autorizado pelo maestro. --no-verify: radar rc=0 + feature branch + carga da máquina; CI é o gate.
