---
title: 'ADR — unidade de troca do Onion: "vertical-skill" SDAAL empacotada como plugin Claude Code (marketplace + proveniência); monetização gated'
date: 2026-06-27
type: adr
status: aceito
decision-scope: distribution / exchange-unit / packaging
supersedes: none
extends: onion-distribution-strategy-2026-06.md
deciders: maestro + sessão de evolução
context_freshness: 2026-06-27
related:
  - onion-distribution-strategy-2026-06.md (veredito por camadas — este ADR executa a camada 1)
  - onion-adr-adopt-to-not-impose-2026-06.md (adopt sem impor — a camada 2 fica do consumidor)
  - ../sdaal/sdaal.md (SDAAL — a adaptação que torna a peça portável)
  - ../knowledge-base/concepts/multi-repo-federation.md (federação = governança por cima do transporte)
  - ../../.claude/commands/design/ (vertical Design — 1ª peça-prova)
  - ../../.claude-plugin/marketplace.json (o marketplace, materializado neste ciclo)
---

# ADR — unidade de troca do Onion: vertical-skill SDAAL via marketplace

> **Status: ACEITO** como decisão de direção. Executa a **camada 1** do `distribution-strategy`
> (que estava gated por apetite; apetite sinalizado pelo maestro em 2026-06-27). A parte de
> **monetização permanece GATED** — nomeada, não construída.

## Contexto

Pergunta do maestro: qual a melhor maneira de **trocar peças** do Onion (verticais, domínios,
metodologias) entre times — standalone ou em federação — usando o que é profissional/popular em jul/2026?
Vale "vender" pedaços? SDAAL + transformer seria o approach?

Diligência (3 Explore agents + WebSearch, jul/2026):

- **O mercado convergiu** para: **SKILL.md** (padrão aberto Anthropic, dez/2025; 16+ ferramentas) +
  **`gh skill`** (abr/2026; `search/install/pin/update/publish`, com **proveniência `repository`/`ref`/
  `tree_sha` no frontmatter** → change-detection content-addressed) + **marketplaces privados do Claude
  Code** (`.claude-plugin/marketplace.json` + `plugin.json`; org/Team/Enterprise puxando de repo GitHub
  privado, fev/2026). MCP registries maduros (~9,6k servers).
- **Vender** é real só em **escala enterprise/consultoria** (Salesforce AgentExchange ~US$800M ARR, split
  70-85%; *"metodologia vira produto, não hora de serviço"*) e **nascente/power-law p/ criador solo**
  (mediana < US$50-100/mês). → monetização = **upside futuro, não driver**.
- **O Onion já tinha o veredito** (`onion-distribution-strategy-2026-06.md`): híbrido por camadas — camada 1
  (`.claude/` execução) vai nativo; camadas 2 (spec-as-code) + 3 (co-evolução/federação) são o **moat**,
  sem equivalente nativo.

## Decisão

1. **Unidade de troca = "vertical-skill": uma vertical/domínio Onion empacotada como plugin Claude Code**
   (pasta com `.claude-plugin/plugin.json` + `commands/agents/skills/hooks/`), no padrão do ecossistema,
   com **proveniência** (`repository` + `ref` + `tree_sha`) para detecção content-addressed de divergência.

2. **Canal:** `onion-evolve` é o **marketplace** (`.claude-plugin/marketplace.json`). Times/federação
   instalam via marketplace **privado** (repo GitHub privado); standalone/cross-IDE via `gh skill`. Começa
   **privado** — publicação pública é decisão posterior.

3. **Separação de camadas preservada (o ponto-chave):** o plugin distribui **só a camada 1** (a
   *capacidade*: commands/agents/skills/hooks/SDAAL-utils da vertical). A **camada 2** (a SSOT
   spec-as-code, ex.: `docs/design-context/`) **NÃO** vai no plugin — fica do consumidor. `/meta:adopt`
   continua o canal das camadas 2+3.

4. **SDAAL é o que torna a peça portável e valiosa entre times heterogêneos.** Uma skill nua é instrução
   estática; uma vertical-skill com SDAAL carrega adapters provider-agnósticos e **auto-adapta ao stack do
   consumidor** (task-manager/forge/design dele), com o transformer interpretando os specs Markdown na
   fronteira (tese SDAAL: LLM=VM, Markdown=bytecode). **Vende-se capacidade adaptativa, não prompt.** Este
   é o diferencial vs uma skill comum de marketplace — e a resposta ao "usar SDAAL + transformer seria bom?":
   **é precisamente o approach certo**, e já é a arquitetura do Onion.

