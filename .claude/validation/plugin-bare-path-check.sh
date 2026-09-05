#!/usr/bin/env bash
# =============================================================================
# plugin-bare-path-check.sh — caminho `.claude/…` NU dentro de um plugin (REGRA 74, com catraca)
#
# O QUE   : dentro de plugins/<p>/**, uma referência a `.claude/{utils,commands,agents,skills,hooks,
#           kb,validation,templates}/…` que NÃO foi reescrita para ${CLAUDE_PLUGIN_ROOT} só resolve no
#           repo do CORE — no consumidor instalado é ponteiro morto. (`.claude/sessions`, `.claude/
#           .onion-version`, `settings.json`, `diary`, `logs`, `beacons` são do PROJETO do consumidor
#           e resolvem lá: legítimos, fora desta regra.)
#           Classe agravada: a ref em `allowed-tools:` — a permissão não casa e o comando NASCE MORTO.
#
# POR QUÊ : medido 2026-09-04: 124 refs nuas em 7 dos 8 plugins (c4-templates 7×, task-manager,
#           templates de contexto, `common:prompts:*` 24×, co-relay.sh em allowed-tools). O PATH-
#           PORTABILITY do assembler só reescreve o que o manifesto EMBARCA; o resto sai intacto.
#           A cura é de MANIFESTO/fonte (embarcar no dono, ou não distribuir o comando) — manual —
#           por isso CATRACA: passivo no baseline = SOFT; novo = HARD; baseline só encolhe.
#
# USO     : plugin-bare-path-check.sh [REPO] [--format text|tsv] [--summary] [--emit-baseline] | --selftest
# Baseline: <repo>/.claude/validation/plugin-bare-path-baseline.txt  (linha: <rel>|<ref>)
# SAÍDA   : <HARD|SOFT><TAB><classe><TAB><rel><TAB><msg>; classe: NOVO · PASSIVO · ALLOWED-TOOLS · CATRACA-VIOLADA · NO-BASELINE
# =============================================================================
set -u
MODE="check"; FORMAT="text"; SUMMARY=0; REPO=""; EMIT=0; BASELINE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --summary) SUMMARY=1; shift ;;
    --emit-baseline) EMIT=1; shift ;;
    --baseline) BASELINE="${2:-}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BASELINE_REL=".claude/validation/plugin-bare-path-baseline.txt"
[ -n "${BASELINE}" ] || BASELINE="${REPO}/${BASELINE_REL}"
command -v python3 >/dev/null 2>&1 || { printf 'plugin-bare-path-check: python3 ausente — varredura pulada\n' >&2; exit 0; }

