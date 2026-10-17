#!/usr/bin/env bash
# =============================================================================
# house-code-gloss.sh — sigla da casa na prosa ao maestro vem com a glosa: LEMBRA antes, barra raro
#
# POR QUÊ : pedido do maestro (2026-10-17): "expressões que não lembro como aqui no r13, I3, ..." —
#           sobre a frase "Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13
#           pode medir". E o reforço do mesmo dia, que decide o desenho: "isso é para você escrever
#           certo e não para ficar travando toda hora". Por isso são DOIS modos, e o normal é o 1º:
#
#   prompt (UserPromptSubmit) — o caminho normal, ANTES de escrever: lê o turno anterior do
#           assistente, acha as siglas que ele usou sem glosa e INJETA a glosa de cada uma (o
#           glossário só das siglas em uso). Nunca barra.
#   stop   (Stop)             — a rede rara: barra (exit 2) só a sigla de opacidade ALTA cuja linha
#           do glossário JÁ FOI LEMBRADA no turno anterior e voltou sem glosa (reincidência). Medido
#           nas respostas reais de 2026-10-17 (885 turnos, 3 sessões): barrar toda sigla sem glosa
#           travaria 33,3% dos turnos; só as de opacidade alta, 4,3%; só a reincidência lembrada,
#           1,4% — e isso ANTES do efeito do lembrete, que existe para baixar a taxa.
#
# COMO    : o glossário é .claude/validation/house-codes.tsv (fonte única; nada embutido aqui). O
#           que conta como glosa e o que não é prosa (código, citação, caminho, URL, "REGRA N
#           (Título)") mora em lib/house_codes.py. A "resposta" é cada bloco de texto do assistente:
#           o maestro lê o bloco quando ele chega, e uma glosa três blocos depois chega tarde.
#           ONION_HOUSE_CODE_STOP escolhe a política do Stop: reincidence (padrão, a medida acima),
#           alta (toda sigla de opacidade alta sem glosa, já na 1ª vez) ou off (só o lembrete).
#           Anti-loop: stop_hook_active=true → exit 0. Sem python3, sem glossário ou sem transcript:
#           exit 0 (a guarda erra para o lado de calar).
#
# USO     : registrado em .claude/settings.json (UserPromptSubmit com `prompt`, Stop com `stop`).
#           --selftest prova as polaridades; --scan <transcript.jsonl> mede o que os dois modos
#           fariam em cada turno de uma sessão real (dogfood; a taxa de bloqueio sai no fim).
# =============================================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAL="${HERE}/../validation"
GLOSSARY="${ONION_HOUSE_CODES_TSV:-${VAL}/house-codes.tsv}"

_engine() {   # $1=modo (prompt|stop|scan|text) · $2=transcript (ou, no modo text, o arquivo com o texto)
  command -v python3 >/dev/null 2>&1 || return 0
  python3 - "$1" "${2:--}" "${HERE}" "${GLOSSARY}" "${VAL}/lint-artifacts.sh" "${VAL}/plugin-bundle-check.sh" <<'PY'
import importlib.util, json, os, subprocess, sys
mode, tp, here, gpath, lint, bundle = sys.argv[1:7]
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

def is_tool_result(j):
    c = (j.get("message") or {}).get("content")
    return isinstance(c, list) and any(isinstance(x, dict) and x.get("type") == "tool_result" for x in c)

def is_turn_start(j):
    return j.get("type") == "user" and not is_tool_result(j) and not j.get("isSidechain")

def blocks(j):
    if j.get("type") != "assistant" or j.get("isSidechain"):
        return []
    t = "\n".join(c.get("text", "") for c in (j.get("message") or {}).get("content") or []
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

def last_turns(path, n):
    """Os textos do assistente nos últimos n turnos (o mais recente por último), pela CAUDA."""
    state = {"seen": 0}
    def pred(j):
        if is_turn_start(j):
            state["seen"] += 1
            return state["seen"] >= n
        return False
    if tt is not None:
        rows = tt.tail_until(path, pred)
    else:
        rows = []
        for line in open(path, encoding="utf-8", errors="replace"):
            try: rows.append(json.loads(line))
            except Exception: pass
    turns, cur = [], None
    for j in rows:
        if is_turn_start(j):
            if cur is not None: turns.append(cur)
            cur = []
            continue
        if cur is None: cur = []
        cur.extend(blocks(j))
    if cur is not None: turns.append(cur)
    return turns[-n:]

def reminder(fs):
    hi = [d for d in fs if d["opacity"] == "alta"]
    lo = [d for d in fs if d["opacity"] != "alta"]
    if not fs:
        return ""
    lines = ["📖 Glossário da casa — siglas que a sua resposta anterior usou SEM glosa. Ao maestro, "
             "escreva a sigla com a glosa na 1ª menção de cada bloco (ex.: \"I3 (um escritor por repo)\") "
             "ou troque a sigla pela glosa. Reincidir nas de opacidade alta barra o fim do turno:"]
    for d in hi[:8]:
        lines.append("  · %s → %s" % (d["token"], d["gloss"]))
    if lo:
        lines.append("  · também sem glosa (não barra): " + "; ".join(
            "%s → %s" % (d["token"], d["gloss"]) for d in lo[:5]))
    return "\n".join(lines)

POLICY = os.environ.get("ONION_HOUSE_CODE_STOP", "reincidence")

def blockers(prev, cur, policy=None):
    """reincidence (padrão): alta cuja LINHA do glossário já veio no lembrete do turno anterior;
    alta: toda sigla de opacidade alta sem glosa; off: nunca barra."""
    policy = policy or POLICY
    if policy == "off":
        return []
    hi = [d for d in cur if d["opacity"] == "alta"]
    if policy == "alta":
        return hi
    rows = {d["row"] for d in prev}
    return [d for d in hi if d["row"] in rows]

if mode == "text":
    for d in find([open(tp, encoding="utf-8", errors="replace").read()]):
        print("%s|%s|%s|%s" % (d["token"], d["opacity"], d["row"], d["gloss"]))
    sys.exit(0)

if not tp or tp == "-" or not os.path.isfile(tp):
    sys.exit(0)

if mode == "prompt":
    # O turno NOVO ainda não está no transcript quando o UserPromptSubmit dispara (ou já está, só com o
    # pedido): em qualquer caso, o turno anterior é o último que tem texto do assistente.
    ts = [t for t in last_turns(tp, 3) if t]
    msg = reminder(find(ts[-1])) if ts else ""
    if msg:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit",
                                                 "additionalContext": msg}}, ensure_ascii=False))
    sys.exit(0)

