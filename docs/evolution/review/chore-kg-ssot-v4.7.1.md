---
branch: chore/kg-ssot-v4.7.1
date: 2026-10-13
reviewed_diff_sha256: 72c667a1aea2d3ba331d29651bd5279cd6d1a206ac6468f93f2c422b5965ca7f
reviewed_code_sha256: ae2a96ab418072177605b901dd45b9e5b44bfd2556e511bd208ba659d0d8be68
findings_total: 3
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 25
verdict: APROVADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: kg_vendor check, veredito JSON nos 443 grafos antes × depois, kg_gate do CI contra o main, famílias mcp_onion_kg_writer e kg_contract_check
---

# O vendor sobe para a kg-ssot-v4.7.1 e a opção E do processo de merge fica confirmada

## O que muda

- `vendor/kg-ssot` ← `kg-ssot-v4.7.1` (71d7375daf46, 313 arquivos), por `kg_vendor.py update --tag`. Mudam
  só `tools/kg_validate.py` (o atalho da libyaml recua para o parser puro apenas com escape de surrogate
  `\u` D800–DFFF ou `\U`, nó do produto `E_RISKY_SURROGATE_ONLY_1013`), `spec/release.json` e a superfície
  de doc. Schemas MUST e SHOULD com o mesmo sha256.
- `E_CONTRATO_V43_ADOTADO` recebe a medição do kit, como nos kits anteriores (o grafo está no teto).
- `C_OPCAO_E_REQUIRED_CHECKS_RULESET` passa a `confirmed`, com a leitura do ruleset aplicado pela API.

## Passada adversarial

1. **O veredito muda em algum grafo?** `kg_validate --format json` nos 443 `.kg.yaml` rastreados com a
   4.7.0 e com a 4.7.1: `results` idênticos, 0 divergentes. Não real.
2. **O gate do CI muda?** O comando do `onion-validate.yml` com os mesmos `--exclude`, rodado numa worktree
   de `origin/main` e nesta branch: rc 0 e saída byte a byte igual (156 grafos, 140 no MUST, 16 na dívida).
   Não real.
3. **O writer, que roda o leitor dentro do processo, muda?** Famílias `mcp_onion_kg_writer` e
   `kg_contract_check` com `LC_ALL=C` (resultado no PR). O redeploy pelo `ops/update-kg-writer.sh` e a
   probe ao vivo vêm depois do merge. Não real até prova em contrário.
