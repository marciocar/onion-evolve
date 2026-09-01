---
title: "Backlog REAL — revisão total dos 99 abertos (2026-09-01)"
category: analysis
date: 2026-09-01
kg: docs/evolution/research/maestro-vivo-2026-08/maestro-vivo-2026-08.kg.yaml
run_id: "wf_2944480c-98f"
tokens: 5388890
agents: 76
duration_min: 21
verified_at: 2026-09-01
---

# Backlog REAL — o que sobrou de verdade dos 99 abertos

> Projeção da revisão-total (72 medidos por censo+realidade com juiz fixo opus; 27 frescos citados
> pelo carimbo ≤7d). SSOT = os grafos-fonte (carimbos/SUPERSEDES aplicados neste PR). Juiz
> reprovou 21/72 (29%) — reprovado fica SEM carimbo, listado para re-medição honesta.
> Custo real 5,39M tokens vs teto 4,5M declarado (+20%; workers rodaram acima dos 45k médios).

**Saldo: 9 REAIS-acionáveis · 0 GATED-com-gatilho-DISPARADO (prontos) · 26 GATED aguardando · 15 mortos-candidatos (selo seu) · 21 re-medir · 1 fora-do-core · 27 frescos**

## 1 · REAIS-ACIONÁVEIS + gatilhos DISPARADOS — material da próxima onda

