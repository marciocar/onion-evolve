---
branch: fix/vendored-broken-links
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 20
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: agente de execução (sem revisor isolado)
nota: "correção de 4 links; guarda nova não implementada (card no relatório); tokens/revisor não medidos"
---

# Passada adversarial: `fix/vendored-broken-links`

> Preencha o frontmatter: os campos numéricos são números (0 = não medido, dito em `nota:`); `verdict` é um
> de: APPROVED FIXED REJECTED REJECTED_AND_FIXED NO_FINDINGS; `elenxo` é true ou false. `reviewed_diff_sha256: pendente` fica: o pr-finalize carimba.
> `findings_blocking` = quantos dos reais BLOQUEIAM (0 ≤ blocking ≤ real); o resto é LIMITE e vai em
> `## Limites declarados`. Aqui 0 quer dizer "nenhum bloqueia": se a passada não triou, APAGUE a linha
> (ausente = não triado). Régua: `.claude/commands/common/prompts/review-triage.md`.
> Confira com `bash .claude/validation/review-artifact-check.sh --schema <este arquivo>`. Apague este bloco.

## O que muda

Quatro links quebrados que viajam ao adotante: `baton-doctrine.md` (2x, `../meta/` vira `../../meta/`; o `/meta:baton` viaja ao hub), `docs/README.md` l.28 (saídas geradas viram caminho em código) e a âncora de `onion-framework-identity.md` l.82 (título real: `SSOT-as-runtime — o KG é o primeiro ato (a ESCRITA é mecanismo; a LEITURA ainda é conselho)`).

## Achados

Nenhum: revisão isolada não feita; mudança só de texto de link.

## Mutantes

Não se aplica: sem guarda nova.

## Limites declarados

- Sem guarda mecânica nova: o `kb-vendored-link-check.sh` só cobre KB e alvo core-privado, não link relativo quebrado em `.claude/`.
