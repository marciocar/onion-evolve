#!/usr/bin/env bash
# a2a-queue-live.sh — a fila A2A do bridge de PRODUÇÃO (data/a2a-pending e os subdiretórios por receptor), core-only.
#
# POR QUE EXISTE (2026-10-15): o bridge enfileira cada sinal verificado como um registro JSON na fila
# (`<fila>/<signal.id>.<taskId>.json`; a do core na raiz, a de cada hub num subdiretório com o id dele, desde a F3),
# e o aceite (.claude/utils/federation-transport/a2a-accept.sh) materializa o sinal no inbox do core sem tocar a
# fila. Limpar a fila era ato manual do maestro com `!`, porque ela mora em /home/onion, um caminho SERVIDO
# (ops/moat-targets.tsv), e o veto do MOAT barra, corretamente, `sudo -u <conta> mv` direto nela. Este wrapper é
# o único caminho de escrita na fila: trava, ensaio por padrão, backup cifrado antes, prova por contagem depois e
# rollback impresso. Molde: ops/a2a-invite-live.sh. "Único" quer dizer o único que o veto deixa passar entre os
# verbos que ele julga (mv, rm, cp, tee, …); interpretador (python3 -c, perl -e, node -e), rsync
# --remove-source-files, tar --remove-files e função, array ou alias que embrulha sudo seguem fora do juiz
# (classe pré-existente, declarada na doutrina do drive).
#
# USO
#   ops/a2a-queue-live.sh list    [--receiver <id>] [--json]
#   ops/a2a-queue-live.sh show    <registro> --out <arq> [--receiver <id>]
#   ops/a2a-queue-live.sh archive <registro> [--receiver <id>] [--force-unaccepted <motivo>] [--apply]
#
#   <registro>  o NOME do arquivo na fila, como o list imprime (sem diretório).
#   --receiver  a fila de um hub (o subdiretório com o id dele). Sem ele: a fila do core (a raiz) no show e no
#               archive, e todas as filas no list.
#   list        nome, receptor, remetente, recebido_em, verified e se o aceite já foi feito. NUNCA imprime o
#               corpo do sinal nem o envelope.
#   show        copia o registro para um arquivo NOVO do operador (0600, fora de árvore git versionável), que é
#               o que o aceite lê:  bash .claude/utils/federation-transport/a2a-accept.sh <arq>
#   archive     MOVE o registro, como a conta do serviço, para <fila>/_archived/ (reversível; nada se apaga) e
#               anota a linha em <fila>/_archived/archive.log. Sem --apply é ENSAIO: nada é escrito, nem o backup.
#               Recusa registro que o aceite ainda não materializou no inbox do core, salvo --force-unaccepted
#               com um motivo (8 a 200 caracteres, uma linha), que vai para o archive.log.
#   ACEITO quer dizer: um doc do inbox do core (docs/evolution/inbox deste checkout, _processed incluso) traz,
#   no frontmatter, a linha `taskId: <o taskId do registro>` que o a2a-accept.sh escreve. O taskId é o
#   randomUUID que o bridge gera por registro. Registro sem taskId, ou de outro receptor (o hub aceita no repo
#   dele, que este wrapper não lê), conta como NÃO aceito.
#   Fixos, sem opção para mudar: a raiz da fila, a conta do serviço e o inbox. O wrapper não aceita caminho.
#
# O QUE ELE FAZ no archive --apply: trava (a mesma do update-bridge) → confere que o registro é arquivo regular e
# que o aceite foi feito → backup rotulado do estado do bridge (bridge-backup.sh, cifrado) → mkdir de _archived
# e mv sem sobrescrever, como a conta do serviço → prova por contagem (a fila perde 1, _archived ganha 1, o
# sha256 do arquivado é o de antes) → linha no archive.log. Falha depois do backup imprime o rollback; nunca o
# executa.
#
# EXIT (molde do a2a-invite-live): 0 ok · 1 problema medido ou escrita recusada · 2 não pude medir (trava, sudo,
#   fila, backup) · 3 uso inválido
#
# MODO DE TESTE (bancada): ONION_A2A_QUEUE_TEST=1 com ONION_A2A_QUEUE_DIR, ONION_A2A_QUEUE_INBOX,
#   ONION_A2A_QUEUE_BACKUP (comando que imprime "ok: <artefato>") e ONION_A2A_QUEUE_LOCK. Nele tudo roda como
#   QUEM RODA (sem sudo) e a fila não pode estar sob a home da conta do serviço.
#   Qualquer ONION_A2A_QUEUE_* sem o modo de teste é uso inválido (rc 3): produção não se redireciona por env.
set -uo pipefail

