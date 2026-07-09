---
tipo: sinal-upstream (artefato de referência)
data: 2026-07-09
origem: rhilo-app (redesenho Command Center v2, branch feat/command-center-v2-redesign)
assunto: ARTEFATO — command-center-atom-map.md (pedido na resposta 'sdaal-design-vertical-ja-existe', Ponto 2)
re: mapear atom-map + invariante de fonte-única contra o design-context/ + SDAAL do core (absorver o conceito, não a impl React)
---

# Command Center v2 — Mapa de Átomos (o contrato do redesign)

> **Fase 0 do redesign.** Antes de qualquer pixel: cada **átomo de informação** tem **1 fonte** (endpoint dono),
> **1 dono de exibição** e **1 dono de escrita**. Este doc é o contrato — a UI (Fases 1-3) obedece a ele.
> Derivado do inventário exaustivo das 10 abas (~100 elementos). Idioma: doc pt-BR, código inglês.

## Convenção de rastreabilidade (`SourceTag`)

Todo elemento que exibe um dado carrega sua **linhagem** (via o primitivo `SourceTag` — tooltip/badge):

```
<SourceTag
  endpoint="/admin/gamification/equity-trend"   // fonte (:3000)
  concept="equidade (Gini)"                       // conceito de domínio (nó do KG/SSOT)
  formula="1 - Σ|share_i - 1/n|"                   // cálculo, se houver transform no front
/>
```

Regra: **o dado só aparece onde é dono**; réplicas viram link ("ver em X") ou `SourceTag` apontando ao dono — nunca uma 2ª busca do mesmo número por outro endpoint.

## Fontes canônicas por átomo

Conceitos de domínio referenciam o KG/SSOT (`metagamify docs/rhilo/graph/wrr-audit.kg.yaml`): esteira, chamada, SLOT, S_LIMBO, dose, activeCases, ratio, SLA-state, decisão, override.

| Átomo | Endpoint dono (:3000) | Conceito (KG) | Dono de EXIBIÇÃO (1) | Dono de ESCRITA (1) |
|---|---|---|---|---|
| **Gini + tendência + anomalia** | `equity-trend?scope=global` | equidade | `EquityCard` (Visão Geral) | — (read) |
| Concentração/saturação por nível | `queue.summary.utilizacao` | esteira/saturação | `SaturationByLevel` (Visão Geral) | — |
| Escritórios ativos / pausados | `queue.summary` | esteira | `GlobalKpis` (Visão Geral) | — |
| Pastas ativas (`activeCases`) | `queue.summary.totalActiveCases` | activeCases | `GlobalKpis` | — |
| Capacidade livre | `queue.summary.totalAvailableCapacity` | capacidade/dose | `GlobalKpis` | — |
| Desvio % (vs alvo) | `queue.summary.desvio` | esteira | `GlobalKpis` | — |
| Déficit/famintos por nível | `conversion-dispersion` | déficit/conversão | `LevelCockpit` (Visão Geral) | — |
| Piso **configurado** por nível | `config.monthlyDefaults` | cap/floor | `LevelCockpit` (read, linka p/ editar) | `JourneyParamsEditor` (Gestão›Config) |
| Piso **efetivo** por nível | `conversion-dispersion.floorPerFirm` | cap/floor efetivo | `LevelCockpit` (rótulo "efetivo") | — |
| Dose (conv% + doseMax/nível) | `config.doseControl` | dose | `LevelCockpit` (read) | `JourneyParamsEditor` (Gestão›Config) |
| Chamadas em voo / limbo | `conversion-dispersion.inflightSlots` | S_LIMBO/dose | `Materialização` (dono) | — |
| SLOTs pendentes (NET) | `pending-slots-by-firm` | SLOT/S_RESERVED | `Materialização` | — |
| SLOTs presos (>15min) | `integration-health.openSlots` | S_LIMBO | `Materialização` | — |
| Sync-log (op/sucesso/falha/p50/p95) | `integration-health` | integração | `Materialização` | — |
| Latência p95 fila | `integration-health.wrrCallMetrics` | integração | `Materialização` | — |
| Roster da fila (posição/elegibilidade) | `queue.queue[]` | esteira/fila | `FilaTable` (Fila & Distribuição) | — |
| Séries reais de chamadas | `distribution-history-all` | chamada | `FilaTable` (col série) | — |
| ratio (activeCases/peso) | `queue.ratio` | ratio | `FilaTable` (adv) + trace nas Decisões | — |
| Cobertura UF / Tese | `queue.coveredUfs/Theses` | elegibilidade | `FilaTable` | — |
| Ledger XP/pontos por firma | `queue/:id/points-history` | peso/XP | `FirmDrawer` | — |
| Decisão real + pipeline S1..S7 | `decisions` / `decisions/:id` | decisão | `DecisionsTab` | — |
| Replay REAL de `decide()` | `decisions/:id/replay` | decisão | `DecisionsTab` (via `ReplayButton`) | (POST) |
| Rejeições (Σ rejectedCount) | `decisions` | decisão | `DecisionsTab` (1 KPI) | — |
| Simulação passo-a-passo | `eligible-firms` + `carolSim` (memória) | decisão (SIM) | `OraculoTab` | — |
| Overrides (cap/floor/escopo/razão/exp) | `overrides` | override | `OverridesEditor` (Gestão›Op) | `OverridesEditor` / `Bulk` / `SLA-Travar` |
| Overrides expirando (≤7d) | `overrides/expiring` | override | `FirmInterventionActions` (lista; KPI = header) | — |
| Modo de distribuição | `distribution/config` | modo | `DistributionModeSummary` (Gestão›Op) | idem |
| Flags do motor (14) + preset | `flags` | flags/dose/ratio | `EngineFlags` (Gestão›Config) | `JourneyParamsEditor` |
| Threshold SLA backlog | `config.slaBacklogBlockThreshold` | SLA | `JourneyParamsEditor` (write) | `JourneyParamsEditor` |
| Backlog SLA (overdue/firma) | `sla-backlog` | SLA-state OVERDUE | `SlaBacklogPanel` (Gestão›SLA) | — |
| Ação Travar/Destravar (cap=0) | `overrides/participant/:id` | override(SLA) | `SlaBacklogPanel` (única) | (PUT/DELETE) |
| Política SLA (regras/prazo/papel) | `sla-config` | SLA/política | `SlaConfigTable` (Gestão›SLA) | `SlaConfigTable` |
| Pastas em atraso (por caso, **PII**) | `sla-backlog/cases` | SLA-state | `SlaBacklogCasesDrawer` | — |
| Projeção mensal (ritmo/faixa-meta) | `journey-projection` | projeção | `ProjecaoTab` | — |
| Alertas (feed) | `alerts` (+ slaAlerts injetados) | alerta | `AlertsTab` | ack=localStorage¹ |

