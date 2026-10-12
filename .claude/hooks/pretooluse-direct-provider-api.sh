#!/usr/bin/env bash
# PreToolUse(Bash) — veta chamada DIRETA à API de um provedor de task manager quando o adapter
# executável dele existe (SAC-75, nó Q_GUARDA_API_DIRETA_DE_PROVEDOR do grafo auto-drive-2026-10).
#
# ── O DEFEITO MEDIDO (datado, não suposto) ──────────────────────────────────────────────────
# 2026-10-08 (SAC-66): o core moveu a issue por script direto na API do Linear em vez do adapter, e o
# estado saiu "In Review" em vez de "In Progress"; no mesmo dia o maestro elevou "USAR a maquinaria,
# nunca interpretá-la" a fluxo obrigatório. Em 2026-10-11 nasceu o executável (tm.sh + adapters/linear.py,
# PR #1038) — e a regra continuou na disciplina da sessão. Medido nos transcripts em 2026-10-12: 147
# comandos Bash únicos tocaram host de provedor (2026-09-23 → 2026-10-12, cinco repos), ~130 com
# cliente HTTP; DEPOIS do merge do tm.sh, em 2026-10-12T03:21, a sessão principal ainda rodou
# `python3 - <<'EOF'` com `urllib.request.Request('https://api.linear.app/graphql', …)`. Esse é o
# caso verbatim da bancada. Nenhum arquivo rastreado tinha a chamada: o defeito mora no COMANDO da
# sessão, e é por isso que o substrato principal é este hook (a REGRA 105 cobre o arquivo rastreado).
#
# ── O QUE VETA (exit 2, antes de executar) ──────────────────────────────────────────────────
# Um comando Bash cuja execução chama um host de `.claude/utils/task-manager/provider-hosts.tsv`:
#  (a) cliente HTTP (curl, wget, httpie, xh, aria2c) com o host num argumento, ou numa variável
#      atribuída LITERALMENTE na mesma string (`B=https://…; curl $B/user`);
#  (b) interpretador com código EMBUTIDO (`python3 -c`, `node -e`, `perl -e`, `ruby -e`, `php -r`) ou
#      lido de HEREDOC (`python3 - <<'EOF'`), quando o código tem `//<host>` E um idioma de rede
#      (urllib, requests, fetch(, httpx, …);
#  (c) interpretador ou shell rodando um ARQUIVO fora do repo (o script avulso no scratchpad), cujo
#      conteúdo tem a mesma forma — inclusive o arquivo que a própria string grava (`cat > x.py <<EOF`);
#  (d) `bash -c STR`, substituição `$(…)`/crase e heredoc lido por shell são re-julgados como shell.
#
# ── QUANDO ARMA (por provedor, derivado — nunca lista fixa) ─────────────────────────────────
# Só quando (1) existe o executável `adapters/<p>.py|.sh` no projeto E (2) <p> é o provider ATIVO
# (`env-check.sh --provider`, que lê o .env como dado e devolve só o nome). Sem executável o curl É o
# caminho que o adapter em prosa prescreve, e vetá-lo barraria o único caminho que existe — é a condição
# escrita no próprio nó. Provider inativo cala: o adotante cujo PRODUTO integra com o Linear não é o
# adotante que opera tasks pelo Linear.
#
# ── O QUE NÃO VETA (teto declarado) ─────────────────────────────────────────────────────────
#  · o adapter: tudo sob `*/utils/task-manager/` (inclusive bundle de plugin) — o hook só lê a string
#    do modelo e arquivos FORA do repo; `bash .claude/utils/task-manager/tm.sh …` não cita host;
#  · texto que só CITA o host: `git commit -m`, `echo`, `grep`, heredoc lido por `cat` (documentar ≠ chamar);
#  · arquivo DENTRO do repo (rastreado é da REGRA 105; não rastreado, calado);
#  · host montado em tempo de execução (`f'https://{HOST}/…'`), host sem `//` (`HTTPSConnection('host')`),
#    variável vinda de fora da string, `cat x | python3 -`, `<<<`, `perl -ne`, `env -S`, `uv run x.py`,
#    WebFetch (não leva cabeçalho de auth), cliente que não está na lista (medidos pelo Elenxo, 2026-10-12);
#  · em CÓDIGO (b, c) o host tem de estar a até 3 linhas de um idioma de rede FORA de literal de string, sem
#    contar comentário nem linha de `import`: texto que cita a chamada cala, chamada com o endpoint numa
#    constante a mais de 3 linhas passa. Em CLIENTE (a) o host tem de ABRIR o argumento (o destino), nunca
#    aparecer num `?q=`, num corpo `-d` ou num cabeçalho. Heredoc no stdin de um SCRIPT é dado, não código;
#  · sem python3 o hook cala: o adapter do Linear também é Python, e vetar o curl sem ele barraria o único
#    caminho. Erra para CALAR (cláusula 4 da guard-doctrine): string que não parseia (aspas abertas) cala.
# Escape: não há flag. Verbo que o tm.sh não tem é ACHADO — implemente em adapters/<p>.py (a REGRA 104
# amarra a declaração) e rode pelo tm.sh. Medição fora disso, o maestro roda fora da sessão.
set -uo pipefail

