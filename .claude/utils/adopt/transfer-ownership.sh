#!/usr/bin/env bash
# ===========================================================================
# transfer-ownership.sh — TRANSIÇÃO 'transferir' (topologia): passa a POSSE de um repo do forge para
# outra conta (ex.: o maestro transfere ao cliente quando ele esta autonomo). Padrao da frota: comeca na
# conta do maestro (+ cliente colaborador) → no futuro TRANSFERE ao cliente (+ maestro colaborador).
#
# Efeito OUTWARD + IRREVERSIVEL-na-pratica (R15.3b): sem --confirm, DRY-RUN. O wizard confirma antes.
#
# ⚠️ Ressalvas (posse no GitHub e SINGULAR):
#   - o NOVO dono precisa ACEITAR a transferencia (e um convite a conta-destino).
#   - migra tudo (historico, issues, colaboradores); a URL antiga REDIRECIONA para a nova.
#   - o ex-dono NAO vira colaborador automatico — o novo dono o re-adiciona (invite-collaborator.sh).
#
# Uso : transfer-ownership.sh <owner/repo> <novo-owner> [--confirm]
# Exit: 0 = ok/dry-run · 2 = uso · 3 = gh ausente/nao-autenticado/falha
# ===========================================================================
set -euo pipefail

REPO=""; NEW_OWNER=""; CONFIRM=""
while [ "$#" -gt 0 ]; do case "$1" in
  --confirm) CONFIRM=1; shift ;;
  -*) echo "uso: transfer-ownership.sh <owner/repo> <novo-owner> [--confirm]" >&2; exit 2 ;;
  *)  if [ -z "${REPO}" ]; then REPO="$1"; elif [ -z "${NEW_OWNER}" ]; then NEW_OWNER="$1"; fi; shift ;;
esac; done
[ -n "${REPO}" ] && [ -n "${NEW_OWNER}" ] || { echo "ERRO: informe <owner/repo> e <novo-owner>." >&2; exit 2; }

if [ -z "${CONFIRM}" ]; then
  echo "DRY-RUN — transferir a POSSE de '${REPO}' para '${NEW_OWNER}'."
  echo "  ⚠️ ${NEW_OWNER} precisa ACEITAR. Migra historico/issues/colaboradores; a URL antiga redireciona."
  echo "  ⚠️ Posse e singular: voce DEIXA de ser dono. Para continuar com acesso, o novo dono te re-adiciona"
  echo "     como colaborador (invite-collaborator.sh ${NEW_OWNER}/$(basename "${REPO}") <voce>) apos o aceite."
  echo "  Para executar: rode de novo com --confirm."
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "ERRO: gh ausente — transfira pela UI (Settings → Transfer ownership)." >&2; exit 3; }
gh auth status >/dev/null 2>&1 || { echo "ERRO: gh nao autenticado (rode 'gh auth login')." >&2; exit 3; }

echo "Transferindo ${REPO} → ${NEW_OWNER}…"
if gh api -X POST "repos/${REPO}/transfer" -f new_owner="${NEW_OWNER}" >/dev/null 2>&1; then
  echo "✅ Transferencia solicitada. ${NEW_OWNER} precisa ACEITAR em github.com (notificacao/email)."
  echo "   Apos o aceite: novo repo = ${NEW_OWNER}/$(basename "${REPO}") (a URL antiga redireciona)."
else
  echo "ERRO: falha ao transferir (destino inexistente? sem permissao admin? destino ja tem repo homonimo?)." >&2
  exit 3
fi
