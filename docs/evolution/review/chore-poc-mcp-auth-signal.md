---
title: "Revisão — sinal downstream à PoC (MCP auth) — PR #651"
date: 2026-08-22
branch: chore/poc-mcp-auth-signal
pr: 651
reviewer: "self-review (autor) — doc único de baixo risco (envelope co-evolução, 74 linhas, não código)"
reviewed_diff_sha256: 7f3bdd997f8c3783432d403c9eb4855be477fe2fd3c8ed81c7537b4d15737761
findings_total: 4
findings_real: 0
tokens: 2500
duration_min: 3
verdict: APROVADO
---

# Resíduo de revisão — REGRA 56 (self-review declarado)

Passada adversarial do autor sobre um envelope doc-bridge de 74 linhas (não código, baixo risco).
Subagente-terceiro seria desproporcional; a natureza do artefato está declarada no campo `reviewer`.

## Eixos checados (tentei refutar)

| Eixo | Resultado |
|---|---|
| **NDA** — vaza nome de cliente? | ✅ só o slug `poc-venda-direta-pdi`; grep por BW&P/HPE/autos = 0 (a entrada do members.yaml exige slug, cliente vive no CLAUDE.md do adotante) |
| **Reprodutibilidade do achado** | ✅ o `curl` do envelope foi de fato rodado: `:3031` devolveu tools/list completo SEM X-Api-Key (200), medido, não declarado |
| **Correção técnica do fix** | ✅ o padrão fail-closed (`hmac.compare_digest` + 401) espelha `ops/mcp-onion-kg/server.py` — o precedente vivo do mesmo repo-família; `compare_digest` (não `==`) evita timing-attack |
| **Fronteira I3** | ✅ escreve só na staging do core (`outbox/`); rodapé instrui o maestro a transportar ao `inbound/` da PoC; a sessão do core não pusha repo alheio |

## Veredito

**APROVADO** — o sinal é honesto (comportamento medido, não declaração), o fix é do lado correto (PoC, I3),
o handoff em 3 passos é explícito, e o NDA é respeitado (slug). Nada a corrigir.
