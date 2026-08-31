---
title: "Revisão — superfície /meta:radar + REGRA 65 (percepção externa com baseline datada)"
date: 2026-08-31
branch: feat/meta-radar-surface
reviewer: "REGRA 65 provada por execução nos 4 modos (fresco silêncio / velho SOFT nomeado / ilegível HARD / vazio HARD); bancada nova run_radar_staleness_selftests 4/4 via harness com as opções do runner (bancada completa >10min sob carga — declarado); regenerações por gerador (inventory/graph/registry/backlog); contagens 107→108 varridas por grep"
reviewed_diff_sha256: 21329dadf8c934c380b8f459405b8683c328dd5eca272d4efa69de6f796d0c8f
findings_total: 13
findings_real: 13
verdict: APROVADO
tokens: 0
duration_min: 35
---

# Resíduo — REGRA 56

## Gatilho de versão (ordem do maestro, 2ª extensão)

"Sempre ver se as estratégias estão adequadas" a cada versão do Claude Code — MECANIZADO: a
baseline E3 ganhou `cc_version`; instalada ≠ rodada ⇒ SOFT nomeando as duas versões e mandando
rodar /meta:radar E3. Caso (f) na bancada (6/6); costura SDAAL: binário injetável por
ONION_CC_BIN (a 1ª versão furava no CI — command -v ignorava o stub; curado antes do commit).

## Passada Elenxo da Onda 6 (mandato REFUTAR, opus/high)

Vereditos: prova SUSTENTADA-COM-EMENDAS · benchmark SUSTENTADA-COM-EMENDAS (2 células erradas:
63→64 regras, 218→88+11 pontos de emissão) · **peça REPROVADA** (republicava veredito derrubado
em f2-confronto.json:327 — recorte + prior art aplicados) · REGRA 65 SUSTENTADA-COM-EMENDAS
(date -d GNU-only virava HARD contra o artefato → cadeia GNU/BSD/awk + degrade SOFT, caso (e) na
bancada 5/5). Todas as emendas aplicadas NESTE commit; objeções sobreviventes preservadas em
E_ELENXO_DA_PASSADA_ONDA6. Merge do lote: só até #738 (as emendas moram aqui no topo da stack).

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
