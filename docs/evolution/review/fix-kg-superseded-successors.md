---
branch: fix/kg-superseded-successors
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 63
findings_real: 63
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 63
verdict: FIXED
elenxo: false
reviewer: agente de execução (passada própria, nó a nó; o brief proibiu lançar agentes, então não houve refutador independente)
nota: "tokens e duração não medidos (0 = não medido, não zero). A escolha de cada sucessor é do mesmo agente que gravou a aresta: falta o refutador independente, e isso fica declarado para a sessão principal decidir antes do merge."
---

# Resíduo: `fix/kg-superseded-successors`

## O que muda

O Delphi selado pelo maestro (`D_MIGRATION_TOUCHED_DELPHI_1112`, no kg-ssot) classificou como furo real o nó
`status: superseded` que nenhuma aresta `SUPERSEDES` alcança (aviso SHOULD `integrity.superseded-without-successor`
do contrato v4.19). O core tinha **63 em 21 grafos**. Cada um foi lido inteiro, com os vizinhos por aresta, e o
sucessor procurado no grafo, no corpus (`kg-corpus-grep.sh`, `git grep` pelo id) e nos resíduos do censo de 08-30.

- **59 ganharam sucessor**: 31 por aresta `SUPERSEDES` local e 28 por `external_edges`.
- **4 foram reabertos** (`status: open`, que era o estado anterior medido no git), com a linha
  "reaberto em 2026-11-12: superseded sem sucessor achável (furo de integridade, Delphi D_MIGRATION_TOUCHED_DELPHI_1112)".

**Direção da aresta externa.** O contrato (`vendor/kg-ssot/tools/kg_validate.py`, `integrity_located`, e o `fix` do
código) só conta a declaração **feita no grafo do nó superado**: `from: "<grafo do sucessor>#<ID>"`, `to: <nó local>`.
Por isso a external_edge foi gravada no grafo do nó superado, não no do sucessor. Onde o grafo do sucessor já
declarava a mesma relação do lado dele (as rodadas r13/r14/r15 do radar E3, o `evolve-cures-2026-10` e o
`task-progress-story-points-2026-10`), a aresta foi espelhada do lado que o contrato lê. No `evolve-cures`, as sete
declarações eram do grafo inteiro (sem `from`); aqui cada uma ganhou a cura específica como ponta.

## Decisões, nó a nó

