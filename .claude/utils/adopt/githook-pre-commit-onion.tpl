#!/usr/bin/env bash
# =============================================================================
# Onion — pre-commit hook NATIVO (provisionado por /meta:adopt)
# -----------------------------------------------------------------------------
# Hook git nativo (SEM husky/lefthook): registrado via `core.hooksPath .githooks`.
# Mecanismo dependency-free; degrada GRACIOSO quando faltam ferramentas (ex.:
# worktree sem node_modules) — pula a etapa em vez de explodir com ENOENT.
# Espelha o padrão do próprio core Onion (.githooks/pre-commit).
# Doutrina: ../../../docs/knowledge-base/decisions/onion-adr-native-githooks-standard-2026-06.md
#
# Ordem: (1) lint Onion determinístico (se presente) → (2) lint-staged do projeto
# (se presente E node_modules presente). Cada etapa ausente = skip gracioso.
#
# Pular um commit pontual: git commit --no-verify
# =============================================================================
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# (1) Lint Onion (mesmo do CI). Ausente (projeto sem .claude/validation) → não bloqueia.
LINT="${REPO_ROOT}/.claude/validation/lint-artifacts.sh"
if [ -f "${LINT}" ]; then
  echo "🧅 Onion pre-commit — rodando lint determinístico…"
  if ! bash "${LINT}"; then
    echo ""
    echo "❌ Commit bloqueado: violação(ões) HARD acima. Corrija ou use 'git commit --no-verify'."
    exit 1
  fi
fi

# (2) lint-staged do projeto (eslint/prettier nos arquivos staged). WORKTREE-PROOF:
#     só roda se node_modules + binário existem (senão skip gracioso, NÃO ENOENT).
if [ -x "${REPO_ROOT}/node_modules/.bin/lint-staged" ]; then
  echo "🧹 pre-commit — lint-staged…"
  if ! ( cd "${REPO_ROOT}" && node_modules/.bin/lint-staged ); then
    echo ""
    echo "❌ Commit bloqueado: lint-staged falhou acima. Corrija ou use 'git commit --no-verify'."
    exit 1
  fi
elif [ -f "${REPO_ROOT}/.lintstagedrc.js" ] || grep -q '"lint-staged"' "${REPO_ROOT}/package.json" 2>/dev/null; then
  # Package manager do ALVO, não chute (sinal de campo 2026-07-25): o hook instruía 'pnpm install' num
  # repo bun-only (packageManager: bun, engines pnpm >=999). Lê o campo packageManager; senão, agnóstico.
  onion_pm="$(grep -oE '"packageManager"[[:space:]]*:[[:space:]]*"[a-z]+' "${REPO_ROOT}/package.json" 2>/dev/null | grep -oE '[a-z]+$' | tail -1)"
  if [ -n "${onion_pm}" ]; then onion_hint="rode '${onion_pm} install'"; else onion_hint="instale as dependências do projeto"; fi
  echo "⏭️  lint-staged configurado, mas node_modules ausente (worktree?) — pulando. ${onion_hint} p/ ativar."
fi
