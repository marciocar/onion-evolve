#!/usr/bin/env bash
# =============================================================================
# session-degraded-notice.sh — UserPromptSubmit: enquanto a sessão estiver DEGRADADA na escada de modelos,
# avisa a cada prompt (D_COMANDOS_SEM_MODEL_OU_NO_LINEUP, piso Sonnet selado 2026-09-03).
#
# Lê .claude/sessions/model-switch.jsonl (escrito por premodelswitch-guard.sh): o ÚLTIMO evento aplicado desta
# sessão com ladder=degraded liga o aviso; um posterior com ladder=restored desliga. Nunca veta (exit 0 sempre);
# sem log ou sem sessão = silêncio. Doutrina: "sempre o máximo" é direção, não bloqueio — degradar é permitido,
# degradar CALADO não.
# =============================================================================
set -uo pipefail
input="$(cat 2>/dev/null || true)"
sid="${CLAUDE_CODE_SESSION_ID:-}"
[ -n "${sid}" ] || sid="$(printf '%s' "${input}" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: print("")' 2>/dev/null || true)"
[ -n "${sid}" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
log="${ONION_MODEL_SWITCH_LOG:-${root}/.claude/sessions/model-switch.jsonl}"
[ -s "${log}" ] || exit 0
state="$(SID="${sid}" python3 - "${log}" <<'PY' 2>/dev/null || true
import json, sys, os
sid=os.environ["SID"]; last=None
for line in open(sys.argv[1], encoding="utf-8"):
    try: d=json.loads(line)
    except Exception: continue
    if d.get("session")!=sid: continue
    if d.get("decision") not in ("allow","applied"): continue
    if d.get("ladder") in ("degraded","restored"): last=d
if last and last.get("ladder")=="degraded": print("degraded\t"+last.get("to","")+"\t"+last.get("ts",""))
PY
)"
[ -n "${state}" ] || exit 0
to="$(printf '%s' "${state}" | cut -f2)"; ts="$(printf '%s' "${state}" | cut -f3)"
echo "⚠️ Onion: sessão DEGRADADA na escada de modelos — rodando em '${to}' desde ${ts}. Volte ao primário com /model assim que houver capacidade (lineup em docs/onion/radar-baselines.yaml, eixo E6)."
exit 0
