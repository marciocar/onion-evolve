#!/usr/bin/env bash
# =============================================================================
# fetch-replies.sh — A6a do spike: o caminho de VOLTA (VPS → notebook). Roda NO NOTEBOOK.
#
# O notebook não tem endpoint público (NAT), então a volta é RETIRADA, não entrega: o channel da sessão
# receptora grava envelopes ASSINADOS (kid onion-evolve-spike-1) em ~/.local/state/onion/a2a-spike/outbox/
# na VPS, e este script os busca por ssh — o canal já autenticado entre as duas máquinas DO MAESTRO.
# ⚠️ Isto NÃO generaliza para dois usuários: outro usuário não tem ssh na VPS. O caminho de volta entre
# usuários é `tasks/get` no /a2a do bridge (lacuna L1 do protocolo), e exige mexer no bridge (MOAT).
#
# Para cada envelope novo: confere a assinatura com a pubkey pinada do core-spike, aud == este membro,
# body_sha256 == sha256(body) e in_reply_to ∈ jtis que ESTE notebook enviou (sent.tsv). Mede no relógio
# DO NOTEBOOK: rtt = t_recebido − t_envio do jti original (um relógio só: sem comparar relógios).
#
# Uso : fetch-replies.sh [--host H] [--me ID] [--sent-tsv F] [--watch [--until-reply JTI] [--interval S] [--timeout S]]
#                         [--local-dir D]
#       --host       alias ssh da VPS (default onion-kvm8) · --local-dir: lê um outbox local (ensaio offline)
#       --me ID      o membro que este fetch É: o aud que o channel assina = o `from` da ida (env A2A_SPIKE_ME;
#                    default maestro-notebook-test, o do ensaio de 14/10; o degrau B usa maestro-peer-test)
#       --sent-tsv F o sent.tsv do REMETENTE (default ~/.local/state/onion/a2a-spike/sent.tsv). No degrau B o
#                    envio roda como outro usuário (a2a-peer), e o sent.tsv dele não está nesta home
#                    (Emenda 12.14). Teste offline: notebook/fetch-replies.selftest.sh
# Saída: uma linha por envelope + ~/.local/state/onion/a2a-spike/recv.tsv
#        (t_recv_ms, kind, in_reply_to, rtt_ms, thread, jti_resposta, veredito)
# Exit: 0 ok · 1 algum envelope REPROVOU a verificação · 2 uso/tooling · 3 timeout sem a resposta pedida
# =============================================================================
set -euo pipefail

HOST="onion-kvm8"; WATCH=""; UNTIL=""; INTERVAL=1; TIMEOUT=300; LOCAL_DIR=""
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUB="${A2A_SPIKE_CORE_PUB:-${HERE}/../keys/onion-evolve-spike-1.pub.pem}"
ME="${A2A_SPIKE_ME:-maestro-notebook-test}"
STATE_DIR="${HOME}/.local/state/onion/a2a-spike"
SENT_TSV="${STATE_DIR}/sent.tsv"
REMOTE_OUTBOX='.local/state/onion/a2a-spike/outbox'

die() { echo "ERRO: $*" >&2; exit 2; }
while [ "$#" -gt 0 ]; do
  # flag de valor sem o valor é erro de USO (rc 2), não "unbound variable" do set -u (rc 1 = envelope reprovou)
  case "$1" in --host|--until-reply|--interval|--timeout|--local-dir|--me|--sent-tsv)
    [ "$#" -ge 2 ] || die "falta o valor de $1" ;; esac
  case "$1" in
  --host) HOST="$2"; shift 2 ;;
  --watch) WATCH=1; shift ;;
  --until-reply) UNTIL="$2"; shift 2 ;;
  --interval) INTERVAL="$2"; shift 2 ;;
  --timeout) TIMEOUT="$2"; shift 2 ;;
  --local-dir) LOCAL_DIR="$2"; shift 2 ;;
  --me) ME="$2"; shift 2 ;;
  --sent-tsv) SENT_TSV="$2"; shift 2 ;;
  -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
  *) die "argumento desconhecido: $1" ;;
esac; done
for t in openssl jq; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done
[ -n "${LOCAL_DIR}" ] || command -v ssh >/dev/null 2>&1 || die "ssh ausente"
[ -f "${PUB}" ] || die "pubkey do core-spike ausente: ${PUB}"
[ -n "${ME}" ] || die "--me vazio: o aud esperado não pode ser vazio"
# sent.tsv ilegível NÃO é erro de uso: cada envelope sai in_reply_to-desconhecido (a verificação reprova, exit 1)
[ -r "${SENT_TSV}" ] || echo "aviso: sent.tsv ilegível (${SENT_TSV}): toda resposta sairá in_reply_to-desconhecido" >&2
mkdir -p "${STATE_DIR}/inbox"; chmod 700 "${STATE_DIR}" 2>/dev/null || true
touch "${STATE_DIR}/seen.txt"

