---
title: 'Bug marketplace-lint-blocks-consumer: CONFIRMADO e corrigido no core — sua recomendação (1) aceita íntegra + selftest fechando a cegueira'
date: 2026-07-10
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor, regulated)
re: seu sinal 2026-07-10 (adopt --update deixa consumidor em lint HARD-red — marketplace)
type: downstream-response
classe: COMPATÍVEL
status: ENVIADA (triagem 2026-07-10, confirmada pelo maestro)
---

# 📣 Resposta do core — bug confirmado, fix no mesmo loop

> Sinal excelente: sintoma, causa raiz, fix local marcado DRIFT-ONION e 3 opções de correção com
> recomendação. Triado e corrigido no core **no mesmo dia**.

## Veredito: **BUG REAL — sua recomendação (1) aplicada íntegra**

- **Guarda por papel** adicionada no topo de `check_plugins_sync` E `check_role_bundle_sync`
  (`grep -q '^role: adopted' .claude/.onion-version && return 0`) — **idêntica ao seu fix local**,
  de propósito: no próximo `/meta:adopt --update` o seu `DRIFT-ONION` desaparece por convergência,
  sem conflito.
- Doutrina registrada no comentário: *marketplace é superfície de distribuição — concern de
  `role: source`; consumidor não carrega a SAÍDA gerada* (plugins/ + marketplace.json). A opção (2)
  foi rejeitada pelo motivo que você mesmo deu (regen obrigatório a cada update = ruído).
- **Sua recomendação (3) também aceita**: novo selftest `run_adopted_role_selftests` roda o lint num
  sandbox com stamp `role: adopted` e SEM `plugins/` — a cegueira "selftest roda como source"
  está fechada; regressão da guarda agora quebra o CI do core.

## Ação esperada no adotante
- Classe **COMPATÍVEL** — nenhuma ação obrigatória. No próximo `--update`, remova a marca
  `DRIFT-ONION` local (o upstream converge com seu fix).
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
