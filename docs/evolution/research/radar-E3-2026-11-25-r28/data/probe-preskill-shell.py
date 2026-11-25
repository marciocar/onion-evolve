# uso: PATH=<pasta com o binário claude da versão>:$PATH python3 -I probe-preskill-shell.py ops/testing/permissions-deny-bench.py <pasta de trabalho> none|block|allow
# sonda o PreSkillShellCommand: um comando com diretiva que grava marcador; hook que registra stdin e sai 2
import sys, os, json, time, importlib.util, subprocess
spec = importlib.util.spec_from_file_location("bench", sys.argv[1]); b = importlib.util.module_from_spec(spec); spec.loader.exec_module(b)
W, mode = sys.argv[2], sys.argv[3]   # mode: none | block | allow
os.makedirs(W, exist_ok=True)
H, P = b.build_fixture(W)
b.write(f"{P}/.claude/commands/probe.md", "---\ndescription: sonda\n---\nmarca: !`touch " + W + "/directive-ran && echo DIRETIVA-RODOU`\n")
b.write(f"{W}/hook.sh", "#!/bin/sh\ncat > " + W + "/hook-stdin.json\necho 'recusado pela sonda r28' >&2\nexit " + ("2" if mode=="block" else "0") + "\n", 0o755)
s = {} if mode == "none" else {"hooks": {"PreSkillShellCommand": [{"hooks": [{"type": "command", "command": f"{W}/hook.sh"}]}]}}
b.write(f"{P}/.claude/settings.json", json.dumps(s))
stub = b.Stub([])
env = {k: v for k, v in os.environ.items() if not k.startswith(("CLAUDE", "ANTHROPIC"))}
env.update(HOME=H, ANTHROPIC_API_KEY="sk-ant-fict-lab", ANTHROPIC_BASE_URL=f"http://127.0.0.1:{stub.port}", DISABLE_TELEMETRY="1", CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1", DISABLE_AUTOUPDATER="1", TMPDIR=f"{W}/tmp")
os.makedirs(f"{W}/tmp", exist_ok=True)
t = time.time()
try:
    r = subprocess.run(["claude", "-p", "/probe", "--model", "haiku", "--no-session-persistence", "--max-turns", "2", "--permission-mode", "bypassPermissions", "--output-format", "json"], cwd=P, env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=90)
    rc, out, err = r.returncode, r.stdout, r.stderr
except subprocess.TimeoutExpired as e:
    rc, out, err = "timeout", (e.stdout or b"").decode() if isinstance(e.stdout, bytes) else (e.stdout or ""), ""
stub.close()
ver = subprocess.run(["claude", "--version"], capture_output=True, text=True).stdout.strip()
user_text = [json.loads(out).get("result","")] if out.strip().startswith("{") else [out[-300:]]
print(json.dumps({"ver": ver, "mode": mode, "rc": rc, "secs": round(time.time()-t,1), "directive_ran": os.path.exists(f"{W}/directive-ran"), "hook_called": os.path.exists(f"{W}/hook-stdin.json"), "hook_stdin": open(f"{W}/hook-stdin.json").read()[-700:] if os.path.exists(f"{W}/hook-stdin.json") else None, "stderr": err[-300:], "evidence_lines": [x[:300] for x in user_text][:3]}, ensure_ascii=False))
