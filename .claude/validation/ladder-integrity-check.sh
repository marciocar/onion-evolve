#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ladder-integrity-check.sh — o GATE que torna a Automação Graduada mecanismo, não prosa.
#
# Doutrina: docs/knowledge-base/concepts/graduated-automation-ladder.md
#   "A automação se CONQUISTA por ação provada" (máxima do maestro, 2026-07-24).
# O gate garante que a escada NÃO DRIFTA e que ela ATESTA a realidade medida:
# nenhuma classe reivindica um degrau que exige prova sem promoted_by ALCANÇÁVEL.
#
# Os 6 degraus (o espectro real, medido 2026-07-24):
#   HUMAN       — piso; propõe, humano decide cada. (sem prova)
#   STRUCTURAL  — auto-POR-CONSTRUÇÃO (derivação determinística, sempre segura). (exige prova: o porquê)
#   MONITORED   — roda sob observação; humano confere. (exige prova: track-record/evidência)
#   DYNAMIC     — auto dentro do escopo ganho. (exige prova)
#   AUTO        — auto-merge own-repo, ganho. (exige prova)
#   MOAT        — irreversível/repo-alheio → NUNCA auto. (sem prova; o extremo seguro)
# Regra: degrau que EXIGE prova sem promoted_by alcançável = HARD (rung-jump sem ação provada).
#
# Registry: .claude/validation/automation-ladder-registry.txt  (formato: <classe>|<degrau>|<promoted_by>)
# Uso:   ladder-integrity-check.sh [<repo_root>] [--format text|tsv] [--summary] | --selftest
# Exit:  0 = íntegra · 1 = drift · 2 = uso. Determinístico, CI-safe.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail
FORMAT="text"

# degraus que EXIGEM promoted_by alcançável (reivindicam autonomia/segurança que precisa de lastro)
_needs_proof() { case "$1" in STRUCTURAL|MONITORED|DYNAMIC|AUTO) return 0;; esac; return 1; }
_valid_rung()  { case "$1" in HUMAN|STRUCTURAL|MONITORED|DYNAMIC|AUTO|MOAT) return 0;; esac; return 1; }

_emit() { # sev path msg
  if [ "${FORMAT}" = "tsv" ]; then printf '%s\t%s\t%s\t%s\n' "$1" "ladder" "$2" "$3"
  else printf 'VIOLATION: %s: [ladder] %s\n' "$2" "$3"; fi
}

