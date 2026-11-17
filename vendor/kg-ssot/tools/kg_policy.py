#!/usr/bin/env python3
"""O leitor da política de áreas do kg-mcp (--area-policy), puro e só de leitura: o kg_mcp.py o usa para servir, e o
kg_gate.py --classification-floor (contrato v4.23) para ler a ordem dos níveis do mesmo arquivo, pelo mesmo leitor
estrito, sem trazer o servidor.

{"schema_version": 1, "canonical": "c-empresa", "groups": {"g-financeiro": ["ana@x.org"]},
 "levels": ["public", "internal", "confidential"], "ceilings": {"c-empresa": "internal",
 "g-financeiro": "confidential"}, "default_level": "internal"}

parse(texto) devolve a política (PolicyDoc) ou levanta ValueError com o que está errado: a chave repetida em qualquer
nível, a chave fora da lista, levels, ceilings e default_level que não vêm juntos, o nível que não é slug ou que se
repete, a área compartilhada (a canônica ou um grupo) sem teto numa política com levels (negar por padrão), e os papéis
e membros fora da forma. Ceiling(levels, teto, default) é o teto de uma área: level_of(nome, texto)
dá o nível declarado do grafo, o default_level quando o meta não declara, ou None quando não se sabe (a falha fecha).
As mensagens são de protocolo: ficam em inglês em qualquer locale (kg_i18n.protocol).

digest(política) é a impressão digital da política lida, "sha256:<hex>": o SHA-256 do JSON canônico da forma
normalizada (normalized), a que o gate e o kg-mcp de fato usam. O gate (--area-policy-digest) e o kg-mcp (idem)
conferem o arquivo que leem contra o mesmo valor fixado e commitado, como um lockfile: a política que diverge não passa
em nenhuma das pontas. Na linha de comando, `python3 -I tools/kg_policy.py digest ARQ` imprime o digest (rc 0) ou diz
por que a política é inválida (rc 2).
"""
import argparse
import hashlib
import json
import re
import pathlib
import sys

sys.dont_write_bytecode = True  # num vendor, ler a política não pode sujar o diretório carimbado
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_validate  # noqa: E402

P_ = kg_i18n.protocol
_ = kg_i18n._


# um e-mail em ASCII imprimível, sem espaço nem controle: o header chega decodificado em latin-1, e um byte acima de
# 0x7e (um U+200B em UTF-8, um controle C1) faria outra identidade com cara da mesma
IDENTITY = re.compile(r"(?:(?![<>@])[!-~])+@(?:(?![<>@])[!-~])+")
IDENTITY_MAX = 254
GROUP_AREA = re.compile(r"g-[a-z0-9][a-z0-9._-]{0,62}")
CANONICAL_AREA = re.compile(r"c-[a-z0-9][a-z0-9._-]{0,62}")


def check_identity(value):
    """A identidade do header, normalizada (minúsculas), ou None quando falta, vem vazia (o placeholder que o
    LibreChat troca por texto vazio), tem espaço ou controle, passa do tamanho ou não é um e-mail."""
    if not isinstance(value, str) or not value or len(value) > IDENTITY_MAX or not IDENTITY.fullmatch(value):
        return None
    return value.lower()


ROLE_NAME = re.compile(r"[a-z0-9][a-z0-9._-]{0,62}")
POLICY_MAX_BYTES = 1 << 20  # 1 MiB: a política é escrita à mão pelo operador, e é relida a cada mudança


def _unique_keys(pairs):
    """O object_pairs_hook da política: a chave repetida, em qualquer nível, invalida o arquivo (o json do Python
    ficaria com a última em silêncio, e outro leitor poderia ficar com a primeira)."""
    out = {}
    for key, value in pairs:
        if key in out:
            raise ValueError(P_("the policy repeats the key {key} in the same object").format(key=json.dumps(key)))
        out[key] = value
    return out


OWN = "own"  # o único valor de write: a própria área, a única em que o kg-mcp grava


