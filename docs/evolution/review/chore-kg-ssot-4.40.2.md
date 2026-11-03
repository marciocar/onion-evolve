---
branch: chore/kg-ssot-4.40.2
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: e819d9c4a59b978dff02440d73c921e1f21f8995fd9128425fea69c5ed07abd7
reviewed_code_sha256: aee3dd3c8c219c6d64e666719277bca6d83c262814599ec589ba221796ba74f5
findings_total: 1
findings_real: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "sessão do core (passada inline; diff de vendor e da base do gate)"
nota: "tokens 0 = não medido (passada inline, sem subagente)."
---

# Passada adversarial: `chore/kg-ssot-4.40.2`

## O que muda

- `vendor/kg-ssot` 4.40.1 → 4.40.2 pela tag `kg-ssot-v4.40.2` (`4b7e74bb422f`), com o contrato v4.18 inalterado. Mudam o
  manual (formato, ferramentas, adoção e as versões pt-BR), o exemplo `cmed-dictionary`, CHANGELOG, ADOPTING, README e o
  carimbo da release. Nenhum schema nem ferramenta.
- `.kg-ssot/gate/contract.json` renovado por `bash ops/kg-gate-ci.sh --update`: o `"kit"` passa a `4.40.2`, e a base
  ganha o registro do grafo da rodada 22 do radar do Claude Code, que entrou na main sem registro.

## Achados

1. Hipótese: o commit da tag difere do candidato da bancada (`a7ce287f8a12`). Conferido: o gate com o vendor da tag
   deu rc 0, com «novos=0», e o vendor passou no `kg_vendor.py check`. Sem achado.

## Mutantes

Nenhum: não há código do core.
