#!/usr/bin/env bash
# ===========================================================================
# topology-projection.sh — projeta as TRANSIÇÕES da topologia-SSOT para o wizard consumir.
#
# fonte≠derivação: a skill onion-wizard NÃO hand-lista os movimentos da família — LÊ daqui, e daqui
# projeta do KG único (docs/onion/graph/onion-family-topology-2026-07.kg.yaml). Se a topologia mudar
# (nova transição, uma gated abre), o wizard reflete SOZINHO — sem editar a skill. A REGRA 41 garante
# que cada transição ativa aponta a um procedimento real; este helper é o leitor dessa fonte.
#
# Saída: TSV, uma transição por linha —  <status>\t<id>\t<trace>\t<label>
#   status: confirmed (ativa, pode conduzir) | open (gated, "em breve" — não executa)
#   trace : o procedimento (o SCAFFOLD) que a skill roteia para executar
# Uso   : bash .claude/utils/wizard/topology-projection.sh
# Exit  : 0 = ok · 3 = KG ausente ou sem python+yaml (o wizard degrada: pede a transição à mão)
# ===========================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
KG="${REPO_ROOT}/docs/onion/graph/onion-family-topology-2026-07.kg.yaml"

[ -f "${KG}" ] || { echo "topology-projection: KG-topologia ausente (${KG})" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "topology-projection: python3+yaml ausente" >&2; exit 3; }

python3 - "${KG}" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
for n in (d.get('nodes') or []):
    nid = n.get('id', '')
    if not nid.startswith('TX_'):
        continue
    status = n.get('status', '?')
    trace  = n.get('trace', '')
    label  = (n.get('label', '') or '').replace('\t', ' ')
    print('\t'.join([status, nid, trace, label]))
PY