class PolicyDoc:
    """A política lida e conferida: a canônica, os grupos, os tetos das áreas, os níveis e os papéis com seus membros."""
    __slots__ = ("canonical", "groups", "ceilings", "levels", "default", "roles", "members", "member_of")

    def __init__(self, canonical=None, groups=None, ceilings=None, levels=None, default=None, roles=None, members=None):
        self.canonical, self.groups, self.ceilings = canonical, groups or {}, ceilings or {}
        self.levels, self.default, self.roles, self.members = levels, default, roles or {}, members or {}
        # o índice pessoa -> grupos, em ordem, feito uma vez por carga: grant() e overridden() não varrem os grupos
        member_of = {}
        for area in sorted(self.groups):
            for who in self.groups[area]:
                member_of.setdefault(who, []).append(area)
        self.member_of = member_of


class Role:
    """Um papel: as áreas que lê, se grava na própria área e o teto que dá a cada área que lê ({área: nível}; a área
    que falta no mapa fica com o teto dela)."""
    __slots__ = ("read", "writes", "ceilings")

    def __init__(self, read, writes, ceilings):
        self.read, self.writes, self.ceilings = read, writes, ceilings


KEYS = {"schema_version", "canonical", "groups", "levels", "ceilings", "default_level", "roles", "members"}
ROLE_KEYS = {"read", "write", "ceilings"}


def parse(text):
    """A política (PolicyDoc) de um texto, ou ValueError com o que está errado."""
    if len(text.encode("utf-8")) > POLICY_MAX_BYTES:
        raise ValueError(P_("the policy is larger than {limit} bytes").format(limit=POLICY_MAX_BYTES))
    doc = json.loads(text, object_pairs_hook=_unique_keys)
    if not isinstance(doc, dict) or doc.get("schema_version") != 1 or set(doc) - KEYS:
        raise ValueError(P_("the policy is an object with schema_version 1, canonical, groups, roles, members and, "
                            "together, levels, ceilings and default_level, nothing else"))
    canonical, groups = doc.get("canonical"), doc.get("groups", {})
    if canonical is not None and not (isinstance(canonical, str) and CANONICAL_AREA.fullmatch(canonical)):
        raise ValueError(P_("canonical: the area name is c-<letters, digits, dot, dash or underscore>"))
    if not isinstance(groups, dict):
        raise ValueError(P_("groups maps each g-<name> area to the list of its identities"))
    out = {}
    for area, members in groups.items():
        if not GROUP_AREA.fullmatch(area) or not isinstance(members, list):
            raise ValueError(P_("groups maps each g-<name> area to the list of its identities"))
        ids = [check_identity(m) for m in members]
        if None in ids:
            raise ValueError(P_("group {area}: every member is an e-mail identity").format(area=area))
        out[area] = frozenset(ids)
    policy = PolicyDoc(canonical, out, _parse_ceilings(doc, canonical, out))  # o índice sai daqui
    if "levels" in doc:
        policy.levels, policy.default = list(doc["levels"]), doc["default_level"]
    policy.roles = _parse_roles(doc, policy)
    policy.members = _parse_members(doc, policy)
    return policy

