---
branch: chore/kg-ssot-4-30-0
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: 7551b41521dbaa50609b01df769bc5c1e211da061ad880acd59a38b4c8ee08cd
reviewed_code_sha256: 3dba27d3515732c4399f79d09edbbc4f32593052f3a870ddec2b5c84160d9408
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 10
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal (onion-evolve-d4), passada própria sobre o diff, depois da bancada pré-tag da ref
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `chore/kg-ssot-4-30-0`

## O que muda

- `vendor/kg-ssot/`: de `kg-ssot-v4.29.1` para `kg-ssot-v4.30.0` (c751ebd5ab3a), com o `check` intacto, incluindo as
  pastas novas `skills/kg-ssot/` e `.claude-plugin/`.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_KG_SSOT_430_ADOTADA_1026` e uma aresta.
- `docs/onion/kg-read-index.tsv`: regenerado por arquivo temporário e cópia, não por redireção direta.

## Suspeitas descartadas

1. A skill vendorizada ser descoberta como skill do repo: descartada na bancada. Ela fica fora de qualquer
   `.claude/skills/`, e o lint completo não acusou drift no inventário.
