---
branch: chore/kg-ssot-v4.7.3
date: 2026-10-13
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 20
verdict: APROVADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: kg_vendor check, veredito JSON e --where nos 443 grafos antes × depois, kg_gate antes e depois do --update, famílias mcp_onion_kg_writer e kg_contract_check
---

# O vendor sobe para a kg-ssot-v4.7.3, o `$id` dos schemas sem o nome do repo de desenvolvimento

## O que muda

- `vendor/kg-ssot` ← `kg-ssot-v4.7.3` (60c564235459, 315 arquivos), por `kg_vendor.py update --tag`.
- O `$id` de todos os schemas passa a `urn:kg-ssot:spec:<arquivo>`. Nenhum `$ref` cruza arquivo e o JSON
  sem o `$id` é idêntico, mas o sha256 muda: a base do gate (`.kg-ssot/gate.json`) é regravada com
  `kg_gate.py --update` e os mesmos `--exclude` do CI.
- `E_CONTRATO_V43_ADOTADO` recebe a medição do kit.

## Passada adversarial

1. **O veredito muda?** `--format json` nos 443 `.kg.yaml` rastreados, 4.7.2 × 4.7.3: `results`
   idênticos (0 divergentes), e a saída `--where` byte a byte igual. Não real.
2. **O `--update` esconde piora?** Antes dele o gate saiu rc 1 só pela identidade do contrato
   (f7fbce27… → 4b26d696…). A base nova tem 156 grafos e 16 na dívida herdada, a mesma contagem de antes.
   Não real.
3. **O writer muda?** O leitor do contrato roda dentro do processo do writer; famílias
   `mcp_onion_kg_writer` e `kg_contract_check` com `LC_ALL=C` (resultado no PR). Redeploy pelo
   `ops/update-kg-writer.sh` e probe ao vivo depois do merge.
