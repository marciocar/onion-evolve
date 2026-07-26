---
title: "Brief GTM decision-ready — D6→D1/D5/D3 (2026-07)"
date: 2026-07-25
status: decision-ready
audience: maestro
decides: maestro (este brief NÃO decide — estrutura para decidir)
kg: docs/onion/graph/gtm-decisions-2026-07.kg.yaml
related:
  - decisions.md
  - 02-product/strategy.md
  - 04-operations/sales-process.md
---

# Brief GTM decision-ready — a decisão-raiz é **D6** (comprador)

> Quatro decisões GTM (D1 postura · D3 consumer/mentoria · D5 preço · D6 comprador) chegaram maduras.
> Elas **não são paralelas**: **D6 (comprador-alvo) é a raiz** — ela calibra o vocabulário e o risco de
> D1, D5 e D3. Por isso este brief é **D6-primeiro**: resolve-se D6 e, para cada escolha plausível dela,
> lê-se o que D1/D5/D3 **se tornam**. Quem decide é o maestro; aqui está o mapa para decidir.

---

## Sumário executivo

**Recomendação central (do analista):** cindir **D6** em duas perguntas que o card hoje funde —
**a quem falar (MENSAGEM/posicionamento)** e **a quem vender primeiro (PIPELINE/receita)** — porque o
próprio corpus já as responde de formas diferentes sem reconciliar:

- **MENSAGEM = P4 (regulado/enterprise).** É o **único diferencial com whitespace confirmado** (10+ buscas:
  nenhum concorrente SDD trata compliance como dimensão peer). Dá ao Onion **categoria própria** em vez de
  competir de frente com Agent OS/BMAD/SuperClaude na faixa genérica de P3. **Condição dura, não cosmética:**
  a mensagem P4 só vai ao ar **sem prometer** o mecanismo de mitigação de inferência (L1-L6) que está `gated`.
  A promessa de hoje é "**workflows faseados + auditabilidade estrutural**" (existe, dogfoodado) — **não**
  "privacidade/federação segura de dado regulado" (ainda não construído). Vender a segunda coisa antes de
  existir é o risco `declarado≠verificado` que o `strategy.md` já nomeia como **queima de moat**.
- **PIPELINE = P3 (empresa/sistemas internos).** Caminho mais **líquido e de ciclo mais curto**; treino/
  consultoria (o degrau 1 de D4) pode nascer de leads P3 **ou** P4 sem esperar o ciclo longo de procurement
  regulado. Faturar não exige que P4 esteja provado.

**P5 (dev solo) não é candidato a primário** — D7 (ratificado) já decidiu que P5 é **MOAT/advocacy**, não meta
de receita. **P6 (leigo)** está fora, travado a um pré-requisito de branding que D6 não resolve.

**Encadeamento das outras três, sob D6 = "MENSAGEM P4 / PIPELINE P3":**

| Decisão | Recomendação | Status pós-brief |
|---|---|---|
| **D1** postura | **Ratificar A (camadas/mini-funil + captura adjacente)** — deixa de ser hipótese. O que falta fechar é o **gatilho de abrir**, não o modelo. | pronta para ratificar |
| **D5** preço | **Blend A+B** — escada por comparáveis só para os degraus vendíveis já (treino, certificação); trava "sob consulta" para compliance-pack/SOTA até instrumentar. | parcialmente pronta |
| **D3** consumer | **Opção C (desacoplar)** — mentoria avança já; app-consumer fica gated. | pronta para desacoplar |

---

## D6 — Comprador-alvo primário *(a decisão-raiz)*

**Pergunta:** quem é o comprador primário — P3 (empresa/sistemas internos), P4 (regulado/enterprise),
P5 (dev solo) ou P6 (leigo) — para focar mensagem/GTM?

