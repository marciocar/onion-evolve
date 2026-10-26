#!/usr/bin/env bash
# =============================================================================
# house-code-gloss.sh — sigla da casa na prosa ao maestro vem com a glosa: LEMBRA antes, barra raro
#
# POR QUÊ : pedido do maestro (2026-10-17): "expressões que não lembro como aqui no r13, I3, ..." —
#           sobre a frase "Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13
#           pode medir". E o reforço do mesmo dia, que decide o desenho: "isso é para você escrever
#           certo e não para ficar travando toda hora". Por isso são DOIS modos, e o normal é o 1º:
#
#   prompt (UserPromptSubmit) — o caminho normal, ANTES de escrever: lê o último turno do assistente
#           que tem texto, acha as siglas que ele usou sem glosa e INJETA a glosa de cada uma (o
#           glossário só das siglas em uso). Grava no estado da sessão as de opacidade alta que LEMBROU.
#           Nunca barra.
#   stop   (Stop)             — a rede rara: barra (exit 2) só a sigla de opacidade ALTA que o lembrete
#           DESTE turno trouxe (o estado gravado pelo prompt, lido e apagado aqui) e que voltou sem glosa.
#           O estado só existe em turno que o maestro abriu (o UserPromptSubmit não dispara em aviso de
#           tarefa de fundo), e a sigla que o próprio maestro escreveu no pedido não barra. A taxa medida
#           em transcripts reais mora no grafo da forja (nó E_MEDIDA_TAXA_DE_BLOQUEIO_*), não aqui.
#   tool   (PreToolUse)       — o 3º caminho, nascido do reforço do maestro em 2026-10-26 ("nada de sigla opaca
#           na prosa"): a prosa que NÃO é a resposta ao maestro e que ele lê mesmo assim. São duas: a mensagem
#           entre sessões (SendMessage, campo `message`), que a outra sessão lê e repassa ao maestro, e os .md
#           de pré-registro e resultado de estudo (basename em CAIXA ALTA — STAGE0, SYNTHESIS, RESULT, N2-PLAN,
#           CORE-STATE, PROTOCOL, ELENXO… — sob docs/evolution/dissect/ ou docs/evolution/research/, exceto
#           README), escritos por Write/Edit. Devolve additionalContext com a glosa de cada sigla sem glosa.
#           SEMPRE exit 0: é lembrete, nunca bloqueio. O Edit é julgado pelo RESULTADO (o arquivo com a troca
#           aplicada), e só se cobra a sigla que aparece no trecho novo: a glosa que o arquivo já tem vale.
#           TETO: o PreToolUse não barra, então a mensagem/o arquivo segue como foi escrito; o lembrete
#           corrige a PRÓXIMA escrita (ou um Edit de cura), não a que disparou. Texto ou arquivo acima de
#           200 KB cala (o motor custa ~1 s a cada 100 KB). Edit cujo old_string não está no arquivo é
#           julgado só pelo trecho novo. Mensagem estruturada (objeto) e Bash que escreve .md não são lidos.
#
# COMO    : o glossário é .claude/validation/house-codes.tsv (fonte única; nada embutido aqui). O
#           que conta como glosa, o domínio de cada sigla e o que não é prosa (código, citação, caminho,
#           URL, "REGRA N (Título)") moram em lib/house_codes.py. A "resposta" é cada bloco de texto do
#           assistente: o maestro lê o bloco quando ele chega, e uma glosa três blocos depois chega tarde.
#           ONION_HOUSE_CODE_STOP escolhe a política do Stop: reincidence (padrão), alta (toda sigla de
#           opacidade alta sem glosa, já na 1ª vez) ou off (só o lembrete); valor fora disso vale off.
#           Estado: ONION_HOUSE_CODE_STATE_DIR (padrão: diretório de runtime do usuário).
#           Anti-loop: stop_hook_active=true → exit 0. Sem python3, sem glossário ou sem transcript:
#           exit 0 (a guarda erra para o lado de calar).
#
# USO     : registrado em .claude/settings.json (UserPromptSubmit com `prompt`, Stop com `stop`, PreToolUse
#           `SendMessage|Write|Edit` com `tool`).
#           --selftest prova as polaridades; --scan <transcript.jsonl> simula os dois modos em cada turno
#           de uma sessão real (dogfood; a taxa de bloqueio sai no fim).
# =============================================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAL="${HERE}/../validation"
GLOSSARY="${ONION_HOUSE_CODES_TSV:-${VAL}/house-codes.tsv}"
STATE_DIR="${ONION_HOUSE_CODE_STATE_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/onion-house-code-gloss-$(id -u)}"

_engine() {   # $1=modo (prompt|stop|scan|text|tool) · $2=transcript (ou, nos modos text e tool, o arquivo com o texto ou o payload do hook) · $3=sessão
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1" "${2:--}" "${HERE}" "${GLOSSARY}" "${VAL}/lint-artifacts.sh" "${VAL}/plugin-bundle-check.sh" "${3:-}" "${STATE_DIR}" <<'PY'
import hashlib, importlib.util, json, os, re, subprocess, sys
# sem bytecode em cache: o .pyc é validado por mtime em SEGUNDOS + tamanho, e uma edição do lib do mesmo
# tamanho no mesmo segundo roda o código VELHO (medido 2026-10-17: trocar n=8 por n=6 e voltar no mesmo
# segundo deixou o hook rodando n=6 com o fonte em n=8 — e um mutante assim parece não morder)
sys.dont_write_bytecode = True
mode, tp, here, gpath, lint, bundle, sid, sdir = sys.argv[1:9]
def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod); return mod
try:
    hc = _load("house_codes", os.path.join(here, "lib", "house_codes.py"))
except Exception:
    sys.exit(0)
try:
    tt = _load("transcript_tail", os.path.join(here, "lib", "transcript-tail.py"))
except Exception:
    tt = None
gl = hc.load_glossary(gpath)
if not gl:
    sys.exit(0)
titles = hc.rule_titles([lint, bundle])
root = os.environ.get("CLAUDE_PROJECT_DIR") or ""
if not root:
    try:
        root = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                              text=True, timeout=5).stdout.strip()
    except Exception:
        root = ""
POLICY = os.environ.get("ONION_HOUSE_CODE_STOP", "reincidence").strip().lower()
if POLICY not in ("reincidence", "alta", "off"):
    POLICY = "off"     # enum fechado: valor desconhecido nunca vira veto

def _msg(j):
    m = j.get("message")
    return m if isinstance(m, dict) else {}

def is_tool_result(j):
    c = _msg(j).get("content")
    return isinstance(c, list) and any(isinstance(x, dict) and x.get("type") == "tool_result" for x in c)

def is_turn_start(j):
    # o resumo de compactação NÃO abre turno: é continuação do turno em curso
    return (j.get("type") == "user" and not is_tool_result(j) and not j.get("isSidechain")
            and not j.get("isCompactSummary"))

def user_text(j):
    c = _msg(j).get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return "\n".join(x.get("text", "") for x in c if isinstance(x, dict) and x.get("type") == "text")
    return ""

_NOT_HUMAN = ("<task-notification", "Stop hook feedback", "<local-command", "<command-name>", "<command-message>",
              "<bash-input>", "<bash-stdout>", "<bash-stderr>", "<cross-session-message", "Another Claude session",
              "This session is being continued")

def is_human(j):
    o = j.get("origin")
    if isinstance(o, dict) and o.get("kind"):
        return o.get("kind") == "human"
    if j.get("isMeta") or j.get("isCompactSummary"):
        return False
    return not user_text(j).lstrip().startswith(_NOT_HUMAN)

