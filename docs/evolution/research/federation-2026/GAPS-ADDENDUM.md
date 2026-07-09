# ADDENDUM aos gaps — 2ª rodada da pesquisa da Federação Onion (2026)

> **Complemento append-only ao [`SYNTHESIS.md`](SYNTHESIS.md).** Não o reescreve — fecha os gaps que
> ele deixou abertos em §"O que ainda falta pesquisar" e firma (ou refuta) os achados que a 1ª rodada
> rebaixou a `hypothesis`. Consolida os 4 streams desta rodada: **G1** (handshake `a2a-live` gated
> regulado + HITL), **G2** (registry de capacidade governado), **G3** (reputação-condicionante +
> SSOT-vs-mesh), **G4** (re-verificação dos rebaixados load-bearing).
>
> **Natureza:** insumo de evidência para a decisão do maestro — **não é doutrina**. Cada achado
> material tem FONTE (URL) nos arquivos G1–G4. `declarado ≠ verificado` está marcado onde a fonte é
> preprint/fornecedor/secundária ou onde o texto é implicação derivada, não citação literal.
>
> **Nota de método sobre a verificação adversarial desta rodada:** os payloads de verificação de
> **G1** e **G2** vieram contaminados com stubs de teste (`claim: "test"/"teste"`, fontes `http://x`
> e `example.com` — domínio reservado da IANA, RFC 2606/6761). Esses vereditos placeholder
> (`hypothesis`/`refuted`) **não** se referem aos achados reais dos arquivos — os próprios arquivos
> alertam para não confundir o stub com o F1 real (G2 §"Verificação adversarial"). Os achados
> materiais de G1 e G2 se sustentam nas suas **fontes primárias próprias** (spec A2A oficial, blog
> oficial MCP, docs Docker/npm/Red Hat), verificadas nos arquivos. **G3** e **G4** trazem verificação
> adversarial íntegra: 9/9 e 7/7 `confirmed` com primária batida um a um.

---

## Gaps fechados

Os três gaps de pesquisa que o SYNTHESIS listou como abertos (§283-293) — o 1º item da lista, "esquema
do resolver de targeting", é **design/dogfood, não pesquisa**, e segue em §Gaps remanescentes.

### Gap "handshake `a2a-live` gated" (regulado, caso Grana.Ai) — **FECHADO** (G1)

O gate humano assíncrono que o Onion queria **não é enxerto no A2A — é o consumo idiomático da spec**:

- **[confirmed] `input-required`/`auth-required` são estados de INTERRUPÇÃO nativos** que pausam a task
  de forma retomável (`G1·F1`, spec oficial primária). O gate do maestro se acopla aí.
- **[confirmed] `auth-required` DELEGA ao cliente, "fora do protocolo A2A", a obtenção de
  consentimento/credenciais** (`G1·F2`) — a autorização mora out-of-band **por construção da spec**, que
  é exatamente onde o maestro + `pin-integrity-check` vivem. É a peça-chave do gap: "sem live-pull
  automático" é o desenho previsto, não uma violação.
- **[confirmed] O receptor DEVE verificar autenticidade antes de agir**: JWS/JWT assinado
  (`iss/aud/iat/exp/jti`, JWKS por `kid`), anti-replay por `jti` single-use + janela de timestamp
  (`G1·F5`), anti-SSRF normativo — allowlist + ownership challenge + egress firewall, bloquear
  localhost/faixas privadas/metadata (`G1·F6`). **Isto É o `pin-integrity-check` do lado A2A**, e roda
  na fronteira transport→task do receptor, não depois.
- **[confirmed] Auth é agent-card-driven + transport-only** (sem identidade no payload),
  `securitySchemes` OpenAPI (OAuth2/OIDC/mTLS/apiKey) (`G1·F3`), sobre substrato OAuth 2.1 com **PKCE
  obrigatório** (`G1·F4` — *ressalva `declarado ≠ verificado`: OAuth 2.1 ainda é draft IETF, estável mas
  não RFC final*).