SVC_USER=onion
SVC_HOME=/home/onion
PROD_QUEUE="${SVC_HOME}/onion-bridge/data/a2a-pending"
PROD_LOCK=/tmp/onion-update-bridge.lock
DEFAULT_RECEIVER=onion-evolve          # o A2A_DEFAULT_RECEIVER do bridge (src/a2a.ts): a fila da raiz é do core
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME=a2a-queue-live

say()  { printf '[%s] %s\n' "${NAME}" "$*"; }
die()  { local rc="$1"; shift; printf '[%s] ERRO: %s\n' "${NAME}" "$*" >&2; exit "${rc}"; }
usage() { sed -n '/^# USO/,/^# O QUE ELE FAZ/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 3; }

case "${1:-}" in -h|--help) sed -n '/^# USO/,/^# MODO DE TESTE/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 0 ;; '') usage ;; esac

# ── modo: produção ou teste declarado ──────────────────────────────────────────────────────────────────
TEST=0
if [ "${ONION_A2A_QUEUE_TEST:-}" = 1 ]; then
  TEST=1
  QUEUE="${ONION_A2A_QUEUE_DIR:?modo de teste exige ONION_A2A_QUEUE_DIR}"
  INBOX="${ONION_A2A_QUEUE_INBOX:?modo de teste exige ONION_A2A_QUEUE_INBOX}"
  BACKUP="${ONION_A2A_QUEUE_BACKUP:?modo de teste exige ONION_A2A_QUEUE_BACKUP}"
  LOCK="${ONION_A2A_QUEUE_LOCK:?modo de teste exige ONION_A2A_QUEUE_LOCK}"
  # o teste nunca toca a home da conta do serviço, nem por symlink
  _r="$(realpath -m -- "${QUEUE}")"
  case "${_r}/" in "${SVC_HOME}/"*) die 3 "modo de teste com fila sob ${SVC_HOME}: recusado (${_r})" ;; esac
else
  [ -n "${ONION_A2A_QUEUE_TEST:-}" ] && die 3 "ONION_A2A_QUEUE_TEST só aceita 1"
  if compgen -e | grep -E '^ONION_A2A_QUEUE_' >/dev/null; then
    die 3 "variável ONION_A2A_QUEUE_* sem ONION_A2A_QUEUE_TEST=1: produção não se redireciona por ambiente"
  fi
  QUEUE="${PROD_QUEUE}"; INBOX="${SELF_DIR}/../docs/evolution/inbox"; BACKUP=""; LOCK="${PROD_LOCK}"
  # o wrapper e o backup que ele chama por sudo (como root) têm de ser os RASTREADOS e limpos de um checkout
  # (a mesma razão do a2a-invite-live: uma cópia em /tmp chamaria um bridge-backup.sh que outra conta planta)
  for _f in "${SELF_DIR}/$(basename "${BASH_SOURCE[0]}")" "${SELF_DIR}/bridge-backup.sh"; do
    git -C "${SELF_DIR}" ls-files --error-unmatch -- "${_f}" >/dev/null 2>&1 \
      || die 3 "${_f} não é arquivo rastreado de um checkout: rode o wrapper do repositório, não uma cópia"
    git -C "${SELF_DIR}" diff --quiet HEAD -- "${_f}" 2>/dev/null \
      || die 3 "${_f} tem mudança não commitada: rode o wrapper como está no commit"
  done
