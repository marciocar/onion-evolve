---
title: "Revisão — superfície /meta:radar + REGRA 65 (percepção externa com baseline datada)"
date: 2026-08-31
branch: feat/meta-radar-surface
reviewer: "REGRA 65 provada por execução nos 4 modos (fresco silêncio / velho SOFT nomeado / ilegível HARD / vazio HARD); bancada nova run_radar_staleness_selftests 4/4 via harness com as opções do runner (bancada completa >10min sob carga — declarado); regenerações por gerador (inventory/graph/registry/backlog); contagens 107→108 varridas por grep"
reviewed_diff_sha256: 25faab4f85f7437b55e94513324a634b3fb372a271cedb23bc82ae450e35d7d7
findings_total: 1
findings_real: 1
verdict: APROVADO
tokens: 0
duration_min: 35
---

# Resíduo — REGRA 56

I_RADAR_SURFACE (Onda 6): /meta:radar nasce maestro-invocado com baseline datada por eixo
(seed = rodada 0 do programa) e REGRA 65 no lint (SOFT por eixo vencido; ilegível/vazio = HARD
fail-loud). Path vendorizado: o merge desta superfície é ato do maestro. Achado da passada:
4 superfícies com contagem cravada 107 (onion.md ×2, warm-up, command-creator) — corrigidas;
a classe "contagem cravada fora da SSOT" já é coberta pela REGRA 16, que foi quem acusou.

## Colheita herdada da stack (registro canônico no resíduo da Onda 6)

Ids (para a guarda): W5_GESTAO_DE_BACKLOG I_R62_CATRACA_DE_PROJECAO I_GATILHOS_W2W3_REGISTRADOS_CEDO
Q_ONDA1_FECHA_COM_DELTA_DE_MORTALIDADE D_CENSO_190_EM_LOTES D_CENSO_VIRA_AMOSTRA_ESTRATIFICADA
C_BACKLOG_DE_DOCUMENTO_ORDENA_ITEM_MORTO C_ORDEM_DO_RADAR_NAO_E_ORDEM_DE_EXECUCAO
C_DECRETO_DA_COLHEITA_SUBMETIDO_AO_ELENXO C_A_METADE_DA_PROMESSA_QUE_E_FALSA
C_DISSENSO_ARQUIVAR_TROCA_PERDA_POR_PASSIVO D_MECANIZAR_A_PROMESSA_QUE_JA_ESTA_ESCRITA
E_O_RELOGIO_NAO_ESTAVA_ANDANDO E_A_ASSIMETRIA_ERA_INSINUACAO E_O_TETO_NAO_CAUSOU_DESVIO
E_NENHUM_KG_YAML_JAMAIS_FOI_DELETADO E_ARQUIVADO_TEM_PROJECAO_E_RELOGIO
E_A_ATENCAO_NAO_PROTEGE_CONTRA_MORTE E_O_GATED_E_A_METADE_QUE_FUNCIONA E_CUSTO_UNITARIO_DA_REVERIFICACAO
