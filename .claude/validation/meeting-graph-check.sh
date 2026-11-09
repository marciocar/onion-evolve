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
#       bash .claude/validation/meeting-graph-check.sh --selftest ["<nome de um caso>"]
#   --root  diretório a que `meta.x_meeting_source` e os `trace:` são relativos (padrão: a raiz git do
#           grafo; sem git, o diretório corrente).
#
# O esquema que ele julga (gramática do .kg.yaml + chaves x_ desta família):
#   meta:  x_meeting_date "AAAA-MM-DD" · x_meeting_source "<transcrição relativa à raiz>" ·
#          x_capture_stopped_at "-" | "#L<n>" (onde a captura parou por recusa)
#   nó:    x_meeting_role: meeting | participant | notice_attempt | notice_absent | decision | action | risk
#          todo nó com papel leva trace: "<x_meeting_source>#L<a>[-L<b>]", linhas dentro do arquivo
#          notice_attempt: x_notice_channel (chat|voz|convite|outro) · x_notice_text (o texto do aviso)
#          notice_absent:  o registro de que NÃO HOUVE aviso. x_notice_absent_basis (como se sabe), status: open,
#                          impact 4 ou 5, trace cobrindo a transcrição inteira; exclui notice_attempt
#          participant:    x_notice_ref (id de um notice_attempt, ou do notice_absent) ·
#                          x_notice_response (ciente | recusou | sem_resposta | autora_do_aviso;
#                          com notice_absent, só nao_avisado | recusou)
#          action:         x_owner (id de um participant, ou NAO_ESPECIFICADO)
#
# AUSÊNCIA DE AVISO: reunião em que de fato não houve aviso não pode inventar um `notice_attempt`. O registro
# `notice_absent` passa na forma (rc 0) e sai como SOFT no stdout, `SOFT:AVISO-AUSENTE\t<nó>\t<n> pessoa(s)…`.
# Não é conformidade nem consentimento: é o risco declarado, e o nó fica aberto no corpus. Quem não registrou
# nada segue em SEM-TENTATIVA-DE-AVISO.
#
# O que REPROVA (rc 1, um motivo por linha `MOTIVO\t<nó>\t<detalhe>` no stdout):
#   aviso:   SEM-TENTATIVA-DE-AVISO · AVISO-INCOMPLETO · AVISO-FORA-DO-TRECHO (o texto não está na linha
#            citada) · AVISO-DEPOIS-DOS-FATOS · PARTICIPANTE-SEM-RESPOSTA · RESPOSTA-FORA-DO-ENUM ·
#            AVISO-REF-INEXISTENTE · SEM-PARTICIPANTE · CONSENTIMENTO-LEGAL-DECLARADO (qualquer chave com
#            "consent" no nome, em qualquer grafia)
#   ausência: AUSENCIA-COM-AVISO · AUSENCIA-DUPLICADA · AUSENCIA-SEM-BASE · AUSENCIA-SEM-DECLARACAO · AUSENCIA-FECHADA ·
#            AUSENCIA-IMPACTO-BAIXO · AUSENCIA-SEM-VARREDURA · RESPOSTA-SEM-AVISO · NAO-AVISADO-SEM-AUSENCIA
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
  local g root="$2" out rc rout rrc
  # caminho ABSOLUTO já: o contrato roda com `cd` na raiz, e um relativo saía "não julgado" com rc 0
  # (2ª passada do refutador, achado 3 — a mesma classe que o kg-decide-seal.sh já curou)
  g="$(realpath -- "$1")"
  out="$(python3 -I -B - "${g}" "${root}" <<'PY'
