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
#   aviso:   SEM-TENTATIVA-DE-AVISO · AVISO-INCOMPLETO · AVISO-FORA-DO-TRECHO (o texto não está na linha
#            citada) · AVISO-DEPOIS-DOS-FATOS · PARTICIPANTE-SEM-RESPOSTA · RESPOSTA-FORA-DO-ENUM ·
#            AVISO-REF-INEXISTENTE · SEM-PARTICIPANTE · CONSENTIMENTO-LEGAL-DECLARADO (qualquer chave com
#            "consent" no nome, em qualquer grafia)
#   recusa:  RECUSA-SEM-PARADA · PARADA-DEPOIS-DA-RECUSA · CAPTURA-APOS-RECUSA (fato cujo trecho TERMINA
#            depois da parada)
#   trecho:  TRACE-AUSENTE · TRACE-FORA-DA-FONTE · TRACE-FORA-DO-ARQUIVO · TRANSCRICAO-AUSENTE ·
#            FONTE-FORA-DA-RAIZ (absoluto ou `..` que sai da raiz)
#   forma:   PAPEL-AUSENTE (todo nó leva x_meeting_role) · PAPEL-DESCONHECIDO · SEM-REUNIAO · ACAO-SEM-DONO ·
#            META-INCOMPLETA · CAMPO-FORA-DO-TIPO (impact fora de inteiro 1-5, confidence fora de 0-1)
#   corpus:  RADAR (kg-radar.sh --integrity --schema reprovou) · CONTRATO (kg-contract-check.sh reprovou,
#            onde ele mora ao lado e o contrato está vendorizado; sem ele, o "não julgado" é declarado)
# O leitor: comentário (`#`, qualquer coluna) nunca abre seção; as chaves de um nó são as da indentação do
# `- id:` + 2, qualquer que seja ela.
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
FACTS = ("decision", "action", "risk")
RESP = {"ciente", "recusou", "sem_resposta", "autora_do_aviso"}
CHAN = {"chat", "voz", "convite", "outro"}
bad = []
def fail(code, nid, why): bad.append(f"{code}\t{nid}\t{why}")
def val(line):
    v = line.split(":", 1)[1].strip()
    v = re.sub(r"\s+#.*$", "", v) if not v.startswith(('"', "'")) else v
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'": v = v[1:-1]
    return v
def ind(line): return len(line) - len(line.lstrip(" "))
# LEITOR: a forma estrita do radar, mas sem confiar em coluna fixa. Comentário (`#` em qualquer coluna) NUNCA
# abre seção — o 1º leitor tratava `# ── decisões ──` na coluna 0 como seção nova e cegava o gate para os nós
# seguintes (achado 1 do refutador). Seção = chave de topo `^[A-Za-z_]...:`. As chaves de um nó são as da
# indentação do `- id:` + 2, qualquer que seja ela (achado 2: `- id:` com 4 espaços escapava).
meta, nodes, cur, sec, nodecol = {}, [], None, None, None
consent_keys = []
for raw in open(g, encoding="utf-8"):
    line = raw.rstrip("\n").rstrip("\r")
    s = line.strip()
    if not s or s.startswith("#"): continue
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", line)
    if m: sec = m.group(1); cur = None; nodecol = None; continue
    key = s[2:] if s.startswith("- ") else s
    k = key.split(":", 1)[0].strip() if ":" in key else ""
    # qualquer chave que fale de consentimento, em qualquer grafia (legal_consent, legalConsent, x_lgpd_consent,
    # consentimento_legal…): o modelo registra AVISO e RESPOSTA, e consentimento é juízo jurídico (achado 7)
    if re.search(r"consent", re.sub(r"[_\-]", "", k.lower())): consent_keys.append(k)
    if sec == "meta" and ind(line) == 2 and k: meta[k] = val(key)
    elif sec == "nodes":
        if re.match(r"^- id:", s):
            cur = {"id": val(s[2:])}; nodes.append(cur); nodecol = ind(line)
        elif cur is not None and ind(line) == nodecol + 2 and k and k not in cur: cur[k] = val(key)
for k in consent_keys:
    fail("CONSENTIMENTO-LEGAL-DECLARADO", "-", f"chave {k}: o grafo registra aviso e resposta, nunca consentimento")
src = meta.get("x_meeting_source", "")
for k in ("x_meeting_date", "x_meeting_source", "x_capture_stopped_at"):
    if not meta.get(k): fail("META-INCOMPLETA", "meta", f"falta {k}")
