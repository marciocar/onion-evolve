#!/usr/bin/env python3
"""conformance.py: confere a saída de um adapter de canal de conversa contra o contrato onion.chat/v1.

Por que existe (D_CHAT_CHANNEL_CONTRACT_SDAAL_1121, selado pelo maestro em 2026-11-21 sobre um Delphi de 4 sessões,
unânime): o contrato e os testes de conformidade moram no core; o adapter roda na peça que opera o canal, com o
segredo dela. O core não chama o provedor. O que ele pode fazer é dizer se o que o adapter entrega ao agente (o
evento recebido) e o que ele manda para fora (a resposta) têm a forma e cumprem as regras do contrato. Este é o
juiz; a peça o roda na própria bancada, contra a saída do adapter com o provedor simulado.

Uso:
  conformance.py check <arquivo>            evento(s) e resposta(s): um objeto JSON, ou JSONL (um por linha)
  conformance.py capabilities <tsv> [--strict]
                                            a declaração adapters/<p>.capabilities.tsv contra vocabulary.tsv; com
                                            --strict, toda capacidade required não implemented também viola (é o
                                            veredito do adapter, não só da declaração)
  conformance.py --vocabulary               imprime as capacidades do contrato (capability, kind, requirement)

Saída: uma linha por violação, «VIOLA<TAB><onde><TAB><código><TAB><mensagem>», no stdout; diagnóstico no stderr.
rc 0 conforme · 1 viola · 2 não mediu (uso, arquivo ausente ou vazio, nenhuma mensagem, jsonschema ausente, contrato
ilegível).
Entrada que não é JSON é violação (rc 1): o adapter entregou algo que não é mensagem.

O que confere no evento recebido (message.received), além da forma do message.schema.json:
  - SEM-ID-DO-PROVEDOR: sem provider_message_id, não há dedupe nem fio;
  - IDENTIDADE-FORA-DO-ID: quem pede tem de vir resolvido pelo id do provedor (resolved_by = provider_id). Nome
    exibido ou texto da mensagem não identificam ninguém;
  - SEM-AUDIENCIA: sem a lista de quem mais vê a conversa, o agente não sabe para quem está respondendo;
  - DUPLICADO: o mesmo (provider, place.id, provider_message_id) duas vezes no mesmo fluxo. O provedor entrega pelo
    menos uma vez; o adapter deduplica antes de entregar ao agente;
  - e as regras que cruzam campos: quem pede está na audiência, a hora em que o agente viu não vem antes da hora
    do pedido, a retenção vence depois do pedido, pessoa não resolvida tem papel «external», e «customer» nunca no WAHA;
  - ID-COM-NUMERO: nenhum identificador (provider_id de quem pede e da audiência, lugar, fio, ids de mensagem) leva
    o id cru com telefone ou e-mail (8+ dígitos, admitido um separador entre eles, ou local@domínio), sem exceção;
    a forma recomendada <provider>:[a-p]{16} não tem dígito.
Na resposta (message.reply): a guarda de vazamento e a audiência passaram antes de sair, a ordem das horas
(pedido, visto, respondido), o passo «serviu?» declarado, o registro de auditoria, e nenhum número no texto
(heurística declarada: 10 ou mais dígitos com separadores de telefone, depois de tirar datas e horas). Com eventos
no mesmo fluxo, a resposta tem de apontar para um deles, no mesmo lugar e fio, em nome de quem pediu e com as horas
da mensagem respondida. Data com a forma certa mas impossível é FORMA, porque desligaria as checagens de ordem.

O que NÃO confere (limite declarado): se o id do provedor é verdadeiro, se a resolução de identidade acertou a
pessoa, se a guarda de vazamento da peça funciona (aqui só se lê o veredito que ela declara). Isso se mede na
bancada da peça, com o provedor simulado e mutantes, que o contrato exige.
"""
import copy
import datetime
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.realpath(__file__))
SCHEMA_PATH = os.path.join(HERE, "message.schema.json")
VOCAB_PATH = os.path.join(HERE, "vocabulary.tsv")
STATUSES = ("implemented", "partial", "not_implemented", "unverified")
# Telefone: 10 ou mais dígitos com até 3 separadores de telefone entre eles ("(11) 98765-4321", "+55 (11) 9 8765-4321").
# Datas e horas saem antes da busca, para "2026-11-22 13:00" não parecer número.
DIGIT_RUN = re.compile(r"(?:\d[\s.()+-]{0,3}){10,}")
DATE_TIME = re.compile(r"\b\d{4}-\d{2}-\d{2}(?:[T ]\d{2}:\d{2}(?::\d{2})?)?\b|\b\d{1,2}:\d{2}(?::\d{2})?\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b")
# Identificador que sai do adapter é pseudônimo: nunca o id cru com telefone ou e-mail (no WAHA, <número>@c.us).
# Forma recomendada: <provider>: mais os 64 primeiros bits do HMAC-SHA256 do id cru (chave privada da instância), um
# nibble por letra de a a p: <provider>:[a-p]{16}, sem nenhum dígito. O apelido da lista fechada também serve. A guarda
# de 8 dígitos NÃO tem exceção: em hex, cerca de 20% dos pseudônimos sorteiam 8 dígitos seguidos (medido pela
# bancada da mensageria), e esses são recusados como qualquer outro.
# 8 ou mais dígitos, admitindo um separador entre eles ("+55 11 98765-4321", "5511_98765_4321"); e qualquer
# local@domínio, com ou sem TLD ("pessoa@empresa", "<número>@c.us", "<id>@lid", "<id>@g.us").
EIGHT_DIGITS = re.compile(r"(?:\d[\s.()+_-]?){8,}")
EMAIL_LIKE = re.compile(r"[^\s@]+@[^\s@]+")
ID_FIELDS = {
    "received": (("provider_message_id",), ("requester", "provider_id"), ("place", "id"), ("thread", "id"),
                 ("thread", "reply_to")),
    "reply": (("in_reply_to",), ("on_behalf_of", "provider_id"), ("place", "id"), ("thread", "id")),
}
# customer é reservado ao canal OFICIAL com cliente final: lista fechada (allowlist), não lista de proibidos, para que
# um provedor novo não oficial (outro nome para o WhatsApp não oficial) não herde o papel por omissão.
CUSTOMER_PROVIDERS = frozenset({"whatsapp-cloud"})
TS_FIELDS = {
    "received": (("requested_at",), ("seen_at",), ("audience", "listed_at"), ("retention", "expires_at")),
    "reply": (("audience_checked", "listed_at"), ("latency", "requested_at"), ("latency", "seen_at"), ("latency", "replied_at")),
}


