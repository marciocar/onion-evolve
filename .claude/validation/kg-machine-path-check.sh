#!/usr/bin/env bash
# kg-machine-path-check.sh — REGRA 99: nó de .kg.yaml não carrega CAMINHO DE MÁQUINA, julgado pela CLASSE.
#
# POR QUE EXISTE (defeito datado, SAC-103). Nas ondas O4 a O7 da migração de provenance (SAC-73,
# 2026-10-09/10) o corpus perdeu caminho de máquina em `provenance.source/locator/method`,
# `verified_against`, `trace`, `label` e `narrative`: medido nesta forja, o corpus de 2026-10-08
# (e03952c2) tinha 247 ocorrências em 180 nós, e hoje tem 0, mais 3 nós marcados com
# `x_path_is_content`. Caminho de máquina não é reverificável por terceiros e vaza na publicação das
# portas. Nada impedia que voltasse: a única régua era uma LISTA de diretórios dentro do migrador, e
# a lista errou pelo vocabulário (falsos negativos `/outro/repo`, `/tmp` e `/proc` sem barra, `/boot`,
# `/opt`, `//home/…`, `~<conta>/`; falsos positivos `/lib/` relativo, `/meta:*`, endpoints, URLs).
# Selo P3 do maestro: acusar pela CLASSE. A primeira passada desta guarda no corpus achou o
# `cd /outro/repo` que as quatro ondas deixaram num label.
#
# A CLASSE e as ISENÇÕES moram em .claude/utils/kg/machine_path.py — UM lugar, importado também pelo
# kg-migrate-v3.py e pelo kg-contract-check.sh (grafo NOVO nasce limpo; rastreado não piora). Aqui
# mora só a CATRACA sobre o corpus.
#
# CATRACA (padrão das REGRAS 78/82): `passivo` no baseline = SOFT; caminho fora do baseline = HARD; o
# número de `passivo` CRESCER vs origin/main = HARD (CATRACA-VIOLADA). Hoje o passivo é ZERO. O baseline
# também lista os nós `isento` (marcados `x_path_is_content`): marcar é permitido pelo selo P4, mas
# isenção nova não passa calada — sai SOFT (ISENCAO-NOVA) até entrar no baseline, à vista no diff.
#
# Uso : bash kg-machine-path-check.sh [<raiz>] [--tsv | --emit-baseline | --list-exempt]
#       bash kg-machine-path-check.sh --selftest
# Exit: 0 = ok (ou só passivo) · 1 = violação · 2 = não pôde julgar (NAO VERIFICADO; nunca é verde).
# TETO: ver o cabeçalho de machine_path.py (raiz que não é de sistema fora de argumento de shell, `$HOME`,
#       Windows, campos fora de nó e comentários, hostname de outra máquina fora do members.yaml).
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${_HERE}/../utils/kg"
ROOT=""; MODE="human"
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="tsv"; shift ;;
    --emit-baseline|--emit) MODE="emit"; shift ;;
    --list-exempt) MODE="exempt"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "kg-machine-path: python3 ausente — NAO VERIFICADO" >&2; exit 2; }
python3 -c 'import yaml' 2>/dev/null || { echo "kg-machine-path: PyYAML ausente — NAO VERIFICADO" >&2; exit 2; }
[ -f "${LIB}/machine_path.py" ] || { echo "kg-machine-path: a classe (machine_path.py) não está em ${LIB} — NAO VERIFICADO" >&2; exit 2; }

if [ "${MODE}" = "selftest" ]; then
  # As DUAS POLARIDADES, verbatim das formas medidas nas ondas. -B: sem bytecode ao lado da classe.
  # KG_MACHINE_PATH_HOSTS injeta um hostname de teste: o do processo não é o SUT.
  KG_MACHINE_PATH_HOSTS="srvteste123" python3 -I -B - "${LIB}" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import machine_path as mp
hrx = mp.host_re(mp.known_hosts())
ok = bad = 0
def check(name, text, want_kind):
    global ok, bad
    got = [k for k, _, _ in mp.find(text, hrx)]
    good = (want_kind in got) if want_kind else (got == [])
    if good:
        ok += 1; print(f"  ✅ {name}")
    else:
        bad += 1; print(f"  ✗ {name} — esperava {want_kind or 'SILÊNCIO'}, veio {mp.find(text, hrx)}")