if meta.get("x_meeting_date") and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", meta["x_meeting_date"]):
    fail("META-INCOMPLETA", "meta", "x_meeting_date fora de AAAA-MM-DD")
lines = None
if src:
    rr = os.path.realpath(root); p = os.path.realpath(os.path.join(root, src))
    # a fonte MORA na raiz: absoluto ou `..` que sai dela não é trecho reverificável (achado 5)
    if os.path.isabs(src) or not (p == rr or p.startswith(rr + os.sep)):
        fail("FONTE-FORA-DA-RAIZ", "meta", f"x_meeting_source {src} é absoluto ou sai da raiz")
    elif os.path.isfile(p):
        with open(p, encoding="utf-8", errors="replace") as fh: lines = [x.rstrip("\r\n") for x in fh]
    else: fail("TRANSCRICAO-AUSENTE", "meta", f"x_meeting_source não existe sob a raiz: {src}")
nlines = len(lines) if lines is not None else None
stop = meta.get("x_capture_stopped_at", "")
stop_line = None
if stop and stop != "-":
    m = re.fullmatch(r"#L(\d+)", stop)
    if m and int(m.group(1)) >= 1 and (nlines is None or int(m.group(1)) <= nlines): stop_line = int(m.group(1))
    else: fail("META-INCOMPLETA", "meta", f"x_capture_stopped_at {stop!r} fora de \"-\" ou \"#L<n>\" dentro do arquivo")
roles = {}
for n in nodes:
    r = n.get("x_meeting_role")
    # num grafo de reunião TODO nó tem papel: sem ele, o nó fugia de todas as regras (achado 2)
    if r is None: fail("PAPEL-AUSENTE", n["id"], "nó sem x_meeting_role num grafo de reunião"); continue
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
        fail("TRACE-FORA-DO-ARQUIVO", n["id"], f"linhas {a}-{b} fora de 1-{nlines}"); continue
    n["_from"], n["_to"] = a, b
by = {n["id"]: n for n in nodes}
if "meeting" not in roles.values(): fail("SEM-REUNIAO", "-", "nenhum nó x_meeting_role: meeting")
if "participant" not in roles.values(): fail("SEM-PARTICIPANTE", "-", "nenhum nó x_meeting_role: participant")
notices = [i for i, r in roles.items() if r == "notice_attempt"]
if not notices:
    fail("SEM-TENTATIVA-DE-AVISO", "-", "reunião sem tentativa de aviso registrada (x_meeting_role: notice_attempt)")
norm = lambda x: re.sub(r"\s+", " ", x).strip()
for i in notices:
    n = by[i]
    txt = norm(n.get("x_notice_text", ""))
    if n.get("x_notice_channel") not in CHAN or not txt:
        fail("AVISO-INCOMPLETO", i, "x_notice_channel (chat|voz|convite|outro) e x_notice_text são obrigatórios"); continue
    # o texto é VERBATIM do trecho citado (achado 8): aviso que não está na linha citada não foi dado ali
    if lines is not None and "_from" in n and txt not in norm(" ".join(lines[n["_from"] - 1:n["_to"]])):
        fail("AVISO-FORA-DO-TRECHO", i, "x_notice_text não aparece no trecho que o trace cita")
facts_from = [by[i]["_from"] for i, r in roles.items() if r in FACTS and "_from" in by[i]]
notice_from = [by[i]["_from"] for i in notices if "_from" in by[i]]
if facts_from and notice_from and min(notice_from) > min(facts_from):
    fail("AVISO-DEPOIS-DOS-FATOS", "-", f"o 1º aviso (#L{min(notice_from)}) vem depois do 1º fato (#L{min(facts_from)})")
refusal_lines = []
for i, r in roles.items():
    n = by[i]
    if r == "participant":
        resp = n.get("x_notice_response")
        if not resp: fail("PARTICIPANTE-SEM-RESPOSTA", i, "falta x_notice_response")
        elif resp not in RESP: fail("RESPOSTA-FORA-DO-ENUM", i, f"x_notice_response {resp} (enum: {'|'.join(sorted(RESP))})")
        if resp == "recusou": refusal_lines.append(n.get("_from", 0))
        ref = n.get("x_notice_ref", "")
        # sem NENHUMA tentativa de aviso o motivo é um só (SEM-TENTATIVA-DE-AVISO); a ref vazia é consequência
        if notices and roles.get(ref) != "notice_attempt": fail("AVISO-REF-INEXISTENTE", i, f"x_notice_ref {ref or '(vazio)'} não é um notice_attempt")
    if r == "action":
        o = n.get("x_owner", "")
        if not (o == "NAO_ESPECIFICADO" or roles.get(o) == "participant"):
            fail("ACAO-SEM-DONO", i, f"x_owner {o or '(vazio)'} não é participant nem NAO_ESPECIFICADO")