def _parse_ceilings(doc, canonical, groups):
    """{área: Ceiling} de levels, ceilings e default_level, que vêm juntos; {} quando a política não tem teto."""
    present = [k for k in ("levels", "ceilings", "default_level") if k in doc]
    if not present:
        return {}
    if len(present) != 3:
        raise ValueError(P_("levels, ceilings and default_level come together"))
    levels, ceilings, default = doc["levels"], doc["ceilings"], doc["default_level"]
    if (not isinstance(levels, list) or not levels
            or not all(isinstance(v, str) and LEVEL.fullmatch(v) for v in levels)):
        raise ValueError(P_("levels is a list of level slugs (lowercase, digits, hyphen), from the least to the most "
                            "sensitive"))
    if len(set(levels)) != len(levels):
        raise ValueError(P_("levels: every level appears once"))
    if not isinstance(default, str) or default not in levels:
        raise ValueError(P_("default_level is one of levels: the level of a graph without x_classification"))
    if not isinstance(ceilings, dict):
        raise ValueError(P_("ceilings maps each shared area (c-<name> or g-<name>) to one of levels"))
    known = set(groups) | ({canonical} if canonical else set())
    out = {}
    for area, level in ceilings.items():
        if not (CANONICAL_AREA.fullmatch(area) or GROUP_AREA.fullmatch(area)):
            raise ValueError(P_("ceilings maps each shared area (c-<name> or g-<name>) to one of levels"))
        if area not in known:
            raise ValueError(P_("ceilings: {area} is neither the canonical area nor a group").format(area=area))
        if not isinstance(level, str) or level not in levels:
            raise ValueError(P_("ceilings: the ceiling of {area} is not one of levels").format(area=area))
        out[area] = Ceiling(levels, level, default)
    # negar por padrão: com levels, toda área compartilhada (a canônica e cada grupo; as de roles[*].read estão entre
    # elas) tem teto. A área fora de ceilings não seria julgada e serviria todo nível, o desconhecido também; a
    # política que a deixa de fora é inválida, e o kg-mcp e o gate a recusam (a falha fecha). A área própria da
    # identidade não é compartilhada e segue sem teto.
    missing = sorted(known - set(out))
    if missing:
        raise ValueError(P_("ceilings: with levels, every shared area has a ceiling; without one: {areas}").format(
            areas=", ".join(missing)))
    return out

def _parse_roles(doc, policy):
    """{papel: Role} de roles; {} sem a chave. Cada papel lê ao menos uma área conhecida (a canônica ou um grupo),
    write só aceita "own", e o teto do papel é um dos levels, numa área que ele lê, igual ou abaixo do teto dela."""
    if "roles" not in doc:
        return {}
    roles = doc["roles"]
    if not isinstance(roles, dict):
        raise ValueError(P_("roles maps each role name to its read, write and ceilings"))
    known = set(policy.groups) | ({policy.canonical} if policy.canonical else set())
    out = {}
    for name, role in roles.items():
        if not ROLE_NAME.fullmatch(name) or not isinstance(role, dict) or set(role) - ROLE_KEYS:
            raise ValueError(P_("roles maps each role name (lowercase, digits, dot, dash or underscore) to an object "
                                "with read and, optionally, write and ceilings"))
        read = role.get("read")
        if not isinstance(read, list) or not read or not all(isinstance(a, str) for a in read):
            raise ValueError(P_("role {role}: read lists at least one shared area").format(role=name))
        for area in read:
            if area not in known:
                raise ValueError(P_("role {role}: {area} is neither the canonical area nor a group").format(
                    role=name, area=area))
        write = role.get("write", [OWN])
        if not isinstance(write, list) or any(w != OWN for w in write):
            raise ValueError(P_('role {role}: write lists only "own", the area of the identity itself: the server '
                                'writes nowhere else').format(role=name))
        ceilings = role.get("ceilings", {})
        if not isinstance(ceilings, dict):
            raise ValueError(P_("role {role}: ceilings maps an area it reads to one of levels").format(role=name))
        if ceilings and policy.levels is None:
            raise ValueError(P_("role {role}: ceilings needs levels, ceilings and default_level in the policy").format(
                role=name))
        for area, level in ceilings.items():
            if area not in read:
                raise ValueError(P_("role {role}: the ceiling of {area} is for an area the role does not read").format(
                    role=name, area=area))
            if area == policy.canonical:
                raise ValueError(P_("role {role}: everyone reads the canonical area at its own ceiling, and a role "
                                    "cannot lower it").format(role=name))
            if not isinstance(level, str) or level not in policy.levels:
                raise ValueError(P_("role {role}: the ceiling of {area} is not one of levels").format(
                    role=name, area=area))
            top = policy.ceilings.get(area)
            if top is not None and policy.levels.index(level) > top.ceiling:
                raise ValueError(P_("role {role}: the ceiling of {area} is above the ceiling of the area").format(
                    role=name, area=area))
        out[name] = Role(frozenset(read), OWN in write, dict(ceilings))
    return out