| Opção | Tradeoffs | Evidência |
|---|---|---|
| **P4 — regulado/enterprise (mensagem lidera por compliance)** | **Pró:** único diferencial confirmado (whitespace compliance-peer); justifica ticket premium; consistente com compliance-pack de D4. **Contra:** ciclo de venda longo; o mecanismo L1-L6 está `gated` (risco `declarado≠verificado`); zero adotante regulado provado; tensiona com M3 (Claude Code-only vs demanda multi-ambiente). | Interno: `personas.md` P4 = "cunha de maior valor", shadow AI 82%/FINRA (Zylos 2026). Mercado: GRC $10-40k/ano; compliance $15.2B até 2026 (14.8% CAGR) — layer3labs.io, surecloud.com. |
| **P3 — empresa/sistemas internos (lidera por consistência/escala/ROI)** | **Pró:** "volume org mais provável", mercado mais líquido; padrão platform-engineering/IDP bottom-up; ciclo mais curto; **não depende de L1-L6** — vende hoje sem risco. **Contra:** dor mais genérica, menos defensável; compete de frente com Agent OS/BMAD/SuperClaude; risco de virar "mais um framework de comandos". | Interno: `personas.md` P3, InfoQ 2026 (16-30% de ganho no quintil que reformula processo). Mercado: comprador de IDP = time de plataforma; bancos/fintechs embutem compliance-as-code no pipeline — tensure.io, gartsolutions.com. |
| **P5 — dev solo** | **Pró:** produto já pronto/provado (standalone grátis); menor fricção (PLG); alimenta o MOAT. **Contra:** `strategy.md`/D7 **já decidiram** que P5 não é meta de receita — escolhê-lo contradiz decisão ratificada; tom P5 ≠ tom P3/P4. | Interno: `strategy.md` "P5 = MOAT/advocacy, não funil de receita"; D7 ratificado. *(existe para descartar com fundamento.)* |
| **Não decidir — abrir até instrumentar** | **Pró:** honesto com dado insuficiente (P3/P4 ambos `[hipótese]`); instrumentar o mini é o caminho de evidência própria. **Contra:** **gateia D1/D5/M3** — não decidir trava as três por mais um ciclo; whitespace P4 já reduz o risco de decidir agora. | `decisions.md` marca D6 `aberto`; `metrics.md` é onde a instrumentação geraria o dado. |

**Recomendação:** **cindir** — MENSAGEM = **P4** (com a condição de não prometer L1-L6 gated); PIPELINE = **P3**.
Não recomendo P5 (contradiz D7) nem reabrir P6 (pré-req de branding).

**Open questions:**
1. D6 é sobre **POSICIONAMENTO** (a quem falar) ou **PIPELINE** (a quem vender primeiro)? A recomendação assume
   perguntas separadas; o card não distingue — o maestro precisa confirmar a cisão.
2. **Zero adotante P4 provado** — escolher P4 na mensagem é aposta em whitespace de pesquisa, não em ICP validado.
   Falta entrevistar 1-2 prospects regulados antes de comprometer copy/GTM.
3. Se P4 vira mensagem, **pressiona M3**: comprador regulado costuma exigir multi-ambiente/on-prem/auditoria de
   terceiros — falta reconciliar com "Claude Code-only por design" (ratificado).
4. Falta instrumentar (`metrics.md`) se o "aha" do mini converte mais forte em sinal P3 ou P4.

---

## Árvore de acoplamento — dado D6, o que D1/D5/D3 se tornam

Não achatar a dependência: **a mesma opção de D1/D5/D3 muda de significado conforme D6**.

```
                         ┌───────────────── D6 (RAIZ) ─────────────────┐
                         │  MENSAGEM=P4  ·  PIPELINE=P3  (recomendado)  │
                         └───────────────────┬──────────────────────────┘
              ┌───────────────────────────────┼───────────────────────────────┐
              ▼                                ▼                                ▼
         D1 (postura)                     D5 (preço)                       D3 (consumer)
```

### Ramo A — **D6 = MENSAGEM P4 / PIPELINE P3** *(recomendado)*
- **D1 →** ratificar **A (camadas)**, mas a **abertura pública fica mais gated**: comprador regulado exige prova
  antes da promessa, então o "gatilho de abrir" precisa contemplar auditabilidade demonstrável. A opção **C
  (SaaS control-plane)** ganha atração de *horizonte* (é onde compliance-as-a-service vira recorrente) — mas
  segue colidindo com a identidade sem-infra e com o gate de D2.
- **D5 →** **dois pontos de preço na mesma camada**: certificação individual (~$1k, serve P3 e P4 igual) +
  compliance-pack enterprise ($15-40k/ano, willingness-to-pay de P4). Comunicar o pack **por risco** (P4) e
  **por consistência** (P3). SOTA fica travado em D2.
- **D3 →** **secundário**. Consumer/mentoria não podem diluir o tom denso-técnico conquistado em P4 — reforça a
  **opção C (desacoplar)** e sobe a probabilidade da **opção D (spin-off de marca)** se o app amadurecer.

### Ramo B — **D6 = P3 primário (mensagem também lidera por consistência/escala)**
- **D1 →** **A (camadas)** vira **PLG clássico de dev tool**: abertura pública mais rápida, gatilho de abrir mais
  simples (adoção bottom-up). Menos pressão sobre o gate de D2 (P3 é menos sensível a dado que P4).
