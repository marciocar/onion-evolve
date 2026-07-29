---
title: "D5 Pricing Sheet decision-ready — a escada treino→cert→compliance→SOTA (2026-07)"
date: 2026-07-28
status: decision-ready
audience: maestro
decides: maestro (este brief NÃO decide os números — estrutura a escolha)
kg: docs/onion/graph/d5-pricing-2026-07.kg.yaml
related:
  - decisions.md
  - gtm-decision-brief-2026-07.md
  - 02-product/metrics.md
  - 02-product/strategy.md
---

# D5 Pricing Sheet — a escada de preço, decision-ready

> **D5 está `aberto`.** Este sheet consolida a pesquisa 2026 numa escada de 4 degraus
> (treino/consultoria → certificação → compliance-pack → assinatura SOTA), cada um com
> **comparáveis de mercado**, **hipótese de número/faixa**, **confiança**, **gate-status**
> (vendível-já vs sob-consulta) e **o que instrumentar**. Quem escolhe os números é o
> maestro — aqui está o mapa para escolher.

---

## Sumário executivo — o blend A+B

A pesquisa se organiza num **blend de duas naturezas de preço**, não numa tabela única:

- **A — FECHA JÁ (comparável direto, sem gate estrutural):** os dois primeiros degraus da
  sequência D4 — **treino/consultoria** (day-rate) e **certificação** (selo Onion). São
  serviços de alto-touch com âncora de mercado firme (consultor sênior de AI/dev-tooling;
  certificação de metodologia estilo SAFe SPC / EOS). O maestro pode fechar um **número
  hoje** — o que falta não é gate, é a escolha do ponto dentro da faixa + o primeiro
  engajamento real para calibrar.

- **B — FICA SOB-CONSULTA (faixa larga, número não-fechado):** os dois degraus superiores —
  **compliance-pack** (faixa citável $15k–$40k/ano, mas gated em D6 = zero comprador P4
  entrevistado + escopo do pack não-fechado) e **assinatura SOTA** (travada pelo **D2
  gated** — vende o mecanismo L1-L6 que ainda não existe/dogfoodado; cotar número aqui é
  `declarado≠verificado` = queima de moat). Apresentar como **faixa de ancoragem**, não
  preço a fechar.

**Trava-mestra transversal (diretriz D5):** ticket **premium ($129+) > pipoca ($5–10)** para
maestro solo; **vender selo/curadoria/serviço, não o texto**; **preço-por-outcome SÓ depois de
instrumentar** (ver `metrics.md` e a spec de instrumentação abaixo). Todo degrau respeita isso —
nenhum vira faixa-volume/pipoca.

