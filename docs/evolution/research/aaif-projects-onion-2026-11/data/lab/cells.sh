#!/usr/bin/env bash
# Células de veto: o mesmo hook no Goose (modo auto) e no Claude Code (bypassPermissions), com stub e chave fictícia.
# O stub sobe com stdout fora do pipe: dentro de $(...) ele prenderia a substituição até o TTL e morreria antes do
# harness conectar (foi o erro da 1ª passada, que o controle positivo denunciou).
# RODOU = o comando do stub criou o MARKER. A prova é o MARKER, não o rc do harness. Toda célula isola HOME e config.
# Uso: LAB=<dir vazio> GOOSE_BIN=<goose> CLAUDE_BIN=<claude> bash cells.sh   (uma linha JSON por célula, sem caminhos)
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
wait_port() { for _ in $(seq 1 50); do [ -s "$1" ] && return 0; sleep 0.1; done; return 1; }
start_stub() { rm -f "$1/port"; STUB_CMD="${2:-true}" STUB_MARKERS="${3:-}" python3 -I "$HERE/stub_messages.py" "$1/port" "$1/stub.log" 70 >/dev/null 2>&1 & wait_port "$1/port"; cat "$1/port"; }
report() { # célula harness dir
  python3 -I - "$1" "$2" "$3" <<'PY'
import json, os, sys
c, h, w = sys.argv[1:]
log = [json.loads(l) for l in open(w + "/stub.log")] if os.path.exists(w + "/stub.log") else []
res = [x for l in log for x in l["results"]]
print(json.dumps({"cell": c, "harness": h, "rc": open(w + "/rc").read().strip(), "RODOU": os.path.exists(w + "/MARKER"),
                  "reqs": len(log), "tool": next((l["tool"] for l in log if l["tool"]), None),
                  "result_err": next((e for l in log for e in l["err"]), None),
                  "result": (res[0][:170].replace(w, "<cell>") if res else None)}, ensure_ascii=False))
PY
}
hook_json() { # comando on_failure chave-on_failure matcher
  python3 -I -c '
import json, sys
a = {"type": "command", "command": sys.argv[1]}
if sys.argv[2] != "-": a[sys.argv[3]] = sys.argv[2]
print(json.dumps({"hooks": {"PreToolUse": [{"matcher": sys.argv[4], "hooks": [a]}]}}))' "$1" "$2" "$3" "$4"
}
goose_cell() { # nome hook on_failure
  local n=$1 hk=$2 of=$3 W="$LAB/goose-$1"; rm -rf "$W"; mkdir -p "$W/proj" "$W/home" "$W/tmp"
  if [ "$hk" != none ]; then
    local P="$W/proj/.agents/plugins/gate"; mkdir -p "$P/hooks"
    echo '{"name":"gate","version":"0.1.0","description":"lab"}' > "$P/plugin.json"
    hook_json "$hk" "$of" on_failure '.*' > "$P/hooks/hooks.json"
  fi
  local PORT; PORT=$(start_stub "$W" "touch $W/MARKER")
  ( cd "$W/proj"; env -i PATH=/usr/bin:/bin HOME="$W/home" XDG_CONFIG_HOME="$W/home/.config" XDG_DATA_HOME="$W/home/.local/share" XDG_STATE_HOME="$W/home/.local/state" TMPDIR="$W/tmp" GOOSE_DISABLE_KEYRING=1 GOOSE_TELEMETRY_ENABLED=false GOOSE_PROVIDER=anthropic GOOSE_MODEL=stub ANTHROPIC_HOST="http://127.0.0.1:$PORT" ANTHROPIC_API_KEY=sk-ant-fict GOOSE_MODE=auto timeout 55 "$GOOSE_BIN" run --no-session --no-profile --with-builtin developer --max-turns 3 -q -t rode </dev/null >"$W/out.txt" 2>"$W/err.txt"; echo "rc=$?" >"$W/rc" )
  report "$n" goose-1.57.0-auto "$W"
}
cc_cell() { # nome hook onFailure
  local n=$1 hk=$2 of=$3 W="$LAB/cc-$1"; rm -rf "$W"; mkdir -p "$W/proj/.claude" "$W/home" "$W/cfg" "$W/tmp"
  [ "$hk" != none ] && hook_json "$hk" "$of" onFailure Bash > "$W/proj/.claude/settings.json"
  local PORT; PORT=$(start_stub "$W" "touch $W/MARKER")
  ( cd "$W/proj"; env -i PATH=/usr/bin:/bin HOME="$W/home" CLAUDE_CONFIG_DIR="$W/cfg" TMPDIR="$W/tmp" ANTHROPIC_BASE_URL="http://127.0.0.1:$PORT" ANTHROPIC_API_KEY=sk-ant-fict CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1 timeout 55 "$CLAUDE_BIN" -p rode --permission-mode bypassPermissions --output-format json --max-turns 3 </dev/null >"$W/out.json" 2>"$W/err.txt"; echo "rc=$?" >"$W/rc" )
  report "$n" "claude-code-$("$CLAUDE_BIN" --version | cut -d' ' -f1)-bypass" "$W"
}
EX2='echo gate-nega >&2; exit 2'; EX1='echo quebrou >&2; exit 1'; MISS='comando-que-nao-existe-lab'
goose_cell controle none -
for i in 1 2 3; do goose_cell "exit2-$i" "$EX2" -; done
for i in 1 2 3; do goose_cell "exit1-$i" "$EX1" -; done
goose_cell inexistente "$MISS" -
goose_cell exit1-block "$EX1" block
goose_cell inexistente-block "$MISS" block
cc_cell controle none -
cc_cell exit2 "$EX2" -
cc_cell exit1 "$EX1" -
cc_cell inexistente "$MISS" -
cc_cell exit1-block "$EX1" block
cc_cell inexistente-block "$MISS" block
