#!/usr/bin/env bash
# =============================================================================
# members-validate.sh — valida o registro de membros da federação (members.yaml)
#
# Propósito : O "teste que falha se um membro quebrar o registro". É o validador
#             determinístico que a spec m3-federation-admin nomeia como
#             pré-requisito de qualquer OP de mutação (OP-1..4): barra membro
#             mal-formado ANTES do commit — hoje só há yaml.safe_load tolerante
#             e awk frouxo (bug FED-2-0). NÃO reimplementa a P6 de nome-projetado
#             (isso é projection-safety.sh — guarda-única, invocada à parte).
#
# Uso       : bash .claude/validation/members-validate.sh [<path-do-members.yaml>] [--json]
#               <path> : caminho PASSADO COMO ARGUMENTO; default = o members.yaml
#                        do próprio repo (resolvido por BASH_SOURCE, nunca embutido).
#               --json : saída JSON {valid, path, errors[]} para o comando consumir.
#
# Saída     : exit 0 = válido · 1 = inválido (erros listados) · 2 = uso incorreto
#             · 3 = python3+yaml ausente (degrada gracioso, não reprova)
#
# Determinístico, sem LLM. É a peça de validação do par
# /meta:federation-member (orquestra) ↔ este script (valida) — ajuste 6a:
# a validação vive aqui, NUNCA num agente.
# =============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# GIT_DIR neutralizado (mesmo cuidado do federation-console.sh): sob hook do git em
# worktree o GIT_DIR é ABSOLUTO e faria rev-parse devolver o subdir, não a raiz.
ROOT="$(env -u GIT_DIR -u GIT_WORK_TREE git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || (cd "${HERE}/../.." && pwd))"

JSON=0
MEMBERS=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    -*) echo "uso: $0 [<path-do-members.yaml>] [--json]" >&2; exit 2 ;;
    *) MEMBERS="$arg" ;;
  esac
done
[[ -z "$MEMBERS" ]] && MEMBERS="${ROOT}/docs/evolution/federation/members.yaml"

if [[ ! -f "$MEMBERS" ]]; then
  echo "uso: $0 [<path-do-members.yaml>] [--json]  — arquivo não encontrado: $MEMBERS" >&2
  exit 2
fi

command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 \
  || { echo "members-validate: python3+yaml ausente (exit 3, gracioso)." >&2; exit 3; }

python3 - "$MEMBERS" "$JSON" <<'PY'
import sys, json, re

path, json_mode = sys.argv[1], sys.argv[2] == "1"
errors = []

def err(msg):
    errors.append(msg)

try:
    import yaml
    with open(path) as fh:
        doc = yaml.safe_load(fh) or {}
except Exception as e:
    err(f"YAML não parseável: {e}")
    doc = None

if isinstance(doc, dict):
    # --- cabeçalho do ledger -------------------------------------------------
    for key in ("version", "trust_policy_version"):
        if key not in doc:
            err(f"cabeçalho: chave '{key}' ausente")

    members = doc.get("members")
    if not isinstance(members, list):
        err("top-level 'members:' ausente ou não é lista")
        members = []

    ROLES = {"source", "hub", "standalone", "consumer"}
    KINDS = {"source", "adopter", "distillation", "door", "method"}
    NONVENDOR = {"distillation", "method"}       # onion_version: n/a
    VENDOR = {"adopter", "door"}                 # pin real obrigatório
    TRUST_LISTS = ("can_receive_from", "can_advise_to", "can_correct_to",
                   "diary_readable_by", "exposes_downstream")

    seen = {}
    for i, m in enumerate(members):
        tag = f"membro[{i}]"
        if not isinstance(m, dict):
            err(f"{tag}: entrada não é um mapa")
            continue

        mid = m.get("id")
        tag = f"membro '{mid}'" if mid else tag
        if not mid or not isinstance(mid, str):
            err(f"{tag}: 'id' ausente ou vazio")
        else:
            if mid in seen:
                err(f"{tag}: 'id' duplicado (já em membro[{seen[mid]}])")
            seen[mid] = i

        if not m.get("name"):
            err(f"{tag}: 'name' ausente")

        role = m.get("role")
        if role not in ROLES:
            err(f"{tag}: 'role' inválido ou ausente ('{role}'); esperado {sorted(ROLES)}")

        kind = m.get("kind")
        if kind not in KINDS:
            err(f"{tag}: 'kind' inválido ou ausente ('{kind}'); esperado {sorted(KINDS)}")

        # a fonte (source) é o único membro sem parent/onion_version/trust — por papel.
        if role == "source":
            continue

        if not m.get("parent"):
            err(f"{tag}: 'parent' ausente (obrigatório salvo role:source)")

        ver = m.get("onion_version")
        if ver in (None, ""):
            err(f"{tag}: 'onion_version' ausente (use 'n/a' só p/ distillation/method)")
        elif kind in VENDOR:
            if str(ver) == "n/a":
                err(f"{tag}: kind '{kind}' vendoriza — 'onion_version' não pode ser 'n/a' (pin VERIFICADO obrigatório)")
            elif not re.fullmatch(r"[0-9a-f]{7,40}", str(ver)):
                err(f"{tag}: 'onion_version' não parece um commit curto ('{ver}')")
        elif kind in NONVENDOR and str(ver) != "n/a":
            err(f"{tag}: kind '{kind}' não vendoriza — 'onion_version' deve ser 'n/a' (veio '{ver}')")

        for f in ("adopted_at", "mode", "personality_summary", "personality_last_sync"):
            if not m.get(f):
                err(f"{tag}: '{f}' ausente")
        if not isinstance(m.get("specializations"), list):
            err(f"{tag}: 'specializations' ausente ou não é lista")

        trust = m.get("trust")
        if not isinstance(trust, dict):
            err(f"{tag}: bloco 'trust:' ausente ou mal-formado (obrigatório salvo role:source)")
        else:
            for tl in TRUST_LISTS:
                if tl not in trust:
                    err(f"{tag}: trust.'{tl}' ausente")
                elif not isinstance(trust[tl], list):
                    err(f"{tag}: trust.'{tl}' não é lista")
elif doc is not None:
    err("documento raiz não é um mapa (esperado: chaves version/trust_policy_version/members)")

valid = len(errors) == 0
if json_mode:
    print(json.dumps({"valid": valid, "path": path, "errors": errors}, ensure_ascii=False))
else:
    if valid:
        print(f"✅ members.yaml válido: {path} ({len(doc.get('members', [])) if isinstance(doc, dict) else 0} membros)")
    else:
        print(f"❌ members.yaml inválido: {path}")
        for e in errors:
            print(f"   ∟ {e}")

sys.exit(0 if valid else 1)
PY