def queued(j):
    """(é do maestro, texto) de uma mensagem que entrou EM FILA no meio do turno, ou None."""
    if j.get("type") != "attachment" or j.get("isSidechain"):
        return None
    a = j.get("attachment")
    if not isinstance(a, dict) or a.get("type") != "queued_command":
        return None
    o = a.get("origin")
    human = (o.get("kind") == "human") if isinstance(o, dict) and o.get("kind") else \
        not str(a.get("prompt", "")).lstrip().startswith(_NOT_HUMAN)
    return human, str(a.get("prompt", ""))

def blocks(j):
    if j.get("type") != "assistant" or j.get("isSidechain"):
        return []
    t = "\n".join(c.get("text", "") for c in _msg(j).get("content") or []
                  if isinstance(c, dict) and c.get("type") == "text")
    return [t] if t.strip() else []

def find(texts):
    # cada bloco é julgado por si, na ordem em que o maestro o lê: a glosa de um bloco ANTERIOR do
    # mesmo turno cobre os seguintes; a de um bloco POSTERIOR chega tarde e não cobre o anterior
    out, glossed = {}, set()
    for b in texts:
        for d in hc.findings(b, gl, titles, root, glossed_out=glossed, already=frozenset(glossed)):
            out.setdefault(d["token"], d)
    return sorted(out.values(), key=lambda d: (d["opacity"] != "alta", d["token"]))

def read_rows(path, pred=None):
    rows = None
    if pred is not None and tt is not None:
        rows = tt.tail_until(path, pred)
    if rows is None:
        rows = []
        for line in open(path, encoding="utf-8", errors="replace"):
            try: rows.append(json.loads(line))
            except Exception: pass
    return [j for j in rows if isinstance(j, dict)]

def turn_id(start):
    if start is None:
        return "bof"
    u = start.get("uuid")
    return str(u) if u else hashlib.sha256(json.dumps(start, sort_keys=True).encode()).hexdigest()[:16]

def split_turns(rows):
    """[{start, blocks, human, asks}] na ordem; human = aberto pelo maestro ou com mensagem dele em fila;
    asks = o texto do que o maestro escreveu no turno (pedido + mensagens em fila)."""
    turns, cur = [], None
    for j in rows:
        if is_turn_start(j):
            if cur is not None: turns.append(cur)
            h = is_human(j)
            cur = {"start": j, "blocks": [], "human": h, "asks": [user_text(j)] if h else []}
            continue
        if cur is None:
            cur = {"start": None, "blocks": [], "human": False, "asks": []}
        q = queued(j)
        if q is not None and q[0]:
            cur["human"] = True
            cur["asks"].append(q[1])
        cur["blocks"].extend(blocks(j))
    if cur is not None: turns.append(cur)
    return turns

def last_turns(path, n):
    state = {"seen": 0}
    def pred(j):
        if isinstance(j, dict) and is_turn_start(j):
            state["seen"] += 1
            return state["seen"] >= n
        return False
    ts = split_turns(read_rows(path, pred))
    # o caminho lento do transcript-tail reaplica o pred, com estado, lendo para frente: ele pode devolver
    # menos turnos do que pedimos. Faltou turno com o arquivo maior que o lido? relê inteiro e corta aqui.
    if len([t for t in ts if t["start"] is not None]) < n and tt is not None:
        ts = split_turns(read_rows(path))
    return ts[-n:]

def reminded(fs):
    return [d for d in fs if d["opacity"] == "alta"][:8]

def reminder(fs):
    hi = reminded(fs)
    lo = [d for d in fs if d["opacity"] != "alta"]
    if not fs:
        return ""
    lines = ["📖 Glossário da casa — siglas que a sua resposta usou SEM glosa até aqui. Ao maestro, "
             "escreva a sigla com a glosa na 1ª menção de cada bloco (ex.: \"I3 (um escritor por repo)\") "
             "ou troque a sigla pela glosa. Repetir sem glosa as de opacidade alta abaixo barra o fim do turno:"]
    for d in hi:
        lines.append("  · %s → %s" % (d["token"], d["gloss"]))
    if lo:
        lines.append("  · também sem glosa (não barra): " + "; ".join(
            "%s → %s" % (d["token"], d["gloss"]) for d in lo[:5]))
    return "\n".join(lines)

def _state_dir_ok():
    """O diretório de estado é NOSSO e fechado (dono = uid, sem permissão de grupo/outros, não é link)."""
    try:
        os.makedirs(sdir, mode=0o700, exist_ok=True)
        st = os.lstat(sdir)
        import stat as _st
        return _st.S_ISDIR(st.st_mode) and st.st_uid == os.getuid() and (st.st_mode & 0o077) == 0
    except Exception:
        return False

def state_path():
    key = sid or hashlib.sha256(tp.encode("utf-8", "replace")).hexdigest()[:16]
    key = re.sub(r"[^A-Za-z0-9_.-]", "_", key)
    return os.path.join(sdir, key + ".tsv")

