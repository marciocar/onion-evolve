# H3 — Monorepo em time + versão: como VERSIONAR, HERDAR e POLIMORFAR config/ferramenta através de escopos (caso Grana.Ai)

> Stream H3 do redesign de **herança-de-escopo** do Sistema Onion.
> Pergunta-mãe: como entregar `.claude/ + docs + agentes + scripts` numa hierarquia
> **framework → empresa → time → pessoa** dentro de um **nx monorepo regulado** (Grana.Ai),
> herdando do pai e podendo sobrepor, **sem atrito** e **seguindo a corrente do mercado**.
> Este stream olha o mecanismo de **compartilhamento + override de config/ferramenta em time num monorepo**.

---

## Resumo executivo

O mercado **não versiona escopo por branch**. Onde há hierarquia empresa→time→pessoa convivendo num mesmo checkout, o
padrão vencedor e universal é a **CASCATA POR DIRETÓRIO/ESCOPO** — o processo caminha a árvore de diretórios (ou uma
cadeia de escopos fixos) mesclando camadas, e **a camada mais específica vence** (last-wins). Isso vale para:

- **ferramenta** (mise/asdf caminham o dir-tree mesclando `mise.toml`/`.tool-versions` — F4),
- **identidade git** (`includeIf "gitdir:…"` injeta config por sub-árvore),
- **config nativa do Claude Code** (managed → cli → local → project → user, e `CLAUDE.md` hierárquico + `@import`),
- **defaults de tarefa no nx** (`targetDefaults` no `nx.json` como base, `project.json` sobrepõe),
- **política de dependência** (Renovate `extends: []` — cadeia de presets, ordem = proveniência).

Três achados estruturais para o Onion:

1. **Branches perdem** para este caso: você fica em UM branch por vez; herança precisa **compor N camadas simultâneas**.
   Cascata compõe; branch não. (Confirma a suspeita do maestro.)
2. **O gap central do enunciado — escopo time/pessoa DENTRO de um repo — já é resolvido pelo mercado para outros
   domínios** (`includeIf gitdir`, mise walk-up, nx tags-por-path, CODEOWNERS-por-path) mas **o Claude Code NÃO o faz
   para `.claude/`**: a cascata nativa dele tem 4 slots FIXOS e o `user` é **global da máquina**, não por-subdiretório.
   Ninguém oferece "`.claude/` de sub-pasta herdando do `.claude/` do repo". Esse é o buraco a fechar.
3. **Governança em regulado é ORTOGONAL à herança**: quem-pode-sobrepor-o-quê é resolvido por **CODEOWNERS-por-path +
   branch protection + required-reviewer rulesets + bypass-list auditável** — camada de *política*, não de *merge*.

Veredito de mecanismo deste stream: **cascata-nativa por escopo/diretório** (composição N-camadas last-wins) como
espinha, **merge-n-camadas** (estilo `vendor-branch.sh` generalizado) só para reconciliar a **base herdada vs override
local** quando as duas mudam, e **overlays** (estilo stow) como modelo mental de "cada camada é um pacote sobreponível".
**Branches: rejeitado como mecanismo de herança** (serve a distribuição/versão do framework, não à composição de escopo).

---

## Achados

### 1. nx: `targetDefaults` (nx.json) é a base, `project.json` sobrepõe — cascata de 2 níveis, mais-específico-vence

**Claim:** No nx a configuração de tarefa resolve por precedência: `inputs = projectJson.targets.build.inputs || nxJson.targetDefaults.build.inputs` — ou seja, o `project.json` do projeto **sobrepõe** os `targetDefaults` globais do `nx.json`, que servem de fallback. "Project level configuration will overwrite both targetDefaults and inferred tasks."

**URL:** https://nx.dev/docs/reference/project-configuration · https://nx.dev/docs/concepts/types-of-configuration

**Materialidade:** alta — é o mecanismo canônico de "config de time (repo-wide) + override por projeto" no ecossistema exato do Grana.Ai (nx).

