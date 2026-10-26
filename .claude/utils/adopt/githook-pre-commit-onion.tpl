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
# >>> onion-hook-trampoline >>>
# TRAMPOLIM DE WORKTREE: com core.hooksPath ABSOLUTO (o Claude Code o grava ao criar worktree de
# agente), toda worktree rodaria o hook do checkout PRINCIPAL e um PR que muda este hook não seria
# provado por ele mesmo. Só age quando ESTE hook mora no `.githooks/` do checkout principal deste
# repo (identidade de diretório; hook em `.git/hooks`, husky ou diretório central não trampolina).
# Aí, se a árvore atual tem o MESMO hook, executável e de conteúdo diferente, ele assume com os
# mesmos argumentos e stdin. Árvore sem o hook: segue este (o gate nunca deixa de rodar). Hook da
# árvore presente e NÃO executável: FALHA FECHADO (revisão do adotante sge, 2026-10-26). Antes caía em
# silêncio no do principal: o hook sob teste não rodava, e o bit perdido chegava à main, onde o git
# IGNORA hook não executável e o gate inteiro some. Rodá-lo por `bash` esconderia o mesmo bit perdido.
# A variável guarda o alvo contra laço e é limpa logo abaixo, para não vazar a um git aninhado.
_onion_top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
_onion_cmn="$(CDPATH= cd "$(git rev-parse --git-common-dir 2>/dev/null || echo /nonexistent)" 2>/dev/null && cd .. && pwd || true)"
_onion_tt="${_onion_top}/.githooks/${0##*/}"
if [ -n "${_onion_top}" ] && [ -n "${_onion_cmn}" ] && [ "${0%/*}" -ef "${_onion_cmn}/.githooks" ] \
   && [ "${ONION_HOOK_TRAMPOLINED:-}" != "${_onion_tt}" ] && [ -f "${_onion_tt}" ] && ! [ "${_onion_tt}" -ef "$0" ]; then
  if ! [ -x "${_onion_tt}" ]; then
    echo "❌ ${0##*/} bloqueado: ${_onion_tt} existe e NÃO é executável — o git o ignoraria e o gate desta árvore não roda. Corrija: chmod +x '${_onion_tt}' (e commite o modo 100755)." >&2
    exit 1
  fi
  if ! cmp -s "${_onion_tt}" "$0"; then
    export ONION_HOOK_TRAMPOLINED="${_onion_tt}"
    exec "${_onion_tt}" "$@"
  fi
fi
unset _onion_top _onion_cmn _onion_tt ONION_HOOK_TRAMPOLINED
# <<< onion-hook-trampoline <<<
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
  # ⚠️ DANO CONSUMADO, medido por um adotante em 2026-10-02: esta linha matava o commit EM SILÊNCIO.
  # Sob `set -euo pipefail` (l.16), num repo com "lint-staged" no package.json, SEM node_modules e SEM
  # o campo `packageManager`, o 1º `grep` não casa e sai 1 — `pipefail` propaga, `set -e` mata o hook
  # NA ATRIBUIÇÃO, antes do `echo` do skip. Resultado: `git commit` sai 1 sem UMA palavra, logo depois
  # de o lint Onion imprimir `OK ✓`. Quem viu isso achou que o lint tinha falhado.
  #
  # ⚠️ E O CORE DECLAROU, ERRADO, QUE NÃO REPRODUZIA. A busca cobriu `*.sh` e o instalador — e a linha
  # vive NESTE `.tpl`. Procurar no caminho errado é não ter procurado, e o veredito errado já tinha
  # sido ENTREGUE ao adotante. Ele mediu de novo e corrigiu o core: `.tpl:16` e `.tpl:43`, presentes em
  # origin/main e no pin dele. Precedente: adotante como refutador do core.
  #
  # A cura é a da casa: captura, rc LIDO, e nenhum fechador precoce decidindo veredito.
  onion_pm=""
  if onion_pm_raw="$(grep -oE '"packageManager"[[:space:]]*:[[:space:]]*"[a-z]+' "${REPO_ROOT}/package.json" 2>/dev/null)"; then
    onion_pm="${onion_pm_raw##*\"}"
  fi
  if [ -n "${onion_pm}" ]; then onion_hint="rode '${onion_pm} install'"; else onion_hint="instale as dependências do projeto"; fi
  echo "⏭️  lint-staged configurado, mas node_modules ausente (worktree?) — pulando. ${onion_hint} p/ ativar."
fi