fi

[ "$(id -u)" -eq 0 ] && die 3 "rodando como root: rode como o operador (o wrapper chama sudo -u ${SVC_USER} onde precisa)"

# as_svc <args…>: como a conta do serviço (produção) ou como quem roda (teste), sempre a partir de /
as_svc() {
  if [ "${TEST}" = 1 ]; then (cd / && "$@")
  else (cd / && sudo -n -u "${SVC_USER}" "$@"); fi
}

# ── argumentos: lista FECHADA (o wrapper não vira mover genérico como a conta do serviço) ───────────────
SUB="$1"; shift
REC=""; RECEIVER=""; OUT=""; FORCE=""; FORCE_SET=0; APPLY=0; JSON=0
ID_RE='^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$'          # a forma do queueDirFor do bridge
REC_RE='^[A-Za-z0-9][A-Za-z0-9._-]{0,250}\.json$'   # nome de registro: sem barra, sem ponto inicial
case "${SUB}" in
  show|archive) [ $# -ge 1 ] || usage; REC="$1"; shift ;;
  list) : ;;
  *) usage ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --receiver)          RECEIVER="${2:-}"; shift 2 || usage ;;
    --out)               [ "${SUB}" = show ] || die 3 "--out só no show"; OUT="${2:-}"; shift 2 || usage ;;
    --force-unaccepted)  [ "${SUB}" = archive ] || die 3 "--force-unaccepted só no archive"; FORCE="${2:-}"; FORCE_SET=1; shift 2 || usage ;;
    --apply)             [ "${SUB}" = archive ] || die 3 "--apply só no archive"; APPLY=1; shift ;;
    --json)              [ "${SUB}" = list ] || die 3 "--json só no list"; JSON=1; shift ;;
    *) die 3 "opção não aceita: $1 (a fila, a conta do serviço e o inbox são fixos)" ;;
  esac
done
[ -z "${RECEIVER}" ] || [[ "${RECEIVER}" =~ ${ID_RE} ]] || die 3 "--receiver fora da forma: ${RECEIVER}"
[ -z "${REC}" ] || [[ "${REC}" =~ ${REC_RE} ]] || die 3 "registro fora da forma (o nome do arquivo, sem diretório): ${REC}"
if [ "${FORCE_SET}" = 1 ]; then
  [[ "${FORCE}" =~ ^[^[:cntrl:]]{8,200}$ ]] || die 3 "--force-unaccepted exige um motivo de 8 a 200 caracteres, numa linha"
fi
[ "${SUB}" = show ] && [ -z "${OUT}" ] && die 3 "show exige --out <arq novo> (a cópia que o aceite lê)"

# a fila de um receptor: a do core na raiz, a de um hub no subdiretório (o mesmo queueDirFor do bridge)
qdir() { if [ -z "$1" ] || [ "$1" = "${DEFAULT_RECEIVER}" ]; then printf '%s' "${QUEUE}"; else printf '%s/%s' "${QUEUE}" "$1"; fi; }

# ── trava: a MESMA do update-bridge (ele reinicia o bridge que escreve nesta fila) ──────────────────────
exec 9>"${LOCK}" || die 2 "não abri a trava ${LOCK}"
flock -n 9 || die 2 "outra execução (este wrapper, o de convites ou o update-bridge) segura ${LOCK}; tente de novo"

as_svc test -d "${QUEUE}" || die 2 "a fila não está em ${QUEUE} (para a conta ${SVC_USER})"

