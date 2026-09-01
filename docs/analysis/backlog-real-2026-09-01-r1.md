# Backlog REAL — /meta:census 2026-09-01

> Projeção do censo (SSOT = grafos-fonte). Teto: {'teto': 2000000, 'price_per_node': 88000, 'max_nos': 22}. Não-medidos-por-teto: 0 (nomeados abaixo).

**4 reais · 1 gatilho-disparado · 10 gated · 2 selos propostos · 5 re-medir · 0 fora · 93 frescos**


## 1 · REAIS + gatilhos DISPARADOS

- `D_QUADRO_CITACOES` (onion-doctrine-elenxo-bulbo-2026-07) — Decidir com o maestro se o quadro de citações graduou junto (vendorizar em KB e/ou publicar em /doutrinas/, espelhando o que já ocorreu com as cunhagens) ou se 
- `Q_A2A_SPAWNSYNC_BLOQUEIA_O_EVENT_LOOP` (m2-bridge-logto-2026-07) — Trocar spawnSync(bash, VERIFY, timeout:15000) por execFile assíncrono (promise) em src/a2a.ts:handleA2A, e adicionar middleware de rate-limit dedicado em app.po
- `Q_TESTEMUNHO_NAO_MEDIVEL_0804` (onion-identity-2026-07) — Adicionar campo opcional `evidence_class: testimony` ao schema de nós do KG e ensinar kg-radar.sh a excluir nós com esse marcador da contagem de "medível/fresco
- `D_pkce_risk_mitigations` (m2-bridge-logto-2026-07) — Decidir explicitamente e registrar: ou aplicar as 3 mitigações reais (CSP no Caddy do bridge + accessTokenTtl curto+rotação no logto-provision.sh + procedimento
- `Q_PIN_GREP_WORTH_IT` (arandek-adoption-dogfood-2026-07) — Rodar grep -rl "source_commit" nos adotantes reais (excluindo .claude/utils/*.sh, .claude/validation/*.sh e /_processed/ automáticos) e contar quantos são artef

## 2 · GATED (gatilho medido, não-disparado)

- `D_D5` — gatilho: Os 3 gates que travam a decisão completa: Q_instrument_value_per_adopter (fechado 08-30), Q_p4_interviews (zero P4 entrevistado) e Q_d2_l1l6_activatio
- `Q_SDAAL_EXECUTAVEL_ONDE_PARA` — gatilho: proposta de uma 2ª peça executável (script) dentro de .claude/utils/forge/ com consumidor não-LLM medido
- `D_spec_now_build_gated` — gatilho: 1º membro role:consumer (T2) real em members.yaml OU 1º contrato registrado em contracts/ (Q_gatilho) — mais o gatilho de negócio paralelo do ADR: 2º 
- `Q_FEDERACAO_VISIBILITY_GATE` — gatilho: qualquer retomada de regeneração de site/federacao/ (ou refresh do snapshot congelado em 2026-07-10/consagrado em cdd0363c)
- `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES` — gatilho: uma reetiquetagem nua (refuted/superseded sem aresta justificando) ou um rebaixamento de plane/impact sem carimbo aparecer no corpus real, capturado p
- `Q_CUSTO_DO_PORTE_NUNCA_MEDIDO` — gatilho: Maestro decide investir tokens no item M9 do menu da refinaria (medição retrospectiva do custo-do-porte 2026-05 + inventário do que se perdeu) — item 
- `Q_train_cert_chaining` — gatilho: 3+ engajamentos reais de treino/consultoria e/ou certificação fechados e registrados (precondição explícita do próprio nó para instrumentar a colisão 
- `Q_RADAR_WIDGET_PARALLEL_FORMULA` — gatilho: qualquer mudança nos fatores de status-factor.awk (a SSOT do motor, sítio único desde 2026-08-09) OU a 1a divergência observada entre RadarWidget.astr
- `C_dissent_auth_transversal` — gatilho: SE a dívida de integração ponto-a-ponto entre whatsapp/email/monitoramento se acumular ao ponto de o catálogo pagar mais do que pagaria uma fina camad
- `C_p4_gate_visibility` — gatilho: ≥1 federado migrado ao Logto consumindo recurso hospedado (ADR onion-adr-hosted-service-identity-2026-08, tabela de materialização, linha "Painel/admi

## 3 · PROPOSTAS DE SELO (flip é do maestro)

- `Q_tunneling` — O nó pede pesquisa+Elenxo comparando 4 providers concretos para decidir "para quê" e ligar ao downstream-by-pull. O vivo superou: a pesquisa (F2b-pesq
- `C_d3_comment_dup` — A claim original ("~40 linhas de template Unicode duplicado entre task.md e feature.md") não sobrevive à medição: task.md foi refatorado (não se sabe 

## 4 · RE-MEDIR (juiz reprovou)

- `Q_LACUNA_DECISAO_MAIS_CODIGO`
- `C_auth_logto_sdaal`
- `Q_COLD_ADOPTER`
- `Q_A_SENHA_DA_CHAVE_QUEBROU_A_AUTOMACAO`
- `Q_three_or_more_branches`

## 5 · FORA-DO-CORE


## 6 · FRESCOS (citados pelo carimbo)

- `D_spec_now_build_gated` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `C_reuse_readmodel` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `C_op_update` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `C_trust_matrix_stays_onion` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `C_op_promote` (m3-federation-admin-2026-07) — verified_at 2026-08-30
- `Q_gatilho` (m3-federation-admin-2026-07) — verified_at 2026-08-30
- `C_op_revoke` (m3-federation-admin-2026-07) — verified_at 2026-08-30
- `C_commodity_vs_diff` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `C_p3_agg_view` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `Q_members_ci_gate` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `C_p3_self_service` (m3-federation-admin-2026-07) — verified_at 2026-08-30
- `C_p4_audit_trail` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `Q_onprem_tension` (m3-federation-admin-2026-07) — verified_at 2026-08-30
- `C_p4_gate_visibility` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `Q_wake_session` (m3-federation-admin-2026-07) — verified_at 2026-09-01
- `D_D5` (d5-pricing-2026-07) — verified_at 2026-09-01
- `C_compliance_pack` (d5-pricing-2026-07) — verified_at 2026-09-01
- `C_sota_subscription` (d5-pricing-2026-07) — verified_at 2026-09-01
- `Q_d2_l1l6_activation` (d5-pricing-2026-07) — verified_at 2026-08-30
- `Q_p4_interviews` (d5-pricing-2026-07) — verified_at 2026-09-01
- `Q_train_cert_chaining` (d5-pricing-2026-07) — verified_at 2026-09-01
- `D_mais_valor` (company-brain-market-2026-07) — verified_at 2026-09-01
- `Q_p4_instrument` (company-brain-market-2026-07) — verified_at 2026-09-01
- `Q_ntenant_proof` (company-brain-market-2026-07) — verified_at 2026-09-01
- `C_NS1_KG` (onion-identity-2026-07) — verified_at 2026-09-01
- `Q_CUSTO_DO_PORTE_NUNCA_MEDIDO` (onion-identity-2026-07) — verified_at 2026-09-01
- `C_COMPLIANCE_RARE` (onion-identity-2026-07) — verified_at 2026-09-01
- `D_NO_DISTORT` (onion-identity-2026-07) — verified_at 2026-09-01
- `C_NS2_PORTABLE` (onion-identity-2026-07) — verified_at 2026-09-01
- `Q_FEDERACAO_VISIBILITY_GATE` (onion-identity-2026-07) — verified_at 2026-09-01
- `Q_TESTEMUNHO_NAO_MEDIVEL_0804` (onion-identity-2026-07) — verified_at 2026-09-01
- `Q_BRANCH_MAIN` (onion-identity-2026-07) — verified_at 2026-09-01
- `D_resource_plan_b` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `D_logto_same_protection_tier` (m2-bridge-logto-2026-07) — verified_at 2026-08-30
- `C_hono_registration_order_bypass` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `D_middleware_order_first` (m2-bridge-logto-2026-07) — verified_at 2026-08-30
- `C_docker_floor_gap` (m2-bridge-logto-2026-07) — verified_at 2026-08-27
- `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `D_logto_not_ssot` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `C_a2a_gate_narrow` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `Q_A2A_SPAWNSYNC_BLOQUEIA_O_EVENT_LOOP` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `Q_p10_mutation_not_run` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `Q_route_inventory` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `Q_docker_cgroup_driver` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `Q_signup_close_not_via_api` (m2-bridge-logto-2026-07) — verified_at 2026-08-30
- `C_console_autooff_gap` (m2-bridge-logto-2026-07) — verified_at 2026-09-01
- `Q_SDAAL_NAO_TEM_CONSUMIDOR_SEM_LLM` (elenxos-2026-08-07) — verified_at 2026-09-01
- `E_LINT_NAO_ENXERGA_WORKFLOWS` (elenxos-2026-08-07) — verified_at 2026-09-01
- `Q_SDAAL_EXECUTAVEL_ONDE_PARA` (elenxos-2026-08-07) — verified_at 2026-09-01
- `Q_GUARDAS_COERENTES` (guardas-revisao-2026-08) — verified_at 2026-08-30
- `Q_INDICE_DO_DIARIO_SEM_CATRACA` (guardas-revisao-2026-08) — verified_at 2026-08-28
- `Q_TRES_GRAFOS_NAO_SAO_YAML_VALIDO` (guardas-revisao-2026-08) — verified_at 2026-08-29
- `C_SEM_GATE_REGRA_SEM_TESTE` (guardas-revisao-2026-08) — verified_at 2026-08-30
- `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES` (catraca-regra49-2026-08) — verified_at 2026-09-01
- `C_MESMA_CLASSE_MUDA_DE_CAMPO_A_CADA_RODADA` (catraca-regra49-2026-08) — verified_at 2026-09-01
- `D_SCRUB_FROZEN_POISON_IN_VENDORS` (catraca-regra49-2026-08) — verified_at 2026-09-01
- `D_META_RADAR_DESENHO` (maestro-vivo-2026-08) — verified_at 2026-09-01
- `A_analysis_structure` (vps-shared-tools-2026-07) — verified_at 2026-09-01
- `ENT_monitoring` (vps-shared-tools-2026-07) — verified_at 2026-09-01
- `C_axis_tunneling` (vps-shared-tools-2026-07) — verified_at 2026-09-01
- `C_dissent_auth_transversal` (vps-shared-tools-2026-07) — verified_at 2026-09-01
- `Q_tunneling` (vps-shared-tools-2026-07) — verified_at 2026-09-01
- `E_SEGUNDO_ADOTANTE_MESMA_CLASSE_DE_EXPOSICAO` (identidade-onion-vps-2026-08) — verified_at 2026-08-30
- `Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` (identidade-onion-vps-2026-08) — verified_at 2026-09-01
- `Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` (identidade-onion-vps-2026-08) — verified_at 2026-08-30
- `Q_MAIS_UM_IMUTAVEL_GATED` (identidade-onion-vps-2026-08) — verified_at 2026-09-01
- `Q_ARANDEK_UPDATE` (arandek-adoption-dogfood-2026-07) — verified_at 2026-09-01
- `D_GREP_OLD_PIN` (arandek-adoption-dogfood-2026-07) — verified_at 2026-09-01
- `Q_PIN_GREP_WORTH_IT` (arandek-adoption-dogfood-2026-07) — verified_at 2026-09-01
- `Q_TENANT_WRITE_DESTINATION` (librechat-kg-runtime-2026-08) — verified_at 2026-09-01
- `Q_MAP_LEG_GATED` (librechat-kg-runtime-2026-08) — verified_at 2026-09-01
- `D_D2_activation` (gtm-decisions-2026-07) — verified_at 2026-08-30
- `Q_instrument_metrics` (gtm-decisions-2026-07) — verified_at 2026-09-01
- `Q_open_trigger` (gtm-decisions-2026-07) — verified_at 2026-08-30
- `Q_p4_no_field_proof` (gtm-decisions-2026-07) — verified_at 2026-09-01
- `C_GRANAAI_LINEAGES_UNKNOWN` (federation-health-2026-07) — verified_at 2026-08-30
- `Q_COUNTABLE_CRITERIA` (graduated-automation-elenxo-2026-07) — verified_at 2026-08-30
- `Q_PREDICTIVE_ALERTS` (graduated-automation-elenxo-2026-07) — verified_at 2026-08-30
- `Q_excecao_enterprise` (cafe-aroma-demo) — verified_at 2026-09-01
- `C_BOLETIM_INFORM` (constellation-dialogic-layer-2026-07) — verified_at 2026-09-01
- `D_ISOLATION_EXTENSION_GATED` (constellation-dialogic-layer-2026-07) — verified_at 2026-08-30
- `Q_MUDEZ_DA_GUARDA_NAO_SE_IDENTIFICA` (elenxo-mecanismos-lint-2026-08-13) — verified_at 2026-09-01
- `D_QUADRO_CITACOES` (onion-doctrine-elenxo-bulbo-2026-07) — verified_at 2026-09-01
- `Q_RADAR_WIDGET_PARALLEL_FORMULA` (onion-doctrine-elenxo-bulbo-2026-07) — verified_at 2026-09-01
- `Q_BULBO_DIAGRAM` (onion-doctrine-elenxo-bulbo-2026-07) — verified_at 2026-08-30
- `C_S4` (granaai-doctrine-absorption-2026-07) — verified_at 2026-08-30
- `Q_REVERSE_JOIN_SCOPE` (guardrails-2nd-pr-state-2026-07) — verified_at 2026-09-01
- `Q_automacao_pipeline` (kg-diagnose-design-2026-07) — verified_at 2026-09-01
- `Q_volume_not_reproduced` (vendor-multi-branch-2026-07) — verified_at 2026-09-01
- `C_d3_comment_dup` (onion-evolution-2026-07-30) — verified_at 2026-09-01
- `Q_orquestrador_gated` (kg-diagnose-automation-2026-07) — verified_at 2026-08-30
- `Q_ALARME_DE_AUSENCIA_DE_AGENDADO` (residuos-2026-08-18) — verified_at 2026-09-01
- `Q_live_narration` (kg-console-rich-design-2026-07) — verified_at 2026-08-30
