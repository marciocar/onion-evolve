#!/usr/bin/env bash
# ===========================================================================
# meeting-graph-check.sh — o GATE do grafo de reunião (`/product:extract-meeting`, saída `.kg.yaml`).
#
# POR QUE EXISTE: até 2026-10-16 as peças de reunião do Onion convertiam texto em Markdown e paravam aí
# (nenhuma escrevia `.kg.yaml`). O extract passou a gravar também o grafo da reunião, e um grafo de
# reunião carrega duas promessas que o radar genérico não confere: (1) cada fato aponta o TRECHO da
# transcrição de onde saiu, e (2) o registro de AVISO aos participantes, no modelo aviso ≠ consentimento
# (absorvido por reescrita: registra cada tentativa de aviso e a resposta de cada participante, para de
# capturar quando alguém recusa e NUNCA declara consentimento legal — isso é juízo jurídico, não fato da
# transcrição). Este script cobra as duas e roda o radar por cima.
#
# Uso:  bash .claude/validation/meeting-graph-check.sh <grafo.kg.yaml> [--root <dir>]
#       bash .claude/validation/meeting-graph-check.sh --selftest
#   --root  diretório a que `meta.x_meeting_source` e os `trace:` são relativos (padrão: a raiz git do
#           grafo; sem git, o diretório corrente).
#
# O esquema que ele julga (gramática do .kg.yaml + chaves x_ desta família):
#   meta:  x_meeting_date "AAAA-MM-DD" · x_meeting_source "<transcrição relativa à raiz>" ·
#          x_capture_stopped_at "-" | "#L<n>" (onde a captura parou por recusa)
#   nó:    x_meeting_role: meeting | participant | notice_attempt | decision | action | risk
#          todo nó com papel leva trace: "<x_meeting_source>#L<a>[-L<b>]", linhas dentro do arquivo
#          notice_attempt: x_notice_channel (chat|voz|convite|outro) · x_notice_text (o texto do aviso)
#          participant:    x_notice_ref (id de um notice_attempt) ·
#                          x_notice_response (ciente | recusou | sem_resposta | autora_do_aviso)
#          action:         x_owner (id de um participant, ou NAO_ESPECIFICADO)
#
# O que REPROVA (rc 1, um motivo por linha `MOTIVO\t<nó>\t<detalhe>` no stdout):
#   SEM-TENTATIVA-DE-AVISO · AVISO-INCOMPLETO · PARTICIPANTE-SEM-RESPOSTA · RESPOSTA-FORA-DO-ENUM ·
#   AVISO-REF-INEXISTENTE · CONSENTIMENTO-LEGAL-DECLARADO (chave com legal_consent/consentimento_legal) ·
#   RECUSA-SEM-PARADA (alguém recusou e x_capture_stopped_at é "-") · CAPTURA-APOS-RECUSA (fato com
#   trecho depois da linha da parada) · TRACE-AUSENTE · TRACE-FORA-DA-FONTE · TRACE-FORA-DO-ARQUIVO ·
#   PAPEL-DESCONHECIDO · SEM-REUNIAO · ACAO-SEM-DONO · META-INCOMPLETA · TRANSCRICAO-AUSENTE ·
#   CAMPO-FORA-DO-TIPO (impact fora de inteiro 1-5, confidence fora de número 0-1) ·
#   RADAR (o kg-radar.sh --integrity --schema reprovou o grafo) · CONTRATO (o kg-contract-check.sh
#   reprovou, onde ele mora ao lado e o contrato está vendorizado; sem ele, o "não julgado" é declarado).
# Exit: 0 conforme · 1 reprovado · 2 NÃO PUDE JULGAR (grafo ou radar ausente, python3 ausente,
#       argumento errado). rc 2 nunca é verde.
# Determinístico, sem LLM. Lê o formato estrito do radar (uma chave por linha, `- id:`), sem PyYAML.
# Exercitado por lint-selftest.sh (run_meeting_graph_selftests).
# ===========================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADAR="${HERE}/kg-radar.sh"
FIX="${HERE}/fixtures/meeting-graph"

