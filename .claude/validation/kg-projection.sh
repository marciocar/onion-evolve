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
#   HARD  ID-AUSENTE       integrity.projection-id-missing: o id citado não existe em grafo nenhum que o produto
#                          leu (os do repo, e os de outro repo que um par --with leu no commit da URL)
#   HARD  GRAFO-NAO-LIDO   um grafo do projection_of que o produto não leu (rc 1): sem leitura não há veredito
#   SOFT  SEM-CITACAO      `uncited`: a página declara projection_of e não cita id entre crases (nada conferido)
#   SOFT  EM-OUTRO-GRAFO   `elsewhere`: o id existe, mas num grafo que o projection_of não lista
#   SOFT  FORA-DO-REPO     `outside`: o projection_of nomeia por URL um grafo de outro repo, não lido (contado)
#   SOFT  NAO-FIXADO       o grafo de outro repo NÃO foi lido no sha fixado: o produto o leu da árvore de trabalho
#                          (`unpinned`: o sha da URL não existe na pasta do par), ou a URL nomeia um ramo e não um
#                          sha (lê a ponta, que anda). HARD com --strict: o lint o passa no core; no derivado tudo é
#                          SOFT no 1º ciclo. É o acordo de transmissão: link entre repos vai fixado no sha.
#   rc 1 do produto sem nenhum achado no JSON também é "não pude julgar": o rc e o JSON discordam.
#   Antes do juiz, a descoberta própria (abaixo): sem página com projection_of no disco, rc 0 sem chamar o produto.
#
# Uso : bash .claude/validation/kg-projection.sh [<raiz>] [--format tsv|human] [--strict] [--with PREFIXO=PASTA]...
# Exit: 0 nada a acusar · 1 algum achado · 2 NÃO PUDE JULGAR
# Env : ONION_KG_TRACE — caminho do kg_trace.py (default: <raiz>/vendor/kg-ssot/tools/kg_trace.py; a bancada
#       aponta o do core numa caixa de areia sem vendor).
#       ONION_KG_PROJECTION_WITH — pares PREFIXO=PASTA, um por linha (a forma que o lint herda do ambiente).
#
# GRAFO DE OUTRO REPOSITÓRIO (proposta da curadoria, emenda G do design-setup-2026-10; absorvida em 2026-10-27).
#   A página cujo projection_of nomeia um grafo por URL (<prefixo>/<sha>/<caminho>) só é JULGADA quando o produto
#   recebe o par --with daquele prefixo: ele lê o grafo NO COMMIT da URL, só leitura (`git show`). Sem o par, sai
#   SOFT FORA-DO-REPO, e um id morto lá passa sem veredito. Os pares vêm de dois lugares (o 1º vence no prefixo):
#     1. --with PREFIXO=PASTA (repetível) e ONION_KG_PROJECTION_WITH: é assim que o ADOTANTE declara os seus;
#     2. o registro da federação <raiz>/docs/evolution/federation/members.yaml, que só o core tem: o membro com
#        `remote: github.com/<dono>/<repo>` dá o par https://github.com/<dono>/<repo>/blob=<local_path>. Só entra
#        o par cujo prefixo alguma página declara. Sem o arquivo não há erro: valem só os pares do item 1.
#   Exemplo, no adotante cuja página cita um grafo do core e tem o clone do core ao lado:
#     ONION_KG_PROJECTION_WITH='https://github.com/marciocar/onion-evolve/blob=../onion-evolve' \
#       bash .claude/validation/kg-projection.sh
#     e, no frontmatter da página:
#     projection_of: [https://github.com/marciocar/onion-evolve/blob/<sha>/docs/onion/graph/<grafo>.kg.yaml]
#   Segurança: forma ruim (sem "=", prefixo fora de https://, pasta vazia) → rc 2. PASTA que não existe ou não é
#   repo git (o CI, sem o clone do par) → aviso nomeado no stderr, o par NÃO vai ao produto e a página segue
#   FORA-DO-REPO: nunca HARD por falta de clone, nunca verde calado. Sem par nenhum, o comportamento é o de antes.
#   Vence, por prefixo, o 1º candidato que tem clone (o explícito antes do registro); o par cujo prefixo nenhuma
#   página declara não vai nem avisa. Clone que não tem o commit da URL: o produto lê a árvore de lá, sai
#   NAO-FIXADO, e o ID-AUSENTE daquela página cai a SOFT (julgado contra a versão errada, sem veredito firme).
#   Teto declarado: do registro só deriva o forge github.com (o /blob/ é dele); outro forge entra pelo item 1. O
#   par só aceita prefixo https:// (o produto aceita qualquer "://"): URL de outro esquema segue FORA-DO-REPO.
#   Além do JSON, este script lê as URLs do projection_of (yaml.safe_load do frontmatter, a leitura do produto)
#   para filtrar os pares e ver o ramo no lugar do sha; o julgamento dos ids segue do produto.
# Exercitado por lint-selftest.sh (run_kg_projection_selftests); registrado no lint-artifacts.sh (REGRA 112).
# ===========================================================================
set -uo pipefail
ROOT="" FORMAT=human STRICT=0
WITHS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --with) [ "$#" -ge 2 ] || { echo "kg-projection: --with pede PREFIXO=PASTA" >&2; exit 2; }; WITHS+=("$2"); shift 2 ;;
    --with=*) WITHS+=("${1#--with=}"); shift ;;
    --strict) STRICT=1; shift ;;
    --format) [ "$#" -ge 2 ] || { echo "kg-projection: --format pede tsv|human" >&2; exit 2; }; FORMAT="$2"; shift 2 ;;
    --format=*) FORMAT="${1#--format=}"; shift ;;
    -h|--help) sed -n '2,/^# =====/p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0 ;;
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
n, urls = 0, []
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
        # as URLs do projection_of, lidas como o produto as lê (yaml.safe_load do frontmatter, e a entrada com
        # "://" é URL): servem para filtrar os pares e para ver o ramo no lugar do sha; os ids seguem do produto.
        # Comentário YAML não é URL (passada adversarial, achado 1). Sem PyYAML o produto não roda, e sem a
        # leitura as URLs ficam de fora: nenhum NAO-FIXADO inventado, e o rc 2 do produto diz o resto.
        try:
            import yaml
            meta = yaml.safe_load(m.group(1))
        except Exception:
            meta = None
        decl = meta.get("projection_of") if isinstance(meta, dict) else None
        for url in ([decl] if isinstance(decl, str) else decl if isinstance(decl, list) else []):
            if isinstance(url, str) and "://" in url.strip():
                urls.append(f"{url.strip()}\t{name}")
