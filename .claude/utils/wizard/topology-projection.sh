#!/usr/bin/env bash
# ===========================================================================
# topology-projection.sh — projeta as TRANSIÇÕES da topologia-SSOT para o wizard consumir.
#
# fonte≠derivação: a skill onion-wizard NÃO hand-lista os movimentos da família — LÊ daqui, e daqui
# projeta do KG único (docs/onion/graph/onion-family-topology-2026-07.kg.yaml). Se a topologia mudar
# (nova transição, uma gated abre), o wizard reflete SOZINHO — sem editar a skill. A REGRA 41 garante
# que cada transição ativa aponta a um procedimento real; este helper é o leitor dessa fonte.
#
# Consumido por DUAS faces da Condução (ambas projetam da MESMA fonte — fonte≠derivação):
#   - onion-wizard (ajuda a FAZER): as TRANSIÇÕES (default).
#   - onion-onboarding (ajuda a CONHECER): os PAPÉIS (--roles) e as AUTORIDADES (--authorities).
#
# Saída (TSV, uma por linha):
#   default       : <status>\t<id>\t<trace>\t<label>   — transições (TX_*); confirmed=ativa, open=gated
#   --roles       : <status>\t<id>\t<label>            — papéis de REPO (ROLE_*); os tiers da família
#   --authorities : <status>\t<id>\t<label>            — autoridades de PESSOA (AUTH_*); ex.: colaborador visitante
# Uso   : bash .claude/utils/wizard/topology-projection.sh [--roles|--authorities]
# Exit  : 0 = ok · 3 = KG ausente ou sem python+yaml (a skill degrada: pede/ensina à mão)
# ===========================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
KG="${REPO_ROOT}/docs/onion/graph/onion-family-topology-2026-07.kg.yaml"
MODE="${1:-transitions}"

[ -f "${KG}" ] || { echo "topology-projection: KG-topologia ausente (${KG})" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "topology-projection: python3+yaml ausente" >&2; exit 3; }

python3 - "${KG}" "${MODE}" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
mode = sys.argv[2]
for n in (d.get('nodes') or []):
    nid = n.get('id', '')
    status = n.get('status', '?')
    label = (n.get('label', '') or '').replace('\t', ' ')
    if mode == '--roles':
        if nid.startswith('ROLE_'):
            print('\t'.join([status, nid, label]))
    elif mode == '--authorities':
        if nid.startswith('AUTH_'):
            print('\t'.join([status, nid, label]))
    else:  # transitions (default)
        if nid.startswith('TX_'):
            print('\t'.join([status, nid, n.get('trace', ''), label]))
PY
