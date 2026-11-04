#!/usr/bin/env bash
# bench_guard.sh <B>: a guarda real no conteiner, sem sessao. Nao le o arquivo: so alimenta a guarda com a chamada.
B=$1
IMG=$(cat "$B/image/IMAGE_ID")
docker run --rm --network none --user "$(id -u):$(id -g)" --cap-drop ALL -v "$B/clone:$B/clone:ro" -v "$B/lab:$B/lab:ro" -w "$B/clone" -e B="$B" "$IMG" bash -c '
python3 --version; git --version; jq --version
python3 -I - <<PY
import json, os, subprocess
b = os.environ["B"] + "/clone"
for tool, ti in (("Read", {"file_path": b + "/.env"}), ("Bash", {"command": "cat .env"}), ("Bash", {"command": "echo LAB_OK_BASH"}), ("Read", {"file_path": b + "/LICENSE"})):
    p = subprocess.run(["bash", ".claude/hooks/pretooluse-env-guard.sh"], input=json.dumps({"tool_name": tool, "tool_input": ti, "cwd": b}), capture_output=True, text=True)
    print(tool, list(ti.values())[0][-16:], "rc=%d" % p.returncode, p.stderr[:50])
PY'
