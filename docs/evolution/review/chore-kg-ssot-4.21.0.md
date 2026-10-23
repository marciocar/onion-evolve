---
branch: chore/kg-ssot-4.21.0
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: 2d5b61cbe35d4a04a1915f742ba172bf21e446e986a7eab046532a52070af65e
reviewed_code_sha256: 4546b833ae56e556bbecec2df7b5a01999e3b19554a68896878f0848104cc5f9
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 60
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; 1 achado é do vendor e foi reportado à sessão par, não curado aqui"
---

# Passada adversarial: `chore/kg-ssot-4.21.0`

## O que muda

- `vendor/kg-ssot` sobe de 4.20.0 para 4.21.0 (`ebd2e0ce1bc6`) pelo `kg_vendor.py update`; `check` rc 0. Entram o
  critério pré-registrado no contrato v4.12 (`x_criterion`, `x_measured_under`, `spec/criterion.schema.json`),
  `tools/kg_criterion.py` e o `kg_migrate nest` (`spec/kg-migrate-nest.schema.json`).
- `.kg-ssot/gate/contract.json` regravado pelo `ops/kg-gate-ci.sh --update` (a identidade do contrato mudou:
  `66547e10…` → `2b66689e…`). Contagem igual: 184 grafos, 182 cumprem o MUST, 2 de dívida herdada; SHOULD idêntico.
- `ops/kg-criterion-ci.sh` (novo, core-only): roda `kg_criterion.py check --root . --format json` e decide pelo rc E
  pelo JSON (forma esperada, findings e unreadable vazios), fail-closed: JSON ilegível, forma inesperada, rc 2 ou rc e
  JSON discordantes saem rc 2. O `ops/kg-gate-ci.sh` o chama depois do gate (vale no CI e no pr-finalize); o rc final é
  o pior dos dois, e 2 vence.
- Família nova `kg_criterion_ci` na bancada: (a) íntegro rc 0, (b) régua editada no lugar rc 1 com
  `integrity.criterion-digest`, (c) sha declarado errado rc 1, (d) sem vendor rc 2, (e) o gate chama o script.

## Achados

1. O leitor do contrato não calcula hash: a régua editada no lugar só é pega pelo `kg_criterion.py check`. Sem ligá-lo
   ao gate, a guarda da D_CRITERIO_PRE_REGISTRADO_NO_CONTRATO_KG_SSOT_1023 não valeria no CI. Curado com o
   `ops/kg-criterion-ci.sh` no `ops/kg-gate-ci.sh`. No core de hoje: `criterios=0 achados=0 ilegiveis=0`, rc 0.
2. Na bancada, `cmd; rc=$?` sob `set -e` abortava a suíte depois do caso (a). Trocado por `if …; then rc=0; else rc=$?; fi`.
3. Fail-open do VENDOR (não curado aqui): um `sha256` sem aspas e só com dígitos vira inteiro no YAML, o nó deixa de
   contar como critério e o `check` sai `criteria=0`, rc 0, sem aviso. Reportado à sessão par com a sugestão de um
   aviso de tipo. A bancada usa sha entre aspas e documenta o porquê.

## Mutantes

- Wrapper que ignora os achados (`sys.exit(0)` e sem a concordância de rc): (b) e (c) reprovam. Restaurado.
- O próprio caso (b) é o mutante da régua editada no lugar.

## Limites declarados

- O critério pré-registrado NÃO foi aplicado no A7 nem no SAC-151 neste PR (passo seguinte), e o `kg_migrate nest`
  não rodou no corpus (decisão do maestro).
- Bancada: 44 famílias do kg, door, decide e kg-writer, 619 passaram antes da cura do caso (c); depois,
  `kg_criterion_ci`, `mcp_onion_kg_writer` e `mcp_onion_kg` 93 passaram e 0 falharam. A completa fica com o CI.
- Um 1º run abortou com rc 127 porque eu editei o `lint-selftest.sh` enquanto ele rodava (o bash lê o script aos
  pedaços); refeito do zero depois.
