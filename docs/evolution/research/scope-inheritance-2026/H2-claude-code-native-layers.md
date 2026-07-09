# H2 — Camadas NATIVAS do Claude Code (o vetor)

> Stream H2 da pesquisa de **herança-de-escopo** do Sistema Onion (scope-inheritance-2026).
> Pergunta-mãe: como VERSIONAR, HERDAR e POLIMORFAR a entrega do Onion (`.claude` + docs +
> agentes + scripts) através de uma HIERARQUIA DE ESCOPOS — framework → empresa → time → pessoa —
> **cavalgando a corrente do mercado (Claude Code é o vetor)** e sem criar atrito.
> Gatilho de campo: **Grana.Ai** (adotante regulado, nx monorepo com time de devs + stage/prod).

Todas as datas de acesso: 2026-07-09. Prioridade a fontes primárias (`docs.anthropic.com` /
`code.claude.com` / `support.claude.com` / repo oficial `anthropics/claude-code`).

---

## Resumo executivo

O Claude Code **já cascateia** boa parte do que a herança-de-escopo do Onion precisa — mas com uma
assimetria decisiva que muda o veredito de mecanismo:

1. **A camada COGNITIVA (instruções) já é MERGE-N-CAMADAS nativo.** `CLAUDE.md`, `.claude/rules/` e
   skills **concatenam** ao longo da árvore de diretórios (raiz → cwd) e da hierarquia de escopo
   (managed → user → project → local). Não sobrescrevem: **compõem**. Isso é exatamente o que o
   maestro queria (herança que COMPÕE, não branches que você "fica em cima de uma por vez"). O
   **time-dentro-do-repo já existe nativamente** via `CLAUDE.md`/skills por diretório de pacote —
   o "achado central" (sub-repo scoping não existe) precisa ser **corrigido** para a camada cognitiva.

2. **A camada de CONFIGURAÇÃO (settings.json) NÃO cascateia pela árvore.** Ao contrário do
   `CLAUDE.md`, o `settings.json` de projeto **só carrega do diretório onde você inicia** — não é
   herdado dos pais. Precedência é por ESCOPO (managed > CLI > local > project > user), não por
   PROFUNDIDADE de diretório. Aqui **não há herança N-camadas nativa** — é o gap real, e é onde o
   `vendor-branch.sh` (Base 2) generalizado para N-camadas continua necessário.

3. **A DISTRIBUIÇÃO versionada por grupo já existe — mas só no plano gerenciado (Team/Enterprise) e
   com um buraco no CLI.** Marketplace de org + `enabledPlugins` + acesso-por-grupo (Enterprise) dão
   versionamento + proveniência (namespace `plugin:skill`). Mas: (a) settings server-managed **ainda
   não** suportam per-group (só plugins suportam); (b) plugins de managed settings **não auto-instalam
   no CLI** (issue fechada como *not planned*) — atrito direto para o adotante regulado.

**Veredito de mecanismo (deste stream):** híbrido — **CASCATA-NATIVA** para a camada cognitiva
(cavalgar `CLAUDE.md`/rules/skills por diretório + `@import`), **MERGE-N-CAMADAS** (vendor-branch
generalizado) para o artefato `.claude`/settings onde a cascata nativa falha, e **plugins+grupos**
para distribuição versionada com proveniência. **Não** branches como veículo de herança.

---

## Achados

### Achado 1 — Precedência de settings: managed > CLI > local > project > user (escopo, não profundidade)
- **Claim:** A ordem exata é, do maior para o menor: **Managed** (não pode ser sobreposto por nada,
  nem por CLI) → **Command line** → **Local** (`.claude/settings.local.json`) → **Project**
  (`.claude/settings.json`) → **User** (`~/.claude/settings.json`). Citação: *"1. Managed (highest):
  can't be overridden by anything; 2. Command line arguments; 3. Local; 4. Project; 5. User (lowest)."*
- **Fonte:** https://code.claude.com/docs/en/settings (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** É a espinha da cadeia framework→empresa→time→pessoa **para configuração**,
  mas mapeia por ESCOPO, não por nível hierárquico arbitrário: user=pessoa, project=repo/time,
  managed=empresa. Não há um "nível" nativo entre project e user para "time dentro do repo".
- **Base reusável tocada:** Base 1 (`resolve-integration-branch.sh` — cadeia de precedência): o
  Onion pode **espelhar exatamente essa ordem** na sua própria resolução por camadas, em vez de
  inventar outra.

