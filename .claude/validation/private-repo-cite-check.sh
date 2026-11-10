#!/usr/bin/env bash
# private-repo-cite-check.sh — REGRA 121: grafo NOVO ou TOCADO não cita repositório não conferível por terceiro.
#
# POR QUE EXISTE (defeito datado, 2026-11-10). O core é público desde 2026-10-13. O kg-ssot mediu na HEAD
# ccd34171d (grafo private-cite-salt-url-2026-11, nó E_CORE_PUBLIC_CITES_PRIVATE_REPOS_1110): 43 nós com
# `provenance.source` em URL de repositório privado ou inalcançável, em 15 arquivos (47 contando `trace` e
# `narrative`), e mais dez arquivos citando um deles por `repo@sha` sem URL. Nome e caminho já estão no
# histórico público, e nada impedia a 44ª citação. Decisão do maestro de 2026-11-10, «Guarda + omitir no
# futuro»: uma guarda que AVISA quando grafo novo ou tocado cita repo privado ou inalcançável; citação
# futura omite URL e hash, com a classe «não conferível por terceiro»; o histórico fica como está.
#
# O QUE ELA JULGA: os .kg.yaml que o diff contra a base (merge-base com origin/main, em cascata) toca ou
# acrescenta, fora de vendor e fixture. Em cada um, todo texto dos nós (e o que fica fora de campo, como
# comentário) é varrido por duas formas de citação de repo de um DONO JULGADO que não está na lista pública:
#   url  — github.com/<dono>/<repo> com ou sem scheme, git@github.com:, ssh://, www., raw.githubusercontent.com,
#          api.github.com/repos/, codeload.github.com; .git e ponto final de frase normalizados; sem caixa;
#   hash — <dono>/<repo>@<sha 7-40> e <repo>@<sha> nu, este só para repo que o members.yaml registra.
# VISIBILIDADE: docs/evolution/federation/public-repos.tsv, versionada e offline (o CI não consulta a rede). Os
# donos julgados são os `owner` da lista mais os donos das URLs do members.yaml. Repo de dono julgado fora
# da lista é "não conferível por terceiro" (privado, inalcançável ou não medido): a guarda não distingue.
#
# SEVERIDADE: citação nova sai SOFT (NAO-CONFERIVEL) — é aviso, por decisão do maestro. A CATRACA é HARD:
# o baseline (docs/evolution/federation/private-repo-cite-baseline.txt) é o passivo contado, e o número dele só cai;
# crescer vs origin/main é afrouxar a régua (CATRACA-VIOLADA), salvo quando a lista pública perdeu repo no
# mesmo diff (um repo virou privado: SOFT CATRACA-POR-VISIBILIDADE). O baseline e a saída tsv guardam o
# repo por HASH curto, nunca o nome: a saída do CI de um repo público é pública.
#
# Uso : bash private-repo-cite-check.sh [<raiz>] [--tsv | --all | --emit-baseline] [--base <ref>] [--show-names]
#       bash private-repo-cite-check.sh [<raiz>] --verify-allowlist   (ONLINE, usa gh; fora do CI)
#       bash private-repo-cite-check.sh --hash-name <nome>   (a linha `private nome#<hash>` para a lista, sem gravar o nome)
#       bash private-repo-cite-check.sh --selftest
# Exit: 0 = ok (ou só aviso) · 1 = catraca violada · 2 = não pôde julgar (NAO VERIFICADO; nunca é verde).
#
# TETO (o que ela não vê): repo de terceiro (dono fora da lista e do members.yaml) que sumiu ou fechou;
#   `<repo>@<sha>` nu de repo que o members.yaml não registra; outras formas de citar (gist, GitLab, nome
#   seguido de "commit abc1234" em prosa, sha sem nome); grafo que o diff não toca; mensagem de commit e
#   corpo de PR; e se a lista pública ainda está certa (isso é o --verify-allowlist, que só roda com rede).
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; MODE="tsvh"; HUMAN=1; BASE_REF=""; SHOW=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="touched"; HUMAN=0; shift ;;
    --all) MODE="all"; shift ;;
    --emit-baseline|--emit) MODE="emit"; shift ;;
    --verify-allowlist) MODE="verify"; shift ;;
    --hash-name) MODE="hashname"; export PRC_NAME="${2:?--hash-name exige o nome}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    --show-names) SHOW=1; shift ;;
    --base) BASE_REF="${2:?--base exige ref}"; shift 2 ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done
