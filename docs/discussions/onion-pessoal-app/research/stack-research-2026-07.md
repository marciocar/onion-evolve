# Pesquisa de stack — App Onion Pessoal (deep-research, 2026-07-17)

> Fonte: deep-research harness (`wwujc53hz`) — 6 ângulos, 23 fontes, 94 claims extraídos, 25 verificados
> adversarialmente (3 votos/claim), **15 confirmados / 10 refutados**. Fontes datadas ~jul-2026.
> Reprodutível: `docs/discussions/onion-pessoal-app/research/` (este arquivo é o destilado).

## Veredito: **React Native + Expo** (app) + **react-native-executorch / callstack-ai** (SLM on-device)

É o único stack comparado que satisfaz **os 4 requisitos duros** com backing **primário e datado**:

| Requisito | Como o RN+Expo atende | Fonte (primária) | Voto |
|---|---|---|---|
| (1) Câmera/mic/notif/fs first-class | expo-camera (takePicture/recordAsync+RECORD_AUDIO), expo-media-library, expo-notifications — 1 codebase Android+iOS | docs.expo.dev | 3-0 |
| (2) SLM on-device (futuro) | **react-native-executorch** (Meta ExecuTorch): Llama/Phi/Qwen/SmolLM **100% offline**, hooks `useLLM`, Expo-compat, **já em produção** (app "Private Mind"). Piso: iOS 17+/Android 13+, New Arch | docs.swmansion.com | 3-0 |
| (2+) Pipeline de companheiro | RN-executorch cobre **Whisper STT + Kokoro TTS + OCR on-device + photo→VLM**, câmera em tempo real via VisionCamera worklets (v0.8.0, 2026-04-03) | docs.swmansion.com | 3-0 |
| (2 alt) 2º runtime redundante | **callstack/ai** (react-native-ai): llama.cpp/llama.rn (GGUF), MLC-LLM, Apple Foundation Models, compat Vercel AI SDK | github.com/callstackincubator/ai | 3-0 |
| (3) Cliente do backend Agent SDK | `@anthropic-ai/claude-agent-sdk` é **backend-only** (roda o loop no processo Node, npm, precisa API key+fs) → o app é cliente, exatamente como o onion-bridge já faz | code.claude.com | 3-0 |
| (4) Ship rápido solo | Expo **EAS** compila iOS na nuvem (sem Mac); free tier 15+15 builds/mês | docs.expo.dev | 3-0 |

**Runner-up: Capacitor** — plugins oficiais de câmera/fs/notif/background-runner, caminho web→store mais rápido;
**mas sem história madura de SLM on-device** (há um showcase LocalLLM da Ionic, mas não sobreviveu como caminho
verificado; e o plugin de microfone não está no set oficial). Perde no requisito decisivo (2).

**Flutter** — lidera em stars (~168k vs RN ~121k), mas **caminho de SLM on-device não documentado** na evidência
e o roadmap "Gemini Nano" foi **REFUTADO (0-3)**. Popularidade não vira capacidade local-first aqui.

## Honestidade da evidência (o que NÃO confiar)

- **Split de qualidade:** claims de *capacidade* (Expo/Capacitor/SwMansion/Callstack/Anthropic docs) = **primários,
  alta confiança**. Claims de *popularidade/market-share* = **blogs SEO de baixa qualidade** que se ecoam → tratar
  percentuais como faixas indicativas, não números.
- **10 claims REFUTADOS**, todos de adoção/market-share: RN "42%", Flutter "46%", RN "most-used", Capacitor "ship
  3-4 semanas". **Nenhum número de market-share confiável sobreviveu.**
- **Ausentes da evidência** (nenhum claim verificado — não dá pra concluir): **Tauri v2 Mobile, Kotlin Multiplatform,
  nativo puro, PWA/TWA específicos, Google AI Edge/MediaPipe/Gemini Nano, Core ML, ONNX Runtime Mobile standalone.**
- **Caveats técnicos:** SLM on-device = bundle grande + pressão de RAM + throughput dependente de hardware;
  RN-executorch exige New Architecture (iOS 17+/Android 13+); Apple Foundation Models text-gen precisa iOS 26+.

## Encaixe com a arquitetura Onion (por que esse stack é o certo, não só o popular)

- **Cérebro (nuvem):** o **onion-bridge** já existe (Node + Hono + `@anthropic-ai/claude-agent-sdk`, cwd = clone do
  core). O app RN é **cliente** dele. Troca-se o frontend PWA por app Expo/RN; o backend fica.
- **SLM on-device = o adapter SDAAL `de-identification/local-slm`.** O "SLM futuro" que o Marcio pediu **é exatamente**
  a "segunda runtime" da tese SDAAL: RN-executorch roda o SLM local pra **de-id de PII antes de subir** pro cérebro
  (P4/privacidade), + modo offline. Não é enxerto — é a peça já prevista.
- **Captura conversa-first:** Whisper STT on-device = o canal de voz; OCR + photo→VLM = **dogfoodar mídias/arquivos/
  conteúdos** (o pedido explícito). Câmera/mic = os componentes que o Marcio quer usar.
- **KG SSOT:** `.kg.yaml` sincronizado com o repo privado soberano; `kg-radar` como órgão de reconciliação.

## Perguntas em aberto (viram a Fase 1b / spike técnico)

1. **Perf real** de RN-executorch vs callstack/ai rodando SLM ~1-3B em Android mid-range (tokens/s, cold-start,
   teto de memória, bateria/térmico) — necessária pra validar o caso de de-id/offline.
2. Um SLM **0.6-3B** é **preciso o bastante pra de-id de PII** sobre o `.kg.yaml` antes de ir pro backend? Fallback?
3. **Tauri v2 Mobile / KMP / Gemini Nano** — a evidência blog-pesada perdeu alguma história local-SLM melhor?
4. **Contrato cliente↔backend** (session state, streaming de tool-call, fila offline) Expo/RN ↔ Node Agent SDK — não pesquisado.
