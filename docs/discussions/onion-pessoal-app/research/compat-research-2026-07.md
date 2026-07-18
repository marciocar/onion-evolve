# Pesquisa de compatibilidade do stack — App Onion Pessoal (deep-research, 2026-07-18)

> Fonte: deep-research `wte2k70qw` — 6 ângulos, 27 fontes, 115 claims → 25 verificados adversarialmente,
> **25 confirmados / 0 refutados**. Prioridade a fontes primárias (docs oficiais, repos, issues). Datado jul-2026.
> KG-SSOT: nós `E_COMPAT`, `C_NOT_DEFASADO`, `Q_GITSYNC` em `stack-research-2026-07.kg.yaml`.

## Veredito: o stack **NÃO começa defasado** — é coeso na última SDK

| Componente | Versão | Status no SDK 57 |
|---|---|---|
| **Expo SDK 57** | RN 0.86 · React 19.2 (lançado **30/06/2026**) | ✅ é a **última**; New Arch por padrão |
| **react-native-executorch** | 0.9.2 (17/06) · nightly 0.10.0-* | ✅ **New-Arch-ONLY** → casa com SDK 57; ⚠ dev build custom (não Expo Go) |
| pareamento executorch 0.9.2 × RN 0.86 | — | ⚠ **NÃO verificado** (0.9.2 predata RN 0.86 por 13 dias; 0.10.0 nightly existe) |
| Piso de device | iOS 17 · Android 13 · **RAM ≥4GB** (1-3B), 8GB+ (4B) | ✅ realista (doc oficial) |
| @anthropic-ai/claude-agent-sdk | ^0.3.x (backend) | ✅ não interage com deps do RN |
| hono | ^4.12 (backend) | ✅ |

**Conclusão:** o requisito duro do SLM (New Arch) é *exatamente* o que o SDK 57 entrega — sem conflito. O único
resíduo é o pareamento binário 0.9.2×RN0.86 (13 dias de defasagem do dep). **Superação = desacoplamento (ADR D7):**
shell no SDK 57 já (chat+câmera+mic+SSE, todos confirmados no 57); a camada SLM usa 0.10.0/espera a stable.

## Libs a adicionar (verificado, escolha por gap)

1. **Store on-device + cripto at-rest (gaps 1+6, num só componente):**
   - **expo-sqlite** (first-party, SDK 57) + **SQLCipher** via config plugin `useSQLCipher:true` + `expo prebuild`. Default.
   - **op-sqlite** (JSI, sem config plugin, SQLCipher via `sqlcipher:true`) se precisar de performance superior. Ambos: **não** Expo Go.
   - A chave de cifra guardada em **expo-secure-store**.
2. **SSE (POST streaming) (gap 2):** **expo/fetch** (first-party, `response.body.getReader()`, POST + `Authorization: Bearer`).
   - ⚠ Existia um bug de consumo de stream-JSON no **SDK 52** (expo/expo#32953) — escopado ao 52; **dogfoodar no SDK 57**.
   - Fallback: **react-native-sse** (POST+headers via XHR) — mas estagnado (v1.2.1, ~2 anos sem publish) → só se o bug se manifestar.
3. **Voz + STT (gap 5):** **executorch `useSpeechToText`** (Whisper on-device, offline — reusa o runtime já no stack) +
   **expo-audio** (oficial no SDK 57; **expo-av deprecado**). `useAudioRecorder` (record→uri→Whisper) maduro; `useAudioStream`
   (PCM ao vivo) menos maduro — dogfoodar.
4. **Token:** expo-secure-store.

## 🚩 Risco aberto — `Q_GITSYNC` (o mais frágil)
Sync **git do life-KG soberano NO DEVICE**: `isomorphic-git` é BYOFS (não embarca fs) **sem suporte RN/Hermes
documentado**; `lightning-fs` é browser-only (IndexedDB, ausente no Hermes). Exige **fs-shim custom sobre
expo-file-system**, sem viabilidade verificada. Alternativas (nodejs-mobile, bindings libgit2) **não cobertas**.
Toca a INVARIANTE 0 (onde/como o life-KG vive e sincroniza). **Precisa de spike próprio.**

## Swaps
Sem swaps fortes — as escolhas first-party (expo-sqlite, expo/fetch, expo-audio, executorch STT) vencem. O único
ponto sem opção first-party madura é o **git-sync** (nenhuma verificada).

## Caveats honestos (a pesquisa flagou)
- **Nenhuma** fonte confirmou/refutou "issues abertas de incompat Expo 57 × executorch" — ausência de contra-evidência ≠ ausência de bug; o pareamento 0.9.2×RN0.86 não foi testado no runtime.
- **Orçamento de busca esgotou (200/200)** em claims tardios (op-sqlite, expo-sqlite, executorch STT, expo-audio) → apoiam-se em **fonte primária única** (doc oficial), sem 2º cross-check adversarial. Confiança alta pela fonte, mas sem triangulação.
- Não cobertos (precisam de pesquisa dedicada antes da decisão): **parser YAML em RN** (js-yaml sob Hermes), confirmação do expo-secure-store, MMKV/MMKV-encryption como alternativa de store.
- `Q_GITSYNC` = **maior risco de execução aberto** (nenhuma verificação real em RN/Hermes).