if mode == "stop":
    ts = last_turns(tp, 2)
    prev, cur = (ts[0], ts[1]) if len(ts) == 2 else ([], ts[-1] if ts else [])
    bad = blockers(find(prev), find(cur))
    if bad:
        why = ("de novo: o lembrete do turno anterior já trazia a glosa" if POLICY == "reincidence"
               else "política estrita ONION_HOUSE_CODE_STOP=%s" % POLICY)
        sys.stderr.write("📖 Sigla da casa SEM GLOSA na prosa ao maestro (%s; pedido do maestro 2026-10-17). "
                         "Termine a resposta glosando cada uma na forma \"SIGLA (glosa)\", ou troque a "
                         "sigla pela glosa:\n" % why)
        for d in bad:
            sys.stderr.write("  · %s → %s\n" % (d["token"], d["gloss"]))
        sys.exit(2)
    sys.exit(0)

if mode == "scan":
    turns, cur = [], None
    for line in open(tp, encoding="utf-8", errors="replace"):
        try: j = json.loads(line)
        except Exception: continue
        if is_turn_start(j):
            if cur is not None: turns.append(cur)  # turno vazio também conta: é o que o Stop vê
            cur = []; continue
        if cur is None: cur = []
        cur.extend(blocks(j))
    if cur is not None: turns.append(cur)
    n = rem = blk = anyf = alta = 0; prev = []
    for i, t in enumerate(turns):
        fs = find(t); n += 1
        if fs: anyf += 1
        if blockers(prev, fs, "alta"): alta += 1
        b = blockers(prev, fs)
        if b:
            blk += 1
            print("BARRARIA turno %d: %s | %s" % (i, ", ".join(d["token"] for d in b), " ⏎ ".join(t)[:160].replace("\n", " ")))
        if fs: rem += 1
        prev = fs
    pct = (lambda x: "%.1f%%" % (100.0 * x / n)) if n else (lambda x: "n/a")
    print("turnos=%d com-sigla-sem-glosa=%d (%s) lembrete-no-turno-seguinte=%d barraria=%d (%s) [politica=%s]"
          " · se barrasse toda alta sem glosa: %d (%s)"
          % (n, anyf, pct(anyf), rem, blk, pct(blk), POLICY, alta, pct(alta)))
    sys.exit(0)
