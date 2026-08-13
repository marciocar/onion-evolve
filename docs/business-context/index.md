# Business Context — Onion

> Contexto de negócio do próprio Sistema Onion (dogfood). Gerado por `/docs:build-business-docs` em 2026-07-13. **Seed núcleo** — camadas 03-market e 04-operations virão numa 2ª passada.

Este seed cumpre duplo papel (decisão do maestro):
1. **Contexto de negócio real do Onion** — dogfood do próprio framework.
2. **Referência replicável** para adotantes (partes marcadas com _§template_ servem de exemplo).

---

## Perfil de negócio

- **Produto:** Onion — framework template em `.claude/` que orquestra produto → engenharia → compliance com Claude Code (spec-as-code / SDD).
- **Categoria:** framework/metodologia para desenvolvimento de software assistido por IA (segmento SDD — spec-driven development).
- **Plataforma:** Claude Code (única, por design deliberado).
- **Estágio:** Early — validando problema/solução; N=1 dogfood + os adotantes de campo (contagem viva: `grep -c '^ *kind: adopter' docs/evolution/federation/members.yaml`). Sem PMF externo.
- **Modelo de negócio:** hoje **não-comercial / não-distribuído**. Em avaliação ativa: modelo em **camadas** (funil aberto + captura adjacente em serviço/certificação). Ver [`decisions.md`](decisions.md) `D1`.
- **Time:** 1 (maestro/criador) + agentes de IA.
- **Repo:** `onion-evolve` = fork privado de evolução; hub público em github.com/marciocar/onion.

---

## Camada 1 — Cliente ([`01-customer/`](01-customer/))

- [Personas](01-customer/personas.md) — 7 personas em camadas (maestro N=1 → adotante família → empresa → regulado → dev solo → leigo/pessoal → contribuidor)
- [Jornada](01-customer/journey.md) — descoberta → adoção → federação → advocacy
- [Voz do cliente](01-customer/voice-of-customer.md) — terminologia e sinais (majoritariamente `[INFERIDO]` — sem base externa ainda)

## Camada 2 — Produto ([`02-product/`](02-product/))

- [Estratégia](02-product/strategy.md) — visão, posicionamento (whitespace de compliance), **modelo comercial em camadas**, diferenciais/moat, guardrails da pesquisa
- [Métricas](02-product/metrics.md) — KPIs-norte e como instrumentar
- Feature catalog — _2ª passada_

## Camada 3 — Mercado ([`03-market/`](03-market/))

- [Panorama competitivo](03-market/competitive-landscape.md) — diretos/indiretos/execução + win-loss + 🎯 whitespace de compliance (pesquisa citada)
- [Tendências de indústria](03-market/industry-trends.md) — SDD mainstream · orquestração multi-agente · context engineering · regulatório

## Camada 4 — Operacional ([`04-operations/`](04-operations/))

- [Processo de vendas](04-operations/sales-process.md) — funil mini→serviço, qualificação, objeções, guardrails
- [Framework de mensagem](04-operations/messaging-framework.md) — _stub, depende de branding (`decisions.md` `D3`)_
- [Comunicação por IA](04-operations/customer-communication.md) — _stub parcial, brand-dependent (`D3`)_

---

## 🗂️ Registro de decisões estratégicas

O mecanismo de rastreio das decisões em aberto vive em **[`decisions.md`](decisions.md)** — cards `D1`–`D6` que você resolve escolhendo/descrevendo ao longo das sessões. É spec-as-code aplicado às próprias decisões de negócio.

---

## ⚠️ Pendências de validação (inferências a confirmar)

Marcado no corpo com `[INFERIDO]` (derivado de evidência) ou `[hipótese]` (opção a decidir). Principais:

1. **Comprador primário** — a validar (`D6`). Sinais: empresas c/ sistemas internos, times regulados.
2. **Modelo comercial** — em camadas é a inclinação, não decisão fechada (`D1`).
3. **Moeda-dado / federação** — hipótese; colide com a fronteira P5 (mitigação de inferência) do `discuss/onion-pessoal-marcio` (`D2`).
4. **Onion Pessoal / mentoria (leigo final)** — hipótese de maior incerteza; exige storytelling/branding/posicionamento (`D3`).
5. **Voz do cliente** — sem clientes externos; conteúdo é N=1 + adotantes, a enriquecer quando houver campo.

**Fontes:** relatórios de pesquisa orquestrada (competitivo + monetização, 2026-07-12, citados em `strategy.md`), `CLAUDE.md`, `README.md`, `docs/analysis/onion-review-2026-05.md`, memória do projeto.
