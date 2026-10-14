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
review_after: 2027-01-12
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
  **Estado em 2026-10-14:** a unit se chama `onion-vps-bridge.service` (o nome `onion-bridge` não existe mais
  no systemd: `systemctl is-active onion-bridge` → inactive, porque a unit não existe). Segue com User=onion
  e `WorkingDirectory` no home do usuário `onion` (`~onion/onion-bridge`), agora atrás de `reverse_proxy 127.0.0.1:8787` (bind em
  loopback) e com o hardening `ProtectHome=read-only`.
- DNS via API Hostinger: `@`/`app` → `179.197.65.94` (aprendizado: `overwrite:false` é ADITIVO — precisou
  `overwrite:true` p/ substituir o IP antigo, senão round-robin entre as 2 máquinas).
- Verificado independente: com a KVM 1 PARADA, os 3 endpoints seguem HTTP 200 + cert válido.
- **Re-medido em 2026-10-14:** `hostname` = srv1812846; `dig +short` de `onionevolve.com` e de
  `app.onionevolve.com` → 179.197.65.94; `curl -sI` → HTTP/2 200 nos dois; o Caddy local serve `root *
  /var/www/onion-landing`. A exclusão da KVM 1 pelo hPanel NÃO foi verificada daqui.
- O classificador do Claude Code (não o Onion) hard-gateia iniciar o bridge (bypassPermissions exposto) e
  materializar credencial — precisou do `!` do maestro; NOPASSWD sudo não vence essa camada.

## Next crumb
Deletar a KVM 1 pelo hPanel após período de confiança (rollback: reapontar DNS p/ IP antigo
`187.77.236.211`). Re-teste (dynamic → rodar): `curl -sI https://onionevolve.com` = 200 + `dig` → KVM 8.
Deploy do site agora é local (`/var/www/onion-landing` + Caddy), não mais `rsync onion-vps`. Ver [[onion-core-home]].

## Re-testada em 2026-10-14 — PARCIAL: (dynamic, rodei) o Signal vale (DNS → KVM 8, 200 nos dois hosts). O Evidence foi corrigido: a unit agora é `onion-vps-bridge.service`, com bind em loopback.
