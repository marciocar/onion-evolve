#!/usr/bin/env bash
# =============================================================================
# rule-title-in-prose.sh — hook Stop: "REGRA N" na PROSA do assistente vem sempre com o título
#
# POR QUÊ : decisão do maestro (2026-09-03): toda menção a uma regra é "REGRA N (Título da REGRA N)"
#           — o número é a chave, o título é o significado; sem ele o leitor não sabe do que se fala.
#           O lint já imprime assim (violation() → RULE_TITLE). A PROSA do assistente não tinha guarda
#           nenhuma e a reincidência aconteceu 2× (09-03 e 09-04, "REGRA 74", "REGRA 72"…). Gatilho
#           social é cura nula; este hook é a cura de mecanismo: lê a ÚLTIMA resposta do assistente no
#           transcript e, se houver "REGRA N" sem "(…)" logo depois, devolve exit 2 com a forma correta
#           — o assistente é obrigado a reescrever antes de encerrar o turno.
#
# COMO    : Stop recebe JSON com transcript_path e stop_hook_active. Se stop_hook_active=true (já
#           estamos num re-turno causado por este hook), sai 0 (anti-loop). Títulos vêm do SSOT:
#           os cabeçalhos "# REGRA N — Título [HARD]" de lint-artifacts.sh (nunca uma lista à mão).
#           Isenção: menção já titulada ("REGRA 74 (…)"), blocos de código (```…```) e saída de
#           ferramenta (o hook só olha o texto do assistente).
#
# USO     : registrado em .claude/settings.json → hooks.Stop. `--selftest` prova os 3 desfechos.
# =============================================================================
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="${HERE}/../validation/lint-artifacts.sh"
# As guardas de PLUGIN (REGRAS 72-75, 77, 79) saíram do lint para o checador da publicação na F4 das
# portas (2026-10-10); os títulos delas moram lá, no MESMO formato de cabeçalho. Ler os dois arquivos.
BUNDLE="${HERE}/../validation/plugin-bundle-check.sh"

_check_text() {   # stdin: texto do assistente · stdout: linhas "N|forma-correta" das menções sem título
  # O texto vai por ARQUIVO: `python3 - <<'PY'` já ocupa o stdin com o script (classe medida 3× em 2026-09-04).
  local tf; tf="$(mktemp)"; cat > "${tf}"
  python3 - "${LINT}" "${tf}" "${BUNDLE}" <<'PY'
import re, sys
lint, tf, bundle = sys.argv[1], sys.argv[2], sys.argv[3]
titles = {}
for src in (lint, bundle):
    try:
        for line in open(src, encoding="utf-8", errors="replace"):
            m = re.match(r"^# REGRA (\d+) — (.+?)\s*\[(?:HARD|SOFT)[^\]]*\]\s*$", line)
            if m: titles.setdefault(int(m.group(1)), m.group(2).strip())
    except Exception:
        pass
txt = open(tf, encoding="utf-8", errors="replace").read()
txt = re.sub(r"```.*?```", "", txt, flags=re.S)          # blocos de código não são prosa
seen = set()
for m in re.finditer(r"\bREGRA (\d+)\b(?!\s*\()", txt):
    n = int(m.group(1))
    # "REGRA 73/74", "REGRAs 72–76" e afins: a 1ª carrega o título; as demais da mesma cadeia passam
    tail = txt[m.end():m.end()+3]
    if tail[:1] in ("/", "–", "-", ",") and re.match(r"[/–,-]\s*\d", tail): continue
    if n in seen: continue
    seen.add(n)
    print(f"{n}|REGRA {n} ({titles.get(n, 'título não encontrado em lint-artifacts.sh')})")
PY
  rm -f "${tf}"
}

