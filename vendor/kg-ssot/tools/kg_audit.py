#!/usr/bin/env python3
"""O pacote de auditoria por pergunta (release 4.22, O5 do roteiro): uma linha por item de questionário, com a pergunta,
a resposta, o veredito, a evidência com data e frescor, as lacunas e o dono, em CSV, XLSX ou JSON.

O item é o par (questionário, número) que o perfil x_questionnaire nomeia (name e questions). Quem entra na linha:
- a pergunta: o nó question com o x_questionnaire do item;
- a resposta: o nó (não question) com o x_questionnaire do item, e o nó SEM perfil ligado à pergunta por DEPENDS_ON,
  numa direção ou na outra (as duas convivem nos grafos reais; a resposta sai uma vez). O nó que tem perfil já disse a
  que item responde, e nunca é puxado para outro item pela aresta;
- a evidência: o nó com SUPPORTS para uma resposta, ou com SUPPORTS ou TRACES_TO para a pergunta, para um pedido ou para
  um requisito de evidência do item, local ou de outro grafo (external_edges), nunca uma pergunta, um pedido ou um
  requisito; o REFUTES para a resposta ou a pergunta sai à parte, como contradição;
- o pedido de evidência (x_questionnaire.role evidence_request, contrato v4.13) e o requisito de evidência
  (evidence_requirement, "que evidência este item exige"): nunca são tomados por pergunta nem por resposta. Cada
  evidência diz de que pedido veio (o pedido para o qual ela aponta por SUPPORTS ou TRACES_TO).
O item que só um pedido ou um requisito cita também sai, com a lacuna de quem falta.

As lacunas são calculadas, nunca escritas à mão: sem resposta viva (a resposta refuted ou superseded sai na lista, mas
não vale), contradição viva (REFUTES de um nó que não é refuted nem superseded), sem evidência confirmada, evidência
confirmada sem verified_at válido, com reverify_every que não é duração, ou vencida pela cadência (verified_at +
reverify_every até --as-of), e o veredito vivo que não é meets nem not_applicable (ou nenhum). A evidência que não é
confirmed sai na lista, mas não fecha a lacuna. O nó com role fora do enum e o número de questions que não é texto não
entram, nem o nó com x_questionnaire sem name ou sem uma lista questions não vazia: saem em "skipped" (no JSON, na planilha
Skipped do XLSX, no CSV com --view skipped, no stderr e na saída humana), e o --fail-on-gap dá rc 1 com eles.

Não julga a forma: isso é do kg_validate.py. Um grafo que não parseia sai em "unreadable" e dá rc 1, porque o pacote
ficaria incompleto em silêncio.

Uso:
  kg_audit.py [--root DIR [--exclude GLOB]... [--no-default-excludes] | ARQ...] [--questionnaire NOME]
              [--as-of AAAA-MM-DD] [--column CHAVE]... [--format human|csv|xlsx|json] [--view questions|evidence]
              [--output ARQ] [--fail-on-gap]
--column traz a chave do nó de resposta (uma x_ do adotante, como x_remediation_cards) como coluna a mais.
--view diz qual planilha o CSV leva: as perguntas (uma linha por item), a evidência (uma linha por item e evidência)
ou o que foi pulado; o XLSX leva as três, e o JSON (kg-ssot.audit/1, spec/audit.schema.json) leva tudo aninhado.

rc: 0 exportou · 1 grafo ilegível, ou lacuna com --fail-on-gap · 2 entrada quebrada.
"""
import argparse
import csv
import datetime
import io
import json
import os
import pathlib
import re
import sys
import zipfile

sys.dont_write_bytecode = True
if __package__:  # no pacote kg_ssot, o vizinho vem pelo pacote, sem mexer no sys.path de quem importa
    from . import kg_i18n, kg_query, kg_validate
else:  # script ou vendor
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import kg_i18n  # noqa: E402
    import kg_query  # noqa: E402
    import kg_validate  # noqa: E402
_ = kg_i18n._

SCHEMA_VERSION = "kg-ssot.audit/1"
CLOSED_VERDICTS = ("meets", "not_applicable")
ROLES = ("item", "evidence_request", "evidence_requirement")
NOT_LIVE = ("refuted", "superseded")  # a resposta, a contradição ou a evidência nesses status não vale para o item
GAPS = ("no-answer", "contradicted", "no-confirmed-evidence", "evidence-unstamped", "evidence-cadence-invalid",
        "evidence-due", "verdict-open")