_scan() {
  local prev=""
  # baseline anterior (catraca): a versão commitada em origin/main, se houver
  prev="$(git -C "${REPO}" show "origin/main:${BASELINE_REL}" 2>/dev/null || true)"
  PREV_BASELINE="${prev}" python3 - "${REPO}" "$1" "$2" "$3" "${BASELINE}" "${BASELINE_REL}" <<'PY'
import os, re, sys
repo, fmt, summary, emit, baseline, baseline_rel = sys.argv[1], sys.argv[2], sys.argv[3] == "1", sys.argv[4] == "1", sys.argv[5], sys.argv[6]
prev = set(l.strip() for l in os.environ.get("PREV_BASELINE", "").splitlines() if l.strip() and not l.startswith("#"))
ROOTS = "utils|commands|agents|skills|hooks|kb|validation|templates"
PAT = re.compile(r"(?<![A-Za-z0-9_${}./-])\.claude/(?:" + ROOTS + r")(?:/[A-Za-z0-9_.@+*{}-]+)*")
found = []   # (rel, ref, in_allowed_tools, lineno)
pdir = os.path.join(repo, "plugins")
if os.path.isdir(pdir):
    for plugin in sorted(os.listdir(pdir)):
        root = os.path.join(pdir, plugin)
        if not os.path.isdir(root): continue
        for dp, dn, fn in os.walk(root):
            if "/.claude-plugin" in dp: continue
            for f in sorted(fn):
                if not (f.endswith(".md") or f.endswith(".sh") or f.endswith(".json") or f.endswith(".yaml")): continue
                path = os.path.join(dp, f); rel = os.path.relpath(path, repo)
                try: txt = open(path, encoding="utf-8", errors="surrogateescape").read()
                except Exception: continue
                in_fm = False; fm_done = False
                for i, line in enumerate(txt.splitlines(), 1):
                    if i == 1 and line.strip() == "---": in_fm = True; continue
                    if in_fm and line.strip() == "---": in_fm = False; fm_done = True
                    for m in PAT.finditer(line):
                        ref = m.group(0).rstrip(".,;:)")
                        at = in_fm and line.lstrip().startswith("allowed-tools")
                        found.append((rel, ref, at, i))
if emit:
    print("# Baseline de caminhos .claude/ NUS dentro de plugins/ — PASSIVO TOLERADO (REGRA 74).")
    print("# Gerado por: bash .claude/validation/plugin-bare-path-check.sh --emit-baseline > " + baseline_rel)
    print("# formato: <rel>|<ref>. SÓ PODE ENCOLHER (embarque o artefato no plugin dono, ou não distribua o comando).")
    for k in sorted(set(f"{r}|{ref}" for r, ref, at, i in found)): print(k)
    sys.exit(0)
rows = []
if not os.path.isfile(baseline):
    rows.append(("HARD", "NO-BASELINE", baseline_rel, "baseline ausente — bootstrap: --emit-baseline > " + baseline_rel))
    cur = set()
else:
    cur = set(l.strip() for l in open(baseline, encoding="utf-8") if l.strip() and not l.startswith("#"))
    # CATRACA POR CONTAGEM (2026-09-04, consolidação 8→5): a chave é <rel>|<ref> e um RENAME de plugin
    # (plugins/onion-work-tools/… → plugins/onion/…) reescreve todas as chaves sem mudar o passivo — a
    # diferença de conjuntos acusaria "cresceu" com 0 refs novas. O que "só encolhe" é o NÚMERO.
    if prev and len(cur) > len(prev):
        grew = cur - prev
        rows.append(("HARD", "CATRACA-VIOLADA", baseline_rel, f"baseline CRESCEU: {len(prev)} → {len(cur)} entrada(s) vs origin/main — o passivo só encolhe; novas: " + ", ".join(sorted(grew)[:3])))
passivo = 0
for rel, ref, at, i in found:
    key = f"{rel}|{ref}"
    if key in cur:
        passivo += 1
        if at: rows.append(("SOFT", "ALLOWED-TOOLS", rel, f"l.{i}: `{ref}` em allowed-tools — a permissão não casa no consumidor; o comando nasce MORTO (passivo tolerado, cure primeiro)"))
        continue
    rows.append(("HARD", "NOVO", rel, f"l.{i}: `{ref}` só resolve no core — embarque no plugin dono (manifesto) ou cite sem caminho"))
if summary:
    print(f"plugin-bare-path: {len(found)} ref(s) nua(s), {passivo} no baseline, {len([r for r in rows if r[0]=='HARD'])} HARD")
elif fmt == "tsv":
    for r in rows: print("\t".join(r))
    if passivo: print(f"SOFT\tPASSIVO\t{baseline_rel}\t{passivo} caminho(s) .claude/ nu(s) em plugins/ tolerados pelo baseline — a métrica de saúde é este número DIMINUINDO")
else:
    for r in rows: print(f"{r[0]} [{r[1]}] {r[2]}: {r[3]}")
    if passivo: print(f"SOFT [PASSIVO] {passivo} tolerado(s) pelo baseline")
PY
}

_selftest() {
  local fails=0 out d
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; d="${SELFTEST_D}"
  mkdir -p "${d}/r/.claude/validation" "${d}/r/plugins/p/commands"
  printf -- '---\nname: x\nallowed-tools: Bash(bash .claude/utils/co/relay.sh*)\n---\nVeja `.claude/utils/c4-templates.md` e `${CLAUDE_PLUGIN_ROOT}/utils/ok.md` e `.claude/sessions/x`.\n' > "${d}/r/plugins/p/commands/x.md"
  local BL="${d}/r/.claude/validation/plugin-bare-path-baseline.txt"
  # (i) sem baseline → HARD NO-BASELINE + NOVO
  out="$(bash "$0" "${d}/r" --format tsv)"
  if grep -q "NO-BASELINE" <<< "${out}" && [ "$(printf '%s\n' "${out}" | grep -c "	NOVO	")" -eq 2 ]; then echo "  ✅ (i) sem baseline = NO-BASELINE + 2 NOVO (sessions/ e PLUGIN_ROOT não contam)"; else echo "  ✗ (i): ${out}"; fails=$((fails+1)); fi
  # (ii) emit → baseline; passivo tolerado (SOFT), allowed-tools marcado
  bash "$0" "${d}/r" --emit-baseline > "${BL}"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if ! grep -q "^HARD" <<< "${out}" && grep -q "ALLOWED-TOOLS" <<< "${out}" && grep -q "PASSIVO" <<< "${out}"; then echo "  ✅ (ii) passivo baselined = SOFT; allowed-tools sinalizado"; else echo "  ✗ (ii): ${out}"; fails=$((fails+1)); fi
  # (iii) ref NOVA fora do baseline → HARD
  printf 'Nova: `.claude/commands/common/templates/t.md`.\n' >> "${d}/r/plugins/p/commands/x.md"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if grep -q "^HARD	NOVO" <<< "${out}"; then echo "  ✅ (iii) ref nova fora do baseline = HARD"; else echo "  ✗ (iii): ${out}"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "plugin-bare-path-check selftest: OK"; return 0; }
  echo "plugin-bare-path-check selftest: ${fails} falha(s)"; return 1
}

case "${MODE}" in selftest) _selftest ;; *) _scan "${FORMAT}" "${SUMMARY}" "${EMIT}" ;; esac
