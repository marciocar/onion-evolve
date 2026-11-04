#!/usr/bin/env bash
# Goose como cliente MCP real contra os dois servidores do repo, com stub no lugar do modelo. Grava o fio por tee.
# Uso: LAB=<dir vazio> GOOSE_BIN=<goose> REPO=<raiz do repo> bash goose_mcp_cells.sh > saida.jsonl
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
cell() { # nome servidor tool-regex entrada-json
  local n=$1 srv=$2 rx=$3 W="$LAB/gm-$1"; rm -rf "$W"; mkdir -p "$W/proj" "$W/home" "$W/tmp" "$W/state"
  cat > "$W/srv.sh" <<WR
#!/bin/sh
tee -a "$W/in.log" | A2A_RT_STATE="$W/state" A2A_RT_ME=lab PYTHONDONTWRITEBYTECODE=1 python3 -I "$srv" | tee -a "$W/out.log"
WR
  chmod +x "$W/srv.sh"
  STUB_TOOLRE="$rx" STUB_INPUT='{}' python3 -I "$HERE/stub_messages.py" "$W/port" "$W/stub.log" 60 >/dev/null 2>&1 &
  for _ in $(seq 1 50); do [ -s "$W/port" ] && break; sleep 0.1; done
  ( cd "$W/proj"; env -i PATH=/usr/bin:/bin HOME="$W/home" XDG_CONFIG_HOME="$W/home/.config" XDG_DATA_HOME="$W/home/.local/share" XDG_STATE_HOME="$W/home/.local/state" TMPDIR="$W/tmp" GOOSE_DISABLE_KEYRING=1 GOOSE_TELEMETRY_ENABLED=false GOOSE_PROVIDER=anthropic GOOSE_MODEL=stub ANTHROPIC_HOST="http://127.0.0.1:$(cat "$W/port")" ANTHROPIC_API_KEY=sk-ant-fict GOOSE_MODE=auto timeout 50 "$GOOSE_BIN" run --no-session --no-profile --with-extension "$W/srv.sh" --max-turns 3 -q -t rode </dev/null >"$W/out.txt" 2>"$W/err.txt"; echo "rc=$?" >"$W/rc" )
  python3 -I - "$n" "$W" <<'PY'
import json, os, re, sys
n, w = sys.argv[1:]
def rows(p):
    out = []
    if os.path.exists(p):
        for l in open(p):
            try: out.append(json.loads(l))
            except ValueError: pass
    return out
inn, res = rows(w + "/in.log"), {r.get("id"): r for r in rows(w + "/out.log")}
seq = []
for r in inn:
    q = r.get("params") or {}
    meta = q.get("_meta") or {}
    a = res.get(r.get("id")) or {}
    seq.append({"method": r.get("method"), "wire": meta.get("io.modelcontextprotocol/protocolVersion") or q.get("protocolVersion"),
                "error": (a.get("error") or {}).get("code"), "tool": q.get("name"),
                "is_error": (a.get("result") or {}).get("isError")})
log = rows(w + "/stub.log")
print(json.dumps({"cell": n, "rc": open(w + "/rc").read().strip(), "tool_vista_pelo_modelo": next((l["tool"] for l in log if l["tool"]), None), "fio": seq}, ensure_ascii=False))
PY
}
cell kg_mcp "$REPO/vendor/kg-ssot/tools/kg_mcp.py" 'kg_schema_help'
cell a2a_rt_mcp "$REPO/.claude/utils/federation-transport/a2a-rt-mcp.py" '__'
