---
title: "Revisão — adopt: seed lê source_commit + 8c roda após o carimbo; fio do selftest vendorizado insatisfazível"
date: 2026-09-03
branch: fix/adopt-seed-stamp-and-order
reviewer: "condutor com medição do adotante (relatório do agente adotante 2026-09-02: pin '(não carimbado)' + mode/role zerados no grafo semeado; selftest vendorizado 19 ✗ por inventory_scope_excluded); bash -n no seed; lint --only rc=0 em adopt.md e seed (o 1º lint acusou vendor-scrub — id do adotante generalizado); radar exit 0 no fios-abertos; backlog LC_ALL=C"
reviewed_diff_sha256: eb72c0ef65ad4b73e802f6068b49fda6d85b1e446c02b4a26e60c949afbcdc78
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 25000
duration_min: 12
---

# Resíduo — REGRA 56

## Achados

1. **Chave errada**: `seed-adoption-graph.sh` lia `commit:` do stamp; `write-stamp.sh` escreve `source_commit:` —
   o pin saía "(não carimbado)" em **toda** adoção com carimbo correto. Cura: lê `source_commit` com fallback
   `commit`.
2. **Ordem de fase**: o passo 8c (semente do KG) rodava na Fase 3, antes do carimbo da Fase 5 — `mode`/`role`
   também saíam zerados. Cura: 8c movido para depois do `write-stamp` do install (o seed é never-clobber, não
   dá para re-rodar depois).
3. **Selftest vendorizado é insatisfazível no adotante** (19 ✗, causa estrutural em `inventory_scope_excluded`):
   vira `Q_SELFTEST_VENDORIZADO_INSATISFAZIVEL_NO_ADOTANTE` no `fios-abertos` com 3 opções e gatilho nomeado —
   não se corrige às cegas num PR de manhã.

## Não mudou

- Nenhum adotante existente foi re-semeado (never-clobber); o adotante que mediu corrigiu os 4 campos à mão.
- A cópia processada do sinal já continha os 3 achados.
