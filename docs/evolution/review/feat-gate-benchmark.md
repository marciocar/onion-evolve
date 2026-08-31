---
title: "Revisão — benchmark do gate + cura do selftest live-dependente"
date: 2026-08-31
branch: feat/gate-benchmark
reviewer: "números todos medidos nesta data com comandos declarados no doc; a cura do kg-backlog (c) re-dogfoodada pelo BLOCO EXTRAIDO com set -euo pipefail (via autorizada pelo proprio arquivo): fixture 7 nos -> enche a 21, TETO morde (rc=1, cita "teto declarado 20"); modo-de-falha provado pela rodada 1 da bancada (10/20, rc=0). Bancada COMPLETA estourou 10min 2x sob carga da VPS — declarado, nao escondido; veredito da bancada citado com as 2 reprovações explicadas, não escondidas"
reviewed_diff_sha256: 13bb96ff54b4c93fccc75ad3cc8ecae6b5546e34295fedd6d016591b12f5b1aa
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 0
duration_min: 25
---

# Resíduo — REGRA 56

I_BENCHMARK_DO_GATE (Onda 6): docs/analysis/onion-gate-benchmark-2026-08.md com latência (132s
sob carga / 16s histórico ocioso), 0 tokens, 63 regras, 6 catracas/84 chaves, 5 vetos reais no
dia, bancada 882/884. Achado real da passada: kg-backlog (c) assumia vivo-no-teto — curado em
lint-selftest.sh (fixture auto-suficiente, enche até teto+1 lido do arquivo).

## Colheita herdada da stack (registro canônico no resíduo da Onda 6)

Ids (para a guarda): W5_GESTAO_DE_BACKLOG I_R62_CATRACA_DE_PROJECAO I_GATILHOS_W2W3_REGISTRADOS_CEDO
Q_ONDA1_FECHA_COM_DELTA_DE_MORTALIDADE D_CENSO_190_EM_LOTES D_CENSO_VIRA_AMOSTRA_ESTRATIFICADA
C_BACKLOG_DE_DOCUMENTO_ORDENA_ITEM_MORTO C_ORDEM_DO_RADAR_NAO_E_ORDEM_DE_EXECUCAO
C_DECRETO_DA_COLHEITA_SUBMETIDO_AO_ELENXO C_A_METADE_DA_PROMESSA_QUE_E_FALSA
C_DISSENSO_ARQUIVAR_TROCA_PERDA_POR_PASSIVO D_MECANIZAR_A_PROMESSA_QUE_JA_ESTA_ESCRITA
E_O_RELOGIO_NAO_ESTAVA_ANDANDO E_A_ASSIMETRIA_ERA_INSINUACAO E_O_TETO_NAO_CAUSOU_DESVIO
E_NENHUM_KG_YAML_JAMAIS_FOI_DELETADO E_ARQUIVADO_TEM_PROJECAO_E_RELOGIO
E_A_ATENCAO_NAO_PROTEGE_CONTRA_MORTE E_O_GATED_E_A_METADE_QUE_FUNCIONA E_CUSTO_UNITARIO_DA_REVERIFICACAO
