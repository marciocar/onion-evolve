---
branch: feat/provisional-team-band
date: 2026-11-09
reviewed_diff_sha256: 754f059fabdfc02e41e504cb6c2c83f0ea86c7aa1db91ea659c79dff7fcad1fe
reviewed_code_sha256: 2799d45d4248ad2a82171331100e68b41e01fabfdc58ee0c42084845100a344d
findings_total: 13
findings_real: 13
tokens: 0
duration_min: 120
findings_fixed: 12
verdict: REJECTED_AND_FIXED
elenxo: false
elenxo_isolado: false
reviewer: "o próprio agente de execução, com mandato de refutar o diff; sem subagente (o brief proíbe criar agentes). Refutador independente reprovou o head 59b2ad09e; as curas deste head ainda não foram re-refutadas"
nota: "tokens = 0: não medido. O que sustenta: bancada (121 casos, 182 mutantes), 40 escritas reais conferidas por leitura separada, e a faixa exercitada contra o Linear real."
---

# Resíduo: faixa provisória do time e separação das retroestimadas

| # | Achado | Destino |
|---|---|---|
| 1 | Aplicar as 40 estimativas expôs defeito da cura anterior: 3 leituras logo após a escrita voltaram com valor velho, e o verbo acusou falha. | Curado: a releitura repete com pausa; caso e mutante próprios. |
| 2 | `not_calibrated` usava o status `insufficient_sample` e viraria faixa para ato humano. | Curado: status próprio; segue rc 3. |
| 3 | O acerto pedido no brief (85,7%) é da conta por categoria, não da faixa do time. | Curado: `measured_accuracy` mede a própria faixa. |
| 4 | Mutante de P80 trocado por P90 equivalente com 8 linhas; `age <= max_queue` era redundante. | Curado: fixture de 12 linhas; a cláusula saiu. |
| 5 | A faixa usa o tempo do time inteiro: as datas ficam dominadas por poucas horas de trabalho e por uma fila que acerta pouco com as abertas. | Limite declarado: 81,1% só concluídas e 48,2% a 57,0% com as abertas; o rc 4 e `calibrated: false` dizem isso a quem consome. |

## Refutador independente (head 59b2ad09e)

| # | Achado | Destino |
|---|---|---|
| 6 | `measured_accuracy` media a partir da criação, não a faixa servida. | Curado: simulação retroativa em 8 datas, publicada por `queue_basis`; o número antigo virou `from_creation_reference`. |
| 7 | `assumes_start_now` dava data com 0 de 42 de acerto. | Curado: só `work_hours_if_started_now`, em `provisional_work_hours_only`. |
| 8 | Ato humano sem pontos recebia faixa. | Curado: `not_calibrated` antes do ramo sem pontos; caso e mutante. |
| 9 | Categoria inexistente ganhava faixa. | Curado: rc 2. |
| 10 | `proposed` não dizia quando os pontos são retro. | Curado: `points_origin` e aviso. |
| 11 | `not_calibrated` fora do cabeçalho e do `estimate.md`. | Curado. |
| 12 | Data provisória não deixava marca em `due_date.set`. | Curado: `--provisional-note` grava comentário; falha é rc 1 nomeado. |
| 13 | Mutantes vivos: acerto por categoria, `with_open` temporal igual ao LOO, `REREAD_PAUSES` de produção. | Curado; o `gate na in` do refutador é equivalente, porque `not_applicable` retorna antes da porta. |

Limite: o caminho `conditional_on_age_in_queue` tem data e acerto medido baixo (ver PR). A data sai, declarada, com o aviso `low_served_accuracy`.
