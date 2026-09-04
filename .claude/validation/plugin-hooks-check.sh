#!/usr/bin/env bash
# =============================================================================
# plugin-hooks-check.sh — hook EMPACOTADO resolve no plugin instalado (REGRA 73)
#
# O QUE   : para cada plugins/<p>/hooks/hooks.json: (1) todo `command` aponta um script que EXISTE
#           dentro do plugin (via ${CLAUDE_PLUGIN_ROOT}/…); (2) nenhum script de hook monta caminho
#           com `$REPO/${CLAUDE_PLUGIN_ROOT}` (variável absoluta prefixada — sempre inválido);
#           (3) todo `${CLAUDE_PLUGIN_ROOT}/<x>` citado DENTRO de um script de hook existe no plugin
#           (o motor que o hook chama viajou?); (4) o `matcher` de cada evento espelha o do
#           settings.json do core para o mesmo script (sem matcher, PostToolUse roda em TODA tool).
#
# POR QUÊ : medido 2026-09-04: `plugins/onion/hooks/aside-router-hook.sh:24` fazia
#           ENGINE="$REPO/${CLAUDE_PLUGIN_ROOT}/validation/aside-router.sh" e o motor não estava
#           empacotado; `[ -f "$ENGINE" ] || exit 0` engolia os dois erros — a feature "aparte do
#           maestro" estava MORTA E SILENCIOSA no plugin. E o hooks.json gerado não carregava o
#           matcher `Bash` do core. Nenhuma guarda via: o lint não varre plugins/.
#
# USO     : plugin-hooks-check.sh [REPO] [--format text|tsv] [--summary] | --selftest
# SAÍDA   : HARD<TAB><classe><TAB><rel><TAB><msg>   classes: script-ausente · repo-prefixado ·
#           motor-ausente · matcher-divergente   · vazio = limpo
# =============================================================================
set -u
MODE="check"; FORMAT="text"; SUMMARY=0; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --summary) SUMMARY=1; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
command -v python3 >/dev/null 2>&1 || { printf 'plugin-hooks-check: python3 ausente — varredura pulada\n' >&2; exit 0; }

_scan() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, os, re, sys
repo, fmt, summary = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
rows = []
PR = "${CLAUDE_PLUGIN_ROOT}"
# matchers do core por basename do script
core_match = {}
try:
    st = json.load(open(os.path.join(repo, ".claude", "settings.json"), encoding="utf-8"))
    for ev, lst in (st.get("hooks") or {}).items():
        for entry in lst:
            for hk in entry.get("hooks") or []:
                bn = os.path.basename(hk.get("command", "").strip().rstrip('"').split('"')[-1].split()[0]) if hk.get("command") else ""
                m = re.search(r'/([A-Za-z0-9_.-]+\.sh)', hk.get("command", ""))
                if m: core_match[(ev, m.group(1))] = entry.get("matcher")
except Exception:
    pass
pdir = os.path.join(repo, "plugins")
if os.path.isdir(pdir):
    for plugin in sorted(os.listdir(pdir)):
        root = os.path.join(pdir, plugin)
        hj = os.path.join(root, "hooks", "hooks.json")
        if not os.path.isfile(hj): continue
        rel_hj = os.path.relpath(hj, repo)
        try: data = json.load(open(hj, encoding="utf-8"))
        except Exception as e:
            rows.append(("HARD", "json-invalido", rel_hj, f"hooks.json não parseia: {e}")); continue
        for ev, lst in (data.get("hooks") or {}).items():
            for entry in lst:
                for hk in entry.get("hooks") or []:
                    cmd = hk.get("command", "")
                    m = re.search(r'\$\{CLAUDE_PLUGIN_ROOT\}/([^" ]+)', cmd)
                    if not m:
                        rows.append(("HARD", "script-ausente", rel_hj, f"{ev}: command sem ${{CLAUDE_PLUGIN_ROOT}}/…: {cmd}")); continue
                    script = os.path.join(root, m.group(1))
                    if not os.path.isfile(script):
                        rows.append(("HARD", "script-ausente", rel_hj, f"{ev}: {m.group(1)} não existe no plugin")); continue
                    bn = os.path.basename(script)
                    cm = core_match.get((ev, bn), "__none__")
                    if cm != "__none__" and (entry.get("matcher") or None) != (cm or None):
                        rows.append(("HARD", "matcher-divergente", rel_hj, f"{ev}/{bn}: matcher do plugin={entry.get('matcher')!r} ≠ core={cm!r} (sem matcher, PostToolUse roda em TODA tool)"))
                    txt = open(script, encoding="utf-8", errors="surrogateescape").read()
                    rel_s = os.path.relpath(script, repo)
                    for i, line in enumerate(txt.splitlines(), 1):
                        if line.lstrip().startswith('#'): continue   # comentário não é caminho
                        if re.search(r'\$\{?REPO\}?/\$\{CLAUDE_PLUGIN_ROOT\}', line) or re.search(r'\$[A-Z_]+/\$\{CLAUDE_PLUGIN_ROOT\}', line):
                            rows.append(("HARD", "repo-prefixado", rel_s, f"l.{i}: variável absoluta prefixada a ${{CLAUDE_PLUGIN_ROOT}} — caminho sempre inválido"))
                        for mm in re.finditer(r'\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_./-]+)', line):
                            tgt = os.path.join(root, mm.group(1))
                            if not os.path.exists(tgt):
                                rows.append(("HARD", "motor-ausente", rel_s, f"l.{i}: {mm.group(1)} citado pelo hook não viajou no plugin (o `[ -f ] || exit 0` esconde isso)"))