# ── acusa (cada forma medida nas ondas O4–O7) ─────────────────────────────────────────────────────────────
check("acusa: cd /outro/repo (O5, omissão do juiz)", "todos cd /outro/repo && git push origin main", "shell")
check("acusa: git -C /outro/repo", "git -C /outro/repo push -f origin main", "shell")
check("acusa: /tmp sem barra (O5, M1)", "o arquivo ficou em /tmp e sumiu", "fs")
check("acusa: /proc sem barra (O5, M1)", "lido de /proc, sem cópia", "fs")
check("acusa: /tmp no fim de frase", "gravado em /tmp.", "fs")
check("acusa: /boot (O5, fora do brief)", "kernel em /boot/vmlinuz", "fs")
check("acusa: /opt (O5, fora do brief)", "binário em /opt/app/bin/x", "fs")
check("acusa: /home absoluto", "lido em /home/conta/repo/x.md", "fs")
check("acusa: barra dupla da permissão (J-O7-1)", "Read(//home/conta/.ssh/**)", "dbl")
check("acusa: ~<conta>/ (O7, A7)", "o ~onion/whatsapp-sender roda", "acct")
check("acusa: ~/ (til do home)", "curl -o ~/.claude/skills/x/SKILL.md", "tilde")
check("acusa: file:// para raiz de sistema", "abra file:///home/conta/x.html", "file")
check("acusa: redirecionamento 2>/tmp", "cmd 2>/tmp/err.log", "fs")
check("acusa: PATH=/usr/bin:/bin", "env -i PATH=/usr/bin:/bin bash", "fs")
check("acusa: hostname da máquina", "medido no srvteste123 em 10-09", "host")
# ── curas do Elenxo (2026-10-10): o que a 1ª redação deixava passar ───────────────────────────────────────
check("acusa: cd para absoluto de um segmento (Elenxo F7)", "rode cd /workspace e depois", "shell")
check("acusa: hostname em maiúsculas (Elenxo F9)", "o SRVTESTE123 respondeu", "host")
check("acusa: caminho entre aspas tipográficas simples (Elenxo F8)", "lido em ‘/tmp/x’", "fs")
check("acusa: caminho entre crases que ABREM", "em `/home/conta/x` e (`/tmp`)", "fs")
# ── cala (cada isenção selada e cada falso positivo medido) ───────────────────────────────────────────────
check("cala: /lib/ dentro de caminho relativo (O5, 4 FP)", ".claude/hooks/lib/invocation-lines.sh l.10", None)
check("cala: comando /meta:* e /engineer:pr", "rode /meta:kg-freshness e depois /engineer:pr", None)
check("cala: endpoint POST /v1/messages", "POST /v1/messages com /admin/stats e /api/sessions", None)
check("cala: URL com scheme://", "https://github.com/home/tmp/x e https://dev.to/x", None)
check("cala: URL sem scheme (//host)", "carregado de //cdn.example.com/lib/x.js", None)
check("cala: glob relativo", "git ls-files '*.kg.yaml' | grep -v '/fixtures/'", None)
check("cala: /dev/null, /dev/stdin, /dev/stdout, /dev/stderr (A4)", "x 2>/dev/null; y </dev/stdin >/dev/stdout 2>/dev/stderr", None)
check("cala: caminho relativo do repo (A6)", "docs/discussions/onion-pessoal-marcio/x.md", None)
check("cala: ~abril/2026 (data aproximada)", "por volta de ~abril/2026", None)
check("cala: /run nu (é também comando)", "use /run para subir o app", None)
check("cala: caminho enraizado em placeholder", "cat <cgroupfs>/onion.slice/onion-auth.slice/memory.min", None)
check("cala: rota do bridge", "as rotas /chat, /a2a e /en/doutrinas/ respondem", None)
check("cala: crase que FECHA + barra de 'ou' (Elenxo F1, prosa real)", "os campos `plane:`/`status:`/etc. e legível só por `onion`/root", None)
check("cala: tag de fechamento (Elenxo F3)", "<var>x</var> e <root>y</root>", None)
check("cala: placeholder que fecha antes do caminho (corpus, 2026-10-10)", "ls -la docs/<dominio-t2>/graph/<dominio-t2>.kg.yaml", None)
# ── P4: o marcador isenta, com a condição de home/hostname ─────────────────────────────────────────────────
def node(mark, text):
    n = {"id": "N", "label": text}
    if mark is not None:
        n["x_path_is_content"] = mark
    return mp.scan_node(n, hrx)
