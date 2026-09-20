---
title: 'Resíduo — o ciclo da porta rodou sem atrito, e isso é o registro'
date: 2026-09-20
branch: chore/pin-after-853
reviewed_diff_sha256: 084667dc5a5518ef36314a177ae9208d2c0cc11a8968f3c33e8d4abfc0c03119
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 2
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Dois números e um pin. A passada é a conferência contra a fonte viva — o carimbo publicado do repo
  da porta, lido do remoto. `elenxo: nao` declarado: não há superfície de execução a refutar.
---

# O que havia para conferir

**1. O pin bate com o publicado?**

```
$ gh api repos/marciocar/onion-core/commits/main --jq '.sha[0:7]'   → dc5d9e7
$ grep 86062a9141a7 docs/evolution/federation/members.yaml          → pin da 10a materializacao
```

O commit `dc5d9e7` é a materialização **do pin** `86062a9141a7` — o SHA do core que a porta espelha,
não o SHA do commit da porta. Os dois são diferentes por construção, e confundi-los seria o erro que
a REGRA 85 existe para pegar.

**2. A catraca fecha sozinha?**

```
$ bash .claude/validation/door-staleness-check.sh
onion-standalone  ok  395/395
onion-core        ok  0/0
```

**3. A porta estava limpa antes de subir?** Verificado no passo anterior: lint da porta **0 HARD**,
**0** termos de cliente com controle positivo de 293 arquivos casando `Onion`.

## A ordem que hoje virou rotina

O ciclo **materializar → push verificado no remoto → avançar o pin** rodou sem atrito desta vez, e é
a primeira em que isso acontece. A regra que o tornou possível nasceu ontem e anteontem, das duas
armadilhas opostas:

- **pin velho** esconde porta nova (2026-09-18);
- **pin novo** inventa porta publicada (2026-09-19/20).

> **As duas mentem; a diferença é a direção.** O pin só anda depois do `gh api .../commits/main`
> confirmar — nunca depois do commit local.

## Uma verificação que quase virou falso alarme

Ao conferir se as curas de hoje viajaram, o `grep` acusou `.githooks/pre-commit: No such file` na
porta. Ia registrar como *"cura que não viajou"*. Medi o outro lado antes: o template que o adotante
recebe (`githook-pre-commit-onion.tpl`) tem **46 linhas e não roda bancada nenhuma** — o gatilho que
curei é do hook **do core**, e é core-only por desenho.

> **Ausência esperada não é ausência defeituosa** — mas isso só se sabe medindo o outro lado.
