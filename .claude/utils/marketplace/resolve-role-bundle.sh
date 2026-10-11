#!/usr/bin/env bash
# resolve-role-bundle.sh — resolve o bundle de verticais (plugins) de um papel.
# Lê o mapa role→bundle (roles.yaml) e imprime os verticais que o papel instala.
#
# Uso : resolve-role-bundle.sh <role> [--with-optional] [--tools [--kind door|adoption]] [--allowlist|--overlays|--known-absent] [roles.yaml]
#         <role>          = source | hub | standalone | plugins | consumer | mini | distilled
#         --with-optional = inclui os verticais opcionais (default: só os base)
#         --tools         = emite os WORK_TOOLS do papel (comandos de commands/meta/), não os verticais
#                           (resolve roles.<role>.work_tools → a UNIÃO dos work_tool_sets nomeados; aceita
#                           um nome ou uma lista de nomes; none/tbd = vazio)
#         --kind adoption = com --tools, o DESTINO é um projeto ADOTADO (carimbo sem `kind: door`): soma
#                           roles.<role>.adoption_keeps, os comandos que o papel de ADOÇÃO mantém e a PORTA
#                           do mesmo papel não leva (decisão do maestro, 2026-10-11: o standalone adotado
#                           mantém co-relay e co-evolve). `door` ou ausente = o conjunto da porta.
#         --allowlist     = emite a ALLOWLIST do papel (só o mini a declara): um caminho relativo a
#                           .claude/ por linha (diretório termina em `/`). Papel sem allowlist → vazio.
#         --overlays      = emite os OVERLAYS da allowlist (F5 das portas): "destino<TAB>fonte" por linha,
#                           os dois relativos à RAIZ do repo — arquivos próprios da porta (README, CLAUDE.md,
#                           skill simplificada) que substituem ou somam ao que o manifesto leva.
#         --known-absent  = emite as AUSÊNCIAS DECLARADAS da allowlist: "citação<TAB>porquê" por linha —
#                           o que os arquivos da porta citam e ela deliberadamente não leva.
# Saída: um vertical (ou tool, ou caminho) por linha (ordenado). Papel desconhecido → exit 2. Vazio → ok.
#
# Determinístico. Consome roles.yaml (SSOT do escopo por papel). Não confundir com o trust model.
# ⚠️ `work_tools` virou LISTA em 2026-10-10 (F2 das portas, SAC-91): a matriz separou `full` de
# `meta_factory`, `federation` e `adoption`, e um papel recebe a união dos conjuntos que nomeia. A forma
# escalar (`work_tools: full`) segue aceita, para um roles.yaml antigo vendorizado num adotante.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROLE="${1:-}"
WITH_OPT=0
MODE="verticals"
ROLES="${SCRIPT_DIR}/roles.yaml"
KIND=""
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --with-optional) WITH_OPT=1 ;;
    --tools) MODE="tools" ;;
    --allowlist) MODE="allowlist" ;;
    --overlays) MODE="overlays" ;;
    --known-absent) MODE="known_absent" ;;
    --kind) [ $# -ge 2 ] || { echo "ERRO: --kind exige um valor (door|adoption)" >&2; exit 2; }
            KIND="$2"; shift ;;
    *) [ -f "$1" ] && ROLES="$1" ;;
  esac
  shift
done
case "${KIND}" in ""|door|adoption) : ;; *) echo "ERRO: --kind desconhecido: '${KIND}' (door|adoption)" >&2; exit 2 ;; esac

[ -n "${ROLE}" ] || { echo "ERRO: uso: resolve-role-bundle.sh <role> [--with-optional|--tools|--allowlist]" >&2; exit 2; }
[ -f "${ROLES}" ] || { echo "ERRO: roles.yaml não encontrado: ${ROLES}" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "ERRO: python3 necessário" >&2; exit 2; }

python3 - "${ROLES}" "${ROLE}" "${WITH_OPT}" "${MODE}" "${KIND}" <<'PY'
import sys, yaml
roles_file, role, with_opt, mode, kind = sys.argv[1], sys.argv[2], sys.argv[3] == "1", sys.argv[4], sys.argv[5]
d = yaml.safe_load(open(roles_file)) or {}
roles = d.get("roles") or {}
if role not in roles:
    sys.stderr.write("ERRO: papel desconhecido: %s (validos: %s)\n" % (role, ", ".join(sorted(roles))))
    sys.exit(2)
r = roles[role] or {}
if mode == "tools":
    sets = d.get("work_tool_sets") or {}
    wt = r.get("work_tools")
    names = wt if isinstance(wt, list) else ([wt] if wt not in (None, "none", "tbd") else [])
    ts = []
    for n in names:
        if n in (None, "none", "tbd"):
            continue
        if n not in sets:
            sys.stderr.write("ERRO: papel %s nomeia work_tool_set inexistente: %s\n" % (role, n))
            sys.exit(2)
        ts += list(sets.get(n) or [])
    # legado: roles.yaml anterior a 2026-10-10 somava o conjunto `downstream` quando downstream: true
    if r.get("downstream") is True and "downstream" in sets and isinstance(wt, str):
        ts += list(sets.get("downstream") or [])
    # o papel de ADOÇÃO soma o que a porta do mesmo papel não leva (2026-10-11). O nome tem de morar num
    # conjunto: comando fora da partição não é capacidade, é erro de digitação (a REGRA 37 também cobra).
    if kind == "adoption":
        known = set()
        for lst in sets.values():
            known |= set(lst or [])
        for t in (r.get("adoption_keeps") or []):
            if t not in known:
                sys.stderr.write("ERRO: papel %s: adoption_keeps nomeia '%s', que não está em conjunto nenhum\n" % (role, t))
                sys.exit(2)
            ts.append(t)
    for t in sorted(set(ts)):
        print(t)
    sys.exit(0)
if mode == "allowlist":
    al = r.get("allowlist") or {}
    out = []
    for key in ("commands", "agents", "skills", "support"):
        out += list(al.get(key) or [])
    for p in sorted(set(out)):
        print(p)
    sys.exit(0)
if mode in ("overlays", "known_absent"):
    al = r.get("allowlist") or {}
    m = al.get(mode) or {}
    if not isinstance(m, dict):
        sys.stderr.write("ERRO: allowlist.%s do papel %s tem de ser um mapa\n" % (mode, role))
        sys.exit(2)
    for k in sorted(m):
        v = str(m[k] if m[k] is not None else "").replace("\t", " ").replace("\n", " ")
        print("%s\t%s" % (k, v))
    sys.exit(0)
vs = list(r.get("base") or [])
if with_opt:
    vs += list(r.get("optional") or [])
for v in sorted(set(vs)):
    print(v)
PY