**Implicação p/ Onion:** o padrão nativo do nx **já é uma cascata de 2 camadas last-wins** (empresa/repo → projeto). O Onion deve espelhar essa semântica em vez de inventar outra: `.claude` de repo = `targetDefaults`; `.claude` de time/projeto = `project.json`.

**Base reusável tocada:** (1) resolução-por-camadas — generaliza `resolve-integration-branch.sh` de "primeiro-que-casa-vence" para "mais-específico-sobrepõe".

---

### 2. nx: NÃO há `extends` a nível de `project.json` para sub-grupos — a herança intermediária (time) hoje é DUPLICAÇÃO

**Claim:** `targetDefaults` só oferece um nível **global** (todos os projetos). Para config compartilhada por um **subconjunto** de projetos (ex.: só o time X), "the only option is duplication". Há discussão aberta pedindo `extends`/referências em `project.json`, ainda **não** entregue.

**URL:** https://github.com/nrwl/nx/discussions/33761 · https://nx.dev/docs/guides/tasks--caching/reduce-repetitive-configuration

**Materialidade:** alta — é a **prova de que o nível intermediário "time" é exatamente o gap** também no líder de mercado. Ninguém tem a camada do meio pronta.

**Implicação p/ Onion:** o Onion não está "atrasado" — o **nível de time entre org e projeto é território aberto**. Oportunidade de liderar com uma cascata N-camadas (empresa→time→pessoa) onde o mercado só tem 2. Mas confirma: a herança precisa **compor**, não duplicar.

**Base reusável tocada:** (2) merge-n-camadas — o que falta virar N-camadas é justamente o nível do meio.

---

### 3. nx tags + `enforce-module-boundaries`: governança de "qual escopo pode depender de qual" via ESLint

**Claim:** Cada lib recebe `tags` no `project.json` (ex. `scope:payments`, `scope:kyc`, `scope:shared`) e a regra `@nx/enforce-module-boundaries` no ESLint **falha o build** se um escopo importar de outro não permitido. Tags carregam duas dimensões: `scope` (domínio/vertical) e `type` (camada).

**URL:** https://nx.dev/docs/features/enforce-module-boundaries · https://nx.dev/blog/mastering-the-project-boundaries-in-nx

**Materialidade:** alta — mostra como o monorepo regulado **isola escopos com enforcement determinístico** (não convenção).

**Implicação p/ Onion:** o Onion pode marcar cada camada/vertical com tag de escopo e usar um gate mecânico (estilo `.claude/validation/`) para impedir que a camada da pessoa importe/sobreponha algo que a camada da empresa proíbe. Enforcement de herança = lint, não confiança.

**Base reusável tocada:** (4) roles.yaml/polimorfismo de bundle — tags de escopo são o equivalente nx de "qual bundle/escopo cada papel recebe".

---

### 4. nx `@nx/owners`: CODEOWNERS é COMPILADO das tags/projetos via `nx sync` — proveniência de ownership auto-sincronizada

**Claim:** Em vez de manter `CODEOWNERS` à mão (que exige revisitar a cada projeto que move/nasce), o `@nx/owners` define ownership por **projeto/tag** (mesma sintaxe do `nx run-many`) e **compila para um `CODEOWNERS` válido** (GitHub/GitLab/Bitbucket) via `nx sync` — ownership fica alinhado à estrutura automaticamente.

**URL:** https://nx.dev/docs/concepts/decisions/code-ownership

**Materialidade:** alta — resolve **proveniência + governança** de escopo de forma gerada (não hardcoded), o mesmo princípio do inventário SSOT do Onion.

**Implicação p/ Onion:** modelo direto para "qual camada contribuiu o quê + quem responde por ela": gerar o `CODEOWNERS` (governança de override) **da mesma SSOT** que define as camadas de escopo, em vez de manter à mão. Espelha `inventory.sh` (SSOT gerada + validada no CI).

**Base reusável tocada:** (1) resolução-por-camadas + a doutrina SSOT-gerada do Onion (inventory).

---

### 5. mise/asdf: cascata REAL por diretório — caminha o dir-tree mesclando `mise.toml`/`.tool-versions`, mais-fundo-vence

