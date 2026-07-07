# Semente de pesquisa — repos-padrão por tier, do core ao standalone × a federação já existente

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). Diferente das sementes de modelo (1/2/8/9), esta
> **não colide com nenhuma rejeição prévia** — é extensão natural de infraestrutura que já existe.

## Por que esta pesquisa

Agora que o onion-mini existe oficialmente (destilação pública, sem vendorizar `.claude/`), o
maestro pergunta: podemos criar versões-padrão de repo por tier, do core ao standalone, para
distribuição controlada e gradual — sem dar acesso ao core — seguindo o modelo de federação já
existente?

**A parte de controle de acesso já existe, pronta, validada.** Os 4 adapters de trust
(`.claude/utils/trust/adapters/{source,hub,consumer,standalone}.md`) já são uma matriz
determinística de "quem recebe/vê o quê por tier", verificada por
`trust-topology-check.sh --dry-run`:

| Tier | O que recebe do core | O que vê de outros |
|---|---|---|
| **hub (T1)** | tudo, autorizado sempre | peers T1 só se em `can_receive_from`; T2 filhos sempre |
| **consumer (T2)** | *não diretamente* — só via hub, que decide propagar | só `public`, filtrado pelo hub |
| **standalone (T3)** | tudo, autorizado sempre | nada — nem `members.yaml` completo (só a própria entrada + a do core) |

RFC-0003 já define os 4 tiers formalmente (§2.1) e uma classificação de dados em 6 níveis
(`private → protected → peer → downstream → public → collective`). Isso não precisa ser
inventado — já é Trust SDAAL em produção.

**O que falta é mecânico, não conceitual.** Comparando `onion-mini` (destilação) com `pulse-mais`
(adoção padrão) no `members.yaml`: ambos usam `role: standalone` — a diferença entre "adotou o
framework" e "foi destilado a partir dele" é hoje só **anotação textual** (`mode: distilled`,
`onion_version: n/a`) e um ADR em prosa
([`onion-adr-mini-distillation-2026-07.md`](onion-adr-mini-distillation-2026-07.md), decisão D2),
não uma distinção mecânica no trust engine. O próprio ADR já nomeia isso como pendência: um
`role: distilled` formal é **"costura gated — só na 2ª destilação real"** (rampa M4, ainda não
disparada).

Achado lateral relevante: já existe, de fato, uma "família multi-plataforma" — onion-cursor,
onion-codex, onion-copilot, onion-zed, onion-antigravity — citada no próprio ADR do Mini como
existente, mas **não registrada na federação** (`members.yaml`). Distribuição controlada por tier
já está acontecendo informalmente; só não está rastreada.

## Questões de pesquisa

**Q1 — "Repos-padrão por tier" significa gerar repos novos, ou classificar os que já existem?**
Duas leituras bem diferentes: (a) tooling de **scaffolding automático** — o core gera
automaticamente uma variante-standalone/hub/consumer a partir de si mesmo, sob demanda; (b)
**registrar formalmente** a família multi-plataforma já existente (cursor/codex/copilot/zed/
antigravity) na federação, com o `role: distilled` que já foi nomeado e gated. (b) é
imediatamente executável com o que já existe; (a) é uma peça de tooling nova.

**Q2 — Vale a pena o `role: distilled` formal agora?** O ADR do Mini marcou isso como gated até
"a 2ª destilação real". A família multi-plataforma já teria mais de uma destilação candidata
(onion-cursor, onion-codex, etc.) — isso já dispara o gatilho, ou o gatilho exige que essas outras
destilações sejam trabalho ativo e verificado, não só citadas de passagem?

**Q3 — "Sem dar acesso ao core" — isso já está garantido, ou precisa de reforço?** A tabela de
trust já impede `standalone` de ver `members.yaml` completo ou qualquer coisa alem de `public`/
`collective` do core. A pergunta prática: o pedido do maestro já está satisfeito pela infra atual,
ou ele quer graus intermediários que a matriz de 4 tiers não modela hoje (ex.: standalone com
acesso a MAIS que `public` mas menos que hub)?

**Q4 — Onde entra o Onion Mini nessa hierarquia?** Ele é T3 (`role: standalone`) mas
qualitativamente diferente de um standalone-por-adoção — é standalone-por-destilação. Se a
resposta a Q1 for "registrar a família", esse cluster de destilações vira um 5º padrão implícito
(nem hub, nem consumer, nem standalone-adotante — "standalone-destilado"), o que talvez precise de
nome próprio no vocabulário controlado (`onion-relation-vocabulary.md`), não só de um campo
`mode:` livre.

## Método previsto

Não é pesquisa externa — é decisão de arquitetura interna. Primeiro resolver Q1 (o que
"repos-padrão por tier" realmente quer dizer) com o maestro; depois, se a resposta for a leitura
(b), o trabalho é quase administrativo: registrar a família multi-plataforma real no
`members.yaml` com a anotação de destilação já em uso pelo onion-mini. Se for a leitura (a),
precisa de uma sessão de design de tooling nova (scaffolding automático), fora do escopo desta
semente.

## Gatilho

O maestro pede ("vamos formalizar a distribuição por tier") → executar a partir DESTA semente,
começando pela resolução de Q1. Registro na memória da sessão:
`sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
