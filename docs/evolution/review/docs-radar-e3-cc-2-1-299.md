---
branch: docs/radar-e3-cc-2-1-299
date: 2026-10-14
reviewed_diff_sha256: 87cdfec80b165916ec3191be8f3b0681ab3f1c5a38e32c2ebf54f9325fd0beef
reviewed_code_sha256: 1d79b7a73ea464db1f315e13cd9c095574e5d1b0c61e8c5cf19edc7a9b492632
findings_total: 11
findings_real: 8
findings_fixed: 8
tokens: 157956
duration_min: 35
verdict: REPROVADO_E_CURADO
reviewer: juiz opus/high (subagente não-fork, mandato REFUTAR, default REPROVA), que baixou o CHANGELOG oficial e remediu cada nó no vivo
---

# Radar E3 r10: o delta 2.1.299 contra a maquinaria do core

## Passada adversarial

O juiz julgou 7 nós: 2 sustentam, 3 exageravam (população de hooks PreToolUse contada em 5 e não 6; regra
MCP que o settings não tem; revisor do CI que roda pela Agent SDK, não por `claude -p`) e 2 foram
reprovados (grep cego por construção sem `-z`; migalha do PreCompact que não existe nas branches do core).
Os 5 foram reescritos com a medição dele, conferida aqui (o `case` do hook l.12-13; 0 refs com os prefixos
do GitFlow; o manifesto do bundle l.74-78). Das omissões, 3 de impacto 2 viraram nós; as de impacto 1
estão na seção NÃO-VERIFICADOS da SYNTHESIS. Aufhebung por `x_supersedes_none`, com a deriva da r9 enviada
ao `/meta:kg-freshness` (SAC-119).

## Rodada 1 do CI: a sonda da bancada casava o id real por substring

O caso (c2) da família `backlog_projection` reprovou de forma determinística: ele garante que o grafo-sonda não
rastreado fica fora da projeção procurando `Q_SONDA` por substring, e o nó novo desta rodada,
`Q_SONDAR_O_BUNDLE_ONION_SOB_2_1_299`, entrou no `docs/backlog.md` e casou. Real, curado na bancada (não no
id): o grep passa a `-w`. A família passa; se a sonda entrar na projeção, o id aparece como palavra e o caso
reprova como antes. É a classe "guarda por lista falha pelo vocabulário".
