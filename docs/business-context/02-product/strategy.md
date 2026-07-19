# Estratégia de Produto

**Última Atualização:** 2026-07-19

> Núcleo do seed. Ancora visão, posicionamento (com pesquisa citada), o **modelo comercial em camadas** e os diferenciais/moat. Inclinações marcadas `[hipótese]`; decisões abertas em [`../decisions.md`](../decisions.md).

---

## Visão e missão

- **Visão (2–3 anos):** o Onion como o organismo que orquestra o ciclo **produto → engenharia → compliance** com IA, evoluindo pelo próprio uso (dogfood + federação) — e do qual **derivam** produtos/serviços nas bordas, sem virar "plataforma que faz tudo".
- **Missão:** tornar o **contexto explícito e versionado** (spec-as-code) a fonte de verdade que a IA lê, para que decisão de negócio, execução técnica e governança parem de se perder.
- **Definição de sucesso (nesta fase):** valor **provado e medido** por adotante + primeira receita **formalizada** (serviço/certificação), sem comprometer a janela de decisão do modelo.

## A dor central (provada vs latente)

- **Provada AGORA:** *delegation gap* / contexto perdido / drift. Devs delegam só 0–20% com confiança; o gargalo é clareza sobre o que construir, não escrever código ([Anthropic 2026](https://agentmarketcap.ai/blog/2026/04/05/anthropic-agentic-coding-trends-report-claude-code-eight-shifts)). Contexto bem mantido → **40% menos erro, 55% mais rápido**. O mecanismo do Onion ataca isso direto.
- **Latente-pertíssimo (o "ouro" a lapidar):** **governança/compliance de IA-no-loop como dimensão peer** — whitespace de mercado (ver Posicionamento).

## Posicionamento (pesquisa citada — 2026-07-12)

**Categoria:** SDD (spec-driven development) sobre Claude Code. Já é tabela-stakes: "toda ferramenta grande lançou sua variante de SDD" ([zeroshot](https://zeroshot.ghost.io/spec-driven-development-with-ai-coding-agents/)).

| Tipo | Concorrentes | Nota |
|---|---|---|
| Diretos (framework `.claude/` + specs + comandos) | **Agent OS** ⚠️ (mais próximo estruturalmente), SuperClaude, BMAD-METHOD | monitorar Agent OS de perto |
| Indiretos — SDD tooling | GitHub Spec Kit (~90k★), Kiro/AWS, Tessl, OpenSpec | plataforma/IDE diferente |
| Indiretos — execução/orquestração | Claude Flow/Ruflo, MetaGPT | infra de agentes, não metodologia |

**🎯 Whitespace (evidência mais forte):** em 10+ buscas, **nenhum** concorrente trata produto + engenharia + **compliance** como três dimensões peer num ciclo só. A indústria trata governança de IA em nível organizacional/regulatório (EU AI Act, ISO 42001, [FINRA](https://zylos.ai/research/2026-05-01-ai-agent-governance-compliance-2026/): autonomia/scope-creep/auditabilidade), **não** como capability integrada a um framework instalável. Os workflows faseados retomáveis + sessions do Onion mitigam exatamente esses 3 riscos FINRA por construção. _É lacuna observada, não categoria confirmada — mas é o ângulo mais defensável._

## Diferenciais / moat

1. **3 dimensões peer (inc. compliance)** — whitespace confirmado.
2. **Workflows faseados retomáveis** — continuidade real (vs one-shot).
3. **Auto-evolução / dogfooding** — o framework se audita e corrige (`/meta:evolve`, federação, auto-teste de guardas).
4. **Federação multi-repo** — co-evolução core↔adotantes.
5. **Moat de credibilidade** (o que você perguntou): **SDAAL-dogfood-KB + regras de evolução + respeito à evolução das doutrinas**. Ninguém compra "temos SDAAL"; compram a **prova viva** de que o método funciona — o dogfood *é* o argumento de venda. Separa "organismo que aprende" de "mais um repo de comandos". Vende-se como **confiança**, não feature.

## Modelo comercial — camadas com funil aberto + captura adjacente `[hipótese — D1]`

Convergência: a intuição do maestro (mini-funil + parte paga + camada de serviço + "já vendo treino/consultoria") **é o modelo de menor risco da pesquisa** — padrão [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) (framework grátis, monetiza workshop) + [Wardley Mapping](https://learnwardleymapping.com/) (método aberto, receita por consultoria) + selo/rede [SAFe/EOS](https://scaledagile.com/certification/).

| Camada | O que | Captura | Risco |
|---|---|---|---|
| **onion-mini** (porta/teaser) | demo instrumentada no repo do prospect (3 contextos + efeito medido) | funil, credibilidade, o "aha" que **não dá pra desver** | baixo |
| **standalone** (dev solo, **grátis**) | framework **completo** — 3 dimensões + ferramentas de trabalho (KG soberano, diary, orquestração…), **SEM federação** | **MOAT / advocacy / dogfood de campo** — o "texto" replicável dado de graça; **não é funil de receita** (solo não sustenta volume) | ⚠️ (decidir o modelo **antes** de abrir) |
| **hub** (empresa, **upsell**) | **+ federação** (a rede: sync multi-repo, bundles por squad, sub-adoção) | o **moat inimitável** (nenhum concorrente tem federação/3-peer) + assinatura de curadoria | médio |
| **Fechada/paga** | facilitadores, templates prontos, curadoria SOTA | template premium + assinatura de atualização | médio |
| **Serviço** | treino, consultoria, **certificação "operador Onion"**, implantação | onde você **já ganha** — formalizar | baixo |

> **Reframe de tiers `[decidido 2026-07-19]`** (pesquisa `docs/evolution/research/onion-tier-matrix-2026-07`): **hub = adoção de EMPRESA** (federação como camada de time); **standalone = dev solo com a ferramenta COMPLETA, mas SEM federação**. A fronteira **é a federação**: dá-se de graça o framework (o "texto"), retém-se a **rede** (o moat). Espelha a Anthropic (Agent Skills plenas no plano pago individual; marketplace/auto-install gated a Team/Enterprise) e o land-and-expand (Datadog): o gatilho de expansão é a **chegada do multi** (2º repo/2ª pessoa), não o uso individual crescer. Um standalone pode **evoluir p/ hub** (chega o multi) ou **virar consumer** (re-parenteia a um hub).

**Motor (land-and-expand, dupla-moeda):** o mini prova valor → o standalone-grátis firma o hábito (MOAT) → a **chegada do multi** (2ª pessoa/repo) dispara o upsell p/ **hub (federação)** OU financeiro. A moeda-dado (federação de contexto) **alimenta** o que justifica a moeda-financeira (curadoria SOTA) — **mas depende de resolver D2** (garantia local-first+destilado; colide com a fronteira de mitigação de inferência). A **instrumentação** do mini/standalone é o produto escondido: mede valor (o "aha"), gera a moeda-dado, e destrava **preço por outcome** amanhã ([tendência 2025-26](https://www.bcg.com/publications/2025/rethinking-b2b-software-pricing-in-the-era-of-ai), exige telemetria que hoje não existe).

### Sequência de receitas `[inclinação — D4]`
**1º** formalizar treino/consultoria (receita mais próxima, menor risco) → **2º** certificação "operador Onion" → **3º** compliance-pack (regulados, ticket alto) → **4º** assinatura de curadoria SOTA (recorrente).

### 🚩 Guardrails da pesquisa (não ignorar)
- **Nunca relicenciar depois de abrir.** HashiCorp/Redis/MongoDB levaram fork financiado por Big Tech em semanas (Valkey pegou 83% do enterprise da Redis). Vantagem do Onion: **nunca foi distribuído → decidir o modelo ANTES de abrir**.
- **O ativo vendável não é o texto** (copiável) — é **selo + rede + atualização contínua + serviço** (padrão SAFe/EOS).
- **Ticket premium > pipoca:** maestro solo não sustenta volume; mire poucos compradores de alto valor.

## Prioridades estratégicas (nesta fase)

1. Provar e **medir** o valor no dogfood + adotantes (base de venda).
2. **Formalizar** treino/consultoria (D4, 1ª receita).
3. Manter a **janela de decisão** do modelo aberta (não abrir publicamente antes de D1).

## Princípios de produto

- **Núcleo estreito e aberto; produtos derivam nas bordas** (disciplina anti-"todo e o nada").
- **Dogfood é o gate** — toda mudança de core se valida rodando o artefato.
- **Compliance como garantia, não passivo** — se a moeda-dado avançar, dados nascem local-first + destilado (colisão com fronteira P5, ver `D2`).

---

_§template: o adotante troca este conteúdo pela sua própria estratégia; o modelo em camadas e os guardrails são referência, não prescrição._
