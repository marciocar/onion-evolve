# S3 — Observabilidade / Console / Mapa da Federação Onion

> Stream de pesquisa para o redesign da federação (2026). Foco: como dar ao maestro um
> **lugar para VER** as comunicações, o histórico e as relações — e um **mapa de adoções
> derivado de dados** — sem transformar o Onion numa plataforma pesada. Cada achado material
> traz FONTE (URL). Onde a evidência é indireta, marco como hipótese.

## Resumo executivo

A pesquisa converge para uma conclusão forte e alinhada à identidade do Onion (framework
template, sem CLI/produto, VPS única com Caddy): **construir uma plataforma de developer
portal tipo Backstage/Port seria over-engineering caro e desalinhado**; o mínimo que resolve
as dores P0-3 (falta console) e P0-4 (falta mapa) é um **site estático append-only gerado
dos dados que o Onion JÁ tem** — `members.yaml` (SSOT de relações) + o CHANGELOG do doc-bridge
(SSOT append-only de eventos) + `graph.sh` (motor de topologia). O padrão canônico é:

1. **Event log já existe** — o CHANGELOG com campo `alvo:` é, literalmente, um append-only
   event log versionado em git (o git é, por design, um append-only log de escritor único —
   exatamente o modelo "entrega-sem-commit" do Onion). Não precisa de EventStore/Kafka; precisa
   de um **read-model/projeção** (CQRS leve) gerada por script.
2. **Mapa = projeção do grafo** — `members.yaml` é um grafo de entidades+relações (idêntico em
   forma ao modelo de blueprints/relations do Port e ao catalog-graph do Backstage). O Onion já
   tem o motor (`graph.sh`); falta **ingerir `members.yaml`** e **renderizar** (Mermaid para o
   estático/docs; Cytoscape.js se precisar de exploração interativa).
3. **Deploy = o que já roda** — Caddy `file_server` + HTTPS automático na VPS KVM 8, subdomínio
   de `onionevolve.com`. Zero backend novo; regenera no CI/hook e serve arquivos estáticos.

A escolha de ferramenta é quase decidida pela forma do problema: **Mermaid para diagramas/docs,
Cytoscape.js se o grafo virar objeto de análise interativa, D3 só se precisar de visual custom**.
Para o console/feed, **Alpine.js sozinho** (carrega JSON no cliente, sem backend, ~15KB) cobre
filtro/timeline navegável. Isso ataca também a P0-2 (ruído): um console que **projeta** o
`members.yaml` torna visível o targeting por `specializations`/`mode`/`classificação` que o
targeting `alvo:` hoje ignora — ver não resolve o roteamento, mas expõe o que roteia.

---

## Achados

### F1 — Backstage self-hosted é caro e é framework, não produto (build-vs-buy pende p/ "buy" ou "não-portal")
**Claim:** Self-hostar Backstage custa 3+ engenheiros de plataforma dedicados
(US$300k–450k/ano só de manutenção, TCO de 1º ano > US$800k), leva ~9 meses até produção, e
"Backstage não é um developer portal; é um framework para construir um". Catálogos crescem para
centenas/milhares de `catalog-info.yaml` e "batem no limite do YAML puro em git".
**Fonte:** https://roadie.io/blog/the-true-cost-of-self-hosting-backstage/ ·
https://dev.to/riya_mittal_cdd264250ad45/backstage-is-not-free-the-real-tco-of-building-vs-buying-an-internal-developer-platform-5ce
**Materialidade:** high
**Implicação p/ Onion:** Decide o BUILD-VS-BUY do stream: para uma federação de ~5 membros com
maestro-único, **adotar Backstage/Port seria absurdo de custo e desalinhado** (Onion não é
produto npm, não tem time de plataforma). Reforça o caminho "site estático simples gerado do
`members.yaml`". Ironia útil: o problema do "YAML puro em git bate no limite" é o oposto no
Onion — 5 membros num `members.yaml` é exatamente a escala onde YAML-em-git é a resposta certa,
não o gargalo. Informa P0-3/P0-4 pela negativa (o que NÃO fazer).

