---
branch: fix/pr-finalize-runs-kg-gate
date: 2026-10-14
reviewed_diff_sha256: 6976c1b8cf83e99b7e4f4476acb3eb3139147d3c9bf89318a2730eaa8752942d
reviewed_code_sha256: 624930af847f7349a60ff0de1ffd2b81a3bcd824517681240e31a06abe0eb003
findings_total: 4
findings_real: 4
findings_fixed: 4
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
4. **O CI reprovou 9 casos da família `pre_push` (rodada 1).** O sandbox da família monta stubs do lint e do
   resíduo, e o motor novo chamava `ops/kg-gate-ci.sh`, que não existia ali (a classe "fail-closed expõe
   harness incompleto"). Real, curado: o sandbox ganha um stub do gate controlado por `kgverdict`, e um
   caso novo prova a recusa ("contrato KG-SSOT reprova o commit → rc 1 com a causa nomeada"). Família:
   49/0. Mutante (o motor sem a chamada ao gate): o caso novo reprova com rc 0.
5. **Por que a bancada não pegou antes do CI?** O commit foi `--no-verify` (checkpoint) e o `pr-finalize`
   rodou sem `ONION_FINALIZE_CHECKPOINT=1`, então o pré-voo das famílias tocadas não rodou. Erro de
   processo da sessão, não do motor; esta rodada fecha com a variável.
