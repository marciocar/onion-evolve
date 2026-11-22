#!/usr/bin/env python3
"""voice_conduct_check — julga o arquivo de voz e conduta de uma persona de serviço.

Desenho: a FORMA vem do esquema (spec/voice-conduct/v2.schema.yaml), percorrido por `walk`; o SENTIDO vem de
uma lista de verificações (`CHECKS`), cada uma uma função pequena que devolve achados. A v1 é lida por um
adaptador que aplica a regra antiga de aprovação (só o dono) e recusa o que só a v2 tem.

Uso:
  voice_conduct_check.py <arquivo> [--today AAAA-MM-DD] [--format human|tsv] [--schema <esquema>]
                         [--allow-draft] [--if-present]
  --allow-draft : arquivo com `status: draft` (sem aprovação ainda) pode sair 0; sem a flag, rascunho é achado.
  --if-present  : arquivo ausente sai 0 com aviso. É o modo de quem chama num projeto que pode não ter
                  Company Brain: o produto é opcional e não cobra quem não tem persona de serviço.
Saída: 0 vale · 1 há achados · 2 não deu para julgar (nunca é verde).
"""
import argparse
import datetime as dt
import os
import re
import string
import sys
import unicodedata
from collections import namedtuple

try:
    import yaml
except ImportError:
    sys.stderr.write("voice_conduct_check: sem PyYAML não há julgamento (rc 2)\n")
    sys.exit(2)

Finding = namedtuple("Finding", "code path text")
SCHEMA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir, "spec", "voice-conduct", "v2.schema.yaml")
V1, V2 = "onion/voice-conduct/v1", "onion/voice-conduct/v2"
ISO_DAY = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
SEMVER = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+")
MAX_BYTES = 256 * 1024  # arquivo de regras é pequeno; acima disso é engano ou ataque
# Quem não pode aprovar: papel com palavra de «todo mundo» (comparada já normalizada), ou o mesmo papel que pede.
CROWD_WORDS = {"qualquer", "quaisquer", "todo", "toda", "todos", "todas", "geral", "anyone", "anybody",
               "everyone", "everybody", "any", "all"}
PLACEHOLDER = re.compile(r"\{\{[^{}]*\}\}")


class Unjudgeable(Exception):
    """Algo impede o julgamento: vira rc 2, nunca verde."""


class StrictLoader(yaml.SafeLoader):
    """SafeLoader que recusa chave repetida (o YAML comum guarda a última em silêncio)."""


def _mapping_without_dups(loader, node, deep=False):
    keys = set()
    for knode, _ in node.value:
        key = loader.construct_object(knode, deep=deep)
        if key in keys:
            raise yaml.constructor.ConstructorError(None, None, f"chave repetida: {key!r}", knode.start_mark)
        keys.add(key)
    return loader.construct_mapping(node, deep=deep)


StrictLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _mapping_without_dups)


def canon(value):
    """Forma canônica de um papel ou de uma ação: sem acento (NFKD), sem caractere invisível, minúsculas,
    '-'/'_' como espaço, espaços colapsados, sem pontuação nas pontas. Assim «Abrir card.», «abrir  card»,
    «abrir-card» e «pedir informacao» batem com as formas escritas de outro jeito. Só se aplica a texto."""
    text = unicodedata.normalize("NFKD", value)
    text = "".join(ch for ch in text if not unicodedata.combining(ch) and unicodedata.category(ch) != "Cf")
    text = text.lower().replace("-", " ").replace("_", " ")
    text = " ".join(text.split())
    return text.strip(string.punctuation + " ")


def key(value):
    """Chave de comparação: a forma canônica sem espaços (um espaço invisível no meio não separa nada)."""
    return canon(value).replace(" ", "")


def is_crowd(raw, canonical):
    """Papel que quer dizer «todo mundo»: símbolo sozinho (como «*») ou alguma palavra de multidão."""
    if canonical == "":
        return True
    return bool(set(canonical.split()) & CROWD_WORDS) or raw.strip() in {"*", "@all", "@channel", "@here"}


# ---------------------------------------------------------------- forma (dirigida pelo esquema)
def _is_day(v):
    if isinstance(v, dt.datetime):
        return False
    if isinstance(v, dt.date):
        return True
    if isinstance(v, str) and ISO_DAY.fullmatch(v):
        try:
            dt.date.fromisoformat(v)
            return True
        except ValueError:
            return False
    return False


