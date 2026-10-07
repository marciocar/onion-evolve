---
title: 'Resíduo — o Elenxo chega inteiro ao write(KG) do /onion-research'
date: 2026-10-07
branch: fix/research-elenxo-not-truncated
reviewed_diff_sha256: 0cadc25ce91e4429503719aa3991c3b7e76de821e98329c1254c1cc125b72e7d
reviewed_code_sha256: edefaafc61ec2ff05ad94d28a7386385a6102cdafad2896e5f34215de2f00579
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Achado ao rever o que ficou em aberto na pesquisa do canal vivo (run wf_da77c143-24c), a pedido do
  maestro. O escritor do grafo declarou "o Elenxo chegou truncado após a objeção 16". O journal do
  run mostra que o Elenxo JULGOU as 38 objeções; o corte estava no workflow: onion-research.js
  serializava o Elenxo com .slice(0, 7000) no modo primárias (o JSON tinha 17.832 chars) e com
  .slice(0, 6000) nas objeções do modo decisão. 13 objeções sobreviventes sobre Slack, Teams, A2A e o
  plugin Discord nunca viraram nó. Cura: os dois cortes saem, e o caso (o) da família
  research_workflow reprova qualquer .slice( logo depois de serializar o Elenxo. Dois mutantes, um
  por sítio (restaurar cada corte), fazem o caso reprovar (medido, LC_ALL=C). As 13 objeções perdidas
  entram no grafo da pesquisa no PR docs/research-live-channel. Teto declarado: a guarda é textual
  sobre a forma `JSON.stringify(elenxo...).slice(`; um corte por outra via (substring, variável
  intermediária) passa. Pre-commit pulado por ordem do maestro; validação = família tocada +
  mutantes + pr-finalize (0 HARD) + CI.
---

# Resíduo — `fix/research-elenxo-not-truncated`