# A ÚLTIMA resposta do assistente que tem texto — lida da CAUDA do transcript (SAC-137, 2026-10-14).
# Antes: o arquivo INTEIRO parseado a cada turno (~0,55 s em 44,7 MB, sem timeout; a 2.1.300 faz o
# transcript crescer ~63 KB por resposta). Agora `lib/transcript-tail.py` lê de trás para frente até
# a 1ª linha que satisfaz o critério, com teto (ONION_STOP_HOOK_TAIL_MAX_BYTES) e fail-safe: estourou
# o teto sem achar, relê o arquivo inteiro como antes — falta de leitura nunca vira silêncio.
# Sem o lib (cópia parcial do .claude/), cai na leitura inteira de antes.
_last_text() {   # $1 = transcript · stdout: o texto da última resposta com bloco de texto
  python3 - "$1" "${HERE}/lib/transcript-tail.py" <<'PY'
import json, sys
tp, lib = sys.argv[1], sys.argv[2]
try:
    import importlib.util
    spec = importlib.util.spec_from_file_location("transcript_tail", lib)
    tt = importlib.util.module_from_spec(spec); spec.loader.exec_module(tt)
except Exception:
    tt = None
if tt is not None:
    rows = tt.tail_until(tp, tt.has_text)
    print(tt.assistant_text(rows[0]) if rows and tt.has_text(rows[0]) else "")
else:
    last = ""
    for line in open(tp, encoding="utf-8", errors="replace"):
        try: j = json.loads(line)
        except Exception: continue
        if j.get("type") != "assistant": continue
        parts = [c.get("text", "") for c in (j.get("message") or {}).get("content") or []
                 if isinstance(c, dict) and c.get("type") == "text"]
        if parts: last = "\n".join(parts)
    print(last)
PY
}

if [ "${1:-}" = "--selftest" ]; then
  fails=0
  out="$(printf 'A REGRA 21 acusou e a REGRA 74 também.\n' | _check_text)"
  # 74 mora no checador de bundle desde a F4: o título TEM de vir de lá, não de "não encontrado"
  if grep -q '^21|REGRA 21 (Grafo' <<< "${out}" && grep -q '^74|REGRA 74 (Caminho .claude/ NU' <<< "${out}"; then echo "  ✅ (a) menções sem título detectadas com a forma correta"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  out="$(printf 'A REGRA 21 (Grafo sincronizado) passou; veja `REGRA 74` em ```REGRA 62```.\n' | _check_text)"
  if [ -z "$(printf '%s' "${out}" | grep -v '^74|')" ] && grep -q '^74|' <<< "${out}"; then echo "  ✅ (b) titulada e bloco de código isentos; crase não isenta"; else echo "  ✗ (b): ${out}"; fails=$((fails+1)); fi
  # (d) 98-101 nasceram com cabeçalho `# REGRA N (Título) — HARD` e este hook as via como "título não
  #     encontrado" (medido 2026-10-11). A catraca nº7 do rules-registry.sh impede a forma voltar; aqui
  #     o hook prova que lê a ponta mais nova do registro.
  out="$(printf 'A REGRA 98 e a REGRA 101 acusaram.\n' | _check_text)"
  if grep -q '^98|REGRA 98 (Diretiva de injeção' <<< "${out}" && grep -q '^101|REGRA 101 (Veto PreToolUse' <<< "${out}"; then echo "  ✅ (d) regras mais novas (98, 101) resolvem o título"; else echo "  ✗ (d): ${out}"; fails=$((fails+1)); fi
  out="$(printf 'Sem regra nenhuma aqui.\n' | _check_text)"
  if [ -z "${out}" ]; then echo "  ✅ (c) texto limpo = vazio"; else echo "  ✗ (c): ${out}"; fails=$((fails+1)); fi

  # ══ PONTA-A-PONTA pela CAUDA (SAC-137): o hook como o harness o invoca, stdin JSON + transcript ══
  # (e) transcript GRANDE sintético (~20 MB, milhares de linhas antes do turno): o MESMO veredito da
  #     leitura inteira, pelo caminho "tail", lendo menos de 2 MiB e mais rápido que um parse inteiro.
  _d="$(mktemp -d)"; _tp="${_d}/t.jsonl"; _tr="${_d}/trace"; _in="${_d}/in.json"
  python3 - "${_tp}" <<'PY'
import json, sys
# o custo do parse está nas CHAVES e no aninhamento, não nos bytes (blob de 60 KB parseia quase de graça):
# rows com 25 chaves de metadado, como as do harness, para o parse inteiro custar o que custa de verdade
meta = {"k%02d" % i: "v%d" % i for i in range(25)}
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    fh.write(json.dumps({"type": "api-request-blob", "message": {"role": "user", "content": "x" * 60000}}) + "\n")
    for i in range(30000):
        u = dict(meta, type="user", message={"role": "user", "content": "pedido %d" % i})
        a = dict(meta, type="assistant", message={"content": [{"type": "text", "text": "A REGRA 21 passou."}]})
        t = dict(meta, type="assistant", message={"content": [{"type": "tool_use", "name": "Bash", "input": {"command": "ls %d" % i, "a": [1, {"b": i}]}}]})
        for r in (u, a, t):
            fh.write(json.dumps(r) + "\n")
    fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": "e agora?"}}) + "\n")
    fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": "A REGRA 74 acusou."}]}}) + "\n")
