---
branch: feat/linear-estimates-velocity-meter
pr: 1554
date: 2026-11-09
reviewed_diff_sha256: e90b65c3f02674c74ed72a2c707157953617c8b7cab82e4ef23fdfda629eac5d
reviewed_code_sha256: 617166bf20e40971b3fe38c11c19689913486a1db21356688ff50fd558ba7069
findings_total: 22
findings_real: 22
tokens: 0
duration_min: 95
findings_fixed: 22
verdict: REJECTED_AND_FIXED
elenxo: false
elenxo_isolado: false
reviewer: "1ª passada: o próprio agente de execução. 2ª passada: refutador independente do head 941acfecd, que reprovou; as curas deste head são do agente de execução e ainda não foram re-refutadas"
nota: "tokens = 0: não medido. elenxo: false porque a re-refutação do head curado cabe à sessão que encomendou. O que sustenta são a bancada (79 casos, 109 mutantes), o backtest publicado no report e as reproduções do refutador refeitas."
---

# Resíduo: estimativa, prazo e medidor de planejado contra executado

Passada adversarial feita por quem escreveu, depois da bancada verde na primeira rodada completa de mutantes.

| # | Achado | Destino |
|---|---|---|
| 1 | O mutante da checagem de `hours_per_point` não mordia: a checagem da fila escondia a ausência dela. | Curado: o caso repete com `--queue-points`. |
| 2 | O mutante da forma `YYYY-MM-DD` não mordia: `date.fromisoformat` aceita `20261130` e o caso não o cobria. | Curado: valor entrou no caso. |
| 3 | O mutante do ano solto não mordia: os outros padrões cobriam todo ano do fixture. | Curado: fixture com ano solto. |
| 4 | A data partia da meia-noite mesmo sem `--today`, e podia sair um dia antes do possível. | Curado: parte do instante atual. |
| 5 | Lendo a amostra real, sobrou contagem de esforço (`3 rodadas de CI`). | Curado: padrão e caso novos. |
| 6 | A regra `eta` da bancada era engolida pela regra `beta`. | Curado no fixture. |
| 7 | A taxa de pontos usa só semanas com pontos, e a fila por velocidade sai otimista. | Limite declarado no campo `limits`. |

Limite que segue: o relógio é o do quadro, e 37 das 91 concluídas não têm `startedAt`. A mediana de 0,8 h mede agente, não pessoa.

## 2ª passada: refutador independente (head 941acfecd)

| # | Achado | Destino |
|---|---|---|
| 8 | CI: o `--project` quebrou a âncora do mutante `l-team` da bancada de arquivamento. | Curado: âncora nova, 27/27. |
| 9 | CI: a bancada nova enumerava providers sem citar zoho (paridade). | Curado. |
| 10 | Faixa descalibrada: `due_date` era p50 e somava marginais; dentro da faixa 31%, real acima do p75 em 38%. | Curado: soma por issue, estatística de ordem conformal, prazo no P80, backtest no `report`. |
| 11 | `propose` exigia contagem, não sinal: pontos inversos saíam rc 0. | Curado: spearman, erro e comparação com ignorar os pontos; rc 3. |
| 12 | `points_ahead_over_velocity` errava nos dois sentidos. | Curado: modo removido, porque não dá para testá-lo por backtest. |
| 13 | Categorias sobreajustadas: 28/83 abertas em `other`; `\bkg\b` casava `[kg-ssot ·`. | Curado: colchete fora do texto classificado, `large_other` olha as abertas, as issues apontadas corrigidas. |
| 14 | Data falsa com rc 0: concluída, cancelada, mãe de filhas abertas, iniciada há 30 dias. | Curado: `not_applicable` e `beyond_history`, com tempo decorrido condicionando os cenários. |
| 15 | 17 de 22 mutantes do refutador sobreviviam. | Curado: casos por recusa, relógio real sem `--now`, arquivadas, ordem e permissão da amostra. |
| 16 | Prazo comparado em UTC e não no fuso de São Paulo. | Curado: `--utc-offset`, padrão -3. |
| 17 | Lote só por minuto de calendário; `BATCH_CLOSE_MINUTES` morta. | Curado: cadeia de fechamentos a até 60 s. |
| 18 | «Relê» era o retorno da própria mutação. | Curado: leitura separada depois da escrita, exercitada na SAC-368. |
| 19 | `٣` aceito como 3. | Curado: só ASCII. |
| 20 | Timeout na leitura da resposta saía em traceback. | Curado: rc 1 com mensagem. |
| 21 | `--estimates-overlay` não aparecia na saída do `propose`. | Curado: `estimates_overlay`, também na recusa. |
| 22 | Nome de time igual a membro do registro na fixture; calibração em sobreviventes sem aviso no `report`. | Curado: nome neutro; `calibration_population` e aviso `survivors_only`. |

Já curados no head anterior: `--queue-points` negativo (a opção saiu), `depois de dd/mm` e `29/02`.

Resta: o relógio é o do quadro; depois de corrigir as categorias contra as abertas não sobra conjunto sem ver; leave-one-out cobre perto do nominal por construção, e o corte temporal hoje tem n=6. Issue velha na fila sai `beyond_history` com a data de "se iniciar agora".
