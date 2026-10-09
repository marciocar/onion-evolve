<!-- GERADO por .claude/validation/kg-view.sh — NÃO EDITE À MÃO. -->
<!-- Fonte: docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml · regenere: bash .claude/validation/kg-view.sh docs/onion/graph/federation-research-2026-06-reconciled.kg.yaml --markdown -->

# Lente do grafo — `federation-research-2026-06-reconciled`

**882 nós · 1087 arestas · 0 órfãos**

> Projeção DERIVADA. O veredito (integridade, reconciliação, frescor) é do
> `kg-radar.sh` — esta lente não julga, só mostra.

## Composição

| Tipo | n |
|---|---|
| claim | 413 |
| decision | 174 |
| evidence | 126 |
| question | 107 |
| entity | 34 |
| artifact | 28 |

| Status | n |
|---|---|
| confirmed | 412 |
| open | 319 |
| superseded | 61 |
| refuted | 52 |
| done | 38 |

| Plano | n |
|---|---|
| DEV | 707 |
| PROD | 175 |

## Radar — 25 focos de atenção (peso × centralidade)

| # | atenção | nó | tipo | plano/status | grau |
|---|---|---|---|---|---|
| 1 | 42.8 | `REC_A2A_RECEIVER_GATE_BUILT` | evidence | PROD/confirmed | 8 |
| 2 | 40.5 | `B6_15_onion_identity` | entity | DEV/confirmed | 8 |
| 3 | 37.5 | `G1_GATED_HANDSHAKE_DESIGN` | decision | DEV/open | 9 |
| 4 | 36.0 | `B2_4_pivot_hub_to_peer` | decision | DEV/confirmed | 7 |
| 5 | 33.0 | `S1_DECISION_FEDERATION_TRANSPORT_ADAPTERS` | decision | DEV/open | 10 |
| 6 | 32.0 | `G3_DECISION_SINGLE_SOURCE_IDENTITY_MESH_COMMS` | decision | DEV/open | 7 |
| 7 | 31.5 | `B6_4_veredito_base_solida` | claim | DEV/confirmed | 6 |
| 8 | 28.5 | `REC2_NO_CONTRACT_EVER_REGISTERED` | evidence | PROD/confirmed | 5 |
| 9 | 27.2 | `B6_6_correction_backlog` | artifact | DEV/open | 7 |
| 10 | 27.0 | `B6_3_decision_reposicionamento_produto` | decision | DEV/confirmed | 5 |
| 11 | 27.0 | `B5_4_finding1_copy_manual_commit` | claim | DEV/confirmed | 5 |
| 12 | 25.5 | `GAPS_DECISION_A2A_LIVE_SIGNALS_ONLY` | decision | DEV/open | 5 |
| 13 | 25.5 | `G2_DECISAO_MANTER_GATED` | decision | DEV/open | 5 |
| 14 | 25.5 | `B2_4_ledger_git_spine` | decision | DEV/confirmed | 5 |
| 15 | 25.2 | `SY5_rfc0002_judged_trio` | claim | PROD/open | 11 |
| 16 | 25.2 | `SY4_prod_rfc0005_ratificada` | evidence | PROD/confirmed | 11 |
| 17 | 24.3 | `S3_decision_catalog_hegel_system` | decision | DEV/open | 8 |
| 18 | 22.5 | `REC_SIGNALS_ONLY_RATIFIED` | evidence | PROD/confirmed | 4 |
| 19 | 22.5 | `B6_3_claim_sdaal_sem_ci_drift` | claim | DEV/open | 5 |
| 20 | 22.5 | `B6_1_veredicto_pre_aplicavel` | claim | PROD/confirmed | 4 |
| 21 | 22.5 | `B6_10_decisao_descentralizado` | decision | DEV/confirmed | 5 |
| 22 | 22.5 | `B5_3_alert_b_mcp_leak` | claim | DEV/confirmed | 4 |
| 23 | 22.5 | `B5_2_mcp_first_leakage` | claim | DEV/confirmed | 4 |
| 24 | 22.5 | `B5_15_ingestor_gap` | claim | DEV/open | 4 |
| 25 | 22.5 | `B4_8_veredito_validado` | claim | PROD/confirmed | 4 |