[ "${MODE}" = "tsvh" ] && MODE="touched"

command -v python3 >/dev/null 2>&1 || { echo "private-repo-cite: python3 ausente — NAO VERIFICADO" >&2; exit 2; }
python3 -c 'import yaml' 2>/dev/null || { echo "private-repo-cite: PyYAML ausente — NAO VERIFICADO" >&2; exit 2; }

ALLOW_REL="docs/evolution/federation/public-repos.tsv"
BASE_REL="docs/evolution/federation/private-repo-cite-baseline.txt"
MEMBERS_REL="docs/evolution/federation/members.yaml"
_TMP="$(mktemp -d)" || { echo "private-repo-cite: mktemp falhou — NAO VERIFICADO" >&2; exit 2; }
trap 'rm -rf "${_TMP}"' EXIT
: > "${_TMP}/files"; : > "${_TMP}/prev_base"; : > "${_TMP}/prev_allow"

if [ "${MODE}" != "selftest" ] && [ "${MODE}" != "hashname" ]; then
  [ -n "${ROOT}" ] || ROOT="$(pwd)"
  command -v git >/dev/null 2>&1 || { echo "private-repo-cite: git ausente — NAO VERIFICADO" >&2; exit 2; }
  _top="$(git -C "${ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "${_top}" ] || { echo "private-repo-cite: '${ROOT}' não é repositório git — NAO VERIFICADO" >&2; exit 2; }
  ROOT="${_top}"
  [ -f "${ROOT}/${ALLOW_REL}" ] || { echo "private-repo-cite: a lista pública (${ALLOW_REL}) não existe — NAO VERIFICADO" >&2; exit 2; }
  _KFP="${_HERE}/kg-fixture-paths.sh"
  [ -f "${_KFP}" ] || { echo "private-repo-cite: predicado de fixture ausente (${_KFP}) — NAO VERIFICADO" >&2; exit 2; }
  # shellcheck source=kg-fixture-paths.sh
  . "${_KFP}"
  # a base: merge-base com origin/main, em cascata (o mesmo arranjo da REGRA 119)
  base=""
  if [ -n "${BASE_REF}" ]; then base="$(git -C "${ROOT}" merge-base "${BASE_REF}" HEAD 2>/dev/null || true)"
  else
    for ref in origin/main main origin/master; do
      base="$(git -C "${ROOT}" merge-base "${ref}" HEAD 2>/dev/null || true)"; [ -n "${base}" ] && break
    done
  fi
  if [ "${MODE}" = "touched" ]; then
    [ -n "${base}" ] || { echo "private-repo-cite: nenhuma base resolvível (origin/main, main, origin/master) — NAO VERIFICADO" >&2; exit 2; }
    { git -C "${ROOT}" diff --name-only --no-renames -z "${base}" -- '*.kg.yaml' \
      && git -C "${ROOT}" ls-files --others --exclude-standard -z -- '*.kg.yaml'; } > "${_TMP}/files" 2>"${_TMP}/err" \
      || { echo "private-repo-cite: git diff falhou: $(head -1 "${_TMP}/err") — NAO VERIFICADO" >&2; exit 2; }
  fi
  # o corpus inteiro: é o conjunto julgado fora do modo touched, e é de onde se derivam os nomes nus privados
  git -C "${ROOT}" ls-files -z -- '*.kg.yaml' > "${_TMP}/all_files" 2>"${_TMP}/err" \
    || { echo "private-repo-cite: git ls-files falhou — NAO VERIFICADO" >&2; exit 2; }
  [ "${MODE}" = "touched" ] || cp "${_TMP}/all_files" "${_TMP}/files"
  # a catraca compara com a ponta de origin/main (não com o merge-base), como a REGRA 99
  if git -C "${ROOT}" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
    git -C "${ROOT}" show "origin/main:${BASE_REL}" > "${_TMP}/prev_base" 2>/dev/null || : > "${_TMP}/prev_base"
    git -C "${ROOT}" show "origin/main:${ALLOW_REL}" > "${_TMP}/prev_allow" 2>/dev/null || : > "${_TMP}/prev_allow"
    git -C "${ROOT}" cat-file -e "origin/main:${BASE_REL}" 2>/dev/null && echo 1 > "${_TMP}/has_prev"
  fi
