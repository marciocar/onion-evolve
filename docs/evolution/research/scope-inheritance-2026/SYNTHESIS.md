# SYNTHESIS — Herança de escopo do Sistema Onion (framework → empresa → time → pessoa)

> Síntese dos 4 streams (H1 cascata/override de mercado · H2 camadas nativas do Claude Code ·
> H3 monorepo/time/versão no caso Grana.Ai · H4 herança mediada por IA SDAAL/KG).
> **Natureza:** insumo de evidência para a decisão do maestro — **não decide doutrina**. Só achados
> **`confirmed`** (50/50 nos 4 streams: H1 12/12, H2 13/13, H3 13/13, H4 sem passe formal mas com fonte
> primária por achado) sustentam recomendação; o resto vai marcado em *Confiança e gaps*.
> Convenção de citação: `H1·F6` = stream H1, achado 6 (para H4, `H4·F5` = achado F5).

---

## Veredito de MECANISMO

**Os 4 streams convergem, com alta confiança e sem divergência material, para o mesmo veredito:
mecanismo HÍBRIDO com CASCATA-NATIVA do Claude Code como espinha dorsal; branches REJEITADAS como
mecanismo de herança de escopo.**

### O branch-exemplo do maestro NÃO serve (como mecanismo de composição)

O exemplo em branches (`onion/adopt → …/granaai → …/teams/desenvolvimento → …/members/mauricio`)
**não é o mecanismo** — e essa é a única resposta que os 4 streams dão em uníssono:

- **É antipadrão documentado.** Usar branch git para representar ambiente/escopo é antipadrão GitOps
  explícito, com fonte primária: gera merge-conflict que propaga config indesejada entre camadas,
  esconde "o que está onde", e "promotion is never a simple Git merge" — a recomendação de mercado é
  overlays por diretório + trunk-based (H1·F6, octopus.com/Kapelonis).
