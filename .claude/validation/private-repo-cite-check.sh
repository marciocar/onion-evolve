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
# Desde 2026-11-13 a classe é o marcador `private-cite:<id>` do contrato v4.22 da kg-ssot (4.51.0), que o
# kg_trace.py conta e nunca lê; o corpus migrou para ele, e o conselho do aviso aponta o marcador.
#
# O QUE ELA JULGA: os .kg.yaml que o diff contra a base (merge-base com origin/main, em cascata) toca ou
# acrescenta, fora de vendor e fixture. Em cada um, todo texto dos nós (e o que fica fora de campo, como
# comentário) é varrido por duas formas de citação de repo de um DONO JULGADO que não está na lista pública:
#   url  — github.com/<dono>/<repo> com ou sem scheme, git@github.com:, ssh://, www., raw.githubusercontent.com,
#          api.github.com/repos/, codeload.github.com; .git e ponto final de frase normalizados; sem caixa;
#   hash — <dono>/<repo>@<sha 7-40>; e, para nome do registro, <repo>@<sha> nu, depois de caminho
#          (worktrees/<repo>@<sha>), <repo> @ <sha> e <repo> (HEAD <sha>);
#   ref  — <dono>/<repo> sem URL nem sha: nu, com #N (PR ou issue) ou como argumento de -R.
# O "registro" do nome nu: o members.yaml, as URLs de dono julgado no corpus e os `private nome#<hash>` da lista.
# VISIBILIDADE: docs/evolution/federation/public-repos.tsv, versionada e offline (o CI não consulta a rede). Os
# donos julgados são os `owner` da lista mais os donos das URLs do members.yaml. Repo de dono julgado fora
# da lista é "não conferível por terceiro" (privado, inalcançável ou não medido): a guarda não distingue.
#
# SEVERIDADE: citação nova sai SOFT (NAO-CONFERIVEL) — é aviso, por decisão do maestro. A CATRACA é HARD:
# o baseline (docs/evolution/federation/private-repo-cite-baseline.txt) é o passivo contado e só encolhe. Ela
# compara o CONJUNTO de entradas com o do merge-base: entrada nova é HARD (CATRACA-VIOLADA), inclusive a que
# troca uma velha mantendo o número; só sai SOFT (CATRACA-POR-VISIBILIDADE) a entrada cuja citação JÁ estava
# no grafo na base e que a guarda passou a ver (repo que saiu da lista, ou vocabulário que cresceu). O baseline e a saída tsv guardam o
# repo por HASH curto, nunca o nome: a saída do CI de um repo público é pública.
#
# Uso : bash private-repo-cite-check.sh [<raiz>] [--tsv | --all | --emit-baseline] [--base <ref>] [--show-names]
#       bash private-repo-cite-check.sh [<raiz>] --verify-allowlist   (ONLINE, usa gh; fora do CI)
#       bash private-repo-cite-check.sh --hash-name <nome>   (a linha `private nome#<hash>` para a lista, sem gravar o nome)
#       bash private-repo-cite-check.sh --selftest
# Exit: 0 = ok (ou só aviso) · 1 = catraca violada · 2 = não pôde julgar (NAO VERIFICADO; nunca é verde).
#
# TETO (o que ela não vê): repo de terceiro (dono fora da lista e do members.yaml) que sumiu ou fechou;
#   nome nu de repo fora do registro; grafo renomeado (as entradas dele contam como novas: cure, não re-emita); outras formas de citar (gist, GitLab, nome
#   seguido de "commit abc1234" em prosa, sha sem nome); grafo que o diff não toca; mensagem de commit e
#   corpo de PR; e se a lista pública ainda está certa (isso é o --verify-allowlist, que só roda com rede).
#
# --private-repos ARQ (ou ONION_PRIVATE_REPOS=ARQ), desde 2026-11-12 com a kg-ssot 4.51.0 (contrato v4.22): a regra do
#   `kg_gate.py --private-repos`, PORTADA em .claude/utils/kg/private_repos.py (manual 05 do vendor, "O repositório
#   privado citado sem o marcador"). O dono lista os repos privados num arquivo FORA de todo repo público (um padrão
#   por linha: prefixo de URL, owner/repo ou repo@); cada valor de texto e cada CHAVE dos grafos julgados (o tocado,
#   ou o corpus com --all) que cita um deles sem o marcador `private-cite:<id>` sai HARD PRIVADO-SEM-MARCADOR (rc 1),
#   depois de decodificar o %xx e levar a NFC, nomeado por grafo, nó e campo, NUNCA pelo padrão nem pelo valor; a
#   chave, o id de nó ou o caminho que contém um padrão sai mascarado. Arquivo ilegível, vazio ou com padrão de
#   espaço, # ou Cf = rc 2. Desligado sem o arquivo: o CI não o tem (ele é privado), então isto é guarda LOCAL do dono.
#   NÃO COBERTOS (o teto do porte, igual ao da referência): largura cheia, espaço de largura zero no texto, barra
#   invertida, nome quebrado em bloco dobrado, dupla codificação, sósias de caractere, comentário no FIM de linha,
#   .kg.json, e as formas que um padrão sem espaço não expressa (`repo @ sha`, `repo (HEAD sha)`, nome nu em prosa):
#   essas seguem com o vocabulário acima. Extensão da casa: o comentário de LINHA INTEIRA é lido.
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT=""; MODE="tsvh"; HUMAN=1; BASE_REF=""; SHOW=0; PRIV="${ONION_PRIVATE_REPOS:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="touched"; HUMAN=0; shift ;;
    --all) MODE="all"; shift ;;
    --emit-baseline|--emit) MODE="emit"; shift ;;
    --verify-allowlist) MODE="verify"; shift ;;
    --hash-name) MODE="hashname"; export PRC_NAME="${2:?--hash-name exige o nome}"; shift 2 ;;
    --selftest) MODE="selftest"; shift ;;
    --show-names) SHOW=1; shift ;;
    --private-repos) [ $# -ge 2 ] && [ -n "$2" ] || { echo "ERRO: --private-repos exige o arquivo" >&2; exit 2; }
                     PRIV="$2"; shift 2 ;;
    --private-repos=*) PRIV="${1#--private-repos=}"; [ -n "${PRIV}" ] || { echo "ERRO: --private-repos exige o arquivo" >&2; exit 2; }; shift ;;
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
  # PORTA (kind: door, ex.: a onion-core com role: source): não leva docs/evolution/, e o objeto desta guarda (o corpus
  # do core e a lista) não chega lá. Ausência LEGÍTIMA, dita como tal; a lista ausente na fonte segue rc 2.
  if [ ! -f "${ROOT}/${ALLOW_REL}" ] && grep -qE '^[[:space:]]*kind:[[:space:]]*door([[:space:]]|$)' "${ROOT}/.claude/.onion-version" 2>/dev/null; then
    [ "${HUMAN}" = 1 ] && echo "private-repo-cite: NÃO SE APLICA — porta (kind: door) não recebe ${ALLOW_REL}; a REGRA 121 é da fonte"
    exit 0
  fi
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
  # os ARQUIVOS DE DADO (csv, tsv, json, jsonl, txt, e md sob data/): o tocado, ou todos fora do modo touched. O filtro
  # de extensão e de exclusão é do Python (DATA_EXT, FUNCTIONAL_NAMES); aqui só a lista do git.
  if [ "${MODE}" = "touched" ]; then
    { git -C "${ROOT}" diff --name-only --no-renames -z "${base}" \
      && git -C "${ROOT}" ls-files --others --exclude-standard -z; } > "${_TMP}/data_files" 2>"${_TMP}/err" \
      || { echo "private-repo-cite: git diff dos dados falhou — NAO VERIFICADO" >&2; exit 2; }
  else
    git -C "${ROOT}" ls-files -z > "${_TMP}/data_files" 2>"${_TMP}/err" \
      || { echo "private-repo-cite: git ls-files dos dados falhou — NAO VERIFICADO" >&2; exit 2; }
  fi
  # a catraca compara o CONJUNTO de entradas com o do merge-base (o que a branch herdou), não a contagem
  # da ponta: trocar uma entrada velha por uma nova mantém o número e é afrouxar do mesmo jeito
  if [ -n "${base}" ] && git -C "${ROOT}" cat-file -e "${base}:${BASE_REL}" 2>/dev/null; then
    git -C "${ROOT}" show "${base}:${BASE_REL}" > "${_TMP}/prev_base" 2>"${_TMP}/err" \
      || { echo "private-repo-cite: git show do baseline da base falhou — NAO VERIFICADO" >&2; exit 2; }
    echo 1 > "${_TMP}/has_prev"
  fi
  export PRC_BASE="${base}"