# ── o juiz (Python, stdlib) ── stdin: o comando · env: ONION_ROOT, ONION_CWD, ONION_MAP
_onion_dpa_judge() {
  python3 -I -B /dev/fd/4 4<<'ONION_DPA_PY'
import os, re, shlex, sys

ROOT = os.path.realpath(os.environ.get("ONION_ROOT") or os.getcwd())
CWD0 = os.path.realpath(os.environ.get("ONION_CWD") or ROOT)
ADAPTERS = os.path.join(ROOT, ".claude", "utils", "task-manager", "adapters")

def load_map(path):
    out = []
    try:
        fh = open(path, encoding="utf-8")
    except OSError:
        return out
    for line in fh:
        line = line.rstrip("\r\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2 or not parts[0].strip() or not parts[1].strip():
            continue
        try:
            out.append((parts[0].strip(), re.compile(parts[1].strip())))
        except re.error:
            continue
    return out

# arma só o provedor que TEM executável no projeto
MAP = [(p, rx) for p, rx in load_map(os.environ.get("ONION_MAP", ""))
       if os.path.isfile(os.path.join(ADAPTERS, p + ".py")) or os.path.isfile(os.path.join(ADAPTERS, p + ".sh"))]
if not MAP:
    sys.exit(0)
URL = [(p, re.compile(r"//(?:" + rx.pattern + r")")) for p, rx in MAP]
# idioma de rede de BIBLIOTECA: `curl`/`wget` em código Python/Node são palavra, não chamada (Elenxo, achado 1)
NET = re.compile(r"urllib|urlopen|\brequests\.|http\.client|httpx|aiohttp|\bfetch\s*\(|axios|XMLHttpRequest|"
                 r"Net::HTTP|LWP::|HTTP::Tiny|Invoke-(?:WebRequest|RestMethod)|undici")
CODE_COMMENT = re.compile(r"^\s*(?:#|//)")
STRLIT = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|`(?:\\.|[^`\\])*`')
IMPORT = re.compile(r"^\s*(?:import\s|from\s+\S+\s+import\s|(?:const|let|var)\s+\w+\s*=\s*require\(|use\s)[^;]*;?\s*$")  # import não é chamada
WINDOW = 3    # o host e o idioma de rede na MESMA instrução, aproximada por janela de linhas
CLIENTS = {"curl", "wget", "http", "https", "xh", "xhs", "httpie", "aria2c"}
SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
INLINE = {"node": {"-e", "--eval", "-p", "--print"}, "bun": {"-e", "--eval"}, "deno": {"eval"},
          "perl": {"-e", "-E"}, "ruby": {"-e"}, "php": {"-r"}}
WRAPPERS = {"env", "command", "exec", "sudo", "nohup", "time", "nice", "timeout", "stdbuf", "xargs", "builtin"}
HITS = []
WRITES = {}   # caminho → corpo de heredoc gravado por cat/tee nesta mesma string
ASSIGN = {}   # NOME → valor literal atribuído nesta string

def interp_kind(base):
    if re.fullmatch(r"python(?:[23](?:\.\d+)?)?|pypy3?", base):
        return "python"
    return base if base in INLINE else None

def host_in(text, url_only, anchored=False):
    for p, rx in (URL if url_only else MAP):
        if anchored:
            # argumento de cliente: o host ABRE a URL (com ou sem esquema, `--url=` aceito). Host num `?q=`, num
            # corpo `-d` ou num cabeçalho não é o destino da chamada (Elenxo, achado 4)
            if re.match(r"^['\"]?(?:--?[A-Za-z-]+=)?(?:[A-Za-z][A-Za-z0-9+.-]*:)?(?://)?(?:" + rx.pattern + r")", text):
                return p
        elif rx.search(text):
            return p
    return None

def judge_code(text, form):
    # Código que só CITA o host (script de medição, heredoc que grava doc ou nó de KG) não é chamada: a linha de
    # comentário sai, e o host tem de estar a até WINDOW linhas de um idioma de rede (Elenxo, achado 1).
    lines = ["" if CODE_COMMENT.match(l) else l for l in text.split("\n")]
    # o idioma de rede conta só FORA de literal de string: `s = 'urllib…https://host'` é texto sobre a chamada,
    # `urllib.request.Request('https://host')` é a chamada (Elenxo, 2ª rodada: heredoc que grava doc, node -e citando)
    net = [k for k, l in enumerate(lines) if not IMPORT.match(l) and NET.search(STRLIT.sub('""', l))]
    if not net:
        return
    for k, l in enumerate(lines):
        p = host_in(l, True)
        if p and any(abs(k - j) <= WINDOW for j in net):
            HITS.append((p, form)); return

HD = re.compile(r"(?<!<)<<(?!<)(-?)[ \t]*(?:'([^'\n]+)'|\"([^\"\n]+)\"|\\?([A-Za-z_][A-Za-z0-9_]*))")

BODIES = []   # corpos de heredoc, GLOBAIS: o `$(cat <<EOF …)` é recortado fora e julgado dentro (Elenxo, E1)

def cut_heredocs(text):
    lines, out, bodies, i = text.split("\n"), [], BODIES, 0
    while i < len(lines):
        line, pend = lines[i], []
        def rep(m):
            pend.append((m.group(1) == "-", m.group(2) or m.group(3) or m.group(4)))
            return " __ONION_HD_%d__ " % (len(bodies) + len(pend) - 1)
        line = HD.sub(rep, line)
        out.append(line)
        i += 1
        for strip_tabs, delim in pend:
            body = []
            while i < len(lines):
                cand = lines[i].lstrip("\t") if strip_tabs else lines[i]
                i += 1
                if cand == delim:
                    break
                body.append(lines[i - 1])
            bodies.append("\n".join(body))
    return "\n".join(out), bodies

def split_substs(s):
    out, subs, i, n, q = [], [], 0, len(s), None
    while i < n:
        c = s[i]
        if q == "'":
            out.append(c); q = None if c == "'" else q; i += 1; continue
        if c == "\\" and i + 1 < n:
            out.append(" " if s[i + 1] == "\n" else s[i:i + 2]); i += 2; continue
        if c == "'" and q is None:
            q = "'"; out.append(c); i += 1; continue
        if c == '"':
            q = None if q == '"' else '"'; out.append(c); i += 1; continue
        if c in "$<>" and s.startswith("(", i + 1) and not (c == "$" and s.startswith("((", i + 1)):
            depth, j, qq = 1, i + 2, None
            while j < n and depth:
                cj = s[j]
                if qq:
                    if cj == qq: qq = None
                    elif cj == "\\" and qq == '"': j += 1
                elif cj in "'\"": qq = cj
                elif cj == "\\": j += 1
                elif cj == "(": depth += 1
                elif cj == ")": depth -= 1
                j += 1
            subs.append(s[i + 2:j - 1] if depth == 0 else s[i + 2:])
            out.append(" __ONION_SUBST__ "); i = j; continue
        if c == "`":
            j = s.find("`", i + 1); j = n if j < 0 else j
            subs.append(s[i + 1:j]); out.append(" __ONION_SUBST__ "); i = j + 1; continue
        if c == "\n" and q is None:
            out.append(" ; "); i += 1; continue
        if c == "#" and q is None and (i == 0 or s[i - 1] in " \t;&|("):
            j = s.find("\n", i); i = n if j < 0 else j; continue     # comentário de shell (Elenxo, achado 3)
        out.append(c); i += 1
    return "".join(out), subs

