---
title: 'Resíduo — o registro acompanha o pin do onion-curation, e o sinal de papel é arquivado como retratado'
date: 2026-10-08
branch: chore/curation-member-version
reviewed_diff_sha256: 169d9c3f43712ae62506986d01458c582b74c7e3ac42adcc9327f64025bc8011
reviewed_code_sha256: 2d00d2a2fb16ae09e66bba517493ac3e3164d7c0e7880e49e2744d54cccb0319
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Dois sinais do onion-curation, lidos inteiros. O primeiro (members-role-divergence) pedia alinhar o
  papel do registro (standalone) ao do carimbo (adopted); o segundo o RETRATA: registro e carimbo são
  dimensões distintas e o par standalone→adopted é permitido pela REGRA 92 (Papel da porta no registro
  concorda com o CARIMBO dela). Conferido no vivo: o door-role-parity-check.sh não acusa o onion-curation
  (a única violação dele hoje é o caso conhecido do clone granaai). Logo o papel NÃO foi alinhado, e os
  dois sinais vão para inbox/_processed (o primeiro como retratado). Feito o único pedido válido:
  onion_version do onion-curation no members.yaml de 5b529e980779 para 7818b8a25ae6, porque o PR #2 do
  adotante (o update) foi mergeado em 2026-10-08T15:08:00Z por merge commit, e onion/vendor é ancestral da
  main dele (merge-base --is-ancestor, medido). members-validate.sh rc=0. Nenhum .kg.yaml editado, logo
  REGRA 87 (PR que EDITA um .kg.yaml enxergou os confirmed dele) sem objeto. Sem Elenxo, declarado:
  atualização de registro medida. Pre-commit pulado por ordem do maestro; validação = pr-finalize + CI.
---

# Resíduo — `chore/curation-member-version`