def p4(name, mark, text, want_acc):
    global ok, bad
    acc, _ = node(mark, text)
    if bool(acc) == want_acc:
        ok += 1; print(f"  ✅ {name}")
    else:
        bad += 1; print(f"  ✗ {name} — acusações={acc}")
p4("P4 cala: citação de terceiro com ~/", "citação", "curl -o ~/.claude/x", False)
p4("P4 cala: citação com hostname", "citação", "o srvteste123 apareceu", False)
p4("P4 cala: receita com /tmp e /usr/bin", "receita", "env -i PATH=/usr/bin:/bin HOME=/tmp/nohome", False)
p4("P4 cala: vetor com /outro/repo", "vetor", "cd /outro/repo", False)
p4("P4 acusa: vetor com ~/ (home de conta)", "vetor", "cat ~/.ssh/id", True)
p4("P4 acusa: receita com /home/<conta>", "receita", "cd /home/conta/x", True)
p4("P4 acusa: receita com hostname", "receita", "ssh srvteste123", True)
p4("P4 acusa: marcador booleano não vale", True, "em /tmp/x", True)
p4("P4 acusa: marcador fora do vocabulário", "sim", "em /tmp/x", True)
p4("P4 acusa: sem marcador", None, "em /tmp/x", True)
print(f"kg-machine-path selftest: {ok} passaram, {bad} falharam")
sys.exit(1 if bad else 0)
PY
  exit $?
fi

[ -n "${ROOT}" ] || ROOT="$(pwd)"
command -v git >/dev/null 2>&1 || { echo "kg-machine-path: git ausente — NAO VERIFICADO" >&2; exit 2; }
_top="$(git -C "${ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "${_top}" ] || { echo "kg-machine-path: '${ROOT}' não é repositório git — NAO VERIFICADO" >&2; exit 2; }
ROOT="${_top}"
_KFP="${_HERE}/kg-fixture-paths.sh"
[ -f "${_KFP}" ] || { echo "kg-machine-path: predicado de fixture ausente (${_KFP}) — NAO VERIFICADO" >&2; exit 2; }
# shellcheck source=kg-fixture-paths.sh
. "${_KFP}"
BASELINE_REL=".claude/validation/kg-machine-path-baseline.txt"
_prev_passivo=""
if git -C "${ROOT}" rev-parse --verify --quiet origin/main >/dev/null 2>&1 \
   && git -C "${ROOT}" cat-file -e "origin/main:${BASELINE_REL}" 2>/dev/null; then
  _prev_passivo="$(git -C "${ROOT}" show "origin/main:${BASELINE_REL}" 2>/dev/null | grep -c '^passivo	' || true)"
fi

KG_FIXTURE_RE="${KG_FIXTURE_RE}" PREV_PASSIVO="${_prev_passivo}" python3 -I -B - "${LIB}" "${ROOT}" "${MODE}" "${BASELINE_REL}" <<'PY'
import os, re, subprocess, sys
lib, root, mode, base_rel = sys.argv[1:5]
sys.path.insert(0, lib)
import machine_path as mp
fix = re.compile(os.environ["KG_FIXTURE_RE"])
ls = subprocess.run(["git", "-C", root, "ls-files", "-z", "*.kg.yaml"], capture_output=True)
if ls.returncode != 0:
    print("kg-machine-path: git ls-files falhou — NAO VERIFICADO", file=sys.stderr); sys.exit(2)
files = [p.decode("utf-8", "surrogateescape") for p in ls.stdout.split(b"\0") if p]
files = [f for f in files if not fix.search(f)]
hrx = mp.host_re(mp.known_hosts(root))
acc, exempt, unread = [], [], []
for f in files:
    try:
        txt = open(os.path.join(root, f), encoding="utf-8").read()
    except OSError as e:
        unread.append((f, str(e))); continue
    a, e, err = mp.scan_text(txt, hrx)
    if err:
        unread.append((f, err)); continue
    acc += [(f,) + x for x in a]
    exempt += [(f,) + x for x in e]

