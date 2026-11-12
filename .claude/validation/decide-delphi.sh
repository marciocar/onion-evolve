#!/usr/bin/env bash
# ===========================================================================
# decide-delphi.sh — o ESTADO e o MEDIDOR do modo Delphi do /meta:decide (cláusula 11 da decide-doctrine).
#
# Por que existe (D_FORGE_DELPHI_MODE_IN_DECIDE_1111, maestro, 2026-11-11): três decisões do maestro de 2026-11-11 e
# 12 dependiam do domínio de outras sessões (o vigia de eventos, o serviço Onion na VPS, uma migração que toca dívida
# antiga), e as três rodaram com a mesma forma: posição independente, crítica cruzada SEM o autor, convergência com o
# dissenso declarado e só então a pergunta ao maestro. A forma vivia na memória de quem conduzia; aqui ela vira estado
# conferível. Este script NÃO conduz a conversa, NÃO chama sessão e NÃO usa IA: ele guarda as respostas que a sessão
# condutora recebeu, as reexibe sem autor e recusa a síntese que esconde quem não respondeu ou quem objetou.
#
# ── O ESTADO (fora do git) ────────────────────────────────────────────────────────────────────
#   ${ONION_DELPHI_DIR:-${XDG_STATE_HOME:-~/.local/state}/onion/delphi}/<id>.json, diretório 700 e arquivo 600, escrita
#   atômica (tmp + rename) sob trava (flock no <id>.lock): duas sessões gravando juntas não se sobrescrevem.
#   O sal do embaralhamento nasce no `open` (aleatório; ONION_DELPHI_SALT fixa, DECLARADO em stderr) e fica no estado:
#   a ordem é estável para o mesmo id, e quem só conhece o id e os nomes não a recalcula para achar o autor.
#
# ── OS SUBCOMANDOS ────────────────────────────────────────────────────────────────────────────
#   open <id> --question "<pergunta>" --participants a,b,c
#   record <id> --round 1|2|3 --from <p> --file <resposta> [--confidence 0..1] [--stance accept|object] [--replace]
#       rodada 2 só depois do `anon` da rodada 1 (ninguém critica o que não viu sem autor); rodada 3 só com a síntese
#       proposta (`propose`) e o `anon` da rodada 2, e exige --stance. A confiança vem de --confidence ou da linha
#       "confiança: 0.N" da resposta; ausente, fica "não declarada" (nunca inventada). Rodada 1 com mais de 15 linhas
#       é AVISO nomeado (a forma pede até 15), não recusa.
#   propose <id> --file <síntese> [--replace]   a síntese que o condutor leva à rodada 3; trocar depois de alguém já ter
#       aceito ou objetado na rodada 3 é recusado (o aceite seria de outro texto).
#   anon <id> --round N [--partial]   as posições da rodada SEM autor (Posição A, B, …), em ordem embaralhada determinística, cada
#       uma dentro da cerca R15.2 (nonce + `<<<`/`>>>` desarmados): é o que vai às sessões na rodada seguinte. Rodada
#       incompleta só sai com --partial (declarado); quem responde DEPOIS do anon da rodada fica marcado tardia.
#   status <id>              quem respondeu, quem FALTA (nomeado), a confiança por rodada, a síntese e os anon emitidos.
#   synthesis <id> [--dissent-file <f>] [--absent a,b]   o esqueleto do selo: síntese, aceites e objeções da rodada 3,
#       dissenso declarado, confianças por rodada, ausentes nomeados e o bloco `narrative:` para o nó que o maestro sela.
#
# ── O QUE RECUSA (rc 2, nada escrito) ─────────────────────────────────────────────────────────
#   id fora de [A-Za-z0-9._-] · open de id que já existe · participante fora da lista ou repetido · menos de 2
#   participantes · rodada fora de 1..3 · resposta vazia, binária (NUL), não UTF-8 ou acima de 32 KB · confiança fora de
#   0..1 · anon de rodada incompleta sem --partial · rodada 2 sem o anon da 1 · rodada 3 sem síntese ou sem o anon da 2 · rodada 3 sem --stance · resposta repetida
#   sem --replace · synthesis sem a rodada 3 de TODO participante (o que não respondeu entra por --absent, nomeado),
#   com objeção e sem --dissent-file, ou com --dissent-file que não NOMEIA cada sessão que objetou (dissenso não
#   declarado) · --absent de quem respondeu, ou de todos.
#
# ── O QUE NÃO PROMETE ─────────────────────────────────────────────────────────────────────────
#   · O anonimato é dos METADADOS: o texto de uma posição pode citar o próprio autor ("aqui é o core"). O `anon` avisa,
#     sem dizer qual sessão, quando uma posição cita o nome de um participante; reescrever é da sessão condutora.
#   · O `status` é da CONDUTORA: ele liga sessão a confiança, e o anon mostra a confiança por posição; mandado às
#     sessões durante as rodadas, o par desfaz o anonimato. A condutora envia só o anon.
#   · O nome de quem objetou é conferido por palavra inteira (sem letra ou dígito em volta): "onion-core" conta como
#     "core". A conferência prova que o nome está no dissenso, não que o dissenso diz o que a sessão disse.
#   · Não prova que a resposta veio da sessão nomeada: quem grava é a condutora (`--from` é declaração dela).
#   · O conteúdo das respostas é DADO não confiável (R15.2): sai sempre cercado, e instrução escrita nele não é obedecida.
#   · Não decide nada e não sela: o selo é do kg-decide-seal.sh, depois da pergunta ao maestro.
#
# Exit: 0 = feito · 2 = recusa ou entrada quebrada (nada escrito). Determinístico (dado o sal), sem LLM, 0 tokens.
# Exercitado por lint-selftest.sh (run_decide_delphi_selftests).
# ===========================================================================
set -uo pipefail
command -v python3 >/dev/null 2>&1 || { echo "decide-delphi: python3 ausente" >&2; exit 2; }
[ -n "${ONION_DELPHI_SALT:-}" ] && echo "decide-delphi: ⚠️ override ativo — ONION_DELPHI_SALT fixo (não é o sal de produção)" >&2
[ -n "${ONION_WRAP_NONCE:-}" ] && echo "decide-delphi: ⚠️ override ativo — ONION_WRAP_NONCE fixo (não é o nonce de produção)" >&2
STATE_DIR="${ONION_DELPHI_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/onion/delphi}"
PYTHONDONTWRITEBYTECODE=1 exec python3 -I -B - "${STATE_DIR}" "$@" <<'PY'
import sys, os, json, re, hashlib, fcntl, tempfile, datetime