def state_read(consume):
    """(marca, [(token, row, kind)]). Marca = (id do turno, nº de blocos já escritos quando lembrou)."""
    if not _state_dir_ok():
        return None, []
    p = state_path()
    try:
        fd = os.open(p, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
        with os.fdopen(fd, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
        if consume:
            os.remove(p)      # o lembrete vale para UM turno: lido, consumido
    except Exception:
        return None, []
    mark, rows = None, []
    for l in lines:
        c = l.split("\t")
        if c[0] == "#mark" and len(c) >= 3 and c[2].isdigit():
            mark = (c[1], int(c[2]))
        elif len(c) >= 3 and c[0]:
            rows.append(tuple(c[:3]))
    return mark, rows

def state_write(mark, rows):
    if not _state_dir_ok():
        return
    try:
        fd = os.open(state_path(), os.O_WRONLY | os.O_CREAT | os.O_TRUNC | getattr(os, "O_NOFOLLOW", 0), 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write("#mark\t%s\t%d\n" % mark)
            for r in rows:
                fh.write("%s\t%s\t%s\n" % r)
    except Exception:
        pass

def asked_codes(turn):
    """As siglas que o próprio maestro escreveu no turno (pedido ou mensagem em fila): ele as conhece."""
    t = "\n".join(turn["asks"]) if turn else ""
    return {m.group(0) for row in gl for m in row["rx"].finditer(t)}

def blockers(cur, state, exempt, policy=None):
    """state = [(token, row, kind)] lembrados neste turno. reincidence: alta lembrada (o mesmo token, ou a
    mesma linha estática do glossário: lembrado r12, a r13 também) que voltou sem glosa;
    alta: toda sigla de opacidade alta sem glosa; off: nunca."""
    policy = policy or POLICY
    if policy == "off":
        return []
    hi = [d for d in cur if d["opacity"] == "alta" and d["token"] not in exempt]
    if policy == "alta":
        return hi
    toks = {t for t, _, _ in state}
    rows = {r for _, r, k in state if k in ("static", "term")}   # term: a linha é o esquema (r12 lembrada, r13 reincide)
    return [d for d in hi if d["token"] in toks or (d["kind"] in ("static", "term") and d["row"] in rows)]

if mode == "text":
    for d in find([open(tp, encoding="utf-8", errors="replace").read()]):
        print("%s|%s|%s|%s" % (d["token"], d["opacity"], d["row"], d["gloss"]))
    sys.exit(0)

# o .md de estudo que a outra sessão e o maestro leem: pré-registro e resultado (medido em 2026-10-26 no
# acervo de dissecação e pesquisa: STAGE0, SYNTHESIS, RESULT, *-PLAN, CORE-STATE, PROTOCOL, ELENXO,
# SIGNAL-DRAFT, ACCEPT-*, BRIEF-* — todos prosa de estudo, todos em CAIXA ALTA; o README é índice)
PREREG = re.compile(r"(?:^|/)docs/evolution/(?:dissect|research)/(?:[^/]+/)+([A-Z0-9][A-Z0-9_-]*)\.md$")

CAP = 200000   # bytes: acima disto o PreToolUse sai calado (o motor custa ~1 s a cada 100 KB; medido 2026-10-26)

def tool_target(d):
    """(onde, texto como fica DEPOIS da chamada, [trechos novos]) ou None se a chamada não é prosa vigiada.
    O julgamento é do RESULTADO (a glosa que o arquivo já tem vale), e só se cobra a sigla dos trechos novos."""
    name = d.get("tool_name")
    ti = d.get("tool_input")
    if not isinstance(ti, dict):
        return None
    if name == "SendMessage":
        m = ti.get("message")
        if not isinstance(m, str) or not m.strip():
            return None            # mensagem estruturada (objeto) não é prosa
        to = ti.get("to")
        return ("a mensagem a outra sessão (SendMessage%s)" % (" para %s" % to if isinstance(to, str) and to else ""),
                m, [m])
    if name not in ("Write", "Edit"):
        return None
    fp = ti.get("file_path")
    mt = PREREG.search(fp) if isinstance(fp, str) else None
    if not mt or mt.group(1) == "README":
        return None
    where = "o .md de estudo %s" % os.path.basename(fp)
    if name == "Write":
        c = ti.get("content")
        return (where, c, [c]) if isinstance(c, str) else None
    new, old = ti.get("new_string"), ti.get("old_string")
    if not isinstance(new, str):
        return None
    full = new
    try:
        if os.path.isfile(fp) and os.path.getsize(fp) <= CAP and isinstance(old, str) and old:
            prior = open(fp, encoding="utf-8", errors="replace").read()
            if old in prior:
                full = prior.replace(old, new) if ti.get("replace_all") is True else prior.replace(old, new, 1)
    except Exception:
        full = new
    return (where, full, [new])

if mode == "tool":
    try:
        d = json.load(open(tp, encoding="utf-8", errors="replace"))
    except Exception:
        sys.exit(0)
    tg = tool_target(d) if isinstance(d, dict) else None
    if not tg or not tg[2] or len(tg[1]) > CAP:
        sys.exit(0)
    where, full, news = tg
    def _in_new(tok):
        rx = re.compile(r"(?<![\w-])%s(?![\w-])" % re.escape(tok))
        return any(rx.search(n) for n in news)
    fs = sorted((x for x in hc.findings(full, gl, titles, root) if _in_new(x["token"])),
                key=lambda x: (x["opacity"] != "alta", x["token"]))
    if not fs:
        sys.exit(0)
    lines = ["📖 Glossário da casa — %s leva sigla SEM glosa, e quem a lê repassa ao maestro. Glose na 1ª "
             "menção (ex.: \"a tarefa do pré-registro (SAC-256)\", \"I3 (um escritor por repo)\") ou troque a "
             "sigla pela glosa; se já foi, corrija na próxima escrita. Lembrete, não bloqueio:" % where]
    for x in fs[:10]:
        lines.append("  · %s → %s" % (x["token"], x["gloss"]))
    # bytes com errors="replace": o destinatário vem do payload, e um surrogate solto quebrava o print com
    # Traceback (Elenxo 2026-10-26); o JSON segue legível em UTF-8, o surrogate vira "?"
    out = json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                             "additionalContext": "\n".join(lines)}}, ensure_ascii=False)
    sys.stdout.buffer.write(out.encode("utf-8", "replace") + b"\n")
    sys.exit(0)

if not tp or tp == "-" or not os.path.isfile(tp):
    sys.exit(0)

if mode == "prompt":
    # Dois momentos, o mesmo código: no INÍCIO de turno o último turno do transcript ainda é o anterior
    # (ou o novo, só com o pedido); no MEIO de turno (mensagem em FILA, que não abre turno) o último
    # turno é o corrente, com os blocos já escritos. Em ambos, lembra-se o último turno com texto, e a
    # MARCA diz quantos blocos dele já existiam: o Stop só julga o que veio DEPOIS do lembrete.
    ts = last_turns(tp, 3)
    cur = ts[-1] if ts else None
    with_text = [t for t in ts if t["blocks"]]
    fs = find(with_text[-1]["blocks"]) if with_text else []
    rows = [(d["token"], d["row"], d["kind"]) for d in reminded(fs)]
    mark = (turn_id(cur["start"]) if cur else "bof", len(cur["blocks"]) if cur else 0)
    old_mark, old_rows = state_read(False)
    if old_mark is not None and old_mark[0] == mark[0]:      # 2º lembrete no MESMO turno: soma
        rows = sorted(set(old_rows) | set(rows))
    state_write(mark, rows)
    msg = reminder(fs)
    if msg:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                                 "additionalContext": msg}}, ensure_ascii=False))
    sys.exit(0)

if mode == "stop":
    mark, state = state_read(True)
    ts = last_turns(tp, 1)
    if not ts:
        sys.exit(0)
    cur = ts[-1]
    if POLICY == "reincidence" and not cur["human"]:
        sys.exit(0)
    texts = cur["blocks"]
    if POLICY == "reincidence":
        if mark is not None and mark[0] == turn_id(cur["start"]):
            texts = texts[mark[1]:]                 # só o que veio DEPOIS do lembrete
    bad = blockers(find(texts), state, asked_codes(cur))
    if bad:
        why = ("o lembrete deste turno já trazia a glosa" if POLICY == "reincidence"
               else "política estrita ONION_HOUSE_CODE_STOP=%s" % POLICY)
        sys.stderr.write("📖 Sigla da casa SEM GLOSA na prosa ao maestro (%s; pedido do maestro 2026-10-17). "
                         "Termine a resposta glosando cada uma na forma \"SIGLA (glosa)\", ou troque a "
                         "sigla pela glosa:\n" % why)
        for d in bad:
            sys.stderr.write("  · %s → %s\n" % (d["token"], d["gloss"]))
        sys.exit(2)
    sys.exit(0)

if mode == "scan":
    # Simula a sessão: em turno do maestro, o prompt lembra as altas do último turno com texto e o Stop
    # barra a reincidência; em turno de aviso (tarefa de fundo, outra sessão) não há lembrete.
    # TETO: não simula o lembrete de MEIO de turno (mensagem em fila) — só o do início.
    n = anyf = blk = alta = human = rem = 0; last_fs = []
    for i, t in enumerate(split_turns(read_rows(tp))):
        fs = find(t["blocks"]); n += 1
        h = t["human"]
        state = [(d["token"], d["row"], d["kind"]) for d in reminded(last_fs)] if h else []
        if h:
            human += 1
            if state: rem += 1
        ex = asked_codes(t)
        if fs: anyf += 1
        if blockers(fs, [], ex, "alta"): alta += 1
        b = blockers(fs, state, ex, "reincidence") if h else []
        if b:
            blk += 1
            print("BARRARIA turno %d: %s | %s" % (i, ", ".join(d["token"] for d in b), " ⏎ ".join(t["blocks"])[:160].replace("\n", " ")))
        if t["blocks"]: last_fs = fs
    pct = (lambda x: "%.1f%%" % (100.0 * x / n)) if n else (lambda x: "n/a")
    sig = sum(1 for r in gl)
    print("turnos=%d (do maestro=%d) com-sigla-sem-glosa=%d (%s) lembrete-de-alta=%d "
          "barraria=%d (%s) [reincidence] · se barrasse toda alta sem glosa: %d (%s) · glossário=%d linhas"
          % (n, human, anyf, pct(anyf), rem, blk, pct(blk), alta, pct(alta), sig))
    sys.exit(0)
PY
}

_sid() { printf '%s' "$1" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("session_id",""))
except Exception: print("")' 2>/dev/null || true; }

if [ "${1:-}" = "--scan" ]; then _engine scan "${2:-}"; exit 0; fi

