# H1 — Cascata de config / override em camadas (mercado)

> Stream H1 do redesign de **herança-de-escopo** do Sistema Onion (framework → empresa → time → pessoa).
> Pergunta-mãe: como VERSIONAR, HERDAR e POLIMORFAR a entrega do Onion (`.claude` + docs + agentes + scripts)
> através de uma hierarquia de escopos, mediada por IA (SDAAL/KG/dogfood no centro), **seguindo a corrente do
> mercado** (Claude Code é o vetor) e **sem criar atrito**. Recorte deste stream: como o mercado faz
> **herança + override + precedência de config em camadas** — e o veredito **BRANCHES vs OVERLAYS vs
> CASCATA-NATIVA vs MERGE-N-CAMADAS**.

## Resumo

O mercado convergiu, de forma quase unânime, para um padrão: **camadas declarativas de config resolvidas por
uma função de precedência determinística** (mais-específico-vence), com **override por chave** e, nos sistemas
maduros, **proveniência inspecionável** (qual camada setou cada valor). Git config (`--show-scope`/`--show-origin`),
Claude Code settings, Kustomize overlays, Helm values, ESLint flat config, EditorConfig e OPA/Rego são todos
instâncias do mesmo esqueleto. O achado transversal mais forte para o Onion: **usar branches para representar
ambientes/escopos é considerado ANTIPADRÃO explícito no ecossistema GitOps** — porque overlays/cascata *compõem*
(N camadas somam numa função pura) e branches *não* (você fica em uma por vez; unir 4 linhagens é tempestade de
conflito sem proveniência por-chave). E o vetor (Claude Code) **já traz** as camadas nativas — settings
(managed→project→user) e CLAUDE.md hierárquico (upward-concat + lazy subtree + `@imports`) — que o Onion **hoje
não explora**, incluindo o único mecanismo que dá **scoping sub-repo** (CLAUDE.md por subdiretório num monorepo),
exatamente o gap do caso Grana.Ai.

---

## Achados numerados

### 1. Git config — cascata canônica com proveniência de primeira classe (`--show-scope`/`--show-origin`)
- **Claim**: Git tem 5 escopos (system → global → local → worktree → command), lidos em ordem, **último-vence**
  (worktree override local override global override system). E — crucial — expõe **proveniência**: `--show-origin`
  anexa a cada valor o arquivo/origem de onde veio; `--show-scope` anexa o escopo (worktree/local/global/system/
  command). "Which layer set this?" é uma pergunta de primeira classe, não reconstruída à mão.
- **Fonte**: https://git-scm.com/docs/git-config · https://man7.org/linux/man-pages/man1/git-config.1.html
- **Materialidade**: ALTA — é o modelo mental exato que o Onion quer generalizar.
- **Implicação p/ Onion**: `resolve-integration-branch.sh` já é uma cascata de precedência (stamp versionado →
  git config local → detecção) — mas resolve **um campo** e **não reporta origem**. Generalizar para um resolver
  N-camadas que, além de resolver, **emita proveniência** (`--show-scope`-style: "integration_branch veio da
  camada empresa; agent X veio da camada pessoa"). É o requisito (c) da lente (versão/proveniência) já com
  precedente de mercado consolidado.
- **Base reusável tocada**: #1 (resolve-integration-branch → cadeia de precedência a generalizar).

### 2. Claude Code settings — a cascata NATIVA do vetor (managed → project → user), array **merge** não replace
- **Claim**: Precedência oficial, do mais forte ao mais fraco: **managed settings > CLI flags > local
  (`.claude/settings.local.json`) > project (`.claude/settings.json`) > user (`~/.claude/settings.json`)**.
  Managed settings **não podem ser sobrepostas por nada abaixo** (nem por flag) — o gancho de governança
  corporativa. E o detalhe de ouro: **arrays como `permissions.allow` fazem MERGE entre escopos (empilham), não
  replace** — um allow do user soma com um allow do project.
- **Fonte**: https://code.claude.com/docs/en/settings · https://systemprompt.io/guides/enterprise-claude-code-managed-settings
- **Materialidade**: ALTA — este é o veículo "seguir a corrente" por excelência.
- **Implicação p/ Onion**: mapeamento direto da hierarquia de escopo pedida — **managed ≈ empresa (regras
  invioláveis, ex.: compliance Grana.Ai), project ≈ time/repo, user ≈ pessoa**. O Onion pode entregar suas
  camadas *dentro* deste mecanismo em vez de inventar um paralelo. E o "array merge" resolve o polimorfismo de
  bundle (roles.yaml) sem atrito: cada camada acrescenta permissões/verticais, não sobrescreve. **Não-friction
  máximo**: é a semântica que o dev já espera do Claude Code.
- **Base reusável tocada**: #4 (camadas nativas do Claude Code — hoje inexploradas).

### 3. Claude Code CLAUDE.md hierárquico — o ÚNICO scoping sub-repo nativo (o "gap" já existe no vetor)
- **Claim**: Claude Code carrega CLAUDE.md em duas mecânicas: **(a) upward-traversal** — do cwd até a raiz do FS,
  concatenando todo CLAUDE.md encontrado (enterprise/managed → project-root → cwd), imediatamente no startup; e
  **(b) lazy/on-demand** — CLAUDE.md de **subdiretórios abaixo** do cwd só entram quando a IA lê arquivos ali.
  Regra: **mais específico sobrepõe mais geral**. Suporta `@path` **imports** para compor instruções entre
  arquivos. Em monorepo, a recomendação oficial é **um CLAUDE.md por package** (`src/db/`, `src/api/`), commitado,
  "para os colegas herdarem".
- **Fonte**: https://code.claude.com/docs/en/large-codebases · https://code.claude.com/docs/en/memory (hierarquia
  e imports `@path`)
