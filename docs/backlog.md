# Backlog vivo — projeção dos grafos ⚙️ GERADO

> Gerado por `.claude/validation/kg-backlog-project.sh` a partir dos nós `status: open` da
> camada canônica (`docs/onion/graph/`, exceto arquivos opt-OUT) + grafos marcados. **Não editar à mão**: feche o
> item no grafo (status ≠ open, com carimbo) e ele sai daqui. Ordem = atenção (a régua do
> radar: impact × incerteza × status). Sem corte NO ESCOPO; 2 grafo(s) de arquivo (opt-OUT) ficam fora — visíveis via `kg-radar --open-tsv`.

**160 itens abertos** em 30 grafo(s) com aberto (de 45 no escopo) · 30 grupo(s). **Nenhum nó declara `owner:`** — o agrupamento é por GRAFO (o fallback). A fila de decisão/execução do core; o topo por atenção é o que "custa caro estar errado".

## m3-federation-admin-2026-07 — 17 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 64.0 | `D_spec_now_build_gated` | m3-federation-admin-2026-07 | SPEC-agora / BUILD-gated — especificar o command-side (mutação de members.yaml) + modelo de auth (Logto Organizations) SEM con |
| 18.0 | `C_reuse_readmodel` | m3-federation-admin-2026-07 | REUSAR o read-model já entregue: console HTML (F1.3), federation-radar (3 checks advisory), pin-integrity-check (gate real), grap |
| 15.6 | `C_auth_logto_sdaal` | m3-federation-admin-2026-07 | AUTH = fronteira gated (o BUILD não se pré-cozinha, gated-work-derives-fresh). Comprometido: só a fronteira §4.3 + a invariân |
| 11.2 | `C_op_update` | m3-federation-admin-2026-07 | OP-3 ATUALIZAR (pin/trust/specializations/personality_summary): escrever onion_version novo (pós pin-integrity-check) e editar a  |
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
| 3.6 | `Q_members_ci_gate` | m3-federation-admin-2026-07 | M2 (revisão adversarial 2026-08-27): members-validate.sh valida na ROTA do comando (Passo 7) e no selftest sobre fixtures, mas N |
| 3.3 | `Q_auth_decision` | m3-federation-admin-2026-07 | Plugar Logto no command-side é decisão do maestro, ainda NÃO tomada (o bridge hoje usa AUTH_TOKEN próprio, não Logto). Auth b |
| 2.0 | `Q_wake_session` | m3-federation-admin-2026-07 | GAP de design/dogfood aberto (não pesquisa): evoluir o receiver git-async para 'acordar a sessão' via SSE/webhook sem quebrar pu |