class NotMeasured(Exception):
    pass


def out(where, code, msg, acc):
    acc.append((str(where), code, msg))


def parse_ts(value):
    if not isinstance(value, str):
        return None
    try:
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def load_schema():
    try:
        import jsonschema  # noqa: F401
    except ImportError:
        raise NotMeasured("jsonschema ausente: sem ele a forma não se mede (pip install jsonschema)")
    try:
        with open(SCHEMA_PATH, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError) as exc:
        raise NotMeasured(f"contrato ilegível ({SCHEMA_PATH}): {exc}")


def validator_for(schema, kind):
    import jsonschema
    sub = copy.deepcopy(schema)
    sub.pop("oneOf", None)
    sub["$ref"] = "#/$defs/" + kind
    return jsonschema.Draft202012Validator(sub)


def schema_errors(validator, obj):
    errs = []
    for e in sorted(validator.iter_errors(obj), key=lambda e: list(e.absolute_path)):
        path = "/".join(str(p) for p in e.absolute_path) or "(raiz)"
        errs.append((path, e.validator, e.message))
    return errs


def classify_schema_error(path, keyword, message):
    """Dá às faltas que o contrato nomeia o código delas; o resto sai como FORMA."""
    if keyword == "required":
        m = re.match(r"'([^']+)' is a required property", message)
        missing = m.group(1) if m else ""
        if missing == "provider_message_id":
            return "SEM-ID-DO-PROVEDOR"
        if missing == "audience":
            return "SEM-AUDIENCIA"
        if missing in ("requester", "resolved_by", "provider_id") and path in ("(raiz)", "requester", "on_behalf_of"):
            return "IDENTIDADE-FORA-DO-ID"
    if path.startswith("requester/resolved_by") or path.startswith("on_behalf_of/resolved_by"):
        return "IDENTIDADE-FORA-DO-ID"
    if path.startswith("requester/provider_id") or path.startswith("on_behalf_of/provider_id"):
        return "IDENTIDADE-FORA-DO-ID"
    if path == "provider_message_id":
        return "SEM-ID-DO-PROVEDOR"
    if path.startswith("audience"):
        return "SEM-AUDIENCIA"
    return "FORMA"