### O que esses focos dizem

- **`REC_A2A_RECEIVER_GATE_BUILT`** *(evidence, confirmed)* — CONFIRMOU-SE: a verificação-antes-de-agir do receptor existe e é executável — a2a-verify.sh (6 camadas, fail-safe, apply_mode propose-only p/ receptor regulado), a2a-ssrf-check.sh, JWKS com pubkeys PINADAS por kid (metagamify-1, granaai-1), a2a-accept.sh fila→inbox
- **`B6_15_onion_identity`** *(entity, confirmed)* — Onion é framework template em .claude/, tri-dimensional peer (produto, engenharia, compliance), instalável sem alterar o projeto-alvo
- **`G1_GATED_HANDSHAKE_DESIGN`** *(decision, open)* — Veredito de desenho: o handshake a2a-live gated mapeia input-required/auth-required ao gate do maestro e roda o pin-integrity-check na fronteira transport→task do receptor — não inventa gate novo
- **`B2_4_pivot_hub_to_peer`** *(decision, confirmed)* — Pivô decidido: abandonar topologia hub (orquestrador único sobre N dirs) por topologia peer — cada repo com Onion soberano, comunicação assíncrona via ledger git compartilhado, humano como maestro
- **`S1_DECISION_FEDERATION_TRANSPORT_ADAPTERS`** *(decision, open)* — Propõe federation-transport SDAAL com adapters git-async (default) | local (carteiro-local) | a2a-live (gated, SSE+webhook sobre claude-agent-sdk), seguindo o molde de task-manager/factory.md e forge/factory.md, com fallback gracioso e aceitação gated no lado receptor
- **`G3_DECISION_SINGLE_SOURCE_IDENTITY_MESH_COMMS`** *(decision, open)* — Decisão proposta (insumo ao maestro, não doutrina ainda): single-source para identidade/contratos (consistência forte, escritor único) + mesh-de-comunicação git-async para colaboração (replicação otimista) — corte por natureza do dado, agora com fonte primária dos dois lados
- **`B6_4_veredito_base_solida`** *(claim, confirmed)* — Veredito: base sólida e fiel ao norte Transformers+SDAAL, confirmado por 3 auditorias convergentes + verificação adversarial
- **`REC2_NO_CONTRACT_EVER_REGISTERED`** *(evidence, confirmed)* — REFUTA a leitura de que a Federação formal está 'entregue e viva': em >5 semanas nenhum contrato real foi registrado — o ledger não tem sequer o diretório contracts/, os únicos contratos no repo são fixtures de validação, e não há registro de nenhum federation-check/rollback exercido. Os 5 comandos e os 3 scripts existem e passam nos fixtures; a capacidade nunca encontrou um caso real
- **`B6_6_correction_backlog`** *(artifact, open)* — Backlog de 10 itens de correção derivados do baseline (settings.json, .mcp.json, allowed-tools, frontmatter, symlinks, refatoração de 3 agentes+12 comandos, relocação de 2 templates) — entrada para Fases 1-2
- **`B6_3_decision_reposicionamento_produto`** *(decision, confirmed)* — Onion reposicionado como produto distribuível — não apenas consultoria de implantação

## Perguntas em aberto (o que ainda cobra resposta)

