# Semente de pesquisa — smolagents e estratégias emergentes × o que o Onion pode extrair

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). **Pesquisa externa real ainda não rodou** — por
> decisão explícita do maestro ao aprovar o plano desta rodada (todas as 10 sementes ficam no
> mesmo estágio: plantadas, não executadas).

## Por que esta pesquisa

O maestro ouviu falar do projeto **smolagents** (framework leve de agentes, Hugging Face) e isso
disparou uma pergunta mais ampla: quais estratégias inovadoras — já consagradas ou "explodindo
silenciosamente" nas fontes onde a informação aparece primeiro (papers, repos, changelogs, não
ainda em blogposts de segunda mão) — o Onion pode extrair pedaços para usar.

**Não há doutrina prévia direta sobre mineração de prior art de projetos específicos no Onion.**
O que existe é um processo ad-hoc, já usado uma vez, de avaliar um sinal externo chegado pelo canal
de co-evolução: `docs/evolution/inbox/_processed/2026-06-20-heyclicky-model-routing-signal.md`
(sinal sobre roteamento de modelo do projeto HeyClicky), que recebeu avaliação e veredito
preliminar (não adotar, "complexidade > ganho"). Isso mostra que o Onion já sabe **avaliar** um
sinal externo pontual — mas não tem um canal dedicado a **buscar** sinais continuamente (essa
lacuna é o assunto da semente-irmã `research-radar-channel`).

Grounding de mercado já absorvido, sem ser pesquisa nova:
[`panorama-ia-generativa-2026-06.md`](panorama-ia-generativa-2026-06.md) chama SLMs de *"a tese
mais subestimada do ano"*, cita paper da NVIDIA (servir 7B custa 10-30x menos que 70-175B) e o
arXiv *"Small Language Models are the Future of Agentic AI"* (arxiv.org/html/2506.02153v2) — bom
ponto de partida, mas é sobre SLMs em geral, não especificamente sobre smolagents ou frameworks
leves de orquestração de agentes.

## Questões de pesquisa

**Q1 — O que smolagents faz de fato, e o que disso já existe no Onion sob outro nome?** Antes de
extrair qualquer "pedaço", mapear a arquitetura real do smolagents (agentes leves, tool-calling
minimalista, poucas dependências) contra os padrões já canônicos do Onion
(`agent-orchestration.md`, os 6 padrões da Anthropic) — o que é genuinamente novo, e o que é
reinvenção com nome diferente?

**Q2 — Onde a informação "aparece primeiro"?** O maestro nomeia isso explicitamente — quer as
fontes primárias (repos, release notes, papers, RFCs de frameworks), não a versão já digerida em
newsletter. Isso é, em si, um requisito de método pra qualquer pesquisa desta semente e da semente
`research-radar-channel`: preferir GitHub/arXiv/documentação oficial a artigos secundários.

**Q3 — Qual o critério de "vale extrair"?** O sinal HeyClicky já mostrou o filtro em ação
("complexidade > ganho no modelo spec-as-code"). Essa pesquisa deveria produzir critério explícito
e reutilizável — não decidir smolagents-sim/smolagents-não isoladamente, mas nomear o que faz um
padrão externo valer a pena importar (ou não) pro Onion, pra ser aplicado de novo em achados
futuros do radar.

**Q4 — Outros projetos na mesma vizinhança.** smolagents não deveria ser o único objeto — a
pesquisa deveria varrer pelo menos 2-3 outros frameworks leves de agentes emergindo na mesma janela
de tempo (ex.: outros projetos minimalistas de orquestração, frameworks de tool-use leve) pra não
enviesar em um único ponto de dado.

## Método previsto

Deep-research harness com fan-out multi-fonte: (1) repositório real do smolagents (código,
release notes, issues de design) — fonte primária, não secundária; (2) 2-3 frameworks vizinhos na
mesma categoria (agentes leves/minimalistas); (3) cruzamento com `agent-orchestration.md` e
`onion-engine-economy.md` pra achar sobreposição/novidade real. Achados que sobreviverem à
verificação adversarial (é genuinamente novo? vale a complexidade?) viram candidatos a entrada em
`agentic-patterns/ai-strategies/` (a KB viva de estratégias, não a rejeitada `onion-engine-
economy.md` §5) ou ficam registrados como "avaliado, não adotado" seguindo o precedente HeyClicky.

## Gatilho

O maestro pede ("roda a pesquisa do smolagents") → executar a partir DESTA semente. Registro na
memória da sessão: `sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