PY
  printf '{"transcript_path":"%s","stop_hook_active":false}' "${_tp}" > "${_in}"
  _t0="$(date +%s%N)"; _rc=0; _out="$(ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" bash "${BASH_SOURCE[0]}" < "${_in}" 2>&1)" || _rc=$?; _t1="$(date +%s%N)"
  _hook_ms=$(( (_t1 - _t0) / 1000000 ))
  _f0="$(date +%s%N)"; python3 -c 'import json,sys
for l in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try: json.loads(l)
    except Exception: pass' "${_tp}"; _f1="$(date +%s%N)"
  _full_ms=$(( (_f1 - _f0) / 1000000 ))
  _bytes="$(sed -n 's/^mode=tail bytes=\([0-9]*\)$/\1/p' "${_tr}" 2>/dev/null | tail -1)"
  if [ "${_rc}" -eq 2 ] && grep -q 'REGRA 74 (' <<< "${_out}" && ! grep -q 'REGRA 21 (' <<< "${_out}" \
     && [ -n "${_bytes}" ] && [ "${_bytes}" -lt 2097152 ] && [ "${_hook_ms}" -lt "${_full_ms}" ]; then
    echo "  ✅ (e) transcript de $(( $(stat -c %s "${_tp}") / 1048576 )) MiB: mesmo veredito pela CAUDA (${_bytes} bytes lidos, ${_hook_ms} ms < parse inteiro ${_full_ms} ms)"
  else echo "  ✗ (e) cauda: rc=${_rc} bytes=[${_bytes:-sem trace}] hook=${_hook_ms}ms parse-inteiro=${_full_ms}ms saida=[${_out}]"; fails=$((fails+1)); fi

  # (f) TETO ESTOURADO (a última resposta com texto além do teto): o fail-safe relê o arquivo inteiro e o
  #     veredito NÃO vira silêncio. Teto forçado a 4 KiB; a resposta fica ~150 KB antes do fim.
  python3 - "${_tp}" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": "vai"}}) + "\n")
    fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": "A REGRA 21 acusou."}]}}) + "\n")
    for i in range(300):
        fh.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {"command": "true " + "z" * 200}}]}}) + "\n")
        fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "content": "w" * 300}]}}) + "\n")
PY
  : > "${_tr}"; _rc=0; _out="$(ONION_STOP_HOOK_TAIL_MAX_BYTES=4096 ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" bash "${BASH_SOURCE[0]}" < "${_in}" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 2 ] && grep -q 'REGRA 21 (' <<< "${_out}" && grep -q '^mode=full' "${_tr}"; then
    echo "  ✅ (f) teto estourado sem achar a resposta → relê inteiro (mode=full) e o veredito se mantém"
  else echo "  ✗ (f) fail-safe: rc=${_rc} trace=[$(cat "${_tr}" 2>/dev/null)] saida=[${_out}]"; fails=$((fails+1)); fi
  rm -rf "${_d}"

  [ "${fails}" -eq 0 ] && { echo "rule-title-in-prose selftest: OK"; exit 0; }
  echo "rule-title-in-prose selftest: ${fails} falha(s)"; exit 1
fi

input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
active="$(printf '%s' "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("1" if d.get("stop_hook_active") else "0")' 2>/dev/null || echo 0)"
[ "${active}" = "1" ] && exit 0
tp="$(printf '%s' "${input}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null || true)"
[ -n "${tp}" ] && [ -f "${tp}" ] || exit 0

last="$(_last_text "${tp}")"
[ -n "${last}" ] || exit 0
offenders="$(printf '%s' "${last}" | _check_text)"
[ -n "${offenders}" ] || exit 0
{
  printf '🔏 REGRA citada SEM TÍTULO na sua última resposta (decisão do maestro 2026-09-03: número = chave, título = significado). Reescreva a resposta usando a forma completa:\n'
  printf '%s\n' "${offenders}" | cut -d'|' -f2 | sed 's/^/  · /'
} >&2
exit 2
