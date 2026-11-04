#!/usr/bin/env bash
# O envelope {jws, signal} da federação atravessa o agentgateway íntegro? Compara sha256 antes e depois, com e sem a
# política a2a. O gateway escuta em 127.0.0.1 por `gateways[].bindAddress`; a API antiga `binds` não tem essa opção e
# escuta em todas as interfaces. As portas de gestão têm default em todas as interfaces ([::]:15020 stats e [::]:15021
# readiness, medido), por isso a config as fixa. O ss e o log do próprio gateway provam a escuta. JWS e token são fictícios.
# Uso: LAB=<dir vazio> AGW_BIN=<agentgateway> REPO=<raiz> bash agw_cells.sh
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
free_port() { python3 -I -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1])'; }
ENV_BODY='{"jws":"eyJhbGciOiJFUzI1NiIsImtpZCI6ImxhYi0xIn0.eyJqdGkiOiJ4IiwiYm9keV9zaGEyNTYiOiJ5In0.c2ln","signal":{"id":"lab","direction":"upstream","from":"lab","to":"onion-evolve","kind":"signal","body":"açúcar\n{}"}}'
RPC_BODY='{"jsonrpc":"2.0","id":1,"method":"message/send","params":{"message":{"role":"user","parts":[{"kind":"text","text":"oi"}],"messageId":"m1"}}}'
cell() { # nome politicas
  local n=$1 pol=$2 W="$LAB/agw-$1"; rm -rf "$W"; mkdir -p "$W"
  printf '%s' "$ENV_BODY" > "$W/env.json"; printf '%s' "$RPC_BODY" > "$W/rpc.json"
  python3 -I "$HERE/agw_backend.py" "$W/bport" "$W/back.log" 25 "$REPO/docs/onion/agent-card.json" >/dev/null 2>&1 &
  for _ in $(seq 1 50); do [ -s "$W/bport" ] && break; sleep 0.1; done
  local GP; GP=$(free_port)
  cat > "$W/cfg.yaml" <<Y
config:
  adminAddr: 127.0.0.1:$(free_port)
  statsAddr: 127.0.0.1:$(free_port)
  readinessAddr: 127.0.0.1:$(free_port)
gateways:
  lab:
    port: $GP
    bindAddress: 127.0.0.1
    protocol: HTTP
routes:
- gateways: [lab]
  backends:
  - host: 127.0.0.1:$(cat "$W/bport")
  policies: $pol
Y
  timeout 20 env -i PATH=/usr/bin:/bin HOME="$W" "$AGW_BIN" -f "$W/cfg.yaml" >"$W/agw.log" 2>&1 &
  local pid=$!; for _ in $(seq 1 60); do curl -s -o /dev/null -m 1 "http://127.0.0.1:$GP/" && break; sleep 0.2; done
  ss -ltnH 2>&1 | awk -v p=":$GP\$" '$4 ~ p {print $4}' > "$W/listen.txt"
  local envh rpch code
  envh=$(sha256sum < "$W/env.json" | cut -d' ' -f1); rpch=$(sha256sum < "$W/rpc.json" | cut -d' ' -f1)
  code=$(curl -s -o "$W/resp-env" -w '%{http_code}' -m 5 -H 'Authorization: Bearer lab-token' -H 'Content-Type: application/json' --data-binary @"$W/env.json" "http://127.0.0.1:$GP/a2a")
  local code2; code2=$(curl -s -o "$W/resp-rpc" -w '%{http_code}' -m 5 -H 'Authorization: Bearer lab-token' -H 'Content-Type: application/json' --data-binary @"$W/rpc.json" "http://127.0.0.1:$GP/a2a")
  curl -s -m 5 -o "$W/card.json" "http://127.0.0.1:$GP/.well-known/agent-card.json"
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  python3 -I - "$n" "$W" "$envh" "$rpch" "$code" "$code2" "$GP" <<'PY'
import json, re, sys
n, w, envh, rpch, code, code2, gp = sys.argv[1:]
back = [json.loads(l) for l in open(w + "/back.log")]
orig = json.load(open(w + "/card.json"))
log = open(w + "/agw.log").read()
print(json.dumps({"cell": n, "escuta": open(w + "/listen.txt").read().strip().replace(gp, "<porta>"),
  "http_envelope": code, "http_jsonrpc": code2,
  "envelope_sha256_igual": bool(back) and back[0]["sha256"] == envh, "jsonrpc_sha256_igual": len(back) > 1 and back[1]["sha256"] == rpch,
  "auth_preservado": bool(back) and back[0]["auth"] == "Bearer lab-token",
  "url_do_card_visto": re.sub(r":\d+", ":<porta>", str(orig.get("url"))),
  "escutas_de_gestao": sorted(re.sub(r":\d+$", ":<porta>", a) for a in re.findall(r"listener established\s+address=(\S+)", log)),
  "avisos": sorted(set(re.findall(r"failed to read a2a request: [^\t\n]+", log)))}, ensure_ascii=False))
PY
}
cell plain '{}'
cell a2a '{a2a: {}}'