def _is_text(v):
    return isinstance(v, str) and v.strip() != ""


TYPE_TESTS = {
    "str": _is_text,
    "int": lambda v: type(v) is int,
    "bool": lambda v: type(v) is bool,
    "date": _is_day,
    "semver": lambda v: isinstance(v, str) and SEMVER.fullmatch(v) is not None,
    "list": lambda v: isinstance(v, list) and len(v) > 0,
    "list_of_str": lambda v: isinstance(v, list) and len(v) > 0 and all(_is_text(x) for x in v),
    "map": lambda v: isinstance(v, dict),
}


def fits(value, rule):
    test = TYPE_TESTS.get(rule.get("type"))
    if test is None:
        raise Unjudgeable(f"tipo desconhecido no esquema: {rule.get('type')!r}")
    if not test(value):
        return False
    if "min" in rule and value < rule["min"]:
        return False
    if "max" in rule and value > rule["max"]:
        return False
    if "equals" in rule and value != rule["equals"]:
        return False
    if "one_of" in rule and value not in rule["one_of"]:
        return False
    return True


def describe(rule):
    extra = [f"{k}={rule[k]}" for k in ("equals", "one_of", "min", "max") if k in rule]
    return rule.get("type", "?") + (f" ({', '.join(extra)})" if extra else "")


def walk(block, required, optional, path):
    """Confere um mapa contra campos obrigatórios e opcionais; devolve achados."""
    out = []
    here = (path + ".") if path else ""
    for name, rule in required.items():
        if name not in block:
            out.append(Finding("VC-FIELD-MISSING", here + name, "falta este campo"))
        elif not fits(block[name], rule):
            out.append(Finding("VC-FIELD-TYPE", here + name, f"valor fora da forma: pede {describe(rule)}"))
    for name, rule in optional.items():
        if name in block and not fits(block[name], rule):
            out.append(Finding("VC-FIELD-TYPE", here + name, f"valor fora da forma: pede {describe(rule)}"))
    for name in block:
        if name not in required and name not in optional:
            out.append(Finding("VC-UNKNOWN-KEY", here + str(name), "campo que o esquema não conhece (ninguém o leria)"))
    return out


# ---------------------------------------------------------------- contexto do julgamento
class Ctx:
    def __init__(self, doc, schema, today, allow_draft):
        self.doc, self.schema, self.today, self.allow_draft = doc, schema, today, allow_draft
        self.v1 = doc.get("schema") == V1
        self.draft = (not self.v1) and doc.get("status") == "draft"

    def get_map(self, *keys):
        node = self.doc
        for k in keys:
            node = node.get(k) if isinstance(node, dict) else None
        return node if isinstance(node, dict) else {}

    def approve_entries(self):
        rva = self.get_map("request_vs_approve")
        raw = rva.get("approve")
        if self.v1:
            return [("request_vs_approve.approve", raw)] if isinstance(raw, dict) else []
        if not isinstance(raw, list):
            return []
        return [(f"request_vs_approve.approve[{i}]", e) for i, e in enumerate(raw)]


def as_day(v):
    if isinstance(v, dt.date) and not isinstance(v, dt.datetime):
        return v
    return dt.date.fromisoformat(v) if _is_day(v) else None


# ---------------------------------------------------------------- verificações (o sentido)
def check_top(c):
    top = c.schema["top_level"]
    required = dict(top["required"])
    optional = dict(top.get("optional", {}))
    required["schema"] = {"type": "str", "equals": c.doc.get("schema")}
    if c.v1:
        required["request_vs_approve"] = {"type": "map"}
        optional.pop("status", None)
    out = []
    if c.draft:  # rascunho ainda não tem aprovação: o carimbo não pode vir antes do aceite do dono
        for k in ("approved_by", "approved_at"):
            required.pop(k)
            if k in c.doc:
                out.append(Finding("VC-DRAFT-STAMPED", k, "rascunho não leva carimbo de aprovação"))
        optional["history"] = {"type": "list"}
        required.pop("history")
        if c.doc.get("history") == []:
            optional.pop("history")
            return out + walk({k: v for k, v in c.doc.items() if k not in ("approved_by", "approved_at", "history")}, required, optional, "")
    return out + walk({k: v for k, v in c.doc.items() if not (c.draft and k in ("approved_by", "approved_at"))}, required, optional, "")


def check_draft(c):
    if c.draft and not c.allow_draft:
        return [Finding("VC-NOT-APPROVED", "status", "rascunho: falta a aprovação do dono antes de valer")]
    return []