### F2 — O padrão de mercado para portal é "grafo dinâmico de entidades+relações" — igual ao members.yaml
**Claim:** O Port modela o portal como "um grafo dinâmico de todas as suas entidades em
contexto, não uma lista estática": *blueprints* (schema das entidades) + *relations* (conexões
que capturam dependências, single ou multiple) formam um "grafo dinâmico de banco de dados".
Entidades vão além de serviços — times, ambientes, recursos.
**Fonte:** https://www.port.io/blog/what-you-need-to-know-about-the-data-model-in-an-internal-developer-portal
**Materialidade:** high
**Implicação p/ Onion:** Validação externa de que o **`members.yaml` já É o data-model certo**:
membros = entidades (com schema: tier/role/specializations/mode/trust), `parent`/`trust.*` =
relations. O Onion não precisa adotar Port — precisa tratar `members.yaml` como o grafo que o
Port cobraria para modelar. Ataca P0-4 (mapa derivado) e P0-2 (o `trust.can_advise_to`,
`specializations`, `mode` são as *relations* que o targeting `alvo:` deveria usar e o console
deveria mostrar).

### F3 — Event Sourcing + CQRS: o log append-only é a fonte, feeds/dashboards são projeções (read-models)
**Claim:** Event Sourcing grava mudanças como eventos imutáveis num append-only store; CQRS
separa o write-model do read-model; **projeções escutam eventos e mantêm views denormalizadas
para query rápida** — o log "naturalmente provê um audit trail robusto". O LinkedIn usa Event
Sourcing para activity feeds: cada ação é um evento, projeções constroem feeds personalizados.
**Fonte:** https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing ·
https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs
**Materialidade:** high
**Implicação p/ Onion:** Dá o *shape* arquitetural do console sem infra: o **CHANGELOG (campo
`alvo:`) é o event store append-only** que o Onion já tem; o console é uma **projeção/read-model
read-only** gerada por script (CQRS leve). Não muta o log — lê e reporta, exatamente como
`/meta:federation-status` já faz. Ataca P0-3: "histórico" = a projeção do CHANGELOG; "activity
feed" = timeline por membro. Nada de EventStore/Kafka.

### F4 — Audit-log via event sourcing é padrão consagrado; databases dão "audit table" sem a complexidade toda
**Claim:** Um comprehensive event log provê audit trail para accountability/compliance/forensics;
para casos leves, "audit table" e temporal tables capturam histórico com impacto mínimo, "sem a
complexidade do Event Sourcing" completo.
**Fonte:** https://blog.arkency.com/audit-log-with-event-sourcing/ ·
https://martinfowler.com/eaaDev/AuditLog.html
**Materialidade:** medium
**Implicação p/ Onion:** Confirma que o Onion **não precisa do Event Sourcing "completo"** (sem
replay de estado, sem aggregates) — precisa só do audit-log navegável. O CHANGELOG + `co-*`
já são o "audit table". Encaixe com a doutrina Onion "entrega-sem-commit / um escritor por repo"
(single-writer append-only). Ataca P0-3.

### F5 — Git JÁ é um append-only log de escritor único — o Onion não precisa de outro event store
**Claim:** "Git usa um modelo de append-only log no seu núcleo: quando você commita, entradas
são adicionadas ao histórico e versões antigas nunca são modificadas". Em logs append-only "só
um escritor pode chamar Append() por vez". Existem projetos (`git-ledger`) que tratam cada
registro como um ref/commit para ter histórico completo.
**Fonte:** https://medium.com/@komalshehzadi/append-only-logs-the-immutable-diary-of-data-58c36a871c7c ·
https://docs.rs/git-ledger/latest/git_ledger/
**Materialidade:** high
**Implicação p/ Onion:** Fecha a decisão de infra: o **transporte git-async do doc-bridge já é o
event store**. O `git log` do CHANGELOG + dos canais `inbox/inbound` É o histórico auditável.
O console lê `git log --follow` / o CHANGELOG e projeta — **zero banco de dados**. O modelo
"single writer / entrega-sem-commit" do Onion é literalmente a garantia de consistência do
append-only log. Ataca P0-3 e casa com a federação formal (ledger de contratos + CHANGELOG).

