---
branch: chore/waha-scope-seals-1108
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: false
reviewer: passada própria do agente de execução sobre o próprio diff, sem subagente (o brief proíbe criar agentes); gates mecânicos kg-radar e kg-contract-check, grep do nome comercial nos arquivos novos
nota: "tokens e duração não medidos (0). Dois selos, três perguntas abertas com espelho no Linear e um anúncio; sem código."
---

# Passada adversarial: `chore/waha-scope-seals-1108`

## O que muda

- `docs/onion/graph/maestro-decisions-1108.kg.yaml`: os selos do escopo e dos riscos do WAHA, três perguntas abertas
  (uma por risco) e duas arestas externas. O teto declarado sobe de 10 para 15, com o motivo no `meta:`.
- `docs/evolution/federation/outbox/brain-granaai/2026-11-08-resposta-waha-grupos-de-parceiros.md`: anúncio ao hub.

## Achados

1. VAZAMENTO EVITADO (corrigido antes do commit): o `to:` dos anúncios dessa pasta traz o id do membro, que carrega o
   nome comercial. O core é público e o brief veda o nome nos arquivos novos; o campo diz «hub». A pasta já está no
   caminho e não muda aqui.
2. PROVENIÊNCIA INCOMPLETA (corrigido antes do commit): o selador grava uma única origem, e a decisão de escopo tem
   três (opções, resposta livre, «Concordo»). As três foram acrescentadas à narrative do nó.

## O que fica de fora, por decisão

- Sem `x_due` nas perguntas: prazo sai de pontos e histórico, que ainda não existem. O título no Linear diz «prazo a calibrar».
- O dono das três perguntas ficou `core`, porque o brief pede dono sem nomear.
- A entrega do anúncio é do líder; sem `co-deliver`.
- O texto da pergunta do nó de riscos foi redigido pelo agente de execução.

## Re-revisão do delta (acréscimo ao escopo do WAHA e selo do sandbox)

Li o delta inteiro. O nó do escopo passa a dizer «só uso interno, só leitura e encaminhamento, sem envio» no label, na
narrative e no `verified_against`, e o anúncio acompanha; a proveniência ganha a confirmação direta na sessão da curadoria.
`D_MD_SANDBOX_CURATION_WITH_LIMIT_1108` traz no label o que cabe nos 280 caracteres e, na narrative, os cinco termos da
escolha, incluindo a cura do `ops/sync-main-worktree.sh`. `Q_SANDBOX_DENY_LAYER_DECISION_1108` fecha pelo selador e cita
o selo por caminho no `verified_against`; há aresta externa do selo para ela. Radar e contrato em rc 0 nos dois grafos.
Sem achado novo.

O sinal da curadoria não entra neste PR: a triagem é do líder. O grafo cita os nós da curadoria pelo id, porque a aresta
externa do contrato só alcança grafo do mesmo repositório.

O dono de `Q_MD_SETTINGS_UPDATE_UNDER_SANDBOX_1108` ficou `curadoria`, porque o sandbox só existe lá; o brief não nomeou.