command -v python3 >/dev/null 2>&1 || { echo "meeting-graph-check: python3 ausente — não pude julgar" >&2; exit 2; }

_check() {   # <grafo> <raiz>
  local g="$1" root="$2" out rc rout rrc
  out="$(python3 -I -B - "${g}" "${root}" <<'PY'
import os, re, sys
g, root = sys.argv[1], sys.argv[2]
ROLES = {"meeting", "participant", "notice_attempt", "decision", "action", "risk"}
RESP = {"ciente", "recusou", "sem_resposta", "autora_do_aviso"}
CHAN = {"chat", "voz", "convite", "outro"}
bad = []
def fail(code, nid, why): bad.append(f"{code}\t{nid}\t{why}")
def val(line):
    v = line.split(":", 1)[1].strip()
    v = re.sub(r"\s+#.*$", "", v) if not v.startswith(('"', "'")) else v
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'": v = v[1:-1]
    return v
meta, nodes, cur, sec = {}, [], None, None
legal = []
for raw in open(g, encoding="utf-8"):
    line = raw.rstrip("\n").rstrip("\r")
    if re.match(r"^\S", line):
        sec = line.split(":", 1)[0].strip(); cur = None; continue
    s = line.strip()
    if not s or s.startswith("#"): continue
    key = s[2:] if s.startswith("- ") else s
    k = key.split(":", 1)[0].strip() if ":" in key else ""
    if re.search(r"legal_consent|consentimento_legal", k, re.I): legal.append(k)
    if sec == "meta" and re.match(r"^  [A-Za-z_]", line) and k: meta[k] = val(key)
    elif sec == "nodes":
        if s.startswith("- id:"): cur = {"id": val(s[2:])}; nodes.append(cur)
        elif cur is not None and re.match(r"^    [A-Za-z_]", line) and k and k not in cur: cur[k] = val(key)
for k in legal:
    fail("CONSENTIMENTO-LEGAL-DECLARADO", "-", f"chave {k}: o grafo registra aviso e resposta, nunca consentimento legal")
src = meta.get("x_meeting_source", "")
for k in ("x_meeting_date", "x_meeting_source", "x_capture_stopped_at"):
    if not meta.get(k): fail("META-INCOMPLETA", "meta", f"falta {k}")
if meta.get("x_meeting_date") and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", meta["x_meeting_date"]):
    fail("META-INCOMPLETA", "meta", "x_meeting_date fora de AAAA-MM-DD")
nlines = None
if src:
    p = os.path.join(root, src)
    if os.path.isfile(p):
        with open(p, encoding="utf-8", errors="replace") as fh: nlines = sum(1 for _ in fh)
    else: fail("TRANSCRICAO-AUSENTE", "meta", f"x_meeting_source não existe sob a raiz: {src}")
stop = meta.get("x_capture_stopped_at", "")
stop_line = None
if stop and stop != "-":
    m = re.fullmatch(r"#L(\d+)", stop)
    if m: stop_line = int(m.group(1))
    else: fail("META-INCOMPLETA", "meta", "x_capture_stopped_at fora de \"-\" ou \"#L<n>\"")
roles = {}
for n in nodes:
    r = n.get("x_meeting_role")
    if r is None: continue
    roles[n["id"]] = r
    if r not in ROLES: fail("PAPEL-DESCONHECIDO", n["id"], f"x_meeting_role {r}"); continue
    if not re.fullmatch(r"[1-5]", n.get("impact", "")):
        fail("CAMPO-FORA-DO-TIPO", n["id"], f"impact {n.get('impact', '(ausente)')!r}: inteiro de 1 a 5")
    c = n.get("confidence", "")
    if not (re.fullmatch(r"(0(\.\d+)?|1(\.0+)?)", c)):
        fail("CAMPO-FORA-DO-TIPO", n["id"], f"confidence {c or '(ausente)'!r}: número de 0 a 1")
    t = n.get("trace", "")
    if not t: fail("TRACE-AUSENTE", n["id"], "nó de reunião sem trace ao trecho"); continue
    m = re.fullmatch(r"(.+)#L(\d+)(?:-L(\d+))?", t)
    if not m or m.group(1) != src:
        fail("TRACE-FORA-DA-FONTE", n["id"], f"trace {t!r} não é {src}#L<a>[-L<b>]"); continue
    a = int(m.group(2)); b = int(m.group(3) or a)
    if a < 1 or b < a or (nlines is not None and b > nlines):
        fail("TRACE-FORA-DO-ARQUIVO", n["id"], f"linhas {a}-{b} fora de 1-{nlines}")
    n["_from"] = a
by = {n["id"]: n for n in nodes}
if "meeting" not in roles.values(): fail("SEM-REUNIAO", "-", "nenhum nó x_meeting_role: meeting")
notices = [i for i, r in roles.items() if r == "notice_attempt"]
if not notices:
    fail("SEM-TENTATIVA-DE-AVISO", "-", "reunião sem tentativa de aviso registrada (x_meeting_role: notice_attempt)")
for i in notices:
    n = by[i]
    if n.get("x_notice_channel") not in CHAN or not n.get("x_notice_text"):
        fail("AVISO-INCOMPLETO", i, "x_notice_channel (chat|voz|convite|outro) e x_notice_text são obrigatórios")
refused = False
for i, r in roles.items():
    n = by[i]
    if r == "participant":
        resp = n.get("x_notice_response")
        if not resp: fail("PARTICIPANTE-SEM-RESPOSTA", i, "falta x_notice_response")
        elif resp not in RESP: fail("RESPOSTA-FORA-DO-ENUM", i, f"x_notice_response {resp} (enum: {'|'.join(sorted(RESP))})")
        if resp == "recusou": refused = True
        ref = n.get("x_notice_ref", "")
        # sem NENHUMA tentativa de aviso o motivo é um só (SEM-TENTATIVA-DE-AVISO); a ref vazia é consequência
        if notices and roles.get(ref) != "notice_attempt": fail("AVISO-REF-INEXISTENTE", i, f"x_notice_ref {ref or '(vazio)'} não é um notice_attempt")
    if r == "action":
        o = n.get("x_owner", "")
        if not (o == "NAO_ESPECIFICADO" or roles.get(o) == "participant"):
            fail("ACAO-SEM-DONO", i, f"x_owner {o or '(vazio)'} não é participant nem NAO_ESPECIFICADO")
if refused and stop_line is None:
    fail("RECUSA-SEM-PARADA", "meta", "alguém recusou o aviso e x_capture_stopped_at é \"-\": a captura tem de parar na recusa")
if stop_line is not None:
    for i, r in roles.items():
        if r in ("decision", "action", "risk") and by[i].get("_from", 0) > stop_line:
            fail("CAPTURA-APOS-RECUSA", i, f"trecho começa na linha {by[i]['_from']}, depois da parada em #L{stop_line}")
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY
)"; rc=$?
  [ -n "${out}" ] && printf '%s\n' "${out}"
  [ "${rc}" -le 1 ] || { echo "meeting-graph-check: o leitor falhou (rc ${rc}) — não pude julgar" >&2; return 2; }
  [ -f "${RADAR}" ] || { echo "meeting-graph-check: kg-radar.sh ausente ao lado (${RADAR}) — integridade não julgada" >&2; return 2; }
  # O CONTRATO do .kg.yaml, onde ele está vendorizado (vendor/kg-ssot) e o checador mora ao lado. rc 2 dele
  # ("não pude julgar": vendor ausente, como num plugin) é DECLARADO, não reprova nem vira verde calado.
  if [ -f "${HERE}/kg-contract-check.sh" ]; then
    local cout crc
    cout="$(cd "${root}" && LC_ALL=C bash "${HERE}/kg-contract-check.sh" "$(realpath -- "${g}")" 2>&1)"; crc=$?
    case "${crc}" in
      0) ;;
      1) printf 'CONTRATO	-	kg-contract-check.sh reprovou: %s