import os, re, sys, unicodedata
g, root = sys.argv[1], sys.argv[2]
ROLES = {"meeting", "participant", "notice_attempt", "notice_absent", "decision", "action", "risk"}
FACTS = ("decision", "action", "risk")
RESP = {"ciente", "recusou", "sem_resposta", "autora_do_aviso", "nao_avisado"}
ABSENT_RESP = {"nao_avisado", "recusou"}  # sem aviso, ninguém ficou ciente dele nem deixou de responder a ele
CHAN = {"chat", "voz", "convite", "outro"}
# VOCABULÁRIO FECHADO das extensões `x_` (2ª passada do refutador, achado 6): negar por substring deixava
# `x_autorizacao_lgpd: concedida` passar. Chave x_ fora destas listas reprova; o resto do nó é a gramática
# do .kg.yaml, que o radar e o contrato julgam.
META_X = {"x_meeting_date", "x_meeting_source", "x_capture_stopped_at", "x_cost_tokens"}
NODE_X = {"x_meeting_role", "x_notice_channel", "x_notice_text", "x_notice_ref", "x_notice_response",
          "x_owner", "x_due", "x_path_is_content", "x_notice_absent_basis"}
bad = []
def fail(code, nid, why): bad.append(f"{code}\t{nid}\t{why}")
nfc = lambda x: unicodedata.normalize("NFC", x)
def val(line):
    v = line.split(":", 1)[1].strip()
    if v[:1] == '"' and v[-1:] == '"' and len(v) >= 2: return nfc(v[1:-1].replace('\\"', '"'))
    if v[:1] == "'" and v[-1:] == "'" and len(v) >= 2: return nfc(v[1:-1].replace("''", "'"))
    return nfc(re.sub(r"\s+#.*$", "", v))
def ind(line): return len(line) - len(line.lstrip(" "))
# LEITOR: a forma estrita do radar, sem confiar em coluna fixa e sem deixar nada escapar calado.
#  · comentário (`#`, qualquer coluna) nunca abre seção; seção = chave de topo `^[A-Za-z_]...:` (1ª passada);
#  · conteúdo de bloco literal (`|`, `>`) é texto, não chave (um `- id:` dentro de label não cria nó);
#  · o 1º `- id:` fixa a coluna dos nós; as chaves do nó são SÓ as da coluna + 2, e item de lista dentro do nó
#    (`- x_notice_response: …` sob uma chave aninhada) NÃO é chave do nó (2ª passada, achado 1: sombreava a real);
#  · na coluna dos nós, todo item que não for `- id:` (estilo fluxo `- {id: …}`, `-   id:`) reprova (achado 2);
#  · chave repetida no nó reprova aqui, sem depender do radar.
meta, nodes, cur, sec, nodecol, block = {}, [], None, None, None, None
consent_keys, dup = [], []
for raw in open(g, encoding="utf-8"):
    line = raw.rstrip("\n")
    s = line.strip()
    if block is not None:
        if not s or ind(line) > block: continue
        block = None
    if not s or s.startswith("#"): continue
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", line)
    if m: sec = m.group(1); cur = None; nodecol = None; continue
    key = s[2:] if s.startswith("- ") else s
    k = key.split(":", 1)[0].strip() if ":" in key else ""
    if ":" in key and re.fullmatch(r"[|>][+-]?", key.split(":", 1)[1].strip()): block = ind(line)
    if re.search(r"consent", k.lower()): consent_keys.append(k)
    if sec == "meta" and ind(line) == 2 and k and not s.startswith("- "): meta[k] = val(key)
    elif sec == "nodes":
        if nodecol is None and s.startswith("-"): nodecol = ind(line)
        if ind(line) == nodecol and s.startswith("-"):
            if re.match(r"^- id:", s): cur = {"id": val(s[2:])}; nodes.append(cur)
            else: fail("NO-FORA-DA-FORMA", "-", f"item da lista de nós fora da forma `- id:`: {s[:60]}"); cur = None
        elif cur is not None and ind(line) == nodecol + 2 and k and not s.startswith("- "):
            if k in cur: dup.append((cur["id"], k))
            else: cur[k] = val(key)
for k in consent_keys:
    fail("CONSENTIMENTO-LEGAL-DECLARADO", "-", f"chave {k}: o grafo registra aviso e resposta, nunca consentimento")
