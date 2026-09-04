#!/usr/bin/env bash
# =============================================================================
# plugin-namespace-check.sh — NAMESPACE de comandos dentro de um plugin (REGRA 72)
#
# O QUE   : um comando empacotado num plugin do Claude Code é invocado como
#           `/<plugin>:<comando>` — NUNCA pelo namespace do core (`/engineer:pr`,
#           `/meta:kg`). Dentro de `plugins/**` toda ocorrência `/<ns-do-core>:<cmd>`
#           é um ponteiro que NÃO RESOLVE no consumidor instalado, em três classes:
#             · mesmo-plugin : o alvo está no MESMO plugin com o prefixo errado
#             · cross-plugin : o alvo está em OUTRO plugin do marketplace
#             · dangling     : o alvo não é distribuído por plugin nenhum (meta-fábrica)
#
# POR QUÊ : medido 2026-09-04 na exploração dos 8 plugins: 544 referências no
#           namespace do core, ZERO na forma do plugin. O lint era cego porque só
#           varre `.claude/` + `docs/` (onde `/engineer:pr` resolve). O consumidor
#           via `/help` listando `/onion-engineering:pr` e o próprio comando mandando
#           rodar `/engineer:pr` — comando que não existe na instalação dele.
#
# A CURA  : determinística, no assembler (`assemble-plugin.sh` → NAMESPACE-PORTABILITY):
#           mesmo-plugin e cross-plugin são REESCRITOS para `/<plugin>:<cmd>` com o
#           MAPA que este helper deriva de TODOS os manifestos (`--map`); dangling
#           perde a barra (`meta:adopt`) e o README do plugin lista "comandos do core
#           citados e não distribuídos" (derivado, content-stable). Por isso a REGRA 72
#           é HARD sem baseline: a cura vive no gerador, não na mão de ninguém.
#
# USO     : plugin-namespace-check.sh [REPO] [--format text|tsv] [--summary]
#           plugin-namespace-check.sh [REPO] --map          # core_form<TAB>plugin<TAB>plugin_form
#           plugin-namespace-check.sh [REPO] --rewrite <DEST> # a CURA (chamada pelo assembler): reescreve in-place
#           plugin-namespace-check.sh --selftest
#
# SAÍDA (tsv): HARD<TAB><classe><TAB><rel-do-arquivo><TAB><mensagem>   · vazio = limpo
# EXIT    : 0 sempre no modo check (o lint decide); --selftest sai 1 se falhar.
#
# Dependências: bash, python3 (a mesma graça do plugin-readme.sh: sem python3 → aviso e vazio).
# =============================================================================
set -u

MODE="check"; FORMAT="text"; SUMMARY=0; REPO=""; REWRITE_DEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --summary) SUMMARY=1; shift ;;
    --map) MODE="map"; shift ;;
    --rewrite) MODE="rewrite"; REWRITE_DEST="${2:-}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'plugin-namespace-check: python3 ausente — varredura pulada (declarado, não silenciado)\n' >&2
  exit 0
fi

