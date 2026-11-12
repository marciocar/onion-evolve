#!/usr/bin/env python3
"""voice-conduct-check.py — confere o arquivo de voz e conduta da persona contra o esquema da vertical.

Vertical company-brain-context (selo D_PERSONA_VOICE_CONDUCT_PIECE_1111, 2026-11-11, card SAC-417). A regra
de voz e conduta da persona de serviço é um arquivo por adotante, versionado e aprovado pelo dono; a persona
o carrega a cada resposta. Este validador é o que torna "versionado e aprovado" uma afirmação conferida, e não
uma declaração: a estrutura vem do esquema (.claude/utils/company-brain/voice-conduct.schema.yaml) e as regras
semânticas (histórico, aprovador, revisão vencida, separação entre pedir e aprovar) estão aqui.

O que NÃO é daqui: medir uma MENSAGEM antes do envio (tamanho, marcações, assinatura, link testado). Isso é o
gate pré-envio, a próxima peça; este validador só confere que o bloco `send_gate` que ele vai ler tem forma.

ISOLADO: só Python 3 e PyYAML. Determinístico: a data de "hoje" entra por --today (default: a data UTC).

Uso: python3 -I -B voice-conduct-check.py --file <voice-conduct.yaml> --schema <schema.yaml>
                                         [--today AAAA-MM-DD] [--format tsv|human]
Saída tsv: `<CÓDIGO>\t<caminho no arquivo>\t<mensagem>`, uma linha por achado.
rc: 0 o arquivo vale · 1 algum achado · 2 NÃO PUDE JULGAR (arquivo ou esquema ausente/ilegível, YAML que não
é mapa, --today inválido). rc 2 nunca é verde.
"""
import argparse
import datetime as dt
import re
import sys

try:
    import yaml
except Exception:  # pragma: no cover
    print("voice-conduct-check: PyYAML ausente — não pude julgar", file=sys.stderr)
    sys.exit(2)

SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
WILDCARDS = {"*", "anyone", "everyone", "todos", "qualquer-pessoa", "qualquer pessoa", "qualquer-membro"}


class Judge:
    def __init__(self):
        self.findings = []

    def add(self, code, where, msg):
        self.findings.append((code, where, msg))


def as_date(v):
    if isinstance(v, dt.datetime):
        return v.date()
    if isinstance(v, dt.date):
        return v
    if isinstance(v, str) and re.match(r"^\d{4}-\d{2}-\d{2}$", v):
        try:
            return dt.date.fromisoformat(v)
        except ValueError:
            return None
    return None


def type_ok(v, spec):
    t = spec.get("type")
    if t == "str":
        ok = isinstance(v, str) and v.strip() != ""
    elif t == "int":
        ok = isinstance(v, int) and not isinstance(v, bool)
        if ok and "min" in spec and v < spec["min"]:
            ok = False
        if ok and "max" in spec and v > spec["max"]:
            ok = False
    elif t == "bool":
        ok = isinstance(v, bool)
    elif t == "date":
        ok = as_date(v) is not None
    elif t == "semver":
        ok = isinstance(v, str) and bool(SEMVER.match(v))
    elif t == "list":
        ok = isinstance(v, list) and len(v) > 0
    elif t == "map":
        ok = isinstance(v, dict)
    else:
        ok = False
    if ok and "equals" in spec and v != spec["equals"]:
        ok = False
    return ok


def check_block(j, block, spec, where, code_missing="VC-FIELD-MISSING", code_type="VC-FIELD-TYPE"):
    for key, s in (spec.get("required") or {}).items():
        if key not in block:
            j.add(code_missing, f"{where}{key}", f"campo obrigatório ausente: {key}")
        elif not type_ok(block[key], s):
            j.add(code_type, f"{where}{key}", f"valor fora do esquema ({s}): {block[key]!r}")
    for key, s in (spec.get("optional") or {}).items():
        if key in block and not type_ok(block[key], s):
            j.add(code_type, f"{where}{key}", f"valor fora do esquema ({s}): {block[key]!r}")


