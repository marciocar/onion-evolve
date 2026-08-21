---
branch: docs/agente-vitrine-onion
pr: 648
date: 2026-08-21
reviewed_diff_sha256: c6e9af5ca6493c5a01d5fddeeb8f91a9d669f25decc50dc9696732f01f3e84f8
findings_total: 2
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: CONFORME-AGENTE-DURAVEL-E-VISIVEL-NA-UI
reviewer: passada adversarial manual; sem subagentes
REVISOU: true
---

# Resíduo — `docs/agente-vitrine-onion`

**Origem:** ordem do maestro — o agente-vitrine Onion com os 3 MCPs.

## Os 2 ataques (limpos)

- **(a) durável?** Sobrevive a restart do api — medido (agente + ACL presentes pós-restart).
  É o defeito que o Onion KB teve (ACL ausente + embeddings órfãos); aqui ACL nasceu junto.
- **(b) visível/consumível na UI?** O endpoint /api/agents (o que a UI lista) mostra o Onion —
  não é fantasma só no banco. Na UI o pool MCP sobe por-usuário na sessão, então as 15 tools
  ficam disponíveis (a via headless que dá 503 é a Agents API, não a UI).

## Registro (não achado) — a atribuição corrigida

Eu havia dito que meu restart apagou o Onion KB; o maestro corrigiu: ELE apagou, porque dava
erro. O erro tinha causa raiz real (RAG owned-by-agent-id + file_ids errados no meu recreate),
agora curada. Corrigir a atribuição no mesmo movimento é a disciplina — não empurrar culpa nem
assumir a que não é minha.

## Ressalva declarada

Agents criados via banco (não UI) funcionam, mas o caminho canônico do produto é o Agent Builder;
se o maestro editar o Onion pela UI, a edição vence (é o dado). E a via Agents API headless não
orquestra MCP (limite do beta) — a vitrine é para a UI.
