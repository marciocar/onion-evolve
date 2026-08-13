---
title: "Development Workflow — Contributing (Sistema Onion core)"
date: 2026-08-13
---

# Development Workflow — Contribuindo com o Sistema Onion (core)

> **Camada 4** (Development Workflow Context) do technical-context, conforme
> [`technical-context-template.md`](../../../.claude/commands/common/templates/technical-context-template.md).
> Escopo: o **CORE** — o framework template em `.claude/` deste repo (`onion-evolve`), não um
> app com API. Não há seção "deployment de produção" no sentido convencional: "deploy" aqui é
> **merge na branch de integração/produção do próprio framework**, consumido por adotantes via
> `/meta:adopt`/`/meta:co-*`. Números de comandos/agentes/skills citados abaixo vêm da SSOT
> gerada [`docs/onion/inventory.md`](../../onion/inventory.md) (102 comandos, 51 agentes, 11 skills — nunca
> digitados à mão, regenerados por `/meta:inventory`).

---

## 1. Branch Strategy (GitFlow)

O core segue **GitFlow clássico**, com o motor canônico documentado em
[`docs/knowledge-base/frameworks/gitflow-patterns.md`](../../knowledge-base/frameworks/gitflow-patterns.md)
(1087 linhas — templates de setup, feature, release, hotfix, migração master→main, resolução de
conflitos, semver, changelog). Os comandos `/git:*` e `/engineer:*` **citam** essa KB em vez de
reimplementar a lógica ad-hoc (`gitflow-patterns.md:6-9`).

### Ponto de entrada único: `/git:flow`

`.claude/commands/git/flow.md` é o **dispatcher único** do ciclo de vida GitFlow — substituiu 7
shims antigos (`git/feature/start`, `git/release/finish`, etc.) por um comando arg-driven:

```bash
/git:flow feature start "user-auth"     # cria feature/user-auth + sessão
/git:flow feature publish               # push + review (forge)
/git:flow feature finish                # merge → develop + cleanup
/git:flow release start "minor"         # release/<versão> (semver auto-bump)
/git:flow release finish                # merge main+develop, tag, Release no host
/git:flow hotfix start "fix-pay"        # hotfix a partir de main + task urgente
/git:flow hotfix finish                 # dual-merge + tag + Release + CI
```
(`git/flow.md:29-36`)

