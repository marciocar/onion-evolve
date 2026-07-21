#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NOTA DE FRONTEIRA (2026-07-21): este script valida o pin do STAMP
# (.claude/.onion-version) — se o commit existe e se o canário bate.
# Ele NÃO valida os pins gravados no histórico da branch onion/vendor.
# Esse era o buraco: medindo os 3 adotantes locais, DOIS tinham pin inválido
# carimbado no vendor ("vnextpin"; "2026-07-12" — uma data). O stamp estava
# `pin-ok` nos dois casos; o registro do vendor é que mentia, e o dano só
# aparecia semanas depois, quando o 3-way merge usava a base errada.
# A entrada agora é guardada em vendor-branch.sh (o pin entra provando ser
# commit). Para AUDITAR o passivo já gravado: `--audit-vendor <target> <source>`.
# ─────────────────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--audit-vendor" ]; then
  _T="${2:?uso: pin-integrity-check.sh --audit-vendor <target> <source>}"
  _S="${3:?uso: pin-integrity-check.sh --audit-vendor <target> <source>}"
  _bad=0; _ok=0
  while read -r _p; do
    [ -n "${_p}" ] || continue
    if git -C "${_S}" cat-file -e "${_p}^{commit}" 2>/dev/null; then _ok=$((_ok+1))
    else printf '  ✗ pin inválido no onion/vendor: %s\n' "${_p}"; _bad=$((_bad+1)); fi
  done < <(git -C "${_T}" log --format=%s onion/vendor 2>/dev/null \
           | sed -n 's/^chore(onion): \(update\|adopt\) to pin \(.*\)$/\2/p' | sort -u)
  printf '  %s pin(s) válido(s), %s inválido(s) em %s\n' "${_ok}" "${_bad}" "${_T}"
  [ "${_bad}" -eq 0 ] && exit 0 || exit 1
fi

# pin-integrity-check.sh — verifica se o pin (source_commit) do stamp de um adotante é CONFIÁVEL.
#
# O pin é HIPÓTESE, não fato: um restore manual pode carimbar um commit sem que os arquivos
# vendorizados correspondam a ele (incidente de campo 2026-06-30 — stamp apontava o HEAD do core,
# vendor era de 6 dias antes; o anúncio downstream "você já tem o fix" saiu falso; sinal
# docs/evolution/inbox/_processed/2026-07-02-sinal-lint-only-ausente-no-vendor.md).
#
# Roda na SESSÃO DO CORE (precisa da história git da fonte). Consumidor: /meta:adopt --update
# (guard pin-integrity) — pin não confiável desativa early-exit "Já atualizado" e delta.
#
# Uso:   pin-integrity-check.sh <source_root> <target_root>
# Saída: "pin-ok <sha>" | "pin-untrusted <motivo>"
# Exit:  0 = pin confiável · 1 = pin não confiável
set -euo pipefail

SOURCE_ROOT="${1:?uso: pin-integrity-check.sh <source_root> <target_root>}"
TARGET="${2:?uso: pin-integrity-check.sh <source_root> <target_root>}"
STAMP="$TARGET/.claude/.onion-version"
# Canário: arquivo vendorizado que muda com frequência no core — divergência dele delata o pin.
CANARY=".claude/validation/lint-artifacts.sh"

if [ ! -f "$STAMP" ]; then
  echo "pin-untrusted stamp-ausente"; exit 1
fi
PIN="$(awk '/^source_commit:/{print $2; exit}' "$STAMP")"

if [ -z "$PIN" ] || [ "$PIN" = "unknown" ]; then
  echo "pin-untrusted unknown"; exit 1
fi
if ! git -C "$SOURCE_ROOT" cat-file -e "${PIN}^{commit}" 2>/dev/null; then
  echo "pin-untrusted inexistente-na-historia ($PIN)"; exit 1
fi
if ! git -C "$SOURCE_ROOT" show "${PIN}:${CANARY}" 2>/dev/null | diff -q - "$TARGET/$CANARY" >/dev/null 2>&1; then
  echo "pin-untrusted canario-divergente ($PIN vs $CANARY)"; exit 1
fi
echo "pin-ok $PIN"
