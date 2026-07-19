---
title: "Fonte de discussão — App próprio para o Onion Pessoal (a superfície de vida)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-17
branch: discuss/onion-pessoal-app
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: CONVERGE       # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "ADR-003 RATIFICADO (2026-07-19, após revisão adversarial — 3 furos endurecidos): INVARIANTE 0 = C (life-KG no device + cérebro nuvem BYOK + de-id LOCAL; VPS nunca toca KG cru), app-orquestrado (Vercel AI SDK direto), STT externo v1, core loop conversa-first, build F0→F3, N=1. App com lar durável (github.com/marciocar/onion-pessoal-app, privado). Furos da revisão: (1) verticais sensíveis gated/over-redação no de-id de regra; (2) origem soberana do KG migra p/ FORA da VPS (cifra se nuvem); (3) C-direct→teste conformidade+fallback bridge. PRÓXIMO — construir: **F0** (life-KG runtime-grade + migrar origem soberana p/ fora da VPS + sync isomorphic-git + spike cifra `isomorphic-git × SOPS+age`; VPS pode ser 1 remote ZERO-KNOWLEDGE cifrado — soberania por cifra, não por confiança; watch-items any-sync/MindooDB); depois **F1** (motor de-id LOCAL + loop read→de-id→Vercel-AI-SDK→write + kg-radar JS). GATED (Poco/F3): SLM on-device Q_DEID/Q_PERF + pesquisa de provider (WebSearch). ── histórico da validação: PROVADO NO G54 (2026-07-19, dogfood real — E_GITPROBE_G54): (1) câmera ✅; (2) git-on-device ✅ = Q_GITSYNC CAMINHO LEVE CONFIRMADO (C_GITSYNC_LIGHT, isomorphic-git+expo-file-system, SEM nodejs-mobile/EAS/dev build) — residuais b/c/d (perf/merge N=1/Yjs) abertos; (3) SSE ✅ STREAMOU no device via BYOK (Q_PROTOCOL FECHADA 100%; app tem 2 modos: cortesia/login + BYOK com X-Anthropic-Key). Bônus: estado git persiste entre sessões do device (bom p/ sync). RESTA: (a) SLM Q_DEID/Q_PERF (precisa EAS dev build) + pesquisa de provider (WebSearch → sessão nova, cobrir LiteRT-LM); (b) residuais do Q_GITSYNC (perf/merge N=1/Yjs); (c) opcional: recarregar saldo Anthropic p/ o modo cortesia. Poco X8 Pro Max chega segunda (alvo final)."
scope_globs: ["docs/discussions/onion-pessoal-app/"]
objective_tags: ["onion-pessoal", "superficie", "onion-bridge", "life-companion"]
---

# 🧵 App próprio para o Onion Pessoal — a superfície de vida

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com o `onion-mobile-app` (superfície dev/PM) nem com a discussão conceitual `onion-pessoal-marcio` (P1-P5).

## O tema
Um app **só para o Onion Pessoal** — não o `onion-mobile-app` (Onion-Bridge, superfície do SDLC dev/PM via Agent SDK), mas um **companheiro de vida** sobre o life-KG do Marcio (3 verticais fechadas em 2026-07-17: Trabalho, Saúde, Relações).

## Founding-question (a régua Aristóteles sobre a própria decisão)
- **Superfície/UX = DIFERENTE → desenha novo.** Companheiro íntimo: captura diária (humor, presença, comportamento), reflexão, private/local-first no dado mais sensível que existe (saúde, casamento). Não é a superfície de dev/PM.
- **Motor/mecanismo = O MESMO → adota, não forka.** KG SDAAL, `kg-radar`, DEV×PROD, reconciliação (Aufhebung). Se o app reconstruir o motor, forka o framework (viola P3 "adota o método, soberano no dado" + cai no `C_MARKET_COMMODITY`).
- **Dado = SOBERANO.** O KG vive no `onion-pessoal` (privado, P4); só sai destilado+gated. O app-code nunca mistura com o dado.

## Por que importa pro Onion
- É a **superfície** que fecha o loop coletar→KG→reconciliar do Onion pessoal — hoje feito à mão (Wizard-of-Oz).
- Reúso vivo do core: o `kg-radar` (reconciliação), a **prévia-como-vista** (discuss `interface-state-of-art`/dialogic-layer), o **sensor** (`behavior-mapping-kg`). O app **compõe** essas peças, não as reinventa.
- Prova viva do método N=1 (caveat `C_ORBIT_CAVEAT` segue: intra-órbita).

## Perguntas de partida
1. **O CORE LOOP.** O app produtiza a sessão de hoje (dump → estruturar+radar → bright-lines). Qual é o **coração**: captura (input sem fricção), espelho (a prévia/radar do DEV×PROD) ou coach (bright-lines/streaks/testes)?
2. **Captura.** Como o *vivido* (PROD) entra sem virar mais um trabalho? (voz, check-in rápido, o sensor behavior-mapping)
3. **Reúso × novo.** O que adota do core (radar, prévia, sensor) vs o que desenha do zero (a UX íntima de vida)?
4. **Privacidade/P4.** Toca saúde e casamento — onde o KG vive, o que é local-first, o que sai destilado.
5. **Plataforma.** Mobile via Agent SDK (como o Onion-Bridge)? PWA? Nativo? Voz-first?