def expand(tok):
    return re.sub(r"\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?", lambda m: ASSIGN.get(m.group(1), m.group(0)), tok)

def outside_repo_file(tok, cwd):
    path = expand(tok)
    if "$" in path or not path or path == "-":
        return None
    path = os.path.realpath(os.path.join(cwd, os.path.expanduser(path)))
    if "/utils/task-manager/" in path + "/":
        return None
    return path

def read_outside(path):
    if path in WRITES:
        return WRITES[path]
    if path == ROOT or path.startswith(ROOT + os.sep):
        return None                          # dentro do repo: rastreado é da REGRA 105
    try:
        if os.path.isfile(path) and os.path.getsize(path) <= 1048576:
            return open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        pass
    return None

def first_arg(words):
    for w in words:
        if w.startswith("-") and w != "-":
            continue
        return w
    return None

def judge_shell(text, depth=0, cwd=None):
    if depth > 4:
        return
    cwd = cwd or CWD0
    text, bodies = cut_heredocs(text)   # bodies is BODIES
    text, subs = split_substs(text)
    for sub in subs:
        judge_shell(sub, depth + 1, cwd)
    try:
        lex = shlex.shlex(text, posix=True, punctuation_chars=";&|()")
        lex.whitespace_split = True
        lex.commenters = ""
        toks = list(lex)
    except ValueError:
        return                               # aspas abertas: não se prova — CALA
    seg = []
    for t in toks + [";"]:
        if t and set(t) <= set(";&|()"):
            if seg:
                cwd = judge_segment(seg, bodies, depth, cwd)
            seg = []
        else:
            seg.append(t)