fi

_main_rc=0
export PRC_KG_UTILS="${_HERE}/../utils/kg" PRC_PRIVATE="${PRIV}"
KG_FIXTURE_RE="${KG_FIXTURE_RE:-x^}" python3 -I -B - "${ROOT:-.}" "${MODE}" "${ALLOW_REL}" "${BASE_REL}" "${MEMBERS_REL}" "${_TMP}" "${SHOW}" "${HUMAN}" <<'PY' || _main_rc=$?
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
# dono/repo SEM URL e sem sha: nu, com #N (PR/issue) ou como argumento de -R. Fora de caminho (não depois de / ou :)
# e nunca colado num @sha (esse é o HASH_RE). dono/repo/caminho sem host também é ref. A posse do token vem do lookahead.
REF_RE = re.compile(
    r"(?<![A-Za-z0-9_.\-/:@])([A-Za-z0-9](?:[A-Za-z0-9\-]{0,38}))/([A-Za-z0-9_.\-]+)(?![A-Za-z0-9_.\-@])", re.I)
# <nome> @ <sha> e <nome> (HEAD <sha>) — só para nome nu do registro (é prosa: sem o registro seria ruído)
HASH_SP_RE = re.compile(
    r"([A-Za-z0-9_.\-]+)(?:\s*@\s+|\s+@\s*|\s+\(\s*(?:HEAD\s+|commit\s+|sha\s+)?)([0-9a-f]{7,40})(?![0-9A-Za-z])", re.I)

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
        if o and o in owners:
            if f"{o}/{r}" not in public:
                out.append(("hash", f"{o}/{r}"))
        elif r in private_names:                             # nu, ou depois de caminho/dono de terceiro
            out.append(("hash", private_names[r]))
    for m in HASH_SP_RE.finditer(text):
        r = norm(m.group(1))
        if r in private_names:
            out.append(("hash", private_names[r]))
    for m in REF_RE.finditer(text):
        r, o = norm(m.group(2)), m.group(1).lower()
        if o in owners and r and f"{o}/{r}" not in public:
            out.append(("ref", f"{o}/{r}"))
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
    check("acusa: caminho antes do nome do registro (worktrees/<nome>@sha)", "em worktrees/repo-secreto@abc1234", "hash")
    check("acusa: caminho absoluto antes do nome do registro", "lido em /srv/x/repo-secreto@abc1234:docs/a.md", "hash")
    check("acusa: <nome> @ <sha> com espaço", "repo-secreto @ abc1234", "hash")
    check("acusa: <nome> (HEAD <sha>)", "repo-secreto (HEAD abc1234)", "hash")
    check("acusa: dono/repo nu", "o código mora em donoteste/repo-secreto, na main", "ref")
    check("acusa: dono/repo#N (PR ou issue)", "fechado em donoteste/repo-secreto#65", "ref")
    check("acusa: gh -R dono/repo", "gh pr view 3 -R donoteste/repo-secreto", "ref")
    check("acusa: dono/repo nu com ponto final", "veja donoteste/repo-secreto.", "ref")
    check("acusa: dono/repo/caminho sem host", "lido em donoteste/repo-secreto/docs/x.md", "ref")
    def exact(name, text, want):
        global ok, bad
        got = sorted(f for f, _ in find(text, owners, public, pn))
        if got == want:
            ok += 1; print(f"  ✅ {name}")
        else:
            bad += 1; print(f"  ✗ {name} — esperava {want}, veio {got}")
    exact("exato: dono/repo@sha é só hash, não vira também ref", "donoteste/repo-secreto@abc1234:x", ["hash"])
    exact("exato: git@github.com:dono/repo é só url, não vira também ref", "git@github.com:donoteste/repo-secreto.git", ["url"])
    check("cala: dono/repo nu público", "ver donoteste/repo-publico#12 e -R donoteste/repo-publico", None)
    check("cala: caminho com dono julgado no meio (não é ref)", "docs/donoteste/repo-secreto/x.md", None)
    check("cala: outro host com dono julgado (GitLab, teto declarado)", "https://gitlab.com/donoteste/repo-secreto", None)
    check("cala: terceiro/repo nu", "anthropics/claude-code#1 e terceiro/lib", None)
    check("cala: palavra @ sha que não é nome do registro", "main @ abc1234 e versão (HEAD 0a1b2c3)", None)
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
    print("# passivo<TAB>grafo<TAB>nó<TAB>forma<TAB>repo por hash — só ENCOLHE (entrada nova vs o merge-base é HARD).")
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
def entries(text):
    return {tuple(l.split("\t")[1:]) for l in text.splitlines() if l.startswith("passivo\t") and len(l.split("\t")) == 5}