- **[confirmed via fornecedor] Defesa-em-profundidade do receptor** (`G1·F7`, Red Hat): Agent Card
  **assinado**, TLS contra CA confiável, parser JSON-RPC patchado, cliente verifica "notificação vem de
  servidor confiável **E** é relevante". Ponto mais material: **a A2A não tem controle nativo contra
  prompt-injection cross-agent** → é o argumento técnico mais forte para o `a2a-live` transportar **só
  sinais gated**, não conversas autônomas.
- **[confirmed] O padrão mecânico do "gate humano no meio de async" é durable-execution pause/resume por
  signal** (`G1·F8`, Temporal): suspende com zero compute, estado persistido, aprovação chega como
  Signal, timer durável faz SLA/escalonamento/auto-reject. **O Onion já tem a metade durável** (inbox
  commitado = checkpoint; entrega-sem-commit = idempotência); o `a2a-live` só adiciona a metade viva
  (SSE/webhook) para acordar o gate — sem trair o "nunca live-pull".

**Veredito do gap:** o handshake regulado **não precisa inventar o gate** — mapeia
`auth-required`/`input-required` ao gate do maestro e roda o `pin-integrity-check` como a
verificação-antes-de-agir que a própria spec A2A já **exige** do receptor.

### Gap "registry de capacidade governado é problema não-resolvido" — **FECHADO com veredito refinado + citação corrigida** (G2)

O alerta da 1ª rodada estava **certo na direção, errado na força, impreciso na citação**. O quadro real
tem duas camadas:

- **[refutado — leitura forte] "não existe padrão pronto de descoberta governada".** Falso desde
  set/2025: **MCP Registry oficial** (Anthropic + GitHub + Microsoft + Block + PulseMCP), com governança
  de namespace reverse-DNS + verificação GitHub OIDC/DNS + moderação por denúncia (`G2·F1/F2`, blog
  oficial MCP primário); **Docker MCP Catalog** com assinatura + SBOM + provenance + commit-pinning
  (`G2·F4`); **Agent Card A2A** em `/.well-known/agent-card.json` (`G2·F6`); plugins Anthropic com
  "safety screening" (`G2·F8`). **A descoberta está padronizada.**
- **[confirmado — direção, com fonte muito melhor] curadoria/confiança GOVERNADA EM ESCALA continua
  não-resolvida.** O próprio ecossistema diz: *"the registry solved discovery; the next challenge is
  trust"* — **64,7M entradas para 1.691 pacotes reais**, typosquatting persistente, meta-registry que
  empurra validação pro downstream (`G2·F3`, SafeDep — *secundária, mas quantitativa e corroborada pelas
  specs primárias*). E as specs **delegam** a curadoria: A2A *"does not prescribe a standard API for
  curated registries"* (`G2·F6`); sub-registry curado no MCP é do consumidor (`G2·F1`).
- **[correção de citação — achado de campo] `IBM/mcp-context-forge#2809` NÃO é "a proposta Backstage
  travada"** — é um **EPIC do IBM ContextForge** (aberto). A proposta Backstage genuinamente parada é
  outra: `community-plugins #4034` + RFC `#32062` (`G2·F5`). **Recomenda-se editar o SYNTHESIS** (§289)
  para trocar a fonte/rótulo — a tese sobrevive mais forte.

**Veredito do gap:** o que o mercado **não** resolveu é exatamente a peça que a curadoria humana do
maestro **é** — o "curated, security-first sub-registry" que a indústria aponta como fator decisivo de
adoção. Para 5 membros, o `members.yaml` **já é** esse sub-registry privado curado; o `pin` **já é** a
provenance-por-commit (`source.commit` do Docker / atestação npm-Sigstore-SLSA, `G2·F4/F7`); o
`.claude/validation/` **já é** o "safety screening". **Manter A2A/registry GATED e curar à mão não é só
defensável — é a posição que a própria evidência recomenda** para esta escala.

### Gap "reputação como condicionante de decisão" — **FECHADO: sobe de teoria imatura a evidência-simulação sólida (gated)** (G3-A)

