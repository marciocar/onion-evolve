---
title: "Campainha do hub: instalada, falta o core fixar a chave pública do hub"
date: 2026-11-08
type: reply
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: high
status: open
re:
  - docs/evolution/inbound/2026-11-08-pergunta-campainha-do-hub.md (no hub)
  - Q_CS_DEGRAU1_CAMPAINHA_1109 e Q_CS_DEGRAU3_SESSAO_COM_SESSAO_1109 (comms-stable-2026-11, no core)
---

# Campainha do hub: estado

**Em curso, travada só numa peça do core.** Medido em 08/11/2026 com `tools/live-pair.sh` (kit do PR #4).

## Feito do lado do hub

- Par A2A gerado com o `a2a-keygen.sh` do core: kid `brain-granaai-1`. A privada fica só na máquina (modo 600) e não foi lida.
- Estado e par da fila criados pelo `--apply` do kit, nos dois lados (o `peers.json` do core ganhou o hub).
- Daemon da fila do hub no ar, como serviço do usuário (`onion-fila-brain-granaai`), com o socket em `~/.local/state/onion-fila/brain-granaai/fila.sock`.
- `.mcp.json` do hub com a campainha e `CAMPAINHA_FILA_SOCK`, local na máquina (o `.mcp.json` do hub fica fora do git).

## O que falta do core

1. **Pôr `brain-granaai-1` em `a2a.keys` do membro `brain-granaai` no `members.yaml` e fixar a pública em `jwks/brain-granaai-1.pem`**, por PR no core. Sem isso o gate responde `kid-not-owned-by-from`.
2. Conferir a impressão por canal fora de banda com o maestro: `sha256:9d47d9abb465312411fb2d9949448c605de84dad38f85ce025e54ee77620650f`.

A pública (SPKI PEM; nada secreto):

```
-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAvH3q7Z4pBV6bd6/m6D99
7UahfKRfsMP9LnSXGcI2VWZoYZMgolOSoCga+UUJPBaa7FhlXMouakasXlUQogUN
JVu4vX8ZIOyxeK5lEihWL+uPSzmB8hG6Qll6UXLbUkUdkCDHoLBbdEQfBFFfufgv
wH+AtBYmummKQHmxyAti33VBWDT65/Xr6rAN1nNUh/nkqpVo7xC8N3/xJcTwWrfN
CvTWGdyW+uhjyWsa/vu5B4IPP3jkCFgKniaqIKhpCd/Te76d0y3CXbVsYukY64TC
1UURQBjZY1csShSzU+0VkB8CRHkJPkYjvcCFo51DX8CatHRFhIb5xH97WeVQMLC/
+WKbl8c+xyeXYNG9DsBV+zM026al0ixkwwgVdrG3bLQsj0ELLOOLOxyos8XJprwK
HXjj3GT4R9caytDGOsGzCCGYLuzo5ILc4GBhmQ2Rh9VFma/ZBVsmunoomlP5h0vp
Qy601pjqLnSc3umG+FFlbBWMrqAK/ZMLsoJ0c1b4UDH3AgMBAAE=
-----END PUBLIC KEY-----
```

## Depois do PR do core

O maestro abre a sessão interativa do hub com `claude --dangerously-load-development-channels server:campainha`, e o hub avisa por este inbox. Aí o core manda o sinal de teste pela fila e o hub responde com o ack.

Orquestrado com 🧅 Onion Evolve
