# Métricas de Produto

**Última Atualização:** 2026-07-13

> KPIs-norte desta fase (early / pré-PMF externo). A maioria é **aspiracional** — depende de instrumentação que ainda não existe. Marcado `[hipótese]` / `[a instrumentar]`.

---

## KPIs-norte (escolhidos pelo maestro)

| KPI | O que mede | Estado |
|---|---|---|
| **Adoção / repos ativos na família** | tração real do método (dogfood + adotantes) | mensurável hoje — **derive, não copie**: `grep -c '^ *kind: adopter' docs/evolution/federation/members.yaml` ([régua canônica](../decisions.md)) |
| **Valor medido por adotante** | retrabalho evitado / velocidade / frescor de contexto | `[a instrumentar]` — é o número que vira prova de venda e base de preço |
| **Conversão mini→pago** | quem prova o mini e sobe pra uma camada de compromisso | `[hipótese]` — depende do mini existir |
| **Receita de serviço/certificação** | R$ de treino/consultoria/selo — sustentação concreta | mensurável quando formalizado (D4) |
| **Mentoria (Evolução + Pessoal)** | tração da linha de mentoria | `[hipótese — D3, depende de branding]` |

## A instrumentação é estratégica

O KPI "valor medido por adotante" é o pivô: é ao mesmo tempo (a) o **"aha"** do mini, (b) a **moeda-dado** do flywheel de federação, e (c) a prova que destrava **preço por outcome**. Sem telemetria, o Onion não pode precificar por resultado ([BCG 2025](https://www.bcg.com/publications/2025/rethinking-b2b-software-pricing-in-the-era-of-ai)). Candidatos a instrumentar:

- **Frescor de contexto** — já existe base: `/meta:context-freshness` (veredito CURRENT/STALE/HISTORICAL).
- **Retrabalho evitado / velocidade** — proxy do efeito Anthropic (40%↓erro, 55%↑veloc); precisa de baseline.
- **Ciclos faseados concluídos vs abandonados** — sinal de continuidade real.

## Métricas de saúde do dogfood (já existem)

O gate mecânico é o dogfood determinístico: `.claude/validation/` (lint + selftest + inventory). Saúde de federação: `/meta:federation-status` (drift + CI por membro). Não são KPIs de negócio, mas são a **prova de que o organismo funciona** (moat de credibilidade).

## Lacunas de benchmark `[TO BE COMPLETED]`

- **Sem taxa de conversão free→paid** de referência para frameworks de metodologia dev (a pesquisa não encontrou; SaaS geral é 2–5%, não transferível).
- **Sem baseline de valor** por adotante ainda — primeiro alvo de instrumentação.

---

_§template: o adotante troca por seus KPIs de negócio reais (engajamento, receita, churn)._