**Claim:** "Mise walks up the directory tree looking for configuration files (`mise.toml`, `.tool-versions`) and merges them hierarchically." Camadas empilham: `~/.config/mise/config.toml` (máquina) → `~/proj/mise.toml` (projeto) → `~/proj/packages/algorithm/mise.toml` (subpacote). Tool-versions são escopadas ao subdiretório.

**URL:** https://mise.jdx.dev/configuration.html · https://mise.jdx.dev/dev-tools/

**Materialidade:** alta — é o **exemplo mais limpo de cascata N-camadas por diretório** já em produção em monorepos, exatamente o formato empresa→time→pessoa querido.

**Implicação p/ Onion:** este é o **mecanismo-referência** para versionar/pinar **ferramenta compartilhada por escopo** no Grana.Ai (mise por dir de time/projeto). E o **modelo mental exato** que falta ao `.claude/`: um resolver que caminha do dir da pessoa até a raiz do repo mesclando camadas de `.claude`.

**Base reusável tocada:** (2) merge-n-camadas + (4) *-context local (SDAAL) — a cascata cognitiva do Onion é o análogo semântico da cascata de tool-versions.

---

### 6. git `includeIf "gitdir:…"` / `hasconfig:remote.*.url`: injeta config por SUB-ÁRVORE — cascata nativa por path dentro do checkout

**Claim:** `[includeIf "gitdir:~/work/**"] path = …` insere config condicionalmente conforme o path do repo/subdir atual; o conteúdo incluído é inserido no ponto da menção e **sobrepõe chaves anteriores** (last-wins). Git 2.36 (2022) adicionou `hasconfig:remote.*.url` para condicionar pelo remote.

**URL:** https://git-scm.com/docs/git-config#_conditional_includes · https://jdsalaro.com/tutorial/git-configuration-folder-dependent-conditional-includes/

**Materialidade:** alta — **prova de que "config por subdiretório dentro de um repo" é padrão nativo e sem atrito** — para identidade git. É o gap do enunciado, já resolvido por analogia num domínio vizinho.

**Implicação p/ Onion:** existe um mecanismo git-nativo de **ativação de camada por path** que o Onion pode imitar (ou até dogfoodar literalmente para a camada de identidade/pessoa). Reforça: escopo-dentro-do-repo = **condicional por path**, não branch.

**Base reusável tocada:** (1) cadeia de precedência (git config já é o degrau 2 do `resolve-integration-branch.sh`).

---

### 7. chezmoi: fonte única + templates + `.chezmoidata` — polimorfismo por máquina com precedência de dados last-wins

**Claim:** O source-dir é **comum a todas as máquinas**; arquivos idênticos são copiados verbatim, os que variam são **templates** que consomem dados locais. Precedência de variáveis "last one wins": built-in (interrogação do sistema) < dados de `.chezmoidata.$FORMAT` < config. A camada **pessoal** herda o baseline e sobrepõe via dados/flags de init (`personal_computer`, `use_secrets`).

**URL:** https://www.chezmoi.io/user-guide/templating/ · https://www.chezmoi.io/reference/templates/ · https://www.chezmoi.io/reference/configuration-file/variables/

**Materialidade:** alta — é o **modelo canônico de camada PESSOAL versionada herdando de um baseline** (org/time), com **polimorfismo** (templates) em vez de cópia divergente.

**Implicação p/ Onion:** ensina a **polimorfar** a entrega (não só sobrepor arquivos): a base do framework é o template, o `*-context` local é o dado que especializa — exatamente a "herança em runtime cognitivo" (SDAAL). Distingue *override de arquivo* de *override de dado que re-renderiza a base* (paralelo ao `distilled` = herança de doutrina reescrita).

**Base reusável tocada:** (4) `*-context` local + SDAAL (base=spec do framework + contexto local re-renderiza) e o papel `distilled` de roles.yaml.

---

### 8. GNU stow: composição por overlay de pacotes (symlink farm) — mas SEM templating (não polimorfa por host)