if [ "${1:-}" = "--selftest" ]; then
  fails=0
  _ok() { echo "  ✅ $1"; }
  _ko() { echo "  ✗ $1"; fails=$((fails+1)); }
  # o texto vai por ARQUIVO: `python3 - <<'PY'` já ocupa o stdin com o script (classe medida 3× em 2026-09-04)
  _t() { local tf; tf="$(mktemp)"; printf '%s' "$1" > "${tf}"; _engine text "${tf}"; rm -f "${tf}"; }
  # (a) o caso LITERAL do maestro: r13 sem glosa é achado, e a glosa sugerida é a do glossário
  out="$(_t 'Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes.')"
  if grep -q '^r13|alta|' <<< "${out}" && grep -q 'radar do Claude Code' <<< "${out}"; then _ok "(a) frase literal do maestro: r13 sem glosa, glosa do glossário"; else _ko "(a) literal: [${out}]"; fi
  # (b) as formas de glosa aceitas: parêntese depois, sigla num parêntese que explica, travessão/dois-pontos,
  #     cópula, palavra do accept perto da sigla
  out="$(_t 'O I3 (só a sessão dona do checkout grava nele) vale. O norte do Onion (NS1) segue. **E6:** a fronteira de modelos do radar. A W7 significa que nada roda sem o maestro pedir. A rodada r13 do radar do Claude Code mede.')"
  if [ -z "${out}" ]; then _ok "(b) cinco formas de glosa calam"; else _ko "(b) glosadas acusadas: [${out}]"; fi
  # (c) o que não é prosa: crase, bloco de código, citação, caminho/branch, URL, ênfase e título de REGRA
  out="$(_t "$(printf 'Rode `kg r13 I3`.\n```\nr13 I3 E3\n```\n> a rodada r13 pode medir\nVeja docs/radar-E3-r13/x.md e chore/radar-e3-r13 e https://x/r13 .\nA REGRA 61 (Fronteira de MOAT: E3 fica) passou.\n')")"
  if [ -z "${out}" ]; then _ok "(c) código, citação, caminho, branch, URL e título de regra calam"; else _ko "(c) não-prosa acusada: [${out}]"; fi
  # (d) rótulo LOCAL: N1..N3 ao lado de N5/N8 são achados numerados do texto, não níveis do dissect
  out="$(_t 'Rodei o dissect ontem. Os residuais N1, N2, N3, N5 e N8 da revisão seguem.')"
  if [ -z "${out}" ]; then _ok "(d) família de rótulo local (N5, N8 fora do glossário) cala"; else _ko "(d) rótulo local acusado: [${out}]"; fi
  # (e) REGRA abreviada: R56 com regra existente vira "REGRA 56 (título)"; R999 inexistente cala; e a
  #     "REGRA 56 (Título)" na mesma resposta GLOSA o R56 (o hook de título e este concordam)
  out="$(_t 'A R56 passou e a R999 também.')"
  out2="$(_t 'A REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) passou, e a R56 também.')"
  if grep -q '^R56|alta|.*REGRA 56 (' <<< "${out}" && ! grep -q 'R999' <<< "${out}" && [ -z "${out2}" ]; then _ok "(e) R56 sugere REGRA 56 com título; R999 cala; REGRA 56 titulada glosa o R56"; else _ko "(e) R<N>: [${out}] · titulada: [${out2}]"; fi
  # (m) id de NÓ cru: só conta se existir num .kg.yaml versionado, e a glosa sugerida é o título do nó;
  #     AF_UNIX e TRACES_TO têm a mesma forma e não são nós: calam. Fixture própria (repo git temporário):
  #     o selftest viaja ao adotante e não pode depender do corpus do core
  _kgd="$(mktemp -d)"; mkdir -p "${_kgd}/docs"
  printf 'nodes:\n  - id: D_FIXTURE_DA_GLOSA\n    node_type: decision\n    label: "a matriz de teste da glosa"\n' > "${_kgd}/docs/t.kg.yaml"
  git -C "${_kgd}" init -q 2>/dev/null && git -C "${_kgd}" add docs/t.kg.yaml 2>/dev/null
  out="$(CLAUDE_PROJECT_DIR="${_kgd}" _t 'A D_FIXTURE_DA_GLOSA vale; AF_UNIX e TRACES_TO não são nós.')"
  rm -rf "${_kgd}"
  if grep -q '^D_FIXTURE_DA_GLOSA|alta|.*|a matriz de teste da glosa' <<< "${out}" && ! grep -qE 'AF_UNIX|TRACES_TO' <<< "${out}"; then _ok "(m) id de nó existente acusa com o título; forma igual sem nó cala"; else _ko "(m) nó: [${out}]"; fi
  # (y) GLOSAS COMUNS em pt-BR calam: vírgula + cópula, "ou seja", "isto é", "diz que", "=", accept a
  #     7 palavras e radical do accept ("investidores")
  # cada frase julgada SOZINHA: numa resposta só, a glosa de uma cobriria a outra e o caso mentiria
  out=""
  while IFS= read -r _l; do out="${out}$(_t "${_l}")"; done <<'TXT'