for nid, k in dup: fail("CHAVE-DUPLICADA", nid, f"{k} aparece mais de uma vez no nó")
for k in meta:
    if k.startswith("x_") and k not in META_X: fail("CHAVE-X-DESCONHECIDA", "meta", f"{k} fora do vocabulário do grafo de reunião")
for n in nodes:
    for k in n:
        if k.startswith("x_") and k not in NODE_X: fail("CHAVE-X-DESCONHECIDA", n["id"], f"{k} fora do vocabulário do grafo de reunião")
src = os.path.normpath(meta.get("x_meeting_source", "")) if meta.get("x_meeting_source") else ""
for k in ("x_meeting_date", "x_meeting_source", "x_capture_stopped_at"):
    if not meta.get(k): fail("META-INCOMPLETA", "meta", f"falta {k}")
if meta.get("x_meeting_date") and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", meta["x_meeting_date"]):
    fail("META-INCOMPLETA", "meta", "x_meeting_date fora de AAAA-MM-DD")
lines = None
if src:
    rr = os.path.realpath(root); p = os.path.realpath(os.path.join(root, src))
    # a fonte MORA na raiz: absoluto ou `..` que sai dela não é trecho reverificável (1ª passada)
    if not (p == rr or p.startswith(rr + os.sep)):
        fail("FONTE-FORA-DA-RAIZ", "meta", f"x_meeting_source {src} é absoluto ou sai da raiz")
    elif os.path.isfile(p):
        with open(p, encoding="utf-8", errors="replace") as fh: lines = [nfc(x.rstrip("\r\n")) for x in fh]
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
    # num grafo de reunião TODO nó tem papel: sem ele, o nó fugia de todas as regras (1ª passada)
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
    if not m or os.path.normpath(m.group(1)) != src:
        fail("TRACE-FORA-DA-FONTE", n["id"], f"trace {t!r} não é {src}#L<a>[-L<b>]"); continue
    a = int(m.group(2)); b = int(m.group(3) or a)
    if a < 1 or b < a or (nlines is not None and b > nlines):
        fail("TRACE-FORA-DO-ARQUIVO", n["id"], f"linhas {a}-{b} fora de 1-{nlines}"); continue
    n["_from"], n["_to"] = a, b
by = {n["id"]: n for n in nodes}
if "meeting" not in roles.values(): fail("SEM-REUNIAO", "-", "nenhum nó x_meeting_role: meeting")
if "participant" not in roles.values(): fail("SEM-PARTICIPANTE", "-", "nenhum nó x_meeting_role: participant")
notices = [i for i, r in roles.items() if r == "notice_attempt"]
absences = [i for i, r in roles.items() if r == "notice_absent"]
absent_mode = bool(absences) and not notices
if not notices and not absences:
    fail("SEM-TENTATIVA-DE-AVISO", "-", "reunião sem tentativa de aviso registrada (x_meeting_role: notice_attempt) nem registro de que não houve aviso (notice_absent)")
norm = lambda x: re.sub(r"\s+", " ", x).strip()
if notices and absences:
    fail("AUSENCIA-COM-AVISO", absences[0], "o grafo declara aviso e ausência de aviso ao mesmo tempo")
if len(absences) > 1:
    fail("AUSENCIA-DUPLICADA", absences[1], "um só registro de ausência por reunião")
for i in absences:
    n = by[i]
    if len(norm(n.get("x_notice_absent_basis", ""))) < 20:
        fail("AUSENCIA-SEM-BASE", i, "x_notice_absent_basis diz como se sabe que não houve aviso (ao menos 20 caracteres)")
    # o próprio nó diz o que aconteceu: lido sozinho no corpus, ele não passa por regularidade
    if "não houve aviso" not in n.get("label", "").lower():
        fail("AUSENCIA-SEM-DECLARACAO", i, "o label diz, nestas palavras, que não houve aviso")
    if n.get("status") != "open":
        fail("AUSENCIA-FECHADA", i, f"status {n.get('status', '(ausente)')}: reunião sem aviso é risco aberto, nunca assunto encerrado")
    if n.get("impact") not in ("4", "5"):
        fail("AUSENCIA-IMPACTO-BAIXO", i, f"impact {n.get('impact', '(ausente)')}: de 4 a 5, para o risco não afundar no radar")
    # ausência é afirmação sobre a fonte inteira: quem leu um trecho não sabe se houve aviso no resto
    if "_from" in n and nlines is not None and (n["_from"] != 1 or n["_to"] != nlines):
        fail("AUSENCIA-SEM-VARREDURA", i, f"trace cobre #L{n['_from']}-L{n['_to']}: a ausência cita a transcrição inteira, #L1-L{nlines}")
