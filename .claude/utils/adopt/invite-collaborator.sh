#!/usr/bin/env bash
# ===========================================================================
# invite-collaborator.sh — TRANSIÇÃO 'convidar' (topologia): adiciona um cliente/par como colaborador
# de um repo do forge. É o passo do onboarding de um adotante (ex.: o maestro convida o cliente ao repo
# que criou p/ ele) — hoje o padrao da frota: repo na conta do maestro + o adotante como colaborador,
# com transferencia futura (ver transfer-ownership.sh).
#
# Efeito OUTWARD (R15.3b): sem --confirm, faz DRY-RUN (mostra o que fara, nao toca em nada). O wizard
# (onion-wizard) roda o dry-run, confirma via AskUserQuestion, e so entao chama com --confirm.
#
# Uso : invite-collaborator.sh <owner/repo> <github-user> [--permission pull|push|admin] [--confirm]
#         --permission: default push (write). --confirm: executa de fato (senao so mostra).
# Exit: 0 = ok/dry-run · 2 = uso incorreto · 3 = gh ausente/nao-autenticado
# ===========================================================================
set -euo pipefail

REPO=""; USER=""; PERM="push"; CONFIRM=""
while [ "$#" -gt 0 ]; do case "$1" in
  --permission) PERM="${2:-push}"; shift 2 ;;
  --confirm)    CONFIRM=1; shift ;;
  -*) echo "uso: invite-collaborator.sh <owner/repo> <user> [--permission pull|push|admin] [--confirm]" >&2; exit 2 ;;
  *)  if [ -z "${REPO}" ]; then REPO="$1"; elif [ -z "${USER}" ]; then USER="$1"; fi; shift ;;
esac; done
[ -n "${REPO}" ] && [ -n "${USER}" ] || { echo "ERRO: informe <owner/repo> e <github-user>." >&2; exit 2; }
case "${PERM}" in pull|push|admin|maintain|triage) : ;; *) echo "ERRO: --permission invalido: '${PERM}'." >&2; exit 2 ;; esac

if [ -z "${CONFIRM}" ]; then
  echo "DRY-RUN — convidar '${USER}' como colaborador de '${REPO}' (permissao: ${PERM})."
  echo "  Efeito: um convite e enviado; ${USER} precisa ACEITAR (nada acontece sem o aceite dele)."
  echo "  Para executar: rode de novo com --confirm."
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "ERRO: gh (GitHub CLI) ausente — instale ou convide pela UI do GitHub." >&2; exit 3; }
gh auth status >/dev/null 2>&1 || { echo "ERRO: gh nao autenticado (rode 'gh auth login')." >&2; exit 3; }

echo "Convidando ${USER} para ${REPO} (permissao: ${PERM})…"
if gh api -X PUT "repos/${REPO}/collaborators/${USER}" -f permission="${PERM}" >/dev/null 2>&1; then
  echo "✅ Convite enviado a ${USER} (${PERM}) em ${REPO}. Ele precisa aceitar em github.com/${REPO}/invitations."
else
  echo "ERRO: falha ao convidar (usuario inexistente? sem permissao no repo? ja e colaborador?)." >&2
  exit 3
fi