XLSX_CELL_MAX = 32767  # o teto de uma célula no Excel, em unidades UTF-16
_XML_BAD = re.compile("[\x00-\x08\x0b\x0c\x0e-\x1f\ufffe\uffff]")  # o que o XML 1.0 não aceita
_LINKS = ("SUPPORTS", "TRACES_TO")


def _profile(node):
    xq = node.get("x_questionnaire") if isinstance(node, dict) else None
    if not isinstance(xq, dict) or not isinstance(xq.get("name"), str) or not xq["name"]:
        return None
    if not isinstance(xq.get("questions"), list):
        return None
    return xq


def _natural(text):
    return [(0, int(p), "") if p.isdigit() else (1, 0, p) for p in re.split(r"(\d+)", text) if p]


def _order(item):
    # o texto cru desempata (1, 01, 001): sem ele a ordem do set muda a cada processo, e os bytes do XLSX também
    return (_natural(item[0]), item[0], _natural(item[1]), item[1])


def _text(value):
    """O valor de uma chave como texto de célula: a lista vira itens separados por '; ', o mapa vira JSON."""
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "; ".join(_text(v) for v in value)
    if isinstance(value, (dict, datetime.date)):
        return json.dumps(kg_query._plain(value), ensure_ascii=False, sort_keys=True, default=str)
    return str(value)


def _role(node):
    xq = _profile(node)
    return xq.get("role", "item") if xq is not None else None


def _ref(corpus, key, **extra):
    n = corpus.nodes[key]
    return {"file": key[0], "id": key[1], "label": _text(n.get("label")), **extra}


def _evidence_view(corpus, key, as_of):
    n = corpus.nodes[key]
    requests = []  # o pedido de que a evidência veio: ela aponta para ele por SUPPORTS ou TRACES_TO
    for et, k, _r in corpus.out.get(key, ()):
        if et in _LINKS and _role(corpus.nodes.get(k)) == "evidence_request" and k[1] not in requests:
            requests.append(k[1])
    problems = []
    stamp = kg_validate._as_date(n.get("verified_at"))
    if n.get("verified_at") is not None and stamp is None:
        problems.append("verified-at-invalid")
    every = kg_validate.parse_duration(n.get("reverify_every"))
    if n.get("reverify_every") is not None and every is None:
        problems.append("reverify-every-invalid")
    due = None
    if stamp and every:
        try:
            due = kg_validate.add_duration(stamp, every)
        except OverflowError:
            due = None
    return {"file": key[0], "id": key[1], "label": _text(n.get("label")), "status": _text(n.get("status")),
            "verified_at": stamp.isoformat() if stamp else None, "verified_scope": n.get("verified_scope")
            if isinstance(n.get("verified_scope"), str) else None,
            "verified_against": _text(n.get("verified_against")) or None,
            "reverify_every": _text(n.get("reverify_every")) or None,
            "due": due.isoformat() if due else None, "overdue": bool(due and due <= as_of),
            "owner": _text(n.get("owner")) or None, "trace": _text(n.get("trace")) or None, "requests": requests,
            "problems": problems}


