---
title: 'Resíduo — o vendor do contrato KG-SSOT sobe de kg-ssot-v4.7.4 para kg-ssot-v4.8.0'
date: 2026-10-17
branch: chore/kg-ssot-4.8.0
reviewed_diff_sha256: 955b899d0a24d9707117edce6812261643902cef47ff9a79db2c5497062c9d6f
reviewed_code_sha256: b174b24e213e2e51f4fad3aba957ce4e21d74f8b1569fc4b09c81f117788c7d2
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Subida pedida pelo hook session-currency-check.sh, que mediu 4.7.4 → 4.8.0 pelo currency-census.sh,
  e anunciada pela sessão do onion-kg-ssot (tag em 3105a3d no espelho público). O caminho foi o da
  maquinaria: kg_vendor.py update --tag kg-ssot-v4.8.0 --source https://github.com/marciocar/kg-ssot
  (356 arquivos, check íntegro antes e depois), e depois ops/kg-gate-ci.sh com e sem --update. O
  gate saiu rc=0 sobre o contrato novo: o mesmo contract_sha256, nenhum código de dívida novo e nenhum
  grafo novo no MUST, o que confirma de forma independente o que o kg-ssot mediu. Por isso não houve
  --accept-regression. A base só recontou os grafos (156 → 175). O requirements.txt do leitor ficou
  idêntico, e o comentário do onion-validate.yml que nomeia a tag vigente foi avançado. O que muda na
  4.8.0 é o .kg.json como formato lido pelo kg_validate, pelo armazém e pelo MCP; o gate e as
  external_edges seguem só com .kg.yaml, e o core não tem .kg.json. Sem Elenxo, declarado: é a troca
  de um vendor por pin, com o verificador de integridade do próprio vendor e o gate do contrato
  como prova executada. A ratificação da release (D_KG_JSON_FORMAT_RELEASE_1016) é do maestro, no
  repo do kg-ssot, e não deste PR. ACHADO REAL, curado: a 4.8.0 traz duas fixtures de conformidade
  do perfil JSON com CRLF de propósito, e o `*.json text eol=lf` do .gitattributes do core as
  normalizava no índice. O motor avisou e eu medi: exportar o índice e rodar o kg_vendor check deu rc=1
  ("editado" nas duas), ou seja, um checkout novo como o do CI receberia um vendor quebrado. A cura é
  `vendor/kg-ssot/** -text` no fim do .gitattributes (vence a regra do *.json), com renormalize. Depois
  dela o mesmo export dá rc=0 com 356 arquivos íntegros; o estado de antes é o mutante e reprova.
---

# Resíduo — `chore/kg-ssot-4.8.0`

Teto: o gate julga a FORMA dos .kg.yaml. O .kg.json novo não tem consumidor no core hoje; quando
algum grafo do core passar a usá-lo, o gate do contrato ainda não o enxerga (fronteira declarada da
própria 4.8.0).