prev = entries(rd(os.path.join(tmp, "prev_base")))
armed = os.path.exists(os.path.join(tmp, "has_prev"))
if armed and base - prev:
    # entrada nova no baseline só é legítima se a citação JÁ ESTAVA no grafo na base, e a guarda só passou a
    # vê-la (um repo saiu da lista pública, ou o vocabulário cresceu). Citação nova não entra no baseline.
    seen_at_base, cache = set(), {}
    for f, n, form, rh in sorted(base - prev):
        if f not in cache:
            g = subprocess.run(["git", "-C", root, "show", f"{os.environ.get('PRC_BASE', '')}:{f}"], capture_output=True, text=True)
            cache[f] = scan_text(g.stdout, owners, public, pn)[0] if g.returncode == 0 else set()
        if (n, form, rh) in {(a, b, rhash(c)) for a, b, c in cache[f]}:
            seen_at_base.add((f, n, form, rh))
    grew = (base - prev) - seen_at_base
    if seen_at_base:
        out("SOFT", "CATRACA-POR-VISIBILIDADE", base_rel, f"{len(seen_at_base)} entrada(s) nova(s) no baseline de citação que já estava no grafo na base (repo que saiu da lista ou forma que a guarda passou a ver) — confira com --verify-allowlist")
    if grew:
        rc = 1
        fs = ", ".join(sorted({f for f, _, _, _ in grew})[:3])
        out("HARD", "CATRACA-VIOLADA", base_rel, f"{len(grew)} entrada(s) nova(s) no baseline vs o merge-base para citação que NÃO estava no grafo na base ({fs}) — citação nova não entra no baseline; omita URL e hash no grafo")
