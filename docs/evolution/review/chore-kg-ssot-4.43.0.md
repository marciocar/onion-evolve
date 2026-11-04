---
branch: chore/kg-ssot-4.43.0
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: a6ec0ce26efb9502d258d6ae2c4608ec40ce08e5e21eedec71ba16312586e772
reviewed_code_sha256: ddc1db16b451cad7487d5bce9cacab3849e0a9f6bf09f93c513a984dc5602230
findings_total: 2
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `chore/kg-ssot-4.43.0`

## O que muda

- `vendor/kg-ssot` 4.42.0 → 4.43.0 pela tag `kg-ssot-v4.43.0` (`3f6455711c7f`), da fonte pública. Segundo o dono, entram `kg_query --due`, o grau `degree.in.SUPPORTS=0`, `--has`, `--missing`, `label` no `--group-by`, `^=`, `*=` e `--chain` em lote.
- `.kg-ssot/gate/` renovado por `bash ops/kg-gate-ci.sh --update`.

## Achados

1. Hipótese: um script do core usar `--where` com operador inexistente, que agora sai rc 2. Conferido por `git grep` fora do vendor: a única chamada de `kg_query` com `--where` é uma citação em `.claude/commands/meta/backlog.md:55`, e nenhuma usa `!=`. Não confirmada.
2. Hipótese: algo no core ler `kg-ssot.query/1` ou `chains/1` e quebrar com as saídas novas. `git grep` não acha leitor fora do vendor. Não confirmada. O `--due` é o único a sair em `query/2`, segundo o dono.

## Mutantes

Não se aplica: atualização de vendor, sem guarda nova. O `kg_vendor.py check` dá o vendor intacto, e `ops/kg-gate-ci.sh` passa com 0 códigos novos.

## Limites declarados

O grep acha só chamada literal: nome montado em variável passaria. A recusa nova do MCP (`edges` com `open`, `in_narrative` ou `narrative`) não foi medida contra um cliente do core. A bancada completa é do CI.
