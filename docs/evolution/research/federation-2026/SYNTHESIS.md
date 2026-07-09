# SÍNTESE — Redesign da Federação Onion (2026)

> Consolidação dos 4 streams de pesquisa (S1 interop-vivo/A2A · S2 modelos de sync ·
> S3 observabilidade/console/mapa · S4 concorrência/academia/governança) contra as **4 dores
> P0 do maestro** e as **fundações reusáveis** do Onion (`graph.sh`, SDAAL, doc-bridge,
> Federação formal dormente). Data: 2026-07-09.
>
> **Natureza deste documento:** insumo de evidência para a decisão do maestro — **não é a
> decisão de doutrina**. Onde a verificação adversarial rebaixou algo (declarado ≠ verificado),
> está marcado. Achados citados por ID (`S1·F4`, `S2·F3`…); só entram achados **confirmed**
> como base de recomendação — os `hypothesis` aparecem rotulados e nunca sustentam uma decisão.

---

## Panorama (o que os 4 streams concordam)

Três teses independentes convergiram nos quatro streams, o que aumenta a confiança:

1. **O mercado já resolveu as peças que faltam ao Onion — a jogada é reuso, não invenção.**
   Catálogo spec-as-code com relações derivadas (Backstage, `S2·F1/F2`), targeting por atributo
   (ArgoCD ApplicationSet, `S2·F3`), pull + evento acelerador (Flux, `S2·F6`), control-plane +
   agente remoto (Argo CD Agent, `S2·F5`), e o par de resiliência SSE-conectado + webhook-offline
   do A2A (`S1·F4/F5`). Cada um mapeia numa fundação que o Onion **já tem**.

2. **O Onion está À FRENTE em governança e ATRÁS em observabilidade.** A doutrina Onion
   (git-async gated, um-escritor-por-repo, entrega-sem-commit, SSOT executável) é validada
   ponto-a-ponto pela indústria: config-as-code por git com rollback (`S4·F7`, com ressalva de
   citação), fail-safe hierárquico "unconfigured = disabled" (`S4·F7`), reputação-por-evidência
   (`S4·F3`), e é **corroborada pelos erros do mercado** — tool-poisoning MCP (`S4·F6`) e a
   fragilidade de subagentes por contexto faltante (`S4·F1/F2`). A lacuna real é **não ter onde VER**
   (P0-3) e **não derivar o mapa** (P0-4).

3. **A VPS KVM 8 já basta.** Console e mapa são **render estático do SSOT** (`members.yaml` +
   CHANGELOG + `graph.sh`) servido pelo Caddy que já roda (`S2·F14`, `S3·F5/F10`, `S4` viabilidade).
   Nenhum backend, nenhum DB, nenhum serviço novo stateful para P0-3/P0-4.

---

## Implicações por dor P0

### P0-1 — Grana.Ai isolada / canal vivo core↔core

**O que a evidência diz.** A indústria tem o molde exato do "core próprio noutra máquina":
**control plane central + agente remoto leve** (Argo CD Agent hub-and-spoke, `S2·F5` confirmed) e o
par de resiliência **SSE quando conectado + webhook push quando offline + task durável + retomada
por resubscribe** (A2A `S1·F4/F5`, `S4·F5` — todos confirmed contra a spec oficial). O Onion **já
opera a metade offline/durável** (doc-bridge git-async, `inbound/` commitado = checkpoint,
entrega-sem-commit = garantia "não repetir efeito de saída", ecoando durable-execution `S1·F11`
confirmed). **Falta só a metade viva** (SSE) — e o motor dela **já existe**: o `onion-bridge` roda
`@anthropic-ai/claude-agent-sdk` com `bypassPermissions` na VPS (`S1·F9` confirmed).

**Cautela forte, com fonte.** Abrir "IA-fala-IA autônoma" cai no anti-padrão que a própria Anthropic
sinaliza — multi-agente rende +90% mas a 15× o custo, e *"domínios que exigem contexto compartilhado
ou muitas dependências não são bom encaixe"* (`S4·F1` confirmed verbatim); a Cognition reforça
(fragilidade = contexto faltante, `S4·F2`). Logo o `a2a-live` deve **transportar sinais gated**, não
conversas autônomas — o gate humano do maestro permanece. E qualquer payload remoto é **supply-chain
não-confiável até verificado** (tool-poisoning MCP, `S4·F6` — thrust confirmed; a estatística
"30%+ de 1.800 servidores" foi **rebaixada** na verificação, estudos comparáveis dão ~7%).