- **Branch não compõe; herança precisa compor.** A intuição do maestro ("não se fica em 4 branches ao
  mesmo tempo; herança precisa COMPOR") é o consenso. Cascata/overlay é uma **função pura de N camadas →
  resultado**, avaliada na leitura, com as N camadas coexistindo simultaneamente (empresa E time E pessoa
  ao mesmo tempo) e override **por-chave** (H1·veredito, H3·F resumo). Branch é **reconciliação de
  histórico com estado**: você fica em UMA por vez; unir 4 linhagens é merge 4-way textual-por-linha,
  **sem proveniência por-chave** (H1·veredito).
- **Nada no vetor modela herança por branch.** A herança nativa do Claude Code é por **composição em
  runtime** (concatenação de `CLAUDE.md`/rules/skills) e **precedência de resolução** (settings/agents).
  Ficar em 4 branches não tem análogo nativo; concatenar 4 `CLAUDE.md` tem (H2·veredito, H4·F1).

**Branch permanece útil — mas noutro eixo, ortogonal ao escopo:** reconciliar **versões do framework no
tempo** (o 3-way do `vendor-branch.sh`: upgrade do core → adotante) e servir de **transporte/proveniência/
ledger** (base herdada vendorizada, ledger de federação). Versão × escopo são dois eixos separados
(H1·F6, H3·veredito, H4·veredito).

### Por que overlays/cascata compõem melhor — e onde cada um entra

O mecanismo é **de três planos, não um** (H4·veredito; corroborado por H2 "mecanismo dual"):

| Plano | Mecanismo recomendado | Por quê | Evidência |
|---|---|---|---|
| **Cognitivo** (doutrina, `*-context` SDAAL, `CLAUDE.md`, rules, skills, agentes) | **CASCATA-NATIVA** (cavalgar) | O Claude Code **já** concatena N camadas amplo→específico (managed→user→project→local) e raiz→cwd; `@import` compõe explícito; walk-up dá override por proximidade (time-dentro-do-repo). É merge-N-camadas nativo. **Não reinventar.** | H1·F3, H2·F4/F5, H3·F11, H4·F1 |
| **Configuração** (`settings.json`, permissões, env, worktree) | **MERGE-N-CAMADAS** (generalizar `vendor-branch.sh`) + qualidade strategic-merge | Assimetria decisiva: `settings.json` **NÃO herda pela árvore** — carrega só do dir inicial, self-contained por diretório. Aqui a cascata nativa **falha** — é o gap real. O Onion precisa de um resolver/gerador que componha framework→empresa→time e materialize o `settings.json` por diretório. | H2·F7 (crítico), H1·F4, H3·F5 |
| **Conhecimento/verdade** (KB, contexto de negócio/compliance que evolui) | **SUPERSEDES bitemporal** (eixo ORTOGONAL) | Verdade nova **invalida sem apagar**, com valid-time + provenance-time — mecanismo separado do merge de arquivo. "git merge não reconcilia verdades" é literalmente correto. Conflito de política resolve-se por **aresta explícita**, não por última-camada-vence. | H4·F5 (Zep/Graphiti), H1·F12 (OPA `roots`/conflito explícito) |

**Overlays (Kustomize base→overlay + strategic-merge)** entram como **modelo de qualidade do merge**, não
como transporte: dão o *type-aware* que o resolver do Onion deve imitar — escalares substituem, mapas
mesclam, listas por merge-key (H1·F4). E **components/mixins** separam o eixo **horizontal** (verticais
opcionais = `roles.yaml`) do **vertical** (escopo = overlay) — são dois mecanismos que não devem colidir
(H1·F5). A regra de ouro do mercado: **manter raso** — 4 escopos já é o limite; não criar sub-níveis
extras (H4·F8). Overlay puro (estilo stow) só serve para as partes **aditivas** (um agente extra do time);
para especializar o mesmo artefato, precisa merge/template (H3·F8).

**Requisito transversal confirmado por todos:** um **resolver de proveniência** — o análogo de
`git config --show-scope`: dado o estado resolvido, imprimir *qual camada contribuiu cada peça*. Git
(H1·F1) e ESLint-flat (H1·F8) provam que, em escala, precedência **explícita e inspecionável** ganha da
cascata mágica. Em regulado (Grana.Ai) isso é requisito de auditoria (H3·F4/F13).

### Ranking final dos 4 candidatos

1. **CASCATA-NATIVA** — vencedor como transporte da herança cognitiva. Máximo não-atrito (seguir a
   corrente) e já resolve o scoping sub-repo na camada cognitiva.
2. **MERGE-N-CAMADAS** (vendor-branch N-ificado) — necessário e suficiente para o gap: o `settings.json`
   que o nativo não herda pela árvore.
3. **OVERLAYS** — modelo de qualidade do merge (strategic-merge type-aware) + components para o eixo
   horizontal; overlay puro só para o aditivo.
4. **BRANCHES-para-escopo** — **rejeitado**. Reposicionado ao eixo VERSÃO (upgrade) e a transporte/ledger.

---

## Matriz escopo × mecanismo

| Escopo | Como **VERSIONA** | Como **HERDA** | Como **SOBREPÕE** | Camada **NATIVA** do Claude Code |
|---|---|---|---|---|
| **Framework** (Onion core) | `.onion-version` (stamp) + tag/release do core; upgrade reconciliado por `vendor-branch.sh` 3-way (eixo VERSÃO) — H3·F2/veredito | É a base; ninguém abaixo o conhece (desacoplamento Kustomize — H4·F8) | N/A (é a raiz da cascata) | Entregue como **plugin(s) versionado(s)** no marketplace interno (`onion-engineering`, `onion-compliance`, …) — H2·F10; ou **vendorizado** via `/meta:adopt` quando o CLI não auto-instala — H2·F12 |
| **Empresa** (Grana.Ai) | `managed-settings.json` versionado + preferência org-wide do plugin (Required) — H2·F10/H3·F12; política também como preset Renovate de org — H3·F9 | Herda o framework por concatenação/`@import` no `CLAUDE.md` raiz — H4·F1/H3·F11 | **Piso inviolável**: `managed` não é sobreponível por nada (nem CLI) — `permissions.deny`, `availableModels`, `strictKnownMarketplaces`, managed `claudeMd` — H2·F1/F3 | **Managed policy** — `managed-settings.json` + managed `CLAUDE.md`; ou **server-managed settings** (sem MDM, push do console) — H2·F11 |
| **Time** (`desenvolvimento`) | `packages/<time>/CLAUDE.md` + `.claude/` commitados (source control) — H2·F5; capacidade por override-de-grupo no marketplace (Enterprise) — H2·F10/H3·F12 | Concatena o raiz (empresa) por upward-traversal; herda default explícito — H4·F1/F3 | **Cognitivo**: `CLAUDE.md`/rules por diretório sobrepõem por proximidade (walk-up) — H2·F5/F8; `claudeMdExcludes` isola outros times — H2·F9. **Config**: `settings.json` NÃO herda → **merge-N-camadas do Onion** materializa self-contained — H2·F7 | **project** (`.claude/` do subdir do time) + `.claude/rules/` `paths:`-scoped + `.claude/agents/` (walk-up) — H2·F5/F8/F9. *Gap: sem nível nativo "time" para `settings.json`.* |
| **Pessoa** (`mauricio`) | `~/.claude/` (cross-repo) versionável pela pessoa; `CLAUDE.local.md` gitignored (por-repo) — H2·F11 | `user` lido antes de project (project vence onde colide); auto-memory per-repo — H1·F2/H2·F9 | Array-merge empilha (não apaga a herança); escalar da camada mais próxima vence — H2·F2; polimorfismo por dados (chezmoi template) — H3·F7 | **user** (`~/.claude/CLAUDE.md`, `~/.claude/agents/`, `~/.claude/rules/`) + **local** (`CLAUDE.local.md`) — H2·F1/F4. *Gap: "pessoa-dentro-do-time-dentro-do-repo" versionável/compartilhável é o único nível nativamente fraco — `@import ~/.claude/…` mitiga — H2·F6/F11.* |

**Leitura da matriz:** as 4 camadas **compõem simultaneamente** em runtime (concatenação amplo→específico
+ precedência tipada), com **compliance inviolável no topo** (managed = Root), **override estrutural**
onde preciso (merge-N-camadas para settings), e **verdade versionada** por SUPERSEDES — tudo já suportado
pelo vetor, sem manter ninguém em 4 branches (H4·encaixe).

---

## Caso Grana.Ai resolvido

Fintech regulada, **nx monorepo** privado, time de devs + stage/prod; dentro: empresa (Grana.Ai) ⊃ time
(`desenvolvimento`) ⊃ pessoa (`mauricio`), cada um herdando do pai e podendo sobrepor. `integration_branch:
develop`, nunca live-pull. **Resolução concreta, sem branch de escopo:**

**1. Framework (Onion core)** — baseline entregue como **plugin(s) versionado(s)** no marketplace interno
(namespace de plugin = proveniência) e/ou **vendorizado** via `/meta:adopt` (modelo durável), pinado por
`.onion-version`. Onde o CLI não auto-instala plugin de managed settings (H2·F12, *not planned*), a
**vendorização é o caminho primário** — o adotante regulado roda no CLI (dev + CI), então não pode depender
de auto-install.

**2. Empresa (Grana.Ai)** — **piso regulado inviolável** na raiz do monorepo: `managed-settings.json`
(ou server-managed, sem MDM — H2·F11) com `permissions.deny` de `.env`/segredos, `availableModels`
aprovados, `strictKnownMarketplaces`, e **managed `claudeMd`** com a doutrina de compliance. `onion-compliance`
marcado **Required** no marketplace de org (H2·F10). **Ninguém abaixo sobrepõe** — é o que "regulado" exige
(managed = Root, H4·F2/F3). Política de dependência como preset Renovate de org + `targetDefaults` no
`nx.json` (H3·F1/F9).

**3. Time (`packages/desenvolvimento/`)** — a **camada cognitiva já é resolvida nativamente**:
`packages/desenvolvimento/CLAUDE.md` (herda o raiz por concatenação) + `packages/desenvolvimento/.claude/skills/`
+ `.claude/rules/` com `paths: packages/desenvolvimento/**`; agentes do time em `.claude/agents/` sobrepõem
os do framework por nome (walk-up) — H2·F5/F8/F9. `claudeMdExcludes` isola `CLAUDE.md` de outros times do
monorepo — **esta é a "sub-repo scoping" que o grounding dava como inexistente, e é nativa** (H2·F5/H1·F3).
Escopo isolado por **nx tags** `scope:desenvolvimento` + `@nx/enforce-module-boundaries` (H3·F3); ownership
gerado em `CODEOWNERS` via `@nx/owners`/`nx sync` (H3·F4). **Gap real:** `settings.json` **não** herda do
raiz (H2·F7) → o **merge-N-camadas do Onion** materializa `packages/desenvolvimento/.claude/settings.json`
self-contained, compondo framework+empresa+time — é a peça de engenharia que o Onion acrescenta.

**4. Pessoa (`mauricio`)** — `~/.claude/CLAUDE.md` + `~/.claude/agents/` + `~/.claude/rules/` (preferência
cross-repo) e, no repo, `CLAUDE.local.md` gitignored (H2·F4/F11). Lido por último → **vence onde não colide
com managed/compliance**. Polimorfismo por dados no estilo chezmoi (`.chezmoidata`) para especializar sem
copiar (H3·F7). Único nível nativamente fraco (compartilhar entre worktrees) — mitigado por `@import
~/.claude/…` (H2·F6).

**Quem herda o quê / quem sobrepõe o quê / auditável:**

- **Herança compõe as 4 camadas simultaneamente** na leitura (framework+empresa+time+pessoa) — nenhuma
  branch (H1·veredito, H4·encaixe).
- **Governança de override é ORTOGONAL à herança** (H3·F13): override de camada inferior sobre item de
  camada superior **exige review do owner da superior** — `CODEOWNERS` por path (gerado da mesma SSOT,
  H3·F4) + branch protection + required-reviewer rulesets (GA 2026-02, H3·F13) + bypass-list. O piso da
  empresa é `managed` (inviolável por design). Onde há **política em conflito** (compliance vs preferência),
  reconciliação **explícita e versionada** estilo OPA-`roots`/KG-`SUPERSEDES` (H1·F12/H4·F5) — não
  "última-camada-vence silenciosa".
- **Trilha de auditoria** = **proveniência versionada por camada** (o resolver responde "qual camada
  contribuiu esta chave", análogo `--show-scope`, H1·F1/H3·F4) — complementa os logs nativos fracos do
  forge (H3·F13).
- **stage/prod** é ortogonal à hierarquia de escopo — resolve por `env`/managed (H2·F11) e pela cadeia
  `resolve-integration-branch.sh`, não é um nível de herança (H2·encaixe·5).

**Não-atrito:** cada peça é um mecanismo que o time do Grana.Ai já usaria (nx tags, CODEOWNERS, mise,
managed settings, `CLAUDE.md` por pacote). O Onion **segue a corrente** — orquestra veículos nativos numa
cascata ordenada com proveniência. A única peça nova é o **resolver/gerador de settings N-camadas** (por
causa de H2·F7) e a convenção do 4º nível (pessoa).

---

## Reuso das 4 bases (não reinventar)

**Base 1 — `resolve-integration-branch.sh` (cadeia de precedência).**
Hoje resolve **um campo** e **não reporta origem**. Generalizar para um **resolver N-camadas que emita
proveniência** (`--show-scope`-style), **espelhando a ordem nativa** em vez de inventar outra: `managed >
CLI > local > project > user` (config) e `group > org > default` (distribuição) — H2·F1/F10, H3·F10.
Git config (H1·F1) e ESLint-flat (H1·F8) provam que precedência explícita+inspecionável é o alvo de
qualidade. É o átomo do resolver de escopo.

**Base 2 — `vendor-branch.sh` 3-way → N-camadas.**
Hoje 2 camadas bilaterais (base-herdada vendor + override-local) por repo. Generalizar para **N camadas**,
com a **qualidade strategic-merge** de Kustomize (escalares substituem, mapas mesclam, listas por merge-key
— H1·F4). Aplicação-alvo: o `settings.json` que o nativo **não herda pela árvore** (H2·F7) — o Onion
compõe e materializa self-contained por diretório. Regra de conflito a codificar: **array-merge/scalar-win**
do próprio nativo (H2·F2) — mas **cuidado**: "arrays sempre mergeiam" é falso; só `permissions` e arrays
marcados (`claudeMdExcludes`, `allowedHttpHookUrls`) mergeiam, "most settings replace" (H1·F2, correção
adversarial). Reservar o **3-way de branch** só para o eixo VERSÃO (upgrade do core), não escopo (H1·F6).

**Base 3 — SUPERSEDES do KG (override de conhecimento versionado).**
É o **eixo ortogonal ao merge de arquivo**, agora com lastro de mercado + fonte primária: Zep/Graphiti
faz **rastreamento bitemporal** — "superseded facts are invalidated, not deleted", cada fato com valid-time
+ provenance-time (H4·F5). O `meta:kg` e o `vendor-branch` **não devem convergir** — são os dois eixos.
Para política em regulado, o conflito resolve-se por **aresta explícita** (OPA: "conflito → resolução
explícita pelo operador, não por ordem" — H1·F12), não por sobrescrita. A proveniência-por-camada cai de
graça do `provenance time`.

**Base 4 — camadas NATIVAS do Claude Code (hoje inexploradas).**
O maior ponto de alavanca não-atrito. **Cavalgar**, não construir paralelo: `managed ≈ empresa`,
`project ≈ time/repo`, `user ≈ pessoa`, `CLAUDE.md`/`skills`/`rules` por **subdiretório ≈ time/package
dentro do monorepo** (H2·F5/F9), `CLAUDE.local.md ≈ pessoa-no-repo`. `@import` (4 hops) = composição
explícita/proveniência por construção (H2·F6). Distribuição: **marketplace de org + override por grupo**
(Enterprise) com namespace de plugin = versão + proveniência (H2·F10). O `roles.yaml`/`resolve-role-bundle.sh`
tem **assentamento nativo direto** aqui: role→group→bundle ≡ resolução group>org>default (H2·F10/H3·F12);
verticais = **components/mixins** opt-in, eixo horizontal separado do escopo (H1·F5).

---

## Herança mediada por IA (SDAAL/KG)

A herança não-atrito do Onion vive em dois planos cognitivos, ambos com lastro de spec de fronteira:

**Polimorfismo SDAAL (base + context-local re-resolvido em runtime).** A mesma base (spec/doc/agente) é
**resolvida diferente** pelo contexto do escopo inferior. O Model Spec da OpenAI dá o vocabulário mais
fino (H4·F3): distingue **defaults sobreponíveis EXPLICITAMENTE** (override de arquivo/`vendor-branch`) de
**guidelines sobreponíveis IMPLICITAMENTE** por "contextual cues / user history". Isso mapeia exatamente
as 3 formas de herança que o Onion mistura:

1. **Inviolável** (managed/compliance) = **Root** — nunca sobreponível (H4·F2/F3; H2·F1/F3).
2. **Default explícito** (base do framework/time) = override **estrutural** por arquivo = `vendor-branch`
   N-ificado (Base 2).
3. **Guideline implícita** = o **`distilled`** de `roles.yaml`: **herança de DOUTRINA reescrita pelo
   contexto**, não de arquivo — o `*-context` local re-resolve o vertical. A pessoa/time **não edita o
   pai**; só adiciona contexto que re-resolve o *porquê* herdado (H4·F4, Constituição do Claude jan/2026:
   reason-based, "herda-se o porquê, o escopo inferior re-resolve o como"). É o análogo do chezmoi
   template + `.chezmoidata` (H3·F7): base = template, `*-context` = dado que re-renderiza.

Isto é **exatamente** a cascata cognitiva nativa (H4·F1): `CLAUDE.md`/rules/skills concatenados
amplo→específico, com **prioridade tipada** para o prune sob orçamento de contexto não descartar a camada
de compliance (H4·F12; `claudeMdExcludes` + managed-inviolável, H2·F9).

**SUPERSEDES do KG (conhecimento/verdade, eixo ortogonal).** Verdade nova **supera sem apagar**, bitemporal
(H4·F5). É como o conhecimento vivo do Grana.Ai (KB/`*-context`/KG de negócio e compliance) evolui: uma
nova regra regulatória **supera** a antiga com proveniência, sem 3-way-merge. O radar do `meta:kg`
(reconciliação conflict-aware) é o análogo da reconsolidação da literatura de memória de agente (H4·F11).
Se o conhecimento escalar além de markdown, **namespaces** por empresa/time/pessoa (isolamento forte) +
metadata (recorte fino), com **consulta em cascata** (pessoa→time→empresa→framework, primeiro match vence)
— mesmo padrão da cascata de config (H4·F10). *(Este último é direção, não slice imediato — ver gaps.)*

---

## Candidatos a 1º slice + o que é design/dogfood

**Slice 1 (recomendado) — Resolver de proveniência N-camadas + gerador de `settings.json` composto por
diretório.** É o **único gap de engenharia real** que os 4 streams convergem em apontar (H2·F7: settings não
herda pela árvore), e o de maior alavanca:
- **DESIGN/CONVENÇÃO** (não código novo): posicionar cada camada como `CLAUDE.md`/rules/skills/agentes no
  nível certo da árvore + escopos nativos — a **camada cognitiva já compõe sozinha**, é só convenção
  (managed=empresa, subdir=time, user/local=pessoa). Valida-se por **dogfood** (abrir o Claude Code no
  monorepo e observar a concatenação), não por engenharia.
- **ENGENHARIA** (o que construir): generalizar `resolve-integration-branch.sh` (Base 1) para caminhar
  `pessoa→time→empresa→framework`, mesclar (Base 2, strategic-merge type-aware) e **materializar o
  `settings.json` self-contained por diretório** com **proveniência por-chave** (`--show-scope` próprio).
  Gate mecânico estilo `.claude/validation/` (never-clobber por-chave, lint da cadeia).
- **DOGFOOD de campo:** o próprio Grana.Ai (adotante regulado já clonado) — testar modo-de-falha (override
  do time que apagaria agentes herdados; drift entre `settings.json` duplicados por diretório — H2·ressalva),
  não só happy-path.

**Slice 2 — Distribuição por plugin/grupo + fallback vendorizado.** Depende de Enterprise (override por
grupo) **e** do buraco do CLI (H2·F12, *not planned*) — por isso **vendorização (adopt) permanece o caminho
primário** e o plugin é aditivo. Menos urgente que o Slice 1 porque o modelo durável já existe.

**Slice 3 (design maior, não 1º) — SUPERSEDES bitemporal no `meta:kg`.** O KG já existe parcialmente; dar
semântica **bitemporal** (valid-time + provenance-time, H4·F5) é evolução de design, ortogonal à cascata de
arquivo. Não bloqueia os slices 1–2.

**Fora de escopo do 1º corte (direção, não slice):** namespaces de vetor para conhecimento escopado
(H4·F10) e memória de agente com controle de acesso (H4·F11) — só quando o conhecimento escalar além de
markdown.

---

## Confiança e gaps

**Confiança geral: ALTA.** Os 4 streams convergem sem divergência material no veredito de mecanismo
(cascata-nativa + merge-N-camadas + SUPERSEDES ortogonal; branches rejeitadas). H1/H2/H3 têm passe
adversarial formal (**38/38 confirmed**); H4 traz fonte primária por achado (specs OpenAI/Anthropic/MCP,
paper Zep/Graphiti) mas **sem passe adversarial formal** — tratar F10–F12 como materialidade média/baixa.

**Declarado ≠ verificado — correções que a síntese incorpora:**

- **"Achado central" do grounding (sub-repo scoping não existe em nenhum eixo) — PARCIALMENTE REFUTADO.**
  Verificado que **existe nativamente na camada COGNITIVA** (`CLAUDE.md`/skills/rules por diretório +
  `claudeMdExcludes` — H2·F5/H1·F3, `confirmed`). O gap real restringe-se a: (a) `settings.json` não herda
  pela árvore (H2·F7); (b) o 4º nível "pessoa-dentro-do-time" versionável/compartilhável (H2·F11); (c) um
  resolver que caminhe subdir→raiz mesclando `.claude` (H3·gap).
- **"Arrays fazem merge" (H1·F2/H2·F2) — SUPERGENERALIZAÇÃO corrigida.** A doc oficial diz "most settings
  replace, not merge"; só `permissions` e arrays explicitamente marcados (`claudeMdExcludes`,
  `allowedHttpHookUrls`) mesclam. **Load-bearing** para o design do merge de settings — não assumir union
  por padrão.
- **Enumeração managed-only (H2·F3) — levemente exagerada.** `availableModels`, `enforceAvailableModels` e
  `disableBypassPermissionsMode` **não** são estritamente só-managed. A tese (existe camada empresa-que-trava)
  permanece sólida; a lista não.
- **Per-group em server-managed settings — declarado por terceiro, VERIFICADO FALSO.** Blog de terceiro
  afirmava respeitar group membership; a doc primária diz "Per-group configurations are not yet supported"
  (H2·F11). Segmentação por grupo hoje existe **só para plugins** (H2·F10). **Não prometer** `settings.json`
  por time via server-managed.
- **Auto-install de plugin no CLI — VERIFICADO not-planned** (H2·F12, issue #45323 fechada). Atrito real
  para o regulado que roda no CLI → vendorização é o caminho durável.
- **nx `extends` em `project.json` — NÃO existe** (H3·F2, discussion aberta). O nível "time" é gap até no
  líder de mercado — oportunidade, não atraso.
- **Correções de atribuição de fonte (não de veracidade), a sanar antes de citar externamente:**
  H3·F11 e H1·F3 — a fusão de `CLAUDE.md`/`@import` está em `/docs/en/memory`, não `/docs/en/settings`;
  H3·F6 — `hasconfig:remote.*.url` (Git 2.36) citar git-scm.com; H1·F4 — merge-key type-aware vem da doc
  K8s SMP, não do `inlinePatch.md`; H1·F7/F9 e H3·F9/F12/F13 — sub-detalhes verdadeiros mas documentados
  em páginas companheiras.

**Gaps abertos a validar em dogfood (não resolvidos por pesquisa):**
1. `settings.json` self-contained por diretório pode gerar **drift/duplicação** — o gerador do Onion tem
   de ser a SSOT que recompõe (é o problema que Base 1+2 resolvem, mas precisa provar em campo).
2. O 4º nível (pessoa-dentro-do-time versionável) é o **único** nativamente fraco — convenção
   `members/<pessoa>` resolvida pelo Onion materializando em user/local é **hipótese de design**, não
   verificada.
3. Profundidade: mercado avisa "manter raso" (H4·F8) — 4 escopos é o limite; validar que o Onion não
   induz sub-níveis extras.