def dig(obj, path):
    for k in path:
        obj = obj.get(k) if isinstance(obj, dict) else None
    return obj


def check_timestamps(obj, kind, where, acc):
    """Data com a forma certa mas impossível (13:00:99, 30 de fevereiro) desligaria em silêncio as checagens de ordem."""
    for path in TS_FIELDS[kind]:
        v = dig(obj, path)
        if isinstance(v, str) and parse_ts(v) is None:
            out(where, "FORMA", f"{'/'.join(path)}: data ou hora impossível ({v!r})", acc)


def raw_id(value):
    if not isinstance(value, str):
        return False
    return bool(EIGHT_DIGITS.search(value) or EMAIL_LIKE.search(value))


def check_ids(obj, kind, where, acc):
    """Guarda de vazamento sobre os identificadores: o id cru com telefone ou e-mail fica dentro do adapter."""
    paths = list(ID_FIELDS[kind])
    if kind == "received":
        members = dig(obj, ("audience", "members"))
        paths += [("audience", "members", i, "provider_id") for i in range(len(members) if isinstance(members, list) else 0)]
    for path in paths:
        v = obj
        for k in path:
            v = v[k] if isinstance(v, list) and isinstance(k, int) and k < len(v) else (v.get(k) if isinstance(v, dict) else None)
        if raw_id(v):
            out(where, "ID-COM-NUMERO", f"{'/'.join(str(p) for p in path)}: identificador cru com 8+ dígitos ou forma de e-mail; use pseudônimo (<provider>:[a-p]{16}) ou apelido", acc)


def check_role(person_holder, provider, field, where, acc):
    role = (person_holder or {}).get("role")
    if (person_holder or {}).get("person") is None and role not in (None, "external"):
        out(where, "IDENTIDADE-FORA-DO-ID", f"{field}: pessoa não resolvida com papel {role!r}: sem pessoa no mapa, o papel é «external»", acc)
    if role == "customer" and provider not in CUSTOMER_PROVIDERS:
        out(where, "PAPEL", f"{field}: papel customer no provedor {provider!r}; cliente final só no canal oficial {sorted(CUSTOMER_PROVIDERS)} (D_WAHA_INTERNAL_ONLY_OFFICIAL_FOR_CUSTOMERS_1121)", acc)