# scan <dir>: uma linha JSON por registro (só metadados: nunca o signal nem o envelope), como a conta do serviço
SCAN_PY='import json, os, sys
d = sys.argv[1]
for n in sorted(os.listdir(d)):
    p = os.path.join(d, n)
    if not n.endswith(".json") or os.path.islink(p) or not os.path.isfile(p):
        continue
    o = {"name": n}
    try:
        r = json.load(open(p, encoding="utf-8"))
        if not isinstance(r, dict):
            raise ValueError
    except Exception:
        o["malformed"] = True; print(json.dumps(o)); continue
    v = r.get("verdict") if isinstance(r.get("verdict"), dict) else {}
    s = r.get("signal") if isinstance(r.get("signal"), dict) else {}
    for k, val in (("taskId", r.get("taskId")), ("receivedAt", r.get("receivedAt")),
                   ("from", r.get("from") or s.get("from")), ("receiver", r.get("receiver"))):
        o[k] = val if isinstance(val, str) else None
    o["verified"] = v.get("verified") is True
    print(json.dumps(o))'
scan() { as_svc python3 -I -c "${SCAN_PY}" "$1"; }

# accepted_doc <taskId>: o doc do inbox que traz `taskId: <id>` no frontmatter (vazio = não aceito)
accepted_doc() {
  [ -n "$1" ] || return 0
  python3 -I -c 'import os, re, sys
root, tid = sys.argv[1], sys.argv[2]
pat = re.compile(r"^\s*taskId:\s*[\"\x27]?" + re.escape(tid) + r"[\"\x27]?\s*$")
for dp, _, fs in os.walk(root):
    for f in sorted(fs):
        if not f.endswith(".md"):
            continue
        try:
            ls = open(os.path.join(dp, f), encoding="utf-8", errors="replace").read().split("\n")
        except OSError:
            continue
        if not ls or ls[0].strip() != "---":
            continue
        hit, under, closed = False, False, False
        for ln in ls[1:]:
            if ln.strip() == "---":
                closed = True
                break
            if ln and not ln[0].isspace():
                under = ln.rstrip() == "verificacao:"       # o a2a-accept.sh grava verificacao.taskId
            elif under and pat.match(ln):
                hit = True
        if hit and closed:                                  # frontmatter sem fechamento não é frontmatter
            print(os.path.join(dp, f)); raise SystemExit' "${INBOX}" "$1" 2>/dev/null
}

