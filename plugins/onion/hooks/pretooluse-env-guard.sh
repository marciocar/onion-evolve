#!/usr/bin/env bash
# raiz do plugin resolvida PELO PRÓPRIO ARQUIVO (o ambiente do shell não traz a variável)
: "${CLAUDE_PLUGIN_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)}"
# pretooluse-env-guard.sh — VETO (exit 2) a qualquer leitura do .env que entregue os segredos ao modelo.
#
# ── DEFEITO DATADO (2026-10-05, sinal de campo de um hub no dogfood do Zoho) ──────────────────
# O /onion:setup-integration mandava ler o .env com `Read` e afirmava que isso "não expõe valores" — e
# expõe: o arquivo inteiro entra no contexto e no transcript. A 1ª cura trocou a prosa e as permissões
# (40 `Bash(cat .env*)`), e o Elenxo a REPROVOU com razão: `allowed-tools` só PRÉ-APROVA, não proíbe; o
# `Read` seguia livre, `Bash(grep * .env)` seguia liberado no settings, e sob bypassPermissions nada é
# restrito. Proibir exige o único mecanismo que barra sob bypass: o exit 2 do PreToolUse — a capacidade
# que justifica o acoplamento ao Claude Code (CLAUDE.md, postura de acoplamento).
#
# ── O QUE VETA ───────────────────────────────────────────────────────────────────────────────
#   · Read / Grep cujo caminho é um arquivo .env (`.env`, `.env.local`, `.env.prod` …);
#   · Bash em que um COMANDO QUE LÊ recebe um arquivo .env como argumento, ou `< .env`;
#   · Bash INANALISÁVEL (aspas desbalanceadas, eval/xargs) que cita um arquivo .env → fechado.
# ── O QUE PASSA (é o caminho certo, e o veto existe para empurrar para ele) ──────────────────
#   · `set -a; source .env; set +a` e `. .env` — carregam no AMBIENTE, nada é impresso;
#   · o helper `env-check.sh` (nomes de chave e o provider; `--get` só para chaves NÃO-secretas);
#   · `test -f .env` / `[ -f .env ]`, `git …` (ls-files, check-ignore, rm --cached), `cp <exemplo> .env`;
#   · escrita: `>> .env`, `> .env` (quem escreve já tem o valor);
#   · `.env.example`, `.env.sample`, `.env.template`, `.env.dist`, `.env.example.onion`, `.envrc`.
# ── FRONTEIRA DECLARADA ──────────────────────────────────────────────────────────────────────
#   · um script que lê o .env POR DENTRO (`python3 x.py`, `node y.js`) não é visto — o veto julga a linha;
#   · nome de arquivo montado em runtime (`f=.e; cat ${f}nv`) não é visto;
#   · `git show HEAD:.env` não é visto (o .env não deve estar versionado — o setup confere isso);
#   · o MAESTRO lê o .env quando quiser, fora da sessão ou com `! cat .env` — o veto é para o modelo;
#   · `source .env` seguido de eco de UMA variável (`echo $JIRA_API_TOKEN`) não é visto — o despejo inteiro
#     (`env`, `printenv`, `set`, `export -p`, `declare -p`) é barrado; o eco nominal fica como teto;
#   · `sed -i` sobre o .env é barrado (lê e reescreve): o caminho é `env-check.sh --set-provider`;
#   · só o plugin `onion` embarca este veto; quem instala só onion-product/onion-engineering recebe o
#     helper sem o veto (o plugin onion é a dependência recomendada dos dois);
#   · `grep -r`/`rg` sobre uma PASTA lê o .env de dentro dela — o veto julga o argumento, não a recursão;
#   · glob conferido no disco vê a pasta no instante do veto: x.env criado na mesma linha por nome montado
#     em runtime (sem citar .env) escaparia.
# SAC-68 (2026-10-08): 7 vetos numa leva em comando que não lia .env. Glob passou a ser julgado pela regra
# do bash e pelo disco (ver glob_reaches_env); o grep no .env segue vetado e ganhou caminho sancionado
# (`env-check.sh --lint`). Bancada: casos (l) e (m) de run_env_exposure_selftests, 7 mutantes.
# HISTÓRICO: 2 passadas do Elenxo REPROVARAM (2026-10-06) — a 1ª mostrou que trocar permissões não proíbe
# nada; a 2ª, que a quebra de linha não separava comandos (`test -f .env` na 1ª linha liberava o bloco
# inteiro), que comentário e `echo` viravam falso positivo nos blocos da própria cura, e que `git diff
# --no-index`, glob (`cat .e*`, Grep glob) e interpretador inline escapavam. Bancada: run_env_exposure_selftests.
set -uo pipefail
input="$(cat)"
# o script vai por -c e o JSON do hook pela entrada padrão. A 1ª redação usava `python3 - <<'PY'`, e aí o
# heredoc ERA a entrada padrão: o JSON nunca chegava e o veto passava tudo (18 de 18 vetos falharam na 1ª
# bateria — fail-open total, pego antes de registrar o hook).
GUARD_PY=$(cat <<'PY'
import fnmatch, glob, json, os, re, shlex, sys

# ── O QUE É UM ARQUIVO .env ───────────────────────────────────────────────────────────────────
SAFE_SUFFIX = re.compile(r'^(example|sample|template|dist|example\.onion)$', re.I)
PROBES = ('.env', '.env.local', '.env.production', 'app.env')   # alvos contra os quais um GLOB é testado
DOT_PROBES = ('.env', '.env.local', '.env.production')
NONDOT_PROBES = ('app.env', 'prod.env')
# ── GLOB: julgado pela regra do BASH e pelo DISCO, não pela forma (SAC-68, 2026-10-08) ──────────────
# Medido numa leva: 6 vetos em comando que não lia .env nenhum — `*)` de um `case`, `ops/testing/*`,
# `for d in */`, `/home/marcio/*/` e um corpo de heredoc com `**`. A causa era testar o glob contra
# `.env` com fnmatch, que casa `*` com nome oculto; o bash (dotglob desligado, o default) NÃO casa.
# Três regras, nesta ordem: (1) glob que termina em `/` só expande para DIRETÓRIO — nunca é um .env;
# (2) glob cuja última parte começa com `.` alcança um .env oculto — fecha como antes; (3) glob sem
# ponto só alcançaria um `x.env` SEM ponto, e isso se confere no DISCO, na pasta onde o comando roda.
# Fecha (como antes) quando a pasta não é conhecida (cd com variável, subshell com cd, pushd) e quando a
# linha CITA um .env literal em qualquer lugar (`cp .env x.env && cat *` criaria o alvo depois do veto).
CTX = {'base': None, 'strict': True}                  # Read/Grep e entrada sem cwd: fechado, como antes
RAW = {'cmd': ''}

def glob_reaches_env(pattern, b):
    if b.startswith('.') and any(fnmatch.fnmatch(p, b) for p in DOT_PROBES):
        return True
    if not any(fnmatch.fnmatch(p, b) for p in NONDOT_PROBES):
        return False
    # glob que NOMEIA env (`*.env`, `*env*`) declara a intenção, e o disco do topo não basta: `grep -r
    # --include=*.env .` desce às subpastas. Escape que a 1ª redação desta cura abria — pego pelo caso (h2).
    if CTX['strict'] or not CTX['base'] or 'env' in b.lower():
        return True
    # variável ou substituição no caminho (`$HOME/*`, `` `pwd`/* ``): o disco não sabe onde é — fecha.
    # `~` se expande aqui (o bash o expande antes do glob). Escapes da passada adversarial do SAC-68.
    if re.search(r'[$`]', pattern):
        return True
    pattern = os.path.expanduser(pattern)
    hits = glob.glob(pattern if os.path.isabs(pattern) else os.path.join(CTX['base'], pattern))
    return any(is_env_name(os.path.basename(h.rstrip('/'))) for h in hits)

def is_env_name(b):
    b = b.strip()
    if b.lower() == '.env':
        return True
    m = re.match(r'^\.env\.([A-Za-z0-9_.-]+)$', b, re.I)
    if m:
        return not SAFE_SUFFIX.match(m.group(1))
    return bool(re.match(r'^[A-Za-z0-9_-]+\.env$', b, re.I))          # prod.env, app.env

def expand_braces(t):
    m = re.search(r'\{([^{}]*)\}', t)
    if not m:
        return [t]
    out = []
    for alt in m.group(1).split(','):
        out.extend(expand_braces(t[:m.start()] + alt + t[m.end():]))
    return out

def is_env_token(tok):
    t = tok.strip().strip('"\'')
    t = re.sub(r'^[<>]+', '', t)
    t = re.sub(r'^[A-Za-z0-9_.-]*:', '', t) if re.match(r'^[A-Za-z0-9_./-]*:\.?[^/]*$', t) and ':' in t else t  # `:.env`, `HEAD:.env`
    for cand in expand_braces(t):
        if re.search(r'[*?\[]', cand) and cand.endswith('/'):
            continue                                                       # glob de DIRETÓRIO: nunca é um .env
        b = os.path.basename(cand.rstrip('/'))
        if is_env_name(b):
            return True
        if re.search(r'[*?\[]', b) and glob_reaches_env(cand, b):
            return True                                                    # glob que alcança um .env
    return False

def cites_env(text):
    return bool(re.search(r'(^|[\s/<"\'=:(`])\.env(\.[A-Za-z0-9_.-]+)?($|[\s"\';|&)>`])', text)) or \
           bool(re.search(r'[\w-]+\.env\b', text))

# ── QUEM PODE RECEBER UM .env SEM LER O CONTEÚDO ─────────────────────────────────────────────
METADATA = {'source', '.', 'test', '[', '[[', 'ls', 'stat', 'touch', 'chmod', 'chown', 'rm', 'mkdir', 'echo', 'printf',
            'wc', 'du', 'file', 'realpath', 'readlink', 'basename', 'dirname', 'sha256sum', 'sha1sum', 'md5sum', 'b2sum',
            'code', 'open', 'xdg-open'}
WRITERS = {'tee'}                                  # .env como destino
COPIERS = {'cp', 'mv', 'install', 'ln'}
GIT_SAFE = {'ls-files', 'check-ignore', 'rm', 'status', 'add', 'mv', 'update-index'}
WRAPPERS = {'sudo', 'env', 'command', 'builtin', 'time', 'nohup', 'nice', 'exec', 'stdbuf', 'timeout'}
SHELLS = {'bash', 'sh', 'zsh', 'dash'}
INTERP = {'python', 'python3', 'node', 'ruby', 'perl', 'php', 'deno', 'bun'}
DUMPERS = {'env', 'printenv'}
VALUE_FLAGS = {'--exclude', '--exclude-dir', '--env-file', '-e', '--regexp', '-f'}   # o valor seguinte não é arquivo lido
HELPER = 'env-check.sh'

def strip_comments(cmd):
    """`#` que ABRE palavra fora de aspas comenta até o fim da linha (como no bash)."""
    out, q, i = [], None, 0
    while i < len(cmd):
        c = cmd[i]
        if q:
            out.append(c)
            if c == q and (q == "'" or cmd[i - 1] != '\\'):
                q = None
        elif c in '"\'':
            q = c; out.append(c)
        elif c == '#' and (i == 0 or cmd[i - 1] in ' \t\n;&|('):
            while i < len(cmd) and cmd[i] != '\n':
                i += 1
            continue
        else:
            out.append(c)
        i += 1
    return ''.join(out)

def segments(cmd):
    cmd = strip_comments(cmd).replace('\\\n', ' ')
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=';&|()<>\n')
    lex.whitespace = ' \t\r'
    lex.whitespace_split = True
    lex.commenters = ''
    seg, out = [], []
    for t in lex:
        if t and set(t) <= set(';&|()\n'):
            if seg:
                out.append(seg)
            seg = []
        else:
            seg.append(t)
    if seg:
        out.append(seg)
    return out