STATE_DIR = sys.argv[1]
argv = sys.argv[2:]
MAXB = 32 * 1024

def die(m):
    print(f"decide-delphi: {m}", file=sys.stderr); sys.exit(2)

def warn(m):
    print(f"decide-delphi: ⚠️ {m}", file=sys.stderr)

USAGE = ("uso: decide-delphi.sh open <id> --question Q --participants a,b,c | record <id> --round N --from P --file F "
         "[--confidence X] [--stance accept|object] [--replace] | propose <id> --file F [--replace] | anon <id> --round N "
         "| status <id> | synthesis <id> [--dissent-file F] [--absent a,b]")
if not argv or argv[0] in ("-h", "--help"):
    print(USAGE); sys.exit(0 if argv else 2)
mode = argv[0]
if mode not in ("open", "record", "propose", "anon", "status", "synthesis"):
    die(f"subcomando desconhecido: {mode}\n{USAGE}")
if len(argv) < 2 or argv[1].startswith("--"):
    die(f"{mode} exige o <id>")
did = argv[1]
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,79}", did):
    die(f"id inválido ({did!r}): só [A-Za-z0-9._-], até 80, começando por letra ou dígito")

FLAGS = {"--question", "--participants", "--round", "--from", "--file", "--confidence", "--stance",
         "--dissent-file", "--absent"}
