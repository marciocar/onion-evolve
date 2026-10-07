---
title: 'Resíduo — o check-member-registered lê o registro como YAML (comentário inline não vira mais FORA DO REGISTRO)'
date: 2026-10-07
branch: fix/member-check-reads-yaml
reviewed_diff_sha256: 720b5e85eb17f7ad5c44ade36c61e592464d1281c8dc355640abe800d9ef8419
reviewed_code_sha256: 5e468d88198b41d6fd9a7a534b7a5da3349b7266961aa3dc67579749d8c016b9
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Medido ao fechar as adoções (2026-10-07): o ops/audit-adopters-registry.sh dava 11 adotantes fora do
  registro, e 3 deles (o hub mais antigo, um adotante de cliente e o gmill) estavam REGISTRADOS. A
  regex do check-member-registered.sh ancorava no fim da linha e não casava `local_path` com
  comentário inline. Agora o leitor é o yaml.safe_load (o mesmo do members-validate.sh), com fallback
  por regex que tira o comentário. Bancada nova member_registered (a)(b)(c) — o checker não tinha
  nenhuma —, e o mutante (a regex antiga de volta) reprova (a). Depois da cura a auditoria dá 8 fora, e
  o maestro confirmou que os 8 são cópias mortas (não registrar). Sem Elenxo, declarado: troca de
  leitor por um que o repo já usa, com mutante.
---

# Resíduo — `fix/member-check-reads-yaml`

Teto: os 8 clones mortos seguem acusados pela auditoria até serem arquivados; ela mede o disco, não a
intenção.
