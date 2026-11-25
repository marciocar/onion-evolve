# uso: PATH=<pasta com o binário claude da versão>:$PATH python3 -I probe-long-command.py ops/testing/permissions-deny-bench.py .claude/settings.json <pasta de trabalho> <repetições> <1=com deny|0=sem> <teto s>
# mede o tempo do motor real julgando um comando longo contra o deny da casa (roteiro falso, sem API real)
import sys, os, json, time, importlib.util, subprocess
spec = importlib.util.spec_from_file_location("bench", sys.argv[1]); b = importlib.util.module_from_spec(spec); spec.loader.exec_module(b)
settings, W, n, withdeny = sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5] == "1"
os.makedirs(W, exist_ok=True)
H, P = b.build_fixture(W)
deny = json.load(open(settings))["permissions"]["deny"]
b.set_settings(P, {"permissions": {"deny": deny}} if withdeny else {})
cmd = "git -c a=b " + "push x -- " * n + "--forc"
t = time.time()
try:
    rc, res = b.run_session(W, H, P, [("Bash", {"command": cmd, "description": "long"})], "default", "long", timeout=int(sys.argv[6]))
    dt = time.time() - t
    print(json.dumps({"ver": subprocess.run(["claude","--version"],capture_output=True,text=True).stdout.strip(), "len": len(cmd), "deny": withdeny, "rc": rc, "secs": round(dt,1), "results": {k:(v[0], v[1][:120]) for k,v in res.items()}}))
except subprocess.TimeoutExpired:
    print(json.dumps({"len": len(cmd), "deny": withdeny, "timeout": True, "secs": round(time.time()-t,1)}))
