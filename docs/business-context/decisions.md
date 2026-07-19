# 🗂️ Registro de Decisões Estratégicas

**Última Atualização:** 2026-07-19

> Mecanismo de rastreio das decisões de negócio em aberto. Cada card é uma pergunta que você resolve **escolhendo** uma opção ou **descrevendo** livremente. Versionado no git → cada sessão avança daqui, não recomeça. Spec-as-code aplicado às decisões de negócio (dogfood do próprio Onion).
>
> **Status:** `aberto` (a decidir) · `hipótese` (inclinação registrada, não fechada) · `ratificado` (decidido, com data).
> **Como usar:** numa sessão, `/catch-up` aponta aqui; você diz "avançar D_" e escolhe/descreve; eu atualizo o card e propago para `strategy.md`/`personas.md` etc.

---

## D1 — Postura comercial

**Pergunta:** o Onion vira comercial? Como reconciliar "não é produto, não distribuído" com "fazer dinheiro / vender como ouro"?

- ( ) Pivot explícito para comercial
- (•) **Camadas: mini-funil aberto + captura adjacente (serviço/certificação/curadoria)** ← inclinação
- ( ) Exploratório (registrar opção, não decidir)
- ( ) Não-comercial, foco em sustentação

**Status:** `hipótese` · **Lean:** camadas (BMAD/Wardley + selo SAFe/EOS). **Trava:** decidir o modelo **antes** de abrir publicamente (guardrail anti-relicenciamento). **Refina:** falta escolher gatilho de "abrir".

## D7 — Semântica de tiers (hub / standalone / consumer) `[ratificado 2026-07-19]`

**Pergunta:** o que separa os tiers de adoção, e o que cada um recebe/paga?

- (•) **hub = adoção de EMPRESA (federação como camada de time); standalone = dev solo com a ferramenta COMPLETA, mas SEM federação; consumer = adota um hub (bundle a definir); um standalone pode evoluir p/ hub (chega o multi) OU virar consumer** ← ratificado

