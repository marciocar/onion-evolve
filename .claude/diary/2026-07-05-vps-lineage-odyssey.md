---
date: 2026-07-05
instance: onion-evolve
type: learning
classification: public
tags: [federation, lineage, vps, pin-integrity, ssh, backup-first, mobile, bridge]
affects: [federation, operations, meta]
breadcrumb_for: [members.yaml, meta:co-evolve, onion-bridge]
share_with: [collective]
next_recommended: "2026-07-03-declared-vs-verified-family"
review_after: 2026-10-05
conflict_class: conditional
valid_when: "o VPS Hostinger (srv1475924) hospeda clone do core + onion-bridge + site onionevolve.com, com acesso via ssh onion-vps"
---

## Signal

"Atualizar o espelho do VPS" não existe — **linhagem com escritor é meia-instância que trabalha**.
O clone que todos tratavam como espelho passivo estava numa feature branch local com commit
próprio, criado de um **celular** via Onion-Bridge. O rito de update de qualquer linhagem começa
com `git status` + branch, nunca com `git pull`.

## Evidence

- **O pin honesto pagou pela 2ª vez**: `pin: unknown` (registrado 2026-07-03 porque não havia SSH)
  teria sido substituído pelo palpite "main, ~#221" — a verificação real achou
  `feature/whatsapp-sender` @ `17a90cb` (commit de 30/jun, autor "Onion System", via bridge/PWA).
  O palpite estaria duplamente errado: branch E hash.
- **A credencial git do clone estava morta** (PAT do clone original): o VPS não conseguia nem
  fetch — o "espelho" estava incapaz de espelhar desde algum momento, silenciosamente. Cura:
  deploy key SSH **gerada no próprio VPS** (privada nunca viaja; escopo = 1 repo).
- **Ordem de segurança executada**: backup dos untracked (scp → workstation) → conserto de auth →
  resgate (push da branch à origin) → só então update (47 commits ff) → restart do serviço →
  health + site verificados → registro (members.yaml PR #250).
- **Chave do maestro tampouco viajou**: par criado na workstation, só a PÚBLICA foi ao painel da
  Hostinger. Regra reafirmada: chave privada jamais passa pelo chat/transcript.
- **Layout real ≠ DEPLOY.md**: bridge vive em `~onion/onion-bridge` (não `/opt`); site
  `onionevolve.com` = estáticos em `/var/www/onion-landing` (Caddy file_server) — descobertos
  lendo o systemd unit e o Caddyfile reais, não confiando no doc de deploy.

## Interpretation

1. **Família "declarado ≠ verificado" ganha o 5º membro**: stamp, contagem, pin, linhagem — e
   agora *papel da linhagem* (espelho declarado vs produtor verificado). O padrão meia-instância
   do rhilo (2026-07-03) se repetiu em 48h noutra máquina: não é acidente do rhilo, é
   **propriedade emergente de qualquer checkout com um escritor acoplado** (lá, sessões Claude
   Code; aqui, o Agent SDK do bridge com bypassPermissions).
2. **Docs de deploy são declaração; o servidor é o verificado** — auditar o unit/Caddyfile antes
   de operar.
3. **Primeira feature nascida no mobile** é marco de autobiografia E aviso operacional: o bridge
   dá poder de escrita a qualquer lugar onde o maestro esteja — a rota de VOLTA desse trabalho
   (resgate manual via SSH hoje) é costura candidata se houver 2ª ocorrência (bridge commitando
   em branch `bridge/*` + sinal no inbox).

## Re-test (por classe: conditional)

Ao vencer `review_after` (ou antes, se o VPS mudar): (1) `ssh onion-vps` ainda conecta?
(2) `git -C /home/onion/onion-evolve status` limpo e na main? (3) health do bridge + site 200?
(4) o parecer do whatsapp-sender foi decidido/executado (branch ainda existe na origin?)?
Divergência em qualquer item → atualizar members.yaml e esta migalha, nunca re-carimbar.
