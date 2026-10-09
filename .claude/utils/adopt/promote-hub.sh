#!/usr/bin/env bash
# =============================================================================
# promote-hub.sh — /meta:adopt --promote-hub: promove o repo ATUAL de adopted a hub (Camada 2).
#
# Uso : promote-hub.sh [<REPO>]        (default: o toplevel do diretório atual)
# rc  : 0 promovido (ou no-op: já é hub) · 1 recusado (core, branch dedicada impossível, gate recusou)
#
# Idempotente. NÃO copia nada — só re-carimba o papel e commita, numa BRANCH DEDICADA.
#
# ══ POR QUE É SCRIPT, E NÃO SNIPPET (F1 das portas, SAC-89, 2026-10-09) ══════════════════════════
# Até aqui isto era um bloco de prosa no adopt.md que commitava na branch que estivesse em HEAD — em
# geral a própria integração, sem PR. Mudar para branch dedicada pedia mais lógica (farol, worktree,
# retomada), e lógica em prosa só é testada por quem extrai e executa a prosa. Script tem bancada.
# Exercitado por lint-selftest.sh (run_adopt_robust_selftests, caso c6; run_role_promotion_selftests).
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "${REPO}" ] && git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: não é repositório git: '${REPO}'" >&2; exit 1; }
REPO="$(git -C "${REPO}" rev-parse --show-toplevel)"

ROLE_NOW="$(awk '/^role:/{print $2; exit}' "${REPO}/.claude/.onion-version" 2>/dev/null)"
[ -f "${REPO}/.claude/.onion-version" ] || ROLE_NOW=source   # sem stamp = a fonte (onion-version.sh)
case "${ROLE_NOW}" in
  source) echo "Abortar: o core (role: source) não se promove — já é autoridade máxima." >&2; exit 1 ;;
  hub)    echo "No-op: já é hub."; exit 0 ;;
  adopted|standalone|"") : ;;   # o caso a promover
  *) echo "Abortar: papel '${ROLE_NOW}' desconhecido no carimbo — não promovo o que não sei ler." >&2; exit 1 ;;
esac

# BRANCH DEDICADA, nunca a integração: o papel novo chega por PR, como qualquer mudança. Com farol
# vivo (a própria sessão conta) a branch nasce numa worktree irmã e o checkout fica intocado.
INTEG="$(bash "${REPO}/.claude/validation/resolve-integration-branch.sh" "${REPO}" 2>/dev/null)"
[ -n "${INTEG}" ] || INTEG="$(git -C "${REPO}" rev-parse --abbrev-ref HEAD)"
WORK="$(bash "${HERE}/dedicated-branch.sh" "${REPO}" chore/onion-promote-hub "${INTEG}")" || exit 1

# Re-carimba role: hub PRESERVANDO adopted_from/adopted_at/mode (write-stamp lê o stamp antigo).
# SEM --framework/--commit/--commit-date de PROPÓSITO: identidade derivada do repo é do ALVO, não do
# core — `--framework` carimbava o nome do repo do alvo e `--commit` um SHA fora da história do core.
# Promover papel não muda versão: o write-stamp herda os três do stamp.
bash "${HERE}/write-stamp.sh" "${WORK}" --role hub >/dev/null || { echo "ERRO: write-stamp recusou o carimbo de hub." >&2; exit 1; }
# REGRA 40: o stamp DEVE estar trackeado (force-add: é gitignored na herança da fonte).
# SEM --no-verify: o gate do repo roda neste commit (é a única checagem local antes do PR). Se ele
# recusar só por HARD que já existia, o --no-verify é legítimo DECLARADO no corpo do PR; calado, não.
git -C "${WORK}" add -f .claude/.onion-version
if ! git -C "${WORK}" diff --cached --quiet; then
  git -C "${WORK}" commit -q -m "chore(onion): promove a hub (role: hub) — autoridade de adoção local dos próprios projetos" \
    || { echo "⚠️  o GATE do repo recusou o commit em ${WORK} (chore/onion-promote-hub) — o carimbo segue aplicado, não commitado." >&2; exit 1; }
fi
echo "✅ Carimbo de HUB em chore/onion-promote-hub (${WORK}). Push + PR para ${INTEG} (merge commit);"
echo "   depois do merge este repo pode: /meta:adopt <projeto> e /meta:adopt --update <projeto>."