**Alinhamento com D6 cindido:** PIPELINE = P3 (empresa/sistemas internos) alimenta os degraus
1-2 (treino/cert) e o compliance-pack no escopo reduzido; MENSAGEM = P4 (regulado) é o
posicionamento do compliance-pack — **sem prometer L1-L6** (só "workflows faseados +
auditabilidade estrutural", que existem/dogfoodados).

| # | Degrau (sequência D4) | Faixa proposta | Confiança | Gate |
|---|---|---|---|---|
| 1 | Treino/Consultoria (day-rate) | **$1.800–$3.000/dia** | média | **vendível-já** (A) |
| 2 | Certificação (selo Onion) | **~$1.250 inicial + ~$249/ano** | média | **vendível-já** p/ 1ª turma; renovação gated (A) |
| 3 | Compliance-pack (cunha P4) | **$15k–$40k/ano** (não-fechado) | média | **sob-consulta** (B — gated D6) |
| 4 | Assinatura SOTA | **$150–$400/mês** indiv. · **$250–$600 base + $60–$120/seat** empresa | baixa | **sob-consulta** (B — gated D2) |

---

## Degrau 1 — Treino/Consultoria (day-rate/engagement)

**Natureza:** blend-A, comparável direto de mercado. É a **receita mais próxima** (1ª da sequência
D4), sem dependência do SSOT L1-L6 nem do branding pendente do D3.

### Comparáveis 2026

| Referência | Preço | Fonte |
|---|---|---|
| AI consulting freelance day-rate (base ampla, EUA) | $600–$1.200/dia (freelancer); agências $1.500–$2.500/dia | [pertamapartners.com](https://www.pertamapartners.com/insights/ai-consultant-rates-2026) |
| AI consultant sênior/arquiteto (7+ anos) | $1.500–$3.000/dia | [rockstardeveloperuniversity.com](https://rockstardeveloperuniversity.com/ai-consulting-rates-statistics/) |
| Consultor software solo premium (ex-FAANG/PhD/nicho) — teto de mercado | $1.500–$3.000+/dia (elite $1.800–$4.000+) | [consultingheads.com](https://consultingheads.com/en/blog/freelance-consultant-costs-in-2026-the-ultimate-guide-to-daily-rates-and-roi) |
| Claude Code / agentic-coding consulting (CLAUDE.md, hooks, MCP, rollout) — **análogo direto** | $100–$300/h → ~$800–$2.400/dia; sprint 1-3 semanas | [ayautomate.com](https://www.ayautomate.com/blog/claude-code-consulting-services) |
| EOS Implementer (metodologia proprietária, sessão de 1 dia, marca própria) — **análogo estrutural** | $4.500–$6.600/sessão (~$650/h equiv.) | [shiftfocusos.com](https://www.shiftfocusos.com/post/eos-implementer-cost-binder-vs-enforcement) |

### Hipótese de número

**$1.800–$3.000/dia** como faixa de lançamento (engajamento avulso, ainda sem selo formal).
Ancorada no **teto do consultor sênior de AI/dev-tooling** ($1.500–$3.000) e **acima do piso de
setup Claude Code** ($800–$2.400) — porque o Onion não vende "configurar ferramenta", vende
**metodologia própria** (workflows faseados + 3 dimensões peer) com prêmio de fundador-solo/expert
(diretriz D5). O M1a prévio ($1.2–2k) fica no **chão** da faixa nova: os comparáveis 2026
sustentam mover o piso para **cima**, não para baixo.

**Horizonte:** uma vez empacotado com selo/certificação (degrau 2), o análogo EOS ($4.5–6.6k/sessão)
mostra que metodologias proprietárias certificadas sustentam **2–3x** esse teto — repricing futuro,
não o número de hoje.

- **Confiança:** média.
- **Gate-status:** **vendível-já** (blend-A). Pode fechar número hoje. Falta a decisão de preço do
  maestro dentro da faixa + o primeiro engajamento real.

### O que instrumentar
1. Rodar 2-3 propostas reais em pontos distintos da faixa ($1.8k vs $2.5k vs $3k/dia) → medir
   taxa de aceite e tempo-para-fechar (onde o mercado resiste).
2. Registrar se o comprador reage mais à narrativa **"metodologia própria + selo"** vs **"setup de
   ferramenta"** (testa se o prêmio D5 converte ou cai para a faixa genérica $800–1.200).
3. Medir **repeat/referral** pós-engajamento (sinal de valor não-capturado = subprecificado).
4. Com 3+ fechados, comparar contra o degrau 2 (certificação) para calibrar espaçamento.

---

## Degrau 2 — Certificação (selo Onion Certified Practitioner/Implementer)

**Natureza:** blend-A para a **primeira turma** (maestro certifica manualmente); renovação anual é gated.
Em NATUREZA parece **SAFe SPC** (certifica quem vai IMPLEMENTAR o framework em orgs cliente — coerente
com D6/P3), não cert de "eu sei a metodologia" tipo PSM.

### Comparáveis 2026

| Referência | Preço | Fonte |
|---|---|---|
| SAFe SPC — curso obrigatório 4 dias (inclui 1ª tentativa de exame) | $2.795–$3.856 curso + $795 exame avulso | [cprime.com](https://www.cprime.com/courses/implementing-safe-spc/) · [agilemania.com](https://agilemania.com/cost-of-spc-certification) |
| SAFe SPC — renovação ANUAL (obrigatória, inclui plataforma) | $995/ano | [scaledagile.com](https://support.scaledagile.com/en/articles/9791345-general-renewal-faqs) |
| Scrum Alliance CSM/CSPO — renovação bienal + 20 SEUs | $100/2anos | [staragile.com](https://staragile.com/info/agile-and-scrum/cspo-certification-renewal) |
| Scrum Alliance A-CSM (avançado) — renovação bienal + 30 SEUs | $175/2anos | [upskillist.com](https://www.upskillist.com/blog/scrum-master-certification-cost-breakdown-2025-update/) |
| Scrum.org PSM I / PSM II — exame único vitalício (sem renovação) | $200 / $250 | [scrum.org](https://www.scrum.org/support/how-much-are-scrumorg-professional-level-assessments) |
| ICAgile ICP — via provedor, sem renovação | $250–$2.500; renovação $0 | [icagile.com](https://www.icagile.com/membership/pricing) |
| PMI-ACP — exame + recert trienal via PDUs | ~$435–495 exame · $60–150/3anos renovação | [masterofproject.com](https://blog.masterofproject.com/pmi-acp-renewal-fee/) |
| EOS Implementer — não é exame; paga-se por SESSÃO (franquia à parte) | $4.500–$6.600/sessão | [guestcanpost.com](https://www.guestcanpost.com/how-much-does-an-eos-implementer-charge-generally/) |

### Hipótese de número

**~$1.250 de certificação inicial** (selo "Onion Certified Practitioner/Implementer") **+ ~$249/ano
de renovação** ("selo ativo").

Os comparáveis formam **dois clusters**: (a) cert de MASSA/baixo-touch (PSM/CSM/ICP/PMI-ACP: exame
$200–500, renovação $0–175/ano) — sustentada por VOLUME e infra de exame própria que o maestro solo
não tem (D1/D5 dizem não competir na faixa "pipoca"); e (b) cert de CONSULTOR/IMPLEMENTADOR/alto-touch
(SAFe SPC: curso ~$2.800–3.900 + $995/ano) — sustentada por plataforma/ecossistema contínuo que o
Onion também não tem hoje.

O **$1.250** fica no topo do range M1a ($795–1.500) e ancora no **"consultor", não no "exame de
massa"** — justificável por ser CURADO/gated (poucas vagas, não plataforma automatizada) e empacotar
**treino+avaliação+selo+listagem**, não um exame isolado.

**Renovação $249/ano (~20% do inicial):** NÃO é taxa-pela-taxa (isso repete o erro
"cerimônia≠substância" da memória do maestro) — precisa de **entrega real por trás**: (1) acesso à
versão atualizada do framework/KB; (2) permanência no diretório público "Onion Certified" (prova
social = o produto do selo); (3) elegibilidade a desconto no compliance-pack (degrau 3). Ratio mais
barato que SAFe (~30%, mas eles têm plataforma robusta) e mais caro que Scrum Alliance
(cerimonial demais p/ D5).

- **Confiança:** média.
- **Gate-status:** **vendível-já** para a 1ª turma (cerimônia mínima viável: entrevista + case + selo
  PDF/LinkedIn). **GATED para escalar** e para cobrar a **renovação com integridade**: falta (1) o
  **rubric** do que "ser Onion Certified" exige (avalia o quê, não só "pagou"); (2) o **diretório
  público** (sem ele a renovação não tem produto tangível → vira taxa-pela-taxa); (3) decidir se
  certificação **pressupõe treino prévio** (encadeamento D4: treino→cert) ou é standalone.

### O que instrumentar
1. Nos primeiros 3-5 certificados: taxa de conversão **treino→certificação** (valida/refuta o
   encadeamento D4).
2. Se compradores **usam o selo** em proposta comercial própria (prova valor de mercado, não só interno).
3. Taxa de **renovação no ano 2 sem diretório** ainda: renovam mesmo assim → selo vale >$249/ano
   (espaço p/ subir); não renovam → falta a entrega tangível antes de insistir na taxa.
4. Com >10-15 certificados, instrumentar CAC/LTV real → migra de hipótese p/ preço-por-outcome.

---

## Degrau 3 — Compliance-pack (cunha P4/regulado)

**Natureza:** blend-B, **sob-consulta**. É a cunha de MENSAGEM do D6 (P4/regulado), mas gated: zero
comprador P4 entrevistado + escopo do pack não-fechado. **Guardrail duro (D6/D2):** a mensagem NÃO
pode prometer o mecanismo L1-L6 (federação segura de dado regulado, gated) — hoje só vende workflows
faseados + auditabilidade estrutural (spec-as-code auditável), que existem/dogfoodados.

### Comparáveis 2026

| Referência | Preço | Fonte |
|---|---|---|
| GRC platform enterprise (GRC/TPRM/privacy/audit, Gartner IRM) | $50k–$500k/ano (típ. $25k–$150k p/ 3-5 módulos) | [securityboulevard.com](https://securityboulevard.com/2026/05/grc-software-pricing-what-it-actually-costs-in-2026/) |
| GRC software geral (entrada→legado) | $10k–$100k/ano (legado $100k–$500k+ multi-ano) | [v-comply.com](https://www.v-comply.com/blog/grc-software-pricing/) |
| Vanta (SOC2/ISO27001), contratos 2026 | $7.5k–$56.8k/ano, mediana $20k; SOC2-só ~$10k; mid-market ~$30–50k | [costbench.com](https://costbench.com/software/compliance-management/vanta/) |
| Vanta 50-200 FTE, 1 framework | $15k–$35k/ano | [sprinto.com](https://sprinto.com/blog/vanta-pricing/) |
| Drata (compliance automation) | $7.5k–$100k+/ano; Foundation ~$15k; startups <50 FTE $12–25k | [costbench.com](https://costbench.com/software/compliance-management/drata/) |
| Enterprise compliance full-stack (impl.+integrações+per-seat) | frequentemente >€250k/ano (serviços 20-40% da licença) | [getmonetizely.com](https://www.getmonetizely.com/articles/how-are-grc-risk-amp-compliance-platforms-priced-for-enterprises-a-procurement-guide) |

### Hipótese de número

**$15k–$40k/ano por engajamento** (era hipótese pré-M1a, confirmada pelos comparáveis 2026): fica no
**terço inferior** do mercado de compliance-automation — abaixo/na mediana Vanta ($20k) até o teto
Drata-Foundation/mid-market ($25–50k), muito abaixo de GRC enterprise puro ($50–500k).

**Posicionamento:** o Onion NÃO entrega monitoramento contínuo de controles/coleta automatizada de
evidência (o núcleo caro-de-manter de Vanta/Drata) — entrega **compliance-as-code** (spec-as-code
auditável, workflows faseados, curadoria de conformidade estrutural). Mais barato de produzir (sem
infra de integrações 24/7) mas ainda exige tempo-especialista/curadoria. **Não vira pipoca nem
compete de igual p/ igual com GRC full-stack** — posiciona como **complemento/pré-requisito** ao GRC
(ou substituto para times menores sem necessidade de monitoramento contínuo).

- **Confiança:** média.
- **Gate-status:** **sob-consulta/gated.** Por quê: (1) nenhum comprador P4 entrevistado (D6 registra
  "1-2 entrevistas P4" como pendência); (2) escopo do "pack" não-fechado (frameworks, nº artefatos,
  acompanhamento de auditoria); (3) guardrail L1-L6 — o preço tem que ancorar no **escopo reduzido**
  (o que já existe), não no GRC-completo dos comparáveis; (4) sem instância entregue, não há custo
  real de produção para calibrar margem. **Não fechar número** — apresentar a faixa como ponto de
  partida de negociação caso a caso.

### O que instrumentar
1. Rodar as 1-2 **entrevistas P4** (D6) ancorando willingness-to-pay nos comparáveis (mostrar
   $15k–$40k e observar reação — não perguntar aberto).
2. Definir e testar **escopo fechado do pack v1** (ex.: 1 framework, N artefatos spec-as-code + 1
   rodada de curadoria) e medir **horas reais** de entrega → custo-base/margem.
3. Rodar 2-3 pilotos a preço fixo dentro da faixa → taxa de fechamento por ponto de preço.
4. Instrumentar **outcome real** pós-entrega (tempo-até-passar-auditoria, redução de findings) →
   só migra p/ preço-por-outcome depois.
5. **Revisitar a faixa quando D2/L1-L6 destravar** — o pack pode subir de tier ao incorporar
   federação segura como diferencial real (não prometido antecipadamente).

---

## Degrau 4 — Assinatura SOTA (topo da escada, amarrada ao D2 gated)

**Natureza:** blend-B, **sob-consulta**, a mais travada. A assinatura SOTA só faz sentido como
categoria de preço **própria** (acima do compliance-pack) quando o mecanismo que ela vende — **L1-L6**
(classificação-por-inferência + gate-por-propósito + ε-ledger) — está **construído E dogfoodado**, com
**threat model N-tenant** verificado (hoje só provado N=1 pessoal). Antes disso, cobrar venderia
garantia não-construída (`declarado≠verificado` = queima de moat, guardrail explícito do D2). A faixa
abaixo é **ancoragem, não preço a fechar**.

### Comparáveis 2026

| Referência | Preço | Fonte |
|---|---|---|
| Claude Code Max (uso pro diário, Opus, 20x Pro) | $100–$200/mês (indivíduo) | claude.com/pricing (síntese SSD Nodes/Verdent 2026) |
| Cursor Teams — seat Standard / Premium | $40 / $120/seat/mês | [cursor.com](https://cursor.com/blog/teams-pricing-june-2026) |
| GitHub Copilot Enterprise (seat + AI Credits) | $39/user/mês (+ GH Enterprise Cloud à parte) | [github.blog](https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/) |
| Devin (Cognition) — Teams / Max | Teams $80 base + $40/seat · Max $200/mês | [pensero.ai](https://pensero.ai/blog/devin-pricing) |

### Hipótese de número (só para quando D2 destravar)

**$150–$400/mês** por assinatura (indivíduo/maestro solo) e **$250–$600/mês base + $60–$120/seat**
para tier empresa/hub — **acima** do teto das ferramentas de codificação genéricas (Cursor $40–120,
Copilot $39, Claude Code Max $100–200) e alinhado à faixa alta de agentes autônomos (Devin Max $200,
Teams $80+$40/seat).

**Lógica:** os comparáveis vendem **assistência de código** (execução), não **curadoria+governança de
contexto federado** entre times/orgs (o que a SOTA prometeria via D2). É categoria adjacente a
compliance/governança (mais perto de GitHub Enterprise + Copilot Enterprise combinados, ou de
governança de dados corporativos), não um assistente de código a mais — por isso o ticket premium
($129+) é **piso, não teto**. A faixa deveria testar contra o compliance-pack ($15–40k/ano ÷ 12 ≈
$1.250–$3.300/mês) como **âncora superior alternativa** se o comprador for P4/empresa (não indivíduo).

- **Confiança:** baixa.
- **Gate-status:** **sob-consulta/gated pelo D2.** Enquanto gated, número é ancoragem de mercado, não
  pricing por valor/outcome.

### O que instrumentar
1. Fechar o **SSOT L1-L6 + dogfood + threat model N-tenant** (gatilho literal do D2) **antes** de
   cotar qualquer número a cliente.
2. Medir (via metrics.md) quanto do "aha" de federação/curadoria os adotantes hub atuais já pagariam.
3. Rodar 1-2 **entrevistas P4** (D6) → saber se o comprador é indivíduo (ancorar em Claude Code
   Max/Devin Max, ~$100–200) ou empresa (ancorar em compliance-pack/Copilot Enterprise, ~$1k+/mês).
4. Só migrar de "faixa por comparável" p/ "preço por outcome" quando o flywheel de dado gerar métrica
   de valor mensurável — precondição explícita da diretriz D5.

---

## A ESCADA — progressão de preço coerente

A sequência D4 forma uma escada onde **cada degrau depende do anterior** (ancoragem coerente, sem
colisão de percepção de valor):

```
                                          Assinatura SOTA          $150–400/mês indiv.
                                          (D2 gated)          $250–600 base + $60–120/seat empresa
                                             ▲ DEPENDS_ON
                                             │  (compliance-pack ÷12 ≈ $1.25–3.3k/mês = âncora superior)
                                   Compliance-pack             $15k–40k/ano
                                   (D6 gated, P4)                 (não-fechado)
                                             ▲ DEPENDS_ON
                                             │  (cert = pré-req de credibilidade p/ vender o pack)
                          Certificação                     ~$1.250 inicial + ~$249/ano
                          (selo Onion)
                                             ▲ DEPENDS_ON
                                             │  (treino = pré-req; encadeamento treino→cert a validar)
        Treino/Consultoria                            $1.800–3.000/dia
        (vendível-já)
```

**Coerência de espaçamento verificada:**
- **Treino→Cert:** dia-avulso ($1.8–3k) e certificação inicial (~$1.25k) estão em ordens de grandeza
  próximas mas com propósitos distintos (execução vs credencial) — instrumentar (degrau 1, item 4)
  para confirmar que não colidem em percepção de valor.
- **Cert→Compliance-pack:** salto grande ($1.25k → $15–40k/ano) é **intencional** — muda de venda a
  indivíduo para venda a organização (P3/P4), com escopo e comprador diferentes.
- **Compliance-pack→SOTA:** a assinatura mensal SOTA ancora sua faixa-empresa **contra** o
  compliance-pack anualizado ($15–40k ÷ 12), garantindo que a recorrência não canibalize o pack.
- **Horizonte de repricing:** quando cert amadurece (selo formal + diretório), o análogo EOS
  ($4.5–6.6k/sessão) puxa o **degrau 1** para cima 2–3x; quando D2 destrava, o **degrau 3** sobe de
  tier. A escada de hoje é o **piso**, não o teto.

---

## SPEC DE INSTRUMENTAÇÃO — o KPI "valor-por-adotante"

O pivô que destrava preço-por-outcome (metrics.md, `[a instrumentar]`). **Não é UM número** — é a
agregação **por adotante** (via `members.yaml` da federação) de 3-4 sinais que **já têm mecanismo host
no core** — cada um lido/persistido **sem construir motor novo**.

### Barato-primeiro (roda hoje, custo zero, síncrono)

**Ciclos faseados concluídos vs abandonados** — grep/awk sobre `.claude/sessions/*/STATE.md` +
`.claude/sessions/archived/*/STATE.md`, no molde de `.claude/validation/inventory.sh`. Custo zero:
nenhuma chamada de LLM, nenhum schema novo (o campo `status`/`phase`/`last_checkpoint`/`blocked_by` já
existe em TODO STATE.md canônico). Sessão com `status != done` e sem checkpoint há >N dias = abandonada.
`done/total` por período = **taxa bruta de conclusão de ciclo por adotante** — o sinal mais barato de
todos, antes de qualquer coisa que precise orquestração ou janela de baseline.

### As 4 medições (todas reusam o core, ordenadas por custo)

| Sinal | Como medir | Base que já existe |
|---|---|---|
| **Ciclos concluídos vs abandonados** | Scanner bash (molde `inventory.sh`) varre `STATE.md`, extrai `status`/`phase`/`last_checkpoint`/`blocked_by`. `done/total` por período. | Todo STATE.md já carrega o schema — zero mudança de formato, só leitura |
| **Frescor de contexto (SSOT viva vs stale)** | Rodar `/meta:context-freshness` periodicamente por adotante (gatilho: hook de sessão ou acoplado ao `/meta:co-evolve`) e persistir a saída (veredito CURRENT/STALE/HISTORICAL) como JSONL append-only. Série temporal = trend de frescor. | `/meta:context-freshness` — fan-out pronto, veredito é a saída padrão |
| **Retrabalho evitado / velocidade** | Cycle-time por fase = `git log --diff-filter=A --format=%aI -- STATE.md` até o commit em que `status` vira done. Retrabalho = entradas em `done_log` que reabrem fase fechada. Precisa **baseline (4-8 semanas)**. | `done_log` timestamped + histórico git dos arquivos de sessão — dado no repo, falta o agregador |
| **Saúde de federação (proxy de engajamento vivo)** | `/meta:federation-status` cruza members.yaml + CHANGELOG + CI por membro — filtro "adotante ativo vs dormente" **antes** de interpretar os outros 3 (só faz sentido p/ quem opera). | `/meta:federation-status` — read-only, roda hoje, zero código novo |

### O que destrava

Sem série temporal desses sinais por adotante, o Onion **não sai do preço-por-camada fixo** para
preço-por-outcome — a barreira que o BCG 2025 nomeia ("exige telemetria que hoje não existe",
strategy.md). Com as 4 medições agregadas ao longo de semanas:

- **(a)** viram a EVIDÊNCIA numérica do "aha" do onion-mini (frescor sobe, ciclos fecham = prova, não
  promessa) → o funil mini→pago fica **auditável**;
- **(b)** viram o GATILHO de expansão hub (adotante com alta conclusão + federação saudável = candidato
  natural à "chegada do multi" que dispara o upsell land-and-expand);
- **(c)** viram a BASE de precificação por resultado dos degraus de serviço (cobrar certificação /
  compliance-pack por "N ciclos fechados sem drift de contexto", não por assento/tempo);
- **(d)** sem esse dado, "valor por adotante" continua `[hipótese]` para sempre — nenhuma decisão de
  preço-por-outcome pode ser tomada com honestidade (`declarado≠verificado`).

---

## Decisões que ficam pro maestro

Este sheet **não decide os números** — estrutura a escolha. Ficam para o maestro:

1. **Degrau 1 (treino/consultoria):** fechar o número/ponto dentro de **$1.800–$3.000/dia** — ou
   autorizar testar 2-3 pontos em propostas reais antes de fixar.
2. **Degrau 2 (certificação):** confirmar **~$1.250 inicial + ~$249/ano** — e decidir se a certificação
   **pressupõe treino prévio** (encadeamento treino→cert) ou é standalone. Autorizar (ou não) cobrar
   renovação **antes** de existir o diretório público.
3. **Degrau 3 (compliance-pack):** manter **$15k–$40k/ano como faixa de negociação** (não-fechado) até
   as entrevistas P4 + escopo do pack v1. Definir o **escopo fechado** do pack (frameworks, nº de
   artefatos, acompanhamento de auditoria).
4. **Degrau 4 (assinatura SOTA):** ratificar que **nenhum número é cotado a cliente antes do D2
   destravar** (L1-L6 dogfoodado + threat model N-tenant). A faixa $150–400/$250–600+seat é ancoragem
   interna, não oferta.
5. **Instrumentação:** autorizar a construção do **agregador barato-primeiro** (scanner de STATE.md) +
   persistência JSONL do context-freshness — é a precondição para qualquer degrau migrar de preço-por-
   camada para **preço-por-outcome**.
6. **Gatilho de repricing:** nomear a métrica/marco que dispara subir o degrau 1 (via selo/EOS) e o
   degrau 3 (via D2) — hoje ambos declarados como "piso, não teto" sem gatilho concreto.
