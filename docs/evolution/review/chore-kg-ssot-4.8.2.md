---
title: 'Resíduo — o vendor do contrato KG-SSOT sobe para kg-ssot-v4.8.2, que só muda a saída'
date: 2026-10-18
branch: chore/kg-ssot-4.8.2
reviewed_diff_sha256: 44c31d803a9f37af7f21cbdb5aec1ef4a2e26852bb1a320a2482ed1f1a7de6bf
reviewed_code_sha256: 59d56ae09939e718131b0fbd963621cd549d26d41e12ed0910acae2b33f4850e
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  A 4.8.2 só muda a saída, segundo o kg-ssot, que mediu 844 grafos com MUST e SHOULD iguais aos da
  4.8.1. Mudam quatro coisas: o veredito do .kg.json traz a linha de cada ocorrência; a dica do
  integrity.orphan-node traz o id e a aresta que conserta; o --where ganha a linha da correção ("→");
  e a mensagem do verified-before-fact passa a dizer as duas leituras. Segui o roteiro do produto, com
  cada passo medido: um update só, porque o kit da 4.8.1 já grava o .gitattributes (rc=0, 356
  arquivos); git add; `check --index` rc=0; gate sem --update rc=0. O requirements.txt é igual ao do
  HEAD. Como a saída mudou, conferi quem a lê no core: nenhum script chama o --where (o kg_validate
  aparece no kg-contract-check.sh, no kg-decide-seal.sh, na bancada e no writer do MCP, e nenhum deles
  usa a opção). Rodei também as 17 famílias da bancada que usam o leitor do contrato ou o gate:
  428/428. Sem Elenxo, declarado: troca de vendor por pin, sem mudança de veredito, com o check do
  índice e o gate como prova executada.
---

# Resíduo — `chore/kg-ssot-4.8.2`

Teto: a garantia de "só a saída" é do produto; aqui ela foi conferida pelo gate (rc=0) e pelas 17
famílias que leem o contrato, não por uma comparação de veredito grafo a grafo.