fi

KG_FIXTURE_RE="${KG_FIXTURE_RE:-x^}" python3 -I -B - "${ROOT:-.}" "${MODE}" "${ALLOW_REL}" "${BASE_REL}" "${MEMBERS_REL}" "${_TMP}" "${SHOW}" "${HUMAN}" <<'PY'
import hashlib, os, re, subprocess, sys
import yaml
root, mode, allow_rel, base_rel, members_rel, tmp, show, human = sys.argv[1:9]
show, human = show == "1", human == "1"

# ── a CLASSE (o vocabulário é o defeito dominante: cada forma tem caso no --selftest e mutante na bancada) ──
URL_RE = re.compile(
    r"(?<![A-Za-z0-9.\-])"                                   # fronteira do host: docs.github.com NÃO é github.com
    r"(?:(?:https?|ssh|git)://)?(?:[A-Za-z0-9_.\-]+@)?(?:www\.)?"
    r"(?:github\.com[/:]|raw\.githubusercontent\.com/|api\.github\.com/repos/|codeload\.github\.com/)"
    r"([A-Za-z0-9](?:[A-Za-z0-9\-]{0,38}))/([A-Za-z0-9_.\-]+)", re.I)
HASH_RE = re.compile(
    r"(?:([A-Za-z0-9](?:[A-Za-z0-9\-]{0,38}))/)?([A-Za-z0-9_.\-]+?)@([0-9a-f]{7,40})(?![0-9A-Za-z])", re.I)   # sem lookbehind: a gula do motor já começa no token inteiro

def norm(repo):
    r = repo.lower().rstrip(".")                             # ponto final de frase
    if r.endswith(".git"):
        r = r[:-4]
    return r

def find(text, owners, public, private_names):
    """[(forma, 'dono/repo')] das citações não conferíveis no texto."""
    out = []
    for m in URL_RE.finditer(text):
        o, r = m.group(1).lower(), norm(m.group(2))
        if r and o in owners and f"{o}/{r}" not in public:
            out.append(("url", f"{o}/{r}"))
    for m in HASH_RE.finditer(text):
        o, r = (m.group(1) or "").lower(), norm(m.group(2))
        if o:
            if o in owners and f"{o}/{r}" not in public:
                out.append(("hash", f"{o}/{r}"))
        elif r in private_names:
            out.append(("hash", private_names[r]))
    return out

