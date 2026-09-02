---
kg: docs/evolution/research/meta-research-lens-2026-09/meta-research-lens-2026-09.kg.yaml
run_id: "Agent tool x4 (lens-internal, lens-claude-code, lens-sota, lens-market — opus) + medição no contexto principal (WebFetch deepdive/docs, extração do script embutido do /deep-research)"
tokens: 1200000
agents: 4
duration_min: 40
verified_at: 2026-09-02
---

# A diretriz de pesquisa vira maquinaria — plano de execução (projeção do grafo)

> **SSOT:** [`meta-research-lens-2026-09.kg.yaml`](./meta-research-lens-2026-09.kg.yaml) (radar exit 0; 26 nós / 34 arestas).
> Dado bruto em [`data/`](./data/). Ordem do maestro (2026-09-02): *"como podemos estruturar um conjunto
> `/meta:*` para eu não precisar sempre ter que escrever estas coisas... pesquisar e montar um plano de
> execução. O CORAÇÃO é o Onion."* Reforços na mesma sessão: *"sempre precisamos estar de olho no mercado"*;
> *"tem uma doutrina, maquinaria ou arquitetura para escolher as fontes?"*.
> `tokens:` é estimativa (o `Agent` tool não reporta custo por worker como o `Workflow`) — declarado, não medido.

## A resposta em uma linha

**Não é um conjunto de comandos novos: é a diretriz virando SPEC CARREGADA + três campos no grafo + duas
guardas no lint + um workflow derivado do `/deep-research` embutido.** O que o maestro re-digita é
*contexto*; a força do Onion é o Transformer; logo a lente entra pelo caminho que o Claude Code 2.1.258 já
dá para contexto (fragmento, `.claude/rules/` por path, skill auto-ativada com `!`cmd``), e a maquinaria
(radar, lint, catraca) **valida a saída** em vez de tentar dirigir o modelo por prosa. Comando novo há um
só, porque workflow exige opt-in e o comando *é* o opt-in: **`/onion-research`**.

## O que já existe (medido, não suposto)