- **[confirmed] RepuNet** (arXiv:2505.05029): reputação dual-level (agente + rede) por interação direta
  + gossip **condiciona conectar/cortar pares** (`wi→j(t) ∈ {Y,N}`); participação **0,19 → 0,85**,
  investimento **0,17 → 0,98**; emerge *"social isolation of exploitative agents"* — reputação como
  **gate de exclusão**, não só escore (`G3·A1`, números exatos batidos).
- **[confirmed] Attention-based Trust Management** (arXiv:2506.02546v2): threshold de aceitação
  (`score > τ` → filtra) + **registro temporal de violações por agente** + **remoção automática** quando
  a taxa de violação passa de ~80% numa janela de 20 queries; ataque AiTM **94,6% → 23,5%**, **100%** de
  detecção de agente malicioso, perda de utilidade limpa **< 2%** (`G3·A2`). *Ressalva de calibração: o
  paper tem 3 ações — inclui "request further verification" — logo "filtra, não questiona" é leve
  simplificação; números materiais intactos.*
- **[confirmed] Reputação é P2P + gossip** (`G3·A3`) — **não exige autoridade central**, pode viajar pelo
  próprio mesh git-async (CHANGELOG/inbox como veículo de gossip verificável). Reconcilia as duas
  metades de G3: identidade single-source, reputação circula pelo mesh.
- **[confirmed] Maturidade** (`G3·A4`, ACM CS 10.1145/2816826 + TRiSM Agentic AI arXiv:2506.04133v2):
  campo acadêmico longo, mas a onda LLM-agent é 2025-2026 e **só em simulação/benchmark**, sem
  "unified framework"/governança multi-org em produção.

**Veredito do gap:** reputação-por-evidência é mecanismo **real e forte** para condicionar
aceite/veto/prioridade — mas os números (85%, 23,5%) são **de simulação, não promessa de produção**.
Aplicação ao veto **permanece GATED atrás de dogfood**: instrumentar o `trust-log` para acumular
histórico primeiro, medir, e só então deixar a reputação **mexer no threshold** do veto. Não vira
doutrina automática nesta rodada.

---

## Achados rebaixados: firmados ou refutados (G4)

Todos os quatro rebaixados load-bearing fecharam com fonte primária. **Nenhum achado material do
SYNTHESIS foi derrubado** — as correções são de citação e estatística, não de tese; em dois pontos a
doutrina fica **mais** defensável.

### S1·F8 (AAIF governa MCP *e* A2A + spec conjunta) — **REFUTADO no claim forte** (`G4-01/02`)

- Os **dois press releases primários da Linux Foundation** confirmam: a AAIF (formada 09-dez-2025)
  ancora **só MCP, goose e AGENTS.md** — **A2A não é mencionado**; o press release do A2A (09-abr-2026)
  **não** cita a AAIF e chama A2A de *"another Linux Foundation project"*, complementar ao MCP.
- **[confirmed — claim atenuado verdadeiro]** MCP e A2A são **ambos projetos LF, oficialmente
  complementares** (A2A = horizontal/peer entre orgs; MCP = vertical/tools internas). 8 platinum
  fundadores AAIF: AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI. A2A cresceu
  de 50+ para **150+ organizações** no 1º ano.
- **Ação no texto:** cortar "AAIF governa MCP e A2A" e "spec conjunta"; afirmar só "ambos LF,
  complementares". O argumento "convergência de governança reduz risco de órfão" **sobrevive em forma
  atenuada** (mesma organização-guarda + complementaridade oficial).

### S1·F15 (delegação verificável cross-MCP/A2A) — **CONFIRMADO como direção de pesquisa ativa** (`G4-03/04/05`; `G1·F9`)

Os **três arXiv IDs** antes não verificados **existem e batem exatamente**:

- **arXiv:2603.24775 — AIP** (Sunil Prakash, 25-mar-2026): Invocation-Bound Capability Tokens (IBCTs),
  bindings MCP/A2A/HTTP, overhead 2,35ms. *Status: preprint autor-único + draft IETF individual + PyPI
  alpha 0.1.1 — **não** endossado por Anthropic/Google.*