def check_history(c):
    out, hist = [], c.doc.get("history")
    if not isinstance(hist, list):
        return out
    versions = {}
    for i, entry in enumerate(hist):
        where = f"history[{i}]"
        if not isinstance(entry, dict):
            out.append(Finding("VC-FIELD-TYPE", where, "cada entrada do histórico é um mapa"))
            continue
        out += walk(entry, c.schema["history_entry"]["required"], {}, where)
        v = entry.get("version")
        if isinstance(v, str):
            if v in versions:
                out.append(Finding("VC-HISTORY-DUP", where, f"a versão {v} já aparece em {versions[v]}"))
            else:
                versions[v] = where
    if c.draft:
        if any(isinstance(e, dict) and e.get("version") == c.doc.get("version") for e in hist):
            out.append(Finding("VC-DRAFT-STAMPED", "history", "a versão em rascunho não entra no histórico antes do aceite"))
        return out
    cur = next((e for e in hist if isinstance(e, dict) and e.get("version") == c.doc.get("version")), None)
    if cur is None:
        out.append(Finding("VC-HISTORY-CURRENT", "history", f"a versão vigente ({c.doc.get('version')}) não tem entrada no histórico"))
    elif as_day(cur.get("date")) != as_day(c.doc.get("approved_at")) or not _is_text(cur.get("approved_by")) \
            or not _is_text(c.doc.get("approved_by")) or canon(cur["approved_by"]) != canon(c.doc["approved_by"]):
        out.append(Finding("VC-HISTORY-CURRENT", "history", "a entrada da versão vigente não bate com approved_at e approved_by"))
    return out


def check_owner_and_dates(c):
    out = []
    if c.draft:
        return out
    if _is_text(c.doc.get("approved_by")) and _is_text(c.doc.get("owner")) and canon(c.doc["approved_by"]) != canon(c.doc["owner"]):
        out.append(Finding("VC-APPROVER-NOT-OWNER", "approved_by", "as regras só valem aprovadas pelo dono delas"))
    day = as_day(c.doc.get("approved_at"))
    if day:
        if day > c.today:
            out.append(Finding("VC-DATE-FUTURE", "approved_at", f"aprovação com data adiante de hoje ({day}, hoje {c.today})"))
        every = c.doc.get("review_every_days")
        if type(every) is int and day + dt.timedelta(days=every) < c.today:
            out.append(Finding("VC-REVIEW-OVERDUE", "approved_at", f"a revisão periódica venceu em {day + dt.timedelta(days=every)}: o dono precisa reaprovar"))
    return out


def check_sections(c):
    out, secs = [], c.doc.get("sections")
    if not isinstance(secs, dict):
        return out
    ids = {}
    for name, spec in c.schema["sections"].items():
        if c.v1 and name == "principles":
            if name in secs:
                out.append(Finding("VC-UNKNOWN-KEY", "sections.principles", "princípios só existem a partir da v2"))
            continue
        if name not in secs:
            if not spec.get("optional_section"):
                out.append(Finding("VC-SECTION-MISSING", f"sections.{name}", "seção obrigatória ausente"))
            continue
        sec = secs[name]
        where = f"sections.{name}"
        if not isinstance(sec, dict):
            out.append(Finding("VC-FIELD-TYPE", where, "a seção é um mapa com `rules`"))
            continue
        required = dict(spec.get("required", {}))
        optional = {} if c.v1 else dict(spec.get("optional", {}))
        if c.v1:
            required.pop("max_chars_basis", None)
        rules = sec.get("rules")
        out += walk({k: v for k, v in sec.items() if k != "rules"}, required, optional, where)
        if not isinstance(rules, list) or not rules:
            out.append(Finding("VC-RULES-EMPTY", where + ".rules", "toda seção precisa de ao menos uma regra {id, text}"))
            continue
        for k, rule in enumerate(rules):
            rwhere = f"{where}.rules[{k}]"
            if not isinstance(rule, dict):
                out.append(Finding("VC-FIELD-TYPE", rwhere, "regra é um mapa {id, text}"))
                continue
            out += walk(rule, c.schema["rule_entry"]["required"], {}, rwhere)
            rid = rule.get("id")
            if _is_text(rid):
                key = rid.strip().upper()
                if key in ids:
                    out.append(Finding("VC-RULE-ID-DUP", rwhere, f"o id {rid} repete {ids[key]} (sem diferença de caixa)"))
                else:
                    ids[key] = rwhere
    for name in secs:
        if name not in c.schema["sections"]:
            out.append(Finding("VC-UNKNOWN-KEY", f"sections.{name}", "seção que o esquema não conhece"))
    return out


