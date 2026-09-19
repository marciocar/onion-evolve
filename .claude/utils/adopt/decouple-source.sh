#!/usr/bin/env bash
# ===========================================================================
# decouple-source.sh — TRANSIÇÃO 'desacoplar': um adotado/hub vira FONTE SOBERANA própria (own T0).
# Corta o adopted_from → decoupled_from; role: adopted|hub → source. A partir daqui o repo AUTORA o
# próprio framework (own /meta:evolve, create-*, adopt) e NÃO recebe mais --update do core — linhagem
# própria. "A fonte é soberana de quem a usa" no limite (o cliente owna o framework, não só os projetos).
#
# Efeito COMMITTADO + irreversível-na-doutrina (R15.3b): sem --confirm, DRY-RUN. O wizard confirma antes.
# Nota: a fonte-desacoplada CARREGA stamp (role: source + decoupled_from) — diferente do core original
# (que não tem stamp). Os role-guards e a REGRA 40 reconhecem decoupled_from (o repo veio da superfície
# vendorizada — não tem os docs core-only; skip dos links + stamp trackeado, como um adotante).
#
# Uso : decouple-source.sh [<repo-path>] [--confirm]   (default: repo atual)
# Exit: 0 = ok/dry-run · 1 = já é fonte · 2 = sem stamp/uso · 3 = git ausente
# ===========================================================================
set -euo pipefail

REPO=""; CONFIRM=""
while [ "$#" -gt 0 ]; do case "$1" in
  --confirm) CONFIRM=1; shift ;;
  -*) echo "uso: decouple-source.sh [<repo-path>] [--confirm]" >&2; exit 2 ;;
  *)  [ -z "${REPO}" ] && REPO="$1"; shift ;;
esac; done
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[ -n "${REPO}" ] && [ -d "${REPO}" ] || { echo "ERRO: repo inválido (rode dentro de um repo ou passe o path)." >&2; exit 2; }
STAMP="${REPO}/.claude/.onion-version"
[ -f "${STAMP}" ] || { echo "ERRO: sem .claude/.onion-version — só um repo ADOTADO (adopted/hub) desacopla; o core já é fonte." >&2; exit 2; }

field() { grep -m1 "^$1:" "${STAMP}" 2>/dev/null | sed "s/^$1:[[:space:]]*//" || true; }
ROLE="$(field role)"; OLD_FROM="$(field adopted_from)"; FW="$(field framework)"
case "${ROLE}" in
  source)      echo "Já é fonte (role: source) — nada a desacoplar." >&2; exit 1 ;;
  adopted|hub|standalone) : ;;   # `standalone` faltava: papel EMITIDO pelo write-stamp.sh:79 era tratado como 'inesperado' (6o sitio, achado 2026-09-18)
  *)           echo "ERRO: role inesperado no stamp: '${ROLE}'." >&2; exit 2 ;;
esac

if [ -z "${CONFIRM}" ]; then
  echo "DRY-RUN — desacoplar '${REPO}' (role: ${ROLE} → source)."
  echo "  Vira FONTE SOBERANA: autora o próprio framework (own evolve/create-*); NÃO recebe mais --update do core."
  echo "  decoupled_from: ${OLD_FROM:-<origem desconhecida>}  ·  irreversível-na-doutrina (corta a linhagem upstream)."
  echo "  Para executar: rode de novo com --confirm."
  exit 0
fi

command -v git >/dev/null 2>&1 || { echo "ERRO: git ausente." >&2; exit 3; }
local_commit="$(git -C "${REPO}" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
local_date="$(git -C "${REPO}" log -1 --format=%cd --date=short 2>/dev/null || date +%F)"
{
  printf 'framework: %s\n'          "${FW:-$(basename "${REPO}")}"
  printf 'source_commit: %s\n'      "${local_commit}"
  printf 'source_commit_date: %s\n' "${local_date}"
  printf 'role: source\n'
  [ -n "${OLD_FROM}" ] && printf 'decoupled_from: %s\n' "${OLD_FROM}"
  printf 'decoupled_at: %s\n'       "$(date +%F)"
} > "${STAMP}"
git -C "${REPO}" add -f .claude/.onion-version 2>/dev/null || true
git -C "${REPO}" commit -q -m "chore(onion): desacopla — vira fonte soberana (role: source, linhagem própria)" --no-verify 2>/dev/null || true
echo "✅ Desacoplado. '${REPO}' agora é FONTE SOBERANA (role: source, decoupled_from: ${OLD_FROM:-—})."
echo "   Autora o próprio framework; sem --update do core. O stamp fica trackeado (guardado pela REGRA 40)."
