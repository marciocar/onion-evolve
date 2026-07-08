---
title: 'Mensagem de teste — canal upstream (inbox do core)'
date: 2026-07-08
from: mauriciomatos (maestro / sessão do core)
to: onion-evolve (core / role:source)
re: validação do canal upstream inbox/
type: field-signal
status: teste
---

# 🧪 Mensagem de teste

Sinal de teste depositado no `inbox/` do core para validar o canal upstream
do doc-bridge (`docs/evolution/inbox/`).

> Não é um sinal de campo real — não vira fix/feature/backlog. Existe só para
> confirmar que o depósito no canal, a contagem do hook "you have mail" (📬) e o
> fluxo de triagem (`git mv` → `_processed/`) funcionam ponta a ponta.

## O que fazer

Nada. Ao confirmar que o hook contou a mensagem, arquive movendo para
`_processed/`:

```bash
git mv docs/evolution/inbox/2026-07-08-test-message.md docs/evolution/inbox/_processed/
```