' "$(grep -E 'MUST|SHOULD' <<< "${cout}" | head -3 | tr -s ' ' | tr '\n' ' ')"; rc=1 ;;
      *) echo "meeting-graph-check: ⚠️ contrato do .kg.yaml NÃO julgado aqui (kg-contract-check.sh saiu ${crc}: vendor ausente?) — os campos de tipo seguem cobrados por este gate" >&2 ;;
    esac
  else
    echo "meeting-graph-check: ⚠️ contrato do .kg.yaml NÃO julgado aqui (kg-contract-check.sh não mora ao lado) — os campos de tipo seguem cobrados por este gate" >&2
  fi
  rout="$(LC_ALL=C bash "${RADAR}" "${g}" --integrity --schema 2>&1)"; rrc=$?
  if [ "${rrc}" -ne 0 ]; then
    printf 'RADAR\t-\tkg-radar.sh --integrity --schema saiu %s: %s\n' "${rrc}" "$(grep -E '✗|❌' <<< "${rout}" | head -3 | tr '\n' ' ')"
    rc=1
  fi
  return "${rc}"
}

if [ "${1:-}" = "--selftest" ]; then
  # Polaridades sobre CÓPIAS do grafo bom da bancada (fixture fictícia, nenhum dado real). Cada caso
  # reprova pelo MOTIVO nomeado — reprovar por outro motivo não conta.
  [ -f "${FIX}/meeting-ok.kg.yaml" ] && [ -f "${FIX}/transcript-ok.txt" ] \
    || { echo "meeting-graph-check: fixtures da bancada ausentes (${FIX}) — selftest não pôde rodar" >&2; exit 2; }
  T="$(TMPDIR="${TMPDIR:-/tmp}" mktemp -d)"; trap 'rm -rf "${T}"' EXIT
  mkdir -p "${T}/.claude/validation/fixtures/meeting-graph"
  cp "${FIX}/transcript-ok.txt" "${T}/.claude/validation/fixtures/meeting-graph/"
  G="${T}/g.kg.yaml"; P=0; F=0
  _case() {   # <nome> <motivo-esperado|OK|SO:motivo> <python que muta o texto em s>   (SO: = o ÚNICO motivo)
    local name="$1" want="$2" mut="$3" o r only=0
    case "${want}" in SO:*) only=1; want="${want#SO:}" ;; esac
    python3 -I -B -c "import sys; s=open(sys.argv[1]).read(); ${mut}; open(sys.argv[2],'w').write(s)" "${FIX}/meeting-ok.kg.yaml" "${G}"
    o="$(_check "${G}" "${T}" 2>/dev/null)"; r=$?
    if [ "${only}" -eq 1 ] && [ "$(grep -c . <<< "${o}")" -ne 1 ]; then r=99; fi
    if { [ "${want}" = "OK" ] && [ "${r}" -eq 0 ]; } || { [ "${want}" != "OK" ] && [ "${r}" -eq 1 ] && grep -q "^${want}	" <<< "${o}"; }; then
      echo "✅ ${name}"; P=$((P+1))
    else echo "✗ ${name} (rc ${r}; esperado ${want}; saída: $(tr '\n' '|' <<< "${o}"))"; F=$((F+1)); fi
  }
  _case "grafo bom passa" OK "pass"
  _case "sem tentativa de aviso reprova" SEM-TENTATIVA-DE-AVISO "s=s.replace('x_meeting_role: notice_attempt','x_meeting_role: decision',1)"
  _case "sem aviso, com refs '-', reprova por um motivo só" SO:SEM-TENTATIVA-DE-AVISO "import re; s=re.sub(r'  - id: NOTICE_1\n.*?(?=\n  - id: )','',s,count=1,flags=re.S); s=re.sub(r'  - from: NOTICE_1\n    to: MEETING\n    edge_type: SUPPORTS\n','',s,1); s=s.replace('x_notice_ref: NOTICE_1','x_notice_ref: \"-\"').replace('autora_do_aviso','sem_resposta').replace('x_notice_response: ciente','x_notice_response: sem_resposta')"
  _case "aviso sem texto reprova" AVISO-INCOMPLETO "import re; s=re.sub(r'\n    x_notice_text:[^\n]*','',s,1)"
  _case "participante sem resposta reprova" PARTICIPANTE-SEM-RESPOSTA "s=s.replace('    x_notice_response: ciente\n','',1)"
  _case "resposta 'consentiu' reprova" RESPOSTA-FORA-DO-ENUM "s=s.replace('x_notice_response: ciente','x_notice_response: consentiu',1)"
  _case "ref de aviso inexistente reprova" AVISO-REF-INEXISTENTE "s=s.replace('x_notice_ref: NOTICE_1','x_notice_ref: NOTICE_9',1)"
  _case "consentimento legal declarado reprova" CONSENTIMENTO-LEGAL-DECLARADO "s=s.replace('  x_capture_stopped_at: \"-\"\n','  x_capture_stopped_at: \"-\"\n  x_legal_consent: true\n',1)"
  _case "recusa sem parada reprova" RECUSA-SEM-PARADA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1)"
  _case "recusa com parada antes da decisão reprova" CAPTURA-APOS-RECUSA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L5\"',1)"
  _case "recusa com parada depois dos fatos passa" OK "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L10\"',1)"
  _case "nó sem trace reprova" TRACE-AUSENTE "import re; s=re.sub(r'\n    trace: \"[^\"]*#L9\"','',s,1)"
  _case "trace para outro arquivo reprova" TRACE-FORA-DA-FONTE "s=s.replace('transcript-ok.txt#L9','outra.txt#L9',1)"
  _case "trace além do fim do arquivo reprova" TRACE-FORA-DO-ARQUIVO "s=s.replace('transcript-ok.txt#L9','transcript-ok.txt#L99',1)"
  _case "ação sem dono reprova" ACAO-SEM-DONO "s=s.replace('x_owner: P_CARLA_MODELO','x_owner: ALGUEM',1)"
  _case "papel desconhecido reprova" PAPEL-DESCONHECIDO "s=s.replace('x_meeting_role: risk','x_meeting_role: rumor',1)"
  _case "transcrição ausente reprova" TRANSCRICAO-AUSENTE "s=s.replace('x_meeting_source: \".claude/validation/fixtures/meeting-graph/transcript-ok.txt\"','x_meeting_source: \"sumiu.txt\"',1)"
  _case "confidence em texto reprova" CAMPO-FORA-DO-TIPO "s=s.replace('confidence: 0.6','confidence: high',1)"
  _case "impact em texto reprova" CAMPO-FORA-DO-TIPO "s=s.replace('impact: 2','impact: medium',1)"
  _case "radar reprova o órfão" RADAR "import re; s=re.sub(r'  - from: R_LIB_PDF_SEM_MANUTENCAO\n    to: D_RELATORIO_PDF_PLANILHA\n    edge_type: CONSTRAINS\n','',s,1)"
  echo "meeting-graph selftest: ${P} passaram, ${F} falharam"
  [ "${F}" -eq 0 ]; exit $?
