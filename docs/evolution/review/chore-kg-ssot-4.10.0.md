---
title: 'Resíduo — o vendor do contrato KG-SSOT sobe para kg-ssot-v4.10.0'
date: 2026-10-20
branch: chore/kg-ssot-4.10.0
reviewed_diff_sha256: 472381ac9cdf4e8b0670992b5d61291be3970f906e7b9ab5ecb06f887b5ec06f
reviewed_code_sha256: 40c50aff430b25501da4fed14a55ee951af838b8625cd2881a04fbbdff817963
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 40
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  A 4.10.0 deixa o servidor MCP de referência pronto para produção: identidade, área e autor por requisição
  atrás de proxy, as duas eras do protocolo (2026-07-28 sem estado e 2025-11-25 com initialize), gate externo
  por comando (CommandGate, --gate-cmd, falha fechada, SIGTERM mata os gates em curso), imagem OCI do kg-mcp,
  paridade SHOULD caso a caso no leitor JS e dois casos novos de espaço em branco no trace. A passada
  adversarial mirou a frase "nenhum veredito MUST muda" da nota da release, e ela se sustenta por
  construção: o diff do vendor não toca os dois schemas do contrato, nem kg_validate.py, kg_gate.py,
  kg_vendor.py ou requirements.txt (git diff --cached --name-only vazio sobre os seis). Medi assim mesmo: o
  update deu rc=0 com 393 arquivos, o check --index deu rc=0, e o gate sem --update deu rc=0 com 177 grafos,
  161 no MUST e 16 na dívida herdada, os mesmos números do .kg-ssot/gate.json. A suíte da tag no leitor
  vendorizado deu latest 263/263. O kg-contract-check sobre os 53 grafos de docs/onion/graph deu rc=1, com
  12 reprovados, todos por dívida MUST herdada que a 4.9.1 já cobrava (a guarda exige MUST vazio também no
  arquivo rastreado) e nenhum código novo. O kg_store ganha só
  argumentos opcionais (gate= no GitStore, max_names= no write) e o CommandGate; o onion-kg-writer não usa
  nenhum dos dois, e a família mcp_onion_kg_writer passou. As 85 famílias afetadas deram 1030/0, e
  kg_contract_check, mcp_onion_kg_writer e kg_ssot_require_hashes deram 84/0. Sem Elenxo, declarado: é troca
  de vendor por pin, sem mudança de veredito, provada pelo check do índice, pelo gate e pela bancada.
---

# Resíduo — `chore/kg-ssot-4.10.0`

Teto: o onion-kg-writer de produção segue na 4.9.1 (served e store em b4600c34). Esta subida não o muda, e
o próximo deploy dele pelo `ops/update-kg-writer.sh` levaria o kg_store da 4.10.0, que só acrescenta
argumentos opcionais. Subir o writer é outra decisão.