PY
}

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
  #     palavra do accept na mesma frase
  out="$(_t 'O I3 (só a sessão dona do checkout grava nele) vale. O norte do Onion (NS1) segue. **E6:** a fronteira de modelos. A rodada r13 do radar do Claude Code mede.')"
  if [ -z "${out}" ]; then _ok "(b) quatro formas de glosa calam"; else _ko "(b) glosadas acusadas: [${out}]"; fi
  # (c) o que não é prosa: crase, bloco de código, citação, caminho/branch, URL e título de REGRA
  out="$(_t "$(printf 'Rode `kg r13 I3`.\n```\nr13 I3 E3\n```\n> a rodada r13 pode medir\nVeja docs/radar-E3-r13/x.md e chore/radar-e3-r13 e https://x/r13 .\nA REGRA 61 (Fronteira de MOAT: E3 fica) passou.\n')")"
  if [ -z "${out}" ]; then _ok "(c) código, citação, caminho, branch, URL e título de regra calam"; else _ko "(c) não-prosa acusada: [${out}]"; fi
  # (d) rótulo LOCAL: N1..N3 ao lado de N5/N8 são achados numerados do texto, não níveis do dissect
  out="$(_t 'Os residuais N1, N2, N3, N5 e N8 seguem.')"
  if [ -z "${out}" ]; then _ok "(d) família de rótulo local (N5, N8 fora do glossário) cala"; else _ko "(d) rótulo local acusado: [${out}]"; fi
  # (e) REGRA abreviada: R56 com regra existente vira "REGRA 56 (título)"; R999 inexistente cala
  out="$(_t 'A R56 passou e a R999 também.')"
  if grep -q '^R56|alta|.*REGRA 56 (' <<< "${out}" && ! grep -q 'R999' <<< "${out}"; then _ok "(e) R56 sugere REGRA 56 com título; R999 inexistente cala"; else _ko "(e) R<N>: [${out}]"; fi
  # (m) id de NÓ cru: só conta se existir num .kg.yaml versionado, e a glosa sugerida é o título do nó;
  #     AF_UNIX e TRACES_TO têm a mesma forma e não são nós: calam
  out="$(_t 'A D_MATRIZ_DE_PORTAS_2026_10 vale; AF_UNIX e TRACES_TO não são nós.')"
  if grep -q '^D_MATRIZ_DE_PORTAS_2026_10|alta|.*|matriz das portas' <<< "${out}" && ! grep -qE 'AF_UNIX|TRACES_TO' <<< "${out}"; then _ok "(m) id de nó existente acusa com o título; forma igual sem nó cala"; else _ko "(m) nó: [${out}]"; fi
  # (f) resposta NORMAL, sem sigla nenhuma: vazio
  out="$(_t 'Abri o PR e o CI está verde. A bancada passou com 12 casos.')"
  if [ -z "${out}" ]; then _ok "(f) resposta normal sem sigla = vazio"; else _ko "(f) [${out}]"; fi

  # ══ PONTA-A-PONTA, como o harness invoca (stdin JSON + transcript) ══
  _d="$(mktemp -d)"; _tp="${_d}/t.jsonl"; _in="${_d}/in.json"
  _mk() {  # $1..$n = pares "u:texto" (pedido humano) ou "a:texto" (resposta com texto)
    python3 - "${_tp}" "$@" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    for s in sys.argv[2:]:
        k, t = s.split(":", 1)
        if k == "u":
            fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": t}}, ensure_ascii=False) + "\n")
        else:
            fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": t}]}}, ensure_ascii=False) + "\n")
            fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {"command": "ls"}}]}}) + "\n")
            fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "content": "ok"}]}}) + "\n")
