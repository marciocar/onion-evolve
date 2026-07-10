---
date: 2026-07-10
instance: onion-evolve
type: innovation
classification: public
tags: [a2a-live, federation, handshake, regulated, granaai, clock-trust, gated, f2.2, rfc-0004]
affects: [federation, transport, security]
breadcrumb_for: [meta:co-evolve, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-09-first-live-a2a-handshake"
review_after: 2026-10-08
conflict_class: static
---

## Signal
O **1º handshake a2a-live com membro REGULADO** fechou o F2.2 (RFC-0004 #5): a **granaai** (standalone,
fintech, `mode: regulated`) assinou um sinal RS256 (`kid=granaai-1`) e o enviou ao `/a2a` público do core;
o core verificou (7 camadas — incluindo a **guarda clock-trust estreada no mesmo dia**) e enfileirou gated
(`input_required`); o maestro aceitou via `a2a-accept.sh` → inbox → triagem normal. Nada auto-aplicado.
Execução por **cobertura autorizada** da ponta adormecida (commit isolado `cd60d103c` na branch
`onion/a2a-sender-granaai` do repo granaai, com log de autoria — I3 preservado: develop intocado).

## Evidence
- **Cadeia viva:** keypair self-gerado na máquina da granaai (priv NUNCA saiu) → pubkey pinada sob gate
  humano (`jwks/granaai-1.pem` + `a2a.keys[granaai]`, commit `dc489b4`) → `send-signal.sh` → `POST
  https://app.onionevolve.com/a2a` → `{"verified":true,"state":"input_required","gated":true,
  "committed":false}` HTTP 200 → fila → `a2a-accept` (ato humano) → `inbox/_processed/2026-07-10-granaai-ack-kg-map.md`.
- **Guarda clock-trust operante no caminho:** o mesmo dia em que o maestro exigiu "carimbo de tempo só com
  fonte verificada", a camada 3 passou a exigir prova de NTP (veto `clock-untrusted`; commit `e750023`,
  +2 selftests = 248) e o handshake regulado já passou por ela em produção (host com drift 0s verificado).
- **Nota honesta (declarado ≠ verificado):** o veredito veio `regulated:false/apply_mode:gated` — CORRETO:
  a camada never-live-pull protege **receptor** regulado, e o receptor aqui é o core. O que o handshake
  regulado exercitou ao vivo foi o kid-binding + clock-trust com membro regulado real; o caminho
  propose-only permanece coberto por selftest (receptor sintético `fin`) até a granaai operar o gate
  receptor vendorizado.
- **Follow-ups registrados:** token a2a DEDICADO p/ granaai (exige append em `INVITE_TOKENS_A2A` + restart
  do bridge — gesto humano) · registro `2026-07-09-metagamify-dedicated-token` segue na fila aguardando
  aceite do maestro · branch `onion/a2a-sender-granaai` aguarda PR na sessão da granaai (não pushada).

## Interpretation
O gate não mudou de natureza com o 2º remetente — mudou de **prova**: agora há 2 membros com chave
(o cenário exato que motivou o kid-binding) e um deles é regulado, e o canal continuou gated de ponta a
ponta. A latência caiu; o controle não. E o padrão fix→re-dogfood segue pagando: a guarda de relógio
nasceu de uma frase do maestro de manhã e já estava no caminho crítico do handshake à noite.
