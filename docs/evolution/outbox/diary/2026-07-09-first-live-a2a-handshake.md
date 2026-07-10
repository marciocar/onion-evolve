---
date: 2026-07-09
instance: onion-evolve
type: innovation
classification: public
tags: [a2a-live, federation, handshake, dogfood, kid-binding, jws, gated, f2.2, rfc-0004]
affects: [federation, transport, security]
breadcrumb_for: [meta:co-evolve, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-09-security-gate-degrades-to-veto"
review_after: 2026-10-07
conflict_class: static
---

## Signal
O **1º handshake a2a-live REAL** aconteceu e foi validado ponta-a-ponta ao vivo: o adotante **metagamify**
(hub não-regulado, mesma máquina) assinou um sinal RS256 e o enviou ao endpoint `/a2a` do core; o core
verificou e **enfileirou gated** (`input_required`), sem aplicar nada. Isso **destrava a Fase 2 da RFC-0004**
(o critério era "gate humano + dogfood") — e o parceiro certo p/ estrear foi o não-regulado, deixando o
regulado (granaai) p/ um gate humano posterior. **E o dogfood revelou uma dureza, fechada no mesmo loop** — o
padrão canônico Onion (fix → re-dogfood) em ação.

## Evidence
- **Cadeia viva provada:** `send-signal.sh` (no repo do metagamify) monta envelope + assina JWS RS256 (chave
  privada NUNCA sai da máquina do remetente) → `POST /a2a` → `a2a-verify.sh` do core (trust · jti · timestamp ·
  ssrf · JWS · kid-binding · never-live-pull) → `{"verified":true,"state":"input_required","gated":true,
  "committed":false}` HTTP 200 → registro em `data/a2a-pending/` do bridge. **Nada auto-aplicado** (I3).
- **A dureza que o dogfood expôs (e que o design puro não pegou):** só verificar assinatura + `iss==from` NÃO
  basta com **2+ membros com chave** — o dono de QUALQUER `kid` pinado poderia assinar reivindicando
  `from=outro`. metagamify foi o **1º membro com chave** → a hora exata de fechar. Hardening: `a2a-verify` passa
  a exigir **`kid ∈ members.yaml a2a.keys[from]`** (+1 selftest de impersonação → 234 total). Sem o handshake
  real, o gap ficaria latente.
- **Modelo de confiança:** o remetente **self-gera** o par (priv gitignorada no repo dele); o core **pina a
  pubkey** (`jwks/<kid>.pem`, force-add sobre o `.gitignore *.pem`) sob gate humano; o `members.yaml` amarra
  `kid→membro`. Trust-establishment é ato humano, não automático.
- **Fronteira operacional:** todo write ao serviço `bypassPermissions` (instalar o endpoint, atualizar o clone
  do bridge, ler o token) foi **gesto humano via `!`** — o classificador do Claude Code hard-gateia writes
  independente de allow-rule. O gate humano do F2.2 acabou **enforçado pelo tooling**, não só pela doutrina.

## Next crumb
Restante gated: o mesmo handshake com um **regulado** (granaai) — `apply_mode:propose-only` já implementado, mas
exige gate humano explícito + never-live-pull. Hardening futuro: **token dedicado** por membro no `/a2a` (o
dogfood usou o `AUTH_TOKEN` admin). Regra durável: **1 chave = 1 membro** (kid-binding) e **fila gated ≠
aplicação** — o canal vivo só acelera o aviso; a aceitação segue humana. Ver
[[2026-07-09-security-gate-degrades-to-veto]] (a fundação do gate) e
[[2026-07-09-federation-redesign-rfc0004-shipped]] (a RFC que isto destrava).
