---
branch: docs/duolingo-hlr-parked
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: 8ee7a5d8310478776d56be3b00924c9b6624c1ded56855e13a22d29e637c57ff
reviewed_code_sha256: 690c29c3dc766feb31146b223468a1e3ed508ec4dd39a89e0302b768e0f539f7
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/duolingo-hlr-parked`

## O que muda

- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `D_DUOLINGO_HLR_PARQUEADO_PARA_O_FRESCOR_DO_KG_1025`, o selo
  do core sobre o `D_DUOLINGO_B1_PARK` da curadoria, e uma aresta `TRACES_TO` ao
  `D_CANAL_CORE_KG_SSOT_FORMALIZADO_1023`, porque o gatilho é mudança no contrato.

## Achados

1. REAL, corrigido: o nó nasceu órfão (`integrity.orphan-node`). Ganhou a aresta ao canal core↔kg-ssot.

## Suspeitas descartadas

1. Citar o nó do par sem conferir: descartada. O `peer-ref-check` deu rc 0 na origin/main da curadoria
   (f591da2e2e44) antes do selo.
