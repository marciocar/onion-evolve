---
date: 2026-07-08
instance: onion-evolve
type: decision
classification: protected
tags: [vps, consolidation, site, dns, caddy, onion-bridge, infra]
affects: [operations, federation, meta]
breadcrumb_for: [members.yaml, meta:co-evolve]
share_with: []
next_recommended: "2026-07-05-vps-lineage-odyssey"
review_after: 2026-10-06
conflict_class: dynamic
valid_when: "onionevolve.com (site + app.onionevolve.com/bridge) serve da KVM 8 srv1812846 (179.197.65.94), com a KVM 1 srv1475924 retirada"
---

## Signal
O core migrou pra uma Hostinger KVM 8 (`srv1812846`) e **consolidou tudo numa máquina só** — revertendo
a decisão "Coexistem". `onionevolve.com` (estáticos + `app.onionevolve.com`/onion-bridge) foi migrado da
KVM 1 (`srv1475924`) pra cá; a KVM 1 virou rollback. Ao operar infra do Onion, o lar único é a KVM 8; o
`vps-bridge` no `members.yaml` está `status: retired`.

## Evidence
- Migração host-a-host (rsync via SSH, segredos nunca pelo chat): site (840K) → `/var/www/onion-landing`;
  bridge (código+.env+`data/tokens.json`, 9 tokens) → `/home/onion/onion-bridge`; auth Claude do user
  `onion` (`.claude` 14M, login OAuth) trazida; clone dedicado do core em `/home/onion/onion-evolve` (ONION_CWD).
- Caddy (TLS Let's Encrypt auto) + systemd `onion-bridge` (Agent SDK bypassPermissions, User=onion, :8787).
- DNS via API Hostinger: `@`/`app` → `179.197.65.94` (aprendizado: `overwrite:false` é ADITIVO — precisou
  `overwrite:true` p/ substituir o IP antigo, senão round-robin entre as 2 máquinas).
- Verificado independente: com a KVM 1 PARADA, os 3 endpoints seguem HTTP 200 + cert válido.
- O classificador do Claude Code (não o Onion) hard-gateia iniciar o bridge (bypassPermissions exposto) e
  materializar credencial — precisou do `!` do maestro; NOPASSWD sudo não vence essa camada.

## Next crumb
Deletar a KVM 1 pelo hPanel após período de confiança (rollback: reapontar DNS p/ IP antigo
`187.77.236.211`). Re-teste (dynamic → rodar): `curl -sI https://onionevolve.com` = 200 + `dig` → KVM 8.
Deploy do site agora é local (`/var/www/onion-landing` + Caddy), não mais `rsync onion-vps`. Ver [[onion-core-home]].