BOOL = {"--replace", "--partial"}
opt = {}
i = 2
while i < len(argv):
    a = argv[i]
    if a in BOOL:
        opt[a] = True; i += 1; continue
    if a in FLAGS:
        if i + 1 >= len(argv) or argv[i + 1] == "":
            die(f"{a} exige um valor")
        opt[a] = argv[i + 1]; i += 2; continue
    die(f"argumento desconhecido: {a}")

path = os.path.join(STATE_DIR, did + ".json")
lockp = os.path.join(STATE_DIR, did + ".lock")

def ensure_dir():
    os.makedirs(STATE_DIR, mode=0o700, exist_ok=True)
    try: os.chmod(STATE_DIR, 0o700)
    except OSError: pass

def load():
    if not os.path.isfile(path):
        die(f"Delphi {did} não existe em {STATE_DIR} (rode open primeiro)")
    try:
        with open(path, encoding="utf-8") as f: st = json.load(f)
    except (OSError, ValueError) as e:
        die(f"estado ilegível ({path}): {e}")
    if not isinstance(st, dict) or st.get("id") != did or not isinstance(st.get("participants"), list):
        die(f"estado com forma inesperada: {path}")
    return st

def save(st):
    fd, tmp = tempfile.mkstemp(dir=STATE_DIR, prefix="." + did + ".", suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(st, f, ensure_ascii=False, indent=1, sort_keys=True); f.write("\n")
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)

def read_text(p, what):
    if not os.path.isfile(p): die(f"{what}: arquivo inexistente: {p}")
    with open(p, "rb") as f: b = f.read(MAXB + 1)
    if len(b) > MAXB: die(f"{what}: acima de {MAXB} bytes ({p})")
    if b"\x00" in b: die(f"{what}: binário (NUL) — só texto ({p})")
    try: t = b.decode("utf-8")
    except UnicodeDecodeError: die(f"{what}: não é UTF-8 ({p})")
    if not t.strip(): die(f"{what}: vazio ({p})")
    return t.rstrip("\n")

def parse_conf(s, what):
    try: c = float(s)
    except ValueError: die(f"{what}: confiança não numérica ({s!r})")
    if not (0.0 <= c <= 1.0): die(f"{what}: confiança fora de 0..1 ({s})")
    return round(c, 3)

CONF_RE = re.compile(r"(?im)^\W*confian[cç]a\W*[:=]?\s*([01](?:[.,]\d+)?)\b")

def nonce():
    n = os.environ.get("ONION_WRAP_NONCE") or os.urandom(8).hex()
    return re.sub(r"[^A-Za-z0-9]", "", n) or os.urandom(8).hex()

def defang(t):
    return t.replace("<<<", "‹‹‹").replace(">>>", "›››")

def fence(origin, body):
    n = nonce()
    o = re.sub(r"[^A-Za-z0-9._/-]", "", origin)
    return (f"<<<UNTRUSTED origin=\"{o}\" channel=\"delphi-round\" verified-crypto=\"false\" verified-semantic=\"false\" nonce=\"{n}\">>>\n"
            f"{defang(body)}\n<<<END UNTRUSTED nonce=\"{n}\">>>")

def rnd(st, r):
    return st.setdefault("rounds", {}).setdefault(str(r), {})

def order(st, r):
    # ordem embaralhada determinística: sha256(sal|id|rodada|participante); o sal mora no estado, não no id
    got = rnd(st, r)
    return sorted(got, key=lambda p: hashlib.sha256(f"{st['salt']}|{did}|{r}|{p}".encode()).hexdigest())

def lettr(k):
    s = ""; k += 1
    while k: k, m = divmod(k - 1, 26); s = chr(65 + m) + s
    return s

def get_round():
    if "--round" not in opt: die(f"{mode} exige --round 1|2|3")
    if opt["--round"] not in ("1", "2", "3"): die(f"--round fora de 1..3 ({opt['--round']})")
    return int(opt["--round"])