if not has_base and acc and mode == "all":
    out("SOFT", "NO-BASELINE", base_rel, "há citação não conferível e NÃO existe baseline — a catraca não está armada (emita com --emit-baseline)")

passivo = novo = 0
for f, n, form, repo in acc:
    if (f, n, form, rhash(repo)) in base:
        passivo += 1; continue
    novo += 1
    shown = repo if show else rhash(repo)
    what = {"url": "URL", "hash": "hash (repo@sha)", "ref": "referência dono/repo"}[form]
    out("SOFT", "NAO-CONFERIVEL", f,
        f"nó {n} cita {shown} por {what}, e esse repo não está na lista pública ({allow_rel}): terceiro não confere. "
        "Troque a citação pelo marcador private-cite:<id> (kg_trace.py private-cite-id do vendor kg-ssot, um por citação): no source e no locator ele substitui o valor inteiro, no trace vira private-cite:<id>#<id de nó>, na prosa troca só o nome do repo, e a resolução fica numa tabela privada do dono. "
        "Se o repo é público, meça com gh repo view e acrescente-o à lista")
# o marcador com o commit colado (private-cite:<id>@<hex>) devolve ao grafo o que o marcador tirou: o commit do repo
# privado. O contrato v4.22 põe o marcador no valor inteiro de source, locator, trace, verified_against e do detalhe do
# method, e na prosa troca o nome sem deixar @sha nem :caminho. HARD em todo grafo julgado, sem baseline: não há passivo
# legítimo desta forma (refutador do #1648, B1). Diz grafo, nó e linha; nunca o id nem o hex.
MK_AT = re.compile(r"private-cite:[A-Za-z0-9_-]{22,43}@[0-9A-Fa-f]{6,40}(?![0-9A-Za-z_-])")
# Na mesma linha do marcador, o hex SOLTO (6+, com dígito e letra, qualquer caixa: `(<hex>)`, `/blob/<hex>/`, argumento
# de flag) também é commit do repo privado, a menos que seja commit DESTE repo: o core é público, e o pin do core
# (onion_version) mora ao lado do marcador nos registros de adotante. A isenção vale só para o commit ALCANÇÁVEL de um ref
# remoto ou de uma tag, que é o que o clone do CI tem (fetch-depth: 0): o objeto que só existe no git local (branch
# apagada, commit de PR squash) passaria aqui e reprovaria no CI — o caso medido no 1º CI do #1648. O commit público que
# só o GitHub alcança vai qualificado: dono/repo@<hex> da lista pública. Re-refutação do #1648.
MK = re.compile(r"private-cite:[A-Za-z0-9_-]{22,43}")
HEX_LOOSE = re.compile(r"(?<![0-9A-Za-z_-])[0-9A-Fa-f]{6,40}(?![0-9A-Za-z_-])")
import bisect
_reach = None
def own_commit(h):
    """Commit deste repo ALCANÇÁVEL de um ref remoto ou tag (o que o clone do CI tem), por prefixo, sem rede."""
    global _reach
    if _reach is None:
        _reach = sorted(subprocess.run(["git", "-C", root, "rev-list", "--remotes", "--tags"], capture_output=True, text=True).stdout.split())
    h = h.lower(); k = bisect.bisect_left(_reach, h)
    return k < len(_reach) and _reach[k].startswith(h)
