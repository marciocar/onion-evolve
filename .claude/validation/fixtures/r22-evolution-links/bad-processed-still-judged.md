---
title: fixture r22 — depois da TRIAGEM o link volta a ser dívida desta casa
date: 2026-10-02
---

# Sinal já triado, em _processed/

Referencia [um alvo inexistente](./nao-existe-alvo-r22-processed.md) — e aqui DEVE flagrar HARD.

Por que é `bad`: em `_processed/` o core já triou, o conteúdo virou registro desta casa, e link
quebrado deixa de ser conteúdo de terceiro e passa a ser nossa dívida. É o par que impede a cura do
escopo de virar buraco — sem este caso, alguém "simplificaria" excluindo `docs/evolution/inbox/*`
inteiro, `_processed/` incluído.
