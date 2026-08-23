# Backlog vivo — projeção dos grafos ⚙️ GERADO

> Gerado por `.claude/validation/kg-backlog-project.sh` a partir dos nós `status: open` da
> camada canônica (`docs/onion/graph/`) + grafos marcados. **Não editar à mão**: feche o
> item no grafo (status ≠ open, com carimbo) e ele sai daqui. Ordem = atenção (a régua do
> radar: impact × incerteza × status). **Sem corte** — nada fica invisível.

**508 itens abertos** em 29 grafo(s) com aberto (de 41 no escopo) · 29 grupo(s). A fila de decisão/execução do core; o topo por atenção é o que "custa caro estar errado".

## m2-bridge-logto-2026-07 — 46 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 119.0 | `D_gate_oidc_dual` | m2-bridge-logto-2026-07 | GATE OIDC DUPLO: 1 API Resource (https://bridge.onionevolve.com) + 2 clients. (a) HUMANO = SPA/Native PÚBLICO com Authorization C |
| 51.0 | `A_flip_steps_reversible` | m2-bridge-logto-2026-07 | PASSOS TURNKEY v3 (ordem LINEAR, cada um com rollback): P0 pré-flight (P0.1 systemd/Caddyfile · P0.2 ENUMERAR ROTAS · P0.2b ORD |
| 45.0 | `D_default_deny_routes` | m2-bridge-logto-2026-07 | DEFAULT-DENY (aprovado pelos verifies, PRESERVADO): o middleware É montado globalmente, mas existe uma ALLOWLIST ANCORADA do que  |
| 38.2 | `A_verification` | m2-bridge-logto-2026-07 | VERIFICAÇÃO v3 (23 provas; a v2 tinha 19). NOVAS/CORRIGIDAS: #3 prova do B1 (fix J); #12 PATH-TRAVERSAL — o MESMO corpus de 12 |
| 36.0 | `D_fail_closed_default` | m2-bridge-logto-2026-07 | FAIL-CLOSED (aprovado pelos verifies, PRESERVADO): BRIDGE_AUTH_MODE com AUSENTE = enforce; qualquer valor que não seja exatamente |
| 28.8 | `E_logto_live` | m2-bridge-logto-2026-07 | Logto self-hosted 1.41.0 VIVO em auth.onionevolve.com (OIDC, emite JWT assinado + JWKS) desde 2026-07-25 — mas SEM NENHUM CONSUM |
| 27.0 | `D_fix_ancestor_floor` | m2-bridge-logto-2026-07 | FIX A fecho — o conserto NÃO é mexer em Caddy/bridge (estão corretos no nível deles): é DECLARAR A PROTEÇÃO NO ANCESTRAL. |
| 25.6 | `D_resource_plan_b` | m2-bridge-logto-2026-07 | ESCADA A->B1->B2->B3 (aprovada pelos verifies, PRESERVADA) — PROVA ANTES do desenho depender (P4.1) + PLANO-B escrito: A = resou |
| 22.4 | `D_logto_same_protection_tier` | m2-bridge-logto-2026-07 | FIX D+A fecho — elevar Logto+Postgres ao MESMO patamar, agora em 3 CAMADAS (a v2 tinha 2 e a de baixo era decorativa): (1) /etc/ |
| 18.0 | `D_middleware_order_first` | m2-bridge-logto-2026-07 | FIX C fecho — EXIGÊNCIA no P5: app.use('*', requireIdentity) é o PRIMEIRO handler registrado, antes de TODA rota, de TODO app. |
| 18.0 | `D_path_canon_guard` | m2-bridge-logto-2026-07 | FIX B fecho — GUARDA DE CANONICALIZAÇÃO OBRIGATÓRIA (canonicalPath), fail-closed: (1) decodifica em laço curto (3 voltas, pe |
| 17.0 | `C_logto_now_critical` | m2-bridge-logto-2026-07 | O flip CRIA uma dependência dura que não existia (hoje o bridge compara uma string sozinho). Sob Logto-down: JWKS cacheado (cach |
| 14.4 | `D_proof_command_fixed` | m2-bridge-logto-2026-07 | FIX E fecho — e o 'fix óbvio' TAMBÉM não serve: jq -R 'split(\".\")�.[1]�@base64d�fromjson' FALHA IGUAL (medido: jq-1.7 imple |
| 13.5 | `C_hono_registration_order_bypass` | m2-bridge-logto-2026-07 | FIX C — no Hono a cadeia segue a ORDEM DE REGISTRO: um handler registrado ANTES do app.use('*', requireIdentity) responde SEM PA |
| 12.8 | `A_spec_turnkey` | m2-bridge-logto-2026-07 | SPEC TURNKEY M2 v3 (este doc, corrigido pelos 14 fixes A-N do 2º verify adversarial) — desenho do gate OIDC DUPLO + guarda de c |
| 12.0 | `C_p9_blocked_no_admin_oidc` | m2-bridge-logto-2026-07 | P9 NAO pode seguir 'na mesma janela do P8' como manda D_retire_legacy_immediately — ACHADO do flip (dogfood). Medido no server.t |
| 11.4 | `D_pin_jwt_algorithms` | m2-bridge-logto-2026-07 | ALG PINADO (aprovado pelos verifies, PRESERVADO): no jwtVerify (jose) do §3.3, fixar explicitamente algorithms: ['RS256'] (ou ['E |
| 10.8 | `C_docker_floor_gap` | m2-bridge-logto-2026-07 | GAP (impacto ELEVADO na v2+, porque o Logto virou caminho crítico): Logto+Postgres (docker) só têm teto duro. MEDIDO no cgroup: |
| 10.8 | `D_posture_anchored_correctly` | m2-bridge-logto-2026-07 | FIX G — a POSTURA (o maestro executa o flip de auth, a sessão especifica) se MANTÉM, mas ancorada onde de fato se ancora: (1)  |
| 10.8 | `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA` | m2-bridge-logto-2026-07 | PRE-EXISTENTE, mas o P11 ELEVOU O RAIO — e essa mudanca de risco precisa morar aqui: antes, numa queda do Logto, o caminho legad |
| 10.4 | `E_floors_effective_measured_20260729` | m2-bridge-logto-2026-07 | RE-VERIFY (kg-freshness 2026-07-29, medido read-only): o fix do teto de ancestral SEGUE EFETIVO. cat /sys/fs/cgroup/system.slice/m |
| 10.2 | `C_pkce_moves_credential_to_device` | m2-bridge-logto-2026-07 | FIX I — RISCO NOVO QUE A v2 NÃO NOMEAVA: com PKCE o material bearer passa a VIVER NO BROWSER DA PWA (localStorage por padrão n |
| 10.2 | `D_logto_not_ssot` | m2-bridge-logto-2026-07 | INVARIANTE herdada do M3: Logto = emissor/validador de identidade (commodity-BUY), NUNCA SSOT de autorização fina. A autorizaç� |
| 9.6 | `C_a2a_gate_narrow` | m2-bridge-logto-2026-07 | [ATUALIZADO 2026-07-27 pós-flip P7: a cláusula final CAIU — o bridge/PWA NÃO segue mais autenticado só por AUTH_TOKEN; /chat |
| 9.6 | `D_pkce_risk_mitigations` | m2-bridge-logto-2026-07 | FIX I fecho — mitigações BARATAS fixadas neste flip (P3.5): (1) ACCESS TOKEN CURTO 10-15min + ROTAÇÃO DE REFRESH TOKEN (Logt |
| 8.1 | `D_legacy_fn_defined` | m2-bridge-logto-2026-07 | FIX K — legacyAuthTokenOk() era USADA (v2:219) e NUNCA DEFINIDA: num spec turnkey, um placeholder no caminho de auth é onde o o |
| 8.1 | `D_steps_renumbered` | m2-bridge-logto-2026-07 | FIX F fecho — ORDEM LINEAR: P0 pré-flight -> P1 API RESOURCE -> P2 M2M APP (sem role ainda) -> P3 ROLE/PERMISSÃO (P3.1 criar r |
| 8.1 | `Q_seven_orgs_still_empty` | m2-bridge-logto-2026-07 | O MECANISMO esta provado, a POVOACAO nao: 1 de 8 organizacoes tem membro. As outras 7 precisam de pessoas reais com conta no Logto |
| 8.0 | `Q_resource_indicators` | m2-bridge-logto-2026-07 | LOAD-BEARING (não nota de rodapé): o aud-binding do §3.3 DEPENDE de o Logto 1.41.0 self-hosted honrar resource=<api-identifier> |
| 7.5 | `Q_a2a_after_flip` | m2-bridge-logto-2026-07 | FIX L1 — PROVA NOVA: na v2 o /a2a era 'CASO À PARTE' sem NENHUM teste, ou seja uma exceção sem verificação. Agora: o DEFAUL |
| 7.2 | `Q_A2A_SPAWNSYNC_BLOQUEIA_O_EVENT_LOOP` | m2-bridge-logto-2026-07 | PRE-EXISTENTE, achado pelo 6o Elenxo ao procurar 'outra rota cara fora do rate-limit': POST /a2a faz spawnSync do gate do core (a2 |
| 6.8 | `C_real_precedent` | m2-bridge-logto-2026-07 | NÃO é hipotético: precedente REAL de escrita de código de um celular por esse caminho (SDK bypassPermissions + git local no VP |
| 6.8 | `D_rbac_two_layers` | m2-bridge-logto-2026-07 | Corolário do grant duplo — com PKCE, sign-up ABERTO no Logto = qualquer pessoa vira usuário do tenant e passa em iss/aud. Fech |
| 6.0 | `Q_route_inventory` | m2-bridge-logto-2026-07 | VPS-DECLARADO: o inventário EXATO das rotas do app Hono só existe no host. A tabela do §3.4 é CONTRATO, não fato. P0.2 enumer |
| 6.0 | `Q_vps_declared` | m2-bridge-logto-2026-07 | VPS-DECLARADO ('o servidor é o verificado') — o que esta sessão NÃO mediu: valor real do AUTH_TOKEN vivo; systemd unit/Caddyf |
| 5.4 | `Q_source_correction` | m2-bridge-logto-2026-07 | FIX N — HIGIENE DE FONTE: o sinal citado por este spec (inbox/_processed/2026-07-25-logto-core-e-licao-do-pin-herdado.md) RECEBE |
| 5.1 | `Q_docker_cgroup_driver` | m2-bridge-logto-2026-07 | FIX L2 — PROVA NOVA no P0.6: a semântica de cgroup_parent DEPENDE do cgroup driver do docker. MEDIDO hoje: driver = systemd (h� |
| 4.8 | `Q_signup_close_not_via_api` | m2-bridge-logto-2026-07 | DIVIDA NOMEADA: o fechamento do registro do tenant `admin` (sign_up identifiers -> []) foi feito por SQL direto, nao pela API nem  |
| 4.2 | `Q_p10_mutation_not_run` | m2-bridge-logto-2026-07 | FRONTEIRA DECLARADA: o controle de mutacao (remover o filtro e reprovar que o canario passa) NAO foi rodado — exigiria desligar  |
| 4.0 | `Q_offline_fallback_truth` | m2-bridge-logto-2026-07 | NAO RESPONDIDO pelo ADR: hoje o correio funciona OFFLINE — o arquivo esta la e o adotante le quando quiser. Com pull, bridge for |
| 3.6 | `Q_gated_m3` | m2-bridge-logto-2026-07 | GATED (não neste flip): RBAC MULTI-OPERADOR / plataforma admin M3 (Logto Organizations só no gatilho 1º role:consumer real) — |
| 3.6 | `Q_pwa_sse_headers` | m2-bridge-logto-2026-07 | FIX M — MANTIDO E DESTACADO (§3.4d próprio, não mais nota de rodapé). LOAD-BEARING a confirmar (P0.3): EventSource NÃO perm |
| 3.4 | `C_console_autooff_gap` | m2-bridge-logto-2026-07 | GAP: console.sh só tem on/off/status manuais (medido: o case tem on) off) status) e mais nada; console desligado agora). Fecho: n |
| 3.0 | `Q_slices_2_to_4_unexercised` | m2-bridge-logto-2026-07 | As fatias 2-4 (Organizations = membros, org roles = tiers, convites, a2a por app) sao DESENHO, nao medicao. So a fatia 1 (um M2M a |
| 2.4 | `Q_default_api_resource_b1` | m2-bridge-logto-2026-07 | FIX J — o 'default API resource do tenant' era apresentado como FALLBACK PREFERIDO (B1) SEM VERIFICAÇÃO NENHUMA: tão VPS-DECL |
| 1.6 | `Q_byok_courtesy_mode` | m2-bridge-logto-2026-07 | INFERÊNCIA A VERIFICAR: a citação '2 modos cortesia-login + BYOK (X-Anthropic-Key)' vem do app-irmão onion-pessoal-app, NÃO d |

## m3-federation-admin-2026-07 — 19 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 64.0 | `D_spec_now_build_gated` | m3-federation-admin-2026-07 | SPEC-agora / BUILD-gated — especificar o command-side (mutação de members.yaml) + modelo de auth (Logto Organizations) SEM con |
| 18.0 | `C_reuse_readmodel` | m3-federation-admin-2026-07 | REUSAR o read-model já entregue: console HTML (F1.3), federation-radar (3 checks advisory), pin-integrity-check (gate real), grap |
| 17.0 | `C_not_backstage` | m3-federation-admin-2026-07 | ANTI-plataforma p/ N=8: Backstage/Port custam 3+ engenheiros + US$450k/ano e só compensam a 200-1000+ devs (S3·F1). A fronteira  |
| 15.6 | `C_auth_logto_sdaal` | m3-federation-admin-2026-07 | AUTH = fronteira gated (o BUILD não se pré-cozinha, gated-work-derives-fresh). Comprometido: só a fronteira §4.3 + a invariân |
| 15.0 | `C_op_register` | m3-federation-admin-2026-07 | OP-1 REGISTRAR (create): comando que escreve a entrada do membro no ledger seguindo o template comentado, reusando o pin já VERIF |
| 11.2 | `C_op_update` | m3-federation-admin-2026-07 | OP-3 ATUALIZAR (pin/trust/specializations/personality_summary): escrever onion_version novo (pós pin-integrity-check) e editar a  |
| 9.0 | `C_command_side_gap` | m3-federation-admin-2026-07 | GAP confirmado: existe read-model completo (SSOT + event-log + 3 read-views) e 1 gate de escrita determinístico (trust-topology-c |
| 8.4 | `C_op_promote` | m3-federation-admin-2026-07 | OP-2 PROMOVER (role: standalone→hub / consumer→T2): atualizar o campo role: no members.yaml do core. Hoje --promote-hub só re |
| 8.4 | `C_trust_matrix_stays_onion` | m3-federation-admin-2026-07 | RBAC do Logto (admin/member por org) é grosso demais p/ a matriz fina (can_receive_from/can_advise_to/can_correct_to/diary_readab |
| 7.0 | `Q_gatilho` | m3-federation-admin-2026-07 | GATILHO objetivo do build: o 1º membro role:consumer (T2) REAL em members.yaml (introduz hub-owner que precisa de visão/ação e |
| 5.8 | `C_op_revoke` | m3-federation-admin-2026-07 | OP-4 REVOGAR/DESATIVAR (status: retired / remover linhagem obsoleta): nenhum script/comando existe; o padrão observado é anotar  |
| 5.6 | `C_commodity_vs_diff` | m3-federation-admin-2026-07 | FRONTEIRA commodity-BUY (Logto) × diferencial-BUILD (Onion): comprar identidade/sessão/token/MFA/CRUD de org/Secret Vault (undif |
| 5.2 | `C_p3_self_service` | m3-federation-admin-2026-07 | REQ P3 (SHOULD condicional): self-service de onboarding multi-squad (mata a dor 'cada dev usa IA de um jeito; nenhuma trilha'). O  |
| 5.2 | `C_p4_audit_trail` | m3-federation-admin-2026-07 | REQ P4 (SHOULD condicional): trilha de auditoria legível/exportável das sessões e fases executadas (quem/quando/o quê) derivad |
| 4.8 | `Q_onprem_tension` | m3-federation-admin-2026-07 | TENSÃO M3 não-resolvida: comprador P4 regulado costuma exigir multi-ambiente/on-prem/auditoria de 3º × identidade Claude Code- |
| 3.6 | `C_p3_agg_view` | m3-federation-admin-2026-07 | REQ P3 (SHOULD condicional): visão agregada de adoção/consistência entre N repos/times DA MESMA empresa (multi-tenant no senti |
| 3.6 | `C_p4_gate_visibility` | m3-federation-admin-2026-07 | REQ P4 (SHOULD): relatório/export do histórico de decisões (decisions.md-like) por projeto/tenant — P4 valoriza 'evidência e |
| 3.3 | `Q_auth_decision` | m3-federation-admin-2026-07 | Plugar Logto no command-side é decisão do maestro, ainda NÃO tomada (o bridge hoje usa AUTH_TOKEN próprio, não Logto). Auth b |
| 2.0 | `Q_wake_session` | m3-federation-admin-2026-07 | GAP de design/dogfood aberto (não pesquisa): evoluir o receiver git-async para 'acordar a sessão' via SSE/webhook sem quebrar pu |

## federation-research-2026-06-reconciled — 319 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 37.5 | `G1_GATED_HANDSHAKE_DESIGN` | federation-research-2026-06-reconciled | Veredito de desenho: o handshake a2a-live gated mapeia input-required/auth-required ao gate do maestro e roda o pin-integrity-chec |
| 33.0 | `S1_DECISION_FEDERATION_TRANSPORT_ADAPTERS` | federation-research-2026-06-reconciled | Propõe federation-transport SDAAL com adapters git-async (default) � local (carteiro-local) � a2a-live (gated, SSE+webhook sobre  |
| 32.0 | `G3_DECISION_SINGLE_SOURCE_IDENTITY_MESH_COMMS` | federation-research-2026-06-reconciled | Decisão proposta (insumo ao maestro, não doutrina ainda): single-source para identidade/contratos (consistência forte, escritor |
| 27.2 | `B6_6_correction_backlog` | federation-research-2026-06-reconciled | Backlog de 10 itens de correção derivados do baseline (settings.json, .mcp.json, allowed-tools, frontmatter, symlinks, refatora� |
| 25.5 | `G2_DECISAO_MANTER_GATED` | federation-research-2026-06-reconciled | Insumo de decisão (não-doutrina): manter A2A/registry GATED e curar à mão é a postura que a própria evidência recomenda par |
| 25.5 | `GAPS_DECISION_A2A_LIVE_SIGNALS_ONLY` | federation-research-2026-06-reconciled | Decisão: o a2a-live (fase-2 gated) deve transportar só sinais gated, nunca conversas autônomas ou live-pull automático |
| 25.2 | `SY5_rfc0002_judged_trio` | federation-research-2026-06-reconciled | PROVA: o pacote inteiro já foi JULGADO — RFC-0002 (status accepted, 2026-06-22) aceita catálogo-first como doutrina, ratifica  |
| 24.3 | `S3_decision_catalog_hegel_system` | federation-research-2026-06-reconciled | Produzir catálogo verificado do sistema hegeliano (Q0a-e) em hegel-system.md antes de qualquer analogia Onion |
| 22.5 | `B5_15_ingestor_gap` | federation-research-2026-06-reconciled | Cadeia doutrina adotante→core está partida no meio: core não ingere doutrina estruturalmente (buraco central) |
| 22.5 | `B6_3_claim_sdaal_sem_ci_drift` | federation-research-2026-06-reconciled | Furo central do SDAAL: nenhuma guarda automatizada para spec desatualizada divergir do provider real (provider-drift) |
| 22.4 | `B6_11_decision_enabler_migalha_condicionada` | federation-research-2026-06-reconciled | Menor enabler dogfoodável recomendado: migalha estruturada com validade condicionada à query — campos conflict_class (dynamic/ |
| 21.2 | `B5_15_four_phase_plan` | federation-research-2026-06-reconciled | Plano de 4 fases: desbloquear → fechar write(KG) → construir o INGESTOR → 1ª federation.kg.yaml de produção |
| 21.2 | `B5_4_decision_autocommit` | federation-research-2026-06-reconciled | Recomendação #1 (agora): apply/--update auto-commita em branch dedicado (chore/onion-resync) com git commit --no-verify, absorve |
| 21.0 | `B5_7_recommendation` | federation-research-2026-06-reconciled | Recomendação da sala de design: aceitar a doutrina catálogo-first como ADR e materializar estendendo onion-patterns com 3-5 pla |
| 20.0 | `B5_12_decisao_profile` | federation-research-2026-06-reconciled | Direção F2: introduzir --profile kg�domain com vendoring mínimo do método |
| 20.0 | `G1_SIGNALS_ONLY_NOT_AUTONOMOUS` | federation-research-2026-06-reconciled | O a2a-live deve transportar só sinais gated (contrato/anúncio), nunca conversas autônomas IA-fala-IA nem live-pull — decisão |
| 19.6 | `B6_5_plan_refactor_sessions` | federation-research-2026-06-reconciled | Plano de execução faseado da branch refactor/sessions-worklog-protocol, que implementa as decisões desta revisão |
| 18.0 | `B4_11_decision_ns1_recommendation` | federation-research-2026-06-reconciled | Recomendação honesta (não decisão final): NS1 como norte, NS3 como hedge de caixa de curto prazo, com Q_COLD_ADOPTER como gate |
| 18.0 | `B5_7_action_requested` | federation-research-2026-06-reconciled | Ação pedida à sala de obra: reconciliar o material com o estado real de .claude/, rejeitar com evidência o que estiver errado, |
| 18.0 | `B6_13_decision_where_onion_lives` | federation-research-2026-06-reconciled | Decisão 1: onde o Onion vive em definitivo — merge no mainline, branch separada, ou reintegração via branch de integração |
| 18.0 | `S8_QuestionLensMeaning` | federation-research-2026-06-reconciled | O que \"lente\" significa nesta semente: abstração de acesso (a) ou camada de tradução/interpretação (b)? |
| 18.0 | `S9_q_radar_mechanism` | federation-research-2026-06-reconciled | Como desenhar o canal-radar de vigilância contínua sobre sinais externos de pesquisa (fora do próprio Onion)? |
| 17.5 | `B6_10_capability_contract` | federation-research-2026-06-reconciled | Capability contract: cada componente auto-descreve provides/requires/loads-condicional/conformance |
| 17.0 | `B5_1_mcp_sweep_decision` | federation-research-2026-06-reconciled | Decisão: varredura única MCP-first→API-first em comandos+agentes+templates, começando pelo template (fonte/propagador) |
| 16.0 | `B5_13_branch_roles_sdaal` | federation-research-2026-06-reconciled | Branch-roles como SDAAL: metodologia de branch generalizada — papéis abstratos (integração, staging, produção, linhagem-cli |
| 15.6 | `S2_DECISION_FEDERATION_TRANSPORT_SDAAL` | federation-research-2026-06-reconciled | Costura proposta: costurar federation-transport {git-async (default) � local (carteiro co-deliver/co-relay) � a2a-live (gated)} vi |
| 15.0 | `B5_8_open_onion_core_base` | federation-research-2026-06-reconciled | #3 onion-core: base plugin pendente para root commands (onion/warm-up/catch-up) + as 4 skills transversais — resolveria o gap do |
| 15.0 | `B6_3_decision_licenciamento_faseado` | federation-research-2026-06-reconciled | Monetização faseada: migrar MIT para BSL/dual-license agora, control plane hospedado sobre a Federação depois |
| 14.7 | `SY5_count_drift_ssot_closed` | federation-research-2026-06-reconciled | PROVA: o drift de contagem virou SSOT gerada + guarda mecânica — docs/onion/inventory.md tem header 'GENERATED BY .claude/valid |
| 14.7 | `SY5_profile_never_built` | federation-research-2026-06-reconciled | PROVA NEGATIVA: o --profile kg�domain do spike F1 não existe — zero ocorrências de 'profile' em .claude/commands/meta/adopt.md |
| 14.7 | `SY5_spec_as_run_not_absorbed` | federation-research-2026-06-reconciled | PROVA NEGATIVA: a pesquisa spec-as-code→spec-as-run→spec-as-all NÃO foi absorvida — 'spec-as-run'/'spec-as-all'/'Spec Growt |
| 14.7 | `SY5_verdict_leva5` | federation-research-2026-06-reconciled | Veredito da leva 5: 17 docs, ~2/3 do passivo já morreu em código sem ninguém marcar; o que sobra concentra-se em 3 fios reais ( |
| 14.7 | `SY6_ev_working_method_kb` | federation-research-2026-06-reconciled | KB integrada onion-working-method.md existe com as 3 camadas recomendadas (Seleção/Execução/Validação) + Disciplina + anti-p |
| 14.4 | `B6_13_decision_integration_branch_name` | federation-research-2026-06-reconciled | Decisão 2: reconciliar a branch de integração existente ou adotar nome limpo |
| 14.2 | `B5_8_status_draft_gated` | federation-research-2026-06-reconciled | Patch é rascunho NÃO aplicado — gated pelo smoke-test no goalflow antes de aplicar |
| 14.0 | `S4_DEC_TRANSPORT_SDAAL` | federation-research-2026-06-reconciled | Proposta: criar federation-transport SDAAL com git-async como default (menor superfície de ataque) e a2a-live como opção opt-in |
| 14.0 | `S5_decision_dogfood_kg_sdaal` | federation-research-2026-06-reconciled | Dogfoodar /meta:kg sobre um subconjunto real (os SDAALs) para provar que o grafo revela o que a prosa escondia |
| 13.6 | `B6_12_decisao_migalha_vencida_retestar` | federation-research-2026-06-reconciled | Toda migalha vencida (⏰) deve ser RE-TESTADA contra evidência atual, nunca apenas re-carimbada — antídoto ao erro auto-refor |
| 13.5 | `B5_8_patch2_orchestration_design` | federation-research-2026-06-reconciled | Patch #2: adicionar skill onion-orchestration ao manifest do onion-design (dependência funcional confirmada de design:generate) |
| 13.5 | `SYNTHESIS.md_GRAPH_SH_INGESTS_MEMBERS` | federation-research-2026-06-reconciled | graph.sh precisa INGERIR members.yaml — pré-requisito técnico único de baixo esforço/alto retorno que habilita targeting, co |
| 12.8 | `B5_12_decisao_zero_wiring` | federation-research-2026-06-reconciled | Direção F2: zero wiring de código, gate KG-apropriado via kg-radar |
| 12.8 | `B5_5_blocker_sdaal_aberto_claim` | federation-research-2026-06-reconciled | Blocker 🔴 vivo do /meta:evolve 2026-06-17: agent-creator-specialist.md guia listar ferramentas MCP sem steering SDAAL, novos ag |
| 12.6 | `SY4_open_dogfood_regulated_member_escopo` | federation-research-2026-06-reconciled | SEGUE ABERTO: o encaixe o membro regulado que os 4 streams desenharam em tabela ainda é PROPOSTA — o resolver existe, o dogfood |
| 12.6 | `SY5_adopt_durability_closed` | federation-research-2026-06-reconciled | PROVA: os Achados 1/3/4 de 07-08 morreram em código — .claude/utils/adopt/durable-commit.sh commita a entrega em branch dedicad |
| 12.6 | `SY5_mcp_first_leak_closed` | federation-research-2026-06-reconciled | PROVA: o vazamento MCP-first foi fechado na FONTE — agent-creator-specialist.md steera explicitamente para adapter SDAAL ('provi |
| 12.6 | `SY5_smoke_test_never_run` | federation-research-2026-06-reconciled | O smoke test do goalflow não deixou rastro de execução no repo (nenhum resultado, diário ou análise citando o veredito) — a |
| 12.6 | `SY6_ev_capability_contract_lint` | federation-research-2026-06-reconciled | Capability contract saiu da pesquisa para o gate: ADR aceito (2026-06-27) + lint REGRA 20 HARD valida o tier de conformance reivin |
| 12.6 | `SY6_ev_worklog_contrato` | federation-research-2026-06-reconciled | Contrato de sessão unificado: SSOT única em gitflow-patterns.md §Contrato de Sessão + KB worklog-protocol.md com worklog×tran |
| 12.5 | `B4_11_question_cold_adopter` | federation-research-2026-06-reconciled | Q_COLD_ADOPTER: existe qualquer pull dos diferenciais raros do Onion fora da órbita de Marcio? — o desempate de maior alavancag |
| 12.5 | `S2_question_federation_vs_orchestration` | federation-research-2026-06-reconciled | Q2 — 'federação de SLMs' é sobre trocar quem orquestra, ou é variação da federação de instâncias soberanas (repos-human |
| 12.0 | `B2_3_decision_encaixe_canonico` | federation-research-2026-06-reconciled | Recomendação do juiz adversarial: encaixar manifesto/experts/contratos/skill na estrutura canônica existente em vez de abrir PR |
| 12.0 | `B4_11_claim_demand_axis_not_onion` | federation-research-2026-06-reconciled | Contrapeso: a demanda de mercado provada é do EIXO (Company Brain, aposta YC 2026), não do Onion — zero adotante frio confirma |
| 12.0 | `B4_6_adopt_qualitative` | federation-research-2026-06-reconciled | Adotar qualitativamente já (custo ~zero): explicitar diversidade do panel e o gate orquestrar-ou-não na doutrina — candidato d |
| 12.0 | `B5_4_decision_vendor_branch` | federation-research-2026-06-reconciled | Recomendação #2 (depois): --update evolui para merge/rebase de vendor-branch onion/framework como fonte-de-merge, não branch-qu |
| 11.2 | `B5_5_precisao_match_question` | federation-research-2026-06-reconciled | Sub-blind-spot remanescente: o catálogo só funciona se os gatilhos de 'reconhece-quando' forem precisos — match errado aplica  |
| 11.2 | `SYNTHESIS.md_SINGLE_SOURCE_MESH` | federation-research-2026-06-reconciled | Recomendação: manter SSOT single-source para identidade/contratos e federar só a comunicação via mesh git-async (+a2a-live ga |
| 11.2 | `B2_5_claim_unresolved_gaps` | federation-research-2026-06-reconciled | Gaps que o landscape diz que ninguém resolve (segurança adversarial em fan-out, break-even de custo, reprodutibilidade regulada) |
| 11.2 | `B5_11_g2_tier_kb_nao_circulante` | federation-research-2026-06-reconciled | G2 aberto: KB com confidentiality INTERNO (case-studies de adotantes reais) shipou para o door — vendoring não distingue doutri |
| 11.2 | `B5_6_gate_dependencia_doc1` | federation-research-2026-06-reconciled | Não implementar catálogo antes de a doutrina do Doc 1 ser reconciliada |
| 11.2 | `B6_14_opcao_c_gated` | federation-research-2026-06-reconciled | Eixo SDAAL messenger reconhecido como capacidade futura mas gated (nasce só com gatilho real, spec-first) |
| 11.2 | `B6_7_decisao_trial_regua_no_skill` | federation-research-2026-06-reconciled | TRIAL camada 1: materializar a régua P0-P3 como seção no onion/SKILL.md, estendendo o skill existente em vez de criar um 8º á |
| 11.2 | `B6_8_decision_team_gated` | federation-research-2026-06-reconciled | Decisão: modo EQUIPE (handoff versionado HANDOFF.md, hook bidirecional, role detection intra-repo) fica GATED até o 1º caso rea |
| 10.8 | `B5_1_inventory_command_decision` | federation-research-2026-06-reconciled | Decisão: rodar /meta:inventory para reconciliar docs/INDEX.md com a SSOT do filesystem |
| 10.5 | `B5_5_meta_strategize_capability` | federation-research-2026-06-reconciled | /meta:strategize — capacidade de meta-estratégia proposta (Docs 1-2) em avaliação |
| 10.5 | `B6_8_decision_document_model` | federation-research-2026-06-reconciled | Decisão recomendada: documentar o modelo unificado de coordenação como KB de conhecimento, não como nova infraestrutura |
| 10.5 | `SY4_open_math_quantitativo_parqueado` | federation-research-2026-06-reconciled | A adoção QUALITATIVA da matemática de transição de fase entrou (diversidade do painel + gate orquestrar-ou-não em prosa), ma |
| 10.5 | `SY5_autonomy_adr_gated_beacon_real` | federation-research-2026-06-reconciled | O runtime de autonomia virou ADR proposed-GATED com KG próprio, e uma das guardas duras já é código: session-beacon.sh impleme |
| 10.5 | `SY5_brand_voice_shipped` | federation-research-2026-06-reconciled | PROVA: o brand voice virou deliverable definitivo — messaging-framework.md (114 linhas, 2026-07-19) carrega Casa de Marca, léxi |
| 10.5 | `SY5_evolve_diaries_redecide` | federation-research-2026-06-reconciled | DUPLICATA REAL: os diários 06-15, 06-16 e 06-17 re-decidem os MESMOS 3 achados (varredura MCP-first, drift de contagem, categoria |
| 10.5 | `SY5_playbooks_materialization_open` | federation-research-2026-06-reconciled | MAS a materialização segue aberta: onion-patterns/SKILL.md tem UMA linha da doutrina recognition-primed (l.177) e nenhuma seçã |
| 10.5 | `SY6_ev_federation_transport_sdaal` | federation-research-2026-06-reconciled | RFC-0004 aceito (fundamentado em 2 rodadas de pesquisa orquestrada): single-source para identidade/contratos + mesh só de comunic |
| 10.5 | `SY6_ev_integration_branch_helper` | federation-research-2026-06-reconciled | As 3 decisões de topologia do handoff foram resolvidas de forma GENÉRICA e não caso-a-caso: resolve-integration-branch.sh + res |
| 10.5 | `SY6_ev_licenca_mit` | federation-research-2026-06-reconciled | LICENSE continua MIT — a migração para BSL/dual-license decidida em 2026-06-17 nunca foi executada |
| 10.5 | `SY6_ev_whatsapp_extraido` | federation-research-2026-06-reconciled | Raiz do repo contém apenas CLAUDE.md, CONTRIBUTING.md, LICENSE, README.md, docs/, plugins/, site/ — zero código de aplicação |
| 10.5 | `SY6_find_identidade_resistiu` | federation-research-2026-06-reconciled | A identidade de 2026-05-18 sobreviveu a uma tentativa formal de reposicionamento (produto/BSL/ICP regulado, jun/2026) — e venceu |
| 10.5 | `SY6_find_lei_da_prosa_n6` | federation-research-2026-06-reconciled | A lei se confirma em N=6 levas, agora com o contra-exemplo simétrico: 100% do que virou lint/SSOT/comando/fragmento sobreviveu (r |
| 10.2 | `B6_13_adopt_update_procedure` | federation-research-2026-06-reconciled | meta:adopt --update com --integration-branch traz o delta do framework mais o procedimento de configuração pós-cópia |
| 10.0 | `S13_question_repo_tier_meaning` | federation-research-2026-06-reconciled | Q1: 'repos-padrão por tier' significa gerar repos novos (scaffolding automático) ou classificar/registrar formalmente os que já |
| 9.6 | `B2_3_next_steps_gate_keeper` | federation-research-2026-06-reconciled | Próximo passo definido: aplicar SA-1/SA-2/SA-3 ao doc de design e validar a Fase 0 com o gate-keeper de meta-spec antes de criar  |
| 9.6 | `B5_5_prioridade_marcio_question` | federation-research-2026-06-reconciled | Prioridade real entre catálogo de meta-estratégia e reposicionamento como produto (BSL/control plane/ICP regulado) — decisão  |
| 9.6 | `B5_9_verification_checklist` | federation-research-2026-06-reconciled | Checklist de verificação ponta-a-ponta (marketplace list, install roda, grupo standalone auto-instala, adopt regulado entrega L2 |
| 9.6 | `S11_decision_deep_research` | federation-research-2026-06-reconciled | Rodar deep-research harness fan-out multi-fonte (repo primário smolagents + 2-3 frameworks leves vizinhos + cruzamento com agent- |
| 9.0 | `B2_4_phased_backlog` | federation-research-2026-06-reconciled | Backlog faseado de execução (Fase 0 spikes/gate-keeper → Fase 1 formato de contrato+bootstrap ledger MVP → Fase 2 publish/ch |
| 9.0 | `B5_10_camada_c_fronteira` | federation-research-2026-06-reconciled | Comandos que dependem de doc L2 ausente (C1-C3: identity, build-tech-docs, task) degradam com aviso em vez de crashar? |
| 9.0 | `B5_10_hipotese_fronteira_l1_l2` | federation-research-2026-06-reconciled | Doutrina do moat: plugin entrega Camada 1 (capacidade autocontida); /meta:adopt entrega Camada 2 (docs + governança) |
| 9.0 | `B5_17_critica_codigo_continua_fonte` | federation-research-2026-06-reconciled | Böckeler e Encarnacao refutam spec-as-all: código executável continua a fonte; spec precisa o bastante para rodar já é códig |
| 9.0 | `S6_question_model_lifecycle` | federation-research-2026-06-reconciled | Uma vez com um modelo pronto, como cuidar dele — monitorar, atualizar, saber quando degrada? |
| 8.6 | `SY_claim_hegel_system_kb_missing` | federation-research-2026-06-reconciled | O destino canônico do catálogo (docs/knowledge-base/education/theories/hegel-system.md) NÃO existe — a pasta só tem plea-ros |
| 8.5 | `B2_3_contract_schema_requirement` | federation-research-2026-06-reconciled | Correção proposta para SA-2: o formato de contrato precisa de campos verificáveis — tests com paths e lint, fixtures de paylo |
| 8.5 | `B5_5_avaliacao_probabilistica_claim` | federation-research-2026-06-reconciled | Fan-out + juízes reduz mas não elimina erro confiante — juízes são o mesmo tipo de modelo do gerador e podem compartilhar vi |
| 8.4 | `B5_11_g3_convencao_provenencia` | federation-research-2026-06-reconciled | G3 aberto: scrub-na-fonte é one-time; falta guard de lint que varra docs/knowledge-base/ contra ids de members.yaml privados para |
| 8.4 | `B5_15_federation_edge_gap` | federation-research-2026-06-reconciled | Relações sociais de federação (adopts/trust-corrects/lineage) não têm equivalente nos 6 edge-types domain do KG |
| 8.4 | `B5_17_spec_drift_nao_resolvido` | federation-research-2026-06-reconciled | Spec drift é a crítica central ainda sem solução disciplinar — SDD trocou 'ninguém atualiza' por 'ninguém reconcilia' |
| 8.4 | `B5_8_open_onion_meta_doctrine` | federation-research-2026-06-reconciled | #4 onion-meta: empacotar os 30 comandos meta/ como plugin tensiona a doutrina de que meta é L2/L3 adopt-only — exige RFC |
| 8.4 | `B6_3_decision_harness_golden_payload` | federation-research-2026-06-reconciled | Condição para endosso sem ressalvas: prototipar harness 'golden-payload' que valida payload documentado do adapter contra fixtur |
| 8.4 | `B6_7_decisao_trial_inventory_pos_criacao` | federation-research-2026-06-reconciled | TRIAL camada 2: adicionar passo padrão de rodar inventory.sh ao final de cada create-*, no modelo entrega-sem-commit, para fechar |
| 8.4 | `B6_7_proximo_passo_adr_ciclo_vida` | federation-research-2026-06-reconciled | Próximo passo concreto: abrir o ADR de ciclo de vida do toolbox (reusando o modelo do ADR de ciclo de vida de contexto de domíni |
| 8.4 | `S2_DECISION_GRAPH_INGEST_MEMBERS` | federation-research-2026-06-reconciled | Costura proposta: graph.sh deve INGERIR members.yaml como fonte de nós (membros) e arestas (parent→adopts/adoptedBy, specializa |
| 8.4 | `S2_DECISION_SELECTOR_ALVO` | federation-research-2026-06-reconciled | Costura proposta: /meta:co-announce passa a resolver alvo: como QUERY/seletor sobre campos que members.yaml já tem (specializatio |
| 8.4 | `S4_DEC_VPS_STATIC_FIRST` | federation-research-2026-06-reconciled | Recomendação de viabilidade: atacar P0-4 (mapa derivado) e P0-3 (console) primeiro, como estáticos gerados na VPS reusando Cadd |
| 8.4 | `SY4_open_agent_teams_capability_detection` | federation-research-2026-06-reconciled | SEGUE ABERTO: a detecção de capacidade de Agent Teams prometida pela KB não existe na skill — o Passo 0 do onion-orchestratio |
| 8.4 | `SY4_open_pessoa_versionavel` | federation-research-2026-06-reconciled | SEGUE ABERTO — o 4º nível: a camada pessoa resolve por ~/.claude (fora do git), então pessoa-dentro-do-time VERSIONÁVEL/COMP |
| 8.4 | `SY5_federation_kg_ontology_answered` | federation-research-2026-06-reconciled | A pergunta da ontologia de relações de federação no KG deixou de ser abstrata: existe ADR federation-kg-audit-overlay — a de |
| 8.4 | `SY5_g2_doctrine_only` | federation-research-2026-06-reconciled | G2 (KB interna vazando para o door) ganhou DOUTRINA mas não mecanismo: a KB public-door-vs-private-core.md codifica destilação  |
| 8.4 | `SY5_ingestor_doctrine_accepted_code_absent` | federation-research-2026-06-reconciled | O ingestor de doutrina virou ADR ACEITO (trust-gate via members.yaml can_correct_to, KG-backed, human-gated, 1º dogfood granaai), |
| 8.4 | `SY5_orchestration_skill_shipped_elsewhere` | federation-research-2026-06-reconciled | Patch #2 aconteceu, mas em outro alvo: a skill onion-orchestration foi empacotada em onion-work-tools, não no manifest do onion-d |
| 8.4 | `SY5_phase_merge_invariant_held` | federation-research-2026-06-reconciled | Invariante confirmada nos 3 runs e ainda no repo: zero fusões de fase — engineer/{plan,start,work,pre-pr,pr,pr-update} e produc |
| 8.4 | `SY5_prose_backlog_antipattern` | federation-research-2026-06-reconciled | Lição destilada da tripla: backlog que mora em prosa datada re-nasce todo dia; só morre quando vira guarda mecânica no lint ou |
| 8.4 | `SY5_runflow_patch_open` | federation-research-2026-06-reconciled | Patch #1 NÃO aplicado: runflow-dev.md continua só em .claude/commands/development/ e não aparece em nenhum manifest de plugin n |
| 8.4 | `SY5_strategy_trio_is_one_package` | federation-research-2026-06-reconciled | Os 3 docs strategy-layer de 06-17 (blindspots + capability-draft + handoff) NÃO são repetição: são um pacote de uma sessão s |
| 8.4 | `SY5_vendor_branch_closed` | federation-research-2026-06-reconciled | PROVA: o Achado 2 (merge de vendor-branch em vez de copy-over) também virou realidade — vendor-branch.sh + adopt.md descrevendo |
| 8.4 | `SY6_ev_diary_conflict_class` | federation-research-2026-06-reconciled | O enabler de migalha condicionada é código vivo: frontmatter conflict_class (dynamic/static/conditional) + valid_when obrigatór |
| 8.4 | `SY6_ev_federacao_viva` | federation-research-2026-06-reconciled | A federação deixou de ser 'gravada mas inativa': members.yaml com 7 membros tipados (source/hub/standalone), pins VERIFICADOS po |
| 8.4 | `SY6_ev_kg_virou_guarda` | federation-research-2026-06-reconciled | O próprio ato de modelar este passivo virou infraestrutura: /meta:kg + knowledge-graph-sdaal.md + kg-radar.sh + kg-provenance-cov |
| 8.4 | `SY6_ev_lint_regra5_por_tipo` | federation-research-2026-06-reconciled | Limite de tamanho por TIPO virou lint: R5 agente>1500 HARD, comando>800 HARD, núcleo SDAAL>500 SOFT, adapter SDAAL>900 SOFT — a |
| 8.4 | `SY6_ev_none_adapter` | federation-research-2026-06-reconciled | task-manager/adapters/none.md existe — as 3 abstrações voltaram a ser simétricas; a violação da própria regra §7/§14.3 d |
| 8.4 | `SY6_ev_porta_publica` | federation-research-2026-06-reconciled | A distribuição resolveu-se por TOPOLOGIA, não por licença: KB porta-pública≠core-privado + ADRs de family-repo-topology e c |
| 8.4 | `SY6_ev_proibicoes_arch7` | federation-research-2026-06-reconciled | A identidade de 2026-05-18 virou NORMA executável: architecture.md §7 'Proibições explícitas' proíbe introduzir .onion/ ou p |
| 8.4 | `SY6_ev_regua_p0p3_skill` | federation-research-2026-06-reconciled | A régua de classificação P0-P3 vive como seção do onion/SKILL.md, com Teste do Eixo para abstração SDAAL (≥2 implementaç |
| 8.4 | `SY6_ev_state_md_ponteiro` | federation-research-2026-06-reconciled | STATE.md virou o ponteiro único lido por 10+ comandos (catch-up, onion, engineer:start/plan/work/warm-up…), matando o protocolo |
| 8.4 | `SY6_ev_team_gated_preservado` | federation-research-2026-06-reconciled | O modo EQUIPE segue explicitamente gated na KB ('só com dogfood, 1º caso N-devs/1-repo') — 13 meses depois ninguém implemento |
| 8.1 | `B4_9_agent_teams_flag` | federation-research-2026-06-reconciled | Flag experimental CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS ligada e testada |
| 8.1 | `B5_8_postpatch_driftguards` | federation-research-2026-06-reconciled | Pós-aplicação é obrigatório re-montar os 2 plugins e rodar lint-artifacts + lint-selftest (R19/R20/R22) e /meta:inventory |
| 8.1 | `B6_13_members_yaml_pending` | federation-research-2026-06-reconciled | Adotante ainda não consta no members.yaml do core; entrada só após pin real pós-update |
| 8.0 | `S11_q_vale_extrair` | federation-research-2026-06-reconciled | O que no smolagents (e vizinhos) é genuinamente novo vs. reinvenção com nome diferente do que o Onion já tem (agent-orchestrat |
| 8.0 | `S13_decision_register_family` | federation-research-2026-06-reconciled | Proposta: se Q1 resolver para leitura (b), registrar a família multi-plataforma real em members.yaml com a anotação de destila� |
| 8.0 | `S2_question_new_evidence_gate` | federation-research-2026-06-reconciled | Q1 — o que contaria como evidência nova (caso real, não hipotético) para reabrir a rejeição marcada 'não reabrir sem evid� |
| 8.0 | `S5_question_generative_composition` | federation-research-2026-06-reconciled | Dado um problema, como compor soluções com as peças existentes? (composição generativa sobre o grafo) |
| 8.0 | `S6_entity_local_slm_adapter` | federation-research-2026-06-reconciled | adapter local-slm de-identification — gated, aguardando 1º adotante regulado com runtime; único ponto onde 'cuidar de modelo'  |
| 7.8 | `B5_11_f5_semente_project_door` | federation-research-2026-06-reconciled | F5 semente: manifesto role-scoped efetivo + ruleset de scrub são o input concreto para automação project-door.sh, gated até � |
| 7.8 | `B6_12_decisao_responder_gated` | federation-research-2026-06-reconciled | Modelo 'um responde ao outro' deve ser responder-gated: a sessão do destino PROPÕE o rascunho ao ver sinal (📬/📥/⏰), o ma |
| 7.7 | `B5_1_kb_freshness_command_decision` | federation-research-2026-06-reconciled | Decisão: rodar /meta:kb-freshness em varredura exaustiva das KBs stale |
| 7.7 | `B6_2_adr_reposicionamento_pendente` | federation-research-2026-06-reconciled | ADR de reposicionamento como produto proposto na FASE 0, nunca escrito |
| 7.5 | `B4_11_decision_maestro_final_weight` | federation-research-2026-06-reconciled | Decisão de peso final entre NS1/NS3 permanece do maestro — o doc estrutura, não decide (nível Criar não é derivável só do |
| 7.5 | `B5_10_camada_b_execucao` | federation-research-2026-06-reconciled | Comandos autocontidos (B1-B5: help, build-index, unit test, fast-commit) funcionam só com o plugin, sem adopt? |
| 7.2 | `B5_14_artifact_adr_thread_runtime` | federation-research-2026-06-reconciled | ADR onion-adr-autonomous-thread-runtime-2026-07, nasce proposed-GATED (sela só após dogfood da Fase 2) |
| 7.2 | `B5_1_fix_phantom_links_decision` | federation-research-2026-06-reconciled | Decisão: corrigir categorias fantasma e links quebrados, começando pelos 21 do security-information-master |
| 7.2 | `B5_6_risco_sobreposicao` | federation-research-2026-06-reconciled | Risco: `onion-orchestration` + `onion-patterns` já cobrem ~60% do catálogo proposto |
| 7.2 | `B5_8_patch1_runflow_dev` | federation-research-2026-06-reconciled | Patch #1: mover comando runflow-dev.md para o manifest do onion-engineering (agente irmão já empacotado) |
| 7.2 | `B6_10_adr_capability_contract` | federation-research-2026-06-reconciled | ADR capability-contract (2026-06) — decisão formal que esta pesquisa fundamenta |
| 7.2 | `S1_composition_decision` | federation-research-2026-06-reconciled | Testar composição de ferramentas existentes (graph --path + freshness + catálogo do working-method) antes de propor infraestrut |
| 7.2 | `S3_q_where_breaks` | federation-research-2026-06-reconciled | Q5 (crivo anti-decoração): onde a analogia quebra — tese-antítese-síntese é Fichte/Chalybäus não o método de Hegel; tele |
| 7.2 | `S9_claim_internal_pattern` | federation-research-2026-06-reconciled | field-observations/ já documenta o padrão campo→assess (maestro)→entrada formal para sinal INTERNO (dogfood), reaproveitáve |
| 6.8 | `B6_13_integration_branch_conflict` | federation-research-2026-06-reconciled | Branch remota pretendida como alvo de PRs Onion carrega história de produto anterior à adoção, gerando conflito de uso |
| 6.4 | `B6_11_decision_gate_adr_breadcrumbs` | federation-research-2026-06-reconciled | ADR de breadcrumbs inteligentes só deve ser escrito após o enabler rodar 1 ciclo real de re-teste por classe (gated-until-trigge |
| 6.4 | `B6_16_evals_trajetoria_negligenciada` | federation-research-2026-06-reconciled | Avaliação de trajetórias completas (não só resposta final) é a disciplina mais negligenciada e mais importante de 2026 |
| 6.4 | `B6_6_remove_symlinks_decision` | federation-research-2026-06-reconciled | Decisão: remover os 2 symlinks mortos, alinhado ao abandono já ratificado de .onion/ |
| 6.4 | `S8_QuestionCollisionRouting` | federation-research-2026-06-reconciled | A leitura (a) colide com a rejeição já registrada de model-routing multi-LLM (onion-engine-economy.md §5) e com a semente fede |
| 6.4 | `SYNTHESIS.md_FIRST_SLICE_ORDER` | federation-research-2026-06-reconciled | Ordem do 1º slice: (1) graph.sh ingere members.yaml, (2) targeting por seletor no alvo:, (3) console read-only, (4) receiver que  |
| 6.3 | `B5_16_question_linha_leiga_p6_bloqueada` | federation-research-2026-06-reconciled | Linha leiga P6 segue bloqueada (D3) — H1/tagline final fica a critério de direção criativa do maestro |
| 6.3 | `B6_10_gap_injecao_condicional` | federation-research-2026-06-reconciled | Lacuna L2: progressive disclosure hoje é tudo-ou-nada por skill; falta injeção condicional (ex: IF provider=jira → carregar K |
| 6.3 | `B6_10_gap_validacao_generalizada` | federation-research-2026-06-reconciled | Lacuna L5: falta validar o artefato contra sua própria auto-descrição, generalizado além do caso task-manager |
| 6.3 | `B6_16_agentes_autonomos_hype_calibrar` | federation-research-2026-06-reconciled | 'Agentes autônomos resolvem tudo' é hype a calibrar — confiabilidade ainda depende de evals, guardrails e human-in-the-loop |
| 6.3 | `SY5_a2a_gate_still_unfired` | federation-research-2026-06-reconciled | A projeção export-only Agent Card carregada de 06-15 para 06-16 tem hoje CÓDIGO (a2a-agent-card.sh + REGRA de sync no lint + ca |
| 6.3 | `SY5_branch_roles_second_resolver` | federation-research-2026-06-reconciled | PROVA parcial do branch-roles SDAAL: nasceu o SEGUNDO resolver de papel — resolve-production-branch.sh, irmão do resolve-integr |
| 6.3 | `SY5_catch_up_gap_persists` | federation-research-2026-06-reconciled | Gap C4 confirmado por inspeção e ainda vivo: nenhum plugin embarca catch-up (só warm-up, em product e engineering) — /catch-u |
| 6.3 | `SY5_g3_scrub_guard_absent` | federation-research-2026-06-reconciled | PROVA NEGATIVA (G3 aberto): não existe guarda de lint varrendo docs/knowledge-base/ contra ids/nomes privados — grep por 'circu |
| 6.3 | `SY5_kb_freshness_gate_closed` | federation-research-2026-06-reconciled | PROVA: o gate de frescor de KB deixou de ser data no frontmatter e virou executável — /meta:kb-freshness e /meta:context-freshn |
| 6.3 | `SY5_marketplace_live` | federation-research-2026-06-reconciled | PROVA: o runbook de marketplace saiu do papel — .claude-plugin/marketplace.json existe com pluginRoot ./plugins e 7 plugins publ |
| 6.3 | `SY5_movimento1_vendored_pending_commit` | federation-research-2026-06-reconciled | Movimento 1 (vendorizar o framework na linhagem de produção) está feito-mas-não-selado: members.yaml carrega pin production 8e |
| 6.3 | `SY5_product_lineage_not_materialized` | federation-research-2026-06-reconciled | PROVA NEGATIVA: a 3ª lineage product(main) aprovada no veredito NÃO foi materializada — members.yaml do metagamify declara só |
| 6.3 | `SY6_ev_adr_reposicionamento_inexistente` | federation-research-2026-06-reconciled | Entre 39 ADRs em docs/analysis/, nenhum é o 'ADR de reposicionamento como produto' proposto na FASE 0 — a pergunta de jun/2026  |
| 6.3 | `SY6_ev_allowed_tools_universal` | federation-research-2026-06-reconciled | allowed-tools passou de 1/93 para 98 arquivos de comando — cobertura dos invocáveis, tratado como capability surface e não doc |
| 6.3 | `SY6_ev_arandek_nunca_graduou` | federation-research-2026-06-reconciled | Arandek não consta em members.yaml; sobrevive só como exemplo em prosa (README de evolução, onboarding-remote-member, inbox _p |
| 6.3 | `SY6_ev_evolve_tiering` | federation-research-2026-06-reconciled | O roteamento dinâmico por tarefa (fim do 'modelo herói') é operacional: /meta:evolve define modelo por dimensão de auditoria ( |
| 6.3 | `SY6_ev_golden_payload_ausente` | federation-research-2026-06-reconciled | 'golden-payload' aparece EXCLUSIVAMENTE no documento que o propôs — nunca virou harness; o mecanismo análogo existe só para c |
| 6.3 | `SY6_ev_identity_kb` | federation-research-2026-06-reconciled | Identidade canônica destilada em KB navegável com tabela 'o que foi rejeitado e por quê' (CLI standalone: 'distribuir como prod |
| 6.3 | `SY6_ev_inventory_sync_prompt` | federation-research-2026-06-reconciled | Passo pós-criação de re-rodar o inventário virou fragmento compartilhado reusado pelos create-* |
| 6.3 | `SY6_ev_kbfreshness_gate3` | federation-research-2026-06-reconciled | O abandono virou GATE de auditoria: /meta:kb-freshness critério #3 reprova KB que contenha referência positiva a .onion/, CLI st |
| 6.3 | `SY6_ev_mcp_json_ausente` | federation-research-2026-06-reconciled | .mcp.json continua ausente — único item do baseline de V&V não fechado, coerente com a doutrina API-first (MCP = transporte op |
| 6.3 | `SY6_ev_retestar_nunca_recarimbar` | federation-research-2026-06-reconciled | '⏰ vencido → RE-TESTAR contra evidência atual, nunca re-carimbar' é regra escrita no comando, com 4 desfechos tipados (váli |
| 6.3 | `SY6_ev_settings_presentes` | federation-research-2026-06-reconciled | settings.json e settings.local.json presentes; templates órfãos de execução removidos |
| 6.3 | `SY6_ev_symlinks_removidos` | federation-research-2026-06-reconciled | Zero symlinks em .claude/; product/help.md não existe mais — os 2 ponteiros mortos para .onion/contexts/ foram removidos |
| 6.3 | `SY6_find_decisao_generaliza_ou_morre` | federation-research-2026-06-reconciled | Padrão novo que nenhuma leitura individual revela: decisão de caso-específico só sobrevive se generalizar. As 3 decisões do h |
| 6.3 | `SY6_find_distribuicao_por_topologia` | federation-research-2026-06-reconciled | A pergunta comercial de junho ('como monetizar/distribuir') não foi respondida nem abandonada — foi RE-FORMULADA em outro plano |
| 6.3 | `SY6_find_pesquisa_desce_para_campo` | federation-research-2026-06-reconciled | As três pesquisas de método (breadcrumbs, work-models, self-describing components) partiram de vocabulários acadêmicos distint |
| 6.0 | `B4_9_question_capability_detection` | federation-research-2026-06-reconciled | Implementar detecção de capacidade + fallback gracioso em onion-orchestration |
| 6.0 | `B5_17_pergunta_quem_reconcilia` | federation-research-2026-06-reconciled | Quem reconcilia mudanças concorrentes de spec entre agente e desenvolvedor humano? |
| 6.0 | `B5_5_custo_comparavel_evolve_claim` | federation-research-2026-06-reconciled | Custo real de /meta:strategize com N candidatos + painel de juízes + verificação adversarial é comparável a /meta:evolve (~1. |
| 6.0 | `B5_6_pergunta_skill_ou_extensao` | federation-research-2026-06-reconciled | Skill nova ou estender `onion-patterns` com seção de playbooks? |
| 6.0 | `B5_6_reconhecedor_leve` | federation-research-2026-06-reconciled | Reconhecedor leve via progressive disclosure de skill (sem comando pesado) |
| 6.0 | `B5_7_overlap_doubt` | federation-research-2026-06-reconciled | Autosuspeita: o catálogo pode sobrepor ~60% com onion-patterns/onion-orchestration — carece de verificação contra o código r |
| 6.0 | `S12_claim_plea_analogy` | federation-research-2026-06-reconciled | As 3 fases PLEA já têm análogo operante no Onion: Planificação=radar/backlog/plans, Execução=atuadores/dogfood, Avaliação |
| 6.0 | `S13_claim_family_unregistered` | federation-research-2026-06-reconciled | A família multi-plataforma (onion-cursor, onion-codex, onion-copilot, onion-zed, onion-antigravity) já existe de fato mas não e |
| 6.0 | `S1_epistemic_lens_question` | federation-research-2026-06-reconciled | Existe (ou deveria existir) uma lente do sabido ao a-saber no Onion, e qual o papel do SDAAL nela? |
| 6.0 | `S3_q_aufhebung_supersedes` | federation-research-2026-06-reconciled | Q1: Aufhebung mapeia com rigor no ciclo claim→refutação→novo-claim do KG? há distinção formal entre contradição-bug e c |
| 6.0 | `SYNTHESIS.md_A2A_LIVE_HANDSHAKE_OPEN` | federation-research-2026-06-reconciled | Especificação do handshake a2a-live gated para o caso o membro regulado (regulado, integration_branch: develop, nunca live-pull) |
| 5.8 | `B6_8_decision_kb_integrated` | federation-research-2026-06-reconciled | Decisão: consolidar Tópico 1 (método) e Tópico 2 (coordenação) numa KB integrada onion-working-method.md, com o modelo de co |
| 5.4 | `B4_2_person_layer_gap_question` | federation-research-2026-06-reconciled | Como versionar/compartilhar o 4º nível (pessoa-dentro-do-time-dentro-do-repo), onde o nativo é fraco? |
| 5.4 | `B5_10_ambiente_goalflow` | federation-research-2026-06-reconciled | goalflow-suite com os 6 plugins Onion habilitados mas não adotado (sem .onion-version) |
| 5.4 | `B5_15_federation_ontology_open` | federation-research-2026-06-reconciled | Ontologia de relações de federação no KG é gap aberto — só a Fase 3 (dogfood) decide, não o abstrato |
| 5.4 | `B6_10_conformance_tiers` | federation-research-2026-06-reconciled | Perfis de conformidade Bronze/Silver/Gold para validar o capability contract |
| 5.4 | `B6_11_question_estrutura_vence_prosa` | federation-research-2026-06-reconciled | Estrutura vence prosa livre? Nenhuma ablação existe (nem CoRE rodou) — vira experimento dogfood próprio do Onion, medindo re- |
| 5.4 | `B6_11_question_prior_art_combinacao_completa` | federation-research-2026-06-reconciled | A combinação completa (grafo argumentativo + staleness re-testável + governança por plane + replay-como-gate + federação git |
| 5.4 | `S11_claim_no_prior_doctrine` | federation-research-2026-06-reconciled | Onion não tem doutrina dedicada a minerar prior art de projetos externos específicos — só um processo ad-hoc já usado uma ve |
| 5.4 | `S9_claim_cadence_tooling` | federation-research-2026-06-reconciled | A mecânica de cadência recorrente já existe pronta (skills /loop e schedule/CronCreate); falta decidir o quê, onde e quem cura |
| 5.2 | `B6_3_entity_federacao_control_plane` | federation-research-2026-06-reconciled | Subsistema de Federação (ledger git + contratos + validação determinística + rollback) identificado como núcleo já prototip |
| 5.1 | `B6_13_decision_pr_target_remote` | federation-research-2026-06-reconciled | Decisão 3: qual remote é o alvo do PR de evolução Onion |
| 4.8 | `B4_10_commercial_sharpening` | federation-research-2026-06-reconciled | Implicação comercial: se camada 1 é commodity nativa/grátis, o Onion monetiza exatamente as camadas 2+3 (governança/coordena� |
| 4.8 | `B6_2_adocao_consciente` | federation-research-2026-06-reconciled | Adoção consciente: entrar e deixar limpo/auto-suficiente com consciência do outro lado — etapas não desenhadas |
| 4.8 | `B6_4_divida_adr_topologia` | federation-research-2026-06-reconciled | Dívida consciente (não ponta solta): ADR de topologia com metadados incoerentes (título RASCUNHO + status accepted) — gated p |
| 4.8 | `S13_question_distilled_role_worth_it` | federation-research-2026-06-reconciled | Q2: vale a pena formalizar role: distilled agora, ou o gatilho do ADR do Mini ('2ª destilação real') exige que a família seja  |
| 4.8 | `S1_freshness_limit` | federation-research-2026-06-reconciled | /meta:context-freshness trata fidelidade (o documentado ainda é verdade?), não cobertura (o que falta documentar?) |
| 4.8 | `S1_no_named_framework` | federation-research-2026-06-reconciled | Hoje não existe framework nomeado 'gap epistêmico' no Onion, embora dois vizinhos resolvam fatias parecidas |
| 4.8 | `S9_q3_cadence_choice` | federation-research-2026-06-reconciled | Q3 — cadência via /loop (sessão ativa) ou schedule/CronCreate (agente autônomo em cron), sem virar 'IA decide sozinha o que � |
| 4.5 | `B4_11_claim_ns3_hedge_caixa` | federation-research-2026-06-reconciled | NS3 (braço de educação, Descasca/Método Onion) é o hedge de receita mais perto de caixa, mas com evidência fraca e desviando |
| 4.5 | `B5_11_flip_publico_gated` | federation-research-2026-06-reconciled | Flip público do onion-standalone + reapontar redirect onion-claude seguem gated ao maestro (MOAT-lock-4) |
| 4.5 | `B5_7_timing_question` | federation-research-2026-06-reconciled | O catálogo é importante mas provavelmente não urgente frente à sessão de reposicionamento como produto (BSL, control plane) � |
| 4.5 | `B6_16_ap2_vulneravel_prompt_injection` | federation-research-2026-06-reconciled | Red-teaming acadêmico já demonstrou vulnerabilidade do protocolo AP2 (pagamentos por agentes) a prompt injection |
| 4.5 | `B6_2_federacao_cross_consumer` | federation-research-2026-06-reconciled | Federação cross-consumer (adotante↔adotante): topologia nova, hoje só vertical |
| 4.5 | `B6_7_outlier_a_create_agent_express` | federation-research-2026-06-reconciled | Outlier A: create-agent-express emite path flat .claude/agents/<name>.md, violando a estrutura categorizada .claude/agents/<catego |
| 4.5 | `B6_7_outlier_b_create_task_structure` | federation-research-2026-06-reconciled | Outlier B: create-task-structure não cria artefato Onion (decompõe trabalho de produto delegando a @task-specialist/product:task |
| 4.5 | `G3_QUESTION_REPUTATION_VETO_THRESHOLD` | federation-research-2026-06-reconciled | Como e quando o histórico de reputação verificado (trust-log acumulado) deve ajustar o threshold de aceitação/veto de um sina |
| 4.5 | `GAPS_REPUTATION_SIMULATION_EVIDENCE` | federation-research-2026-06-reconciled | Reputação como gate de exclusão (RepuNet, Attention-Trust Management) é mecanismo real e forte, mas os números (85%, 23,5%) s |
| 4.5 | `S11_q_fontes_primarias` | federation-research-2026-06-reconciled | Onde a informação sobre padrões emergentes 'aparece primeiro' (repos/papers/RFCs) em vez de blogposts de segunda mão? |
| 4.5 | `S4_claim_bifurcado_retrofit` | federation-research-2026-06-reconciled | Retrofit 2026-07-06 (parecer rejection-vs-spinoff): onion-mini/família multi-plataforma já é a resposta bifurcada, fora do core |
| 4.5 | `S4_decision_clarify_first` | federation-research-2026-06-reconciled | Método previsto: esclarecer Q2 com o maestro ANTES de qualquer pesquisa técnica de viabilidade |
| 4.5 | `S7_claim_metaphor_fragile` | federation-research-2026-06-reconciled | Ressalva que a pesquisa precisa enfrentar: a própria metáfora bytecode/VM já foi qualificada pelo maestro como frágil se levad |
| 4.2 | `B4_12_claim_no_e2e_test` | federation-research-2026-06-reconciled | Dívida técnica transversal permanece: /meta:adopt --update não tem teste ponta-a-ponta automatizado porque o fluxo roda dentro  |
| 4.2 | `B5_6_playbooks_exemplo` | federation-research-2026-06-reconciled | 5 playbooks implícitos já existentes a destilar (descoberta-a-backlog, planejamento-a-entrega, auditoria-ampla, hotfix, adoção |
| 4.2 | `B5_9_plugin_root_caveat` | federation-research-2026-06-reconciled | Caveat: `${CLAUDE_PLUGIN_ROOT}` pode não resolver em markdown de comando (bug upstream claude-code #9354) — exige teste ao vivo |
| 4.2 | `B6_2_naming_control_plane_risk` | federation-research-2026-06-reconciled | Risco de naming: 'control plane' colide com categoria de runtime 2026; nomear distinto é decisão futura |
| 4.2 | `S13_claim_trust_matrix_exists` | federation-research-2026-06-reconciled | A matriz de trust por tier (hub/consumer/standalone) já existe, é determinística e validada por trust-topology-check.sh --dry-r |
| 4.2 | `SY4_open_aprovador_excecao_arvore` | federation-research-2026-06-reconciled | SEGUE ABERTO (risco baixo): quem aprova a exceção ao default de orquestração plana continua não escrito; o ADR só diz que a  |
| 4.2 | `SY5_branch_roles_adr_still_proposed` | federation-research-2026-06-reconciled | Mas o ADR branch-roles-sdaal continua 'proposto (design-only, gated)' — o mecanismo generalizado (branch_roles: no .onion-versio |
| 4.2 | `SY5_index_residual_drift` | federation-research-2026-06-reconciled | Resíduo VIVO (pequeno): docs/INDEX.md:47 diz '30 em meta/' e a SSOT gerada diz 32 — o mecanismo existe mas este derivado hand-m |
| 4.2 | `SY5_meta_factory_doctrine_held` | federation-research-2026-06-reconciled | PROVA da doutrina 'meta-factory nunca é plugin': o onion-work-tools empacota só meta cross-cutting (kg, diary, orchestrate, meta |
| 4.2 | `SY5_onion_meta_question_dissolved` | federation-research-2026-06-reconciled | A pergunta #4 ('empacotar os 30 comandos meta/ tensiona a doutrina, exige RFC') foi dissolvida por DECOMPOSIÇÃO, não por RFC: s |
| 4.2 | `SY5_p6_still_blocked` | federation-research-2026-06-reconciled | A única pergunta do brand voice que sobrevive é a mesma que nasceu: a linha leiga P6 segue BLOQUEADA por D3, declarada no topo d |
| 4.2 | `SY5_spec_research_has_no_kg` | federation-research-2026-06-reconciled | Agravante mecânico: spec-as-code-evolution-2026/ é a ÚNICA das 3 pesquisas desta leva sem .kg.yaml ao lado do SYNTHESIS — as  |
| 4.2 | `SY6_ev_adr_toolbox` | federation-research-2026-06-reconciled | ADR de ciclo de vida do toolbox escrito e aceito |
| 4.2 | `SY6_ev_drift_guard_r19` | federation-research-2026-06-reconciled | Drift-guard determinístico existe para plugins de vertical (R19 HARD: regenera e compara, edição à mão ou fonte alterada bloq |
| 4.2 | `SY6_ev_metaspecs_criadas` | federation-research-2026-06-reconciled | As 5 meta-specs L0 'A CRIAR' existem e estão populadas (agents, architecture, code-standards, commands, integrations + index) |
| 4.2 | `SY6_ev_outlier_a_corrigido` | federation-research-2026-06-reconciled | Outlier A fechado: create-agent-express agora exige subpasta de categoria ('agentes vivem em subpasta de categoria, nunca no root' |
| 4.2 | `SY6_ev_outlier_b_movido` | federation-research-2026-06-reconciled | Outlier B fechado: create-task-structure mudou de /meta/ para /product/ |
| 4.2 | `SY6_ev_presskit_coerente` | federation-research-2026-06-reconciled | press-kit.md ainda afirma 'não é um produto comercial distribuído publicamente… não há licença, assinatura própria ou CLI |
| 4.2 | `SY6_ev_slm_virou_adr` | federation-research-2026-06-reconciled | A tese 'SLM 10-30x mais barato para tarefa agêntica específica' virou decisão arquitetural concreta: ADR SLM-as-tool para de-id |
| 4.2 | `SY6_find_auditoria_semantica_insubstituivel` | federation-research-2026-06-reconciled | A lição do audit de fidelidade se auto-confirma nesta leva: o gate determinístico passa 0/0 sobre dívida doutrinária. Das 16  |
| 4.2 | `SY6_find_gated_sem_vazamento` | federation-research-2026-06-reconciled | 'Gated' é disciplina cumprida, não procrastinação: modo EQUIPE, a2a-live, eixo messenger SDAAL, ADR de breadcrumbs e rota-de-v |
| 4.2 | `SY6_open_injecao_condicional` | federation-research-2026-06-reconciled | Lacuna L2 (injeção condicional real — IF provider=jira → carregar KB jira) está declarada no título do ADR de capability c |
| 4.2 | `SY6_open_provider_drift` | federation-research-2026-06-reconciled | O furo central apontado ao SDAAL — nenhuma guarda que detecte spec de adapter divergindo do provider REAL — segue aberto: R19  |
| 4.0 | `B5_10_decisao_veredito_final` | federation-research-2026-06-reconciled | Decisão pendente: goalflow-suite fica plugin-only (L1) ou roda /meta:adopt para framework completo L2+3 |
| 4.0 | `S2_decision_deep_research_trigger` | federation-research-2026-06-reconciled | Gatilho: maestro pede 'roda a pesquisa de SLMs federados' → deep-research adversarial; achado sobrevivente vai a revisão humana |
| 4.0 | `S3_gatilho_maestro_pede` | federation-research-2026-06-reconciled | Gatilho: maestro pede \"roda a pesquisa Hegel\" para disparar a semente |
| 4.0 | `S9_decision_trigger` | federation-research-2026-06-reconciled | Gatilho: quando o maestro pedir 'vamos montar o canal-radar', executar a partir desta semente começando pelas decisões estrutura |
| 3.6 | `B4_8_question_aprovador_excecao` | federation-research-2026-06-reconciled | Quem aprova a exceção ao default de orquestração plana não está escrito — gatilho de implementação incompleto nesse pont |
| 3.6 | `B5_12_validacao_dryrun` | federation-research-2026-06-reconciled | Validação extra não-bloqueante: rodar adopt --dry-run real num KG throwaway |
| 3.6 | `B5_2_a2a_projection_carryforward` | federation-research-2026-06-reconciled | Projeção export-only Agent Card (A2A) carregada adiante — gatilho (1º consumer não-Onion) ainda não disparou |
| 3.6 | `B5_5_falta_benchmark_question` | federation-research-2026-06-reconciled | Faltam benchmarks medidos de custo real para aplicar a regra de 'altitude por risco' com segurança |
| 3.6 | `B5_6_criterio_aceitacao` | federation-research-2026-06-reconciled | Critério de aceitação: ≥5 playbooks, reconhecimento sem comando obrigatório, fallback explícito, não duplicar skills exist |
| 3.6 | `B5_6_pergunta_comando_explicito` | federation-research-2026-06-reconciled | Precisa de `/meta:strategize` ou skill automática já basta? |
| 3.6 | `B6_14_rota_volta_mobile` | federation-research-2026-06-reconciled | Trabalho nascido no mobile precisa de rota de volta estruturada (bridge commitar em branch própria + sinalizar via inbox) — gat |
| 3.6 | `B6_3_question_coordenacao_overlap` | federation-research-2026-06-reconciled | Quem executa cada fase do plano proposto e em que branch, para não colidir com a evolução em curso na sala de obra (arquivos de |
| 3.6 | `B6_9_question_topic2_link` | federation-research-2026-06-reconciled | A KB integrada deve referenciar (não duplicar) o resultado do Tópico 2 (Harness+Ledger nos 3 modos) na Camada 2 de execução e  |
| 3.6 | `S11_decision_gatilho` | federation-research-2026-06-reconciled | Gatilho declarado: maestro pede explicitamente ('roda a pesquisa do smolagents') para executar a partir desta semente |
| 3.6 | `S12_q_llm_vm_arch` | federation-research-2026-06-reconciled | A tese LLM-as-VM (MD=spec executável, KG=estado de conhecimento, grafos=mapa navegável, scripts=determinismo) é original frente |
| 3.6 | `S1_graph_path_limit` | federation-research-2026-06-reconciled | /meta:graph --path caminha só entre nós que já existem no grafo, não entre sabido e desconhecido |
| 3.6 | `S4_claim_onion_mini_bridge` | federation-research-2026-06-reconciled | onion-mini já roda em qualquer lugar que leia AGENTS.md (incl. VSCode com extensões agênticas) sem o core precisar mudar nada |
| 3.6 | `S4_q_efficiency_criterion` | federation-research-2026-06-reconciled | Q3: qual proposta concreta de eficiência (não replicar tudo, aproveitar AGENTS.md/onion-mini como ponte) faltaria como evidênci |
| 3.6 | `S5_entity_srl_plea_seed` | federation-research-2026-06-reconciled | Seed irmão SRL-PLEA (Q5 aberta sobre bytecodes PLEA, herdada por este seed) |
| 3.6 | `S5_question_plea_mechanism` | federation-research-2026-06-reconciled | Como PLEA se materializa como mecanismo de auto-regulação de ferramentas (não de aprendiz humano)? |
| 3.6 | `S6_claim_provider_diff` | federation-research-2026-06-reconciled | llm-provider (roadmap SDAAL) resolve 'qual modelo usar', não 'como saber se o modelo já escolhido ainda está bom' — são prob |
| 3.6 | `S6_decision_borrow_lifecycle_form` | federation-research-2026-06-reconciled | proposta: emprestar a FORMA do ciclo de vida de contexto (CRUD+, veredito de frescor RECENTE/DEGRADADO/OBSOLETO) para modelo — s |
| 3.6 | `S7_decision_scope_research` | federation-research-2026-06-reconciled | Decidir, antes de pesquisar, se a investigação testa a metáfora bytecode/VM tecnicamente (enfrentando a ressalva de fragilidade |
| 3.6 | `S8_ClaimReadingA` | federation-research-2026-06-reconciled | Leitura (a): Onion como abstração de acesso — interface única por trás da qual qualquer modelo é chamado (llm-provider leva |
| 3.6 | `S8_DecisionClarifySessionFirst` | federation-research-2026-06-reconciled | Método proposto: sessão dedicada de clareza conceitual interna (testar leituras contra onion-relation-vocabulary.md e contra a r |
| 3.6 | `S9_q1_folder_reuse` | federation-research-2026-06-reconciled | Q1 — reaproveitar field-observations/ com campo domain: novo, ou criar pasta-irmã para não misturar dogfood interno com ecossi |
| 3.2 | `B5_10_regra_crash_vira_sinal` | federation-research-2026-06-reconciled | Se um comando da Camada C crashar (stack trace/erro cru) em vez de avisar, isso é bug de robustez a anotar como sinal de co-evolu |
| 3.2 | `B5_13_gate_extracao_escopo_rhilo` | federation-research-2026-06-reconciled | Gated (não agora): extrair as customizações-RHILO de rhilo/main para camadas de escopo composto (RFC-0005 Fase 3 SUPERSEDES-de- |
| 3.2 | `B6_6_reaudit_script` | federation-research-2026-06-reconciled | Comandos de re-auditoria (find/grep de tamanhos, plataforma e symlinks) definidos como critério de verificação final do plano |
| 3.2 | `REC2_Q_FORMAL_FEDERATION_DEAD_OR_DORMANT` | federation-research-2026-06-reconciled | NÃO VERIFIQUEI: se a Federação formal de contratos está DORMENTE (esperando o 1º caso real de API compartilhada entre membros |
| 3.2 | `S11_q_criterio_extracao` | federation-research-2026-06-reconciled | Qual critério explícito e reutilizável define quando um padrão externo vale a pena importar pro Onion? |
| 3.2 | `S7_claim_analogy_breaks` | federation-research-2026-06-reconciled | Anti-tese deliberada (Q4): um modelo treinado não tem a auditabilidade/versionamento em PR que markdown tem — \"virar modelo\"  |
| 3.0 | `B4_5_question_quarto_nivel_pessoa` | federation-research-2026-06-reconciled | O 4º nível (pessoa-dentro-do-time versionável/compartilhável) é o único nativamente fraco — convenção members/<pessoa> � |
| 3.0 | `B4_6_calibration_trigger` | federation-research-2026-06-reconciled | Gatilho para revisitar: se surgirem critérios de aceite numéricos para o judge-panel ou necessidade de calibrar N_max de panel p |
| 3.0 | `B5_14_question_automate_class_size` | federation-research-2026-06-reconciled | A classe AUTOMATE real deste repo é pequena (non-vendor) — a confirmar em campo |
| 3.0 | `B5_6_loop_aprendizado_playbook` | federation-research-2026-06-reconciled | Sem match no catálogo → deliberação → resíduo vira proposta de novo playbook (catálogo aprende) |
| 3.0 | `B5_7_adr_format_question` | federation-research-2026-06-reconciled | Formato final do ADR não decidido: meta-spec nova vs seção dentro de architecture.md existente |
| 3.0 | `B6_12_pergunta_dropbox_escala_cross_repo` | federation-research-2026-06-reconciled | Drop-box escala entre repositórios distintos com cadências diferentes? Ninguém mediu — o Onion está à frente da literatura  |
| 3.0 | `B6_1_piloto_p3_pendente` | federation-research-2026-06-reconciled | Qual projeto-alvo será o piloto para validar empiricamente P3 (guias operacionais e comandos /docs:build-*-docs) após o saneamen |
| 3.0 | `B6_2_canal_aprendizado_bidirecional` | federation-research-2026-06-reconciled | Canal de aprendizado bidirecional + cross-consumer: extensão do inbox de co-evolução |
| 3.0 | `GAPS_QUESTION_REPUTATION_VETO_THRESHOLD` | federation-research-2026-06-reconciled | Quando instrumentar e medir o trust-log o suficiente para deixar a reputação mexer no threshold do veto (em vez de doutrina auto |
| 3.0 | `S12_claim_metacog_artifacts` | federation-research-2026-06-reconciled | Artefatos metacognitivos já existem no Onion: diário=automonitorização, conflict_class/valid_when/review_after=autoavaliação |
| 3.0 | `S12_claim_sdaal_gate` | federation-research-2026-06-reconciled | Implementação do canal messenger-autorregulatório exige eixo SDAAL spec-first (parecer §4-C) e é gated |
| 3.0 | `S4_Q_TARGETING_RESOLUTION` | federation-research-2026-06-reconciled | Como resolver o campo alvo: do CHANGELOG por specialization/mode/tier do members.yaml (fatorando o conhecimento coletivo), em vez  |
| 3.0 | `S6_entity_llm_provider_roadmap` | federation-research-2026-06-reconciled | abstração llm-provider planejada (não construída) no roadmap do SDAAL, já marcada como 'caso a repensar' por bootstrapping es |
| 3.0 | `S7_decision_trigger_research` | federation-research-2026-06-reconciled | Gatilho: quando o maestro pedir (\"roda a pesquisa de Onion-como-modelo\"), executar o deep-research harness (fan-out multi-fonte  |
| 3.0 | `S8_ClaimOnionMiniPrimitiveLens` | federation-research-2026-06-reconciled | O onion-mini já é, na prática, a doutrina (master-prompt) interpretada por qualquer Transformer intercambiável (Claude, GPT vi |
| 3.0 | `S9_evidence_heyclicky` | federation-research-2026-06-reconciled | Sinal externo HeyClicky (roteamento de modelo) chegou via docs/evolution/inbox/, foi avaliado e recebeu veredito preliminar — pr |
| 3.0 | `SYNTHESIS.md_TARGETING_SCHEMA_OPEN` | federation-research-2026-06-reconciled | Esquema concreto do resolver de targeting (alvo: como query): sintaxe, precedência entre seletores, closure gated no graph.sh — |
| 2.8 | `B5_1_a2a_export_gated` | federation-research-2026-06-reconciled | Item gated: projeção export-only Agent Card (formato A2A, sem runtime) do members.yaml, condicionada ao 1º consumer não-Onion  |
| 2.8 | `B6_9_decision_backlog_p1p2` | federation-research-2026-06-reconciled | Backlog P1/P2 (não agora): destilar os 5-6 playbooks de onion-patterns como exemplos worked; criar /meta:create-phased-command co |
| 2.7 | `B5_10_camada_a_resolucao` | federation-research-2026-06-reconciled | Os 6 namespaces de plugin resolvem em /help e /plugin list? |
| 2.7 | `S12_q_messenger_channel` | federation-research-2026-06-reconciled | O messenger (whatsapp-sender) serve como canal de prompts autorregulatórios (lembretes de planificação, check-ins de execução |
| 2.4 | `B4_9_question_reavaliar_experimental` | federation-research-2026-06-reconciled | Reavaliar quando Agent Teams sair de experimental (remover ressalva de portabilidade) |
| 2.4 | `B5_5_desconhecidos_sessao_claim` | federation-research-2026-06-reconciled | Limites de visibilidade da sessão: não sabe se a sala de obra já começou algo nessa direção, nem se analyze-complex-problem/ |
| 2.4 | `G1_AIP_PREPRINT_LOW_AUTHORITY` | federation-research-2026-06-reconciled | AIP (Agent Identity Protocol, arXiv 2603.24775v1) existe e afirma delegação verificável cross-MCP/A2A, mas é preprint de autor |
| 2.4 | `G2_QUESTAO_GATILHO_SIGSTORE` | federation-research-2026-06-reconciled | Se um adotante passar a rodar CI que publica artefatos consumidos por terceiros, quando vira barato/idiomático adotar provenance  |
| 2.4 | `S13_question_core_access_sufficient` | federation-research-2026-06-reconciled | Q3: o pedido do maestro ('sem dar acesso ao core') já está satisfeito pela matriz de 4 tiers, ou ele quer graus intermediários  |
| 2.4 | `S13_question_mini_hierarchy_position` | federation-research-2026-06-reconciled | Q4: onde entra o Onion Mini nessa hierarquia — é standalone-por-destilação (5º padrão implícito, precisa nome no vocabulá |
| 2.4 | `S2_SSOT_VS_MESH` | federation-research-2026-06-reconciled | SSOT-central (members.yaml) vs mesh descentralizado (CRDT) para federação: trade-off arquitetural verdadeiro, mas a especificida |
| 2.4 | `S3_q_bildung_self_evolution` | federation-research-2026-06-reconciled | Q2: Bildung (autoformação pela negação como motor) é lente válida para o loop dogfood→erro→doutrina do Onion? |
| 2.4 | `S3_q_bridge_srl_plea` | federation-research-2026-06-reconciled | Q4: a avaliação PLEA (redesenho de estratégia, não mera detecção de discrepância) tem estrutura dialética, com Vygotsky co |
| 2.4 | `S4_CANONICAL_SOURCE_COMPILE` | federation-research-2026-06-reconciled | Cursor/Windsurf: só regras commitadas no repo contam, regras globais por-dev \"drift silently\"; prática é manter fonte canôni |
| 2.4 | `S8_ClaimReadingB` | federation-research-2026-06-reconciled | Leitura (b): Onion como camada de tradução/interpretação — reformata/verifica/contextualiza output bruto de qualquer modelo  |
| 2.4 | `S9_q2_sources` | federation-research-2026-06-reconciled | Q2 — quais fontes primárias (repos, papers, release notes, arXiv, changelogs) compõem o radar, e com que frequência cada uma  |
| 2.0 | `B4_12_question_reopen_lint` | federation-research-2026-06-reconciled | Gatilho de revisão: reabrir o lint de schema se a federação passar a parsear mais campos do stamp por script |
| 2.0 | `G1_TRUST_BLOCK_DELEGATION_Q` | federation-research-2026-06-reconciled | Deve o bloco trust:/members.yaml evoluir para delegação com escopo/consentimento propagável (linha AIP) quando/se o mercado con |
| 2.0 | `S1_trigger_composition_attempt` | federation-research-2026-06-reconciled | Gatilho: maestro pede tentativa real da lente num caso real → executar a partir da tentativa de composição (Q4), não de desig |
| 2.0 | `S6_artifact_engine_economy_kb` | federation-research-2026-06-reconciled | onion-engine-economy.md — destino previsto do achado (nota de doutrina), já trata SLM como ferramenta |
| 1.8 | `B4_11_claim_ns2_ns4_backlog` | federation-research-2026-06-reconciled | NS2 (método portátil multi-plataforma) e NS4 (control-plane hospedado) ficam como backlog — sub-provado e conf 0.30/risco de r |
| 1.8 | `REC_Q_A2A_LIVE_TRAFFIC_UNVERIFIED` | federation-research-2026-06-reconciled | NÃO VERIFIQUEI: se houve tráfego a2a-live REAL além do 1º handshake de 2026-07-09 (metagamify). Não achei no repo fila data/a |
| 1.8 | `S1_real_gap_dependency` | federation-research-2026-06-reconciled | Qual o primeiro gap real (não hipotético) do próprio Onion para dogfoodar a lente? |
| 1.8 | `S1_who_decides_question` | federation-research-2026-06-reconciled | Quem decide 'o que se quer saber' — gate humano (padrão da doutrina) ou uma IA que descobre sozinha o gap? |
| 1.6 | `S6_question_mlops_fit` | federation-research-2026-06-reconciled | quanto de MLOps (drift, re-treino agendado, canary) é genuinamente aplicável ao Onion vs overhead desproporcional, e isso só fa |
| 1.2 | `S1_IDENTITY_DELEGATION_RESEARCH` | federation-research-2026-06-reconciled | Identidade/delegação verificável cross-MCP/A2A (AIP, frameworks de consent) é área de pesquisa ativa em arXiv 2026, não stan |
| 1.2 | `SYNTHESIS.md_CRDT_HYPOTHESIS_UNSOURCED` | federation-research-2026-06-reconciled | \"Mesh-CRDT remove SPOF\" (S2·F11) é hypothesis: a especificidade CRDT não tem fonte primária (o arXiv citado é sobre liqo/mu |
| 1.0 | `S3_q_master_servant_topology` | federation-research-2026-06-reconciled | Q3: dialética senhor-servo (reconhecimento) informa a topologia responder-gated maestro-IA e a co-constituição core↔adotantes |
| 0.6 | `G4_Q_MONOREPO_SIZE` | federation-research-2026-06-reconciled | Qual o tamanho típico de um monorepo enterprise Nx? Sem número único confiável — único data point disponível é o teste Re |

## d5-pricing-2026-07 — 7 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 35.8 | `D_D5` | d5-pricing-2026-07 | D5 — preço por camada (escada treino→certificação→compliance-pack→SOTA). Blend A+B: degraus 1-2 vendíveis-já (compar� |
| 19.2 | `C_compliance_pack` | d5-pricing-2026-07 | DEGRAU 3 Compliance-pack (cunha P4): faixa $15k-40k/ano CITÁVEL não-fechado. Terço inferior do mercado compliance-automation (a |
| 10.8 | `C_sota_subscription` | d5-pricing-2026-07 | DEGRAU 4 Assinatura SOTA: $150-400/mês indiv. · $250-600 base + $60-120/seat empresa. Acima das ferramentas de codificação gen |
| 10.0 | `Q_instrument_value_per_adopter` | d5-pricing-2026-07 | GATE de instrumentação: 'valor medido por adotante' (metrics.md `[a instrumentar]`) — agregação por adotante de 4 sinais que |
| 7.5 | `Q_d2_l1l6_activation` | d5-pricing-2026-07 | GATE D2: a assinatura SOTA vende o mecanismo L1-L6 (classificação-por-inferência + gate-por-propósito + ε-ledger) que segue G |
| 6.6 | `Q_p4_interviews` | d5-pricing-2026-07 | Zero comprador P4 (regulado) entrevistado — o compliance-pack $15-40k é willingness-to-pay não-validado. D6 registra 1-2 entre |
| 4.9 | `Q_train_cert_chaining` | d5-pricing-2026-07 | Encadeamento treino→certificação a validar: a cert pressupõe treino prévio (D4 sequencial) ou é standalone? + espaçamento  |

## onion-identity-2026-07 — 25 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 29.2 | `C_NS1_KG` | onion-identity-2026-07 | NS1: framework que constroi conhecimento reconciliavel vivo (KG); edge mais forte, negocio nao provado |
| 20.0 | `D_METHOD_KG` | onion-identity-2026-07 | construir conhecimento das verticais como KG SDAAL vivo (padrao candidato) |
| 17.5 | `Q_IDENTITY` | onion-identity-2026-07 | o que o Onion e de verdade hoje vs o pitch, e qual o fluxo real |
| 10.8 | `Q_CUSTO_DO_PORTE_NUNCA_MEDIDO` | onion-identity-2026-07 | A LACUNA QUE O REPO CONFESSA E NAO RASTREIA (nomeada 2026-08-06 para PARAR DE SER REDESCOBERTA). O CLAUDE.md linhas 2-9 declara qu |
| 10.0 | `C_ANCORA_SOLTA_79PCT` | onion-identity-2026-07 | A CONTRADICAO MEDIDA DENTRO DA PROPRIA DECISAO DE VALOR: 77 runs de orquestracao com transcript · 19 sinteses versionadas (25%) � |
| 9.6 | `D_PHASE_ORDER` | onion-identity-2026-07 | metodo+grafo primeiro; preenchimento das verticais depois (verticais vazias) |
| 8.0 | `Q_MARKET` | onion-identity-2026-07 | onde somos unicos vs commodity (mercado jul2026, lente edge-core Hagel) |
| 7.5 | `Q_COLD_ADOPTER` | onion-identity-2026-07 | existe QUALQUER pull dos diferenciais raros FORA da orbita de Marcio (1 adotante frio) |
| 7.5 | `Q_COLD_ADOPTER_0717` | onion-identity-2026-07 | org externa e o mesmo que adotante frio? pulse-mais e ORGANIZACAO REAL E EXTERNA (members.yaml:93, correcao do maestro) mas o repo |
| 7.4 | `C_COMPLIANCE_RARE` | onion-identity-2026-07 | compliance-no-loop = vertical RARA que casa com ICP regulado; prova de campo em granaai |
| 7.2 | `Q_METHOD` | onion-identity-2026-07 | como heranca-polimorfismo (RFC-0004/0005) se aplica a construcao de conhecimento |
| 7.0 | `D_COLD_ADOPTER_EXP` | onion-identity-2026-07 | experimento cold-adopter: probe organico (onion-mini+one-pager) + concierge arms-length; 4-6 semanas, guarda anti-vaidade/anti-v4. |
| 6.4 | `C_FATIAS_JA_TESTADAS` | onion-identity-2026-07 | CONSUMO EM FATIAS NAO E HIPOTESE — JA HOUVE TESTE: criacao de plugin e skills para o Onion, incluindo testes de INSTALACAO E USO |
| 6.4 | `D_NO_DISTORT` | onion-identity-2026-07 | nao entortar doutrina: lane-de-conhecimento e GitFlow coexistem (eixos diferentes) |
| 6.0 | `Q_TESTEMUNHO_NAO_MEDIVEL_0804` | onion-identity-2026-07 | nos da classe TESTEMUNHO (verified_against: relato-do-maestro-*) sao estruturalmente nao-re-verificaveis por maquina: afirmam INTE |
| 5.6 | `C_HEGEL_CRITERION` | onion-identity-2026-07 | KG e a tecnica certa quando o conhecimento deixa de ser monotonico (contradicao/Schranke) |
| 5.4 | `Q_DEVELOP_ROLE` | onion-identity-2026-07 | papel canonico da develop: integracao GitFlow ou lane de framework |
| 4.8 | `C_M8_FECHA_SO_UM_TERCO` | onion-identity-2026-07 | GATILHO DECLARADO, com o teto junto: o item M8 do menu da refinaria (corrida serial reescopada, ~300k tokens) fecha UM dos tres nu |
| 4.8 | `C_NS2_PORTABLE` | onion-identity-2026-07 | NS2: metodo portatil/destilavel, familia multi-plataforma (onion-mini + Custom GPT reais; familia nao verificada) |
| 4.8 | `Q_FUTURE` | onion-identity-2026-07 | o que desejamos ser vs o que podemos ser (north-star) |
| 4.0 | `C_NS3_EDU` | onion-identity-2026-07 | NS3: braco de educacao (Descasca/Metodo Onion); mais proximo de caixa, evidencia mais fraca |
| 4.0 | `Q_CLIENT_SCOPE` | onion-identity-2026-07 | cliente de consultoria = escopo (compoe) ou linhagem (ramifica) |
| 3.3 | `C_ICP_TENSION` | onion-identity-2026-07 | tensao nao reconciliada: ICP estreito (regulado+multi-repo) vs 4 personas amplas da KB |
| 3.0 | `Q_BRANCH_MAIN` | onion-identity-2026-07 | onde a main-produto entra no mapa de linhagens do members.yaml |
| 2.4 | `C_NS4_CONTROLPLANE` | onion-identity-2026-07 | NS4: control-plane hospedado + open-core BSL (1 prova regulada granaai; control-plane nao escrito; maior gap desejo-vs-poder) |

## company-brain-market-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 27.0 | `D_mais_valor` | company-brain-market-2026-07 | MAIS-VALOR: fechar o gap N-tenant do L1 (schema-masking multi-tenant) — transforma 'Personal Brain N=1' em 'Company Brain prová |
| 12.0 | `D_mais_proximo` | company-brain-market-2026-07 | MAIS-PRÓXIMO (menor esforço × maior prob.): re-embalar ativos que já existem — nomear o KG como 'Company Brain de projeto' n |
| 8.2 | `Q_ntenant_proof` | company-brain-market-2026-07 | Gap mais crítico p/ 'Company' (vs pessoal): a prova N=1 pessoal NÃO generaliza p/ multi-tenant (múltiplos leitores do mesmo gra |
| 6.6 | `Q_p4_instrument` | company-brain-market-2026-07 | Pré-req de D2/mais-valor: instrumentar 1-2 prospects P4 reais + 'valor medido por adotante'. Sem isso, 'Company Brain regulado' � |

## guardas-revisao-2026-08 — 6 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 21.6 | `Q_GUARDAS_COERENTES` | guardas-revisao-2026-08 | as guardas nascidas reativamente formam um sistema coerente, sem sobreposicao cega nem lacuna? |
| 9.0 | `C_R45_COBERTURA_FALSA` | guardas-revisao-2026-08 | a R45 cobre 1 de 9 raizes vendorizadas — 46 links vivos p/ caminho core-privado em 21 arquivos ficam fora; o baseline em 0 decla |
| 6.0 | `C_DOCSTRINGS_STALE` | guardas-revisao-2026-08 | R45 diz "nasce com 101" (baseline tem 0) e R44 diz "tudo em HUMAN" (15 classes, 1 MONITORED) — declarado != verificado DENTRO da |
| 5.4 | `C_DUPLICACAO_4_CLONES` | guardas-revisao-2026-08 | REGRAS 21/38/24/25 sao clones byte-identicos apos normalizar literais — helper economizaria ~69 linhas e daria UM lugar p/ o 2>/ |
| 5.4 | `C_R28_R46_DOUBLE_FIRING` | guardas-revisao-2026-08 | R28 classe (1) e R46 detectam a MESMA condicao — um dir orfao com 3 anuncios emite 4 SOFT para um fato so; cura e amputar a clas |
| 5.4 | `C_SEM_GATE_REGRA_SEM_TESTE` | guardas-revisao-2026-08 | nao existe gate regra-sem-fixture; o STRICT do CI reprova skip por tooling ausente, o que e outra coisa — candidato a 6a catraca |

## elenxos-2026-08-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 20.0 | `Q_SDAAL_NAO_TEM_CONSUMIDOR_SEM_LLM` | elenxos-2026-08-07 | ABERTO, e a F4 so tapou o primeiro caso: o SDAAL e Markdown lido por LLM ('documentacao substitui codigo executavel'). Um step de  |
| 8.0 | `E_LINT_NAO_ENXERGA_WORKFLOWS` | elenxos-2026-08-07 | POR QUE NINGUEM VIU: as REGRAS 10 e 11 (anti-provider-direto e forge-method-existe) varrem APENAS `.claude/commands` e `.claude/ag |
| 8.0 | `Q_SDAAL_EXECUTAVEL_ONDE_PARA` | elenxos-2026-08-07 | ABERTO: a F4 abriu a primeira peca EXECUTAVEL dentro de `.claude/utils/forge/` — necessaria porque um step de Actions e shell pu |
| 5.4 | `E_ALLOWLIST_NO_KG_VIEW` | elenxos-2026-08-07 | SITIO 3 (NAO CURADO): kg-view.sh:101-107 carrega uma COPIA de statusFactor que nao conhece os status novos — retorna -1, clampad |

## identidade-onion-vps-2026-08 — 5 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 20.0 | `Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA` | identidade-onion-vps-2026-08 | ⚠️ ATUALIZADO 2026-08-13 — O BLOQUEIO DEIXOU DE SER CONCEITUAL E VIROU UMA CONTA. Com [Q_CUSTODIA_DA_CHAVE_GPG_FORA_DA_VPS]  |
| 12.0 | `Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` | identidade-onion-vps-2026-08 | ACHADO DE ADOTANTE, ainda NAO COMUNICADO — acao pendente do maestro, nao minha. Medido em `/home/marcio/onion-adopt-arandek/dock |
| 12.0 | `Q_LACUNA_DECISAO_MAIS_CODIGO` | identidade-onion-vps-2026-08 | A OPORTUNIDADE, e ela e de diferenciacao e nao de divida. A pesquisa nao achou NENHUM sistema publico que una grafo de DECISAO e g |
| 6.0 | `Q_A_SENHA_DA_CHAVE_QUEBROU_A_AUTOMACAO` | identidade-onion-vps-2026-08 | O PRECO DE PROTEGER A CHAVE, e ele e real — decisao do maestro, nao minha. Por A chave GPG ganhou passphrase (era o segredo de m |
| 5.4 | `Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` | identidade-onion-vps-2026-08 | A guarda `vps-exposure-check.sh` cobre o lado de CA (bind publico em container vivo, conector upstream, backup em claro) e roda di |

## gtm-decisions-2026-07 — 7 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 15.6 | `D_D5` | gtm-decisions-2026-07 | D5 — preço por camada (treino→certificação→compliance-pack→curadoria SOTA): A (escada por comparáveis) vs B (adiar/sob |
| 13.0 | `C_D5_rec` | gtm-decisions-2026-07 | REC D5: BLEND A+B — escada por comparáveis SÓ p/ degraus vendíveis já (treino day-rate ~$1.2-2k; certificação $795-$1.5k + |
| 7.5 | `D_D2_activation` | gtm-decisions-2026-07 | D2-ATIVAÇÃO — ligar o flywheel de moeda-dado (SSOT 6 camadas L1-L6 de mitigação de inferência, dogfoodado). Direção RATIF |
| 6.0 | `Q_d6_message_vs_pipeline` | gtm-decisions-2026-07 | D6 mistura 'comprador da MENSAGEM' com 'comprador que fatura PRIMEIRO' — o maestro precisa decidir se D6 é POSICIONAMENTO (a qu |
| 5.0 | `Q_instrument_metrics` | gtm-decisions-2026-07 | Falta 'valor medido por adotante' (metrics.md `[a instrumentar]`) + taxa de conversão free→paid (sem benchmark p/ frameworks de |
| 4.4 | `Q_open_trigger` | gtm-decisions-2026-07 | Qual o GATILHO concreto de 'abrir publicamente' o standalone (métrica/data/nº de adotantes provados/aprovação do maestro)? É  |
| 4.4 | `Q_p4_no_field_proof` | gtm-decisions-2026-07 | Zero adotante P4 (regulado) provado hoje — escolher P4 como mensagem é aposta em whitespace de pesquisa, não ICP validado. Fal |

## vps-shared-tools-2026-07 — 15 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 14.4 | `ENT_email` | vps-shared-tools-2026-07 | EMAIL: NAO EXISTE — gap nomeado. Logto SEM conector de email travou convite por org (forcou redesenho --enroll). Servico de emai |
| 10.8 | `A_analysis_structure` | vps-shared-tools-2026-07 | ESTRUTURA DE ANALISE INICIAL (4 fases, antes do plano): F0 frame+invariantes+Elenxo catalogo-vs-plataforma · F1 pesquisa por-tool |
| 10.8 | `Q_juiz_adversarial_nao_rodou_m8` | vps-shared-tools-2026-07 | ABERTO: a corrida serial do M8 voltou com 44% de veredito DRIFTED (4/9), acima do limiar de 30% que o /meta:kg-freshness usa para  |
| 9.0 | `Q_monitoring_stack` | vps-shared-tools-2026-07 | PESQUISA+ELENXO: stack de observabilidade — Langfuse (LLM) × OpenTelemetry (traces/metrics padrao) × P2(?) × afins. Eixo: LLM |
| 8.0 | `D_email_plus_logto_connector` | vps-shared-tools-2026-07 | DIRECAO: construir o servico de EMAIL E LIGAR o conector de email no LOGTO (destrava convite por org, o gap medido). Um so servico |
| 6.3 | `ENT_monitoring` | vps-shared-tools-2026-07 | MONITORAMENTO/OBSERVABILIDADE: candidato, zero desenho. Maestro nomeou P2 (a esclarecer — Prometheus/Posthog/Phoenix?), Langfuse |
| 6.0 | `Q_email_logto_conector_nunca_medido` | vps-shared-tools-2026-07 | ABERTO: D_email_plus_logto_connector e DIRECAO pura ('construir o servico de EMAIL e ligar o conector'), sem estado material mediv |
| 6.0 | `Q_email_provider` | vps-shared-tools-2026-07 | PESQUISA: provider de email — SMTP self-host (Postfix/maddy) vs transacional (Resend/Postmark/SES) — deliverability, custo, e  |
| 4.8 | `C_axis_email` | vps-shared-tools-2026-07 | TESTE-DO-EIXO email: SMTP self-host x API transacional (Resend/Postmark/SES) — SDAAL-CANDIDATO se >=2 reais intencionados; hoje  |
| 4.8 | `C_axis_monitoring` | vps-shared-tools-2026-07 | TESTE-DO-EIXO monitoramento: DIVIDE em (a) obs-de-MAQUINA (PM2/OTel/Prometheus) = contratos DISTINTOS nao-intercambiaveis -> STACK |
| 4.2 | `C_dissent_auth_transversal` | vps-shared-tools-2026-07 | DISSENT (sobrevivente, vigiar): auth NAO e adapter-par — e alicerce TRANSVERSAL que whatsapp/email/monitoramento assumem como da |
| 4.0 | `Q_p2_clarify` | vps-shared-tools-2026-07 | ESCLARECER com o maestro: o que e 'P2' no monitoramento? (Prometheus? Posthog? Phoenix/Arize? Pydantic Logfire?) — nome nao reso |
| 4.0 | `Q_tunneling` | vps-shared-tools-2026-07 | PESQUISA+ELENXO: ngrok × Cloudflare Tunnel × Tailscale Funnel × Caddy-so. Para QUE (dev-preview? webhook inbound? exposicao efe |
| 3.6 | `ENT_tunneling` | vps-shared-tools-2026-07 | EXPOSICAO/TUNNELING: ngrok nomeado como interessante. Avaliar fit vs o Caddy ja vivo + alternativas (Cloudflare Tunnel, Tailscale  |
| 3.2 | `C_axis_tunneling` | vps-shared-tools-2026-07 | TESTE-DO-EIXO tunneling: ngrok/Cloudflare-Tunnel/Tailscale sao intercambiaveis -> SDAAL-candidato SE o caso-de-uso exigir troca de |

## guardrails-2nd-pr-state-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 13.5 | `C_SURFACE_REMAINS_GATED` | guardrails-2nd-pr-state-2026-07 | o UNICO residuo real e a superficie /meta:guardrails — GATED (fio #4 do promotion-plan). Relabel ONION-Rn amplo = docs-pass opci |
| 4.0 | `Q_REVERSE_JOIN_SCOPE` | guardrails-2nd-pr-state-2026-07 | GATED/deferido: o join-reverso (arquivo->guardrails que governam) so vira ferramenta barata SE as guardas passarem a self-declarar |

## catraca-regra49-2026-08 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 12.8 | `C_MESMA_CLASSE_MUDA_DE_CAMPO_A_CADA_RODADA` | catraca-regra49-2026-08 | Fio de METODO, e e o que esta rodada mais ensina. Dois dos quatro achados confirmados (a direcao da aresta e o `git mv` para `fixt |
| 10.0 | `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES` | catraca-regra49-2026-08 | As CINCO classes novas nao tem NENHUMA cobertura de campo. `--emit-baseline` e hoje identico ao baseline versionado, logo o laco d |
| 8.0 | `Q_GIT_MV_ESVAZIA_O_BASELINE_EM_LOTE` | catraca-regra49-2026-08 | Divida que sai deste PR de proposito: um `git mv` de UM grafo para qualquer pasta `fixtures/` tirou CINCO entradas do baseline de  |

## constellation-dialogic-layer-2026-07 — 7 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 10.8 | `D_ARISTOTLE_HOME_CANDIDATE` | constellation-dialogic-layer-2026-07 | dar casa canonica a Aristoteles e candidato gated, nao promocao agora |
| 10.4 | `D_ARISTOTLE_HOME_IS_KB` | constellation-dialogic-layer-2026-07 | recomendacao: casa = KB focada da regua de transferencia, cross-link SDAAL/adopt (o vivido) + Hegel/Bloom (irmas) — promocao foc |
| 9.0 | `R_NO_MEASURE_WITHOUT_DOGFOOD` | constellation-dialogic-layer-2026-07 | nao tratar confidence ATRIBUIDA como medicao sem dogfood real (honrar os dois-quantitativos) |
| 5.6 | `D_STORE_GATED` | constellation-dialogic-layer-2026-07 | guardar como pesquisa de core design-only/gated, NAO mesclar — julgamento conjunto (nao promovido) |
| 5.4 | `C_BOLETIM_INFORM` | constellation-dialogic-layer-2026-07 | 3o uso: o boletim core->estrela INFORMA a estrela do que virou main (simetrico ao carteiro star->core PUSH) — 3 travas: contexto |
| 4.0 | `D_ISOLATION_EXTENSION_GATED` | constellation-dialogic-layer-2026-07 | GATED: estender a linha so-metadados (hoje 'frontmatter+Tier-0') p/ incluir o .kg.yaml como superficie publica precisa ratificacao |
| 3.6 | `D_BOLETIM_CANDIDATE` | constellation-dialogic-layer-2026-07 | documentar o boletim como padrao CANDIDATO — emergiu 1x (Rule of Three nao cumprida); vira firme por recorrencia/uso, nao por es |

## context-freshness-2026-08-12 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 9.0 | `Q_CONTAGEM_DE_ADOTANTES_STALE_EM_DOIS_DOCS_DE_BUSINESS` | context-freshness-2026-08-12 | DOIS docs de business afirmam '4 adotantes' e o vivo diz 8: `business/metrics.md` ('1 core + 4 adotantes', e o proprio texto admit |
| 6.0 | `Q_ORCAMENTO_DE_CI_MEDIDO_CONTRA_ARTEFATO_41PCT_MENOR` | context-freshness-2026-08-12 | O `contributing.md` apresenta um ORCAMENTO DE CI como 'medido 2026-07-20': '~7,5min total, teto timeout-minutes: 15', com o lint e |

## colaboracao-onion-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.4 | `D_PRODUTOS_CORE` | colaboracao-onion-2026-07 | propor 6 produtos deriaveis ao core (gerador de vertical, deck de treino, retro-skill, etc.) |
| 4.5 | `E_RETRO` | colaboracao-onion-2026-07 | retro do parceiro (Gustavo) — instrumento criado; coleta em andamento |
| 4.0 | `Q_AUTORIZACAO_NAO_FORMALIZADA` | colaboracao-onion-2026-07 | perfil colaborador-visitante + boundary de autorizacao de relay ainda nao formalizados no core |
| 3.0 | `Q_RETRO_PENDENTE` | colaboracao-onion-2026-07 | o que a retro do Gustavo vai confirmar/refutar sobre o processo? |

## granaai-doctrine-absorption-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.1 | `C_S3b` | granaai-doctrine-absorption-2026-07 | FEATURE: --update deixa docs/onion/inventory.md stale (inventory.sh so roda na Fase 3 da adocao) — lint HARD bloqueia o 1o commi |
| 4.8 | `C_S4` | granaai-doctrine-absorption-2026-07 | FEATURE: /meta:kg map projeto (canonicalizacao de monorepo) — hoje map area existe, projeto/monorepo aberto |

## librechat-kg-runtime-2026-08 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.1 | `Q_TENANT_WRITE_DESTINATION` | librechat-kg-runtime-2026-08 | BURACO revelado pela selagem: a escrita de um chat no PAPEL-DE-NEGOCIO (tenant) precisa de destino FORA do core (fila do tenant/ad |
| 7.7 | `Q_MAP_LEG_GATED` | librechat-kg-runtime-2026-08 | BURACO exposto pelo protocolo: a perna MAP (ingestao doc->grafo) nao tem tool no core — existe so na PoC (ingerir_documento_cola |
| 6.0 | `Q_WEB_SEARCH_GAP` | librechat-kg-runtime-2026-08 | A face conversavel do Onion (MCPs onion-framework/kg/exec) nao tem tool de busca/crawling web — como mapear um dominio externo q |
| 3.2 | `D_ROUTE_TO_BRIDGE` | librechat-kg-runtime-2026-08 | Enquanto a gap de web nao for resolvida: requisicoes de mapeamento de dominio externo vao ao Claude Code/Bridge (execucao plena),  |

## federation-health-2026-07 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.0 | `C_METAGAMIFY_VENDOR_VNEXTPIN` | federation-health-2026-07 | metagamify onion/vendor tem 1 pin INVALIDO na historia: '2026-07-12' (uma DATA, nao commit — vnextpin). Merge-base pode ficar er |
| 6.0 | `C_GRANAAI_LINEAGES_UNKNOWN` | federation-health-2026-07 | granaai linhagens mauricio (pin nao-verificavel-deste-host) e leonardo-offline (pin desconhecido) — estado de verificacao INDETE |
| 3.6 | `C_ADOPTER_PERSONALITY_SEEDS_PENDING` | federation-health-2026-07 | 6 dos 7 adotantes seguem personality_summary SEED MANUAL datado (o 7o, marcio-pessoal, e gated/n-a soberano) — o sync e por-inst |

## graduated-automation-elenxo-2026-07 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.0 | `Q_MONITORED_RUNG` | graduated-automation-elenxo-2026-07 | Onda 2: como nomear+mecanizar o degrau MONITORADO (shadow, roda+observado)? promover o onion-effect-gate.sh orfao; dogfood INTERNO |
| 6.0 | `Q_COUNTABLE_CRITERIA` | graduated-automation-elenxo-2026-07 | Onda 3: criterios de promocao CONTAVEIS (N execucoes monitoradas sem anomalia => destrava) + rollback provado como pre-condicao de |
| 6.0 | `Q_PREDICTIVE_ALERTS` | graduated-automation-elenxo-2026-07 | Onda 4: alertas PREDITIVOS — territorio novo (o core e reativo/CI-safe por design). anteceder a falha da automacao antes de ela  |

## arandek-adoption-dogfood-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 7.2 | `D_GREP_OLD_PIN` | arandek-adoption-dogfood-2026-07 | BACKLOG (nao implementado; priorizar e do maestro). No /meta:adopt --update, apos reescrever o .onion-version: `grep -rl <pin-anti |
| 7.2 | `Q_ARANDEK_UPDATE` | arandek-adoption-dogfood-2026-07 | quando o arandek rodar /meta:adopt --update, recebe os 6 fixes; o contorno do D1 dele (technical-context ponteiro) simplifica p/ d |
| 3.2 | `Q_RELAY` | arandek-adoption-dogfood-2026-07 | relay do sinal (docs/evolution/inbox do arandek → inbox do core via /meta:co-relay) pendente — território da sessão do adota |
| 2.0 | `Q_PIN_GREP_WORTH_IT` | arandek-adoption-dogfood-2026-07 | FRONTEIRA DECLARADA PELO PROPRIO ADOTANTE (R15.2 — registrada como observacao, nao como pedido): 'pode ser que o custo nao compe |

## elenxo-mecanismos-lint-2026-08-13 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.4 | `Q_MUDEZ_DA_GUARDA_NAO_SE_IDENTIFICA` | elenxo-mecanismos-lint-2026-08-13 | O TETO DA GUARDA DIRTY-TREE GANHA DONO NO GRAFO (8o Elenxo, fechamento do Q_PARECER): no caminho benigno a guarda NAO emite nada � |

## onion-evolution-2026-07-30 — 6 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.4 | `C_d6_sysdoc_mcp` | onion-evolution-2026-07-30 | D6/recommended: system-documentation-orchestrator usa mcp_code-understanding_* (4 chamadas sequenciais em prosa) mas NÃO o declar |
| 3.2 | `C_d3_storypoints_dup` | onion-evolution-2026-07-30 | D3/recommended: workflow de story-points duplicado em 3 comandos (task/estimate/feature, ~100 linhas cumulativas). Padrão: consol |
| 2.8 | `C_d2_analysis_diff` | onion-evolution-2026-07-30 | D2/opportunistic: /quick:analysis × /meta:analyze-complex-problem — mesmo verbo, mesmo destino (docs/analysis/), sem nota de di |
| 2.8 | `C_d3_comment_dup` | onion-evolution-2026-07-30 | D3/opportunistic: template de comentário Unicode duplicado entre product/task.md e product/feature.md (~40 linhas). Padrão: comm |
| 2.4 | `C_d2_test_diff` | onion-evolution-2026-07-30 | D2/opportunistic (ENFRAQUECIDO na verificação): test-agent × test-planner. O corpo do test-agent JÁ TEM '### Com test-planner: |
| 1.2 | `C_d7_discussion_links` | onion-evolution-2026-07-30 | D7/opportunistic (baixo valor): docs de DISCUSSÃO (onion-pessoal-marcio, proto/README, technical-context/contributing) usam links |

## onion-doctrine-elenxo-bulbo-2026-07 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.1 | `D_QUADRO_CITACOES` | onion-doctrine-elenxo-bulbo-2026-07 | quadro de citacoes do maestro NASCEU (gated): as formulacoes recorrentes dele, atribuidas+datadas (verbatim vs parafrase marcado)  |
| 2.4 | `Q_PUBLICATION_AREA` | onion-doctrine-elenxo-bulbo-2026-07 | a area de publicacao de doutrinas ainda nao existe — onde e como a pagina gradua de gated a publica (grupo fechado primeiro)? |
| 1.6 | `Q_BULBO_DIAGRAM` | onion-doctrine-elenxo-bulbo-2026-07 | um visual do Bulbo (cebola cortada: as 4 camadas + o corte que revela tudo) e candidato quando graduar — vale o espaco? |

## kg-console-rich-design-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_f3_wow` | kg-console-rich-design-2026-07 | F3 wow polish (partículas em arestas, semantic-zoom, minimapa, scrollytelling) — gated, eye-candy destacável; vai por último  |
| 2.0 | `Q_live_narration` | kg-console-rich-design-2026-07 | Narração LIVE opcional (POST a um LLM 'explique esta seleção') como enhancement que degrada gracioso offline — gated; a pré |

## kg-diagnose-automation-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_orquestrador_gated` | kg-diagnose-automation-2026-07 | Follow-up GATED (2º passo): um comando que ROLA a sequência extract→consolidate→candidatos disparando agentes sozinho? Merec |

## kg-diagnose-design-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_automacao_pipeline` | kg-diagnose-design-2026-07 | Follow-up GATED: um orquestrador que encadeia extract→consolidate→diagnose automaticamente? Decisão do maestro: NÃO agora � |

## residuos-2026-08-18 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_ALARME_DE_AUSENCIA_DE_AGENDADO` | residuos-2026-08-18 | GATED por Teste do Gatilho — alarme para agendado que PARA de rodar. GATILHO NOMEADO: a 1a vez que um run com event=schedule for |

## vendor-multi-branch-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_volume_not_reproduced` | vendor-multi-branch-2026-07 | Reproduzimos a CLASSE (conflito contabil em codigo de aplicacao por vendor branch-especifico), NAO os 110 arquivos. O volume depen |
| 2.0 | `Q_three_or_more_branches` | vendor-multi-branch-2026-07 | Tres ou mais integration branches nao foram exercitadas. A convencao por-branch se estende por CONSTRUCAO, mas isso e inferencia,  |