### Achado 2 — Merge de arrays vs override de escalares (a semântica de composição nativa)
- **Claim:** *"Arrays merge across settings sources rather than override"* (ex.: `allowedHttpHookUrls`
  de user + project **concatenam**), enquanto escalares seguem precedência (*"if user sets
  `spinnerTipsEnabled` true and project sets false, the project value applies"*). Regras de permissão
  também **mergeiam** entre escopos. `claudeMdExcludes`: *"Arrays merge across layers."*
- **Fonte:** https://code.claude.com/docs/en/settings (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** O nativo **já distingue** "campo que compõe" (array → union) de "campo que
  vence" (escalar → precedência). É o mesmo dilema do merge N-camadas do Onion (o que soma vs o que
  sobrepõe). Adotar essa convenção evita reinventar regra de merge.
- **Base reusável tocada:** Base 2 (vendor-branch: base+override) — a política array-merge/scalar-win
  é a regra de resolução de conflito que o merge N-camadas do Onion precisa codificar.

### Achado 3 — Chaves de trava "só-empresa" (o veículo de "empresa que trava")
- **Claim:** Managed settings são imutáveis e expõem chaves que **só** valem em managed:
  `allowManagedPermissionRulesOnly`, `strictKnownMarketplaces`/`blockedMarketplaces` (trava
  marketplace), `availableModels`+`enforceAvailableModels`, `forceLoginOrgUUID`/`forceLoginMethod`,
  `disableBypassPermissionsMode`, `allowManagedHooksOnly`, e `claudeMd` (conteúdo de CLAUDE.md
  gerenciado). *"Managed settings parse tolerantly... A single typo cannot disable the rest of your
  organization's policy."*
- **Fonte:** https://code.claude.com/docs/en/settings ; https://code.claude.com/docs/en/permissions
  (managed-only settings) (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** É o mapeamento direto de **empresa = camada que trava** (compliance
  Grana.Ai: forçar modelos aprovados, negar leitura de `.env`, travar marketplaces). O Onion não
  precisa construir "enforcement" — cavalga `permissions.deny` + managed-only keys.
- **Base reusável tocada:** Base 1 (resolução por camadas com uma camada terminal não-sobreponível).

### Achado 4 — CLAUDE.md hierárquico CONCATENA (não sobrescreve) — o merge-n-camadas cognitivo nativo
- **Claim:** Escopos de `CLAUDE.md` em ordem de carga (amplo→específico): **Managed policy**
  (`/Library/Application Support/ClaudeCode/CLAUDE.md` · `/etc/claude-code/CLAUDE.md` · Windows
  `C:\Program Files\ClaudeCode\CLAUDE.md`, ou chave `claudeMd`) → **User** (`~/.claude/CLAUDE.md`) →
  **Project** (`./CLAUDE.md` ou `./.claude/CLAUDE.md`) → **Local** (`./CLAUDE.local.md`, gitignored).
  Crucial: *"All discovered files are concatenated into context rather than overriding each other...
  content is ordered from the filesystem root down to your working directory."* Precedência em
  conflito: *"managed > project > user"* (mais específico vence a intenção).
- **Fonte:** https://code.claude.com/docs/en/memory (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** A camada de **DOUTRINA/contexto** (spec do framework + contexto local do
  repo, o coração do SDAAL) **já é herança em runtime cognitivo, nativa e N-camadas**. Framework
  (managed/user) + empresa + repo + local **compõem** sem branch. É a evidência mais forte de que a
  herança cognitiva do Onion deve CAVALGAR esse veículo, não construir outro.
- **Base reusável tocada:** Base 4 (camadas nativas) + o `*-context` local que a IA lê p/ especializar
  (o "distilled = herança de DOUTRINA reescrita" do `roles.yaml` casa com `claudeMd` gerenciado).

### Achado 5 — CLAUDE.md por diretório: o TIME-DENTRO-DO-REPO já existe nativamente
- **Claim:** *"Claude Code loads every CLAUDE.md file from your working directory and every parent
  directory at launch, then loads each subdirectory's file on demand when it reads files there."* Em
  monorepo, o padrão recomendado é **um `CLAUDE.md` por pacote** (`packages/api/CLAUDE.md`,
  `packages/web/CLAUDE.md`), commitado: *"Commit these files to the repository so teammates inherit
  them. Each directory's owner typically maintains its file."* Idem para **skills por diretório**
  (`packages/api/.claude/skills/`) que só carregam quando relevantes.