for i in notices:
    n = by[i]
    txt = norm(n.get("x_notice_text", ""))
    if n.get("x_notice_channel") not in CHAN or not txt:
        fail("AVISO-INCOMPLETO", i, "x_notice_channel (chat|voz|convite|outro) e x_notice_text são obrigatórios"); continue
    if lines is None or "_from" not in n: continue
    cited = norm(" ".join(lines[n["_from"] - 1:n["_to"]]))
    # VERBATIM do trecho citado (1ª passada) E não um fragmento dele (2ª passada, achado 4: uma palavra
    # satisfazia a cobrança): o texto do aviso cobre ao menos metade do trecho e tem ao menos 20 caracteres.
    if txt not in cited:
        fail("AVISO-FORA-DO-TRECHO", i, "x_notice_text não aparece no trecho que o trace cita")
    elif len(txt) < 20 or len(txt) * 2 < len(cited):
        fail("AVISO-FRAGMENTO", i, f"x_notice_text cobre {len(txt)} de {len(cited)} caracteres do trecho: copie a fala do aviso inteira")
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
        elif absent_mode and resp not in ABSENT_RESP:
            fail("RESPOSTA-SEM-AVISO", i, f"x_notice_response {resp}: sem aviso, só {'|'.join(sorted(ABSENT_RESP))}")
        elif not absent_mode and resp == "nao_avisado":
            fail("NAO-AVISADO-SEM-AUSENCIA", i, "nao_avisado exige o registro notice_absent no grafo")
        # a recusa acontece no FIM do trecho do participante (quem entra em L11 e recusa em L13 cita L11-L13)
        if resp == "recusou": refusal_lines.append(n.get("_to", 0))
        ref = n.get("x_notice_ref", "")
        # sem NENHUM registro o motivo é um só (SEM-TENTATIVA-DE-AVISO); a ref vazia é consequência
        if absent_mode and roles.get(ref) != "notice_absent": fail("AVISO-REF-INEXISTENTE", i, f"x_notice_ref {ref or '(vazio)'} não é o notice_absent")
        if notices and roles.get(ref) != "notice_attempt": fail("AVISO-REF-INEXISTENTE", i, f"x_notice_ref {ref or '(vazio)'} não é um notice_attempt")
    if r == "action":
        o = n.get("x_owner", "")
        if not (o == "NAO_ESPECIFICADO" or roles.get(o) == "participant"):
            fail("ACAO-SEM-DONO", i, f"x_owner {o or '(vazio)'} não é participant nem NAO_ESPECIFICADO")
# A PARADA é amarrada à RECUSA: existe, não passa da 1ª recusa, e nada além do nó da reunião cita trecho
# que TERMINE depois dela (2ª passada, achado 7: participante e aviso também são captura)
if refusal_lines and stop_line is None:
    fail("RECUSA-SEM-PARADA", "meta", "alguém recusou o aviso e x_capture_stopped_at é \"-\": a captura tem de parar na recusa")
if refusal_lines and stop_line is not None and stop_line > min(refusal_lines):
    fail("PARADA-DEPOIS-DA-RECUSA", "meta", f"a captura parou em #L{stop_line}, depois da 1ª recusa em #L{min(refusal_lines)}")