os.umask(0o077)
ensure_dir()
lockf = open(lockp, "a")
fcntl.flock(lockf, fcntl.LOCK_EX)

if mode == "open":
    if os.path.exists(path): die(f"Delphi {did} já existe ({path}): um id por consulta")
    q = opt.get("--question", "").strip()
    if not q: die("open exige --question")
    ps = [p.strip() for p in opt.get("--participants", "").split(",") if p.strip()]
    if len(ps) < 2: die("open exige --participants com ao menos 2 sessões (a,b,…)")
    if len(set(ps)) != len(ps): die("participante repetido em --participants")
    for p in ps:
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", p): die(f"participante inválido: {p!r}")
    salt = os.environ.get("ONION_DELPHI_SALT") or os.urandom(16).hex()
    st = {"id": did, "question": q, "participants": ps, "salt": salt,
          "opened": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
          "rounds": {"1": {}, "2": {}, "3": {}}, "anon_emitted": [], "proposal": None}
    save(st)
    print(f"decide-delphi: aberto {did} · {len(ps)} participantes: {', '.join(ps)}")
    print(f"  estado: {path}")
    sys.exit(0)

st = load()
ps = st["participants"]

if mode == "record":
    r = get_round()
    p = opt.get("--from", "")
    if p not in ps: die(f"--from {p!r} não é participante deste Delphi ({', '.join(ps)})")
    if "--file" not in opt: die("record exige --file <resposta>")
    if r >= 2 and (r - 1) not in st.get("anon_emitted", []):
        die(f"rodada {r} antes do anon da rodada {r-1}: a crítica cruzada é sobre as posições SEM autor (rode anon {did} --round {r-1})")
    if r == 3 and not st.get("proposal"):
        die("rodada 3 sem síntese proposta: rode propose primeiro (a convergência é sobre um texto)")
    stance = opt.get("--stance")
    if r == 3:
        if stance not in ("accept", "object"): die("rodada 3 exige --stance accept|object")
    elif stance is not None:
        die("--stance só vale na rodada 3")
    got = rnd(st, r)
    if p in got and not opt.get("--replace"):
        die(f"{p} já respondeu a rodada {r} (use --replace para trocar, declarado)")
    text = read_text(opt["--file"], f"resposta de {p}")
    if "--confidence" in opt:
        conf = parse_conf(opt["--confidence"], f"resposta de {p}")
    else:
        m = CONF_RE.search(text)
        conf = parse_conf(m.group(1).replace(",", "."), f"resposta de {p}") if m else None
    lines = len(text.splitlines())
    if r == 1 and lines > 15:
        warn(f"rodada 1 de {p} com {lines} linhas (a forma pede até 15)")
    ent = {"text": text, "confidence": conf, "sha256": hashlib.sha256(text.encode()).hexdigest()}
    if r == 3: ent["stance"] = stance
    if p in got: ent["replaced"] = True; warn(f"{p} trocou a resposta da rodada {r} (--replace)")
    if r in st.get("anon_emitted", []):
        ent["late"] = True
        warn(f"{p} respondeu a rodada {r} DEPOIS do anon dela: a posição pode não ser independente (marcada tardia no status e na síntese)")
    got[p] = ent
    save(st)
    falta = [x for x in ps if x not in got]
    print(f"decide-delphi: {did} rodada {r} · gravada a resposta de {p} · confiança {conf if conf is not None else 'não declarada'}"
          + (f" · posição {stance}" if r == 3 else ""))
    print(f"  falta na rodada {r}: {', '.join(falta) if falta else 'ninguém'}")
    sys.exit(0)

if mode == "propose":
    if "--file" not in opt: die("propose exige --file <síntese>")
    if not rnd(st, 2): die("síntese antes da rodada 2: a convergência vem depois da crítica cruzada")
    if st.get("proposal") and not opt.get("--replace"): die("já há síntese proposta (use --replace)")
    if st.get("proposal") and rnd(st, 3): die("a rodada 3 já tem respostas sobre a síntese atual: trocá-la invalidaria os aceites (abra outro Delphi)")
    text = read_text(opt["--file"], "síntese")
    st["proposal"] = {"text": text, "sha256": hashlib.sha256(text.encode()).hexdigest()}
    save(st)
    print(f"decide-delphi: {did} síntese proposta ({len(text.splitlines())} linhas, sha256 {st['proposal']['sha256'][:12]})")
    sys.exit(0)