def _loose_on_marker_line(line):
    """Hex solto na linha do marcador que não é commit deste repo alcançável nem dono/repo@<hex> da lista pública."""
    rest = re.sub(r"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)@[0-9A-Fa-f]{6,40}(?![0-9A-Za-z_-])",
                  lambda m: " " if m.group(1).lower() in public else m.group(0), MK.sub(" ", line))
    return [x for x in HEX_LOOSE.findall(rest) if re.search(r"[0-9]", x) and re.search(r"[A-Fa-f]", x) and not own_commit(x)]
for f in files:
    node = "-"
    for i, line in enumerate(rd(os.path.join(root, f)).splitlines(), 1):
        m = re.match(r"\s*-\s+id:\s*['\"]?([A-Za-z0-9_.-]+)", line)
        if m:
            node = m.group(1)
        if MK_AT.search(line):
            rc = 1
            out("HARD", "MARCADOR-COM-COMMIT", f, f"nó {node}, linha {i}: o marcador private-cite:<id> leva um commit colado (@<hex>), o que devolve ao grafo público o commit do repo privado. No source, locator, trace, verified_against e no detalhe do method o marcador ocupa o valor inteiro; na prosa, tire o @<hex> e o :caminho")
        elif MK.search(line):
            loose = _loose_on_marker_line(line)
            if loose:
                rc = 1
                out("HARD", "MARCADOR-COM-COMMIT", f, f"nó {node}, linha {i}: {len(loose)} hex solto(s) na linha do marcador private-cite:<id> que não são commit deste repo — o commit do repo privado volta ao grafo público. Troque por ⟨commit⟩ e registre na tabela privada")