def check_concision_basis(c):
    if c.v1:
        return []
    conc = c.get_map("sections", "concision")
    basis, evidence = conc.get("max_chars_basis"), conc.get("max_chars_evidence")
    if basis == "measured" and evidence is None:
        return [Finding("VC-MEASURE-WITHOUT-EVIDENCE", "sections.concision.max_chars_evidence", "número dado como medido precisa dizer de onde veio a medida")]
    if basis == "measured" and isinstance(evidence, dict):
        return walk(evidence, {"source": {"type": "str"}, "sample": {"type": "int", "min": 1}, "measured_at": {"type": "date"}},
                    {}, "sections.concision.max_chars_evidence")
    if basis == "hypothesis" and evidence is not None:
        return [Finding("VC-EVIDENCE-WITHOUT-MEASURE", "sections.concision.max_chars_evidence", "evidência só cabe com max_chars_basis: measured")]
    return []


def check_request_vs_approve(c):
    out = []
    rva = c.doc.get("request_vs_approve")
    if not isinstance(rva, dict):
        return out
    spec = c.schema["request_vs_approve"]
    req_rules = dict(spec["required"])
    if c.v1:
        req_rules["approve"] = {"type": "map"}
    out += walk(rva, req_rules, {}, "request_vs_approve")
    request = rva.get("request") if isinstance(rva.get("request"), dict) else {}
    out += walk(request, spec["request_side"]["required"], {}, "request_vs_approve.request")
    asked = {key(a) for a in request.get("actions") or [] if _is_text(a)}
    askers = {key(w) for w in request.get("who") or [] if _is_text(w)}
    owner = canon(c.doc.get("owner", "")) if _is_text(c.doc.get("owner")) else None
    approver_of = {}
    for where, entry in c.approve_entries():
        if not isinstance(entry, dict):
            out.append(Finding("VC-FIELD-TYPE", where, "cada aprovação é um mapa {who, actions}"))
            continue
        out += walk(entry, spec["approve_entry"]["required"], {}, where)
        raw_who = [w for w in entry.get("who") or [] if _is_text(w)]
        who = {key(w) for w in raw_who}
        if any(is_crowd(w, canon(w)) for w in raw_who):
            out.append(Finding("VC-REQUEST-APPROVE", where + ".who", "aprovar nunca é de todo mundo: nomeie o papel"))
        elif who & askers:
            out.append(Finding("VC-REQUEST-APPROVE", where + ".who", "o mesmo papel que pede não pode aprovar"))
        if c.v1 and owner is not None and who != {owner.replace(" ", "")}:
            out.append(Finding("VC-APPROVER-NOT-OWNER", where + ".who", "na v1 só o dono aprova; para aprovar por tipo de ato, migre para a v2"))
        for action in entry.get("actions") or []:
            if not _is_text(action):
                continue
            k = key(action)
            if k == "":
                out.append(Finding("VC-FIELD-TYPE", where + ".actions", f"ação sem conteúdo: «{action}»"))
                continue
            if k in asked:
                out.append(Finding("VC-REQUEST-APPROVE", where + ".actions", f"«{action}» aparece em pedir e em aprovar"))
            if k in approver_of:
                out.append(Finding("VC-APPROVE-ACTION-DUP", where + ".actions", f"«{action}» já tem aprovador em {approver_of[k]}"))
            else:
                approver_of[k] = where
    return out


def check_send_gate(c):
    gate = c.doc.get("send_gate")
    if gate is None:
        return []
    if not isinstance(gate, dict):
        return [Finding("VC-FIELD-TYPE", "send_gate", "o gate de envio é um mapa")]
    out = walk(gate, {}, c.schema["send_gate"]["optional"], "send_gate")
    limit, rule = gate.get("max_chars"), c.get_map("sections", "concision").get("max_chars")
    if type(limit) is int and type(rule) is int and limit > rule:
        out.append(Finding("VC-GATE-LOOSER", "send_gate.max_chars", f"o gate deixa passar {limit}, mais que a regra ({rule})"))
    return out