fi

G=""; ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ -n "${2:-}" ] || { echo "meeting-graph-check: --root exige um diretório" >&2; exit 2; }; ROOT="$2"; shift ;;
    --*) echo "meeting-graph-check: opção desconhecida: $1" >&2; exit 2 ;;
    *) [ -z "${G}" ] || { echo "meeting-graph-check: argumento a mais: $1" >&2; exit 2; }; G="$1" ;;
  esac
  shift
done
[ -n "${G}" ] || { sed -n '/^# Uso:/,/^#   --root/p' "$0" >&2; exit 2; }
[ -f "${G}" ] || { echo "meeting-graph-check: grafo inexistente: ${G}" >&2; exit 2; }
if [ -z "${ROOT}" ]; then ROOT="$(git -C "$(dirname "${G}")" rev-parse --show-toplevel 2>/dev/null || pwd)"; fi
[ -d "${ROOT}" ] || { echo "meeting-graph-check: raiz inexistente: ${ROOT}" >&2; exit 2; }
_check "${G}" "${ROOT}"; rc=$?
case "${rc}" in
  0) echo "meeting-graph-check: ✅ ${G} conforme (aviso registrado, trace ao trecho, radar verde)" >&2 ;;
  1) echo "meeting-graph-check: ✗ ${G} REPROVADO" >&2 ;;
esac
exit "${rc}"