**Fundação a reusar:** `federation-transport` SDAAL (ver §Reuso) com adapter `a2a-live` **gated**,
sobre o bridge que já roda. Fronteira no nível do REPO: o Nx do Grana.Ai é o data-plane que
distribui internamente (`S2·F9`), o core não sincroniza arquivo-a-arquivo no monorepo alheio.

> **Nota de estado (declarado ≠ verificado):** o `members.yaml` registra Grana.Ai como
> `role: standalone`, **não** `role: source` — doutrina "fonte ≠ derivação: uma só fonte". A dor P0-1
> é **canal**, não um segundo core soberano (ver §Veredito multi-core).

### P0-2 — Ruído no targeting `alvo:`

**O que a evidência diz.** O remédio é **targeting por ATRIBUTO/seletor, não por id** — padrão
maduro e convergente: ArgoCD ApplicationSet generators estampam N alvos por seletor (`S2·F3`
confirmed), Renovate `packageRules`/presets (`S2·F7` confirmed), e o "search by skill" do registry
A2A (`S1·F2`, `S2·F12`). Na academia, é a instância direta do anti-padrão "contexto faltante":
mensagem chega a quem não tem contexto para agir (`S4·F2`). O modelo canônico de enforcement é
**policy-as-data** — a política decide, não o agente (OPA/Rego na camada de tool-calling, `S1·F12`
confirmed).

**A chave: custo zero de schema.** O `members.yaml` **já carrega** `specializations`, `mode`,
`role`/`tier` e o bloco `trust:` — ou seja, **já é policy-as-data** (`S1·F12`, `S2·F3`, `S4·F2/F7`).
Falta apenas o `alvo:` ser **resolvido como query** sobre esses campos (`{specialization: nx-monorepo}`,
`{mode: regulated}`, `{tier: hub}`) em vez de per-id OU broadcast. Nenhum campo novo no SSOT.

**Fundação a reusar:** `graph.sh` (motor BFS impact/path/closure) é o candidato natural a **avaliar a
política sobre o grafo de membros** — resolver "quem recebe o quê" vira um query de closure gated,
uma vez que ele ingira o `members.yaml`.

### P0-3 — Falta console / histórico / relações