**Claim:** Stow é um "symlink farm manager": cada "pacote" no dir de dotfiles é sobreposto (symlink) na home; organização modular por pacote, detecção de conflito, reversível. Limite explícito: "Stow has no templating capability to customize files per machine" — camadas se **sobrepõem** mas não se **reescrevem**.

**URL:** https://rickcogley.github.io/dotfiles/explanations/gnu-stow.html · https://lobste.rs/s/5h8eyy/managing_dotfiles_with_gnu_stow

**Materialidade:** média — define a fronteira entre **OVERLAY puro** (compõe por sobreposição de arquivos inteiros) e **cascata com polimorfismo** (chezmoi/SDAAL).

**Implicação p/ Onion:** overlay é ótimo para **compor camadas de arquivos discretos** (um agente extra do time, um comando extra da pessoa) sem conflito — o Onion pode usar esse modelo para as partes **aditivas** da herança. Mas para as partes que **especializam o mesmo artefato** (CLAUDE.md, contextos), overlay não basta: precisa de merge/template. Sinaliza um **híbrido**: overlay para aditivo, merge/template para override.

**Base reusável tocada:** (2) vendor-branch (3-way só onde há override real; o resto compõe limpo — mesma lógica de "conflito só onde toca").

---

### 9. Renovate: `extends: []` — cadeia de presets compartilháveis, aninháveis, com auto-extend de preset de ORG

**Claim:** Presets são config reutilizável referenciada num array `extends`; podem ser **aninhados**; Renovate aplica na **ordem do array** (proveniência explícita). No onboarding, procura automaticamente um repo `renovate-config` com `default.json` no **user/group/org pai** e o estende. Pinning por escopo via `packageRules` + `rangeStrategy: pin`.

**URL:** https://docs.renovatebot.com/config-presets/ · https://docs.renovatebot.com/key-concepts/presets/

**Materialidade:** alta — é **herança de POLÍTICA por cadeia explícita** (empresa→time→projeto) com **proveniência ordenada** e pinagem por escopo, tudo declarativo/versionado.

**Implicação p/ Onion:** modelo direto para "empresa define baseline, time estende, projeto sobrepõe" com **cada camada nomeada e ordenada** (proveniência automática de qual camada contribuiu o quê). O auto-extend do preset de org é o análogo do "puxar do pai" sem que o filho copie nada.

**Base reusável tocada:** (1) cadeia de precedência (ordem do `extends` = provenance) + (3) SUPERSEDES (verdade nova da camada superior supera a base sem apagá-la).

---

### 10. Claude Code — cascata NATIVA de settings: managed → cli → local → project → user (managed = piso inviolável)

