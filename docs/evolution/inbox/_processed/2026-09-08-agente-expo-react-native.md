---
title: Sinal ao core — agente de engenharia para Expo/React Native (o react-developer é web/shadcn)
date: 2026-09-08
from: jogo-da-vida (role: adopted)
kind: lacuna
---

# Sinal: falta um agente Expo/React Native na vertical de engenharia

## O que observamos

O `onion-engineering:react-developer` (última edição 2026-07-08) é orientado a web: cita shadcn/ui dez vezes, Next.js 13 e
"2025"; não menciona React Native, Expo, Reanimated, react-native-web nem React Compiler. Neste repo (app Expo SDK 57
universal, RN 0.86, React 19.2, expo-router com export estático, React Compiler ligado) ele funcionou nos lotes L3–L6
**só porque o prompt do condutor carregava toda a doutrina** (kit, `aria-*` na web, `.get()/.set()` em shared values, sem
`useCallback/useMemo`, `Platform.OS` só em `src/platform/`). O conhecimento veio do modelo e do contexto, não do agente.

## Pedido

Uma variante `expo-developer` (ou seção RN dentro do `react-developer`) com: Expo SDK atual e `npx expo install` (versões
compatíveis, `expo-doctor`), expo-router (rotas dinâmicas no export estático precisam de fallback no servidor), react-native-web
(descarta `accessibilityState/Value`; usar `aria-*`), Reanimated 4 (só transform/opacity; shared values por `.get()/.set()`),
React Compiler (sem memo manual; `react-hooks/refs`, `set-state-in-effect`), `Platform.OS` confinado a `src/platform/`, tree
shaking do Metro (`EXPO_UNSTABLE_TREE_SHAKING`, `EXPO_UNSTABLE_METRO_OPTIMIZE_GRAPH` — 38 % de JS a menos aqui), e o par
Vitest (Node) + Playwright (web) com strings acessíveis como contrato.

## Evidência

- `docs/evolution/review/feature-{ui-kit-motion,journey-celebrations,badges-rewards,share-invite,premium-polish}.md`: os achados
  recorrentes (ARIA na web, reduced-motion, compiler) são exatamente os que um agente RN evitaria de saída.
- `apps/app/scripts/lint-motion.mjs`, `apps/app/src/platform/`, ADR-010 §Bundle.

Transporte: `/meta:co-relay docs/evolution/inbox/2026-09-08-agente-expo-react-native.md --target /home/marcio/onion-evolve`.
