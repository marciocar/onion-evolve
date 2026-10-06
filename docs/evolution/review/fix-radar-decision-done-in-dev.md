---
title: 'Resíduo — o radar avisa decisão done em DEV (MU-18)'
date: 2026-10-06
branch: fix/radar-decision-done-in-dev
reviewed_diff_sha256: c86e268bd6af401b13b09656e3a6158c88b7b5d29fdfc724354eaa91b13e11f2
reviewed_code_sha256: 13e3f4cba94c633e2040cc24c01c57be7c54163488fb14698b236fee93bf90b8
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 15
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Triagem do sinal do onion-slm (2026-10-06), item B, aprovado pelo maestro. A kg-grammar diz que `decision`
  só vira `done` verificada em PROD; o motor só rebaixava a atenção (DEV/done = 0,5), e as 20 mutações MU-18
  passaram sem aviso. Cura: aviso SOFT `decision-done-em-DEV` na seção de reconciliação do radar, AGREGADO
  (uma linha por grafo, com a contagem e até 5 ids), sem reprovar. A forma agregada vem de uma medição feita
  antes de forjar: o corpus tem 95 casos em 36 grafos (contra 763 em PROD), e 95 linhas por leitura
  ensinariam a ignorar o aviso. Bancada: caso (r1) na família seed (avisa D1 em DEV, cala D2 em PROD, rc 0).
  Mutante (o aviso desligado) morde. Famílias afetadas pelo radar: 333/0. O MU-07 (tipo de nó trocado) não é
  regra e fica como pergunta de pesquisa (o espaço do Onion SLM). Sem Elenxo, declarado.
---

# Resíduo — `fix/radar-decision-done-in-dev`

Depois do rebase sobre o #938 (que mexeu no mesmo radar e na mesma família), os plugins que embutem o radar foram regenerados — o 1º lint do commit acusou 4 HARD da REGRA 19 (Plugins de vertical (plugins/*) sincronizados com as fontes) por eu não ter regenerado. Revisado à mão.

Teto declarado: os 95 casos existentes não são corrigidos aqui; o aviso os torna visíveis, e a triagem deles
é por grafo (promover o plane com verified_at, ou voltar a open).
