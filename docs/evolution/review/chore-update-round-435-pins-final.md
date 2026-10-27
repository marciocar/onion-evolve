---
branch: chore/update-round-435-pins-final
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: b1036cc80883c73b01d19ebe829837b704760eeb4989cf4fe0f90defda587b22
reviewed_code_sha256: ef6209b70ad2e860f36a7dd6133956820846e273516c33a6f67943445d0ab6bd
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, conferindo o --check depois do --seal e o estado de cada PR no forge; sem subagentes
nota: ""
---

# Passada adversarial: `chore/update-round-435-pins-final`

## O que muda

- `members.yaml`: kg-ssot, sge e brain passam de `fb36b24becfa` para `95365699a0e3`, carimbados por
  `ops/registry-pins.sh --seal` depois do merge dos PRs 285, 163 e 1648. A curadoria já estava em
  `95365699a0e3` pelo PR 1417.
- Grafo de coordenação: fecha `Q_COORD_UPDATE_4_ADOTANTES_4350`, a rodada da 4.35.0 aos quatro
  adotantes.

## O que a passada conferiu

- `ops/registry-pins.sh --check --only <id>` antes do selo: os três acusaram DIVERGE, com o vivo em
  `95365699a0e3` lido no remoto. A curadoria deu `ok`.
- `gh pr view` nos quatro PRs dos adotantes: MERGED.

## Achado (real, corrigido no adotante)

- O PR 1648 do brain entrou às 22:18 UTC com o campo `commit` do `vendor/kg-ssot/.kg-ssot-version` em
  `3960131ab70d`, que é a tag 4.35.0 no repo de desenvolvimento da kg-ssot. O brain vendoriza pelo espelho
  público, onde a mesma tag é `9fc22ac170d1`. A correção (`f03900257`) chegou à branch depois do merge e
  segue no PR 1652 do brain, que é o merge da sessão dona. O nó fechado o declara. A classe fica nomeada
  no resíduo do PR 1417: o carimbo não diz de qual remoto veio.
