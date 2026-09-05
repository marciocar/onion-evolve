#!/usr/bin/env bash
# =============================================================================
# plugin-dead-link-check.sh — link markdown RELATIVO morto dentro de um plugin (REGRA 75)
#
# O QUE   : em plugins/<p>/**/*.md, um link `[título](caminho-relativo)` cujo alvo NÃO existe dentro
#           do plugin é ponteiro morto no consumidor instalado (o alvo existia no core, ao lado da
#           fonte; no plugin a irmã não viajou). Fora da regra: URLs, caminhos absolutos, `${…}`,
#           âncoras puras (`#x`), padrões regex em prosa (`.*\.md`) e `templates/` (apontam para
#           arquivos que o CONSUMIDOR vai gerar — intencional).
#
# POR QUÊ : medido 2026-09-04: 148 links relativos mortos em 7/8 plugins (commands 46, utils 31, kb 30,
#           templates 24, skills 17). O assembler já curava a classe POR CONSTRUÇÃO — mas só em kb/ e só
#           para irmãs no mesmo diretório (`irma.md`). Esta é a generalização: todo .md do plugin, qualquer
#           caminho relativo. Cura = `--rewrite` (link → texto do título), chamada pelo assembler.
#           HARD sem baseline: a cura vive no gerador.
#
# USO     : plugin-dead-link-check.sh [REPO] [--format text|tsv] [--summary]
#           plugin-dead-link-check.sh [REPO] --rewrite <DEST>     # a CURA (chamada pelo assembler)
#           plugin-dead-link-check.sh --selftest
# SAÍDA   : HARD<TAB>link-morto<TAB><rel><TAB><msg>  · vazio = limpo
# =============================================================================
set -u
MODE="check"; FORMAT="text"; SUMMARY=0; REPO=""; REWRITE_DEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FORMAT="${2:-text}"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    --summary) SUMMARY=1; shift ;;
    --rewrite) MODE="rewrite"; REWRITE_DEST="${2:-}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
command -v python3 >/dev/null 2>&1 || { printf 'plugin-dead-link-check: python3 ausente — varredura pulada\n' >&2; exit 0; }

# Um só motor para scan e rewrite (regex e exclusões num lugar).
_engine() {
  python3 - "$@" <<'PY'
import os, re, sys
mode, root, fmt, summary = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
LINK = re.compile(r'\[([^\[\]]*)\]\(([^)\s]+?)(#[^)]*)?\)')
def skip_target(t):
    return (re.match(r'^[a-z][a-z0-9+.-]*:', t) or t.startswith("/") or "${" in t
            or t.startswith("#") or "*" in t or "\\" in t or t in (".", "./"))
def plugin_dirs(repo):
    pdir = os.path.join(repo, "plugins")
    if not os.path.isdir(pdir): return []
    return [os.path.join(pdir, p) for p in sorted(os.listdir(pdir)) if os.path.isdir(os.path.join(pdir, p))]
def files(proot):
    for dp, dn, fn in os.walk(proot):
        if "/.claude-plugin" in dp or "/templates" in dp: continue
        for f in sorted(fn):
            if f.endswith(".md"): yield os.path.join(dp, f)
def alive(dp, tgt):
    # VIVO = resolve DENTRO do plugin (só o plugin viaja). `../../../docs/x.md` pode existir no core ao lado
    # do plugins/ e não existir no consumidor — e o veredito dependia de ONDE o plugin estava montado (a REGRA 19
    # acusou drift entre a montagem em /tmp e a de plugins/). Medido 2026-09-04.
    resolved = os.path.normpath(os.path.join(dp, tgt))
    if not (resolved == PROOT or resolved.startswith(PROOT + os.sep)): return False
    return os.path.exists(resolved) or os.path.exists(resolved + ".md")
rows = []; rewritten = 0
targets = [root] if mode == "rewrite" else plugin_dirs(root)
for proot in targets:
    PROOT = os.path.normpath(proot)
    for path in files(proot):
        try: txt = open(path, encoding="utf-8", errors="surrogateescape").read()
        except Exception: continue
        dp = os.path.dirname(path)
        def sub(m):
            global rewritten
            title, tgt = m.group(1), m.group(2)
            if skip_target(tgt): return m.group(0)
            if alive(dp, tgt): return m.group(0)
            rewritten += 1; return title
        if mode == "rewrite":
            new = LINK.sub(sub, txt)
            if new != txt: open(path, "w", encoding="utf-8", errors="surrogateescape").write(new)
        else:
            for i, line in enumerate(txt.splitlines(), 1):
                for m in LINK.finditer(line):
                    tgt = m.group(2)
                    if skip_target(tgt): continue
                    if alive(dp, tgt): continue
                    rows.append(("HARD", "link-morto", os.path.relpath(path, os.path.dirname(os.path.dirname(proot))), f"l.{i}: `[{m.group(1)}]({tgt})` — alvo não existe no plugin (a irmã não viajou); o assembler converte em texto"))
if mode == "rewrite":
    print(f"dead-link-portability: {rewritten} link(s) morto(s) → texto do título")
elif summary:
    print(f"plugin-dead-link: {len(rows)} link(s) relativo(s) morto(s) em plugins/" if rows else "plugin-dead-link: 0 — limpo")
elif fmt == "tsv":
    for r in rows: print("\t".join(r))
else:
    for r in rows: print(f"{r[0]} [{r[1]}] {r[2]}: {r[3]}")
PY
}

