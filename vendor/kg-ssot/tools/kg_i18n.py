#!/usr/bin/env python3
"""A língua da saída humana das ferramentas do KG-SSOT (release 4.18.0), no padrão do gettext.

O texto em inglês é a fonte e a própria chave (msgid); a tradução vive num catálogo .po por língua
(locale/<lingua>/LC_MESSAGES/kg-ssot.po), o formato que as plataformas de tradução leem. A língua sai do ambiente na
ordem do gettext: KG_SSOT_LANG (a forçada pelo usuário), LANGUAGE (lista separada por dois-pontos), LC_ALL,
LC_MESSAGES e LANG. "C", "POSIX" e vazio são o inglês. Uma língua sem catálogo, ou uma frase sem tradução, sai em
inglês. A saída em JSON e os códigos (form.required.node.label) não passam por aqui: são o vocabulário estável.

Como no gettext, LANGUAGE só vale quando o locale efetivo (LC_ALL, LC_MESSAGES, LANG) não é o C: LC_ALL=C força o
inglês mesmo num desktop com LANGUAGE=pt_BR:en. A KG_SSOT_LANG vem antes de tudo.

Texto de máquina (o protocolo MCP, que vira prompt de modelo) não muda com o locale: protocol() marca a frase, que
fica em inglês, e machine() faz o _() devolver a fonte dentro do bloco (o que o MCP chama de kg_validate e kg_store).

Uso nas ferramentas:  from kg_i18n import _   ·   print(_("{n} graph(s) read").format(n=3))
Uso no shell:         KG_SSOT_LANG=pt-BR kg-validate grafo.kg.yaml   ·   KG_SSOT_LANG=en ...
"""
import ast
import contextlib
import contextvars
import os
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
# no repo e no vendor, o catálogo fica em locale/ ao lado de tools/; no pacote kg_ssot, ao lado do módulo
_ROOTS = (HERE.parent / "locale", HERE / "locale")
DOMAIN = "kg-ssot"
ENV_ORDER = ("KG_SSOT_LANG", "LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG")


def normalize(tag):
    """'pt_BR.UTF-8', 'pt-BR', 'pt-br' → 'pt_BR'; 'pt' → 'pt'; 'C', 'POSIX' e vazio → None (o inglês)."""
    tag = (tag or "").strip().split(".")[0].split("@")[0].replace("-", "_")
    if not tag or tag.upper() in ("C", "POSIX"):
        return None
    lang, _sep, region = tag.partition("_")
    return f"{lang.lower()}_{region.upper()}" if region else lang.lower()


_AVAILABLE = None


def available():
    """As línguas com catálogo, além do inglês (lido uma vez por processo)."""
    global _AVAILABLE
    if _AVAILABLE is not None:
        return _AVAILABLE
    out = set()
    for root in _ROOTS:
        if root.is_dir():
            out |= {p.parent.parent.name for p in root.glob(f"*/LC_MESSAGES/{DOMAIN}.po")}
    _AVAILABLE = frozenset(out)
    return _AVAILABLE


def negotiate(env=None):
    """A língua escolhida, ou None para o inglês. Para na primeira variável definida, como o gettext; dentro dela,
    a primeira língua com catálogo, aceitando a língua sem região (pt casa pt_BR, e pt_BR casa pt)."""
    env = os.environ if env is None else env
    have = available()
    # o locale efetivo das mensagens; se for o C (ou POSIX), o LANGUAGE não vale, como no gettext
    effective = next((env.get(n) for n in ("LC_ALL", "LC_MESSAGES", "LANG") if env.get(n)), None)
    locale_is_c = effective is None or normalize(effective) is None
    for name in ENV_ORDER:
        value = env.get(name)
        if not value or (name == "LANGUAGE" and locale_is_c):
            continue
        for tag in value.split(":") if name == "LANGUAGE" else (value,):
            lang = normalize(tag)
            if lang is None or lang == "en" or lang.startswith("en_"):
                return None
            if lang in have:
                return lang
            base = lang.split("_")[0]
            match = sorted(h for h in have if h.split("_")[0] == base)
            if match:
                return match[0]
        return None  # a variável definida decide, mesmo sem catálogo: o inglês
    return None


def _unquote(s):
    """O conteúdo de uma string do .po (entre aspas, com os escapes do C)."""
    return ast.literal_eval(s) if s.startswith('"') and s.endswith('"') else ""


def parse_po(text):
    """{msgid: msgstr} de um .po: entradas de msgid e msgstr com continuação de linha; a fuzzy, a vazia e o cabeçalho
    (msgid vazio) ficam de fora. Sem plural: a saída das ferramentas não usa."""
    catalog, msgid, msgstr, field, fuzzy = {}, None, None, None, False

    def flush():
        if msgid and msgstr and not fuzzy:
            catalog[msgid] = msgstr

    for raw in text.splitlines() + [""]:
        line = raw.strip()
        if not line:
            flush()
            msgid = msgstr = field = None
            fuzzy = False
        elif line.startswith("#,") and "fuzzy" in line:
            fuzzy = True
        elif line.startswith("#"):
            continue
        elif line.startswith("msgid "):
            flush()
            msgid, msgstr, field = _unquote(line[6:]), None, "id"
        elif line.startswith("msgstr "):
            msgstr, field = _unquote(line[7:]), "str"
        elif line.startswith('"'):
            if field == "id":
                msgid += _unquote(line)
            elif field == "str":
                msgstr += _unquote(line)
    return catalog


_CACHE = {}


def catalog(lang):
    if lang is None:
        return {}
    if lang not in _CACHE:
        _CACHE[lang] = {}
        for root in _ROOTS:
            path = root / lang / "LC_MESSAGES" / f"{DOMAIN}.po"
            if path.is_file():
                _CACHE[lang] = parse_po(path.read_text(encoding="utf-8"))
                break
    return _CACHE[lang]


_CHOSEN = {}


def _lang_now():
    """A língua para o ambiente atual, guardada pelos valores das variáveis (um teste pode trocar o ambiente)."""
    key = tuple(os.environ.get(n) for n in ENV_ORDER)
    if key not in _CHOSEN:
        _CHOSEN[key] = negotiate()
    return _CHOSEN[key]


_MACHINE = contextvars.ContextVar("kg_ssot_machine_text", default=False)


@contextlib.contextmanager
def machine():
    """Dentro do bloco, o _() devolve a fonte (o inglês): para o texto que vai a uma máquina, e não a uma pessoa."""
    token = _MACHINE.set(True)
    try:
        yield
    finally:
        _MACHINE.reset(token)


def machine_active():
    """Se o _() está devolvendo a fonte (dentro de machine()): quem chama um subprocesso nosso passa a língua adiante."""
    return _MACHINE.get()


def N_(msgid):
    """Como no gettext: marca a frase para o catálogo sem traduzi-la agora (o _(msgid) traduz depois)."""
    return msgid


def protocol(msgid):
    """Texto de protocolo (o MCP): fica em inglês em qualquer locale e não entra no catálogo."""
    return msgid


def _(msgid):
    """A tradução de msgid na língua do ambiente, ou o próprio msgid (o inglês)."""
    if _MACHINE.get():
        return msgid
    return catalog(_lang_now()).get(msgid, msgid)


def language():
    """O código da língua em uso: 'en' ou o do catálogo (pt_BR)."""
    return _lang_now() or "en"
