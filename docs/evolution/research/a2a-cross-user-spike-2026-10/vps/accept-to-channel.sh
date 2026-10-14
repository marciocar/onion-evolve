#!/usr/bin/env bash
# =============================================================================
# accept-to-channel.sh — o ATO HUMANO do receptor no spike A2A cross-user. Roda NA VPS, pelo maestro
# (com `!` no prompt da sessão receptora, ou num terminal dele) — nunca pelo modelo por conta própria.
#
# Pega UM registro da fila gated do bridge (data/a2a-pending/, escrita pelo POST /a2a depois do
# a2a-verify do core) e:
#   1. recusa se verdict.verified != true                       (defesa em profundidade, como o a2a-accept)
#   2. RE-VERIFICA a assinatura com a pubkey pinada e AMARRA O CORPO: claim body_sha256 do JWS ==
#      sha256(signal.body) == signal.body_sha256; iss == from; aud == onion-evolve; thread do claim == signal.
#      O gate do core NÃO faz isto (achado F1 do protocolo): sem esta camada, o corpo que chega à sessão
#      não é o que o remetente assinou — o envelope fora do JWS é texto livre.
#   3. registra a aceitação com o a2a-accept.sh do core, num inbox DO SPIKE (não no inbox de co-evolução:
#      conversa não é sinal de triagem, e misturar sujaria a fila do /meta:co-evolve)
#   4. entrega o corpo ao channel MCP da sessão receptora (loopback, bearer de arquivo 0600), uma vez só
#      por jti (dedupe local — o jti.state do bridge veta replay NA ENTRADA; este veta reentrega NA SAÍDA)
#
# Modos de consentimento (SPIKE-PROTOCOL.md §4 — pré-registrados; C2 só com assinatura do maestro):
#   C1 (default): um registro por invocação = uma aceitação humana por mensagem.
#   C2 (--lease): o maestro aceita UMA THREAD de UM membro por TTL segundos; registros novos dessa thread
#                 entram sem nova aceitação até o TTL vencer. Exige emenda à RFC-0004 para sair do spike.
#
# Uso : accept-to-channel.sh <registro.json|-> [--no-push] [--channel-url URL]
#       accept-to-channel.sh --lease --thread T --from ID --ttl S [--pending-dir D]
# Env : A2A_SPIKE_JWKS (default: jwks/ do core desta árvore) · A2A_SPIKE_STATE (~/.local/state/onion/a2a-spike)
#       A2A_SPIKE_CHANNEL_TOKEN (default ~/.config/onion/a2a/channel-token)
# Exit: 0 entregue (ou já entregue) · 1 recusado · 2 uso/tooling
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../../../../.." && pwd)"
ACCEPT="${ROOT}/.claude/utils/federation-transport/a2a-accept.sh"
JWKS="${A2A_SPIKE_JWKS:-${ROOT}/.claude/utils/federation-transport/jwks}"
STATE="${A2A_SPIKE_STATE:-${HOME}/.local/state/onion/a2a-spike}"
CHAN_TOKEN="${A2A_SPIKE_CHANNEL_TOKEN:-${HOME}/.config/onion/a2a/channel-token}"
CHAN_URL="http://127.0.0.1:8790/deliver"
RECEIVER="onion-evolve"
REC=""; NOPUSH=""; LEASE=""; L_THREAD=""; L_FROM=""; L_TTL=""; PENDING="/home/onion/onion-bridge/data/a2a-pending"
X_FROM=""; X_THREAD=""
MEMBERS="${A2A_SPIKE_MEMBERS:-${ROOT}/docs/evolution/federation/members.yaml}"