| Atenção | Nó | Grafo | Próximo passo |
|---|---|---|---|
| 18.0 | `C_reuse_readmodel` | m3-federation-admin-2026-07 | Fechar status:open→done neste .kg.yaml (a recomendação foi seguida à risca; M2/REGRA 66 fechou hoje sem redesenho, nada resta a decidir aqui). |
| 10.8 | `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA` | m2-bridge-logto-2026-07 | Abrir PR no onion-bridge (/home/onion/onion-bridge/src/identity.ts) implementando jwksAttemptedAt (marca a TENTATIVA mesmo em falha, para o piso de 60s valer no |
| 9.6 | `C_a2a_gate_narrow` | m2-bridge-logto-2026-07 | Recarimbar verified_at (2026-07-27→2026-09-01) sem mudar o label — nenhum drift; o gate estreito de /a2a é arquitetura intencional e permanece assim; o risco vi |
| 8.0 | `E_LINT_NAO_ENXERGA_WORKFLOWS` | elenxos-2026-08-07 | Estender o `_find` de check_no_direct_provider_calls/check_abstraction_methods_exist (e regras SDAAL irmãs) para incluir `.github/workflows/*.yml` e `.claude/va |
| 5.6 | `C_commodity_vs_diff` | m3-federation-admin-2026-07 | Selar o nó como status:confirmed com verified_at=2026-09-01 e a evidência acima (README do Logto + members.yaml) — nenhuma mudança de arquitetura necessária, só |
| 5.0 | `Q_instrument_metrics` | gtm-decisions-2026-07 | Persistir a saída `--jsonl` dos 4 scripts (cron diário ou hook) num arquivo versionado/tracked e escrever um agregador simples que combine os 4 sinais num "valo |
| 4.2 | `Q_p10_mutation_not_run` | m2-bridge-logto-2026-07 | Em /home/marcio/onion-bridge-dev, subir `npm run dev` local (fora de produção), remover temporariamente o `...(callerCanWrite(c) ? {} : { tools: READ_ONLY_TOOLS |
| 3.4 | `C_console_autooff_gap` | m2-bridge-logto-2026-07 | Editar /home/marcio/onion-vps-logto/console.sh: no case on) adicionar `sudo systemd-run --unit=onion-logto-console-autooff --on-active=30m -- <caminho>/console. |
| 3.0 | `Q_BRANCH_MAIN` | onion-identity-2026-07 | Materializar em docs/evolution/federation/members.yaml a lineage `product: {branch: main, pin: <verificado por pin-integrity-check.sh>}` para o <hub-t1>, confor |

## 2 · GATED — aguardando gatilho (nomeado e MEDIDO como não-disparado)

| Nó | Gatilho |
|---|---|
| `C_NS1_KG` | aparecer 1 adotante fora da órbita do maestro que adote o Onion por iniciativa própria (não convite/CTO/curso/serviço dele) puxando especificamente os diferenciais raros  |
| `Q_SDAAL_NAO_TEM_CONSUMIDOR_SEM_LLM` | demanda medida: um workflow `.github/workflows/*.yml` passa a chamar `gh api`/`gh pr` cru para uma operação do forge ainda não materializada (equivalente ao que motivou p |
| `C_compliance_pack` | Q_p4_interviews: zero comprador P4 entrevistado — gate fecha quando 1-2 entrevistas P4 forem conduzidas e registradas em decisions.md (D6) |
| `C_op_update` | gate da <cliente-poc> multi-operador citado no próprio comando (0 role:consumer, contracts/ inexistente) — a costura update/promote/revoke se deriva fresca quando esse gate  |
| `C_sota_subscription` | SSOT L1-L6 (classificação-por-inferência + gate-por-propósito + ε-ledger) construído + dogfoodado com threat model N-tenant verificado (hoje só N=1 pessoal provado) |
| `D_logto_not_ssot` | 1º role:consumer (T2) real aparecer em docs/evolution/federation/members.yaml, OU o plano de recursos B3 (D_resource_plan_b) ser ativado |
| `Q_ntenant_proof` | Gate D2-ativação (L1-L6 dogfoodado) dispara, OU Q_p4_instrument fecha com adotante P4 real medido — qualquer um dos dois libera investir em prova N-tenant |
| `Q_TENANT_WRITE_DESTINATION` | nasce quando houver multi-tenant KG routing (segunda proposta de conhecimento de tenant batendo no mesmo buraco, ou decisão de desenhar o roteamento) |
| `Q_MAP_LEG_GATED` | Nasce quando houver consumidor nomeado de ingestão doc→grafo no core (não a PoC) |
| `C_COMPLIANCE_RARE` | gtm-decision-brief-2026-07.md pede "1-2 entrevistas P4 + instrumentar conversão do aha por persona" (metrics.md) antes de tratar P4 como ICP validado |
| `Q_FEDERACAO_VISIBILITY_GATE` | qualquer retomada de regeneração de site/federacao/ (ou refresh do snapshot) |
| `D_GREP_OLD_PIN` | decisão explícita do maestro de priorizar (o próprio nó diz "BACKLOG não implementado; priorizar é do maestro"); Q_PIN_GREP_WORTH_IT pede medir quantos artefatos derivado |
| `Q_p4_interviews` | o maestro conseguir e realizar 1-2 conversas com compradores/times regulados (P4) disponíveis para discutir o compliance-pack — nenhum candidato P4 de pricing identificad |
| `ENT_monitoring` | REGRA DOS 5 PORTÕES do F2-b: pull datado (dor com data) + não-reuso provado + dado novo + volume força + dono nomeado — todos precisam passar para internalizar observabil |
| `Q_MUDEZ_DA_GUARDA_NAO_SE_IDENTIFICA` | próximo PR que tocar .github/workflows/onion-review.yml leva a cura barata (notice positivo no else) junto |
| `C_BOLETIM_INFORM` | recorrência — 2a ocorrência real do boletim core→estrela (Rule of Three, per §14 do research) |
| `C_p4_audit_trail` | 1º membro role:consumer (T2) real em members.yaml OU 1º contrato breaking registrado em contracts/ (Q_gatilho, m3-federation-admin-2026-07.kg.yaml) |
| `Q_docker_cgroup_driver` | D_logto_same_protection_tier ser efetivamente implementado (criação dos arquivos onion.slice/onion-auth.slice + reload do compose com cgroup_parent) — hoje é só decisão r |
| `Q_MAIS_UM_IMUTAVEL_GATED` | maestro contratar a conta rsync.net (decisão de custo dele, sem urgência) |
| `Q_p4_no_field_proof` | O maestro decidir buscar/agendar 1-2 entrevistas com prospects regulados (P4) — ninguém mais pode disparar isso, é ação comercial dele. |
| `Q_REVERSE_JOIN_SCOPE` | demanda real recorrente: o mesmo padrão de join-reverso ser fiado à mão 2-3x (per D_GUARDRAIL_PULL_NOT_PUSH), hoje N=0 |
| `C_p3_agg_view` | ADR 2026-08 substitui o gatilho antigo (T2/contracts) por: "≥1 federado NÃO-maestro migrado para o Logto consumindo recurso hospedado" — hoje 1 usuário no Logto e é o pró |
| `C_axis_tunneling` | Um humano que NÃO é o maestro precisar de uma UI (não shell) numa caixa da VPS — hoje só o maestro tem essa necessidade; acesso SSH/shell de terceiros (ex.: <adotante-d>) |
| `D_SCRUB_FROZEN_POISON_IN_VENDORS` | a equivalência vendor==merge-base quebrar em poc-venda-direta-pdi ou <membro-t2> (veneno congelado voltando a incomodar) |
| `Q_ALARME_DE_AUSENCIA_DE_AGENDADO` | 1a vez que um run com event=schedule for observado ausente por >48h |
| `Q_wake_session` | O próprio GAPS-ADDENDUM.md não nomeia um gatilho específico para ESTE gap (wake-session); o gap irmão citado no mesmo documento (assinatura criptográfica do pin/Agent Car |

## 3 · PROPOSTAS DE SELO (mortos-candidatos — flip é seu; SUPERSEDES já aplicado nos DRIFTED)

| Nó | O que o superou |
|---|---|
| `D_mais_valor` | A decisão do nó (fechar N-tenant/schema-masking PORQUE isso destrava 'Company Brain provável' como segmento de mercado a vender) foi superada por uma correção de GTM data |
| `D_resource_plan_b` | O nó pede um PLANO DE CONTINGÊNCIA (A→B1→B2→B3) a ser seguido SE o Plano A falhasse nas provas, com B3 gated por aceite explícito do maestro. O vivo mostra que A não falh |
| `C_hono_registration_order_bypass` | A premissa do claim — um `app.use('*', requireIdentity)` GLOBAL cuja ORDEM DE REGISTRO decide bypass-total — não corresponde à arquitetura real. A produção nunca adotou m |
| `C_MESMA_CLASSE_MUDA_DE_CAMPO_A_CADA_RODADA` | A parte histórica do claim (duas classes confirmadas eram a mesma classe reaparecendo em campo diferente) segue verdadeira e já está registrada (edges SUPPORTS de E_O_FEC |
| `D_META_RADAR_DESENHO` | A proposta foi INTEGRALMENTE ENTREGUE e MERGEADA na main desde a rodada anterior (08-31→09-01): comando /meta:radar, REGRA 65 (staleness por eixo + extensão para versão d |
| `Q_GUARDA_DE_EXPOSICAO_SO_OLHA_PARA_DENTRO` | O nó ficou aberto como pergunta GATED em 2026-08-12; o próprio grafo mostra que o gatilho disparou (2º adotante com o mesmo defeito) e a decisão foi tomada e mecanizada e |
| `A_analysis_structure` | O nó pede uma escada sequencial F0→F4 que segue tecnicamente incompleta (F2 reprovada e nunca refeita; F3/F4 nunca rodaram como fases formais). Mas o OBJETIVO da escada — |
| `C_trust_matrix_stays_onion` | O nó está com status:open pedindo algo que já existe e está em produção: a matriz fina não é "grosso demais" resolvida por Logto — ela nunca dependeu do RBAC Logto para e |
| `Q_ARANDEK_UPDATE` | O nó estava formulado como pergunta em aberto sobre um evento futuro ("quando... rodar"); o evento não só ocorreu como foi superado por múltiplos ciclos adicionais de upd |
| `Q_p4_instrument` | O nó (aberto desde 07-25) dizia 'Zero adotante P4 provado hoje'. Isso morreu: entre 2026-08-04 e 2026-08-27 rodou uma PoC real com prospect real (HPE Autos, via oferta Be |
| `D_NO_DISTORT` | O nó está status: open no grafo, mas o trabalho que ele descreve (aplicar a diretriz "não entortar doutrina" ao decidir o papel da develop) foi CONCLUÍDO, RATIFICADO e EN |
| `C_NS2_PORTABLE` | O nó descreve NS2 como candidata de north-star em aberto com uma ressalva pendente ("família não verificada"). Isso morreu em duas camadas: (a) Q_NORTHSTAR foi decidida e |
| `Q_members_ci_gate` | O nó pedia ligar HARD o gate de CI sobre members.yaml vivo (estava só na rota do comando + selftest). Isso foi entregue: REGRA 66 faz exatamente isso, com PR(s) 6799c8df/ |
| `Q_automacao_pipeline` | O nó ficou aberto (status:open) como se a pergunta seguisse pendente, mas ela já foi respondida e a resposta já foi construída no mesmo dia (PR #500): automação parcial m |
| `Q_volume_not_reproduced` | A pergunta "o volume real (110 arquivos) foi medido no repo do adotante?" foi respondida — com "não foi, e não precisou ser". No mesmo dia (2026-07-27), o próprio update  |

## 4 · RE-MEDIR — o juiz reprovou a medição (sem carimbo; motivo registrado)

| Nó | Motivo do juiz |
|---|---|
| `D_spec_now_build_gated` | O gatilho foi medido, mas o gatilho ERRADO — e este é o nó que POSSUI o gate. Existe em docs/analysis/onion-adr-hosted-service-identity-2026-08.md (commit 44173a95, 2026- |
| `D_D5` | Contagem de claims desonesta e morte não procurada. (a) claims=13/13 não sai do label: o method soma NÓS DO GRAFO INTEIRO ('1 decision + 4 claims de preço + 8 evidence +  |
| `Q_PRIMEIRO_DOGFOOD_REAL_DAS_CINCO_CLASSES` | GATILHO DECLARADO CONTRA A PRÓPRIA MEDIÇÃO. O worker registra `gatilho_disparou: NAO` para um gatilho que ele MESMO observou disparar três vezes: 88099af3 (2026-08-27, 47 |
| `C_auth_logto_sdaal` | Confirmou 5/5 apoiando-se em nó SUPERSEDIDO e sem checar o ADR que decidiu justamente a parte declarada 'não-comprometida'. (a) O observed diz que Q_auth_decision 'já foi |
| `Q_LACUNA_DECISAO_MAIS_CODIGO` | COVERAGE 9/9 INFLADA — o method e 'Contei 9 afirmacoes no label', sem um unico comando. Das 9, pelo menos 5 sao claims EXTERNOS e datados (nenhum sistema publico une graf |
| `Q_CUSTO_DO_PORTE_NUNCA_MEDIDO` | MORTE NÃO PROCURADA + gatilho contraditório. O label diz textualmente 'ESTE NO NAO PEDE A MEDICAO — pede que a lacuna pare de ser invisivel'; o próprio grep do worker já  |
| `D_pkce_risk_mitigations` | CONTAGEM DESONESTA CONTRA O LABEL: 3/3 + CONFIRMED para um nó em que 2 das 3 mitigações NÃO existem. Medi: `ops/bridge-auth/logto-provision.sh:593` seta `accessTokenTtl:3 |
| `Q_SDAAL_EXECUTAVEL_ONDE_PARA` | METHOD NAO EXECUTADO: o campo method nao contem UM SO comando — e literalmente 'Lido o no completo (label, verified_against)', isto e, verificar o no lendo o no. Mas o ob |
| `Q_COLD_ADOPTER` | O CONFIRMED NÃO PROCUROU A MORTE. O nó pergunta se existe QUALQUER pull FORA da órbita; o worker mediu telemetria de UM repo criado há 6 dias (marciocar/onion-plugins, 20 |
| `Q_A2A_SPAWNSYNC_BLOQUEIA_O_EVENT_LOOP` | NÓ plane:PROD SELADO CONTRA O ARTEFATO ERRADO. O nó tem `trace: /home/onion/onion-bridge/src/a2a.ts` (produção), e o worker mediu em `/home/marcio/onion-bridge-dev/src/a2 |
| `Q_TESTEMUNHO_NAO_MEDIVEL_0804` | MEDIÇÃO REPORTADA É FALSA CONTRA O COMANDO DECLARADO. O observed afirma 'Zero ocorrências de evidence_class em todo o repo (schema, radar, docs, qualquer .kg.yaml)', mas  |
| `Q_A_SENHA_DA_CHAVE_QUEBROU_A_AUTOMACAO` | CONTAGEM DESONESTA (1/1) E DRIFT MEDIVEL NAO ACHADO. O label carrega no minimo 9 afirmacoes (pass show rc=2; TRES up.sh afetados; backups nao quebraram; 3 defeitos empilh |
| `D_QUADRO_CITACOES` | CONTAGEM DE CLAIMS CONVENIENTE + evidência recontada errado. O label tem 6 asserções, e a 6ª é 'mesma area de doutrinas FUTURA' — exatamente a que o próprio worker mediu  |
| `Q_train_cert_chaining` | Gatilho DECLARADO, não medido — por confissão do próprio worker. O campo gatilho diz '3+ engajamentos reais de treino e/ou certificação fechados (dados externos ao repo,  |
| `Q_RADAR_WIDGET_PARALLEL_FORMULA` | O GATILHO FOI MEDIDO NO ARQUIVO QUE NÃO CONTÉM MAIS A FÓRMULA. O worker cita 'kg-radar.sh:10-11' como o lado core da fórmula paralela — mas essas duas linhas são COMENTÁR |
| `C_dissent_auth_transversal` | GATILHO DECLARADO, NUNCA MEDIDO — e ele e uma QUANTIDADE contavel que o proprio worker escreveu: '2+ integracoes diretas duplicando logica de auth fora da projecao member |
| `Q_tunneling` | CONFIRMED CONTRADITO PELO PROPRIO LOTE, por falha de VOCABULARIO no grep. O no pergunta 'ngrok x Cloudflare Tunnel x Tailscale Funnel x Caddy-so — para QUE?'. Essa pesqui |
| `C_p4_gate_visibility` | Confirmou 3/3 sem NUNCA abrir o trace do próprio nó — e o trace não sustenta o claim. O nó traceia CLAUDE.md:15, que é a doutrina do acoplamento por `exit 2` de hook ('A  |
| `C_d3_comment_dup` | CONFIRMED sobre uma claim QUANTITATIVA que a própria medição do worker desmente. O label afirma 'template de comentário Unicode DUPLICADO entre task.md e feature.md (~40  |
| `Q_PIN_GREP_WORTH_IT` | MEDIÇÃO NO DIRETÓRIO ERRADO + a medição central nunca reportada. O método declara grep em '/home/marcio/{<membro-t2>,onion-arthur,onion-pedro,<adotante-a>}' como 'adotant |
| `Q_three_or_more_branches` | GATILHO MEDIDO NO CAMPO CEGO. O worker mediu só 'grep -n integration_branch' em members.yaml (3 ocorrências, linhas 166/199/394) e concluiu 'nenhum adotante tem mais de 1 |

## 5 · FORA-DO-CORE

- `Q_excecao_enterprise` — Nenhum — nó didático fictício não deve virar item de backlog real; nenhuma ação necessária no core.

## 6 · FRESCOS (≤7 dias — não re-medidos, carimbo cita a fonte)

- `D_logto_same_protection_tier` (m2-bridge-logto-2026-07, at. 22.4) — verified_at 2026-08-30
- `Q_GUARDAS_COERENTES` (guardas-revisao-2026-08, at. 21.6) — verified_at 2026-08-30
- `D_middleware_order_first` (m2-bridge-logto-2026-07, at. 18.0) — verified_at 2026-08-30
- `E_SEGUNDO_ADOTANTE_MESMA_CLASSE_DE_EXPOSICAO` (identidade-onion-vps-2026-08, at. 14.2) — verified_at 2026-08-30
- `Q_ARANDEK_SEGREDOS_E_BINDS_NO_COMPOSE_COMMITADO` (identidade-onion-vps-2026-08, at. 12.0) — verified_at 2026-08-30
- `C_docker_floor_gap` (m2-bridge-logto-2026-07, at. 10.8) — verified_at 2026-08-27
- `C_op_promote` (m3-federation-admin-2026-07, at. 8.4) — verified_at 2026-08-30
- `Q_INDICE_DO_DIARIO_SEM_CATRACA` (guardas-revisao-2026-08, at. 8.1) — verified_at 2026-08-28
- `Q_TRES_GRAFOS_NAO_SAO_YAML_VALIDO` (guardas-revisao-2026-08, at. 8.0) — verified_at 2026-08-29
- `Q_d2_l1l6_activation` (d5-pricing-2026-07, at. 7.5) — verified_at 2026-08-30
- `D_D2_activation` (gtm-decisions-2026-07, at. 7.5) — verified_at 2026-08-30
- `Q_gatilho` (m3-federation-admin-2026-07, at. 7.0) — verified_at 2026-08-30
- `Q_route_inventory` (m2-bridge-logto-2026-07, at. 6.0) — verified_at 2026-09-01
- `C_GRANAAI_LINEAGES_UNKNOWN` (federation-health-2026-07, at. 6.0) — verified_at 2026-08-30
- `Q_COUNTABLE_CRITERIA` (graduated-automation-elenxo-2026-07, at. 6.0) — verified_at 2026-08-30
- `Q_PREDICTIVE_ALERTS` (graduated-automation-elenxo-2026-07, at. 6.0) — verified_at 2026-08-30
- `C_op_revoke` (m3-federation-admin-2026-07, at. 5.8) — verified_at 2026-08-30
- `C_SEM_GATE_REGRA_SEM_TESTE` (guardas-revisao-2026-08, at. 5.4) — verified_at 2026-08-30
- `C_p3_self_service` (m3-federation-admin-2026-07, at. 5.2) — verified_at 2026-08-30
- `Q_onprem_tension` (m3-federation-admin-2026-07, at. 4.8) — verified_at 2026-08-30
- `Q_signup_close_not_via_api` (m2-bridge-logto-2026-07, at. 4.8) — verified_at 2026-08-30
- `C_S4` (granaai-doctrine-absorption-2026-07, at. 4.8) — verified_at 2026-08-30
- `Q_open_trigger` (gtm-decisions-2026-07, at. 4.4) — verified_at 2026-08-30
- `D_ISOLATION_EXTENSION_GATED` (constellation-dialogic-layer-2026-07, at. 4.0) — verified_at 2026-08-30
- `Q_orquestrador_gated` (kg-diagnose-automation-2026-07, at. 2.4) — verified_at 2026-08-30
- `Q_live_narration` (kg-console-rich-design-2026-07, at. 2.0) — verified_at 2026-08-30
- `Q_BULBO_DIAGRAM` (onion-doctrine-elenxo-bulbo-2026-07, at. 1.6) — verified_at 2026-08-30
