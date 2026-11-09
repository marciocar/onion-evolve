---
date: 2026-07-10
instance: onion-evolve
type: error
classification: public
tags: [vps, ssh, firewall, systemd, socket-activation, acesso, infra]
affects: [operations]
breadcrumb_for: [members.yaml, onion-core-home]
share_with: []
next_recommended: "2026-07-08-site-consolidation-vps"
review_after: 2027-01-12
conflict_class: dynamic
valid_when: "o acesso do maestro à VPS usa Port <porta-alternativa> no ssh config do notebook; a 22 segue aberta no servidor e o ssh é socket-activated (Ubuntu 24)"
---

## Signal
O maestro perdeu o acesso SSH/mosh à VPS a partir do notebook (o notebook dele): timeout +
`kex_exchange_identification: Connection closed by remote host`. Primeira hipótese (IP errado) caiu —
o IP estava certo. Segunda (firewall do servidor/provedor) caiu com evidência: porta 22 conectável
de 4 nós externos (check-host.net) e ufw/fail2ban limpos. Diagnóstico final: **a rede do notebook
filtra a porta 22 de saída via middlebox/DPI** (o 443 passa — o site abria normalmente de lá).

## Evidence
- `tcpdump` na eth0 durante retentativa: **0 SYNs** chegaram — o pacote morre antes do servidor.
- `check-host.net` TCP 22 e a alternativa: ✅ de todos os nós (CH/PT/SI/US/IR/UA) — servidor saudável.
- Fix: uma porta alternativa — `ufw allow <porta-alternativa>/tcp` + `Port <porta-alternativa>` em
  `/etc/ssh/sshd_config.d/10-alt-port.conf`; notebook com `Port <porta-alternativa>` nos aliases do ssh.

## Erro no caminho (a lição que vale a migalha)
Ubuntu 24 usa **socket-activation** no ssh: quem abre portas é o `ssh.socket`, e um **generator**
(`sshd-socket-generator`) lê os `Port` do `sshd_config` e regenera os `ListenStream` sozinho.
Criei um drop-in **manual** em `/etc/systemd/system/ssh.socket.d/` duplicando o que o generator já
tinha gerado → `Address already in use` → o restart falho **derrubou a 22 inteira** (~2 min de
downtime; só não virou lockout porque a sessão de trabalho roda local na KVM).

**Lei:** para porta extra de SSH em Ubuntu socket-activated: `Port` no `sshd_config.d/*.conf` +
`daemon-reload` (+ restart do socket quando necessário) — **nunca** drop-in manual de `ListenStream`
no `ssh.socket`. Antes de reiniciar o socket, conferir `/run/systemd/generator/ssh.socket.d/`.

## Re-test (ao vencer review_after)
1. `ssh -p <porta-alternativa> <alias-ssh>` ainda conecta do notebook? A rede ainda filtra a 22?
2. `/run/systemd/generator/ssh.socket.d/addresses.conf` ainda lista 22 + a alternativa?
3. Se a rede do maestro mudou e a 22 voltou a passar: avaliar fechar a alternativa (menos superfície).

## Re-testada em 2026-10-14: (dynamic, rodei no servidor) `/run/systemd/generator/ssh.socket.d/addresses.conf` lista 22 e a alternativa (v4 e v6); `sshd_config.d/10-alt-port.conf` tem `Port 22` e `Port <porta-alternativa>`; `ss -ltn` mostra as duas portas escutando; o ufw permite a alternativa; `/etc/systemd/system/ssh.socket.d/` não tem drop-in manual. NÃO verificado daqui: o item 1, o lado do notebook (a rede ainda filtra a 22?), porque exige a máquina do maestro.
