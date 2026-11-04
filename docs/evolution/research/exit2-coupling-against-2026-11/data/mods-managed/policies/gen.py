import json, os, shutil, sys
B, guard = sys.argv[1:3]
HOOK = {"PreToolUse": [{"matcher": "Read|Grep|Bash", "hooks": [{"type": "command", "command": "bash /etc/claude-code/hooks/managed-env-veto.sh"}]}]}
AMMO = {"pluginConfigs": {"cc-plugin-sec-default@builtin": {"options": {"allowManagedModsOnly": True}}}}
POL = {
    "AMMO": AMMO,
    "HOOK": {"hooks": HOOK},
    "HOOK_SIDE": {"hooks": HOOK, "disableSideloadFlags": True},
    "COMBO": {**AMMO, "hooks": HOOK, "disableSideloadFlags": True},
    "HOOK_SIDE_BLOCK": {"hooks": HOOK, "disableSideloadFlags": True, "blockedMarketplaces": [{"source": "skills-dir"}]},
    # emenda 1
    "NEUTRAL": {"cleanupPeriodDays": 30},
    "XMISS": {"hooks": {"PreToolUse": [{"matcher": "Read|Grep|Bash", "hooks": [{"type": "command", "command": "bash /etc/claude-code/hooks/nao-existe.sh"}]}]}},
}
os.makedirs(f"{B}/policies/XBAD", exist_ok=True)
open(f"{B}/policies/XBAD/managed-settings.json", "w").write('{"disableSideloadFlags": true,}\n')
for n, p in POL.items():
    d = f"{B}/policies/{n}"
    os.makedirs(d, exist_ok=True)
    json.dump(p, open(d + "/managed-settings.json", "w"), indent=2)
    if "hooks" in p:
        os.makedirs(d + "/hooks", exist_ok=True)
        shutil.copy(guard, d + "/hooks/pretooluse-env-guard.sh")
        shutil.copy(f"{B}/policies/managed-env-veto.sh", d + "/hooks/managed-env-veto.sh")