Princípios (`git/flow.md:39-42`):
1. **Git local** (branch/checkout/merge/tag/**push**) = `git` direto, orientado pela KB — nunca
   passa por adapter.
2. **Host remoto** (PR/review/CI/Release) = sempre via o adapter **forge**
   (`.claude/utils/forge/interface.md`) — nunca `gh`/API em prosa.
3. **Task manager** (opcional) — se `TASK_MANAGER_PROVIDER != none`, via o adapter task-manager;
   roteamento/formatação por provider são do adapter, nunca reimplementados no comando.

### Matriz de proteção de branch

De `gitflow-patterns.md:1000-1006` (§Matriz de Branches Protegidas):

| Branch | Push direto | Merge permitido | Observação |
|--------|-------------|-----------------|------------|
| `main` | Bloqueado | Fast-forward apenas | Produção; entra só via release/hotfix |
| `master` | Bloqueado | Fast-forward apenas | Equivalente clássico de `main` |
| `develop` | Bloqueado | Fast-forward apenas | Integração; entra via PR |
| `feature/*` | Permitido | merge normal | Branch de trabalho |
| `hotfix/*`, `release/*` | Permitido | merge normal | Branches temporárias |

A enforcement "hard" (bloquear push) vive nas branch protection rules do host remoto, lidas via
`forge.validateRepo()` — a matriz acima é a **convenção local** que os comandos respeitam antes de
tentar qualquer operação (`gitflow-patterns.md:1008`).

> **Nota de design (gated)**: hoje o papel da branch é derivado do **nome literal**
> (regex `^(main|master|develop)$`). Um ADR interno (`onion-adr-branch-roles-sdaal-2026-07.md`,
> status `proposto`) propõe resolver o papel via SDAAL (`roleOf(branch)`) em vez de assumir pelo
> nome — cobre casos como branch de produção por-cliente que não casa o regex, ou um `develop` que
> na verdade é staging num adotante regulado (`gitflow-patterns.md:987-995`).

### Resolução da branch de integração (não hardcoded)

`git config gitflow.branch.develop` é **local da máquina** — não viaja no clone. Para que a base
dos PRs seja a mesma em qualquer máquina, o Onion resolve a branch de integração por uma cadeia
determinística exposta pelo helper `.claude/validation/resolve-integration-branch.sh`
(`gitflow-patterns.md:52-62`):

1. `.claude/.onion-version` campo `integration_branch` — SSOT **versionada** (viaja no clone),
   carimbada por `/meta:adopt --integration-branch <nome>`. Vence a cadeia.
2. `git config --get gitflow.branch.develop` — conveniência local.
3. Default detectado — `develop` se existir; senão a branch principal (`gitflow.branch.master` →
   `origin/HEAD` → `main`).

`/engineer:pr` consome esse helper explicitamente antes de abrir o PR:
```bash
BASE="$(bash .claude/validation/resolve-integration-branch.sh)"
```
(`.claude/commands/engineer/pr.md:35`)

### Prefixos de branch (não force `feature/`)

O GitFlow tem mais prefixos que `feature/*`: `docs/*`, `hotfix/*`, `release/*`, `fix/*`, `chore/*`.
Se a branch atual já tem um prefixo GitFlow válido, `/engineer:pr` trabalha nela; senão cria uma
cujo prefixo case com o tipo de mudança (docs-only → `docs/…`; correção → `fix/…`; feature →
`feature/…`) (`.claude/commands/engineer/pr.md:29-33`).

### Sync pós-merge

`/git:sync` segue a mesma Matriz + a §Estratégia de sync por contexto
(`gitflow-patterns.md:1010-1015`):

| Branch atual | Target | Estratégia |
|---|---|---|
| `feature/*` | `develop` | `feature-cleanup` (`git merge develop --no-edit` na feature) |
| `release/*` | `main` | `release-sync` (fast-forward) |
| `hotfix/*` | `main` | `hotfix-sync` (dual-merge) |
| `develop` | `main` | `protected-sync` (`git merge origin/main --ff-only`) |

Se o fast-forward falhar numa branch protegida, o padrão é **nunca forçar** — instrui o fluxo de
PR (`/engineer:pr`), que passa pelo adapter forge (`gitflow-patterns.md:1032-1034`).

---

## 2. O ciclo faseado `engineer/` (plan → pr-update)

Este é o workflow de engenharia **invariante** do framework (CLAUDE.md §Contexto do Projeto —
"não devem ser consolidados"), com 12 comandos em `.claude/commands/engineer/`:

```
/engineer:plan → /engineer:start → /engineer:work → /engineer:pre-pr → /engineer:pr → /engineer:pr-update
```
(fases explícitas em `.claude/commands/engineer/pr.md:16`: "fase 5 do workflow faseado de
engenharia (`plan → start → work → pre-pr → pr → pr-update`)")

- **`/engineer:plan`** — cria `plan.md` faseado em `.claude/sessions/<feature-slug>/`. Cada fase é
  um chunk auto-contido (100–300 linhas, ~2h de trabalho humano), com vocabulário de estado
  obrigatório `[DONE]`/`[ACTIVE]`/`[TODO]` — invariante: exatamente uma fase `[ACTIVE]`, igual a
  `STATE.md.NEXT.phase` (`engineer/plan.md:23-25`). Retomabilidade após interrupção é requisito de
  design, não acidente.
- **`/engineer:pre-pr`** — checklist antes do PR: valida critérios de aceitação (checkboxes da
  task), depois dispara **fan-out paralelo** de 4 agentes independentes — `branch-metaspec-checker`,
  `branch-code-reviewer`, `branch-documentation-writer`, `branch-test-planner` — e consolida num
  relatório único (fan-in) (`engineer/pre-pr.md:38-46`). Fallback sequencial se o substrato de
  paralelismo não estiver disponível (`common/prompts/orchestration-fallback.md`).
- **`/engineer:pr`** — abre o PR via adapter forge (nunca `gh` em prosa), resolve a base pela
  cadeia de integration branch, e assina o corpo do PR com a assinatura da família:
  `🧅 Orquestrado com [Onion](https://onionevolve.com)` (substitui o default do harness, "🤖
  Generated with Claude Code") (`engineer/pr.md:52-59`).
- Testes verdes são passo 1, obrigatório antes de qualquer commit (`engineer/pr.md:26`).
- Task manager: em cada fase relevante, `updateStatus`/tags via adapter, condicionado a
  `TASK_MANAGER_PROVIDER != none` — nunca chamado direto (`engineer/pr.md:31-33`).

---

## 3. Code Review

Duas camadas complementares e **desacopladas**:

### 3.1 Review determinístico (dogfood mecânico — CI)

`.github/workflows/onion-validate.yml`: roda em PRs que tocam `.claude/**`, `docs/meta-specs/**`,
`docs/design-context/**`, `plugins/**`, `docs/**` ou `CLAUDE.md`. Três steps sequenciais
(teto `timeout-minutes: 25`; **duração medida 2026-08-12 no CI: 15m29s** para o job inteiro —
run 31560719645):
1. `bash .claude/validation/lint-artifacts.sh` — linter determinístico (3279 linhas, 59 guardas
   `check_*`, sem LLM, grep/wc/find).
2. `bash .claude/validation/lint-selftest.sh` — self-test via fixtures (9610 linhas); **798 casos**
   na medição de 2026-08-12.

> ⚠️ **Este orçamento foi re-medido em 2026-08-13, e o anterior mentia com autoridade.** A redação
> antiga dizia "orçamento **medido** 2026-07-20: ~7,5min total, teto 15" com o lint em "2261
> linhas". Vivo: teto **25**, lint **3279** (+45%), selftest **9610**. Número apresentado como
> *medição* carrega autoridade que número solto não tem — o leitor não o questiona, e foi assim que
> ficou 3 semanas errado. **Não re-medi os tempos por step** (só o total do job, pelo CI); os
> `~21s`/`~6m59s` por step foram **removidos** em vez de atualizados por chute, porque tempo
> estimado apresentado como medido é a própria classe de defeito que esta nota registra.
3. `bash .claude/validation/lint-design-tokens.sh` — gate de design tokens (DTCG + refs + WCAG),
   requer `jq` (fail-loud no CI se ausente).

`lint-artifacts.sh` cobre (cabeçalho do arquivo, `lint-artifacts.sh:19-35`, lista parcial):
frontmatter obrigatório de agente/comando; proibição de `model: gpt-4`; limites de linha (agente
>1500, comando >800, ambos HARD); kebab-case de filenames (SOFT); inventário canônico
(`docs/onion/inventory.md`) em sincronia com o filesystem (HARD); contagens no `CLAUDE.md` em
sincronia com a SSOT (HARD); guarda SDAAL contra chamada direta a provider (`mcp_<provider>_*`,
`$CLICKUP_TASK_ID`) fora de adapters/especialistas (HARD); método `taskManager.*`/`forge.*` usado
pelo consumidor deve existir na interface (HARD).

Categorias de violação: **HARD** (bloqueia CI/merge) vs **SOFT** (aviso, não bloqueia)
(`lint-artifacts.sh:14-16`).

### 3.2 Review semântico (Claude — advisory)

`.github/workflows/onion-review.yml` ("Onion Code Review (Claude)"): dispara em
`pull_request: [opened, synchronize]`, roda `anthropics/claude-code-action` **pinado** em
`v1.0.171` (commit `e90deca4`) — não a tag móvel `@v1` — porque a `@v1` regrediu para 100% de crash
em 2026-07-14 (`onion-review.yml:36-41`). O prompt aplica a doutrina do `@metaspec-gate-keeper`
contra `docs/meta-specs/`.

**Semântica de vermelho/verde é contraintuitiva por design**: o job só fica vermelho quando o
revisor **crasha** (não roda) — nunca quando encontra violações.

> ⚠️ **Correção de 2026-08-07.** Este parágrafo afirmava que as violações *"viram comentários
> inline e o job sai verde"*. A segunda metade era **falsa desde sempre**, e a causa não era a que
> se supôs: **não faltava credencial** (a action faz OIDC→App token e o log da run confirma
> *"App token successfully obtained"*) — **faltava ferramenta**. O `claude_args` não declarava
> `--allowedTools`, então o servidor MCP de comentário nunca era instalado; o log mostra
> `permission_denials_count: 14` e `No buffered inline comments`. Medido: os PRs **#549 a #557**
> têm todos `comments=0` e `reviews=0`, a ~US$ 1,27 por PR.
>
> **O desenho mudou em vez de ligar o MCP:** o revisor agora **devolve** os achados como dado
> (`--json-schema`, fail-closed) e **o Onion posta**, pelo transporte `api` do adapter forge
> (`.claude/utils/forge/post-review-comment.sh`). Isso torna o posting **shell testável** —
> a ausência disso é o que manteve o defeito vivo por 15 commits.
>
> Até que um PR **posterior a este** produza comentário visível, trate "o revisor comenta" como
> **não-verificado**: um PR que edita o próprio workflow não mede o revisor (a action se auto-pula
> quando o arquivo difere da branch default).

`continue-on-error: true` está setado de propósito: reprovar por `is_error`
bloquearia o PR pelo crash do bot, sem informação sobre o código. O gate de qualidade duro é o
determinístico (§3.1); o semântico é **advisory-quando-roda** (`onion-review.yml:35-42`). Sem o
secret `ANTHROPIC_API_KEY`, o step é pulado — degrada gracioso.

**Checagem semântica arquitetural fora do CI**: validações de conformidade com meta-specs e
invariantes de framework não rodam automaticamente no CI — são locais, via
`/meta:metaspec-validate` orquestrado por `@metaspec-gate-keeper` (`onion-validate.yml`, step
final "Lembrete — checagens semânticas são locais").

---

## 4. Testes

Três comandos em `.claude/commands/test/` (unit, integration, e2e) — geram e executam testes com
detecção automática de framework (`.claude/commands/test/unit.md:2-4`):

- `/test:unit <file-path> [--generate]` — testes unitários com coverage; ferramentas permitidas:
  `npm`, `pnpm`, `pytest`, `go`, `cargo`, `mvn` (detecção multi-linguagem, `test/unit.md:6`).
- `/test:integration` — testes de integração.
- `/test:e2e` — testes end-to-end.

No fluxo `/engineer:pr`, testes verdes é o **passo 1 obrigatório** antes de qualquer commit/push
(`engineer/pr.md:26`); no `/engineer:pre-pr`, o agente `branch-test-planner` cobre "testes
finalizados para a branch" como parte do fan-out de 4 (§2 acima).

Para o **próprio core** (framework, não app com testes de negócio), o "teste" determinístico é o
gate de validação: `lint-artifacts.sh` + `lint-selftest.sh` (§3.1) — ver §6 (Dogfood) abaixo, que é
a doutrina que generaliza esse princípio.

---

## 5. Setup do Ambiente Local

### Instalação do pre-commit hook nativo (git hook, sem dependências)

O core usa **git hooks nativos** via `core.hooksPath`, não Husky (decisão registrada em
`docs/analysis/onion-adr-native-githooks-standard-2026-06.md`,
`.claude/utils/adopt/install-onion-githook.sh:12`). Ativação **opt-in**, uma vez por clone
(`.githooks/pre-commit:12-13`):

```bash
git config core.hooksPath .githooks
```

Desativar temporariamente um commit: `git commit --no-verify` (`.githooks/pre-commit:15`).

`.githooks/pre-commit` roda:
1. `.claude/validation/lint-artifacts.sh` — o mesmo linter determinístico do CI. Se ausente no repo
   (ex.: projeto-alvo sem `.claude/validation`), não bloqueia (`.githooks/pre-commit:22-30`).
2. `.claude/validation/lint-selftest.sh` — **condicional**: só roda quando o commit mexe em
   `.claude/validation/**` (~1min extra: monta sandbox copiando a árvore), evitando penalizar todo
   commit com o custo do self-test (`.githooks/pre-commit:32-45`).

### Provisionamento em adotantes

`.claude/utils/adopt/install-onion-githook.sh <dest-dir>` — usado por `/meta:adopt` (Fase 3 +
`--update`) para instalar o mesmo hook em repos adotados. Comportamento **never-clobber**
(idempotente): se já existe `pre-commit` diferente, grava sidecar `pre-commit.onion` para merge
manual em vez de sobrescrever; detecta Husky e avisa migração sem desinstalar; só seta
`core.hooksPath` se estiver UNSET (`install-onion-githook.sh:14-20,45-81`). Determinístico, sem
LLM; exercitado por `lint-selftest.sh` (`run_githook_selftests`) (`install-onion-githook.sh:29`).

### Inicialização de repositório (`/git:init`)

`/git:init` detecta automaticamente `main`/`master`, configura `develop` e os prefixos GitFlow
padrão (`feature/`, `release/`, `hotfix/`), seguindo `gitflow-patterns.md §Template 1` como fonte
única — dúvidas ad-hoc vão para o mentor `@gitflow-specialist` (não é dependência de runtime)
(`.claude/commands/git/init.md:35-37`).

### Comandos de warm-up

`/warm-up` (root) e `/engineer:warm-up` carregam contexto técnico — arquitetura, padrões de
código, comandos de desenvolvimento e frameworks técnicos — antes de iniciar trabalho.

---

## 6. Dogfood: o padrão-master de validação do core

O CLAUDE.md do repo declara a doutrina canônica (§"Evolução do Core — Dogfood é o padrão master",
`CLAUDE.md`): toda mudança no core se valida **rodando o artefato de verdade**, não só
plano/lint/spec. O gate mecânico (`.claude/validation/`: lint + selftest + inventory) é o **dogfood
determinístico**; para o resto, o artefato é invocado e observado.

A doutrina detalhada vive em
[`docs/knowledge-base/concepts/onion-dogfooding-doctrine.md`](../../knowledge-base/concepts/onion-dogfooding-doctrine.md),
que formaliza o **ciclo de investigação/auditoria** usado no core (relevante para quem contribui
com mudanças que tocam `.claude/validation/`, KGs de auditoria ou o comando `/meta:kg`):

```
KG-first (se houver .kg.yaml) → read(KG): o grafo é o SSOT de estado, ACIMA do git/memória
        ↓ drive-to-verify: claim PROD de alto impacto → cruzar contra o vivo antes de agir
        ↓ (agir)
        ↓ write(KG): o que o dogfood descobriu volta como nó/aresta (SUPPORTS/REFUTES/SUPERSEDES)
```
(`docs/knowledge-base/concepts/onion-dogfooding-doctrine.md:124-135`)

`read(KG)` deve vir **antes** de auditar (senão o sensor re-deriva o que a SSOT já sabia — falha
medida em campo ≥4× com o próprio autor da doutrina); `write(KG)` deve vir **depois** de dogfoodar
(senão o achado morre em prosa e não persiste). Sem as duas pernas, o ciclo é leitura, não runtime
— o par é **KG-first + drive-to-verify** (`onion-dogfooding-doctrine.md:140-142`).

Comando associado: `/meta:kg` (modela investigações/auditorias como Knowledge Graph SDAAL
`.kg.yaml`, roda o radar determinístico `kg-radar.sh`).

---

## 7. Inventário SSOT — regra para quem contribui

Qualquer mudança que crie/remova comando, agente, skill ou KB **deve** rodar
`/meta:inventory` (ou `bash .claude/validation/inventory.sh --markdown`) para regenerar
`docs/onion/inventory.md` antes de commitar — os números em `CLAUDE.md` e neste
technical-context **derivam** dessa SSOT gerada do filesystem, nunca são digitados à mão
(`docs/onion/inventory.md:1-5`; guardado por `lint-artifacts.sh` regras 8-9, HARD). Contrato de
contagem (`.claude/validation/inventory.sh:13-15`): "comando invocável" = `.md` em
`.claude/commands/` exceto `common/` e READMEs; "agente" = `.md` em `.claude/agents/` exceto
READMEs; "skill" = diretório em `.claude/skills/`; "KB" = `.md` em `docs/knowledge-base/` exceto
`index.md`.

---

## Fora de escopo neste arquivo

Este é o CORE (framework template em `.claude/`, não um app com API/backend). Não há seção de
"API Specification" (Layer 3 do template) nem "deployment de produção" no sentido de infra —
"deploy" do framework é a chegada de mudanças na branch de integração/produção do próprio repo,
consumida por adotantes via `/meta:adopt` e os fluxos de co-evolução (`/meta:co-announce`,
`/meta:co-deliver`, `/meta:co-relay`, `/meta:co-evolve`), que ficam fora do escopo deste arquivo
(pertencem à dimensão de federação/distribuição, não ao workflow interno de contribuição).
