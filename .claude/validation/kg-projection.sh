#!/usr/bin/env bash
# ===========================================================================
# kg-projection.sh — a REGRA 112 (Página com projection_of cita ids que existem nos grafos dela), julgada pelo
# PRODUTO: o `kg_trace.py projection` do kg-ssot (4.35.0, `kg-ssot.projection/1`).
#
# POR QUE EXISTE (deriva medida, 2026-10-27): uma página de contexto (negócio, técnico, design) que declara ser
# projeção de grafos (`projection_of:` no frontmatter) cita ids de nó entre crases; sem checador, um nó renomeado
# ou removido deixava a página citando um id morto. O kg-ssot mediu a deriva nos contextos dele (2 de 6 ids citados
# no design-context não resolviam) e promoveu o checador ao produto. No core, o piloto é o
# docs/design-context/brief.md (onda 1 do design, #1409), e a 1ª medida achou 2 ids em `elsewhere`: o brief
# cita o posicionamento e o público do business-context sem listar aquele grafo no projection_of.
#
# Este script NÃO tem parser: o julgamento é do produto, e o que fica aqui é a tradução do JSON para o TSV do lint.
# Lê o rc e o JSON, nunca a prosa:
#   rc 0|1 + JSON  → um achado por linha do JSON (abaixo)
#   rc 2 ou outro, JSON ilegível, vendor sem o subcomando `projection` (anterior à 4.35.0) ou python3 ausente
#                  → rc 2: NÃO PUDE JULGAR (o lint o diz, nunca verde calado)
# Achados (TSV `SEV·CÓDIGO·caminho·mensagem`):
#   HARD  ID-AUSENTE       integrity.projection-id-missing: o id citado não existe em grafo nenhum do repo
#   HARD  GRAFO-NAO-LIDO   um grafo do projection_of que o produto não leu (rc 1): sem leitura não há veredito
#   SOFT  SEM-CITACAO      `uncited`: a página declara projection_of e não cita id entre crases (nada conferido)
#   SOFT  EM-OUTRO-GRAFO   `elsewhere`: o id existe, mas num grafo que o projection_of não lista
#   SOFT  FORA-DO-REPO     `outside`: o projection_of nomeia por URL um grafo de outro repo, não lido (contado)
#   SOFT  NAO-FIXADO       `unpinned`: o grafo de outro repo foi lido da árvore de trabalho, não do commit da URL
#   rc 1 do produto sem nenhum achado no JSON também é "não pude julgar": o rc e o JSON discordam.
#   Antes do juiz, a descoberta própria (abaixo): sem página com projection_of no disco, rc 0 sem chamar o produto.
#
# Uso : bash .claude/validation/kg-projection.sh [<raiz>] [--format tsv|human]
# Exit: 0 nada a acusar · 1 algum achado · 2 NÃO PUDE JULGAR
# Env : ONION_KG_TRACE — caminho do kg_trace.py (default: <raiz>/vendor/kg-ssot/tools/kg_trace.py; a bancada
#       aponta o do core numa caixa de areia sem vendor).
# Exercitado por lint-selftest.sh (run_kg_projection_selftests); registrado no lint-artifacts.sh (REGRA 112).
# ===========================================================================
set -uo pipefail
ROOT="" FORMAT=human
while [ "$#" -gt 0 ]; do
  case "$1" in
    --format) [ "$#" -ge 2 ] || { echo "kg-projection: --format pede tsv|human" >&2; exit 2; }; FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    -h|--help) sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "kg-projection: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] && ROOT="$1" || { echo "kg-projection: raiz repetida: $1" >&2; exit 2; }; shift ;;
  esac
done
case "${FORMAT}" in tsv|human) : ;; *) echo "kg-projection: --format pede tsv|human" >&2; exit 2 ;; esac
[ -n "${ROOT}" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ -d "${ROOT}" ] || { echo "kg-projection: raiz inexistente: ${ROOT} — não pude julgar" >&2; exit 2; }
ROOT="$(cd "${ROOT}" && pwd)"
command -v python3 >/dev/null 2>&1 || { echo "kg-projection: python3 ausente — não pude julgar" >&2; exit 2; }

# DESCOBERTA PRÓPRIA, antes do juiz (passada adversarial da adoção da 4.35.0, achados 4 e 5): conta no disco as
# páginas .md com `projection_of` no frontmatter (rastreadas e não rastreadas, fora de vendor/ e de fixture).
#   0 páginas          → nada a julgar: rc 0, mesmo sem o produto (o adotante sem projeção não ganha aviso eterno)
#   raiz fora do git   → rc 2: o produto descobre as páginas pelo índice do git e julgaria 0, verde calado
#   o produto julga 0 páginas e o disco tem alguma → rc 2 (VACUIDADE), abaixo
# Teto declarado: página nova NÃO rastreada, num repo que já tem outras rastreadas, não é julgada (o produto lê o
# índice; o pre-commit e o CI veem o arquivo depois do `git add`).
_disc="$(python3 -I -B - "${ROOT}" <<'PY'
import os, re, subprocess, sys
root = sys.argv[1]
out = subprocess.run(["git", "-C", root, "ls-files", "-z", "-co", "--exclude-standard", "--", "*.md"], capture_output=True)
git = out.returncode == 0 and subprocess.run(["git", "-C", root, "rev-parse", "--show-prefix"], capture_output=True).stdout.strip() == b""
if git:
    names = [n for n in out.stdout.decode("utf-8", "surrogateescape").split("\0") if n]
else:
    names = []
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x not in (".git", "node_modules", "vendor")]
        names += [os.path.relpath(os.path.join(d, f), root) for f in files if f.endswith(".md")]
