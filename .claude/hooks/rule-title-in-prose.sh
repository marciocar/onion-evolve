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

_check_text() {   # stdin: texto do assistente · stdout: linhas "N|forma-correta" das menções sem título
  # O texto vai por ARQUIVO: `python3 - <<'PY'` já ocupa o stdin com o script (classe medida 3× em 2026-09-04).
  local tf; tf="$(mktemp)"; cat > "${tf}"
  python3 - "${LINT}" "${tf}" <<'PY'
import re, sys
lint, tf = sys.argv[1], sys.argv[2]
titles = {}
try:
    for line in open(lint, encoding="utf-8", errors="replace"):
        m = re.match(r"^# REGRA (\d+) — (.+?)\s*\[(?:HARD|SOFT)[^\]]*\]\s*$", line)
        if m: titles[int(m.group(1))] = m.group(2).strip()
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

if [ "${1:-}" = "--selftest" ]; then
  fails=0
  out="$(printf 'A REGRA 19 acusou e a REGRA 74 também.\n' | _check_text)"
  if printf '%s' "${out}" | grep -q '^19|REGRA 19 (Plugins de vertical' && printf '%s' "${out}" | grep -q '^74|REGRA 74 ('; then echo "  ✅ (a) menções sem título detectadas com a forma correta"; else echo "  ✗ (a): ${out}"; fails=$((fails+1)); fi
  out="$(printf 'A REGRA 19 (Plugins de vertical sincronizados) passou; veja `REGRA 74` em ```REGRA 62```.\n' | _check_text)"
  if [ -z "$(printf '%s' "${out}" | grep -v '^74|')" ] && printf '%s' "${out}" | grep -q '^74|'; then echo "  ✅ (b) titulada e bloco de código isentos; crase não isenta"; else echo "  ✗ (b): ${out}"; fails=$((fails+1)); fi
  out="$(printf 'Sem regra nenhuma aqui.\n' | _check_text)"
  if [ -z "${out}" ]; then echo "  ✅ (c) texto limpo = vazio"; else echo "  ✗ (c): ${out}"; fails=$((fails+1)); fi
  [ "${fails}" -eq 0 ] && { echo "rule-title-in-prose selftest: OK"; exit 0; }
  echo "rule-title-in-prose selftest: ${fails} falha(s)"; exit 1
fi

input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
active="$(printf '%s' "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("1" if d.get("stop_hook_active") else "0")' 2>/dev/null || echo 0)"
[ "${active}" = "1" ] && exit 0
tp="$(printf '%s' "${input}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null || true)"
[ -n "${tp}" ] && [ -f "${tp}" ] || exit 0

last="$(python3 - "${tp}" <<'PY'
import json, sys
last = ""
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try: j = json.loads(line)
    except Exception: continue
    if j.get("type") != "assistant": continue
    msg = j.get("message") or {}
    parts = []
    for c in msg.get("content") or []:
        if isinstance(c, dict) and c.get("type") == "text": parts.append(c.get("text", ""))
    if parts: last = "\n".join(parts)
print(last)
PY
)"
[ -n "${last}" ] || exit 0
offenders="$(printf '%s' "${last}" | _check_text)"
[ -n "${offenders}" ] || exit 0
{
  printf '🔏 REGRA citada SEM TÍTULO na sua última resposta (decisão do maestro 2026-09-03: número = chave, título = significado). Reescreva a resposta usando a forma completa:\n'
  printf '%s\n' "${offenders}" | cut -d'|' -f2 | sed 's/^/  · /'
} >&2
exit 2
