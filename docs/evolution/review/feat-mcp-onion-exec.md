---
branch: feat/mcp-onion-exec
pr: 644
date: 2026-08-20
reviewed_diff_sha256: 4ca2d1c9e19125897e759a6abc8f3847ace0ad72be7e32a5f19a374132918326
findings_total: 3
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: CONFORME-CAMADA1-CONTIDA-WRITE-EH-PROPOSTA
reviewer: passada adversarial manual (3 ataques: shell-injection, escrita no grafo vivo, camada-2-vazando); sem subagentes
REVISOU: true
---

# Resíduo — `feat/mcp-onion-exec`

**Origem:** ordem do maestro (Camadas 1 e 2 em fronteira de ACL) — F6.5, o último degrau do plano.

## Os 3 ataques (limpos)

- **(a) shell-injection nas tools de exec?** As 3 tools de comando usam listas fixas (`['bash',
  'script']`) sem interpolação de argumento livre — `kg_freshness` valida o path (`..`+sufixo)
  antes. `propose_kg_write` valida slug por regex e não passa nada ao shell.
- **(b) propose_kg_write escreve o grafo vivo?** Não — grava só em `docs/evolution/kg-inbox/` com
  sufixo `.proposal.kg.yaml`; testado (a proposta caiu na fila, o grafo vivo ficou intacto). O
  radar ali é advisory; o gate real é a selagem pelo core (I3).
- **(c) a Camada 2 (prompt livre) vazou?** Não existe no server — grep por 'bridge_task'/prompt
  livre = zero. A superfície é 4 tools nomeadas, ponto.

## O desenho, em uma linha

read (onion-kg) + exec-contido (onion-exec) fecham o ciclo KG no chat; o write é PROPOSTA que o
core sela (fila kg-inbox). A Camada 2 fica gated por ACL — o Bridge roda bypassPermissions, e
prompt livre exposto seria dar o core inteiro a quem alcança a tool.

## Ressalva declarada

O `run_lint`/`run_inventory` executam no core como marcio — são idempotentes e read-only de
efeito (emitem, não gravam), mas consomem CPU; sem rate-limit próprio além do timeout de 300s.
Consumidor concreto ainda é 1 (o maestro); se abrir a mais usuários, rate-limit entra.
