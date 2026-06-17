# Integração Contínua (CI) — Workflows nativas do Onion

O Sistema Onion mantém **duas GitHub Actions nativas** que validam PRs que tocam o framework. Ambas são Claude-native (sem dependência de provedores externos).

## Workflows

| Workflow | Arquivo | Gatilho | O que faz | Secret |
|---|---|---|---|---|
| **Onion Artifact Linter** | `.github/workflows/onion-validate.yml` | PR tocando `.claude/**` ou `docs/meta-specs/**` | Linter **determinístico** (`.claude/validation/lint-artifacts.sh`): frontmatter, kebab-case, limites de linha, ausência de `gpt-4` em campo `model`, ausência de vaporware, proibição de agente fleet-orchestrator — **seguido** do auto-teste das guardas (`.claude/validation/lint-selftest.sh`) | nenhum |
| **Onion Code Review (Claude)** | `.github/workflows/onion-review.yml` | PR (`opened`/`synchronize`) | Revisão **semântica** via Claude (`sonnet-4-6`) aplicando a doutrina do `@metaspec-gate-keeper` contra `docs/meta-specs/` | `ANTHROPIC_API_KEY` |

## Camadas complementares

- **Determinística** (linter): sempre roda, sem secret — cobre estrutura, YAML e nomenclatura.
- **Auto-teste de guardas** (selftest): roda logo após o linter, no mesmo job, sem secret. Injeta fixtures conhecidas (`.claude/validation/fixtures/`) e confirma que cada guarda ainda reage — uma regra que silenciosamente parar de funcionar (regex quebrada, allowlist larga) passa a **falhar o CI** em vez de degradar em silêncio. Detalhes: [testing-validation-system.md](./testing-validation-system.md).
- **Semântica** (revisor Claude): roda quando `ANTHROPIC_API_KEY` está configurado como secret do repositório; degrada graciosamente (pula) se ausente.

## Hook local (pre-commit) — opt-in

Para pegar violações **HARD** antes do push (fail-fast em vez de descobrir no CI), há um hook versionado em `.githooks/pre-commit` que roda o mesmo linter determinístico. Ativação (uma vez por clone):

```bash
git config core.hooksPath .githooks
```

Bloqueia o commit só em violação HARD (SOFT não bloqueia). Para pular pontualmente: `git commit --no-verify`. Em projeto-alvo sem `.claude/validation/`, o hook não bloqueia (exit 0).

## Configuração do revisor Claude

1. `gh secret set ANTHROPIC_API_KEY` (ou Settings → Secrets and variables → Actions).
2. Instalar o GitHub App do Claude (`/install-github-app` no Claude Code, ou https://github.com/apps/claude).
3. A workflow `onion-review.yml` precisa estar **idêntica na branch e na `main`** — a action valida isso por segurança (no primeiro setup, o erro de validação na própria PR que adiciona a workflow é esperado).

> Localmente, a validação semântica também roda via `/meta:metaspec-validate` (orquestrado pelo `@metaspec-gate-keeper`).
