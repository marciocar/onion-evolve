---
branch: chore/kg-ssot-4.16.0
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: 0ece29164694c268d6c10a25c89e1e3189c9a31be3d1d56cc880c69468facd69
reviewed_code_sha256: a12b1949d3c04d79eaba453ded5acd62b5798fae6d8c7db5487518d56a148e19
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 8
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: sessão principal
nota: "tokens 0 = não medido; vendor por kg_vendor.py e base migrada pelo próprio gate"
---

# Passada adversarial: `chore/kg-ssot-4.16.0`

## O que muda

- O vendor vai da 4.15.1 para a 4.16.0.
- A base sai do `.kg-ssot/gate.json` e vai para a pasta `.kg-ssot/gate/`, com `contract.json`, `graphs/` e
  `accepted/`: 185 arquivos.
- Cinco comentários que citavam o arquivo passam a citar a pasta, e o `trace:` do nó `E_CONTRATO_V4_ADOTADO`
  passa a apontar para `.kg-ssot/gate/contract.json` (a REGRA 55 pegou o caminho movido; as `provenance.source`
  históricas, qualificadas por branch, ficam como estavam)

## Achados

Nenhum. Conferi:
- pelo `ops/kg-gate-ci.sh`, são 181 grafos e os mesmos 16 na dívida herdada, e o gate sai 0 depois do
  `--update`;
- o `git grep` do `gate.json` fora do vendor só acha comentários e docs históricos;
- a leitura de verdade é do `kg_gate.py`, que entende os dois formatos.

## Mutantes

Não se aplica.

## Limites declarados

- Os documentos históricos em `docs/evolution/inbox/_processed/` seguem citando o `gate.json`, de propósito:
  é o registro do que valia na época.
- O `docs/onion/kg-read-index.tsv` é projeção e se regenera no fechamento.
