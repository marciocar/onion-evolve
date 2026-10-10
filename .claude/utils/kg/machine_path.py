"""machine_path.py — a CLASSE "caminho de máquina" num lugar só (SAC-103, 2026-10-10).

Por que existe. Nas ondas O4 a O7 da migração de provenance (SAC-73, 2026-10-09/10) o corpus de `.kg.yaml`
perdeu centenas de caminhos desta máquina em `provenance`, `verified_against`, `trace`, `label` e
`narrative`: caminho de máquina não é reverificável por terceiros e vaza na publicação das portas. A régua
das ondas era uma LISTA de diretórios no `kg-migrate-v3.py`, e a lista errou pelo vocabulário, medido:
  · falsos negativos: `/outro/repo` (O5, omissão do juiz), `/tmp` e `/proc` sem barra, `/boot` e `/opt`
    fora do brief, a barra dupla `//home/…` da sintaxe de permissão do Claude Code (J-O7-1) e `~<conta>/`;
  · falsos positivos: `/lib/` dentro de caminho relativo, comandos `/meta:*`, endpoints, URLs e globs.
O selo P3 do maestro manda acusar pela CLASSE. Este módulo é a classe, e é importado pelo migrador e pela
guarda (kg-machine-path-check.sh, kg-contract-check.sh): uma regex, nunca duas cópias.

A CLASSE (o que acusa), sempre no INÍCIO DE TOKEN:
  fs     — absoluto cuja raiz é RAIZ DE SISTEMA DE ARQUIVOS (FHS 3.0 + as raízes de host que o FHS não lista:
           snap, nix, e as do macOS: Users, Volumes, private), com ou sem barra final (`/tmp`, `/proc`);
  shell  — absoluto de QUALQUER raiz (`/outro/repo`) quando é ARGUMENTO DE CAMINHO de shell: `cd`, `-C`,
           `ls`, `cat`, `source`… ou redirecionamento `>`;
  dbl    — a barra dupla seguida de caminho (`//home/…`), que não é URL (sem `:` antes, segmento sem ponto);
  file   — `file://` apontando para raiz de sistema;
  tilde  — `~/`;
  acct   — `~<conta>/` seguido de letra (o `~abril/2026` de data fica de fora);
  host   — o hostname da máquina (o do processo e os `host:` do members.yaml, quando há).

ISENÇÕES (seladas): comando `/x:y` (`/meta:*`), endpoints e caminhos de URL (`scheme://` ou rota que não é
raiz de sistema), `/dev/{null,stdin,stdout,stderr}` (selo A4), caminho RELATIVO do repo (selo A6: nunca é
início de token com `/`), e o nó marcado `x_path_is_content: "citação"|"vetor"|"receita"` (selo P4) — com a
condição: marcador que NÃO é `citação` não isenta HOME DE CONTA nem HOSTNAME (citação de terceiro aceita `~/`).

TETO declarado (o que a classe NÃO vê): absoluto de raiz que não é de sistema fora de argumento de shell
(`/workspace/x` em prosa) — é indistinguível de endpoint (`/admin/stats`, `/v1/messages`) e a guarda erra para
o lado de calar; `$HOME/x` (variável, não literal); caminho Windows (`C:\\`); `/run` NU (é também comando);
campos fora de nó (`meta`, arestas) e comentários YAML; hostname de OUTRA máquina que não esteja no
members.yaml.
"""
import os
import re
import socket

# ── raízes de sistema de arquivos ────────────────────────────────────────────────────────────────────────────
# FHS 3.0 (o padrão, não um palpite) + as raízes reais que ele não lista. `run` só COM barra: `/run` nu é comando.
FS_ROOTS = ("bin", "boot", "dev", "etc", "home", "lib", "lib32", "lib64", "libx32", "media", "mnt", "opt",
            "proc", "root", "run", "sbin", "srv", "sys", "tmp", "usr", "var", "snap", "nix",
            "Users", "Volumes", "private")
_BARE_OK = tuple(r for r in FS_ROOTS if r != "run")
HOME_ROOTS = ("home", "root", "Users")          # raiz que é HOME DE CONTA (P4: só citação a isenta)
P4_MARKS = ("citação", "vetor", "receita")

