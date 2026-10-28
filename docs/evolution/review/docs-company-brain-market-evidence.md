---
branch: docs/company-brain-market-evidence
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: sessão autora (passada adversarial curta, só leitura)
nota: "tokens não medidos (0); a passada é da própria sessão, sem revisor independente"
---

# Passada adversarial: `docs/company-brain-market-evidence`

## O que muda

No grafo `docs/onion/graph/company-brain-multiaudiencia-2026-10.kg.yaml`, três nós novos e cinco arestas:
`E_MA_MARKET_CURADORIA_PROPOSTA_1028` (a proposta condicional da curadoria, SUPPORTS `Q_MA_MARKET`),
`Q_MA_FREE_ORG_READ_ENFORCED` (o card do maestro, do qual `Q_MA_ENFORCEMENT` e `D_MA_ARCH` passam a depender) e
`E_MA_MCP_CLONE_SERVIDO_PARADO_1028` (CONSTRAINS `C_MA_MCP_READ_LIVE`). O sinal da curadoria vai para
`docs/evolution/inbox/_processed/`.

## Achados

1. **Real, corrigido.** O `verified_against` de `E_MA_MCP_CLONE_SERVIDO_PARADO_1028` dizia "nenhum timer, cron
   ou script", mas a medida tinha olhado só os timers e o crontab do usuário. Conferi também `/etc/cron.d` e
   `/etc/crontab` (nada do MCP) e o nó passou a nomear o que foi olhado e o que não é legível (o crontab da raiz).
   A ligação com a curadoria ficou em `provenance.source` (o contrato v4.16 não aceita URL em `external_edges`),
   fixada no sha 2c8d3846ce21 da origin/main dela; o `peer-ref-check.sh` deu rc 0 para os dois nós e para o sha do
   PLAN-D (518b332b9eb4, ancestral).
2. **Não real.** Suspeita de nome de cliente no sinal movido (REGRA 36): o grep por nomes de adotante e por
   token/senha deu zero; o único login citado é o do dono, já público nas URLs do repo.

## Mutantes

- Ponta trocada para um id inexistente (`D_COMPANY_BRAIN_MARKET_PROPOSAL_X`): o `peer-ref-check.sh` responde 1,
  não 0 — a conferência separa existe de não existe.

## Limites declarados

- A raiz servida (`ONION_KG_ROOT`) mora num EnvironmentFile só da raiz e não foi lida; a afirmação de que é o
  worktree destacado vem do comentário da unit e do `git log` no worktree que o comentário nomeia.
- O served_commit e os 23 grafos são testemunho do maestro; não houve probe autenticado nesta sessão.
- O código em dia se refere a `ops/mcp-onion-kg`; dependências que o servidor chama fora dessa pasta não foram
  comparadas.