- **arXiv:2606.03518 — Overlaying Governance** (Ibrahim & Li, 02-jun-2026): delegação como relação
  **contratual com accountability** + resource scope attenuation + provas formais.
- **arXiv:2604.16524 — Anumati** (Kadaboina, 16-abr-2026): distingue proof of acceptance de proof of
  adherence; estende A2A+MCP; TLA+ + Python de referência.

**Veredito de doutrina inalterado:** direção futura monitorada do bloco `trust:` — gate humano do
maestro + trust SDAAL seguem necessários; adotar seria prematuro. `declarado ≠ verificado`: são
**propostas acadêmicas independentes, não standards**.

### Estatística MCP tool-poisoning — **CORRIGIDA (números reais)** (`G4-06`)

- O "**30%+ de 1.800 servidores**" da 1ª rodada é **conflado/superestimado**. O survey primário
  **arXiv:2506.13538** ("MCP at First Glance", **1.899 servidores** open-source) dá:
  - **7,2%** com vulnerabilidade geral
  - **5,5%** com tool-poisoning MCP-específico
  - (66% com code smells; 8 vulnerabilidades distintas, só 3 sobrepondo software tradicional)
- **Fato mais forte** (corroboração AIP, arXiv:2603.24775): scan de **~2.000 servidores MCP, TODOS sem
  autenticação por padrão**. A medida honesta distingue "vuln explorável (~7%)" de "sem auth
  (quase universal)".
- **Ação no texto:** substituir "30%+ de 1.800" (SYNTHESIS §57-58, §278; S4·F6) por os números reais.
  O thrust `never-clobber` + ingestão gated **sai reforçado** — o dado "sem auth universal" pesa mais
  que o número inflado.

### Custo self-host Backstage — **FIRMADO com ressalva de viés** (`G4-07`)

- Números concretos (verbatim): **≥3 engenheiros dedicados**, **~$450k/ano**, **6-12 meses** a produção,
  **>$800k** no 1º ano. `declarado ≠ verificado` de forma parcial: fonte é **David Tuite, CEO da Roadie**
  (Backstage gerenciado) → **viés de fornecedor** direcional (tende ao teto).
- **Veredito:** o build-vs-buy do S3 **sobrevive ao desconto do viés** — mesmo pela metade, é 1+ ordem
  de grandeza acima do valor para ~5 membros. Citar com o disclaimer.

### "63% das empresas com 50+ devs usam monorepo" — **SEM FONTE → permanece `hypothesis`/não-usar** (`G4-08`)

- A fonte citada (nx.dev) **NÃO contém** o número; busca ampla não achou survey quantitativo de adoção.
  O que há de sólido são **estudos de caso** (Google/Piper, Meta/Sapling, Microsoft/Windows-em-Git,
  Uber) — não taxa de adoção.
- **Ação no texto:** trocar por afirmação qualitativa por estudos de caso. O argumento de S2·F9 (Nx
  resolve enforcement **dentro** do monorepo; o core federa no nível do **repo**) **não depende** do
  número — decorre das capacidades do Nx (boundaries/generators/conformance), que seguem confirmadas.

---

## O veredito multi-core se sustenta?

**Sim — e sai MAIS forte.** Na 1ª rodada, o veredito "single-source para identidade/contratos + mesh de
comunicação git-async (+ `a2a-live` gated)" repousava parcialmente em `S2·F11` (mesh-CRDT remove SPOF),
que estava **rebaixado a `hypothesis`** por falta de fonte primária. G3-B fecha os dois lados com
primária:

- **[confirmed, reenquadrado] `S2·F11` passa de hipótese a claim confirmado** (`G3·B1`, Wikipedia CRDT +
  crdt.tech, verbatim): CRDT **de fato** remove o coordenador central como SPOF — **mas precificado pelo
  CAP** (consistência eventual, não forte; overhead de metadados/tombstones "may be costly"). O corte
  **não é escala e sim natureza-do-dado**: identidade/contratos = **recurso-exclusivo → consistência
  forte, single-writer**; comunicação = **estado-colaborativo → replicação otimista (mesh)** (`G3·B2`).