fm = re.compile(r"\A(?:﻿)?---[ \t]*\n(.*?)\n---[ \t]*(?:\n|\Z)", re.S)
key = re.compile(r"^projection_of[ \t]*:", re.M)
n = 0
for name in names:
    if name.startswith("vendor/") or "/vendor/" in name or "fixture" in name:
        continue
    try:
        with open(os.path.join(root, name), encoding="utf-8") as fh:
            head = fh.read(8192)
    except (OSError, UnicodeDecodeError):
        continue
    m = fm.match(head)
    if m and key.search(m.group(1)):
        n += 1
print(f"{n} {'git' if git else 'nogit'}")
PY
)" || { echo "kg-projection: a descoberta das páginas falhou — não pude julgar" >&2; exit 2; }
_npages="${_disc%% *}"
[ "${_npages}" -gt 0 ] 2>/dev/null || exit 0
[ "${_disc#* }" = git ] || { echo "kg-projection: ${_npages} página(s) com projection_of e a raiz não é a raiz de um repo git: o produto lê as páginas rastreadas e julgaria 0 — não pude julgar" >&2; exit 2; }

KT="${ONION_KG_TRACE:-${ROOT}/vendor/kg-ssot/tools/kg_trace.py}"
[ -n "${ONION_KG_TRACE:-}" ] || [ -f "${KT}" ] || [ ! -f "${ROOT}/tools/kg_trace.py" ] || KT="${ROOT}/tools/kg_trace.py"
[ -f "${KT}" ] || { echo "kg-projection: kg_trace.py ausente (${KT}) — o vendor kg-ssot >= 4.35.0 é quem julga a projeção; não pude julgar" >&2; exit 2; }

_kj="$(mktemp)"; _ke="$(mktemp)"; trap 'rm -f "${_kj}" "${_ke}"' EXIT
_krc=0; python3 -I -B "${KT}" projection --root "${ROOT}" --format json >"${_kj}" 2>"${_ke}" || _krc=$?
case "${_krc}" in
  0|1) : ;;
  *) echo "kg-projection: kg_trace.py projection rc=${_krc} (entrada quebrada, ou vendor anterior à 4.35.0, sem o subcomando): $(head -1 "${_ke}" 2>/dev/null) — não pude julgar" >&2; exit 2 ;;
esac

python3 -I -B - "${_kj}" "${_krc}" "${FORMAT}" "${_npages}" <<'PY'
import json, sys
path, krc, fmt, ndisk = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
try:
    d = json.load(open(path, encoding="utf-8"))
except (OSError, ValueError):
    print("kg-projection: o JSON do kg_trace.py projection não se lê — não pude julgar", file=sys.stderr); sys.exit(2)
if not isinstance(d, dict) or d.get("schema_version") != "kg-ssot.projection/1":
    print(f"kg-projection: schema_version inesperado ({d.get('schema_version') if isinstance(d, dict) else type(d).__name__})"
          " — não pude julgar", file=sys.stderr); sys.exit(2)
if not d.get("pages"):  # VACUIDADE: o disco tem página com projection_of e o produto não leu nenhuma
    print(f"kg-projection: o disco tem {ndisk} página(s) com projection_of e o produto julgou 0 (não rastreadas?) "
          "— não pude julgar", file=sys.stderr); sys.exit(2)
rows = []
for m in d.get("missing") or []:
    rows.append(("HARD", "ID-AUSENTE", m["page"], f"`{m['id']}` não existe em grafo nenhum do repositório "
                 "(integrity.projection-id-missing): o nó foi renomeado ou removido? cite o id vivo"))
for g in d.get("graph_errors") or []:
    rows.append(("HARD", "GRAFO-NAO-LIDO", g["page"], f"o grafo {g['graph']} do projection_of não foi lido: sem leitura "
                 "não há veredito sobre os ids desta página"))
for p in d.get("uncited") or []:
    rows.append(("SOFT", "SEM-CITACAO", p, "declara projection_of e não cita nenhum id entre crases: nada foi conferido "
                 "(o id em texto corrido não é lido)"))
for e in d.get("elsewhere") or []:
    rows.append(("SOFT", "EM-OUTRO-GRAFO", e["page"], f"`{e['id']}` está em {', '.join(e.get('graphs') or [])}, que o "
                 "projection_of não lista: liste o grafo ou cite o id do grafo certo"))
for o in d.get("outside") or []:
    rows.append(("SOFT", "FORA-DO-REPO", o["page"], f"`{o['id']}`: o projection_of nomeia por URL um grafo de outro "
                 f"repositório ({', '.join(o.get('declared') or [])}) que não foi lido (--with): contado, não julgado"))
for u in d.get("unpinned") or []:
    rows.append(("SOFT", "NAO-FIXADO", "-", f"{u}: lido da árvore de trabalho, não do commit da URL"))
if krc == 1 and not any(r[0] == "HARD" for r in rows):
    print("kg-projection: o produto saiu rc 1 e o JSON não traz id ausente nem grafo não lido: o rc e o JSON "
          "discordam — não pude julgar", file=sys.stderr); sys.exit(2)
for sev, code, pg, msg in rows:
    if fmt == "tsv":
        print(f"{sev}\t{code}\t{pg}\t{msg}")
    else:
        print(f"  ✗ {sev} [{code}] {pg}: {msg}")
if fmt == "human":
    print(f"kg-projection: {d.get('pages', 0)} página(s), {d.get('cited', 0)} id(s) citado(s), "
          f"{d.get('resolved', 0)} resolvem; {len(rows)} achado(s)")
sys.exit(1 if rows else 0)
PY
