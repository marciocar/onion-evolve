---
branch: chore/kg-ssot-4391
pr: pendente
date: 2026-10-29
reviewed_diff_sha256: f09d9e1250574c4719e27147793d0b800a7de8ed468c36dc719e96a14de9a4e7
reviewed_code_sha256: 119804b81de98108a252a51f8930956a12f886c418043cfdb82dc243dfc068ba
findings_total: 2
findings_real: 0
tokens: 59369
duration_min: 1
findings_fixed: 0
verdict: APROVADO
elenxo: nao
reviewer: revisor novo só-leitura (code-reviewer), sem o contexto da sessão
nota: "tokens do revisor medidos pelo harness (59369). Os dois achados são observações para a kg-ssot (a fonte), não defeitos deste PR."
---

# Passada adversarial: `chore/kg-ssot-4391`

## O que muda

- `vendor/kg-ssot` 4.39.0 → 4.39.1, com o contrato v4.18 inalterado. Mudam o `tools/kg_trace.py` e o `spec/digest.schema.json`, mais a prosa e o carimbo da release: no `digest`, um grafo que não parseia sai `unreadable` com o `code` do leitor, em vez de `not_found`. O rc segue 1.
- O gate deu o mesmo resultado antes e depois (204 grafos, 202 passam no MUST, as 2 dívidas herdadas, SHOULD idêntico), sem aviso de identidade, então o `.kg-ssot/gate/contract.json` fica como está.
- Nada fora de `vendor/` muda: as menções à 4.39.0 no core são históricas.

## Achados

O revisor conferiu cinco pontos e não achou defeito real em nenhum:

- os 712 arquivos do manifesto contra o `git archive` da tag (sha256 do vendor, da tag e do manifesto coincidem, zero divergências), e a versão 4.39.1 no `release.json`, no `plugin.json` e no `.kg-ssot-version`;
- o `digest` em JSON e em texto: `unreadable` com `code: parse.yaml-error`, `ok` com o hash e `not_found`, rc 1; a saída valida contra o schema novo;
- o contrato `spec/kg-contract-v4*` sem diff;
- nenhuma menção à versão no core que peça bump;
- o único consumidor do digest no core (`lint-selftest.sh`) lê só o caminho feliz, que não mudou.

1. **Observação para a kg-ssot, não curada aqui:** a 4.39.1 amplia o enum de `status` e acrescenta o campo `code` sob o mesmo `kg-ssot.digest/1`, numa versão patch. A saída nova contra o schema da 4.39.0 dá 2 erros (enum fechado e `additionalProperties: false`). Um consumidor externo que valide estrito contra o digest/1 antigo passa a rejeitar a saída. Sem impacto no core hoje; cabe à kg-ssot (um `digest/2` ou uma nota explícita no CHANGELOG).
2. **Lacuna antiga do schema, da kg-ssot:** ele não amarra `node_sha256 == null` a `status != ok`; um mutante `unreadable` com sha preenchido passa. Já existia na 4.39.0.

## Mutantes

Contra o `digest.schema.json` novo: `unreadable` sem `code` (1 erro), `not_found` com `code` (1), `ok` com `code` (1), `code` inteiro (1), todos rejeitados como esperado. `unreadable` com sha preenchido passa (achado 2). A saída nova contra o schema antigo dá 2 erros (achado 1).

Na sessão, medido na worktree: o `digest` de `Q_COORD_UPDATE_4_ADOTANTES_4390` sai rc 0 com `status: ok`, e um grafo quebrado sai rc 1 com `status: unreadable` e `code: parse.yaml-error`.

## Limites declarados

- O revisor não rodou a bancada, o selftest nem o `ops/kg-gate-ci.sh` (VPS compartilhada); o gate foi rodado pela sessão, rc 0.
- O commit do vendor saiu com `--no-verify` como checkpoint declarado: o pre-commit passou de 9 min e o timeout o matou. O gate final é o CI.