def judge(doc, schema, today):
    j = Judge()
    top = schema["top_level"]
    known = set(top.get("required") or {}) | set(top.get("optional") or {})
    for key in doc:
        if key not in known:
            j.add("VC-UNKNOWN-KEY", str(key), "chave fora do esquema (erro de digitação vira regra que ninguém lê)")
    check_block(j, doc, top, "")

    # histórico
    hist = doc.get("history") if isinstance(doc.get("history"), list) else []
    for i, h in enumerate(hist):
        if not isinstance(h, dict):
            j.add("VC-FIELD-TYPE", f"history[{i}]", "entrada do histórico não é mapa")
            continue
        check_block(j, h, schema["history_entry"], f"history[{i}].")
    cur = [h for h in hist if isinstance(h, dict) and h.get("version") == doc.get("version")]
    if isinstance(doc.get("version"), str):
        if not cur:
            j.add("VC-HISTORY-CURRENT", "history", f"a versão atual {doc.get('version')} não está no histórico")
        else:
            h = cur[-1]
            if as_date(h.get("date")) != as_date(doc.get("approved_at")) or h.get("approved_by") != doc.get("approved_by"):
                j.add("VC-HISTORY-CURRENT", "history", "a entrada da versão atual diverge de approved_at/approved_by")

    # aprovação e revisão
    if isinstance(doc.get("owner"), str) and isinstance(doc.get("approved_by"), str):
        if doc["owner"] != doc["approved_by"]:
            j.add("VC-APPROVER-NOT-OWNER", "approved_by", f"quem aprovou ({doc['approved_by']}) não é o dono ({doc['owner']})")
    ad = as_date(doc.get("approved_at"))
    if ad is not None:
        if ad > today:
            j.add("VC-DATE-FUTURE", "approved_at", f"aprovação no futuro ({ad} > {today})")
        rev = doc.get("review_every_days")
        if isinstance(rev, int) and not isinstance(rev, bool) and rev >= 1:
            due = ad + dt.timedelta(days=rev)
            if due < today:
                j.add("VC-REVIEW-OVERDUE", "approved_at", f"revisão periódica vencida em {due} (hoje {today}): reaprovar")

    # seções e regras
    secs = doc.get("sections") if isinstance(doc.get("sections"), dict) else {}
    seen = {}
    for name, sspec in schema["sections"].items():
        if name not in secs:
            j.add("VC-SECTION-MISSING", f"sections.{name}", f"seção obrigatória ausente: {name}")
            continue
        s = secs[name]
        if not isinstance(s, dict):
            j.add("VC-FIELD-TYPE", f"sections.{name}", "seção não é mapa")
            continue
        check_block(j, s, sspec, f"sections.{name}.")
        rules = s.get("rules")
        if not isinstance(rules, list) or not rules:
            j.add("VC-RULES-EMPTY", f"sections.{name}.rules", "seção sem regras (lista não vazia de {id, text})")
            continue
        for i, r in enumerate(rules):
            w = f"sections.{name}.rules[{i}]"
            if not isinstance(r, dict):
                j.add("VC-FIELD-TYPE", w, "regra não é mapa {id, text}")
                continue
            check_block(j, r, schema["rule_entry"], f"{w}.")
            rid = r.get("id")
            if isinstance(rid, str) and rid:
                if rid in seen:
                    j.add("VC-RULE-ID-DUP", w, f"id de regra repetido: {rid} (já em {seen[rid]})")
                else:
                    seen[rid] = w
    for name in secs:
        if name not in schema["sections"]:
            j.add("VC-UNKNOWN-KEY", f"sections.{name}", "seção fora do esquema")

    # pedir ≠ aprovar
    rva = doc.get("request_vs_approve") if isinstance(doc.get("request_vs_approve"), dict) else None
    if rva is not None:
        rs = schema["request_vs_approve"]
        check_block(j, rva, rs, "request_vs_approve.")
        sides = {}
        for side in ("request", "approve"):
            b = rva.get(side)
            if isinstance(b, dict):
                check_block(j, b, rs["side"], f"request_vs_approve.{side}.")
                sides[side] = b
        ap = sides.get("approve") or {}
        rq = sides.get("request") or {}
        apw = {str(x).strip().lower() for x in (ap.get("who") or []) if isinstance(ap.get("who"), list)}
        if apw & WILDCARDS:
            j.add("VC-REQUEST-APPROVE", "request_vs_approve.approve.who",
                  f"aprovar é do dono, não de qualquer pessoa: {sorted(apw & WILDCARDS)}")
        both = set(map(str, ap.get("actions") or [])) & set(map(str, rq.get("actions") or [])) \
            if isinstance(ap.get("actions"), list) and isinstance(rq.get("actions"), list) else set()
        if both:
            j.add("VC-REQUEST-APPROVE", "request_vs_approve",
                  f"ação nos dois lados (pedir e aprovar se confundem): {sorted(both)}")

    # bloco do gate de envio (forma só; medir a mensagem é a próxima peça)
    sg = doc.get("send_gate")
    if isinstance(sg, dict):
        check_block(j, sg, schema["send_gate"], "send_gate.")
        for key in sg:
            if key not in (schema["send_gate"].get("optional") or {}):
                j.add("VC-UNKNOWN-KEY", f"send_gate.{key}", "chave fora do esquema do gate de envio")
        conc = (secs.get("concision") or {}).get("max_chars") if isinstance(secs.get("concision"), dict) else None
        gm = sg.get("max_chars")
        if isinstance(gm, int) and isinstance(conc, int) and gm > conc:
            j.add("VC-GATE-LOOSER", "send_gate.max_chars",
                  f"o gate aceita {gm} caracteres e a regra de concisão diz {conc}: o gate não pode ser mais frouxo")
    return j.findings


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--file", required=True)
    ap.add_argument("--schema", required=True)
    ap.add_argument("--today", default=None)
    ap.add_argument("--format", default="human", choices=["tsv", "human"])
    a = ap.parse_args()
    try:
        today = dt.date.fromisoformat(a.today) if a.today else dt.datetime.now(dt.timezone.utc).date()
    except ValueError:
        print(f"voice-conduct-check: --today inválido: {a.today} — não pude julgar", file=sys.stderr)
        return 2
    try:
        with open(a.schema, encoding="utf-8") as fh:
            schema = yaml.safe_load(fh)
        with open(a.file, encoding="utf-8-sig") as fh:
            doc = yaml.safe_load(fh)
    except FileNotFoundError as e:
        print(f"voice-conduct-check: arquivo ausente: {e.filename} — não pude julgar", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"voice-conduct-check: YAML ilegível ({type(e).__name__}) — não pude julgar", file=sys.stderr)
        return 2
    if not isinstance(schema, dict) or schema.get("schema_id") != "onion/voice-conduct/v1":
        print("voice-conduct-check: esquema inválido ou de outra versão — não pude julgar", file=sys.stderr)
        return 2
    if not isinstance(doc, dict):
        print("voice-conduct-check: o arquivo não é um mapa YAML — não pude julgar", file=sys.stderr)
        return 2
    findings = judge(doc, schema, today)
    for code, where, msg in findings:
        if a.format == "tsv":
            print(f"{code}\t{where}\t{msg}")
        else:
            print(f"❌ {code} [{where}] {msg}")
    if a.format == "human" and not findings:
        print(f"✅ voz e conduta: {a.file} confere com onion/voice-conduct/v1 (persona {doc.get('persona')}, v{doc.get('version')})")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