def check_placeholders(c):
    out = []

    def scan(node, path):
        if isinstance(node, dict):
            for k, v in node.items():
                scan(v, f"{path}.{k}" if path else str(k))
        elif isinstance(node, list):
            for i, v in enumerate(node):
                scan(v, f"{path}[{i}]")
        elif isinstance(node, str) and PLACEHOLDER.search(node):
            out.append(Finding("VC-PLACEHOLDER", path, "marcador do template ainda não preenchido"))
    scan(c.doc, "")
    return out


CHECKS = [check_placeholders, check_top, check_draft, check_history, check_owner_and_dates, check_sections,
          check_concision_basis, check_request_vs_approve, check_send_gate]


def judge(doc, schema, today, allow_draft=False):
    if not isinstance(doc, dict):
        return [Finding("VC-FIELD-TYPE", "/", "o arquivo precisa ser um mapa")]
    if doc.get("schema") not in (V1, V2):
        return [Finding("VC-SCHEMA-UNKNOWN", "schema", f"esquema {doc.get('schema')!r} não reconhecido (aceitos: {V1}, {V2})")]
    ctx = Ctx(doc, schema, today, allow_draft)
    findings = []
    for check in CHECKS:
        findings += check(ctx)
    return findings


def load(path, what):
    try:
        if os.path.getsize(path) > MAX_BYTES:
            raise Unjudgeable(f"{what} passa de {MAX_BYTES} bytes")
        with open(path, encoding="utf-8-sig") as fh:
            text = fh.read()
        # alias YAML (&a / *a) multiplica o documento na memória; arquivo de regras não precisa disso
        if any(isinstance(ev, yaml.AliasEvent) for ev in yaml.parse(text, Loader=yaml.SafeLoader)):
            raise Unjudgeable(f"{what} usa alias YAML (*), que este validador recusa")
        return yaml.load(text, Loader=StrictLoader)
    except UnicodeDecodeError:
        raise Unjudgeable(f"{what} não está em UTF-8: {path}")
    except yaml.constructor.ConstructorError as exc:
        if "chave repetida" in str(exc):
            return exc  # achado do arquivo, não falta de julgamento
        raise Unjudgeable(f"{what} ilegível: {exc}")
    except (OSError, yaml.YAMLError) as exc:
        raise Unjudgeable(f"{what} ilegível: {exc}")


def main(argv=None):
    ap = argparse.ArgumentParser(prog="voice_conduct_check", description="julga o arquivo de voz e conduta da persona")
    ap.add_argument("file")
    ap.add_argument("--today")
    ap.add_argument("--format", choices=("human", "tsv"), default="human")
    ap.add_argument("--schema", default=SCHEMA_PATH)
    ap.add_argument("--allow-draft", action="store_true")
    ap.add_argument("--if-present", action="store_true")
    args = ap.parse_args(argv)
    try:
        if args.if_present and not os.path.lexists(args.file):
            sys.stderr.write(f"voice_conduct_check: {args.file} não existe; sem persona de serviço, nada a cobrar\n")
            return 0
        today = dt.datetime.now(dt.timezone.utc).date()
        if args.today:
            if not ISO_DAY.fullmatch(args.today):
                raise Unjudgeable(f"--today fora de AAAA-MM-DD: {args.today}")
            today = dt.date.fromisoformat(args.today)
        schema = load(args.schema, "o esquema")
        if not isinstance(schema, dict) or schema.get("schema_id") != V2:
            raise Unjudgeable(f"o esquema em {args.schema} não é {V2}")
        doc = load(args.file, "o arquivo")
        if isinstance(doc, Exception):
            findings = [Finding("VC-DUP-KEY", "/", str(doc).splitlines()[0])]
        else:
            findings = judge(doc, schema, today, args.allow_draft)
    except Unjudgeable as exc:
        sys.stderr.write(f"voice_conduct_check: não deu para julgar: {exc}\n")
        return 2
    except Exception as exc:  # qualquer falha inesperada é «não julguei», nunca verde nem achado falso
        sys.stderr.write(f"voice_conduct_check: não deu para julgar ({type(exc).__name__}: {exc})\n")
        return 2
    for f in findings:
        print(f"{f.code}\t{f.path}\t{f.text}" if args.format == "tsv" else f"✗ {f.code} em {f.path}: {f.text}")
    if not findings and args.format == "human":
        tag = " (rascunho)" if isinstance(doc, dict) and doc.get("status") == "draft" else ""
        print(f"✓ {args.file}: forma e sentido conferem com {doc.get('schema')}{tag}")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