def tsv(sev, code, path, msg):
    print(f"{sev}\t{code}\t{path}\t{msg}" if mode == "tsv" else f"{sev}: [machine-path/{code}] {path} — {msg}")

ex_nodes = sorted({(f, n, m) for f, n, _, _, _, m in exempt})
if mode == "emit":
    print("# kg-machine-path-baseline — a dívida TOLERADA da REGRA 99 (caminho de máquina em nó de .kg.yaml).")
    print("# Gerado por: bash .claude/validation/kg-machine-path-check.sh --emit-baseline")
    print("# passivo<TAB>grafo<TAB>nó<TAB>campo<TAB>token — caminho tolerado; o número só ENCOLHE (crescer vs origin/main é HARD).")
    print("# isento<TAB>grafo<TAB>nó<TAB>marcador — nó com x_path_is_content (selo P4) que isenta algo; isenção nova sai SOFT até entrar aqui.")
    for f, n, fld, k, t in sorted(set(acc)):
        print(f"passivo\t{f}\t{n}\t{fld}\t{t}")
    for f, n, m in ex_nodes:
        print(f"isento\t{f}\t{n}\t{m}")
    sys.exit(0)
if mode == "exempt":
    for f, n, fld, k, t, m in exempt:
        print(f"{f}\t{n}\t{fld}\t{k}\t{t}\t{m}")
    print(f"# {len(ex_nodes)} nó(s) isento(s), {len(exempt)} ocorrência(s)", file=sys.stderr)
    sys.exit(0)

base_p, base_i, has_base = set(), set(), False
try:
    for line in open(os.path.join(root, base_rel), encoding="utf-8"):
        has_base = True
        c = line.rstrip("\n").split("\t")
        if c[0] == "passivo" and len(c) == 5:
            base_p.add(tuple(c[1:]))
        elif c[0] == "isento" and len(c) == 4:
            base_i.add(tuple(c[1:]))
except OSError:
    pass

rc = 0
prev = os.environ.get("PREV_PASSIVO", "")
if prev.isdigit() and len(base_p) > int(prev):
    rc = 1
    tsv("HARD", "CATRACA-VIOLADA", base_rel, f"o passivo CRESCEU: {prev} → {len(base_p)} vs origin/main — caminho de máquina se cura no grafo, não se tolera")
if not has_base and acc:
    tsv("SOFT", "NO-BASELINE", base_rel, "há caminho de máquina e NÃO existe baseline — a catraca não está armada (emita com --emit-baseline)")
passivo = 0
for f, n, fld, k, t in acc:
    if (f, n, fld, t) in base_p:
        passivo += 1; continue
    rc = 1
    tsv("HARD", "CAMINHO-DE-MAQUINA", f,
        f"nó {n}, campo {fld}: '{t}' ({k}) é caminho de máquina — não é reverificável por terceiros e vaza nas portas. "
        "Reescreva pela forma (caminho relativo do repo, remoto@sha:caminho, ou ⟨descrição⟩); se o caminho É o conteúdo, "
        "marque o nó com x_path_is_content: \"citação\"|\"vetor\"|\"receita\" (home de conta e hostname só a citação isenta)")
for f, n, m in ex_nodes:
    if (f, n, m) not in base_i:
        tsv("SOFT", "ISENCAO-NOVA", f, f"nó {n} isenta caminho de máquina por x_path_is_content \"{m}\" e não está no baseline — confira que o caminho É o conteúdo e emita o baseline")
for f, err in unread:
    tsv("SOFT", "NAO-JULGADO", f, f"não deu para ler/parsear ({err}) — este grafo NÃO foi julgado (YAML inválido é da REGRA 78)")
if passivo:
    tsv("SOFT", "PASSIVO", base_rel, f"{passivo} caminho(s) de máquina tolerado(s) pelo baseline — a métrica de saúde é este número diminuindo")
if mode == "human":
    print(f"kg-machine-path: {len(files)} grafo(s), {len(acc)} acusação(ões), {len(ex_nodes)} nó(s) isento(s) por x_path_is_content, {len(unread)} não julgado(s)")
sys.exit(rc)
PY