- **D5 →** ancoragem desce para a **faixa dev-tool/IDP** ($130-260/mês recorrente, consultoria day-rate), sem o
  "prêmio de risco regulatório" — a mesma escada, números mais baixos.
- **D3 →** continua **C (desacoplar)**, mas a mentoria pode usar a **mesma marca** sem tanto risco de diluição
  (tom P3 é menos denso que o de P4).

### Ramo C — **D6 = não decidir agora**
- **D1/D5 travados** por mais um ciclo (não há a quem precificar nem abrir). **D3 = B (gated puro)** por default.
  Custo: perde-se a janela do whitespace P4 já confirmado. Só recomendável se o maestro exigir dado de conversão
  próprio antes de qualquer copy — o que empurra a instrumentação de `metrics.md` para o caminho crítico.

> **Invariante em todos os ramos:** D7 (ratificado) fixa que **standalone é grátis** e a fronteira de venda é a
> **federação** — nenhum ramo precifica o framework/standalone em si, só os degraus de cima. E a **ativação de
> D2** (moeda-dado) segue `gated` — o degrau **SOTA** de D5 e o **Company Brain além de N=1** de D3 dependem dela.

---

## D1 — Postura comercial

**Pergunta:** o Onion vira comercial? Como reconciliar "framework template, não distribuído" com "fazer dinheiro"?

| Opção | Tradeoffs | Evidência |
|---|---|---|
| **A — Camadas (mini-funil aberto + captura adjacente: selo/curadoria/serviço)** *(inclinação atual)* | **Pró:** funil já desenhado e propagado; o ativo vendável é selo+rede+serviço (resistente a fork), não o texto; receita "mais próxima" (treino) começa já. **Contra:** exige travar o modelo antes de abrir; standalone é zero-receita por design (toda receita depende de converter p/ hub/serviço); falta o **gatilho de abrir**. | Interno: `strategy.md` §Modelo comercial, `sales-process.md`. Mercado: BMAD (MIT + workshop), Wardley (aberto + consultoria), SAFe/EOS (selo/rede). **Sinal novo:** Anthropic opera a MESMA fronteira — Claude Code pleno em Pro/Max, marketplace/governança gated a Team/Enterprise (claude.com/pricing, fev/2026). |
| **B — Licença restritiva (BSL/SSPL desde o início)** | **Pró:** captura mais direta/antecipada. **Contra:** guardrail interno é explícito contra — relicenciar tarde → fork hostil (HashiCorp→OpenTofu, Redis→Valkey 83%, Mongo); sem comunidade, é só fricção; conflita com a identidade "não distribuído". | `strategy.md` §Guardrails; casos HashiCorp/Redis/Mongo são o contra-exemplo canônico da pesquisa (2026-07). |
| **C — SaaS control-plane (dashboard/console pago da federação)** | **Pró:** monetiza a camada 2+3 (não comoditizada); recorrência. **Contra:** exige infra SaaS nova (colide com identidade sem-CLI/sem-infra, ratificada 2026-05-18); a substância (moeda-dado D2) está `gated`. | `onion-distribution-strategy-2026-06.md` §4; `decisions.md` D2; `CLAUDE.md` (v4.0 FASES 5-9 abandonadas). Mercado: hybrid pricing 43%→61% em 2026 (Bessemer) — mas depende de telemetria ausente. |
| **D — Consultoria-only (nunca abre)** | **Pró:** moat mínimo; monetiza o que já existe; zero infra. **Contra:** sem funil de aha, cresce só por outreach 1:1 do maestro (não escala); desperdiça D7/pesquisa; é "não decidir" disfarçado (é o modo de fato hoje). | `strategy.md` §Diferenciais (o moat de credibilidade **pressupõe visibilidade de adoção**, que consultoria-only não gera). |

**Recomendação:** **ratificar A** (deixa de ser hipótese). Tratar **C como HORIZONTE** pós-D2-ativação (não descartar,
não escolher agora). **B** contraria o próprio guardrail. **D** reduz escopo ao que já acontece sem decisão.
O item que realmente falta fechar em D1 **é o gatilho de abrir**, não o modelo.

**Open questions:** (1) qual o **gatilho concreto** de abrir o standalone (métrica/data/nº de adotantes/aprovação
do maestro)? (2) D5 sem número por camada até instrumentar `metrics.md`; (3) marcar C formalmente como horizonte
pós-D2 ou descartar? (4) o "aha" do mini roda no repo do prospect — isso expõe a camada 1 do Onion antes de decidir abrir?

