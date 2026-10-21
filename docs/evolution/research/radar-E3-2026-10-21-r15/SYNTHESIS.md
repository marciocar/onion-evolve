---
title: Radar E3 r15 — o delta do Claude Code 2.1.307 contra o Onion
date: 2026-10-21
kg: docs/evolution/research/radar-E3-2026-10-21-r15/radar-E3-2026-10-21-r15.kg.yaml
run_id: "nenhum (rodada conduzida pela sessão, sem Workflow; o juiz é um subagente avulso)"
tokens: 160960
agents: 1
duration_min: 30
review_after: 2026-11-20
type: research
mode: cc-update
---

> **Projeção do grafo, nunca fonte.** O custo cobre só o juiz.

## O que mediu

A rodada mediu 1 versão, a 2.1.307, com 43 itens. A cópia do CHANGELOG bate byte a byte com a fonte. O host
e o revisor do CI estão na 2.1.307 (pin v1.0.257, #1275). O /chat segue na 2.1.306 (SDK 0.3.306): o PR do SDK
0.3.307 ainda não está no forge.

## O que toca a casa

- **Teto do WebSearch × memória do fallback de busca → SAC-185.** O juiz leu o aviso no **binário** de cada
  versão: o anti-contorno ("não consulte buscadores com curl ou wget, nem por leitor ou proxy de terceiros")
  existe desde a 2.1.304. A 2.1.307 só acrescenta o navegador e o computer use, e nenhuma versão nomeia o
  WebFetch. A memória `search-is-sdaal-fallback-when-capped` receita WebFetch sobre buscador no teto, o que
  contraria o espírito do aviso. A KB já cumpre o aviso. Decisão do maestro: revogar, restringir ou manter a
  memória.
- **SDK do bridge, 1 versão atrás:** o ganho que toca a casa é o fork de subagentes lançados juntos, que no
  host já vale.
- **Sinais fracos:**
  - o painel do decide lê pelo ArtifactData, não pela leitura do Artifact que a 2.1.307 conserta;
  - o servidor MCP do SDK não tem consumidor (REPROVA: o piloto `ui://` não escolheu a forma do servidor);
  - o defeito do transcript de subagente (tokens de placeholder em 41% das linhas na 2.1.306, 0% na 2.1.307)
    é real na casa, mas nada o lê.

## Juiz

Subagente opus/high, pedido pela sessão (modelo declarado). Deu 11 vereditos: 7 SUSTENTA, 3 EXAGERA e
1 REPROVA. Encontrou 8 omissões, nenhuma com impacto 2 medido. Achou 2 superações, que viraram os nós
`C_SUPERACAO_20261021_*`. Na Aufhebung, 3 nós da r14 foram superados: o pin do revisor, a pergunta de prova
presa ao v1.0.256 e o "/chat igual ao host".

## NÃO-VERIFICADOS

- se o conserto da leitura do Artifact cobre o transporte do ArtifactData;
- de onde o Workflow tira o `totalTokens`;
- se o aviso de parada por app conectado casa a regex da sonda de tarefas de fundo;
- a descontinuação da API `2023-06-01`.
