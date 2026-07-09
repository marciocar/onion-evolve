# S2 — Modelos de sync/federação do mercado (redesign da Federação Onion)

> Stream S2 do redesign da federação. Pesquisa de mercado (2025-2026) ancorada nas 4 dores
> P0 do maestro e nas fundações reusáveis do Onion (graph.sh, SDAAL, doc-bridge, Federação
> formal dormente). **Não decide doutrina — coleta evidência.** Cada achado material tem FONTE (URL).

## Resumo

O mercado resolve "federar config/policy/capacidade por múltiplos repos/tenants" com um pequeno
conjunto de padrões maduros e convergentes que o Onion pode **reusar sem reinventar**:

1. **Catálogo spec-as-code com relações derivadas** (Backstage): entidades em YAML → grafo de
   ownership/dependsOn/consumesApi renderizado automaticamente. É o análogo direto de `members.yaml`
   + `graph.sh`, e ataca **P0#3 (console/relações)** e **P0#4 (mapa derivado)**.
2. **Targeting por atributo, não por id** (ArgoCD ApplicationSet generators, Renovate `packageRules`,
   A2A registry "search by skill"): o alvo é um *seletor* sobre labels/pastas/capacidades — exatamente
   o que resolve **P0#2 (ruído do `alvo:`)**, já que `members.yaml` tem `specializations`/`mode`/classificação.
3. **Pull-based reconcile como default + evento como acelerador** (Flux notification controller):
   valida o doc-bridge git-async e mostra o caminho híbrido para um canal mais VIVO sem abandonar git.
4. **Control plane central + agentes remotos** (Argo CD Agent, A2A agent cards, mesh vs SSOT):
   o desenho para **P0#1 (Grana.Ai core↔core isolado)** — federação-de-federações real com control
   plane vs data plane e o trade-off SSOT-central vs mesh-descentralizado (CRDT).

Confiança geral: **alta** para os padrões estruturais (fontes primárias de docs oficiais e vendors);
**média** para a extrapolação "IA-fala-IA" (A2A é jovem, abril/2025), que fica como hipótese gated.

---

## Achados

