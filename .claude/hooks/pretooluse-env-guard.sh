#!/usr/bin/env bash
# pretooluse-env-guard.sh — VETO (exit 2) a qualquer leitura do .env que entregue os segredos ao modelo.
#
# ── DEFEITO DATADO (2026-10-05, sinal de campo de um hub no dogfood do Zoho) ──────────────────
# O /meta:setup-integration mandava ler o .env com `Read` e afirmava que isso "não expõe valores" — e
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
#   · `.env.example`, `.env.sample`, `.env.template`, `.env.dist`, `.env.example.onion`, `.envrc`;
#   · (U4, 2026-10-20) LISTAR, NOMEAR e CITAR: `find … \( -name '.env*' \) -print`, `grep -o '^[A-Z_]*='` (padrão
#     que só casa nome de chave), heredoc que grava prosa em arquivo de DADOS (.md/.txt/.json…) citando um .env,
#     o padrão de um `case`, `python3 - <<'EOF'` cujo código não cita .env, `bash $H` com H=…/env-check.sh.
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
#     em runtime (sem citar .env) escaparia;
#   · (U4) `grep -o` de nomes ainda imprime um pedaço de valor MULTILINHA cuja linha de continuação tenha a forma
#     de nome (`PARTE=` no meio de uma chave PEM) — fragmento, nunca a linha; e `grep -c/-q/-l` seguem barrados
#     (oráculo de 1 bit; selo D_GREP_E_HEREDOC_SEGUEM_VETADOS de 2026-10-08, que o U4 restringe só no -o de nomes);
#   · (U4) a pasta de um glob com `$D` usa a ÚLTIMA atribuição literal da linha, sem ver ramos (`if …; then D=a;
#     else D=b; fi`); o heredoc de dados prova o arquivo pela EXTENSÃO, e o `bash x.md` que o executaria é barrado,
#     mas `python3 x.md` não (é a fronteira do script que lê por dentro, acima);
#   · (U4) residual medido no replay e NÃO curado: `{ cat <<'EOF' … } > $R` (grupo) e `grep -l` sobre `.env*`.
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

# ── shlex LINEAR (fix/vetos-fail-closed, 2026-10-11) ───────────────────────────────────────────
# O shlex da stdlib monta cada token com `self.token += nextchar`. Num ATRIBUTO o CPython não otimiza a
# concatenação no lugar, e cada caractere copia o token inteiro: custo quadrático no comprimento do token.
# Medido depois de curar o regex de cites_env: 15 s num token único de 1 MB, quase tudo em read_token. A
# cura troca só o ACUMULADOR: `token` vira uma propriedade que guarda os pedaços numa lista e entrega a
# string montada uma vez, no fim do token. A máquina de estados do shlex é a mesma, e os tokens também.
# Se uma versão futura do Python mudar o read_token, o pior caso é perder a otimização ou estourar uma
# exceção; e exceção aqui cai no `|| out=…` lá embaixo, que FECHA (nunca abre).
class _TokenAcc:
    __slots__ = ('parts', 'n')
    def __init__(self, s=''):
        self.parts = [s] if s else []
        self.n = len(s)
    def __iadd__(self, s):
        self.parts.append(s); self.n += len(s)
        return self
    def __bool__(self):
        return self.n > 0
    def __len__(self):
        return self.n
    def __str__(self):
        if len(self.parts) > 1:
            self.parts = [''.join(self.parts)]
        return self.parts[0] if self.parts else ''
    def __eq__(self, other):
        return str(self) == (str(other) if isinstance(other, _TokenAcc) else other)
    __hash__ = None

class LinearShlex(shlex.shlex):
    @property
    def token(self):
        return self._acc
    @token.setter
    def token(self, v):
        self._acc = v if isinstance(v, _TokenAcc) else _TokenAcc(v)
    def read_token(self):
        r = super().read_token()
        return str(r) if isinstance(r, _TokenAcc) else r

# ── O QUE É UM ARQUIVO .env ───────────────────────────────────────────────────────────────────
SAFE_SUFFIX = re.compile(r'^(example|sample|template|dist|example\.onion)$', re.I)
PROBES = ('.env', '.env.local', '.env.production', 'app.env')   # alvos contra os quais um GLOB é testado
DOT_PROBES = ('.env', '.env.local', '.env.production')
NONDOT_PROBES = ('app.env', 'prod.env')
# ── GLOB: julgado pela regra do BASH e pelo DISCO, não pela forma (SAC-68, 2026-10-08) ──────────────
# Medido numa leva: 6 vetos em comando que não lia .env nenhum — `*)` de um `case`, `ops/testing/*`,
# `for d in */`, `/home/<usuario>/*/` e um corpo de heredoc com `**`. A causa era testar o glob contra
# `.env` com fnmatch, que casa `*` com nome oculto; o bash (dotglob desligado, o default) NÃO casa.
# Três regras, nesta ordem: (1) glob que termina em `/` só expande para DIRETÓRIO — nunca é um .env;
# (2) glob cuja última parte começa com `.` alcança um .env oculto — fecha como antes; (3) glob sem
# ponto só alcançaria um `x.env` SEM ponto, e isso se confere no DISCO, na pasta onde o comando roda.
# Fecha (como antes) quando a pasta não é conhecida (cd com variável, subshell com cd, pushd) e quando a
# linha CITA um .env literal em qualquer lugar (`cp .env x.env && cat *` criaria o alvo depois do veto).
CTX = {'base': None, 'strict': True}                  # Read/Grep e entrada sem cwd: fechado, como antes
RAW = {'cmd': ''}

