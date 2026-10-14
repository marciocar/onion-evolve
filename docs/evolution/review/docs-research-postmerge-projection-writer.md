---
title: 'Resíduo — o Passo B empacotado: grafo de 103 nós, o dogfood T1–T6 do B1, dois selos do maestro e um delegado'
date: 2026-10-14
branch: docs/research-postmerge-projection-writer
reviewed_diff_sha256: f92898f1661b92047e0a1bd9fb8b484d10416780d4966fc81f9e63105b12efed
reviewed_code_sha256: 4adb049f7661fb82ffacd69b01ec8fdd2364fc8353d42022cc837d79b9bc4ca5
findings_total: 6
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 70
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Passada adversarial do próprio autor, com medição e sem revisor independente (declarado). O diff
  traz o grafo das duas rodadas (wf_e26bb266-4aa e wf_6babcd2c-1d8), dois selos do /meta:decide
  gravados pelo kg-decide-seal.sh (rc 0 nos dois), três nós novos e o teto subido de 93 para 96 com
  motivo, além da SYNTHESIS.md e do docs/backlog.md regenerado. Na 2ª leva, a pedido da sessão principal:
  6 nós E_DOGFOOD_B1_* (T1–T6 medidos no sandbox), 3 Q_B1_* superseded por aresta e o selo DELEGADO
  D_B1_GATED_VARIANTE_CHECKRUN_REGISTRADA (kg-decide-seal.sh --new, rc 0), com teto 96 → 103.
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

5. **REAL e CURADO (2ª leva).** O label do selo delegado, como foi repassado, tinha 492 caracteres, e
   o selador recusou com rc 2, sem escrever nada. Encurtei o label para 267 caracteres e pus o texto
   inteiro na narrative do nó, junto com a delegação e o caminho do log de decisões.
6. **NÃO É DEFEITO (declarado).** O `kg-decide-seal.sh` grava `verified_against`/`provenance` como
   "decisão do maestro". Num selo delegado, isso esconderia a delegação. Por isso editei os dois campos
   depois do selo, para dizer "decisão delegada pelo maestro (autorização noturna de 2026-10-14)". O
   `method: testemunho:` ficou intacto, porque é a forma que o contrato reconhece. Rodei de novo o
   radar e o contrato: os dois verdes. **O log citado (`docs/evolution/decisions-delegated-2026-10-14.md`)
   NÃO está neste PR:** vive no checkout principal e ainda não está rastreado.

## Verificado por execução

- `kg-radar.sh --integrity --schema`: exit 0, com 103 nós e 162 arestas.
- `kg-contract-check.sh`: o grafo está conforme.
- `kg-backlog-check.sh`: OK, 103/103 nós e nenhum `done` sem carimbo.
- `kg-machine-path-check.sh`: 0 acusações.
- `door-leak-scan.sh` sobre o diretório do grafo: nada acusado. O nome do repo sandbox foi omitido de
  propósito, pela REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação).
  As acusações em `docs/backlog.md` já existem no main e não vêm deste diff.
- Fatos do #1101 (MERGED, 2026-10-14T02:11:34Z, merge commit 0139fe2d, s1–s8, 5 de 50 atrás e 3 que
  esperariam o CI): conferidos em `gh pr view 1101`.
- Mensagens verbatim do 403 e da guarda, e os ids de runs e rule-suites de T1–T6: conferidos no relatório
  final do subagente do dogfood. Por amostra, reabri no GitHub: o run 38506709399 deu `success` e o
  38506294705 deu `failure` (os dois `workflow_dispatch` do escritor), e o sandbox é `public`, com
  branch padrão `trunk`. Os outros ids não reabri.

## NÃO verificado

- A bancada inteira não rodou. O diff não toca código nem guarda, só grafo, prosa e projeção.
- Os tokens (5.687.579 e 1.126.300) foram conferidos nos retornos dos runs. Agentes e duração vêm
  do repasse da sessão principal e não foram reabertos no journal.