PY
  }
  printf '{"transcript_path":"%s","stop_hook_active":false}' "${_tp}" > "${_in}"
  # (g) PRIMEIRA vez sem glosa: o Stop NÃO barra (o lembrete vem no turno seguinte)
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes."
  _rc=0; _o="$(bash "${BASH_SOURCE[0]}" stop < "${_in}" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then _ok "(g) 1ª vez sem glosa: Stop não barra (rc 0)"; else _ko "(g) rc=${_rc} [${_o}]"; fi
  # (h) o LEMBRETE antes de escrever: o turno anterior usou r12 sem glosa → additionalContext com a glosa
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?"
  _rc=0; _o="$(bash "${BASH_SOURCE[0]}" prompt < "${_in}" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ] && grep -q '"additionalContext"' <<< "${_o}" && grep -q 'r12 → a rodada N do radar' <<< "${_o}"; then _ok "(h) UserPromptSubmit injeta a glosa da sigla em uso (rc 0, nunca barra)"; else _ko "(h) rc=${_rc} [${_o}]"; fi
  # (i) o caso LITERAL do maestro como REINCIDÊNCIA: lembrado r12 no turno anterior, a frase com r13 barra
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes." "a:Os dois agentes estão rodando."
  _rc=0; _o="$(bash "${BASH_SOURCE[0]}" stop < "${_in}" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 2 ] && grep -q 'r13 → a rodada N do radar do Claude Code' <<< "${_o}"; then _ok "(i) frase literal do maestro após lembrete: Stop barra por r13 (rc 2) com a glosa"; else _ko "(i) rc=${_rc} [${_o}]"; fi
  # (j) resposta NORMAL depois do lembrete — com glosa, ou sem sigla — NUNCA trava
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:A rodada r13 do radar do Claude Code pode medir." "a:Abri o PR; o CI está verde."
  _rc=0; _o="$(bash "${BASH_SOURCE[0]}" stop < "${_in}" 2>&1)" || _rc=$?
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:Abri o PR e o CI está verde."
  _rc2=0; _o2="$(bash "${BASH_SOURCE[0]}" stop < "${_in}" 2>&1)" || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 0 ]; then _ok "(j) depois do lembrete, resposta glosada ou sem sigla não trava (rc 0 e 0)"; else _ko "(j) glosada rc=${_rc} [${_o}] · sem sigla rc=${_rc2} [${_o2}]"; fi
  # (k) baixa opacidade reincidente (SAC-N, MOAT, F2) NUNCA barra
  _mk "u:status?" "a:A SAC-156 e a F2 seguem; MOAT intacto." "u:e agora?" "a:A SAC-156 e a F2 seguem; MOAT intacto."
  _rc=0; _o="$(bash "${BASH_SOURCE[0]}" stop < "${_in}" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then _ok "(k) sigla de opacidade baixa reincidente não barra"; else _ko "(k) rc=${_rc} [${_o}]"; fi
  # (n) política ESTRITA (ONION_HOUSE_CODE_STOP=alta): a frase literal do maestro barra já na 1ª vez;
  #     e ONION_HOUSE_CODE_STOP=off nunca barra, mesmo na reincidência
  _mk "u:como está?" "a:Processo, disco e SDK do bridge estão todos em 2.1.302, então a rodada r13 pode medir. Lanço os dois agentes."
  _rc=0; _o="$(ONION_HOUSE_CODE_STOP=alta bash "${BASH_SOURCE[0]}" stop < "${_in}" 2>&1)" || _rc=$?
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:a rodada r13 pode medir."
  _rc2=0; ONION_HOUSE_CODE_STOP=off bash "${BASH_SOURCE[0]}" stop < "${_in}" >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 2 ] && grep -q 'r13 → ' <<< "${_o}" && grep -q 'estrita' <<< "${_o}" && [ "${_rc2}" -eq 0 ]; then _ok "(n) política alta barra o literal na 1ª vez (rc 2); off nunca barra (rc 0)"; else _ko "(n) alta rc=${_rc} [${_o}] · off rc=${_rc2}"; fi
  # (o) ORDEM DE LEITURA no mesmo turno: glosa num bloco ANTERIOR cobre o seguinte (rc 0); glosa só
  #     num bloco POSTERIOR chega tarde e não cobre o anterior (rc 2) — política alta para isolar a ordem
  _mk "u:e então?" "a:A rodada r13 do radar do Claude Code mede a 2.1.302." "a:A r13 segue."
  _rc=0; ONION_HOUSE_CODE_STOP=alta bash "${BASH_SOURCE[0]}" stop < "${_in}" >/dev/null 2>&1 || _rc=$?
  _mk "u:e então?" "a:A r13 segue." "a:A rodada r13 do radar do Claude Code mede a 2.1.302."
  _rc2=0; ONION_HOUSE_CODE_STOP=alta bash "${BASH_SOURCE[0]}" stop < "${_in}" >/dev/null 2>&1 || _rc2=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 2 ]; then _ok "(o) glosa em bloco anterior cobre o seguinte (rc 0); glosa tardia não cobre (rc 2)"; else _ko "(o) antes rc=${_rc} (esperado 0) · tardia rc=${_rc2} (esperado 2)"; fi
  # (l) anti-loop: stop_hook_active=true sai 0 mesmo com reincidência
  _mk "u:e a rodada?" "a:A rodada r12 terminou." "u:e agora?" "a:a rodada r13 pode medir."
  printf '{"transcript_path":"%s","stop_hook_active":true}' "${_tp}" > "${_d}/in2.json"
  _rc=0; bash "${BASH_SOURCE[0]}" stop < "${_d}/in2.json" >/dev/null 2>&1 || _rc=$?
  if [ "${_rc}" -eq 0 ]; then _ok "(l) stop_hook_active=true: sai 0 (anti-loop)"; else _ko "(l) rc=${_rc}"; fi
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
case "${mode}" in
  prompt) _engine prompt "${tp}"; exit 0 ;;
  stop)   _engine stop "${tp}"; exit $? ;;
  *)      exit 0 ;;
esac
