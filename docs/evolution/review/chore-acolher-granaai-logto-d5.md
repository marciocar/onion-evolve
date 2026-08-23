---
title: "Revisao — acolhimento da org granaai (D5) — self-review"
date: 2026-08-23
branch: chore/acolher-granaai-logto-d5
reviewer: "self-review (autor) — org-map regen + 1 no KG documentando mutacao provada por comportamento"
reviewed_diff_sha256: 7210fd4ab09fd3430177363cc569043154b646c2c8435b1cd6d7a9f4c5604628
findings_total: 4
findings_real: 0
tokens: 1400
duration_min: 3
verdict: APROVADO
---

# Residuo de revisao — REGRA 56 (self-review)

Acolhimento da org orfa D5 (ordem do maestro): rename no Logto + regen do org-map + 1 no KG.

- **Mutacao verificada?** SIM — PATCH /organizations renomeou nome-comercial -> granaai; ANTES/DEPOIS
  medidos; --project-federation confirma "sem divergencia: Logto == SSOT" e granaai saiu de "sem org".
- **Doutrina id-nao-comercial?** SIM — o nome comercial saiu do Logto E do repo (org-map so com ids;
  grep grana.ai|arthur no mapo e no grafo = vazio; lint projecao/NOME verde).
- **KG coerente?** SIM — E_d5_granaai_acolhida (confirmed, verified_at) + SUPPORTS -> D_logto_is_projection;
  radar --integrity --schema exit 0; nao-orfao.
- **Segredo?** NAO ecoado (secret/token nunca impressos; so ids internos do Logto).

**Veredito: APROVADO** — o D5 que a re-verificacao pegou em ato foi fechado, verificado por
comportamento, sem violar a regra "o projetor nunca absorve por conta propria" (a decisao foi do maestro).