**O que a evidência diz.** **Não construir plataforma tipo Backstage/Port** — para 5 membros e
maestro único seria over-engineering caro (self-host Backstage = 3+ engenheiros, ~US$450k/ano,
6-12 meses; *"Backstage não é um portal, é um framework para construir um"* — `S3·F1` confirmed
verbatim). O caminho certo é **projeção read-only (CQRS leve)** sobre um event-store que o Onion
**já tem**: o CHANGELOG com campo `alvo:` é um **append-only event log versionado em git** — e git é,
por design, um append-only log de escritor único (`S3·F3/F4/F5` confirmed; ressalva: a cor "LinkedIn
usa para feeds" e "escritor único" **não estão** nas fontes citadas — embelezamento não-load-bearing).
O console não é fonte, nunca corrompe estado: regenerável do zero (`S3·F13`). Vocabulário de estados
para o histórico vem do **task lifecycle A2A de 8 estados** (`S1·F3` confirmed): `input_required`/
`auth_required` ↔ gate do maestro; `rejected` ↔ veto fail-safe da Federação formal. TRiSM dá as views
(trust/risk/security, `S4·F4`). UX-alvo já especificada: side-drawer + navegação por teclado + filtro
que isola em poucos cliques (`S3·F12` confirmed) — o mesmo filtro por `specialization`/`mode` que
**expõe visualmente** o fix da P0-2.

**Fundação a reusar:** `/meta:federation-status` **já é** o monitor read-only (drift + CI por membro,
`S4·F10`); P0-3 é dar-lhe **superfície visual**. Front-end: **Alpine.js** lendo `feed.json` no cliente
(`S3·F11` — **hypothesis**: a fonte não sustenta "Alpine sozinho/~15KB" e a escolha exata fica em
aberto; a direção "estático sem backend" é sólida por F5/F10).

### P0-4 — Falta mapa de adoções derivado

**O que a evidência diz.** "Derivar da estrutura, não desenhar à mão" é literalmente a dor. Backstage
mostra que relações são **derivadas das entidades** (`ownedBy`/`dependsOn`/`parentOf`, `S2·F1/F2`
confirmed, "commonly generated based on `spec.[field]`"); Cursor/Windsurf: fonte global desenhada à
mão **"drifta em silêncio"**, o mantível é **uma fonte canônica que compila para os alvos** (`S4·F8` —
**hypothesis**, consenso de prática em fonte de baixa autoridade, mas coerente). Gerar Mermaid de YAML
é padrão batido (YAMLtecture, `S3·F8` confirmed): `members.yaml → script → Mermaid`. O tooling é
decidido pela FORMA (`S3·F6`): **Mermaid primeiro** (renderiza em docs/GitHub sem build), **Cytoscape.js**
só se o grafo virar objeto de exploração interativa (reusa o BFS do `graph.sh`), **D3 é excesso**.

**Fundação a reusar:** **`graph.sh` precisa INGERIR o `members.yaml`** (hoje não ingere — é o
pré-requisito técnico único, baixo esforço/alto retorno). O Onion está **à frente** aqui: seu SSOT já
é executável (spec-as-code), não um `.md` copiado (`S4·F8`).

---

## Veredito multi-core (single-source vs federação-de-federações)

> **Insumo fundamentado para a decisão do maestro — não a decisão.**

**Recomendação: manter SSOT single-source para IDENTIDADE/CONTRATOS, e federar apenas a
COMUNICAÇÃO via mesh git-async (+ `a2a-live` gated). NÃO promover Grana.Ai a `role: source`.**

**Fundamentação na evidência:**

- **Para 5 membros, SSOT-central é o ponto ótimo — mesh-CRDT é over-engineering.** O trade-off
  "control plane = single source of truth de config" vs mesh descentralizado é real (`S2·F10`
  confirmed; `S2·F11` **hypothesis** — a especificidade "CRDT remove SPOF" **não tem fonte primária**,
  o arXiv citado é sobre liqo/multi-cluster K8s, não CRDT). A conclusão barata e defensável:
  **identidade/contratos ficam SSOT-central (`members.yaml` no core); a comunicação já é um proto-mesh
  git-async (merge por repo, um escritor)**. Full-mesh CRDT só se as adoções escalarem ordens de
  magnitude.

- **O padrão control-plane + agente remoto resolve "core próprio noutra máquina" SEM segundo
  soberano.** Argo CD Agent (`S2·F5` confirmed) e o modelo control-plane/data-plane (`S2·F10`) mostram
  que o Grana.Ai pode rodar seu Onion localmente **como agente subordinado / data-plane** — o core
  segue sendo o control-plane único que emite/observa contratos. Isso preserva o invariante
  entrega-sem-commit (I3) e a doutrina "uma só fonte" que o `members.yaml` já grava para o Grana.Ai
  (`role: standalone`, "NÃO tem role:source próprio").

- **Federated learning cross-silo dá o modelo do que se troca.** Compartilha-se **conhecimento
  destilado (sinais, migalhas, vereditos, `personality_summary`), nunca o repo bruto** (`S4·F11`
  confirmed) — que é exatamente o `exposes:`/entrega-sem-commit. Grana.Ai (monorepo nx privado,
  regulado, time de devs) é o caso cross-silo canônico: partilha aprendizado, não código-fonte.

- **Convergência de protocolos reduz o risco da aposta.** ACP fundiu no A2A (`S1·F13` confirmed); há
  **um alvo dominante** para o `a2a-live`, não três — como o forge SDAAL costura github e deixa
  gitlab/bitbucket "🔜".

**Trade-offs honestos:**

| Opção | A favor | Contra |
|---|---|---|
| **Single-source + mesh de comunicação** (recomendada) | Barato, alinha à doutrina "uma fonte", SPOF só na *identidade* (mitigável: `members.yaml` versionado + ledger append-only); Grana roda local como data-plane | Core é dependência de alto valor para contratos; canal vivo exige o `a2a-live` gated (fase 2) |
| **Federação-de-federações real** (Grana = `role: source`) | Autonomia total do Grana; sobrevive a core offline | Contradiz doutrina vigente; multiplica control-planes ("isola mas CUSTA", `S2·F10`); reconciliação multi-source sem CRDT maduro; over-engineering para a escala atual |

**Gatilho de revisão:** se surgir um 2º hub com sub-adotados próprios operando desconectado do core
por períodos longos, reabrir a questão — aí o custo do mesh descentralizado passa a se justificar.

---

## Construir-aqui-na-VPS (opções)

Infra provada em `srv1812846` (KVM 8, 8 vCPU/32 GB): Caddy `file_server` + TLS Let's Encrypt auto
serve `onionevolve.com`; `app.onionevolve.com → reverse_proxy 127.0.0.1:8787 → onion-bridge` (systemd,
`claude-agent-sdk`); DNS via API Hostinger. Sobre isso, **sem infra nova**:

### Leve (recomendado começar) — estático gerado, esforço baixo

- **Mapa de adoções (P0-4).** `graph.sh` (+ ingestão `members.yaml`) emite **Mermaid** → `map.mmd`
  renderizado em docs/GitHub **sem build**, e/ou `file_server` num subdomínio (`map.onionevolve.com`).
  Esforço: pequeno (o motor BFS já existe; falta o parser de `members.yaml` + emissor Mermaid).
  Evidência: `S3·F6/F8`, `S2·F4`, `S4·F8`.
- **Console/histórico (P0-3).** Script de projeção (bash/python) do `git log`/CHANGELOG → `feed.json` +
  `members.json`; página estática HTML + Alpine.js (filtro/timeline/side-drawer) servida por Caddy
  (`console.onionevolve.com`), regenerada por hook/cron. Zero backend/DB. Esforço: pequeno-médio.
  Evidência: `S3·F3/F5/F10/F11/F12`, `S2·F14`, `S4·F10`.
- **Receiver que ACORDA (P0-1 parcial).** O hook "you have mail" 📬/📥 já é um proto-webhook-receiver
  local (`S2·F6`); evoluir para acordar a sessão do adotante em vez de esperar o maestro — mantém
  pull/git-async como SSOT, ganha responsividade sem virar push nem quebrar I3. Esforço: pequeno.

### Pesado (fase 2, gated) — processo persistente, esforço médio-alto

- **Endpoint `a2a-live` (P0-1 completo).** A2A é JSON-RPC/HTTP+SSE + `PushNotificationConfig` webhook
  (`S1·F4/F5`) — hospedável atrás do Caddy já existente; Agent Card em `/.well-known/agent-card.json`
  (path atual — corrigir o `agent.json` antigo citado em `S2·F12`). Exige o bridge headless persistente
  (**já existe**) + validação determinística de payload anti-SSRF/replay via trust SDAAL **antes** de
  virar ação (`S1·F5/F6`, `S4·F6/F12`). Só depois de P0-3/P0-4 e sob gate humano.
- **Remote MCP connector (opcional).** Expor o core como connector OAuth 2.1/PKCE (`mcp.onionevolve.com`,
  `S1·F10`) para consumo idiomático por Claude Code de outros cores. Complementar ao A2A, não substituto.

**Nenhum item leve exige Temporal/Kubernetes/DB.** O padrão é build estático + reverse_proxy leve sobre
o que já roda.

---

## Reuso das fundações (NÃO reinventar)

| Fundação existente | Como é aproveitada | Achados |
|---|---|---|
| **`graph.sh`** (BFS impact/path/closure; gerador-de-seed sem store; **hoje NÃO ingere `members.yaml`**) | Peça-ponte de P0-2/P0-3/P0-4. Ao ingerir `members.yaml` (nós = membros; arestas = `parent`→adopts/adoptedBy, `specializations`→tags, `trust.*`→confiança) vira: (a) resolver de targeting por atributo/closure (P0-2), (b) dado do console (P0-3), (c) emissor do mapa Mermaid (P0-4). | `S1·F2/F12`, `S2·F1/F2/F4`, `S3·F6/F8`, `S4·F8` |
| **SDAAL** (`task-manager/factory.md` já abstrai `api\|mcp` + fallback; `forge/factory.md` mostra default divergente por domínio) | Precedente **pronto** para um `federation-transport` com adapters `git-async` (default, menor superfície de ataque) \| `local` (carteiro co-deliver/co-relay, já existe) \| `a2a-live` (gated). Fallback gracioso idêntico; `detectTransport()` lê `members.yaml`. | `S1·F4/F5/F7`, `S2·F5/F12`, `S4·F5/F12` |
| **doc-bridge** (`/meta:co-*` + CHANGELOG `alvo:` + inbox/inbound; entrega-sem-commit) | É o **event-store append-only** (git) para o console (P0-3) E o "webhook push offline durável" do par de resiliência A2A (metade que o Onion já tem). Falta só resolver `alvo:` por seletor (P0-2) e a metade viva SSE. | `S1·F5/F11`, `S2·F6`, `S3·F3/F5`, `S4·F2` |
| **Federação formal dormente** (`/meta:federation-*`: veto fail-safe + rollback + ledger de contratos) | É o **control-plane** (SSOT de contratos) que o mercado validou: fail-safe hierárquico "unconfigured = disabled" (`S4·F7`), estrutura TRiSM (`S4·F4`), lifecycle de estados A2A (`S1·F3`). `federation-status` = monitor read-only que vira o console. Ligar reputação (`S4·F3`) como condicionante do veto é evolução futura. | `S1·F3`, `S2·F10`, `S4·F3/F4/F7` |
| **trust SDAAL** (`.claude/utils/trust/` + `trust-log.md` + `pin-integrity-check`) | "Declarado ≠ verificado" **já é** reputação-por-evidência (`S4·F3`) e a camada de autorização do receptor no A2A (`S1·F6`). Endurecer ingestão remota como supply-chain não-confiável antes de `a2a-live` (`S4·F6`). | `S1·F6`, `S4·F3/F6` |

---

## Candidatos a 1º slice (independentes de doutrina)

Ordenados por **menor dependência de decisão doutrinária × maior alívio de dor**. Os dois primeiros
**não exigem** nenhuma decisão sobre IA-fala-IA nem multi-core — são derivação pura do SSOT que já existe:

1. **`graph.sh` ingere `members.yaml` → mapa de adoções derivado (P0-4).** Pré-requisito técnico único
   de quase tudo. Baixo esforço, mata o mapa desenhado à mão do site. Nenhuma doutrina em jogo.
   *(Slice-semente: habilita 2, 3 e 4.)*

2. **Targeting fino por seletor no `alvo:` (P0-2).** Uma vez que (1) exista, `/meta:co-announce` resolve
   `alvo:` como query sobre `specializations`/`mode`/`tier` (padrão ApplicationSet/policy-as-data).
   Zero campo novo no SSOT. Independente de doutrina.

3. **Console read-only = superfície visual do `federation-status` + CHANGELOG (P0-3).** Projeção estática
   (Alpine.js sobre `feed.json`) servida pelo Caddy. Read-only, regenerável, anti-plataforma. Reusa (1).

4. **Receiver que acorda a sessão (P0-1 parcial).** Evolui o hook "you have mail" sem trair pull/git-async
   nem I3. Ganho de responsividade sem abrir canal vivo.

**Fica para fase 2 gated (exige decisão de doutrina):** `a2a-live` para o Grana.Ai (P0-1 completo) e
reputação-condicionante do veto — ambos dependem do veredito multi-core e do gate humano.

---

## Confiança e gaps

### Sólido (confirmed em fonte primária, base segura de decisão)

- **Par de resiliência A2A** (SSE conectado + webhook offline + lifecycle 8 estados + resubscribe):
  `S1·F2/F3/F4/F5` batem **literalmente** com a spec oficial. Maturidade real (v1.0, 150+ orgs,
  produção enterprise, ACP fundido): `S1·F1/F13/F14`, `S4·F5`.
- **Padrões de sync do mercado** (Backstage relações derivadas, ApplicationSet seletores, Argo CD Agent
  hub-spoke, Flux pull+webhook, Renovate presets, control/data plane): `S2·F1/F2/F3/F5/F6/F7/F10` —
  fontes primárias de docs oficiais.
- **Console = estático append-only sem plataforma**: `S3·F1/F3/F5/F8/F9/F10` (custo Backstage, ES/CQRS,
  git append-only, YAML→Mermaid, yst, Caddy) — âncoras high sólidas.
- **Doutrina Onion validada + erros do mercado que a corroboram**: `S4·F1/F3/F5/F9/F11/F12` (anti-padrão
  multi-agente Anthropic verbatim, RepuNet, A2A, plugins GA, FL cross-silo, threat-modeling).
- **Motor/execução**: Claude Agent SDK + subagents (`S1·F9`), durable execution AWS (`S1·F11`),
  policy-as-data OPA (`S1·F12`).

### Incerto / rebaixado (declarado ≠ verificado — NÃO usar como base)

- **`S1·F8` (AAIF governa MCP E A2A + spec conjunta) → hypothesis.** O press release primário da AAIF
  **não menciona A2A** (âncoras são só MCP/goose/AGENTS.md). O vínculo A2A↔AAIF vem de secundárias.
  A formação (dez/2025) e co-fundadores estão confirmados; o resto, não.
- **`S1·F15` (AIP/delegação verificável cross-MCP/A2A) → hypothesis.** arXiv IDs **não verificados
  individualmente**. Direção futura do bloco `trust:`, nunca base de decisão.
- **`S2·F11` (mesh-CRDT remove SPOF) → hypothesis.** A especificidade CRDT **não tem fonte primária**
  (o arXiv é liqo/multi-cluster K8s). Trade-off SSOT-vs-mesh é real; "CRDT" não é conclusão fonteada.
- **`S2·F12`/`S3` drift factual:** path correto é `/.well-known/agent-card.json` (não `agent.json`);
  corrigir na costura futura.
- **`S4·F7` (Copilot org-instructions git/rollback/audit) → hypothesis.** A citação **confla dois
  features** e aponta a fonte errada: version-control/rollback aplica a instruções de **repo**
  (`.github/copilot-instructions.md`), não ao feature org-GA (config via UI); fail-safe é changelog
  separado. Os fatos existem; a citação, não. A implicação p/ Onion sobrevive.
- **`S4·F8` / `S3·F11` → hypothesis.** "Uma fonte compila para alvos" (dev.to, baixa autoridade) e
  "Alpine sozinho/~15KB" (fonte não sustenta os específicos). Direção plausível, decisão de tooling
  fica em aberto.
- **Estatísticas fabricadas/mis-fonteadas (remover antes de citar em doutrina):** `S2·F4` ("30→5 min",
  "3-4 engenheiros"), `S2·F8` ("198 deps/14 workspaces/18 PRs"), `S2·F9` ("63% das empresas 50+ devs"),
  `S4·F6` ("30%+ de 1.800 servidores" — comparáveis dão ~7%). Os claims qualitativos sobrevivem; os
  números, não.
- **Cores não-load-bearing:** `S3·F3` ("LinkedIn usa ES para feeds") e `S3·F5` ("escritor único") não
  estão nas fontes citadas — remover sem impacto na tese.

### O que ainda falta pesquisar (não coberto pelos streams)

- **Esquema concreto do resolver de targeting** (`alvo:` como query): sintaxe, precedência entre
  seletores, comportamento de closure gated no `graph.sh`. É design, não pesquisa de mercado — dogfood.
- **Especificação do handshake `a2a-live` gated** para o caso Grana.Ai (regulado, `integration_branch:
  develop`, nunca live-pull): como o gate humano + `pin-integrity-check` se encaixam no lifecycle A2A.
- **"Registry de capacidade governado" é problema não-resolvido no mercado** (`S2` alerta: proposta
  Backstage MCP registry travada). O Onion não deve assumir padrão pronto de descoberta governada —
  daí manter A2A/registry gated.
- **Reputação como condicionante de decisão** (RepuNet aplicado ao veto/urgência, `S4·F3`): teoria
  sólida, aplicação ao Onion ainda é hipótese a validar em dogfood.
```
