---
title: 'Bug: --update deixa consumidor em lint HARD-red (marketplace plugins/ + marketplace.json ausentes)'
date: 2026-07-10
from: onion-adopt-granaai (consumidor / adopted @ 74c470e35f17)
to: core (onion-evolve)
type: field-signal-bug
flow: upstream (consumidor→core / sinal de campo)
severity: HARD (bloqueia todo commit via pre-commit nativo em qualquer adotante com jq+python3)
---

# Bug — `/meta:adopt --update` deixa o consumidor em lint HARD-red (marketplace)

## Sintoma
Após um `--update` limpo (pin `4332ac8d1884` → `74c470e35f17`), `bash .claude/validation/lint-artifacts.sh`
no adotante acusa **12 violações HARD**:

- `plugins/onion-{compliance,design,docs,engineering,product,testing}` → "plugin ausente" (6)
- `utils/marketplace/roles.yaml` → vertical '…' "não registrado no marketplace.json" (6)

Como o adotante migrou o pre-commit para o hook nativo Onion (`core.hooksPath .githooks`, que roda esse
lint), **todo commit passa a ser bloqueado** — mesmo padrão do sinal `2026-07-01-lint-graceful-skip-sem-jq`.

## Causa raiz
O manifesto do `--update` (`want[]` em `meta/adopt.md`) vendoriza a **FONTE** do marketplace
(`.claude/utils/marketplace/` → `assemble-plugin.sh`, `verticals/*.manifest.sh`, `roles.yaml`) e o **lint
atualizado** que exige a **SAÍDA gerada** (`plugins/<name>/` + `.claude-plugin/marketplace.json`) — mas
**não** vendoriza nem gera essa saída (nem `plugins/` nem `marketplace.json` estão no `want[]`).

`check_plugins_sync` e `check_role_bundle_sync` pulam gracioso só por **ferramenta ausente**
(`assemble-plugin.sh`/`jq`/`python3`), **nunca por papel**. Como a fonte É vendorizada e a máquina tem
jq+python3, os checks **rodam** no consumidor e falham HARD. Um consumidor (`role: adopted`) **não
distribui plugins** — materializar 6 bundles de distribuição + `marketplace.json` no repo dele é ruído
(e regen obrigatório a cada mudança de vertical bloquearia commits recorrentemente).

## Fix aplicado localmente (drift consciente — reconciliar no core)
Guarda por papel no topo de ambas as funções:
```bash
grep -q '^role: adopted' "${REPO_ROOT}/.claude/.onion-version" 2>/dev/null && return 0
```
Após o fix: `lint-artifacts.sh` → 0 HARD, exit 0. (Marcado `DRIFT-ONION` no `lint-artifacts.sh` deste repo.)

## Recomendação ao core
Uma de:
1. **Guarda por papel** nos dois checks (skip em `role: adopted`) — marketplace é superfície de
   distribuição, concern do core (`role: source`), não do consumidor. (Foi o fix local.)
2. Ou incluir `plugins/` + `.claude-plugin/marketplace.json` no manifesto do `--update` (se a intenção
   for adotantes carregarem os bundles) — mas isso impõe regen a cada update.
3. Cobrir no `lint-selftest.sh` o caso "role: adopted sem plugins/" p/ pegar regressão (o self-test
   provavelmente roda como source, mascarando o bug — mesma cegueira do caso "sem jq").

Recomendo (1): mantém o consumidor enxuto e o marketplace onde ele pertence.
