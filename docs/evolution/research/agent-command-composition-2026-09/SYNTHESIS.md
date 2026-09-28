---
title: 'Composição de comando de agente: o campo nomeou as partes, e o destino do que se PRODUZ ficou sem dono'
date: 2026-09-28
kg: docs/evolution/research/agent-command-composition-2026-09/agent-command-composition-2026-09.kg.yaml
run_id: wf_ba0cf8fd-e47 (varredura) · wf_91ae27d0-df6 (primárias)
tokens: 8217748
agents: 114
duration_min: 83
---

# Composição de comando de agente — setembro de 2026

> **Projeção do grafo, nunca fonte paralela.** 26 nós · 56 arestas · `kg-radar --integrity --schema`
> exit 0 · `review_after: 2026-12-27` (cadência MERCADO, 90d). Os ids citados são a autoridade; este
> documento é leitura.

## A pergunta, e a resposta em uma linha

A composição inteira — **doutrina reutilizável + contexto medido injetado + orquestração determinística
+ destino obrigatório em grafo** — **não tem nome de mercado confirmado**. O campo nomeou as **partes**,
e deixou de fora exatamente a peça que fecha o ciclo.

| parte | nome no mercado | fonte / tier |
|---|---|---|
| (a) doutrina como fragmento reutilizável | **"Agent Skills"**, spec aberta | Thoughtworks Radar vol. 34 · tier 7 |
| (b) contexto injetado | **MCP**, sob a **Agentic AI Foundation / Linux Foundation** | fonte institucional · tier 9/10 |
| (c) orquestração determinística | topologia **declarada**, orquestrador sem custo de token | Microsoft *Conductor* · tier 6 |
| **(d) destino obrigatório do que se PRODUZ** | **sem dono** | — |

## O achado que o Elenxo salvou de uma leitura generosa

A primeira redação desta síntese dizia *"o campo já tem destino declarativo e validade temporal"*. O
refutador derrubou a metade do destino, e **a objeção sobrevive**:

O `Context Store` do *Context Kubernetes* é peça da **via de LEITURA**. A única interface voltada ao
agente é a `Definition 3.4 (Context Endpoint)`, **read-only por assinatura** —
`ε(q, ω, α) → {u1,...,uk} ⊆ U` — seguida de:

> *"The agent never specifies where knowledge lives—only what it needs."*

**Medido no texto inteiro (88 KB):** `write(` ocorre **uma vez**, só na assinatura do CxRI
(`write(conn, path, c) → Result`), **sem nenhum critério de aceitação ou rejeição** em lugar algum. E
`agent-produced`, `knowledge produced`, `write path`, `writes back`, `contribute knowledge` →
**zero ocorrências**.

**Definir onde o conhecimento organizacional mora para ser ENTREGUE não é impor destino ao conhecimento
PRODUZIDO.** A distinção é o achado da rodada.

## O que o paper TEM, e que converge com o Onion

Duas peças, ancoradas em citação verbatim:

- **`Freshness Manager`** com quatro estados — `fresh, stale, expired, conflicted` (Seção 3.3);
- **`Requirement 2.4 (Context Freshness)`**, exigência formal numerada com referência cruzada ao NIST:
  > *"The system must continuously monitor the currency of all knowledge and take corrective action when
  > knowledge exceeds its configured time-to-live."*

Ou seja: **validade temporal com TTL e ação corretiva é arte externa estabelecida** — o `verified_at` /
`review_after` do Onion não é invenção, é convergência. O que **não** é arte externa é o **gate sobre a
escrita**.

## Onde o Onion está sozinho, e agora isto é afirmação ancorada

O único gate determinístico do paper está no **registro de permissão de agente**:

> *"This invariant is enforced at registration time: the Permission Engine rejects any agent profile
> that is not a strict subset…"*

É gate de **autorização**, não de **qualidade do que se escreve** — e o próprio paper o marca como
*design invariant*, com o R7 declarado como **design, não implementado**.

**O `kg-radar --integrity --schema exit 0` como PRECONDIÇÃO do `write(KG)` não tem equivalente
publicado nas quatro fontes primárias lidas.** Não é "ninguém pensou nisso": é que as especificações
abertas de 2026 padronizam **transporte** (MCP), **empacotamento** (Agent Skills) e **roteamento**
(Conductor), e nenhuma delas condiciona a escrita a um veredito mecânico.

## NÃO-VERIFICADOS — o que esta leva não sustenta

**Rejeitadas na ancoragem (4), que NÃO viraram nó** — entraram só na contabilidade de
`E_LACUNAS_PRIMARIES_0928`:

| fonte | veredito | o que caiu |
|---|---|---|
| `agentskills-spec` | `NÃO-ENCONTRADA` | versionamento normativo e governança/validação da spec |
| `conductor-msft` | `EXAGERADA` | *"roteia, não veta"* — **confirmado em conteúdo, caído por locator** |
| `conductor-msft` | `EXAGERADA` | schema de output tipado por agente |
| `mcp-governance` | `EXAGERADA` | a lista de membros fundadores por nível |

A segunda linha é a mais instrutiva: **claim certa sem âncora exata não passa.** A ancoragem não
pergunta *"isto é verdade?"* — pergunta *"o texto diz isto, aqui?"*.

**Da varredura anterior, e não recuperado:** 20 claims refutadas **todas por fonte fraca** (nenhuma por
contra-evidência), 31 não verificadas por teto de orçamento, 35 descartadas por orçamento.

**Eixo CAPITAL — não medido, e declarado.** Nenhuma rodada de investimento, M&A, valuation ou down
round. Nenhum worker foi colocado em base de capital. Isto é **lacuna de busca, não ausência de
mercado**, e viola a invariante `follow-the-money-e-eixo-de-pesquisa` até ser fechado — o que **não**
se faz em `primaries` (não há documento nomeado a ler), e exige varredura por trajetória.

## valeu-a-pena

| rodada | tokens | agentes | nós | por nó | veredito |
|---|---|---|---|---|---|
| varredura (`research`) | 7.265.255 | 104 | 8 | **~908k** | 20 refutadas por fonte fraca; 66 claims sem verificação por teto |
| **primárias** (`primaries`) | **952.493** | **10** | **+18** | **~53k** | 4 de 4 fontes alcançadas · 18 ancoradas · 4 rejeitadas |

**17× mais barato por nó**, e a tabela da própria skill previa ~42k/nó para `primaries` — bateu. A
lição é da **régua**, não do gosto: a varredura pagou **descoberta** para uma pergunta cujas fontes
acabaram sendo poucas e nomeáveis, e o teto que eu declarei (`maxFetch 15`) foi o gargalo, não a
disponibilidade de fonte.

## Nada foi selado

As duas propostas de veredito saíram como nós **`question` abertos**. Selar é do maestro, e a tabela de
selagem do `/meta:drive` (KIND `decision`) é o caminho.
