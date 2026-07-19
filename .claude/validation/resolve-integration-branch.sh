#!/usr/bin/env bash
# =============================================================================
# resolve-integration-branch.sh — Resolve a BRANCH DE INTEGRAÇÃO de um repo Onion
#
# Propósito : Dar ao fluxo de PR (/engineer:pr) e ao /meta:adopt uma resposta
#             determinística e PORTÁVEL para "qual branch os PRs de evolução
#             devem mirar?". Resolve o gap do sinal de campo
#             docs/evolution/inbox/_processed/2026-06-18-adopt-gitflow-develop-branch-config.md:
#             antes, a escolha vivia só em `git config gitflow.branch.develop`,
#             que é LOCAL da máquina (não viaja no clone) E não era lida por
#             comando nenhum. Agora o SSOT durável é o `.onion-version`
#             (versionado, viaja no clone); git config é só conveniência local.
#
# Cadeia de resolução (primeiro que casar vence):
#   (1) campo `integration_branch:` em <REPO_DIR>/.claude/.onion-version  (SSOT versionado)
#   (2) git config --get gitflow.branch.develop                          (conveniência local)
#   (3) default detectado: `develop` se a branch existir; senão a branch
#       principal (gitflow.branch.master → origin/HEAD → `main`)
#
# Aviso anti-silêncio (STDERR): quando NÃO há sinal algum e cai no literal "main"
# (nem stamp/config/develop/origin-HEAD), emite um aviso no STDERR — o STDOUT segue
# só o nome da branch. Impede o "palpite silencioso" que resolveu 'main' num repo
# cuja integração era master/onion-adopt (sinal de campo 2026-07-14).
#
# Uso       : resolve-integration-branch.sh [REPO_DIR]   (default: .)
#             Emite o nome da branch em STDOUT. Exit 0 sempre (sempre há default).
#
# Determinístico, sem LLM. Consumido por /engineer:pr e /meta:adopt; coberto
# pelo lint-selftest.sh (modo resolve). Viaja para repos adotados via manifesto.
# =============================================================================
set -euo pipefail

REPO_DIR="${1:-.}"
STAMP="${REPO_DIR}/.claude/.onion-version"

# (1) SSOT versionado: campo integration_branch no stamp (viaja no clone).
#     gsub(/\r/) tolera stamp salvo com CRLF (editado à mão no Windows) — senão o nome da
#     branch viria com \r e a base do PR seria inválida. ($2 basta: branch names não têm espaço.)
if [ -f "${STAMP}" ]; then
  ib="$(awk '/^integration_branch:/{gsub(/\r/,"",$2); print $2; exit}' "${STAMP}")"
  if [ -n "${ib:-}" ]; then printf '%s\n' "${ib}"; exit 0; fi
fi

# (2) Fallback: git config local (conveniência; NÃO viaja no clone).
ib="$(git -C "${REPO_DIR}" config --get gitflow.branch.develop 2>/dev/null || true)"
if [ -n "${ib:-}" ]; then printf '%s\n' "${ib}"; exit 0; fi

# (3) Default detectado: develop se existir; senão a branch principal.
if git -C "${REPO_DIR}" show-ref --verify --quiet refs/heads/develop; then
  printf 'develop\n'; exit 0
fi
master="$(git -C "${REPO_DIR}" config --get gitflow.branch.master 2>/dev/null || true)"
if [ -z "${master:-}" ]; then
  master="$(git -C "${REPO_DIR}" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@' || true)"
fi
# (4) PALPITE CEGO: nenhum sinal (nem stamp/config/develop, nem origin/HEAD) → cai no literal "main".
#     Avisa no STDERR (o STDOUT segue SÓ o nome — BASE=$(...) intacto) para que o palpite deixe de ser
#     SILENCIOSO. Sinal de campo 2026-07-14: um repo cuja integração real era master/onion-adopt
#     resolveu "main" sem avisar. Só aqui: quando origin/HEAD dá a branch principal de verdade, o palpite é
#     confiável → sem ruído no caso comum (greenfield main).
if [ -z "${master:-}" ]; then
  {
    printf '⚠️  resolve-integration-branch: SEM sinal de branch de integração — usando o palpite cego "main".\n'
    printf '    (sem integration_branch no .onion-version, sem gitflow.branch.develop, sem branch develop, sem origin/HEAD).\n'
    printf '    Se a branch de integração NÃO for "main", grave o campo no SSOT versionado:\n'
    printf '      integration_branch: <sua-branch>   # em .claude/.onion-version   (ou passe --integration-branch no /meta:adopt)\n'
  } >&2
fi
printf '%s\n' "${master:-main}"