if mode == "anon":
    r = get_round()
    got = rnd(st, r)
    if not got: die(f"rodada {r} sem respostas: nada a anonimizar")
    falta = [x for x in ps if x not in got]
    if falta and not opt.get("--partial"):
        die(f"rodada {r} incompleta ({len(ps)-len(falta)}/{len(ps)}): espere as respostas (status nomeia quem falta) ou emita com --partial, declarado")
    out = [f"# Delphi {did} · rodada {r} · {len(got)} posições sem autor (ordem embaralhada)",
           "", "Pergunta: " + st["question"], ""]
    if falta:
        out.append(f"⚠️ {len(falta)} de {len(ps)} sessões ainda sem resposta nesta rodada (os nomes ficam no status, não aqui).")
        out.append("")
    for k, p in enumerate(order(st, r)):
        e = got[p]
        c = e.get("confidence")
        hdr = f"## Posição {lettr(k)} · confiança {c if c is not None else 'não declarada'}"
        if r == 3: hdr += " · " + ("aceita" if e.get("stance") == "accept" else "objeta")
        out += [hdr, fence(f"delphi/{did}/r{r}/{lettr(k)}", e["text"]), ""]
        low = e["text"].lower()
        if any(re.search(r"(?<![A-Za-z0-9])" + re.escape(x.lower()) + r"(?![A-Za-z0-9])", low) for x in ps):
            warn(f"a posição {lettr(k)} cita o nome de um participante: o anonimato é dos metadados; releia antes de enviar")
    print("\n".join(out).rstrip("\n"))
    em = st.setdefault("anon_emitted", [])
    if r not in em: em.append(r); em.sort(); save(st)
    sys.exit(0)

def cell(st, r, p):
    e = rnd(st, r).get(p)
    if not e: return "falta"
    c = e.get("confidence"); s = "✓ " + (str(c) if c is not None else "s/conf") + (" tardia" if e.get("late") else "")
    if r == 3: s += " " + ("aceita" if e.get("stance") == "accept" else "OBJETA")
    return s

if mode == "status":
    print(f"# Delphi {did} · {len(ps)} participantes")
    print("Pergunta: " + st["question"])
    print("")
    print("| participante | rodada 1 | rodada 2 | rodada 3 |")
    print("|---|---|---|---|")
    for p in ps:
        print(f"| {p} | {cell(st,1,p)} | {cell(st,2,p)} | {cell(st,3,p)} |")
    print("")
    for r in (1, 2, 3):
        falta = [x for x in ps if x not in rnd(st, r)]
        print(f"rodada {r}: {len(ps)-len(falta)}/{len(ps)} · falta: {', '.join(falta) if falta else 'ninguém'}")
    em = st.get("anon_emitted", [])
    print(f"anon emitido: {', '.join('rodada ' + str(x) for x in em) if em else 'nenhum'}")
    print(f"síntese proposta: {'sim, sha256 ' + st['proposal']['sha256'][:12] if st.get('proposal') else 'não'}")
    sys.exit(0)