def check_received(obj, where, acc, seen, received_ids):
    req = obj.get("requester") or {}
    aud = obj.get("audience") or {}
    members = aud.get("members") if isinstance(aud.get("members"), list) else []
    ids = {m.get("provider_id") for m in members if isinstance(m, dict)}
    if req.get("provider_id") and members and req["provider_id"] not in ids:
        out(where, "SEM-AUDIENCIA", "quem pede não está na audiência: a lista não é de quem vê esta conversa", acc)
    check_role(req, obj.get("provider"), "requester", where, acc)
    t_req, t_seen = parse_ts(obj.get("requested_at")), parse_ts(obj.get("seen_at"))
    if t_req and t_seen and t_seen < t_req:
        out(where, "LATENCIA", "seen_at antes de requested_at: a latência sairia negativa", acc)
    t_exp = parse_ts((obj.get("retention") or {}).get("expires_at"))
    if t_req and t_exp and t_exp <= t_req:
        out(where, "RETENCAO", "retention.expires_at não é depois do pedido: sem prazo de retenção de verdade", acc)
    pid = obj.get("provider_message_id")
    if isinstance(pid, str) and pid:
        key = (obj.get("provider"), (obj.get("place") or {}).get("id"), pid)
        if key in seen:
            out(where, "DUPLICADO", f"mesma mensagem do provedor já entregue em {seen[key]}: o adapter deduplica antes do agente", acc)
        else:
            seen[key] = where
        received_ids.setdefault((obj.get("provider"), pid), []).append(obj)


def check_reply(obj, where, acc):
    if (obj.get("leak_guard") or {}).get("verdict") != "passed":
        out(where, "VAZAMENTO", "resposta saiu sem a guarda de vazamento passar", acc)
    ac = obj.get("audience_checked") or {}
    if ac.get("verdict") != "ok":
        out(where, "SEM-AUDIENCIA", "resposta saiu com a audiência reprovada", acc)
    lat = obj.get("latency") or {}
    t_req, t_seen, t_rep = (parse_ts(lat.get(k)) for k in ("requested_at", "seen_at", "replied_at"))
    t_aud = parse_ts(ac.get("listed_at"))
    if t_req and t_seen and t_seen < t_req:
        out(where, "LATENCIA", "seen_at antes de requested_at", acc)
    if t_seen and t_rep and t_rep < t_seen:
        out(where, "LATENCIA", "replied_at antes de seen_at", acc)
    if t_aud and t_rep and t_aud > t_rep:
        out(where, "SEM-AUDIENCIA", "a audiência foi listada DEPOIS da resposta: o verbo de audiência vem antes", acc)
    served = obj.get("served") or {}
    if served.get("asked") is False and not str(served.get("reason") or "").strip():
        out(where, "SERVIU", "o passo «serviu?» foi pulado sem motivo declarado", acc)
    text = (obj.get("body") or {}).get("text")
    if isinstance(text, str) and DIGIT_RUN.search(DATE_TIME.sub(" ", text)):
        out(where, "VAZAMENTO", "o texto que sai tem 10 ou mais dígitos com separadores de telefone (cara de número)", acc)


def check_reply_against(obj, ev, where, acc):
    """A resposta tem de ser À mensagem que pediu: mesmo lugar, mesmo fio, em nome de quem pediu, com as horas dela."""
    if dig(obj, ("place", "id")) != dig(ev, ("place", "id")):
        out(where, "FIO", "a resposta vai a outro lugar que não o da mensagem que pediu (outra audiência)", acc)
    if dig(obj, ("thread", "id")) != dig(ev, ("thread", "id")):
        out(where, "FIO", "a resposta vai a outro fio que não o da mensagem que pediu", acc)
    for k in ("provider_id", "person", "role"):
        if dig(obj, ("on_behalf_of", k)) != dig(ev, ("requester", k)):
            out(where, "IDENTIDADE-FORA-DO-ID", f"on_behalf_of.{k} não é o de quem pediu na mensagem respondida", acc)
            break
    for k in ("requested_at", "seen_at"):
        a, b = parse_ts(dig(obj, ("latency", k))), parse_ts(ev.get(k))
        if a and b and a != b:
            out(where, "LATENCIA", f"latency.{k} não é o {k} da mensagem respondida", acc)