**Status:** `ratificado` (2026-07-19) · **Base:** pesquisa orquestrada [`onion-tier-matrix-2026-07`](../evolution/research/onion-tier-matrix-2026-07/SYNTHESIS.md) — convergência motor+doutrina+mercado (Anthropic separa na MESMA junta: capability individual plena vs marketplace/governança gated a Team/Enterprise; land-and-expand). **Fronteira de venda = a federação** (o "texto"/framework grátis no standalone; a rede é o upsell/moat no hub). **Codificado:** eixo `work_tools` em `roles.yaml` (PR #443). **Propagado:** `strategy.md`/`journey.md`/`personas.md`/`sales-process.md`. **Destravado (2026-07-19):** D2 ratificou a **direção** (c local-first+destilado) → vender federação como upsell limpo está desbloqueado em **arquitetura**; a **ativação** do flywheel de dado segue `gated` (ver D2).

## D2 — Moeda-dado / federação de contexto `[ratificado 2026-07-19 — DIREÇÃO; ATIVAÇÃO gated]`

**Pergunta:** o modelo usa "compromisso de dado" (adotantes contribuem contexto → flywheel de federação)?

> **O card fundia duas decisões** — DIREÇÃO (arquitetura) e ATIVAÇÃO (ligar o flywheel). Ratificadas em separado.

**DIREÇÃO (arquitetura) — RATIFICADA:**
- ( ) Sim, sem restrição forte agora — ❌ **ELIMINADA** (regride a postura fail-safe já ratificada + colide com EU AI Act/EDPB no exato pilar que o Onion vende, compliance-peer)
- ( ) É hipótese — adiar — ⤴ superada (só empurrava o bloqueio de D7)
- (•) **Sim, mas LOCAL-FIRST + DESTILADO** ← **ratificado (direção)**
- ( ) Não por ora — só moeda-financeira — 🛟 retido como **REDE** (fallback pré-comprometido se o custo do mecanismo inviabilizar; **nunca (a)**)

**ATIVAÇÃO — `gated`.** Ratificar a direção **≠** ligar o flywheel. **Gatilho:** o SSOT único das 6 camadas
(classificação-por-inferência + gate-por-propósito + ε-ledger) **construído + dogfoodado**; o threat model
**N-tenant** verificado com lente própria (⚠️ P5 foi provada em **N=1 pessoal** — a extrapolação p/ N-tenant é
**a verificar**, não citar P5 como bloqueio direto); abertas de ε / purpose-binding / taxonomia L3 resolvidas.

**Mecânica (c):** o contexto de negócio **bruto fica soberano/local** (git como SoT); só **predicado destilado/
agregado sobe**; classificação por **PIOR CASO DE INFERÊNCIA** (P4 — herda o que permite deduzir, não o que
afirma); gates de saída **L1-L6** (05-mitigacao-inferencia). Estruturalmente = a doutrina **RFC-0004** (single-source
p/ identidade/contratos; federa-se só a derivação/comunicação) aplicada a um domínio novo.

**Guardrails:** **nunca** anunciar (c) como garantia operacional antes do mecanismo existir + dogfoodado
(declarado≠verificado — venderia garantia não-construída = **queima o moat**); registrar o **resíduo** (~7-8%,
nunca zero — LLM reconstrói atributos mesmo do destilado); **nunca relicenciar** depois de abrir.

**Status:** `ratificado` (direção) · `gated` (ativação) · **Base:** pesquisa [`onion-d2-data-currency-2026-07`](../evolution/research/onion-d2-data-currency-2026-07/SYNTHESIS.md). **Destrava:** D7 (federação como upsell limpo).

## D3 — Onion Pessoal / leigo final + mentoria

**Pergunta:** perseguir a linha consumidor (Company Brain N=1) e mentoria (Evolução + Pessoal)?

- (•) **Registrado como hipótese de maior incerteza** ← escolhido
- Requisitos: **super storytelling + branding + posicionamento** (muda comprador e promessa).

**Status:** `aberto` · **Depende de:** acionar `@branding-positioning-specialist` + `@storytelling-business-specialist` quando amadurecer. Ligado a `discuss/onion-pessoal-marcio` e `discuss/onion-mobile-app`. **Não** comprometer como pilar sem esse trabalho.

## D4 — Priorização das receitas

**Pergunta:** qual sequência de camadas pagas perseguir?

- (•) **Formalizar treino/consultoria → certificação → compliance-pack → assinatura SOTA** ← inclinação
- ( ) Compliance-pack primeiro (cunha de maior valor, ciclo longo)
- ( ) Perseguir em paralelo (risco "todo e o nada")

**Status:** `hipótese` · **Lean:** sequencial (receita mais próxima primeiro). **Refina:** definir marco que dispara passar de uma pra próxima.

## D5 — Preço / ticket

**Pergunta:** como precificar cada camada?

**Status:** `aberto` · **Diretriz da pesquisa:** ticket premium ($129+) > pipoca ($5–10) para maestro solo; vender selo/curadoria/serviço, não o texto; preço por outcome só depois de instrumentar (ver `metrics.md`). **Falta:** hipótese de número por camada.

## D6 — Comprador primário

**Pergunta:** quem é o comprador-alvo primário?

- Candidatos: empresas c/ sistemas internos (P3) · times regulados (P4) · dev solo (P5) · leigo/pessoal (P6).

**Status:** `aberto` (a validar) · **Sinais:** P4 (regulado) é a cunha de maior valor + whitespace; P3 é o volume org mais provável. **Falta:** escolher 1 primário para focar mensagem/GTM.

---

## Decisões já ratificadas (fora deste registro)

Vivem no `CLAUDE.md` / `docs/analysis/onion-review-2026-05.md` (identidade canônica 2026-05-18): Claude Code-only, 3 dimensões peer, workflows faseados invariantes, `.onion/` e v4.0 FASES 5-9 abandonados. Este registro **não** as reabre — trata só do eixo comercial/GTM novo.