¹ ack só em `localStorage` — não sincroniza entre admins nem com backend. Dívida conhecida; fora do escopo desta fase (marcar `SourceTag` como "client-side").

## Ledger de de-duplicação (o que muda)

| Átomo | Hoje aparece em (N×) | Decisão |
|---|---|---|
| **Gini** | EquityTrend + KpiStrip + DistributionHealth + HealthScore (4×, 2 endpoints) | **1×** em `EquityCard` (fonte `equity-trend`). HealthScore era sintético (só gini+anomalia) → **funde no `EquityCard`** com rótulo honesto "Equidade". Corta as outras 3 exibições. |
| **Anomalia de equidade** | HealthScore badge + EquityTrend badge + alerta (3×) | **1×** no `EquityCard`; o alerta `gini_anomaly` fica (deep-linka ao card), não reexibe o valor. |
| **cap/floor por nível** | LevelCapFloor + LevelDetailDrawer + JourneyParams + OverridesEditor(level) + Projeção (5×, 3 endpoints) | Separar **3 átomos distintos e rotulados**: **configurado** (`monthly-defaults`, editado 1× em Gestão), **efetivo** (`conversion-dispersion`, read no cockpit), **override** (`overrides/level`, em OverridesEditor). Nunca misturar sem rótulo. |
| **SLOT não-materializado** | pending (Status) + preso>15min (Saúde) + em-voo/limbo (Overview) (3 nomes/endpoints) | **1 aba `Materialização`** com glossário único: hierarquia `reservado → pendente(NET) ⊃ preso>15min`; `limbo` = o conceito de domínio. Cada KPI com `SourceTag` do seu endpoint. |
| **override** | KPIs G1-4 + OverridesEditor + SlaBacklog + Bulk + Alertas-Travar (~8×) | **1 dono de exibição** = `OverridesEditor`. KPIs = resumo com `SourceTag`. **1 ação Travar** = `SlaBacklogPanel` (corta o botão Travar do AlertCard → deep-link). Os 3 write-paths convergem no mesmo endpoint, cada um rotulado pela `reason`. |
| **override expirando** | KPI G4 + lista G12 (mesmo hook `7`) | **1×**: a lista (`FirmInterventionActions`); o número vira o header da lista. |
| **quem está atrás** | LevelCapFloor + StarvationPanel + Projeção + LevelDrawer (4×, fontes concorrentes) | **1 fonte** = `conversion-dispersion` (déficit do engine). "Faminto" no cockpit; a lista reusa a MESMA fonte (sem cálculo concorrente no front). "Fora da meta" (projeção) é átomo DISTINTO (ritmo mensal) — rótulo separado. |
| **saturação por nível** | SaturationStrip + PendingSlotsCard + LevelCapFloor (3×) | **1 primitivo `LevelBar`**; saturação da esteira = `queue.summary` (1×); pending por nível = na aba Materialização. |
| **contagem de alertas** | banner + KPIs + chips de filtro + badge-tab (4×) | **1×**: o banner/badge-tab é a contagem; os chips de filtro **são** os counts (sem KPIs separados). |
| **rejeições** | DecisionsTab KPI + RejectionSummaryCard (2×) | **1×** em `DecisionsTab`. |
| **modo/receita** | DistributionMode + flags/preset + WRRFlagsCard (3×, polissêmico) | Desambiguar: **modo de distribuição** (`distribution/config`, Gestão›Op) ≠ **flags/receita do motor** (`flags`, Gestão›Config). `WRRFlagsCard` sai da Overview. |
| **"o que vai acontecer"** | Fila-projetada(servidor) + Oráculo + Dispersão-Simulado (3 motores) | **Real** (projeção do servidor) fica na `FilaTable` (toggle "projetada"). **Simulação** (`carolSim`) só no `OraculoTab`, rótulo SIMULAÇÃO. Corta o Dispersão-Simulado (= Oráculo comprimido). |
| **nível da firma** | engine `level` (Fila) vs contratual `firmLevel` (Dispersão/Oráculo) | **Fonte canônica = `firmLevel` (contratual)** — é a verdade de tier p/ floor/cap. Exibir engine-`level` só como diagnóstico quando divergir (badge "engine: X"). |