- **Materialidade**: ALTA — **resolve o ACHADO CENTRAL do brief**: "sub-repo scoping (time/pessoa DENTRO de um
  repo) não existe em nenhum eixo". Existe — no vetor, via CLAUDE.md por subdiretório + lazy load. O Onion é que
  não o explora.
- **Implicação p/ Onion**: a herança cognitiva SDAAL (base = spec do framework + `*-context` local) já é
  isomórfica a "CLAUDE.md concatenado do topo + CLAUDE.md do package". O Onion deve **materializar cada camada de
  escopo como um CLAUDE.md/`*-context` no nível certo da árvore** e deixar o carregamento nativo compor. Num nx
  monorepo (Grana.Ai): `CLAUDE.md` raiz (empresa) → `packages/<time>/CLAUDE.md` (time) → e a camada pessoa via
  `~/.claude` (user) ou `settings.local.json`. Lazy load = **não-friction + controle de context bloat** (só carrega
  a camada do package em que se está mexendo).
- **Base reusável tocada**: #4 (camadas nativas) + SDAAL (herança cognitiva em runtime).

### 4. Kustomize base + overlay — composição por DIRETÓRIO com strategic-merge (mapas mergeiam, escalares/listas por chave)
- **Claim**: Kustomize mantém um conjunto-núcleo (`base`) e guarda os deltas em diretórios (`overlays`). O
  **strategic merge patch** é *type-aware*: **substitui escalares, mergeia mapas, e usa merge-key para listas**
  (ex.: containers por `name`, não replace da lista inteira). Patches posteriores sobrepõem os anteriores nos
  campos que tocam. Você só declara os campos que quer mudar.
- **Fonte**: https://github.com/kubernetes-sigs/kustomize/blob/master/examples/inlinePatch.md ·
  https://fabianlee.org/2022/04/18/kubernetes-kustomize-transformations-with-patchesstrategicmerge/
- **Materialidade**: ALTA — é o modelo de "override parcial inteligente" que o Onion precisa para não ter que
  reescrever arquivos inteiros por camada.
