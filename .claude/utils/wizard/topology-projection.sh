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
# Uso   : bash .claude/utils/wizard/topology-projection.sh [--roles|--authorities] [--role <papel>]
# Exit  : 0 = ok · 3 = KG ausente ou sem python+yaml (a skill degrada: pede/ensina à mão)
#
# ⚠️ SENSÍVEL AO PAPEL desde 2026-10-10 (F2 das portas, matriz D_MATRIZ_DE_PORTAS_2026_10): numa porta
# SEM adoção nem federação (standalone, plugins, mini) as transições cujo procedimento é de adoção ou
# federação NÃO são projetadas — o motor delas não viaja para esses papéis, e o wizard ofereceria um
# movimento que não roda. O papel vem do carimbo (`.claude/.onion-version`, campo `role:`); sem carimbo
# o repo é o core (`source`). `--role` sobrescreve, para teste. O corte é pelo TRACE da transição, não
# pelo nome dela: transição nova de adoção amanhã sai sozinha, se o procedimento morar nos prefixos.
# ===========================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
KG="${REPO_ROOT}/docs/onion/graph/onion-family-topology-2026-07.kg.yaml"
MODE="transitions"; ROLE_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --roles|--authorities) MODE="$1"; shift ;;
    --role) ROLE_OVERRIDE="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
ROLE="${ROLE_OVERRIDE}"
if [ -z "${ROLE}" ] && [ -f "${REPO_ROOT}/.claude/.onion-version" ]; then
  ROLE="$(awk '/^role:/{print $2; exit}' "${REPO_ROOT}/.claude/.onion-version" 2>/dev/null || true)"
fi
: "${ROLE:=source}"

[ -f "${KG}" ] || { echo "topology-projection: KG-topologia ausente (${KG})" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "topology-projection: python3+yaml ausente" >&2; exit 3; }

python3 - "${KG}" "${MODE}" "${ROLE}" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
mode, role = sys.argv[2], sys.argv[3]
# Papéis sem adoção nem federação, e os prefixos do procedimento que eles NÃO recebem (os mesmos
# que o vendor-manifest.sh corta desses papéis, mais os comandos dos conjuntos adoption/federation).
NO_ADOPTION = {"standalone", "plugins", "mini"}
CUT = (".claude/commands/meta/adopt.md", ".claude/commands/meta/federation-", ".claude/commands/meta/co-",
       ".claude/utils/adopt/", ".claude/utils/co-evolution/", ".claude/utils/federation-transport/")
dropped = []
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
            tr = n.get('trace', '') or ''
            if role in NO_ADOPTION and tr.startswith(CUT):
                dropped.append(nid)
                continue
            print('\t'.join([status, nid, tr, label]))
if dropped:
    sys.stderr.write("topology-projection: papel '%s' nao recebe adocao nem federacao; %d transicao(oes) nao projetada(s): %s\n"
                     % (role, len(dropped), " ".join(dropped)))
PY