## Decisões difíceis (registradas)

1. **HealthScore** era 100% derivado de Gini+anomalia mas prometia "saúde da fila" (integração era Fase-2 nunca ligada). **Funde no `EquityCard`** honesto; não inventa saúde que não mede.
2. **Fila × Dispersão** = duas projeções da mesma `queue`. **Fundem** numa `FilaTable` com grupos de colunas alternáveis (ordem/elegibilidade · séries reais · meta/teto). Séries: `distribution-history-all` (uma fonte).
3. **Decisões (real S1..S7) × Oráculo (carolSim)** — mesmos verbos ("replay", "por que ganhou"), motores/fontes **diferentes**. **Rótulos inequívocos**: Decisões = REAL (persistido, pipeline S1..S7, replay via `decide()`); Oráculo = SIMULAÇÃO (modelo Equilíbrio, memória). Plugar o `ReplayButton` (replay real, hoje órfão) nas Decisões.
4. **3 abas órfãs** (Projeção/Status/Saúde, vivas sem menu): **Status+Saúde fundem** em `Materialização & Integração`; **Projeção** reintroduzida visível, reconciliada com o cockpit (déficit ≠ ritmo-mensal, rótulos claros).
5. **Constantes de incidente** hardcoded (`compensacao-memo-carol`/`2026-07-31` no Bulk; saturação=10 no SaturationStrip) → extrair p/ config/const nomeada.
6. **PII** (nome/CPF do cliente) só no `SlaBacklogCasesDrawer` — manter contido, mascarar CPF por padrão, revelar sob ação.

## IA atômica resultante (cada aba, 1 pergunta)

| Aba | Pergunta atômica | Átomos donos |
|---|---|---|
| **Visão Geral** | A distribuição está saudável e justa? | Gini/tendência/anomalia · saturação/nível · KPIs globais · déficit/nível (cockpit) · feed |
| **Fila & Distribuição** | Quem recebe o próximo e como está a distribuição real? | roster (ordem/elegibilidade) · séries reais · meta/teto · ratio |
| **Decisões** | Por que cada entrega foi para onde foi? (REAL) | decisão S1..S7 · elegibilidade · replay real · rejeições |
| **Oráculo** | Como a distribuição se desenrola passo-a-passo? (SIMULAÇÃO) | trace `carolSim` · fallback/rajada · inflight |
| **Materialização & Integração** | Os SLOTs viram caso? A integração está saudável? | pending/preso/limbo (glossário) · sync-log · latência |
| **Gestão** | Como eu mudo o motor? | overrides · modo · flags · cap/floor/dose (write) · SLA (política+backlog) |
| **Alertas** | O que precisa de atenção agora? | feed (deep-link à origem) |
| **Projeção** | Todo mundo está no ritmo mensal? | ritmo/faixa-meta por advogado |

**Invariante de verificação:** cada endpoint-dono aparece como fonte de exibição em **1** componente (grep). Réplicas usam `SourceTag`/link, não 2ª busca.

---

## Sub-modelo de Configuração (dose · overrides · flags · env)

A config não é um átomo plano — é um **espaço com 4 camadas de armazenamento e precedência**. A aba Gestão › Configuração
obedece a este modelo.

### As 4 camadas + a escada de precedência

