#!/usr/bin/env bash
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