def _fnm(name, pat):
    """fnmatch sem o caso quadrático da stdlib (passada adversarial, 2026-10-11): o translate varre até o
    fim a cada `[` sem `]` depois dele — 172 s num token de 80 KB de `[`. Um `[` depois do ÚLTIMO `]` nunca
    fecha, então é literal, e nenhum alvo testado aqui contém `[`: o resultado é False, como na stdlib."""
    if '[' in pat[pat.rfind(']') + 1:] and '[' not in name:
        return False
    return fnmatch.fnmatch(name, pat)

def glob_reaches_env(pattern, b):
    if b.startswith('.') and any(_fnm(p, b) for p in DOT_PROBES):
        return True
    if not any(_fnm(p, b) for p in NONDOT_PROBES):
        return False
    # glob que NOMEIA env (`*.env`, `*env*`) declara a intenção, e o disco do topo não basta: `grep -r
    # --include=*.env .` desce às subpastas. Escape que a 1ª redação desta cura abria — pego pelo caso (h2).
    if CTX['strict'] or not CTX['base'] or 'env' in b.lower():
        return True
    # variável ou substituição no caminho (`$HOME/*`, `` `pwd`/* ``): o disco não sabe onde é — fecha.
    # `~` se expande aqui (o bash o expande antes do glob). Escapes da passada adversarial do SAC-68.
    _av = CTX.get('assigned') or {}
    pattern = re.sub(r'\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?', lambda m: _av.get(m.group(1), m.group(0)), pattern)
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

# `(?<=[\w-])\.env\b` no lugar de `[\w-]+\.env\b`: a mesma pergunta (há um `.env` colado a um caractere de
# palavra?), sem backtracking. A forma antiga recomeçava de cada posição de uma palavra longa, varria até o
# fim e voltava: quadrática. Medido em 2026-10-11, token único de 300 KB: 186 s; perto de 520 KB passaria do
# timeout de 600 s e o onFailure block BARRARIA (Q_ENV_GUARD_QUADRATICO_ATINGE_TIMEOUT). Só o booleano importa,
# e o booleano é idêntico: existe match ⇔ existe `.env` com um [\w-] imediatamente antes e \b depois.
CITES_DOT = re.compile(r'(^|[\s/<"\'=:(`])\.env(\.[A-Za-z0-9_.-]+)?($|[\s"\';|&)>`])')
CITES_NAMED = re.compile(r'(?<=[\w-])\.env\b')

def cites_env(text):
    return bool(CITES_DOT.search(text)) or bool(CITES_NAMED.search(text))

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
# SAC-149 (2026-10-15, medido no --update de um adotante): um grep cujo PADRÃO era a regex dos nomes de hook (pasta
# de hooks seguida de `[A-Za-z0-9_.-]*`), numa linha que também rodava `test -f .env`,
# era vetado. O `.env` literal da linha liga o modo estrito, e o veto julgava o PADRÃO do grep como um glob que
# alcança `.env` (`[A-Za-z0-9_.-]*` casa `.env` no fnmatch). O padrão não é arquivo: o grep o lê como regex.
# Sem -e/-f (nem cluster curto que os contenha, que erra para o veto), o 1º posicional sai da lista de lidos.
# PASSADA ADVERSARIAL (2026-10-15): o GNU getopt aceita ABREVIAÇÃO de opção longa (`--reg=.` é `--regexp=.`, medido
# no grep 3.11 lendo o arquivo), então toda opção longa que é prefixo de --regexp ou --file conta como "padrão por
# flag" e o veto volta; e o `rg` saiu da lista: um RIPGREP_CONFIG_PATH injeta --regexp sem aparecer na linha.
# Variável GREP_* no segmento também devolve o veto. Na dúvida, o padrão é tratado como arquivo — erra para o veto.
GREPS = {'grep', 'egrep', 'fgrep'}