- **[confirmed] A comunicação git-async do Onion JÁ É replicação otimista canônica** (`G3·B3`, Saito &
  Shapiro MSR TR-2003-60 + Wikipedia Optimistic replication): o modelo copy-modify-merge do git/CVS é o
  exemplo seminal. "Federar só a comunicação via mesh git-async" **não é invenção** — é aplicar um
  modelo já provado. A pré-condição "conflitos raros" é satisfeita pelo invariante **um-escritor-por-repo**.
- **[confirmed] Num ledger single-writer em N≈5, o valor-núcleo do CRDT (multi-escritor concorrente sem
  coordenação) fica OCIOSO** (`G3·B4` — *materialidade média: implicação derivada honestamente rotulada,
  não citação literal*). CRDT é over-engineering **não** por "cedo demais em escala", mas porque **a
  condição de uso não existe** na identidade.
- **[confirmed] Control-plane central único = ótimo operacional em escala pequena** (`G3·B5`, Red Hat /
  Argo CD — *fonte de fornecedor*): hub-and-spoke, "Git serves as single source of truth", SPOF residual
  mitigado por **HA + ledger versionado** (não por mesh). `declarado ≠ verificado` parcial: o próprio
  Argo CD Agent descentraliza para reduzir o SPOF, então "remédio é HA e NÃO mesh" é levemente forte —
  mas o núcleo (control-plane único ótimo + **Grana.Ai como agente/data-plane subordinado, não
  `role:source`**) está confirmado por primária de fornecedor.

**Ajuste necessário no SYNTHESIS:** substituir a nota §266 que marca `S2·F11` como `hypothesis` ("a
especificidade CRDT não tem fonte primária; o arXiv citado é liqo/multi-cluster K8s") — agora há fonte
primária CRDT direta, e o veredito muda de "defensável apoiado em hipótese" para **"firmado por evidência
melhor dos dois lados"**. O gatilho de revisão (§165: reabrir se surgir 2º hub escrevendo identidade
concorrentemente e desconectado por longos períodos) **permanece** — é exatamente a condição que ligaria
o valor ocioso do CRDT.

**Conclusão:** o veredito não precisa de ajuste de direção; precisa apenas da **atualização de citação**
(S2·F11 confirmed) e ganha robustez. Nenhuma evidência nova contradiz single-source + mesh + a2a-live
gated.

---

## Impacto na fase-2 / 1º slice

**Os candidatos a 1º slice não mudam.** Os dois primeiros (independentes de doutrina) seguem intactos e
**ganham reforço de formato** de G2:

1. **`graph.sh` ingere `members.yaml` → mapa derivado (P0-4).** Inalterado como slice-semente. G2·F6/F1
   sugerem, a **custo ~zero de schema**, alinhar a grafia aos formatos emergentes: identidade em
   **namespace reverse-DNS por membro**, **Agent Card derivado** em `/.well-known/agent-card.json`, `pin`
   documentado como provenance-de-commit, tier de trust **`verified|community`** visível — prepara
   interop com MCP Registry / A2A sem comprometer o gate.
2. **Targeting fino por seletor no `alvo:` (P0-2).** Inalterado — resolver `alvo:` como query sobre
   `specializations`/`mode`/`tier`. G3·A2 acrescenta vocabulário reutilizável (threshold de aceitação +
   registro de violação) para uma evolução futura *gated*, não para o slice.
3. **Console read-only (P0-3).** Inalterado; G2·F4 sugere expor o tier de trust (`verified` vs
   `community`) por membro na superfície visual.
4. **Receiver que acorda a sessão (P0-1 parcial).** Inalterado — **e G1·F6 endurece**: como o
   `PushNotificationConfig.url` é input não-confiável, o receiver deve nascer com allowlist derivado do
   `members.yaml` + egress bloqueando privado/metadata, para não virar pivô SSRF.