### F6 — Escolha de lib de grafo é decidida pela FORMA do problema, não por preferência
**Claim:** Em 2025-26 os três ocupam nichos não-sobrepostos: **Mermaid** para diagramas de
documentação (texto→diagrama, renderizado nativamente no GitHub/PRs, ~3M downloads/semana);
**D3.js** para visualização custom de baixo nível (controle total, curva íngreme); **Cytoscape.js**
quando "o grafo é um objeto de análise" (algoritmos, layouts, centralidade, pathfinding).
**Fonte:** https://www.pkgpulse.com/guides/mermaid-vs-d3-vs-chartjs-diagrams-data-visualization-2026 ·
https://js.cytoscape.org/ · https://www.pkgpulse.com/guides/cytoscape-vs-vis-network-vs-sigma-graph-visualization-2026
**Materialidade:** high
**Implicação p/ Onion:** Guia direto de tooling do mapa (P0-4): comece com **Mermaid** (o mapa
de adoções como `graph TD` gerado do `members.yaml`, renderiza em docs/GitHub sem build);
promova a **Cytoscape.js** só se/quando o maestro quiser *explorar* o grafo (BFS interativo,
filtro por specialization, highlight de impacto) — o que casa com o `graph.sh` (que já faz
impact/path/closure). D3 provavelmente é excesso. Reuso, não reinvenção: `graph.sh` gera o
modelo, Mermaid/Cytoscape só renderiza.

