---
title: 'Resíduo — o vendor do contrato KG-SSOT sobe para kg-ssot-v4.9.1'
date: 2026-10-18
branch: chore/kg-ssot-4.9.1
reviewed_diff_sha256: 0b295d26c56eea2d39fe9e7da5461656d604c5f86dbd0eb91fd253a86b19fad8
reviewed_code_sha256: 06cad7af4896a503a0e9e0bf87622f2bd3167a44f43d825d9b42a39de1fe71ef
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  A 4.9.1 traz o armazém no Windows (caminho próprio, nomes portáveis, --store-optional, saída UTF-8 em pipe)
  e a cura do _spec_home, proposta pelo kg-ssot depois do achado do harness do writer neste core: o
  kg_store, o kg_mcp e o kg_conformance passam a achar o spec/ pelo próprio caminho, e não mais pelo
  kg_validate._ROOT. Nenhum veredito muda. Segui o roteiro do produto e medi cada passo: um update (rc=0,
  387 arquivos), git add, check --index (rc=0) e o gate sem --update (rc=0); o requirements.txt ficou igual
  ao do HEAD. O caso que o kg-ssot pediu para conferir, contrato-versao-desconhecida-recusa no harness do
  writer, segue isolado com o _spec_home novo: mcp_onion_kg_writer deu 65/65, com o mutante (m) mordendo. O
  spec/ copiado pelo harness continua necessário, porque é ele que dá caminho ao kg_store copiado para o
  code root falso. As 17 famílias que leem o contrato ou o gate deram 436/436. Sem Elenxo, declarado: é
  troca de vendor por pin, sem mudança de veredito, provada pelo check do índice, pelo gate e pela bancada.
---

# Resíduo — `chore/kg-ssot-4.9.1`

Teto: as regras novas de nome do armazém valem para as áreas de dados do onion-kg-writer em produção, e esta
subida não muda o writer no ar. Medir /var/lib/onion-chat-kg antes de qualquer deploy dele é uma tarefa
registrada, e o deploy depende de pedido do maestro.