def package(corpus, questionnaire=None, as_of=None, columns=()):
    """(itens, pulados): uma linha por item (questionário, número), em ordem natural, e os nós ou números que o pacote
    não pôde usar, com o motivo (o número que não é texto, o role fora do enum), para nada sumir em silêncio."""
    as_of = as_of or datetime.date.today()
    buckets = {"question": {}, "item": {}, "evidence_request": {}, "evidence_requirement": {}}
    skipped = []
    for key in corpus.order:
        node = corpus.nodes[key]
        xq = _profile(node)
        raw = node.get("x_questionnaire")
        name = raw.get("name") if isinstance(raw, dict) else None
        if questionnaire is not None and isinstance(name, str) and name != questionnaire:
            continue  # o perfil de outro questionário, válido ou não, não é deste pacote
        if xq is None or not xq["questions"]:
            if "x_questionnaire" in node:  # o perfil sem name, sem a lista questions ou com ela vazia não some
                skipped.append({"file": key[0], "id": key[1], "reason": "profile-invalid", "detail": _text(raw)[:80]})
            continue
        role = xq.get("role", "item")
        if role not in ROLES:
            skipped.append({"file": key[0], "id": key[1], "reason": "role-invalid", "detail": _text(role)})
            continue
        kind = "question" if role == "item" and node.get("node_type") == "question" else role
        for q in xq["questions"]:
            if not isinstance(q, str) or not q:
                skipped.append({"file": key[0], "id": key[1], "reason": "question-not-text", "detail": _text(q)})
                continue
            bucket = buckets[kind].setdefault((xq["name"], q), {})
            bucket[key] = None  # o dict guarda a ordem e responde a pertença em O(1)
    q_all, a_all, req_all, rq_all = (buckets[k] for k in ("question", "item", "evidence_request", "evidence_requirement"))
    rows = []
    for item in sorted(set(q_all) | set(a_all) | set(req_all) | set(rq_all), key=_order):
        q_keys = list(q_all.get(item, {}))
        a_keys = dict(a_all.get(item, {}))
        for q in q_keys:  # a resposta ligada à pergunta por DEPENDS_ON, numa direção ou na outra
            for k in [d for et, d, _r in corpus.out.get(q, ()) if et == "DEPENDS_ON"] + \
                     [s for et, s, _r in corpus.into.get(q, ()) if et == "DEPENDS_ON"]:
                n = corpus.nodes.get(k)
                # só o nó sem perfil: o que tem perfil já disse a que item responde, e outro item não é este
                if n is not None and n.get("node_type") != "question" and "x_questionnaire" not in n:
                    a_keys.setdefault(k, None)
        r_keys = list(req_all.get(item, {}))
        rq_keys = list(rq_all.get(item, {}))
        own = set(q_keys) | set(a_keys) | set(r_keys) | set(rq_keys)
        live_answers = {k: None for k in a_keys if corpus.nodes[k].get("status") not in NOT_LIVE}
        ev_keys, contra = {}, {}
        # só a resposta viva traz evidência e contradição: a superseded ou refuted (a refutação já reconciliada) não
        # fecha nem abre lacuna do item
        targets = ([(a, ("SUPPORTS",), True) for a in live_answers] + [(q, _LINKS, True) for q in q_keys]
                   + [(r, _LINKS, False) for r in r_keys + rq_keys])
        for target, types, refutable in targets:
            for et, src, _r in corpus.into.get(target, ()):
                if src not in corpus.nodes or src in own:
                    continue
                if et in types:
                    if corpus.nodes[src].get("node_type") == "question" or \
                            _role(corpus.nodes[src]) in ("evidence_request", "evidence_requirement"):
                        continue  # a pergunta, o pedido ou o requisito de outro item não é evidência deste
                    ev_keys.setdefault(src, None)
                elif et == "REFUTES" and refutable:
                    contra.setdefault(src, None)
        evidence = [_evidence_view(corpus, k, as_of) for k in ev_keys]
        answer_rows = []
        for k in a_keys:
            n = corpus.nodes[k]
            xq = _profile(n) or {}
            answer_rows.append({"file": k[0], "id": k[1], "label": _text(n.get("label")), "status": _text(n.get("status")),
                                "live": k in live_answers,
                                "answer_draft": xq.get("answer_draft") if isinstance(xq.get("answer_draft"), str) else None,
                                "verdict": xq.get("verdict") if isinstance(xq.get("verdict"), str) else None,
                                "answered_at": _text(xq.get("answered_at")) or None,
                                "owner": _text(n.get("owner")) or None,
                                "columns": {c: _text(n.get(c)) for c in columns}})
        verdicts = sorted({a["verdict"] for a in answer_rows if a["verdict"] and a["live"]})
        confirmed = [e for e in evidence if e["status"] == "confirmed"]
        live_contra = [k for k in contra if corpus.nodes[k].get("status") not in NOT_LIVE]
        found = {
            "no-answer": not live_answers,
            "contradicted": bool(live_contra),
            "no-confirmed-evidence": not confirmed,
            "evidence-unstamped": any(e["verified_at"] is None for e in confirmed),
            "evidence-cadence-invalid": any("reverify-every-invalid" in e["problems"] for e in confirmed),
            "evidence-due": any(e["overdue"] for e in confirmed),
            "verdict-open": not verdicts or any(v not in CLOSED_VERDICTS for v in verdicts),
        }
        owners = {}
        for k in list(a_keys) + q_keys + r_keys + rq_keys:
            o = _text(corpus.nodes[k].get("owner"))
            if o:
                owners.setdefault(o, None)
        rows.append({
            "questionnaire": item[0], "question": item[1],
            "questions": [_ref(corpus, k, trace=_text(corpus.nodes[k].get("trace")) or None) for k in q_keys],
            "answers": answer_rows, "verdicts": verdicts, "evidence": evidence,
            "requirements": [_ref(corpus, k, owner=_text(corpus.nodes[k].get("owner")) or None) for k in rq_keys],
            "contradictions": [_ref(corpus, k, status=_text(corpus.nodes[k].get("status"))) for k in contra],
            "requests": [_ref(corpus, k, owner=_text(corpus.nodes[k].get("owner")) or None) for k in r_keys],
            "owners": list(owners), "gaps": [g for g in GAPS if found[g]]})
    return rows, skipped


