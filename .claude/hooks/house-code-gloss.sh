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
# USO     : registrado em .claude/settings.json (UserPromptSubmit com `prompt`, Stop com `stop`).
#           --selftest prova as polaridades; --scan <transcript.jsonl> simula os dois modos em cada turno
#           de uma sessão real (dogfood; a taxa de bloqueio sai no fim).
# =============================================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAL="${HERE}/../validation"
GLOSSARY="${ONION_HOUSE_CODES_TSV:-${VAL}/house-codes.tsv}"
STATE_DIR="${ONION_HOUSE_CODE_STATE_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/onion-house-code-gloss-$(id -u)}"

_engine() {   # $1=modo (prompt|stop|scan|text) · $2=transcript (ou, no modo text, o arquivo com o texto) · $3=sessão
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1" "${2:--}" "${HERE}" "${GLOSSARY}" "${VAL}/lint-artifacts.sh" "${VAL}/plugin-bundle-check.sh" "${3:-}" "${STATE_DIR}" <<'PY'
import hashlib, importlib.util, json, os, re, subprocess, sys
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
    return j.get("type") == "user" and not is_tool_result(j) and not j.get("isSidechain")

def user_text(j):
    c = _msg(j).get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return "\n".join(x.get("text", "") for x in c if isinstance(x, dict) and x.get("type") == "text")
    return ""

def is_human(j):
    o = j.get("origin")
    if isinstance(o, dict) and o.get("kind"):
        return o.get("kind") == "human"
    t = user_text(j).lstrip()
    return not j.get("isMeta") and not t.startswith(("<task-notification", "Stop hook feedback", "<local-command"))

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
    if pred is not None and tt is not None:
        rows = tt.tail_until(path, pred)
    else:
        rows = []
        for line in open(path, encoding="utf-8", errors="replace"):
            try: rows.append(json.loads(line))
            except Exception: pass
    return [j for j in rows if isinstance(j, dict)]

def split_turns(rows):
    """[(linha que abriu o turno ou None, [blocos de texto do assistente])], na ordem."""
    turns, start, cur = [], None, None
    for j in rows:
        if is_turn_start(j):
            if cur is not None: turns.append((start, cur))
            start, cur = j, []
            continue
        if cur is None: cur = []
        cur.extend(blocks(j))
    if cur is not None: turns.append((start, cur))
    return turns

def last_turns(path, n):
    state = {"seen": 0}
    def pred(j):
        if isinstance(j, dict) and is_turn_start(j):
            state["seen"] += 1
            return state["seen"] >= n
        return False
    return split_turns(read_rows(path, pred))[-n:]

def reminded(fs):
    return [d for d in fs if d["opacity"] == "alta"][:8]

def reminder(fs):
    hi = reminded(fs)
    lo = [d for d in fs if d["opacity"] != "alta"]
    if not fs:
        return ""
    lines = ["📖 Glossário da casa — siglas que a sua resposta anterior usou SEM glosa. Ao maestro, "
             "escreva a sigla com a glosa na 1ª menção de cada bloco (ex.: \"I3 (um escritor por repo)\") "
             "ou troque a sigla pela glosa. Repetir sem glosa as de opacidade alta abaixo barra o fim do turno:"]
    for d in hi:
        lines.append("  · %s → %s" % (d["token"], d["gloss"]))
    if lo:
        lines.append("  · também sem glosa (não barra): " + "; ".join(
            "%s → %s" % (d["token"], d["gloss"]) for d in lo[:5]))
    return "\n".join(lines)

def state_path():
    key = sid or hashlib.sha256(tp.encode("utf-8", "replace")).hexdigest()[:16]
    key = re.sub(r"[^A-Za-z0-9_.-]", "_", key)
    return os.path.join(sdir, key + ".tsv")

def prompt_codes(start):
    """As siglas que o próprio maestro escreveu no pedido: ele as conhece, não barram."""
    if start is None:
        return set()
    t = user_text(start)
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
    rows = {r for _, r, k in state if k == "static"}
    return [d for d in hi if d["token"] in toks or (d["kind"] == "static" and d["row"] in rows)]

if mode == "text":
    for d in find([open(tp, encoding="utf-8", errors="replace").read()]):
        print("%s|%s|%s|%s" % (d["token"], d["opacity"], d["row"], d["gloss"]))
    sys.exit(0)

if not tp or tp == "-" or not os.path.isfile(tp):
    sys.exit(0)

if mode == "prompt":
    # O turno NOVO pode ainda não estar no transcript (ou estar só com o pedido): o turno lembrado é o
    # último que tem texto do assistente.
    ts = [t for _, t in last_turns(tp, 3) if t]
    fs = find(ts[-1]) if ts else []
    try:
        os.makedirs(sdir, mode=0o700, exist_ok=True)
        with open(state_path(), "w", encoding="utf-8") as fh:
            for d in reminded(fs):
                fh.write("%s\t%s\t%s\n" % (d["token"], d["row"], d["kind"]))
    except Exception:
        pass
    msg = reminder(fs)
    if msg:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                                 "additionalContext": msg}}, ensure_ascii=False))
    sys.exit(0)

