---
branch: fix/a2a-notice-cures
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: FIXED
elenxo: false
reviewer: "passada própria sobre o próprio diff, sem subagente (o brief proibiu criar agentes); gate mecânico: bancada a2a_rt e a2a_accept, kg-radar e selador"
nota: "elenxo false: não houve leitor independente. A bancada prova cada cura com caso e mutante; a passada própria achou 1 defeito real (curado) e 1 cosmético (declarado)."
---

# Avisos do A2A que dizem o próximo passo

Quatro curas do atrito da ida e volta A2A VPS↔notebook de 2026-11-09 (cerca de 8 atos manuais e 22 min), cada
uma com caso e mutante na bancada (`run_a2a_rt_selftests`, `run_a2a_accept_selftests`), mais o grafo
`docs/onion/graph/a2a-outbound-2026-11.kg.yaml` com duas decisões do maestro seladas pelo `kg-decide-seal.sh`.

## Achado 1: o «aceito →» apontava o razão mesmo quando ele não foi gravado (REAL, curado)

A 1ª redação imprimia `aceito → <doc> · razão <arquivo>` incondicionalmente. Quando o `printf >> razão` falha, o
script já avisa «o razão de aceites não foi gravado», e a linha final contradizia o aviso. Curado: a nota do razão
nasce do resultado da escrita (`razão NÃO gravado (<arquivo>)` na falha).

## Achado 2: dois iat na saída do envio (cosmético, não curado)

A linha `gravado no outbox` já trazia `iat` do relógio local (`MS`), e a nova linha do prazo usa o `iat` do
payload assinado. Podem diferir em 1 s. O prazo vale pelo assinado, que é o que a retirada confere; a linha
antiga fica como está para não mudar a forma que outras leituras conhecem.

## O que não foi medido

- O «quando» do «já aceito» vem do mtime do doc: um clone novo zera o mtime, e o rótulo da fonte vai na saída.
  Doc fora do inbox dá «não medido»: o razão não guarda o instante.
- As duas primárias do grafo (cross-session-messaging e mcp) não foram relidas por esta sessão; vêm do brief. O
  pino 1.32.2 do SDK no doorbell foi lido no `package.json`.
- Reaberto num commit novo (sem reescrever histórico): `D_A2A_OUTBOUND_IROH_PHASE2_1110` tinha sido selada
  com «Fase 2 só com iroh»; o maestro pediu a revisão das estimativas antes do selo. O nó volta a `open`, com as
  três opções nomeadas e sem escolha. Re-revisado: só o grafo mudou; radar 0 e contrato verdes.
- A pergunta da decisão `D_QUEUE_HARVEST_OPENCLAW_NOW_1110` foi redigida a partir das opções do brief, que não
  trazia o texto exato dela.