def _join(values):
    return "; ".join(v for v in values if v)


def question_table(rows, columns=()):
    head = [_("Questionnaire"), _("Question"), _("Question text"), _("Source item"), _("Answer"), _("Verdict"),
            _("Answer text"), _("Required evidence"), _("Evidence"), _("Evidence dates"), _("Contradictions"),
            _("Evidence requests"), _("Owner"), _("Gaps")] + list(columns)
    body = []
    for r in rows:
        body.append([
            r["questionnaire"], r["question"], _join(q["label"] for q in r["questions"]),
            _join(q["trace"] or "" for q in r["questions"]),
            _join(a["id"] + ("" if a["live"] else f" ({a['status']})") for a in r["answers"]), _join(r["verdicts"]),
            _join(a["answer_draft"] or "" for a in r["answers"] if a["live"]),
            _join(f"{q['id']} {q['label']}" for q in r["requirements"]), _join(e["id"] for e in r["evidence"]),
            _join(f"{e['id']} {e['verified_at'] or _('unstamped')}" + (f" ({e['verified_scope']})" if e["verified_scope"]
                                                                       else "") for e in r["evidence"]),
            _join(f"{c['id']} ({c['status']})" if c["status"] else c["id"] for c in r["contradictions"]),
            _join(q["id"] for q in r["requests"]), _join(r["owners"]),
            _join(r["gaps"])] + [_join(a["columns"].get(c, "") for a in r["answers"] if a["live"]) for c in columns])
    return head, body


def evidence_table(rows):
    head = [_("Questionnaire"), _("Question"), _("Evidence"), _("File"), _("Label"), _("Status"), _("Verified at"),
            _("Verified scope"), _("Verified against"), _("Reverify every"), _("Due"), _("Overdue"), _("Owner"),
            _("Trace"), _("Evidence requests"), _("Problems")]
    body = []
    for r in rows:
        for e in r["evidence"]:
            body.append([r["questionnaire"], r["question"], e["id"], e["file"], e["label"], e["status"],
                         e["verified_at"] or "", e["verified_scope"] or "", e["verified_against"] or "",
                         e["reverify_every"] or "", e["due"] or "", _("yes") if e["overdue"] else "",
                         e["owner"] or "", e["trace"] or "", _join(e["requests"]), _join(e["problems"])])
    return head, body


def skipped_table(skipped):
    head = [_("File"), _("Node"), _("Reason"), _("Detail")]
    return head, [[k["file"], k["id"], k["reason"], k["detail"]] for k in skipped]


def _csv_safe(cell):
    """A célula que começa com =, +, -, @, TAB ou CR vira texto (o apóstrofo da OWASP contra a injeção de fórmula)."""
    return "'" + cell if cell[:1] in ("=", "+", "-", "@", "\t", "\r") else cell


def to_csv(head, body):
    out = io.StringIO()
    w = csv.writer(out, lineterminator="\r\n")
    w.writerow(head)
    for row in body:
        w.writerow([_csv_safe(c) for c in row])
    return out.getvalue()


def _col(i):
    name = ""
    i += 1
    while i:
        i, rem = divmod(i - 1, 26)
        name = chr(65 + rem) + name
    return name


def _utf16_len(text):
    return len(text.encode("utf-16-le")) // 2