def _parse_members(doc, policy):
    """{e-mail ou grupo: {papéis}} de members; {} sem a chave. Cada papel citado existe em roles."""
    if "members" not in doc:
        return {}
    members = doc["members"]
    if not isinstance(members, dict):
        raise ValueError(P_("members maps an e-mail or a group to the roles it holds"))
    out = {}
    for who, names in members.items():
        key = who if who in policy.groups else check_identity(who)
        if key is None:
            raise ValueError(P_("members: each key is an e-mail identity or a group of the policy"))
        if not isinstance(names, list) or not names or not all(isinstance(n, str) for n in names):
            raise ValueError(P_("members: each e-mail or group lists at least one role"))
        for n in names:
            if n not in policy.roles:
                raise ValueError(P_("members: the role {role} does not exist").format(role=n))
        out[key] = out.get(key, frozenset()) | frozenset(names)
    return out


LEVEL = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")  # o nível de x_classification: o slug do contrato v4.20


class Ceiling:
    """O teto de uma área: os níveis em ordem, o nível máximo entregue e o nível do grafo sem meta.x_classification."""

    def __init__(self, levels, ceiling, default):
        self.rank = {level: i for i, level in enumerate(levels)}
        self.ceiling, self.default = self.rank[ceiling], default

    def level_of(self, name, text):
        """O nível declarado do grafo, o default_level quando o meta não declara, ou None quando não se sabe: o grafo que
        não parseia, o meta que não é mapa e o x_classification que não é um nível da lista (a falha fecha)."""
        source = text if isinstance(text, kg_validate.JsonText) else kg_validate.as_source(name, text)
        _tree, doc, code = kg_validate.parse_v1(source)
        if code or not isinstance(doc, dict):
            return None
        if "meta" not in doc:
            return self.default
        meta = doc["meta"]
        # o meta que não é mapa simples (nulo, lista, texto, ou com a chave de mescla <<, que outro leitor resolveria
        # para um nível que este não vê) tem nível desconhecido
        if not isinstance(meta, dict) or "<<" in meta:
            return None
        if "x_classification" not in meta:
            return self.default
        level = meta["x_classification"]
        return level if isinstance(level, str) and level in self.rank else None

    def allows(self, name, text):
        level = self.level_of(name, text)
        return level is not None and self.rank[level] <= self.ceiling


# o digest da política (--area-policy-digest no gate e no kg-mcp): a forma normalizada, em JSON canônico
DIGEST = re.compile(r"sha256:[0-9a-f]{64}")
DIGEST_FILE_MAX = 1024  # o arquivo commitado do @ARQ guarda uma linha; mais que isso não é um digest


def normalized(policy):
    """A forma normalizada de uma política lida (PolicyDoc): o que o gate e o kg-mcp usam dela, e nada do jeito em que o
    arquivo foi escrito. Ela própria é uma política válida, que parse lê para o mesmo PolicyDoc. O digest dela muda
    sempre que o comportamento pode mudar, e às vezes também sem mudar: o teto de papel igual ao da área e o teto
    omitido dão o mesmo acesso e digests diferentes, como o papel que ninguém tem e a política sem ele. A diferença sem
    efeito falha fechada (o pin não bate e a política é recusada), nunca aberta.

    - todas as chaves presentes: canonical (null quando falta), groups, roles e members ({} quando faltam); levels,
      ceilings e default_level só quando a política tem levels (os três vêm juntos);
    - levels na ordem do arquivo: a ordem é a semântica (do menos ao mais sensível);
    - os membros de cada grupo, o read de cada papel e os papéis de cada membro ordenados e sem repetição: o leitor
      guarda conjuntos (frozenset), e a ordem e a repetição não mudam nada;
    - as identidades em minúsculas, como check_identity as compara (Ana@X.org e ana@x.org são a mesma pessoa), e as
      chaves de members que se fundem por isso, fundidas, como o leitor faz;
    - write explícito: ["own"] quando o papel grava na própria área (o que write ausente quer dizer) e [] quando não;
    - o ceilings do papel explícito ({} quando falta)."""
    doc = {"schema_version": 1, "canonical": policy.canonical,
           "groups": {area: sorted(members) for area, members in policy.groups.items()},
           "roles": {name: {"read": sorted(role.read), "write": [OWN] if role.writes else [],
                            "ceilings": dict(role.ceilings)}
                     for name, role in policy.roles.items()},
           "members": {who: sorted(names) for who, names in policy.members.items()}}
    if policy.levels is not None:
        doc["levels"] = list(policy.levels)
        doc["ceilings"] = {area: policy.levels[top.ceiling] for area, top in policy.ceilings.items()}
        doc["default_level"] = policy.default
    return doc