O I3, que significa que só a sessão dona grava nele, vale.
I3, ou seja, só a sessão dona grava.
A rodada r13, isto é, a medição da versão nova, passou.
O I3 diz que só a sessão dona grava nele.
I3 = só a sessão dona grava nele.
A r13 mediu a versão 2.1.302 do Claude Code.
No radar, o eixo E4 cobre dinheiro e investidores.
TXT
  if [ -z "${out}" ]; then _ok "(y) glosas comuns em pt-BR (cópula com vírgula, ou seja, isto é, diz que, =) calam"; else _ko "(y) glosa honesta acusada: [${out}]"; fi
  # (f) resposta NORMAL, sem sigla nenhuma: vazio
  out="$(_t 'Abri o PR e o CI está verde. A bancada passou com 12 casos.')"
  if [ -z "${out}" ]; then _ok "(f) resposta normal sem sigla = vazio"; else _ko "(f) [${out}]"; fi
  # (r) GLOSA DE FACHADA não passa: parêntese sem palavras, só com outra sigla, versão depois dos
  #     dois-pontos, travessão com uma palavra só, "E3/E4" (não é caminho) e ênfase em volta da sigla
  out="$(_t "$(printf 'Isso vale (I3).\nA rodada r13 (ok) passou.\nA rodada r14: 2.1.302.\nRodei a rodada r15 — e passou.\nOs eixos E3/E4 do radar seguem.\nNo radar, _E5_ segue.\n')")"
  miss=""; for k in I3 r13 r14 r15 E3 E4 E5; do grep -q "^${k}|" <<< "${out}" || miss="${miss} ${k}"; done
  if [ -z "${miss}" ]; then _ok "(r) glosa de fachada acusa (parêntese vazio, versão, uma palavra, E3/E4, ênfase)"; else _ko "(r) passaram sem glosa:${miss} [${out}]"; fi
  # (s) COLISÃO com palavra comum cala: sem o domínio da sigla no bloco, ela não é a da casa
  out="$(_t 'O teste E3, E4 e E5 do formulário passou. Vamos ver o r1. Custou R$ 10. O D10 do meu relatório.')"
  if [ -z "${out}" ]; then _ok "(s) colisão com palavra comum (sem o domínio no bloco) cala"; else _ko "(s) colisão acusada: [${out}]"; fi
  # (vt) o TERMO do vocabulário (linhas term, projetadas dos x_term): a mesma notation em dois esquemas. O caso
  #     que errou em 2026-10-23 — "a réplica r1 ... do spike A2A rodou; a rodada seguinte" — ganhava a glosa do
  #     radar (o domínio "rodada" casava e o radar era o único sentido de r1). Agora: (v1) o literal não sugere o
  #     radar (o accept "réplica" perto da menção desempata e glosa); (v2) só o domínio do spike → a glosa é a
  #     réplica; (v3) só o do radar → a rodada; (v4) os dois sem desempate → pede a forma qualificada (baixa,
  #     lembra e nunca barra); (v5) a forma qualificada glosa; (v6) a rodada sem termo (r18) ainda cai na linha
  #     static genérica; (v7) o nível do dissect é termo do esquema dissect; (v8) dissect:N2 (qualificada, sem
  #     hífen que a faça passar por caminho) glosa; (v9) o termo vence a static genérica (glossário mínimo); (v10) xq:r2 glosa pelo qualificador;
  #     (v11) dois accepts perto não desempatam; (v12) prefixo que não é esquema não glosa
  v1="$(_t 'A réplica r1 do cenário A7-C1 do spike A2A rodou; a rodada seguinte mediu.')"
  v2="$(_t 'Fechamos o spike A2A. O r1 rodou.')"
  v3="$(_t 'Na 2.1.300 a r1 mediu o delta.')"
  v4="$(_t 'Fechamos o spike A2A. Na rodada seguinte, o r1 mediu.')"
  v5="$(_t 'Fechamos o spike A2A. Na rodada seguinte, o a2a-spike:r1 mediu.')"
  v6="$(_t 'Na 2.1.400 a r18 mediu.')"
  v7="$(_t 'Rodei o dissect. O N2 ficou caro.')"
  v8="$(_t 'Rodei o dissect. O dissect:N2 ficou caro.')"
  # (v9) o termo vence a linha static genérica: glossário mínimo em que só a static teria domínio no bloco
  _g9="$(mktemp)"; printf 'static\tr\\d{1,3}\talta\tSTATIC\t-\trelat\nterm\tr1\talta\tTERMO\t-\tzzz\tx\n' > "${_g9}"
  v9="$(GLOSSARY="${_g9}"; _t 'O r1 do relatório.')"
  # (v10) a forma qualificada glosa por si, sem accept nenhum (esquema xq, domínio relat): sem o qualificador acusa
  printf 'term\tr2\talta\tTERMO\t-\trelat\txq\n' >> "${_g9}"
  v10="$(GLOSSARY="${_g9}"; _t 'O xq:r2 do relatório.')"; v10b="$(GLOSSARY="${_g9}"; _t 'O r2 do relatório.')"; rm -f "${_g9}"
  # (v11) DOIS accepts casando perto da menção não desempatam: é ambígua (sem isto, "o 1º que casar" escolhia um)
  v11="$(_t 'O radar e a réplica do spike mediram o r1.')"
  # (v12) prefixo que NÃO é esquema conhecido não glosa (sem isto, qualquer "foo:" viraria glosa)
  v12="$(_t 'Fechamos o spike A2A. Depois, o foo:r1 mediu nada.')"
  if [ -z "${v1}" ] && grep -q '^r1|alta|r\\d{1,3}|réplica 1 do spike A2A$' <<< "${v2}" \
     && grep -q '^r1|alta|r\\d{1,3}|rodada 1 do radar do Claude Code$' <<< "${v3}" \
     && grep -q '^r1|baixa|r\\d{1,3}|ambígua entre esquemas: escreva a2a-spike:r1 (.*) ou radar-cc:r1 (' <<< "${v4}" \
     && [ -z "${v5}" ] && grep -q '^r18|alta|r\\d{1,3}|a rodada N do radar' <<< "${v6}" \
     && grep -q '^N2|alta|dissect|nível 2 do /meta:dissect (mecanismo)$' <<< "${v7}" && [ -z "${v8}" ] && [ -z "${v9}" ] \
     && [ -z "${v10}" ] && grep -q '^r2|alta|r\\d{1,3}|TERMO$' <<< "${v10b}" \
     && grep -q '^r1|baixa|r\\d{1,3}|ambígua entre esquemas' <<< "${v11}" && grep -q '^r1|' <<< "${v12}"; then
    _ok "(vt) termo do vocabulário: r1 é réplica no contexto do spike, rodada no do radar, e ambígua pede esquema:código"
  else _ko "(vt) termo: v1=[${v1}] v2=[${v2}] v3=[${v3}] v4=[${v4}] v5=[${v5}] v6=[${v6}] v7=[${v7}] v8=[${v8}] v9=[${v9}] v10=[${v10}] v10b=[${v10b}] v11=[${v11}] v12=[${v12}]"; fi

  # ══ PONTA-A-PONTA, como o harness invoca (stdin JSON + transcript + estado da sessão) ══
  _d="$(mktemp -d)"; _tp="${_d}/t.jsonl"; _in="${_d}/in.json"
  export ONION_HOUSE_CODE_STATE_DIR="${_d}/state"
  _mk() {  # pares "u:texto" (pedido humano), "n:texto" (aviso de tarefa de fundo) ou "a:texto" (resposta)
    python3 - "${_tp}" "$@" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    for s in sys.argv[2:]:
        k, t = s.split(":", 1)
        if k == "u":
            fh.write(json.dumps({"type": "user", "origin": {"kind": "human"}, "message": {"role": "user", "content": t}}, ensure_ascii=False) + "\n")
        elif k == "q":
            fh.write(json.dumps({"type": "attachment", "attachment": {"type": "queued_command", "prompt": t, "origin": {"kind": "human"}}}, ensure_ascii=False) + "\n")
        elif k == "c":
            fh.write(json.dumps({"type": "user", "isCompactSummary": True, "message": {"role": "user", "content": "This session is being continued from a previous conversation. " + t}}, ensure_ascii=False) + "\n")
        elif k == "n":
            fh.write(json.dumps({"type": "user", "origin": {"kind": "task-notification"}, "message": {"role": "user", "content": "<task-notification>" + t}}, ensure_ascii=False) + "\n")
        else:
            fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": t}]}}, ensure_ascii=False) + "\n")
            fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {"command": "ls"}}]}}) + "\n")
            fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "content": "ok"}]}}) + "\n")