def grep_pattern_index(args):
    """índice do posicional que é o PADRÃO do grep, ou None se o padrão vem por -e/-f (ou não dá para saber)."""
    for a in args[1:]:
        if a == '--':
            break
        if a.startswith('--') and len(a) > 2:
            _ln = a[2:].split('=', 1)[0]
            if 'regexp'.startswith(_ln) or 'file'.startswith(_ln):
                return None
            continue
        if a.startswith('-') and not a.startswith('--') and ('e' in a[1:] or 'f' in a[1:]):
            return None
    dd = False
    for i, a in enumerate(args[1:], 1):
        if not dd and a == '--':
            dd = True; continue
        if dd or not a.startswith('-'):
            return i
    return None

# ── U4 (2026-10-20, sinal de campo de um hub adotante + REPLAY dos vetos reais) ──────────────────────────────
# Os 100 vetos gravados nos transcripts desta máquina foram re-julgados pela main de 2026-10-20: 44 comandos
# distintos ainda eram barrados, e a maioria não lia valor nenhum. As classes curadas aqui, uma por função:
#   · `find . \( -name x -o -name y \) -print`: o shlex tomava `\(` por operador e o segmento seguinte começava
#     em `-name`, julgado como o comando que lia `.env*` (quote_escaped_punct);
#   · o padrão de um `case` (`*)`, `docs/onion/*)`) era julgado como COMANDO, e um glob em posição de comando
#     numa pasta desconhecida fecha: o laço que resolvia conflito de rebase foi vetado (case_patterns);
#   · `grep -o` com um padrão que só casa NOME de chave (`^[A-Z_]*=`) lia o .env para imprimir só nomes
#     (grep_names_only). O que imprime linha inteira (grep sem -o, -c, -q) segue barrado: selo de 2026-10-08;
#   · heredoc que grava PROSA em arquivo de dados (.md, .txt, .json…) citando um .env (o relatório de update):
#     ver split_heredocs. Arquivo sem extensão de dados segue barrado, e executar um arquivo de dados com um
#     shell (`bash x.md`) passa a ser barrado, porque é o que fecharia o "pode virar script";
#   · heredoc para interpretador (`python3 - <<'EOF'`) é CÓDIGO e se julga como `python3 -c`: barra se citar .env;
#   · ESCAPE ANTERIOR achado no caminho: `echo "$(cat .env)"` passava, porque o shlex entrega a substituição entre
#     aspas duplas como um token só. Toda substituição fora de aspas simples é julgada agora (substitutions).
def quote_escaped_punct(cmd):
    """`\\(` `\\)` `\\;` fora de aspas são LITERAIS no bash; vira a palavra `'\\('`, que o shlex não toma por operador."""
    out, q, i, n = [], None, 0, len(cmd)
    while i < n:
        c = cmd[i]
        if q:
            out.append(c)
            if q == '"' and c == '\\' and i + 1 < n:
                out.append(cmd[i + 1]); i += 2; continue
            if c == q:
                q = None
        elif c in '"\'':
            q = c; out.append(c)
        elif c == '\\' and i + 1 < n:
            out.append("'\\" + cmd[i + 1] + "'" if cmd[i + 1] in '();&|<>' else c + cmd[i + 1]); i += 2; continue
        else:
            out.append(c)
        i += 1
    return ''.join(out)

def substitutions(cmd):
    """o texto de cada `$(…)` e de cada crase fora de aspas SIMPLES, inclusive dentro de aspas duplas.
    Substituição sem fechar devolve o resto do texto: na dúvida, julga-se mais, nunca menos."""
    out, i, n, dq = [], 0, len(cmd), False
    while i < n:
        c = cmd[i]
        if c == '\\':
            i += 2; continue
        if c == "'" and not dq:
            j = cmd.find("'", i + 1)
            i = n if j < 0 else j + 1; continue
        if c == '"':
            dq = not dq; i += 1; continue
        if c == '$' and cmd[i + 1:i + 2] == '(':
            j, d, qq = i + 2, 1, None
            while j < n and d:
                cj = cmd[j]
                if qq:
                    if cj == qq:
                        qq = None
                    elif cj == '\\' and qq == '"':
                        j += 1
                elif cj in '"\'':
                    qq = cj
                elif cj == '\\':
                    j += 1
                elif cj == '(':
                    d += 1
                elif cj == ')':
                    d -= 1
                j += 1
            out.append(cmd[i + 2:j - 1] if d == 0 else cmd[i + 2:])
            i = j; continue
        if c == '`':
            j = cmd.find('`', i + 1)
            out.append(cmd[i + 1:j] if j > 0 else cmd[i + 1:])
            i = n if j < 0 else j + 1; continue
        i += 1
    return out