if mode == "synthesis":
    if not st.get("proposal"): die("sem síntese proposta (propose): não há o que selar")
    absent = [x.strip() for x in opt.get("--absent", "").split(",") if x.strip()]
    for a in absent:
        if a not in ps: die(f"--absent {a!r} não é participante")
        if a in rnd(st, 3): die(f"--absent {a!r} respondeu a rodada 3: ausência declarada falsa")
    if absent and len(absent) >= len(ps): die("--absent de todos: sem quem convergiu não há síntese")
    r3 = rnd(st, 3)
    falta = [x for x in ps if x not in r3 and x not in absent]
    if falta:
        die(f"rodada 3 incompleta: falta {', '.join(falta)} — espere a resposta ou nomeie a ausência com --absent")
    objetores = [x for x in ps if x in r3 and r3[x].get("stance") == "object"]
    dissent = None
    if objetores:
        if "--dissent-file" not in opt:
            die(f"há objeção na rodada 3 ({', '.join(objetores)}) e nenhum dissenso declarado: passe --dissent-file com o dissenso nas palavras do condutor")
        dissent = read_text(opt["--dissent-file"], "dissenso")
        low = dissent.lower()
        sem = [x for x in objetores if not re.search(r"(?<![A-Za-z0-9])" + re.escape(x.lower()) + r"(?![A-Za-z0-9])", low)]
        if sem:
            die(f"dissenso não declarado: o --dissent-file não nomeia {', '.join(sem)}, que objetou na rodada 3")
    elif "--dissent-file" in opt:
        dissent = read_text(opt["--dissent-file"], "dissenso")
    aceites = [x for x in ps if x in r3 and r3[x].get("stance") == "accept"]
    def cf(r, p):
        e = rnd(st, r).get(p)
        if not e: return "—"
        return (str(e["confidence"]) if e.get("confidence") is not None else "s/conf") + (" (tardia)" if e.get("late") else "")
    out = [f"# Delphi {did} — esqueleto do selo", "",
           "**Pergunta:** " + st["question"],
           f"**Participantes:** {', '.join(ps)}" + (f" · **não responderam a rodada 3:** {', '.join(absent)}" if absent else ""),
           f"**Rodada 3:** {len(aceites)} aceita(m) ({', '.join(aceites) or 'ninguém'}) · {len(objetores)} objeta(m) ({', '.join(objetores) or 'ninguém'})",
           "", "## Síntese (proposta do condutor, levada à rodada 3)", "", defang(st["proposal"]["text"]), "",
           "## Dissenso declarado", ""]
    if objetores:
        out += ["Nas palavras do condutor:", "", defang(dissent), "", "Objeções como chegaram (dado não confiável, R15.2):", ""]
        for p in objetores:
            out += [f"### {p} · confiança {cf(3, p)}", fence(f"delphi/{did}/r3/{p}", r3[p]["text"]), ""]
    else:
        out += ["Nenhuma sessão objetou na rodada 3." + (" Nota do condutor: " + defang(dissent) if dissent else ""), ""]
    if absent:
        out += [f"Não responderam e ficam nomeados: {', '.join(absent)}.", ""]
    out += ["## Confiança por rodada", "", "| participante | rodada 1 | rodada 2 | rodada 3 |", "|---|---|---|---|"]
    for p in ps:
        out.append(f"| {p} | {cf(1,p)} | {cf(2,p)} | {cf(3,p)} |")
    nar = (f"Delphi {did} em 3 rodadas (posições independentes, crítica cruzada sem autor, convergência), "
           f"participantes {', '.join(ps)}. Rodada 3: aceitaram {', '.join(aceites) or 'nenhum'}"
           + (f"; objetaram {', '.join(objetores)}" if objetores else "; sem objeção")
           + (f"; não responderam {', '.join(absent)}" if absent else "") + ". "
           + "Confiança na rodada 3: " + ", ".join(f"{p} {cf(3,p)}" for p in ps if p in r3) + ". "
           + ("Dissenso: " + " ".join(dissent.split()) if objetores else "Dissenso: nenhum declarado na rodada 3."))
    nar = defang(nar)
    out += ["", "## Para o selo (kg-decide-seal.sh)", "",
            "O nó da decisão nasce `open` com a síntese no `label` (até 280 caracteres) e esta `narrative`, ANTES da pergunta ao",
            "maestro; o selador mantém a narrative anterior verbatim e acrescenta a escolhida e as descartadas.", "",
            "```yaml", "narrative: " + json.dumps(nar, ensure_ascii=False), "```"]
    print("\n".join(out))
    sys.exit(0)
PY
