---
branch: feat/provisional-team-band
date: 2026-11-09
reviewed_diff_sha256: 5015374dce6ffc09f0e9cd3551475d97f39de85936c4a91c7ca8732c5187e030
reviewed_code_sha256: ad69e3de829a15bdaa24f94a6ba1ebb5c3209ed2a09ff48f3e5845444f58f527
findings_total: 5
findings_real: 5
tokens: 0
duration_min: 60
findings_fixed: 4
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes). A refutação independente cabe à sessão que encomendou"
nota: "tokens = 0: não medido. O que sustenta: bancada (106 casos, 155 mutantes), 40 escritas reais conferidas por leitura separada, e a faixa exercitada contra o Linear real."
---

# Resíduo: faixa provisória do time e separação das retroestimadas

| # | Achado | Destino |
|---|---|---|
| 1 | Aplicar as 40 estimativas expôs defeito da cura anterior: 3 leituras logo após a escrita voltaram com valor velho, e o verbo acusou falha. | Curado: a releitura repete com pausa; caso e mutante próprios. |
| 2 | `not_calibrated` usava o status `insufficient_sample` e viraria faixa para ato humano. | Curado: status próprio; segue rc 3. |
| 3 | O acerto pedido no brief (85,7%) é da conta por categoria, não da faixa do time. | Curado: `measured_accuracy` mede a própria faixa. |
| 4 | Mutante de P80 trocado por P90 equivalente com 8 linhas; `age <= max_queue` era redundante. | Curado: fixture de 12 linhas; a cláusula saiu. |
| 5 | A faixa usa o tempo do time inteiro: as datas ficam dominadas por poucas horas de trabalho e por uma fila que acerta pouco com as abertas. | Limite declarado: 81,1% só concluídas e 48,2% a 57,0% com as abertas; o rc 4 e `calibrated: false` dizem isso a quem consome. |