**Fase 2 gated — o handshake regulado (G1) NÃO muda a decisão, mas dá o desenho pronto:**

- O `a2a-live` para o Grana.Ai deixa de ser "especificação a pesquisar" e vira **desenho fundamentado**:
  Agent Card **assinado** em `/.well-known/agent-card.json` com `securitySchemes: [oauth2 (2.1+PKCE),
  mtls]`; sinal recebido entra como task que **pausa em `input-required`/`auth-required`** → gate do
  maestro; **antes** de virar task, a fronteira do receptor roda o `pin-integrity-check` do lado A2A
  (JWS `kid`→JWKS, `jti` single-use, janela de timestamp, allowlist, egress) — `G1·F1-F7`.
- **Confirmação-chave para o regulado:** "nunca live-pull" é **compatível e previsto** pela spec — o
  `auth-required` delega o consentimento out-of-band ao cliente (`G1·F2`), e o transporte carrega
  **sinais gated**, não live-pull automático. Isso **remove a incerteza** que mantinha o a2a-live como
  "fase 2 a pesquisar" — continua fase 2 (exige o veredito multi-core + gate humano), mas o **risco de
  desenho caiu**.
- **Reputação-condicionante do veto** permanece fase-2 gated (G3·A4): instrumentar/medir o `trust-log`
  antes de deixar a reputação mexer no threshold. Não muda de status nesta rodada.

**Reforço técnico transversal (não muda slice, endurece a doutrina):** a A2A **não tem** controle nativo
contra prompt-injection cross-agent (`G1·F7`) — argumento primário mais forte para o `a2a-live`
transportar **só sinais gated**. A estatística corrigida "MCP quase todo sem auth" (`G4-06`) reforça
`never-clobber` + ingestão gated mais que o número inflado.

---

## Gaps REMANESCENTES

O que ainda é **design/dogfood, não pesquisa de mercado** — a pesquisa está encerrada nestes pontos, a
resolução é fazer:

- **Esquema concreto do resolver de targeting** (`alvo:` como query) — **DESIGN, não pesquisa** (já era
  assim no SYNTHESIS §285). Falta definir: sintaxe do seletor, precedência entre seletores, comportamento
  de **closure gated** no `graph.sh` após ingerir `members.yaml`. O padrão de mercado (ApplicationSet
  generators / policy-as-data) já está confirmado como referência; a instância concreta é dogfood.
- **Assinatura criptográfica / OIDC do Agent Card e do `pin`** — **não-necessária na escala atual**
  (`G2·F7`: transporte git-async entre repos do próprio maestro, um-escritor-por-repo). É **gatilho de
  revisão**, não gap: se um adotante passar a rodar CI que publica artefatos consumidos por terceiros,
  adotar provenance Sigstore/SLSA + JWS no Agent Card vira barato e idiomático.
- **Instrumentação do `trust-log` para reputação-condicionante** — **dogfood**, pré-requisito para
  qualquer decisão de ligar reputação no threshold do veto (G3·A4). Acumular histórico → medir → só
  então decidir. Não é pesquisa: os mecanismos (RepuNet, Attention-Trust) já estão confirmados.
- **Materialização concreta do `federation-transport` SDAAL** com adapters `git-async` (default) |
  `local` (já existe) | `a2a-live` (gated) — **design/implementação**. A costura de referência
  (task-manager/forge factory) já existe; falta escrever o adapter.
- **OAuth 2.1 como draft IETF** (`G1·F4`) — não é gap de pesquisa, é **acompanhamento**: estável e já
  usado pelo Claude Code para MCP remoto, mas ainda não é RFC final. Sem impacto no desenho; monitorar a
  finalização.

**Nada material do SYNTHESIS foi reaberto ou derrubado.** Esta rodada fecha os três gaps de pesquisa,
firma os quatro rebaixados load-bearing, e corrige três citações/estatísticas (S1·F8 atenuado, S2·F11
confirmed, "30%+" → 7,2%/5,5%, "63% monorepo" removido, `#2809` reatribuído) — a tese central sai
intacta e, em vários pontos, mais defensável.