if stop_line is not None:
    for i, r in roles.items():
        if r not in ("meeting", "notice_absent") and by[i].get("_to", 0) > stop_line:  # os dois falam da fonte, não capturam fato
            fail("CAPTURA-APOS-RECUSA", i, f"trecho vai até a linha {by[i]['_to']}, depois da parada em #L{stop_line}")
lines_out = list(bad)
if absent_mode:
    people = sum(1 for r in roles.values() if r == "participant")
    lines_out.append(f"SOFT:AVISO-AUSENTE\t{absences[0]}\t{people} pessoa(s) na reunião SEM aviso de gravação: risco de compliance aberto (LGPD). Este registro não é conformidade nem consentimento, e a análise jurídica não foi feita")
print("\n".join(lines_out))
sys.exit(1 if bad else 0)
PY
)"; rc=$?
  [ -n "${out}" ] && printf '%s\n' "${out}"
  case "${out}" in *"SOFT:AVISO-AUSENTE"*) NOTICE_ABSENT=1 ;; esac
  [ "${rc}" -le 1 ] || { echo "meeting-graph-check: o leitor falhou (rc ${rc}) — não pude julgar" >&2; return 2; }
  [ -f "${RADAR}" ] || { echo "meeting-graph-check: kg-radar.sh ausente ao lado (${RADAR}) — integridade não julgada" >&2; return 2; }
  # O CONTRATO do .kg.yaml, onde ele está vendorizado (vendor/kg-ssot) e o checador mora ao lado. rc 2 dele
  # ("não pude julgar": vendor ausente, como num plugin) é DECLARADO, não reprova nem vira verde calado.
  if [ -f "${HERE}/kg-contract-check.sh" ]; then
    local cout crc
    cout="$(cd "${root}" && LC_ALL=C bash "${HERE}/kg-contract-check.sh" "${g}" 2>&1)"; crc=$?
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
  # `--selftest "<nome do caso>"` roda SÓ esse caso: é o que o mutante da bancada usa (um mutante por cura,
  # e o caso que ele nomeia). Nome que não casa caso nenhum sai 1 — seleção vazia nunca é verde.
  ONLY="${2:-}"
  # Polaridades sobre CÓPIAS do grafo bom da bancada (fixture fictícia, nenhum dado real). Cada caso
  # reprova pelo MOTIVO nomeado — reprovar por outro motivo não conta.
  [ -f "${FIX}/meeting-ok.kg.yaml" ] && [ -f "${FIX}/transcript-ok.txt" ] && [ -f "${FIX}/meeting-notice-absent.kg.yaml" ] \
    || { echo "meeting-graph-check: fixtures da bancada ausentes (${FIX}) — selftest não pôde rodar" >&2; exit 2; }
  T="$(TMPDIR="${TMPDIR:-/tmp}" mktemp -d)"; trap 'rm -rf "${T}"' EXIT
  mkdir -p "${T}/.claude/validation/fixtures/meeting-graph"
  cp "${FIX}/transcript-ok.txt" "${FIX}/transcript-no-notice.txt" "${T}/.claude/validation/fixtures/meeting-graph/"
  G="${T}/g.kg.yaml"; P=0; F=0
  BASE="${FIX}/meeting-ok.kg.yaml"
  _case() {   # <nome> <motivo-esperado|OK|SO:motivo|SOFT:<trecho da linha SOFT>> <python que muta o texto em s> [raiz]   (SO: = o ÚNICO motivo)
    local name="$1" want="$2" mut="$3" croot="${4:-${T}}" o r only=0
    [ -z "${ONLY}" ] || [ "${name}" = "${ONLY}" ] || return 0
    case "${want}" in SO:*) only=1; want="${want#SO:}" ;; esac
    python3 -I -B -c "import sys; s=open(sys.argv[1]).read(); ${mut}; open(sys.argv[2],'w').write(s)" "${BASE}" "${G}"
    if [ "${5:-}" = "rel" ]; then o="$(cd "${T}" && _check "$(basename "${G}")" "${croot}" 2>/dev/null)"; r=$?
    else o="$(_check "${G}" "${croot}" 2>/dev/null)"; r=$?; fi
    if [ "${only}" -eq 1 ] && [ "$(grep -c . <<< "${o}")" -ne 1 ]; then r=99; fi
    if { [ "${want}" = "OK" ] && [ "${r}" -eq 0 ] && ! grep -q '^SOFT:' <<< "${o}"; } \
       || { [ "${want#SOFT:}" != "${want}" ] && [ "${r}" -eq 0 ] && grep -q "^SOFT:AVISO-AUSENTE	.*${want#SOFT:}" <<< "${o}"; } \
       || { [ "${want}" != "OK" ] && [ "${want#SOFT:}" = "${want}" ] && [ "${r}" -eq 1 ] && grep -q "^${want}	" <<< "${o}"; }; then
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
  _case "nó com outra indentação é lido" TRACE-FORA-DA-FONTE "import re; a=s.index('nodes:\\n')+7; b=s.index('\\nedges:'); s=s[:a]+re.sub(r'(?m)^(?=.)','  ',s[a:b])+s[b:]; s=s.replace('transcript-ok.txt#L9\\\"','outra.txt#L9\\\"',1)"
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
  _case "lista dentro do nó não sombreia a chave real" RECUSA-SEM-PARADA "s=s.replace('    x_notice_response: ciente\n','    tags:\n    - x_notice_response: ciente\n    x_notice_response: recusou\n',1)"
  _case "nó em estilo fluxo reprova" NO-FORA-DA-FORMA "s=s.replace('\nedges:','  - {id: D_SECRET, x_meeting_role: decision}\n\nedges:',1)"
  _case "texto de bloco literal não é chave" OK "s=s.replace('    label: \"Risco: a biblioteca','    narrative: |-\n      consent: isto é texto do bloco, não chave\n    label: \"Risco: a biblioteca',1)"
  _case "chave repetida no nó reprova" CHAVE-DUPLICADA "s=s.replace('    x_notice_response: ciente\n','    x_notice_response: ciente\n    x_notice_response: ciente\n',1)"
  _case "chave x fora do vocabulário reprova" CHAVE-X-DESCONHECIDA "s=s.replace('    x_notice_response: ciente\n','    x_notice_response: ciente\n    x_autorizacao_lgpd: concedida\n',1)"
  _case "aviso de uma palavra reprova" AVISO-FRAGMENTO "import re; s=re.sub(r'x_notice_text: \"[^\"]*\"','x_notice_text: \"Aviso\"',s,1)"
  _case "aviso citando outra linha reprova" AVISO-FORA-DO-TRECHO "s=s.replace('transcript-ok.txt#L3\"','transcript-ok.txt#L6\"',1)"
  _case "duas recusas: a parada vale pela 1ª" PARADA-DEPOIS-DA-RECUSA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou').replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L5\"',1)"
  _case "dois avisos: vale o 1º" OK "s=s.replace('  - id: P_ANA_TESTE','  - id: NOTICE_2\n    node_type: evidence\n    x_meeting_role: notice_attempt\n    x_notice_channel: voz\n    x_notice_text: \"Risco: a biblioteca de PDF que usamos está sem manutenção há um ano.\"\n    plane: DEV\n    status: open\n    impact: 2\n    confidence: 0.5\n    label: \"Segunda tentativa de aviso, fictícia.\"\n    trace: \".claude/validation/fixtures/meeting-graph/transcript-ok.txt#L9\"\n\n  - id: P_ANA_TESTE',1).replace('\nedges:\n','\nedges:\n\n  - from: NOTICE_2\n    to: MEETING\n    edge_type: SUPPORTS\n',1)"
  _case "fato que termina na linha da parada passa" OK "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('transcript-ok.txt#L4\"','transcript-ok.txt#L9\"',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L9\"',1)"
  _case "participante depois da parada reprova" CAPTURA-APOS-RECUSA "s=s.replace('x_notice_response: ciente','x_notice_response: recusou',1).replace('transcript-ok.txt#L4\"','transcript-ok.txt#L9\"',1).replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L9\"',1).replace('transcript-ok.txt#L5\"','transcript-ok.txt#L10\"',1)"
  _case "trace na linha 0 reprova" TRACE-FORA-DO-ARQUIVO "s=s.replace('transcript-ok.txt#L9\"','transcript-ok.txt#L0\"',1)"
  _case "faixa invertida reprova" TRACE-FORA-DO-ARQUIVO "s=s.replace('transcript-ok.txt#L6-L7','transcript-ok.txt#L7-L6',1)"
  _case "parada na linha 0 reprova" META-INCOMPLETA "s=s.replace('x_capture_stopped_at: \"-\"','x_capture_stopped_at: \"#L0\"',1)"
  _case "comentário no fim do valor é ignorado" OK "s=s.replace('    x_notice_response: ciente\n','    x_notice_response: ciente  # respondeu\n',1)"
  _case "fonte com ./ passa" OK "s=s.replace('x_meeting_source: \".claude','x_meeting_source: \"./.claude',1)"
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
  # ── AUSÊNCIA DE AVISO: passa na forma como SOFT, nunca como conformidade, e não abre brecha ──
  _case "aviso de verdade com nao_avisado reprova" NAO-AVISADO-SEM-AUSENCIA "s=s.replace('x_notice_response: ciente','x_notice_response: nao_avisado',1)"
  BASE="${FIX}/meeting-notice-absent.kg.yaml"
  NA_TXT='.claude/validation/fixtures/meeting-graph/transcript-no-notice.txt'
  _case "ausência registrada passa como SOFT, com a contagem" "SOFT:2 pessoa(s) na reunião SEM aviso" "pass"
  _case "ausência tirada do grafo volta a reprovar" SEM-TENTATIVA-DE-AVISO "s=s.replace('x_meeting_role: notice_absent','x_meeting_role: risk',1)"
  _case "ausência sem base reprova" AUSENCIA-SEM-BASE "import re; s=re.sub(r'\n    x_notice_absent_basis:[^\n]*','',s,1)"
  _case "ausência com base curta reprova" AUSENCIA-SEM-BASE "import re; s=re.sub(r'x_notice_absent_basis: \"[^\"]*\"','x_notice_absent_basis: \"nada\"',s,1)"
  _case "ausência que não diz que não houve aviso reprova" AUSENCIA-SEM-DECLARACAO "s=s.replace('NÃO HOUVE aviso de gravação nesta reunião.','Reunião regular, tudo certo.',1)"
  _case "ausência encerrada reprova" AUSENCIA-FECHADA "import re; s=re.sub(r'(x_meeting_role: notice_absent\n(?:    [^\n]*\n)*?    status: )open',r'\1done',s,1)"
  _case "ausência de impacto baixo reprova" AUSENCIA-IMPACTO-BAIXO "import re; s=re.sub(r'(x_meeting_role: notice_absent\n(?:    [^\n]*\n)*?    impact: )5',r'\g<1>2',s,1)"
  _case "ausência sobre um trecho só reprova" AUSENCIA-SEM-VARREDURA "s=s.replace('transcript-no-notice.txt#L1-L8','transcript-no-notice.txt#L1-L3',1)"
  _case "ausência com aviso reprova" AUSENCIA-COM-AVISO "s=s.replace('  - id: P_DIEGO','  - id: NOTICE_FAKE\n    node_type: evidence\n    x_meeting_role: notice_attempt\n    x_notice_channel: chat\n    x_notice_text: \"Boa tarde. Vamos direto ao cadastro de fornecedores.\"\n    plane: DEV\n    status: open\n    impact: 2\n    confidence: 0.5\n    label: \"Aviso inventado.\"\n    trace: \"'+'${NA_TXT}'+'#L3\"\n\n  - id: P_DIEGO',1).replace('\nedges:\n','\nedges:\n  - from: NOTICE_FAKE\n    to: MEETING\n    edge_type: SUPPORTS\n',1)"
  _case "duas ausências reprovam" AUSENCIA-DUPLICADA "s=s.replace('  - id: P_DIEGO','  - id: NOTICE_ABSENT_2\n    node_type: claim\n    x_meeting_role: notice_absent\n    x_notice_absent_basis: \"Transcrição inteira lida; nenhum aviso em lugar nenhum.\"\n    plane: DEV\n    status: open\n    impact: 5\n    confidence: 0.5\n    label: \"Outra ausência.\"\n    trace: \"'+'${NA_TXT}'+'#L1-L8\"\n\n  - id: P_DIEGO',1).replace('\nedges:\n','\nedges:\n  - from: NOTICE_ABSENT_2\n    to: MEETING\n    edge_type: SUPPORTS\n',1)"
  _case "ciente sem aviso reprova" RESPOSTA-SEM-AVISO "s=s.replace('x_notice_response: nao_avisado','x_notice_response: ciente',1)"
  _case "sem_resposta sem aviso reprova" RESPOSTA-SEM-AVISO "s=s.replace('x_notice_response: nao_avisado','x_notice_response: sem_resposta',1)"
  _case "participante fora da ausência reprova" AVISO-REF-INEXISTENTE "s=s.replace('x_notice_ref: NOTICE_ABSENT','x_notice_ref: \"-\"',1)"
  _case "recusa sem aviso ainda exige a parada" RECUSA-SEM-PARADA "s=s.replace('x_notice_response: nao_avisado','x_notice_response: recusou',1)"
  _case "aviso ausente com consentimento reprova" CONSENTIMENTO-LEGAL-DECLARADO "s=s.replace('    x_notice_response: nao_avisado\n','    x_notice_response: nao_avisado\n    x_consent_inferred: sim\n',1)"
  BASE="${FIX}/meeting-ok.kg.yaml"
  # O CONTRATO só julga onde o vendor existe (o core): o caso roda com a raiz do repo do checador, e fora dele
  # sai ⊘ declarado — nunca verde por vacuidade, nunca falha por ambiente.
  CROOT="$(git -C "${HERE}" rev-parse --show-toplevel 2>/dev/null || true)"
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../utils/kg/kgssot-tools.sh" 2>/dev/null || kgssot_tools_dir() { return 1; }  # resolver único (sem ele: o caminho de hoje)
  _KGT="$(kgssot_tools_dir "${CROOT:-.}")" || _KGT="${CROOT}/vendor/kg-ssot/tools"
  if [ -n "${CROOT}" ] && [ -f "${_KGT}/kg_gate.py" ] && [ -f "${HERE}/kg-contract-check.sh" ] \
     && [ -f "${CROOT}/.claude/validation/fixtures/meeting-graph/transcript-ok.txt" ]; then
    _case "contrato reprova o method fora da forma" CONTRATO "s=s.replace('method: \"reading: trecho da transcrição da reunião\"','method: \"lido na transcrição\"',1)" "${CROOT}"
    _case "contrato julga também o caminho relativo" CONTRATO "s=s.replace('method: \"reading: trecho da transcrição da reunião\"','method: \"lido na transcrição\"',1)" "${CROOT}" rel
  else echo "⊘ contrato reprova o method fora da forma (ferramentas do kg-ssot ausentes: não julgado aqui)"; fi
  if [ -n "${ONLY}" ] && [ "$((P + F))" -eq 0 ]; then echo "✗ caso inexistente: ${ONLY}"; F=1; fi
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
  0) if [ "${NOTICE_ABSENT:-0}" -eq 1 ]; then
       echo "meeting-graph-check: ⚠️ ${G} forma conforme, MAS SEM AVISO aos participantes: risco de compliance aberto, não é conformidade (trace ao trecho, radar verde)" >&2
     else echo "meeting-graph-check: ✅ ${G} conforme (aviso registrado, trace ao trecho, radar verde)" >&2; fi ;;
  1) echo "meeting-graph-check: ✗ ${G} REPROVADO" >&2 ;;
esac
exit "${rc}"
