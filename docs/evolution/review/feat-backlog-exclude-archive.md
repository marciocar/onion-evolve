---
title: "Revisao adversarial — opt-OUT de arquivo no backlog"
date: 2026-08-23
branch: feat/backlog-exclude-archive
reviewer: "@branch-code-reviewer (passada adversarial, mandato REFUTAR)"
reviewed_diff_sha256: 8cf0db21381d2590c8451960494c7cb14540e8ec6e9977df651cd93c63706b03
findings_total: 7
findings_real: 1
verdict: APROVADO
tokens: 45801
duration_min: 6
---

# Residuo de revisao — REGRA 56

Passada adversarial sobre o opt-OUT `# kg-backlog-archive: on` (backlog 507->188). **7 eixos, 1 achado, CURADO.**

## Verificacoes que passaram (tentei refutar)
- Opt-OUT funciona/nao vaza: escopo 41->40 (so federation-research sai); m2/m3/identity/pricing PERMANECEM; federation-research=0 no backlog.
- Marcador `\b`-escapado: 'online'/'off' nao casam; 'on'/'on #comentario' casam. Sem falso-positivo.
- Radar intacto: --integrity --schema exit 0; federation-research segue no --open-tsv (319) — saiu do BACKLOG, nao do radar.
- Idempotencia: run1==run2==commitado. bash -n limpo; array vazio sob set -u sobrevive (bash 5.2).
- Regressao F4b: opt-in kg-backlog-guard (librechat-kg-runtime) segue no backlog. Lint 0 HARD.

## Achado F1 (baixo) — CURADO
Dois cabecalhos ainda diziam "camada canonica INTEIRA / nada fica invisivel", contradizendo a exclusao — um
mantenedor leria "nada invisivel" e concluiria que nao ha federation-research aberto (ha 319). **Cura:** cabecalho
de escopo agora diz "EXCETO grafos opt-OUT"; o render() troca "nada fica invisivel" por um CONTADOR honesto
("N grafo(s) de arquivo ficam fora — visiveis via kg-radar --open-tsv"). Regenerado, bash -n limpo, lint 0 HARD.

## Veredito
**APROVADO** — mecanismo correto, sem regressao, sem defeito mecanico; F1 (doc-drift) curado neste PR. O backlog
virou superficie de controle limpa (a fila ACIONAVEL: m2/m3/identity/pricing), o arquivo de pesquisa segue no radar.
