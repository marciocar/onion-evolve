---
title: 'Resíduo — radar E3 rodada 8 (2.1.290→2.1.295) e a REGRA 89 aceitando a forma de extensão do contrato'
date: 2026-10-08
branch: docs/radar-e3-r8
reviewed_diff_sha256: a8c92fe65e19b6e676dfe4de67ad01ab5aaf1f29f653072a5303e40262527db5
reviewed_code_sha256: 92724c183d721fcbf2de0e3504294a00dc8326e1098b38bfe0e640b7ca45fd2f
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 158870
duration_min: 25
verdict: CORRIGIDO
elenxo: sim
nota: >-
  /meta:radar E3 pedido pelo maestro depois da atualização do Claude Code (baseline r7 em 2.1.289,
  disco em 2.1.295). Delta de seis versões contíguas lido no CHANGELOG oficial (data/, conferido byte a
  byte pelo juiz) e cruzado com o vivo do core. Juiz fixo opus/high com mandato de refutar: 12 nós
  julgados, 4 REPROVA e 3 EXAGERA, todos corrigidos no grafo; o x_supersedes_external sobre a r7
  (E_MODS_FALHAM_ABERTO_NO_UPGRADE) foi REPROVADO, porque as correções de mod são evidência A FAVOR da
  tese da r7 e não superação, e virou x_supersedes_none com a razão; 12 itens que faltavam foram
  apontados e os 5 de maior impacto viraram nós (17 no total). Achado principal: onFailure: block nos
  hooks (2.1.295), que nenhum dos 20 hooks do Onion usa; ficou como Q_ADOTAR_ONFAILURE_BLOCK_NOS_VETOS,
  com medição ao vivo como condição. Cura feita no caminho: a REGRA 89 (Rodada de radar selada reconcilia
  o corpus que superou (Aufhebung), com catraca) exigia meta.supersedes_*, que o contrato v3 acusa como
  chave desconhecida, e toda rodada nova reprovaria no gate do CI; radar-aufhebung-check.sh passa a
  aceitar x_supersedes_* (casos d2 e d3 na família radar_aufhebung, e o mutante sem o prefixo reprova os
  dois); o /meta:radar documenta a forma x_. Baseline do E3 selada no mesmo commit (last_run 2026-10-08,
  cc_version 2.1.295). Grafo novo conforme ao contrato v3 (kg-contract-check rc 0) e radar
  --integrity --schema exit 0; nenhum .kg.yaml existente editado, logo REGRA 87 (PR que EDITA um .kg.yaml
  enxergou os confirmed dele) sem objeto. Pre-commit pulado por ordem do maestro; validação = família +
  mutante + pr-finalize + CI.
---

# Resíduo — `docs/radar-e3-r8`