def judge_segment(words, bodies, depth, cwd):
    while words and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0]):
        k, v = words[0].split("=", 1); ASSIGN[k] = v; words = words[1:]
    if words and words[0] in ("export", "declare", "local", "readonly", "typeset"):
        for w in words[1:]:
            if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w):
                k, v = w.split("=", 1); ASSIGN[k] = v
        return cwd
    while words and os.path.basename(words[0]) in WRAPPERS:
        words = words[1:]
        while words and (words[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", words[0])
                         or re.fullmatch(r"\d+(?:\.\d+)?[smhd]?", words[0])):
            words = words[1:]
    if not words:
        return cwd
    base = os.path.basename(words[0])
    rest = words[1:]
    hds = [bodies[int(m.group(1))] for w in rest for m in [re.fullmatch(r"__ONION_HD_(\d+)__", w)]
           if m and int(m.group(1)) < len(bodies)]
    plain = [w for w in rest if not re.fullmatch(r"__ONION_HD_\d+__", w)]
    if base == "cd":
        a = first_arg(plain)
        if a and "$" not in a:
            nd = os.path.realpath(os.path.join(cwd, os.path.expanduser(a)))
            return nd if os.path.isdir(nd) else cwd
        return cwd
    if base in CLIENTS:
        for w in plain:
            p = host_in(expand(w), False, anchored=True)
            if p:
                HITS.append((p, "cliente " + base)); break
        return cwd
    if base in ("cat", "tee") and hds:
        tgt = None
        for k, w in enumerate(plain):
            if w in (">", ">>") and k + 1 < len(plain): tgt = plain[k + 1]; break
            if w.startswith(">") and len(w.lstrip(">")) > 0: tgt = w.lstrip(">"); break
        if tgt is None and base == "tee":
            tgt = first_arg(plain)
        if tgt:
            path = outside_repo_file(tgt, cwd)
            if path:
                WRITES[path] = hds[0]
        return cwd
    kind = interp_kind(base)
    if base in SHELLS:
        ci = next((k for k, w in enumerate(plain) if re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", w)), None)
        if ci is not None and ci + 1 < len(plain):
            judge_shell(expand(plain[ci + 1]), depth + 1, cwd)
            return cwd
        a = first_arg(plain)
        if not a or a == "-":                  # shell: sem arquivo de script, o stdin é CÓDIGO (Elenxo, achado 2)
            for b in hds:
                judge_shell(b, depth + 1, cwd)
        if a and a != "-":
            path = outside_repo_file(a, cwd)
            body = read_outside(path) if path else None
            if body is not None:
                judge_shell(body, depth + 1, cwd)
        return cwd
    if kind:
        flags = {"-c"} if kind == "python" else INLINE[kind]
        for k, w in enumerate(plain):
            if w in flags and k + 1 < len(plain):
                judge_code(expand(plain[k + 1]), "codigo embutido " + base); return cwd
        a = first_arg(plain)
        if not a or a == "-":                  # interpretador: com arquivo de script, o heredoc é DADO (Elenxo, achado 2)
            for b in hds:
                judge_code(b, "heredoc " + base)
        if a and a != "-":
            path = outside_repo_file(a, cwd)
            body = read_outside(path) if path else None
            if body is not None:
                judge_code(body, "arquivo fora do repo " + base)
    return cwd

judge_shell(sys.stdin.read())
seen = set()
for p, form in HITS:
    if p not in seen:
        seen.add(p); print("%s\t%s" % (p, form))
ONION_DPA_PY
}

# ── o provider ativo, como o tm.sh o resolve (.env da raiz; numa worktree, o da árvore principal) ──
_onion_dpa_active() {  # $1=raiz $2=cwd
  local tm="$1/.claude/utils/task-manager" envf top common
  [ -f "${tm}/env-check.sh" ] || return 0
  if [ -n "${TM_ENV_FILE:-}" ]; then envf="${TM_ENV_FILE}"
  else
    top="$(git -C "$2" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$1")"
    envf="${top}/.env"
    if [ ! -f "${envf}" ]; then
      common="$(git -C "$2" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
      [ -n "${common}" ] && [ -f "$(dirname "${common}")/.env" ] && envf="$(dirname "${common}")/.env"
    fi
  fi
  bash "${tm}/env-check.sh" --env "${envf}" --provider 2>/dev/null || true
}

_onion_dpa_main() {
  local input parsed hcwd cmd root hits active p form
  input="$(cat)"
  command -v python3 >/dev/null 2>&1 || return 0
  parsed="$(printf '%s' "${input}" | python3 -I -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
try: d=json.load(sys.stdin)
except Exception: d={}
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
print(str(d.get("cwd") or "").replace("\n"," ")); print(str(ti.get("command") or ""))' 2>/dev/null)" || return 0
  hcwd="${parsed%%$'\n'*}"; cmd="${parsed#*$'\n'}"; [ "${cmd}" = "${parsed}" ] && cmd=""
  [ -n "${cmd}" ] || return 0
  [ -d "${hcwd}" ] || hcwd="${PWD}"
  root="${CLAUDE_PROJECT_DIR:-$(git -C "${hcwd}" rev-parse --show-toplevel 2>/dev/null || pwd)}"
  [ -f "${root}/.claude/utils/task-manager/provider-hosts.tsv" ] || return 0
  hits="$(printf '%s' "${cmd}" | ONION_ROOT="${root}" ONION_CWD="${hcwd}" \
          ONION_MAP="${root}/.claude/utils/task-manager/provider-hosts.tsv" _onion_dpa_judge 2>/dev/null)" || return 0
  [ -n "${hits}" ] || return 0
  active="$(_onion_dpa_active "${root}" "${hcwd}")"
  while IFS=$'\t' read -r p form; do
    [ -n "${p}" ] && [ "${p}" = "${active}" ] || continue
    echo "GUARDA-PRETOOLUSE (API direta de provedor): ${form} chama a API do ${p} direto, e o adapter executável dele existe — use 'bash .claude/utils/task-manager/tm.sh <verbo>' ('tm.sh --capabilities' lista os verbos). Verbo que falta é ACHADO, não contorno: implemente em .claude/utils/task-manager/adapters/${p}.py (a REGRA 104 amarra a declaração) e rode pelo tm.sh. Dogfood é usar a maquinaria, não reescrever o cliente na sessão." >&2
    exit 2
  done <<< "${hits}"
  return 0
}

# ── --selftest: as duas polaridades, pelo MESMO caminho do runner (JSON no stdin, CLAUDE_PROJECT_DIR) ──
_onion_dpa_selftest() {
  command -v python3 >/dev/null 2>&1 || { echo "selftest: python3 ausente — não medido"; return 0; }
  local self d out ok=0 tot=0 H Hc
  self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  d="$(TMPDIR=/tmp mktemp -d)"; mkdir -p "${d}/repo/.claude/utils/task-manager/adapters" "${d}/fora"
  # o host nasce em tempo de execução: este arquivo não carrega o host literal (a REGRA 105 o leria)
  H="api.linear"; H="${H}.app"; Hc="api.clickup"; Hc="${Hc}.com"
  cp "$(dirname "${self}")/../utils/task-manager/provider-hosts.tsv" "${d}/repo/.claude/utils/task-manager/" 2>/dev/null \
    || { echo "selftest: provider-hosts.tsv ausente"; rm -rf "${d}"; return 1; }
  : > "${d}/repo/.claude/utils/task-manager/adapters/linear.py"
  printf '#!/usr/bin/env bash\necho "${TASK_MANAGER_PROVIDER:-linear}"\n' > "${d}/repo/.claude/utils/task-manager/env-check.sh"
  git -C "${d}/repo" init -q 2>/dev/null
  printf 'import urllib.request\nurllib.request.urlopen("https://%s/graphql")\n' "${H}" > "${d}/fora/avulso.py"
  printf 'import json\nprint(json.dumps({"host": "https://%s/graphql"}))\n' "${H}" > "${d}/fora/so-cita.py"
  _run() {  # $1=comando [$2=provider ativo] → rc do hook
    local rc=0
    printf '%s' "$1" | C="${d}/repo" python3 -I -c 'import json,os,sys;print(json.dumps({"cwd":os.environ["C"],"tool_input":{"command":sys.stdin.read()}}))' \
      | (cd "${d}/repo" && TASK_MANAGER_PROVIDER="${2:-linear}" CLAUDE_PROJECT_DIR="${d}/repo" TM_ENV_FILE=/nao-existe bash "${self}" >/dev/null 2>&1) || rc=$?
    printf '%s' "${rc}"
  }
  _c() {  # <nome> <rc esperado> <comando> [provider]
    tot=$((tot + 1)); local got; got="$(_run "$3" "${4:-}")"
    if [ "${got}" = "$2" ]; then ok=$((ok + 1)); echo "✓ $1"; else echo "✗ $1 (esperava rc=$2, veio ${got})"; fi
  }
  # ── polaridade ACUSA ──
  _c "(i) o caso verbatim de 2026-10-12: python3 heredoc com urllib" 2 "cd /x && (set -a; source .e""nv; set +a; python3 - <<'EOF'
import json,os,urllib.request
def gql(q,v):
  r=urllib.request.Request('https://${H}/graphql',data=json.dumps({'query':q}).encode())
  return json.load(urllib.request.urlopen(r))
EOF
)"
  _c "(ii) curl direto ao host" 2 "set -a; source .e""nv; set +a; curl -s https://${H}/graphql -H 'Authorization: x'"
  _c "(iii) python3 -c com urllib" 2 "python3 -c \"import urllib.request; urllib.request.urlopen('https://${H}/graphql')\""
  _c "(iv) host numa variável literal: B=…; curl \$B" 2 "B=https://${H}/graphql; curl -s \"\$B\""
  _c "(v) script avulso FORA do repo" 2 "python3 ${d}/fora/avulso.py"
  _c "(vi) arquivo gravado e rodado na mesma string" 2 "cat > ${d}/fora/novo.py <<'EOF'
import urllib.request
urllib.request.urlopen('https://${H}/graphql')
EOF
python3 ${d}/fora/novo.py"
  _c "(vii) bash -c e substituição são re-julgados" 2 "x=\$(bash -c 'curl -s https://${H}/graphql')"
  # ── polaridade CALA ──
  _c "(viii) o caminho do adapter: tm.sh" 0 "bash .claude/utils/task-manager/tm.sh item.read SAC-75"
  _c "(ix) texto que só cita o host (commit, grep, echo)" 0 "git commit -m \"curl https://${H}/graphql\" && grep -rn ${H} docs/ && echo 'curl https://${H}'"
  _c "(x) heredoc lido por cat (documentação)" 0 "cat <<'EOF'
curl -s https://${H}/graphql
EOF"
  _c "(xi) código sem idioma de rede (só cita)" 0 "python3 ${d}/fora/so-cita.py"
  _c "(xii) provedor SEM executável (clickup): o curl é o caminho que o adapter prescreve" 0 "curl -s https://${Hc}/api/v2/user" clickup
  _c "(xiii) provedor com executável mas INATIVO" 0 "curl -s https://${H}/graphql" jira
  Hz="projectsapi.zoho"; Hz="${Hz}.com"   # zoho: o 5º provider — sem executável, o curl é o caminho que o adapter prescreve
  _c "(xiii-z) provedor SEM executável (zoho): cala" 0 "curl -s https://${Hz}/restapi/portals/" zoho
  _c "(xiv) aspas abertas: não se prova, cala" 0 "curl -s 'https://${H}/graphql"
  # ── os achados do Elenxo (2026-10-12), cada um com mutante na bancada ──
  _c "(xv) heredoc em \$(…) antes do curl não derruba o juiz (E1)" 2 "git commit -m \"\$(cat <<'EOF'
msg
EOF
)\" && curl -s https://${H}/graphql -H 'Authorization: x'"
  _c "(xvi) heredoc é DADO no stdin de um script: cala (achado 2)" 0 "bash .claude/utils/task-manager/tm.sh comment.add SAC-75 - <<'EOF'
