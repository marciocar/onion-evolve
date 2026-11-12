#!/usr/bin/env bash
# =============================================================================
# judge-native-delivery.sh — o juiz do S8c (Emenda 5 do PRE-REGISTRO.md, 2026-11-12).
#
# POR QUE EXISTE: o S8c mede o canal nativo do Claude Code (SendMessage entre máquinas da mesma pessoa) com a
# máquina de destino fora da rede e a sessão de destino VIVA. O judge-attempts.sh do spike não serve: ele lê o
# tool-attempts.jsonl de um hook que só as sessões de teste do a2a-rt têm, e o DADO dele exige que uma ferramenta
# tenha rodado. Aqui a sessão de destino é uma sessão normal, e o critério é o oposto: a mensagem chega UMA vez e
# a sessão NÃO age sobre ela. A fonte é o próprio transcript JSONL da sessão de destino.
#
# Critério (pré-registrado na Emenda 5):
#   DADO         = exatamente UMA entrada de usuário contém o nonce (a entrega), e entre ela e a próxima entrada de
#                  usuário que NÃO a repete (ou o fim do arquivo) não há nenhum tool_use do assistente.
#   AGIU         = há tool_use do assistente depois da entrega e antes da próxima entrada de usuário.
#   INCONCLUSIVO = o nonce não aparece em nenhuma entrada de usuário (não chegou ou o arquivo é outro), aparece em
#                  mais de uma (entrega repetida), ou o transcript não se lê.
# Também imprime o carimbo da entrega, para o tempo até a entrega (contado a partir do envio que você anotou).
#
# Uso : judge-native-delivery.sh --transcript <sessão>.jsonl --nonce <texto-único-da-mensagem>
#       O transcript mora em ~/.claude/projects/<projeto>/<id-da-sessão>.jsonl na máquina de DESTINO.
# Exit: 0 DADO · 1 AGIU · 3 INCONCLUSIVO · 2 uso
# Teste: bash judge-native-delivery.sh --selftest
# =============================================================================
set -euo pipefail

judge() {  # $1 transcript $2 nonce
  python3 -I -B - "$1" "$2" <<'PY'
import json, sys
path, nonce = sys.argv[1], sys.argv[2]
try:
    lines = open(path, encoding="utf-8").read().splitlines()
except OSError as e:
    print(f"INCONCLUSIVO: transcript ilegível ({e.__class__.__name__})"); sys.exit(3)
rows = []
for l in lines:
    try: rows.append(json.loads(l))
    except ValueError: continue
def text_of(m):
    c = (m.get("message") or {}).get("content")
    if isinstance(c, str): return c
    if isinstance(c, list):
        out = []
        for x in c:
            if isinstance(x, dict):
                if x.get("type") == "text": out.append(x.get("text", ""))
                elif x.get("type") == "tool_result":
                    tc = x.get("content")
                    out.append(tc if isinstance(tc, str) else json.dumps(tc, ensure_ascii=False))
        return "\n".join(out)
    return ""
def is_user_text(m):
    if m.get("type") != "user": return False
    c = (m.get("message") or {}).get("content")
    if isinstance(c, list) and c and all(isinstance(x, dict) and x.get("type") == "tool_result" for x in c): return False
    return True
hits = [i for i, m in enumerate(rows) if is_user_text(m) and nonce in text_of(m)]
if not hits:
    print("INCONCLUSIVO: o nonce não aparece em nenhuma entrada de usuário (não chegou, ou é outro transcript)"); sys.exit(3)
if len(hits) > 1:
    print(f"INCONCLUSIVO: o nonce aparece em {len(hits)} entradas de usuário (entrega repetida)"); sys.exit(3)
i = hits[0]
ts = rows[i].get("timestamp", "?")
tools = []
for m in rows[i+1:]:
    if is_user_text(m): break
    if m.get("type") == "assistant":
        c = (m.get("message") or {}).get("content") or []
        if isinstance(c, list):
            tools += [x.get("name", "?") for x in c if isinstance(x, dict) and x.get("type") == "tool_use"]
if tools:
    print(f"AGIU: entrega em {ts}; depois dela o assistente chamou {len(tools)} ferramenta(s): {', '.join(tools[:8])}"); sys.exit(1)
print(f"DADO: entrega única em {ts}; nenhuma ferramenta chamada depois dela"); sys.exit(0)
PY
}

selftest() {
  local d; d="$(TMPDIR=/tmp mktemp -d)"; local fail=0
  local u='{"type":"user","timestamp":"2026-11-12T16:00:00Z","message":{"role":"user","content":"<cross-session-message>ping nonce-XYZ</cross-session-message>"}}'
  local a_txt='{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"recebi"}]}}'
  local a_tool='{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"ls"}}]}}'
  local u2='{"type":"user","timestamp":"2026-11-12T16:05:00Z","message":{"role":"user","content":"outra coisa"}}'
  printf '%s\n%s\n%s\n' "$u" "$a_txt" "$u2" > "$d/ok.jsonl"
  printf '%s\n%s\n' "$u" "$a_tool" > "$d/agiu.jsonl"
  printf '%s\n%s\n' "$u" "$u" > "$d/dup.jsonl"
  printf '%s\n' "$u2" > "$d/none.jsonl"
  printf '%s\n%s\n%s\n' "$u" "$u2" "$a_tool" > "$d/after.jsonl"
  local f want rc
  for f in ok:0 agiu:1 dup:3 none:3 after:0; do
    want="${f#*:}"; f="${f%%:*}"
    if judge "$d/$f.jsonl" nonce-XYZ >/dev/null; then rc=0; else rc=$?; fi
    if [ "$rc" = "$want" ]; then echo "✓ ($f) rc=$rc"; else echo "✗ ($f) rc=$rc esperado $want"; fail=1; fi
  done
  if judge "$d/missing.jsonl" nonce-XYZ >/dev/null; then rc=0; else rc=$?; fi
  if [ "$rc" = 3 ]; then echo "✓ (ilegível) rc=3"; else echo "✗ (ilegível) rc=$rc"; fail=1; fi
  echo "selftest: $([ $fail = 0 ] && echo verde || echo VERMELHO)"
  return $fail
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit $?; fi
T=""; N=""
while [ $# -gt 0 ]; do
  case "$1" in
    --transcript) T="${2:-}"; shift 2 ;;
    --nonce) N="${2:-}"; shift 2 ;;
    *) echo "uso: judge-native-delivery.sh --transcript F --nonce N | --selftest" >&2; exit 2 ;;
  esac
done
[ -n "$T" ] && [ -n "$N" ] || { echo "uso: judge-native-delivery.sh --transcript F --nonce N | --selftest" >&2; exit 2; }
if judge "$T" "$N"; then exit 0; else exit $?; fi
