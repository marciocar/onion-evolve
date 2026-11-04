#!/usr/bin/env bash
# Com AGENTS.md e CLAUDE.md, o que o Claude Code põe na requisição? Mede o marcador no corpo enviado ao stub, com chave fictícia.
# Uso: LAB=<dir vazio> CLAUDE_BIN=<claude> bash agents_md_cells.sh    (uma linha JSON por célula)
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
cell() { # nome: monta proj pelo nome
  local n=$1 W="$LAB/am-$1"; rm -rf "$W"; mkdir -p "$W/proj" "$W/home" "$W/cfg" "$W/tmp"; git init -q "$W/proj"
  case "$n" in
    nenhum) : ;;
    so-claude) echo MARK_CLAUDE_X > "$W/proj/CLAUDE.md" ;;
    so-agents) echo MARK_AGENTS_X > "$W/proj/AGENTS.md" ;;
    os-dois) echo MARK_CLAUDE_X > "$W/proj/CLAUDE.md"; echo MARK_AGENTS_X > "$W/proj/AGENTS.md" ;;
    os-dois-import) printf 'MARK_CLAUDE_X\n@AGENTS.md\n' > "$W/proj/CLAUDE.md"; echo MARK_AGENTS_X > "$W/proj/AGENTS.md" ;;
    agents-em-subdir) echo MARK_CLAUDE_X > "$W/proj/CLAUDE.md"; mkdir "$W/proj/d"; echo MARK_AGENTS_X > "$W/proj/d/AGENTS.md" ;;
  esac
  STUB_MARKERS=MARK_CLAUDE_X,MARK_AGENTS_X python3 -I "$HERE/stub_messages.py" "$W/port" "$W/stub.log" 40 >/dev/null 2>&1 &
  for _ in $(seq 1 50); do [ -s "$W/port" ] && break; sleep 0.1; done
  ( cd "$W/proj"; env -i PATH=/usr/bin:/bin HOME="$W/home" CLAUDE_CONFIG_DIR="$W/cfg" TMPDIR="$W/tmp" ANTHROPIC_BASE_URL="http://127.0.0.1:$(cat "$W/port")" ANTHROPIC_API_KEY=sk-ant-fict CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 DISABLE_AUTOUPDATER=1 timeout 35 "$CLAUDE_BIN" -p oi --tools "" --output-format json </dev/null >"$W/out.json" 2>"$W/err.txt"; echo "rc=$?" >"$W/rc" )
  python3 -I - "$n" "$W" <<'PY'
import json, sys
n, w = sys.argv[1:]
log = [json.loads(l) for l in open(w + "/stub.log")]
m = log[0]["marks"] if log else {}
print(json.dumps({"cell": n, "rc": open(w + "/rc").read().strip(), "reqs": len(log), "claude_md_na_requisicao": m.get("MARK_CLAUDE_X"), "agents_md_na_requisicao": m.get("MARK_AGENTS_X")}))
PY
}
for c in nenhum so-claude so-agents os-dois os-dois-import agents-em-subdir; do cell "$c"; done