# ── ARQUIVOS DE DADO (desde 2026-11-13, fix/provenance-triage-scrub) ────────────────────────────────────────────────
# Nenhuma guarda varria CSV: os 41 arquivos de data/provenance-triage/ chegaram à main pública com 393 linhas citando
# repo privado e 342 com caminho de home de conta, inclusive caminho/repo@commit. Nos csv, tsv, json, jsonl e txt, e em todo arquivo de texto
# sob data/, julgados (o tocado, ou todos com --all), cada LINHA é varrida por:
#   CAMINHO-DE-MAQUINA-EM-DADO (HARD): home de conta com segmento (/home/<x>, /root/<x>, /Users/<x>, também //home/),
#     pela classe do machine_path.py (a mesma da REGRA 99). `/home` nu como conceito e ./home/ relativo calam;
#   MARCADOR-COM-COMMIT (HARD): a mesma regra dos grafos, acima;
#   PRIVADO-SEM-MARCADOR-EM-DADO (HARD, só com --private-repos / ONION_PRIVATE_REPOS): padrão do arquivo privado do dono.
# Nunca imprime o valor. Escopo: csv, tsv, json, jsonl e txt em qualquer lugar, e todo arquivo de texto sob data/.
# Fora: vendor, fixture, binário, e a configuração FUNCIONAL que os hooks do core leem na pasta de
# operações dele (o caminho ali é o alvo que o veto do MOAT protege; trocá-lo desarmaria a guarda) — lista declarada,
# por pasta e nome, não padrão. Na porta e no adotante a pasta não existe, e a isenção não tem efeito.
DATA_EXT = (".csv", ".tsv", ".json", ".jsonl", ".txt")
# sob uma pasta data/, TODO arquivo de texto é dado (o refutador do #1649 achou commit em register.js); o binário fica fora
DATA_BIN = (".gz", ".tgz", ".tar", ".zip", ".png", ".jpg", ".jpeg", ".gif", ".pdf", ".webp", ".ico", ".woff", ".woff2")
FUNCTIONAL_DIR, FUNCTIONAL_NAMES = "ops", {"moat-targets.tsv", "cc-sdk-targets.tsv"}
HEX_COMMIT = re.compile(r"(?<![0-9A-Za-z_-])[0-9A-Fa-f]{7,40}(?![0-9A-Za-z_-])")
NONCOMMIT_LABEL = re.compile(r"(?i)(?:\bmd5(?:sum)?|\bsha-?(?:1|256)|\bsess(?:ion|ão|ao)|\bsubagent[e]?|\buuid)\b[^\n]{0,40}$")
HOME_SEG = re.compile(r"/{1,2}(?:home|root|Users)/[A-Za-z0-9_.@+-]+")
def data_scope(f):
    functional = os.path.dirname(f) == FUNCTIONAL_DIR and os.path.basename(f) in FUNCTIONAL_NAMES
    own_artifact = f in (base_rel, allow_rel)  # o baseline (repo por hash) e a lista pública são da própria guarda
    if f.startswith("vendor/") or fix.search(f) or functional or own_artifact or f.endswith(".kg.yaml"):
        return False
    low = f.lower()
    if low.endswith(DATA_BIN):
        return False
    return low.endswith(DATA_EXT) or "/data/" in f
data_files = [f for f in kg_list("data_files") if data_scope(f)] if os.path.exists(os.path.join(tmp, "data_files")) else []
# o próprio arquivo de padrões, se o dono o pôs dentro da árvore (não versionado), não é dado do repo
if os.environ.get("PRC_PRIVATE"):
    _pp = os.path.realpath(os.environ["PRC_PRIVATE"])
    data_files = [f for f in data_files if os.path.realpath(os.path.join(root, f)) != _pp]