| Cláusula da diretriz | Cobertura | Onde |
|---|---|---|
| Claude Code na versão atual | **TOTAL** | eixo E3 + REGRA 65 (`cc_version`; e desde #768 a versão do PROCESSO) |
| Caminho do dinheiro | **TOTAL** | eixo E4-capital do `/meta:radar` |
| Decisões revisáveis · dogfood · breadcrumbs | **TOTAL** | `SUPERSEDES`, `/meta:kg-freshness`, `kg-born-marker`, `trace:` |
| Lente Onion · fontes amplas · revisar o que temos · não reinventar/não abandonar · Transformer | PARCIAL | peças espalhadas (`radar.md:49`, `adopt.md:26-29`, Elenxo) |
| Guardar em `.kg.yaml` com **temporalidade** e **reuso** | PARCIAL | `verified_at` existe; **revisita não**; 27 grafos de pesquisa **nunca lidos** por pesquisa nova |
| **Escolher fontes** | **NENHUMA** | só R15 (confiança no conteúdo) e uma frase em `kg.md:116` |

Os três gaps (tema livre sem porta · grafo não envelhece · ninguém lê o corpus) **são uma superfície só**.

## O desenho — 6 peças, nenhuma gorda

1. **`common/prompts/research-doctrine.md`** — as 10 cláusulas como checklist executável. Citado por
   `/meta:radar`, `@research-agent`, `/meta:kg` e pela skill. *Não vai para o CLAUDE.md* (contra-sinal
   abaixo).
2. **`.claude/rules/research-lens.md`** com `paths: docs/evolution/research/**` — carrega só quando se
   toca um grafo de pesquisa (progressive context disclosure nativa; `InstructionsLoaded` prova que carregou).
3. **Três campos no grafo** (irmãos do `verified_at`, que continua sendo *quando EU verifiquei*):
   - `valid_from:` no nó de evidência — *quando o fato passou a valer* (bi-temporal; Graphiti/arXiv 2501.13956);
   - `source_tier:` 1–10 (escala DREAM: 9–10 definitiva · 7–8 alta · 4–6 moderada · 1–3 baixa) +
     `source_kind:` `primary|paper|engineer|analyst|forum|vendor-on-competitor|aggregator`;
   - `meta.review_after:` no grafo, derivado da cadência do tipo dominante (tabela abaixo).
4. **Duas guardas SOFT no lint** (irmãs da REGRA 65): `review_after` vencido em `docs/evolution/research/*/*.kg.yaml`;
   `confidence ≥ 0.8` com `source_tier ≤ 3` ou `vendor-on-competitor` sem fonte primária.
5. **`kg-corpus-grep.sh <tema>`** — nós de todos os grafos que casam, com data, veredito e tier. É o passo
   0 de toda pesquisa (o corpus entra no contexto **antes** da busca, via `!`cmd`` na skill).
6. **`/onion-research`** = `.claude/workflows/onion-research.js` **derivado** do `/deep-research` embutido
   (mesmos schemas e votação 3/2), com o que ele não tem: fase 0 corpus; **eixos fixos sempre presentes**
   (Claude Code versão atual · **mercado/capital** · repos por trajetória · analistas · comunidade) + ângulos do
   tema; `source_tier` por fonte; orçamento em `args` (excedente **nomeado**, nunca silêncio); tiering por
   fase (coleta sonnet/medium; verify+síntese opus/high ou fable); fase final `write(KG)` + radar exit 0 +
   `review_after`. Lido de `docs/onion/radar-sources.yaml` (roster por eixo e cadência — dado, não prosa).

**Doutrina de fontes** (a pergunta do maestro): roster por eixo com cadência (dado) + tier por nó (campo) +
guarda (lint) + verificação de citação mecânica como check opcional caro (re-fetch, o trecho existe e
sustenta — WANDR). O tier *fornecedor-sobre-concorrente* existe e é **sempre suspeito**: toda comparação de
ferramenta de busca encontrada foi escrita por concorrente direto.

**Periodicidade por tipo** (justificada com datas no grafo): ferramenta/preço de API **30 d** · lineup de
modelos **45 d** · mercado/capital **90 d** · benchmark **120 d** · doutrina **12 m ou gatilho nomeado**.
Roster: semanal (Anthropic Engineering + changelog, cursor.com/blog, TechCrunch/CNBC por M&A, HN por
trajetória) · mensal (State of AI newsletter, a16z, YC RFS) · trimestral (Thoughtworks Radar — maior densidade
por palavra —, Menlo, Gartner Hype Cycles, batch YC) · anual (SO Survey, State of AI Report, Forrester em outubro).

## Plano de execução (4 PRs, cada um com dogfood nomeado)

| Fase | Entrega | Dogfood | Custo est. | Gatilho |
|---|---|---|---|---|
| **F1 fundação** | peças 1–5 + bancada | `kg-corpus-grep "PreModelSwitch"` e `"instruction bloat"` devolvem os nós desta sessão | 300–500k | selo do maestro |
| **F2 motor** | peça 6 + skill auto-ativada + `radar-sources.yaml` + `/meta:radar --axis` ad-hoc | 1 pergunta real pequena (o NÃO-VERIFICADO *"teto de WebSearch por sessão"*), medindo custo/nó vs 68–74k do censo | 1–1,5M | F1 mergeado |
| **F3 decisão** | modo *para decidir* na skill: corpus → lacunas → pesquisa só nelas → Elenxo (refuta também **o que eu descartei**) → nó `decision` open | a decisão *"instruction bloat: o que podar"* | ~500k | F2 mergeado |
| **F4 revisita** | REGRA 65 varre `review_after` + roster; `/onion-research --revisit <grafo>` re-mede só STALE | revisitar o grafo mais velho do corpus | ~300k | F1 mergeado |

Gated, com gatilho nomeado no grafo: **poda do instruction bloat** (dispara no dogfood de F3); **busca como
SDAAL** (`.claude/utils/search/`, dispara quando o teto de WebSearch morder); routines na nuvem / cron local
para revisita (MOAT W7 — só o maestro).

## Não reinventar · não abandonar (o teste do capital)

- **Virou feature de outro → integrar:** observabilidade (ClickHouse comprou a Langfuse), orquestração
  multi-agente (Agent HQ, Copilot app; *coding agent swarms* em CAUTION), sandbox/permissões, scaffolding de
  spec (Kiro, spec-kit), certificação (AIUC-1 no STAR Registry).
- **Escasso → construir:** verificação, evals, governança auditável, memória temporal (Braintrust, Cognee,
  Potpie, Graphon financiados; *context graph* no Radar só em ASSESS — liderança de 1–2 ciclos).
- **Número externo para o `exit 2`:** o auto mode da própria Anthropic admite **17% de falso-negativo**
  (2026-03-25). O caminho probabilístico erra 1 em 6; o determinístico é o argumento.
- **Tese que caiu:** IDE proprietário como fosso (Cursor → SpaceX US$ 60B; Amp desmembrado; Windsurf comprado).

## Contra-sinal (dói, e por isso está aqui)

Thoughtworks Radar v34 pôs **agent instruction bloat em CAUTION** — e descreve as 52.655 linhas de markdown
acoplado do core. A cura recomendada (*progressive context disclosure*) o Claude Code já entrega: skills sob
demanda, rules por path, `!`cmd``. Consequência **neste** plano: a diretriz não engorda o CLAUDE.md; e nasce o
fio de poda `D_PODA_INSTRUCTION_BLOAT_MEDIDA` (gated no F3). O post de harness da Anthropic dá o critério:
*"suposições sobre o que o modelo não sabe expiram"* — instrução por limitação vencida sai.

## Lacunas declaradas

Gartner 403 (números via terceiro; MQ 2026 não obtido) · SO Survey 2026 sem resultados · State of AI 2026 não
publicado · OpenAI primário 403 · **teto de WebSearch por sessão não lido em fonte primária** · custos de busca
só em blogs de concorrentes · ARR/fatias do Claude Code só em agregadores · líderes nomeados não localizados ·
estrelas sem controle de inflação · Zep/Letta/Jina/MCP Perplexity-Brave/routine→workflow não verificados.
**Nada foi medido em dogfood nesta rodada** — todo número é externo; F1–F4 existem para medir.

## valeu-a-pena

4 workers opus + medição própria, ~1,2M tokens (estimado; o `Agent` não reporta por worker — o próprio plano
corrige isso ao usar `Workflow`, que reporta). Produto: 26 nós com fonte e data, 4 fases com dogfood e custo,
2 fios gated com gatilho, e uma resposta negativa medida (*não há doutrina de fontes*) que valia sozinha a rodada.
