---
branch: chore/kg-ssot-4.22.0
pr: pendente
date: 2026-10-23
reviewed_diff_sha256: e943d40c8ea84b2acf7b7688838afe2e3111d44907f1acd7d30bfb763d7ba1d4
reviewed_code_sha256: caa397fcee45ac385fb41666c7fbee5144fe13bb6ee060aec670f2528d0c0f9f
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 25
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: "subagente da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos; adoção de vendor sem mudança de código do core"
---

# Passada adversarial: `chore/kg-ssot-4.22.0`

## O que muda

- `vendor/kg-ssot` 4.21.1 → 4.22.0 (`46f49dcc81fd`, 615 arquivos), `kg_vendor.py check` rc 0. Entram o
  `tools/kg_audit.py` (pacote de auditoria por pergunta), o `spec/audit.schema.json` e o `x_questionnaire.role` no
  SHOULD do contrato v4.13.
- `.kg-ssot/gate/contract.json` ganha a identidade nova do contrato (`d524a68f7d86…`) pelo `kg-gate-ci.sh --update`.

## Achados

Nenhum. Gate antes e depois igual: 184 grafos, 182 no MUST, 2 de dívida herdada, os SHOULD idênticos linha a linha
(diff vazio). `kg-criterion-ci.sh` rc 0 com 0 critérios e 0 achados. O core não usa `x_questionnaire`
(`git grep` fora do vendor não acha nada), então o enum novo não alerta em nenhum grafo, e o `kg_audit.py` no core
dá rc 0 com `items: []`.

## Mutantes

- Grafo que não se lê (`nodes: [` sem fechar) numa raiz temporária: o `kg_audit.py` dá rc 1 e lista o arquivo em
  `unreadable`, como a 4.22.0 promete. Não fica pacote incompleto em silêncio.
- Antes do `--update`, o gate já dava rc 0 com o aviso de identidade: a comparação decide o veredito, e a regravação
  só troca a identidade.

## Limites declarados

- Bancada só nas famílias do kg, do door e do decide (166 passaram, 0 falharam); a completa fica com o CI.
- O harness do kg-writer não precisou de cura: os arquivos novos do vendor não entram no corpus.
