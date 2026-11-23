---
branch: fix/kg-provenance-private-cite-1123
pr: pendente
date: 2026-11-23
reviewed_diff_sha256: 129726e8b941cc1bb3a0f647860ff11238a2ff09cbe5642f62fd708b5dc4b570
reviewed_code_sha256: 73521fc6412d779ec2b63344e7d2749f303d998be6e14ce86e7b7400ea674089
findings_total: 1
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 5
findings_fixed: 0
verdict: APPROVED
elenxo: false
reviewer: "a sessão do core (autora), passada própria: mudança só de grafo, sem código"
nota: "acrescenta provenance a 2 nós decision done; o gate do grafo (radar --integrity --schema e contrato) rodou exit 0"
---

# Passada: `fix/kg-provenance-private-cite-1123`

## O que muda

Os nós `D_CHECK_DE_LINT_COM_CATRACA_E_LISTA_OFFLINE` e `D_VOCABULARIO_DO_NOME_NU_POR_TRES_FONTES`, do grafo da guarda de
citação de repo privado, nasceram `done` sem `provenance` (SHOULD do contrato v4). O kg-ssot mediu a subida de 157 para
159 avisos desde 8fb21e2 e apontou os dois. Cada um ganha `provenance` como testemunho da sessão do core na forja da
guarda (2026-11-10), citando as ordens do maestro que a narrative já registra.

## Achados

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | A autoria das decisões poderia ser do maestro, não do core | não | não | A narrative separa: o desenho é da sessão; o maestro deu duas ordens (aviso na citação nova; o número só cai), citadas no `method` |

## Conferido

- `kg-radar.sh --integrity --schema` rc 0 e `kg-contract-check.sh` rc 0 no grafo tocado.
