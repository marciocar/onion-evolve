#!/usr/bin/env bash
# =============================================================================
# detect-transport.sh — resolve o TRANSPORTE de co-evolução p/ um membro (SDAAL federation-transport).
#
# F2.1 do roadmap de federação (RFC-0004). Instância determinística do detector SDAAL (irmão de
# forge/detector + resolve-integration-branch). Resolve QUAL adapter de transporte usar entre o core e um
# membro, sem o comando precisar saber o "como":
#     git-async (default) | local (carteiro same-machine) | a2a-live (GATED: endpoint vivo desde 2026-07-09, aceite humano)
#
# Precedência (idioma resolve-integration-branch):
#   1. env FEDERATION_TRANSPORT explícito (git-async|local|a2a-live|auto)
#   2. auto  → local se o membro tem local_path EXISTENTE nesta máquina (carteiro), senão git-async
#   3. default → git-async (sempre disponível; menor superfície de ataque — RFC-0004 §3)
# a2a-live NUNCA é auto-selecionado (gated): só via FEDERATION_TRANSPORT=a2a-live explícito, e avisa que é gated.
# ⚠️ Até 2026-10-15 este cabeçalho e o aviso diziam "stub, sem canal vivo": o endpoint está vivo desde
# 2026-07-09 (adapters/a2a-live.md, correção de 2026-08-30) e só o ACEITE segue humano.
#
# Uso : detect-transport.sh <member-id>   → imprime a via (git-async|local|a2a-live)
# Gracioso: membro/members.yaml ausente ou sem python+yaml → não checa same-machine → git-async. Determinístico.
# Exercitado por lint-selftest.sh (run_detect_transport_selftests).
# =============================================================================
set -uo pipefail

MEMBER="${1:-}"; [ -n "${MEMBER}" ] || { echo "uso: detect-transport.sh <member-id>" >&2; exit 2; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../../.." && pwd))"
MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"

KIND="${FEDERATION_TRANSPORT:-git-async}"

# valida o valor
case "${KIND}" in git-async|local|a2a-live|auto) ;; *)
  echo "ERRO: FEDERATION_TRANSPORT inválido: '${KIND}' (use git-async|local|a2a-live|auto)." >&2; exit 3 ;;
esac

# local_path do membro (python+yaml; gracioso)
_member_localpath() {
  [ -f "${MEMBERS}" ] || return 0
  command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 || return 0
  python3 - "${MEMBERS}" "${MEMBER}" <<'PY'
import sys, yaml
try: ms=(yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
except Exception: sys.exit(0)
for m in ms:
    if m.get('id')==sys.argv[2]:
        print(m.get('local_path','') or ''); break
PY
}

case "${KIND}" in
  auto)
    lp="$(_member_localpath)"
    if [ -n "${lp}" ] && [ -d "${lp}" ]; then echo "local"; else echo "git-async"; fi ;;
  a2a-live)
    echo "⚠️  a2a-live é GATED: o endpoint está vivo, mas todo sinal entra na fila e só vira inbox por ato humano (a2a-accept.sh). Diagnóstico: a2a-doctor.sh." >&2
    echo "a2a-live" ;;
  *) echo "${KIND}" ;;
esac