def substitutions_closed(text):
    """True se toda substituição aberta no texto (fora de aspas simples) fecha nele, sem `<(`/`>(`."""
    if re.search(r'[<>]\(', text):
        return False
    i, n, dq = 0, len(text), False
    while i < n:
        c = text[i]
        if c == '\\':
            i += 2; continue
        if c == "'" and not dq:
            j = text.find("'", i + 1)
            if j < 0:
                return False
            i = j + 1; continue
        if c == '"':
            dq = not dq; i += 1; continue
        if c == '$' and text[i + 1:i + 2] == '(':
            j, d, qq = i + 2, 1, None
            while j < n and d:
                cj = text[j]
                if qq:
                    if cj == qq:
                        qq = None
                elif cj in '"\'':
                    qq = cj
                elif cj == '(':
                    d += 1
                elif cj == ')':
                    d -= 1
                j += 1
            if d:
                return False
            i = j; continue
        if c == '`':
            j = text.find('`', i + 1)
            if j < 0:
                return False
            i = j + 1; continue
        i += 1
    return not dq

# grep -o que só imprime NOME de chave. O padrão tem de provar: ancorado em `^`, feito de letras, dígitos, `_`,
# espaço, `#`, classes só desses caracteres (sem negação, faixas dentro de um mesmo grupo: `[0-z]` contém `=` e
# devolveria o valor), alternância só dentro de parênteses (`^A|[A-Z]*=` casaria no meio do valor), e o `=`, se
# houver, é o ÚLTIMO caractere. Sem `=`, o padrão precisa de uma palavra literal de 4+ caracteres (`LINEAR`).
_CLASS_ITEM = re.compile(r'\[:(upper|lower|alpha|digit|alnum|space|blank):\]|[A-Z]-[A-Z]|[a-z]-[a-z]|[0-9]-[0-9]|[A-Za-z0-9_ ]')
GREP_NAME_FLAGS = set('oEPGFiIwxnhHsr')
GREP_NAME_LONG = {'--only-matching', '--extended-regexp', '--perl-regexp', '--basic-regexp', '--ignore-case',
                  '--no-filename', '--with-filename', '--line-number', '--no-messages', '--word-regexp',
                  '--line-regexp', '--recursive', '--color', '--colour'}

def _safe_class(inner):
    i = 0
    while i < len(inner):
        m = _CLASS_ITEM.match(inner, i)
        if not m:
            return False
        g = m.group(0)
        if len(g) == 3 and g[1] == '-' and g[0] > g[2]:
            return False
        i = m.end()
    return bool(inner)

def names_only_pattern(p):
    if not p.startswith('^'):
        return False
    body = p[1:]
    if '=' in body and (body.count('=') != 1 or not body.endswith('=')):
        return False
    i, depth, lits = 0, 0, re.sub(r'\[(?:\[:[a-z]+:\]|[^\]])*\]', ' ', body)
    if not body.endswith('=') and ('|' in body or not re.search(r'[A-Za-z0-9_]{4,}', lits)):
        return False
    while i < len(body):
        c = body[i]
        if c == '[':
            k = i + 1
            if body[k:k + 1] in ('^', '!'):
                return False
            while k < len(body) and body[k] != ']':
                if body.startswith('[:', k):
                    e = body.find(':]', k)
                    if e < 0:
                        return False
                    k = e + 2
                else:
                    k += 1
            if k >= len(body) or not _safe_class(body[i + 1:k]):
                return False
            i = k + 1; continue
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth < 0:
                return False
        elif c == '|':
            if depth == 0:
                return False
        elif c == '{':
            m = re.match(r'\{\d*,?\d*\}', body[i:])
            if not m:
                return False
            i += m.end(); continue
        elif not (c.isascii() and (c.isalnum() or c in '_ #=*+?')):
            return False
        i += 1
    return depth == 0

def grep_names_only(args, seg):
    """True se o grep, como escrito, só pode imprimir NOMES de chave (e caminho/número de linha)."""
    if any(re.match(r'^GREP_[A-Z_]*=', t) for t in seg):
        return False
    pi = grep_pattern_index(args)
    if pi is None or not names_only_pattern(args[pi]):
        return False
    has_o, skip = False, False
    # o GNU getopt PERMUTA: opção depois do padrão e do arquivo vale (`grep -o P .env -A3`, passada do U4).
    # Todo argumento com `-` é julgado como opção, exceto depois de `--`.
    _dd = args.index('--') if '--' in args else len(args)
    for a in [x for i, x in enumerate(args[1:_dd], 1) if i < pi or x.startswith('-')]:
        if skip:
            if not a.isdigit():
                return False
            skip = False; continue
        if a.startswith('--'):
            base = a.split('=', 1)[0]
            if base == '--max-count':
                if '=' not in a:
                    skip = True
                continue
            if base not in GREP_NAME_LONG:
                return False
            has_o = has_o or base == '--only-matching'
            continue
        fl = a[1:]
        if fl.startswith('m') or re.match(r'^[A-Za-z]*m\d*$', fl):
            pre, _, num = fl.partition('m')
            if set(pre) - GREP_NAME_FLAGS or (num and not num.isdigit()):
                return False
            has_o = has_o or 'o' in pre
            skip = not num
            continue
        if not fl or set(fl) - GREP_NAME_FLAGS:
            return False
        has_o = has_o or 'o' in fl
    return has_o and not skip