def read_messages(path):
    if path != "-" and not os.path.isfile(path):
        raise NotMeasured(f"arquivo ausente: {path}")
    try:
        raw = sys.stdin.read() if path == "-" else open(path, encoding="utf-8").read()
    except (OSError, UnicodeDecodeError) as exc:
        raise NotMeasured(f"arquivo ilegível: {path}: {exc}")
    if not raw.strip():
        raise NotMeasured(f"arquivo vazio: {path}")
    try:
        whole = json.loads(raw)
        return [(1, whole, None)] if not isinstance(whole, list) else [(i + 1, o, None) for i, o in enumerate(whole)]
    except ValueError:
        pass
    msgs = []
    for n, line in enumerate(raw.splitlines(), 1):
        if not line.strip():
            continue
        try:
            msgs.append((n, json.loads(line), None))
        except ValueError as exc:
            msgs.append((n, None, str(exc)))
    return msgs


def cmd_check(path):
    schema = load_schema()
    roles_schema = set(schema.get("$defs", {}).get("requester", {}).get("properties", {}).get("role", {}).get("enum") or [])
    roles_vocab = {k.split(".", 1)[1] for k in load_vocab("role")}
    if roles_schema != roles_vocab:
        raise NotMeasured(f"contrato incoerente: papéis do schema {sorted(roles_schema)} != do vocabulário {sorted(roles_vocab)}")
    validators = {"received": validator_for(schema, "received"), "reply": validator_for(schema, "reply")}
    acc, seen, received_ids, replies = [], {}, {}, []
    msgs = read_messages(path)
    if not msgs:
        raise NotMeasured(f"nenhuma mensagem em {path}: sem saída do adapter, nada a medir")
    for n, obj, err in msgs:
        where = f"{path}:{n}"
        if err is not None:
            out(where, "NAO-E-JSON", f"linha não é JSON: {err}", acc)
            continue
        if not isinstance(obj, dict):
            out(where, "FORMA", "a mensagem não é um objeto JSON", acc)
            continue
        kind = obj.get("kind")
        if kind == "message.received":
            v = validators["received"]
        elif kind == "message.reply":
            v = validators["reply"]
        else:
            out(where, "FORMA", f"kind desconhecido: {kind!r} (message.received ou message.reply)", acc)
            continue
        for p, kw, msg in schema_errors(v, obj):
            out(where, classify_schema_error(p, kw, msg), f"{p}: {msg}", acc)
        k2 = "received" if kind == "message.received" else "reply"
        check_timestamps(obj, k2, where, acc)
        check_ids(obj, k2, where, acc)
        if k2 == "reply":
            check_role(obj.get("on_behalf_of"), obj.get("provider"), "on_behalf_of", where, acc)
        if kind == "message.received":
            check_received(obj, where, acc, seen, received_ids)
        else:
            check_reply(obj, where, acc)
            replies.append((where, obj))
    if received_ids:
        for where, obj in replies:
            evs = received_ids.get((obj.get("provider"), obj.get("in_reply_to"))) or []
            # o mesmo id do provedor pode existir em dois lugares (a dedupe é por lugar): vale o do lugar da resposta
            ev = next((e for e in evs if dig(e, ("place", "id")) == dig(obj, ("place", "id"))), evs[0] if evs else None)
            if ev is None:
                out(where, "FIO", "in_reply_to não aponta para nenhuma mensagem recebida neste fluxo", acc)
            else:
                check_reply_against(obj, ev, where, acc)
    return acc


def load_vocab(kind="capability"):
    """kind=capability: verbos e regras (o que o adapter declara) · kind=role: o vocabulário fechado de papel."""
    try:
        rows = open(VOCAB_PATH, encoding="utf-8").read().splitlines()
    except OSError as exc:
        raise NotMeasured(f"vocabulário ilegível: {exc}")
    vocab = {}
    for line in rows:
        if not line.strip() or line.startswith("#") or line.startswith("capability\t"):
            continue
        cols = line.split("\t")
        if len(cols) < 3:
            raise NotMeasured(f"vocabulário malformado: {line!r}")
        if (cols[1] == "role") == (kind == "role"):
            vocab[cols[0]] = (cols[1], cols[2])
    if not vocab:
        raise NotMeasured("vocabulário vazio")
    return vocab