- **Implicação p/ Onion**: a herança de escopo do Onion não deve ser "copiar o arquivo e editar" (clobber), e sim
  **patch declarativo por camada** — a camada time declara só o delta sobre a empresa. O merge type-aware é o alvo
  de qualidade para o resolver N-camadas (versus o footgun do tsconfig, achado #7). Encaixa como a evolução
  natural do 3-way do `vendor-branch.sh` de bilateral → N-camadas, mas **resolvido em build/read, não em merge de
  git**.
- **Base reusável tocada**: #2 (vendor-branch — 2 camadas bilaterais → N-camadas).

### 5. Kustomize **components** — camadas OPCIONAIS composáveis (mixins) para cross-cutting (não-herança)
- **Claim**: além de base/overlay (que são *herança*), Kustomize tem **components**: blocos **opcionais e
  composáveis** que você mistura num overlay (feature-flags, monitoring, security). "Bases/overlays criam
  hierarquia de herança; components são plug-and-play." O padrão-irmão (NVIDIA AICR) chama de **mixins** —
  fragmentos composáveis para concerns transversais que senão duplicariam em cada folha.
- **Fonte**: https://github.com/kubernetes-sigs/kustomize/blob/master/examples/components.md ·
  https://github.com/kubernetes/enhancements/blob/master/keps/sig-cli/1802-kustomize-components/README.md
- **Materialidade**: ALTA — separa dois eixos que o Onion mistura: **herança vertical** (empresa→time→pessoa) vs
  **composição horizontal** (quais verticais/domínios).
- **Implicação p/ Onion**: `roles.yaml` (`base` + `optional`, ex.: standalone Grana.Ai = base + `onion-compliance`)
  é **exatamente o padrão component/mixin**, não herança. O redesign deve tratar **verticais como components
  opcionais** (Grana.Ai *opta por* compliance) e **escopo como overlay** (time herda da empresa). São dois
  mecanismos distintos que não devem colidir — evita "inchar o bundle" (crítica já viva no CLAUDE.md sobre
  especialistas dedicados).
- **Base reusável tocada**: roles.yaml + resolve-role-bundle.sh (polimorfismo de bundle por papel).

### 6. GitOps — "branch por ambiente/escopo" é ANTIPADRÃO explícito; overlays compõem, branches não (resposta ao maestro)
- **Claim**: usar branches git para modelar ambientes/escopos é antipadrão documentado. Motivos citados por
  fontes primárias do ecossistema: gera merge-conflicts, esconde "o que está aonde", **vai contra o design das
  ferramentas** ("Helm e Kustomize não sabem nada de branches/merges/PRs; ambos usam arquivos plain para
  ambientes"), e **promoção não é um simples merge** — configs de ambientes diferentes (secrets, configmaps) são
  *fundamentalmente diferentes* e não devem ser mergeadas. A recomendação é **overlays por diretório + trunk-based**.
- **Fonte**: https://octopus.com/blog/stop-using-branches-deploying-different-gitops-environments ·
  https://codefresh.io/blog/applied-gitops-with-kustomize/ (Kapelonis, "Stop Using Branches…")
- **Materialidade**: ALTA — **é a resposta direta à pergunta-chave do maestro** (o exemplo em branches
  onion/adopt → granaai → teams/desenvolvimento → members/mauricio).
- **Implicação p/ Onion**: o mecanismo de herança de escopo **não deve ser branches**. Branches não compõem
  (você fica em uma por vez; herança precisa somar 4 camadas simultâneas); a intuição do maestro ("branches talvez
  não seja o mecanismo") está alinhada ao consenso de mercado. Branches permanecem úteis para **uma coisa
  ortogonal**: reconciliar *versões do framework* ao longo do tempo (é o que `vendor-branch.sh` faz — 3-way de
  upgrade), **não** para representar escopos.
- **Base reusável tocada**: #2 (vendor-branch topologia) — reposiciona branch como upgrade, não como escopo.

### 7. tsconfig `extends` — o FOOTGUN de proveniência: arrays fazem **replace silencioso**, não merge
- **Claim**: `extends` carrega a base e o filho sobrepõe. Mas: **`compilerOptions` mergeia por chave**, enquanto
  **arrays (`lib`, `types`) e top-level (`include`/`exclude`/`files`) são SUBSTITUÍDOS, não mesclados** — se a base
  tem `lib:["ES2022","DOM"]` e o filho tem `lib:["ES2022"]`, o resultado é `["ES2022"]`, DOM some silenciosamente.
  TS 5.0+ aceita `extends` como **array** (últimos entries vencem). Circularidade é proibida.
- **Fonte**: https://www.typescriptlang.org/tsconfig/extends.html ·
  https://miyoon.medium.com/array-parameters-in-tsconfig-json-are-always-overwritten-11c80bb514e1
- **Materialidade**: MÉDIA-ALTA — lição negativa de design (o que **não** fazer).
- **Implicação p/ Onion**: o "replace silencioso de array sem proveniência" é precisamente o modo-de-falha que o
  Onion quer evitar em `.claude` (uma camada time listar 2 agentes e apagar os 10 herdados sem aviso). Reforça o
  princípio **never-clobber** e a necessidade de merge type-aware + proveniência: a semântica-default deveria ser
  **merge com aviso**, e replace só quando explícito. Contrasta bem com o array-**merge** do Claude Code settings
  (achado #2), que é a escolha certa.
- **Base reusável tocada**: #1 (resolver de precedência) + never-clobber (vendor-branch/adopt).

### 8. ESLint flat config — matou a cascata implícita por diretório, trocou por array ORDENADO + glob explícito
- **Claim**: o flat config (default no ESLint v9, abril/2024; caminho legado removido no v10, fim/2025)
  **eliminou deliberadamente a cascata de diretório** do `.eslintrc`. Agora é **um array ordenado** de objetos de
  config; ESLint acha todos que casam (via glob `files`/`ignores`) e mergeia **do topo para o fim**, **último-que-
  casa-vence**. A precedência virou **explícita e linear**, não mais mágica de estrutura de pastas.
- **Fonte**: https://eslint.org/blog/2022/08/new-config-system-part-2/ ·
  https://eslint.org/blog/2025/03/flat-config-extends-define-config-global-ignores/
- **Materialidade**: MÉDIA-ALTA — um projeto grande e maduro **abandonou** a cascata-por-diretório em favor de
  precedência explícita. Sinal forte sobre o trade-off.
- **Implicação p/ Onion**: tensão de design real. A cascata-por-diretório (EditorConfig/CLAUDE.md) é
  não-friction mas "mágica" (difícil saber por que um valor venceu). ESLint concluiu que, em escala, **precedência
  explícita e ordenada é mais depurável**. Para o Onion: manter o carregamento nativo (mágico, não-friction) para
  o caso comum, MAS oferecer um **resolver que torna a ordem explícita e inspecionável** (`/meta` que imprime a
  cadeia resolvida por chave) — o melhor dos dois. Alinha com o achado #1 (proveniência).
- **Base reusável tocada**: #1 (precedência) + #4 (camadas nativas).

### 9. Helm values — hierarquia parent→subchart com **push-down** de globals (empresa injeta no time)
- **Claim**: precedência (alta→baixa): `--set` (rightmost) > `-f`/values files (rightmost) > **values.yaml do
  parent** > **values.yaml do subchart**. Merge é **deep**. E o parent **empurra config para dentro** do subchart:
  um bloco `mysubchart:` no parent é enviado ao subchart; **`global:`** propaga para todos os subcharts.
- **Fonte**: https://helm.sh/docs/chart_template_guide/subcharts_and_globals/ ·
  https://helm.sh/docs/chart_template_guide/values_files/
- **Materialidade**: MÉDIA-ALTA — modela o eixo **empresa→time** com *push-down* (o pai impõe/injeta no filho),
  não só o filho puxando do pai.
- **Implicação p/ Onion**: além de "time herda da empresa" (pull), há o vetor **"empresa injeta no time"** (push,
  ex.: `global:` = política de compliance Grana.Ai que desce para todos os packages). Reforça o achado #2 (managed
  settings inviolável) com um segundo mecanismo: **valores globais herdáveis + overridáveis** onde permitido. O
  Onion pode ter uma "camada global da empresa" que desce por default mas admite override nas camadas onde a
  política permitir.
- **Base reusável tocada**: #4 (managed≈empresa) + roles.yaml (o que desce por papel).

### 10. EditorConfig — cascata "mais-próximo-vence" com `root=true` como BARREIRA de herança
- **Claim**: ao abrir um arquivo, procura `.editorconfig` no diretório e em **todos os pais**, parando quando
  acha um com **`root=true`** ou na raiz do FS. Arquivos mais próximos são lidos **por último → vencem**. **Só as
  propriedades explicitamente listadas** na camada mais baixa sobrepõem; as demais das camadas superiores
  **continuam valendo** (override cirúrgico, não substituição). `root=true` é um **stop-token**: "não herde acima
  daqui".
- **Fonte**: https://spec.editorconfig.org/index.html · https://editorconfig.org/
- **Materialidade**: MÉDIA-ALTA — dá dois primitivos que o Onion precisa: **override parcial por chave** e a
  **barreira de herança**.
- **Implicação p/ Onion**: o `root=true` é o análogo exato do papel **`distilled`** de `roles.yaml` (herança de
  doutrina reescrita, "não vendoriza nem herda arquivo") e de um futuro "escopo selado" (um time regulado que quer
  cortar a herança da empresa em certo ponto). Ter um **stop-token explícito por camada** é padrão de mercado, não
  invenção. E o "só o listado sobrepõe, o resto herda" é a semântica não-friction correta (oposto do tsconfig).
- **Base reusável tocada**: roles.yaml (distilled = barreira/reescrita) + never-clobber.

### 11. cosmiconfig — o contraexemplo: **para no primeiro achado** (merge é ESCOLHA, não default) + `$import`
- **Claim**: cosmiconfig sobe a árvore procurando config, mas **para no primeiro arquivo encontrado — não acha
  todos e mergeia**. É um NÃO-cascata deliberado. Para compor, oferece uma feature explícita: a chave especial
  **`$import`**, onde o arquivo importado vira **base** cujas propriedades o importador pode sobrepor.
- **Fonte**: https://github.com/cosmiconfig/cosmiconfig (README) · https://www.npmjs.com/package/cosmiconfig
- **Materialidade**: MÉDIA — lição de contraste: nem todo mundo mergeia camadas; alguns preferem
  "uma-config-vence + import explícito".
- **Implicação p/ Onion**: valida que **"mesclar N camadas" é uma decisão de design com custo** (previsibilidade
  vs composição). O `$import` explícito é o mesmo espírito do `@path` do CLAUDE.md (achado #3): **composição opt-in
  por referência**, mais fácil de rastrear que a cascata implícita. Para o Onion, sugere oferecer **ambos**:
  cascata nativa (default não-friction) + imports explícitos (`@path`) quando o autor quer proveniência clara.
- **Base reusável tocada**: #4 (imports `@path`) + SDAAL (base + override local).

### 12. OPA/Rego + OCP — bundles com `roots` (escopo) + stacks hierárquicos; **conflito é resolvido EXPLICITAMENTE**
- **Claim**: bundles OPA declaram um campo **`roots`** = prefixos de path que definem o **escopo** do bundle (o
  que ele é dono; default `[""]` = tudo). O OPA Control Plane monta bundles compondo **stacks** hierárquicos
  (políticas org-wide) via selectors/requirements. Quando políticas de níveis diferentes divergem, isso é chamado
  **"conflito"** e **deve ser resolvido explicitamente** no Rego (você *autora* `allow overrides deny` ou o
  contrário) — a ordem das statements **não** decide sozinha (Rego é order-independent).
- **Fonte**: https://www.openpolicyagent.org/docs/management-bundles · https://www.openpolicyagent.org/docs/ocp/concepts
- **Materialidade**: ALTA — no domínio de **política/compliance** (Grana.Ai é regulado), o mercado **não deixa o
  conflito ser resolvido por acidente de ordem**; exige reconciliação declarada.
- **Implicação p/ Onion**: isomórfico ao **SUPERSEDES do KG** — "git merge não reconcilia verdades"; a verdade
  nova supera a antiga por **aresta explícita**, não por sobrescrita. Para camadas de escopo *com política*
  (compliance da empresa vs preferência do time), o override não pode ser "última camada ganha silenciosamente" —
  precisa ser **reconciliação declarada e versionada** (quem supera quem, e por quê). O `roots` também dá o
  primitivo de **ownership/escopo por path** que o Onion pode usar para dizer "a camada empresa é dona de
  `docs/compliance-context/`; time não sobrepõe".
- **Base reusável tocada**: #3 (SUPERSEDES do KG — override de conhecimento versionado).

---

## Veredito de mecanismo (deste stream)

**Por que overlays/cascata compõem e branches não** — a distinção é *build-time function* vs *stateful history*:

- **Cascata/overlays** são uma **função pura de N camadas → resultado**, avaliada no momento da leitura/build.
  As N camadas coexistem simultaneamente (é o ponto: empresa E time E pessoa ao mesmo tempo), o override é
  **por-chave**, e a proveniência é derivável ("este valor veio da camada X"). Adicionar uma camada é somar um
  termo — composição trivial (achados #1, #2, #4, #9, #10).
- **Branches** são **reconciliação de histórico com estado**: você fica em **uma** por vez, e unir 4 linhagens é
  um merge 4-way com conflitos textual-por-linha, **sem proveniência por-chave** e sem "qual camada setou isto". O
  próprio ecossistema GitOps declara "branch por ambiente/escopo" **antipadrão** (#6). A intuição do maestro
  ("não se fica em 4 branches ao mesmo tempo; herança precisa COMPOR") é o consenso de mercado.

**Ranking dos mecanismos para herança-de-escopo (framework→empresa→time→pessoa):**

1. **CASCATA-NATIVA (vencedor como transporte)** — usar as camadas que o **vetor Claude Code já entrega**:
   settings (`managed→project→user`, com array-merge) + CLAUDE.md hierárquico (upward-concat + lazy subtree +
   `@imports`). Máximo não-friction ("seguir a corrente"), e **já resolve o scoping sub-repo** (o gap central) via
   CLAUDE.md por package. Mapa: **managed≈empresa, project≈time/repo, user≈pessoa, subtree-CLAUDE.md≈package/pessoa
   -no-monorepo**.
2. **OVERLAYS (o modelo mental + qualidade de merge)** — Kustomize base/overlay dá o *type-aware strategic merge*
   (mapas mergeiam, listas por chave) que o resolver do Onion deve imitar para **never-clobber por-chave**, e
   **components/mixins** separam o eixo horizontal (verticais opcionais = `roles.yaml`) do vertical (escopo).
3. **MERGE-N-CAMADAS (reservar para upgrade, não para escopo)** — o 3-way do `vendor-branch.sh` é a ferramenta
   certa para **reconciliar versões do framework no tempo** (upgrade do core → adotante), **não** para representar
   escopos. Branch = eixo de versão, não eixo de escopo.
4. **BRANCHES-para-escopo (rejeitado)** — antipadrão; não compõe; sem proveniência por-chave.

**Camadas com POLÍTICA (compliance) são exceção**: onde a camada carrega verdade/política (empresa regulada), o
override **não** pode ser "última-camada-vence silenciosa" — precisa ser **reconciliação explícita e versionada**,
no espírito OPA-`roots` + KG-`SUPERSEDES` (#12, #3). Managed settings inviolável (#2) é o gancho para "a empresa
impõe; o time não sobrepõe".

**Requisito transversal confirmado por todo o stream**: um **resolver de proveniência** — o Onion precisa de um
`git config --show-scope` próprio: dado o estado resolvido, imprimir *qual camada contribuiu cada peça*. Git (#1)
e ESLint-flat (#8) mostram que, em escala, a precedência **explícita e inspecionável** ganha da cascata mágica.
Design recomendado: **cascata nativa não-friction no caso comum + resolver que materializa a cadeia por-chave sob
demanda** (via `/meta`).

> **mechanism_lean**: híbrido — **cascata-nativa** (camadas do Claude Code: settings + CLAUDE.md hierárquico) como
> transporte primário da herança de escopo; **overlays/strategic-merge** como modelo de qualidade do resolver
> N-camadas (never-clobber por-chave + components = verticais opcionais); **merge-n-camadas (vendor-branch 3-way)**
> reservado só para reconciliar *versões* do framework; **branches para escopo, rejeitado** (antipadrão GitOps).

---

## Encaixe Grana.Ai (empresa/time/pessoa num nx monorepo regulado)

Grana.Ai = adotante regulado, **nx monorepo**, com time de devs + stage/prod; dentro, empresa/times/pessoas, cada
um querendo sua camada de `.claude`/docs herdando do pai e podendo sobrepor. Resolução concreta **sem branches**,
seguindo o vetor:

| Escopo | Veículo nativo (Claude Code) | Papel Onion | Semântica |
|---|---|---|---|
| **Framework** | pacote/vendor do core (SSOT), `.onion-version` | `source` | base herdada; upgrade via `vendor-branch.sh` 3-way (eixo VERSÃO) |
| **Empresa (Grana.Ai)** | `managed-settings.json` + `CLAUDE.md` raiz do monorepo + `docs/compliance-context/` | `standalone` + component `onion-compliance` (opt-in) | política **inviolável** (managed); global push-down estilo Helm `global:`; `roots`-style ownership de `docs/compliance-context/` |
| **Time (ex.: `packages/desenvolvimento`)** | `packages/<time>/CLAUDE.md` (lazy subtree load) + `.claude/settings.json` do package/projeto | overlay de escopo | herda empresa + delta do time; **override cirúrgico por-chave** (estilo EditorConfig: só o listado sobrepõe) |
| **Pessoa (ex.: mauricio)** | `~/.claude/settings.json` + `~/.claude/CLAUDE.md` (user) e/ou `settings.local.json` (não-versionado) | camada pessoal | preferências pessoais; array-merge empilha, não apaga a herança |

Pontos concretos:

- **O scoping sub-repo (o gap central) é resolvido pelo carregamento nativo**: no nx monorepo, **um CLAUDE.md por
  package** (achado #3) — a IA, ao mexer em `packages/desenvolvimento`, compõe automaticamente `raiz(empresa) +
  package(time)` via upward-concat, e o **lazy load** evita context-bloat (não carrega os outros packages). É
  exatamente a recomendação oficial de monorepo do vetor. **Nenhuma branch envolvida.**
- **Herança compõe as 4 camadas simultaneamente** (framework+empresa+time+pessoa) — o que branches não fariam
  (não se fica em 4 branches ao mesmo tempo). Cada camada é um **overlay/patch** resolvido na leitura.
- **Compliance é component opt-in, não herança forçada** (achado #5 + `roles.yaml`): Grana.Ai = `standalone` base +
  `onion-compliance` optional. Times não-regulados no mesmo monorepo não pagam o custo; a **política** que *é*
  herdada vem por managed-settings (inviolável) + reconciliação explícita estilo OPA/KG (achado #12), não por
  "última camada vence".
- **Proveniência para auditoria (repo regulado exige)**: o resolver Onion (generalização de
  `resolve-integration-branch.sh`) deve responder, para qualquer recurso `.claude`/doc, **"qual camada
  (framework/empresa/time/pessoa) o contribuiu"** — requisito de auditoria que o git config já provou ser viável
  (`--show-scope`). Sem isso, um adotante regulado não consegue provar de onde veio uma regra.
- **Upgrade do framework permanece ortogonal**: quando o core evolui, `vendor-branch.sh` reconcilia a **versão**
  (3-way) sem tocar nas camadas de escopo — os dois eixos (versão × escopo) ficam separados, como Kustomize
  overlays (escopo) coexistem com bumps de imagem (versão).

---

## Fontes

- Git config (escopos, precedência, `--show-origin`/`--show-scope`): https://git-scm.com/docs/git-config · https://man7.org/linux/man-pages/man1/git-config.1.html
- Claude Code settings (precedência managed→project→user, array-merge): https://code.claude.com/docs/en/settings · https://systemprompt.io/guides/enterprise-claude-code-managed-settings
- Claude Code memory/CLAUDE.md (hierarquia, lazy subtree, imports, monorepo): https://code.claude.com/docs/en/large-codebases · https://code.claude.com/docs/en/memory
- Kustomize strategic merge / base+overlay: https://github.com/kubernetes-sigs/kustomize/blob/master/examples/inlinePatch.md · https://fabianlee.org/2022/04/18/kubernetes-kustomize-transformations-with-patchesstrategicmerge/
- Kustomize components/mixins: https://github.com/kubernetes-sigs/kustomize/blob/master/examples/components.md · https://github.com/kubernetes/enhancements/blob/master/keps/sig-cli/1802-kustomize-components/README.md
- GitOps branch-por-ambiente = antipadrão: https://octopus.com/blog/stop-using-branches-deploying-different-gitops-environments · https://codefresh.io/blog/applied-gitops-with-kustomize/
- tsconfig `extends` (arrays replace, multi-extends): https://www.typescriptlang.org/tsconfig/extends.html · https://miyoon.medium.com/array-parameters-in-tsconfig-json-are-always-overwritten-11c80bb514e1
- ESLint flat config (fim da cascata por diretório, último-vence): https://eslint.org/blog/2022/08/new-config-system-part-2/ · https://eslint.org/blog/2025/03/flat-config-extends-define-config-global-ignores/
- Helm values (precedência, parent→subchart, globals): https://helm.sh/docs/chart_template_guide/subcharts_and_globals/ · https://helm.sh/docs/chart_template_guide/values_files/
- EditorConfig (cascata, `root=true`, override parcial): https://spec.editorconfig.org/index.html · https://editorconfig.org/
- cosmiconfig (para no 1º achado, `$import`): https://github.com/cosmiconfig/cosmiconfig
- OPA/Rego bundles + OCP stacks (`roots`, conflito explícito): https://www.openpolicyagent.org/docs/management-bundles · https://www.openpolicyagent.org/docs/ocp/concepts

---

## Verificação adversarial

> Verificador adversarial do stream H1 (2026-07-09). Método: refutar cada achado material contra a fonte
> primária citada — a fonte existe? é atual? sustenta a claim **sem exagero**? há contra-evidência? Na dúvida,
> `hypothesis`. Fontes primárias re-fetchadas: docs oficiais de Claude Code (settings + memory + large-codebases),
> git-scm, Kustomize (GitHub), octopus.com, typescriptlang.org, eslint.org, helm.sh, spec.editorconfig.org,
> cosmiconfig (GitHub), openpolicyagent.org.

| finding_id | veredito | nota |
|---|---|---|
| **H1-01** | **confirmed** | git-scm/docs/git-config confirma literalmente os 5 escopos (system→global→local→worktree→command), "read in the order given above, with **last value found taking precedence**", e `--show-origin` (origin type + arquivo) / `--show-scope` (worktree/local/global/system/command). O paralelo com `resolve-integration-branch.sh` (resolve 1 campo, sem proveniência) é observação interna do repo, não da fonte — plausível e não-exagerada. |
| **H1-02** | **confirmed** | code.claude.com/docs/en/settings confirma a precedência managed>CLI>local>project>user e "Managed (highest): can't be overridden by anything". Nuance importante: **não é "arrays" em geral que mergeiam** — a doc diz "most settings replace, not merge"; o merge é específico de `permissions` ("Permission rules behave differently because they merge across scopes") e de arrays marcados como tal (ex.: `allowedHttpHookUrls`, `claudeMdExcludes`). A claim cita corretamente `permissions.allow` como o exemplo — logo sustenta-se. Só não generalizar "arrays sempre mergeiam". |
| **H1-03** | **confirmed** | code.claude.com/docs/en/memory + /large-codebases confirmam upward-traversal com concatenação ("All discovered files are concatenated…ordered from filesystem root down…closer are read last"), **lazy load de subdiretórios** ("subdirectory's file on demand when it reads files there"), imports `@path` (profundidade máx. 4) e a recomendação explícita de monorepo ("one per package…Commit these files so teammates inherit them"). Precisão: a doc enquadra como **concatenação com ordenação** (mais-específico lido por último → vence em conflito), não "override" no sentido replace — a paráfrase "mais-específico-sobrepõe" é fiel ao efeito. |
| **H1-04** | **confirmed** | O comportamento type-aware do strategic-merge (escalares substituem, mapas mergeiam, listas por merge-key ex. `containers` por `name`) é fato estabelecido do Kubernetes SMP e é o alvo correto. **Ressalva de atribuição**: o `inlinePatch.md` re-fetchado é fino nessas mecânicas (mostra troca de imagem e `$patch: delete`, sem detalhar merge-key); a especificação type-aware é sustentada pela fonte secundária (fabianlee) e pela doc do K8s SMP, não pela primária citada. Claim materialmente correta; só a citação primária é magra. |
| **H1-05** | **confirmed** | components.md confirma components como blocos **opt-in composáveis** ("Each opt-in feature gets packaged as a component…referred to from higher-level overlays"), distintos de base/overlay que são herança. O mapeamento a `roles.yaml` (base+optional) é raciocínio interno coerente. O rótulo "mixins/NVIDIA AICR" é cor secundária, não verificada nesta fonte, mas não é load-bearing. |
| **H1-06** | **confirmed** | octopus.com sustenta o antipadrão com as três razões: merge propaga mudança indesejada entre ambientes, "Both Helm and Kustomize use plain files…not Git branches", e "promotion is never a simple Git merge"; recomenda base+overlays por diretório. Resposta direta à pergunta do maestro (branches para escopo). Sem exagero. |
| **H1-07** | **confirmed** | typescriptlang.org/tsconfig/extends confirma que `files`/`include`/`exclude` são **overwrite** (citação literal) e `compilerOptions` mergeia por chave. As duas sub-claims extras — arrays dentro de compilerOptions (`lib`,`types`) serem substituídos e `extends` como array no TS 5.0+ (last-wins) — **não** aparecem nesta página; repousam na fonte secundária (miyoon) e nas release notes do TS 5.0. Ambas são corretas (setar `lib` no filho substitui o array da base; TS 5.0 realmente adicionou `extends` como array). Confirmada, com a nota de que o footgun de array específico não está na doc primária. |
| **H1-08** | **confirmed** | eslint.org/blog confirma o abandono da cascata por diretório em favor do array ordenado ("The only real difference is the merge happens from the top of the array down…The last matching config always wins"). Datas de versão (v9 default abr/2024; remoção do legado no v10 fim/2025) são fatos de roadmap ESLint — v9/flat-default está correto; a data exata de remoção no v10 é projeção de roadmap (não load-bearing para a lição). Núcleo confirmado. |
| **H1-09** | **confirmed** | helm.sh confirma "A parent chart can override values for subcharts" (push-down) e globals propagando a todos os subcharts ("accessed from any chart or subchart by exactly the same name"). Ressalva: **deep-merge** e a cadeia completa de precedência (`--set`>`-f` rightmost>parent>subchart) não estão nesta página específica — repousam na página companheira values_files (citada como secundária) e são comportamento conhecido do Helm. Push-down + globals confirmados na primária. |
| **H1-10** | **confirmed** | spec.editorconfig.org confirma busca upward parando em `root=true` ou raiz do FS, "closer file are read last → take precedence", override cirúrgico (só o listado sobrepõe; `unset` remove) e `root=true` como stop-token ("not to check any higher directory"). Análogo interno com `distilled`/roles.yaml é raciocínio do repo, plausível. |
| **H1-11** | **confirmed** | cosmiconfig README confirma literalmente "Stops at the first configuration found, instead of finding all…and merging them" e a chave `$import` ("import another file as a base"), inclusive array de imports com "later entries taking precedence". Contraexemplo bem caracterizado; paralelo com `@path` é coerente. |
| **H1-12** | **confirmed** | openpolicyagent.org/docs/management-bundles confirma `roots` como namespace de ownership por prefixo de path e que conflitos entre bundles **não** têm garantia de ordem ("no ordering guarantees…OPA may go into an error state") → devem ser resolvidos explicitamente pelo operador. A parte "OCP compõe stacks hierárquicos" vem da fonte secundária (ocp/concepts), não desta página; o núcleo (roots = escopo; conflito resolvido explicitamente, não por ordem — Rego é order-independent) está sustentado. Isomorfismo com KG-SUPERSEDES é analogia interna, válida. |

**Síntese do verificador**: nenhum achado refutado; **12/12 confirmed**. O stream é sólido e não exagera nas
claims centrais. Três ressalvas de **atribuição de fonte** (não de veracidade) a registrar para auditoria:
(a) H1-04 — o `inlinePatch.md` primário é fino sobre o merge type-aware; a mecânica merge-key vem da doc do
Kubernetes SMP / fonte secundária. (b) H1-07 — o footgun de array (`lib`/`types` replace) e `extends`-como-array
do TS 5.0 vêm de secundária/release-notes, não da página `extends`. (c) H1-09 — deep-merge e a cadeia completa de
precedência do Helm vêm da página companheira `values_files`, não de `subcharts_and_globals`. Correção fina
sugerida ao autor: no achado #2, evitar a generalização "arrays fazem merge" — o correto é "`permissions` (e
arrays explicitamente marcados como `claudeMdExcludes`/`allowedHttpHookUrls`) mergeiam; a maioria dos settings
faz replace" (a própria doc: "most settings replace, not merge").