# ── list ───────────────────────────────────────────────────────────────────────────────────────────────
if [ "${SUB}" = list ]; then
  rcvs=()
  if [ -n "${RECEIVER}" ]; then
    as_svc test -d "$(qdir "${RECEIVER}")" || die 1 "não há fila para o receptor '${RECEIVER}'"
    rcvs=("${RECEIVER}")
  else
    rcvs=("${DEFAULT_RECEIVER}")
    while IFS= read -r _s; do [ -n "${_s}" ] && rcvs+=("${_s}"); done < <(as_svc python3 -I -c 'import os, re, sys
d = sys.argv[1]
for n in sorted(os.listdir(d)):
    if re.match(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$", n) and os.path.isdir(os.path.join(d, n)) and not os.path.islink(os.path.join(d, n)):
        print(n)' "${QUEUE}")
  fi
  total=0
  for r in "${rcvs[@]}"; do
    q="$(qdir "${r}")"
    rows="$(scan "${q}")" || die 2 "não li a fila ${q}"
    arch=0; as_svc test -d "${q}/_archived" && arch="$(scan "${q}/_archived" | grep -c . || true)"
    n=0
    while IFS= read -r ln; do
      [ -n "${ln}" ] || continue
      n=$((n + 1))
      tid="$(python3 -I -c 'import json,sys; print(json.loads(sys.argv[1]).get("taskId") or "")' "${ln}")"
      rrcv="$(python3 -I -c 'import json,sys; print(json.loads(sys.argv[1]).get("receiver") or "")' "${ln}")"
      acc=""
      if [ "${r}" = "${DEFAULT_RECEIVER}" ] && { [ -z "${rrcv}" ] || [ "${rrcv}" = "${DEFAULT_RECEIVER}" ]; }; then acc="$(accepted_doc "${tid}")"
      else acc="-"; fi                           # registro de hub: o aceite é no repo do hub, que daqui não se lê
      if [ "${JSON}" = 1 ]; then
        python3 -I -c 'import json,sys; o=json.loads(sys.argv[1]); o["queue"]=sys.argv[2]; o["accepted_doc"]=None if sys.argv[3] in ("", "-") else sys.argv[3]; o["accepted_measured"]=sys.argv[3] != "-"; print(json.dumps(o, ensure_ascii=False))' "${ln}" "${r}" "${acc}"
      else
        python3 -I -c 'import json,sys
o={k: ("".join(c for c in v if c.isprintable()) if isinstance(v, str) else v) for k, v in json.loads(sys.argv[1]).items()}; acc=sys.argv[2]
if o.get("malformed"): print("  %s  [registro malformado]" % o["name"]); raise SystemExit
a = "não medido (o hub aceita no repo dele)" if acc == "-" else (("sim (" + acc + ")") if acc else "não")
print("  %s\n      remetente=%s  recebido_em=%s  verified=%s  aceito=%s" % (o["name"], o.get("from"), o.get("receivedAt"),
      "sim" if o.get("verified") else "NAO", a))' "${ln}" "${acc#"${INBOX}/"}"
      fi
    done <<< "${rows}"
    [ "${JSON}" = 1 ] || say "fila ${r} (${q}): ${n} registro(s) na fila, ${arch} arquivado(s)"
    total=$((total + n))
  done
  [ "${JSON}" = 1 ] || say "total: ${total} registro(s) em ${#rcvs[@]} fila(s)"
  exit 0
fi

# ── show e archive: o registro existe e é arquivo regular? ─────────────────────────────────────────────
Q="$(qdir "${RECEIVER}")"
SRC="${Q}/${REC}"
as_svc test -d "${Q}" || die 1 "não há fila para o receptor '${RECEIVER:-${DEFAULT_RECEIVER}}'"
as_svc test -L "${Q}" && die 1 "a fila do receptor é symlink: recusado (${Q})"
as_svc test -L "${Q}/_archived" && die 1 "${Q}/_archived é symlink: recusado (o arquivado iria para outro lugar)"
as_svc test -L "${SRC}" && die 1 "o registro é symlink: recusado (${SRC})"
as_svc test -f "${SRC}" || die 1 "não há o registro ${REC} na fila ${Q}"
META="$(scan "${Q}" | python3 -I -c 'import json,sys
for ln in sys.stdin:
    o = json.loads(ln)
    if o["name"] == sys.argv[1]: print(json.dumps(o)); break' "${REC}")"
[ -n "${META}" ] || die 2 "não li os metadados de ${REC}"
mget() { python3 -I -c 'import json,sys; v=json.loads(sys.argv[1]).get(sys.argv[2]); print("" if v is None else v)' "${META}" "$1"; }

# ── show: a cópia do operador (0600, arquivo novo), que o aceite lê ────────────────────────────────────
if [ "${SUB}" = show ]; then
  [ -e "${OUT}" ] || [ -L "${OUT}" ] && die 1 "${OUT} já existe: recuso sobrescrever"
  out_dir="$(dirname -- "${OUT}")"
  [ -d "${out_dir}" ] || die 1 "o diretório de --out não existe: ${out_dir}"
  if git -C "${out_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
     && ! git -C "${out_dir}" check-ignore -q -- "$(realpath -m -- "${OUT}")" 2>/dev/null; then
    die 1 "${OUT} cairia numa árvore git sem estar no .gitignore: gere fora do repo (o registro carrega o envelope assinado)"
  fi
  ( umask 077; set -C; as_svc cat -- "${SRC}" > "${OUT}" ) || die 2 "não copiei o registro para ${OUT}"
  s_src="$(as_svc sha256sum -- "${SRC}" | cut -d' ' -f1)"; s_out="$(sha256sum -- "${OUT}" | cut -d' ' -f1)"
  [ -n "${s_src}" ] && [ "${s_src}" = "${s_out}" ] || die 1 "a cópia em ${OUT} não bate com o registro (sha256)"
  say "OK — ${REC} copiado para ${OUT} (0600, sha256 ${s_out:0:12}); verified=$( [ "$(mget verified)" = True ] && echo sim || echo NAO )"
  rcv_arg=""; [ -n "${RECEIVER}" ] && [ "${RECEIVER}" != "${DEFAULT_RECEIVER}" ] && rcv_arg=" --receiver ${RECEIVER}"
  say "próximo (o aceite, no repo do receptor): bash .claude/utils/federation-transport/a2a-accept.sh ${OUT}${rcv_arg}"
  say "depois do aceite: ops/a2a-queue-live.sh archive ${REC}${rcv_arg} --apply"
  exit 0
fi

# ── archive ────────────────────────────────────────────────────────────────────────────────────────────
TID="$(mget taskId)"; RRCV="$(mget receiver)"
[[ "${TID}" =~ ^[A-Za-z0-9-]{1,64}$ ]] || TID=""        # forma do randomUUID do bridge; fora dela, conta como ausente
[[ "${RRCV}" =~ ${ID_RE} ]] || [ -z "${RRCV}" ] || RRCV="<fora-da-forma>"
ACC=""
if [ "${Q}" = "${QUEUE}" ] && { [ -z "${RRCV}" ] || [ "${RRCV}" = "${DEFAULT_RECEIVER}" ]; }; then ACC="$(accepted_doc "${TID}")"; fi
if [ -n "${ACC}" ]; then
  STATUS="aceito:${ACC#"${INBOX}/"}"
elif [ "${FORCE_SET}" = 1 ]; then
  STATUS="forcado:${FORCE}"
  say "AVISO: ${REC} NÃO foi aceito (taskId '${TID:-ausente}' sem doc no inbox${RRCV:+, receptor ${RRCV}}); arquivando por --force-unaccepted"
else
  die 1 "${REC} não foi aceito: nenhum doc de ${INBOX#"${SELF_DIR}/../"} traz 'taskId: ${TID:-<ausente>}'${RRCV:+ (receptor ${RRCV}: o hub aceita no repo dele)}. Aceite antes (ops/a2a-queue-live.sh show ${REC} --out <arq>, depois a2a-accept.sh <arq>) ou passe --force-unaccepted '<motivo>'"
fi
DST_DIR="${Q}/_archived"; DST="${DST_DIR}/${REC}"
as_svc test -e "${DST}" && die 1 "já há ${REC} em ${DST_DIR}: recuso sobrescrever o arquivado"

if [ "${APPLY}" = 0 ]; then
  say "ENSAIO: moveria ${SRC} → ${DST} (${STATUS%%:*}). Nada foi escrito. Para mover, repita com --apply."
  exit 0
fi

# ── contagem ANTES (a prova é por contagem, não pelo rc do mv) ─────────────────────────────────────────
count() { as_svc test -d "$1" || { echo 0; return; }; scan "$1" | grep -c . || true; }
names() { as_svc test -d "$1" || return 0; scan "$1" | python3 -I -c 'import json,sys
for ln in sys.stdin: print(json.loads(ln)["name"])'; }
before_q="$(count "${Q}")"; before_a="$(count "${DST_DIR}")"; before_names="$(names "${Q}")"
sha_before="$(as_svc sha256sum -- "${SRC}" | cut -d' ' -f1)"
[[ "${before_q}" =~ ^[1-9][0-9]*$ ]] && [ -n "${sha_before}" ] || die 2 "não medi a fila antes do arquivamento"

# ── backup rotulado do estado do bridge (cifrado), artefato NOMEADO ────────────────────────────────────
label="pre-queue-archive-$(printf '%s' "${TID:-${REC}}" | tr -c 'A-Za-z0-9' '-' | cut -c1-8)"
if [ "${TEST}" = 1 ]; then BK_OUT="$("${BACKUP}" "${label}")"; else BK_OUT="$(sudo -n "${SELF_DIR}/bridge-backup.sh" "${label}")"; fi
[ $? -eq 0 ] || die 2 "backup falhou: sem rede de segurança não se move"
BK="$(printf '%s\n' "${BK_OUT}" | sed -n 's/^ok: \([^ ]*\).*/\1/p' | tail -1)"
[ -n "${BK}" ] || die 2 "o backup não nomeou o artefato: ${BK_OUT}"
say "backup: ${BK}"

rollback() {
  cat >&2 <<EOF
[${NAME}] ─── ROLLBACK MANUAL (do maestro, fora da sessão: \`!\` no prompt) ───
  # devolve o registro à fila (sem sobrescrever o que estiver lá):
  sudo -u ${SVC_USER} mv -n -- ${DST} ${SRC}
  # se o arquivado sumiu, o backup rotulado tem a fila inteira: ${BK}
  ops/a2a-queue-live.sh list${RECEIVER:+ --receiver ${RECEIVER}}     # o registro volta a aparecer
EOF
}
fail_after_write() { printf '[%s] ERRO: %s\n' "${NAME}" "$1" >&2; rollback; exit 1; }

# ── escrita: mkdir e mv sem sobrescrever, como a conta do serviço ──────────────────────────────────────
as_svc mkdir -p -m 0750 -- "${DST_DIR}" || die 2 "não criei ${DST_DIR}"
as_svc mv -n -- "${SRC}" "${DST}"
rc=$?
after_q="$(count "${Q}")"; after_a="$(count "${DST_DIR}")"; after_names="$(names "${Q}")"
if [ "${rc}" -ne 0 ]; then
  as_svc test -f "${SRC}" || fail_after_write "o mv saiu ${rc} e o registro não está mais na fila"
  say "o mv saiu ${rc}: nada foi movido (fila ${before_q} intacta)"; exit 1
fi
as_svc test -e "${SRC}" && fail_after_write "o registro continua na fila depois do mv"
# a fila é medida como CONJUNTO, não como número: o bridge segue enfileirando durante o arquivamento (a trava só
# exclui o update-bridge), e um registro que chega não é falha; um que SOME, além deste, é
missing="$(comm -23 <(printf '%s\n' "${before_names}" | grep -vxF -- "${REC}" | LC_ALL=C sort) <(printf '%s\n' "${after_names}" | LC_ALL=C sort) | grep -c . || true)"
[ "${missing}" = 0 ] || fail_after_write "contagem da fila: ${missing} registro(s) além de ${REC} sumiram da fila"
arrived="$(comm -13 <(printf '%s\n' "${before_names}" | LC_ALL=C sort) <(printf '%s\n' "${after_names}" | LC_ALL=C sort) | grep -c . || true)"
[ "${arrived}" = 0 ] && arrived=""
[ "${after_a}" = "$(( before_a + 1 ))" ] || fail_after_write "contagem de _archived: esperava $(( before_a + 1 )), há ${after_a}"
sha_after="$(as_svc sha256sum -- "${DST}" | cut -d' ' -f1)"
[ "${sha_after}" = "${sha_before}" ] || fail_after_write "o arquivado não tem o sha256 do registro (${sha_after:0:12} ≠ ${sha_before:0:12})"
printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "${REC}" "${TID:-}" "${STATUS}" "$(id -un)" \
  | as_svc tee -a -- "${DST_DIR}/archive.log" >/dev/null || say "AVISO: o registro FOI arquivado, mas a linha do archive.log falhou"
say "OK — ${REC} arquivado (${STATUS%%:*}): fila ${before_q} → ${after_q}${arrived:+ (${arrived} chegado(s) durante)}, _archived ${before_a} → ${after_a}, sha256 ${sha_after:0:12} conferido"
exit 0
