#!/usr/bin/env bash
# =============================================================================
# instructions-loaded-log.sh — L1 da poda de instruções: CENSO DE CARGA (D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS, opção C)
#
# Hook InstructionsLoaded (Claude Code ≥ 2.1.25x; payload medido no binário 2.1.259): file_path, memory_type
# (User|Project|Local|Managed), load_reason (session_start|nested_traversal|path_glob_match|include|compact),
# globs?, trigger_file_path?, parent_file_path?. Registra o que CARREGOU e por quê — não o que influenciou.
# Este hook só APENDE uma linha JSON em .claude/sessions/instructions-loaded.jsonl (fora do git, como o
# model-switch.jsonl). Nunca veta (exit 0 sempre): é instrumento, não guarda. A leitura é a projeção
# `bash .claude/validation/instructions-loaded-census.sh` (por arquivo × load_reason, N sessões).
# Doutrina: podar por comportamento, nunca por contagem de linha — o censo só aponta CANDIDATAS (arquivo que só
# carrega em session_start mas é doutrina de escopo; paths: que nunca casam). Protocolo: `poda-instrucoes-protocolo-2026-09` (core-only)
# =============================================================================
input="$(cat 2>/dev/null || true)"
[ -n "${input}" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
log="${ONION_INSTRUCTIONS_LOG:-${root}/.claude/sessions/instructions-loaded.jsonl}"
mkdir -p "$(dirname "${log}")" 2>/dev/null || exit 0
ROOT="${root}" printf '%s' "${input}" | ROOT="${root}" python3 -c '
import json, sys, os, datetime
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
root = os.environ.get("ROOT", "")
fp = d.get("file_path", "") or ""
if root and fp.startswith(root + "/"): fp = fp[len(root) + 1:]
rec = {
    "ts": datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "session": (d.get("session_id") or "")[:8],
    "file": fp,
    "memory_type": d.get("memory_type", ""),
    "load_reason": d.get("load_reason", ""),
    "trigger": os.path.relpath(d["trigger_file_path"], root) if d.get("trigger_file_path") and root else (d.get("trigger_file_path") or ""),
}
print(json.dumps(rec, ensure_ascii=False))
' >> "${log}" 2>/dev/null || true
exit 0
