---
branch: fix/pr-finalize-runs-kg-gate
date: 2026-10-14
reviewed_diff_sha256: 9be8b487e6a88ea684e96e70a6cd58f6e7e206685d017112bd30279217c9eaa8
reviewed_code_sha256: 997ad0154eb78c24f972e10a3e741300fc4cc4e3ead9b16ea7850eba43295a5e
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 30
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Dogfood do modo de falha com mutante (label de 540 caracteres num grafo rastreado) pelo pr-finalize --check
---

# O pr-finalize passa a julgar o commit também pelo contrato KG-SSOT, pela mesma invocação do CI

## O que aconteceu

O #1106 passou no pr-finalize (0 HARD) e reprovou no CI: um label de 538 caracteres subiu a dívida SHOULD
de um grafo, e a catraca dessa dívida é do `kg_gate.py`, que só o passo "Contrato KG-SSOT" do
`onion-validate.yml` rodava. O pr-finalize julgava o commit com o lint, não com o contrato.

## A cura

- `ops/kg-gate-ci.sh`: vendor check + `kg_gate.py` com os `--exclude` da base, num lugar só. O CI e o
  pr-finalize chamam o mesmo script; copiar a linha duplicaria os `--exclude`, que têm de casar com os da
  base (`.kg-ssot/gate.json`).
- O pr-finalize roda o gate na worktree do HEAD, depois do lint e antes do carimbo legítimo (`_DONE=1`), e
  também no `--check`. Custo medido: ~5 s.

## Passada adversarial

1. **A cura reprova o caso real?** Mutante: label de 540 caracteres num nó do grafo r9, stageado. O
   `pr-finalize --check` sai rc 1 com `✗ PIOROU debt.form.range.node.label: 2161 → 2162`; sem o mutante, rc 0
   com "contrato KG-SSOT verde".
2. **A mensagem de reprovação diz a causa?** Real, curado: o 1º filtro (`MUST|✗`) mostrava só as 16 linhas
   MUST herdadas e escondia o `✗ PIOROU`. Agora o recorte é `^✗` sem as linhas `(herdado)`.
3. **O CI mudou de comportamento?** O passo roda o mesmo vendor check e o mesmo `kg_gate.py` com os mesmos
   dois `--exclude`; só saiu do YAML para o script. Sem PyYAML/jsonschema o gate sai rc 2 e o pr-finalize para
   (nunca verde por ausência).
