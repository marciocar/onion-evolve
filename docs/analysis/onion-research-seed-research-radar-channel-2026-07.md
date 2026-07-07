# Semente de pesquisa — canal-radar de fontes de pesquisa × vigilância contínua sobre sinais externos

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Irmã direta de
> [onion-research-seed-smolagents-and-emerging-patterns-2026-07.md](onion-research-seed-smolagents-and-emerging-patterns-2026-07.md) —
> aquela é sobre UM alvo específico; esta é sobre o **mecanismo de vigilância recorrente** em si.

## Por que esta pesquisa

O maestro pede um canal de fonte de pesquisa que mantenha um **radar** sobre a investigação — não
uma pergunta única (isso é a semente `smolagents-and-emerging-patterns`), mas vigilância
*contínua* sobre o que emerge externamente.

**A forma já existe — para outro domínio.** `docs/knowledge-base/agentic-patterns/README.md`
documenta exatamente o padrão que esta semente precisa, só que para sinal **interno** (como o
próprio harness/IA se comporta no dogfood do maestro), não externo (o que emerge no ecossistema
de IA/agentes fora do Onion):

> *"campo → field-observations/ (captura rápida, sem polir) → assess (pelo maestro) →
> harness/ ou ai-strategies/ (entrada formal, distilada)"*
> *"Espelha o ciclo inbox/ → triagem → core do Onion. A observação bruta é o insumo; a entrada
> formal é o produto. Não pular a observação — o campo sabe antes da teoria."*

Há também um precedente concreto, embora pontual e não recorrente: um sinal externo real
(HeyClicky, roteamento de modelo) chegou pelo canal `docs/evolution/inbox/`, foi avaliado, e
recebeu veredito preliminar registrado. Isso prova que o mecanismo de "sinal externo → avaliação →
veredito" já funciona **uma vez** — falta a parte de **buscar de novo, sempre**.

**A mecânica de cadência recorrente não precisa ser inventada** — já existe como ferramenta
pronta: as skills `/loop` (self-paced ou intervalo fixo) e `schedule`/`CronCreate` (agentes cloud
em cron). O que falta não é "como vigiar de novo e de novo" — é decidir **o quê** entra no radar,
**onde** a captura bruta aterrissa, e **quem** faz a curadoria periódica (o mesmo "assess pelo
maestro" que já existe pro sinal interno).

## Questões de pesquisa

**Q1 — Reaproveitar `field-observations/` (com um campo `domain:` novo) ou criar uma pasta-irmã?**
A forma é a mesma (captura bruta → curadoria → promoção); o domínio é diferente (dogfood interno
vs. ecossistema externo). Misturar no mesmo lugar economiza estrutura, mas pode confundir "o que
aprendemos usando IA" com "o que o mercado de IA está fazendo" — categorias de conhecimento
diferentes, ritmos de mudança diferentes (tensão com `fonte≠derivação` se ficarem juntas).

**Q2 — Quais fontes primárias compõem o radar?** A semente `smolagents` já nomeia o requisito de
método (fontes primárias — repos, papers, release notes — não digestão secundária). Esta semente
precisa decidir a LISTA: quais repos/newsletters/arXiv categories/changelogs entram na vigilância
recorrente, e com que frequência cada um é checado (nem toda fonte muda no mesmo ritmo).

**Q3 — Cadência: `/loop` (sessão ativa) ou `schedule`/cron (agente autônomo)?** `/loop` exige uma
sessão viva rodando; `schedule`/`CronCreate` roda sem o maestro precisar estar na frente. Pra um
radar de pesquisa que deveria funcionar "no fundo", cron parece mais alinhado — mas isso ainda
precisa de decisão humana no momento de curadoria (ver `field-observations/`: "assess pelo
maestro" nunca é automático). Como desenhar isso sem virar "IA decide sozinha o que é relevante"?

**Q4 — O que dispara a promoção pra fora do radar (pra uma semente formal, um sinal de inbox, ou
uma nota de doutrina)?** O padrão `field-observations/` já tem esse fluxo pro caso interno — esta
semente deveria adaptar o mesmo critério, ou o "vale a pena" externo é qualitativamente diferente
(ex.: relevância de mercado vs. relevância de comportamento de harness)?

## Método previsto

Não é pesquisa externa em si — é desenho de mecanismo. Primeiro decidir Q1-Q4 (decisão
estrutural, não pesquisa); só depois disso a primeira rodada real de captura roda (usando o
mecanismo desenhado) sobre as fontes decididas em Q2. Ponto de partida honesto: esta semente
description a si mesma — o radar só nasce depois de alguém (o maestro) decidir sua própria forma,
o que é justamente o "sem julgamento ainda" que motivou toda esta rodada de sementes.

## Gatilho

O maestro pede ("vamos montar o canal-radar") → executar a partir DESTA semente, começando pelas
decisões estruturais (Q1-Q4), não pela captura. Registro na memória da sessão:
`sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