# ── HEREDOC: o corpo só é DADO quando o PREFIXO INTEIRO prova que é (2026-10-06) ─────────────────
# Medido ao abrir o PR #933: o veto lia cada linha do corpo de um heredoc como comando, e uma linha de
# markdown começando com `**` (glob que casa `.env`) barrou um `cat > corpo.md <<'EOF'` — texto inerte.
# DUAS passadas adversariais reprovaram curas anteriores: a 1ª tratava o corpo como dado por padrão
# (26 escapes: `cat <<E | bash`, `sudo -u x bash`, `ssh h`, `<<END-X`…); a 2ª analisava LINHA A LINHA,
# sem o estado do shell que vem antes (heredoc externo, aspas abertas, `\` de continuação, `<<-` mal
# tokenizado, `>(sh)`, `git -c alias.x='!sh'`, script gravado sem extensão e executado — 9 escapes, todos
# executados de verdade). Por isso a regra é a MAIS ESTREITA que serve ao caso legítimo: o prefixo do
# comando até a linha do operador é analisado INTEIRO e tem de provar — um só `<<`, nenhuma aspa aberta,
# nenhum `\` de continuação, nenhuma substituição (`$(`, `<(`, `>(`, crase), nenhum pipe adiante, o
# consumidor numa lista FECHADA (cat, tee, gh sem alias, ou exatamente `git commit`), delimitador de
# palavra simples e terminador presente. Qualquer dúvida → nada se separa e tudo é julgado como na main.
# E um corpo que CITA .env e vai para ARQUIVO é sempre vetado: qualquer arquivo pode virar script depois.
HEREDOC_ANY = re.compile(r'(?<!<)<<(?!<)')
HEREDOC_WORD = re.compile(r'(?<!<)<<(-?)[ \t]*((?:[A-Za-z0-9_.-]|"[^"\n]*"|\'[^\'\n]*\'|\\.)+)(?=$|[\s;|&<>)])')
REDIRS = {'>', '>>', '>|', '&>', '&>>', '1>', '1>>'}