# selo A4: os quatro fluxos padrão são parte do comando, iguais em qualquer Linux
_DEV_STD = r'(?!dev/(?:null|stdin|stdout|stderr)(?![\w/.-]))'
# início de token: começo, espaço, aspas, abre-parêntese/colchete/chave, atribuição, separadores, crase,
# dois-pontos (PATH=/usr/bin:/bin), redirecionamento e os abre-aspas tipográficos da narrative
# a crase só abre token quando ELA abre (depois de início, espaço ou delimitador): a que FECHA, seguida de
# `/raiz` no sentido de "ou" (`plane:`/`status:`/etc.), não é caminho (achado F1 do Elenxo, 2 casos na prosa).
# `<` fica de fora: `</var>` é tag de fechamento (F3); `< /etc/x` com espaço segue acusado.
_TS = r'(?:^|(?<=[\s"\'(=,;\[:>|{⟨«“‘→])|(?<=^`)|(?<=[\s(\[{"\'>*_]`))'
_SEG = r'[A-Za-z0-9._@+-]+'
# fim de raiz nua: não segue letra/dígito/_/-, e ponto só se for fim de frase (não `/tmp.x`)
_END = r'(?![A-Za-z0-9_-]|\.[A-Za-z0-9])'

_ROOTS_SLASH = "|".join(FS_ROOTS)
_ROOTS_BARE = "|".join(_BARE_OK)
_FS = r'/' + _DEV_STD + r'(?:(?:' + _ROOTS_SLASH + r')/|(?:' + _ROOTS_BARE + r')' + _END + r')'

CLASS_RE = re.compile(
    _TS + r'(?P<fs>' + _FS + r')'
    + r'|(?:^|(?<=[\s"\'(=,;\[>|{⟨«“‘→])|(?<=^`)|(?<=[\s(\[{"\'>*_]`))(?P<dbl>//(?=[A-Za-z0-9_+-])' + r'[A-Za-z0-9_+@-]+/)'   # sem `:` antes, sem ponto
    + r'|(?P<file>file://(?:localhost)?' + _FS + r')'
    + r'|' + _TS + r'(?P<tilde>~/)'
    + r'|' + _TS + r'(?P<acct>~[a-z_][a-z0-9_-]*/(?=[A-Za-z._]))'
)
# argumento de caminho de shell: o verbo (ou a flag -C, ou o redirecionamento) e um absoluto de QUALQUER raiz
SHELL_ARG_RE = re.compile(
    r'(?:(?:^|(?<=[\s;&|(`"\'$⟨]))(?:cd|pushd|ls|cat|source|rm|cp|mv|mkdir|touch|stat|tee|du|find|chmod|chown|-C)'
    # redirecionamento: `>` depois de espaço, ou `N>`/`&>` cujo dígito/e-comercial ABRE o token. O `>` que
    # fecha um placeholder (`docs/<dominio-t2>/graph/…`) não é redirecionamento — medido no corpus quando o
    # argumento de shell passou a aceitar um segmento só (colaboracao-onion-2026-07, 2026-10-10).
    r'(?:\s+-[A-Za-z]+)*\s+|(?:^|(?<=\s)|(?<=^[\d&])|(?<=\s[\d&]))>>?\s*)'
    r'(?P<shell>/' + _DEV_STD + _SEG + r'(?:/' + _SEG + r')*/?)'   # `cd /workspace` (1 segmento) também: F7
)


def known_hosts(root=None, extra=None):
    """Os hostnames de máquina: o do processo, os `host:` do members.yaml (se `root` o tiver) e os de
    KG_MACHINE_PATH_HOSTS (espaço ou vírgula; é como a bancada injeta um). Só nomes de 6+ caracteres: nome
    curto casaria palavra comum."""
    hosts = set()
    h = (socket.gethostname() or "").split(".")[0]
    if h:
        hosts.add(h)
    for x in re.split(r'[\s,]+', os.environ.get("KG_MACHINE_PATH_HOSTS", "")):
        if x:
            hosts.add(x)
    for x in (extra or ()):
        hosts.add(x)
    if root:
        hosts.update(_member_hosts(os.path.join(root, "docs", "evolution", "federation", "members.yaml")))
    return sorted(x for x in hosts if len(x) >= 6)