print(f"{n} {'git' if git else 'nogit'}")
print("\n".join(urls))
PY
)" || { echo "kg-projection: a descoberta das páginas falhou — não pude julgar" >&2; exit 2; }
_urls="$(sed '1d' <<< "${_disc}")"; _disc="$(head -1 <<< "${_disc}")"
_npages="${_disc%% *}"
[ "${_npages}" -gt 0 ] 2>/dev/null || exit 0
[ "${_disc#* }" = git ] || { echo "kg-projection: ${_npages} página(s) com projection_of e a raiz não é a raiz de um repo git: o produto lê as páginas rastreadas e julgaria 0 — não pude julgar" >&2; exit 2; }

KT="${ONION_KG_TRACE:-${ROOT}/vendor/kg-ssot/tools/kg_trace.py}"
[ -n "${ONION_KG_TRACE:-}" ] || [ -f "${KT}" ] || [ ! -f "${ROOT}/tools/kg_trace.py" ] || KT="${ROOT}/tools/kg_trace.py"
[ -f "${KT}" ] || { echo "kg-projection: kg_trace.py ausente (${KT}) — o vendor kg-ssot >= 4.35.0 é quem julga a projeção; não pude julgar" >&2; exit 2; }

_kj="$(mktemp)"; _ke="$(mktemp)"; _kp="$(mktemp)"; trap 'rm -f "${_kj}" "${_ke}" "${_kp}"' EXIT