### F7 — Backstage catalog-graph mostra o padrão de UX de "relationship graph" a copiar barato
**Claim:** O plugin Catalog Graph do Backstage: card por-entidade com vizinhos diretos + página
full para explorar o grafo maior; filtra por *kind*/*relation*, muda direção do layout, define
*max depth*, escolhe render das edges. Responde "que serviços consomem esta API, quem é dono
disto, o que esta mudança afeta".
**Fonte:** https://backstage.io/docs/features/software-catalog/creating-the-catalog-graph/ ·
https://roadie.io/backstage/plugins/catalog-graph/
**Materialidade:** medium
**Implicação p/ Onion:** Especifica a UX-alvo do mapa/console sem adotar o Backstage: **max-depth
+ filtro por relation + "o que esta mudança afeta"** são EXATAMENTE as três queries do
`graph.sh` (closure, path, impact reverso). "Que membros esta co-evolução `alvo:` afeta?" é a
query de impacto sobre `members.yaml`. Copie a UX (card de vizinhos + página de exploração),
não a stack. Ataca P0-2 (visualizar quem um `alvo:` atinge antes de enviar) e P0-4.

### F8 — Gerar Mermaid a partir de YAML é padrão maduro (YAMLtecture, scripts em CI)
**Claim:** "Documentation as Code": scripts parseiam YAML e emitem pseudocódigo Mermaid,
renderizado via Mermaid CLI em CI/CD. **YAMLtecture** é um CLI leve cujo princípio é "um único
YAML config gera múltiplos diagramas Mermaid; mudou a arquitetura, muda o YAML e regenera".
Ferramentas convertem Docker Compose / GitHub Actions YAML em diagramas.
**Fonte:** https://medium.com/@jaredhatfield/introducing-yamltecture-d94fef51e3e5 ·
https://www.avonture.be/blog/docker-python-mermaid/
**Materialidade:** high
**Implicação p/ Onion:** Prova de viabilidade direta da P0-4: **`members.yaml` → script →
Mermaid** é um caminho batido. O "single source → múltiplos diagramas regenerados" é
precisamente a relação `members.yaml` → (mapa de tiers, mapa de trust, mapa de specializations).
Regenerar num hook/CI mata o "mapa desenhado à mão" do site. Encaixa como um passo novo no
`graph.sh` (emitir Mermaid além do seed atual) ou um script irmão em `.claude/validation/`.

### F9 — `yst`: site estático a partir de YAML/CSV/SQLite, sem servidor, com transformações embutidas
**Claim:** `yst` gera sites estáticos combinando dados YAML/CSV/SQLite com templates; faz
sort/filter/group/limit **sem chamadas a banco**, rebuild incremental, saída HTML pura "sem
dependências de runtime". "Combina velocidade/segurança/deploy fácil de site estático com a
flexibilidade de um site dinâmico que separa apresentação de dados".
**Fonte:** https://github.com/jgm/yst
**Materialidade:** medium
**Implicação p/ Onion:** Existe precedente exato de "site estático data-driven a partir de YAML".
O Onion provavelmente NÃO adota `yst` (Haskell, dependência estranha ao stack) mas ele valida o
*padrão* e o menu de features que o gerador do console precisa: filtro/sort/group sobre
`members.yaml` + CHANGELOG, saída HTML estática. Um script bash/python + template é suficiente e
mais alinhado. Ataca P0-3/P0-4.

### F10 — Caddy file_server + HTTPS automático é o deploy mínimo (e o Onion JÁ o roda na VPS)
**Claim:** Caddy é servidor moderno com HTTPS automático; servir site estático é `file_server` +
TLS Let's Encrypt automático, "forma simples e eficiente de hospedar um site"; Caddy até adapta
config de YAML/TOML/etc.
**Fonte:** https://caddyserver.com/docs/quick-starts/static-files ·
https://caddyserver.com/
**Materialidade:** high
**Implicação p/ Onion:** Fecha a questão de deploy com **reuso total da infra existente**: o
`members.yaml` documenta que a KVM 8 já serve `onionevolve.com` via Caddy `file_server` + TLS
auto e já tem `app.onionevolve.com → reverse_proxy` para o bridge. O console/mapa é só **mais
um `file_server` num subdomínio** (ex. `console.onionevolve.com` ou `map.onionevolve.com`),
regenerado por hook. Nenhum serviço novo, nenhum backend. Viabilidade VPS = confirmada e barata.

### F11 — Alpine.js sozinho cobre "dashboard de JSON sem backend"; htmx precisaria de servidor
**Claim:** Para dashboard interno de arquivo único que carrega JSON **sem backend**, "Alpine.js
sozinho é a melhor escolha" — carrega e transforma JSON no cliente, ~15KB, sem build step
(script tag, sem npm/webpack). htmx é server-driven (troca fragmentos HTML vindos do servidor),
logo exige backend; combinar os dois é o "sweet spot" quando há servidor.
**Fonte:** https://www.infoworld.com/article/3856520/htmx-and-alpine-js-how-to-combine-two-great-lean-front-ends.html ·
https://www.pkgpulse.com/guides/htmx-vs-alpinejs-2026
**Materialidade:** medium
**Implicação p/ Onion:** Escolha de front-end do console: como o Onion quer **estático sem
backend** (Caddy file_server), **Alpine.js** é o casamento certo para o interativo leve (filtro
do feed, toggle de tier, busca no audit log) lendo um `feed.json`/`members.json` gerado do
CHANGELOG/`members.yaml`. Evita a tentação do htmx (que arrastaria um backend e contradiria a
identidade "sem serviço"). Ataca P0-3 (console navegável) mantendo o mínimo.

### F12 — UX de audit-log 2025: side-drawer + navegação por teclado + filtro que "isola em poucos cliques"
**Claim:** Padrões modernos de audit-log: navegação por setas do teclado entre registros com
side-drawer aberto (revisar detalhe **sem sair da tabela** e voltar à posição), densidade/tipografia
para reduzir fadiga de leitura, e **cada filtro isola eventos relevantes em poucos cliques** (ex.
filtrar por membro para ver só as ações dele).
**Fonte:** https://help.gohighlevel.com/support/solutions/articles/155000006667-audit-logs ·
https://aiuxplayground.com/pattern/audit-trail/
**Materialidade:** medium
**Implicação p/ Onion:** Especifica a UX do console de histórico (P0-3): tabela do CHANGELOG +
side-drawer com o conteúdo do anúncio + **filtro por membro/`alvo:`/classificação**. O filtro
"por membro em poucos cliques" é a contrapartida visível da P0-2: se o console filtra por
`specialization`/`mode`, torna óbvio para o maestro que o targeting deveria fazer o mesmo. Barato
de fazer em Alpine.js sobre `feed.json`.

### F13 — CQRS/Event Sourcing: comece pequeno, um bounded context, não a plataforma toda
**Claim:** Recomendação prática 2025: "comece pequeno — pegue um único bounded context e
implemente com framework leve"; projeções mantêm views denormalizadas para query rápida; audit
via tabela evita a complexidade do ES completo.
**Fonte:** https://www.javacodegeeks.com/2025/10/cqrs-and-event-sourcing-in-practice-building-scalable-systems.html
**Materialidade:** low
**Implicação p/ Onion:** Reforça a disciplina de escopo: o console v1 deve cobrir **um único
"bounded context" — a federação (membros + comunicações)** — não virar dashboard de tudo.
Projeção read-only, regenerada, descartável. Anti-plataforma. Governa o roadmap de P0-3/P0-4.

---

## Encaixe nas fundações / viabilidade VPS

**Mapeamento dor P0 → achado → fundação reusada:**

| Dor P0 | Achados-chave | Fundação Onion reusada (não reinventar) |
|---|---|---|
| **P0-1** core↔core vivo (Grana.Ai isolada) | F3, F5 (event log em git é o transporte); tangencial | SDAAL → `federation-transport` (git-async default; a2a-live como 2º transporte). O console é **read-model** sobre qualquer transporte; não resolve o canal vivo, mas dá a ele um lugar para aparecer. |
| **P0-2** ruído no targeting `alvo:` | F2, F6, F7, F12 (grafo de relations; filtro por specialization/mode) | `members.yaml` já tem `specializations`/`mode`/`trust.*`; `graph.sh` faz a query de impacto. Console **expõe** o roteamento correto; o fix do targeting é do stream de roteamento, mas a visibilidade nasce aqui. |
| **P0-3** falta console/histórico/relações | F3, F4, F5, F9, F11, F12, F13 | **CHANGELOG (campo `alvo:`) = event store append-only**; console = projeção CQRS read-only (Alpine.js sobre `feed.json` gerado do `git log`/CHANGELOG). Espelha `/meta:federation-status` (já read-only). |
| **P0-4** mapa de adoções derivado | F2, F6, F7, F8, F9 | **`members.yaml` = grafo de entidades+relations**; `graph.sh` = motor (precisa **ingerir `members.yaml`** — hoje não ingere). Emitir **Mermaid** (estático/docs) e/ou Cytoscape.js (interativo). Mata o mapa desenhado à mão. |

**Arquitetura mínima recomendada (síntese da evidência, não doutrina):**

```
members.yaml ──┐                    ┌── map.mmd (Mermaid: tiers, trust, specializations)
               ├─► graph.sh (+ingest)┤
CHANGELOG ─────┤   + script projeção ├── feed.json  (audit-log projetado do git log)
(alvo:, inbox) ┘                     └── members.json (entidades+relations)
                                              │
                                     site estático (HTML + Alpine.js, ~15KB, sem build)
                                              │
                                     Caddy file_server + TLS auto  (KVM 8, já roda)
                                              │
                                     console.onionevolve.com  (regen por hook/CI)
```

**Por que isso é "mínimo" e não vira plataforma pesada:**
- **Sem backend, sem DB, sem serviço novo** (F5, F10, F11): git é o event store, Caddy já serve
  estático, Alpine.js roda no cliente. O único código novo é **script de projeção** (bash/python)
  + **template HTML** + **ingest de `members.yaml` no `graph.sh`**.
- **CQRS leve read-only** (F3, F4, F13): projeção descartável; se o CHANGELOG é a verdade, o
  console pode ser regenerado do zero a qualquer momento — nunca é fonte, nunca corrompe estado.
- **Build-vs-buy resolvido pela escala** (F1): Backstage/Port fazem sentido a 200–1000+ devs com
  time de plataforma; a federação Onion tem 5 membros e um maestro — o custo de qualquer portal
  comercial/self-hosted é 1–2 ordens de grandeza acima do valor. O estático gerado é a resposta.
- **Tooling decidido pela forma** (F6): Mermaid primeiro (renderiza em docs/GitHub sem build,
  serve o "mapa" já hoje); Cytoscape.js só se o grafo virar objeto de exploração interativa —
  e aí reusa o BFS do `graph.sh`.

**Riscos / lacunas honestas:**
- **P0-1 não é resolvida por este stream** — console/mapa dão *observabilidade*, não o canal
  core↔core vivo. Hipótese: o `federation-transport` (SDAAL, F3/F5) é onde isso mora; o console
  só torna visível o que trafega.
- **`graph.sh` ainda não ingere `members.yaml`** (fato interno declarado no briefing) — é o
  pré-requisito técnico do mapa derivado (F8). Baixo esforço, alto retorno.
- **Cross-host redirect / render de Mermaid grande**: Mermaid degrada em grafos muito grandes;
  a 5 membros é não-problema, mas se a federação crescer para dezenas, migrar o mapa para
  Cytoscape.js (F6) é o caminho — mantendo `graph.sh` como motor único.

---

## Verificação adversarial

> Passe cético "evidência ou abstenção" (2026-07-09). Cada achado material foi testado contra a
> própria fonte (WebFetch/WebSearch), procurando refutação ou exagero. Veredito: **confirmed**
> (fonte sólida sustenta) · **hypothesis** (plausível, mas a fonte citada não sustenta os
> específicos load-bearing) · **refuted** (fonte fraca/errada/contradita). Achado das citações:
> a decisão de tooling é sólida, mas **vários findings ancoram no primeiro URL quando o específico
> só é sustentado por um segundo URL co-citado** — a conclusão não muda, o rastro de evidência sim.

| Finding | Veredito | Nota |
|---|---|---|
| **F1** | confirmed | Fonte roadie sustenta tudo verbatim: "at least three dedicated engineers"; "$450,000 per year"; 1º ano "exceeds $800,000" (450k + ~200k de valor adiado em 9 meses); "Time to production: 6–12 months"; e literal "Backstage is not a developer portal. It's a framework for building one." O "US$300–450k" do claim é levemente mais largo que os $450k da fonte (limite inferior sem origem explícita), mas dentro da faixa. |
| **F2** | confirmed | Port descreve o data-model como grafo: "a graph of how everything is related to everything"; blueprints = "customizable schema definitions"; relations conectam entidades; entidades vão além de serviços (times/ambientes/recursos/incidentes). O "exatamente a forma do members.yaml" é **inferência do pesquisador**, não afirmação da fonte — mas o claim de padrão-de-mercado está sustentado. |
| **F3** | confirmed | Microsoft Learn sustenta o núcleo integralmente: append-only immutable store como system of record; materialized views = "read-only projections... optimized for querying"; combinação com CQRS (read/write separados); "append-only event storage provides an audit trail". **Ressalva:** a atribuição "LinkedIn usa isso para activity feeds" **não está** nas fontes Microsoft citadas — é embelezamento não-sourced pelo achado. O shape arquitetural (load-bearing) não depende dela. |
| **F4** | confirmed | Arkency sustenta ES como pattern maduro de audit-log ("excellent tool for an audit log") **e** a concessão "You don't have to go all in with events. Event sourcing is a great technique but it's not required for audit logs." **Ressalva:** o específico "audit table / temporal tables" não está no post da Arkency; apoia-se no Martin Fowler (AuditLog) co-citado no achado. Materialidade medium — ok. |
| **F5** | confirmed | Fonte medium sustenta verbatim: "Git... uses an append-only log model at its core. When you commit changes, they are added... old versions of files are never modified." **Ressalva:** o "escritor único / só um Append por vez" **não** aparece nesta fonte (a busca confirmou ausência); é propriedade real/genérica de append-only logs, mas não-citada aqui. A conclusão load-bearing (git-async do doc-bridge = event store) sustenta-se. |
| **F6** | confirmed | Mermaid (text→diagram, "GitHub renders natively", ~3M/semana) e D3 (custom low-level, ~5M/semana) confirmados pelo 1º guia. Cytoscape ("Pick Cytoscape.js when the graph is an analysis object: algorithms, layouts, centrality, path finding") confirmado pelo 2º guia co-citado. **Ressalva material:** o URL primário do achado (`mermaid-vs-d3-vs-chartjs`) **não menciona Cytoscape.js** — compara Mermaid/D3/**Chart.js**. O enquadramento tríplice só fecha com o 2º URL (`cytoscape-vs-vis-network-vs-sigma`), que o achado lista. |
| **F7** | confirmed | Features do plugin Catalog Graph confirmadas pelo roadie co-citado: card de vizinhos + página de exploração; "filter by kind or relation, change layout direction, set max depth, and choose how edges render"; responde ownership/impacto. **Ressalva:** o URL primário (`backstage.io/.../creating-the-catalog-graph`) é **conceitual** (nodes/edges/relations) e **não** detalha a UX do plugin — os específicos vêm do 2º URL. |
| **F8** | confirmed | YAMLtecture confirmado: "a single config that you would want to generate multiple Mermaid diagrams from" e regeneração ao mudar o YAML. **Ressalva menor:** "regenerado em CI" **não** é explícito no artigo (pipes automation-friendly; a parte CI/render vem do avonture.be co-citado). Núcleo do claim sustentado. |
| **F9** | confirmed | GitHub jgm/yst sustenta verbatim: gera site estático de "YAML or CSV text files or SQLite3"; sort/filter/group/limit; "pure HTML files with no runtime dependencies". Precedente do padrão data-driven estático confirmado. |
| **F10** | confirmed | Caddy `file_server` para estático confirmado no quick-start (exemplo `localhost` + `file_server`). **Ressalva:** o HTTPS automático **não é demonstrado nesta página específica** (remete a seção "Auto HTTPS" separada) — mas é feature-flagship real do Caddy (o exemplo `localhost` já ganha TLS). O fato interno "KVM 8 já roda onionevolve.com" é não-verificável externamente (declarado como interno). |
| **F11** | hypothesis | **Achado mais fraco.** A fonte infoworld citada **não** sustenta os específicos load-bearing: não diz "Alpine sozinho é a melhor escolha" para dashboard JSON sem backend, **não** cita "~15KB", e **contradiz levemente** ao afirmar que htmx também faz "Ajax-style API calls... without a build step" (enfraquece "htmx exigiria backend"). O artigo é sobre **combinar** os dois. A orientação geral (Alpine p/ estático) é comum e plausível, mas o 2º URL (pkgpulse htmx-vs-alpinejs) não foi verificado. Na dúvida → hypothesis. |
| **F12** | confirmed | O URL primário (aiuxplayground) retornou 403 direto, mas o conteúdo da **mesma fonte** foi confirmado via busca: side-drawer que "keeps you in context"; setas esquerda/direita para "jump to the previous or next audit record" com o drawer aberto; filtro por user/date/action para isolar eventos. Casa com o redesign gohighlevel co-citado. UX sustentada. |

**Síntese do verificador:** a tese central do stream (console/mapa = site estático append-only
gerado do `members.yaml` + CHANGELOG, sem backend/DB/plataforma) sobrevive ao teste adversarial —
F1, F2, F3, F5, F8, F9, F10 (as âncoras high) estão sólidas. **Dois padrões de fragilidade a
corrigir no rastro de evidência**, nenhum que derrube a conclusão: (1) **embelezamento não-sourced**
— a atribuição LinkedIn (F3) e o "escritor único" (F5) não estão nas fontes citadas; (2)
**mis-citação de âncora** — F6 (Cytoscape), F7 (features do plugin) e F11 (specs do Alpine) têm o
específico sustentado por um 2º URL co-citado, não pelo primário; em F6 o primário nem cobre a lib.
Único veredito abaixo de confirmed: **F11 → hypothesis** (fonte primária não sustenta "Alpine
sozinho/~15KB" e contradiz levemente o enquadramento do htmx). Recomendação: promover os 2ºs URLs a
fonte primária em F6/F7/F11 e remover/rebaixar as cores não-sourced de F3/F5.