_selftest() {
  local fails=0 out d
  SELFTEST_D="$(mktemp -d)"; trap 'rm -rf "${SELFTEST_D}"' EXIT; d="${SELFTEST_D}"
  mkdir -p "${d}/r/plugins/p/kb" "${d}/r/plugins/p/commands" "${d}/r/plugins/p/templates"
  printf 'ok\n' > "${d}/r/plugins/p/kb/viva.md"
  printf 'Veja [viva](../kb/viva.md), [morta](../kb/morta.md), [fora](../../../docs/x.md), [url](https://x/y.md), [ancora](#sec), [regex](.*\\.md) e [abs](/etc/x).\n' > "${d}/r/plugins/p/commands/c.md"
  printf 'Template: [gera](../docs/business-context/x.md)\n' > "${d}/r/plugins/p/templates/t.md"
  out="$(bash "$0" "${d}/r" --format tsv)"
  if [ "$(printf '%s\n' "${out}" | grep -c '^HARD')" -eq 2 ] && grep -q 'morta.md' <<< "${out}" && grep -q 'docs/x.md' <<< "${out}"; then echo "  ✅ (a) 2 mortos (irmã ausente, fora do plugin); URL/âncora/regex/abs/templates não contam"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  bash "$0" "${d}/r" --rewrite "${d}/r/plugins/p" >/dev/null
  out="$(cat "${d}/r/plugins/p/commands/c.md")"
  if [ "${out}" = 'Veja [viva](../kb/viva.md), morta, fora, [url](https://x/y.md), [ancora](#sec), [regex](.*\.md) e [abs](/etc/x).' ] && [ -z "$(bash "$0" "${d}/r" --format tsv)" ]; then echo "  ✅ (b) rewrite: só os mortos viram texto; scan limpo depois"; else echo "  ✗ (b): ${out}"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "plugin-dead-link-check selftest: OK"; return 0; }
  echo "plugin-dead-link-check selftest: ${fails} falha(s)"; return 1
}

case "${MODE}" in
  selftest) _selftest ;;
  rewrite) [ -d "${REWRITE_DEST}" ] || { printf 'destino ausente: %s\n' "${REWRITE_DEST}" >&2; exit 2; }; _engine rewrite "${REWRITE_DEST}" text 0 ;;
  *) _engine check "${REPO}" "${FORMAT}" "${SUMMARY}" ;;
esac