if mode == "stop":
    state = []
    try:
        with open(state_path(), encoding="utf-8") as fh:
            state = [tuple(l.rstrip("\n").split("\t")[:3]) for l in fh if l.count("\t") >= 2]
        os.remove(state_path())      # o lembrete vale para UM turno: lido, consumido
    except Exception:
        state = []
    ts = last_turns(tp, 1)
    if not ts:
        sys.exit(0)
    start, cur = ts[-1]
    if POLICY == "reincidence" and (start is None or not is_human(start)):
        sys.exit(0)
    bad = blockers(find(cur), state, prompt_codes(start))
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
    # Simula a sessão: em turno aberto pelo maestro, o prompt lembra as altas do último turno com texto
    # e o Stop barra a reincidência; em turno de aviso (tarefa de fundo, outra sessão) não há lembrete.
    n = anyf = blk = alta = human = rem = 0; last_fs = []
    for i, (start, t) in enumerate(split_turns(read_rows(tp))):
        fs = find(t); n += 1
        h = start is not None and is_human(start)
        state = [(d["token"], d["row"], d["kind"]) for d in reminded(last_fs)] if h else []
        if h:
            human += 1
            if state: rem += 1
        ex = prompt_codes(start)
        if fs: anyf += 1
        if blockers(fs, [], ex, "alta"): alta += 1
        b = blockers(fs, state, ex, "reincidence") if h else []
        if b:
            blk += 1
            print("BARRARIA turno %d: %s | %s" % (i, ", ".join(d["token"] for d in b), " ⏎ ".join(t)[:160].replace("\n", " ")))
        if t: last_fs = fs
    pct = (lambda x: "%.1f%%" % (100.0 * x / n)) if n else (lambda x: "n/a")
    print("turnos=%d (abertos pelo maestro=%d) com-sigla-sem-glosa=%d (%s) lembrete-de-alta=%d "
          "barraria=%d (%s) [reincidence] · se barrasse toda alta sem glosa: %d (%s)"
          % (n, human, anyf, pct(anyf), rem, blk, pct(blk), alta, pct(alta)))
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
  #     AF_UNIX e TRACES_TO têm a mesma forma e não são nós: calam
  out="$(_t 'A D_MATRIZ_DE_PORTAS_2026_10 vale; AF_UNIX e TRACES_TO não são nós.')"
  if grep -q '^D_MATRIZ_DE_PORTAS_2026_10|alta|.*|matriz das portas' <<< "${out}" && ! grep -qE 'AF_UNIX|TRACES_TO' <<< "${out}"; then _ok "(m) id de nó existente acusa com o título; forma igual sem nó cala"; else _ko "(m) nó: [${out}]"; fi
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
  if [ "${_rc}" -eq 0 ] && grep -q '"additionalContext"' <<< "${_o}" && grep -q 'r12 → a rodada N do radar' <<< "${_o}" && grep -q '^r12' "${ONION_HOUSE_CODE_STATE_DIR}/st1.tsv"; then _ok "(h) UserPromptSubmit injeta a glosa da sigla em uso e grava o lembrado (rc 0, nunca barra)"; else _ko "(h) rc=${_rc} [${_o}]"; fi
  # (i) o caso LITERAL do maestro como REINCIDÊNCIA: lembrado r12 neste turno, a frase com r13 barra
  _rc=0; _o="$(_cycle "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" -- "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes." "a:Os dois agentes estão rodando." 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 2 ] && grep -q 'r13 → a rodada N do radar do Claude Code' <<< "${_o}"; then _ok "(i) frase literal do maestro após lembrete: Stop barra por r13 (rc 2) com a glosa"; else _ko "(i) rc=${_rc} [${_o}]"; fi
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
  unset ONION_HOUSE_CODE_STATE_DIR
  rm -rf "${_d}"

  [ "${fails}" -eq 0 ] && { echo "house-code-gloss selftest: OK"; exit 0; }
  echo "house-code-gloss selftest: ${fails} falha(s)"; exit 1
fi

mode="${1:-stop}"
input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
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
