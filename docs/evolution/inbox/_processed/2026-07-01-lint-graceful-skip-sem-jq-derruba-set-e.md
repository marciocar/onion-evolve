---
title: 'Bug: lint-artifacts.sh — graceful-skip sem jq derruba o script (set -e)'
date: 2026-07-01
from: onion-adopt-granaai (consumidor / adopted @ 4332ac8d1884)
to: core (onion-evolve)
type: field-signal-bug
flow: upstream (consumidor→core / sinal de campo)
severity: HARD (bloqueia todo commit via pre-commit nativo em máquina sem jq)
---

# Bug — `lint-artifacts.sh`: guardas "pula gracioso" derrubam o script sob `set -e`

## Sintoma
Em máquina **sem `jq`** (WSL Ubuntu, adotante regulated), `bash .claude/validation/lint-artifacts.sh`
sai com **exit 1 e nenhuma violação impressa** — morre silenciosamente após `check_plugins_sync`,
antes do sumário. Como o adotante migrou o pre-commit para o hook nativo Onion (`core.hooksPath
.githooks`, que roda esse lint), **todo commit passou a ser bloqueado**.

## Causa raiz
O script tem `set -euo pipefail`. As guardas de skip usam `|| return` **sem argumento**:

```bash
command -v jq >/dev/null 2>&1 || return   # sem jq → pula gracioso (INTENÇÃO)
```

`return` sem arg herda o exit status do último comando — aqui `command -v jq` (falhou = 1). Como a
função é chamada como **statement solto** (não em `if`/`||`), esse `return 1` dispara o `set -e` e
**aborta o script inteiro**. A intenção documentada ("pula gracioso") é justamente o oposto.

Afeta **13 guardas** (padrão `<cond> || return`) em: `check_plugins_sync` (l.394-396),
`check_capability_conformance` (l.436), `check_graph_sync` (l.493-494), `check_claude_md_counts`
(l.516-517), `check_abstraction_methods_exist` (l.586-587,593), `check_inventory_total_drift` (l.761),
`run_inventory_fixes` (l.998). As duas de `jq` (396, 494) são as que disparam sem jq; as demais
(guardas de arquivo/vazio) têm o mesmo bug latente se a condição for falsa.

## Fix aplicado localmente (drift consciente — reconciliar no core)
`|| return` → `|| return 0` nas 13 ocorrências. Após o fix o lint roda até o fim: 0 HARD, exit 0.
(Diff no commit `fix(onion): lint graceful-skip sem jq + gerar inventory.md ausente` deste repo.)

## Recomendação ao core
Aplicar o mesmo `return 0` nas guardas de skip do `lint-artifacts.sh` upstream. Considerar cobrir no
`lint-selftest.sh` um caso "sem jq no PATH" para pegar regressão (o self-test provavelmente roda em
ambiente COM jq, mascarando o bug).

## Nota secundária (não-bug)
A adoção não gerou `docs/onion/inventory.md` (SSOT canônico) — o lint acusava ausência (única violação
HARD real). Gerado localmente com `inventory.sh`. Talvez a Fase 3 do `/meta:adopt` devesse gerar o
inventory.md (+ graph.md) no alvo, já que o lint nativo (agora pre-commit) os exige.