**Claim:** Precedência oficial: **1. Managed (não pode ser sobreposto por nada) → 2. CLI args → 3. Local → 4. Project → 5. User**. `managed-settings.json` vive em `/etc/claude-code/` (Linux), `/Library/Application Support/ClaudeCode/` (macOS), `C:\Program Files\ClaudeCode\` (Win), com `managed-settings.d/` para fragmentos. Campos como `allowManagedPermissionRulesOnly` impedem regras de user/project de valerem.

**URL:** https://code.claude.com/docs/en/settings

**Materialidade:** alta — é a **cascata nativa que o Onion HOJE não explora**, e o piso `managed` é exatamente "empresa impõe, ninguém relaxa" — governança de regulado embutida.

**Implicação p/ Onion:** o veículo óbvio já existe: **managed ≈ empresa (piso regulado inviolável)**, **project ≈ time/repo**, **user ≈ pessoa**. Mas note o **gap**: são **4 slots fixos**, o `user` é **global da máquina** (não por-subdir), e **falta o nível "time" intermediário por-diretório dentro do monorepo**. A cascata nativa cobre empresa/pessoa/repo; **não** cobre time-dentro-do-repo nem pessoa-por-subpasta.

**Base reusável tocada:** (4) camadas nativas do Claude Code — hoje inexploradas; este é o encaixe direto.

---

### 11. Claude Code — `CLAUDE.md` hierárquico + `@import`: instrução mais específica vence, composição modular por referência

**Claim:** O Claude Code carrega **todos** os `CLAUDE.md` aplicáveis (enterprise/project/user/subdir) e **combina**; "more specific instructions take precedence over broader ones". `@import`/`@path` referencia arquivos externos para reuso modular sem copiar.

**URL:** https://code.claude.com/docs/en/settings · https://agentfactory.panaversity.org/docs/General-Agents-Foundations/claude-code-teams-cicd/claude-md-configuration-hierarchy

**Materialidade:** alta — **cascata de CONHECIMENTO/instrução** (não só de flags): o `CLAUDE.md` já compõe N camadas com last-wins e importa por referência.

**Implicação p/ Onion:** a herança **cognitiva** (doutrina/contexto) já tem veículo nativo: `CLAUDE.md` de subdir do time + `@import` do baseline do framework. Isso realiza a "herança em runtime cognitivo" sem inventar mecanismo. O `@import` é a peça de **composição por referência** (o filho aponta o pai, não copia) — anti-atrito.

**Base reusável tocada:** (3) SUPERSEDES do KG (instrução específica supera a genérica sem apagar) + (4) SDAAL/contexto local.

---

### 12. Claude Code — marketplace de org: auto-install/available por GRUPO, `forcedPlugins`/`strictKnownMarketplaces` no managed

**Claim:** Team/Enterprise distribuem plugins curados; a preferência de instalação é por org **e sobreponível por GRUPO** (ex.: auto-install para Engenharia, disponível-sob-demanda para Legal). `forcedPlugins` no managed instala sem interação (CI/containers); `strictKnownMarketplaces` restringe as fontes aprovadas.

**URL:** https://support.claude.com/en/articles/13837433-manage-plugins-for-your-organization · https://code.claude.com/docs/en/plugin-marketplaces

**Materialidade:** alta — é **escopo-de-capacidade por grupo** nativo, e o `roles.yaml` do Onion já foi desenhado para isso ("role → group → auto-install destes plugins").

**Implicação p/ Onion:** o polimorfismo de bundle por papel (`resolve-role-bundle.sh`) tem **assentamento nativo direto** no marketplace de org: empresa=marketplace, grupo=time, override-por-grupo=camada de time. `forcedPlugins` no managed = piso regulado de "o que o time DEVE ter". Realiza empresa/time como capacidade sem branch.

**Base reusável tocada:** (4) roles.yaml + resolve-role-bundle.sh (o comentário do próprio arquivo já cita "acesso-por-grupo Team/Enterprise").

---

### 13. Governança em regulado: CODEOWNERS-por-path + branch protection + required-reviewer rulesets + bypass-list auditável

**Claim:** Para SOX/SOC2, protege-se ramos exigindo **aprovação de code owner**, commits assinados, sem force-push, com paths sensíveis (billing/accounting) exigindo review de finance/audit. O novo **required-reviewer rule** (GA 2026-02) e **required review by specific teams** (rulesets, 2025-11) reforçam CODEOWNERS **sem substituí-lo**; só quem está na **bypass list** empurra sem review. Limite conhecido: os logs nativos do GitHub carecem de granularidade/exportação que auditoria exige.

**URL:** https://github.blog/changelog/2026-02-17-required-reviewer-rule-is-now-generally-available/ · https://github.blog/changelog/2025-11-03-required-review-by-specific-teams-now-available-in-rulesets/ · https://www.propelcode.ai/blog/code-review-compliance-sox-hipaa-pci-requirements

**Materialidade:** alta — responde diretamente o "quem-pode-sobrepor-o-quê com AUDITORIA" do Grana.Ai regulado.

**Implicação p/ Onion:** governança de override é **camada de política ORTOGONAL à herança** — resolvida por `CODEOWNERS` por path (gerado, achado #4) + branch protection + rulesets + bypass-list. O override de uma camada inferior sobre a superior deve **passar por review do owner da camada superior**. Como logs nativos são fracos, o Onion pode complementar com **proveniência versionada por camada** (qual camada mudou o quê, no git) como trilha de auditoria própria.

**Base reusável tocada:** (2) vendor-branch (o override vira conflito git resolvível = evento auditável) + (4) CODEOWNERS gerado da SSOT de escopo.

---

## Veredito de mecanismo (deste stream)

| Mecanismo | Papel no caso monorepo/time | Veredito |
|---|---|---|
| **Cascata-nativa por escopo/diretório** | Espinha. Caminha empresa→time→pessoa mesclando camadas, mais-específico-vence. Já é o padrão de mise, git `includeIf`, settings/CLAUDE.md do Claude Code, nx `targetDefaults`. | ✅ **ADOTAR como mecanismo primário** |
| **Merge-n-camadas** (generalizar `vendor-branch.sh`) | Só quando **base herdada E override local mudam** — reconciliar como conflito git resolvível/auditável. Hoje 2 camadas bilaterais; falta virar N. | ✅ **ADOTAR para o eixo de reconciliação** (base↔override) |
| **Overlays** (modelo stow) | Modelo mental para as partes **aditivas** (um agente/comando extra de time/pessoa) — compõem sem conflito. Não serve para especializar o mesmo artefato. | ⚠️ **Parcial** — só o aditivo |
| **Branches** (`onion/adopt→…/teams/…/members/…`) | Você fica em UM branch por vez; herança precisa de **N camadas simultâneas**. Serve à **distribuição/versão do framework**, não à composição de escopo em runtime. | ❌ **REJEITADO como mecanismo de herança** |

**Síntese:** o mecanismo é **cascata-nativa (N-camadas, last-wins, por diretório/escopo) + merge-n-camadas para reconciliar
base↔override + overlay para o aditivo** — um **híbrido com espinha em cascata**. Branch fica fora do loop de herança.

**Proveniência (transversal (c)):** cada camada deve ser **nomeada e ordenada** (como o `extends: []` do Renovate e a
ordem de inserção do `includeIf`), para que o resolver possa reportar **qual camada contribuiu cada chave/artefato** —
requisito de auditoria em regulado. A proveniência sai de graça se a cascata for ordenada e versionada.

**O gap confirmado (transversal (e)):** *escopo time/pessoa DENTRO de um repo* não existe para `.claude/` em nenhum eixo.
O mercado já o resolve para **domínios vizinhos** por-path (`includeIf gitdir`, mise walk-up, nx tags/owners por path,
CODEOWNERS por path). A cascata nativa do Claude Code tem só 4 slots e `user` é global — **falta um resolver que caminhe
do subdir da pessoa até a raiz do repo mesclando camadas de `.claude`/contexto**. Essa é a peça a construir.

---

## Encaixe Grana.Ai (empresa/time/pessoa num nx monorepo regulado — resolvido concretamente)

**Topologia proposta (sem branch de escopo, seguindo a corrente):**

1. **Framework (Onion core)** — baseline vendorizado; entra como camada-base (vendor-branch, achado #8/#2) e/ou
   `@import` da doutrina no `CLAUDE.md` raiz (#11). Pinado por versão (`.onion-version`).
2. **Empresa (Grana.Ai)** — **piso regulado inviolável** via `managed-settings.json` (#10) + `forcedPlugins`/
   `strictKnownMarketplaces` no marketplace de org (#12). É o que **ninguém relaxa** (compliance). Baseline de política
   também como **preset Renovate de org** (#9) e `targetDefaults` no `nx.json` (#1).
3. **Time (ex.: `desenvolvimento`)** — camada intermediária, **o gap do mercado** (#2). Materializar por **diretório de
   projeto/time no monorepo**: `.claude/`, `mise.toml` e `CLAUDE.md` **na pasta do time**, resolvidos por cascata-por-path
   (modelo mise #5 / `includeIf gitdir` #6). Escopo isolado por **nx tags** `scope:desenvolvimento` (#3); ownership do time
   gerado em `CODEOWNERS` via `@nx/owners`/`nx sync` (#4). Capacidade do time = **override-por-grupo** no marketplace (#12).
4. **Pessoa (ex.: `mauricio`)** — camada mais específica: `user` settings (#10) + `CLAUDE.md`/dados pessoais no estilo
   **chezmoi templates + `.chezmoidata`** (#7) herdando o baseline do time e sobrepondo por polimorfismo (não por cópia).

**Resolução em runtime:** um resolver (generalização do `resolve-integration-branch.sh`, #1/#6) caminha
`pessoa → time → empresa → framework`, mescla last-wins e **reporta proveniência por chave**. Onde base e override
colidem, cai no **merge-n-camadas** (vendor-branch generalizado, #2) — conflito git resolvível = evento auditável.

**Governança/regulado (quem sobrepõe o quê, com auditoria):** override de camada inferior sobre item de camada superior
**exige review do owner da superior** — `CODEOWNERS` por path (gerado, #4) + branch protection + required-reviewer
rulesets + bypass-list (#13). O piso da empresa é `managed` (inviolável por design, #10). Trilha de auditoria =
**proveniência versionada por camada** no git (complementa os logs nativos fracos do forge).

**Ferramenta compartilhada (stage/prod, pinagem por escopo):** `mise`/`.tool-versions` por diretório de time/projeto (#5)
+ Renovate com `extends` de preset de org e `rangeStrategy: pin` por escopo (#9) — versão de ferramenta herda do pai e
sobrepõe por subpasta, exatamente como as camadas de config.

**Não-atrito (transversal (b)):** cada peça acima é **um mecanismo que o time do Grana.Ai já usaria de qualquer forma**
(nx tags, CODEOWNERS, mise, managed settings, CLAUDE.md). O Onion **segue a corrente**: orquestra veículos nativos numa
cascata ordenada com proveniência, em vez de introduzir branches de escopo ou um formato proprietário.

---

## Verificação adversarial

Passe adversarial (2026-07-09) contra as 13 fontes materiais. Método: fetch da fonte citada, checagem de existência/frescor, se sustenta o claim sem exagero e se há contra-evidência. Veredito por finding.

| finding_id | veredito | nota |
|------------|----------|------|
| **H3-01** | **confirmed** | Fonte oficial nx confirma a cascata "inferred tasks < targetDefaults (nx.json) < project-level (project.json/package.json)", "most specific wins" e que project.json sobrescreve targetDefaults. Ressalva: a doc descreve **3 fontes**, não 2 — o claim ("cascata de 2 níveis") subconta; e o merge é **inteligente** (spread token `"..."`), não substituição pura. Núcleo (mais-específico-vence) intacto. |
| **H3-02** | **confirmed** | Discussion #33761 existe e é **feature request aberta** (post 2025-12-08, apoio 2026-03-09, sem implementação): "when multiple projects share identical target configurations (but not all projects), there's no way to define that configuration once and reference it" → "the only option is duplication". Sustenta o ponto "nível intermediário (time) é gap até no líder de mercado". Recente. |
| **H3-03** | **confirmed** | Doc oficial confirma tags (`scope:*`) + `@nx/enforce-module-boundaries` + `depConstraints` que **falham no lint** com mensagem "A project tagged with 'scope:admin' can only depend on...". Ressalva menor: enforcement é em **lint** (ESLint), não "build" compilado — mas lint gateia o CI. Determinístico, confirmado. |
| **H3-04** | **confirmed** | Doc oficial: "The `@nx/owners` plugin lets you define code ownership based on projects... and compiles it into a valid CODEOWNERS file for GitHub, Bitbucket, or GitLab." Gerado da mesma SSOT. O mecanismo `nx sync` (sync generator) é consistente com owners mas não citado verbatim nesta página — sem exagero material. |
| **H3-05** | **confirmed** | Doc mise confirma recursão para cima ("These files recurse upwards... The config contents are merged together"), scoping por subdiretório (exemplo node@20 em myproj vira node@18 em myproj/backend) e precedência mise.local > mise.toml > global > /etc. Exemplo limpo de cascata N-camadas por diretório. Forte. |
| **H3-06** | **confirmed** | Fonte jdsalaro sustenta includeIf `gitdir:**` por sub-árvore + last-wins ("the former's user section will be overriden by the latter"). O detalhe **Git 2.36 `hasconfig:remote.*.url`** NÃO está nessa fonte, mas é **independentemente verdadeiro** (Git 2.36, abr/2022 — confirmado por busca + git-config docs). Recomendação: citar git-scm.com/docs/git-config para a parte hasconfig. |
| **H3-07** | **confirmed** | Doc chezmoi confirma source-dir comum + templates que consomem dados locais + precedência `.chezmoi` (built-in) < `.chezmoidata.$FORMAT` (alfabético) < `data` do config, "later data overwrite earlier ones". Polimorfismo por template, não cópia. Fiel. |
| **H3-08** | **confirmed** | Fonte confirma symlink farm/overlay reversível ("Unstow and restore original state") e o limite verbatim "No templating: Can't customize files per machine." Fronteira overlay-puro vs cascata-com-polimorfismo bem estabelecida. |
| **H3-09** | **confirmed** | Doc Renovate confirma `extends` array ordenado + presets aninháveis + auto-extend de `renovate-config/default.json` do user/group/org pai (e busca hierárquica nearest-to-furthest em GitLab). Ressalva: `packageRules`+`rangeStrategy:pin` **não** está nesta página (config-presets) — é feature real documentada em outra página. Herança de política por cadeia ordenada: confirmada. |
| **H3-10** | **confirmed** | Doc oficial confirma cascata **managed > cli > local > project > user**, locais de `managed-settings.json` (/etc/claude-code/, /Library/Application Support/ClaudeCode/, C:\Program Files\ClaudeCode\) e `allowManagedPermissionRulesOnly` ("Only rules in managed settings apply"). "4 slots FIXOS" é leitura interpretativa (4 escopos persistentes fora do cli) — aceitável. |
| **H3-11** | **confirmed (citação a corrigir)** | O FATO é sólido em doc oficial, MAS a fonte citada (`/docs/en/settings`) NÃO o cobre — está em **`/docs/en/memory`**: "All discovered files are concatenated into context rather than overriding each other... instructions closer to where you launched Claude are read last" + imports `@path/to/import` (recursivo até 4 hops). Nuance: docs dizem **concatenação com ordenação last-wins**, não "override" estrito — "mais específico precede" é caracterização justa da ordem de leitura. Corrigir a URL da fonte para a página de memory. |
| **H3-12** | **confirmed** | Artigo de suporte confirma override de preferência de install **por grupo** ("override a plugin's organization-wide installation preference for specific groups"; auto-install Engenharia / disponível Legal; conflito = mais permissivo vence). Ressalva: `forcedPlugins` e `strictKnownMarketplaces` **não** aparecem neste artigo (são reais, em managed settings/plugin reference). Núcleo escopo-por-grupo: confirmado. |
| **H3-13** | **confirmed** | Changelog GitHub confirma required-reviewer rule **GA em 2026-02-17**, que "augments CODEOWNERS files but doesn't replace them" e permite exigir aprovação de **times designados** + exclusão de paths. Ressalvas: o item "2025-11 required review by specific teams", a **bypass-list** e a alegação sobre **granularidade fraca de logs para SOX/SOC2** são analíticas/de outras fontes — não estão neste changelog. Núcleo (override-de-camada ortogonal à herança, via ruleset+CODEOWNERS): confirmado. |

**Síntese:** 13/13 confirmed. Nenhuma fabricação. Ajustes recomendados antes de citar: (a) **H3-11 — trocar a URL da fonte** de `/docs/en/settings` para `/docs/en/memory` (o settings não descreve a fusão de CLAUDE.md nem `@import`); (b) **H3-06** — adicionar git-scm.com/docs/git-config para o detalhe `hasconfig:remote.*.url` (Git 2.36); (c) suavizar sub-detalhes fora da fonte primária citada em H3-09 (`rangeStrategy:pin`), H3-12 (`forcedPlugins`/`strictKnownMarketplaces`) e H3-13 (bypass-list, log SOX/SOC2) — todos verdadeiros, mas documentados em outras páginas; (d) H3-01 — a cascata nx tem **3 fontes** (não 2) e o merge usa spread token.