---

## D5 — Preço por camada

**Pergunta:** como precificar treino → certificação → compliance-pack → curadoria SOTA, dado "ticket premium
($129+) > pipoca ($5-10)", vender selo/serviço (não o texto), e preço-por-outcome só depois de instrumentar?

| Opção | Tradeoffs | Evidência |
|---|---|---|
| **A — Escada por comparáveis (faixas, não números fixos)** | **Pró:** dá número para vender já; ancora em mercados maduros; faixa preserva margem. **Contra:** comparáveis têm 10-20 anos de prova, o Onion tem 1 core + 4 adotantes — ancorar alto sem track record gera objeção. | SAFe SPC $795 + $3.5-7k, renovação $195-995/ano; GRC Vanta/Drata $15-75k/ano; AI-gov $40-150k/ano; consultoria IA solo $1.2-2.8k/dia; dev-tool premium $130-260/mês. |
| **B — Adiar número (day-rate + "sob consulta" até instrumentar)** | **Pró:** fiel a `declarado≠verificado` e ao guardrail "preço por outcome só depois de instrumentar". **Contra:** atrasa a receita que D4 quer já; "sob consulta" é fricção na 1ª call; não resolve, empurra. | `metrics.md` "valor por adotante" = `[a instrumentar]`; sem benchmark free→paid p/ frameworks de metodologia dev (BCG 2025). |
| **C — Ticket único alto (bundle anual)** | **Pró:** vende selo/serviço puro; 1 número; menos overhead p/ maestro solo. **Contra:** fecha a porta p/ quem quer 1 peça; colide com o motor land-and-expand incremental; teto de fulfillment (EOS ~$3.5k/mês por engajamento). | `strategy.md` guardrail "poucos compradores de alto valor"; EOS implementer (capacidade limitada). |
| **D — Segmentado por comprador (D6-coupled)** | **Pró:** alinha preço ao valor percebido (P4 paga por risco, P3 por consistência). **Contra:** exige **D6 resolvido primeiro**; mais complexo sem cases. | `personas.md` P4 = "cunha de maior valor"; `decisions.md` D6 registra o mesmo tensionamento. |

**Recomendação:** **blend A+B**. Escada por comparáveis **só** para os degraus que D4 já persegue e precisam de
número hoje — **treino/consultoria** (day-rate ~$1.2-2k) e **certificação "operador Onion"** ($795-$1.5k one-time
+ renovação anual baixa, ajustado **para baixo** por falta de rede/selo reconhecido). Trava de B — **"sob consulta"/
faixa larga não-comprometida** — para **compliance-pack** ($15-40k/ano como ponto de partida citável, **não fechado**)
e **assinatura SOTA**, até existirem 2-3 cases com "valor por adotante" instrumentado. **SOTA depende de D2** (moeda-dado
`gated`): precificá-la agora venderia garantia não-construída. **C** fica como simplificação de GTM se o maestro
preferir menos SKUs (não priorizo — colide com land-and-expand). **D** informa **como comunicar** o compliance-pack
(risco↔P4, consistência↔P3), mas não deve travar o degrau de certificação, que serve os dois igual.

**Open questions:** (1) aceitar operar sem benchmark free→paid ou instrumentar antes de anunciar preço? (2) unidade
de cobrança do hub/pack (repo/squad/seat/flat) — muda a faixa em ordem de grandeza; (3) compliance-pack = SaaS
recorrente (Vanta/Drata) ou serviço + retainer (EOS, capacidade limitada)? (4) quantos ciclos antes de recertificação
paga? (5) falta o número-pivô "valor por adotante" (`metrics.md`).

---

## D3 — Linha consumer (Company Brain / Onion Pessoal) + mentoria

**Pergunta:** perseguir consumer (Company Brain N=1) + mentoria como pilar de GTM? Requer branding/storytelling
próprios (muda comprador e promessa vs o funil B2B/dev).

