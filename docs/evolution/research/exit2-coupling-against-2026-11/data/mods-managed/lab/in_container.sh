#!/usr/bin/env bash
# in_container.sh <saida-prefixo> <perm> [flags extras de claude...]
# Roda DENTRO do conteiner: sobe o stub em loopback, roda uma sessao com nice, derruba o stub pelo PID.
# A chave e ficticia, igual a do laboratorio da curadoria: nao ha credencial real aqui.
set -u
pref=$1; perm=$2
python3 -I "$LAB_ROOT/lab/stub3.py" 41975 "$pref.stub.log" & S=$!
sleep 0.5
export ANTHROPIC_API_KEY=sk-ant-fict-lab ANTHROPIC_BASE_URL=http://127.0.0.1:41975
export DISABLE_TELEMETRY=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1
nice -n 10 timeout 200 claude -p rode --model haiku --permission-mode "$perm" \
  --output-format stream-json --verbose --include-hook-events --debug-file "$pref.debug.log" \
  --no-session-persistence --max-turns 14 "${@:3}" > "$pref.stream.jsonl" 2> "$pref.err.txt" < /dev/null
rc=$?
echo "$rc" > "$pref.rc"
kill "$S" 2>/dev/null; wait "$S" 2>/dev/null
exit 0
