#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ladder-integrity-check.sh — o GATE que torna a Automação Graduada mecanismo, não prosa.
#
# Doutrina: docs/knowledge-base/concepts/graduated-automation-ladder.md
#   "A automação se CONQUISTA por ação provada" (máxima do maestro, 2026-07-24).
# O gate garante que a escada NÃO DRIFTA: nenhuma classe de ação sobe de degrau
# (HUMANO → MONITORADO → DINÂMICO → AUTO) sem um GATE DE PROMOÇÃO declarado e
# ALCANÇÁVEL (promoted_by aponta para evidência que existe — um .kg.yaml, uma
# migalha, um ADR). É o irmão da catraca (REGRA 29/42) aplicado ao enforcement.
#
# Registry (SSOT do estado da escada): .claude/validation/automation-ladder-registry.txt
#   formato por linha:  <classe>|<degrau>|<promoted_by>
#   degrau ∈ HUMAN | MONITORED | DYNAMIC | AUTO   (HUMAN = piso; não exige prova)
#
# Nasce SILENCIOSO: hoje toda classe está em HUMAN → 0 violações. Só uma classe
# declarada ACIMA de HUMAN sem promoted_by alcançável reprova (HARD).
#
# Uso:   ladder-integrity-check.sh [<repo_root>] [--format text|tsv] [--summary]
#        ladder-integrity-check.sh --selftest
# Saída: text (default, pt-BR) | tsv (SEV\tTAG\tPATH\tMSG, para o lint).
# Exit:  0 = íntegra · 1 = drift · 2 = uso. Determinístico, CI-safe (só lê o repo).
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
FORMAT="text"

_rung_ord() { case "$1" in HUMAN) echo 0;; MONITORED) echo 1;; DYNAMIC) echo 2;; AUTO) echo 3;; *) echo -1;; esac; }

_emit() { # sev path msg
  if [ "${FORMAT}" = "tsv" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "ladder" "$2" "$3"
  else printf 'VIOLATION: %s: [ladder] %s\n' "$2" "$3"; fi
}

check_ladder() {
  local root="${1:-.}"
  local rel=".claude/validation/automation-ladder-registry.txt"
  local registry="${root}/${rel}"
  local hard=0 classes=0
  if [ ! -f "${registry}" ]; then
    [ "${FORMAT}" = "tsv" ] || echo "  (sem registry — escada não declarada; nasce silencioso)"
    return 0
  fi
  while IFS='|' read -r cls rung prom; do
    cls="$(echo "${cls}" | tr -d '[:space:]')"; [ -z "${cls}" ] && continue
    case "${cls}" in \#*) continue;; esac
    rung="$(echo "${rung}" | tr -d '[:space:]')"; prom="$(echo "${prom}" | tr -d '[:space:]')"
    classes=$((classes+1))
    local ord; ord="$(_rung_ord "${rung}")"
    if [ "${ord}" -lt 0 ]; then
      _emit HARD "${rel}" "classe '${cls}' declara degrau inválido '${rung}' (HUMAN|MONITORED|DYNAMIC|AUTO)"; hard=$((hard+1)); continue
    fi
    if [ "${ord}" -ge 1 ]; then
      if [ -z "${prom}" ] || [ "${prom}" = "-" ]; then
        _emit HARD "${rel}" "classe '${cls}' subiu para '${rung}' SEM gate de promoção (promoted_by vazio) — rung-jump sem ação provada"; hard=$((hard+1))
      elif [ ! -e "${root}/${prom}" ] && [ ! -e "${prom}" ]; then
        _emit HARD "${rel}" "classe '${cls}' em '${rung}' aponta promoted_by='${prom}' INALCANÇÁVEL — evidência de promoção não existe"; hard=$((hard+1))
      fi
    fi
  done < "${registry}"
  [ "${FORMAT}" = "tsv" ] || echo "  escada: ${classes} classe(s) declarada(s), ${hard} violação(ões) HARD"
  [ "${hard}" -eq 0 ] && return 0 || return 1
}

run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0; local reg="${tmp}/.claude/validation/automation-ladder-registry.txt"
  mkdir -p "${tmp}/.claude/validation"
  printf 'co-announce-generate|HUMAN|-\na2a-accept|HUMAN|-\n' > "${reg}"
  check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (i) tudo HUMAN passa" || { echo "  ✗ (i)"; fails=$((fails+1)); }
  printf 'forged|AUTO|-\n' > "${reg}"
  if check_ladder "${tmp}" >/dev/null 2>&1; then echo "  ✗ (ii) AUTO-sem-prova deveria REPROVAR"; fails=$((fails+1)); else echo "  ✅ (ii) AUTO sem gate reprova (severidade load-bearing)"; fi
  printf 'x|MONITORED|docs/nao-existe.kg.yaml\n' > "${reg}"
  if check_ladder "${tmp}" >/dev/null 2>&1; then echo "  ✗ (iii) promoted_by inalcançável deveria reprovar"; fails=$((fails+1)); else echo "  ✅ (iii) promoted_by inalcançável reprova"; fi
  printf 'x|MONITORED|.claude/validation/automation-ladder-registry.txt\n' > "${reg}"
  check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (iv) MONITORED com prova alcançável passa" || { echo "  ✗ (iv)"; fails=$((fails+1)); }
  rm -f "${reg}"; check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (v) sem registry nasce silencioso" || { echo "  ✗ (v)"; fails=$((fails+1)); }
  rm -rf "${tmp}"; echo "  selftest: $((5-fails))/5 verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}

_root="."
while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) run_selftest; exit $? ;;
    --format)   FORMAT="${2:-text}"; shift 2 ;;
    --summary)  shift ;;
    *)          _root="$1"; shift ;;
  esac
done
check_ladder "${_root}"