| grafo | nó | sucessor (ou reaberto) | evidência |
|---|---|---|---|
| `m2-bridge-logto-2026-07` | `D_path_canon_guard` | `E_default_deny_never_existed` | a allowlist que a guarda protegia nunca existiu; o código usa guardas por rota (selo do maestro 08-30) |
| `m2-bridge-logto-2026-07` | `Q_default_api_resource_b1` | `E_p4_rfc8707_proven` | Plano A provado (aud vinculada por RFC 8707): "a escada B1->B2->B3 NAO sera necessaria" |
| `m2-bridge-logto-2026-07` | `A_spec_turnkey` | `E_CENSO0901_C_hono_registration_order_bypass` | a produção nunca adotou o middleware global do spec; foi para guardas por rota |
| `m2-bridge-logto-2026-07` | `A_flip_steps_reversible` | `D_retire_legacy_immediately` | P11 (08-13) tirou AUTH_TOKEN e dual-legacy do binário: o roteiro reversível por linha de env acabou |
| `m2-bridge-logto-2026-07` | `A_verification` | `E_p9_complete` | as 23 provas de um desenho não construído deram lugar à matriz 401/200 medida após o P9 |
| `m2-bridge-logto-2026-07` | `Q_byok_courtesy_mode` | `D_retire_legacy_immediately` | P11 tirou convites courtesy/byok e o encanamento byok do binário: a pergunta ficou sem objeto |
| `m2-bridge-logto-2026-07` | `Q_gated_m3` | `D_org_born_on_demand` | o gatilho das Organizations virou mecanismo: org nasce na 1ª matrícula (decisão do maestro) |
| `m2-bridge-logto-2026-07` | `Q_slices_2_to_4_unexercised` | `D_enroll_instead_of_invite` | as fatias foram rodadas; a 3 redesenhada para --enroll, matrícula executada e verificada no ar |
| `m2-bridge-logto-2026-07` | `E_federation_projected` | `D_org_born_on_demand` | --project-federation deixou de criar orgs e passou a relatar; as 7 vazias foram removidas |
| `m2-bridge-logto-2026-07` | `Q_orgs_are_empty_scaffolding` | `E_org_has_member_with_role` | a org deixou de ser esqueleto (já o REFUTAVA no grafo) |
| `m2-bridge-logto-2026-07` | `Q_seven_orgs_still_empty` | `D_org_born_on_demand` | "as 7 vazias foram removidas"; org passa a nascer sob demanda |
| `m2-bridge-logto-2026-07` | `Q_offline_fallback_truth` | `D_pull_serves_history_not_queue` | o pull serve o histórico com sha256 e descarta o que não bate: não há segundo registro editável |
| `vps-shared-tools-2026-07` | `ENT_email` | `email-logto-2026-08#E_connector_live_invite_sent` (external_edges) | o gap fechou: conector SMTP no Logto e convite real de org com HTTP 201 (antes 501) |
| `vps-shared-tools-2026-07` | `ENT_tunneling` | `E_CENSO0901_Q_tunneling` | a pesquisa F2b concluiu que "tunneling" é o nome errado: a capacidade é ingresso autenticado, já instalado |
| `vps-shared-tools-2026-07` | `D_email_plus_logto_connector` | `email-logto-2026-08#E_connector_live_invite_sent` (external_edges) | a direção foi executada: conector SMTP criado e convite real enviado |
| `vps-shared-tools-2026-07` | `Q_p2_clarify` | `E_CENSO0901_ENT_monitoring` | a pesquisa de observabilidade rodou (stack-harmonia, Elenxo) sem depender do "P2": o bloqueio caiu |
| `vps-shared-tools-2026-07` | `Q_monitoring_stack` | `E_CENSO0901_ENT_monitoring` | pesquisa com Elenxo já executada em stack-harmonia-2026-08, veredito explícito |
| `vps-shared-tools-2026-07` | `Q_email_provider` | `email-logto-2026-08#D_no_self_host_mta` (external_edges) | decidido: não self-hospedar MTA; provider transacional (Postmark) provado ponta a ponta |
| `vps-shared-tools-2026-07` | `C_axis_email` | `email-logto-2026-08#D_email_is_script_not_sdaal` (external_edges) | o teste do eixo foi decidido: email é script, não SDAAL, nos dois níveis |
| `vps-shared-tools-2026-07` | `C_axis_monitoring` | `E_CENSO0901_ENT_monitoring` | o framing pedido para a F1 foi respondido pelo Elenxo de stack-harmonia |
| `vps-shared-tools-2026-07` | `Q_juiz_adversarial_nao_rodou_m8` | `kg-freshness-dogfood-2026-08#D_B_JUIZ_FIXO_VEREDITO_PROPOSTA` (external_edges) | selo B do maestro (08-30): o juiz vira etapa fixa, o limiar de 30% que o nó denunciava caiu |
| `vps-shared-tools-2026-07` | `Q_email_logto_conector_nunca_medido` | `email-logto-2026-08#E_connector_live_invite_sent` (external_edges) | o estado material do conector foi medido: conector vivo e convite com HTTP 201 |
| `onion-identity-2026-07` | `Q_MARKET` | `D_NORTHSTAR_NS1_KG` | censo lote 3: respondida pelo norte NS1 selado pelo maestro em 08-06 |
| `onion-identity-2026-07` | `Q_METHOD` | `D_NORTHSTAR_NS1_KG` | censo lote 3: respondida pelo norte NS1 (o grafo como SSOT-runtime é o método) |
| `onion-identity-2026-07` | `C_ICP_TENSION` | `D_ICP_EMPRESA_MAIS_N1` | o ICP composto (decisão do maestro 08-06, fecha Q_ICP) reconcilia o estreito com as personas amplas |
| `onion-identity-2026-07` | `C_NS3_EDU` | `D_NORTHSTAR_NS1_KG` | candidata a norte não escolhida: o maestro selou NS1 |
| `onion-identity-2026-07` | `C_NS4_CONTROLPLANE` | `D_NORTHSTAR_NS1_KG` | candidata a norte não escolhida: o maestro selou NS1 |
| `onion-identity-2026-07` | `D_COLD_ADOPTER_EXP` | `D_NORTHSTAR_NS1_KG` | o experimento existia para desempatar NS1×NS3, e o desempate veio por decisão direta do maestro (censo lote 4) |
| `onion-identity-2026-07` | `Q_COLD_ADOPTER_0717` | `E_ORBIT_0804` | org externa sob operação de consultoria/CTO não é adotante frio (caso arandek medido) |
| `onion-identity-2026-07` | `C_M8_FECHA_SO_UM_TERCO` | `m8-serial-2026-08#E_FALLBACK_SERIAL_RODA` (external_edges) | o M8 rodou e fechou o terço declarado: o fallback serial executa |
| `onion-identity-2026-07` | `C_ANCORA_SOLTA_79PCT` | **reaberto (open)** | o censo lote 2 virou superseded sem dizer por quê; o número foi corrigido só em prosa (feat-norte-selado R4: 43%/76%), sem nó sucessor |
| `evolve-round-2026-10` | `C_CREATE_SKILL_EXECUTA_GIT_DIFF_A_CADA_INVOCACAO` | `evolve-cures-2026-10#E_LEVA1_DIRETIVAS_DESCRITAS_NAO_ESCRITAS` (external_edges) | cura 1: seis diretivas viraram descrição, 6 antes e 0 depois no simulador (o grafo das curas já apontava, sem from) |
| `evolve-round-2026-10` | `C_RAIO_X_PUBLICA_ALVOS_FALSOS_DE_SKILLS` | `evolve-cures-2026-10#E_LEVA1_SKILL_E_NAO_MEDIVEL` (external_edges) | cura 3: skill com paths: sai NAO-MEDIVEL; o raio-X caiu de 4 alvos para 1 |
| `evolve-round-2026-10` | `C_CHECKPOINT_DO_DRIVE_E_SO_PROSA_E_NAO_VIAJA` | `evolve-cures-2026-10#E_LEVA2_CHECKPOINT_DO_DRIVE_NO_GRAFO` (external_edges) | cura 4: o checkpoint mora no grafo (meta.drive_checkpoint) e o censo o cobra |
| `evolve-round-2026-10` | `C_LINK_QUEBRADO_NA_DOUTRINA_DE_CLIENTE` | `evolve-cures-2026-10#E_LEVA1_LINK_DA_DOUTRINA_DE_CLIENTE` (external_edges) | cura 2: link corrigido para quatro níveis e conferido |
| `evolve-round-2026-10` | `C_FINDINGSCHEMA_DO_EVOLVE_NAO_E_JSON_SCHEMA` | `evolve-cures-2026-10#E_LEVA2_PECA4_DO_EVOLVE` (external_edges) | cura 5: peça 4 em .claude/workflows/evolve.js com JSON Schema real e Workflow/Agent no allowed-tools |
| `evolve-round-2026-10` | `C_QUATRO_SIMBOLOS_FANTASMAS_NO_EVOLVE` | `evolve-cures-2026-10#E_LEVA2_PECA4_DO_EVOLVE` (external_edges) | cura 5: o bloco JS com runCommand e sweepSessionMemory saiu da superfície |
| `evolve-round-2026-10` | `E_D9_NAO_E_NOOP_NO_CORE` | `evolve-cures-2026-10#E_LEVA1_PREMISSA_DO_D9_CORRIGIDA` (external_edges) | cura 7: a premissa "no-op" do D9 foi riscada com a medição ao lado |
| `radar-E3-2026-10-16-r12` | `E_SDK_0_3_301_EM_PRODUCAO_1016` | `radar-E3-2026-10-17-r13#E_CHAT_EM_PRODUCAO_NO_CLI_2_1_302_1017` (external_edges) | a r13 já declarava a SUPERSEDES do lado dela; produção subiu de 2.1.301 para 2.1.302 |
| `radar-E3-2026-10-17-r13` | `E_PIN_DO_REVISOR_SOBE_E_ENTRA_NO_CENSO_1017` | `radar-E3-2026-10-21-r14#E_PIN_DO_REVISOR_EM_1_0_256_CLI_2_1_306` (external_edges) | a r14 já declarava: o pin subiu de v1.0.252 para v1.0.256 |
| `radar-E3-2026-10-17-r13` | `Q_REVISOR_NO_PIN_NOVO_PROVADO_NUM_PR_COM_A_LABEL` | `radar-E3-2026-10-21-r14#Q_REVISOR_NO_PIN_1_0_256_PROVADO_NUM_PR_COM_A_LABEL` (external_edges) | a r14 já declarava: a mesma prova, no pin seguinte |
| `radar-E3-2026-10-17-r13` | `E_CHAT_EM_PRODUCAO_NO_CLI_2_1_302_1017` | `radar-E3-2026-10-21-r14#E_SDK_DO_BRIDGE_QUATRO_VERSOES_ATRAS_1021` (external_edges) | a r14 já declarava: o bridge ficou 4 versões atrás do host |
| `radar-E3-2026-10-21-r14` | `E_PIN_DO_REVISOR_EM_1_0_256_CLI_2_1_306` | `radar-E3-2026-10-21-r15#E_PIN_DO_REVISOR_EM_1_0_257_CLI_2_1_307` (external_edges) | a r15 já declarava: pin v1.0.257 (CLI 2.1.307) |
| `radar-E3-2026-10-21-r14` | `E_SDK_DO_BRIDGE_EM_0_3_306_EM_PRODUCAO_1021` | `radar-E3-2026-10-21-r15#E_SDK_DO_BRIDGE_UMA_VERSAO_ATRAS_1021` (external_edges) | a r15 já declarava: o bridge ficou 1 versão atrás do host |
| `radar-E3-2026-10-21-r14` | `Q_REVISOR_NO_PIN_1_0_256_PROVADO_NUM_PR_COM_A_LABEL` | `radar-E3-2026-10-21-r15#Q_REVISOR_NO_PIN_1_0_257_PROVADO_NUM_PR_COM_A_LABEL` (external_edges) | a r15 já declarava: a prova passou para o pin v1.0.257 |
| `fila-2026-10-06` | `E_TM_PERCENTUAL_IGNORA_STORY_POINTS` | `task-progress-story-points-2026-10#E_PERCENTUAL_PONDERADO_E_DECLARADO` (external_edges) | o grafo do sucessor já declarava: o % da mãe passou a ser ponderado por pontos |
| `fila-2026-10-06` | `E_PRECOMMIT_SELECAO_GROSSA` | `Q_PRECOMMIT_SELECAO_POR_CASO` | a re-forja por caso (SAC-72, 10-11) levou o núcleo fixo de 14 para 1, medido antes e depois |
| `librechat-kg-runtime-2026-08` | `Q_WEB_SEARCH_GAP` | `E_ONION_KG_MCP_DESLIGADO_DE_PROPOSITO` | a face conversável perdeu o objeto: em 08-27 o bloco do Onion saiu do LibreChat e os MCPs do host foram desligados |
| `librechat-kg-runtime-2026-08` | `D_ROUTE_TO_BRIDGE` | `E_ONION_KG_MCP_DESLIGADO_DE_PROPOSITO` | a política valia para a face conversável, removida do LibreChat em 08-27 (medido em 10-11) |
| `onion-refinaria-2026-08` | `E_lint_only_ja_existe_e_e_parcial` | `elenxo-mecanismos-lint-2026-08-13#E_PISO_IRREDUTIVEL_DA_REFINARIA_SUPERADO` (external_edges) | o nó do Elenxo de 08-13 se declara o reconciliador: piso de ~12s caiu para ~5s |
| `vaultwarden-logto-2026-08` | `E_PRIMEIRO_CASO_DOCUMENTADO` | `E_SSO_VALIDADO_PONTA_A_PONTA` | o primeiro caso público passou a existir e funciona (já o REFUTAVA no grafo) |
| `waha-adapter-2026-07` | `E_gatilho_fechado` | `E_ack_lifecycle_proven` | o "gatilho" de 08-01 era só aceite na fila; a entrega real foi provada pelo ciclo de ack do webhook |
| `arandek-adoption-dogfood-2026-07` | `Q_RELAY` | `pr-decision-history-2026-08#PR_465` (external_edges) | o relay chegou ao core (b01d740a, 07-25) e foi triado para _processed no PR #465 |
| `colaboracao-onion-2026-07` | `D_PRODUTOS_CORE` | `relay-gustavo-pulga-triage-2026-07#D_prioridade` (external_edges) | a proposta virou a triagem dos 7 produtos, com veredito por produto e entregas |
| `federation-health-2026-07` | `C_METAGAMIFY_VENDOR_VNEXTPIN` | **reaberto (open)** | o censo lote 3 disse "pin já avançado", mas o único avanço medido (PR #490) é do members.yaml, não do carimbo inválido na história do vendor |
| `federation-health-2026-07` | `C_ADOPTER_PERSONALITY_SEEDS_PENDING` | **reaberto (open)** | o censo lote 6 apontou só a contagem desatualizada; nenhum nó registra a contagem nova |
| `graduated-automation-elenxo-2026-07` | `Q_MONITORED_RUNG` | **reaberto (open)** | o próprio censo lote 3 achou (a) e (c) ainda abertas; só (b) morreu (E_EFFECT_GATE_LIVE), e isso não substitui o nó |
| `gtm-decisions-2026-07` | `C_D5_rec` | `d5-pricing-2026-07#D_D5` (external_edges) | a recomendação foi incorporada na decisão D5 (blend A+B) do grafo de pricing, ratificada em 07-29 |
| `identidade-onion-vps-2026-08` | `Q_RECUPERACAO_NAO_EXISTE_ONDE_MAIS_DOI` | `I_A6_O_BLOQUEIO_NAO_ERA_SMTP` | o bloqueio não era SMTP: o e-mail entrou nas identidades em 08-11 (já o REFUTAVA no grafo) |
| `kg-console-rich-design-2026-07` | `Q_f3_wow` | `pr-decision-history-2026-08#PR_488` (external_edges) | o F3 (partículas, semantic-zoom, minimapa, scrollytelling) foi entregue no PR #488 em 07-29 |
| `m3-federation-admin-2026-07` | `Q_auth_decision` | `stack-harmonia-2026-08#D_hosted_service_identity` (external_edges) | o ADR aceito decidiu o modelo de identidade (Organization do Logto projetada do members.yaml); o bridge já usa OIDC |
| `relay-gustavo-pulga-triage-2026-07` | `C_p1_gerador_vertical` | `E_create_vertical_existe` | o produto já existia: /meta:create-vertical (já o REFUTAVA no grafo) |
| `relay-gustavo-pulga-triage-2026-07` | `E_sem_perfil_visitante` | `D_p4_visitor_authority` | entregue: AUTH_visitor na topologia e lente na fase Orient do onion-onboarding |

## Onde a escolha é mais fraca

Três sucessores carregam inferência além da leitura literal, e merecem o olho do refutador:

- `D_path_canon_guard` ← `E_default_deny_never_existed`: a guarda de canonicalização defendia a allowlist que nunca
  existiu. Se o roteador por rota também precisar de canonicalização, o sucessor fica parcial.
- `Q_gated_m3` ← `D_org_born_on_demand`: o nó é um balde de sete itens gated; o sucessor cobre o gatilho das
  Organizations (o eixo do balde), não os outros seis (CSP da PWA, RBAC fino, `bypassPermissions`).
- `Q_auth_decision` ← `D_hosted_service_identity`: o ADR decidiu o modelo de identidade e o bridge já usa OIDC, mas o
  "command-side" do M3 (mutação do `members.yaml`) segue sem auth backend por desenho.

## Gate

- `kg-radar.sh <grafo> --integrity --schema` exit 0 e `kg-contract-check.sh <grafo>` rc 0 nos 21 grafos tocados.
- `ops/kg-gate-ci.sh`: rc 0, `integrity.superseded-without-successor` **63 → 0**; a base foi regravada com
  `ops/kg-gate-ci.sh --update` para travar o ganho (o diff da base só remove a linha do aviso por grafo).

## Refutador independente

Amostra de 15 (as 3 fracas e 12 sorteadas com `random.seed(20261112)`): 11 SUSTENTA, 4 EXAGERA, 0 REPROVA; direção das 28 external_edges conferida no validador; os 4 reabertos voltaram ao status anterior medido; gate rc 0. Correções aplicadas: `D_path_canon_guard` e `Q_gated_m3` reabertos (o sucessor não os supera); `Q_auth_decision` reaberto com a aresta virando CONSTRAINS; `C_M8_FECHA_SO_UM_TERCO` vira `confirmed`, com a aresta SUPPORTS e proveniência própria. Limite: cerca de 8% de EXAGERA na amostra sugere resíduo parecido nos 44 não lidos.
