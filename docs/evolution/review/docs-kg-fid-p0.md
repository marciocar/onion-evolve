---
branch: docs/kg-fid-p0
pr: TBD
date: 2026-08-15
reviewed_diff_sha256: 6f7512d60cdc5aab2a51ed96cf038ad29e2afbba778d312df69248e63f67fc7c
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 40000
duration_min: 15
verdict: CORRIGIDO
reviewer: Elenxo P0 adversarial (agente dedicado, 9 achados medidos rodando o SDK) + verificação claim→medição
---

# Passada adversarial — `docs/kg-fid-p0`

Carimbo de 1 evidence (impact 5) da fase F-ID.P0. A substância é a contenção no bridge
(commit 43c2c9c, deployado): a sonda PROVOU um convidado lendo o .env de produção, e cada
cura foi verificada por re-sonda comportamental (16 sondas), não declaração. O Elenxo P0
(agente adversarial dedicado) mediu 9 achados rodando o Agent SDK de verdade — 5 já
curados neste diff (deny cirúrgica, settingSources vazio, /proc, git-ceiling duplo, env
filtrado), 2 refutados (env-spread não era regressão; deny NÃO quebra CLAUDE.md), e o
resíduo do vetor Bash declarado (fechado tirando write do convidado; sandbox exige bwrap
que liga fail-open — P0-7). Conferência claim→medição: ENV_BLOQUEADO, core legível,
/proc bloqueado, data/ bloqueado, git-docs 'not a git repository' — todos reproduzíveis.
Radar exit 0.