if summary:
    from collections import Counter
    c = Counter(r[1] for r in rows)
    print(f"plugin-hooks: {len(rows)} — " + ", ".join(f"{k}={v}" for k, v in sorted(c.items())) if rows else "plugin-hooks: 0 — limpo")
elif fmt == "tsv":
    for r in rows: print("\t".join(r))
else:
    for r in rows: print(f"{r[0]} [{r[1]}] {r[2]}: {r[3]}")
PY
}

_selftest() {
  local fails=0 out
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; local d="${SELFTEST_D}"
  mkdir -p "${d}/r/.claude" "${d}/r/plugins/p/hooks" "${d}/r/plugins/p/validation"
  printf '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash \\"$CLAUDE_PROJECT_DIR/.claude/hooks/g.sh\\""}]}]}}\n' > "${d}/r/.claude/settings.json"
  printf '#!/usr/bin/env bash\nE="${CLAUDE_PLUGIN_ROOT}/validation/engine.sh"\n[ -f "$E" ] || exit 0\n' > "${d}/r/plugins/p/hooks/g.sh"; : > "${d}/r/plugins/p/validation/engine.sh"
  printf '{"hooks":{"PostToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/g.sh\\""}]}]}}\n' > "${d}/r/plugins/p/hooks/hooks.json"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if [ -z "${out}" ]; then echo "  ✅ (a) hook resolvível, motor presente, matcher igual = limpo"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  # (b) motor ausente + repo prefixado
  printf '#!/usr/bin/env bash\nE="$REPO/${CLAUDE_PLUGIN_ROOT}/validation/missing.sh"\n[ -f "$E" ] || exit 0\n' > "${d}/r/plugins/p/hooks/g.sh"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "repo-prefixado" && printf '%s' "${out}" | grep -q "motor-ausente"; then echo "  ✅ (b) repo-prefixado + motor-ausente detectados"; else echo "  ✗ (b): ${out}"; fails=$((fails+1)); fi
  # (c) matcher divergente (plugin sem matcher, core com Bash) + script ausente
  printf '{"hooks":{"PostToolUse":[{"hooks":[{"type":"command","command":"bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/g.sh\\""}]}],"UserPromptSubmit":[{"hooks":[{"type":"command","command":"bash \\"${CLAUDE_PLUGIN_ROOT}/hooks/nope.sh\\""}]}]}}\n' > "${d}/r/plugins/p/hooks/hooks.json"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "matcher-divergente" && printf '%s' "${out}" | grep -q "script-ausente"; then echo "  ✅ (c) matcher-divergente + script-ausente detectados"; else echo "  ✗ (c): ${out}"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "plugin-hooks-check selftest: OK"; return 0; }
  echo "plugin-hooks-check selftest: ${fails} falha(s)"; return 1
}

case "${MODE}" in selftest) _selftest ;; *) _scan "${REPO}" "${FORMAT}" "${SUMMARY}" ;; esac
