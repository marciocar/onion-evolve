---
branch: docs/diary-review-2026-10-20
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 2a1933c79b86377b2beccab6e8cf17bec4c860ed17dd008bb49db240ba7c42e3
reviewed_code_sha256: fdd91222d9f2a1064a2e556a86a03b9fccdbf7a71b374e4b3785e1a5ebafa4ac
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 10
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão; 3 migalhas sorteadas por shuf e re-conferidas contra o vivo; sem subagentes
nota: ""
---

# Passada adversarial: `docs/diary-review-2026-10-20`

## O que muda

Re-teste do diário pelo protocolo `/meta:diary review`, autorizado pelo maestro em `/meta:decide` (2026-10-20).
São 35 migalhas vencidas: as 25 reais da tabela de 2026-10-19 e mais 10 que venceram em 2026-10-19. O placar
é 21 VÁLIDAS, 1 INVÁLIDA e 13 PARCIAIS. As 2 já marcadas `superseded` ficaram intocadas. Há também duas
correções laterais: uma nota de correção no re-teste de 08-17 da `marathon-close` ("Trilha-no-KG EXISTE" é
falso no vivo) e o ADR do runtime autônomo, que em l.5, l.48 e l.100 dizia "AUTOMATE segue GATED" (o degrau
foi forjado no PR #1107, em 2026-10-14). O índice foi regenerado.

## Sorteio

`shuf -n 3` sobre os arquivos do diário tocados:

1. `2026-07-18-autonomous-thread-runtime-graduated-ladder` (PARCIAL)
2. `2026-07-18-perception-instruments-doctrine` (VÁLIDA)
3. `2026-07-19-onion-is-the-hero-platform-is-base` (VÁLIDA)

## Achados

1. **REAL, curado (perception-instruments):** a evidência dizia só "0 nós `layer: domain` em
   `perception-instruments-2026-07.kg.yaml`". Isso é estreito demais para sustentar que o `next_recommended`
   segue aberto, porque o instrumento poderia ter nascido em outro grafo. Medi o repo inteiro: não existe
   `instrumentos.kg.yaml`, e os dois grafos com `layer: domain` (`technical-context-core`, `colaboracao-onion`)
   modelam subsistemas e entidades, não um nó por CHECK. O veredito se mantém, e a evidência foi ampliada.
2. **REAL, curado (onion-is-the-hero):** o `next_recommended` manda auditar os READMEs **da família** e os
   case-studies do hub, mas a medição só olhou este repo. O texto agora declara o escopo: só o core foi medido,
   as portas e o hub não.
3. **Confirmado sem achado (autonomous):** `drive.md` l.20-23, `drive-automate.sh` l.111-122 (allowlist) e
   l.25/l.32 (`--merge` desligado por padrão), e o PR #1107 (`68c20c2a`, 2026-10-14) batem com o texto.

## Mutantes

Não se aplica. A mudança é de prosa e frontmatter do diário e de um ADR, sem código executável. O gate é o
`diary-index.sh` (128 entradas, 0 stale) e o lint.

## Re-revisão depois do rebase (2026-10-20, sessão principal)

O PR foi rebaseado sobre a `main`, que tinha recebido o #1217. O hash de código mudou por isso: a base trouxe
código, mas o diff deste PR não mudou de natureza. A única mudança nossa é uma linha na migalha
`dogfood-que-refutou`, que agora registra o #1217 como mergeado (03:11 UTC) e o `D_build_none_of_three` como
`superseded` na `main`. Conferido na `main`: o nó está `superseded`. Sem achado novo.