## m2-bridge-logto-2026-07 — 31 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 45.0 | `D_default_deny_routes` | m2-bridge-logto-2026-07 | DEFAULT-DENY (aprovado pelos verifies, PRESERVADO): o middleware É montado globalmente, mas existe uma ALLOWLIST ANCORADA do que  |
| 25.6 | `D_resource_plan_b` | m2-bridge-logto-2026-07 | ESCADA A->B1->B2->B3 (aprovada pelos verifies, PRESERVADA) — PROVA ANTES do desenho depender (P4.1) + PLANO-B escrito: A = resou |
| 22.4 | `D_logto_same_protection_tier` | m2-bridge-logto-2026-07 | FIX D+A fecho — elevar Logto+Postgres ao MESMO patamar, agora em 3 CAMADAS (a v2 tinha 2 e a de baixo era decorativa): (1) /etc/ |
| 18.0 | `D_middleware_order_first` | m2-bridge-logto-2026-07 | FIX C fecho — EXIGÊNCIA no P5: app.use('*', requireIdentity) é o PRIMEIRO handler registrado, antes de TODA rota, de TODO app. |
| 13.5 | `C_hono_registration_order_bypass` | m2-bridge-logto-2026-07 | FIX C — no Hono a cadeia segue a ORDEM DE REGISTRO: um handler registrado ANTES do app.use('*', requireIdentity) responde SEM PA |
| 10.8 | `C_docker_floor_gap` | m2-bridge-logto-2026-07 | GAP (impacto ELEVADO na v2+, porque o Logto virou caminho crítico): Logto+Postgres (docker) só têm teto duro. MEDIDO no cgroup: |
| 10.8 | `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA` | m2-bridge-logto-2026-07 | PRE-EXISTENTE, mas o P11 ELEVOU O RAIO — e essa mudanca de risco precisa morar aqui: antes, numa queda do Logto, o caminho legad |
| 10.2 | `D_logto_not_ssot` | m2-bridge-logto-2026-07 | INVARIANTE herdada do M3: Logto = emissor/validador de identidade (commodity-BUY), NUNCA SSOT de autorização fina. A autorizaç |
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
| 5.1 | `Q_docker_cgroup_driver` | m2-bridge-logto-2026-07 | FIX L2 — PROVA NOVA no P0.6: a semântica de cgroup_parent DEPENDE do cgroup driver do docker. MEDIDO hoje: driver = systemd (h |
| 4.8 | `Q_signup_close_not_via_api` | m2-bridge-logto-2026-07 | DIVIDA NOMEADA: o fechamento do registro do tenant `admin` (sign_up identifiers -> []) foi feito por SQL direto, nao pela API nem  |
| 4.2 | `Q_p10_mutation_not_run` | m2-bridge-logto-2026-07 | FRONTEIRA DECLARADA: o controle de mutacao (remover o filtro e reprovar que o canario passa) NAO foi rodado — exigiria desligar  |
| 4.0 | `Q_offline_fallback_truth` | m2-bridge-logto-2026-07 | NAO RESPONDIDO pelo ADR: hoje o correio funciona OFFLINE — o arquivo esta la e o adotante le quando quiser. Com pull, bridge for |
| 3.6 | `Q_gated_m3` | m2-bridge-logto-2026-07 | GATED (não neste flip): RBAC MULTI-OPERADOR / plataforma admin M3 (Logto Organizations só no gatilho 1º role:consumer real) — |
| 3.6 | `Q_pwa_sse_headers` | m2-bridge-logto-2026-07 | FIX M — MANTIDO E DESTACADO (§3.4d próprio, não mais nota de rodapé). LOAD-BEARING a confirmar (P0.3): EventSource NÃO perm |
| 3.4 | `C_console_autooff_gap` | m2-bridge-logto-2026-07 | GAP: console.sh só tem on/off/status manuais (medido: o case tem on) off) status) e mais nada; console desligado agora). Fecho: n |
| 3.0 | `Q_slices_2_to_4_unexercised` | m2-bridge-logto-2026-07 | As fatias 2-4 (Organizations = membros, org roles = tiers, convites, a2a por app) sao DESENHO, nao medicao. So a fatia 1 (um M2M a |
| 2.4 | `Q_default_api_resource_b1` | m2-bridge-logto-2026-07 | FIX J — o 'default API resource do tenant' era apresentado como FALLBACK PREFERIDO (B1) SEM VERIFICAÇÃO NENHUMA: tão VPS-DECL |
| 1.6 | `Q_byok_courtesy_mode` | m2-bridge-logto-2026-07 | INFERÊNCIA A VERIFICAR: a citação '2 modos cortesia-login + BYOK (X-Anthropic-Key)' vem do app-irmão onion-pessoal-app, NÃO d |

## d5-pricing-2026-07 — 6 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 35.8 | `D_D5` | d5-pricing-2026-07 | D5 — preço por camada (escada treino→certificação→compliance-pack→SOTA). Blend A+B: degraus 1-2 vendíveis-já (compar |
| 19.2 | `C_compliance_pack` | d5-pricing-2026-07 | DEGRAU 3 Compliance-pack (cunha P4): faixa $15k-40k/ano CITÁVEL não-fechado. Terço inferior do mercado compliance-automation (a |
| 10.8 | `C_sota_subscription` | d5-pricing-2026-07 | DEGRAU 4 Assinatura SOTA: $150-400/mês indiv. · $250-600 base + $60-120/seat empresa. Acima das ferramentas de codificação gen |
| 7.5 | `Q_d2_l1l6_activation` | d5-pricing-2026-07 | GATE D2: a assinatura SOTA vende o mecanismo L1-L6 (classificação-por-inferência + gate-por-propósito + ε-ledger) que segue G |
| 6.6 | `Q_p4_interviews` | d5-pricing-2026-07 | Zero comprador P4 (regulado) entrevistado — o compliance-pack $15-40k é willingness-to-pay não-validado. D6 registra 1-2 entre |
| 4.9 | `Q_train_cert_chaining` | d5-pricing-2026-07 | Encadeamento treino→certificação a validar: a cert pressupõe treino prévio (D4 sequencial) ou é standalone? + espaçamento  |

## onion-identity-2026-07 — 22 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 29.2 | `C_NS1_KG` | onion-identity-2026-07 | NS1: framework que constroi conhecimento reconciliavel vivo (KG); edge mais forte, negocio nao provado |
| 10.8 | `Q_CUSTO_DO_PORTE_NUNCA_MEDIDO` | onion-identity-2026-07 | A LACUNA QUE O REPO CONFESSA E NAO RASTREIA (nomeada 2026-08-06 para PARAR DE SER REDESCOBERTA). O CLAUDE.md linhas 2-9 declara qu |
| 8.0 | `Q_MARKET` | onion-identity-2026-07 | onde somos unicos vs commodity (mercado jul2026, lente edge-core Hagel) |
| 7.5 | `Q_COLD_ADOPTER` | onion-identity-2026-07 | existe QUALQUER pull dos diferenciais raros FORA da orbita de Marcio (1 adotante frio) |
| 7.5 | `Q_COLD_ADOPTER_0717` | onion-identity-2026-07 | org externa e o mesmo que adotante frio? pulse-mais e ORGANIZACAO REAL E EXTERNA (members.yaml:93, correcao do maestro) mas o repo |
| 7.4 | `C_COMPLIANCE_RARE` | onion-identity-2026-07 | compliance-no-loop = vertical RARA que casa com ICP regulado; prova de campo em granaai |
| 7.2 | `Q_FEDERACAO_VISIBILITY_GATE` | onion-identity-2026-07 | site/federacao/ e snapshot congelado (2026-07-10) por DECLARACAO, nao por mecanismo (achados R3+NOVO-4 da revisao do PR #671): nad |
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

## company-brain-market-2026-07 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 27.0 | `D_mais_valor` | company-brain-market-2026-07 | MAIS-VALOR: fechar o gap N-tenant do L1 (schema-masking multi-tenant) — transforma 'Personal Brain N=1' em 'Company Brain prová |
| 8.2 | `Q_ntenant_proof` | company-brain-market-2026-07 | Gap mais crítico p/ 'Company' (vs pessoal): a prova N=1 pessoal NÃO generaliza p/ multi-tenant (múltiplos leitores do mesmo gra |
| 6.6 | `Q_p4_instrument` | company-brain-market-2026-07 | Pré-req de D2/mais-valor: instrumentar 1-2 prospects P4 reais + 'valor medido por adotante'. Sem isso, 'Company Brain regulado'  |

## guardas-revisao-2026-08 — 7 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 21.6 | `Q_GUARDAS_COERENTES` | guardas-revisao-2026-08 | as guardas nascidas reativamente formam um sistema coerente, sem sobreposicao cega nem lacuna? |
| 8.1 | `C_DUPLICACAO_4_CLONES` | guardas-revisao-2026-08 | REGRAS 21/38/24/25 sao clones byte-identicos apos normalizar literais — helper economizaria ~69 linhas e daria UM lugar p/ o 2>/ |
| 8.1 | `Q_INDICE_DO_DIARIO_SEM_CATRACA` | guardas-revisao-2026-08 | LACUNA DE COBERTURA medida em 2026-08-28: `.claude/diary/index.md` e projecao GERADA e nao tem catraca de em-sync, ao contrario do |
| 8.0 | `Q_TRES_GRAFOS_NAO_SAO_YAML_VALIDO` | guardas-revisao-2026-08 | DECLARADO != VERIFICADO NO PROPRIO FORMATO DA SSOT. O formato se chama `.kg.yaml` e 4 de 75 arquivos NAO passavam num parser YAML  |
| 6.0 | `C_DOCSTRINGS_STALE` | guardas-revisao-2026-08 | R45 diz "nasce com 101" (baseline tem 0) e R44 diz "tudo em HUMAN" (15 classes, 1 MONITORED) — declarado != verificado DENTRO da |
| 5.4 | `C_R28_R46_DOUBLE_FIRING` | guardas-revisao-2026-08 | R28 classe (1) e R46 detectam a MESMA condicao — um dir orfao com 3 anuncios emite 4 SOFT para um fato so; cura e amputar a clas |
| 5.4 | `C_SEM_GATE_REGRA_SEM_TESTE` | guardas-revisao-2026-08 | nao existe gate regra-sem-fixture; o STRICT do CI reprova skip por tooling ausente, o que e outra coisa — candidato a 6a catraca |

## catraca-regra49-2026-08 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 20.0 | `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES` | catraca-regra49-2026-08 | As CINCO classes novas nao tem NENHUMA cobertura de campo. `--emit-baseline` e hoje identico ao baseline versionado, logo o laco d |
| 12.8 | `C_MESMA_CLASSE_MUDA_DE_CAMPO_A_CADA_RODADA` | catraca-regra49-2026-08 | Fio de METODO, e e o que esta rodada mais ensina. Dois dos quatro achados confirmados (a direcao da aresta e o `git mv` para `fixt |
| 8.0 | `Q_GIT_MV_ESVAZIA_O_BASELINE_EM_LOTE` | catraca-regra49-2026-08 | Divida que sai deste PR de proposito: um `git mv` de UM grafo para qualquer pasta `fixtures/` tirou CINCO entradas do baseline de  |
| 2.4 | `D_SCRUB_FROZEN_POISON_IN_VENDORS` | catraca-regra49-2026-08 | FOLLOW-UP M2 (gatilho: o veneno congelado voltar a incomodar): poc(47)/gustavo(48) tem chaves estrangeiras JA rastreadas no onion/ |

## elenxos-2026-08-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 20.0 | `Q_SDAAL_NAO_TEM_CONSUMIDOR_SEM_LLM` | elenxos-2026-08-07 | ABERTO, e a F4 so tapou o primeiro caso: o SDAAL e Markdown lido por LLM ('documentacao substitui codigo executavel'). Um step de  |
| 8.0 | `E_LINT_NAO_ENXERGA_WORKFLOWS` | elenxos-2026-08-07 | POR QUE NINGUEM VIU: as REGRAS 10 e 11 (anti-provider-direto e forge-method-existe) varrem APENAS `.claude/commands` e `.claude/ag |
| 8.0 | `Q_SDAAL_EXECUTAVEL_ONDE_PARA` | elenxos-2026-08-07 | ABERTO: a F4 abriu a primeira peca EXECUTAVEL dentro de `.claude/utils/forge/` — necessaria porque um step de Actions e shell pu |
| 5.4 | `E_ALLOWLIST_NO_KG_VIEW` | elenxos-2026-08-07 | SITIO 3 (NAO CURADO): kg-view.sh:101-107 carrega uma COPIA de statusFactor que nao conhece os status novos — retorna -1, clampad |

## fios-abertos — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 20.0 | `D_CENSO_190_EM_LOTES` | fios-abertos | SELADO PELO MAESTRO 2026-08-30 (supersede D_CENSO_VIRA_AMOSTRA_ESTRATIFICADA): executar o CENSO dos ~190 itens abertos do docs/bac |

## identidade-onion-vps-2026-08 — 5 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 12.0 | `Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` | identidade-onion-vps-2026-08 | ACHADO DE ADOTANTE, ainda NAO COMUNICADO — acao pendente do maestro, nao minha. Medido em `/home/marcio/onion-adopt-arandek/dock |
| 12.0 | `Q_LACUNA_DECISAO_MAIS_CODIGO` | identidade-onion-vps-2026-08 | A OPORTUNIDADE, e ela e de diferenciacao e nao de divida. A pesquisa nao achou NENHUM sistema publico que una grafo de DECISAO e g |
| 7.2 | `Q_BACKUP_MECANISMO_ARMADO_SEM_AGENDAMENTO` | identidade-onion-vps-2026-08 | SUPERSEDE [Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA] com a verdade de 2026-08-29: a lacuna de 08-13 FECHOU PELA METADE. O pass JA TEM oni |
| 6.0 | `Q_A_SENHA_DA_CHAVE_QUEBROU_A_AUTOMACAO` | identidade-onion-vps-2026-08 | O PRECO DE PROTEGER A CHAVE, e ele e real — decisao do maestro, nao minha. Por A chave GPG ganhou passphrase (era o segredo de m |
| 5.4 | `Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` | identidade-onion-vps-2026-08 | A guarda `vps-exposure-check.sh` cobre o lado de CA (bind publico em container vivo, conector upstream, backup em claro) e roda di |

## vps-shared-tools-2026-07 — 12 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 10.8 | `A_analysis_structure` | vps-shared-tools-2026-07 | ESTRUTURA DE ANALISE INICIAL (4 fases, antes do plano): F0 frame+invariantes+Elenxo catalogo-vs-plataforma · F1 pesquisa por-tool |
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

## gtm-decisions-2026-07 — 5 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 7.5 | `D_D2_activation` | gtm-decisions-2026-07 | D2-ATIVAÇÃO — ligar o flywheel de moeda-dado (SSOT 6 camadas L1-L6 de mitigação de inferência, dogfoodado). Direção RATIF |
| 6.0 | `Q_d6_message_vs_pipeline` | gtm-decisions-2026-07 | D6 mistura 'comprador da MENSAGEM' com 'comprador que fatura PRIMEIRO' — o maestro precisa decidir se D6 é POSICIONAMENTO (a qu |
| 5.0 | `Q_instrument_metrics` | gtm-decisions-2026-07 | Falta 'valor medido por adotante' (metrics.md `[a instrumentar]`) + taxa de conversão free→paid (sem benchmark p/ frameworks de |
| 4.4 | `Q_open_trigger` | gtm-decisions-2026-07 | Qual o GATILHO concreto de 'abrir publicamente' o standalone (métrica/data/nº de adotantes provados/aprovação do maestro)? É  |
| 4.4 | `Q_p4_no_field_proof` | gtm-decisions-2026-07 | Zero adotante P4 (regulado) provado hoje — escolher P4 como mensagem é aposta em whitespace de pesquisa, não ICP validado. Fal |

## arandek-adoption-dogfood-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 7.2 | `D_GREP_OLD_PIN` | arandek-adoption-dogfood-2026-07 | BACKLOG (nao implementado; priorizar e do maestro). No /meta:adopt --update, apos reescrever o .onion-version: `grep -rl <pin-anti |
| 7.2 | `Q_ARANDEK_UPDATE` | arandek-adoption-dogfood-2026-07 | quando o arandek rodar /meta:adopt --update, recebe os 6 fixes; o contorno do D1 dele (technical-context ponteiro) simplifica p/ d |
| 3.2 | `Q_RELAY` | arandek-adoption-dogfood-2026-07 | relay do sinal (docs/evolution/inbox do arandek → inbox do core via /meta:co-relay) pendente — território da sessão do adota |
| 2.0 | `Q_PIN_GREP_WORTH_IT` | arandek-adoption-dogfood-2026-07 | FRONTEIRA DECLARADA PELO PROPRIO ADOTANTE (R15.2 — registrada como observacao, nao como pedido): 'pode ser que o custo nao compe |

## context-freshness-2026-08-12 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 6.0 | `Q_ORCAMENTO_DE_CI_MEDIDO_CONTRA_ARTEFATO_41PCT_MENOR` | context-freshness-2026-08-12 | O `contributing.md` apresenta um ORCAMENTO DE CI como 'medido 2026-07-20': '~7,5min total, teto timeout-minutes: 15', com o lint e |

## cafe-aroma-demo — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.6 | `Q_excecao_enterprise` | cafe-aroma-demo | Cliente enterprise com contrato de 3 anos merece exceção ao teto? Dúvida ABERTA — sobe para a Ana como pergunta explícita, n |

## constellation-dialogic-layer-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.6 | `D_STORE_GATED` | constellation-dialogic-layer-2026-07 | guardar como pesquisa de core design-only/gated, NAO mesclar — julgamento conjunto (nao promovido) |
| 5.4 | `C_BOLETIM_INFORM` | constellation-dialogic-layer-2026-07 | 3o uso: o boletim core->estrela INFORMA a estrela do que virou main (simetrico ao carteiro star->core PUSH) — 3 travas: contexto |
| 4.0 | `D_ISOLATION_EXTENSION_GATED` | constellation-dialogic-layer-2026-07 | GATED: estender a linha so-metadados (hoje 'frontmatter+Tier-0') p/ incluir o .kg.yaml como superficie publica precisa ratificacao |
| 3.6 | `D_BOLETIM_CANDIDATE` | constellation-dialogic-layer-2026-07 | documentar o boletim como padrao CANDIDATO — emergiu 1x (Rule of Three nao cumprida); vira firme por recorrencia/uso, nao por es |

## elenxo-mecanismos-lint-2026-08-13 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.4 | `Q_MUDEZ_DA_GUARDA_NAO_SE_IDENTIFICA` | elenxo-mecanismos-lint-2026-08-13 | O TETO DA GUARDA DIRTY-TREE GANHA DONO NO GRAFO (8o Elenxo, fechamento do Q_PARECER): no caminho benigno a guarda NAO emite nada  |

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
| 4.8 | `Q_RADAR_WIDGET_PARALLEL_FORMULA` | onion-doctrine-elenxo-bulbo-2026-07 | o RadarWidget de /maquinaria/ (site) DUPLICA a tabela de statusFactor do kg-radar.sh (conferida fator a fator na revisao adversari |
| 1.6 | `Q_BULBO_DIAGRAM` | onion-doctrine-elenxo-bulbo-2026-07 | um visual do Bulbo (cebola cortada: as 4 camadas + o corte que revela tudo) e candidato quando graduar — vale o espaco? [ATUALIZ |

## colaboracao-onion-2026-07 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 4.5 | `E_RETRO` | colaboracao-onion-2026-07 | retro do parceiro (Gustavo) — instrumento criado; coleta em andamento |
| 4.0 | `Q_AUTORIZACAO_NAO_FORMALIZADA` | colaboracao-onion-2026-07 | perfil colaborador-visitante + boundary de autorizacao de relay ainda nao formalizados no core |
| 3.0 | `Q_RETRO_PENDENTE` | colaboracao-onion-2026-07 | o que a retro do Gustavo vai confirmar/refutar sobre o processo? |

## guardrails-2nd-pr-state-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 4.0 | `Q_REVERSE_JOIN_SCOPE` | guardrails-2nd-pr-state-2026-07 | GATED/deferido: o join-reverso (arquivo->guardrails que governam) so vira ferramenta barata SE as guardas passarem a self-declarar |

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
| 2.4 | `Q_automacao_pipeline` | kg-diagnose-design-2026-07 | Follow-up GATED: um orquestrador que encadeia extract→consolidate→diagnose automaticamente? Decisão do maestro: NÃO agora  |

## residuos-2026-08-18 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_ALARME_DE_AUSENCIA_DE_AGENDADO` | residuos-2026-08-18 | GATED por Teste do Gatilho — alarme para agendado que PARA de rodar. GATILHO NOMEADO: a 1a vez que um run com event=schedule for |

## vendor-multi-branch-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_volume_not_reproduced` | vendor-multi-branch-2026-07 | Reproduzimos a CLASSE (conflito contabil em codigo de aplicacao por vendor branch-especifico), NAO os 110 arquivos. O volume depen |
| 2.0 | `Q_three_or_more_branches` | vendor-multi-branch-2026-07 | Tres ou mais integration branches nao foram exercitadas. A convencao por-branch se estende por CONSTRUCAO, mas isso e inferencia,  |

