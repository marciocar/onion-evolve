---
title: "ADR-001 — Arquitetura do App Onion Pessoal"
category: discussion-adr
status: proposed
date: 2026-07-18
revision: 2
branch: discuss/onion-pessoal-app
supersedes: []
gated: true
---

# ADR-001 — Arquitetura do App Onion Pessoal (rev. 2)

> **Discussão isolada — proposed, gated.** rev.2 incorpora review adversarial orquestrado (privacidade/P4-P5,
> conformidade-doutrina, solidez técnica) que encontrou drifts CRÍTICOS na rev.1. Nada vai pro core/produção sem
> o maestro pedir. `[VERIFICADO]` = evidência; `[PROPOSTO]` = spec-alvo a reconciliar; `[CORRIGIDO-r2]` = furo do review consertado.

## Contexto

App **companheiro conversacional** sobre o **life-KG** do Marcio (3 verticais F0 runtime-grade em `~/onion-pessoal/`),
na doutrina **KG-SSOT-first + runtime SDAAL**. Ordem-mãe: **camadas pessoal→produto**. Evidência:
`research/stack-research-2026-07.{md,kg.yaml}` (radar exit 0).

## INVARIANTE 0 — Locus de deploy `[CORRIGIDO-r2, era o furo-mãe]`

O review de privacidade achou o buraco estrutural: **a rev.1 nunca fixava ONDE o cérebro roda**, e toda a alegação
de soberania dependia disso. **Decisão:** o cérebro que opera verticais `private` (saúde/casamento) roda **num nó
pessoal confiável do Marcio** (device ou máquina com full-disk-encryption), **nunca na VPS compartilhada** (Hostinger =
terceiro). O life-KG cru **nunca persiste no disco da VPS**. O `onion-bridge` público atual (VPS, `cwd`=core) serve o
**framework**, não a vida — o bridge pessoal é um **deploy separado no nó confiável**. Se algum dia rodar em nuvem, a
P4 ("local-first, nunca copiado") **cai** e tem de ser re-derivada sob esse threat model — não silenciosamente.

## Decisões

### D1 — Adopter standalone/regulated com core clonado no nó pessoal `[CORRIGIDO-r2]`
Instância = **adopter que federa** (`role: standalone`, `mode: regulated`, dado soberano), já em `members.yaml`.
**Correção do review-doutrina:** NÃO é "method-only" — a P3 recomendou a **Posição A** (standalone que tem `.claude/`
em disco), e o cérebro **precisa** do `.claude/` do core (tools: `kg-radar`, agents). Então: **core clonado (docs-only)
no nó pessoal**; o `onion_version: n/a` do `members.yaml` precisa ser **reconciliado** (vira um pin real quando o core
for clonado) — senão o update-path G1 (`capability-update-out-of-git`, **docs-only maestro-gated, never-live-pull**) fica
incoerente (não há `.claude/` a reconciliar). "Parte no core" segue rejeitada (`fonte≠derivação`; life-KG nunca no repo público).