if data_files:
    sys.path.insert(0, os.environ.get("PRC_KG_UTILS", ""))
    try:
        import machine_path as _mp
    except Exception as e:
        print(f"private-repo-cite: machine_path.py ausente ({e}) — os {len(data_files)} arquivo(s) de dado NAO VERIFICADO(s)", file=sys.stderr)
        sys.exit(2)
    _priv = []
    if os.environ.get("PRC_PRIVATE"):
        try:
            import private_repos as _pr
            _priv = [_pr.compile_pattern(x) for _, x in _pr.read_patterns(os.environ["PRC_PRIVATE"])]
        except BaseException as e:
            print(f"private-repo-cite: --private-repos não leu o arquivo ({type(e).__name__}) — NAO VERIFICADO", file=sys.stderr)
            sys.exit(2)
    for f in data_files:
        for i, line in enumerate(rd(os.path.join(root, f)).splitlines(), 1):
            if any(_mp._root_of(t) in _mp.HOME_ROOTS and HOME_SEG.match(line[s:]) for _k, t, s in _mp.find(line)):
                rc = 1
                out("HARD", "CAMINHO-DE-MAQUINA-EM-DADO", f, f"linha {i}: caminho de home de conta num arquivo de dado público — troque por caminho relativo ao repo ou por ⟨caminho⟩ (o original vai na tabela privada)")
            if MK_AT.search(line) or (MK.search(line) and _loose_on_marker_line(line)):
                rc = 1
                out("HARD", "MARCADOR-COM-COMMIT", f, f"linha {i}: commit ao lado do marcador private-cite:<id> num arquivo de dado — troque por ⟨commit⟩")
            if _priv and any(r.search(_pr.norm(line)) for r in _priv):
                rc = 1
                out("HARD", "PRIVADO-SEM-MARCADOR-EM-DADO", f, f"linha {i}: cita um repositório privado (padrão do --private-repos) sem o marcador private-cite:<id>")
    # ── o COMMIT solto em dado (refutador do #1649, B2): o hex sem marcador por perto passava. Duas camadas:
    #   COMMIT-PRIVADO-EM-DADO (HARD, só com ONION_PRIVATE_CLONES = clones dos repos privados, separados por os.pathsep):
    #     todo hex de 7 a 40 em QUALQUER linha do arquivo julgado que é commit de um desses clones e não do core;
    #   HEX-NAO-CONFERIDO-EM-DADO (HARD, sempre, falha fechada): na LINHA ACRESCENTADA pelo diff (o arquivo novo inteiro),
    #     o hex que não é commit do core alcançável, nem `dono/repo@<hex>` de repo da lista pública ou de dono de
    #     terceiro, nem leva um rótulo de não-commit logo antes (md5, sha1, sha256, sessão, subagente, uuid).
    #   «Acrescentado» é por token: o hex na linha acrescentada que NÃO estava no arquivo da base (o JSON minificado é
    #   uma linha só, e mexer nele não torna novo cada id que ele já tinha). Por que só o acrescentado na 2ª camada: o corpus de dado tem ~1.000 hex que não são commit (hash, id de
    #   sessão), e a falha fechada sobre ele reescreveria evidência sem ganho; o que ENTRA passa pela catraca.
    _clones = [c for c in os.environ.get("ONION_PRIVATE_CLONES", "").split(os.pathsep) if c]
    def _batch(repo, hs):
        r = subprocess.run(["git", "-C", repo, "cat-file", "--batch-check=%(objecttype)"],
                           input="".join(h + "^{commit}\n" for h in hs), capture_output=True, text=True)
        return {h for h, l in zip(hs, r.stdout.splitlines()) if l.strip() == "commit"}
    def _added(f):
        """(linhas acrescentadas, texto da base). None nas linhas = o arquivo inteiro é novo."""
        if mode != "touched":
            return set(), ""
        b = subprocess.run(["git", "-C", root, "show", f"{os.environ.get('PRC_BASE', 'HEAD')}:{f}"], capture_output=True)
        base_txt = b.stdout.decode("utf-8", "replace").lower() if b.returncode == 0 else ""
        if subprocess.run(["git", "-C", root, "ls-files", "--error-unmatch", f], capture_output=True).returncode != 0:
            return None, base_txt  # arquivo novo, não versionado: todas as linhas
        d = subprocess.run(["git", "-C", root, "diff", "-U0", os.environ.get("PRC_BASE", "HEAD"), "--", f], capture_output=True, text=True).stdout
        out_, ln = set(), 0
        for l in d.splitlines():
            m = re.match(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@", l)
            if m:
                ln = int(m.group(1)); continue
            if l.startswith("+") and not l.startswith("+++"):
                out_.add(ln); ln += 1
        return out_, base_txt
    for f in data_files:
        lines = rd(os.path.join(root, f)).splitlines()
        occ = [(i, m) for i, line in enumerate(lines, 1) for m in HEX_COMMIT.finditer(line)
               if re.search(r"[0-9]", m.group(0)) and re.search(r"[A-Fa-f]", m.group(0)) and not own_commit(m.group(0))]
        if not occ:
            continue
        if _clones:
            hs = sorted({m.group(0).lower() for _, m in occ}); pv = set()
            for c in _clones:
                pv |= _batch(c, [h for h in hs if h not in pv])
            for i in sorted({i for i, m in occ if m.group(0).lower() in pv}):
                rc = 1
                out("HARD", "COMMIT-PRIVADO-EM-DADO", f, f"linha {i}: commit de repositório privado num arquivo de dado público — troque por ⟨commit⟩ e registre na tabela privada")
        added, base_txt = _added(f)
        for i, m in occ:
            if added is not None and i not in added:
                continue
            # o hex NOVO é o que não estava no arquivo na base: a linha mexida (ou o JSON de uma linha só) que só
            # carrega hex antigos não é entrada nova (o passivo antigo é da COMMIT-PRIVADO-EM-DADO, com os clones)
            if re.search(r"(?<![0-9a-z_-])" + re.escape(m.group(0).lower()) + r"(?![0-9a-z_-])", base_txt):
                continue
            line = lines[i - 1]; pre = line[:m.start()]
            q = re.search(r"([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)@$", pre)
            if q and (f"{q.group(1)}/{q.group(2)}".lower() in public or q.group(1).lower() not in owners):
                continue
            if NONCOMMIT_LABEL.search(pre[-40:]):
                continue
            rc = 1
            out("HARD", "HEX-NAO-CONFERIDO-EM-DADO", f, f"linha {i}: hex que não é commit do core alcançável nem dono/repo@<hex> público entrou num arquivo de dado — troque por ⟨commit⟩ (se for de repo privado), qualifique como dono/repo@<hex> (se público) ou rotule (md5, sessão…)")
for f, err in unread:
    out("SOFT", "NAO-JULGADO", f, f"não deu para parsear ({err}) — este grafo NÃO foi julgado (YAML inválido é da REGRA 78)")
if human:
    escopo = "tocado(s) pelo diff" if mode == "touched" else "do corpus"
    print(f"private-repo-cite: {len(files)} grafo(s) {escopo}, {novo} citação(ões) nova(s) não conferível(is), "
          f"{passivo} no passivo, baseline com {len(base)} (merge-base: {len(prev) if armed else 'sem baseline'}), {len(unread)} não julgado(s)")
sys.exit(rc)
PY

# ── --private-repos: a regra do kg_gate.py, portada (ver o cabeçalho). Só nos modos que julgam (touched e all). ──
[ -n "${PRIV}" ] || exit "${_main_rc}"
case "${MODE}" in touched|all) : ;; *) exit "${_main_rc}" ;; esac
_PR="${_HERE}/../utils/kg/private_repos.py"
[ -f "${_PR}" ] || { echo "private-repo-cite: --private-repos sem o porte (${_PR}) — NAO VERIFICADO" >&2; exit 2; }
_pfiles=()
while IFS= read -r -d '' _f; do [ -f "${ROOT}/${_f}" ] && _pfiles+=("${_f}"); done < "${_TMP}/files"
if [ "${MODE}" = touched ] && [ "${#_pfiles[@]}" -eq 0 ]; then
  [ "${HUMAN}" = 1 ] && echo "private-repo-cite: --private-repos: 0 grafo(s) tocado(s), nada a conferir"
  exit "${_main_rc}"