now_ms() {
  if command -v python3 >/dev/null 2>&1; then python3 -c 'import time;print(int(time.time()*1000))'
  elif command -v perl >/dev/null 2>&1; then perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000'
  else echo "$(( $(date +%s) * 1000 ))"; fi
}
b64url_decode() { local d; d="$(printf '%s' "$1" | tr '_-' '/+')"; case $(( ${#d} % 4 )) in 2) d="${d}==";; 3) d="${d}=";; esac; printf '%s' "${d}" | openssl base64 -d -A; }

list_remote() {
  if [ -n "${LOCAL_DIR}" ]; then ls "${LOCAL_DIR}" 2>/dev/null | grep '\.json$' || true
  else ssh -o BatchMode=yes "${HOST}" "ls ${REMOTE_OUTBOX} 2>/dev/null" | grep '\.json$' || true; fi
}
get_remote() {  # $1 = nome
  case "$1" in *[!A-Za-z0-9._-]*) die "nome de arquivo suspeito no outbox: $1" ;; esac
  if [ -n "${LOCAL_DIR}" ]; then cat "${LOCAL_DIR}/$1"
  else ssh -o BatchMode=yes "${HOST}" "cat ${REMOTE_OUTBOX}/$1"; fi
}

BAD=0; GOT_UNTIL=""
verify_one() {  # $1 = nome; imprime veredito e grava recv.tsv
  local name="$1" f t_recv jws h r p s pl kid kind irt thread rj body_sha cl_sha verdict="ok" t_send rtt exp
  # o nome é validado ANTES de virar caminho local (o get_remote também valida, mas o `>` abriria antes)
  case "${name}" in *[!A-Za-z0-9._-]*|.*) die "nome de arquivo suspeito no outbox: ${name}" ;; esac
  f="${STATE_DIR}/inbox/${name}"; get_remote "${name}" > "${f}"; t_recv="$(now_ms)"
  jws="$(jq -r '.jws // empty' "${f}")"; h="${jws%%.*}"; r="${jws#*.}"; p="${r%%.*}"; s="${r#*.}"
  pl="$(b64url_decode "${p}")"; kid="$(b64url_decode "${h}" | jq -r '.kid // empty')"
  b64url_decode "${s}" > "${f}.sig"
  if [ "${kid}" != "onion-evolve-spike-1" ]; then verdict="kid-inesperado:${kid}"
  elif ! printf '%s' "${h}.${p}" | openssl dgst -sha256 -verify "${PUB}" -signature "${f}.sig" >/dev/null 2>&1; then verdict="assinatura-invalida"
  elif [ "$(printf '%s' "${pl}" | jq -r '.aud')" != "${ME}" ]; then verdict="aud-errado"
  else
    # exp ausente/não numérico REPROVA: o `[ -lt ]` com 'null' falhava calado e virava "não expirado"
    exp="$(printf '%s' "${pl}" | jq -r '.exp // empty')"
    case "${exp}" in ''|*[!0-9]*) verdict="sem-exp" ;; *) [ "${exp}" -ge "$(date +%s)" ] || verdict="expirado" ;; esac
  fi
  rm -f "${f}.sig"
  kind="$(printf '%s' "${pl}" | jq -r '.kind // "?"')"; irt="$(printf '%s' "${pl}" | jq -r '.in_reply_to // ""')"
  thread="$(printf '%s' "${pl}" | jq -r '.thread // ""')"; rj="$(printf '%s' "${pl}" | jq -r '.jti // ""')"
  cl_sha="$(printf '%s' "${pl}" | jq -r '.body_sha256 // ""')"
  body_sha="$(jq -j '.signal.body // ""' "${f}" | openssl dgst -sha256 | awk '{print $NF}')"
  [ "${verdict}" = ok ] && [ "${body_sha}" != "${cl_sha}" ] && verdict="corpo-adulterado"
  t_send="$(awk -F'\t' -v j="${irt}" '$3==j {print $1; exit}' "${SENT_TSV}" 2>/dev/null || true)"
  # o sent.tsv pode ser de OUTRO usuário (--sent-tsv, degrau B): t_send cru no $(( )) executaria
  # `a[$(cmd)]` como quem roda o fetch. Só dígitos; o resto vira jti desconhecido (passada adversarial 2026-10-22)
  case "${t_send}" in *[!0-9]*) t_send="" ;; esac
  if [ -z "${t_send}" ]; then [ "${verdict}" = ok ] && verdict="in_reply_to-desconhecido"; rtt="?"; else rtt=$(( t_recv - t_send )); fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${t_recv}" "${kind}" "${irt}" "${rtt}" "${thread}" "${rj}" "${verdict}" >> "${STATE_DIR}/recv.tsv"
  echo "${name}" >> "${STATE_DIR}/seen.txt"
  printf '[%s] %s ← %s (rtt %s ms) %s\n' "${verdict}" "${kind}" "${irt}" "${rtt}" "${thread}"
  [ "${kind}" = reply ] && [ "${verdict}" = ok ] && printf '%s\n' "$(jq -r '.signal.body' "${f}")" | sed 's/^/    │ /'
  [ "${verdict}" = ok ] || BAD=1
  [ -n "${UNTIL}" ] && [ "${irt}" = "${UNTIL}" ] && [ "${kind}" = reply ] && GOT_UNTIL=1
  return 0
}

START="$(date +%s)"
while :; do
  # sem `for $(...)`: nada de word-splitting nem glob local sobre nomes vindos do remoto
  NAMES="$(list_remote)"
  while IFS= read -r n; do
    [ -n "${n}" ] || continue
    grep -qxF "${n}" "${STATE_DIR}/seen.txt" || verify_one "${n}"
  done <<EOF
${NAMES}
EOF
  [ -z "${WATCH}" ] && break
  [ -n "${GOT_UNTIL}" ] && break
  [ $(( $(date +%s) - START )) -ge "${TIMEOUT}" ] && { echo "timeout: nenhuma resposta a ${UNTIL:-nada} em ${TIMEOUT}s" >&2; exit 3; }
  sleep "${INTERVAL}"
done
exit "${BAD}"