# A PARADA é amarrada à RECUSA (achado 3): existe, não passa da 1ª linha de recusa, e nenhum fato TERMINA depois dela
if refusal_lines and stop_line is None:
    fail("RECUSA-SEM-PARADA", "meta", "alguém recusou o aviso e x_capture_stopped_at é \"-\": a captura tem de parar na recusa")
if refusal_lines and stop_line is not None and stop_line > min(refusal_lines):
    fail("PARADA-DEPOIS-DA-RECUSA", "meta", f"a captura parou em #L{stop_line}, depois da 1ª recusa em #L{min(refusal_lines)}")
if stop_line is not None:
    for i, r in roles.items():
        if r in FACTS and by[i].get("_to", 0) > stop_line:
            fail("CAPTURA-APOS-RECUSA", i, f"trecho vai até a linha {by[i]['_to']}, depois da parada em #L{stop_line}")
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
  _case() {   # <nome> <motivo-esperado|OK|SO:motivo> <python que muta o texto em s> [raiz]   (SO: = o ÚNICO motivo)
    local name="$1" want="$2" mut="$3" croot="${4:-${T}}" o r only=0
    case "${want}" in SO:*) only=1; want="${want#SO:}" ;; esac
    python3 -I -B -c "import sys; s=open(sys.argv[1]).read(); ${mut}; open(sys.argv[2],'w').write(s)" "${FIX}/meeting-ok.kg.yaml" "${G}"
    o="$(_check "${G}" "${croot}" 2>/dev/null)"; r=$?
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
  _case "recusa com parada antes da decisão reprova" CAPTURA-APOS-RECUSA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L4\"',1)"
  _case "parada depois da recusa reprova" PARADA-DEPOIS-DA-RECUSA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L10\"',1)"
  _case "faixa que atravessa a parada reprova" CAPTURA-APOS-RECUSA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('transcript-ok.txt#L4\"','transcript-ok.txt#L9\"',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L9\"',1).replace('transcript-ok.txt#L9\"\n\nedges','transcript-ok.txt#L9-L10\"\n\nedges',1)"
  _case "parada além do fim do arquivo reprova" META-INCOMPLETA "s=s.replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L999\"',1)"
  _case "recusa no fim, com parada nela, passa" OK "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('transcript-ok.txt#L4\"','transcript-ok.txt#L10\"',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L10\"',1)"
  _case "comentário na coluna 0 não cega o leitor" RECUSA-SEM-PARADA "s=s.replace('  - id: P_BRUNO_EXEMPLO','# ── participantes ──\n  - id: P_BRUNO_EXEMPLO',1).replace('x_notice_response: ciente','x_notice_response: recusou',1)"
  _case "nó sem papel reprova" PAPEL-AUSENTE "s=s.replace('    x_meeting_role: decision\n','',1)"
  _case "nó com outra indentação é lido" TRACE-FORA-DA-FONTE "s=s.replace('  - id: R_LIB_PDF_SEM_MANUTENCAO\n    node_type: claim\n    x_meeting_role: risk\n    plane: DEV\n    status: open\n    impact: 3\n    confidence: 0.6\n','    - id: R_LIB_PDF_SEM_MANUTENCAO\n      node_type: claim\n      x_meeting_role: risk\n      plane: DEV\n      status: open\n      impact: 3\n      confidence: 0.6\n',1).replace('    trace: \".claude/validation/fixtures/meeting-graph/transcript-ok.txt#L9\"','      trace: \"outra.txt#L9\"',1)"
  _case "fonte absoluta reprova" FONTE-FORA-DA-RAIZ "s=s.replace('x_meeting_source: \".claude','x_meeting_source: \"/.claude',1)"
  _case "fonte que sai da raiz reprova" FONTE-FORA-DA-RAIZ "s=s.replace('x_meeting_source: \".claude','x_meeting_source: \"../x/.claude',1)"
  _case "reunião sem participante reprova" SEM-PARTICIPANTE "s=s.replace('x_meeting_role: participant','x_meeting_role: meeting').replace('x_owner: P_CARLA_MODELO','x_owner: NAO_ESPECIFICADO',1)"
  _case "consentimento em outra grafia reprova" CONSENTIMENTO-LEGAL-DECLARADO "s=s.replace('    x_notice_response: ciente\n','    x_notice_response: ciente\n    x_lgpdConsent: obtido\n',1)"
  _case "aviso só com espaço reprova" AVISO-INCOMPLETO "import re; s=re.sub(r'x_notice_text: \"[^\"]*\"','x_notice_text: \"   \"',s,1)"
  _case "aviso que não está no trecho reprova" AVISO-FORA-DO-TRECHO "s=s.replace('x_notice_text: \"Aviso:','x_notice_text: \"Outro aviso:',1)"
  _case "aviso depois dos fatos reprova" AVISO-DEPOIS-DOS-FATOS "s=s.replace('transcript-ok.txt#L3\"','transcript-ok.txt#L10\"',1).replace('x_notice_text: \"Aviso: esta reunião está sendo gravada e transcrita para virar ata e grafo. Quem não concordar, diga agora.\"','x_notice_text: \"Encerramos por hoje.\"',1)"
  _case "meta sem data reprova" META-INCOMPLETA "import re; s=re.sub(r'\n  x_meeting_date:[^\n]*','',s,1)"
  _case "sem nó de reunião reprova" SEM-REUNIAO "s=s.replace('x_meeting_role: meeting','x_meeting_role: risk',1)"
  _case "comentário que cita consentimento não reprova" OK "s=s.replace('nodes:\n','nodes:\n  # x_legal_consent: não se usa, o modelo é aviso e resposta\n',1)"
  _case "CRLF passa" OK "s=s.replace('\n','\r\n')"
  _case "nó sem trace reprova" TRACE-AUSENTE "import re; s=re.sub(r'\n    trace: \"[^\"]*#L9\"','',s,1)"
  _case "trace para outro arquivo reprova" TRACE-FORA-DA-FONTE "s=s.replace('transcript-ok.txt#L9','outra.txt#L9',1)"
  _case "trace além do fim do arquivo reprova" TRACE-FORA-DO-ARQUIVO "s=s.replace('transcript-ok.txt#L9','transcript-ok.txt#L99',1)"
  _case "ação sem dono reprova" ACAO-SEM-DONO "s=s.replace('x_owner: P_CARLA_MODELO','x_owner: ALGUEM',1)"
  _case "papel desconhecido reprova" PAPEL-DESCONHECIDO "s=s.replace('x_meeting_role: risk','x_meeting_role: rumor',1)"
  _case "transcrição ausente reprova" TRANSCRICAO-AUSENTE "s=s.replace('x_meeting_source: \".claude/validation/fixtures/meeting-graph/transcript-ok.txt\"','x_meeting_source: \"sumiu.txt\"',1)"
  _case "confidence em texto reprova" CAMPO-FORA-DO-TIPO "s=s.replace('confidence: 0.6','confidence: high',1)"
  _case "impact em texto reprova" CAMPO-FORA-DO-TIPO "s=s.replace('impact: 2','impact: medium',1)"
  _case "radar reprova o órfão" RADAR "import re; s=re.sub(r'  - from: R_LIB_PDF_SEM_MANUTENCAO\n    to: D_RELATORIO_PDF_PLANILHA\n    edge_type: CONSTRAINS\n','',s,1)"
  # O CONTRATO só julga onde o vendor existe (o core): o caso roda com a raiz do repo do checador, e fora dele
  # sai ⊘ declarado — nunca verde por vacuidade, nunca falha por ambiente.
  CROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "${CROOT}" ] && [ -f "${CROOT}/vendor/kg-ssot/tools/kg_gate.py" ] && [ -f "${HERE}/kg-contract-check.sh" ] \
     && [ -f "${CROOT}/.claude/validation/fixtures/meeting-graph/transcript-ok.txt" ]; then
    _case "contrato reprova o method fora da forma" CONTRATO "s=s.replace('method: \"leitura: trecho da transcrição da reunião\"','method: \"lido na transcrição\"',1)" "${CROOT}"
  else echo "⊘ contrato reprova o method fora da forma (vendor/kg-ssot ausente: não julgado aqui)"; fi
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
