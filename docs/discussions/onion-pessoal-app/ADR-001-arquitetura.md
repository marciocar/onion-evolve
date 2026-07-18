---
title: "ADR-001 — Arquitetura do App Onion Pessoal"
category: discussion-adr
status: proposed
date: 2026-07-18
branch: discuss/onion-pessoal-app
supersedes: []
gated: true
---

# ADR-001 — Arquitetura do App Onion Pessoal

> **Discussão isolada — proposed, gated.** Consolida o que foi VERIFICADO na sessão de 2026-07-17/18.
> Nada vai pro core/produção sem o maestro pedir. Decisões marcadas `[VERIFICADO]` têm evidência;
> `[PROPOSTO]` são spec-alvo a reconciliar.

## Contexto

Um app **companheiro conversacional** sobre o **life-KG** do Marcio (3 verticais F0 runtime-grade em
`~/onion-pessoal/`), na doutrina **KG-SSOT-first + runtime SDAAL**, ingerindo conteúdos/mídias/arquivos, com
câmera/mic e caminho pra SLM on-device. Ordem-mãe do maestro: **camadas pessoal→produto** (N=1 primeiro).
Evidência viva: `research/stack-research-2026-07.{md,kg.yaml}` (deep-research, radar exit 0).

## Decisões

### D1 — Filho, não parte `[VERIFICADO]`
O app/instância é um **adopter que federa** (`role: standalone`, `mode: regulated`, adota o MÉTODO, dado
soberano) — já registrado como `marcio-pessoal` em `members.yaml`. "Parte dentro do core" é rejeitada por
`fonte≠derivação` (o life-KG privado nunca entra no repo público). **Consequência aberta:** herança de updates
do core p/ um adopter method-only = **gap G1** (modo docs-only, ADR `onion-adr-capability-update-out-of-git`) —
a peça a desenhar se quiser "atualização natural".

### D2 — Stack: React Native + Expo (+ executorch/callstack p/ SLM) `[VERIFICADO]`
Único stack que bate os 4 requisitos duros com fontes **primárias** (deep-research, 15 confirmados/10 refutados):
câmera/mic/notif/fs (expo-*), SLM on-device provado (react-native-executorch — Whisper/TTS/OCR/VLM offline,
2º runtime callstack-ai), cliente de backend Node Agent SDK, ship rápido (EAS). Runner-up **Capacitor** (sem SLM
maduro). Números de market-share **refutados** — decisão apoiada em **capacidade**, não popularidade.

### D3 — Cérebro: onion-bridge RECONFIGURADO pro life-KG `[PROPOSTO, fork-chave]`
O app é **cliente** de uma instância do **onion-bridge** (Node + Hono + `@anthropic-ai/claude-agent-sdk`).
**Fork de uma linha:** o bridge do pessoal roda com **`cwd`/`ONION_CWD` → `~/onion-pessoal`** (o life-KG), não
`/home/onion/onion-evolve` (o core). ⇒ **não é app do zero: é o bridge existente reconfigurado** pra ler o grafo
de vida. Encurta o near-term drasticamente.

### D4 — Canal de chat = superfície NOVA `[VERIFICADO que falta + PROPOSTO o contrato]`
Sonda ao vivo (2026-07-17) confirmou: `app.onionevolve.com` expõe **só** o A2A (`co-evolution-signal`,
signals-only, gated — **não** conversa). O canal conversacional **não existe** na superfície verificada. Spec-alvo
(spec-as-code, ver `proto/chat-endpoint.md`):
```
POST /chat  { sessionId, message }  → SSE: assistant_delta | tool_use | tool_result | done
auth: bearer do maestro  (separado do oauth2/mTLS do A2A, que é só federação)
```

### D5 — SLM on-device = adapter SDAAL `de-identification/local-slm` `[VERIFICADO o encaixe]`
O "SLM futuro" NÃO é enxerto: é a "segunda runtime" da tese SDAAL. RN-executorch roda o SLM local pra **de-id de
PII antes de subir** pro cérebro (P4) + modo offline. Camada **futura**, gated na `Q_DEID` (um 0.6-3B faz de-id
preciso o bastante?).

### D6 — Runtime KG-SSOT-first `[VERIFICADO]`
O `.kg.yaml` do life-KG é o **store de registro**; `kg-radar.sh` é o **motor de reconciliação** determinístico;
o app **superfície do veredito** do radar (RADAR/RECONCILIAÇÃO/INTEGRIDADE), distinguindo falha estrutural
(exit 1) de aviso. Loop `read→verify→act→write`. Captura e espelho = o mesmo ato (conversa-first).

### D7 — Build em camadas (helper→fiação→campo) + faseado `[doutrina]`
F0 substância (✅ grafos runtime-grade) → spike (contrato/de-id) → superfície (bridge-reconfig + cliente RN) →
**produto** (Fase 1b: mercado/dor/preço/viral) — a última, gated na ordem pessoal→produto.

## Privacidade (P4/P5) — invariante
Life-KG cru **nunca** sai do repo soberano; só saída **destilada + gated**; de-id **on-device** antes de qualquer
upload; a inferência interna é indefesa por construção (P5) → governa-se fronteira-de-saída, não o motor.

## Consequências / o que fica aberto (gated)
- **Q_PROTOCOL residual:** o contrato de chat proposto precisa ser reconciliado contra o fonte do bridge (VPS,
  inalcançável autônomo daqui) OU implementado se o bridge só tem A2A.
- **Q_DEID / Q_PERF:** spike do SLM on-device (camada futura).
- **G1:** desenhar o update-path docs-only p/ o adopter method-only.
- **Fase 1b:** pesquisa de produto — depois que o N=1 rodar.
- **Rodar o app RN + deploy do bridge-reconfig:** precisam de ambiente de dev/device e acesso à VPS.