| Opção | Tradeoffs | Evidência |
|---|---|---|
| **A — Comprometer já (consumer + mentoria juntos, branding dedicado)** | **Pró:** aproveita o timing "AI second brain" quente; 2ª motion de receita. **Contra:** exige braço de branding novo/caro; fura "núcleo estreito"; leigo tem elasticidade **abaixo** do ticket de D5; app em F0/F1, N=1 — vende promessa não-construída. | `personas.md` P6 = "[hipótese — maior incerteza]"; `voice-of-customer.md` "complexidade bloqueia P6 hoje". Mercado consumer: $9,99-40/mês — contradiz D5. |
| **B — Manter gated (status quo)** | **Pró:** não gasta capital de branding antes do SSOT técnico (D2) pronto. **Contra:** estaciona D3 sem gatilho de reavaliação; janela de mercado pode fechar; amarra a mentoria (que já fatura) ao app não-provado. | `decisions.md` D3 = "hipótese de maior incerteza"; `onion-pessoal-app` (F0 fechado só no device do maestro). |
| **C — Desacoplar: mentoria avança / app fica gated** *(recomendado)* | **Pró:** mentoria já é receita D4, não depende do app nem de branding leigo; pricing de mercado ($149-399/mês, cohorts $97-497) **compatível com D5**; separa risco técnico (app) do comercial (mentoria). **Contra:** decidir se mentoria usa a mesma marca ou sub-marca; reconciliar 2 GTMs se o app amadurecer depois. | `sales-process.md` (treino = item 1 de D4, sem depender do app). Mercado: communipass.com, kourses.com. |
| **D — Spin-off de marca ("Onion Pessoal" separado)** | **Pró:** protege o posicionamento denso já conquistado; testa a hipótese sem gastar a marca-mãe. **Contra:** dobra o trabalho de branding; perde o fio "prova viva do método"; não resolve comprador (D6) nem preço (D5). | Sinal fraco (sem case 1:1). `voice-of-customer.md`: público leigo herdaria o vocabulário denso, marcado como bloqueio a P6. |

**Recomendação:** **opção C (desacoplar)**, com **D** como refinamento de marca **depois** que a mentoria validar.
A mentoria pode avançar **hoje** sem violar `declarado≠verificado`; o app-consumer permanece gated (F0/F1, N=1, e a
promessa "Company Brain reconciliado" depende de D2). Deixar D3-puro-consumer **aberto/gated** (não descartado)
preserva a opcionalidade se o app amadurecer.

**Open questions:** (1) gatilho para acionar branding/storytelling — marco técnico do app (F1?), 2º usuário externo,
ou calendário? (2) mentoria usa a **mesma marca** Onion ou sub-marca — e quem decide (D1 ou novo card)? (3) D3 aposta
em **um** comprador (P6) ou **dois** (leigo paga pipoca / empresa paga ticket alto)? Se dois, colide com D6 pedir "1
primário". (4) falta preço-base testado para mentoria e app — os números são análogos externos, não dado próprio.

---

## O que falta instrumentar antes de fechar

O gargalo comum às quatro decisões é **dado próprio**, não análise de mercado — a análise já convergiu.

1. **`metrics.md` — "valor medido por adotante"** (`[a instrumentar]`): é o número-pivô. Sem ele, todo preço de
   **compliance-pack e SOTA** (D5) é chute educado, e o **preço-por-outcome** (a tendência de mercado 2026) fica
   fora de alcance. **Bloqueia:** D5 (degraus altos), D1 (valor por degrau de D4).
2. **Conversão do "aha" por persona** no mini/standalone: mede se o sinal converte mais forte em **P3 ou P4**.
   **Bloqueia:** fechar D6 com **dado próprio** em vez de whitespace de pesquisa.
3. **Benchmark free→paid** para frameworks de metodologia dev: **não existe** (registrado no repo). Decidir se
   opera-se sem ele ou instrumenta-se antes de anunciar preço público. **Bloqueia:** anúncio de preço em D5.
4. **1-2 entrevistas com prospects regulados (P4):** hoje P4 é `[hipótese]`, zero adotante provado. Valida o ICP
   antes de comprometer copy/GTM. **Bloqueia:** solidez da mensagem P4 (D6) e a reconciliação com M3.
5. **Gatilho de abrir (D1):** métrica/data/nº de adotantes/aprovação — é **decisão do maestro**, nenhuma fonte
   externa resolve. **Bloqueia:** D1 sair de hipótese para operação pública.
6. **Ativação de D2 (moeda-dado):** o SSOT 6 camadas L1-L6 **construído + dogfoodado** + threat model N-tenant
   verificado. **Bloqueia:** o degrau **SOTA** (D5) e **Company Brain além de N=1** (D3) — e a promessa de dado
   para o comprador P4.

> **Ordem sugerida (não decisão):** os itens 5 e 4 são do maestro/campo e podem andar já; 1-3 são engenharia de
> `metrics.md` no caminho crítico de D5; 6 segue `gated` por desenho (não force). Ratificar **D1=A** e **D3=C**
> **não depende** de nenhum instrumento — pode fechar agora; **D5** (degraus altos) e **D6** (com dado próprio)
> são os que a instrumentação destrava.
