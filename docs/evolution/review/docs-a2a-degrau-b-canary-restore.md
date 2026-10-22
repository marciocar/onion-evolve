---
branch: docs/a2a-degrau-b-canary-restore
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 4
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: sessao-principal
nota: >-
  Selo do maestro (D_DEGRAU_B_CANARIO_RESTAURA_NO_FIM_DO_LOTE_1022, via /meta:decide) e a emenda da
  frase do restore na §12.14. A passada mediu o plant-canaries.sh: o plantio recusa sandbox existente
  (l.53), então um restore sem --purge-sandbox impediria o replantio do A8. A emenda diz isso e manda
  o restore COM purge.
---

# Passada adversarial: `docs/a2a-degrau-b-canary-restore`

## O que muda

- Grafo do spike: nó `D_DEGRAU_B_CANARIO_RESTAURA_NO_FIM_DO_LOTE_1022`, gravado pelo
  `kg-decide-seal.sh` (radar `--integrity --schema` 0, contrato rc 0), ligado a
  `D_DEGRAU_B_A7_ANTES_DO_A8_COM_FOTO_LIMPA_1022`.
- `SPIKE-PROTOCOL.md` §12.14: a frase "o restore só vem depois do A8" fica riscada e emendada no
  mesmo dia, com o selo citado.

## O que a passada tentou refutar

- **Restore sem purge bastaria:** refutado pela l.53 do `plant-canaries.sh` (recusa sandbox existente).
- **A emenda reabre a ordem A7 → A8:** não reabre; o A8 continua exigindo a foto `--assert-clean
  --strict` LIMPA e o plantio antes dele, agora com sandbox novo.

## NÃO MEDIDO

O restore e o replantio reais na VPS: rodam no lote do maestro.
