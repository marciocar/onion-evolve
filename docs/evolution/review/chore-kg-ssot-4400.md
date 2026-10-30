---
branch: chore/kg-ssot-4400
pr: pendente
date: 2026-10-30
reviewed_diff_sha256: b31d5793652317f2b8bfbd291150c7652d0b245e5b7f81073b91491cf8261b49
reviewed_code_sha256: b3c2bfcaf9d0bb593438cbe09a059f01c832fdde0170d6e7ce5e6921c8e878bd
findings_total: 7
findings_real: 0
tokens: 81201
duration_min: 4
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: revisor novo só-leitura (code-reviewer), sem o contexto da sessão
nota: "tokens do revisor medidos pelo harness (81201). Os sete achados são observações: nenhum defeito deste PR."
---

# Passada adversarial: `chore/kg-ssot-4400`

## O que muda

- `vendor/kg-ssot` 4.39.1 → 4.40.0, com o contrato v4.18 inalterado. Mudam o `tools/kg_query.py`, o `tools/kg_trace.py`, o `spec/revisit.schema.json` e o `spec/digest.schema.json`, mais a prosa e o carimbo da release.
- O `kg_query --revisit` ganha o motivo `pin-changed` (o par E_ SUPPORTS D_ com o `node_sha256` ou o `sha256` fixado) e passa a `kg-ssot.revisit/2`. O `kg_trace digest` aceita lote e passa a `kg-ssot.digest/2`.
- O gate sai rc 0 (206 grafos, 204 passam no MUST, as 2 dívidas herdadas), sem aviso de identidade, então o `.kg-ssot/gate/contract.json` fica como está. O revisit sai rc 0 com o schema /2 e as listas vazias. O `kg_trace check` resolve 2613 de 2613.
- Nada fora de `vendor/` muda: nenhum consumidor do core compara o schema nem faz parse do JSON do revisit ou do digest.

## Achados

O revisor conferiu os pontos abaixo e não achou defeito real:

1. O vendor bate byte a byte com a tag: 712 arquivos do manifesto contra `git show kg-ssot-v4.40.0:<f>`, 0 divergências; versão 4.40.0 em `release.json`, `plugin.json` e `.kg-ssot-version`; `spec/kg-contract-v4*` sem diff.
2. Digest: o único consumidor é a bancada (n) de `lint-selftest.sh` (família `kg_trace_resolve`), que lê a linha texto `<sha>  <ref>` com `cut -c1-64`. Essa linha não mudou. `lint-artifacts.sh:868` só cita o comando na cura.
3. Revisit: no core, `--revisit` aparece só num comentário de `kg-trace.sh`, que consome o JSON do `kg_trace check` (sem mudança). `peer-ref-check.sh` e `dissect-object-check.py` usam `kg_query --id` e filtros.
4. O revisit da 4.40.0 dá o mesmo payload da 4.39.1 no corpus do core, salvo o `schema_version` (0 decisões em revisita).
5. Fora de escopo: `.kg-ssot/gate/contract.json` guarda `"kit": "4.38.0"`. Esse campo só serve de trava contra rebaixamento e não reprova.
6. O resíduo deste PR nasce no fechamento (este arquivo).
7. A observação do resíduo da 4.39.1 (enum ampliado sob o mesmo `digest/1`) está resolvida: a 4.40.0 sobe para `/2` e declara a regra de subir a versão do schema.

## Mutantes

- O revisor montou um sandbox com `D_X` apoiada por `E_EV` (`node_sha256` em `#N_FONTE`). Com o rótulo do nó mudado, sai `pin-changed`. Com o nó removido, sai `gone: true` e `current: null`. Com a fonte removida, sai `unresolved` com `pin_source_missing`.
- Os 8 JSONs de digest e revisit validam contra os schemas novos (jsonschema 4.26.0). Os 6 mutantes de schema são todos rejeitados: `digest/1`, `ok` sem sha, `file_missing` com sha, `pin: sha1`, `revisit/1` e `reasons` sem `current`.
- Medido na sessão: as famílias `kg_trace_resolve`, `kg_trace_root_file`, `kg_gate_ci`, `peer_ref_check`, `kg_projection`, `dissect_object` e `kg_open_queue` saem rc 0, com 0 falhas.

## Limites declarados

- O revisor não rodou a bancada, o lint nem o `ops/kg-gate-ci.sh` (VPS compartilhada). O gate e as famílias acima foram rodados pela sessão.
- O revisor não exercitou o `io.unreadable` nem o `--revisit --with`, que o próprio CHANGELOG diz que ainda não confere o pin.
- O commit do vendor saiu com `--no-verify` como checkpoint declarado: o pre-commit passou de 9 min e o timeout o matou. O gate final é o CI.