# Um promoted_by pode apontar EVIDÊNCIA core-privada (ex.: members.yaml, o diário) —
# ausente-por-desenho no adotante. A classe é doutrina HERDADA (o adotante não a
# promoveu; a prova vive core-side). Mesmo role-guard do _scan_relative_links: no
# adotante, evidência core-privada inalcançável NÃO é HARD; no core (role:source) é.
_core_private_prom() {
  case "$1" in
    docs/analysis/*|docs/onion/*|docs/evolution/*|docs/discussions/*) return 0 ;;
    docs/applying/*|docs/materials/*|docs/plans/*)                    return 0 ;;
    .claude/diary/*|.claude/sessions/*)                              return 0 ;;
  esac
  return 1
}

check_ladder() {
  local root="${1:-.}"
  local rel=".claude/validation/automation-ladder-registry.txt"
  local registry="${root}/${rel}"
  local hard=0 classes=0
  local adopted=""; grep -qE '^(role: (adopted|hub)|decoupled_from:)' "${root}/.claude/.onion-version" 2>/dev/null && adopted=1
  if [ ! -f "${registry}" ]; then
    [ "${FORMAT}" = "tsv" ] || echo "  (sem registry — escada não declarada; nasce silencioso)"
    return 0
  fi
  while IFS='|' read -r cls rung prom; do
    cls="$(echo "${cls}" | tr -d '[:space:]')"; [ -z "${cls}" ] && continue
    case "${cls}" in \#*) continue;; esac
    rung="$(echo "${rung}" | tr -d '[:space:]')"; prom="$(echo "${prom}" | tr -d '[:space:]')"
    classes=$((classes+1))
    if ! _valid_rung "${rung}"; then
      _emit HARD "${rel}" "classe '${cls}' declara degrau inválido '${rung}' (HUMAN|STRUCTURAL|MONITORED|DYNAMIC|AUTO|MOAT)"; hard=$((hard+1)); continue
    fi
    if _needs_proof "${rung}"; then
      if [ -z "${prom}" ] || [ "${prom}" = "-" ]; then
        _emit HARD "${rel}" "classe '${cls}' em '${rung}' SEM promoted_by — reivindica autonomia/estrutura sem lastro (rung-jump sem ação provada)"; hard=$((hard+1))
      elif [ ! -e "${root}/${prom}" ] && [ ! -e "${prom}" ]; then
        # Adotante + evidência core-privada = ausente-por-desenho → não é HARD (doutrina herdada).
        if [ -n "${adopted}" ] && _core_private_prom "${prom}"; then :; else
          _emit HARD "${rel}" "classe '${cls}' em '${rung}' aponta promoted_by='${prom}' INALCANÇÁVEL — evidência não existe"; hard=$((hard+1))
        fi
      fi
    fi
  done < "${registry}"
  [ "${FORMAT}" = "tsv" ] || echo "  escada: ${classes} classe(s) declarada(s), ${hard} violação(ões) HARD"
  [ "${hard}" -eq 0 ] && return 0 || return 1
}

run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0; local reg="${tmp}/.claude/validation/automation-ladder-registry.txt"
  mkdir -p "${tmp}/.claude/validation"
  # (i) HUMAN + MOAT (extremos seguros, sem prova) → passa
  printf 'a|HUMAN|-\nb|MOAT|-\n' > "${reg}"
  check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (i) HUMAN + MOAT (sem prova) passam" || { echo "  ✗ (i)"; fails=$((fails+1)); }
  # (ii) MUTATION — AUTO sem prova → REPROVA
  printf 'forged|AUTO|-\n' > "${reg}"
  if check_ladder "${tmp}" >/dev/null 2>&1; then echo "  ✗ (ii) AUTO-sem-prova deveria REPROVAR"; fails=$((fails+1)); else echo "  ✅ (ii) AUTO sem lastro reprova (severidade load-bearing)"; fi
  # (iii) STRUCTURAL sem prova → REPROVA (auto-por-construção também precisa apontar o porquê)
  printf 'x|STRUCTURAL|-\n' > "${reg}"
  if check_ladder "${tmp}" >/dev/null 2>&1; then echo "  ✗ (iii) STRUCTURAL-sem-prova deveria reprovar"; fails=$((fails+1)); else echo "  ✅ (iii) STRUCTURAL sem prova reprova"; fi
  # (iv) MONITORED com prova alcançável → passa
  printf 'x|MONITORED|.claude/validation/automation-ladder-registry.txt\n' > "${reg}"
  check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (iv) MONITORED com prova alcançável passa" || { echo "  ✗ (iv)"; fails=$((fails+1)); }
  # (v) degrau inválido → reprova
  printf 'x|SUPERAUTO|-\n' > "${reg}"
  if check_ladder "${tmp}" >/dev/null 2>&1; then echo "  ✗ (v) degrau inválido deveria reprovar"; fails=$((fails+1)); else echo "  ✅ (v) degrau inválido reprova"; fi
  # (vi) sem registry → silencioso
  rm -f "${reg}"; check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (vi) sem registry nasce silencioso" || { echo "  ✗ (vi)"; fails=$((fails+1)); }
  # (vii) role-guard: promoted_by CORE-PRIVADO inalcançável — no CORE reprova, no ADOTANTE passa.
  #       (o bug de campo que o lint de um adotante pegou: members.yaml não vendoriza.)
  printf 'regulated-adopter-correct-to-core|MONITORED|docs/evolution/federation/zzz-nonexistent.yaml\n' > "${reg}"
  printf 'framework: core\nrole: source\n' > "${tmp}/.claude/.onion-version"
  if check_ladder "${tmp}" >/dev/null 2>&1; then echo "  ✗ (vii-core) core deveria reprovar evidência core-privada inalcançável"; fails=$((fails+1)); else echo "  ✅ (vii-core) core reprova promoted_by core-privado inalcançável"; fi
  printf 'framework: x\nrole: adopted\n' > "${tmp}/.claude/.onion-version"
  check_ladder "${tmp}" >/dev/null 2>&1 && echo "  ✅ (vii-adotante) adotante tolera evidência core-privada herdada" || { echo "  ✗ (vii-adotante) adotante deveria tolerar core-privado ausente-por-desenho"; fails=$((fails+1)); }
  rm -rf "${tmp}"; echo "  selftest: $((8-fails))/8 verdes"
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
