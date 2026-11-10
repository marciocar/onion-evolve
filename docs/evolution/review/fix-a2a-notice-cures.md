---
branch: fix/a2a-notice-cures
date: 2026-11-10
reviewed_diff_sha256: 344b1dc0f0dec10ea81f9e62c514725533288e38929c19fe2e89184cee591299
reviewed_code_sha256: 2b48e981749a6d407ba27fc138ce02cd38ae6490c99c08c6bebeb0f8bd7c6f1e
findings_total: 3
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 10
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "revisão adversarial independente, conduzida pela sessão do core sobre o PR #1571, mais a passada própria do autor; gate mecânico: bancada a2a_rt e a2a_accept, kg-radar, contrato e selador"
nota: "a revisão independente deu REJECTED leve por um defeito: o locator de D_QUEUE_HARVEST_OPENCLAW_NOW_1110 citava uma pergunta que não foi feita. Curado num commit novo com a pergunta literal. Código, bancada (288/0) e o nó do iroh open aprovados. A passada própria achou 1 defeito real (curado) e 1 cosmético (declarado)."
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

## Achado 3, da revisão independente: o locator citava uma pergunta que não foi feita (REAL, curado)

O brief não trazia a pergunta de `D_QUEUE_HARVEST_OPENCLAW_NOW_1110`, e a 1ª redação a reconstruiu a partir das
opções («Colher agora as ideias do OpenClaw para a fila A2A, ou junto da Fase 2?»). O selo citava, como prova,
uma pergunta que o maestro nunca viu. Curado num commit novo: o locator traz a pergunta literal, e o label foi
alinhado a ela (as três regras do OpenClaw entram já no onion-queue, com teste de mutante). Escolhida «Sim, já»
e rejeitada «Junto da Fase 2» não mudam. Radar 0, contrato verde.

## O que não foi medido

- O «quando» do «já aceito» vem do mtime do doc: um clone novo zera o mtime, e o rótulo da fonte vai na saída.
  Doc fora do inbox dá «não medido»: o razão não guarda o instante.
- As duas primárias do grafo (cross-session-messaging e mcp) não foram relidas por esta sessão; vêm do brief. O
  pino 1.32.2 do SDK no doorbell foi lido no `package.json`.
- Reaberto num commit novo (sem reescrever histórico): `D_A2A_OUTBOUND_IROH_PHASE2_1110` tinha sido selada
  com «Fase 2 só com iroh»; o maestro pediu a revisão das estimativas antes do selo. O nó volta a `open`, com as
  três opções nomeadas e sem escolha. Re-revisado: só o grafo mudou; radar 0 e contrato verdes.