1. **`S9_q_radar_mechanism`** (atenção 18.0) — Como desenhar o canal-radar de vigilância contínua sobre sinais externos de pesquisa (fora do próprio Onion)?
2. **`S8_QuestionLensMeaning`** (atenção 18.0) — O que "lente" significa nesta semente: abstração de acesso (a) ou camada de tradução/interpretação (b)?
3. **`B6_13_decision_where_onion_lives`** (atenção 18.0) — Decisão 1: onde o Onion vive em definitivo — merge no mainline, branch separada, ou reintegração via branch de integração
4. **`B5_7_action_requested`** (atenção 18.0) — Ação pedida à sala de obra: reconciliar o material com o estado real de .claude/, rejeitar com evidência o que estiver errado, e decidir se a doutrina vira ADR aceito
5. **`B5_8_open_onion_core_base`** (atenção 15.0) — #3 onion-core: base plugin pendente para root commands (onion/warm-up/catch-up) + as 4 skills transversais — resolveria o gap do /catch-up
6. **`B6_13_decision_integration_branch_name`** (atenção 14.4) — Decisão 2: reconciliar a branch de integração existente ou adotar nome limpo
7. **`SY4_open_dogfood_regulated_member_escopo`** (atenção 12.6) — SEGUE ABERTO: o encaixe o membro regulado que os 4 streams desenharam em tabela ainda é PROPOSTA — o resolver existe, o dogfood de campo (empresa+time+pessoa no monorepo nx) está listado como próximo passo, não como feito
8. **`S2_question_federation_vs_orchestration`** (atenção 12.5) — Q2 — 'federação de SLMs' é sobre trocar quem orquestra, ou é variação da federação de instâncias soberanas (repos-humanos) já existente no Onion, aplicada a modelos?
9. **`B4_11_question_cold_adopter`** (atenção 12.5) — Q_COLD_ADOPTER: existe qualquer pull dos diferenciais raros do Onion fora da órbita de Marcio? — o desempate de maior alavancagem da estratégia
10. **`B5_5_precisao_match_question`** (atenção 11.2) — Sub-blind-spot remanescente: o catálogo só funciona se os gatilhos de 'reconhece-quando' forem precisos — match errado aplica o fluxo errado com confiança (mesmo modo de falha do contexto stale do ADR de ciclo de vida); a parte difícil é a precisão do reconhecimento, não a lista de fluxos
11. **`B5_11_g2_tier_kb_nao_circulante`** (atenção 11.2) — G2 aberto: KB com confidentiality INTERNO (case-studies de adotantes reais) shipou para o door — vendoring não distingue doutrina public-safe de análise interna
12. **`S13_question_repo_tier_meaning`** (atenção 10.0) — Q1: 'repos-padrão por tier' significa gerar repos novos (scaffolding automático) ou classificar/registrar formalmente os que já existem (família multi-plataforma)?
13. **`B2_3_next_steps_gate_keeper`** (atenção 9.6) — Próximo passo definido: aplicar SA-1/SA-2/SA-3 ao doc de design e validar a Fase 0 com o gate-keeper de meta-spec antes de criar qualquer arquivo
14. **`B5_5_prioridade_marcio_question`** (atenção 9.6) — Prioridade real entre catálogo de meta-estratégia e reposicionamento como produto (BSL/control plane/ICP regulado) — decisão que só o Marcio toma, sessão só sinaliza o conflito
15. **`S6_question_model_lifecycle`** (atenção 9.0) — Uma vez com um modelo pronto, como cuidar dele — monitorar, atualizar, saber quando degrada?
16. **`B5_10_camada_c_fronteira`** (atenção 9.0) — Comandos que dependem de doc L2 ausente (C1-C3: identity, build-tech-docs, task) degradam com aviso em vez de crashar?
17. **`SY4_open_pessoa_versionavel`** (atenção 8.4) — SEGUE ABERTO — o 4º nível: a camada pessoa resolve por ~/.claude (fora do git), então pessoa-dentro-do-time VERSIONÁVEL/COMPARTILHÁVEL continua sem mecanismo; a hipótese members/<pessoa> não foi materializada nem dogfoodada
18. **`SY4_open_agent_teams_capability_detection`** (atenção 8.4) — SEGUE ABERTO: a detecção de capacidade de Agent Teams prometida pela KB não existe na skill — o Passo 0 do onion-orchestration só faz health-check do Workflow; a KB declara um mecanismo que o executável não implementa (declarado≠verificado)
19. **`B6_7_proximo_passo_adr_ciclo_vida`** (atenção 8.4) — Próximo passo concreto: abrir o ADR de ciclo de vida do toolbox (reusando o modelo do ADR de ciclo de vida de contexto de domínio) selando a régua no SKILL.md + o passo inventory.sh como as 2 decisões baratas e de alto retorno; outliers entram em TRIAL em paralelo, tudo human-gated
20. **`B5_8_open_onion_meta_doctrine`** (atenção 8.4) — #4 onion-meta: empacotar os 30 comandos meta/ como plugin tensiona a doutrina de que meta é L2/L3 adopt-only — exige RFC