def _consumer_ok(seg):
    args = [t for t in seg if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', t)]
    if not args:
        return None
    name = args[0]
    if name in ('cat', 'tee'):
        return name
    if name == 'gh' and 'alias' not in args:
        return name
    if name == 'git' and len(args) > 1 and args[1] == 'commit':
        return name
    return None

def split_heredocs(cmd):
    """Devolve (comando sem o corpo PROVADO como dado, [(entre aspas?, gravado em arquivo?, corpo)])."""
    lines = cmd.split('\n')
    idx = next((i for i, l in enumerate(lines) if HEREDOC_ANY.search(l)), None)
    if idx is None:
        return cmd, []
    prefix = '\n'.join(lines[:idx + 1])
    line = lines[idx]
    if (re.search(r'\$\(|<\(|>\(|`', prefix) or re.search(r'\\$', '\n'.join(lines[:idx]), re.M)
            or line.rstrip().endswith('\\') or len(HEREDOC_ANY.findall(prefix)) != 1):
        return cmd, []
    m = HEREDOC_WORD.search(line)
    if not m:
        return cmd, []
    word, dash = m.group(2), m.group(1) == '-'
    delim = re.sub(r'["\'\\]', '', word)
    if not re.match(r'^[A-Za-z0-9_.-]+$', delim):
        return cmd, []
    quoted = bool(re.search(r'["\'\\]', word))
    try:
        lex = shlex.shlex(strip_comments(prefix), posix=True, punctuation_chars=';&|()<>')
        lex.whitespace_split = True
        lex.commenters = ''
        toks = list(lex)
    except ValueError:
        return cmd, []                                   # aspas abertas no prefixo
    if toks.count('<<') != 1:
        return cmd, []                                   # `<<` dentro de aspas, ou outro operador
    k = toks.index('<<')
    if any('|' in t for t in toks[k:]):
        return cmd, []                                   # o corpo seguiria para outro comando
    b = max([i for i, t in enumerate(toks[:k]) if t and set(t) <= set(';&|()\n')] or [-1]) + 1
    seg = toks[b:]
    name = _consumer_ok(seg[:seg.index('<<')])
    if not name:
        return cmd, []
    _around = line[m.end():] + ' ' + line[:m.start()]
    # gravado: tee, redirecionamento para arquivo, ou para um descritor >= 3 (que pode ser um arquivo aberto antes)
    written = (name == 'tee' or any(t in REDIRS for t in seg) or bool(re.search(r'(^|\s)\d*>{1,2}\s*[^&\s]', _around))
               or bool(re.search(r'>&\s*[3-9]', _around)))
    j = idx + 1
    while j < len(lines) and (lines[j].lstrip('\t') if dash else lines[j]) != delim:
        j += 1
    if j >= len(lines):
        return cmd, []                                   # terminador ausente
    body = '\n'.join(lines[idx + 1:j])
    rest_cmd, rest_docs = split_heredocs('\n'.join(lines[j + 1:]))
    return '\n'.join(lines[:idx + 1] + ([rest_cmd] if j + 1 < len(lines) else [])), [(quoted, written, body)] + rest_docs

def judge_heredocs(docs, depth):
    for quoted, written, body in docs:
        if written and cites_env(body):
            return 'heredoc que grava em ARQUIVO um texto citando um arquivo .env (pode virar script) — escreva com a ferramenta Write'
        if not quoted and re.search(r'\$\(|`', body) and cites_env(body):
            return 'heredoc sem aspas com substituição de comando que cita um arquivo .env'
    return None

def judge(cmd, depth=0):
    """None = passa; str = motivo do veto."""
    if depth > 4:
        return 'aninhamento de shell profundo demais para provar'
    cmd, docs = split_heredocs(cmd)
    r = judge_heredocs(docs, depth)
    if r:
        return r
    try:
        segs = segments(cmd)
    except ValueError:
        return 'comando inanalisável que cita um arquivo .env' if cites_env(cmd) else None
    sourced = False
    for seg in segs:
        # redirecionamentos: `< .env` lê; `<<< STR` para shell é código
        for i, t in enumerate(seg):
            if t in ('<', '<<<') and i + 1 < len(seg) and is_env_token(seg[i + 1]):
                return 'redirecionar um arquivo .env para a entrada de um comando'
        toks = [t for t in seg if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', t)] or seg
        args = [t for i, t in enumerate(toks) if t not in ('>', '>>', '<', '<<<', '2>', '&>')
                and not (i > 0 and toks[i - 1] in ('>', '>>'))]
        # `env` sozinho (ou só com opções) depois de carregar o .env DESPEJA o ambiente — julgado antes de ser tirado como invólucro
        if sourced and args and os.path.basename(args[0]) in DUMPERS and all(x.startswith('-') for x in args[1:]):
            return "carregar o .env e despejar o ambiente ('%s') no mesmo comando" % os.path.basename(args[0])
        # palavras-chave do shell não são o comando (`if ! grep … .gitignore` é o grep)
        while args and args[0] in ('if', 'then', 'else', 'elif', 'while', 'until', 'do', '!', '{', '}', 'fi', 'done'):
            args = args[1:]
        while args and args[0] in WRAPPERS:
            args = args[1:]
            while args and args[0].startswith('-'):
                args = args[1:]
        if not args:
            continue
        name = os.path.basename(args[0])
        # a pasta onde os próximos segmentos rodam (para o glob conferido no disco)
        if name in ('pushd', 'popd'):
            CTX['base'] = None
        elif name == 'cd':
            tgt = args[1] if len(args) > 1 else '~'
            if CTX['base'] and '(' not in RAW['cmd'] and not re.search(r'[$`*?\[]', tgt) and tgt != '-':
                CTX['base'] = os.path.normpath(os.path.join(CTX['base'], os.path.expanduser(tgt)))
            else:
                CTX['base'] = None
        if is_env_token(args[0]):
            return 'um arquivo .env na posição de comando (nome montado em runtime)'
        # o que segue um VALUE_FLAG é valor, não arquivo lido
        files = [a for i, a in enumerate(args[1:], 1)
                 if not (args[i - 1] in VALUE_FLAGS) and not re.match(r'^--(exclude|exclude-dir|env-file)=', a)]
        inc = [a.split('=', 1)[1] for a in args if a.startswith('--include=')] + \
              [args[i + 1] for i, a in enumerate(args[:-1]) if a == '--include']
        envs = [a for a in files if is_env_token(a)] + [g for g in inc if is_env_token(g)]
        if name in SHELLS and len(args) > 1:
            if args[1] == '-c' and len(args) > 2:
                r = judge(args[2], depth + 1)
                if r:
                    return r
                continue
            if os.path.basename(args[1]) == HELPER:
                continue
            if '<<<' in seg:
                k = seg.index('<<<')
                if k + 1 < len(seg):
                    r = judge(seg[k + 1], depth + 1)
                    if r:
                        return r
        if name in INTERP and any(a in ('-c', '-e', '-r', '--eval') for a in args) and any(cites_env(a) for a in args[1:]):
            return 'interpretador com código inline que cita um arquivo .env'
        if name in ('eval', 'xargs') and any(is_env_token(a) or cites_env(a) for a in args[1:]):
            return 'eval/xargs com um arquivo .env não pode ser provado inofensivo'
        if name in ('source', '.') and envs:
            sourced = True
            continue
        if sourced and (name in DUMPERS or (name in ('export', 'declare', 'typeset') and '-p' in args)
                        or (name == 'set' and len(args) == 1)):
            return "carregar o .env e despejar o ambiente ('%s') no mesmo comando" % name
        if not envs:
            continue
        if name == 'git':
            sub = next((a for a in args[1:] if not a.startswith('-')), '')
            if sub in GIT_SAFE:
                continue
            return "'git %s' sobre um arquivo .env mostra o conteúdo" % sub
        if name == 'find' and not any(a.startswith(('-exec', '-ok')) for a in args):
            continue
        if name in METADATA:
            continue
        if name in WRITERS and all(is_env_token(a) for a in files if not a.startswith('-')):
            continue
        if name in COPIERS:
            rest = [a for a in files if not a.startswith('-')]
            if rest and (is_env_token(rest[-1]) and not any(is_env_token(a) for a in rest[:-1]) or all(is_env_token(a) for a in rest)):
                continue                  # .env só como DESTINO, ou cópia/rename entre arquivos .env
        return "'%s' lendo %s" % (name, envs[0])
    return None

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
d = d if isinstance(d, dict) else {}
tool = d.get('tool_name') or ''
ti = d.get('tool_input') or {}
reason = None
if tool == 'Read':
    if is_env_token(str(ti.get('file_path') or '')):
        reason = 'Read de um arquivo .env'
elif tool == 'Grep':
    if is_env_token(str(ti.get('path') or '')) or (ti.get('glob') and is_env_token(str(ti.get('glob')))):
        reason = 'Grep sobre um arquivo .env (caminho ou glob)'
elif tool == 'Bash':
    RAW['cmd'] = str(ti.get('command') or '')
    CTX['base'] = str(d.get('cwd') or '') or os.getcwd()
    CTX['strict'] = cites_env(RAW['cmd'])            # um .env literal na linha: o glob volta a fechar
    reason = judge(RAW['cmd'])
print(reason or '')
PY
)
out="$(printf '%s' "$input" | python3 -c "$GUARD_PY")" || out="o analisador do veto falhou — fechado por segurança"
[ -z "${out}" ] && exit 0
echo "GUARDA-PRETOOLUSE (.env): ${out} — o conteúdo do .env (os segredos) entraria no contexto e no transcript. Use: 'bash ${CLAUDE_PLUGIN_ROOT}/utils/task-manager/env-check.sh --provider|--check|--get <CHAVE-NÃO-SECRETA>', ou carregue no ambiente com 'set -a; source .env; set +a'. Se precisar ver o arquivo, o maestro o abre fora da sessão." >&2
exit 2