| Camada | Onde | Papel |
|---|---|---|
| **Config declarativa** | `Journey.config.wrr` (JSONB) — `metagamify schema-v1.ts` | defaults por nível (cap/floor, dose, targetShare, filtros) |
| **Overrides** | tabela `WRROverride` | ajustes pontuais tier-1 (escopo × dimensão × período) |
| **Estado corrente** | Redis (`wrr:monthly:*`, `wrr:level_count:*`) | contadores civis BRT (não editável na UI) |
| **Toggles** | tabela `FeatureFlag` (todas **default-OFF**) | liga/desliga mecanismos |

**Resolução de limites** (`metagamify wrr/overrides/limit-resolver.ts` + `decide.ts` S1..S7):
```
participant override  >  badge override  >  level override  >  journeyDefault(config)  >  null
cap é DURO (pre-gate S2.5 + S5, com escape de nível)   >   floor é SOFT (S6, só reordena prioridade)
"cap vence floor" (clampFloorsToCaps) · override = tier-1 · min_ratio = fallback final · deficit subsume aging
```
Dose: **C1** (`dose_inflight_cap`) trava `pendingSlots ≥ doseMaxByLevel`; **C2** (`dose_inflight_credit`) soma `pendingSlots×conversion` ao progresso → piso efetivo. `doseMax` é derivável (`ceil(1/conv)`).

### Grafo flag→config→env (no-op-sem)

`stratified`/`floor_aware`→`levelTargetShare` · `participant_cap`/`floor`→`monthlyDefaults` · `C1`→`doseMaxByLevel` · `C2`→`conversionByLevel` · `measured_conversion`→`doseControl` · `exclude_forced`→net-real (desaturation ∨ rolling).

### Superfície MORTA/duplicada (marcar como legado na UI; NÃO remover — aposentadoria é backend, fora do escopo)

| Item | Status | Nota |
|---|---|---|
| `routing/level-router.ts`, `floor-urgency.ts`, `overrides/monthly-cap-filter.ts` | módulos legados sem consumidor vivo | `decide()` reimplementou internamente |
| `levelDefaults` (config) | **morto** (só `monthlyDefaults` é lido) | comentário do schema está invertido |
| `controlElementIds` (badges de controle) | legado redundante c/ overrides | |
| `use_workload_projection` | **flag fantasma** (motor nem lê; dual-write incondicional) | KG `C_WORKLOAD_PROJ` |
| `aging_selection`, `proportional_surplus` | **zumbis** (motor lê; sem toggle/UI — só SQL) | fora de `ALLOWED_FLAG_KEYS` |
| CAP em **4 fontes** | flag + `monthlyDefaults` + env `WRR_DAILY_CAP` + `override.dailyCap` | env-cap era inerte (KG `C_CALLSCAP_INERT`) |
| Roteamento em 2 modelos | deficit/flat (=Equilíbrio, prod) vs stratified/target_share (Legado) | escolher UM (Modo) |

### Env-vars (read-only na UI, `SourceTag`="env, deploy-time")

`WRR_DOSE_INFLIGHT_WINDOW_DAYS` (tune de C1/C2, default 14) · `WRR_DAILY_CAP_*` (cap diário — 4ª fonte de cap) · `METAGAMIFY_UNASSIGN_ON_TERMINAL` (gate puro, ON em prod → candidato a always-on) · `VITE_FEATURE_GAMIFICATION` (master de UI).

### Aba Configuração — 3 blocos vivos + a view que faltava

| Bloco | Átomos donos | Fonte |
|---|---|---|
| **Limites** | cap/floor unificado/nível + overrides tipados | `config/monthly-defaults` (write) · `overrides/*` |
| **Roteamento** | o **Modo** (Equilíbrio/Legado/Personalizado); 11 toggles atrás de "Avançado" | `flags` (SSOT do preset) |
| **Dose** | `conversionByLevel` + C1/C2 (doseMax oculto/derivado) | `config/dose-control` |
| **⭐ Config Efetiva** (a resultante, o átomo que faltava) | cap/floor/dose **RESOLVIDO** por nível/firma, camadas visíveis (default→override→clamp), cada uma `SourceTag` | **NOVO endpoint backend** autoritativo (expõe `limit-resolver.ts`) |

**Overrides como TIPO** (não CRUD plano): `escopo(nível|participante|badge) × dimensão(cap|floor) × período(D|S|M) × razão × expiração × tier`. Validação estruturada (Zod/RHF; hoje ZERO): `cap≥floor`, `cap=0`=trava. A UI mostra **onde o override entra na escada** (tier-1).

**Simplificação = SEGURA (front-only):** marcar legado/morto (não remover), agrupar por intenção (Modo colapsa 11 toggles), registrar os achados no KG p/ aposentadoria backend futura.