die() { echo "ERRO: $*" >&2; exit 2; }
refuse() { echo "RECUSADO: $*" >&2; exit 1; }
while [ "$#" -gt 0 ]; do case "$1" in
  --no-push) NOPUSH=1; shift ;;
  --channel-url) CHAN_URL="$2"; shift 2 ;;
  --lease) LEASE=1; shift ;;
  --thread) L_THREAD="$2"; shift 2 ;;
  --from) L_FROM="$2"; shift 2 ;;
  --ttl) L_TTL="$2"; shift 2 ;;
  --pending-dir) PENDING="$2"; shift 2 ;;
  --expect-from) X_FROM="$2"; shift 2 ;;
  --expect-thread) X_THREAD="$2"; shift 2 ;;
  -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
  -) REC="-"; shift ;;
  -*) die "argumento desconhecido: $1" ;;
  *) REC="$1"; shift ;;
esac; done
for t in jq openssl curl; do command -v "$t" >/dev/null 2>&1 || die "ferramenta ausente: $t"; done
mkdir -p "${STATE}/inbox" "${STATE}/records"; chmod 700 "${STATE}" 2>/dev/null || true

now_ms() { python3 -c 'import time;print(int(time.time()*1000))' 2>/dev/null || echo "$(( $(date +%s) * 1000 ))"; }
b64url_decode() { local d="$1"; d="${d//-/+}"; d="${d//_//}"; case $(( ${#d} % 4 )) in 2) d="${d}==";; 3) d="${d}=";; esac; printf '%s' "${d}" | openssl base64 -d -A; }

# ── C2: lease por thread ─────────────────────────────────────────────────────────────────────────────
if [ -n "${LEASE}" ]; then
  [ -n "${L_THREAD}" ] && [ -n "${L_FROM}" ] && [ -n "${L_TTL}" ] || die "--lease exige --thread, --from e --ttl"
  [ "${L_TTL}" -le 1800 ] 2>/dev/null || die "TTL acima de 1800 s não está no protocolo"
  END=$(( $(date +%s) + L_TTL ))
  printf '%s\tLEASE-START\t%s\t%s\t%s\n' "$(now_ms)" "${L_FROM}" "${L_THREAD}" "${L_TTL}" >> "${STATE}/accept.tsv"
  echo "lease aberto: from=${L_FROM} thread=${L_THREAD} até $(date -d "@${END}" +%T 2>/dev/null || echo "${END}")" >&2
  PROBE="$(mktemp "${STATE}/records/probe.XXXXXX")"
  while [ "$(date +%s)" -lt "${END}" ]; do
    sudo -n ls "${PENDING}" 2>/dev/null | grep -E '^[A-Za-z0-9._-]+\.json$' | while IFS= read -r f; do
      sudo -n cat "${PENDING}/${f}" > "${PROBE}" 2>/dev/null || continue
      # o filtro é só pré-seleção (barato); a decisão é da invocação C1 abaixo, que confere
      # --expect-from/--expect-thread contra os CLAIMS ASSINADOS, nunca contra o envelope solto
      th="$(jq -r '.envelope.signal.thread // ""' "${PROBE}")"; fr="$(jq -r '.envelope.signal.from // ""' "${PROBE}")"
      [ "${th}" = "${L_THREAD}" ] && [ "${fr}" = "${L_FROM}" ] || continue
      bash "$0" "${PROBE}" --channel-url "${CHAN_URL}" --expect-from "${L_FROM}" --expect-thread "${L_THREAD}" 2>&1 \
        | grep -v '^já entregue' >&2 || true
    done || true   # fila vazia: o grep sai 1 e, sob pipefail+errexit, mataria o lease
    sleep 1
  done
  rm -f "${PROBE}"
  printf '%s\tLEASE-END\t%s\t%s\n' "$(now_ms)" "${L_FROM}" "${L_THREAD}" >> "${STATE}/accept.tsv"
  echo "lease vencido — de volta ao C1 (uma aceitação por mensagem)" >&2; exit 0
fi

# ── C1: um registro ─────────────────────────────────────────────────────────────────────────────────
[ -n "${REC}" ] || die "uso: accept-to-channel.sh <registro.json|-> [--no-push]"
command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1 || die "python3+yaml ausente (kid-binding)"
T_ACC="$(now_ms)"
# arquivos POR INVOCAÇÃO (refutador 2026-10-14: com caminho fixo, um lease e um C1 simultâneos podiam
# entregar o corpo de B com o meta de A) + lock em volta do dedupe/entrega
LOCAL="$(mktemp "${STATE}/records/rec.XXXXXX")"; BODYF="$(mktemp "${STATE}/records/body.XXXXXX")"
TMPS="$(mktemp)"; trap 'rm -f "${TMPS}" "${BODYF}"' EXIT
if [ "${REC}" = "-" ]; then cat > "${LOCAL}"
elif [ -r "${REC}" ]; then cp "${REC}" "${LOCAL}"
else sudo -n cat "${REC}" > "${LOCAL}" 2>/dev/null || die "registro ilegível (fila do bridge é da conta onion): ${REC}"; fi
jq -e . "${LOCAL}" >/dev/null 2>&1 || refuse "registro não é JSON"
[ "$(jq -r '.verdict.verified // false' "${LOCAL}")" = "true" ] || refuse "verdict.verified != true"

JWS="$(jq -r '.envelope.jws // empty' "${LOCAL}")"; [ -n "${JWS}" ] || refuse "registro sem envelope.jws (auditoria perdida)"
H="${JWS%%.*}"; R="${JWS#*.}"; P="${R%%.*}"; SIGB="${R#*.}"
HDR="$(b64url_decode "${H}")"; PL="$(b64url_decode "${P}")"
KID="$(printf '%s' "${HDR}" | jq -r '.kid // empty')"; ALG="$(printf '%s' "${HDR}" | jq -r '.alg // empty')"
[ "${ALG}" = "RS256" ] || refuse "alg ${ALG}"
case "${KID}" in ""|*/*|..*|.) refuse "kid inválido" ;; esac
[ -f "${JWKS}/${KID}.pem" ] || refuse "kid ${KID} não pinado em ${JWKS}"
b64url_decode "${SIGB}" > "${TMPS}"
printf '%s' "${H}.${P}" | openssl dgst -sha256 -verify "${JWKS}/${KID}.pem" -signature "${TMPS}" >/dev/null 2>&1 || refuse "assinatura não confere"

FROM="$(jq -r '.envelope.signal.from // empty' "${LOCAL}")"
# kid-binding (o mesmo do a2a-verify): a chave pinada tem de ser DO from. Sem isto a re-verificação só
# provaria "alguma chave pinada assinou" — e um registro montado à mão passaria com a chave de outro dono.
python3 - "${MEMBERS}" "${FROM}" "${KID}" <<'PY' || refuse "kid ${KID} não pertence a keys[${FROM}] no members.yaml"
import sys, yaml
ms = (yaml.safe_load(open(sys.argv[1])) or {}).get('members') or []
keys = next(((m.get('a2a') or {}).get('keys') or [] for m in ms if m.get('id') == sys.argv[2]), [])
sys.exit(0 if sys.argv[3] in keys else 1)
PY
EXP="$(printf '%s' "${PL}" | jq -r '.exp // empty')"
case "${EXP}" in ''|*[!0-9]*) refuse "JWS sem exp numérico (achado F2: o gate do core aceita; o spike não)" ;; esac
[ "${EXP}" -ge "$(date +%s)" ] || refuse "expirado (exp ${EXP})"
[ "$(jq -r '.from // empty' "${LOCAL}")" = "${FROM}" ] || refuse "from do registro ≠ from do envelope"
[ "$(printf '%s' "${PL}" | jq -r '.iss // empty')" = "${FROM}" ] || refuse "iss ≠ from"
[ "$(printf '%s' "${PL}" | jq -r '.aud // empty')" = "${RECEIVER}" ] || refuse "aud ≠ ${RECEIVER}"
JTI="$(printf '%s' "${PL}" | jq -r '.jti // empty')"; [ -n "${JTI}" ] || refuse "sem jti"
CL_SHA="$(printf '%s' "${PL}" | jq -r '.body_sha256 // empty')"
[ -n "${CL_SHA}" ] || refuse "JWS sem claim body_sha256 — corpo não amarrado à assinatura (envelope de sinal antigo?)"
# o corpo vai a um arquivo e o hash sai do arquivo: `$(...)` comeria o \n final e mudaria o hash
jq -j '.envelope.signal.body // ""' "${LOCAL}" > "${BODYF}"
BODY_SHA="$(openssl dgst -sha256 < "${BODYF}" | awk '{print $NF}')"
[ "${BODY_SHA}" = "${CL_SHA}" ] || refuse "corpo adulterado: sha256(body)=${BODY_SHA} ≠ claim ${CL_SHA}"
[ "$(jq -r '.envelope.signal.body_sha256 // empty' "${LOCAL}")" = "${CL_SHA}" ] || refuse "signal.body_sha256 ≠ claim"
THREAD="$(printf '%s' "${PL}" | jq -r '.thread // empty')"
[ "$(jq -r '.envelope.signal.thread // empty' "${LOCAL}")" = "${THREAD}" ] || refuse "thread do envelope ≠ claim"
[ -z "${X_FROM}" ] || [ "${X_FROM}" = "${FROM}" ] || refuse "lease é de ${X_FROM}; o claim assinado diz ${FROM}"
[ -z "${X_THREAD}" ] || [ "${X_THREAD}" = "${THREAD}" ] || refuse "lease é da thread ${X_THREAD}; o claim assinado diz ${THREAD}"

exec 8>"${STATE}/.deliver.lock"
command -v flock >/dev/null 2>&1 && flock 8
if grep -qxF "${JTI}" "${STATE}/delivered.jti" 2>/dev/null; then echo "já entregue (jti ${JTI}) — nada a fazer" >&2; exit 0; fi

# registro humano da aceitação (o a2a-accept do core, idempotente, num inbox do spike)
bash "${ACCEPT}" "${LOCAL}" --inbox "${STATE}/inbox" >/dev/null || refuse "a2a-accept recusou"

TASK="$(jq -r '.taskId // ""' "${LOCAL}")"
if [ -z "${NOPUSH}" ]; then
  [ -f "${CHAN_TOKEN}" ] || die "token do channel ausente: ${CHAN_TOKEN}"
  HF="$(mktemp)"; ( umask 077; printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "${CHAN_TOKEN}")" > "${HF}" )
  PAYLOAD="$(jq -n --rawfile body "${BODYF}" --arg from "${FROM}" --arg kid "${KID}" --arg jti "${JTI}" \
    --arg thread "${THREAD}" --arg task "${TASK}" --arg sha "${CL_SHA}" \
    '{body:$body, meta:{from:$from, kid:$kid, jti:$jti, thread:$thread, task_id:$task, body_sha256:$sha}}')"
  T_PUSH="$(now_ms)"
  CODE="$(printf '%s' "${PAYLOAD}" | curl -sS -m 10 -o /dev/null -w '%{http_code}' -H @"${HF}" \
          -H 'Content-Type: application/json' --data-binary @- "${CHAN_URL}" || true)"
  rm -f "${HF}"
  [ "${CODE}" = "200" ] || refuse "channel não aceitou (http ${CODE}) — a sessão receptora está aberta com a flag de dev?"
else
  T_PUSH="$(now_ms)"; CODE="no-push"
fi
printf '%s\n' "${JTI}" >> "${STATE}/delivered.jti"
printf '%s\tACCEPT\t%s\t%s\t%s\t%s\t%s\t%s\n' "${T_ACC}" "${T_PUSH}" "${FROM}" "${THREAD}" "${JTI}" "${TASK}" "${CODE}" >> "${STATE}/accept.tsv"
echo "aceito e entregue ao channel: from=${FROM} thread=${THREAD} jti=${JTI} (push http ${CODE})" >&2