### D2 — Stack: React Native + Expo (+ executorch/callstack p/ SLM) `[VERIFICADO + compat 2026-07-18]`
Único stack que bate os 4 requisitos com fontes primárias (2 deep-research). **Compat verificada (25/25 claims):** SDK 57
= RN 0.86/React 19.2 (lançado 30/06 — **é a ÚLTIMA, NÃO defasado**); executorch 0.9.x é **New-Arch-ONLY + dev-build**
(não Expo Go) → **casa** com o SDK 57 (New Arch default), sem conflito. iOS17/Android13/**RAM≥4GB** realistas.
- **Estratégia de DESACOPLAMENTO (D7):** único residual = executorch 0.9.2 (17/06) é 13 dias ANTERIOR a RN 0.86 (30/06),
  pareamento binário não-verificado (nightly 0.10.0 já existe). ⇒ **shell no SDK 57 JÁ** (chat+câmera+mic+SSE, todos
  confirmados no 57); a **camada SLM** usa 0.10.0/espera a stable. Assim NÃO se começa defasado nem se fica refém do dep travado.
- **Libs a adicionar (verificado):** store+cripto = **expo-sqlite + SQLCipher** (op-sqlite se precisar JSI); SSE = **expo/fetch**
  (`getReader`, POST+Bearer; dogfoodar o bug de stream-JSON que existia no SDK 52); voz = **executorch `useSpeechToText`**
  (Whisper on-device) + **expo-audio** (expo-av deprecado); token = expo-secure-store.
- **⚠ RISCO ABERTO `Q_GITSYNC`:** o sync git do life-KG soberano NO DEVICE é o ponto frágil (isomorphic-git BYOFS sem RN
  verificado; lightning-fs browser-only). Toca a INVARIANTE 0 (como o life-KG vive/sincroniza no nó confiável). Precisa spike próprio.

### D3 — Cérebro: onion-bridge RECONFIGURADO por env (config, não fork) `[CORRIGIDO-r2]`
**Reenquadrado (review-doutrina):** reapontar não é "fork" — é **reconfiguração via env, config pura; ZERO fork de código
do bridge**. Invariante: o código do bridge fica **reconciliável** (recebe updates do core); qualquer mudança de código =
derivação não-reconciliável, **proibida**.
**Correção técnica do cwd (o pilar quebrado):** o Agent SDK roda com **`cwd` = o clone do CORE** (aí `.claude/kg-radar.sh`
e agents resolvem), e o **life-KG entra como caminho SEPARADO** (`LIFE_KG=~/onion-pessoal`, absoluto) que o agente lê/escreve.
Não dá pra `cwd`=dados **e** tools do core juntos — resolvido separando os dois paths.

### D4 — Canal de chat = superfície NOVA, auth ≥ A2A `[CORRIGIDO-r2]`
Sonda ao vivo confirmou: `app.onionevolve.com` expõe **só** A2A (`co-evolution-signal`, signals-only). O chat não existe na
superfície verificada. **Correção de segurança (review-privacidade):** o `/chat` toca o dado MAIS sensível → auth **≥** A2A:
**mTLS client-cert device-bound + tokens curtos PKCE**, **não** bearer estático. `sessionId` **vinculado à identidade
autenticada**. `/health` autenticado, sem vazar path absoluto. Contrato em `proto/chat-endpoint.md`.

### D5 — SLM on-device = de-id `[VERIFICADO o encaixe; CORRIGIDO-r2 o transporte]`
De-id `private` = adapter SDAAL **`de-identification/local-slm`** (existe). **Nuance do review:** o adapter atual roda por
**HTTP (Ollama/vLLM)**; o **executorch embarcado** é um **transporte NOVO** — registrar como extensão-de-transporte do
adapter, não suposição silenciosa. **Sequenciamento CORRIGIDO:** de-id não é "camada futura solta" — é **pré-condição** de
qualquer upload de mídia/inferência-cloud sobre `private` (ver INVARIANTE 0 + D7).

### D6 — Runtime KG-SSOT-first COM o radar como gate `[CORRIGIDO-r2]`
**Furo do review-doutrina (DRIFT-1):** a ref. da rev.1 só lia e hardcodava `reconciled:true` — "SSOT que mente". Corrigido:
o loop **(a)** roda `kg-radar.sh` e **ramifica no exit code** (exit 1 = falha estrutural → BLOQUEIA o write + superfície o
erro), **(b)** só então emite `kg_write`, **(c)** carimba **`verified_at`** no PROD capturado, **(d)** correções entram
**append-mostly** como arestas `REFUTES`/`SUPERSEDES` — nunca overwrite. É `read→verify→act→write` de verdade.

### D7 — Build em camadas + sequenciamento privacy-safe `[CORRIGIDO-r2]`
helper→fiação→campo. **Near-term privacy-safe (review):** conversa **texto** no nó confiável, **sem upload de mídia crua**;
`attachments` = **gated-on-de-id** (processar câmera/mic/arquivo 100% on-device via executorch antes de qualquer subida).
Os gates **L1 (escopo-de-consulta por vertical)** e **L6 (ε-ledger)** precisam **existir antes de embarcar**, não "futuro".
Ordem: substância (✅) → spike (contrato/de-id) → superfície → **produto** (Fase 1b, gated na ordem pessoal→produto).

### D8 — Continuidade de federação: /chat ⊥ /a2a+doc-bridge `[gap achado pelo maestro, 2026-07-18]`
O app usa **/chat** (loop humano↔cérebro). Isso **NÃO substitui nem perde a federação** — meu foco em /chat era
app-cêntrico e omitiu essa dimensão. Verificado no fonte: **/chat e /a2a COEXISTEM** no mesmo bridge (rotas
separadas). A instância pessoal **PERMANECE membro federado**: hoje via **doc-bridge** (inbox/inbound +
co-relay/co-deliver), NÃO via A2A-live (gated/foundation; `marcio-pessoal` nem tem bloco `a2a:` no `members.yaml` —
trust zerado, research-arm). **Perder a federação seria WRONG Onion:** ela É o canal de co-evolução que traz os
updates do core (o gap G1 que você perguntou no começo). Dois loops ORTOGONAIS, ambos ficam:
- **Loop humano** = `/chat` (o maestro conversando com o life-KG).
- **Loop máquina/co-evolução** = A2A + doc-bridge (sinais gated core↔membro; a herança de updates).

## Privacidade (P4/P5) — invariante operacional (não mais aspiracional)
Life-KG cru só no nó confiável, **nunca** VPS; saída só **destilada+gated**; **de-id on-device antes de qualquer upload**;
**sem `bypassPermissions`** no bridge do life-KG (allow-list: radar read-only; escrita ao `.kg.yaml` **human-gated**);
retrieval **escopado à vertical** da conversa (L1); a inferência interna é indefesa (P5) → governa-se fronteira-de-saída +
declara-se **VPS e a API Anthropic** como atores do threat model (o prompt carrega o KG → 3º no loop).

## Consequências / aberto (gated)
- **Q_PROTOCOL residual:** contrato de chat proposto a reconciliar contra o fonte do bridge (VPS, inalcançável autônomo).
- **Q_DEID / Q_PERF:** spike do SLM on-device (agora pré-condição, não luxo futuro).
- **G1 + `members.yaml`:** reconciliar `onion_version: n/a` × core-clonado; desenhar o update-path docs-only maestro-gated.
- **Mídia/conteúdo:** declarar eixo SDAAL (`content-source`/`media-store`) gated, não hardcodar no endpoint.
- **Rodar RN + deploy do bridge no nó confiável:** precisam de device/ambiente + o nó do Marcio.

## Anexo — o review que endureceu este ADR
Review adversarial orquestrado (3 lentes paralelas, 2026-07-18) achou: privacidade (locus de deploy não-declarado quebrava
P4; bearer < A2A; upload pré-de-id; inferência em terceiro), técnica (API `ClaudeSDKClient`→`query()`; cwd-vs-tools; SSE em
RN precisa `expo/fetch`), doutrina (method-only×core-clonado; "fork"→config; radar não-gate; `verified_at` ausente). Dogfood:
a revisão-no-papel-em-paralelo pegou o que uma passada linear não pegaria.