- **Fonte:** https://code.claude.com/docs/en/large-codebases ; https://code.claude.com/docs/en/memory
  (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** **CORRIGE o "achado central"** da pesquisa: sub-repo scoping (time dentro
  de um repo) **existe nativamente para a camada cognitiva** — o "time desenvolvimento" da Grana.Ai é
  um `packages/<time>/CLAUDE.md` + `packages/<time>/.claude/skills/`, herdando o `CLAUDE.md` raiz por
  concatenação. O gap sobra só para **settings** (Achado 7) e para o **4º nível pessoa** (Achado 11).
- **Base reusável tocada:** Base 4. Encaixe do `roles.yaml` (bundle por papel) num eixo de DIRETÓRIO,
  não de branch.

### Achado 6 — `@import` (transclusão, profundidade 4) — composição explícita nativa
- **Claim:** *"CLAUDE.md files can import additional files using `@path/to/import` syntax... Relative
  paths resolve relative to the file containing the import... Imported files can recursively import
  other files, with a maximum depth of four hops."* Para compartilhar preferências pessoais entre
  worktrees: *"import a file from your home directory instead: `@~/.claude/my-project-instructions.md`."*
  Import de `@AGENTS.md` também é suportado.
- **Fonte:** https://code.claude.com/docs/en/memory (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** Dá um mecanismo **declarativo** de herança: um `CLAUDE.md` de time pode
  `@import` a doutrina do framework (`@~/.claude/onion/...` ou um caminho vendorizado), tornando a
  composição **explícita e versionável** — cada camada declara de quem herda. Proveniência por
  construção. Limite de 4 hops delimita a profundidade framework→empresa→time→pessoa (cabe).
- **Base reusável tocada:** Base 3 (SUPERSEDES/versionamento de conhecimento): `@import` é o "ponteiro"
  para a verdade herdada; a reescrita local (override) fica ao lado, no mesmo arquivo.

### Achado 7 — ASSIMETRIA CRÍTICA: settings.json NÃO herda pela árvore (o gap real)
- **Claim:** *"Project settings in `.claude/settings.json` load only from your starting directory and
  are not inherited from parent directories the way CLAUDE.md files are: a `.claude/settings.json` at
  the repository root applies only when you start from the root."* E: *"each subdirectory's
  `.claude/settings.json` must be self-contained rather than layered on a root file."*
- **Fonte:** https://code.claude.com/docs/en/large-codebases (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** Aqui o nativo **não** cascateia. Um pacote/time num monorepo tem de
  **repetir** as settings — não herda do raiz. Este é o **gap que justifica MERGE-N-CAMADAS do Onion**:
  o Onion precisa de um resolvedor/gerador que COMPONHA settings de framework→empresa→time e
  materialize o `settings.json` self-contained por diretório (o nativo lê um arquivo só; o Onion o
  produz por composição). É o `vendor-branch.sh` bilateral generalizado para N camadas.
- **Base reusável tocada:** Base 2 (vendor-branch, hoje 2 camadas bilaterais → virar N-camadas) — e
  Base 1 (a resolução por camadas gera o arquivo final).

### Achado 8 — Precedência de subagents/skills por escopo + walk-up por diretório
- **Claim:** Colisão de nome de subagent resolve por: **Managed** (1, deployado no dir de managed
  settings) → *session-defined* (2) → **Project `.claude/agents/`** (3) → **User `~/.claude/agents/`**
  (4) → **Plugin** (5). *"Project subagents are discovered by walking up from the current working
  directory... when more than one nested directory defines the same `name`, Claude Code uses the
  definition closest to the working directory."* Skills de plugin usam namespace `plugin-name:skill-name`
  e *"never collide with per-directory skills."*
- **Fonte:** https://code.claude.com/docs/en/sub-agents (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** Os **agentes** do Onion também herdam/polimorfam nativamente:
  managed(empresa) sobrepõe project(time) sobrepõe user(pessoa), e o walk-up dá override por
  proximidade (time-dentro-do-repo de novo). O namespace de plugin dá **proveniência** (quem forneceu
  o agente) sem colisão — casa com o `resolve-role-bundle.sh` (bundle por papel).
- **Base reusável tocada:** Base 4 + `roles.yaml`/`resolve-role-bundle.sh` (polimorfismo de bundle).

### Achado 9 — `.claude/rules/` path-scoped + symlink: override cirúrgico e compartilhamento
- **Claim:** Rules em `.claude/rules/*.md` carregam com a mesma prioridade do `CLAUDE.md`; com
  frontmatter `paths:` (glob) só carregam para arquivos que casam. *"User-level rules are loaded
  before project rules, giving project rules higher priority."* Rules e skills suportam **symlink**
  para compartilhar um conjunto entre projetos (*"maintain a shared set of rules and link them into
  multiple projects"*). `claudeMdExcludes` (arrays mergeiam entre escopos) exclui `CLAUDE.md` de
  outros times num monorepo — *"Managed policy CLAUDE.md files cannot be excluded."*
- **Fonte:** https://code.claude.com/docs/en/memory ; https://code.claude.com/docs/en/large-codebases
  (materialidade **ALTA/MÉDIA**, primária)
- **Implicação p/ Onion:** `paths:`-scoped rules = **polimorfismo por caminho** (regra do time X só
  ativa em `packages/X`). Symlink = a base-herdada (framework) pode ser **linkada** e o override local
  fica ao lado — um análogo nativo do vendor-branch sem 3-way merge. `claudeMdExcludes` é o botão de
  **desativar herança** que não interessa (não-fricção em monorepo grande).
- **Base reusável tocada:** Base 2 (herança por link + override) e Base 1 (user<project na resolução).

### Achado 10 — Marketplace de org + acesso-por-GRUPO: distribuição versionada com proveniência
- **Claim:** Team/Enterprise distribuem plugins por **Organization settings > Plugins** com 4 modos:
  *Installed by default*, *Available for install*, *Not available*, *Required* (*"without the option
  to remove it"*). **Group-level** (só **Enterprise**): *"auto-installing a plugin for Engineering
  while making it available for Legal and hiding it elsewhere."* Resolução: *"group setting, then
  org-wide setting, then marketplace default"*; multi-grupo: *"the most permissive setting applies"*
  (Required > Installed by default > Available > Not available). Overrides de grupo persistem em
  re-syncs do GitHub.
- **Fonte:** https://support.claude.com/en/articles/13837433-manage-plugins-for-your-organization
  (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** É o veículo nativo para **empresa→time** com **versionamento** (plugin
  versionado) e **proveniência** (o plugin carrega sua origem/namespace). Mapeia Grana.Ai:
  `onion-compliance` como *Required* para a org, `onion-design` *Available* só para o grupo de design.
  A **cadeia de resolução de grupo** (group→org→default) é literalmente a Base 1 aplicada a "quem
  recebe qual bundle" — o `roles.yaml` (role→group→bundle) já foi desenhado prevendo isto.
- **Base reusável tocada:** Base 1 (cadeia de precedência) + `roles.yaml`/`resolve-role-bundle.sh`.

### Achado 11 — Server-managed settings (sem MDM) — poderoso, mas SEM per-group (ainda) [correção adversarial]
- **Claim:** Owners configuram via **Admin Settings > Claude Code > Managed settings** no console
  claude.ai, *"without requiring device management infrastructure"*; clientes buscam no startup +
  polling horário. Ocupa o **topo** da hierarquia junto com endpoint-managed; resolução é
  all-or-nothing: *"if server-managed settings deliver any keys at all, other endpoint-managed
  settings are ignored."* **PORÉM**, limitação oficial: *"Settings apply uniformly to all users in
  the organization. Per-group configurations are not yet supported."* — o que **contradiz** blogs de
  terceiros que afirmam que server-managed "respeita group membership". A segmentação por grupo hoje
  existe **só para plugins** (Achado 10), não para `settings.json` server-managed.
- **Fonte:** https://code.claude.com/docs/en/server-managed-settings (materialidade **ALTA**, primária).
  Contraste com claim de terceiro NÃO confirmado: https://tygartmedia.com/claude-code-server-managed-settings-admin-console/
- **Implicação p/ Onion:** Para **empresa** (Grana.Ai org inteira) o server-managed é **não-fricção
  máxima** (zero MDM, push do console) — ótimo veículo para a camada framework+empresa. Mas para
  **time** (grupo dentro da empresa) o `settings.json` gerenciado **não** segmenta — reforça que a
  granularidade de TIME tem de vir de outro lugar (per-directory + plugins por grupo + merge do Onion).
  Lição de método: **verificar claim de blog contra a doc primária** (o veredito de terceiro foi
  refutado).
- **Base reusável tocada:** Base 1 (camada topo não-sobreponível) + Base 4.

### Achado 12 — Buraco no CLI: plugins de managed settings NÃO auto-instalam (atrito real de campo)
- **Claim:** *"Plugins configured in org managed settings (`extraKnownMarketplaces` + `enabledPlugins`)
  do not auto-install in the CLI, though they work in the desktop app and web app."* Fluxo atual: CLI
  cacheia managed settings em `~/.claude/remote-settings.json`, mas **não registra** o marketplace em
  `known_marketplaces.json` nem instala — usuário precisa rodar `/plugin marketplace add` +
  `/plugin install` à mão. Status: **fechada como *not planned*** (duplicata de #23737/#28310/#19275,
  *"None of these resulted in the feature actually shipping for CLI."*).
- **Fonte:** https://github.com/anthropics/claude-code/issues/45323 (materialidade **ALTA**, primária)
- **Implicação p/ Onion:** O adotante regulado da Grana.Ai roda **no CLI** (nx monorepo, dev + CI).
  Então o caminho "empresa empurra plugin por managed settings" **tem atrito hoje no CLI** — o Onion
  não pode depender de auto-install. Reforça o veículo de **vendorização** (`/meta:adopt` +
  vendor-branch) como fallback durável e não-fricção enquanto o gap do CLI persiste. `enabledPlugins`
  como **project setting** (commitado) ainda liga o plugin por repo — esse caminho funciona.
- **Base reusável tocada:** Base 2 (vendor-branch como fallback quando o marketplace nativo não chega
  ao CLI) — a razão de o Onion manter o modelo durável de adoção.

### Achado 13 — Ferramentas de escopo em monorepo (o toolkit Grana.Ai) + o "quando parar de layer"
- **Claim:** Monorepo dispõe nativamente de: `claudeMdExcludes` (pular CLAUDE.md de outros times),
  `permissions.additionalDirectories` / `--add-dir` (ler pacote irmão), `worktree.sparsePaths`
  (checkout esparso por subárvore), e um `SessionStart` hook que lê o dir de launch e recomenda o
  plugin daquele caminho. Guia oficial: *"Replace many per-directory CLAUDE.md files with one set of
  conventions everyone installs → A plugin in an internal marketplace"* — i.e., **quando o layering
  por diretório para de escalar, mova a doutrina para um plugin versionado** que uma platform team
  mantém central.
- **Fonte:** https://code.claude.com/docs/en/large-codebases (materialidade **MÉDIA/ALTA**, primária)
- **Implicação p/ Onion:** Dá o **kit de não-fricção** para o nx monorepo da Grana.Ai (esconder times
  irrelevantes, cruzar pacotes, worktree enxuto). E dá a **doutrina de transição** que o Onion já vive:
  contexto que vira ruído por diretório → promover a **plugin versionado** (exatamente o modelo de
  verticais/marketplace do Onion). O `SessionStart`-hook path→plugin é um análogo nativo do
  `*-context` resolver do Onion.
- **Base reusável tocada:** Base 4 + verticais/marketplace do Onion (`resolve-role-bundle.sh`).

---

## Veredito de mecanismo (deste stream)

**BRANCHES: reprovado como veículo de herança.** Nada no nativo do Claude Code modela herança de
escopo por branch git — e o nativo é a corrente. A herança nativa é por **composição em runtime**
(concatenação de `CLAUDE.md`/rules/skills pela árvore + hierarquia de escopo) e por **precedência de
resolução** (settings/agents). Ficar em 4 branches ao mesmo tempo não tem análogo nativo; concatenar
4 `CLAUDE.md` tem.

**O mecanismo nativo é DUAL, e o Onion deve cavalgar cada metade onde ela é forte:**

| Camada do Onion | Mecanismo nativo que já resolve | Veredito |
|---|---|---|
| **Cognitiva** (doutrina, contexto SDAAL, agentes, skills) | **CASCATA-NATIVA** — `CLAUDE.md`/rules/skills concatenam raiz→cwd e managed→user→project→local; `@import` compõe explicitamente; walk-up dá override por proximidade (time-dentro-do-repo) | **Cavalgar.** É merge-n-camadas nativo. Não inventar. |
| **Configuração** (`settings.json`, permissões, env, worktree) | **Não cascateia pela árvore** (só carrega do dir inicial; self-contained por diretório) | **MERGE-N-CAMADAS do Onion** (vendor-branch N-camadas) gera o `settings.json` composto por diretório. É o gap real. |
| **Distribuição/versão** (verticais, bundles por papel) | **Marketplace de org + grupos (Enterprise) + plugin namespace** dão versão + proveniência; mas **CLI não auto-instala** e **settings server-managed não segmentam por grupo** | **Cavalgar onde chega; vendorizar (adopt) como fallback durável** enquanto o CLI/per-group não fecham. |

**mechanism_lean:** **híbrido** — cascata-nativa para a camada cognitiva (o coração SDAAL já herda
nativamente, inclusive time-dentro-do-repo por `CLAUDE.md`/skills de diretório) + merge-n-camadas
(vendor-branch generalizado a N) para o `settings.json`, que o nativo **não** herda pela árvore +
plugins/grupos para distribuição versionada com proveniência. **Branches não.**

**Encaixe nas 4 bases reusáveis (síntese):**
- **Base 1 (resolução por camadas)** ↔ Achados 1, 3, 10, 11: o Onion **espelha** a ordem nativa
  (managed>local>project>user; group>org>default) em vez de inventar precedência própria.
- **Base 2 (vendor-branch → N-camadas)** ↔ Achados 2, 7, 9, 12: o gap de settings-não-herda + o
  buraco do CLId justificam o merge N-camadas + vendorização durável; a regra array-merge/scalar-win
  do nativo é a política de conflito a codificar.
- **Base 3 (SUPERSEDES/KG)** ↔ Achados 4, 6: `@import` como ponteiro para a verdade herdada + override
  local ao lado = versionar conhecimento sem apagar; a doutrina "distilled" (reescrita) casa com
  `claudeMd` gerenciado.
- **Base 4 (camadas nativas)** ↔ todos: o eixo inteiro (managed/user/project/local + por-diretório)
  é o veículo; hoje **inexplorado** pelo Onion e o de maior alavanca não-fricção.

---

## Encaixe Grana.Ai (empresa/time/pessoa num nx monorepo regulado)

Mapeamento concreto, cavalgando o nativo e preenchendo os gaps com as bases do Onion:

1. **FRAMEWORK (Onion core):** doutrina base entregue como **plugin(s) versionado(s)** no marketplace
   interno da Grana.Ai (`onion-engineering`, `onion-product`, `onion-testing`, `onion-docs`,
   `onion-compliance`) — namespace de plugin dá proveniência. Onde o CLI não auto-instala (Achado 12),
   **vendorizar via `/meta:adopt`** (modelo durável já existente).

2. **EMPRESA (Grana.Ai org):** camada que **trava** — via **server-managed settings** (sem MDM,
   Achado 11) OU managed `settings.json`: `permissions.deny` de `.env`/segredos, `availableModels`
   aprovados, `strictKnownMarketplaces`, e **managed `claudeMd`** com a doutrina de compliance
   regulada (Achado 3/4). `onion-compliance` marcado **Required** no marketplace de org (Achado 10).
   Isto é a camada que ninguém abaixo sobrepõe — exatamente o que "regulado" exige.

3. **TIME (ex.: `packages/desenvolvimento/` no nx monorepo):** **nativo já resolve a camada cognitiva**
   — `packages/desenvolvimento/CLAUDE.md` (herda o raiz por concatenação) +
   `packages/desenvolvimento/.claude/skills/` + `.claude/rules/` com `paths: packages/desenvolvimento/**`.
   No **Enterprise**, plugins **auto-instalados por grupo** (grupo "desenvolvimento" recebe o bundle do
   `roles.yaml`). **Gap:** `settings.json` **não** herda do raiz (Achado 7) → o **merge N-camadas do
   Onion** materializa `packages/desenvolvimento/.claude/settings.json` self-contained compondo
   framework+empresa+time.

4. **PESSOA (ex.: `mauricio`):** `~/.claude/CLAUDE.md` + `~/.claude/agents/` + `~/.claude/rules/`
   (camada user, atravessa todos os repos da pessoa) para preferência global; e, **dentro do repo**,
   `CLAUDE.local.md` (gitignored) para preferências pessoais-por-projeto. **Gap do 4º nível:** o
   nativo não tem "pessoa-dentro-do-time-dentro-do-repo" versionável/compartilhável — `CLAUDE.local.md`
   é gitignored e por-worktree; para compartilhar entre worktrees, `@import ~/.claude/...` (Achado 6).
   Este é o **único nível onde o nativo é fraco** e o Onion pode agregar valor (convenção de
   `members/<pessoa>` resolvida pelo Onion, materializando na camada user/local).

5. **stage/prod:** ortogonal à hierarquia de escopo — resolve por `env`/`autoMode.environment` no
   managed (Achado 11) e/ou pela cadeia de precedência já existente (Base 1,
   `resolve-integration-branch.sh`). Não é um nível de herança, é um eixo de ambiente.

**Não-fricção — o que muda para o adotante:** quase nada no dia-a-dia. `CLAUDE.md` por pacote e skills
já são o hábito do monorepo (Achado 5/13); plugins por grupo são config de admin; a única peça que o
Onion **acrescenta** é o **resolvedor/gerador de settings N-camadas** (por causa do Achado 7) e a
convenção do 4º nível (pessoa). Tudo o mais é **cavalgar a corrente**.

**Ressalvas abertas (a validar em dogfood):**
- O buraco do CLI (Achado 12) é o maior risco de atrito para o regulado — depender de auto-install é
  frágil; manter vendorização como caminho primário.
- Per-group em server-managed settings **não existe ainda** (Achado 11) — não prometer segmentação de
  `settings.json` por time via server-managed; usar per-directory + Onion-merge.
- `settings.json` self-contained por diretório (Achado 7) pode gerar **duplicação** — o gerador do
  Onion precisa ser a fonte única que recompõe, senão vira drift (é exatamente o problema que a Base 1
  + Base 2 resolvem).

---

## Verificação adversarial

> Passe de refutação do stream H2 (data: 2026-07-09). Método: tentar REFUTAR cada achado material
> contra a fonte primária citada (fonte existe? é atual? sustenta sem exagero? há contra-evidência?).
> Veredito por `finding_id`. Todas as fontes primárias (`code.claude.com`, `support.claude.com`,
> repo `anthropics/claude-code`) foram re-buscadas e citam o achado.

| finding_id | veredito | nota (evidência / ressalva) |
|---|---|---|
| **H2-01** | **confirmed** | `code.claude.com/docs/en/settings` cita verbatim: *"1. Managed (highest): can't be overridden by anything; 2. Command line arguments; 3. Local; 4. Project; 5. User (lowest)."* Managed não-sobreponível nem por CLI confirmado. A tese "sem nível nativo entre project e user para time-dentro-do-repo em CONFIGURAÇÃO" é sustentada pelo Achado 7 (settings.json não herda pela árvore). |
| **H2-02** | **confirmed** | Verbatim: *"Later files override earlier ones for scalar values, arrays are concatenated and de-duplicated, and objects are deep-merged"* e *"Permission rules behave differently because they merge across scopes rather than override."* Array-merge (union) / scalar-win / permissões-mergeiam confirmados. Nuance benigna: arrays não só concatenam, **de-duplicam** (ainda é union). |
| **H2-03** | **confirmed (com ressalva de enumeração)** | O mecanismo material — camada managed-only que "trava" + parse tolerante — é confirmado verbatim: *"Managed settings parse tolerantly... A single typo cannot disable the rest of your organization's policy."* A lista managed-only oficial confirma `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly`, `strictKnownMarketplaces`, `blockedMarketplaces`, `forceLoginOrgUUID`, `forceLoginMethod`, `claudeMd`. **Ressalva (exagero pontual):** `availableModels` e `enforceAvailableModels` **não** são managed-only — funcionam em qualquer escopo (`enforceAvailableModels` só é *significativo* em managed); `disableBypassPermissionsMode` é sub-chave real de `permissions` (usada no exemplo server-managed) mas **não** consta da lista managed-only. Rotulá-las "só-managed" superestima levemente; não muda a conclusão material (existe camada empresa-que-trava). |
| **H2-04** | **confirmed** | `code.claude.com/docs/en/memory` verbatim: load order broad→specific = **Managed policy → User → Project → Local**; *"All discovered files are concatenated into context rather than overriding each other"*; *"content is ordered from the filesystem root down to your working directory."* Concatenação N-camadas cognitiva confirmada. |
| **H2-05** | **confirmed** | `large-codebases` verbatim: *"Claude Code loads every CLAUDE.md file from your working directory and every parent directory at launch, then loads each subdirectory's file on demand."* Padrão um-CLAUDE.md-por-pacote (`packages/api/CLAUDE.md`), *"Commit these files... teammates inherit them. Each directory's owner typically maintains its file"*, e skills por diretório (`packages/api/.claude/skills/`) confirmados. Corrige o "achado central": time-dentro-do-repo existe nativamente na camada cognitiva. |
| **H2-06** | **confirmed** | `memory` verbatim: *"maximum depth of four hops"*, *"Relative paths resolve relative to the file containing the import, not the working directory"*, e o import `@~/.claude/my-project-instructions.md` para compartilhar entre worktrees. Import de `@AGENTS.md` também confirmado. |
| **H2-07** | **confirmed** | `large-codebases` verbatim: *"Project settings in .claude/settings.json load only from your starting directory and are not inherited from parent directories the way CLAUDE.md files are"* e *"each subdirectory's .claude/settings.json must be self-contained rather than layered on a root file."* É a assimetria decisiva — confirmada sem exagero. |
| **H2-08** | **confirmed** | `sub-agents` verbatim: ordem de prioridade **1 Managed → 2 `--agents` CLI (sessão) → 3 `.claude/agents/` (projeto) → 4 `~/.claude/agents/` (user) → 5 Plugin**; *"Project subagents are discovered by walking up from the current working directory... uses the definition closest to the working directory"* (v2.1.178). Namespace de plugin `plugin-name:skill-name` que *"never collide with per-directory skills"* confirmado (via `large-codebases`). |
| **H2-09** | **confirmed** | `memory` verbatim: `paths:` glob frontmatter; *"User-level rules are loaded before project rules, giving project rules higher priority"*; symlink de rules/skills suportado; `claudeMdExcludes` *"Arrays merge across layers"*; *"Managed policy CLAUDE.md files cannot be excluded."* Todos os sub-claims batem. |
| **H2-10** | **confirmed** | `support.claude.com/.../13837433` verbatim: 4 modos (*Installed by default / Available for install / Not available / Required — "without the option to remove it"*); group-level *"available on Enterprise plans"*; exemplo Engineering/Legal; resolução *"group setting, then org-wide setting, then marketplace default"*; multi-grupo *"most permissive... Required > Installed by default > Available for install > Not available"*; overrides de grupo persistem em re-sync do GitHub. |
| **H2-11** | **confirmed** | `server-managed-settings` verbatim confirma o **all-or-nothing**: *"if server-managed settings deliver any keys at all, other endpoint-managed settings are ignored"* e a limitação decisiva: *"Settings apply uniformly to all users in the organization. Per-group configurations are not yet supported."* A correção adversarial (blog de terceiro que afirmava respeitar group membership está errado; segmentação por grupo hoje é só de plugins) **sustenta-se**. |
| **H2-12** | **confirmed** | Issue `anthropics/claude-code#45323` acessível e vigente: plugins de org managed settings (`extraKnownMarketplaces` + `enabledPlugins`) *"do not auto-install in the CLI... work in the desktop app and web app, but CLI users must manually run /plugin marketplace add and /plugin install"*; cache em `~/.claude/remote-settings.json` mas marketplace **não** registrado em `known_marketplaces.json`; **fechada como not planned**; duplicatas #23737/#28310/#19275 com *"None of these resulted in the feature actually shipping for CLI."* |
| **H2-13** | **confirmed** | `large-codebases` verbatim: `claudeMdExcludes`, `permissions.additionalDirectories`/`--add-dir`, `worktree.sparsePaths`, e o `SessionStart` hook que lê o dir de launch e recomenda o plugin daquele caminho. Doutrina de transição confirmada: *"Replace many per-directory CLAUDE.md files with one set of conventions everyone installs → A plugin in an internal marketplace"* + *"Plugins: versioned bundles of skills, hooks, and commands that a platform team owns centrally."* |

**Síntese da refutação:** 13/13 achados **confirmados** contra fonte primária. Único ajuste material —
**H2-03**: a *enumeração* de chaves managed-only inclui 3 chaves que **não** são estritamente
só-managed (`availableModels`, `enforceAvailableModels`, `disableBypassPermissionsMode`); a *tese*
(existe camada empresa-que-trava via chaves managed-only + parse tolerante) permanece sólida. Nenhuma
contra-evidência derruba o veredito de mecanismo do stream (cascata-nativa cognitiva + merge-N-camadas
para settings + plugins/grupos para distribuição; branches reprovadas).
