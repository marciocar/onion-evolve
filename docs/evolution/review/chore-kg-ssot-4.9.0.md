---
title: 'Resíduo — o vendor do contrato KG-SSOT sobe para kg-ssot-v4.9.0, e o harness do writer volta a isolar a guarda de versão'
date: 2026-10-18
branch: chore/kg-ssot-4.9.0
reviewed_diff_sha256: e2c4d0aab1abc77dc03c03e786c3d4db049ee5bebc74a4ffd61a7413acd382db
reviewed_code_sha256: 7e0073b267e94f36ac41da513376e9efed7a593c532931813d7f3bcacb37d6f3
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 35
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A 4.9.0 traz canais de distribuição novos (PyPI, npm, MCP Bundle, MCP Registry) e, para o vendor, nenhum
  veredito muda. A referência passa a casar os regex por inteiro e deixa de emitir um código redundante
  num valor terminado em \n. O roteiro do produto, medido passo a passo: um único update (rc=0, 387
  arquivos), git add, check --index (rc=0) e o gate sem --update (rc=0); o requirements.txt ficou igual
  ao do HEAD. ACHADO, curado: das famílias que leem o contrato, uma reprovou: o harness do writer do MCP,
  no caso contrato-versao-desconhecida-recusa. O writer continuava recusando, sem gravar e sem julgar,
  mas o motivo mudou, e o mutante da guarda de versão do writer deixou de morder. A causa está no harness,
  não no produto: na 4.9.0 o kg_store.py valida o próprio veredito contra
  kg_validate._ROOT/spec/verdict.schema.json. O kg_validate falso copiava os globais do real, inclusive o
  _ROOT, e com isso o armazém lia o schema do vendor de verdade (só a versão 1) e recusava o /2 antes da
  conferência de versão do writer, que é justamente o que o caso exercita. A cura copia o spec/ real
  inteiro para o code root falso, abre só a versão no verdict.schema.json dele (como já fazia) e aponta o
  _ROOT do falso para lá. Uma 1ª tentativa afrouxava o motivo aceito; ela foi revertida, porque aceitaria a
  recusa do armazém no lugar da recusa do writer. Medido depois da cura: mcp_onion_kg_writer 65/65, com o
  mutante (m) mordendo de novo. Sem Elenxo, declarado: troca de vendor por pin, com o check do índice e o
  gate como prova, mais a cura de um harness provada pelo mutante que voltou a morder.
---

# Resíduo — `chore/kg-ssot-4.9.0`

Teto: a guarda de versão do writer agora só é exercitada porque o harness abre a versão no schema. No vendor
real o schema já exige a versão 1, e a guarda fica como defesa para o dia em que esse schema mudar.
