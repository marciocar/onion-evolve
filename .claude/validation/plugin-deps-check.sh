#!/usr/bin/env bash
# =============================================================================
# plugin-deps-check.sh — contrato de DEPENDÊNCIA entre plugins (REGRA 77)
#
# O QUE   : (1) artefato DUPLICADO entre plugins (mesmo basename em skills/, validation/, kb/, utils/ com
#           conteúdo idêntico ou divergente) sem que um dependa do outro — duas cópias divergem;
#           (2) plugin que cita `/<outro-plugin>:<cmd>` (reescrita da REGRA 72) ou uma skill/util que só
#           outro plugin embarca, sem declarar `REQUIRES_PLUGINS=(<outro>)` no manifesto;
#           (3) manifesto com REQUIRES_PLUGINS ⇒ capability.json.requires carrega `plugin:<x>` e o README
#           gerado tem a seção "Requer".
#
# POR QUÊ : medido 2026-09-04: onion e onion-work-tools embarcavam a MESMA skill (onion-orchestration),
#           o MESMO motor (kg-radar.sh, 3 md5 diferentes entre plugins e core) e a MESMA KB; nenhum
#           capability.json declarava outro PLUGIN; onion-design citava uma skill que não embarca. A
#           consolidação 8→5 sumiu com a duplicação; este helper impede que volte e torna a dependência
#           de fato (cross-plugin da REGRA 72) um CONTRATO declarado.
#
# USO     : plugin-deps-check.sh [REPO] [--format text|tsv] [--summary] | --selftest
# SAÍDA   : HARD<TAB><classe><TAB><rel><TAB><msg>; classes: duplicado · dependencia-nao-declarada ·
#           requires-sem-plugin · readme-sem-requer · vazio = limpo
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
command -v python3 >/dev/null 2>&1 || { printf 'plugin-deps-check: python3 ausente — varredura pulada\n' >&2; exit 0; }