fi
_prc=0
_pout="$(python3 -I -B "${_PR}" --patterns "${PRIV}" --root "${ROOT}" --format tsv --corpus ${_pfiles[@]+"${_pfiles[@]}"} 2>"${_TMP}/perr")" || _prc=$?
if [ "${_prc}" -ge 2 ]; then
  echo "private-repo-cite: --private-repos NÃO JULGOU (rc ${_prc}): $(head -1 "${_TMP}/perr") — NAO VERIFICADO" >&2
  exit 2
fi
_pn=0
while IFS=$'\t' read -r _g _w _fd _ls _v; do
  [ "${_v:-}" = PRIVATE-REPO ] || continue
  _pn=$((_pn + 1))
  _m="nó ${_w}, campo ${_fd}: cita um repositório privado (padrão na linha ${_ls} do --private-repos) sem o marcador private-cite:<id>. Cure com o private-cite-id do kg_trace.py do vendor kg-ssot (um id por citação): o marcador substitui o valor inteiro no source e no locator, vira private-cite:<id>#<id de nó> no trace, e na prosa troca só o nome do repo"
  if [ "${HUMAN}" = 1 ]; then echo "HARD: [private-repo-cite/PRIVADO-SEM-MARCADOR] ${_g} — ${_m}"
  else printf 'HARD\tPRIVADO-SEM-MARCADOR\t%s\t%s\n' "${_g}" "${_m}"; fi
done <<< "${_pout}"
[ "${HUMAN}" = 1 ] && echo "private-repo-cite: --private-repos: $(awk -F'\t' '$2=="RESUMO"{print $4}' <<< "${_pout}")"
# rc 1 do porte sem nenhuma linha traduzida: o rc e a saída discordam, e isso nunca é verde nem achado mudo
if [ "${_prc}" -eq 1 ] && [ "${_pn}" -eq 0 ]; then
  echo "private-repo-cite: --private-repos: o porte saiu rc 1 sem achado que esta tradução leia — NAO VERIFICADO" >&2; exit 2
fi
# o pior dos dois vence: o rc 2 da guarda principal (não julgou) nunca vira rc 1 (passada adversarial, L2)
[ "${_main_rc}" -ge 2 ] && exit "${_main_rc}"
[ "${_prc}" -eq 1 ] && exit 1
exit "${_main_rc}"