5. **Federação = governança por cima do transporte.** O marketplace **transporta** a peça; quando a peça
   tem interface quebrável entre repos, os contratos `/meta:federation-*` (ledger + tests/fixtures + veto)
   **controlam** a evolução. Marketplace e federação são camadas complementares, não concorrentes.

6. **Monetização = GATED/futuro.** Não construir infra de pagamento/licença/IP agora (nascente p/ solo;
   real só enterprise). A **proveniência + `tree_sha`** já dão a base técnica de IP/autoria quando reabrir.
   **Gatilho de reabrir:** 1º interesse comercial concreto **ou** 2º time externo pedindo uma peça.

## Consequências

- **+** Onion troca peças no padrão que o ecossistema já fala (SKILL.md/`gh skill`/marketplace) — descoberta,
  versão, cross-IDE, proveniência — sem abrir mão do moat (camadas 2+3).
- **+** O `tree_sha` resolve o gap de "content diverged" que o relay manual da co-evolução não tinha.
- **+** Caminho aberto p/ "vender verticais" sem investir cedo numa aposta nascente.
- **−** Mapear o layout-Onion (`.claude/commands/design/…`) p/ o layout-plugin
  (`commands/agents/skills/hooks`) gera um **artefato montado** (duplicação controlada, à la
  `docs/onion/inventory.md`): SSOT continua `.claude/`, o dir do plugin é **gerado** por script
  determinístico. Drift-guard estilo `check_inventory_sync` = follow-up.
- **−** Verticais command-based (Design) não têm SKILL.md p/ carimbar proveniência de frontmatter; a
  proveniência fica no nível do plugin (`plugin.json` version+repository + stamp `tree_sha`). Para peças
  skill-shaped, a convenção `gh skill` de frontmatter aplica direto.

## Não-decisões (fora de escopo)

- **Monetização / licença / pagamento** — gated (acima).
- **Migração de TODAS as verticais** — só após o protótipo Design provar em campo.
- **Marketplace público** — começa privado.
- **Substituir `/meta:adopt`** — não: adopt segue dono das camadas 2+3; o plugin cobre a 1.

## Prova (protótipo, mesmo ciclo) — ✅ FECHADO

Vertical **Design** empacotada como plugin `onion-design`:
- **Script de montagem determinístico** `.claude/utils/marketplace/assemble-design-plugin.sh` — assembla
  `plugins/onion-design/{commands,agents,utils,validation}` + `.claude-plugin/{plugin.json,provenance.json}`
  das fontes canônicas em `.claude/`. SSOT = `.claude/`; plugin = artefato gerado.
- **`marketplace.json`** na raiz (`onion-evolve` = marketplace privado), entrada `onion-design`.
- **Schema validado:** `plugin.json` com exatamente os 8 campos (additionalProperties OK), semver, author{name},
  version match marketplace↔plugin. JSON bem-formado nos 3 manifestos.
- **Proveniência content-addressed:** `repository` + `ref` + `tree_sha` (hash do ls-tree das fontes) —
  determinístico (2ª montagem no mesmo HEAD = mesmo `tree_sha`).
- **Dogfood de instalação simulada:** num consumidor temp, os componentes do plugin entregam `/design:*` +
  agentes; **`design-context/` (camada 2) NÃO veio** (separação de camadas confirmada); o gate WCAG viajou
  e **degradou gracioso** sem `design-context` — prova de "instala a capacidade, adapta/no-opa ao contexto
  do consumidor".
- **Gate verde:** `lint-artifacts` 0 HARD; `lint-selftest` 79/79 (5 guardas novas `assemble-plugin`).

### Generalização provada (2026-06-27, mesmo dia) — 2ª vertical

O assembler design-específico foi **generalizado** para `assemble-plugin.sh` (dirigido por manifesto
shell, dependency-free) + manifestos em `verticals/<plugin>.manifest.sh`. Prova de que o padrão vale
para N verticais sem duplicar o script:
- **`onion-design`** (manifesto retrofitado) — `tree_sha` **idêntico** ao da 1ª geração (generalização
  não alterou a saída).
- **`onion-compliance`** (manifesto novo) — **shape distinto**: 5 agentes (ISO 27001/22301, SOC2, PMBOK,
  security-information-master) + `build-compliance-docs`, **sem** SDAAL utils nem gate. O genérico cria só
  as pastas necessárias (compliance não tem `utils/`/`validation/`).
