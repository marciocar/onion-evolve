---
title: "Fonte de discussão — App próprio para o Onion Pessoal (a superfície de vida)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-17
branch: discuss/onion-pessoal-app
# ── bloco Tier-0 (o mapa da constelação lê SÓ isto — metadados, nunca o corpo) ──
phase: CONVERGE       # SEED | EXPLORE | DEEP | CONVERGE | PROMOTE | PARK
next_action: "**F1 FECHADO (2026-07-19)** — o motor privado inteiro construído e provado no G54 num dia: kg-radar JS (gate D6, conformidade JS↔sh 8/8) · de-id LOCAL · CORE LOOP com cérebro real (Anthropic BYOK direto, sem VPS) · gestão de prompts KG-SSOT-first+runtime · REFORÇO eval-driven (≡ /meta:diary review) · CHAT COM MEMÓRIA (life-KG persistente; reconheceu pessoa entre turnos) · IMAGEM ao cérebro · VOZ assimétrica (STT externo via uploadAsync; TTS ON-DEVICE). F0 já estava fechado (cifra, store, sync zero-knowledge). App: github.com/marciocar/onion-pessoal-app (master). DECISÕES do dia: (a) AMENDA da INVARIANTE 0 — mídia vai CRUA enquanto não houver equivalente on-device, registrada em CÓDIGO (mediaPolicy.ts: ALLOW_RAW_MEDIA + condição de saída) e na KG (D_MEDIA_EXCEPTION); TEXTO segue com de-id local integral. (b) S2S GATED (D_VOICE_ASYMMETRY): colapsaria a compartimentalização (transcritor ouve mas não te conhece; cérebro te conhece mas só vê tokens) + RN instável. Saída: whisper.rn/whisper-kit-expo. **PRÓXIMO — F2**: superfície + SSOT 6-camadas de inferência/P5 (onde moram Q_METADATA_LEAK e o de-id-por-SLM que DESLIGA a exceção de mídia). Fios leves: arquivos no mesmo flag (definir tipos), amendar o texto do ADR-003, rotacionar PAT+chave OpenAI (passaram pelo chat), migrar a origem soberana p/ fora da VPS (ops)."
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
