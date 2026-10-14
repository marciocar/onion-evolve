---
title: 'Resíduo — o Passo B empacotado: grafo de 96 nós, dois selos do maestro e a SYNTHESIS como projeção'
date: 2026-10-14
branch: docs/research-postmerge-projection-writer
reviewed_diff_sha256: d5e16f59e8cb9c34d80a653191eaabcbf051d11b909a4033ea1a823c5944b0be
reviewed_code_sha256: 55751df56e7403278538ddf537518774a93e0cda76a8a2050ec7eaf3d904797a
findings_total: 4
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 40
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Passada adversarial do próprio autor, com medição e sem revisor independente (declarado). O diff
  traz o grafo das duas rodadas (wf_e26bb266-4aa e wf_6babcd2c-1d8), dois selos do /meta:decide
  gravados pelo kg-decide-seal.sh (rc 0 nos dois), três nós novos e o teto subido de 93 para 96 com
  motivo, além da SYNTHESIS.md e do docs/backlog.md regenerado.
---

# Resíduo — `docs/research-postmerge-projection-writer`

## Achados da passada

1. **REAL e CURADO.** O label do nó de evidência do dogfood passava do teto: 284 caracteres contra
   280. Medi com `len()` sobre os labels e encurtei o texto.
2. **REAL e CURADO.** A §6 da SYNTHESIS saiu com um rascunho de cálculo no meio da frase («105 nós
   contando o teto antigo de 64 + 0? não»). Era prosa que afirmava um número errado de nós por rodada.
   Reescrevi a seção a partir do comentário do teto no `meta:` (64 + 29).
3. **REAL e CURADO.** O comentário do `meta:` dizia «ESTE GRAFO NÃO SELA NADA. D_ fica OPEN», e isso
   ficou falso depois dos selos. Mantive a linha antiga, porque é história, e acrescentei logo abaixo o
   registro datado dos dois selos.
4. **NÃO É DEFEITO (declarado).** O label de `Q_B1_GREEN_SHA_FF_NEEDS_DOGFOOD` ainda diz «PROPOSTA
   (não selo)», embora o nó esteja `done`. É o comportamento do selador: o label fica intacto e o selo
   vai para a narrative, o `verified_against` e a `provenance`. Não editei à mão para não mexer na
   escrita determinística do selo.

## Verificado por execução

- `kg-radar.sh --integrity --schema`: exit 0, com 96 nós e 147 arestas.
- `kg-contract-check.sh`: o grafo está conforme.
- `kg-backlog-check.sh`: OK, 96/96 nós e nenhum `done` sem carimbo.
- `kg-machine-path-check.sh`: 0 acusações.
- `door-leak-scan.sh` sobre o diretório do grafo: nada acusado. O nome do repo sandbox foi omitido de
  propósito, pela REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação).
  As acusações em `docs/backlog.md` já existem no main e não vêm deste diff.
- Fatos do #1101 (MERGED, 2026-10-14T02:11:34Z, merge commit 0139fe2d, s1–s8, 5 de 50 atrás e 3 que
  esperariam o CI): conferidos em `gh pr view 1101`.
- Mensagens verbatim do 403 e da guarda: conferidas no log do subagente do dogfood.

## NÃO verificado

- A bancada inteira não rodou. O diff não toca código nem guarda, só grafo, prosa e projeção.
- Os tokens (5.687.579 e 1.126.300) foram conferidos nos retornos dos runs. Agentes e duração vêm
  do repasse da sessão principal e não foram reabertos no journal.
