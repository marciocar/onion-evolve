---
branch: research/bridge-produto-2026-08
pr: pendente
date: 2026-08-14
reviewed_diff_sha256: c60aba9d30d5b51ef73ef90987aad5cfe74d0fed34553d25f5fc81d6bc15e99e
findings_total: 12
findings_real: 12
findings_fixed: 12
tokens: 71000
duration_min: 12
verdict: CORRIGIDO
reviewer: code-reviewer (opus, adversarial — 10º Elenxo da linha; fidelidade evidência→claim)
---

# Passada adversarial — `research/bridge-produto-2026-08`

## O 10º Elenxo: nós verificados "contra o próprio run" deixaram passar 3 citações falsas

A lei da linha na camada de PESQUISA: o campo `verified_against` dos nós E_* confessava o
defeito (`lente-do-workflow-...`) — verificação contra o run, não contra o vivo. Por ali
passaram: fonte afirmando o CONTRÁRIO do claim (issues de quota do Open WebUI TODAS fechadas,
#1430 em 2024, #23323/#6692 em abr/2026 — e o G1 vendia "gap de 3 anos aberto" como DO), URL
da lente errada no E_PRICING, nó fundindo 2 lentes sob URL que não continha nada do claim
(E_MEMORIA — única inflação de confidence do grafo, 0,75→0,9), anúncio virando fato consumado
(Auto Mode: reação MISTA ao anúncio de 07/08, não backlash uniforme em 14/08).

## Os 12, todos curados

1-2. **ALTA**: DOs #3/#4 sem aresta (violando o próprio ANTI-SALADA) E com evidência vencida →
nós novos E_MULTICONVERSA_TABLE_STAKE + E_QUOTA_GAP_FECHADO_ABRIL_2026 (com a releitura AO VIVO
das 4 issues), quota REBAIXADA a table-stake no posicionamento (continua DO por necessidade de
produto, não como gap do concorrente). 3. E_PRICING → claude.com/pricing. 4. E_MEMORIA → URL
weavai.app (que sustenta 63,8/49,0 = +30% com exatidão) + confidence 0,75. 5. Mem0 US$23,9M
(não 24,5). 6. E_AUTOMODE reescrito (anúncio/efetivo/reação mista; a decisão PR-03b fica de pé
pela triangulação C3). 7. Bullets de contradições VAZIOS no SYNTHESIS (bug do meu gerador:
campo 'signal') → regenerados. 8. E_TETOS truncava palavras → regenerado íntegro. 9. Nós
compostos ganham 2ª fonte/ressalva (HN p/ precedente Office; C2-triangulada-sem-Reddit
propagada como o critic pediu). 10. Refs de nó quebradas no doc → ids completos. 11. "validado
por" → "apoiado por (conf 0,5, vendor sem metodologia; vale pela triangulação)" — o maior DO
não se apoia mais num claim que a própria fonte pede para não citar como fato. 12. plane DEV +
verified_against contra-o-run: os nós corrigidos agora citam a verificação AO VIVO; classe
registrada como lição (verificar-contra-o-vivo na transposição lente→nó).

## O que o ataque não derrubou

Radar 0/0 (0 órfãos, SUPERSEDES consistente) · lint 0 HARD · contador do site 114/114 correto ·
confidence disciplinada em 9/10 · números de mercado exatos contra o vivo (OpenClaw 386.204★,
Mission Control 6.001★, Open WebUI 148.719★) · citações do HN exatas.

## Teto declarado

O changelog do Open WebUI não foi conferido para confirmar SE limites por usuário/grupo foram
entregues (a inferência das issues-fechadas é forte; o nó a declara como a-conferir). Reddit
segue triangulado (crawler bloqueado) — ressalva agora propagada nos nós derivados da C2.