def _xml(text):
    text = _XML_BAD.sub("\ufffd", text)
    if _utf16_len(text) > XLSX_CELL_MAX:  # o teto do Excel conta unidades UTF-16: um emoji vale duas
        units, keep = 0, []
        for ch in text:
            units += 2 if ord(ch) > 0xFFFF else 1
            if units > XLSX_CELL_MAX - 1:  # a reticência ocupa a última unidade
                break
            keep.append(ch)
        text = "".join(keep) + "…"
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def _sheet(head, body):
    rows = []
    for r, row in enumerate([head] + body, start=1):
        style = ' s="1"' if r == 1 else ""  # o cabeçalho em negrito
        cells = "".join(f'<c r="{_col(c)}{r}" t="inlineStr"{style}><is><t xml:space="preserve">{_xml(v)}</t></is></c>'
                        for c, v in enumerate(row))
        rows.append(f'<row r="{r}">{cells}</row>')
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" state="frozen"/></sheetView>'
            f'</sheetViews><sheetData>{"".join(rows)}</sheetData></worksheet>')


def to_xlsx(sheets):
    """Um XLSX mínimo (SpreadsheetML), sem dependência: as planilhas [(nome, cabeçalho, linhas)], todo valor como texto,
    com o cabeçalho em negrito e congelado. Os bytes são estáveis: o mesmo pacote dá o mesmo arquivo."""
    ns = "http://schemas.openxmlformats.org"
    files = {
        "[Content_Types].xml": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        + "".join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" '
                  'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                  for i in range(1, len(sheets) + 1)) + "</Types>",
        "_rels/.rels": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        f'<Relationships xmlns="{ns}/package/2006/relationships">'
        f'<Relationship Id="rId1" Type="{ns}/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        "</Relationships>",
        "xl/workbook.xml": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        f'<workbook xmlns="{ns}/spreadsheetml/2006/main" xmlns:r="{ns}/officeDocument/2006/relationships"><sheets>'
        + "".join(f'<sheet name="{_xml(name[:31])}" sheetId="{i}" r:id="rId{i}"/>'
                  for i, (name, _h, _b) in enumerate(sheets, start=1)) + "</sheets></workbook>",
        "xl/_rels/workbook.xml.rels": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        f'<Relationships xmlns="{ns}/package/2006/relationships">'
        + "".join(f'<Relationship Id="rId{i}" Type="{ns}/officeDocument/2006/relationships/worksheet" '
                  f'Target="worksheets/sheet{i}.xml"/>' for i in range(1, len(sheets) + 1))
        + f'<Relationship Id="rId{len(sheets) + 1}" Type="{ns}/officeDocument/2006/relationships/styles" '
          'Target="styles.xml"/></Relationships>',
        "xl/styles.xml": '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        f'<styleSheet xmlns="{ns}/spreadsheetml/2006/main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
        '</fills><borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
    }
    for i, (_name, head, body) in enumerate(sheets, start=1):
        files[f"xl/worksheets/sheet{i}.xml"] = _sheet(head, body)
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for name, text in files.items():
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, text.encode("utf-8"))
    return out.getvalue()


