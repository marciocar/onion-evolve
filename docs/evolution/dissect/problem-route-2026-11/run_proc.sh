#!/usr/bin/env bash
# run_proc.sh — um processo cego da parte em papel (G1, G2, F, A1, A2, C1, C2, J), em série, isolado.
#
# Uso: bash run_proc.sh <papel> <pasta vazia fora do repo> <arquivo do prompt> <tools: "" | Read> <ledger.jsonl> [<session_id para --resume>]
#   stdout do claude (JSON) vai a <pasta>/<papel>.<n>.json; o ledger ganha uma linha com uso de tokens e duração.
#
# Forma (STAGE0.md §4): claude -p --model opus --setting-sources "" --strict-mcp-config --disable-slash-commands,
# CLAUDE_CODE_DISABLE_AUTO_MEMORY=1, cwd numa pasta fora do repo; --tools "" em A, C e J; --tools Read em G e F.
# O prompt vai por stdin. Teto de memória: systemd-run --user --scope -p MemoryMax=1G. timeout -k.
# Carga: acima de 15, espera abaixo de 12, com teto de espera de 30 min; estourou, sai 75 com mensagem própria.
set -uo pipefail
role="$1"; dir="$2"; prompt="$3"; tools="$4"; ledger="$5"; resume="${6:-}"
case "$dir" in "$HOME/onion-evolve"*|"$HOME/worktrees"*) echo "run_proc: pasta dentro de um repo: $dir" >&2; exit 2 ;; esac

load() { awk '{print int($1)}' /proc/loadavg; }
if [ "$(load)" -gt 15 ]; then
  waited=0
  while [ "$(load)" -ge 12 ]; do
    [ "$waited" -ge 1800 ] && { echo "run_proc: CARGA-ALTA-TETO-DE-ESPERA: carga $(load) acima de 12 por 30 min; $role não rodou" >&2; exit 75; }
    sleep 30; waited=$((waited + 30))
  done
fi

n=1; while [ -e "$dir/$role.$n.json" ]; do n=$((n + 1)); done
out="$dir/$role.$n.json"
args=(-p --model opus --setting-sources "" --strict-mcp-config --disable-slash-commands --output-format json --tools "$tools")
[ -n "$resume" ] && args+=(--resume "$resume")
start=$(date +%s)
( cd "$dir" && CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 systemd-run --user --scope --quiet -p MemoryMax=1G \
    timeout -k 30 3600 claude "${args[@]}" < "$prompt" > "$out" 2> "$dir/$role.$n.err" )
rc=$?
end=$(date +%s)
python3 - "$out" "$role" "$n" "$rc" "$((end - start))" "$ledger" "$resume" <<'PY'
import json, sys
out, role, n, rc, secs, ledger, resume = sys.argv[1:]
try:
    d = json.load(open(out, encoding='utf-8'))
except Exception:
    d = {}
u = d.get('usage') or {}
row = {'role': role, 'call': int(n), 'rc': int(rc), 'secs': int(secs), 'resume': resume or None,
       'session_id': d.get('session_id'), 'num_turns': d.get('num_turns'), 'is_error': d.get('is_error'),
       'input': u.get('input_tokens', 0), 'cache_creation': u.get('cache_creation_input_tokens', 0),
       'cache_read': u.get('cache_read_input_tokens', 0), 'output': u.get('output_tokens', 0)}
row['total'] = row['input'] + row['cache_creation'] + row['cache_read'] + row['output']
open(ledger, 'a', encoding='utf-8').write(json.dumps(row) + '\n')
print(json.dumps(row))
PY
exit "$rc"