PY
  }
  printf '{"transcript_path":"%s","stop_hook_active":false,"session_id":"st1"}' "${_tp}" > "${_in}"
  _hook() { bash "${BASH_SOURCE[0]}" "$@" < "${_in}"; }
  # _cycle <prefixo até o pedido do turno> -- <respostas do turno>: o UserPromptSubmit roda sobre o
  # prefixo (grava o estado), depois o Stop sobre o turno inteiro — a ordem real do harness
  _cycle() {
    local pre=() post=() seen=0 a
    for a in "$@"; do if [ "${a}" = "--" ]; then seen=1; elif [ "${seen}" -eq 0 ]; then pre+=("${a}"); else post+=("${a}"); fi; done
    _mk "${pre[@]}"; _hook prompt > "${_d}/prompt.out" 2>&1
    _mk "${pre[@]}" "${post[@]}"; _hook stop
  }
  # (g) PRIMEIRA vez sem glosa: o Stop NÃO barra (o lembrete vem no turno seguinte)
  _rc=0; _o="$(_cycle "u:como está?" -- "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes." 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then _ok "(g) 1ª vez sem glosa: Stop não barra (rc 0)"; else _ko "(g) rc=${_rc} [${_o}]"; fi
  # (h) o LEMBRETE antes de escrever: o turno anterior usou r12 sem glosa → additionalContext com a glosa
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"
  _rc=0; _o="$(_hook prompt 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ] && grep -q '"additionalContext"' <<< "${_o}" && grep -q 'r12 → rodada 12 do radar' <<< "${_o}" && grep -q '^r12' "${ONION_HOUSE_CODE_STATE_DIR}/st1.tsv"; then _ok "(h) UserPromptSubmit injeta a glosa da sigla em uso e grava o lembrado (rc 0, nunca barra)"; else _ko "(h) rc=${_rc} [${_o}]"; fi
  # (i) o caso LITERAL do maestro como REINCIDÊNCIA: lembrado r12 neste turno, a frase com r13 barra
  _rc=0; _o="$(_cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes." "a:Os dois agentes estão rodando." 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 2 ] && grep -q 'r13 → rodada 13 do radar do Claude Code' <<< "${_o}"; then _ok "(i) frase literal do maestro após lembrete: Stop barra por r13 (rc 2) com a glosa"; else _ko "(i) rc=${_rc} [${_o}]"; fi
  # (vf) a REINCIDÊNCIA do termo é por FAMÍLIA, não por esquema: lembrado r12 (que é termo do radar), a rodada
  #      SEGUINTE sem termo (r18) e o caso da bancada (r20) barram igual — é a mesma família de sigla para quem lê.
  #      Sem isto (a reincidência guardando o esquema), o lembrete do r12 deixava passar justo a rodada nova.
  _rcf=0; _of="$(_cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:Na 2.1.400 a r18 mediu o delta." 2>&1)" || _rcf=$?
  #      E a fronteira: OUTRA família (o N2 do dissect) não barra pelo lembrete do r12
  _rcf2=0; _cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:Rodei o dissect e o N2 ficou caro." >/dev/null 2>&1 || _rcf2=$?
  if [ "${_rcf}" -eq 2 ] && [ "${_rcf2}" -eq 0 ]; then _ok "(vf) lembrado um código que é termo, a reincidência barra o da mesma família sem termo (r18) e não a de outra família (N2)"
  else _ko "(vf) reincidência por família: r18 rc=${_rcf} [${_of}] · N2 rc=${_rcf2} (esperados 2 e 0)"; fi
  # (j) resposta NORMAL depois do lembrete — com glosa, ou sem sigla — NUNCA trava
  _rc=0; _o="$(_cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:A rodada r13 do radar do Claude Code pode medir." "a:Abri o PR; o CI está verde." 2>&1)" || _rc=$?
  _rc2=0; _o2="$(_cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:Abri o PR e o CI está verde." 2>&1)" || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 0 ]; then _ok "(j) depois do lembrete, resposta glosada ou sem sigla não trava (rc 0 e 0)"; else _ko "(j) glosada rc=${_rc} [${_o}] · sem sigla rc=${_rc2} [${_o2}]"; fi
  # (k) baixa opacidade reincidente (SAC-N, MOAT, F2) NUNCA barra
  _rc=0; _o="$(_cycle "u:status?" "a:A SAC-156 e a F2 seguem; MOAT intacto." "u:e agora?" -- "a:A SAC-156 e a F2 seguem; MOAT intacto." 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then _ok "(k) sigla de opacidade baixa reincidente não barra"; else _ko "(k) rc=${_rc} [${_o}]"; fi
  # (p) turno de AVISO (tarefa de fundo) não barra, mesmo com o lembrete gravado e não consumido: o
  #     UserPromptSubmit não dispara nele, e o turno não é do maestro. E o lembrete vale UM turno: o Stop
  #     que barrou o consome, e um 2º Stop sobre o mesmo turno (sem lembrete novo) não barra de novo
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"; _hook prompt >/dev/null 2>&1
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:Ok." "n:tarefa terminou" "a:A rodada r14 terminou."
  _rc=0; _o="$(_hook stop 2>&1)" || _rc=$?
  _rc1=0; _cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:a rodada r13 pode medir." >/dev/null 2>&1 || _rc1=$?
  _rc2=0; _hook stop >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc1}" -eq 2 ] && [ "${_rc2}" -eq 0 ]; then _ok "(p) aviso de tarefa de fundo não barra; o lembrete é consumido pelo Stop que barrou (rc 0, 2, 0)"; else _ko "(p) aviso rc=${_rc} [${_o}] · 1º stop rc=${_rc1} (esperado 2) · 2º stop rc=${_rc2} (esperado 0)"; fi
  # (q) EXPLICAR a sigla nunca trava: a cópula glosa ("O I3 é a regra de que…"), e a sigla que o próprio
  #     maestro escreveu no pedido ("o que é I3?") não barra, mesmo numa resposta curta
  _rc=0; _o="$(_cycle "u:status?" "a:Por I3, o push é deles." "u:e o push?" -- "a:O I3 é a regra de que só a sessão dona do repositório grava nele." 2>&1)" || _rc=$?
  _rc2=0; _o2="$(_cycle "u:status?" "a:Por I3, o push é deles." "u:o que é I3?" -- "a:Sim, o I3 vale aqui também." 2>&1)" || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 0 ]; then _ok "(q) explicar a sigla não trava: cópula glosa; sigla do pedido do maestro não barra"; else _ko "(q) cópula rc=${_rc} [${_o}] · do pedido rc=${_rc2} [${_o2}]"; fi
  # (u) LEMBRETE NO MEIO DO TURNO (mensagem do maestro em FILA): o UserPromptSubmit dispara com o turno
  #     em curso; a 1ª menção (antes do lembrete) não barra, e a resposta glosada depois dele não trava.
  #     Sem glosa depois do lembrete, barra
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir." "q:reforço: escreva certo"
  _hook prompt >/dev/null 2>&1
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir." "q:reforço: escreva certo" "a:Sigo. A rodada r13 (a medição do radar do Claude Code para a 2.1.302) terminou."
  _rc=0; _o="$(_hook stop 2>&1)" || _rc=$?
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir." "q:reforço: escreva certo"
  _hook prompt >/dev/null 2>&1
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir." "q:reforço: escreva certo" "a:A rodada r13 segue."
  _rc2=0; _hook stop >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 2 ]; then _ok "(u) lembrete no meio do turno: só o que veio depois dele é julgado (glosado rc 0, sem glosa rc 2)"; else _ko "(u) glosado rc=${_rc} [${_o}] (esperado 0) · sem glosa rc=${_rc2} (esperado 2)"; fi
  # (v) COMPACTAÇÃO no meio do turno não abre turno novo: a glosa lida antes dela continua valendo
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"; _hook prompt >/dev/null 2>&1
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:A rodada r13 (a medição do radar do Claude Code) começou." "c:resumo" "a:A rodada r13 segue."
  _rc=0; _o="$(_hook stop 2>&1)" || _rc=$?
  _rc2=0; ONION_HOUSE_CODE_STOP=alta _hook stop >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 0 ]; then _ok "(v) compactação no meio do turno não apaga a glosa já lida (padrão e estrita)"; else _ko "(v) padrão rc=${_rc} [${_o}] · estrita rc=${_rc2}"; fi
  # (w) ESTADO INSEGURO: diretório de estado aberto a outros (777) ou arquivo de estado que é link →
  #     nada é escrito nem lido (o alvo do link fica intacto) e o Stop não barra por estado plantado
  _ev="${_d}/evil"; mkdir -p "${_ev}"; chmod 777 "${_ev}"; printf 'precioso' > "${_d}/victim.txt"
  ln -s "${_d}/victim.txt" "${_ev}/st1.tsv"
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"
  ONION_HOUSE_CODE_STATE_DIR="${_ev}" _hook prompt >/dev/null 2>&1
  _sd="${_d}/safe"; mkdir -p -m 700 "${_sd}"; printf 'precioso' > "${_d}/victim2.txt"; ln -s "${_d}/victim2.txt" "${_sd}/st1.tsv"
  ONION_HOUSE_CODE_STATE_DIR="${_sd}" _hook prompt >/dev/null 2>&1
  _ev2="${_d}/evil2"; mkdir -p "${_ev2}"; chmod 777 "${_ev2}"; printf '#mark\tbof\t0\nr13\tr\\d{1,3}\tstatic\n' > "${_ev2}/st1.tsv"
  _mk "u:como está?" "a:a rodada r13 pode medir."
  _rc=0; ONION_HOUSE_CODE_STATE_DIR="${_ev2}" _hook stop >/dev/null 2>&1 || _rc=$?
  if [ "$(cat "${_d}/victim.txt")" = "precioso" ] && [ "$(cat "${_d}/victim2.txt")" = "precioso" ] && [ "${_rc}" -eq 0 ]; then _ok "(w) diretório de estado aberto ou link: nada escrito, alvo intacto, estado plantado não barra"; else _ko "(w) victim=[$(cat "${_d}/victim.txt")] victim2=[$(cat "${_d}/victim2.txt")] plantado rc=${_rc}"; fi
  # (x) CAMINHO LENTO da leitura da cauda (teto estourado): o lembrete é o mesmo do caminho normal
  _mk "u:a" "a:ok" "u:b" "a:ok" "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"
  _o1="$(_hook prompt 2>&1)"; _o2="$(ONION_STOP_HOOK_TAIL_MAX_BYTES=1 _hook prompt 2>&1)"
  if grep -q 'r12 → ' <<< "${_o1}" && [ "${_o1}" = "${_o2}" ]; then _ok "(x) teto da cauda estourado devolve o mesmo lembrete"; else _ko "(x) normal=[${_o1}] lento=[${_o2}]"; fi
  # (n) política ESTRITA (ONION_HOUSE_CODE_STOP=alta): a frase literal do maestro barra já na 1ª vez;
  #     off nunca barra, mesmo na reincidência; valor desconhecido (ALTA é aceito; "xyz") vale off
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes."
  _rc=0; _o="$(ONION_HOUSE_CODE_STOP=ALTA _hook stop 2>&1)" || _rc=$?
  _rc3=0; ONION_HOUSE_CODE_STOP=xyz _hook stop >/dev/null 2>&1 || _rc3=$?
  _rc2=0; ONION_HOUSE_CODE_STOP=off _cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:a rodada r13 pode medir." >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 2 ] && grep -q 'r13 → ' <<< "${_o}" && grep -q 'estrita' <<< "${_o}" && [ "${_rc2}" -eq 0 ] && [ "${_rc3}" -eq 0 ]; then _ok "(n) política alta barra o literal na 1ª vez (rc 2); off e valor desconhecido nunca barram"; else _ko "(n) alta rc=${_rc} [${_o}] · off rc=${_rc2} · xyz rc=${_rc3}"; fi
  # (o) ORDEM DE LEITURA no mesmo turno: glosa num bloco ANTERIOR cobre o seguinte (rc 0); glosa só
  #     num bloco POSTERIOR chega tarde e não cobre o anterior (rc 2) — política alta para isolar a ordem
  _mk "u:e então?" "a:A rodada r13 do radar do Claude Code mede a 2.1.302." "a:A rodada r13 segue."
  _rc=0; ONION_HOUSE_CODE_STOP=alta _hook stop >/dev/null 2>&1 || _rc=$?
  _mk "u:e então?" "a:A rodada r13 segue." "a:A rodada r13 do radar do Claude Code mede a 2.1.302."
  _rc2=0; ONION_HOUSE_CODE_STOP=alta _hook stop >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 2 ]; then _ok "(o) glosa em bloco anterior cobre o seguinte (rc 0); glosa tardia não cobre (rc 2)"; else _ko "(o) antes rc=${_rc} (esperado 0) · tardia rc=${_rc2} (esperado 2)"; fi
  # (l) anti-loop: stop_hook_active=true sai 0 mesmo com reincidência; e linha JSON que não é objeto não quebra
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"; _hook prompt >/dev/null 2>&1
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:a rodada r13 pode medir."
  printf '[1,2]\n"str"\n' >> "${_tp}"
  printf '{"transcript_path":"%s","stop_hook_active":true,"session_id":"st1"}' "${_tp}" > "${_d}/in2.json"
  _rc=0; bash "${BASH_SOURCE[0]}" stop < "${_d}/in2.json" >/dev/null 2>&1 || _rc=$?
  _rc2=0; _o2="$(ONION_HOUSE_CODE_STOP=alta _hook stop 2>&1)" || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 2 ] && ! grep -q Traceback <<< "${_o2}"; then _ok "(l) stop_hook_active=true sai 0 (anti-loop); linha JSON não-objeto não quebra o hook"; else _ko "(l) ativo rc=${_rc} · lixo rc=${_rc2} [${_o2}]"; fi
  # ── modo tool (PreToolUse, 2026-10-26): a prosa que a outra sessão e o maestro leem fora da resposta ──
  # o payload vai pelo stdin, como o runner o entrega; rc tem de ser 0 em TODOS (lembrete, nunca bloqueio)
  _tool() { _rc=0; _o="$(printf '%s' "$1" | bash "${BASH_SOURCE[0]}" tool 2>&1)" || _rc=$?; }
  # (t1) o caso do pedido: SendMessage com SAC-256 solto → lembrete com a glosa do glossário
  _tool '{"tool_name":"SendMessage","tool_input":{"to":"main","message":"Fechei o SAC-256 e sigo para o próximo."}}'
  if [ "${_rc}" -eq 0 ] && grep -q '"hookEventName": "PreToolUse"' <<< "${_o}" && grep -q 'SendMessage para main' <<< "${_o}" && grep -q 'SAC-256 → a tarefa do task manager' <<< "${_o}"; then _ok "(t1) SendMessage com SAC-256 sem glosa: additionalContext com a glosa (rc 0)"; else _ko "(t1) rc=${_rc} [${_o}]"; fi
  # (t2) a mesma mensagem com a glosa → silêncio
  _tool '{"tool_name":"SendMessage","tool_input":{"to":"main","message":"Fechei a tarefa da glosa entre sessões (SAC-256) e sigo."}}'
  if [ "${_rc}" -eq 0 ] && [ -z "${_o}" ]; then _ok "(t2) SendMessage com a glosa cala (rc 0)"; else _ko "(t2) glosada acusada: rc=${_rc} [${_o}]"; fi
  # (t3) Write de STAGE0.md com K1 solto → lembrete; (t4) o mesmo texto fora da lista (notes.md, README.md) → silêncio
  _tool '{"tool_name":"Write","tool_input":{"file_path":"/w/docs/evolution/dissect/x-2026-10/STAGE0.md","content":"# Etapa 0\n\nO critério K1 decide o veredito."}}'
  if [ "${_rc}" -eq 0 ] && grep -q 'STAGE0.md' <<< "${_o}" && grep -q 'K1 → o critério ou mutante' <<< "${_o}"; then _ok "(t3) Write de STAGE0.md com K1 solto: lembrete (rc 0)"; else _ko "(t3) rc=${_rc} [${_o}]"; fi
  _tool '{"tool_name":"Write","tool_input":{"file_path":"/w/docs/evolution/dissect/x-2026-10/notes.md","content":"# Etapa 0\n\nO critério K1 decide o veredito."}}'
  _o4="${_o}"; _rc4="${_rc}"
  _tool '{"tool_name":"Write","tool_input":{"file_path":"/w/docs/evolution/dissect/x-2026-10/README.md","content":"# Etapa 0\n\nO critério K1 decide o veredito."}}'
  if [ "${_rc4}" -eq 0 ] && [ -z "${_o4}" ] && [ "${_rc}" -eq 0 ] && [ -z "${_o}" ]; then _ok "(t4) .md fora da lista (notes.md, README.md) cala (rc 0)"; else _ko "(t4) notes rc=${_rc4} [${_o4}] · README rc=${_rc} [${_o}]"; fi
  # (t5) Edit: a sigla glosada em outro ponto do arquivo não é cobrada de novo; sem a glosa no arquivo, é
  mkdir -p "${_d}/docs/evolution/research/y-2026-10"; _ef="${_d}/docs/evolution/research/y-2026-10/SYNTHESIS.md"
  printf '# Síntese\n\nO I3 (um escritor por repo) vale aqui.\n' > "${_ef}"
  _tool "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${_ef}\",\"old_string\":\"vale aqui.\",\"new_string\":\"vale aqui. E o I3 segue valendo.\"}}"
  _o5="${_o}"; _rc5="${_rc}"
  printf '# Síntese\n\nNada aqui.\n' > "${_ef}"
  _tool "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${_ef}\",\"old_string\":\"Nada aqui.\",\"new_string\":\"E o I3 segue valendo.\"}}"
  if [ "${_rc5}" -eq 0 ] && [ -z "${_o5}" ] && [ "${_rc}" -eq 0 ] && grep -q 'I3 → o invariante' <<< "${_o}"; then _ok "(t5) Edit: glosa já no arquivo cobre; sem ela, lembra (rc 0)"; else _ko "(t5) com glosa rc=${_rc5} [${_o5}] · sem rc=${_rc} [${_o}]"; fi
  # (t6) payload lixo, ferramenta fora do matcher e mensagem não-texto: rc 0, mudo, sem Traceback
  _tool 'lixo SendMessage {'; _o6="${_o}${_rc}"
  _tool '{"tool_name":"Bash","tool_input":{"command":"echo SAC-256 docs/evolution/research/a/STAGE0.md"}}'; _o6="${_o6}${_o}${_rc}"
  _tool '{"tool_name":"SendMessage","tool_input":{"to":"main","message":{"type":"shutdown_request"}}}'; _o6="${_o6}${_o}${_rc}"
  if [ "${_o6}" = "000" ]; then _ok "(t6) payload lixo, Bash e mensagem estruturada: mudo, rc 0"; else _ko "(t6) [${_o6}]"; fi
  # ── os achados da passada adversarial de 2026-10-26, cada um com o caso que o reproduzia ──
  # (t7) a sigla definida numa linha de tabela está glosada; a célula vazia de sentido não
  _tool '{"tool_name":"Write","tool_input":{"file_path":"/w/docs/evolution/dissect/x-2026-10/STAGE0.md","content":"# Critérios\n\n| id | critério |\n|---|---|\n| K1 | o veredito absorver exige dois usos reais |\n| I3 | só a sessão dona do repo commita nele |\n\nO critério K1 decide, e o I3 vale.\n"}}'
  _o7="${_o}${_rc}"
  _tool '{"tool_name":"Write","tool_input":{"file_path":"/w/docs/evolution/dissect/x-2026-10/STAGE0.md","content":"# Critérios\n\n| K1 | ok |\n\nO critério K1 decide."}}'
  if [ "${_o7}" = "0" ] && [ "${_rc}" -eq 0 ] && grep -q 'K1 →' <<< "${_o}"; then _ok "(t7) K1 definido em linha de tabela cala; célula sem definição lembra (rc 0)"; else _ko "(t7) tabela [${_o7}] · célula vazia rc=${_rc} [${_o}]"; fi
  # (t8) "Kimi K3" (nome de modelo) num arquivo que fala de critério LONGE dali não é rótulo do pré-registro
  _tool '{"tool_name":"Write","tool_input":{"file_path":"/w/docs/evolution/research/y-2026-10/SYNTHESIS.md","content":"O modelo Kimi K3 respondeu rápido.\n\nMais adiante: o critério de aceite segue o pré-registro."}}'
  if [ "${_rc}" -eq 0 ] && [ -z "${_o}" ]; then _ok "(t8) Kimi K3 com critério longe cala (rc 0)"; else _ko "(t8) rc=${_rc} [${_o}]"; fi
  # (t9) Edit é julgado pelo RESULTADO: trocar só o número de uma tarefa glosada cala; apagar a glosa lembra
  printf '# Síntese\n\nFechei a tarefa da glosa entre sessões (SAC-255).\n' > "${_ef}"
  _tool "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${_ef}\",\"old_string\":\"SAC-255\",\"new_string\":\"SAC-256\"}}"
  _o9="${_o}${_rc}"
  printf '# Síntese\n\nO I3 (um escritor por repo) vale.\n' > "${_ef}"
  _tool "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${_ef}\",\"old_string\":\"O I3 (um escritor por repo) vale.\",\"new_string\":\"O I3 vale.\"}}"
  if [ "${_o9}" = "0" ] && [ "${_rc}" -eq 0 ] && grep -q 'I3 →' <<< "${_o}"; then _ok "(t9) Edit julgado pelo resultado: troca de número glosado cala; glosa apagada lembra (rc 0)"; else _ko "(t9) troca [${_o9}] · apagada rc=${_rc} [${_o}]"; fi
  # (t10) assunto vazio antes do parêntese não é glosa; assunto curto e honesto é
  _tool '{"tool_name":"SendMessage","tool_input":{"to":"main","message":"Para o detalhe, veja o que está em (SAC-256)."}}'
  _o10="${_o}"; _rc10="${_rc}"
  _tool '{"tool_name":"SendMessage","tool_input":{"to":"main","message":"Fiz a migração (SAC-256)."}}'
  if [ "${_rc10}" -eq 0 ] && grep -q 'SAC-256 →' <<< "${_o10}" && [ "${_rc}" -eq 0 ] && [ -z "${_o}" ]; then _ok "(t10) assunto vazio lembra; assunto curto honesto cala (rc 0)"; else _ko "(t10) vazio rc=${_rc10} [${_o10}] · honesto rc=${_rc} [${_o}]"; fi
  # (t11) destinatário com surrogate solto e texto acima do teto: rc 0, nada de Traceback
  _tool '{"tool_name":"SendMessage","tool_input":{"to":"\ud800","message":"Fechei o SAC-256."}}'
  _o11="${_o}${_rc}"
  _big="$(python3 -c 'print("SAC-256 " * 30000)')"
  _tool "{\"tool_name\":\"SendMessage\",\"tool_input\":{\"to\":\"main\",\"message\":\"${_big}\"}}"
  if ! grep -q Traceback <<< "${_o11}" && grep -q 'SAC-256 →' <<< "${_o11}" && [ "${_rc}" -eq 0 ] && [ -z "${_o}" ]; then _ok "(t11) surrogate no destinatário sem Traceback; texto acima do teto cala (rc 0)"; else _ko "(t11) surrogate [${_o11}] · teto rc=${_rc} [${_o:0:120}]"; fi
  unset ONION_HOUSE_CODE_STATE_DIR
  rm -rf "${_d}"

  [ "${fails}" -eq 0 ] && { echo "house-code-gloss selftest: OK"; exit 0; }
  echo "house-code-gloss selftest: ${fails} falha(s)"; exit 1
fi

mode="${1:-stop}"
input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
if [ "${mode}" = "tool" ]; then
  # filtro barato ANTES do python: o matcher inclui Write|Edit, que dispara em TODA escrita da sessão
  case "${input}" in
    *SendMessage*|*evolution*) : ;;   # sem aspas nem barras: JSON com barra ou letra escapada não escapa do filtro
    *) exit 0 ;;
  esac
  _pf="$(mktemp 2>/dev/null)" || exit 0
  printf '%s' "${input}" > "${_pf}"
  _engine tool "${_pf}" "" || true
  rm -f "${_pf}"
  exit 0
fi
if [ "${mode}" = "stop" ]; then
  active="$(printf '%s' "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("1" if d.get("stop_hook_active") else "0")' 2>/dev/null || echo 0)"
  [ "${active}" = "1" ] && exit 0
fi
tp="$(printf '%s' "${input}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null || true)"
[ -n "${tp}" ] && [ -f "${tp}" ] || exit 0
sid="$(_sid "${input}")"
case "${mode}" in
  prompt) _engine prompt "${tp}" "${sid}"; exit 0 ;;
  stop)   _engine stop "${tp}" "${sid}"; exit $? ;;
  *)      exit 0 ;;
esac
