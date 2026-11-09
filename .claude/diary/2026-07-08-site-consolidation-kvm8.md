---
date: 2026-07-08
instance: onion-evolve
type: decision
classification: public
tags: [vps, consolidation, site, dns, caddy, onion-bridge, infra]
affects: [operations, federation, meta]
breadcrumb_for: [members.yaml, meta:co-evolve]
share_with: []
next_recommended: "2026-07-05-vps-lineage-odyssey"
review_after: 2027-01-12
conflict_class: dynamic
valid_when: "onionevolve.com (site + app.onionevolve.com/bridge) serve da VPS <host-da-vps> (<ip-publico-da-vps>), com a VPS antiga <host-antigo-da-vps> retirada"
---

## Signal
O core migrou pra uma VPS (`<host-da-vps>`) e **consolidou tudo numa máquina só** — revertendo
a decisão "Coexistem". `onionevolve.com` (estáticos + `app.onionevolve.com`/onion-bridge) foi migrado da
VPS antiga (`<host-antigo-da-vps>`) pra cá; a VPS antiga virou rollback. Ao operar infra do Onion, o lar único é a VPS; o
`vps-bridge` no `members.yaml` está `status: retired`.

## Evidence
- Migração host-a-host (rsync via SSH, segredos nunca pelo chat): site (840K) → `<raiz-do-site>`;
  bridge (código+.env+`data/tokens.json`, 9 tokens) → `<home-do-usuario-de-servico>/onion-bridge`; auth Claude do user
  `onion` (`.claude` 14M, login OAuth) trazida; clone dedicado do core em `<home-do-usuario-de-servico>/onion-evolve` (ONION_CWD).
- Caddy (TLS Let's Encrypt auto) + systemd `onion-bridge` (Agent SDK bypassPermissions, User=onion, :8787).
  **Estado em 2026-10-14:** a unit se chama `onion-vps-bridge.service` (o nome `onion-bridge` não existe mais
  no systemd: `systemctl is-active onion-bridge` → inactive, porque a unit não existe). Segue com User=onion
  e `WorkingDirectory` no home do usuário `onion` (`<home-do-usuario-de-servico>/onion-bridge`), agora atrás de `reverse_proxy 127.0.0.1:8787` (bind em
  loopback) e com o hardening `ProtectHome=read-only`.
- DNS via API provedor: `@`/`app` → `<ip-publico-da-vps>` (aprendizado: `overwrite:false` é ADITIVO — precisou
  `overwrite:true` p/ substituir o IP antigo, senão round-robin entre as 2 máquinas).
- Verificado independente: com a VPS antiga PARADA, os 3 endpoints seguem HTTP 200 + cert válido.
- **Re-medido em 2026-10-14:** `hostname` = <host-da-vps>; `dig +short` de `onionevolve.com` e de
  `app.onionevolve.com` → <ip-publico-da-vps>; `curl -sI` → HTTP/2 200 nos dois; o Caddy local serve `root *
  <raiz-do-site>`. A exclusão da VPS antiga pelo hPanel NÃO foi verificada daqui.
- O classificador do Claude Code (não o Onion) hard-gateia iniciar o bridge (bypassPermissions exposto) e
  materializar credencial — precisou do `!` do maestro; NOPASSWD sudo não vence essa camada.

## Next crumb
Deletar a VPS antiga pelo hPanel após período de confiança (rollback: reapontar DNS p/ IP antigo
`<ip-antigo-da-vps>`). Re-teste (dynamic → rodar): `curl -sI https://onionevolve.com` = 200 + `dig` → VPS.
Deploy do site agora é local (`<raiz-do-site>` + Caddy), não mais `rsync`. Ver [[onion-core-home]].

## Re-testada em 2026-10-14 — PARCIAL: (dynamic, rodei) o Signal vale (DNS → VPS, 200 nos dois hosts). O Evidence foi corrigido: a unit agora é `onion-vps-bridge.service`, com bind em loopback.
