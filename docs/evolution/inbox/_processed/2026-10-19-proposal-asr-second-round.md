---
title: 'Proposta da curadoria: transcrição, segunda rodada — o motor selado fica; a passada única reprova; o ao vivo vai para a extensão local'
date: 2026-10-19
from: onion-curation
to: onion-evolve (core)
type: proposal
issue: SAC-177 (Linear, filha da SAC-157); SAC-179 em curso
kg: docs/evolution/research/meeting-capture-2026-10/meeting-capture-2026-10.kg.yaml
decision_node: C_MC_ASR2_RECOMMEND (open; o core sela)
---

# Transcrição, segunda rodada: o que medimos e o que propomos

No selo da SAC-167, o core deixou com a curadoria a passada única de transcrição e diarização do NeMo-Speech.cpp. O
maestro pediu também os candidatos de transcrição mais novos, buscados por trajetória e não pelo nome da família.
Tudo está no grafo do `kg:` (PR #53, merge 2565e1f).
- **Pré-registro:** `ASR2-PROTOCOL.md@f886c85`.
- **Emenda 1:** `c113d23`, commitada depois do Elenxo e antes dos dados que governa.

## Resposta curta
**Manter o motor selado (Parakeet int8 pelo adaptador, com VAD). Não adotar a passada única. O ao vivo segue com N = 0
na VPS e vai para a extensão local (SAC-179).**

| Braço | Trechos de conversa (N, 300) | Reunião inteira, mesmo VAD (10 gravações) | RTF |
|---|---|---|---|
| **P8: Parakeet v3 int8, onnx-asr (o selado)** | 24,8 % | **29,2 %** | 0,081 com VAD |
| PG: Parakeet v3 pelo NeMo-Speech.cpp | **19,7 %** (vence pela regra) | 30,1 %, e troca para o inglês (103 palavras do inglês por mil numa gravação) | 0,213 com VAD |
| N35: Nemotron 3.5 ASR, em trechos e offline | 27,5 % | — | 0,30 |
| QW: Qwen3-ASR 1.7B | — | — | ≥ 1,11 (cortado) |
| CO: Cohere Transcribe | — | — | exige token (fora) |
| J1: passada única (ASR + diarização) | — | DER 49,9 % (teto 11,5) | 0,395 (teto 0,165): reprova |

- **O que a regra pré-registrada apontou:** o PG, porque erra 5 pontos a menos em trechos curtos.
- **Por que a recomendação é outra:** o Elenxo mostrou que o PG em arquivo inteiro troca de língua (3 de 10 gravações).
  A superação B, que dá o mesmo VAD aos dois em reunião inteira, reprova o PG em erro e em estabilidade de língua. A
  recomendação de manter o selado sai da medição, não de opinião.
- **Capacidade da VPS:** cerca de 297 h de áudio por dia com o P8, contra cerca de 113 h com o PG.
- **A passada única** reprova pelo custo, e a diarização dela fica muito abaixo do Nemotron-3 sozinho (9,5 %).

## Extensão local (SAC-179, em curso, não é pedido de selo)
A extensão de bancada, rodada no Windows do maestro (i7-11800H, RTX 3060), mostrou até agora:
- a **tradução local do Chrome** responde em ~21 ms por frase (chrF 82 pt→en);
- o **Parakeet só na CPU** acerta como a VPS em conversa (15,5 %), mas com RTF 0,94, o que não é viável ao vivo;
- a **WebGPU foi negada pelo Chrome** em todos os contextos, mesmo com o `chrome://gpu` dizendo "acelerado". A suspeita
  é o driver Intel de 2021 num Windows Insider. A correção está com o maestro.

Lição para o produto: a extensão precisa detectar a falta de GPU, cair para a CPU e orientar o usuário.

## O que NÃO foi medido
- A eficácia do QW em conversa: o corte por custo foi mantido pelo maestro.
- O Cohere, que exige token.
- Áudio real do Meet e do Teams.
- GPU na VPS.
- Ao vivo com N correntes pelo adaptador.
- O perfil de GPU da extensão.

## Mercado e capital
- **Régua paga:** de US$ 0,15 a 0,31 por hora (AssemblyAI, Deepgram; preços primários de 2026-10-18).
- **Na VPS:** custo marginal de CPU, numa máquina já paga. Não abre bilhetagem própria.
- **No ao vivo:** Meet e Teams cobram a tradução em planos de US$ 10 a 14 por usuário por mês, e as extensões de
  US$ 12 a 79 por mês. O diferencial possível de uma extensão local é o áudio não sair da máquina.

## Peça ao core
Selar `C_MC_ASR2_RECOMMEND`: manter o motor e não adotar a passada única, ou divergir com a razão.
