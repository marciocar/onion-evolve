---
title: "Incidente de exposição de rede na VPS — Docker furando o ufw (contido)"
date: 2026-08-05
status: contido (contenção aplicada + persistida); follow-up durável pendente
scope: vps-shared-tools / segurança
host: srv1812846 (179.197.65.94, eth0)
kg: docs/onion/graph/onion-vps-consolidation-2026-08.kg.yaml
related:
  - docs/discussions/vps-shared-tools/SEED.md
  - docs/evolution/research/stack-harmonia-2026-08/
---

# Incidente — data stores expostos à internet (Docker bypassa o ufw)

## Achado (medido ao vivo 2026-08-05, não fabricado)

Na VPS `srv1812846` (`179.197.65.94`, iface `eth0`), a cadeia `FORWARD` roda `DOCKER-FORWARD`
**antes** das regras `ufw-*`, e o `DOCKER-USER` estava **vazio** → o DNAT incondicional do Docker
(`! -i docker0/br-*`, sem restrição de origem) entrega tráfego externo direto aos containers.
**O ufw (que só libera 22/2222/80/443/mosh) não protege nenhuma porta publicada por Docker.**

Exposto na internet (medido via `ss`, `iptables -t nat -S DOCKER`, e teste de auth por `/dev/tcp`):

| Serviço | Porta | Auth | Tenant | Severidade |
|---------|-------|------|--------|-----------|
| prodfiel-redis | 6390 | **`+PONG` — SEM SENHA** | prodfiel | 🔴🔴 crítico (RCE via `CONFIG SET`, roubo de dados) |
| onionfresh-redis | 6391 | **`+PONG` — SEM SENHA** | onionfresh | 🔴🔴 crítico |
| onion-adopt-arandek-redis | 6379 | `-NOAUTH` (tem senha) | arandek (cliente) | 🟠 exposto, autenticado |
| onion-adopt-arandek-postgres / test-db | 5438 / 5439 | aberto | arandek | 🟠 |
| onion-adopt-arandek-milvus / minio / attu | 19530 / 9090,9091 / 3007 | aberto (defaults fracos comuns) | arandek | 🟠 |

O WAHA (`onion-waha`) estava em **loopback** (`127.0.0.1:3999`) — nunca foi o vetor de rede; seu
risco é Classe B (`docker inspect`). **Correção de enquadramento (maestro):** o WAHA **não é
órfão a parar** — é o **WhatsApp padrão da VPS** (`onion-vps-waha`, keeper). O "docker stop" do
plano fica revogado; consolida-se: mantém rodando (loopback + a regra `DOCKER-USER` cobrem a rede)
+ renomeia p/ `onion-vps-waha` + migra segredos p/ `pass`; wiring SDAAL segue gated (dogfood-first).
Confirmar número dedicado (não pessoal) — cliente não-oficial tem risco de ban.

## Contenção aplicada (2026-08-05, reversível)

Regra global default-deny em `DOCKER-USER` para tráfego externo (`-i eth0`), preservando
established/related, loopback e container-a-container (via `br-*`, não `eth0`). **Não** toca
`INPUT` do host → ssh/mosh/Caddy intactos, zero risco de lockout. Nenhum `docker-compose` de
adotante foi alterado.

```
-A DOCKER-USER -i eth0 -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN
-A DOCKER-USER -i eth0 -j DROP
```

**Persistência:** `onion-vps-docker-firewall.service` (systemd oneshot `After=docker.service`,
idempotente, script `/usr/local/sbin/onion-vps-docker-firewall.sh`) — re-aplica no boot depois que
o Docker cria a chain. Sobrevive a reboot e a restart do daemon.

**Reversão:** `sudo systemctl disable --now onion-vps-docker-firewall.service` +
`sudo iptables -D DOCKER-USER -i eth0 -j DROP` (e a RETURN, e as v6).

**Sanidade pós-contenção:** onion-logto `healthy`, `app.onionevolve.com/health` → 200, loopback ok.

## Follow-up durável (decisão: conter agora, notificar depois)

1. **Cura durável (por-tenant, gated ao próximo toque no repo):** rebindar os `ports:` do compose de
   cada stack exposto de `0.0.0.0:<p>:<c>` para `127.0.0.1:<p>:<c>` — o padrão que o `onion-logto`
   já usa. A regra `DOCKER-USER` é a rede de segurança; o rebind é a correção na fonte.
2. **Notificar os donos:** **arandek** (cliente — prioridade), **prodfiel**, **onionfresh**. A
   exposição é dos serviços DELES; o achado + a cura de rebind devem ir downstream (co-announce/inbound).
3. **Confirmação externa** (opcional, definitiva): `nc -zvw3 179.197.65.94 6390` de um host externo
   (laptop do maestro) — confirma o bloqueio real e descarta edge-firewall Hostinger na frente.
4. **Auditar os demais `0.0.0.0`** não-data-store (node em 4011/4013/7003/8787, bun em 3100/4000/4310/4012)
   — a regra global já os cobre; avaliar se algum era intencionalmente público (via Caddy, não raw).

## Convenção de nomenclatura (decisão do maestro, 2026-08-05)

Ferramentas/serviços que são **do Onion e padrão da VPS** usam o prefixo **`onion-vps-`**
(ex.: `onion-vps-waha`, `onion-vps-logto`, `onion-vps-bridge`). Distingue de:
- `onion-adopt-<nome>-*` — stacks de adotante;
- nomes próprios do adotante (`prodfiel-*`, `onionfresh-*`).

Já dogfoodada no artefato de contenção (`onion-vps-docker-firewall`). **Renomes aplicados
(2026-08-05):** `onion-vps-waha`, `onion-vps-logto`, `onion-vps-logto-postgres`,
`onion-vps-bridge.service`. Método seguro: só `container_name` (dir/projeto/service-name mantidos →
volumes nomeados preservados, DB de identidade intacto: users=2/apps=10); refs `docker exec/inspect`
em `backup.sh`/`upgrade.sh` atualizadas; bridge via rename de systemd unit com verify+rollback.
Bug de dogfood corrigido: `onion-logto/up.sh` (`"${@:-up -d}"` → `set -- up -d`). Backups em
`*.bak-<ts>` nos repos e `/home/marcio/onion-bridge.service.bak-*`.
