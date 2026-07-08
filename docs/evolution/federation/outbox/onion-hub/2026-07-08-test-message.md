---
title: 'Mensagem de teste — do fork de evolução ao hub público'
date: 2026-07-08
from: onion-evolve (fork privado de evolução / role:source local)
to: onion (hub público canônico — github.com/marciocar/onion)
re: validação de transporte manual fork→hub (sem doc-bridge configurado)
type: field-signal
classe: COMPATÍVEL
status: teste — não é uma decisão/contribuição real de framework
---

# 🧪 Mensagem de teste — fork → hub público

> **Ressalva de canal:** o hub público `marciocar/onion` **não é membro registrado**
> em `members.yaml` e **não há doc-bridge configurado** para ele. Este arquivo está
> na `outbox/` apenas como **drop-box de transporte manual** — a `outbox/` é
> nominalmente staging *downstream* (core→adotante), então este uso é fora-do-padrão
> e deliberado, só para o teste.

Sinal de teste originado no fork de evolução (`onion-evolve`), endereçado ao hub
público canônico. Não é uma contribuição real — existe só para validar que o
transporte manual (cola/PR) do fork para a porta canônica funciona.

Se você está lendo isto no `marciocar/onion`, o transporte **fork→hub** funcionou. 🎉

## Transporte (maestro)

Não há Carteiro-local para o hub (vive fora desta máquina). Transporte manual:

1. Copiar o conteúdo desta mensagem para o hub público — via `inbox/` do repo
   canônico (se ele tiver o canal), ou como issue/PR em `github.com/marciocar/onion`.
2. Após transportar, marcar como enviado movendo para `_processed/`:

   ```bash
   git mv docs/evolution/federation/outbox/onion-hub/2026-07-08-test-message.md \
          docs/evolution/federation/outbox/onion-hub/_processed/
   ```

> Auditoria canônica de anúncios reais é o `CHANGELOG.md` (append-only) — este
> rascunho de teste **não** entra lá.