def cmd_capabilities(path, strict=False):
    vocab = load_vocab()
    if not os.path.isfile(path):
        raise NotMeasured(f"declaração ausente: {path}")
    lines = open(path, encoding="utf-8").read().splitlines()
    acc, declared, header, done = [], {}, False, []
    for n, line in enumerate(lines, 1):
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        if cols[0] == "capability":
            header = True
            continue
        where = f"{path}:{n}"
        if len(cols) < 5:
            out(where, "FORMA", "linha com menos de 5 colunas (capability, requirement, status, api_version, source[, note])", acc)
            continue
        cap, requirement, status, _api, source = cols[:5]
        if cap in declared:
            out(where, "REPETIDA", f"{cap} já declarada na linha {declared[cap]}", acc)
            continue
        declared[cap] = n
        if cap not in vocab:
            out(where, "FORA-DO-VOCABULARIO", f"{cap} não existe em vocabulary.tsv", acc)
            continue
        if requirement != vocab[cap][1]:
            out(where, "REQUISITO", f"{cap}: requirement {requirement!r}, o contrato diz {vocab[cap][1]!r}", acc)
        if status not in STATUSES:
            out(where, "STATUS", f"{cap}: status {status!r} fora de {'|'.join(STATUSES)}", acc)
        elif status in ("implemented", "partial") and source.strip() in ("", "-"):
            out(where, "SEM-FONTE", f"{cap}: {status} sem fonte (onde se mede na peça)", acc)
        if vocab[cap][1] == "required":
            if status == "implemented":
                done.append(cap)
            elif strict:
                out(where, "OBRIGATORIA-FALTANDO", f"{cap}: required e {status}", acc)
    if not header:
        out(path, "FORMA", "sem a linha de cabeçalho «capability…»", acc)
    for cap in vocab:
        if cap not in declared:
            out(path, "AUSENTE", f"{cap} não declarada (todo o vocabulário se declara, até o que falta)", acc)
    n_req = sum(1 for k, r in vocab.values() if r == "required")
    print(f"chat-conformance: o adapter declara {len(done)} de {n_req} capacidades obrigatórias implementadas", file=sys.stderr)
    return acc


def main(argv):
    if argv == ["--vocabulary"]:
        try:
            for cap, (kind, req) in load_vocab().items():
                print(f"{cap}\t{kind}\t{req}")
            return 0
        except NotMeasured as exc:
            print(f"chat-conformance: não medi: {exc}", file=sys.stderr)
            return 2
    strict = argv[2:] == ["--strict"] and argv[:1] == ["capabilities"]
    if not (len(argv) == 2 or strict) or argv[0] not in ("check", "capabilities"):
        print("uso: conformance.py check <arquivo|-> | capabilities <tsv> [--strict] | --vocabulary", file=sys.stderr)
        return 2
    try:
        acc = cmd_check(argv[1]) if argv[0] == "check" else cmd_capabilities(argv[1], strict)
    except NotMeasured as exc:
        print(f"chat-conformance: não medi: {exc}", file=sys.stderr)
        return 2
    for where, code, msg in acc:
        print(f"VIOLA\t{where}\t{code}\t{msg}")
    if acc:
        print(f"chat-conformance: {len(acc)} violação(ões) do contrato onion.chat/v1", file=sys.stderr)
        return 1
    if argv[0] == "capabilities" and not strict:
        print("chat-conformance: declaração conforme ao vocabulário onion.chat/v1 (o veredito do adapter é o --strict)", file=sys.stderr)
    else:
        print("chat-conformance: conforme ao contrato onion.chat/v1", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