- Marketplace agora lista **2 plugins** (nomes únicos, versões batem). Dogfood: instalação simulada de
  compliance entrega agentes + command **sem vazar `compliance-context`** (camada 2). Selftest 81/81
  (cobre design **e** compliance, incl. manifesto inválido → exit 2).

→ Com 2 verticais provando o padrão, os follow-ups **path-portability** e **drift-guard** passam a valer
o investimento (antes era cedo, com 1 só).

### Path-portability ✅ FECHADO (follow-up resolvido)

A reescrita de paths foi implementada **manifesto-dirigida no assembler** (SSOT-core intacta; plugin =
artefato transformado):
- **Mapa derivado do manifesto:** refs a componentes BUNDLADOS (`UTILS`/`VALIDATION`/`TEMPLATES`) →
  `${CLAUDE_PLUGIN_ROOT}/...`. Cirúrgico: `docs/*-context/` (camada 2) e soft-deps
  (`@metaspec-gate-keeper`, `onion-orchestration`) **não** entram no mapa → ficam intactas.
- **Novo componente `TEMPLATES`:** bundla `compliance-context-template.md` → `templates/` + ref reescrita.
- **Scripts portáveis:** as cópias do plugin têm `PROJECT="${1:-$(pwd)}"` (default = cwd do consumidor);
  os scripts-core seguem `${REPO_ROOT}` (intactos).
- **Dogfood real:** num consumidor temp com `design-context` PRÓPRIO, o gate e o sink do PLUGIN rodaram
  (sem arg → `PROJECT=pwd`), validaram e geraram 29 CSS vars **do consumidor**; plugin self-contained
  (zero path absoluto do core). Design: 0 ref core-layout residual. Selftest **83/83** (guardas e2/e3 de
  portabilidade). Gate verde.
- ⚠️ **Caveat (issue upstream #9354):** `${CLAUDE_PLUGIN_ROOT}` em **markdown de comando** pode não
  substituir confiável — a reescrita é a forma portável best-effort; em conteúdo de agent + scripts
  funciona. Verificação viva (`/plugin install`) confirma o elo de command-markdown.

### Achado pré-existente — ✅ RESOLVIDO via orquestração (2026-06-27)

Os agentes de compliance citavam `compliance_iso27001_template.md`, `_iso22301_`, `_soc2_`, `_pmbok_` que
**não existiam no core** (refs penduradas). Resolvido por **orquestração** (`Workflow`, 4 workers-especialistas em
paralelo — 1 por framework, outputs disjuntos): cada especialista autorou seu template (392–557 linhas,
dialeto-puro/REGRA 13), gravado em `commands/common/templates/`. Agora: refs resolvem no core (arquivos
existem) e, no plugin, viram `${CLAUDE_PLUGIN_ROOT}/templates/` (via os 4 adicionados ao `TEMPLATES` do
manifesto + path-portability do #197). 0 ref core-layout residual no plugin compliance.

### Drift-guard — ✅ FECHADO (REGRA 19)

`check_plugins_sync` no `lint-artifacts.sh` [HARD]: cada `plugins/<name>` é regenerado da fonte e comparado
(diff `-x provenance.json` + `tree_sha`); drift (edição à mão OU fonte mudada sem regenerar) bloqueia merge.
`tree_sha` passou a ser **worktree-based** (não `ls-tree HEAD`) → consistente no pre-commit. Ignora
`ref`/`commit_date` (voláteis). Dogfood adversarial: adulterar→HARD, voláteis→ignorados, restaurar→0 HARD.
Selftest `run_plugins_sync_selftests` (em-sync + detecção + voláteis).

### Limitações honestas restantes (follow-ups)

1. **Drift-guard:** os `plugins/*` gerados são commitados; falta um lint estilo `check_inventory_sync` que
   rejeite divergência entre o gerado e a regeneração. Hoje protegido pela guarda de determinismo do selftest.
2. **Instalação viva:** `/plugin marketplace add` + `/plugin install` é interativo do Claude Code (não roda
   em bash) — passo de verificação do maestro (também valida o caveat #9354).
3. **Verticais command-based** (Design) não têm SKILL.md p/ proveniência de frontmatter; aqui ela vive no
   nível do plugin (`provenance.json`). Peças skill-shaped usam a convenção `gh skill` direto no frontmatter.