def walk(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from walk(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from walk(v)

def scan_text(txt, owners, public, private_names):
    """(hits, erro): hits = {(nó, forma, dono/repo)}; o que só aparece fora de campo vira nó '<fora-de-campo>'."""
    try:
        doc = yaml.safe_load(txt)
    except yaml.YAMLError as e:
        return set(), f"YAML inválido: {str(e).splitlines()[0]}"
    hits = set()
    if isinstance(doc, dict):
        for k, v in doc.items():
            if k == "nodes" and isinstance(v, list):
                for n in v:
                    nid = str(n.get("id", "?")) if isinstance(n, dict) else "?"
                    for s in walk(n):
                        for form, repo in find(s, owners, public, private_names):
                            hits.add((nid, form, repo))
            else:
                for s in walk(v):
                    for form, repo in find(s, owners, public, private_names):
                        hits.add((f"<{k}>", form, repo))
    seen = {(f, r) for _, f, r in hits}
    for form, repo in find(txt, owners, public, private_names):   # comentário e o que o parse não guarda
        if (form, repo) not in seen:
            hits.add(("<fora-de-campo>", form, repo)); seen.add((form, repo))
    return hits, None

def rhash(repo):
    return "repo#" + hashlib.sha256(repo.encode()).hexdigest()[:12]

def nhash(name):
    return "nome#" + hashlib.sha256(name.lower().encode()).hexdigest()[:12]

def load_allow(text):
    owners, public, phash = set(), set(), set()
    for line in text.splitlines():
        c = line.rstrip("\n").split("\t")
        if c[0] == "owner" and len(c) >= 2 and c[1].strip():
            owners.add(c[1].strip().lower())
        elif c[0] == "public" and len(c) >= 2 and "/" in c[1]:
            public.add(c[1].strip().lower())
        elif c[0] == "private" and len(c) >= 2 and c[1].startswith("nome#"):
            phash.add(c[1].strip())
    return owners, public, phash

def url_repos(text):
    return {(o.lower(), norm(r)) for o, r in re.findall(r"github\.com[/:]([A-Za-z0-9\-]+)/([A-Za-z0-9_.\-]+)", text)}

class PrivateNames(dict):
    """nome nu → rótulo. Fontes: o members.yaml, as URLs de dono julgado no corpus e os `private nome#<hash>` da lista."""
    def __init__(self, names, phash):
        super().__init__(names); self.phash = phash
    def __contains__(self, r):
        return dict.__contains__(self, r) or nhash(r) in self.phash
    def __getitem__(self, r):
        return dict.get(self, r) or f"<nome-nu>/{r}"

def derive(allow_text, members_text, corpus_text=""):
    owners, public, phash = load_allow(allow_text)
    mrep = url_repos(members_text)
    owners |= {o for o, _ in mrep}
    mrep |= {(o, r) for o, r in url_repos(corpus_text) if o in owners}
    names = {r: f"{o}/{r}" for o, r in sorted(mrep) if f"{o}/{r}" not in public}
    return owners, public, PrivateNames(names, phash)

# ══ --selftest: as DUAS POLARIDADES, verbatim das formas medidas ═══════════════════════════════════════════
if mode == "selftest":
    allow = f"owner\tdonoteste\npublic\tdonoteste/repo-publico\t2026-11-10\nprivate\t{nhash('clone-medido')}\t2026-11-10\n"
    members = "url: https://github.com/donoteste/repo-secreto\nurl: https://github.com/dono2/outro-privado\nurl: https://github.com/donoteste/repo-publico\n"
    corpus = "source: https://github.com/donoteste/visto-no-corpus/blob/x\nsource: https://github.com/terceiro/lib-alheia\n"
    owners, public, pn = derive(allow, members, corpus)
    ok = bad = 0
    def check(name, text, want):
        global ok, bad
        got = find(text, owners, public, pn)
        good = (want in [f for f, _ in got]) if want else (got == [])
        if good:
            ok += 1; print(f"  ✅ {name}")
        else:
            bad += 1; print(f"  ✗ {name} — esperava {want or 'SILÊNCIO'}, veio {got}")
    # ── acusa ────────────────────────────────────────────────────────────────────────────────────────────
    check("acusa: URL https com blob e sha (a forma medida em provenance.source)", "https://github.com/donoteste/repo-secreto/blob/abc1234/docs/x.md", "url")
    check("acusa: URL sem scheme", "lido em github.com/donoteste/repo-secreto/tree/main", "url")
    check("acusa: git@github.com: (clone ssh)", "git clone git@github.com:donoteste/repo-secreto.git", "url")
    check("acusa: ssh://git@github.com/", "ssh://git@github.com/donoteste/repo-secreto", "url")
    check("acusa: www.github.com", "https://www.github.com/donoteste/repo-secreto", "url")
    check("acusa: raw.githubusercontent.com", "https://raw.githubusercontent.com/donoteste/repo-secreto/main/x.md", "url")
    check("acusa: api.github.com/repos/", "GET https://api.github.com/repos/donoteste/repo-secreto/commits", "url")
    check("acusa: codeload.github.com", "https://codeload.github.com/donoteste/repo-secreto/tar.gz/main", "url")
    check("acusa: caixa diferente (o GitHub não distingue)", "https://github.com/DonoTeste/Repo-Secreto", "url")
    check("acusa: ponto final de frase colado no nome", "veja github.com/donoteste/repo-secreto.", "url")
    check("acusa: dono derivado do members.yaml, fora da lista", "https://github.com/dono2/outro-privado/pull/3", "url")
    check("acusa: dono/repo@sha:caminho, sem URL", "donoteste/repo-secreto@abc1234:docs/x.md", "hash")
    check("acusa: repo@sha nu de repo do members.yaml (sha de 40)", "repo-secreto@0123456789abcdef0123456789abcdef01234567:x", "hash")
    check("acusa: repo@sha nu entre parênteses", "(repo-secreto@abc1234)", "hash")
    check("acusa: caminho do clone com sha (~/<nome>@sha)", "rodado em ~/repo-secreto@abc1234", "hash")
    check("acusa: repo de dono julgado que a lista não conhece", "https://github.com/donoteste/nunca-medido", "url")
    check("acusa: repo@sha nu de repo que o corpus cita por URL (forma dominante: 84 no corpus)", "visto-no-corpus@abc1234:x", "hash")
    check("acusa: repo@sha nu de nome privado medido, que a lista guarda por hash", "clone-medido@abc1234:docs/x.md", "hash")
    check("acusa: nome medido em caixa diferente", "Clone-Medido@abc1234", "hash")
    # ── cala ─────────────────────────────────────────────────────────────────────────────────────────────
    check("cala: repo público da lista", "https://github.com/donoteste/repo-publico/blob/abc1234/x.md", None)
    check("cala: público com .git", "git clone https://github.com/donoteste/repo-publico.git", None)
    check("cala: público com ponto final", "veja github.com/donoteste/repo-publico.", None)
    check("cala: docs.github.com não é github.com (fronteira do host)", "https://docs.github.com/en/repositories/x", None)
    check("cala: api.github.com fora de /repos/", "https://api.github.com/users/donoteste", None)
    check("cala: repo de terceiro", "https://github.com/anthropics/claude-code/issues/1", None)
    check("cala: público@sha nu", "repo-publico@abc1234:x", None)
    check("cala: arquivo@sha", "server.py@abc1234 e lint-artifacts.sh@0a1b2c3", None)
    check("cala: terceiro/repo@sha", "terceiro/claude-code-action@abc1234", None)
    check("cala: forma omitida, nome sem URL nem hash", "repositório privado repo-secreto (não conferível por terceiro)", None)
    check("cala: repo@tag não é sha", "repo-secreto@v1.2.3", None)
    check("cala: e-mail com cara de sha não é repo do registro", "fulano@facade1 escreveu", None)
    check("cala: gist (teto declarado)", "https://gist.github.com/donoteste/abc123", None)
    check("cala: nome@sha de terceiro visto no corpus (dono não julgado)", "lib-alheia@abc1234", None)
    check("cala: público em caixa diferente", "https://github.com/DonoTeste/Repo-Publico", None)
    check("cala: terceiro/<nome do registro>@sha (o dono é outro)", "x/repo-secreto@abc1234", None)
    check("cala: @ seguido de hex e letra não é sha", "repo-secreto@abcdef1234zz", None)
    check("cala: palavra@sha que não é nome medido (grafo@, core@, develop@)", "grafo@abc1234 core@0a1b2c3 develop@1234567", None)
    # ── o grafo: campo, fora de campo e chave do nó ─────────────────────────────────────────────────────
    g = ("meta:\n  id: t\n# fonte antiga: https://github.com/donoteste/repo-secreto\nnodes:\n"
         "  - id: E_A\n    provenance:\n      source: \"https://github.com/donoteste/repo-secreto/blob/abc1234/x\"\n"
         "  - id: E_B\n    trace:\n      - \"repo-secreto@abc1234:y\"\n  - id: E_C\n    label: \"https://github.com/donoteste/repo-publico\"\n")
    h, err = scan_text(g, owners, public, pn)
    want = {("E_A", "url", "donoteste/repo-secreto"), ("E_B", "hash", "donoteste/repo-secreto")}
    if err is None and h == want:
        ok += 1; print("  ✅ grafo: acusa E_A (url) e E_B (hash), cala E_C (público)")
    else:
        bad += 1; print(f"  ✗ grafo — veio {h} err={err}")
    h2, _ = scan_text("meta:\n  id: t\n# fonte: https://github.com/donoteste/repo-secreto\nnodes: []\n", owners, public, pn)
    if h2 == {("<fora-de-campo>", "url", "donoteste/repo-secreto")}:
        ok += 1; print("  ✅ grafo: citação só em comentário acusa como <fora-de-campo>")
    else:
        bad += 1; print(f"  ✗ comentário — veio {h2}")
    _, e3 = scan_text("nodes: [\n", owners, public, pn)
    if e3:
        ok += 1; print("  ✅ grafo: YAML inválido devolve erro (não é aprovação)")
    else:
        bad += 1; print("  ✗ YAML inválido passou sem erro")
    print(f"private-repo-cite selftest: {ok} passaram, {bad} falharam")
    sys.exit(1 if bad else 0)

# ══ produção ════════════════════════════════════════════════════════════════════════════════════════════
def rd(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return ""
if mode == "hashname":
    # imprime a linha da lista para um nome privado medido, sem gravar o nome em lugar nenhum
    print(f"private\t{nhash(os.environ['PRC_NAME'].strip())}\t" + subprocess.run(["date", "+%F"], capture_output=True, text=True).stdout.strip())
    sys.exit(0)
fix = re.compile(os.environ["KG_FIXTURE_RE"])
def kg_list(name):
    raw = open(os.path.join(tmp, name), "rb").read().split(b"\0")
    fs = sorted({p.decode("utf-8", "surrogateescape") for p in raw if p})
    return [f for f in fs if not fix.search(f) and not f.startswith("vendor/") and os.path.isfile(os.path.join(root, f))]
allow_text = rd(os.path.join(root, allow_rel))
corpus_text = "\n".join(rd(os.path.join(root, f)) for f in kg_list("all_files"))
owners, public, pn = derive(allow_text, rd(os.path.join(root, members_rel)), corpus_text)
if not owners:
    print(f"private-repo-cite: a lista pública não declara nenhum `owner` e o members.yaml não deu dono — NAO VERIFICADO", file=sys.stderr)
    sys.exit(2)

if mode == "verify":
    # ONLINE (gh): a lista ainda está certa? e o que o corpus cita fora dela, o que é?
    import shutil
    if not shutil.which("gh"):
        print("private-repo-cite: gh ausente — a lista NÃO foi reconferida", file=sys.stderr); sys.exit(2)
    def vis(repo):
        p = subprocess.run(["gh", "repo", "view", repo, "--json", "visibility", "-q", ".visibility"], capture_output=True, text=True)
        return p.stdout.strip() if p.returncode == 0 else "INALCANCAVEL"
    rc = 0
    for repo in sorted(public):
        v = vis(repo)
        if v != "PUBLIC":
            rc = 1; print(f"LISTA-ERRADA\t{repo}\t{v} — saia da lista pública")
    print(f"# {len(public)} repo(s) da lista reconferido(s) contra o GitHub")
    sys.exit(rc)

files = kg_list("files")

acc, unread = [], []
for f in files:
    h, err = scan_text(rd(os.path.join(root, f)), owners, public, pn)
    if err:
        unread.append((f, err)); continue
    acc += [(f, n, form, repo) for n, form, repo in sorted(h)]

if mode == "emit":
    print("# private-repo-cite-baseline — o PASSIVO contado da REGRA 121 (citação de repo não conferível por terceiro).")
    print("# Gerado por: bash .claude/validation/private-repo-cite-check.sh --emit-baseline")
    print("# passivo<TAB>grafo<TAB>nó<TAB>forma<TAB>repo por hash — o número só CAI (crescer vs origin/main é HARD).")
    print("# O repo vai por hash: este arquivo é público. Para o nome, rode a guarda com --all --show-names localmente.")
    for f, n, form, repo in sorted(set(acc)):
        print(f"passivo\t{f}\t{n}\t{form}\t{rhash(repo)}")
    sys.exit(0)

def out(sev, code, path, msg):
    print(f"{sev}\t{code}\t{path}\t{msg}" if not human else f"{sev}: [private-repo-cite/{code}] {path} — {msg}")

base, has_base = set(), False
for line in rd(os.path.join(root, base_rel)).splitlines():
    has_base = True
    c = line.split("\t")
    if c[0] == "passivo" and len(c) == 5:
        base.add(tuple(c[1:]))

rc = 0
prev_base = rd(os.path.join(tmp, "prev_base"))
prev_n = sum(1 for l in prev_base.splitlines() if l.startswith("passivo\t"))
if os.path.exists(os.path.join(tmp, "has_prev")) and len(base) > prev_n:
    _, prev_public, _ = load_allow(rd(os.path.join(tmp, "prev_allow")))
    lost = prev_public - public
    if lost:
        out("SOFT", "CATRACA-POR-VISIBILIDADE", base_rel, f"o passivo cresceu ({prev_n} → {len(base)}) e a lista pública perdeu {len(lost)} repo(s) no mesmo diff — confira que viraram privados (--verify-allowlist)")
    else:
        rc = 1
        out("HARD", "CATRACA-VIOLADA", base_rel, f"o passivo CRESCEU: {prev_n} → {len(base)} vs origin/main — citação nova não entra no baseline; omita URL e hash no grafo")
if not has_base and acc and mode == "all":
    out("SOFT", "NO-BASELINE", base_rel, "há citação não conferível e NÃO existe baseline — a catraca não está armada (emita com --emit-baseline)")

passivo = novo = 0
for f, n, form, repo in acc:
    if (f, n, form, rhash(repo)) in base:
        passivo += 1; continue
    novo += 1
    shown = repo if show else rhash(repo)
    what = "URL" if form == "url" else "hash (repo@sha)"
    out("SOFT", "NAO-CONFERIVEL", f,
        f"nó {n} cita {shown} por {what}, e esse repo não está na lista pública ({allow_rel}): terceiro não confere. "
        "Omita URL e hash e escreva a classe na fonte: source: \"não conferível por terceiro: <o que foi lido, sem URL nem hash>\". "
        "Se o repo é público, meça com gh repo view e acrescente-o à lista")
for f, err in unread:
    out("SOFT", "NAO-JULGADO", f, f"não deu para parsear ({err}) — este grafo NÃO foi julgado (YAML inválido é da REGRA 78)")
if human:
    escopo = "tocado(s) pelo diff" if mode == "touched" else "do corpus"
    print(f"private-repo-cite: {len(files)} grafo(s) {escopo}, {novo} citação(ões) nova(s) não conferível(is), "
          f"{passivo} no passivo, baseline com {len(base)} (origin/main: {prev_n}), {len(unread)} não julgado(s)")
sys.exit(rc)
PY