# heredoc que grava em arquivo de DADOS: a prosa pode citar um .env (U4). O "pode virar script" se fecha do
# outro lado: um shell que executa um arquivo de dados é barrado em judge().
DATA_EXT = ('.md', '.txt', '.json', '.yaml', '.yml', '.csv', '.tsv', '.log', '.html', '.xml')

def is_data_file(path):
    p = path.strip().strip('"\'')
    return p.lower().endswith(DATA_EXT) and not is_env_token(p)

# SAC-149, falso positivo 1 (um `*.env` de trabalho que a sessão gravou no scratchpad, vetado na leitura): a cura
# por CONTEÚDO foi tentada e REPROVADA na passada adversarial de 2026-10-15 — `cp .env <scratch>/x.env; cat …` num
# comando só lia o segredo (o hook julga antes de o cp rodar), e "sem cara de segredo" deixava passar DB_PW=… e
# URL com credencial. Fica o veto, e a mensagem diz a saída honesta: o arquivo de trabalho não se chama *.env.
SCRATCH_RE = re.compile(r'^/tmp/claude-[0-9]+/.+/scratchpad/')

def scratch_hint(tok):
    return SCRATCH_RE.match(tok.strip().strip('"\'')) is not None

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

KEYWORDS = ('if', 'then', 'else', 'elif', 'while', 'until', 'do', '!', '{', '}', 'fi', 'done', 'esac')

def _tokens(cmd):
    cmd = quote_escaped_punct(strip_comments(cmd).replace('\\\n', ' '))
    lex = LinearShlex(cmd, posix=True, punctuation_chars=';&|()<>\n')
    lex.whitespace = ' \t\r'
    lex.whitespace_split = True
    lex.commenters = ''
    return list(lex)

def _is_sep(t):
    return bool(t) and set(t) <= set(';&|()\n')

def segments(cmd):
    """Os comandos da linha. Os PADRÕES de um `case` (`a|b)`, `*)`) não são comandos e saem (U4): só a
    palavra literal sai, e um padrão com `$`, crase ou redirecionamento devolve a separação sem esta regra."""
    toks = _tokens(cmd)
    plain = _segments_plain(toks)
    seg, out, depth, pat, pat_n = [], [], 0, False, 0
    for t in toks:
        if pat:
            if '$' in t or '`' in t or t.startswith(('<', '>')):
                return plain
            if t == ')':
                pat = False; continue
            if t in ('|', '(', '\n'):
                continue
            if t == 'esac' and pat_n == 0:
                depth -= 1; pat = False; continue
            pat_n += 1
            continue
        if t == 'in' and len(seg) >= 2 and seg[-2] == 'case' and all(x in KEYWORDS for x in seg[:-2]):
            seg = []; pat = True; pat_n = 0; depth += 1
            continue
        if depth > 0 and t in (';;', ';&', ';;&'):
            if seg:
                out.append(seg)
            seg = []; pat = True; pat_n = 0
            continue
        if depth > 0 and t == 'esac' and not seg:
            depth -= 1; continue
        if _is_sep(t):
            if seg:
                out.append(seg)
            seg = []
        else:
            seg.append(t)
    if pat or depth:
        return plain
    if seg:
        out.append(seg)
    return out

def _segments_plain(toks):
    seg, out = [], []
    for t in toks:
        if _is_sep(t):
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
# E um corpo que CITA .env e vai para ARQUIVO é vetado: qualquer arquivo pode virar script depois.
# U4 (2026-10-20) afrouxou DUAS cláusulas, cada uma com o seu fecho: (1) substituição no prefixo vale se fecha
# ANTES do operador e depois dele (o `<<` dentro dela segue recusado); (2) o arquivo de DADOS (.md, .txt…) com
# destino resolvido pode receber prosa citando .env, e executar um arquivo de dados com um shell é barrado.
HEREDOC_ANY = re.compile(r'(?<!<)<<(?!<)')
HEREDOC_WORD = re.compile(r'(?<!<)<<(-?)[ \t]*((?:[A-Za-z0-9_.-]|"[^"\n]*"|\'[^\'\n]*\'|\\.)+)(?=$|[\s;|&<>)])')
REDIRS = {'>', '>>', '>|', '&>', '&>>', '1>', '1>>'}

INTERP_STDIN_OK = {'-', '-I', '-u', '-B', '-E', '-s', '-S', '-q', '-O', '-OO', '-IB', '-Iu', '-uI', '-BI'}

