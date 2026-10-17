---
title: 'Proposta da curadoria: captura com Windows como cliente e VPS como servidor — capturar no Windows, transcrever em LOTE na VPS com Parakeet int8'
date: 2026-10-17
from: onion-curation
to: onion-evolve (core)
type: proposal
issue: SAC-164 (Linear, filha da SAC-157)
answers: Q_CAPTURA_WINDOWS_CLIENTE_VPS_SERVIDOR_1016
kg: docs/evolution/research/meeting-capture-2026-10/meeting-capture-2026-10.kg.yaml
decision_node: C_MC_WINDOWS_VPS_PATH (open; o core sela)
---

# Windows como cliente e VPS como servidor: o que medimos e o que propomos

O core pediu, em 2026-10-16, a pesquisa do caminho com a máquina do maestro em Windows e uma VPS Linux como servidor.
A resposta literal do maestro está no seu `Q_CAPTURA_WINDOWS_CLIENTE_VPS_SERVIDOR_1016`. Tudo abaixo está no grafo do
`kg:`, no repo da curadoria (PR #48).
- O protocolo foi pré-registrado em `VPS-STT-PROTOCOL.md@c414c60`, com as emendas 1 (`e409fb8`) e 2 (`7616c2f`),
  cada uma commitada antes de rodar.
- A sessão desta curadoria roda na própria VPS (8 vCPU, 31 GiB, sem GPU), então "medido na VPS" é literal.
- Seguindo o pedido do maestro, os pacotes estavam na última versão do PyPI, e o ffmpeg foi instalado com a
  autorização dele.

## Resposta curta
**Capturar no Windows e transcrever na VPS em LOTE, ao fim da reunião, com o Parakeet v3 em int8.** Uma reunião de
1 h sai em cerca de 7 min. Ao vivo, a VPS sem GPU não aguenta pela regra; fica para depois de corrigir o VAD e medir
de novo, ou para uma GPU.

## 1. Captura no Windows (`E_MC_WIN_CAPTURE_READ`, leitura de código no pin, conferida)
- **Meet no navegador: a extensão da Vexa no Chrome ou no Edge.**
  - O endereço do ingest aceita override na UI, então ela aponta para a VPS.
  - Faltam: proxy TLS (`wss`), auth por token (o host não autentica nada e escuta em todas as interfaces), o host da
    VPS em `host_permissions` e CORS restrito.
  - Instala-se em modo desenvolvedor, porque não está na Web Store.
  - Banda: cerca de 512 kbps por canal ativo.
- **App do Teams: o anarlog no Windows.**
  - Tem instalador (v1.4.30), capta o sistema por WASAPI loopback e o microfone, e o `meetings export` existe no
    Windows.
  - O aviso no chat não sai no Windows, o que casa com o selo de vocês (aviso pt-BR nosso, envio dele desligado).
  - O provedor `custom` aponta para a VPS.
  - Pela extensão, o Teams perde o microfone local (Vexa #1789, PR #1790, ambos abertos): a voz do próprio maestro
    some.
- **Alternativa fina, se as duas falharem:** cliente próprio com dois fluxos, o mic como "eu" e o loopback como
  "outros" (PyAudioWPatch, ou o crate `wasapi` que o anarlog usa).

## 2. O motor, nas versões atuais (`E_MC_ENGINE_AMENDMENT1`)

| Motor (30 falas pt-BR, CPU, 3 repetições) | WER | RTF | RSS |
|---|---|---|---|
| **Parakeet v3 int8** | **4,86 %** | **0,085** | 1,64 GiB |
| Canary-1b-v2 int8 | 5,08 % | 0,26 | 2,26 GiB |
| Parakeet v3 fp32 | 5,19 % | 0,13 | 2,73 GiB |
| Canary-1b-v2 fp32 | 5,41 % | 0,40 | 4,93 GiB |

- Os quatro cabem na VPS, e o Parakeet int8 vence. O Canary, mais novo, perde nos dois pesos.
- As diferenças de WER não têm significância; a escolha vem do RTF.

## 3. O servidor (o adaptador, construído porque não havia pronto)
- Nenhum servidor aberto serve o Parakeet nos dois protocolos com palavras e tempos. O speaches e o achetronic perdem
  as palavras.
- O adaptador é um processo Python sobre o `onnx-asr`, com três rotas:
  - `POST /v1/audio/transcriptions` (OpenAI, como a Vexa chama);
  - `WS /v1/listen` (Deepgram ao vivo);
  - `POST /v1/listen` (Deepgram em lote, como o lote do anarlog chama).
- Código, testes de forma e bancada em `data/vps-stt/` no repo da curadoria.
- **Ao vivo** (`E_MC_VPS_SERVER_MEASURED`): capacidade N = 0 pela regra.
  - Reprova no pareamento, porque o corte por VAD muda 3 a 5 falas longas. A sonda sem corte dá 30/30, então no L1
    é configuração do adaptador, não limite do motor.
  - N = 1 é marginal em latência, e N ≥ 2 satura.
  - Uma reunião com várias pessoas ocupa mais de um stream (a Vexa mantém um buffer por falante).
- **Lote de 1 h** (`E_MC_LONG_BATCH_MEASURED`, arquivo de 61,5 min): **sustentado** pela regra, pelos dois clientes.
  - WER de 6,19 %: 1,33 ponto acima do controle, para um limite de 1,5.
  - RTF de 0,092 a 0,118.
  - RSS de 7,41e9 B, para um limite de 8e9.
  - A folga é pequena em WER e em memória. O primeiro ajuste a medir é o `batch_size=1`.
  - O cliente da Vexa tem timeout de 30 s, que é preciso configurar ou cortar no cliente.

## 4. Local contra VPS
- O critério foi pré-registrado: processar local só se o Windows der RTF abaixo de 0,5 e a privacidade pesar mais que
  a central.
- O braço W não rodou, porque a máquina do maestro está fora do alcance. O script está pronto em
  `data/vps-stt/windows_w_arm.py`.
- Pela medição, a VPS já resolve em lote, e o Windows só precisa capturar.

## 5. Mercado e quem paga
- A VPS já é paga pelo maestro (o preço do plano não foi verificado); o custo marginal por reunião é CPU.
- A régua paga:
  - Deepgram Nova-3 multilíngue pré-gravado a US$0,0052/min, cerca de US$0,31/h (deepgram.com/pricing,
    2026-10-17);
  - Recall.ai a US$0,50/h, mais US$0,15/h de transcrição.
- Não abre bilhetagem própria. O valor está no grafo da reunião, que nenhuma delas entrega.

## 6. O que o core decide
1. **Selar o caminho** `C_MC_WINDOWS_VPS_PATH` (recomendado): captura no Windows (anarlog para o app do Teams, extensão
   para o Meet), lote na VPS com o Parakeet int8, aviso pt-BR e respostas pelo `meeting-graph-check.sh` de vocês.
2. **Onde mora o adaptador:** é código novo e não é da curadoria. Ele pode virar peça do core (absorver por reescrita,
   com bancada), ou serviço operado no host do maestro. Ele toca a VPS servida, então o deploy é do maestro (MOAT).
3. **Diarização:** sem ela o grafo só tem "eu × outros", e no anarlog é por canal. O pyannote community-1 exige token
   do Hugging Face; o `sherpa-onnx` com a segmentação pyannote 3.0 não exige, mas o DER em pt-BR não foi medido. Uma
   rodada própria pode ser pedida.

## Não medido (lista de 1ª classe)
- O Windows real (o braço W).
- Reunião real.
- A rede do maestro.
- TLS e auth.
- Os clientes reais (simulados a partir do código).
- O L2 com outro VAD.
- Workers múltiplos.
- Diarização.
- GPU.
- O modo só-gravação da extensão.

Orquestrado com 🧅 Onion Evolve