# -----------------------------------------------------------------------------
# MAPA: PLUGIN_NAME + COMMANDS[] de cada manifesto (sourced num subshell, como o
# assembler faz). Dir → todos os *.md de dentro (achatado, como o assembler copia).
# Formato: core_form<TAB>plugin<TAB>plugin_form   (core_form: /engineer:pr · /onion · /validate:collab:pair-testing)
# -----------------------------------------------------------------------------
_derive_map() {
  local repo="$1" m name entries e f rel core
  for m in "${repo}"/.claude/utils/marketplace/verticals/*.manifest.sh; do
    [ -f "${m}" ] || continue
    case "$(basename "${m}")" in __*) continue ;; esac
    name="$(bash -c '. "$1" >/dev/null 2>&1; printf "%s" "${PLUGIN_NAME:-}"' _ "${m}")"
    [ -n "${name}" ] || continue
    entries="$(bash -c '. "$1" >/dev/null 2>&1; printf "%s\n" "${COMMANDS[@]:-}"' _ "${m}")"
    while IFS= read -r e; do
      [ -n "${e}" ] || continue
      if [ -d "${repo}/${e}" ]; then
        while IFS= read -r f; do
          case "$(basename "${f}")" in README.md) continue ;; esac
          rel="${f#${repo}/.claude/commands/}"; rel="${rel%.md}"
          core="/${rel//\//:}"
          printf '%s\t%s\t/%s:%s\n' "${core}" "${name}" "${name}" "$(basename "${rel}")"
        done < <(find "${repo}/${e}" -maxdepth 1 -type f -name '*.md' | sort)   # -maxdepth 1 = o `cp dir/*.md` do assembler (subpastas NÃO viajam)
      elif [ -f "${repo}/${e}" ]; then
        rel="${e#.claude/commands/}"; rel="${rel%.md}"
        core="/${rel//\//:}"
        printf '%s\t%s\t/%s:%s\n' "${core}" "${name}" "${name}" "$(basename "${rel}")"
      fi
    done <<< "${entries}"
  done
}

_scan() {
  local repo="$1" fmt="$2" summary="$3"
  _derive_map "${repo}" > "${TMPMAP}"
  python3 - "${repo}" "${TMPMAP}" "${fmt}" "${summary}" <<'PY'
import os, re, sys
repo, mapfile, fmt, summary = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
core = {}
for line in open(mapfile, encoding="utf-8"):
    p = line.rstrip("\n").split("\t")
    if len(p) == 3: core[p[0]] = (p[1], p[2])
# Namespaces = os do core (fixos) ∪ os que o mapa derivou (bancada usa alpha/beta). Token termina em
# [a-z0-9] e não pode preceder `*`/`-` (glob em prosa como `/docs:build-*` não é referência).
CORE_NS = {"meta","engineer","product","git","docs","validate","test","design","development","quick"}
ns = CORE_NS | {k.split(":")[0][1:] for k in core if ":" in k}
NS = "(?:" + "|".join(sorted(re.escape(n) for n in ns)) + ")"
PAT = re.compile(r"(?<![A-Za-z0-9_/.\-])/" + NS + r":[a-z0-9-]*[a-z0-9](?::[a-z0-9-]*[a-z0-9])*(?![A-Za-z0-9*-])")
rows = []
pdir = os.path.join(repo, "plugins")
if os.path.isdir(pdir):
    for plugin in sorted(os.listdir(pdir)):
        root = os.path.join(pdir, plugin)
        if not os.path.isdir(root): continue
        for dp, dn, fn in os.walk(root):
            if "/.claude-plugin" in dp: continue
            for f in sorted(fn):
                if not (f.endswith(".md") or f.endswith(".sh") or f.endswith(".json") or f.endswith(".yaml")): continue
                path = os.path.join(dp, f)
                try: txt = open(path, encoding="utf-8", errors="surrogateescape").read()
                except Exception: continue
                for i, line in enumerate(txt.splitlines(), 1):
                    for m in PAT.finditer(line):
                        ref = m.group(0)
                        if ref in core:
                            tgt, form = core[ref]
                            cls = "mesmo-plugin" if tgt == plugin else "cross-plugin"
                            msg = f"l.{i}: `{ref}` deveria ser `{form}` ({cls}; o namespace do core não resolve no consumidor instalado)"
                        else:
                            cls = "dangling"
                            msg = f"l.{i}: `{ref}` não é distribuído por plugin nenhum — cite sem a barra (`{ref[1:]}`) e deixe o README listar como comando do core"
                        rows.append(("HARD", cls, os.path.relpath(path, repo), msg))
if summary:
    from collections import Counter
    c = Counter(r[1] for r in rows)
    print(f"plugin-namespace: {len(rows)} ref(s) no namespace do core dentro de plugins/ — " + ", ".join(f"{k}={v}" for k, v in sorted(c.items())) if rows else "plugin-namespace: 0 — limpo")
elif fmt == "tsv":
    for r in rows: print("\t".join(r))
else:
    for r in rows: print(f"{r[0]} [{r[1]}] {r[2]}: {r[3]}")
PY
}

# A CURA — mesma regex do scan (um só lugar): mapeado → forma do plugin; dangling → sem a barra.
_rewrite() {
  local repo="$1" dest="$2"
  [ -d "${dest}" ] || { printf 'plugin-namespace-check --rewrite: destino ausente: %s\n' "${dest}" >&2; return 2; }
  _derive_map "${repo}" > "${TMPMAP}"
  python3 - "${dest}" "${TMPMAP}" <<'PY'
import os, re, sys
dest, mapfile = sys.argv[1], sys.argv[2]
core = {}
for line in open(mapfile, encoding="utf-8"):
    p = line.rstrip("\n").split("\t")
    if len(p) == 3: core[p[0]] = p[2]
CORE_NS = {"meta","engineer","product","git","docs","validate","test","design","development","quick"}
ns = CORE_NS | {k.split(":")[0][1:] for k in core if ":" in k}
NS = "(?:" + "|".join(sorted(re.escape(n) for n in ns)) + ")"
PAT = re.compile(r"(?<![A-Za-z0-9_/.\-])/" + NS + r":[a-z0-9-]*[a-z0-9](?::[a-z0-9-]*[a-z0-9])*(?![A-Za-z0-9*-])")
mapped = dangling = 0
def sub(m):
    global mapped, dangling
    ref = m.group(0)
    if ref in core: mapped += 1; return core[ref]
    dangling += 1; return ref[1:]
for dp, dn, fn in os.walk(dest):
    if "/.claude-plugin" in dp: continue
    for f in fn:
        if not (f.endswith(".md") or f.endswith(".sh") or f.endswith(".json") or f.endswith(".yaml")): continue
        path = os.path.join(dp, f)
        try: txt = open(path, encoding="utf-8", errors="surrogateescape").read()
        except Exception: continue
        new = PAT.sub(sub, txt)
        if new != txt: open(path, "w", encoding="utf-8", errors="surrogateescape").write(new)
print(f"namespace-portability: {mapped} ref(s) → forma do plugin, {dangling} dangling → sem barra (comando do core, não distribuído)")
PY
}

_selftest() {
  local fails=0 out
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; local d="${SELFTEST_D}"
  mkdir -p "${d}/src/.claude/commands/alpha" "${d}/src/.claude/commands/beta" "${d}/src/.claude/utils/marketplace/verticals" "${d}/src/plugins/probe-a/commands"
  printf -- '---\nname: one\ndescription: x\n---\n' > "${d}/src/.claude/commands/alpha/one.md"
  printf -- '---\nname: two\ndescription: x\n---\n' > "${d}/src/.claude/commands/alpha/two.md"
  printf -- '---\nname: three\ndescription: x\n---\n' > "${d}/src/.claude/commands/beta/three.md"
  printf 'PLUGIN_NAME="probe-a"\nCOMMANDS=(.claude/commands/alpha)\n' > "${d}/src/.claude/utils/marketplace/verticals/probe-a.manifest.sh"
  printf 'PLUGIN_NAME="probe-b"\nCOMMANDS=(.claude/commands/beta/three.md)\n' > "${d}/src/.claude/utils/marketplace/verticals/probe-b.manifest.sh"
  # (a) mapa derivado: dir achatado + arquivo; forma do plugin
  out="$(bash "$0" "${d}/src" --map)"
  if printf '%s\n' "${out}" | grep -q "^/alpha:two	probe-a	/probe-a:two$" && printf '%s\n' "${out}" | grep -q "^/beta:three	probe-b	/probe-b:three$"; then echo "  ✅ (a) mapa derivado dos manifestos (dir achatado + arquivo)"; else echo "  ✗ (a) mapa: ${out}"; fails=$((fails+1)); fi
  # (b) as três classes num arquivo do plugin
  printf 'Rode /alpha:two depois /beta:three e por fim /meta:adopt. URL https://x/meta:nao e path a/meta:nao nao contam.\n' > "${d}/src/plugins/probe-a/commands/one.md"
  out="$(bash "$0" "${d}/src" --format tsv)"
  if [ "$(printf '%s\n' "${out}" | grep -c .)" -eq 3 ] && printf '%s\n' "${out}" | grep -q "mesmo-plugin" && printf '%s\n' "${out}" | grep -q "cross-plugin" && printf '%s\n' "${out}" | grep -q "dangling"; then echo "  ✅ (b) três classes detectadas, URL/path não contam"; else echo "  ✗ (b): ${out}"; fails=$((fails+1)); fi
  # (c) forma do plugin e forma sem barra são limpas
  printf 'Rode /probe-a:two depois /probe-b:three e por fim meta:adopt.\n' > "${d}/src/plugins/probe-a/commands/one.md"
  out="$(bash "$0" "${d}/src" --format tsv)"
  if [ -z "${out}" ]; then echo "  ✅ (c) forma do plugin + dangling sem barra = limpo"; else echo "  ✗ (c): ${out}"; fails=$((fails+1)); fi
  # (e) --rewrite: mapeado vira forma do plugin, dangling perde a barra, URL intacta; idempotente
  printf 'Rode /alpha:two depois /beta:three e por fim /meta:adopt. URL https://x/meta:nao fica.\n' > "${d}/src/plugins/probe-a/commands/one.md"
  bash "$0" "${d}/src" --rewrite "${d}/src/plugins/probe-a" >/dev/null
  out="$(cat "${d}/src/plugins/probe-a/commands/one.md")"
  if [ "${out}" = "Rode /probe-a:two depois /probe-b:three e por fim meta:adopt. URL https://x/meta:nao fica." ]; then echo "  ✅ (e) rewrite: mapeado → plugin, dangling → sem barra, URL intacta"; else echo "  ✗ (e): ${out}"; fails=$((fails+1)); fi
  bash "$0" "${d}/src" --rewrite "${d}/src/plugins/probe-a" >/dev/null
  if [ "$(cat "${d}/src/plugins/probe-a/commands/one.md")" = "${out}" ] && [ -z "$(bash "$0" "${d}/src" --format tsv)" ]; then echo "  ✅ (e2) rewrite idempotente e o scan fica limpo"; else echo "  ✗ (e2)"; fails=$((fails+1)); fi
  # (d) sem plugins/ → vazio, exit 0
  rm -rf "${d}/src/plugins"; out="$(bash "$0" "${d}/src" --format tsv)"; rc=$?
  if [ -z "${out}" ] && [ "${rc}" -eq 0 ]; then echo "  ✅ (d) sem plugins/ = vazio, exit 0"; else echo "  ✗ (d)"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "plugin-namespace-check selftest: OK"; return 0; }
  echo "plugin-namespace-check selftest: ${fails} falha(s)"; return 1
}

TMPMAP="$(mktemp)"; trap 'rm -f "${TMPMAP}"' EXIT
case "${MODE}" in
  map) _derive_map "${REPO}" ;;
  rewrite) _rewrite "${REPO}" "${REWRITE_DEST}" ;;
  selftest) _selftest ;;
  *) _scan "${REPO}" "${FORMAT}" "${SUMMARY}" ;;
esac
