# 🗂️ Registro de Decisões Estratégicas

**Última Atualização:** 2026-07-29

> Mecanismo de rastreio das decisões de negócio em aberto. Cada card é uma pergunta que você resolve **escolhendo** uma opção ou **descrevendo** livremente. Versionado no git → cada sessão avança daqui, não recomeça. Spec-as-code aplicado às decisões de negócio (dogfood do próprio Onion).
>
> **Status:** `aberto` (a decidir) · `hipótese` (inclinação registrada, não fechada) · `ratificado` (decidido, com data).
> **Como usar:** numa sessão, `/catch-up` aponta aqui; você diz "avançar D_" e escolhe/descreve; eu atualizo o card e propago para `strategy.md`/`personas.md` etc.

---

## D1 — Postura comercial `[ratificado 2026-07-25]`

**Pergunta:** o Onion vira comercial? Como reconciliar "não é produto, não distribuído" com "fazer dinheiro / vender como ouro"?

- ( ) Pivot explícito para comercial
- (•) **A: Camadas — mini-funil aberto + captura adjacente (serviço/certificação/curadoria)** ← ratificado
- ( ) Exploratório (registrar opção, não decidir)
- ( ) Não-comercial, foco em sustentação

**Status:** `ratificado` (2026-07-25) = **A (camadas)**. Sob D6 cindido, a postura em camadas deixa de ser hipótese — o modelo está fechado (BMAD/Wardley + selo SAFe/EOS). **Trava mantida:** decidir/abrir só com o guardrail anti-relicenciamento ativo. **Refina (não bloqueia o modelo):** falta o **gatilho de "abrir"** — é operacional, não de modelo. **Base:** brief [`gtm-decision-brief-2026-07`](gtm-decision-brief-2026-07.md).

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

## D3 — Onion Pessoal / leigo final + mentoria `[ratificado 2026-07-25 — DESACOPLADO]`

**Pergunta:** perseguir a linha consumidor (Company Brain N=1) e mentoria (Evolução + Pessoal)?

- (•) **C: DESACOPLAR — mentoria/curadoria avança JÁ (fatura; alinha com P3/P4 e D4); app-consumer (leigo/pessoal) fica `gated`** ← ratificado
- Requisitos do trilho consumer: **super storytelling + branding + posicionamento** (muda comprador e promessa) — só quando amadurecer.

**Status:** `ratificado` (2026-07-25) = **desacoplar**. A mentoria não espera o app-consumer: avança já como captura adjacente (D1=A). O trilho **consumer/leigo** (Company Brain N=1, app mobile) segue `gated` — não comprometer como pilar sem branding/storytelling. Ligado a `discuss/onion-pessoal-marcio` e `discuss/onion-mobile-app`. **Base:** brief [`gtm-decision-brief-2026-07`](gtm-decision-brief-2026-07.md).

## D4 — Priorização das receitas

**Pergunta:** qual sequência de camadas pagas perseguir?

- (•) **Formalizar treino/consultoria → certificação → compliance-pack → assinatura SOTA** ← inclinação
- ( ) Compliance-pack primeiro (cunha de maior valor, ciclo longo)
- ( ) Perseguir em paralelo (risco "todo e o nada")

**Status:** `hipótese` · **Lean:** sequencial (receita mais próxima primeiro). **Refina:** definir marco que dispara passar de uma pra próxima.

## D5 — Preço / ticket `[parcialmente ratificado 2026-07-29]`

**Pergunta:** como precificar cada camada?

**Status:** `parcialmente ratificado` (2026-07-29). Escada de 4 degraus preparada no [`d5-pricing-brief-2026-07`](d5-pricing-brief-2026-07.md) (comparáveis 2026, KG [`d5-pricing-2026-07`](../onion/graph/d5-pricing-2026-07.kg.yaml)). **Decisões do maestro:**

- **Degrau 1 — treino/consultoria:** faixa **$1.800–3.000/dia**; **NÃO fixar ainda** — testar 2-3 pontos em propostas P3/P4 reais e ler a conversão antes de cravar (preço-por-descoberta, não por palpite).
- **Degrau 2 — certificação:** **só o inicial ~$1.250** por ora; a renovação (~$249/ano) fica **gated no diretório público de certificados existir** — não cobrar recorrência por um valor ainda não-construído (`declarado≠verificado`).
- **Degrau 3 — compliance-pack:** **$15–40k/ano sob-consulta** (faixa de negociação, não fechada) — gated: zero P4 entrevistado + escopo do pack v1 a definir.
- **Degrau 4 — assinatura SOTA:** faixa interna $150–400/mês · $250–600+seat, **NÃO cotável a cliente** até o D2 destravar (L1-L6 dogfoodado); cotar antes = queima de moat.
- **Instrumentação:** **AUTORIZADA** — construir o agregador barato-primeiro (scanner de `STATE.md` custo-zero + persistência JSONL do `context-freshness`). É a precondição de mover qualquer degrau de preço-por-camada para preço-por-outcome.

**Falta (não bloqueia):** o teste de campo do degrau 1; entrevistas P4 p/ fechar o degrau 3; o **gatilho de repricing** (o marco que sobe cada degrau — a escada de hoje é piso, não teto).

## D6 — Comprador primário `[ratificado 2026-07-25 — CINDIDO mensagem/pipeline]`

**Pergunta:** quem é o comprador-alvo primário?

- Candidatos: empresas c/ sistemas internos (P3) · times regulados (P4) · dev solo (P5) · leigo/pessoal (P6).
- (•) **CINDIR: MENSAGEM = P4 (regulado) · PIPELINE = P3 (empresa/sistemas internos)** ← ratificado

**Status:** `ratificado` (2026-07-25 — a decisão-raiz). O card fundia duas perguntas; o maestro cindiu. **MENSAGEM/posicionamento = P4** (único whitespace confirmado — compliance-peer; dá categoria própria em vez de competir na faixa genérica). **PIPELINE/receita primeiro = P3** (mais líquido, ciclo curto, **não** depende de L1-L6). **Guardrail duro:** a mensagem P4 vai ao ar **sem prometer** o mecanismo L1-L6 (gated) — promessa hoje = "workflows faseados + auditabilidade estrutural" (existe/dogfoodado), **não** "federação segura de dado regulado" (não construído) = `declarado≠verificado`/queima de moat. **P5** = MOAT/advocacy (D7), não primário; **P6** fora (pré-req de branding). **Base:** brief [`gtm-decision-brief-2026-07`](gtm-decision-brief-2026-07.md) + KG [`gtm-decisions-2026-07`](../onion/graph/gtm-decisions-2026-07.kg.yaml). **Falta (não bloqueia):** 1-2 entrevistas P4 + instrumentar conversão do "aha" por persona.

---

## Decisões já ratificadas (fora deste registro)

Vivem no `CLAUDE.md` / `docs/analysis/onion-review-2026-05.md` (identidade canônica 2026-05-18): Claude Code-only, 3 dimensões peer, workflows faseados invariantes, `.onion/` e v4.0 FASES 5-9 abandonados. Este registro **não** as reabre — trata só do eixo comercial/GTM novo.
