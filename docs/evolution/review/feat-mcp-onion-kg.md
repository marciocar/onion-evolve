---
branch: feat/mcp-onion-kg
pr: 643
date: 2026-08-20
reviewed_diff_sha256: 9659a8881df0ba9d025394f37ae9c6fedf5dd3c9d5fa4189113792842fef67c0
findings_total: 3
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: CONFORME-READ-ONLY-PROVADO-E-TRAVERSAL-RECUSADO
reviewer: passada adversarial manual (3 ataques, 2 contra a superfície de segurança); sem subagentes
REVISOU: true
---

# Resíduo — `feat/mcp-onion-kg`

**Origem:** ordem do maestro ("sim" ao passo 2) — o MCP onion-kg construído e conectado no
mesmo dia da spec F4b.

## Os 3 ataques (limpos, re-medidos no servidor VIVO)

- **(a) read-only é read-only?** grep no server: zero opens de escrita, zero subprocess
  mutante, zero os.remove/rename — todas as 6 tools são leitura por construção.
- **(b) path traversal?** `kb_get` com `../../.env` → recusado ("caminho docs/knowledge-base");
  `kg_radar` com `../onion-vps-waha/.envrc` → recusado (".kg.yaml do repo"). Os dois checks
  (`..` + prefixo/sufixo) seguram as duas tools que aceitam caminho.
- **(c) sobrevive a reboot?** unit `enabled`, `After=docker.service` (o bind 172.23.0.1 só
  existe com a bridge de pé).

## Lições de campo seladas no caminho (não são achados meus novos)

1. `restart` não injeta env nova — o 401 do 1º boot era o token ausente; `up -d` recria.
2. `allowedAddresses` exige `host:PORT` (Zod) — fix descoberto pela sessão da PoC sob
   autorização do maestro, deixado sem commit para o core selar; selado neste ciclo.
3. Warn `SSE stream not available (404)` é benigno: o GET de stream é opcional no
   streamable-http e o server stdlib não o implementa — mesmo comportamento do molde da PoC.

## Ressalva declarada

O token vive em EnvironmentFile 600 (root) — a exceção declarada da casa para serviços de
boot (GPG não destrava sem humano; mesmo desenho do onion-vps-bridge). E o write-leg segue
NÃO construído por desenho: proposta-que-o-core-sela é fila futura, gated por demanda real.