def human(rows, skipped=()):
    lines = []
    for r in rows:
        lines.append(f"{r['questionnaire']} #{r['question']}  " + (_join(r["verdicts"]) or "-") + "  "
                     + (_("gaps: {gaps}").format(gaps=_join(r["gaps"])) if r["gaps"] else _("no gap")))
        for q in r["questions"]:
            lines.append(f"  ? {q['id']}  {q['label']}")
        for a in r["answers"]:
            lines.append(f"  = {a['id']}  {a['label']}" + ("" if a["live"] else f"  ({a['status']})"))
        for q in r["requirements"]:
            lines.append(f"  * {q['id']}  {q['label']}")
        for e in r["evidence"]:
            lines.append(f"  + {e['id']}  {e['status']}  {e['verified_at'] or _('unstamped')}"
                         + (f"  {_('due')} {e['due']}" if e["due"] else ""))
        for c in r["contradictions"]:
            lines.append(f"  ! {c['id']}  {c['label']}")
    for k in skipped:
        lines.append(_("SKIPPED  {file}#{id}  {reason}  {detail}").format(**k))
    n_gap = sum(1 for r in rows if r["gaps"])
    lines.append(_("· {n} item(s); {gap} with a gap").format(n=len(rows), gap=n_gap))
    return "\n".join(lines) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=_("The audit package by question: one row per questionnaire item, with "
                                               "the answer, the verdict, the dated evidence, the gaps, and the owner."))
    ap.add_argument("files", nargs="*", help=_(".kg.yaml or .kg.json files (or --root)"))
    ap.add_argument("--root", help=_("the corpus root: the graphs git tracks under it"))
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help=_("with --root, paths to leave out (repeatable), added to the defaults"))
    ap.add_argument("--no-default-excludes", action="store_true", help=_("with --root, also read the vendor and the fixtures"))
    ap.add_argument("--questionnaire", help=_("only the items of this questionnaire (x_questionnaire.name)"))
    ap.add_argument("--as-of", metavar="YYYY-MM-DD", help=_("the day the evidence is due against (default: today)"))
    ap.add_argument("--column", action="append", default=[], metavar=_("KEY"),
                    help=_("a key of the answer node to add as a column (repeatable)"))
    ap.add_argument("--format", default="human", choices=("human", "csv", "xlsx", "json"))
    ap.add_argument("--view", default="questions", choices=("questions", "evidence", "skipped"),
                    help=_("csv: the questions (one row per item), the evidence (one row per item and evidence), or "
                           "what was skipped"))
    ap.add_argument("--output", metavar=_("FILE"), help=_("write here instead of the standard output (required for xlsx)"))
    ap.add_argument("--fail-on-gap", action="store_true", help=_("rc 1 when an item has a gap or something was skipped"))
    args = ap.parse_intermixed_args(argv)
    kg_validate._utf8_stdio()

    def broken(msg):
        print(_("BROKEN INPUT  {error}").format(error=msg), file=sys.stderr)
        return 2
    if not args.root and not args.files:
        return broken(_("give --root, the files, or both"))
    if args.format == "xlsx" and not args.output:
        return broken(_("xlsx needs --output"))
    as_of = None
    if args.as_of is not None:
        as_of = kg_validate.iso_date(args.as_of)
        if as_of is None:
            return broken(_("--as-of {value} is not a YYYY-MM-DD date").format(value=args.as_of))
    try:
        corpus = kg_query.load(args.root, args.files, args.exclude, not args.no_default_excludes)
    except (OSError, ValueError, UnicodeDecodeError) as exc:
        return broken(exc)
    rows, skipped = package(corpus, args.questionnaire, as_of, args.column)
    if args.format == "json":
        data = (json.dumps({"schema_version": SCHEMA_VERSION, "as_of": (as_of or datetime.date.today()).isoformat(),
                            "questionnaire": args.questionnaire, "columns": args.column, "items": rows,
                            "skipped": skipped, "unreadable": corpus.unreadable}, ensure_ascii=False, indent=1) + "\n").encode("utf-8")
    elif args.format == "csv":
        head, body = (question_table(rows, args.column) if args.view == "questions" else
                      evidence_table(rows) if args.view == "evidence" else skipped_table(skipped))
        data = ("﻿" + to_csv(head, body)).encode("utf-8")  # o BOM faz o Excel ler o UTF-8
    elif args.format == "xlsx":
        data = to_xlsx([(_("Questions"), *question_table(rows, args.column)), (_("Evidence"), *evidence_table(rows)),
                        (_("Skipped"), *skipped_table(skipped))])
    else:
        data = human(rows, skipped).encode("utf-8")
    try:
        if args.output:
            pathlib.Path(args.output).write_bytes(data)
        else:
            sys.stdout.buffer.write(data) if hasattr(sys.stdout, "buffer") else sys.stdout.write(data.decode("utf-8"))
            sys.stdout.flush()
    except BrokenPipeError:  # quem lê fechou o pipe (| head): não é entrada quebrada
        try:
            sys.stdout = open(os.devnull, "w")
        except OSError:
            pass
    except OSError as exc:
        return broken(exc)
    if args.format != "human":  # na saída humana o pulado já saiu na listagem
        for k in skipped:
            print(_("SKIPPED  {file}#{id}  {reason}  {detail}").format(**k), file=sys.stderr)
    for u in corpus.unreadable:
        print(_("UNREADABLE  {file}  {code}").format(file=u["file"], code=u["code"]), file=sys.stderr)
    if corpus.unreadable:
        return 1  # o pacote sem um grafo ilegível ficaria incompleto em silêncio
    if args.format == "csv" and args.view != "skipped" and skipped:  # o CSV de uma planilha só não leva o pulado
        print(_("· {n} skipped: see --view skipped").format(n=len(skipped)), file=sys.stderr)
    return 1 if args.fail_on_gap and (skipped or any(r["gaps"] for r in rows)) else 0


if __name__ == "__main__":
    sys.exit(main())
