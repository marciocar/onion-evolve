---
branch: docs/merge-verified-rebase-gap
pr: 646
date: 2026-08-21
reviewed_diff_sha256: d3b28cfb97529cc62ad66e7515d71244da7c2d711a8ce6abfe603531881c8117
findings_total: 2
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: CONFORME-CURA-NO-MESMO-LOOP-GATES-INTACTOS
reviewer: passada adversarial manual (o fallback afrouxa gate?) + dogfood: o helper curado merge ESTE PR; sem subagentes
REVISOU: true
---

# Resíduo — `docs/merge-verified-rebase-gap`

**Origem:** o próprio #645 recusado pelo helper (--rebase em stack re-apontada) — o gap virou
migalha E cura no mesmo commit.

## O ataque que importa — o fallback afrouxa algum gate?

Não. A ordem do script é: (1) checks head-pinned + `há check FALHO/PENDENTE → die`; (2)
`onion-review-verdict` lido da fonte + `!= SUCCESS → die`; (3) SÓ ENTÃO o `gh pr merge`, e o
fallback --squash está DENTRO do passo 3 — depois de todos os gates. O squash muda como o
histórico entra, não SE os gates passaram. O grep confirma: die's de gate vêm ANTES da linha
do merge.

## Ataque 2 (limpo)

O `grep -qi "can't be rebased"` só degrada nessa string exata — qualquer outra falha do
`gh pr merge` (conflito, permissão) cai no `die` normal, sem fallback. Não é um catch-all que
mascara falha real.

## Dogfood declarado

Este PR é o PRIMEIRO que o helper curado vai mergear. Se ele mesmo precisar do fallback (não
precisa — não é stack), o teste seria circular; como não é stack, mergeia por --rebase normal,
e a cura fica provada pelo #645 que a originou (mergeado por squash à mão, o que a cura agora
automatiza).

## Ressalva

O SyntaxWarning do python no terminal foi do meu heredoc de edição (escape em regex de exemplo),
não do código do helper — o helper é bash, e `bash -n` passou limpo.