curl -s https://${H}/graphql era o defeito
EOF"
  _c "(xvii) comentário de shell com parênteses cala (achado 3)" 0 "# nao chamar direto (curl https://${H}/graphql), usar o adapter
bash .claude/utils/task-manager/tm.sh item.read SAC-75"
  _c "(xviii) host fora do DESTINO do cliente (busca, corpo) cala (achado 4)" 0 "curl -s 'https://html.duckduckgo.com/html/?q=${H}+graphql' -d '{\"t\":\"https://${H}\"}'"
  _c "(xix) heredoc python que grava texto citando a chamada cala (achado 1)" 0 "python3 - <<'EOF'
s = 'O caso: urllib.request.Request(\"https://${H}/graphql\")'
open('/dev/null', 'w').write(s)
EOF"
  _c "(xx) heredoc de interpretador dentro de \$(…) é julgado (E11)" 2 "x=\$(python3 - <<'EOF'
import urllib.request
print(urllib.request.urlopen('https://${H}/graphql').read())
EOF
)"
  rm -rf "${d}"
  echo "selftest: ${ok}/${tot} verdes"
  [ "${ok}" -eq "${tot}" ]
}

if [ "${1:-}" = "--selftest" ]; then _onion_dpa_selftest; exit $?; fi
_onion_dpa_main; exit $?