# OS PARES --with (cabeçalho, "GRAFO DE OUTRO REPOSITÓRIO"): os explícitos (--with e ONION_KG_PROJECTION_WITH)
# vencem os derivados do registro no mesmo prefixo. Sai em ${_kp}: `W<TAB>PREFIXO=PASTA` (vai ao produto) e
# `B<TAB>URL<TAB>página` (a URL coberta por um par nomeia um ramo, não um sha). rc 2: forma ruim.
if [ -n "${ONION_KG_PROJECTION_WITH:-}" ]; then
  while IFS= read -r _w; do [ -n "${_w//[[:space:]]/}" ] && WITHS+=("${_w}"); done <<< "${ONION_KG_PROJECTION_WITH}"
fi
python3 -I -B - "${ROOT}/docs/evolution/federation/members.yaml" "${_urls}" ${WITHS[@]+"${WITHS[@]}"} >"${_kp}" <<'PY' \
  || { _prc=$?; [ "${_prc}" = 2 ] || echo "kg-projection: os pares --with não se montaram (rc=${_prc}) — não pude julgar" >&2; exit 2; }
import os, re, subprocess, sys
members, urls, explicit = sys.argv[1], sys.argv[2], sys.argv[3:]
declared = [ln.split("\t", 1) for ln in urls.split("\n") if "\t" in ln]
for _u, _pg in declared:
    print(f"D\t{_u}\t{_pg}")
def warn(msg):
    print(f"kg-projection: aviso: {msg}", file=sys.stderr)
def is_git(folder):
    return subprocess.run(["git", "-C", folder, "rev-parse", "--git-dir"], capture_output=True).returncode == 0
pairs = {}  # prefixo → [(pasta, origem)], na ordem: explícitos primeiro; vence o 1º que tem clone
for w in explicit:
    prefix, sep, folder = w.strip().partition("=")
    prefix = prefix.rstrip("/")
    if not sep or not folder or not prefix.startswith("https://") or len(prefix) <= len("https://"):
        print(f"kg-projection: --with pede PREFIXO=PASTA com o prefixo em https:// (recebi: {w!r}) — não pude julgar",
              file=sys.stderr)
        sys.exit(2)
    pairs.setdefault(prefix, []).append((folder, "--with"))
used = lambda p: any(u.startswith(p + "/") for u, _pg in declared)
if declared and os.path.isfile(members):
    try:
        import yaml
        reg = yaml.safe_load(open(members, encoding="utf-8")) or {}
        rows = (reg.get("members") or []) if isinstance(reg, dict) else []
    except Exception as exc:  # o registro que não se lê não derruba o juízo: valem os pares explícitos
        warn(f"o registro {members} não se leu ({type(exc).__name__}); os pares dele não entram")
        rows = []
    for mb in rows:
        if not isinstance(mb, dict):
            continue
        remote, local = str(mb.get("remote") or "").strip(), str(mb.get("local_path") or "").strip()
        if not re.fullmatch(r"github\.com/[\w.-]+/[\w.-]+", remote) or not local:
            continue
        prefix = f"https://{remote}/blob"  # na ordem do arquivo: o mesmo remoto em dois membros = dois clones
        pairs.setdefault(prefix, []).append((local, f"members.yaml ({mb.get('id', '?')})"))
for prefix, cands in pairs.items():
    if not used(prefix):  # par que nenhuma página declara: não vai, nem avisa (achado 3)
        continue
    folder = next((f for f, _o in cands if os.path.isdir(f) and is_git(f)), None)
    if folder is None:
        tried = "; ".join(f"{f} (de {o})" for f, o in cands)
        warn(f"o par {prefix} não vai ao produto: nenhuma pasta é um repo git ({tried}), sem o clone do par; "
             "a página que cita esse prefixo segue FORA-DO-REPO")
        continue
    print(f"W\t{prefix}={folder}")
    for url, page in declared:
        if url.startswith(prefix + "/"):
            ref = url[len(prefix) + 1:].split("/", 1)[0]
            if not re.fullmatch(r"[0-9a-fA-F]{7,40}", ref):
                print(f"B\t{url}\t{page}")