_manifest_deps() {   # stdout: plugin<TAB>dep1,dep2
  local m name deps
  for m in "${REPO}"/.claude/utils/marketplace/verticals/*.manifest.sh; do
    [ -f "${m}" ] || continue; case "$(basename "${m}")" in __*) continue ;; esac
    name="$(bash -c '. "$1" >/dev/null 2>&1; printf "%s" "${PLUGIN_NAME:-}"' _ "${m}")"
    deps="$(bash -c '. "$1" >/dev/null 2>&1; printf "%s," "${REQUIRES_PLUGINS[@]:-}"' _ "${m}")"
    [ -n "${name}" ] && printf '%s\t%s\n' "${name}" "${deps%,}"
  done
}

_scan() {
  local tf; tf="$(mktemp)"; _manifest_deps > "${tf}"
  python3 - "${REPO}" "${tf}" "$1" "$2" <<'PY'
import os, re, sys, json, hashlib
repo, depsfile, fmt, summary = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
deps = {}
for line in open(depsfile, encoding="utf-8"):
    p = line.rstrip("\n").split("\t")
    if len(p) == 2: deps[p[0]] = set(x for x in p[1].split(",") if x)
pdir = os.path.join(repo, "plugins")
plugins = [p for p in sorted(os.listdir(pdir))] if os.path.isdir(pdir) else []
rows = []
def md5(path):
    return hashlib.md5(open(path, "rb").read()).hexdigest()
# (1) duplicados: mesmo caminho relativo (skills/<x>/SKILL.md, validation/<x>, kb/<x>, utils/<x>...) em 2+ plugins
index = {}
for p in plugins:
    root = os.path.join(pdir, p)
    # Só CONHECIMENTO (skills/, kb/) é duplicata: motores em validation/utils/hooks viajam com o comando que
    # os chama (um plugin só alcança a PRÓPRIA raiz ${CLAUDE_PLUGIN_ROOT}) e divergem por reescrita per-plugin.
    for sub in ("skills", "kb"):
        base = os.path.join(root, sub)
        if not os.path.isdir(base): continue
        for dp, dn, fn in os.walk(base):
            for f in fn:
                path = os.path.join(dp, f); rel = os.path.relpath(path, root)
                index.setdefault(rel, []).append((p, md5(path)))
for rel, owners in sorted(index.items()):
    if len(owners) < 2: continue
    names = [o[0] for o in owners]
    # tolerado se TODOS os que carregam o artefato dependem de um dono comum? Não: duplicata é duplicata — um dono só.
    same = len({o[1] for o in owners}) == 1
    rows.append(("HARD", "duplicado", f"plugins/{names[0]}/{rel}", f"`{rel}` embarcado por {len(names)} plugins ({', '.join(names)}; conteúdo {'idêntico' if same else 'DIVERGENTE'}) — um dono por artefato; os outros declaram REQUIRES_PLUGINS=(<dono>)"))
# (2) dependência de fato sem declaração: /<outro>:<cmd> ou ${CLAUDE_PLUGIN_ROOT}/skills|utils|validation/<x> que só outro plugin tem
have = {p: set(rel for rel in index if any(o[0] == p for o in index[rel])) for p in plugins}
skills_of = {p: set() for p in plugins}
for p in plugins:
    sk = os.path.join(pdir, p, "skills")
    if os.path.isdir(sk): skills_of[p] = set(os.listdir(sk))
hard_used = {}
for p in plugins:
    root = os.path.join(pdir, p); used = {}
    for dp, dn, fn in os.walk(root):
        if "/.claude-plugin" in dp: continue
        for f in fn:
            if not (f.endswith(".md") or f.endswith(".sh") or f.endswith(".json")): continue
            path = os.path.join(dp, f)
            try: txt = open(path, encoding="utf-8", errors="surrogateescape").read()
            except Exception: continue
            for m in re.finditer(r"(?<![A-Za-z0-9_/.\-])/(onion(?:-[a-z0-9-]+)?):[a-z0-9-]+", txt):
                other = m.group(1)
                if other != p and other in plugins: used.setdefault(other, set()).add(os.path.relpath(path, repo))
            for m in re.finditer(r"skills/([a-z0-9-]+)", txt):
                s = m.group(1)
                if s not in skills_of.get(p, set()):
                    for other in plugins:
                        if other != p and s in skills_of[other]:
                            used.setdefault(other, set()).add(os.path.relpath(path, repo)); hard_used.setdefault(p, set()).add(other)
    for other, files in sorted(used.items()):
        if other in deps.get(p, set()): continue
        ex = sorted(files)[0]
        if other in hard_used.get(p, set()):
            rows.append(("HARD", "dependencia-nao-declarada", ex, f"plugin `{p}` USA uma skill que só o plugin `{other}` embarca ({len(files)} arquivo(s)) sem `REQUIRES_PLUGINS=({other})` no manifesto"))
        else:
            rows.append(("SOFT", "mencao-cruzada", ex, f"plugin `{p}` cita comandos do plugin `{other}` ({len(files)} arquivo(s)) — informativo; o README gerado lista em 'Funciona melhor com' (declare REQUIRES_PLUGINS só se for dependência funcional)"))
# (3) declarado ⇒ capability.json.requires tem plugin:<x> e README tem seção Requer
for p in plugins:
    cap = os.path.join(pdir, p, ".claude-plugin", "capability.json"); rd = os.path.join(pdir, p, "README.md")
    for other in sorted(deps.get(p, set())):
        try: req = json.load(open(cap, encoding="utf-8")).get("requires", [])
        except Exception: req = []
        if f"plugin:{other}" not in req:
            rows.append(("HARD", "requires-sem-plugin", os.path.relpath(cap, repo), f"manifesto declara REQUIRES_PLUGINS=({other}) mas capability.json.requires não tem `plugin:{other}` — regenere o plugin"))
        try: r = open(rd, encoding="utf-8").read()
        except Exception: r = ""
        if "## Requer" not in r or f"`{other}`" not in r:
            rows.append(("HARD", "readme-sem-requer", os.path.relpath(rd, repo), f"README do plugin `{p}` sem seção 'Requer' citando `{other}` — regenere o plugin"))
if summary:
    from collections import Counter
    c = Counter(r[1] for r in rows)
    print(f"plugin-deps: {len(rows)} — " + ", ".join(f"{k}={v}" for k, v in sorted(c.items())) if rows else "plugin-deps: 0 — limpo")
elif fmt == "tsv":
    for r in rows: print("\t".join(r))
else:
    for r in rows: print(f"{r[0]} [{r[1]}] {r[2]}: {r[3]}")
PY
  rm -f "${tf}"
}

_selftest() {
  local fails=0 out d
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; d="${SELFTEST_D}"
  mkdir -p "${d}/r/.claude/utils/marketplace/verticals" "${d}/r/plugins/onion/skills/orch" "${d}/r/plugins/onion-x/commands" "${d}/r/plugins/onion-x/.claude-plugin" "${d}/r/plugins/onion/.claude-plugin"
  printf 'PLUGIN_NAME="onion"\nCOMMANDS=()\n' > "${d}/r/.claude/utils/marketplace/verticals/onion.manifest.sh"
  printf 'PLUGIN_NAME="onion-x"\nCOMMANDS=()\n' > "${d}/r/.claude/utils/marketplace/verticals/onion-x.manifest.sh"
  printf 'skill\n' > "${d}/r/plugins/onion/skills/orch/SKILL.md"
  printf 'Use /onion:kg e a skill skills/orch.\n' > "${d}/r/plugins/onion-x/commands/c.md"
  printf '{"requires":[]}\n' > "${d}/r/plugins/onion-x/.claude-plugin/capability.json"; printf '# x\n' > "${d}/r/plugins/onion-x/README.md"
  # (a) dependência de fato sem declaração → HARD
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "dependencia-nao-declarada" && [ "$(printf '%s\n' "${out}" | grep -c '^HARD')" -eq 1 ]; then echo "  ✅ (a) uso de outro plugin sem REQUIRES_PLUGINS → 1 HARD"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  # (a2) só menção de comando de outro plugin → SOFT informativa, não HARD
  printf 'Use /onion:kg.\n' > "${d}/r/plugins/onion-x/commands/c.md"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "^SOFT	mencao-cruzada" && ! printf '%s' "${out}" | grep -q "^HARD"; then echo "  ✅ (a2) menção de comando de outro plugin = SOFT informativa"; else echo "  ✗ (a2): ${out}"; fails=$((fails+1)); fi
  printf 'Use /onion:kg e a skill skills/orch.\n' > "${d}/r/plugins/onion-x/commands/c.md"
  # (b) declarado no manifesto mas capability/README não refletem → requires-sem-plugin + readme-sem-requer
  printf 'PLUGIN_NAME="onion-x"\nCOMMANDS=()\nREQUIRES_PLUGINS=(onion)\n' > "${d}/r/.claude/utils/marketplace/verticals/onion-x.manifest.sh"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "requires-sem-plugin" && printf '%s' "${out}" | grep -q "readme-sem-requer" && ! printf '%s' "${out}" | grep -q "dependencia-nao-declarada"; then echo "  ✅ (b) declarado ⇒ exige capability.json plugin:onion + README 'Requer'"; else echo "  ✗ (b): ${out}"; fails=$((fails+1)); fi
  # (c) tudo coerente → limpo; (d) duplicata → HARD
  printf '{"requires":["plugin:onion"]}\n' > "${d}/r/plugins/onion-x/.claude-plugin/capability.json"; printf '# x\n\n## Requer\n\n- `onion`\n' > "${d}/r/plugins/onion-x/README.md"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if [ -z "${out}" ]; then echo "  ✅ (c) contrato coerente = limpo"; else echo "  ✗ (c): ${out}"; fails=$((fails+1)); fi
  mkdir -p "${d}/r/plugins/onion-x/skills/orch"; printf 'skill2\n' > "${d}/r/plugins/onion-x/skills/orch/SKILL.md"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if printf '%s' "${out}" | grep -q "duplicado" && printf '%s' "${out}" | grep -q "DIVERGENTE"; then echo "  ✅ (d) artefato duplicado (divergente) → HARD"; else echo "  ✗ (d): ${out}"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "plugin-deps-check selftest: OK"; return 0; }
  echo "plugin-deps-check selftest: ${fails} falha(s)"; return 1
}

case "${MODE}" in selftest) _selftest ;; *) _scan "${FORMAT}" "${SUMMARY}" ;; esac