def canonical_json(doc):
    """Os bytes do JSON canônico: chaves ordenadas, sem espaço, UTF-8. Numa política (só textos ASCII e o inteiro 1)
    é o mesmo que o JCS (RFC 8785) daria."""
    return json.dumps(doc, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def digest(policy):
    """"sha256:<hex>" da forma normalizada de uma política lida (PolicyDoc)."""
    return "sha256:" + hashlib.sha256(canonical_json(normalized(policy))).hexdigest()


def digest_text(text):
    """O digest do texto de uma política, pelo leitor estrito (ValueError ou RecursionError quando é inválida)."""
    return digest(parse(text))


def read_pin(value):
    """O digest fixado de --area-policy-digest: o valor literal sha256:<64 hex minúsculos>, ou @ARQ, o arquivo commitado
    que o guarda numa linha (os brancos das pontas não contam, nem o BOM do UTF-8, que um editor no Windows põe).
    ValueError quando o valor não é um digest, ou o arquivo não se lê; o arquivo em UTF-16 (o `>` do Windows
    PowerShell 5.1 grava assim) ganha a dica de gravá-lo em UTF-8."""
    if not isinstance(value, str):
        raise ValueError(P_("the digest is sha256:<64 lowercase hex digits>, or @FILE with that line"))
    if value.startswith("@"):
        path = value[1:]
        try:
            with open(path, "rb") as fh:
                data = fh.read(DIGEST_FILE_MAX + 1)
            if data.startswith((b"\xff\xfe", b"\xfe\xff")):
                raise ValueError(P_("the digest file {path} is UTF-16: save it as UTF-8 (in PowerShell, "
                                    "kg_policy.py digest FILE | Out-File -Encoding utf8 {path})").format(path=path))
            text = data.decode("utf-8").removeprefix("\ufeff")
        except (OSError, UnicodeDecodeError) as exc:
            raise ValueError(P_("the digest file {path} cannot be read ({error})").format(
                path=path, error=getattr(exc, "strerror", None) or type(exc).__name__)) from None
        if len(data) > DIGEST_FILE_MAX or not DIGEST.fullmatch(text.strip()):
            raise ValueError(P_("the digest file {path} does not hold one sha256:<64 lowercase hex digits> line").format(
                path=path))
        return text.strip()
    if not DIGEST.fullmatch(value):
        raise ValueError(P_("the digest is sha256:<64 lowercase hex digits>, or @FILE with that line"))
    return value


def main(argv=None):
    """kg_policy.py digest ARQ: o digest da política (rc 0), ou por que ela é inválida (rc 2)."""
    ap = argparse.ArgumentParser(description=_("The kg-mcp area policy: digest FILE prints the sha256 of its normalized "
                                               "form, the value that --area-policy-digest pins in the gate and in the "
                                               "kg-mcp."))
    ap.add_argument("command", choices=("digest",))
    ap.add_argument("file", metavar=_("FILE"), help=_("the policy file (JSON)"))
    args = ap.parse_args(argv)
    kg_validate._utf8_stdio()
    try:
        with open(args.file, encoding="utf-8") as fh:
            text = fh.read()
    except (OSError, UnicodeDecodeError) as exc:
        print(_("BROKEN INPUT  {error}").format(error=_("{path} cannot be read ({error})").format(
            path=args.file, error=getattr(exc, "strerror", None) or type(exc).__name__)), file=sys.stderr)
        return 2
    try:
        value = digest_text(text)
    except (ValueError, RecursionError) as exc:  # JSONDecodeError é ValueError; aninhamento fundo, RecursionError
        print(_("BROKEN INPUT  {error}").format(error=_("{path} is not a valid policy: {error}").format(
            path=args.file, error=exc)), file=sys.stderr)
        return 2
    print(value)
    return 0


if __name__ == "__main__":
    sys.exit(main())