def _consumer_ok(seg):
    args = [t for t in seg if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', t)]
    if not args:
        return None
    if args[0] == 'timeout':                         # `timeout 60 python3 -I -`: o invólucro não muda o consumidor
        args = args[1:]
        while args and args[0].startswith('-'):
            args = args[1:]
        args = args[1:]
        if not args:
            return None
    name = args[0]
    if name in ('cat', 'tee'):
        return name
    if name == 'gh' and 'alias' not in args:
        return name
    if name == 'git' and len(args) > 1 and args[1] == 'commit':
        return name
    # U4: interpretador lendo o PROGRAMA da entrada padrão (`python3 -I - <<'EOF'`): o corpo é código e se julga
    # como `python3 -c` (barra se citar .env). Só opções e um `-` final; argumento de script ou -c/-m: não prova.
    if name in INTERP and all(a in INTERP_STDIN_OK for a in args[1:]):
        return 'interp'
    return None

def _dests(seg, name, toks_before):
    """os destinos de um consumidor que grava (o que segue `>`/`>>` e os argumentos do tee), com `$VAR` resolvido
    pela última atribuição LITERAL do mesmo comando; destino que não se resolve devolve None (não prova)."""
    out = []
    for i, t in enumerate(seg):
        if t in REDIRS and i + 1 < len(seg):
            out.append(seg[i + 1])
    if name == 'tee':
        k = seg.index('<<') if '<<' in seg else len(seg)
        out += [t for t in seg[1:k] if not t.startswith('-') and t not in REDIRS and t not in out]
    res = []
    for d in out:
        m = re.match(r'^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?$', d)
        if m:
            vals = [t.split('=', 1)[1] for t in toks_before if t.startswith(m.group(1) + '=')]
            if not vals:
                return None
            d = vals[-1]
        res.append(d)
    return res

def split_heredocs(cmd):
    """Devolve (comando sem o corpo PROVADO como dado, [(entre aspas?, gravado em arquivo?, corpo, tipo, dado?)])."""
    lines = cmd.split('\n')
    idx = next((i for i, l in enumerate(lines) if HEREDOC_ANY.search(l)), None)
    if idx is None:
        return cmd, []
    prefix = '\n'.join(lines[:idx + 1])
    line = lines[idx]
    # SUBSTITUIÇÃO no prefixo (U4): antes, qualquer `$(` ou crase recusava a separação, e o resíduo de revisão
    # (`SHA=$(git diff … | sha256sum) && cat > r.md <<'EOF'`) tinha cada linha de markdown julgada como comando.
    # Agora vale se toda substituição FECHA antes do operador e depois dele na mesma linha: medido em bash 5,
    # `$(cat <<'E')` com o corpo nas linhas seguintes EXECUTA o corpo — o `<<` dentro de uma substituição,
    # mesmo fechada na linha, é recusado (o texto antes do operador não fecha). `<(`/`>(` seguem recusados.
    _op = HEREDOC_ANY.search(line)
    if (re.search(r'\\$', '\n'.join(lines[:idx]), re.M) or line.rstrip().endswith('\\')
            or len(HEREDOC_ANY.findall(prefix)) != 1
            or not substitutions_closed('\n'.join(lines[:idx] + [line[:_op.start()]]))
            or not substitutions_closed(line[_op.end():])):
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
        # a quebra de linha SEPARA comandos (U4): sem isso, `mkdir x` numa linha e `cat >> f <<'E'` na seguinte
        # viravam um consumidor só, `mkdir`, fora da lista — e o corpo era julgado como comando
        lex = LinearShlex(quote_escaped_punct(strip_comments(prefix)), posix=True, punctuation_chars=';&|()<>\n')
        lex.whitespace = ' \t\r'
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
    # o consumidor dentro de um SUBSHELL aberto (`( cat <<E … ) | sh`): o que vem depois do corpo decide para onde
    # ele vai, e o prefixo não prova. (`{ cat <<E` já cai: o consumidor seria `{`, fora da lista.) Isto também
    # recusa `$(cat <<'E')` por um segundo caminho, além da checagem de substituição antes do operador.
    _sp = ''.join(t for t in toks[:k] if _is_sep(t))
    if _sp.count('(') != _sp.count(')'):
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
    # DADO (U4): gravado só em arquivo(s) de dados com destino resolvido, sem descritor >= 3
    dests = _dests(seg, name, toks[:k]) if written and name in ('cat', 'tee') else None
    data = bool(dests) and all(is_data_file(d) for d in dests) and not re.search(r'>&\s*[3-9]', _around)
    # as REFERÊNCIAS ao arquivo de dados (nome, caminho, e a variável do destino), para saber se a linha o reusa
    if data:
        _raw = [seg[i + 1] for i, t in enumerate(seg) if t in REDIRS and i + 1 < len(seg)]
        data = sorted({os.path.basename(d) for d in dests} | {'$' + re.sub(r'^\$\{?|\}$', '', r) for r in _raw if r.startswith('$')})
    rest_cmd, rest_docs = split_heredocs('\n'.join(lines[j + 1:]))
    return ('\n'.join(lines[:idx + 1] + ([rest_cmd] if j + 1 < len(lines) else [])),
            [(quoted, written, body, ('interp-env' if any(cites_env(t) or is_env_token(t.split('=', 1)[-1]) for t in seg[:seg.index('<<')]
                                      if re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', t)) else 'interp') if name == 'interp' else 'text', data)]
            + rest_docs)

def judge_heredocs(docs, depth):
    for quoted, written, body, kind, data in docs:
        if kind.startswith('interp'):
            if cites_env(body) or kind == 'interp-env':
                return 'interpretador que recebe por heredoc um código citando um arquivo .env (no corpo ou numa variável do prefixo)'
            continue
        if written and not data and cites_env(body):
            return 'heredoc que grava em ARQUIVO um texto citando um arquivo .env (pode virar script) — escreva com a ferramenta Write'
        if not quoted and re.search(r'\$\(|`', body) and cites_env(body):
            return 'heredoc sem aspas com substituição de comando que cita um arquivo .env'
    return None

# o heredoc de DADOS citando .env só vale se a MESMA linha não o usar como CÓDIGO: medido na passada do U4,
# `bash -c "$(cat x.md)"`, `eval "$(cat x.md)"`, `cat x.md | bash` e `mv x.md run.sh; bash run.sh` liam o .env.
# Barra quando o arquivo (nome, caminho ou a variável do destino) chega a um shell/interpretador/eval como
# programa, a um pipe para shell, à entrada de um shell, ou é renomeado/copiado/tornado executável. Ler o arquivo
# como DADO (`bash kg-radar.sh x.yaml`, `gh pr create --body-file x.md`, `git add`) segue passando. Por chamadas
# separadas o vetor já existia: a ferramenta Write grava qualquer script — é a fronteira declarada no topo.
RENAMERS = {'mv', 'cp', 'ln', 'install', 'rename', 'chmod'}
CODE_RUNNERS = SHELLS | INTERP | {'eval', 'source', '.', 'exec'}

def _mentions(text, ref):
    if ref.startswith('$'):
        return bool(re.search(r'\$\{?' + re.escape(ref[1:]) + r'(?![A-Za-z0-9_])', text))
    return ref in text

def data_used_as_code(cmd, refs):
    if not refs:
        return False
    for ref in refs:
        _r = re.escape(ref[1:]) if ref.startswith('$') else re.escape(ref)
        if re.search(_r + r'[^|;&\n]*\|\s*(?:sudo\s+(?:-\S+\s+)*)?(?:' + '|'.join(sorted(SHELLS | INTERP)) + r')\b', cmd):
            return True
    try:
        segs = _segments_plain(_tokens(cmd))
    except ValueError:
        return True
    for seg in segs:
        args = [t for t in seg if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', t)]
        while args and (args[0] in KEYWORDS or args[0] in WRAPPERS):
            args = args[1:]
        if not args:
            continue
        name = os.path.basename(args[0])
        hit = lambda t: any(_mentions(t, r) for r in refs)
        if name in RENAMERS and any(hit(a) for a in args[1:]):
            return True
        if name in CODE_RUNNERS:
            if name == 'eval' and any(hit(a) for a in args[1:]):
                return True
            rest = [a for a in args[1:] if not a.startswith('-')]
            if rest and hit(rest[0]):
                return True
            if '-c' in args and any(hit(a) for a in args[args.index('-c') + 1:args.index('-c') + 2]):
                return True
            if any(seg[i] == '<' and i + 1 < len(seg) and hit(seg[i + 1]) for i in range(len(seg))):
                return True
    for sub in substitutions(cmd):
        if any(_mentions(sub, r) for r in refs) and re.search(r'(?:^|[;&|\s])(?:eval|bash|sh|zsh|dash|source)\s', cmd):
            return True
    return False

def judge(cmd, depth=0):
    """None = passa; str = motivo do veto."""
    if depth > 4:
        return 'aninhamento de shell profundo demais para provar'
    cmd, docs = split_heredocs(cmd)
    r = judge_heredocs(docs, depth)
    if r:
        return r
    if any(d[4] and cites_env(d[2]) and data_used_as_code(cmd, d[4]) for d in docs):
        return 'heredoc grava em arquivo de dados um texto citando um arquivo .env, e a mesma linha o usa como código — escreva com a ferramenta Write e rode à parte'
    # toda substituição, inclusive entre aspas duplas (`echo "$(cat .env)"` passava: o shlex a entrega inteira)
    for sub in substitutions(cmd):
        r = judge(sub, depth + 1)
        if r:
            return r
    try:
        segs = segments(cmd)
    except ValueError:
        return 'comando inanalisável que cita um arquivo .env' if cites_env(cmd) else None
    sourced = False
    # VAR=literal do mesmo comando (U4): `bash $H` com H=…/env-check.sh é o helper, e `grep x $D/*` com D=pasta
    # literal se confere no disco como `grep x pasta/*`. Segmento SÓ de atribuições não lê nada (`E=/etc/x.env`).
    assigned = CTX.setdefault('assigned', {})
    for seg in segs:
        if all(re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', t) for t in seg):
            for t in seg:
                _k, _v = t.split('=', 1)
                if re.search(r'[$`]', _v):
                    assigned.pop(_k, None)
                else:
                    assigned[_k] = _v
            continue
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
        while args and args[0] in KEYWORDS:
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
        # `dd if=.env` (passada adversarial, 2026-10-15; falha ANTERIOR a este diff): `if=…` tem forma de atribuição
        # VAR=valor e saía da linha junto com as atribuições — o dd lia o .env para o stdout sem veto. Lê-se do `seg`.
        if name == 'dd' and any(is_env_token(t[3:]) for t in seg if t.startswith('if=')):
            return "'dd' lendo um arquivo .env (if=)"
        if name in GREPS and not any(re.match(r'^GREP_[A-Z_]*=', t) for t in seg):
            _pi = grep_pattern_index(args)
            if _pi is not None:
                files = [a for a in files if a is not args[_pi]]
        envs = [a for a in files if is_env_token(a)] + [g for g in inc if is_env_token(g)]
        if name in SHELLS and len(args) > 1:
            if args[1] == '-c' and len(args) > 2:
                r = judge(args[2], depth + 1)
                if r:
                    return r
                continue
            _a1 = args[1]
            _m1 = re.match(r'^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?$', _a1)
            if _m1 and _m1.group(1) in assigned:
                _a1 = assigned[_m1.group(1)]
            if os.path.basename(_a1) == HELPER:
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
        # ESCAPE ANTERIOR (passada do U4): `find . -name .env | xargs cat` passava — o find só lista, e o xargs não
        # citava o .env. Numa linha que cita um .env, o xargs só passa se o comando dele for de METADADO.
        if name == 'xargs' and CTX['strict']:
            _xa, _i = args[1:], 0
            while _i < len(_xa) and _xa[_i].startswith('-'):
                _i += 2 if _xa[_i] in ('-I', '-n', '-P', '-d', '-s', '-L', '-E', '-a') else 1
            _xc = os.path.basename(_xa[_i]) if _i < len(_xa) else 'echo'
            if _xc not in METADATA or _xc in ('source', '.'):
                return "xargs '%s' numa linha que cita um arquivo .env (o nome chega pela entrada)" % _xc
        # o outro lado do heredoc de DADOS (U4): executar com um shell um arquivo de dados (.md, .txt…) é barrado
        if name in SHELLS | {'source', '.'}:
            _sc = next((a for a in args[1:] if not a.startswith('-')), '')
            if _sc and is_data_file(_sc):
                return "'%s' executando um arquivo de dados (%s) como script" % (name, _sc)
        if name in ('source', '.') and envs:
            sourced = True
            continue
        if sourced and (name in DUMPERS or (name in ('export', 'declare', 'typeset') and '-p' in args)
                        or (name == 'set' and len(args) == 1)):
            return "carregar o .env e despejar o ambiente ('%s') no mesmo comando" % name
        if not envs:
            continue
        if name in GREPS and grep_names_only(args, seg):
            continue                                 # grep -o com padrão que só casa NOME de chave (U4)
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
        return "'%s' lendo %s" % (name, envs[0]) + (" (arquivo de trabalho no scratchpad? o veto não isenta *.env nem ali: grave-o com outra extensão, .vars ou .txt)" if scratch_hint(envs[0]) else "")
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
        reason = 'Read de um arquivo .env' + (" (arquivo de trabalho no scratchpad? o veto não isenta *.env nem ali: grave-o com outra extensão, .vars ou .txt)" if scratch_hint(str(ti.get('file_path') or '')) else "")
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
echo "GUARDA-PRETOOLUSE (.env): ${out} — o conteúdo do .env (os segredos) entraria no contexto e no transcript. Use: 'bash .claude/utils/task-manager/env-check.sh --provider|--check|--get <CHAVE-NÃO-SECRETA>', ou carregue no ambiente com 'set -a; source .env; set +a'. Se precisar ver o arquivo, o maestro o abre fora da sessão." >&2
exit 2
