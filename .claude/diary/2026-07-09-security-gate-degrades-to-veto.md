---
date: 2026-07-09
instance: onion-evolve
type: innovation
classification: public
tags: [a2a-live, security-gate, fail-safe, verify-before-acting, jws, ssrf, dogfood, federation, f2.2]
affects: [federation, transport, security]
breadcrumb_for: [meta:co-evolve, meta:evolve]
share_with: [collective]
next_recommended: "2026-07-09-federation-redesign-rfc0004-shipped"
review_after: 2026-10-07
conflict_class: static
---

## Signal
Um **gate de segurança degrada para VETO, nunca para SKIP** — o oposto do idioma de degradação graciosa dos
GERADORES de artefato. F2.2 (endpoint a2a-live) foi partido em duas metades por risco: o **endpoint vivo**
(Hono/SSE/webhook) fica no repo privado da VPS sobre `bypassPermissions` e exige gate humano + dogfood com
regulado; a **fundação de segurança do receptor** — a "verificação-antes-de-agir" que a spec A2A exige — foi
construída e **dogfoodada no core SEM abrir canal** (offline puro). Helper-testável-primeiro em estado forte.

## Evidence
- **Duas idiomas de "graceful degradation" que NÃO se misturam:** gerador sem `jq`/`python+yaml` → **skip**
  (seguro: "não regenerou, sem dano"). Gate de segurança sem a ferramenta que **estabelece** confiança
  (openssl p/ JWS, jq p/ parse, python p/ ler a policy) → **VETO** (RFC-0004 §4: "sem output válido = veto;
  ausência nunca é aprovação"). Skip num gate = fail-open, o antipadrão. Divergência declarada no cabeçalho
  (espelha `factory.md`), com selftest dedicado provando `tooling-absent → veto` (escondendo openssl do PATH).
- **`a2a-verify.sh`** — 6 camadas fail-fast, veredito tipado com invariantes hardcoded (`gated:true` e
  `committed:false` SEMPRE, verificado em asserts em veredito verified E vetoed): trust (COMPÕE
  `trust-topology-check.sh`, não duplica) · anti-replay `jti` single-use (state por-receptor, idioma do
  `mail-receiver`) · janela de timestamp · anti-SSRF (`a2a-ssrf-check.sh`) · JWS RS256 (pubkey pinada por `kid`,
  JWKS **fixture local — zero rede**) · never-live-pull (regulado → `apply_mode:propose-only`).
- **Crypto em Bash é viável e determinístico:** base64url (pad + `tr`) + `openssl dgst -sha256 -verify` sobre
  `header.payload`; o selftest forja par RSA + JWS on-the-fly (como `pin-integrity` forja commits) → happy +
  replay + expired + future + trust-denied + ssrf + bad-signature + unknown-kid + regulated + fail-safe.
- **Confidencialidade como guard testado:** o Agent Card gerado projeta SÓ o core (`id==onion-evolve` &&
  `role==source`); selftest falha se qualquer id de adotante vazar. Selftest 206→**233** (+27); lint HARD 0.

## Next crumb
O **endpoint vivo** continua GATED (metade da VPS): o `~/onion-bridge` serve o Agent Card e chama o
`a2a-verify` do core na fronteira transport→ação; o dogfood de destrave é o handshake com um regulado sob gate
humano. Regra durável: **canal vivo nunca dá ao transporte remoto poder de escrita cross-repo** (I3 +
isolamento `bypassPermissions`); o gate roda **antes** de o sinal virar ação. Ver
[[2026-07-09-federation-redesign-rfc0004-shipped]] (a RFC que amarra o gate) e
[[2026-07-09-adopt-vendor-branch-merge]] (mesma família: never-clobber/verify-before-acting).
