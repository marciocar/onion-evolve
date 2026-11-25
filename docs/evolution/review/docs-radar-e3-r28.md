---
branch: docs/radar-e3-r28
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 0
tokens: 315324
duration_min: 18
findings_fixed: 9
verdict: FIXED
elenxo: true
reviewer: "subagente general-purpose opus independente (não-fork, sem nome), mandato REFUTAR, effort high"
nota: "tokens = o juiz e a sonda do agent_id. Os 9 achados são os 6 EXAGERA (aplicados com as 6 superações) e as 3 omissões medidas que viraram nó (deny perdido em bypass com comando longo, crase em heredoc, deriva do cited-directive). Nenhum código de produção mudou: o diff é o grafo, os dados e as sondas da rodada, a SYNTHESIS, o selo do eixo E3 e as projeções."
---

# Passada adversarial: `docs/radar-e3-r28`

## O que muda

A rodada 28 do radar do Claude Code (2.1.331 e 2.1.332), as três sondas da rodada em `data/` e o selo da baseline do eixo E3.

## Achados

Os vereditos estão em `docs/evolution/research/radar-E3-2026-11-25-r28/data/judge-verdicts.json`. O resultado foi 9 SUSTENTA, 6 EXAGERA e 0 REPROVA. O `judge-verdict-check.sh` saiu rc 0, com 6 superações e 0 recusados.

- **Os 6 EXAGERA** foram reescritos nos nós. Cada um tem a superação correspondente (`C_SUPERACAO_20261125_*`):
  - deny lento medido só em default;
  - deny da diretiva só curta;
  - 4 hooks sem timeout;
  - contagem de diretivas;
  - campo `agent_id` do colega de time;
  - SAC-432 não comentada. Agora está comentada e com o título corrigido.
- **Omissão de impacto alto: o deny da casa se perde em bypass acima de ~10 mil caracteres.** A rodada o confirmou de forma independente com `data/probe-deny-bypass-long.py`, e ele virou nó e a issue SAC-551.
- **Omissão: a crase em heredoc sem aspas passa pelo deny.** Ela já causou um push acidental do juiz para o origin do core (branch `feat/dir`, mesmo sha da main), avisado à sessão líder. Virou nó e entrou na SAC-551.
- **Omissão: a deriva do cited-directive** segue igual na 2.1.332. Virou nó.

## Mutantes

Não se aplica: nenhuma guarda nem código de produção mudou. As três sondas em `data/` são instrumentos de medida da rodada, e não guardas. As guardas propostas (SAC-551, SAC-552) nascem com bancada e mutante na leva delas.

## Limites declarados

- O Code Mode segue desligado neste host, e a sessão interativa não foi medida no caso do comando longo.
- O que ficou sem medida está em NÃO-VERIFICADOS na SYNTHESIS.
- O branch `feat/dir` segue no origin até alguém com o push removê-lo.