### F1 — Backstage: catálogo spec-as-code é a "data layer" de que TUDO pende; relações são derivadas das entidades
**Claim:** No Backstage, o software catalog é a camada de dados sobre a qual TechDocs, scorecards,
API explorer e integrações CI/CD se apoiam; entidades são descritas em YAML e as *relações*
(`ownedBy`, `dependsOn`, `consumesApi`, `hasPart`) têm semântica bem-conhecida e são **consumidas por
plugins** — não desenhadas à mão.
**Fonte:** https://backstage.io/docs/features/software-catalog/well-known-relations/ · https://backstage.io/docs/features/software-catalog/
**Materialidade:** alta.
**Implicação p/ Onion (P0#3, P0#4):** É o espelho exato do par `members.yaml` (entidades) + `graph.sh`
(relações). O Onion já tem o vocabulário de relação (`onion-relation-vocabulary.md`, TBox do graph.sh);
falta **ingerir `members.yaml`** como fonte de nós/arestas (hoje graph.sh não o ingere) e emitir o mapa
de adoções DERIVADO. O "console/relações" (P0#3) é um render desse grafo — não um produto novo.

### F2 — Backstage well-known relations: cada relação tem source+target+type tipados e reversíveis
**Claim:** Relações são tipadas com par direto/reverso (`dependsOn`/`dependencyOf`, `ownedBy`/`ownerOf`,
`parentOf`/`childOf`), permitindo travessia nos dois sentidos e consumo programático por qualquer plugin.
**Fonte:** https://backstage.io/docs/features/software-catalog/well-known-relations/
**Materialidade:** alta.
**Implicação p/ Onion (P0#4, fundação graph.sh):** Valida o motor BFS do graph.sh (`--impact` = travessia
reversa, `--path`, `--closure`). A hierarquia de tiers do `members.yaml` (`source`/`hub`/`standalone`/
`consumer` com `parent:`) já é um `parentOf`/`childOf`. Reusar: mapear `parent`→aresta `adopts`/`adoptedBy`
e `specializations`→tags, e o mapa de adoções cai fora do grafo sem código de desenho manual.

### F3 — ArgoCD ApplicationSet: um manifesto + um *generator* estampa N apps por SELETOR (pasta/cluster/label), zero drift
**Claim:** O ApplicationSet usa *generators* (Git-directory, Cluster, List, Matrix) para gerar 1 Application
por item que casa um seletor — "um ApplicationSet mira 10 clusters"; o Cluster generator auto-descobre
clusters registrados. Alvo = critério, não enumeração manual.
**Fonte:** https://sumguy.com/argocd-applicationsets-patterns/ · https://www.opendesk-edu.org/en/blog/gitops-argocd-app-of-apps-applicationset
**Materialidade:** alta.
**Implicação p/ Onion (P0#2 — ruído do `alvo:`):** Este é o padrão-remédio direto. Hoje `alvo:` faz
per-id OU broadcast. O ApplicationSet mostra o modelo certo: **targeting declarativo por atributo** —
`alvo: {specialization: nx-monorepo}` ou `alvo: {mode: regulated}` resolvido contra os campos que o
`members.yaml` JÁ tem. `/meta:co-announce` passaria a resolver o alvo por seletor (como o generator),
não por lista.

### F4 — ApplicationSet Git generator = "app-of-apps feito direito": deriva apps da ESTRUTURA do repo
**Claim:** O Git generator inspeciona o repo e gera 1 Application por pasta/arquivo que casa — a forma
"correta" do padrão app-of-apps, substituindo a árvore app-of-apps mantida à mão. Reduz ciclos de deploy
multi-cluster de 30+ min para ~5 min e o overhead de 3-4 engenheiros para self-service.
**Fonte:** https://sumguy.com/argocd-applicationsets-patterns/
**Materialidade:** alta.
**Implicação p/ Onion (P0#4):** "Derivar da estrutura, não desenhar à mão" é literalmente a dor #4. O mapa
de adoções do site é desenhado à mão; deveria ser gerado do `members.yaml` como o Git generator gera apps
das pastas. Custo de coordenação cai quando a fonte declarativa única alimenta os artefatos derivados.

### F5 — Argo CD Agent (2025): control plane CENTRAL + binário-agente leve em cada cluster remoto
**Claim:** Technology Preview 2025 do OpenShift GitOps: um Argo CD Agent (binário Go pequeno) roda nos
clusters remotos e fala de volta com a instância Argo CD central no cluster de gestão — hub-and-spoke
explícito para GitOps multi-cluster.
**Fonte:** https://www.redhat.com/en/blog/multi-cluster-gitops-argo-cd-agent-openshift-gitops
**Materialidade:** alta.
**Implicação p/ Onion (P0#1 — Grana.Ai core↔core):** Molde direto para o caso "core próprio noutra máquina".
Grana.Ai tem seu próprio Onion core num monorepo nx com stage/prod; falta canal VIVO core↔core. O modelo
Argo CD Agent (central emite/observa; agente remoto executa localmente e reporta) encaixa como um
**federation-transport `a2a-live`** costurado no SDAAL — o Onion-source é o control plane, o core-remoto é
o agente, sem que o source commite no repo alheio (preserva "entrega-sem-commit" I3).

### F6 — Flux notification controller: pull por intervalo (default) + webhook receiver como acelerador, SEM virar push
**Claim:** Flux reconcilia por `spec.interval` (poll) e, com Receivers, um webhook (GitHub/GitLab/Harbor…)
dispara reconciliação imediata — "pull tão responsivo quanto push", commit→deploy de minutos para segundos.
Explicitamente: webhooks **não** tornam o Flux push-based; o intervalo vira rede de segurança.
**Fonte:** https://fluxcd.io/flux/guides/webhook-receivers/ · https://oneuptime.com/blog/post/2026-03-05-flux-cd-event-driven-reconciliation/view
**Materialidade:** alta.
**Implicação p/ Onion (P0#1, fundação doc-bridge):** Valida o doc-bridge git-async como base correta
(pull é a raiz do GitOps) e mostra a evolução mínima: manter o CHANGELOG/inbox git como SSOT, mas somar um
"receiver" (o hook "you have mail" 📬 já é um proto-receiver local) que ACORDA a sessão em vez de esperar o
maestro abrir o repo. Torna o canal mais VIVO sem trair "um escritor por repo".

### F7 — Renovate shareable presets (`extends`): config org-wide num lugar, propagada a todos os repos
**Claim:** Presets compartilhados guardam config num repo central; cada repo faz `extends` (idealmente via
`onboardingConfig`), então uma mudança no preset se distribui automaticamente a todos os repos rastreados —
evita copiar/colar por repo.
**Fonte:** https://docs.renovatebot.com/config-presets/ · https://docs.renovatebot.com/key-concepts/presets/
**Materialidade:** alta.
**Implicação p/ Onion (P0#2, adopt/vendor):** Modelo de "policy central + herança explícita por consumidor".
O Onion já faz vendoring via `/meta:adopt` (KB embarcado, vendor-branch merge never-clobber). O `extends`
sugere um nível a mais: adotantes referenciarem um *preset de política* do core (ex.: regras de trust,
classificações de diário compartilháveis) em vez de cópia — mudança no core propaga por pull, com override local.

### F8 — Renovate ganha em monorepo por entender workspaces e AGRUPAR updates; Dependabot fragmenta
**Claim:** Renovate entende npm/Yarn/Lerna workspaces, atualiza deps internas corretamente e agrupa
(`group:monorepos`) num PR só; teste real (monorepo 198 deps, 14 workspaces, abr/2026): Dependabot abriu 18
PRs sem conseguir colapsar bumps entre workspaces; agrupamento só dentro de cada workspace.
**Fonte:** https://dev.to/alex_aslam/renovate-vs-dependabot-which-bot-will-rule-your-monorepo-4431 · https://docs.renovatebot.com/bot-comparison/
**Materialidade:** média-alta.
**Implicação p/ Onion (P0#1 — caso Grana.Ai nx):** Grana.Ai é um monorepo nx com TIME. A lição é
**agrupamento consciente de workspace**: uma propagação do core para o monorepo Grana.Ai deve chegar como
UM anúncio agrupado (não N sinais por app/lib), respeitando a topologia nx. Reforça targeting por atributo
(F3) + entrega agrupada como antídoto ao ruído (P0#2) num consumidor multi-projeto.

### F9 — Nx: generators + `@nx/enforce-module-boundaries` + conformance rules aplicam padrão org-wide dentro do monorepo
**Claim:** Generators padronizam scaffolding/convenções (transformações AST); a lint rule
`enforce-module-boundaries` impõe restrições de dependência (ex.: app não depende de app); conformance rules
aplicam padrões organizacionais automaticamente; ownership é definido a nível de projeto. 63% das empresas
com 50+ devs usam monorepo.
**Fonte:** https://nx.dev/docs/concepts/decisions/why-monorepos · https://dev.to/mcheremnov/mastering-nx-the-complete-guide-to-modern-monorepo-development-5573
**Materialidade:** média-alta.
**Implicação p/ Onion (P0#1):** Dentro do monorepo Grana.Ai, o *enforcement* de policy compartilhada já é
resolvido por Nx (boundaries + generators + owners por projeto). Implicação: o Onion-source **não** deve
tentar sincronizar policy arquivo-a-arquivo dentro do monorepo alheio; deve federar no nível do REPO
(fronteira control-plane) e deixar o Nx do Grana.Ai ser o data-plane que distribui internamente. Fronteira
limpa = menor custo de coordenação.

### F10 — Control plane = single source of truth de config; per-tenant control plane isola mas CUSTA (e não resolve o data plane)
**Claim:** O control plane funciona como fonte única de verdade com a config mais atual de todas as peças e
garante consistência em escala; porém control planes por-tenant melhoram isolamento ao custo de operar um
por tenant, e ainda assim não resolvem isolamento no data plane (noisy neighbor, segurança) — que exige
tratamento separado.
**Fonte:** https://konghq.com/blog/learning-center/control-plane-vs-data-plane · https://kubernetes.io/docs/concepts/security/multi-tenancy/
**Materialidade:** alta.
**Implicação p/ Onion (P0#1, Federação formal):** Nomeia a arquitetura para a federação-de-federações: o
Onion-source é o **control plane** (SSOT = `members.yaml` + ledger de contratos da Federação formal); cada
core-adotante (Grana.Ai) é um control plane subordinado com seu próprio data plane (o monorepo/devs). O
trade-off "isola mas custa" avisa: não multiplicar control planes sem ganho — o hub `rhilo` (T1) e o
standalone (T3) já são o gradiente certo.

### F11 — Federação centralizada vs mesh descentralizado (CRDT): SSOT central é ponto único de dependência
**Claim:** Um registry/control plane central (ex.: Istiod) ingere service entries de todas as malhas e
re-propaga como recursos aos data planes — mas o desafio é disponibilidade/consistência do central: vira
dependência de alto valor e ponto único. Alternativa: federação descentralizada com banco de CRDTs
sincronizando o desired state global, removendo o SPOF.
**Fonte:** (mesh/CRDT) https://konghq.com/blog/learning-center/control-plane-vs-data-plane · (CRDT federation) https://arxiv.org/pdf/2204.05710
**Materialidade:** média (CRDT é direção acadêmica; o trade-off SSOT-central vs mesh é sólido).
**Implicação p/ Onion (P0#1 — SSOT vs mesh):** Decisão de doutrina a alimentar (não decidir aqui): o Onion
hoje é SSOT-central puro (`members.yaml` no core). Para core↔core VIVO, o git-async já é um proto-CRDT
(merge por repo, um escritor). Manter SSOT-central para *identidade/contratos* e mesh git-async para
*comunicação* parece o meio-termo barato; full-mesh CRDT é over-engineering para 5 membros.

### F12 — A2A (Google→Linux Foundation, abr/2025): Agent Card em `/.well-known/agent.json` = anúncio de CAPACIDADE machine-readable + registry "search by skill"
**Claim:** Agent Cards são JSON em URI padrão `/.well-known/agent.json` (RFC 8615) declarando endpoints,
auth, skills com input/output e capacidades de task. Discovery por registry (agentes publicam cards; clientes
buscam por critério "skills específicas" e o registry retorna cards que casam) ou por configuração direta
(sistemas acoplados/privados). Transporte JSON-RPC 2.0 sobre HTTP + SSE para streaming.
**Fonte:** https://a2a-protocol.org/latest/topics/agent-discovery/ · https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/
**Materialidade:** média-alta (padrão jovem, mas é o vetor natural do "IA-fala-IA" futuro).
**Implicação p/ Onion (P0#1, P0#2; hipótese gated):** O Agent Card é o análogo externo do
`personality_summary`+`specializations`+`exposes` que cada membro do `members.yaml` já declara. Se/quando o
Onion habilitar IA-fala-IA, o transporte `a2a-live` do federation-transport (SDAAL) usaria cards + registry;
o "search by skill" é o mesmo targeting-por-atributo do F3 (reforça P0#2). Hoje SEM IA-fala-IA — fica como
costura futura gated, não implementação. **Hipótese**, não recomendação.

### F13 — Submodule vs subtree vs package registry: pin-por-consumidor (submodule) vs vendoring com patch local (subtree) vs versionado (registry)
**Claim:** Submodule guarda ponteiro → cada consumidor pina/atualiza no seu ritmo (Service A em `abc123`,
B em `def456`), bom para pin estrito independente. Subtree copia conteúdo na história → clones não precisam
saber; certo para "lib vendorizada com patch local" (`git subtree pull --squash`, patch some no próximo pull).
Registry versionado é o que "a maioria dos times modernos faz" para first-party.
**Fonte:** https://www.gitflow.dev/blog/multi-repo-coordination · https://www.grizzlypeaksoftware.com/library/git-submodules-and-subtrees-when-to-use-each-naksp03o
**Materialidade:** média-alta.
**Implicação p/ Onion (fundação adopt/vendor):** Descreve exatamente o mecanismo atual do `/meta:adopt`:
vendoring por cópia com never-clobber = padrão **subtree** (patch local preservado no merge de vendor-branch).
O `onion_version` pin por membro/linhagem no `members.yaml` = semântica **submodule** (cada adotante pina seu
ritmo). Confirma que o Onion escolheu o híbrido pragmático certo; o próximo grau (registry) só valeria se
adoções escalarem muito além de 5 — não agora.

### F14 — Backstage TechDocs "docs-like-code" + annotations conectam entidade a sistemas externos; console é RENDER do catálogo
**Claim:** TechDocs escreve docs em Markdown junto do código (solução docs-like-code da Spotify);
annotations conectam a entidade a GitHub/CI/Kubernetes/observability; o portal (console) é a camada de UI
que LÊ entidades do catálogo — o catálogo é a fonte, o portal é a vista.
**Fonte:** https://backstage.io/docs/overview/what-is-backstage/ · https://backstage.io/docs/features/software-catalog/
**Materialidade:** alta.
**Implicação p/ Onion (P0#3 — console/histórico):** O console de federação não precisa ser um app com estado
próprio; é um **render** do SSOT (members.yaml + CHANGELOG + ledger + graph.md). Isso torna o deploy na VPS
barato (ver seção de viabilidade): gerar HTML estático do grafo/histórico, servido pelo Caddy que já roda no
KVM 8. Histórico = o próprio CHANGELOG git (append-only) já é o event log; o console só o exibe.

---

## Encaixe nas fundações / viabilidade VPS

### Mapa achado → dor P0 → fundação reusável

| Dor P0 | Achados que informam | Fundação Onion a reusar (não reinventar) |
|--------|----------------------|-------------------------------------------|
| **#1 Grana.Ai core↔core isolado** | F5 (Argo CD Agent hub-spoke), F6 (Flux pull+webhook), F8 (agrupar por workspace), F9 (Nx enforça internamente), F10 (control/data plane), F11 (SSOT vs mesh), F12 (A2A live, gated) | **SDAAL factory** → novo `federation-transport {git-async \| local \| a2a-live}` (precedente pronto: task-manager/factory.md já abstrai `api\|mcp` com fallback). Fronteira control-plane no nível do REPO; Nx do Grana.Ai é o data-plane. |
| **#2 Ruído do `alvo:`** | F3 (ApplicationSet generators/seletores), F7 (Renovate presets), F8 (grouping), F12 (search-by-skill) | **members.yaml** JÁ tem `specializations`/`mode`/classificação → `/meta:co-announce` resolve `alvo:` por SELETOR de atributo, não per-id/broadcast. Zero campo novo no SSOT. |
| **#3 Console/histórico/relações** | F1, F2 (catálogo+relações Backstage), F14 (TechDocs = render do catálogo), F6 (notification controller = event log) | **graph.sh** (motor BFS já existe) + **CHANGELOG git** (event log append-only já existe). Console = render estático do grafo + histórico, não app com estado. |
| **#4 Mapa de adoções derivado** | F1, F2 (relações derivadas), F4 (Git generator deriva da estrutura) | **graph.sh** precisa **INGERIR members.yaml** (hoje não ingere) → emite mapa de adoções derivado. Mata o desenho-à-mão do site. |

### Costuras concretas (menor esforço, maior reuso)

1. **graph.sh ← members.yaml (P0#3+P0#4):** adicionar `members.yaml` como fonte de nós (membros) e arestas
   (`parent`→adopts/adoptedBy; `specializations`→tags; `trust.*`→arestas de confiança). O BFS existente
   (`--impact`/`--path`/`--closure`) passa a responder "quem adota o quê", "caminho core→Grana.Ai",
   "órfãos de adoção". Espelha o Backstage catalog→relations (F1/F2). É a fundação única para o mapa (P0#4)
   E o console (P0#3).

2. **Targeting por seletor no doc-bridge (P0#2):** `/meta:co-announce` aceita `alvo:` como *query* sobre
   `members.yaml` (`{specialization: X}`, `{mode: regulated}`, `{tier: hub}`) resolvida como o ApplicationSet
   generator (F3) / Renovate packageRules. Nenhuma mudança no schema do SSOT — só no resolver do alvo.

3. **Receiver que ACORDA (P0#1):** o hook "you have mail" 📬/📥 já é um proto-webhook-receiver LOCAL (F6).
   Evoluir para acordar a sessão do adotante em vez de esperar o maestro — mantém pull/git-async como SSOT,
   ganha responsividade sem virar push nem quebrar "um escritor por repo" (I3).

4. **federation-transport via SDAAL (P0#1):** costurar `git-async` (default, doc-bridge atual) | `local`
   (carteiro co-deliver/co-relay, mesma máquina) | `a2a-live` (gated, F12) usando o MESMO padrão factory do
   task-manager (`api|mcp`+fallback). A Federação formal (veto/rollback/ledger) é o control plane (F10);
   o transport é o data plane. Grana.Ai = primeiro consumidor `a2a-live` quando graduar.

### Viabilidade na VPS (Hostinger KVM 8, srv1812846)

- **Console/mapa = estático servido pelo Caddy que JÁ roda** (site onionevolve.com + app.onionevolve.com via
  reverse_proxy). Como o console é render do SSOT (F14), o build é: `graph.sh --markdown` + parser do
  CHANGELOG → HTML/SVG estático em `/var/www/` (ex.: `federation.onionevolve.com` ou `/federation`). TLS
  Let's Encrypt automático já existe. **Custo ~zero de infra nova** — build-on-VPS leve, sem banco, sem SPA.
- **Receiver/acordar sessão:** o onion-bridge (claude-agent-sdk, systemd `User=onion`) já roda na porta 8787;
  um endpoint/hook adicional que reage a novo item em `inbound/` é incremento, não serviço novo.
- **a2a-live (futuro, gated):** A2A é JSON-RPC/HTTP+SSE (F12) — hospedável no mesmo Caddy/systemd; Agent Card
  em `/.well-known/agent.json` do domínio. Só quando IA-fala-IA for habilitado por doutrina; **hoje é hipótese**.
- **Trade-off de custo de coordenação:** para 5 membros, SSOT-central (`members.yaml` no core) + mesh
  git-async é o ponto ótimo (F10/F11). Full control-plane-per-tenant ou CRDT-mesh só se as adoções
  escalarem ordens de magnitude — over-engineering agora.

### Sinais de alerta colhidos (aprender com os erros do mercado)

- **SSOT central é ponto único de dependência** (F11): manter o `members.yaml` versionado e o ledger git
  como append-only mitiga; não centralizar *runtime* que possa cair.
- **Per-tenant control plane não resolve o data plane** (F10): não tentar sincronizar dentro do monorepo
  Grana.Ai — deixar o Nx (F9) fazê-lo.
- **Backstage MCP registry proposal está travada/sem governança em escala** (F, busca de marketplace):
  https://github.com/IBM/mcp-context-forge/issues/2809 — aviso de que "registry de capacidade governado"
  é problema não-resolvido no mercado; o Onion não deve assumir que existe padrão pronto para descoberta
  governada — daí manter A2A/registry como gated.
- **Submodule confunde e desincroniza** (F13): a escolha do Onion por vendoring subtree-like + pin explícito
  no members.yaml evita a pegadinha clássica do "esqueci `git submodule update`".

---

## Verificação adversarial

> Passe cético do verificador S2 (doutrina "evidência ou abstenção"). Cada fonte foi refetchada e
> confrontada com o claim. Veredito por achado, com o *porquê*. Onde a fonte não sustenta o número/atribuição
> específica, o veredito é rebaixado — mesmo quando a direção geral do achado se mantém.

| ID | Veredito | Nota |
|----|----------|------|
| **F1** | **confirmed** | Fonte oficial Backstage lista os 7 pares de relação e diz explicitamente que são *"commonly generated based on `spec.[field]`"* — derivadas das entidades, não desenhadas. Claim sustentado sem exagero. |
| **F2** | **confirmed** | Os pares direto/reverso batem literalmente (`dependsOn`/`dependencyOf`, `ownedBy`/`ownerOf`, `parentOf`/`childOf`) + *"The relation is directional... the entity at the other end will have the opposite relation"*. Travessia bidirecional confirmada; a analogia com o BFS do graph.sh é do pesquisador (razoável), não da fonte. |
| **F3** | **confirmed** | sumguy.com confirma generators List/Cluster/Git-directory/Matrix estampando 1 App por item de seletor, com Cluster generator auto-descobrindo clusters. "Alvo = critério, não enumeração" sustentado. |
| **F4** | **confirmed (claim) / número refutado** | O núcleo ("Git generator deriva apps da ESTRUTURA do repo em vez de app-of-apps à mão") é sustentado. **PORÉM** os números do corpo do achado ("30+ min → ~5 min", "3-4 engenheiros") **NÃO existem na fonte** — sumguy.com não traz nenhum número de tempo/headcount. Números a remover ou marcar como não-fonteados. |
| **F5** | **confirmed** | Red Hat confirma: agente Go leve nos clusters remotos + Principal no control plane central, hub-and-spoke, Tech Preview OpenShift GitOps 1.17 (2025), GA planejada 1.19. Molde direto e recente. |
| **F6** | **confirmed** | Flux docs: *"Flux is by design pull-based... webhook receivers make pull-based pipelines as responsive as push-based"*. A leitura "SEM virar push" é fiel (pull continua a raiz). Ressalva menor: a frase "intervalo vira rede de segurança" é inferência do exemplo `interval: 60m`, não afirmada verbatim nesta página. |
| **F7** | **confirmed** | Renovate docs confirmam `extends` central + descoberta automática de `renovate-config/default.json` no org, com mudança propagada por pull. Sem exagero. |
| **F8** | **hypothesis** | Direção qualitativa (Renovate agrupa por workspace; Dependabot fragmenta) é sustentada. **MAS os específicos citados no corpo — "198 deps, 14 workspaces, abr/2026, Dependabot 18 PRs" — NÃO estão na fonte.** O dev.to traz outro dado anedótico ("50-project monorepo, Dependabot 200 PRs/semana, poupou 15h/mês"), sem contagem controlada. Número "18 PRs em teste real" parece fabricado; rebaixado. |
| **F9** | **confirmed (mecanismo) / stat refutada** | Generators e ownership por projeto (CODEOWNERS) confirmados nesta URL. `@nx/enforce-module-boundaries` é feature real do Nx (fato de domínio), embora esta página específica só diga "rules to define which libraries can depend on each other" e **não** use o termo nem "conformance rules". A estatística **"63% das empresas 50+ devs usam monorepo" NÃO está na fonte** — remover. Implicação (federar no nível do repo, Nx como data-plane) permanece sólida. |
| **F10** | **confirmed** | konghq sustenta "control plane = single source of truth de config". A parte "per-tenant isola mas custa e não resolve o data plane" **não** vem do konghq — vem da 2ª fonte (kubernetes.io multi-tenancy), que a confirma bem ("benefit of stronger isolation must be evaluated against cost", noisy-neighbor no data plane). Achado ok desde que o campo `source` credite as DUAS fontes (hoje lista só konghq). |
| **F11** | **hypothesis** | O trade-off geral "SSOT central = ponto único de dependência vs alternativa descentralizada" é verdade arquitetural sólida. **PORÉM a sustentação é fraca/mis-fonteada:** konghq **não** menciona mesh/CRDT/SPOF (confirmado no refetch); e o arXiv 2204.05710 é sobre **liqo/"liquid computing" (multi-cluster K8s)**, não um paper de "CRDTs removem o SPOF" — o abstract *não* especifica CRDT como mecanismo de sync. A especificidade "CRDT" não tem fonte primária. Direção mantida como hipótese; retirar a alegação de que CRDT-mesh é conclusão fonteada. |
| **F12** | **confirmed (mecanismo) / drift factual** | Agent Card machine-readable em URI well-known + discovery por registry "search by skill" + JSON-RPC/HTTP: tudo confirmado. **Drift:** a spec atual usa `/.well-known/agent-card.json`, **não** `agent.json` (este é o caminho antigo/deprecado citado no achado). "abr/2025, Linux Foundation" conflaciona o *anúncio* (Google, abr/2025) com a *doação à LF* (meados de 2025; rodapé © 2026 Linux Foundation). Corrigir path e proveniência. Continua corretamente marcado como hipótese gated. |
| **F13** | **confirmed** | gitflow.dev confirma as 3 semânticas (submodule=pin por consumidor; subtree=vendoring com patch local; registry=versionado, "default modern answer for most teams"). Mapeamento adopt=subtree-like + pin=submodule-like é leitura fiel. |
| **F14** | **confirmed** | TechDocs docs-like-code (origem Spotify) + portal como RENDER do catálogo é arquitetura Backstage estabelecida e consistente com F1 (catálogo = data layer de que tudo pende). Implicação "console estático barato no Caddy" é do pesquisador, plausível. |

### Síntese do verificador

- **Padrões estruturais (F1–F3, F5–F7, F10, F13, F14): sólidos.** Fontes primárias (docs oficiais Backstage/Flux/Renovate/Red Hat/Kong/K8s) sustentam os claims sem exagero. Confiança alta mantida.
- **Três achados carregam números/atribuições não-fonteados** que devem ser corrigidos antes de virar doutrina:
  - **F4:** tempos "30→5 min" e "3-4 engenheiros" — inexistentes na fonte.
  - **F8:** "198 deps / 14 workspaces / 18 PRs em teste real" — a fonte traz outro anedótico ("200 PRs/semana"); número fabricado.
  - **F9:** "63% das empresas 50+ devs" — inexistente na fonte.
- **F11 é o mais fraco:** o trade-off é verdadeiro, mas o CRDT específico não tem fonte primária (o arXiv é liqo, não CRDT) e o konghq não fala de mesh. Manter como *direção a alimentar*, jamais como conclusão fonteada. Já classificado como média — coerente.
- **F12** correto no mecanismo, mas com **drift factual** (path `agent-card.json`, não `agent.json`; proveniência LF). Como já é hipótese gated, o risco é baixo — mas corrija o path na costura futura.
- **Nenhum achado material foi plenamente refutado** (nenhum claim central é falso); os rebaixamentos são por **specifics fabricados/mis-fonteados**, não por tese errada. Recomendação: limpar os 3 números órfãos (F4/F8/F9) e a atribuição CRDT (F11) antes de citar em decisão de doutrina.