PY
_wargs=()
while IFS=$'\t' read -r _k _v _; do [ "${_k}" = W ] && _wargs+=("--with=${_v}"); done < "${_kp}"
_krc=0; python3 -I -B "${KT}" projection --root "${ROOT}" --format json ${_wargs[@]+"${_wargs[@]}"} >"${_kj}" 2>"${_ke}" || _krc=$?
case "${_krc}" in
  0|1) : ;;
  *) echo "kg-projection: kg_trace.py projection rc=${_krc} (entrada quebrada, ou vendor anterior à 4.35.0, sem o subcomando): $(head -1 "${_ke}" 2>/dev/null) — não pude julgar" >&2; exit 2 ;;
esac

python3 -I -B - "${_kj}" "${_krc}" "${FORMAT}" "${_npages}" "${STRICT}" "${_kp}" <<'PY'
import json, sys
path, krc, fmt, ndisk = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
strict, pairs_file = sys.argv[5] == "1", sys.argv[6]
kp = [ln.rstrip("\n").split("\t") for ln in open(pairs_file, encoding="utf-8")]
branch = [r[1:3] for r in kp if r[0] == "B" and len(r) >= 3]
page_of = {}
for r in kp:  # a 1ª página que declara a URL dá o caminho do NAO-FIXADO (o JSON do produto só traz a URL)
    if r[0] == "D" and len(r) >= 3:
        page_of.setdefault(r[1], r[2])
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
# a página que declara um grafo de outro repo lido FORA do sha (unpinned: o clone não tem o commit) teve os ids
# julgados contra a árvore de lá, não contra o commit da URL: o ID-AUSENTE dela sai SOFT (sem veredito firme), e
# quem barra é o NAO-FIXADO abaixo (passada adversarial, achado 2: o clone desatualizado não vira HARD de id)
unpinned = list(d.get("unpinned") or [])
loose = {r[2] for r in kp if r[0] == "D" and len(r) >= 3 and r[1] in unpinned}
for m in d.get("missing") or []:
    if m["page"] in loose:
        rows.append(("SOFT", "ID-AUSENTE", m["page"], f"`{m['id']}` não está no grafo de outro repositório lido FORA do "
                     "sha da URL (o clone do par não tem o commit): sem veredito firme; busque o commit no clone "
                     "(git fetch) e rode de novo (integrity.projection-id-missing)"))
        continue
    rows.append(("HARD", "ID-AUSENTE", m["page"], f"`{m['id']}` não existe em grafo nenhum que o produto leu (os "
                 "deste repositório e os de outro que um par --with leu no commit da URL) "
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
# o rc 1 do produto se confere contra os achados DELE, antes do NAO-FIXADO que o --strict eleva aqui
judged_hard = bool(d.get("missing") or d.get("graph_errors"))
pin_sev = "HARD" if strict else "SOFT"
for u in unpinned:
    rows.append((pin_sev, "NAO-FIXADO", page_of.get(u, "-"), f"{u}: lido da árvore de trabalho, não do commit da URL: "
                 "o sha não existe no clone do par. Ou o sha está errado (fixe num commit que o repositório de lá tem), "
                 "ou o clone não o buscou (git fetch na pasta do par)"))
for u, pg in branch:
    if u not in unpinned:
        rows.append((pin_sev, "NAO-FIXADO", pg, f"{u}: a URL nomeia um ramo, não um sha, e o grafo é lido na ponta "
                     "dele, que anda: link entre repositórios vai fixado no sha"))
if krc == 1 and not judged_hard:
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
