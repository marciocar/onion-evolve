---
branch: chore/kg-ssot-4.19.0
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 20449a4e1e01b888b4a619e7d6c792f2660e0961cf21d3683f73d6690059e7ca
reviewed_code_sha256: acc4a9c99f1cc1f92872b0f887022b8076c7216525a6a3f4c08492cd35cbf58e
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 25
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada no próprio fork, sem subagente); o vendor é byte-idêntico à tag e o kg_vendor.py check sai rc 0"
---

# Passada adversarial: `chore/kg-ssot-4.19.0`

## O que muda

- `vendor/kg-ssot/` sobe de `kg-ssot-v4.18.0` para `kg-ssot-v4.19.0` (contrato v4.11, commit `b06659bba979` do
  espelho) pelo `kg_vendor.py update`; chegam `tools/kg_vocab.py`, `spec/vocab.schema.json` e `spec/vocab-examples/`.
- `.kg-ssot/gate/` regravada com `bash ops/kg-gate-ci.sh --update`: a identidade do contrato muda e os cinco grafos
  que melhoraram travam o ganho; entram também os registros das rodadas r15 e r16 do radar, que faltavam na base.
- `.github/workflows/onion-validate.yml`: o comentário do passo do contrato cita a tag e o contrato novos.
- `docs/onion/graph/sinais-de-campo-2026-09.kg.yaml`: `E_KG_SSOT_419_ADOTADA_1022` (a medição) e
  `Q_KG_MIGRATE_KEYS_NO_CORPUS_1022` (a migração de chaves fica com o maestro).

## Achados

1. O sinal da par dizia "cinco grafos saem do MUST". Medido pelo gate: cinco **melhoram**, mas só dois saem do MUST
   inteiro (doctrine-behavior-over-declaration e graduated-automation-elenxo); os outros três seguem com
   `top.kind`/`top.version` ou `provenance` faltante. O nó registra a medição, não o sinal.
2. Harness que copia o vendor avulso: o do kg-writer (`ops/mcp-onion-kg-writer/selftest.py`) copia o `spec/`
   inteiro (leva o `vocab.schema.json`) e o `kg_store` + `kg_i18n`; o `kg_store` da 4.19.0 importa só `kg_i18n` e
   `kg_validate`, que o harness já provê. Nada a curar; a família `mcp_onion_kg_writer` passou.

## Mutantes

- Não se aplica a vendor: o `kg_vendor.py check` reprova qualquer byte alterado. As famílias do kg (47, incluindo
  `kg_contract_check`, `kg_machine_path`, `plan_contract_migration`, `decide`, `mcp_onion_kg_writer`) rodaram com o
  vendor novo: 596 passaram, 0 falharam (LC_ALL=C, rc 0).

## Limites declarados

- O `kg_migrate.py keys` não rodou no corpus: renomear 76 chaves é decisão do maestro (nó aberto).
- A bancada completa fica para o CI; localmente rodaram as famílias do kg.