def _member_hosts(path):
    """Os `host:` das LINHAGENS do members.yaml (`<membro>.lineages.<nome>.host`) — a máquina onde a linhagem
    roda. Só ali: o `host:` de um bloco de deploy nomeia o SERVIÇO (medido em 2026-10-10: `host: onion-bridge`,
    nome de repo, acusaria 218 citações legítimas do produto se fosse lido como máquina)."""
    try:
        import yaml
        data = yaml.safe_load(open(path, encoding="utf-8"))
    except Exception:
        return set()
    out = set()

    def walk(v):
        if isinstance(v, dict):
            for k, x in v.items():
                if k == "lineages" and isinstance(x, dict):
                    for lin in x.values():
                        if isinstance(lin, dict) and isinstance(lin.get("host"), str):
                            out.add(lin["host"].split(".")[0])
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
    walk(data)
    return out


def host_re(hosts):
    hosts = [h for h in hosts if h]
    if not hosts:
        return None
    return re.compile(r'(?<![A-Za-z0-9_.-])(?:' + "|".join(re.escape(h) for h in hosts) + r')(?![A-Za-z0-9_-])', re.I)   # hostname não diferencia caixa (F9)


def _root_of(token):
    m = re.match(r'^(?:file://(?:localhost)?)?/+([^/\s]+)', token)
    return m.group(1) if m else ""


def is_home(kind, token):
    """Home de conta ou hostname: o que só `citação` isenta (selo P4)."""
    if kind in ("tilde", "acct", "host"):
        return True
    return _root_of(token) in HOME_ROOTS


def find(text, hrx=None):
    """[(kind, token, start)] de cada caminho de máquina em `text`, sem sobreposição."""
    if not isinstance(text, str) or not text:
        return []
    out, spans = [], []
    for m in CLASS_RE.finditer(text):
        kind = m.lastgroup
        out.append((kind, m.group(kind), m.start(kind)))
        spans.append((m.start(kind), m.end(kind)))
    for m in SHELL_ARG_RE.finditer(text):
        s = m.start("shell")
        if not any(a <= s < b for a, b in spans):
            out.append(("shell", m.group("shell"), s))
    if hrx is not None:
        for m in hrx.finditer(text):
            out.append(("host", m.group(0), m.start()))
    return sorted(out, key=lambda x: x[2])


class _ClassMatcher:
    """Compatível com o uso `ABS_FS_RE.search(v)` do migrador: verdadeiro se há caminho de máquina (sem
    hostname, que o migrador julga à parte)."""

    def search(self, text):
        r = find(text)
        return r[0] if r else None


ABS_FS_RE = _ClassMatcher()


def _walk(v, path=""):
    if isinstance(v, str):
        yield path, v
    elif isinstance(v, dict):
        for k, x in v.items():
            yield from _walk(x, f"{path}.{k}" if path else str(k))
    elif isinstance(v, list):
        for x in v:
            yield from _walk(x, path)


def scan_node(node, hrx=None):
    """(acusações, isenções) de UM nó. Cada item: (campo, kind, token). A isenção diz o motivo."""
    acc, exempt = [], []
    mark = node.get("x_path_is_content")
    valid = isinstance(mark, str) and mark in P4_MARKS
    for field, val in _walk(node):
        if field == "x_path_is_content":
            continue
        for kind, tok, _ in find(val, hrx):
            if valid and (mark == "citação" or not is_home(kind, tok)):
                exempt.append((field, kind, tok, mark))
            else:
                acc.append((field, kind, tok))
    return acc, exempt


def scan_text(text, hrx=None):
    """Varre um `.kg.yaml` inteiro. Devolve (acusações, isenções, erro): acusação = (nó, campo, kind, token);
    isenção = (nó, campo, kind, token, marcador); erro = texto se o YAML não parseia (nada julgado)."""
    import yaml
    try:
        docs = list(yaml.safe_load_all(text))
    except Exception as e:  # o YAML inválido é da REGRA 78; aqui só se declara que não se julgou
        return [], [], str(e).replace("\n", " ")[:140]
    acc, exempt = [], []
    for d in docs:
        if not isinstance(d, dict):
            continue
        nodes = d.get("nodes")
        for n in (nodes if isinstance(nodes, list) else []):
            if not isinstance(n, dict):
                continue
            nid = str(n.get("id", "?"))
            a, e = scan_node(n, hrx)
            acc += [(nid,) + x for x in a]
            exempt += [(nid,) + x for x in e]
    return acc, exempt, None
