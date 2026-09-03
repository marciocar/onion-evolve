# Backlog vivo — projeção dos grafos ⚙️ GERADO

> Gerado por `.claude/validation/kg-backlog-project.sh` a partir dos nós `status: open` da
> camada canônica (`docs/onion/graph/`, exceto arquivos opt-OUT) + grafos marcados. **Não editar à mão**: feche o
> item no grafo (status ≠ open, com carimbo) e ele sai daqui. Ordem = atenção (a régua do
> radar: impact × incerteza × status). Sem corte NO ESCOPO; 2 grafo(s) de arquivo (opt-OUT) ficam fora — visíveis via `kg-radar --open-tsv`.

**91 itens abertos** em 30 grafo(s) com aberto (de 52 no escopo) · 30 grupo(s). **Nenhum nó declara `owner:`** — o agrupamento é por GRAFO (o fallback). A fila de decisão/execução do core; o topo por atenção é o que "custa caro estar errado".

## m3-federation-admin-2026-07 — 12 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 68.0 | `D_spec_now_build_gated` | m3-federation-admin-2026-07 | SPEC-agora / BUILD-gated — especificar o command-side (mutação de members.yaml) + modelo de auth (Logto Organizations) SEM con |
| 15.6 | `C_auth_logto_sdaal` | m3-federation-admin-2026-07 | AUTH = fronteira gated (o BUILD não se pré-cozinha, gated-work-derives-fresh). Comprometido: só a fronteira §4.3 + a invariân |
| 11.2 | `C_op_update` | m3-federation-admin-2026-07 | OP-3 ATUALIZAR (pin/trust/specializations/personality_summary): escrever onion_version novo (pós pin-integrity-check) e editar a  |
| 8.4 | `C_op_promote` | m3-federation-admin-2026-07 | OP-2 PROMOVER (role: standalone→hub / consumer→T2): atualizar o campo role: no members.yaml do core. Hoje --promote-hub só re |
| 7.0 | `Q_gatilho` | m3-federation-admin-2026-07 | GATILHO objetivo do build: o 1º membro role:consumer (T2) REAL em members.yaml (introduz hub-owner que precisa de visão/ação e |
| 5.8 | `C_op_revoke` | m3-federation-admin-2026-07 | OP-4 REVOGAR/DESATIVAR (status: retired / remover linhagem obsoleta): nenhum script/comando existe; o padrão observado é anotar  |
| 5.4 | `C_p3_agg_view` | m3-federation-admin-2026-07 | REQ P3 (SHOULD condicional): visão agregada de adoção/consistência entre N repos/times DA MESMA empresa (multi-tenant no senti |
| 5.4 | `C_p4_gate_visibility` | m3-federation-admin-2026-07 | REQ P4 (SHOULD): relatório/export do histórico de decisões (decisions.md-like) por projeto/tenant — P4 valoriza 'evidência e |
| 5.2 | `C_p3_self_service` | m3-federation-admin-2026-07 | REQ P3 (SHOULD condicional): self-service de onboarding multi-squad (mata a dor 'cada dev usa IA de um jeito; nenhuma trilha'). O  |
| 5.2 | `C_p4_audit_trail` | m3-federation-admin-2026-07 | REQ P4 (SHOULD condicional): trilha de auditoria legível/exportável das sessões e fases executadas (quem/quando/o quê) derivad |
| 4.8 | `Q_onprem_tension` | m3-federation-admin-2026-07 | TENSÃO M3 não-resolvida: comprador P4 regulado costuma exigir multi-ambiente/on-prem/auditoria de 3º × identidade Claude Code- |
| 2.0 | `Q_wake_session` | m3-federation-admin-2026-07 | GAP de design/dogfood aberto (não pesquisa): evoluir o receiver git-async para 'acordar a sessão' via SSE/webhook sem quebrar pu |

## poda-instruction-bloat-2026-09 — 6 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 41.6 | `Q_PODA_INSTRUCTION_BLOAT_CORE` | poda-instruction-bloat-2026-09 | O que podar do CLAUDE.md (246 linhas / 17.041 bytes) e das skills do core do Onion para curar o agent instruction bloat (Thoughtwo |
| 28.0 | `D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS` | poda-instruction-bloat-2026-09 | DECISAO ABERTA (o maestro sela): o que podar do CLAUDE.md e das skills do core, entre (A) mover doutrina para skills/rules por pat |
| 21.0 | `C_OPCAO_C_MEDIR_PRIMEIRO_COM_INSTRUCTIONSLOADED` | poda-instruction-bloat-2026-09 | OPCAO C — medir primeiro com InstructionsLoaded e podar so o que nunca carrega / nunca muda comportamento. A favor: e a unica op |
| 12.0 | `C_OPCAO_A_DOUTRINA_EM_SKILLS_E_RULES_POR_PATH` | poda-instruction-bloat-2026-09 | OPCAO A — mover doutrina para skills/rules por path e deixar o CLAUDE.md so com identidade + roteamento. A favor: e a cura que o |
| 2.8 | `C_OPCAO_D_NAO_PODAR` | poda-instruction-bloat-2026-09 | OPCAO D — nao podar. A favor, e mais forte do que a rodada admitiu: 17.041 bytes sao ~0,5% da janela de 1M, o custo de janela e  |
| 2.4 | `C_OPCAO_B_MANTER_CLAUDE_MD_E_COMPRIMIR` | poda-instruction-bloat-2026-09 | OPCAO B — manter o CLAUDE.md e comprimir. A favor: custo zero de arquitetura, nada se move de lugar, nenhum risco de doutrina su |

## d5-pricing-2026-07 — 6 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 35.8 | `D_D5` | d5-pricing-2026-07 | D5 — preço por camada (escada treino→certificação→compliance-pack→SOTA). Blend A+B: degraus 1-2 vendíveis-já (compar |
| 19.2 | `C_compliance_pack` | d5-pricing-2026-07 | DEGRAU 3 Compliance-pack (cunha P4): faixa $15k-40k/ano CITÁVEL não-fechado. Terço inferior do mercado compliance-automation (a |
| 10.8 | `C_sota_subscription` | d5-pricing-2026-07 | DEGRAU 4 Assinatura SOTA: $150-400/mês indiv. · $250-600 base + $60-120/seat empresa. Acima das ferramentas de codificação gen |
| 7.5 | `Q_d2_l1l6_activation` | d5-pricing-2026-07 | GATE D2: a assinatura SOTA vende o mecanismo L1-L6 (classificação-por-inferência + gate-por-propósito + ε-ledger) que segue G |
| 6.6 | `Q_p4_interviews` | d5-pricing-2026-07 | Zero comprador P4 (regulado) entrevistado — o compliance-pack $15-40k é willingness-to-pay não-validado. D6 registra 1-2 entre |
| 4.9 | `Q_train_cert_chaining` | d5-pricing-2026-07 | Encadeamento treino→certificação a validar: a cert pressupõe treino prévio (D4 sequencial) ou é standalone? + espaçamento  |

## onion-identity-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 29.2 | `C_NS1_KG` | onion-identity-2026-07 | NS1: framework que constroi conhecimento reconciliavel vivo (KG); edge mais forte, negocio nao provado |
| 10.8 | `Q_CUSTO_DO_PORTE_NUNCA_MEDIDO` | onion-identity-2026-07 | A LACUNA QUE O REPO CONFESSA E NAO RASTREIA (nomeada 2026-08-06 para PARAR DE SER REDESCOBERTA). O CLAUDE.md linhas 2-9 declara qu |
| 7.5 | `Q_COLD_ADOPTER` | onion-identity-2026-07 | existe QUALQUER pull dos diferenciais raros FORA da orbita de Marcio (1 adotante frio) |
| 7.2 | `Q_FEDERACAO_VISIBILITY_GATE` | onion-identity-2026-07 | site/federacao/ e snapshot congelado (2026-07-10) por DECLARACAO, nao por mecanismo (achados R3+NOVO-4 da revisao do PR #671): nad |

## meta-research-lens-2026-09 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 25.5 | `Q_DIRETRIZ_DE_PESQUISA_VIRA_MAQUINARIA` | meta-research-lens-2026-09 | Como a diretriz de pesquisa que o maestro re-digita a cada pesquisa/decisao (lente Onion, fontes atuais, Claude Code na versao atu |
| 14.0 | `D_PODA_INSTRUCTION_BLOAT_MEDIDA` | meta-research-lens-2026-09 | DECISAO PROPOSTA (fio proprio, GATED): medir o que do CLAUDE.md/skills/rules carrega SEMPRE vs sob demanda (InstructionsLoaded hoo |
| 9.0 | `D_F4_REVISITA_REGRA65_E_MODO_REVISIT` | meta-research-lens-2026-09 | F4 (1 PR, revisita): REGRA 65 passa a varrer review_after dos grafos de pesquisa e das fontes do roster (SOFT); /onion-research -- |
| 6.3 | `D_BUSCA_COMO_SDAAL_GATED` | meta-research-lens-2026-09 | DECISAO PROPOSTA (GATED): adapter de busca em .claude/utils/search/ (irmao do task-manager: WebSearch nativo default; MCP Exa/Tavi |

## elenxos-2026-08-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 24.0 | `Q_SDAAL_NAO_TEM_CONSUMIDOR_SEM_LLM` | elenxos-2026-08-07 | ABERTO, e a F4 so tapou o primeiro caso: o SDAAL e Markdown lido por LLM ('documentacao substitui codigo executavel'). Um step de  |
| 8.0 | `Q_SDAAL_EXECUTAVEL_ONDE_PARA` | elenxos-2026-08-07 | ABERTO: a F4 abriu a primeira peca EXECUTAVEL dentro de `.claude/utils/forge/` — necessaria porque um step de Actions e shell pu |

## m2-bridge-logto-2026-07 — 8 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 22.4 | `D_logto_same_protection_tier` | m2-bridge-logto-2026-07 | FIX D+A fecho — elevar Logto+Postgres ao MESMO patamar, agora em 3 CAMADAS (a v2 tinha 2 e a de baixo era decorativa): (1) /etc/ |
| 18.0 | `D_middleware_order_first` | m2-bridge-logto-2026-07 | FIX C fecho — EXIGÊNCIA no P5: app.use('*', requireIdentity) é o PRIMEIRO handler registrado, antes de TODA rota, de TODO app. |
| 14.2 | `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA` | m2-bridge-logto-2026-07 | PRE-EXISTENTE, mas o P11 ELEVOU O RAIO — e essa mudanca de risco precisa morar aqui: antes, numa queda do Logto, o caminho legad |
| 10.8 | `C_docker_floor_gap` | m2-bridge-logto-2026-07 | GAP (impacto ELEVADO na v2+, porque o Logto virou caminho crítico): Logto+Postgres (docker) só têm teto duro. MEDIDO no cgroup: |
| 10.2 | `D_logto_not_ssot` | m2-bridge-logto-2026-07 | INVARIANTE herdada do M3: Logto = emissor/validador de identidade (commodity-BUY), NUNCA SSOT de autorização fina. A autorizaç |
| 6.0 | `Q_route_inventory` | m2-bridge-logto-2026-07 | VPS-DECLARADO: o inventário EXATO das rotas do app Hono só existe no host. A tabela do §3.4 é CONTRATO, não fato. P0.2 enumer |
| 5.1 | `Q_docker_cgroup_driver` | m2-bridge-logto-2026-07 | FIX L2 — PROVA NOVA no P0.6: a semântica de cgroup_parent DEPENDE do cgroup driver do docker. MEDIDO hoje: driver = systemd (h |
| 4.8 | `Q_signup_close_not_via_api` | m2-bridge-logto-2026-07 | DIVIDA NOMEADA: o fechamento do registro do tenant `admin` (sign_up identifiers -> []) foi feito por SQL direto, nao pela API nem  |

## guardas-revisao-2026-08 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 21.6 | `Q_GUARDAS_COERENTES` | guardas-revisao-2026-08 | as guardas nascidas reativamente formam um sistema coerente, sem sobreposicao cega nem lacuna? |
| 8.1 | `Q_INDICE_DO_DIARIO_SEM_CATRACA` | guardas-revisao-2026-08 | LACUNA DE COBERTURA medida em 2026-08-28: `.claude/diary/index.md` e projecao GERADA e nao tem catraca de em-sync, ao contrario do |
| 8.0 | `Q_TRES_GRAFOS_NAO_SAO_YAML_VALIDO` | guardas-revisao-2026-08 | DECLARADO != VERIFICADO NO PROPRIO FORMATO DA SSOT. O formato se chama `.kg.yaml` e 4 de 75 arquivos NAO passavam num parser YAML  |
| 5.4 | `C_SEM_GATE_REGRA_SEM_TESTE` | guardas-revisao-2026-08 | nao existe gate regra-sem-fixture; o STRICT do CI reprova skip por tooling ausente, o que e outra coisa — candidato a 6a catraca |

## fable-5-1-superacao-2026-09 — 9 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 19.6 | `Q_EXP_JUIZ_FABLE_CALIBRACAO` | fable-5-1-superacao-2026-09 | EXPERIMENTO: juiz do kg-freshness/censo opus/high → fable/high SO na faixa CONFIRMED. Metrica: re-rodar a calibracao contra o ME |
| 6.4 | `C_LEITURA_KG_UNICA_PERNA_MODELO_DEPENDENTE` | fable-5-1-superacao-2026-09 | HIPOTESE (nao selada; EMENDA DO JUIZ: 1M de contexto NAO e novidade do 5.1 — Opus 5 e Fable 5 ja eram 1M, agent-orchestration.md |
| 5.6 | `D_TIERING_SSOT_UNICA_E_EFFORT` | fable-5-1-superacao-2026-09 | DECISAO PROPOSTA (2 partes, sem experimento de modelo): (a) a tabela de tiering replicada em ~8 docs vira UMA fonte (agent-orchest |
| 5.4 | `D_RETIER_COMPLIANCE_E_GATES_PREPR` | fable-5-1-superacao-2026-09 | DECISAO PROPOSTA (barata, mas NAO selada — depende de leitura dos corpos, lacuna 3 do inventario): alinhar o model: dos agentes  |
| 5.4 | `Q_EXP_WORKER_FABLE_NOS_COMPOSTOS` | fable-5-1-superacao-2026-09 | EXPERIMENTO: worker sonnet → fable APENAS em nos COMPOSTOS (os que deram 44-48% de subcontagem de denominador). Metrica unica: c |
| 4.8 | `Q_EXP_AUTO_REVISAO_5_1` | fable-5-1-superacao-2026-09 | EXPERIMENTO (base empirica da REGRA 56): a taxa de auto-revisao medida em 2026-08-02 foi ZERO (15 auto-correcoes, 8 por gatilho so |
| 4.5 | `Q_READONLY_CLAUSE_E_DEFEITO_DE_ESPEC` | fable-5-1-superacao-2026-09 | NAO E CASO DE MODELO: a clausula READ-ONLY do kg-freshness confunde POST com MUTACAO (pedir token por client_credentials e leitura |
| 4.0 | `Q_EXP_LEITURA_KG_1M` | fable-5-1-superacao-2026-09 | EXPERIMENTO (pre-condicao: definir a metrica, que hoje NAO existe): numa sessao 5.1, contar quantas decisoes da sessao citam no do |
| 3.3 | `Q_EXP_ELENXO_3_VS_6_LENTES` | fable-5-1-superacao-2026-09 | EXPERIMENTO: refutador Elenxo opus/high → fable permite 3 lentes independentes em vez de 4-6 sem perder cobertura adversarial? M |

## websearch-cap-2026-09 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 19.2 | `Q_WEBSEARCH_CAP_2_1_258` | websearch-cap-2026-09 | Qual e o teto de chamadas WebSearch por sessao no Claude Code 2.1.258 — a env var CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION, seu  |

## identidade-onion-vps-2026-08 — 5 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 14.2 | `E_SEGUNDO_ADOTANTE_MESMA_CLASSE_DE_EXPOSICAO` | identidade-onion-vps-2026-08 | O GATILHO DO Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO DISPAROU — um caso e caso, DOIS E CLASSE. O censo mediu um SEGUNDO adotan |
| 12.0 | `Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` | identidade-onion-vps-2026-08 | ACHADO DE ADOTANTE, ainda NAO COMUNICADO — acao pendente do maestro, nao minha. Medido em `/home/marcio/onion-adopt-arandek/dock |
| 6.4 | `Q_REFUTES_EDGE_SEM_PAR` | identidade-onion-vps-2026-08 | A lacuna REAL que restou do Q_LACUNA refutado: a aresta REFUTES tipada (refutacao como cidada de 1a classe do grafo, com reconcili |
| 5.4 | `Q_SENHA_CHAVE_ESTADO_2026_09` | identidade-onion-vps-2026-08 | ESTADO ATUAL da chave GPG com passphrase (substitui o no de 08-12 que misturava >=9 afirmacoes): a protecao FICA (decisao do maest |
| 4.8 | `Q_MAIS_UM_IMUTAVEL_GATED` | identidade-onion-vps-2026-08 | O +1 da regra 3-2-1-1-0 (imutabilidade DO LADO DO SERVIDOR) segue pendente por escolha declarada: o R2 resolve o OFF-SITE (perda d |

## audit-textual-gates-2026-09 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.4 | `D_MOAT_DEPLOY_E_RELOGIO_VIRAM_MECANISMO` | audit-textual-gates-2026-09 | DECISAO PROPOSTA: dos 4 itens do MOAT do /meta:drive (merge · deploy · repo alheio · relogio), o merge ganhou veto neste PR; de |
| 4.8 | `Q_REGRA56_VERACIDADE_DOS_ACHADOS` | audit-textual-gates-2026-09 | Quanto os campos findings_total/findings_real/verdict do residuo R56 correspondem a achados REAIS quando o revisor e a propria ses |
| 3.6 | `Q_PRECOMMIT_ARMADO_EM_CLONE_FRESCO` | audit-textual-gates-2026-09 | O pre-commit do core depende de `git config core.hooksPath .githooks` LOCAL — um clone fresco (maquina nova, worktree de adotant |
| 3.6 | `Q_R15_WRAP_NO_CAMINHO_CRITICO` | audit-textual-gates-2026-09 | onion-untrusted-wrap.sh (R15, anti-prompt-injection) nao e chamado por hook nenhum; a defesa depende de o modelo seguir untrusted- |

## company-brain-market-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.2 | `Q_ntenant_proof` | company-brain-market-2026-07 | Gap mais crítico p/ 'Company' (vs pessoal): a prova N=1 pessoal NÃO generaliza p/ multi-tenant (múltiplos leitores do mesmo gra |

## librechat-kg-runtime-2026-08 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 8.1 | `Q_TENANT_WRITE_DESTINATION` | librechat-kg-runtime-2026-08 | BURACO revelado pela selagem: a escrita de um chat no PAPEL-DE-NEGOCIO (tenant) precisa de destino FORA do core (fila do tenant/ad |
| 7.7 | `Q_MAP_LEG_GATED` | librechat-kg-runtime-2026-08 | BURACO exposto pelo protocolo: a perna MAP (ingestao doc->grafo) nao tem tool no core — existe so na PoC (ingerir_documento_cola |

## onion-doctrine-elenxo-bulbo-2026-07 — 3 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 7.7 | `D_QUADRO_CITACOES` | onion-doctrine-elenxo-bulbo-2026-07 | quadro de citacoes do maestro NASCEU (gated): as formulacoes recorrentes dele, atribuidas+datadas (verbatim vs parafrase marcado)  |
| 4.8 | `Q_RADAR_WIDGET_PARALLEL_FORMULA` | onion-doctrine-elenxo-bulbo-2026-07 | o RadarWidget de /maquinaria/ (site) DUPLICA a tabela de statusFactor do kg-radar.sh (conferida fator a fator na revisao adversari |
| 1.6 | `Q_BULBO_DIAGRAM` | onion-doctrine-elenxo-bulbo-2026-07 | um visual do Bulbo (cebola cortada: as 4 camadas + o corte que revela tudo) e candidato quando graduar — vale o espaco? [ATUALIZ |

## gtm-decisions-2026-07 — 4 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 7.5 | `D_D2_activation` | gtm-decisions-2026-07 | D2-ATIVAÇÃO — ligar o flywheel de moeda-dado (SSOT 6 camadas L1-L6 de mitigação de inferência, dogfoodado). Direção RATIF |
| 7.5 | `Q_instrument_metrics` | gtm-decisions-2026-07 | Falta 'valor medido por adotante' (metrics.md `[a instrumentar]`) + taxa de conversão free→paid (sem benchmark p/ frameworks de |
| 4.4 | `Q_open_trigger` | gtm-decisions-2026-07 | Qual o GATILHO concreto de 'abrir publicamente' o standalone (métrica/data/nº de adotantes provados/aprovação do maestro)? É  |
| 4.4 | `Q_p4_no_field_proof` | gtm-decisions-2026-07 | Zero adotante P4 (regulado) provado hoje — escolher P4 como mensagem é aposta em whitespace de pesquisa, não ICP validado. Fal |

## fios-abertos — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 6.8 | `Q_SELFTEST_VENDORIZADO_INSATISFAZIVEL_NO_ADOTANTE` | fios-abertos | A bancada vendorizada (lint-selftest.sh) NAO PODE passar no adotante: medido em 2026-09-02 no 1o adotante greenfield do pin 8e2517 |

## federation-health-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 6.0 | `C_GRANAAI_LINEAGES_UNKNOWN` | federation-health-2026-07 | granaai linhagens mauricio (pin nao-verificavel-deste-host) e leonardo-offline (pin desconhecido) — estado de verificacao INDETE |

## graduated-automation-elenxo-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 6.0 | `Q_COUNTABLE_CRITERIA` | graduated-automation-elenxo-2026-07 | Onda 3: criterios de promocao CONTAVEIS (N execucoes monitoradas sem anomalia => destrava) + rollback provado como pre-condicao de |
| 6.0 | `Q_PREDICTIVE_ALERTS` | graduated-automation-elenxo-2026-07 | Onda 4: alertas PREDITIVOS — territorio novo (o core e reativo/CI-safe por design). anteceder a falha da automacao antes de ela  |

## cafe-aroma-demo — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.6 | `Q_excecao_enterprise` | cafe-aroma-demo | Cliente enterprise com contrato de 3 anos merece exceção ao teto? Dúvida ABERTA — sobe para a Ana como pergunta explícita, n |

## constellation-dialogic-layer-2026-07 — 2 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.4 | `C_BOLETIM_INFORM` | constellation-dialogic-layer-2026-07 | 3o uso: o boletim core->estrela INFORMA a estrela do que virou main (simetrico ao carteiro star->core PUSH) — 3 travas: contexto |
| 4.0 | `D_ISOLATION_EXTENSION_GATED` | constellation-dialogic-layer-2026-07 | GATED: estender a linha so-metadados (hoje 'frontmatter+Tier-0') p/ incluir o .kg.yaml como superficie publica precisa ratificacao |

## elenxo-mecanismos-lint-2026-08-13 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 5.4 | `Q_MUDEZ_DA_GUARDA_NAO_SE_IDENTIFICA` | elenxo-mecanismos-lint-2026-08-13 | O TETO DA GUARDA DIRTY-TREE GANHA DONO NO GRAFO (8o Elenxo, fechamento do Q_PARECER): no caminho benigno a guarda NAO emite nada  |

## granaai-doctrine-absorption-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 4.8 | `C_S4` | granaai-doctrine-absorption-2026-07 | FEATURE: /meta:kg map projeto (canonicalizacao de monorepo) — hoje map area existe, projeto/monorepo aberto |

## vps-shared-tools-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 4.2 | `C_dissent_auth_transversal` | vps-shared-tools-2026-07 | DISSENT (sobrevivente, vigiar): auth NAO e adapter-par — e alicerce TRANSVERSAL que whatsapp/email/monitoramento assumem como da |

## guardrails-2nd-pr-state-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 4.0 | `Q_REVERSE_JOIN_SCOPE` | guardrails-2nd-pr-state-2026-07 | GATED/deferido: o join-reverso (arquivo->guardrails que governam) so vira ferramenta barata SE as guardas passarem a self-declarar |

## catraca-regra49-2026-08 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `D_SCRUB_FROZEN_POISON_IN_VENDORS` | catraca-regra49-2026-08 | FOLLOW-UP M2 (gatilho: o veneno congelado voltar a incomodar): poc(47)/gustavo(48) tem chaves estrangeiras JA rastreadas no onion/ |

## kg-diagnose-automation-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_orquestrador_gated` | kg-diagnose-automation-2026-07 | Follow-up GATED (2º passo): um comando que ROLA a sequência extract→consolidate→candidatos disparando agentes sozinho? Merec |

## residuos-2026-08-18 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.4 | `Q_ALARME_DE_AUSENCIA_DE_AGENDADO` | residuos-2026-08-18 | GATED por Teste do Gatilho — alarme para agendado que PARA de rodar. GATILHO NOMEADO: a 1a vez que um run com event=schedule for |

## kg-console-rich-design-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.0 | `Q_live_narration` | kg-console-rich-design-2026-07 | Narração LIVE opcional (POST a um LLM 'explique esta seleção') como enhancement que degrada gracioso offline — gated; a pré |

## vendor-multi-branch-2026-07 — 1 item(ns)

| Atenção | Nó | Grafo | O que é |
|--:|---|---|---|
| 2.0 | `Q_three_or_more_branches` | vendor-multi-branch-2026-07 | Tres ou mais integration branches nao foram exercitadas. A convencao por-branch se estende por CONSTRUCAO, mas isso e inferencia,  |

